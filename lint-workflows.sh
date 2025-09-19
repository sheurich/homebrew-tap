#!/bin/bash

# Workflow linting and testing script for GitHub Actions workflows
# Provides comprehensive validation including YAML syntax, GitHub Actions validation, and shell script checks
#
# Usage:
#   ./lint-workflows.sh              # Lint all workflows
#   ./lint-workflows.sh --fix        # Auto-fix issues where possible
#   ./lint-workflows.sh --help       # Show help

set -euo pipefail # Enable strict error handling

# Color output for better readability
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to print colored output
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to show help
show_help() {
  cat <<EOF
GitHub Actions Workflow Linting and Testing Script

Usage: $0 [OPTIONS]

OPTIONS:
  --help      Show this help message
  --fix       Auto-fix linting issues where possible
  --verbose   Enable verbose output
  --yaml-only Only run YAML linting (skip actionlint and shellcheck)

This script performs the following checks:
- YAML syntax validation with yamllint
- GitHub Actions workflow validation with actionlint (if available)
- Shell script validation with shellcheck for embedded scripts

EXAMPLES:
  $0                    # Full validation of all workflows
  $0 --fix             # Fix YAML formatting issues automatically
  $0 --yaml-only       # Only run YAML validation
  $0 --verbose         # Show detailed output

EOF
}

# Parse command line arguments
VERBOSE=false
FIX_ISSUES=false
YAML_ONLY=false

while [[ $# -gt 0 ]]
do
  case $1 in
    --help)
      show_help
      exit 0
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --fix)
      FIX_ISSUES=true
      shift
      ;;
    --yaml-only)
      YAML_ONLY=true
      shift
      ;;
    --*)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    *)
      log_error "This script doesn't accept positional arguments: $1"
      show_help
      exit 1
      ;;
  esac
done

# Verbose logging
verbose_log() {
  if [[ "${VERBOSE}" == "true" ]]
  then
    log_info "$1"
  fi
}

# Check if tools are available
check_tool_availability() {
  local tool=$1
  local required=${2:-false}

  if command -v "${tool}" >/dev/null 2>&1
  then
    verbose_log "${tool} is available"
    return 0
  else
    if [[ "${required}" == "true" ]]
    then
      log_error "${tool} is required but not found"
      return 1
    else
      log_warning "${tool} not found, skipping related checks"
      return 1
    fi
  fi
}

# Function to validate environment
validate_environment() {
  verbose_log "Validating workflow linting environment"

  local errors=0

  if ! check_tool_availability yamllint true
  then
    ((errors++))
  fi

  if [[ "${YAML_ONLY}" == "false" ]]
  then
    check_tool_availability actionlint false || log_info "actionlint can be installed with: go install github.com/rhymond/actionlint/cmd/actionlint@latest"
    check_tool_availability shellcheck false || log_info "shellcheck can be installed with: apt-get install shellcheck"
  fi

  if [[ ${errors} -gt 0 ]]
  then
    log_error "Environment validation failed with ${errors} errors"
    exit 1
  fi

  verbose_log "Environment validation passed"
}

# Function to run YAML linting
run_yamllint() {
  if [[ "${FIX_ISSUES}" == "true" ]]
  then
    log_warning "yamllint doesn't support auto-fixing. Run with manual fixes."
  fi

  log_info "Running yamllint on workflow files..."

  local yamllint_config=".yamllint.yml"
  if [[ ! -f "${yamllint_config}" ]]
  then
    log_warning "No .yamllint.yml found, using default configuration"
    yamllint_config=""
  fi

  local exit_code=0
  # Use explicit file list to avoid issues with directory traversal
  local workflow_files
  workflow_files=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null || echo "")

  if [[ -z "${workflow_files}" ]]
  then
    log_warning "No workflow files found in .github/workflows/"
    return 0
  fi

  if [[ -n "${yamllint_config}" ]]
  then
    if yamllint -c "${yamllint_config}" $workflow_files
    then
      log_success "YAML syntax validation passed"
    else
      exit_code=$?
      log_error "YAML syntax validation failed"
    fi
  else
    if yamllint $workflow_files
    then
      log_success "YAML syntax validation passed"
    else
      exit_code=$?
      log_error "YAML syntax validation failed"
    fi
  fi

  return "${exit_code}"
}

