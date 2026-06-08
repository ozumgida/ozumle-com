#!/bin/bash

TEMPLATE_DIR="${1:-template}"
SETTINGS_DIR="${2:-settings}"
OUTPUT_DIR="${3:-.}"

cd "$(dirname "$0")"
cd ..
source "$TEMPLATE_DIR/helper.sh"

dir=$(basename "$TEMPLATE_DIR")
if [ "$dir" != "template" ] && [ "$dir" != "$TEMPLATE_DIR" ]; then
  :
fi

if [ -d "$TEMPLATE_DIR/img" ]; then
  mkdir -p "$OUTPUT_DIR/img"
  cp -r "$TEMPLATE_DIR/img/." "$OUTPUT_DIR/img/"
  rm -rf "$TEMPLATE_DIR/img"
  echo "img moved to site root"
fi

SITE_JSON="$SETTINGS_DIR/site.json"

build_css() {
  local css_output=$(json_nested "$SITE_JSON" assets cssOutput)
  [ -z "$css_output" ] && css_output="site.css"
  local files=$(json_nested_array "$SITE_JSON" assets css)
  {
    if [ -n "$files" ]; then
      while IFS= read -r f; do
        [ -n "$f" ] && min "$TEMPLATE_DIR/$f"
      done <<< "$files"
    else
      min "$TEMPLATE_DIR/css/base.css"
      min "$TEMPLATE_DIR/css/layout.css"
      min "$TEMPLATE_DIR/css/page.css"
      min "$TEMPLATE_DIR/css/product.css"
      min "$TEMPLATE_DIR/css/basket.css"
    fi
  } > "$OUTPUT_DIR/$css_output"

  echo "css merged"
}

build_js() {
  local js_output=$(json_nested "$SITE_JSON" assets jsOutput)
  [ -z "$js_output" ] && js_output="site.js"
  {
    # Include shipping.js from settings (customer-editable)
    [ -f "$SETTINGS_DIR/shipping.js" ] && min "$SETTINGS_DIR/shipping.js"

    local files=$(json_nested_array "$SITE_JSON" assets js)
    if [ -n "$files" ]; then
      while IFS= read -r f; do
        [ -n "$f" ] && min "$TEMPLATE_DIR/$f"
      done <<< "$files"
    else
      min "$TEMPLATE_DIR/js/lazy.js"
      min "$TEMPLATE_DIR/js/off.js"
      min "$TEMPLATE_DIR/js/navmenu.js"
      min "$TEMPLATE_DIR/js/helper.js"
      min "$TEMPLATE_DIR/js/basket.js"
    fi
    # Conditional filter.js — included when isFiltering: true
    if grep -q '"isFiltering"[[:space:]]*:[[:space:]]*true' "$SITE_JSON" \
       && [ -f "$TEMPLATE_DIR/js/filter.js" ]; then
      min "$TEMPLATE_DIR/js/filter.js"
    fi
  } > "$OUTPUT_DIR/$js_output"

  echo "js merged"
}

build_menu_css() {
  local menu_css_src=$(json_val "$SITE_JSON" menuCss)
  local menu_css_output=$(json_val "$SITE_JSON" menuCssOutput)
  [ -z "$menu_css_src" ] || [ -z "$menu_css_output" ] && return
  if [ ! -f "$SETTINGS_DIR/menu.json" ]; then
    if [ -f "$OUTPUT_DIR/$menu_css_output" ]; then
      rm -f "$OUTPUT_DIR/$menu_css_output"
      echo "$menu_css_output removed (orphan)"
    fi
    return 0
  fi
  min "$TEMPLATE_DIR/$menu_css_src" > "$OUTPUT_DIR/$menu_css_output"
  echo "menu.css built"
}

build_images() {
  if ! command -v ffmpeg &>/dev/null; then
    echo "ffmpeg not found. ffmpeg is required for image conversion."
    local answer="n"
    [[ -t 0 ]] && read -rp "Install ffmpeg? (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      sudo dnf install -y ffmpeg
      if ! command -v ffmpeg &>/dev/null; then
        echo "ffmpeg installation failed, skipping images."
        return 1
      fi
    else
      echo "ffmpeg not installed, skipping images."
      return 0
    fi
  fi

  for dir in "$OUTPUT_DIR/img/pages" "$OUTPUT_DIR/img/products"; do
    [ -d "$dir" ] || continue
    for jpg in "$dir"/*.jpg; do
      [ -f "$jpg" ] || continue
      base="${jpg%.jpg}"

      [ -f "${base}.webp" ] || ffmpeg -y -i "$jpg" -c:v libwebp -quality 99 "${base}.webp" 2>/dev/null
      [ -f "${base}-k.webp" ] || ffmpeg -y -i "$jpg" -vf "scale=20:-1,boxblur=2:1" -c:v libwebp -quality 88 "${base}-k.webp" 2>/dev/null
    done
  done
  echo "images processed"
}

build_css
build_js
build_images
build_menu_css
