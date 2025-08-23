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

## Documentation

- `DEVELOPMENT.md` explains environment setup and local testing.
- `SPEC.md` describes the automation architecture.
- `TODO.md` tracks planned improvements.

## Automation details

### Livecheck strategies

Both formulas use the GitHub tags livecheck strategy with a custom regex:
- **Boulder:** Detects `v0.YYYYMMDD.N` tags using `regex(/^v?(0\.\d{8}\.\d+)$/i)`.
- **Ingest:** Detects SemVer tags like `v0.15.0` using `regex(/^v?(\d+\.\d+\.\d+)$/i)`.

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
2. **Run Homebrew linters locally** before pushing:
   - Style (Rubocop via Homebrew):
     ```bash
     brew style --formula Formula/boulder.rb
     brew style --formula Formula/ingest.rb
     # or for the entire tap
     brew style .
     ```
   - Audit:
     ```bash
     # offline checks
     brew audit --strict --formula Formula/boulder.rb
     brew audit --strict --formula Formula/ingest.rb
     # enable online checks (queries upstream, e.g., GitHub releases)
     brew audit --online --strict --formula Formula/boulder.rb
     brew audit --online --strict --formula Formula/ingest.rb
     # or for the entire tap
     brew audit --online --strict --tap sheurich/tap
     ```
   - Optional local build/test (avoids altering workstation state by using a throwaway prefix):
     ```bash
     # Create a temporary Homebrew prefix and run an isolated build/test
     TMPBREW="$(mktemp -d)"
     brew --prefix  # shows your default prefix; unchanged by the following
     HOMEBREW_CACHE="$TMPBREW/Cache" \
     HOMEBREW_TEMP="$TMPBREW/Temp" \
     HOMEBREW_PREFIX="$TMPBREW/prefix" \
     HOMEBREW_CELLAR="$TMPBREW/Cellar" \
     brew install --build-from-source Formula/ingest.rb && brew test Formula/ingest.rb
     rm -rf "$TMPBREW"
     ```
     Notes:
     - The above uses a separate, disposable Cellar/Prefix/Cache so it does not install/uninstall into your primary Homebrew.
     - For Boulder, ensure the tag and revision in the formula match upstream before attempting a local build.
   Notes:
   - `brew style` will auto-install its bundled gems the first time it runs.
   - Prefer fixing style offenses locally (e.g., line length or trailing commas) before pushing.
3. **Push your changes**. The GitHub workflows will:
   - detect new upstream releases;
   - open bump PRs;
   - validate with style/audit/install/test; and
   - merge automatically once checks pass.

For help with Homebrew, run `brew help` or `man brew`.
