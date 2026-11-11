// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Clock")
        icon: "preferences-system-time"
        source: "ConfigClock.qml"
    }
    ConfigCategory {
        name: i18n("Weather")
        icon: "weather-few-clouds"
        source: "ConfigWeather.qml"
    }
    ConfigCategory {
        name: i18n("Calendar")
        icon: "view-calendar"
        source: "ConfigCalendar.qml"
    }
}
