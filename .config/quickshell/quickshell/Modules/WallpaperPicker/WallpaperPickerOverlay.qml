import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../wallpaper" as Upstream

PanelWindow {
    id: root

    signal overlayClose()

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-shell:wallpaper-picker"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Upstream.WallpaperPicker {
        anchors.fill: parent
    }
}
