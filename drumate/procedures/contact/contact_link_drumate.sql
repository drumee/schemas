DELIMITER $

DROP PROCEDURE IF EXISTS `contact_link_drumate`$
CREATE PROCEDURE `contact_link_drumate`(
  IN _contact_id VARCHAR(16),
  IN _uid VARCHAR(16)
)
BEGIN
  -- Point one contact row at a Drumee account and leave it 'informed', the
  -- state contact_invite_informed then advances to 'active' (refreshing auto
  -- names and the contact_block mapping). Used by contact.accept_invite: the
  -- inviter's row of a "Join Drumee" invitation is keyed by the invited email.
  UPDATE contact
    SET entity = _uid, uid = _uid, category = 'drumate', status = 'informed',
        mtime = UNIX_TIMESTAMP()
  WHERE id = _contact_id;
  SELECT * FROM contact WHERE id = _contact_id;
END$

DELIMITER ;
