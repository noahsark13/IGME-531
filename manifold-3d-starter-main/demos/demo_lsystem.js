import { Manifold, show, color } from '../lib/viewer.js';

// Same russian dolls as demo.js, but built with an L-system.
//
// Rule: X → F[iX]
//   "A doll is a shell (F) with a doll (X) inside."
//   X expands each iteration. F is terminal — it stays put.
//
// Symbols:
//   F   = place a hollow shell (or solid core if too small)
//   X   = "there's a doll here" (expands to F[iX])
//   i   = go inside: shrink radius, drop to cavity floor
//   [/] = push/pop state


// ── L-System Engine (same as week 9) ──────────────────

const expand = (axiom, rules, iterations) => {
  let str = axiom;
  for (let i = 0; i < iterations; i++) {
    let next = '';
    for (const ch of str) {
      next += rules[ch] || ch;
    }
    str = next;
  }
  return str;
};


// ── Interpreter ───────────────────────────────────────

const MIN_WALL = 0.4;

const interpret = (str, startRadius) => {
  let r = startRadius;
  let y = 0;
  const stack = [];
  const parts = [];

  for (const ch of str) {
    switch (ch) {
      case 'F': {
        const wall = r * 0.2;
        if (wall < MIN_WALL) {
          // Solid core
          parts.push(Manifold.sphere(r, 48).translate([0, y, 0]));
        } else {
          // Hollow shell
          const cavity = r - wall;
          parts.push(
            Manifold.sphere(r, 48)
              .subtract(Manifold.sphere(cavity, 48))
              .translate([0, y, 0])
          );
        }
        break;
      }
      case 'i': {
        // Go inside: shrink and drop to cavity floor
        const cavity = r - r * 0.2;
        const innerR = cavity * 0.75;
        y -= (cavity - innerR);
        r = innerR;
        break;
      }
      case '[': stack.push({ r, y }); break;
      case ']': ({ r, y } = stack.pop()); break;
    }
  }

  return Manifold.union(parts);
};


// ── Run ───────────────────────────────────────────────

const DOLL_RADIUS = 40;
const expanded = expand('X', { 'X': 'F[iX]' }, 8);
const dolls = interpret(expanded, DOLL_RADIUS);

// Cut away one quarter + flat bottom
const s = DOLL_RADIUS * 2;
const quarterCut = Manifold.cube([s, s, s]).translate([0, -s / 2, 0]);
const bottomCut = Manifold.cube([s, s, s], true)
  .translate([0, -s / 2 - DOLL_RADIUS + DOLL_RADIUS * 0.1, 0]);

const model = dolls.subtract(quarterCut).subtract(bottomCut);

show(model, color(0.85, 0.45, 0.5));
