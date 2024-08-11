aaa;


ALTER TABLE drumate         engine=innoDB;
ALTER TABLE error           engine=innoDB;
ALTER TABLE files_formats   engine=innoDB;
ALTER TABLE hub             engine=innoDB;
ALTER TABLE intl            engine=innoDB;
ALTER TABLE language        engine=innoDB;
ALTER TABLE locale          engine=innoDB;
ALTER TABLE log             engine=innoDB;
ALTER TABLE membership      engine=innoDB;
ALTER TABLE notice          engine=innoDB;
ALTER TABLE notices         engine=innoDB;
ALTER TABLE params_tpl      engine=innoDB;
ALTER TABLE preregister     engine=innoDB;
ALTER TABLE pub_headlines   engine=innoDB;
ALTER TABLE remit           engine=innoDB;
ALTER TABLE request         engine=innoDB;
ALTER TABLE sessions        engine=innoDB;
ALTER TABLE signon          engine=innoDB;
ALTER TABLE sys_conf        engine=innoDB;
ALTER TABLE team            engine=innoDB;
| yp           | community             | cname       | utf8               | utf8_general_ci |
| yp           | community             | photo       | utf8               | utf8_general_ci |
| yp           | community             | description | utf8               | utf8_general_ci |
| yp           | community             | keywords    | utf8               | utf8_general_ci |
| yp           | community_profile     | cname       | utf8               | utf8_general_ci |
| yp           | community_profile     | name        | utf8               | utf8_general_ci |
| yp           | community_profile     | photo       | utf8               | utf8_general_ci |
| yp           | community_profile     | description | utf8               | utf8_general_ci |
| yp           | community_profile     | keywords    | utf8               | utf8_general_ci |
| yp           | community_view        | nickname    | utf8               | utf8_general_ci |
| yp           | community_view        | fullname    | utf8               | utf8_general_ci |
| yp           | community_view        | cname       | utf8               | utf8_general_ci |
| yp           | community_view        | photo       | utf8               | utf8_general_ci |
| yp           | community_view        | description | utf8               | utf8_general_ci |
| yp           | community_view        | keywords    | utf8               | utf8_general_ci |
| yp           | drumate_ssv           | online      | utf8               | utf8_general_ci |
| yp           | drumate_view          | online      | utf8               | utf8_general_ci |
| yp           | files_formats         | description | utf8               | utf8_general_ci |
| yp           | hub_csv               | cname       | utf8               | utf8_general_ci |
| yp           | hub_csv               | name        | utf8               | utf8_general_ci |
| yp           | hub_csv               | photo       | utf8               | utf8_general_ci |
| yp           | hub_csv               | description | utf8               | utf8_general_ci |
| yp           | hub_csv               | keywords    | utf8               | utf8_general_ci |
| yp           | open_communities_view | cname       | utf8               | utf8_general_ci |
| yp           | open_communities_view | photo       | utf8               | utf8_general_ci |
| yp           | open_communities_view | description | utf8               | utf8_general_ci |
| yp           | project_csv           | cname       | utf8               | utf8_general_ci |
| yp           | project_csv           | name        | utf8               | utf8_general_ci |
| yp           | project_csv           | photo       | utf8               | utf8_general_ci |
| yp           | project_csv           | description | utf8               | utf8_general_ci |
| yp           | project_csv           | keywords    | utf8               | utf8_general_ci |
| yp           | space_view            | cname       | utf8               | utf8_general_ci |
| yp           | space_view            | description | utf8               | utf8_general_ci |
| yp           | space_view            | keywords    | utf8               | utf8_general_ci |
| yp           | user_csv              | online      | utf8               | utf8_general_ci |
| yp           | user_view             | online      | utf8               | utf8_general_ci |
SELECT table_schema, table_name, column_name, character_set_name, collation_name FROM information_schema.columns WHERE collation_name = 'utf8_general_ci' and table_schema='yp' ORDER BY table_schema, table_name,ordinal_position;
-----------------------+-------------------+--------------------+-----------------+
 table_name            | column_name       | character_set_name | collation_name  |
