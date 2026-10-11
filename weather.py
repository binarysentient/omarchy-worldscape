#!/usr/bin/env python3
"""Fetch independent city forecasts with a 15-minute last-good disk cache."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import urlopen, Request
from zoneinfo import ZoneInfo
import hashlib
import json
import os
import time

HERE = Path(__file__).resolve().parent
CACHE = Path(os.environ.get('XDG_CACHE_HOME', str(Path.home()/'.cache'))) / 'omarchy-worldscape'

def local_locations(locations):
    """Replace the matching country card with wttr.in's detected city."""
    options = json.loads((HERE/'local-location.json').read_text())
    if not options.get('enabled', False):
        return locations
    cache_file = CACHE/'local-location.json'
    cached = {}
    try:
        cached = json.loads(cache_file.read_text())
    except (OSError, ValueError):
        pass
    if time.time() - cached.get('checked', 0) >= 900:
        try:
            request = Request('https://wttr.in/?format=j1', headers={'User-Agent':'Omarchy-Worldscape/0.1'})
            with urlopen(request, timeout=10) as response:
                area = json.load(response)['nearest_area'][0]
            country = area['country'][0]['value']
            city = area['areaName'][0]['value']
            latitude, longitude = float(area['latitude']), float(area['longitude'])
            if not city or not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
                raise ValueError('Invalid detected location')
            cached = dict(checked=time.time(), city=city, country=country,
                          region=area.get('region', [{'value':''}])[0]['value'],
                          latitude=latitude, longitude=longitude)
            CACHE.mkdir(parents=True, exist_ok=True)
            cache_file.write_text(json.dumps(cached))
        except Exception:
            # Preserve the last detected city while offline; retry next minute.
            pass
    countries = {'Canada':0, 'United States of America':1, 'United States':1,
                 'USA':1, 'United Kingdom':2, 'India':3}
    rows = [dict(location, _local=False) for location in locations]
    index = countries.get(cached.get('country'))
    if index is not None:
        rows[index] = dict(rows[index], city=cached['city'],
                           region=', '.join(filter(None, [cached.get('region'), cached['country']])),
                           latitude=cached['latitude'], longitude=cached['longitude'],
                           _local=True, _autoTimezone=True)
    return rows

def is_local(zone):
    tz = os.environ.get('TZ', '').lstrip(':')
    local = (Path(tz) if tz.startswith('/') else Path('/usr/share/zoneinfo')/tz) if tz else Path('/etc/localtime')
    try:
        return local.read_bytes() == (Path('/usr/share/zoneinfo')/zone).read_bytes()
    except OSError:
        return False

def fetch(location):
    row = dict(location, local=location.get('_local', is_local(location['zone'])), report=None, stale=False, error='')
    moment = datetime.now(ZoneInfo(location['zone']))
    row['time'] = moment.strftime('%H:%M')
    # Same local-hour periods as the world clock; approximate, not sunrise/set.
    hour = moment.hour
    row['periodIcon'] = ('\U000f059c' if 5 <= hour < 8 else
                         '\U000f0599' if 8 <= hour < 17 else
                         '\U000f059b' if 17 <= hour < 20 else
                         '\U000f0594' if 20 <= hour < 23 else '\U000f04b2')
    key = hashlib.sha256(json.dumps(location, sort_keys=True).encode()).hexdigest()[:20]
    path = CACHE / (key + '.json')
    cached = {}
    try:
        cached = json.loads(path.read_text())
        row['report'] = cached['report']
        row['updated'] = cached['updated']
    except (OSError, ValueError, KeyError):
        cached = {}
    if time.time() - cached.get('updated', 0) < 900:
        return row
    params = dict(latitude=location['latitude'], longitude=location['longitude'], timezone='auto' if location.get('_autoTimezone') else location['zone'],
                  current='temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day',
                  daily='weather_code,temperature_2m_max,temperature_2m_min', forecast_days=4)
    try:
        request = Request('https://api.open-meteo.com/v1/forecast?' + urlencode(params), headers={'User-Agent':'Omarchy-Worldscape/0.1'})
        with urlopen(request, timeout=12) as response:
            report = json.load(response)
        if report.get('current', {}).get('temperature_2m') is None:
            raise ValueError('Missing current weather')
        row.update(report=report, updated=time.time())
        CACHE.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix('.' + str(os.getpid()) + '.tmp')
        temporary.write_text(json.dumps(dict(report=report, updated=row['updated'])))
        temporary.replace(path)
    except Exception:
        row.update(stale=bool(row['report']), error='Offline · cached forecast' if row['report'] else 'Weather unavailable · retrying')
    return row

def update_local_time(row):
    # A detected US city can be outside Pacific time. Use its forecast zone.
    zone = (row.get('report') or {}).get('timezone') or row['zone']
    moment = datetime.now(ZoneInfo(zone))
    row['time'] = moment.strftime('%H:%M')
    hour = moment.hour
    row['periodIcon'] = ('\U000f059c' if 5 <= hour < 8 else
                         '\U000f0599' if 8 <= hour < 17 else
                         '\U000f059b' if 17 <= hour < 20 else
                         '\U000f0594' if 20 <= hour < 23 else '\U000f04b2')
    return row

if __name__ == '__main__':
    locations = local_locations(json.loads((HERE/'locations.json').read_text()))
    with ThreadPoolExecutor(max_workers=4) as pool:
        print(json.dumps([update_local_time(row) for row in pool.map(fetch, locations)]))
