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

## Technical writing

Applies to any prose you write for me: papers, proofs, theses, reports,
documentation, commit messages that explain a design.

### Audience
- Write for a reviewer at a top-tier venue who reads the text fresh, is
  an expert in the field, and has no access to drafts, notes, chat
  history or the reasoning that led here. They only see the final text.
- They do not want the work in the middle. Every detour, hedge or
  justification of a choice that is no longer on the table wastes their
  time and costs trust. If a decision needs recording, it goes in a
  notes file, not in the document.
- Be a ruthless editor. Churn is not a cost; a weaker text is. Restructure
  when the structure is wrong, instead of patching a remark onto it.

### Voice
- Write as I write, and where the document has human-written passages,
  match them; do not improve on them.
- First person plural, present tense, direct. "We replace X by Y." "We
  abort on a wrong guess." "We rely on the PRF security of F."
- Short declarative sentences, one idea each. Split semicolon chains.
  Prefer the verb to the nominalization: "we replace", not "the
  replacement is made".
- Plain verbs: replace, abort, hold, agree, rely on, guess, bound, use,
  require, exclude, show. No metaphorical or bureaucratic verbs: not
  "credits", "serves", "carries", "sits", "incurs", "names", "selects",
  "reads off", "threads", "treats", "covers", "demands", "asks for",
  "judges", "stands in for", "lives in", "counts", "yields",
  "diverges", "prices in", "leverages".
- No hedging ("arguably", "essentially", "it seems", "we believe"), no
  filler ("note that", "it is easy to see", "clearly"), no em-dashes.
- US English; in LaTeX, math in `\( \)`, not `$`.

### Clarity
- One fixed term per concept, used consistently; if the text defines a
  term formally, use it only in that meaning and describe informal
  devices in plain words rather than borrowing a defined term.
- Each argument step follows one template: what changes, why it is
  justified (the assumption or reduction), what follows, then stop.
- Use the assumption you rely on directly: cite it where you need it. Do
  not disclaim it as unnecessary, and do not re-derive it the long way
  to avoid naming it.
- Say load-bearing things inline, once, in the place the reader needs
  them. Do not say that something is "handled elsewhere" or "already
  accounted for" without a reference to where.
- If something is genuinely open, mark it visibly; never hide it in
  vague prose. If a claim cannot be made precise, do not make it.
- A case split belongs where the cases diverge. A step that some cases
  skip is a step in the wrong case; fix the structure, not the remark.
- Do not leave `\todo` boxes or questions in text you hand over: resolve
  them in the text or raise them in your reply.
