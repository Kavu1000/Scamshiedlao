import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ScamShield Lao",
  description: "Real-time scam detection for Lao users powered by AI",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="lo">
      <body>{children}</body>
    </html>
  );
}
