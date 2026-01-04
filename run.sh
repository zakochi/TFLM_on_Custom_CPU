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

# 1. 編譯軟體
make -C sw -j$(nproc)

# 2. 同步 Hex
echo ">>> Syncing Hex files to hw/src..."
cp -u sw/build/imem.hex hw/src/imem.hex
cp -u sw/build/dmem.hex hw/src/dmem.hex

# ==========================================
# Phase 2: Hardware Build Decision
# ==========================================
echo ""
echo ">>> [Step 2] Hardware Build Decision"
NEED_VIVADO=false

if [ ! -f "$BITSTREAM" ]; then
    echo "Reason: Bitstream missing (Checked: $BITSTREAM)"
    NEED_VIVADO=true
else
    # 檢查 Bitstream 是否存在
    echo "Info: Found existing Bitstream at $BITSTREAM"

    # 3. 檢查 Hex 是否比 Bitstream 新
    if [ "hw/src/imem.hex" -nt "$BITSTREAM" ] || [ "hw/src/dmem.hex" -nt "$BITSTREAM" ]; then
        echo "Reason: Software (Hex) updated in hw/src."
        NEED_VIVADO=true
        
        # 4. 觸發 Vivado 重讀 Hex
        if [ -f "hw/src/Computer.v" ]; then
            touch hw/src/Computer.v
        else
            touch "$HW_SRC_DIR"/*.v
        fi
    fi

    # 5. 檢查硬體源碼
    for f in $HW_SRC_DIR/*; do
        if [[ "$f" == *.hex ]]; then continue; fi
        
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
    
    if [ ! -f "soc/soc.xpr" ]; then
        echo ">>> Creating Vivado Project Structure..."
        vivado -mode batch -source ${TCL_DIR}/create_proj.tcl -nolog -nojournal
    fi

    echo ">>> Updating Memory & Bitstream..."
    vivado -mode batch -source ${TCL_DIR}/update_mem.tcl -nolog -nojournal
    
    if [ $? -ne 0 ]; then
        echo "Error: Vivado Build Failed. Check hw/vivado.log or logs under hw/soc/."
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

echo "open_hw_manager" > program_temp.tcl
echo "connect_hw_server" >> program_temp.tcl
echo "open_hw_target" >> program_temp.tcl
echo "set dev [lindex [get_hw_devices] 0]" >> program_temp.tcl
echo "current_hw_device \$dev" >> program_temp.tcl
echo "refresh_hw_device -update_hw_probes false \$dev" >> program_temp.tcl
echo "set_property PROGRAM.FILE {$BITSTREAM} \$dev" >> program_temp.tcl
echo "program_hw_devices \$dev" >> program_temp.tcl
echo "close_hw_manager" >> program_temp.tcl
echo "exit" >> program_temp.tcl

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

sleep 1
stty -F $UART_PORT $BAUD_RATE raw -echo cs8 -cstopb -parenb
cat $UART_PORT