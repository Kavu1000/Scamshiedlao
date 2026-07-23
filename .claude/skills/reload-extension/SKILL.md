---
name: reload-extension
description: >-
  The correct procedure to make Chrome pick up edits to the MV3 extension, and why
  the popup can appear stale. Use after editing anything in extension/ (popup vanilla
  files, content.js, background.js, manifest.json, icons), or when the user reports
  "I reloaded but still see the old popup / old UI".
---

# Reload the extension so edits take effect

The extension has **no build step** — `extension/` is loaded unpacked. The trap: an unpacked extension's ID is derived from its **folder path**, so remove+re-add from the same path keeps the same `chrome-extension://` origin, and Chrome often serves the **popup and its assets from cache**. That's why edits can look like they "didn't apply".

## Procedure (do this after any extension edit)
1. **Bump `version`** in `extension/manifest.json` (e.g. `1.5.0` → `1.5.1`). This is the reliable proof that a reload actually took.
2. Go to `chrome://extensions/`, Developer mode on, click the **reload** (↻) icon on the ScamShield Lao card.
3. To force-refresh the **popup** specifically (its assets cache hardest): open the popup → right-click → **Inspect** → **Network** tab → check **"Disable cache"** → press **⌘R** with DevTools open.
4. For **content-script** changes (`content.js`/`content.css`): reload the extension, then **reload the web page** you're testing on (or the popup re-injects via `chrome.scripting` on next scan).
5. Confirm the manifest version shown on the card matches what you just set.

## Hard rules (don't undo these)
- **Never** copy `popup/out/` (Next.js export) over `extension/popup/`. Next emits inline `<script>` tags (blocked by the extension CSP `script-src 'self'`) and absolute `/_next/` paths that 404 from the subdir — it will *look* installed but the popup will be blank/broken. Edit the vanilla `extension/popup/{index.html,popup.css,popup.js}` directly.
- Keep the popup CSP-clean: no inline scripts, external JS only, relative asset paths.

Always end an extension edit by telling the user these reload steps and the new version number.
