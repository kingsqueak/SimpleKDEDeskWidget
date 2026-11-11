// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_use24Hour: use24Hour.checked
    property alias cfg_showSeconds: showSeconds.checked
    property alias cfg_showDate: showDate.checked
    property alias cfg_showZulu: showZulu.checked

    Kirigami.FormLayout {
        QQC2.CheckBox { id: use24Hour; Kirigami.FormData.label: i18n("Clock:"); text: i18n("24-hour time") }
        QQC2.CheckBox { id: showSeconds; text: i18n("Show seconds") }
        QQC2.CheckBox { id: showDate; text: i18n("Show the date") }
        QQC2.CheckBox { id: showZulu; text: i18n("Show UTC (Zulu) time") }
    }
}
