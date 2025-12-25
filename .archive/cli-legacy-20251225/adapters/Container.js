/**
 * Dependency Injection Container
 *
 * Wires together all layers of the Clean Architecture:
 * - Adapters (repositories)
 * - Use Cases
 * - Domain (entities, value objects)
 *
 * This is a simple container that creates and caches instances.
 * For production, could use a library like awilix or bottlejs.
 */

import { join } from 'path'
import { homedir } from 'os'
import { FileSystemSessionRepository } from './repositories/FileSystemSessionRepository.js'
import { FileSystemProjectRepository } from './repositories/FileSystemProjectRepository.js'
import { CreateSessionUseCase } from '../use-cases/CreateSessionUseCase.js'
import { EndSessionUseCase } from '../use-cases/EndSessionUseCase.js'
import { ScanProjectsUseCase } from '../use-cases/ScanProjectsUseCase.js'
import { GetStatusUseCase } from '../use-cases/GetStatusUseCase.js'
import { GetRecentProjectsUseCase } from '../use-cases/GetRecentProjectsUseCase.js'
import { SimpleEventPublisher } from './events/SimpleEventPublisher.js'

export class Container {
  constructor(options = {}) {
    this.instances = {}

    // Configuration
    this.config = {
      dataDir: options.dataDir || join(homedir(), '.flow-cli'),
      detectorScriptPath: options.detectorScriptPath || null
    }
  }

  /**
   * Get or create an instance
   * @private
   */
  _resolve(name, factory) {
    if (!this.instances[name]) {
      this.instances[name] = factory()
    }
    return this.instances[name]
  }

  // Repositories (Adapters Layer)

  getSessionRepository() {
    return this._resolve('sessionRepository', () => {
      const filePath = join(this.config.dataDir, 'sessions.json')
      return new FileSystemSessionRepository(filePath)
    })
  }

  getProjectRepository() {
    return this._resolve('projectRepository', () => {
      const filePath = join(this.config.dataDir, 'projects.json')
      return new FileSystemProjectRepository(filePath, this.config.detectorScriptPath)
    })
  }

  // Use Cases (Application Layer)

  getCreateSessionUseCase() {
    return this._resolve('createSessionUseCase', () => {
      return new CreateSessionUseCase(this.getSessionRepository(), this.getProjectRepository())
    })
  }

  getEndSessionUseCase() {
    return this._resolve('endSessionUseCase', () => {
      return new EndSessionUseCase(this.getSessionRepository(), this.getProjectRepository())
    })
  }

  getScanProjectsUseCase() {
    return this._resolve('scanProjectsUseCase', () => {
      return new ScanProjectsUseCase(this.getProjectRepository())
    })
  }

  getGetStatusUseCase() {
    return this._resolve('getStatusUseCase', () => {
      return new GetStatusUseCase(this.getSessionRepository(), this.getProjectRepository())
    })
  }

  getGetRecentProjectsUseCase() {
    return this._resolve('getRecentProjectsUseCase', () => {
      return new GetRecentProjectsUseCase(this.getProjectRepository())
    })
  }

  // Services (Infrastructure Layer)

  getEventPublisher() {
    return this._resolve('eventPublisher', () => {
      return new SimpleEventPublisher()
    })
  }

  /**
   * Clear all cached instances (useful for testing)
   */
  clear() {
    this.instances = {}
  }

  /**
   * Get all use cases
   */
  getUseCases() {
    return {
      createSession: this.getCreateSessionUseCase(),
      endSession: this.getEndSessionUseCase(),
      scanProjects: this.getScanProjectsUseCase(),
      getStatus: this.getGetStatusUseCase(),
      getRecentProjects: this.getGetRecentProjectsUseCase()
    }
  }

  /**
   * Get all repositories
   */
  getRepositories() {
    return {
      sessions: this.getSessionRepository(),
      projects: this.getProjectRepository()
    }
  }
}

/**
 * Create a container with default configuration
 */
export function createContainer(options = {}) {
  return new Container(options)
}
