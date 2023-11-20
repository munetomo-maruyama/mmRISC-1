################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src_kernel/src/croutine.c \
../src_kernel/src/event_groups.c \
../src_kernel/src/heap_4.c \
../src_kernel/src/list.c \
../src_kernel/src/port.c \
../src_kernel/src/queue.c \
../src_kernel/src/riscv-virt.c \
../src_kernel/src/stream_buffer.c \
../src_kernel/src/tasks.c \
../src_kernel/src/timers.c 

S_UPPER_SRCS += \
../src_kernel/src/portASM.S 

OBJS += \
./src_kernel/src/croutine.o \
./src_kernel/src/event_groups.o \
./src_kernel/src/heap_4.o \
./src_kernel/src/list.o \
./src_kernel/src/port.o \
./src_kernel/src/portASM.o \
./src_kernel/src/queue.o \
./src_kernel/src/riscv-virt.o \
./src_kernel/src/stream_buffer.o \
./src_kernel/src/tasks.o \
./src_kernel/src/timers.o 

S_UPPER_DEPS += \
./src_kernel/src/portASM.d 

C_DEPS += \
./src_kernel/src/croutine.d \
./src_kernel/src/event_groups.d \
./src_kernel/src/heap_4.d \
./src_kernel/src/list.d \
./src_kernel/src/port.d \
./src_kernel/src/queue.d \
./src_kernel/src/riscv-virt.d \
./src_kernel/src/stream_buffer.d \
./src_kernel/src/tasks.d \
./src_kernel/src/timers.d 


# Each subdirectory must supply rules for building sources it contributes
src_kernel/src/%.o: ../src_kernel/src/%.c src_kernel/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imafc_zicsr -mabi=ilp32f -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -ggdb -I"/media/psf/Home/Documents/CQ/RISCV/mmRISC/mmRISC-1/workspace/mmRISC_FreeRTOS/src_kernel/inc" -I"/media/psf/Home/Documents/CQ/RISCV/mmRISC/mmRISC-1/workspace/mmRISC_FreeRTOS/src_app/inc" -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src_kernel/src/%.o: ../src_kernel/src/%.S src_kernel/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv64-unknown-elf-gcc -march=rv32imafc_zicsr -mabi=ilp32f -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -ggdb -x assembler-with-cpp -DportasmHANDLE_INTERRUPT=external_interrupt_handler -I"/media/psf/Home/Documents/CQ/RISCV/mmRISC/mmRISC-1/workspace/mmRISC_FreeRTOS/src_kernel/inc" -I"/media/psf/Home/Documents/CQ/RISCV/mmRISC/mmRISC-1/workspace/mmRISC_FreeRTOS/src_app/inc" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


