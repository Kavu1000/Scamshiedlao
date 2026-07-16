"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { ScanResult, getChromeStorage, setChromeStorage, checkHealth } from "@/lib/api";

function RiskScoreCard({ result }: { result: ScanResult }) {
  const level = result.risk_level.toLowerCase();
  const [displayScore, setDisplayScore] = useState(0);

  useEffect(() => {
    const timer = setTimeout(() => setDisplayScore(result.risk_score), 100);
    return () => clearTimeout(timer);
  }, [result.risk_score]);

  return (
    <div className={`risk-card risk-card-${level}`}>
      <div className="risk-card-header">
        <span className="risk-label">Risk Analysis</span>
        <div style={{ display: "flex", gap: "6px", alignItems: "center" }}>
          {result.ai_analyzed && (
            <span className="ai-badge">✦ DeepSeek-R1</span>
          )}
          <span className={`risk-badge risk-badge-${level}`}>
            {level === "critical" && "🔴"} 
            {level === "high" && "🟠"}
            {level === "medium" && "🟡"}
            {level === "low" && "🟢"}
            {" "}{result.risk_level}
          </span>
        </div>
      </div>

      <div className="risk-score-row">
        <span className={`risk-score-number risk-score-${level}`}>{displayScore}</span>
        <span className="risk-score-suffix">/ 100</span>
        {result.scam_type !== "none" && (
          <span className="risk-score-type">
            {result.scam_type.replace("_", " ")}
          </span>
        )}
      </div>

      <div className="progress-bar-track">
        <div
          className={`progress-bar-fill progress-fill-${level}`}
          style={{ width: `${displayScore}%` }}
        />
      </div>

      {result.reasons.length > 0 && (
        <div className="reasons-list">
          {result.reasons.slice(0, 3).map((r, i) => (
            <div key={i} className="reason-item">
              <span className="reason-icon">▸</span>
              <span>{r}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function SafeCard() {
  return (
    <div className="safe-card">
      <span className="safe-icon">🛡</span>
      <div className="safe-title">Page is Safe</div>
      <div className="safe-desc">No scam indicators detected on this page.</div>
    </div>
  );
}

function SkeletonCard() {
  return (
    <div className="risk-card">
      <div className="skeleton" style={{ height: 16, width: "60%", marginBottom: 12 }} />
      <div className="skeleton" style={{ height: 40, width: "40%", marginBottom: 12 }} />
      <div className="skeleton" style={{ height: 6, marginBottom: 12 }} />
      <div className="skeleton" style={{ height: 12, marginBottom: 6 }} />
      <div className="skeleton" style={{ height: 12, width: "80%" }} />
    </div>
  );
}

export default function PopupPage() {
  const [scanResult, setScanResult] = useState<ScanResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [autoScan, setAutoScan] = useState(true);
  const [backendOnline, setBackendOnline] = useState(true);
  const [currentUrl, setCurrentUrl] = useState("");

  useEffect(() => {
    async function init() {
      const health = await checkHealth();
      setBackendOnline(health);

      const stored = await getChromeStorage<any>(["lastScanResult", "autoScan", "lastScanUrl"]);
      if (stored.lastScanResult) setScanResult(stored.lastScanResult as ScanResult);
      if (stored.autoScan !== undefined) setAutoScan(stored.autoScan as boolean);
      if (stored.lastScanUrl) setCurrentUrl(stored.lastScanUrl as string);
      setLoading(false);
    }
    init();
  }, []);

  const handleAutoScanToggle = async (value: boolean) => {
    setAutoScan(value);
    await setChromeStorage({ autoScan: value });
    if (typeof chrome !== "undefined" && chrome.runtime) {
      chrome.runtime.sendMessage({ type: "SET_AUTO_SCAN", value });
    }
  };

  const statusText = !backendOnline
    ? "Backend Offline"
    : loading
    ? "Scanning... (ກຳລັງປົກປ້ອງ)"
    : scanResult?.is_scam
    ? `Scam detected on this page: ${scanResult.risk_score}%`
    : "Page is Safe ✓";

  const statusDotClass = !backendOnline
    ? "status-dot status-dot-offline"
    : loading
    ? "status-dot status-dot-scanning"
    : scanResult?.is_scam
    ? "status-dot status-dot-threat"
    : "status-dot status-dot-safe";

  return (
    <div className="popup-container">
      {/* Header */}
      <header className="header">
        <div className="header-brand">
          <div className="header-logo">🛡</div>
          <div>
            <div className="header-title">ScamShield Lao</div>
            <div className="header-subtitle">Real-time Protection</div>
          </div>
        </div>
        <div className="header-actions">
          <Link href="/history" className="icon-btn" title="Scan History">🕐</Link>
          <Link href="/settings" className="icon-btn" title="Settings">⚙</Link>
        </div>
      </header>

      {/* Main */}
      <main className="main-content">
        {/* Status Bar */}
        <div className="status-bar">
          <div className="status-indicator">
            <span className={statusDotClass} />
            <span className="status-text">{statusText}</span>
          </div>
          <div className="status-right">
            <span className="toggle-label">Auto-Scan</span>
            <label className="toggle-switch">
              <input
                type="checkbox"
                checked={autoScan}
                onChange={(e) => handleAutoScanToggle(e.target.checked)}
              />
              <span className="toggle-track" />
              <span className="toggle-thumb" />
            </label>
          </div>
        </div>

        {/* Result */}
        {loading ? (
          <SkeletonCard />
        ) : scanResult?.is_scam ? (
          <>
            {/* Threat alert */}
            <div className="threat-summary">
              <span className="threat-count">⚠</span>
              <div>
                <strong className="threat-text">
                  <strong>Scam Detected!</strong>
                </strong>
                <div className="threat-text">
                  Click highlighted posts on the page to view detailed threat analysis.
                </div>
              </div>
            </div>
            <RiskScoreCard result={scanResult} />
          </>
        ) : (
          <SafeCard />
        )}

        {/* Actions */}
        <div className="btn-group">
          <Link href="/history" className="btn btn-secondary" style={{ flex: 1 }}>
            🕐 View Scan History
          </Link>
          <button className="btn btn-secondary" style={{ flex: 1 }}
            onClick={() => {
              if (typeof chrome !== "undefined" && chrome.tabs) {
                chrome.tabs.query({ active: true, currentWindow: true }, (tabs: any[]) => {
                  if (tabs[0]?.id) chrome.tabs.reload(tabs[0].id);
                });
              }
            }}>
            ↻ Re-scan
          </button>
        </div>

        {!backendOnline && (
          <div style={{
            padding: "10px 12px",
            background: "rgba(239,68,68,0.08)",
            border: "1px solid rgba(239,68,68,0.2)",
            borderRadius: "var(--radius-sm)",
            fontSize: 12,
            color: "#ef4444",
          }}>
            ⚠ Backend offline — start the Python server on port 8000
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="popup-footer">
        <span className="footer-url">{currentUrl || "No page scanned yet"}</span>
        <span className="ai-badge">✦ DeepSeek-R1</span>
      </footer>
    </div>
  );
}
