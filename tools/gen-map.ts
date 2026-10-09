// Generates src/workspace/Arena.model.json and Spawns.model.json.
// Run: bun tools/gen-map.ts
// The arena is mirrored across X=0: two sniper towers at ±X, a raised bunker in the middle.

type V3 = [number, number, number];
type Part = { name: string; className: string; properties: Record<string, unknown>; tags?: string[] };

const parts: Part[] = [];
let n = 0;

const C = {
  floor: "#c9b48a",
  wall: "#8a8f98",
  concrete: "#a7a39b",
  dark: "#4b4f57",
  wood: "#9a6b3f",
  red: "#d6453d",
  blue: "#3d7bd6",
  metal: "#6c7480",
};

function part(name: string, size: V3, pos: V3, color: string, material = "SmoothPlastic", extra: Record<string, unknown> = {}) {
  parts.push({
    name: `${name}${++n}`,
    className: "Part",
    properties: { Anchored: true, Size: size, Position: pos, Color: color, Material: material, ...extra },
  });
}

// Plank ramp between two points; runs along X or Z only (single-axis rotation).
function ramp(name: string, a: V3, b: V3, width: number, color: string) {
  const dx = b[0] - a[0], dy = b[1] - a[1], dz = b[2] - a[2];
  const mid: V3 = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 0.5, (a[2] + b[2]) / 2];
  const deg = (r: number) => (r * 180) / Math.PI;
  if (Math.abs(dz) < 1e-6) {
    const sx = dx >= 0 ? 1 : -1;
    const len = Math.hypot(dx, dy);
    part(name, [len, 1, width], mid, color, "Concrete", { Orientation: [0, 0, deg(Math.atan2(dy * sx, dx * sx))] });
  } else {
    const sz = dz >= 0 ? 1 : -1;
    const len = Math.hypot(dz, dy);
    part(name, [width, 1, len], mid, color, "Concrete", { Orientation: [-deg(Math.atan2(dy * sz, dz * sz)), 0, 0] });
  }
}

const W = 240, D = 160, WALL_H = 26;

// Floor and boundary
part("Floor", [W, 1, D], [0, -0.5, 0], C.floor, "Sand");
part("Wall", [4, WALL_H, D + 8], [W / 2 + 2, WALL_H / 2, 0], C.wall, "Concrete");
part("Wall", [4, WALL_H, D + 8], [-W / 2 - 2, WALL_H / 2, 0], C.wall, "Concrete");
part("Wall", [W, WALL_H, 4], [0, WALL_H / 2, D / 2 + 2], C.wall, "Concrete");
part("Wall", [W, WALL_H, 4], [0, WALL_H / 2, -D / 2 - 2], C.wall, "Concrete");

