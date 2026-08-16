---
title: "Phase 1: Schema + procs"
status: completed
phase: 1
priority: P1
effort: "4h"
dependencies: []
---

# Phase 1: Schema + procs

## Overview

Mở rộng lineage procs để phục vụ được move, không chỉ trash. Phần SQL thuần — chưa đụng server code.

## Thiết kế đã đổi sau khi đọc source (bằng chứng, không phải giả định)

Plan ban đầu định **cập nhật `current_hub_id`/`current_file_nid`** cho cả `move_out` và `move_back`. Đọc source thật cho thấy làm vậy sẽ hỏng. Bốn phát hiện:

**1. `current_*` không thể mang nghĩa "file ở đâu".**
`file_thread_lineage` có `UNIQUE KEY (current_hub_id, current_file_nid)`. Nếu `move_out` trỏ cặp này sang WS đích, thì một thread mới tạo trên file đó **ở WS đích** sẽ đụng khoá. Thêm cặp cột riêng: `holder_hub_id`/`holder_file_nid` = **file ở đâu**, NULL khi file ở nhà. `current_*` giữ nguyên nghĩa cũ = **thread ở đâu**.

**2. `(current_hub_id, current_thread_id)` KHÔNG unique.**
Dữ liệu stage có 2 dòng cùng `current_thread_id='1512212315122125'`, một dòng là rác từ lần move fail (`current_file_nid='8c8ffd8c...'` không còn trong `media`). Định vị theo thread id sẽ chọn nhầm dòng **theo may rủi**. Mọi tra cứu đi qua `current_file_nid` (có UNIQUE) hoặc `holder_*`.
→ Cũng vì vậy `channel_file_thread_info` join theo `ft.file_nid`, không theo `root_message_id`.

**3. `move_back` bắt buộc đổi `current_file_nid`.**
File quay về là node MỚI (`mfs_create_node`), đúng như `channel_file_thread_rebind_returned_file` đã trỏ lại `file_thread`. Đây là **reason duy nhất** đổi `current_file_nid`, và cũng là lý do nó phải resolve qua `holder_*` chứ không qua `_file_nid` (nid mới chưa khớp gì cả).

**4. `entity.headline`/`ident` rỗng 687/687 hub.**
Tên WS thật nằm ở `yp.hub.profile->>'$.name'` (đúng cách `media.js:416` đang làm). Đích của move còn có thể là **drumate** (personal space) — không có row trong `yp.hub` — nên phải fallback sang `yp.drumate.firstname/lastname`. Kiểm chứng: hub → `"Internal Workspace"`, drumate → `"Salvatore Phuong Hoa"`.

Ngoài ra guard cũ `(_target_state='unavailable' AND @_direct_media_id IS NOT NULL)` **không dùng chung được** cho trash và move: trash giữ media row (`status='hidden'`), move **xoá hẳn** (`mfs_move_all.sql:230`). Guard tách theo `reason`.

## Requirements

**Functional**
- `file_thread_access_transition_direct` chấp nhận `reason IN ('move_out','move_back','orphaned')`
- **Cả `move_out` lẫn `move_back`** cập nhật `current_hub_id`/`current_file_nid` về vị trí mới của FILE
- Thêm giá trị enum `orphaned` vào `file_thread_lineage.state` — trạng thái cuối khi file bị xoá hẳn
- Có proc tra lineage theo `original_hub_id` + `original_file_nid` để nhận diện "file về đúng nhà"
- `channel_file_thread_info` trả thêm `lineage_state` + tên WS đang giữ file (Phase 3 cần)

### Ngữ nghĩa hai cặp cột (quan trọng)

| Cột | Nghĩa |
|---|---|
| `original_hub_id`, `original_file_nid` | **thread ở đâu** — bất biến, là "nhà" |
| `current_hub_id`, `current_file_nid` | **file đang ở đâu** — đổi mỗi lần move |

Phân biệt này là điều kiện để Phase 2 nhận diện move-back: tra lineage theo `current_*` (file đang ở đâu), rồi so `original_hub_id` với WS đích. Trùng → file đang về nhà.

