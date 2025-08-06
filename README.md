# Homebrew Tap

This repository hosts the **sheurich/tap** Homebrew tap. A tap allows you to provide
additional formulas outside of Homebrew core. It currently contains two formulas,
`boulder` and `ingest`, and includes automation to keep them up to date.

## Repository overview

```
.
├── Formula/                # Homebrew formulas live here
│   ├── boulder.rb          # ACME-based certificate authority
│   └── ingest.rb           # Plain text file parser for AI/LLMs
└── .github/workflows/      # GitHub Actions for automatic updates
```

- `Formula/boulder.rb` builds [Boulder](https://github.com/letsencrypt/boulder) from the official GitHub repository and
  installs the compiled binaries.
- `Formula/ingest.rb` builds [Ingest](https://github.com/sammcj/ingest) from the official GitHub repository and
  installs the compiled binaries.
- `.github/workflows/update-tap.yml` checks twice daily for new releases and
  opens bump pull requests automatically.
- `.github/workflows/auto-merge-bump-pr.yml` validates those PRs with
  `brew style`, `brew audit`, `brew install --build-from-source`, and `brew test`,
  then merges them automatically if successful.

## Automation details

### Livecheck strategies

- Both formulas use the default Git livecheck strategy:
  - Boulder tags follow `v0.YYYYMMDD.N` (e.g., `v0.20250805.0`) and are detected without custom regex.
  - Ingest uses SemVer-like tags (e.g., `v0.15.0`) and is also detected by the Git strategy.

### Bump PRs and auto-merge

- The update workflow runs on a schedule (`0 0 * * *` and `0 12 * * *`) and via manual dispatch.
- When updates are found, bump PRs are opened automatically using a Personal Access Token (`HOMEBREW_GITHUB_API_TOKEN`).
- The auto-merge workflow:
  - Only processes branches prefixed with `bump-` for safety.
  - Runs `brew style`, `brew audit --online`, installs from source, and runs the formula tests.
  - Uses squash merge via `gh pr merge --squash --delete-branch`.
  - Runs unattended; merges require passing checks (no admin override).

### Build metadata conventions

- Boulder:
  - BUILD_ID is derived from the release tag without the leading `v` (e.g., `0.20250805.0`).
  - BUILD_TIME is derived from the date in the tag (`YYYYMMDD`) and formatted as `YYYY-MM-DDT00:00:00Z`.
  - Head builds use an 8-char short commit as BUILD_ID and `Time.now.utc.iso8601` for BUILD_TIME.
- Ingest:
  - Uses upstream’s expected variables (`VERSION` and a `BUILD_TIME` suffix including short SHA).

## Installation

To install Boulder or Ingest directly from this tap, run:

```bash
brew install sheurich/tap/boulder
brew install sheurich/tap/ingest
```

Alternatively, add the tap first and then install:

```bash
brew tap sheurich/tap
brew install boulder
brew install ingest
```

## Development onboarding

1. **Add or update formulas** in the `Formula/` directory.
2. **Follow Homebrew's style guidelines**. See `brew style` and the
   [Homebrew documentation](https://docs.brew.sh).
3. **Push your changes**. The GitHub workflows will:
   - detect new upstream releases;
   - open bump PRs;
   - validate with style/audit/install/test; and
   - merge automatically once checks pass.

For help with Homebrew, run `brew help` or `man brew`.
