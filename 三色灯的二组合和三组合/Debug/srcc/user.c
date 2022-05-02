///=====================================================================
//文件名称：user.c文件
//制作单位：SD-Arm(sumcu.suda.edu.cn)
//更新记录：20211230
//移植规则：【固定】
//=====================================================================
#include "user.h"


void USART2_IRQHandler(void) __attribute__((interrupt("WCH-Interrupt-fast")));
void USART2_IRQHandler()
{
    if(UART2_Handler != 0) UART2_Handler();
}

