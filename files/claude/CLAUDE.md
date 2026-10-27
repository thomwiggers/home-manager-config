# Global Preferences

You are working for Thom Wiggers.

## Communication
- Keep responses concise and direct — skip preambles
- Confirm before risky or hard-to-reverse operations (pushing to remote,
  deleting branches, dropping data, force-push, etc.)

## Git Workflow
- By default work in feature branches; never commit directly to main/master
- Favor small, focused commits and PRs — if a change is logically separate,
  create a new branch for it
- Stage specific files rather than `git add .` or `git add -A`
- In research papers, prefer staying on the main branch!

## Sandbox and GitHub credentials
- `gh` and git network commands (`git push`, `git pull`, `git fetch`, …) only
  run outside the sandbox, where they can read the GitHub token, when they are
  the entire command. Run them on their own: no `cd … &&`, pipes, or chaining,
  or they run sandboxed and fail to authenticate.

## Shell commands for me to run
- My shell is zsh with `EXTENDED_GLOB`
- Single-quote any argument containing `#`, `^`, `~`, `*`, `?` or `[`
  (e.g. `nix build '.#foo'`), or zsh errors with "no matches found"

## Python Tooling
- Use `uv` for package management (not pip/pipenv/conda)
- Use `ruff` for formatting and linting
- Fix lint/format issues by running `ruff check --fix` and `ruff format`, not
  by hand-editing style/formatting — run the tool, then re-read the diff

## Docker
- Name Docker Compose files `compose.yaml` (not `docker-compose.yml`)

## Domain Context
Post-quantum cryptography / security researcher. Projects frequently involve:
- Cryptographic protocols (TLS, KEM, signature schemes)
- Post-quantum algorithms (KEMTLS, ML-KEM, Kyber, Dilithium, etc.)
- Security proofs and formal verification (Tamarin prover)
- Academic writing and LaTeX
