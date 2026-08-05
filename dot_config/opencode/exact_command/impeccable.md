---
description: Design work via Impeccable (shape, critique, audit, polish, bolder, quieter, distill, harden, animate, colorize, typeset, layout, live, ...)
agent: design
---

Load the `impeccable` skill, then handle this request: $ARGUMENTS

## Routing

Treat `$ARGUMENTS` as `<command> [target]`.

- **Known command** — one of `shape`, `init`, `document`, `extract`, `critique`, `audit`, `polish`, `bolder`, `quieter`, `distill`, `harden`, `onboard`, `animate`, `colorize`, `typeset`, `layout`, `delight`, `overdrive`, `clarify`, `adapt`, `optimize`, `live`. Load that command's reference playbook and follow it.
- **Empty** — follow the skill's `reference/routing.md` and present its context-aware menu. Do NOT auto-run a command.
- **Free-form description** — treat it as general design work per the skill's own routing rules.

## Reminders

- Run `node ~/.config/opencode/skills/impeccable/scripts/context.mjs` once per session before acting, with cwd at the user's project.
- Detect the project's UI stack before writing any code — never assume one.
- Honor the Guidance Precedence in your agent instructions: project conventions (`DESIGN.md`, existing components, the skill matching the stack) beat Impeccable, which beats Pencil's `get_guidelines`.
- Do NOT use `scripts/pin.mjs`. It creates sibling *skill* directories in the project, which are wiped by chezmoi and would be visible to every agent. Ask for a dedicated command file instead.
