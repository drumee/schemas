DELIMITER $

-- =========================================================
-- org_title_list
-- =========================================================
-- An organisation's own titles (yp.org_title), in the order they follow the
-- three built-ins. The built-ins are not rows and are not returned: the
-- service prepends them, so a deployment without this table still offers
-- exactly the three it always did.
DROP PROCEDURE IF EXISTS `org_title_list`$
CREATE PROCEDURE `org_title_list`(
  IN _domain_id INT UNSIGNED
)
BEGIN
  SELECT id, name, `rank`
    FROM org_title
   WHERE domain_id = _domain_id
   ORDER BY `rank` ASC, ctime ASC;
END$

DELIMITER ;
