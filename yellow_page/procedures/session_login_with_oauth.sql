DELIMITER $$

DROP PROCEDURE IF EXISTS yp.session_login_with_oauth$$

CREATE PROCEDURE yp.session_login_with_oauth(
    IN _provider VARCHAR(20) CHARACTER SET ascii,
    IN _provider_user_id VARCHAR(255) CHARACTER SET ascii,
    IN _email VARCHAR(500), 
    
    IN _cid VARCHAR(64) CHARACTER SET ascii, -- Session ID
    IN _domain_name VARCHAR(1000)
)
BEGIN
    DECLARE _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL;
    DECLARE _profile JSON DEFAULT "{}";
    DECLARE _sid VARCHAR(64) CHARACTER SET ascii;
    DECLARE _db_name VARCHAR(52) DEFAULT '0';
    DECLARE _ctime INT(11); 
    DECLARE _dom_id INT(8);
    DECLARE _secret VARCHAR(500);
    DECLARE _mimicker VARCHAR(64);
    DECLARE _mimic_id VARCHAR(16);
    DECLARE _mimic_type VARCHAR(30) DEFAULT 'normal';
    DECLARE _mimic_entity JSON;

    SELECT IFNULL(domain_id, 1) 
    FROM yp.organisation 
    WHERE link = _domain_name OR domain_id = _domain_name
    INTO _dom_id;

    SELECT oa.user_id 
    FROM yp.oauth_accounts oa
    WHERE oa.provider = _provider AND oa.provider_user_id = _provider_user_id
    INTO _uid;

    IF _uid IS NULL THEN
        SELECT e.id 
        FROM yp.drumate d
        INNER JOIN yp.entity e ON e.id = d.id  
        LEFT JOIN yp.organisation o ON o.domain_id = e.dom_id
        WHERE d.email = _email AND o.link = _domain_name
        INTO _uid;
        
        IF _uid IS NOT NULL THEN
            INSERT INTO yp.oauth_accounts (user_id, provider, provider_user_id, email, ctime, mtime)
            VALUES (_uid, _provider, _provider_user_id, _email, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
            ON DUPLICATE KEY UPDATE 
                mtime = UNIX_TIMESTAMP();
        END IF;
    END IF;

    IF _uid IS NOT NULL THEN
        SELECT e.id, `profile`, db_name, d.email, o.link 
        FROM yp.drumate d 
        INNER JOIN yp.entity e ON e.id = d.id  
        LEFT JOIN yp.organisation o ON o.domain_id = e.dom_id
        WHERE e.id = _uid AND o.link = _domain_name
        INTO _uid, _profile, _db_name, _email, _domain_name;
    END IF;

    SELECT secret FROM yp.token WHERE email = _email AND method = 'signup' 
    ORDER BY ctime DESC LIMIT 1 INTO _secret;

    IF _uid IS NULL THEN 
        UPDATE yp.cookie SET failed = failed + 1, `status` = 'oauth_user_not_found' 
        WHERE id = _cid;
        
        SELECT failed, `status`, 'oauth_user_not_found' AS error_code 
        FROM yp.cookie 
        WHERE id = _cid;
    ELSE
        SELECT id FROM yp.cookie WHERE id = _cid INTO _sid;
        IF _sid IS NULL THEN 
            SELECT _cid INTO _sid;
            SELECT UNIX_TIMESTAMP() INTO _ctime;
            INSERT INTO yp.cookie (`id`,`uid`,`ctime`,`mtime`,`ua`, `status`)
            VALUES(_sid, _uid, _ctime, _ctime, 'oauth_login', 'new');
        END IF;
        
        SELECT 'victim' ,mimicker, id FROM yp.mimic WHERE status = 'active' AND uid = _uid INTO  _mimic_type , _mimicker, _mimic_id ;
        SELECT 'old', mimicker, id  FROM yp.mimic WHERE status = 'active' AND mimicker = _uid  INTO  _mimic_type , _mimicker, _mimic_id;
        SELECT 'mimc', m.mimicker, m.id  FROM yp.mimic m
        INNER JOIN yp.cookie c ON  m.uid = c.uid AND m.mimicker = c.mimicker 
        WHERE   m.status ='active' AND  c.id = _sid AND c.uid = _uid   INTO _mimic_type ,_mimicker, _mimic_id;

        IF _mimic_type = 'old' THEN 
            UPDATE yp.mimic SET status = 'endbytime'  WHERE id = _mimic_id;
            UPDATE yp.mimic SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('endbytime',  UNIX_TIMESTAMP())) WHERE id=_mimic_id;
            UPDATE yp.cookie SET uid=_mimicker , mimicker=null WHERE mimicker=_mimicker ;
            SELECT 'normal' INTO _mimic_type; 
        END IF;
        
        UPDATE yp.cookie SET 
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
            mimicker,
            _mimic_id mimic_id,
            _mimic_type mimc_type,
            area,
            area_id as aid,
            e.status AS `condition`,
            e.mtime,
            e.ctime,
            _profile AS `profile`,
            _secret `secret`,
            _provider AS oauth_provider 
        FROM yp.entity e INNER JOIN (yp.drumate d, yp.cookie c) ON e.id = d.id AND e.id = c.uid 
        WHERE d.id = _uid AND c.id = _cid;
    END IF;
END$$

DELIMITER ;