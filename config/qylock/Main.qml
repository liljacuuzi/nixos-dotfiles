import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: root.cSurface

    // Dynamic Matugen Material You Dark palette (with upstream dark defaults as fallback)
    property string wallpaperSource: "bg.png"
    property color cSurface: "#131218"
    property color cSurfaceContainerLowest: "#1C1924"
    property color cSurfaceContainerLow: "#1C1B20"
    property color cSurfaceContainer: "#25232A"
    property color cSurfaceContainerHigh: "#2B2930"
    property color cSurfaceContainerHighest: "#36343B"
    property color cPrimary: "#D0BCFF"
    property color cPrimaryContainer: "#4F4461"
    property color cSecondaryContainer: "#3A3247"
    property color cOnSurface: "#E6E1E5"
    property color cOnSurfaceVariant: "#CBC2DB"
    property color cOutline: "#958DA5"
    property color cError: "#FFB4AB"
    property color cScrim: "#000000"

    function loadMatugenPalette() {
        var home = Quickshell.env("HOME") || "";
        if (!home) return;
        var url = "file://" + home + "/.cache/matugen/qylock-colors.json";
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", url, false);
            xhr.send();
            if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText) {
                var data = JSON.parse(xhr.responseText);
                if (data.wallpaper && data.wallpaper.length > 0) {
                    root.wallpaperSource = data.wallpaper.indexOf("file://") === 0
                        ? data.wallpaper
                        : "file://" + data.wallpaper;
                }
                if (data.surface) root.cSurface = data.surface;
                if (data.surface_container_lowest) root.cSurfaceContainerLowest = data.surface_container_lowest;
                if (data.surface_container_low) root.cSurfaceContainerLow = data.surface_container_low;
                if (data.surface_container) root.cSurfaceContainer = data.surface_container;
                if (data.surface_container_high) root.cSurfaceContainerHigh = data.surface_container_high;
                if (data.surface_container_highest) root.cSurfaceContainerHighest = data.surface_container_highest;
                if (data.primary) root.cPrimary = data.primary;
                if (data.primary_container) root.cPrimaryContainer = data.primary_container;
                if (data.secondary_container) root.cSecondaryContainer = data.secondary_container;
                if (data.on_surface) root.cOnSurface = data.on_surface;
                if (data.on_surface_variant) root.cOnSurfaceVariant = data.on_surface_variant;
                if (data.outline) root.cOutline = data.outline;
                if (data.error) root.cError = data.error;
                if (data.scrim) root.cScrim = data.scrim;
            }
        } catch (e) {
            console.warn("qylock material-you-dark: failed to load matugen palette:", e);
        }
    }

    // Background (active raw wallpaper from Matugen, fallback to bg.png)
    Image {
        id: bgImage
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        onStatusChanged: {
            if (status === Image.Error && source !== "bg.png") {
                source = "bg.png";
            }
        }
    }

    // Subtle dark scrim so clock & cards stay legible on bright wallpapers
    Rectangle {
        anchors.fill: parent
        color: root.cScrim
        opacity: 0.28
    }

    readonly property real s: Screen.height / 768
    property bool isQuickshell: typeof sddm === "undefined"
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0

    function getUserLogin() {
        if (userHelper.currentItem && userHelper.currentItem.uLogin) {
            return userHelper.currentItem.uLogin;
        }
        if (typeof userModel !== "undefined" && userModel) {
            if (typeof userModel.data === "function" && typeof userModel.index === "function") {
                var dataName = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 1);
                if (dataName) return dataName;
            }
            if (userModel.lastUser) return userModel.lastUser;
        }
        return "";
    }

    function getUserDisplayName() {
        if (userHelper.currentItem && userHelper.currentItem.uName) {
            return userHelper.currentItem.uName;
        }
        if (typeof userModel !== "undefined" && userModel) {
            if (typeof userModel.data === "function" && typeof userModel.index === "function") {
                var realName = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 2);
                if (realName) return realName;
                var dataName = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 1);
                if (dataName) return dataName;
            }
            if (userModel.lastUser) return userModel.lastUser;
        }
        return "USER";
    }

    // UI States
    property real ui1: 0
    property real ui2: 0
    property string errorMessage: ""
    property string pendingAction: "" // "" = unlock, "powerOff", "reboot"

    // Fonts
    FontLoader {
        id: customFont
        source: "font/GoogleSans-VariableFont_GRAD,opsz,wght.ttf"
    }

    readonly property string sansFont: customFont.name !== "" ? customFont.name : "Roboto, Inter, sans-serif"

    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item {
            property string sName: model.name || ""
        }
    }

    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    Timer {
        id: focusTimer
        interval: 250
        running: true
        onTriggered: pwd.forceActiveFocus()
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.errorMessage = "ACCESS DENIED";
            pwd.text = "";
            shakeAnim.start();
            errTimer.start();
        }
    }

    Timer {
        id: errTimer
        interval: 3000
        onTriggered: root.errorMessage = ""
    }

    Component.onCompleted: {
        loadMatugenPalette();
        fadeAnim.start();
        if (typeof keyboard !== "undefined") keyboard.numLock = true;
    }

    SequentialAnimation {
        id: fadeAnim
        PauseAnimation { duration: 250 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "ui1"; from: 0; to: 1; duration: 750; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "ui2"; from: 0; to: 1; duration: 750; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeTranslate; property: "x"; to: 15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: -15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: -15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 50 }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
        onClicked: pwd.forceActiveFocus()
    }

    // Layout Row
    Row {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 96 * s
        opacity: root.ui1
        scale: 0.96 + (0.04 * root.ui1)
        transform: Translate { y: (1 - root.ui1) * 30 * s }

        // Left Section
        Column {
            spacing: 24 * s
            anchors.verticalCenter: parent.verticalCenter

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    let d = new Date();
                    hText.text = Qt.formatTime(d, "hh");
                    mText.text = Qt.formatTime(d, "mm");
                    dateChipText.text = Qt.formatDate(d, "dddd, MMM d").toUpperCase();
                }
            }

            // Clock
            Column {
                spacing: -24 * s

                Text {
                    id: hText
                    text: Qt.formatTime(new Date(), "hh")
                    font.family: root.sansFont
                    font.pixelSize: 140 * s
                    font.weight: Font.Bold
                    color: root.cOnSurface
                }

                Text {
                    id: mText
                    text: Qt.formatTime(new Date(), "mm")
                    font.family: root.sansFont
                    font.pixelSize: 140 * s
                    font.weight: Font.Bold
                    color: root.cOnSurfaceVariant
                }
            }

            // Date Pill
            Rectangle {
                width: dateChipText.implicitWidth + 32 * s
                height: 44 * s
                radius: 22 * s
                color: root.cSecondaryContainer

                Text {
                    id: dateChipText
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(), "dddd, MMM d").toUpperCase()
                    font.family: root.sansFont
                    font.pixelSize: 11 * s
                    font.bold: true
                    font.letterSpacing: 1 * s
                    color: root.cOnSurface
                }
            }
        }

        // Right Section
        Column {
            spacing: 24 * s
            anchors.verticalCenter: parent.verticalCenter

            // Settings Title
            Text {
                text: "QUICK SETTINGS"
                font.family: root.sansFont
                font.pixelSize: 11 * s
                font.bold: true
                font.letterSpacing: 1.5 * s
                color: root.cOutline
            }

            // Settings Grid
            Grid {
                columns: 2
                spacing: 16 * s

                // Power
                Rectangle {
                    id: powerTile
                    property bool isSelected: root.pendingAction === "powerOff"
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: powerMouse.pressed ? root.cSurfaceContainerLowest : (powerMouse.containsMouse || isSelected ? root.cSurfaceContainerHighest : root.cSurfaceContainer)
                    border.color: isSelected ? root.cPrimary : "transparent"
                    border.width: isSelected ? 2 * s : 0
                    scale: powerMouse.pressed ? 0.95 : (powerMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s

                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: powerTile.isSelected ? root.cPrimaryContainer : root.cSecondaryContainer
                            Behavior on color { ColorAnimation { duration: 150 } }
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: powerIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><path d='M18.36 6.64a9 9 0 1 1-12.73 0'></path><line x1='12' y1='2' x2='12' y2='12'></line></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: powerIcon
                                source: powerIcon
                                color: root.cOnSurface
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "POWER"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: (powerMouse.containsMouse || powerTile.isSelected) ? root.cOnSurface : root.cOnSurfaceVariant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: powerTile.isSelected ? "CONFIRM PWD" : "SHUT DOWN"
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: powerTile.isSelected ? root.cPrimary : (powerMouse.containsMouse ? root.cOnSurfaceVariant : root.cOutline)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.pendingAction = (root.pendingAction === "powerOff") ? "" : "powerOff";
                            root.errorMessage = "";
                            pwd.forceActiveFocus();
                        }
                    }
                }

                // Session
                Rectangle {
                    id: sessionTile
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: sessionMouse.pressed ? root.cSurfaceContainerLowest : (sessionMouse.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainer)
                    scale: sessionMouse.pressed ? 0.95 : (sessionMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s

                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: root.cSecondaryContainer
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: sessionIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='3'></circle><path d='M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z'></path></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: sessionIcon
                                source: sessionIcon
                                color: root.cOnSurface
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "SESSION"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: sessionMouse.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "OXWM").toUpperCase()
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: sessionMouse.containsMouse ? root.cOnSurfaceVariant : root.cOutline
                                Behavior on color { ColorAnimation { duration: 150 } }
                                elide: Text.ElideRight
                                width: 90 * s
                            }
                        }
                    }

                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sessionModel !== "undefined" && sessionModel && sessionModel.rowCount() > 0) {
                                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                            }
                        }
                    }
                }

                // Reboot
                Rectangle {
                    id: rebootTile
                    property bool isSelected: root.pendingAction === "reboot"
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: rebootMouse.pressed ? root.cSurfaceContainerLowest : (rebootMouse.containsMouse || isSelected ? root.cSurfaceContainerHighest : root.cSurfaceContainer)
                    border.color: isSelected ? root.cPrimary : "transparent"
                    border.width: isSelected ? 2 * s : 0
                    scale: rebootMouse.pressed ? 0.95 : (rebootMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s

                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: rebootTile.isSelected ? root.cPrimaryContainer : root.cSecondaryContainer
                            Behavior on color { ColorAnimation { duration: 150 } }
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: rebootIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><polyline points='23 4 23 10 17 10'></polyline><path d='M20.49 15a9 9 0 1 1-2.12-9.36L23 10'></path></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: rebootIcon
                                source: rebootIcon
                                color: root.cOnSurface
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "REBOOT"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: (rebootMouse.containsMouse || rebootTile.isSelected) ? root.cOnSurface : root.cOnSurfaceVariant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: rebootTile.isSelected ? "CONFIRM PWD" : "RESTART"
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: rebootTile.isSelected ? root.cPrimary : (rebootMouse.containsMouse ? root.cOnSurfaceVariant : root.cOutline)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.pendingAction = (root.pendingAction === "reboot") ? "" : "reboot";
                            root.errorMessage = "";
                            pwd.forceActiveFocus();
                        }
                    }
                }

                // Sleep
                Rectangle {
                    id: suspendTile
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: suspendMouse.pressed ? root.cSurfaceContainerLowest : (suspendMouse.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainer)
                    scale: suspendMouse.pressed ? 0.95 : (suspendMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s

                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: root.cSecondaryContainer
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: suspendIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><path d='M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z'></path></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: suspendIcon
                                source: suspendIcon
                                color: root.cOnSurface
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s

                            Text {
                                text: "SLEEP"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: suspendMouse.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "SUSPEND"
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: suspendMouse.containsMouse ? root.cOnSurfaceVariant : root.cOutline
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }

                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined" && sddm && sddm.suspend) sddm.suspend();
                    }
                }
            }

            // Login Card
            Rectangle {
                id: notificationCard
                width: 376 * s
                height: 180 * s
                radius: 32 * s
                color: root.cSurfaceContainerLow
                transform: Translate { id: shakeTranslate }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20 * s
                    spacing: 12 * s

                    // Header
                    Row {
                        width: parent.width
                        spacing: 8 * s

                        Item {
                            width: 12 * s
                            height: 12 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: lockIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='11' width='18' height='11' rx='2' ry='2'></rect><path d='M7 11V7a5 5 0 0 1 10 0v4'></path></svg>"
                                anchors.fill: parent
                                sourceSize.width: 24 * s
                                sourceSize.height: 24 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: lockIcon
                                source: lockIcon
                                color: root.cOutline
                            }
                        }
                        Text {
                            text: "SYSTEM UI"
                            font.family: root.sansFont
                            font.pixelSize: 10 * s
                            font.bold: true
                            font.letterSpacing: 1 * s
                            color: root.cOutline
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "•  now"
                            font.family: root.sansFont
                            font.pixelSize: 10 * s
                            color: root.cOutline
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Password Box
                    Rectangle {
                        width: parent.width
                        height: 52 * s
                        radius: 26 * s
                        color: root.cSurfaceContainerHigh
                        border.color: root.errorMessage !== "" ? root.cError : (pwd.activeFocus ? root.cPrimary : "transparent")
                        border.width: (pwd.activeFocus || root.errorMessage !== "") ? 2 * s : 0
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: pwd
                            anchors.fill: parent
                            anchors.leftMargin: 20 * s
                            anchors.rightMargin: 20 * s
                            font.family: root.sansFont
                            font.pixelSize: 18 * s
                            font.letterSpacing: 6 * s
                            color: root.cOnSurface
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true

                            cursorVisible: false
                            cursorDelegate: Item { width: 0; height: 0 }
                            selectionColor: root.cPrimaryContainer

                            property bool wasClicked: false
                            onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                            Keys.onEscapePressed: {
                                if (text.length > 0) {
                                    text = "";
                                } else if (root.pendingAction !== "") {
                                    root.pendingAction = "";
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.errorMessage !== ""
                                    ? root.errorMessage
                                    : (root.pendingAction === "powerOff"
                                        ? "PASSWORD TO SHUT DOWN"
                                        : (root.pendingAction === "reboot"
                                            ? "PASSWORD TO REBOOT"
                                            : "PASSWORD REQUIRED"))
                                font.family: root.sansFont
                                font.pixelSize: 11 * s
                                font.bold: true
                                font.letterSpacing: 1.5 * s
                                color: root.errorMessage !== "" ? root.cError : (root.pendingAction !== "" ? root.cPrimary : root.cOutline)
                                opacity: pwd.text === "" && (!pwd.activeFocus || (!pwd.wasClicked && pwd.text.length === 0)) ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Cursor
                            Rectangle {
                                id: customCursor
                                width: 2 * s
                                height: 18 * s
                                color: root.cPrimary
                                anchors.verticalCenter: parent.verticalCenter
                                x: pwd.cursorRectangle.x
                                visible: pwd.activeFocus && (pwd.text.length > 0 || pwd.wasClicked) && root.errorMessage === ""

                                SequentialAnimation {
                                    loops: Animation.Infinite
                                    running: customCursor.visible
                                    NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0; duration: 400; easing.type: Easing.InOutQuad }
                                    NumberAnimation { target: customCursor; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.InOutQuad }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: {
                                    pwd.wasClicked = true;
                                    pwd.forceActiveFocus();
                                }
                            }

                            onAccepted: {
                                if (typeof sddm !== "undefined" && sddm && pwd.text !== "") {
                                    let currentUser = root.getUserLogin();
                                    if (typeof sddm.loginWithAction === "function") {
                                        sddm.loginWithAction(currentUser, pwd.text, root.sessionIndex, root.pendingAction);
                                    } else {
                                        sddm.login(currentUser, pwd.text, root.sessionIndex);
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Row
                    Row {
                        width: parent.width
                        spacing: 12 * s

                        // User Switch
                        Rectangle {
                            width: userText.implicitWidth + 32 * s
                            height: 38 * s
                            radius: 19 * s
                            color: userMouse.pressed ? root.cSurfaceContainerLow : (userMouse.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainerHigh)
                            scale: userMouse.pressed ? 0.95 : (userMouse.containsMouse ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                            Text {
                                id: userText
                                anchors.centerIn: parent
                                text: root.getUserDisplayName().toUpperCase()
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                font.bold: true
                                font.letterSpacing: 1 * s
                                color: root.cOnSurfaceVariant
                            }

                            MouseArea {
                                id: userMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof userModel !== "undefined" && userModel && userModel.rowCount() > 0) {
                                        root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                                    }
                                }
                            }
                        }

                        // Unlock Pill
                        Item {
                            width: parent.width - (userText.implicitWidth + 32 * s) - 12 * s
                            height: 38 * s

                            Rectangle {
                                anchors.right: parent.right
                                width: parent.width
                                height: 38 * s
                                radius: 19 * s
                                color: loginMouse.pressed ? root.cSurfaceContainerLowest : (loginMouse.containsMouse ? root.cPrimaryContainer : root.cSecondaryContainer)
                                scale: loginMouse.pressed ? 0.95 : (loginMouse.containsMouse ? 1.02 : 1.0)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6 * s

                                    Text {
                                        text: root.pendingAction === "powerOff"
                                            ? "SHUT DOWN"
                                            : (root.pendingAction === "reboot" ? "REBOOT" : "UNLOCK")
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        font.bold: true
                                        font.letterSpacing: 1.5 * s
                                        color: root.cOnSurface
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "➔"
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        color: root.cOnSurface
                                        anchors.verticalCenter: parent.verticalCenter
                                        transform: Translate {
                                            x: loginMouse.containsMouse ? 3 * s : 0
                                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: loginMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (pwd.text === "") {
                                            pwd.forceActiveFocus();
                                        } else {
                                            pwd.accepted();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
