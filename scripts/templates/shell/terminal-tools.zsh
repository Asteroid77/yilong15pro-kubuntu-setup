# Managed by KUbuntu Migrate
export PATH="$HOME/.atuin/bin:$HOME/.local/bin:$PATH"

mdv() {
  if ! command -v glow >/dev/null 2>&1; then
    echo "glow 未安装" >&2
    return 1
  fi
  if [ "$#" -eq 0 ]; then
    glow -
  else
    glow "$@"
  fi
}

mdstream() {
  if ! command -v sd >/dev/null 2>&1; then
    echo "Streamdown(sd) 未安装" >&2
    return 1
  fi
  sd "$@"
}

mdrun() {
  if ! command -v sd >/dev/null 2>&1; then
    echo "Streamdown(sd) 未安装" >&2
    return 1
  fi
  if [ "$#" -eq 0 ]; then
    echo "用法: mdrun <command> [args...]" >&2
    return 2
  fi

  local wrapper rc
  wrapper=$(mktemp "${TMPDIR:-/tmp}/mdrun.XXXXXX") || return 1

  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s' 'exec '
    printf '%q ' "$@"
    printf '\n'
  } > "$wrapper"

  chmod +x "$wrapper" || {
    rm -f "$wrapper"
    return 1
  }

  sd -e "$wrapper"
  rc=$?
  rm -f "$wrapper"
  return "$rc"
}

refreshapps() {
  local DESKTOP_DIR="$HOME/.local/share/applications"
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
  fi

  local ICON_CACHE_DIR="$HOME/.local/share/icons/hicolor"
  if [ -d "$ICON_CACHE_DIR" ] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache "$ICON_CACHE_DIR" >/dev/null 2>&1 || true
  fi
}

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi
