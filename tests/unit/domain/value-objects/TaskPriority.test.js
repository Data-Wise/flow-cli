/**
 * Unit tests for TaskPriority value object
 */

import { TaskPriority } from '../../../../cli/domain/value-objects/TaskPriority.js'

describe('TaskPriority Value Object', () => {
  describe('Construction', () => {
    test('creates valid priority', () => {
      const priority = new TaskPriority(TaskPriority.HIGH)

      expect(priority.value).toBe(TaskPriority.HIGH)
    })

    test('throws error for invalid priority', () => {
      expect(() => new TaskPriority('invalid')).toThrow('Invalid task priority: invalid')
    })

    test('is immutable', () => {
      const priority = new TaskPriority(TaskPriority.HIGH)

      expect(() => {
        priority._value = TaskPriority.LOW
      }).toThrow()
    })
  })

  describe('Numeric Values', () => {
    test('returns correct numeric value for low', () => {
      const priority = new TaskPriority(TaskPriority.LOW)
      expect(priority.getNumericValue()).toBe(1)
    })

    test('returns correct numeric value for medium', () => {
      const priority = new TaskPriority(TaskPriority.MEDIUM)
      expect(priority.getNumericValue()).toBe(2)
    })

    test('returns correct numeric value for high', () => {
      const priority = new TaskPriority(TaskPriority.HIGH)
      expect(priority.getNumericValue()).toBe(3)
    })

    test('returns correct numeric value for urgent', () => {
      const priority = new TaskPriority(TaskPriority.URGENT)
      expect(priority.getNumericValue()).toBe(4)
    })

    test('numeric values are ordered', () => {
      const low = new TaskPriority(TaskPriority.LOW)
      const medium = new TaskPriority(TaskPriority.MEDIUM)
      const high = new TaskPriority(TaskPriority.HIGH)
      const urgent = new TaskPriority(TaskPriority.URGENT)

      expect(low.getNumericValue()).toBeLessThan(medium.getNumericValue())
      expect(medium.getNumericValue()).toBeLessThan(high.getNumericValue())
      expect(high.getNumericValue()).toBeLessThan(urgent.getNumericValue())
    })
  })

  describe('Colors', () => {
    test('returns correct color for each priority', () => {
      expect(new TaskPriority(TaskPriority.LOW).getColor()).toBe('gray')
      expect(new TaskPriority(TaskPriority.MEDIUM).getColor()).toBe('blue')
      expect(new TaskPriority(TaskPriority.HIGH).getColor()).toBe('yellow')
      expect(new TaskPriority(TaskPriority.URGENT).getColor()).toBe('red')
    })
  })

  describe('Icons', () => {
    test('returns correct icon for each priority', () => {
      expect(new TaskPriority(TaskPriority.LOW).getIcon()).toBe('⬇️')
      expect(new TaskPriority(TaskPriority.MEDIUM).getIcon()).toBe('➡️')
      expect(new TaskPriority(TaskPriority.HIGH).getIcon()).toBe('⬆️')
      expect(new TaskPriority(TaskPriority.URGENT).getIcon()).toBe('🔥')
    })
  })

  describe('Equality', () => {
    test('equals returns true for same priority', () => {
      const priority1 = new TaskPriority(TaskPriority.HIGH)
      const priority2 = new TaskPriority(TaskPriority.HIGH)

      expect(priority1.equals(priority2)).toBe(true)
    })

    test('equals returns false for different priorities', () => {
      const priority1 = new TaskPriority(TaskPriority.HIGH)
      const priority2 = new TaskPriority(TaskPriority.LOW)

      expect(priority1.equals(priority2)).toBe(false)
    })

    test('equals returns false for non-TaskPriority', () => {
      const priority = new TaskPriority(TaskPriority.HIGH)

      expect(priority.equals('high')).toBe(false)
      expect(priority.equals(null)).toBe(false)
    })
  })

  describe('Comparison', () => {
    test('isHigherThan returns true for higher priority', () => {
      const high = new TaskPriority(TaskPriority.HIGH)
      const low = new TaskPriority(TaskPriority.LOW)

      expect(high.isHigherThan(low)).toBe(true)
    })

    test('isHigherThan returns false for lower priority', () => {
      const low = new TaskPriority(TaskPriority.LOW)
      const high = new TaskPriority(TaskPriority.HIGH)

      expect(low.isHigherThan(high)).toBe(false)
    })

    test('isHigherThan returns false for same priority', () => {
      const high1 = new TaskPriority(TaskPriority.HIGH)
      const high2 = new TaskPriority(TaskPriority.HIGH)

      expect(high1.isHigherThan(high2)).toBe(false)
    })

    test('urgent is higher than all others', () => {
      const urgent = new TaskPriority(TaskPriority.URGENT)
      const high = new TaskPriority(TaskPriority.HIGH)
      const medium = new TaskPriority(TaskPriority.MEDIUM)
      const low = new TaskPriority(TaskPriority.LOW)

      expect(urgent.isHigherThan(high)).toBe(true)
      expect(urgent.isHigherThan(medium)).toBe(true)
      expect(urgent.isHigherThan(low)).toBe(true)
    })
  })

  describe('String Representation', () => {
    test('toString returns value', () => {
      const priority = new TaskPriority(TaskPriority.HIGH)

      expect(priority.toString()).toBe('high')
    })
  })

  describe('All Priority Levels', () => {
    test('all defined priorities are valid', () => {
      const priorities = [
        TaskPriority.LOW,
        TaskPriority.MEDIUM,
        TaskPriority.HIGH,
        TaskPriority.URGENT
      ]

      for (const priorityValue of priorities) {
        expect(() => new TaskPriority(priorityValue)).not.toThrow()
      }
    })

    test('all priorities have colors', () => {
      const priorities = [
        TaskPriority.LOW,
        TaskPriority.MEDIUM,
        TaskPriority.HIGH,
        TaskPriority.URGENT
      ]

      for (const priorityValue of priorities) {
        const priority = new TaskPriority(priorityValue)
        expect(priority.getColor()).toBeTruthy()
        expect(typeof priority.getColor()).toBe('string')
      }
    })

    test('all priorities have icons', () => {
      const priorities = [
        TaskPriority.LOW,
        TaskPriority.MEDIUM,
        TaskPriority.HIGH,
        TaskPriority.URGENT
      ]

      for (const priorityValue of priorities) {
        const priority = new TaskPriority(priorityValue)
        expect(priority.getIcon()).toBeTruthy()
        expect(typeof priority.getIcon()).toBe('string')
      }
    })
  })
})
