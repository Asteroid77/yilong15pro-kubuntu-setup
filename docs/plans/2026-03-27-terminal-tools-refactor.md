# Terminal Tools Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the current kitty-bound terminal route into a general `terminal_tools` route for `Atuin + glow + Streamdown` and a separate pure `kitty` optional route, while migrating the current machine away from kitty-bound shell/config integration.

**Architecture:** Introduce a new `step_12_terminal_tools.sh` for shared terminal enhancements and a new `step_13_kitty.sh` for kitty-only installation and shell helpers. Rework feature flags and shell templates so common tooling is terminal-agnostic, then migrate the current machine by replacing the old managed shell block and cleaning up kitty-specific managed configs and desktop entries.

**Tech Stack:** Bash, existing helper library in `scripts/lib/common.sh`, GitHub release downloads, upstream installer scripts/binaries, shell template injection, dry-run verification.

---

> 说明：根据当前用户要求，本计划不包含 git commit / branch 操作。

### Task 1: Add failing tests for managed block removal and template split

**Files:**
- Modify: `tests/test_terminal_common.sh`
- Modify: `scripts/lib/common.sh`

**Step 1: Write the failing test**

Extend `tests/test_terminal_common.sh` to cover:

- `remove_managed_block <file> <marker>` removes an existing managed block
- `scripts/templates/shell/terminal-tools.zsh` contains `mdv`, `mdstream`, and `atuin init`
- `scripts/templates/shell/kitty.zsh` does **not** contain `mdv`, `mdstream`, or `atuin init`

Use minimal assertions such as:

```bash
remove_managed_block "$TARGET_FILE" "kubuntu-migrate kitty"
assert_not_contains "$TARGET_FILE" '# >>> kubuntu-migrate kitty >>>'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'mdv()'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'mdv()'
```

**Step 2: Run test to verify it fails**

Run:

```bash
bash "tests/test_terminal_common.sh"
```

Expected:
- FAIL because `remove_managed_block` does not exist yet and the new shell templates do not exist yet

**Step 3: Write minimal implementation**

Add `remove_managed_block()` to `scripts/lib/common.sh`, implemented with the same marker format used by `upsert_managed_block()`:

```bash
remove_managed_block() {
    local TARGET_FILE=$1
    local MARKER=$2
    local START_MARKER="# >>> ${MARKER} >>>"
    local END_MARKER="# <<< ${MARKER} <<<"
    # remove block if present, otherwise no-op
}
```

Do not add unrelated helpers in this task.

**Step 4: Run test to verify it fails for the correct next reason**

Run:

```bash
bash "tests/test_terminal_common.sh"
```

Expected:
- FAIL because the new split shell templates still do not exist

---

### Task 2: Split feature flags and run pipeline wiring

**Files:**
- Modify: `scripts/lib/common.sh`
- Modify: `scripts/run.sh`

**Step 1: Write the failing verification**

Define the expected references:

- `terminal_tools|Atuin + glow + Streamdown|on`
- `kitty_terminal|kitty` with default `off`
- `scripts/run.sh` sources `scripts/steps/12_terminal_tools.sh`
- `scripts/run.sh` sources `scripts/steps/13_kitty.sh`
- `main()` calls `step_12_terminal_tools` then `step_13_kitty`

**Step 2: Run verification to verify it fails**

Run:

```bash
rg -n 'terminal_tools|step_12_terminal_tools|step_13_kitty|kitty_terminal' \
  "scripts/lib/common.sh" "scripts/run.sh"
```

Expected:
- Missing `terminal_tools`
- Missing split step wiring
- Existing `kitty_terminal` still bound to shared tools and default `on`

**Step 3: Write minimal implementation**

Modify:

- `scripts/lib/common.sh`
  - add `terminal_tools|Atuin + glow + Streamdown|on`
  - change `kitty_terminal` description to a pure kitty route and default it to `off`
- `scripts/run.sh`
  - source `scripts/steps/12_terminal_tools.sh`
  - source `scripts/steps/13_kitty.sh`
  - call `step_12_terminal_tools`
  - call `step_13_kitty`

Keep the existing ordering so terminal tools run before optional kitty setup.

**Step 4: Run verification to verify it passes**

Run:

```bash
rg -n 'terminal_tools|step_12_terminal_tools|step_13_kitty|kitty_terminal' \
  "scripts/lib/common.sh" "scripts/run.sh"
```

Expected:
- All expected references found

---

### Task 3: Create split shell templates and preserve only terminal-agnostic helpers

**Files:**
- Create: `scripts/templates/shell/terminal-tools.zsh`
- Create: `scripts/templates/shell/terminal-tools.bash`
- Create: `scripts/templates/shell/kitty.zsh`
- Create: `scripts/templates/shell/kitty.bash`
- Modify: `scripts/templates/atuin/config.toml` (only if needed)
- Delete: `scripts/templates/shell/kitty-bootstrap.zsh`
- Delete: `scripts/templates/shell/kitty-bootstrap.bash`

