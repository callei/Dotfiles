// NotificationWidget.qml - Quickshell notifications toggle
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Common" as Common
import "../../../Services" as Services
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    paddingLeft: 7
    paddingRight: 7

    Widgets.Icon {
        icon: ""
        iconSize: Common.Theme.fontSizeLarge
    }

    onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
            Services.ShellService.toggleWidget("notifications")
        }
    }

    onPressed: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            Services.ShellService.toggleWidget("notifications")
        }
    }
}
