defmodule Droodotfoo.Wiki.Mailer do
  @moduledoc """
  Email mailer for wiki edit notifications.
  """

  use Swoosh.Mailer, otp_app: :droodotfoo
end
