-- Create multiple databases for microservices
-- This script runs automatically when PostgreSQL container starts

-- Auth Service database
CREATE DATABASE auth;
GRANT ALL PRIVILEGES ON DATABASE auth TO cinema;

-- User Service database
CREATE DATABASE users;
GRANT ALL PRIVILEGES ON DATABASE users TO cinema;

-- Catalog Service database
CREATE DATABASE catalog;
GRANT ALL PRIVILEGES ON DATABASE catalog TO cinema;

-- Payment Service database
CREATE DATABASE payments;
GRANT ALL PRIVILEGES ON DATABASE payments TO cinema;

-- Print confirmation
\echo 'Databases created successfully!'
\echo 'Available databases:'
\l
