//======================================================================
//文件名称：user.h（user头文件）
//制作单位：SD-Arm(sumcu.suda.edu.cn)
//更新记录：20200831-20200903
//======================================================================

#ifndef __USER_H
#define __USER_H

//（1）【固定】文件包含
#include "emuart.h"
#include "flash.h"
#include "uart.h"
#include "gec.h"
#include "printf.h"

//（2）【变动】指示灯端口及引脚定义—根据实际使用的引脚改动

//（3）【变动】BIOS使用的串口,用于User程序写入及打桩调试

//（4）【变动】中断服务函数宏定义



//（5）注册中断服务函数  【CC-220102】
extern void UART2_Handler();

#endif /* USER_H_ */
