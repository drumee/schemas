---
title: "Phase 3: UI thread chỉ-đọc + card info"
status: completed
phase: 3
priority: P1
effort: "5h"
dependencies: [2]
---

# Phase 3: UI thread chỉ-đọc + card info

## Đã làm (deploy stage, chờ user test qua giao diện)

Giả định "thread vẫn liệt kê trong rail" ở cuối file **đúng là sai** — kiểm ngay đầu Phase 3:
`channel_file_thread_list_by_folder` dùng `INNER JOIN media`, file đi rồi thì thread **biến mất khỏi rail**. Sửa proc trước, không thì sửa UI vô nghĩa.

### SQL

| Chỗ | Sửa |
|---|---|
| `list_by_folder` | `INNER JOIN` → `LEFT JOIN` + nhánh thứ hai cho thread có lineage `unavailable`/`orphaned`, quyền lấy từ **folder** (file không còn ở DB này để hỏi `user_permission`) |
| `file_thread_lineage` | thêm cột `file_name` — media row bị xoá mang theo tên, rail sẽ hiện nid thô thay vì `"quarterly report"` |
| `transition_direct` | thêm tham số `_file_name`, ghi lúc `move_out` |
| `file_thread_info` | thêm `away_file_name` |

Kiểm chứng trên stage: trước move rail hiện bình thường; sau move thread **vẫn hiện**, `lineage_state=unavailable`, `holder_hub_name="Salvatore Phuong Hoa"`, tên file `"quarterly report"` giữ nguyên.

### UI

Điểm mấu chốt: `_ftIsFileRevoked` gác **mọi** đường mở thread (`index.js:3302`). Nếu ghi move-out là `"revoked"` thì thread hiện trong rail nhưng **không mở được**. Nên thêm trạng thái thứ ba `"away"` — so sánh trong guard là `=== "revoked"` nên `"away"` lọt qua đúng ý.

| File | Sửa |
|---|---|
| `file-thread-access.js` | `_ftIsAwayReason` tách nhánh; `_onFileThreadMovedAway` (không ẩn, không popup, không về General); `_ftFreezeWrites` tách khỏi `_ftFreeze` để đóng băng **không** blur; `_ftSetCardAway`/`_ftClearCardAway`; `_refreshFileThreadInfoCard` |
| `folder/index.js` | `_fillFileInfoCard` hydrate dòng trạng thái + ẩn "Open file →" |
| `skeleton/toolkit/index.js` | thêm `ft-info-status` |
| `folder/skin/index.scss` | style away/orphaned — **không blur** (blur sẽ che đúng thứ user cần đọc) |
| `locale/*.json` | 4 key × 6 ngôn ngữ |

Deploy: build sạch (3 warning kích thước asset có sẵn), rsync lên `/srv/drumee/runtime/ui/aaron/app`, xác nhận `manifest.json` trỏ bundle mới và code+locale mới có trong chunk đã deploy.

## Overview

Thread `unavailable` (file đã chuyển WS khác) phải **đọc được**, không bị ẩn — và card info nói rõ file đi đâu. Với `orphaned` (file bị xoá hẳn) card nói file đã bị xoá.

Đây là thay đổi UI thật, đảo ngược giả định ban đầu "UI không cần sửa".

## Requirements

**Functional**
- Thread `unavailable`/`orphaned` **vẫn liệt kê** trong rail + dropdown
- Mở được, đọc được toàn bộ message cũ
- **Sau move, UI cập nhật nid mới** — mở file không 404, không cần reload trang
- Card info hiện trạng thái: "File đã chuyển sang <WS>" hoặc "File đã bị xoá"
- **Chặn gửi tin mới** — thread đóng băng, chỉ đọc
- Nút "Open file →" ẩn hoặc disable

