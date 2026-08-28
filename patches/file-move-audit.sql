-- =========================================================
-- file-move-audit.sql
--
-- READ-ONLY. Kiểm tra một instance có đủ artifact cho flow
-- cross-hub file-thread move (batch deploy 2026-07-26) không.
--
-- Chạy:  mariadb < patches/file-move-audit.sql
--
-- Mọi query đều SELECT. An toàn chạy trên prod giờ làm việc,
-- trừ Q3 (scan information_schema per-DB) — chạy giờ thấp tải.
--
-- Diễn giải: mỗi query có dòng EXPECT ngay trên nó. Lệch với
-- EXPECT nghĩa là instance chưa sẵn sàng cho flow này.
-- =========================================================

SELECT '=== Q0: YP-level artifacts ===' AS section;
-- EXPECT: cả 6 dòng đều có_không = 1
SELECT n.name,
       (SELECT COUNT(*) FROM mysql.proc p
         WHERE p.db = 'yp' AND p.name = n.name) AS co_khong
FROM (
  SELECT 'file_move_saga_begin' AS name
  UNION ALL SELECT 'file_move_saga_get'
  UNION ALL SELECT 'file_move_saga_transition'
  UNION ALL SELECT 'file_move_entity_storage'
  UNION ALL SELECT 'file_thread_lineage_resolve'
  UNION ALL SELECT 'file_thread_access_transition_direct'
) n;

-- EXPECT: cả 2 dòng = 1
SELECT t.name,
       (SELECT COUNT(*) FROM information_schema.TABLES i
         WHERE i.TABLE_SCHEMA = 'yp' AND i.TABLE_NAME = t.name) AS co_khong
FROM (
  SELECT 'file_move_saga' AS name UNION ALL SELECT 'file_thread_lineage'
) t;


SELECT '=== Q1: DB song thieu PROC ===' AS section;
-- EXPECT: 0 dong.
-- LEFT JOIN tu yp.entity (KHONG phai INNER JOIN mysql.proc) — DB thieu
-- han proc se khong co row trong mysql.proc va bi bo sot neu INNER JOIN.
--
-- Danh sach proc o day phai KHOP CHINH XAC voi query chon DB trong
-- file-move-backfill.sh va voi yp.file_move_readiness. Lech mot proc thi
-- backfill bo qua DB ma audit van bao thieu — am tham, khong bao loi.
-- (Da xay ra that tren stage voi channel_file_thread_resolve_access.)
SELECT e.db_name, e.type, e.area, FROM_UNIXTIME(e.ctime) AS created,
  MAX(p.name = 'mfs_move_all'
      AND p.body LIKE '%channel_migrate_moved_scope%')            AS move_all_new,
  MAX(p.name = 'channel_migrate_moved_scope')                     AS migrate_scope,
  MAX(p.name = 'file_move_thread_position')                       AS thread_position,
  MAX(p.name = 'channel_file_thread_rebind_returned_file')        AS rebind,
  MAX(p.name = 'file_move_source_snapshot')                       AS src_snapshot,
  MAX(p.name = 'file_move_destination_snapshot')                  AS dst_snapshot,
  MAX(p.name = 'file_move_return_precheck')                       AS return_precheck,
  MAX(p.name = 'channel_file_thread_info')                        AS ft_info,
  MAX(p.name = 'channel_file_thread_list_by_folder')              AS ft_list,
  MAX(p.name = 'channel_file_thread_ensure_root')                 AS ft_ensure,
  MAX(p.name = 'channel_file_thread_resolve_access')              AS ft_access
FROM yp.entity e
LEFT JOIN mysql.proc p ON p.db = e.db_name
WHERE e.status = 'active'
GROUP BY e.db_name, e.type, e.area, e.ctime
HAVING move_all_new = 0 OR migrate_scope = 0 OR thread_position = 0
    OR rebind = 0 OR src_snapshot = 0 OR dst_snapshot = 0
    OR return_precheck = 0 OR ft_info = 0 OR ft_list = 0
    OR ft_ensure = 0 OR ft_access = 0
ORDER BY e.ctime DESC;

-- Kiem cheo bang chinh nguon su that ma server dung
-- (_beginCrossHubMove -> yp.file_move_readiness). Neu Q1 tra 0 dong ma
-- query nay tra > 0 thi hai danh sach proc da lech nhau — sua truoc khi
-- ket luan instance da san sang.
-- EXPECT: 0
SELECT COUNT(*) AS readiness_noi_chua_san_sang FROM (
  SELECT e.db_name FROM yp.entity e
  LEFT JOIN mysql.proc p ON p.db = e.db_name
  WHERE e.status = 'active'
  GROUP BY e.db_name
  HAVING MAX(p.name='mfs_move_all'
             AND p.body LIKE '%channel_migrate_moved_scope%') = 0
      OR MAX(p.name='channel_migrate_moved_scope') = 0
      OR MAX(p.name='file_move_thread_position') = 0
      OR MAX(p.name='channel_file_thread_rebind_returned_file') = 0
      OR MAX(p.name='file_move_source_snapshot') = 0
      OR MAX(p.name='file_move_destination_snapshot') = 0
      OR MAX(p.name='file_move_return_precheck') = 0
      OR MAX(p.name='channel_file_thread_resolve_access') = 0
      OR MAX(p.name='channel_file_thread_info') = 0
      OR MAX(p.name='channel_file_thread_list_by_folder') = 0
      OR MAX(p.name='channel_file_thread_ensure_root') = 0
) x;


