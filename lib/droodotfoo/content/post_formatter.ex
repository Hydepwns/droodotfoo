defmodule Droodotfoo.Content.PostFormatter do
  @moduledoc """
  ASCII art formatting for blog posts.
  Inspired by minimalist monospace web design.
  """

  alias Droodotfoo.Content.Posts.Post

  @type header :: %{
          title: String.t(),
          description: String.t() | nil,
          metadata: [{String.t(), String.t()}]
        }

  @doc """
  Return post header data for rendering.
  """
  @spec format_header(Post.t()) :: header()
  def format_header(%Post{} = post) do
    %{
      title: String.upcase(post.title),
      description: post.description,
      metadata:
        [
          {"Published", Date.to_string(post.date)},
          {"Reading", "#{post.read_time} min"},
          if(post.tags != [], do: {"Tags", Enum.join(post.tags, ", ")}, else: nil)
        ]
        |> Enum.filter(&(&1 != nil))
    }
  end

  @doc """
  Format a back link with arrow.
  """
  @spec back_link(String.t()) :: String.t()
  def back_link(text \\ "Back to Home") do
    "← #{text}"
  end

  @doc """
  Format tags as a comma-separated list with brackets.
  """
  @spec format_tags([String.t()]) :: String.t()
  def format_tags([]), do: ""

  def format_tags(tags) when is_list(tags) do
    "[#{Enum.join(tags, "] [")}]"
  end
end
