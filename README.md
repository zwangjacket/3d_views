# 3D Space View

A beautiful 360° panorama viewer gallery built with Marzipano.

🌐 **Live Site**: [https://zwangjacket.github.io/3d_views/](https://zwangjacket.github.io/3d_views/)

## Features

- 📸 **Gallery Homepage** - Browse all available 360° scenes with preview cards
- 🔄 **Interactive 360° Viewer** - Drag to look around, zoom in/out
- ♾️ **Auto-rotate** - Optional automatic panning
- 📱 **Responsive Design** - Works on desktop and mobile

## Adding New Scenes

### Quick Method (Recommended)

1. **Create your 360° image** using [Marzipano Tool](https://www.marzipano.net/tool/)
2. **Download** the export zip file
3. **Run the script**:
   ```bash
   ./add-scene.sh ~/Downloads/your-export.zip "Your Scene Name"
   ```
4. **Commit and push**:
   ```bash
   git add -A && git commit -m "Add scene: Your Scene Name" && git push
   ```

### Manual Method

See the workflow guide in `.agent/workflows/add-scene.md`

## Project Structure

```
3d_views/
├── index.html          # Homepage gallery
├── viewer.html         # 360° viewer page  
├── data.js            # Scene configuration
├── index.js           # Viewer logic
├── add-scene.sh       # Automated scene addition script
├── tiles/             # Scene tile images
│   └── {scene-id}/
│       ├── preview.jpg
│       └── {zoom-levels}/
├── style.css          # Viewer styles
├── img/               # UI icons
└── vendor/            # Marzipano library
```

## Technologies

- [Marzipano](http://www.marzipano.net/) - 360° image viewer
- Vanilla JavaScript & CSS
- GitHub Pages for hosting

## License

See LICENSE file for details.
