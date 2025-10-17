# Commands Module Refactoring Guide

## Overview

This guide documents the refactoring of `lib/droodotfoo/terminal/commands.ex` from a monolithic 3,938-line file into focused, maintainable modules.

**Goal:** Split into 10 modules, each under 600 lines

## Progress

### ✅ Completed (1/10 modules)

- [x] **Commands.Navigation** (116 lines) - `lib/droodotfoo/terminal/commands/navigation.ex`
  - Functions: `ls/2`, `cd/2`, `pwd/1`
  - Status: ✅ Complete, compiles successfully

### 🔄 In Progress (9/10 modules)

#### 2. Commands.FileOps
- **Target file:** `lib/droodotfoo/terminal/commands/file_ops.ex`
- **Functions to move:** `find`, `cat`, `touch`, `mkdir`, `rm`, `cp`, `mv`, `head`, `tail`, `wc`, `grep_cmd`
- **Source lines:** 54-216, helpers at 77-105
- **Estimated lines:** ~200

#### 3. Commands.System
- **Target file:** `lib/droodotfoo/terminal/commands/system.ex`
- **Functions to move:** `whoami`, `hostname`, `uname`, `date_cmd`, `env`, `echo`
- **Source lines:** 217-245
- **Estimated lines:** ~50

#### 4. Commands.Utilities
- **Target file:** `lib/droodotfoo/terminal/commands/utilities.ex`
- **Functions to move:** `help`, `man`, `clear_cmd`, `history_cmd`, `export_cmd`, `download`, `theme`, `perf`, `metrics`, `crt`, `high_contrast`, `a11y`
- **Source lines:** 246-375, 2470-2589
- **Estimated lines:** ~250

#### 5. Commands.Fun
- **Target file:** `lib/droodotfoo/terminal/commands/fun.ex`
- **Functions to move:** `cowsay`, `fortune`, `sl`, `lolcat`, `figlet`, `weather`, `joke`
- **Source lines:** 377-435, 638-678
- **Estimated lines:** ~100

#### 6. Commands.DrooFoo
- **Target file:** `lib/droodotfoo/terminal/commands/droo_foo.ex`
- **Functions to move:** `about`, `contact_cmd`, `projects`, `skills`, `experience`, `education`, `api`, `resume`, `resume_pdf`
- **Source lines:** 436-518, 2270-2398, 3838-3938
- **Estimated lines:** ~250

#### 7. Commands.Git
- **Target file:** `lib/droodotfoo/terminal/commands/git.ex`
- **Functions to move:** `git`, `npm`, `yarn`, `cargo`, `curl`, `wget`, `ping`, `ssh`, `tar`
- **Source lines:** 519-637
- **Estimated lines:** ~150

#### 8. Commands.Plugins
- **Target file:** `lib/droodotfoo/terminal/commands/plugins.ex`
- **Functions to move:** `matrix`, `rain`, `spotify`, `music`, `github`, `gh`
- **Helpers:** `launch_plugin`
- **Source lines:** 679-762, helper at 2401-2468
- **Estimated lines:** ~150

#### 9. Commands.Web3
- **Target file:** `lib/droodotfoo/terminal/commands/web3.ex`
- **Functions to move:** `web3`, `wallet`, `w3`, `ens`, `nft`, `tokens`, `balance`, `tx`, `contract`, `call`
- **Source lines:** 763-1311
- **Estimated lines:** ~550

#### 10. Commands.Fileverse
- **Target file:** `lib/droodotfoo/terminal/commands/fileverse.ex`
- **Functions to move:** `ipfs`, `ddoc`, `docs`, `storage`, `files`, `file`, `portal`, `encrypt`, `decrypt`, `sheet`, `sheets`, `site_tree`, `heartbit`, `agent`
- **Helpers:** `truncate_string`
- **Source lines:** 1312-2269, 2590-3837
- **Estimated lines:** ~800 (may need further splitting)

## Refactoring Process

### Step-by-Step for Each Module

