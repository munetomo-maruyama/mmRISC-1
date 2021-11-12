################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../kernel/src/croutine.c \
../kernel/src/event_groups.c \
../kernel/src/list.c \
../kernel/src/queue.c \
../kernel/src/stream_buffer.c \
../kernel/src/tasks.c \
../kernel/src/timers.c 

OBJS += \
./kernel/src/croutine.o \
./kernel/src/event_groups.o \
./kernel/src/list.o \
./kernel/src/queue.o \
./kernel/src/stream_buffer.o \
./kernel/src/tasks.o \
./kernel/src/timers.o 

C_DEPS += \
./kernel/src/croutine.d \
./kernel/src/event_groups.d \
./kernel/src/list.d \
./kernel/src/queue.d \
./kernel/src/stream_buffer.d \
./kernel/src/tasks.d \
./kernel/src/timers.d 


# Each subdirectory must supply rules for building sources it contributes
kernel/src/%.o: ../kernel/src/%.c kernel/src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -ggdb -I"/home/taka/RISCV/mmRISC/workspace/mmRISC_FreeRTOS/kernel/inc" -O0 -fno-common -fno-builtin-printf -nostartfiles -nostdlib -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


