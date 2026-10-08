DELIMITER $

-- =========================================================
-- my_orgs
-- =========================================================
-- Every organisation a person belongs to, for the org dropdown (Figma
-- 900:150849 / 900:150993): the primary one (privilege table) and the
-- secondary ones (org_membership), with the person's privilege there, the
-- organisation's plan (its own quota row) and its counts.
--   source: 'primary' | 'membership'
-- Guests (workspace access without membership) are added by the service,
-- which can read the person's own database.
DROP PROCEDURE IF EXISTS `my_orgs`$
CREATE PROCEDURE `my_orgs`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT t.*,
         (SELECT q.plan FROM quota q
           WHERE q.domain_id = t.domain_id AND q.payer_id = t.org_id LIMIT 1) AS plan,
         (SELECT COUNT(*) FROM department dp WHERE dp.domain_id = t.domain_id) AS department_count,
         ((SELECT COUNT(*) FROM privilege p2 WHERE p2.domain_id = t.domain_id)
          + (SELECT COUNT(*) FROM org_membership m2 WHERE m2.domain_id = t.domain_id)) AS member_count
    FROM (
      SELECT o.id AS org_id, o.domain_id, o.name, o.link, o.ident,
             p.privilege, 'primary' AS source
        FROM privilege p
        INNER JOIN organisation o ON o.domain_id = p.domain_id
       WHERE p.uid = _uid AND p.domain_id > 1
      UNION ALL
      SELECT o.id, o.domain_id, o.name, o.link, o.ident,
             m.privilege, 'membership'
        FROM org_membership m
        INNER JOIN organisation o ON o.domain_id = m.domain_id
       WHERE m.uid = _uid
    ) t
   ORDER BY t.privilege DESC, t.name;
END$

DELIMITER ;
