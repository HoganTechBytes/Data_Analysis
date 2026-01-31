# pylint: disable=invalid-name,import-error

"""
    Audio Analytics — Read One Spotify MPD Slice (No DB Writes)

    Purpose:
    - Confirm we can reliably read one MPD slice file from disk
    - Inspect slice-level metadata (info block)
    - Inspect playlist-level structure (count + first playlist peek)
    - Compute expected track-appearance rows (sum of num_tracks)

    This script is intentionally read-only.
    It builds confidence before we insert any playlist/track rows into Postgres.
"""

from __future__ import annotations
import json
from pathlib import Path

# =====================================================================================
# Path configuration
# Figure out where the project root is so this script works
# no matter where I run it from (VS Code terminal, repo root, etc.)
# =====================================================================================

SCRIPT_PATH = Path(__file__).resolve()

# -------------------------------------------------------------------------------------
# This backs us up to the audio-analytics/ directory.
# Using this instead of relative paths keeps things predictable.
# -------------------------------------------------------------------------------------

PROJECT_ROOT = SCRIPT_PATH.parents[2]
RAW_DATA_DIR = PROJECT_ROOT / '.raw' / 'data'

# -------------------------------------------------------------------------------------
# Hardcoding the first slice on purpose.
# This is the training-wheels run before anything gets automated.
# -------------------------------------------------------------------------------------

SLICE_FILE = 'mpd.slice.0-999.json'
SLICE_PATH = RAW_DATA_DIR / SLICE_FILE

# -------------------------------------------------------------------------------------
# Slice-level metadata (maps to spotify_raw.mpd_slices)
# This should be 1-1 with the the row already inserted into our database (PostgreSQL)
# -------------------------------------------------------------------------------------

print(f'[INFO] Reading MPD slice from: {SLICE_PATH}')

with SLICE_PATH.open(encoding='utf-8') as f:
    data = json.load(f)

info = data.get('info', {})
slice_label = info.get('slice')
generated_on = info.get('generated_on')
version = info.get('version')

if not slice_label:
    print('[QA WARNING] Missing slice label in JSON; file provenance may be incomplete.')

print(f'[INFO] slice_label: {slice_label}')
print(f'[INFO] generated_on: {generated_on}')
print(f'[INFO] version: {version}')

# ---------------------------------------------------------------------------------
# Playlist-level structure (maps to spotify_raw.mpd_playlists)
# At this stage we are only inspecting shape and counts — no DB writes yet.
# ---------------------------------------------------------------------------------

playlists = data.get('playlists', [])

print(f'[INFO] playlists_in_slice: {len(playlists):,}')

# Peek at the first playlist just to confirm expected keys exist
first = playlists[0]
pid = first.get('pid')
name = first.get('name')

print(f'[INFO] first_playlist_pid: {pid}')
print(f'[INFO] first_playlist_name: {name}')

# ---------------------------------------------------------------------------------
# Expected track appearance rows
# This gives us a rough expectation for how large
# spotify_raw.mpd_playlists_tracks should be after ingestion.
# ---------------------------------------------------------------------------------

expected_tracks = sum(p.get('num_tracks', 0) for p in playlists)

print(
    f'[INFO] expected_track_appearances (sum of num_tracks): '
    f'{expected_tracks:,}'
)

# ---------------------------------------------------------------------------------
# QA check: declared num_tracks should usually match the length of the
# tracks array for a playlist. Differences are not fatal, but they may
# affect expected row counts and downstream validation.
# ---------------------------------------------------------------------------------

declared = first.get('num_tracks')
actual = len(first.get('tracks', []))

if declared is not None and declared != actual:
    print(
        '[QA NOTE] num_tracks mismatch on first playlist. '
        f'Declared={declared}, actual_tracks={actual}. '
        'This may impact expected appearance-row totals; '
        'validate during ingestion.'
    )