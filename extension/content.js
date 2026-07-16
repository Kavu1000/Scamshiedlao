// ScamShield Lao — Content Script
// Injected into every page to extract text and render scam overlays

(function () {
  if (window.__scamShieldInjected) return;
  window.__scamShieldInjected = true;

  let scanResult = null;
  let highlightedElements = [];

  // ─── Extract meaningful text blocks from the page ───────────────────────────
  function extractTextBlocks() {
    const candidates = [];
    const selectors = [
      "article", "p", "[data-testid='post-container']",
      ".post", ".feed-item", ".story", ".ad", "[class*='post']",
      "[class*='feed']", "[class*='card']", "main", "section",
    ];

    selectors.forEach((sel) => {
      document.querySelectorAll(sel).forEach((el) => {
        const text = el.innerText?.trim();
        if (text && text.length > 80) {
          candidates.push({ el, text });
        }
      });
    });

    // Deduplicate by element
    const seen = new Set();
    return candidates.filter(({ el }) => {
      if (seen.has(el)) return false;
      seen.add(el);
      return true;
    });
  }

  // ─── Get full page text for initial scan ───────────────────────────────────
  function getPageText() {
    return document.body?.innerText?.slice(0, 8000) || "";
  }

  // ─── Render risk badge overlay on a specific element ───────────────────────
  function injectOverlay(el, score, level, reasons) {
    if (el.__scamShieldOverlay) return;
    el.__scamShieldOverlay = true;

    // เติม ?. กันเหนียวป้องกันระดับความเสี่ยงเป็นค่าว่าง
    const safeLevel = level ? level.toLowerCase() : 'unknown';
    el.classList.add("scamshield-flagged", `scamshield-${safeLevel}`);

    const badge = document.createElement("div");
    badge.className = `scamshield-badge scamshield-badge-${safeLevel}`;
    badge.innerHTML = `
      <span class="scamshield-badge-icon">⚠</span>
      <span class="scamshield-badge-score">Risk Score: ${score}%</span>
      <button class="scamshield-badge-close" title="Dismiss">✕</button>
    `;

    const tooltip = document.createElement("div");
    tooltip.className = "scamshield-tooltip";
    
    // กันเหนียวกรณีที่ไม่มีอาเรย์ของเหตุผลส่งมาจากหลังบ้าน
    const safeReasons = Array.isArray(reasons) ? reasons.slice(0, 2).join("<br>") : "Suspicious activity detected";
    tooltip.innerHTML = `
      <div class="scamshield-tooltip-title">⚠ Scam Detected</div>
      <div class="scamshield-tooltip-reason">${safeReasons}</div>
    `;

    badge.appendChild(tooltip);

    // Close button
    badge.querySelector(".scamshield-badge-close").addEventListener("click", (e) => {
      e.stopPropagation();
      badge.remove();
      el.classList.remove("scamshield-flagged", `scamshield-${safeLevel}`);
    });

    // Position relative
    if (getComputedStyle(el).position === "static") {
      el.style.position = "relative";
    }
    el.appendChild(badge);
    highlightedElements.push(el);
  }

  // ─── Escape helper ─────────────────────────────────────────────────────────
  function esc(str) {
    return String(str == null ? "" : str).replace(/[&<>"']/g, (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])
    );
  }

  // ─── Page-level banner (safe + risky) ──────────────────────────────────────
  function showPageBanner(result) {
    const existing = document.getElementById("scamshield-banner");
    if (existing) existing.remove();

    if (!result || !result.risk_level) return;

    const reasons = Array.isArray(result.reasons) ? result.reasons.slice(0, 3) : [];
    const level = result.risk_level.toLowerCase();

    if (level === "low") {
      // ── Safe banner (green) with "safe because..." explanation ──
      const banner = document.createElement("div");
      banner.id = "scamshield-banner";
      banner.className = "scamshield-banner scamshield-banner-safe";
      const reasonsHtml = reasons.length
        ? `<ul class="scamshield-banner-reasons">${reasons.map((r) => `<li>${esc(r)}</li>`).join("")}</ul>`
        : "";
      banner.innerHTML = `
        <div class="scamshield-banner-inner">
          <span class="scamshield-banner-icon">✅</span>
          <div class="scamshield-banner-text">
            <strong>ScamShield Lao</strong> — This page looks safe (risk ${esc(result.risk_score)}%)
            ${reasonsHtml ? `<div class="scamshield-banner-subtitle">Safe because:</div>${reasonsHtml}` : ""}
          </div>
          <button class="scamshield-banner-close" id="scamshield-dismiss">✕</button>
        </div>
      `;
      document.body.prepend(banner);
      document.getElementById("scamshield-dismiss").onclick = () => banner.remove();
      // Safe banners auto-dismiss so they don't linger.
      setTimeout(() => {
        const b = document.getElementById("scamshield-banner");
        if (b && b.classList.contains("scamshield-banner-safe")) {
          b.style.transition = "opacity 0.5s ease";
          b.style.opacity = "0";
          setTimeout(() => b.remove(), 500);
        }
      }, 8000);
      return;
    }

    // ── Risk banner (CRITICAL / HIGH / MEDIUM) ──
    const reasonsHtml = reasons.length
      ? `<ul class="scamshield-banner-reasons">${reasons.map((r) => `<li>${esc(r)}</li>`).join("")}</ul>`
      : "";
    const banner = document.createElement("div");
    banner.id = "scamshield-banner";
    banner.className = `scamshield-banner scamshield-banner-${level}`;
    banner.innerHTML = `
      <div class="scamshield-banner-inner">
        <span class="scamshield-banner-icon">🛡</span>
        <div class="scamshield-banner-text">
          <strong>ScamShield Lao</strong> — ⚠ ${esc(result.risk_level)} RISK detected on this page (${esc(result.risk_score)}%)
          <span class="scamshield-banner-type">${result.scam_type && result.scam_type !== "none" ? "· " + esc(result.scam_type.replace("_", " ").toUpperCase()) : ""}</span>
          ${reasonsHtml ? `<div class="scamshield-banner-subtitle">Why:</div>${reasonsHtml}` : ""}
        </div>
        <button class="scamshield-banner-close" id="scamshield-dismiss">✕</button>
      </div>
    `;
    document.body.prepend(banner);
    document.getElementById("scamshield-dismiss").onclick = () => banner.remove();
  }

  // ─── Match flagged phrases to DOM elements ─────────────────────────────────
  function highlightFlaggedElements(result) {
    if (!result || !result.is_scam) return;
    const blocks = extractTextBlocks();
    const phrases = result.flagged_phrases || [];

    blocks.forEach(({ el, text }) => {
      const textLower = text.toLowerCase();
      const matched = phrases.some((p) => p && textLower.includes(p.toLowerCase()));
      if (matched) {
        injectOverlay(el, result.risk_score, result.risk_level, result.reasons);
      }
    });
  }

  // ─── Perform a scan on demand and respond to whoever asked ─────────────────
  function performScan(sendResponse) {
    const text = getPageText();
    if (!text || text.length < 50) {
      sendResponse({ error: "Not enough text on this page to scan." });
      return;
    }

    chrome.runtime.sendMessage(
      {
        type: "SCAN_PAGE",
        text,
        url: window.location.href,
        pageTitle: document.title,
      },
      (response) => {
        if (chrome.runtime.lastError || !response || response.error) {
          sendResponse({ error: response?.error || "Scan request failed." });
          return;
        }
        scanResult = response;
        showPageBanner(response);
        highlightFlaggedElements(response);
        sendResponse(response);
      }
    );
  }

  // ─── Listen for scan triggers (from the popup) and relayed results ────────
  chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.type === "TRIGGER_SCAN") {
      performScan(sendResponse);
      return true; // keep channel open for the async response
    }
    if (message.type === "SCAN_RESULT") {
      scanResult = message.result;
      showPageBanner(message.result);
      highlightFlaggedElements(message.result);
    }
  });
})();