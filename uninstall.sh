#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Dotfiles Uninstaller
# ============================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOME_DIR="$HOME"
CONFIG_DIR="$HOME_DIR/.config"

STATE_DIR="$HOME_DIR/.local/state/dotfiles"
BACKUP_DIR="$STATE_DIR/backups"

INSTALLED_PKG_FILE="$STATE_DIR/installed-packages.txt"
INSTALLED_AUR_FILE="$STATE_DIR/installed-aur-packages.txt"
BACKUP_MANIFEST="$STATE_DIR/backups.txt"

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
# Safety
# ------------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
    error "Do not run this script as root."
    exit 1
fi

if [[ ! -d "$STATE_DIR" ]]; then
    error "No dotfiles installation state was found."
    echo
    echo "Expected:"
    echo "  $STATE_DIR"
    echo
    echo "The dotfiles may not have been installed using install.sh."
    exit 1
fi

# ------------------------------------------------------------
# Find latest backup
# ------------------------------------------------------------

LATEST_BACKUP=""

if [[ -d "$BACKUP_DIR" ]]; then
    LATEST_BACKUP="$(
        find "$BACKUP_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -printf '%T@ %p\n' 2>/dev/null \
        | sort -n \
        | tail -1 \
        | cut -d' ' -f2-
    )"
fi

# ------------------------------------------------------------
# Confirmation
# ------------------------------------------------------------

section "Dotfiles Uninstaller"

echo "This will undo the dotfiles installation."
echo
echo "Repository:"
echo "  $REPO_DIR"
echo
echo "State:"
echo "  $STATE_DIR"
echo

if [[ -n "$LATEST_BACKUP" ]]; then
    echo "Latest backup:"
    echo "  $LATEST_BACKUP"
else
    echo "Latest backup:"
    echo "  None"
fi

echo
warning "This will remove packages that were installed by install.sh."
warning "Packages that existed before the installation will NOT be removed."
echo

read -r -p "Continue? [y/N] " ANSWER

if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
    echo
    info "Uninstallation cancelled."
    exit 0
fi

# ------------------------------------------------------------
# Restore configuration
# ------------------------------------------------------------

section "Restoring configuration"

if [[ -f "$BACKUP_MANIFEST" && -n "$LATEST_BACKUP" ]]; then

    # Read the manifest backwards so nested paths are handled safely.
    while IFS='|' read -r ORIGINAL BACKUP; do

        [[ -z "$ORIGINAL" ]] && continue
        [[ -z "$BACKUP" ]] && continue

        # Only restore backups belonging to this backup directory.
        if [[ "$BACKUP" != "$LATEST_BACKUP/"* ]]; then
            continue
        fi

        if [[ ! -e "$BACKUP" && ! -L "$BACKUP" ]]; then
            warning "Backup missing: $BACKUP"
            continue
        fi

        info "Restoring: $ORIGINAL"

        # Remove currently installed configuration.
        if [[ -e "$ORIGINAL" || -L "$ORIGINAL" ]]; then
            rm -rf "$ORIGINAL"
        fi

        mkdir -p "$(dirname "$ORIGINAL")"

        cp -a "$BACKUP" "$ORIGINAL"

        success "Restored: $ORIGINAL"

    done < "$BACKUP_MANIFEST"

else
    warning "No configuration backup was found."

    # --------------------------------------------------------
    # No backup exists.
    # Remove configurations installed by the rice.
    # --------------------------------------------------------

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

        DEST="$CONFIG_DIR/$config"

        if [[ -e "$DEST" || -L "$DEST" ]]; then
            info "Removing $DEST"
            rm -rf "$DEST"
            success "Removed $DEST"
        fi

    done

    STARSHIP="$CONFIG_DIR/starship.toml"

    if [[ -e "$STARSHIP" || -L "$STARSHIP" ]]; then
        info "Removing $STARSHIP"
        rm -f "$STARSHIP"
        success "Removed $STARSHIP"
    fi
fi

# ------------------------------------------------------------
# Remove packages installed by install.sh
# ------------------------------------------------------------

section "Removing installed packages"

if [[ -f "$INSTALLED_AUR_FILE" && -s "$INSTALLED_AUR_FILE" ]]; then

    if command -v yay >/dev/null 2>&1; then

        info "Removing AUR packages installed by Dotfiles..."

        mapfile -t AUR_PACKAGES < "$INSTALLED_AUR_FILE"

        if [[ "${#AUR_PACKAGES[@]}" -gt 0 ]]; then
            yay -Rns -- "${AUR_PACKAGES[@]}" || \
                warning "Some AUR packages could not be removed."
        fi

    else
        warning "yay is not installed; skipping recorded AUR packages."
    fi

else
    info "No AUR packages were installed by Dotfiles."
fi


if [[ -f "$INSTALLED_PKG_FILE" && -s "$INSTALLED_PKG_FILE" ]]; then

    info "Removing official packages installed by Dotfiles..."

    mapfile -t OFFICIAL_PACKAGES < "$INSTALLED_PKG_FILE"

    if [[ "${#OFFICIAL_PACKAGES[@]}" -gt 0 ]]; then
        sudo pacman -Rns -- "${OFFICIAL_PACKAGES[@]}" || \
            warning "Some official packages could not be removed."
    fi

else
    info "No official packages were installed by Dotfiles."
fi

# ------------------------------------------------------------
# Remove empty configuration directories
# ------------------------------------------------------------

section "Cleaning empty directories"

for directory in \
    "$CONFIG_DIR/hypr" \
    "$CONFIG_DIR/waybar" \
    "$CONFIG_DIR/rofi" \
    "$CONFIG_DIR/swaync" \
    "$CONFIG_DIR/wlogout" \
    "$CONFIG_DIR/kitty" \
    "$CONFIG_DIR/fish" \
    "$CONFIG_DIR/nvim" \
    "$CONFIG_DIR/cava"
do

    if [[ -d "$directory" ]]; then
        rmdir "$directory" 2>/dev/null || true
    fi

done

# ------------------------------------------------------------
# Remove installer state
# ------------------------------------------------------------

section "Cleaning installer state"

info "Removing installation state..."

rm -rf "$STATE_DIR"

success "Dotfiles installation state removed."

# ------------------------------------------------------------
# Final message
# ------------------------------------------------------------

section "Uninstallation complete"

echo -e "${GREEN}The Dotfiles installation has been removed.${RESET}"
echo
echo "Your previous configurations were restored when backups existed."
echo "Packages that existed before the installation were left untouched."
echo
echo "The repository itself was NOT deleted:"
echo
echo "  $REPO_DIR"
echo
echo "If you want to remove the repository too:"
echo
echo "  rm -rf ~/Dotfiles"
echo
echo "A logout/login may be required for the desktop environment to fully return to its previous state."
echo
