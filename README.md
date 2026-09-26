# ECG CNN-LSTM Classification

A 5-class ECG heartbeat classification system using a lightweight **1D CNN + LSTM neural network** trained on the MIT-BIH Arrhythmia dataset.

The project is developed with a future goal of deploying the trained model using **fixed-point arithmetic and Verilog/FPGA hardware implementation**.

---

## Overview

Electrocardiogram (ECG) signals contain important information about the electrical activity of the heart. Automatic heartbeat classification can assist in identifying different types of cardiac rhythms.

This project implements a lightweight deep learning architecture combining:

- **1D Convolutional Neural Networks (CNN)** for extracting local morphological features from ECG signals.
- **Long Short-Term Memory (LSTM)** for learning sequential dependencies in the extracted features.
- **Softmax classification** for five ECG heartbeat classes.

The model is intentionally kept relatively compact to make it suitable for future hardware-oriented optimization and FPGA implementation.

---

## Dataset

The project uses the **MIT-BIH Arrhythmia dataset** provided through the Kaggle Heartbeat dataset.

Dataset source:

https://www.kaggle.com/datasets/shayanfazeli/heartbeat

The current experiment uses:

- `mitbih_train.csv`
- `mitbih_test.csv`

The PTBDB datasets are not used in the current 5-class classification experiment.

### Input Format

Each ECG heartbeat contains:

- **187 ECG signal samples**
- **1 class label**

Therefore, each input sample has 187 time steps.

---

## ECG Classes

The model performs five-class classification:

| Class | Description |
|---|---|
| N | Normal |
| S | Supraventricular |
| V | Ventricular |
| F | Fusion |
| Q | Unknown |

---

## Model Architecture

The proposed model uses a lightweight CNN-LSTM architecture:

```text
Input ECG
   │
   ▼
Conv1D - 32 filters
   │
   ▼
Batch Normalization
   │
   ▼
MaxPooling1D
   │
   ▼
Dropout
   │
   ▼
Conv1D - 64 filters
   │
   ▼
Batch Normalization
   │
   ▼
MaxPooling1D
   │
   ▼
Dropout
   │
   ▼
LSTM - 64 units
   │
   ▼
Dropout
   │
   ▼
Dense - 32 units
   │
   ▼
Dropout
   │
   ▼
Dense - 5
   │
   ▼
Softmax
   │
   ▼
N / S / V / F / Q

Data Preprocessing
MIT-BIH ECG data
       │
       ▼
Train / Validation split
       │
       ▼
StandardScaler
       │
       ▼
Reshape to (187, 1)
       │
       ▼
CNN-LSTM model

Training Strategy

Two experiments were evaluated:

Experiment 1 — Class-Weighted Training

Class weights were applied to compensate for the strong class imbalance.

Results:

Test Accuracy : 90.19%
Macro F1      : 0.7221
Weighted F1   : 0.9205
Test Loss     : 0.2734

The class-weighted model increased recall for minority classes but produced many false positives for the Normal class.

Experiment 2 — Without Class Weights

The same architecture and dataset split were used without applying class weights.

Final test results:

Test Accuracy : 97.40%
Macro F1      : 0.8787
Weighted F1   : 0.9729
Test Loss     : 0.0987

The second experiment is used as the current baseline model.

Final Test Results
Overall Performance
Metric	Result
Test Accuracy	97.40%
Macro F1	87.87%
Weighted F1	97.29%
Test Loss	0.098

Future Work
CNN-LSTM Training
       │
       ▼
Model Analysis
       │
       ▼
Quantization
       │
       ▼
Fixed-Point Representation
       │
       ▼
Weight / Activation Optimization
       │
       ▼
Verilog RTL
       │
       ▼
Simulation
       │
       ▼
Synthesis
       │
       ▼
FPGA Implementation

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



