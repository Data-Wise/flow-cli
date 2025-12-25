/**
 * ProjectType Value Object
 *
 * Represents the type of project being worked on.
 * Immutable - once created, cannot be changed.
 */

export class ProjectType {
  // Project types based on actual workflow detection
  static R_PACKAGE = 'r-package'
  static QUARTO = 'quarto'
  static NODE = 'node'
  static PYTHON = 'python'
  static MCP = 'mcp'
  static ZSH = 'zsh'
  static SPACEMACS = 'spacemacs'
  static TEACHING = 'teaching'
  static RESEARCH = 'research'
  static GENERAL = 'general'

  /**
   * Create a project type
   * @param {string} value - One of the defined project types
   */
  constructor(value) {
    const validTypes = [
      ProjectType.R_PACKAGE,
      ProjectType.QUARTO,
      ProjectType.NODE,
      ProjectType.PYTHON,
      ProjectType.MCP,
      ProjectType.ZSH,
      ProjectType.SPACEMACS,
      ProjectType.TEACHING,
      ProjectType.RESEARCH,
      ProjectType.GENERAL
    ]

    if (!validTypes.includes(value)) {
      throw new Error(`Invalid project type: ${value}. Must be one of: ${validTypes.join(', ')}`)
    }

    this._value = value
    Object.freeze(this) // Make immutable
  }

  /**
   * Get the type value
   */
  get value() {
    return this._value
  }

  /**
   * Get display icon for this project type
   */
  getIcon() {
    const icons = {
      [ProjectType.R_PACKAGE]: '📊',
      [ProjectType.QUARTO]: '📝',
      [ProjectType.NODE]: '⬢',
      [ProjectType.PYTHON]: '🐍',
      [ProjectType.MCP]: '🔌',
      [ProjectType.ZSH]: '🐚',
      [ProjectType.SPACEMACS]: '🚀',
      [ProjectType.TEACHING]: '🎓',
      [ProjectType.RESEARCH]: '🔬',
      [ProjectType.GENERAL]: '📁'
    }
    return icons[this._value] || '📁'
  }

  /**
   * Get display name for this project type
   */
  getDisplayName() {
    const names = {
      [ProjectType.R_PACKAGE]: 'R Package',
      [ProjectType.QUARTO]: 'Quarto',
      [ProjectType.NODE]: 'Node.js',
      [ProjectType.PYTHON]: 'Python',
      [ProjectType.MCP]: 'MCP Server',
      [ProjectType.ZSH]: 'ZSH Config',
      [ProjectType.SPACEMACS]: 'Spacemacs',
      [ProjectType.TEACHING]: 'Teaching',
      [ProjectType.RESEARCH]: 'Research',
      [ProjectType.GENERAL]: 'General'
    }
    return names[this._value] || 'Unknown'
  }

  /**
   * Compare with another ProjectType
   */
  equals(other) {
    return other instanceof ProjectType && this._value === other._value
  }

  /**
   * String representation
   */
  toString() {
    return this._value
  }
}
