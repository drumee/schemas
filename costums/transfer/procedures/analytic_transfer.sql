
DELIMITER $



DROP PROCEDURE IF EXISTS `get_analytic_transfer`$
CREATE PROCEDURE `get_analytic_transfer`(
  IN _nid  varchar(16)
)
BEGIN
  SELECT * FROM analytic_transfer WHERE nid = _nid;
END $

DELIMITER $
DROP PROCEDURE IF EXISTS `update_analytic_transfer`$
CREATE PROCEDURE `update_analytic_transfer`(
  IN _nid  varchar(16),
  IN _value JSON
)
BEGIN
  DECLARE _size  INT;
  DECLARE _receiver INT;
  DECLARE _is_download INT;
  DECLARE _file_count INT;
  DECLARE _download_by JSON;
  DECLARE _metadata JSON;
  DECLARE _receiver_hash JSON DEFAULT '[]';
  DECLARE _sender_hash JSON;

    SELECT get_json_object(_value, "size") INTO _size;
    SELECT get_json_object(_value, "receiver") INTO _receiver;
    SELECT get_json_object(_value, "is_download") INTO _is_download;
    SELECT get_json_object(_value, "download_by") INTO _download_by;
    SELECT get_json_object(_value, "receiver_hash") INTO _receiver_hash;
    SELECT get_json_object(_value, "sender_hash") INTO _sender_hash;
    SELECT get_json_object(_value, "file_count") INTO _file_count;


    IF IFNULL(_is_download,-1) = 0 THEN  
      SELECT JSON_OBJECT(
        'size', _size,
        'receiver',_receiver,
        "sent_at",UNIX_TIMESTAMP(), 
        "download_at", JSON_ARRAY(), 
        "download_by", JSON_ARRAY(), 
        "sender_hash" , IFNULL(_sender_hash, uuid()),
        "receiver_hash",_receiver_hash,
        "file_count", _file_count
      ) INTO _metadata;
      INSERT INTO analytic_transfer (nid,metadata,ctime) VALUES (_nid,_metadata,UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE metadata=_metadata;
    END IF;

    IF IFNULL(_is_download,-1) = 1 THEN  

      UPDATE analytic_transfer 
      SET metadata = JSON_ARRAY_INSERT(metadata, '$.download_at[0]', UNIX_TIMESTAMP())
      WHERE nid = _nid ;
   
      UPDATE analytic_transfer 
      SET metadata = JSON_ARRAY_INSERT(metadata, '$.download_by[0]', _download_by)
      WHERE nid = _nid ;

    END IF;

  SELECT * FROM analytic_transfer WHERE nid = _nid;
END $


DROP PROCEDURE IF EXISTS `analytic_transfer_log`$
CREATE PROCEDURE `analytic_transfer_log`(
  _nid varchar(16),
  _ua TEXT
)
BEGIN
  INSERT INTO analytic_transfer 
    SELECT null, _nid, JSON_OBJECT("page_view", 1, "ua", _ua), UNIX_TIMESTAMP();
  SELECT * FROM analytic_transfer WHERE nid = _nid;
END $

DELIMITER ;