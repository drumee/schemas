DELIMITER $

-- =========================================================
--
-- =========================================================
-- DROP PROCEDURE IF EXISTS `cproc_flow1`$
-- CREATE PROCEDURE `cproc_flow1`(
--    IN beacons json
-- )
-- BEGIN
--   SELECT route from lmh where
--   JSON_CONTAINS(route, beacons, '$') and arrivalAerodromeIcaoId='LSGG';
--
-- END$

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `cproc_flow1`$
CREATE PROCEDURE `cproc_flow1`(
   IN beacons text
)
BEGIN
  SET sql_mode = '';
  SET @b = json_array("PEKIM","PILUL","PIMUP","PIXIS","PIBAT","LUSAR");
  SELECT levels, points,
  departureAerodromeIcaoId AS dep_airport,
  arrivalAerodromeIcaoId AS arr_airport,
  concat(departureAerodromeIcaoId, ' -> ', arrivalAerodromeIcaoId) as city_pair,
  COUNT(*) AS quantity,
  samCtot, samSent
  FROM lmh WHERE
  JSON_CONTAINS(points, @b, '$') AND
    arrivalAerodromeIcaoId='LSGG' GROUP BY city_pair;

END$

-- =========================================================
-- complete : ftfmAllFtPointProfile->"$"
-- =========================================================
DROP PROCEDURE IF EXISTS `cproc_flow2`$
CREATE PROCEDURE `cproc_flow2`(
   IN beacons text
)
BEGIN
  SET sql_mode = '';
  SET @b = json_array("ODEBU","OGULO","OKASI","OKEKO","OKEPI", "OKIRA", "MOU", "MADIV", "MOKIP");
  SELECT levels, points,
  departureAerodromeIcaoId AS dep_airport,
  arrivalAerodromeIcaoId AS arr_airport,
  concat(departureAerodromeIcaoId, ' -> ', arrivalAerodromeIcaoId) as city_pair,
  COUNT(*) AS quantity,
  samCtot, samSent
  FROM lmh WHERE
  JSON_CONTAINS(points, @b, '$') OR
  (departureAerodromeIcaoId like "LFP%" AND
    (arrivalAerodromeIcaoId='LFLL' OR arrivalAerodromeIcaoId='LFLS')) GROUP BY city_pair;

END$

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `cproc_get_beacons`$
CREATE PROCEDURE `cproc_get_beacons`(
   IN ne varchar(512),
   IN sw varchar(512)
)
BEGIN
  SET @s1 = CONCAT("SET @northEast = ST_GeomFromText(", quote(ne), ")");
  SET @s2 = CONCAT("SET @southWest = ST_GeomFromText(", quote(sw), ")");
  PREPARE stmt1 FROM @s1;
  PREPARE stmt2 FROM @s2;
  EXECUTE stmt1;
  EXECUTE stmt2;
  DEALLOCATE PREPARE stmt1;
  DEALLOCATE PREPARE stmt2;
  SET @rec = ST_MakeEnvelope(@northEast, @southWest);
  SELECT `name`, ST_AsText(coords) AS coords FROM nav_point WHERE MBRWithin(coords, @rec);
END$

-- =========================================================
--
-- =========================================================
DROP FUNCTION IF EXISTS `strSplit`$
CREATE FUNCTION strSplit(x TEXT, delim VARCHAR(12), pos INTEGER) 
RETURNS TEXT
BEGIN
  DECLARE output TEXT;
  SET output = REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos)
                 , LENGTH(SUBSTRING_INDEX(x, delim, pos - 1)) + 1)
                 , delim
                 , '');
  IF output = '' THEN SET output = null; END IF;
  RETURN output;
END $$


-- =========================================================
-- complete : ftfmAllFtPointProfile->"$"
-- =========================================================
-- DROP PROCEDURE IF EXISTS `cproc_new1`$
-- CREATE PROCEDURE `cproc_flow2`(
--    IN beacons text
-- )
-- BEGIN
--   SET sql_mode = '';
--   SELECT levels AS rfl, route
--   departureAerodromeIcaoId AS dep_airport,
--   arrivalAerodromeIcaoId AS arr_airport,
--   concat(departureAerodromeIcaoId, ' -> ', arrivalAerodromeIcaoId) as city_pair,
--   COUNT(*) AS quantity,
--   samCtot, samSent
--   FROM lmh WHERE
--   WHERE (JSON_SEARCH(route, 'one' , 'PEKIM') IS NOT NULL AND
--   JSON_SEARCH(route, 'one' , 'PILUL') IS NOT NULL AND
--   JSON_SEARCH(route, 'one', 'PIBAT') IS NOT NULL) AND
--   departureAerodromeIcaoId like "LFP%";
-- 
-- END$
-- select ftfmAllFtPointProfile->>"$[*].level", route from lmh where JSON_SEARCH(route, 'one' , 'ODEBU') IS NOT NULL AND JSON_SEARCH(route, 'one' , 'MILPA') IS NOT NULL limit 10;

-- -- =========================================================
-- --
-- -- =========================================================
-- DROP PROCEDURE IF EXISTS `cproc_all_flow`$
-- CREATE PROCEDURE `cproc_all_flow`(
--    IN beacons1 json,
--    IN beacons2 json
-- )
-- BEGIN
--
--   SELECT route from lmh where
--   (JSON_CONTAINS(route, beacons1, '$') AND arrivalAerodromeIcaoId='LSGG') OR
--   (departureAerodromeIcaoId like "LFP%" AND (arrivalAerodromeIcaoId='LFLL' OR arrivalAerodromeIcaoId='LFLS')) OR
--   JSON_CONTAINS(route, beacons2, '$');
-- END$

DELIMITER ;
