import { Manifold, CrossSection, show, color } from './lib/viewer.js';

// Your code here — build a Manifold, then call show() to display it.
// See docs.md for the full API reference.
// See demo_basics.js for examples of every feature.

const POSITIONS = [
  // z = 0 layer (cross shape)
  [1,0,0], [0,1,0], [1,1,0], [2,1,0], [1,2,0],
  // z = 1 layer (ring shape — corners + edges, no center)
  [0,0,1], [0,1,1], [0,2,1],
  [1,0,1],          [1,2,1],
  [2,0,1], [2,1,1], [2,2,1],
  // z = 2 layer (cross shape, mirror of z=0)
  [1,0,2], [0,1,2], [1,1,2], [2,1,2], [1,2,2]
];

function mosleySnowflake(level) {
  if (level === 0) {
    return Manifold.cube([1, 1, 1], true);
  }

  const sub = mosleySnowflake(level - 1);

  const copies = POSITIONS.map(([x, y, z]) => {
    // Scale sub by 1/3, then offset to its grid position
    return sub
      .scale(1 / 3)
      .translate([(x - 1) / 3, (y - 1) / 3, (z - 1) / 3]);
  });

  return Manifold.union(copies);
}

const fractal = mosleySnowflake(3);

show(fractal);