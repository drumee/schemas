-- replace into font_face values(null, 'AvantGardeLT Book', 'normal', 400, "AvantGarde Book", "AvantGarde", "fonts.drumee.name/fonts/avantgarde/AvantGardeLT-Book.ttf" , "truetype", "", "");
-- alter table font_face drop key family;
alter table font_face add UNIQUE KEY `family` (`family`, `weight`);
