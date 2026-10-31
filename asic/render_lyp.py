# Render a GDS to PNG with the colours of a KLayout .lyp file (headless)
# usage: python3 asic/render_lyp.py <gds> <lyp> <out.png> [pixels]
import sys
import pya

gds, lyp, out = sys.argv[1:4]
W = int(sys.argv[4]) if len(sys.argv) > 4 else 1400

view = pya.LayoutView()
view.load_layout(gds, True)
view.load_layer_props(lyp)
view.set_config("background-color", "#000000")
view.set_config("grid-visible", "false")
view.set_config("text-visible", "false")
view.max_hier()
view.zoom_fit()
view.save_image(out, W, W)
print("wrote", out)
