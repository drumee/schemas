DELIMITER $

DROP PROCEDURE IF EXISTS `notification_contact_refused`$

CREATE PROCEDURE `notification_contact_refused`()
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;

  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();

  SELECT
    a.id,
    a.timestamp     AS ctime,
    a.uid           AS author_id,
    d.firstname,
    d.lastname,
    d.email
  FROM yp.contact_activity a
  INNER JOIN (
    SELECT MAX(a2.id) AS id
      FROM yp.contact_activity a2
     WHERE a2.target_uid = _uid
       AND a2.event = 'invite_refused'
       AND a2.dismissed_at IS NULL
     GROUP BY a2.uid
  ) keep ON keep.id = a.id
  LEFT JOIN yp.drumate d ON d.id = a.uid
  ORDER BY a.timestamp DESC
  LIMIT 50;
END$

DELIMITER ;
