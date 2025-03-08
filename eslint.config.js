import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import';
import eslintPluginPrettierRecommended from 'eslint-plugin-prettier/recommended';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  ...tseslint.configs.recommendedRequiringTypeChecking,
  {
    languageOptions: {
      parserOptions: {
        project: ['./*/tsconfig.json'],
        ecmaVersion: 2021,
        sourceType: 'module',
      },
      globals: {
        ...eslint.configs.recommended.languageOptions.globals,
      },
    },
    settings: {
      'import/resolver': {
        typescript: true,
        node: true,
      },
    },
    plugins: {
      import: importPlugin,
    },
    rules: {
      // Strict rules
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/explicit-function-return-type': 'error',
      '@typescript-eslint/explicit-module-boundary-types': 'error',
      '@typescript-eslint/no-unused-vars': ['error', { 'argsIgnorePattern': '^_' }],
      '@typescript-eslint/no-non-null-assertion': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'import/order': [
        'error', 
        { 'groups': ['builtin', 'external', 'internal', ['parent', 'sibling', 'index']] }
      ],
      'prettier/prettier': 'error',
    },
  },
  importPlugin.configs.recommended,
  importPlugin.configs.typescript,
  eslintPluginPrettierRecommended,
);
