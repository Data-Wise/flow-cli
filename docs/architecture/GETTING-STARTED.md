# Getting Started with Flow-CLI Architecture

**Build Your First Feature in 30 Minutes**

---

## 🎯 What You'll Build

A simple **Task Management** feature following Clean Architecture:

- Task entity (domain)
- CreateTask use case (application logic)
- Task repository (data access)
- CLI command (interface)

By the end, you'll understand:

- ✅ Where different code goes (4-layer architecture)
- ✅ How to write testable business logic
- ✅ How to swap implementations easily
- ✅ How Clean Architecture works in practice

---

## 📋 Prerequisites

```bash
# You have:
- Node.js 18+ installed
- Basic JavaScript/ES6 knowledge
- Text editor or IDE
- 30-45 minutes

# Nice to have (but not required):
- Familiarity with async/await
- Basic testing knowledge (Jest)
```

---

## 🚀 Step 1: Create Domain Entity (5 min)

### What is an Entity?

An entity has:

- **Identity** (unique ID)
- **Behavior** (methods that enforce business rules)
- **State** (properties that can change over time)

### Create Task Entity

```bash
# Create file
mkdir -p cli/domain/entities
touch cli/domain/entities/Task.js
```

```javascript
// cli/domain/entities/Task.js

export class Task {
  constructor(id, description, options = {}) {
    this.id = id
    this.description = description
    this.completed = options.completed || false
    this.priority = options.priority || 'medium'
    this.createdAt = options.createdAt || new Date()
    this.completedAt = null

    // Validate on creation
    this.validate()
  }

  /**
   * Business Rule: Description must be non-empty
   */
  validate() {
    if (!this.description || this.description.trim() === '') {
      throw new Error('Task description cannot be empty')
    }

    if (this.description.length > 500) {
      throw new Error('Task description too long (max 500 chars)')
    }
  }

  /**
   * Business Rule: Can only complete pending tasks
   */
  complete() {
    if (this.completed) {
      throw new Error('Task is already completed')
    }

    this.completed = true
    this.completedAt = new Date()
  }

  /**
   * Business Rule: Can reopen completed tasks
   */
  reopen() {
    if (!this.completed) {
      throw new Error('Task is not completed')
    }

    this.completed = false
    this.completedAt = null
  }

  /**
   * Query: Is this task overdue?
   */
  isOverdue(dueDate) {
    if (!dueDate) return false
    return !this.completed && new Date() > new Date(dueDate)
  }
}
```

### ✅ Checkpoint

Test your entity (run in Node REPL):

```javascript
import { Task } from './cli/domain/entities/Task.js'

// Valid task
const task = new Task('task-1', 'Write documentation')
console.log(task.id) // 'task-1'

// Complete it
task.complete()
console.log(task.completed) // true

// Try to complete again (should throw)
try {
  task.complete()
} catch (error) {
  console.log(error.message) // 'Task is already completed'
}
```

**✨ What you learned:**

