# KLidKeeper

A native KDE Plasma 6 widget and C++ plugin that inhibits system sleep when closing your laptop lid, with configurable screen power actions.

## How It Works

KLidKeeper runs directly within the KDE Plasma desktop shell via a native C++ QML plugin and communicates with Linux system services over D-Bus without requiring root privileges:

- **Sleep Inhibition (`systemd-logind`)**:  
  When stay-awake mode is enabled, the plugin issues an `Inhibit` call to `org.freedesktop.login1.Manager` on the system D-Bus with `handle-lid-switch:sleep` and mode `block`. `systemd-logind` returns a dedicated file descriptor. As long as KLidKeeper holds this file descriptor open, logind suppresses system suspend when the lid is closed. Disabling the toggle closes the descriptor, instantly restoring normal sleep behavior.
- **Lid Sensor Detection (`KDE Solid` & `logind`)**:  
  KLidKeeper listens to the `lidClosedChanged` signal from KDE's `org.kde.Solid.PowerManagement` session service and queries initial status via `isLidClosed()`. It additionally tracks `org.freedesktop.login1` `PropertiesChanged` for the `LidClosed` property as a fallback, ensuring reliable detection across various laptop hardware.
- **Display Power Management**:  
  When the lid closes while stay-awake mode is active:
  - **DPMS Off (Turn off screen)**: Checks `$XDG_SESSION_TYPE`. Under **Wayland**, invokes `kscreen-doctor --dpms off` to turn off display backlights (falling back to `xset`). Under **X11**, invokes `xset dpms force off` (falling back to `kscreen-doctor`). When the lid is reopened, sends the corresponding `on` command.
  - **Dim display brightness**: Queries `org.kde.Solid.PowerManagement.Actions.BrightnessControl` over session D-Bus to record current brightness level, then lowers it to minimum (`brightnessMin`). Restores the previous brightness value when opened.
- **Screen Lock Inhabitation (`org.freedesktop.ScreenSaver`)**:  
  When "Prevent screen lock" is enabled, requests an inhibit cookie from `org.freedesktop.ScreenSaver` on the session bus, suppressing the lock screen while awake mode is active.

## System Requirements

| Component | Requirement | Details |
| :--- | :--- | :--- |
| **Operating System** | Linux with `systemd` | Uses `systemd-logind` for lid inhibit locks. |
| **Desktop Environment** | KDE Plasma 6.0+ | Built with Qt 6 (`qt6-base`, `qt6-declarative`), KDE Frameworks 6 (`libplasma`, `ki18n`, `extra-cmake-modules`). |
| **Display Server** | Wayland or X11 | Both supported. Wayland uses `kscreen-doctor`; X11 uses `xset`. |
| **Hardware** | Laptop with ACPI lid switch | Standard Linux kernel lid button device (`/dev/input/` or `/proc/acpi/button/lid/`). |
| **Privileges** | Standard user (Unprivileged) | No `root` or `sudo` required at runtime. |

> **Note on `logind.conf`**: Your `/etc/systemd/logind.conf` should keep default settings (e.g. `HandleLidSwitch=suspend`). You do **not** need to edit config files or disable sleep globally; KLidKeeper dynamically overrides lid actions via the standard logind Inhibit API only when you turn it on.

## Features

- **Prevent Sleep on Lid Close**: Takes a `systemd-logind` inhibit lock (`handle-lid-switch:sleep`) so background tasks, downloads, or media playback continue uninterrupted.
- **Configurable Screen Actions**:
  - **Turn off screen (DPMS Off)** *(Default)*: Turns off display backlight while the lid is closed to save power and prevent display heating against the keyboard. Restores immediately upon opening.
  - **Dim display brightness**: Sets backlight brightness to minimum on lid close and restores previous level upon opening.
  - **Do nothing**: Keeps display state unchanged.
- **Inhibit Screen Lock**: Optionally prevents session lock while stay-awake mode is active (`org.freedesktop.ScreenSaver`).
- **System Tray Integration**:
  - **Middle-click** icon to quickly toggle stay-awake mode.
  - **Left-click** icon to open settings popup.
  - Dynamic coffee cup status icon matching system tray style.
- **Localization**: Built-in English and Russian translations.

## Requirements

### Build Dependencies
- KDE Plasma 6 (`libplasma` >= 6.0)
- KF6 (`ki18n`, `extra-cmake-modules`)
- Qt 6 (`qt6-base`, `qt6-declarative`)
- `systemd` (`systemd-libs`, `systemd-logind`)

### Runtime Dependencies
- `kscreen-doctor`: For display power management on Wayland *(included in standard Plasma installations)*
- `xorg-xset`: For display power management on X11 *(optional, only needed on X11)*

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
