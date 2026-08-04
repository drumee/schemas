DELIMITER $

-- =========================================================
-- mkt_coupon_redemptions
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_redemptions`$
CREATE PROCEDURE `mkt_coupon_redemptions`(
  IN _coupon_id INT,
  IN _code      VARCHAR(64),
  IN _status    VARCHAR(16),
  IN _q         VARCHAR(128),
  IN _page      INT
)
BEGIN
  DECLARE _offset INT DEFAULT 0;
  DECLARE _range INT DEFAULT 50;
  IF IFNULL(_page, 0) < 1 THEN SET _page = 1; END IF;
  SET _offset = (_page - 1) * _range;

  SELECT r.*
  FROM mkt_coupon_redemption r
  WHERE (IFNULL(_coupon_id, 0) = 0 OR r.coupon_id = _coupon_id)
    AND (IFNULL(_code, '') = '' OR r.code = UPPER(TRIM(_code)))
    AND (IFNULL(_status, '') = '' OR r.status = _status)
    AND (IFNULL(_q, '') = ''
         OR r.email LIKE CONCAT('%', _q, '%')
         OR r.partner LIKE CONCAT('%', _q, '%')
         OR r.uid = _q)
  ORDER BY r.ctime DESC
  LIMIT _offset, _range;
END $

DELIMITER ;
