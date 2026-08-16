---
title: "Phase 2: Server move-out + move-back"
status: completed
phase: 2
priority: P1
effort: "6h"
dependencies: [1]
---

# Phase 2: Server move-out + move-back

## Overview

Viết đường move mới trong `server-team`: move file bằng `mfs_move_all` thuần, rồi đánh dấu lineage và phát event. Không copy, không verify, không compensate.

## Sửa sau khi user làm rõ: nhiều thread trên cùng một file

User hỏi lại và chỉ ra thiếu sót thật: mỗi WS có thể có thread **riêng** cho cùng một file. Code lúc đó ngầm giả định mỗi file chỉ một thread trên toàn hệ thống.

Ba chỗ hỏng vì giả định đó:

| Chỗ | Lỗi | Sửa |
|---|---|---|
| `_applyFileThreadMove` | Xử lý xong thread ở đích rồi `continue` — bỏ luôn thread ở nguồn | Bỏ `continue`; mỗi move xử lý **cả hai đầu** |
| `resolve_holder` | `LIMIT 1` — chỉ thấy một thread | Trả tập hợp |
| `orphan_holder` | `LIMIT 1` — chỉ một thread thành `orphaned` | Đổi **mọi** thread đang đợi (user chốt) |

Thêm: `orphan_holder` cập nhật nhiều dòng mà `last_transition_id` là UNIQUE → mỗi dòng lấy id riêng ghép từ `lineage_id`.

**Một điều tôi từng nói sai với user:** "phải sửa chỗ tạo thread để ghi lineage". Không cần — `reserve_direct:66-81` tự `INSERT` lineage khi chưa có.

### Kiểm chứng (stage, fixture riêng, đã dọn)

| Bước | Kết quả |
|---|---|
| 1. A→B, chỉ A có thread | A `unavailable`, holder=B |
| 2. B tạo thread riêng, B→A | A `active` (rev 2), B `unavailable` → **ca từng hỏng** |
| 3. A→B lần nữa | Đảo vai: A `unavailable` (rev 3), B `active` (rev 2) |
| 4. B→C | Cả hai `unavailable`, cùng trỏ C |
| 5. Xoá hẳn ở C | `orphaned=2` — **cả hai** cùng đổi |

## Bốn phát hiện làm đổi thiết kế

**1. `reserve` và `transition` nằm hai phía của `mfs_move_all`.**
`reserve_direct` yêu cầu media row **còn** (`status NOT IN ('hidden','deleted')`, `:40`); `transition_direct` với `move_out` yêu cầu media row **đã đi**. Hai điều kiện loại trừ nhau — đúng cái bế tắc mà comment `workspace_move:1382-1389` mô tả. Không phải bế tắc thật, chỉ là thứ tự:

```
snapshot + reserve   ← file còn ở đây
mfs_move_all         ← file rời đi
transition move_out  ← file đã đi
```

Hệ quả: reserve trước move nghĩa là move fail sẽ để lineage kẹt `moving`. Nên có `_releaseFileThreadReservations` chạy ở 3 chỗ: throw, kết quả rỗng, và cuối cùng cho file không nằm trong plan (move bị từ chối một phần).

**2. `transact()` nuốt mất cặp `nid → des_id`.**
Nó trả kết quả của `after_transact`, chỉ gồm hàng nhánh `show`. Cặp nid cũ→mới nằm ở hàng `action='move'` của `_final_media`. Thêm `this.heap.movePlan` giữ lại bản thô, không đổi giá trị trả về.

**3. `file_move_source_snapshot` vô dụng sau move.**
`INNER JOIN media` + `status NOT IN ('hidden','deleted')` → sau move trả rỗng. Phải chụp **trước**.

