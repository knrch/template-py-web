<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { fetchHealth } from './api/client';

const status = ref<'unknown' | 'ok' | 'fail'>('unknown');
const version = ref<string>('');

onMounted(async () => {
  try {
    const h = await fetchHealth();
    status.value = h.status === 'ok' ? 'ok' : 'fail';
    version.value = h.version;
  } catch {
    status.value = 'fail';
  }
});
</script>

<template>
  <main>
    <h1><PROJECT_NAME></h1>
    <p>Backend: <strong :class="status">{{ status }}</strong></p>
    <p v-if="version">Version: <code>{{ version }}</code></p>
  </main>
</template>

<style scoped>
main {
  font-family: system-ui, sans-serif;
  max-width: 40rem;
  margin: 4rem auto;
  padding: 0 1rem;
}
.ok { color: green; }
.fail { color: red; }
.unknown { color: gray; }
</style>
