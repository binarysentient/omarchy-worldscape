#!/usr/bin/env python3
"""Independent non-network clock reads and asynchronous weather refreshes."""
import json
import os
import sys
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor
from zoneinfo import ZoneInfo
import weather

SNAPSHOT = weather.CACHE / 'calendar-snapshot.json'
COUNTRIES = ["Canada", "United States", "United Kingdom", "India"]

def configured_rows():
    return [dict(r, local=weather.is_local(r['zone']), report=None, error='Fetching forecast…', stale=False)
            for r in json.loads((weather.HERE/'locations.json').read_text())]

def read_rows():
    # An old, blank or hand-damaged snapshot falls back to the configured
    # cities; the clock must never depend on what the weather path left behind.
    try:
        rows = json.loads(SNAPSHOT.read_text())
        if isinstance(rows, list) and rows and all(isinstance(r, dict) and r.get('zone') for r in rows):
            return rows
    except (OSError, ValueError):
        pass
    return configured_rows()

def row_zone(row):
    for zone in ((row.get('report') or {}).get('timezone'), row.get('zone')):
        try:
            return ZoneInfo(zone)
        except Exception:
            continue
    return timezone.utc

def clock_rows(rows):
    now = datetime.now(timezone.utc)
    local = now.astimezone()
    for index, row in enumerate(rows):
        if index < len(COUNTRIES):
            row.setdefault("country", COUNTRIES[index])
        try:
            weather.update_local_time(row)
        except Exception:
            pass
        moment = now.astimezone(row_zone(row))
        row['abbreviation'] = moment.tzname()
        row['date'] = moment.strftime('%a %d %b').replace(' 0', ' ')
        # Real offset from tzdata, so the panel can keep each city's clock
        # (and its sky) moving between helper runs. Older readers ignore it.
        row['utcOffsetMinutes'] = int(moment.utcoffset().total_seconds() // 60)
        minutes = int((moment.utcoffset() - local.utcoffset()).total_seconds()/60)
        hours, mins = divmod(abs(minutes),60)
        row['difference'] = 'Same time' if minutes == 0 else ('+' if minutes > 0 else '−') + str(hours) + (f':{mins:02d}' if mins else '') + 'h'
    return rows

if __name__ == '__main__':
    if '--weather' in sys.argv:
        locations = weather.local_locations(json.loads((weather.HERE/'locations.json').read_text()))
        with ThreadPoolExecutor(max_workers=4) as pool:
            rows = list(pool.map(weather.fetch, locations))
        weather.CACHE.mkdir(parents=True,exist_ok=True)
        temp = SNAPSHOT.with_suffix(f'.{os.getpid()}.tmp')
        temp.write_text(json.dumps(rows)); temp.replace(SNAPSHOT)
    else:
        rows = read_rows()
    print(json.dumps(clock_rows(rows)))
