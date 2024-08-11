

-- LOAD DATA LOCAL INFILE 'country.txt' INTO TABLE  `country_fr` charset latin1 FIELDS TERMINATED BY '\t';
CREATE TABLE `icons` ( `sys_id` INT NOT NULL AUTO_INCREMENT , 
`name` VARCHAR(128) NULL DEFAULT NULL ,
PRIMARY KEY (`sys_id`), INDEX (`en`, `fr`, `ru`), UNIQUE (`name`)) ENGINE = InnoDB;
