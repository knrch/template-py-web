import { fileURLToPath, URL } from 'node:url';
import { defineConfig, loadEnv } from 'vite';
import vue from '@vitejs/plugin-vue';
import { sentryVitePlugin } from '@sentry/vite-plugin';

// `@sentry/vite-plugin` uploads source maps to Sentry at build time.
// Activates only when SENTRY_AUTH_TOKEN + SENTRY_ORG + SENTRY_PROJECT are
// set (CI). Local builds skip the upload but still emit source maps so
// the DX is the same.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const hasSentryToken = Boolean(env.SENTRY_AUTH_TOKEN && env.SENTRY_ORG && env.SENTRY_PROJECT);

  return {
    plugins: [
      vue(),
      hasSentryToken
        ? sentryVitePlugin({
            org: env.SENTRY_ORG,
            project: env.SENTRY_PROJECT,
            authToken: env.SENTRY_AUTH_TOKEN,
            release: { name: env.VITE_GIT_SHA },
          })
        : null,
    ].filter(Boolean),
    build: {
      sourcemap: true,
    },
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
    server: {
      port: 5173,
      proxy: {
        '/api': {
          target: 'http://localhost:8000',
          changeOrigin: true,
        },
        '/health': {
          target: 'http://localhost:8000',
          changeOrigin: true,
        },
      },
    },
    test: {
      environment: 'happy-dom',
      globals: true,
      include: ['tests/unit/**/*.test.ts'],
    },
  };
});
