DELIMITER $

-- =========================================================
-- organisation_change_ident
-- =========================================================
-- Move an organisation to a new address: <ident>.<main_domain>. The setup
-- wizard's "Custom domain" (B2B Org Structure, Figma 900:149766).
--
-- An organisation's address lives in four places, all rewritten together:
--   domain.name, organisation.ident / link, and every vhost of the domain --
--   the org's own (= link) and each hub / user one, `<label>-<link>` (the
--   DASH rule org_provision, ensure_vhost and drumate_create follow).
-- Host lookup is get_hub -> vhost.fqdn with no cache, and the session cookie
-- is scoped to main_domain(), so the new address works at once and nobody is
-- signed out. The old address stops resolving.
--
-- _dry_run = 1 only answers whether the ident is free (no write): the wizard
-- checks at step 1 and moves at Finish.
--
-- Errors (one row, `error` column): INVALID_IDENT, NO_ORG,
-- IDENT_NOT_AVAILABLE. Format and reserved names are checked by the service.
DROP PROCEDURE IF EXISTS `organisation_change_ident`$
CREATE PROCEDURE `organisation_change_ident`(
  IN _domain_id INT UNSIGNED,
  IN _ident     VARCHAR(80),
  IN _dry_run   TINYINT
)
proc: BEGIN
  DECLARE _old      VARCHAR(80);
  DECLARE _old_host VARCHAR(1024) CHARACTER SET ascii;
  DECLARE _new_host VARCHAR(1024) CHARACTER SET ascii;
  DECLARE _taken    INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET _ident = LOWER(TRIM(_ident));
  IF _ident IS NULL OR _ident = '' OR _ident NOT REGEXP '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' THEN
    SELECT 'INVALID_IDENT' AS error;
    LEAVE proc;
  END IF;

  SELECT ident, link INTO _old, _old_host
    FROM organisation WHERE domain_id = _domain_id LIMIT 1;
  IF _old IS NULL OR _old_host IS NULL THEN
    SELECT 'NO_ORG' AS error;
    LEAVE proc;
  END IF;

  SET _new_host = CONCAT(_ident, '.', main_domain());

  IF _ident = _old THEN
    SELECT _ident AS ident, _old_host AS link, 1 AS available, 0 AS changed;
    LEAVE proc;
  END IF;

  -- Same guards as org_provision, plus: no rewritten vhost may land on a
  -- vhost of another domain.
  SELECT COUNT(*) INTO _taken FROM (
    SELECT id FROM entity       WHERE ident = _ident
    UNION
    SELECT id FROM organisation WHERE ident = _ident AND domain_id != _domain_id
    UNION
    SELECT id FROM vhost        WHERE fqdn = _new_host
    UNION
    SELECT CAST(id AS CHAR(16)) FROM domain WHERE name = _new_host AND id != _domain_id
    UNION
    SELECT o.id FROM vhost v
      INNER JOIN vhost o
        ON o.fqdn = CONCAT(LEFT(v.fqdn, LENGTH(v.fqdn) - LENGTH(_old_host)), _new_host)
       AND o.dom_id != _domain_id
     WHERE v.dom_id = _domain_id
       AND RIGHT(v.fqdn, LENGTH(_old_host) + 1) = CONCAT('-', _old_host)
  ) t;
  IF _taken > 0 THEN
    SELECT 'IDENT_NOT_AVAILABLE' AS error, _ident AS ident;
    LEAVE proc;
  END IF;

  IF _dry_run THEN
    SELECT _ident AS ident, _new_host AS link, 1 AS available, 0 AS changed;
    LEAVE proc;
  END IF;

  START TRANSACTION;

  UPDATE vhost
     SET fqdn = CASE
       WHEN fqdn = _old_host THEN _new_host
       ELSE CONCAT(LEFT(fqdn, LENGTH(fqdn) - LENGTH(_old_host)), _new_host)
     END
   WHERE dom_id = _domain_id
     AND (fqdn = _old_host OR RIGHT(fqdn, LENGTH(_old_host) + 1) = CONCAT('-', _old_host));

  UPDATE domain SET name = _new_host WHERE id = _domain_id;

  UPDATE organisation
     SET ident = _ident,
         link = _new_host,
         metadata = IF(JSON_VALID(metadata),
           JSON_SET(metadata, '$.ident', _ident, '$.link', _new_host),
           metadata)
   WHERE domain_id = _domain_id;

  COMMIT;

  SELECT _ident AS ident, _new_host AS link, _old_host AS old_link, 1 AS available, 1 AS changed;
END$

DELIMITER ;
