// ScamShield Lao — Popup logic (self-contained, no inline scripts for MV3 CSP)

const DEFAULT_API_BASE = "http://localhost:8000/api";

// ─── Small helpers ──────────────────────────────────────────────────────────
const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => Array.from(document.querySelectorAll(sel));

function storageGet(keys) {
  return new Promise((resolve) => chrome.storage.local.get(keys, resolve));
}
function storageSet(data) {
  return new Promise((resolve) => chrome.storage.local.set(data, resolve));
}
function getActiveTab() {
  return new Promise((resolve) =>
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => resolve(tabs[0] || null))
  );
}

async function getApiBase() {
  const { scamshieldSettings } = await storageGet("scamshieldSettings");
  const url = scamshieldSettings?.backendUrl?.trim();
  if (!url) return DEFAULT_API_BASE;
  return url.replace(/\/+$/, "").endsWith("/api") ? url.replace(/\/+$/, "") : `${url.replace(/\/+$/, "")}/api`;
}

function truncateUrl(url, max = 42) {
  try {
    const u = new URL(url);
    const path = u.hostname + u.pathname;
    return path.length > max ? path.slice(0, max) + "…" : path;
  } catch {
    return (url || "").slice(0, max);
  }
}
function formatTime(iso) {
  const d = new Date(iso);
  return (
    d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) +
    " " +
    d.toLocaleDateString([], { month: "short", day: "numeric" })
  );
}
function escapeHtml(str) {
  return String(str ?? "").replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])
  );
}

// ─── View switching ─────────────────────────────────────────────────────────
function showView(name) {
  $$(".view").forEach((v) => v.classList.toggle("active", v.dataset.view === name));
  if (name === "history") loadHistory();
}

// ─── Scan flow ──────────────────────────────────────────────────────────────
let currentResult = null;

function setStatus(text, dotClass) {
  $("#statusText").textContent = text;
  $("#statusDot").className = "status-dot" + (dotClass ? " " + dotClass : "");
}
function setScanning(on) {
  $("#progressBar").classList.toggle("active", on);
  $("#rescanBtn").classList.toggle("spin", on);
  $("#rescanBtn").disabled = on;
  $("#scanBtn").disabled = on;
}

function renderScanning() {
  currentResult = null;
  setScanning(true);
  setStatus("Scanning current page... (ກຳລັງກວດ)", "scanning");
  $("#scanBtn").textContent = "⏳ Scanning...";
  $("#aiBadge").style.display = "none";
  $("#resultArea").innerHTML = `
    <div class="risk-card">
      <div class="skeleton" style="height:16px;width:60%;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:40px;width:40%;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:6px;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:12px;margin-bottom:6px;"></div>
      <div class="skeleton" style="height:12px;width:80%;"></div>
    </div>`;
}

function renderIdle(message) {
  setScanning(false);
  setStatus("Ready to scan", "");
  $("#scanBtn").textContent = "🔍 Scan This Page";
  $("#aiBadge").style.display = "none";
  $("#resultArea").innerHTML = `
    <div class="state-card idle">
      <span class="state-icon">🔍</span>
      <div class="state-title">Not Scanned Yet</div>
      <div class="state-desc">${escapeHtml(message || "Click Scan This Page to check for scam indicators.")}</div>
    </div>`;
}