- Entities contain business logic
- Validation happens in domain layer
- Methods enforce business rules (can't complete twice)
- No external dependencies (pure JavaScript)

---

## 🚀 Step 2: Define Repository Interface (5 min)

### What is a Repository?

A repository is an **interface** (contract) that defines:

- How to save/load entities
- **Not** how it's implemented (file? database? memory?)

### Create ITaskRepository

```bash
mkdir -p cli/domain/repositories
touch cli/domain/repositories/ITaskRepository.js
```

```javascript
// cli/domain/repositories/ITaskRepository.js

/**
 * Port: Task repository interface
 * Implementations will be in adapters layer
 */
export class ITaskRepository {
  /**
   * Save a task
   * @param {Task} task
   * @returns {Promise<Task>}
   */
  async save(task) {
    throw new Error('save() not implemented')
  }

  /**
   * Find task by ID
   * @param {string} id
   * @returns {Promise<Task|null>}
   */
  async findById(id) {
    throw new Error('findById() not implemented')
  }

  /**
   * List all tasks
   * @param {Object} filters - Optional filters
   * @returns {Promise<Task[]>}
   */
  async list(filters = {}) {
    throw new Error('list() not implemented')
  }

  /**
   * Delete task
   * @param {string} id
   * @returns {Promise<boolean>}
   */
  async delete(id) {
    throw new Error('delete() not implemented')
  }
}
```

**✨ What you learned:**

- Repositories are **interfaces** (just method signatures)
- Defined in domain layer (what we need)
- Implemented in adapters layer (how we get it)
- This is **Dependency Inversion** - domain doesn't know about files/DB

---

## 🚀 Step 3: Create Use Case (10 min)

### What is a Use Case?

A use case orchestrates:

- Domain entities
- Repositories
- Business workflows

### Create CreateTaskUseCase

```bash
mkdir -p cli/use-cases
touch cli/use-cases/CreateTaskUseCase.js
```

```javascript
// cli/use-cases/CreateTaskUseCase.js

import { Task } from '../domain/entities/Task.js'

export class CreateTaskUseCase {
  constructor(taskRepository) {
    this.taskRepository = taskRepository
  }

  /**
   * Execute: Create a new task
   * @param {Object} request
   * @param {string} request.description
   * @param {string} request.priority
   * @returns {Promise<Task>}
   */
  async execute(request) {
    const { description, priority = 'medium' } = request

    // Generate unique ID
    const id = this.generateId()

    // Create domain entity (validation happens here)
    const task = new Task(id, description, { priority })

    // Persist via repository
    await this.taskRepository.save(task)

    return task
  }

  generateId() {
    return `task-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }
}
```

**✨ What you learned:**

- Use cases contain **application logic** (workflow)
- Use cases use domain entities (Task)
- Use cases depend on repository **interface** (not implementation)
- Easy to test (just inject a mock repository)

---

## 🚀 Step 4: Implement Repository (10 min)

### In-Memory Implementation (for testing)

```bash
mkdir -p cli/adapters/repositories
touch cli/adapters/repositories/InMemoryTaskRepository.js
```

```javascript
// cli/adapters/repositories/InMemoryTaskRepository.js

import { ITaskRepository } from '../../domain/repositories/ITaskRepository.js'

/**
 * Adapter: In-memory implementation (for testing)
 */
export class InMemoryTaskRepository extends ITaskRepository {
  constructor() {
    super()
    this.tasks = []
  }

  async save(task) {
    // Check if exists
    const index = this.tasks.findIndex(t => t.id === task.id)

    if (index >= 0) {
      // Update existing
      this.tasks[index] = task
    } else {
      // Add new
      this.tasks.push(task)
    }

    return task
  }

  async findById(id) {
    return this.tasks.find(t => t.id === id) || null
  }

  async list(filters = {}) {
    let results = [...this.tasks]

    if (filters.completed !== undefined) {
      results = results.filter(t => t.completed === filters.completed)
    }

    if (filters.priority) {
      results = results.filter(t => t.priority === filters.priority)
    }

    return results
  }

  async delete(id) {
    const index = this.tasks.findIndex(t => t.id === id)

    if (index >= 0) {
      this.tasks.splice(index, 1)
      return true
    }

    return false
  }

  // Test helper
  clear() {
    this.tasks = []
  }
}
```

**✨ What you learned:**

- Adapters **implement** interfaces from domain
- In-memory implementation is perfect for testing
- Same interface, different implementation (flexibility!)

---

## 🚀 Step 5: Wire It Together (5 min)

### Dependency Injection

```bash
touch cli/container.js
```

```javascript
// cli/container.js

import { CreateTaskUseCase } from './use-cases/CreateTaskUseCase.js'
import { InMemoryTaskRepository } from './adapters/repositories/InMemoryTaskRepository.js'

/**
 * Dependency Injection Container
 * Wire up dependencies here
 */
export function createContainer() {
  // Create repository (could swap with FileSystemTaskRepository later)
  const taskRepository = new InMemoryTaskRepository()

  // Create use cases
  const createTask = new CreateTaskUseCase(taskRepository)

  return {
    taskRepository,
    useCases: {
      createTask
    }
  }
}
```

**✨ What you learned:**

- Dependencies are wired at application startup
- Easy to swap implementations (change ONE line)
- Use cases don't know what repository implementation they're using

---

## 🚀 Step 6: Test It! (5 min)

```bash
touch cli/test.js
```

```javascript
// cli/test.js

import { createContainer } from './container.js'

