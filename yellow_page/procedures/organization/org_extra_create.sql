DELIMITER $

-- =========================================================
-- org_extra_create
-- =========================================================
-- "+ New organization" (Figma 900:150993, Business plan): create one more
-- organisation for a person WITHOUT moving them. The org rows are the ones
-- org_provision writes (domain, organisation from a clean pool entity, the
-- org hub, its vhost, a quota row), minus everything that would move the
-- person or their hubs:
--   - no domain_grant: their privilege row / drumate.domain_id stay on their
--     first organisation; their standing here is a 63 row in org_membership;
--   - organisation.owner_id is NULL (UNIQUE, already used by their first
--     organisation); the owner is in org_extra and the metadata;
--   - the quota row copies the creator's current plan (get_quota).
-- org_extra keeps the pool entity's previous columns for org_extra_delete.
--
-- Plan gating and the ident format are the service's; this re-checks that
-- the ident is free. Errors: IDENT_NOT_AVAILABLE, NO_POOL_ENTITY.
DROP PROCEDURE IF EXISTS `org_extra_create`$
CREATE PROCEDURE `org_extra_create`(
  IN _uid   VARCHAR(16),
  IN _name  VARCHAR(512),
  IN _ident VARCHAR(80)
)
proc: BEGIN
  DECLARE _domain_id INT;
  DECLARE _host      VARCHAR(1024) CHARACTER SET ascii;
  DECLARE _org_id    VARCHAR(16) CHARACTER SET ascii;
  DECLARE _prev      LONGTEXT;
  DECLARE _quota     LONGTEXT;
  DECLARE _taken     INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET _ident = LOWER(TRIM(_ident));
  SET _host = CONCAT(_ident, '.', main_domain());

  SELECT COUNT(*) INTO _taken FROM (
    SELECT id FROM entity       WHERE ident = _ident
    UNION
    SELECT id FROM organisation WHERE ident = _ident
    UNION
    SELECT id FROM vhost        WHERE fqdn = _host
    UNION
    SELECT CAST(id AS CHAR(16)) FROM domain WHERE name = _host
  ) t;
  IF _taken > 0 THEN
    SELECT 'IDENT_NOT_AVAILABLE' AS error, _ident AS ident;
    LEAVE proc;
  END IF;

  SELECT JSON_REMOVE(get_quota(_uid), '$.domain_id', '$.category', '$.storage') INTO _quota;

  START TRANSACTION;

  SELECT id FROM entity
   WHERE `type` = 'hub' AND area = 'pool'
     AND JSON_VALUE(settings, "$.pool_state") = "clean"
   LIMIT 1 FOR UPDATE
  INTO _org_id;
  IF _org_id IS NULL THEN
    ROLLBACK;
    SELECT 'NO_POOL_ENTITY' AS error;
    LEAVE proc;
  END IF;

  SELECT JSON_OBJECT('area', area, 'type', `type`, 'status', status,
                     'dom_id', dom_id, 'homepage', homepage)
    INTO _prev FROM entity WHERE id = _org_id;

  INSERT INTO domain (name) VALUES (_host);
  SELECT id INTO _domain_id FROM domain WHERE name = _host;

  INSERT INTO organisation (`id`, `domain_id`, `name`, `link`, `ident`, `owner_id`, `metadata`)
  VALUES (
    _org_id, _domain_id, _name, _host, _ident, NULL,
    JSON_OBJECT('ident', _ident, 'name', _name, 'link', _host,
                'domain_id', _domain_id, 'owner_uid', _uid, 'extra', 1)
  );

  UPDATE entity SET
    `area` = 'public', `dom_id` = _domain_id, `type` = 'organization',
    `status` = 'active', `homepage` = ""
  WHERE id = _org_id;

  INSERT INTO hub (`id`, `owner_id`, `origin_id`, `name`, `serial`, `hubname`, `domain_id`, `profile`)
  SELECT _org_id, _uid, _uid, _host, 9999999, NULL, _domain_id, NULL;

  INSERT INTO vhost (`fqdn`, `id`, `dom_id`) VALUES (_host, _org_id, _domain_id);

  INSERT INTO quota (domain_id, payer_id, plan, quota, source, ctime, mtime)
  VALUES (_domain_id, _org_id, IFNULL(JSON_VALUE(_quota, '$.plan'), 'free'), _quota,
          'extra_org', UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

  INSERT INTO org_membership (uid, domain_id, privilege, by_id, ctime)
  VALUES (_uid, _domain_id, 63, _uid, UNIX_TIMESTAMP());

  INSERT INTO org_extra (domain_id, org_id, owner_uid, prev_entity, ctime)
  VALUES (_domain_id, _org_id, _uid, _prev, UNIX_TIMESTAMP());

  COMMIT;

  SELECT o.id AS org_id, o.domain_id, o.name, o.link, o.ident, 63 AS privilege
    FROM organisation o WHERE o.domain_id = _domain_id;
END$

DELIMITER ;
