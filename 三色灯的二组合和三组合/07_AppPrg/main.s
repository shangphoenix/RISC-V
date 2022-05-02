/*=====================================================================
//文件名称：main.s
//功能概要：三色灯的二组合和三组合
//编写者：苏州大学 2006405021 刘畅
//版本更新：20220502
//=====================================================================*/

.include "includes.inc"


/*（1）数据段定义  */
/* 定义数据存储data段开始，实际数据存储在RAM中 */
.section .data
data_format:                         /*字符串,\0为字符串结束标志*/
    .ascii "%d\n\0"                  /*printf使用的数据格式控制符 */
light_show:
    .ascii "闪烁次数mLightCount=\0"  /*闪烁次数提示*/
light_show0:
	.ascii "LIGHT_ALL:OFF--\n\0"           /*三个灯全灭状态提示*/
light_show1:
    .ascii "LIGHT_RED&GREEN:ON--\n\0"      /*红灯和绿灯亮状态提示   */
light_show2:
    .ascii "LIGHT_GREEN&BLUE:ON--\n\0"     /*绿灯和蓝灯灯亮状态提示*/
light_show3:
    .ascii "LIGHT_BLUE&RED:ON--\n\0"     /*蓝灯和红灯灯亮状态提示*/
light_show4:
    .ascii "LIGHT_ALL:ON--\n\0"     /*三个灯都亮状态提示*/


.align 4                   /*.word格式四字节对齐*/
mMainLoopCount:            /*定义主循环次数变量*/
    .word 0
mLightCount:               /*灯的闪烁次数*/
    .word 0   
mFlag:                    /*定义三个灯的状态标志,0全灭，1红绿灯亮，2绿蓝灯亮，3红蓝灯，4全亮 */
    .byte 0

/*（2）定义代码存储text段开始，实际代码存储在Flash中*/
.section   .text
hello_information:           /*字符串标号*/
	.ascii "\n"
    .ascii "-------------------------------------------------\n"
    .ascii "【金葫芦提示】汇编语言点亮发光二极管               \n"
    .ascii "    第一次用纯汇编点亮的红色发光二极管，太棒了！    \n"
    .ascii "    这只是万里长征第一步，但是，万事开头难,         \n"
    .ascii "    有了第一步，坚持下去，定有收获！               \n"
    .ascii "-------------------------------------------------\n\0"

.type main function    /*声明main为函数类型 */
.global main           /*将main定义成全局函数，便于芯片初始化之后调用*/
.align 2               /*指令和数据采用2字节对齐，兼容Thumb指令集*/

/* -------------------------------------------------------------------- */
/*主函数，一般情况下可以认为程序从此开始运行 */
main:
/*（3）======启动部分（开头）主循环前的初始化工作====================== */
/* 通过调整栈指针分配出出栈空间用于存放局部变量和调用函数返回地址，
      主函数中栈空间分出44字节，   ra为返回地址寄存器，占用4个字节，
      将ra中的返回地址放入sp指针地址偏移44个字节的位置*/
    ADDI sp,sp,-48                	/* 分配栈帧 */
    SW ra,44(sp)                	/* 存储放回地址 */
/* （3.1）声明main函数使用的局部变量 */

/* （3.2）【不变】关总中断 */
	LI t0, 0x8
	CSRC mstatus, t0
/* （3.3）给主函数使用的局部变量赋初值 */

/* （3.4）给全局变量赋初值 */

/* （3.5）用户外设模块初始化*/
/*  初始化红灯, a0、a1、a2是gpio_init的入口参数    */
    LI a0,LIGHT_RED                /* a0=端口号|引脚号 */
    LI a1,GPIO_OUTPUT              /* a1=输出模式 */
    LI a2,LIGHT_OFF                 /* a2=灯暗 */
    CALL gpio_init                 /* 调用gpio_init函数 */
/*  初始化绿灯, a0、a1、a2是gpio_init的入口参数    */
    LI a0,LIGHT_GREEN                /* a0=端口号|引脚号 */
    LI a1,GPIO_OUTPUT              /* a1=输出模式 */
    LI a2,LIGHT_OFF                 /* a2=灯暗 */
    CALL gpio_init                 /* 调用gpio_init函数 */
/*  初始化蓝灯, a0、a1、a2是gpio_init的入口参数    */
    LI a0,LIGHT_BLUE                /* a0=端口号|引脚号 */
    LI a1,GPIO_OUTPUT              /* a1=输出模式 */
    LI a2,LIGHT_OFF                 /* a2=灯暗 */
    CALL gpio_init                 /* 调用gpio_init函数 */
/* 初始化串口UART_User */
    LI a0,UART_User                /* 串口号 */
    LI a1,UART_User_baud           /* 波特率 */
    CALL uart_init                 /* 调用uart初始化函数 */
/* 初始化串口2中断 */
    LI a0,UART_User_IRQ
    LI a1,UART_User_baud
    CALL uart_init

/*（3.6）使能模块中断 */
    LI a0,UART_User_IRQ
    CALL uart_enable_re_int
    
