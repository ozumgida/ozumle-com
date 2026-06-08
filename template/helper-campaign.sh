#!/bin/bash
# Campaign feature helpers — sourced by update.sh when present.

CAMPAIGN_JSON="$SETTINGS_DIR/campaign.json"

# --- Inject Campaign Config into site.js ---
inject_campaign_config() {
  [ ! -f "$CAMPAIGN_JSON" ] && return

  if ! grep -q 'let CAMPAIGN_CONFIG = \[\];' "$OUTPUT_DIR/site.js"; then
    echo "ERROR: placeholder 'let CAMPAIGN_CONFIG = [];' not found in site.js"
    return
  fi

  local js
  js=$(python3 - "$CAMPAIGN_JSON" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
result = []
for c in data.get('campaigns', []):
    if not c.get('active', False):
        continue
    obj = {
        'type': c.get('type', ''),
        'label': c.get('label', ''),
        'messageLine': c.get('messageLine', ''),
        'img': c.get('img', ''),
        'addProducts': c.get('addProducts', []),
    }
    t = obj['type']
    if t == 'tier_discount':
        obj['tiers'] = c.get('tiers', [])
    elif t == 'multi_unit':
        obj['productId'] = c.get('productId', '')
        obj['tiers'] = c.get('tiers', [])
    elif t == 'free_shipping':
        obj['conditions'] = c.get('conditions', [])
    elif t == 'happy_hour':
        obj['schedule'] = c.get('schedule', {})
        obj['discountType'] = c.get('discountType', '')
        obj['discountValue'] = c.get('discountValue', 0)
        obj['scope'] = c.get('scope', 'all')
    result.append(obj)
print(json.dumps(result, ensure_ascii=False))
PYEOF
)

  sed -i "s#let CAMPAIGN_CONFIG = \[\];#let CAMPAIGN_CONFIG=$(sed_safe "$js");#" "$OUTPUT_DIR/site.js"
  echo "campaign config injected"
}

# --- Inline campaign strip (for product pages) ---
build_campaigns_strip() {
  [ ! -f "$CAMPAIGN_JSON" ] && return

  local items
  items=$(python3 - "$CAMPAIGN_JSON" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
idx = 0
parts = []
for c in data.get('campaigns', []):
    if not c.get('active', False):
        idx += 1
        continue
    img = c.get('img', '')
    if img:
        label = c.get('label', '').replace('"', '&quot;')
        parts.append(f'<a data-ci="{idx}" href="#basket"><img src="/img/campaign/{img}" alt="{label}" loading="lazy"></a>')
    idx += 1
print(''.join(parts))
PYEOF
)

  [ -z "$items" ] && return
  printf '<section class="campaign-strip">%s</section>' "$items"
}

# --- Build campaigns.html ---
build_campaigns_html() {
  [ ! -f "$CAMPAIGN_JSON" ] && return

  local items
  items=$(python3 - "$CAMPAIGN_JSON" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
idx = 0
parts = []
for c in data.get('campaigns', []):
    if not c.get('active', False):
        idx += 1
        continue
    img = c.get('img', '')
    if img:
        label = c.get('label', '').replace('"', '&quot;')
        parts.append(f'<a data-ci="{idx}" href="#basket"><img src="/img/campaign/{img}" alt="{label}" loading="lazy"></a>')
    idx += 1
print(''.join(parts))
PYEOF
)

  local layout
  layout=$(<"$TEMPLATE_DIR/campaigns-layout.html")
  printf '%s' "${layout/\{\{campaigns_items\}\}/$items}" > "$OUTPUT_DIR/campaigns.html"
  echo "campaigns.html built"
}
