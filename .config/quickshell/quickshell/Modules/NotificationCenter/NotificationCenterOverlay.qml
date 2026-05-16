// NotificationCenterOverlay.qml - Notification panel backed by Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications as QSNotifications
import "../../Common" as Common
import "../../Services" as Services

PanelWindow {
    id: root

    signal overlayClose()

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-shell:notifications"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: Services.ShellService.notificationsVisible

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property int panelTopMargin: Common.Theme.barHeight + Common.Theme.barMargin + Common.Theme.spacingSm + 6
    readonly property int panelRightMargin: 12
    readonly property int panelBottomMargin: 8
    readonly property int panelWidth: 380
    readonly property color panelBackgroundColor: Qt.rgba(Common.Theme.background.r, Common.Theme.background.g, Common.Theme.background.b, 0.88)
    readonly property color panelBorderColor: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.16)

    readonly property var notificationServer: Services.ShellService.notificationServer
    property var notificationList: []
    property int notificationCount: notificationList.length
    property bool muteEnabled: false
    property bool micMuteEnabled: false
    property string powerProfile: ""
    property bool nightModeEnabled: false
    property real volumeValue: 0.5
    property string statusText: "Quickshell backend active"
    property string lastActionItemId: ""

    property var actionItems: [
        { id: "performance", label: "󰾆", command: "powerprofilesctl set performance" },
        { id: "balanced", label: "󰾅", command: "powerprofilesctl set balanced" },
        { id: "powersaver", label: "", command: "powerprofilesctl set power-saver" },
        { id: "mute", label: "󰝟", command: Quickshell.env("HOME") + "/.config/quickshell/bin/qs_control.sh volume-mute" },
        { id: "micmute", label: "󰍭", command: Quickshell.env("HOME") + "/.config/quickshell/bin/qs_control.sh mic-mute" },
        { id: "night", label: "󰖔", command: Quickshell.env("HOME") + "/.config/hypr/scripts/night_mode_toggle.sh" }
    ]

    function pushStatus(message) {
        const msg = String(message || "").trim()
        if (msg.length === 0) return
        statusText = msg
    }

    function notificationAt(model, index) {
        if (!model || index < 0) return null
        if (typeof model.objectAt === "function") return model.objectAt(index)
        if (typeof model.get === "function") return model.get(index)
        return null
    }

    function syncFromTrackedNotifications() {
        if (!notificationServer || !notificationServer.trackedNotifications) return

        const tracked = notificationServer.trackedNotifications
        if (typeof tracked.count !== "number") return

        const next = []
        for (let i = tracked.count - 1; i >= 0; i--) {
            const n = notificationAt(tracked, i)
            if (!n) continue
            next.push({ id: n.id, notification: n })
        }
        notificationList = next
    }

    onNotificationServerChanged: syncFromTrackedNotifications()

    function addNotification(notification) {
        if (!notification) return

        notification.tracked = true

        for (let i = 0; i < notificationList.length; i++) {
            if (notificationList[i].id === notification.id) return
        }

        notification.closed.connect(reason => {
            root.removeNotificationById(notification.id)
        })

        const next = notificationList.slice()
        next.unshift({ id: notification.id, notification: notification })
        notificationList = next
        pushStatus("New notification: " + (notification.summary || notification.appName || "Untitled"))
    }

    function removeNotificationById(id) {
        const next = []
        for (let i = 0; i < notificationList.length; i++) {
            const entry = notificationList[i]
            if (entry.id !== id) {
                next.push(entry)
            }
        }
        notificationList = next
    }

    function closeLatestNotification() {
        if (notificationList.length === 0) return
        const latest = notificationList[0].notification
        if (latest && typeof latest.dismiss === "function") {
            latest.dismiss()
        }
    }

    function clearAllNotifications() {
        const current = notificationList.slice()
        for (let i = 0; i < current.length; i++) {
            const n = current[i].notification
            if (n && typeof n.dismiss === "function") {
                n.dismiss()
            }
        }
        notificationList = []
    }

    function refreshState() {
        powerProfileProcess.running = true
        muteProcess.running = true
        micMuteProcess.running = true
        nightModeProcess.running = true
        volumeProcess.running = true
    }

    function updateVolume(value) {
        const clamped = Math.max(0, Math.min(1, value))
        setVolumeProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped.toString()]
        setVolumeProcess.running = true
    }

    function runAction(itemId, command) {
        lastActionItemId = itemId
        runActionProcess.command = ["sh", "-c", command]
        runActionProcess.running = true
        pushStatus("Running " + itemId + "...")
        actionRefreshTimer.restart()
    }

    function runStatePopupForAction(itemId) {
        if (itemId === "mute") {
            statePopupProcess.command = [
                "sh",
                "-c",
                "v=$(pamixer --get-mute 2>/dev/null); if [ \"$v\" = \"true\" ]; then s='Muted'; else s='Unmuted'; fi; notify-send -a 'Quickshell' -u low 'Output audio' \"$s\""
            ]
            statePopupProcess.running = true
            return
        }
        if (itemId === "micmute") {
            statePopupProcess.command = [
                "sh",
                "-c",
                "v=$(pamixer --default-source --get-mute 2>/dev/null); if [ \"$v\" = \"true\" ]; then s='Microphone muted'; else s='Microphone unmuted'; fi; notify-send -a 'Quickshell' -u low 'Mic status' \"$s\""
            ]
            statePopupProcess.running = true
            return
        }
        if (itemId === "night") {
            statePopupProcess.command = [
                "sh",
                "-c",
                "v=$($HOME/.config/hypr/scripts/check_night_mode.sh 2>/dev/null); case \"$v\" in true|1|on) s='On' ;; *) s='Off' ;; esac; notify-send -a 'Quickshell' -u low 'Night mode' \"$s\""
            ]
            statePopupProcess.running = true
        }
    }

    function isActionActive(itemId) {
        if (itemId === "performance") return powerProfile === "performance"
        if (itemId === "balanced") return powerProfile === "balanced"
        if (itemId === "powersaver") return powerProfile === "power-saver"
        if (itemId === "mute") return muteEnabled
        if (itemId === "micmute") return micMuteEnabled
        if (itemId === "night") return nightModeEnabled
        return false
    }

    function urgencyColor(urgency) {
        if (urgency === QSNotifications.NotificationUrgency.Critical) {
            return Common.Theme.warning
        }
        if (urgency === QSNotifications.NotificationUrgency.Low) {
            return Common.Theme.surfaceVariant
        }
        return Common.Theme.foreground
    }

    Component.onCompleted: {
        syncFromTrackedNotifications()
        refreshState()
    }

    Connections {
        target: root.notificationServer
        function onNotification(notification) {
            root.addNotification(notification)
        }
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
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: root.panelTopMargin
        anchors.rightMargin: root.panelRightMargin
        anchors.bottomMargin: root.panelBottomMargin
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
                    text: "Notification Center"
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
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: root.notificationCount + " notifications"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 132
                    Layout.preferredHeight: 34
                    radius: Common.Theme.radiusFull
                    color: Qt.rgba(Common.Theme.color9.r, Common.Theme.color9.g, Common.Theme.color9.b, 0.65)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.color9.r, Common.Theme.color9.g, Common.Theme.color9.b, 0.75)

                    Text {
                        anchors.centerIn: parent
                        text: "QS backend"
                        color: Common.Theme.background
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                radius: Common.Theme.radiusMedium
                color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.05)
                border.width: 1
                border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Common.Theme.spacingSm
                    spacing: Common.Theme.spacingXs

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "󰕾 Volume"
                            color: Common.Theme.foreground
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeMedium
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: Math.round(root.volumeValue * 100) + "%"
                            color: Common.Theme.surfaceVariant
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 1
                        value: root.volumeValue
                        onMoved: root.updateVolume(value)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Theme.spacingSm

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Common.Theme.radiusFull
                    color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "Close Latest"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeLatestNotification()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Common.Theme.radiusFull
                    color: Qt.rgba(Common.Theme.warning.r, Common.Theme.warning.g, Common.Theme.warning.b, 0.28)
                    border.width: 1
                    border.color: Qt.rgba(Common.Theme.warning.r, Common.Theme.warning.g, Common.Theme.warning.b, 0.4)

                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearAllNotifications()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: Common.Theme.spacingSm
                columnSpacing: Common.Theme.spacingSm

                Repeater {
                    model: root.actionItems

                          delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                           radius: Common.Theme.radiusMedium
                        color: root.isActionActive(modelData.id)
                               ? Qt.rgba(Common.Theme.color9.r, Common.Theme.color9.g, Common.Theme.color9.b, 0.7)
                               : Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.06)
                           border.width: 1
                           border.color: root.isActionActive(modelData.id)
                                   ? Qt.rgba(Common.Theme.color9.r, Common.Theme.color9.g, Common.Theme.color9.b, 0.8)
                                   : Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.isActionActive(modelData.id) ? Common.Theme.background : Common.Theme.foreground
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeLarge
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runAction(modelData.id, modelData.command)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Common.Theme.radiusMedium
                color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.04)
                border.width: 1
                border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Common.Theme.spacingSm
                    spacing: Common.Theme.spacingXs

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Notifications"
                            color: Common.Theme.foreground
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeMedium
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.notificationCount
                            color: Common.Theme.surfaceVariant
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: root.notificationList
                        clip: true
                        spacing: Common.Theme.spacingXs

                        delegate: Rectangle {
                            required property var modelData
                            readonly property var n: modelData.notification

                            width: ListView.view ? ListView.view.width : 340
                            radius: Common.Theme.radiusMedium
                            color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.05)
                            border.width: 1
                            border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)
                            implicitHeight: contentColumn.implicitHeight + Common.Theme.spacingSm * 2

                            ColumnLayout {
                                id: contentColumn
                                anchors.fill: parent
                                anchors.margins: Common.Theme.spacingSm
                                spacing: Common.Theme.spacingXs

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Common.Theme.spacingSm

                                    Rectangle {
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        radius: Common.Theme.radiusSmall
                                        color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.08)

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            color: Common.Theme.foreground
                                            font.family: Common.Theme.fontFamily
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: n.summary && n.summary.length > 0 ? n.summary : "Notification"
                                            color: root.urgencyColor(n.urgency)
                                            font.family: Common.Theme.fontFamily
                                            font.pointSize: Common.Theme.fontSizeSmall
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: n.appName || "Unknown app"
                                            color: Common.Theme.surfaceVariant
                                            font.family: Common.Theme.fontFamily
                                            font.pointSize: Common.Theme.fontSizeSmall
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        radius: Common.Theme.radiusSmall
                                        color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.08)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: Common.Theme.foreground
                                            font.family: Common.Theme.fontFamily
                                            font.pointSize: Common.Theme.fontSizeSmall
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (n && typeof n.dismiss === "function") {
                                                    n.dismiss()
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: n.body && n.body.length > 0
                                    text: n.body
                                    color: Common.Theme.foreground
                                    font.family: Common.Theme.fontFamily
                                    font.pointSize: Common.Theme.fontSizeSmall
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: n.actions && n.actions.length > 0
                                    spacing: Common.Theme.spacingXs

                                    Repeater {
                                        model: n.actions

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.preferredHeight: 28
                                            Layout.preferredWidth: actionLabel.implicitWidth + 16
                                            radius: Common.Theme.radiusSmall
                                            color: Qt.rgba(Common.Theme.color9.r, Common.Theme.color9.g, Common.Theme.color9.b, 0.25)

                                            Text {
                                                id: actionLabel
                                                anchors.centerIn: parent
                                                text: modelData.text || "Action"
                                                color: Common.Theme.foreground
                                                font.family: Common.Theme.fontFamily
                                                font.pointSize: Common.Theme.fontSizeSmall
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData && typeof modelData.invoke === "function") {
                                                        modelData.invoke()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
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
        }
    }

    Process {
        id: powerProfileProcess
        command: ["powerprofilesctl", "get"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.powerProfile = data.trim()
            }
        }
    }

    Process {
        id: muteProcess
        command: ["pamixer", "--get-mute"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.muteEnabled = data.trim() === "true"
            }
        }
    }

    Process {
        id: micMuteProcess
        command: ["pamixer", "--default-source", "--get-mute"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.micMuteEnabled = data.trim() === "true"
            }
        }
    }

    Process {
        id: nightModeProcess
        command: ["sh", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/check_night_mode.sh"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const v = data.trim().toLowerCase()
                root.nightModeEnabled = (v === "true" || v === "1" || v === "on")
            }
        }
    }

    Process {
        id: volumeProcess
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const val = parseFloat(data.trim())
                if (!isNaN(val)) {
                    root.volumeValue = Math.max(0, Math.min(1, val))
                }
            }
        }
    }

    Process {
        id: setVolumeProcess
        running: false
        onExited: _code => actionRefreshTimer.restart()
    }

    Process {
        id: runActionProcess
        running: false

        onExited: _code => {
            actionRefreshTimer.restart()
            root.runStatePopupForAction(root.lastActionItemId)
        }
    }

    Process {
        id: statePopupProcess
        running: false
    }

    Timer {
        id: actionRefreshTimer
        interval: 350
        onTriggered: root.refreshState()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshState()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.syncFromTrackedNotifications()
    }
}
