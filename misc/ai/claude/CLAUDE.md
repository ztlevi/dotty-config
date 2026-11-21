## CLI Tool Preferences

When using Bash:
- Prefer `fd` over `find` (e.g., `fd <pattern>` instead of `find . -name <pattern>`)
- Prefer `rg` over `grep` (e.g., `rg <pattern> <path>` instead of `grep -r`)
- Prefer `sd` over `sed` (e.g., `sd 'old' 'new' <file>` instead of `sed -i 's/old/new/g'`)

Still prioritize built-in tools (Read/Edit/Grep/Glob) over Bash where applicable.

## Git push

`git push` is permitted by settings, but ONLY when I specifically ask you to push in that message.

- Never push automatically — not after committing, not after finishing a task, not to "save progress" or open a PR/CR.
- Approval to push once does not carry over to later pushes; ask again each time.
- Never force-push (`--force`, `--force-with-lease`) unless I explicitly say so.

## Scuderia context

@~/dev/work/context/scuderia-context.md

## CRUX / cr troubleshooting

@~/dev/work/context/crux-context.md

## Hyperpod/Scuderia Tickets analysis

@~/dev/work/context/ticket-analysis.md

## HyperPod team ownership

@~/dev/work/context/hyperpod-team-ownership.md

## Personal build and test

@~/dev/work/context/personal-build-and-test.md
