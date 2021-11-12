################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../application/src/gpio.c \
../application/src/interrupt.c \
../application/src/libc-hooks.c \
../application/src/main.c \
../application/src/main_blinky.c \
../application/src/uart.c \
../application/src/xprintf.c 

S_UPPER_SRCS += \
../application/src/startup.S 

OBJS += \
./application/src/gpio.o \
./application/src/interrupt.o \
./application/src/libc-hooks.o \
./application/src/main.o \
./application/src/main_blinky.o \
./application/src/startup.o \
./application/src/uart.o \
./application/src/xprintf.o 

S_UPPER_DEPS += \
./application/src/startup.d 

C_DEPS += \
./application/src/gpio.d \
./application/src/interrupt.d \
./application/src/libc-hooks.d \
./application/src/main.d \
./application/src/main_blinky.d \
./application/src/uart.d \
./application/src/xprintf.d 


# Each subdirectory must supply rules for building sources it contributes
application/src/%.o: ../application/src/%.c application/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/kernel/inc" -O0 -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

application/src/%.o: ../application/src/%.S application/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -x assembler-with-cpp -DportasmHANDLE_INTERRUPT=external_interrupt_handler -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/kernel/inc" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


