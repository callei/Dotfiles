// Module.qml - Reusable pill-shaped module container
import QtQuick
import QtQuick.Effects
import qs.Common

Rectangle {
    id: root

    default property alias content: contentRow.data
    property bool hoverable: true
    property bool autoSizeContentWidth: true
    property real contentWidth: 40  // default minimum
    property int paddingLeft: 0
    property int paddingRight: 0
    property int paddingY: Theme.modulePaddingY
    property int contentSpacing: Theme.spacingXs
    property int moduleRadius: Theme.moduleRadius
    property bool passThroughComposedEvents: false
    readonly property bool hovered: mouseArea.containsMouse

    implicitHeight: contentRow.implicitHeight + paddingY * 2
    implicitWidth: contentWidth + paddingLeft + paddingRight

    radius: moduleRadius
    color: "transparent"

    Rectangle {
        id: backgroundSource
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.moduleOpacity)
        visible: false

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    // Drop shadow similar to Waybar: 3px 3px 8px rgba(0,0,0,0.3)
    MultiEffect {
        anchors.fill: parent
        source: backgroundSource
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, Theme.shadowOpacity)
        shadowHorizontalOffset: Theme.shadowOffset + 1
        shadowVerticalOffset: Theme.shadowOffset + 1
        shadowBlur: Math.max(0.35, Theme.shadowBlur / 36)
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.leftMargin: root.paddingLeft
        anchors.rightMargin: root.paddingRight
        anchors.topMargin: root.paddingY
        anchors.bottomMargin: root.paddingY

        Row {
            id: contentRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.contentSpacing
            onImplicitWidthChanged: {
                if (root.autoSizeContentWidth) {
                    root.contentWidth = Math.max(implicitWidth, 20)
                }
            }
        }
    }

    // Hover effect
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.hoverable && mouseArea.containsMouse
               ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
               : "transparent"
        visible: root.hoverable

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        visible: !root.passThroughComposedEvents
        enabled: !root.passThroughComposedEvents
        hoverEnabled: root.hoverable && !root.passThroughComposedEvents
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: root.passThroughComposedEvents
        cursorShape: root.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor

        // Forward clicks to parent
        onClicked: (mouse) => {
            root.clicked(mouse)
            if (root.passThroughComposedEvents) mouse.accepted = false
        }
        onPressed: (mouse) => {
            root.pressed(mouse)
            if (root.passThroughComposedEvents) mouse.accepted = false
        }
        onReleased: (mouse) => {
            root.released(mouse)
            if (root.passThroughComposedEvents) mouse.accepted = false
        }
    }

    signal clicked(var mouse)
    signal pressed(var mouse)
    signal released(var mouse)
}
