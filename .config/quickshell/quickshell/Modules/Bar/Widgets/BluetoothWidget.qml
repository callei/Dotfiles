// BluetoothWidget.qml - Bluetooth status
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Common" as Common
import "../../../Services" as Services
import "../../../Widgets" as Widgets

Widgets.Module {
    onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
            Services.ShellService.toggleWidget("bluetooth")
        }
    }

    id: root
    paddingLeft: 11
    paddingRight: 5

    property bool powered: true
    property bool connected: false
    property int batteryPercent: -1
    property string deviceName: ""

    Row {
        spacing: Common.Theme.spacingSm

        Widgets.Text {
            text: root.batteryPercent >= 0 ? root.batteryPercent + "%" : ""
            visible: root.batteryPercent >= 0
        }

        Widgets.Icon {
            icon: getIcon()
            iconSize: Common.Theme.fontSizeLarge
            color: Common.Theme.foreground

            function getIcon() {
                if (!root.powered) return "󰂲"
                if (root.connected) return "󰂯"
                return "󰂯"
            }
        }
    }

    Process {
        id: bluetoothProcess
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.powered = (data.trim() === "yes")
            }
        }
    }

    Process {
        id: connectedProcess
        command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | head -1"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                root.connected = line.length > 0
                if (root.connected) {
                    const parts = line.split(' ')
                    if (parts.length >= 3) {
                        root.deviceName = parts.slice(2).join(' ')
                    }
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.connected = false
            root.deviceName = ""
            bluetoothProcess.running = true
            connectedProcess.running = true
        }
    }
}
