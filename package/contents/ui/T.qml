// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

// Widget text: chosen font, size scaled with the card, text colour and halo outline.
// `card` is the Card.qml root, found through the QML context.
import QtQuick

Text {
    property real size: 13
    property int weightIndex: card.textWeight
    font.family: card.family
    font.pixelSize: Math.max(1, size * card.sc)
    font.weight: card.weightOf(weightIndex)
    color: card.textColor
    style: card.halo > 0.01 ? Text.Outline : Text.Normal
    styleColor: card.haloColor
    elide: Text.ElideRight
    maximumLineCount: 1
    textFormat: Text.PlainText
}
