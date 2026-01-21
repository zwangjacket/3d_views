---
description: How to add a new 360° scene from a Marzipano export
---

# Add New 360° Scene Workflow

This workflow describes how to integrate a new 360° image from [Marzipano Tool](https://www.marzipano.net/tool/).

## Prerequisites
- Node.js installed (for running the add-scene script)
- A Marzipano export zip file

## Steps

### Option A: Using the Automated Script (Recommended)

// turbo
1. Run the add-scene script with the zip file and desired scene name:
```bash
./add-scene.sh ~/Downloads/your-export.zip "Your Scene Name"
```

// turbo
2. Preview locally (optional):
```bash
python3 -m http.server 8000
```
Then open http://localhost:8000

// turbo
3. Commit and push the changes:
```bash
git add -A && git commit -m "Add scene: Your Scene Name" && git push
```

### Option B: Manual Integration

1. **Download from Marzipano Tool**
   - Go to https://www.marzipano.net/tool/
   - Upload your equirectangular 360° image
   - Click "Export" and download the zip file

2. **Extract the zip file**
   - Extract to a temporary location
   - Look for the `app-files` folder inside

3. **Copy the tiles**
   - Find the scene folder inside `app-files/tiles/` (e.g., `0-your-image-name`)
   - Copy this folder to `tiles/` in the project
   - Rename it with a unique ID format: `{number}-{scene-slug}`

4. **Update data.js**
   - Open `data.js`
   - Add a new scene object to the `scenes` array:
   ```javascript
   {
     "id": "2-your-scene-slug",
     "name": "Your Scene Display Name",
     "levels": [
       { "tileSize": 256, "size": 256, "fallbackOnly": true },
       { "tileSize": 512, "size": 512 },
       { "tileSize": 512, "size": 1024 }
     ],
     "faceSize": 720,
     "initialViewParameters": {
       "pitch": 0,
       "yaw": 0,
       "fov": 1.5707963267948966
     },
     "linkHotspots": [],
     "infoHotspots": []
   }
   ```
   - Make sure the `id` matches the folder name you created in `tiles/`

5. **Commit and push**
   ```bash
   git add -A
   git commit -m "Add scene: Your Scene Name"
   git push
   ```

## Files Structure

```
3d_views/
├── index.html          # Homepage gallery
├── viewer.html         # 360° viewer page
├── data.js            # Scene configuration (edit this to add scenes)
├── index.js           # Viewer logic
├── add-scene.sh       # Automated scene addition script
├── tiles/
│   ├── 0-first-scene/  # Each scene has its own folder
│   │   ├── preview.jpg
│   │   ├── 1/          # Tile levels
│   │   └── 2/
│   └── 1-second-scene/
│       └── ...
└── ...
```

## Troubleshooting

- **Scene not appearing**: Check that the scene ID in `data.js` matches the folder name in `tiles/`
- **Black/broken preview**: Ensure `preview.jpg` exists in the scene's tile folder
- **Tiles not loading**: Check browser console for 404 errors on tile paths
