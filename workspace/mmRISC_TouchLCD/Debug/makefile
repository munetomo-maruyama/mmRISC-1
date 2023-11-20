################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include src/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

OPTIONAL_TOOL_DEPS := \
$(wildcard ../makefile.defs) \
$(wildcard ../makefile.init) \
$(wildcard ../makefile.targets) \


BUILD_ARTIFACT_NAME := mmRISC_TouchLCD
BUILD_ARTIFACT_EXTENSION := elf
BUILD_ARTIFACT_PREFIX :=
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME)$(if $(BUILD_ARTIFACT_EXTENSION),.$(BUILD_ARTIFACT_EXTENSION),)

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
mmRISC_TouchLCD.hex \

SECONDARY_SIZE += \
mmRISC_TouchLCD.siz \


# All Target
all: main-build

# Main-build Target
main-build: mmRISC_TouchLCD.elf secondary-outputs

# Tool invocations
mmRISC_TouchLCD.elf: $(OBJS) $(USER_OBJS) makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Building target: $@'
	@echo 'Invoking: GNU RISC-V Cross C Linker'
	riscv64-unknown-elf-gcc -march=rv32imafc_zicsr -mabi=ilp32f -msmall-data-limit=8 -mno-save-restore -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -ggdb -T "/media/psf/Home/Documents/CQ/RISCV/mmRISC/mmRISC-1/workspace/mmRISC_TouchLCD/link.ld" -nostartfiles -Xlinker --gc-sections -L/opt/riscv/riscv64-unknown-elf/lib/rv32imafc/ilp32f -L/opt/riscv/lib/gcc/riscv64-unknown-elf/12.2.0/rv32imafc/ilp32f -Wl,-Map,"mmRISC_TouchLCD.map" -nostartfiles -nostdlib -o "mmRISC_TouchLCD.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

mmRISC_TouchLCD.hex: mmRISC_TouchLCD.elf makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Invoking: GNU RISC-V Cross Create Flash Image'
	riscv64-unknown-elf-objcopy -O ihex "mmRISC_TouchLCD.elf"  "mmRISC_TouchLCD.hex"
	@echo 'Finished building: $@'
	@echo ' '

mmRISC_TouchLCD.siz: mmRISC_TouchLCD.elf makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Invoking: GNU RISC-V Cross Print Size'
	riscv64-unknown-elf-size --format=berkeley "mmRISC_TouchLCD.elf"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(SECONDARY_FLASH)$(SECONDARY_SIZE)$(ASM_DEPS)$(S_UPPER_DEPS)$(C_DEPS) mmRISC_TouchLCD.elf
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_SIZE)

.PHONY: all clean dependents main-build

-include ../makefile.targets
