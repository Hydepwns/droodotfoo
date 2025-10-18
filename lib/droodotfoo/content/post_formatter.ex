defmodule Droodotfoo.Content.PostFormatter do
  @moduledoc """
  ASCII art formatting for blog posts.
  Inspired by minimalist monospace web design.
  """

  alias Droodotfoo.Content.Posts.Post

  @doc """
  Return post header data for rendering.
  """
  def format_header(%Post{} = post) do
    %{
      title: String.upcase(post.title),
      description: post.description,
      metadata:
        [
          {"Published", Date.to_string(post.date)},
          {"Reading", "#{post.read_time} min"},
          if(length(post.tags) > 0, do: {"Tags", Enum.join(post.tags, ", ")}, else: nil)
        ]
        |> Enum.filter(&(&1 != nil))
    }
  end

  @doc """
  Format a back link with arrow.
  """
  def back_link(text \\ "Back to Home") do
    "← #{text}"
  end

  @doc """
  Format tags as a comma-separated list with brackets.
  """
  def format_tags([]), do: ""

  def format_tags(tags) when is_list(tags) do
    "[#{Enum.join(tags, "] [")}]"
  end
end
