################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (9-2020-q2-update)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../DWIN_LIB/DWIN.c \
../DWIN_LIB/DWIN_APP.c 

OBJS += \
./DWIN_LIB/DWIN.o \
./DWIN_LIB/DWIN_APP.o 

C_DEPS += \
./DWIN_LIB/DWIN.d \
./DWIN_LIB/DWIN_APP.d 


# Each subdirectory must supply rules for building sources it contributes
DWIN_LIB/%.o: ../DWIN_LIB/%.c DWIN_LIB/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L476xx -c -I../Core/Inc -I../Drivers/STM32L4xx_HAL_Driver/Inc -I../Drivers/STM32L4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L4xx/Include -I../Drivers/CMSIS/Include -I../DWIN_LIB -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-DWIN_LIB

clean-DWIN_LIB:
	-$(RM) ./DWIN_LIB/DWIN.d ./DWIN_LIB/DWIN.o ./DWIN_LIB/DWIN_APP.d ./DWIN_LIB/DWIN_APP.o

.PHONY: clean-DWIN_LIB

