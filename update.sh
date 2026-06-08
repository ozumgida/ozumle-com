#!/bin/bash

TEMPLATE_DIR="template"
SETTINGS_DIR="settings"
OUTPUT_DIR="."

cd "$(dirname "$0")"
source "$TEMPLATE_DIR/helper.sh"
source "$TEMPLATE_DIR/helper-template.sh"
[ -f "$TEMPLATE_DIR/helper-menu.sh" ] && source "$TEMPLATE_DIR/helper-menu.sh"
[ -f "$TEMPLATE_DIR/helper-filter.sh" ] && source "$TEMPLATE_DIR/helper-filter.sh"
[ -f "$TEMPLATE_DIR/helper-campaign.sh" ] && source "$TEMPLATE_DIR/helper-campaign.sh"

declare -A _SCHEMA_CACHE

# --- Settings ---
SITE_JSON="$SETTINGS_DIR/site.json"
COMPANY_JSON="$SETTINGS_DIR/company.json"

# Read settings files once — no subprocess per field
_TMP_SC=$(<"$SITE_JSON")
_TMP_CC=$(<"$COMPANY_JSON")
jstr "$_TMP_SC" domain;         SITE_DOMAIN="$_JVAL"
jstr "$_TMP_SC" cachePrefix;    SITE_CACHE_PREFIX="$_JVAL"
jstr "$_TMP_SC" lang;           SITE_LANG="$_JVAL"
jstr "$_TMP_CC" currencySymbol; SITE_CURRENCY_SYMBOL="$_JVAL"
jstr "$_TMP_SC" pagesDir;       PAGES_DIR="$_JVAL"
[ -z "$PAGES_DIR" ] && PAGES_DIR="pages"
jstr "$_TMP_SC" productsDir;    PRODUCTS_DIR="$_JVAL"
[ -z "$PRODUCTS_DIR" ] && PRODUCTS_DIR="products"
# rootPages — bash regex on preloaded content (matches across newlines via [^]]*)
_RR='"rootPages"[[:space:]]*:[[:space:]]*\[([^]]*)\]'
[[ "$_TMP_SC" =~ $_RR ]] && { ROOT_PAGES="${BASH_REMATCH[1]//\"/}"; ROOT_PAGES="${ROOT_PAGES//[[:space:]]/}"; }
unset _TMP_SC _TMP_CC _RR

# --- Sitemap XML ---
build_sitemap_xml() {
  local xml='<?xml version="1.0" encoding="UTF-8"?>'
  xml+='<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

  local _ipc=$(<"$SETTINGS_DIR/pages/index.json"); jnum "$_ipc" priority; local idx_priority="${_JVAL:-1.0}"
  xml+="<url><loc>${SITE_DOMAIN}/</loc><priority>${idx_priority}</priority></url>"

  local entries=""
  for pj in "$SETTINGS_DIR"/pages/*.json; do
    local name="${pj##*/}"; name="${name%.json}"
    { [ "$name" = "404" ] || [ "$name" = "index" ] || [ "$name" = "staff" ] || [ "$name" = "menu" ]; } && continue
    grep -q '"showInSitemap"[[:space:]]*:[[:space:]]*false' "$pj" && continue
    local _pc=$(<"$pj"); jnum "$_pc" priority; local priority="${_JVAL:-0.6}"
    entries+="${priority}|<url><loc>${SITE_DOMAIN}/${PAGES_DIR}/${name}.html</loc><priority>${priority}</priority></url>"$'\n'
  done
  xml+=$(echo "$entries" | sort -t'|' -k1 -rn | cut -d'|' -f2-)

  local _rf='"isForMenu"[[:space:]]*:[[:space:]]*false'
  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
    [[ "$c" =~ $_rf ]] && continue
    jstr "$c" url; local url="$_JVAL"
    xml+="<url><loc>${SITE_DOMAIN}/${PRODUCTS_DIR}/${url}.html</loc><priority>0.8</priority></url>"
  done

  # Filter pages (categories + tags) — populated by build_filter_pages
  if type build_filter_pages &>/dev/null; then
    for entry in "${FILTER_PAGE_CATS[@]}" "${FILTER_PAGE_TAGS[@]}"; do
      local furl="${entry%%|*}"
      xml+="<url><loc>${SITE_DOMAIN}/${PAGES_DIR}/${furl}.html</loc><priority>0.5</priority></url>"
    done
  fi

  xml+='</urlset>'
  printf '%s' "$xml" > "$OUTPUT_DIR/sitemap.xml"
  echo "sitemap.xml built"
}

