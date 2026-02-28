defmodule Droodotfoo.Git.Source do
  @moduledoc """
  Behaviour for git source adapters (GitHub, Forgejo, etc).

  Each source implements a common interface for browsing repos,
  files, and commits.
  """

  @type source :: :github | :forgejo

  @type repo :: %{
          name: String.t(),
          full_name: String.t(),
          description: String.t() | nil,
          default_branch: String.t(),
          stars: integer(),
          forks: integer(),
          updated_at: String.t(),
          html_url: String.t(),
          clone_url: String.t(),
          language: String.t() | nil,
          private: boolean(),
          archived: boolean(),
          source: source()
        }

  @type tree_entry :: %{
          name: String.t(),
          path: String.t(),
          type: :file | :dir,
          size: integer() | nil,
          sha: String.t() | nil
        }

  @type file_content :: %{
          content: String.t(),
          size: integer(),
          encoding: String.t() | nil,
          sha: String.t() | nil
        }

  @type commit :: %{
          sha: String.t(),
          short_sha: String.t(),
          message: String.t(),
          author: String.t(),
          email: String.t() | nil,
          date: String.t(),
          html_url: String.t() | nil
        }

  @callback list_repos(owner :: String.t(), opts :: keyword()) ::
              {:ok, [repo()]} | {:error, term()}

  @callback get_repo(owner :: String.t(), name :: String.t()) ::
              {:ok, repo()} | {:error, term()}

  @callback get_tree(
              owner :: String.t(),
              repo :: String.t(),
              branch :: String.t(),
              path :: String.t()
            ) ::
              {:ok, [tree_entry()]} | {:error, term()}

  @callback get_file(
              owner :: String.t(),
              repo :: String.t(),
              branch :: String.t(),
              path :: String.t()
            ) ::
              {:ok, file_content()} | {:error, term()}

  @callback get_commits(
              owner :: String.t(),
              repo :: String.t(),
              branch :: String.t(),
              opts :: keyword()
            ) ::
              {:ok, [commit()]} | {:error, term()}

  @callback list_branches(owner :: String.t(), repo :: String.t()) ::
              {:ok, [String.t()]} | {:error, term()}
end
