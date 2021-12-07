#include <Arduino.h>
#include <MsTimer2.h>  //Serial output uses timer

//
unsigned char tcount = 0;
unsigned char Buffer[80];  //Create buffer
unsigned char Buffer_Len = 0;
bool pushButtonPWM;   // Create a boolean variable to store the PWM switch state
bool pushButtonSW;   // Create a boolean variable to store the switch state of the rangefinder
int ledPinPWM = 9;        //PWMLED pin number
int brightness = 128;  //PWMLED brightness parameters

//
unsigned char b[7]={
	0X5A,0XA5,0X07,0X82,0X21,0X00,0X00 //Serial output prefix
};
long a;                  //Ranging output result variable

float checkdistance_5_4(){      //Ranging function
 digitalWrite(5,LOW);
 delayMicroseconds(2);
 digitalWrite(5,HIGH);
 delayMicroseconds(10);
 digitalWrite(5,LOW);
 float distance = pulseIn(4,HIGH)/58.00;
 delay(10);
 return distance;
 }

void Timer2Interrupt()    //Timer function
{
  if(tcount>0)
    tcount--;
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);      //The baud rate is set to 115200
  pinMode(6,OUTPUT);              
  pinMode(7,OUTPUT);
  pinMode(3,OUTPUT);
  pinMode(2,OUTPUT);
 
  //
  pinMode(5,OUTPUT);
pinMode(4,INPUT);
//
  MsTimer2::set(5, Timer2Interrupt);//Timer setting, each step is 5ms
  MsTimer2::start();
//COM SETUP

}

void loop() {
  // put your main code here, to run repeatedly:
  if(Serial.available())
  {
    Buffer[Buffer_Len] = Serial.read();
    Buffer_Len++;
    tcount = 5;
  }
  else
  {
    if(tcount==0)
   { if(Buffer[0]==0X5A){             //Communication Frame Header Judgment
switch(Buffer[4]){

case 0x56 :                      //PWMLED brightness control
   brightness=Buffer[8];delay(10);analogWrite(ledPinPWM, brightness);
  break;
case 0x55:                      //LED on and off control
   if(Buffer[8]==1){digitalWrite(7, HIGH);}else
{digitalWrite(7, LOW);}
  break;
case 0x54:
   if(Buffer[8]==1){digitalWrite(6, HIGH);}else
{digitalWrite(6, LOW);}
break;
  case 0x53:
   if(Buffer[8]==1){digitalWrite(3, HIGH);}else
{digitalWrite(3, LOW);}
break;
  case 0x52:
   if(Buffer[8]==1){digitalWrite(2, HIGH);}else
{digitalWrite(2, LOW);}
break; 
  case 0x51:                   //Rangefinder switch
  pushButtonSW = Buffer[8];
break;
case 0x57:                     //Rangefinder reset
  if(Buffer[8]==1){a = 0;
  long c = a>>8;
  long d = a>>16;
  Serial.write(b,7);
  Serial.write(d);
  Serial.write(c&0x0000FF);
  Serial.write(a&0x0000FF);}
  
break;
      
      //
      }
      
      Buffer_Len = 0;      //Cache empty
    }
if(pushButtonSW){a = long(checkdistance_5_4()*100);  //Ranging output
  long c = a>>8;
  long d = a>>16;
  Serial.write(b,7);
  Serial.write(d);
  Serial.write(c&0x0000FF);
  Serial.write(a&0x0000FF);

  }                                        
                                
  }}
  //2021/12/7
  }
        
  
