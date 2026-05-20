import { createApp } from 'vue';
import App from './App.vue';
import { initSentry } from './sentry';

const app = createApp(App);

// Pass `router` here once vue-router is wired:
//   import { router } from './router';
//   initSentry({ app, router });
initSentry({ app });

app.mount('#app');