Với `direct_trash`/`direct_restore` thì `current_* = original_*` luôn, nên hành vi cũ không đổi.

**Non-functional**
- Không phá luồng trash/restore đang chạy — `direct_trash`/`direct_restore` giữ nguyên hành vi
- Idempotent (`DROP IF EXISTS` + `CREATE`), một routine một file (`schemas/CLAUDE.md`)

## Architecture

### Guard hiện tại và move

`file_thread_access_transition_direct.sql:60-66`:

```sql
IF @_direct_thread_id IS NULL
   OR (_target_state = 'unavailable' AND @_direct_media_id IS NOT NULL)
   OR (_target_state = 'active' AND @_direct_media_id IS NULL) THEN
  → DURABLE_STATE_MISMATCH
```

Trash: media row **còn** trong DB (chỉ `status='hidden'`), và proc được gọi **sau** `mfs_pre_trash_next` (xem `media.js:2196-2211`) — lúc đó row đã ẩn nên `@_direct_media_id` (query có `status NOT IN ('hidden','deleted')` ở reserve, nhưng transition thì không lọc status) — **cần đọc kỹ lại điểm này khi implement**, hai proc lọc khác nhau.

Move cross-hub: media row **biến mất khỏi DB nguồn**. Nên:
- `move_out` gọi **sau** `mfs_move_all` → `@_direct_media_id IS NULL` → thoả guard `unavailable`
- `move_back` gọi **sau** `mfs_move_all` đưa file về → `@_direct_media_id IS NOT NULL` → thoả guard `active`

Thứ tự này Phase 2 chịu trách nhiệm. Guard có thể giữ nguyên — bước 7 kiểm chứng.

### Vì sao phải cập nhật `current_*`

`UPDATE file_thread_lineage` (`:101-113`) chỉ đổi `state`, `current_operation_id`, `last_transition_*`, `access_revision`, `mtime`. **Không đụng** `current_hub_id`/`current_file_nid` — đúng cho trash (file không đi đâu).

Move thì nid đổi mỗi lần cross-hub (quan sát thật: `d99275b7` → `8c8ffd8c` → `a54784bd` → `c7e386aa`). Không cập nhật thì lineage trỏ nid chết, lần move sau tra không ra.

### Trạng thái cuối `orphaned`

`state` hiện là `enum('active','moving','unavailable','conflict','failed')`.

`unavailable` = tạm thời, file ở WS khác, còn cơ hội về. File bị xoá hẳn → cơ hội mất → cần trạng thái cuối phân biệt được.

Chọn **thêm giá trị `orphaned`** thay vì dùng lại `failed` — `failed` đang mang nghĩa "saga hỏng", trộn hai ngữ nghĩa sẽ khó đọc về sau. `file_thread_lineage` chỉ tồn tại trong `yp` (DB đơn), nên `ALTER TABLE` một lần, rẻ.

Chuyển tiếp hợp lệ: `unavailable → orphaned`. Không có đường ra khỏi `orphaned` (file đã xoá thì không về được).

### Các proc

| Proc | Vai trò |
|---|---|
| `file_thread_access_transition_direct` (sửa) | thêm `move_out`/`move_back`/`orphaned`; hai nhánh move cập nhật `current_hub_id`/`current_file_nid` |
| `file_thread_access_reserve_direct` (sửa) | nhận `move_out` — đặt `state='moving'` + `current_operation_id` trước khi move |
| `file_thread_lineage_resolve_home` (mới) | tra lineage theo `(original_hub_id, original_file_nid)`, `state IN ('unavailable')`. Read-only |
| `file_thread_lineage_resolve_position` (mới) | tra theo `(current_hub_id, current_file_nid)` — Phase 2 dùng để nhận diện move-back và phát hiện file bị xoá. Read-only |
| `channel_file_thread_info` (sửa) | trả thêm `lineage_state`, `holder_hub_name` — Phase 3 hydrate card info |
| `file_thread_lineage` (sửa bảng) | thêm `orphaned` vào enum `state` |

`channel_file_thread_rebind_returned_file` **dùng lại nguyên, không sửa** — đã hoạt động, compensation từng gọi thành công.

