---
name: web-scraper
description: Use when the user needs to scrape web data, find hard-to-access online information, extract structured data from websites, or perform batch web research. Triggers on "scrape", "extract data from", "find information about", "web research", "crawl", or "batch scrape".
---

# Web Scraper

High-performance web scraping orchestrator using Exa search API with Sonnet subagent batching and browser fallback.

## Prerequisites

API key stored in macOS Keychain (encrypted, no prompts):
```bash
# One-time setup
security add-generic-password -a "$USER" -s "exa-api-key" -w "YOUR_KEY"

# In ~/.zshrc
export EXA_API_KEY=$(security find-generic-password -a "$USER" -s "exa-api-key" -w 2>/dev/null)
```

Get key at: https://exa.ai

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Opus (Orchestrator)                     │
│  - Analyzes user request                                 │
│  - Plans scraping strategy                               │
│  - Batches targets to Sonnet subagents                   │
│  - Aggregates results into JSON                          │
└─────────────────────────────────────────────────────────┘
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
     ┌──────────┐   ┌──────────┐   ┌──────────┐
     │ Sonnet   │   │ Sonnet   │   │ Sonnet   │
     │ Agent 1  │   │ Agent 2  │   │ Agent N  │
     │ (target) │   │ (target) │   │ (target) │
     └──────────┘   └──────────┘   └──────────┘
            │              │              │
            ▼              ▼              ▼
     ┌──────────────────────────────────────┐
     │         Extraction Methods           │
     │  1. Exa API search + content         │
     │  2. WebFetch for direct URLs         │
     │  3. Playwright browser (fallback)    │
     └──────────────────────────────────────┘
```

## Workflow

### Step 1: Parse Request
Identify from user request:
- **Targets**: URLs, domains, or search queries
- **Data schema**: What fields to extract
- **Batch size**: How many targets to process
- **Output format**: JSON structure expected

### Step 2: Exa Search (Preferred Method)

Use Exa API for intelligent search when targets aren't direct URLs:

```bash
curl -X POST "https://api.exa.ai/search" \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "<search query>",
    "type": "neural",
    "useAutoprompt": true,
    "numResults": 10,
    "contents": {
      "text": true,
      "highlights": true
    }
  }'
```

For specific URLs, use `findSimilar` or `contents`:
```bash
curl -X POST "https://api.exa.ai/contents" \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "ids": ["<url1>", "<url2>"],
    "text": true
  }'
```

### Step 3: Batch to Sonnet Subagents

For multiple targets, spawn parallel Sonnet agents:

```
Use the Task tool with:
- subagent_type: "general-purpose"
- model: "sonnet"
- prompt: Include target URL, extraction schema, and instructions
```

**Batching Strategy:**
- Group 3-5 targets per Sonnet agent
- Launch agents in parallel using multiple Task calls
- Each agent handles: fetch → parse → extract → return JSON

**Sonnet Agent Prompt Template:**
```
Scrape the following targets and extract data matching this schema:
Schema: {json_schema}

Targets:
1. {url1}
2. {url2}
3. {url3}

Instructions:
1. First try WebFetch for each URL
2. If blocked or JS-heavy, use Playwright browser_navigate + browser_snapshot
3. Extract matching fields from page content
4. Return JSON array of results

Output format:
{
  "results": [...],
  "failures": [{"url": "...", "reason": "..."}]
}
```

### Step 4: Browser Fallback

When programmatic methods fail (403, JS-rendered, anti-bot):

```
1. mcp__plugin_playwright_playwright__browser_navigate to URL
2. mcp__plugin_playwright_playwright__browser_snapshot to get content
3. Extract data from accessibility tree
4. mcp__plugin_playwright_playwright__browser_close when done
```

Use browser for:
- JavaScript-rendered SPAs
- Sites with anti-bot protection
- Pages requiring interaction (clicks, scrolls)
- Login-gated content (if credentials provided)

### Step 5: Aggregate Results

Collect all subagent responses and merge into final JSON:

```json
{
  "query": "<original user query>",
  "timestamp": "<ISO timestamp>",
  "total_targets": 25,
  "successful": 23,
  "failed": 2,
  "results": [
    {
      "source_url": "https://...",
      "extracted_data": { ... },
      "method": "exa|webfetch|browser"
    }
  ],
  "failures": [
    {"url": "...", "reason": "...", "attempted_methods": [...]}
  ]
}
```

## Output Format

ALWAYS return structured JSON. Ask user for schema if unclear:

```json
{
  "results": [
    {
      "url": "source url",
      "title": "page title",
      "data": {
        // user-defined schema
      }
    }
  ],
  "metadata": {
    "scraped_at": "ISO timestamp",
    "total_results": 10,
    "methods_used": ["exa", "browser"]
  }
}
```

## Cost Optimization

- **Exa API**: ~$0.001/search, ~$0.003/content extraction
- **Sonnet subagents**: Fast, good for parsing
- **Browser**: Most expensive, use as fallback only

Prioritize:
1. Exa search + contents (fastest, cheapest)
2. WebFetch direct (free but limited)
3. Sonnet + WebFetch batches (parallelism)
4. Browser (JS sites, anti-bot)

## Example Usage

**User:** Find pricing info for the top 10 AI coding assistants

**Response:**
1. Exa search: "AI coding assistant pricing 2024"
2. Get top 10 results with content
3. Spawn 2 Sonnet agents (5 URLs each)
4. Extract: name, pricing tiers, features
5. Return JSON array with pricing data

**User:** Scrape product listings from these 50 URLs

**Response:**
1. Batch URLs into 10 groups of 5
2. Launch 10 parallel Sonnet agents
3. Each agent: WebFetch → extract → JSON
4. Browser fallback for failures
5. Aggregate all results

## Error Handling

- **Rate limited**: Exponential backoff, switch to browser
- **403/Blocked**: Try browser with different viewport
- **Timeout**: Retry once, then mark as failed
- **Parse error**: Return raw content + error message
