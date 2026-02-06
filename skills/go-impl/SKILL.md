---
name: go-impl
description: "Go implementation workflow with test-first development and validation gates"
---

# Go Implementation Workflow

## Before Starting
1. Run `make check` to verify baseline
2. Identify files to modify

## Implementation Loop
For each change:
1. Write/update test first
2. Implement minimal code to pass
3. Run `go test ./...`
4. Run `goimports -w [file]`
5. Run `go vet ./...`

## Validation Gate
Before marking complete:
- [ ] All tests pass
- [ ] No vet warnings
- [ ] Imports ordered correctly
- [ ] No unrelated changes

## Context Prompt Template
Before implementing: here's the current state of [feature], files involved are [X, Y, Z], change should [specific behavior], must not break [constraint].
