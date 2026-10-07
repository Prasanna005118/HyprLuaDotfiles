#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Dotfiles Installer
# ============================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOME_DIR="$HOME"
CONFIG_DIR="$HOME_DIR/.config"

STATE_DIR="$HOME_DIR/.local/state/dotfiles"
BACKUP_DIR="$STATE_DIR/backups"

INSTALLED_PKG_FILE="$STATE_DIR/installed-packages.txt"
INSTALLED_AUR_FILE="$STATE_DIR/installed-aur-packages.txt"
BACKUP_MANIFEST="$STATE_DIR/backups.txt"
INSTALL_MARKER="$STATE_DIR/installed"

PACKAGES_FILE="$REPO_DIR/packages.txt"
AUR_PACKAGES_FILE="$REPO_DIR/aur-packages.txt"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
CURRENT_BACKUP_DIR="$BACKUP_DIR/$TIMESTAMP"

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

info() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
  echo -e "${GREEN}[OK]${RESET} $1"
}

warning() {
  echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

section() {
  echo
  echo -e "${CYAN}============================================================${RESET}"
  echo -e "${CYAN} $1${RESET}"
  echo -e "${CYAN}============================================================${RESET}"
  echo
}

# ------------------------------------------------------------
# Safety checks
# ------------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
  error "Do not run this script as root."
  exit 1
fi

if [[ ! -f "$PACKAGES_FILE" ]]; then
  error "Missing packages.txt"
  exit 1
fi

if [[ ! -f "$AUR_PACKAGES_FILE" ]]; then
  error "Missing aur-packages.txt"
  exit 1
fi

# ============================================================
# EXISTING INSTALLATION CHECK
# ============================================================

if [[ -f "$INSTALL_MARKER" ]]; then

  section "Dotfiles already installed"

  warning "An existing Dotfiles installation was detected."
  echo
  echo "Installation state:"
  echo "  $STATE_DIR"
  echo
  echo "This installer will NOT run again."
  echo
  echo "This prevents an existing Dotfiles installation from"
  echo "being backed up over your original configuration."
  echo
  echo "If you want to reinstall:"
  echo
  echo "  1. Run:"
  echo
  echo "       ~/Dotfiles/uninstall.sh"
  echo
  echo "  2. Then run:"
  echo
  echo "       ~/Dotfiles/install.sh"
  echo

  exit 1
fi

# ------------------------------------------------------------
# Detect partial/old state
# ------------------------------------------------------------

if [[ -d "$STATE_DIR" ]]; then

  section "Previous installation state detected"

  warning "The state directory exists, but the installation marker is missing."
  echo
  echo "State directory:"
  echo "  $STATE_DIR"
  echo

  read -r -p "Remove the old state and continue? [y/N] " ANSWER

  if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
    info "Installation cancelled."
    exit 0
  fi

  rm -rf "$STATE_DIR"

  success "Old state removed."
fi

# ------------------------------------------------------------
# Create state directories
# ------------------------------------------------------------

mkdir -p "$STATE_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$CURRENT_BACKUP_DIR"

touch "$INSTALLED_PKG_FILE"
touch "$INSTALLED_AUR_FILE"
touch "$BACKUP_MANIFEST"

# ------------------------------------------------------------
# Backup function
# ------------------------------------------------------------

backup_path() {

  local source="$1"

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    return 0
  fi

  local relative_path

  if [[ "$source" == "$HOME_DIR/"* ]]; then
    relative_path="${source#$HOME_DIR/}"
  else
    relative_path="$(basename "$source")"
  fi

  local destination="$CURRENT_BACKUP_DIR/$relative_path"

  mkdir -p "$(dirname "$destination")"

  cp -a "$source" "$destination"

  echo "$source|$destination" >>"$BACKUP_MANIFEST"

  success "Backed up: $source"
}

# ============================================================
# Package installation
# ============================================================

section "Installing packages"

OFFICIAL_BEFORE="$(mktemp)"
AUR_BEFORE="$(mktemp)"

cleanup_temp() {
  rm -f "$OFFICIAL_BEFORE"
  rm -f "$AUR_BEFORE"
  rm -f /tmp/dotfiles-official-after
  rm -f /tmp/dotfiles-aur-after
}

trap cleanup_temp EXIT

pacman -Qq | sort >"$OFFICIAL_BEFORE"

if command -v yay >/dev/null 2>&1; then
  yay -Qq | sort >"$AUR_BEFORE"
else
  touch "$AUR_BEFORE"
fi

info "Installing official repository packages..."

grep -vE '^[[:space:]]*(#|$)' "$PACKAGES_FILE" |
  sudo pacman -S --needed -

success "Official packages installed."

# ============================================================
# Install yay if required
# ============================================================

if grep -vE '^[[:space:]]*(#|$)' "$AUR_PACKAGES_FILE" | grep -q .; then

  if ! command -v yay >/dev/null 2>&1; then

    section "Installing yay"

    info "yay is required for AUR packages."

    sudo pacman -S --needed git base-devel

    TEMP_DIR="$(mktemp -d)"

    git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay"

    (
      cd "$TEMP_DIR/yay"
      makepkg -si --noconfirm
    )

    rm -rf "$TEMP_DIR"

    success "yay installed."
  fi

  section "Installing AUR packages"

  grep -vE '^[[:space:]]*(#|$)' "$AUR_PACKAGES_FILE" |
    yay -S --needed -

  success "AUR packages installed."
fi

# ============================================================
# Record newly installed packages
# ============================================================

pacman -Qq | sort >/tmp/dotfiles-official-after

comm -13 "$OFFICIAL_BEFORE" /tmp/dotfiles-official-after \
  >"$INSTALLED_PKG_FILE"

if command -v yay >/dev/null 2>&1; then

  yay -Qq | sort >/tmp/dotfiles-aur-after

  comm -13 "$AUR_BEFORE" /tmp/dotfiles-aur-after \
    >"$INSTALLED_AUR_FILE"

fi

# ============================================================
# Configuration deployment
# ============================================================

section "Deploying configuration"

CONFIGS=(
  "hypr"
  "waybar"
  "rofi"
  "swaync"
  "wlogout"
  "kitty"
  "fish"
  "nvim"
  "cava"
)

for config in "${CONFIGS[@]}"; do

  SOURCE="$REPO_DIR/$config"
  DEST="$CONFIG_DIR/$config"

  if [[ ! -e "$SOURCE" ]]; then
    continue
  fi

  info "Installing $config..."

  if [[ -e "$DEST" || -L "$DEST" ]]; then
    backup_path "$DEST"
    rm -rf "$DEST"
  fi

  mkdir -p "$(dirname "$DEST")"

  cp -a "$SOURCE" "$DEST"

  success "$config installed."

done

# ============================================================
# Starship
# ============================================================

if [[ -f "$REPO_DIR/starship.toml" ]]; then

  section "Installing Starship configuration"

  STARSHIP_DEST="$CONFIG_DIR/starship.toml"

  if [[ -e "$STARSHIP_DEST" || -L "$STARSHIP_DEST" ]]; then
    backup_path "$STARSHIP_DEST"
    rm -f "$STARSHIP_DEST"
  fi

  mkdir -p "$CONFIG_DIR"

  cp -a "$REPO_DIR/starship.toml" "$STARSHIP_DEST"

  success "starship.toml installed."

fi

# ============================================================
# Replace __HOME__ placeholders
# ============================================================

section "Making configuration portable"

info "Replacing __HOME__ with $HOME_DIR"

CONFIG_ROOTS=(
  "$CONFIG_DIR/hypr"
  "$CONFIG_DIR/waybar"
  "$CONFIG_DIR/rofi"
  "$CONFIG_DIR/swaync"
  "$CONFIG_DIR/wlogout"
  "$CONFIG_DIR/kitty"
  "$CONFIG_DIR/fish"
  "$CONFIG_DIR/nvim"
  "$CONFIG_DIR/cava"
)

for root in "${CONFIG_ROOTS[@]}"; do

  [[ -d "$root" ]] || continue

  while IFS= read -r -d '' file; do

    if grep -Iq . "$file" 2>/dev/null &&
      grep -q '__HOME__' "$file" 2>/dev/null; then

      sed -i "s#__HOME__#$HOME_DIR#g" "$file"

    fi

  done < <(find "$root" -type f -print0)

done

success "Portable paths configured."

# ============================================================
# Make scripts executable
# ============================================================

section "Setting script permissions"

for root in "${CONFIG_ROOTS[@]}"; do

  [[ -d "$root" ]] || continue

  find "$root" \
    -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \; 2>/dev/null || true

done

success "Script permissions configured."

# ============================================================
# User directories
# ============================================================

mkdir -p \
  "$HOME_DIR/Pictures" \
  "$HOME_DIR/Pictures/Screenshots" \
  "$HOME_DIR/Downloads"

# ============================================================
# Neovim / LazyVim
# ============================================================

if [[ -d "$CONFIG_DIR/nvim" ]] &&
  command -v nvim >/dev/null 2>&1; then

  section "Bootstrapping Neovim"

  info "Launching Neovim to bootstrap plugins..."

  timeout 30 nvim --headless \
    "+Lazy! sync" \
    "+qa" \
    >/tmp/dotfiles-nvim.log 2>&1 || true

  success "Neovim bootstrap attempted."

fi

# ============================================================
# CREATE INSTALLATION MARKER
# ============================================================

cat >"$INSTALL_MARKER" <<EOF
Dotfiles installation
Repository: $REPO_DIR
Installed: $(date)
Backup: $CURRENT_BACKUP_DIR
EOF

# ============================================================
# Verification
# ============================================================

section "Verifying installation"

FAILED=0

COMMANDS=(
  "hyprland"
  "hyprlock"
  "hypridle"
  "waybar"
  "rofi"
  "swaync"
  "wlogout"
  "kitty"
  "nvim"
  "grim"
  "slurp"
  "swappy"
  "wl-copy"
  "wpctl"
  "playerctl"
  "matugen"
  "awww"
)

for cmd in "${COMMANDS[@]}"; do

  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${RESET} $cmd"
  else
    echo -e "${RED}✗${RESET} $cmd"
    FAILED=1
  fi

done

# ============================================================
# Summary
# ============================================================

section "Installation complete"

echo -e "${GREEN}Dotfiles installed successfully.${RESET}"
echo
echo "Repository:"
echo "  $REPO_DIR"
echo
echo "State:"
echo "  $STATE_DIR"
echo
echo "Backup:"
echo "  $CURRENT_BACKUP_DIR"
echo
echo "Installed packages:"
echo "  $INSTALLED_PKG_FILE"
echo
echo "Installed AUR packages:"
echo "  $INSTALLED_AUR_FILE"
echo

if [[ "$FAILED" -eq 0 ]]; then
  echo -e "${GREEN}All rice components were detected.${RESET}"
else
  echo -e "${YELLOW}Some components were not detected.${RESET}"
  echo "Check /tmp/dotfiles-nvim.log if Neovim had problems."
fi

echo
echo "Next steps:"
echo "  1. Log out."
echo "  2. Select Hyprland."
echo "  3. Log back in."
echo
echo "To uninstall:"
echo "  $REPO_DIR/uninstall.sh"
echo
