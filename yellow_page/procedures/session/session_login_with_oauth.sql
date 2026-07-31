DELIMITER $$

DROP PROCEDURE IF EXISTS session_login_with_oauth$$
CREATE PROCEDURE session_login_with_oauth(
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
    -- Email the OAuth provider supplied on THIS request (before STEP 3 overwrites
    -- _email with the stored drumate address). Used to keep relay addresses in
    -- sync when Apple rotates them (revoke + re-grant keeps the sub but issues a
    -- new @privaterelay.appleid.com address; the old one stops forwarding).
    DECLARE _oauth_email VARCHAR(500) DEFAULT _email;
    DECLARE _stored_email VARCHAR(500) DEFAULT NULL;
    -- Derived from the address suffix rather than passed as a param, so this SP's
    -- signature stays unchanged (5 args) and it can be patched independently of
    -- the loby code. @privaterelay.appleid.com is Apple's fixed relay domain.
    DECLARE _is_private_email TINYINT DEFAULT 0;
    -- Owner of the Google address, when it belongs to a DIFFERENT drumate than
    -- the provider_user_id currently resolves to (STEP 1b pollution guard).
    DECLARE _email_owner_uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL;

    SET _is_private_email = IF(_oauth_email LIKE '%@privaterelay.appleid.com', 1, 0);

    SELECT IFNULL(domain_id, 1) 
    FROM yp.organisation 
    WHERE link = _domain_name OR domain_id = _domain_name
    INTO _dom_id;

    -- STEP 1: Try to find user by OAuth provider + provider_user_id
    SELECT oa.user_id
    FROM oauth_accounts oa
    WHERE oa.provider = _provider AND oa.provider_user_id = _provider_user_id
    INTO _uid;

    -- STEP 1b: Guard against Google-Drive-connect pollution hijacking sign-in.
    -- oauth_accounts is shared between sign-in identity and Drive-integration
    -- tokens: google_drive_callback writes the CONNECTING user's user_id for a
    -- connected account's provider_user_id, so a sub can end up mapped to a user
    -- who is NOT the owner of that Google address. drumate.email is UNIQUE, so if
    -- a DIFFERENT drumate owns this Google address, the sub-link is that artifact
    -- and must not drive sign-in — resolve to the address owner instead. Only
    -- overrides on a positive owner match (leaves normal / email-changed sign-ins
    -- untouched); skipped for Apple private-relay addresses (rotating, not a
    -- stable ownership key).
    IF _uid IS NOT NULL AND _is_private_email = 0
       AND _oauth_email IS NOT NULL AND _oauth_email <> '' THEN
      SELECT e.id
      FROM drumate d
      INNER JOIN entity e ON e.id = d.id
      LEFT JOIN organisation o ON o.domain_id = e.dom_id
      WHERE d.email = _oauth_email AND o.link = _domain_name AND e.id <> _uid
      LIMIT 1
      INTO _email_owner_uid;
      IF _email_owner_uid IS NOT NULL THEN
        SET _uid = _email_owner_uid;
      END IF;
    END IF;

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
            is_private_email,
            ctime,
            mtime
          )
          VALUES (
            _uid,
            _provider,
            _provider_user_id,
            _oauth_email,
            _is_private_email,
            UNIX_TIMESTAMP(),
            UNIX_TIMESTAMP()
          )
          ON DUPLICATE KEY UPDATE
            email = _oauth_email,
            is_private_email = _is_private_email,
            mtime = UNIX_TIMESTAMP();
      
      END IF;
    END IF;

    -- STEP 3: Get user profile if found
    IF _uid IS NOT NULL THEN
      SELECT e.id, `profile`, e.db_name, d.email, o.link
      FROM drumate d
      INNER JOIN entity e ON e.id = d.id
      LEFT JOIN organisation o ON o.domain_id = e.dom_id
      WHERE e.id = _uid AND o.link = _domain_name
      INTO _uid, _profile, _db_name, _stored_email, _domain_name;

      -- Keep the OAuth row's address current with what the provider sent this
      -- time (cheap; the row is keyed by provider + provider_user_id).
      IF _oauth_email IS NOT NULL AND _oauth_email <> '' THEN
        UPDATE oauth_accounts
          SET email = _oauth_email,
              is_private_email = _is_private_email,
              mtime = UNIX_TIMESTAMP()
          WHERE user_id = _uid AND provider = _provider;
      END IF;

      -- Relay rotation: when the account's login email is itself an Apple
      -- private-relay address and Apple now hands us a DIFFERENT relay address,
      -- the old one no longer forwards. Migrate the stored login email to the
      -- live relay so OTP / notifications keep reaching the user. Only touches
      -- relay accounts — never a real, user-typed address.
      IF _is_private_email = 1
         AND _oauth_email <> ''
         AND _oauth_email <> _stored_email
         AND _stored_email LIKE '%@privaterelay.appleid.com' THEN
        -- drumate.email is a GENERATED column (json_value(profile,'$.email'));
        -- writing profile is what actually moves it (see drumate_verify_email
        -- for the same fix -- a direct `email = ...` assignment here is
        -- silently ignored / errors under strict sql_mode and never commits).
        UPDATE drumate SET profile = JSON_SET(profile, '$.email', _oauth_email) WHERE id = _uid;
        SET _stored_email = _oauth_email;
      END IF;

      -- Downstream (session row, OTP) uses the resolved login address.
      SET _email = _stored_email;
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

      -- 2FA gate: when the resolved user has email-based 2FA enabled, do NOT
      -- finalize the session here. Leave the cookie in an 'otp_pending' state
      -- and return an 'otp_required' marker so the caller (loby) can mint+email
      -- an OTP and hand off to the signin app's OTP screen, which finalizes the
      -- same pending cookie via session_login_otp. Mirrors the password-login
      -- 2FA path (profile.otp === 'email').
      IF JSON_VALUE(_profile, '$.otp') = 'email' THEN
        UPDATE cookie SET
          failed = 0,
          mtime = UNIX_TIMESTAMP(),
          `uid` = _uid,
          status = 'otp_pending'
        WHERE id = _cid;

        SELECT
          0 AS failed,
          'otp_pending' AS `status`,
          'otp_required' AS error_code,
          _uid AS id,
          _email AS email;
        LEAVE sp_main;
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
        dd.name AS domain,
        dd.id AS domain_id,
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
      INNER JOIN domain dd ON dd.id=e.dom_id
      INNER JOIN (drumate d, cookie c) ON e.id = d.id AND e.id = c.uid 
      WHERE d.id = _uid AND c.id = _cid;
    END IF;
END$$

DELIMITER ;