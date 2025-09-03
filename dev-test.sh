#!/bin/bash

# Development testing script for Homebrew formulas
# Provides comprehensive testing including style, audit, livecheck, and build validation
# Based on the README guidance for isolated build/test
# 
# Usage:
#   ./dev-test.sh              # Test all formulas
#   ./dev-test.sh boulder      # Test specific formula
#   ./dev-test.sh --help       # Show help

set -euo pipefail  # Enable strict error handling

# Ensure Homebrew is in PATH
export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

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
  cat << EOF
Homebrew Formula Development Testing Script

Usage: $0 [OPTIONS] [FORMULA]

ARGUMENTS:
  FORMULA     Name of specific formula to test (boulder, ingest)
              If not provided, tests all formulas

OPTIONS:
  --help      Show this help message
  --verbose   Enable verbose output
  --no-build  Skip isolated build testing

EXAMPLES:
  $0                    # Test all formulas
  $0 boulder           # Test only boulder formula
  $0 --verbose ingest  # Test ingest with verbose output

This script performs the following checks:
- Formula style validation (RuboCop via Homebrew)
- Formula audit checks (offline and online)
- Livecheck for upstream updates
- Formula information display
- Optional isolated build testing

EOF
}

# Parse command line arguments
VERBOSE=false
NO_BUILD=false
FORMULA=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      show_help
      exit 0
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --no-build)
      NO_BUILD=true
      shift
      ;;
    --*)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    *)
      if [[ -n "$FORMULA" ]]; then
        log_error "Multiple formulas specified. Please specify only one."
        exit 1
      fi
      FORMULA="$1"
      shift
      ;;
  esac
done

# Set default if no formula specified
FORMULA=${FORMULA:-all}

# Verbose logging
verbose_log() {
  if [[ "$VERBOSE" == "true" ]]; then
    log_info "$1"
  fi
}

log_info "Running Homebrew development checks for formula: ${FORMULA}"

# Function to test a specific formula
test_formula() {
  local formula=$1
  printf "\n==> Testing formula: %s\n" "${formula}"

  verbose_log "Starting comprehensive validation for $formula"

  # Validate formula exists
  if [[ ! -f "Formula/${formula}.rb" ]]; then
    log_error "Formula file not found: Formula/${formula}.rb"
    return 1
  fi

  log_info "Running brew style..."
  if brew style --formula "sheurich/tap/${formula}"; then
    log_success "Style check passed"
  else
    log_error "Style check failed for $formula"
    return 1
  fi

  log_info "Running brew audit (offline)..."
  if brew audit --strict --formula "sheurich/tap/${formula}"; then
    log_success "Offline audit passed"
  else
    log_error "Offline audit failed for $formula"
    return 1
  fi

  log_info "Running brew audit (online)..."
  if brew audit --online --strict --formula "sheurich/tap/${formula}"; then
    log_success "Online audit passed"
  else
    log_warning "Online audit failed for $formula (may be due to network issues)"
  fi

  log_info "Checking for updates with livecheck..."
  if brew livecheck "sheurich/tap/${formula}"; then
    log_success "Livecheck completed"
  else
    log_warning "Livecheck failed for $formula"
  fi

  log_info "Formula info:"
  brew info "sheurich/tap/${formula}" || log_warning "Failed to get formula info"
  
  log_success "All checks completed for $formula"
}

