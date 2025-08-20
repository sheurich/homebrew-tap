#!/bin/bash

# Development testing script for Homebrew formulas
# Based on the README guidance for isolated build/test

set -e

# Ensure Homebrew is in PATH
export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

FORMULA=${1:-all}

echo "==> Running Homebrew development checks for formula: ${FORMULA}"

# Function to test a specific formula
test_formula() {
  local formula=$1
  printf "\n==> Testing formula: %s\n" "${formula}"

  echo "  -> Running brew style..."
  brew style --formula "sheurich/tap/${formula}"

  echo "  -> Running brew audit (offline)..."
  brew audit --strict --formula "sheurich/tap/${formula}"

  echo "  -> Running brew audit (online)..."
  brew audit --online --strict --formula "sheurich/tap/${formula}"

  echo "  -> Checking for updates with livecheck..."
  brew livecheck "sheurich/tap/${formula}"

  echo "  -> Formula info:"
  brew info "sheurich/tap/${formula}"
}

# Function to run isolated build/test
isolated_build_test() {
  local formula=$1
  printf "\n==> Running isolated build/test for: %s\n" "${formula}"

  TMPBREW="$(mktemp -d)"
  echo "  -> Using temporary Homebrew prefix: ${TMPBREW}"

  # Note: This requires the formula to be available for installation
  # For development testing, we can run the style/audit checks instead
  echo "  -> Skipping build test (would require specific version/tag match)"
  echo "  -> To run full build test manually:"
  echo "     HOMEBREW_CACHE='${TMPBREW}/Cache' \\"
  echo "     HOMEBREW_TEMP='${TMPBREW}/Temp' \\"
  echo "     HOMEBREW_PREFIX='${TMPBREW}/prefix' \\"
  echo "     HOMEBREW_CELLAR='${TMPBREW}/Cellar' \\"
  echo "     brew install --build-from-source Formula/${formula}.rb && brew test Formula/${formula}.rb"

  rm -rf "${TMPBREW}"
}

if [[ "${FORMULA}" = "all" ]]
then
  echo "==> Testing all formulas"
  test_formula boulder
  test_formula ingest

  printf "\n==> Running tap-wide checks\n"
  echo "  -> Running brew style for entire tap..."
  brew style .

  echo "  -> Running brew audit for entire tap..."
  brew audit --online --strict --tap sheurich/tap
else
  test_formula "${FORMULA}"
  isolated_build_test "${FORMULA}"
fi

printf "\n==> Development environment checks completed successfully!\n"
printf "\n==> Quick reference:\n"
echo "  - Style check: brew style --formula sheurich/tap/<formula>"
echo "  - Audit check: brew audit --online --strict --formula sheurich/tap/<formula>"
echo "  - Live check: brew livecheck sheurich/tap/<formula>"
echo "  - Info: brew info sheurich/tap/<formula>"
echo "  - Test all: ./dev-test.sh"
echo "  - Test specific: ./dev-test.sh <formula>"
