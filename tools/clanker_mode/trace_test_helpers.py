"""Structural trace assertions shared by local and live capability tests."""

import json


def read_records(path):
    return [json.loads(line) for line in path.read_text().splitlines()]


def message_bodies(records):
    return [record["message"] for record in records if record["type"] == "message"]
