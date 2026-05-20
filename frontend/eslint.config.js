// Flat config for ESLint 10. Lints .vue (template + script) and .ts/.tsx.
// Run: pnpm lint    (pnpm exec eslint . --max-warnings 0)
// Fix: pnpm format  (pnpm exec eslint . --fix)
//
// Layers in order: ESLint recommended → typescript-eslint → eslint-plugin-vue
// flat-recommended. Vue plugin must run last so its parser owns .vue files.

import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import vue from 'eslint-plugin-vue';
import vueParser from 'vue-eslint-parser';
import globals from 'globals';

export default [
  {
    ignores: ['dist/**', 'node_modules/**', 'coverage/**', 'dev-dist/**'],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...vue.configs['flat/recommended'],
  {
    files: ['**/*.{ts,tsx,vue}'],
    languageOptions: {
      parser: vueParser,
      parserOptions: {
        parser: tseslint.parser,
        ecmaVersion: 'latest',
        sourceType: 'module',
        extraFileExtensions: ['.vue'],
      },
      globals: { ...globals.browser, ...globals.es2024 },
    },
    rules: {
      // Surface explicit-any as an error so escapes are visible in review.
      '@typescript-eslint/no-explicit-any': 'error',
      // Force `import type { … }` for type-only imports.
      '@typescript-eslint/consistent-type-imports': 'error',
      // Vue template hygiene.
      'vue/multi-word-component-names': 'off',
      'vue/require-default-prop': 'off',
    },
  },
  {
    files: ['**/*.{js,mjs,cjs}'],
    languageOptions: {
      globals: { ...globals.node, ...globals.browser },
    },
  },
];