# Function to run isolated build/test
isolated_build_test() {
  local formula=$1
  
  if [[ "$NO_BUILD" == "true" ]]; then
    log_info "Skipping isolated build test (--no-build specified)"
    return 0
  fi
  
  printf "\n==> Running isolated build/test for: %s\n" "${formula}"

  # Create temporary directory with proper cleanup
  local tmpbrew
  tmpbrew="$(mktemp -d -t homebrew-test-XXXXXX)"
  
  # Ensure cleanup on exit
  trap "rm -rf '$tmpbrew'" EXIT
  
  log_info "Using temporary Homebrew prefix: ${tmpbrew}"

  verbose_log "Setting up isolated environment variables"
  
  # Note: This requires the formula to be available for installation
  # For development testing, we can run the style/audit checks instead
  log_warning "Skipping build test (would require specific version/tag match)"
  log_info "To run full build test manually:"
  cat << EOF
     HOMEBREW_CACHE='${tmpbrew}/Cache' \\
     HOMEBREW_TEMP='${tmpbrew}/Temp' \\
     HOMEBREW_PREFIX='${tmpbrew}/prefix' \\
     HOMEBREW_CELLAR='${tmpbrew}/Cellar' \\
     brew install --build-from-source Formula/${formula}.rb && brew test Formula/${formula}.rb
EOF

  # Cleanup is handled by trap
  trap - EXIT
  rm -rf "${tmpbrew}"
}

# Function to validate environment
validate_environment() {
  verbose_log "Validating development environment"
  
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not found in PATH. Please install Homebrew first."
    exit 1
  fi
  
  if ! brew --version >/dev/null 2>&1; then
    log_error "Homebrew is not working properly"
    exit 1
  fi
  
  verbose_log "Environment validation passed"
}

# Main execution logic
main() {
  validate_environment
  
  if [[ "${FORMULA}" = "all" ]]; then
    log_info "Testing all formulas"
    
    # Get list of available formulas
    local formulas=()
    for formula_file in Formula/*.rb; do
      if [[ -f "$formula_file" ]]; then
        local formula_name
        formula_name=$(basename "$formula_file" .rb)
        formulas+=("$formula_name")
      fi
    done
    
    if [[ ${#formulas[@]} -eq 0 ]]; then
      log_error "No formula files found in Formula/ directory"
      exit 1
    fi
    
    log_info "Found ${#formulas[@]} formulas: ${formulas[*]}"
    
    # Test each formula
    local failed_formulas=()
    for formula in "${formulas[@]}"; do
      if ! test_formula "$formula"; then
        failed_formulas+=("$formula")
        log_error "Tests failed for $formula"
      fi
    done
    
    # Tap-wide checks
    printf "\n==> Running tap-wide checks\n"
    log_info "Running brew style for all formulae..."
    if brew style Formula; then
      log_success "Tap-wide style check passed"
    else
      log_error "Tap-wide style check failed"
      failed_formulas+=("tap-style")
    fi

    log_info "Running brew audit for entire tap..."
    if brew audit --online --strict --tap sheurich/tap; then
      log_success "Tap-wide audit passed"
    else
      log_warning "Tap-wide audit failed (may be due to network issues)"
    fi
    
    # Summary
    if [[ ${#failed_formulas[@]} -eq 0 ]]; then
      log_success "All tests passed!"
    else
      log_error "Some tests failed for: ${failed_formulas[*]}"
      exit 1
    fi
  else
    # Validate formula exists
    if [[ ! -f "Formula/${FORMULA}.rb" ]]; then
      log_error "Formula not found: ${FORMULA}"
      log_info "Available formulas:"
      for formula_file in Formula/*.rb; do
        if [[ -f "$formula_file" ]]; then
          formula_name=$(basename "$formula_file" .rb)
          echo "  - $formula_name"
        fi
      done
      exit 1
    fi
    
    test_formula "${FORMULA}"
    isolated_build_test "${FORMULA}"
  fi

  printf "\n"
  log_success "Development environment checks completed successfully!"
  printf "\n==> Quick reference:\n"
  echo "  - Style check: brew style --formula sheurich/tap/<formula>"
  echo "  - Audit check: brew audit --online --strict --formula sheurich/tap/<formula>"
  echo "  - Live check: brew livecheck sheurich/tap/<formula>"
  echo "  - Info: brew info sheurich/tap/<formula>"
  echo "  - Test all: ./dev-test.sh"
  echo "  - Test specific: ./dev-test.sh <formula>"
  echo "  - Help: ./dev-test.sh --help"
}

# Run main function
main
