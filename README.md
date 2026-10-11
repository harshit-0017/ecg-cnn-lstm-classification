# ECG CNN-LSTM Atrial Fibrillation Detection

A lightweight 1D CNN + LSTM neural network that classifies single-lead ECG recordings as **Normal** or **Atrial Fibrillation (AF)**, trained on the PhysioNet/CinC 2017 Challenge dataset.

The project is developed with the goal of deploying the trained model using fixed-point arithmetic and a Verilog/FPGA hardware implementation.

## Overview

Atrial fibrillation is an irregular heart rhythm that can be detected from the timing and shape of ECG beats. This project combines:

- **1D Convolutional Neural Networks (CNN)** to extract local waveform features and shrink the signal from 9000 samples to 281 time steps.
- **Long Short-Term Memory (LSTM)** to learn the rhythm over those time steps.
- **Softmax classification** for two classes: Normal and AF.

The model is intentionally compact (about 44.5k parameters) to make it suitable for hardware-oriented optimization and FPGA implementation.

## Dataset

PhysioNet/CinC Challenge 2017 (`training2017`): https://physionet.org/content/challenge-2017/1.0.0/

Kaggle copy used for training: `<add your Kaggle dataset link>`

| Property | Value |
|---|---|
| Recordings | 8528 single-lead ECG recordings |
| Sampling rate | 300 Hz |
| Duration | 9 s to 60 s |
| Format | `.mat` (signal in key `val`) and `.hea`; labels in `REFERENCE.csv` |

Original labels:

| Label | Description | Records |
|---|---|---|
| N | Normal | 5050 |
| A | Atrial fibrillation | 738 |
| O | Other rhythm | 2456 |
| ~ | Too noisy | 284 |

The current experiment uses **Normal (N) vs AF (A) only**: 5788 records. Records labelled O and ~ are not used. The classes are imbalanced (about 6.8 : 1).

## Input Format

Each model input is one 30-second window:

- 9000 ECG samples (30 s at 300 Hz)
- 1 channel
- per-window z-score normalization

Therefore, each input sample has 9000 time steps. Shorter records are zero-padded.

## ECG Classes

| Class | Description |
|---|---|
| N | Normal |
| AF | Atrial fibrillation |

## Model Architecture

The proposed model uses a lightweight CNN-LSTM architecture:

```text
Input ECG (9000 x 1)
   │
   ▼
Conv1D - 16 filters (kernel 7, stride 2)
   │
   ▼
Batch Normalization
   │
   ▼
ReLU
   │
   ▼
MaxPooling1D (2)                         9000 -> 4500 -> 2250
   │
   ▼
Conv1D - 32 filters (kernel 5, stride 2)
   │
   ▼
Batch Normalization
   │
   ▼
ReLU
   │
   ▼
MaxPooling1D (2)                         2250 -> 1125 -> 562
   │
   ▼
Dropout (0.25)
   │
   ▼
Conv1D - 64 filters (kernel 3, stride 1)
   │
   ▼
Batch Normalization
   │
   ▼
ReLU
   │
   ▼
MaxPooling1D (2)                         562 -> 281
   │
   ▼
Dropout (0.25)
   │
   ▼
LSTM - 64 units (281 time steps)
   │
   ▼
Dropout (0.40)
   │
   ▼
Dense - 32 units (ReLU)
   │
   ▼
Dropout (0.30)
   │
   ▼
Dense - 2
   │
   ▼
Softmax
   │
   ▼
Normal / AF
```

A CNN + BiLSTM variant (`Bidirectional(LSTM(64))`) with identical settings is also provided for comparison.

## Data Preprocessing

```text
PhysioNet/CinC 2017 records (REFERENCE.csv labels)
       │
       ▼
Keep Normal (N) and AF (A) records
       │
       ▼
Train / Validation / Test split by record (80 / 10 / 10, stratified)
       │
       ▼
Cut 30 s windows (9000 samples, zero-pad short records)
       │
       ▼
Per-window z-score normalization
       │
       ▼
Reshape to (9000, 1)
       │
       ▼
CNN-LSTM model
```

Split sizes: train 4630, validation 579, test 579 records (test: 505 Normal, 74 AF).

- Training uses up to 4 non-overlapping windows per record.
- Validation and early stopping use the first window of each record.
- Final evaluation scores every window of a record and **averages the probabilities** per record.

## Training Strategy

Training setup: Adam (learning rate 1e-3), batch size 64, up to 60 epochs, EarlyStopping on validation loss (patience 10, best weights restored), ReduceLROnPlateau, seed 42.

Three experiments were evaluated:

### Experiment 1: Class-Weighted Training

Class weights were applied to compensate for the class imbalance (first window, threshold 0.5).

