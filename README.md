# ECG CNN-LSTM: Atrial Fibrillation Detection with Verilog/FPGA

A lightweight 1D CNN-LSTM model for classifying single-lead ECG recordings as **Normal** or **Atrial Fibrillation (AF)**. This project combines deep-learning-based ECG classification with fixed-point arithmetic and a Verilog hardware implementation targeting FPGA deployment.

The project covers model training, evaluation, weight export, RTL development, simulation, and preparation for hardware synthesis.

## Project Overview

Atrial fibrillation is a cardiac arrhythmia associated with irregular heart rhythm. This project explores a compact CNN-LSTM architecture that learns local ECG waveform features using convolutional layers and temporal information using an LSTM.

The project has two main components:

- **Software model:** CNN-LSTM training and record-level evaluation using Python.
- **Hardware implementation:** Verilog modules for fixed-point computation, weight storage, convolution MAC operations, and activation/pooling logic.

### Key Features

- Binary ECG classification: Normal vs. AF
- Raw ECG input of 9,000 samples
- Lightweight CNN-LSTM architecture with 44,098 trainable parameters
- Record-level evaluation with multi-window probability averaging
- Signed 16-bit Q8.8 fixed-point weight export
- Verilog weight ROM using `$readmemh`
- Convolution MAC and ReLU/max-pooling RTL modules
- Testbenches for module-level functional verification
- FPGA synthesis and full-network hardware validation planned

## Dataset

**Dataset:** PhysioNet/CinC Challenge 2017

Official dataset: https://physionet.org/content/challenge-2017/1.0.0/

Kaggle training notebook: https://www.kaggle.com/code/harshitprajesh/lstm-af

The original dataset contains single-lead ECG recordings with four labels.

| Label | Description | Records |
|---|---|---:|
| N | Normal rhythm | 5,050 |
| A | Atrial fibrillation | 738 |
| O | Other rhythm | 2,456 |
| ~ | Noisy recording | 284 |
| **Total** | | **8,528** |

This experiment uses only Normal and AF recordings, resulting in 5,788 records. Records labelled Other and Noisy are excluded.

The resulting dataset is imbalanced, with approximately 6.84 Normal recordings for every AF recording.

## Input Processing

Each model input is represented as a single-channel ECG window.

| Property | Value |
|---|---|
| Sampling rate | 300 Hz |
| Input duration | 30 seconds |
| Input samples | 9,000 |
| Input shape | `(9000, 1)` |
| Normalization | Per-window z-score |
| Short recordings | Zero-padded |
| Long recordings | Windowed for evaluation |

The train, validation, and test sets are split by record using stratified sampling.

| Split | Records |
|---|---:|
| Training | 4,630 |
| Validation | 579 |
| Test | 579 |
| **Total** | **5,788** |

Training uses up to four non-overlapping windows per record. Validation and early stopping use the first window of each record. For final record-level evaluation, probabilities from all evaluated windows belonging to a record are averaged.

The test set contains 505 Normal records and 74 AF records.

## Model Architecture

The model uses three 1D convolutional layers followed by a unidirectional LSTM and fully connected classification layers.

```text
Input ECG (9000 × 1)
        |
        v
Conv1D: 16 filters, kernel 7, stride 2
        |
       ReLU
        |
MaxPooling1D (2)
        |
        v
Conv1D: 32 filters, kernel 5, stride 2
        |
       ReLU
        |
MaxPooling1D (2)
        |
     Dropout
        |
        v
Conv1D: 64 filters, kernel 3, stride 1
        |
       ReLU
        |
MaxPooling1D (2)
        |
     Dropout
        |
        v
LSTM: 64 units
        |
     Dropout
        |
        v
Dense: 32 units, ReLU
        |
     Dropout
        |
        v
Dense: 2 logits
        |
        v
Normal / AF
```

### Layer Summary