**Non-functional**
- Text qua `LOCALE.*`, thêm key vào `locale/en.json` và mirror các ngôn ngữ
- Không HTML thô — dùng `Skeletons.*` (framework invariant #4)
- Phân biệt rõ hai ngữ cảnh: mất quyền (hiện có) vs move-out/orphaned (mới)

## Architecture

### Stale-nid sau move (Goal 7)

Triệu chứng đã gặp thật: sau move, mở file báo lỗi
`__player_image: ERR:126 ... file/preview/47a05fe547a05fea/... failed to load`.

**Chẩn đoán đúng** (đã kiểm chứng, khác giả thuyết ban đầu):

| Kiểm | Kết quả |
|---|---|
| `47a05fe547a05fea` trong `media` hai DB | **0** — không tồn tại |
| thư mục vật lý `47a05fe5*` | **không có** |
| thư mục vật lý của nid HIỆN TẠI (`c7e386aac7e386ae`) | **có, khớp DB** |

Nên **không phải** "thư mục không đổi tên theo nid" như giả thuyết ban đầu — `after_transact` (`media.js:300-322`) có `move_node` và nó chạy đúng.

Nguyên nhân thật: nid `47a05fe5` là **bản trung gian đã bị compensation xoá**. UI giữ model cũ từ trước rollback, rồi build URL preview từ nid đã chết.

Sau khi bỏ saga (Phase 4), compensation không còn — nhưng vấn đề vẫn tồn tại ở dạng nhẹ hơn: **mỗi lần move cross-hub, nid đổi**. Widget đang mở giữ nid cũ cho tới khi model được refresh.

Hướng sửa (chọn khi implement):
- Nghe event `media.move` → cập nhật `model.id` của widget đang mở
- Hoặc: player bắt 404 → resolve lại nid qua `mfs_access_node` rồi thử lại

Ưu tiên hướng 1 — sửa nguồn, không vá triệu chứng.

### Vì sao phải đổi

`file-thread-access.js` viết cho ngữ cảnh **mất quyền truy cập**: ẩn hẳn, cards `data-ft_available=0`, tên gạch ngang (`ftc-unavailable`), không mở được, popup rồi về `# General`.

Đúng cho mất quyền. **Sai cho move-out** — thread vẫn của team này, chỉ file đi chỗ khác. Phải đọc lại được.

Tách hai đường theo `reason` trong payload:

| `reason` | Hành vi |
|---|---|
| mất quyền (hiện có) | như hiện tại — ẩn, chặn, popup |
| `move_out` | **giữ hiển thị**, mở được, chỉ-đọc, card báo đã chuyển |
| `orphaned` | **giữ hiển thị**, mở được, chỉ-đọc, card báo đã xoá |

### Card info — điểm bám

`_fillFileInfoCard` (`folder/index.js:3523`) đã hydrate `ft-info-name`, `ft-info-replies`, `ft-info-time`, `ft-info-badge`. Skeleton có sẵn cấu trúc, chỉ thêm một dòng trạng thái.

Thêm `ft-info-status`, hydrate từ `channel.file_thread_info` — proc này phải trả thêm `lineage_state` và tên WS đích. **Điểm phụ thuộc Phase 1/2.**

### Chặn gửi tin

`chat/index.js` đã có `freezeFileScope`/`unfreezeFileScope` — dùng lại. Khác biệt: freeze hiện đi kèm ẩn hoàn toàn; ở đây freeze nhưng vẫn hiện.

### Popup

Người **tự move** không nên thấy popup "mất quyền". `file-thread-access.js` hiện không lọc `actor`. Với `move_out`:
- actor là chính mình → không popup, chỉ cập nhật card
- actor là người khác → thông báo nhẹ, không cảnh báo đỏ

## Related Code Files

- Sửa: `ui-team/src/drumee/builtins/window/folder/file-thread-access.js` — tách nhánh theo `reason`
- Sửa: `ui-team/src/drumee/builtins/window/folder/index.js` — `_fillFileInfoCard` thêm dòng trạng thái
- Sửa: skeleton info card (tìm nơi định nghĩa `ft-info-*` trong `folder/skeleton/`)
- Sửa: `ui-team/src/drumee/builtins/window/folder/skeleton/thread-menu.js`
- Sửa: `ui-team/locale/en.json` + các locale khác
- Sửa: `common/procedures/channel/channel_file_thread_info.sql` — trả thêm `lineage_state`
- Sửa: `common/procedures/channel/channel_file_thread_list_by_folder.sql` — xem bước 8
- Đọc: `ui-team/src/drumee/builtins/widget/chat/index.js` (`freezeFileScope`)

## Implementation Steps

1. **Đọc `file-thread-access.js` toàn bộ** (541 dòng) trước khi sửa. Lifecycle hiện tại xử lý race, revision ordering, idempotent finalize — không phá.
2. **Mở rộng `channel_file_thread_info`** trả `lineage_state` + tên WS đích khi `unavailable`. Chỉ **thêm** cột, không đổi cột cũ.
3. **Tách nhánh theo `reason`** trong `onFileThreadAccessChanged` — `move_out`/`orphaned` đi nhánh mới, phần còn lại giữ nguyên.
4. **Nhánh mới**: không gọi `_ftInvalidateCards`, không `_finalizeRevokedFileThread`. Thay bằng: freeze composer, cập nhật card info, refresh rail.
5. **Thêm `ft-info-status`** vào skeleton + hydrate trong `_fillFileInfoCard`.
6. **Locale keys** — `FILE_MOVED_TO_WORKSPACE` ("File đã chuyển sang {0}"), `FILE_DELETED_THREAD_KEPT`, `THREAD_READ_ONLY`. Mirror đủ ngôn ngữ.
7. **Lọc actor** — bỏ qua popup khi `actor.uid === Visitor.id`.
8. **Sửa `channel_file_thread_list_by_folder`** — proc lọc theo `media.parent_id`, mà file đã rời WS → thread **biến mất khỏi rail**. Phải liệt kê thêm thread có lineage `unavailable`/`orphaned` thuộc WS này. Kiểm sớm cùng bước 2.
9. **Sửa stale-nid** — đọc `builtins/player/image/index.js` và đường build URL preview. Cập nhật `model.id` khi nhận `media.move` cho node đang mở. Test: move file rồi mở ngay, không reload.

## Success Criteria

- [ ] Sau move-out: thread vẫn hiện trong rail của WS gốc
- [ ] Mở thread đọc được đủ message cũ, đúng thứ tự
- [ ] Card info hiện "File đã chuyển sang <tên WS>"
- [ ] Composer bị chặn — không gửi được tin mới
- [ ] Người tự move **không** thấy popup cảnh báo
- [ ] File bị xoá ở WS mới → card đổi thành "File đã bị xoá"
- [ ] Move back: card bình thường lại, composer mở lại
- [ ] **Hồi quy**: luồng mất quyền thật vẫn ẩn + popup như cũ
- [ ] Không chuỗi hardcode — mọi text qua `LOCALE.*`
- [ ] Sau move, mở file trong UI đang mở → hiện ảnh, không 404, không cần F5

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| Sửa `file-thread-access.js` phá luồng mất quyền | Thu hồi quyền → thread vẫn mở được | Tách nhánh theo `reason`, không đụng nhánh cũ. Test hồi quy bắt buộc |
| Thread biến mất khỏi rail dù đã sửa UI | Rail rỗng sau move | Nguyên nhân ở SQL, không phải UI. Bước 8 |
| Đổi contract `file_thread_info` phá chỗ khác | Lỗi ở panel/card khác | Chỉ **thêm** cột, không đổi/xoá |
| Locale thiếu ngôn ngữ → text trống | Nhãn trống | `createSafeObject` trả tên key, không lỗi nhưng xấu. Mirror đủ |
| Card info không có chỗ đặt dòng trạng thái | Layout vỡ | Đọc skeleton trước, xem Figma `2216-165656` có chừa chỗ không |
| Sửa stale-nid đụng nhiều widget | Grid/player/thread card đều giữ nid | Bắt đầu từ player (nơi triệu chứng rõ nhất), rồi mở rộng nếu cần. Không refactor toàn bộ |

**Giả định có thể sai:** "thread vẫn liệt kê trong rail sau khi file đi". `file_thread_list_by_folder` join theo `media.parent_id` — file đi rồi thì join rỗng. Gần như chắc chắn phải sửa proc. Kiểm sớm ở bước 2.
