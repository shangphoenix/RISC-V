/*=====================================================================
//�ļ����ƣ�main.s
//���ܸ�Ҫ����ɫ�ƵĶ���Ϻ������
//��д�ߣ����ݴ�ѧ 2006405021 ����
//�汾���£�20220502
//=====================================================================*/

.include "includes.inc"


/*��1�����ݶζ���  */
/* �������ݴ洢data�ο�ʼ��ʵ�����ݴ洢��RAM�� */
.section .data
data_format:                         /*�ַ���,\0Ϊ�ַ���������־*/
    .ascii "%d\n\0"                  /*printfʹ�õ����ݸ�ʽ���Ʒ� */
light_show:
    .ascii "��˸����mLightCount=\0"  /*��˸������ʾ*/
light_show0:
	.ascii "LIGHT_ALL:OFF--\n\0"           /*������ȫ��״̬��ʾ*/
light_show1:
    .ascii "LIGHT_RED&GREEN:ON--\n\0"      /*��ƺ��̵���״̬��ʾ   */
light_show2:
    .ascii "LIGHT_GREEN&BLUE:ON--\n\0"     /*�̵ƺ����Ƶ���״̬��ʾ*/
light_show3:
    .ascii "LIGHT_BLUE&RED:ON--\n\0"     /*���ƺͺ�Ƶ���״̬��ʾ*/
light_show4:
    .ascii "LIGHT_ALL:ON--\n\0"     /*�����ƶ���״̬��ʾ*/


.align 4                   /*.word��ʽ���ֽڶ���*/
mMainLoopCount:            /*������ѭ����������*/
    .word 0
mLightCount:               /*�Ƶ���˸����*/
    .word 0   
mFlag:                    /*���������Ƶ�״̬��־,0ȫ��1���̵�����2����������3�����ƣ�4ȫ�� */
    .byte 0

/*��2���������洢text�ο�ʼ��ʵ�ʴ���洢��Flash��*/
.section   .text
hello_information:           /*�ַ������*/
	.ascii "\n"
    .ascii "-------------------------------------------------\n"
    .ascii "�����«��ʾ��������Ե������������               \n"
    .ascii "    ��һ���ô��������ĺ�ɫ��������ܣ�̫���ˣ�    \n"
    .ascii "    ��ֻ�����ﳤ����һ�������ǣ����¿�ͷ��,         \n"
    .ascii "    ���˵�һ���������ȥ�������ջ�               \n"
    .ascii "-------------------------------------------------\n\0"

.type main function    /*����mainΪ�������� */
.global main           /*��main�����ȫ�ֺ���������оƬ��ʼ��֮�����*/
.align 2               /*ָ������ݲ���2�ֽڶ��룬����Thumbָ�*/

/* -------------------------------------------------------------------- */
/*��������һ������¿�����Ϊ����Ӵ˿�ʼ���� */
main:
/*��3��======�������֣���ͷ����ѭ��ǰ�ĳ�ʼ������====================== */
/* ͨ������ջָ��������ջ�ռ����ڴ�žֲ������͵��ú������ص�ַ��
      ��������ջ�ռ�ֳ�44�ֽڣ�   raΪ���ص�ַ�Ĵ�����ռ��4���ֽڣ�
      ��ra�еķ��ص�ַ����spָ���ַƫ��44���ֽڵ�λ��*/
    ADDI sp,sp,-48                	/* ����ջ֡ */
    SW ra,44(sp)                	/* �洢�Żص�ַ */
/* ��3.1������main����ʹ�õľֲ����� */

/* ��3.2�������䡿�����ж� */
	LI t0, 0x8
	CSRC mstatus, t0
/* ��3.3����������ʹ�õľֲ���������ֵ */

/* ��3.4����ȫ�ֱ�������ֵ */

/* ��3.5���û�����ģ���ʼ��*/
/*  ��ʼ�����, a0��a1��a2��gpio_init����ڲ���    */
    LI a0,LIGHT_RED                /* a0=�˿ں�|���ź� */
    LI a1,GPIO_OUTPUT              /* a1=���ģʽ */
    LI a2,LIGHT_OFF                 /* a2=�ư� */
    CALL gpio_init                 /* ����gpio_init���� */
/*  ��ʼ���̵�, a0��a1��a2��gpio_init����ڲ���    */
    LI a0,LIGHT_GREEN                /* a0=�˿ں�|���ź� */
    LI a1,GPIO_OUTPUT              /* a1=���ģʽ */
    LI a2,LIGHT_OFF                 /* a2=�ư� */
    CALL gpio_init                 /* ����gpio_init���� */
/*  ��ʼ������, a0��a1��a2��gpio_init����ڲ���    */
    LI a0,LIGHT_BLUE                /* a0=�˿ں�|���ź� */
    LI a1,GPIO_OUTPUT              /* a1=���ģʽ */
    LI a2,LIGHT_OFF                 /* a2=�ư� */
    CALL gpio_init                 /* ����gpio_init���� */
/* ��ʼ������UART_User */
    LI a0,UART_User                /* ���ں� */
    LI a1,UART_User_baud           /* ������ */
    CALL uart_init                 /* ����uart��ʼ������ */
/* ��ʼ������2�ж� */
    LI a0,UART_User_IRQ
    LI a1,UART_User_baud
    CALL uart_init

/*��3.6��ʹ��ģ���ж� */
    LI a0,UART_User_IRQ
    CALL uart_enable_re_int
    
