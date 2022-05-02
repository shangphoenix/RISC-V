.include "gpio.inc"

.equ NOERROR,       0x0
.equ ERROR,         0x1
.equ LEDON,         0x1
#定义代码存储text段开始，实际代码存储在Flash中
.section   .text
.align 2                          /*指令和数据采用2字节对齐*/

gpio_port_pin_resolution:
/* 通过调整栈指针分配出出栈空间用于存放局部变量和存放调用函数返回地址，
      主函数中栈空间分出16字节，   ra为返回地址寄存器，占用4个字节，将ra
      中的返回地址放入sp指针地址偏移16个字节的位置*/
	addi sp, sp, -16			/* 分配堆栈框架*/
	sw ra, 12(sp)				/* 将寄存器地址写到堆栈上*/
	/* 计算出GPIO端口号和引脚号 */
	srli t4,a0,0x8				/* t4=a0=端口号 */
	andi t5,a0,255				/* a2=a0=引脚号 */
	mv a0,t4
	mv a1,t5
	/* 释放栈空间 */
	lw ra, 12(sp)               /* 恢复返回地址 */
    addi sp, sp, 16             /* 释放栈帧 */
    mv  a0,	t4					/* 读取返回值 */
    mv  a1, t5					/* 读取返回值 */
    ret							/* 返回 */

/*======================================================================
// 函数名称：gpio_init
// 函数返回：无
// 参数说明：r0:(端口号|(引脚号)),例:(PTB_NUM|(5u))表示B口5脚,头文件中有宏定义
//           r1:引脚方向（0=输入,1=输出,可用引脚方向宏定义）
//           r2:端口引脚初始状态（0=低电平，1=高电平）
// 功能概要：初始化指定端口引脚作为GPIO引脚功能，并定义为输入或输出。若是输出，
//           还指定初始状态是低电平或高电平
// 备    注：端口x的每个引脚控制寄存器PORTx_PCRn的地址=PORT_PCR_BASE+x*0x1000+n*4
//           其中:x=0~4，对应A~E;n=0~31
//======================================================================  */
.type GPIO_init function          /*声明gpio_init为函数类型*/
.global gpio_init                 /*将gpio_init定义成全局函数，便于芯片初始化之后调用*/
gpio_init:
/* 通过调整栈指针分配出出栈空间用于存放局部变量和存放调用函数返回地址，
      主函数中栈空间分出16字节，   ra为返回地址寄存器，占用4个字节，将ra
      中的返回地址放入sp指针地址偏移16个字节的位置*/
	addi sp, sp, -16			/* 分配堆栈框架*/
	sw ra, 12(sp)				/* 将寄存器地址写到堆栈上*/

	mv a3,a2					/* 将函数第3个参数a2赋值给a3 */
	mv a2,a1					/* 将函数第2个参数a1赋值给a2/
/* 计算出GPIO端口号和引脚号 */
	/*jalr gpio_port_pin_resolution	/* a0=端口号，a1=引脚号 */
	srli t4,a0,0x8				/* t4=a0=端口号 */
	andi t5,a0,255				/* t5=a0=引脚号 */
	mv a0,t4					/* a0=端口号 */
	mv a1,t5					/* a1=引脚号 */
/* 配置GPIO时钟 */
	li t0, RCC_APB2PCENR_BASE	/* 将时钟APB2PCENR寄存器赋值给t0 */
	mv t1, a0					/* t1=a0=端口号 */
	li t2, 1					/* 1左移两位赋值给t2寄存器 */
	addi t1,t1,2				/* t1=t1+2 等于GPIO时钟需要左移的位*/
	sll t2, t2, t1				/* t1 左移 t2位 */
	sw t2, 0(t0)				/* 这里是开GPIO的时钟  */
/* 判断GPIO引脚是否大于7 */
	li a4, 0x08					/* a4=0x08 */
	bgeu a1,a4,GPIO_PIN_H		/* 当(a1=引脚号)>(a4=0x08)时跳转 GPIO_PIN_H*/
	j GPIO_PIN_L				/* 当(a1=引脚号)<=(a4=0x08)时跳转 GPIO_PIN_H*/
/* 引脚PIN大于7时 */
GPIO_PIN_H:
/* 算出GPIOx相对于GPIOA的偏移地址 */
	mv t0, a0					/* t0=a0=端口号 */
	li t1, 0x400				/* t1=各端口基地址差值(0x400)*/
	mul t0, t0, t1				/* t0=待操作端口与GPIOA口的偏移地址 */
/* 就算出GPIOx的地址给 ->t0  */
	li t1, GPIOA_CFGHR			/* 加载GPIO的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/

/* 判断GPIO输入输出模式 */
	beqz a2, gpio_input_H		/* 函数第2个参数a2=0，则跳转gpio_input_H */
	li t4,1						/* t4=1 */
	beq a2,t4, gpio_output_H	/* 函数第2个参数a2=1，则跳转gpio_output_H */
	li a2, ERROR
	j exit

/* 配置GPIO引脚为输出模式 */
gpio_output_H:
	li t1, 4					/* t1=4 */
	li t3, 8					/* t3=8 */
	sub t3,a1,t3				/* t3=((a1=引脚号)- 8)*/
	mul t1,t1,t3				/* t1= 4*(a1=引脚号) */
	li t2, GPIO_PINS_0			/* PTA_0为0x00000002输出  */
	sll t2,t2,t1				/* t2<<t1位 */
	sw t2, 0(t0)				/* 向t0寄存器保存的地址中 写入t2寄存器中存储的数据 */
/* 判断GPIO输出电平状态 */
	beqz a3, ledOFF				/* 将函数第3个传参给a3，如果a3为0则跳转ledOFF */
	li t3, LEDON				/* 给t3寄存器赋值0x01 */
	beq a3, t3, ledON			/* 比较a3和t3是否相等，相等则跳转置ledON */
	li a3, ERROR
	j exit

/* 配置GPIO引脚为输入模式 */
gpio_input_H:
	li t1, 4					/* t1=4 */
	li t3, 8					/* t3=8 */
	sub t3,a1,t3				/* t3=((a1=引脚号)- 8)*/
	mul t1,t1,t3				/* t1= 4*(a1=引脚号) */
	li t2, 0x00000000			/* PTA_0为0x00000002输出  */
	sll t2,t2,t1				/* t2<<t1位 */
	sw t2, 0(t0)				/* 向t0寄存器保存的地址中 写入t2寄存器中存储的数据 */

/* 引脚PIN小于等于7时 */
GPIO_PIN_L:
/* 算出GPIOx相对于GPIOA的偏移地址 */
	mv t0, a0					/* t0=a0=端口号 */
	li t1, 0x400				/* t1=各端口基地址差值(0x400)*/
	mul t0, t0, t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
	/* 就算出GPIOx的地址给 ->t0  */
	li t1, GPIOA_CFGLR			/* 加载GPIO的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/

/* 判断GPIO输出输出模式 */
	beqz a2, gpio_input_L		/* 函数第二个参数a2=0，则跳转gpio_input_L */
	li t4,1						/* t4=1 */
	beq a2,t4, gpio_output_L	/* 函数第二个参数a2=1，则跳转gpio_output_L */
	li a2, ERROR
	j exit

/* 配置GPIO引脚为输出模式 */
gpio_output_L:
/* 配置GPIO引脚为输出模式 */
	li t1, 4					/* t1=4 */
	mul t1,t1,a1				/* t1= 4*(a1=引脚号) */
	li t2, GPIO_PINS_0			/* PTA_0为0x00000002输出  */
	sll t2,t2,t1				/* t2<<t1位 */
	sw t2, 0(t0)				/* 向t0寄存器保存的地址中 写入t2寄存器中存储的数据 */
