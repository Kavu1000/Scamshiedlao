"use client";
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { ScanResult, checkHealth } from "@/lib/api";

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
          {result.ai_analyzed && <span className="ai-badge">✦ AI Verified</span>}
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

function UnavailableCard({ message }: { message: string }) {
  return (
    <div className="unavailable-card">
      <span className="unavailable-icon">🔍</span>
      <div className="unavailable-title">Not Scanned Yet</div>
      <div className="unavailable-desc">{message}</div>
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
  const [scanning, setScanning] = useState(true);
  const [unavailableMsg, setUnavailableMsg] = useState<string | null>(null);
  const [backendOnline, setBackendOnline] = useState(true);
  const [currentUrl, setCurrentUrl] = useState("");

  const triggerScan = useCallback(async () => {
    setScanning(true);
    setUnavailableMsg(null);
    setScanResult(null);

    if (typeof chrome === "undefined" || !chrome.tabs) {
      setUnavailableMsg("Load this as a Chrome extension to scan the active tab.");
      setScanning(false);
      return;
    }

    const tab = await new Promise<{ id?: number; url?: string }>((resolve) =>
      chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => resolve(tabs[0] || {}))
    );

    if (!tab.id) {
      setUnavailableMsg("No active tab found.");
      setScanning(false);
      return;
    }
    setCurrentUrl(tab.url || "");

    const response = await new Promise<unknown>((resolve) =>
      chrome.tabs.sendMessage(tab.id!, { type: "TRIGGER_SCAN" }, (res) => resolve(res))
    );

    const errored = chrome.runtime.lastError || !response || (response as { error?: string }).error;
    if (errored) {
      const reason = (response as { error?: string })?.error;
      setUnavailableMsg(
        reason || "Couldn't reach this page — try reloading the tab, or this page type isn't supported."
      );
      setScanning(false);
      return;
    }

    setScanResult(response as ScanResult);
    setScanning(false);
  }, []);

  useEffect(() => {
    (async () => {
      const health = await checkHealth();
      setBackendOnline(health);
      if (health) await triggerScan();
      else setScanning(false);
    })();
  }, [triggerScan]);

  const statusText = !backendOnline
    ? "Backend Offline"
    : scanning
    ? "Scanning current page... (ກຳລັງກວດ)"
    : scanResult?.is_scam
    ? `Scam detected on this page: ${scanResult.risk_score}%`
    : scanResult
    ? "Page is Safe ✓"
    : "Ready to scan";

  const statusDotClass = !backendOnline
    ? "status-dot status-dot-offline"
    : scanning
    ? "status-dot status-dot-scanning"
    : scanResult?.is_scam
    ? "status-dot status-dot-threat"
    : scanResult
    ? "status-dot status-dot-safe"
    : "status-dot status-dot-offline";

  return (
    <div className="popup-container">
      {scanning && <div className="scan-progress-bar" />}

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
          <button
            className={`icon-btn-scan${scanning ? " spin" : ""}`}
            title="Scan this page"
            onClick={triggerScan}
            disabled={scanning || !backendOnline}
          >
            ↻
          </button>
        </div>

        {/* Result */}
        {scanning ? (
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
        ) : scanResult ? (
          <SafeCard />
        ) : (
          <UnavailableCard
            message={unavailableMsg || "Click Scan This Page to check for scam indicators."}
          />
        )}

        {/* Actions */}
        <div className="btn-group">
          <button
            className="btn btn-primary"
            style={{ flex: 2 }}
            onClick={triggerScan}
            disabled={scanning || !backendOnline}
          >
            {scanning ? "⏳ Scanning..." : scanResult ? "↻ Re-scan Page" : "🔍 Scan This Page"}
          </button>
          <Link href="/history" className="btn btn-secondary" style={{ flex: 1 }}>
            🕐 History
          </Link>
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
        {scanResult?.ai_analyzed && <span className="ai-badge">✦ AI Verified</span>}
      </footer>
    </div>
  );
}
