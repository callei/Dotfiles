// NetworkOverlay.qml - Quickshell Wi-Fi panel with auth workflow
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common" as Common

PanelWindow {
    id: root

    signal overlayClose()

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-shell:network"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property int panelTopMargin: Common.Theme.barHeight + Common.Theme.barMargin + Common.Theme.spacingSm + 6
    readonly property int panelRightMargin: Common.Theme.barMargin + Common.Theme.spacingMd
    readonly property int panelWidth: 384
    readonly property int panelHeight: 500
    readonly property color panelBackgroundColor: Qt.rgba(Common.Theme.background.r, Common.Theme.background.g, Common.Theme.background.b, 0.88)
    readonly property color panelBorderColor: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.16)

    property bool wifiEnabled: true
    property string activeSsid: ""
    property int activeSignal: 0
    property string statusText: "Refreshing..."

    property string selectedSsid: ""
    property string selectedSecurity: ""
    property bool selectedInUse: false
    property string wifiPassword: ""
    property string lastConnectError: ""

    ListModel {
        id: wifiModel
    }

    function quoteShell(input) {
        return "'" + String(input).replace(/'/g, "'\\''") + "'"
    }

    function networkIsSecure(security) {
        const s = String(security || "").toLowerCase().trim()
        return s !== "" && s !== "--" && s !== "open" && s !== "none"
    }

    function networkNeedsEnterpriseAuth(security) {
        const s = String(security || "").toLowerCase()
        return s.indexOf("802.1x") >= 0 || s.indexOf("wpa-eap") >= 0 || s.indexOf("enterprise") >= 0 || s.indexOf("eap") >= 0
    }

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

    function selectNetwork(ssid, security, inUse) {
        selectedSsid = ssid
        selectedSecurity = security
        selectedInUse = inUse
        if (!networkIsSecure(security)) {
            wifiPassword = ""
        }
    }

    function refreshData() {
        statusText = "Refreshing..."
        wifiStateProcess.running = true
        activeWifiProcess.running = true
        listWifiProcess.running = true
    }

    function connectSelected() {
        if (!selectedSsid || selectedSsid.length === 0) return

        if (networkNeedsEnterpriseAuth(selectedSecurity)) {
            statusText = "Enterprise Wi-Fi: use nmtui for identity/password"
            return
        }

        let cmd = "nmcli dev wifi connect " + quoteShell(selectedSsid)
        if (networkIsSecure(selectedSecurity) && wifiPassword && wifiPassword.length > 0) {
            cmd += " password " + quoteShell(wifiPassword)
        }

        lastConnectError = ""
        connectProcess.command = ["sh", "-c", cmd]
        connectProcess.running = true
        if (networkIsSecure(selectedSecurity) && (!wifiPassword || wifiPassword.length === 0)) {
            statusText = "Connecting (saved profile or open auth)..."
        } else {
            statusText = "Connecting..."
        }
    }

    function applyWifiList(rawData) {
        wifiModel.clear()

        const lines = String(rawData || "").split("\n")
        const dedup = {}

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line) continue

            const parts = splitNmcliTerseLine(line)
            if (parts.length < 4) continue

            const inUse = parts[0] === "*" || parts[0] === "yes"
            const ssid = parts[1] && parts[1].length > 0 ? parts[1] : "Hidden network"
            const signal = parseInt(parts[2]) || 0
            const security = parts[3] && parts[3].length > 0 ? parts[3] : "--"
            const key = ssid + "\u0000" + security

            if (!dedup[key] || inUse || signal > dedup[key].signal) {
                dedup[key] = { inUse: inUse, ssid: ssid, signal: signal, security: security }
            }
        }

        const items = []
        for (const key in dedup) {
            if (Object.prototype.hasOwnProperty.call(dedup, key)) items.push(dedup[key])
        }

        items.sort((a, b) => {
            if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
            if (a.signal !== b.signal) return b.signal - a.signal
            return a.ssid.localeCompare(b.ssid)
        })

        for (let j = 0; j < items.length; j++) {
            wifiModel.append(items[j])
        }

        let selectedStillPresent = false
        if (root.selectedSsid.length > 0) {
            for (let k = 0; k < wifiModel.count; k++) {
                const row = wifiModel.get(k)
                if (row.ssid === root.selectedSsid && row.security === root.selectedSecurity) {
                    selectedStillPresent = true
                    root.selectedInUse = row.inUse
                    break
                }
            }
        }

        if (!selectedStillPresent) {
            if (wifiModel.count > 0) {
                const first = wifiModel.get(0)
                root.selectNetwork(first.ssid, first.security, first.inUse)
            } else {
                root.selectedSsid = ""
                root.selectedSecurity = ""
                root.selectedInUse = false
                root.wifiPassword = ""
            }
        }

        root.statusText = wifiModel.count > 0 ? (wifiModel.count + " networks") : "No networks found"
    }

    function forgetSelected() {
        if (!selectedSsid || selectedSsid.length === 0) return
        forgetProcess.command = ["sh", "-c", "nmcli connection delete id " + quoteShell(selectedSsid)]
        forgetProcess.running = true
        statusText = "Removing saved network..."
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: root.overlayClose()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.overlayClose()
        }
    }

    Rectangle {
        id: panel
        width: root.panelWidth
        height: root.panelHeight
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.panelTopMargin
        anchors.rightMargin: root.panelRightMargin
        radius: Common.Theme.radiusLarge
        color: root.panelBackgroundColor
        border.width: 1
        border.color: root.panelBorderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Common.Theme.spacingMd
            spacing: Common.Theme.spacingSm

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Network"
                    font.family: Common.Theme.fontFamily
                    font.pointSize: Common.Theme.fontSizeXl
                    font.bold: true
                    color: Common.Theme.foreground
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 28
                    radius: Common.Theme.radiusFull
                    color: hoverClose.containsMouse
                           ? Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.15)
                           : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                    }

                    MouseArea {
                        id: hoverClose
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.overlayClose()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Theme.spacingSm

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiEnabled
                              ? (root.activeSsid.length > 0 ? root.activeSsid + " (" + root.activeSignal + "%)" : "Wi-Fi on")
                              : "Wi-Fi off"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                        elide: Text.ElideRight
                        width: parent.width - Common.Theme.spacingMd
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: root.wifiEnabled ? Qt.rgba(Common.Theme.color2.r, Common.Theme.color2.g, Common.Theme.color2.b, 0.8)
                                             : Qt.rgba(Common.Theme.color8.r, Common.Theme.color8.g, Common.Theme.color8.b, 0.7)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiEnabled ? "Disable" : "Enable"
                        color: Common.Theme.background
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wifiToggleProcess.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]
                            wifiToggleProcess.running = true
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.statusText
                color: Common.Theme.surfaceVariant
                font.family: Common.Theme.fontFamily
                font.pointSize: Common.Theme.fontSizeSmall
                elide: Text.ElideRight
            }

            ListView {
                id: wifiList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: wifiModel
                clip: true
                spacing: Common.Theme.spacingXs

                delegate: Rectangle {
                    required property var model

                    width: wifiList.width
                    height: 52
                    radius: Common.Theme.radiusMedium
                    color: model.ssid === root.selectedSsid
                           ? Qt.rgba(Common.Theme.color9.r, Common.Theme.color9.g, Common.Theme.color9.b, 0.25)
                           : (hover.containsMouse
                              ? Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)
                              : Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.05))
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Common.Theme.spacingSm
                        anchors.rightMargin: Common.Theme.spacingSm
                        spacing: Common.Theme.spacingSm

                        Text {
                            Layout.fillWidth: true
                            text: (model.inUse ? "● " : "") + model.ssid
                            elide: Text.ElideRight
                            color: Common.Theme.foreground
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeMedium
                        }

                        Text {
                            text: model.security
                            color: Common.Theme.surfaceVariant
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall
                            visible: model.security !== "--"
                        }

                        Text {
                            text: model.signal + "%"
                            color: Common.Theme.surfaceVariant
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall
                        }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectNetwork(model.ssid, model.security, model.inUse)
                        onDoubleClicked: {
                            root.selectNetwork(model.ssid, model.security, model.inUse)
                            root.connectSelected()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.networkIsSecure(root.selectedSecurity) ? 88 : 62
                radius: Common.Theme.radiusMedium
                color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.05)
                border.width: 1
                border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Common.Theme.spacingSm
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: root.selectedSsid === ""
                              ? "Select a network"
                              : (root.selectedSsid + (root.selectedInUse ? " (connected)" : ""))
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    TextField {
                        Layout.fillWidth: true
                        visible: root.networkIsSecure(root.selectedSecurity)
                        placeholderText: "Wi-Fi password"
                        echoMode: TextInput.Password
                        text: root.wifiPassword
                        color: Common.Theme.foreground
                        placeholderTextColor: Common.Theme.surfaceVariant
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                        background: Rectangle {
                            radius: Common.Theme.radiusSmall
                            color: Qt.rgba(Common.Theme.background.r, Common.Theme.background.g, Common.Theme.background.b, 0.85)
                            border.width: 1
                            border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)
                        }
                        onTextChanged: root.wifiPassword = text
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Theme.spacingSm

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: Qt.rgba(Common.Theme.color2.r, Common.Theme.color2.g, Common.Theme.color2.b, 0.45)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !connectProcess.running
                        onClicked: root.connectSelected()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: Qt.rgba(Common.Theme.warning.r, Common.Theme.warning.g, Common.Theme.warning.b, 0.28)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.warning.r, Common.Theme.warning.g, Common.Theme.warning.b, 0.4)

                    Text {
                        anchors.centerIn: parent
                        text: "Forget"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.selectedSsid !== "" && !forgetProcess.running
                        onClicked: root.forgetSelected()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: Qt.rgba(Common.Theme.color11.r, Common.Theme.color11.g, Common.Theme.color11.b, 0.35)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "Refresh"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshData()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: Common.Theme.radiusFull
                color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.06)
                border.width: 1
                border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: "Open nmtui"
                    color: Common.Theme.foreground
                    font.family: Common.Theme.fontFamily
                    font.pointSize: Common.Theme.fontSizeSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fallbackNmtui.running = true
                }
            }
        }
    }

    Process {
        id: wifiStateProcess
        command: ["nmcli", "radio", "wifi"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = data.trim().toLowerCase() === "enabled"
            }
        }
    }

    Process {
        id: activeWifiProcess
        command: ["sh", "-c", "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes:' | head -1"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = root.splitNmcliTerseLine(data.trim())
                if (parts.length >= 3) {
                    root.activeSsid = parts[1] || ""
                    root.activeSignal = parseInt(parts[2]) || 0
                } else {
                    root.activeSsid = ""
                    root.activeSignal = 0
                }
            }
        }
    }

    Process {
        id: listWifiProcess
        command: ["sh", "-c", "nmcli -t -f in-use,ssid,signal,security dev wifi list --rescan auto 2>/dev/null"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.applyWifiList(this.text)
            }
        }
    }

    Process {
        id: connectProcess
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                root.lastConnectError = this.text.trim()
            }
        }

        onExited: code => {
            if (code === 0) {
                root.statusText = "Connected"
            } else if (root.networkNeedsEnterpriseAuth(root.selectedSecurity)) {
                root.statusText = "Enterprise Wi-Fi: use nmtui"
            } else if (root.networkIsSecure(root.selectedSecurity) && (!root.wifiPassword || root.wifiPassword.length === 0)) {
                root.statusText = "Password required (or use saved profile)"
            } else if (root.lastConnectError.length > 0) {
                root.statusText = root.lastConnectError
            } else {
                root.statusText = "Connection failed"
            }
            if (code === 0) {
                root.wifiPassword = ""
            }
            refreshTimer.restart()
        }
    }

    Process {
        id: forgetProcess
        running: false

        onExited: code => {
            root.statusText = code === 0 ? "Network forgotten" : "Forget failed"
            refreshTimer.restart()
        }
    }

    Process {
        id: wifiToggleProcess
        running: false

        onExited: _code => refreshTimer.restart()
    }

    Process {
        id: fallbackNmtui
        command: ["kitty", "-e", "nmtui"]
        running: false
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: root.refreshData()
    }

    Timer {
        interval: 7000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshData()
    }
}
