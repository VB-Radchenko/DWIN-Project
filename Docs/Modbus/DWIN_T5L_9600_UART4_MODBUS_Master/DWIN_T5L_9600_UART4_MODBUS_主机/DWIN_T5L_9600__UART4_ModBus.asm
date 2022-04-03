;==================
;缓充R30-R243   
;   214 BYTE
;备份地址 R244
;备份地址 R245
;指令序号 R246
;待接收长 R247
;发送长度 R248
;重复次数 R249
;通讯错误 R250
;收发标志 R251
;指令地址 R252
;指令地址 R253
;备用R254 255
;==================
                 ORG         1000H 
                 GOTO        Main
                 ORG         1080H
Main:            CALL        ModBus_Ini
Maia:            CALL        Dwin_ModBus_RTU 
                 GOTO        Maia
;==================
ModBus_Ini:      LDWR        R10,0X5AA5    ;0X0088H=5A通讯配置  88L=0XA5 启用通讯 
                 LDWR        R12,0XE000    ;0X0089=E000        22号指令起始地址  
                 LDWR        R14,0XFF00    ;0X008AH=255条指令   8AL=00= 模式
                 LDWR        R16,0X05FF    ;0X008BH=最多发送5次  8BL=100 延时发送下条 
                 LDWR        R18,0X0140    ;0X008CH=01 从机id   8CL=40 4口配置8N1 ?????????????
                 LDWR        R20,0X0A80    ;0X008D=2688 波特率 15667200/9600=0660H
                 LDWR        R0, 0X0088 
                 MOVXR       R10,0,6
Ini_RET:         NOP
                 RET
;==================           
Dwin_ModBus_RTU: LDBR        R10,7,1
                 MOVRD       R10,0,1  ;切换到第7组寄存器
判BUS执行条件:     LDWR        R0,0X0088;0X0088H=0X5A 执行一次配置 
                 MOVXR       R10,1,1
执行一次配置:		 IJNE        R10,0X5A,进入通讯过程
		         LDBR        R10,0X00,1
		         MOVXR       R10,0,1
		         CALL        Ser4_Setup
进入通讯过程:      IJNE        R11,0XA5,退出通讯过程
                 LDWR        R0,0X008A
                 MOVXR       R10,1,1
                 IJNE        R11,0,1
                 GOTO        执行主RTU模式 
                 IJNE        R11,2,2 
执行主RTU模式:     CALL        MOD_S_RTU_GC         
                 GOTO        退出通讯过程;执行MODBUS主机，RTU格式,返回数据中含时钟
                 IJNE        R11,4,退出通讯过程
                 CALL        MOD_L_RTU_GC 
退出通讯过程:      LDBR        R10,0,1
                 MOVRD       R10,0,1   ;切换到第0组寄存器      
                 RET
;====================
Ser4_Setup:      LDWR        R0,0X008C ;效验+波特率
                 MOVXR       R12,1,2
                 COMSET      R13,0     ;9600   25804800/设置的波特率
                 LDWR        R0,0X008A
                 MOVXR       R10,1,1
                 IJNE        R11,0,1
                 GOTO        SRCSH
                 IJNE        R11,2,SLRR246
SRCSH:           LDWR        R0,0X0089 ;0X0089 22号指令起始地址 
                 MOVXR       R252,1,1  ;指令地址 R252
计算备份地址:      LDWR        R0,0X008A                
                 MOVXR       R11,1,1 
                 LDBR        R10,0,1
                 LDWR        R12,8
                 LDBR        R14,0,4
                 SMAC        R10,R12,R14 
                 LDBR        R10,0,4
                 MOV         R252,R12,2
                 ADD         R10,R14,R18;指令条数x8+起始地址=R24R25
                 MOV         R24,R244,2 ;R244R245发送后的数据备份地址
SLRR246:         LDBR        R246,0,6                  
Ser4_SetupRET:   NOP                 
                 RET
;====================
MOD_S_RTU_GC:    IJNE        R251,1,SR进入发送;R251  收发标志
                 CALL        SR当前进入接收状态
                 GOTO        MOD_S_RTU_GCRET
