"""
Renders the pull-to-refresh hand animation (149 frames, 30 fps), same timeline and markers as
assets/lottie/refresh.json so lib/core/widgets/lottie_refresh.dart works unchanged:
  settle 0-9 | curl 9-17 | press 17-22 | pull 22-34 | release 34-46 | hidden 46-98 |
  return 98-113 | sway 113-149

For every visible frame it writes, to --out:
  main_###.png  Cycles render (hand + cloth sheet)
  mask_###.png  Workbench render: hand white, everything else black (antialiased)
and once:  ref.png  the empty, flat sheet under the same lights
tools/blender/compose_frames.py turns those into transparent overlay frames.

Run headless (takes a while on CPU):
  blender -b --factory-startup -P tools/blender/video_anim.py -- --out tools/blender/render
      --fit tools/blender/fit/fit.json --model tools/blender/models/zootopia_style_hand_base.glb
      [--samples 16] [--frames 0-148] [--gpu] [--nomask] [--skip-existing]
  (or on Colab: python tools/blender/make_notebooks_video.py --one, then upload the notebook)
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def arg(name, default=None):
    return argv[argv.index(name) + 1] if name in argv else default

OUT = arg("--out")
SAMPLES = int(arg("--samples", "16"))
RES = (int(arg("--w", "1144")), int(arg("--h", "760")))
lo, hi = (int(v) for v in arg("--frames", "0-199").split("-"))
ONLY = {int(v) for v in arg("--only", "").split(",") if v}   # test a few frames
BG = (0xF4 / 255, 0xFA / 255, 0xFF / 255)       # app background (light)
os.makedirs(OUT, exist_ok=True)

def lerp(a, b, t): return a + (b - a) * t
def clamp(x, a=0.0, b=1.0): return max(a, min(b, x))
def smooth(t): t = clamp(t); return t * t * (3 - 2 * t)
def seg(f, a, b): return clamp((f - a) / (b - a))
def table(f, pts):
    if f <= pts[0][0]: return pts[0][1]
    for (f0, v0), (f1, v1) in zip(pts, pts[1:]):
        if f <= f1: return lerp(v0, v1, (f - f0) / (f1 - f0))
    return pts[-1][1]
def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

# --------------------------------------------------------------------------- motion
# 200 frames @ 30 fps. The hand searches the sheet (left tap, right tap), finds it in
# the centre, grabs, pulls it up out of the top, comes back in and idles back to frame 0.
#   enter 0-12 | search 12-60 | curl 60-68 | press 68-76 | pull 76-92 | release 92-104 |
#   hidden 104-150 | return 150-165 | idle 165-200
OP = 200

def ease(t):
    t = clamp(t)
    return t * t * t * (t * (6 * t - 15) + 10)          # smootherstep: no velocity jumps

def spline(f, keys):
    """Catmull-Rom through [(frame, value)]: smooth velocity across keys (no jerks)"""
    if f <= keys[0][0]: return keys[0][1]
    if f >= keys[-1][0]: return keys[-1][1]
    for i in range(len(keys) - 1):
        (f1, v1), (f2, v2) = keys[i], keys[i + 1]
        if f <= f2:
            f0, v0 = keys[i - 1] if i > 0 else (2 * f1 - f2, v1)
            f3, v3 = keys[i + 2] if i + 2 < len(keys) else (2 * f2 - f1, v2)
            t = (f - f1) / (f2 - f1)
            # tangents scaled to each segment's length (non-uniform key spacing)
            m1 = (v2 - v0) / (f2 - f0) * (f2 - f1)
            m2 = (v3 - v1) / (f3 - f1) * (f2 - f1)
            t2, t3 = t * t, t * t * t
            return ((2 * t3 - 3 * t2 + 1) * v1 + (t3 - 2 * t2 + t) * m1
                    + (-2 * t3 + 3 * t2) * v2 + (t3 - t2) * m2)

def eased(f, keys):
    """each segment eases in and out (holds at every key)"""
    if f <= keys[0][0]: return keys[0][1]
    for (f0, v0), (f1, v1) in zip(keys, keys[1:]):
        if f <= f1: return lerp(v0, v1, ease((f - f0) / (f1 - f0)))
    return keys[-1][1]

# swing in degrees (+ = left); looping: frame 200 == frame 0
ROT_KEYS = [(-10, 0.0), (0, 0.0), (12, 0.0), (22, 22.0), (30, 24.0), (40, -6.0), (46, -24.0),
            (52, -25.0), (60, -2.0), (66, 0.0), (104, 0.0), (150, 0.0), (165, 0.0), (176, 9.0),
            (188, -7.0), (200, 0.0), (212, 0.0)]
def rot_at(f): return spline(f, ROT_KEYS)

# vertical travel in reference pixels (- = up); 143 px = 1 world unit
DY_KEYS = [(0, 0), (76, 0), (79, -6), (92, -250), (150, -250), (162, 10), (170, 0), (200, 0)]
PX = 1 / 143.0
def dy_at(f): return eased(f, DY_KEYS)

def curl_at(f):        # 0 open hand .. 1 fist
    return ease(seg(f, 60, 68)) if f < 120 else 0.0
def tap_at(f):         # searching taps: dip to the sheet and back
    return max(ease(1 - abs(f - 27) / 4), ease(1 - abs(f - 49) / 4), 0.0)
def press_at(f):       # fist lowered onto the sheet, lifted as the pull starts
    return ease(seg(f, 66, 74)) * (1 - ease(seg(f, 77, 81))) if f < 120 else 0.0
def visible(f):
    return f <= 104 or f >= 150

PIVOT = Vector((0.035, 1.48, 0.0))     # where the arm swings from (above the top edge)
REST_KNUCKLE_Y = -0.05                 # knuckles' world y at rest
HOVER, PRESSED = 0.44, 0.3             # hand height above the sheet
PINCH = Vector((0.0, -0.22, 0.0))      # where the knuckles grab the sheet

# --------------------------------------------------------------------------- scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = 30
scene.frame_start, scene.frame_end = 1, 150
scene.render.resolution_x, scene.render.resolution_y = RES
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "None"

world = bpy.data.worlds.new("World")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = tuple(srgb_to_linear(c) for c in BG) + (1,)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.35

cam_data = bpy.data.cameras.new("Cam")
cam_data.lens, cam_data.sensor_fit, cam_data.sensor_width = 50, "HORIZONTAL", 36
cam = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam)
cam.location = (0, 0, 4 * 50 / 36)
scene.camera = cam

def area(name, loc, rot, size, power, color=(1, 1, 1)):
    d = bpy.data.lights.new(name, "AREA")
    d.size, d.energy, d.color = size, power, color
    o = bpy.data.objects.new(name, d)
    o.location, o.rotation_euler = loc, rot
    scene.collection.objects.link(o)

area("Key", (-3.2, 2.6, 2.2), (math.radians(-50), math.radians(-52), math.radians(-35)), 3.0, 380)
area("Fill", (2.5, -1.5, 4.5), (math.radians(18), math.radians(28), 0), 6.0, 90, (0.9, 0.94, 1.0))
area("Top", (0, 0, 6), (0, 0, 0), 8.0, 110)

def mat_clay():
    m = bpy.data.materials.new("Clay")
    m.use_nodes = True
    nt = m.node_tree
    p = nt.nodes["Principled BSDF"]
    p.inputs["Roughness"].default_value = 0.42
    p.inputs["Subsurface Weight"].default_value = 0.35
    p.inputs["Subsurface Radius"].default_value = (0.6, 0.25, 0.2)
    p.inputs["Subsurface Scale"].default_value = 0.08
    p.inputs["Coat Weight"].default_value = 0.15
    p.inputs["Coat Roughness"].default_value = 0.3
    ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.06
    ao.samples = 4
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs["A"].default_value = (0.42, 0.1, 0.13, 1)
    mix.inputs["B"].default_value = (0.86, 0.33, 0.37, 1)
    nt.links.new(ao.outputs["AO"], mix.inputs["Factor"])
    nt.links.new(mix.outputs["Result"], p.inputs["Base Color"])
    return m

CLAY = mat_clay()
SHEET_MAT = bpy.data.materials.new("Sheet")
SHEET_MAT.use_nodes = True
sp = SHEET_MAT.node_tree.nodes["Principled BSDF"]
# mid grey, not the app colour: a near-white sheet clips to pure white under the key light
# and swallows the soft shadows. compose_frames.py only measures how much darker each pixel
# is than the empty sheet, so the sheet's own brightness never reaches the app.
sp.inputs["Base Color"].default_value = (0.3, 0.31, 0.33, 1)
sp.inputs["Roughness"].default_value = 0.85
sp.inputs["Sheen Weight"].default_value = 0.4

# --------------------------------------------------------------------------- the hand
def skin_chain_mesh(points, radii):
    me = bpy.data.meshes.new("chain")
    me.from_pydata([tuple(p) for p in points], [(i, i + 1) for i in range(len(points) - 1)], [])
    ob = bpy.data.objects.new("chain", me)
    scene.collection.objects.link(ob)
    sk = ob.modifiers.new("Skin", "SKIN")
    sk.use_smooth_shade = True
    for i, r in enumerate(radii):
        me.skin_vertices[0].data[i].radius = r if isinstance(r, tuple) else (r, r)
    me.skin_vertices[0].data[0].use_root = True
    ob.modifiers.new("Subsurf", "SUBSURF").levels = 3
    bpy.context.view_layer.update()
    baked = bpy.data.meshes.new_from_object(ob.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(me)
    return baked

# Chubby baby hand like the reference: a thick arm that stays thick, a hand barely
# wider than the arm, four short stubby fingers curled down toward the camera and a
# thumb sticking out to the right. Local space: hand centre at the origin, arm up +y,
# +z towards the camera.
FINGERS = ((-0.165, 0.01, 0.092), (-0.055, 0.03, 0.1), (0.055, 0.025, 0.1), (0.16, 0.0, 0.094))
SCALE = float(arg("--scale", "1.0"))

ROLL = float(arg("--roll", "-30"))        # hand turned at the wrist, palm side towards the left

# Open: the chubby fingers hang down (-y), tips curling a little towards the camera, thumb
# pointing down-right. Fist: a compact ball, finger nubs curled under at the bottom front,
# thumb wrapped across them. Matches the reference frame by frame.
def finger_points(x, reach, c):
    opn = [(x * 0.8, 0.12, 0.0), (x * 1.05, -0.1 - reach, 0.02), (x * 1.25, -0.27 - reach, 0.02),
           (x * 1.35, -0.4 - reach, 0.07)]
    fist = [(x * 0.8, 0.12, 0.0), (x, -0.08 - reach, 0.04), (x, -0.17 - reach, 0.14),
            (x * 0.95, -0.1 - reach, 0.24)]
    return [tuple(lerp(a, b, c) for a, b in zip(o, f)) for o, f in zip(opn, fist)]

def thumb_points(c):
    opn = [(0.14, 0.12, 0.02), (0.27, 0.0, 0.04), (0.36, -0.12, 0.05), (0.4, -0.22, 0.07)]
    fist = [(0.14, 0.12, 0.04), (0.22, -0.04, 0.12), (0.12, -0.16, 0.2), (0.0, -0.17, 0.22)]
    return [tuple(lerp(a, b, c) for a, b in zip(o, f)) for o, f in zip(opn, fist)]

MODEL = arg("--model")   # a downloaded cartoon hand (.glb); replaces the procedural hand
_MODEL_CACHE = {}

def _model_base():
    """the model's vertices/faces in hand space: mirrored so the thumb is on the right,
    knuckle line at the origin, fingers along -y, back of the hand towards +z"""
    if "v" in _MODEL_CACHE:
        return _MODEL_CACHE["v"], _MODEL_CACHE["f"]
    import numpy as np
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=MODEL)
    new = [o for o in bpy.data.objects if o not in before]
    verts, faces = [], []
    for o in new:
        if o.type != "MESH":
            continue
        base = len(verts)
        m = o.matrix_world
        verts += [tuple(m @ v.co) for v in o.data.vertices]
        faces += [tuple(base + i for i in reversed(poly.vertices)) for poly in o.data.polygons]  # mirrored: flip winding
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)
    V = np.array(verts, dtype=np.float64)
    V[:, 0] *= -1                                   # thumb to the right
    knuckle_y = -1.5                                # where the fingers leave the hand (model units)
    V[:, 1] -= knuckle_y
    k = MODEL_SCALE / (V[:, 0].max() - V[:, 0].min())
    V *= k
    _MODEL_CACHE.update(v=V, f=faces, k=k)
    return V, faces

MODEL_SCALE = float(arg("--model-width", "0.86"))  # hand width in world units

def _curl_model(V, c):
    """curl the fingers under (arc bend about the knuckle line towards the palm, -z)
    and tuck the thumb across, blended smoothly from the back of the hand."""
    import numpy as np
    if c <= 0:
        return V.copy()
    k = _MODEL_CACHE["k"]
    out = V.copy()
    x, y, z = V[:, 0], V[:, 1], V[:, 2]
    thumb = np.clip((x - 1.0 * k) / (0.15 * k), 0, 1) * np.clip((y + 0.2 * k) / (0.3 * k), 0, 1)         * np.clip((1.2 * k - y) / (0.3 * k), 0, 1)
    # fingers: weight ramps in just past the knuckles
    d = np.maximum(0.0, -y)                         # distance past the knuckle line
    w = np.clip(d / (0.35 * k), 0, 1); w = w * w * (3 - 2 * w) * (1 - thumb)
    L = 1.2 * k                                     # finger length
    theta = c * math.radians(250)
    R = L / theta
    zc = -0.3 * k - R                               # bend centre, palm side
    r = (z - zc)
    phi = d / R
    by = -r * np.sin(phi)
    bz = zc + r * np.cos(phi)
    out[:, 1] = y + (by - y) * w
    out[:, 2] = z + (bz - z) * w
    # thumb: swings in under the fingers
    base = np.array([1.05 * k, 0.45 * k, -0.2 * k])
    q1 = Quaternion((0, 1, 0), math.radians(38 * c)) @ Quaternion((0, 0, 1), math.radians(-32 * c))
    M = np.array(q1.to_matrix())
    t = (V - base) @ M.T + base
    out = out + (t - out) * thumb[:, None]
    return out

def build_hand_model(c):
    import numpy as np, time as _t
    t0 = _t.time()
    V, faces = _model_base()
    hand = _curl_model(V, c)
    me = bpy.data.meshes.new("ModelHand")
    me.from_pydata(hand.tolist(), [], faces)
    # the arm: a chubby tube from above the frame down into the open wrist
    k = _MODEL_CACHE["k"]
    wrist_y = 2.6 * k                               # top of the hand's wrist opening (model y 1.1 + 1.5)
    # tapers into the hand and ends well inside it, so the wrist has no step
    # Inside the hand the arm widens to the hand's own width, so the hand's outline carries
    # straight on up into the arm; it plugs the open wrist and ends deep inside the hand.
    zc = -0.065
    arm = skin_chain_mesh([Vector((0, 3.6, 0.42)), Vector((0, 1.3, 0.1)), Vector((0, wrist_y + 0.1, zc)),
                           Vector((0, wrist_y - 0.12, zc)), Vector((0, wrist_y - 0.3, zc)),
                           Vector((-0.03, wrist_y - 0.5, zc))],
                          [(0.3, 0.26), (0.3, 0.22), (0.31, 0.2), (0.3, 0.18), (0.28, 0.16), (0.22, 0.12)])
    bm = bmesh.new()
    bm.from_mesh(me); bm.from_mesh(arm)
    bpy.data.meshes.remove(arm)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("Hand", me)
    scene.collection.objects.link(ob)
    rm = ob.modifiers.new("Fuse", "REMESH")     # hand + arm become one smooth surface
    rm.mode, rm.voxel_size, rm.use_smooth_shade = "VOXEL", 0.0045, True
    # bake the fused mesh, then blend the wrist away: heavy smoothing in a band around the
    # join, fading out above and below (Taubin smoothing, so the arm doesn't shrink)
    bpy.context.view_layer.update()
    fused = bpy.data.meshes.new_from_object(ob.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    ob.modifiers.clear()
    old = ob.data; ob.data = fused; bpy.data.meshes.remove(old)
    P = np.empty(len(fused.vertices) * 3); fused.vertices.foreach_get("co", P); P = P.reshape(-1, 3)
    E = np.empty(len(fused.edges) * 2, dtype=np.int64); fused.edges.foreach_get("vertices", E); E = E.reshape(-1, 2)
    deg = np.bincount(E.ravel(), minlength=len(P)).astype(np.float64)[:, None]
    dy = np.abs(P[:, 1] - (wrist_y - 0.1))
    w = np.clip((0.5 - dy) / 0.3, 0, 1); w = (w * w * (3 - 2 * w))[:, None]
    for i in range(300):
        nb = np.stack([np.bincount(E[:, 0], P[E[:, 1], j], len(P)) + np.bincount(E[:, 1], P[E[:, 0], j], len(P))
                       for j in range(3)], axis=1)
        lap = nb / np.maximum(deg, 1) - P
        P = P + (0.6 if i % 2 == 0 else -0.62) * w * lap
    fused.vertices.foreach_set("co", P.ravel()); fused.update()
    sm = ob.modifiers.new("Soften", "CORRECTIVE_SMOOTH")
    sm.factor, sm.iterations, sm.use_only_smooth, sm.smooth_type = 0.8, 30, True, "LENGTH_WEIGHTED"
    pol = ob.modifiers.new("Polish", "SUBSURF")
    pol.levels, pol.render_levels = 0, 1
    ob.data.materials.append(CLAY)
    ob.color = (1, 1, 1, 1)
    print(f"TIMING build curl={c}: {_t.time() - t0:.1f}s, {len(ob.data.vertices)} verts", flush=True)
    return ob

def build_hand(c):
    if MODEL:
        return build_hand_model(c)
    return build_hand_procedural(c)

def build_hand_procedural(c):
    """hand mesh for curl c (0 open, 1 fist), knuckles at the origin, arm up +y"""
    S = lambda co: Vector(co) * SCALE
    HS = 1.4 * SCALE            # the hand is big next to the arm, like the reference
    roll = Quaternion((0, 1, 0), math.radians(ROLL))
    H = lambda co: (roll @ Vector(co)) * HS
    parts = [skin_chain_mesh(
        [S((0.0, 3.6, 0.42)), S((0.0, 1.0, 0.14)), S((0.0, 0.5, 0.06)), H((0.0, 0.14, 0.02)), H((0.0, 0.0, -0.01))],
        [tuple(v * SCALE for v in r) for r in ((0.31, 0.28), (0.29, 0.26), (0.27, 0.24))]
        + [tuple(v * HS for v in r) for r in ((0.26, 0.24), (0.24, 0.21))])]
    for x, reach, r in FINGERS:
        rr = r * lerp(0.85, 1.0, c)    # open fingers slimmer than the curled nubs
        parts.append(skin_chain_mesh([H(p) for p in finger_points(x, reach, c)],
                                     [(rr * 1.3 * HS, rr * 0.9 * HS), rr * 1.08 * HS, rr * HS, rr * 0.92 * HS]))
    parts.append(skin_chain_mesh([H(p) for p in thumb_points(c)], [v * HS for v in (0.115, 0.1, 0.092, 0.085)]))
    bm = bmesh.new()
    for me in parts:
        bm.from_mesh(me)
        bpy.data.meshes.remove(me)
    me = bpy.data.meshes.new("HandMesh")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("Hand", me)
    scene.collection.objects.link(ob)
    rm = ob.modifiers.new("Fuse", "REMESH")
    rm.mode, rm.voxel_size, rm.use_smooth_shade = "VOXEL", 0.0045, True
    sm = ob.modifiers.new("Soften", "CORRECTIVE_SMOOTH")
    sm.factor, sm.iterations, sm.use_only_smooth, sm.smooth_type = 0.85, 40, True, "LENGTH_WEIGHTED"
    pol = ob.modifiers.new("Polish", "SUBSURF")
    pol.levels, pol.render_levels = 0, 2
    ob.data.materials.append(CLAY)
    ob.color = (1, 1, 1, 1)
    return ob

def place_hand(ob, f):
    rot = -math.radians(rot_at(f))               # + in the table = swings left
    rise = -dy_at(f) * PX                        # up, world units
    z = lerp(HOVER, PRESSED, max(press_at(f), 0.7 * tap_at(f))) + rise * 0.25
    hang = Vector((0.0, REST_KNUCKLE_Y - PIVOT.y + rise, 0.0))
    R = Matrix.Rotation(rot, 4, "Z")
    ob.matrix_world = Matrix.Translation(PIVOT + Vector((0, 0, z))) @ R @ Matrix.Translation(hang)

FIT_PATH = arg("--fit")
FIT = None
if FIT_PATH and os.path.exists(FIT_PATH):
    import json
    FIT = {int(k): v for k, v in json.load(open(FIT_PATH))["frames"].items()}
    OP = 149

def place_fitted(ob, p):
    """per-frame pose measured from the reference video: rot (deg, + = left),
    dx/dy (world units, + = right/up), curl and z"""
    R = Matrix.Rotation(-math.radians(p["rot"]), 4, "Z")
    Sc = Matrix.Scale(p.get("s", 1.0), 4)        # scaled about the pivot, like the 2D fit
    hang = Vector((0.0, REST_KNUCKLE_Y - PIVOT.y + p["dy"], 0.0))
    ob.matrix_world = (Matrix.Translation(PIVOT + Vector((p["dx"], 0, p["z"]))) @ R @ Sc
                       @ Matrix.Translation(hang))

# --------------------------------------------------------------------------- the sheet (cloth)
bpy.ops.mesh.primitive_grid_add(x_subdivisions=190, y_subdivisions=150, size=1)
sheet = bpy.context.active_object
sheet.name = "Sheet"
sheet.scale = (6.4, 5.0, 1)          # well past the frame on every side
bpy.ops.object.transform_apply(scale=True)
sheet.data.materials.append(SHEET_MAT)
sheet.color = (0, 0, 0, 1)
for poly in sheet.data.polygons:
    poly.use_smooth = True
pinch_g = sheet.vertex_groups.new(name="pinch")
pins_g = sheet.vertex_groups.new(name="pins")
for v in sheet.data.vertices:
    x, y = v.co.x, v.co.y
    if math.hypot(x - PINCH.x, (y - PINCH.y) * 1.15) < 0.26:
        pinch_g.add([v.index], 1.0, "REPLACE")
        pins_g.add([v.index], 1.0, "REPLACE")
    if abs(x) > 3.1 or abs(y) > 2.4:   # all four edges held, out of sight
        pins_g.add([v.index], 1.0, "REPLACE")

# The cloth folds come from compose_frames.py (the cleaned-up fabric layer), so by
# default the sheet stays flat: faster, and the hand still casts its real shadow.
if "--cloth" in argv:
    grab = bpy.data.objects.new("Grab", None)
    scene.collection.objects.link(grab)
    grab.location = PINCH
    hook = sheet.modifiers.new("Hook", "HOOK")
    hook.object = grab
    hook.vertex_group = "pinch"
    scene.frame_set(1)
    bpy.context.view_layer.update()
    hook.center = grab.matrix_world.translation
    hook.matrix_inverse = grab.matrix_world.inverted()
    # blender frame = animation frame + 1
    def key_grab(f, loc, strength=1.0):
        grab.location = loc
        grab.keyframe_insert("location", frame=f + 1)
        hook.strength = strength
        sheet.keyframe_insert('modifiers["Hook"].strength', frame=f + 1)
    key_grab(0, PINCH)
    key_grab(16, PINCH)
    key_grab(21, PINCH + Vector((0, 0, -0.05)))                       # pressed in
    key_grab(26, PINCH + Vector((0, 0.45, 0.6)))
    key_grab(33, Vector((0.0, 1.35, 1.1)))                            # dragged up and to the top edge
    key_grab(35, Vector((0.0, 1.35, 1.1)))
    key_grab(46, PINCH)                                               # let go: the sheet glides back flat
    key_grab(60, PINCH)

    cloth = sheet.modifiers.new("Cloth", "CLOTH")
    cs = cloth.settings
    cs.quality = 10
    cs.mass = 0.18
    cs.tension_stiffness = 60
    cs.compression_stiffness = 0.4
    cs.shear_stiffness = 30
    cs.bending_stiffness = 0.02
    cs.air_damping = 2.0
    cs.vertex_group_mass = "pins"
    cs.effector_weights.gravity = 0.0
    cloth.point_cache.frame_start = 1
    cloth.point_cache.frame_end = 60
sheet.modifiers.new("Smooth", "SUBSURF").render_levels = 1

# --------------------------------------------------------------------------- render helpers
GPU = "--gpu" in argv
if GPU:   # e.g. Google Colab: use every NVIDIA GPU via OptiX (falls back to CUDA)
    prefs = bpy.context.preferences.addons["cycles"].preferences
    for kind in ("OPTIX", "CUDA"):
        try:
            prefs.compute_device_type = kind
            prefs.get_devices()
            if any(d.type == kind for d in prefs.devices):
                break
        except TypeError:
            continue
    for d in prefs.devices:
        d.use = d.type != "CPU"
    print("GPU devices:", [d.name for d in prefs.devices if d.use], flush=True)

def use_cycles():
    scene.render.engine = "CYCLES"
    scene.cycles.device = "GPU" if GPU else "CPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = "OPENIMAGEDENOISE"
    scene.cycles.max_bounces = 4
    scene.cycles.diffuse_bounces = 2
    scene.cycles.glossy_bounces = 2
    scene.cycles.transmission_bounces = 2
    scene.cycles.use_adaptive_sampling = True
    scene.view_settings.view_transform = "Standard"

def use_mask():
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.light = "FLAT"
    sh.color_type = "OBJECT"
    scene.display.render_aa = "16"
    world.color = (0, 0, 0)
    scene.view_settings.view_transform = "Standard"

def render_to(path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)

hand = None
if "--masks" in argv:          # rest-pose silhouettes for fit_video.py
    use_mask()
    for c in (0.0, 0.25, 0.5, 0.75, 1.0):
        h = build_hand(c)
        place_fitted(h, {"rot": 0.0, "dx": 0.0, "dy": 0.0, "z": HOVER})
        bpy.context.view_layer.update()
        render_to(os.path.join(OUT, f"rest_{int(c * 100):03d}.png"))
        bpy.data.objects.remove(h)
    print("ALL DONE", flush=True)
    raise SystemExit
if "--look" in argv:           # look-dev: open hand and fist side by side
    use_cycles()
    for c, dx in ((0.0, -0.75), (1.0, 0.75)):
        h = build_hand(c)
        place_fitted(h, {"rot": 0.0, "dx": dx, "dy": -0.35, "z": HOVER})
    bpy.context.view_layer.update()
    render_to(os.path.join(OUT, "look.png"))
    print("ALL DONE", flush=True)
    raise SystemExit
# reference: the empty, flat sheet under the same lights
scene.frame_set(1)
use_cycles()
if not os.path.exists(os.path.join(OUT, "ref.png")) or "--ref" in argv:
    render_to(os.path.join(OUT, "ref.png"))

HANDS = {}
for f in range(0, OP):
    # cloth sim steps through its cache in order; once the hand has let go the
    # sheet is flat again, so the return/sway frames reuse the untouched first frame
    scene.frame_set(f + 1 if f <= 59 else 1)
    shown = (f in FIT) if FIT is not None else visible(f)
    if f < lo or f > hi or not shown or (ONLY and f not in ONLY):
        continue
    if "--skip-existing" in argv and os.path.exists(os.path.join(OUT, f"main_{f:03d}.png")):
        continue
    if FIT is not None:
        # the hand's shape only changes during the curl: build each shape once and reuse it
        c = round(FIT[f]["curl"], 3)
        if c not in HANDS:
            HANDS[c] = build_hand(c)
        for k, h in HANDS.items():
            h.hide_render = k != c
        hand = HANDS[c]
        place_fitted(hand, FIT[f])
    else:
        if hand is not None:
            me = hand.data
            bpy.data.objects.remove(hand)
            bpy.data.meshes.remove(me)
        hand = build_hand(curl_at(f))
        place_hand(hand, f)
    bpy.context.view_layer.update()
    use_cycles()
    render_to(os.path.join(OUT, f"main_{f:03d}.png"))
    try:      # the mask only guides where to look; compose_frames.py copes without it
        if "--nomask" in argv:
            raise RuntimeError("--nomask")
        use_mask()
        render_to(os.path.join(OUT, f"mask_{f:03d}.png"))
    except Exception as e:
        print("mask render skipped:", e, flush=True)
    print(f"FRAME {f} done", flush=True)
print("ALL DONE", flush=True)
