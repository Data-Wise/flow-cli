/**
 * Project Detector Bridge
 *
 * Bridges Node.js to vendored zsh-claude-workflow shell functions.
 * Uses the vendored project-detector.sh to detect project types.
 *
 * @module project-detector-bridge
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const execAsync = promisify(exec);

/**
 * Detect project type using vendored zsh-claude-workflow functions
 *
 * @param {string} projectPath - Absolute path to project directory
 * @returns {Promise<string>} Project type (r-package, quarto, node, python, etc.)
 * @throws {Error} If detection fails
 *
 * @example
 * const type = await detectProjectType('/Users/dt/projects/r-packages/stable/rmediation');
 * console.log(type); // 'r-package'
 */
export async function detectProjectType(projectPath) {
  const vendorDir = path.join(__dirname, '../vendor/zsh-claude-workflow');
  const coreScript = path.join(vendorDir, 'core.sh');
  const detectorScript = path.join(vendorDir, 'project-detector.sh');

  try {
    // Source core.sh first, then project-detector.sh, then run get_project_type
    const { stdout, stderr } = await execAsync(
      `source "${coreScript}" && source "${detectorScript}" && cd "${projectPath}" && get_project_type`,
      {
        shell: '/bin/zsh',
        env: process.env
      }
    );

    if (stderr) {
      console.error(`Warning from project detector: ${stderr}`);
    }

    // Map the output types to our expected types
    const detectedType = stdout.trim();
    return mapProjectType(detectedType);
  } catch (error) {
    console.error(`Failed to detect project type for ${projectPath}:`, error.message);
    return 'unknown';
  }
}

/**
 * Map project types from zsh-claude-workflow to our naming convention
 *
 * @param {string} type - Type from get_project_type (rpkg, quarto, etc.)
 * @returns {string} Normalized type name
 * @private
 */
function mapProjectType(type) {
  const mapping = {
    'rpkg': 'r-package',
    'quarto': 'quarto',
    'quarto-ext': 'quarto-extension',
    'research': 'research',
    'project': 'generic',
    'unknown': 'unknown'
  };

  return mapping[type] || type;
}

/**
 * Get list of supported project types
 *
 * These types match the detection logic in project-detector.sh
 *
 * @returns {string[]} Array of supported project type identifiers
 */
export function getSupportedTypes() {
  return [
    'r-package',
    'quarto',
    'quarto-extension',
    'research',
    'generic',
    'unknown'
  ];
}

/**
 * Detect multiple projects in parallel
 *
 * @param {string[]} projectPaths - Array of absolute paths to projects
 * @returns {Promise<Object>} Map of path -> project type
 *
 * @example
 * const results = await detectMultipleProjects([
 *   '/Users/dt/projects/r-packages/stable/rmediation',
 *   '/Users/dt/projects/teaching/stat-440'
 * ]);
 * // { '/Users/dt/.../rmediation': 'r-package', '/Users/dt/.../stat-440': 'quarto' }
 */
export async function detectMultipleProjects(projectPaths) {
  const results = {};

  // Run detections in parallel for performance
  const detections = await Promise.all(
    projectPaths.map(async (projectPath) => {
      const type = await detectProjectType(projectPath);
      return { projectPath, type };
    })
  );

  // Convert to map
  for (const { projectPath, type } of detections) {
    results[projectPath] = type;
  }

  return results;
}

/**
 * Check if a project type is supported
 *
 * @param {string} type - Project type to check
 * @returns {boolean} True if type is supported
 */
export function isTypeSupported(type) {
  return getSupportedTypes().includes(type);
}
