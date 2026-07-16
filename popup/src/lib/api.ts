// API client for ScamShield Lao backend
const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api";

export interface ScanResult {
  risk_score: number;
  risk_level: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
  scam_type: string;
  reasons: string[];
  flagged_phrases: string[];
  is_scam: boolean;
  confidence: number;
  heuristic_score: number;
  ai_analyzed: boolean;
  url: string;
  page_title: string;
  from_cache: boolean;
}

export interface HistoryItem {
  session_id: string;
  url: string;
  page_title: string;
  risk_score: number;
  risk_level: string;
  scam_type: string;
  is_scam: boolean;
  created_at: string;
}

export interface Stats {
  total_scans: number;
  total_scams_detected: number;
  total_user_reports: number;
  scam_rate: number;
  risk_breakdown: Record<string, number>;
  scam_type_breakdown: Record<string, number>;
}

function getSessionId(): string {
  if (typeof chrome !== "undefined" && chrome.storage) {
    return ""; // handled by background.js
  }
  let id = localStorage.getItem("scamshield_session");
  if (!id) {
    id = `session_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    localStorage.setItem("scamshield_session", id);
  }
  return id;
}

export async function scanContent(
  text: string,
  url: string,
  pageTitle: string
): Promise<ScanResult> {
  const res = await fetch(`${API_BASE}/scan`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      text,
      url,
      page_title: pageTitle,
      session_id: getSessionId(),
    }),
  });
  if (!res.ok) throw new Error(`Scan failed: ${res.status}`);
  return res.json();
}

export async function getHistory(
  sessionId: string,
  page = 1,
  limit = 20
): Promise<{ items: HistoryItem[]; total: number }> {
  const res = await fetch(
    `${API_BASE}/history?session_id=${sessionId}&page=${page}&limit=${limit}`
  );
  if (!res.ok) throw new Error(`History failed: ${res.status}`);
  return res.json();
}

export async function getStats(): Promise<Stats> {
  const res = await fetch(`${API_BASE}/stats`);
  if (!res.ok) throw new Error(`Stats failed: ${res.status}`);
  return res.json();
}

export async function submitReport(data: {
  url: string;
  page_title: string;
  description: string;
  scam_type: string;
}): Promise<{ id: string; message: string }> {
  const res = await fetch(`${API_BASE}/report`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`Report failed: ${res.status}`);
  return res.json();
}

export async function checkHealth(): Promise<boolean> {
  try {
    const res = await fetch(`${API_BASE}/health`, { signal: AbortSignal.timeout(3000) });
    return res.ok;
  } catch {
    return false;
  }
}

// Chrome extension storage helpers
export function getChromeStorage<T>(
  keys: string[]
): Promise<Record<string, T>> {
  if (typeof chrome !== "undefined" && chrome.storage) {
    return new Promise((resolve) =>
      chrome.storage.local.get(keys, (items) => resolve(items as Record<string, T>))
    );
  }
  const result: Record<string, T> = {};
  keys.forEach((k) => {
    const v = localStorage.getItem(k);
    if (v) result[k] = JSON.parse(v) as T;
  });
  return Promise.resolve(result);
}

export function setChromeStorage(data: Record<string, unknown>): Promise<void> {
  if (typeof chrome !== "undefined" && chrome.storage) {
    return new Promise((resolve) => chrome.storage.local.set(data, resolve));
  }
  Object.entries(data).forEach(([k, v]) =>
    localStorage.setItem(k, JSON.stringify(v))
  );
  return Promise.resolve();
}
