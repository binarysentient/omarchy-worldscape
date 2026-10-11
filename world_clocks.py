#!/usr/bin/env python3
"""Local tzdata supplies DST rules; no network or fixed PST/EST offsets."""
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo
import json
import os

ZONES = [('Toronto', 'Canada · Eastern', 'America/Toronto'),
         ('California', 'United States · Pacific', 'America/Los_Angeles'),
         ('London', 'United Kingdom', 'Europe/London'),
         ('India', 'India Standard Time', 'Asia/Kolkata')]

def day_period(hour):
    """Approximate daily rhythm by local hour, not astronomical sunrise/set."""
    if 5 <= hour < 8:
        return 'Dawn', '\U000f059c'
    if 8 <= hour < 17:
        return 'Day', '\U000f0599'
    if 17 <= hour < 20:
        return 'Dusk', '\U000f059b'
    if 20 <= hour < 23:
        return 'Night', '\U000f0594'
    return 'Sleep', '\U000f04b2'

def local_zone_path():
    tz = os.environ.get('TZ', '').lstrip(':')
    if tz:
        return Path(tz) if tz.startswith('/') else Path('/usr/share/zoneinfo') / tz
    return Path('/etc/localtime')

def clocks(now=None):
    now = now or datetime.now(timezone.utc)
    local = now.astimezone()
    rows = []
    for city, region, name in ZONES:
        moment = now.astimezone(ZoneInfo(name))
        period, period_icon = day_period(moment.hour)
        try: current = local_zone_path().resolve().read_bytes() == (Path('/usr/share/zoneinfo')/name).read_bytes()
        except OSError: current = False
        delta = (moment.date() - local.date()).days
        date = moment.strftime('%a %d %b').replace(' 0', ' ')
        if delta: date = ('Tomorrow' if delta == 1 else 'Yesterday' if delta == -1 else f'{delta:+d} days') + ' · ' + date
        minutes = int((moment.utcoffset() - local.utcoffset()).total_seconds() / 60)
        hours, mins = divmod(abs(minutes), 60)
        relative = 'Same time' if minutes == 0 else ('+' if minutes > 0 else '−') + str(hours) + (f':{mins:02d}' if mins else '') + 'h'
        rows.append(dict(city=city, region=region, zone=name, time=moment.strftime('%H:%M'),
                         abbreviation=moment.tzname(), date=date, current=current, difference=relative,
                         period=period, periodIcon=period_icon))
    return rows

if __name__ == '__main__':
    print(json.dumps(clocks()))
