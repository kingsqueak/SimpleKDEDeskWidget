// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQC

KCM.SimpleKCM {
    property string cfg_fontFamily
    property alias cfg_clockWeight: clockWeight.currentIndex
    property alias cfg_textWeight: textWeight.currentIndex
    property alias cfg_textColor: textColor.color
    property alias cfg_backgroundColor: backgroundColor.color
    property alias cfg_backgroundOpacity: backgroundOpacity.value
    property alias cfg_displayOpacity: displayOpacity.value
    property alias cfg_shadowStrength: shadowStrength.value
    property alias cfg_textHalo: textHalo.value
    property alias cfg_plasmaBackground: plasmaBackground.checked

    readonly property var weightNames: ["Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"]

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: fontFamily
            Kirigami.FormData.label: i18n("Font:")
            model: [i18n("System default")].concat(Qt.fontFamilies())
            currentIndex: cfg_fontFamily === "" ? 0 : Math.max(0, model.indexOf(cfg_fontFamily))
            onActivated: cfg_fontFamily = currentIndex === 0 ? "" : currentText
            Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        }
        QQC2.ComboBox {
            id: clockWeight
            Kirigami.FormData.label: i18n("Clock weight:")
            model: weightNames
        }
        QQC2.ComboBox {
            id: textWeight
            Kirigami.FormData.label: i18n("Text weight:")
            model: weightNames
        }

        Item { Kirigami.FormData.isSection: true }

        KQC.ColorButton {
            id: textColor
            Kirigami.FormData.label: i18n("Text colour:")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Text outline:")
            QQC2.Slider { id: textHalo; from: 0; to: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: Math.round(textHalo.value * 100) + "%" }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Drop shadow:")
            QQC2.Slider { id: shadowStrength; from: 0; to: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: Math.round(shadowStrength.value * 100) + "%" }
        }

        Item { Kirigami.FormData.isSection: true }

        KQC.ColorButton {
            id: backgroundColor
            Kirigami.FormData.label: i18n("Card colour:")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Card opacity:")
            QQC2.Slider { id: backgroundOpacity; from: 0; to: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: Math.round(backgroundOpacity.value * 100) + "%" }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Whole widget:")
            QQC2.Slider { id: displayOpacity; from: 0.2; to: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
            QQC2.Label { text: Math.round(displayOpacity.value * 100) + "%" }
        }
        QQC2.CheckBox {
            id: plasmaBackground
            text: i18n("Use the Plasma theme background")
        }
        QQC2.Label {
            text: i18n("Size: enter Edit Mode on the desktop and drag the widget's corner; everything scales with its width.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }
    }
}
