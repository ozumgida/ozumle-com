#!/bin/bash
# HTML partial renderers and content builders for update.sh.
# Depends on helper.sh being sourced first.

# --- Parts Content Builder ---
build_main() {
  local file="$1"
  grep -q '"parts"' "$file" || return

  local html="" found=0 in_content=0 in_list=0 in_img_block=0

  while IFS= read -r line; do
    if [ $found -eq 0 ]; then
      [[ "$line" == *'"parts"'* ]] && found=1
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*\{ ]] && [ $in_content -eq 0 ] && [ $in_list -eq 0 ]; then
      if [ $in_img_block -eq 1 ]; then
        html+="</div></section>"
        in_img_block=0
      fi
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*\] ]]; then
      if [ $in_list -eq 1 ]; then
        html+="</ul>"; in_list=0
      elif [ $in_content -eq 1 ]; then
        in_content=0
      else
        [ $in_img_block -eq 1 ] && html+="</div></section>" && in_img_block=0
        break
      fi
      continue
    fi

    if [[ "$line" == *'"img"'* ]] && [ $in_content -eq 0 ] && [ $in_list -eq 0 ]; then
      local _ri='"img"[[:space:]]*:[[:space:]]*"([^"]*)"'
      if [[ "$line" =~ $_ri ]]; then
        local img_val="${BASH_REMATCH[1]}"
        html+="<section>"
        html+="<img src=\"/img/pages/${img_val%.webp}-k.webp\" data-src=\"/img/pages/${img_val}\" loading=\"lazy\" alt=\"\">"
        html+="<div>"
        in_img_block=1
      fi
      continue
    fi

    if [[ "$line" == *'"title"'* ]]; then
      local _rt='"title"[[:space:]]*:[[:space:]]*"([^"]*)"'
      [[ "$line" =~ $_rt ]] && [ -n "${BASH_REMATCH[1]}" ] && html+="<h3>${BASH_REMATCH[1]}</h3>"
      continue
    fi

    [[ "$line" == *'"content"'* ]] && { in_content=1; in_list=0; continue; }
    [[ "$line" == *'"list"'* ]] && { in_list=1; in_content=0; html+="<ul>"; continue; }

    if [ $in_content -eq 1 ] || [ $in_list -eq 1 ]; then
      [[ "$line" == *'"'* ]] || continue
      local _rv='^[[:space:]]*"(.*)"[[:space:],]*$'
      [[ "$line" =~ $_rv ]] || continue
      local v="${BASH_REMATCH[1]}"
      [ $in_content -eq 1 ] && html+="<p>${v}</p>"
      [ $in_list -eq 1 ] && html+="<li>${v}</li>"
    fi
  done < "$file"

  printf '%s' "${html//\\\"/\"}"
}

# --- Contact Builder ---
build_contact() {
  local _cc=$(<"$COMPANY_JSON")
  jstr "$_cc" map;       local map="$_JVAL"
  jstr "$_cc" phone;     local phone="$_JVAL"; local tel="${phone//[ ]/}"
  jstr "$_cc" email;     local email="$_JVAL"
  jstr "$_cc" legalName; local legal="$_JVAL"

  json_label address;   local lbl_address="$_JVAL"
  json_label phone;     local lbl_phone="$_JVAL"
  json_label email;     local lbl_email="$_JVAL"
  json_label showOnMap; local lbl_map="$_JVAL"

  local html="<address>"
  html+="<h3>${legal}</h3>"

  html+="<div><img src=\"/img/address.png\" alt=\"${lbl_address}\"><p>"
  local _ra='^[[:space:]]*"(.*)"[[:space:],]*$'
  local in_addr=0 first=1
  while IFS= read -r line; do
    [[ "$line" == *'"address"'* ]] && { in_addr=1; continue; }
    [ $in_addr -eq 0 ] && continue
    [[ "$line" == *']'* ]] && break
    [[ "$line" =~ $_ra ]] || continue
    local v="${BASH_REMATCH[1]}"
    if [ -n "$v" ]; then
      [ $first -eq 0 ] && html+="<br>"
      html+="${v}"; first=0
    fi
  done <<< "$_cc"
  html+="</p></div>"

  html+="<a href=\"tel:${tel}\"><img src=\"/img/phone.png\" alt=\"${lbl_phone}\"><p>${phone}</p></a>"
  html+="<a href=\"mailto:${email}\"><img src=\"/img/email.png\" alt=\"${lbl_email}\"><p>${email}</p></a>"
  [ -n "$map" ] && html+="<a href=\"${map}\" target=\"_blank\"><img src=\"/img/map.png\" alt=\"${lbl_map}\"><p>${lbl_map}</p></a>"

  html+="</address>"
  printf '%s' "$html"
}

