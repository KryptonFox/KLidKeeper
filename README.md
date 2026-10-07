# KLidKeeper (KDE Plasma 6)

**KLidKeeper** (`org.kde.klid`) — нативный виджет и C++ плагин для панели задач и системного трея **KDE Plasma 6**, предотвращающий переход ноутбука в спящий режим при закрытии крышки.

[English description below](#english)

---

## 🇷🇺 Русский

### Возможности и настройки

1. **Предотвращать сон при закрытии крышки:**
   - Блокирует переход в сон через D-Bus интерфейс `systemd-logind` (`handle-lid-switch:sleep`).
   - Ноутбук продолжает работать при закрытой крышке (фоновые сборки, воспроизведение музыки, серверные задачи, скачивание файлов).
2. **Действие с экраном при закрытии крышки:**
   - 🖥️ **Выключать экран (DPMS Off)** — **опция по умолчанию**: при закрытии крышки подсветка матрицы выключается (через `kscreen-doctor` на Wayland или `xset` на X11), предотвращая нагрев матрицы о клавиатуру и экономя батарею. При открытии экран мгновенно зажигается.
   - 🔅 **Понижать яркость дисплея до минимума:** снижает подсветку до 0% при закрытии и восстанавливает прежний уровень при открытии.
   - 💡 **Не изменять:** экран остаётся включенным.
3. **Предотвращать блокировку экрана:**
   - Блокирует автоблокировку сессии через `org.freedesktop.ScreenSaver` во время активности режима бодрствования.
4. **Удобное управление:**
   - **Средний клик (колесико мыши)** по иконке в трее или на панели мгновенно включает/выключает режим без открытия всплывающего окна.
   - **Левый клик:** открывает окно настроек.
   - **Динамическая иконка:** наполненная чашка кофе при активном режиме, пустая — в обычном режиме сна.
5. **Мультиязычность (i18n):**
   - Автоматически использует системный язык пользователя (доступны русский и английский переводы через Gettext / KF6I18n).

---

### Установка из AUR (Arch Linux / CachyOS / Manjaro)

С помощью любого AUR-хелпера:

```bash
# Версия из Git (всегда свежий код)
paru -S plasma6-applets-klidkeeper-git
# или
yay -S plasma6-applets-klidkeeper-git
```

Или вручную через `makepkg`:
```bash
git clone https://aur.archlinux.org/plasma6-applets-klidkeeper-git.git
cd plasma6-applets-klidkeeper-git
makepkg -si
```

---

### Локальная сборка и установка (в `~/.local` без root)

```bash
# 1. Сборка
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local
cmake --build build

# 2. Установка
cmake --install build

# 3. Обновление плазмоида в Plasma
kpackagetool6 --type Plasma/Applet --upgrade package/ || kpackagetool6 --type Plasma/Applet --install package/
```

### Предпросмотр без перезапуска Plasma:
```bash
# На русском
LANGUAGE=ru plasmoidviewer -f planar -a package/

# На английском
LANGUAGE=en plasmoidviewer -f planar -a package/
```

---

### Инструкция для публикации в AUR

Пакеты подготовлены в папке `aur/`:
- `aur/PKGBUILD` и `aur/.SRCINFO` — для пакета `plasma6-applets-klidkeeper-git`
- `aur/release/` — для релизного пакета `plasma6-applets-klidkeeper`

**Шаги для залития в AUR:**
1. Зарегистрируйтесь на [aur.archlinux.org](https://aur.archlinux.org) и добавьте свой SSH-ключ в настройках профиля.
2. Склонируйте пустой репозиторий пакета с AUR:
   ```bash
   git clone ssh://aur@aur.archlinux.org/plasma6-applets-klidkeeper-git.git
   cd plasma6-applets-klidkeeper-git
   ```
3. Скопируйте файлы сборки из этого репозитория:
   ```bash
   cp ~/Dev/cpp/KLidKeeper/aur/PKGBUILD .
   cp ~/Dev/cpp/KLidKeeper/aur/.SRCINFO .
   ```
4. Зафиксируйте и отправьте изменения:
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Initial commit for plasma6-applets-klidkeeper-git"
   git push origin master
   ```

---

<a name="english"></a>
## 🇬🇧 English

Native KDE Plasma 6 widget and C++ extension plugin designed to keep your laptop awake when the lid is closed.

### Features
- **Prevent sleep on lid close:** Calls `systemd-logind` Inhibit lock (`handle-lid-switch:sleep`).
- **Screen action on lid close:**
  - 🖥️ **Turn off screen (DPMS Off)** *(Default)*: Powers off screen backlight while lid is closed, turns back on immediately when opened.
  - 🔅 **Dim display brightness:** Reduces brightness to minimum on lid close, restores upon opening.
  - 💡 **Do nothing:** Keeps display on.
- **Prevent screen lock:** Inhibits session locker via `org.freedesktop.ScreenSaver`.
- **Tray & Panel integration:** Middle-click toggles mode instantly; dynamic coffee cup icon.
- **Full i18n support:** System locale detection with built-in English and Russian translations.

### License
GPL-2.0-or-later
