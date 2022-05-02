/*======================================================================
//文件名称：user.inc
//功能概要：包含工程中用到的头文件
//版权所有：SD-ARM(sumcu.suda.edu.cn)
//版本更新：2019-09-01 V1.0
//======================================================================*/
.include "gpio.inc"

/*指示灯端口及引脚定义*/
.equ LIGHT_RED,  (PTC_NUM|0)      /*红色RUN灯使用的端口/引脚*/
.equ LIGHT_GREEN,(PTC_NUM|1)      /*绿色RUN灯使用的端口/引脚*/
.equ LIGHT_BLUE, (PTC_NUM|2)      /*蓝色RUN灯使用的端口/引脚*/

/*灯状态宏定义（灯亮、灯暗对应的物理电平由硬件接法决定）*/
.equ LIGHT_ON,1                 /*灯亮*/
.equ LIGHT_OFF,0                /*灯暗*/

/* GPIO引脚方向宏定义*/
.equ GPIO_INPUT,  0     /*GPIO输入*/
.equ GPIO_OUTPUT, 1    /*GPIO输出*/

.equ UART_User, 1       /*TX引脚：GEC_10；RX引脚：GEC_8(实物板上标识UART0)*/
.equ UART_User_IRQ, 2
.equ UART_User_baud,115200
/*宏定义相关数据*/
.equ DELAY_NUM,1000000          /*延时数（约1秒），控制小灯闪烁频率*/
.equ UART_BAUD,115200           /*串口波特率*/

/*myprintf重定义*/
.equ printf, myprintf

.equ MAINLOOP_COUNT,15000000    /*主循环次数设定值（常量）*/
.equ SystemCoreClock,72000000

/*定义原中断处理程序名*/
.type  UART2_Handler, function
.global UART2_Handler

/* 定义新中断处理程序名 */
.type UART_User_Handler, function
.global UART_User_Handler

/*建立新旧中断处理程序名的映射*/
.equ UART2_Handler,UART_User_Handler
