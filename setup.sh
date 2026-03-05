#!/bin/bash
# =============================================================================
# macOS Apps -> External SSD Setup Script
# Moves WhatsApp and Telegram (app binaries + compatible data folders) to an
# external SSD and replaces them with symlinks on the main drive.
#
# Usage:
#   ./setup.sh                        # uses /Volumes/HIKSEMI by default
#   ./setup.sh /Volumes/MY_DRIVE      # custom external drive
# =============================================================================

set -e

EXTERNAL="${1:-/Volumes/HIKSEMI}"
APPS_SRC="/Applications"
LIB="$HOME/Library"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}> $1${NC}"; }
success() { echo -e "${GREEN}+ $1${NC}"; }
warn()    { echo -e "${YELLOW}! $1${NC}"; }
error()   { echo -e "${RED}x $1${NC}"; exit 1; }

echo ""
echo "  macOS Apps -> External SSD"
echo "  External drive: $EXTERNAL"
echo ""

[[ -d "$EXTERNAL" ]] || error "External drive not found at '$EXTERNAL'. Is it mounted?"

info "Quitting WhatsApp and Telegram..."
osascript -e 'quit app "WhatsApp"' 2>/dev/null || true
osascript -e 'quit app "Telegram"' 2>/dev/null || true
sleep 2

mkdir -p "$EXTERNAL/Applications"
mkdir -p "$EXTERNAL/Library/Application Support"
mkdir -p "$EXTERNAL/Library/Group Containers"
mkdir -p "$EXTERNAL/Library/Containers"

# Move a path to external SSD and symlink back. Idempotent.
move_and_link() {
    local src="$1"
    local dst="$2"

    if [[ -L "$src" ]]; then
        warn "Already symlinked, skipping: $(basename "$src")"
        return
    fi
    if [[ ! -e "$src" ]]; then
        warn "Not found, skipping: $src"
        return
    fi

    local size
    size=$(du -sh "$src" 2>/dev/null | cut -f1)
    info "Moving ($size): $(basename "$src")"
    mkdir -p "$(dirname "$dst")"
    mv "$src" "$dst"
    ln -s "$dst" "$src"
    success "$(basename "$src") symlinked to external SSD"
}

# Move an app binary (requires sudo)
move_app() {
    local app="$1"
    local src="$APPS_SRC/$app"
    local dst="$EXTERNAL/Applications/$app"

    if [[ -L "$src" ]]; then
        warn "Already symlinked, skipping: $app"
        return
    fi
    if [[ ! -e "$src" ]]; then
        warn "Not found, skipping: $src"
        return
    fi

    local size
    size=$(du -sh "$src" 2>/dev/null | cut -f1)
    info "Moving ($size): $app (requires sudo)"
    sudo mv "$src" "$dst"
    sudo ln -s "$dst" "$src"
    success "$app symlinked to external SSD"
}

# -----------------------------------------------------------------------------
# WhatsApp
# -----------------------------------------------------------------------------
if [[ -e "$APPS_SRC/WhatsApp.app" || -L "$APPS_SRC/WhatsApp.app" ]]; then
    echo ""
    echo "  WhatsApp"
    echo "  --------"
    move_app "WhatsApp.app"
    move_and_link \
        "$LIB/Containers/desktop.WhatsApp/Data" \
        "$EXTERNAL/Library/Containers/desktop.WhatsApp/Data"
    # NOTE: The following folders crash WhatsApp when symlinked (message DB):
    #   ~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared
    #   ~/Library/Containers/net.whatsapp.WhatsApp/Data
else
    warn "WhatsApp not found in /Applications, skipping."
fi

# -----------------------------------------------------------------------------
# Telegram
# -----------------------------------------------------------------------------
if [[ -e "$APPS_SRC/Telegram.app" || -L "$APPS_SRC/Telegram.app" ]]; then
    echo ""
    echo "  Telegram"
    echo "  --------"
    move_app "Telegram.app"
    move_and_link \
        "$LIB/Application Support/Telegram Desktop" \
        "$EXTERNAL/Library/Application Support/Telegram Desktop"
    # NOTE: The following folder crashes Telegram when symlinked (message DB):
    #   ~/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram
else
    warn "Telegram not found in /Applications, skipping."
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "  Summary"
echo "  -------"
echo ""

print_status() {
    local path="$1"
    local label="$2"
    if [[ -L "$path" ]]; then
        echo -e "  ${GREEN}[symlink]${NC} $label"
    elif [[ -e "$path" ]]; then
        echo -e "  ${YELLOW}[main SSD]${NC} $label"
    else
        echo -e "  ${RED}[missing]${NC} $label"
    fi
}

print_status "$APPS_SRC/WhatsApp.app"                        "WhatsApp.app"
print_status "$LIB/Containers/desktop.WhatsApp/Data"         "desktop.WhatsApp/Data"
print_status "$APPS_SRC/Telegram.app"                        "Telegram.app"
print_status "$LIB/Application Support/Telegram Desktop"     "Telegram Desktop (App Support)"

echo ""
warn "Both apps require the external drive to be mounted to launch."
echo ""