SELECT '=== Q2: DB song thieu BANG/COT ===' AS section;
-- EXPECT: 0 dong.
-- Quan trong: channel_migrate_moved_scope.sql:112-118 degrade IM LANG khi
-- thieu bang/cot (_thread_infra_ok=0 -> bo Step 2c/5/6). Chi kiem proc la
-- KHONG DU. Query nay nang — chay gio thap tai.
SELECT e.db_name, e.type,
  (SELECT COUNT(*) FROM information_schema.TABLES t
    WHERE t.TABLE_SCHEMA = e.db_name AND t.TABLE_NAME = 'file_thread')    AS tbl_file_thread,
  (SELECT COUNT(*) FROM information_schema.TABLES t
    WHERE t.TABLE_SCHEMA = e.db_name AND t.TABLE_NAME = 'channel_migrate_log') AS tbl_migrate_log,
  (SELECT COUNT(*) FROM information_schema.COLUMNS c
    WHERE c.TABLE_SCHEMA = e.db_name AND c.TABLE_NAME = 'channel'
      AND c.COLUMN_NAME = 'file_thread_id')                               AS col_file_thread_id
FROM yp.entity e
WHERE e.status = 'active'
HAVING tbl_file_thread = 0 OR tbl_migrate_log = 0 OR col_file_thread_id = 0
ORDER BY e.type, e.db_name;


SELECT '=== Q3: Saga ton dong ===' AS section;
-- EXPECT: chi co state committed / compensated. Bat ky state khac deu la
-- move dang do hoac da hong.
SELECT state, COUNT(*) AS so_luong,
       FROM_UNIXTIME(MIN(ctime)) AS cu_nhat,
       FROM_UNIXTIME(MAX(ctime)) AS moi_nhat
FROM yp.file_move_saga GROUP BY state ORDER BY so_luong DESC;

-- EXPECT: 0 dong. Moi dong = 1 file dang o trang thai khong xac dinh.
SELECT operation_id, state, failure_code,
       source_hub_id, source_file_nid, source_thread_id,
       destination_hub_id, destination_file_nid, destination_thread_id,
       FROM_UNIXTIME(ctime) AS bat_dau, FROM_UNIXTIME(expires_at) AS het_han
FROM yp.file_move_saga
WHERE state NOT IN ('committed', 'compensated')
ORDER BY ctime DESC;


SELECT '=== Q4: Lineage bi khoa ===' AS section;
-- EXPECT: chi co state active.
-- 'failed'/'expired' duoc file_move_saga_transition.sql:115-118 reset ve
-- active. Rieng lineage do saga 'compensation_failed' tao ra KHONG CO
-- duong go — file do bi khoa vinh vien khoi cross-hub move.
SELECT state, COUNT(*) AS so_luong FROM yp.file_thread_lineage
GROUP BY state ORDER BY so_luong DESC;

SELECT l.lineage_id, l.original_hub_id, l.original_file_nid,
       l.current_hub_id, l.current_file_nid, l.state,
       s.state AS saga_state, s.failure_code,
       FROM_UNIXTIME(l.mtime) AS sua_lan_cuoi
FROM yp.file_thread_lineage l
LEFT JOIN yp.file_move_saga s ON s.operation_id = l.current_operation_id
WHERE l.state <> 'active'
ORDER BY l.mtime DESC;


SELECT '=== Q5: file_thread mo coi ===' AS section;
-- Hau qua cua compensation that bai: media row bi mang ve nguon nhung
-- file_thread + channel rows o lai dich -> thread tro vao file khong ton tai.
-- Query nay chi in cau lenh; chay thu cong cho tung DB trong Q3.
SELECT CONCAT(
  'SELECT ''', e.db_name, ''' AS db, ft.file_nid, ft.root_message_id, ',
  '(SELECT COUNT(*) FROM `', e.db_name, '`.media m WHERE m.id = ft.file_nid) AS media_ton_tai, ',
  '(SELECT COUNT(*) FROM `', e.db_name, '`.channel c ',
  ' WHERE c.message_id = ft.root_message_id OR c.file_thread_id = ft.root_message_id) AS so_message ',
  'FROM `', e.db_name, '`.file_thread ft ',
  'HAVING media_ton_tai = 0;'
) AS chay_lenh_nay
FROM yp.entity e
WHERE e.status = 'active'
  AND e.db_name IN (
    SELECT DISTINCT destination_hub_db FROM (
      SELECT (SELECT db_name FROM yp.entity WHERE id = s.destination_hub_id) AS destination_hub_db
      FROM yp.file_move_saga s
      WHERE s.state NOT IN ('committed')
    ) x WHERE destination_hub_db IS NOT NULL
  );


SELECT '=== Q6: Tong ket ===' AS section;
SELECT
  (SELECT COUNT(*) FROM yp.entity WHERE status = 'active')                       AS db_song,
  (SELECT COUNT(*) FROM yp.file_move_saga)                                       AS saga_tong,
  (SELECT COUNT(*) FROM yp.file_move_saga WHERE state = 'committed')             AS saga_thanh_cong,
  (SELECT COUNT(*) FROM yp.file_move_saga
    WHERE state NOT IN ('committed','compensated'))                              AS saga_ton_dong,
  (SELECT COUNT(*) FROM yp.file_thread_lineage WHERE state <> 'active')          AS lineage_khoa;
