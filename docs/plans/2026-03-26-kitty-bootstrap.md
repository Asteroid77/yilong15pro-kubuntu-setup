# Kitty Bootstrap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a reusable terminal setup path to this migration repo that installs the latest upstream kitty plus glow, Streamdown, and Atuin with idempotent shell/config integration.

**Architecture:** Integrate a new terminal step into the existing `scripts/run.sh` pipeline, extend `scripts/lib/common.sh` with reusable file-management helpers, and keep terminal configuration in `scripts/templates/`. Validate with a small shell test for common helpers plus repository dry-run execution.

**Tech Stack:** Bash, existing repo helper library, GitHub release API, upstream installer scripts/binaries, pipx, shell syntax validation.

---

### Task 1: Add failing tests for reusable terminal helper functions

**Files:**
- Create: `tests/test_terminal_common.sh`
- Modify: `scripts/lib/common.sh`

**Step 1: Write the failing test**

Create `tests/test_terminal_common.sh` to validate these expected behaviors:
- `backup_file_with_timestamp <file>` creates exactly one timestamped backup
- `upsert_managed_block <file> <marker> <content>` inserts a marker block when absent
- Running `upsert_managed_block` a second time replaces the block instead of duplicating it

The test should:
- create temp files under `mktemp -d`
- source `scripts/lib/common.sh`
- call the target functions
- assert file contents using `grep`, `cmp`, or `diff`

**Step 2: Run test to verify it fails**

Run:
```bash
bash "tests/test_terminal_common.sh"
```

Expected:
- FAIL because `backup_file_with_timestamp` and `upsert_managed_block` do not exist yet

**Step 3: Write minimal implementation**

Add the following helpers to `scripts/lib/common.sh`:
- `backup_file_with_timestamp()`
- `upsert_managed_block()`
- any minimal helper they need, scoped only to terminal setup needs

**Step 4: Run test to verify it passes**

Run:
```bash
bash "tests/test_terminal_common.sh"
```

Expected:
- PASS with explicit success output

---

### Task 2: Add feature flag, metadata, and run pipeline integration

**Files:**
- Modify: `scripts/lib/common.sh`
- Modify: `scripts/run.sh`

**Step 1: Write the failing verification**

Decide the new feature id: `kitty_terminal`.
Then add/update a simple grep-based verification block in the terminal helper test or a temporary command checklist to require:
- `select_install_features` contains `kitty_terminal`
- `scripts/run.sh` sources and calls `step_12_terminal`

**Step 2: Run verification to verify it fails**

Run:
```bash
rg -n 'kitty_terminal|step_12_terminal|12_terminal' "scripts/lib/common.sh" "scripts/run.sh"
```

Expected:
- Missing matches for the new feature and new step wiring

**Step 3: Write minimal implementation**

Modify:
- `scripts/lib/common.sh` to add feature entry `kitty_terminal|kitty + glow + Streamdown + Atuin|on`
- any repo constants needed for upstream assets/install sources
- `scripts/run.sh` to source `scripts/steps/12_terminal.sh` and call `step_12_terminal` before `step_99_finish`

**Step 4: Run verification to verify it passes**

Run:
```bash
rg -n 'kitty_terminal|step_12_terminal|12_terminal' "scripts/lib/common.sh" "scripts/run.sh"
```

Expected:
- All expected references found

---

### Task 3: Add templates for kitty and shell integration

**Files:**
- Create: `scripts/templates/kitty/kitty.conf`
- Create: `scripts/templates/kitty/open-actions.conf`
- Create: `scripts/templates/shell/kitty-bootstrap.zsh`
- Create: `scripts/templates/shell/kitty-bootstrap.bash`
- Create: `scripts/templates/atuin/config.toml`

**Step 1: Write the failing verification**

Define required template expectations:
- kitty template contains practical defaults for scrollback, clipboard, and pager use
- shell templates expose `mdv` and `mdstream`
- shell templates include Atuin initialization guarded by command existence

**Step 2: Run verification to verify it fails**

