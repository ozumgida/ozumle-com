#!/bin/bash
# Shared helper functions for update.sh and process-template.sh

# --- Minifier ---
min() {
  sed 's/^ *//; s/ *$//; /^$/d; s/  */ /g' "$1"
}

# --- JSON Helpers ---
json_val() {
  sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
}

json_flag() {
  grep -q "\"$2\"[[:space:]]*:[[:space:]]*true" "$1"
}

json_num() {
  sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p' "$1" | head -1
}

json_img() {
  sed -n 's/.*"images"[[:space:]]*:[[:space:]]*\["\([^"]*\)".*/\1/p' "$1" | head -1
}

json_nested() {
  sed -n '/"'"$2"'"[[:space:]]*:/,/^[[:space:]]*}/p' "$1" \
    | sed -n 's/.*"'"$3"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

json_label() {
  _JVAL=""
  local _r="\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  [[ "$_LABELS_SECTION" =~ $_r ]] && _JVAL="${BASH_REMATCH[1]}"
}

# Read array items from a nested JSON section
# Usage: json_nested_array "file" "section" "key" → one value per line
json_nested_array() {
  sed -n '/"'"$2"'"[[:space:]]*:/,/^[[:space:]]*}/p' "$1" \
    | tr '\n' ' ' \
    | sed -n 's/.*"'"$3"'"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' \
    | tr ',' '\n' \
    | sed -n 's/.*"\([^"]*\)".*/\1/p'
}

# --- Pure-bash field extractors (no subprocess) ---
# Sets _JVAL; use as: jstr "$content" key; local x="$_JVAL"
jstr() { _JVAL=""; local _r="\"$2\"[[:space:]]*:[[:space:]]*\"([^\"]*)\"";   [[ "$1" =~ $_r ]] && _JVAL="${BASH_REMATCH[1]}"; }
jnum() { _JVAL=""; local _r="\"$2\"[[:space:]]*:[[:space:]]*([0-9.]+)";      [[ "$1" =~ $_r ]] && _JVAL="${BASH_REMATCH[1]}"; }
jimg() { _JVAL=""; local _r='"images"[[:space:]]*:[[:space:]]*\["([^"]*)';   [[ "$1" =~ $_r ]] && _JVAL="${BASH_REMATCH[1]}"; }

# --- Sed Safety ---
sed_safe() {
  local v="$1"
  v="${v//\\/\\\\}"
  v="${v//&/\\&}"
  v="${v//#/\\#}"
  v="${v//$'\n'/\\n}"
  v="${v//$'\r'/\\r}"
  v="${v//$'\t'/\\t}"
  printf '%s' "$v"
}

# --- Utility ---
blur_src() {
  local src="$1"
  printf '%s' "${src%.webp}-k.webp"
}

# --- Routing ---
is_root_page() {
  [[ ",$ROOT_PAGES," == *",$1,"* ]]
}

page_href() {
  local name="$1"
  if is_root_page "$name"; then
    printf '/%s.html' "$name"
  else
    printf '/%s/%s.html' "$PAGES_DIR" "$name"
  fi
}

page_output_path() {
  local name="$1"
  if is_root_page "$name"; then
    printf '%s/%s.html' "$OUTPUT_DIR" "$name"
  else
    printf '%s/%s/%s.html' "$OUTPUT_DIR" "$PAGES_DIR" "$name"
  fi
}

# --- Template Engine ---
render_template() {
  _RENDERED="$1"
  shift
  while [ $# -ge 2 ]; do
    local key="$1" val="$2"
    # Bash 5.2+: & and \ are special in replacement strings
    val="${val//\\/\\\\}"
    val="${val//&/\\&}"
    _RENDERED="${_RENDERED//\{\{$key\}\}/$val}"
    shift 2
  done
}

apply_layout() {
  local tpl_file="$1"
  shift
  local content
  content=$(<"$tpl_file")
  render_template "$content" "$@"
  printf '%s' "$_RENDERED"
}

# --- HTML Components ---
build_social_links() {
  local ig=$(json_val "$COMPANY_JSON" instagram)
  local fb=$(json_val "$COMPANY_JSON" facebook)
  local ln=$(json_val "$COMPANY_JSON" linkedin)
  local wa=$(json_val "$COMPANY_JSON" whatsapp | tr -d '+ ')
  local html=""
  [ -n "$ig" ] && [ "$ig" != "#" ] && html+="<a href=\"${ig}\" target=\"_blank\"><img src=\"/img/instagram.png\" alt=\"Instagram\"></a>"
  [ -n "$fb" ] && [ "$fb" != "#" ] && html+="<a href=\"${fb}\" target=\"_blank\"><img src=\"/img/facebook.png\" alt=\"Facebook\"></a>"
  [ -n "$ln" ] && [ "$ln" != "#" ] && html+="<a href=\"${ln}\" target=\"_blank\"><img src=\"/img/linkedin.png\" alt=\"LinkedIn\"></a>"
  [ -n "$wa" ] && html+="<a href=\"https://wa.me/${wa}\" target=\"_blank\"><img src=\"/img/whatsapp.png\" alt=\"WhatsApp\"></a>"
  printf '%s' "$html"
}

build_lang_nav() {
  _LANG_NAV=""
  local path="$1" html=""
  for i in "${!L_SWITCH_CODES[@]}"; do
    if [ "${L_SWITCH_CODES[$i]}" = "$SITE_LANG" ]; then
      html+="<b>${L_SWITCH_LABELS[$i]}</b>"
    else
      html+="<a href=\"${L_SWITCH_URLS[$i]}${path}\" hreflang=\"${L_SWITCH_CODES[$i]}\">${L_SWITCH_LABELS[$i]}</a>"
    fi
  done
  [ -n "$html" ] && _LANG_NAV='<span class="lang">'"${html}"'</span>'
}

parse_hreflangs() {
  L_HREFLANGS=""
  for i in "${!L_SWITCH_CODES[@]}"; do
    [ -n "$L_HREFLANGS" ] && L_HREFLANGS+=" "
    L_HREFLANGS+="${L_SWITCH_CODES[$i]}|${L_SWITCH_URLS[$i]}"
  done
}

build_seo_tags() {
  _SEO_TAGS=""
  local path="$1"
  for entry in $L_HREFLANGS; do
    local lang="${entry%%|*}"
    local domain="${entry#*|}"
    _SEO_TAGS+="<link rel=\"alternate\" hreflang=\"${lang}\" href=\"${domain}${path}\">"
  done
}

build_hmenu() {
  _HMENU=""
  local active="$1"
  for i in "${!L_MNAMES[@]}"; do
    local mname="${L_MNAMES[$i]}"
    local href
    if [[ ",$ROOT_PAGES," == *",$mname,"* ]]; then
      href="/${mname}.html"
    else
      href="/${PAGES_DIR}/${mname}.html"
    fi
    if [ "$mname" = "$active" ]; then
      _HMENU+="<a href=\"${href}\" class=\"active\">${L_MSHORTS[$i]}</a>"
    else
      _HMENU+="<a href=\"${href}\">${L_MSHORTS[$i]}</a>"
    fi
  done
}

# --- Schema Builders ---
# Builds additionalProperty JSON from product content string; sets _ADD_PROPS global
build_add_props() {
  _ADD_PROPS=""
  local first=1 in_other=0
  local _rn='"name"[[:space:]]*:[[:space:]]*"([^"]*)"'
  local _rv='"value"[[:space:]]*:[[:space:]]*"([^"]*)"'
  while IFS= read -r line; do
    [[ "$line" == *'"otherDesc"'* ]] && { in_other=1; continue; }
    [ $in_other -eq 0 ] && continue
    [[ "$line" =~ ^[[:space:]]*\] ]] && break
    [[ "$line" =~ $_rn ]] || continue
    local n="${BASH_REMATCH[1]}" v=""
    [[ "$line" =~ $_rv ]] && v="${BASH_REMATCH[1]}"
    [ $first -eq 0 ] && _ADD_PROPS+=","
    _ADD_PROPS+="{\"@type\":\"PropertyValue\",\"name\":\"${n}\",\"value\":\"${v}\"}"
    first=0
  done <<< "$1"
}

# Builds product JSON-LD schema; sets _SCHEMA global (no subshell needed at call site)
build_schema() {
  local pj="$1"
  local c=$(<"$pj")  # read once — bash builtin, no subprocess

  jstr "$c" id;       local id="$_JVAL"
  jstr "$c" name;     local name="$_JVAL"
  jstr "$c" metaDesc; local desc="$_JVAL"
  jstr "$c" url;      local url="$_JVAL"
  jstr "$c" keywords; local keys="$_JVAL"
  jnum "$c" price;    local price="$_JVAL"
  jimg "$c";          local img="$_JVAL"

  local wval=""
  local _rw='"weight"[^}]*"value"[[:space:]]*:[[:space:]]*([0-9]+)'
  [[ "$c" =~ $_rw ]] && wval="${BASH_REMATCH[1]}"

  # Use pre-cached company values from init_layout; override if product specifies
  local brand="$C_BRAND"     currency="$C_CURRENCY"  valid_until="$C_VALID_UNTIL"
  local mfr_name="$C_MFR_NAME" mfr_id="$C_MFR_ID"   mfr_phone="$C_MFR_PHONE"
  local mfr_addr="$C_MFR_ADDR" mfr_city="$C_MFR_CITY" mfr_country="$C_MFR_COUNTRY"

  jstr "$c" brand;    [ -n "$_JVAL" ] && brand="$_JVAL"
  jstr "$c" currency; [ -n "$_JVAL" ] && currency="$_JVAL"
  jnum "$c" priceValidUntilDays
  if [ -n "$_JVAL" ]; then
    valid_until=$(date -d "+${_JVAL} days" +%Y-%m-%d)
  fi

  # Manufacturer override — single sed pass only if product defines it
  if [[ "$c" =~ \"manufacturer\" ]]; then
    local mfr_sec
    mfr_sec=$(sed -n '/"manufacturer"/,/^[[:space:]]*}/p' "$pj")
    jstr "$mfr_sec" name;       [ -n "$_JVAL" ] && mfr_name="$_JVAL"
    jstr "$mfr_sec" identifier; [ -n "$_JVAL" ] && mfr_id="$_JVAL"
    jstr "$mfr_sec" phone;      [ -n "$_JVAL" ] && mfr_phone="$_JVAL"
    jstr "$mfr_sec" address;    [ -n "$_JVAL" ] && mfr_addr="$_JVAL"
    jstr "$mfr_sec" city;       [ -n "$_JVAL" ] && mfr_city="$_JVAL"
    jstr "$mfr_sec" country;    [ -n "$_JVAL" ] && mfr_country="$_JVAL"
  fi

  local schema_domain="${SITE_DOMAIN#https://}"
  schema_domain="${schema_domain#http://}"

  local s='{"@context":"https://schema.org/","@type":"Product"'
  s+=',"name":"'"${brand} ${name}"'"'
  s+=',"productID":"'"${id}"'"'
  s+=',"description":"'"${desc}"'"'
  s+=',"url":"'"${schema_domain}/${PRODUCTS_DIR}/${url}"'.html"'
  s+=',"image":"'"${schema_domain}/images/${img}"'"'
  s+=',"brand":{"@type":"Brand","name":"'"${brand}"'"}'
  s+=',"manufacturer":{"@type":"Organization","name":"'"${mfr_name}"'","identifier":"'"${mfr_id}"'"'
  s+=',"contactPoint":{"@type":"ContactPoint","telephone":"'"${mfr_phone}"'","contactType":"customer service"}'
  s+=',"address":{"@type":"PostalAddress","streetAddress":"'"${mfr_addr}"'","addressLocality":"'"${mfr_city}"'","addressCountry":"'"${mfr_country}"'"}}'
  s+=',"keywords":"'"${keys}"'"'
  [ -n "$wval" ] && s+=',"weight":{"@type":"QuantitativeValue","value":'"${wval}"',"unitCode":"GRM"}'

  build_add_props "$c"
  [ -n "$_ADD_PROPS" ] && s+=',"additionalProperty":['"${_ADD_PROPS}"']'

  s+=',"offers":{"@type":"Offer"'
  s+=',"url":"'"${schema_domain}/${PRODUCTS_DIR}/${url}"'.html"'
  s+=',"priceCurrency":"'"${currency}"'"'
  s+=',"price":"'"${price}"'"'
  s+=',"priceValidUntil":"'"${valid_until}"'"'
  s+=',"itemCondition":"https://schema.org/NewCondition"'
  s+=',"availability":"https://schema.org/InStock"}'

  if [[ "$c" =~ \"aggregateRating\" ]]; then
    local ar_sec
    ar_sec=$(sed -n '/"aggregateRating"/,/^[[:space:]]*}/p' "$pj")
    jstr "$ar_sec" ratingValue; local ar_val="$_JVAL"
    jstr "$ar_sec" reviewCount; local ar_count="$_JVAL"
    if [ -n "$ar_val" ] && [ -n "$ar_count" ]; then
      jstr "$ar_sec" bestRating;  local ar_best="$_JVAL"
      jstr "$ar_sec" worstRating; local ar_worst="$_JVAL"
      s+=',"aggregateRating":{"@type":"AggregateRating"'
      s+=',"ratingValue":"'"${ar_val}"'","reviewCount":"'"${ar_count}"'"'
      s+=',"bestRating":"'"${ar_best}"'","worstRating":"'"${ar_worst}"'"}'
    fi
  fi

  if [[ "$c" =~ \"review\" ]]; then
    local rv_sec
    rv_sec=$(sed -n '/"review"/,/^[[:space:]]*}/p' "$pj")
    jstr "$rv_sec" author; local rv_author="$_JVAL"
    if [ -n "$rv_author" ]; then
      jstr "$rv_sec" ratingValue; local rv_val="$_JVAL"
      jstr "$rv_sec" date;        local rv_date="$_JVAL"
      jstr "$rv_sec" body;        local rv_body="$_JVAL"
      s+=',"review":{"@type":"Review"'
      s+=',"reviewRating":{"@type":"Rating","ratingValue":"'"${rv_val}"'"}'
      s+=',"author":{"@type":"Person","name":"'"${rv_author}"'"}'
      s+=',"datePublished":"'"${rv_date}"'"'
      s+=',"reviewBody":"'"${rv_body}"'"}'
    fi
  fi

  s+='}'
  _SCHEMA="$s"
}

build_home_schema() {
  local _cc=$(<"$COMPANY_JSON")

  jstr "$_cc" phone;       local phone="$_JVAL"
  local tel="${phone//[+ ]/}"
  jstr "$_cc" email;       local email="$_JVAL"
  jstr "$_cc" legalName;   local legal="$_JVAL"
  jstr "$_cc" description; local desc="$_JVAL"
  local brand="$C_BRAND"
  jstr "$_cc" country;     local country="${_JVAL:-TR}"

  local addr="" in_addr=0
  local _ra='^[[:space:]]*"(.*)"[[:space:],]*$'
  while IFS= read -r line; do
    [[ "$line" == *'"address"'* ]] && { in_addr=1; continue; }
    [ $in_addr -eq 0 ] && continue
    [[ "$line" == *']'* ]] && break
    [[ "$line" =~ $_ra ]] || continue
    local v="${BASH_REMATCH[1]}"
    [ -n "$v" ] && { [ -n "$addr" ] && addr+=", "; addr+="$v"; }
  done <<< "$_cc"

  jstr "$_cc" instagram; local ig="$_JVAL"
  local sameAs=""
  [ -n "$ig" ] && [ "$ig" != "#" ] && sameAs+="\"${ig}\""

  local s='{"@context":"https://schema.org","@graph":['

  s+='{"@type":"Organization"'
  s+=',"name":"'"${legal}"'"'
  s+=',"url":"'"${SITE_DOMAIN}"'"'
  s+=',"logo":"'"${SITE_DOMAIN}/logo.png"'"'
  s+=',"description":"'"${desc}"'"'
  s+=',"brand":{"@type":"Brand","name":"'"${brand}"'"}'
  s+=',"telephone":"'"${tel}"'"'
  s+=',"email":"'"${email}"'"'
  s+=',"address":{"@type":"PostalAddress","streetAddress":"'"${addr}"'","addressCountry":"'"${country}"'"}'
  [ -n "$sameAs" ] && s+=',"sameAs":['"${sameAs}"']'
  s+='}'

  s+=',{"@type":"WebSite"'
  s+=',"name":"'"${brand}"'"'
  s+=',"url":"'"${SITE_DOMAIN}"'"}'

  # Use pre-computed schema cache — no $(build_schema) subshells
  local ctx_prefix='{"@context":"https://schema.org/",'
  s+=',{"@type":"ItemList","itemListElement":['
  local pos=0 first=1
  for pj in "$SETTINGS_DIR"/products/*.json; do
    pos=$((pos + 1))
    [ $first -eq 0 ] && s+=","
    first=0
    local ps="${_SCHEMA_CACHE[$pj]}"
    ps="{${ps#"$ctx_prefix"}"  # strip @context — pure bash, no subprocess
    s+='{"@type":"ListItem","position":'"${pos}"',"item":'"${ps}"'}'
  done
  s+=']}]}'

  printf '%s' "$s"
}

write_html_page() {
  local out_path="$1" title="$2" desc="$3" keys="$4"
  local canonical="$5" hreflang="$6" lang_nav="$7"
  local nav="$8" main="$9" extra="${10}"
  apply_layout "$TEMPLATE_DIR/layout.html" \
    "lang" "$SITE_LANG" \
    "title" "$title" \
    "description" "$desc" \
    "keywords" "$keys" \
    "canonical" "$canonical" \
    "hreflang" "$hreflang" \
    "lang_nav" "$lang_nav" \
    "nav" "$nav" \
    "main" "$main" \
    "offline_warning" "$L_OFFLINE" \
    "social" "$L_SOCIAL" \
    "email" "$L_EMAIL" \
    "copyright" "${L_LEGAL} © ${L_YEAR}" \
    "footer_nav" "$L_FNAV" \
    "slogan" "$L_SLOGAN" \
    "extra_scripts" "$extra" \
    > "$out_path"
}
