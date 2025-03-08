module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module',
    project: ['./*/tsconfig.json']
  },
  env: {
    node: true,
    es2021: true
  },
  plugins: [
    '@typescript-eslint',
    'import',
    'prettier'
  ],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'plugin:import/errors',
    'plugin:import/warnings',
    'plugin:import/typescript',
    'prettier'
  ],
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
    'prettier/prettier': 'error'
  }
};