| Layer | Output Shape | Parameters |
|---|---|---:|
| Input | `(9000, 1)` | 0 |
| Conv1D: 16 filters | `(4500, 16)` | 128 |
| ReLU | `(4500, 16)` | 0 |
| MaxPooling1D | `(2250, 16)` | 0 |
| Conv1D: 32 filters | `(1125, 32)` | 2,592 |
| ReLU | `(1125, 32)` | 0 |
| MaxPooling1D | `(562, 32)` | 0 |
| Dropout | `(562, 32)` | 0 |
| Conv1D: 64 filters | `(562, 64)` | 6,208 |
| ReLU | `(562, 64)` | 0 |
| MaxPooling1D | `(281, 64)` | 0 |
| Dropout | `(281, 64)` | 0 |
| LSTM: 64 units | `(64)` | 33,024 |
| Dropout | `(64)` | 0 |
| Dense: 32 units | `(32)` | 2,080 |
| Dropout | `(32)` | 0 |
| Output Dense: 2 units | `(2)` | 66 |
| **Total** | | **44,098** |

The model has **44,098 trainable parameters**. The architecture is compact enough to explore hardware-oriented optimization, although intermediate feature buffers and arithmetic logic also contribute to FPGA resource usage.

### Batch Normalization

**The current model does not contain BatchNormalization layers.**

The architecture consists of convolution, ReLU, max-pooling, dropout, LSTM, dense, and output layers. Consequently, the current hardware implementation does not require dedicated BatchNormalization modules or BatchNorm parameter folding.

Dropout is used during training and is disabled during inference.

## Training Configuration

| Hyperparameter | Value |
|---|---|
| Optimizer | Adam |
| Initial learning rate | 0.001 |
| Batch size | 64 |
| Maximum epochs | 60 |
| Early stopping patience | 10 |
| Best weights restored | Yes |
| Learning-rate scheduling | ReduceLROnPlateau |
| Random seed | 42 |

Class-weighted training is used to address the class imbalance. The final reported evaluation averages window probabilities at the record level and uses an AF decision threshold of 0.76, as reported by the latest experiment.

## Model Evaluation

The following results correspond to the latest supplied test report. They are **floating-point Python results**, not measurements from the Verilog implementation.

### Final Test Metrics

| Metric | Result |
|---|---:|
| Test Accuracy | **95.34%** |
| Macro F1-score | 89.60% |
| Weighted F1-score | 95.35% |
| AF Precision | 81.33% |
| AF Recall | 82.43% |
| AF F1-score | 81.88% |

### Evaluation Settings

| Evaluation Setting | Accuracy | Macro F1 | AF Precision | AF Recall | AF F1 |
|---|---:|---:|---:|---:|---:|
| First window, threshold 0.50 | 94.99% | 89.32% | 77.11% | 86.49% | 81.53% |
| All windows averaged, threshold 0.50 | 95.34% | 90.05% | 78.31% | 87.84% | 82.80% |
| All windows averaged, threshold 0.76 | 95.34% | 89.60% | 81.33% | 82.43% | 81.88% |

### Classification Report

| Class | Precision | Recall | F1-score | Support |
|---|---:|---:|---:|---:|
| Normal (N) | 97.42% | 97.23% | 97.32% | 505 |
| AF (A) | 81.33% | 82.43% | 81.88% | 74 |
| Macro average | 89.38% | 89.83% | 89.60% | 579 |
| Weighted average | 95.36% | 95.34% | 95.35% | 579 |

### Confusion Matrix

Rows represent actual labels and columns represent predicted labels.

| Actual / Predicted | Normal | AF |
|---|---:|---:|
| Normal | 491 | 14 |
| AF | 13 | 61 |

The test set contains only 74 AF records, so a small number of changed predictions can noticeably affect AF-specific metrics. Results are based on one data split; cross-validation has not been performed.

## Fixed-Point Hardware Preparation

The trained model's parameters are exported into hexadecimal files for use in Verilog RTL.

### Fixed-Point Representation

