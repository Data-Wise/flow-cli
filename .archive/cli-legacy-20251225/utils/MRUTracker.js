/**
 * MRUTracker
 *
 * Most Recently Used (MRU) tracking for projects.
 *
 * Features:
 * - LRU eviction when size limit reached
 * - Automatic reordering on access
 * - Persistent storage support
 * - Fast O(1) access and updates
 *
 * Use Cases:
 * - Quick access to recently used projects
 * - Project picker optimization
 * - Session history tracking
 *
 * Usage:
 * ```js
 * const mru = new MRUTracker({ maxSize: 20 })
 * mru.access('flow-cli')
 * mru.access('zsh-config')
 * const recent = mru.getRecent(10) // ['zsh-config', 'flow-cli']
 * ```
 */

export class MRUTracker {
  /**
   * Create a new MRU tracker
   * @param {Object} options - Configuration options
   * @param {number} [options.maxSize=50] - Maximum number of entries
   */
  constructor(options = {}) {
    this.maxSize = options.maxSize || 50
    // Use Map to maintain insertion order
    // Map iteration order = insertion order in JavaScript
    this.entries = new Map()
  }

  /**
   * Record access to a project
   * @param {string} projectId - Project identifier
   * @param {Object} [metadata] - Optional metadata to store
   */
  access(projectId, metadata = {}) {
    // Remove existing entry (will re-add at end)
    if (this.entries.has(projectId)) {
      this.entries.delete(projectId)
    }

    // Add/move to end (most recent)
    this.entries.set(projectId, {
      projectId,
      timestamp: Date.now(),
      ...metadata
    })

    // Enforce size limit (evict oldest)
    if (this.entries.size > this.maxSize) {
      this._evictOldest()
    }
  }

  /**
   * Get N most recent projects
   * @param {number} [limit=10] - Number of projects to return
   * @returns {Array} Recent project IDs (most recent first)
   */
  getRecent(limit = 10) {
    const entries = Array.from(this.entries.keys())
    // Reverse because Map order is oldest->newest
    return entries.reverse().slice(0, limit)
  }

  /**
   * Get recent projects with metadata
   * @param {number} [limit=10] - Number of projects to return
   * @returns {Array} Recent entries with metadata
   */
  getRecentWithMetadata(limit = 10) {
    const entries = Array.from(this.entries.values())
    return entries.reverse().slice(0, limit)
  }

  /**
   * Check if a project is in MRU list
   * @param {string} projectId - Project identifier
   * @returns {boolean} True if project is tracked
   */
  has(projectId) {
    return this.entries.has(projectId)
  }

  /**
   * Get position of project in MRU list (0 = most recent)
   * @param {string} projectId - Project identifier
   * @returns {number} Position or -1 if not found
   */
  getPosition(projectId) {
    if (!this.entries.has(projectId)) {
      return -1
    }

    const keys = Array.from(this.entries.keys()).reverse()
    return keys.indexOf(projectId)
  }

  /**
   * Remove a project from MRU list
   * @param {string} projectId - Project identifier
   * @returns {boolean} True if removed
   */
  remove(projectId) {
    return this.entries.delete(projectId)
  }

  /**
   * Clear all entries
   */
  clear() {
    this.entries.clear()
  }

  /**
   * Get number of tracked projects
   * @returns {number} Entry count
   */
  size() {
    return this.entries.size
  }

  /**
   * Get all project IDs
   * @returns {string[]} All tracked project IDs (most recent first)
   */
  getAll() {
    return Array.from(this.entries.keys()).reverse()
  }

  /**
   * Serialize to JSON-compatible object
   * @returns {Object} Serializable state
   */
  toJSON() {
    return {
      maxSize: this.maxSize,
      entries: Array.from(this.entries.entries())
    }
  }

  /**
   * Restore from serialized state
   * @param {Object} data - Serialized state
   * @returns {MRUTracker} Restored tracker
   */
  static fromJSON(data) {
    const tracker = new MRUTracker({ maxSize: data.maxSize })

    // Restore entries in order
    for (const [projectId, entry] of data.entries) {
      tracker.entries.set(projectId, entry)
    }

    return tracker
  }

  /**
   * Get statistics
   * @returns {Object} MRU statistics
   */
  getStats() {
    const now = Date.now()
    const entries = Array.from(this.entries.values())

    if (entries.length === 0) {
      return {
        size: 0,
        oldestAge: 0,
        newestAge: 0,
        averageAge: 0
      }
    }

    const ages = entries.map(e => now - e.timestamp)
    const oldest = Math.max(...ages)
    const newest = Math.min(...ages)
    const average = ages.reduce((sum, age) => sum + age, 0) / ages.length

    return {
      size: this.entries.size,
      maxSize: this.maxSize,
      oldestAge: Math.floor(oldest / 1000), // seconds
      newestAge: Math.floor(newest / 1000), // seconds
      averageAge: Math.floor(average / 1000) // seconds
    }
  }

  /**
   * Remove old entries (older than threshold)
   * @param {number} maxAge - Maximum age in milliseconds
   * @returns {number} Number of entries removed
   */
  cleanup(maxAge) {
    const now = Date.now()
    let removed = 0

    for (const [projectId, entry] of this.entries.entries()) {
      if (now - entry.timestamp > maxAge) {
        this.entries.delete(projectId)
        removed++
      }
    }

    return removed
  }

  /**
   * Evict oldest entry (LRU)
   * @private
   */
  _evictOldest() {
    // First entry is oldest (Map preserves insertion order)
    const firstKey = this.entries.keys().next().value
    if (firstKey) {
      this.entries.delete(firstKey)
    }
  }

  /**
   * Merge with another MRU tracker
   * @param {MRUTracker} other - Other tracker to merge
   * @param {string} [strategy='latest'] - Merge strategy ('latest' or 'keep')
   */
  merge(other, strategy = 'latest') {
    for (const [projectId, entry] of other.entries.entries()) {
      if (strategy === 'latest') {
        // Always use the latest timestamp
        const existing = this.entries.get(projectId)
        if (!existing || entry.timestamp > existing.timestamp) {
          this.access(projectId, entry)
        }
      } else if (strategy === 'keep') {
        // Keep existing if present
        if (!this.entries.has(projectId)) {
          this.access(projectId, entry)
        }
      }
    }

    // Enforce size limit after merge
    while (this.entries.size > this.maxSize) {
      this._evictOldest()
    }
  }
}
