import { createApp } from 'vue';
import * as Sentry from '@sentry/vue';
import App from './App.vue';

const app = createApp(App);

const dsn = import.meta.env.VITE_SENTRY_DSN;
if (dsn) {
  Sentry.init({
    app,
    dsn,
    tracesSampleRate: 0.1,
    release: import.meta.env.VITE_GIT_SHA ?? 'dev',
  });
}

app.config.errorHandler = (err) => {
  Sentry.captureException(err);
  console.error(err);
};

app.mount('#app');
