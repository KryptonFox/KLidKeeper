# KLidKeeper

A native KDE Plasma 6 widget and C++ plugin that inhibits system sleep when closing your laptop lid, with configurable screen power actions.

## Features

- **Prevent Sleep on Lid Close**: Takes a `systemd-logind` inhibit lock (`handle-lid-switch:sleep`) so background tasks, downloads, or media playback continue uninterrupted.
- **Configurable Screen Actions**:
  - **Turn off screen (DPMS Off)** *(Default)*: Turns off display backlight while the lid is closed (via `kscreen-doctor` on Wayland or `xset` on X11) to save power and prevent display heating against the keyboard. Restores immediately upon opening.
  - **Dim display brightness**: Sets backlight brightness to minimum on lid close and restores previous level upon opening.
  - **Do nothing**: Keeps display state unchanged.
- **Inhibit Screen Lock**: Optionally prevents session lock while stay-awake mode is active (`org.freedesktop.ScreenSaver`).
- **System Tray Integration**:
  - **Middle-click** icon to quickly toggle stay-awake mode.
  - **Left-click** icon to open settings popup.
  - Dynamic coffee cup status icon matching system tray style.
- **Localization**: Built-in English and Russian translations.

## Requirements

- KDE Plasma 6 (`libplasma` >= 6.0)
- KF6 (`ki18n`, `extra-cmake-modules`)
- Qt 6 (`qt6-base`, `qt6-declarative`)
- `systemd` (`systemd-logind`)

### Optional Dependencies
- `kscreen-doctor`: For display power management on Wayland
- `xorg-xset`: For display power management on X11

## Installation

### Arch Linux

Install via AUR helper (once available on AUR):
```bash
paru -S plasma6-applets-klidkeeper-git
# or
yay -S plasma6-applets-klidkeeper-git
```

Or install directly with `makepkg`:
```bash
git clone https://github.com/KryptonFox/KLidKeeper.git
cd KLidKeeper/aur/local
makepkg -si
```

### Building from Source

```bash
cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DKDE_INSTALL_USE_QT_SYS_PATHS=ON

cmake --build build
sudo cmake --install build
```

To reload Plasma and make the applet available in your System Tray:

```bash
systemctl --user restart plasma-plasmashell.service
```

## License

GPL-2.0-or-later
