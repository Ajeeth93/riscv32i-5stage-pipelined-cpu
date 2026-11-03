# ASIC v2 log

## 1. IR-drop baseline
Run: RUN_2026-10-30_22-42-44 · corner nom_tt_025C_1v80 · static analysis (OpenROAD PSM)

| Net  | Worst drop | Average drop |
|------|-----------:|-------------:|
| VPWR | 0.72 mV    | 0.126 mV     |
| VGND | 0.68 mV    | 0.121 mV     |

- Combined worst case ≈ 1.4 mV = 0.08 % of 1.8 V. Budget 5 % = 90 mV, so margin ≈ 60×.
- Total power 7.6 mW (vectorless estimate), so supply current ≈ 4.2 mA.
- Limits: static only (no dynamic droop), typical corner only, estimated switching activity.

### Heat map (met1, VPWR) — docs/img/irdrop_met1_vpwr.png
- PDN: 3 vertical met4 straps, 3 horizontal met5 straps.
- Horizontal bands = one met1 rail per row; busier rows show more drop.
- Lowest drop directly under the met4 straps.
- Worst region: right edge. The last met4 strap is ~30 % of the core width from the edge,
  so that section is fed from one side only: drop ∝ L²/2, versus L²/8 for a span fed from both ends.
- Consequence for PPA: the PDN is over-designed, so a sparser grid can free routing tracks.
  Watch the right edge first if the grid is made sparser; rebalance the strap offset/pitch if needed.
