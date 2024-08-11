-- update media set parent_path = IF(category='folder', REPLACE(file_path, user_filename, ''), REPLACE(file_path, concat(id, '-orig.', extension), ""));

replace into media select null, hubs.id, owner_id, vhost, hub.name, 
(select id from media where parent_id='0' limit 1), '', entity.area, 'text/plain', 
'hub', 0, entity.space, '', 
unix_timestamp(), unix_timestamp(), 0, 0, '', '', 'active', 'submitted', 0
from hubs left join(yp.entity, yp.hub) on hubs.id=entity.id and hubs.id=hub.id 
where owner_id is not null;
