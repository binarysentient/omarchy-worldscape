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

def read_rows():
    try:
        return json.loads(SNAPSHOT.read_text())
    except (OSError, ValueError):
        return [dict(r, local=weather.is_local(r['zone']), report=None, error='Fetching forecast…', stale=False)
                for r in json.loads((weather.HERE/'locations.json').read_text())]

def clock_rows(rows):
    now = datetime.now(timezone.utc)
    local = now.astimezone()
    for index, row in enumerate(rows):
        row.setdefault("country", ["Canada", "United States", "United Kingdom", "India"][index])
        weather.update_local_time(row)
        zone = (row.get('report') or {}).get('timezone') or row['zone']
        moment = now.astimezone(ZoneInfo(zone))
        row['abbreviation'] = moment.tzname()
        row['date'] = moment.strftime('%a %d %b').replace(' 0', ' ')
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
