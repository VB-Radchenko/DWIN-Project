#ifndef __DWIN_H
#define __DWIN_H

//==============================================================================
//---------------------------------Includes-------------------------------------
//==============================================================================
#ifdef STM32L476xx
#include "stm32l4xx_hal.h"
#endif
#include <stdbool.h>
//==============================================================================
//---------------------------------Defines--------------------------------------
//==============================================================================
#define DWIN_UART huart4

#define DWIN_UART_BUFFER_SIZE 400
//==============================================================================
//--------------------------------Variables-------------------------------------
//==============================================================================
typedef enum 
{
  none = 0x00,
  writeReg = 0x80,
  readReg = 0x81,
  writeVariable = 0x82,
  readVariable = 0x83
}commandDWIN;


struct parsingDataDWIN_P
{
  uint16_t header;
  uint8_t length;
  commandDWIN command;
  uint8_t data[249];
};

struct readDataDWIN_P{
     uint16_t uartBuffer[DWIN_UART_BUFFER_SIZE];
     uint16_t uartCnt;
     uint8_t GettingByte;
     bool PacketReady;
     uint16_t delayOverflowMaxTime;
     uint16_t lengthRxPacket;
     bool timeoutOverflow;
     uint8_t rxData[DWIN_UART_BUFFER_SIZE];
     uint16_t timeoutDelay;
     struct parsingDataDWIN_P parsingDataDWIN;
  } ;
//==============================================================================
//--------------------------------PROTOTYPE-------------------------------------
//==============================================================================


//==============================================================================
//--------------------------------FUNCTIONS-------------------------------------
//==============================================================================
void dwinUartDmaInit();
void writeLedDWIN(uint8_t ledWork, uint8_t ledSleep);
void writeVariableDWIN(uint8_t len, uint16_t adress, uint8_t* data);
void writeHalfWordDWIN(uint16_t adress, uint16_t data);
void writeWordDWIN(uint16_t adress, uint32_t data);
void writeDoubleWordDWIN(uint16_t adress, uint64_t data);
void readVariableDWIN(uint16_t adress, uint8_t lenHalfWord);
void goToPageDWIN(uint16_t page);
void receivingDataPacket();
void parsingDWIN();
//==============================================================================
//---------------------------------END FILE-------------------------------------
//==============================================================================
#endif /* __DWIN_H */
