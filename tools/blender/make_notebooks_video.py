"""
Writes three self-contained notebooks (Colab or Kaggle) that render the video-matched hand:
video_anim.py + the frame-by-frame fit + the downloaded hand model are all embedded.
Run:  python tools/blender/make_notebooks_video.py
"""
import base64
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
import sys
PARTS = {"ALL": "0-148"} if "--one" in sys.argv else {"A": "0-25", "B": "26-121", "C": "122-148"}
SAMPLES = 16
MODEL = "zootopia_style_hand_base.glb"

script = open(os.path.join(HERE, "video_anim.py"), encoding="utf-8").read()
fit = open(os.path.join(HERE, "fit", "fit.json"), encoding="utf-8").read()
model_b64 = base64.b64encode(open(os.path.join(HERE, "models", MODEL), "rb").read()).decode()

def md(t): return {"cell_type": "markdown", "metadata": {}, "source": t}
def code(t): return {"cell_type": "code", "metadata": {}, "execution_count": None, "outputs": [], "source": t}

for name, frames in PARTS.items():
    zipname = f"video_{name}_{frames}"
    cells = [
        md(f"# Bite Size hand (video match) - part {name}, frames {frames}\n\n"
           "**Colab:** Runtime → Change runtime type → **T4 GPU** → Save, then Runtime → **Run all**.\n\n"
           f"When it finishes, `{zipname}.zip` downloads. Send it back.\n\n"
           "Hand model: \"Zootopia style hand base\" by Lizzy Koopa (CC BY 4.0)."),
        code("!nvidia-smi -L"),
        code("!apt-get -qq install -y libxi6 libxxf86vm1 libxfixes3 libxrender1 libgl1 libxkbcommon0 libsm6 > /dev/null 2>&1\n"
             "!wget -q https://download.blender.org/release/Blender5.2/blender-5.2.3-linux-x64.tar.xz\n"
             "!tar -xf blender-5.2.3-linux-x64.tar.xz && ./blender-5.2.3-linux-x64/blender -b --version | head -1"),
        code("%%writefile video_anim.py\n" + script),
        code("%%writefile fit.json\n" + fit),
        code("import base64\nopen('" + MODEL + "', 'wb').write(base64.b64decode('" + model_b64 + "'))\nprint('model ok')"),
        code("import os\nOUT = '/kaggle/working/render' if os.path.isdir('/kaggle/working') else '/content/render'\n"
             "os.makedirs(OUT, exist_ok=True)\n"
             f"!./blender-5.2.3-linux-x64/blender -b --factory-startup -P video_anim.py -- --out $OUT --fit fit.json --model {MODEL} "
             f"--samples {SAMPLES} --frames {frames} --gpu --nomask 2>&1 | grep -E 'GPU devices|FRAME|ALL DONE|rror|skipped'"),
        code("import os, shutil\n"
             "base = '/kaggle/working' if os.path.isdir('/kaggle/working') else '/content'\n"
             f"zipped = shutil.make_archive(os.path.join(base, '{zipname}'), 'zip', base, 'render')\n"
             "print('wrote', zipped, os.path.getsize(zipped) // 1_000_000, 'MB')\n"
             "try:\n    from google.colab import files\n    files.download(zipped)\n"
             "except ImportError:\n    print('Kaggle: download it from the Output panel')"),
    ]
    nb = {"cells": cells, "metadata": {"accelerator": "GPU", "colab": {"provenance": [], "gpuType": "T4"},
          "kernelspec": {"name": "python3", "display_name": "Python 3"}}, "nbformat": 4, "nbformat_minor": 0}
    path = os.path.join(HERE, f"video_part_{name}.ipynb")
    json.dump(nb, open(path, "w", encoding="utf-8"))
    print("wrote", path, os.path.getsize(path) // 1_000_000, "MB")
