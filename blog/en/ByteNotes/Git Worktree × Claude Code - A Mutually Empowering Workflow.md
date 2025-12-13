---
status: idea
type: Workshop
language: EN
---



## Pain Points

While researching Claude Code best practices, I learned that Git Worktree combined with Claude can greatly unleash Claude's maximum potential. But I didn't seem to use it much before. After analyzing myself, I found two main issues:

**1. Commands are too long**

```bash
git worktree add ../wonderland-nexus-feature-a -b feature-a
```

Having to type out the full project name, path, and branch name every time is repetitive and error-prone.

**2. .env.local doesn't auto-sync**

This is determined by Git Worktree's nature—each worktree is an independent filesystem directory, and `.env.local` is ignored by `.gitignore`, so it won't be synced by git.

The problem is my project startup depends on these local environment variable configurations. Every time I create a new worktree, I have to manually copy this file again next time, which is really annoying (AI really does make people lazier).

But giving up the worktree workflow because of these small issues feels like picking up sesame seeds while losing the watermelon.

So I think this can also be automated. In the past when typing git commands in shell, I had already configured aliases like `gp` (git push) `gl` (git pull), knowing very well how great it is to type fewer characters.

So I had Claude write an automation solution, **minimizing how much I need to type**.

---

## V1: Auto-sync .env.local

The first version's core idea was: use a shell script to handle sync logic, then chain it with `git worktree add` through a git alias.

**Sync script** (`scripts/sync-env-to-worktree.sh`):

- Auto-detect the main worktree location
- Iterate through all `.env.local` files needing sync
- Copy to the corresponding location in the target worktree

**Git Alias** (`.git/config`):

```ini
[alias]
    wt = "!f() { \
        git worktree add \"$@\" && \
        WORKTREE_PATH=$(echo \"$@\" | awk '{print $1}') && \
        ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
    }; f"
```

When executing `git wt`, it creates the worktree first, then automatically calls the sync script.

Usage:

```bash
git wt ../wonderland-nexus-feature-A feature-A
# After creating worktree, automatically triggers sync script
```

Also added an npm script in `package.json` as backup:

```json
{
  "scripts": {
    "sync-env": "bash scripts/sync-env-to-worktree.sh"
  }
}
```

This way if you forget to use `git wt`, or the main worktree's `.env.local` is updated, you can still manually sync:

```bash
yarn sync-env ../wonderland-nexus-feat-like
```

No more manual copying. But **the command itself is still long, I want to be even lazier**.

---

## V2: Simplify Command Input

After carefully observing my usage habits, we usually name branches with a feat point. So: worktree path is typically `../project-name-feat-name`

This means the feat name needs to be typed twice:
1. In the path for folder naming
2. After `-b` for defining branch name

```bash
git wt ../wonderland-nexus-feature-A feature-A
# After creating worktree, automatically triggers sync script
```
As above, feat-A twice

I think this can be optimized too, so I fed my requirements to Claude Code, letting me type just one feat name and auto-completing the folder name and branch name

Updated Git Alias:

```ini
[alias]
    wt = "!f() { \
        if [ $# -eq 1 ]; then \
            BRANCH=\"$1\"; \
            WORKTREE_PATH=\"../wonderland-nexus-$BRANCH\"; \
            git worktree add \"$WORKTREE_PATH\" -b \"$BRANCH\"; \
        else \
            git worktree add \"$@\"; \
            WORKTREE_PATH=\"$1\"; \
        fi && \
        ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
    }; f"
```

The logic is simple: check parameter count, if only one parameter go simplified mode, auto-infer path and branch name; multiple parameters go full mode, pass through to native command.

After optimization, just input branch name:

```bash
git wt feat-A
# Auto-infer path: ../wonderland-nexus-feat-A
# Auto-create branch: -b feat-A
# Auto-sync .env.local
```

Input reduced by 70% instantly. Of course, full mode is still available for special needs:

```bash
git wt ~/custom-path -b custom-branch  # Fully compatible with original usage
```

Already very usable at this point, but I found another optimization point for branch naming.

---

## V3: Support `/` Separator in Branch Names

I occasionally use Git GUI tools (like SourceTree, including GitHub's display):

If branch names use `/` separator (like `feat/xxx`), they'll auto-group into folder structure in GUI:

```
📁 feat
  ├─ like-button
  └─ share-feature
📁 fix
  └─ navbar-bug
```

This looks very clear, branches of the same type are grouped together. This is also the naming convention recommended by Git Flow.

But I also need to keep the folder naming method.

**Final solution**: Let Git branch names keep `/`, while worktree folder paths auto-convert `/` to `-`:

```ini
[alias]
    wt = "!f() { \
        if [ $# -eq 1 ]; then \
            BRANCH=\"$1\"; \
            WORKTREE_NAME=$(echo \"$BRANCH\" | tr '/' '-'); \
            WORKTREE_PATH=\"../wonderland-nexus-$WORKTREE_NAME\"; \
            git worktree add \"$WORKTREE_PATH\" -b \"$BRANCH\"; \
        else \
            git worktree add \"$@\"; \
            WORKTREE_PATH=\"$1\"; \
        fi && \
        ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
    }; f"
```

Key change is adding this line:

```bash
WORKTREE_NAME=$(echo \"$BRANCH\" | tr '/' '-')
```

Using `tr` command to convert `/` to `-` in branch names.

```bash
git wt feat/like-button
# Git branch name: feat/like-button (groups in GUI)
# Worktree path: ../wonderland-nexus-feat-like-button (filesystem friendly)
```

---

## V4: Multi-Worktree Parallel Work, How to Verify Features Correspondingly

After using git worktree, I started having Claude develop different features in parallel on different branches. This also means I might run multiple services simultaneously when checking, but sometimes I'm not sure which browser window corresponds to which feat.

Why not just display the current branch name on the page.

**1. Inject Branch Name at Build Time**

Modify `apps/web/next.config.mjs`, add to `env` config:

```js
env: {
  NEXT_PUBLIC_GIT_BRANCH: (() => {
    try {
      return require('child_process')
        .execSync('git rev-parse --abbrev-ref HEAD')
        .toString().trim();
    } catch {
      return 'unknown';
    }
  })(),
},
```

**2. Create Dev Environment Indicator Component**

Create `apps/web/src/components/DevBranchIndicator.tsx`:

- Only shows in development environment (`NODE_ENV === 'development'`)
- Fixed at bottom-right of page, semi-transparent floating style
- Displays current branch name
- Collapsible/expandable, doesn't affect normal page operations

**3. Import in Root Layout**

Add `<DevBranchIndicator />` component at the end of body in `apps/web/src/app/layout.tsx`.

This way each window's bottom-right shows the current branch name, instantly clear which is which.

---

## Final Usage

```bash
# Daily use (one parameter does everything)
git wt feat/new-feature

# Special needs (full mode still available)
git wt ~/custom-path -b branch

# Remedy (forgot to use git wt or main worktree configs updated)
yarn sync-env ../some-worktree
```

---

## Summary

Honestly these requirements are all small, but when optimized well, the daily usage experience improvement is real.

Looking back at what I've done, it's essentially all about **being lazy, lazier, laziest**.

But does this mean I'm a lazy person?

I don't think so, because these are all typical repetitive work, which I think is the task AI should help us solve first.
