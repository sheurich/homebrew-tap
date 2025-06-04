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
- `.github/workflows/update-tap.yml` checks daily for new releases and
  opens bump pull requests automatically.
- `.github/workflows/auto-merge-bump-pr.yml` validates those PRs with
  `brew audit` (and optional install/test) and merges them if successful.

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
3. **Push your changes**. The GitHub workflows will handle livecheck updates and
   merge bump PRs for you.

For help with Homebrew, run `brew help` or `man brew`.
