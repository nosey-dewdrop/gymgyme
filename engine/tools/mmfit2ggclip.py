#!/usr/bin/env python3
"""mmfit2ggclip — MM-Fit 3D pose (Human3.6M 17-joint) -> gymgyme .ggclip.

MM-Fit (mmfit.github.io, MIT license) stores 3D pose per workout as
wXX_pose_3d.npy with shape (3, n_frames, 18):
  axis 0..2 = coordinate rows [X, depth, vertical]
  column 0  = frame id
  columns 1..17 = 17 joints in Human3.6M / Martinez-et-al order:
    0 hip(root)  1 rhip 2 rknee 3 rankle  4 lhip 5 lknee 6 lankle
    7 spine 8 thorax 9 neck 10 head
    11 lshoulder 12 lelbow 13 lwrist  14 rshoulder 15 relbow 16 rwrist

Vertical axis (row 2) points UP (head > ankle); MediaPipe screen y points
DOWN, so we flip it. Row 0 -> screen x, row 1 -> depth (z), -row 2 -> screen y.

The engine only reads the joints listed in RETARGET below (shoulder / elbow /
wrist / hip / knee / ankle). Everything MediaPipe has that MM-Fit lacks (face,
fingers, feet detail) gets visibility 0 so the engine ignores it.

Output = one .ggclip:
  line 1        ggclip 1 <movename>
  each frame    t  33x(x y z vis) screen  33x(x y z vis) world

No external deps beyond numpy.
"""
import sys, csv, argparse
import numpy as np

# --- Human3.6M(17) joint index -> MediaPipe-33 index -----------------------
# only the joints the coach_engine MoveSpecs actually use are mapped.
# MediaPipe: 11/12 shoulder L/R, 13/14 elbow, 15/16 wrist,
#            23/24 hip, 25/26 knee, 27/28 ankle, 0 nose.
RETARGET = {
    # h36m_col(1-based joint) : mediapipe_idx
    10: 0,   # head       -> nose (approx; engine barely uses it)
    11: 11,  # lshoulder  -> L_SHO
    14: 12,  # rshoulder  -> R_SHO
    12: 13,  # lelbow     -> L_ELB
    15: 14,  # relbow     -> R_ELB
    13: 15,  # lwrist     -> L_WRI
    16: 16,  # rwrist     -> R_WRI
    4:  23,  # lhip       -> L_HIP
    1:  24,  # rhip       -> R_HIP
    5:  25,  # lknee      -> L_KNE
    2:  26,  # rknee      -> R_KNE
    6:  27,  # lankle     -> L_ANK
    3:  28,  # rankle     -> R_ANK
}

# MM-Fit exercise label -> gymgyme MoveSpec name (builtinMove in coach_engine)
MOVE_MAP = {
    "squats": "squat",
    "pushups": "pushup",
    "lunges": "lunge",
    "situps": "situp",
    "dumbbell_shoulder_press": "press",
    "lateral_shoulder_raises": "armraise",
    "jumping_jacks": "jumpingjack",
    # rows / bicep_curls / tricep_extensions: no direct MoveSpec -> skip
}

FPS = 30.0  # MM-Fit RGB stream is 30 fps; frame ids are 30 fps indices.


def load_pose(path):
    p = np.load(path)
    assert p.ndim == 3 and p.shape[0] == 3 and p.shape[2] == 18, \
        f"unexpected mmfit pose shape {p.shape}"
    return p


def frame_slice(pose, start_fid, end_fid):
    """rows of pose whose frame id is within [start_fid, end_fid]."""
    fids = pose[0, :, 0]
    i0 = int(np.searchsorted(fids, start_fid))
    i1 = int(np.searchsorted(fids, end_fid, side="right"))
    return pose[:, i0:i1, :], fids[i0:i1]


