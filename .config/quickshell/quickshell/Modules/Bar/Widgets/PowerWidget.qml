// PowerWidget.qml - Wlogout launcher
import QtQuick
import "../../../Common" as Common
import "../../../Services" as Services
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    paddingLeft: 9
    paddingRight: 7

    Widgets.Icon {
        icon: ""
        iconSize: Common.Theme.fontSizeLarge
    }

    onClicked: Services.ShellService.toggleWidget("power")
}