## Related Code Files

Thực tế đã làm:

- Sửa: `yellow_page/tables/file_thread_lineage.sql` — `orphaned` + `holder_hub_id`/`holder_file_nid`
- Tạo: `patches/260812-file-thread-lineage-holder.sql` — `ALTER TABLE` cho DB đang chạy
- Sửa: `yellow_page/procedures/mfs/file_thread_access_transition_direct.sql` — thêm 2 tham số `_holder_*`
- Tạo: `yellow_page/procedures/mfs/file_thread_lineage_resolve_holder.sql`
- Tạo: `yellow_page/procedures/mfs/file_thread_lineage_track_holder.sql` — hop sang WS thứ ba
- Tạo: `yellow_page/procedures/mfs/file_thread_lineage_orphan_holder.sql`
- Sửa: `common/procedures/channel/channel_file_thread_info.sql` — `lineage_state` + `holder_hub_name`
- **Không sửa**: `file_thread_access_reserve_direct.sql` — proc không có tham số `reason`, và `move_out` cần đúng ngữ nghĩa nó đang có (`active → moving`). Plan ban đầu tưởng phải sửa.
- Đọc, không sửa: `channel_file_thread_rebind_returned_file.sql`
- Cập nhật: `patches/manifest.txt` (+3 dòng; `channel_file_thread_info` đã có sẵn)

Khác plan: `lineage_resolve_home`/`lineage_resolve_position` **không tạo**. `resolve_position` trùng `file_thread_lineage_resolve` đã có; `resolve_home` thì `resolve_holder` làm đúng việc cần hơn — Phase 2 hỏi "file đang ở đây có thread lạc ở đâu không", không phải "thread này nhà ở đâu".

## Implementation Steps

1. **Đọc trước khi sửa** — `file_thread_access_transition_direct.sql` toàn bộ, đặc biệt khối CAS `:101-113`, guard `:60-66`, và so sánh cách reserve vs transition lọc `media.status` (khác nhau).
2. **Mở rộng whitelist reason** cả hai proc: `IN ('direct_trash','direct_restore','move_out','move_back')`.
3. **Nhánh move** — với `move_out` VÀ `move_back`, thêm `current_hub_id = _hub_id, current_file_nid = _file_nid` vào `UPDATE` (vị trí mới của file). `direct_trash`/`direct_restore` giữ nguyên, không đụng.
4. **Điều chỉnh CAS predicate** — hiện `WHERE ... current_file_nid = _file_nid`. Với cả hai nhánh move, `_file_nid` là nid MỚI, chưa khớp lineage. Phải khoá theo `lineage_id` (caller truyền vào, đã resolve từ trước) thay vì `current_file_nid`.
   **Cẩn thận:** đây là nới lỏng CAS. Phải giữ điều kiện `state = _expected_state` và `current_operation_id` để không mất bảo vệ chống race.
5. **`ALTER TABLE` thêm `orphaned`** vào enum `state`. Viết patch file riêng cho DB đang chạy, và sửa cả `tables/file_thread_lineage.sql` cho DB tạo mới.
6. **Viết `file_thread_lineage_resolve_home`** — input `(_hub_id, _file_nid)`, trả lineage có `original_hub_id=_hub_id AND original_file_nid=_file_nid AND state='unavailable'`. Chỉ SELECT.
7. **Viết `file_thread_lineage_resolve_position`** — input `(_hub_id, _file_nid)`, trả lineage theo `current_*`. Phase 2 dùng để phân biệt move-out/move-back và phát hiện file bị xoá.
8. **Mở rộng `channel_file_thread_info`** — thêm `lineage_state` và tên WS đang giữ file. Chỉ **thêm** cột, không đổi cột cũ (proc này có nhiều consumer).
9. **Thêm mọi file vào `patches/manifest.txt`** đúng thứ tự phụ thuộc.
10. **Test trên stage** — chỉ trên workspace tạo riêng. Trước khi gọi bất kỳ proc nào, đọc body xác nhận nó ghi gì.

## Success Criteria