| Property | Configuration |
|---|---|
| Parameter type | Signed fixed-point |
| Parameter width | 16 bits |
| Fractional bits | 8 |
| Representation | Q8.8 |
| Weight file format | Hexadecimal, one value per line |
| ROM initialization | `$readmemh` |

For Q8.8, the stored integer represents a real value scaled by \(2^8 = 256\).

\[
x_{\text{real}}=\frac{x_{\text{stored}}}{256}
\]

For example, the signed 16-bit value `16'h0100` represents 1.0, while `16'hFF00` represents -1.0.

When two Q8.8 values are multiplied, their product has 16 fractional bits. The product or accumulated result must be appropriately scaled back to Q8.8, with sufficient accumulator width to avoid overflow.

The hexadecimal weight files contain quantized parameters. The effect of quantization on the model's final classification accuracy must be evaluated separately.

### Exported Parameter Files

The current exported model contains 13 parameter files:

| Layer | Parameter | Shape | Values |
|---|---|---|---:|
| Conv1 | Kernel | `(7, 1, 16)` | 112 |
| Conv1 | Bias | `(16)` | 16 |
| Conv2 | Kernel | `(5, 16, 32)` | 2,560 |
| Conv2 | Bias | `(32)` | 32 |
| Conv3 | Kernel | `(3, 32, 64)` | 6,144 |
| Conv3 | Bias | `(64)` | 64 |
| LSTM | Input kernel | `(64, 256)` | 16,384 |
| LSTM | Recurrent kernel | `(64, 256)` | 16,384 |
| LSTM | Bias | `(256)` | 256 |
| Dense1 | Kernel | `(64, 32)` | 2,048 |
| Dense1 | Bias | `(32)` | 32 |
| Output | Kernel | `(32, 2)` | 64 |
| Output | Bias | `(2)` | 2 |

All exported parameters use signed 16-bit Q8.8 representation.

The LSTM parameter dimensions correspond to four gates: input, forget, candidate, and output. Gate ordering, tensor flattening, and weight orientation must match the trained framework when loading parameters into RTL.

The current parameter metadata is stored in `weights_meta.json`.

**Parameter storage estimate:** 44,098 parameters × 2 bytes = 88,196 bytes, approximately 86.1 KiB for the exported parameter values. This estimate excludes ROM implementation overhead, activation buffers, intermediate results, and control logic.

## Verilog Hardware Architecture

The hardware work translates the trained CNN-LSTM model into fixed-point RTL modules. The intended data path processes an ECG window through the convolutional feature extractor, LSTM, dense layer, and final binary decision.

### Intended Hardware Data Path

```text
ECG Input Window
   (9000 samples)
         |
         v
Input Buffer / Sequencer
         |
         v
Conv1D MAC Engine
  7-tap convolution
         |
         v
ReLU + MaxPool
         |
         v
Conv1D MAC Engine
  5-tap convolution
         |
         v
ReLU + MaxPool
         |
         v
Conv1D MAC Engine
  3-tap convolution
         |
         v
ReLU + MaxPool
         |
         v
LSTM Engine
  281 time steps
         |
         v
Dense Layer
  64 -> 32
         |
         v
Output Layer
  32 -> 2 logits
         |
         v
Normal / AF Decision
```

This diagram describes the intended complete inference path. The current repository contains module-level RTL building blocks; the complete end-to-end data path is still in progress.

### Weight ROM

The `weight_rom.v` module provides stored model parameters to the computation modules.

The ROM is initialized using hexadecimal files and `$readmemh`. The current implementation uses selectors to identify parameter groups.

| Selector | Parameter Group |
|---:|---|
| 0 | Conv1 weights |
| 1 | Conv1 bias |
| 6 | Conv2 weights |
| 7 | Conv2 bias |
| 12 | Conv3 weights |
| 13 | Conv3 bias |
| 18 | LSTM input kernel |
| 19 | LSTM recurrent kernel |
| 20 | LSTM bias |
| 21 | Dense1 weights |
| 22 | Dense1 bias |
| 23 | Output weights |
| 24 | Output bias |

