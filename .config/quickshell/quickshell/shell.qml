// shell.qml - Main shell orchestrator
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications as QSNotifications
import "Common" as Common
import "Services" as Services
import "Modules/Bar" as BarModule
import "Modules/Launcher" as LauncherModule
import "Modules/Network" as NetworkModule
import "Modules/Bluetooth" as BluetoothModule
import "Modules/NotificationCenter" as NotificationCenterModule
import "Modules/OSD" as OsdModule
import "Modules/WallpaperPicker" as WallpaperPickerModule
import "Widgets" as Widgets

ShellRoot {
    id: root

    Component.onCompleted: {
        // Initialize services on startup
        Services.ShellService // Force singleton initialization
    }

    // Bar on each screen
    Variants {
        model: Quickshell.screens

        delegate: BarModule.Bar {
            required property var modelData
            screen: modelData
        }
    }

    QSNotifications.NotificationServer {
        id: notificationServer

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: true

        Component.onCompleted: {
            Services.ShellService.notificationServer = notificationServer
        }

        onNotification: notification => {
            // Keep notifications available to custom panels and popups until dismissed.
            notification.tracked = true
        }
    }

    // Keep launcher preloaded so app list is ready immediately after login.
    LazyLoader {
        id: launcherLoader
        active: true

        Component.onCompleted: {
            Services.ShellService.launcherLoader = launcherLoader
        }

        LauncherModule.LauncherOverlay {
            id: launcherOverlay
            onOverlayClose: Services.ShellService.closeLauncher()
        }
    }

    LazyLoader {
        id: wallpaperPickerLoader
        active: false

        Component.onCompleted: {
            Services.ShellService.wallpaperPickerLoader = wallpaperPickerLoader
        }

        WallpaperPickerModule.WallpaperPickerOverlay {
            id: wallpaperPickerOverlay
            onOverlayClose: Services.ShellService.closeWallpaperPicker()
        }
    }

    LazyLoader {
        id: networkLoader
        active: false

        Component.onCompleted: {
            Services.ShellService.networkLoader = networkLoader
        }

        NetworkModule.NetworkOverlay {
            id: networkOverlay
            onOverlayClose: Services.ShellService.closeNetworkPanel()
        }
    }

    LazyLoader {
        id: bluetoothLoader
        active: false

        Component.onCompleted: {
            Services.ShellService.bluetoothLoader = bluetoothLoader
        }

        BluetoothModule.BluetoothOverlay {
            id: bluetoothOverlay
            onOverlayClose: Services.ShellService.closeBluetoothPanel()
        }
    }

    LazyLoader {
        id: notificationsLoader
        active: false

        Component.onCompleted: {
            Services.ShellService.notificationsLoader = notificationsLoader
        }

        NotificationCenterModule.NotificationCenterOverlay {
            id: notificationCenterOverlay
            onOverlayClose: Services.ShellService.closeNotificationsPanel()
        }
    }

    // Notification toasts always active.
    NotificationCenterModule.NotificationToastOverlay {}

    // OSD remains active and runs in parallel with external tools.
    OsdModule.OsdOverlay {}
}
