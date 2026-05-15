DELIMITER $

-- Returns the first contact (other than _contact_id) that already references
-- _email — either as the contact's `entity` (the default identifier) or as
-- any row in `contact_email`. Empty result set means the email is free.
DROP PROCEDURE IF EXISTS `my_contact_email_in_use`$
CREATE PROCEDURE `my_contact_email_in_use`(
  IN _email      VARCHAR(255),
  IN _contact_id VARCHAR(16)
)
BEGIN
  DECLARE _needle VARCHAR(255);

  IF _contact_id IN ('', '0') THEN
    SELECT NULL INTO _contact_id;
  END IF;

  SELECT LOWER(TRIM(IFNULL(_email, ''))) INTO _needle;

  IF _needle = '' THEN
    -- Empty needle never matches; return an empty result set explicitly.
    SELECT c.id, c.firstname, c.lastname, c.entity, c.entity AS email
    FROM contact c WHERE 1 = 0;
  ELSE
    SELECT
      c.id,
      c.firstname,
      c.lastname,
      c.entity,
      COALESCE(ce.email, c.entity) AS email
    FROM contact c
    LEFT JOIN contact_email ce
      ON ce.contact_id = c.id
     AND LOWER(TRIM(ce.email)) = _needle
    WHERE
      (LOWER(TRIM(c.entity)) = _needle OR ce.sys_id IS NOT NULL)
      AND (_contact_id IS NULL OR c.id <> _contact_id)
    LIMIT 1;
  END IF;
END$

DELIMITER ;
