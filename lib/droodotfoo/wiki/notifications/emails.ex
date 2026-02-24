defmodule Droodotfoo.Wiki.Notifications.Emails do
  @moduledoc """
  Email templates for wiki edit notifications.
  """

  import Swoosh.Email

  @admin_email Application.compile_env(:droodotfoo, :wiki_admin_email, "droo@droo.foo")
  @from_email {"droo.foo wiki", "droo@droo.foo"}

  @doc """
  Notify admin of a new edit submission.
  """
  def new_edit_notification(pending_edit) do
    article = pending_edit.article

    new()
    |> to(admin_email())
    |> from(@from_email)
    |> subject("[Wiki] New edit suggestion: #{article.title}")
    |> html_body(new_edit_html(pending_edit, article))
    |> text_body(new_edit_text(pending_edit, article))
  end

  @doc """
  Notify submitter that their edit was approved.
  """
  def edit_approved_notification(pending_edit) do
    article = pending_edit.article

    new()
    |> to(pending_edit.submitter_email)
    |> from(@from_email)
    |> subject("[Wiki] Your edit was approved: #{article.title}")
    |> html_body(approved_html(pending_edit, article))
    |> text_body(approved_text(pending_edit, article))
  end

  @doc """
  Notify submitter that their edit was rejected.
  """
  def edit_rejected_notification(pending_edit) do
    article = pending_edit.article

    new()
    |> to(pending_edit.submitter_email)
    |> from(@from_email)
    |> subject("[Wiki] Your edit was not accepted: #{article.title}")
    |> html_body(rejected_html(pending_edit, article))
    |> text_body(rejected_text(pending_edit, article))
  end

  defp admin_email do
    Application.get_env(:droodotfoo, :wiki_admin_email, @admin_email)
  end

  defp new_edit_html(pending_edit, article) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>New Edit Suggestion</title>
      <style>
        body { font-family: monospace; line-height: 1.6; color: #c0c0c0; background: #1a1a1a; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #0a0a0a; color: #00ff00; padding: 20px; border: 1px solid #333; }
        .content { background: #1a1a1a; padding: 20px; border: 1px solid #333; border-top: none; }
        .field { margin-bottom: 15px; }
        .label { color: #00ff00; font-weight: bold; }
        .value { margin-top: 5px; color: #c0c0c0; }
        .reason { background: #0a0a0a; padding: 15px; border-left: 4px solid #00ff00; color: #c0c0c0; }
        a { color: #00ff00; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>New Edit Suggestion</h1>
        </div>
        <div class="content">
          <div class="field">
            <div class="label">Article:</div>
            <div class="value">#{escape_html(article.title)} (#{article.source})</div>
          </div>
          <div class="field">
            <div class="label">Submitter:</div>
            <div class="value">#{escape_html(pending_edit.submitter_email || "anonymous")}</div>
          </div>
          #{if pending_edit.reason do
      """
          <div class="field">
            <div class="label">Reason:</div>
            <div class="reason">#{escape_html(pending_edit.reason)}</div>
          </div>
      """
    else
      ""
    end}
          <div class="field">
            <div class="label">Submitted:</div>
            <div class="value">#{format_datetime(pending_edit.inserted_at)}</div>
          </div>
          <p>Review at: <a href="https://wiki.droo.foo/admin/pending">wiki.droo.foo/admin/pending</a></p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp new_edit_text(pending_edit, article) do
    """
    NEW EDIT SUGGESTION
    ===================
    Article: #{article.title} (#{article.source})
    Submitter: #{pending_edit.submitter_email || "anonymous"}
    #{if pending_edit.reason, do: "Reason: #{pending_edit.reason}", else: ""}
    Submitted: #{format_datetime(pending_edit.inserted_at)}
    ---
    Review at: https://wiki.droo.foo/admin/pending
    """
  end

  defp approved_html(pending_edit, article) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Edit Approved</title>
      <style>
        body { font-family: monospace; line-height: 1.6; color: #c0c0c0; background: #1a1a1a; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #0a0a0a; color: #00ff00; padding: 20px; border: 1px solid #333; }
        .content { background: #1a1a1a; padding: 20px; border: 1px solid #333; border-top: none; }
        .note { background: #0a0a0a; padding: 15px; border-left: 4px solid #00ff00; color: #c0c0c0; }
        a { color: #00ff00; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Edit Approved</h1>
        </div>
        <div class="content">
          <p>Your suggested edit to <strong>#{escape_html(article.title)}</strong> has been approved and is now live.</p>
          #{if pending_edit.reviewer_note do
      """
          <div class="note">
            <strong>Reviewer note:</strong> #{escape_html(pending_edit.reviewer_note)}
          </div>
      """
    else
      ""
    end}
          <p>View the article: <a href="https://wiki.droo.foo/#{article.source}/#{article.slug}">wiki.droo.foo/#{article.source}/#{article.slug}</a></p>
          <p>Thank you for contributing!</p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp approved_text(pending_edit, article) do
    """
    EDIT APPROVED
    =============
    Your suggested edit to "#{article.title}" has been approved and is now live.
    #{if pending_edit.reviewer_note, do: "\nReviewer note: #{pending_edit.reviewer_note}", else: ""}
    View the article: https://wiki.droo.foo/#{article.source}/#{article.slug}
    ---
    Thank you for contributing!
    """
  end

  defp rejected_html(pending_edit, article) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Edit Not Accepted</title>
      <style>
        body { font-family: monospace; line-height: 1.6; color: #c0c0c0; background: #1a1a1a; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #0a0a0a; color: #ffaa00; padding: 20px; border: 1px solid #333; }
        .content { background: #1a1a1a; padding: 20px; border: 1px solid #333; border-top: none; }
        .note { background: #0a0a0a; padding: 15px; border-left: 4px solid #ffaa00; color: #c0c0c0; }
        a { color: #00ff00; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Edit Not Accepted</h1>
        </div>
        <div class="content">
          <p>Your suggested edit to <strong>#{escape_html(article.title)}</strong> was not accepted.</p>
          #{if pending_edit.reviewer_note do
      """
          <div class="note">
            <strong>Reason:</strong> #{escape_html(pending_edit.reviewer_note)}
          </div>
      """
    else
      ""
    end}
          <p>Feel free to submit another edit if you believe there's an error.</p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp rejected_text(pending_edit, article) do
    """
    EDIT NOT ACCEPTED
    =================
    Your suggested edit to "#{article.title}" was not accepted.
    #{if pending_edit.reviewer_note, do: "\nReason: #{pending_edit.reviewer_note}", else: ""}
    ---
    Feel free to submit another edit if you believe there's an error.
    """
  end

  defp escape_html(nil), do: ""

  defp escape_html(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  defp format_datetime(nil), do: ""
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")
end
