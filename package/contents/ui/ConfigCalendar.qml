// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_icsFeeds: feeds.text
    property alias cfg_hideFinishedEvents: hideFinished.checked
    property alias cfg_maxEvents: maxEvents.value

    Kirigami.FormLayout {
        QQC2.Label {
            Kirigami.FormData.label: i18n("ICS feeds:")
            text: i18n("One calendar per line: its iCal URL, optionally followed by a colour (#rrggbb). Lines starting with ; are ignored.\nGoogle: Calendar settings → \"Secret address in iCal format\". iCloud: share the calendar publicly and copy the webcal:// link.")
            wrapMode: Text.WordWrap
            opacity: 0.8
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }
        QQC2.ScrollView {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8
            QQC2.TextArea {
                id: feeds
                wrapMode: TextEdit.NoWrap
                font.family: "monospace"
                placeholderText: "https://calendar.google.com/calendar/ical/…/basic.ics #3478f6"
            }
        }
        QQC2.Label {
            text: i18n("These URLs are secrets: anyone with one can read that calendar. They are stored in your Plasma config (~/.config/plasma-org.kde.plasma.desktop-appletsrc).")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: hideFinished; Kirigami.FormData.label: i18n("Events:"); text: i18n("Hide events that have finished") }
        QQC2.SpinBox { id: maxEvents; Kirigami.FormData.label: i18n("Show at most:"); from: 1; to: 20 }
    }
}