Run:
```bash
find "scripts/templates" -maxdepth 3 -type f | rg 'kitty|atuin|shell'
```

Expected:
- No matching template files yet

**Step 3: Write minimal implementation**

Create the templates with only the minimum defaults required for:
- usable kitty startup config
- Markdown viewing aliases/functions
- Atuin shell integration

**Step 4: Run verification to verify it passes**

Run:
```bash
find "scripts/templates" -maxdepth 3 -type f | sort
```

Expected:
- All new template files present

---

### Task 4: Implement the terminal setup step

**Files:**
- Create: `scripts/steps/12_terminal.sh`
- Modify: `scripts/lib/common.sh`
- Modify: `scripts/templates/*` as needed

**Step 1: Write the failing verification**

Define step responsibilities:
- install latest upstream kitty
- install glow
- install pipx if needed, then Streamdown
- install Atuin
- write kitty configs
- inject shell blocks idempotently

**Step 2: Run verification to verify it fails**

Run:
```bash
bash -n "scripts/steps/12_terminal.sh"
```

Expected:
- FAIL because file does not exist yet

**Step 3: Write minimal implementation**

Implement `step_12_terminal()` with focused helper calls only. Keep logic split into small private functions where needed, for example:
- `install_upstream_kitty`
- `install_glow`
- `install_streamdown`
- `install_atuin`
- `install_kitty_templates`
- `install_shell_terminal_bootstrap`

Use existing repo helpers where possible:
- `smart_download`
- `github_latest_asset_url`
- `write_file`
- `append_file`
- newly added managed-block helpers

**Step 4: Run syntax verification to verify it passes**

Run:
```bash
bash -n "scripts/steps/12_terminal.sh" "scripts/lib/common.sh" "scripts/run.sh"
```

Expected:
- No syntax errors

---

### Task 5: Add README documentation for the new terminal route

**Files:**
- Modify: `README.md`

**Step 1: Write the failing verification**

Define required README updates:
- feature mention in software matrix or terminal section
- note that kitty uses upstream latest rather than distro package
- mention glow / Streamdown / Atuin integration

**Step 2: Run verification to verify it fails**

Run:
```bash
rg -n 'kitty|glow|Streamdown|Atuin' "README.md"
```

Expected:
- Missing or incomplete documentation for the new route

**Step 3: Write minimal implementation**

Update `README.md` with a concise terminal section matching the repository’s current style.

**Step 4: Run verification to verify it passes**

Run:
```bash
rg -n 'kitty|glow|Streamdown|Atuin' "README.md"
```

Expected:
- README contains the new terminal route documentation

---

### Task 6: Run repository-level verification

**Files:**
- Test: `tests/test_terminal_common.sh`
- Test: `scripts/run.sh`
- Test: `scripts/steps/12_terminal.sh`

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
bash -n "scripts/run.sh" "scripts/lib/common.sh" "scripts/steps/12_terminal.sh"
```

Expected:
- exit 0, no output

**Step 3: Run dry-run integration verification**

Run:
```bash
bash "init.sh" --dry-run --no-interactive
```

Expected:
- exit 0
- output includes kitty / glow / streamdown / atuin related actions
- no unintended destructive operations

**Step 4: Inspect dry-run output for expected terminal actions**

Run:
```bash
bash "init.sh" --dry-run --no-interactive | rg 'kitty|glow|atuin|streamdown|pipx'
```

Expected:
- visible terminal-step related actions

---

### Task 7: Final review and handoff

**Files:**
- Review: all touched files

**Step 1: Review diff**

Run:
```bash
git -C "/home/meteor/KUbuntu Migrate" status --short

git -C "/home/meteor/KUbuntu Migrate" diff -- docs/plans scripts README.md tests
```

Expected:
- only intended files changed

**Step 2: Summarize handoff notes**

Prepare a concise summary covering:
- where kitty config lives
- which shell files were auto-modified
- how to re-run safely
- whether re-login or `source ~/.zshrc` is needed