# --- Init Layout ---
init_layout() {
  local _cc=$(<"$COMPANY_JSON")
  local _sc=$(<"$SITE_JSON")

  jstr "$_cc" email;          L_EMAIL="$_JVAL"
  jstr "$_cc" legalName;      L_LEGAL="$_JVAL"
  jstr "$_cc" slogan;         L_SLOGAN="$_JVAL"
  jstr "$_cc" phone;          L_PHONE="$_JVAL"
  L_YEAR=$(date +%Y)
  jstr "$_sc" offlineWarning; L_OFFLINE="$_JVAL"
  jstr "$_cc" brand;          L_BRAND="$_JVAL"

  # Pre-cache company schema fields (used by build_schema for every product)
  jstr "$_cc" currency;            C_CURRENCY="$_JVAL"
  jnum "$_cc" priceValidUntilDays; C_PVDAYS="${_JVAL:-180}"
  C_BRAND="$L_BRAND"
  C_VALID_UNTIL=$(date -d "+${C_PVDAYS} days" +%Y-%m-%d)
  # Extract manufacturer block once — 1 sed pass instead of 6
  local _mfr_sec
  _mfr_sec=$(sed -n '/"manufacturer"/,/^[[:space:]]*}/p' "$COMPANY_JSON")
  jstr "$_mfr_sec" name;       C_MFR_NAME="$_JVAL"
  jstr "$_mfr_sec" identifier; C_MFR_ID="$_JVAL"
  jstr "$_mfr_sec" phone;      C_MFR_PHONE="$_JVAL"
  jstr "$_mfr_sec" address;    C_MFR_ADDR="$_JVAL"
  jstr "$_mfr_sec" city;       C_MFR_CITY="$_JVAL"
  jstr "$_mfr_sec" country;    C_MFR_COUNTRY="$_JVAL"

  # Pre-cache labels section for zero-cost json_label calls
  _LABELS_SECTION=$(sed -n '/"labels"[[:space:]]*:/,/^[[:space:]]*}/p' "$SITE_JSON")

  # Pre-parse langSwitch entries (used by build_lang_nav and parse_hreflangs)
  L_SWITCH_CODES=(); L_SWITCH_LABELS=(); L_SWITCH_URLS=()
  local _in_sw=0 _sw_label="" _sw_url="" _sw_code=""
  while IFS= read -r line; do
    [[ "$line" == *'"langSwitch"'* ]] && { _in_sw=1; continue; }
    [ $_in_sw -eq 0 ] && continue
    [[ "$line" =~ ^[[:space:]]*\] ]] && { _in_sw=0; break; }
    jstr "$line" label; [ -n "$_JVAL" ] && _sw_label="$_JVAL"
    jstr "$line" url;   [ -n "$_JVAL" ] && _sw_url="$_JVAL"
    jstr "$line" lang;  [ -n "$_JVAL" ] && _sw_code="$_JVAL"
    if [[ "$line" == *"}"* ]] && [ -n "$_sw_label" ]; then
      L_SWITCH_CODES+=("$_sw_code")
      L_SWITCH_LABELS+=("$_sw_label")
      L_SWITCH_URLS+=("$_sw_url")
      _sw_label="" _sw_url="" _sw_code=""
    fi
  done <<< "$_sc"

  parse_hreflangs

  # Social links — inline to avoid $(build_social_links) subshell
  jstr "$_cc" whatsapp;  local _wa="${_JVAL//[+ ]/}"
  jstr "$_cc" instagram; local _ig="$_JVAL"
  jstr "$_cc" facebook;  local _fb="$_JVAL"
  jstr "$_cc" linkedin;  local _ln="$_JVAL"
  jstr "$_cc" telegram;  local _tg="${_JVAL#@}"
  L_SOCIAL=""
  [ -n "$_ig" ] && [ "$_ig" != "#" ] && L_SOCIAL+="<a href=\"${_ig}\" target=\"_blank\"><img src=\"/img/instagram.png\" alt=\"Instagram\"></a>"
  [ -n "$_fb" ] && [ "$_fb" != "#" ] && L_SOCIAL+="<a href=\"${_fb}\" target=\"_blank\"><img src=\"/img/facebook.png\" alt=\"Facebook\"></a>"
  [ -n "$_ln" ] && [ "$_ln" != "#" ] && L_SOCIAL+="<a href=\"${_ln}\" target=\"_blank\"><img src=\"/img/linkedin.png\" alt=\"LinkedIn\"></a>"
  [ -n "$_wa" ] && L_SOCIAL+="<a href=\"https://wa.me/${_wa}\" target=\"_blank\"><img src=\"/img/whatsapp.png\" alt=\"WhatsApp\"></a>"
  [ -n "$_tg" ] && [ "$_tg" != "#" ] && L_SOCIAL+="<a href=\"https://t.me/${_tg}\" target=\"_blank\"><img src=\"/img/telegram.png\" alt=\"Telegram\"></a>"

  L_FNAV=""
  L_MNAMES=()
  L_MSHORTS=()
  for pj in "$SETTINGS_DIR"/pages/*.json; do
    local pname="${pj##*/}"; pname="${pname%.json}"
    local _pc=$(<"$pj")
    jstr "$_pc" title; local short="${_JVAL%% |*}"
    local href
    if [[ ",$ROOT_PAGES," == *",$pname,"* ]]; then
      href="/${pname}.html"
    else
      href="/${PAGES_DIR}/${pname}.html"
    fi
    json_flag "$pj" showOnFooter && L_FNAV+="<a href=\"${href}\">${short}</a>"
    json_flag "$pj" showOnHeaderMenu && { L_MNAMES+=("$pname"); L_MSHORTS+=("$short"); }
  done
}

