---
title: "Thread stays in original workspace on cross-hub move"
description: "Bỏ migrate thread cross-DB; thread ở lại WS gốc dạng unavailable, chỉ hồi sinh khi file quay về đúng WS đó"
status: pending
priority: P1
effort: "2-3d"
tags: [mfs, file-thread, cross-hub-move, simplification]
created: 2026-08-12
---

# Thread stays in original workspace on cross-hub move

## Overview

Thay cơ chế **migrate thread cross-DB** (saga 9 trạng thái + proc 1200 dòng) bằng cơ chế **thread ở lại WS gốc** — tái dùng nguyên hạ tầng lineage đang chạy tốt cho trash/restore.

### Vì sao đổi

Cơ chế migrate **chưa từng chạy thành công một lần nào**. `yp.file_move_saga` trên stage không có dòng `state='committed'`.

Chẩn đoán cuối cùng, từ log instrument trực tiếp (`operation_id: aNPASi8T7rYo5Hjr`):

```
destinationFileNid: "c7c06a0fc7c06a14"   ← findMfsMoveResult ĐÚNG
sourcePosition:     null                  ← nguồn sạch, ĐÚNG
destinationPosition: null                 ← ĐÍCH KHÔNG CÓ file_thread row
check_base: FILE_NOT_FOUND { nid: 'c7c06a0fc7c06a14',
  mfs_root: '/data/mfs/fb61/fb610c4ffb610c57//__storage__/' }
```

`channel_migrate_moved_scope` không tạo được `file_thread` ở đích, và `channel_migrate_log` **rỗng cả hai DB** — lỗi bị `CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END` (`mfs_move_all.sql:283`) nuốt sạch, không để lại dấu vết.

Đã loại trừ hết: proc/bảng/cột đủ (backfill 144 DB xong, `readiness=1`), `findMfsMoveResult` đúng, không phải timing. Còn lại đúng một nguyên nhân: **migrate thread cross-DB không hoạt động**, và mỗi lần fail đều đi vào compensation — nơi từng làm mất file.

### Cơ chế thay thế đã có sẵn

Luồng trash/restore **đang chạy tốt** với đúng ý tưởng này:

| Hành động | Thread | Vị trí code |
|---|---|---|
| Xoá vào trash | ở lại, `state='unavailable'`, `reason='direct_trash'` | `media.js:2186-2211` |
| Khôi phục | hồi sinh, `state='active'`, `reason='direct_restore'` | `media.js:1739`, `1851` |

`yp.file_thread_lineage` đã có gần đủ: `state enum('active','moving','unavailable','conflict','failed')` (thêm `orphaned` ở Phase 1), `original_hub_id`/`original_file_nid` (thread thuộc về đâu), `access_revision` (sắp thứ tự sự kiện, UI đã dùng).

UI có sẵn hạ tầng event: `file-thread-access.js` (541 dòng) nhận `channel.file_thread_access_changed`, xử lý revision ordering, freeze, rebind card. Nhưng hành vi hiện tại là **ẩn** thread — Phase 3 tách nhánh để move-out giữ hiển thị chỉ-đọc.

### Ngữ nghĩa mới

**Mỗi WS có thread riêng cho cùng một file.** File ở đâu thì thread ở đó mở khoá; các thread khác ngủ.

| File đang ở | Thread A | Thread B |
|---|---|---|
| A | 🔓 `active` | 🔒 `unavailable` |
| B | 🔒 `unavailable` | 🔓 `active` |
| C (WS thứ ba) | 🔒 | 🔒 |
| bị xoá hẳn | `orphaned` | `orphaned` |

| Tình huống | Thread |
|---|---|
| Move file trong cùng WS (folder → folder) | **đi theo file** — giữ nguyên như hiện tại, không đụng |
| Move file sang WS khác | thread WS nguồn **ở lại**, `unavailable`, chỉ-đọc; emit `revoked` |
| Move file tới WS có thread cũ | thread WS đó **hồi sinh**, `active`; emit `restored` |
| Một lần move | xử lý **cả hai đầu**: khoá nơi file rời đi, mở nơi file đến |
| Move sang WS thứ ba | mọi thread vẫn `unavailable`, chỉ cập nhật "file đang ở đâu" |
| Move folder chứa file có thread | **giống move file** — mỗi file xử lý riêng |
| File **xoá hẳn** ở WS đang giữ | **mọi** thread đang đợi → `orphaned` (trạng thái cuối) |

