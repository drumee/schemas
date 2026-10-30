DELIMITER $

DROP PROCEDURE IF EXISTS `mkt_offer_pending_set`$
CREATE PROCEDURE `mkt_offer_pending_set`(
  IN _uid  VARCHAR(16),
  IN _code VARCHAR(64)
)
BEGIN
  -- Hold an offer code from a signup link (?offer=CODE) for this account
  -- until checkout. Only a live code is kept; an unknown, disabled or expired
  -- one is ignored rather than stored, and the answer says which.
  DECLARE _norm VARCHAR(64);
  DECLARE _cid INT UNSIGNED;
  DECLARE _now INT UNSIGNED;

  SET _now = UNIX_TIMESTAMP();
  SET _norm = UPPER(TRIM(IFNULL(_code, '')));

  SELECT id INTO _cid FROM mkt_coupon
   WHERE code = _norm AND active = 1
     AND (ends_at IS NULL OR ends_at = 0 OR ends_at >= _now)
   LIMIT 1;

  IF IFNULL(_uid, '') = '' OR _cid IS NULL THEN
    SELECT 'OFFER_NOT_AVAILABLE' AS error, _norm AS code;
  ELSE
    INSERT INTO mkt_offer_pending (uid, code, ctime, mtime)
    VALUES (_uid, _norm, _now, _now)
    ON DUPLICATE KEY UPDATE code = _norm, mtime = _now;
    SELECT uid, code FROM mkt_offer_pending WHERE uid = _uid;
  END IF;
END$

DELIMITER ;