/* （3.7）开总中断 */
	LI t0, 0x8
	CSRS mstatus, t0

/*显示hello_information定义的字符串    */
    LA a0,hello_information
    CALL printf

/*call .   //在此打桩(.表示当前地址)，理解发光二极管为何亮起来了？*/
/*（4）======启动部分（结尾）======================================= */

    LA t6,mMainLoopCount             /* t6作为mMainLoopCount变量 */
main_loop:
/*（4.1）主循环次数变量mMainLoopCount+1*/
    ADDI t6,t6,1
/*（4.2）未达到主循环次数设定值，继续循环 */
    LI t5,MAINLOOP_COUNT
    BLTU t6,t5,main_loop

/*（4.3）达到主循环次数设定值，执行下列语句，进行灯的亮暗处理  */
/*[测试代码部分]*/
/*（4.3.1）清除循环次数变量  */
    LA t6, mMainLoopCount     /*t6←mMainLoopCount的地址*/
    LI t5,0
    SW t5,0(t6)
/*(4.3.2)打印闪烁次数*/
	LA a3,mLightCount          /* a3←mLightCount的地址*/
    LW a1,0(a3)                /* a1←a3地址中的数据 */
    ADDI a1,a1,1               /* a1←a1+1 */
    SW a1,0(a3)                /* a3←a1 */
	/*mLightCount←mLightCount+1*/
    LA a0,light_show          /* a0←light_show3的地址 */
    CALL printf                /* 调用printf函数 */
	/*打印出“闪烁次数mLightCount=”*/
    LA a0,data_format          /* a0←data_format(按十进制整数输出) */
    LA a2,mLightCount          /* a2←mLightCount */
    LW a1,0(a2)                /* a1←a2 */
    CALL printf                /* 调用printf函数  */
    /*以十进制整数格式打印mLightCount的数值*/
/*（4.3.3）判断灯的状态标志mFlag，改变灯状态及标志 */
    /*判断灯的状态标志 */
    LA t2,mFlag
    LW t6,0(t2)
    LI t5,0
    BNE t6,t5,main_light_1   /* 判断mFlag是否为0，不相等跳转 */
    /*全灭*/
    LI a0,LIGHT_RED
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*关红灯*/
	LI a0,LIGHT_GREEN
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*关绿灯*/
    LI a0,LIGHT_BLUE
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*关蓝灯*/
    LA a2,mFlag
    LI t4,1
    SW t4,0(a2)
    /*灯的状态标志mFlag改为1*/
    LA a0,light_show0
    CALL printf
    /*打印灯亮提示*/
    J main_exit

main_light_1:
	LI t5,1
    BNE t6,t5,main_light_2   /* 判断mFlag是否为1，不相等跳转 */
	/*红绿*/
	LI a0,LIGHT_RED
    LI a1,LIGHT_ON
    CALL gpio_set
   /*开红灯*/
	LI a0,LIGHT_GREEN
    LI a1,LIGHT_ON
    CALL gpio_set
   /*开绿灯*/
    LA a2,mFlag
    LI t4,2
    SW t4,0(a2)
    /*灯的状态标志mFlag改为2*/
    LA a0,light_show1
    CALL printf
    /*打印灯亮提示*/
    J main_exit
main_light_2:
	LI t5,2
    BNE t6,t5,main_light_3   /* 判断mFlag是否为2，不相等跳转 */
	/*绿蓝*/
	LI a0,LIGHT_RED
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*关红灯*/
	LI a0,LIGHT_BLUE
    LI a1,LIGHT_ON
    CALL gpio_set
   /*开蓝灯*/
    LA a2,mFlag
    LI t4,3
    SW t4,0(a2)
    /*灯的状态标志mFlag改为3*/
    LA a0,light_show2
    CALL printf
    /*打印灯亮提示*/
    J main_exit
main_light_3:
	LI t5,3
    BNE t6,t5,main_light_4   /* 判断mFlag是否为3，不相等跳转 */
	/*红蓝*/
	LI a0,LIGHT_RED
    LI a1,LIGHT_ON
    CALL gpio_set
   /*开红灯*/
	LI a0,LIGHT_GREEN
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*关绿灯*/
    LA a2,mFlag
    LI t4,3
    SW t4,0(a2)
    /*灯的状态标志mFlag改为3*/
    LA a0,light_show3
    CALL printf
    /*打印灯亮提示*/
    J main_exit
main_light_4:
	/*全亮*/
	LI a0,LIGHT_BLUE
    LI a1,LIGHT_ON
    CALL gpio_set
   /*开绿灯*/
    LA a2,mFlag
    LI t4,0
    SW t4,0(a2)
    /*灯的状态标志mFlag改为0*/
    LA a0,light_show4
    CALL printf
    /*打印灯亮提示*/
    
main_exit:
    LI a5,0
    J main_loop                    /* 继续循环 */

/* 释放栈空间 */
    LW ra, 44(sp)               /* 恢复返回地址 */
    ADDI sp, sp, 48             /* 释放栈帧 */
    RET                         /* 返回 */