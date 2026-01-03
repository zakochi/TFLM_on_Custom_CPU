# ==========================================
# 1.  Toolchain 
# ==========================================
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TARGET_PREFIX := riscv64-unknown-elf

CC      = $(TARGET_PREFIX)-gcc
CXX     = $(TARGET_PREFIX)-g++
OBJCOPY = $(TARGET_PREFIX)-objcopy
SIZE    = $(TARGET_PREFIX)-size
MKDIR   = mkdir -p
COPY    = cp -r
RM      = rm -rf

PROJECT_ROOT = .
PLATFORM_DIR = $(PROJECT_ROOT)/platform
APP_DIR      = $(PROJECT_ROOT)/app
BUILD_DIR    = $(PROJECT_ROOT)/build
TFLM_SRC_ROOT = ../../tflite-micro

MICRO_BUILD_DIR = $(BUILD_DIR)/micro_src
TFLM_PREPARED_MARKER = $(MICRO_BUILD_DIR)/.tflm_ready

#### Set Model ####
-include $(PROJECT_ROOT)/model_config.mk
MODEL_NAME ?= ad01_int8.tflite


# ==========================================
# 2. TFLM Copy List
# ==========================================
TFLM_COPY_SRC_DIRS := \
	tensorflow/lite \
	tensorflow/lite/c \
	tensorflow/lite/core/api \
	tensorflow/lite/core/c \
	tensorflow/lite/kernels \
	tensorflow/lite/kernels/internal \
	tensorflow/lite/kernels/internal/optimized \
	tensorflow/lite/kernels/internal/reference \
	tensorflow/lite/kernels/internal/reference/integer_ops \
	tensorflow/lite/micro \
	tensorflow/lite/micro/kernels \
	tensorflow/lite/micro/memory_planner \
	tensorflow/lite/micro/arena_allocator \
	tensorflow/lite/micro/tflite_bridge \
	tensorflow/lite/schema

TFLM_FIND_PARAMS := -maxdepth 1 -type f -not -name '*_test*' -regex '.*\.\(h\|c\|cc\)'

# ==========================================
# 3. Compiler Parameter
# ==========================================
ARCH_FLAGS   = -march=rv32i -mabi=ilp32 -mcmodel=medany
COMMON_FLAGS = $(ARCH_FLAGS) -Os -g -ffunction-sections -fdata-sections -fno-builtin \
               -fsingle-precision-constant -flto

CXXFLAGS     = $(COMMON_FLAGS) -std=c++11 -fno-rtti -fno-exceptions -fno-threadsafe-statics -fpermissive
CFLAGS       = $(COMMON_FLAGS) -std=c11

LDFLAGS      = $(ARCH_FLAGS) -T $(PLATFORM_DIR)/linker.ld \
               -nostartfiles -Wl,--gc-sections \
               -flto \
               --specs=nano.specs -lm

INCLUDES  = -I$(PROJECT_ROOT) -I$(APP_DIR) -I$(PLATFORM_DIR) -I$(MICRO_BUILD_DIR)
INCLUDES += -I$(MICRO_BUILD_DIR)/third_party/flatbuffers/include
INCLUDES += -I$(MICRO_BUILD_DIR)/third_party/gemmlowp
INCLUDES += -I$(MICRO_BUILD_DIR)/third_party/ruy

