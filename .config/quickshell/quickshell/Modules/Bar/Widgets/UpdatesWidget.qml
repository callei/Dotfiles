// UpdatesWidget.qml - Package updates count
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Common" as Common
import "../../../Widgets" as Widgets

Widgets.Module {
        Timer {
            interval: 60000 // check every minute
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: updatesProcess.running = true
        }
    id: root
    paddingLeft: 11
    paddingRight: root.updateCount === 0 ? 20 : 14 // more right padding always, even more if 0
    moduleRadius: 20

    property int updateCount: 0


    property int minModuleWidth: 48
    width: Math.max(minModuleWidth, contentRow.implicitWidth + paddingLeft + paddingRight)
    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Row {
        id: contentRow
        spacing: 6

        Widgets.Icon {
            icon: ""
        }

        Widgets.Text {
            text: root.updateCount.toString()
        }
    }

    Process {
        id: updatesProcess
        command: [
            "bash",
            "-lc",
            "repo=0; aur=0; if command -v checkupdates >/dev/null 2>&1; then repo=$(checkupdates 2>/dev/null | wc -l); fi; if command -v yay >/dev/null 2>&1; then aur=$(yay -Qua 2>/dev/null | wc -l); fi; echo $((repo + aur))"
        ]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val)) root.updateCount = val
            }
        }
    }

    onClicked: {
        updateTerminalProcess.running = true
    }

    Process {
        id: updateTerminalProcess
        command: ["kitty", "--title", "system_update", "--class", "floatterm", "--detach",
                  "sh", "-c", Quickshell.env("HOME") + "/.config/waybar/scripts/system_update.sh"]
        running: false
    }
}