/* ��3.7�������ж� */
	LI t0, 0x8
	CSRS mstatus, t0

/*��ʾhello_information������ַ���    */
    LA a0,hello_information
    CALL printf

/*call .   //�ڴ˴�׮(.��ʾ��ǰ��ַ)����ⷢ�������Ϊ���������ˣ�*/
/*��4��======�������֣���β��======================================= */

    LA t6,mMainLoopCount             /* t6��ΪmMainLoopCount���� */
main_loop:
/*��4.1����ѭ����������mMainLoopCount+1*/
    ADDI t6,t6,1
/*��4.2��δ�ﵽ��ѭ�������趨ֵ������ѭ�� */
    LI t5,MAINLOOP_COUNT
    BLTU t6,t5,main_loop

/*��4.3���ﵽ��ѭ�������趨ֵ��ִ��������䣬���еƵ���������  */
/*[���Դ��벿��]*/
/*��4.3.1�����ѭ����������  */
    LA t6, mMainLoopCount     /*t6��mMainLoopCount�ĵ�ַ*/
    LI t5,0
    SW t5,0(t6)
/*(4.3.2)��ӡ��˸����*/
	LA a3,mLightCount          /* a3��mLightCount�ĵ�ַ*/
    LW a1,0(a3)                /* a1��a3��ַ�е����� */
    ADDI a1,a1,1               /* a1��a1+1 */
    SW a1,0(a3)                /* a3��a1 */
	/*mLightCount��mLightCount+1*/
    LA a0,light_show          /* a0��light_show3�ĵ�ַ */
    CALL printf                /* ����printf���� */
	/*��ӡ������˸����mLightCount=��*/
    LA a0,data_format          /* a0��data_format(��ʮ�����������) */
    LA a2,mLightCount          /* a2��mLightCount */
    LW a1,0(a2)                /* a1��a2 */
    CALL printf                /* ����printf����  */
    /*��ʮ����������ʽ��ӡmLightCount����ֵ*/
/*��4.3.3���жϵƵ�״̬��־mFlag���ı��״̬����־ */
    /*�жϵƵ�״̬��־ */
    LA t2,mFlag
    LW t6,0(t2)
    LI t5,0
    BNE t6,t5,main_light_1   /* �ж�mFlag�Ƿ�Ϊ0���������ת */
    /*ȫ��*/
    LI a0,LIGHT_RED
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*�غ��*/
	LI a0,LIGHT_GREEN
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*���̵�*/
    LI a0,LIGHT_BLUE
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*������*/
    LA a2,mFlag
    LI t4,1
    SW t4,0(a2)
    /*�Ƶ�״̬��־mFlag��Ϊ1*/
    LA a0,light_show0
    CALL printf
    /*��ӡ������ʾ*/
    J main_exit

main_light_1:
	LI t5,1
    BNE t6,t5,main_light_2   /* �ж�mFlag�Ƿ�Ϊ1���������ת */
	/*����*/
	LI a0,LIGHT_RED
    LI a1,LIGHT_ON
    CALL gpio_set
   /*�����*/
	LI a0,LIGHT_GREEN
    LI a1,LIGHT_ON
    CALL gpio_set
   /*���̵�*/
    LA a2,mFlag
    LI t4,2
    SW t4,0(a2)
    /*�Ƶ�״̬��־mFlag��Ϊ2*/
    LA a0,light_show1
    CALL printf
    /*��ӡ������ʾ*/
    J main_exit
main_light_2:
	LI t5,2
    BNE t6,t5,main_light_3   /* �ж�mFlag�Ƿ�Ϊ2���������ת */
	/*����*/
	LI a0,LIGHT_RED
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*�غ��*/
	LI a0,LIGHT_BLUE
    LI a1,LIGHT_ON
    CALL gpio_set
   /*������*/
    LA a2,mFlag
    LI t4,3
    SW t4,0(a2)
    /*�Ƶ�״̬��־mFlag��Ϊ3*/
    LA a0,light_show2
    CALL printf
    /*��ӡ������ʾ*/
    J main_exit
main_light_3:
	LI t5,3
    BNE t6,t5,main_light_4   /* �ж�mFlag�Ƿ�Ϊ3���������ת */
	/*����*/
	LI a0,LIGHT_RED
    LI a1,LIGHT_ON
    CALL gpio_set
   /*�����*/
	LI a0,LIGHT_GREEN
    LI a1,LIGHT_OFF
    CALL gpio_set
   /*���̵�*/
    LA a2,mFlag
    LI t4,3
    SW t4,0(a2)
    /*�Ƶ�״̬��־mFlag��Ϊ3*/
    LA a0,light_show3
    CALL printf
    /*��ӡ������ʾ*/
    J main_exit
main_light_4:
	/*ȫ��*/
	LI a0,LIGHT_BLUE
    LI a1,LIGHT_ON
    CALL gpio_set
   /*���̵�*/
    LA a2,mFlag
    LI t4,0
    SW t4,0(a2)
    /*�Ƶ�״̬��־mFlag��Ϊ0*/
    LA a0,light_show4
    CALL printf
    /*��ӡ������ʾ*/
    
main_exit:
    LI a5,0
    J main_loop                    /* ����ѭ�� */

/* �ͷ�ջ�ռ� */
    LW ra, 44(sp)               /* �ָ����ص�ַ */
    ADDI sp, sp, 48             /* �ͷ�ջ֡ */
    RET                         /* ���� */