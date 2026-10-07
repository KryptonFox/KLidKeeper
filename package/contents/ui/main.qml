import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.klid 1.0

PlasmoidItem {
    id: root

    // Sizing for popup / desktop / plasmoidviewer
    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Kirigami.Units.gridUnit * 21
    width: implicitWidth
    height: implicitHeight

    // Dynamic icon for Plasma panel & system tray
    Plasmoid.icon: controller.isInhibited ? "caffeine-cup-full" : "caffeine-cup-empty"
    Plasmoid.title: i18n("KLidKeeper")

    // Rich native tooltip
    toolTipMainText: i18n("KLidKeeper")
    toolTipSubText: controller.isInhibited
        ? i18n("Stay Awake: ACTIVE\n• Laptop will NOT sleep on lid close\n• Middle-click: Deactivate\n• Left-click: Open settings")
        : i18n("Stay Awake: INACTIVE\n• Laptop will sleep on lid close\n• Middle-click: Activate\n• Left-click: Open settings")

    LidController {
        id: controller
    }

    // Direct middle-click handler on applet root for system tray
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: controller.toggle()
    }

    // Contextual right-click menu in tray/panel
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: controller.isInhibited ? i18n("Allow sleep on lid close") : i18n("Prevent sleep on lid close")
            icon.name: controller.isInhibited ? "caffeine-cup-empty" : "caffeine-cup-full"
            onTriggered: controller.toggle()
        }
    ]

    // =========================================================================
    // Compact Representation (Panel Icon / System Tray)
    // =========================================================================
    compactRepresentation: MouseArea {
        id: compactArea
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                controller.toggle();
            } else if (mouse.button === Qt.LeftButton) {
                root.expanded = !root.expanded;
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: controller.isInhibited
                ? Qt.resolvedUrl("../icons/caffeine-cup-full.svg")
                : Qt.resolvedUrl("../icons/caffeine-cup-empty.svg")
            fallback: controller.isInhibited ? "caffeine-cup-full" : "caffeine-cup-empty"
            active: compactArea.containsMouse || controller.isInhibited
        }
    }

    // =========================================================================
    // Full Representation (Popup Settings Menu)
    // =========================================================================
    fullRepresentation: PlasmaExtras.Representation {
        id: fullArea

        Layout.minimumWidth: Kirigami.Units.gridUnit * 21
        Layout.preferredWidth: Kirigami.Units.gridUnit * 23
        Layout.maximumWidth: Kirigami.Units.gridUnit * 26

        Layout.minimumHeight: contentLayout.implicitHeight + (header ? header.implicitHeight : 0) + (Kirigami.Units.gridUnit * 2)
        Layout.preferredHeight: Layout.minimumHeight

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: controller.isInhibited
                        ? Qt.resolvedUrl("../icons/caffeine-cup-full.svg")
                        : Qt.resolvedUrl("../icons/caffeine-cup-empty.svg")
                    fallback: controller.isInhibited ? "caffeine-cup-full" : "caffeine-cup-empty"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    active: controller.isInhibited
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        text: i18n("KLidKeeper")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Lid & Sleep Management")
                        opacity: 0.65
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }

                // Minimal status pill
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: statusText.implicitWidth + Kirigami.Units.largeSpacing
                    implicitHeight: statusText.implicitHeight + Kirigami.Units.smallSpacing
                    radius: height / 2
                    color: controller.isInhibited
                        ? Qt.alpha(Kirigami.Theme.highlightColor, 0.2)
                        : Kirigami.Theme.alternateBackgroundColor
                    border.color: controller.isInhibited
                        ? Kirigami.Theme.highlightColor
                        : Qt.alpha(Kirigami.Theme.textColor, 0.2)
                    border.width: 1

                    PlasmaComponents3.Label {
                        id: statusText
                        anchors.centerIn: parent
                        text: controller.isInhibited ? i18n("ACTIVE") : i18n("NORMAL")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.smallFont.pointSize * 0.9
                        color: controller.isInhibited
                            ? Kirigami.Theme.highlightColor
                            : Kirigami.Theme.disabledTextColor
                    }
                }
            }
        }

        contentItem: ColumnLayout {
            id: contentLayout
            spacing: Kirigami.Units.largeSpacing

            // -----------------------------------------------------------------
            // 1. Hero Toggle: Prevent sleep on lid close
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cardRow.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing * 1.5
                color: controller.isInhibited
                    ? Qt.alpha(Kirigami.Theme.highlightColor, 0.12)
                    : (hoverArea.containsMouse ? Qt.alpha(Kirigami.Theme.textColor, 0.06) : Qt.alpha(Kirigami.Theme.textColor, 0.03))
                border.color: controller.isInhibited
                    ? Qt.alpha(Kirigami.Theme.highlightColor, 0.5)
                    : Qt.alpha(Kirigami.Theme.textColor, 0.15)
                border.width: 1

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controller.toggle()

                    RowLayout {
                        id: cardRow
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            source: controller.isInhibited
                                ? Qt.resolvedUrl("../icons/caffeine-cup-full.svg")
                                : Qt.resolvedUrl("../icons/caffeine-cup-empty.svg")
                            fallback: controller.isInhibited ? "caffeine-cup-full" : "caffeine-cup-empty"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            active: controller.isInhibited
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            PlasmaComponents3.Label {
                                text: i18n("Prevent sleep on lid close")
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: controller.isInhibited
                                    ? i18n("Active: Laptop will not sleep when lid is closed")
                                    : i18n("Inactive: Standard sleep behavior on lid close")
                                opacity: 0.75
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        PlasmaComponents3.Switch {
                            id: inhibitSwitch
                            checked: controller.isInhibited
                            onToggled: {
                                if (checked !== controller.isInhibited) {
                                    controller.toggle();
                                }
                            }

                            PlasmaComponents3.ToolTip.visible: hovered
                            PlasmaComponents3.ToolTip.text: checked
                                ? i18n("Click to allow sleep on lid close")
                                : i18n("Click to prevent sleep on lid close")
                        }
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            // -----------------------------------------------------------------
            // 2. Display behavior when lid is closed
            // -----------------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: i18n("When laptop lid is closed:")
                    font.bold: true
                    opacity: 0.85
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }

                QQC2.ButtonGroup {
                    id: screenActionGroup
                }

                // Option 1: Turn off screen (DPMS Off)
                PlasmaComponents3.RadioButton {
                    Layout.fillWidth: true
                    QQC2.ButtonGroup.group: screenActionGroup
                    checked: controller.screenAction === LidController.TurnOffScreen
                    text: i18n("Turn off screen (DPMS Off)")
                    onToggled: {
                        if (checked) {
                            controller.screenAction = LidController.TurnOffScreen;
                        }
                    }

                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.text: i18n("Turns off display backlight while the lid is closed. Wakes up immediately upon opening.")
                }

                // Option 2: Dim brightness
                PlasmaComponents3.RadioButton {
                    Layout.fillWidth: true
                    QQC2.ButtonGroup.group: screenActionGroup
                    checked: controller.screenAction === LidController.DimBrightness
                    text: i18n("Dim display brightness to minimum")
                    onToggled: {
                        if (checked) {
                            controller.screenAction = LidController.DimBrightness;
                        }
                    }

                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.text: i18n("Dims display brightness to 0% when closed and restores previous brightness upon opening.")
                }

                // Option 3: Do nothing
                PlasmaComponents3.RadioButton {
                    Layout.fillWidth: true
                    QQC2.ButtonGroup.group: screenActionGroup
                    checked: controller.screenAction === LidController.DoNothing
                    text: i18n("Do nothing (keep screen on)")
                    onToggled: {
                        if (checked) {
                            controller.screenAction = LidController.DoNothing;
                        }
                    }

                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.text: i18n("Display remains powered on in its current state.")
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            // -----------------------------------------------------------------
            // 3. Prevent screen lock setting
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    PlasmaComponents3.Label {
                        text: i18n("Prevent screen lock")
                        font.bold: true
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Do not lock session on lid close or idle while awake")
                        opacity: 0.7
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                PlasmaComponents3.Switch {
                    checked: controller.preventLock
                    onToggled: {
                        controller.preventLock = checked;
                    }

                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.text: checked
                        ? i18n("Screen lock is prevented while awake mode is active")
                        : i18n("Screen may be locked according to system power settings")
                }
            }

            // Informative status hint
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.75
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                text: controller.isInhibited
                    ? (controller.screenAction === LidController.TurnOffScreen
                        ? i18n("💡 Laptop will stay awake with lid closed; display will turn off automatically.")
                        : (controller.screenAction === LidController.DimBrightness
                            ? i18n("💡 Laptop will stay awake with lid closed; display brightness will be dimmed.")
                            : i18n("💡 Laptop will stay awake with lid closed; display will remain on.")))
                    : i18n("💤 Normal sleep active: Laptop will sleep when lid is closed.")
            }
        }
    }
}
