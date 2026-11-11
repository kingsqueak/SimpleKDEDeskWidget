#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 KC2RGW Chris
"""Today's events from ICS feeds, as JSON on stdout, for SimpleKDEDeskWidget.

Arguments are feed lines: "URL" or "URL #rrggbb" (webcal:// is treated as https://).
Each feed's last good copy is cached in ~/.cache/simplekdedeskwidget so a network
blip doesn't empty the list.
"""

import datetime as dt
import hashlib
import json
import os
import sys
import urllib.request

PALETTE = ["#3478f6", "#34c759", "#ff9500", "#af52de", "#ff2d55", "#30b0c7", "#a2845e"]
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
                     "simplekdedeskwidget")


def out(obj):
    print(json.dumps(obj))
    sys.exit(0)


try:
    import icalendar
    import recurring_ical_events
except ImportError:
    out({"events": [], "errors": [
        "Needs python3-icalendar and python3-recurring-ical-events (apt install them)"]})


def fetch(url):
    if url.startswith("webcal://"):
        url = "https://" + url[len("webcal://"):]
    path = os.path.join(CACHE, hashlib.sha1(url.encode()).hexdigest() + ".ics")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "SimpleKDEDeskWidget/0.1"})
        with urllib.request.urlopen(req, timeout=20) as r:
            data = r.read()
        os.makedirs(CACHE, exist_ok=True)
        with open(path + ".tmp", "wb") as f:
            f.write(data)
        os.replace(path + ".tmp", path)
        return data, None
    except Exception as e:  # noqa: BLE001 - any failure falls back to the cache
        err = f"{url.split('/')[2] if '//' in url else url}: {e}"
        if os.path.exists(path):
            with open(path, "rb") as f:
                return f.read(), err + " (showing cached copy)"
        return None, err


def local(t, tz):
    if isinstance(t, dt.datetime):
        if t.tzinfo is None:
            t = t.replace(tzinfo=tz)
        return t.astimezone(tz)
    return dt.datetime.combine(t, dt.time(0), tz)


def main():
    tz = dt.datetime.now().astimezone().tzinfo
    start = dt.datetime.combine(dt.date.today(), dt.time(0), tz)
    end = start + dt.timedelta(days=1)
    events, errors = [], []
    for i, line in enumerate(a for a in sys.argv[1:] if a.strip()):
        parts = line.split()
        url = parts[0]
        color = next((p for p in parts[1:] if p.startswith("#")), PALETTE[i % len(PALETTE)])
        data, err = fetch(url)
        if err:
            errors.append(err)
        if data is None:
            continue
        try:
            cal = icalendar.Calendar.from_ical(data)
            name = str(cal.get("X-WR-CALNAME", ""))
            for ev in recurring_ical_events.of(cal).between(start, end):
                if str(ev.get("STATUS", "")).upper() == "CANCELLED":
                    continue
                s = ev.get("DTSTART").dt
                e = ev.get("DTEND").dt if ev.get("DTEND") else None
                all_day = not isinstance(s, dt.datetime)
                s_l = local(s, tz)
                if e is None:
                    e_l = s_l + (dt.timedelta(days=1) if all_day else dt.timedelta(0))
                else:
                    e_l = local(e, tz)
                events.append({
                    "title": str(ev.get("SUMMARY", "(no title)")),
                    "start": s_l.isoformat(),
                    "end": e_l.isoformat(),
                    "startMs": int(s_l.timestamp() * 1000),
                    "endMs": int(e_l.timestamp() * 1000),
                    "allDay": all_day,
                    "color": color,
                    "calendar": name,
                    "location": str(ev.get("LOCATION", "")),
                })
        except Exception as e:  # noqa: BLE001
            errors.append(f"feed {i + 1}: {e}")
    events.sort(key=lambda x: (not x["allDay"], x["startMs"], x["title"]))
    out({"events": events, "errors": errors})


main()