1. **Open the template** in `lib/droodotfoo/terminal/commands/MODULE_NAME.ex`
2. **Open the source** in `lib/droodotfoo/terminal/commands.ex`
3. **Copy functions** from the specified line ranges
4. **Paste into template**, replacing the TODO comments
5. **Add necessary aliases** (check the original imports)
6. **Copy helper functions** if listed
7. **Format the code**: `mix format`
8. **Compile and check**: `mix compile`
9. **Run tests**: `mix test`
10. **Commit the module**: `git add ... && git commit -m "Refactor: Extract Commands.MODULE_NAME"`

### Example: Navigation Module (Reference)

```elixir
defmodule Droodotfoo.Terminal.Commands.Navigation do
  @moduledoc """
  Navigation command implementations.
  """

  alias Droodotfoo.Terminal.FileSystem

  def ls(args, state) do
    # ... implementation
  end

  def cd(args, state) do
    # ... implementation
  end

  def pwd(state) do
    # ... implementation
  end

  # Helper functions
  defp parse_ls_args(args), do: # ...
  defp format_ls_output(contents, opts, path, state), do: # ...
end
```

## Final Step: Update Main Module

After all modules are complete, replace `commands.ex` with delegation:

```elixir
defmodule Droodotfoo.Terminal.Commands do
  @moduledoc """
  Main entry point for terminal commands.
  Uses defdelegate for backward compatibility.
  """

  alias Droodotfoo.Terminal.Commands.{
    Navigation,
    FileOps,
    System,
    Utilities,
    Fun,
    DrooFoo,
    Git,
    Plugins,
    Web3,
    Fileverse
  }

  # Navigation
  defdelegate ls(args, state), to: Navigation
  defdelegate cd(args, state), to: Navigation
  defdelegate pwd(state), to: Navigation

  # ... repeat for all commands
end
```

## Testing Strategy

### After Each Module
```bash
# 1. Format
mix format

# 2. Compile
mix compile

# 3. Run related tests
mix test test/droodotfoo/terminal/
```

### Final Integration Test
```bash
# Run all tests
mix test

# Check for any failures
mix test --failed

# Verify no regressions
mix test --slowest 10
```

## Benefits

### Before Refactoring
- ❌ 3,938 lines in one file
- ❌ 280 functions mixed together
- ❌ Difficult to navigate
- ❌ Hard to maintain
- ❌ Merge conflicts common

### After Refactoring
- ✅ 10 focused modules, each <600 lines
- ✅ Clear separation of concerns
- ✅ Easy to find specific commands
- ✅ Better maintainability
- ✅ Easier to test individual modules

## Scripts Available

### 1. Complexity Analysis
```bash
mix run scripts/analyze_complexity.exs --format markdown
```

### 2. Create Module Templates (Already run)
```bash
elixir scripts/create_command_module_templates.exs
```

## Next Steps

1. **Continue with FileOps module** (next simplest after Navigation)
2. **Then System** (very small, ~50 lines)
3. **Build momentum** with the smaller modules first
4. **Save Web3 and Fileverse for last** (largest modules)
5. **Update main Commands module** with defdelegate
6. **Run full test suite**
7. **Update documentation**
8. **Delete old commands.ex.backup** after verification

## Rollback Plan

If issues arise:
```bash
# Restore original
cp lib/droodotfoo/terminal/commands.ex.backup lib/droodotfoo/terminal/commands.ex

# Remove new modules
rm -rf lib/droodotfoo/terminal/commands/

# Revert commit
git revert <commit-hash>
```

## Notes

- Original file backed up at: `lib/droodotfoo/terminal/commands.ex.backup`
- Module templates created with TODOs for guidance
- Each module is self-contained with its own helpers
- No changes to public API - backward compatible
- Uses `defdelegate` to maintain existing interfaces

## Completion Checklist

- [x] Analysis script created
- [x] Complexity report generated
- [x] Module templates created
- [x] Navigation module complete (1/10)
- [ ] FileOps module (2/10)
- [ ] System module (3/10)
- [ ] Utilities module (4/10)
- [ ] Fun module (5/10)
- [ ] DrooFoo module (6/10)
- [ ] Git module (7/10)
- [ ] Plugins module (8/10)
- [ ] Web3 module (9/10)
- [ ] Fileverse module (10/10)
- [ ] Main Commands module updated with defdelegate
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CI/CD complexity checks added

---

**Last Updated:** 2025-10-16
**Status:** 1/10 modules complete (10%)
**Estimated Time to Complete:** 4-6 hours for remaining 9 modules
