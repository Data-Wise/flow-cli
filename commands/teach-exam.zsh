# commands/teach-exam.zsh - Teaching exam creation
# Creates exam templates for Canvas integration via examark

# ============================================================================
# TEACH-EXAM COMMAND
# ============================================================================

teach-exam() {
  local topic="$1"

  if [[ -z "$topic" ]]; then
    _flow_log_error "Usage: teach-exam <topic>"
    echo ""
    echo "Examples:"
    echo "  teach-exam \"Midterm 1: Weeks 1-8\""
    echo "  teach-exam \"Final Exam\""
    echo "  teach-exam \"Quiz 3: ANOVA\""
    return 1
  fi

  # Detect teaching project
  local project_type=$(_flow_detect_project_type .)
  if [[ "$project_type" != "teaching" ]]; then
    _flow_log_error "Not in a teaching project"
    echo "Run this command from a teaching project directory"
    echo "Initialize with: teach-init \"Course Name\""
    return 1
  fi

  # Load config
  local config_file=".flow/teach-config.yml"
  if [[ ! -f "$config_file" ]]; then
    _flow_log_error "Teaching config not found: $config_file"
    echo "Initialize teaching workflow with: teach-init \"Course Name\""
    return 1
  fi

  # Check yq availability
  if ! command -v yq &>/dev/null; then
    _flow_log_error "yq is required"
    echo "Install: brew install yq"
    return 1
  fi

  echo "📝 Creating exam: $topic"
  echo ""

  # Check examark config
  local examark_enabled=$(yq -r '.examark.enabled // false' "$config_file" 2>/dev/null)
  if [[ "$examark_enabled" != "true" ]]; then
    echo "${FLOW_COLORS[warning]}⚠️  examark not enabled in config${FLOW_COLORS[reset]}"
    echo ""
    echo "To enable exam workflow:"
    echo "  1. Install examark: ${FLOW_COLORS[cmd]}npm install -g examark${FLOW_COLORS[reset]}"
    echo "  2. Enable in config: ${FLOW_COLORS[cmd]}yq -i '.examark.enabled = true' $config_file${FLOW_COLORS[reset]}"
    echo ""
    read "continue?Continue anyway? [y/N] "
    if [[ "$continue" != "y" ]]; then
      echo "Cancelled"
      return 1
    fi
    echo ""
  fi

  # Get exam directory (with default)
  local exam_dir=$(yq -r '.examark.exam_dir // "exams"' "$config_file" 2>/dev/null)
  mkdir -p "$exam_dir"

  # Get defaults
  local default_duration=$(yq -r '.examark.default_duration // "120"' "$config_file" 2>/dev/null)
  local default_points=$(yq -r '.examark.default_points // "100"' "$config_file" 2>/dev/null)

  # Prompt for exam details
  echo "${FLOW_COLORS[bold]}Exam Details${FLOW_COLORS[reset]}"
  echo ""

  read "duration?  Duration (minutes) [$default_duration]: "
  duration="${duration:-$default_duration}"

  read "points?  Total points [$default_points]: "
  points="${points:-$default_points}"

  # Generate default filename from topic
  local default_filename=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

  read "filename?  Filename (without .md) [$default_filename]: "
  filename="${filename:-$default_filename}"

  local exam_file="$exam_dir/$filename.md"

  # Check if file exists
  if [[ -f "$exam_file" ]]; then
    _flow_log_warning "File already exists: $exam_file"
    read "overwrite?Overwrite? [y/N] "
    if [[ "$overwrite" != "y" ]]; then
      echo "Cancelled"
      return 1
    fi
  fi

  # Create exam from template
  _teach_create_exam_template "$exam_file" "$topic" "$duration" "$points"

  echo ""
  echo "✅ Exam template created: ${FLOW_COLORS[cmd]}$exam_file${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}Next steps:${FLOW_COLORS[reset]}"
  echo ""
  echo "  1. Edit exam:"
  echo "     ${FLOW_COLORS[cmd]}\$EDITOR $exam_file${FLOW_COLORS[reset]}"
  echo ""
  echo "  2. Convert to Canvas QTI:"
  echo "     ${FLOW_COLORS[cmd]}./scripts/exam-to-qti.sh $exam_file${FLOW_COLORS[reset]}"
  echo ""
  echo "  3. Upload to Canvas:"
  echo "     Quizzes → Import → QTI 1.2 format"
  echo ""
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

_teach_create_exam_template() {
  local exam_file="$1"
  local topic="$2"
  local duration="$3"
  local points="$4"

  # Get course name for header
  local config_file=".flow/teach-config.yml"
  local course_name=$(yq -r '.course.name // "Course"' "$config_file" 2>/dev/null)

  # Get template directory
  local template_dir="${FLOW_PLUGIN_DIR}/lib/templates/teaching"
  local template_file="$template_dir/exam-template.md"

  if [[ -f "$template_file" ]]; then
    # Use template and substitute variables
    cat "$template_file" | \
      sed "s/{{TOPIC}}/$topic/g" | \
      sed "s/{{DURATION}}/$duration/g" | \
      sed "s/{{POINTS}}/$points/g" | \
      sed "s/{{COURSE_NAME}}/$course_name/g" \
      > "$exam_file"
  else
    # Fallback: create basic template inline
    cat > "$exam_file" <<EOF
---
title: $topic
course: $course_name
duration: $duration minutes
points: $points
---

# $topic

**Name:** _______________________________

**Duration:** $duration minutes
**Total Points:** $points

---

## Instructions

- You have $duration minutes to complete this exam
- Exam is worth $points points total
- Show all work for partial credit
- Read each question carefully

---

## Section 1: Multiple Choice (30 points)

1. [3 pts] Question text here?
   - [ ] Option A
   - [ ] Option B
   - [x] Option C (correct answer)
   - [ ] Option D

---

## Section 2: Short Answer (40 points)

1. [10 pts] Question text here?

   **Answer:**
   <!-- Student writes answer here -->

---

## Section 3: Problems (30 points)

1. [15 pts] Problem description here?

   **Solution:**
   <!-- Student shows work here -->

---

## Answer Key (instructor only)

### Section 1
1. C

### Section 2
1. [Expected answer with key points]

### Section 3
1. [Expected solution with rubric]
   - Part a (5 pts): ...
   - Part b (5 pts): ...
   - Part c (5 pts): ...
EOF
  fi
}