function renderResult(result) {
  currentResult = result;
  setScanning(false);
  const level = (result.risk_level || "low").toLowerCase();
  $("#scanBtn").textContent = "↻ Re-scan Page";
  $("#aiBadge").style.display = result.ai_analyzed ? "inline-flex" : "none";

  // ── SAFE (LOW risk) ──
  if (level === "low") {
    setStatus("Page is Safe ✓", "safe");
    const safeReasons = (result.reasons || [])
      .slice(0, 4)
      .map(
        (r) =>
          `<div class="reason-item"><span class="reason-icon" style="color:#22c55e;">✓</span><span>${escapeHtml(r)}</span></div>`
      )
      .join("");
    const scoreLine = result.risk_score != null ? ` — risk score ${result.risk_score}/100` : "";
    $("#resultArea").innerHTML = `
      <div class="state-card safe">
        <span class="state-icon">🛡</span>
        <div class="state-title">Page is Safe</div>
        <div class="state-desc">No scam indicators detected on this page${scoreLine}.</div>
      </div>
      ${
        safeReasons
          ? `<div class="risk-card low" style="margin-top:12px;">
               <div class="risk-label" style="margin-bottom:8px;">Why it's safe</div>
               <div class="reasons-list">${safeReasons}</div>
             </div>`
          : ""
      }`;
    return;
  }

  // ── RISKY (MEDIUM = caution, HIGH/CRITICAL = danger) ──
  const isDanger = level === "high" || level === "critical";
  setStatus(
    isDanger ? `Scam risk detected: ${result.risk_score}%` : `Caution — ${result.risk_level} risk: ${result.risk_score}%`,
    isDanger ? "threat" : "warn"
  );

  const emoji = { critical: "🔴", high: "🟠", medium: "🟡", low: "🟢" }[level] || "🟡";
  const reasons = (result.reasons || [])
    .slice(0, 4)
    .map((r) => `<div class="reason-item"><span class="reason-icon">▸</span><span>${escapeHtml(r)}</span></div>`)
    .join("");
  const typeLabel =
    result.scam_type && result.scam_type !== "none"
      ? `<span class="risk-score-type">${escapeHtml(result.scam_type.replace(/_/g, " "))}</span>`
      : "";

  const summaryClass = isDanger ? "threat-summary" : "caution-summary";
  const heading = isDanger ? "Scam Detected!" : "Caution Advised";
  const summaryText = isDanger
    ? "Strong scam indicators found. Do not share personal info, passwords, or money."
    : "Some suspicious elements were found on this page. Proceed carefully.";

  $("#resultArea").innerHTML = `
    <div class="${summaryClass}">
      <span class="threat-count">⚠</span>
      <div>
        <strong class="threat-text"><strong>${heading}</strong></strong>
        <div class="threat-text">${summaryText}</div>
      </div>
    </div>
    <div class="risk-card ${level}" style="margin-top:12px;">
      <div class="risk-card-header">
        <span class="risk-label">Why it's flagged</span>
        <div style="display:flex;gap:6px;align-items:center;">
          ${result.ai_analyzed ? '<span class="ai-badge">✦ AI Verified</span>' : ""}
          <span class="risk-badge ${level}">${emoji} ${escapeHtml(result.risk_level)}</span>
        </div>
      </div>
      <div class="risk-score-row">
        <span class="risk-score-number ${level}">${result.risk_score}</span>
        <span class="risk-score-suffix">/ 100</span>
        ${typeLabel}
      </div>
      <div class="progress-bar-track">
        <div class="progress-bar-fill ${level}" id="progressFill"></div>
      </div>
      ${reasons ? `<div class="reasons-list">${reasons}</div>` : ""}
    </div>`;

  // animate the score bar
  requestAnimationFrame(() => {
    const fill = $("#progressFill");
    if (fill) fill.style.width = `${result.risk_score}%`;
  });
}

function sendScanMessage(tabId) {
  return new Promise((resolve) => {
    let settled = false;
    const done = (r) => { if (!settled) { settled = true; resolve(r); } };
    try {
      chrome.tabs.sendMessage(tabId, { type: "TRIGGER_SCAN" }, (res) => {
        if (chrome.runtime.lastError) return done({ error: chrome.runtime.lastError.message });
        done(res);
      });
    } catch (e) {
      done({ error: e.message });
    }
    // safety timeout in case the content script never answers
    setTimeout(() => done({ error: "timeout" }), 35000);
  });
}

function ensureContentScript(tabId) {
  return new Promise((resolve) => {
    if (typeof chrome === "undefined" || !chrome.scripting) return resolve();
    try {
      chrome.scripting.insertCSS({ target: { tabId }, files: ["content.css"] }, () => void chrome.runtime.lastError);
      chrome.scripting.executeScript({ target: { tabId }, files: ["content.js"] }, () => {
        void chrome.runtime.lastError; // ignore; retry will surface real failures
        resolve();
      });
    } catch {
      resolve();
    }
  });
}

async function triggerScan() {
  renderScanning();

  const tab = await getActiveTab();
  if (!tab || !tab.id) {
    renderIdle("No active tab found.");
    return;
  }
  $("#footerUrl").textContent = tab.url ? truncateUrl(tab.url) : "";

  if (!tab.url || !/^https?:\/\//i.test(tab.url)) {
    renderIdle("This page type can't be scanned. Open a normal website (http/https) and try again.");
    return;
  }

  let response = await sendScanMessage(tab.id);

  // Tabs opened before the extension loaded have no content script yet —
  // inject it on demand and retry once.
  if (response && response.error && response.error !== "timeout") {
    await ensureContentScript(tab.id);
    response = await sendScanMessage(tab.id);
  }

  if (!response || response.error) {
    renderIdle(
      "Couldn't reach this page. Reload the tab so the scanner can load, then try again."
    );
    return;
  }
  renderResult(response);
}

// ─── History ────────────────────────────────────────────────────────────────
let historyItems = [];
let historyFilter = "ALL";

async function loadHistory() {
  const { sessionId } = await storageGet("sessionId");
  $("#historySession").textContent = sessionId ? `Session: ${sessionId.slice(0, 24)}…` : "Session: —";
  $("#historyArea").innerHTML = `
    <div class="history-list">
      ${Array(4).fill('<div class="skeleton" style="height:56px;"></div>').join("")}
    </div>`;

  if (!sessionId) {
    renderHistory([]);
    return;
  }
  try {
    const apiBase = await getApiBase();
    const res = await fetch(`${apiBase}/history?session_id=${encodeURIComponent(sessionId)}&page=1&limit=50`);
    if (!res.ok) throw new Error(`History failed: ${res.status}`);
    const data = await res.json();
    historyItems = data.items || [];
  } catch (e) {
    historyItems = [];
  }
  renderHistory(historyItems);
}

