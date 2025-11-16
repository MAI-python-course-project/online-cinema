-- ClickHouse initialization script
-- Creates tables for analytics service

-- Create database
CREATE DATABASE IF NOT EXISTS analytics;

-- Use analytics database
USE analytics;

-- Viewing events table
CREATE TABLE IF NOT EXISTS viewing_events (
    event_id UUID DEFAULT generateUUIDv4(),
    user_id UUID,
    movie_id UUID,
    event_type String,
    timestamp DateTime DEFAULT now(),
    duration UInt32,
    progress UInt32,
    quality String,
    device String,
    ip_address String,
    user_agent String
) ENGINE = MergeTree()
ORDER BY (timestamp, user_id, movie_id)
PARTITION BY toYYYYMM(timestamp)
TTL timestamp + INTERVAL 1 YEAR;

-- Popular movies materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS popular_movies_daily
ENGINE = SummingMergeTree()
ORDER BY (date, movie_id)
AS SELECT
    toDate(timestamp) as date,
    movie_id,
    count() as view_count,
    sum(duration) as total_watch_time
FROM viewing_events
WHERE event_type = 'view'
GROUP BY date, movie_id;

-- User activity table
CREATE TABLE IF NOT EXISTS user_activity (
    user_id UUID,
    date Date,
    sessions_count UInt32,
    total_watch_time UInt32,
    movies_watched UInt32
) ENGINE = SummingMergeTree()
ORDER BY (date, user_id)
PARTITION BY toYYYYMM(date);
