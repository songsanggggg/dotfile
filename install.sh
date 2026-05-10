#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC_DIR="${SCRIPT_DIR}/.config"
CONFIG_DEST_DIR="${HOME}/.config"
FCITX_CUSTOMIZER_URL="https://fcitx5.debuggerx.com/fcitx5_customizer.sh"

packages=(
  swayfx
  kitty
  waybar
  wlogout
  blueman
  bluez-utils
  networkmanager
  nm-connection-editor
  pavucontrol
  thunar
  tumbler
  thunar-archive-plugin
  file-roller
  gvfs
  libnotify
  grim
  slurp
  wl-clipboard
  polkit-gnome
  otf-font-awesome
  noto-fonts-cjk
  fuzzel
  mako
  swaylock
  swayidle
  swaybg
  network-manager-applet
  cliphist
  swappy
  playerctl
  brightnessctl
  fzf
  pacman-contrib
  otf-commit-mono-nerd
  upower
  gnome-keyring
  libsecret
  seahorse
)

SWAY_CONFIG_PATH="${CONFIG_DEST_DIR}/sway/config"
VSCODE_ARGV_DIR="${HOME}/.config/Code/User"
VSCODE_ARGV_PATH="${VSCODE_ARGV_DIR}/argv.json"
VSCODE_FLAGS_PATH="${HOME}/.config/code-flags.conf"
SWAY_DBUS_ENV_LINE='exec_always dbus-update-activation-environment --all'
VSCODE_PASSWORD_STORE_FLAG='--password-store=gnome-libsecret'

print_completion_message() {
  cat <<'EOF'

Done.

Next steps:
  1. Log into the "sway" Wayland session provided by swayfx.
  2. Inside sway, run: swaymsg reload
  3. If the bar does not appear, run: ~/.config/waybar/scripts/restart-waybar
  4. Hotkeys reference: HOTKEYS.md
EOF
}

print_vscode_keyring_completion_message() {
  cat <<'EOF'

VS Code keyring fix applied.

Next steps:
  1. Log out of the current Wayland session, then log back into sway.
  2. Start VS Code again and verify the keyring warning is gone.
  3. If GNOME Keyring asks for a password, unlock it with your login password.
  4. If you use greetd and auto-unlock still fails, add pam_gnome_keyring.so to /etc/pam.d/greetd.
EOF
}

require_config_source() {
  if [[ ! -d "$CONFIG_SRC_DIR" ]]; then
    printf 'Config source directory not found: %s\n' "$CONFIG_SRC_DIR" >&2
    exit 1
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$cmd" >&2
    exit 1
  fi
}

run_remote_bash_script() {
  local url="$1"
  shift || true

  require_cmd curl
  require_cmd bash

  local tmp_script
  tmp_script="$(mktemp)"

  curl -fsSL "$url" -o "$tmp_script"
  bash "$tmp_script" "$@"
  rm -f "$tmp_script"
}

install_packages() {
  printf 'Installing packages with yay...\n'
  yay -S --needed "${packages[@]}"
}

install_vscode_keyring_packages() {
  printf 'Installing VS Code keyring dependencies with yay...\n'
  yay -S --needed gnome-keyring libsecret seahorse
}

deploy_configs() {
  printf 'Deploying configs into %s...\n' "$CONFIG_DEST_DIR"
  mkdir -p "$CONFIG_DEST_DIR"

  local entry
  rm -rf "${CONFIG_DEST_DIR:?}/quickshell"

  for entry in sway waybar mako fuzzel swaylock kitty; do
    rm -rf "${CONFIG_DEST_DIR:?}/${entry}"
    cp -r "${CONFIG_SRC_DIR}/${entry}" "${CONFIG_DEST_DIR}/${entry}"
  done

  if [[ -d "${CONFIG_DEST_DIR}/sway/scripts" ]]; then
    chmod +x "${CONFIG_DEST_DIR}/sway/scripts/"*
  fi
  if [[ -d "${CONFIG_DEST_DIR}/waybar/scripts" ]]; then
    chmod +x "${CONFIG_DEST_DIR}/waybar/scripts/"*
  fi
}

ensure_line_in_file() {
  local file_path="$1"
  local line="$2"

  mkdir -p "$(dirname "$file_path")"
  touch "$file_path"

  if grep -Fqx "$line" "$file_path"; then
    return 0
  fi

  printf '\n%s\n' "$line" >>"$file_path"
}

ensure_sway_dbus_environment() {
  printf 'Ensuring sway exports the D-Bus activation environment...\n'
  ensure_line_in_file "$SWAY_CONFIG_PATH" "$SWAY_DBUS_ENV_LINE"
}

