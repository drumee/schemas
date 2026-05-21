UPDATE contact
SET
  status   = 'active',
  uid      = entity,
  category = 'drumate',
  metadata = JSON_SET(IFNULL(metadata, '{}'), '$.is_auto', 0)
WHERE status = 'informed';
