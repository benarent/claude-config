# Common Scraping Scenarios

## 1. Competitor Pricing Research

**User request:** "Find pricing for top 10 observability platforms"

**Orchestrator approach:**
```
1. Exa search: "observability platform pricing plans 2024"
2. Extract top 10 relevant URLs
3. Batch to 2 Haiku agents (5 each)
4. Schema:
   {
     "company": "string",
     "product": "string",
     "tiers": [{"name": "string", "price": "string", "features": ["string"]}],
     "free_tier": "boolean",
     "enterprise_pricing": "string"
   }
```

## 2. Job Listings Aggregation

**User request:** "Scrape remote DevOps jobs from these 20 job boards"

**Orchestrator approach:**
```
1. Split URLs into 4 batches of 5
2. Launch 4 parallel Haiku agents
3. Each agent uses browser (job boards are JS-heavy)
4. Schema:
   {
     "title": "string",
     "company": "string",
     "location": "string",
     "salary_range": "string",
     "posted_date": "string",
     "apply_url": "string"
   }
```

## 3. Documentation Extraction

**User request:** "Extract all API endpoints from Stripe's docs"

**Orchestrator approach:**
```
1. Exa search: "site:stripe.com/docs/api"
2. Get content for all doc pages
3. Haiku agents parse each page
4. Schema:
   {
     "endpoint": "string",
     "method": "string",
     "description": "string",
     "parameters": [{"name": "string", "type": "string", "required": "boolean"}],
     "response_example": "object"
   }
```

## 4. News/Press Monitoring

**User request:** "Find all press mentions of [Company] in the last week"

**Orchestrator approach:**
```
1. Exa search with date filter:
   {
     "query": "[Company] announcement OR news OR press release",
     "startPublishedDate": "2024-01-24",
     "numResults": 50,
     "contents": {"highlights": true}
   }
2. Single Haiku agent to structure results
3. Schema:
   {
     "headline": "string",
     "source": "string",
     "date": "string",
     "summary": "string",
     "sentiment": "positive|neutral|negative",
     "url": "string"
   }
```

## 5. E-commerce Product Data

**User request:** "Scrape product details from these 100 Amazon links"

**Orchestrator approach:**
```
1. Amazon blocks bots - browser required
2. Batch into 10 groups of 10
3. Each Haiku agent:
   - browser_navigate to URL
   - browser_snapshot
   - Extract from accessibility tree
4. Schema:
   {
     "asin": "string",
     "title": "string",
     "price": "string",
     "rating": "number",
     "review_count": "number",
     "features": ["string"],
     "availability": "string"
   }
```

## 6. Research Paper Metadata

**User request:** "Find papers about LLM security from the last year"

**Orchestrator approach:**
```
1. Exa search: "LLM security research paper arxiv 2024"
2. Get top 30 results
3. 3 Haiku agents (10 papers each)
4. Schema:
   {
     "title": "string",
     "authors": ["string"],
     "abstract": "string",
     "date": "string",
     "arxiv_id": "string",
     "citations": "number",
     "pdf_url": "string"
   }
```

## Haiku Agent Prompt Template

```
You are a web scraping agent. Extract structured data from the following targets.

SCHEMA:
{json_schema}

TARGETS:
{url_list}

INSTRUCTIONS:
1. For each URL, first try WebFetch
2. If WebFetch fails (403, timeout, JS-rendered), use Playwright:
   - mcp__plugin_playwright_playwright__browser_navigate
   - mcp__plugin_playwright_playwright__browser_snapshot
   - Extract data from accessibility tree
3. Parse page content and extract fields matching the schema
4. If a field can't be found, set it to null
5. Return results as JSON

OUTPUT FORMAT:
{
  "results": [
    {"url": "...", "data": {...}}
  ],
  "failures": [
    {"url": "...", "reason": "...", "attempted": ["webfetch", "browser"]}
  ]
}

Return ONLY the JSON, no explanation.
```
