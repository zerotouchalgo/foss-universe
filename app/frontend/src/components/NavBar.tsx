import React from 'react';
import { Layout, BarChart2, Activity, Shield, Database, Globe } from 'lucide-react';
import { useAppStore } from '../store';
import { StatusBadge } from './StatusBadge';

const NAV_ITEMS = [
  { label: 'Dashboard', icon: <Layout size={16} />, id: 'dashboard' },
  { label: 'Markets', icon: <BarChart2 size={16} />, id: 'markets' },
  { label: 'Strategies', icon: <Activity size={16} />, id: 'strategies' },
  { label: 'Trades', icon: <Shield size={16} />, id: 'trades' },
  { label: 'Data', icon: <Database size={16} />, id: 'data' },
];

interface NavBarProps {
  activeNav: string;
  onNavChange: (id: string) => void;
}

export function NavBar({ activeNav, onNavChange }: NavBarProps) {
  return (
    <nav style={{
      display: 'flex',
      alignItems: 'center',
      gap: '4px',
      padding: '0 24px',
      height: '48px',
      background: 'var(--bg-secondary)',
      borderBottom: '1px solid var(--border)',
      overflowX: 'auto',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginRight: '16px' }}>
        <Globe size={20} color="var(--accent)" />
        <span style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--accent-glow)', whiteSpace: 'nowrap' }}>
          FOSS Universe
        </span>
      </div>
      {NAV_ITEMS.map((item) => (
        <button
          key={item.id}
          onClick={() => onNavChange(item.id)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '6px 12px',
            background: activeNav === item.id ? 'rgba(99,102,241,0.15)' : 'transparent',
            color: activeNav === item.id ? 'var(--accent-glow)' : 'var(--text-secondary)',
            border: 'none',
            borderRadius: '6px',
            fontSize: '0.85rem',
            fontWeight: activeNav === item.id ? 500 : 400,
            whiteSpace: 'nowrap',
            transition: 'all 0.15s',
          }}
        >
          {item.icon}
          {item.label}
        </button>
      ))}
    </nav>
  );
}
