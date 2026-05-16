// Theme.qml - Dynamic theme system using one canonical theme source
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string lastThemeContent: ""

    // Semantic colors
    property color background: color0
    property color surface: Qt.rgba(color0.r, color0.g, color0.b, 0.85)
    property color surfaceVariant: color8
    property color foreground: fg
    property color primary: accent
    property color secondary: color2
    property color outline: Qt.rgba(fg.r, fg.g, fg.b, 0.2)
    property color error: "#f38ba8"
    property color success: "#a6e3a1"
    property color warning: "#f9e2af"

    // Raw palette from theme file
    property string wallpaper: ""
    property color bg: "#262320"
    property color fg: "#f6d8c6"
    property color accent: "#e8a278"

    property color color0: "#262320"
    property color color1: "#784505"
    property color color2: "#6c8295"
    property color color3: "#e8a278"
    property color color4: "#755c55"
    property color color5: "#c2ab9d"
    property color color6: "#dcc1b1"
    property color color7: "#f6d8c6"
    property color color8: "#60564e"
    property color color9: "#ebae89"
    property color color10: "#94652f"
    property color color11: "#8a95a0"
    property color color12: "#91776e"
    property color color13: "#cdb5a6"
    property color color14: "#e2c6b6"
    property color color15: "#f7dbcb"

    // Design tokens
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 16
    readonly property int radiusLarge: 20
    readonly property int radiusFull: 999

    readonly property int spacingXs: 8
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24
    readonly property int spacing2xMd: spacingMd * 2

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 14
    readonly property int fontSizeXl: 18
    readonly property real letterSpacing: 1

    readonly property real shadowOpacity: 0.3
    readonly property int shadowBlur: 40
    readonly property int shadowOffset: 5

    // Animation durations
    readonly property int animFast: 150
    readonly property int animNormal: 250
    readonly property int animSlow: 400

    // Bar-specific
    readonly property int barHeight: 50
    readonly property int barMargin: 0
    readonly property int barPaddingTop: 12
    readonly property int barPaddingBottom: 8
    readonly property int barModuleGap: spacing2xMd
    readonly property int barEdgeInset: barModuleGap
    readonly property int barEdgeInsetRight: 23
    readonly property int moduleRadius: radiusLarge
    readonly property int modulePaddingX: 14
    readonly property int modulePaddingY: 11
    readonly property real moduleOpacity: 0.65
    readonly property int workspacePillRadius: 20

    // Theme loading
    readonly property string themePath: Quickshell.env("HOME") + "/.config/themes/current.conf"

    Component.onCompleted: loadTheme()

    Process {
        id: themeLoader
        command: [
            "bash",
            "-c",
            "[ -f \"" + root.themePath + "\" ] && cat \"" + root.themePath + "\""
        ]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyThemeConf(this.text)
        }

        onExited: (code) => {
            if (code === 0) {
                console.log("Theme loaded successfully")
            }
        }
    }

    function loadTheme() {
        themeLoader.running = true
    }

    function applyThemeConf(content) {
        if (!content || content.length === 0) return
        if (content === root.lastThemeContent) return
        root.lastThemeContent = content
        root.parseThemeConf(content)
    }

    function parseThemeConf(content) {
        const lines = content.split('\n')
        for (let line of lines) {
            line = line.trim()
            if (line.startsWith('#') || !line.includes('=')) continue

            const parts = line.split('=')
            if (parts.length !== 2) continue

            const key = parts[0].trim().replace('$', '')
            let value = parts[1].trim()

            // Parse rgba colors to hex
            if (value.startsWith('rgba(') && value.endsWith(')')) {
                const hex = value.substring(5, value.length - 3)
                value = '#' + hex.substring(0, 6)
            }

            // Set properties dynamically
            if (root.hasOwnProperty(key)) {
                root[key] = value
            }
        }
    }

    // File watcher for live theme updates
    FileView {
        id: themeWatcher
        path: root.themePath
        onTextChanged: root.applyThemeConf(text)
    }

    // Fallback polling avoids stale colors if file notifications are missed.
    Timer {
        interval: 1200
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.loadTheme()
    }
}
