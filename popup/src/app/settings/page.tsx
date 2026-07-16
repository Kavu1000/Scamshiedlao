"use client";
import { useState } from "react";
import Link from "next/link";

export default function SettingsPage() {
  const [sensitivity, setSensitivity] = useState(50);
  const [language, setLanguage] = useState<"lo" | "en">("lo");
  const [notifications, setNotifications] = useState(true);
  const [backendUrl, setBackendUrl] = useState("http://localhost:8000");
  const [saved, setSaved] = useState(false);

  const save = async () => {
    const settings = { sensitivity, language, notifications, backendUrl };
    if (typeof chrome !== "undefined" && chrome.storage) {
      chrome.storage.local.set({ scamshieldSettings: settings });
    } else {
      localStorage.setItem("scamshieldSettings", JSON.stringify(settings));
    }
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <div className="popup-container">
      <header className="header">
        <div className="header-brand">
          <Link href="/" className="icon-btn" title="Back" style={{ marginRight: 4 }}>←</Link>
          <div>
            <div className="header-title">Settings</div>
            <div className="header-subtitle">ScamShield Lao</div>
          </div>
        </div>
      </header>

      <main className="main-content">
        {/* Language */}
        <div className="settings-section">
          <div className="settings-title">Language / ພາສາ</div>
          <div style={{ display: "flex", gap: 8 }}>
            {(["lo", "en"] as const).map((lang) => (
              <button
                key={lang}
                onClick={() => setLanguage(lang)}
                style={{
                  flex: 1, padding: "8px", borderRadius: "var(--radius-sm)",
                  border: `1px solid ${language === lang ? "var(--border-accent)" : "var(--border)"}`,
                  background: language === lang ? "rgba(99,102,241,0.15)" : "var(--bg-card)",
                  color: language === lang ? "#818cf8" : "var(--text-secondary)",
                  fontSize: 13, fontWeight: 600, cursor: "pointer",
                }}
              >
                {lang === "lo" ? "🇱🇦 ລາວ" : "🇬🇧 English"}
              </button>
            ))}
          </div>
        </div>

        {/* Detection Sensitivity */}
        <div className="settings-section">
          <div className="settings-title">Detection Sensitivity</div>
          <div className="settings-row" style={{ flexDirection: "column", alignItems: "stretch", gap: 10 }}>
            <div style={{ display: "flex", justifyContent: "space-between" }}>
              <span className="settings-row-label">Sensitivity Level</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: "var(--brand-primary)" }}>{sensitivity}%</span>
            </div>
            <input
              type="range" min={20} max={90} value={sensitivity}
              onChange={(e) => setSensitivity(Number(e.target.value))}
              style={{ width: "100%", accentColor: "var(--brand-primary)" }}
            />
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 10, color: "var(--text-muted)" }}>
              <span>Fewer alerts</span>
              <span>More alerts</span>
            </div>
          </div>
        </div>

        {/* Notifications */}
        <div className="settings-section">
          <div className="settings-title">Notifications</div>
          <div className="settings-row">
            <div>
              <div className="settings-row-label">Show page banner</div>
              <div className="settings-row-desc">Display warning banner when scam is detected</div>
            </div>
            <label className="toggle-switch">
              <input type="checkbox" checked={notifications} onChange={(e) => setNotifications(e.target.checked)} />
              <span className="toggle-track" />
              <span className="toggle-thumb" />
            </label>
          </div>
        </div>

        {/* Backend URL */}
        <div className="settings-section">
          <div className="settings-title">Backend API URL</div>
          <input
            type="text" value={backendUrl}
            onChange={(e) => setBackendUrl(e.target.value)}
            style={{
              width: "100%", padding: "9px 12px",
              background: "var(--bg-card)", border: "1px solid var(--border)",
              borderRadius: "var(--radius-sm)", color: "var(--text-primary)",
              fontSize: 12, outline: "none", fontFamily: "monospace",
            }}
            placeholder="http://localhost:8000"
          />
        </div>

        {/* AI Info */}
        <div style={{
          padding: "10px 12px",
          background: "rgba(99,102,241,0.08)",
          border: "1px solid rgba(99,102,241,0.2)",
          borderRadius: "var(--radius-sm)",
          fontSize: 11,
          color: "#818cf8",
          lineHeight: 1.6,
        }}>
          <strong>✦ AI Engine: DeepSeek-R1</strong> via OpenRouter<br />
          Add your API key to <code style={{ fontSize: 10, background: "rgba(255,255,255,0.05)", padding: "1px 4px", borderRadius: 3 }}>backend/.env</code> to enable AI analysis.
        </div>

        <button onClick={save} className="btn btn-primary">
          {saved ? "✓ Saved!" : "💾 Save Settings"}
        </button>
      </main>
    </div>
  );
}
