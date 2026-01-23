# lib/concept-extraction.zsh
# Concept extraction library for teach analyze command
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management


# Load guard - prevent double-sourcing
if [[ -n "$_FLOW_CONCEPT_EXTRACTION_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_CONCEPT_EXTRACTION_LOADED=1

# Source core library for colors and logging
source "${0:A:h}/core.zsh"

# Extract concepts field from .qmd frontmatter using yq
# Usage: _extract_concepts_from_frontmatter <file_path>
# Returns: JSON string of concepts section, or empty string on error
_extract_concepts_from_frontmatter() {
    local file="$1"
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        _flow_log_error "File not found: $file"
        echo ""
        return 1
    fi
    
    # Extract YAML frontmatter (between --- delimiters)
    local frontmatter
    frontmatter=$(awk '/^---$/{p++;next} p==1{print}' "$file")
    
    # Check if frontmatter exists
    if [[ -z "$frontmatter" ]]; then
        _flow_log_debug "No frontmatter found in: $file"
        echo ""
        return 0
    fi
    
    # Extract concepts field using yq
    local concepts_json
    if command -v yq &>/dev/null; then
        concepts_json=$(echo "$frontmatter" | yq eval -o json '.concepts // ""' - 2>/dev/null)
        # Return empty if concepts is null, empty string, empty array, or array with only empty strings
        local trimmed
        trimmed=$(echo "$concepts_json" | tr -d '\n' | xargs)
        # Check if trimmed result is empty, "[]", or "[""]"
        if [[ -z "$trimmed" || "$trimmed" == "[]" || "$trimmed" == "[\"\"]" ]]; then
            echo -n ""
        else
            echo -n "$trimmed"
        fi
    else
        _flow_log_error "yq not found. Run: teach doctor --fix"
        echo ""
        return 1
    fi
}

# Parse introduced concepts from concepts array
# Usage: _parse_introduced_concepts <concepts_json>
# Returns: Array of concept names (space-separated)
_parse_introduced_concepts() {
    local concepts_json="$1"
    
    if [[ -z "$concepts_json" || "$concepts_json" == "null" ]]; then
        echo ""
        return 0
    fi
    
    # Use yq to extract introduces array, strip quotes, and trim whitespace
    local introduced
    introduced=$(echo "$concepts_json" | yq eval -o json '.introduces // [] | .[]' - 2>/dev/null | sed 's/"//g' | tr '\n' ' ' | xargs)
    
    echo "$introduced"
}

# Parse required concepts (prerequisites) from concepts array
# Usage: _parse_required_concepts <concepts_json>
# Returns: Array of prerequisite concept names (space-separated)
_parse_required_concepts() {
    local concepts_json="$1"
    
    if [[ -z "$concepts_json" || "$concepts_json" == "null" ]]; then
        echo ""
        return 0
    fi
    
    # Use yq to extract requires array, strip quotes, and trim whitespace
    local required
    required=$(echo "$concepts_json" | yq eval -o json '.requires // [] | .[]' - 2>/dev/null | sed 's/"//g' | tr '\n' ' ' | xargs)
    
    echo "$required"
}

# Extract week number from filename or frontmatter
# Usage: _get_week_from_file <file_path> [frontmatter_json]
# Returns: Week number as integer, or 0 if not found
_get_week_from_file() {
    local file="$1"
    local frontmatter_json="$2"
    
    # Try extracting from filename first (week-05-lecture.qmd -> 5)
    local filename
    filename=$(basename "$file" .qmd)
    
    local week_from_filename
    if [[ "$filename" =~ week-([0-9]+) ]]; then
        week_from_filename="${match[1]}"
        # Remove leading zeros
        week_from_filename=$((10#$week_from_filename))
        echo "$week_from_filename"
        return 0
    fi
    
    # Fallback: try frontmatter week field if provided
    if [[ -n "$frontmatter_json" && "$frontmatter_json" != "null" ]]; then
        local week_from_fm
        week_from_fm=$(echo "$frontmatter_json" | yq eval -o json '.week // 0' - 2>/dev/null)
        if [[ "$week_from_fm" -gt 0 ]]; then
            echo "$week_from_fm"
            return 0
        fi
    fi
    
    # Not found - try extracting week from file's frontmatter directly
    if command -v yq >/dev/null 2>&1; then
        local frontmatter
        frontmatter=$(awk '/^---$/{p++;next} p==1{print}' "$file")
        if [[ -n "$frontmatter" ]]; then
            local week_direct
            week_direct=$(echo "$frontmatter" | yq eval -o json '.week // 0' - 2>/dev/null)
            if [[ "$week_direct" -gt 0 ]]; then
                echo "$week_direct"
                return 0
            fi
        fi
    fi
    
    # Not found
    echo "0"
    return 1
}

# Find line number where concept is defined in file
# Usage: _get_concept_line_number <file_path> <concept_name>
# Returns: Line number (1-based), or 0 if not found
_get_concept_line_number() {
    local file="$1"
    local concept_name="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi
    
    # Search for concept definition in frontmatter
    local line_num
    line_num=$(grep -n -E "(-[[:space:]]*|[\"']?)"${concept_name}"([\"']?[[:space:]]*[,\\]])" "$file" 2>/dev/null | head -1 | cut -d: -f1)
    
    if [[ -n "$line_num" ]]; then
        echo "$line_num"
    else
        echo "0"
    fi
}

# Build concept graph by scanning all .qmd files
# Usage: _build_concept_graph [course_directory]
# Returns: JSON string of complete concept graph
_build_concept_graph() {
    local course_dir="${1:-$PWD}"
    local teach_dir="$course_dir/.teach"
    local lectures_dir="$course_dir/lectures"

    # Check if lectures directory exists
    if [[ ! -d "$lectures_dir" ]]; then
        # Return temp file with basic graph (use $$ for unique filenames)
        local results_file="/tmp/concepts-graph-$$-${RANDOM}.json"
        jq -n '{version: "1.0", schema_version: "concept-graph-v1", metadata: {last_updated: "", course_hash: "", total_concepts: 0, weeks: 0, extraction_method: "frontmatter"}, concepts: {}}' > "$results_file"
        echo "$results_file"
        return 1
    fi

    # Create a temporary script to build the graph in a clean environment
    # NOTE: We use global variables (no 'local') because LOCAL_OPTIONS is enabled
    # in the user's shell and cannot be disabled. This prevents debug output
    # from variable assignments.
    local temp_script="/tmp/build-graph-$$-${RANDOM}.zsh"

    # Build the script content using globals to avoid LOCAL_OPTIONS printing
    cat > "$temp_script" << 'SCRIPT'
#!/usr/bin/env zsh
# Build concept graph in isolated environment
# Uses global variables to avoid LOCAL_OPTIONS debug output

# Find course directory from script argument
course_dir="$1"
lectures_dir="$course_dir/lectures"

# Initialize empty graph using jq (using assignment without 'local')
graph=$(jq -n '{version: "1.0", schema_version: "concept-graph-v1", metadata: {last_updated: "", course_hash: "", total_concepts: 0, weeks: 0, extraction_method: "frontmatter"}, concepts: {}}')
total_concepts=0
max_week=0

# Function to extract concepts from frontmatter
_extract_concepts_from_frontmatter() {
    file="$1"
    frontmatter=$(awk '/^---$/{p++;next} p==1{print}' "$file")
    if [[ -z "$frontmatter" ]]; then
        echo ""
        return 0
    fi
    concepts_json=$(echo "$frontmatter" | yq eval -o json '.concepts // ""' - 2>/dev/null)
    trimmed=$(echo "$concepts_json" | tr -d '\n' | xargs)
    if [[ -z "$trimmed" || "$trimmed" == "[]" || "$trimmed" == "[\"\"]" ]]; then
        echo -n ""
    else
        echo -n "$trimmed"
    fi
}

# Function to parse introduced concepts
_parse_introduced_concepts() {
    concepts_json="$1"
    if [[ -z "$concepts_json" || "$concepts_json" == "null" ]]; then
        echo ""
        return 0
    fi
    introduced=$(echo "$concepts_json" | yq eval -o json '.introduces // [] | .[]' - 2>/dev/null | sed 's/"//g' | tr '\n' ' ' | xargs)
    echo "$introduced"
}

# Function to parse required concepts
_parse_required_concepts() {
    concepts_json="$1"
    if [[ -z "$concepts_json" || "$concepts_json" == "null" ]]; then
        echo ""
        return 0
    fi
    required=$(echo "$concepts_json" | yq eval -o json '.requires // [] | .[]' - 2>/dev/null | sed 's/"//g' | tr '\n' ' ' | xargs)
    echo "$required"
}

# Function to get week from file
_get_week_from_file() {
    file="$1"
    concepts_json="$2"
    
    filename=$(basename "$file" .qmd)
    
    if [[ "$filename" =~ week-([0-9]+) ]]; then
        week_from_filename="${match[1]}"
        week_from_filename=$((10#$week_from_filename))
        echo "$week_from_filename"
        return 0
    fi
    
    if [[ -n "$concepts_json" && "$concepts_json" != "null" ]]; then
        week_from_fm=$(echo "$concepts_json" | yq eval -o json '.week // 0' - 2>/dev/null)
        if [[ "$week_from_fm" -gt 0 ]]; then
            echo "$week_from_fm"
            return 0
        fi
    fi
    
    if command -v yq >/dev/null 2>&1; then
        frontmatter=$(awk '/^---$/{p++;next} p==1{print}' "$file")
        if [[ -n "$frontmatter" ]]; then
            week_direct=$(echo "$frontmatter" | yq eval -o json '.week // 0' - 2>/dev/null)
            if [[ "$week_direct" -gt 0 ]]; then
                echo "$week_direct"
                return 0
            fi
        fi
    fi
    
    echo "0"
    return 1
}

# Function to get concept line number
_get_concept_line_number() {
    file="$1"
    concept_name="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi
    
    line_num=$(grep -n -E "(-[[:space:]]*|[\"']?)"${concept_name}"([\"']?[[:space:]]*[,\\]])" "$file" 2>/dev/null | head -1 | cut -d: -f1)
    
    if [[ -n "$line_num" ]]; then
        echo "$line_num"
    else
        echo "0"
    fi
}

# Scan all .qmd files
qmd_files=($(find "$lectures_dir" -name "*.qmd" -type f 2>/dev/null | sort))

for file in "${qmd_files[@]}"; do
    concepts_json=$(_extract_concepts_from_frontmatter "$file")
    
    if [[ -z "$concepts_json" || "$concepts_json" == "null" ]]; then
        continue
    fi
    
    introduced=$(_parse_introduced_concepts "$concepts_json")
    required=$(_parse_required_concepts "$concepts_json")
    
    week=$(_get_week_from_file "$file" "$concepts_json")
    if [[ "$week" -gt "$max_week" ]]; then
        max_week=$week
    fi
    
    rel_path="${file#$course_dir/}"

    # Use ${=var} to enable word splitting in ZSH
    for concept in ${=introduced}; do
        [[ -z "$concept" ]] && continue

        existing=$(echo "$graph" | jq -r --arg cid "$concept" '.concepts[$cid] // "null"' 2>/dev/null)

        if [[ -z "$existing" || "$existing" == "null" ]]; then
            line_num=$(_get_concept_line_number "$file" "$concept")

            concept_name="${(C)concept}"

            graph=$(echo "$graph" | jq \
                --arg cid "$concept" \
                --arg name "$concept_name" \
                --argjson w "$week" \
                --arg lec "$rel_path" \
                --argjson ln "$line_num" \
                '.concepts[$cid] = {id: $cid, name: $name, prerequisites: [], introduced_in: {week: $w, lecture: $lec, line_number: $ln}}' 2>/dev/null)

            ((total_concepts++))
        fi
    done

    # Use ${=var} to enable word splitting in ZSH
    for prereq in ${=required}; do
        [[ -z "$prereq" ]] && continue

        for introduced_concept in ${=introduced}; do
            [[ -z "$introduced_concept" ]] && continue

            graph=$(echo "$graph" | jq --arg cid "$introduced_concept" --arg prereq "$prereq" '.concepts[$cid].prerequisites += [$prereq]' 2>/dev/null)
        done
    done
done

# Update metadata
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
course_hash=$(find "$course_dir" -name "*.qmd" -type f -exec shasum {} \; 2>/dev/null | shasum | cut -d' ' -f1)

graph=$(echo "$graph" | jq \
    --arg ts "$timestamp" \
    --arg hash "$course_hash" \
    --argjson count "$total_concepts" \
    --argjson weeks "$max_week" \
    '.metadata.last_updated = $ts | .metadata.course_hash = $hash | .metadata.total_concepts = $count | .metadata.weeks = $weeks' 2>/dev/null)

# Output clean JSON
echo "$graph"
SCRIPT

    # Execute the script and capture output
    local result
    result=$(zsh --no-rcs "$temp_script" "$course_dir" 2>/dev/null)
    local exit_code=$?
    
    # Clean up temp script
    rm -f "$temp_script"
    
    if [[ $exit_code -eq 0 && -n "$result" ]]; then
        # Save result to temp file and return file path (use $$ for unique filenames)
        local results_file="/tmp/concepts-graph-$$-${RANDOM}.json"
        echo "$result" > "$results_file"
        echo "$results_file"
    else
        # Fallback: create temp file with basic graph
        local results_file="/tmp/concepts-graph-$$-${RANDOM}.json"
        jq -n '{version: "1.0", schema_version: "concept-graph-v1", metadata: {last_updated: "", course_hash: "", total_concepts: 0, weeks: 0, extraction_method: "frontmatter"}, concepts: {}}' > "$results_file"
        echo "$results_file"
    fi
}

# Load existing concept graph from .teach/concepts.json
# Usage: _load_concept_graph [course_directory]
# Returns: JSON string of concept graph, or empty string if not found
_load_concept_graph() {
    local course_dir="${1:-$PWD}"
    local concepts_file="$course_dir/.teach/concepts.json"
    
    if [[ ! -f "$concepts_file" ]]; then
        _flow_log_debug "Concept graph not found: $concepts_file"
        echo ""
        return 1
    fi
    
    # Validate JSON
    if ! jq empty "$concepts_file" 2>/dev/null; then
        _flow_log_error "Invalid JSON in concept graph: $concepts_file"
        echo ""
        return 1
    fi
    
    cat "$concepts_file"
}

# Save concept graph to .teach/concepts.json with atomic write
# Usage: _save_concept_graph <graph_json> [course_directory]
# Returns: 0 on success, 1 on error
_save_concept_graph() {
    local graph_json="$1"
    local course_dir="${2:-$PWD}"
    local teach_dir="$course_dir/.teach"
    local concepts_file="$teach_dir/concepts.json"
    local temp_file="$concepts_file.tmp.$$"
    
    # Create .teach directory if it doesn't exist
    if [[ ! -d "$teach_dir" ]]; then
        mkdir -p "$teach_dir" 2>/dev/null || {
            _flow_log_error "Failed to create .teach directory: $teach_dir"
            return 1
        }
    fi
    
    # Validate JSON before writing
    if ! echo "$graph_json" | jq empty 2>/dev/null; then
        _flow_log_error "Invalid JSON provided to save_concept_graph"
        return 1
    fi
    
    # Write to temporary file
    if ! echo "$graph_json" > "$temp_file" 2>/dev/null; then
        _flow_log_error "Failed to write temporary file: $temp_file"
        return 1
    fi
    
    # Atomic move
    if ! mv "$temp_file" "$concepts_file" 2>/dev/null; then
        _flow_log_error "Failed to move temporary file to: $concepts_file"
        rm -f "$temp_file"
        return 1
    fi
    
    _flow_log_success "Concept graph saved to: $concepts_file"
    return 0
}
