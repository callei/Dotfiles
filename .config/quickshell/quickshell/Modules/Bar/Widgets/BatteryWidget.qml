// BatteryWidget.qml - Battery status
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Common" as Common
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    hoverable: false
    autoSizeContentWidth: false
    paddingLeft: 14
    paddingRight: 18
    contentWidth: 44

    property int percentage: 100
    property bool charging: false
    property string status: "Full"
    readonly property color levelColor: charging
                                      ? Common.Theme.success
                                      : (percentage <= 20
                                         ? Common.Theme.error
                                         : (percentage <= 30 ? Common.Theme.warning : Common.Theme.foreground))

    Row {
        spacing: Common.Theme.spacingSm

        Widgets.Text {
            text: root.percentage + "%"
            color: root.levelColor
        }

        Widgets.Icon {
            icon: root.charging ? "󰂄" : getBatteryIcon()
            color: root.levelColor

            function getBatteryIcon() {
                if (root.percentage >= 90) return "󰁹"
                if (root.percentage >= 70) return "󰂂"
                if (root.percentage >= 50) return "󰂀"
                if (root.percentage >= 30) return "󰁾"
                if (root.percentage >= 10) return "󰁼"
                return "󰁻"
            }
        }
    }

    // Read battery status
    Process {
        id: batteryProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val)) root.percentage = val
            }
        }
    }

    Process {
        id: statusProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.status = data.trim()
                root.charging = (root.status === "Charging")
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batteryProcess.running = true
            statusProcess.running = true
        }
    }
}
