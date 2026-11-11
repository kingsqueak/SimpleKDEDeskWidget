// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "../code/logic.js" as Logic

// The whole widget. Resize it in Plasma's edit mode: everything scales with the width.
Item {
    id: card

    property var model
    readonly property var cfg: Plasmoid.configuration

    // Base design is 380 px wide plus a margin for the drop shadow.
    readonly property real baseWidth: 380
    readonly property real baseMargin: 24
    readonly property real sc: Math.max(0.3, width / (baseWidth + 2 * baseMargin))

    readonly property string family: cfg.fontFamily || Kirigami.Theme.defaultFont.family
    readonly property int clockWeight: cfg.clockWeight
    readonly property int textWeight: cfg.textWeight
    readonly property color textColor: cfg.textColor
    readonly property real halo: cfg.textHalo
    // Halo colour is the opposite of the text, so light text gets a dark edge and vice versa.
    readonly property color haloColor: {
        var c = textColor
        var lum = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
        var v = lum > 0.5 ? 0 : 1
        return Qt.rgba(v, v, v, Math.min(1, halo * 1.6))
    }
    readonly property bool imperial: cfg.imperial
    readonly property date now: model.now

    function weightOf(i) { return Logic.weight(i) }
    function fmt(d, pattern) { return Qt.formatDateTime(d, pattern) }
    function pad2(n) { return n < 10 ? "0" + n : "" + n }

    Layout.preferredWidth: 360
    Layout.preferredHeight: cardBox.height + 2 * baseMargin * sc
    Layout.minimumWidth: 160
    Layout.minimumHeight: cardBox.height + 2 * baseMargin * sc

    Item {
        id: shadowed
        anchors.fill: parent
        opacity: card.cfg.displayOpacity
        layer.enabled: card.cfg.shadowStrength > 0.01
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            blurMax: 48
            shadowBlur: Math.min(1, card.cfg.shadowStrength)
            shadowOpacity: Math.min(1, 0.9 * card.cfg.shadowStrength + 0.25)
            shadowVerticalOffset: 7 * card.cfg.shadowStrength * card.sc
            autoPaddingEnabled: true
        }

        Rectangle {
            id: cardBox
            x: card.baseMargin * card.sc
            y: card.baseMargin * card.sc
            width: card.baseWidth * card.sc
            height: content.implicitHeight + 2 * 22 * card.sc
            radius: 24 * card.sc
            color: Qt.rgba(card.cfg.backgroundColor.r, card.cfg.backgroundColor.g,
                           card.cfg.backgroundColor.b, card.cfg.backgroundOpacity)
            border.width: card.cfg.backgroundOpacity > 0.02 ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.12 * Math.min(1, card.cfg.backgroundOpacity * 2))

            ColumnLayout {
                id: content
                x: 22 * card.sc
                y: 22 * card.sc
                width: parent.width - 2 * x
                spacing: 16 * card.sc

                ClockSection { Layout.fillWidth: true }
                Divider {}
                WeatherSection { Layout.fillWidth: true }
                Divider {}
                EventsSection { Layout.fillWidth: true }
            }
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: Math.max(1, card.sc)
        color: card.textColor
        opacity: 0.25
    }

    // Small monochrome icon tinted with the text colour.
    component Glyph: Kirigami.Icon {
        property real size: 12
        implicitWidth: size * card.sc
        implicitHeight: size * card.sc
        isMask: true
        color: card.textColor
    }

    // ---------------- Clock ----------------

    component ClockSection: ColumnLayout {
        spacing: 2 * card.sc
        RowLayout {
            spacing: 3 * card.sc
            T {
                size: 78; weightIndex: card.clockWeight
                text: card.cfg.use24Hour ? card.fmt(card.now, "HH:mm")
                    : ((card.now.getHours() % 12) || 12) + ":" + card.pad2(card.now.getMinutes())
                font.letterSpacing: -1.5 * card.sc
                font.features: { "tnum": 1 }
                Layout.alignment: Qt.AlignBaseline
            }
            T {
                visible: card.cfg.showSeconds
                size: 30; weightIndex: card.clockWeight; opacity: 0.65
                text: card.fmt(card.now, "ss")
                font.features: { "tnum": 1 }
                Layout.alignment: Qt.AlignBaseline
            }
            T {
                visible: !card.cfg.use24Hour
                size: 20; opacity: 0.65
                text: card.now.getHours() < 12 ? "AM" : "PM"
                Layout.leftMargin: 2 * card.sc
                Layout.alignment: Qt.AlignBaseline
            }
            Item { Layout.fillWidth: true }
        }
        RowLayout {
            visible: card.cfg.showDate || card.cfg.showZulu
            opacity: 0.85
            T {
                visible: card.cfg.showDate
                size: 17
                text: card.fmt(card.now, "dddd, MMMM d")
                Layout.fillWidth: true
            }
            Item { Layout.fillWidth: !card.cfg.showDate }
            T {
                visible: card.cfg.showZulu
                size: 17
                text: card.pad2(card.now.getUTCHours()) + ":" + card.pad2(card.now.getUTCMinutes()) + "Z"
                font.features: { "tnum": 1 }
            }
        }
    }

    // ---------------- Weather ----------------

    component WeatherSection: ColumnLayout {
        spacing: 10 * card.sc

        RowLayout {
            spacing: 5 * card.sc
            opacity: 0.85
            Glyph { source: "mark-location"; size: 12 }
            T { size: 12; text: card.cfg.placeName || "Weather"; Layout.fillWidth: true }
            T { size: 12; text: "Open-Meteo"; opacity: 0.6 }
        }

        Repeater {
            model: card.cfg.showAlerts ? card.model.alerts.slice(0, 3) : []
            delegate: AlertBanner { required property var modelData; alert: modelData; Layout.fillWidth: true }
        }

        T {
            visible: card.model.days.length === 0
            size: 13; opacity: 0.7
            wrapMode: Text.WordWrap; maximumLineCount: 3
            Layout.fillWidth: true
            text: card.model.weatherMessage || (card.model.weatherLoading ? "Loading forecast…" : "No forecast")
        }

        RowLayout {
            visible: card.model.days.length > 0
            spacing: 0
            Layout.fillWidth: true
            Repeater {
                model: card.model.days.slice(0, 3)
                delegate: DayColumn {
                    required property var modelData
                    required property int index
                    day: modelData; dayIndex: index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    Layout.alignment: Qt.AlignTop
                }
            }
        }

        T {
            visible: card.model.days.length > 0 && card.model.weatherMessage !== ""
            size: 11; color: "#ffcc00"
            text: "⚠ " + card.model.weatherMessage
            Layout.alignment: Qt.AlignHCenter
        }

        LightningLine {
            visible: card.cfg.showLightning && card.model.lightning !== null
            Layout.fillWidth: true
        }
    }

    component DayColumn: ColumnLayout {
        property var day
        property int dayIndex
        readonly property real rangeLow: Math.min.apply(null, card.model.days.map(function (d) { return d.lowC }))
        readonly property real rangeHigh: Math.max.apply(null, card.model.days.map(function (d) { return d.highC }))
        spacing: 5 * card.sc

        T {
            size: 14; weightIndex: 4
            text: dayIndex === 0 ? "Today" : Qt.formatDate(day.date, "ddd")
            Layout.alignment: Qt.AlignHCenter
        }
        Kirigami.Icon {
            source: day.icon
            implicitWidth: 44 * card.sc
            implicitHeight: 44 * card.sc
            Layout.alignment: Qt.AlignHCenter
        }
        RowLayout {
            spacing: 4 * card.sc
            Layout.alignment: Qt.AlignHCenter
            T { size: 20; weightIndex: 3; text: Logic.temp(day.highC, card.imperial); Layout.alignment: Qt.AlignBaseline }
            T { size: 15; opacity: 0.6; text: Logic.temp(day.lowC, card.imperial); Layout.alignment: Qt.AlignBaseline }
        }
        // iOS-weather style bar: where the day's low..high sits inside the three-day range.
        Rectangle {
            id: track
            implicitWidth: 70 * card.sc
            implicitHeight: 5 * card.sc
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.18)
            Layout.alignment: Qt.AlignHCenter
            readonly property real span: Math.max(rangeHigh - rangeLow, 1)
            Rectangle {
                readonly property real x0: (day.lowC - rangeLow) / track.span * track.width
                readonly property real x1: (day.highC - rangeLow) / track.span * track.width
                x: x0
                width: Math.max(x1 - x0, track.height)
                height: track.height
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Logic.tempColor(day.lowC) }
                    GradientStop { position: 1; color: Logic.tempColor(day.highC) }
                }
            }
        }
        ColumnLayout {
            spacing: 2 * card.sc
            opacity: 0.75
            Layout.alignment: Qt.AlignHCenter
            RowLayout {
                spacing: 3 * card.sc
                Layout.alignment: Qt.AlignHCenter
                Glyph { source: "raindrop"; size: 10 }
                T {
                    size: 11
                    text: (day.precipChance !== null && day.precipChance !== undefined
                           ? day.precipChance + "%  " : "") + Logic.precip(day.precipMM, card.imperial)
                }
            }
            T {
                size: 11
                text: "≋ " + Logic.wind(day.gustMS !== null && day.gustMS !== undefined ? day.gustMS : day.windMS, card.imperial)
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    component AlertBanner: Rectangle {
        property var alert
        implicitHeight: row.implicitHeight + 12 * card.sc
        radius: 8 * card.sc
        color: Qt.alpha(Logic.alertColor(alert.severity), 0.85)
        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: 10 * card.sc
            anchors.rightMargin: 10 * card.sc
            spacing: 7 * card.sc
            Kirigami.Icon {
                source: Logic.alertIcon(alert.event)
                implicitWidth: 16 * card.sc; implicitHeight: 16 * card.sc
                isMask: true; color: "white"
            }
            T {
                size: 13; weightIndex: 4; color: "white"; style: Text.Normal
                text: alert.event
                Layout.fillWidth: true
            }
            T {
                visible: alert.ends !== null
                size: 11; color: "white"; style: Text.Normal; opacity: 0.9
                text: alert.ends === null ? "" : "until " + (alert.ends.toDateString() === card.now.toDateString()
                      ? Qt.formatTime(alert.ends, card.cfg.use24Hour ? "HH:mm" : "h:mm AP")
                      : Qt.formatDateTime(alert.ends, card.cfg.use24Hour ? "MMM d HH:mm" : "MMM d h:mm AP"))
            }
        }
        // Full NWS headline on hover.
        HoverHandler { id: hover }
        QQC2.ToolTip.visible: hover.hovered
        QQC2.ToolTip.text: alert.headline
        QQC2.ToolTip.delay: 500
    }

    component LightningLine: Rectangle {
        readonly property var l: card.model.lightning
        readonly property bool close: l !== null && l.nearestKm <= 16   // ~10 miles: the usual "go indoors" distance
        readonly property int mins: l === null ? 0 : Math.max(0, Math.floor((card.now.getTime() - l.latest) / 60000))
        implicitHeight: lrow.implicitHeight + 12 * card.sc
        radius: 8 * card.sc
        color: Qt.alpha(close ? "#ff3b30" : "#ffcc00", 0.18)
        RowLayout {
            id: lrow
            anchors.fill: parent
            anchors.leftMargin: 10 * card.sc
            anchors.rightMargin: 10 * card.sc
            spacing: 6 * card.sc
            T { size: 14; weightIndex: 4; text: "⚡︎"; color: close ? "#ff3b30" : "#ffcc00" }
            T {
                size: 13; weightIndex: 4
                text: l === null ? "" : "Lightning " + Logic.distance(l.nearestKm, card.imperial) + " " + Logic.compass(l.nearestBearing)
                Layout.fillWidth: true
            }
            T {
                size: 11; opacity: 0.8
                text: l === null ? "" : l.count + " in 30 min · " + (mins === 0 ? "now" : mins + " min ago")
            }
        }
    }

    // ---------------- Calendar ----------------

    component EventsSection: ColumnLayout {
        readonly property var visibleEvents: card.model.events.filter(function (e) {
            return !(card.cfg.hideFinishedEvents && !e.allDay && e.endMs <= card.now.getTime())
        })
        spacing: 7 * card.sc

        RowLayout {
            spacing: 5 * card.sc
            opacity: 0.85
            Glyph { source: "view-calendar-day"; size: 12 }
            T { size: 12; text: "Today"; Layout.fillWidth: true }
            T {
                size: 12; opacity: 0.6
                text: visibleEvents.length ? visibleEvents.length + " event" + (visibleEvents.length === 1 ? "" : "s") : ""
            }
        }

        Repeater {
            model: visibleEvents.slice(0, card.cfg.maxEvents)
            delegate: EventRow { required property var modelData; ev: modelData; Layout.fillWidth: true }
        }

        T {
            readonly property int more: visibleEvents.length - card.cfg.maxEvents
            visible: more > 0
            size: 13; opacity: 0.65
            text: "+ " + more + " more"
        }

        T {
            visible: visibleEvents.length === 0
            size: 13; opacity: 0.65
            wrapMode: Text.WordWrap; maximumLineCount: 3
            Layout.fillWidth: true
            text: card.model.feedLines.length === 0 ? "Add ICS calendar feeds in Configure → Calendar"
                : !card.model.calendarLoaded ? "Loading calendar…"
                : "Nothing on the calendar today"
        }

        Repeater {
            model: card.model.calendarErrors.slice(0, 2)
            delegate: T {
                required property var modelData
                size: 11; color: "#ffcc00"
                wrapMode: Text.WordWrap; maximumLineCount: 2
                Layout.fillWidth: true
                text: "⚠ " + modelData
            }
        }
    }

    component EventRow: RowLayout {
        property var ev
        readonly property bool finished: !ev.allDay && ev.endMs <= card.now.getTime()
        readonly property bool current: !ev.allDay && ev.startMs <= card.now.getTime() && ev.endMs > card.now.getTime()
        spacing: 9 * card.sc
        opacity: finished ? 0.4 : 1

        Rectangle {
            implicitWidth: 4 * card.sc; implicitHeight: 18 * card.sc
            radius: width / 2
            color: ev.color
        }
        T {
            size: 13; opacity: 0.75
            text: ev.allDay ? "All day"
                : Qt.formatTime(new Date(ev.startMs), card.cfg.use24Hour ? "HH:mm" : "h:mm ap")
            font.features: { "tnum": 1 }
            Layout.preferredWidth: 64 * card.sc
        }
        T {
            size: 14; weightIndex: current ? 4 : card.textWeight
            text: ev.title
            Layout.fillWidth: true
        }
        Rectangle {
            visible: current
            implicitWidth: nowText.implicitWidth + 10 * card.sc
            implicitHeight: nowText.implicitHeight + 4 * card.sc
            radius: height / 2
            color: Qt.alpha(ev.color, 0.85)
            Text {
                id: nowText
                anchors.centerIn: parent
                text: "NOW"
                color: "white"
                font.pixelSize: 9 * card.sc
                font.weight: Font.Black
                font.family: card.family
            }
        }
    }
}
