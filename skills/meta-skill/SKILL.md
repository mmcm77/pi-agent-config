---
name: meta-skill
description: Create or improve focused Pi skill packages from a requested capability or reusable workflow. Use when the user asks to create, convert, revise, or standardize a skill.
---

# Meta Skill

Create focused, valid skill packages for Pi. Infer a narrow intent from the requested capability when the description is sparse.

## Pi skill format

User skills live at `~/.pi/agent/skills/<name>/SKILL.md`. Project skills live at `<project>/.pi/skills/<name>/SKILL.md` and load only after the project is trusted.

Pi uses the Agent Skills format. Each skill is a directory containing `SKILL.md` and optional supporting resources:

```text
<name>/
├── SKILL.md
├── scripts/       # deterministic or repeated operations
├── references/    # detailed guidance loaded only when needed
└── assets/        # templates or files used in outputs
```

Pi reads these YAML frontmatter fields:

- `name`: required lowercase kebab-case identifier, 1 to 64 characters.
- `description`: required description of what the skill does and when to use it, up to 1024 characters.
- `license`: optional license name or bundled license reference.
- `compatibility`: optional environment requirements, up to 500 characters.
- `metadata`: optional key-value mapping.
- `allowed-tools`: optional space-delimited list of pre-approved tools. This is experimental and is not a tool restriction.
- `disable-model-invocation`: optional boolean. When `true`, the skill is available only through `/skill:<name>`.

The `description` is always visible to the model. Pi loads the Markdown body on demand when the task matches, or when the user invokes `/skill:<name>`. Relative file references resolve from the skill directory.

Do not add agent-only fields such as `tools` or `model`, or unsupported harness fields such as `argument-hint`, `version`, `color`, `permissionMode`, `maxTurns`, `memory`, `skills`, `mcpServers`, or `hooks`. Pi ignores unknown skill frontmatter.

## Preferred structure

Use the minimum sections the skill needs. Default to:

```markdown
# Human-Readable Name

One sentence stating the skill's objective.

## Process

1. Ordered, actionable steps.

## Boundaries

- Scope and safety constraints specific to this skill.

## Response

State the required result or output contract.
```

Omit `Boundaries` when the skill has no meaningful task-specific risks. Add setup, modes, examples, or resource guidance only when they improve execution. Do not repeat global agent rules inside the skill.

## Process

1. Determine the reusable capability, trigger conditions, expected result, and task-specific constraints from the request and current conversation. Keep one primary responsibility per skill.
2. Choose a concise lowercase kebab-case name. Keep the directory name and frontmatter name identical.
3. Write a specific description that includes both what the skill does and when it should load. Distinguish it from adjacent tasks so it does not trigger too broadly.
4. Choose the requested scope. If scope is unspecified, use the user skill directory.
5. Read an existing target before replacing it. Preserve useful task-specific constraints and supporting resources while removing obsolete or unsupported content.
6. Write a compact body using imperative, plain language. Include the objective, ordered process, relevant evidence standard, task-specific boundaries, and response contract.
7. Keep details in `SKILL.md` when they are needed on every invocation. Move large or conditional material into `references/`, repeated deterministic work into `scripts/`, and output source files into `assets/`. Do not create supporting resources without a current need.
8. Use relative paths for bundled resources and state when each resource should be read or run. Resolve source material from its actual location before copying or adapting it.
9. Remove platform boilerplate, duplicate instructions, persona language, decorative sections, unnecessary examples, and claims the skill cannot verify.
10. Re-read every created or changed file. Verify the required frontmatter, supported fields, name and directory match, relative references, trigger specificity, body structure, and requested scope.

## Quality standard

A strong skill is narrow enough to trigger predictably, explicit enough to execute without hidden context, and short enough that its instructions remain clear. It states each rule once, separates required steps from optional guidance, requires evidence before claiming completion, and blocks destructive or out-of-scope actions relevant to its capability.

## Response

Report the skill path, supporting files created or changed, validation performed, and any assumption that materially affected the result. Do not include unrelated setup or documentation.
