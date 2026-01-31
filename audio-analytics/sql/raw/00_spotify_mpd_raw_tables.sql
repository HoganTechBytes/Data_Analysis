-- ==============================================================================================
-- Spotify Million PLaylist Dataset (MPD 1)
-- Raw ingestion tables
-- Database: audio_analytics (PostgreSQL)
-- Schema: spotify_raw
-- Owner: jon_admin
-- ==============================================================================================

CREATE SCHEMA IF NOT EXISTS spotify_raw AUTHORIZATION jon_admin;

-- ----------------------------------------------------------------------------------------------
-- Slice metadata (one row per JSON slice file)
-- ----------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS spotify_raw.mpd_slices(
    slice_id            bigserial       PRIMARY KEY,
    slice_label         text            NOT NULL,               -- e.g. '0-999'
    generated_on        timestamp,
    version             text,
    source_file         text            NOT NULL,               -- filename
    loaded_at           timestamp       NOT NULL DEFAULT now(),
    UNIQUE (source_file)

);

-- ----------------------------------------------------------------------------------------------
-- Playlists
-- ----------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS spotify_raw.mpd_playlists(
    pid                 bigint          PRIMARY KEY,            -- Playlist ID
    name                text,
    description         text,
    collaborative       text,                                   -- 'true'/'false' as provided
    modified_at         bigint,                                 -- epoch seconds (UTC)
    num_tracks          int,
    num_albums          int,
    num_artist          int,
    num_followers       int,
    num_edits           int,
    duration_ms         bigint,
    slice_id            bigint
        REFERENCES spotify_raw.mpd_slices(slice_id),
    raw_json            jsonb
);

-- ----------------------------------------------------------------------------------------------
-- Tracks in playlists (appearance level grain)
-- ----------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS spotify_raw.mpd_playlists_tracks(
    pid                 bigint NOT NULL
        REFERENCES spotify_raw.mpd_playlists(pid),
    pos                 int NOT NULL,                   -- position in playlist
    track_uri           text NOT NULL,
    track_name          text,
    artist_uri          text,
    artist_name         text,
    album_uri           text,
    album_name          text,
    duration_ms         int,
    raw_json            jsonb,
    PRIMARY KEY (pid, pos)
);

-- ----------------------------------------------------------------------------------------------
-- Indexes for common joins / analytics paths
-- ----------------------------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS ix_mpd_tracks_track_uri
    ON spotify_raw.mpd_playlists_tracks (track_uri);

CREATE INDEX IF NOT EXISTS ix_mpd_tracks_artist_uri
    ON spotify_raw.mpd_playlists_tracks (artist_uri);

CREATE INDEX IF NOT EXISTS ix_mpd_tracks_album_uri
    ON spotify_raw.mpd_playlists_tracks (album_uri);

CREATE INDEX IF NOT EXISTS ix_mpd_playlists_slice_id
    ON spotify_raw.mpd_playlists (slice_id);