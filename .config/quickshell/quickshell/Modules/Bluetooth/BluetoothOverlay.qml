// BluetoothOverlay.qml - Quickshell Bluetooth panel with pairing workflow
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
    WlrLayershell.namespace: "qs-shell:bluetooth"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property int panelTopMargin: Common.Theme.barHeight + Common.Theme.barMargin + Common.Theme.spacingSm + 6
    readonly property int panelRightMargin: Common.Theme.barMargin + Common.Theme.spacingMd + 392
    readonly property int panelWidth: 384
    readonly property int panelHeight: 500
    readonly property color panelBackgroundColor: Qt.rgba(Common.Theme.background.r, Common.Theme.background.g, Common.Theme.background.b, 0.88)
    readonly property color panelBorderColor: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.16)

    property bool powered: false
    property bool scanning: false
    property string statusText: "Refreshing..."

    property string selectedMac: ""
    property string selectedName: ""
    property bool selectedConnected: false
    property bool selectedPaired: false
    property bool selectedTrusted: false

    ListModel {
        id: deviceModel
    }

    function refreshData() {
        statusText = scanning ? "Scanning..." : "Refreshing..."
        powerProcess.running = true
        devicesProcess.running = true
    }

    function selectDevice(mac, name, connected, paired, trusted) {
        selectedMac = mac
        selectedName = name
        selectedConnected = connected
        selectedPaired = paired
        selectedTrusted = trusted
    }

    function connectOrPairSelected() {
        if (!selectedMac || selectedMac.length === 0) return
        if (!selectedPaired) {
            pairProcess.command = ["bluetoothctl", "pair", selectedMac]
            pairProcess.running = true
            statusText = "Pairing..."
            return
        }
        connectProcess.command = ["bluetoothctl", selectedConnected ? "disconnect" : "connect", selectedMac]
        connectProcess.running = true
        statusText = selectedConnected ? "Disconnecting..." : "Connecting..."
    }

    function toggleTrustSelected() {
        if (!selectedMac || selectedMac.length === 0) return
        trustProcess.command = ["bluetoothctl", "trust", selectedMac]
        trustProcess.running = true
        statusText = "Updating trust..."
    }

    function removeSelected() {
        if (!selectedMac || selectedMac.length === 0) return
        removeProcess.command = ["bluetoothctl", "remove", selectedMac]
        removeProcess.running = true
        statusText = "Removing device..."
    }

    function startScan() {
        if (scanning) return
        scanning = true
        statusText = "Scanning..."
        scanProcess.running = true
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
                    text: "Bluetooth"
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
                        text: root.powered ? "Bluetooth on" : "Bluetooth off"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: root.powered ? Qt.rgba(Common.Theme.color2.r, Common.Theme.color2.g, Common.Theme.color2.b, 0.8)
                                        : Qt.rgba(Common.Theme.color8.r, Common.Theme.color8.g, Common.Theme.color8.b, 0.7)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: root.powered ? "Disable" : "Enable"
                        color: Common.Theme.background
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            togglePowerProcess.command = ["bluetoothctl", "power", root.powered ? "off" : "on"]
                            togglePowerProcess.running = true
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: scanning
                           ? Qt.rgba(Common.Theme.color9.r, Common.Theme.color9.g, Common.Theme.color9.b, 0.7)
                           : Qt.rgba(Common.Theme.color11.r, Common.Theme.color11.g, Common.Theme.color11.b, 0.35)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: scanning ? "Scanning" : "Scan"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.powered && !scanning
                        onClicked: root.startScan()
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
                id: deviceList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: deviceModel
                clip: true
                spacing: Common.Theme.spacingXs

                delegate: Rectangle {
                    required property var model

                    width: deviceList.width
                    height: 52
                    radius: Common.Theme.radiusMedium
                    color: model.mac === root.selectedMac
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
                            text: model.name
                            elide: Text.ElideRight
                            color: Common.Theme.foreground
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeMedium
                        }

                        Text {
                            text: model.connected ? "Connected" : (model.paired ? "Paired" : "New")
                            color: model.connected ? Common.Theme.success : Common.Theme.surfaceVariant
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall
                        }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectDevice(model.mac, model.name, model.connected, model.paired, model.trusted)
                        onDoubleClicked: {
                            root.selectDevice(model.mac, model.name, model.connected, model.paired, model.trusted)
                            root.connectOrPairSelected()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                radius: Common.Theme.radiusMedium
                color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.05)
                border.width: 1
                border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Common.Theme.spacingSm
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.selectedName !== "" ? root.selectedName : "Select a device"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.selectedMac !== ""
                              ? (root.selectedMac + "  |  " + (root.selectedTrusted ? "trusted" : "untrusted"))
                              : ""
                        color: Common.Theme.surfaceVariant
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                        elide: Text.ElideRight
                        visible: root.selectedMac !== ""
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
                        text: root.selectedPaired
                              ? (root.selectedConnected ? "Disconnect" : "Connect")
                              : "Pair"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.selectedMac !== ""
                        onClicked: root.connectOrPairSelected()
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
                        text: "Trust"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.selectedMac !== ""
                        onClicked: root.toggleTrustSelected()
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
                        text: "Remove"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.selectedMac !== ""
                        onClicked: root.removeSelected()
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
                    text: "Open blueman-manager"
                    color: Common.Theme.foreground
                    font.family: Common.Theme.fontFamily
                    font.pointSize: Common.Theme.fontSizeSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fallbackBlueman.running = true
                }
            }
        }
    }

    Process {
        id: powerProcess
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.powered = data.trim() === "yes"
            }
        }
    }

    Process {
        id: devicesProcess
        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do info=$(bluetoothctl info \"$mac\" 2>/dev/null); conn=$(echo \"$info\" | awk '/Connected:/ {print $2}'); paired=$(echo \"$info\" | awk '/Paired:/ {print $2}'); trusted=$(echo \"$info\" | awk '/Trusted:/ {print $2}'); [ -z \"$conn\" ] && conn=no; [ -z \"$paired\" ] && paired=no; [ -z \"$trusted\" ] && trusted=no; echo \"$mac|$name|$conn|$paired|$trusted\"; done"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                deviceModel.clear()
                const lines = data.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (!line) continue
                    const parts = line.split("|")
                    if (parts.length < 5) continue

                    const mac = parts[0]
                    const name = parts[1] && parts[1].length > 0 ? parts[1] : mac
                    const connected = parts[2] === "yes"
                    const paired = parts[3] === "yes"
                    const trusted = parts[4] === "yes"
                    deviceModel.append({
                        mac: mac,
                        name: name,
                        connected: connected,
                        paired: paired,
                        trusted: trusted
                    })
                }

                if (deviceModel.count > 0 && root.selectedMac === "") {
                    const first = deviceModel.get(0)
                    root.selectDevice(first.mac, first.name, first.connected, first.paired, first.trusted)
                }

                root.statusText = deviceModel.count > 0
                    ? (deviceModel.count + " devices")
                    : (root.powered ? "No devices found" : "Bluetooth is off")
            }
        }
    }

    Process {
        id: scanProcess
        command: ["sh", "-c", "bluetoothctl --timeout 8 scan on >/dev/null 2>&1"]
        running: false

        onExited: _code => {
            root.scanning = false
            refreshTimer.restart()
        }
    }

    Process {
        id: connectProcess
        running: false

        onExited: code => {
            root.statusText = code === 0 ? "Done" : "Action failed"
            refreshTimer.restart()
        }
    }

    Process {
        id: pairProcess
        running: false

        onExited: code => {
            root.statusText = code === 0 ? "Paired" : "Pairing failed"
            refreshTimer.restart()
        }
    }

    Process {
        id: trustProcess
        running: false

        onExited: _code => refreshTimer.restart()
    }

    Process {
        id: removeProcess
        running: false

        onExited: code => {
            root.statusText = code === 0 ? "Device removed" : "Remove failed"
            root.selectedMac = ""
            refreshTimer.restart()
        }
    }

    Process {
        id: togglePowerProcess
        running: false

        onExited: _code => refreshTimer.restart()
    }

    Process {
        id: fallbackBlueman
        command: ["blueman-manager"]
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
