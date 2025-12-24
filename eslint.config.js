import js from '@eslint/js'
import prettierConfig from 'eslint-config-prettier'
import jestPlugin from 'eslint-plugin-jest'

export default [
  js.configs.recommended,
  prettierConfig,
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2025,
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: {
          implicitStrict: true
        }
      },
      globals: {
        process: 'readonly',
        console: 'readonly',
        Buffer: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly'
      }
    },
    rules: {
      // Errors - must fix
      'no-console': 'off',
      'prefer-const': 'error',
      'no-var': 'error',

      // Warnings - should fix but not blocking
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'no-undef': 'warn',
      'no-empty': 'warn',
      'no-misleading-character-class': 'warn',
      'object-shorthand': 'warn',
      'prefer-arrow-callback': 'warn'
    }
  },
  {
    files: ['**/*.test.js', '**/tests/**/*.js'],
    plugins: {
      jest: jestPlugin
    },
    languageOptions: {
      globals: {
        ...jestPlugin.environments.globals.globals,
        process: 'readonly',
        console: 'readonly'
      }
    },
    rules: {
      ...jestPlugin.configs.recommended.rules
    }
  },
  {
    ignores: [
      'node_modules/',
      'coverage/',
      'dist/',
      'build/',
      '.husky/',
      '*.config.js',
      'cli/node_modules/',
      'cli/coverage/',
      'docs/archive/2025-12-20-app-removal/**',
      'site/**',  // MkDocs generated site
      'scripts/**',  // Build scripts
      // Legacy CommonJS files - to be migrated
      'cli/adapters/status.js',
      'cli/adapters/workflow.js',
      'cli/api/status-api.js',
      'cli/api/workflow-api.js',
      'cli/test/test-status.js'
    ]
  }
]