/* 判断GPIO输出电平状态 */
	beqz a3, ledOFF				/* 将函数第3个传参给a3，如果a3为0则跳转ledOFF */
	li t3, LEDON				/* 给t3寄存器赋值0x01 */
	beq a3, t3, ledON			/* 比较a3和t3是否相等，相等则跳转置ledON */
	li a3, ERROR
	j exit

/* 配置GPIO引脚为输入模式 */
gpio_input_L:
/* 配置GPIO引脚为输出模式 */
	li t1, 4					/* t1=4 */
	mul t1,t1,a1				/* t1= 4*(a1=引脚号) */
	li t2, 0x00000000			/* PTA_0为0x00000002输出  */
	sll t2,t2,t1				/* t2<<t1位 */
	sw t2, 0(t0)				/* 向t0寄存器保存的地址中 写入t2寄存器中存储的数据 */
/* 引脚清零为低电平 */
ledON:
/* 算出GPIOx的地址 */
	mv t0, a0					/* t0=t4=端口号 */
	li t1, 0x400				/* t1=各端口基地址差值(0x400)*/
	mul t0, t0, t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
/* 就算出GPIOx的地址给 ->t0  */
	li t1, GPIOA_CFGLR			/* 加载GPIO的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/
/* 对BCR寄存器进行引脚置位 */
	mv t1,a1					/* t1=a1=引脚号 */
	li t2, 1					/* t2=1 */
	sll t2,t2,t1				/* 将 t2=1左移t1=t5=引脚号位->t2*/
	sw t2, 20(t0)				/* 将BCR寄存器置1清零，使IO引脚输出为低电平  */
	j exit
/* 引脚清零为高电平 */
ledOFF:
/* 算出GPIOx的地址 */
	mv t0, a0					/* t0=t4=端口号 */
	li t1, 0x400				/* t1=各端口基地址差值(0x400)*/
	mul t0, t0, t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
/* 就算出GPIOx的地址给 ->t0  */
	li t1, GPIOA_CFGLR			/* 加载GPIO的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/
/* 对BSHR寄存器进行引脚置位 */
	mv t1,a1					/* t1=a1=引脚号 */
	li t2, 1					/* t2=1 */
	sll t2,t2,t1				/* 将 t2=1左移t1=t5=引脚号位->t2*/
	sw t2, 16(t0)				/* 将BCR寄存器置1清零，使IO引脚输出为低电平  */
	j exit
/* 退出并释放栈空间 */
exit:
	lw ra, 12(sp)               /* 恢复返回地址 */
    addi sp, sp, 16             /* 释放栈空间 */
    ret							/* 返回 */

/*=====================================================================
//函数名称：gpio_set
//函数返回：无
// 参数说明：r0:(端口号|(引脚号)),例:(PTB_NUM|(5u))表示B口5脚,头文件中有宏定义
//           r1:希望设置的端口引脚状态（0=低电平，1=高电平）
//功能概要：当指定引脚被定义为GPIO功能且为输出时，本函数设定引脚状态
// 备    注：端口x的每个引脚控制寄存器PORTx_PCRn的地址=PORT_PCR_BASE+x*0x1000+n*4
//           其中:x=0~4，对应A~E;n=0~31
//=====================================================================*/
.type gpio_set function         /*声明gpio_set为函数类型 */
.global gpio_set                /*将gpio_set定义成全局函数，便于芯片初始化之后调用*/
gpio_set:
/* 通过调整栈指针分配出出栈空间用于存放局部变量和存放调用函数返回地址，
      主函数中栈空间分出16字节，   ra为返回地址寄存器，占用4个字节，将ra
      中的返回地址放入sp指针地址偏移16个字节的位置*/
	addi sp, sp, -16			/* 分配栈空间*/
	sw ra, 12(sp)				/* 存储返回地址 */

	mv a2,a1					/* 将函数第二个参数赋值给a2 */
	/* 计算出GPIO端口号和引脚号 */
	srli t4,a0,0x8				/* t4=a0=端口号 */
	andi t5,a0,255				/* a2=a0=引脚号 */
	mv a0,t4					/* a0=端口号 */
	mv a1,t5					/* a1=引脚号 */

	/* 判断GPIO引脚是否大于8 */
	li a4, 0x08					/* a4=0x08 */
	bgeu t5,a4,GPIO_SET_PIN_H	/* a1>=a4时跳转 */
	j GPIO_SET_PIN_L
