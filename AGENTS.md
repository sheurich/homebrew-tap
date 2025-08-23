# AGENTS

This repository contains documentation across several files:

- `README.md` – overview of the tap and automation.
- `DEVELOPMENT.md` – development environment setup and testing workflow.
- `SPEC.md` – system architecture specification.
- `TODO.md` – backlog and planned improvements.

### Contribution guidelines

- Homebrew formulas live in `Formula/`. Run `./dev-test.sh <formula>` to
  execute style and audit checks before committing changes. `./dev-test.sh`
  without arguments runs checks for all formulas and the tap.
- Keep Ruby code aligned with Homebrew's style conventions.