Invalid selector or address requests return zero in the tested ROM implementation.

The ROM testbench has checked representative values from multiple parameter groups, including Conv1, Conv2, Conv3, LSTM, Dense1, and the output layer. This verifies basic parameter loading, but does not by itself verify complete network inference.

### Conv1D MAC Unit

The `conv1d_mac.v` module implements a single convolution output using:

- Seven input samples
- Signed 16-bit Q8.8 input values
- Selected Conv1 weights and bias
- Multiply-accumulate operations
- A control FSM with idle, MAC, bias, and finish states
- A `done` signal indicating completion

The module is a building block for convolution computation. It does not yet represent a fully parallel implementation of all convolution channels and time steps.

Its testbench uses known input values and checks the generated output. Full fixed-point arithmetic correctness must be established by comparing the output against an independently calculated reference, including product scaling, accumulation width, bias alignment, and signed overflow behaviour.

### ReLU and Max-Pooling

The `relu_maxpool1d.v` module implements the basic operations required after convolution:

- **ReLU:** negative inputs are clipped to zero.
- **Max-pooling:** the larger of two input values is selected.

The module-level simulation has exercised positive, negative, and zero-valued inputs and compared the resulting ReLU and max-pooling outputs against their expected values.

### LSTM and Dense Computation

The exported LSTM parameters are available for integration into an RTL LSTM engine. The LSTM computation requires input and recurrent matrix operations, gate bias addition, sigmoid and tanh activation functions, and cell/hidden-state updates.

The dense layers require additional fixed-point MAC operations and bias handling.

The complete LSTM, dense-layer, output-layer, and control integration must be verified against Python reference vectors before claiming end-to-end hardware equivalence.

## Computational Cost Estimate

The following estimates use the model dimensions and standard dense convolution/LSTM operations. They count multiply-accumulate operations, not every additional comparison, activation, memory access, or control cycle.

| Layer | Approximate MACs per 9,000-sample input |
|---|---:|
| Conv1 | 504,000 |
| Conv2 | 2,880,000 |
| Conv3 | 3,452,928 |
| LSTM | 9,207,808 |
| Dense layers | 2,112 |
| **Total** | **Approximately 16.05 million** |

A single shared MAC unit would require approximately 16.05 million MAC cycles in an idealized one-MAC-per-cycle design. At 100 MHz, that corresponds to roughly 160.5 ms, before accounting for additional control, memory, activation, and pipeline overhead.

Parallel MAC units can reduce computation latency at the cost of additional hardware resources and memory bandwidth. Actual latency must be established from the synthesized and verified implementation.

## Hardware Verification Status

| Component / Stage | Status |
|---|---|
| CNN-LSTM training and Python evaluation | Completed for the reported experiment |
| Fixed-point parameter export | Exported Q8.8 parameter files available |
| Weight ROM | Module simulation completed |
| Conv1D MAC | Module-level simulation performed |
| ReLU and max-pooling | Module-level simulation performed |
| Complete CNN-LSTM RTL integration | In progress |
| RTL-versus-Python reference comparison | In progress |
| Full-network synthesis | Planned |
| FPGA implementation and board-level testing | Planned |

Module-level tests establish the behaviour of the tested blocks only. They should not be interpreted as proof that the complete fixed-point network reproduces the Python model's predictions.

## Binary Classification Decision

The output layer produces two logits, one for Normal and one for AF. Softmax is not necessary when only a binary decision is required.

For an AF probability threshold \(t\), the equivalent decision rule is:

\[
\text{Predict AF if } z_{AF}-z_N
\geq \ln\left(\frac{t}{1-t}\right)
\]

For the reported threshold \(t=0.76\):

\[
\ln\left(\frac{0.76}{0.24}\right)\approx 1.153
\]

If the output logits are represented in Q8.8, this threshold corresponds approximately to a stored difference of 295, assuming both logits use the same scaling and fractional-bit convention.

