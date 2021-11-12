################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src_porting/src/heap_4.c \
../src_porting/src/port.c \
../src_porting/src/riscv-virt.c 

S_UPPER_SRCS += \
../src_porting/src/portASM.S 

OBJS += \
./src_porting/src/heap_4.o \
./src_porting/src/port.o \
./src_porting/src/portASM.o \
./src_porting/src/riscv-virt.o 

S_UPPER_DEPS += \
./src_porting/src/portASM.d 

C_DEPS += \
./src_porting/src/heap_4.d \
./src_porting/src/port.d \
./src_porting/src/riscv-virt.d 


# Each subdirectory must supply rules for building sources it contributes
src_porting/src/%.o: ../src_porting/src/%.c src_porting/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/src_kernel/inc" -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/src_porting/inc" -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/src_app/inc" -O0 -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src_porting/src/%.o: ../src_porting/src/%.S src_porting/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -x assembler-with-cpp -DportasmHANDLE_INTERRUPT=external_interrupt_handler -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/src_kernel/inc" -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/src_porting/inc" -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/src_app/inc" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


