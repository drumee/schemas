---
name: server-essentials-permission-bit-versions
description: Published @drumee/server-essentials 1.3.2-1.3.6 revert the 1.3.0/1.3.1 permission-bit renumbering; server-team pins 1.3.1 via package-lock. Check before reasoning about ACL bits.
metadata:
  type: project
---

Published npm versions of `@drumee/server-essentials` disagree on the permission
bit layout (verified 2026-09-17 by downloading the tarballs):

- 1.3.0 / 1.3.1: `Permission` read=2, download=4, write=delete=modify=8,
  admin=16, owner=32; `Privilege` read=3, download=chat=7, write=delete=15.
- 1.3.2 .. 1.3.6 (latest, and GitHub `main`): back to the OLD layout —
  download=2 (same as read), write=4, delete=8; `Privilege.WRITE`=7.
- GitHub branch `permission-change` is presumably where the renumbering lives.

server-team `package.json` asks `^1.3.1` but `package-lock.json` resolves
1.3.1, so a lockfile-respecting install (`npm ci`) keeps the new layout; a
bare `npm install`/`npm update` would pull 1.3.6 and silently make
`src: "write"` = bit 4 (the chat bit), collapsing chat and edit roles.

**Why:** the chat-upload permission fix (schemas `fix/chat-upload-role-write`,
server-team `member-capability.js`, hub.js `Privilege.WRITE` grants) is only
coherent under the 1.3.1 layout. `member-capability.js` pins literals for the
same reason.

**How to apply:** when advising on ACL bits, role masks, or anything that
reads `Permission.*`/`Privilege.*`, resolve the installed version first
(`node -e 'require("@drumee/server-essentials/package.json").version'` from
server-team) rather than trusting GitHub main or npm latest. Flag any deploy
step that reinstalls server-team dependencies without the lockfile.
