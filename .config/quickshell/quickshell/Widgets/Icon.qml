// Icon.qml - Icon component using Nerd Font
import QtQuick
import qs.Common

Text {
    property string icon: ""
    property int iconSize: Theme.fontSizeMedium

    text: icon
    font.family: Theme.fontFamily
    font.pixelSize: iconSize
    font.letterSpacing: Theme.letterSpacing * 0.8
    font.hintingPreference: Font.PreferFullHinting
    color: Theme.foreground
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
    width: iconSize + 2
    height: Math.max(implicitHeight, iconSize + 2)
}
