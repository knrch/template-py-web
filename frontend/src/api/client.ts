/**
 * Single API client. All backend calls go through here.
 */
import * as Sentry from '@sentry/vue';

const BASE = import.meta.env.VITE_API_URL || '';

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly body: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  Sentry.addBreadcrumb({
    category: 'api',
    message: `${init?.method ?? 'GET'} ${path}`,
    level: 'info',
  });

  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...(init?.headers ?? {}) },
    credentials: 'include',
    ...init,
  });

  if (!res.ok) {
    const body: unknown = await res.json().catch(() => ({}));
    throw new ApiError(`HTTP ${res.status}`, res.status, body);
  }
  return (await res.json()) as T;
}

export interface Health {
  status: string;
  version: string;
  checks: Record<string, string>;
}

export const fetchHealth = (): Promise<Health> => request<Health>('/health');
