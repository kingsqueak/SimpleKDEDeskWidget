// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris
.pragma library

// WMO weather interpretation codes -> Breeze icon name and a short description.
function wmo(c) {
    if (c === 0) return ["weather-clear", "Clear"];
    if (c === 1) return ["weather-clear", "Mainly clear"];
    if (c === 2) return ["weather-few-clouds", "Partly cloudy"];
    if (c === 3) return ["weather-overcast", "Cloudy"];
    if (c === 45 || c === 48) return ["weather-fog", "Fog"];
    if (c >= 51 && c <= 55) return ["weather-showers-scattered", "Drizzle"];
    if ([56, 57, 66, 67].indexOf(c) >= 0) return ["weather-freezing-rain", "Freezing rain"];
    if ([61, 63, 80, 81].indexOf(c) >= 0) return ["weather-showers", "Rain"];
    if (c === 65 || c === 82) return ["weather-showers", "Heavy rain"];
    if ((c >= 71 && c <= 77) || c === 85 || c === 86) return ["weather-snow", "Snow"];
    if (c >= 95 && c <= 99) return ["weather-storm", "Thunderstorms"];
    return ["weather-overcast", "—"];
}

// Cold blue through green and yellow to hot red, by °C (same stops as the Mac widget).
function tempColor(c) {
    var stops = [[-10, "#5856d6"], [0, "#007aff"], [10, "#30b0c7"], [18, "#34c759"],
                 [25, "#ffcc00"], [32, "#ff9500"], [40, "#ff3b30"]];
    if (c <= stops[0][0]) return stops[0][1];
    for (var i = 1; i < stops.length; i++) {
        if (c <= stops[i][0]) {
            var a = stops[i - 1], b = stops[i];
            return (c - a[0]) / (b[0] - a[0]) < 0.5 ? a[1] : b[1];
        }
    }
    return stops[stops.length - 1][1];
}

function temp(c, imperial) {
    var v = imperial ? c * 9 / 5 + 32 : c;
    return Math.round(v) + "°";
}

function precip(mm, imperial) {
    if (imperial) {
        var inch = mm / 25.4;
        return inch < 0.01 ? "0\"" : inch.toFixed(2) + "\"";
    }
    return mm < 0.1 ? "0 mm" : (mm < 10 ? mm.toFixed(1) : mm.toFixed(0)) + " mm";
}

function wind(ms, imperial) {
    return imperial ? Math.round(ms * 2.23694) + " mph" : Math.round(ms * 3.6) + " km/h";
}

function distance(km, imperial) {
    return imperial ? Math.round(km / 1.609344) + " mi" : Math.round(km) + " km";
}

// Alerts: severity order, colour and icon.
function alertRank(sev) {
    var r = { "Extreme": 0, "Severe": 1, "Moderate": 2, "Minor": 3 }[sev];
    return r === undefined ? 4 : r;
}

function alertColor(sev) {
    if (sev === "Extreme" || sev === "Severe") return "#ff3b30";
    if (sev === "Moderate") return "#ff9500";
    return "#c9a300";
}

function alertIcon(event) {
    var e = event.toLowerCase();
    if (e.indexOf("thunder") >= 0) return "weather-storm";
    if (e.indexOf("tornado") >= 0) return "weather-storm";
    if (e.indexOf("flood") >= 0) return "weather-showers";
    if (/winter|snow|blizzard|ice/.test(e)) return "weather-snow";
    if (e.indexOf("wind") >= 0) return "weather-clouds";
    if (e.indexOf("heat") >= 0) return "weather-clear";
    if (e.indexOf("fog") >= 0) return "weather-fog";
    return "dialog-warning";
}

// Blitzortung packs each message with a small LZW-style dictionary coder:
// code units below 256 are literal, higher ones refer back to earlier phrases.
function lzwDecode(s) {
    if (!s.length) return "";
    var dict = {};
    var prev = s.charAt(0);
    var out = [prev];
    var code = 256;
    for (var i = 1; i < s.length; i++) {
        var a = s.charCodeAt(i);
        var w = a < 256 ? s.charAt(i) : (dict[a] !== undefined ? dict[a] : prev + prev.charAt(0));
        out.push(w);
        dict[code++] = prev + w.charAt(0);
        prev = w;
    }
    return out.join("");
}

function rad(d) { return d * Math.PI / 180; }

function distanceKm(lat1, lon1, lat2, lon2) {
    var dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
    var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function bearing(lat1, lon1, lat2, lon2) {
    var y = Math.sin(rad(lon2 - lon1)) * Math.cos(rad(lat2));
    var x = Math.cos(rad(lat1)) * Math.sin(rad(lat2)) -
            Math.sin(rad(lat1)) * Math.cos(rad(lat2)) * Math.cos(rad(lon2 - lon1));
    return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
}

function compass(deg) {
    var p = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    return p[Math.round(deg / 45) % 8];
}

// One Blitzortung message -> {time(ms), km, bearing} if inside the radius, else null.
function parseStrike(msg, lat, lon, radiusKm) {
    var o;
    try { o = JSON.parse(lzwDecode(msg)); } catch (e) { return null; }
    if (typeof o.lat !== "number" || typeof o.lon !== "number" || typeof o.time !== "number") return null;
    if (Math.abs(o.lat - lat) > radiusKm / 100 + 0.5) return null;   // cheap box test first
    var km = distanceKm(lat, lon, o.lat, o.lon);
    if (km > radiusKm) return null;
    return { time: o.time / 1e6, km: km, bearing: bearing(lat, lon, o.lat, o.lon) };
}

// Single-quote a string for /bin/sh.
function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
}

// Font.Weight values for the seven weight choices (Light .. Black).
var weights = [300, 400, 500, 600, 700, 800, 900];
var weightNames = ["Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"];
function weight(i) { return weights[Math.max(0, Math.min(6, i))]; }
