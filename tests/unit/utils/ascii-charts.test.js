/**
 * Tests for ASCII Chart Utilities
 */

import {
  sparkline,
  progressBar,
  barChart,
  trendIndicator,
  percentIndicator,
  histogram,
  durationBar
} from '../../../cli/utils/ascii-charts.js'

describe('ASCII Chart Utilities', () => {
  describe('sparkline', () => {
    it('should generate sparkline from data', () => {
      const data = [1, 2, 3, 5, 8, 5, 3, 2, 1]
      const result = sparkline(data)

      expect(result).toBeTruthy()
      expect(result.length).toBe(data.length)
      expect(result).toMatch(/[▁▂▃▄▅▆▇█]+/)
    })

    it('should handle empty data', () => {
      expect(sparkline([])).toBe('')
      expect(sparkline(null)).toBe('')
    })

    it('should handle constant values', () => {
      const data = [5, 5, 5, 5, 5]
      const result = sparkline(data)

      expect(result.length).toBe(data.length)
      // All values should be the same character (middle tick)
      expect(new Set(result).size).toBe(1)
    })

    it('should handle custom min/max', () => {
      const data = [5, 10, 15]
      const result = sparkline(data, { min: 0, max: 20 })

      expect(result).toBeTruthy()
      expect(result.length).toBe(data.length)
    })

    it('should show increasing trend', () => {
      const data = [1, 2, 3, 4, 5, 6, 7, 8]
      const result = sparkline(data)

      // First character should be lower than last
      const ticks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']
      const firstIndex = ticks.indexOf(result[0])
      const lastIndex = ticks.indexOf(result[result.length - 1])

      expect(lastIndex).toBeGreaterThan(firstIndex)
    })
  })

  describe('progressBar', () => {
    it('should generate progress bar', () => {
      const result = progressBar(60, 100)

      expect(result).toContain('[')
      expect(result).toContain(']')
      expect(result).toContain('60%')
      expect(result).toMatch(/[█░]+/)
    })

    it('should handle 0%', () => {
      const result = progressBar(0, 100)

      expect(result).toContain('0%')
      expect(result).toMatch(/\[░+\]/)
    })

    it('should handle 100%', () => {
      const result = progressBar(100, 100)

      expect(result).toContain('100%')
      expect(result).toMatch(/\[█+\]/)
    })

    it('should respect custom width', () => {
      const result = progressBar(50, 100, { width: 10 })

      // Should have 10 characters between brackets
      const barContent = result.match(/\[(.*?)\]/)[1]
      expect(barContent.length).toBe(10)
    })

    it('should hide percentage when showPercent is false', () => {
      const result = progressBar(60, 100, { showPercent: false })

      expect(result).not.toContain('%')
      expect(result).toMatch(/\[█+░+\]/)
    })

    it('should use custom characters', () => {
      const result = progressBar(50, 100, {
        filled: '#',
        empty: '-',
        showPercent: false
      })

      expect(result).toContain('#')
      expect(result).toContain('-')
      expect(result).not.toContain('█')
      expect(result).not.toContain('░')
    })
  })

  describe('trendIndicator', () => {
    it('should show upward trend', () => {
      const result = trendIndicator(100, 80)
      expect(result).toBe('↗')
    })

    it('should show downward trend', () => {
      const result = trendIndicator(80, 100)
      expect(result).toBe('↘')
    })

    it('should show flat trend', () => {
      const result = trendIndicator(100, 100)
      expect(result).toBe('→')
    })

    it('should respect threshold', () => {
      const result = trendIndicator(101, 100, { threshold: 5 })
      expect(result).toBe('→') // Within threshold
    })

    it('should exceed threshold', () => {
      const result = trendIndicator(106, 100, { threshold: 5 })
      expect(result).toBe('↗') // Beyond threshold
    })
  })

  describe('durationBar', () => {
    it('should format minutes only', () => {
      const result = durationBar(45)

      expect(result).toContain('45m')
      expect(result).toMatch(/[█░]/)
    })

    it('should format hours and minutes', () => {
      const result = durationBar(90)

      expect(result).toContain('1h 30m')
    })

    it('should format hours only', () => {
      const result = durationBar(120)

      expect(result).toContain('2h')
      expect(result).not.toContain('0m')
    })

    it('should show visual blocks', () => {
      const result = durationBar(30) // 2 blocks (15m each)

      expect(result).toMatch(/█{2}/)
    })

    it('should limit blocks to 10', () => {
      const result = durationBar(300) // 20 blocks worth

      const blocks = result.match(/█+/)?.[0] || ''
      expect(blocks.length).toBeLessThanOrEqual(10)
    })

    it('should show partial block', () => {
      const result = durationBar(23) // 1 full block + partial

      expect(result).toContain('█')
      expect(result).toContain('░')
    })
  })

  describe('barChart', () => {
    it('should generate bar chart', () => {
      const data = [
        { label: 'Project A', value: 120 },
        { label: 'Project B', value: 80 }
      ]
      const result = barChart(data)

      expect(result).toContain('Project A')
      expect(result).toContain('Project B')
      expect(result).toContain('120')
      expect(result).toContain('80')
      expect(result).toMatch(/█+/)
    })

    it('should handle empty data', () => {
      expect(barChart([])).toBe('')
      expect(barChart(null)).toBe('')
    })

    it('should normalize bars to max value', () => {
      const data = [
        { label: 'Max', value: 100 },
        { label: 'Half', value: 50 }
      ]
      const result = barChart(data, { maxWidth: 40 })
      const lines = result.split('\n')

      // Max value should have full width bar
      const maxLine = lines[0]
      const maxBar = maxLine.match(/█+/)[0]
      expect(maxBar.length).toBe(40)

      // Half value should have half width bar
      const halfLine = lines[1]
      const halfBar = halfLine.match(/█+/)[0]
      expect(halfBar.length).toBe(20)
    })

    it('should respect label width', () => {
      const data = [{ label: 'Very Long Project Name', value: 100 }]
      const result = barChart(data, { labelWidth: 10 })

      // Label should be truncated to 10 characters
      expect(result).toContain('Very Long ')
    })
  })

  describe('percentIndicator', () => {
    it('should show high indicator', () => {
      const result = percentIndicator(85)

      expect(result).toContain('85%')
      expect(result).toContain('██')
    })

    it('should show medium indicator', () => {
      const result = percentIndicator(50)

      expect(result).toContain('50%')
      expect(result).toContain('█░')
    })

    it('should show low indicator', () => {
      const result = percentIndicator(20)

      expect(result).toContain('20%')
      expect(result).toContain('░░')
    })

    it('should respect custom thresholds', () => {
      const result = percentIndicator(40, { thresholds: [30, 70] })

      // 40 is between 30 and 70, so medium
      expect(result).toContain('█░')
    })
  })

  describe('histogram', () => {
    it('should generate histogram', () => {
      const data = [1, 2, 2, 3, 3, 3, 4, 4, 5]
      const result = histogram(data)

      expect(result).toBeTruthy()
      expect(result).toMatch(/[█ ]+/)
      expect(result.split('\n').length).toBe(5) // Default height
    })

    it('should handle empty data', () => {
      expect(histogram([])).toBe('')
      expect(histogram(null)).toBe('')
    })

    it('should respect custom bins', () => {
      const data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      const result = histogram(data, { bins: 5 })

      // Should have bars for 5 bins
      const firstLine = result.split('\n')[0]
      expect(firstLine.length).toBe(5)
    })

    it('should respect custom height', () => {
      const data = [1, 2, 3, 4, 5]
      const result = histogram(data, { height: 10 })

      expect(result.split('\n').length).toBe(10)
    })
  })

  describe('Integration scenarios', () => {
    it('should visualize session duration trend', () => {
      // Simulate session durations over time
      const sessions = [30, 45, 60, 55, 70, 65, 80, 75, 90]
      const trend = sparkline(sessions)

      expect(trend).toBeTruthy()
      expect(trend.length).toBe(sessions.length)
    })

    it('should show completion rate progress', () => {
      const completed = 7
      const total = 10
      const rate = (completed / total) * 100
      const bar = progressBar(rate, 100)

      expect(bar).toContain('70%')
    })

    it('should display project statistics', () => {
      const projects = [
        { label: 'flow-cli', value: 180 },
        { label: 'zsh-config', value: 120 },
        { label: 'scripts', value: 60 }
      ]
      const chart = barChart(projects)

      expect(chart).toContain('flow-cli')
      expect(chart).toContain('180')
    })
  })
})
