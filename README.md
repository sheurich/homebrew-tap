# Sheurich Homebrew Tap

This repository hosts the **sheurich/tap** Homebrew tap. A tap allows you to provide
additional formulas outside of Homebrew core. It currently contains one formula,
`boulder`, and includes automation to keep it up to date.

## Repository overview

```
.
├── Formula/                # Homebrew formulas live here
│   └── boulder.rb          # ACME-based certificate authority
└── .github/workflows/      # GitHub Actions for automatic updates
```

- `Formula/boulder.rb` builds Boulder from the official GitHub repository and
  installs the compiled binaries.
- `.github/workflows/update-tap.yml` checks daily for new Boulder releases and
  opens bump pull requests automatically.
- `.github/workflows/auto-merge-bump-pr.yml` validates those PRs with
  `brew audit` (and optional install/test) and merges them if successful.

## Installation

To install Boulder directly from this tap, run:

```bash
brew install sheurich/tap/boulder
```

Alternatively, add the tap first and then install:

```bash
brew tap sheurich/tap
brew install boulder
```

## Development onboarding

1. **Add or update formulas** in the `Formula/` directory.
2. **Follow Homebrew's style guidelines**. See `brew style` and the
   [Homebrew documentation](https://docs.brew.sh).
3. **Push your changes**. The GitHub workflows will handle livecheck updates and
   merge bump PRs for you.

For help with Homebrew, run `brew help` or `man brew`.