Tất cả đã kiểm chứng trên stage (fixture riêng, đã dọn; 9 dòng lineage thật nguyên vẹn).

- [x] `move_out` trả `transitioned=1` khi media row đã rời DB nguồn, ghi `holder_hub_id`/`holder_file_nid`, **giữ nguyên** `current_*` (R3)
- [x] `move_out` **bị từ chối** khi file chưa rời đi → `DURABLE_STATE_MISMATCH` (R2)
- [x] `move_back` xoá `holder_*` và trỏ `current_file_nid` sang nid mới (M1, M2)
- [x] `original_hub_id`/`original_file_nid` **không đổi** qua mọi transition (M2)
- [x] `lineage_resolve_holder` trả đúng theo `(holder_hub, holder_nid)`, rỗng khi sai cặp (H3, H4)
- [x] `track_holder` xử lý hop sang WS thứ ba, giữ `unavailable`, tăng `access_revision` (H1)
- [x] `track_holder` **từ chối** thread đang ở nhà → `HOLDER_CAS_MISMATCH` (H2)
- [x] `state` enum có `orphaned`; `unavailable → orphaned` được, **không có đường ra** (O2, G1b)
- [x] `orphan_holder` idempotent — gọi lần hai trả `NO_LINEAGE`, không ghi đè (O3)
- [x] `reserve_direct` trên thread `orphaned` → `LINEAGE_BUSY` (G2b)
- [x] `channel_file_thread_info` trả thêm `lineage_state` + `holder_hub_name`, **không phá** consumer cũ (T6, T7, T8)
- [x] `holder_hub_name` đúng cho cả hub (`"Internal Workspace"`) lẫn drumate (`"Salvatore Phuong Hoa"`) (R5b)
- [x] **Hồi quy trash/restore**: `unavailable` → `active`, `holder_*` giữ NULL, `current_file_nid` không đổi (TR1–TR5)
- [x] 5 guard đầu vào từ chối sạch, không ghi gì (T1–T5)
- [x] Mọi file mới có trong `patches/manifest.txt`
- [x] Proc mới chỉ ghi vào `file_thread_lineage`, không đụng `channel`/`media`

### Đã sửa trong lúc test

`move_back` trên thread `orphaned` từng trả `LINEAGE_NOT_TRACKED` ("không có thread này") thay vì `LINEAGE_ORPHANED` ("file đã bị xoá") — vì mệnh đề resolve chỉ khớp `state='unavailable'`. Cả hai đều từ chối move, nhưng chỉ một cái debug được. Đã thêm `orphaned` vào mệnh đề khớp, `ORDER BY FIELD(state,...)` để `unavailable` luôn được ưu tiên.

Một lần test cho kết quả sai vì **fixture của tôi sai**, không phải proc: tôi trỏ `file_thread.file_nid` sang một nid mà lineage không biết — trạng thái luồng thật không tạo ra được. Dựng lại fixture đúng thì cả ba kết quả đều đúng.

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| Sửa proc làm hỏng trash đang chạy | Xoá file → thread không thành `unavailable` | Test hồi quy **trước** khi sang Phase 2. Snapshot proc cũ trước khi ghi |
| CAS predicate sai → transition im lặng không áp dụng | `transitioned=0`, `status='CAS_MISMATCH'` | Test phải kiểm `transitioned=1`, không chỉ `failed=0` |
| Gọi proc test làm hỏng dữ liệu thật | — | **Bài học phiên trước**: proc lineage CÓ ghi, và `channel_migrate_moved_scope` từng kéo thread thật đi khi tôi gọi thử. Chỉ test trên workspace tạo riêng; đọc body proc trước khi gọi |
| `move_back` gọi khi lineage vẫn `active` | `status='DIRECT_STATE_CONFLICT'` | Đúng thiết kế — Phase 2 chỉ gọi sau khi `resolve_home` trả kết quả |

**Giả định có thể sai:** "guard hiện tại dùng được cho move nếu đúng thứ tự gọi". Bước 7 kiểm chứng. Nếu sai → tách guard theo `reason` thay vì dùng chung.
