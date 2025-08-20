# Development Environment Setup

This document provides setup instructions for developing Homebrew formulas in the `sheurich/tap` repository.

## Prerequisites

- Linux/ARM64 environment
- Git configured
- Internet connection for downloading dependencies

## Quick Setup

Run this command to set up your development environment:

```bash
# Install Homebrew (if not already installed)
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

# Configure PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc

# Install build dependencies
sudo apt-get update && sudo apt-get install -y build-essential
brew install gcc

# Add this tap to your local Homebrew
brew tap sheurich/tap /path/to/this/repo
```

## Development Workflow

### Testing Formulas

Use the provided development script for comprehensive testing:

```bash
# Test all formulas
./dev-test.sh

# Test a specific formula
./dev-test.sh boulder
./dev-test.sh ingest
```

### Manual Testing Commands

```bash
# Style checks (Rubocop via Homebrew)
brew style --formula sheurich/tap/boulder
brew style --formula sheurich/tap/ingest
brew style .  # entire tap

# Audit checks
brew audit --strict --formula sheurich/tap/boulder
brew audit --online --strict --formula sheurich/tap/boulder
brew audit --online --strict --tap sheurich/tap  # entire tap

# Check for upstream updates
brew livecheck sheurich/tap/boulder
brew livecheck sheurich/tap/ingest

# Get formula information
brew info sheurich/tap/boulder
brew info sheurich/tap/ingest
```

### Isolated Build Testing

For full build/test validation without affecting your system:

```bash
TMPBREW="$(mktemp -d)"
HOMEBREW_CACHE="$TMPBREW/Cache" \
HOMEBREW_TEMP="$TMPBREW/Temp" \
HOMEBREW_PREFIX="$TMPBREW/prefix" \
HOMEBREW_CELLAR="$TMPBREW/Cellar" \
brew install --build-from-source Formula/ingest.rb && brew test Formula/ingest.rb
rm -rf "$TMPBREW"
```

**Note:** For Boulder, ensure the tag and revision in the formula match upstream before attempting a local build.

## Development Environment Details

### Installed Tools

- **Homebrew**: Package manager and formula development toolkit
- **GCC**: Compiler collection for building from source
- **Ruby**: Required for Homebrew development (bundled with Homebrew)
- **RuboCop**: Style checker (installed via `brew style`)
- **ActionLint**: GitHub Actions workflow linter
- **ShellCheck**: Shell script analyzer

### Git Hooks

This repository includes pre-configured git hooks:

- **prepare-commit-msg**: Automatically adds Co-Authored-By and Change-ID trailers
- **post-commit**: Reviews commit messages and provides feedback

### GitHub Workflows

Automated workflows handle:

1. **Update Tap** (`update-tap.yml`):
   - Runs twice daily (00:00 and 12:00 UTC)
   - Checks for new upstream releases
   - Opens bump PRs automatically

2. **Auto-merge Bump PR** (`auto-merge-bump-pr.yml`):
   - Validates bump PRs with style, audit, build, and test checks
   - Auto-merges successful PRs

## Formula Development Guidelines

### Style Requirements

- Follow Homebrew Ruby style guide
- Use `brew style` to check compliance
- Fix offenses locally before pushing

### Livecheck Strategies

- **Boulder**: Detects `v0.YYYYMMDD.N` tags using `regex(/^v?(0\d{8}\.\d+)$/i)`
- **Ingest**: Detects SemVer tags like `v0.15.0` using `regex(/^v?(\d+\.\d+\.\d+)$/i)`

### Build Metadata

- **Boulder**: Uses BUILD_ID from release tag, BUILD_TIME from date in tag
- **Ingest**: Uses VERSION and BUILD_TIME with short SHA suffix

## Troubleshooting

### Common Issues

1. **ARM64 Architecture Warning**: This is expected on ARM64 systems. Binary packages (bottles) aren't available, but building from source works.

2. **Bundler Root Warning**: Safe to ignore in development environments.

3. **Formula Not Found**: Ensure the tap is added with `brew tap sheurich/tap /path/to/repo`.

### Getting Help

- Run `brew help` for general Homebrew help
- Check `man brew` for detailed documentation
- Review the main [README.md](README.md) for repository-specific information

## Environment Variables

Useful environment variables for development:

```bash
# Disable cleanup after install (faster development)
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Hide environment hints
export HOMEBREW_NO_ENV_HINTS=1

# Enable developer mode (automatic when using brew style)
brew developer on
```
