// MemoryWidget.qml - RAM usage
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Common" as Common
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    hoverable: false
    paddingLeft: 13
    paddingRight: 12

    property int percentage: 0

    property int minModuleWidth: 48
    width: Math.max(minModuleWidth, contentRow.implicitWidth + paddingLeft + paddingRight)
    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Row {
        id: contentRow
        spacing: 12 // increased spacing between icon and percentage

        Widgets.Icon {
            icon: ""
        }

        Widgets.Text {
            text: root.percentage + "%"
        }
    }
    Process {
        id: memoryProcess
        command: ["sh", "-c", "free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100.0}'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val)) root.percentage = val
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memoryProcess.running = true
    }
}
