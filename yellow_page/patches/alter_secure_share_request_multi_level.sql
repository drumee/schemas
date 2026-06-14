-- Multi-level access requests: a recipient can request several permissions at
-- once (e.g. chat + edit). ENUM holds a single value, so widen requested_level
-- and granted_level to SET — MySQL's native multi-value type (comma-list,
-- validated against the allowed members). Existing single values convert
-- losslessly (an ENUM 'can_edit' becomes the SET value 'can_edit').
ALTER TABLE `secure_share_access_request`
  MODIFY `requested_level` SET('can_download','can_chat','can_edit') NOT NULL,
  MODIFY `granted_level`   SET('can_view','can_download','can_chat','can_edit') DEFAULT NULL;