ensure_vscode_password_store() {
  printf 'Configuring VS Code to use gnome-libsecret...\n'
  mkdir -p "$VSCODE_ARGV_DIR"

  if [[ ! -f "$VSCODE_ARGV_PATH" ]] || [[ ! -s "$VSCODE_ARGV_PATH" ]]; then
    cat >"$VSCODE_ARGV_PATH" <<'EOF'
{
  "password-store": "gnome-libsecret"
}
EOF
    return 0
  fi

  if grep -Eq '"password-store"[[:space:]]*:[[:space:]]*"gnome-libsecret"' "$VSCODE_ARGV_PATH"; then
    return 0
  fi

  if grep -Eq '"password-store"[[:space:]]*:' "$VSCODE_ARGV_PATH"; then
    local tmp_file
    tmp_file="$(mktemp)"
    sed -E 's/"password-store"[[:space:]]*:[[:space:]]*"[^"]*"/"password-store": "gnome-libsecret"/' \
      "$VSCODE_ARGV_PATH" >"$tmp_file"
    mv "$tmp_file" "$VSCODE_ARGV_PATH"
    return 0
  fi

  local separator=","
  local last_content_line
  last_content_line="$(awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*\/\// { next }
    /^[[:space:]]*}[[:space:]]*$/ { next }
    { line=$0 }
    END { print line }
  ' "$VSCODE_ARGV_PATH")"

  if [[ -z "$last_content_line" || "$last_content_line" =~ ^[[:space:]]*\{[[:space:]]*$ || "$last_content_line" =~ ,[[:space:]]*$ ]]; then
    separator=""
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  awk -v separator="$separator" '
    /^[[:space:]]*}[[:space:]]*$/ && !done {
      print "  " separator "\"password-store\": \"gnome-libsecret\""
      done=1
    }
    { print }
  ' "$VSCODE_ARGV_PATH" >"$tmp_file"

  if cmp -s "$VSCODE_ARGV_PATH" "$tmp_file"; then
    rm -f "$tmp_file"
    cp "$VSCODE_ARGV_PATH" "${VSCODE_ARGV_PATH}.bak"
    cat >"$VSCODE_ARGV_PATH" <<'EOF'
{
  "password-store": "gnome-libsecret"
}
EOF
    return 0
  fi

  mv "$tmp_file" "$VSCODE_ARGV_PATH"
}

ensure_vscode_code_flags() {
  printf 'Configuring the code launcher to pass --password-store=gnome-libsecret...\n'
  mkdir -p "$(dirname "$VSCODE_FLAGS_PATH")"

  if [[ ! -f "$VSCODE_FLAGS_PATH" ]]; then
    cat >"$VSCODE_FLAGS_PATH" <<EOF
$VSCODE_PASSWORD_STORE_FLAG
EOF
    return 0
  fi

  if grep -Fqx "$VSCODE_PASSWORD_STORE_FLAG" "$VSCODE_FLAGS_PATH"; then
    return 0
  fi

  printf '\n%s\n' "$VSCODE_PASSWORD_STORE_FLAG" >>"$VSCODE_FLAGS_PATH"
}

install_sway_stack() {
  require_config_source
  require_cmd yay

  install_packages
  deploy_configs
  ensure_sway_dbus_environment
  ensure_vscode_password_store
  ensure_vscode_code_flags
  print_completion_message
}

install_vscode_keyring_fix() {
  require_cmd yay

  install_vscode_keyring_packages
  ensure_sway_dbus_environment
  ensure_vscode_password_store
  ensure_vscode_code_flags
  print_vscode_keyring_completion_message
}

update_configs_only() {
  require_config_source
  deploy_configs
  ensure_sway_dbus_environment
  print_completion_message
}

install_fcitx_stack() {
  local mode="${1:-menu}"

  case "$mode" in
    menu)
      printf 'Running fcitx5 customizer interactive menu...\n'
      run_remote_bash_script "$FCITX_CUSTOMIZER_URL"
      ;;
    recommend)
      printf 'Running fcitx5 customizer with recommended preset...\n'
      run_remote_bash_script "$FCITX_CUSTOMIZER_URL" recommend
      ;;
    *)
      printf 'Unknown fcitx mode: %s\n' "$mode" >&2
      exit 1
      ;;
  esac
}

print_menu() {
  cat <<'EOF'
Select an action:
  1. Install and configure SwayFX + Waybar desktop
  2. Update configs only (no package install)
  3. Run fcitx5 customizer
  4. Install SwayFX + Waybar desktop and run fcitx5 customizer
  5. Install SwayFX + Waybar desktop and run fcitx5 customizer recommended preset
  6. Run fcitx5 customizer recommended preset
  7. Fix VS Code keyring support for Sway
  q. Quit
EOF
}

interactive_menu() {
  local choice

  print_menu
  printf 'Enter choice: '
  read -r choice

  case "$choice" in
    1) install_sway_stack ;;
    2) update_configs_only ;;
    3) install_fcitx_stack menu ;;
    4)
      install_sway_stack
      install_fcitx_stack menu
      ;;
    5)
      install_sway_stack
      install_fcitx_stack recommend
      ;;
    6) install_fcitx_stack recommend ;;
    7) install_vscode_keyring_fix ;;
    q|Q) exit 0 ;;
    *)
      printf 'Invalid choice: %s\n' "$choice" >&2
      exit 1
      ;;
  esac
}

main() {
  case "${1:-menu}" in
    menu)
      interactive_menu
      ;;
    sway)
      install_sway_stack
      ;;
    config)
      update_configs_only
      ;;
    fcitx)
      install_fcitx_stack menu
      ;;
    fcitx-recommend)
      install_fcitx_stack recommend
      ;;
    vscode-keyring)
      install_vscode_keyring_fix
      ;;
    all)
      install_sway_stack
      install_fcitx_stack menu
      ;;
    all-recommend)
      install_sway_stack
      install_fcitx_stack recommend
      ;;
    *)
      cat <<'EOF' >&2
Usage:
  ./install.sh                # open selection menu
  ./install.sh sway           # install packages and deploy configs
  ./install.sh config         # deploy configs only
  ./install.sh fcitx          # run fcitx5 customizer menu
  ./install.sh fcitx-recommend
  ./install.sh vscode-keyring # fix VS Code keyring support on sway
  ./install.sh all
  ./install.sh all-recommend
EOF
      exit 1
      ;;
  esac
}

main "$@"