/* 引脚PIN大于7时 */
GPIO_SET_PIN_H:
	/* 算出GPIOx相对于GPIOA的偏移地址 */
	mv t0,a0					/* t0=a0=端口号 */
	li t1,0x400					/* t1=各端口基地址差值(0x400)*/
	mul t0,t0,t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
	/* 就算出GPIOx的地址给 ->t0  */
	li t1,GPIOA_CFGHR			/* 加载GPIOA的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/
/* 配置GPIO引脚为输出模式 */
/*	li t1, 4					/* t1=4 */
/*	li t3, 8					/* t3=8 */
/*	sub t3,a1,t3				/* t3=((a1=引脚号)- 8)*/
/*	mul t1,t1,t3				/* t1= 4*(t3=引脚号) */
/*	li t2, GPIO_PINS_0			/* PTA_0为0x00000002输出  */
/*	sll t2,t2,t1				/* t2<<t1位 */
/*	sw t2, 0(t0)				/* 向t0寄存器保存的地址中 写入t2寄存器中存储的数据 */
/* 判断GPIO输出电平状态 */
	beqz a2, SET_ledOFF				/* 将函数第2个传参给a3，如果a2为0则跳转SET_ledOFF */
	li t3, LEDON				/* 给t3寄存器赋值0x01 */
	beq a2, t3, SET_ledON			/* 比较a2和t3是否相等，相等则跳转置SET_ledON */
	li a2, ERROR
	j SET_exit
/* 引脚PIN小于等于7时 */
GPIO_SET_PIN_L:
/* 算出GPIOx相对于GPIOA的偏移地址 */
	mv t0, a0					/* t0=t4=端口号 */
	li t1, 0x400				/* t1=各端口基地址差值(0x400)*/
	mul t0, t0, t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
	/* 就算出GPIOx的地址给 ->t0  */
	li t1, GPIOA_CFGLR			/* 加载GPIO的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/
/* 配置GPIO引脚为输出模式 */
/*	li t1, 4					/* t1=4 */
/*	mul t1,t1,a1				/* t1= 4*(a1=引脚号) */
/*	li t2, GPIO_PINS_0			/* PTA_0为0x00000002输出  */
/*	sll t2,t2,t1				/* t2<<t1位 */
/*	sw t2, 0(t0)				/* 向t0寄存器保存的地址中 写入t2寄存器中存储的数据 */
/* 判断GPIO输出电平状态 */
	beqz a2, SET_ledOFF				/* 将函数第2个传参给a2，如果a2为0则跳转ledOFF */
	li t3, LEDON				/* 给t3寄存器赋值0x01 */
	beq a2, t3, SET_ledON			/* 比较a2和t3是否相等，相等则跳转置ledON */
	li a2, ERROR
	j SET_exit

SET_ledON:
/* 算出GPIOx的基地址 */
	mv t0, a0					/* t0=t4=端口号 */
	li t1, 0x400				/* t1=各端口基地址差值(0x400)*/
	mul t0, t0, t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
/* 就算出GPIOx的地址给 ->t0  */
	li t1, GPIOA_CFGLR			/* 加载GPIO的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/
/* 对BCR寄存器进行引脚置位 */
	mv t1,a1					/* t1=a1=引脚号 */
	li t2, 1					/* t2=1 */
	sll t2,t2,t1				/* 将 t2=1左移t1=a1=引脚号位->t2*/
	sw t2, 20(t0)				/* 将BCR寄存器置1清零，使IO引脚输出为低电平  */
	j SET_exit
