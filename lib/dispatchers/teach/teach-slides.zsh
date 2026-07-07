# teach-slides.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_slides_from_lecture() {
    local from_lecture="$1"
    local week_num="$2"
    shift 2
    local -a extra_args=("$@")
    local config_file=".flow/teach-config.yml"
    local -a lecture_files=()
    local verbose=false
    local dry_run=false
    local output_dir="slides"

    # Parse extra args for verbose and dry-run
    for arg in "${extra_args[@]}"; do
        [[ "$arg" == "--verbose" || "$arg" == "-v" ]] && verbose=true
        [[ "$arg" == "--dry-run" ]] && dry_run=true
    done

    # ─────────────────────────────────────────────────────────────────────
    # Step 1: Determine lecture files to convert
    # ─────────────────────────────────────────────────────────────────────

    if [[ -n "$from_lecture" ]]; then
        # Explicit file provided
        if [[ -f "$from_lecture" ]]; then
            lecture_files+=("$from_lecture")
        else
            _teach_error "Lecture file not found: $from_lecture"
            return 1
        fi
    elif [[ -n "$week_num" ]]; then
        # Week number provided - look up files from teach-config.yml
        if [[ ! -f "$config_file" ]]; then
            _teach_error "No teach-config.yml found" "Run 'teach init' first"
            return 1
        fi

        if ! command -v yq &>/dev/null; then
            _teach_error "yq required for config parsing" "Install: brew install yq"
            return 1
        fi

        # Check if week has parts structure
        local has_parts
        has_parts=$(yq ".semester_info.weeks[] | select(.number == $week_num) | .parts // null" "$config_file" 2>/dev/null)

        if [[ "$has_parts" != "null" && -n "$has_parts" ]]; then
            # Multi-part week - get all part files
            local -a part_files
            part_files=($(yq ".semester_info.weeks[] | select(.number == $week_num) | .parts[].file" "$config_file" 2>/dev/null))
            for pf in "${part_files[@]}"; do
                if [[ -f "$pf" ]]; then
                    lecture_files+=("$pf")
                else
                    _teach_warn "Part file not found: $pf"
                fi
            done
        else
            # Single lecture week - try to find lecture file
            local lecture_pattern="lectures/week-$(printf '%02d' $week_num)*.qmd"
            for f in $~lecture_pattern; do
                [[ -f "$f" ]] && lecture_files+=("$f")
            done
        fi

        if [[ ${#lecture_files[@]} -eq 0 ]]; then
            _teach_error "No lecture files found for week $week_num"
            return 1
        fi
    else
        _teach_error "Specify --from-lecture FILE or --week N"
        return 1
    fi

    [[ "$verbose" == "true" ]] && echo "📄 Found ${#lecture_files[@]} lecture file(s) to convert"

    # ─────────────────────────────────────────────────────────────────────
    # Step 2: Process each lecture file
    # ─────────────────────────────────────────────────────────────────────

    local -a generated_files=()

    for lecture_file in "${lecture_files[@]}"; do
        [[ "$verbose" == "true" ]] && echo "📖 Processing: $lecture_file"

        # Generate output filename
        local basename="${lecture_file:t:r}"  # Remove path and extension
        local output_file="${output_dir}/${basename}_slides.qmd"

        # Create output directory if needed
        [[ ! -d "$output_dir" ]] && mkdir -p "$output_dir"

        if [[ "$dry_run" == "true" ]]; then
            echo ""
            echo "📋 Dry-run: Would generate slides from $lecture_file"
            echo "   Output: $output_file"
            _teach_lecture_to_slides_preview "$lecture_file"
        else
            # Generate the slides
            _teach_convert_lecture_to_slides "$lecture_file" "$output_file" "$verbose"
            local exit_code=$?

            if [[ $exit_code -eq 0 ]]; then
                generated_files+=("$output_file")
                echo "✅ Generated: $output_file"
            else
                _teach_warn "Failed to convert: $lecture_file"
            fi
        fi
    done

    # ─────────────────────────────────────────────────────────────────────
    # Step 3: Summary
    # ─────────────────────────────────────────────────────────────────────

    if [[ "$dry_run" != "true" && ${#generated_files[@]} -gt 0 ]]; then
        echo ""
        echo "📊 Generated ${#generated_files[@]} slide file(s):"
        for f in "${generated_files[@]}"; do
            echo "   • $f"
        done
        echo ""
        echo "💡 Next steps:"
        echo "   1. Review and customize the generated slides"
        echo "   2. Run: quarto preview ${generated_files[1]}"
        echo "   3. Add to _quarto.yml navigation if needed"
    fi

    return 0
}

# ============================================================================
# SLIDES WITH OPTIMIZATION (Phase 4)
# Runs slide optimizer before generating slides
# ============================================================================

# Generate slides with AI-powered optimization
# Usage: _teach_slides_optimized <from_lecture> <week_num> <preview> <apply> <key_concepts> [args...]

_teach_slides_optimized() {
    local from_lecture="$1"
    local week_num="$2"
    local preview_breaks="$3"
    local apply_suggestions="$4"
    local key_concepts="$5"
    shift 5
    local -a extra_args=("$@")

    # Source slide optimizer if not already loaded
    if ! typeset -f _slide_optimize >/dev/null 2>&1; then
        source "${0:A:h:h}/slide-optimizer.zsh" 2>/dev/null || {
            _teach_error "Slide optimizer not available" "Ensure lib/slide-optimizer.zsh exists"
            return 1
        }
    fi

    # Resolve lecture files (same logic as _teach_slides_from_lecture)
    local config_file=".flow/teach-config.yml"
    local -a lecture_files=()

    if [[ -n "$from_lecture" && -f "$from_lecture" ]]; then
        lecture_files+=("$from_lecture")
    elif [[ -n "$week_num" ]]; then
        local lecture_pattern="lectures/week-$(printf '%02d' $week_num)*.qmd"
        for f in $~lecture_pattern; do
            [[ -f "$f" ]] && lecture_files+=("$f")
        done
    fi

    if [[ ${#lecture_files[@]} -eq 0 ]]; then
        _teach_error "No lecture files found" "Specify --from-lecture FILE or --week N"
        return 1
    fi

    echo "📐 Slide Optimization Mode"
    echo "═══════════════════════════════════════════════════"
    echo ""

    local -a generated_files=()

    for lecture_file in "${lecture_files[@]}"; do
        echo "📖 Optimizing: ${lecture_file:t}"

        # Step 1: Build concept graph if not available (auto-analyze)
        local concept_graph=""
        local course_dir="${lecture_file:h:h}"
        [[ "$course_dir" == "${lecture_file:t}" ]] && course_dir="."
        if [[ -f "$course_dir/.teach/concepts.json" ]]; then
            concept_graph=$(cat "$course_dir/.teach/concepts.json" 2>/dev/null)
        else
            # Auto-analyze: source and run _teach_analyze to build concept graph
            if ! typeset -f _teach_analyze >/dev/null 2>&1; then
                local analyze_cmd="${FLOW_PLUGIN_DIR:-${0:A:h:h}}/commands/teach-analyze.zsh"
                [[ -f "$analyze_cmd" ]] && source "$analyze_cmd"
            fi
            if typeset -f _teach_analyze >/dev/null 2>&1; then
                echo "  ℹ️  No concept graph found — running analysis first..."
                (cd "$course_dir" && _teach_analyze "$lecture_file" "--quiet") >/dev/null 2>&1
                [[ -f "$course_dir/.teach/concepts.json" ]] && \
                    concept_graph=$(cat "$course_dir/.teach/concepts.json" 2>/dev/null)
            fi
        fi

        local optimization
        optimization=$(_slide_optimize "$lecture_file" "$concept_graph" "false")

        if [[ -z "$optimization" || "$optimization" == "{}" ]]; then
            echo "  ⚠️  No optimization suggestions for this file"
            echo ""
            continue
        fi

        # Step 2: If preview mode, show preview and continue
        if [[ "$preview_breaks" == "true" ]]; then
            _slide_preview_breaks "$optimization"
            continue
        fi

        # Step 2b: If --key-concepts only, show concepts and continue
        if [[ "$key_concepts" == "true" && "$apply_suggestions" != "true" ]]; then
            echo ""
            echo "  🔑 Key Concepts for Callout Boxes:"
            echo "  ─────────────────────────────────────"
            if command -v jq &>/dev/null; then
                echo "$optimization" | jq -r '.key_concepts_for_emphasis[]? | "  • \(.name) (\(.source))"' 2>/dev/null
                local concept_count
                concept_count=$(echo "$optimization" | jq '.key_concepts_for_emphasis | length' 2>/dev/null || echo 0)
                echo ""
                echo "  ${concept_count} concept(s) identified"
            else
                echo "  (jq required for concept display)"
            fi
            echo ""
            # Also show timing estimate
            local est_time
            est_time=$(echo "$optimization" | jq '.time_estimate.total_minutes // 0' 2>/dev/null || echo 0)
            [[ "$est_time" -gt 0 ]] && echo "  ⏱️  Estimated presentation time: ${est_time} min"
            echo ""
            continue
        fi

        # Step 3: Generate optimized slides
        local output_dir="slides"
        local basename="${lecture_file:t:r}"
        local output_file="${output_dir}/${basename}_slides.qmd"
        [[ ! -d "$output_dir" ]] && mkdir -p "$output_dir"

        if [[ "$apply_suggestions" == "true" ]]; then
            # Apply break suggestions directly
            _slide_apply_breaks "$lecture_file" "$output_file" "$optimization"
            if [[ $? -eq 0 ]]; then
                generated_files+=("$output_file")
                echo "  ✅ Generated (optimized): $output_file"
            else
                _teach_warn "Failed to apply optimizations: $lecture_file"
            fi
        else
            # Generate slides normally, then show optimization suggestions
            _teach_convert_lecture_to_slides "$lecture_file" "$output_file" "false"
            if [[ $? -eq 0 ]]; then
                generated_files+=("$output_file")
                echo "  ✅ Generated: $output_file"

                # Show optimization summary
                local break_count=0
                if command -v jq &>/dev/null; then
                    break_count=$(echo "$optimization" | jq '.slide_breaks | length' 2>/dev/null || echo 0)
                fi
                echo "  💡 $break_count optimization suggestions available (use --apply-suggestions)"
            fi
        fi

        # Show key concepts if requested (alongside generation)
        if [[ "$key_concepts" == "true" && "$apply_suggestions" == "true" ]] && command -v jq &>/dev/null; then
            local concept_list
            concept_list=$(echo "$optimization" | jq -r '.key_concepts_for_emphasis[]? | .name' 2>/dev/null | paste -sd', ' -)
            [[ -n "$concept_list" ]] && echo "  🔑 Callout concepts: $concept_list"
        fi

        # Cache optimization results
        if [[ -d "$course_dir/.teach" ]]; then
            echo "$optimization" > "$course_dir/.teach/slide-optimization-${basename}.json" 2>/dev/null
        fi

        echo ""
    done

    # Summary
    if [[ ${#generated_files[@]} -gt 0 && "$preview_breaks" != "true" ]]; then
        echo "═══════════════════════════════════════════════════"
        echo "📊 Generated ${#generated_files[@]} optimized slide file(s)"
        echo ""
        echo "💡 Next steps:"
        echo "   1. Review slides: quarto preview ${generated_files[1]}"
        if [[ "$apply_suggestions" != "true" ]]; then
            echo "   2. Apply optimizations: teach slides --optimize --apply-suggestions --from-lecture ${lecture_files[1]}"
        fi
        echo "   3. Key concepts: teach slides --optimize --key-concepts --from-lecture ${lecture_files[1]}"
    elif [[ "$key_concepts" == "true" && "$preview_breaks" != "true" ]]; then
        echo "═══════════════════════════════════════════════════"
        echo "💡 To generate slides with these concepts as callouts:"
        echo "   teach slides --optimize --apply-suggestions --from-lecture ${lecture_files[1]}"
    fi

    return 0
}

# Preview what would be extracted from lecture file (dry-run)

_teach_lecture_to_slides_preview() {
    local lecture_file="$1"

    # Count sections, code chunks, callouts
    local h2_count h3_count code_chunks callouts

    h2_count=$(grep -c "^## " "$lecture_file" 2>/dev/null || echo 0)
    h3_count=$(grep -c "^### " "$lecture_file" 2>/dev/null || echo 0)
    code_chunks=$(grep -c '```{r' "$lecture_file" 2>/dev/null || echo 0)
    callouts=$(grep -c '::: {.callout' "$lecture_file" 2>/dev/null || echo 0)

    echo ""
    echo "   Content analysis:"
    echo "   ├── H2 sections (slides):    $h2_count"
    echo "   ├── H3 subsections:          $h3_count"
    echo "   ├── R code chunks:           $code_chunks"
    echo "   └── Callout boxes:           $callouts"
    echo ""
    echo "   Estimated slides: ~$((h2_count + h3_count / 2))"
}

# Convert a single lecture file to RevealJS slides
# Usage: _teach_convert_lecture_to_slides <input_file> <output_file> [verbose]

_teach_convert_lecture_to_slides() {
    local input_file="$1"
    local output_file="$2"
    local verbose="${3:-false}"

    # Extract YAML frontmatter using yq for proper parsing
    local title subtitle author date
    title=$(yq '.title // ""' "$input_file" 2>/dev/null)
    subtitle=$(yq '.subtitle // ""' "$input_file" 2>/dev/null)
    author=$(yq '.author // ""' "$input_file" 2>/dev/null)
    date=$(yq '.date // ""' "$input_file" 2>/dev/null)

    # Generate RevealJS YAML header
    {
        echo "---"
        echo "title: \"${title:-Lecture Slides}\""
        echo "subtitle: \"${subtitle:-}\""
        echo "author: \"${author:-}\""
        echo "date: \"${date:-}\""
        echo "format:"
        echo "  revealjs:"
        echo "    theme: [default, custom.scss]"
        echo "    slide-number: true"
        echo "    chalkboard: true"
        echo "    code-line-numbers: true"
        echo "    code-overflow: wrap"
        echo "    highlight-style: github"
        echo "    footer: \"${title:-}\""
        echo "execute:"
        echo "  echo: true"
        echo "  warning: false"
        echo "---"
        echo ""
    } > "$output_file"

    # Process the lecture content
    # Skip the YAML frontmatter and process the rest
    local in_frontmatter=false
    local frontmatter_count=0
    local in_code_block=false
    local in_callout=false
    local callout_depth=0
    local current_section=""
    local slide_count=0
    local line=""

    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Track frontmatter
        if [[ "$line" == "---" ]]; then
            ((frontmatter_count++))
            if [[ $frontmatter_count -le 2 ]]; then
                continue  # Skip YAML frontmatter
            fi
        fi

        # Skip until past frontmatter
        [[ $frontmatter_count -lt 2 ]] && continue

        # Track code blocks (don't modify content inside)
        if [[ "$line" =~ ^\`\`\` ]]; then
            in_code_block=$([[ "$in_code_block" == "true" ]] && echo "false" || echo "true")
        fi

        # Track callouts
        if [[ "$line" =~ '^:::' && "$line" =~ '\{\.callout' ]]; then
            in_callout=true
            ((callout_depth++))
        elif [[ "$line" == ":::" && "$in_callout" == "true" ]]; then
            ((callout_depth--))
            [[ $callout_depth -eq 0 ]] && in_callout=false
        fi

        # Convert H1 to slide title (level 1 becomes title slide)
        if [[ "$line" =~ ^#\  && ! "$line" =~ ^##\  ]]; then
            # H1 becomes a section title slide
            printf '\n' >> "$output_file"
            printf '%s {.center}\n' "$line" >> "$output_file"
            printf '\n' >> "$output_file"
            ((slide_count++))
            continue
        fi

        # H2 becomes new slide
        if [[ "$line" =~ ^##\  && ! "$line" =~ ^###\  ]]; then
            printf '\n' >> "$output_file"
            printf '%s\n' "$line" >> "$output_file"
            ((slide_count++))
            continue
        fi

        # H3 with content becomes slide with incremental reveal
        if [[ "$line" =~ ^###\  ]]; then
            printf '\n' >> "$output_file"
            printf '%s\n' "$line" >> "$output_file"
            continue
        fi

        # Convert TL;DR boxes to callout-note for slides
        if [[ "$line" =~ ':::.+\{\.tldr-box\}' ]]; then
            printf '::: {.callout-tip}\n' >> "$output_file"
            printf '## Key Points\n' >> "$output_file"
            continue
        fi

        # Convert checkpoint questions to interactive elements
        if [[ "$line" =~ "Checkpoint Question" ]]; then
            printf '\n' >> "$output_file"
            printf '::: {.callout-warning}\n' >> "$output_file"
            printf '## 🤔 Checkpoint\n' >> "$output_file"
            continue
        fi

        # Pass through code chunks (important for R examples)
        # Use printf '%s\n' to preserve LaTeX backslashes like \tau, \beta, \alpha
        if [[ "$in_code_block" == "true" ]] || [[ "$line" =~ ^\`\`\` ]]; then
            printf '%s\n' "$line" >> "$output_file"
            continue
        fi

        # Convert columns to slide-friendly format
        if [[ "$line" =~ ':::.+\{\.columns\}' ]]; then
            printf '\n' >> "$output_file"
            printf ':::: {.columns}\n' >> "$output_file"
            continue
        fi

        if [[ "$line" =~ ':::.+\{\.column' ]]; then
            printf '\n' >> "$output_file"
            printf '%s\n' "$line" >> "$output_file"
            continue
        fi

        # Pass through most content
        # IMPORTANT: Use printf '%s\n' instead of echo to preserve LaTeX backslashes
        # echo interprets escape sequences like \t (tab), \b (backspace), \v (vertical tab)
        # which corrupts LaTeX commands like \tau, \beta, \varepsilon, \underbrace, \alpha
        printf '%s\n' "$line" >> "$output_file"

    done < "$input_file"

    [[ "$verbose" == "true" ]] && echo "   Created $slide_count slides"

    return 0
}

# Archive semester backups (v5.14.0 - Task 5)

