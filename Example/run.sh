#!/bin/bash
set -e

# ==========================================
# Setting
# ==========================================
BITSTREAM="hw/soc/soc.runs/impl_1/Computer.bit"
BAUD_RATE=115200
HW_SRC_DIR="hw/src"
TCL_DIR="tcl"

# ==========================================
# Phase 1: Software Build
# ==========================================
echo ">>> [Step 1] Software Build"
if [ ! -d "sw/build" ]; then mkdir -p sw/build; fi

if [ ! -d "tflite-micro" ] && [ ! -d "../tflite-micro" ] && [ ! -d "../../tflite-micro" ]; then
    echo "Warning : tflite-micro not found."
fi

if [ ! -f "sw/build/micro_src/.tflm_ready" ]; then
    make -C sw prepare_tflm -j$(nproc)
fi

make -C sw -j$(nproc)

# ==========================================
# Phase 2: Hardware Build Decision
# ==========================================
echo ""
echo ">>> [Step 2] Hardware Build Decision"
NEED_VIVADO=false

if [ ! -f "$BITSTREAM" ]; then
    echo "Reason: Bitstream missing."
    NEED_VIVADO=true
else
    if [ "sw/build/imem.hex" -nt "$BITSTREAM" ] || [ "sw/build/dmem.hex" -nt "$BITSTREAM" ]; then
        echo "Reason: Software (Hex) updated."
        NEED_VIVADO=true
    fi
    for f in $HW_SRC_DIR/*; do
        if [ "$f" -nt "$BITSTREAM" ]; then
            echo "Reason: Hardware source ($f) updated."
            NEED_VIVADO=true
            break
        fi
    done
fi

if [ "$NEED_VIVADO" = true ]; then
    echo ">>> Starting Vivado Build..."
    
    cd hw
    
    # Check if project file exists inside soc/ directory
    if [ ! -f "soc/soc.xpr" ]; then
        echo ">>> Creating Vivado Project Structure..."
        vivado -mode batch -source ${TCL_DIR}/create_proj.tcl -nolog -nojournal
    fi

    echo ">>> Updating Memory & Bitstream..."
    vivado -mode batch -source ${TCL_DIR}/update_mem.tcl -nolog -nojournal
    
    if [ $? -ne 0 ]; then
        echo "Error: Fail to Generate Bitstream. Check Log under ./hw/soc/."
        cd ..
        exit 1
    fi
    
    cd ..
else
    echo ">>> Bitstream is up-to-date. Skipping Vivado."
fi

# ==========================================
# Phase 3: Program FPGA
# ==========================================
echo ""
echo ">>> [Step 3] Program FPGA"

cat << TCL_EOF > program_temp.tcl
open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices] 0]
current_hw_device \$dev
refresh_hw_device -update_hw_probes false \$dev
set_property PROGRAM.FILE {$BITSTREAM} \$dev
program_hw_devices \$dev
close_hw_manager
exit
TCL_EOF

vivado -mode batch -source program_temp.tcl -nolog -nojournal > /dev/null
rm program_temp.tcl

if [ $? -ne 0 ]; then
    echo "Error: Fail to Program (Please Check the USB Connection)."
    exit 1
fi
echo ">>> Programming Done."

# ==========================================
# Phase 4: UART Monitor
# ==========================================
echo ""
echo ">>> [Step 4] UART Monitor"

UART_PORT=""
for port in /dev/ttyUSB1 /dev/ttyUSB0; do
    if [ -e "$port" ]; then UART_PORT="$port"; break; fi
done

if [ -z "$UART_PORT" ]; then
    echo "Error: UART port not found."
    exit 1
fi

echo "Target UART: $UART_PORT ($BAUD_RATE)"
echo ">>> [PLEASE PRESS RESET BUTTON ON FPGA NOW]"
echo "----------------------------------------------"

stty -F $UART_PORT $BAUD_RATE raw -echo cs8 -cstopb -parenb
cat $UART_PORT