# ==========================================
# 4. Compress
# ==========================================
PLATFORM_SRCS = $(wildcard $(PLATFORM_DIR)/*.c)
PLATFORM_ASM  = $(wildcard $(PLATFORM_DIR)/*.S)
APP_SRCS      = $(wildcard $(APP_DIR)/*.cc)

TFLM_SRCS_ALL = $(shell find $(MICRO_BUILD_DIR) -name "*.cc" -o -name "*.c" 2>/dev/null)
TFLM_SRCS     = $(filter-out %_test.cc %_benchmark.cc %/micro_interpreter_context.cc, $(TFLM_SRCS_ALL))
TFLM_SRCS    := $(filter-out %/fft2d/fft4g.c %/fft2d/fft8g.c %_h.c, $(TFLM_SRCS))

SRCS_C   = $(filter %.c, $(TFLM_SRCS) $(PLATFORM_SRCS))
SRCS_CXX = $(filter %.cc, $(TFLM_SRCS) $(APP_SRCS)) 
SRCS_ASM = $(PLATFORM_ASM)

MODEL_OBJ = $(BUILD_DIR)/model_data.o

OBJS = $(SRCS_C:%.c=$(BUILD_DIR)/%.o) \
       $(SRCS_CXX:%.cc=$(BUILD_DIR)/%.o) \
       $(SRCS_ASM:%.S=$(BUILD_DIR)/%.o) \
       $(MODEL_OBJ)

# ==========================================
# 5. Build Rules
# ==========================================

all: prepare_tflm $(BUILD_DIR)/imem.hex $(BUILD_DIR)/dmem.hex

prepare_tflm: $(TFLM_PREPARED_MARKER)

$(TFLM_PREPARED_MARKER):
	@echo "Copying TFLM sources..."
	@$(MKDIR) $(MICRO_BUILD_DIR)
	@for d in $(TFLM_COPY_SRC_DIRS); do \
		mkdir -p $(MICRO_BUILD_DIR)/$$d; \
		find $(TFLM_SRC_ROOT)/$$d $(TFLM_FIND_PARAMS) -exec cp {} $(MICRO_BUILD_DIR)/$$d \; ; \
	done
	@echo "Copying Third Party..."
	@mkdir -p $(MICRO_BUILD_DIR)/third_party/gemmlowp
	@$(COPY) $(TFLM_SRC_ROOT)/third_party/gemmlowp/fixedpoint $(MICRO_BUILD_DIR)/third_party/gemmlowp
	@$(COPY) $(TFLM_SRC_ROOT)/third_party/gemmlowp/internal $(MICRO_BUILD_DIR)/third_party/gemmlowp
	@mkdir -p $(MICRO_BUILD_DIR)/third_party/flatbuffers/include
	@$(COPY) $(TFLM_SRC_ROOT)/third_party/flatbuffers/include/* $(MICRO_BUILD_DIR)/third_party/flatbuffers/include
	@mkdir -p $(MICRO_BUILD_DIR)/third_party/ruy/ruy/profiler
	@$(COPY) $(TFLM_SRC_ROOT)/third_party/ruy/ruy/profiler/instrumentation.h $(MICRO_BUILD_DIR)/third_party/ruy/ruy/profiler
	@mkdir -p $(MICRO_BUILD_DIR)/third_party/fft2d
	@$(COPY) $(TFLM_SRC_ROOT)/third_party/fft2d/*.h $(MICRO_BUILD_DIR)/third_party/fft2d 2>/dev/null || true
	@$(COPY) $(TFLM_SRC_ROOT)/third_party/fft2d/*.c $(MICRO_BUILD_DIR)/third_party/fft2d 2>/dev/null || true
	
	@echo "Applying patches..."
	@sed -i 's/TF_LITE_GLOBAL_STD_PREFIX::/::/g' $(MICRO_BUILD_DIR)/tensorflow/lite/kernels/internal/cppmath.h
	@sed -i 's/std::fmax/::fmax/g' $(MICRO_BUILD_DIR)/tensorflow/lite/kernels/internal/max.h
	@sed -i 's/std::fmin/::fmin/g' $(MICRO_BUILD_DIR)/tensorflow/lite/kernels/internal/min.h
	@touch $@

$(BUILD_DIR)/model_data.cc: $(APP_DIR)/$(MODEL_NAME) $(PROJECT_ROOT)/model_config.mk
	@echo "Converting $< to C++ using Python..."
	@$(MKDIR) $(dir $@)
	@python3 -c "import sys; data=open(sys.argv[1],'rb').read(); print('// Source: $(MODEL_NAME)'); print('#include <cstddef>'); print('#include <cstdint>'); print('extern const unsigned char g_model[];'); print('alignas(16) extern const unsigned char g_model[] = {'); print(','.join([hex(b) for b in data])); print('};'); print('extern const int g_model_len = ' + str(len(data)) + ';')" $< > $@

$(MODEL_OBJ): $(BUILD_DIR)/model_data.cc
	@echo "CXX (Model) $<"
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR)/main.elf: $(OBJS)
	@echo "Linking $@"
	@$(CXX) $(LDFLAGS) -o $@ $^
	@echo "======================================================="
	@echo "Build Size Summary:"
	@$(SIZE) $@
	@echo "======================================================="

$(BUILD_DIR)/imem.bin: $(BUILD_DIR)/main.elf
	@echo "Extracting IMEM binary..."
	@$(OBJCOPY) -O binary -j .text $< $@

$(BUILD_DIR)/dmem.bin: $(BUILD_DIR)/main.elf
	@echo "Extracting DMEM binary..."
	@# DMEM Section (rodata, data, bss)
	@$(OBJCOPY) -O binary -j .rodata -j .data -j .bss $< $@

$(BUILD_DIR)/imem.hex: $(BUILD_DIR)/imem.bin
	@echo "Generating IMEM Hex (32-bit width)..."
	@python3 -c "import sys; \
	f=open(sys.argv[1],'rb'); data=f.read(); f.close(); \
	w=open(sys.argv[2],'w'); \
	w.write('@00000000\n'); \
	[w.write(''.join(['{:02X}'.format(b) for b in reversed(data[i:i+4])]) + '\n') for i in range(0, len(data), 4)]; \
	w.close();" $< $@

$(BUILD_DIR)/dmem.hex: $(BUILD_DIR)/dmem.bin
	@echo "Generating DMEM Hex (32-bit width)..."
	@python3 -c "import sys; \
	f=open(sys.argv[1],'rb'); data=f.read(); f.close(); \
	w=open(sys.argv[2],'w'); \
	w.write('@00000000\n'); \
	[w.write(''.join(['{:02X}'.format(b) for b in reversed(data[i:i+4])]) + '\n') for i in range(0, len(data), 4)]; \
	w.close();" $< $@

$(OBJS): $(TFLM_PREPARED_MARKER)

$(BUILD_DIR)/%.o: %.cc
	@$(MKDIR) $(dir $@)
	@echo "CXX $<"
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: $(BUILD_DIR)/%.cc
	@$(MKDIR) $(dir $@)
	@echo "CXX (Src) $<"
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: %.c
	@$(MKDIR) $(dir $@)
	@echo "CC $<"
	@$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@$(MKDIR) $(dir $@)
	@echo "ASM $<"
	@$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	@echo "Cleaning build directory..."
	$(RM) $(BUILD_DIR)

.PHONY: all clean prepare_tflm