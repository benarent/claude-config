# Exa API Reference

## Endpoints

### Search
```bash
POST https://api.exa.ai/search
```

**Parameters:**
- `query` (string): Natural language search query
- `type` (string): "neural" (semantic) or "keyword"
- `useAutoprompt` (bool): Let Exa optimize query
- `numResults` (int): 1-100, default 10
- `includeDomains` (array): Only these domains
- `excludeDomains` (array): Skip these domains
- `startPublishedDate` (string): ISO date filter
- `endPublishedDate` (string): ISO date filter
- `contents` (object): Include text/highlights

**Example:**
```bash
curl -X POST "https://api.exa.ai/search" \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "best practices for kubernetes security 2024",
    "type": "neural",
    "useAutoprompt": true,
    "numResults": 20,
    "contents": {
      "text": true,
      "highlights": {
        "numSentences": 3
      }
    }
  }'
```

### Contents (Get page content by URL)
```bash
POST https://api.exa.ai/contents
```

**Parameters:**
- `ids` (array): URLs to fetch content from
- `text` (bool): Include full text
- `highlights` (object): Extract key sentences

**Example:**
```bash
curl -X POST "https://api.exa.ai/contents" \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "ids": [
      "https://example.com/article1",
      "https://example.com/article2"
    ],
    "text": true,
    "highlights": {
      "numSentences": 5,
      "query": "pricing information"
    }
  }'
```

### Find Similar
```bash
POST https://api.exa.ai/findSimilar
```

**Parameters:**
- `url` (string): Reference URL
- `numResults` (int): How many similar pages
- `includeDomains` / `excludeDomains`

**Example:**
```bash
curl -X POST "https://api.exa.ai/findSimilar" \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://competitor.com/product",
    "numResults": 10,
    "excludeDomains": ["competitor.com"]
  }'
```

## Response Format

```json
{
  "results": [
    {
      "title": "Page Title",
      "url": "https://...",
      "publishedDate": "2024-01-15",
      "author": "Author Name",
      "score": 0.95,
      "text": "Full page content...",
      "highlights": ["Key sentence 1", "Key sentence 2"]
    }
  ]
}
```

## Cost

- Search: ~$0.001 per query
- Contents: ~$0.003 per URL
- FindSimilar: ~$0.001 per query

## Rate Limits

- 100 requests/minute on free tier
- Higher limits with paid plans

## Pro Tips

1. **Use `useAutoprompt: true`** for better results - Exa reformulates your query
2. **Combine search + contents** in one call using `contents` parameter
3. **Filter by date** for recent information
4. **Use highlights** to extract relevant snippets without parsing full text
5. **Domain filtering** to focus on authoritative sources
