-- File: ~/schemas/yellow_page/tables/001_create_oauth_accounts.sql

CREATE TABLE IF NOT EXISTS yp.oauth_accounts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL  
        COMMENT 'Reference to yp.entity.id',

    provider ENUM('google', 'apple') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    provider_user_id VARCHAR(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,

    email VARCHAR(255) NOT NULL,

    access_token TEXT DEFAULT NULL,
    refresh_token TEXT DEFAULT NULL,

    ctime INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (created_at)',
    mtime INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (updated_at)',

    UNIQUE KEY uni_provider_user (provider, provider_user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_email (email),

    CONSTRAINT fk_oauth_user_entity
        FOREIGN KEY (user_id) 
        REFERENCES yp.entity(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Links Drumee users (entity) to Google/Apple OAuth provider IDs';