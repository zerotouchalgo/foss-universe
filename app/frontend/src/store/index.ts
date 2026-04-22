import { create } from 'zustand';

export type StatusType = 'idle' | 'checking' | 'ok' | 'error';

interface AppState {
  brokerConfigured: boolean;
  hasApiKey: boolean;
  backendStatus: StatusType;
  redisStatus: StatusType;
  setBrokerConfigured: (v: boolean) => void;
  setHasApiKey: (v: boolean) => void;
  setBackendStatus: (s: StatusType) => void;
  setRedisStatus: (s: StatusType) => void;
}

export const useAppStore = create<AppState>((set) => ({
  brokerConfigured: false,
  hasApiKey: false,
  backendStatus: 'checking',
  redisStatus: 'idle',
  setBrokerConfigured: (v) => set({ brokerConfigured: v }),
  setHasApiKey: (v) => set({ hasApiKey: v }),
  setBackendStatus: (s) => set({ backendStatus: s }),
  setRedisStatus: (s) => set({ redisStatus: s }),
}));
