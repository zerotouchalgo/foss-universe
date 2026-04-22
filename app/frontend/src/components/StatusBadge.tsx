import React from 'react';

interface StatusBadgeProps {
  status: 'ok' | 'error' | 'checking' | 'idle';
  label?: string;
}

export function StatusBadge({ status, label }: StatusBadgeProps) {
  const colors: Record<string, string> = {
    ok: 'var(--success)',
    error: 'var(--error)',
    checking: 'var(--warning)',
    idle: 'var(--text-muted)',
  };

  const labels: Record<string, string> = {
    ok: 'Running',
    error: 'Error',
    checking: 'Checking...',
    idle: 'Idle',
  };

  return (
    <span style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: '6px',
      padding: '3px 10px',
      background: `${colors[status]}18`,
      border: `1px solid ${colors[status]}40`,
      borderRadius: '20px',
      fontSize: '0.75rem',
      fontWeight: 500,
      color: colors[status],
    }}>
      <span style={{
        width: '6px',
        height: '6px',
        borderRadius: '50%',
        background: colors[status],
        animation: status === 'checking' ? 'pulse 1.5s ease-in-out infinite' : 'none',
      }} />
      {label || labels[status]}
    </span>
  );
}
