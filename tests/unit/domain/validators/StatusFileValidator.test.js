/**
 * Unit tests for StatusFileValidator
 */

import { describe, test, expect } from '@jest/globals'
import { StatusFileValidator } from '../../../../cli/domain/validators/StatusFileValidator.js'

describe('StatusFileValidator', () => {
  let validator

  beforeEach(() => {
    validator = new StatusFileValidator()
  })

  describe('Valid .STATUS files', () => {
    test('validates minimal valid file', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package'
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(true)
      expect(result.errors).toHaveLength(0)
    })

    test('validates complete valid file with all fields', () => {
      const data = {
        status: 'active',
        progress: 75,
        type: 'r-package',
        next: [
          {
            action: 'Write tests',
            estimate: '2h',
            priority: 'high',
            blockers: []
          }
        ],
        metrics: {
          sessions_total: 45,
          sessions_this_week: 5,
          total_duration_minutes: 2340,
          last_session: '2025-12-23T10:00:00Z',
          last_updated: '2025-12-23T18:30:00Z'
        }
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(true)
      expect(result.errors).toHaveLength(0)
    })

    test('validates all valid statuses', () => {
      const statuses = ['active', 'paused', 'archived', 'complete']

      for (const status of statuses) {
        const data = { status, progress: 0, type: 'generic' }
        expect(validator.validate(data).valid).toBe(true)
      }
    })

    test('validates all valid types', () => {
      const types = [
        'r-package',
        'quarto',
        'research',
        'node',
        'python',
        'mcp',
        'spacemacs',
        'generic'
      ]

      for (const type of types) {
        const data = { status: 'active', progress: 0, type }
        expect(validator.validate(data).valid).toBe(true)
      }
    })

    test('validates progress boundary values', () => {
      expect(validator.validate({ status: 'active', progress: 0, type: 'generic' }).valid).toBe(
        true
      )
      expect(validator.validate({ status: 'active', progress: 100, type: 'generic' }).valid).toBe(
        true
      )
    })
  })

  describe('Required fields', () => {
    test('requires status field', () => {
      const data = { progress: 50, type: 'r-package' }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors).toContain('Missing required field: status')
    })

    test('requires progress field', () => {
      const data = { status: 'active', type: 'r-package' }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors).toContain('Missing required field: progress')
    })

    test('requires type field', () => {
      const data = { status: 'active', progress: 50 }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors).toContain('Missing required field: type')
    })
  })

  describe('Status field validation', () => {
    test('rejects invalid status', () => {
      const data = { status: 'invalid', progress: 50, type: 'r-package' }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('Invalid status: "invalid"')
    })
  })

  describe('Progress field validation', () => {
    test('rejects negative progress', () => {
      const data = { status: 'active', progress: -10, type: 'r-package' }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('Progress must be a number between 0 and 100')
    })

    test('rejects progress over 100', () => {
      const data = { status: 'active', progress: 150, type: 'r-package' }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('Progress must be a number between 0 and 100')
    })
  })

  describe('Type field validation', () => {
    test('rejects invalid type', () => {
      const data = { status: 'active', progress: 50, type: 'invalid-type' }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('Invalid type: "invalid-type"')
    })
  })

  describe('Next actions validation', () => {
    test('rejects non-array next field', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        next: 'not an array'
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('Field "next" must be an array')
    })

    test('rejects next action without action field', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        next: [{ estimate: '2h' }]
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('missing or invalid "action" field')
    })

    test('rejects invalid priority', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        next: [
          {
            action: 'Write tests',
            priority: 'super-urgent'
          }
        ]
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('invalid priority "super-urgent"')
    })

    test('rejects non-array blockers', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        next: [
          {
            action: 'Write tests',
            blockers: 'not an array'
          }
        ]
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('"blockers" must be an array')
    })
  })

  describe('Metrics validation', () => {
    test('rejects non-object metrics', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        metrics: 'not an object'
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('Field "metrics" must be an object')
    })

    test('rejects negative session counts', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        metrics: {
          sessions_total: -5
        }
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('must be a non-negative number')
    })

    test('rejects invalid date formats', () => {
      const data = {
        status: 'active',
        progress: 50,
        type: 'r-package',
        metrics: {
          last_session: 'not-a-date'
        }
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors[0]).toContain('must be a valid date')
    })
  })

  describe('Helper methods', () => {
    test('isValid returns true for valid data', () => {
      const data = { status: 'active', progress: 50, type: 'r-package' }

      expect(validator.isValid(data)).toBe(true)
    })

    test('isValid returns false for invalid data', () => {
      const data = { status: 'invalid', progress: 50, type: 'r-package' }

      expect(validator.isValid(data)).toBe(false)
    })

    test('getErrors returns error messages', () => {
      const data = { progress: 50, type: 'r-package' }

      const errors = validator.getErrors(data)

      expect(errors).toContain('Missing required field: status')
    })
  })

  describe('Multiple errors', () => {
    test('accumulates all validation errors', () => {
      const data = {
        status: 'invalid-status',
        progress: 150,
        type: 'invalid-type',
        next: 'not-an-array'
      }

      const result = validator.validate(data)

      expect(result.valid).toBe(false)
      expect(result.errors.length).toBeGreaterThanOrEqual(3)
    })
  })
})
