DELIMITER $

-- =========================================================
-- mkt_link_list
--
-- The registry, with what each link actually produced beside it.
--
-- THE JOIN IS ON THREE COLUMNS, NOT FIVE. Signup only persists
-- utm_source/utm_medium/utm_campaign (loby service/lib/loby.js), so two
-- registry rows that differ only by utm_content or utm_term are
-- indistinguishable in the signup data and necessarily report the same
-- figures. `links_sharing` counts how many rows share a triple, so the UI can
-- say so out loud instead of printing one number twice and letting the reader
-- assume each link earned it. When Phase 0 lands, widen the join to five
-- columns and drop the column.
--
-- THERE IS NO clicks COLUMN. Nothing counts clicks on a campaign link —
-- yp has no landing-hit table and analytics-server's `trafic` is nginx-derived
-- and hub-scoped. A zero here would read as "nobody clicked"; its absence
-- reads as "not measured", which is the true statement.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_link_list`$
CREATE PROCEDURE `mkt_link_list`(
  IN _include_archived TINYINT
)
BEGIN
  SELECT
    l.id,
    l.name,
    l.destination,
    l.utm_source,
    l.utm_medium,
    l.utm_campaign,
    l.utm_term,
    l.utm_content,
    l.ref,
    l.owner,
    l.archived,
    FROM_UNIXTIME(l.ctime, '%Y-%m-%d') AS created,
    IFNULL(p.signups, 0)   AS signups,
    IFNULL(p.activated, 0) AS activated,
    (SELECT COUNT(*) FROM mkt_campaign_link x
      WHERE x.utm_source = l.utm_source
        AND x.utm_medium = l.utm_medium
        AND x.utm_campaign = l.utm_campaign) AS links_sharing
  FROM mkt_campaign_link l
  LEFT JOIN (
    SELECT
      LOWER(TRIM(JSON_VALUE(d.profile, '$.utm.utm_source')))   AS s,
      LOWER(TRIM(JSON_VALUE(d.profile, '$.utm.utm_medium')))   AS m,
      LOWER(TRIM(JSON_VALUE(d.profile, '$.utm.utm_campaign'))) AS c,
      COUNT(*) AS signups,
      SUM(IF(
        EXISTS(SELECT 1 FROM mfs_changelog mu
          WHERE mu.uid = d.id AND mu.event = 'media.new'
            AND IFNULL(JSON_VALUE(mu.src, '$.ftype'), '') NOT IN ('hub', 'folder'))
        OR EXISTS(SELECT 1 FROM services_log ss
          WHERE ss.uid = d.id AND ss.name = 'secure_share.create')
        OR EXISTS(SELECT 1 FROM services_log ws
          WHERE ws.uid = d.id AND ws.name = 'desk.track_workspace'
            AND NOT (IFNULL(JSON_VALUE(ws.args, '$.backfill'), 0) = 1
                 AND IFNULL(JSON_VALUE(ws.args, '$.filename'), '') IN
                     ('Internal Workspace','External Workspace','Personal Workspace')))
      , 1, 0)) AS activated
    FROM drumate d
    WHERE JSON_VALUE(d.profile, '$.utm.utm_campaign') IS NOT NULL
    GROUP BY s, m, c
  ) p
    ON p.s = l.utm_source AND p.m = l.utm_medium AND p.c = l.utm_campaign
  WHERE (_include_archived = 1 OR l.archived = 0)
  ORDER BY l.archived ASC, l.ctime DESC;
END $

DELIMITER ;
