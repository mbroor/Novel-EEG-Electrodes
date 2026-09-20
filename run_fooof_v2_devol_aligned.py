"""FOOOF v2 (DeVol/Liu). Outcomes: alpha peak (dB), exponent, offset, walk noise floor.
Exclude negative aperiodic exponents only. n=18 (Pilot008 excluded)."""
from pathlib import Path
import numpy as np
import pandas as pd
import scipy.io as sio
from scipy import stats
from fooof import FOOOF

ROOT = Path.home() / "Desktop" / "new_code_version_manuscript"
SFN = Path.home() / "Desktop" / "Preprocessed Data (matlab)" / "Phase1_clean"
OUT = ROOT / "results" / "v2_devol_aligned"
EXCLUDE = {"Pilot008"}
FREQ, ALPHA = [3, 40], [8, 13]


def fit_channel(freqs, power):
    f = np.asarray(freqs, float).ravel()
    p = np.asarray(power, float).ravel()
    ok = np.isfinite(f) & np.isfinite(p) & (p > 0)
    f, p = f[ok], p[ok]
    if len(f) < 10:
        return None
    fm = FOOOF(aperiodic_mode="fixed", peak_width_limits=[1, 8],
               min_peak_height=0.05, max_n_peaks=3, verbose=False)
    try:
        fm.fit(f, p, freq_range=FREQ)
    except Exception:
        return None
    offset, exponent = map(float, fm.aperiodic_params_)
    r2 = float(fm.r_squared_)
    if exponent < 0:
        return {"excluded": True, "r2": r2, "offset": offset, "exponent": exponent}
    peaks = np.atleast_2d(fm.peak_params_) if fm.peak_params_.size else np.empty((0, 3))
    alpha = [pk for pk in peaks if ALPHA[0] <= pk[0] <= ALPHA[1]]
    snr = 10.0 * float(max(alpha, key=lambda pk: pk[1])[1]) if alpha else 0.0
    return {"excluded": False, "r2": r2, "offset": offset, "exponent": exponent,
            "snr_peak_db": snr}


def noise_floor_40_100(freqs, psd_all):
    f = np.asarray(freqs, float).ravel()
    p = np.nanmean(np.atleast_2d(psd_all), axis=0)
    ok = np.isfinite(f) & np.isfinite(p) & (p > 0) & ~((f >= 58) & (f <= 62))
    f, p = f[ok], p[ok]
    band = (f >= 40) & (f <= 100)
    return 10.0 * float(np.mean(np.log10(p[band]))) if band.sum() > 3 else np.nan


def paired_stats(cap, nov):
    d = pd.DataFrame({"cap": cap, "nov": nov}).dropna()
    if len(d) < 3:
        return None
    diff = d["nov"] - d["cap"]
    sw = stats.shapiro(diff)
    t = stats.ttest_rel(d["nov"], d["cap"])
    w = stats.wilcoxon(d["nov"], d["cap"])
    sd = diff.std(ddof=1)
    return {
        "n": len(d),
        "cap_mean": float(d["cap"].mean()), "cap_sd": float(d["cap"].std(ddof=1)),
        "novel_mean": float(d["nov"].mean()), "novel_sd": float(d["nov"].std(ddof=1)),
        "mean_diff_novel_minus_cap": float(diff.mean()),
        "novel_greater_n": int((diff > 0).sum()),
        "shapiro_p": float(sw.pvalue),
        "paired_t": float(t.statistic), "paired_t_p": float(t.pvalue), "df": len(d) - 1,
        "cohens_d": float(diff.mean() / sd) if sd > 0 else np.nan,
        "wilcoxon_W": float(w.statistic), "wilcoxon_p": float(w.pvalue),
        "test_used": "Wilcoxon" if sw.pvalue < 0.05 else "paired t",
    }


