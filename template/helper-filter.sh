#!/bin/bash
# helper-filter.sh — Product filtering & category grouping
# Sourced by update.sh when present. Requires helper.sh + helper-template.sh.

FILTER_CATS=()   # "url|name" pairs, ordered by first appearance
FILTER_TAGS=()   # "url|name" pairs, ordered by first appearance
_FILTER_DATA_COLLECTED=0

# --- collect_filter_data ---
# Reads all product JSONs; populates FILTER_CATS and FILTER_TAGS.
collect_filter_data() {
  [ $_FILTER_DATA_COLLECTED -eq 1 ] && return
  FILTER_CATS=()
  FILTER_TAGS=()
  local seen_cats="" seen_tags=""

  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")

    # Extract category (single-line: "category": { "name": "...", "url": "..." })
    local cat_url="" cat_name=""
    local _rc='"category"[[:space:]]*:[[:space:]]*\{[^}]*"name"[[:space:]]*:[[:space:]]*"([^"]*)"[^}]*"url"[[:space:]]*:[[:space:]]*"([^"]*)"'
    local _rc2='"category"[[:space:]]*:[[:space:]]*\{[^}]*"url"[[:space:]]*:[[:space:]]*"([^"]*)"[^}]*"name"[[:space:]]*:[[:space:]]*"([^"]*)"'
    if [[ "$c" =~ $_rc ]]; then
      cat_name="${BASH_REMATCH[1]}"; cat_url="${BASH_REMATCH[2]}"
    elif [[ "$c" =~ $_rc2 ]]; then
      cat_url="${BASH_REMATCH[1]}"; cat_name="${BASH_REMATCH[2]}"
    fi

    if [ -n "$cat_url" ] && [[ "$seen_cats" != *"|${cat_url}|"* ]]; then
      FILTER_CATS+=("${cat_url}|${cat_name}")
      seen_cats+="|${cat_url}|"
    fi

    # Extract optional tags array (multi-line)
    local in_tags=0
    while IFS= read -r line; do
      [[ "$line" == *'"tags"'* ]] && { in_tags=1; continue; }
      [ $in_tags -eq 0 ] && continue
      [[ "$line" == *']'* ]] && break
      jstr "$line" url;  local tag_url="$_JVAL"
      jstr "$line" name; local tag_name="$_JVAL"
      if [ -n "$tag_url" ] && [[ "$seen_tags" != *"|${tag_url}|"* ]]; then
        FILTER_TAGS+=("${tag_url}|${tag_name}")
        seen_tags+="|${tag_url}|"
      fi
    done <<< "$c"
  done

  _FILTER_DATA_COLLECTED=1
}

