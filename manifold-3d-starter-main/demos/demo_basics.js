import { Manifold, CrossSection, show, color } from '../lib/viewer.js';

// ============================================================
// manifold-3d Basics
//
// Uncomment ONE section at a time to see it in the viewer.
// Each section is self-contained.
// ============================================================


// ── 1. PRIMITIVES ─────────────────────────────────────

// Cube — corner at origin by default
// show(Manifold.cube([20, 20, 20]));

// Cube — centered on origin
// show(Manifold.cube([20, 20, 20], true));

// Sphere — (radius, segments). More segments = smoother.
// show(Manifold.sphere(12, 48));

// Cylinder — (height, radiusBottom, radiusTop, segments, center?)
// show(Manifold.cylinder(30, 8, 8, 32, true));

// Cone — cylinder with radiusTop = 0
// show(Manifold.cylinder(20, 10, 0, 32));

// Tapered cylinder — different top and bottom radii
// show(Manifold.cylinder(25, 10, 4, 32));


// ── 2. BOOLEAN OPERATIONS ─────────────────────────────
// The core of CSG: combine simple shapes into complex ones.

// Union — merge two shapes together
// const a = Manifold.cube([20, 20, 20], true);
// const b = Manifold.sphere(13, 48);
// show(a.add(b));

// Difference — cut one shape out of another
// const a = Manifold.cube([20, 20, 20], true);
// const b = Manifold.sphere(13, 48);
// show(a.subtract(b));

// Intersection — keep only the overlap
// const a = Manifold.cube([20, 20, 20], true);
// const b = Manifold.sphere(13, 48);
// show(a.intersect(b));

// Batch union — multiple shapes at once (faster than chaining)
// const cubes = [];
// for (let i = 0; i < 5; i++) {
//   cubes.push(Manifold.cube([6, 6, 6], true).translate([i * 8 - 16, 0, 0]));
// }
// show(Manifold.union(cubes));


// ── 3. TRANSFORMS ─────────────────────────────────────

// Translate — move in space
// const a = Manifold.cube([10, 10, 10], true);
// const b = Manifold.sphere(6, 32).translate([15, 0, 0]);
// show(a.add(b));

// Rotate — angles in DEGREES, [x, y, z]
// show(Manifold.cube([20, 10, 5], true).rotate([0, 0, 45]));

// Scale — non-uniform [x, y, z] or uniform number
// show(Manifold.sphere(10, 48).scale([1, 1, 2]));

// Mirror — reflect across a plane (defined by normal vector)
// const half = Manifold.cube([10, 20, 20]).translate([2, -10, -10]);
// const whole = half.add(half.mirror([1, 0, 0]));
// show(whole);


// ── 4. 2D → 3D: EXTRUDE & REVOLVE ────────────────────
// Draw a 2D profile, then sweep it into 3D.

// Extrude — push a 2D shape upward
// const square = CrossSection.square([20, 20], true);
// show(square.extrude(15));

// Twisted extrude — rotate as it goes up
// const circle = CrossSection.circle(8, 48);
// show(circle.extrude(30, 16, 360));

// Tapered extrude — shrink to a point (pyramid)
// const square = CrossSection.square([20, 20], true);
// show(square.extrude(20, 1, 0, 0));

// Revolve — spin a profile around Y axis (like a lathe)
// Torus: offset a circle from the axis, then spin it
// const profile = CrossSection.circle(3, 32).translate([10, 0]);
// show(profile.revolve(48));

// Partial revolve — 270 degrees
// const profile = CrossSection.circle(3, 32).translate([10, 0]);
// show(profile.revolve(48, 270));

// Vase — revolve a custom polygon profile
// const pts = [[0,0], [8,0], [10,5], [7,15], [8,18], [6,20], [0,20]];
// const profile = CrossSection.ofPolygons([pts]);
// const solid = profile.revolve(48);
// const hollow = CrossSection.ofPolygons([[[0,0],[6,0],[8,5],[5,15],[6,18],[4,20],[0,20]]]).revolve(48);
// show(solid.subtract(hollow));


// ── 5. PRACTICAL COMBOS ───────────────────────────────

// Dice — cube with pip indentations
// const die = Manifold.cube([20, 20, 20], true);
// const pip = Manifold.sphere(2, 16);
// // One face: single center pip
// const face1 = pip.translate([0, 0, 10]);
// // Opposite face: four corner pips
// const face6pips = [];
// for (const [dx, dy] of [[-1,-1],[-1,1],[1,-1],[1,1],[-1,0],[1,0]]) {
//   face6pips.push(pip.translate([dx * 5, dy * 5, -10]));
// }
// show(die.subtract(face1).subtract(Manifold.union(face6pips)));

// Snowman
// const body = Manifold.sphere(10, 48);
// const torso = Manifold.sphere(7, 48).translate([0, 14, 0]);
// const head = Manifold.sphere(5, 48).translate([0, 24, 0]);
// show(Manifold.union([body, torso, head]));

// Hollow box with round holes
// const shell = Manifold.cube([40, 30, 20], true)
//   .subtract(Manifold.cube([36, 26, 18], true));
// const holeX = Manifold.cylinder(40, 4, 4, 32, true).rotate([0, 90, 0]);
// const holeY = Manifold.cylinder(30, 4, 4, 32, true).rotate([90, 0, 0]);
// const holeZ = Manifold.cylinder(20, 3, 3, 32, true);
// show(shell.subtract(holeX).subtract(holeY).subtract(holeZ));

// Monument — stacked transforms
// const base = Manifold.cylinder(2, 15, 15, 32);
// const pillar = Manifold.cylinder(20, 3, 3, 16).translate([0, 0, 2]);
// const top = Manifold.sphere(6, 32).translate([0, 0, 22]);
// show(Manifold.union([base, pillar, top]).rotate([90, 0, 0]));
