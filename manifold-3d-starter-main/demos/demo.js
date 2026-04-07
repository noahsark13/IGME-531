import { Manifold, show, color } from '../lib/viewer.js';

// A russian doll is a hollow sphere with a smaller russian doll inside.
// Recurses until the wall would be thinner than MIN_WALL.
const MIN_WALL = 0.4;
const DOLL_RADIUS = 40;

const doll = (r) => {
  const wall = r * 0.2;
  if (wall < MIN_WALL) return Manifold.sphere(r, 48); // solid core

  const cavity = r - wall;
  const shell = Manifold.sphere(r, 48)
    .subtract(Manifold.sphere(cavity, 48));

  const innerR = cavity * 0.75;
  const inner = doll(innerR)
    .translate([0, -(cavity - innerR), 0]);

  return Manifold.union([shell, inner]);
};

// Cut away one quarter to see inside
const r = DOLL_RADIUS;
const s = r * 2;
const quarterCut = Manifold.cube([s, s, s]).translate([0, -s / 2, 0]);

// Flat bottom for printing
const bottomCut = Manifold.cube([s, s, s], true)
  .translate([0, -s / 2 - r + r * 0.1, 0]);

const model = doll(r).subtract(quarterCut).subtract(bottomCut);

show(model, color(0.85, 0.45, 0.5));