**4. `_purge()` là code chết.**
Không ai gọi (`grep` toàn repo). Xoá hẳn thật sự đi qua `purge()` → `mfs_delete_trash` (xoá DB row) → `_empty_bin` → tiến trình con `offline/media/purge.js` (chỉ xoá file vật lý). Móc orphan vào `purge()`, không phải `_purge()`.
Thêm: `mfs_delete_trash` **không** trả `hub_id` — lấy từ ngữ cảnh request.

### Proc mới: `channel_file_thread_list_in_subtree`

`channel_file_thread_list_by_folder` không dùng được: nhận **4 tham số** (không phải 2), chỉ liệt kê **con trực tiếp**, và **có phân trang** — thư mục lồng nhau sẽ sót thread.

Proc mới duyệt theo `parent_id` (không dùng `parent_path` — đường dẫn tên, rename là đổi), giới hạn 64 tầng chống chu trình. Kiểm chứng: file lẻ, thư mục cha, gốc hub (21ms), và cây 4 tầng — gom đủ cả 2 thread.

## Requirements

**Functional**
- Move file có thread sang WS khác: file sang, thread ở lại `unavailable`, emit `revoked` cho WS nguồn
- Move file về đúng WS gốc: thread `active`, rebind nid mới, emit `restored`
- Move folder chứa file có thread: cùng ngữ nghĩa, mỗi file có thread được xử lý riêng
- Move cùng WS: **không đụng gì** — thread tự đi theo `media.parent_id`
- **File bị xoá ở WS đang giữ** (trash/remove) mà lineage đang `unavailable` → chuyển `orphaned`, emit event

**Non-functional**
- Payload event mang đủ `reason` (`move_out`/`orphaned`) + `actor` — Phase 3 cần để tách nhánh và lọc popup
- Không có bước nào chép message cross-DB
- Thất bại ở bước đánh dấu lineage **không** làm hỏng move (file đã sang là chuyện đã rồi) — nhưng phải log rõ

## Architecture

### Luồng move-out

```
1. mfs_move_all (đường move thường, KHÔNG gọi channel_migrate_moved_scope)
2. với mỗi file có thread trong tập vừa move:
   a. file_thread_access_reserve_direct(... 'move_out')   → state='moving'
   b. file_thread_access_transition_direct(... 'unavailable', 'move_out')
      → state='unavailable', access_revision++
   c. emit channel.file_thread_access_changed
      { state:"revoked", reason:"move_out", hub_id: <WS gốc>,
        file_nid, file_thread_id, access_revision, actor, filename }
      → sockets của WS GỐC
3. emit media.move / media.remove như move thường
```

Thứ tự bắt buộc: `mfs_move_all` **trước**, transition **sau** — vì guard `unavailable` yêu cầu media row đã rời DB nguồn (xem Phase 1 Architecture).

### Luồng move-back

```
1. TRƯỚC khi move, tra theo vị trí HIỆN TẠI của file:
   SELECT * FROM file_thread_lineage
    WHERE current_hub_id = <WS hiện tại> AND current_file_nid = <nid hiện tại>
   → có row, state='unavailable', original_hub_id = <WS đích>  ⇒ đây là move-back
2. mfs_move_all đưa file về
3. nếu bước 1 xác định là move-back:
   a. channel_file_thread_rebind_returned_file(original_nid, new_nid, thread_id)
   b. file_thread_access_transition_direct(... 'active', 'move_back')
      → state='active', cập nhật current_hub_id/current_file_nid
   c. emit { state:"restored", previous_file_nid: <nid cũ>, file_nid: <nid mới> }
      → sockets WS GỐC
```

### Điểm cần giải quyết: nhận diện "về đúng nhà"

Move-back cần biết file đang về **có phải file mà thread đang chờ không**. Nhưng nid đổi mỗi lần cross-hub, nên không so nid trực tiếp được.

Hai hướng:

**A. Tra qua lineage `current_*`** — trước khi move, tra `file_thread_lineage WHERE current_hub_id = <WS hiện tại> AND current_file_nid = <nid hiện tại>`. Nếu có, `state='unavailable'`, và `original_hub_id = <WS đích>` → đây là move-back.

