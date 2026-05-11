# Managed by KUbuntu Migrate
export PATH="$HOME/DEV/script/bin:$HOME/.local/bin:$PATH"

if [ -f "$HOME/DEV/script/zsh/yakuake-snapshot.zsh" ]; then
  source "$HOME/DEV/script/zsh/yakuake-snapshot.zsh"
fi

ysnap-restore() {
  yakuake-snapshot-restore
}
