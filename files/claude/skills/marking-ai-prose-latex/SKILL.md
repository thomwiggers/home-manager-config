---
name: marking-ai-prose-latex
description: Use when writing or editing prose in a LaTeX document (paper, proof, thesis, commentary files), when a project mentions a `slop` environment or `\slopfootnote`, or when setting up AI-text marking in a new LaTeX project.
---

# Marking AI-written prose in LaTeX (`slop`)

## Overview

Every sentence of prose Claude writes in a LaTeX document is wrapped in a `slop`
environment: hot pink, URW Chancery, with a bold `SLOP` margin note. A reviewer
spots AI text at a glance; the human deletes the wrapper once they have
reviewed it.

## Make the rule permanent in the project

Skills only load when Claude judges they apply, so a quick `.tex` edit can skip this
one. On activation, check the project's `CLAUDE.md` / `AGENTS.md`: if neither mentions
`slop`, recommend that the user add this line (propose it; do not edit the file
unasked):

> Wrap all AI-written prose in LaTeX in the `slop` environment (`\slopfootnote` for
> footnotes); see the `marking-ai-prose-latex` skill for setup and special cases.

If the project has no `.claude/skills/marking-ai-prose-latex/SKILL.md`, also recommend
installing a project-local copy and committing it, so collaborators' agents follow the
same convention (this personal skill only exists on this machine). Adapt the copy to
the project: point to where the macro and editor highlighting live instead of the setup
code, and use its paths and build commands. If `.gitignore` ignores `.claude`, it needs
`.claude/*` plus `!.claude/skills/` (a negation cannot re-include a path inside an
ignored directory).

## Rules

- Wrap exactly the sentences you added, directly around them, in the file where
  they live — inside an `\input`ed file, not around the `\input{...}` call.
- Footnotes you write: `\slopfootnote{...}` (not `\footnote{\begin{slop}...}`).
- Never wrap text a human wrote or already reviewed, even when you edit next to it.
  If you rewrite a human sentence, the rewritten sentence is yours: wrap it.
- Not wrapped: pseudocode lines in figures, math-only content, labels, code,
  `\section{...}` titles (moving argument; wrap the body text instead).
- Inside lists, wrap inside the `\item`: `\item \begin{slop}...\end{slop}`.
- Never remove an existing wrapper yourself; that is the reviewer's decision.

## Setup (add to the project's macro file, after `xcolor` and `hyperref`)

If the project already defines `slop`, use it; check it has the twocolumn fix
below. Otherwise add:

```latex
% Marks AI-generated prose: hot pink, URW Chancery, SLOP margin note.
% Wrap such text in \begin{slop}...\end{slop}; human-reviewed text stays unwrapped.
\definecolor{slop}{HTML}{FF69B4}
% Zero-width note: in twocolumn, \marginparwidth is ~4pt and a plain note
% overflows into the left column's text. \llap/\rlap push it outward instead.
\newcommand{\slopnote}{\footnotesize\bfseries\color{slop}SLOP}
% Inside a footnote \marginpar is lost; \@footnotetext is patched to flag it.
\newif\ifslopinfootnote
\makeatletter
\let\slop@footnotetext\@footnotetext
\long\def\@footnotetext#1{\slop@footnotetext{\slopinfootnotetrue#1}}
\makeatother
\newenvironment{slop}{%
  % no \marginpar in inner mode (tabular, minipage, \parbox), floats
  % (captions, incl. figure*) or footnotes: LaTeX errors or loses the float
  \ifslopinfootnote\else\ifinner\else\expandafter\ifx\csname @captype\endcsname\relax
    \marginpar[\hfill\llap{\slopnote}]{\rlap{\slopnote}}\fi\fi\fi%
  \color{slop}\fontfamily{pzc}\selectfont
}{}
\newcommand{\slopfootnote}[1]{\footnote{\begingroup\color{slop}\fontfamily{pzc}%
  \selectfont\textbf{SLOP:} #1\endgroup}}
```

### Editor highlighting (VS Code)

Highlights slop regions in the source, too. Needs the `fabiospampinato.vscode-highlight`
extension (add it to `.vscode/extensions.json` `recommendations`); add to
`.vscode/settings.json`:

```json
"highlight.regexes": {
  "(\\\\(?:begin|end)\\{slop\\})": {
    "filterLanguageRegex": "latex",
    "decorations": [
      { "color": "#ff1493", "fontWeight": "bold", "backgroundColor": "#ff69b430",
        "isWholeLine": true, "overviewRulerColor": "#ff1493" }
    ]
  },
  "(\\\\begin\\{slop\\})([\\s\\S]*?)(\\\\end\\{slop\\})": {
    "filterLanguageRegex": "latex",
    "decorations": [
      { "color": "#ff1493", "fontWeight": "bold" },
      { "backgroundColor": "#ff69b412" },
      { "color": "#ff1493", "fontWeight": "bold" }
    ]
  },
  "(\\\\slopfootnote)(\\{(?:\\\\.|[^{}\\\\]|\\{(?:\\\\.|[^{}\\\\]|\\{(?:\\\\.|[^{}\\\\])*\\})*\\})*\\})": {
    "filterLanguageRegex": "latex",
    "decorations": [
      { "color": "#ff1493", "fontWeight": "bold", "overviewRulerColor": "#ff1493" },
      { "backgroundColor": "#ff69b412" }
    ]
  }
}
```

The first rule tints whole lines holding `\begin{slop}`/`\end{slop}` and marks them in
the scrollbar; the second gives a faint background to the wrapped text (one decoration
per capture group). The third does the same for `\slopfootnote{...}`; JS regexes cannot
match balanced braces, so it handles up to two levels of nested `{...}` (and escaped
`\{`/`\}`) in the argument.

**Every slop marker needs a rule.** If the project defines another slop environment or
macro (e.g. `\slopmark`, `\slopinline{...}`, a `slopitem` list), add a matching regex
in the same commit as the macro, and drop the rule when the macro goes. Unhighlighted
slop is easy to miss in review.

## Special cases

| Situation | What happens / what to do |
|---|---|
| Two-column (`twocolumn`, usenix, IEEEtran, acmart) | `\marginparwidth` is tiny (4pt); notes must be zero-width (`\llap`/`\rlap` above), or they overlap left-column text (log shows `Overfull \hbox (~20pt too wide)` per slop). Left column: note in left margin; right column: right margin. |
| Captions, `figure*`, `table` | Color/font only, no margin note (`\@captype` set). |
| `tabular`, `minipage`, `\parbox`, `\mbox` | Color/font only (`\ifinner`). |
| Footnotes | Patched `\@footnotetext` suppresses the note; prefer `\slopfootnote`. |
| `\begin{slop}` spanning paragraphs | Fine; one margin note at the start only. Prefer one wrapper per paragraph for reviewability. |
| Inline math inside slop | Fine; math font is unaffected, only colored. |
| Macro file shared between documents (e.g. a proof reusing the paper's macros) | Edit the canonical file; symlinks follow, real copies need the same change. |
| `pzc` missing | Font substitution warning; install URW base35 / `texlive-fontsextra`. `\bfseries` with `pzc` substitutes medium weight (harmless warning). |

## Verify

Build (with `-synctex=1` if the project asks) and check the log: no new
`Overfull \hbox` lines at slop locations, no `\marginpar` "Float(s) lost" or
"Not in outer par mode" errors. Ask the user how it looks rather than
screenshotting.
