# Homebrew Tap - sheurich/homebrew-tap

Personal Homebrew formulas with automated daily updates.

## Installation

```bash
brew tap sheurich/homebrew-tap
brew install boulder  # ACME certificate authority from Let's Encrypt
brew install ingest   # Convert plain text files to markdown for AI/LLMs
```

## Formulas

### Boulder
ACME-based certificate authority, the software that powers Let's Encrypt.

- **Source**: https://github.com/letsencrypt/boulder
- **Version**: Date-based (`v0.YYYYMMDD.N` format, e.g., v0.20251110.0)
- **License**: MPL-2.0
- **Build**: Go binary with custom timestamp extraction for reproducible builds

### Ingest
Parse directories of plain text files into markdown optimized for AI/LLMs.

- **Source**: https://github.com/sammcj/ingest
- **Version**: Semantic versioning (e.g., v0.15.1)
- **License**: MIT
- **Build**: Go binary via upstream Makefile

## Development

### Testing Formulas

```bash
# Validate formula syntax and style
brew audit --strict Formula/*.rb
brew style Formula/*.rb

# Install and test locally
brew install --build-from-source Formula/boulder.rb
brew test Formula/boulder.rb

# Check for upstream updates
brew livecheck --tap sheurich/homebrew-tap

# Run full test suite (as CI does)
brew test-bot --only-formulae --only-json-tab
```

### Formula Architecture

#### Boulder (`Formula/boulder.rb`)
- Extracts commit timestamp for reproducible builds:
  ```ruby
  commit_time = Utils.git_commit_timestamp(stable.url, stable.specs[:revision], timezone: "UTC")
  ldflags = "-s -w -X github.com/letsencrypt/boulder/core.BuildTime=#{commit_time.iso8601}"
  ```
- Installs all binaries from `bin/*` directory
- Test validates version format: `/\d+\.\d{8}\.\d+/`

#### Ingest (`Formula/ingest.rb`)
- Standard Go build using upstream Makefile
- Single binary installation
- Test validates version output and reads the formula file

### Manual Updates

When updating formulas manually:

1. Update `url` with new tag/version
2. Generate new `sha256`: `curl -sL [url] | shasum -a 256`
3. Update `revision` to full commit hash
4. Test locally before committing

## Automation

This tap self-maintains through GitHub Actions:

### Update Workflow (`.github/workflows/update.yml`)
- **Schedule**: Runs at 00:00 and 12:00 UTC daily
- **Process**: Checks for new upstream versions via livecheck
- **Output**: Creates PRs with `bump-[formula]-[version]` naming
- **Authentication**: Uses `HOMEBREW_GITHUB_API_TOKEN` secret

### Test & Merge Workflow (`.github/workflows/test-and-merge.yml`)
- **Trigger**: PRs with `bump-` prefix
- **Validation**: Runs `brew test-bot` (audit, style, install, test)
- **Completion**: Auto-merges passing PRs via squash merge, deletes branch

## Contributing

Automated updates maintain this repository. Formulas update automatically twice daily; manual contributions are rare.

- **Issues**: Report problems via [GitHub Issues](https://github.com/sheurich/homebrew-tap/issues)
- **Manual PRs**: Follow the `[formula] [version]` commit format (e.g., "boulder 0.20251110.0")

## Technical Reference

### Commit Conventions
- Formula updates: `[formula] [version]` (e.g., "boulder 0.20251110.0")
- PR naming for bumps: `bump-[formula]-[version]`
- Workflow changes: Direct description of change

### Version Detection
- **Boulder**: Uses GitHub API to check latest tag matching `v0.YYYYMMDD.N`
- **Ingest**: Standard GitHub release tags with semver

### Test Requirements
All formulas must:
1. Install without errors
2. Pass `brew audit --strict`
3. Pass `brew style`
4. Return correct version from `--version` flag
5. Boulder: Output matches `/\d+\.\d{8}\.\d+/`
6. Ingest: Reads the formula file

### Directory Structure
```
homebrew-tap/
├── .github/
│   ├── dependabot.yml        # Weekly GitHub Actions updates
│   └── workflows/
│       ├── test-and-merge.yml # Auto-merge bump PRs
│       └── update.yml         # Check for updates twice daily
└── Formula/
    ├── boulder.rb             # ACME CA formula
    └── ingest.rb              # Text parser formula
```