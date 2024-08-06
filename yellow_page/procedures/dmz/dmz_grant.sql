DELIMITER $
--  DROP PROCEDURE IF EXISTS `dmz_grant`$
DROP PROCEDURE IF EXISTS `dmz_grant_next`$
CREATE PROCEDURE `dmz_grant_next`(
  IN _hub_id    VARCHAR(16) CHARACTER SET ascii,
  IN _node_id   VARCHAR(16) CHARACTER SET ascii,
  IN _guest_id  VARCHAR(64) CHARACTER SET ascii,
  IN _token     VARCHAR(64) ,
  IN _pw        VARCHAR(250)
)
BEGIN
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _is_sync int(4) DEFAULT 0;
  DECLARE _fingerprint VARCHAR(250) DEFAULT NULL;

  SELECT id,notify_at ,is_sync
    FROM dmz_token 
    WHERE hub_id=_hub_id AND node_id=_node_id AND guest_id=_guest_id
  INTO _token,_ts,_is_sync;

  IF _pw <> '' THEN 
    SELECT sha2(_pw, 512) INTO _fingerprint;
  END IF;

  REPLACE dmz_token (hub_id, node_id, guest_id, id, fingerprint, notify_at, is_sync) 
    SELECT _hub_id, _node_id, _guest_id, _token, _fingerprint, _ts, _is_sync;
     

  SELECT t.hub_id, node_id, guest_id, t.id token
    FROM dmz_token t 
    INNER JOIN dmz_user u on u.id=t.guest_id
    WHERE t.id = _token
  UNION 
  SELECT t.hub_id, node_id, guest_id, t.id token
    FROM dmz_token t 
    INNER JOIN dmz_media u on u.id=t.guest_id
    WHERE t.id = _token;

END$
