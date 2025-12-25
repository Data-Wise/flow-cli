/**
 * StatusFileGateway
 *
 * Adapter for reading .STATUS files from project directories.
 * Supports both legacy format and new YAML frontmatter format.
 */

import { readFile, writeFile } from 'fs/promises'
import { existsSync } from 'fs'
import { join } from 'path'

export class StatusFileGateway {
  /**
   * Read .STATUS file from project directory
   * @param {string} projectPath - Path to project directory
   * @returns {Promise<Object|null>} Status data or null if not found
   */
  async read(projectPath) {
    const statusPath = join(projectPath, '.STATUS')

    if (!existsSync(statusPath)) {
      return null
    }

    try {
      const content = await readFile(statusPath, 'utf-8')

      // Check if it's YAML frontmatter format (starts with ---)
      if (content.trim().startsWith('---')) {
        return this._parseYAMLFormat(content)
      } else {
        return this._parseLegacyFormat(content)
      }
    } catch (error) {
      console.error(`Warning: Could not read .STATUS file: ${error.message}`)
      return null
    }
  }

  /**
   * Parse YAML frontmatter format (.STATUS v2)
   * @private
   */
  _parseYAMLFormat(content) {
    // Extract frontmatter
    const frontmatterMatch = content.match(/^---\n(.*?)\n---/s)
    if (!frontmatterMatch) {
      return this._parseLegacyFormat(content)
    }

    const frontmatter = frontmatterMatch[1]
    const body = content.slice(frontmatterMatch[0].length).trim()

    // Simple YAML parser for our specific format
    const data = {}
    let currentSection = null
    let currentArray = null
    let indentLevel = 0

    for (const line of frontmatter.split('\n')) {
      const trimmed = line.trim()

      // Skip comments and empty lines
      if (!trimmed || trimmed.startsWith('#')) continue

      // Calculate indent level
      const currentIndent = line.search(/\S/)

      // Detect sections (next:, metrics:) at indent level 0
      if (currentIndent === 0 && trimmed.endsWith(':') && !trimmed.startsWith('-')) {
        currentSection = trimmed.slice(0, -1)
        if (currentSection === 'next') {
          data[currentSection] = []
          currentArray = data[currentSection]
        } else {
          data[currentSection] = {}
          currentArray = null // Reset array context
        }
        indentLevel = currentIndent
        continue
      }

      // Parse array items for 'next' section
      if (currentSection === 'next' && trimmed.startsWith('- ')) {
        const item = {}
        currentArray.push(item)

        // Parse action line
        const actionMatch = trimmed.match(/- action: "(.+)"/)
        if (actionMatch) {
          item.action = actionMatch[1]
        }
        continue
      }

      // Parse nested properties (indented)
      if (currentIndent > 0 && trimmed.includes(':')) {
        const colonIndex = trimmed.indexOf(':')
        const key = trimmed.substring(0, colonIndex).trim()
        const value = trimmed.substring(colonIndex + 1).trim()

        if (currentArray && currentArray.length > 0) {
          // Add to last array item
          const lastItem = currentArray[currentArray.length - 1]
          lastItem[key] = this._parseValue(value)
        } else if (currentSection) {
          // Add to current section object
          data[currentSection][key] = this._parseValue(value)
        }
        continue
      }

      // Top-level key-value pairs (indent 0, no current section)
      if (currentIndent === 0 && trimmed.includes(':') && !currentSection) {
        const colonIndex = trimmed.indexOf(':')
        const key = trimmed.substring(0, colonIndex).trim()
        const value = trimmed.substring(colonIndex + 1).trim()
        data[key] = this._parseValue(value)
      }
    }

    return {
      format: 'yaml',
      status: data.status || 'unknown',
      progress: data.progress || 0,
      type: data.type || 'generic',
      next: data.next || [],
      metrics: data.metrics || {},
      body
    }
  }

  /**
   * Parse legacy .STATUS format (plain text)
   * @private
   */
  _parseLegacyFormat(content) {
    const lines = content.split('\n')
    const data = {
      format: 'legacy',
      status: 'unknown',
      progress: 0,
      next: [],
      body: content
    }

    // Try to extract common patterns
    for (const line of lines) {
      const trimmed = line.trim()

      // Look for status indicators
      if (trimmed.startsWith('status:') || trimmed.startsWith('Status:')) {
        const statusMatch = trimmed.match(/status:\s*(\w+)/i)
        if (statusMatch) {
          data.status = statusMatch[1].toLowerCase()
        }
      }

      // Look for progress percentage
      const progressMatch = trimmed.match(/(\d+)%/)
      if (progressMatch) {
        data.progress = parseInt(progressMatch[1], 10)
      }

      // Look for "next:" or "next action:" lines
      if (
        trimmed.toLowerCase().startsWith('next:') ||
        trimmed.toLowerCase().startsWith('next action:')
      ) {
        const actionText = trimmed.split(':').slice(1).join(':').trim()
        if (actionText) {
          data.next.push({ action: actionText, priority: 'medium' })
        }
      }
    }

    return data
  }

  /**
   * Parse YAML value (string, number, boolean)
   * @private
   */
  _parseValue(value) {
    // Remove quotes
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      return value.slice(1, -1)
    }

    // Parse numbers
    if (/^\d+$/.test(value)) {
      return parseInt(value, 10)
    }

    // Parse booleans
    if (value === 'true') return true
    if (value === 'false') return false

    return value
  }

  /**
   * Write .STATUS file to project directory
   * @param {string} projectPath - Path to project directory
   * @param {Object} data - Status data to write
   * @returns {Promise<void>}
   */
  async write(projectPath, data) {
    const statusPath = join(projectPath, '.STATUS')

    // Generate YAML frontmatter format
    const content = this._generateYAMLFormat(data)

    try {
      await writeFile(statusPath, content, 'utf-8')
    } catch (error) {
      throw new Error(`Failed to write .STATUS file: ${error.message}`)
    }
  }

  /**
   * Generate YAML frontmatter format
   * @private
   */
  _generateYAMLFormat(data) {
    const lines = ['---']

    // Required fields
    if (data.status) lines.push(`status: ${data.status}`)
    if (data.progress !== undefined) lines.push(`progress: ${data.progress}`)
    if (data.type) lines.push(`type: ${data.type}`)

    // Next actions
    if (data.next && Array.isArray(data.next) && data.next.length > 0) {
      lines.push('')
      lines.push('next:')
      for (const action of data.next) {
        lines.push(`  - action: "${action.action}"`)
        if (action.estimate) lines.push(`    estimate: "${action.estimate}"`)
        if (action.priority) lines.push(`    priority: ${action.priority}`)
        if (action.blockers && action.blockers.length > 0) {
          lines.push(`    blockers:`)
          for (const blocker of action.blockers) {
            lines.push(`      - "${blocker}"`)
          }
        }
      }
    }

    // Metrics (auto-updated)
    if (data.metrics && Object.keys(data.metrics).length > 0) {
      lines.push('')
      lines.push('# Auto-updated fields (do not edit manually)')
      lines.push('metrics:')
      for (const [key, value] of Object.entries(data.metrics)) {
        lines.push(`  ${key}: ${value}`)
      }
    }

    lines.push('---')

    // Body content
    if (data.body) {
      lines.push('')
      lines.push(data.body.trim())
    }

    return lines.join('\n') + '\n'
  }

  /**
   * Check if path has a .STATUS file
   * @param {string} projectPath - Path to project directory
   * @returns {boolean}
   */
  hasStatusFile(projectPath) {
    const statusPath = join(projectPath, '.STATUS')
    return existsSync(statusPath)
  }
}
