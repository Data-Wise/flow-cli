# Specialized Libraries API Reference

> **Version:** 5.15.1 | **Updated:** 2026-01-22 | **Functions:** 160

This document provides comprehensive API documentation for flow-cli's specialized library functions. These functions power advanced features like parallel rendering, AI integration, teaching workflows, and configuration management.

---

## Table of Contents

1. [Dotfile Management](#dotfile-management)
2. [AI & LLM Integration](#ai-llm-integration)
3. [Parallel Rendering](#parallel-rendering)
4. [Date Parsing & Management](#date-parsing-management)
5. [Performance Monitoring](#performance-monitoring)
6. [R Package Management](#r-package-management)
7. [Quarto Profile Management](#quarto-profile-management)
8. [renv Integration](#renv-integration)
9. [Custom Validators](#custom-validators)
10. [Configuration Management](#configuration-management)
11. [Git Hook Management](#git-hook-management)
12. [Cache Analysis](#cache-analysis)
13. [Status Dashboard](#status-dashboard)
14. [Project Inventory](#project-inventory)
15. [Help System](#help-system)

---

## Dotfile Management

**File:** `lib/dotfile-helpers.zsh` | **Functions:** 27

Functions for managing dotfiles with chezmoi and Bitwarden integration.

### Chezmoi Detection & Verification

| Function | Purpose |
|----------|---------|
| `_dot_has_chezmoi` | Check if chezmoi dotfile manager is available (session cached) |
| `_dot_is_chezmoi_source` | Check if current directory is chezmoi source directory |
| `_dot_verify_chezmoi` | Verify chezmoi is installed with helpful error messages |

### Bitwarden Integration

| Function | Purpose |
|----------|---------|
| `_dot_has_bitwarden` | Check if Bitwarden CLI is available (session cached) |
| `_dot_bw_unlocked` | Check if Bitwarden vault is currently unlocked |
| `_dot_bw_unlock` | Unlock Bitwarden vault interactively with session caching |
| `_dot_bw_lock` | Lock Bitwarden vault and clear session |
| `_dot_bw_get_secret` | Get a secret value from Bitwarden by item name and field |
| `_dot_bw_list_items` | List all items in Bitwarden vault |
| `_dot_verify_bitwarden` | Verify Bitwarden CLI is installed with helpful messages |

### Chezmoi Operations

| Function | Purpose |
|----------|---------|
| `_dot_chezmoi_edit` | Edit a managed file with automatic apply |
| `_dot_chezmoi_add` | Add a file to chezmoi management |
| `_dot_chezmoi_diff` | Show pending changes in chezmoi |
| `_dot_chezmoi_apply` | Apply chezmoi changes to home directory |
| `_dot_chezmoi_update` | Pull and apply updates from remote |
| `_dot_chezmoi_status` | Show current chezmoi status |
| `_dot_chezmoi_cd` | Change to chezmoi source directory |
| `_dot_chezmoi_data` | Show chezmoi template data |

### macOS Keychain Integration

| Function | Purpose |
|----------|---------|
| `_dot_keychain_get` | Get a password from macOS Keychain |
| `_dot_keychain_set` | Store a password in macOS Keychain |
| `_dot_keychain_delete` | Delete a password from macOS Keychain |
| `_dot_keychain_exists` | Check if a keychain item exists |

### Security & Utility Functions

| Function | Purpose |
|----------|---------|
| `_dot_secret_source` | Determine the best available secret source |
| `_dot_get_secret` | Get a secret from any available source |
| `_dot_clear_caches` | Clear all cached session data |
| `_dot_health_check` | Check health of dotfile management tools |
| `_dot_help` | Display help for dotfile management commands |

---

## AI & LLM Integration

### AI Recipes

**File:** `lib/ai-recipes.zsh` | **Functions:** 11

| Function | Purpose |
|----------|---------|
| `_flow_recipe_init` | Initialize the user recipes directory |
| `_flow_recipe_list` | Display all available AI recipes (built-in and user) |
| `_flow_recipe_get` | Retrieve a recipe's content by name |
| `_flow_recipe_apply` | Replace template variables with actual values |
| `_flow_recipe_create` | Create a new user recipe from template |
| `_flow_recipe_edit` | Open an existing user recipe in editor |
| `_flow_recipe_delete` | Delete a user-created recipe |
| `_flow_recipe_show` | Display the full content of a recipe |
| `_flow_recipe_run` | Execute a recipe via Claude CLI |
| `flow_ai_recipe` | Main entry point for recipe command routing |
| `_flow_recipe_help` | Display help for the recipe system |

### AI Usage Tracking

**File:** `lib/ai-usage.zsh` | **Functions:** 9

| Function | Purpose |
|----------|---------|
| `_flow_ai_log_usage` | Log AI command execution to tracking system |
| `_flow_ai_update_stats` | Update aggregated usage statistics |
| `_flow_ai_get_stats` | Retrieve raw statistics JSON data |
| `flow_ai_stats` | Display formatted usage statistics dashboard |
| `flow_ai_suggest` | Provide personalized AI command suggestions |
| `flow_ai_recent` | Display recent AI command usage history |
| `flow_ai_clear_history` | Delete all AI usage tracking data |
| `flow_ai_usage` | Main entry point for usage tracking commands |
| `_flow_ai_usage_help` | Display help for usage tracking system |

---

## Parallel Rendering

### Render Queue Management

**File:** `lib/render-queue.zsh` | **Functions:** 11

| Function | Purpose |
|----------|---------|
| `_estimate_render_time` | Estimate render time based on history and heuristics |
| `_record_render_time` | Record actual render time to history cache |
| `_optimize_render_queue` | Optimize queue ordering for parallelism |
| `_create_job_queue` | Create job queue file with optimized ordering |
| `_fetch_job_atomic` | Atomically fetch next job (thread-safe) |
| `_record_job_result` | Atomically record job result (thread-safe) |
| `_calculate_optimal_workers` | Calculate optimal worker count based on system |
| `_categorize_files_by_time` | Categorize files into fast/medium/slow |
| `_estimate_total_time` | Estimate total serial execution time |
| `_estimate_parallel_time` | Estimate parallel execution time |
| `_calculate_speedup` | Calculate speedup factor from timings |

### Parallel Execution Helpers

**File:** `lib/parallel-helpers.zsh` | **Functions:** 10

| Function | Purpose |
|----------|---------|
| `_detect_cpu_cores` | Detect CPU cores (cross-platform) |
| `_create_worker_pool` | Create worker pool for parallel rendering |
| `_worker_process` | Worker process main loop |
| `_distribute_jobs` | Distribute jobs to queue |
| `_wait_for_workers` | Wait for workers with timeout |
| `_aggregate_results` | Aggregate results to JSON |
| `_cleanup_workers` | Clean up worker pool and temp files |
| `_parallel_render` | Main orchestrator for parallel rendering |
| `_monitor_progress` | Monitor real-time progress |
| `_display_results` | Display final results |

### Progress Display

**File:** `lib/parallel-progress.zsh` | **Functions:** 9

| Function | Purpose |
|----------|---------|
| `_init_progress_bar` | Initialize progress bar state |
| `_update_progress` | Update progress bar display |
| `_calculate_eta` | Calculate estimated time remaining |
| `_format_duration` | Format duration as human-readable string |
| `_show_worker_status` | Show worker status |
| `_format_stats` | Format final statistics |
| `_display_file_results` | Display per-file results |
| `_display_error_details` | Display error details for failures |
| `_show_compact_progress` | Show compact one-line progress |

---

## Date Parsing & Management

**File:** `lib/date-parser.zsh` | **Functions:** 10

| Function | Purpose |
|----------|---------|
| `_date_parse_quarto_yaml` | Extract and normalize date from Quarto YAML frontmatter |
| `_date_parse_markdown_inline` | Find and extract all inline dates from markdown |
| `_date_extract_from_line` | Extract the first date from a single line of text |
| `_date_normalize` | Convert any supported date format to ISO-8601 |
| `_date_compute_from_week` | Calculate date from semester week number |
| `_date_add_days` | Add or subtract days from a date (cross-platform) |
| `_date_find_teaching_files` | Find teaching-related files with date references |
| `_date_load_config` | Load all dates from teach config into associative array |
| `_date_compare` | Compare dates from file against config reference |
| `_date_apply_to_file` | Apply date replacements to a file |

---

## Performance Monitoring

**File:** `lib/performance-monitor.zsh` | **Functions:** 10

| Function | Purpose |
|----------|---------|
| `_init_performance_log` | Initialize performance log file with proper schema |
| `_rotate_performance_log` | Rotate performance log when it exceeds size limits |
| `_record_performance` | Record a performance entry with metrics |
| `_read_performance_log` | Read performance log entries within time window |
| `_calculate_moving_average` | Calculate moving average of a metric |
| `_get_latest_metric` | Get most recent value for a specific metric |
| `_identify_slow_files` | Identify slowest files based on render time |
| `_calculate_trend` | Calculate trend direction and percentage change |
| `_generate_ascii_graph` | Generate ASCII bar graph for a value |
| `_format_performance_dashboard` | Display formatted performance metrics dashboard |

---

## R Package Management

**File:** `lib/r-helpers.zsh` | **Functions:** 9

| Function | Purpose |
|----------|---------|
| `_detect_r_packages` | Extract R package names from teaching.yml |
| `_detect_r_packages_from_description` | Extract R dependencies from DESCRIPTION file |
| `_list_r_packages_from_sources` | Aggregate packages from all config sources |
| `_check_r_package_installed` | Verify if a package is installed in R |
| `_get_r_package_version` | Retrieve installed version of a package |
| `_check_missing_r_packages` | Identify which packages are not installed |
| `_install_r_packages` | Install specified R packages from CRAN |
| `_install_missing_r_packages` | Auto-detect and install missing packages |
| `_show_r_package_status` | Display formatted R package status report |

---

## Quarto Profile Management

**File:** `lib/profile-helpers.zsh` | **Functions:** 9

| Function | Purpose |
|----------|---------|
| `_detect_quarto_profiles` | Parse _quarto.yml for profile definitions |
| `_get_profile_description` | Retrieve description/title for a profile |
| `_get_profile_config` | Get complete YAML configuration for a profile |
| `_list_profiles` | Display all profiles with descriptions and status |
| `_get_current_profile` | Determine the currently active profile |
| `_switch_profile` | Switch to a different Quarto profile |
| `_validate_profile` | Verify a profile exists in _quarto.yml |
| `_create_profile` | Create new profile from template |
| `_show_profile_info` | Display detailed info about a profile |

---

## renv Integration

**File:** `lib/renv-integration.zsh` | **Functions:** 8

| Function | Purpose |
|----------|---------|
| `_read_renv_lock` | Read and parse renv.lock JSON structure |
| `_get_renv_packages` | Extract list of package names from renv.lock |
| `_get_renv_package_info` | Retrieve detailed JSON metadata for a package |
| `_get_renv_package_version` | Extract version string for a package from renv.lock |
| `_get_renv_package_source` | Extract installation source for a package |
| `_check_renv_sync` | Verify installed packages match renv.lock versions |
| `_renv_restore` | Restore R packages from renv.lock |
| `_show_renv_status` | Display comprehensive renv package status |

---

## Custom Validators

**File:** `lib/custom-validators.zsh` | **Functions:** 8

| Function | Purpose |
|----------|---------|
| `_discover_validators` | Find all custom validator scripts in .teach/validators/ |
| `_get_validator_name_from_path` | Extract clean validator name from script path |
| `_validate_validator_api` | Check if validator implements required plugin API |
| `_load_validator_metadata` | Extract metadata from validator without running |
| `_execute_validator` | Run a single validator script on a file |
| `_aggregate_validator_results` | Collect and summarize validation results |
| `_run_custom_validators` | Main orchestrator to run validators on files |
| `_list_custom_validators` | Display all available validators with metadata |

---

## Configuration Management

**File:** `lib/config-validator.zsh` | **Functions:** 8

| Function | Purpose |
|----------|---------|
| `_flow_config_hash` | Compute SHA-256 hash of config for change detection |
| `_flow_config_changed` | Check if config has changed using hash comparison |
| `_flow_config_invalidate` | Force invalidation of config hash cache |
| `_teach_validate_config` | Validate teach-config.yml against schema |
| `_teach_config_get` | Get configuration value with optional default |
| `_teach_has_scholar_config` | Check if scholar section exists in config |
| `_teach_find_config` | Find teach-config.yml by searching up directory tree |
| `_teach_config_summary` | Display formatted summary of teaching config |

---

## Git Hook Management

**File:** `lib/hook-installer.zsh` | **Functions:** 8

| Function | Purpose |
|----------|---------|
| `_get_installed_hook_version` | Extract version string from installed git hook |
| `_compare_versions` | Compare two semantic version strings |
| `_check_hook_version` | Check if a git hook needs upgrade |
| `_install_single_hook` | Install a single git hook from template |
| `_install_git_hooks` | Install all configured git hooks |
| `_upgrade_git_hooks` | Interactively upgrade outdated hooks |
| `_uninstall_git_hooks` | Remove all flow-cli managed hooks |
| `_check_all_hooks` | Display status of all hooks with version info |

---

## Cache Analysis

**File:** `lib/cache-analysis.zsh` | **Functions:** 6

| Function | Purpose |
|----------|---------|
| `_analyze_cache_size` | Analyze total cache size and file count |
| `_analyze_cache_by_directory` | Break down cache size by subdirectory |
| `_analyze_cache_by_age` | Break down cache by file age |
| `_calculate_cache_hit_rate` | Calculate cache hit rate from performance log |
| `_generate_cache_recommendations` | Generate actionable optimization recommendations |
| `_format_cache_report` | Generate formatted cache analysis report |

---

## Status Dashboard

**File:** `lib/status-dashboard.zsh` | **Functions:** 3

| Function | Purpose |
|----------|---------|
| `_status_time_ago` | Format Unix timestamp as human-readable relative time |
| `_status_box_line` | Format a single line for boxed dashboard display |
| `_teach_show_status_dashboard` | Display comprehensive teaching project status |

---

## Project Inventory

**File:** `lib/inventory.zsh` | **Functions:** 2

| Function | Purpose |
|----------|---------|
| `_flow_generate_inventory` | Generate project inventory from .STATUS files |
| `_flow_generate_inventory_json` | Generate project inventory in JSON format |

---

## Help System

**File:** `lib/help-browser.zsh` | **Functions:** 2

| Function | Purpose |
|----------|---------|
| `_flow_show_help_preview` | Generate help preview for fzf preview window |
| `_flow_help_browser` | Interactive help browser using fzf |

---

## Summary Statistics

| Category | File | Functions |
|----------|------|-----------|
| Dotfile Management | `dotfile-helpers.zsh` | 27 |
| AI Recipes | `ai-recipes.zsh` | 11 |
| AI Usage | `ai-usage.zsh` | 9 |
| Render Queue | `render-queue.zsh` | 11 |
| Parallel Helpers | `parallel-helpers.zsh` | 10 |
| Parallel Progress | `parallel-progress.zsh` | 9 |
| Date Parser | `date-parser.zsh` | 10 |
| Performance Monitor | `performance-monitor.zsh` | 10 |
| R Helpers | `r-helpers.zsh` | 9 |
| Profile Helpers | `profile-helpers.zsh` | 9 |
| renv Integration | `renv-integration.zsh` | 8 |
| Custom Validators | `custom-validators.zsh` | 8 |
| Config Validator | `config-validator.zsh` | 8 |
| Hook Installer | `hook-installer.zsh` | 8 |
| Cache Analysis | `cache-analysis.zsh` | 6 |
| Status Dashboard | `status-dashboard.zsh` | 3 |
| Inventory | `inventory.zsh` | 2 |
| Help Browser | `help-browser.zsh` | 2 |
| **Total** | **18 files** | **160** |

---

## See Also

- [Core API Reference](CORE-API-REFERENCE.md) - Core library functions
- [Teaching API Reference](TEACHING-API-REFERENCE.md) - Teaching workflow functions
- [Integration API Reference](INTEGRATION-API-REFERENCE.md) - Integration functions
- [Architecture Overview](ARCHITECTURE-OVERVIEW.md) - System architecture