Không cần đụng chỗ tạo thread: `file_thread_access_reserve_direct` (`:66-81`) tự tạo dòng lineage khi chưa có, ngay lúc move đầu tiên của thread đó.

Đánh đổi: người ở WS đích không thấy thread. Chấp nhận được — thread là hội thoại của team cũ.

**Lợi ích quyết định: message không bao giờ rời DB gốc.** Không có bước nào có thể làm mất dữ liệu.

## Quyết định thiết kế (đã chốt với user)

1. Move cùng WS: giữ nguyên
2. Move folder: cùng ngữ nghĩa với move file
3. Dữ liệu đã lỡ migrate: dọn
4. `channel_migrate_moved_scope`: **xoá lời gọi khỏi `mfs_move_all`, giữ file proc** (lý do ở Phase 4)
5. **File bị xoá hẳn ở WS mới** → thread chuyển **trạng thái cuối**, không giữ `unavailable` mãi
6. **Thread `unavailable` PHẢI hiện lên** — card info trong chat, không ẩn
7. `yp.file_move_saga` + proc saga: **xoá**

### Chi tiết quyết định 5 — trạng thái cuối

`file_thread_lineage.state` hiện là `enum('active','moving','unavailable','conflict','failed')`.

`unavailable` = tạm thời, file đang ở WS khác, còn cơ hội quay về. Khi file bị xoá hẳn thì cơ hội đó mất → cần trạng thái cuối, phân biệt được với `unavailable`.

Chọn **thêm giá trị enum `orphaned`** thay vì dùng lại `failed` — `failed` đang mang nghĩa "saga hỏng", trộn hai ngữ nghĩa sẽ khó đọc về sau. `file_thread_lineage` chỉ tồn tại trong `yp` (DB đơn) nên `ALTER TABLE` một lần, rẻ.

Đường kích hoạt: khi file bị **xoá hẳn** ở WS đang giữ, kiểm lineage theo `current_hub_id`/`current_file_nid`. Có và đang `unavailable` → chuyển `orphaned`, emit event tới **WS gốc** để card info cập nhật.

**Trash (xoá tạm) không kích hoạt** — còn khôi phục được nên giữ `unavailable`.

### Chi tiết quyết định 6 — card info phải hiện

Hiện `file-thread-access.js` **ẩn** thread không truy cập được: cards `data-ft_available=0`, tên file gạch ngang (`ftc-unavailable`), thread không mở được.

Với move-out thì khác: thread vẫn còn nguyên, chỉ file đi chỗ khác. Người dùng **phải đọc lại được** hội thoại cũ.

Cần:
- Thread `unavailable` vẫn **liệt kê trong rail/dropdown**, không biến mất
- Mở được, đọc được message cũ
- **Card info** (`_fillFileInfoCard`, `folder/index.js:3523`) hiện trạng thái: "File đã chuyển sang workspace khác" + tên WS đích nếu đọc được
- **Chặn gửi tin mới** — thread đóng băng, chỉ đọc
- Với `orphaned`: card ghi "File đã bị xoá"

Đây là **thay đổi UI thật**, khác giả định ban đầu "UI không cần sửa" — nên Phase 3 dành riêng cho nó.

## Khoảng trống kỹ thuật (đã giải quyết ở Phase 1)

Giả định ban đầu — "dùng `current_*` để ghi vị trí mới của file" — **sai**, phát hiện khi đọc source. `UNIQUE KEY (current_hub_id, current_file_nid)` sẽ bị đụng khi WS đích tạo thread mới trên chính file đó.

Thiết kế thực tế: **thêm cặp cột `holder_*`**.

| Cột | Nghĩa | Đổi khi |
|---|---|---|
| `original_hub_id`, `original_file_nid` | thread sinh ra ở đâu | không bao giờ |
| `current_hub_id`, `current_file_nid` | **thread đang ở đâu** | chỉ `move_back` (file về là node mới) |
| `holder_hub_id`, `holder_file_nid` | **file đang ở đâu**, NULL = ở nhà | `move_out`, mỗi hop |

Nhận diện move-back: tra `resolve_holder(hub_đích, nid)`. Có kết quả và `current_hub_id` = WS đích → file về nhà.

Ba điểm nữa từ source (chi tiết + bằng chứng ở Phase 1):
- `(current_hub_id, current_thread_id)` **không unique** — stage có 2 dòng trùng, một là rác. Mọi tra cứu đi qua `current_file_nid` hoặc `holder_*`
- Guard media khác nhau theo reason: trash **giữ** row (`hidden`), move **xoá** row (`mfs_move_all.sql:230`)
- Tên WS lấy từ `yp.hub.profile->>'$.name'`, fallback `yp.drumate` — `entity.headline` rỗng 687/687