def normalize(seg):
    """seg: (3, T, 18). Build per-frame mediapipe-33 screen coords in [0,1].

    Uses whole-segment bbox of the used joints so aspect is preserved and the
    body sits inside the frame. Returns (T, 33, 4) screen + (T, 33, 4) world.
    """
    T = seg.shape[1]
    used_cols = list(RETARGET.keys())
    # raw coords per used joint: x=row0, z(depth)=row1, y=-row2 (flip up->down)
    X = seg[0, :, used_cols].T          # (T, k)
    Z = seg[1, :, used_cols].T
    Y = -seg[2, :, used_cols].T
    # bbox over the whole clip -> stable normalization (no per-frame jitter)
    xmin, xmax = X.min(), X.max()
    ymin, ymax = Y.min(), Y.max()
    span = max(xmax - xmin, ymax - ymin, 1e-6)
    # center inside a 0..1 box with a small margin
    margin = 0.1
    def nx(v): return margin + (v - xmin) / span * (1 - 2 * margin)
    def ny(v): return margin + (v - ymin) / span * (1 - 2 * margin)
    zscale = span

    screen = np.zeros((T, 33, 4), dtype=float)
    world = np.zeros((T, 33, 4), dtype=float)
    for k, col in enumerate(used_cols):
        mp = RETARGET[col]
        screen[:, mp, 0] = nx(X[:, k])
        screen[:, mp, 1] = ny(Y[:, k])
        screen[:, mp, 2] = Z[:, k] / zscale
        screen[:, mp, 3] = 1.0            # visible
        # world = metric-ish (mm -> metres), engine uses relative bone lengths
        world[:, mp, 0] = X[:, k] / 1000.0
        world[:, mp, 1] = Y[:, k] / 1000.0
        world[:, mp, 2] = Z[:, k] / 1000.0
        world[:, mp, 3] = 1.0
    # unmapped landmarks keep vis=0 -> engine skips them
    return screen, world


def write_ggclip(path, movename, screen, world, fids):
    T = screen.shape[0]
    with open(path, "w") as f:
        f.write(f"ggclip 1 {movename}\n")
        for i in range(T):
            t = int(round((fids[i] - fids[0]) / FPS * 1000.0))  # ms from start
            row = [str(t)]
            for j in range(33):
                x, y, z, v = screen[i, j]
                row.append(f"{x:.5f} {y:.5f} {z:.5f} {v:.3f}")
            for j in range(33):
                x, y, z, v = world[i, j]
                row.append(f"{x:.5f} {y:.5f} {z:.5f} {v:.3f}")
            f.write(" ".join(row) + "\n")
    return T


def segments_for(label_csv, exercise):
    out = []
    with open(label_csv) as f:
        for r in csv.reader(f):
            if len(r) < 4:
                continue
            s, e, reps, name = int(r[0]), int(r[1]), int(r[2]), r[3]
            if name == exercise:
                out.append((s, e, reps))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pose_npy")
    ap.add_argument("labels_csv")
    ap.add_argument("--exercise", required=True,
                    help="mmfit label, e.g. squats / pushups / lunges")
    ap.add_argument("--set", type=int, default=0,
                    help="which labelled set of that exercise (0-based)")
    ap.add_argument("-o", "--out", required=True)
    a = ap.parse_args()

    if a.exercise not in MOVE_MAP:
        sys.exit(f"no MoveSpec mapping for '{a.exercise}' "
                 f"(known: {', '.join(MOVE_MAP)})")
    move = MOVE_MAP[a.exercise]

    pose = load_pose(a.pose_npy)
    segs = segments_for(a.labels_csv, a.exercise)
    if not segs:
        sys.exit(f"no '{a.exercise}' segments in {a.labels_csv}")
    if a.set >= len(segs):
        sys.exit(f"only {len(segs)} '{a.exercise}' sets; asked #{a.set}")
    s, e, reps = segs[a.set]
    seg, fids = frame_slice(pose, s, e)
    if seg.shape[1] < 30:
        sys.exit(f"segment too short ({seg.shape[1]} frames)")
    screen, world = normalize(seg)
    n = write_ggclip(a.out, move, screen, world, fids)
    print(f"wrote {a.out}: move={move} exercise={a.exercise} set#{a.set} "
          f"frames={n} label_reps={reps} (mmfit frames {s}-{e})")


if __name__ == "__main__":
    main()
