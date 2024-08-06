DELIMITER $

DROP PROCEDURE IF EXISTS `helpdesk`$
CREATE PROCEDURE `helpdesk`(
	_ln VARCHAR(25),
	_page int
)
BEGIN
	SELECT * FROM helpdesk WHERE ln = _ln AND _page =1 ;
END $

DELIMITER ;
