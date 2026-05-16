// TailscaleWidget.qml - Tailscale connectivity indicator
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../../Common" as Common
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    hoverable: false
    paddingLeft: 13
    paddingRight: 9
    paddingY: 13
    contentWidth: 22

    property bool connected: false

    visible: connected

    Item {
        id: iconBox
        implicitWidth: Common.Theme.fontSizeLarge
        implicitHeight: Common.Theme.fontSizeLarge

        Image {
            id: tailscaleIcon
            visible: false
            anchors.centerIn: parent
            width: Common.Theme.fontSizeLarge
            height: Common.Theme.fontSizeLarge
            source: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/tailscale-light.svg"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
        }

        MultiEffect {
            anchors.fill: tailscaleIcon
            source: tailscaleIcon
            colorization: 1.0
            colorizationColor: Common.Theme.foreground
        }
    }

    Process {
        id: tailscaleProcess
        command: [
            "sh",
            "-c",
            "if command -v tailscale >/dev/null 2>&1; then tailscale status --json 2>/dev/null; fi"
        ]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const txt = this.text.trim()
                if (!txt) {
                    root.connected = false
                    return
                }

                try {
                    const status = JSON.parse(txt)
                    root.connected = status.BackendState === "Running" && status.Self && status.Self.Online === true
                } catch (error) {
                    root.connected = false
                }
            }
        }

        onExited: code => {
            if (code !== 0) {
                root.connected = false
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: tailscaleProcess.running = true
    }
}