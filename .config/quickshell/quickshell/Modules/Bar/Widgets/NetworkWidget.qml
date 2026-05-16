// NetworkWidget.qml - Network status
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Common" as Common
import "../../../Services" as Services
import "../../../Widgets" as Widgets

Widgets.Module {
    onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
            Services.ShellService.toggleWidget("network")
        }
    }

    id: root
    paddingLeft: 11
    paddingRight: 10

    property string ssid: ""
    property int signalStrength: 0
    property bool connected: false
    property string connectionType: "disconnected"

    property int minModuleWidth: 48
    property int maxModuleWidth: 220
    property int wifiTextPadding: 6 // reduced for tighter left/right text padding

    function splitNmcliTerseLine(line) {
        const text = String(line || "")
        const out = []
        let chunk = ""
        let escaped = false

        for (let i = 0; i < text.length; i++) {
            const ch = text[i]
            if (escaped) {
                chunk += ch
                escaped = false
                continue
            }
            if (ch === "\\") {
                escaped = true
                continue
            }
            if (ch === ":") {
                out.push(chunk)
                chunk = ""
                continue
            }
            chunk += ch
        }

        if (escaped) chunk += "\\"
        out.push(chunk)
        return out
    }

    // Animate width for smooth transitions
    width: Math.max(minModuleWidth, contentRow.implicitWidth + paddingLeft + paddingRight)
    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Row {
        id: contentRow
        spacing: -1 // reduced spacing between text and icon

        Widgets.Text {
            text: root.connected && root.connectionType === "wifi" ? root.ssid : ""
            visible: root.connected && root.connectionType === "wifi"
            leftPadding: root.connected && root.connectionType === "wifi" ? 4 : 0 // smaller left padding
            rightPadding: root.connected && root.connectionType === "wifi" ? wifiTextPadding : 0
        }

        Widgets.Icon {
            icon: getIcon()
            iconSize: Common.Theme.fontSizeLarge

            function getIcon() {
                if (!root.connected) return ""
                if (root.connectionType === "ethernet") return "󰈀"
                // WiFi signal strength icons
                if (root.signalStrength >= 75) return "󰤥"
                if (root.signalStrength >= 50) return "󰤢"
                return "󰤟"
            }
        }
    }

    Process {
        id: networkProcess
        command: ["sh", "-c", "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = root.splitNmcliTerseLine(data.trim())
                if (parts.length >= 3 && parts[0] === "yes") {
                    root.ssid = parts[1] || ""
                    root.signalStrength = parseInt(parts[2]) || 0
                    root.connected = true
                    root.connectionType = "wifi"
                }
            }
        }

        onExited: (code) => {
            if (code !== 0 || !root.connected) {
                // Check for ethernet
                ethernetProcess.running = true
            }
        }
    }

    Process {
        id: ethernetProcess
        command: ["sh", "-c", "nmcli -t -f device,type,state dev 2>/dev/null | grep 'ethernet:connected'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("connected")) {
                    root.connected = true
                    root.connectionType = "ethernet"
                    root.ssid = ""
                }
            }
        }

        onExited: (code) => {
            if (code !== 0 && root.connectionType !== "wifi") {
                root.connected = false
                root.connectionType = "disconnected"
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            networkProcess.running = true
        }
    }
}
