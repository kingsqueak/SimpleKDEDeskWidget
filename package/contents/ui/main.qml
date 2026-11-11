// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

import QtQuick
import QtWebSockets
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "../code/logic.js" as Logic

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property bool hasLocation: !(cfg.latitude === 0 && cfg.longitude === 0)

    // Clock
    property date now: new Date()

    // Weather (data kept in °C, mm and m/s)
    property var days: []
    property string weatherMessage: ""
    property bool weatherLoading: false

    // NWS alerts
    property var alerts: []

    // Lightning
    property var strikes: []
    property var lightning: null      // {count, nearestKm, nearestBearing, latest(ms)}
    property string lightningStatus: "Off"

    // Calendar
    property var events: []
    property var calendarErrors: []
    property bool calendarLoaded: false

    Plasmoid.backgroundHints: cfg.plasmaBackground ? PlasmaCore.Types.StandardBackground
                                                   : PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    fullRepresentation: Card { model: root }
    toolTipMainText: ""
    toolTipSubText: ""

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var prev = root.now
            root.now = new Date()
            if (prev.getDate() !== root.now.getDate()) {   // midnight rollover
                root.refreshWeather()
                root.refreshCalendar()
            }
        }
    }

    // ---- Weather: Open-Meteo, every 30 min ----

    function refreshWeather() {
        if (!hasLocation) { days = []; weatherMessage = "Set a location in Configure → Weather"; return }
        weatherLoading = true
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + cfg.latitude.toFixed(3)
            + "&longitude=" + cfg.longitude.toFixed(3)
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,"
            + "precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max"
            + "&wind_speed_unit=ms&timezone=auto&forecast_days=3"
        var x = new XMLHttpRequest()
        x.open("GET", url)
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            weatherLoading = false
            var obj = null
            try { obj = JSON.parse(x.responseText) } catch (e) {}
            var err = ""
            if (x.status !== 200) err = "Open-Meteo: " + ((obj && obj.reason) || ("HTTP " + x.status))
            else if (!obj || !obj.daily || !obj.daily.time) err = "Open-Meteo: unexpected reply"
            if (err) {
                weatherMessage = days.length ? "Couldn't refresh: " + err : err
                return
            }
            var d = obj.daily, list = []
            for (var i = 0; i < d.time.length; i++) {
                if (d.temperature_2m_max[i] === null || d.temperature_2m_min[i] === null) continue
                var p = d.time[i].split("-")
                var w = Logic.wmo(d.weather_code[i] || 0)
                list.push({
                    date: new Date(+p[0], +p[1] - 1, +p[2]),
                    highC: d.temperature_2m_max[i], lowC: d.temperature_2m_min[i],
                    precipMM: d.precipitation_sum[i] || 0,
                    precipChance: d.precipitation_probability_max[i],
                    windMS: d.wind_speed_10m_max[i] || 0,
                    gustMS: d.wind_gusts_10m_max[i],
                    icon: w[0], summary: w[1]
                })
            }
            days = list
            weatherMessage = list.length ? "" : "No forecast data returned"
        }
        x.send()
    }

    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: root.refreshWeather() }

    // ---- Alerts: NWS (US only), every 5 min ----

    function refreshAlerts() {
        if (!cfg.showAlerts || !hasLocation) { alerts = []; return }
        var x = new XMLHttpRequest()
        x.open("GET", "https://api.weather.gov/alerts/active?point="
               + cfg.latitude.toFixed(3) + "," + cfg.longitude.toFixed(3))
        x.setRequestHeader("Accept", "application/geo+json")
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status !== 200) { alerts = []; return }   // 404 = outside NWS coverage
            var obj = null
            try { obj = JSON.parse(x.responseText) } catch (e) { return }
            var list = []
            var feats = obj.features || []
            for (var i = 0; i < feats.length; i++) {
                var p = feats[i].properties
                if (!p || !p.event || (p.status && p.status !== "Actual")) continue
                var end = p.ends || p.expires
                list.push({ event: p.event, severity: p.severity || "Unknown",
                            headline: p.headline || p.event,
                            ends: end ? new Date(end) : null })
            }
            list.sort(function (a, b) {
                var r = Logic.alertRank(a.severity) - Logic.alertRank(b.severity)
                if (r) return r
                return (a.ends ? a.ends.getTime() : 8.64e15) - (b.ends ? b.ends.getTime() : 8.64e15)
            })
            var seen = {}, uniq = []
            for (var j = 0; j < list.length; j++) {     // one line per kind of alert
                if (seen[list[j].event]) continue
                seen[list[j].event] = true
                uniq.push(list[j])
            }
            alerts = uniq
        }
        x.send()
    }

    Timer { interval: 5 * 60 * 1000; running: true; repeat: true; onTriggered: root.refreshAlerts() }

    // ---- Lightning: Blitzortung websocket, filtered locally ----

    readonly property var hosts: ["ws1.blitzortung.org", "ws7.blitzortung.org", "ws8.blitzortung.org"]
    property int hostIndex: 0
    property double lastMessage: 0
    property int retryDelay: 5
    readonly property bool lightningWanted: cfg.showLightning && hasLocation

    WebSocket {
        id: ws
        active: false
        onStatusChanged: function () {
            if (ws.status === WebSocket.Open) {
                sendTextMessage('{"a":111}')
                root.lightningStatus = "Live"
                root.lastMessage = Date.now()
            } else if (ws.status === WebSocket.Error || ws.status === WebSocket.Closed) {
                if (root.lightningWanted) root.reconnect()
            }
        }
        onTextMessageReceived: function (message) {
            root.lastMessage = Date.now()
            root.retryDelay = 5
            var s = Logic.parseStrike(message, root.cfg.latitude, root.cfg.longitude, root.cfg.lightningRadiusKm)
            if (s) {
                root.strikes.push(s)
                root.recomputeLightning()
            }
        }
    }

    Timer { id: retryTimer; repeat: false; onTriggered: root.connectLightning() }

    function connectLightning() {
        if (!lightningWanted) return
        ws.active = false
        ws.url = "wss://" + hosts[hostIndex % hosts.length] + "/"
        lightningStatus = "Connecting to " + hosts[hostIndex % hosts.length]
        lastMessage = Date.now()
        ws.active = true
    }

    function reconnect() {
        ws.active = false
        if (retryTimer.running) return
        hostIndex++
        retryTimer.interval = retryDelay * 1000
        lightningStatus = "Reconnecting in " + retryDelay + " s"
        retryDelay = Math.min(retryDelay * 2, 300)
        retryTimer.start()
    }

    function applyLightning() {
        strikes = []
        recomputeLightning()
        retryTimer.stop()
        if (lightningWanted) connectLightning()
        else { ws.active = false; lightningStatus = "Off" }
    }

    function recomputeLightning() {
        var cutoff = Date.now() - 30 * 60 * 1000
        strikes = strikes.filter(function (s) { return s.time >= cutoff })
        if (!strikes.length) { lightning = null; return }
        var nearest = strikes[0], latest = 0
        for (var i = 0; i < strikes.length; i++) {
            if (strikes[i].km < nearest.km) nearest = strikes[i]
            latest = Math.max(latest, strikes[i].time)
        }
        lightning = { count: strikes.length, nearestKm: nearest.km,
                      nearestBearing: nearest.bearing, latest: latest }
    }

    // Age out old strikes; reconnect if the stream has gone quiet for 90 s.
    Timer {
        interval: 20000; running: true; repeat: true
        onTriggered: {
            root.recomputeLightning()
            if (root.lightningWanted && ws.status === WebSocket.Open && Date.now() - root.lastMessage > 90000)
                root.reconnect()
        }
    }

    // ---- Calendar: ICS feeds through the Python helper, every 15 min ----

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source)
            var obj = null
            try { obj = JSON.parse(data["stdout"]) } catch (e) {}
            if (!obj) {
                root.calendarErrors = ["Calendar helper failed: " + (data["stderr"] || "no output").trim().split("\n").pop()]
            } else {
                root.events = obj.events
                root.calendarErrors = obj.errors
            }
            root.calendarLoaded = true
        }
    }

    readonly property var feedLines: cfg.icsFeeds.split("\n").map(function (l) { return l.trim() })
                                         .filter(function (l) { return l.length && l.charAt(0) !== ";" })

    function refreshCalendar() {
        if (!feedLines.length) { events = []; calendarErrors = []; calendarLoaded = true; return }
        var helper = decodeURIComponent(Qt.resolvedUrl("../code/sdkw_calendar.py").toString().replace(/^file:\/\//, ""))
        var cmd = "python3 " + Logic.shellQuote(helper)
        for (var i = 0; i < feedLines.length; i++) cmd += " " + Logic.shellQuote(feedLines[i])
        // A unique suffix so a repeated identical command still runs.
        exec.connectSource(cmd + " #" + Date.now())
    }

    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.refreshCalendar() }

    // ---- React to settings ----

    Connections {
        target: root.cfg
        function onLatitudeChanged() { locTimer.restart() }
        function onLongitudeChanged() { locTimer.restart() }
        function onShowAlertsChanged() { root.refreshAlerts() }
        function onShowLightningChanged() { root.applyLightning() }
        function onLightningRadiusKmChanged() { root.applyLightning() }
        function onIcsFeedsChanged() { root.refreshCalendar() }
    }
    Timer {
        id: locTimer; interval: 500
        onTriggered: { root.refreshWeather(); root.refreshAlerts(); root.applyLightning() }
    }

    Component.onCompleted: {
        refreshWeather()
        refreshAlerts()
        applyLightning()
        refreshCalendar()
    }
}
