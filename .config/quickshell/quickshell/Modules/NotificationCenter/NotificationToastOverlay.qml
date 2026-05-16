// NotificationToastOverlay.qml - Lightweight notification toasts
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications as QSNotifications
import "../../Common" as Common
import "../../Services" as Services

PanelWindow {
    id: root
    readonly property int toastWidth: 320
    readonly property var notificationServer: Services.ShellService.notificationServer
    property var seenIds: ({})
    property bool initialized: false

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-shell:notification-toasts"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: toastWidth
    implicitHeight: toastColumn.implicitHeight
    visible: toastModel.count > 0

    anchors {
        right: true
        bottom: true
    }

    margins {
        right: Common.Theme.spacingXl
        bottom: Common.Theme.spacingXl
    }

    ListModel { id: toastModel }

    function notificationAt(model, index) {
        if (!model || index < 0) return null
        if (typeof model.objectAt === "function") return model.objectAt(index)
        if (typeof model.get === "function") return model.get(index)
        return null
    }

    function addToast(notification) {
        if (!notification) return

        toastModel.insert(0, {
            toastId: notification.id,
            summary: notification.summary && notification.summary.length > 0 ? notification.summary : "Notification",
            body: notification.body || "",
            appName: notification.appName || "",
            urgency: notification.urgency
        })

        if (toastModel.count > 3) {
            toastModel.remove(3, toastModel.count - 3)
        }
    }

    function removeToastById(id) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).toastId === id) {
                toastModel.remove(i)
                return
            }
        }
    }

    function syncToasts() {
        const server = root.notificationServer
        if (!server || !server.trackedNotifications) return

        const tracked = server.trackedNotifications
        if (typeof tracked.count !== "number") return

        for (let i = tracked.count - 1; i >= 0; i--) {
            const n = notificationAt(tracked, i)
            if (!n) continue
            if (seenIds[n.id]) continue
            seenIds[n.id] = true
            if (initialized) addToast(n)
        }
    }

    function urgencyColor(urgency) {
        if (urgency === QSNotifications.NotificationUrgency.Critical) return Common.Theme.warning
        if (urgency === QSNotifications.NotificationUrgency.Low) return Common.Theme.surfaceVariant
        return Common.Theme.foreground
    }

    Component.onCompleted: {
        syncToasts()
        initialized = true
    }

    onNotificationServerChanged: syncToasts()

    Connections {
        target: root.notificationServer
        function onNotification(notification) {
            notification.tracked = true
            seenIds[notification.id] = true
            root.addToast(notification)
        }
    }

    ColumnLayout {
        id: toastColumn
        width: parent.width
        spacing: Common.Theme.spacingSm

        Repeater {
            model: toastModel

            delegate: Rectangle {
                required property var modelData

                Layout.preferredWidth: root.toastWidth
                implicitHeight: toastContent.implicitHeight + Common.Theme.spacingSm * 2
                Layout.preferredHeight: implicitHeight
                radius: Common.Theme.radiusMedium
                color: Qt.rgba(Common.Theme.background.r, Common.Theme.background.g, Common.Theme.background.b, 0.92)
                border.width: 1
                border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

                ColumnLayout {
                    id: toastContent
                    anchors.fill: parent
                    anchors.margins: Common.Theme.spacingSm
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            color: root.urgencyColor(modelData.urgency)
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeMedium
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.appName
                            color: Common.Theme.surfaceVariant
                            font.family: Common.Theme.fontFamily
                            font.pointSize: Common.Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: modelData.body && modelData.body.length > 0
                        text: modelData.body
                        color: Common.Theme.foreground
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeSmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeToastById(modelData.toastId)
                }

                Timer {
                    interval: 4500
                    running: true
                    onTriggered: root.removeToastById(modelData.toastId)
                }
            }
        }
    }
}
