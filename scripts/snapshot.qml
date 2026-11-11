// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

// Renders the widget with made-up sample data on a background image, for the README
// screenshot. Run by scripts/make-screenshot.py; nothing real (calendar, location,
// network) is used.
//
//   TZ=America/Denver qml6 scripts/snapshot.qml -- background.png out.png

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../package/contents/ui"

Window {
    id: win
    width: 1500
    height: 900
    visible: true
    color: "black"

    readonly property var args: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1)

    // Same sample data as the Mac widget's --snapshot.
    readonly property date now: new Date(2026, 5, 17, 15, 10, 42)
    function at(h, m) { return new Date(2026, 5, 17, h, m, 0) }
    function c(f) { return (f - 32) * 5 / 9 }
    readonly property real mph: 0.44704

    readonly property var sample: ({
        now: now,
        weatherMessage: "",
        weatherLoading: false,
        days: [
            { date: new Date(2026, 5, 17), highC: c(84), lowC: c(58), precipMM: 6.4, precipChance: 70,
              windMS: 9 * mph, gustMS: 34 * mph, icon: "weather-storm", summary: "Thunderstorms" },
            { date: new Date(2026, 5, 18), highC: c(79), lowC: c(55), precipMM: 0.5, precipChance: 20,
              windMS: 7 * mph, gustMS: 18 * mph, icon: "weather-few-clouds", summary: "Partly cloudy" },
            { date: new Date(2026, 5, 19), highC: c(86), lowC: c(57), precipMM: 0, precipChance: 5,
              windMS: 6 * mph, gustMS: 14 * mph, icon: "weather-clear", summary: "Sunny" }
        ],
        alerts: [
            { event: "Severe Thunderstorm Watch", severity: "Moderate",
              headline: "Severe Thunderstorm Watch until 9:00 PM", ends: at(21, 0) }
        ],
        lightning: { count: 23, nearestKm: 14 * 1.609344, nearestBearing: 280, latest: now.getTime() - 120000 },
        feedLines: ["sample"],
        calendarLoaded: true,
        calendarErrors: [],
        events: [
            ev("Library books due", new Date(2026, 5, 17), new Date(2026, 5, 18), true, "#34c759"),
            ev("Team stand-up", at(9, 30), at(9, 45), false, "#3478f6"),
            ev("Lunch with Sam", at(12, 30), at(13, 30), false, "#ff9500"),
            ev("Dentist", at(15, 0), at(16, 0), false, "#af52de"),
            ev("Radio club net on 2 m", at(19, 0), at(20, 0), false, "#30b0c7")
        ]
    })

    function ev(title, s, e, allDay, color) {
        return { title: title, startMs: s.getTime(), endMs: e.getTime(), allDay: allDay, color: color }
    }

    readonly property var settings: ({
        fontFamily: "", clockWeight: 4, textWeight: 2,
        textColor: "#ffffff", backgroundColor: "#0d1220",
        backgroundOpacity: 0.45, displayOpacity: 1, shadowStrength: 0.8, textHalo: 0.12,
        plasmaBackground: false,
        use24Hour: false, showSeconds: true, showDate: true, showZulu: true,
        placeName: "Boulder, CO", imperial: true, showAlerts: true, showLightning: true,
        hideFinishedEvents: false, maxEvents: 8
    })

    Image {
        anchors.fill: parent
        source: "file://" + win.args[0]
        fillMode: Image.PreserveAspectCrop
    }

    Card {
        id: card
        model: win.sample
        cfg: win.settings
        width: 428
        height: Layout.preferredHeight
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 6
        anchors.rightMargin: 60
    }

    // Wait for icons and the shadow effect to settle, then save and quit.
    Timer {
        interval: 1500
        running: true
        onTriggered: win.contentItem.grabToImage(function (r) {
            r.saveToFile(win.args[1])
            Qt.quit()
        })
    }
}
