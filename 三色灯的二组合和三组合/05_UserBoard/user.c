///=====================================================================
//�ļ����ƣ�user.c�ļ�
//������λ��SD-Arm(sumcu.suda.edu.cn)
//���¼�¼��20211230
//��ֲ���򣺡��̶���
//=====================================================================
#include "user.h"


void USART2_IRQHandler(void) __attribute__((interrupt("WCH-Interrupt-fast")));
void USART2_IRQHandler()
{
    if(UART2_Handler != 0) UART2_Handler();
}

