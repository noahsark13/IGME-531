# manifold-3d Quick Reference

A browser-based library for creating 3D solid geometry using Constructive Solid Geometry (CSG). Models are watertight and can be exported as STL for 3D printing.

Full docs: https://manifoldcad.org/docs/jsapi/modules.html
Interactive editor: https://manifoldcad.org/

---

## Setup

All demos import from `lib/viewer.js`, which handles the 3D viewport and provides:

```js
import { Manifold, CrossSection, show, color } from './lib/viewer.js';
```

- `show(manifold)` — display a model in the viewport (auto-centers, sits on grid)
- `show(manifold, color(r, g, b))` — display with a color (values 0–1)
- An **Export STL** button appears in the status bar after `show()`

---

## Manifold — 3D Solid Geometry

### Creating Shapes

```js
Manifold.cube(size, center?)
```
- `size` — `[x, y, z]` or a single number for a uniform cube
- `center` — if `true`, centered on origin. Default: corner at origin.

```js
Manifold.sphere(radius, circularSegments?)
```
- `circularSegments` — smoothness. Default varies; `48` is a good value.

```js
Manifold.cylinder(height, radiusLow, radiusHigh?, circularSegments?, center?)
```
- `radiusHigh = radiusLow` → true cylinder
- `radiusHigh = 0` → cone
- `center` — if `true`, centered on Z axis. Default: base at origin.
- Cylinder/cone axis is **Z**.

```js
Manifold.tetrahedron()
```
- Unit tetrahedron.

### Boolean Operations

The core of CSG — combine simple shapes into complex ones.

```js
a.add(b)          // union: merge a and b together
a.subtract(b)     // difference: cut b out of a
a.intersect(b)    // intersection: keep only the overlap
```

Batch versions (faster for many shapes):
```js
Manifold.union(arrayOfManifolds)
Manifold.intersection(arrayOfManifolds)
```

### Transforms

All transforms return a **new** Manifold (the original is unchanged).

```js
manifold.translate([x, y, z])
manifold.rotate([xDeg, yDeg, zDeg])   // degrees, not radians
manifold.scale([x, y, z])             // or a single number for uniform
manifold.mirror([nx, ny, nz])         // reflect across plane with this normal
```

### Deformation

```js
manifold.warp(fn)
```
- `fn` receives a `[x, y, z]` array for each vertex — **modify it in place**.
- Example twist:
  ```js
  shape.warp(v => {
    const angle = v[2] * 0.1;
    const x = v[0], y = v[1];
    v[0] = x * Math.cos(angle) - y * Math.sin(angle);
    v[1] = x * Math.sin(angle) + y * Math.cos(angle);
  });
  ```

### Signed Distance Functions

```js
Manifold.levelSet(sdf, bounds, edgeLength)
```
- `sdf` — function `([x,y,z]) => number`. Positive = inside, 0 = surface, negative = outside.
- `bounds` — `{ min: [x,y,z], max: [x,y,z] }` — bounding box to evaluate within.
- `edgeLength` — mesh resolution. Smaller = higher quality, slower.

Example — sphere from SDF:
```js
Manifold.levelSet(
  pt => 10 - Math.sqrt(pt[0]**2 + pt[1]**2 + pt[2]**2),
  { min: [-12,-12,-12], max: [12,12,12] },
  0.5
);
```

### Measurements

```js
manifold.numVert()       // number of vertices
manifold.numTri()        // number of triangles
manifold.volume()        // enclosed volume
manifold.surfaceArea()   // total surface area
manifold.boundingBox()   // { min: [x,y,z], max: [x,y,z] }
```

### Cleanup

**WASM objects are NOT garbage collected.** Call `.delete()` when done with a Manifold you no longer need. (The viewer handles this for objects passed to `show()`.)

---

## CrossSection — 2D Shapes

2D shapes used as input for extrude/revolve operations.

### Creating 2D Shapes

```js
CrossSection.square(size, center?)
```
- `size` — `[width, height]` or a single number

```js
CrossSection.circle(radius, circularSegments?)
```

```js
CrossSection.ofPolygons(contours)
```
- `contours` — array of polygons, each polygon is an array of `[x, y]` points
- Example: `CrossSection.ofPolygons([[[0,0], [10,0], [5,10]]])`

### 2D Boolean Operations

Same as 3D:
```js
a.add(b)          // union
a.subtract(b)     // difference
a.intersect(b)    // intersection
```

### 2D Transforms

```js
section.translate([x, y])
section.rotate(degrees)
section.scale([x, y])       // or a single number
section.mirror([nx, ny])
```

### 2D → 3D

```js
section.extrude(height, nDivisions?, twistDegrees?, scaleTop?, center?)
```
- `height` — how far to push upward (along Z)
- `nDivisions` — smoothness of twist/taper (more = smoother)
- `twistDegrees` — rotate the shape as it extrudes (e.g., `360` for a full twist)
- `scaleTop` — scale at the top. `1` = same size, `0` = point (pyramid), `0.5` = half size.

```js
section.revolve(circularSegments?, revolveDegrees?)
```
- Spins the 2D shape around the **Y axis**.
- `revolveDegrees` — default `360`. Use less for partial shapes (e.g., `180` for half).

Example — torus:
```js
CrossSection.circle(3, 32).translate([10, 0]).revolve(48)
```

### Measurements

```js
section.area()
```

---

## Types

```
Vec2 = [number, number]
Vec3 = [number, number, number]
Box  = { min: Vec3, max: Vec3 }
```

---

## Common Patterns

**Hollow shell:**
```js
const shell = Manifold.sphere(r, 48)
  .subtract(Manifold.sphere(r - wallThickness, 48));
```

**Recursive structure:**
```js
const thing = (size, depth) => {
  const base = Manifold.cube([size, size, size]);
  if (depth <= 0) return base;
  const child = thing(size / 3, depth - 1).translate([...]);
  return Manifold.union([base, child]);
};
```

**Custom profile → solid of revolution:**
```js
const pts = [[0,0], [8,0], [6,10], [3,15], [0,15]];
const profile = CrossSection.ofPolygons([pts]);
const vase = profile.revolve(48);
```

**Flat bottom for 3D printing:**
```js
const cut = Manifold.cube([big, big, big], true)
  .translate([0, -big/2 - r + flatAmount, 0]);
model.subtract(cut);
```
