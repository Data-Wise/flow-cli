/**
 * Unit tests for ProjectType value object
 */

import { ProjectType } from '../../../../cli/domain/value-objects/ProjectType.js'

describe('ProjectType Value Object', () => {
  describe('Construction', () => {
    test('creates valid project type', () => {
      const type = new ProjectType(ProjectType.R_PACKAGE)

      expect(type.value).toBe(ProjectType.R_PACKAGE)
    })

    test('throws error for invalid type', () => {
      expect(() => new ProjectType('invalid')).toThrow('Invalid project type: invalid')
    })

    test('is immutable', () => {
      const type = new ProjectType(ProjectType.NODE)

      expect(() => {
        type._value = ProjectType.PYTHON
      }).toThrow()
    })
  })

  describe('Icons', () => {
    test('returns correct icon for R package', () => {
      const type = new ProjectType(ProjectType.R_PACKAGE)
      expect(type.getIcon()).toBe('📊')
    })

    test('returns correct icon for Node', () => {
      const type = new ProjectType(ProjectType.NODE)
      expect(type.getIcon()).toBe('⬢')
    })

    test('returns correct icon for Python', () => {
      const type = new ProjectType(ProjectType.PYTHON)
      expect(type.getIcon()).toBe('🐍')
    })

    test('returns default icon for unknown type', () => {
      const type = new ProjectType(ProjectType.GENERAL)
      expect(type.getIcon()).toBe('📁')
    })
  })

  describe('Display Names', () => {
    test('returns correct display name for R package', () => {
      const type = new ProjectType(ProjectType.R_PACKAGE)
      expect(type.getDisplayName()).toBe('R Package')
    })

    test('returns correct display name for Quarto', () => {
      const type = new ProjectType(ProjectType.QUARTO)
      expect(type.getDisplayName()).toBe('Quarto')
    })

    test('returns correct display name for MCP', () => {
      const type = new ProjectType(ProjectType.MCP)
      expect(type.getDisplayName()).toBe('MCP Server')
    })
  })

  describe('Equality', () => {
    test('equals returns true for same type', () => {
      const type1 = new ProjectType(ProjectType.R_PACKAGE)
      const type2 = new ProjectType(ProjectType.R_PACKAGE)

      expect(type1.equals(type2)).toBe(true)
    })

    test('equals returns false for different types', () => {
      const type1 = new ProjectType(ProjectType.R_PACKAGE)
      const type2 = new ProjectType(ProjectType.NODE)

      expect(type1.equals(type2)).toBe(false)
    })

    test('equals returns false for non-ProjectType', () => {
      const type = new ProjectType(ProjectType.R_PACKAGE)

      expect(type.equals('r-package')).toBe(false)
      expect(type.equals(null)).toBe(false)
    })
  })

  describe('String Representation', () => {
    test('toString returns value', () => {
      const type = new ProjectType(ProjectType.R_PACKAGE)

      expect(type.toString()).toBe('r-package')
    })
  })

  describe('All Project Types', () => {
    test('all defined types are valid', () => {
      const types = [
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

      for (const typeValue of types) {
        expect(() => new ProjectType(typeValue)).not.toThrow()
      }
    })

    test('all types have icons', () => {
      const types = [
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

      for (const typeValue of types) {
        const type = new ProjectType(typeValue)
        expect(type.getIcon()).toBeTruthy()
        expect(typeof type.getIcon()).toBe('string')
      }
    })

    test('all types have display names', () => {
      const types = [
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

      for (const typeValue of types) {
        const type = new ProjectType(typeValue)
        expect(type.getDisplayName()).toBeTruthy()
        expect(typeof type.getDisplayName()).toBe('string')
      }
    })
  })
})
