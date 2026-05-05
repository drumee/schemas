DELIMITER $

DROP PROCEDURE IF EXISTS `hub_count_high_risk_actions`$
CREATE PROCEDURE `hub_count_high_risk_actions`(
  IN _from_time INT(11),
  IN _to_time INT(11)
)
BEGIN
  -- Counts action_log rows representing risk-relevant events for the
  -- High-Risk Actions audit insight card. The set is intentionally
  -- conservative: admin/permission category changes plus the explicitly
  -- risky action types added in alter_action_log_add_actions.sql. The yp
  -- aggregator (get_audit_stats) sums this across every hub in the domain.
  SELECT COUNT(*) AS total
  FROM action_log a
  WHERE (_from_time = 0 OR a.ctime >= _from_time)
    AND (_to_time   = 0 OR a.ctime <= _to_time)
    AND (
      a.category IN ('admin', 'permission')
      OR a.action IN ('grant_access', 'change_policy', 'share_link', 'removed')
    );
END$

DELIMITER ;