// Mirrored halves: s = +1 (red side) / -1 (blue side)
for (const s of [1, -1]) {
  const accent = s > 0 ? C.red : C.blue;
  const tx = 96 * s; // tower center X
  const top = 16;

  // Sniper tower deck
  part("TowerDeck", [28, 1.5, 48], [tx, top - 0.75, 0], C.dark, "Metal");
  for (const px of [84, 108]) for (const pz of [-22, 22]) part("TowerLeg", [3, top - 1.5, 3], [px * s, (top - 1.5) / 2, pz], C.metal, "Metal");

  // Front parapet with firing gaps (faces the middle)
  const fx = 82.5 * s;
  for (const z of [-19.5, -6.5, 6.5, 19.5]) part("Parapet", [1, 3.5, 9], [fx, top + 1.75, z], accent);
  part("ParapetTrim", [1.2, 0.3, 48], [fx, top + 3.65, 0], accent, "Neon", { CanCollide: false });
  // Back wall
  part("TowerBack", [1, 7, 48], [109.5 * s, top + 3.5, 0], C.wall, "Concrete");
  // Side parapets leaving room for the ramps (ramps arrive at x 98..106)
  for (const z of [-23.5, 23.5]) part("SideParapet", [15, 3.5, 1], [90.5 * s, top + 1.75, z], accent);
  // Ramps down to the ground at both ends
  ramp("TowerRamp", [102 * s, top, -24], [102 * s, 0, -62], 8, C.concrete);
  ramp("TowerRamp", [102 * s, top, 24], [102 * s, 0, 62], 8, C.concrete);
  // Cover under the tower
  part("Crate", [5, 5, 5], [92 * s, 2.5, 8], C.wood, "Wood");
  part("Crate", [5, 5, 5], [92 * s, 2.5, -8], C.wood, "Wood");

  // Mid-field cover walls
  part("CoverWall", [14, 8, 2], [50 * s, 4, 32], C.concrete, "Concrete");
  part("CoverWall", [14, 8, 2], [50 * s, 4, -32], C.concrete, "Concrete");
  part("CoverWall", [2, 8, 16], [58 * s, 4, 0], C.concrete, "Concrete");
  part("CoverWall", [12, 6, 2], [28 * s, 3, 56], C.concrete, "Concrete");
  part("CoverWall", [12, 6, 2], [28 * s, 3, -56], C.concrete, "Concrete");

  // Tall pillars break long sightlines
  part("Pillar", [4, 22, 4], [34 * s, 11, 26], C.wall, "Concrete");
  part("Pillar", [4, 22, 4], [34 * s, 11, -26], C.wall, "Concrete");

  // Crate stacks (climbable: 5 studs up)
  for (const z of [-62, 62]) {
    part("Crate", [5, 5, 5], [60 * s, 2.5, z], C.wood, "Wood");
    part("Crate", [5, 5, 5], [65 * s, 2.5, z], C.wood, "Wood");
    part("Crate", [5, 5, 5], [65 * s, 7.5, z], C.wood, "Wood");
  }
  part("Crate", [6, 6, 6], [72 * s, 3, 18], C.wood, "Wood");
  part("Crate", [6, 6, 6], [72 * s, 3, -18], C.wood, "Wood");
  part("Crate", [4, 4, 4], [16 * s, 2, 32], C.wood, "Wood");
  part("Crate", [4, 4, 4], [16 * s, 2, -32], C.wood, "Wood");

  // Long low trench walls near the back edges
  part("Trench", [30, 4, 2], [72 * s, 2, 44], C.concrete, "Concrete");
  part("Trench", [30, 4, 2], [72 * s, 2, -44], C.concrete, "Concrete");

  // Ramp up to the central bunker
  ramp("BunkerRamp", [12 * s, 6, 0], [30 * s, 0, 0], 6, C.concrete);
}

// Central bunker: raised deck with low walls
part("Bunker", [24, 6, 24], [0, 3, 0], C.dark, "Concrete");
part("BunkerWall", [24, 3, 1], [0, 7.5, 11.5], C.concrete, "Concrete");
part("BunkerWall", [24, 3, 1], [0, 7.5, -11.5], C.concrete, "Concrete");
part("BunkerTrim", [24.2, 0.3, 24.2], [0, 6.1, 0], "#e0b03a", "Neon", { CanCollide: false, Transparency: 0.85 });
// Central walls on the long axis
part("CenterWall", [20, 8, 2], [0, 4, 46], C.concrete, "Concrete");
part("CenterWall", [20, 8, 2], [0, 4, -46], C.concrete, "Concrete");

const arena = { className: "Model", children: parts };
await Bun.write(new URL("../src/workspace/Arena.model.json", import.meta.url), JSON.stringify(arena, null, 1));

// Spawns: neutral, 3 s of spawn protection
const spawnSpots: V3[] = [
  [96, 0.5, 0], [-96, 0.5, 0],
  [60, 0.5, 72], [60, 0.5, -72], [-60, 0.5, 72], [-60, 0.5, -72],
  [0, 0.5, 70], [0, 0.5, -70],
];
const spawns = {
  className: "Folder",
  children: spawnSpots.map((p, i) => ({
    name: `Spawn${i + 1}`,
    className: "SpawnLocation",
    properties: { Anchored: true, Size: [6, 1, 6], Position: p, Color: "#e0b03a", Material: "SmoothPlastic", Neutral: true, Duration: 3 },
  })),
};
await Bun.write(new URL("../src/workspace/Spawns.model.json", import.meta.url), JSON.stringify(spawns, null, 1));
console.log(`arena parts: ${parts.length}, spawns: ${spawnSpots.length}`);
