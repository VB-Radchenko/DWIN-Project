
//==============================================================================
//---------------------------------Includes-------------------------------------
//==============================================================================
#include "DWIN_APP.h"
#include "DWIN.h"
#include <stdbool.h>
#include <string.h>
#include <math.h>
#include "tim.h"
//==============================================================================
//---------------------------------Defines--------------------------------------
//==============================================================================
#define ledDataAdress 0x5006
#define PI 3.14159265
#define VAL 0.01745329251994329576923690768489
//==============================================================================
//--------------------------------Variables-------------------------------------
//==============================================================================
extern struct readDataDWIN_P readDataDWIN;
extern struct curveDataDWIN_p curveDataDWIN;
uint32_t PWMData = 0;
uint16_t adress = 0;
uint8_t adress_h,adress_l;
//==============================================================================
//--------------------------------PROTOTYPE-------------------------------------
//==============================================================================


//==============================================================================
//--------------------------------FUNCTIONS-------------------------------------
//==============================================================================

//==============================================================================
//--------------------------------APP INIT--------------------------------------
//==============================================================================

void dwinAppInit()
{

	  HAL_TIM_PWM_Start(&htim2, TIM_CHANNEL_1);
	  TIM2->CCR1=0;
	  memset(&curveDataDWIN, 0, sizeof(curveDataDWIN));

}
//==============================================================================
//---------------------------------PWM LED--------------------------------------
//==============================================================================

void ledPWM()
{
	parsingDWIN();
	readVariableDWIN(0x5006, 1);
	HAL_Delay(1);
	parsingDWIN();
	adress = ledDataAdress;
	adress_h = ((ledDataAdress & 0xFF00)>>8);
	adress_l = ledDataAdress & 0x00FF;
	if (((readDataDWIN.parsingDataDWIN.data[0] == (ledDataAdress & 0xFF00)>>8)) && (readDataDWIN.parsingDataDWIN.data[1] == (ledDataAdress & 0x00F))) // Checking for address match
	{
		PWMData = readDataDWIN.parsingDataDWIN.data[3]<<8 | readDataDWIN.parsingDataDWIN.data[4];
		if (PWMData >= 50)
		{
			PWMData = ((PWMData - 49) * 2000);
			TIM2->CCR1 = PWMData;
			//TIM2->CCR1 = 1000;
		}
		else
		{
			TIM2->CCR1 = 0;
		}
	}
}

//==============================================================================
//--------------------------------Curve One-------------------------------------
//==============================================================================

uint16_t cnt = 0;
void curveOneProcessDWIN()
{
	cnt++;
	  if ( cnt < 180)
	  {
		  writeOneCurveDWIN(0, 1, &cnt);
		  waitOkMessageDWIN();

	  }
	  else
	  {
		  cnt = 0;
	  }
}

//==============================================================================
//--------------------------------Curve All-------------------------------------
//==============================================================================
uint16_t meandr = 0;
void curveProcessDWIN()
{
	  if ( cnt < 180)
	  {
		  if (cnt < 90) meandr = 50;
		  else meandr = 200;
		  cnt++;

		  curveDataDWIN.CurveEnable[0] = true;
		  curveDataDWIN.CurveEnable[1] = true;
		  curveDataDWIN.CurveEnable[2] = true;
		  curveDataDWIN.CurveEnable[3] = true;
		  curveDataDWIN.CurveEnable[4] = true;
		  curveDataDWIN.CurveEnable[5] = true;
		  curveDataDWIN.CurveEnable[6] = true;
		  curveDataDWIN.CurveEnable[7] = true;

		  curveDataDWIN.CurveLenData[0] = 1;
		  curveDataDWIN.CurveLenData[1] = 1;
		  curveDataDWIN.CurveLenData[2] = 1;
		  curveDataDWIN.CurveLenData[3] = 1;
		  curveDataDWIN.CurveLenData[4] = 1;
		  curveDataDWIN.CurveLenData[5] = 1;
		  curveDataDWIN.CurveLenData[6] = 1;
		  curveDataDWIN.CurveLenData[7] = 1;

		  curveDataDWIN.CurveData[0][0] = cnt;
		  curveDataDWIN.CurveData[1][0] = sin(cnt * 2 * VAL) * 127 + 127;
		  curveDataDWIN.CurveData[2][0] = cos(cnt * 2 * VAL) * 127 + 127;
		  curveDataDWIN.CurveData[3][0] = cnt;
		  curveDataDWIN.CurveData[4][0] = sin(cnt * 2 * VAL) * 127 + 127;
		  curveDataDWIN.CurveData[5][0] = cos(cnt * 2 * VAL) * 127 + 127;
		  curveDataDWIN.CurveData[6][0] = meandr;
		  curveDataDWIN.CurveData[7][0] = meandr;

		  writeCurveDWIN(curveDataDWIN);
		  waitOkMessageDWIN();
		  memset(&curveDataDWIN, 0, sizeof(curveDataDWIN));
	  }
	  else
	  {
		  cnt = 0;
	  }
}

//==============================================================================
//------------------------------Curve All X10-----------------------------------
//==============================================================================
void curveProcessX10DWIN()
{
	  if ( cnt < 18)
	  {
		  if (cnt < 9) meandr = 50;
		  else meandr = 200;
		  cnt++;

		  curveDataDWIN.CurveEnable[0] = true;
		  curveDataDWIN.CurveEnable[1] = true;
		  curveDataDWIN.CurveEnable[2] = true;
		  curveDataDWIN.CurveEnable[3] = true;
		  curveDataDWIN.CurveEnable[4] = true;
		  curveDataDWIN.CurveEnable[5] = true;
		  curveDataDWIN.CurveEnable[6] = true;
		  curveDataDWIN.CurveEnable[7] = true;

		  curveDataDWIN.CurveLenData[0] = 10;
		  curveDataDWIN.CurveLenData[1] = 10;
		  curveDataDWIN.CurveLenData[2] = 10;
		  curveDataDWIN.CurveLenData[3] = 10;
		  curveDataDWIN.CurveLenData[4] = 10;
		  curveDataDWIN.CurveLenData[5] = 10;
		  curveDataDWIN.CurveLenData[6] = 1;
		  curveDataDWIN.CurveLenData[7] = 1;

		  for (uint8_t i = 0; i <10 ; i++)
		  {
			  curveDataDWIN.CurveData[0][i] = cnt*10 + i;
			  curveDataDWIN.CurveData[3][i] = cnt*10 + i;
		  }

		  for (uint8_t i = 0; i <10 ; i++)
		  {
			  curveDataDWIN.CurveData[1][i] = sin((cnt * 10 + i) * 2 * VAL) * 127 + 127;
			  curveDataDWIN.CurveData[4][i] = sin((cnt * 10 + i) * 2 * VAL) * 127 + 127;
		  }


		  for (uint8_t i = 0; i <10 ; i++)
		  {
			  curveDataDWIN.CurveData[2][i] = cos((cnt * 10 + i) * 2 * VAL) * 127 + 127;
			  curveDataDWIN.CurveData[5][i] = sin((cnt * 10 + i) * 2 * VAL) * 127 + 127;
		  }

		  curveDataDWIN.CurveData[6][0] = meandr;
		  curveDataDWIN.CurveData[7][0] = meandr;

		  writeCurveDWIN(curveDataDWIN);
		  waitOkMessageDWIN();
		  memset(&curveDataDWIN, 0, sizeof(curveDataDWIN));
	  }
	  else
	  {
		  cnt = 0;
	  }
}
//==============================================================================
//---------------------------------END FILE-------------------------------------
//==============================================================================
