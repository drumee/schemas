---
title: "Phase 5: Kiểm chứng trên stage"
status: completed
phase: 5
priority: P1
effort: "3h"
dependencies: [4]
---

# Phase 5: Kiểm chứng trên stage

## Overview

Chứng minh cơ chế mới chạy đúng bằng dữ liệu, qua 8 ca thật. Không kết luận "chạy được" khi chỉ thấy không có lỗi.

## Requirements

**Functional**
- 8 ca test dưới đây đều pass
- Mỗi ca có số đo trước/sau, không dựa vào cảm nhận UI

**Non-functional**
- Test bằng file mới trong workspace test, không đụng dữ liệu cũ
- Mọi thao tác lên DB stage phải nói trước với user (bài học phiên trước)

## Architecture

### Bài học từ phiên trước — bắt buộc đọc

1. **Proc lineage và migrate CÓ ghi.** Gọi `channel_migrate_moved_scope` "để thăm dò" đã kéo thread thật sang đích và xoá ở nguồn. Trước khi gọi bất kỳ proc nào, đọc body xác nhận nó mutate gì.
2. **Log của service nằm ở `aaron-service-out-21.log` / `aaron-service-error-21.log`**, không phải `aaron-out-20.log`. Đọc nhầm file làm mất 30 phút.
3. **`workspace_move` sinh nid mới mỗi lần.** Thư mục vật lý CÓ đổi tên theo (`after_transact` → `move_node`, `media.js:300-322`) — giả thuyết "không đổi tên" đã bị bác bỏ bằng kiểm chứng. Lỗi 404 gặp thật là do **UI giữ nid cũ**. Ca test phải mở file **không reload trang**, mới bắt được.
4. **Trạng thái đo sau khi compensation chạy ≠ trạng thái lúc verify.** Muốn biết điều gì xảy ra tại thời điểm X, phải instrument, không suy từ trạng thái cuối.

## Related Code Files

- Không sửa. Chỉ đọc + query.
- Tạo: report tại `plans/reports/`

## Implementation Steps

### Chuẩn bị

1. Tạo workspace test riêng (hoặc dùng lại A/C nhưng file mới)
2. Upload file mới, tạo thread ≥3 message từ ≥2 tài khoản
3. Ghi lại: `file_nid`, `file_thread_id`, danh sách `message_id` + `author_id` + `ctime`

### Ca 1 — move-out cơ bản

Move A→B. Kiểm:
```sql
-- Thread PHẢI còn nguyên ở A
SELECT COUNT(*) FROM `<A>`.file_thread WHERE root_message_id='<tid>';           -- 1
SELECT COUNT(*) FROM `<A>`.channel WHERE message_id='<tid>' OR file_thread_id='<tid>'; -- = số ghi ở bước 3

-- B KHÔNG có gì
SELECT COUNT(*) FROM `<B>`.file_thread WHERE root_message_id='<tid>';           -- 0
SELECT COUNT(*) FROM `<B>`.channel WHERE message_id='<tid>' OR file_thread_id='<tid>'; -- 0

-- Lineage
SELECT state, original_hub_id, current_hub_id, current_file_nid, access_revision
FROM yp.file_thread_lineage WHERE original_thread_id='<tid>';
-- state='unavailable', original_hub_id=A, current_hub_id=B

-- Saga: bảng đã DROP ở Phase 4, query này phải báo lỗi "table doesn't exist"
-- (nếu bảng còn thì Phase 4 chưa xong)
```

UI: A → thread **vẫn hiện** trong rail, chuyển chỉ-đọc (chi tiết ở Ca 6). B → file xuất hiện, **mở được** (kiểm ảnh hiện ra, không chỉ kiểm có tile).

### Ca 2 — move-back

Move B→A. Kiểm:
- `lineage.state='active'`, `current_hub_id=A`, `current_file_nid`= nid mới
- `file_thread.file_nid` = nid mới
- `channel.metadata._file_nid` = nid mới (cả root card lẫn child)
- Số message = số ghi ở bước 3
- UI: thread mở lại được ở A, message đủ, đúng thứ tự

### Ca 3 — move sang WS thứ ba

Move A→B→C. Kiểm thread vẫn ở A, `unavailable`, `current_hub_id=C`. Rồi C→A: hồi sinh.

### Ca 4 — move cùng WS (hồi quy)

Move file có thread giữa 2 folder trong cùng WS. Kiểm:
- `file_thread_lineage` **không có row mới**
- Thread hiển thị bình thường trong rail của folder mới
- Không có event `file_thread_access_changed` nào

