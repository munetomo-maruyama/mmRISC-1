################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/float.c \
../src/gpio.c \
../src/interrupt.c \
../src/libc-hooks.c \
../src/main.c \
../src/system.c \
../src/uart.c \
../src/xprintf.c 

S_UPPER_SRCS += \
../src/startup.S 

OBJS += \
./src/float.o \
./src/gpio.o \
./src/interrupt.o \
./src/libc-hooks.o \
./src/main.o \
./src/startup.o \
./src/system.o \
./src/uart.o \
./src/xprintf.o 

S_UPPER_DEPS += \
./src/startup.d 

C_DEPS += \
./src/float.d \
./src/gpio.d \
./src/interrupt.d \
./src/libc-hooks.d \
./src/main.d \
./src/system.d \
./src/uart.d \
./src/xprintf.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imafc_zicsr -mabi=ilp32f -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -ggdb -DFLOAT_HARD -O0 -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.S src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv64-unknown-elf-gcc -march=rv32imafc_zicsr -mabi=ilp32f -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -ggdb -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