SR进入发送:       CALL        SR进入发送状态 
MOD_S_RTU_GCRET: NOP 
                 RET
;====================  
SR进入发送状态:	 LDWR        R0,0X008B  ; 8BH=补发次数  8BL=指令间延时x100
                 MOVXR       R10,1,1
                 LDBR        R10,0,1
                 LDWR        R12,100
                 LDBR        R14,0,4
                 SMAC        R10,R12,R14;R16R17=指令间延时x100
                 MOVDR       35,R10,2
                 JU          R10,R16,SR进入发送状态RET  ;延迟未到退出
SR判上次错误:      IJNE        R250,0,SR判重发次数  ;通讯错误 R250 0=OK 1=无应答  2=超时 3=校验错误
SR判发送条件:      CALL        SR判断发送条件是否具备
                 IJNE        R254,1,SR指针+1调整 
		         CALL        SR计算接收长度+数据组织
                 GOTO        SR发送过程
SR判重发次数:      LDBR        R10,0,1     ;装载补发次数
                 LDWR        R0,0X008B                 
                 MOVXR       R11,1,1     ;R10R11  = 设定补发次数
                 MOV         R249,R255,1 ;R249    = 实际重发次数
                 LDBR        R254,0,1    ;R254R255= 实际重发次数
                 JU          R254,R10,SR备份数据装载
                 LDBR        R250,1,1
                 LDWR        R0,0X008E                       
                 MOVXR       R10,1,1
                 MOV         R250,R10,1 
                 MOVXR       R10,0,1
SR指针+1调整:     CALL        SR指针调整过程
                 GOTO        SR进入发送状态RET
SR备份数据装载:    MOV         R244,R0,2
                 MOV         R248,R9,1 
                 LDBR        R8,0,1
                 SHR         R8,2,1
                 INC         R9,0,1
                 MOVXR       R30,1,0    ;装载70字
SR发送过程:       LDBR        R9,1,1
SR发送过R:        RDXLEN      SerNum,R8  
                 IJNE        R8,0,1
                 GOTO        SR发送数据过程
                 RDXDAT      SerNum,R8,R9
                 GOTO        SR发送过R
SR发送数据过程:    COMTXD      SerNum,R30,R248 ;发送长度 R248
SR备份发送数据:    IJNE        R249,0,SR发送结束处理
                 MOV         R244,R0,2
                 MOV         R248,R9,1
                 LDBR        R8,0,1
                 SHR         R8,2,1
                 INC         R9,0,1 
                 MOVXR       R30,0,0    ;备份70字
SR发送结束处理:    LDBR        R251,1,1   ;收发标志=1,准备接收
                 INC         R249,0,1   ;R249发送次数+1
                 LDWR        R10,0      ;通信超时清零
                 MOVRD       R10,35,2   ;通信超时清零  T1定时器=0
SR进入发送状态RET: NOP               
		         RET
;===================                 
SR指针调整过程:    LDBR        R247,0,5   ;实际重发次数R249=0 通讯错误 R250=0 R251=0
                 INC         R246,0,1   ;指令序号 R246+1
		         LDWR        R0,0X008A  ;8AH=配置的指令条数
                 MOVXR       R10,1,1
                 CJNE        R10,R246,SR地址指针+8
                 LDBR        R246,0,1
                 LDWR        R0,0X0089 ;0X0089  22号指令起始地址
                 MOVXR       R252,1,1  ;当前地址 R252
                 GOTO        SR指针调整过程RET
SR地址指针+8:     INC         R252,1,8
SR指针调整过程RET: NOP                 
                 RET
;==================
SR判断发送条件是否具备:
		         LDBR        R254,0,1   ;这个标志复用
		         MOV         R252,R0,2  ;R252当前地址
		         MOVXR       R10,1,8    ;R10-R21
;R10=5A R11=ID   R12=CMD R13=Len R14=超时 R15=执行模式 R16R17=备份
;R18R19=DGUS地址  R20R21=从机地址点表  
SR本条是否启用:    IJNE        R10,0x5A,SR判断发送条件是否具备RET   
SR无条件的执行0:   IJNE        R15,0x00,SR当前页执行1  
                 GOTO        SR通信条件具备                
