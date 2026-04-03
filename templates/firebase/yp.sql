

replace into tmp_yp.tutorial select * from yp.tutorial;
replace into tmp_yp.sys_var select * from yp.sys_var;
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
