#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Install or update the plasmoid for this user.
#   ./install.sh           install / upgrade
#   ./install.sh restart   install, then restart plasmashell so the desktop loads the new code
#   ./install.sh test      run it in plasmoidviewer (plasma-sdk) without installing
#   ./install.sh remove    uninstall
set -e
cd "$(dirname "$0")"
ID=com.kingsqueak.simplekdedeskwidget

case "${1:-}" in
    test)
        exec plasmoidviewer -a package -l floating -f planar -s 460x760
        ;;
    remove)
        kpackagetool6 -t Plasma/Applet -r "$ID"
        exit 0
        ;;
esac

if kpackagetool6 -t Plasma/Applet -s "$ID" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u package
else
    kpackagetool6 -t Plasma/Applet -i package
fi

if [ "${1:-}" = restart ]; then
    systemctl --user restart plasma-plasmashell.service
fi
