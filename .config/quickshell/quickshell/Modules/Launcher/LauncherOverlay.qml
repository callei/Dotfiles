// LauncherOverlay.qml - Application launcher with recents and improved icon fallbacks
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common" as Common
import "../../Services" as Services
import "../../Widgets" as Widgets

PanelWindow {
    id: root

    signal overlayClose()

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-shell:launcher"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    property bool launcherTargetVisible: Services.ShellService.launcherVisible
    visible: launcherTargetVisible || fadeOutHold.running

    onLauncherTargetVisibleChanged: {
        if (launcherTargetVisible) {
            searchInput.text = ""
            keyboardSelectionLock = false
            rebuildFiltered()
            searchInput.forceActiveFocus()
        } else {
            fadeOutHold.restart()
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property string wpctlPath: Quickshell.env("HOME") + "/.config/quickshell/bin/wpctl"
    readonly property string recentsPath: Quickshell.env("HOME") + "/.cache/quickshell-shell/launcher-recent.txt"

    property var allApps: []
    property var recentIds: []
    property string selectedId: ""
    property bool keyboardSelectionLock: false
    property string statusText: "Loading applications..."
    readonly property color panelBackgroundColor: Qt.rgba(Common.Theme.background.r, Common.Theme.background.g, Common.Theme.background.b, 0.46)

    Timer {
        id: fadeOutHold
        interval: 95
    }

    Component.onCompleted: {
        loadApps()
        loadRecents()
    }

    function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'"
    }

    function loadApps() {
        appsProcess.running = true
    }

    function loadRecents() {
        recentsLoadProcess.running = true
    }

    function saveRecents() {
        const lines = recentIds.slice(0, 30)
        let script = "mkdir -p " + shellQuote(Quickshell.env("HOME") + "/.cache/quickshell-shell") + "\\n"
        script += "cat > " + shellQuote(recentsPath) + " <<'EOF'\\n"
        script += lines.join("\\n") + "\\nEOF"
        recentsSaveProcess.command = ["sh", "-c", script]
        recentsSaveProcess.running = true
    }

    function markRecent(appId) {
        const trimmed = String(appId || "")
        if (trimmed.length === 0) return
        const filtered = []
        filtered.push(trimmed)
        for (let i = 0; i < recentIds.length; i++) {
            if (recentIds[i] !== trimmed) {
                filtered.push(recentIds[i])
            }
            if (filtered.length >= 30) break
        }
        recentIds = filtered
        saveRecents()
    }

    function recentRank(appId) {
        const idx = recentIds.indexOf(appId)
        return idx >= 0 ? (1000 - idx) : 0
    }

    function rebuildFiltered() {
        filtered.clear()

        const query = searchInput.text.trim().toLowerCase()
        const candidates = []

        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i]
            const name = String(app.name || "")
            const id = String(app.id || "")
            const icon = String(app.icon || "")
            const iconPath = String(app.iconPath || "")
            const lName = name.toLowerCase()
            const lId = id.toLowerCase()

            if (query !== "" && lName.indexOf(query) < 0 && lId.indexOf(query) < 0) {
                continue
            }

            let score = recentRank(id)
            if (query !== "") {
                if (lName.startsWith(query)) score += 350
                if (lId.startsWith(query)) score += 280
                if (lName.indexOf(query) >= 0) score += 140
                if (lId.indexOf(query) >= 0) score += 80
            }

            candidates.push({
                id: id,
                name: name,
                icon: icon,
                iconPath: iconPath,
                score: score,
                recent: recentRank(id) > 0
            })
        }

        candidates.sort((a, b) => {
            if (a.score !== b.score) return b.score - a.score
            return a.name.localeCompare(b.name)
        })

        for (let j = 0; j < candidates.length && j < 80; j++) {
            filtered.append(candidates[j])
        }

        if (filtered.count > 0) {
            let selectedStillExists = false
            for (let k = 0; k < filtered.count; k++) {
                if (filtered.get(k).id === selectedId) {
                    selectedStillExists = true
                    break
                }
            }
            if (!selectedStillExists) {
                selectedId = filtered.get(0).id
            }
            statusText = ""
        } else {
            selectedId = ""
            statusText = "No matching applications"
        }
    }

    function getSelectedIndex() {
        for (let i = 0; i < filtered.count; i++) {
            if (filtered.get(i).id === selectedId) return i
        }
        return 0
    }

    function selectIndexWithScroll(idx) {
        if (idx < 0 || idx >= filtered.count) return
        selectedId = filtered.get(idx).id
        appList.positionViewAtIndex(idx, ListView.Contain)
    }

    function launchSelected() {
        if (selectedId === "") return
        launchProcess.command = [root.wpctlPath, "launch", root.selectedId]
        launchProcess.running = true
    }

    ListModel {
        id: filtered
    }

    Process {
        id: appsProcess
        command: [root.wpctlPath, "apps", "--json"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allApps = JSON.parse(this.text)
                    root.rebuildFiltered()
                } catch (_e) {
                    root.statusText = "Failed to parse app list"
                }
            }
        }

        onExited: code => {
            if (code !== 0) {
                root.statusText = "Failed to load apps"
            }
        }
    }

    Process {
        id: recentsLoadProcess
        command: ["sh", "-c", "cat " + root.shellQuote(root.recentsPath) + " 2>/dev/null || true"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const lines = data.split("\n")
                const items = []
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (line.length > 0) items.push(line)
                }
                root.recentIds = items
                root.rebuildFiltered()
            }
        }
    }

    Process {
        id: recentsSaveProcess
        running: false
    }

    Process {
        id: launchProcess
        running: false

        onExited: code => {
            if (code === 0) {
                root.markRecent(root.selectedId)
                root.overlayClose()
            } else {
                root.statusText = "Launch failed"
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: root.overlayClose()
    }

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            enabled: root.launcherTargetVisible
            onClicked: root.overlayClose()
        }
    }

    Rectangle {
        id: launcherPanel
        width: 500
        height: Math.min(520, parent.height * 0.62)
        anchors.centerIn: parent
        radius: Common.Theme.radiusLarge
        clip: true
        opacity: root.launcherTargetVisible ? 1 : 0
        color: root.panelBackgroundColor
        border.width: 1
        border.color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.12)

        Behavior on opacity {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            z: 2
            anchors.fill: parent
            anchors.margins: Common.Theme.spacingLg
            spacing: Common.Theme.spacingMd

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: Common.Theme.radiusMedium
                color: Qt.rgba(Common.Theme.foreground.r, Common.Theme.foreground.g, Common.Theme.foreground.b, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Common.Theme.spacingMd
                    spacing: Common.Theme.spacingMd

                    Widgets.Icon {
                        icon: ""
                        color: Common.Theme.surfaceVariant
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Search applications..."
                        font.family: Common.Theme.fontFamily
                        font.pointSize: Common.Theme.fontSizeMedium
                        color: Common.Theme.foreground
                        placeholderTextColor: Common.Theme.surfaceVariant
                        background: null
                        verticalAlignment: TextInput.AlignVCenter
                        topPadding: 3
                        bottomPadding: 3
                        leftPadding: 0
                        rightPadding: 0

                        onTextChanged: root.rebuildFiltered()

                        Keys.onUpPressed: {
                            root.keyboardSelectionLock = true
                            const idx = root.getSelectedIndex()
                            if (idx > 0) root.selectIndexWithScroll(idx - 1)
                        }

                        Keys.onDownPressed: {
                            root.keyboardSelectionLock = true
                            const idx = root.getSelectedIndex()
                            if (idx < filtered.count - 1) root.selectIndexWithScroll(idx + 1)
                        }

                        Keys.onReturnPressed: root.launchSelected()

                        Component.onCompleted: forceActiveFocus()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ListView {
                    id: appList
                    anchors.fill: parent
                    clip: true
                    model: filtered
                    spacing: Common.Theme.spacingXs
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 620
                    maximumFlickVelocity: 1900

                    delegate: Rectangle {
                        required property int index
                        required property var model
                        readonly property string appNameKey: String(model.name || "").toLowerCase()
                        readonly property string appIdKey: String(model.id || "").toLowerCase()
                        readonly property string appIconKey: String(model.icon || "").toLowerCase()
                        readonly property bool hasIconPath: model.iconPath && model.iconPath.length > 0
                        readonly property string iconIdBase: String(model.id || "").replace(/\.desktop$/i, "")
                        readonly property string iconNameKey: String(model.name || "").toLowerCase().replace(/[^a-z0-9]+/g, "-")
                        readonly property string iconNameFlat: String(model.name || "").toLowerCase().replace(/[^a-z0-9]+/g, "")
                        readonly property string iconFallbackKey: (appIdKey.indexOf("avahi") >= 0 || appNameKey.indexOf("avahi") >= 0 || appIdKey === "bssh.desktop" || appIdKey === "bvnc.desktop")
                                                                  ? "network-workgroup"
                                                                  : ((appIdKey.indexOf("lstopo") >= 0 || appIconKey === "hwloc")
                                                                    ? "utilities-system-monitor"
                                                                    : "")

                        width: appList.width
                        height: 48
                        radius: Common.Theme.radiusMedium
                        color: "transparent"
                        border.width: model.id === root.selectedId ? 2 : 0
                        border.color: model.id === root.selectedId
                                      ? Qt.rgba(Common.Theme.primary.r, Common.Theme.primary.g, Common.Theme.primary.b, 0.95)
                                      : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Common.Theme.spacingSm
                            spacing: Common.Theme.spacingMd

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32

                                Image {
                                    id: pathIcon
                                    anchors.fill: parent
                                    source: hasIconPath ? "file://" + model.iconPath : ""
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    visible: hasIconPath && status === Image.Ready
                                }

                                Image {
                                    id: themedIcon
                                    anchors.fill: parent
                                    source: (!hasIconPath && model.icon && model.icon.length > 0) ? "image://icon/" + model.icon : ""
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    visible: !hasIconPath && status === Image.Ready
                                }

                                Image {
                                    id: themedIconById
                                    anchors.fill: parent
                                    source: (!hasIconPath && !themedIcon.visible && iconIdBase.length > 0) ? "image://icon/" + iconIdBase : ""
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    visible: !hasIconPath && !themedIcon.visible && status === Image.Ready
                                }

                                Image {
                                    id: themedIconByName
                                    anchors.fill: parent
                                    source: (!hasIconPath && !themedIcon.visible && !themedIconById.visible && iconNameKey.length > 0) ? "image://icon/" + iconNameKey : ""
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    visible: !hasIconPath && !themedIcon.visible && !themedIconById.visible && status === Image.Ready
                                }

                                Image {
                                    id: themedIconByFlatName
                                    anchors.fill: parent
                                    source: (!hasIconPath && !themedIcon.visible && !themedIconById.visible && !themedIconByName.visible && iconNameFlat.length > 0) ? "image://icon/" + iconNameFlat : ""
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    visible: !hasIconPath && !themedIcon.visible && !themedIconById.visible && !themedIconByName.visible && status === Image.Ready
                                }

                                Image {
                                    id: themedIconFallback
                                    anchors.fill: parent
                                    source: (!themedIcon.visible && !themedIconById.visible && !themedIconByName.visible && !themedIconByFlatName.visible && !pathIcon.visible && iconFallbackKey.length > 0) ? "image://icon/" + iconFallbackKey : ""
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    visible: !themedIcon.visible && !themedIconById.visible && !themedIconByName.visible && !themedIconByFlatName.visible && !pathIcon.visible && status === Image.Ready
                                }

                                Widgets.Icon {
                                    anchors.centerIn: parent
                                    icon: "󰣆"
                                    iconSize: 18
                                    visible: !themedIcon.visible
                                             && !themedIconById.visible
                                             && !themedIconByName.visible
                                             && !themedIconByFlatName.visible
                                             && !pathIcon.visible
                                             && !themedIconFallback.visible
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.name || model.id
                                color: Common.Theme.foreground
                                font.family: Common.Theme.fontFamily
                                font.pointSize: Common.Theme.fontSizeMedium
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.keyboardSelectionLock = false
                                root.selectedId = model.id
                            }

                            onDoubleClicked: {
                                root.keyboardSelectionLock = false
                                root.selectedId = model.id
                                root.launchSelected()
                            }

                            onEntered: {
                                if (!root.keyboardSelectionLock) {
                                    root.selectedId = model.id
                                }
                            }

                            onPositionChanged: {
                                if (root.keyboardSelectionLock) root.keyboardSelectionLock = false
                                root.selectedId = model.id
                            }
                        }
                    }
                }

            }

            Text {
                Layout.fillWidth: true
                text: root.statusText
                visible: text.length > 0
                color: Common.Theme.surfaceVariant
                font.family: Common.Theme.fontFamily
                font.pointSize: Common.Theme.fontSizeSmall
                elide: Text.ElideRight
            }
        }
    }
}
