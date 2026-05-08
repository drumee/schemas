DELIMITER $
DROP PROCEDURE IF EXISTS `notification_hub_invites`$
CREATE PROCEDURE `notification_hub_invites`()
BEGIN

  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;

  SELECT
    a.id,
    a.timestamp AS ctime,
    a.uid       AS author_id,
    a.target_uid,
    a.event,
    a.data,
    d.firstname AS inviter_firstname,
    d.lastname  AS inviter_lastname,
    d.email     AS inviter_email,
    e.headline  AS hub_headline,
    e.ident     AS hub_ident
  FROM yp.contact_activity a
  LEFT JOIN yp.drumate d ON d.id = a.uid
  LEFT JOIN yp.entity  e
         ON e.id = JSON_UNQUOTE(JSON_EXTRACT(a.data, '$.hub_id'))
  WHERE a.target_uid    = _uid
    AND a.event         = 'hub_invite_received'
    AND a.dismissed_at IS NULL
  ORDER BY a.timestamp DESC
  LIMIT 50;

END$
DELIMITER ;
