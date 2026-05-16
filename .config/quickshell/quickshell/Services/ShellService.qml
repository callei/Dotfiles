// ShellService.qml - Central service for shell state and IPC
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Loader references (set by UnifiedShell)
    property var launcherLoader: null
    property var wallpaperPickerLoader: null
    property var networkLoader: null
    property var bluetoothLoader: null
    property var notificationsLoader: null
    property var notificationServer: null

    // State
    property bool launcherVisible: false
    property bool wallpaperPickerVisible: false
    property bool networkVisible: false
    property bool bluetoothVisible: false
    property bool notificationsVisible: false
    property bool powerVisible: false

    property string activeWidget: "hidden"

    // Process to read IPC file
    Process {
        id: ipcReader
        command: ["sh", "-c", "if [ -f /tmp/qs_widget_state ]; then cat /tmp/qs_widget_state; rm -f /tmp/qs_widget_state; fi"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const output = data.trim()
                if (output) {
                    root.processWidgetCommand(output)
                }
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        
        onTriggered: {
            ipcReader.running = true
        }
    }

    function processWidgetCommand(command: string) {
        if (!command || command.length === 0) return

        const parts = command.trim().split(":")
        const widget = parts[0]

        if (widget === "close") {
            closeAllOverlays()
            return
        }

        if (widget === "toggle" && parts.length > 1) {
            const target = parts[1]
            if (target.length > 0) {
                toggleWidget(target)
                return
            }
        }
        
        if (widget.length > 0) {
            openWidget(widget)
        }
    }

    function toggleWidget(widgetName: string) {
        switch (widgetName) {
            case "launcher":
                toggleLauncher()
                break
            case "wallpaper":
                toggleWallpaperPicker()
                break
            case "network":
                toggleNetworkPanel()
                break
            case "bluetooth":
                toggleBluetoothPanel()
                break
            case "notifications":
                toggleNotificationsPanel()
                break
            case "power":
                openPowerMenu()
                break
        }
    }

    function openWidget(widgetName: string) {
        switch (widgetName) {
            case "launcher":
                openLauncher()
                break
            case "wallpaper":
                openWallpaperPicker()
                break
            case "network":
                openNetworkPanel()
                break
            case "bluetooth":
                openBluetoothPanel()
                break
            case "notifications":
                openNotificationsPanel()
                break
            case "power":
                openPowerMenu()
                break
        }
    }

    function writeActiveWidget(widgetName: string) {
        activeWidget = widgetName
        const safe = widgetName.replace(/'/g, "'\\''")
        Quickshell.execDetached(["sh", "-c", "printf '%s' '" + safe + "' > /tmp/qs_active_widget"])
    }

    // Launcher
    function toggleLauncher() {
        if (launcherVisible) {
            closeLauncher()
        } else {
            openLauncher()
        }
    }

    function openLauncher() {
        closeAllOverlays()
        if (launcherLoader) {
            launcherLoader.active = true
            launcherVisible = true
            writeActiveWidget("launcher")
        }
    }

    function closeLauncher() {
        launcherVisible = false
        if (activeWidget === "launcher") writeActiveWidget("hidden")
    }

    // Wallpaper Picker
    function toggleWallpaperPicker() {
        if (wallpaperPickerVisible) {
            closeWallpaperPicker()
        } else {
            openWallpaperPicker()
        }
    }

    function openWallpaperPicker() {
        closeAllOverlays()
        if (wallpaperPickerLoader) {
            wallpaperPickerLoader.active = true
            wallpaperPickerVisible = true
            writeActiveWidget("wallpaper")
        }
    }

    function closeWallpaperPicker() {
        if (wallpaperPickerLoader) {
            wallpaperPickerLoader.active = false
            wallpaperPickerVisible = false
        }
        if (activeWidget === "wallpaper") writeActiveWidget("hidden")
    }

    // Network
    function toggleNetworkPanel() {
        if (networkVisible) {
            closeNetworkPanel()
        } else {
            openNetworkPanel()
        }
    }

    function openNetworkPanel() {
        closeAllOverlays()
        if (networkLoader) {
            networkLoader.active = true
            networkVisible = true
            writeActiveWidget("network")
        }
    }

    function closeNetworkPanel() {
        if (networkLoader) {
            networkLoader.active = false
            networkVisible = false
        }
        if (activeWidget === "network") writeActiveWidget("hidden")
    }

    // Bluetooth
    function toggleBluetoothPanel() {
        if (bluetoothVisible) {
            closeBluetoothPanel()
        } else {
            openBluetoothPanel()
        }
    }

    function openBluetoothPanel() {
        closeAllOverlays()
        if (bluetoothLoader) {
            bluetoothLoader.active = true
            bluetoothVisible = true
            writeActiveWidget("bluetooth")
        }
    }

    function closeBluetoothPanel() {
        if (bluetoothLoader) {
            bluetoothLoader.active = false
            bluetoothVisible = false
        }
        if (activeWidget === "bluetooth") writeActiveWidget("hidden")
    }

    // Notifications
    function toggleNotificationsPanel() {
        if (notificationsVisible) {
            closeNotificationsPanel()
        } else {
            openNotificationsPanel()
        }
    }

    function openNotificationsPanel() {
        closeAllOverlays()
        if (notificationsLoader) {
            notificationsLoader.active = true
            notificationsVisible = true
            writeActiveWidget("notifications")
        }
    }

    function closeNotificationsPanel() {
        notificationsVisible = false
        if (activeWidget === "notifications") writeActiveWidget("hidden")
    }

    // Close all overlays
    function closeAllOverlays() {
        closeLauncher()
        closeWallpaperPicker()
        closeNetworkPanel()
        closeBluetoothPanel()
        closeNotificationsPanel()
        writeActiveWidget("hidden")
    }

    function openPowerMenu() {
        closeAllOverlays()
        if (powerMenuProcess.running) return
        powerVisible = true
        writeActiveWidget("power")
        powerMenuProcess.running = true
    }

    Process {
        id: powerMenuProcess
        command: ["wlogout"]
        running: false

        onExited: _code => {
            powerVisible = false
            if (activeWidget === "power") {
                writeActiveWidget("hidden")
            }
        }
    }
}