SR当前页执行1:     IJNE        R15,0x01,SR指定按键值非零2
                 LDWR        R0,0X0014  ;当前页面   
                 MOVXR       R24,1,1
		         CJNE        R24,R16,SR判断发送条件是否具备RET      
		         CJNE        R25,R17,SR判断发送条件是否具备RET
		         GOTO        SR通信条件具备
SR指定按键值非零2: IJNE        R15,0x02,SR06发送完清0模式3;发送后等于0
                 MOV         R252,R0,2             ;当前地址R252
                 INC         R0,1,3                ;指向触发按键
                 MOVXR       R24,1,1
                 MOV         R24,R0,2
                 MOVXR       R24,1,1
                 IJNE        R25,0,1
                 GOTO        SR判断发送条件是否具备RET
                 LDWR        R24,0
                 MOVXR       R24,0,1
                 GOTO        SR通信条件具备
SR06发送完清0模式3:IJNE        R15,0x03,SR变量值发生变化4      
                 IJNE        R12,0x06,SR判断发送条件是否具备RET
                 MOV         R18,R0,2
                 MOVXR       R24,1,1
                 IJNE        R24,0,SR通信条件具备
                 IJNE        R25,0,SR通信条件具备
                 GOTO        SR判断发送条件是否具备RET
SR变量值发生变化4: IJNE        R15,0X04,SR模式5  ;分06 ，10 指令
SR变量值变化05H:  IJNE        R12,0X05,SR变量值变化06H
                 CALL        SR搜寻变化的bit位
                 CJNE        R51,R53,1
                 GOTO        SR判断发送条件是否具备RET        
                 MOVXR       R8,0,1         
                 GOTO        SR通信条件具备
SR变量值变化06H:   IJNE        R12,0x06,SR变量值变化10H  ;06指令
		         MOV         R18,R0,2                ;R18R19=DGUS地址
		         MOVXR       R24,1,1                 ;R24R25=读入变量当前值       
		         MOV         R252,R0,2               ;R252当前执行地址 
		         INC         R0,1,3                  ;当前地址+偏移量3=备份地址
		         MOVXR       R26,1,1
		         CJNE        R24,R26,2
                 CJNE        R25,R27,1
                 GOTO        SR判断发送条件是否具备RET
		         MOVXR       R24,0,1
		         GOTO        SR通信条件具备
SR变量值变化10H:   IJNE        R12,0x10,SR判断发送条件是否具备RET   
                 MOV         R18,R0,2                ;R18R19=DGUS地址起始
		         LDWR        R8,0
		         MOV         R13,R9,1                ;R8R9 待处理数据长度
		         MOVXR       R30,1,0                                
                 SHL         R9,1,1                  ;字长*2=字节长
		         CRCA        R30,R6,R9
		         MOV         R252,R0,2
		         INC         R0,1,3
		         MOVXR       R24,1,1
                 CJNE        R6,R24,2
                 CJNE        R7,R25,1
                 GOTO        SR判断发送条件是否具备RET
		         MOVXR       R6,0,1
		         GOTO        SR通信条件具备
SR模式5:          IJNE        R15,5,SR判断发送条件是否具备RET		          
		         GOTO        SR判断发送条件是否具备RET
SR通信条件具备:    LDBR        R254,1,1
SR判断发送条件是否具备RET:   
                 RET
;================== 
SR搜寻变化的bit位:
                 LDBR        R50,0,16          ;R50R51R52R53R54R55R56R57  
                 MOV         R18,R56,2       ; /R58R59R60R61R62R63R64R65  
                 LDWR        R64,16          
                 DIV         R50,R58,0
                 LDBR        R56,1,1  
                 INC         R57,0,0X10
                 MOV         R56,R0,2
                 MOVXR       R50,1,1
                 MOV         R50,R8,2
                 MOV         R252,R0,2
                 INC         R0,1,3
                 MOVXR       R52,1,1
LOOPBITR:        IJNE        R65,0,1
                 GOTO        SR屏蔽高15bit                 
                 SHR         R50,2,1
                 SHR         R52,2,1
                 DEC         R65,0,1
                 GOTO        LOOPBITR
