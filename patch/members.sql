-- CREATE TABLE `members` ( `id` VARBINARY(16) NOT NULL , `privilege` TINYINT(4) NOT NULL DEFAULT 0 , PRIMARY KEY (`id`), INDEX (`privilege`)) ENGINE = InnoDB;

-- insert into sites select hid, (select count(*) from sites) as rank from yp.membership_csv where user_id=(select id from yp.entity where db_name=database());

insert into members select drumate_id, privilege from yp.membership where hub_id=(select id from yp.entity where db_name=database());