# --- Sitemap HTML Builder ---
build_sitemap_html() {
  json_label pages;    local lbl_pages="$_JVAL"
  json_label products; local lbl_products="$_JVAL"

  local html="<h3>${lbl_pages}</h3><ul>"
  local entries=""
  for pj in "$SETTINGS_DIR"/pages/*.json; do
    local name="${pj##*/}"; name="${name%.json}"
    { [ "$name" = "404" ] || [ "$name" = "index" ] || [ "$name" = "staff" ] || [ "$name" = "menu" ]; } && continue
    grep -q '"showInSitemap"[[:space:]]*:[[:space:]]*false' "$pj" && continue
    local _pc=$(<"$pj")
    jnum "$_pc" priority; local priority="${_JVAL:-0.6}"
    jstr "$_pc" title;    local short="${_JVAL%% |*}"
    local href
    if [[ ",$ROOT_PAGES," == *",$name,"* ]]; then
      href="/${name}.html"
    else
      href="/${PAGES_DIR}/${name}.html"
    fi
    entries+="${priority}|<li><a href='${href}'>${short}</a></li>"$'\n'
  done
  html+=$(echo "$entries" | sort -t'|' -k1 -rn | cut -d'|' -f2- | tr -d '\n')
  html+="</ul>"

  html+="<h3>${lbl_products}</h3><ul>"
  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
    jstr "$c" name; local name="$_JVAL"
    jstr "$c" url;  local url="$_JVAL"
    html+="<li><a href='/${PRODUCTS_DIR}/${url}.html'>${name}</a></li>"
  done
  html+="</ul>"

  # Filter pages — categories and tags sections
  if type build_filter_pages &>/dev/null && [ ${#FILTER_PAGE_CATS[@]} -gt 0 ]; then
    json_label categories; local lbl_cats="${_JVAL:-Categories}"
    html+="<h3>${lbl_cats}</h3><ul>"
    for entry in "${FILTER_PAGE_CATS[@]}"; do
      local furl="${entry%%|*}"
      local fname="${entry#*|}"
      html+="<li><a href='/${PAGES_DIR}/${furl}.html'>${fname}</a></li>"
    done
    html+="</ul>"
  fi
  if type build_filter_pages &>/dev/null && [ ${#FILTER_PAGE_TAGS[@]} -gt 0 ]; then
    json_label tags; local lbl_tags="${_JVAL:-Tags}"
    html+="<h3>${lbl_tags}</h3><ul>"
    for entry in "${FILTER_PAGE_TAGS[@]}"; do
      local furl="${entry%%|*}"
      local fname="${entry#*|}"
      html+="<li><a href='/${PAGES_DIR}/${furl}.html'>${fname}</a></li>"
    done
    html+="</ul>"
  fi

  printf '%s' "$html"
}

# --- Hero Builder ---
build_hero() {
  local data_key="$1"
  # Extract hero section once — 1 sed pass instead of 3×json_nested + separate lazy check
  local _hs
  _hs=$(sed -n '/"'"$data_key"'"[[:space:]]*:/,/^[[:space:]]*}/p' "$SITE_JSON")
  jstr "$_hs" img;       local hero_img="$_JVAL"
  jstr "$_hs" link;      local hero_link="$_JVAL"
  jstr "$_hs" link_text; local hero_btn="$_JVAL"
  local hero_lazy=""
  local _rl='"lazy"[[:space:]]*:[[:space:]]*true'
  [[ "$_hs" =~ $_rl ]] && hero_lazy="1"

  # Parse text array
  local hero_line1="" hero_line2=""
  local text_idx=0
  while IFS= read -r v || [ -n "$v" ]; do
    [ -z "$v" ] && continue
    [ $text_idx -eq 0 ] && hero_line1="$v"
    [ $text_idx -eq 1 ] && hero_line2="$v"
    text_idx=$((text_idx + 1))
  done < <(json_nested_array "$SITE_JSON" "$data_key" text)

  # Build img tag based on lazy flag — inline blur_src (no subprocess)
  local img_tag
  if [ "$hero_lazy" = "1" ]; then
    img_tag="<img src=\"/img/pages/${hero_img%.webp}-k.webp\" data-src=\"/img/pages/$hero_img\" loading=\"lazy\" alt=\"${hero_line1}\">"
  else
    img_tag="<img src=\"/img/pages/$hero_img\" alt=\"${hero_line1}\">"
  fi

  local tpl
  tpl=$(<"$TEMPLATE_DIR/partials/hero.html")
  render_template "$tpl" \
    "hero_img_tag" "$img_tag" \
    "hero_line1" "$hero_line1" \
    "hero_line2" "$hero_line2" \
    "hero_link" "$hero_link" \
    "hero_btn" "$hero_btn"
  printf '%s' "$_RENDERED"
}

# --- Product Cards Builder (plain — single category or no filter flags) ---
build_product_cards_plain() {
  json_label addToBasket; local addToBasket="$_JVAL"
  local html="<ul class=\"prd\">"
  local _rf='"isForMenu"[[:space:]]*:[[:space:]]*false'

  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
    [[ "$c" =~ $_rf ]] && continue

    jstr "$c" name;      local name="$_JVAL"
    jstr "$c" url;       local url="$_JVAL"
    jnum "$c" price;     local price="$_JVAL"
    jstr "$c" shortDesc; local shortDesc="$_JVAL"
    jimg "$c";           local img="$_JVAL"
    jstr "$c" id;        local id="$_JVAL"

    html+="<li>"
    html+="<a href=\"/${PRODUCTS_DIR}/${url}.html\">"
    html+="<img src=\"/img/products/${img%.webp}-k.webp\" data-src=\"/img/products/${img}\" loading=\"lazy\" alt=\"${L_BRAND} ${name}\" title=\"${L_BRAND} ${name}\">"
    html+="<h3>${name}</h3>"
    html+="</a>"
    html+="<b>${price} ${SITE_CURRENCY_SYMBOL}</b>"
    html+="<p>${shortDesc}</p>"
    html+="<button data-id=\"${id}\">${addToBasket}</button>"
    html+="</li>"
  done

  html+="</ul>"
  printf '%s' "$html"
}

# Dispatch wrapper — helper-filter.sh tarafından override edilebilir
build_product_cards() { build_product_cards_plain; }

# --- Tabs Builder ---
build_tabs() {
  local pj="$1"
  json_label productDescTab;  local lbl_desc="$_JVAL"
  json_label productSpecsTab; local lbl_specs="$_JVAL"

  local html='<input type="radio" id="tab-desc" name="ptab" checked>'
  html+='<input type="radio" id="tab-specs" name="ptab">'
  html+="<div class=\"tab-nav\"><label for=\"tab-desc\">${lbl_desc}</label><label for=\"tab-specs\">${lbl_specs}</label></div>"

  local _rl='^[[:space:]]*"(.*)"[[:space:],]*$'
  local _rn='"name"[[:space:]]*:[[:space:]]*"([^"]*)"'
  local _rv='"value"[[:space:]]*:[[:space:]]*"([^"]*)"'

  # Tab 1: longDesc paragraphs
  html+='<div class="tab-desc">'
  local in_long=0
  while IFS= read -r line; do
    [[ "$line" == *'"longDesc"'* ]] && { in_long=1; continue; }
    [ $in_long -eq 0 ] && continue
    [[ "$line" == *']'* ]] && break
    [[ "$line" =~ $_rl ]] && html+="<p>${BASH_REMATCH[1]}</p>"
  done < "$pj"
  html+='</div>'

  # Tab 2: otherDesc table
  html+='<div class="tab-specs"><table>'
  local in_other=0
  while IFS= read -r line; do
    [[ "$line" == *'"otherDesc"'* ]] && { in_other=1; continue; }
    [ $in_other -eq 0 ] && continue
    [[ "$line" == *']'* ]] && break
    local n="" v=""
    [[ "$line" =~ $_rn ]] && n="${BASH_REMATCH[1]}"
    [[ "$line" =~ $_rv ]] && v="${BASH_REMATCH[1]}"
    [ -n "$n" ] && html+="<tr><th>${n}</th><td>${v}</td></tr>"
  done < "$pj"
  html+='</table></div>'

  _TABS="$html"
}

# --- Partial Renderer ---
render_partial() {
  local partial_spec="$1" page_json="$2"
  local name="${partial_spec%%:*}"
  local data_key="${partial_spec#*:}"
  [ "$data_key" = "$name" ] && data_key=""

  local _pjc=$(<"$page_json")
  jstr "$_pjc" title; local page_short="${_JVAL%% |*}"

  case "$name" in
    hero)
      build_hero "$data_key"
      ;;
    contact)
      build_contact
      ;;
    product-cards)
      build_product_cards
      ;;
    product-cards-all)
      type build_product_cards_all &>/dev/null && build_product_cards_all
      ;;
    staff-form)
      type build_staff_form &>/dev/null && build_staff_form
      ;;
    sitemap-list)
      build_sitemap_html
      ;;
    campaign-strip)
      type build_campaigns_strip &>/dev/null && build_campaigns_strip
      ;;
    article-header)
      # isAllProductsPage uses h4 + slogan, others use h2 + short title
      local heading_tag="h2"
      local page_heading="$page_short"
      if json_flag "$page_json" isAllProductsPage; then
        heading_tag="h4"
        page_heading="$L_SLOGAN"
      fi
      printf '<article><%s>%s</%s>' "$heading_tag" "$page_heading" "$heading_tag"
      ;;
    page-image)
      # Only render if image file exists
      local pname="${page_json##*/}"; pname="${pname%.json}"
      if [ -f "$OUTPUT_DIR/img/pages/${pname}.webp" ]; then
        local tpl
        tpl=$(<"$TEMPLATE_DIR/partials/page-image.html")
        render_template "$tpl" \
          "name" "$pname" \
          "page_heading" "$page_short"
        printf '%s' "$_RENDERED"
      fi
      ;;
    parts)
      build_main "$page_json"
      ;;
    article-footer)
      printf '</article>'
      ;;
    *)
      local tpl_file="$TEMPLATE_DIR/partials/${name}.html"
      if [ -f "$tpl_file" ]; then
        local tpl
        tpl=$(<"$tpl_file")
        render_template "$tpl"
        printf '%s' "$_RENDERED"
      fi
      ;;
  esac
}

# --- Build Main Content from Partials ---
build_main_content() {
  local page_json="$1"
  local html=""
  local partials=$(tr '\n' ' ' < "$page_json" | sed -n 's/.*"partials"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p')

  if [ -z "$partials" ]; then
    return
  fi

  IFS=',' read -ra part_arr <<< "$partials"
  for p in "${part_arr[@]}"; do
    p=$(echo "$p" | tr -d '"[:space:]')
    html+=$(render_partial "$p" "$page_json")
  done
  printf '%s' "$html"
}