-----------------------+-------------------+--------------------+-----------------+
 alias                 | vhost             | utf8               | utf8_unicode_ci |
 area                  | id                | utf8               | utf8_unicode_ci |
 area                  | owner_id          | utf8               | utf8_unicode_ci |
 area                  | level             | utf8               | utf8_unicode_ci |
 community_profile     | ident             | utf8               | utf8_unicode_ci |
 community_profile     | type              | utf8               | utf8_unicode_ci |
 community_profile     | vhost             | utf8               | utf8_unicode_ci |
 community_profile     | area              | utf8               | utf8_unicode_ci |
 community_profile     | layout            | utf8               | utf8_unicode_ci |
 community_profile     | home              | utf8               | utf8_unicode_ci |
 community_profile     | fallback          | utf8               | utf8_unicode_ci |
 community_profile     | headline          | utf8               | utf8_unicode_ci |
 domain                | name              | utf8               | utf8_unicode_ci |
 domain                | alias             | utf8               | utf8_unicode_ci |
 drumate               | id                | utf8               | utf8_unicode_ci |
 drumate               | email             | utf8               | utf8_unicode_ci |
 drumate               | dmail             | utf8               | utf8_unicode_ci |
 drumate               | firstname         | utf8               | utf8_unicode_ci |
 drumate               | lastname          | utf8               | utf8_unicode_ci |
 drumate               | photo_pub         | utf8               | utf8_unicode_ci |
 drumate               | photo_res         | utf8               | utf8_unicode_ci |
 drumate               | photo_prv         | utf8               | utf8_unicode_ci |
 drumate               | gender            | utf8               | utf8_unicode_ci |
 drumate               | fingerprint       | utf8               | utf8_unicode_ci |
 drumate               | activation_key    | utf8               | utf8_unicode_ci |
 drumate               | ip_pw_changing    | utf8               | utf8_unicode_ci |
 entity                | ident             | utf8               | utf8_unicode_ci |
 entity                | vhost             | utf8               | utf8_unicode_ci |
 entity                | db_name           | utf8               | utf8_unicode_ci |
 entity                | db_host           | utf8               | utf8_unicode_ci |
 entity                | fs_host           | utf8               | utf8_unicode_ci |
 entity                | home_dir          | utf8               | utf8_unicode_ci |
 entity                | home_layout       | utf8               | utf8_unicode_ci |
 entity                | layout            | utf8               | utf8_unicode_ci |
 entity                | type              | utf8               | utf8_unicode_ci |
 entity                | area              | utf8               | utf8_unicode_ci |
 entity                | headline          | utf8               | utf8_unicode_ci |
 entity                | status            | utf8               | utf8_unicode_ci |
 error                 | code              | utf8               | utf8_unicode_ci |
 error                 | level             | utf8               | utf8_unicode_ci |
 hub                   | id                | utf8               | utf8_unicode_ci |
 hub                   | dmail             | utf8               | utf8_unicode_ci |
 hub                   | name              | utf8               | utf8_unicode_ci |
 hub                   | photo             | utf8               | utf8_unicode_ci |
 hub                   | autojoin          | utf8               | utf8_unicode_ci |
 hub                   | description       | utf8               | utf8_unicode_ci |
 hub                   | keywords          | utf8               | utf8_unicode_ci |
 intl                  | key_code          | utf8               | utf8_unicode_ci |
 intl                  | category          | utf8               | utf8_unicode_ci |
 intl                  | fr                | utf8               | utf8_unicode_ci |
 intl                  | en                | utf8               | utf8_unicode_ci |
 language              | code              | utf8               | utf8_unicode_ci |
 language              | lcid              | utf8               | utf8_unicode_ci |
 language              | locale_en         | utf8               | utf8_unicode_ci |
 language              | locale            | utf8               | utf8_unicode_ci |
 language              | comment           | utf8               | utf8_unicode_ci |
 locale                | lang              | utf8               | utf8_unicode_ci |
 locale                | lang_scope        | utf8               | utf8_unicode_ci |
 locale                | lang_desc         | utf8               | utf8_unicode_ci |
 locale                | lc_ctype          | utf8               | utf8_unicode_ci |
 locale                | lc_numeric        | utf8               | utf8_unicode_ci |
 locale                | lc_time           | utf8               | utf8_unicode_ci |
 locale                | lc_date           | utf8               | utf8_unicode_ci |
 locale                | lc_collate        | utf8               | utf8_unicode_ci |
 locale                | lc_monetary       | utf8               | utf8_unicode_ci |
 locale                | lc_messages       | utf8               | utf8_unicode_ci |
 locale                | lc_paper          | utf8               | utf8_unicode_ci |
 locale                | lc_name           | utf8               | utf8_unicode_ci |
 locale                | lc_address        | utf8               | utf8_unicode_ci |
 locale                | lc_telephone      | utf8               | utf8_unicode_ci |
 locale                | lc_measurement    | utf8               | utf8_unicode_ci |
 locale                | lc_identification | utf8               | utf8_unicode_ci |
 locale                | lc_all            | utf8               | utf8_unicode_ci |
 log                   | id                | utf8               | utf8_unicode_ci |
 log                   | key_id            | utf8               | utf8_unicode_ci |
 log                   | username          | utf8               | utf8_unicode_ci |
 log                   | last_ip           | utf8               | utf8_unicode_ci |
 log                   | last_ip_fwd_for   | utf8               | utf8_unicode_ci |
 log                   | req_uri           | utf8               | utf8_unicode_ci |
 log                   | referer           | utf8               | utf8_unicode_ci |
 log                   | ua                | utf8               | utf8_unicode_ci |
 log                   | action            | utf8               | utf8_unicode_ci |
 membership            | id                | utf8               | utf8_unicode_ci |
 membership            | drumate_id        | utf8               | utf8_unicode_ci |
 membership            | cid               | utf8               | utf8_unicode_ci |
 membership            | hub_id            | utf8               | utf8_unicode_ci |
 membership            | area_id           | utf8               | utf8_unicode_ci |
 membership            | area              | utf8               | utf8_unicode_ci |
 membership            | username          | utf8               | utf8_unicode_ci |
 notice                | dest_email        | utf8               | utf8_unicode_ci |
 notice                | category          | utf8               | utf8_unicode_ci |
 notice                | link_type         | utf8               | utf8_unicode_ci |
 notice                | status            | utf8               | utf8_unicode_ci |
 notices               | email             | utf8               | utf8_unicode_ci |
 notices               | type              | utf8               | utf8_unicode_ci |
 notices               | message           | utf8               | utf8_unicode_ci |
 notices               | status            | utf8               | utf8_unicode_ci |
 notices               | data              | utf8               | utf8_unicode_ci |
 notices               | subject_type      | utf8               | utf8_unicode_ci |
 preregister           | email             | utf8               | utf8_unicode_ci |
 preregister           | referer           | utf8               | utf8_unicode_ci |
 remit                 | method            | utf8               | utf8_unicode_ci |
 request               | firstname         | utf8               | utf8_unicode_ci |
 request               | lastname          | utf8               | utf8_unicode_ci |
 request               | email             | utf8               | utf8_unicode_ci |
 request               | message           | utf8               | utf8_unicode_ci |
 request               | reason            | utf8               | utf8_unicode_ci |
 request               | ident             | utf8               | utf8_unicode_ci |
 sessions              | id                | utf8               | utf8_unicode_ci |
 sessions              | user_id           | utf8               | utf8_unicode_ci |
 sessions              | username          | utf8               | utf8_unicode_ci |
 sessions              | domain            | utf8               | utf8_unicode_ci |
 sessions              | last_ip           | utf8               | utf8_unicode_ci |
 sessions              | last_ip_fwd_for   | utf8               | utf8_unicode_ci |
 sessions              | req_uri           | utf8               | utf8_unicode_ci |
 sessions              | referer           | utf8               | utf8_unicode_ci |
 sessions              | ua                | utf8               | utf8_unicode_ci |
 sessions              | action            | utf8               | utf8_unicode_ci |
 settings              | dbhost            | utf8               | utf8_unicode_ci |
 settings              | fshost            | utf8               | utf8_unicode_ci |
 settings              | mfs_root          | utf8               | utf8_unicode_ci |
 settings              | user_root         | utf8               | utf8_unicode_ci |
 settings              | site_root         | utf8               | utf8_unicode_ci |
 signon                | firstname         | utf8               | utf8_unicode_ci |
 signon                | lastname          | utf8               | utf8_unicode_ci |
 signon                | email             | utf8               | utf8_unicode_ci |
 signon                | ident             | utf8               | utf8_unicode_ci |
 signon                | act_key           | utf8               | utf8_unicode_ci |
 signon                | ip                | utf8               | utf8_unicode_ci |
 signon                | referer           | utf8               | utf8_unicode_ci |
 sys_conf              | conf_key          | utf8               | utf8_unicode_ci |
 sys_conf              | conf_value        | utf8               | utf8_unicode_ci |
 team                  | firstname         | utf8               | utf8_unicode_ci |
 team                  | lastname          | utf8               | utf8_unicode_ci |
 team                  | domain            | utf8               | utf8_unicode_ci |
 team                  | email             | utf8               | utf8_unicode_ci |
 team                  | mobile            | utf8               | utf8_unicode_ci |
ALTER TABLE `entity` CHANGE `ident` `ident` VARCHAR(40) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '';
