

replace into tmp_yp.tutorial select * from yp.tutorial;
replace into tmp_yp.sys_var select * from yp.sys_var;
replace into tmp_yp.sys_conf select * from yp.sys_conf where conf_key 
    not in ('google_client_id', 'google_client_secret', 'stripe_skey', 
    'stripe_testclock', 'stripe_endpointSecret', 'stripe_testclock_on');
replace into tmp_yp.helpdesk select * from yp.helpdesk;
replace into tmp_yp.filecap select * from yp.filecap;
replace into tmp_yp.extention select * from yp.extention;
replace into tmp_yp.country select * from yp.country;
replace into tmp_yp.countries select * from yp.countries;
replace into tmp_yp.city select * from yp.city where cc_iso='fr';
replace into tmp_yp.cities select * from yp.cities;
replace into tmp_yp.languages select * from yp.languages;
replace into tmp_yp.language select * from yp.language;
replace into tmp_yp.icons select * from yp.icons;
replace into tmp_yp.font select * from yp.font;
replace into tmp_yp.error select * from yp.error;


-- select v.id from yp.vhost v inner join yp.domain d on v.fqdn=d.name where d.id=1 into @id;
-- replace into tmp_yp.entity select * from yp.entity where id=@id;
-- replace into tmp_yp.hub select * from yp.hub where uid=@id;


-- select id from vhost where fqdn='tunnel.drumee.io' into @id;
-- replace into tmp_yp.entity select * from yp.entity where id=@id;
-- replace into tmp_yp.hub select * from yp.hub where uid=@id;
