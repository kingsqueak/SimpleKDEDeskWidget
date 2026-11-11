// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property double cfg_latitude
    property double cfg_longitude
    property alias cfg_placeName: placeName.text
    property alias cfg_imperial: imperial.checked
    property alias cfg_showAlerts: showAlerts.checked
    property alias cfg_showLightning: showLightning.checked
    property double cfg_lightningRadiusKm

    property var results: []
    property string searchMessage: ""

    // Place search with Open-Meteo's free geocoder.
    function search() {
        var q = query.text.trim()
        if (!q) return
        searchMessage = i18n("Searching…")
        var x = new XMLHttpRequest()
        x.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=8&language=en&name=" + encodeURIComponent(q))
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            var obj = null
            try { obj = JSON.parse(x.responseText) } catch (e) {}
            results = (obj && obj.results) || []
            searchMessage = results.length ? "" : i18n("No places found")
        }
        x.send()
    }

    function label(r) {
        var parts = [r.name]
        if (r.admin1) parts.push(r.country_code === "US" ? r.admin1 : r.admin1)
        if (r.country_code && r.country_code !== "US") parts.push(r.country_code)
        return parts.join(", ")
    }

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Find place:")
            QQC2.TextField {
                id: query
                placeholderText: i18n("Town or city")
                onAccepted: search()
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            QQC2.Button { text: i18n("Search"); icon.name: "search"; onClicked: search() }
        }
        QQC2.Label { visible: searchMessage !== ""; text: searchMessage; opacity: 0.7 }
        ColumnLayout {
            visible: results.length > 0
            Repeater {
                model: results
                delegate: QQC2.Button {
                    required property var modelData
                    flat: true
                    text: modelData.name + (modelData.admin1 ? ", " + modelData.admin1 : "")
                          + (modelData.country ? " — " + modelData.country : "")
                          + "  (" + modelData.latitude.toFixed(2) + ", " + modelData.longitude.toFixed(2) + ")"
                    onClicked: {
                        cfg_latitude = modelData.latitude
                        cfg_longitude = modelData.longitude
                        placeName.text = label(modelData)
                        results = []
                    }
                }
            }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.TextField { id: placeName; Kirigami.FormData.label: i18n("Place name:") }
        QQC2.TextField {
            Kirigami.FormData.label: i18n("Latitude:")
            text: cfg_latitude.toFixed(4)
            validator: DoubleValidator { bottom: -90; top: 90 }
            onEditingFinished: cfg_latitude = Number(text)
        }
        QQC2.TextField {
            Kirigami.FormData.label: i18n("Longitude:")
            text: cfg_longitude.toFixed(4)
            validator: DoubleValidator { bottom: -180; top: 180 }
            onEditingFinished: cfg_longitude = Number(text)
        }
        QQC2.CheckBox { id: imperial; Kirigami.FormData.label: i18n("Units:"); text: i18n("°F, inches, mph, miles") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: showAlerts; Kirigami.FormData.label: i18n("Alerts:"); text: i18n("Show NWS weather alerts (US only)") }
        QQC2.CheckBox { id: showLightning; Kirigami.FormData.label: i18n("Lightning:"); text: i18n("Show nearby lightning (Blitzortung.org)") }
        RowLayout {
            Kirigami.FormData.label: i18n("Radius:")
            enabled: showLightning.checked
            QQC2.SpinBox {
                id: radius
                from: 5; to: 300
                value: Math.round(imperial.checked ? cfg_lightningRadiusKm / 1.609344 : cfg_lightningRadiusKm)
                onValueModified: cfg_lightningRadiusKm = imperial.checked ? value * 1.609344 : value
            }
            QQC2.Label { text: imperial.checked ? i18n("miles") : i18n("km") }
        }
        QQC2.Label {
            text: i18n("Lightning data comes from the volunteer Blitzortung.org network: free for personal use, no guarantees, not for safety decisions. Your location is never sent; strikes are filtered on this computer.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }
    }
}
