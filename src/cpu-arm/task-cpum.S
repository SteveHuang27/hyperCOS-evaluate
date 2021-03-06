/*-****************************************************************************/
/*-                                                                           */
/*-            Copyright (c) of hyperCOS.                                     */
/*-                                                                           */
/*-  This software is copyrighted by and is the sole property of socware.net. */
/*-  All rights, title, ownership, or other interests in the software remain  */
/*-  the property of socware.net. The source code is FREE for short-term      */
/*-  evaluation, educational or non-commercial research only. Any commercial  */
/*-  application may only be used in accordance with the corresponding license*/
/*-  agreement. Any unauthorized use, duplication, transmission, distribution,*/
/*-  or disclosure of this software is expressly forbidden.                   */
/*-                                                                           */
/*-  Knowledge of the source code may NOT be used to develop a similar product*/
/*-                                                                           */
/*-  This Copyright notice may not be removed or modified without prior       */
/*-  written consent of socware.net.                                          */
/*-                                                                           */
/*-  socware.net reserves the right to modify this software                   */
/*-  without notice.                                                          */
/*-                                                                           */
/*-  To contact socware.net:                                                  */
/*-                                                                           */
/*-             socware.help@gmail.com                                        */
/*-                                                                           */
/*-****************************************************************************/

#include "asm-off.h"
#include "cpu/asm.h"
#include "cpu/_irq.h"

	.asm_syn
	.text

	.asm_fun _task_pendsv
_task_pendsv:
	cpsid	i
	ldr	r3, =fctx_corrupted
	ldr	r3, [r3]
	cmp	r3, #0
	beq	1f
	movw	r3, #0xED88		// CPACR
	movt	r3, #0xE000
	ldr	r2, [r3]
	bic.w	r2, 0xf00000
	str	r2, [r3]
1:
	ldr     r3, = _task_pend
	ldr     r0, [r3]
	cbnz	r0, 2f
	cpsie	i
	bx	lr
2:
	mov     r2, #0
	str     r2, [r3]
	stmdb   sp!,{r0, lr}
	bl      _task_switch_status
	mov     r1, r0
	ldmia   sp!,{r0, lr}

	add     r0, r0, #task_context
	ldr     r0, [r0]

	// @param r0  next_task->context
	// @param r1  &(cur_task->context)
	.asm_fun _task_switch
_task_switch:
	mrs     r3, PSP
	add	r3, #-(reg_sz-reg_irq_sz)
	mov     r2, lr
	stmia   r3, {r2, r4-r11}
	str     r3, [r1]
	//bne	1f
	//ldr	r3, =_task_cur
	//ldr	r3, [r3]
	//ldr	r2, =cpu_fctx
	//str	r3, [r2]
	// @note FPCAR = stack_top
	//add	r2, r1, #(task_stack_sz-task_context)
	//ldr	r2, [r2]
	//add   r3, r1, #(task_stack-task_context)
	//ldr   r3, [r3]
	//add   r3, r2
	//movw	r2, #0xEF38		// FPCAR
	//movt	r2, #0xE000
	//str   r3, [r2]
//1:
_stack_check:
#if CFG_STACK_CHK
	ldr     r2, [r1, #(task_stack- task_context)]
	ldr     r3, [r2]
	ldr     r4, =0xABBA
	cmp     r3, r4
	beq     _task_load
	mov     r5, r0
	add     r0, r1, #-task_context
	ldr     r6, task_ov
	blx     r6
	mov     r0, r5
#endif

	// @param r0   next_task->context
	.asm_fun _task_load
_task_load:
	movw	r3, #0xED88		// CPACR
	movt	r3, #0xE000
	ldr	r2, [r3]
	bic.w	r2, 0xf00000
	str	r2, [r3]
	ldmia   r0!, {r2, r4-r11}
	lsls	r2, r2, #27
	ite	mi
	orrmi.w	lr, lr, #16
	bicpl.w	lr, lr, #16
	msr	PSP, r0
	cpsie	i
	bx	lr

	.global task_ov
task_ov:
	.word   _stackov
