---
name: agent-worktrees
description: Safely create, inspect, hand off, review, and clean up Git branches and worktrees for parallel agentic engineering. Use when starting isolated agent work, assigning concurrent tasks, reviewing an exact pull-request head, auditing stale worktrees, or cleaning up after merge.
compatibility: Requires Git; exact pull-request review and PR-aware cleanup require an authenticated GitHub CLI.
---

# Agent Worktrees

Manage parallel engineering work with one task, one branch, and one writable worktree. Never allow two agents to write in the same worktree.

## Safety rules

- Inspect before changing anything. Start with `git status --short --branch`, `git worktree list --porcelain`, and `git branch -vv`.
- Do not switch branches or modify the user's current worktree merely to create another worktree.
- Do not stash, reset, clean, force-delete, or discard changes unless the user explicitly authorizes that exact destructive action.
- Never remove a worktree until confirming whether it contains tracked, staged, or untracked changes.
- Never delete a branch until confirming its commits are merged or the user explicitly chooses to abandon them.
- Prefer worktree directories outside the repository. Do not create new worktrees under `.claude/`, `.codex/`, `.pi/`, or another agent-specific directory inside the checkout.
- A branch can be checked out in only one worktree. Resume its existing worktree rather than creating a duplicate.
- Use detached worktrees only for read-only review or exact-commit verification, not implementation.
- Treat edits that exist only in a worktree as uncommitted, never shipped.

## Establish repository context

Determine the root and repository name without assuming the current directory:

```bash
repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")
git remote get-url origin
git status --short --branch
git worktree list --porcelain
git branch -vv
```

Read the repository's `AGENTS.md` and any delivery guide it references before work associated with an epic or pull request. In Clubpicks, follow `docs/engineering/agent-delivery.md` and keep the epic's canonical agent-state block current.

## Choose a mode

### 1. Create an implementation worktree

Use this for a new independent task. Obtain the issue number or another stable task identifier and a short lowercase slug. Prefer:

- Branch: `agent/issue-<number>-<slug>`
- Directory: `../<repo-name>-worktrees/issue-<number>-<slug>`

Before creation:

1. Run `git fetch origin`.
2. Confirm the proposed branch does not already exist locally or remotely.
3. Confirm the destination directory does not exist.
4. Confirm no existing worktree already owns the task or branch.
5. Use `origin/main` unless repository guidance names another base.

Create it without changing the current checkout:

```bash
mkdir -p "$(dirname "$destination")"
git worktree add -b "$branch" "$destination" origin/main
```

Report the absolute worktree path, branch, base commit, and intended owner/task. If the branch or directory already exists, stop and offer to resume or inspect it; do not invent a second copy.

### 2. Inventory or resume work

Use `git worktree list --porcelain` as the authoritative local inventory. For each relevant worktree, report:

- Absolute path
- Branch or detached state
- Current commit
- Dirty/clean state, checked from inside that worktree
- Whether its branch has an open, merged, or closed PR when `gh` is available
- Recommended action: retain, resume, inspect, or cleanup candidate

Do not classify age alone as proof that a worktree is abandoned. `prunable` means Git's recorded path is missing; it does not prove the branch is safe to delete.

### 3. Create an exact-PR-head review worktree

Use this for independent final-head verification. The verifier must not be the author and must not reuse the author's writable worktree.

Get the authoritative remote head:

```bash
pr=<number>
head_sha=$(gh pr view "$pr" --json headRefOid --jq .headRefOid)
git fetch origin "pull/$pr/head"
test "$(git rev-parse FETCH_HEAD)" = "$head_sha"
git worktree add --detach "$review_destination" "$head_sha"
```

After creating it, run `git rev-parse HEAD` inside the review worktree and confirm it equals the full `head_sha`. Review and test read-only at that commit. If a defect is found, report it to the author; do not repair it in the detached review worktree.

For Clubpicks final verification, follow the marker and evidence requirements in `docs/engineering/agent-delivery.md`. Any later push invalidates the verification.

### 4. Clean up after merge or abandonment

Begin with an audit, not deletion:

```bash
git worktree list --porcelain
git worktree prune --dry-run
```

For each candidate:

1. Inspect `git status --short --branch` inside it.
2. Identify its branch and full head SHA.
3. Check its PR state with `gh pr list --head "$branch" --state all` when applicable.
4. Confirm the branch is merged into the intended base, or obtain explicit abandonment approval.
5. Show the exact worktree and branch that would be removed.

For a clean, merged worktree, remove conservatively:

```bash
git worktree remove "$destination"
git branch -d "$branch"
git worktree prune
```

Do not use `git worktree remove --force` or `git branch -D` without explicit user approval after showing what would be lost. Detached review worktrees may be removed after verification, but still check for local changes first.

## Parallel-agent coordination

- Give each agent an explicit task boundary, branch, and absolute worktree path.
- Give concurrent agents disjoint write scopes whenever possible.
- Do not let an agent commit unrelated changes found in its worktree.
- Commit before transferring ownership. A handoff must name the branch, worktree, full SHA, dirty/clean state, PR, checks run, and next action.
- For an epic, use the canonical issue state as the coordination record rather than creating a separate local state file.
- Use an integration branch only when dependent changes cannot land independently. Prefer small independently mergeable PRs.

## Final response

Keep the result operational and concise:

```text
Mode: created | inventoried | review-ready | cleaned
Worktree: <absolute path>
Branch: <branch or detached>
Head: <full SHA>
Base/PR: <base or PR URL>
State: <clean/dirty and committed/uncommitted>
Next action: <one concrete action>
```

If no changes were made because of a safety check, say exactly what blocked the operation and present non-destructive options.
