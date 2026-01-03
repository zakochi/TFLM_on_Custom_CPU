# TFLM on Custom RISC-V CPU

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Xilinx_FPGA-red.svg)
![Architecture](https://img.shields.io/badge/Arch-RISC--V-green.svg)

This project demonstrates how to deploy **TensorFlow Lite for Microcontrollers (TFLM)** on a custom RISC-V soft-core processor. It features a fully automated "One-Click" build system that handles software compilation, hardware synthesis (Vivado), bitstream generation, and FPGA programming.

## Features

* **Integrated Workflow**: A single script (`run.sh`) manages both C++ software build and Verilog hardware synthesis.
* **Smart Build**: Automatically detects changes in Software (.cc) or Hardware (.v) to avoid unnecessary recompilation.
* **Headless Automation**: Uses TCL scripts to control Vivado in batch mode, removing the need for GUI operations.
* **TFLM Baseline**: Includes a stable TFLM integration derived from the CFU-Playground project.

## Prerequisites

Before you begin, ensure you have the following installed/downloaded:

1.  **Xilinx Vivado** (Verified on 2020.2 or later)
2.  **RISC-V Toolchain**:
    * We use the SiFive Freedom Tools (2020.08).
    * [**Download Here (riscv64-unknown-elf-gcc-10.1.0-2020.08.2)**](https://static.dev.sifive.com/dev-tools/freedom-tools/v2020.08/riscv64-unknown-elf-gcc-10.1.0-2020.08.2-x86_64-linux-ubuntu14.tar.gz)
3.  **Python 3** (For Hex generation scripts)
4.  **Make** & **Git**

## Directory Structure

To ensure the build scripts work correctly, please organize your workspace as follows:

```text
Project_Root/
├── riscv64-unknown-elf-gcc-10.1.0-2020.08.2-x86_64-linux-ubuntu14/  <-- Toolchain
└── proj/
    ├── tflite-micro/        <-- TFLM Source Code (Needed in Step 1)
    │   ├── tensorflow/
    │   ├── third_party/
    │   └── LICENSE
    └── TFLM_on_Custom_CPU/  <-- This Repository (cloned here)
        ├── hw/              
        │   ├── src/         <-- Hardware Source (.v, .vh, .xdc)
        │   ├── tcl/         <-- Automation Scripts
        │   └── soc/         <-- Vivado Project Output (Auto-generated)
        ├── sw/              <-- Software Source (App & Makefile)
        └── run.sh           <-- Automation Script
```
## How to Use
### Step 1: Prepare Environment
1. Toolchain: Download and extract the RISC-V toolchain to your Project_Root.

2. TFLM Source Code: Since this project depends on a specific snapshot of TFLM (circa 2021) for RISC-V compatibility, we recommend obtaining it from the CFU-Playground repository.

Run the following commands in your proj/ directory to fetch the correct version:

```
cd {your_Project_Root}/proj/

# Clone CFU-Playground to get the compatible TFLM version
git clone https://github.com/google/CFU-Playground.git

# Copy the TFLM directory to your project workspace
cp -r CFU-Playground/third_party/tflite-micro .

# (Optional) Clean up
rm -rf CFU-Playground
```

### Step 2: Clone Repository
Navigate to your proj directory and clone this repository:

```
cd {your_Project_Root}/proj/
git clone https://github.com/zakochi/TFLM_on_Custom_CPU.git
```
### Step 3: Run the Demo
Enter the repository directory and execute the automation script. This script will compile the software, synthesize the hardware (if needed), program the FPGA, and start the UART monitor.

```
cd TFLM_on_Custom_CPU
chmod +x run.sh
./run.sh
```

## License & Acknowledgments
This project is open-source and available under the Apache License 2.0.
Credits

TensorFlow Lite for Microcontrollers (TFLM):
Copyright © The TensorFlow Authors.
Licensed under Apache 2.0.
Official Repository

CFU-Playground:

The TFLM integration, Makefile patches, and directory structure used in this project are derived from the CFU-Playground project. We gratefully acknowledge their work in making TFLM accessible for RISC-V FPGA research.
Copyright © Google LLC and other contributors.
Licensed under Apache 2.0.

RISC-V Toolchain:

Provided by SiFive (Freedom Tools).

Disclaimer:

This project is for educational and research purposes. It is not an official Google product.
