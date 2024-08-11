DROP TABLE IF EXISTS `hubs`;
CREATE TABLE `hubs` ( `id` VARBINARY(16) NOT NULL , `rank` TINYINT(4) NOT NULL DEFAULT '1' , PRIMARY KEY (`id`), INDEX (`rank`)) ENGINE = InnoDB;

insert into hubs select * from sites;

-- insert into sites select hid, (select count(*) from sites) as rank from yp.membership_csv where user_id=(select id from yp.entity where db_name=database());