**Step 1: Write the failing verification**

Expected template responsibilities:

- `terminal-tools.*` contains:
  - PATH extension for `~/.atuin/bin` and `~/.local/bin`
  - `mdv`
  - `mdstream`
  - guarded `atuin init`
  - `refreshapps`
- `kitty.*` contains only kitty-specific shell helpers such as `kssh`

**Step 2: Run verification to verify it fails**

Run:

```bash
find "scripts/templates/shell" -maxdepth 1 -type f | sort
rg -n 'mdv\(|mdstream\(|atuin init|refreshapps|kssh\(' "scripts/templates/shell"
```

Expected:
- New split templates missing
- Old `kitty-bootstrap` templates still contain mixed responsibilities

**Step 3: Write minimal implementation**

Create:

- `scripts/templates/shell/terminal-tools.zsh`
- `scripts/templates/shell/terminal-tools.bash`
- `scripts/templates/shell/kitty.zsh`
- `scripts/templates/shell/kitty.bash`

Use these responsibility boundaries:

`terminal-tools.zsh` / `terminal-tools.bash`

```bash
export PATH="$HOME/.atuin/bin:$HOME/.local/bin:$PATH"

mdv() { ... glow ... }
mdstream() { ... sd ... }
alias refreshapps='update-desktop-database "$HOME/.local/share/applications" && (...)'

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init <shell>)"
fi
```

`kitty.zsh` / `kitty.bash`

```bash
kssh() {
  kitten ssh "$@"
}
```

Delete the obsolete `kitty-bootstrap.*` files after replacement.

**Step 4: Run verification to verify it passes**

Run:

```bash
find "scripts/templates/shell" -maxdepth 1 -type f | sort
rg -n 'mdv\(|mdstream\(|atuin init|refreshapps|kssh\(' "scripts/templates/shell"
```

Expected:
- New split templates present
- Shared helpers only in `terminal-tools.*`
- `kssh()` only in `kitty.*`

---

### Task 4: Implement the new terminal tools step and migration cleanup

**Files:**
- Create: `scripts/steps/12_terminal_tools.sh`
- Modify: `scripts/lib/common.sh`
- Modify: `scripts/templates/atuin/config.toml` (if needed)
- Modify: `scripts/templates/shell/terminal-tools.zsh`
- Modify: `scripts/templates/shell/terminal-tools.bash`

**Step 1: Write the failing verification**

The new step must:

- install `glow`
- install `pipx` + `Streamdown`
- install `Atuin`
- write `~/.config/atuin/config.toml`
- replace old `kubuntu-migrate kitty` blocks with `kubuntu-migrate terminal-tools`
- remove kitty-managed configs and desktop entries on the current machine when `kitty_terminal` is not enabled

**Step 2: Run syntax verification to verify it fails**

Run:

```bash
bash -n "scripts/steps/12_terminal_tools.sh"
```

Expected:
- FAIL because the file does not exist yet

**Step 3: Write minimal implementation**

Create `scripts/steps/12_terminal_tools.sh` by moving the shared logic out of the existing terminal step:

- `terminal_glow_asset_regex`
- `terminal_glow_tar_asset_regex`
- `can_sudo_non_interactive`
- `run_pipx`
- `terminal_latest_asset_url` (or a renamed generic terminal helper if desired)
- `install_glow`
- `ensure_pipx_ready`
- `install_streamdown`
- `install_atuin`
- `install_terminal_tools_templates`
- `install_shell_terminal_tools_bootstrap`
- `cleanup_legacy_kitty_managed_block`
- `cleanup_kitty_managed_files_if_disabled`
- `step_12_terminal_tools`

Migration cleanup behavior:

- Always remove the old `kubuntu-migrate kitty` managed block from `~/.zshrc` and `~/.bashrc`
- Always write the new `kubuntu-migrate terminal-tools` block
- Only remove `~/.config/kitty/*` and `kitty.desktop` / `kitty-open.desktop` when `kitty_terminal` is disabled
- Before removal, back up any existing file with `backup_file_with_timestamp`

Use `remove_managed_block` for managed block cleanup rather than inline ad-hoc text manipulation.

**Step 4: Run syntax verification to verify it passes**

Run:

```bash
bash -n "scripts/steps/12_terminal_tools.sh" "scripts/lib/common.sh"
```

Expected:
- No syntax errors

---

### Task 5: Slim the kitty route into a pure kitty optional step

**Files:**
- Create: `scripts/steps/13_kitty.sh`
- Modify: `scripts/templates/kitty/kitty.conf`
- Modify: `scripts/templates/kitty/open-actions.conf`
- Modify: `scripts/templates/shell/kitty.zsh`
- Modify: `scripts/templates/shell/kitty.bash`
- Delete: `scripts/steps/12_terminal.sh`

**Step 1: Write the failing verification**

The pure kitty step must:

- install only the kitty binary and menu entries
- write only kitty-specific config files
- inject only kitty-specific shell helpers
- stop writing `~/.config/atuin/config.toml`
- stop injecting `mdv` / `mdstream` / `atuin init`

