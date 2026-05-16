// Text.qml - Styled text component
import QtQuick
import qs.Common

Text {
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeMedium
    font.letterSpacing: Theme.letterSpacing
    font.hintingPreference: Font.PreferFullHinting
    color: Theme.foreground
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
