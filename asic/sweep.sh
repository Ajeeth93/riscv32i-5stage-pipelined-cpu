#!/usr/bin/env bash
# Performance/area sweep: one config copy per experiment, run back to back.
# Usage: ./asic/sweep.sh        (from the project folder, venv active)
set -u
cd "$(dirname "$0")/.."

run() {   # run <tag> <clock ns> <core util %>
    tag=$1; clk=$2; util=$3; dens=$((util + 5))
    cfg=asic/config_$tag.json
    python3 - "$cfg" "$clk" "$util" "$dens" <<'PY'
import json, sys
cfg, clk, util, dens = sys.argv[1], float(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
c = json.load(open("asic/config.json"))
c["CLOCK_PERIOD"] = clk
c["FP_CORE_UTIL"] = util
c["PL_TARGET_DENSITY_PCT"] = dens
json.dump(c, open(cfg, "w"), indent=2)
PY
    echo "=== $tag: clock $clk ns, util $util %, density $dens %  ($(date +%H:%M))"
    python3 -m librelane --dockerized --run-tag "$tag" "$cfg" > "asic/sweep_$tag.log" 2>&1
    echo "    finished $(date +%H:%M), exit code $?"
}

run clk17   17 40
run u50     18 50
run u60     18 60
run u70     18 70
