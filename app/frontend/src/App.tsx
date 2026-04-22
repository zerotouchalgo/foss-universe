import React, { useState } from 'react';
import { NavBar } from './components/NavBar';
import { Dashboard } from './components/Dashboard';

const PAGES: Record<string, React.ReactNode> = {
  dashboard: <Dashboard />,
  markets: <PlaceholderPage title="Markets" desc="Live market data, orderbook, price charts" />,
  strategies: <PlaceholderPage title="Strategies" desc="Build and manage your trading strategies" />,
  trades: <PlaceholderPage title="Trade History" desc="View executed trades and performance" />,
  data: <PlaceholderPage title="Data" desc="Historical data and analytics" />,
};

function PlaceholderPage({ title, desc }: { title: string; desc: string }) {
  return (
    <div style={{
      padding: '48px 32px',
      textAlign: 'center',
      maxWidth: '600px',
      margin: '0 auto',
    }}>
      <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '12px' }}>{title}</h2>
      <p style={{ color: 'var(--text-secondary)' }}>{desc}</p>
      <div style={{
        marginTop: '32px',
        padding: '24px',
        background: 'var(--bg-card)',
        borderRadius: '12px',
        border: '1px dashed var(--border)',
        color: 'var(--text-muted)',
        fontSize: '0.875rem',
      }}>
        {title} page coming soon
      </div>
    </div>
  );
}

export default function App() {
  const [activeNav, setActiveNav] = useState('dashboard');

  return (
    <div style={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      <NavBar activeNav={activeNav} onNavChange={setActiveNav} />
      <main style={{ flex: 1 }}>
        {PAGES[activeNav]}
      </main>
      <footer style={{
        padding: '16px 24px',
        borderTop: '1px solid var(--border)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        fontSize: '0.75rem',
        color: 'var(--text-muted)',
      }}>
        <span>FOSS Universe v1.0.0</span>
        <span>Powered by OpenAlgo</span>
      </footer>
    </div>
  );
}
