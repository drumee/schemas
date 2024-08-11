-- id = ifpsId
CREATE TABLE `nav_point` (
  `name` varchar(8) CHARACTER SET ascii NOT NULL DEFAULT '',
  `type` varchar(6) CHARACTER SET ascii NOT NULL DEFAULT '',
  coords GEOMETRY NOT NULL,
  PRIMARY KEY (`name`),
  KEY `type` (`type`),
  SPATIAL INDEX(`coords`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;

-- INSERT INTO geom VALUES (ST_GeomFromText('POINT(1 1)'));