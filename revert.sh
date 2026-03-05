#!/bin/bash
# =============================================================================
# macOS Apps -> External SSD Revert Script
# Moves everything back to the main SSD and removes symlinks.
#
# Usage:
#   ./revert.sh                        # uses /Volumes/HIKSEMI by default
#   ./revert.sh /Volumes/MY_DRIVE      # custom external drive
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
echo "  External SSD -> macOS (revert)"
echo "  External drive: $EXTERNAL"
echo ""

[[ -d "$EXTERNAL" ]] || error "External drive not found at '$EXTERNAL'. Is it mounted?"

info "Quitting WhatsApp and Telegram..."
osascript -e 'quit app "WhatsApp"' 2>/dev/null || true
osascript -e 'quit app "Telegram"' 2>/dev/null || true
sleep 2

# Remove symlink and move data back from external SSD
restore() {
    local link="$1"
    local src="$2"

    if [[ ! -L "$link" ]]; then
        warn "Not a symlink, skipping: $link"
        return
    fi
    if [[ ! -e "$src" ]]; then
        warn "Source not found on external SSD, skipping: $src"
        return
    fi

    info "Restoring: $(basename "$link")"
    rm "$link"
    mv "$src" "$link"
    success "$(basename "$link") restored to main SSD"
}

restore_app() {
    local app="$1"
    local link="$APPS_SRC/$app"
    local src="$EXTERNAL/Applications/$app"

    if [[ ! -L "$link" ]]; then
        warn "Not a symlink, skipping: $app"
        return
    fi
    if [[ ! -e "$src" ]]; then
        warn "Not found on external SSD, skipping: $app"
        return
    fi

    info "Restoring: $app (requires sudo)"
    sudo rm "$link"
    sudo mv "$src" "$link"
    success "$app restored to main SSD"
}

echo ""
echo "  WhatsApp"
echo "  --------"
restore_app "WhatsApp.app"
restore \
    "$LIB/Containers/desktop.WhatsApp/Data" \
    "$EXTERNAL/Library/Containers/desktop.WhatsApp/Data"

echo ""
echo "  Telegram"
echo "  --------"
restore_app "Telegram.app"
restore \
    "$LIB/Application Support/Telegram Desktop" \
    "$EXTERNAL/Library/Application Support/Telegram Desktop"

echo ""
success "All done. Both apps are back on the main SSD."
echo ""
