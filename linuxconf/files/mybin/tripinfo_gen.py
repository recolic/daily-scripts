#!/usr/bin/env python3
# GPT 5.6 sol
"""Convert a structured trip document to an ASCII or Markdown checklist."""

from __future__ import annotations

import argparse
import configparser
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

ASCII_WIDTH = 48
ASCII_TIME_MIN_WIDTH = 15
ASCII_ROUTE_MIN_WIDTH = 16


@dataclass(frozen=True)
class Ride:
    src_time: datetime | None
    src_loc: str
    src_terminal: str
    dst_time: datetime | None
    dst_loc: str
    dst_terminal: str
    ride_id: str
    reserve: str
    ticket: str
    seat: str
    note: str


def parse_time(value: str, section: str, field: str) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError as exc:
        raise ValueError(f"[{section}] {field} is not an ISO date/time: {value}") from exc


def read_rides(path: Path) -> list[Ride]:
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.optionxform = str
    try:
        with path.open(encoding="utf-8") as source:
            parser.read_file(source)
    except (OSError, configparser.Error) as exc:
        raise ValueError(f"cannot read {path}: {exc}") from exc

    rides: list[Ride] = []
    for section in parser.sections():
        get = parser[section].get
        rides.append(
            Ride(
                src_time=parse_time(get("src.t", "").strip(), section, "src.t"),
                src_loc=get("src.loc", "").strip(),
                src_terminal=get("src.terminal", "").strip(),
                dst_time=parse_time(get("dst.t", "").strip(), section, "dst.t"),
                dst_loc=get("dst.loc", "").strip(),
                dst_terminal=get("dst.terminal", "").strip(),
                ride_id=get("ride.id", "").strip(),
                reserve=get("ride.reserve", "").strip(),
                ticket=get("ride.ticket", "").strip(),
                seat=get("ride.seat", "").strip(),
                note=get("ride.note", "").strip(),
            )
        )
    return rides


def location(loc: str, terminal: str) -> str:
    return f"{loc}:{terminal}" if terminal else loc


def ascii_location(loc: str, terminal: str) -> str:
    if len(loc) == 3 and loc.isalpha():
        return f"{loc}:{terminal:<2}" if terminal else f"{loc:<6}"
    return f"{loc}:{terminal:<2}" if terminal else loc


def clock(value: datetime | None) -> str:
    return value.strftime("%H:%M") if value else ""


def arrival_clock(ride: Ride) -> str:
    if ride.dst_time is None:
        return ""
    if ride.src_time is None:
        return clock(ride.dst_time)
    days = (ride.dst_time.date() - ride.src_time.date()).days
    prefix = f"{days}+" if days > 0 else ""
    return prefix + clock(ride.dst_time)


def ticket_number(value: str) -> str:
    return f"{value[:3]}-{value[3:]}" if len(value) == 13 and value.isdigit() else value


def optional_ascii(ride: Ride) -> str:
    parts = [part for part in (ticket_number(ride.ticket), ride.reserve) if part]
    result = " / ".join(parts)
    if ride.note:
        result = f"{result} {ride.note}".strip()
    return result


def optional_md(ride: Ride) -> str:
    parts = [part for part in (ticket_number(ride.ticket), ride.reserve) if part]
    result = " / ".join(parts)
    if ride.note:
        result = f"{result}; {ride.note}" if result else ride.note
    return result


def ascii_time_range(ride: Ride) -> str:
    return f"{clock(ride.src_time)} - {arrival_clock(ride)}"


def ascii_route(ride: Ride) -> str:
    return f"{ascii_location(ride.src_loc, ride.src_terminal)} => {ascii_location(ride.dst_loc, ride.dst_terminal)}"


def ascii_ride(ride: Ride) -> str:
    details = ride.ride_id
    if ride.seat:
        details = f"{details}:{ride.seat}"
    return details


def ascii_header(value: datetime | None) -> str:
    return value.strftime("%b %d [%a]").replace(" 0", " ") if value else "Date unknown"


def render_ascii(rides: list[Ride]) -> str:
    lines: list[str] = []
    current_date = object()
    for ride in rides:
        ride_date = ride.src_time.date() if ride.src_time else None
        if ride_date != current_date:
            if lines:
                lines.append("")
            lines.extend((ascii_header(ride.src_time), ""))
            current_date = ride_date
        time_range = ascii_time_range(ride)
        route = ascii_route(ride)
        details = ascii_ride(ride)
        line = f"{time_range:<{ASCII_TIME_MIN_WIDTH}} {route:<{ASCII_ROUTE_MIN_WIDTH}}"
        if details:
            line += f", {details}"
        if len(line) > ASCII_WIDTH:
            route = route.replace(" => ", "=>")
            line = f"{time_range:<{ASCII_TIME_MIN_WIDTH}} {route:<{ASCII_ROUTE_MIN_WIDTH}}"
            if details:
                line += f", {details}"
        if len(line) > ASCII_WIDTH:
            time_range = time_range.replace(" - ", "-")
            line = f"{time_range:<{ASCII_TIME_MIN_WIDTH}} {route:<{ASCII_ROUTE_MIN_WIDTH}}"
            if details:
                line += f", {details}"
        lines.append(line.rstrip())
        optional = optional_ascii(ride)
        if optional:
            lines.append(f"{'':<{ASCII_TIME_MIN_WIDTH}} {optional}")
        lines.append("")
    return "\n".join(lines).rstrip() + ("\n" if rides else "")


def markdown_header(value: datetime | None, first: datetime | None) -> str:
    if value is None:
        return "## Date unknown"
    offset = (value.date() - first.date()).days if first else 0
    day = "D Day" if offset == 0 else f"D+{offset}"
    return f"## {day} / {value.strftime('%b %d').upper()}"


def render_md(rides: list[Ride]) -> str:
    lines: list[str] = []
    first = next((ride.src_time for ride in rides if ride.src_time), None)
    current_date = object()
    for ride in rides:
        ride_date = ride.src_time.date() if ride.src_time else None
        if ride_date != current_date:
            if lines:
                lines.append("")
            lines.extend((markdown_header(ride.src_time, first), "", "| | |", "|---|---|"))
            current_date = ride_date
        route = f"{location(ride.src_loc, ride.src_terminal)}=>{location(ride.dst_loc, ride.dst_terminal)}"
        time_range = f"**{clock(ride.src_time)} - {arrival_clock(ride)}**<br />{route}"
        ride_details = f"**{ride.ride_id}**" if ride.ride_id else ""
        if ride.seat:
            ride_details += f":{ride.seat}"
        optional = optional_md(ride)
        if optional:
            ride_details += f" <br />{optional}"
        lines.append(f"|{time_range}|{ride_details}|")
    return "\n".join(lines).rstrip() + ("\n" if rides else "")


def main() -> int:
    argument_parser = argparse.ArgumentParser(description=__doc__)
    argument_parser.add_argument("path", type=Path, help="structured trip text file")
    argument_parser.add_argument("format", choices=("ascii", "md"), help="output format")
    args = argument_parser.parse_args()

    try:
        rides = read_rides(args.path)
    except ValueError as exc:
        argument_parser.error(str(exc))
    sys.stdout.write(render_ascii(rides) if args.format == "ascii" else render_md(rides))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
