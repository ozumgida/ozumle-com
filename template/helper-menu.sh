#!/bin/bash
# Helper functions for the Menu and Staff features.
# Sourced by update.sh when present; if absent, these features are silently skipped.

# --- Staff Form Builder ---
build_staff_form() {
  local menu_json="$SETTINGS_DIR/menu.json"
  local tpl_file="$TEMPLATE_DIR/partials/staff-form.html"
  [ ! -f "$tpl_file" ] && return
  local waiter_label="Waiter"
  local save_label="Save"
  if [ -f "$menu_json" ]; then
    waiter_label=$(json_val "$menu_json" waiterLabel)
    save_label=$(json_val "$menu_json" saveLabel)
  fi
  local tpl
  tpl=$(<"$tpl_file")
  render_template "$tpl" \
    "waiterLabel" "$waiter_label" \
    "saveLabel" "$save_label"
  printf '%s' "$_RENDERED"
}

# --- Product Cards Builder (unfiltered — for menu.html) ---
build_product_cards_all() {
  json_label addToBasket; local addToBasket="$_JVAL"
  local html="<ul class=\"prd\">"

  for pj in "$SETTINGS_DIR"/products/*.json; do
    local c=$(<"$pj")
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

# --- Build Menu Page ---
build_menu() {
  local menu_json="$SETTINGS_DIR/menu.json"
  if [ ! -f "$menu_json" ]; then
    if [ -f "$OUTPUT_DIR/menu.html" ]; then
      rm -f "$OUTPUT_DIR/menu.html"
      echo "menu.html removed (orphan)"
    fi
    return 0
  fi

  local _mj=$(<"$menu_json"); jstr "$_mj" title; local title="$_JVAL"
  local main_html=$(build_product_cards_all)
  local out_path=$(page_output_path "menu")

  apply_layout "$TEMPLATE_DIR/menu-layout.html" \
    "lang" "$SITE_LANG" \
    "title" "$title" \
    "slogan" "$L_SLOGAN" \
    "offline_warning" "$L_OFFLINE" \
    "main" "$main_html" \
    > "$out_path"

  echo "menu.html built"
}
