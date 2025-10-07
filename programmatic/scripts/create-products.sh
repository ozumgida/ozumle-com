#!/bin/bash

DATA_DIR="../../data"
PRODUCTS_DIR="../../products"
JSON_FILE="${DATA_DIR}/products.json"

mkdir -p "$PRODUCTS_DIR"

if [ ! -f "$JSON_FILE" ]; then
    echo "Error: JSON file not found at $JSON_FILE"
    exit 1
fi

if ! jq '.' "$JSON_FILE" > /dev/null 2>&1; then
    echo "Error: Invalid JSON format in $JSON_FILE"
    exit 1
fi

jq -c '.products[]' "$JSON_FILE" | while read -r product; do
    name=$(echo "$product" | jq -r '.name')
    url=$(echo "$product" | jq -r '.url')
    meta_desc=$(echo "$product" | jq -r '.metaDesc')
    meta_keywords=$(echo "$product" | jq -r '.keywords')
    
    title="${name} | Özüm'le"
    
    echo "Processing product: $name"
    
    output_file="${PRODUCTS_DIR}/${url}.html"
    
    cat > "$output_file" << EOF
<!DOCTYPE html><html lang="tr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${title}</title><meta name="description" content="${meta_desc}"><meta name="keywords" content="${meta_keywords}"><link rel="stylesheet" href="/static/site.css"/><link rel="icon" href="/favicon.png" type="image/png"/></head><body><div id="loading">loading...</div><script src="/static/site.js"></script></body></html>
EOF
    
    echo "✓ Created $(basename "$output_file")"
done

echo "======================================================="
echo "All product pages have been generated successfully!"