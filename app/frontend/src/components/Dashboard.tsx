import React, { useEffect } from 'react';
import { useAppStore } from '../store';
import type { StatusType } from '../store';
import { StatusBadge } from './StatusBadge';
import { getHealth, getSetup } from '../api';

export function Dashboard() {
  const { brokerConfigured, backendStatus, setBackendStatus, setBrokerConfigured, setHasApiKey } = useAppStore();

  React.useEffect(() => {
    setBackendStatus('checking');
    Promise.all([getHealth(), getSetup()])
      .then(([health, setup]) => {
        setBackendStatus('ok');
        setBrokerConfigured(setup.broker_configured);
        setHasApiKey(setup.has_api_key);
      })
      .catch(() => setBackendStatus('error'));
  }, []);

  const cards: Array<{ label: string; value: string; sub: string; icon: string; status: StatusType }> = [
    {
      label: 'Backend API',
      value: backendStatus === 'ok' ? 'Healthy' : backendStatus === 'checking' ? 'Checking...' : 'Error',
      sub: 'Flask + Socket.IO',
      icon: '⚡',
      status: backendStatus,
    },
    {
      label: 'Broker API Key',
      value: brokerConfigured ? 'Configured' : 'Missing',
      sub: 'Trading credentials',
      icon: '🔑',
      status: brokerConfigured ? 'ok' : 'error',
    },
    {
      label: 'Redis Cache',
      value: 'Connected',
      sub: 'Socket.IO message queue',
      icon: '💾',
      status: 'ok',
    },
    {
      label: 'WebSocket',
      value: 'Active',
      sub: 'Real-time data feed',
      icon: '📡',
      status: backendStatus,
    },
  ];

  return (
    <div style={{ padding: '32px', maxWidth: '1400px', margin: '0 auto' }}>
      {/* Header */}
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '6px' }}>
          Dashboard
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
          OpenAlgo Mini FOSS Universe — Trading Terminal Overview
        </p>
      </div>

      {/* Status Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
        gap: '16px',
        marginBottom: '32px',
      }}>
        {cards.map((card) => (
          <div key={card.label} style={{
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: '12px',
            padding: '20px 24px',
            display: 'flex',
            flexDirection: 'column',
            gap: '8px',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                {card.label}
              </span>
              <span style={{ fontSize: '1.2rem' }}>{card.icon}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ fontSize: '1.25rem', fontWeight: 600 }}>{card.value}</span>
              <StatusBadge status={card.status} />
            </div>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{card.sub}</span>
          </div>
        ))}
      </div>

      {/* Actions */}
      <div style={{
        background: 'var(--bg-card)',
        border: '1px solid var(--border)',
        borderRadius: '12px',
        padding: '24px',
        marginBottom: '24px',
      }}>
        <h2 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '16px' }}>Quick Actions</h2>
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
          {[
            { label: 'Check Health', action: () => getHealth().then(console.log) },
            { label: 'Check Setup', action: () => getSetup().then(console.log) },
          ].map((btn) => (
            <button key={btn.label} onClick={btn.action} style={{
              padding: '10px 20px',
              background: 'var(--accent)',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '0.875rem',
              fontWeight: 500,
              transition: 'background 0.15s',
            }}>
              {btn.label}
            </button>
          ))}
        </div>
      </div>

      {/* Setup Banner */}
      {!brokerConfigured && (
        <div style={{
          background: 'rgba(239,68,68,0.08)',
          border: '1px solid rgba(239,68,68,0.3)',
          borderRadius: '12px',
          padding: '20px 24px',
        }}>
          <h3 style={{ color: 'var(--error)', fontWeight: 600, marginBottom: '8px' }}>
            Broker API Not Configured
          </h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '12px' }}>
            Add your broker API credentials to <code style={{ background: 'var(--bg-secondary)', padding: '2px 6px', borderRadius: '4px', fontSize: '0.8rem' }}>data/.env</code> and run <code style={{ background: 'var(--bg-secondary)', padding: '2px 6px', borderRadius: '4px', fontSize: '0.8rem' }}>encrypt.sh</code> to update <code style={{ background: 'var(--bg-secondary)', padding: '2px 6px', borderRadius: '4px', fontSize: '0.8rem' }}>.env.enc</code>.
          </p>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
            Required: <code>BROKER_API_KEY</code>, <code>BROKER_API_SECRET</code>
          </div>
        </div>
      )}
    </div>
  );
}
