################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../app/src/gpio.c \
../app/src/interrupt.c \
../app/src/libc-hooks.c \
../app/src/main.c \
../app/src/main_blinky.c \
../app/src/riscv-virt.c \
../app/src/uart.c \
../app/src/xprintf.c 

S_UPPER_SRCS += \
../app/src/startup.S 

OBJS += \
./app/src/gpio.o \
./app/src/interrupt.o \
./app/src/libc-hooks.o \
./app/src/main.o \
./app/src/main_blinky.o \
./app/src/riscv-virt.o \
./app/src/startup.o \
./app/src/uart.o \
./app/src/xprintf.o 

S_UPPER_DEPS += \
./app/src/startup.d 

C_DEPS += \
./app/src/gpio.d \
./app/src/interrupt.d \
./app/src/libc-hooks.d \
./app/src/main.d \
./app/src/main_blinky.d \
./app/src/riscv-virt.d \
./app/src/uart.d \
./app/src/xprintf.d 


# Each subdirectory must supply rules for building sources it contributes
app/src/%.o: ../app/src/%.c app/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/app/inc" -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/kernel/inc" -O0 -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

app/src/%.o: ../app/src/%.S app/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -x assembler-with-cpp -DportasmHANDLE_INTERRUPT=external_interrupt_handler -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/app/inc" -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/kernel/inc" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


