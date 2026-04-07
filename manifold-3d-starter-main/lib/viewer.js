// ── manifold-3d Viewer ─────────────────────────────────
// Handles all rendering infrastructure. Student code just
// imports { Manifold, show } and writes geometry.
//
// Usage:
//   import { Manifold, CrossSection, show, color } from './lib/viewer.js';
//   const cube = Manifold.cube([20, 20, 20], true);
//   show(cube);

import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';


// ── DOM Setup ─────────────────────────────────────────

const style = document.createElement('style');
style.textContent = `
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #1e1e2e;
    color: #cdd6f4;
    font-family: system-ui, sans-serif;
    height: 100vh;
    display: grid;
    grid-template-rows: 1fr auto;
    overflow: hidden;
  }
  #viewport { width: 100%; height: 100%; }
  #viewport canvas { display: block; }
  #status {
    padding: 8px 20px;
    background: #252538;
    border-top: 1px solid rgba(255,255,255,0.06);
    font-size: 12px;
    font-family: monospace;
    color: #6c7086;
    display: flex;
    gap: 16px;
    align-items: center;
  }
  #status button {
    padding: 3px 10px;
    background: #a6e3a1;
    color: #1e1e2e;
    border: none;
    border-radius: 4px;
    font-size: 11px;
    font-weight: 600;
    cursor: pointer;
  }
  #status button:hover { opacity: 0.85; }
`;
document.head.appendChild(style);

const viewport = document.createElement('div');
viewport.id = 'viewport';
document.body.appendChild(viewport);

const statusBar = document.createElement('div');
statusBar.id = 'status';
statusBar.textContent = 'Loading WASM...';
document.body.appendChild(statusBar);


// ── Manifold Init ─────────────────────────────────────

const Module = (await import('./manifold-3d/manifold.js')).default;

const wasm = await Module();
wasm.setup();

/** @type {typeof import('./manifold-3d/manifold-encapsulated-types').Manifold} */
const Manifold = wasm.Manifold;
/** @type {typeof import('./manifold-3d/manifold-encapsulated-types').CrossSection} */
const CrossSection = wasm.CrossSection;
/** @type {typeof import('./manifold-3d/manifold-encapsulated-types').Mesh} */
const Mesh = wasm.Mesh;

statusBar.textContent = 'Ready';


// ── Three.js Scene ────────────────────────────────────

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(window.devicePixelRatio);
viewport.appendChild(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e1e2e);

const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 1000);
camera.position.set(30, 25, 30);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;

// Lighting
scene.add(new THREE.AmbientLight(0xffffff, 0.4));
const keyLight = new THREE.DirectionalLight(0xffffff, 1.2);
keyLight.position.set(30, 50, 40);
scene.add(keyLight);
const fillLight = new THREE.DirectionalLight(0x8888cc, 0.4);
fillLight.position.set(-20, 10, -20);
scene.add(fillLight);

// Ground grid (resized in show() to fit the model)
let grid = null;
const setGrid = (span) => {
  if (grid) scene.remove(grid);
  const size = Math.ceil(span / 10) * 10;
  grid = new THREE.GridHelper(size, size / 4, 0x444466, 0x2a2a3e);
  grid.material.transparent = true;
  grid.material.opacity = 0.4;
  scene.add(grid);
};
setGrid(60);

// Resize + render loop
const resize = () => {
  const w = viewport.clientWidth, h = viewport.clientHeight;
  renderer.setSize(w, h);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
};
window.addEventListener('resize', resize);
resize();

const animate = () => {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
};
animate();


// ── Show / Color API ──────────────────────────────────

let currentMeshes = [];
let currentManifold = null;

const manifoldToThree = (manifold, matColor) => {
  const withNormals = manifold.calculateNormals(0, 30);
  const mesh = withNormals.getMesh(0);

  const numProp = mesh.numProp;
  const verts = mesh.vertProperties;
  const tris = mesh.triVerts;
  const numVerts = verts.length / numProp;

  const positions = new Float32Array(numVerts * 3);
  const normals = new Float32Array(numVerts * 3);

  for (let i = 0; i < numVerts; i++) {
    positions[i * 3]     = verts[i * numProp];
    positions[i * 3 + 1] = verts[i * numProp + 1];
    positions[i * 3 + 2] = verts[i * numProp + 2];
    normals[i * 3]       = verts[i * numProp + 3];
    normals[i * 3 + 1]   = verts[i * numProp + 4];
    normals[i * 3 + 2]   = verts[i * numProp + 5];
  }

  withNormals.delete();

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.setAttribute('normal', new THREE.BufferAttribute(normals, 3));
  geo.setIndex(new THREE.BufferAttribute(new Uint32Array(tris), 1));

  const mat = new THREE.MeshStandardMaterial({
    roughness: 0.35, metalness: 0.05, ...matColor
  });

  return new THREE.Mesh(geo, mat);
};

