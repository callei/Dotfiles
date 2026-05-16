// OsdOverlay.qml - Lightweight OSD scaffold for volume and brightness
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common" as Common

PanelWindow {
    id: root

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-shell:osd"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: Common.Theme.spacingXl
    }

    // Keep the layer-shell surface out of the input path while idle.
    implicitHeight: osdCard.visible ? (osdCard.height + Common.Theme.spacingSm) : 0

    property bool initialized: false
    property string currentLabel: "Volume"
    property string currentIcon: "󰕾"
    property int currentPercent: 0
    property bool muted: false
    property bool showProgress: true

    property int lastVolume: -1
    property int lastBrightness: -1
    property bool lastMuted: false
    property bool micStateKnown: false
    property bool lastMicMuted: false

    function handleIpcState(line) {
        const parts = String(line || "").trim().split(":")
        if (parts.length < 2) return

        const kind = parts[0].trim()
        const raw = parseInt(parts[1].trim())
        const value = isNaN(raw) ? 0 : Math.max(0, Math.min(100, raw))

        if (kind === "volume") {
            lastVolume = value
            showVolume(value, false)
            return
        }
        if (kind === "volume-muted") {
            lastVolume = value
            showVolume(value, true)
            return
        }
        if (kind === "mute") {
            const fallback = lastVolume >= 0 ? lastVolume : 0
            showVolume(fallback, true)
            return
        }
        if (kind === "brightness") {
            lastBrightness = value
            showBrightness(value)
            return
        }
        if (kind === "mic") {
            showMic(value > 0)
        }
    }

    function showOsd(label, percent, icon, isMuted, progressVisible) {
        currentLabel = label
        currentPercent = Math.max(0, Math.min(100, percent))
        currentIcon = icon
        muted = isMuted
        showProgress = progressVisible
        osdCard.visible = true
        hideTimer.restart()
    }

    function showVolume(percent, isMuted) {
        showOsd(isMuted ? "Volume muted" : "Volume", percent, isMuted ? "󰝟" : "󰕾", isMuted, true)
    }

    function showBrightness(percent) {
        showOsd("Brightness", percent, "󰃠", false, true)
    }

    function showMic(isMuted) {
        showOsd(isMuted ? "Microphone muted" : "Microphone on", 0, isMuted ? "󰍭" : "󰍬", isMuted, false)
    }

    function parseMutedToken(token) {
        const t = String(token || "").trim().toLowerCase()
        return t === "yes" || t === "true" || t === "1"
    }

    Rectangle {
        id: osdCard
        visible: false
        width: 360
        height: root.showProgress ? 52 : 40
        radius: 999
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        color: Qt.rgba(Common.Theme.bg.r, Common.Theme.bg.g, Common.Theme.bg.b, 0.55)
        border.width: 0
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Common.Theme.animFast }
        }

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: Common.Theme.spacingSm

            Text {
                text: root.currentIcon
                color: root.muted ? Common.Theme.color1 : Common.Theme.color7
                font.family: Common.Theme.fontFamily
                font.pointSize: 14
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.showProgress ? 3 : 0

                Item {
                    Layout.fillWidth: true
                    implicitHeight: labelRow.implicitHeight

                    Row {
                        id: labelRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: root.currentLabel
                            color: root.muted ? Common.Theme.color1 : Common.Theme.color7
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall + 1
                        }

                        Text {
                            text: root.currentPercent + "%"
                            color: Common.Theme.surfaceVariant
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall
                            visible: root.showProgress
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    radius: 999
                    color: Qt.rgba(Common.Theme.color2.r, Common.Theme.color2.g, Common.Theme.color2.b, 0.5)
                    visible: root.showProgress

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(parent.width * (root.currentPercent / 100))
                        height: parent.height
                        radius: parent.radius
                        color: root.muted ? Common.Theme.color1 : Common.Theme.accent
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: osdCard.visible = false
    }

    Process {
        id: osdStateReader
        command: ["sh", "-c", "if [ -f /tmp/qs_osd_state ]; then cat /tmp/qs_osd_state; rm -f /tmp/qs_osd_state; fi"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const lines = data.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (line.length === 0) continue
                    root.handleIpcState(line)
                }
            }
        }
    }

    Timer {
        interval: 120
        running: true
        repeat: true
        onTriggered: osdStateReader.running = true
    }

    Process {
        id: volumeProcess
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                const muted = line.indexOf("MUTED") >= 0
                const match = line.match(/([0-9]*\.?[0-9]+)/)
                if (!match) return
                const volume = Math.round(parseFloat(match[1]) * 100)

                if (!root.initialized) {
                    root.lastVolume = volume
                    root.lastMuted = muted
                    return
                }
                root.lastVolume = volume
                root.lastMuted = muted
            }
        }
    }

    Process {
        id: brightnessStateProcess
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%' "]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const brightness = parseInt(data.trim())
                if (isNaN(brightness)) return
                root.lastBrightness = brightness
            }
        }
    }

    Process {
        id: micStateProcess
        command: ["sh", "-c", "pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const token = data.trim()
                if (token.length === 0) return

                const muted = root.parseMutedToken(token)
                if (!root.micStateKnown || !root.initialized) {
                    root.lastMicMuted = muted
                    root.micStateKnown = true
                    return
                }

                if (muted !== root.lastMicMuted) {
                    root.lastMicMuted = muted
                    root.showMic(muted)
                }
            }
        }
    }

    Timer {
        interval: 1800
        running: true
        repeat: true
        onTriggered: {
            volumeProcess.running = true
            brightnessStateProcess.running = true
            if (!root.initialized) root.initialized = true
        }
    }

    Timer {
        interval: 650
        running: true
        repeat: true
        onTriggered: micStateProcess.running = true
    }
}
