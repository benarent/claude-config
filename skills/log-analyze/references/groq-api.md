# Groq API Reference

## Endpoint

```
POST https://api.groq.com/openai/v1/chat/completions
```

## Authentication

```bash
export GROQ_API_KEY="gsk_..."
```

Get API key at: https://console.groq.com/keys

## Basic Request

```bash
curl -s https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.3-70b-versatile",
    "messages": [
      {"role": "system", "content": "You are a log analysis expert."},
      {"role": "user", "content": "Analyze these logs..."}
    ],
    "response_format": {"type": "json_object"},
    "temperature": 0.1
  }'
```

## Recommended Model

**llama-3.3-70b-versatile**
- Context: 128K tokens
- Speed: 300-800 tokens/sec
- Best for: Complex analysis, pattern recognition
- Cost: $0.59/M input, $0.79/M output

Alternative for simpler tasks:
- `llama-3.1-8b-instant` - Faster, cheaper, less capable

## JSON Output

Always use `response_format` for structured output:

```json
{
  "response_format": {"type": "json_object"}
}
```

System prompt must mention JSON:
```
"You are a log analysis expert. Output valid JSON only."
```

## Rate Limits

### Free Tier
- 30 requests/minute
- 14,400 requests/day
- 6,000 tokens/minute

### Paid Tier
- Higher limits based on plan
- Recommended for production use

## Error Handling

### Rate Limited (429)

```bash
retry_with_backoff() {
  local max_attempts=5
  local timeout=1
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    response=$(curl -s -w "%{http_code}" ...)
    http_code="${response: -3}"

    if [ "$http_code" = "429" ]; then
      sleep $timeout
      timeout=$((timeout * 2))
      attempt=$((attempt + 1))
    else
      echo "${response:0:-3}"
      return 0
    fi
  done

  echo "Max retries exceeded" >&2
  return 1
}
```

### Common Errors

| Code | Meaning | Action |
|------|---------|--------|
| 400 | Bad request | Check JSON syntax |
| 401 | Unauthorized | Check API key |
| 429 | Rate limited | Wait and retry |
| 500 | Server error | Retry after delay |

## Parallel Requests

Use xargs for controlled parallelism:

```bash
# Max 5 concurrent requests (respects rate limits)
ls chunks/*.txt | xargs -P 5 -I {} bash -c '
  curl -s https://api.groq.com/openai/v1/chat/completions \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "model": "llama-3.3-70b-versatile",
  "messages": [{"role": "user", "content": "$(cat {})"}],
  "response_format": {"type": "json_object"}
}
EOF
' > "results/{}.json"
```

## Token Estimation

Rough estimates for log analysis:
- 1 line of logs ≈ 20-50 tokens
- 1K lines ≈ 30-50K tokens
- 10K lines ≈ 300-500K tokens

Stay under 100K tokens per request (leave room for output).

## Response Parsing

```bash
# Extract content from response
response=$(curl -s ...)
content=$(echo "$response" | jq -r '.choices[0].message.content')

# Check for errors
if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
  error_msg=$(echo "$response" | jq -r '.error.message')
  echo "API Error: $error_msg" >&2
  exit 1
fi
```

## Best Practices

1. **Batch small requests** - Combine multiple small log chunks into one request
2. **Use low temperature** - 0.1 for consistent structured output
3. **Explicit JSON schema** - Include expected schema in system prompt
4. **Handle partial failures** - Don't fail entire job if one chunk fails
5. **Log raw responses** - Save to temp file for debugging