**Step 2: Run verification to verify it fails**

Run:

```bash
rg -n 'install_glow|install_streamdown|install_atuin|mdv|mdstream|atuin init' \
  "scripts/steps/12_terminal.sh" "scripts/templates/shell/kitty-bootstrap.zsh" \
  "scripts/templates/shell/kitty-bootstrap.bash"
```

Expected:
- Existing kitty route still includes shared tooling and mixed shell helpers

**Step 3: Write minimal implementation**

Create `scripts/steps/13_kitty.sh` containing only kitty-specific functions:

- `terminal_kitty_asset_regex`
- `terminal_template_path` if still needed here
- `rewrite_kitty_desktop_entries`
- `install_template_with_backup` if shared locally, or move to a common location if needed
- `install_upstream_kitty`
- `install_kitty_templates`
- `install_shell_kitty_bootstrap`
- `step_13_kitty`

`install_shell_kitty_bootstrap` should:

- read `scripts/templates/shell/kitty.zsh`
- read `scripts/templates/shell/kitty.bash`
- inject the managed block with marker `kubuntu-migrate kitty`

Do not reintroduce shared terminal-tools logic here.

Delete the obsolete `scripts/steps/12_terminal.sh` once `run.sh` points to the new split files.

**Step 4: Run verification to verify it passes**

Run:

```bash
rg -n 'install_glow|install_streamdown|install_atuin|mdv|mdstream|atuin init' \
  "scripts/steps/13_kitty.sh" "scripts/templates/shell/kitty.zsh" \
  "scripts/templates/shell/kitty.bash"
```

Expected:
- No shared terminal-tools logic inside kitty-only step/templates

---

### Task 6: Update README to document the new split routes

**Files:**
- Modify: `README.md`

**Step 1: Write the failing verification**

The README should separately describe:

- the general terminal tools route
- the optional kitty route
- the fact that kitty no longer implicitly installs `Atuin + glow + Streamdown`

**Step 2: Run verification to verify it fails**

Run:

```bash
rg -n 'terminal_tools|kitty|glow|Streamdown|Atuin' "README.md"
```

Expected:
- Existing docs still describe a single combined terminal route

**Step 3: Write minimal implementation**

Update `README.md` to reflect:

- new feature names
- which shell helpers belong to `terminal_tools`
- which shell helpers belong to `kitty`
- that the recommended path for Konsole/Yakuake users is `terminal_tools`

Keep the wording concise and consistent with the repo style.

**Step 4: Run verification to verify it passes**

Run:

```bash
rg -n 'terminal_tools|kitty|glow|Streamdown|Atuin' "README.md"
```

Expected:
- README clearly documents both split routes

---

### Task 7: Run repository-level and current-machine verification

**Files:**
- Test: `tests/test_terminal_common.sh`
- Test: `scripts/run.sh`
- Test: `scripts/steps/12_terminal_tools.sh`
- Test: `scripts/steps/13_kitty.sh`

**Step 1: Run helper tests**

Run:

```bash
bash "tests/test_terminal_common.sh"
```

Expected:
- PASS

**Step 2: Run syntax checks**

Run:

```bash
bash -n "scripts/run.sh" "scripts/lib/common.sh" \
  "scripts/steps/12_terminal_tools.sh" "scripts/steps/13_kitty.sh"
```

Expected:
- No syntax errors

**Step 3: Run dry-run verification**

Run:

```bash
bash "init.sh" --dry-run --no-interactive
```

Then inspect:

```bash
bash "init.sh" --dry-run --no-interactive | rg 'terminal_tools|kitty|glow|atuin|streamdown|pipx'
```

Expected:
- `terminal_tools` actions show `glow`, `Streamdown`, `Atuin`
- `kitty_terminal` actions show only kitty-specific work

**Step 4: Run current-machine migration verification**

Run:

```bash
command -v glow
command -v sd
command -v atuin
rg -n 'kubuntu-migrate terminal-tools|kubuntu-migrate kitty' "$HOME/.zshrc" "$HOME/.bashrc"
test ! -f "$HOME/.config/kitty/kitty.conf"
test ! -f "$HOME/.config/kitty/open-actions.conf"
test ! -f "$HOME/.local/share/applications/kitty.desktop"
test ! -f "$HOME/.local/share/applications/kitty-open.desktop"
test -x "$HOME/.local/bin/kitty"
```

Expected:
- shared tools exist
- only `kubuntu-migrate terminal-tools` managed block remains in rc files unless `kitty_terminal` is explicitly enabled
- kitty-managed configs and desktop files are cleaned
- kitty binary remains installed

---

Plan complete and saved to `docs/plans/2026-03-27-terminal-tools-refactor.md`. Two execution options:

**1. Subagent-Driven (this session)** - 我在当前会话里直接继续实现、逐步验证、快速迭代

**2. Parallel Session (separate)** - 你开一个新会话，按 `executing-plans` 流程分批执行

你选哪一种？
