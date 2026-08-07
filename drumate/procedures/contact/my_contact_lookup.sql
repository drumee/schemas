DELIMITER $

-- =========================================================
-- my_contact_lookup
--
-- Type-ahead lookup over the caller's address book for the
-- workspace-invite pickers.
--
-- Unlike `my_contact` / `contact_search_next`, which match the
-- typed string against name columns ONLY, this matches against
-- EVERY email a contact holds:
--   * all `contact_email` rows (not just is_default = 1),
--   * the contact's `entity` when it is an email,
--   * the linked drumate's account email,
-- and still matches the name columns so typing a name keeps working.
--
-- Emits ONE ROW PER MATCHING EMAIL (a contact with a work and a
-- private address that both match yields two rows), because the
-- caller is picking an address to invite, not a person.
--
-- _key          typed string; '' (or '%') means "no filter" — list
--               the whole address book, paged.
-- _filter_email JSON array of addresses to exclude (chips already
--               picked by the caller).
-- _only_drumate 1 = keep only contacts that resolve to a drumate.
-- _page         1-based; page size comes from pageToLimits.
--
-- Ranking: 0 exact email, 1 email prefix, 2 email substring,
--          3 name-only match. Ties break on surname, then email.
-- =========================================================
DROP PROCEDURE IF EXISTS `my_contact_lookup`$
CREATE PROCEDURE `my_contact_lookup`(
  IN _key          VARCHAR(255),
  IN _filter_email JSON,
  IN _only_drumate TINYINT,
  IN _page         INT(6)
)
BEGIN
  DECLARE _domain_id INTEGER;
  DECLARE _range     BIGINT;
  DECLARE _offset    BIGINT;
  DECLARE _uid       VARCHAR(16);
  DECLARE _mail      VARCHAR(500);
  DECLARE _needle    VARCHAR(255);
  DECLARE _cap       BIGINT;
  DECLARE _length    INTEGER DEFAULT 0;
  DECLARE _idx       INTEGER DEFAULT 0;

  -- A trailing '%' is how the legacy callers spelled "prefix search";
  -- this proc owns its own wildcards, so strip any the caller sent.
  SELECT LOWER(TRIM(REPLACE(IFNULL(_key, ''), '%', ''))) INTO _needle;
  SELECT IFNULL(_only_drumate, 0) INTO _only_drumate;

  SELECT e.dom_id, d.id, d.email
    FROM yp.entity e INNER JOIN yp.drumate d USING(id)
    WHERE e.db_name = DATABASE()
    INTO _domain_id, _uid, _mail;

  CALL pageToLimits(_page, _offset, _range);

  -- Each branch below contributes at most the rows the requested page can
  -- reach, best-ranked first. Without this an empty key (the "browse the
  -- address book" case) would materialize every contact on every keystroke
  -- just to return twenty of them.
  SELECT _offset + _range INTO _cap;

  -- ── Addresses the caller already picked ────────────────────
  DROP TABLE IF EXISTS _lookup_filter;
  CREATE TEMPORARY TABLE `_lookup_filter` (
    `email` VARCHAR(255) NOT NULL
  );

  SELECT JSON_LENGTH(_filter_email) INTO _length;
  WHILE _idx < IFNULL(_length, 0) DO
    INSERT INTO _lookup_filter
      SELECT LOWER(TRIM(JSON_UNQUOTE(JSON_EXTRACT(_filter_email, CONCAT('$[', _idx, ']')))));
    SELECT _idx + 1 INTO _idx;
  END WHILE;

  -- ── Result accumulator ─────────────────────────────────────
  -- UNIQUE(email) + INSERT IGNORE deduplicates: the same address
  -- reached through several joins keeps its best-ranked row.
  DROP TABLE IF EXISTS _lookup;
  CREATE TEMPORARY TABLE `_lookup` (
    `match_rank`    TINYINT      NOT NULL DEFAULT 3,
    `page`          INT(6),
    `is_mycontact`  TINYINT      NOT NULL DEFAULT 1,
    `id`            VARCHAR(255),
    `contact_id`    VARCHAR(16),
    `email`         VARCHAR(255) NOT NULL,
    `firstname`     VARCHAR(255),
    `lastname`      VARCHAR(255),
    `fullname`      VARCHAR(512),
    `surname`       VARCHAR(255),
    `category`      VARCHAR(16),
    `is_drumate`    TINYINT      NOT NULL DEFAULT 0,
    `is_need_email` TINYINT      NOT NULL DEFAULT 0,
    `status`        VARCHAR(20),
    `is_blocked`    TINYINT      NOT NULL DEFAULT 0,
    `is_blocked_me` TINYINT      NOT NULL DEFAULT 0,
    UNIQUE KEY `uk_email` (`email`)
  );

  -- 1. Every address in contact_email (work, private, secondary…).
  INSERT IGNORE INTO _lookup (
    match_rank, `page`, is_mycontact, id, contact_id, email,
    firstname, lastname, fullname, surname, category,
    is_drumate, is_need_email, `status`, is_blocked, is_blocked_me
  )
  SELECT
    CASE
      WHEN _needle = ''                                              THEN 3
      WHEN LOWER(TRIM(ce.email)) = _needle                           THEN 0
      WHEN LOWER(TRIM(ce.email)) LIKE CONCAT(_needle, '%')           THEN 1
      WHEN LOWER(TRIM(ce.email)) LIKE CONCAT('%', _needle, '%')      THEN 2
      ELSE 3
    END AS match_rank,
    _page,
    1,
    COALESCE(du.id, de.id, dm.id, c.entity, LOWER(TRIM(ce.email))),
    c.id,
    LOWER(TRIM(ce.email)),
    c.firstname,
    c.lastname,
    NULLIF(TRIM(CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))), ''),
    IFNULL(c.surname, NULLIF(TRIM(CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))), '')),
    ce.category,
    CASE WHEN COALESCE(du.id, de.id, dm.id) IS NULL THEN 0 ELSE 1 END,
    CASE WHEN du.id IS NULL THEN 1 ELSE 0 END,
    c.`status`,
    CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END
  FROM contact c
    INNER JOIN contact_email ce
      ON ce.contact_id = c.id AND ce.email IS NOT NULL AND TRIM(ce.email) <> ''
    LEFT JOIN yp.drumate de ON de.id = c.entity
    LEFT JOIN yp.drumate du ON du.id = c.uid
    LEFT JOIN yp.drumate dm ON dm.email = ce.email
    LEFT JOIN yp.contact_block mycb ON mycb.contact_id = c.id
    LEFT JOIN yp.contact_block hiscb
      ON (hiscb.owner_id = c.entity OR hiscb.owner_id = dm.id)
     AND (hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail)
    LEFT JOIN archive_entity ae ON ae.entity_id = c.id
  WHERE
    c.`status` <> 'received'
    AND ae.entity_id IS NULL
    AND LOWER(TRIM(ce.email)) <> LOWER(TRIM(IFNULL(_mail, '')))
    AND LOWER(TRIM(ce.email)) NOT IN (SELECT email FROM _lookup_filter)
    AND (
      _needle = ''
      OR LOWER(TRIM(ce.email)) LIKE CONCAT('%', _needle, '%')
      OR LOWER(c.firstname)    LIKE CONCAT(_needle, '%')
      OR LOWER(c.lastname)     LIKE CONCAT(_needle, '%')
      OR LOWER(c.surname)      LIKE CONCAT(_needle, '%')
    )
    AND (_only_drumate = 0 OR COALESCE(du.id, de.id, dm.id) IS NOT NULL)
  ORDER BY match_rank ASC, ce.is_default DESC
  LIMIT _cap;

  -- 2. Contacts whose address lives on the row itself — `entity` when
  --    it is an email, or the linked drumate's account email. Covers
  --    contacts created from an invite, which have no contact_email row.
  INSERT IGNORE INTO _lookup (
    match_rank, `page`, is_mycontact, id, contact_id, email,
    firstname, lastname, fullname, surname, category,
    is_drumate, is_need_email, `status`, is_blocked, is_blocked_me
  )
  SELECT
    CASE
      WHEN _needle = ''                                                   THEN 3
      WHEN LOWER(TRIM(c._email)) = _needle                                  THEN 0
      WHEN LOWER(TRIM(c._email)) LIKE CONCAT(_needle, '%')                  THEN 1
      WHEN LOWER(TRIM(c._email)) LIKE CONCAT('%', _needle, '%')             THEN 2
      ELSE 3
    END AS match_rank,
    _page,
    1,
    COALESCE(du.id, de.id, c.entity, LOWER(TRIM(c._email))),
    c.id,
    LOWER(TRIM(c._email)),
    c.firstname,
    c.lastname,
    NULLIF(TRIM(CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))), ''),
    IFNULL(c.surname, NULLIF(TRIM(CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))), '')),
    NULL,
    CASE WHEN COALESCE(du.id, de.id) IS NULL THEN 0 ELSE 1 END,
    CASE WHEN du.id IS NULL THEN 1 ELSE 0 END,
    c.`status`,
    CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END,
    0
  FROM (
    SELECT
      c.*,
      COALESCE(du2.email, de2.email, IF(c.entity LIKE '%@%', c.entity, NULL)) AS _email
    FROM contact c
      LEFT JOIN yp.drumate de2 ON de2.id = c.entity
      LEFT JOIN yp.drumate du2 ON du2.id = c.uid
  ) c
    LEFT JOIN yp.drumate de ON de.id = c.entity
    LEFT JOIN yp.drumate du ON du.id = c.uid
    LEFT JOIN yp.contact_block mycb ON mycb.contact_id = c.id
    LEFT JOIN archive_entity ae ON ae.entity_id = c.id
  WHERE
    c._email IS NOT NULL
    AND c.`status` <> 'received'
    AND ae.entity_id IS NULL
    AND LOWER(TRIM(c._email)) <> LOWER(TRIM(IFNULL(_mail, '')))
    AND LOWER(TRIM(c._email)) NOT IN (SELECT email FROM _lookup_filter)
    AND (
      _needle = ''
      OR LOWER(TRIM(c._email)) LIKE CONCAT('%', _needle, '%')
      OR LOWER(c.firstname)    LIKE CONCAT(_needle, '%')
      OR LOWER(c.lastname)     LIKE CONCAT(_needle, '%')
      OR LOWER(c.surname)      LIKE CONCAT(_needle, '%')
    )
    AND (_only_drumate = 0 OR COALESCE(du.id, de.id) IS NOT NULL)
  ORDER BY match_rank ASC
  LIMIT _cap;

  -- 3. Same-domain colleagues (paid domains only), mirroring the UNION
  --    branch of `my_contact` — they are invitable without being in the
  --    address book. Matched on email as well as name.
  INSERT IGNORE INTO _lookup (
    match_rank, `page`, is_mycontact, id, contact_id, email,
    firstname, lastname, fullname, surname, category,
    is_drumate, is_need_email, `status`, is_blocked, is_blocked_me
  )
  SELECT
    CASE
      WHEN _needle = ''                                        THEN 3
      WHEN LOWER(TRIM(d.email)) = _needle                      THEN 0
      WHEN LOWER(TRIM(d.email)) LIKE CONCAT(_needle, '%')      THEN 1
      WHEN LOWER(TRIM(d.email)) LIKE CONCAT('%', _needle, '%') THEN 2
      ELSE 3
    END AS match_rank,
    _page,
    1,
    d.id,
    NULL,
    LOWER(TRIM(d.email)),
    d.firstname,
    d.lastname,
    d.fullname,
    COALESCE(d.firstname, d.lastname, d.email),
    NULL,
    1,
    0,
    'mate',
    0,
    0
  FROM yp.drumate d
  WHERE
    d.domain_id = _domain_id
    AND _domain_id > 1
    AND d.id <> _uid
    AND d.email IS NOT NULL
    AND LOWER(TRIM(d.email)) NOT IN (SELECT email FROM _lookup_filter)
    AND (
      _needle = ''
      OR LOWER(TRIM(d.email)) LIKE CONCAT('%', _needle, '%')
      OR LOWER(d.firstname)   LIKE CONCAT(_needle, '%')
      OR LOWER(d.lastname)    LIKE CONCAT(_needle, '%')
      OR LOWER(d.fullname)    LIKE CONCAT(_needle, '%')
    )
  ORDER BY match_rank ASC
  LIMIT _cap;

  SELECT
    `page`,
    is_mycontact,
    id,
    contact_id,
    email,
    firstname,
    lastname,
    fullname,
    surname,
    category,
    is_drumate,
    is_need_email,
    `status`,
    is_blocked,
    is_blocked_me
  FROM _lookup
  ORDER BY match_rank ASC, IFNULL(surname, email) ASC, email ASC
  LIMIT _offset, _range;

  DROP TABLE IF EXISTS _lookup;
  DROP TABLE IF EXISTS _lookup_filter;
END$

DELIMITER ;
