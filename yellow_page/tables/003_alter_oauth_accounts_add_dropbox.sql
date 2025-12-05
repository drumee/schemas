-- File: ~/schemas/yellow_page/tables/003_alter_oauth_accounts_add_dropbox.sql
-- Purpose: Add 'dropbox' to oauth_accounts provider enum

USE yp;

ALTER TABLE oauth_accounts 
MODIFY COLUMN provider ENUM('google', 'apple', 'dropbox') 
CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
COMMENT 'OAuth provider name';

SHOW CREATE TABLE oauth_accounts;