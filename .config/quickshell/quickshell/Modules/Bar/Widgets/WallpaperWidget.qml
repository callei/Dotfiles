// WallpaperWidget.qml - Wallpaper picker trigger
import QtQuick
import "../../../Common" as Common
import "../../../Services" as Services
import "../../../Widgets" as Widgets

Widgets.Module {
    id: root
    paddingLeft: 11
    paddingRight: 11

    Widgets.Icon {
        icon: "󰸉"
        iconSize: Common.Theme.fontSizeLarge
    }

    onClicked: Services.ShellService.toggleWidget("wallpaper")
}
