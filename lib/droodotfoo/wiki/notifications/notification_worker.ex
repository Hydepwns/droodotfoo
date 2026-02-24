defmodule Droodotfoo.Wiki.Notifications.NotificationWorker do
  @moduledoc """
  Oban worker for sending wiki edit notifications.

  Handles:
  - new_edit: Notify admin of new edit submission
  - approved: Notify submitter of approval
  - rejected: Notify submitter of rejection

  ## Manual Invocation

      %{type: "new_edit", pending_edit_id: 123}
      |> Droodotfoo.Wiki.Notifications.NotificationWorker.new()
      |> Oban.insert()

  """

  use Oban.Worker,
    queue: :notifications,
    max_attempts: 3,
    unique: [period: 60, keys: [:type, :pending_edit_id]]

  require Logger

  alias Droodotfoo.Wiki.Content
  alias Droodotfoo.Wiki.Mailer
  alias Droodotfoo.Wiki.Notifications.Emails

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => type, "pending_edit_id" => pending_edit_id}}) do
    case Content.get_pending_edit(pending_edit_id) do
      nil ->
        Logger.warning("NotificationWorker: pending edit #{pending_edit_id} not found")
        :ok

      pending_edit ->
        send_notification(type, pending_edit)
    end
  end

  defp send_notification("new_edit", pending_edit) do
    Logger.info("NotificationWorker: sending new_edit notification for edit #{pending_edit.id}")

    pending_edit
    |> Emails.new_edit_notification()
    |> Mailer.deliver()
    |> handle_result("new_edit", pending_edit.id)
  end

  defp send_notification("approved", pending_edit) do
    if pending_edit.submitter_email do
      Logger.info("NotificationWorker: sending approved notification for edit #{pending_edit.id}")

      pending_edit
      |> Emails.edit_approved_notification()
      |> Mailer.deliver()
      |> handle_result("approved", pending_edit.id)
    else
      Logger.info(
        "NotificationWorker: skipping approved notification (no email) for edit #{pending_edit.id}"
      )

      :ok
    end
  end

  defp send_notification("rejected", pending_edit) do
    if pending_edit.submitter_email do
      Logger.info("NotificationWorker: sending rejected notification for edit #{pending_edit.id}")

      pending_edit
      |> Emails.edit_rejected_notification()
      |> Mailer.deliver()
      |> handle_result("rejected", pending_edit.id)
    else
      Logger.info(
        "NotificationWorker: skipping rejected notification (no email) for edit #{pending_edit.id}"
      )

      :ok
    end
  end

  defp send_notification(type, pending_edit) do
    Logger.warning(
      "NotificationWorker: unknown notification type #{type} for edit #{pending_edit.id}"
    )

    :ok
  end

  defp handle_result({:ok, _}, type, id) do
    Logger.info("NotificationWorker: #{type} notification sent for edit #{id}")
    :ok
  end

  defp handle_result({:error, reason}, type, id) do
    Logger.error("NotificationWorker: failed to send #{type} for edit #{id}: #{inspect(reason)}")
    {:error, reason}
  end
end
