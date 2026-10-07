import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import com.github.kryptonfox.klidkeeper 1.0

PlasmoidItem {
    id: root

    // Sizing for desktop / plasmoidviewer
    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Kirigami.Units.gridUnit * 18
    width: implicitWidth
    height: implicitHeight

    // System tray integration
    Plasmoid.icon: controller.isInhibited ? "caffeine-cup-full" : "caffeine-cup-empty"
    Plasmoid.title: i18n("KLidKeeper")
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

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
            source: controller.isInhibited ? "caffeine-cup-full" : "caffeine-cup-empty"
            fallback: controller.isInhibited ? "system-suspend-inhibited" : "system-suspend-uninhibited"
            isMask: true
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
        Layout.maximumWidth: Kirigami.Units.gridUnit * 25

        contentItem: ColumnLayout {
            id: contentLayout
            spacing: Kirigami.Units.mediumSpacing

            // -----------------------------------------------------------------
            // 1. Hero Toggle Card: Prevent sleep on lid close
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                radius: Kirigami.Units.smallSpacing * 1.5
                color: controller.isInhibited
                    ? Qt.alpha(Kirigami.Theme.highlightColor, 0.16)
                    : (heroHover.containsMouse ? Qt.alpha(Kirigami.Theme.textColor, 0.06) : Qt.alpha(Kirigami.Theme.textColor, 0.03))
                border.color: controller.isInhibited
                    ? Qt.alpha(Kirigami.Theme.highlightColor, 0.5)
                    : Qt.alpha(Kirigami.Theme.textColor, 0.12)
                border.width: 1

                implicitHeight: heroLayout.implicitHeight + (Kirigami.Units.mediumSpacing * 2)

                MouseArea {
                    id: heroHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controller.toggle()
                }

                RowLayout {
                    id: heroLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: controller.isInhibited ? "caffeine-cup-full" : "caffeine-cup-empty"
                        fallback: controller.isInhibited ? "system-suspend-inhibited" : "system-suspend-uninhibited"
                        isMask: true
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
                            opacity: 0.7
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

            // -----------------------------------------------------------------
            // 2. Settings Group Card (Display behavior & Screen lock)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                radius: Kirigami.Units.smallSpacing * 1.5
                color: Qt.alpha(Kirigami.Theme.textColor, 0.03)
                border.color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                border.width: 1

                implicitHeight: settingsCol.implicitHeight + (Kirigami.Units.mediumSpacing * 2)

                ColumnLayout {
                    id: settingsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.mediumSpacing

                    // Row A: Screen Action with ComboBox
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing

                        PlasmaComponents3.Label {
                            text: i18n("When laptop lid is closed:")
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        PlasmaComponents3.ComboBox {
                            id: screenCombo
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                            model: [
                                i18n("Turn off screen (DPMS Off)"),
                                i18n("Dim display brightness to minimum"),
                                i18n("Do nothing (keep screen on)")
                            ]
                            currentIndex: controller.screenAction
                            onActivated: index => {
                                controller.screenAction = index;
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        opacity: 0.5
                    }

                    // Row B: Prevent Screen Lock with Switch
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            PlasmaComponents3.Label {
                                text: i18n("Prevent screen lock")
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: i18n("Do not lock session on lid close or idle while awake")
                                opacity: 0.65
                                font.pointSize: Kirigami.Theme.smallFont.pointSize * 0.95
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
                }
            }

            // -----------------------------------------------------------------
            // 3. Informative Status Banner
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                radius: Kirigami.Units.smallSpacing * 1.5
                color: Qt.alpha(controller.isInhibited ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor, 0.07)
                border.color: Qt.alpha(controller.isInhibited ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor, 0.14)
                border.width: 1

                implicitHeight: bannerLabel.implicitHeight + (Kirigami.Units.mediumSpacing * 2)

                PlasmaComponents3.Label {
                    id: bannerLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    wrapMode: Text.WordWrap
                    opacity: 0.85
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

            // -----------------------------------------------------------------
            // 4. Spacer: absorbs extra tray popup height, pins cards to the top
            // -----------------------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