# --- validate_filter ---
# Warns when isFiltering:true config is ineffective.
validate_filter() {
  json_flag "$SITE_JSON" isFiltering || return
  local cat_count=${#FILTER_CATS[@]}
  local tag_count=${#FILTER_TAGS[@]}
  local issues=""
  [ "$cat_count" -eq 0 ] && issues+=" no categories found,"
  [ "$cat_count" -eq 1 ] && issues+=" single category (filter has no effect),"
  [ "$tag_count" -eq 1 ] && issues+=" single tag (filter has no effect),"
  if [ -n "$issues" ]; then
    issues="${issues%,}"
    echo ""
    echo "WARNING: isFiltering is true but:${issues}"
    echo ""
  fi
}

# --- build_filter_ui ---
# Produces chip HTML (category row always; tag row only if FILTER_TAGS non-empty).
build_filter_ui() {
  local html="<div class=\"filter-ui\">"
  html+="<div class=\"filter-cats\">"
  json_label filterAll; local lbl_all="${_JVAL:-All}"
  html+="<button class=\"chip active\" data-cat=\"\">${lbl_all}</button>"
  for entry in "${FILTER_CATS[@]}"; do
    local url="${entry%%|*}"
    local name="${entry#*|}"
    html+="<button class=\"chip\" data-cat=\"${url}\">${name}</button>"
  done
  html+="</div>"
  if [ ${#FILTER_TAGS[@]} -gt 0 ]; then
    html+="<div class=\"filter-tags\">"
    for entry in "${FILTER_TAGS[@]}"; do
      local url="${entry%%|*}"
      local name="${entry#*|}"
      html+="<button class=\"chip\" data-tag=\"${url}\">${name}</button>"
    done
    html+="</div>"
  fi
  html+="</div>"
  printf '%s' "$html"
}

# --- _build_product_li ---
# Renders a single product <li>. Used by both grouped and plain builders.
_build_product_li() {
  local name="$1" url="$2" price="$3" shortDesc="$4" img="$5" id="$6"
  local cat_url="$7" tags_attr="$8" addToBasket="$9"
  local li="<li"
  [ -n "$cat_url" ]   && li+=" data-cat=\"${cat_url}\""
  [ -n "$tags_attr" ] && li+=" data-tags=\"${tags_attr}\""
  li+=">"
  li+="<a href=\"/${PRODUCTS_DIR}/${url}.html\">"
  li+="<img src=\"/img/products/${img%.webp}-k.webp\" data-src=\"/img/products/${img}\" loading=\"lazy\" alt=\"${L_BRAND} ${name}\" title=\"${L_BRAND} ${name}\">"
  li+="<h3>${name}</h3>"
  li+="</a>"
  li+="<b>${price} ${SITE_CURRENCY_SYMBOL}</b>"
  li+="<p>${shortDesc}</p>"
  li+="<button data-id=\"${id}\">${addToBasket}</button>"
  li+="</li>"
  printf '%s' "$li"
}

# --- _extract_product_cat_tags ---
# Extracts category url and tags (space-joined) from product JSON content.
# Sets _PROD_CAT_URL and _PROD_TAGS_ATTR globals.
_extract_product_cat_tags() {
  local c="$1"
  _PROD_CAT_URL=""
  _PROD_TAGS_ATTR=""
  local _rc='"category"[[:space:]]*:[[:space:]]*\{[^}]*"url"[[:space:]]*:[[:space:]]*"([^"]*)"'
  [[ "$c" =~ $_rc ]] && _PROD_CAT_URL="${BASH_REMATCH[1]}"
  # Tags
  local in_tags=0
  while IFS= read -r line; do
    [[ "$line" == *'"tags"'* ]] && { in_tags=1; continue; }
    [ $in_tags -eq 0 ] && continue
    [[ "$line" == *']'* ]] && break
    jstr "$line" url; [ -n "$_JVAL" ] && _PROD_TAGS_ATTR+="${_JVAL} "
  done <<< "$c"
  _PROD_TAGS_ATTR="${_PROD_TAGS_ATTR% }"
}

# --- build_product_cards_grouped ---
# Renders products grouped by category.
# Uses <details>/<summary> when isCategoryCollapsable:true, <div>/<h3> otherwise.
build_product_cards_grouped() {
  json_label addToBasket; local addToBasket="$_JVAL"
  local use_details=0
  json_flag "$SITE_JSON" isCategoryCollapsable && use_details=1
  local html=""
  local _rf='"isForMenu"[[:space:]]*:[[:space:]]*false'

  for cat_entry in "${FILTER_CATS[@]}"; do
    local cat_url="${cat_entry%%|*}"
    local cat_name="${cat_entry#*|}"
    local group_items=""

    for pj in "$SETTINGS_DIR"/products/*.json; do
      local c=$(<"$pj")
      [[ "$c" =~ $_rf ]] && continue
      _extract_product_cat_tags "$c"
      [ "$_PROD_CAT_URL" = "$cat_url" ] || continue

      jstr "$c" name;      local name="$_JVAL"
      jstr "$c" url;       local url="$_JVAL"
      jnum "$c" price;     local price="$_JVAL"
      jstr "$c" shortDesc; local shortDesc="$_JVAL"
      jimg "$c";           local img="$_JVAL"
      jstr "$c" id;        local id="$_JVAL"

      group_items+=$(_build_product_li "$name" "$url" "$price" "$shortDesc" "$img" "$id" "$cat_url" "$_PROD_TAGS_ATTR" "$addToBasket")
    done

    [ -z "$group_items" ] && continue

    if [ "$use_details" -eq 1 ]; then
      html+="<details class=\"cat-group\" open><summary>${cat_name}</summary>"
      html+="<ul class=\"prd\">${group_items}</ul>"
      html+="</details>"
    else
      html+="<div class=\"cat-group\">"
      html+="<h3>${cat_name}</h3>"
      html+="<ul class=\"prd\">${group_items}</ul>"
      html+="</div>"
    fi
  done

  printf '%s' "$html"
}

# --- build_product_cards (override) ---
# Dispatch: filter UI (if isFiltering) + grouped (if >1 cat) or plain.
build_product_cards() {
  [ $_FILTER_DATA_COLLECTED -eq 0 ] && collect_filter_data
  local cat_count=${#FILTER_CATS[@]}
  local html=""

  json_flag "$SITE_JSON" isFiltering && html+=$(build_filter_ui)

  if [ "$cat_count" -gt 1 ]; then
    html+=$(build_product_cards_grouped)
  else
    html+=$(build_product_cards_plain)
  fi

  printf '%s' "$html"
}

# --- build_product_meta_tags ---
# Produces <div class="product-meta-tags">...</div> for product detail pages.
# Called from build_products() in update.sh when isFiltering:true.
build_product_meta_tags() {
  local c="$1"
  _extract_product_cat_tags "$c"
  [ -z "$_PROD_CAT_URL" ] && return

  # Get category name
  local cat_name=""
  local _rcn='"category"[[:space:]]*:[[:space:]]*\{[^}]*"name"[[:space:]]*:[[:space:]]*"([^"]*)"'
  [[ "$c" =~ $_rcn ]] && cat_name="${BASH_REMATCH[1]}"
  [ -z "$cat_name" ] && return

  local html="<div class=\"product-meta-tags\">"
  html+="<a href=\"/${PAGES_DIR}/${_PROD_CAT_URL}.html\">${cat_name}</a>"

  local in_tags=0
  while IFS= read -r line; do
    [[ "$line" == *'"tags"'* ]] && { in_tags=1; continue; }
    [ $in_tags -eq 0 ] && continue
    [[ "$line" == *']'* ]] && break
    jstr "$line" url;  local tag_url="$_JVAL"
    jstr "$line" name; local tag_name="$_JVAL"
    [ -n "$tag_url" ] && html+="<a href=\"/${PAGES_DIR}/${tag_url}.html\">${tag_name}</a>"
  done <<< "$c"

  html+="</div>"
  printf '%s' "$html"
}

# --- build_category_page ---
# Builds /pages/{url}.html listing products in that category.
build_category_page() {
  local cat_url="$1"
  local cat_name="$2"

  json_label addToBasket; local addToBasket="$_JVAL"
  local items=""
  local _rf='"isForMenu"[[:space:]]*:[[:space:]]*false'

  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
    [[ "$c" =~ $_rf ]] && continue
    _extract_product_cat_tags "$c"
    [ "$_PROD_CAT_URL" = "$cat_url" ] || continue

    jstr "$c" name;      local name="$_JVAL"
    jstr "$c" url;       local url="$_JVAL"
    jnum "$c" price;     local price="$_JVAL"
    jstr "$c" shortDesc; local shortDesc="$_JVAL"
    jimg "$c";           local img="$_JVAL"
    jstr "$c" id;        local id="$_JVAL"

    items+=$(_build_product_li "$name" "$url" "$price" "$shortDesc" "$img" "$id" "$cat_url" "$_PROD_TAGS_ATTR" "$addToBasket")
  done

  [ -z "$items" ] && return

  local html="<article><h2>${cat_name}</h2><ul class=\"prd\">${items}</ul></article>"
  local title="${cat_name} | ${L_BRAND}"
  local out_path="${OUTPUT_DIR}/${PAGES_DIR}/${cat_url}.html"
  local seo_path="/${PAGES_DIR}/${cat_url}.html"
  local canonical="${SITE_DOMAIN}${seo_path}"
  build_seo_tags "$seo_path"; local hreflang="$_SEO_TAGS"
  build_lang_nav "$seo_path"; local lang_nav="$_LANG_NAV"
  build_hmenu ""; local hmenu="$_HMENU"

  write_html_page "$out_path" "$title" "" "" "$canonical" "$hreflang" "$lang_nav" "$hmenu" "$html" ""
}

# --- build_tag_page ---
# Builds /pages/{url}.html listing products with that tag.
build_tag_page() {
  local tag_url="$1"
  local tag_name="$2"

  json_label addToBasket; local addToBasket="$_JVAL"
  local items=""

  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
    _extract_product_cat_tags "$c"
    [[ " ${_PROD_TAGS_ATTR} " == *" ${tag_url} "* ]] || continue

    jstr "$c" name;      local name="$_JVAL"
    jstr "$c" url;       local url="$_JVAL"
    jnum "$c" price;     local price="$_JVAL"
    jstr "$c" shortDesc; local shortDesc="$_JVAL"
    jimg "$c";           local img="$_JVAL"
    jstr "$c" id;        local id="$_JVAL"

    items+=$(_build_product_li "$name" "$url" "$price" "$shortDesc" "$img" "$id" "$_PROD_CAT_URL" "$_PROD_TAGS_ATTR" "$addToBasket")
  done

  [ -z "$items" ] && return

  local html="<article><h2>${tag_name}</h2><ul class=\"prd\">${items}</ul></article>"
  local title="${tag_name} | ${L_BRAND}"
  local out_path="${OUTPUT_DIR}/${PAGES_DIR}/${tag_url}.html"
  local seo_path="/${PAGES_DIR}/${tag_url}.html"
  local canonical="${SITE_DOMAIN}${seo_path}"
  build_seo_tags "$seo_path"; local hreflang="$_SEO_TAGS"
  build_lang_nav "$seo_path"; local lang_nav="$_LANG_NAV"
  build_hmenu ""; local hmenu="$_HMENU"

  write_html_page "$out_path" "$title" "" "" "$canonical" "$hreflang" "$lang_nav" "$hmenu" "$html" ""
}

# --- build_filter_pages ---
# Builds category and tag pages when isFiltering:true.
# Populates FILTER_PAGE_CATS and FILTER_PAGE_TAGS for sitemap use.
FILTER_PAGE_CATS=()
FILTER_PAGE_TAGS=()

build_filter_pages() {
  [ $_FILTER_DATA_COLLECTED -eq 0 ] && collect_filter_data

  if ! json_flag "$SITE_JSON" isFiltering; then
    # Clean up stale filter pages from previous builds
    for entry in "${FILTER_CATS[@]}" "${FILTER_TAGS[@]}"; do
      local furl="${entry%%|*}"
      local fpath="${OUTPUT_DIR}/${PAGES_DIR}/${furl}.html"
      [ -f "$fpath" ] && [ ! -f "${SETTINGS_DIR}/pages/${furl}.json" ] && rm -f "$fpath"
    done
    return
  fi

  validate_filter

  mkdir -p "$OUTPUT_DIR/$PAGES_DIR"
  FILTER_PAGE_CATS=()
  FILTER_PAGE_TAGS=()

  for entry in "${FILTER_CATS[@]}"; do
    local _saved_entry="$entry"
    local url="${entry%%|*}"
    local name="${entry#*|}"
    build_category_page "$url" "$name"
    FILTER_PAGE_CATS+=("$_saved_entry")
  done

  for entry in "${FILTER_TAGS[@]}"; do
    local _saved_entry="$entry"
    local url="${entry%%|*}"
    local name="${entry#*|}"
    build_tag_page "$url" "$name"
    FILTER_PAGE_TAGS+=("$_saved_entry")
  done

  echo "filter pages built (${#FILTER_PAGE_CATS[@]} categories, ${#FILTER_PAGE_TAGS[@]} tags)"
}
