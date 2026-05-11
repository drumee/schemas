DELIMITER $

DROP PROCEDURE IF EXISTS `hub_count_admins`$
CREATE PROCEDURE `hub_count_admins`()
BEGIN
  -- Distinct entities holding hub-level admin (`resource_id = '*'`, admin
  -- bit = 0b0010000 = 16). Feeds the bus-factor component of the audit-logs
  -- Security Score — hubs with exactly one admin are a single point of
  -- failure; the yp aggregator counts hubs where this returns > 1.
  SELECT COUNT(DISTINCT p.entity_id) AS total
  FROM permission p
  WHERE p.resource_id = '*'
    AND (p.permission & 16) > 0;
END$

DELIMITER ;
