以串口2中断为例，定义中断步骤如下所示：

（1）在在uart.h文件中，对串口号进行宏定义，并对串口使用的引脚组(TX,RX)0进行配置：
 #define UART_1    1                             //UART_1
 #define UART_2    2                             //UART_2
 #define UART1_GROUP    0                        //UART_1的引脚组配置：0:PTA9~10,1:PTB6~7
 #define UART2_GROUP    0                        //UART_2的引脚组配置：0:PTA2~3 

（2）在user.h文件中,对串口进行宏定义：
 #define UART_Debug   UART_1                     //BIOS串口
 #define UART_User    UART_2                     //用户串口

（3）main.c文件中的主函数启动部分：
 uart_init(UART_User, 115200);                   //调用uart.h文件中的uart_init函数对串口进行初始化，设置串口号、波特率
 uart_enable_re_int(UART_User);                  //调用uart.h文件中的uart_enable_re_int函数开串口接收中断

（4）isr.c文件中UART_User串口收到一个字节后，触发UART_User_Handler程序：   
 void UART_User_Handler(void)
 {
   DISABLE_INTERRUPTS;                           //关总中断
   uint8_t flag,ch;
     if(uart_get_re_int(UART_User))              //函数获取串口接收中断标志，同时禁用发送中断
      {
        ch = uart_re1(UART_User,&flag);          //串行接收1个字节,&flag:接收成功标志的指针:&flag=1:接收成功；&flag=0:接收失败
        uart_send1(UART_User,ch);                //串行发送1个字节,ch:要发送的字节
      }
   ENABLE_INTERRUPTS;                            //开总中断
  }    

（5）在user.h文件中,重定义为UART2_Handler，并注册中断服务函数：
extern void UART_User_Handler(void);            	//中断服务函数
 #define UART2_Handler UART_User_Handler         //对UART_User_Handler重定义
 
（6）在user.c文件中,打开串口2中断服务程序，触发中断收发数据:          
 void USART2_IRQHandler(void) __attribute__((interrupt("WCH-Interrupt-fast")));
 void USART2_IRQHandler()
 {
   if(UART2_Handler != 0) UART2_Handler();
 }

         



