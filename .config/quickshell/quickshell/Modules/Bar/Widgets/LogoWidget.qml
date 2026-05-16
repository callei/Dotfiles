// LogoWidget.qml - App launcher trigger
import QtQuick
import Quickshell
import "../../../Common" as Common
import "../../../Services" as Services
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    paddingLeft: 9
    paddingRight: 6

    Widgets.Icon {
        icon: "\udb82\udcc7"  // Arch Linux logo
        iconSize: Common.Theme.fontSizeLarge
    }

    onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
            Services.ShellService.toggleWidget("launcher")
        }
    }
}
