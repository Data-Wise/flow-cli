/**
 * Jest configuration for ES modules
 */
export default {
  testEnvironment: 'node',
  transform: {},
  rootDir: '..',
  testMatch: ['<rootDir>/tests/**/*.test.js'],
  collectCoverageFrom: ['<rootDir>/cli/domain/**/*.js', '!<rootDir>/cli/domain/**/*.test.js'],
  coverageDirectory: '<rootDir>/cli/coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  testPathIgnorePatterns: ['/node_modules/', '<rootDir>/docs/', '<rootDir>/site/'],
  verbose: true
}