SR屏蔽高15bit:    LDWR        R54,1           
                 AND         R50,R54,2  
                 AND         R52,R54,2
                 MOV         R51,R255,1      ;
                 RET
;==================   	
SR计算接收长度+数据组织:
                 MOV         R252,R0,2  ;R252当前地址
		         MOVXR       R10,1,8    ;R10-R21
SR指令1:          IJNE        R12,0X01,SR指令2  ;指令1
                 GOTO        1-2LEN=7
SR指令2:          IJNE        R12,0X02,SR指令3  ;指令2         ;01 01 02 XX XX C  C 
1-2LEN=7:        LDBR        R247,7,1          ;R247待接收长度;R30R31R32R33R34R35R36
                 GOTO        SR基本指令
SR指令3:          IJNE        R12,0X03,SR指令4  ;指令3
                 GOTO        SR计算待接收长度    ;计算待接收长度
SR指令4:          IJNE        R12,0X04,SR指令5  ;指令4
SR计算待接收长度:   MOV         R13,R247,1       ;R247待接收长度
                 SHL         R247,1,1
	             INC         R247,0,5
                 LDWR        R0,0X008A
                 MOVXR       R30,1,1
                 IJNE        R31,2,1           ;指令数据后加时钟=2
                 INC         R247,0,6          ;6字节时钟 
	             GOTO        SR基本指令
SR指令5:          IJNE        R12,0X05,SR指令06-10;指令5           
	             LDBR        R247,8,1          ;R247待接收长度
	             GOTO        SR基本指令
SR指令06-10:      LDBR        R247,8,1          ;指令06-10  
SR基本指令:       CALL         SR待发送数据组织
数据组织RET:      NOP
                 RET            
;================
SR待发送数据组织: ;R10=5A R11=ID   R12=CMD R13=Len R14=超时 R15=执行模式 R16R17=备份   
                ;R18R19=DGUS地址  R20R21=从机地址点表 
LOADID+CMD:      MOV         R11,R30,2    ;ID+cmd
		         MOV         R20,R32,2    ;从机地址
SRCMD=01:	     IJNE        R12,0X01,1
		         GOTO        SRCMD=02
		         IJNE        R12,0X02,SRCMD=03 ;R30R31  R32R33  R34R35  R36R37
SRCMD=02:  	     CALL        DYSR0102
		         GOTO        SRPKWRET
SRCMD=03:        IJNE        R12,0X03,1
		         GOTO        SRCMD=04
		         IJNE        R12,0X04,SRCMD=05
SRCMD=04:        LDBR        R34,0,1         ;01 03 10 00  00 01 xx xx
		         MOV         R13,R35,1
		         LDBR        R9,6,1
		         CRCA        R30,R36,R9
		         LDBR        R248,8,1   ;发送长度  
		         GOTO        SRPKWRET
SRCMD=05:        IJNE        R12,0X05,SRCMD=06
                 LDWR        R34,0XFF00
                 IJNE        R255,0,1 
                 LDWR        R34,0
                 LDBR        R9,6,1
                 CRCA        R30,R36,R9
				 LDBR        R248,8,1   ;发送长度  
				 GOTO        SRPKWRET
SRCMD=06:        IJNE        R12,0X06,SRCMD=10          
				 MOV         R18,R0,2
				 MOVXR       R34,1,1        ;01 06 10 00 00 01 xx xx
				 LDBR        R9,6,1
				 CRCA        R30,R36,R9
				 LDBR        R248,8,1   ;发送长度 
				 IJNE        R15,0X03,SRPKWRET 
				 LDWR        R22,0
				 MOV         R18,R0,2
				 MOVXR       R22,0,1
				 GOTO        SRPKWRET
SRCMD=10:        IJNE        R12,0X10, SRPKWRET;R30R31R32R33R34R35R36R37R38R39R40R41 R42 
				 CALL        DYSR10
SRPKWRET:        NOP
                 RET
;=================
DYSR0102:        LDWR        R34,16            ;01 01   00 63    00 10   XX XX 
                 LDBR        R9,6,1
		         CRCA        R30,R36,R9
		         LDBR        R248,8,1   ;发送长度 
                 RET