```text
Test Accuracy : 95.68%
Macro F1      : 0.9059
Weighted F1   : 0.9574
Test Loss     : 0.1392
AF Precision  : 0.8101
AF Recall     : 0.8649
AF F1         : 0.8366
```

### Experiment 2: Oversampling

The AF windows in the training set were oversampled with augmented copies (random shift, amplitude scaling, noise) until both classes had equal counts. Class weights were not used (first window, threshold 0.5).

```text
Test Accuracy : 96.03%
Macro F1      : 0.9048
Weighted F1   : 0.9589
Test Loss     : 0.1016
AF Precision  : 0.9048
AF Recall     : 0.7703
AF F1         : 0.8321
```

Oversampling reached about 99% training accuracy against about 96% validation accuracy and missed more AF records, so it is not used in the final model.

### Experiment 3: Final Model (class weights + all-window averaging + tuned threshold)

Class-weighted training, with probabilities averaged over all windows of each record and the AF threshold tuned on the validation records only (threshold = 0.82).

## Final Test Results

### Overall Performance

| Metric | Result |
|---|---|
| Test Accuracy | 96.20% |
| Macro F1 | 91.58% |
| Weighted F1 | 96.22% |
| AF Precision | 84.21% |
| AF Recall | 86.49% |
| AF F1 | 85.33% |

### Evaluation setting comparison (same trained model)

| Setting | Accuracy | Macro F1 | AF Precision | AF Recall | AF F1 |
|---|---|---|---|---|---|
| First window, threshold 0.50 | 0.9447 | 0.8875 | 0.7283 | 0.9054 | 0.8072 |
| All windows averaged, threshold 0.50 | 0.9551 | 0.9067 | 0.7727 | 0.9189 | 0.8395 |
| All windows averaged, threshold 0.82 (final) | 0.9620 | 0.9158 | 0.8421 | 0.8649 | 0.8533 |

### Classification Report (final)

| Class | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| Normal | 0.9801 | 0.9762 | 0.9782 | 505 |
| AF | 0.8421 | 0.8649 | 0.8533 | 74 |

### Confusion Matrix (final)

|  | Pred Normal | Pred AF |
|---|---|---|
| True Normal | 493 | 12 |
| True AF | 10 | 64 |

### Notes

- The test set has only 74 AF records, so differences of one to two points are within noise. Separate training runs of the same configuration also vary slightly.
- Only Normal vs AF is evaluated; Other (O) and Noisy (~) records are excluded.
- One train/validation/test split is used (no cross-validation).
- All results are floating-point Python results.

## FPGA / Verilog Preparation

`export_weights_hex_for_verilog.py` converts the trained model into hardware-ready files:

- BatchNorm is folded into the Conv1D weights and biases (no BatchNorm block needed in hardware).
- 16-bit signed fixed-point weights with a per-tensor Q format, written as `.hex` files (one value per line, loadable with `$readmemh`).
- LSTM weights split per gate (i, f, c, o).
- `manifest.json` and `ecg_params.vh` with shapes, depths and fractional bits.
- `test_vectors/` with a real input window and the expected output of every layer.

Hardware decision rule (softmax not needed): AF when `logit1 - logit0 >= ln(0.82 / 0.18)`, about 1.52.

### Computation per 30 s window

| Layer | MACs |
|---|---|
| Conv1 | 504,000 |
| Conv2 | 2,880,000 |
| Conv3 | 3,452,928 |
| LSTM (281 steps) | 9,207,808 |
| Dense layers | 2,112 |
| Total | about 16.05 million |

With one shared MAC at 100 MHz this takes about 16.05 M cycles (about 160 ms); with N parallel MACs, about 16.05 M / N cycles.

## Future Work

```text
CNN-LSTM Training                         [done]
       │
       ▼
Model Analysis / Threshold Tuning         [done]
       │
       ▼
Quantization (16-bit) + BN Folding        [done]
       │
       ▼
Fixed-Point Representation (hex export)   [done]
       │
       ▼
Verilog RTL                               [in progress]
       │
       ▼
Simulation vs Python test vectors         [in progress]
       │
       ▼
Synthesis                                 [planned]
       │
       ▼
FPGA Implementation                       [planned]
```

## How to Reproduce (Kaggle)

1. Create a Kaggle notebook with a GPU and attach the `training2017` dataset.
2. Paste `ecg_training2017_cnn_lstm_one_cell.py` into one cell and run it.
3. In the same session, run `export_weights_hex_for_verilog.py` in a new cell and download `ecg_weights_hex.zip` from `/kaggle/working`.

**Author**

Harshit Prajesh

B.Tech — Electronics and Communication Engineering
IIIT Bhopal

Interests:

RTL Design
ASIC Design
VLSI
FPGA
Functional Verification
Hardware Acceleration
Edge AI



