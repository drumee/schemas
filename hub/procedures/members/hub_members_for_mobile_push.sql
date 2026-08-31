DELIMITER $

DROP PROCEDURE IF EXISTS `hub_members_for_mobile_push`$
CREATE PROCEDURE `hub_members_for_mobile_push`(
  IN _page INT UNSIGNED,
  IN _range INT UNSIGNED
)
BEGIN
  DECLARE _bounded_page INT UNSIGNED DEFAULT 1;
  DECLARE _bounded_range INT UNSIGNED DEFAULT 45;
  DECLARE _offset BIGINT UNSIGNED DEFAULT 0;

  SET _bounded_page = GREATEST(IFNULL(_page, 1), 1);
  SET _bounded_range = LEAST(GREATEST(IFNULL(_range, 45), 1), 45);
  SET _offset = (_bounded_page - 1) * _bounded_range;

  SELECT entity_id AS id,
    permission AS privilege,
    expiry_time AS expiry
  FROM permission
  WHERE resource_id = '*'
  ORDER BY entity_id
  LIMIT _offset, _bounded_range;
END$

DELIMITER ;
