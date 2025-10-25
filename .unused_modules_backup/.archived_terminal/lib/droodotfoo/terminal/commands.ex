defmodule Droodotfoo.Terminal.Commands do
  @moduledoc """
  Terminal command orchestration module.

  All command implementations have been moved to focused submodules:
  - Commands.Navigation - Directory navigation (ls, cd, pwd)
  - Commands.System - System information (whoami, date, uname, env)
  - Commands.Fun - Easter eggs and fun commands (fortune, cowsay, sl)
  - Commands.Plugins - Game plugins and integrations (spotify, github, games)
  - Commands.Git - Development tools (git, npm, yarn, cargo)
  - Commands.FileOps - File operations (cat, grep, find, touch, mkdir)
  - Commands.DrooFoo - Personal website commands (projects, resume, contact)
  - Commands.Utilities - Terminal utilities (help, theme, search, tree)
  - Commands.Web3 - Blockchain integration (wallet, ens, nft, tokens)
  - Commands.Fileverse - Fileverse SDK (dDocs, dSheets, IPFS, Portal)

  Each command returns {:ok, output} or {:error, message}.
  Some commands also return updated state as {:ok, output, new_state}.
  """

  alias Droodotfoo.Terminal.Commands

  # Navigation module delegates
  defdelegate ls(args, state), to: Commands.Navigation
  defdelegate cd(args, state), to: Commands.Navigation
  defdelegate pwd(state), to: Commands.Navigation

  # System module delegates
  defdelegate whoami(state), to: Commands.System
  defdelegate date(state), to: Commands.System
  defdelegate uptime(state), to: Commands.System
  defdelegate uname(args, state), to: Commands.System
  defdelegate echo(args, state), to: Commands.System
  defdelegate hostname(state), to: Commands.System
  defdelegate env(state), to: Commands.System

  # Fun module delegates
  defdelegate fortune(state), to: Commands.Fun
  defdelegate cowsay(args, state), to: Commands.Fun
  defdelegate sl(state), to: Commands.Fun
  defdelegate sudo(args, state), to: Commands.Fun
  defdelegate vim(args, state), to: Commands.Fun
  defdelegate emacs(args, state), to: Commands.Fun
  defdelegate exit(state), to: Commands.Fun

  # Plugins module delegates
  defdelegate plugins(args, state), to: Commands.Plugins
  defdelegate snake(args, state), to: Commands.Plugins
  defdelegate calc(args, state), to: Commands.Plugins
  defdelegate calculator(args, state), to: Commands.Plugins
  defdelegate matrix(args, state), to: Commands.Plugins
  defdelegate rain(args, state), to: Commands.Plugins
  defdelegate conway(args, state), to: Commands.Plugins
  defdelegate life(args, state), to: Commands.Plugins
  defdelegate tetris(args, state), to: Commands.Plugins
  defdelegate t(args, state), to: Commands.Plugins
  defdelegate twenty48(args, state), to: Commands.Plugins
  defdelegate game48(args, state), to: Commands.Plugins
  defdelegate wordle(args, state), to: Commands.Plugins
  defdelegate word(args, state), to: Commands.Plugins
  defdelegate typing(args, state), to: Commands.Plugins
  defdelegate type(args, state), to: Commands.Plugins
  defdelegate wpm(args, state), to: Commands.Plugins
  defdelegate spotify(args, state), to: Commands.Plugins
  defdelegate music(args, state), to: Commands.Plugins
  defdelegate github(args, state), to: Commands.Plugins
  defdelegate gh(args, state), to: Commands.Plugins

  # Git module delegates
  defdelegate git(args, state), to: Commands.Git
  defdelegate npm(args, state), to: Commands.Git
  defdelegate pip(args, state), to: Commands.Git
  defdelegate yarn(args, state), to: Commands.Git
  defdelegate cargo(args, state), to: Commands.Git
  defdelegate curl(args, state), to: Commands.Git
  defdelegate wget(args, state), to: Commands.Git
  defdelegate ping(args, state), to: Commands.Git
  defdelegate ssh(args, state), to: Commands.Git
  defdelegate tar(args, state), to: Commands.Git

  # FileOps module delegates
  defdelegate find(args, state), to: Commands.FileOps
  defdelegate cat(args, state), to: Commands.FileOps
  defdelegate head(args, state), to: Commands.FileOps
  defdelegate tail(args, state), to: Commands.FileOps
  defdelegate grep(args, state), to: Commands.FileOps
  defdelegate rm(args, state), to: Commands.FileOps
  defdelegate touch(args, state), to: Commands.FileOps
  defdelegate mkdir(args, state), to: Commands.FileOps
  defdelegate cp(args, state), to: Commands.FileOps
  defdelegate mv(args, state), to: Commands.FileOps
  defdelegate wc(args, state), to: Commands.FileOps

  # DrooFoo module delegates
  defdelegate projects(args, state), to: Commands.DrooFoo
  defdelegate project(args, state), to: Commands.DrooFoo
  defdelegate skills(args, state), to: Commands.DrooFoo
  defdelegate resume(args, state), to: Commands.DrooFoo
  defdelegate contact(args, state), to: Commands.DrooFoo
  defdelegate download(args, state), to: Commands.DrooFoo
  defdelegate charts(state), to: Commands.DrooFoo
  defdelegate api(args, state), to: Commands.DrooFoo
  defdelegate resume_export(args, state), to: Commands.DrooFoo
  defdelegate resume_formats(args, state), to: Commands.DrooFoo
  defdelegate resume_preview(args, state), to: Commands.DrooFoo
  defdelegate contact_form(args, state), to: Commands.DrooFoo
  defdelegate contact_status(args, state), to: Commands.DrooFoo

  # Utilities module delegates
  defdelegate help(args, state), to: Commands.Utilities
  defdelegate man(args, state), to: Commands.Utilities
  defdelegate clear(state), to: Commands.Utilities
  defdelegate history(state), to: Commands.Utilities
  defdelegate themes(state), to: Commands.Utilities
  defdelegate theme(args, state), to: Commands.Utilities
  defdelegate perf(args, state), to: Commands.Utilities
  defdelegate dashboard(args, state), to: Commands.Utilities
  defdelegate metrics(args, state), to: Commands.Utilities
  defdelegate crt(args, state), to: Commands.Utilities
  defdelegate contrast(args, state), to: Commands.Utilities
  defdelegate a11y(args, state), to: Commands.Utilities
  defdelegate search(args, state), to: Commands.Utilities
  defdelegate tree(args, state), to: Commands.Utilities

  # Web3 module delegates
  defdelegate web3(args, state), to: Commands.Web3
  defdelegate wallet(args, state), to: Commands.Web3
  defdelegate w3(args, state), to: Commands.Web3
  defdelegate ens(args, state), to: Commands.Web3
  defdelegate nft(args, state), to: Commands.Web3
  defdelegate nfts(args, state), to: Commands.Web3
  defdelegate tokens(args, state), to: Commands.Web3
  defdelegate balance(args, state), to: Commands.Web3
  defdelegate crypto(args, state), to: Commands.Web3
  defdelegate tx(args, state), to: Commands.Web3
  defdelegate transactions(args, state), to: Commands.Web3
  defdelegate contract(args, state), to: Commands.Web3
  defdelegate call(args, state), to: Commands.Web3

  # Fileverse module delegates
  defdelegate ipfs(args, state), to: Commands.Fileverse
  defdelegate ddoc(args, state), to: Commands.Fileverse
  defdelegate docs(args, state), to: Commands.Fileverse
  defdelegate upload(args, state), to: Commands.Fileverse
  defdelegate files(args, state), to: Commands.Fileverse
  defdelegate file(args, state), to: Commands.Fileverse
  defdelegate encrypt(args, state), to: Commands.Fileverse
  defdelegate decrypt(args, state), to: Commands.Fileverse
  defdelegate portal(args, state), to: Commands.Fileverse
  defdelegate sheet(args, state), to: Commands.Fileverse
  defdelegate sheets(args, state), to: Commands.Fileverse
end
