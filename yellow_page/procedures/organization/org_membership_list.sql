DELIMITER $

-- =========================================================
-- org_membership_list
-- =========================================================
-- The people who belong to an organisation as a SECONDARY organisation,
-- for the Admin Console member list: uid, privilege, name, email.
DROP PROCEDURE IF EXISTS `org_membership_list`$
CREATE PROCEDURE `org_membership_list`(
  IN _domain_id INT UNSIGNED
)
BEGIN
  SELECT m.uid, m.privilege, m.ctime,
         d.firstname, d.lastname, d.fullname, d.email, d.username
    FROM org_membership m
    LEFT JOIN drumate d ON d.id = m.uid
   WHERE m.domain_id = _domain_id
   ORDER BY m.ctime;
END$

DELIMITER ;