async function test() {
  const container = createContainer()
  const { createTask } = container.useCases

  // Create a task
  const task = await createTask.execute({
    description: 'Write tests',
    priority: 'high'
  })

  console.log('✅ Created task:', task.id)
  console.log('   Description:', task.description)
  console.log('   Priority:', task.priority)
  console.log('   Completed:', task.completed)

  // Complete it
  task.complete()
  console.log('✅ Completed task at:', task.completedAt)

  // Save updated task
  await container.taskRepository.save(task)

  // List all tasks
  const all = await container.taskRepository.list()
  console.log('✅ Total tasks:', all.length)

  // List completed tasks
  const completed = await container.taskRepository.list({ completed: true })
  console.log('✅ Completed tasks:', completed.length)
}

test().catch(console.error)
```

```bash
# Run it
node cli/test.js
```

**Output:**

```
✅ Created task: task-1703...
   Description: Write tests
   Priority: high
   Completed: false
✅ Completed task at: 2025-12-23T...
✅ Total tasks: 1
✅ Completed tasks: 1
```

---

## 🎉 You Did It!

You just built a feature using Clean Architecture!

### What You Accomplished

✅ **Domain Layer**: Task entity with business rules
✅ **Repository Interface**: ITaskRepository (port)
✅ **Use Case**: CreateTaskUseCase (application logic)
✅ **Adapter**: InMemoryTaskRepository (implementation)
✅ **Dependency Injection**: Wired everything together
✅ **Tested**: It works!

### Key Takeaways

| Layer          | What It Does                | Example                                                     |
| -------------- | --------------------------- | ----------------------------------------------------------- |
| **Domain**     | Business rules (pure logic) | Task.complete() throws if already completed                 |
| **Use Cases**  | Orchestrate workflows       | CreateTaskUseCase coordinates entity creation + persistence |
| **Adapters**   | Implement interfaces        | InMemoryTaskRepository implements ITaskRepository           |
| **Frameworks** | External tools              | (Not used in this example)                                  |

---

## 🚀 Next Steps

### Add More Features (Practice!)

**Easy (15 min each):**

1. Add `CompleteTaskUseCase`
2. Add `ListTasksUseCase`
3. Add `DeleteTaskUseCase`

**Medium (30 min each):** 4. Add `FileSystemTaskRepository` (persist to JSON file) 5. Add task priorities (high/medium/low) as Value Object 6. Add task tags

**Advanced (1 hour each):** 7. Add CLI command (adapter controller) 8. Add task due dates with reminders 9. Add task dependencies (can't complete B until A is done)

### Explore the Codebase

Now that you understand the pattern, explore:

```bash
# See real examples
cli/domain/entities/Session.js
cli/use-cases/CreateSessionUseCase.js
cli/adapters/repositories/FileSystemSessionRepository.js
```

### Read More Documentation

- [CODE-EXAMPLES.md](./CODE-EXAMPLES.md) - More patterns and examples
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Architecture cheat sheet
- [PATTERN-COOKBOOK.md](./PATTERN-COOKBOOK.md) - Decision trees

---

## 🐛 Troubleshooting

### "throw new Error('save() not implemented')"

**Problem:** Using ITaskRepository directly instead of implementation

**Fix:**

```javascript
// ❌ Wrong
const repo = new ITaskRepository()

// ✅ Right
const repo = new InMemoryTaskRepository()
```

### "Task description cannot be empty"

**Problem:** Validation in Task constructor

**Fix:** This is GOOD! Your business rules are working. Provide a valid description:

```javascript
new Task('id', '') // ❌ Throws
new Task('id', 'Valid description') // ✅ Works
```

---

## 💡 Key Concepts Recap

### Dependency Inversion

```javascript
// Domain defines WHAT it needs (interface)
class ITaskRepository {
  async save(task) {}
}

// Adapters provide HOW (implementation)
class InMemoryTaskRepository extends ITaskRepository {
  async save(task) {
    this.tasks.push(task)
  }
}

// Use case doesn't care which implementation
new CreateTaskUseCase(new InMemoryTaskRepository()) // In-memory
new CreateTaskUseCase(new FileSystemTaskRepository()) // File system
new CreateTaskUseCase(new DatabaseTaskRepository()) // Database
```

### Testability

```javascript
// Easy to test - inject mock
const mockRepo = {
  save: async task => task // Mock implementation
}

const useCase = new CreateTaskUseCase(mockRepo)

// Test without file I/O or database
const result = await useCase.execute({ description: 'Test' })
expect(result.description).toBe('Test')
```

---

**Congratulations!** You now understand Clean Architecture. Keep practicing!

---

**Last Updated:** 2025-12-23
**Part of:** Architecture Enhancement Plan (A→C Implementation)
**Time to Complete:** 30-45 minutes