/**
 * Display a Manifold in the 3D viewport.
 * Clears any previously shown geometry.
 *
 * @param {import('./manifold-3d/manifold-encapsulated-types').Manifold} manifold
 * @param {object} [materialOpts] - Three.js material options (e.g. from color())
 */
const show = (manifold, materialOpts) => {
  // Clear previous
  for (const m of currentMeshes) scene.remove(m);
  currentMeshes = [];
  if (currentManifold) { currentManifold.delete(); currentManifold = null; }

  currentManifold = manifold;

  const threeMesh = manifoldToThree(manifold, materialOpts || { color: 0x89b4fa });

  // Place bottom on the grid (y=0)
  const box = new THREE.Box3().setFromObject(threeMesh);
  threeMesh.position.y -= box.min.y;

  scene.add(threeMesh);
  currentMeshes.push(threeMesh);

  // Fit grid + camera to model size
  box.setFromObject(threeMesh); // recompute after shift
  const span = box.getSize(new THREE.Vector3());
  setGrid(Math.max(span.x, span.z) * 2);
  const center = box.getCenter(new THREE.Vector3());
  controls.target.copy(center);

  const vertCount = manifold.numVert();
  const triCount = manifold.numTri();

  // Update status with stats + export button
  statusBar.innerHTML = '';
  statusBar.textContent =
    `${vertCount.toLocaleString()} verts | ${triCount.toLocaleString()} tris | drag to orbit  `;

  const exportBtn = document.createElement('button');
  exportBtn.textContent = 'Export STL';
  exportBtn.addEventListener('click', () => downloadSTL(manifold));
  statusBar.appendChild(exportBtn);
};

/**
 * Create material options for show().
 * @param {number} r - Red (0-1)
 * @param {number} g - Green (0-1)
 * @param {number} b - Blue (0-1)
 * @returns {object} Material options to pass to show()
 */
const color = (r, g, b) => ({
  color: new THREE.Color(r, g, b)
});


// ── STL Export ────────────────────────────────────────

const downloadSTL = (manifold) => {
  const mesh = manifold.getMesh();
  const numProp = mesh.numProp;
  const verts = mesh.vertProperties;
  const tris = mesh.triVerts;
  const numTris = tris.length / 3;

  const bufLen = 80 + 4 + numTris * 50;
  const buf = new ArrayBuffer(bufLen);
  const view = new DataView(buf);

  view.setUint32(80, numTris, true);

  let offset = 84;
  for (let t = 0; t < numTris; t++) {
    const i0 = tris[t * 3], i1 = tris[t * 3 + 1], i2 = tris[t * 3 + 2];
    const v0 = [verts[i0*numProp], verts[i0*numProp+1], verts[i0*numProp+2]];
    const v1 = [verts[i1*numProp], verts[i1*numProp+1], verts[i1*numProp+2]];
    const v2 = [verts[i2*numProp], verts[i2*numProp+1], verts[i2*numProp+2]];

    const e1 = [v1[0]-v0[0], v1[1]-v0[1], v1[2]-v0[2]];
    const e2 = [v2[0]-v0[0], v2[1]-v0[1], v2[2]-v0[2]];
    const nx = e1[1]*e2[2] - e1[2]*e2[1];
    const ny = e1[2]*e2[0] - e1[0]*e2[2];
    const nz = e1[0]*e2[1] - e1[1]*e2[0];
    const len = Math.sqrt(nx*nx + ny*ny + nz*nz) || 1;

    view.setFloat32(offset, nx/len, true); offset += 4;
    view.setFloat32(offset, ny/len, true); offset += 4;
    view.setFloat32(offset, nz/len, true); offset += 4;

    for (const v of [v0, v1, v2]) {
      view.setFloat32(offset, v[0], true); offset += 4;
      view.setFloat32(offset, v[1], true); offset += 4;
      view.setFloat32(offset, v[2], true); offset += 4;
    }

    view.setUint16(offset, 0, true); offset += 2;
  }

  const blob = new Blob([buf], { type: 'application/octet-stream' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${document.title || 'model'}.stl`;
  a.click();
  URL.revokeObjectURL(url);
};


// ── Exports ───────────────────────────────────────────

export { Manifold, CrossSection, Mesh, show, color };
