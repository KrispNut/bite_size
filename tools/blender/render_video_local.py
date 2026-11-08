"""Render every missing video-matched frame on this machine, then compose + pack into the app.
Keeps Windows awake while it works (no settings changed). Log: tools/blender/render_video.log"""
import ctypes, os, subprocess, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
LOG = os.path.join(ROOT, "tools", "blender", "render_video.log")
def run(args):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(time.strftime("%H:%M:%S RUN ") + " ".join(args) + "\n"); f.flush()
        if subprocess.run(args, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT).returncode:
            raise SystemExit("failed: " + args[1])
ctypes.windll.kernel32.SetThreadExecutionState(0x80000000 | 0x00000001)
try:
    bl = os.path.join(ROOT, "tools", "blender")
    run([B, "-b", "--factory-startup", "-P", "tools/blender/video_anim.py", "--",
         "--out", os.path.join(bl, "render"), "--fit", os.path.join(bl, "fit", "fit.json"),
         "--model", os.path.join(bl, "models", "zootopia_style_hand_base.glb"),
         "--samples", "16", "--frames", "0-148", "--skip-existing"])
    run([sys.executable, "tools/blender/compose_frames.py"])
    run([sys.executable, "tools/blender/pack_lottie.py"])
    with open(LOG, "a") as f: f.write(time.strftime("%H:%M:%S ") + "DONE: assets/lottie/refresh*.json updated\n")
finally:
    ctypes.windll.kernel32.SetThreadExecutionState(0x80000000)