## Goals

| # | Goal | Priority |
|---|------|----------|
| 1 | Move cross-WS không còn đụng vào message — thread ở lại WS gốc | P1 |
| 2 | Move back đúng WS gốc → thread hồi sinh, verified | P1 |
| 3 | Bỏ đường migrate cross-DB khỏi luồng move | P1 |
| 4 | Dọn dữ liệu mồ côi từ các lần migrate fail | P2 |
| 5 | Thread `unavailable` đọc được ở WS gốc, card info nói rõ file đã đi đâu | P1 |
| 6 | File bị xoá ở WS mới → thread chuyển trạng thái cuối, card info cập nhật | P2 |
| 7 | Sau move, UI không giữ nid cũ → file mở được ngay, không cần reload | P1 |

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [Phase 1: Schema + procs](./phase-01-schema-and-procs.md) | **Done** — đã kiểm chứng trên stage |
| 2 | [Phase 2: Server move-out + move-back](./phase-02-server-move-out-and-move-back.md) | **Done** — SQL đã kiểm; UI chờ Phase 5 |
| 3 | [Phase 3: UI thread chỉ-đọc + card info + stale-nid](./phase-03-ui-readonly-thread-and-info-card.md) | **Done** — deploy stage, chờ test giao diện |
| 4 | [Phase 4: Gỡ đường migrate + dọn dẹp](./phase-04-retire-migrate-path-and-cleanup.md) | **Done** |
| 5 | [Phase 5: Kiểm chứng trên stage](./phase-05-stage-verification.md) | **Done** — SQL xong; còn kiểm qua giao diện |

## Success Criteria

- [ ] Move file có thread sang WS khác: file sang, thread ở lại `unavailable`, **0 message rời DB gốc**
- [ ] UI nguồn: thread vẫn hiện trong rail, chỉ-đọc, card info báo file đã chuyển đi
- [ ] UI đích: file xuất hiện, mở được, không có thread
- [ ] Move back đúng WS gốc: thread `active`, message đủ, `metadata._file_nid` trỏ nid mới
- [ ] Move sang WS thứ ba rồi về gốc: thread vẫn hồi sinh đúng
- [ ] Move cùng WS: hành vi không đổi (hồi quy)
- [ ] Move folder chứa file có thread: cùng ngữ nghĩa
- [ ] `yp.file_move_saga` đã DROP, hạ tầng saga đã gỡ
- [ ] Không còn `file_thread` mồ côi (row có `file_nid` không tồn tại trong `media`)
- [ ] File bị xoá hẳn ở WS đang giữ → lineage `orphaned`, card info báo file đã bị xoá
- [ ] Trash (xoá tạm) → vẫn `unavailable`, không chuyển `orphaned`
- [ ] Sau **mọi** lần move, mở file ngay trong UI đang mở — không 404, không cần F5

## Ghi chú vận hành

Backfill 144 DB (đã làm) **vẫn cần** — `channel_file_thread_*` procs dùng cho đọc/ghi thread bình thường, không riêng move. `file_move_readiness` + precondition-check giữ lại, chỉ bớt kiểm mấy proc thuộc đường migrate.

Quy trình patch bắt buộc (đã kiểm chứng trên stage):
- **KHÔNG** dùng `bin/patch-from-file` (mang `--orphan=remove --force` → có thể `DROP DATABASE`)
- Backup phải có `--routines`
- Rollback bằng snapshot `SHOW CREATE PROCEDURE`, không full-DB restore

## Open Questions

1. Cách sửa stale-nid (Goal 7): nghe `media.move` cập nhật `model.id`, hay để player bắt 404 rồi resolve lại? Quyết ở Phase 3 sau khi đọc `player/image`. Nghiêng về hướng 1 — sửa tại nguồn.
2. 9 dòng lineage trên stage có **4 dòng `state='failed'`** và 2 dòng trùng `current_thread_id` (rác từ các lần move fail cũ). Dọn ở Phase 4 — cần chốt: xoá hẳn hay chuyển `orphaned`?

Đã chốt (user trả lời): file xoá hẳn → trạng thái cuối `orphaned`; thread `unavailable` **hiện** card info, không ẩn; `yp.file_move_saga` → xoá.

<!-- slug: thread-stays-in-original-workspace-on-cross-hub-move -->
