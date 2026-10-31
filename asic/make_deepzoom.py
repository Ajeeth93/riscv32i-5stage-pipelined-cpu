# Render a GDS into Deep Zoom (DZI) tiles for an OpenSeadragon web viewer, using KLayout.
# usage: python3 asic/make_deepzoom.py <gds> <lyp> <out_dir> <name> [max_pixels]
import sys, os, math, time
import pya
from PIL import Image

gds, lyp, out_dir, name = sys.argv[1:5]
MAX = int(sys.argv[5]) if len(sys.argv) > 5 else 16384   # pixels across at full zoom
T = 256                                                   # tile size

view = pya.LayoutView()
view.load_layout(gds, True)
view.load_layer_props(lyp)
view.set_config("background-color", "#000000")
view.set_config("grid-visible", "false")
view.set_config("text-visible", "false")
view.max_hier()

bb = view.cellview(0).cell.dbbox()   # chip outline in um
W = MAX
H = int(round(MAX * bb.height() / bb.width()))
um_px_full = bb.width() / W
max_level = math.ceil(math.log2(max(W, H)))

tmp = os.path.join(out_dir, "_tile.png")
os.makedirs(out_dir, exist_ok=True)

def render(png, tw, th, box):
    try:
        view.save_image_with_options(png, tw, th, 0, 0, 0, box, False)
    except AttributeError:            # older KLayout: zoom, then save
        view.zoom_box(box)
        view.save_image(png, tw, th)

total = sum(math.ceil(math.ceil(W / 2**(max_level - L)) / T) *
            math.ceil(math.ceil(H / 2**(max_level - L)) / T) for L in range(max_level + 1))
print(f"{name}: {W}x{H} px, {um_px_full*1000:.1f} nm/px, levels 0..{max_level}, {total} tiles")

done, t0 = 0, time.time()
for L in range(max_level + 1):
    s = 2 ** (max_level - L)
    lw, lh = math.ceil(W / s), math.ceil(H / s)
    um_px = um_px_full * s
    d = os.path.join(out_dir, f"{name}_files", str(L))
    os.makedirs(d, exist_ok=True)
    for c in range(math.ceil(lw / T)):
        for r in range(math.ceil(lh / T)):
            px0, py0 = c * T, r * T
            tw, th = min(T, lw - px0), min(T, lh - py0)
            x0 = bb.left + px0 * um_px
            ytop = bb.top - py0 * um_px
            box = pya.DBox(x0, ytop - th * um_px, x0 + tw * um_px, ytop)
            render(tmp, tw, th, box)
            Image.open(tmp).convert("RGB").save(os.path.join(d, f"{c}_{r}.webp"), "WEBP", quality=80)
            done += 1
            if done % 250 == 0:
                el = time.time() - t0
                print(f"  {done}/{total} tiles, {el:.0f} s, ~{el/done*(total-done):.0f} s left")

with open(os.path.join(out_dir, f"{name}.dzi"), "w") as f:
    f.write(f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<Image xmlns="http://schemas.microsoft.com/deepzoom/2008" Format="webp" Overlap="0" TileSize="{T}">'
            f'<Size Width="{W}" Height="{H}"/></Image>\n')
os.remove(tmp)
print(f"done: {done} tiles in {time.time()-t0:.0f} s -> {out_dir}/{name}.dzi")
