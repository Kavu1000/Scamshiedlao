// ScamShield Lao — Background Service Worker
const API_BASE = "http://localhost:8000/api";

// Generate a persistent session ID
async function getSessionId() {
  const { sessionId } = await chrome.storage.local.get("sessionId");
  if (sessionId) return sessionId;
  const id = `session_${Date.now()}_${Math.random().toString(36).slice(2)}`;
  await chrome.storage.local.set({ sessionId: id });
  return id;
}

// Listen for messages from content script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "SCAN_PAGE") {
    handleScanPage(message, sender).then(sendResponse).catch((err) => {
      sendResponse({ error: err.message });
    });
    return true; // keep channel open for async response
  }

  if (message.type === "GET_SCAN_STATE") {
    chrome.storage.local.get(["autoScan", "lastScanResult"], sendResponse);
    return true;
  }

  if (message.type === "SET_AUTO_SCAN") {
    chrome.storage.local.set({ autoScan: message.value });
    sendResponse({ ok: true });
    return true;
  }

  if (message.type === "SUBMIT_REPORT") {
    handleReport(message.data).then(sendResponse).catch((err) => {
      sendResponse({ error: err.message });
    });
    return true;
  }
});

async function handleScanPage(message, sender) {
  const sessionId = await getSessionId();
  const { autoScan } = await chrome.storage.local.get("autoScan");
  if (autoScan === false) return { skipped: true };

  const response = await fetch(`${API_BASE}/scan`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      text: message.text,
      url: message.url,
      page_title: message.pageTitle,
      session_id: sessionId,
    }),
  });

  if (!response.ok) throw new Error(`API error: ${response.status}`);
  const result = await response.json();

  // Store last result for popup
  await chrome.storage.local.set({
    lastScanResult: result,
    lastScanUrl: message.url,
  });

  // Update badge
  updateBadge(result.risk_level);

  // Notify content script to render overlays
  if (sender.tab?.id) {
    chrome.tabs.sendMessage(sender.tab.id, {
      type: "SCAN_RESULT",
      result,
    });
  }

  return result;
}

async function handleReport(data) {
  const response = await fetch(`${API_BASE}/report`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  if (!response.ok) throw new Error(`Report failed: ${response.status}`);
  return await response.json();
}

function updateBadge(riskLevel) {
  const colors = {
    CRITICAL: "#ef4444",
    HIGH: "#f97316",
    MEDIUM: "#eab308",
    LOW: "#22c55e",
  };
  const labels = { CRITICAL: "!!!", HIGH: "!", MEDIUM: "~", LOW: "" };
  chrome.action.setBadgeText({ text: labels[riskLevel] || "" });
  chrome.action.setBadgeBackgroundColor({
    color: colors[riskLevel] || "#64748b",
  });
}

// Auto-scan on tab navigation
chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status === "complete" && tab.url?.startsWith("http")) {
    const { autoScan } = await chrome.storage.local.get("autoScan");
    if (autoScan !== false) {
      // Reset badge while scanning
      chrome.action.setBadgeText({ text: "..." });
      chrome.action.setBadgeBackgroundColor({ color: "#6366f1" });
    }
  }
});
