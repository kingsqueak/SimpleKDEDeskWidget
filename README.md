# SimpleKDEDeskWidget

A KDE Plasma 6 desktop widget: a big clock, a three-day forecast, US weather alerts, nearby lightning and today's calendar. It's the Plasma version of [SimpleDesktopWidget](https://github.com/kingsqueak/SimpleDesktopWidget) for macOS.

- **Clock**: 12 or 24 hour, seconds, date, UTC (Zulu) time.
- **Forecast**: [Open-Meteo](https://open-meteo.com) (free, no key). Shows high and low, a temperature-range bar, chance and amount of precipitation, and wind gusts. Refreshes every 30 minutes.
- **Alerts**: active National Weather Service alerts for your location, one banner for each type of alert (US only). Checked every 5 minutes.
- **Lightning**: live strikes from the volunteer [Blitzortung.org](https://www.blitzortung.org) network. The widget filters strikes on your computer by the radius you choose, so your location is never sent anywhere. Off by default. Don't use it for safety decisions.
- **Calendar**: today's events from ICS feed URLs, including recurring events. Finished events fade out, and the one happening now is marked NOW.
- **Appearance**: font, clock and text weight, text colour, text outline, drop shadow, card colour and opacity. Everything scales with the widget's width.

## Install

Needs Plasma 6 and, for the calendar, two Python libraries:

```sh
sudo apt install python3-icalendar python3-recurring-ical-events
./install.sh            # install or upgrade into ~/.local/share/plasma/plasmoids
./install.sh restart    # same, then restart plasmashell so the desktop loads the new code
./install.sh test       # try it in plasmoidviewer (package plasma-sdk) without installing
./install.sh remove
```

Then right-click the desktop, choose **Add or Manage Widgets…**, and drag **SimpleKDEDeskWidget** onto the desktop. To resize it, enter Edit Mode and drag a corner. To change its settings, right-click it and choose **Configure SimpleKDEDeskWidget…**.

## Settings

- **Weather → Find place** searches Open-Meteo's place list. Small towns sometimes don't appear; if yours doesn't, type the latitude and longitude yourself.
- **Calendar → ICS feeds**: put one URL per line. You can add a colour after the URL, like `https://…/basic.ics #34c759`. `webcal://` links work too.
  - Google Calendar: open the calendar's settings and copy **Secret address in iCal format**.
  - iCloud: share the calendar as a public calendar and copy the link.
  - Treat these URLs like passwords: anyone who has one can read the calendar. Plasma keeps them in `~/.config/plasma-org.kde.plasma.desktop-appletsrc`.
  - Feeds are fetched every 15 minutes. The last good copy of each is kept in `~/.cache/simplekdedeskwidget/`, so the list stays filled if the network drops.

## Differences from the Mac version

- Moving and resizing use Plasma's own Edit Mode instead of the Mac version's Configure mode.
- There's no frosted glass. The **Use the Plasma theme background** option gives you the theme's panel background instead.
- Desktop icons aren't moved out of the widget's way. Plasma keeps widgets and folder-view icons on separate layers.
- The calendar reads ICS feeds instead of the system calendar (EventKit on the Mac).

## How it works

Everything is QML and JavaScript running inside plasmashell:

- Open-Meteo and NWS are fetched with `XMLHttpRequest`.
- Blitzortung comes in over a `QtWebSockets` connection. Its messages are LZW-packed JSON, decoded in `contents/code/logic.js`.
- Calendar feeds go through `contents/code/sdkw_calendar.py`, run with Plasma's executable data engine. It prints today's events as JSON.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