# --- Build Pages ---
build_pages() {
  mkdir -p "$OUTPUT_DIR/$PAGES_DIR"

  for pj in "$SETTINGS_DIR"/pages/*.json; do
    local name="${pj##*/}"; name="${name%.json}"
    local _pc=$(<"$pj")
    jstr "$_pc" title;       local title="$_JVAL"
    jstr "$_pc" description; local desc="$_JVAL"
    jstr "$_pc" keywords;    local keys="$_JVAL"
    build_hmenu "$name"; local hmenu="$_HMENU"
    local main_html=$(build_main_content "$pj")

    local out_path seo_path
    if [[ ",$ROOT_PAGES," == *",$name,"* ]]; then
      out_path="${OUTPUT_DIR}/${name}.html"
      seo_path="/${name}.html"
    else
      out_path="${OUTPUT_DIR}/${PAGES_DIR}/${name}.html"
      seo_path="/${PAGES_DIR}/${name}.html"
    fi
    [ "$name" = "index" ] && seo_path="/"
    local canonical="${SITE_DOMAIN}${seo_path}"
    build_seo_tags "$seo_path"; local hreflang="$_SEO_TAGS"
    build_lang_nav "$seo_path"; local lang_nav="$_LANG_NAV"

    local extra=""
    if [ "$name" = "index" ]; then
      local schema=$(build_home_schema)
      extra=$'\n    '"<script type=\"application/ld+json\">${schema}</script>"
    fi

    write_html_page "$out_path" "$title" "$desc" "$keys" "$canonical" "$hreflang" "$lang_nav" "$hmenu" "$main_html" "$extra"
  done

  echo "pages built"
}