def report(label, pm, col):
    s = paired_stats(pm[pm.montage == "CAP"].set_index("pilot")[col],
                     pm[pm.montage == "NOVEL"].set_index("pilot")[col])
    if not s:
        return
    print(f"{label}: {s['cap_mean']:.3f}±{s['cap_sd']:.3f} vs {s['novel_mean']:.3f}±{s['novel_sd']:.3f} "
          f"| {s['novel_greater_n']}/{s['n']} | {s['test_used']} "
          f"t={s['paired_t']:.3f} p={s['paired_t_p']:.4f} | W={s['wilcoxon_W']:.0f} p={s['wilcoxon_p']:.4f}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    chan_rows, rec_rows = [], []
    n_fit = n_drop = 0

    for mf in sorted(SFN.rglob("*_alphaSNR.mat")):
        if mf.parent.name in EXCLUDE:
            continue
        mat = sio.loadmat(str(mf), struct_as_record=False, squeeze_me=True,
                          variable_names=["out"])["out"]
        freqs = np.asarray(mat.freqs_psd, float).ravel()
        psd = np.atleast_2d(np.asarray(mat.psd_all, float))
        montage = "CAP" if "_CAP_" in mf.name else "NOVEL"
        condition = "walk" if ("walk" in mf.name.lower() or "usual" in mf.name.lower()) else "rest"

        kept = []
        for ch in range(psd.shape[0]):
            if not np.any(np.isfinite(psd[ch])):
                continue
            res = fit_channel(freqs, psd[ch])
            if res is None:
                continue
            n_fit += 1
            if res["excluded"]:
                n_drop += 1
                continue
            kept.append(res)
            chan_rows.append({
                "pilot": mf.parent.name, "condition": condition, "montage": montage,
                "file": mf.name, "channel_index": ch + 1,
                "r2": res["r2"], "offset": res["offset"], "exponent": res["exponent"],
                "snr_peak_db": res["snr_peak_db"],
            })

        rec_rows.append({
            "pilot": mf.parent.name, "condition": condition, "montage": montage,
            "file": mf.name, "n_chan_used": len(kept),
            "snr_peak_db": np.mean([r["snr_peak_db"] for r in kept]) if kept else np.nan,
            "exponent_mean": np.mean([r["exponent"] for r in kept]) if kept else np.nan,
            "offset_mean": np.mean([r["offset"] for r in kept]) if kept else np.nan,
            "r2_mean": np.mean([r["r2"] for r in kept]) if kept else np.nan,
            "kwasa_noise_floor_40_100_db": noise_floor_40_100(freqs, psd),
        })

    chan = pd.DataFrame(chan_rows)
    rec = pd.DataFrame(rec_rows)
    chan.to_csv(OUT / "v2_per_channel.csv", index=False)
    rec.to_csv(OUT / "v2_recordings.csv", index=False)

    metrics = ["snr_peak_db", "exponent_mean", "offset_mean", "r2_mean",
               "kwasa_noise_floor_40_100_db"]
    pm = rec.groupby(["pilot", "condition", "montage"])[metrics].mean().reset_index()
    pm.to_csv(OUT / "v2_participant_means.csv", index=False)

    rest, walk = pm[pm.condition == "rest"], pm[pm.condition == "walk"]
    outcomes = [
        ("3.5 Rest alpha SNR (dB)", rest, "snr_peak_db"),
        ("3.5 Rest aperiodic exponent", rest, "exponent_mean"),
        ("3.5 Rest aperiodic offset", rest, "offset_mean"),
        ("Walk alpha SNR (dB)", walk, "snr_peak_db"),
        ("Walk 40-100 Hz noise floor (dB)", walk, "kwasa_noise_floor_40_100_db"),
    ]
    rows = []
    print(f"FOOOF: {n_fit} fits, {n_drop} excluded ({100 * n_drop / max(n_fit, 1):.1f}%), "
          f"R²={chan['r2'].mean():.3f}")
    for label, df, col in outcomes:
        s = paired_stats(df[df.montage == "CAP"].set_index("pilot")[col],
                         df[df.montage == "NOVEL"].set_index("pilot")[col])
        if s:
            rows.append({"section": label, **s})
            report(label, df, col)
    pd.DataFrame(rows).to_csv(ROOT / "results" / "manuscript_group_stats.csv", index=False)
    print(f"Saved {OUT}")


if __name__ == "__main__":
    main()