### Ca 5 — move folder chứa file có thread

Folder có 2 file, mỗi file 1 thread. Move folder A→B. Kiểm cả 2 thread ở lại A, `unavailable`, và cả 2 emit event.

### Ca 6 — thread chỉ-đọc hiển thị đúng (quyết định 6)

Sau Ca 1 (thread đang `unavailable` ở A), kiểm ở WS A:
- Thread **vẫn hiện** trong rail và dropdown, không biến mất
- Mở được, đọc đủ message cũ
- Card info hiện "File đã chuyển sang <tên B>"
- Composer bị chặn — thử gõ + Enter, không gửi được
- Người **tự move** không thấy popup cảnh báo

### Ca 7 — file bị xoá hẳn → orphaned (quyết định 5)

Từ trạng thái Ca 1, sang WS B **xoá hẳn** file. Kiểm:
```sql
SELECT state FROM yp.file_thread_lineage WHERE original_thread_id='<tid>';
-- 'orphaned'
```
- WS A nhận event, card info đổi thành "File đã bị xoá"
- Thread vẫn đọc được
- Không có đường ra khỏi `orphaned` — thử move gì đó về A, thread không hồi sinh

Kiểm thêm: **trash (xoá tạm)** ở B → lineage vẫn `unavailable`, không thành `orphaned`.

### Ca 8 — file mở được ngay sau move, không reload (Goal 7)

Sau mỗi ca trên, mở file trong UI **đang mở sẵn** — không F5, không đổi trang. Đây là ca bắt stale-nid.

Nếu fail, phân biệt hai nguyên nhân:
```sql
-- nid trong URL 404 có tồn tại trong DB không?
SELECT COUNT(*) FROM `<db>`.media WHERE id='<nid_trong_url>';
```
```bash
# thư mục vật lý của nid HIỆN TẠI (theo DB) có không?
ls /data/mfs/<prefix>/<hub_id>/__storage__/<nid_hien_tai>/
```

| DB có nid URL | Thư mục nid hiện tại | Kết luận |
|---|---|---|
| 0 | có | **stale-nid ở UI** — Phase 3 bước 9 chưa xong |
| 1 | không | thư mục chưa đồng bộ — bug khác, mở plan riêng |

Lần gặp thật rơi vào hàng 1.

### Kết thúc

9. Viết report với số đo 8 ca vào `plans/reports/`

## Success Criteria

- [ ] Cả 8 ca pass
- [ ] Ca 1: `channel` rows ở A **không đổi số lượng** trước/sau move
- [ ] Ca 2: message đủ, `author_id` + `ctime` khớp bản ghi ban đầu
- [ ] Ca 4: không có row lineage mới, không event — hồi quy sạch
- [ ] Ca 8: file mở được sau **mọi** lần move
- [x] `yp.file_move_saga` đã bị DROP ở `yp` lẫn `tmp_yp` — 0 bảng, 0 proc saga còn lại toàn server
- [ ] Report có số đo, không chỉ "OK"

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| Ca 8 fail — file không mở được | 404 preview | Dùng bảng phân biệt ở Ca 8 để xác định là stale-nid (Phase 3 bước 9) hay thư mục lệch. Đừng đoán |
| Ca 6 fail — thread biến mất khỏi rail | Rail rỗng sau move-out | Nguyên nhân ở `file_thread_list_by_folder` (join theo `media.parent_id`). Phase 3 bước 8 lẽ ra đã sửa — quay lại kiểm |
| Ca 7: `orphaned` không kích hoạt | Xoá file ở B nhưng lineage vẫn `unavailable` | Kiểm Phase 2 đã móc vào đúng đường xoá hẳn chưa (không phải trash) |
| Ca 4 phát hiện hồi quy | Thread biến mất khi move cùng WS | **Dừng.** Hồi quy nặng hơn cả vấn đề đang sửa. Rollback Phase 4 |
| Test làm hỏng dữ liệu như phiên trước | — | Chỉ dùng workspace + file tạo riêng. Đọc body proc trước khi gọi. Không gọi proc "để thăm dò" |

**Giả định có thể sai:** "Phase 3 đã xử lý xong phần UI". Ca 6 là phép thử. Nếu thread vẫn biến mất khỏi rail thì nguyên nhân nằm ở SQL (`file_thread_list_by_folder`), không phải JS — quay lại Phase 3 bước 8.