# --- Cleanup Orphan Pages ---
# Removes html outputs that no longer have a matching json (or whose routing changed).
cleanup_orphan_pages() {
  if [ -d "$OUTPUT_DIR/$PAGES_DIR" ]; then
    for f in "$OUTPUT_DIR/$PAGES_DIR"/*.html; do
      [ -f "$f" ] || continue
      local name="${f##*/}"; name="${name%.html}"
      if [ ! -f "$SETTINGS_DIR/pages/${name}.json" ]; then
        rm -f "$f"
        echo "${PAGES_DIR}/${name}.html removed (orphan)"
      fi
    done
  fi

  for f in "$OUTPUT_DIR"/*.html; do
    [ -f "$f" ] || continue
    local name="${f##*/}"; name="${name%.html}"
    case "$name" in
      menu|campaigns) continue ;;
    esac
    if [ ! -f "$SETTINGS_DIR/pages/${name}.json" ] || [[ ",$ROOT_PAGES," != *",$name,"* ]]; then
      rm -f "$f"
      echo "${name}.html removed (orphan)"
    fi
  done
}

# --- Build Products (E6) ---
build_products() {
  json_label addToBasket; local addToBasket="$_JVAL"
  local _st=$(<"$SITE_JSON"); jstr "$_st" taxIncluded; local taxIncluded="$_JVAL"
  build_hmenu ""; local hmenu="$_HMENU"

  mkdir -p "$OUTPUT_DIR/$PRODUCTS_DIR"

  local product_tpl
  product_tpl=$(<"$TEMPLATE_DIR/partials/product.html")

  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
    jstr "$c" id;       local id="$_JVAL"
    jstr "$c" name;     local name="$_JVAL"
    jstr "$c" url;      local url="$_JVAL"
    jnum "$c" price;    local price="$_JVAL"
    jstr "$c" metaDesc; local desc="$_JVAL"
    jstr "$c" keywords; local keys="$_JVAL"
    jimg "$c";          local img="$_JVAL"
    local title="${L_BRAND} ${name} | ${L_BRAND}"

    local seo_path="/${PRODUCTS_DIR}/${url}.html"
    local canonical="${SITE_DOMAIN}${seo_path}"
    build_seo_tags "$seo_path"; local hreflang="$_SEO_TAGS"
    build_lang_nav "$seo_path"; local lang_nav="$_LANG_NAV"

    local schema="${_SCHEMA_CACHE[$pj]}"

    local meta_tags=""
    type build_product_meta_tags &>/dev/null && json_flag "$SITE_JSON" isFiltering \
      && meta_tags=$(build_product_meta_tags "$c")

    build_tabs "$pj"; local tabs="$_TABS"

    local blur="${img%.webp}-k.webp"

    render_template "$product_tpl" \
      "product_img" "$img" \
      "product_blur" "$blur" \
      "product_full_name" "${L_BRAND} ${name}" \
      "product_id" "$id" \
      "product_name" "$name" \
      "product_price" "$price" \
      "currency_symbol" "$SITE_CURRENCY_SYMBOL" \
      "tax_label" "$taxIncluded" \
      "add_to_basket" "$addToBasket" \
      "tabs" "$tabs" \
      "product_meta_tags" "$meta_tags"
    local product_html="$_RENDERED"

    local schema_script=$'\n    '"<script type=\"application/ld+json\">${schema}</script>"

    write_html_page "$OUTPUT_DIR/$PRODUCTS_DIR/${url}.html" "$title" "$desc" "$keys" "$canonical" "$hreflang" "$lang_nav" "$hmenu" "$product_html" "$schema_script"
  done

  echo "products built"
}