function renderHistory(items) {
  const scamCount = items.filter((i) => i.is_scam).length;
  $("#historySubtitle").textContent = `${items.length} scans · ${scamCount} threats`;

  const filtered = historyFilter === "ALL" ? items : items.filter((i) => i.risk_level === historyFilter);

  if (filtered.length === 0) {
    $("#historyArea").innerHTML = `
      <div class="empty-state">
        <div class="big">📋</div>
        No scan history yet.<br />Click "Scan This Page" to check a page.
      </div>`;
    return;
  }

  const colors = { critical: "#ef4444", high: "#f97316", medium: "#eab308", low: "#22c55e" };
  $("#historyArea").innerHTML =
    '<div class="history-list">' +
    filtered
      .map((item) => {
        const level = (item.risk_level || "low").toLowerCase();
        const type =
          item.scam_type && item.scam_type !== "none"
            ? `<div class="history-type" style="color:${colors[level] || "var(--text-muted)"}">${escapeHtml(
                item.scam_type.replace(/_/g, " ")
              )}</div>`
            : "";
        return `
          <div class="history-item">
            <div class="history-item-header">
              <span class="history-url">${escapeHtml(truncateUrl(item.url))}</span>
              <span class="history-time">${escapeHtml(formatTime(item.created_at))}</span>
            </div>
            <div class="history-row2">
              <span class="history-title">${escapeHtml(item.page_title || "Untitled Page")}</span>
              <span class="risk-badge ${level}" style="font-size:10px;padding:2px 7px;">${item.risk_score}%</span>
            </div>
            ${type}
          </div>`;
      })
      .join("") +
    "</div>";
}

// ─── Settings ───────────────────────────────────────────────────────────────
async function loadSettings() {
  const { scamshieldSettings } = await storageGet("scamshieldSettings");
  const s = scamshieldSettings || {};
  const lang = s.language || "lo";
  $$("#langGroup .lang-btn").forEach((b) => b.classList.toggle("active", b.dataset.lang === lang));
  $("#notifToggle").checked = s.notifications !== false;
  $("#backendUrl").value = s.backendUrl || "http://localhost:8000";
}

async function saveSettings() {
  const activeLang = $("#langGroup .lang-btn.active")?.dataset.lang || "lo";
  const settings = {
    language: activeLang,
    notifications: $("#notifToggle").checked,
    backendUrl: $("#backendUrl").value.trim() || "http://localhost:8000",
  };
  await storageSet({ scamshieldSettings: settings });
  const btn = $("#saveSettingsBtn");
  btn.textContent = "✓ Saved!";
  setTimeout(() => (btn.textContent = "💾 Save Settings"), 1600);
}

// ─── Backend health ─────────────────────────────────────────────────────────
async function checkHealth() {
  try {
    const apiBase = await getApiBase();
    const res = await fetch(`${apiBase}/health`, { signal: AbortSignal.timeout(3000) });
    return res.ok;
  } catch {
    return false;
  }
}

// ─── Wiring ─────────────────────────────────────────────────────────────────
function wireEvents() {
  $$("[data-goto]").forEach((el) => el.addEventListener("click", () => showView(el.dataset.goto)));
  $("#scanBtn").addEventListener("click", triggerScan);
  $("#rescanBtn").addEventListener("click", triggerScan);

  $$("#filterTabs .filter-tab").forEach((tab) =>
    tab.addEventListener("click", () => {
      historyFilter = tab.dataset.filter;
      $$("#filterTabs .filter-tab").forEach((t) => t.classList.toggle("active", t === tab));
      renderHistory(historyItems);
    })
  );

  $$("#langGroup .lang-btn").forEach((btn) =>
    btn.addEventListener("click", () => {
      $$("#langGroup .lang-btn").forEach((b) => b.classList.toggle("active", b === btn));
    })
  );
  $("#saveSettingsBtn").addEventListener("click", saveSettings);
}

async function init() {
  wireEvents();
  await loadSettings();

  const online = await checkHealth();
  if (!online) {
    setScanning(false);
    setStatus("Backend Offline", "");
    $("#backendAlert").style.display = "block";
    $("#scanBtn").disabled = true;
    $("#rescanBtn").disabled = true;
    renderIdle("Start the backend server on port 8000, then re-open this popup.");
    return;
  }
  // On open, immediately scan the active tab (on-demand, triggered by opening the popup).
  triggerScan();
}

document.addEventListener("DOMContentLoaded", init);
