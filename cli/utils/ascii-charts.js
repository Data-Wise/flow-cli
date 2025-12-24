/**
 * ASCII Chart Utilities
 *
 * Lightweight ASCII visualization helpers for terminal output.
 * No external dependencies - pure JavaScript implementations.
 *
 * Features:
 * - Sparklines (mini line charts): ▁▂▃▅▇█▇▅▃▂▁
 * - Progress bars: [████████████░░░░░░░░] 60%
 * - Horizontal bar charts
 * - Trend indicators: ↗ ↘ →
 */

/**
 * Generate ASCII sparkline from data points
 *
 * @param {number[]} data - Array of numbers to visualize
 * @param {Object} options - Configuration options
 * @param {number} [options.min] - Minimum value (default: auto)
 * @param {number} [options.max] - Maximum value (default: auto)
 * @returns {string} ASCII sparkline
 *
 * @example
 * sparkline([1, 2, 3, 5, 8, 5, 3, 2, 1])
 * // Returns: "▁▂▃▅▇▅▃▂▁"
 */
export function sparkline(data, options = {}) {
  if (!data || data.length === 0) return ''

  const ticks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']

  const min = options.min !== undefined ? options.min : Math.min(...data)
  const max = options.max !== undefined ? options.max : Math.max(...data)

  // Handle edge case where all values are the same
  if (min === max) {
    return ticks[Math.floor(ticks.length / 2)].repeat(data.length)
  }

  const range = max - min

  return data
    .map(value => {
      const normalized = (value - min) / range
      const index = Math.min(Math.floor(normalized * ticks.length), ticks.length - 1)
      return ticks[index]
    })
    .join('')
}

/**
 * Generate ASCII progress bar
 *
 * @param {number} value - Current value
 * @param {number} max - Maximum value
 * @param {Object} options - Configuration options
 * @param {number} [options.width=20] - Width of the bar
 * @param {string} [options.filled='█'] - Character for filled portion
 * @param {string} [options.empty='░'] - Character for empty portion
 * @param {boolean} [options.showPercent=true] - Show percentage
 * @returns {string} ASCII progress bar
 *
 * @example
 * progressBar(60, 100)
 * // Returns: "[████████████░░░░░░░░] 60%"
 */
export function progressBar(value, max, options = {}) {
  const width = options.width || 20
  const filled = options.filled || '█'
  const empty = options.empty || '░'
  const showPercent = options.showPercent !== false

  const percent = Math.round((value / max) * 100)
  const filledWidth = Math.round((value / max) * width)
  const emptyWidth = width - filledWidth

  const bar = `[${filled.repeat(filledWidth)}${empty.repeat(emptyWidth)}]`

  return showPercent ? `${bar} ${percent}%` : bar
}

/**
 * Generate horizontal bar chart
 *
 * @param {Object[]} data - Array of {label, value} objects
 * @param {Object} options - Configuration options
 * @param {number} [options.maxWidth=40] - Maximum bar width
 * @param {number} [options.labelWidth=20] - Label column width
 * @returns {string} Multi-line bar chart
 *
 * @example
 * barChart([
 *   { label: 'Project A', value: 120 },
 *   { label: 'Project B', value: 80 }
 * ])
 */
export function barChart(data, options = {}) {
  const maxWidth = options.maxWidth || 40
  const labelWidth = options.labelWidth || 20

  if (!data || data.length === 0) return ''

  const maxValue = Math.max(...data.map(d => d.value))

  return data
    .map(item => {
      const label = item.label.padEnd(labelWidth).substring(0, labelWidth)
      const barWidth = Math.round((item.value / maxValue) * maxWidth)
      const bar = '█'.repeat(barWidth)
      const value = String(item.value).padStart(5)

      return `${label} ${bar} ${value}`
    })
    .join('\n')
}

/**
 * Get trend indicator
 *
 * @param {number} current - Current value
 * @param {number} previous - Previous value
 * @param {Object} options - Configuration options
 * @param {number} [options.threshold=0] - Threshold for "no change"
 * @returns {string} Trend indicator: ↗ (up), ↘ (down), → (flat)
 *
 * @example
 * trendIndicator(100, 80)  // Returns: "↗"
 * trendIndicator(80, 100)  // Returns: "↘"
 * trendIndicator(100, 100) // Returns: "→"
 */
export function trendIndicator(current, previous, options = {}) {
  const threshold = options.threshold || 0
  const diff = current - previous

  if (Math.abs(diff) <= threshold) return '→'
  return diff > 0 ? '↗' : '↘'
}

/**
 * Format percentage with visual indicator
 *
 * @param {number} value - Percentage value (0-100)
 * @param {Object} options - Configuration options
 * @param {number[]} [options.thresholds=[33, 66]] - Thresholds for colors
 * @returns {string} Formatted percentage with indicator
 *
 * @example
 * percentIndicator(85)  // Returns: "85% ██"
 * percentIndicator(45)  // Returns: "45% █░"
 * percentIndicator(20)  // Returns: "20% ░░"
 */
export function percentIndicator(value, options = {}) {
  const thresholds = options.thresholds || [33, 66]
  const percent = Math.round(value)

  let indicator
  if (percent >= thresholds[1]) {
    indicator = '██' // High
  } else if (percent >= thresholds[0]) {
    indicator = '█░' // Medium
  } else {
    indicator = '░░' // Low
  }

  return `${percent}% ${indicator}`
}

/**
 * Create mini histogram
 *
 * @param {number[]} data - Array of numbers
 * @param {Object} options - Configuration options
 * @param {number} [options.bins=10] - Number of bins
 * @param {number} [options.height=5] - Height in characters
 * @returns {string} ASCII histogram
 */
export function histogram(data, options = {}) {
  const bins = options.bins || 10
  const height = options.height || 5

  if (!data || data.length === 0) return ''

  const min = Math.min(...data)
  const max = Math.max(...data)
  const range = max - min
  const binWidth = range / bins

  // Create bins
  const counts = new Array(bins).fill(0)
  data.forEach(value => {
    const binIndex = Math.min(Math.floor((value - min) / binWidth), bins - 1)
    counts[binIndex]++
  })

  const maxCount = Math.max(...counts)

  // Generate histogram from top to bottom
  const lines = []
  for (let row = height; row > 0; row--) {
    const line = counts
      .map(count => {
        const threshold = (maxCount / height) * row
        return count >= threshold ? '█' : ' '
      })
      .join('')
    lines.push(line)
  }

  return lines.join('\n')
}

/**
 * Format duration with visual representation
 *
 * @param {number} minutes - Duration in minutes
 * @returns {string} Formatted duration with blocks
 *
 * @example
 * durationBar(45)  // Returns: "45m ████░"
 * durationBar(90)  // Returns: "1h 30m █████████░"
 */
export function durationBar(minutes) {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60

  let text
  if (hours > 0) {
    text = mins > 0 ? `${hours}h ${mins}m` : `${hours}h`
  } else {
    text = `${mins}m`
  }

  // Visual blocks (each block = 15 minutes)
  const blocks = Math.floor(minutes / 15)
  const partial = minutes % 15 > 7 // Half block threshold
  const fullBlocks = '█'.repeat(Math.min(blocks, 10))
  const partialBlock = partial && blocks < 10 ? '░' : ''

  return `${text.padEnd(8)} ${fullBlocks}${partialBlock}`
}