;=================
DYSR10:          LDBR        R34,0,1           ;01 10 10 00 00 02 04 xx xx xx xx crchcrcl
				 MOV         R13,R35,1
                 MOV         R13,R36,1
				 SHL         R36,1,1    
				 MOV         R18,R0,2
				 MOV         R35,R9,1
				 MOVXR       R37,1,0
				 MOV         R36,R9,1
				 INC         R9,0,7
				 CRCA        R30,R254,R9
				 LDBR        R2,254,1
				 MOV         R9,R3,1
				 INC         R3,0,30
				 LDBR        R9,2,1
				 MOVA
				 DEC         R3,0,28
				 MOV         R3,R248,1
                 RET 
;=================
SR当前进入接收状态: LDWR       R10,0
                 RDXLEN     SerNum,R11    
                 LDBR       R12,0,1 
                 MOV        R247,R13,1    ;R247待接收长度
                 JU         R10,R12,SR通讯超时判断
                 RDXDAT     SerNum,R30,R247
                 GOTO       SR接收数据校验
SR通讯超时判断:    CALL       SR超时判断           
                 IJNE       R254,1,SR当前进入接收状态RET 
                 LDBR       R250,2,1      ;通讯超时=2
                 LDBR       R251,0,1      ;转为发送状态
                 GOTO       SR错误序号上传
SR接收数据校验:    CALL       SR接收数据校验过程 
                 IJNE       R0,0,SR校验错误处理
                 CALL       SR正确数据处理过程
                 GOTO       SR错误序号上传
SR校验错误处理:    LDBR       R250,3,1      ;R250,校验错误=3
                 LDBR       R251,0,1      ;转为发送状态
SR错误序号上传:    LDWR       R0,0X008E                       
                 MOVXR      R10,1,1
                 MOV        R250,R10,1 
                 MOVXR      R10,0,1
SR当前进入接收状态RET:                
                 RET
;=======================                
SR超时判断:       LDBR       R254,0,1     
                 MOV        R252,R0,2
                 INC        R0,1,2 
                 MOVXR      R11,1,1
                 LDBR       R10,0,1
                 LDWR       R12,100
                 LDBR       R14,0,4 
                 SMAC       R10,R12,R14     ;R16R17  超时设定时间
                 MOVDR      35,R10,2
                 JU         R10,R16,SR超时判断RET
SR通讯超时:       LDBR       R254,1,1 
SR超时判断RET:    NOP             
                 RET
;================== 
SR接收数据校验过程: MOV         R247,R2,1   ;R247 待接收长度
				 DEC         R2,0,2;
				 INC         R2,0,30
				 LDBR        R3,254,1
				 LDBR        R9,2,1
				 MOVA 
				 MOV         R247,R9,1
				 DEC         R9,0,2
				 CRCA        R30,R20,R9
				 TESTS       R20,R254,2
                 RET  
;==================
SR正确数据处理过程:;R10=CMD R11=LEN  R12=超时 R13=触发方式  R14R15=备用 R16R17=Dgus地址
			     MOV         R252,R0,2          ;R252=地址指针
				 INC         R0,1,1
				 MOVXR       R10,1,4
			     IJNE        R31,0X01,SRR31=02
			     GOTO        SRBITZL            ;010102 XX   XX    C     C 
SRR31=02:		 IJNE        R31,0X02,SRR31=03  ;       R33  R34   R35   R36                 
SRBITZL:         LDBR        R50,0,16          ;R50R51R52R53R54R55R56R57  
                 MOV         R16,R56,2       ; /R58R59R60R61R62R63R64R65  
                 LDWR        R64,16          
                 DIV         R50,R58,0
                 LDBR        R56,1,1
                 MOV         R56,R0,2
                 MOV         R34,R32,1
				 MOVXR       R32,0,1 
				 GOTO        SR接受数据处理完
SRR31=03:        IJNE        R31,0X03,SRR31=04
		         GOTO        SRWRDATA
