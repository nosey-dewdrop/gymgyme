#!/usr/bin/env python3
"""classify-moves.py — programmatic inventory of data/moves-db.js.

Splits the 386-move library into three honest coaching classes:
  - rep   : angle-oscillation move the engine can COUNT (squat/pushup/lunge/...)
  - hold  : isometric hold the engine can TIME + form-gate (plank/wall-sit/...)
  - reference : stretch / mobility / balance / unusual — NO honest coaching signal,
                shown as "reference" so the product never fakes a rep count.

Rule of the loop: when a move is ambiguous, it is REFERENCE. We would rather
under-claim than coach a move whose joint chain / phase we cannot read.

Usage:  python3 engine/tools/classify-moves.py            (summary table)
        python3 engine/tools/classify-moves.py --list rep (dump one class)
Output is deterministic (sorted) so the benchmark log can pin exact numbers.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB_PATH = os.path.join(ROOT, "data", "moves-db.js")


def load_db():
    txt = open(DB_PATH, encoding="utf-8").read()
    m = re.search(r"const\s+MOVE_DB\s*=\s*(\{.*\});?\s*$", txt, re.S)
    if not m:
        m = re.search(r"MOVE_DB\s*=\s*(\{.*\})", txt, re.S)
    return json.loads(m.group(1))


# ── HOLD signals: isometric, no oscillation. Order matters (checked first). ──
HOLD_KEYS = [
    "plank", "wall sit", "wall-sit", "wallsit", "hollow hold", "hollow body",
    "hold", "l-sit", "l sit", "isometric", "dead hang", "static", "wall press",
    "chair sit", "horse stance", "boat pose", "bridge hold",
]

# ── STRETCH / REFERENCE signals: mobility, yoga, balance, breathing. No count. ──
REF_KEYS = [
    "stretch", "pose", "flow", "circles", "circle", "rotation", "rotations",
    "opener", "reach", "mobility", "cat-cow", "cat cow", "cat stretch",
    "child's pose", "cobra", "sphinx", "puppy", "seal", "pigeon", "thread",
    "windmill", "roll", "rolls", "twist", "twists", "wave", "swing", "swings",
    "march", "marching", "step", "walkout", "walk-out", "inchworm", "worm",
    "balance", "stand on", "figure four", "figure-4", "warm up", "warmup",
    "warm-up", "cool down", "cooldown", "breathing", "breath", "shrug",
    "tilt", "tilts", "nod", "neck", "wrist", "ankle circ", "hip circ",
    "shoulder circ", "arm circ", "scapular", "cscape", "dead bug", "deadbug",
    "clam", "clamshell", "fire hydrant", "donkey kick", "pulse", "pulses",
    "hold and release", "prayer", "cross-body", "crossbody", "downward dog",
    "upward dog", "cobra to", "sun salutation", "flossing", "floss",
]

# ── REP signals: countable angle oscillation. Keyed by move family. ──
# family -> (list of substrings, engine base spec used for parameters).
REP_FAMILIES = {
    "squat":   (["squat", "sit-to-stand", "sit to stand", "chair stand", "wall squat pulse"], "squat"),
    "lunge":   (["lunge", "split squat", "step-up", "step up", "curtsy"], "lunge"),
    "pushup":  (["push-up", "pushup", "push up", "press-up", "chest press",
                 "floor press", "diamond", "pike push", "wide push", "incline push",
                 "decline push", "archer push", "spider", "hindu push"], "pushup"),
    "raise":   (["raise", "curl", "extension", "kickback (arm)", "fly", "flye",
                 "pull-apart", "pull apart", "pulldown", "row", "press-out",
                 "front raise", "lateral raise", "reverse fly", "overhead press",
                 "shoulder press", "arnold", "pull-up", "pullup", "chin-up",
                 "chinup", "chin up", "pull up"], "armraise"),
    "situp":   (["sit-up", "situp", "sit up", "crunch", "v-up", "v up", "vup",
                 "toe touch", "leg raise", "leg lift", "flutter", "scissor",
                 "reverse crunch", "bicycle", "jackknife", "jack knife"], "situp"),
    "bridge":  (["glute bridge", "hip thrust", "bridge (rep)", "single leg bridge",
                 "marching bridge", "frog pump"], "glutebridge"),
    "jack":    (["jumping jack", "jack", "star jump", "seal jack"], "jumpingjack"),
    "calf":    (["calf raise", "calf-raise", "heel raise", "toe raise"], "calfraise"),
    "kickback":(["glute kickback", "donkey (rep)", "quadruped hip ext"], "kickback"),
    "press":   (["overhead", "shoulder press", "military press", "push press",
                 "z press", "pike press"], "press"),
}


def classify(name):
    n = name.lower()

    # 1) HOLD wins over everything (an "isometric hold" is a hold even if it says squat).
    for k in HOLD_KEYS:
        if k in n:
            return ("hold", None)

    # 2) explicit reference/mobility/stretch signals -> reference (honest under-claim).
    for k in REF_KEYS:
        if k in n:
            return ("reference", None)

    # 3) rep families.
    for fam, (subs, spec) in REP_FAMILIES.items():
        for s in subs:
            if s in n:
                return ("rep", fam)

    # 4) unknown -> reference (never fake a count).
    return ("reference", None)


def main():
    db = load_db()
    buckets = {"rep": [], "hold": [], "reference": []}
    fam_counts = {}
    for cat, moves in db.items():
        for m in moves:
            cls, fam = classify(m)
            buckets[cls].append((cat, m, fam))
            if fam:
                fam_counts[fam] = fam_counts.get(fam, 0) + 1

    total = sum(len(v) for v in buckets.values())

    if len(sys.argv) > 2 and sys.argv[1] == "--list":
        cls = sys.argv[2]
        for cat, m, fam in sorted(buckets.get(cls, [])):
            print(f"{cat:10} {m}" + (f"  [{fam}]" if fam else ""))
        return

    print(f"MOVE_DB total: {total}")
    print(f"  rep       : {len(buckets['rep']):4}  (engine counts reps)")
    print(f"  hold      : {len(buckets['hold']):4}  (engine times + form-gates)")
    print(f"  reference : {len(buckets['reference']):4}  (honest label, not coached)")
    print()
    print("REP families:")
    for fam in sorted(fam_counts, key=lambda k: -fam_counts[k]):
        print(f"  {fam:10} {fam_counts[fam]:4}")


if __name__ == "__main__":
    main()
