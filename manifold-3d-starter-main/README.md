# manifold-3d — 3D Solid Geometry

Create 3D models in JavaScript. Export as STL for 3D printing.

## Quick Start

1. Open `index.html` in a browser (use Live Server)
2. Edit `index.js` — this is your file
3. Save → refresh browser to see changes
4. Click **Export STL** in the status bar to download your model

## How It Works

```js
import { Manifold, CrossSection, show, color } from './lib/viewer.js';

// Build geometry using Manifold methods
const sphere = Manifold.sphere(12, 48);
const cube = Manifold.cube([20, 20, 20], true);
const model = cube.subtract(sphere);

// Display it
show(model);
// or with color:
show(model, color(0.8, 0.3, 0.3));
```

## What to Edit

| File | Purpose |
|------|---------|
| `index.js` | **Your code goes here** |
| `index.html` | Opens your model in a browser (don't edit) |
| `docs.md` | API reference — method signatures and examples |
| `demos/` | Working examples to study and copy from |
| `lib/` | **Do not edit.** This is the code that creates the 3D viewer, handles the rendering, and makes `show()` work. Treat it like a library. |

## Resources

- `docs.md` — quick reference for every function you need
- `demos/demo_basics.js` — uncomment examples to try each feature
- `demos/demo.js` — recursive russian dolls
- `demos/demo_lsystem.js` — same thing built with an L-system
- Full API docs: https://manifoldcad.org/docs/jsapi/modules.html
- Interactive playground: https://manifoldcad.org/

## Key Concepts

**Primitives** — `Manifold.cube()`, `.sphere()`, `.cylinder()`

**Booleans** — `.add()` (union), `.subtract()` (cut), `.intersect()` (overlap)

**Transforms** — `.translate([x,y,z])`, `.rotate([x,y,z])`, `.scale(n)`

**2D → 3D** — `CrossSection.circle()` / `.square()` → `.extrude()` / `.revolve()`

## Tips

- Start simple. A cube is fine. Add complexity one step at a time.
- Keep iterations low on recursive models (3-4). Higher = slow.
- `show()` replaces the previous model — call it once at the end.
- Units are millimeters when you open the STL in a slicer.
- VS Code gives you autocomplete on `Manifold.` and `CrossSection.` methods.
