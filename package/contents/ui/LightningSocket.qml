// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 KC2RGW Chris

// The Blitzortung connection, in its own file so main.qml loads it with a Loader:
// if QtWebSockets isn't installed (package qml6-module-qtwebsockets), only the
// lightning line is lost, not the whole widget.
import QtWebSockets

WebSocket {
    active: false
    readonly property bool isOpen: status === WebSocket.Open
    readonly property bool failed: status === WebSocket.Error || status === WebSocket.Closed
}
