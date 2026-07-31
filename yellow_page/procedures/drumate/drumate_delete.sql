DELIMITER $


DROP PROCEDURE IF EXISTS `drumate_delete`$
CREATE PROCEDURE `drumate_delete`(
 IN _key VARBINARY(80)
)
BEGIN
  DECLARE _domain_id INT(4);
  DECLARE _id VARCHAR(16);
  DECLARE _ident VARBINARY(80);
  DECLARE _type VARCHAR(80);
  DECLARE _db VARCHAR(80);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _entity_db VARCHAR(20);
  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _drumate_id VARCHAR(16);
  DECLARE _drumate_domain_id INT(4);
  DECLARE _drumate_db VARCHAR(100);
  DECLARE _email VARCHAR(1000);
  DECLARE _real_email VARCHAR(1000);
  DECLARE _rid VARCHAR(16) ;

  DECLARE _src_db_name VARCHAR(100);

  SELECT id, ident,`type`, db_name, home_dir FROM entity
  WHERE  id=_key INTO _id, _ident, _type, _db, _home_dir;

  -- -- To get source sharebox db 
  -- SELECT db_name FROM yp.entity WHERE id=(SELECT sb.id FROM yp.hub sb 
  -- INNER JOIN yp.entity e ON e.id = sb.id WHERE sb.owner_id =_id AND  e.area='restricted'  ) INTO _src_db_name;   

  SELECT email, JSON_VALUE(`profile`, '$.old_email')
    FROM drumate WHERE id = _id INTO _email, _real_email;
  -- An account retired by the legacy freeze-based delete carries its true
  -- address in profile.old_email; `email` itself was rewritten to
  -- '<uid>/<address>' to release the UNIQUE key. Purge on both so the backlog
  -- of already-frozen accounts cleans up through the same path as a fresh one.
  SELECT COALESCE(NULLIF(_real_email, ''), _email) INTO _real_email;
  SELECT domain_id FROM privilege WHERE uid = _id INTO _domain_id;



  /* Clear refrences contact manager */

  SELECT 0 INTO _sys_id; 
  SELECT sys_id  FROM drumate WHERE sys_id > 0  ORDER BY sys_id ASC LIMIT 1 INTO _sys_id;
 
  WHILE _sys_id <> 0 DO
     
    SELECT NULL,NULL,NULL INTO _drumate_id,_drumate_domain_id,_drumate_db;
    SELECT id  FROM  drumate WHERE sys_id = _sys_id INTO _drumate_id; 
    SELECT domain_id FROM privilege WHERE uid = _drumate_id  ORDER BY domain_id DESC  LIMIT 1  INTO _drumate_domain_id;
    SELECT db_name FROM entity WHERE status <> 'deleted' AND id = _drumate_id INTO _drumate_db;


    IF ( _drumate_id IS NOT NULL AND _drumate_domain_id IS NOT NULL AND _drumate_db IS NOT NULL) THEN
      IF (_drumate_domain_id = _domain_id) THEN   -- SAME domain  user
        SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact_email WHERE contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _id,_id,_email,_email;
        DEALLOCATE PREPARE stamt;

        SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _id,_id,_email,_email;
        DEALLOCATE PREPARE stamt; 
      END IF ;
      IF (_drumate_domain_id <> _domain_id) THEN    -- cross domain user
        SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact WHERE (uid =? or entity = ? or uid = ? or entity =?) AND status="received"');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _id,_id,_email,_email;
        DEALLOCATE PREPARE stamt; 

        SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact_email SET  is_default = 0 WHERE   is_default = 1 AND contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _id,_id,_email,_email;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact_email WHERE  email =? AND contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _email,_id,_id,_email,_email;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('INSERT INTO ', _drumate_db ,'.contact_email (id,email,category,ctime,mtime ,contact_id ,is_default )
        SELECT  yp.uniqueId(),?,"priv",UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),id,1 FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? 
        ON DUPLICATE KEY UPDATE is_default =1');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _email,_id,_id,_email,_email;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact SET category ="independant", metadata = JSON_OBJECT("source",? ), status="memory", uid = null, entity=? WHERE uid =? or entity =? or uid = ? or entity =?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING  _email,_email,_id,_id,_email,_email;
        DEALLOCATE PREPARE stamt; 
      END IF;  
    END IF; 

    SELECT _sys_id INTO  _temp_sys_id ;  
    SELECT 0 INTO  _sys_id ; 
    SELECT IFNULL(sys_id,0)  FROM drumate WHERE sys_id >_temp_sys_id ORDER BY sys_id ASC  LIMIT 1 INTO _sys_id;
  END WHILE;

  INSERT INTO trash.entity SELECT * FROM yp.entity WHERE id=_id;
  INSERT INTO trash.drumate (sys_id, id, username, domain_id, remit,  `profile`) 
    SELECT sys_id, id, username, domain_id, remit, `profile` 
    FROM yp.drumate WHERE id=_id;
  INSERT INTO trash.vhost SELECT * FROM yp.vhost  WHERE id=_id;
  INSERT INTO trash.privilege SELECT * FROM yp.privilege WHERE uid=_id;

  -- =====================================================================
  -- Purge every row still keyed to this drumate.
  --
  -- Only entity/drumate/vhost/privilege/cookie used to be cleared, which left
  -- the account's credentials behind: an `oauth_accounts` row outlives the
  -- account, and session_login_with_oauth resolves on provider_user_id BEFORE
  -- it ever looks at the address, so a Google/Apple re-signup would keep
  -- resolving to the dead id instead of falling through to the signup branch.
  -- The surviving row also re-binds the caller's cookie to the dead account on
  -- every attempt, which is what locked a deleted user out of the whole site.
  -- Authentication state first, so a failure in the bulk deletes below can
  -- never leave a still-usable credential behind.
  -- =====================================================================
  DELETE FROM oauth_accounts WHERE user_id = _id;
  DELETE FROM socket_active WHERE id IN (SELECT id FROM socket WHERE `uid` = _id);
  DELETE FROM socket WHERE `uid` = _id;
  DELETE FROM authn WHERE id = _id;
  DELETE FROM otp WHERE `uid` = _id;
  DELETE FROM secret WHERE `uid` = _id;
  DELETE FROM verification WHERE drumate_id = _id;
  DELETE FROM device WHERE `uid` = _id;
  DELETE FROM device_registation WHERE `uid` = _id;
  DELETE FROM mfs_token WHERE user_id = _id;
  DELETE FROM mfs_authorized_node WHERE `uid` = _id;
  DELETE FROM public_key WHERE user_id = _id;
  DELETE FROM pseudo_entity WHERE `uid` = _id;
  DELETE FROM mimic WHERE id = _id OR `uid` = _id OR mimicker = _id;

  /* Entity-scoped rows that entity_delete has always cleared for a hub but
     drumate_delete never did for a drumate. */
  DELETE FROM disk_usage WHERE hub_id = _id;
  DELETE FROM corporate WHERE entity_id = _id;
  DELETE FROM share_box WHERE owner_id = _id;
  DELETE FROM dmz_token WHERE hub_id = _id;
  DELETE FROM map_role WHERE `uid` = _id;

  /* The account's own rows. Scoped to what this account OWNS: a notification is
     a message sitting in somebody's inbox, so only the ones addressed to this
     account go. The contact_* tables are two-sided relationship rows that mean
     nothing once either side is gone, and the loop above already scrubs this
     account out of everyone else's address book, so both sides go there.

     Deliberately NOT touched, because these rows are read by OTHER people and
     removing them would change what those people see:
       - yp.mfs_changelog  -- changelog_read joins it against _user_hubs to build
                              the activity feed of every SHARED workspace, and
                              mfs_show_node_by reads it for unread/new badges.
                              Dropping a departing member's rows would rewrite
                              teammates' feeds and badge state, and wipe the
                              hub audit trail get_hub_audit_logs serves.
       - yp.services_log   -- security/API audit trail; retention is a policy
                              call for Somanos, not something to destroy here.
       - yp.meeting_schedule -- a meeting created in a shared hub is that hub's
                              calendar entry for its other attendees.
       - yp.subscription / stripe_event -- billing history needed for accounting
                              and Stripe reconciliation. */
  DELETE FROM reminder WHERE `uid` = _id;
  DELETE FROM notification WHERE owner_id = _id;
  DELETE FROM contact_activity WHERE `uid` = _id OR target_uid = _id;
  DELETE FROM contact_block WHERE owner_id = _id OR `uid` = _id;
  DELETE FROM contact_sync WHERE owner_id = _id OR `uid` = _id;
  DELETE FROM survey_response WHERE `uid` = _id;
  DELETE FROM reward_claim WHERE `uid` = _id;

  /* Shares this account created. Rows describing it as the RECIPIENT of
     somebody else's share are left alone -- they belong to that creator, and
     removing them would silently revoke a share nobody asked to revoke. */
  DELETE FROM secure_share_access_event WHERE actor_id = _id;
  DELETE FROM secure_share_access_request WHERE creator_id = _id;
  DELETE FROM secure_share_token WHERE creator_id = _id;

  /* Address-keyed rows. Releasing these is what lets the same person sign up
     again from scratch. Guarded on a non-empty address so a malformed profile
     can never turn these into unfiltered deletes. */
  IF _real_email IS NOT NULL AND _real_email <> '' THEN
    DELETE FROM dmz_token WHERE guest_id IN (SELECT id FROM dmz_user WHERE email = _real_email);
    DELETE FROM dmz_user WHERE email = _real_email;
    DELETE FROM pending_invitation WHERE email = _real_email;
    DELETE FROM token WHERE email = _real_email;
    DELETE FROM emailing WHERE email = _real_email;
    DELETE FROM emailing_cc WHERE email = _real_email;
  END IF;
  DELETE FROM token WHERE inviter_id = _id;

  DELETE FROM privilege WHERE uid = _id;
  DELETE FROM vhost WHERE id = _id;
  DELETE FROM drumate WHERE id = _id;
  DELETE FROM entity WHERE id = _id;
  DELETE FROM cookie WHERE uid=_id;

  -- `OR` here read as "always true when db_name is set", so an empty db_name
  -- would have reached DROP DATABASE `` and raised a syntax error. No row
  -- carries one today, but this path is now reachable from a user-initiated
  -- delete. Matches entity_delete's guard.
  IF _db IS NOT NULL AND _db != "" THEN
    SET @s = CONCAT("DROP DATABASE IF EXISTS `", _db, "`");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  SELECT _id id, _ident ident, _type type, _db db_name, _home_dir home_dir;

END$



DELIMITER ;
