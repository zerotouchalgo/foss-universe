const API_BASE = '/';

export interface HealthResponse {
  status: string;
  env: string;
}

export interface SetupResponse {
  status: string;
  has_api_key: boolean;
  broker_configured: boolean;
}

export async function getHealth(): Promise<HealthResponse> {
  const res = await fetch(`${API_BASE}api/health`);
  return res.json();
}

export async function getSetup(): Promise<SetupResponse> {
  const res = await fetch(`${API_BASE}auth/check-setup`);
  return res.json();
}
