DROP PROCEDURE IF EXISTS `intl_list`$
DROP PROCEDURE IF EXISTS `list_locale`$
CREATE PROCEDURE `list_locale`(
  IN _page INT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  select key_code, fr, en, ru, zh from intl where category='ui'
  ORDER BY key_code ASC LIMIT _offset, _range;
 END $

DROP PROCEDURE IF EXISTS `update_locale`$
CREATE PROCEDURE `update_locale`(
  _key VARCHAR(40),
  _en text,
  _fr text,
  _ru text,
  _zh text
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  UPDATE intl SET en=_en, fr=_fr, ru=_ru, zh=_zh WHERE key_code=_key;
  SELECT key_code, fr, en, ru, zh from intl where key_code=_key;
 END $