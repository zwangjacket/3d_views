#!/bin/bash
# =============================================================================
# add-scene.sh - Add a new 360° scene from a Marzipano export
# =============================================================================
# 
# Usage: ./add-scene.sh <path-to-zip> <scene-name>
#
# Example: ./add-scene.sh ~/Downloads/my-kitchen.zip "Kitchen View"
#
# This script will:
#   1. Extract the Marzipano zip file
#   2. Copy the tiles to the tiles/ directory
#   3. Add the scene to data.js
#   4. Display instructions for committing changes
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory (where this script and the project files are)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TILES_DIR="$SCRIPT_DIR/tiles"
DATA_FILE="$SCRIPT_DIR/data.js"
TEMP_DIR="/tmp/marzipano-extract-$$"

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo ""
    echo "Usage: $0 <path-to-zip> <scene-name>"
    echo ""
    echo "Example: $0 ~/Downloads/my-kitchen.zip \"Kitchen View\""
    exit 1
fi

ZIP_PATH="$1"
SCENE_NAME="$2"

# Validate zip file exists
if [ ! -f "$ZIP_PATH" ]; then
    echo -e "${RED}Error: Zip file not found: $ZIP_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Adding new 360° scene: ${GREEN}$SCENE_NAME${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Extract the zip
echo -e "${YELLOW}Step 1:${NC} Extracting zip file..."
mkdir -p "$TEMP_DIR"
unzip -q "$ZIP_PATH" -d "$TEMP_DIR"

# Find the app-files directory (handle different zip structures)
APP_FILES=""
if [ -d "$TEMP_DIR/app-files" ]; then
    APP_FILES="$TEMP_DIR/app-files"
elif [ -d "$TEMP_DIR/"*/app-files ]; then
    APP_FILES=$(find "$TEMP_DIR" -type d -name "app-files" | head -1)
else
    # Maybe files are at root level
    APP_FILES="$TEMP_DIR"
fi

# Step 2: Extract scene info from data.js
echo -e "${YELLOW}Step 2:${NC} Reading scene configuration..."
MARZIPANO_DATA="$APP_FILES/data.js"
if [ ! -f "$MARZIPANO_DATA" ]; then
    echo -e "${RED}Error: Could not find data.js in the extracted files${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Extract the scene ID from the Marzipano data.js
ORIGINAL_SCENE_ID=$(grep -o '"id": "[^"]*"' "$MARZIPANO_DATA" | head -1 | sed 's/"id": "\(.*\)"/\1/')
echo "   Found scene ID: $ORIGINAL_SCENE_ID"

# Extract scene configuration (levels, faceSize, etc.)
SCENE_LEVELS=$(sed -n '/"levels":/,/\]/p' "$MARZIPANO_DATA" | tr -d '\n' | sed 's/.*"levels": *\(\[.*\]\).*/\1/')
FACE_SIZE=$(grep -o '"faceSize": [0-9]*' "$MARZIPANO_DATA" | head -1 | sed 's/"faceSize": //')

# Step 3: Count existing scenes to generate new ID
echo -e "${YELLOW}Step 3:${NC} Generating new scene ID..."
SCENE_COUNT=$(grep -c '"id":' "$DATA_FILE" 2>/dev/null || echo "0")
NEW_SCENE_ID="$SCENE_COUNT-$(echo "$SCENE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
echo "   New scene ID: $NEW_SCENE_ID"

# Step 4: Copy tiles
echo -e "${YELLOW}Step 4:${NC} Copying tiles..."
TILES_SOURCE="$APP_FILES/tiles/$ORIGINAL_SCENE_ID"
if [ ! -d "$TILES_SOURCE" ]; then
    # Try to find the tiles directory
    TILES_SOURCE=$(find "$APP_FILES/tiles" -mindepth 1 -maxdepth 1 -type d | head -1)
fi

if [ ! -d "$TILES_SOURCE" ]; then
    echo -e "${RED}Error: Could not find tiles directory${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

mkdir -p "$TILES_DIR"
cp -r "$TILES_SOURCE" "$TILES_DIR/$NEW_SCENE_ID"
echo "   Copied tiles to: tiles/$NEW_SCENE_ID"

# Step 5: Add scene to data.js
echo -e "${YELLOW}Step 5:${NC} Adding scene to data.js..."

# Create the new scene JSON
NEW_SCENE=$(cat <<EOF
    {
      "id": "$NEW_SCENE_ID",
      "name": "$SCENE_NAME",
      "levels": [
        {
          "tileSize": 256,
          "size": 256,
          "fallbackOnly": true
        },
        {
          "tileSize": 512,
          "size": 512
        },
        {
          "tileSize": 512,
          "size": 1024
        }
      ],
      "faceSize": ${FACE_SIZE:-720},
      "initialViewParameters": {
        "pitch": 0,
        "yaw": 0,
        "fov": 1.5707963267948966
      },
      "linkHotspots": [],
      "infoHotspots": []
    }
EOF
)

# Use node to safely add the scene to data.js
node -e "
const fs = require('fs');
const dataFile = '$DATA_FILE';

// Read existing data.js
let content = fs.readFileSync(dataFile, 'utf8');

// Extract the APP_DATA object (remove 'var APP_DATA = ' and trailing ';')
const jsonStr = content.replace(/^var APP_DATA = /, '').replace(/;\s*$/, '');
const data = JSON.parse(jsonStr);

// Add new scene
const newScene = {
  id: '$NEW_SCENE_ID',
  name: '$SCENE_NAME',
  levels: [
    { tileSize: 256, size: 256, fallbackOnly: true },
    { tileSize: 512, size: 512 },
    { tileSize: 512, size: 1024 }
  ],
  faceSize: ${FACE_SIZE:-720},
  initialViewParameters: { pitch: 0, yaw: 0, fov: 1.5707963267948966 },
  linkHotspots: [],
  infoHotspots: []
};

data.scenes.push(newScene);

// Write back
const output = 'var APP_DATA = ' + JSON.stringify(data, null, 2) + ';\\n';
fs.writeFileSync(dataFile, output);
console.log('   Scene added successfully!');
"

# Step 6: Cleanup
echo -e "${YELLOW}Step 6:${NC} Cleaning up..."
rm -rf "$TEMP_DIR"

# Done!
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Scene '$SCENE_NAME' added successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Preview locally:  cd $SCRIPT_DIR && python3 -m http.server 8000"
echo "  2. Commit changes:   git add -A && git commit -m \"Add scene: $SCENE_NAME\""
echo "  3. Push to GitHub:   git push"
echo ""
