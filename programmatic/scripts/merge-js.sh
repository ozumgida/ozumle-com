#!/bin/bash

# Read 
helper_content=$(cat ../helper.js)
basket_content=$(cat ../basket.js)
pages_content=$(cat ../pages.js)
product_content=$(cat ../product.js)
main_content=$(cat ../main.js)

# Merge
output_file="../../static/site.js"
echo "$main_content" > "$output_file"
echo "$helper_content" >> "$output_file"
echo "$basket_content" >> "$output_file"
echo "$pages_content" >> "$output_file"
echo "$product_content" >> "$output_file"

echo "Merged files into $output_file"