import {getLength, getPointAtLength} from '@remotion/paths';

type Point = [number, number];

/**
 * Morphing between any two closed shapes.
 *
 * interpolatePath() from @remotion/paths works when both paths have a similar structure.
 * Shapes built differently, such as a heart made of curves and a circle made of arcs,
 * can tear or collapse mid-morph. This resamples both outlines to the same number of
 * evenly spaced points, matches their winding and starting point, then blends point
 * by point and draws a smooth curve through the result.
 */
const toPoints = (d: string, count: number): Point[] => {
  const length = getLength(d);
  const pts = Array.from({length: count}, (_, i): Point => {
    const p = getPointAtLength(d, (i / count) * length);
    if (!p) throw new Error(`Can't sample point ${i} of path: ${d.slice(0, 60)}…`);
    return [p.x, p.y];
  });
  // Shoelace sign gives the winding. Make every outline run the same way.
  const area = pts.reduce((sum, [x, y], i) => {
    const [nx, ny] = pts[(i + 1) % count];
    return sum + (x * ny - nx * y);
  }, 0);
  return area < 0 ? pts.reverse() : pts;
};

/** Rotates `to` so its points line up with `from` (the least total travel). */
const align = (from: Point[], to: Point[]): Point[] => {
  const n = from.length;
  let best = 0;
  let bestCost = Infinity;
  for (let offset = 0; offset < n; offset++) {
    let cost = 0;
    for (let i = 0; i < n && cost < bestCost; i++) {
      const [ax, ay] = from[i];
      const [bx, by] = to[(i + offset) % n];
      cost += (ax - bx) ** 2 + (ay - by) ** 2;
    }
    if (cost < bestCost) {
      bestCost = cost;
      best = offset;
    }
  }
  return [...to.slice(best), ...to.slice(0, best)];
};

/** A closed Catmull-Rom spline through the points, written as cubic Béziers. */
const smoothPath = (pts: Point[]) => {
  const n = pts.length;
  const f = (v: number) => v.toFixed(2);
  let d = `M ${f(pts[0][0])} ${f(pts[0][1])}`;
  for (let i = 0; i < n; i++) {
    const [p0, p1, p2, p3] = [pts[(i - 1 + n) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]];
    const c1x = p1[0] + (p2[0] - p0[0]) / 6;
    const c1y = p1[1] + (p2[1] - p0[1]) / 6;
    const c2x = p2[0] - (p3[0] - p1[0]) / 6;
    const c2y = p2[1] - (p3[1] - p1[1]) / 6;
    d += ` C ${f(c1x)} ${f(c1y)} ${f(c2x)} ${f(c2y)} ${f(p2[0])} ${f(p2[1])}`;
  }
  return `${d} Z`;
};

/**
 * Prepares a morph from one closed path to another and returns `(t) => path`.
 * At t = 0 and t = 1 you get the original paths back exactly. Build it once with
 * useMemo, because the setup samples both outlines.
 */
export const makeMorph = (from: string, to: string, samples = 180) => {
  const a = toPoints(from, samples);
  const b = align(a, toPoints(to, samples));
  return (t: number) => {
    if (t <= 0) return from;
    if (t >= 1) return to;
    return smoothPath(
      a.map(([ax, ay], i): Point => [ax + (b[i][0] - ax) * t, ay + (b[i][1] - ay) * t]),
    );
  };
};
