################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../porting/src/heap_4.c \
../porting/src/port.c \
../porting/src/riscv-virt.c 

S_UPPER_SRCS += \
../porting/src/portASM.S 

OBJS += \
./porting/src/heap_4.o \
./porting/src/port.o \
./porting/src/portASM.o \
./porting/src/riscv-virt.o 

S_UPPER_DEPS += \
./porting/src/portASM.d 

C_DEPS += \
./porting/src/heap_4.d \
./porting/src/port.d \
./porting/src/riscv-virt.d 


# Each subdirectory must supply rules for building sources it contributes
porting/src/%.o: ../porting/src/%.c porting/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/kernel/inc" -O0 -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

porting/src/%.o: ../porting/src/%.S porting/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -x assembler-with-cpp -DportasmHANDLE_INTERRUPT=external_interrupt_handler -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/kernel/inc" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


