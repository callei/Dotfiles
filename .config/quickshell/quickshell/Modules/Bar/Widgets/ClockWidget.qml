import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../Common" as Common
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    hoverable: true
    paddingLeft: 14
    paddingRight: 14
    property string dateText: ""
    property bool popupVisible: false
    property int popupOffsetX: -75
    property int popupOffsetY: 20

    function updateDate() {
        const now = new Date()
        dateText = Qt.formatDate(now, "dddd d MMMM")
    }

    function updatePopupPosition() {
        if (!popupVisible) return
        const base = timeText.mapToGlobal(timeText.width / 2, timeText.height)
        dateOverlay.margins.left = Math.max(0, Math.round(base.x - dateOverlay.width / 2 + popupOffsetX))
        dateOverlay.margins.top = Math.max(0, Math.round(base.y + popupOffsetY))
    }

    Item {
        implicitWidth: timeText.implicitWidth
        implicitHeight: Math.max(timeText.implicitHeight, Common.Theme.fontSizeLarge)

        Widgets.Text {
            id: timeText
            anchors.centerIn: parent

            function updateTime() {
                const now = new Date()
                text = Qt.formatTime(now, "HH:mm")
                root.updateDate()
            }

            Component.onCompleted: updateTime()
        }
    }

    PanelWindow {
        id: dateOverlay
        visible: popupVisible || datePopup.opacity > 0
        screen: root.window ? root.window.screen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        color: "transparent"
        
        implicitWidth: datePopup.implicitWidth
        implicitHeight: datePopup.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-shell:clock-date"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
        }

        margins {
            top: 0
            left: 0
        }

        Rectangle {
            id: datePopup
            anchors.fill: parent
            radius: Common.Theme.radiusSmall
            color: Qt.rgba(Common.Theme.background.r, Common.Theme.background.g, Common.Theme.background.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)
            opacity: popupVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            implicitWidth: dateLabel.implicitWidth + 18
            implicitHeight: dateLabel.implicitHeight + 12

            Widgets.Text {
                id: dateLabel
                anchors.centerIn: parent
                text: root.dateText
                
                font.pixelSize: -1
                font.pointSize: Common.Theme.fontSizeSmall
            }
        }
        onVisibleChanged: {
            if (visible) root.updatePopupPosition()
        }
    }

    onHoveredChanged: {
        if (root.hovered) {
            root.updatePopupPosition()
            popupVisible = true
        } else {
            popupVisible = false
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: timeText.updateTime()
    }
}