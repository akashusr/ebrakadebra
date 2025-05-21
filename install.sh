#!/bin/bash

set -e

WORKSPACE_DIR="/workspace"
TARGET_DIR=$(find "$WORKSPACE_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
PROJECT_NAME=$(basename "$TARGET_DIR")

VITE_CONFIG="$TARGET_DIR/vite.config.js"
GITPOD_CONFIG="$WORKSPACE_DIR/$PROJECT_NAME/.gitpod.yml"

echo "➡ Found target project directory: $TARGET_DIR"

# Update vite.config.js
if [[ -f "$VITE_CONFIG" ]]; then
  echo "📦 Backing up existing vite.config.js to vite.config.js.bak"
  cp "$VITE_CONFIG" "$VITE_CONFIG.bak"

  echo "🛠 Injecting 'server: { allowedHosts: true }' into vite.config.js"

  # Only inject if not already present
  if ! grep -q 'allowedHosts: true' "$VITE_CONFIG"; then
    awk '
      /plugins: \[.*\],?/ {
        print
        print "  server: {\n    allowedHosts: true\n  },"
        next
      }
      { print }
    ' "$VITE_CONFIG.bak" > "$VITE_CONFIG"

    echo "✅ server config injected successfully!"
  else
    echo "ℹ️  server config already present, skipping injection."
  fi
else
  echo "❌ vite.config.js not found in $TARGET_DIR"
  exit 1
fi

GITPOD_CONFIG=".gitpod.yml"

# Desired content
GITPOD_CONTENT=$(cat << 'EOF'
tasks:
  - init: npm install && npm run build
    command: npm run dev

ports:
  - port: 5173
    onOpen: open-browser
EOF
)

# Create or replace .gitpod.yml
echo "🔁 Writing content to $GITPOD_CONFIG..."
echo "$GITPOD_CONTENT" > "$GITPOD_CONFIG"
echo "✅ $GITPOD_CONFIG has been written successfully!"