**B. Cột riêng** trên `media` ở WS đích ghi nguồn gốc. Thêm schema, không nên.

→ Chọn **A**. Phase 1 đã ghi rõ ngữ nghĩa: `original_*` = thread ở đâu (bất biến), `current_*` = file đang ở đâu (đổi mỗi lần move, cả `move_out` lẫn `move_back`). Có `UNIQUE KEY (current_hub_id, current_file_nid)` nên tra là O(1) và không nhập nhằng.

### Move folder

`mfs_move_all` trả `_final_media` liệt kê mọi node đã move. Lọc `category NOT IN ('folder','hub')`, với mỗi file kiểm có thread không (`channel_file_thread_info` hoặc query `file_thread` trực tiếp), rồi áp dụng move-out cho từng cái.

### File bị xoá ở WS đang giữ → `orphaned`

Thread đang `unavailable` chờ file quay về. Nếu file bị xoá hẳn ở WS mới thì không còn cơ hội — thread phải biết.

Điểm bám: `trash()` (`media.js:2143`) và các đường `media.remove`. Sau khi xoá thành công:

```
1. file_thread_lineage_resolve_position(<WS hiện tại>, <nid vừa xoá>)
2. có row và state='unavailable':
   a. transition_direct(... 'orphaned', 'orphaned')
   b. emit channel.file_thread_access_changed
      { state:"orphaned", reason:"orphaned", hub_id: <WS GỐC của thread>,
        file_nid: <original_file_nid>, file_thread_id, access_revision }
      → sockets WS GỐC (không phải WS vừa xoá file)
```

Lưu ý: event gửi tới **WS gốc** — nơi thread đang nằm — chứ không phải WS vừa xoá file. Người ở WS gốc là người cần biết.

Trash (xoá tạm) vs remove (xoá hẳn) khác nhau: trash còn khôi phục được, nên **chỉ chuyển `orphaned` khi xoá hẳn**. Trash thì giữ `unavailable`.

## Related Code Files

- Sửa: `server-team/service/private/media.js`
  - `move_cross_hub()` → viết lại thành đường mới, hoặc thay bằng `workspace_move` mở rộng
  - `workspace_move()` → thêm xử lý thread (hiện comment `:1336-1341` nói không làm được — giờ làm được vì không cần migrate)
  - Gỡ `TEMP-DIAG` log đã thêm khi chẩn đoán
- Đọc: `server-team/service/private/media.js:2186-2211` (pattern trash), `:1739` (pattern restore)
- Không sửa: `ui-team/src/drumee/builtins/window/folder/file-thread-access.js`

## Implementation Steps

1. **Viết helper `_fileThreadsInMovedSet(movePlan, srcDb)`** — từ kết quả `mfs_move_all`, trả danh sách file có thread kèm `file_thread_id`.
2. **Viết `_markThreadMovedOut(target)`** — reserve → transition → emit `revoked`. Mô phỏng `media.js:2186-2211` nhưng reason `move_out`.
3. **Viết `_markThreadMovedBack(target)`** — rebind → transition → emit `restored` kèm `previous_file_nid`.
4. **Sửa `workspace_move()`** — sau `transact("mfs_move_all")`, gọi resolve_home để phân loại từng file: về nhà → `_markThreadMovedBack`, đi khỏi nhà → `_markThreadMovedOut`.
5. **Viết `_markThreadOrphaned(target)`** — gọi từ đường xoá hẳn file. Chỉ chạy khi `resolve_position` trả lineage `unavailable`.
6. **Móc vào đường xoá** — `trash()` giữ `unavailable` (còn khôi phục được); chỉ đường xoá hẳn mới chuyển `orphaned`.
7. **Quyết định số phận `move_cross_hub()`** — xem Phase 4. Tạm thời giữ nguyên, chưa gỡ.
8. **UI**: `selectCrossWorkspaceMoveService()` (`ui-team/.../file-thread-move-route.js`) hiện chọn `move_cross_hub` khi có thread. Sau khi `workspace_move` xử lý được thread, hàm này **không còn cần** — luôn dùng `workspace_move`. Sửa ở Phase 4.

