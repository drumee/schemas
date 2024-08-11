
SET @id='ffffffffffffffff';
replace into tmp_yp.drumate (id, username, domain_id, remit, fingerprint, profile) 
    select id, username, domain_id, remit, "****", profile from yp.drumate 
    where id=@id;

replace into tmp_yp.entity select * from yp.entity where id=@id;
replace into tmp_yp.privilege select * from yp.privilege where uid=@id;

replace into tmp_yp.tutorial select * from yp.tutorial;
replace into tmp_yp.sys_var select * from yp.sys_var;
replace into tmp_yp.sys_conf select * from yp.sys_conf;
replace into tmp_yp.helpdesk select * from yp.helpdesk;
replace into tmp_yp.filecap select * from yp.filecap;
replace into tmp_yp.extention select * from yp.extention;
replace into tmp_yp.country select * from yp.country;
replace into tmp_yp.countries select * from yp.countries;
replace into tmp_yp.city select * from yp.city;
replace into tmp_yp.cities select * from yp.cities;
replace into tmp_yp.locale select * from yp.locale;
replace into tmp_yp.languages select * from yp.languages;
replace into tmp_yp.language select * from yp.language;
replace into tmp_yp.intl select * from yp.intl;
replace into tmp_yp.icons select * from yp.icons;
replace into tmp_yp.font select * from yp.font;
replace into tmp_yp.files_formats select * from yp.files_formats;

select id from vhost where fqdn='tunnel.drumee.io' into @id;
replace into tmp_yp.error select * from yp.error;
