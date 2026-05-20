// Sentry init for Vue 3. Called from main.ts after the app is created.
// All knobs are env-driven so prod/dev split happens in .env, not in code.

import * as Sentry from '@sentry/vue';
import type { App } from 'vue';
import type { Router } from 'vue-router';

interface InitArgs {
  app: App;
  router?: Router;
}

export function initSentry({ app, router }: InitArgs): void {
  const dsn = import.meta.env.VITE_SENTRY_DSN;
  if (!dsn) {
    // No-op in dev unless DSN is set. Keeps local logs clean.
    return;
  }

  const tracesSampleRate = Number(import.meta.env.VITE_SENTRY_TRACES_SAMPLE_RATE ?? '0.1');
  const replaysSessionSampleRate = Number(
    import.meta.env.VITE_SENTRY_REPLAYS_SESSION_SAMPLE_RATE ?? '0',
  );
  const replaysOnErrorSampleRate = Number(
    import.meta.env.VITE_SENTRY_REPLAYS_ON_ERROR_SAMPLE_RATE ?? '1.0',
  );

  // Connect frontend traces to backend traces by propagating sentry-trace +
  // baggage headers to these origins. Defaults to same-origin /api/* plus
  // whatever VITE_API_URL points at.
  const apiUrl = import.meta.env.VITE_API_URL ?? '';
  const tracePropagationTargets: (string | RegExp)[] = [/^\/api\//];
  if (apiUrl) {
    tracePropagationTargets.push(apiUrl);
  }

  Sentry.init({
    app,
    dsn,
    environment: import.meta.env.VITE_SENTRY_ENVIRONMENT ?? import.meta.env.MODE,
    release: import.meta.env.VITE_GIT_SHA ?? 'dev',
    integrations: [
      Sentry.browserTracingIntegration(router ? { router } : undefined),
      Sentry.replayIntegration({ maskAllText: true, blockAllMedia: true }),
    ],
    tracesSampleRate,
    tracePropagationTargets,
    replaysSessionSampleRate,
    replaysOnErrorSampleRate,
    // Forward Vue lifecycle errors and route through the global handler.
    logErrors: true,
  });

  app.config.errorHandler = (err, _instance, info) => {
    Sentry.captureException(err, { extra: { vueInfo: info } });
    // Keep console output for local dev / Railway logs.
    // eslint-disable-next-line no-console
    console.error(err);
  };
}
