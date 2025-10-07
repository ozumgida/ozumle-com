#!/bin/bash

html_content="<!DOCTYPE html><html lang=\"tr\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title></title><meta name=\"description\" content=\"\"><meta name=\"keywords\" content=\"\"><link rel=\"stylesheet\" href=\"/static/site.css\"/><link rel=\"icon\" href=\"/favicon.png\" type=\"image/png\"/></head><body><div id=\"loading\">loading...</div><script src=\"/static/site.js\"></script></body></html>"

site_json=$(cat ../../data/site.json)

extract_value() {
    local json="$1"
    local key="$2"
    local page="$3"

    echo "$json" | jq -r ".pages.\"$page\".\"$key\"" 2>/dev/null || echo ""
}

pages=$(echo "$site_json" | jq -r '.pages | keys[]')

for page in $pages; do

    title=$(extract_value "$site_json" "title" "$page")
    description=$(extract_value "$site_json" "description" "$page")
    keywords=$(extract_value "$site_json" "keywords" "$page")

    echo "Processing page: $page"

    output_file="../../${page}.html"

    cat > "$output_file" << EOF
<!DOCTYPE html><html lang="tr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${title}</title><meta name="description" content="${description}"><meta name="keywords" content="${keywords}"><link rel="stylesheet" href="/static/site.css"/><link rel="icon" href="/favicon.png" type="image/png"/></head><body><div id="loading">loading...</div><script src="/static/site.js"></script></body></html>
EOF

    echo "✓ Created $(basename "$output_file")"
done

echo "==========================================="
echo "All pages have been generated successfully!"
