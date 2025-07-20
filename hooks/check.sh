#!/usr/bin/env bash

# INPUT
# {
#   "session_id": "abc123",
#   "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
#   "cwd": "/Users/...",
#   "hook_event_name": "PostToolUse",
#   "tool_name": "Write",
#   "tool_input": {
#     "file_path": "/path/to/file.txt",
#     "content": "file content"
#   },
#   "tool_response": {
#     "filePath": "/path/to/file.txt",
#     "success": true
#   }
# }

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Parse file path from input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit if no file path found
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Exit if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Get file extension
EXTENSION="${FILE_PATH##*.}"
BASENAME=$(basename "$FILE_PATH")

# Function to format error output for Claude
format_error() {
    local tool="$1"
    local file="$2"
    local error_output="$3"

    cat <<EOF >&2
🔴 Linting Error in $file

Tool: $tool
File: $file

Error Output:
$error_output

Claude Instructions:
1. Read the file at: $file
2. Fix the formatting/linting issues reported above
3. Use the Edit or MultiEdit tool to apply the fixes
4. The errors above indicate what needs to be fixed

EOF
}

# Main linting logic based on file type
case "$EXTENSION" in
json)
    # For JSON files, use jq to format and validate
    if ! jq . "$FILE_PATH" >"${FILE_PATH}.tmp" 2>&1; then
        ERROR_OUTPUT=$(jq . "$FILE_PATH" 2>&1 || true)
        rm -f "${FILE_PATH}.tmp"
        format_error "jq (JSON formatter)" "$FILE_PATH" "$ERROR_OUTPUT"
        exit 2
    fi
    mv "${FILE_PATH}.tmp" "$FILE_PATH"
    echo "✓ Auto-formatted JSON: $BASENAME"
    ;;

tf | hcl)
    # For Terraform/HCL files, auto-format with terraform fmt
    if ! terraform fmt "$FILE_PATH" 2>&1; then
        ERROR_OUTPUT=$(terraform fmt "$FILE_PATH" 2>&1 || true)
        format_error "terraform fmt" "$FILE_PATH" "$ERROR_OUTPUT"
        exit 2
    fi
    echo "✓ Auto-formatted Terraform: $BASENAME"
    ;;

py)
    # For Python files, auto-format with ruff
    if ! ruff format "$FILE_PATH" 2>&1; then
        ERROR_OUTPUT=$(ruff format "$FILE_PATH" 2>&1 || true)
        format_error "ruff format" "$FILE_PATH" "$ERROR_OUTPUT"
        exit 2
    fi

    # Also auto-fix linting issues where possible
    if ! ruff check --fix "$FILE_PATH" 2>&1; then
        # Some issues can't be auto-fixed, show what remains
        LINT_OUTPUT=$(ruff check "$FILE_PATH" 2>&1 || true)
        if echo "$LINT_OUTPUT" | grep -q "error"; then
            format_error "ruff check (unfixable issues)" "$FILE_PATH" "$LINT_OUTPUT"
            exit 2
        fi
    fi
    echo "✓ Auto-formatted Python: $BASENAME"
    ;;

go)
    # For Go files, auto-format with goimports
    if ! goimports -w "$FILE_PATH" 2>&1; then
        ERROR_OUTPUT=$(goimports -w "$FILE_PATH" 2>&1 || true)
        format_error "goimports" "$FILE_PATH" "$ERROR_OUTPUT"
        exit 2
    fi
    echo "✓ Auto-formatted Go: $BASENAME"
    ;;

sh | bash)
    # For shell scripts, auto-format with shfmt
    if ! shfmt -w "$FILE_PATH" 2>&1; then
        ERROR_OUTPUT=$(shfmt -w "$FILE_PATH" 2>&1 || true)
        format_error "shfmt" "$FILE_PATH" "$ERROR_OUTPUT"
        exit 2
    fi

    # Check for shell script errors with shellcheck (no auto-fix available)
    if command -v shellcheck >/dev/null 2>&1; then
        if ! shellcheck "$FILE_PATH" >/dev/null 2>&1; then
            CHECK_OUTPUT=$(shellcheck "$FILE_PATH" 2>&1 || true)
            format_error "shellcheck (requires manual fixes)" "$FILE_PATH" "$CHECK_OUTPUT"
            exit 2
        fi
    fi
    echo "✓ Auto-formatted Shell: $BASENAME"
    ;;

*)
    # No linting for other file types
    exit 0
    ;;
esac

# If we get here, all checks passed
exit 0