# Function to run actionlint
run_actionlint() {
  if [[ "${YAML_ONLY}" == "true" ]]
  then
    return 0
  fi

  if ! command -v actionlint >/dev/null 2>&1
  then
    log_warning "actionlint not available, skipping GitHub Actions validation"
    return 0
  fi

  log_info "Running actionlint on workflow files..."

  local exit_code=0
  if actionlint
  then
    log_success "GitHub Actions validation passed"
  else
    exit_code=$?
    log_error "GitHub Actions validation failed"
  fi

  return "${exit_code}"
}

# Function to extract and validate shell scripts from workflows
validate_embedded_shell() {
  if [[ "${YAML_ONLY}" == "true" ]]
  then
    return 0
  fi

  if ! command -v shellcheck >/dev/null 2>&1
  then
    log_warning "shellcheck not available, skipping shell script validation"
    return 0
  fi

  log_info "Extracting and validating embedded shell scripts..."

  local workflow_files
  workflow_files=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null || echo "")

  if [[ -z "${workflow_files}" ]]
  then
    log_warning "No workflow files found for shell script extraction"
    return 0
  fi

  temp_dir=$(mktemp -d -t workflow-shell-check-XXXXXX)
  cleanup_temp_dir() { rm -rf "${temp_dir}"; }
  trap cleanup_temp_dir EXIT

  local script_count=0
  local failed_scripts=0

  # Extract shell scripts from workflow files
  for workflow_file in $workflow_files
  do
    verbose_log "Extracting shell scripts from ${workflow_file}"

    # Use a simple but effective approach to extract run: | blocks
    # This is basic but works for most common cases
    awk -v temp_dir="${temp_dir}" -v workflow_file="${workflow_file}" '''
      /run: [|>]/ { in_script=1; script_num++; next }
      in_script && /^[[:space:]]*$/ { next }
      in_script && /^[[:space:]]*- / { in_script=0; next }
      in_script && /^[[:space:]]*[a-zA-Z_-]+:/ { in_script=0; print line > script_file; next }
      in_script {
        if (script_file == "") {
           script_file = temp_dir "/script_" script_num ".sh"
           print "#!/bin/bash" > script_file
           print "# Extracted from " workflow_file > script_file
           print "" > script_file
           }
           print $0 > script_file
           }
           !in_script { script_file = "" }
           ''' "${workflow_file}"
           done
           
           # Check extracted scripts
           for script_file in "${temp_dir}"/*.sh; do
           if [[ -f "${script_file}" ]]
        then
      ((script_count++))
      verbose_log "Checking $(basename "${script_file}")"

      if shellcheck "${script_file}"
      then
        verbose_log "✅ $(basename "${script_file}") passed shellcheck"
      else
        ((failed_scripts++))
        log_warning "⚠️  $(basename "${script_file}") has shellcheck warnings/errors"
      fi
    fi
  done

  if [[ ${script_count} -eq 0 ]]
  then
    log_info "No shell scripts found in workflows to validate"
    return 0
  fi

  if [[ ${failed_scripts} -eq 0 ]]
  then
    log_success "All ${script_count} embedded shell scripts passed validation"
    return 0
  else
    log_warning "${failed_scripts} out of ${script_count} shell scripts have issues"
    return 1
  fi
}

# Main execution logic
main() {
  log_info "Starting GitHub Actions workflow validation"
  verbose_log "Options: FIX_ISSUES=${FIX_ISSUES}, YAML_ONLY=${YAML_ONLY}, VERBOSE=${VERBOSE}"

  validate_environment

  local total_errors=0

  # Run YAML linting
  if ! run_yamllint
  then
    ((total_errors++))
  fi

  # Run actionlint
  if ! run_actionlint
  then
    ((total_errors++))
  fi

  # Validate embedded shell scripts
  if ! validate_embedded_shell
  then
    ((total_errors++))
  fi

  # Summary
  printf "\n"
  if [[ ${total_errors} -eq 0 ]]
  then
    log_success "All workflow validation checks passed!"
    printf "\n==> Quick reference:\n"
    echo "  - YAML linting: yamllint -c .yamllint.yml .github/workflows/"
    echo "  - GitHub Actions: actionlint"
    echo "  - Shell scripts: shellcheck <script>"
    echo "  - Full validation: ./lint-workflows.sh"
    echo "  - Help: ./lint-workflows.sh --help"
  else
    log_error "Workflow validation completed with ${total_errors} error(s)"
    printf "\n==> Fix suggestions:\n"
    echo "  - Fix YAML issues manually or with editor formatting"
    echo "  - Check actionlint output for GitHub Actions issues"
    echo "  - Use shellcheck recommendations for shell scripts"
    echo "  - Run with --verbose for detailed output"
    exit 1
  fi
}

# Check if script is being sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  main
fi
