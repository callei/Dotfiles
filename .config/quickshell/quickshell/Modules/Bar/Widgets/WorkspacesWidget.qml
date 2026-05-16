// WorkspacesWidget.qml - Hyprland workspace indicator
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../Common" as Common
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    hoverable: false
    passThroughComposedEvents: true

    paddingLeft: 7
    paddingRight: 7
    paddingY: 8

    // Match the visual outer height of the regular bar pills while keeping 7px inner padding.
    readonly property int targetOuterHeight: Common.Theme.fontSizeLarge + Common.Theme.modulePaddingY * 2 + 4
    implicitHeight: targetOuterHeight

    readonly property int indicatorHeight: Math.max(10, targetOuterHeight - paddingY * 2)
    readonly property int inactiveIndicatorWidth: 25
    readonly property int activeIndicatorWidth: inactiveIndicatorWidth + 17
    readonly property int widthDelta: activeIndicatorWidth - inactiveIndicatorWidth

    property int focusedWsId: 1
    property int previousFocusedWsId: 1
    property real switchProgress: 1.0

    Component.onCompleted: {
        const current = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
        focusedWsId = current
        previousFocusedWsId = current
        switchProgress = 1
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            const next = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
            if (next === root.focusedWsId) return
            root.previousFocusedWsId = root.focusedWsId
            root.focusedWsId = next
            root.switchProgress = 0
            switchAnim.restart()
        }
    }

    NumberAnimation {
        id: switchAnim
        target: root
        property: "switchProgress"
        from: 0
        to: 1
        duration: 320
        easing.type: Easing.OutCubic
    }

    function widthForWorkspace(wsId) {
        const prevId = previousFocusedWsId
        const currentId = focusedWsId

        if (wsId === currentId) {
            return inactiveIndicatorWidth + widthDelta * switchProgress
        }
        if (wsId === prevId) {
            return activeIndicatorWidth - widthDelta * switchProgress
        }
        return inactiveIndicatorWidth
    }

    function switchWorkspace(wsId) {
        if (Hyprland.usingLua) {
            // I Hyprland 0.55+ använder man hl.dsp.focus({ workspace = ID })
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
            return
        }
        // Gammal fallback för äldre Hyprland-versioner
        Hyprland.dispatch("workspace " + wsId)
    }
    
    Row {
        spacing: 6

        Repeater {
            model: 5

            Rectangle {
                required property int index
                readonly property int wsId: index + 1
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                readonly property bool isActive: root.focusedWsId === wsId
                readonly property bool isOccupied: ws !== undefined

                width: root.widthForWorkspace(wsId)
                height: root.indicatorHeight
                radius: height / 2 // always pill shape
                color: isActive
                    ? Common.Theme.color12
                    : (mouse.containsMouse
                        ? Qt.rgba(Common.Theme.color12.r, Common.Theme.color12.g, Common.Theme.color12.b, 0.55)
                        : (isOccupied
                            ? Common.Theme.color11
                            : Qt.rgba(Common.Theme.color11.r, Common.Theme.color11.g, Common.Theme.color11.b, 0.40)))
                Behavior on color {
                    ColorAnimation { duration: 320 }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.switchWorkspace(wsId)
                }
            }
        }
    }
}