# --- Service Worker Builder ---
build_sw() {
  local core="\"/\",\"/site.css\",\"/site.js\",\"/logo.png\",\"/favicon.png\",\"/favicon.ico\""

  local products=""
  for f in "$OUTPUT_DIR/$PRODUCTS_DIR"/*.html; do
    [ -f "$f" ] && products+=",\"/${PRODUCTS_DIR}/${f##*/}\""
  done
  for f in "$OUTPUT_DIR"/img/products/*.webp; do
    [ -f "$f" ] && products+=",\"/img/products/${f##*/}\""
  done
  products=${products#,}

  local pages=""
  for f in "$OUTPUT_DIR/$PAGES_DIR"/*.html; do
    [ -f "$f" ] && pages+=",\"/${PAGES_DIR}/${f##*/}\""
  done
  pages+=",\"/index.html\",\"/404.html\""
  for f in "$OUTPUT_DIR"/img/*.png; do
    [ -f "$f" ] && pages+=",\"/img/${f##*/}\""
  done
  for f in "$OUTPUT_DIR"/img/pages/*.webp; do
    [ -f "$f" ] && pages+=",\"/img/pages/${f##*/}\""
  done
  for f in "$OUTPUT_DIR"/img/campaign/*; do
    [ -f "$f" ] && pages+=",\"/img/campaign/${f##*/}\""
  done
  pages=${pages#,}

  local version=$(date +%Y%m%d%H%M%S)

  sed \
    -e "s#__CACHE_PREFIX__#${SITE_CACHE_PREFIX}#" \
    -e "s#__CORE__#[${core}]#" \
    -e "s#__PRODUCTS__#[${products}]#" \
    -e "s#__PAGES__#[${pages}]#" \
    -e "s#__VERSION__#${version}#" \
    "$TEMPLATE_DIR/js/sw.js" > "$OUTPUT_DIR/sw.js"

  echo "sw.js built"
}

# --- Schema Pre-computation ---
precompute_schemas() {
  for pj in "$SETTINGS_DIR"/products/*.json; do
    build_schema "$pj"
    _SCHEMA_CACHE["$pj"]="$_SCHEMA"
  done
  echo "schemas precomputed"
}

# --- Product Catalog Injection ---
inject_product_catalog() {
  local js="let PRODUCTS={"
  local first=1
  local _rw='"weight"[^}]*"value"[[:space:]]*:[[:space:]]*([0-9]+)'
  local _rf='"isForMenu"[[:space:]]*:[[:space:]]*false'

  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
    local menuOnly=0
    [[ "$c" =~ $_rf ]] && menuOnly=1
    jstr "$c" id;    local id="$_JVAL"
    jstr "$c" name;  local name="$_JVAL"
    jnum "$c" price; local price="$_JVAL"
    jimg "$c";       local img="$_JVAL"
    local wval=0
    [[ "$c" =~ $_rw ]] && wval="${BASH_REMATCH[1]}"

    [ $first -eq 0 ] && js+=","
    js+="\"${id}\":{\"name\":\"${name}\",\"price\":${price},\"weight\":${wval},\"img\":\"${img}\""
    [ $menuOnly -eq 1 ] && js+=",\"ord\":0"
    js+="}"
    first=0
  done

  js+="};"
  sed -i "s#let PRODUCTS = {};#$(sed_safe "$js")#" "$OUTPUT_DIR/site.js"
  echo "product catalog injected"
}

# --- Basket Config Injection ---
inject_basket_config() {
  local _sc=$(<"$SITE_JSON")
  local payment_options_json="[]"
  local _rpa='"paymentOptions"[[:space:]]*:[[:space:]]*(\[[^]]*\])'
  [[ "$_sc" =~ $_rpa ]] && payment_options_json="${BASH_REMATCH[1]}"
  local _cc=$(<"$COMPANY_JSON")
  jstr "$_cc" timezone; local site_timezone="$_JVAL"
  jstr "$_sc" basketWarning;   local warning="$_JVAL"
  jstr "$_sc" whatsAppWarning; local wa_warning="$_JVAL"
  jstr "$_sc" shippingWarning; local shipping_warning="$_JVAL"
  jstr "$_cc" phone;           local _phone="$_JVAL"
  jstr "$_cc" whatsapp;        local _wa_raw="$_JVAL"; local wa_number="${_wa_raw//[+ ]/}"
  jstr "$_cc" telegram;        local _tg_raw="$_JVAL"; local tg_username="${_tg_raw#@}"
  warning="${warning//\{\{phone\}\}/${_phone}}"
  wa_warning="${wa_warning//\{\{phone\}\}/${_phone}}"
  shipping_warning="${shipping_warning//\{\{phone\}\}/${_phone}}"

  jstr "$_sc" productsPage; local products_page="$_JVAL"
  if [ -z "$products_page" ]; then
    for pj in "$SETTINGS_DIR"/pages/*.json; do
      if json_flag "$pj" isAllProductsPage; then
        local _pn="${pj##*/}"; _pn="${_pn%.json}"
        if [[ ",$ROOT_PAGES," == *",$_pn,"* ]]; then
          products_page="/${_pn}.html"
        else
          products_page="/${PAGES_DIR}/${_pn}.html"
        fi
        break
      fi
    done
  fi

  local is_basket_desc="false"
  json_flag "$SITE_JSON" isBasketDesc && is_basket_desc="true"

  local js="let BASKET_CONFIG={"
  js+="\"warning\":\"${warning}\""
  js+=",\"waWarning\":\"${wa_warning}\""
  js+=",\"shippingWarning\":\"${shipping_warning}\""
  js+=",\"isBasketDesc\":${is_basket_desc}"
  js+=",\"paymentOptions\":${payment_options_json}"
  js+=",\"currency\":\"${SITE_CURRENCY_SYMBOL}\""
  js+=",\"waNumber\":\"${wa_number}\""
  js+=",\"productsPage\":\"${products_page}\""
  if json_flag "$SITE_JSON" isTelegramOrder; then
    if [ -n "$tg_username" ] && [ "$tg_username" != "#" ]; then
      js+=",\"tgUsername\":\"${tg_username}\""
    else
      echo ""
      echo "WARNING: isTelegramOrder is true but company telegram info should be added"
      echo ""
    fi
  fi

  if [ -n "$site_timezone" ]; then
    js+=",\"timezone\":\"${site_timezone}\""
  fi

  # Build labels object
  js+=",\"labels\":{"
  local first=1
  local label_keys="addToBasket basket myBasket itemSuffix for openBasket closeBasket subtotal shipping freeShipping total delete unit whatsAppOrder whatsAppGreeting telegramOrder telegramGreeting emptyBasket productsLinkText emptyBasketDesc waiterLabel tableLabel basketDescPlaceholder basketDescTooltip paymentLabel noteLabel happyHourTimezoneWarning discountProgressPrefix discountProgressSuffix notForOnlineOrder"
  for k in $label_keys; do
    json_label "$k"; local v="$_JVAL"
    if [ -n "$v" ]; then
      [ $first -eq 0 ] && js+=","
      js+="\"${k}\":\"${v}\""
      first=0
    fi
  done
  js+="}}"

  sed -i "s#let BASKET_CONFIG = {};#$(sed_safe "$js");#" "$OUTPUT_DIR/site.js"
  echo "basket config injected"
}

