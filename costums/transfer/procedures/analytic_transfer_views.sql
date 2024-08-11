
DELIMITER $


-- DROP PROCEDURE IF EXISTS `analytic_transfer_users`$
DROP PROCEDURE IF EXISTS `analytic_transfer_views`$
CREATE PROCEDURE `analytic_transfer_views`(
  IN _json JSON
)
BEGIN
    WITH data1 
    AS (
      SELECT DISTINCT json_value(metadata, "$.page_view") page_count,
      FROM_UNIXTIME(ctime, "%y-%m-%d") day, 
      count(*) page_view
      FROM analytic_transfer GROUP BY day ASC
    )
    SELECT day, sum(page_view) OVER (ORDER BY day) AS views from data1 GROUP BY day;
END $

DELIMITER ;
