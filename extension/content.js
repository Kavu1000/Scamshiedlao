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

  // ─── Page-level warning banner ─────────────────────────────────────────────
  function showPageBanner(result) {
    const existing = document.getElementById("scamshield-banner");
    if (existing) existing.remove();

    if (!result || !result.risk_level) return;

    const level = result.risk_level.toLowerCase();
    // Show banner for CRITICAL, HIGH, MEDIUM — skip LOW
    if (level === "low") return;

    const banner = document.createElement("div");
    banner.id = "scamshield-banner";
    banner.className = `scamshield-banner scamshield-banner-${level}`;
    banner.innerHTML = `
      <div class="scamshield-banner-inner">
        <span class="scamshield-banner-icon">🛡</span>
        <div class="scamshield-banner-text">
          <strong>ScamShield Lao</strong> — ⚠ ${result.risk_level} RISK detected on this page (${result.risk_score}%)
          <span class="scamshield-banner-type">${result.scam_type && result.scam_type !== "none" ? "· " + result.scam_type.replace("_", " ").toUpperCase() : ""}</span>
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

  // ─── Initial page scan ─────────────────────────────────────────────────────
  function runInitialScan() {
    const text = getPageText();
    if (!text || text.length < 50) return;

    chrome.runtime.sendMessage(
      {
        type: "SCAN_PAGE",
        text,
        url: window.location.href,
        pageTitle: document.title,
      },
      (response) => {
        if (chrome.runtime.lastError || !response) return;
        if (response.skipped) return;
        scanResult = response;
        showPageBanner(response);
        highlightFlaggedElements(response);
      }
    );
  }

  // ─── Listen for result from background ────────────────────────────────────
  chrome.runtime.onMessage.addListener((message) => {
    if (message.type === "SCAN_RESULT") {
      scanResult = message.result;
      showPageBanner(message.result);
      highlightFlaggedElements(message.result);
    }
  });

  // Run on page load
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", runInitialScan);
  } else {
    runInitialScan();
  }
})();