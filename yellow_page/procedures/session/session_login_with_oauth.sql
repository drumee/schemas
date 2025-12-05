DELIMITER $$

DROP PROCEDURE IF EXISTS yp.session_login_with_oauth$$

CREATE PROCEDURE yp.session_login_with_oauth(
    IN _provider VARCHAR(20) CHARACTER SET ascii,
    IN _provider_user_id VARCHAR(255) CHARACTER SET ascii,
    IN _email VARCHAR(500), 
    IN _cid VARCHAR(64) CHARACTER SET ascii,
    IN _domain_name VARCHAR(1000)
)
sp_main: BEGIN
    DECLARE _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL;
    DECLARE _profile JSON DEFAULT "{}";
    DECLARE _sid VARCHAR(64) CHARACTER SET ascii;
    DECLARE _db_name VARCHAR(52) DEFAULT '0';
    DECLARE _ctime INT(11); 
    DECLARE _dom_id INT(8);
    DECLARE _secret VARCHAR(500);

    SELECT IFNULL(domain_id, 1) 
    FROM yp.organisation 
    WHERE link = _domain_name OR domain_id = _domain_name
    INTO _dom_id;

    -- STEP 1: Try to find user by OAuth provider + provider_user_id
    SELECT oa.user_id 
    FROM oauth_accounts oa
    WHERE oa.provider = _provider AND oa.provider_user_id = _provider_user_id
    INTO _uid;

    -- STEP 2: If OAuth account NOT found, check if email exists
    IF _uid IS NULL THEN
      SELECT e.id 
      FROM drumate d
      INNER JOIN entity e ON e.id = d.id  
      LEFT JOIN organisation o ON o.domain_id = e.dom_id
      WHERE d.email = _email AND o.link = _domain_name
      INTO _uid;
      
      -- If email exists without OAuth link, AUTO-LINK it
      IF _uid IS NOT NULL THEN
          -- Create OAuth account link automatically
          INSERT INTO oauth_accounts (
            user_id, 
            provider, 
            provider_user_id, 
            email, 
            linked_at
          )
          VALUES (
            _uid, 
            _provider, 
            _provider_user_id, 
            _email, 
            UNIX_TIMESTAMP()
          )
          ON DUPLICATE KEY UPDATE
            linked_at = UNIX_TIMESTAMP();
      
      END IF;
    END IF;

    -- STEP 3: Get user profile if found
    IF _uid IS NOT NULL THEN
      SELECT e.id, `profile`, e.db_name, d.email, o.link 
      FROM drumate d 
      INNER JOIN entity e ON e.id = d.id  
      LEFT JOIN organisation o ON o.domain_id = e.dom_id
      WHERE e.id = _uid AND o.link = _domain_name
      INTO _uid, _profile, _db_name, _email, _domain_name;
    END IF;

    -- Get secret token
    SELECT secret FROM token WHERE email = _email AND method = 'signup' 
    ORDER BY ctime DESC LIMIT 1 INTO _secret;

    -- STEP 4: Handle result
    IF _uid IS NULL THEN 
        -- User not found - Return error (should trigger SIGN-UP flow)
        UPDATE cookie SET failed = failed + 1, `status` = 'oauth_user_not_found' 
        WHERE id = _cid;
        
        SELECT failed, `status`, 'oauth_user_not_found' AS error_code,
               'User not found. Please sign up first.' AS message
        FROM cookie 
        WHERE id = _cid;
    ELSE
      -- User found - Create/update session
      SELECT id FROM cookie WHERE id = _cid INTO _sid;
      IF _sid IS NULL THEN 
        SELECT _cid INTO _sid;
        SELECT UNIX_TIMESTAMP() INTO _ctime;
        INSERT INTO cookie (`id`,`uid`,`ctime`,`mtime`,`ua`, `status`)
        VALUES(_sid, _uid, _ctime, _ctime, 'oauth_login', 'new');
      END IF;
      
      
      UPDATE cookie SET 
        failed = 0, 
        mtime = UNIX_TIMESTAMP(), 
        `uid` = _uid, 
        status = 'ok',
        ttl = IFNULL(JSON_VALUE(_profile, "$.session_ttl"), 2592000)
      WHERE id = _cid;
      
      SELECT
        c.id AS session_id,
        e.id,
        e.id AS hub_id,
        d.username AS ident,
        d.username,
        d.fullname,
        _domain_name AS domain,
        _dom_id AS domain_id,
        db_name,
        db_host,
        fs_host,
        vhost,
        home_dir,
        home_id,
        c.status,
        email,
        dmail,
        firstname,
        lastname,
        area,
        area_id AS aid,
        e.status AS `condition`,
        e.mtime,
        e.ctime,
        `profile` AS `profile`,
        _secret AS `secret`,
        _provider AS oauth_provider 
      FROM entity e 
      INNER JOIN (drumate d, cookie c) ON e.id = d.id AND e.id = c.uid 
      WHERE d.id = _uid AND c.id = _cid;
    END IF;
END$$

DELIMITER ;