/* 引脚清零为高电平 */
SET_ledOFF:
/* 算出GPIOx的基地址 */
	mv t0, a0					/* t0=t4=端口号 */
	li t1, 0x400				/* t1=各端口基地址差值(0x400)*/
	mul t0, t0, t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
/* 就算出GPIOx的地址给 ->t0  */
	li t1, GPIOA_CFGLR			/* 加载GPIO的地址 */
	add t0,t0,t1				/* t0=GPIOx端口的地址*/
/* 对BSHR寄存器进行引脚置位 */
	mv t1,a1					/* t1=a1=引脚号 */
	li t2, 1					/* t2=1 */
	sll t2,t2,t1				/* 将 t2=1左移t1=a1=引脚号位->t2*/
	sh t2, 16(t0)				/* 将BSHR寄存器置1高电平，使IO引脚输出为高电平  */
	j SET_exit
/* 退出并释放栈空间 */
SET_exit:
	lw ra, 12(sp)               /* 恢复返回地址 */
    addi sp, sp, 16             /* 释放栈空间 */
    ret							/* 返回 */

/*======================================================================
// 函数名称：gpio_reverse
// 函数返回：无
// 参数说明：r0:(端口号)|(引脚号),例:(PTB_NUM|(5u))表示B口5脚,头文件中有宏定义
// 功能概要：反转指定引脚状态
//======================================================================*/
.type gpio_reverse function     /*声明gpio_reverse为函数类型  */
.global gpio_reverse            /*将gpio_reverse定义成全局函数，便于芯片初始化之后调用 */
gpio_reverse:
/* 通过调整栈指针分配出出栈空间用于存放局部变量和存放调用函数返回地址，
      主函数中栈空间分出16字节，   ra为返回地址寄存器，占用4个字节，将ra
      中的返回地址放入sp指针地址偏移16个字节的位置*/
	addi sp, sp, -16			/* 分配堆栈框架*/
	sw ra, 12(sp)				/* 将寄存器地址写到堆栈上*/

	/* 计算出GPIO端口号和引脚号 */
	srli t4,a0,0x8				/* t4=a0=端口号 */
	andi t5,a0,255				/* a2=a0=引脚号 */
	mv a0,t4					/* a0=端口号 */
	mv a1,t5					/* a1=引脚号 */

	/* 算出GPIOx相对于GPIOA的偏移地址 */
	mv t0,a0					/* t0=a0=端口号 */
	li t1,0x400					/* t1=各端口基地址差值(0x400)*/
	mul t0,t0,t1				/* t0=待操作端口与GPIO-A口的偏移地址 */
	/* 就算出GPIOx的地址给 ->t0  */
	li t1,GPIOA_BASE		/* 加载GPIOA的OUTDR寄存器地址 */
	add t1,t1,t0				/* t0=GPIOx端口的OUTDR寄存器地址*/

	lh 	t3, 12(t1)				/* t3=待操作端口GPIO->ODR寄存器中的内容 */
	li 	t4,1
	sll	t4,t4,a1				/* t4=待操作GPIO_ODR掩码（为1的位由a1决定） */
	and t4,t3,t4				/* 进行与运算，(gpio_ptr->OUTDR & (1u<<pin))*/

/* 判断t3与t4运算结果是否等于0x00 */
	beqz t4, gpio_reverse_BSHR	/* t4=0,跳转 gpio_reverse_BSHR*/
/* 当t4不等于0时进入BCR寄存器进行清零操作 *

  	/* 就算出GPIOx的BCR地址给 ->t0  */
	li t1,GPIOA_BASE		/* 加载GPIOA的BSHR寄存器地址 */
	add t1,t1,t0				/* t0=GPIOx端口的BSHR寄存器地址*/
	lh t3, 20(t1)				/* 将t0地址中的内容加载到t3 */

	li t2,1						/* t2=1 */
	sll t2,t2,a1				/* t2=1<<a1=引脚位 */
	or t2,t2,t3					/* t3或t2 */
	sw t2,20(t1)				/* t0地址中写入t2的内容 */
	j gpio_reverse_exit

