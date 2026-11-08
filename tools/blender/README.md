# Pull-to-refresh hand

How `assets/lottie/refresh.json` and `refresh_dark.json` are made. They show a
3D cartoon hand that searches for the page, grips it like fabric and yanks it
up. The widget that plays them is `lib/core/widgets/lottie_refresh.dart`.

You only need this folder to **change how the hand or fabric looks**. The app
builds and runs without any of it.

## What's here

| Path | What it is |
| --- | --- |
| `video/reference_full.mp4` | The original reference clip: two full loops. The second loop shows the search before the grab. |
| `video/reference.mp4` | The cropped reference that everything is measured from (572×380, 30 fps). |
| `video/cutout/` | The hand and fabric cut out of the reference, one PNG per frame. Made by `extract_frames.py`. |
| `video/folds/` | The same frames de-flickered at 2× size. The fabric folds are taken from these. Made by `polish_frames.py`. |
| `models/zootopia_style_hand_base.glb` | The hand model (credit below). |
| `fit/fit.json` | The hand's pose for each video frame: curl, rotation, scale and offset. Made by `fit_video.py`. |
| `fit/rest_*.png` | The hand's silhouettes at five curl amounts. `fit_video.py` matches them against the video. |
| `render/` | The Blender renders (`main_###.png`) and the empty sheet (`ref.png`). These took a Colab T4 run to make, so they're kept. |
| `composed/` | Generated output, gitignored. The finished light and dark frames, before packing. |

## The pipeline

The steps run in this order. Each one only needs re-running if something
before it changed.

```
reference.mp4 ─ extract_frames.py ─> video/cutout ─ polish_frames.py ─> video/folds ─┐
                     video/cutout + fit/rest_*.png ─ fit_video.py ─> fit/fit.json      │
  model.glb + fit.json ─ video_anim.py (Blender) ─> render/ ──────────────────────────┤
                                               compose_frames.py ─> composed/{light,dark}
                                                     pack_lottie.py ─> assets/lottie/refresh*.json
```

### Tweaking the look (most changes)

Fold strength, shadow and dark-mode creases all live at the top of
`compose_frames.py`. Change them, then run:

```bash
python tools/blender/compose_frames.py
```

```bash
python tools/blender/pack_lottie.py
```

`compose_frames.py` takes about 15 minutes. `pack_lottie.py` writes straight
into `assets/lottie/`. Then hot-restart the app.

### Re-rendering the hand

Re-render when the hand's shape, curl, lighting or motion changes
(`video_anim.py`, `fit.json`). This is the slow step.

- **Colab (free T4 GPU, about 25 min):** run the command below. Upload
  `tools/blender/video_part_ALL.ipynb` to Colab, set Runtime → T4 GPU, then
  Run all. Unzip the download over `render/`.

  ```bash
  python tools/blender/make_notebooks_video.py --one
  ```

- **This PC (CPU, hours):** this renders the missing frames, composes them and
  packs the result.

  ```bash
  python tools/blender/render_video_local.py
  ```

  It expects Blender 5.2 at `C:\Program Files\Blender Foundation\Blender 5.2`.

## Setup

- Python 3 with `numpy` and `pillow`:

  ```bash
  pip install -r tools/blender/requirements.txt
  ```

- `ffmpeg` on PATH, for `extract_frames.py` only.
- Blender 5.2.3, for re-rendering only.

## Frame map

There are 149 frames at 30 fps. The widget refers to these frames by name.

| Frames | Marker | In the app |
| --- | --- | --- |
| 0–9 | settle | open hand over the sheet |
| 9–17 | curl | fingers close |
| 17–22 | press | presses in and grips (`_gripped` = 22) |
| 22–34 | pull | creases stretch, then the yank (`_taut` = 27) |
| 34–46 | release | hand flies up and out (`_away` = 46) |
| 46–98 | hidden | empty: the page waits, then drops back (timing is in the widget) |
| 98–113 | return | hand comes down from the top |
| 113–148 | sway | searches left and right, then wraps to frame 0 |

When you pull, the widget plays 100 → 148 → 0 → 9 (the search), then 9 → 22
(the grip), then on release 22 → 46 (the yank).

## Credit

The hand model is "Zootopia style hand base" by Lizzy Koopa, licensed
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Shipping it needs a
credit line in the app, for example on an About or Licenses screen.
