################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src_app/src/gpio.c \
../src_app/src/interrupt.c \
../src_app/src/libc-hooks.c \
../src_app/src/main.c \
../src_app/src/main_blinky.c \
../src_app/src/system.c \
../src_app/src/uart.c \
../src_app/src/xprintf.c 

S_UPPER_SRCS += \
../src_app/src/startup.S 

OBJS += \
./src_app/src/gpio.o \
./src_app/src/interrupt.o \
./src_app/src/libc-hooks.o \
./src_app/src/main.o \
./src_app/src/main_blinky.o \
./src_app/src/startup.o \
./src_app/src/system.o \
./src_app/src/uart.o \
./src_app/src/xprintf.o 

S_UPPER_DEPS += \
./src_app/src/startup.d 

C_DEPS += \
./src_app/src/gpio.d \
./src_app/src/interrupt.d \
./src_app/src/libc-hooks.d \
./src_app/src/main.d \
./src_app/src/main_blinky.d \
./src_app/src/system.d \
./src_app/src/uart.d \
./src_app/src/xprintf.d 


# Each subdirectory must supply rules for building sources it contributes
src_app/src/%.o: ../src_app/src/%.c src_app/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -I"/home/taka/RISCV/mmRISC-1/workspace/mmRISC_FreeRTOS/src_kernel/inc" -I"/home/taka/RISCV/mmRISC-1/workspace/mmRISC_FreeRTOS/src_app/inc" -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src_app/src/%.o: ../src_app/src/%.S src_app/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -x assembler-with-cpp -DportasmHANDLE_INTERRUPT=external_interrupt_handler -I"/home/taka/RISCV/mmRISC-1/workspace/mmRISC_FreeRTOS/src_kernel/inc" -I"/home/taka/RISCV/mmRISC-1/workspace/mmRISC_FreeRTOS/src_app/inc" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


