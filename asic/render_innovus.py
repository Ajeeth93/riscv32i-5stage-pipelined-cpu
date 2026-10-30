# Innovus-style render of a sky130 GDS (headless KLayout) - v2
import sys
import pya

gds, out = sys.argv[1], sys.argv[2]
W = int(sys.argv[3]) if len(sys.argv) > 3 else 4000

view = pya.LayoutView()
view.load_layout(gds, True)
view.set_config("background-color", "#000000")
view.set_config("grid-visible", "false")
view.set_config("text-visible", "false")
view.clear_layers()

# KLayout: LAST in list = drawn ON TOP -> lowest metal first, top metal last
layers = [
    ("prBoundary", 235, 4, 0x909090),  # die outline
    ("met1",       68, 20, 0x1C2C8C),  # dim blue (cell wiring + rails)
    ("met2",       69, 20, 0xFF2020),  # red    - vertical routing
    ("met3",       70, 20, 0x20D020),  # green  - horizontal routing
    ("met4",       71, 20, 0xE8E000),  # yellow - vertical routing + power straps
    ("met5",       72, 20, 0xC040FF),  # purple - horizontal power straps
]
for name, l, d, col in layers:
    lp = pya.LayerPropertiesNode()
    lp.source = f"{l}/{d}@1"
    lp.name = name
    lp.fill_color = col
    lp.frame_color = col
    lp.dither_pattern = 1 if name == "prBoundary" else 0   # 0 = solid, 1 = outline only
    view.insert_layer(view.end_layers(), lp)

view.max_hier()
view.zoom_fit()
view.save_image(out, W, W)
print("wrote", out)
