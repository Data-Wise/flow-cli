/**
 * SimpleEventPublisher
 *
 * A simple event publisher using Node's EventEmitter.
 * Used for real-time updates in the web dashboard.
 *
 * Events:
 * - session:created - When a new session is created
 * - session:updated - When a session is modified
 * - session:ended - When a session ends
 * - project:scanned - When projects are scanned
 */

import { EventEmitter } from 'events'

export class SimpleEventPublisher extends EventEmitter {
  constructor() {
    super()
    this.setMaxListeners(100) // Allow many WebSocket connections
  }

  /**
   * Publish an event
   * @param {string} eventName
   * @param {*} data
   */
  publish(eventName, data = {}) {
    this.emit(eventName, data)
  }

  /**
   * Subscribe to an event
   * @param {string} eventName
   * @param {Function} handler
   */
  subscribe(eventName, handler) {
    this.on(eventName, handler)
  }

  /**
   * Unsubscribe from an event
   * @param {string} eventName
   * @param {Function} handler
   */
  unsubscribe(eventName, handler) {
    this.off(eventName, handler)
  }

  /**
   * Get subscriber count for an event
   * @param {string} eventName
   * @returns {number}
   */
  getSubscriberCount(eventName) {
    return this.listenerCount(eventName)
  }
}