`TEMP-DIAG` đã gỡ khỏi `media.js` và stage — không còn việc này.

## Success Criteria

Đã kiểm chứng ở tầng SQL trên stage (fixture riêng, đã dọn):

- [x] Chuỗi `reserve → move → transition` chạy đúng thứ tự, `APPLIED`, `holder_*` ghi đúng (E2, E3, E4)
- [x] Thread + message **ở lại DB nguồn**, `file_thread` còn nguyên sau move-out (E5)
- [x] `file_thread_lineage`: `state='unavailable'`, `holder_hub_id`=WS đích, `current_*` giữ nguyên
- [x] `channel_file_thread_list_in_subtree` gom đủ thread ở cây 4 tầng (S4, S5)
- [x] Deploy stage: `node --check` sạch, service online, log khởi động không lỗi mới

Còn phải kiểm qua UI thật (Phase 5) — những mục này chưa chạm tới:

- [ ] Move file có thread A→B qua giao diện: WS A nhận `revoked`, WS B **không** nhận `restored`
- [ ] Move back B→A: `state='active'`, thread mở được, message đủ, `metadata._file_nid` = nid mới
- [ ] Move A→B→C→A: thread vẫn hồi sinh khi về A
- [ ] Move cùng WS: `file_thread_lineage` không có row mới, thread hiển thị bình thường
- [ ] Move folder chứa 2 file có thread: cả 2 thread xử lý đúng
- [ ] Xoá hẳn file ở WS đang giữ → lineage `orphaned`, WS gốc nhận event
- [ ] Trash (xoá tạm) ở WS đang giữ → lineage vẫn `unavailable`, không chuyển `orphaned`
- [ ] `yp.file_move_saga` **không có dòng mới**
- [ ] Move bị từ chối giữa chừng → không còn lineage nào kẹt `moving`

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| `mfs_move_all` xong nhưng đánh dấu lineage fail | Thread vẫn `active` dù file đã đi | Log rõ, không rollback move. Thread `active` trỏ file không tồn tại = UI hiện card gạch — chấp nhận được, hơn hẳn mất message. Có thể thêm job dọn sau |
| Nhận diện move-back sai → thread hồi sinh nhầm file | Thread gắn vào file khác | `channel_file_thread_rebind_returned_file` có guard `THREAD_LINEAGE_MISMATCH`, `DESTINATION_THREAD_CONFLICT` — dùng lại nguyên, không nới |
| Move folder có nhiều file thread, một cái fail | Một thread không đánh dấu | Xử lý từng file độc lập, log cái fail. Không abort cả folder |
| `workspace_move` là đường dùng chung, sửa gây hồi quy | Move thường lỗi | Nhánh thread chỉ chạy khi file CÓ thread. File không thread đi đường cũ nguyên vẹn |
| UI popup hiện cho người **thực hiện** move (đáng ra chỉ người khác thấy) | User tự move rồi bị popup "mất quyền" | Kiểm `actor` trong payload — `file-thread-access.js` hiện không lọc theo actor. Có thể cần bổ sung, xem Open Question |

**Giả định đã bị bác bỏ:** ban đầu plan cho rằng "event contract giữ nguyên → UI không cần sửa". Sai — `file-thread-access.js` viết cho ngữ cảnh mất quyền (ẩn thread), còn move-out cần giữ hiển thị chỉ-đọc. Phase 3 dành riêng cho phần UI này.

Điều Phase 2 phải đảm bảo: payload event mang đủ `reason` (`move_out`/`orphaned`) và `actor` để Phase 3 tách nhánh và lọc popup được.
