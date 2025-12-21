# Architecture Code Examples

**Purpose:** Copy-paste-ready code snippets for implementing Clean Architecture patterns
**Audience:** Developers implementing new features in the zsh-configuration system
**Date:** 2025-12-21

---

## Quick Navigation

- [Domain Layer](#domain-layer) - Entities, Value Objects, Repositories
- [Use Cases Layer](#use-cases-layer) - Application logic
- [Adapters Layer](#adapters-layer) - Controllers, Gateways, Presenters
- [Dependency Injection](#dependency-injection) - Wiring it all together
- [Testing Patterns](#testing-patterns) - Unit and integration tests

---

## Domain Layer

### Creating a New Entity

**When:** You need an object with identity that encapsulates business rules

**Example:** Task entity with validation and state management

```javascript
// cli/domain/entities/Task.js

import { TaskPriority } from '../value-objects/TaskPriority.js';
import { TaskStatus } from '../value-objects/TaskStatus.js';

export class Task {
  constructor(id, description, options = {}) {
    // Required properties
    this.id = id;
    this.description = description;

    // Optional properties with defaults
    this.priority = options.priority || TaskPriority.MEDIUM;
    this.status = options.status || TaskStatus.PENDING;
    this.project = options.project || null;
    this.tags = options.tags || [];
    this.createdAt = new Date();
    this.completedAt = null;

    // Validate on creation
    this.validate();
  }

  /**
   * Business rule: Description must be meaningful
   */
  validate() {
    if (!this.description || this.description.trim().length < 3) {
      throw new Error('Task description must be at least 3 characters');
    }

    if (this.description.length > 200) {
      throw new Error('Task description too long (max 200 chars)');
    }
  }

  /**
   * Business rule: Can only complete pending or in-progress tasks
   */
  complete() {
    if (this.status === TaskStatus.COMPLETED) {
      throw new Error('Task already completed');
    }

    if (this.status === TaskStatus.CANCELLED) {
      throw new Error('Cannot complete cancelled task');
    }

    this.status = TaskStatus.COMPLETED;
    this.completedAt = new Date();
  }

  /**
   * Business rule: Can only cancel pending or in-progress tasks
   */
  cancel(reason) {
    if (this.status === TaskStatus.COMPLETED) {
      throw new Error('Cannot cancel completed task');
    }

    if (this.status === TaskStatus.CANCELLED) {
      throw new Error('Task already cancelled');
    }

    this.status = TaskStatus.CANCELLED;
    this.cancellationReason = reason;
  }

  /**
   * Business rule: High priority tasks are urgent
   */
  isUrgent() {
    return this.priority === TaskPriority.HIGH;
  }

  /**
   * Business rule: Quick win = high priority + simple
   */
  isQuickWin() {
    return this.tags.includes('quick-win') ||
           (this.priority === TaskPriority.HIGH && this.estimatedMinutes <= 30);
  }

  /**
   * Update tags (maintains immutability)
   */
  addTag(tag) {
    if (!this.tags.includes(tag)) {
      this.tags = [...this.tags, tag];
    }
  }

  removeTag(tag) {
    this.tags = this.tags.filter(t => t !== tag);
  }
}
```

### Creating a Value Object

**When:** You need immutable data with no identity (two objects with same value are identical)

**Example:** Task priority with validation

```javascript
// cli/domain/value-objects/TaskPriority.js

export class TaskPriority {
  static HIGH = 'high';
  static MEDIUM = 'medium';
  static LOW = 'low';

  static ALL = [
    TaskPriority.HIGH,
    TaskPriority.MEDIUM,
    TaskPriority.LOW
  ];

  constructor(value) {
    if (!TaskPriority.ALL.includes(value)) {
      throw new Error(`Invalid priority: ${value}. Must be one of: ${TaskPriority.ALL.join(', ')}`);
    }

    // Make immutable
    Object.defineProperty(this, 'value', {
      value,
      writable: false,
      enumerable: true,
      configurable: false
    });
  }

  /**
   * Value objects are compared by value, not reference
   */
  equals(other) {
    return other instanceof TaskPriority && other.value === this.value;
  }

  /**
   * Helper: Check if high priority
   */
  isHigh() {
    return this.value === TaskPriority.HIGH;
  }

  /**
   * Helper: Check if low priority
   */
  isLow() {
    return this.value === TaskPriority.LOW;
  }

  /**
   * String representation
   */
  toString() {
    return this.value;
  }

  /**
   * Emoji representation
   */
  toEmoji() {
    const emojiMap = {
      [TaskPriority.HIGH]: '🔴',
      [TaskPriority.MEDIUM]: '🟡',
      [TaskPriority.LOW]: '🟢'
    };
    return emojiMap[this.value];
  }
}
```

### Creating a Repository Interface (Port)

**When:** Domain needs persistence but shouldn't know HOW it's stored

**Example:** Task repository interface

```javascript
// cli/domain/repositories/ITaskRepository.js

/**
 * Port: Interface that domain defines, adapters implement
 * Domain knows WHAT it needs, not HOW it's stored
 */
export class ITaskRepository {
  /**
   * Save or update a task
   * @param {Task} task
   * @returns {Promise<Task>}
   */
  async save(task) {
    throw new Error('ITaskRepository.save() must be implemented');
  }

  /**
   * Find task by ID
   * @param {string} taskId
   * @returns {Promise<Task|null>}
   */
  async findById(taskId) {
    throw new Error('ITaskRepository.findById() must be implemented');
  }

  /**
   * Find all tasks for a project
   * @param {string} projectName
   * @returns {Promise<Task[]>}
   */
  async findByProject(projectName) {
    throw new Error('ITaskRepository.findByProject() must be implemented');
  }

  /**
   * Find tasks matching criteria
   * @param {Object} filters
   * @param {string} filters.status - Filter by status
   * @param {string} filters.priority - Filter by priority
   * @param {string[]} filters.tags - Filter by tags (any match)
   * @returns {Promise<Task[]>}
   */
  async find(filters) {
    throw new Error('ITaskRepository.find() must be implemented');
  }

  /**
   * Delete a task
   * @param {string} taskId
   * @returns {Promise<boolean>}
   */
  async delete(taskId) {
    throw new Error('ITaskRepository.delete() must be implemented');
  }

  /**
   * Get all tasks
   * @returns {Promise<Task[]>}
   */
  async all() {
    throw new Error('ITaskRepository.all() must be implemented');
  }
}
```

---

## Use Cases Layer

### Creating a Use Case

**When:** You need to orchestrate domain objects to accomplish a task

**Example:** Create task use case with validation

```javascript
// cli/use-cases/CreateTaskUseCase.js

import { Task } from '../domain/entities/Task.js';
import { TaskPriority } from '../domain/value-objects/TaskPriority.js';

export class CreateTaskUseCase {
  constructor(taskRepository, projectRepository) {
    this.taskRepository = taskRepository;
    this.projectRepository = projectRepository;
  }

  /**
   * Execute the use case
   * @param {Object} request
   * @param {string} request.description - Task description
   * @param {string} request.priority - Priority level
   * @param {string} request.project - Project name (optional)
   * @param {string[]} request.tags - Tags (optional)
   * @returns {Promise<CreateTaskResult>}
   */
  async execute(request) {
    // Input validation (application-level)
    this.validateRequest(request);

    // Verify project exists if specified
    if (request.project) {
      const project = await this.projectRepository.findByName(request.project);
      if (!project) {
        return {
          success: false,
          error: `Project not found: ${request.project}`
        };
      }
    }

    // Create domain entity
    const priority = new TaskPriority(request.priority || TaskPriority.MEDIUM);
    const task = new Task(
      this.generateId(),
      request.description,
      {
        priority,
        project: request.project,
        tags: request.tags || []
      }
    );

    // Persist
    const savedTask = await this.taskRepository.save(task);

    return {
      success: true,
      task: savedTask
    };
  }

  validateRequest(request) {
    if (!request.description) {
      throw new Error('Description is required');
    }

    if (request.priority && !TaskPriority.ALL.includes(request.priority)) {
      throw new Error(`Invalid priority: ${request.priority}`);
    }
  }

  generateId() {
    return `task-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

### Creating a Query Use Case

**When:** You need to fetch and present data (read-only operations)

**Example:** List tasks with filtering

```javascript
// cli/use-cases/ListTasksUseCase.js

export class ListTasksUseCase {
  constructor(taskRepository, projectRepository) {
    this.taskRepository = taskRepository;
    this.projectRepository = projectRepository;
  }

  /**
   * List tasks with optional filtering
   * @param {Object} query
   * @param {string} query.project - Filter by project
   * @param {string} query.status - Filter by status
   * @param {string} query.priority - Filter by priority
   * @param {boolean} query.quickWinsOnly - Show only quick wins
   * @returns {Promise<ListTasksResult>}
   */
  async execute(query = {}) {
    // Validate project if specified
    if (query.project) {
      const project = await this.projectRepository.findByName(query.project);
      if (!project) {
        return {
          success: false,
          error: `Project not found: ${query.project}`
        };
      }
    }

    // Build filters
    const filters = {};
    if (query.status) filters.status = query.status;
    if (query.priority) filters.priority = query.priority;
    if (query.project) filters.project = query.project;

    // Fetch tasks
    let tasks = await this.taskRepository.find(filters);

    // Additional business logic filtering
    if (query.quickWinsOnly) {
      tasks = tasks.filter(task => task.isQuickWin());
    }

    // Sort by priority (high to low) then by created date
    tasks.sort((a, b) => {
      if (a.priority.isHigh() && !b.priority.isHigh()) return -1;
      if (!a.priority.isHigh() && b.priority.isHigh()) return 1;
      return b.createdAt - a.createdAt;
    });

    // Create summary
    const summary = {
      total: tasks.length,
      byPriority: {
        high: tasks.filter(t => t.priority.isHigh()).length,
        medium: tasks.filter(t => t.priority.value === 'medium').length,
        low: tasks.filter(t => t.priority.isLow()).length
      },
      quickWins: tasks.filter(t => t.isQuickWin()).length
    };

    return {
      success: true,
      tasks,
      summary
    };
  }
}
```

---

## Adapters Layer

### Creating a Repository Adapter

**When:** You need to implement a repository interface for a specific storage mechanism

**Example:** File system task repository

```javascript
// cli/adapters/repositories/FileSystemTaskRepository.js

import { ITaskRepository } from '../../domain/repositories/ITaskRepository.js';
import { Task } from '../../domain/entities/Task.js';
import { TaskPriority } from '../../domain/value-objects/TaskPriority.js';
import { TaskStatus } from '../../domain/value-objects/TaskStatus.js';
import { readFile, writeFile, readdir, unlink } from 'fs/promises';
import { join } from 'path';

/**
 * Adapter: File system implementation of task repository
 */
export class FileSystemTaskRepository extends ITaskRepository {
  constructor(storageDir) {
    super();
    this.storageDir = storageDir;
  }

  async save(task) {
    const filePath = join(this.storageDir, `${task.id}.json`);
    const data = this.toJSON(task);
    await writeFile(filePath, JSON.stringify(data, null, 2));
    return task;
  }

  async findById(taskId) {
    try {
      const filePath = join(this.storageDir, `${taskId}.json`);
      const content = await readFile(filePath, 'utf-8');
      return this.toEntity(JSON.parse(content));
    } catch (error) {
      if (error.code === 'ENOENT') return null;
      throw error;
    }
  }

  async findByProject(projectName) {
    const all = await this.all();
    return all.filter(task => task.project === projectName);
  }

  async find(filters) {
    const all = await this.all();
    return all.filter(task => this.matchesFilters(task, filters));
  }

  async delete(taskId) {
    try {
      const filePath = join(this.storageDir, `${taskId}.json`);
      await unlink(filePath);
      return true;
    } catch (error) {
      if (error.code === 'ENOENT') return false;
      throw error;
    }
  }

  async all() {
    const files = await readdir(this.storageDir);
    const tasks = [];

    for (const file of files) {
      if (!file.endsWith('.json')) continue;

      const taskId = file.replace('.json', '');
      const task = await this.findById(taskId);
      if (task) tasks.push(task);
    }

    return tasks;
  }

  /**
   * Map domain entity to JSON (persistence format)
   */
  toJSON(task) {
    return {
      id: task.id,
      description: task.description,
      priority: task.priority.value,
      status: task.status.value,
      project: task.project,
      tags: task.tags,
      createdAt: task.createdAt.toISOString(),
      completedAt: task.completedAt?.toISOString() || null,
      cancellationReason: task.cancellationReason || null,
      estimatedMinutes: task.estimatedMinutes || null
    };
  }

  /**
   * Map JSON to domain entity (reconstruction)
   */
  toEntity(json) {
    const priority = new TaskPriority(json.priority);
    const status = new TaskStatus(json.status);

    const task = new Task(json.id, json.description, {
      priority,
      status,
      project: json.project,
      tags: json.tags || []
    });

    task.createdAt = new Date(json.createdAt);
    task.completedAt = json.completedAt ? new Date(json.completedAt) : null;
    task.cancellationReason = json.cancellationReason;
    task.estimatedMinutes = json.estimatedMinutes;

    return task;
  }

  /**
   * Check if task matches filter criteria
   */
  matchesFilters(task, filters) {
    if (filters.status && task.status.value !== filters.status) {
      return false;
    }

    if (filters.priority && task.priority.value !== filters.priority) {
      return false;
    }

    if (filters.project && task.project !== filters.project) {
      return false;
    }

    if (filters.tags && filters.tags.length > 0) {
      const hasTag = filters.tags.some(tag => task.tags.includes(tag));
      if (!hasTag) return false;
    }

    return true;
  }
}
```

### Creating an In-Memory Repository (for Testing)

**When:** You need fast, isolated tests without touching the file system

**Example:** In-memory task repository

```javascript
// cli/adapters/repositories/InMemoryTaskRepository.js

import { ITaskRepository } from '../../domain/repositories/ITaskRepository.js';

/**
 * Adapter: In-memory implementation for testing
 */
export class InMemoryTaskRepository extends ITaskRepository {
  constructor() {
    super();
    this.tasks = new Map();
  }

  async save(task) {
    // Clone to prevent external mutation
    this.tasks.set(task.id, this.clone(task));
    return task;
  }

  async findById(taskId) {
    const task = this.tasks.get(taskId);
    return task ? this.clone(task) : null;
  }

  async findByProject(projectName) {
    const tasks = Array.from(this.tasks.values());
    return tasks.filter(task => task.project === projectName)
                .map(task => this.clone(task));
  }

  async find(filters) {
    const tasks = Array.from(this.tasks.values());
    return tasks.filter(task => this.matchesFilters(task, filters))
                .map(task => this.clone(task));
  }

  async delete(taskId) {
    return this.tasks.delete(taskId);
  }

  async all() {
    return Array.from(this.tasks.values()).map(task => this.clone(task));
  }

  /**
   * Test helper: Clear all data
   */
  clear() {
    this.tasks.clear();
  }

  /**
   * Test helper: Get count
   */
  count() {
    return this.tasks.size;
  }

  /**
   * Deep clone to prevent mutation
   */
  clone(task) {
    return Object.assign(
      Object.create(Object.getPrototypeOf(task)),
      JSON.parse(JSON.stringify(task))
    );
  }

  matchesFilters(task, filters) {
    if (filters.status && task.status.value !== filters.status) {
      return false;
    }
    if (filters.priority && task.priority.value !== filters.priority) {
      return false;
    }
    if (filters.project && task.project !== filters.project) {
      return false;
    }
    return true;
  }
}
```

### Creating a Controller

**When:** You need to handle user input and delegate to use cases

**Example:** CLI controller for tasks

```javascript
// cli/adapters/controllers/TaskController.js

import { CreateTaskUseCase } from '../../use-cases/CreateTaskUseCase.js';
import { ListTasksUseCase } from '../../use-cases/ListTasksUseCase.js';
import { CompleteTaskUseCase } from '../../use-cases/CompleteTaskUseCase.js';

/**
 * Controller: Handles CLI concerns, delegates to use cases
 */
export class TaskController {
  constructor(
    createTaskUseCase,
    listTasksUseCase,
    completeTaskUseCase,
    presenter
  ) {
    this.createTask = createTaskUseCase;
    this.listTasks = listTasksUseCase;
    this.completeTask = completeTaskUseCase;
    this.presenter = presenter;
  }

  /**
   * Handle: add task command
   */
  async handleAdd(argv) {
    try {
      // Parse CLI arguments
      const request = {
        description: argv.description || argv._[0],
        priority: argv.priority || argv.p,
        project: argv.project,
        tags: argv.tags ? argv.tags.split(',') : []
      };

      // Execute use case
      const result = await this.createTask.execute(request);

      // Present result
      if (result.success) {
        this.presenter.showSuccess(`Created task: ${result.task.description}`);
        this.presenter.showTask(result.task);
      } else {
        this.presenter.showError(result.error);
        process.exit(1);
      }
    } catch (error) {
      this.presenter.showError(`Failed to create task: ${error.message}`);
      process.exit(1);
    }
  }

  /**
   * Handle: list tasks command
   */
  async handleList(argv) {
    try {
      // Parse CLI arguments
      const query = {
        project: argv.project || argv.p,
        status: argv.status || argv.s,
        priority: argv.priority,
        quickWinsOnly: argv['quick-wins'] || argv.q
      };

      // Execute use case
      const result = await this.listTasks.execute(query);

      // Present result
      if (result.success) {
        this.presenter.showTaskList(result.tasks, result.summary);
      } else {
        this.presenter.showError(result.error);
        process.exit(1);
      }
    } catch (error) {
      this.presenter.showError(`Failed to list tasks: ${error.message}`);
      process.exit(1);
    }
  }

  /**
   * Handle: complete task command
   */
  async handleComplete(argv) {
    try {
      const taskId = argv._[0];
      if (!taskId) {
        this.presenter.showError('Task ID required');
        process.exit(1);
      }

      // Execute use case
      const result = await this.completeTask.execute({ taskId });

      // Present result
      if (result.success) {
        this.presenter.showSuccess(`Completed task: ${result.task.description}`);
      } else {
        this.presenter.showError(result.error);
        process.exit(1);
      }
    } catch (error) {
      this.presenter.showError(`Failed to complete task: ${error.message}`);
      process.exit(1);
    }
  }
}
```

### Creating a Presenter

**When:** You need to format output for a specific interface (terminal, JSON, HTML)

**Example:** Terminal presenter with colors

```javascript
// cli/adapters/presenters/TerminalTaskPresenter.js

import chalk from 'chalk';

/**
 * Presenter: Format task data for terminal display
 */
export class TerminalTaskPresenter {
  showSuccess(message) {
    console.log(chalk.green('✓'), message);
  }

  showError(message) {
    console.error(chalk.red('✗'), message);
  }

  showWarning(message) {
    console.warn(chalk.yellow('⚠'), message);
  }

  showTask(task) {
    console.log('');
    console.log(chalk.bold('Task Details:'));
    console.log(`  ID:          ${task.id}`);
    console.log(`  Description: ${task.description}`);
    console.log(`  Priority:    ${task.priority.toEmoji()} ${task.priority.value}`);
    console.log(`  Status:      ${this.formatStatus(task.status)}`);
    if (task.project) {
      console.log(`  Project:     ${task.project}`);
    }
    if (task.tags.length > 0) {
      console.log(`  Tags:        ${task.tags.join(', ')}`);
    }
    console.log(`  Created:     ${this.formatDate(task.createdAt)}`);
    if (task.isQuickWin()) {
      console.log(chalk.yellow('  ⚡ Quick Win'));
    }
    console.log('');
  }

  showTaskList(tasks, summary) {
    if (tasks.length === 0) {
      console.log(chalk.gray('No tasks found'));
      return;
    }

    // Summary header
    console.log('');
    console.log(chalk.bold(`Tasks (${summary.total} total)`));
    console.log(chalk.gray(`  ${summary.byPriority.high} high | ${summary.byPriority.medium} medium | ${summary.byPriority.low} low`));
    if (summary.quickWins > 0) {
      console.log(chalk.yellow(`  ⚡ ${summary.quickWins} quick wins available`));
    }
    console.log('');

    // Task list
    tasks.forEach((task, index) => {
      const prefix = task.priority.toEmoji();
      const description = task.isQuickWin()
        ? chalk.yellow(task.description)
        : task.description;
      const project = task.project
        ? chalk.gray(`(${task.project})`)
        : '';

      console.log(`  ${prefix} ${description} ${project}`);
    });
    console.log('');
  }

  formatStatus(status) {
    const colors = {
      pending: chalk.yellow,
      'in-progress': chalk.blue,
      completed: chalk.green,
      cancelled: chalk.red
    };
    const color = colors[status.value] || chalk.white;
    return color(status.value);
  }

  formatDate(date) {
    return date.toLocaleString();
  }
}
```

---

## Dependency Injection

### Wiring Everything Together

**When:** Application startup - create all objects and wire dependencies

**Example:** Dependency injection container

```javascript
// cli/frameworks/di-container.js

import { CreateTaskUseCase } from '../use-cases/CreateTaskUseCase.js';
import { ListTasksUseCase } from '../use-cases/ListTasksUseCase.js';
import { CompleteTaskUseCase } from '../use-cases/CompleteTaskUseCase.js';

import { FileSystemTaskRepository } from '../adapters/repositories/FileSystemTaskRepository.js';
import { FileSystemProjectRepository } from '../adapters/repositories/FileSystemProjectRepository.js';

import { TaskController } from '../adapters/controllers/TaskController.js';
import { TerminalTaskPresenter } from '../adapters/presenters/TerminalTaskPresenter.js';

import { homedir } from 'os';
import { join } from 'path';

/**
 * Dependency Injection Container
 * Creates and wires all dependencies at application startup
 */
export class DIContainer {
  constructor() {
    this.instances = new Map();
    this.configure();
  }

  configure() {
    // Configuration
    const storageDir = join(homedir(), '.zsh-workflow', 'tasks');
    const projectsDir = join(homedir(), '.zsh-workflow', 'projects');

    // Layer 1: Repositories (Adapters)
    this.instances.set('taskRepository',
      new FileSystemTaskRepository(storageDir)
    );
    this.instances.set('projectRepository',
      new FileSystemProjectRepository(projectsDir)
    );

    // Layer 2: Use Cases
    this.instances.set('createTaskUseCase',
      new CreateTaskUseCase(
        this.get('taskRepository'),
        this.get('projectRepository')
      )
    );

    this.instances.set('listTasksUseCase',
      new ListTasksUseCase(
        this.get('taskRepository'),
        this.get('projectRepository')
      )
    );

    this.instances.set('completeTaskUseCase',
      new CompleteTaskUseCase(
        this.get('taskRepository')
      )
    );

    // Layer 3: Presenters
    this.instances.set('terminalPresenter',
      new TerminalTaskPresenter()
    );

    // Layer 3: Controllers
    this.instances.set('taskController',
      new TaskController(
        this.get('createTaskUseCase'),
        this.get('listTasksUseCase'),
        this.get('completeTaskUseCase'),
        this.get('terminalPresenter')
      )
    );
  }

  get(name) {
    if (!this.instances.has(name)) {
      throw new Error(`Dependency not found: ${name}`);
    }
    return this.instances.get(name);
  }

  /**
   * Get controller for CLI
   */
  getTaskController() {
    return this.get('taskController');
  }
}
```

### Application Entry Point

**Example:** CLI entry point using DI container

```javascript
// cli/frameworks/cli/task-cli.js

import yargs from 'yargs';
import { DIContainer } from '../di-container.js';

/**
 * CLI Application Entry Point
 */
async function main() {
  // Create DI container
  const container = new DIContainer();
  const controller = container.getTaskController();

  // Parse CLI arguments
  const argv = yargs(process.argv.slice(2))
    .command('add <description>', 'Add a new task', (yargs) => {
      yargs
        .positional('description', {
          describe: 'Task description',
          type: 'string'
        })
        .option('priority', {
          alias: 'p',
          type: 'string',
          choices: ['high', 'medium', 'low'],
          default: 'medium'
        })
        .option('project', {
          type: 'string',
          describe: 'Project name'
        })
        .option('tags', {
          type: 'string',
          describe: 'Comma-separated tags'
        });
    }, (argv) => controller.handleAdd(argv))

    .command('list', 'List tasks', (yargs) => {
      yargs
        .option('project', {
          alias: 'p',
          type: 'string',
          describe: 'Filter by project'
        })
        .option('status', {
          alias: 's',
          type: 'string',
          choices: ['pending', 'in-progress', 'completed', 'cancelled']
        })
        .option('quick-wins', {
          alias: 'q',
          type: 'boolean',
          describe: 'Show only quick wins'
        });
    }, (argv) => controller.handleList(argv))

    .command('complete <taskId>', 'Complete a task', (yargs) => {
      yargs.positional('taskId', {
        describe: 'Task ID',
        type: 'string'
      });
    }, (argv) => controller.handleComplete(argv))

    .demandCommand(1, 'You must specify a command')
    .help()
    .argv;
}

main().catch(error => {
  console.error('Fatal error:', error.message);
  process.exit(1);
});
```

---

## Testing Patterns

### Unit Testing Domain Entities

**Pattern:** Test business rules in isolation (no dependencies)

```javascript
// test/unit/entities/Task.test.js

import { Task } from '../../../domain/entities/Task.js';
import { TaskPriority } from '../../../domain/value-objects/TaskPriority.js';
import { TaskStatus } from '../../../domain/value-objects/TaskStatus.js';

describe('Task Entity', () => {
  describe('creation', () => {
    test('creates task with required fields', () => {
      const task = new Task('task-1', 'Fix the bug');

      expect(task.id).toBe('task-1');
      expect(task.description).toBe('Fix the bug');
      expect(task.status.value).toBe(TaskStatus.PENDING);
      expect(task.priority.value).toBe(TaskPriority.MEDIUM);
    });

    test('throws on invalid description', () => {
      expect(() => new Task('task-1', '')).toThrow('at least 3 characters');
      expect(() => new Task('task-1', 'ab')).toThrow('at least 3 characters');
    });

    test('accepts custom priority', () => {
      const priority = new TaskPriority(TaskPriority.HIGH);
      const task = new Task('task-1', 'Urgent fix', { priority });

      expect(task.priority.value).toBe(TaskPriority.HIGH);
    });
  });

  describe('complete()', () => {
    test('completes pending task', () => {
      const task = new Task('task-1', 'Do something');

      task.complete();

      expect(task.status.value).toBe(TaskStatus.COMPLETED);
      expect(task.completedAt).toBeInstanceOf(Date);
    });

    test('throws when completing completed task', () => {
      const task = new Task('task-1', 'Do something');
      task.complete();

      expect(() => task.complete()).toThrow('already completed');
    });

    test('throws when completing cancelled task', () => {
      const task = new Task('task-1', 'Do something');
      task.cancel('No longer needed');

      expect(() => task.complete()).toThrow('Cannot complete cancelled');
    });
  });

  describe('isQuickWin()', () => {
    test('identifies quick win by tag', () => {
      const task = new Task('task-1', 'Quick fix', {
        tags: ['quick-win']
      });

      expect(task.isQuickWin()).toBe(true);
    });

    test('identifies quick win by priority and duration', () => {
      const task = new Task('task-1', 'Quick fix', {
        priority: new TaskPriority(TaskPriority.HIGH)
      });
      task.estimatedMinutes = 15;

      expect(task.isQuickWin()).toBe(true);
    });

    test('not quick win if low priority', () => {
      const task = new Task('task-1', 'Long task', {
        priority: new TaskPriority(TaskPriority.LOW)
      });

      expect(task.isQuickWin()).toBe(false);
    });
  });
});
```

### Integration Testing Use Cases

**Pattern:** Test use cases with real adapters (or in-memory fakes)

```javascript
// test/integration/use-cases/CreateTaskUseCase.test.js

import { CreateTaskUseCase } from '../../../use-cases/CreateTaskUseCase.js';
import { InMemoryTaskRepository } from '../../../adapters/repositories/InMemoryTaskRepository.js';
import { InMemoryProjectRepository } from '../../../adapters/repositories/InMemoryProjectRepository.js';
import { Project } from '../../../domain/entities/Project.js';

describe('CreateTaskUseCase', () => {
  let taskRepo;
  let projectRepo;
  let useCase;

  beforeEach(() => {
    taskRepo = new InMemoryTaskRepository();
    projectRepo = new InMemoryProjectRepository();
    useCase = new CreateTaskUseCase(taskRepo, projectRepo);
  });

  test('creates task successfully', async () => {
    const result = await useCase.execute({
      description: 'Fix failing test',
      priority: 'high'
    });

    expect(result.success).toBe(true);
    expect(result.task).toBeDefined();
    expect(result.task.description).toBe('Fix failing test');
    expect(result.task.priority.value).toBe('high');
  });

  test('creates task with project reference', async () => {
    // Setup: Add project to repository
    const project = new Project('proj-1', 'rmediation', '/path/to/rmediation', 'r-package');
    await projectRepo.save(project);

    const result = await useCase.execute({
      description: 'Add new feature',
      project: 'rmediation'
    });

    expect(result.success).toBe(true);
    expect(result.task.project).toBe('rmediation');
  });

  test('fails when project not found', async () => {
    const result = await useCase.execute({
      description: 'Add feature',
      project: 'nonexistent'
    });

    expect(result.success).toBe(false);
    expect(result.error).toContain('Project not found');
  });

  test('validates required fields', async () => {
    await expect(
      useCase.execute({ description: '' })
    ).rejects.toThrow('Description is required');
  });

  test('validates priority values', async () => {
    await expect(
      useCase.execute({
        description: 'Task',
        priority: 'invalid'
      })
    ).rejects.toThrow('Invalid priority');
  });

  test('persists task to repository', async () => {
    const result = await useCase.execute({
      description: 'Persistent task'
    });

    const saved = await taskRepo.findById(result.task.id);
    expect(saved).toBeDefined();
    expect(saved.description).toBe('Persistent task');
  });
});
```

### End-to-End Testing

**Pattern:** Test complete flow from controller to repository

```javascript
// test/e2e/task-workflow.test.js

import { DIContainer } from '../../../frameworks/di-container.js';
import { TaskPriority } from '../../../domain/value-objects/TaskPriority.js';
import { mkdir, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';

describe('Task Workflow E2E', () => {
  let container;
  let tempDir;

  beforeEach(async () => {
    // Create temporary directory for test data
    tempDir = join(tmpdir(), `zsh-workflow-test-${Date.now()}`);
    await mkdir(tempDir, { recursive: true });

    // Create DI container with test storage
    container = new DIContainer();
    // Override storage paths for testing
    // (in real implementation, DIContainer would accept config)
  });

  afterEach(async () => {
    // Cleanup
    await rm(tempDir, { recursive: true, force: true });
  });

  test('complete workflow: create, list, complete', async () => {
    const createUseCase = container.get('createTaskUseCase');
    const listUseCase = container.get('listTasksUseCase');
    const completeUseCase = container.get('completeTaskUseCase');

    // Create multiple tasks
    const task1 = await createUseCase.execute({
      description: 'High priority task',
      priority: TaskPriority.HIGH
    });

    const task2 = await createUseCase.execute({
      description: 'Medium priority task',
      priority: TaskPriority.MEDIUM
    });

    expect(task1.success).toBe(true);
    expect(task2.success).toBe(true);

    // List all tasks
    const listResult = await listUseCase.execute({});

    expect(listResult.success).toBe(true);
    expect(listResult.tasks).toHaveLength(2);
    expect(listResult.summary.total).toBe(2);
    expect(listResult.summary.byPriority.high).toBe(1);

    // Complete high priority task
    const completeResult = await completeUseCase.execute({
      taskId: task1.task.id
    });

    expect(completeResult.success).toBe(true);

    // List pending tasks
    const pendingResult = await listUseCase.execute({
      status: 'pending'
    });

    expect(pendingResult.tasks).toHaveLength(1);
    expect(pendingResult.tasks[0].description).toBe('Medium priority task');
  });
});
```

---

## Summary

These code examples demonstrate:

1. **Domain Layer**: Pure business logic with no dependencies
2. **Use Cases Layer**: Application workflows orchestrating domain objects
3. **Adapters Layer**: Implementations connecting to external systems
4. **Dependency Injection**: Wiring everything together at startup
5. **Testing**: Unit, integration, and E2E test patterns

**Key Principles Applied:**
- ✅ Dependencies point inward (Dependency Rule)
- ✅ Domain knows nothing about infrastructure
- ✅ Interfaces (Ports) defined by inner layers
- ✅ Implementations (Adapters) in outer layers
- ✅ Easy to test (dependency injection)
- ✅ Easy to swap implementations

**Next Steps:**
1. Copy relevant examples to your feature
2. Adjust names and business rules to match your domain
3. Write tests first (TDD)
4. Implement layer by layer (Domain → Use Cases → Adapters → Frameworks)

---

**Generated:** 2025-12-21
**Part of:** Documentation Sprint (Week 1)
**See Also:** [ARCHITECTURE-PATTERNS-ANALYSIS.md](ARCHITECTURE-PATTERNS-ANALYSIS.md), [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
