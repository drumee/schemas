DELIMITER $

-- =========================================================
-- pool_free
-- =========================================================
-- How many pool entities of `_type` are actually available.
--
-- This has to agree with `pickupEntity`, which only ever hands out a pool
-- entity whose `settings.pool_state` is 'clean' — the flag the hubs factory
-- sets last, once the schema is loaded, the storage root exists and the
-- file-name search projection is published. Counting every row in the pool
-- instead counted half-built leftovers that no create_hub could ever be given,
-- so a pool of failures read as full: the factory stopped building at its
-- watermark while `desk_create_hub` answered "Pool <area> is empty".
DROP FUNCTION IF EXISTS `pool_free`$
CREATE FUNCTION `pool_free`(
  _type VARCHAR(80)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(512);
  SELECT COUNT(id) FROM yp.entity
    WHERE area='pool'
    AND type=_type
    AND JSON_VALUE(settings, "$.pool_state")='clean' INTO _res;
  RETURN _res;
END$

DELIMITER ;
