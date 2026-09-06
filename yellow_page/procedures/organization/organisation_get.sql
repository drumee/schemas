DELIMITER $

-- =========================================================
-- organisation_get
-- =========================================================
-- Look an organisation up by whichever handle the caller happens to hold:
-- its own id, its domain_id, its vhost link, or its name. Callers genuinely
-- do pass all four -- lib/env.js and butler.check_domain pass a hostname,
-- most service code passes a domain_id.
--
-- LIMIT 1 because every caller reads the result as a single row. await_proc
-- collapses one row to a bare object but N rows to an ARRAY, so a second
-- match does not raise an error here -- it silently turns `org.id` into
-- undefined in the caller. The four-way OR makes that reachable whenever one
-- organisation's name equals another's link or ident.
--
-- NOTE FOR CALLERS: _key is VARCHAR(1000) and is compared against the INT
-- column domain_id, so MySQL coerces -- '2xyz' matches domain_id = 2. Never
-- hand this procedure an unvalidated request value; resolve through
-- domain_privilege first and pass the validated integer.
DROP PROCEDURE IF EXISTS `organisation_get`$
CREATE PROCEDURE `organisation_get`(
   IN _key VARCHAR(1000)
)
BEGIN
  SELECT *, link `url` FROM organisation
   WHERE id = _key OR domain_id = _key OR link = _key OR name = _key
   LIMIT 1;
END$

DELIMITER ;
