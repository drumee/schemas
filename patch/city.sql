-- Load data into table
-- LOAD DATA LOCAL
-- INFILE 'GEODATASOURCE-CITIES-FREE.TXT'
-- INTO TABLE `world_cities_free`
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 LINES;

-- Country,City,AccentCity,Region,Population,Latitude,Longitude
-- Create table "country"
CREATE TABLE `city`(
	`cc_fips` VARCHAR(2),
	`name_ascii` VARCHAR(100),
	`name_utf8` VARCHAR(100),
	`region` VARCHAR(100),
	`population` VARCHAR(100),
	`lat` INT(8),
	`lng` INT(8),
	INDEX `name_ascii`(`name_ascii`),
	INDEX `name_utf8`(`name_utf8`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE `country_fr`(
	`cc_iso` VARCHAR(2),
	`name_utf8` VARCHAR(100),
	`f1` VARCHAR(100),
	`f2` VARCHAR(100),
	`f3` VARCHAR(100),
	`f4` VARCHAR(100),
	`f5` VARCHAR(100),
	INDEX `name_utf8`(`name_utf8`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


LOAD DATA LOCAL INFILE 'country.txt' INTO TABLE  `country_fr` charset latin1 FIELDS TERMINATED BY '\t';