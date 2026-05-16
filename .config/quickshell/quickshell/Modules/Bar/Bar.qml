// Bar.qml - Main status bar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Common" as Common
import "Widgets"

PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Common.Theme.barHeight + Common.Theme.barPaddingTop + Common.Theme.barPaddingBottom
    color: "transparent"
    exclusionMode: ExclusionMode.Auto

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-shell:bar"

    margins {
        top: Common.Theme.barMargin
        left: Common.Theme.barMargin
        right: Common.Theme.barMargin
    }

    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: "transparent"


        RowLayout {
            anchors.fill: parent
            anchors.topMargin: Common.Theme.barPaddingTop
            anchors.bottomMargin: Common.Theme.barPaddingBottom

            // Left modules
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: leftRow.width + Common.Theme.barEdgeInset + Common.Theme.spacingMd

                RowLayout {
                    id: leftRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Common.Theme.barEdgeInset
                    spacing: 0

                    LogoWidget {
                        Layout.leftMargin: 0
                        Layout.rightMargin: 13
                    }

                    BatteryWidget {
                        Layout.leftMargin: 13
                        Layout.rightMargin: 13
                    }

                    ClockWidget {
                        Layout.leftMargin: 8
                        Layout.rightMargin: 13
                    }

                    UpdatesWidget {
                        Layout.leftMargin: 13
                        Layout.rightMargin: 13
                    }

                    TailscaleWidget {
                        Layout.leftMargin: 10
                        Layout.rightMargin: 0
                    }
                }
            }

            // Center modules
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true

                RowLayout {
                    id: centerRow
                    anchors.verticalCenter: parent.verticalCenter

                    WorkspacesWidget {
                        Layout.leftMargin: 430
                    }
                }
            }

            // Right modules
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: rightRow2.width + Common.Theme.barEdgeInsetRight + Common.Theme.spacingMd

                RowLayout {
                    id: rightRow2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Common.Theme.barEdgeInsetRight
                    spacing: 0

                    BluetoothWidget {
                        Layout.leftMargin: 0
                        Layout.rightMargin: 12
                    }

                    NetworkWidget {
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                    }

                    MemoryWidget {
                        Layout.leftMargin: 12
                        Layout.rightMargin: 14
                    }

                    NotificationWidget {
                        Layout.leftMargin: 14
                        Layout.rightMargin: 12
                    }

                    PowerWidget {
                        Layout.leftMargin: 12
                        Layout.rightMargin: 0
                    }
                }
            }
        }

        }
    }
