defmodule Mix.Tasks.Resume.Export do
  @moduledoc """
  Export resume data to JSON file for Fileverse upload.

  ## Usage

      mix resume.export                      # Saves to priv/resume.json
      mix resume.export custom.json          # Saves to custom file
      mix resume.export --pretty             # Pretty-printed to priv/resume.json
      mix resume.export --stdout             # Outputs to stdout

  ## Examples

      # Export to default location (priv/resume.json)
      mix resume.export

      # Export pretty-printed to default location
      mix resume.export --pretty

      # Export to custom file
      mix resume.export custom.json

      # Export to stdout and copy to clipboard (macOS)
      mix resume.export --stdout | pbcopy

  """

  use Mix.Task

  @shortdoc "Export resume data to JSON for Fileverse"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, args, _} =
      OptionParser.parse(args,
        strict: [pretty: :boolean, stdout: :boolean],
        aliases: [p: :pretty, s: :stdout]
      )

    pretty = Keyword.get(opts, :pretty, false)
    to_stdout = Keyword.get(opts, :stdout, false)

    # Get resume data
    resume_data = Droodotfoo.Resume.ResumeData.get_hardcoded_resume_data()

    # Encode to JSON
    json =
      if pretty do
        Jason.encode!(resume_data, pretty: true)
      else
        Jason.encode!(resume_data)
      end

    cond do
      to_stdout ->
        # Output to stdout
        IO.puts(json)

      args == [] ->
        # Default to priv/resume.json
        filename = "priv/resume.json"
        File.write!(filename, json)
        Mix.shell().info("Resume exported to: #{filename}")
        Mix.shell().info("File size: #{byte_size(json)} bytes")
        Mix.shell().info("")
        Mix.shell().info("Next steps:")
        Mix.shell().info("1. Upload #{filename} to https://docs.fileverse.io/")
        Mix.shell().info("2. Copy the IPFS CID from the URL")
        Mix.shell().info("3. Set environment variable:")
        Mix.shell().info("   export RESUME_IPFS_CID=\"QmYourCIDHere\"")

      true ->
        # Write to custom file
        [filename] = args
        File.write!(filename, json)
        Mix.shell().info("Resume exported to: #{filename}")
        Mix.shell().info("File size: #{byte_size(json)} bytes")
        Mix.shell().info("")
        Mix.shell().info("Next steps:")
        Mix.shell().info("1. Upload #{filename} to https://docs.fileverse.io/")
        Mix.shell().info("2. Copy the IPFS CID from the URL")
        Mix.shell().info("3. Set environment variable:")
        Mix.shell().info("   export RESUME_IPFS_CID=\"QmYourCIDHere\"")
    end
  end
end
