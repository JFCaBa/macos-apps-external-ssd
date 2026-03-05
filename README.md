# Run WhatsApp & Telegram from an External SSD on macOS

Free up internal storage on a nearly-full Mac by moving WhatsApp and Telegram
to a small external SSD. The apps continue to work normally — macOS sees them
in `/Applications` via symlinks.

![HIKSEMI SSD plugged into MacBook Air](images/hiksemi-macbook.jpg)

---

## Why

WhatsApp and Telegram can easily consume **1–2 GB** of internal storage between
their app binaries, caches, and message data. On a MacBook Air with limited
internal SSD space, that adds up fast.

The trick: move what you can to an external drive and leave a symlink behind so
macOS and Spotlight still find everything in the expected places.

I use a **HIKSEMI 512 GB USB-C SSD** — it's tiny enough to leave plugged in
permanently on one USB-C port while keeping the other free for charging or a dock.

---

## What gets moved

Tested on macOS 26.3 (Sequoia), MacBook Air M1.

| Item | Size* | Moveable? |
|------|-------|-----------|
| `WhatsApp.app` | ~225 MB | yes |
| `Telegram.app` | ~139 MB | yes |
| `Containers/desktop.WhatsApp/Data` | ~286 MB | yes |
| `Application Support/Telegram Desktop` | ~80 MB | yes |
| `Group Containers/group.net.whatsapp.WhatsApp.shared` | ~67 MB | NO — crashes |
| `Containers/net.whatsapp.WhatsApp/Data` | ~13 MB | NO — crashes |
| `Group Containers/6N38VWS5BX.ru.keepcoder.Telegram` | ~510 MB | NO — crashes |

**Total freed: ~730 MB**

The folders marked NO contain the primary message databases. Both apps perform
integrity checks on startup and intentionally crash if those folders are
accessed through a symlink.

*Sizes vary depending on your usage.

---

## Requirements

- macOS (tested on macOS 26 / Sequoia)
- An external SSD formatted as **APFS** or **Mac OS Extended (Journaled)**
- WhatsApp and/or Telegram installed from the App Store

---

## Quick start

```bash
git clone https://github.com/YOUR_USERNAME/macos-apps-external-ssd
cd macos-apps-external-ssd
chmod +x setup.sh revert.sh

# Default: expects drive mounted at /Volumes/HIKSEMI
./setup.sh

# Custom drive name
./setup.sh /Volumes/MY_DRIVE
```

The script will:
1. Quit both apps
2. Move the app binaries to the external SSD (requires sudo for `/Applications`)
3. Move the compatible data folders
4. Create symlinks in their original locations
5. Print a summary

---

## Revert

To move everything back to the main SSD:

```bash
./revert.sh

# or with a custom drive
./revert.sh /Volumes/MY_DRIVE
```

---

## Manual steps

If you prefer to do it yourself:

```bash
EXTERNAL="/Volumes/HIKSEMI"

# Quit apps first
osascript -e 'quit app "WhatsApp"'; osascript -e 'quit app "Telegram"'
sleep 2

mkdir -p "$EXTERNAL/Applications"
mkdir -p "$EXTERNAL/Library/Application Support"
mkdir -p "$EXTERNAL/Library/Containers/desktop.WhatsApp"

# App binaries (sudo required)
sudo mv /Applications/WhatsApp.app "$EXTERNAL/Applications/"
sudo ln -s "$EXTERNAL/Applications/WhatsApp.app" /Applications/WhatsApp.app

sudo mv /Applications/Telegram.app "$EXTERNAL/Applications/"
sudo ln -s "$EXTERNAL/Applications/Telegram.app" /Applications/Telegram.app

# WhatsApp data
mv "$HOME/Library/Containers/desktop.WhatsApp/Data" "$EXTERNAL/Library/Containers/desktop.WhatsApp/"
ln -s "$EXTERNAL/Library/Containers/desktop.WhatsApp/Data" "$HOME/Library/Containers/desktop.WhatsApp/Data"

# Telegram data
mv "$HOME/Library/Application Support/Telegram Desktop" "$EXTERNAL/Library/Application Support/"
ln -s "$EXTERNAL/Library/Application Support/Telegram Desktop" "$HOME/Library/Application Support/Telegram Desktop"
```

---

## Important notes

- **The external drive must be mounted** for WhatsApp and Telegram to launch.
  If you unplug it, the apps won't open.
- The script is **idempotent** — safe to run multiple times.
- Message history stays on the main SSD (in the folders that can't be moved).

---

## The hardware

<!-- Add your photos here -->

![HIKSEMI SSD](images/hiksemi-ssd.jpg)

The [HIKSEMI 512 GB USB-C SSD](https://www.hiksemi.com) fits flush against the
MacBook Air's body. Because it uses USB-C directly (no cable), it occupies one
port while leaving the other free for charging or accessories.

---

## License

MIT
