---
name: changelog
description: "Generate changelogs from git history. Use when the user asks to create a changelog, release notes, or summarize changes between tags, branches, or date ranges. Triggers on 'changelog', 'release notes', 'what changed', 'diff summary'."
---

# Changelog Generator

Generate structured changelogs from git commit history using conventional commits.

## Usage

```
/changelog                          # since last tag
/changelog v1.2.0..v1.3.0          # between tags
/changelog --since="2 weeks ago"    # date range
/changelog main..feature-branch     # branch diff
```

## Workflow

### Step 1: Determine Range

Parse user input to determine the git range:

```bash
# Default: last tag to HEAD
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  RANGE="$LAST_TAG..HEAD"
else
  RANGE="HEAD~50..HEAD"  # fallback: last 50 commits
fi

# User-specified range
RANGE="v1.2.0..v1.3.0"

# Date-based
git log --after="2025-01-01" --before="2025-02-01" --oneline
```

### Step 2: Extract Commits

```bash
# Get conventional commit log with authors
git log $RANGE --pretty=format:"%h|%s|%an|%ad" --date=short

# Include PR numbers if available
git log $RANGE --pretty=format:"%h|%s|%an" --grep="(#[0-9]*)"
```

### Step 3: Categorize

Group commits by conventional commit prefix:

| Prefix | Category | Emoji |
|--------|----------|-------|
| `feat:` | Features | n/a |
| `fix:` | Bug Fixes | n/a |
| `perf:` | Performance | n/a |
| `refactor:` | Refactoring | n/a |
| `docs:` | Documentation | n/a |
| `test:` | Tests | n/a |
| `ci:` | CI/CD | n/a |
| `chore:` | Maintenance | n/a |
| `BREAKING CHANGE` | Breaking Changes | n/a |

Commits without conventional prefix: categorize by analyzing the message.

### Step 4: Enrich

For each commit, optionally:
- Link PR numbers: `#123` -> `[#123](https://github.com/org/repo/pull/123)`
- Link issues: `fixes #456` -> `[#456](https://github.com/org/repo/issues/456)`
- Get PR title if commit message is a merge commit
- Attribute contributors

Detect repo origin for links:
```bash
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
```

### Step 5: Generate Output

**Default format: Markdown**

```markdown
# Changelog

## [v1.3.0] - 2025-02-05

### Breaking Changes
- Description of breaking change (#PR)

### Features
- Add user authentication flow (#123) - @author
- Support batch processing for imports (#124) - @author

### Bug Fixes
- Fix race condition in session handler (#125) - @author

### Performance
- Optimize database query for user lookup (#126) - @author

### Contributors
@author1, @author2, @author3
```

## Options

| Flag | Effect |
|------|--------|
| `--format=md` | Markdown (default) |
| `--format=json` | JSON output |
| `--format=slack` | Slack-friendly format |
| `--no-links` | Skip PR/issue linking |
| `--no-authors` | Omit contributor attribution |
| `--breaking-only` | Only show breaking changes |
| `--include-merge` | Include merge commits (excluded by default) |

## Slack Format

When `--format=slack` or user asks for Slack-friendly output:

```
*Release v1.3.0* (2025-02-05)

*Breaking Changes*
- Description of breaking change (<link|#PR>)

*Features*
- Add user authentication flow (<link|#123>)

*Bug Fixes*
- Fix race condition in session handler (<link|#125>)
```

## JSON Format

```json
{
  "version": "v1.3.0",
  "date": "2025-02-05",
  "range": "v1.2.0..v1.3.0",
  "categories": {
    "breaking": [],
    "features": [],
    "fixes": [],
    "performance": [],
    "other": []
  },
  "contributors": [],
  "stats": {
    "total_commits": 42,
    "files_changed": 87,
    "insertions": 1234,
    "deletions": 567
  }
}
```

## Edge Cases

- **No tags exist**: Use commit count or date range, warn user
- **Non-conventional commits**: Best-effort categorization from message content
- **Monorepo**: If user specifies a path, scope with `git log -- path/`
- **Squash merges**: Parse PR title from squash commit message
- **Co-authored commits**: Extract `Co-authored-by` trailers
