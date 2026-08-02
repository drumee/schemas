DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_verify_email_token_v2`$
CREATE PROCEDURE `drumate_verify_email_token_v2`(
  IN _token VARCHAR(255),
  IN _cid   VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  DECLARE _id      VARBINARY(16) DEFAULT NULL;
  DECLARE _ctime   INT(11) DEFAULT 0;
  DECLARE _status  VARCHAR(64) DEFAULT NULL;
  DECLARE _profile JSON DEFAULT NULL;
  DECLARE _sid     VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _signed  TINYINT DEFAULT 0;
  DECLARE _email   VARCHAR(500) DEFAULT NULL;
  -- verification.drumate_id is varbinary(16) holding the 16 ASCII characters of
  -- the uid, so _id must NOT be returned directly (the driver would hand the
  -- caller a Buffer, and HEX() would double it to 32 characters). Read the
  -- entity's own varchar id into _uid and return that.
  DECLARE _uid     VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;

  -- v2 of drumate_verify_email_token. The verification half is byte-for-byte the
  -- same as v1; v2 additionally binds the caller's session to the account, so
  -- clicking the link in the signup mail lands the user inside the app instead
  -- of bouncing them to a second sign-in.
  --
  -- Why the token check lives INSIDE this procedure: a bare
  -- "log this cookie in as this uid" primitive would be a standing hazard --
  -- anything that could call it could mint a session for any account. Keeping
  -- the proof here means the only way to obtain a session is to present a
  -- valid, unexpired, unconsumed verification token, which is deliverable only
  -- to that mailbox. Same trust model as session_login_with_oauth (an external
  -- party vouches for the address), and the cookie bind below is deliberately
  -- the identical five-field write that session_signin and
  -- session_login_with_oauth use, ttl included -- session_login_otp omits ttl
  -- because a preceding session_signin already set it, so copying that one
  -- would silently leave the session on the cookie-table default.
  SELECT drumate_id, ctime INTO _id, _ctime
    FROM verification WHERE token = _token LIMIT 1;

  IF _id IS NOT NULL AND (UNIX_TIMESTAMP() - _ctime) <= 86400 THEN
    UPDATE drumate
      SET profile = JSON_SET(profile, "$.email", IFNULL(unverified_email, JSON_VALUE(profile, "$.email"))),
          registration_verified = 1,
          unverified_email = NULL
      WHERE id = _id;
    -- Single use: the row is consumed here, so the link cannot mint a second
    -- session and cannot be replayed from a browser history or a forwarded mail.
    DELETE FROM verification WHERE drumate_id = _id;

    -- Read the account AFTER the update so the returned address is the verified
    -- one. entity.status is the guard that session_login_otp and
    -- session_login_with_oauth both lack: a frozen / archived / locked account
    -- must never be handed a session, even with a valid token.
    SELECT e.id, e.status, d.profile, JSON_VALUE(d.profile, "$.email")
      INTO _uid, _status, _profile, _email
      FROM entity e INNER JOIN drumate d ON d.id = e.id
     WHERE e.id = _id LIMIT 1;

    -- Only bind a cookie row that already exists. An anonymous visitor always
    -- has one (session_check_cookie INSERTs it with uid = nobody_id), so a
    -- missing row means there is no session to attach to and we simply report
    -- the verification.
    SELECT id INTO _sid FROM cookie WHERE id = _cid;

    IF _sid IS NOT NULL AND _status = 'active' THEN
      UPDATE cookie
         SET failed = 0,
             mtime  = UNIX_TIMESTAMP(),
             `uid`  = _uid,
             status = 'ok',
             ttl    = IFNULL(JSON_VALUE(_profile, "$.session_ttl"), 2592000)
       WHERE id = _cid;
      SELECT 1 INTO _signed;
    END IF;

    SELECT 1 AS verified, _signed AS signed_in, _uid AS id, _email AS email;
  ELSE
    -- Unknown, expired or already-consumed token. Identical to v1's answer, with
    -- the two extra columns so the caller can read one stable shape.
    SELECT 0 AS verified, 0 AS signed_in, NULL AS id, NULL AS email;
  END IF;
END$

DELIMITER ;
