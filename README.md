# Novel EEG Electrodes — Analysis Code

Code accompanying the manuscript on "Design and Test Novel EEG Electrode Attachments for Type 4 Afro-textured Hairstyles" 

**Pipeline:** BrainVision EEG → MATLAB preprocess (EEGLAB) → PSD `.mat` files → Python FOOOF (aperiodic-corrected alpha, exponent, offset, walk noise floor).

This repository contains analysis scripts only. Raw EEG and large preprocessed `.mat` files are not included.

## Requirements

### MATLAB preprocess
- MATLAB (tested with R2025b)
- [EEGLAB](https://eeglab.org/) with plugins: **CleanLine**, **clean_rawdata** / ASR tools as used by `pop_clean_rawdata`
- BrainVision loader (`pop_loadbv`)

### Python FOOOF
- Python 3
- `numpy`, `pandas`, `scipy`, `fooof`

```bash
pip install numpy pandas scipy fooof
```

## Repository contents

| File | Role |
|------|------|
| `batch_preprocess_rest_phase1.m` | Batch rest recordings → PSD mats |
| `batch_preprocess_walk_phase1.m` | Batch walk recordings → PSD mats |
| `preprocess_one_recording.m` | Core preprocess for one `.vhdr` file |
| `setup_eeglab_paths.m` | Add EEGLAB to the MATLAB path |
| `channel_range_for_montage.m` | Cap = ch 1–16, Novel = 17–32 (Pilot005 swapped) |
| `autoRejCh_func_CL.m` | Reject channels with SD > 3× median SD |
| `compute_spectopo_psd.m` | Welch PSD via EEGLAB `spectopo` (linear power) |
| `rest_recordings.csv` | Rest file list (pilot, folder, montage, vhdr)
| `walk_recordings.csv`| Walk file list
| `run_fooof_v2_devol_aligned.py` | FOOOF v2 fits + Cap vs Novel group stats |

## Before you run — edit local paths

Scripts currently point to local folders. Change these to your machine:

**MATLAB** (`batch_preprocess_rest_phase1.m` and `batch_preprocess_walk_phase1.m`):
- `rawRoot` — folder with raw BrainVision data
- `outRoot` — folder for `*_alphaSNR.mat` outputs

**MATLAB** (`setup_eeglab_paths.m`):
- `eeglabPath` — your EEGLAB install directory

**Python** (`run_fooof_v2_devol_aligned.py`):
- `SFN` — folder of preprocessed `*_alphaSNR.mat` files
- `ROOT` / `OUT` — where CSV results should be written

## How to run

### 1. Preprocess (MATLAB)

```matlab
cd('.../EEG Novel Electrodes Code')   % this folder
batch_preprocess_rest_phase1
batch_preprocess_walk_phase1
```

**Pipeline per recording (same for rest and walk):**
1. Load Cap or Novel channels (`pop_loadbv`); recording reference **CPz** (no average re-reference)
2. High-pass 1 Hz
3. CleanLine @ 60 Hz
4. Bad-channel reject (SD > 3× median)
5. `pop_clean_rawdata` (flatline / channel criteria; burst & window criteria off)
6. Non-overlapping 4 s epochs
7. Spectopo PSD (2 s Hamming, 50% overlap) → save `*_alphaSNR.mat`

### 2. FOOOF + stats (Python)

```bash
python run_fooof_v2_devol_aligned.py
```

- Fit range 3–40 Hz; max 3 peaks; alpha peak height in 8–13 Hz (×10 dB)
- Exclude fits with **negative aperiodic exponent**
- Exclude **Pilot008** (n = 18 in manuscript stats)
- Writes per-channel / recording / participant CSVs and `manuscript_group_stats.csv`

## Notes

- Rest vs walk differ only by which CSV file list is used; preprocess code is shared.
- Do not commit raw EEG or large `.mat` outputs to this repo.
- macOS `.DS_Store` files should not be kept in the repository.

## Citation

If you use this code, please cite the manuscript (and EEGLAB: Delorme & Makeig, 2004; FOOOF as appropriate).
