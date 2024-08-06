DELIMITER $

DROP PROCEDURE IF EXISTS `cookie_deprecated`$
CREATE PROCEDURE `cookie_deprecated`()

BEGIN

  DELETE
  FROM yp.cookie 
  WHERE id IN 
  (
      SELECT SUBSTRING( id, length(Substring_Index(id, '=', 1) )+2, 64) id  
      FROM ( 
            SELECT  MAX(ctime)ctime , 
            json_value(headers, "$.cookie") id  
            FROM  services_log 
            GROUP BY json_value(headers, "$.cookie")
          ) A 
      WHERE ctime <= (SELECT UNIX_TIMESTAMP() -  2678400 )  

  );

END$

DELIMITER ;
