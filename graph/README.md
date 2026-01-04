# VWW Model Implementation on Custom CPU

This repository facilitates the deployment of the Visual Wake Words (VWW) model on a custom CPU architecture. Follow the instructions below to prepare input data, configure the software, and run the simulation.

## 1. VWW Input Generation

The `graph/` directory is used to store test images for the VWW model (`vww_96_int8.tflite`). The input generation script `gen_vww_input_cc.py` is located in the root of this repository (`TFLM_on_Custom_CPU/`).

1.  **Add Images:**
    Place any custom images you wish to test inside the `graph/` directory.

2.  **Generate C-Arrays:**
    Execute the conversion script from the repository root (`TFLM_on_Custom_CPU/`):
    
    ```bash
    python3 gen_vww_input_cc.py
    ```
    
    * This script will scan the `graph/` folder.
    * It converts images into VWW-compatible input formats (96x96, int8).
    * It generates corresponding `.cc` files (e.g., `graph/person_office.cc`) inside the `graph/` folder.

## 2. Software Configuration

Before running the project, you need to configure the software build system for the VWW application.

1.  **Navigate to the software directory:**
    ```bash
    cd sw/
    ```

2.  **Select the Model:**
    Open `model_config.mk`. Uncomment the VWW model line and ensure all other models are commented out:
    ```makefile
    MODEL_NAME = vww_96_int8.tflite
    # MODEL_NAME = ad01_int8.tflite
    # ...
    ```

3.  **Swap the Main Application:**
    Switch the source file from the Audio (AD01) application to the VWW application (assuming the current `main.cc` is for AD01):
    ```bash
    # Backup the current AD01 main file
    mv main.cc main.cc.ad01
    
    # Enable the VWW main file
    mv main.cc.vww main.cc
    ```

4.  **Inject Input Data:**
    Open the newly enabled `main.cc`.
    * Open the generated `.cc` file you want to test (e.g., `../graph/person_office.cc`).
    * Copy the content of the C-array (the numbers inside `{ ... }`).
    * Paste it into the `input_data` array within `main.cc`:
    
    ```cpp
    // Put your input graph here
    extern const int8_t input_data[] = {
        // Paste the generated matrix content here...
        -50, -12, 10, ...
    };
    ```

## 3. Execution

Once configured, return to the project root directory (`TFLM_on_Custom_CPU`) and launch the run script.

1.  **Return to root:**
    ```bash
    cd ..
    ```

2.  **Run Simulation:**
    ```bash
    ./run
    ```

## 4. Development & Troubleshooting

### Hardware Modifications
If you modify any hardware source files in `hw/src/`:
* The system should attempt to re-synthesize automatically.
* **Force Re-synthesis:** If `./run` does not trigger a necessary re-synthesis, delete the SoC build directory manually:
    ```bash
    rm -r hw/soc
    ```

### Software Modifications
If you modify software files (like `main.cc`) but the changes are not reflected in the execution:
* **Force Re-compilation:** Delete the software build directory manually:
    ```bash
    rm -r sw/build
    ```

## 5. Acknowledgments & Credits

The test images included in the `graph/` directory are compiled from standard computer vision datasets and open-source collections. We acknowledge the following sources:

* **Standard Test Images:** Sourced from [Darknet (YOLO)](https://github.com/pjreddie/darknet) and [OpenCV Samples](https://github.com/opencv/opencv).
    * *Files:* `person_office`, `person_horse`, `noperson_eagle`, `noperson_dog`, `noperson_giraffe`, `person_basketball`, `noperson_fruits`, `noperson_house`.
  
These images are provided here for academic and educational testing purposes.