SRR31=04:		 IJNE        R31,0X04,SR接受数据处理完  ;03 04 指令的接收数据CRCHCRCL 前有6字节时间
SRWRDATA:        MOV         R16,R0,2
                 MOV         R11,R9,1
                 MOVXR       R33,0,0             ;                         R33R34R35R36R37R38R39R40R41R42 
                 CALL        SR附带的时间移入       ;附带的时间移入   01 03 0A  XX XX XX XX 年 月 日  时 分 秒   crch crcl
SR接受数据处理完:  LDWR        R0,0X008E 
                 LDWR        R10,0
                 MOV         R246,R11,1
                 MOVXR       R10,0,1
                 CALL        SR指针调整过程
                 RET  
;=====================   
SR附带的时间移入:  LDWR        R0,0X008A
                 MOVXR       R10,1,1
                 IJNE        R11,2,SR附带的时间移入RET
                 SHL         R9,1,1
                 INC         R9,0,33
                 MOV         R9,R2,1 
                 LDBR        R3,10,1 
                 LDBR        R9,6,1
                 MOVA
                 MOV         R15,R16,1
                 MOV         R14,R15,1
                 MOV         R13,R14,1
                 LDWR        R0,0X0010    
                 MOVXR       R10,0,4
SR附带的时间移入RET:                 
                 RET
;==================== 
;从机模式
;收到数据 R252
;长度备份 R253
;备用R254 255
;===================                
MOD_L_RTU_GC:    RDXLEN     SerNum,R10
                 IJNE       R10,0,1
                 GOTO       MOD_L_RTU_GCRET 
                 IJNE       R252,0,LR追加后续数据
                 MOV        R10,R253,1
                 LDBR       R252,1,1   ;有数据输入标志
                 LDWR       R10,0      ;通信超时清零
                 MOVRD      R10,35,2   ;通信超时清零  T1定时器=0
                 GOTO       MOD_L_RTU_GCRET
LR追加后续数据:    CJNE       R10,R253,1                 
                 GOTO       LR无后续数据追加
                 MOV        R10,R253,1
                 LDWR       R10,0      ;通信超时清零
                 MOVRD      R10,35,2   ;通信超时清零  T1定时器=0
                 GOTO       MOD_L_RTU_GCRET
LR无后续数据追加:  LDWR       R10,200
                 MOVDR      35,R12,2                
                 JU         R12,R10,MOD_L_RTU_GCRET 
                 RDXDAT     SerNum,R30,R253      
                 CALL       LR接收指令处理 
MOD_L_RTU_GCRET: NOP                
                 RET   
;=================== 
LR接收指令处理:    LDWR       R0,0X008C
                 MOVXR      R10,1,1
LR_ID_比对:       CJNE       R10,R30,LR接收指令处理RET
                 MOV        R253,R9,1
                 DEC        R9,0,2      
                 CRCA       R30,R254,R9   
                 LDBR       R3,250,1
                 MOV        R253,R2,1 
                 INC        R2,0,28
                 LDBR       R9,2,1
                 MOVA
                 CJNE       R250,R254,LRXYERR
                 CJNE       R251,R255,LRXYERR
LR校验ok:         IJNE       R31,0X01,1
                 GOTO       LR=02  
                 IJNE       R31,0X02,LR=03 ;ID 01 XX XX XX XX C C 
LR=02:           DEC        R32,1,1
                 LDBR       R50,0,16         ;R50R51R52R53R54R55R56R57
                 MOV        R32,R56,2        ;R58R59R60R61R62R63R64R65 
                 LDWR       R64,16 
                 DIV        R50,R58,0
                 LDBR       R56,1,1
                 MOV        R56,R0,2
                 INC        R1,0,0X10
                 MOV        R65,R9,1
                 MOVXR      R12,1,1
                 INC        R0,1,1
                 MOVXR      R10,1,1
LOOP0102Y:       IJNE       R9,0,1                 
                 GOTO       W0102SJ
                 DEC        R9,0,1      
                 SHR        R10,4,1
                 GOTO       LOOP0102Y
W0102SJ:         MOV        R12,R34,1         
                 MOV        R13,R33,1
                 LDBR       R32,2,1       
                 LDBR       R248,5,1       ;01 01 L XX XX C C  
                 CRCA       R30,R254,R248 
                 GOTO       LRCJY  