gpio_reverse_BSHR:
/* 就算出GPIOx的BSHR地址给 ->t0  */
	li t1,GPIOA_BASE			/* 加载GPIOA的BSHR寄存器地址 */
	add t1,t1,t0				/* t0=GPIOx端口的BSHR寄存器地址*/
	lh t3,16(t1)				/* 将t0地址中的内容加载到t3 */

	li t2,1						/* t2=1 */
	sll t2,t2,a1				/* t2=1<<a1=引脚位 */
	or t2,t2,t3					/* t3或t2 */
	sw t2,16(t1)				/* t0地址中写入t2的内容 */
	j gpio_reverse_exit

gpio_reverse_exit:
	lw ra, 12(sp)               /* 恢复返回地址 */
    addi sp, sp, 16             /* 释放栈空间 */
    ret							/* 返回 */

/*======================================================================
// 函数名称：gpio_get
// 函数返回：r2:指定端口引脚的状态（1或0）
// 参数说明：r0:(端口号)|(引脚号),例:(PTB_NUM|(5u))表示B口5脚,头文件中有宏定义
// 功能概要：当指定端口引脚被定义为GPIO功能且为输入时，本函数获取指定引脚状态
//======================================================================*/
.type gpio_get function         /*声明gpio_get为函数类型*/
.global gpio_get                /*将gpio_get定义成全局函数，便于芯片初始化之后调用*/
gpio_get:
/* 通过调整栈指针分配出出栈空间用于存放局部变量和存放调用函数返回地址，
      主函数中栈空间分出16字节，   ra为返回地址寄存器，占用4个字节，将ra
      中的返回地址放入sp指针地址偏移16个字节的位置*/
	addi sp, sp, -16			/* 分配堆栈框架*/
	sw ra, 12(sp)				/* 将寄存器地址写到堆栈上*/

	/* 计算出GPIO端口号和引脚号 */
	srli t4,a0,0x8				/* t4=a0=端口号 */
	andi t5,a0,255				/* t5=a0=引脚号 */
	mv a2,t4					/* a2=端口号 */
	mv a3,t5					/* a3=引脚号 */

	/* 算出GPIOx相对于GPIOA的偏移地址 */
	mv t0,a2					/* t0=a0=端口号 */
	li t1,0x400					/* t1=各端口基地址差值(0x400)*/
	mul t0,t0,t1				/* t0=待操作端口相对于GPIO_A的偏移地址 */

	/* 就算出GPIOx的地址给 ->t0  */
	li t1,GPIOA_BASE			/* 加载GPIOA的OUTDR寄存器地址 */
	add t1,t1,t0				/* t0=GPIOx端口的OUTDR寄存器地址*/

	lh t3,8(t1)					/* t3=端口GPIOx->INDR寄存器的地址  */
	li t4,1						/* t4=1 */
	sll t4,t4,a3				/* t4=待操作GPIO_INDR掩码（为1的位由a3=引脚号决定） */
	and t4,t4,t3				/* 与运算设GPIO_INDR */
/* 判断与运算结果t4是否为0 */
	li t4,0
	beqz t4,gpio_get_OUTDR		/* 与运算t4=0跳转 gpio_get_OUTDR*/
/*	li a0,1						/* a0=1返回 */
	j gpio_get_exit

gpio_get_OUTDR:
	lw ra, 12(sp)               /* 恢复返回地址 */
    addi sp, sp, 16             /* 释放栈空间 */
    li  a0,1					/* 返回值1 */
    ret							/* 返回 */

gpio_get_exit:
	lw ra, 12(sp)               /* 恢复返回地址 */
    addi sp, sp, 16             /* 释放栈空间*/
    li  a0,0					/* 返回值0 */
    ret							/* 返回 */