# ============================================
# MAIN EXECUTION (E5: preserved order)
# ============================================

bash "$TEMPLATE_DIR/process-template.sh" "$TEMPLATE_DIR" "$SETTINGS_DIR" "$OUTPUT_DIR" \
  || { echo "ERROR: process-template.sh failed"; exit 1; }

grep -q 'let PRODUCTS = {};' "$OUTPUT_DIR/site.js" \
  || { echo "ERROR: PRODUCTS placeholder missing in site.js"; exit 1; }
grep -q 'let BASKET_CONFIG = {};' "$OUTPUT_DIR/site.js" \
  || { echo "ERROR: BASKET_CONFIG placeholder missing in site.js"; exit 1; }
grep -q 'let CAMPAIGN_CONFIG = \[\];' "$OUTPUT_DIR/site.js" \
  || { echo "ERROR: CAMPAIGN_CONFIG placeholder missing in site.js"; exit 1; }

inject_product_catalog
init_layout
inject_basket_config
precompute_schemas
type build_menu &>/dev/null && build_menu
type inject_campaign_config &>/dev/null && inject_campaign_config
type build_campaigns_html &>/dev/null && build_campaigns_html
build_pages
cleanup_orphan_pages
build_products
type build_filter_pages &>/dev/null && build_filter_pages
build_sitemap_xml
build_sw
