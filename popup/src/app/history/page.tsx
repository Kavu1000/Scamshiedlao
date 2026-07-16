"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { HistoryItem, getHistory } from "@/lib/api";

function formatTime(iso: string) {
  const d = new Date(iso);
  return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) +
    " " + d.toLocaleDateString([], { month: "short", day: "numeric" });
}

function truncateUrl(url: string, max = 40) {
  try {
    const u = new URL(url);
    const path = u.hostname + u.pathname;
    return path.length > max ? path.slice(0, max) + "…" : path;
  } catch {
    return url.slice(0, max);
  }
}

export default function HistoryPage() {
  const [items, setItems] = useState<HistoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>("ALL");
  const [sessionId, setSessionId] = useState("");

  useEffect(() => {
    async function load() {
      let sid = "";
      if (typeof chrome !== "undefined" && chrome.storage) {
        const s = await new Promise<{ sessionId?: string }>((r: any) =>
          chrome.storage.local.get("sessionId", r)
        );
        sid = s.sessionId || "";
      } else {
        sid = localStorage.getItem("scamshield_session") || "";
      }
      setSessionId(sid);
      if (!sid) { setLoading(false); return; }
      try {
        const data = await getHistory(sid, 1, 50);
        setItems(data.items);
      } catch (e) {
        console.error(e);
      }
      setLoading(false);
    }
    load();
  }, []);

  const filtered = filter === "ALL" ? items : items.filter((i) => i.risk_level === filter);
  const scamCount = items.filter((i) => i.is_scam).length;

  return (
    <div className="popup-container">
      <header className="header">
        <div className="header-brand">
          <Link href="/" className="icon-btn" title="Back" style={{ marginRight: 4 }}>←</Link>
          <div>
            <div className="header-title">Scan History</div>
            <div className="header-subtitle">{items.length} scans · {scamCount} threats</div>
          </div>
        </div>
      </header>

      <main className="main-content" style={{ gap: 10 }}>
        {/* Filter Tabs */}
        <div style={{ display: "flex", gap: 6 }}>
          {["ALL", "CRITICAL", "HIGH", "MEDIUM", "LOW"].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              style={{
                flex: 1,
                padding: "5px 4px",
                borderRadius: "var(--radius-sm)",
                border: `1px solid ${filter === f ? "var(--border-accent)" : "var(--border)"}`,
                background: filter === f ? "rgba(99,102,241,0.15)" : "var(--bg-card)",
                color: filter === f ? "#818cf8" : "var(--text-muted)",
                fontSize: 10,
                fontWeight: 600,
                cursor: "pointer",
                transition: "all 0.2s",
              }}
            >
              {f}
            </button>
          ))}
        </div>

        {/* List */}
        {loading ? (
          <div className="history-list">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="skeleton" style={{ height: 56, borderRadius: "var(--radius-sm)" }} />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ textAlign: "center", padding: "32px 0", color: "var(--text-muted)", fontSize: 13 }}>
            <div style={{ fontSize: 32, marginBottom: 10 }}>📋</div>
            No scan history yet.<br />Visit some pages and ScamShield will scan them automatically.
          </div>
        ) : (
          <div className="history-list" style={{ maxHeight: 340, overflowY: "auto" }}>
            {filtered.map((item, i) => {
              const level = item.risk_level.toLowerCase();
              const colors: Record<string, string> = {
                critical: "#ef4444", high: "#f97316", medium: "#eab308", low: "#22c55e",
              };
              return (
                <div key={i} className="history-item">
                  <div className="history-item-header">
                    <span className="history-url">{truncateUrl(item.url)}</span>
                    <span className="history-time">{formatTime(item.created_at)}</span>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                    <span className="history-title">
                      {item.page_title || "Untitled Page"}
                    </span>
                    <span
                      className={`risk-badge risk-badge-${level}`}
                      style={{ fontSize: 10, padding: "2px 7px" }}
                    >
                      {item.risk_score}%
                    </span>
                  </div>
                  {item.scam_type && item.scam_type !== "none" && (
                    <div style={{ fontSize: 10, color: colors[level] || "var(--text-muted)", marginTop: 3 }}>
                      {item.scam_type.replace("_", " ").toUpperCase()}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </main>

      <footer className="popup-footer">
        <span className="footer-url">Session: {sessionId.slice(0, 24)}…</span>
        <span className="ai-badge">✦ DeepSeek-R1</span>
      </footer>
    </div>
  );
}
