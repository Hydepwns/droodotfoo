# Unused Modules Backup

This directory contains modules that were removed from active use but preserved for potential future restoration.

## Files

### portfolio.ex (3.7KB)
- **Module**: `Droodotfoo.Content.Portfolio`
- **Purpose**: Portfolio content for search and display
- **Removed**: Oct 19, 2024
- **Status**: Referenced in `lib/droodotfoo/raxol/command.ex` (stubbed)
- **Action**: Restore if portfolio search feature is needed

### samples.ex (7.8KB)
- **Module**: `Droodotfoo.Resume.Samples`
- **Purpose**: Sample resume data for testing/demo
- **Removed**: Oct 19, 2024
- **Status**: Referenced in `lib/droodotfoo/raxol/command.ex` (stubbed)
- **Action**: Restore if `loadresume` command is needed

### fileverse_loader.ex (7.6KB)
- **Module**: Fileverse-related functionality
- **Removed**: Oct 19, 2024
- **Status**: Not referenced
- **Action**: Can be safely deleted if Fileverse migration is complete

### ssh_simulator.ex (2.6KB)
- **Module**: `Droodotfoo.Features.SSHSimulator`
- **Removed**: Oct 18, 2024
- **Status**: Not referenced (deleted from git tracking)
- **Action**: Can be safely deleted if feature is not needed

### terminal_multiplexer.ex (5.2KB)
- **Module**: `Droodotfoo.Features.TerminalMultiplexer`
- **Removed**: Oct 18, 2024
- **Status**: Not referenced (deleted from git tracking)
- **Action**: Can be safely deleted if feature is not needed

## Restoration Process

If you need to restore a module:

1. Move the file from `.unused_modules_backup/` to appropriate location in `lib/`
2. Remove stub code in `lib/droodotfoo/raxol/command.ex` (search for TODO comments)
3. Uncomment the alias statements
4. Run tests to verify integration

## Cleanup Decision

After confirming modules are truly unused:
- Remove this entire directory from the repository
- Add `.unused_modules_backup/` to `.gitignore` if needed
