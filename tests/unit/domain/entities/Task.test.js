/**
 * Unit tests for Task entity
 */

import { Task } from '../../../../cli/domain/entities/Task.js'
import { TaskPriority } from '../../../../cli/domain/value-objects/TaskPriority.js'

describe('Task Entity', () => {
  describe('Construction', () => {
    test('creates task with required fields', () => {
      const task = new Task('task-1', 'Fix bug in Session entity')

      expect(task.id).toBe('task-1')
      expect(task.description).toBe('Fix bug in Session entity')
      expect(task.priority.value).toBe(TaskPriority.MEDIUM)
      expect(task.completed).toBe(false)
      expect(task.tags).toEqual([])
    })

    test('creates task with optional fields', () => {
      const task = new Task('task-1', 'Fix bug', {
        priority: TaskPriority.HIGH,
        projectId: 'project-1',
        sessionId: 'session-1',
        tags: ['bug', 'urgent'],
        estimatedMinutes: 30,
        dueDate: new Date('2025-12-25')
      })

      expect(task.priority.value).toBe(TaskPriority.HIGH)
      expect(task.projectId).toBe('project-1')
      expect(task.sessionId).toBe('session-1')
      expect(task.tags).toEqual(['bug', 'urgent'])
      expect(task.estimatedMinutes).toBe(30)
      expect(task.dueDate).toBeInstanceOf(Date)
    })

    test('accepts TaskPriority instance', () => {
      const priority = new TaskPriority(TaskPriority.URGENT)
      const task = new Task('task-1', 'Fix bug', { priority })

      expect(task.priority).toBe(priority)
    })

    test('throws error if ID is empty', () => {
      expect(() => new Task('', 'description')).toThrow('Task must have an ID')
    })

    test('throws error if description is empty', () => {
      expect(() => new Task('task-1', '')).toThrow('Task must have a description')
    })

    test('throws error if description is too long', () => {
      const longDesc = 'a'.repeat(501)
      expect(() => new Task('task-1', longDesc)).toThrow('Task description too long')
    })

    test('throws error if tags is not an array', () => {
      expect(() => new Task('task-1', 'description', { tags: 'invalid' })).toThrow(
        'Task tags must be an array'
      )
    })

    test('throws error if tags contains non-strings', () => {
      expect(() => new Task('task-1', 'description', { tags: ['valid', 123] })).toThrow(
        'Task tags must be strings'
      )
    })

    test('throws error for invalid estimated minutes', () => {
      expect(() => new Task('task-1', 'description', { estimatedMinutes: -10 })).toThrow(
        'Estimated minutes must be a non-negative number'
      )
    })

    test('throws error for invalid actual minutes', () => {
      expect(() => new Task('task-1', 'description', { actualMinutes: 'invalid' })).toThrow(
        'Actual minutes must be a non-negative number'
      )
    })
  })

  describe('Complete/Uncomplete', () => {
    test('completes task', () => {
      const task = new Task('task-1', 'Fix bug')

      task.complete()

      expect(task.completed).toBe(true)
      expect(task.completedAt).toBeInstanceOf(Date)
    })

    test('throws error when completing already completed task', () => {
      const task = new Task('task-1', 'Fix bug')
      task.complete()

      expect(() => task.complete()).toThrow('Task is already completed')
    })

    test('uncompletes task', () => {
      const task = new Task('task-1', 'Fix bug')
      task.complete()

      task.uncomplete()

      expect(task.completed).toBe(false)
      expect(task.completedAt).toBeNull()
    })

    test('throws error when uncompleting non-completed task', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(() => task.uncomplete()).toThrow('Task is not completed')
    })
  })

  describe('Update Description', () => {
    test('updates description', () => {
      const task = new Task('task-1', 'Old description')

      task.updateDescription('New description')

      expect(task.description).toBe('New description')
    })

    test('throws error for empty description', () => {
      const task = new Task('task-1', 'Old description')

      expect(() => task.updateDescription('')).toThrow('Description cannot be empty')
    })

    test('throws error for too long description', () => {
      const task = new Task('task-1', 'Old description')
      const longDesc = 'a'.repeat(501)

      expect(() => task.updateDescription(longDesc)).toThrow('Task description too long')
    })
  })

  describe('Update Priority', () => {
    test('updates priority', () => {
      const task = new Task('task-1', 'Fix bug')
      const newPriority = new TaskPriority(TaskPriority.URGENT)

      task.updatePriority(newPriority)

      expect(task.priority).toBe(newPriority)
    })

    test('throws error for invalid priority type', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(() => task.updatePriority('high')).toThrow('Priority must be a TaskPriority instance')
    })
  })

  describe('Estimates and Tracking', () => {
    test('sets estimate', () => {
      const task = new Task('task-1', 'Fix bug')

      task.setEstimate(30)

      expect(task.estimatedMinutes).toBe(30)
    })

    test('throws error for invalid estimate', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(() => task.setEstimate(-10)).toThrow('Estimate must be a non-negative number')
    })

    test('records actual time', () => {
      const task = new Task('task-1', 'Fix bug')

      task.recordActualTime(45)

      expect(task.actualMinutes).toBe(45)
    })

    test('throws error for invalid actual time', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(() => task.recordActualTime('invalid')).toThrow(
        'Actual time must be a non-negative number'
      )
    })

    test('calculates time variance', () => {
      const task = new Task('task-1', 'Fix bug')

      task.setEstimate(30)
      task.recordActualTime(45)

      expect(task.getTimeVariance()).toBe(15)
    })

    test('returns null variance when data unavailable', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(task.getTimeVariance()).toBeNull()

      task.setEstimate(30)
      expect(task.getTimeVariance()).toBeNull()
    })

    test('detects over estimate', () => {
      const task = new Task('task-1', 'Fix bug')

      task.setEstimate(30)
      task.recordActualTime(45)

      expect(task.isOverEstimate()).toBe(true)

      task.recordActualTime(20)
      expect(task.isOverEstimate()).toBe(false)
    })
  })

  describe('Due Dates', () => {
    test('sets due date', () => {
      const task = new Task('task-1', 'Fix bug')
      const dueDate = new Date('2025-12-25')

      task.setDueDate(dueDate)

      expect(task.dueDate).toBe(dueDate)
    })

    test('throws error for invalid due date', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(() => task.setDueDate('2025-12-25')).toThrow('Due date must be a Date instance')
    })

    test('clears due date', () => {
      const task = new Task('task-1', 'Fix bug', {
        dueDate: new Date('2025-12-25')
      })

      task.clearDueDate()

      expect(task.dueDate).toBeNull()
    })

    test('detects overdue tasks', () => {
      const task = new Task('task-1', 'Fix bug')

      // Past date
      task.setDueDate(new Date(Date.now() - 24 * 60 * 60 * 1000))
      expect(task.isOverdue()).toBe(true)

      // Future date
      task.setDueDate(new Date(Date.now() + 24 * 60 * 60 * 1000))
      expect(task.isOverdue()).toBe(false)

      // Completed task is not overdue
      task.setDueDate(new Date(Date.now() - 24 * 60 * 60 * 1000))
      task.complete()
      expect(task.isOverdue()).toBe(false)
    })

    test('detects due soon tasks', () => {
      const task = new Task('task-1', 'Fix bug')

      // Due in 12 hours (within 24)
      task.setDueDate(new Date(Date.now() + 12 * 60 * 60 * 1000))
      expect(task.isDueSoon(24)).toBe(true)

      // Due in 48 hours (outside 24)
      task.setDueDate(new Date(Date.now() + 48 * 60 * 60 * 1000))
      expect(task.isDueSoon(24)).toBe(false)

      // Past due is not due soon
      task.setDueDate(new Date(Date.now() - 1 * 60 * 60 * 1000))
      expect(task.isDueSoon(24)).toBe(false)

      // Completed task is not due soon
      task.setDueDate(new Date(Date.now() + 12 * 60 * 60 * 1000))
      task.complete()
      expect(task.isDueSoon(24)).toBe(false)
    })

    test('respects custom hours for due soon', () => {
      const task = new Task('task-1', 'Fix bug')

      task.setDueDate(new Date(Date.now() + 10 * 60 * 60 * 1000))

      expect(task.isDueSoon(12)).toBe(true)
      expect(task.isDueSoon(8)).toBe(false)
    })
  })

  describe('Tag Management', () => {
    test('adds tag', () => {
      const task = new Task('task-1', 'Fix bug')

      task.addTag('important')

      expect(task.tags).toContain('important')
    })

    test('does not add duplicate tags', () => {
      const task = new Task('task-1', 'Fix bug', { tags: ['bug'] })

      task.addTag('bug')

      expect(task.tags).toEqual(['bug'])
    })

    test('throws error for invalid tag type', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(() => task.addTag(123)).toThrow('Tag must be a string')
    })

    test('removes tag', () => {
      const task = new Task('task-1', 'Fix bug', { tags: ['bug', 'urgent'] })

      task.removeTag('urgent')

      expect(task.tags).toEqual(['bug'])
    })

    test('removing non-existent tag does not error', () => {
      const task = new Task('task-1', 'Fix bug', { tags: ['bug'] })

      expect(() => task.removeTag('nonexistent')).not.toThrow()
      expect(task.tags).toEqual(['bug'])
    })
  })

  describe('Metadata Management', () => {
    test('updates metadata', () => {
      const task = new Task('task-1', 'Fix bug')

      task.updateMetadata({ context: 'session', notes: 'Test failed' })

      expect(task.metadata.context).toBe('session')
      expect(task.metadata.notes).toBe('Test failed')
    })

    test('merges metadata updates', () => {
      const task = new Task('task-1', 'Fix bug', {
        metadata: { context: 'session' }
      })

      task.updateMetadata({ notes: 'Test failed' })

      expect(task.metadata.context).toBe('session')
      expect(task.metadata.notes).toBe('Test failed')
    })
  })

  describe('Summary', () => {
    test('returns task summary', () => {
      const task = new Task('task-1', 'Fix bug', {
        priority: TaskPriority.HIGH,
        projectId: 'project-1',
        tags: ['bug'],
        estimatedMinutes: 30,
        actualMinutes: 45
      })

      const summary = task.getSummary()

      expect(summary).toEqual({
        id: 'task-1',
        description: 'Fix bug',
        priority: TaskPriority.HIGH,
        priorityIcon: '⬆️',
        priorityColor: 'yellow',
        completed: false,
        completedAt: null,
        projectId: 'project-1',
        sessionId: null,
        tags: ['bug'],
        dueDate: null,
        isOverdue: false,
        isDueSoon: false,
        estimatedMinutes: 30,
        actualMinutes: 45,
        timeVariance: 15,
        isOverEstimate: true,
        createdAt: expect.any(Date),
        updatedAt: expect.any(Date)
      })
    })
  })

  describe('Search Matching', () => {
    test('matches by description', () => {
      const task = new Task('task-1', 'Fix bug in Session entity')

      expect(task.matchesSearch('bug')).toBe(true)
      expect(task.matchesSearch('session')).toBe(true)
      expect(task.matchesSearch('PROJECT')).toBe(false)
    })

    test('matches by tags', () => {
      const task = new Task('task-1', 'Fix bug', { tags: ['urgent', 'backend'] })

      expect(task.matchesSearch('urgent')).toBe(true)
      expect(task.matchesSearch('BACKEND')).toBe(true)
    })

    test('matches by priority', () => {
      const task = new Task('task-1', 'Fix bug', { priority: TaskPriority.HIGH })

      expect(task.matchesSearch('high')).toBe(true)
    })

    test('matches by project ID', () => {
      const task = new Task('task-1', 'Fix bug', { projectId: 'rmediation' })

      expect(task.matchesSearch('rmediation')).toBe(true)
    })

    test('matches empty query', () => {
      const task = new Task('task-1', 'Fix bug')

      expect(task.matchesSearch('')).toBe(true)
      expect(task.matchesSearch(null)).toBe(true)
    })

    test('is case insensitive', () => {
      const task = new Task('task-1', 'Fix Bug in Session')

      expect(task.matchesSearch('fix')).toBe(true)
      expect(task.matchesSearch('BUG')).toBe(true)
      expect(task.matchesSearch('SesSiOn')).toBe(true)
    })
  })
})
