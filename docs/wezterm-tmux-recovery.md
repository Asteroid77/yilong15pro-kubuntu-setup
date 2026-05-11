# WezTerm tmux Recovery

## Scope

This route is for WezTerm GUI tab recovery only.

It does not use Yakuake/Konsole profiles, `~/.tmux.conf`, or the global tmux resurrect directory. Keep those routes separate; mixing them is what caused polluted restores such as old `meteor-tab-*` sessions appearing in WezTerm.

## Owned Files

- `~/.wezterm.lua`
- `~/.config/tmux/wezterm.conf`
- `~/DEV/script/bin/wezterm-tmux-tab`

KUbuntu Migrate templates:

- `scripts/templates/wezterm/wezterm.lua`
- `scripts/templates/tmux/wezterm.conf`
- `scripts/templates/bin/wezterm-tmux-tab`

## Runtime State

- tmux socket: `~/.local/state/tmux-wezterm/main.sock`
- tmux config: `~/.config/tmux/wezterm.conf`
- tmux resurrect dir: `~/.local/state/wezterm-tmux/resurrect`
- business tmux sessions: normal session names, default new names `wezterm-work-N`
- technical tmux sessions: reserved prefix `wezterm-tech-`

Each WezTerm GUI tab maps to one business tmux session. The tmux session name is the GUI tab title source, and each session can contain its own normal tmux windows and panes.

The helper uses only the dedicated socket and config. On startup it restores the dedicated resurrect state, lists business sessions as `session_name<TAB>display_name`, and WezTerm rebuilds one GUI tab per business session. The post-save hook filters technical sessions and old Yakuake/Konsole session names out of the dedicated resurrect snapshot.

The old `main` session plus window model is not migrated automatically. Existing `main` state can remain on disk, but this route treats `main`, `wezterm-tab-*`, and `meteor-tab-*` as non-business sessions and filters them from future WezTerm saves.

## Shortcuts

- `Ctrl+Shift+T`: create a new business tmux session and open a matching WezTerm GUI tab.
- `Ctrl+Shift+R`: rename the current business tmux session; the GUI tab title follows the session name.

## Validation

1. Fully close WezTerm.
2. Open WezTerm.
3. Create two GUI tabs with `Ctrl+Shift+T`.
4. Rename the tabs with `Ctrl+Shift+R` to `frontend` and `backend`.
5. In the `frontend` tab, use native tmux commands to create multiple tmux windows.
6. Wait at least 60 seconds for tmux-continuum, or save manually from inside tmux with prefix then `Ctrl+s`.
7. Fully close WezTerm.
8. Open WezTerm again.

Expected result:

- WezTerm GUI tabs are recreated from business tmux sessions.
- GUI tab titles match tmux session names.
- Each GUI tab retains its own tmux windows and panes.
- Old `meteor-tab-*` Yakuake/Konsole sessions do not appear.

## Known Boundaries

- This restores tmux sessions, windows, panes, working directories, and captured pane contents as supported by tmux-resurrect. It is not native terminal scrollback restoration.
- WezTerm does not provide a reliable GUI close hook that can replace tmux-continuum autosave.
- If `~/.local/state/wezterm-tmux/resurrect` is empty, the first clean run creates a fresh `wezterm-work-1` business session. Rename or recreate workspaces as needed.
- Do not copy `~/.local/share/tmux/resurrect/last` into this route; that global file may contain old Yakuake/Konsole experiments.
- Do not delete old resurrect files during this migration. If cleanup is needed, back up or rename them first.
