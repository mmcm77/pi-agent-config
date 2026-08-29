# Model routing

- Keep the lead session on `openai-codex/gpt-5.6-terra:medium` for normal feature, fix, test, review, and integration work.
- Do not delegate small, well-scoped tasks. When delegation is useful, use `openai-codex/gpt-5.6-luna:low` for bounded reconnaissance, inventory, formatting, and summarization.
- Use `openai-codex/gpt-5.6-sol:high` only for security-sensitive changes, authentication or authorization, data migrations, architecture decisions, difficult cross-domain integration, or final adjudication after conflicting evidence.
- For `session_handoff`, omitting a model inherits Terra/medium. Select Luna/low or Sol/high explicitly when the task matches those tiers.
- Escalate only one tier at a time when task risk requires it or the current tier produces a concrete capability failure. Do not escalate solely because a task is long.

# Orchestration

- `pi-sessions` is the only delegation mechanism. Use `session_handoff` for a concrete, bounded task that can proceed independently; use its messaging and report flow for steering and completion.
- Keep one lead responsible for scope, integration, and the final completion decision. Do not delegate small tasks or parallelize work that shares files, state, or unresolved architecture.
- Every handoff must state the objective, owned files or responsibility, acceptance criteria, required evidence, and stop condition. Tell writers not to revert or overwrite concurrent work.
- Use one writer per file or worktree. A verifier receives fresh context, remains read-only, checks the exact final revision, and reports only reproducible findings.
- A child report must state status, files changed, checks run with results, blockers, and residual risk. The lead validates accepted work before claiming completion.