This decision rule must use the correct output-class ordering and be validated against the quantized implementation. The floating-point threshold does not guarantee identical predictions after quantization.

## Repository Structure

The current hardware files are organized under `ecg_cnn_lstm_hw/`.

```text
ecg-cnn-lstm-classification/
|
├── ecg_cnn_lstm_hw/
|   ├── conv1d_mac.v
|   ├── relu_maxpool1d.v
|   ├── weight_rom.v
|   ├── tb_conv1d_mac.v
|   ├── tb_relu_maxpool1d.v
|   ├── tb_weight.v
|   ├── structure.txt
|   └── weights/
|       ├── layer1_conv1_param0.hex
|       ├── layer1_conv1_param1.hex
|       ├── layer4_conv2_param0.hex
|       ├── layer4_conv2_param1.hex
|       ├── layer8_conv3_param0.hex
|       ├── layer8_conv3_param1.hex
|       ├── layer12_lstm_param0.hex
|       ├── layer12_lstm_param1.hex
|       ├── layer12_lstm_param2.hex
|       ├── layer14_dense1_param0.hex
|       ├── layer14_dense1_param1.hex
|       ├── layer16_output_param0.hex
|       ├── layer16_output_param1.hex
|       └── weights_meta.json
|
└── README.md
```

This tree lists the current hardware files tracked in the project as described. Training and export scripts should be included in the repository if they are part of the committed source tree.

## Simulation

The Verilog modules can be simulated using Icarus Verilog and inspected using GTKWave.

Example commands, run from the hardware directory:

```powershell
iverilog -o sim_conv conv1d_mac.v weight_rom.v tb_conv1d_mac.v
vvp sim_conv
```

```powershell
iverilog -o sim_pool relu_maxpool1d.v tb_relu_maxpool1d.v
vvp sim_pool
```

For ROM testing, compile `weight_rom.v` with `tb_weight.v` using the actual ROM file paths expected by the module. Run simulations from a directory in which the relative `weights/` paths resolve correctly.

These commands demonstrate module-level simulation. An end-to-end testbench will be required once the complete inference datapath is integrated.

## Reproducing the Python Experiment

1. Open a Kaggle notebook and attach the PhysioNet/CinC 2017 `training2017` dataset.
2. Run the CNN-LSTM training script.
3. Evaluate the trained model using the specified record-level split and threshold.
4. Run the weight-export script.
5. Download the exported hexadecimal parameters and metadata.
6. Place the files in the hardware `weights/` directory.
7. Simulate the RTL modules and compare outputs against Python reference vectors.

The reported floating-point metrics are tied to the training run and evaluation configuration. Reproducing the same metrics requires matching the data split, preprocessing, checkpoint, window aggregation, and decision threshold.

## Future Work

- Complete the Conv1D computation engine across all time steps and channels.
- Implement and verify the fixed-point LSTM gate and state-update logic.
- Integrate dense and output layers with the correct fixed-point scaling.
- Create layer-by-layer Python reference vectors for RTL verification.
- Validate quantized outputs and measure any accuracy change.
- Integrate the full network using an FSM and suitable input/intermediate buffers.
- Run synthesis and timing analysis using Vivado.
- Evaluate FPGA resource utilization, throughput, latency, and power.
- Perform end-to-end FPGA validation.

## Limitations

- The reported model metrics are from floating-point Python evaluation.
- Fixed-point RTL accuracy has not yet been established for the complete network.
- The test set contains 74 AF records, and results come from one split without cross-validation.
- The classifier is trained for Normal versus AF; it is not designed to distinguish every possible cardiac rhythm.
- This project is an engineering and research prototype, not a clinically validated diagnostic device.

## Author

**Harshit Prajesh**  
B.Tech, Electronics and Communication Engineering  
IIIT Bhopal

**Interests:** RTL Design, ASIC Design, VLSI, FPGA, Functional Verification, Hardware Acceleration, and Edge AI.