LR=03:           IJNE       R31,0X03,1
                 GOTO       LR=04
                 IJNE       R31,0X04,LR=05   ;ID 03 XX XX XX XX C C  
LR=04:           MOV        R32,R0,2
                 MOV        R35,R32,1
                 SHL        R32,1,1
                 MOV        R35,R9,1
                 MOVXR      R33,1,0
                 MOV        R32,R248,1
                 INC        R248,0,3
                 CRCA       R30,R254,R248
                 GOTO       LRCJY
LR=05:           IJNE       R31,0X05,LR=06   ;ID 05 00 64 FF 00 C C 
                 ;DEC        R32,1,1
                 LDBR       R50,0,16         ;R50R51R52R53R54R55R56R57
                 MOV        R32,R56,2        ;R58R59R60R61R62R63R64R65 
                 LDWR       R64,16 
                 DIV        R50,R58,0
                 LDBR       R56,1,1
                 MOV        R56,R0,2
                 MOV        R65,R9,1
                 IJNE       R34,0XFF,LRBITW0
                 LDWR       R7,1 
LOOPLRYW:        IJNE       R9,0,1                 
                 GOTO       LRBITW1
                 SHL        R7,2,1 
                 DEC        R9,0,1
                 GOTO       LOOPLRYW
LRBITW1:         MOVXR      R10,1,1                 
                 OR         R10,R7,2
                 GOTO       LRW05YD
LRBITW0:         LDWR       R7,0XFFFE                 
LOOPLRYW1:       IJNE       R9,0,1                 
                 GOTO       WLRBIT0
                 SHL        R7,2,1 
                 DEC        R9,0,1
                 GOTO       LOOPLRYW1
WLRBIT0:         MOVXR      R10,1,1            
                 AND        R10,R7,2
LRW05YD:         MOVXR      R10,0,1
                 MOV        R36,R254,2 
                 LDBR       R254,6,1
                 GOTO       LRCJY
LR=06:           IJNE       R31,0X06,LR=10    ;ID 06 XX XX XX XX C C 
                 MOV        R32,R0,2 
                 MOVXR      R34,0,1
                 LDBR       R248,6,1
                 MOV        R36,R254,2 
                 GOTO       LRCJY
LR=10:           IJNE       R31,0X10,LR接收指令处理RET
                 MOV        R32,R0,2          ;ID 10 ADH ADL LEH LEL ZL XX XX XX XX C C 
                 MOV        R35,R9,1
                 MOVXR      R37,0,0
                 LDBR       R9,6,1
                 CRCA       R30,R254,R9
                 LDBR       R248,6,1
                 GOTO       LRCJY
LRXYERR:         INC        R31,0,0X80
                 LDBR       R32,1,1
                 LDBR       R248,3,1
                 CRCA       R30,R254,R248
LRCJY:           COMTXD     SerNum,R30,R248
                 LDBR       R248,2,1
                 COMTXD     SerNum,R254,R248
LR接收指令处理RET: NOP                                     
                 RET 
;===================                 
;HXE1000:    LDWR       R4,0X1800
;            LDWR       R6,0X1000
;            LDWR       R2,0x0200
;LOOP_EXH1000:MOV        R4 ,R0,2
;            MOVXR      R10,1,2
;            MOV        R10,R14,2
;            MOV        R6,R0,2
;            MOVXR      R12,0,2
;            INC        R4,1,2
;            INC        R6,1,2
;            INC        R8,1,1
;            JS         R8,R2,LOOP_EXH1000
;                
;                         
; HXERET1000:
;           RET   		    
;============================================		    
XCH:        LDWR       R4,0X8000
            LDWR       R6,0X8800
            LDWR       R2,0X0200
LOOP_EXH:   MOV        R4 ,R0,2
            MOVXR      R10,1,2
            MOV        R10,R14,2
            MOV        R6,R0,2
            MOVXR      R12,0,2
            INC        R4,1,2
            INC        R6,1,2
            INC        R8,1,1
            JS         R8,R2,LOOP_EXH
           
 HXERET:
           RET                            
        