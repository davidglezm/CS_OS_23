
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	c7e78793          	addi	a5,a5,-898 # 80005ce0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e1078793          	addi	a5,a5,-496 # 80000ebc <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	34a080e7          	jalr	842(ra) # 80002474 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a88080e7          	jalr	-1400(ra) # 80000c1a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7f6080e7          	jalr	2038(ra) # 800019b6 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	eaa080e7          	jalr	-342(ra) # 8000207a <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	212080e7          	jalr	530(ra) # 8000241e <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	aa6080e7          	jalr	-1370(ra) # 80000cce <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a90080e7          	jalr	-1392(ra) # 80000cce <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	94c080e7          	jalr	-1716(ra) # 80000c1a <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	1de080e7          	jalr	478(ra) # 800024ca <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	9d2080e7          	jalr	-1582(ra) # 80000cce <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	dc6080e7          	jalr	-570(ra) # 80002206 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	728080e7          	jalr	1832(ra) # 80000b8a <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	ea678793          	addi	a5,a5,-346 # 80021318 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	61e080e7          	jalr	1566(ra) # 80000c1a <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	574080e7          	jalr	1396(ra) # 80000cce <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	40a080e7          	jalr	1034(ra) # 80000b8a <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	3b4080e7          	jalr	948(ra) # 80000b8a <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	3dc080e7          	jalr	988(ra) # 80000bce <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	44e080e7          	jalr	1102(ra) # 80000c6e <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	978080e7          	jalr	-1672(ra) # 80002206 <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	348080e7          	jalr	840(ra) # 80000c1a <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	760080e7          	jalr	1888(ra) # 8000207a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	378080e7          	jalr	888(ra) # 80000cce <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	25c080e7          	jalr	604(ra) # 80000c1a <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2fe080e7          	jalr	766(ra) # 80000cce <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	308080e7          	jalr	776(ra) # 80000d16 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1fa080e7          	jalr	506(ra) # 80000c1a <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	29a080e7          	jalr	666(ra) # 80000cce <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	0ce080e7          	jalr	206(ra) # 80000b8a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	126080e7          	jalr	294(ra) # 80000c1a <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1c2080e7          	jalr	450(ra) # 80000cce <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1fc080e7          	jalr	508(ra) # 80000d16 <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	198080e7          	jalr	408(ra) # 80000cce <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <freepmem>:

// HW 4 - Task 1
// Function for returning total free memory 
uint64 freepmem(void){
    80000b40:	1101                	addi	sp,sp,-32
    80000b42:	ec06                	sd	ra,24(sp)
    80000b44:	e822                	sd	s0,16(sp)
    80000b46:	e426                	sd	s1,8(sp)
    80000b48:	1000                	addi	s0,sp,32
  
  int numOfPages = 0;
  struct run *ptr;

  // Acquire a lock to ensure exclusive access to kernel memory management
  acquire(&kmem.lock);
    80000b4a:	00010497          	auipc	s1,0x10
    80000b4e:	73648493          	addi	s1,s1,1846 # 80011280 <kmem>
    80000b52:	8526                	mv	a0,s1
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	0c6080e7          	jalr	198(ra) # 80000c1a <acquire>
  
  // Initialize a pointer 'r' to the head of the free memory list
  ptr = kmem.freelist;
    80000b5c:	6c9c                	ld	a5,24(s1)

  // Traverse the free memory list and count the number of pages
  while(ptr){
    80000b5e:	c785                	beqz	a5,80000b86 <freepmem+0x46>
  int numOfPages = 0;
    80000b60:	4481                	li	s1,0
    numOfPages++;
    80000b62:	2485                	addiw	s1,s1,1
    ptr = ptr->next;
    80000b64:	639c                	ld	a5,0(a5)
  while(ptr){
    80000b66:	fff5                	bnez	a5,80000b62 <freepmem+0x22>
  }
  
  // Release the lock to allow other threads to access the memory management
  release(&kmem.lock);
    80000b68:	00010517          	auipc	a0,0x10
    80000b6c:	71850513          	addi	a0,a0,1816 # 80011280 <kmem>
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	15e080e7          	jalr	350(ra) # 80000cce <release>
  // times the total number of pages availble
  int totalFreeMem = numOfPages * PGSIZE;

  // Return the total amount of free memory in bytes
  return totalFreeMem;
}
    80000b78:	00c4951b          	slliw	a0,s1,0xc
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret
  int numOfPages = 0;
    80000b86:	4481                	li	s1,0
    80000b88:	b7c5                	j	80000b68 <freepmem+0x28>

0000000080000b8a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b8a:	1141                	addi	sp,sp,-16
    80000b8c:	e422                	sd	s0,8(sp)
    80000b8e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b90:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b92:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b96:	00053823          	sd	zero,16(a0)
}
    80000b9a:	6422                	ld	s0,8(sp)
    80000b9c:	0141                	addi	sp,sp,16
    80000b9e:	8082                	ret

0000000080000ba0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba0:	411c                	lw	a5,0(a0)
    80000ba2:	e399                	bnez	a5,80000ba8 <holding+0x8>
    80000ba4:	4501                	li	a0,0
  return r;
}
    80000ba6:	8082                	ret
{
    80000ba8:	1101                	addi	sp,sp,-32
    80000baa:	ec06                	sd	ra,24(sp)
    80000bac:	e822                	sd	s0,16(sp)
    80000bae:	e426                	sd	s1,8(sp)
    80000bb0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb2:	6904                	ld	s1,16(a0)
    80000bb4:	00001097          	auipc	ra,0x1
    80000bb8:	de6080e7          	jalr	-538(ra) # 8000199a <mycpu>
    80000bbc:	40a48533          	sub	a0,s1,a0
    80000bc0:	00153513          	seqz	a0,a0
}
    80000bc4:	60e2                	ld	ra,24(sp)
    80000bc6:	6442                	ld	s0,16(sp)
    80000bc8:	64a2                	ld	s1,8(sp)
    80000bca:	6105                	addi	sp,sp,32
    80000bcc:	8082                	ret

0000000080000bce <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bd8:	100024f3          	csrr	s1,sstatus
    80000bdc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000be6:	00001097          	auipc	ra,0x1
    80000bea:	db4080e7          	jalr	-588(ra) # 8000199a <mycpu>
    80000bee:	5d3c                	lw	a5,120(a0)
    80000bf0:	cf89                	beqz	a5,80000c0a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	da8080e7          	jalr	-600(ra) # 8000199a <mycpu>
    80000bfa:	5d3c                	lw	a5,120(a0)
    80000bfc:	2785                	addiw	a5,a5,1
    80000bfe:	dd3c                	sw	a5,120(a0)
}
    80000c00:	60e2                	ld	ra,24(sp)
    80000c02:	6442                	ld	s0,16(sp)
    80000c04:	64a2                	ld	s1,8(sp)
    80000c06:	6105                	addi	sp,sp,32
    80000c08:	8082                	ret
    mycpu()->intena = old;
    80000c0a:	00001097          	auipc	ra,0x1
    80000c0e:	d90080e7          	jalr	-624(ra) # 8000199a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c12:	8085                	srli	s1,s1,0x1
    80000c14:	8885                	andi	s1,s1,1
    80000c16:	dd64                	sw	s1,124(a0)
    80000c18:	bfe9                	j	80000bf2 <push_off+0x24>

0000000080000c1a <acquire>:
{
    80000c1a:	1101                	addi	sp,sp,-32
    80000c1c:	ec06                	sd	ra,24(sp)
    80000c1e:	e822                	sd	s0,16(sp)
    80000c20:	e426                	sd	s1,8(sp)
    80000c22:	1000                	addi	s0,sp,32
    80000c24:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	fa8080e7          	jalr	-88(ra) # 80000bce <push_off>
  if(holding(lk))
    80000c2e:	8526                	mv	a0,s1
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	f70080e7          	jalr	-144(ra) # 80000ba0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c38:	4705                	li	a4,1
  if(holding(lk))
    80000c3a:	e115                	bnez	a0,80000c5e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3c:	87ba                	mv	a5,a4
    80000c3e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c42:	2781                	sext.w	a5,a5
    80000c44:	ffe5                	bnez	a5,80000c3c <acquire+0x22>
  __sync_synchronize();
    80000c46:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	d50080e7          	jalr	-688(ra) # 8000199a <mycpu>
    80000c52:	e888                	sd	a0,16(s1)
}
    80000c54:	60e2                	ld	ra,24(sp)
    80000c56:	6442                	ld	s0,16(sp)
    80000c58:	64a2                	ld	s1,8(sp)
    80000c5a:	6105                	addi	sp,sp,32
    80000c5c:	8082                	ret
    panic("acquire");
    80000c5e:	00007517          	auipc	a0,0x7
    80000c62:	41250513          	addi	a0,a0,1042 # 80008070 <digits+0x30>
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	8d4080e7          	jalr	-1836(ra) # 8000053a <panic>

0000000080000c6e <pop_off>:

void
pop_off(void)
{
    80000c6e:	1141                	addi	sp,sp,-16
    80000c70:	e406                	sd	ra,8(sp)
    80000c72:	e022                	sd	s0,0(sp)
    80000c74:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c76:	00001097          	auipc	ra,0x1
    80000c7a:	d24080e7          	jalr	-732(ra) # 8000199a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c82:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c84:	e78d                	bnez	a5,80000cae <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c86:	5d3c                	lw	a5,120(a0)
    80000c88:	02f05b63          	blez	a5,80000cbe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c8c:	37fd                	addiw	a5,a5,-1
    80000c8e:	0007871b          	sext.w	a4,a5
    80000c92:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c94:	eb09                	bnez	a4,80000ca6 <pop_off+0x38>
    80000c96:	5d7c                	lw	a5,124(a0)
    80000c98:	c799                	beqz	a5,80000ca6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c9e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ca6:	60a2                	ld	ra,8(sp)
    80000ca8:	6402                	ld	s0,0(sp)
    80000caa:	0141                	addi	sp,sp,16
    80000cac:	8082                	ret
    panic("pop_off - interruptible");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ca50513          	addi	a0,a0,970 # 80008078 <digits+0x38>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	884080e7          	jalr	-1916(ra) # 8000053a <panic>
    panic("pop_off");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3d250513          	addi	a0,a0,978 # 80008090 <digits+0x50>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	874080e7          	jalr	-1932(ra) # 8000053a <panic>

0000000080000cce <release>:
{
    80000cce:	1101                	addi	sp,sp,-32
    80000cd0:	ec06                	sd	ra,24(sp)
    80000cd2:	e822                	sd	s0,16(sp)
    80000cd4:	e426                	sd	s1,8(sp)
    80000cd6:	1000                	addi	s0,sp,32
    80000cd8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	ec6080e7          	jalr	-314(ra) # 80000ba0 <holding>
    80000ce2:	c115                	beqz	a0,80000d06 <release+0x38>
  lk->cpu = 0;
    80000ce4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ce8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cec:	0f50000f          	fence	iorw,ow
    80000cf0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	f7a080e7          	jalr	-134(ra) # 80000c6e <pop_off>
}
    80000cfc:	60e2                	ld	ra,24(sp)
    80000cfe:	6442                	ld	s0,16(sp)
    80000d00:	64a2                	ld	s1,8(sp)
    80000d02:	6105                	addi	sp,sp,32
    80000d04:	8082                	ret
    panic("release");
    80000d06:	00007517          	auipc	a0,0x7
    80000d0a:	39250513          	addi	a0,a0,914 # 80008098 <digits+0x58>
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	82c080e7          	jalr	-2004(ra) # 8000053a <panic>

0000000080000d16 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d16:	1141                	addi	sp,sp,-16
    80000d18:	e422                	sd	s0,8(sp)
    80000d1a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d1c:	ca19                	beqz	a2,80000d32 <memset+0x1c>
    80000d1e:	87aa                	mv	a5,a0
    80000d20:	1602                	slli	a2,a2,0x20
    80000d22:	9201                	srli	a2,a2,0x20
    80000d24:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d28:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d2c:	0785                	addi	a5,a5,1
    80000d2e:	fee79de3          	bne	a5,a4,80000d28 <memset+0x12>
  }
  return dst;
}
    80000d32:	6422                	ld	s0,8(sp)
    80000d34:	0141                	addi	sp,sp,16
    80000d36:	8082                	ret

0000000080000d38 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d38:	1141                	addi	sp,sp,-16
    80000d3a:	e422                	sd	s0,8(sp)
    80000d3c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d3e:	ca05                	beqz	a2,80000d6e <memcmp+0x36>
    80000d40:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d44:	1682                	slli	a3,a3,0x20
    80000d46:	9281                	srli	a3,a3,0x20
    80000d48:	0685                	addi	a3,a3,1
    80000d4a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d4c:	00054783          	lbu	a5,0(a0)
    80000d50:	0005c703          	lbu	a4,0(a1)
    80000d54:	00e79863          	bne	a5,a4,80000d64 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d58:	0505                	addi	a0,a0,1
    80000d5a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d5c:	fed518e3          	bne	a0,a3,80000d4c <memcmp+0x14>
  }

  return 0;
    80000d60:	4501                	li	a0,0
    80000d62:	a019                	j	80000d68 <memcmp+0x30>
      return *s1 - *s2;
    80000d64:	40e7853b          	subw	a0,a5,a4
}
    80000d68:	6422                	ld	s0,8(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret
  return 0;
    80000d6e:	4501                	li	a0,0
    80000d70:	bfe5                	j	80000d68 <memcmp+0x30>

0000000080000d72 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d72:	1141                	addi	sp,sp,-16
    80000d74:	e422                	sd	s0,8(sp)
    80000d76:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d78:	c205                	beqz	a2,80000d98 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d7a:	02a5e263          	bltu	a1,a0,80000d9e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d7e:	1602                	slli	a2,a2,0x20
    80000d80:	9201                	srli	a2,a2,0x20
    80000d82:	00c587b3          	add	a5,a1,a2
{
    80000d86:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d88:	0585                	addi	a1,a1,1
    80000d8a:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d8c:	fff5c683          	lbu	a3,-1(a1)
    80000d90:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d94:	fef59ae3          	bne	a1,a5,80000d88 <memmove+0x16>

  return dst;
}
    80000d98:	6422                	ld	s0,8(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret
  if(s < d && s + n > d){
    80000d9e:	02061693          	slli	a3,a2,0x20
    80000da2:	9281                	srli	a3,a3,0x20
    80000da4:	00d58733          	add	a4,a1,a3
    80000da8:	fce57be3          	bgeu	a0,a4,80000d7e <memmove+0xc>
    d += n;
    80000dac:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dae:	fff6079b          	addiw	a5,a2,-1
    80000db2:	1782                	slli	a5,a5,0x20
    80000db4:	9381                	srli	a5,a5,0x20
    80000db6:	fff7c793          	not	a5,a5
    80000dba:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dbc:	177d                	addi	a4,a4,-1
    80000dbe:	16fd                	addi	a3,a3,-1
    80000dc0:	00074603          	lbu	a2,0(a4)
    80000dc4:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dc8:	fee79ae3          	bne	a5,a4,80000dbc <memmove+0x4a>
    80000dcc:	b7f1                	j	80000d98 <memmove+0x26>

0000000080000dce <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dce:	1141                	addi	sp,sp,-16
    80000dd0:	e406                	sd	ra,8(sp)
    80000dd2:	e022                	sd	s0,0(sp)
    80000dd4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd6:	00000097          	auipc	ra,0x0
    80000dda:	f9c080e7          	jalr	-100(ra) # 80000d72 <memmove>
}
    80000dde:	60a2                	ld	ra,8(sp)
    80000de0:	6402                	ld	s0,0(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret

0000000080000de6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de6:	1141                	addi	sp,sp,-16
    80000de8:	e422                	sd	s0,8(sp)
    80000dea:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dec:	ce11                	beqz	a2,80000e08 <strncmp+0x22>
    80000dee:	00054783          	lbu	a5,0(a0)
    80000df2:	cf89                	beqz	a5,80000e0c <strncmp+0x26>
    80000df4:	0005c703          	lbu	a4,0(a1)
    80000df8:	00f71a63          	bne	a4,a5,80000e0c <strncmp+0x26>
    n--, p++, q++;
    80000dfc:	367d                	addiw	a2,a2,-1
    80000dfe:	0505                	addi	a0,a0,1
    80000e00:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e02:	f675                	bnez	a2,80000dee <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e04:	4501                	li	a0,0
    80000e06:	a809                	j	80000e18 <strncmp+0x32>
    80000e08:	4501                	li	a0,0
    80000e0a:	a039                	j	80000e18 <strncmp+0x32>
  if(n == 0)
    80000e0c:	ca09                	beqz	a2,80000e1e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e0e:	00054503          	lbu	a0,0(a0)
    80000e12:	0005c783          	lbu	a5,0(a1)
    80000e16:	9d1d                	subw	a0,a0,a5
}
    80000e18:	6422                	ld	s0,8(sp)
    80000e1a:	0141                	addi	sp,sp,16
    80000e1c:	8082                	ret
    return 0;
    80000e1e:	4501                	li	a0,0
    80000e20:	bfe5                	j	80000e18 <strncmp+0x32>

0000000080000e22 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e22:	1141                	addi	sp,sp,-16
    80000e24:	e422                	sd	s0,8(sp)
    80000e26:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e28:	872a                	mv	a4,a0
    80000e2a:	8832                	mv	a6,a2
    80000e2c:	367d                	addiw	a2,a2,-1
    80000e2e:	01005963          	blez	a6,80000e40 <strncpy+0x1e>
    80000e32:	0705                	addi	a4,a4,1
    80000e34:	0005c783          	lbu	a5,0(a1)
    80000e38:	fef70fa3          	sb	a5,-1(a4)
    80000e3c:	0585                	addi	a1,a1,1
    80000e3e:	f7f5                	bnez	a5,80000e2a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e40:	86ba                	mv	a3,a4
    80000e42:	00c05c63          	blez	a2,80000e5a <strncpy+0x38>
    *s++ = 0;
    80000e46:	0685                	addi	a3,a3,1
    80000e48:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4c:	40d707bb          	subw	a5,a4,a3
    80000e50:	37fd                	addiw	a5,a5,-1
    80000e52:	010787bb          	addw	a5,a5,a6
    80000e56:	fef048e3          	bgtz	a5,80000e46 <strncpy+0x24>
  return os;
}
    80000e5a:	6422                	ld	s0,8(sp)
    80000e5c:	0141                	addi	sp,sp,16
    80000e5e:	8082                	ret

0000000080000e60 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e60:	1141                	addi	sp,sp,-16
    80000e62:	e422                	sd	s0,8(sp)
    80000e64:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e66:	02c05363          	blez	a2,80000e8c <safestrcpy+0x2c>
    80000e6a:	fff6069b          	addiw	a3,a2,-1
    80000e6e:	1682                	slli	a3,a3,0x20
    80000e70:	9281                	srli	a3,a3,0x20
    80000e72:	96ae                	add	a3,a3,a1
    80000e74:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e76:	00d58963          	beq	a1,a3,80000e88 <safestrcpy+0x28>
    80000e7a:	0585                	addi	a1,a1,1
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff5c703          	lbu	a4,-1(a1)
    80000e82:	fee78fa3          	sb	a4,-1(a5)
    80000e86:	fb65                	bnez	a4,80000e76 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e88:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8c:	6422                	ld	s0,8(sp)
    80000e8e:	0141                	addi	sp,sp,16
    80000e90:	8082                	ret

0000000080000e92 <strlen>:

int
strlen(const char *s)
{
    80000e92:	1141                	addi	sp,sp,-16
    80000e94:	e422                	sd	s0,8(sp)
    80000e96:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e98:	00054783          	lbu	a5,0(a0)
    80000e9c:	cf91                	beqz	a5,80000eb8 <strlen+0x26>
    80000e9e:	0505                	addi	a0,a0,1
    80000ea0:	87aa                	mv	a5,a0
    80000ea2:	4685                	li	a3,1
    80000ea4:	9e89                	subw	a3,a3,a0
    80000ea6:	00f6853b          	addw	a0,a3,a5
    80000eaa:	0785                	addi	a5,a5,1
    80000eac:	fff7c703          	lbu	a4,-1(a5)
    80000eb0:	fb7d                	bnez	a4,80000ea6 <strlen+0x14>
    ;
  return n;
}
    80000eb2:	6422                	ld	s0,8(sp)
    80000eb4:	0141                	addi	sp,sp,16
    80000eb6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eb8:	4501                	li	a0,0
    80000eba:	bfe5                	j	80000eb2 <strlen+0x20>

0000000080000ebc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebc:	1141                	addi	sp,sp,-16
    80000ebe:	e406                	sd	ra,8(sp)
    80000ec0:	e022                	sd	s0,0(sp)
    80000ec2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec4:	00001097          	auipc	ra,0x1
    80000ec8:	ac6080e7          	jalr	-1338(ra) # 8000198a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ecc:	00008717          	auipc	a4,0x8
    80000ed0:	14c70713          	addi	a4,a4,332 # 80009018 <started>
  if(cpuid() == 0){
    80000ed4:	c139                	beqz	a0,80000f1a <main+0x5e>
    while(started == 0)
    80000ed6:	431c                	lw	a5,0(a4)
    80000ed8:	2781                	sext.w	a5,a5
    80000eda:	dff5                	beqz	a5,80000ed6 <main+0x1a>
      ;
    __sync_synchronize();
    80000edc:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee0:	00001097          	auipc	ra,0x1
    80000ee4:	aaa080e7          	jalr	-1366(ra) # 8000198a <cpuid>
    80000ee8:	85aa                	mv	a1,a0
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1ce50513          	addi	a0,a0,462 # 800080b8 <digits+0x78>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	692080e7          	jalr	1682(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	0d8080e7          	jalr	216(ra) # 80000fd2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f02:	00001097          	auipc	ra,0x1
    80000f06:	7c8080e7          	jalr	1992(ra) # 800026ca <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0a:	00005097          	auipc	ra,0x5
    80000f0e:	e16080e7          	jalr	-490(ra) # 80005d20 <plicinithart>
  }

  scheduler();        
    80000f12:	00001097          	auipc	ra,0x1
    80000f16:	fb6080e7          	jalr	-74(ra) # 80001ec8 <scheduler>
    consoleinit();
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	530080e7          	jalr	1328(ra) # 8000044a <consoleinit>
    printfinit();
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	842080e7          	jalr	-1982(ra) # 80000764 <printfinit>
    printf("\n");
    80000f2a:	00007517          	auipc	a0,0x7
    80000f2e:	19e50513          	addi	a0,a0,414 # 800080c8 <digits+0x88>
    80000f32:	fffff097          	auipc	ra,0xfffff
    80000f36:	652080e7          	jalr	1618(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000f3a:	00007517          	auipc	a0,0x7
    80000f3e:	16650513          	addi	a0,a0,358 # 800080a0 <digits+0x60>
    80000f42:	fffff097          	auipc	ra,0xfffff
    80000f46:	642080e7          	jalr	1602(ra) # 80000584 <printf>
    printf("\n");
    80000f4a:	00007517          	auipc	a0,0x7
    80000f4e:	17e50513          	addi	a0,a0,382 # 800080c8 <digits+0x88>
    80000f52:	fffff097          	auipc	ra,0xfffff
    80000f56:	632080e7          	jalr	1586(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f5a:	00000097          	auipc	ra,0x0
    80000f5e:	b4a080e7          	jalr	-1206(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f62:	00000097          	auipc	ra,0x0
    80000f66:	322080e7          	jalr	802(ra) # 80001284 <kvminit>
    kvminithart();   // turn on paging
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	068080e7          	jalr	104(ra) # 80000fd2 <kvminithart>
    procinit();      // process table
    80000f72:	00001097          	auipc	ra,0x1
    80000f76:	968080e7          	jalr	-1688(ra) # 800018da <procinit>
    trapinit();      // trap vectors
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	728080e7          	jalr	1832(ra) # 800026a2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	748080e7          	jalr	1864(ra) # 800026ca <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	d80080e7          	jalr	-640(ra) # 80005d0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f92:	00005097          	auipc	ra,0x5
    80000f96:	d8e080e7          	jalr	-626(ra) # 80005d20 <plicinithart>
    binit();         // buffer cache
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	f52080e7          	jalr	-174(ra) # 80002eec <binit>
    iinit();         // inode table
    80000fa2:	00002097          	auipc	ra,0x2
    80000fa6:	5e0080e7          	jalr	1504(ra) # 80003582 <iinit>
    fileinit();      // file table
    80000faa:	00003097          	auipc	ra,0x3
    80000fae:	592080e7          	jalr	1426(ra) # 8000453c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb2:	00005097          	auipc	ra,0x5
    80000fb6:	e8e080e7          	jalr	-370(ra) # 80005e40 <virtio_disk_init>
    userinit();      // first user process
    80000fba:	00001097          	auipc	ra,0x1
    80000fbe:	cd4080e7          	jalr	-812(ra) # 80001c8e <userinit>
    __sync_synchronize();
    80000fc2:	0ff0000f          	fence
    started = 1;
    80000fc6:	4785                	li	a5,1
    80000fc8:	00008717          	auipc	a4,0x8
    80000fcc:	04f72823          	sw	a5,80(a4) # 80009018 <started>
    80000fd0:	b789                	j	80000f12 <main+0x56>

0000000080000fd2 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd2:	1141                	addi	sp,sp,-16
    80000fd4:	e422                	sd	s0,8(sp)
    80000fd6:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fd8:	00008797          	auipc	a5,0x8
    80000fdc:	0487b783          	ld	a5,72(a5) # 80009020 <kernel_pagetable>
    80000fe0:	83b1                	srli	a5,a5,0xc
    80000fe2:	577d                	li	a4,-1
    80000fe4:	177e                	slli	a4,a4,0x3f
    80000fe6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fe8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fec:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff0:	6422                	ld	s0,8(sp)
    80000ff2:	0141                	addi	sp,sp,16
    80000ff4:	8082                	ret

0000000080000ff6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff6:	7139                	addi	sp,sp,-64
    80000ff8:	fc06                	sd	ra,56(sp)
    80000ffa:	f822                	sd	s0,48(sp)
    80000ffc:	f426                	sd	s1,40(sp)
    80000ffe:	f04a                	sd	s2,32(sp)
    80001000:	ec4e                	sd	s3,24(sp)
    80001002:	e852                	sd	s4,16(sp)
    80001004:	e456                	sd	s5,8(sp)
    80001006:	e05a                	sd	s6,0(sp)
    80001008:	0080                	addi	s0,sp,64
    8000100a:	84aa                	mv	s1,a0
    8000100c:	89ae                	mv	s3,a1
    8000100e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001010:	57fd                	li	a5,-1
    80001012:	83e9                	srli	a5,a5,0x1a
    80001014:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001016:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001018:	04b7f263          	bgeu	a5,a1,8000105c <walk+0x66>
    panic("walk");
    8000101c:	00007517          	auipc	a0,0x7
    80001020:	0b450513          	addi	a0,a0,180 # 800080d0 <digits+0x90>
    80001024:	fffff097          	auipc	ra,0xfffff
    80001028:	516080e7          	jalr	1302(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102c:	060a8663          	beqz	s5,80001098 <walk+0xa2>
    80001030:	00000097          	auipc	ra,0x0
    80001034:	ab0080e7          	jalr	-1360(ra) # 80000ae0 <kalloc>
    80001038:	84aa                	mv	s1,a0
    8000103a:	c529                	beqz	a0,80001084 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103c:	6605                	lui	a2,0x1
    8000103e:	4581                	li	a1,0
    80001040:	00000097          	auipc	ra,0x0
    80001044:	cd6080e7          	jalr	-810(ra) # 80000d16 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001048:	00c4d793          	srli	a5,s1,0xc
    8000104c:	07aa                	slli	a5,a5,0xa
    8000104e:	0017e793          	ori	a5,a5,1
    80001052:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001056:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    80001058:	036a0063          	beq	s4,s6,80001078 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105c:	0149d933          	srl	s2,s3,s4
    80001060:	1ff97913          	andi	s2,s2,511
    80001064:	090e                	slli	s2,s2,0x3
    80001066:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001068:	00093483          	ld	s1,0(s2)
    8000106c:	0014f793          	andi	a5,s1,1
    80001070:	dfd5                	beqz	a5,8000102c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001072:	80a9                	srli	s1,s1,0xa
    80001074:	04b2                	slli	s1,s1,0xc
    80001076:	b7c5                	j	80001056 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001078:	00c9d513          	srli	a0,s3,0xc
    8000107c:	1ff57513          	andi	a0,a0,511
    80001080:	050e                	slli	a0,a0,0x3
    80001082:	9526                	add	a0,a0,s1
}
    80001084:	70e2                	ld	ra,56(sp)
    80001086:	7442                	ld	s0,48(sp)
    80001088:	74a2                	ld	s1,40(sp)
    8000108a:	7902                	ld	s2,32(sp)
    8000108c:	69e2                	ld	s3,24(sp)
    8000108e:	6a42                	ld	s4,16(sp)
    80001090:	6aa2                	ld	s5,8(sp)
    80001092:	6b02                	ld	s6,0(sp)
    80001094:	6121                	addi	sp,sp,64
    80001096:	8082                	ret
        return 0;
    80001098:	4501                	li	a0,0
    8000109a:	b7ed                	j	80001084 <walk+0x8e>

000000008000109c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109c:	57fd                	li	a5,-1
    8000109e:	83e9                	srli	a5,a5,0x1a
    800010a0:	00b7f463          	bgeu	a5,a1,800010a8 <walkaddr+0xc>
    return 0;
    800010a4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a6:	8082                	ret
{
    800010a8:	1141                	addi	sp,sp,-16
    800010aa:	e406                	sd	ra,8(sp)
    800010ac:	e022                	sd	s0,0(sp)
    800010ae:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b0:	4601                	li	a2,0
    800010b2:	00000097          	auipc	ra,0x0
    800010b6:	f44080e7          	jalr	-188(ra) # 80000ff6 <walk>
  if(pte == 0)
    800010ba:	c105                	beqz	a0,800010da <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010bc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010be:	0117f693          	andi	a3,a5,17
    800010c2:	4745                	li	a4,17
    return 0;
    800010c4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c6:	00e68663          	beq	a3,a4,800010d2 <walkaddr+0x36>
}
    800010ca:	60a2                	ld	ra,8(sp)
    800010cc:	6402                	ld	s0,0(sp)
    800010ce:	0141                	addi	sp,sp,16
    800010d0:	8082                	ret
  pa = PTE2PA(*pte);
    800010d2:	83a9                	srli	a5,a5,0xa
    800010d4:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010d8:	bfcd                	j	800010ca <walkaddr+0x2e>
    return 0;
    800010da:	4501                	li	a0,0
    800010dc:	b7fd                	j	800010ca <walkaddr+0x2e>

00000000800010de <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010de:	715d                	addi	sp,sp,-80
    800010e0:	e486                	sd	ra,72(sp)
    800010e2:	e0a2                	sd	s0,64(sp)
    800010e4:	fc26                	sd	s1,56(sp)
    800010e6:	f84a                	sd	s2,48(sp)
    800010e8:	f44e                	sd	s3,40(sp)
    800010ea:	f052                	sd	s4,32(sp)
    800010ec:	ec56                	sd	s5,24(sp)
    800010ee:	e85a                	sd	s6,16(sp)
    800010f0:	e45e                	sd	s7,8(sp)
    800010f2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010f4:	c639                	beqz	a2,80001142 <mappages+0x64>
    800010f6:	8aaa                	mv	s5,a0
    800010f8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010fa:	777d                	lui	a4,0xfffff
    800010fc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001100:	fff58993          	addi	s3,a1,-1
    80001104:	99b2                	add	s3,s3,a2
    80001106:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000110a:	893e                	mv	s2,a5
    8000110c:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001110:	6b85                	lui	s7,0x1
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eda080e7          	jalr	-294(ra) # 80000ff6 <walk>
    80001124:	cd1d                	beqz	a0,80001162 <mappages+0x84>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	e785                	bnez	a5,80001152 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	05390063          	beq	s2,s3,8000117a <mappages+0x9c>
    a += PGSIZE;
    8000113e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001140:	bfc9                	j	80001112 <mappages+0x34>
    panic("mappages: size");
    80001142:	00007517          	auipc	a0,0x7
    80001146:	f9650513          	addi	a0,a0,-106 # 800080d8 <digits+0x98>
    8000114a:	fffff097          	auipc	ra,0xfffff
    8000114e:	3f0080e7          	jalr	1008(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001152:	00007517          	auipc	a0,0x7
    80001156:	f9650513          	addi	a0,a0,-106 # 800080e8 <digits+0xa8>
    8000115a:	fffff097          	auipc	ra,0xfffff
    8000115e:	3e0080e7          	jalr	992(ra) # 8000053a <panic>
      return -1;
    80001162:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001164:	60a6                	ld	ra,72(sp)
    80001166:	6406                	ld	s0,64(sp)
    80001168:	74e2                	ld	s1,56(sp)
    8000116a:	7942                	ld	s2,48(sp)
    8000116c:	79a2                	ld	s3,40(sp)
    8000116e:	7a02                	ld	s4,32(sp)
    80001170:	6ae2                	ld	s5,24(sp)
    80001172:	6b42                	ld	s6,16(sp)
    80001174:	6ba2                	ld	s7,8(sp)
    80001176:	6161                	addi	sp,sp,80
    80001178:	8082                	ret
  return 0;
    8000117a:	4501                	li	a0,0
    8000117c:	b7e5                	j	80001164 <mappages+0x86>

000000008000117e <kvmmap>:
{
    8000117e:	1141                	addi	sp,sp,-16
    80001180:	e406                	sd	ra,8(sp)
    80001182:	e022                	sd	s0,0(sp)
    80001184:	0800                	addi	s0,sp,16
    80001186:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001188:	86b2                	mv	a3,a2
    8000118a:	863e                	mv	a2,a5
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	f52080e7          	jalr	-174(ra) # 800010de <mappages>
    80001194:	e509                	bnez	a0,8000119e <kvmmap+0x20>
}
    80001196:	60a2                	ld	ra,8(sp)
    80001198:	6402                	ld	s0,0(sp)
    8000119a:	0141                	addi	sp,sp,16
    8000119c:	8082                	ret
    panic("kvmmap");
    8000119e:	00007517          	auipc	a0,0x7
    800011a2:	f5a50513          	addi	a0,a0,-166 # 800080f8 <digits+0xb8>
    800011a6:	fffff097          	auipc	ra,0xfffff
    800011aa:	394080e7          	jalr	916(ra) # 8000053a <panic>

00000000800011ae <kvmmake>:
{
    800011ae:	1101                	addi	sp,sp,-32
    800011b0:	ec06                	sd	ra,24(sp)
    800011b2:	e822                	sd	s0,16(sp)
    800011b4:	e426                	sd	s1,8(sp)
    800011b6:	e04a                	sd	s2,0(sp)
    800011b8:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	926080e7          	jalr	-1754(ra) # 80000ae0 <kalloc>
    800011c2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011c4:	6605                	lui	a2,0x1
    800011c6:	4581                	li	a1,0
    800011c8:	00000097          	auipc	ra,0x0
    800011cc:	b4e080e7          	jalr	-1202(ra) # 80000d16 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011d0:	4719                	li	a4,6
    800011d2:	6685                	lui	a3,0x1
    800011d4:	10000637          	lui	a2,0x10000
    800011d8:	100005b7          	lui	a1,0x10000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	fa0080e7          	jalr	-96(ra) # 8000117e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011e6:	4719                	li	a4,6
    800011e8:	6685                	lui	a3,0x1
    800011ea:	10001637          	lui	a2,0x10001
    800011ee:	100015b7          	lui	a1,0x10001
    800011f2:	8526                	mv	a0,s1
    800011f4:	00000097          	auipc	ra,0x0
    800011f8:	f8a080e7          	jalr	-118(ra) # 8000117e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011fc:	4719                	li	a4,6
    800011fe:	004006b7          	lui	a3,0x400
    80001202:	0c000637          	lui	a2,0xc000
    80001206:	0c0005b7          	lui	a1,0xc000
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	f72080e7          	jalr	-142(ra) # 8000117e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001214:	00007917          	auipc	s2,0x7
    80001218:	dec90913          	addi	s2,s2,-532 # 80008000 <etext>
    8000121c:	4729                	li	a4,10
    8000121e:	80007697          	auipc	a3,0x80007
    80001222:	de268693          	addi	a3,a3,-542 # 8000 <_entry-0x7fff8000>
    80001226:	4605                	li	a2,1
    80001228:	067e                	slli	a2,a2,0x1f
    8000122a:	85b2                	mv	a1,a2
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	f50080e7          	jalr	-176(ra) # 8000117e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001236:	4719                	li	a4,6
    80001238:	46c5                	li	a3,17
    8000123a:	06ee                	slli	a3,a3,0x1b
    8000123c:	412686b3          	sub	a3,a3,s2
    80001240:	864a                	mv	a2,s2
    80001242:	85ca                	mv	a1,s2
    80001244:	8526                	mv	a0,s1
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f38080e7          	jalr	-200(ra) # 8000117e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000124e:	4729                	li	a4,10
    80001250:	6685                	lui	a3,0x1
    80001252:	00006617          	auipc	a2,0x6
    80001256:	dae60613          	addi	a2,a2,-594 # 80007000 <_trampoline>
    8000125a:	040005b7          	lui	a1,0x4000
    8000125e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001260:	05b2                	slli	a1,a1,0xc
    80001262:	8526                	mv	a0,s1
    80001264:	00000097          	auipc	ra,0x0
    80001268:	f1a080e7          	jalr	-230(ra) # 8000117e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000126c:	8526                	mv	a0,s1
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	5d6080e7          	jalr	1494(ra) # 80001844 <proc_mapstacks>
}
    80001276:	8526                	mv	a0,s1
    80001278:	60e2                	ld	ra,24(sp)
    8000127a:	6442                	ld	s0,16(sp)
    8000127c:	64a2                	ld	s1,8(sp)
    8000127e:	6902                	ld	s2,0(sp)
    80001280:	6105                	addi	sp,sp,32
    80001282:	8082                	ret

0000000080001284 <kvminit>:
{
    80001284:	1141                	addi	sp,sp,-16
    80001286:	e406                	sd	ra,8(sp)
    80001288:	e022                	sd	s0,0(sp)
    8000128a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000128c:	00000097          	auipc	ra,0x0
    80001290:	f22080e7          	jalr	-222(ra) # 800011ae <kvmmake>
    80001294:	00008797          	auipc	a5,0x8
    80001298:	d8a7b623          	sd	a0,-628(a5) # 80009020 <kernel_pagetable>
}
    8000129c:	60a2                	ld	ra,8(sp)
    8000129e:	6402                	ld	s0,0(sp)
    800012a0:	0141                	addi	sp,sp,16
    800012a2:	8082                	ret

00000000800012a4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012a4:	715d                	addi	sp,sp,-80
    800012a6:	e486                	sd	ra,72(sp)
    800012a8:	e0a2                	sd	s0,64(sp)
    800012aa:	fc26                	sd	s1,56(sp)
    800012ac:	f84a                	sd	s2,48(sp)
    800012ae:	f44e                	sd	s3,40(sp)
    800012b0:	f052                	sd	s4,32(sp)
    800012b2:	ec56                	sd	s5,24(sp)
    800012b4:	e85a                	sd	s6,16(sp)
    800012b6:	e45e                	sd	s7,8(sp)
    800012b8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ba:	03459793          	slli	a5,a1,0x34
    800012be:	e795                	bnez	a5,800012ea <uvmunmap+0x46>
    800012c0:	8a2a                	mv	s4,a0
    800012c2:	892e                	mv	s2,a1
    800012c4:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c6:	0632                	slli	a2,a2,0xc
    800012c8:	00b609b3          	add	s3,a2,a1
      // panic("uvmunmap: walk");
      continue;
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped"); -- HW 4 - TASK 4
    if(PTE_FLAGS(*pte) == PTE_V)
    800012cc:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ce:	6a85                	lui	s5,0x1
    800012d0:	0535e263          	bltu	a1,s3,80001314 <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012d4:	60a6                	ld	ra,72(sp)
    800012d6:	6406                	ld	s0,64(sp)
    800012d8:	74e2                	ld	s1,56(sp)
    800012da:	7942                	ld	s2,48(sp)
    800012dc:	79a2                	ld	s3,40(sp)
    800012de:	7a02                	ld	s4,32(sp)
    800012e0:	6ae2                	ld	s5,24(sp)
    800012e2:	6b42                	ld	s6,16(sp)
    800012e4:	6ba2                	ld	s7,8(sp)
    800012e6:	6161                	addi	sp,sp,80
    800012e8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e1650513          	addi	a0,a0,-490 # 80008100 <digits+0xc0>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	248080e7          	jalr	584(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e1e50513          	addi	a0,a0,-482 # 80008118 <digits+0xd8>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	238080e7          	jalr	568(ra) # 8000053a <panic>
    *pte = 0;
    8000130a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	9956                	add	s2,s2,s5
    80001310:	fd3972e3          	bgeu	s2,s3,800012d4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001314:	4601                	li	a2,0
    80001316:	85ca                	mv	a1,s2
    80001318:	8552                	mv	a0,s4
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	cdc080e7          	jalr	-804(ra) # 80000ff6 <walk>
    80001322:	84aa                	mv	s1,a0
    80001324:	d56d                	beqz	a0,8000130e <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    80001326:	611c                	ld	a5,0(a0)
    80001328:	0017f713          	andi	a4,a5,1
    8000132c:	d36d                	beqz	a4,8000130e <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132e:	3ff7f713          	andi	a4,a5,1023
    80001332:	fd7704e3          	beq	a4,s7,800012fa <uvmunmap+0x56>
    if(do_free){
    80001336:	fc0b0ae3          	beqz	s6,8000130a <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    8000133a:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000133c:	00c79513          	slli	a0,a5,0xc
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	6a2080e7          	jalr	1698(ra) # 800009e2 <kfree>
    80001348:	b7c9                	j	8000130a <uvmunmap+0x66>

000000008000134a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134a:	1101                	addi	sp,sp,-32
    8000134c:	ec06                	sd	ra,24(sp)
    8000134e:	e822                	sd	s0,16(sp)
    80001350:	e426                	sd	s1,8(sp)
    80001352:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	78c080e7          	jalr	1932(ra) # 80000ae0 <kalloc>
    8000135c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135e:	c519                	beqz	a0,8000136c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001360:	6605                	lui	a2,0x1
    80001362:	4581                	li	a1,0
    80001364:	00000097          	auipc	ra,0x0
    80001368:	9b2080e7          	jalr	-1614(ra) # 80000d16 <memset>
  return pagetable;
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6105                	addi	sp,sp,32
    80001376:	8082                	ret

0000000080001378 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001378:	7179                	addi	sp,sp,-48
    8000137a:	f406                	sd	ra,40(sp)
    8000137c:	f022                	sd	s0,32(sp)
    8000137e:	ec26                	sd	s1,24(sp)
    80001380:	e84a                	sd	s2,16(sp)
    80001382:	e44e                	sd	s3,8(sp)
    80001384:	e052                	sd	s4,0(sp)
    80001386:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001388:	6785                	lui	a5,0x1
    8000138a:	04f67863          	bgeu	a2,a5,800013da <uvminit+0x62>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	89ae                	mv	s3,a1
    80001392:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	74c080e7          	jalr	1868(ra) # 80000ae0 <kalloc>
    8000139c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	974080e7          	jalr	-1676(ra) # 80000d16 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013aa:	4779                	li	a4,30
    800013ac:	86ca                	mv	a3,s2
    800013ae:	6605                	lui	a2,0x1
    800013b0:	4581                	li	a1,0
    800013b2:	8552                	mv	a0,s4
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	d2a080e7          	jalr	-726(ra) # 800010de <mappages>
  memmove(mem, src, sz);
    800013bc:	8626                	mv	a2,s1
    800013be:	85ce                	mv	a1,s3
    800013c0:	854a                	mv	a0,s2
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	9b0080e7          	jalr	-1616(ra) # 80000d72 <memmove>
}
    800013ca:	70a2                	ld	ra,40(sp)
    800013cc:	7402                	ld	s0,32(sp)
    800013ce:	64e2                	ld	s1,24(sp)
    800013d0:	6942                	ld	s2,16(sp)
    800013d2:	69a2                	ld	s3,8(sp)
    800013d4:	6a02                	ld	s4,0(sp)
    800013d6:	6145                	addi	sp,sp,48
    800013d8:	8082                	ret
    panic("inituvm: more than a page");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d5650513          	addi	a0,a0,-682 # 80008130 <digits+0xf0>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	158080e7          	jalr	344(ra) # 8000053a <panic>

00000000800013ea <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f6:	00b67d63          	bgeu	a2,a1,80001410 <uvmdealloc+0x26>
    800013fa:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fc:	6785                	lui	a5,0x1
    800013fe:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001400:	00f60733          	add	a4,a2,a5
    80001404:	76fd                	lui	a3,0xfffff
    80001406:	8f75                	and	a4,a4,a3
    80001408:	97ae                	add	a5,a5,a1
    8000140a:	8ff5                	and	a5,a5,a3
    8000140c:	00f76863          	bltu	a4,a5,8000141c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001410:	8526                	mv	a0,s1
    80001412:	60e2                	ld	ra,24(sp)
    80001414:	6442                	ld	s0,16(sp)
    80001416:	64a2                	ld	s1,8(sp)
    80001418:	6105                	addi	sp,sp,32
    8000141a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141c:	8f99                	sub	a5,a5,a4
    8000141e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001420:	4685                	li	a3,1
    80001422:	0007861b          	sext.w	a2,a5
    80001426:	85ba                	mv	a1,a4
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	e7c080e7          	jalr	-388(ra) # 800012a4 <uvmunmap>
    80001430:	b7c5                	j	80001410 <uvmdealloc+0x26>

0000000080001432 <uvmalloc>:
  if(newsz < oldsz)
    80001432:	0ab66163          	bltu	a2,a1,800014d4 <uvmalloc+0xa2>
{
    80001436:	7139                	addi	sp,sp,-64
    80001438:	fc06                	sd	ra,56(sp)
    8000143a:	f822                	sd	s0,48(sp)
    8000143c:	f426                	sd	s1,40(sp)
    8000143e:	f04a                	sd	s2,32(sp)
    80001440:	ec4e                	sd	s3,24(sp)
    80001442:	e852                	sd	s4,16(sp)
    80001444:	e456                	sd	s5,8(sp)
    80001446:	0080                	addi	s0,sp,64
    80001448:	8aaa                	mv	s5,a0
    8000144a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144c:	6785                	lui	a5,0x1
    8000144e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001450:	95be                	add	a1,a1,a5
    80001452:	77fd                	lui	a5,0xfffff
    80001454:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001458:	08c9f063          	bgeu	s3,a2,800014d8 <uvmalloc+0xa6>
    8000145c:	894e                	mv	s2,s3
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	682080e7          	jalr	1666(ra) # 80000ae0 <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	8a8080e7          	jalr	-1880(ra) # 80000d16 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001476:	4779                	li	a4,30
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c5e080e7          	jalr	-930(ra) # 800010de <mappages>
    80001488:	e905                	bnez	a0,800014b8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x2c>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f4e080e7          	jalr	-178(ra) # 800013ea <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6121                	addi	sp,sp,64
    800014b6:	8082                	ret
      kfree(mem);
    800014b8:	8526                	mv	a0,s1
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	528080e7          	jalr	1320(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c2:	864e                	mv	a2,s3
    800014c4:	85ca                	mv	a1,s2
    800014c6:	8556                	mv	a0,s5
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	f22080e7          	jalr	-222(ra) # 800013ea <uvmdealloc>
      return 0;
    800014d0:	4501                	li	a0,0
    800014d2:	bfd1                	j	800014a6 <uvmalloc+0x74>
    return oldsz;
    800014d4:	852e                	mv	a0,a1
}
    800014d6:	8082                	ret
  return newsz;
    800014d8:	8532                	mv	a0,a2
    800014da:	b7f1                	j	800014a6 <uvmalloc+0x74>

00000000800014dc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014dc:	7179                	addi	sp,sp,-48
    800014de:	f406                	sd	ra,40(sp)
    800014e0:	f022                	sd	s0,32(sp)
    800014e2:	ec26                	sd	s1,24(sp)
    800014e4:	e84a                	sd	s2,16(sp)
    800014e6:	e44e                	sd	s3,8(sp)
    800014e8:	e052                	sd	s4,0(sp)
    800014ea:	1800                	addi	s0,sp,48
    800014ec:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ee:	84aa                	mv	s1,a0
    800014f0:	6905                	lui	s2,0x1
    800014f2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f4:	4985                	li	s3,1
    800014f6:	a829                	j	80001510 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014fa:	00c79513          	slli	a0,a5,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fde080e7          	jalr	-34(ra) # 800014dc <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001510:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f7f713          	andi	a4,a5,15
    80001516:	ff3701e3          	beq	a4,s3,800014f8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8b85                	andi	a5,a5,1
    8000151c:	d7fd                	beqz	a5,8000150a <freewalk+0x2e>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c3250513          	addi	a0,a0,-974 # 80008150 <digits+0x110>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	014080e7          	jalr	20(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4b2080e7          	jalr	1202(ra) # 800009e2 <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f84080e7          	jalr	-124(ra) # 800014dc <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6785                	lui	a5,0x1
    8000156c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000156e:	95be                	add	a1,a1,a5
    80001570:	4685                	li	a3,1
    80001572:	00c5d613          	srli	a2,a1,0xc
    80001576:	4581                	li	a1,0
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	d2c080e7          	jalr	-724(ra) # 800012a4 <uvmunmap>
    80001580:	bfd9                	j	80001556 <uvmfree+0xe>

0000000080001582 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001582:	c269                	beqz	a2,80001644 <uvmcopy+0xc2>
{
    80001584:	715d                	addi	sp,sp,-80
    80001586:	e486                	sd	ra,72(sp)
    80001588:	e0a2                	sd	s0,64(sp)
    8000158a:	fc26                	sd	s1,56(sp)
    8000158c:	f84a                	sd	s2,48(sp)
    8000158e:	f44e                	sd	s3,40(sp)
    80001590:	f052                	sd	s4,32(sp)
    80001592:	ec56                	sd	s5,24(sp)
    80001594:	e85a                	sd	s6,16(sp)
    80001596:	e45e                	sd	s7,8(sp)
    80001598:	0880                	addi	s0,sp,80
    8000159a:	8aaa                	mv	s5,a0
    8000159c:	8b2e                	mv	s6,a1
    8000159e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015a0:	4481                	li	s1,0
    800015a2:	a829                	j	800015bc <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015a4:	00007517          	auipc	a0,0x7
    800015a8:	bbc50513          	addi	a0,a0,-1092 # 80008160 <digits+0x120>
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	f8e080e7          	jalr	-114(ra) # 8000053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
    800015b4:	6785                	lui	a5,0x1
    800015b6:	94be                	add	s1,s1,a5
    800015b8:	0944f463          	bgeu	s1,s4,80001640 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800015bc:	4601                	li	a2,0
    800015be:	85a6                	mv	a1,s1
    800015c0:	8556                	mv	a0,s5
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	a34080e7          	jalr	-1484(ra) # 80000ff6 <walk>
    800015ca:	dd69                	beqz	a0,800015a4 <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    800015cc:	6118                	ld	a4,0(a0)
    800015ce:	00177793          	andi	a5,a4,1
    800015d2:	d3ed                	beqz	a5,800015b4 <uvmcopy+0x32>
      // panic("uvmcopy: page not present"); -- HW 4 - TASK 4
      continue;
    pa = PTE2PA(*pte);
    800015d4:	00a75593          	srli	a1,a4,0xa
    800015d8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015dc:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	500080e7          	jalr	1280(ra) # 80000ae0 <kalloc>
    800015e8:	89aa                	mv	s3,a0
    800015ea:	c515                	beqz	a0,80001616 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ec:	6605                	lui	a2,0x1
    800015ee:	85de                	mv	a1,s7
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	782080e7          	jalr	1922(ra) # 80000d72 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015f8:	874a                	mv	a4,s2
    800015fa:	86ce                	mv	a3,s3
    800015fc:	6605                	lui	a2,0x1
    800015fe:	85a6                	mv	a1,s1
    80001600:	855a                	mv	a0,s6
    80001602:	00000097          	auipc	ra,0x0
    80001606:	adc080e7          	jalr	-1316(ra) # 800010de <mappages>
    8000160a:	d54d                	beqz	a0,800015b4 <uvmcopy+0x32>
      kfree(mem);
    8000160c:	854e                	mv	a0,s3
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	3d4080e7          	jalr	980(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001616:	4685                	li	a3,1
    80001618:	00c4d613          	srli	a2,s1,0xc
    8000161c:	4581                	li	a1,0
    8000161e:	855a                	mv	a0,s6
    80001620:	00000097          	auipc	ra,0x0
    80001624:	c84080e7          	jalr	-892(ra) # 800012a4 <uvmunmap>
  return -1;
    80001628:	557d                	li	a0,-1
}
    8000162a:	60a6                	ld	ra,72(sp)
    8000162c:	6406                	ld	s0,64(sp)
    8000162e:	74e2                	ld	s1,56(sp)
    80001630:	7942                	ld	s2,48(sp)
    80001632:	79a2                	ld	s3,40(sp)
    80001634:	7a02                	ld	s4,32(sp)
    80001636:	6ae2                	ld	s5,24(sp)
    80001638:	6b42                	ld	s6,16(sp)
    8000163a:	6ba2                	ld	s7,8(sp)
    8000163c:	6161                	addi	sp,sp,80
    8000163e:	8082                	ret
  return 0;
    80001640:	4501                	li	a0,0
    80001642:	b7e5                	j	8000162a <uvmcopy+0xa8>
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	9a4080e7          	jalr	-1628(ra) # 80000ff6 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b1650513          	addi	a0,a0,-1258 # 80008180 <digits+0x140>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ec8080e7          	jalr	-312(ra) # 8000053a <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	6c4080e7          	jalr	1732(ra) # 80000d72 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9d0080e7          	jalr	-1584(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	caa5                	beqz	a3,80001776 <copyin+0x70>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a01d                	j	80001752 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	018505b3          	add	a1,a0,s8
    80001732:	0004861b          	sext.w	a2,s1
    80001736:	412585b3          	sub	a1,a1,s2
    8000173a:	8552                	mv	a0,s4
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	636080e7          	jalr	1590(ra) # 80000d72 <memmove>

    len -= n;
    80001744:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001748:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000174a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174e:	02098263          	beqz	s3,80001772 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001752:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001756:	85ca                	mv	a1,s2
    80001758:	855a                	mv	a0,s6
    8000175a:	00000097          	auipc	ra,0x0
    8000175e:	942080e7          	jalr	-1726(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    80001762:	cd01                	beqz	a0,8000177a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001764:	418904b3          	sub	s1,s2,s8
    80001768:	94d6                	add	s1,s1,s5
    8000176a:	fc99f2e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176e:	84ce                	mv	s1,s3
    80001770:	bf7d                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001772:	4501                	li	a0,0
    80001774:	a021                	j	8000177c <copyin+0x76>
    80001776:	4501                	li	a0,0
}
    80001778:	8082                	ret
      return -1;
    8000177a:	557d                	li	a0,-1
}
    8000177c:	60a6                	ld	ra,72(sp)
    8000177e:	6406                	ld	s0,64(sp)
    80001780:	74e2                	ld	s1,56(sp)
    80001782:	7942                	ld	s2,48(sp)
    80001784:	79a2                	ld	s3,40(sp)
    80001786:	7a02                	ld	s4,32(sp)
    80001788:	6ae2                	ld	s5,24(sp)
    8000178a:	6b42                	ld	s6,16(sp)
    8000178c:	6ba2                	ld	s7,8(sp)
    8000178e:	6c02                	ld	s8,0(sp)
    80001790:	6161                	addi	sp,sp,80
    80001792:	8082                	ret

0000000080001794 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001794:	c2dd                	beqz	a3,8000183a <copyinstr+0xa6>
{
    80001796:	715d                	addi	sp,sp,-80
    80001798:	e486                	sd	ra,72(sp)
    8000179a:	e0a2                	sd	s0,64(sp)
    8000179c:	fc26                	sd	s1,56(sp)
    8000179e:	f84a                	sd	s2,48(sp)
    800017a0:	f44e                	sd	s3,40(sp)
    800017a2:	f052                	sd	s4,32(sp)
    800017a4:	ec56                	sd	s5,24(sp)
    800017a6:	e85a                	sd	s6,16(sp)
    800017a8:	e45e                	sd	s7,8(sp)
    800017aa:	0880                	addi	s0,sp,80
    800017ac:	8a2a                	mv	s4,a0
    800017ae:	8b2e                	mv	s6,a1
    800017b0:	8bb2                	mv	s7,a2
    800017b2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b6:	6985                	lui	s3,0x1
    800017b8:	a02d                	j	800017e2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ba:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017be:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c0:	37fd                	addiw	a5,a5,-1
    800017c2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	8b2080e7          	jalr	-1870(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017f4:	417906b3          	sub	a3,s2,s7
    800017f8:	96ce                	add	a3,a3,s3
    800017fa:	00d4f363          	bgeu	s1,a3,80001800 <copyinstr+0x6c>
    800017fe:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	daf9                	beqz	a3,800017dc <copyinstr+0x48>
    80001808:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180a:	41650633          	sub	a2,a0,s6
    8000180e:	fff48593          	addi	a1,s1,-1
    80001812:	95da                	add	a1,a1,s6
    while(n > 0){
    80001814:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    8000181e:	df51                	beqz	a4,800017ba <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	fed796e3          	bne	a5,a3,80001816 <copyinstr+0x82>
      dst++;
    8000182e:	8b3e                	mv	s6,a5
    80001830:	b775                	j	800017dc <copyinstr+0x48>
    80001832:	4781                	li	a5,0
    80001834:	b771                	j	800017c0 <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x32>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	37fd                	addiw	a5,a5,-1
    8000183e:	0007851b          	sext.w	a0,a5
}
    80001842:	8082                	ret

0000000080001844 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001844:	7139                	addi	sp,sp,-64
    80001846:	fc06                	sd	ra,56(sp)
    80001848:	f822                	sd	s0,48(sp)
    8000184a:	f426                	sd	s1,40(sp)
    8000184c:	f04a                	sd	s2,32(sp)
    8000184e:	ec4e                	sd	s3,24(sp)
    80001850:	e852                	sd	s4,16(sp)
    80001852:	e456                	sd	s5,8(sp)
    80001854:	e05a                	sd	s6,0(sp)
    80001856:	0080                	addi	s0,sp,64
    80001858:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185a:	00010497          	auipc	s1,0x10
    8000185e:	e7648493          	addi	s1,s1,-394 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001862:	8b26                	mv	s6,s1
    80001864:	00006a97          	auipc	s5,0x6
    80001868:	79ca8a93          	addi	s5,s5,1948 # 80008000 <etext>
    8000186c:	04000937          	lui	s2,0x4000
    80001870:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001872:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001874:	00016a17          	auipc	s4,0x16
    80001878:	85ca0a13          	addi	s4,s4,-1956 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000187c:	fffff097          	auipc	ra,0xfffff
    80001880:	264080e7          	jalr	612(ra) # 80000ae0 <kalloc>
    80001884:	862a                	mv	a2,a0
    if(pa == 0)
    80001886:	c131                	beqz	a0,800018ca <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001888:	416485b3          	sub	a1,s1,s6
    8000188c:	858d                	srai	a1,a1,0x3
    8000188e:	000ab783          	ld	a5,0(s5)
    80001892:	02f585b3          	mul	a1,a1,a5
    80001896:	2585                	addiw	a1,a1,1
    80001898:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189c:	4719                	li	a4,6
    8000189e:	6685                	lui	a3,0x1
    800018a0:	40b905b3          	sub	a1,s2,a1
    800018a4:	854e                	mv	a0,s3
    800018a6:	00000097          	auipc	ra,0x0
    800018aa:	8d8080e7          	jalr	-1832(ra) # 8000117e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ae:	16848493          	addi	s1,s1,360
    800018b2:	fd4495e3          	bne	s1,s4,8000187c <proc_mapstacks+0x38>
  }
}
    800018b6:	70e2                	ld	ra,56(sp)
    800018b8:	7442                	ld	s0,48(sp)
    800018ba:	74a2                	ld	s1,40(sp)
    800018bc:	7902                	ld	s2,32(sp)
    800018be:	69e2                	ld	s3,24(sp)
    800018c0:	6a42                	ld	s4,16(sp)
    800018c2:	6aa2                	ld	s5,8(sp)
    800018c4:	6b02                	ld	s6,0(sp)
    800018c6:	6121                	addi	sp,sp,64
    800018c8:	8082                	ret
      panic("kalloc");
    800018ca:	00007517          	auipc	a0,0x7
    800018ce:	8c650513          	addi	a0,a0,-1850 # 80008190 <digits+0x150>
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	c68080e7          	jalr	-920(ra) # 8000053a <panic>

00000000800018da <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018da:	7139                	addi	sp,sp,-64
    800018dc:	fc06                	sd	ra,56(sp)
    800018de:	f822                	sd	s0,48(sp)
    800018e0:	f426                	sd	s1,40(sp)
    800018e2:	f04a                	sd	s2,32(sp)
    800018e4:	ec4e                	sd	s3,24(sp)
    800018e6:	e852                	sd	s4,16(sp)
    800018e8:	e456                	sd	s5,8(sp)
    800018ea:	e05a                	sd	s6,0(sp)
    800018ec:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ee:	00007597          	auipc	a1,0x7
    800018f2:	8aa58593          	addi	a1,a1,-1878 # 80008198 <digits+0x158>
    800018f6:	00010517          	auipc	a0,0x10
    800018fa:	9aa50513          	addi	a0,a0,-1622 # 800112a0 <pid_lock>
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	28c080e7          	jalr	652(ra) # 80000b8a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001906:	00007597          	auipc	a1,0x7
    8000190a:	89a58593          	addi	a1,a1,-1894 # 800081a0 <digits+0x160>
    8000190e:	00010517          	auipc	a0,0x10
    80001912:	9aa50513          	addi	a0,a0,-1622 # 800112b8 <wait_lock>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	274080e7          	jalr	628(ra) # 80000b8a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191e:	00010497          	auipc	s1,0x10
    80001922:	db248493          	addi	s1,s1,-590 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001926:	00007b17          	auipc	s6,0x7
    8000192a:	88ab0b13          	addi	s6,s6,-1910 # 800081b0 <digits+0x170>
      p->kstack = KSTACK((int) (p - proc));
    8000192e:	8aa6                	mv	s5,s1
    80001930:	00006a17          	auipc	s4,0x6
    80001934:	6d0a0a13          	addi	s4,s4,1744 # 80008000 <etext>
    80001938:	04000937          	lui	s2,0x4000
    8000193c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000193e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001940:	00015997          	auipc	s3,0x15
    80001944:	79098993          	addi	s3,s3,1936 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001948:	85da                	mv	a1,s6
    8000194a:	8526                	mv	a0,s1
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	23e080e7          	jalr	574(ra) # 80000b8a <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001954:	415487b3          	sub	a5,s1,s5
    80001958:	878d                	srai	a5,a5,0x3
    8000195a:	000a3703          	ld	a4,0(s4)
    8000195e:	02e787b3          	mul	a5,a5,a4
    80001962:	2785                	addiw	a5,a5,1
    80001964:	00d7979b          	slliw	a5,a5,0xd
    80001968:	40f907b3          	sub	a5,s2,a5
    8000196c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196e:	16848493          	addi	s1,s1,360
    80001972:	fd349be3          	bne	s1,s3,80001948 <procinit+0x6e>
  }
}
    80001976:	70e2                	ld	ra,56(sp)
    80001978:	7442                	ld	s0,48(sp)
    8000197a:	74a2                	ld	s1,40(sp)
    8000197c:	7902                	ld	s2,32(sp)
    8000197e:	69e2                	ld	s3,24(sp)
    80001980:	6a42                	ld	s4,16(sp)
    80001982:	6aa2                	ld	s5,8(sp)
    80001984:	6b02                	ld	s6,0(sp)
    80001986:	6121                	addi	sp,sp,64
    80001988:	8082                	ret

000000008000198a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001990:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001992:	2501                	sext.w	a0,a0
    80001994:	6422                	ld	s0,8(sp)
    80001996:	0141                	addi	sp,sp,16
    80001998:	8082                	ret

000000008000199a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
    800019a0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a2:	2781                	sext.w	a5,a5
    800019a4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a6:	00010517          	auipc	a0,0x10
    800019aa:	92a50513          	addi	a0,a0,-1750 # 800112d0 <cpus>
    800019ae:	953e                	add	a0,a0,a5
    800019b0:	6422                	ld	s0,8(sp)
    800019b2:	0141                	addi	sp,sp,16
    800019b4:	8082                	ret

00000000800019b6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b6:	1101                	addi	sp,sp,-32
    800019b8:	ec06                	sd	ra,24(sp)
    800019ba:	e822                	sd	s0,16(sp)
    800019bc:	e426                	sd	s1,8(sp)
    800019be:	1000                	addi	s0,sp,32
  push_off();
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	20e080e7          	jalr	526(ra) # 80000bce <push_off>
    800019c8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ca:	2781                	sext.w	a5,a5
    800019cc:	079e                	slli	a5,a5,0x7
    800019ce:	00010717          	auipc	a4,0x10
    800019d2:	8d270713          	addi	a4,a4,-1838 # 800112a0 <pid_lock>
    800019d6:	97ba                	add	a5,a5,a4
    800019d8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	294080e7          	jalr	660(ra) # 80000c6e <pop_off>
  return p;
}
    800019e2:	8526                	mv	a0,s1
    800019e4:	60e2                	ld	ra,24(sp)
    800019e6:	6442                	ld	s0,16(sp)
    800019e8:	64a2                	ld	s1,8(sp)
    800019ea:	6105                	addi	sp,sp,32
    800019ec:	8082                	ret

00000000800019ee <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ee:	1141                	addi	sp,sp,-16
    800019f0:	e406                	sd	ra,8(sp)
    800019f2:	e022                	sd	s0,0(sp)
    800019f4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	fc0080e7          	jalr	-64(ra) # 800019b6 <myproc>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	2d0080e7          	jalr	720(ra) # 80000cce <release>

  if (first) {
    80001a06:	00007797          	auipc	a5,0x7
    80001a0a:	e4a7a783          	lw	a5,-438(a5) # 80008850 <first.1>
    80001a0e:	eb89                	bnez	a5,80001a20 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a10:	00001097          	auipc	ra,0x1
    80001a14:	cd2080e7          	jalr	-814(ra) # 800026e2 <usertrapret>
}
    80001a18:	60a2                	ld	ra,8(sp)
    80001a1a:	6402                	ld	s0,0(sp)
    80001a1c:	0141                	addi	sp,sp,16
    80001a1e:	8082                	ret
    first = 0;
    80001a20:	00007797          	auipc	a5,0x7
    80001a24:	e207a823          	sw	zero,-464(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a28:	4505                	li	a0,1
    80001a2a:	00002097          	auipc	ra,0x2
    80001a2e:	ad8080e7          	jalr	-1320(ra) # 80003502 <fsinit>
    80001a32:	bff9                	j	80001a10 <forkret+0x22>

0000000080001a34 <allocpid>:
allocpid() {
    80001a34:	1101                	addi	sp,sp,-32
    80001a36:	ec06                	sd	ra,24(sp)
    80001a38:	e822                	sd	s0,16(sp)
    80001a3a:	e426                	sd	s1,8(sp)
    80001a3c:	e04a                	sd	s2,0(sp)
    80001a3e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a40:	00010917          	auipc	s2,0x10
    80001a44:	86090913          	addi	s2,s2,-1952 # 800112a0 <pid_lock>
    80001a48:	854a                	mv	a0,s2
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	1d0080e7          	jalr	464(ra) # 80000c1a <acquire>
  pid = nextpid;
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	e0278793          	addi	a5,a5,-510 # 80008854 <nextpid>
    80001a5a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5c:	0014871b          	addiw	a4,s1,1
    80001a60:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a62:	854a                	mv	a0,s2
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	26a080e7          	jalr	618(ra) # 80000cce <release>
}
    80001a6c:	8526                	mv	a0,s1
    80001a6e:	60e2                	ld	ra,24(sp)
    80001a70:	6442                	ld	s0,16(sp)
    80001a72:	64a2                	ld	s1,8(sp)
    80001a74:	6902                	ld	s2,0(sp)
    80001a76:	6105                	addi	sp,sp,32
    80001a78:	8082                	ret

0000000080001a7a <proc_pagetable>:
{
    80001a7a:	1101                	addi	sp,sp,-32
    80001a7c:	ec06                	sd	ra,24(sp)
    80001a7e:	e822                	sd	s0,16(sp)
    80001a80:	e426                	sd	s1,8(sp)
    80001a82:	e04a                	sd	s2,0(sp)
    80001a84:	1000                	addi	s0,sp,32
    80001a86:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a88:	00000097          	auipc	ra,0x0
    80001a8c:	8c2080e7          	jalr	-1854(ra) # 8000134a <uvmcreate>
    80001a90:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a92:	c121                	beqz	a0,80001ad2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a94:	4729                	li	a4,10
    80001a96:	00005697          	auipc	a3,0x5
    80001a9a:	56a68693          	addi	a3,a3,1386 # 80007000 <_trampoline>
    80001a9e:	6605                	lui	a2,0x1
    80001aa0:	040005b7          	lui	a1,0x4000
    80001aa4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aa6:	05b2                	slli	a1,a1,0xc
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	636080e7          	jalr	1590(ra) # 800010de <mappages>
    80001ab0:	02054863          	bltz	a0,80001ae0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab4:	4719                	li	a4,6
    80001ab6:	05893683          	ld	a3,88(s2)
    80001aba:	6605                	lui	a2,0x1
    80001abc:	020005b7          	lui	a1,0x2000
    80001ac0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ac2:	05b6                	slli	a1,a1,0xd
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	618080e7          	jalr	1560(ra) # 800010de <mappages>
    80001ace:	02054163          	bltz	a0,80001af0 <proc_pagetable+0x76>
}
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	60e2                	ld	ra,24(sp)
    80001ad6:	6442                	ld	s0,16(sp)
    80001ad8:	64a2                	ld	s1,8(sp)
    80001ada:	6902                	ld	s2,0(sp)
    80001adc:	6105                	addi	sp,sp,32
    80001ade:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae0:	4581                	li	a1,0
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	00000097          	auipc	ra,0x0
    80001ae8:	a64080e7          	jalr	-1436(ra) # 80001548 <uvmfree>
    return 0;
    80001aec:	4481                	li	s1,0
    80001aee:	b7d5                	j	80001ad2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af0:	4681                	li	a3,0
    80001af2:	4605                	li	a2,1
    80001af4:	040005b7          	lui	a1,0x4000
    80001af8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001afa:	05b2                	slli	a1,a1,0xc
    80001afc:	8526                	mv	a0,s1
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	7a6080e7          	jalr	1958(ra) # 800012a4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b06:	4581                	li	a1,0
    80001b08:	8526                	mv	a0,s1
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	a3e080e7          	jalr	-1474(ra) # 80001548 <uvmfree>
    return 0;
    80001b12:	4481                	li	s1,0
    80001b14:	bf7d                	j	80001ad2 <proc_pagetable+0x58>

0000000080001b16 <proc_freepagetable>:
{
    80001b16:	1101                	addi	sp,sp,-32
    80001b18:	ec06                	sd	ra,24(sp)
    80001b1a:	e822                	sd	s0,16(sp)
    80001b1c:	e426                	sd	s1,8(sp)
    80001b1e:	e04a                	sd	s2,0(sp)
    80001b20:	1000                	addi	s0,sp,32
    80001b22:	84aa                	mv	s1,a0
    80001b24:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b26:	4681                	li	a3,0
    80001b28:	4605                	li	a2,1
    80001b2a:	040005b7          	lui	a1,0x4000
    80001b2e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b30:	05b2                	slli	a1,a1,0xc
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	772080e7          	jalr	1906(ra) # 800012a4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3a:	4681                	li	a3,0
    80001b3c:	4605                	li	a2,1
    80001b3e:	020005b7          	lui	a1,0x2000
    80001b42:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b44:	05b6                	slli	a1,a1,0xd
    80001b46:	8526                	mv	a0,s1
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	75c080e7          	jalr	1884(ra) # 800012a4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b50:	85ca                	mv	a1,s2
    80001b52:	8526                	mv	a0,s1
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	9f4080e7          	jalr	-1548(ra) # 80001548 <uvmfree>
}
    80001b5c:	60e2                	ld	ra,24(sp)
    80001b5e:	6442                	ld	s0,16(sp)
    80001b60:	64a2                	ld	s1,8(sp)
    80001b62:	6902                	ld	s2,0(sp)
    80001b64:	6105                	addi	sp,sp,32
    80001b66:	8082                	ret

0000000080001b68 <freeproc>:
{
    80001b68:	1101                	addi	sp,sp,-32
    80001b6a:	ec06                	sd	ra,24(sp)
    80001b6c:	e822                	sd	s0,16(sp)
    80001b6e:	e426                	sd	s1,8(sp)
    80001b70:	1000                	addi	s0,sp,32
    80001b72:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b74:	6d28                	ld	a0,88(a0)
    80001b76:	c509                	beqz	a0,80001b80 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	e6a080e7          	jalr	-406(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b80:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b84:	68a8                	ld	a0,80(s1)
    80001b86:	c511                	beqz	a0,80001b92 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b88:	64ac                	ld	a1,72(s1)
    80001b8a:	00000097          	auipc	ra,0x0
    80001b8e:	f8c080e7          	jalr	-116(ra) # 80001b16 <proc_freepagetable>
  p->pagetable = 0;
    80001b92:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b96:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b9a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b9e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001baa:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bae:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb2:	0004ac23          	sw	zero,24(s1)
}
    80001bb6:	60e2                	ld	ra,24(sp)
    80001bb8:	6442                	ld	s0,16(sp)
    80001bba:	64a2                	ld	s1,8(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <allocproc>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	e04a                	sd	s2,0(sp)
    80001bca:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bcc:	00010497          	auipc	s1,0x10
    80001bd0:	b0448493          	addi	s1,s1,-1276 # 800116d0 <proc>
    80001bd4:	00015917          	auipc	s2,0x15
    80001bd8:	4fc90913          	addi	s2,s2,1276 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bdc:	8526                	mv	a0,s1
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	03c080e7          	jalr	60(ra) # 80000c1a <acquire>
    if(p->state == UNUSED) {
    80001be6:	4c9c                	lw	a5,24(s1)
    80001be8:	cf81                	beqz	a5,80001c00 <allocproc+0x40>
      release(&p->lock);
    80001bea:	8526                	mv	a0,s1
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	0e2080e7          	jalr	226(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf4:	16848493          	addi	s1,s1,360
    80001bf8:	ff2492e3          	bne	s1,s2,80001bdc <allocproc+0x1c>
  return 0;
    80001bfc:	4481                	li	s1,0
    80001bfe:	a889                	j	80001c50 <allocproc+0x90>
  p->pid = allocpid();
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	e34080e7          	jalr	-460(ra) # 80001a34 <allocpid>
    80001c08:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c0a:	4785                	li	a5,1
    80001c0c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	ed2080e7          	jalr	-302(ra) # 80000ae0 <kalloc>
    80001c16:	892a                	mv	s2,a0
    80001c18:	eca8                	sd	a0,88(s1)
    80001c1a:	c131                	beqz	a0,80001c5e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	e5c080e7          	jalr	-420(ra) # 80001a7a <proc_pagetable>
    80001c26:	892a                	mv	s2,a0
    80001c28:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c2a:	c531                	beqz	a0,80001c76 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c2c:	07000613          	li	a2,112
    80001c30:	4581                	li	a1,0
    80001c32:	06048513          	addi	a0,s1,96
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	0e0080e7          	jalr	224(ra) # 80000d16 <memset>
  p->context.ra = (uint64)forkret;
    80001c3e:	00000797          	auipc	a5,0x0
    80001c42:	db078793          	addi	a5,a5,-592 # 800019ee <forkret>
    80001c46:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c48:	60bc                	ld	a5,64(s1)
    80001c4a:	6705                	lui	a4,0x1
    80001c4c:	97ba                	add	a5,a5,a4
    80001c4e:	f4bc                	sd	a5,104(s1)
}
    80001c50:	8526                	mv	a0,s1
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6902                	ld	s2,0(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret
    freeproc(p);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	f08080e7          	jalr	-248(ra) # 80001b68 <freeproc>
    release(&p->lock);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	064080e7          	jalr	100(ra) # 80000cce <release>
    return 0;
    80001c72:	84ca                	mv	s1,s2
    80001c74:	bff1                	j	80001c50 <allocproc+0x90>
    freeproc(p);
    80001c76:	8526                	mv	a0,s1
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	ef0080e7          	jalr	-272(ra) # 80001b68 <freeproc>
    release(&p->lock);
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	04c080e7          	jalr	76(ra) # 80000cce <release>
    return 0;
    80001c8a:	84ca                	mv	s1,s2
    80001c8c:	b7d1                	j	80001c50 <allocproc+0x90>

0000000080001c8e <userinit>:
{
    80001c8e:	1101                	addi	sp,sp,-32
    80001c90:	ec06                	sd	ra,24(sp)
    80001c92:	e822                	sd	s0,16(sp)
    80001c94:	e426                	sd	s1,8(sp)
    80001c96:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	f28080e7          	jalr	-216(ra) # 80001bc0 <allocproc>
    80001ca0:	84aa                	mv	s1,a0
  initproc = p;
    80001ca2:	00007797          	auipc	a5,0x7
    80001ca6:	38a7b323          	sd	a0,902(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001caa:	03400613          	li	a2,52
    80001cae:	00007597          	auipc	a1,0x7
    80001cb2:	bb258593          	addi	a1,a1,-1102 # 80008860 <initcode>
    80001cb6:	6928                	ld	a0,80(a0)
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	6c0080e7          	jalr	1728(ra) # 80001378 <uvminit>
  p->sz = PGSIZE;
    80001cc0:	6785                	lui	a5,0x1
    80001cc2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cca:	6cb8                	ld	a4,88(s1)
    80001ccc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cce:	4641                	li	a2,16
    80001cd0:	00006597          	auipc	a1,0x6
    80001cd4:	4e858593          	addi	a1,a1,1256 # 800081b8 <digits+0x178>
    80001cd8:	15848513          	addi	a0,s1,344
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	184080e7          	jalr	388(ra) # 80000e60 <safestrcpy>
  p->cwd = namei("/");
    80001ce4:	00006517          	auipc	a0,0x6
    80001ce8:	4e450513          	addi	a0,a0,1252 # 800081c8 <digits+0x188>
    80001cec:	00002097          	auipc	ra,0x2
    80001cf0:	24c080e7          	jalr	588(ra) # 80003f38 <namei>
    80001cf4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf8:	478d                	li	a5,3
    80001cfa:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	fd0080e7          	jalr	-48(ra) # 80000cce <release>
}
    80001d06:	60e2                	ld	ra,24(sp)
    80001d08:	6442                	ld	s0,16(sp)
    80001d0a:	64a2                	ld	s1,8(sp)
    80001d0c:	6105                	addi	sp,sp,32
    80001d0e:	8082                	ret

0000000080001d10 <growproc>:
{
    80001d10:	1101                	addi	sp,sp,-32
    80001d12:	ec06                	sd	ra,24(sp)
    80001d14:	e822                	sd	s0,16(sp)
    80001d16:	e426                	sd	s1,8(sp)
    80001d18:	e04a                	sd	s2,0(sp)
    80001d1a:	1000                	addi	s0,sp,32
    80001d1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	c98080e7          	jalr	-872(ra) # 800019b6 <myproc>
    80001d26:	892a                	mv	s2,a0
  sz = p->sz;
    80001d28:	652c                	ld	a1,72(a0)
    80001d2a:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d2e:	00904f63          	bgtz	s1,80001d4c <growproc+0x3c>
  } else if(n < 0){
    80001d32:	0204cd63          	bltz	s1,80001d6c <growproc+0x5c>
  p->sz = sz;
    80001d36:	1782                	slli	a5,a5,0x20
    80001d38:	9381                	srli	a5,a5,0x20
    80001d3a:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d3e:	4501                	li	a0,0
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d4c:	00f4863b          	addw	a2,s1,a5
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	1582                	slli	a1,a1,0x20
    80001d56:	9181                	srli	a1,a1,0x20
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d8080e7          	jalr	1752(ra) # 80001432 <uvmalloc>
    80001d62:	0005079b          	sext.w	a5,a0
    80001d66:	fbe1                	bnez	a5,80001d36 <growproc+0x26>
      return -1;
    80001d68:	557d                	li	a0,-1
    80001d6a:	bfd9                	j	80001d40 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6c:	00f4863b          	addw	a2,s1,a5
    80001d70:	1602                	slli	a2,a2,0x20
    80001d72:	9201                	srli	a2,a2,0x20
    80001d74:	1582                	slli	a1,a1,0x20
    80001d76:	9181                	srli	a1,a1,0x20
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	670080e7          	jalr	1648(ra) # 800013ea <uvmdealloc>
    80001d82:	0005079b          	sext.w	a5,a0
    80001d86:	bf45                	j	80001d36 <growproc+0x26>

0000000080001d88 <fork>:
{
    80001d88:	7139                	addi	sp,sp,-64
    80001d8a:	fc06                	sd	ra,56(sp)
    80001d8c:	f822                	sd	s0,48(sp)
    80001d8e:	f426                	sd	s1,40(sp)
    80001d90:	f04a                	sd	s2,32(sp)
    80001d92:	ec4e                	sd	s3,24(sp)
    80001d94:	e852                	sd	s4,16(sp)
    80001d96:	e456                	sd	s5,8(sp)
    80001d98:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	c1c080e7          	jalr	-996(ra) # 800019b6 <myproc>
    80001da2:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	e1c080e7          	jalr	-484(ra) # 80001bc0 <allocproc>
    80001dac:	10050c63          	beqz	a0,80001ec4 <fork+0x13c>
    80001db0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db2:	048ab603          	ld	a2,72(s5)
    80001db6:	692c                	ld	a1,80(a0)
    80001db8:	050ab503          	ld	a0,80(s5)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	7c6080e7          	jalr	1990(ra) # 80001582 <uvmcopy>
    80001dc4:	04054863          	bltz	a0,80001e14 <fork+0x8c>
  np->sz = p->sz;
    80001dc8:	048ab783          	ld	a5,72(s5)
    80001dcc:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dd0:	058ab683          	ld	a3,88(s5)
    80001dd4:	87b6                	mv	a5,a3
    80001dd6:	058a3703          	ld	a4,88(s4)
    80001dda:	12068693          	addi	a3,a3,288
    80001dde:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de2:	6788                	ld	a0,8(a5)
    80001de4:	6b8c                	ld	a1,16(a5)
    80001de6:	6f90                	ld	a2,24(a5)
    80001de8:	01073023          	sd	a6,0(a4)
    80001dec:	e708                	sd	a0,8(a4)
    80001dee:	eb0c                	sd	a1,16(a4)
    80001df0:	ef10                	sd	a2,24(a4)
    80001df2:	02078793          	addi	a5,a5,32
    80001df6:	02070713          	addi	a4,a4,32
    80001dfa:	fed792e3          	bne	a5,a3,80001dde <fork+0x56>
  np->trapframe->a0 = 0;
    80001dfe:	058a3783          	ld	a5,88(s4)
    80001e02:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e06:	0d0a8493          	addi	s1,s5,208
    80001e0a:	0d0a0913          	addi	s2,s4,208
    80001e0e:	150a8993          	addi	s3,s5,336
    80001e12:	a00d                	j	80001e34 <fork+0xac>
    freeproc(np);
    80001e14:	8552                	mv	a0,s4
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	d52080e7          	jalr	-686(ra) # 80001b68 <freeproc>
    release(&np->lock);
    80001e1e:	8552                	mv	a0,s4
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	eae080e7          	jalr	-338(ra) # 80000cce <release>
    return -1;
    80001e28:	597d                	li	s2,-1
    80001e2a:	a059                	j	80001eb0 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e2c:	04a1                	addi	s1,s1,8
    80001e2e:	0921                	addi	s2,s2,8
    80001e30:	01348b63          	beq	s1,s3,80001e46 <fork+0xbe>
    if(p->ofile[i])
    80001e34:	6088                	ld	a0,0(s1)
    80001e36:	d97d                	beqz	a0,80001e2c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	796080e7          	jalr	1942(ra) # 800045ce <filedup>
    80001e40:	00a93023          	sd	a0,0(s2)
    80001e44:	b7e5                	j	80001e2c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e46:	150ab503          	ld	a0,336(s5)
    80001e4a:	00002097          	auipc	ra,0x2
    80001e4e:	8f4080e7          	jalr	-1804(ra) # 8000373e <idup>
    80001e52:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e56:	4641                	li	a2,16
    80001e58:	158a8593          	addi	a1,s5,344
    80001e5c:	158a0513          	addi	a0,s4,344
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	000080e7          	jalr	ra # 80000e60 <safestrcpy>
  pid = np->pid;
    80001e68:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e6c:	8552                	mv	a0,s4
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e60080e7          	jalr	-416(ra) # 80000cce <release>
  acquire(&wait_lock);
    80001e76:	0000f497          	auipc	s1,0xf
    80001e7a:	44248493          	addi	s1,s1,1090 # 800112b8 <wait_lock>
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	d9a080e7          	jalr	-614(ra) # 80000c1a <acquire>
  np->parent = p;
    80001e88:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	e40080e7          	jalr	-448(ra) # 80000cce <release>
  acquire(&np->lock);
    80001e96:	8552                	mv	a0,s4
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	d82080e7          	jalr	-638(ra) # 80000c1a <acquire>
  np->state = RUNNABLE;
    80001ea0:	478d                	li	a5,3
    80001ea2:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea6:	8552                	mv	a0,s4
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	e26080e7          	jalr	-474(ra) # 80000cce <release>
}
    80001eb0:	854a                	mv	a0,s2
    80001eb2:	70e2                	ld	ra,56(sp)
    80001eb4:	7442                	ld	s0,48(sp)
    80001eb6:	74a2                	ld	s1,40(sp)
    80001eb8:	7902                	ld	s2,32(sp)
    80001eba:	69e2                	ld	s3,24(sp)
    80001ebc:	6a42                	ld	s4,16(sp)
    80001ebe:	6aa2                	ld	s5,8(sp)
    80001ec0:	6121                	addi	sp,sp,64
    80001ec2:	8082                	ret
    return -1;
    80001ec4:	597d                	li	s2,-1
    80001ec6:	b7ed                	j	80001eb0 <fork+0x128>

0000000080001ec8 <scheduler>:
{
    80001ec8:	7139                	addi	sp,sp,-64
    80001eca:	fc06                	sd	ra,56(sp)
    80001ecc:	f822                	sd	s0,48(sp)
    80001ece:	f426                	sd	s1,40(sp)
    80001ed0:	f04a                	sd	s2,32(sp)
    80001ed2:	ec4e                	sd	s3,24(sp)
    80001ed4:	e852                	sd	s4,16(sp)
    80001ed6:	e456                	sd	s5,8(sp)
    80001ed8:	e05a                	sd	s6,0(sp)
    80001eda:	0080                	addi	s0,sp,64
    80001edc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ede:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee0:	00779a93          	slli	s5,a5,0x7
    80001ee4:	0000f717          	auipc	a4,0xf
    80001ee8:	3bc70713          	addi	a4,a4,956 # 800112a0 <pid_lock>
    80001eec:	9756                	add	a4,a4,s5
    80001eee:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef2:	0000f717          	auipc	a4,0xf
    80001ef6:	3e670713          	addi	a4,a4,998 # 800112d8 <cpus+0x8>
    80001efa:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001efc:	498d                	li	s3,3
        p->state = RUNNING;
    80001efe:	4b11                	li	s6,4
        c->proc = p;
    80001f00:	079e                	slli	a5,a5,0x7
    80001f02:	0000fa17          	auipc	s4,0xf
    80001f06:	39ea0a13          	addi	s4,s4,926 # 800112a0 <pid_lock>
    80001f0a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0c:	00015917          	auipc	s2,0x15
    80001f10:	1c490913          	addi	s2,s2,452 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f18:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f1c:	10079073          	csrw	sstatus,a5
    80001f20:	0000f497          	auipc	s1,0xf
    80001f24:	7b048493          	addi	s1,s1,1968 # 800116d0 <proc>
    80001f28:	a811                	j	80001f3c <scheduler+0x74>
      release(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	da2080e7          	jalr	-606(ra) # 80000cce <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f34:	16848493          	addi	s1,s1,360
    80001f38:	fd248ee3          	beq	s1,s2,80001f14 <scheduler+0x4c>
      acquire(&p->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	cdc080e7          	jalr	-804(ra) # 80000c1a <acquire>
      if(p->state == RUNNABLE) {
    80001f46:	4c9c                	lw	a5,24(s1)
    80001f48:	ff3791e3          	bne	a5,s3,80001f2a <scheduler+0x62>
        p->state = RUNNING;
    80001f4c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f50:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f54:	06048593          	addi	a1,s1,96
    80001f58:	8556                	mv	a0,s5
    80001f5a:	00000097          	auipc	ra,0x0
    80001f5e:	6de080e7          	jalr	1758(ra) # 80002638 <swtch>
        c->proc = 0;
    80001f62:	020a3823          	sd	zero,48(s4)
    80001f66:	b7d1                	j	80001f2a <scheduler+0x62>

0000000080001f68 <sched>:
{
    80001f68:	7179                	addi	sp,sp,-48
    80001f6a:	f406                	sd	ra,40(sp)
    80001f6c:	f022                	sd	s0,32(sp)
    80001f6e:	ec26                	sd	s1,24(sp)
    80001f70:	e84a                	sd	s2,16(sp)
    80001f72:	e44e                	sd	s3,8(sp)
    80001f74:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	a40080e7          	jalr	-1472(ra) # 800019b6 <myproc>
    80001f7e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	c20080e7          	jalr	-992(ra) # 80000ba0 <holding>
    80001f88:	c93d                	beqz	a0,80001ffe <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f8c:	2781                	sext.w	a5,a5
    80001f8e:	079e                	slli	a5,a5,0x7
    80001f90:	0000f717          	auipc	a4,0xf
    80001f94:	31070713          	addi	a4,a4,784 # 800112a0 <pid_lock>
    80001f98:	97ba                	add	a5,a5,a4
    80001f9a:	0a87a703          	lw	a4,168(a5)
    80001f9e:	4785                	li	a5,1
    80001fa0:	06f71763          	bne	a4,a5,8000200e <sched+0xa6>
  if(p->state == RUNNING)
    80001fa4:	4c98                	lw	a4,24(s1)
    80001fa6:	4791                	li	a5,4
    80001fa8:	06f70b63          	beq	a4,a5,8000201e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fb2:	efb5                	bnez	a5,8000202e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb6:	0000f917          	auipc	s2,0xf
    80001fba:	2ea90913          	addi	s2,s2,746 # 800112a0 <pid_lock>
    80001fbe:	2781                	sext.w	a5,a5
    80001fc0:	079e                	slli	a5,a5,0x7
    80001fc2:	97ca                	add	a5,a5,s2
    80001fc4:	0ac7a983          	lw	s3,172(a5)
    80001fc8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fca:	2781                	sext.w	a5,a5
    80001fcc:	079e                	slli	a5,a5,0x7
    80001fce:	0000f597          	auipc	a1,0xf
    80001fd2:	30a58593          	addi	a1,a1,778 # 800112d8 <cpus+0x8>
    80001fd6:	95be                	add	a1,a1,a5
    80001fd8:	06048513          	addi	a0,s1,96
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	65c080e7          	jalr	1628(ra) # 80002638 <swtch>
    80001fe4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe6:	2781                	sext.w	a5,a5
    80001fe8:	079e                	slli	a5,a5,0x7
    80001fea:	993e                	add	s2,s2,a5
    80001fec:	0b392623          	sw	s3,172(s2)
}
    80001ff0:	70a2                	ld	ra,40(sp)
    80001ff2:	7402                	ld	s0,32(sp)
    80001ff4:	64e2                	ld	s1,24(sp)
    80001ff6:	6942                	ld	s2,16(sp)
    80001ff8:	69a2                	ld	s3,8(sp)
    80001ffa:	6145                	addi	sp,sp,48
    80001ffc:	8082                	ret
    panic("sched p->lock");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	1d250513          	addi	a0,a0,466 # 800081d0 <digits+0x190>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	534080e7          	jalr	1332(ra) # 8000053a <panic>
    panic("sched locks");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	1d250513          	addi	a0,a0,466 # 800081e0 <digits+0x1a0>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	524080e7          	jalr	1316(ra) # 8000053a <panic>
    panic("sched running");
    8000201e:	00006517          	auipc	a0,0x6
    80002022:	1d250513          	addi	a0,a0,466 # 800081f0 <digits+0x1b0>
    80002026:	ffffe097          	auipc	ra,0xffffe
    8000202a:	514080e7          	jalr	1300(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000202e:	00006517          	auipc	a0,0x6
    80002032:	1d250513          	addi	a0,a0,466 # 80008200 <digits+0x1c0>
    80002036:	ffffe097          	auipc	ra,0xffffe
    8000203a:	504080e7          	jalr	1284(ra) # 8000053a <panic>

000000008000203e <yield>:
{
    8000203e:	1101                	addi	sp,sp,-32
    80002040:	ec06                	sd	ra,24(sp)
    80002042:	e822                	sd	s0,16(sp)
    80002044:	e426                	sd	s1,8(sp)
    80002046:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	96e080e7          	jalr	-1682(ra) # 800019b6 <myproc>
    80002050:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	bc8080e7          	jalr	-1080(ra) # 80000c1a <acquire>
  p->state = RUNNABLE;
    8000205a:	478d                	li	a5,3
    8000205c:	cc9c                	sw	a5,24(s1)
  sched();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	f0a080e7          	jalr	-246(ra) # 80001f68 <sched>
  release(&p->lock);
    80002066:	8526                	mv	a0,s1
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c66080e7          	jalr	-922(ra) # 80000cce <release>
}
    80002070:	60e2                	ld	ra,24(sp)
    80002072:	6442                	ld	s0,16(sp)
    80002074:	64a2                	ld	s1,8(sp)
    80002076:	6105                	addi	sp,sp,32
    80002078:	8082                	ret

000000008000207a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000207a:	7179                	addi	sp,sp,-48
    8000207c:	f406                	sd	ra,40(sp)
    8000207e:	f022                	sd	s0,32(sp)
    80002080:	ec26                	sd	s1,24(sp)
    80002082:	e84a                	sd	s2,16(sp)
    80002084:	e44e                	sd	s3,8(sp)
    80002086:	1800                	addi	s0,sp,48
    80002088:	89aa                	mv	s3,a0
    8000208a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	92a080e7          	jalr	-1750(ra) # 800019b6 <myproc>
    80002094:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	b84080e7          	jalr	-1148(ra) # 80000c1a <acquire>
  release(lk);
    8000209e:	854a                	mv	a0,s2
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	c2e080e7          	jalr	-978(ra) # 80000cce <release>

  // Go to sleep.
  p->chan = chan;
    800020a8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ac:	4789                	li	a5,2
    800020ae:	cc9c                	sw	a5,24(s1)

  sched();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	eb8080e7          	jalr	-328(ra) # 80001f68 <sched>

  // Tidy up.
  p->chan = 0;
    800020b8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	c10080e7          	jalr	-1008(ra) # 80000cce <release>
  acquire(lk);
    800020c6:	854a                	mv	a0,s2
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	b52080e7          	jalr	-1198(ra) # 80000c1a <acquire>
}
    800020d0:	70a2                	ld	ra,40(sp)
    800020d2:	7402                	ld	s0,32(sp)
    800020d4:	64e2                	ld	s1,24(sp)
    800020d6:	6942                	ld	s2,16(sp)
    800020d8:	69a2                	ld	s3,8(sp)
    800020da:	6145                	addi	sp,sp,48
    800020dc:	8082                	ret

00000000800020de <wait>:
{
    800020de:	715d                	addi	sp,sp,-80
    800020e0:	e486                	sd	ra,72(sp)
    800020e2:	e0a2                	sd	s0,64(sp)
    800020e4:	fc26                	sd	s1,56(sp)
    800020e6:	f84a                	sd	s2,48(sp)
    800020e8:	f44e                	sd	s3,40(sp)
    800020ea:	f052                	sd	s4,32(sp)
    800020ec:	ec56                	sd	s5,24(sp)
    800020ee:	e85a                	sd	s6,16(sp)
    800020f0:	e45e                	sd	s7,8(sp)
    800020f2:	e062                	sd	s8,0(sp)
    800020f4:	0880                	addi	s0,sp,80
    800020f6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	8be080e7          	jalr	-1858(ra) # 800019b6 <myproc>
    80002100:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002102:	0000f517          	auipc	a0,0xf
    80002106:	1b650513          	addi	a0,a0,438 # 800112b8 <wait_lock>
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	b10080e7          	jalr	-1264(ra) # 80000c1a <acquire>
    havekids = 0;
    80002112:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002114:	4a15                	li	s4,5
        havekids = 1;
    80002116:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002118:	00015997          	auipc	s3,0x15
    8000211c:	fb898993          	addi	s3,s3,-72 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002120:	0000fc17          	auipc	s8,0xf
    80002124:	198c0c13          	addi	s8,s8,408 # 800112b8 <wait_lock>
    havekids = 0;
    80002128:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000212a:	0000f497          	auipc	s1,0xf
    8000212e:	5a648493          	addi	s1,s1,1446 # 800116d0 <proc>
    80002132:	a0bd                	j	800021a0 <wait+0xc2>
          pid = np->pid;
    80002134:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002138:	000b0e63          	beqz	s6,80002154 <wait+0x76>
    8000213c:	4691                	li	a3,4
    8000213e:	02c48613          	addi	a2,s1,44
    80002142:	85da                	mv	a1,s6
    80002144:	05093503          	ld	a0,80(s2)
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	532080e7          	jalr	1330(ra) # 8000167a <copyout>
    80002150:	02054563          	bltz	a0,8000217a <wait+0x9c>
          freeproc(np);
    80002154:	8526                	mv	a0,s1
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	a12080e7          	jalr	-1518(ra) # 80001b68 <freeproc>
          release(&np->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b6e080e7          	jalr	-1170(ra) # 80000cce <release>
          release(&wait_lock);
    80002168:	0000f517          	auipc	a0,0xf
    8000216c:	15050513          	addi	a0,a0,336 # 800112b8 <wait_lock>
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b5e080e7          	jalr	-1186(ra) # 80000cce <release>
          return pid;
    80002178:	a09d                	j	800021de <wait+0x100>
            release(&np->lock);
    8000217a:	8526                	mv	a0,s1
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b52080e7          	jalr	-1198(ra) # 80000cce <release>
            release(&wait_lock);
    80002184:	0000f517          	auipc	a0,0xf
    80002188:	13450513          	addi	a0,a0,308 # 800112b8 <wait_lock>
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b42080e7          	jalr	-1214(ra) # 80000cce <release>
            return -1;
    80002194:	59fd                	li	s3,-1
    80002196:	a0a1                	j	800021de <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002198:	16848493          	addi	s1,s1,360
    8000219c:	03348463          	beq	s1,s3,800021c4 <wait+0xe6>
      if(np->parent == p){
    800021a0:	7c9c                	ld	a5,56(s1)
    800021a2:	ff279be3          	bne	a5,s2,80002198 <wait+0xba>
        acquire(&np->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a72080e7          	jalr	-1422(ra) # 80000c1a <acquire>
        if(np->state == ZOMBIE){
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	f94781e3          	beq	a5,s4,80002134 <wait+0x56>
        release(&np->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	b16080e7          	jalr	-1258(ra) # 80000cce <release>
        havekids = 1;
    800021c0:	8756                	mv	a4,s5
    800021c2:	bfd9                	j	80002198 <wait+0xba>
    if(!havekids || p->killed){
    800021c4:	c701                	beqz	a4,800021cc <wait+0xee>
    800021c6:	02892783          	lw	a5,40(s2)
    800021ca:	c79d                	beqz	a5,800021f8 <wait+0x11a>
      release(&wait_lock);
    800021cc:	0000f517          	auipc	a0,0xf
    800021d0:	0ec50513          	addi	a0,a0,236 # 800112b8 <wait_lock>
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	afa080e7          	jalr	-1286(ra) # 80000cce <release>
      return -1;
    800021dc:	59fd                	li	s3,-1
}
    800021de:	854e                	mv	a0,s3
    800021e0:	60a6                	ld	ra,72(sp)
    800021e2:	6406                	ld	s0,64(sp)
    800021e4:	74e2                	ld	s1,56(sp)
    800021e6:	7942                	ld	s2,48(sp)
    800021e8:	79a2                	ld	s3,40(sp)
    800021ea:	7a02                	ld	s4,32(sp)
    800021ec:	6ae2                	ld	s5,24(sp)
    800021ee:	6b42                	ld	s6,16(sp)
    800021f0:	6ba2                	ld	s7,8(sp)
    800021f2:	6c02                	ld	s8,0(sp)
    800021f4:	6161                	addi	sp,sp,80
    800021f6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021f8:	85e2                	mv	a1,s8
    800021fa:	854a                	mv	a0,s2
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	e7e080e7          	jalr	-386(ra) # 8000207a <sleep>
    havekids = 0;
    80002204:	b715                	j	80002128 <wait+0x4a>

0000000080002206 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002206:	7139                	addi	sp,sp,-64
    80002208:	fc06                	sd	ra,56(sp)
    8000220a:	f822                	sd	s0,48(sp)
    8000220c:	f426                	sd	s1,40(sp)
    8000220e:	f04a                	sd	s2,32(sp)
    80002210:	ec4e                	sd	s3,24(sp)
    80002212:	e852                	sd	s4,16(sp)
    80002214:	e456                	sd	s5,8(sp)
    80002216:	0080                	addi	s0,sp,64
    80002218:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000221a:	0000f497          	auipc	s1,0xf
    8000221e:	4b648493          	addi	s1,s1,1206 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002222:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002224:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002226:	00015917          	auipc	s2,0x15
    8000222a:	eaa90913          	addi	s2,s2,-342 # 800170d0 <tickslock>
    8000222e:	a811                	j	80002242 <wakeup+0x3c>
      }
      release(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a9c080e7          	jalr	-1380(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000223a:	16848493          	addi	s1,s1,360
    8000223e:	03248663          	beq	s1,s2,8000226a <wakeup+0x64>
    if(p != myproc()){
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	774080e7          	jalr	1908(ra) # 800019b6 <myproc>
    8000224a:	fea488e3          	beq	s1,a0,8000223a <wakeup+0x34>
      acquire(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	9ca080e7          	jalr	-1590(ra) # 80000c1a <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002258:	4c9c                	lw	a5,24(s1)
    8000225a:	fd379be3          	bne	a5,s3,80002230 <wakeup+0x2a>
    8000225e:	709c                	ld	a5,32(s1)
    80002260:	fd4798e3          	bne	a5,s4,80002230 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002264:	0154ac23          	sw	s5,24(s1)
    80002268:	b7e1                	j	80002230 <wakeup+0x2a>
    }
  }
}
    8000226a:	70e2                	ld	ra,56(sp)
    8000226c:	7442                	ld	s0,48(sp)
    8000226e:	74a2                	ld	s1,40(sp)
    80002270:	7902                	ld	s2,32(sp)
    80002272:	69e2                	ld	s3,24(sp)
    80002274:	6a42                	ld	s4,16(sp)
    80002276:	6aa2                	ld	s5,8(sp)
    80002278:	6121                	addi	sp,sp,64
    8000227a:	8082                	ret

000000008000227c <reparent>:
{
    8000227c:	7179                	addi	sp,sp,-48
    8000227e:	f406                	sd	ra,40(sp)
    80002280:	f022                	sd	s0,32(sp)
    80002282:	ec26                	sd	s1,24(sp)
    80002284:	e84a                	sd	s2,16(sp)
    80002286:	e44e                	sd	s3,8(sp)
    80002288:	e052                	sd	s4,0(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	44248493          	addi	s1,s1,1090 # 800116d0 <proc>
      pp->parent = initproc;
    80002296:	00007a17          	auipc	s4,0x7
    8000229a:	d92a0a13          	addi	s4,s4,-622 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000229e:	00015997          	auipc	s3,0x15
    800022a2:	e3298993          	addi	s3,s3,-462 # 800170d0 <tickslock>
    800022a6:	a029                	j	800022b0 <reparent+0x34>
    800022a8:	16848493          	addi	s1,s1,360
    800022ac:	01348d63          	beq	s1,s3,800022c6 <reparent+0x4a>
    if(pp->parent == p){
    800022b0:	7c9c                	ld	a5,56(s1)
    800022b2:	ff279be3          	bne	a5,s2,800022a8 <reparent+0x2c>
      pp->parent = initproc;
    800022b6:	000a3503          	ld	a0,0(s4)
    800022ba:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	f4a080e7          	jalr	-182(ra) # 80002206 <wakeup>
    800022c4:	b7d5                	j	800022a8 <reparent+0x2c>
}
    800022c6:	70a2                	ld	ra,40(sp)
    800022c8:	7402                	ld	s0,32(sp)
    800022ca:	64e2                	ld	s1,24(sp)
    800022cc:	6942                	ld	s2,16(sp)
    800022ce:	69a2                	ld	s3,8(sp)
    800022d0:	6a02                	ld	s4,0(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret

00000000800022d6 <exit>:
{
    800022d6:	7179                	addi	sp,sp,-48
    800022d8:	f406                	sd	ra,40(sp)
    800022da:	f022                	sd	s0,32(sp)
    800022dc:	ec26                	sd	s1,24(sp)
    800022de:	e84a                	sd	s2,16(sp)
    800022e0:	e44e                	sd	s3,8(sp)
    800022e2:	e052                	sd	s4,0(sp)
    800022e4:	1800                	addi	s0,sp,48
    800022e6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	6ce080e7          	jalr	1742(ra) # 800019b6 <myproc>
    800022f0:	89aa                	mv	s3,a0
  if(p == initproc)
    800022f2:	00007797          	auipc	a5,0x7
    800022f6:	d367b783          	ld	a5,-714(a5) # 80009028 <initproc>
    800022fa:	0d050493          	addi	s1,a0,208
    800022fe:	15050913          	addi	s2,a0,336
    80002302:	02a79363          	bne	a5,a0,80002328 <exit+0x52>
    panic("init exiting");
    80002306:	00006517          	auipc	a0,0x6
    8000230a:	f1250513          	addi	a0,a0,-238 # 80008218 <digits+0x1d8>
    8000230e:	ffffe097          	auipc	ra,0xffffe
    80002312:	22c080e7          	jalr	556(ra) # 8000053a <panic>
      fileclose(f);
    80002316:	00002097          	auipc	ra,0x2
    8000231a:	30a080e7          	jalr	778(ra) # 80004620 <fileclose>
      p->ofile[fd] = 0;
    8000231e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002322:	04a1                	addi	s1,s1,8
    80002324:	01248563          	beq	s1,s2,8000232e <exit+0x58>
    if(p->ofile[fd]){
    80002328:	6088                	ld	a0,0(s1)
    8000232a:	f575                	bnez	a0,80002316 <exit+0x40>
    8000232c:	bfdd                	j	80002322 <exit+0x4c>
  begin_op();
    8000232e:	00002097          	auipc	ra,0x2
    80002332:	e2a080e7          	jalr	-470(ra) # 80004158 <begin_op>
  iput(p->cwd);
    80002336:	1509b503          	ld	a0,336(s3)
    8000233a:	00001097          	auipc	ra,0x1
    8000233e:	5fc080e7          	jalr	1532(ra) # 80003936 <iput>
  end_op();
    80002342:	00002097          	auipc	ra,0x2
    80002346:	e94080e7          	jalr	-364(ra) # 800041d6 <end_op>
  p->cwd = 0;
    8000234a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000234e:	0000f497          	auipc	s1,0xf
    80002352:	f6a48493          	addi	s1,s1,-150 # 800112b8 <wait_lock>
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	8c2080e7          	jalr	-1854(ra) # 80000c1a <acquire>
  reparent(p);
    80002360:	854e                	mv	a0,s3
    80002362:	00000097          	auipc	ra,0x0
    80002366:	f1a080e7          	jalr	-230(ra) # 8000227c <reparent>
  wakeup(p->parent);
    8000236a:	0389b503          	ld	a0,56(s3)
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	e98080e7          	jalr	-360(ra) # 80002206 <wakeup>
  acquire(&p->lock);
    80002376:	854e                	mv	a0,s3
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	8a2080e7          	jalr	-1886(ra) # 80000c1a <acquire>
  p->xstate = status;
    80002380:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002384:	4795                	li	a5,5
    80002386:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	942080e7          	jalr	-1726(ra) # 80000cce <release>
  sched();
    80002394:	00000097          	auipc	ra,0x0
    80002398:	bd4080e7          	jalr	-1068(ra) # 80001f68 <sched>
  panic("zombie exit");
    8000239c:	00006517          	auipc	a0,0x6
    800023a0:	e8c50513          	addi	a0,a0,-372 # 80008228 <digits+0x1e8>
    800023a4:	ffffe097          	auipc	ra,0xffffe
    800023a8:	196080e7          	jalr	406(ra) # 8000053a <panic>

00000000800023ac <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023ac:	7179                	addi	sp,sp,-48
    800023ae:	f406                	sd	ra,40(sp)
    800023b0:	f022                	sd	s0,32(sp)
    800023b2:	ec26                	sd	s1,24(sp)
    800023b4:	e84a                	sd	s2,16(sp)
    800023b6:	e44e                	sd	s3,8(sp)
    800023b8:	1800                	addi	s0,sp,48
    800023ba:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023bc:	0000f497          	auipc	s1,0xf
    800023c0:	31448493          	addi	s1,s1,788 # 800116d0 <proc>
    800023c4:	00015997          	auipc	s3,0x15
    800023c8:	d0c98993          	addi	s3,s3,-756 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	84c080e7          	jalr	-1972(ra) # 80000c1a <acquire>
    if(p->pid == pid){
    800023d6:	589c                	lw	a5,48(s1)
    800023d8:	01278d63          	beq	a5,s2,800023f2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8f0080e7          	jalr	-1808(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023e6:	16848493          	addi	s1,s1,360
    800023ea:	ff3491e3          	bne	s1,s3,800023cc <kill+0x20>
  }
  return -1;
    800023ee:	557d                	li	a0,-1
    800023f0:	a829                	j	8000240a <kill+0x5e>
      p->killed = 1;
    800023f2:	4785                	li	a5,1
    800023f4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023f6:	4c98                	lw	a4,24(s1)
    800023f8:	4789                	li	a5,2
    800023fa:	00f70f63          	beq	a4,a5,80002418 <kill+0x6c>
      release(&p->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	8ce080e7          	jalr	-1842(ra) # 80000cce <release>
      return 0;
    80002408:	4501                	li	a0,0
}
    8000240a:	70a2                	ld	ra,40(sp)
    8000240c:	7402                	ld	s0,32(sp)
    8000240e:	64e2                	ld	s1,24(sp)
    80002410:	6942                	ld	s2,16(sp)
    80002412:	69a2                	ld	s3,8(sp)
    80002414:	6145                	addi	sp,sp,48
    80002416:	8082                	ret
        p->state = RUNNABLE;
    80002418:	478d                	li	a5,3
    8000241a:	cc9c                	sw	a5,24(s1)
    8000241c:	b7cd                	j	800023fe <kill+0x52>

000000008000241e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000241e:	7179                	addi	sp,sp,-48
    80002420:	f406                	sd	ra,40(sp)
    80002422:	f022                	sd	s0,32(sp)
    80002424:	ec26                	sd	s1,24(sp)
    80002426:	e84a                	sd	s2,16(sp)
    80002428:	e44e                	sd	s3,8(sp)
    8000242a:	e052                	sd	s4,0(sp)
    8000242c:	1800                	addi	s0,sp,48
    8000242e:	84aa                	mv	s1,a0
    80002430:	892e                	mv	s2,a1
    80002432:	89b2                	mv	s3,a2
    80002434:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	580080e7          	jalr	1408(ra) # 800019b6 <myproc>
  if(user_dst){
    8000243e:	c08d                	beqz	s1,80002460 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002440:	86d2                	mv	a3,s4
    80002442:	864e                	mv	a2,s3
    80002444:	85ca                	mv	a1,s2
    80002446:	6928                	ld	a0,80(a0)
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	232080e7          	jalr	562(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002450:	70a2                	ld	ra,40(sp)
    80002452:	7402                	ld	s0,32(sp)
    80002454:	64e2                	ld	s1,24(sp)
    80002456:	6942                	ld	s2,16(sp)
    80002458:	69a2                	ld	s3,8(sp)
    8000245a:	6a02                	ld	s4,0(sp)
    8000245c:	6145                	addi	sp,sp,48
    8000245e:	8082                	ret
    memmove((char *)dst, src, len);
    80002460:	000a061b          	sext.w	a2,s4
    80002464:	85ce                	mv	a1,s3
    80002466:	854a                	mv	a0,s2
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	90a080e7          	jalr	-1782(ra) # 80000d72 <memmove>
    return 0;
    80002470:	8526                	mv	a0,s1
    80002472:	bff9                	j	80002450 <either_copyout+0x32>

0000000080002474 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002474:	7179                	addi	sp,sp,-48
    80002476:	f406                	sd	ra,40(sp)
    80002478:	f022                	sd	s0,32(sp)
    8000247a:	ec26                	sd	s1,24(sp)
    8000247c:	e84a                	sd	s2,16(sp)
    8000247e:	e44e                	sd	s3,8(sp)
    80002480:	e052                	sd	s4,0(sp)
    80002482:	1800                	addi	s0,sp,48
    80002484:	892a                	mv	s2,a0
    80002486:	84ae                	mv	s1,a1
    80002488:	89b2                	mv	s3,a2
    8000248a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	52a080e7          	jalr	1322(ra) # 800019b6 <myproc>
  if(user_src){
    80002494:	c08d                	beqz	s1,800024b6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002496:	86d2                	mv	a3,s4
    80002498:	864e                	mv	a2,s3
    8000249a:	85ca                	mv	a1,s2
    8000249c:	6928                	ld	a0,80(a0)
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	268080e7          	jalr	616(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024a6:	70a2                	ld	ra,40(sp)
    800024a8:	7402                	ld	s0,32(sp)
    800024aa:	64e2                	ld	s1,24(sp)
    800024ac:	6942                	ld	s2,16(sp)
    800024ae:	69a2                	ld	s3,8(sp)
    800024b0:	6a02                	ld	s4,0(sp)
    800024b2:	6145                	addi	sp,sp,48
    800024b4:	8082                	ret
    memmove(dst, (char*)src, len);
    800024b6:	000a061b          	sext.w	a2,s4
    800024ba:	85ce                	mv	a1,s3
    800024bc:	854a                	mv	a0,s2
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	8b4080e7          	jalr	-1868(ra) # 80000d72 <memmove>
    return 0;
    800024c6:	8526                	mv	a0,s1
    800024c8:	bff9                	j	800024a6 <either_copyin+0x32>

00000000800024ca <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024ca:	715d                	addi	sp,sp,-80
    800024cc:	e486                	sd	ra,72(sp)
    800024ce:	e0a2                	sd	s0,64(sp)
    800024d0:	fc26                	sd	s1,56(sp)
    800024d2:	f84a                	sd	s2,48(sp)
    800024d4:	f44e                	sd	s3,40(sp)
    800024d6:	f052                	sd	s4,32(sp)
    800024d8:	ec56                	sd	s5,24(sp)
    800024da:	e85a                	sd	s6,16(sp)
    800024dc:	e45e                	sd	s7,8(sp)
    800024de:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024e0:	00006517          	auipc	a0,0x6
    800024e4:	be850513          	addi	a0,a0,-1048 # 800080c8 <digits+0x88>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	09c080e7          	jalr	156(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f0:	0000f497          	auipc	s1,0xf
    800024f4:	33848493          	addi	s1,s1,824 # 80011828 <proc+0x158>
    800024f8:	00015917          	auipc	s2,0x15
    800024fc:	d3090913          	addi	s2,s2,-720 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002500:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002502:	00006997          	auipc	s3,0x6
    80002506:	d3698993          	addi	s3,s3,-714 # 80008238 <digits+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    8000250a:	00006a97          	auipc	s5,0x6
    8000250e:	d36a8a93          	addi	s5,s5,-714 # 80008240 <digits+0x200>
    printf("\n");
    80002512:	00006a17          	auipc	s4,0x6
    80002516:	bb6a0a13          	addi	s4,s4,-1098 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000251a:	00006b97          	auipc	s7,0x6
    8000251e:	d5eb8b93          	addi	s7,s7,-674 # 80008278 <states.0>
    80002522:	a00d                	j	80002544 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002524:	ed86a583          	lw	a1,-296(a3)
    80002528:	8556                	mv	a0,s5
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	05a080e7          	jalr	90(ra) # 80000584 <printf>
    printf("\n");
    80002532:	8552                	mv	a0,s4
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	050080e7          	jalr	80(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000253c:	16848493          	addi	s1,s1,360
    80002540:	03248263          	beq	s1,s2,80002564 <procdump+0x9a>
    if(p->state == UNUSED)
    80002544:	86a6                	mv	a3,s1
    80002546:	ec04a783          	lw	a5,-320(s1)
    8000254a:	dbed                	beqz	a5,8000253c <procdump+0x72>
      state = "???";
    8000254c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254e:	fcfb6be3          	bltu	s6,a5,80002524 <procdump+0x5a>
    80002552:	02079713          	slli	a4,a5,0x20
    80002556:	01d75793          	srli	a5,a4,0x1d
    8000255a:	97de                	add	a5,a5,s7
    8000255c:	6390                	ld	a2,0(a5)
    8000255e:	f279                	bnez	a2,80002524 <procdump+0x5a>
      state = "???";
    80002560:	864e                	mv	a2,s3
    80002562:	b7c9                	j	80002524 <procdump+0x5a>
  }
}
    80002564:	60a6                	ld	ra,72(sp)
    80002566:	6406                	ld	s0,64(sp)
    80002568:	74e2                	ld	s1,56(sp)
    8000256a:	7942                	ld	s2,48(sp)
    8000256c:	79a2                	ld	s3,40(sp)
    8000256e:	7a02                	ld	s4,32(sp)
    80002570:	6ae2                	ld	s5,24(sp)
    80002572:	6b42                	ld	s6,16(sp)
    80002574:	6ba2                	ld	s7,8(sp)
    80002576:	6161                	addi	sp,sp,80
    80002578:	8082                	ret

000000008000257a <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    8000257a:	7119                	addi	sp,sp,-128
    8000257c:	fc86                	sd	ra,120(sp)
    8000257e:	f8a2                	sd	s0,112(sp)
    80002580:	f4a6                	sd	s1,104(sp)
    80002582:	f0ca                	sd	s2,96(sp)
    80002584:	ecce                	sd	s3,88(sp)
    80002586:	e8d2                	sd	s4,80(sp)
    80002588:	e4d6                	sd	s5,72(sp)
    8000258a:	e0da                	sd	s6,64(sp)
    8000258c:	fc5e                	sd	s7,56(sp)
    8000258e:	0100                	addi	s0,sp,128
    80002590:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	424080e7          	jalr	1060(ra) # 800019b6 <myproc>
    8000259a:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    8000259c:	0000f917          	auipc	s2,0xf
    800025a0:	28c90913          	addi	s2,s2,652 # 80011828 <proc+0x158>
    800025a4:	00015a17          	auipc	s4,0x15
    800025a8:	c84a0a13          	addi	s4,s4,-892 # 80017228 <bcache+0x140>
  int nprocs = 0;
    800025ac:	4a81                	li	s5,0
    procinfo.state = p->state;
    procinfo.size = p->sz;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    800025ae:	4b81                	li	s7,0
    800025b0:	fac40493          	addi	s1,s0,-84
    800025b4:	a089                	j	800025f6 <procinfo+0x7c>
    800025b6:	f8f42c23          	sw	a5,-104(s0)
    for (int i=0; i<16; i++)
    800025ba:	f9c40793          	addi	a5,s0,-100
      procinfo.ppid = 0;
    800025be:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    800025c0:	00074683          	lbu	a3,0(a4)
    800025c4:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    800025c8:	0705                	addi	a4,a4,1
    800025ca:	0785                	addi	a5,a5,1
    800025cc:	fe979ae3          	bne	a5,s1,800025c0 <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    800025d0:	02800693          	li	a3,40
    800025d4:	f8840613          	addi	a2,s0,-120
    800025d8:	85ce                	mv	a1,s3
    800025da:	050b3503          	ld	a0,80(s6)
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	09c080e7          	jalr	156(ra) # 8000167a <copyout>
    800025e6:	02054c63          	bltz	a0,8000261e <procinfo+0xa4>
      return -1;
    addr += sizeof(procinfo);
    800025ea:	02898993          	addi	s3,s3,40
  for(p = proc; p < &proc[NPROC]; p++){ 
    800025ee:	16890913          	addi	s2,s2,360
    800025f2:	03490763          	beq	s2,s4,80002620 <procinfo+0xa6>
    if(p->state == UNUSED)
    800025f6:	ec092783          	lw	a5,-320(s2)
    800025fa:	dbf5                	beqz	a5,800025ee <procinfo+0x74>
    nprocs++;
    800025fc:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    800025fe:	ed892703          	lw	a4,-296(s2)
    80002602:	f8e42423          	sw	a4,-120(s0)
    procinfo.state = p->state;
    80002606:	f8f42623          	sw	a5,-116(s0)
    procinfo.size = p->sz;
    8000260a:	ef093783          	ld	a5,-272(s2)
    8000260e:	f8f43823          	sd	a5,-112(s0)
    if (p->parent)
    80002612:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    80002616:	87de                	mv	a5,s7
    if (p->parent)
    80002618:	df59                	beqz	a4,800025b6 <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    8000261a:	5b1c                	lw	a5,48(a4)
    8000261c:	bf69                	j	800025b6 <procinfo+0x3c>
      return -1;
    8000261e:	5afd                	li	s5,-1
  }
  return nprocs;
}
    80002620:	8556                	mv	a0,s5
    80002622:	70e6                	ld	ra,120(sp)
    80002624:	7446                	ld	s0,112(sp)
    80002626:	74a6                	ld	s1,104(sp)
    80002628:	7906                	ld	s2,96(sp)
    8000262a:	69e6                	ld	s3,88(sp)
    8000262c:	6a46                	ld	s4,80(sp)
    8000262e:	6aa6                	ld	s5,72(sp)
    80002630:	6b06                	ld	s6,64(sp)
    80002632:	7be2                	ld	s7,56(sp)
    80002634:	6109                	addi	sp,sp,128
    80002636:	8082                	ret

0000000080002638 <swtch>:
    80002638:	00153023          	sd	ra,0(a0)
    8000263c:	00253423          	sd	sp,8(a0)
    80002640:	e900                	sd	s0,16(a0)
    80002642:	ed04                	sd	s1,24(a0)
    80002644:	03253023          	sd	s2,32(a0)
    80002648:	03353423          	sd	s3,40(a0)
    8000264c:	03453823          	sd	s4,48(a0)
    80002650:	03553c23          	sd	s5,56(a0)
    80002654:	05653023          	sd	s6,64(a0)
    80002658:	05753423          	sd	s7,72(a0)
    8000265c:	05853823          	sd	s8,80(a0)
    80002660:	05953c23          	sd	s9,88(a0)
    80002664:	07a53023          	sd	s10,96(a0)
    80002668:	07b53423          	sd	s11,104(a0)
    8000266c:	0005b083          	ld	ra,0(a1)
    80002670:	0085b103          	ld	sp,8(a1)
    80002674:	6980                	ld	s0,16(a1)
    80002676:	6d84                	ld	s1,24(a1)
    80002678:	0205b903          	ld	s2,32(a1)
    8000267c:	0285b983          	ld	s3,40(a1)
    80002680:	0305ba03          	ld	s4,48(a1)
    80002684:	0385ba83          	ld	s5,56(a1)
    80002688:	0405bb03          	ld	s6,64(a1)
    8000268c:	0485bb83          	ld	s7,72(a1)
    80002690:	0505bc03          	ld	s8,80(a1)
    80002694:	0585bc83          	ld	s9,88(a1)
    80002698:	0605bd03          	ld	s10,96(a1)
    8000269c:	0685bd83          	ld	s11,104(a1)
    800026a0:	8082                	ret

00000000800026a2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026a2:	1141                	addi	sp,sp,-16
    800026a4:	e406                	sd	ra,8(sp)
    800026a6:	e022                	sd	s0,0(sp)
    800026a8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026aa:	00006597          	auipc	a1,0x6
    800026ae:	bfe58593          	addi	a1,a1,-1026 # 800082a8 <states.0+0x30>
    800026b2:	00015517          	auipc	a0,0x15
    800026b6:	a1e50513          	addi	a0,a0,-1506 # 800170d0 <tickslock>
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	4d0080e7          	jalr	1232(ra) # 80000b8a <initlock>
}
    800026c2:	60a2                	ld	ra,8(sp)
    800026c4:	6402                	ld	s0,0(sp)
    800026c6:	0141                	addi	sp,sp,16
    800026c8:	8082                	ret

00000000800026ca <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ca:	1141                	addi	sp,sp,-16
    800026cc:	e422                	sd	s0,8(sp)
    800026ce:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d0:	00003797          	auipc	a5,0x3
    800026d4:	58078793          	addi	a5,a5,1408 # 80005c50 <kernelvec>
    800026d8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026dc:	6422                	ld	s0,8(sp)
    800026de:	0141                	addi	sp,sp,16
    800026e0:	8082                	ret

00000000800026e2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026e2:	1141                	addi	sp,sp,-16
    800026e4:	e406                	sd	ra,8(sp)
    800026e6:	e022                	sd	s0,0(sp)
    800026e8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	2cc080e7          	jalr	716(ra) # 800019b6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026f6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026f8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026fc:	00005697          	auipc	a3,0x5
    80002700:	90468693          	addi	a3,a3,-1788 # 80007000 <_trampoline>
    80002704:	00005717          	auipc	a4,0x5
    80002708:	8fc70713          	addi	a4,a4,-1796 # 80007000 <_trampoline>
    8000270c:	8f15                	sub	a4,a4,a3
    8000270e:	040007b7          	lui	a5,0x4000
    80002712:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002714:	07b2                	slli	a5,a5,0xc
    80002716:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002718:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000271c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000271e:	18002673          	csrr	a2,satp
    80002722:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002724:	6d30                	ld	a2,88(a0)
    80002726:	6138                	ld	a4,64(a0)
    80002728:	6585                	lui	a1,0x1
    8000272a:	972e                	add	a4,a4,a1
    8000272c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000272e:	6d38                	ld	a4,88(a0)
    80002730:	00000617          	auipc	a2,0x0
    80002734:	13860613          	addi	a2,a2,312 # 80002868 <usertrap>
    80002738:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000273a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000273c:	8612                	mv	a2,tp
    8000273e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002740:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002744:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002748:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002750:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002752:	6f18                	ld	a4,24(a4)
    80002754:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002758:	692c                	ld	a1,80(a0)
    8000275a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000275c:	00005717          	auipc	a4,0x5
    80002760:	93470713          	addi	a4,a4,-1740 # 80007090 <userret>
    80002764:	8f15                	sub	a4,a4,a3
    80002766:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002768:	577d                	li	a4,-1
    8000276a:	177e                	slli	a4,a4,0x3f
    8000276c:	8dd9                	or	a1,a1,a4
    8000276e:	02000537          	lui	a0,0x2000
    80002772:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002774:	0536                	slli	a0,a0,0xd
    80002776:	9782                	jalr	a5
}
    80002778:	60a2                	ld	ra,8(sp)
    8000277a:	6402                	ld	s0,0(sp)
    8000277c:	0141                	addi	sp,sp,16
    8000277e:	8082                	ret

0000000080002780 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002780:	1101                	addi	sp,sp,-32
    80002782:	ec06                	sd	ra,24(sp)
    80002784:	e822                	sd	s0,16(sp)
    80002786:	e426                	sd	s1,8(sp)
    80002788:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000278a:	00015497          	auipc	s1,0x15
    8000278e:	94648493          	addi	s1,s1,-1722 # 800170d0 <tickslock>
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	486080e7          	jalr	1158(ra) # 80000c1a <acquire>
  ticks++;
    8000279c:	00007517          	auipc	a0,0x7
    800027a0:	89450513          	addi	a0,a0,-1900 # 80009030 <ticks>
    800027a4:	411c                	lw	a5,0(a0)
    800027a6:	2785                	addiw	a5,a5,1
    800027a8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027aa:	00000097          	auipc	ra,0x0
    800027ae:	a5c080e7          	jalr	-1444(ra) # 80002206 <wakeup>
  release(&tickslock);
    800027b2:	8526                	mv	a0,s1
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	51a080e7          	jalr	1306(ra) # 80000cce <release>
}
    800027bc:	60e2                	ld	ra,24(sp)
    800027be:	6442                	ld	s0,16(sp)
    800027c0:	64a2                	ld	s1,8(sp)
    800027c2:	6105                	addi	sp,sp,32
    800027c4:	8082                	ret

00000000800027c6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027c6:	1101                	addi	sp,sp,-32
    800027c8:	ec06                	sd	ra,24(sp)
    800027ca:	e822                	sd	s0,16(sp)
    800027cc:	e426                	sd	s1,8(sp)
    800027ce:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027d0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027d4:	00074d63          	bltz	a4,800027ee <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027d8:	57fd                	li	a5,-1
    800027da:	17fe                	slli	a5,a5,0x3f
    800027dc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027de:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027e0:	06f70363          	beq	a4,a5,80002846 <devintr+0x80>
  }
}
    800027e4:	60e2                	ld	ra,24(sp)
    800027e6:	6442                	ld	s0,16(sp)
    800027e8:	64a2                	ld	s1,8(sp)
    800027ea:	6105                	addi	sp,sp,32
    800027ec:	8082                	ret
     (scause & 0xff) == 9){
    800027ee:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027f2:	46a5                	li	a3,9
    800027f4:	fed792e3          	bne	a5,a3,800027d8 <devintr+0x12>
    int irq = plic_claim();
    800027f8:	00003097          	auipc	ra,0x3
    800027fc:	560080e7          	jalr	1376(ra) # 80005d58 <plic_claim>
    80002800:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002802:	47a9                	li	a5,10
    80002804:	02f50763          	beq	a0,a5,80002832 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002808:	4785                	li	a5,1
    8000280a:	02f50963          	beq	a0,a5,8000283c <devintr+0x76>
    return 1;
    8000280e:	4505                	li	a0,1
    } else if(irq){
    80002810:	d8f1                	beqz	s1,800027e4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002812:	85a6                	mv	a1,s1
    80002814:	00006517          	auipc	a0,0x6
    80002818:	a9c50513          	addi	a0,a0,-1380 # 800082b0 <states.0+0x38>
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	d68080e7          	jalr	-664(ra) # 80000584 <printf>
      plic_complete(irq);
    80002824:	8526                	mv	a0,s1
    80002826:	00003097          	auipc	ra,0x3
    8000282a:	556080e7          	jalr	1366(ra) # 80005d7c <plic_complete>
    return 1;
    8000282e:	4505                	li	a0,1
    80002830:	bf55                	j	800027e4 <devintr+0x1e>
      uartintr();
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	160080e7          	jalr	352(ra) # 80000992 <uartintr>
    8000283a:	b7ed                	j	80002824 <devintr+0x5e>
      virtio_disk_intr();
    8000283c:	00004097          	auipc	ra,0x4
    80002840:	9cc080e7          	jalr	-1588(ra) # 80006208 <virtio_disk_intr>
    80002844:	b7c5                	j	80002824 <devintr+0x5e>
    if(cpuid() == 0){
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	144080e7          	jalr	324(ra) # 8000198a <cpuid>
    8000284e:	c901                	beqz	a0,8000285e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002850:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002854:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002856:	14479073          	csrw	sip,a5
    return 2;
    8000285a:	4509                	li	a0,2
    8000285c:	b761                	j	800027e4 <devintr+0x1e>
      clockintr();
    8000285e:	00000097          	auipc	ra,0x0
    80002862:	f22080e7          	jalr	-222(ra) # 80002780 <clockintr>
    80002866:	b7ed                	j	80002850 <devintr+0x8a>

0000000080002868 <usertrap>:
{
    80002868:	1101                	addi	sp,sp,-32
    8000286a:	ec06                	sd	ra,24(sp)
    8000286c:	e822                	sd	s0,16(sp)
    8000286e:	e426                	sd	s1,8(sp)
    80002870:	e04a                	sd	s2,0(sp)
    80002872:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002874:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002878:	1007f793          	andi	a5,a5,256
    8000287c:	e3b5                	bnez	a5,800028e0 <usertrap+0x78>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000287e:	00003797          	auipc	a5,0x3
    80002882:	3d278793          	addi	a5,a5,978 # 80005c50 <kernelvec>
    80002886:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	12c080e7          	jalr	300(ra) # 800019b6 <myproc>
    80002892:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002894:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002896:	14102773          	csrr	a4,sepc
    8000289a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028a0:	47a1                	li	a5,8
    800028a2:	04f71d63          	bne	a4,a5,800028fc <usertrap+0x94>
    if(p->killed)
    800028a6:	551c                	lw	a5,40(a0)
    800028a8:	e7a1                	bnez	a5,800028f0 <usertrap+0x88>
    p->trapframe->epc += 4;
    800028aa:	6cb8                	ld	a4,88(s1)
    800028ac:	6f1c                	ld	a5,24(a4)
    800028ae:	0791                	addi	a5,a5,4
    800028b0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028b6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ba:	10079073          	csrw	sstatus,a5
    syscall();
    800028be:	00000097          	auipc	ra,0x0
    800028c2:	370080e7          	jalr	880(ra) # 80002c2e <syscall>
  if(p->killed)
    800028c6:	549c                	lw	a5,40(s1)
    800028c8:	12079063          	bnez	a5,800029e8 <usertrap+0x180>
  usertrapret();
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	e16080e7          	jalr	-490(ra) # 800026e2 <usertrapret>
}
    800028d4:	60e2                	ld	ra,24(sp)
    800028d6:	6442                	ld	s0,16(sp)
    800028d8:	64a2                	ld	s1,8(sp)
    800028da:	6902                	ld	s2,0(sp)
    800028dc:	6105                	addi	sp,sp,32
    800028de:	8082                	ret
    panic("usertrap: not from user mode");
    800028e0:	00006517          	auipc	a0,0x6
    800028e4:	9f050513          	addi	a0,a0,-1552 # 800082d0 <states.0+0x58>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	c52080e7          	jalr	-942(ra) # 8000053a <panic>
      exit(-1);
    800028f0:	557d                	li	a0,-1
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	9e4080e7          	jalr	-1564(ra) # 800022d6 <exit>
    800028fa:	bf45                	j	800028aa <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	eca080e7          	jalr	-310(ra) # 800027c6 <devintr>
    80002904:	892a                	mv	s2,a0
    80002906:	ed71                	bnez	a0,800029e2 <usertrap+0x17a>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002908:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    8000290c:	47b5                	li	a5,13
    8000290e:	00f70763          	beq	a4,a5,8000291c <usertrap+0xb4>
    80002912:	14202773          	csrr	a4,scause
    80002916:	47bd                	li	a5,15
    80002918:	08f71d63          	bne	a4,a5,800029b2 <usertrap+0x14a>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000291c:	143027f3          	csrr	a5,stval
  if (r_stval() < p->sz){
    80002920:	64b8                	ld	a4,72(s1)
    80002922:	04e7fe63          	bgeu	a5,a4,8000297e <usertrap+0x116>
    char* physical_frame = kalloc();
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	1ba080e7          	jalr	442(ra) # 80000ae0 <kalloc>
    8000292e:	892a                	mv	s2,a0
    if(physical_frame == 0){
    80002930:	c505                	beqz	a0,80002958 <usertrap+0xf0>
        memset((void*)physical_frame, 0, PGSIZE);
    80002932:	6605                	lui	a2,0x1
    80002934:	4581                	li	a1,0
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	3e0080e7          	jalr	992(ra) # 80000d16 <memset>
    8000293e:	143025f3          	csrr	a1,stval
        mappages(p->pagetable, PGROUNDDOWN(r_stval()), PGSIZE, (uint64)physical_frame, (PTE_R | PTE_W | PTE_X | PTE_U));
    80002942:	4779                	li	a4,30
    80002944:	86ca                	mv	a3,s2
    80002946:	6605                	lui	a2,0x1
    80002948:	77fd                	lui	a5,0xfffff
    8000294a:	8dfd                	and	a1,a1,a5
    8000294c:	68a8                	ld	a0,80(s1)
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	790080e7          	jalr	1936(ra) # 800010de <mappages>
    80002956:	bf85                	j	800028c6 <usertrap+0x5e>
    80002958:	14302673          	csrr	a2,stval
      printf("usertrap(): out of memory, pid=%d, fault_address=%p\n", p->pid, r_stval());
    8000295c:	588c                	lw	a1,48(s1)
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	99250513          	addi	a0,a0,-1646 # 800082f0 <states.0+0x78>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c1e080e7          	jalr	-994(ra) # 80000584 <printf>
      p->killed = 1;
    8000296e:	4785                	li	a5,1
    80002970:	d49c                	sw	a5,40(s1)
      exit(-1);
    80002972:	557d                	li	a0,-1
    80002974:	00000097          	auipc	ra,0x0
    80002978:	962080e7          	jalr	-1694(ra) # 800022d6 <exit>
    8000297c:	b7a9                	j	800028c6 <usertrap+0x5e>
    8000297e:	14302673          	csrr	a2,stval
      printf("usertrap(): unexpected page fault, pid=%d, fault_address=%p\n", p->pid, r_stval());
    80002982:	588c                	lw	a1,48(s1)
    80002984:	00006517          	auipc	a0,0x6
    80002988:	9a450513          	addi	a0,a0,-1628 # 80008328 <states.0+0xb0>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	bf8080e7          	jalr	-1032(ra) # 80000584 <printf>
    p->killed = 1;
    80002994:	4785                	li	a5,1
    80002996:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002998:	557d                	li	a0,-1
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	93c080e7          	jalr	-1732(ra) # 800022d6 <exit>
  if(which_dev == 2)
    800029a2:	4789                	li	a5,2
    800029a4:	f2f914e3          	bne	s2,a5,800028cc <usertrap+0x64>
    yield();
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	696080e7          	jalr	1686(ra) # 8000203e <yield>
    800029b0:	bf31                	j	800028cc <usertrap+0x64>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029b6:	5890                	lw	a2,48(s1)
    800029b8:	00006517          	auipc	a0,0x6
    800029bc:	9b050513          	addi	a0,a0,-1616 # 80008368 <states.0+0xf0>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	bc4080e7          	jalr	-1084(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029cc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029d0:	00006517          	auipc	a0,0x6
    800029d4:	9c850513          	addi	a0,a0,-1592 # 80008398 <states.0+0x120>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	bac080e7          	jalr	-1108(ra) # 80000584 <printf>
    p->killed = 1;
    800029e0:	bf55                	j	80002994 <usertrap+0x12c>
  if(p->killed)
    800029e2:	549c                	lw	a5,40(s1)
    800029e4:	dfdd                	beqz	a5,800029a2 <usertrap+0x13a>
    800029e6:	bf4d                	j	80002998 <usertrap+0x130>
    800029e8:	4901                	li	s2,0
    800029ea:	b77d                	j	80002998 <usertrap+0x130>

00000000800029ec <kerneltrap>:
{
    800029ec:	7179                	addi	sp,sp,-48
    800029ee:	f406                	sd	ra,40(sp)
    800029f0:	f022                	sd	s0,32(sp)
    800029f2:	ec26                	sd	s1,24(sp)
    800029f4:	e84a                	sd	s2,16(sp)
    800029f6:	e44e                	sd	s3,8(sp)
    800029f8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a02:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a06:	1004f793          	andi	a5,s1,256
    80002a0a:	cb85                	beqz	a5,80002a3a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a10:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a12:	ef85                	bnez	a5,80002a4a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a14:	00000097          	auipc	ra,0x0
    80002a18:	db2080e7          	jalr	-590(ra) # 800027c6 <devintr>
    80002a1c:	cd1d                	beqz	a0,80002a5a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1e:	4789                	li	a5,2
    80002a20:	06f50a63          	beq	a0,a5,80002a94 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a24:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a28:	10049073          	csrw	sstatus,s1
}
    80002a2c:	70a2                	ld	ra,40(sp)
    80002a2e:	7402                	ld	s0,32(sp)
    80002a30:	64e2                	ld	s1,24(sp)
    80002a32:	6942                	ld	s2,16(sp)
    80002a34:	69a2                	ld	s3,8(sp)
    80002a36:	6145                	addi	sp,sp,48
    80002a38:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	97e50513          	addi	a0,a0,-1666 # 800083b8 <states.0+0x140>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	af8080e7          	jalr	-1288(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	99650513          	addi	a0,a0,-1642 # 800083e0 <states.0+0x168>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	ae8080e7          	jalr	-1304(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002a5a:	85ce                	mv	a1,s3
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	9a450513          	addi	a0,a0,-1628 # 80008400 <states.0+0x188>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	b20080e7          	jalr	-1248(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a70:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	99c50513          	addi	a0,a0,-1636 # 80008410 <states.0+0x198>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b08080e7          	jalr	-1272(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	9a450513          	addi	a0,a0,-1628 # 80008428 <states.0+0x1b0>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	aae080e7          	jalr	-1362(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	f22080e7          	jalr	-222(ra) # 800019b6 <myproc>
    80002a9c:	d541                	beqz	a0,80002a24 <kerneltrap+0x38>
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	f18080e7          	jalr	-232(ra) # 800019b6 <myproc>
    80002aa6:	4d18                	lw	a4,24(a0)
    80002aa8:	4791                	li	a5,4
    80002aaa:	f6f71de3          	bne	a4,a5,80002a24 <kerneltrap+0x38>
    yield();
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	590080e7          	jalr	1424(ra) # 8000203e <yield>
    80002ab6:	b7bd                	j	80002a24 <kerneltrap+0x38>

0000000080002ab8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab8:	1101                	addi	sp,sp,-32
    80002aba:	ec06                	sd	ra,24(sp)
    80002abc:	e822                	sd	s0,16(sp)
    80002abe:	e426                	sd	s1,8(sp)
    80002ac0:	1000                	addi	s0,sp,32
    80002ac2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	ef2080e7          	jalr	-270(ra) # 800019b6 <myproc>
  switch (n) {
    80002acc:	4795                	li	a5,5
    80002ace:	0497e163          	bltu	a5,s1,80002b10 <argraw+0x58>
    80002ad2:	048a                	slli	s1,s1,0x2
    80002ad4:	00006717          	auipc	a4,0x6
    80002ad8:	98c70713          	addi	a4,a4,-1652 # 80008460 <states.0+0x1e8>
    80002adc:	94ba                	add	s1,s1,a4
    80002ade:	409c                	lw	a5,0(s1)
    80002ae0:	97ba                	add	a5,a5,a4
    80002ae2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ae4:	6d3c                	ld	a5,88(a0)
    80002ae6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae8:	60e2                	ld	ra,24(sp)
    80002aea:	6442                	ld	s0,16(sp)
    80002aec:	64a2                	ld	s1,8(sp)
    80002aee:	6105                	addi	sp,sp,32
    80002af0:	8082                	ret
    return p->trapframe->a1;
    80002af2:	6d3c                	ld	a5,88(a0)
    80002af4:	7fa8                	ld	a0,120(a5)
    80002af6:	bfcd                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a2;
    80002af8:	6d3c                	ld	a5,88(a0)
    80002afa:	63c8                	ld	a0,128(a5)
    80002afc:	b7f5                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a3;
    80002afe:	6d3c                	ld	a5,88(a0)
    80002b00:	67c8                	ld	a0,136(a5)
    80002b02:	b7dd                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a4;
    80002b04:	6d3c                	ld	a5,88(a0)
    80002b06:	6bc8                	ld	a0,144(a5)
    80002b08:	b7c5                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a5;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	6fc8                	ld	a0,152(a5)
    80002b0e:	bfe9                	j	80002ae8 <argraw+0x30>
  panic("argraw");
    80002b10:	00006517          	auipc	a0,0x6
    80002b14:	92850513          	addi	a0,a0,-1752 # 80008438 <states.0+0x1c0>
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	a22080e7          	jalr	-1502(ra) # 8000053a <panic>

0000000080002b20 <fetchaddr>:
{
    80002b20:	1101                	addi	sp,sp,-32
    80002b22:	ec06                	sd	ra,24(sp)
    80002b24:	e822                	sd	s0,16(sp)
    80002b26:	e426                	sd	s1,8(sp)
    80002b28:	e04a                	sd	s2,0(sp)
    80002b2a:	1000                	addi	s0,sp,32
    80002b2c:	84aa                	mv	s1,a0
    80002b2e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	e86080e7          	jalr	-378(ra) # 800019b6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b38:	653c                	ld	a5,72(a0)
    80002b3a:	02f4f863          	bgeu	s1,a5,80002b6a <fetchaddr+0x4a>
    80002b3e:	00848713          	addi	a4,s1,8
    80002b42:	02e7e663          	bltu	a5,a4,80002b6e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b46:	46a1                	li	a3,8
    80002b48:	8626                	mv	a2,s1
    80002b4a:	85ca                	mv	a1,s2
    80002b4c:	6928                	ld	a0,80(a0)
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	bb8080e7          	jalr	-1096(ra) # 80001706 <copyin>
    80002b56:	00a03533          	snez	a0,a0
    80002b5a:	40a00533          	neg	a0,a0
}
    80002b5e:	60e2                	ld	ra,24(sp)
    80002b60:	6442                	ld	s0,16(sp)
    80002b62:	64a2                	ld	s1,8(sp)
    80002b64:	6902                	ld	s2,0(sp)
    80002b66:	6105                	addi	sp,sp,32
    80002b68:	8082                	ret
    return -1;
    80002b6a:	557d                	li	a0,-1
    80002b6c:	bfcd                	j	80002b5e <fetchaddr+0x3e>
    80002b6e:	557d                	li	a0,-1
    80002b70:	b7fd                	j	80002b5e <fetchaddr+0x3e>

0000000080002b72 <fetchstr>:
{
    80002b72:	7179                	addi	sp,sp,-48
    80002b74:	f406                	sd	ra,40(sp)
    80002b76:	f022                	sd	s0,32(sp)
    80002b78:	ec26                	sd	s1,24(sp)
    80002b7a:	e84a                	sd	s2,16(sp)
    80002b7c:	e44e                	sd	s3,8(sp)
    80002b7e:	1800                	addi	s0,sp,48
    80002b80:	892a                	mv	s2,a0
    80002b82:	84ae                	mv	s1,a1
    80002b84:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	e30080e7          	jalr	-464(ra) # 800019b6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b8e:	86ce                	mv	a3,s3
    80002b90:	864a                	mv	a2,s2
    80002b92:	85a6                	mv	a1,s1
    80002b94:	6928                	ld	a0,80(a0)
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	bfe080e7          	jalr	-1026(ra) # 80001794 <copyinstr>
  if(err < 0)
    80002b9e:	00054763          	bltz	a0,80002bac <fetchstr+0x3a>
  return strlen(buf);
    80002ba2:	8526                	mv	a0,s1
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	2ee080e7          	jalr	750(ra) # 80000e92 <strlen>
}
    80002bac:	70a2                	ld	ra,40(sp)
    80002bae:	7402                	ld	s0,32(sp)
    80002bb0:	64e2                	ld	s1,24(sp)
    80002bb2:	6942                	ld	s2,16(sp)
    80002bb4:	69a2                	ld	s3,8(sp)
    80002bb6:	6145                	addi	sp,sp,48
    80002bb8:	8082                	ret

0000000080002bba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	1000                	addi	s0,sp,32
    80002bc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	ef2080e7          	jalr	-270(ra) # 80002ab8 <argraw>
    80002bce:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bd0:	4501                	li	a0,0
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	64a2                	ld	s1,8(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret

0000000080002bdc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bdc:	1101                	addi	sp,sp,-32
    80002bde:	ec06                	sd	ra,24(sp)
    80002be0:	e822                	sd	s0,16(sp)
    80002be2:	e426                	sd	s1,8(sp)
    80002be4:	1000                	addi	s0,sp,32
    80002be6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be8:	00000097          	auipc	ra,0x0
    80002bec:	ed0080e7          	jalr	-304(ra) # 80002ab8 <argraw>
    80002bf0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bf2:	4501                	li	a0,0
    80002bf4:	60e2                	ld	ra,24(sp)
    80002bf6:	6442                	ld	s0,16(sp)
    80002bf8:	64a2                	ld	s1,8(sp)
    80002bfa:	6105                	addi	sp,sp,32
    80002bfc:	8082                	ret

0000000080002bfe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bfe:	1101                	addi	sp,sp,-32
    80002c00:	ec06                	sd	ra,24(sp)
    80002c02:	e822                	sd	s0,16(sp)
    80002c04:	e426                	sd	s1,8(sp)
    80002c06:	e04a                	sd	s2,0(sp)
    80002c08:	1000                	addi	s0,sp,32
    80002c0a:	84ae                	mv	s1,a1
    80002c0c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	eaa080e7          	jalr	-342(ra) # 80002ab8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c16:	864a                	mv	a2,s2
    80002c18:	85a6                	mv	a1,s1
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	f58080e7          	jalr	-168(ra) # 80002b72 <fetchstr>
}
    80002c22:	60e2                	ld	ra,24(sp)
    80002c24:	6442                	ld	s0,16(sp)
    80002c26:	64a2                	ld	s1,8(sp)
    80002c28:	6902                	ld	s2,0(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <syscall>:
[SYS_freepmem]   sys_freepmem,
};

void
syscall(void)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	e426                	sd	s1,8(sp)
    80002c36:	e04a                	sd	s2,0(sp)
    80002c38:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	d7c080e7          	jalr	-644(ra) # 800019b6 <myproc>
    80002c42:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c44:	05853903          	ld	s2,88(a0)
    80002c48:	0a893783          	ld	a5,168(s2)
    80002c4c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c50:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffd8fff>
    80002c52:	4759                	li	a4,22
    80002c54:	00f76f63          	bltu	a4,a5,80002c72 <syscall+0x44>
    80002c58:	00369713          	slli	a4,a3,0x3
    80002c5c:	00006797          	auipc	a5,0x6
    80002c60:	81c78793          	addi	a5,a5,-2020 # 80008478 <syscalls>
    80002c64:	97ba                	add	a5,a5,a4
    80002c66:	639c                	ld	a5,0(a5)
    80002c68:	c789                	beqz	a5,80002c72 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c6a:	9782                	jalr	a5
    80002c6c:	06a93823          	sd	a0,112(s2)
    80002c70:	a839                	j	80002c8e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c72:	15848613          	addi	a2,s1,344
    80002c76:	588c                	lw	a1,48(s1)
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	7c850513          	addi	a0,a0,1992 # 80008440 <states.0+0x1c8>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	904080e7          	jalr	-1788(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c88:	6cbc                	ld	a5,88(s1)
    80002c8a:	577d                	li	a4,-1
    80002c8c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6902                	ld	s2,0(sp)
    80002c96:	6105                	addi	sp,sp,32
    80002c98:	8082                	ret

0000000080002c9a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c9a:	1101                	addi	sp,sp,-32
    80002c9c:	ec06                	sd	ra,24(sp)
    80002c9e:	e822                	sd	s0,16(sp)
    80002ca0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ca2:	fec40593          	addi	a1,s0,-20
    80002ca6:	4501                	li	a0,0
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	f12080e7          	jalr	-238(ra) # 80002bba <argint>
    return -1;
    80002cb0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cb2:	00054963          	bltz	a0,80002cc4 <sys_exit+0x2a>
  exit(n);
    80002cb6:	fec42503          	lw	a0,-20(s0)
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	61c080e7          	jalr	1564(ra) # 800022d6 <exit>
  return 0;  // not reached
    80002cc2:	4781                	li	a5,0
}
    80002cc4:	853e                	mv	a0,a5
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	6105                	addi	sp,sp,32
    80002ccc:	8082                	ret

0000000080002cce <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cce:	1141                	addi	sp,sp,-16
    80002cd0:	e406                	sd	ra,8(sp)
    80002cd2:	e022                	sd	s0,0(sp)
    80002cd4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	ce0080e7          	jalr	-800(ra) # 800019b6 <myproc>
}
    80002cde:	5908                	lw	a0,48(a0)
    80002ce0:	60a2                	ld	ra,8(sp)
    80002ce2:	6402                	ld	s0,0(sp)
    80002ce4:	0141                	addi	sp,sp,16
    80002ce6:	8082                	ret

0000000080002ce8 <sys_fork>:

uint64
sys_fork(void)
{
    80002ce8:	1141                	addi	sp,sp,-16
    80002cea:	e406                	sd	ra,8(sp)
    80002cec:	e022                	sd	s0,0(sp)
    80002cee:	0800                	addi	s0,sp,16
  return fork();
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	098080e7          	jalr	152(ra) # 80001d88 <fork>
}
    80002cf8:	60a2                	ld	ra,8(sp)
    80002cfa:	6402                	ld	s0,0(sp)
    80002cfc:	0141                	addi	sp,sp,16
    80002cfe:	8082                	ret

0000000080002d00 <sys_wait>:

uint64
sys_wait(void)
{
    80002d00:	1101                	addi	sp,sp,-32
    80002d02:	ec06                	sd	ra,24(sp)
    80002d04:	e822                	sd	s0,16(sp)
    80002d06:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d08:	fe840593          	addi	a1,s0,-24
    80002d0c:	4501                	li	a0,0
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	ece080e7          	jalr	-306(ra) # 80002bdc <argaddr>
    80002d16:	87aa                	mv	a5,a0
    return -1;
    80002d18:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d1a:	0007c863          	bltz	a5,80002d2a <sys_wait+0x2a>
  return wait(p);
    80002d1e:	fe843503          	ld	a0,-24(s0)
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	3bc080e7          	jalr	956(ra) # 800020de <wait>
}
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d32:	7139                	addi	sp,sp,-64
    80002d34:	fc06                	sd	ra,56(sp)
    80002d36:	f822                	sd	s0,48(sp)
    80002d38:	f426                	sd	s1,40(sp)
    80002d3a:	f04a                	sd	s2,32(sp)
    80002d3c:	ec4e                	sd	s3,24(sp)
    80002d3e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d40:	fcc40593          	addi	a1,s0,-52
    80002d44:	4501                	li	a0,0
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	e74080e7          	jalr	-396(ra) # 80002bba <argint>
    return -1;
    80002d4e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d50:	06054563          	bltz	a0,80002dba <sys_sleep+0x88>
  acquire(&tickslock);
    80002d54:	00014517          	auipc	a0,0x14
    80002d58:	37c50513          	addi	a0,a0,892 # 800170d0 <tickslock>
    80002d5c:	ffffe097          	auipc	ra,0xffffe
    80002d60:	ebe080e7          	jalr	-322(ra) # 80000c1a <acquire>
  ticks0 = ticks;
    80002d64:	00006917          	auipc	s2,0x6
    80002d68:	2cc92903          	lw	s2,716(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d6c:	fcc42783          	lw	a5,-52(s0)
    80002d70:	cf85                	beqz	a5,80002da8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d72:	00014997          	auipc	s3,0x14
    80002d76:	35e98993          	addi	s3,s3,862 # 800170d0 <tickslock>
    80002d7a:	00006497          	auipc	s1,0x6
    80002d7e:	2b648493          	addi	s1,s1,694 # 80009030 <ticks>
    if(myproc()->killed){
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	c34080e7          	jalr	-972(ra) # 800019b6 <myproc>
    80002d8a:	551c                	lw	a5,40(a0)
    80002d8c:	ef9d                	bnez	a5,80002dca <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d8e:	85ce                	mv	a1,s3
    80002d90:	8526                	mv	a0,s1
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	2e8080e7          	jalr	744(ra) # 8000207a <sleep>
  while(ticks - ticks0 < n){
    80002d9a:	409c                	lw	a5,0(s1)
    80002d9c:	412787bb          	subw	a5,a5,s2
    80002da0:	fcc42703          	lw	a4,-52(s0)
    80002da4:	fce7efe3          	bltu	a5,a4,80002d82 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002da8:	00014517          	auipc	a0,0x14
    80002dac:	32850513          	addi	a0,a0,808 # 800170d0 <tickslock>
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	f1e080e7          	jalr	-226(ra) # 80000cce <release>
  return 0;
    80002db8:	4781                	li	a5,0
}
    80002dba:	853e                	mv	a0,a5
    80002dbc:	70e2                	ld	ra,56(sp)
    80002dbe:	7442                	ld	s0,48(sp)
    80002dc0:	74a2                	ld	s1,40(sp)
    80002dc2:	7902                	ld	s2,32(sp)
    80002dc4:	69e2                	ld	s3,24(sp)
    80002dc6:	6121                	addi	sp,sp,64
    80002dc8:	8082                	ret
      release(&tickslock);
    80002dca:	00014517          	auipc	a0,0x14
    80002dce:	30650513          	addi	a0,a0,774 # 800170d0 <tickslock>
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	efc080e7          	jalr	-260(ra) # 80000cce <release>
      return -1;
    80002dda:	57fd                	li	a5,-1
    80002ddc:	bff9                	j	80002dba <sys_sleep+0x88>

0000000080002dde <sys_kill>:

uint64
sys_kill(void)
{
    80002dde:	1101                	addi	sp,sp,-32
    80002de0:	ec06                	sd	ra,24(sp)
    80002de2:	e822                	sd	s0,16(sp)
    80002de4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002de6:	fec40593          	addi	a1,s0,-20
    80002dea:	4501                	li	a0,0
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	dce080e7          	jalr	-562(ra) # 80002bba <argint>
    80002df4:	87aa                	mv	a5,a0
    return -1;
    80002df6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002df8:	0007c863          	bltz	a5,80002e08 <sys_kill+0x2a>
  return kill(pid);
    80002dfc:	fec42503          	lw	a0,-20(s0)
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	5ac080e7          	jalr	1452(ra) # 800023ac <kill>
}
    80002e08:	60e2                	ld	ra,24(sp)
    80002e0a:	6442                	ld	s0,16(sp)
    80002e0c:	6105                	addi	sp,sp,32
    80002e0e:	8082                	ret

0000000080002e10 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e10:	1101                	addi	sp,sp,-32
    80002e12:	ec06                	sd	ra,24(sp)
    80002e14:	e822                	sd	s0,16(sp)
    80002e16:	e426                	sd	s1,8(sp)
    80002e18:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e1a:	00014517          	auipc	a0,0x14
    80002e1e:	2b650513          	addi	a0,a0,694 # 800170d0 <tickslock>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	df8080e7          	jalr	-520(ra) # 80000c1a <acquire>
  xticks = ticks;
    80002e2a:	00006497          	auipc	s1,0x6
    80002e2e:	2064a483          	lw	s1,518(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e32:	00014517          	auipc	a0,0x14
    80002e36:	29e50513          	addi	a0,a0,670 # 800170d0 <tickslock>
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	e94080e7          	jalr	-364(ra) # 80000cce <release>
  return xticks;
}
    80002e42:	02049513          	slli	a0,s1,0x20
    80002e46:	9101                	srli	a0,a0,0x20
    80002e48:	60e2                	ld	ra,24(sp)
    80002e4a:	6442                	ld	s0,16(sp)
    80002e4c:	64a2                	ld	s1,8(sp)
    80002e4e:	6105                	addi	sp,sp,32
    80002e50:	8082                	ret

0000000080002e52 <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    80002e52:	1101                	addi	sp,sp,-32
    80002e54:	ec06                	sd	ra,24(sp)
    80002e56:	e822                	sd	s0,16(sp)
    80002e58:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    80002e5a:	fe840593          	addi	a1,s0,-24
    80002e5e:	4501                	li	a0,0
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	d7c080e7          	jalr	-644(ra) # 80002bdc <argaddr>
    80002e68:	87aa                	mv	a5,a0
    return -1;
    80002e6a:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80002e6c:	0007c863          	bltz	a5,80002e7c <sys_getprocs+0x2a>
  return(procinfo(addr));
    80002e70:	fe843503          	ld	a0,-24(s0)
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	706080e7          	jalr	1798(ra) # 8000257a <procinfo>
}
    80002e7c:	60e2                	ld	ra,24(sp)
    80002e7e:	6442                	ld	s0,16(sp)
    80002e80:	6105                	addi	sp,sp,32
    80002e82:	8082                	ret

0000000080002e84 <sys_freepmem>:

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
    80002e84:	1141                	addi	sp,sp,-16
    80002e86:	e406                	sd	ra,8(sp)
    80002e88:	e022                	sd	s0,0(sp)
    80002e8a:	0800                	addi	s0,sp,16
  int res = freepmem();
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	cb4080e7          	jalr	-844(ra) # 80000b40 <freepmem>
  return res;
}
    80002e94:	2501                	sext.w	a0,a0
    80002e96:	60a2                	ld	ra,8(sp)
    80002e98:	6402                	ld	s0,0(sp)
    80002e9a:	0141                	addi	sp,sp,16
    80002e9c:	8082                	ret

0000000080002e9e <sys_sbrk>:

// HW 4 - Task 2
// system call to allocate VIRTUAL memory on the disk
uint64
sys_sbrk(void){
    80002e9e:	7179                	addi	sp,sp,-48
    80002ea0:	f406                	sd	ra,40(sp)
    80002ea2:	f022                	sd	s0,32(sp)
    80002ea4:	ec26                	sd	s1,24(sp)
    80002ea6:	e84a                	sd	s2,16(sp)
    80002ea8:	1800                	addi	s0,sp,48
  int new_size;
  int increment;

  // Retrieve the first system call argument, which is the number 
  // of bytes to increase the heap by, and store it in 'increment'
  if(argint(0, &increment) < 0){
    80002eaa:	fdc40593          	addi	a1,s0,-36
    80002eae:	4501                	li	a0,0
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	d0a080e7          	jalr	-758(ra) # 80002bba <argint>
    80002eb8:	87aa                	mv	a5,a0
    return -1;
    80002eba:	557d                	li	a0,-1
  if(argint(0, &increment) < 0){
    80002ebc:	0207c263          	bltz	a5,80002ee0 <sys_sbrk+0x42>
  }

  // Get the current size of the process's heap from its process structure.]
  curr_size = myproc()->sz;
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	af6080e7          	jalr	-1290(ra) # 800019b6 <myproc>
    80002ec8:	4524                	lw	s1,72(a0)

  // Calculate the new size of the heap by adding 'increment' to the current size
  new_size = curr_size + increment;
    80002eca:	fdc42903          	lw	s2,-36(s0)
    80002ece:	0099093b          	addw	s2,s2,s1

  // Check if the new size is below a memory safety threshold ('TRAPFRAME')
  // This is to ensure the heap does not overlap with the trap frame
  if(new_size < TRAPFRAME){
    // If the new size is valid, update the process's heap size to -> new_size
    myproc()->sz = new_size;
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	ae4080e7          	jalr	-1308(ra) # 800019b6 <myproc>
    80002eda:	05253423          	sd	s2,72(a0)
    
    // Return the old heap end address before the increment
    return curr_size;
    80002ede:	8526                	mv	a0,s1
  }

  // If the new size is not valid or exceeds the memory safety threshold
  return -1;
}
    80002ee0:	70a2                	ld	ra,40(sp)
    80002ee2:	7402                	ld	s0,32(sp)
    80002ee4:	64e2                	ld	s1,24(sp)
    80002ee6:	6942                	ld	s2,16(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret

0000000080002eec <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eec:	7179                	addi	sp,sp,-48
    80002eee:	f406                	sd	ra,40(sp)
    80002ef0:	f022                	sd	s0,32(sp)
    80002ef2:	ec26                	sd	s1,24(sp)
    80002ef4:	e84a                	sd	s2,16(sp)
    80002ef6:	e44e                	sd	s3,8(sp)
    80002ef8:	e052                	sd	s4,0(sp)
    80002efa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002efc:	00005597          	auipc	a1,0x5
    80002f00:	63c58593          	addi	a1,a1,1596 # 80008538 <syscalls+0xc0>
    80002f04:	00014517          	auipc	a0,0x14
    80002f08:	1e450513          	addi	a0,a0,484 # 800170e8 <bcache>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	c7e080e7          	jalr	-898(ra) # 80000b8a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f14:	0001c797          	auipc	a5,0x1c
    80002f18:	1d478793          	addi	a5,a5,468 # 8001f0e8 <bcache+0x8000>
    80002f1c:	0001c717          	auipc	a4,0x1c
    80002f20:	43470713          	addi	a4,a4,1076 # 8001f350 <bcache+0x8268>
    80002f24:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f28:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f2c:	00014497          	auipc	s1,0x14
    80002f30:	1d448493          	addi	s1,s1,468 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f34:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f36:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f38:	00005a17          	auipc	s4,0x5
    80002f3c:	608a0a13          	addi	s4,s4,1544 # 80008540 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f40:	2b893783          	ld	a5,696(s2)
    80002f44:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f46:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f4a:	85d2                	mv	a1,s4
    80002f4c:	01048513          	addi	a0,s1,16
    80002f50:	00001097          	auipc	ra,0x1
    80002f54:	4c2080e7          	jalr	1218(ra) # 80004412 <initsleeplock>
    bcache.head.next->prev = b;
    80002f58:	2b893783          	ld	a5,696(s2)
    80002f5c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f5e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f62:	45848493          	addi	s1,s1,1112
    80002f66:	fd349de3          	bne	s1,s3,80002f40 <binit+0x54>
  }
}
    80002f6a:	70a2                	ld	ra,40(sp)
    80002f6c:	7402                	ld	s0,32(sp)
    80002f6e:	64e2                	ld	s1,24(sp)
    80002f70:	6942                	ld	s2,16(sp)
    80002f72:	69a2                	ld	s3,8(sp)
    80002f74:	6a02                	ld	s4,0(sp)
    80002f76:	6145                	addi	sp,sp,48
    80002f78:	8082                	ret

0000000080002f7a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f7a:	7179                	addi	sp,sp,-48
    80002f7c:	f406                	sd	ra,40(sp)
    80002f7e:	f022                	sd	s0,32(sp)
    80002f80:	ec26                	sd	s1,24(sp)
    80002f82:	e84a                	sd	s2,16(sp)
    80002f84:	e44e                	sd	s3,8(sp)
    80002f86:	1800                	addi	s0,sp,48
    80002f88:	892a                	mv	s2,a0
    80002f8a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f8c:	00014517          	auipc	a0,0x14
    80002f90:	15c50513          	addi	a0,a0,348 # 800170e8 <bcache>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	c86080e7          	jalr	-890(ra) # 80000c1a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f9c:	0001c497          	auipc	s1,0x1c
    80002fa0:	4044b483          	ld	s1,1028(s1) # 8001f3a0 <bcache+0x82b8>
    80002fa4:	0001c797          	auipc	a5,0x1c
    80002fa8:	3ac78793          	addi	a5,a5,940 # 8001f350 <bcache+0x8268>
    80002fac:	02f48f63          	beq	s1,a5,80002fea <bread+0x70>
    80002fb0:	873e                	mv	a4,a5
    80002fb2:	a021                	j	80002fba <bread+0x40>
    80002fb4:	68a4                	ld	s1,80(s1)
    80002fb6:	02e48a63          	beq	s1,a4,80002fea <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fba:	449c                	lw	a5,8(s1)
    80002fbc:	ff279ce3          	bne	a5,s2,80002fb4 <bread+0x3a>
    80002fc0:	44dc                	lw	a5,12(s1)
    80002fc2:	ff3799e3          	bne	a5,s3,80002fb4 <bread+0x3a>
      b->refcnt++;
    80002fc6:	40bc                	lw	a5,64(s1)
    80002fc8:	2785                	addiw	a5,a5,1
    80002fca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	11c50513          	addi	a0,a0,284 # 800170e8 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	cfa080e7          	jalr	-774(ra) # 80000cce <release>
      acquiresleep(&b->lock);
    80002fdc:	01048513          	addi	a0,s1,16
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	46c080e7          	jalr	1132(ra) # 8000444c <acquiresleep>
      return b;
    80002fe8:	a8b9                	j	80003046 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fea:	0001c497          	auipc	s1,0x1c
    80002fee:	3ae4b483          	ld	s1,942(s1) # 8001f398 <bcache+0x82b0>
    80002ff2:	0001c797          	auipc	a5,0x1c
    80002ff6:	35e78793          	addi	a5,a5,862 # 8001f350 <bcache+0x8268>
    80002ffa:	00f48863          	beq	s1,a5,8000300a <bread+0x90>
    80002ffe:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003000:	40bc                	lw	a5,64(s1)
    80003002:	cf81                	beqz	a5,8000301a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003004:	64a4                	ld	s1,72(s1)
    80003006:	fee49de3          	bne	s1,a4,80003000 <bread+0x86>
  panic("bget: no buffers");
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	53e50513          	addi	a0,a0,1342 # 80008548 <syscalls+0xd0>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	528080e7          	jalr	1320(ra) # 8000053a <panic>
      b->dev = dev;
    8000301a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000301e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003022:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003026:	4785                	li	a5,1
    80003028:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	0be50513          	addi	a0,a0,190 # 800170e8 <bcache>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c9c080e7          	jalr	-868(ra) # 80000cce <release>
      acquiresleep(&b->lock);
    8000303a:	01048513          	addi	a0,s1,16
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	40e080e7          	jalr	1038(ra) # 8000444c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003046:	409c                	lw	a5,0(s1)
    80003048:	cb89                	beqz	a5,8000305a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000304a:	8526                	mv	a0,s1
    8000304c:	70a2                	ld	ra,40(sp)
    8000304e:	7402                	ld	s0,32(sp)
    80003050:	64e2                	ld	s1,24(sp)
    80003052:	6942                	ld	s2,16(sp)
    80003054:	69a2                	ld	s3,8(sp)
    80003056:	6145                	addi	sp,sp,48
    80003058:	8082                	ret
    virtio_disk_rw(b, 0);
    8000305a:	4581                	li	a1,0
    8000305c:	8526                	mv	a0,s1
    8000305e:	00003097          	auipc	ra,0x3
    80003062:	f24080e7          	jalr	-220(ra) # 80005f82 <virtio_disk_rw>
    b->valid = 1;
    80003066:	4785                	li	a5,1
    80003068:	c09c                	sw	a5,0(s1)
  return b;
    8000306a:	b7c5                	j	8000304a <bread+0xd0>

000000008000306c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	e426                	sd	s1,8(sp)
    80003074:	1000                	addi	s0,sp,32
    80003076:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003078:	0541                	addi	a0,a0,16
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	46c080e7          	jalr	1132(ra) # 800044e6 <holdingsleep>
    80003082:	cd01                	beqz	a0,8000309a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003084:	4585                	li	a1,1
    80003086:	8526                	mv	a0,s1
    80003088:	00003097          	auipc	ra,0x3
    8000308c:	efa080e7          	jalr	-262(ra) # 80005f82 <virtio_disk_rw>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret
    panic("bwrite");
    8000309a:	00005517          	auipc	a0,0x5
    8000309e:	4c650513          	addi	a0,a0,1222 # 80008560 <syscalls+0xe8>
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	498080e7          	jalr	1176(ra) # 8000053a <panic>

00000000800030aa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030aa:	1101                	addi	sp,sp,-32
    800030ac:	ec06                	sd	ra,24(sp)
    800030ae:	e822                	sd	s0,16(sp)
    800030b0:	e426                	sd	s1,8(sp)
    800030b2:	e04a                	sd	s2,0(sp)
    800030b4:	1000                	addi	s0,sp,32
    800030b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b8:	01050913          	addi	s2,a0,16
    800030bc:	854a                	mv	a0,s2
    800030be:	00001097          	auipc	ra,0x1
    800030c2:	428080e7          	jalr	1064(ra) # 800044e6 <holdingsleep>
    800030c6:	c92d                	beqz	a0,80003138 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030c8:	854a                	mv	a0,s2
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	3d8080e7          	jalr	984(ra) # 800044a2 <releasesleep>

  acquire(&bcache.lock);
    800030d2:	00014517          	auipc	a0,0x14
    800030d6:	01650513          	addi	a0,a0,22 # 800170e8 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	b40080e7          	jalr	-1216(ra) # 80000c1a <acquire>
  b->refcnt--;
    800030e2:	40bc                	lw	a5,64(s1)
    800030e4:	37fd                	addiw	a5,a5,-1
    800030e6:	0007871b          	sext.w	a4,a5
    800030ea:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ec:	eb05                	bnez	a4,8000311c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ee:	68bc                	ld	a5,80(s1)
    800030f0:	64b8                	ld	a4,72(s1)
    800030f2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030f4:	64bc                	ld	a5,72(s1)
    800030f6:	68b8                	ld	a4,80(s1)
    800030f8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030fa:	0001c797          	auipc	a5,0x1c
    800030fe:	fee78793          	addi	a5,a5,-18 # 8001f0e8 <bcache+0x8000>
    80003102:	2b87b703          	ld	a4,696(a5)
    80003106:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003108:	0001c717          	auipc	a4,0x1c
    8000310c:	24870713          	addi	a4,a4,584 # 8001f350 <bcache+0x8268>
    80003110:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003112:	2b87b703          	ld	a4,696(a5)
    80003116:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003118:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000311c:	00014517          	auipc	a0,0x14
    80003120:	fcc50513          	addi	a0,a0,-52 # 800170e8 <bcache>
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	baa080e7          	jalr	-1110(ra) # 80000cce <release>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6902                	ld	s2,0(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret
    panic("brelse");
    80003138:	00005517          	auipc	a0,0x5
    8000313c:	43050513          	addi	a0,a0,1072 # 80008568 <syscalls+0xf0>
    80003140:	ffffd097          	auipc	ra,0xffffd
    80003144:	3fa080e7          	jalr	1018(ra) # 8000053a <panic>

0000000080003148 <bpin>:

void
bpin(struct buf *b) {
    80003148:	1101                	addi	sp,sp,-32
    8000314a:	ec06                	sd	ra,24(sp)
    8000314c:	e822                	sd	s0,16(sp)
    8000314e:	e426                	sd	s1,8(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003154:	00014517          	auipc	a0,0x14
    80003158:	f9450513          	addi	a0,a0,-108 # 800170e8 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	abe080e7          	jalr	-1346(ra) # 80000c1a <acquire>
  b->refcnt++;
    80003164:	40bc                	lw	a5,64(s1)
    80003166:	2785                	addiw	a5,a5,1
    80003168:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000316a:	00014517          	auipc	a0,0x14
    8000316e:	f7e50513          	addi	a0,a0,-130 # 800170e8 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	b5c080e7          	jalr	-1188(ra) # 80000cce <release>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret

0000000080003184 <bunpin>:

void
bunpin(struct buf *b) {
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003190:	00014517          	auipc	a0,0x14
    80003194:	f5850513          	addi	a0,a0,-168 # 800170e8 <bcache>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	a82080e7          	jalr	-1406(ra) # 80000c1a <acquire>
  b->refcnt--;
    800031a0:	40bc                	lw	a5,64(s1)
    800031a2:	37fd                	addiw	a5,a5,-1
    800031a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a6:	00014517          	auipc	a0,0x14
    800031aa:	f4250513          	addi	a0,a0,-190 # 800170e8 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	b20080e7          	jalr	-1248(ra) # 80000cce <release>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret

00000000800031c0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	e04a                	sd	s2,0(sp)
    800031ca:	1000                	addi	s0,sp,32
    800031cc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ce:	00d5d59b          	srliw	a1,a1,0xd
    800031d2:	0001c797          	auipc	a5,0x1c
    800031d6:	5f27a783          	lw	a5,1522(a5) # 8001f7c4 <sb+0x1c>
    800031da:	9dbd                	addw	a1,a1,a5
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	d9e080e7          	jalr	-610(ra) # 80002f7a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031e4:	0074f713          	andi	a4,s1,7
    800031e8:	4785                	li	a5,1
    800031ea:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ee:	14ce                	slli	s1,s1,0x33
    800031f0:	90d9                	srli	s1,s1,0x36
    800031f2:	00950733          	add	a4,a0,s1
    800031f6:	05874703          	lbu	a4,88(a4)
    800031fa:	00e7f6b3          	and	a3,a5,a4
    800031fe:	c69d                	beqz	a3,8000322c <bfree+0x6c>
    80003200:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003202:	94aa                	add	s1,s1,a0
    80003204:	fff7c793          	not	a5,a5
    80003208:	8f7d                	and	a4,a4,a5
    8000320a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000320e:	00001097          	auipc	ra,0x1
    80003212:	120080e7          	jalr	288(ra) # 8000432e <log_write>
  brelse(bp);
    80003216:	854a                	mv	a0,s2
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	e92080e7          	jalr	-366(ra) # 800030aa <brelse>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6902                	ld	s2,0(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret
    panic("freeing free block");
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	34450513          	addi	a0,a0,836 # 80008570 <syscalls+0xf8>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	306080e7          	jalr	774(ra) # 8000053a <panic>

000000008000323c <balloc>:
{
    8000323c:	711d                	addi	sp,sp,-96
    8000323e:	ec86                	sd	ra,88(sp)
    80003240:	e8a2                	sd	s0,80(sp)
    80003242:	e4a6                	sd	s1,72(sp)
    80003244:	e0ca                	sd	s2,64(sp)
    80003246:	fc4e                	sd	s3,56(sp)
    80003248:	f852                	sd	s4,48(sp)
    8000324a:	f456                	sd	s5,40(sp)
    8000324c:	f05a                	sd	s6,32(sp)
    8000324e:	ec5e                	sd	s7,24(sp)
    80003250:	e862                	sd	s8,16(sp)
    80003252:	e466                	sd	s9,8(sp)
    80003254:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003256:	0001c797          	auipc	a5,0x1c
    8000325a:	5567a783          	lw	a5,1366(a5) # 8001f7ac <sb+0x4>
    8000325e:	cbc1                	beqz	a5,800032ee <balloc+0xb2>
    80003260:	8baa                	mv	s7,a0
    80003262:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003264:	0001cb17          	auipc	s6,0x1c
    80003268:	544b0b13          	addi	s6,s6,1348 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000326e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003272:	6c89                	lui	s9,0x2
    80003274:	a831                	j	80003290 <balloc+0x54>
    brelse(bp);
    80003276:	854a                	mv	a0,s2
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	e32080e7          	jalr	-462(ra) # 800030aa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003280:	015c87bb          	addw	a5,s9,s5
    80003284:	00078a9b          	sext.w	s5,a5
    80003288:	004b2703          	lw	a4,4(s6)
    8000328c:	06eaf163          	bgeu	s5,a4,800032ee <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003290:	41fad79b          	sraiw	a5,s5,0x1f
    80003294:	0137d79b          	srliw	a5,a5,0x13
    80003298:	015787bb          	addw	a5,a5,s5
    8000329c:	40d7d79b          	sraiw	a5,a5,0xd
    800032a0:	01cb2583          	lw	a1,28(s6)
    800032a4:	9dbd                	addw	a1,a1,a5
    800032a6:	855e                	mv	a0,s7
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	cd2080e7          	jalr	-814(ra) # 80002f7a <bread>
    800032b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b2:	004b2503          	lw	a0,4(s6)
    800032b6:	000a849b          	sext.w	s1,s5
    800032ba:	8762                	mv	a4,s8
    800032bc:	faa4fde3          	bgeu	s1,a0,80003276 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032c0:	00777693          	andi	a3,a4,7
    800032c4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032c8:	41f7579b          	sraiw	a5,a4,0x1f
    800032cc:	01d7d79b          	srliw	a5,a5,0x1d
    800032d0:	9fb9                	addw	a5,a5,a4
    800032d2:	4037d79b          	sraiw	a5,a5,0x3
    800032d6:	00f90633          	add	a2,s2,a5
    800032da:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800032de:	00c6f5b3          	and	a1,a3,a2
    800032e2:	cd91                	beqz	a1,800032fe <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e4:	2705                	addiw	a4,a4,1
    800032e6:	2485                	addiw	s1,s1,1
    800032e8:	fd471ae3          	bne	a4,s4,800032bc <balloc+0x80>
    800032ec:	b769                	j	80003276 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032ee:	00005517          	auipc	a0,0x5
    800032f2:	29a50513          	addi	a0,a0,666 # 80008588 <syscalls+0x110>
    800032f6:	ffffd097          	auipc	ra,0xffffd
    800032fa:	244080e7          	jalr	580(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032fe:	97ca                	add	a5,a5,s2
    80003300:	8e55                	or	a2,a2,a3
    80003302:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003306:	854a                	mv	a0,s2
    80003308:	00001097          	auipc	ra,0x1
    8000330c:	026080e7          	jalr	38(ra) # 8000432e <log_write>
        brelse(bp);
    80003310:	854a                	mv	a0,s2
    80003312:	00000097          	auipc	ra,0x0
    80003316:	d98080e7          	jalr	-616(ra) # 800030aa <brelse>
  bp = bread(dev, bno);
    8000331a:	85a6                	mv	a1,s1
    8000331c:	855e                	mv	a0,s7
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	c5c080e7          	jalr	-932(ra) # 80002f7a <bread>
    80003326:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003328:	40000613          	li	a2,1024
    8000332c:	4581                	li	a1,0
    8000332e:	05850513          	addi	a0,a0,88
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	9e4080e7          	jalr	-1564(ra) # 80000d16 <memset>
  log_write(bp);
    8000333a:	854a                	mv	a0,s2
    8000333c:	00001097          	auipc	ra,0x1
    80003340:	ff2080e7          	jalr	-14(ra) # 8000432e <log_write>
  brelse(bp);
    80003344:	854a                	mv	a0,s2
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	d64080e7          	jalr	-668(ra) # 800030aa <brelse>
}
    8000334e:	8526                	mv	a0,s1
    80003350:	60e6                	ld	ra,88(sp)
    80003352:	6446                	ld	s0,80(sp)
    80003354:	64a6                	ld	s1,72(sp)
    80003356:	6906                	ld	s2,64(sp)
    80003358:	79e2                	ld	s3,56(sp)
    8000335a:	7a42                	ld	s4,48(sp)
    8000335c:	7aa2                	ld	s5,40(sp)
    8000335e:	7b02                	ld	s6,32(sp)
    80003360:	6be2                	ld	s7,24(sp)
    80003362:	6c42                	ld	s8,16(sp)
    80003364:	6ca2                	ld	s9,8(sp)
    80003366:	6125                	addi	sp,sp,96
    80003368:	8082                	ret

000000008000336a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000336a:	7179                	addi	sp,sp,-48
    8000336c:	f406                	sd	ra,40(sp)
    8000336e:	f022                	sd	s0,32(sp)
    80003370:	ec26                	sd	s1,24(sp)
    80003372:	e84a                	sd	s2,16(sp)
    80003374:	e44e                	sd	s3,8(sp)
    80003376:	e052                	sd	s4,0(sp)
    80003378:	1800                	addi	s0,sp,48
    8000337a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000337c:	47ad                	li	a5,11
    8000337e:	04b7fe63          	bgeu	a5,a1,800033da <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003382:	ff45849b          	addiw	s1,a1,-12
    80003386:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000338a:	0ff00793          	li	a5,255
    8000338e:	0ae7e463          	bltu	a5,a4,80003436 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003392:	08052583          	lw	a1,128(a0)
    80003396:	c5b5                	beqz	a1,80003402 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003398:	00092503          	lw	a0,0(s2)
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	bde080e7          	jalr	-1058(ra) # 80002f7a <bread>
    800033a4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033a6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033aa:	02049713          	slli	a4,s1,0x20
    800033ae:	01e75593          	srli	a1,a4,0x1e
    800033b2:	00b784b3          	add	s1,a5,a1
    800033b6:	0004a983          	lw	s3,0(s1)
    800033ba:	04098e63          	beqz	s3,80003416 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033be:	8552                	mv	a0,s4
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	cea080e7          	jalr	-790(ra) # 800030aa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033c8:	854e                	mv	a0,s3
    800033ca:	70a2                	ld	ra,40(sp)
    800033cc:	7402                	ld	s0,32(sp)
    800033ce:	64e2                	ld	s1,24(sp)
    800033d0:	6942                	ld	s2,16(sp)
    800033d2:	69a2                	ld	s3,8(sp)
    800033d4:	6a02                	ld	s4,0(sp)
    800033d6:	6145                	addi	sp,sp,48
    800033d8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033da:	02059793          	slli	a5,a1,0x20
    800033de:	01e7d593          	srli	a1,a5,0x1e
    800033e2:	00b504b3          	add	s1,a0,a1
    800033e6:	0504a983          	lw	s3,80(s1)
    800033ea:	fc099fe3          	bnez	s3,800033c8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ee:	4108                	lw	a0,0(a0)
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e4c080e7          	jalr	-436(ra) # 8000323c <balloc>
    800033f8:	0005099b          	sext.w	s3,a0
    800033fc:	0534a823          	sw	s3,80(s1)
    80003400:	b7e1                	j	800033c8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003402:	4108                	lw	a0,0(a0)
    80003404:	00000097          	auipc	ra,0x0
    80003408:	e38080e7          	jalr	-456(ra) # 8000323c <balloc>
    8000340c:	0005059b          	sext.w	a1,a0
    80003410:	08b92023          	sw	a1,128(s2)
    80003414:	b751                	j	80003398 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003416:	00092503          	lw	a0,0(s2)
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e22080e7          	jalr	-478(ra) # 8000323c <balloc>
    80003422:	0005099b          	sext.w	s3,a0
    80003426:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000342a:	8552                	mv	a0,s4
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	f02080e7          	jalr	-254(ra) # 8000432e <log_write>
    80003434:	b769                	j	800033be <bmap+0x54>
  panic("bmap: out of range");
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	16a50513          	addi	a0,a0,362 # 800085a0 <syscalls+0x128>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	0fc080e7          	jalr	252(ra) # 8000053a <panic>

0000000080003446 <iget>:
{
    80003446:	7179                	addi	sp,sp,-48
    80003448:	f406                	sd	ra,40(sp)
    8000344a:	f022                	sd	s0,32(sp)
    8000344c:	ec26                	sd	s1,24(sp)
    8000344e:	e84a                	sd	s2,16(sp)
    80003450:	e44e                	sd	s3,8(sp)
    80003452:	e052                	sd	s4,0(sp)
    80003454:	1800                	addi	s0,sp,48
    80003456:	89aa                	mv	s3,a0
    80003458:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000345a:	0001c517          	auipc	a0,0x1c
    8000345e:	36e50513          	addi	a0,a0,878 # 8001f7c8 <itable>
    80003462:	ffffd097          	auipc	ra,0xffffd
    80003466:	7b8080e7          	jalr	1976(ra) # 80000c1a <acquire>
  empty = 0;
    8000346a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000346c:	0001c497          	auipc	s1,0x1c
    80003470:	37448493          	addi	s1,s1,884 # 8001f7e0 <itable+0x18>
    80003474:	0001e697          	auipc	a3,0x1e
    80003478:	dfc68693          	addi	a3,a3,-516 # 80021270 <log>
    8000347c:	a039                	j	8000348a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000347e:	02090b63          	beqz	s2,800034b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003482:	08848493          	addi	s1,s1,136
    80003486:	02d48a63          	beq	s1,a3,800034ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000348a:	449c                	lw	a5,8(s1)
    8000348c:	fef059e3          	blez	a5,8000347e <iget+0x38>
    80003490:	4098                	lw	a4,0(s1)
    80003492:	ff3716e3          	bne	a4,s3,8000347e <iget+0x38>
    80003496:	40d8                	lw	a4,4(s1)
    80003498:	ff4713e3          	bne	a4,s4,8000347e <iget+0x38>
      ip->ref++;
    8000349c:	2785                	addiw	a5,a5,1
    8000349e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034a0:	0001c517          	auipc	a0,0x1c
    800034a4:	32850513          	addi	a0,a0,808 # 8001f7c8 <itable>
    800034a8:	ffffe097          	auipc	ra,0xffffe
    800034ac:	826080e7          	jalr	-2010(ra) # 80000cce <release>
      return ip;
    800034b0:	8926                	mv	s2,s1
    800034b2:	a03d                	j	800034e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b4:	f7f9                	bnez	a5,80003482 <iget+0x3c>
    800034b6:	8926                	mv	s2,s1
    800034b8:	b7e9                	j	80003482 <iget+0x3c>
  if(empty == 0)
    800034ba:	02090c63          	beqz	s2,800034f2 <iget+0xac>
  ip->dev = dev;
    800034be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034c6:	4785                	li	a5,1
    800034c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034d0:	0001c517          	auipc	a0,0x1c
    800034d4:	2f850513          	addi	a0,a0,760 # 8001f7c8 <itable>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	7f6080e7          	jalr	2038(ra) # 80000cce <release>
}
    800034e0:	854a                	mv	a0,s2
    800034e2:	70a2                	ld	ra,40(sp)
    800034e4:	7402                	ld	s0,32(sp)
    800034e6:	64e2                	ld	s1,24(sp)
    800034e8:	6942                	ld	s2,16(sp)
    800034ea:	69a2                	ld	s3,8(sp)
    800034ec:	6a02                	ld	s4,0(sp)
    800034ee:	6145                	addi	sp,sp,48
    800034f0:	8082                	ret
    panic("iget: no inodes");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	0c650513          	addi	a0,a0,198 # 800085b8 <syscalls+0x140>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	040080e7          	jalr	64(ra) # 8000053a <panic>

0000000080003502 <fsinit>:
fsinit(int dev) {
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	e84a                	sd	s2,16(sp)
    8000350c:	e44e                	sd	s3,8(sp)
    8000350e:	1800                	addi	s0,sp,48
    80003510:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003512:	4585                	li	a1,1
    80003514:	00000097          	auipc	ra,0x0
    80003518:	a66080e7          	jalr	-1434(ra) # 80002f7a <bread>
    8000351c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000351e:	0001c997          	auipc	s3,0x1c
    80003522:	28a98993          	addi	s3,s3,650 # 8001f7a8 <sb>
    80003526:	02000613          	li	a2,32
    8000352a:	05850593          	addi	a1,a0,88
    8000352e:	854e                	mv	a0,s3
    80003530:	ffffe097          	auipc	ra,0xffffe
    80003534:	842080e7          	jalr	-1982(ra) # 80000d72 <memmove>
  brelse(bp);
    80003538:	8526                	mv	a0,s1
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	b70080e7          	jalr	-1168(ra) # 800030aa <brelse>
  if(sb.magic != FSMAGIC)
    80003542:	0009a703          	lw	a4,0(s3)
    80003546:	102037b7          	lui	a5,0x10203
    8000354a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000354e:	02f71263          	bne	a4,a5,80003572 <fsinit+0x70>
  initlog(dev, &sb);
    80003552:	0001c597          	auipc	a1,0x1c
    80003556:	25658593          	addi	a1,a1,598 # 8001f7a8 <sb>
    8000355a:	854a                	mv	a0,s2
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	b56080e7          	jalr	-1194(ra) # 800040b2 <initlog>
}
    80003564:	70a2                	ld	ra,40(sp)
    80003566:	7402                	ld	s0,32(sp)
    80003568:	64e2                	ld	s1,24(sp)
    8000356a:	6942                	ld	s2,16(sp)
    8000356c:	69a2                	ld	s3,8(sp)
    8000356e:	6145                	addi	sp,sp,48
    80003570:	8082                	ret
    panic("invalid file system");
    80003572:	00005517          	auipc	a0,0x5
    80003576:	05650513          	addi	a0,a0,86 # 800085c8 <syscalls+0x150>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	fc0080e7          	jalr	-64(ra) # 8000053a <panic>

0000000080003582 <iinit>:
{
    80003582:	7179                	addi	sp,sp,-48
    80003584:	f406                	sd	ra,40(sp)
    80003586:	f022                	sd	s0,32(sp)
    80003588:	ec26                	sd	s1,24(sp)
    8000358a:	e84a                	sd	s2,16(sp)
    8000358c:	e44e                	sd	s3,8(sp)
    8000358e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003590:	00005597          	auipc	a1,0x5
    80003594:	05058593          	addi	a1,a1,80 # 800085e0 <syscalls+0x168>
    80003598:	0001c517          	auipc	a0,0x1c
    8000359c:	23050513          	addi	a0,a0,560 # 8001f7c8 <itable>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	5ea080e7          	jalr	1514(ra) # 80000b8a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035a8:	0001c497          	auipc	s1,0x1c
    800035ac:	24848493          	addi	s1,s1,584 # 8001f7f0 <itable+0x28>
    800035b0:	0001e997          	auipc	s3,0x1e
    800035b4:	cd098993          	addi	s3,s3,-816 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035b8:	00005917          	auipc	s2,0x5
    800035bc:	03090913          	addi	s2,s2,48 # 800085e8 <syscalls+0x170>
    800035c0:	85ca                	mv	a1,s2
    800035c2:	8526                	mv	a0,s1
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	e4e080e7          	jalr	-434(ra) # 80004412 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035cc:	08848493          	addi	s1,s1,136
    800035d0:	ff3498e3          	bne	s1,s3,800035c0 <iinit+0x3e>
}
    800035d4:	70a2                	ld	ra,40(sp)
    800035d6:	7402                	ld	s0,32(sp)
    800035d8:	64e2                	ld	s1,24(sp)
    800035da:	6942                	ld	s2,16(sp)
    800035dc:	69a2                	ld	s3,8(sp)
    800035de:	6145                	addi	sp,sp,48
    800035e0:	8082                	ret

00000000800035e2 <ialloc>:
{
    800035e2:	715d                	addi	sp,sp,-80
    800035e4:	e486                	sd	ra,72(sp)
    800035e6:	e0a2                	sd	s0,64(sp)
    800035e8:	fc26                	sd	s1,56(sp)
    800035ea:	f84a                	sd	s2,48(sp)
    800035ec:	f44e                	sd	s3,40(sp)
    800035ee:	f052                	sd	s4,32(sp)
    800035f0:	ec56                	sd	s5,24(sp)
    800035f2:	e85a                	sd	s6,16(sp)
    800035f4:	e45e                	sd	s7,8(sp)
    800035f6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f8:	0001c717          	auipc	a4,0x1c
    800035fc:	1bc72703          	lw	a4,444(a4) # 8001f7b4 <sb+0xc>
    80003600:	4785                	li	a5,1
    80003602:	04e7fa63          	bgeu	a5,a4,80003656 <ialloc+0x74>
    80003606:	8aaa                	mv	s5,a0
    80003608:	8bae                	mv	s7,a1
    8000360a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000360c:	0001ca17          	auipc	s4,0x1c
    80003610:	19ca0a13          	addi	s4,s4,412 # 8001f7a8 <sb>
    80003614:	00048b1b          	sext.w	s6,s1
    80003618:	0044d593          	srli	a1,s1,0x4
    8000361c:	018a2783          	lw	a5,24(s4)
    80003620:	9dbd                	addw	a1,a1,a5
    80003622:	8556                	mv	a0,s5
    80003624:	00000097          	auipc	ra,0x0
    80003628:	956080e7          	jalr	-1706(ra) # 80002f7a <bread>
    8000362c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000362e:	05850993          	addi	s3,a0,88
    80003632:	00f4f793          	andi	a5,s1,15
    80003636:	079a                	slli	a5,a5,0x6
    80003638:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000363a:	00099783          	lh	a5,0(s3)
    8000363e:	c785                	beqz	a5,80003666 <ialloc+0x84>
    brelse(bp);
    80003640:	00000097          	auipc	ra,0x0
    80003644:	a6a080e7          	jalr	-1430(ra) # 800030aa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003648:	0485                	addi	s1,s1,1
    8000364a:	00ca2703          	lw	a4,12(s4)
    8000364e:	0004879b          	sext.w	a5,s1
    80003652:	fce7e1e3          	bltu	a5,a4,80003614 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003656:	00005517          	auipc	a0,0x5
    8000365a:	f9a50513          	addi	a0,a0,-102 # 800085f0 <syscalls+0x178>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	edc080e7          	jalr	-292(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003666:	04000613          	li	a2,64
    8000366a:	4581                	li	a1,0
    8000366c:	854e                	mv	a0,s3
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	6a8080e7          	jalr	1704(ra) # 80000d16 <memset>
      dip->type = type;
    80003676:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000367a:	854a                	mv	a0,s2
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	cb2080e7          	jalr	-846(ra) # 8000432e <log_write>
      brelse(bp);
    80003684:	854a                	mv	a0,s2
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	a24080e7          	jalr	-1500(ra) # 800030aa <brelse>
      return iget(dev, inum);
    8000368e:	85da                	mv	a1,s6
    80003690:	8556                	mv	a0,s5
    80003692:	00000097          	auipc	ra,0x0
    80003696:	db4080e7          	jalr	-588(ra) # 80003446 <iget>
}
    8000369a:	60a6                	ld	ra,72(sp)
    8000369c:	6406                	ld	s0,64(sp)
    8000369e:	74e2                	ld	s1,56(sp)
    800036a0:	7942                	ld	s2,48(sp)
    800036a2:	79a2                	ld	s3,40(sp)
    800036a4:	7a02                	ld	s4,32(sp)
    800036a6:	6ae2                	ld	s5,24(sp)
    800036a8:	6b42                	ld	s6,16(sp)
    800036aa:	6ba2                	ld	s7,8(sp)
    800036ac:	6161                	addi	sp,sp,80
    800036ae:	8082                	ret

00000000800036b0 <iupdate>:
{
    800036b0:	1101                	addi	sp,sp,-32
    800036b2:	ec06                	sd	ra,24(sp)
    800036b4:	e822                	sd	s0,16(sp)
    800036b6:	e426                	sd	s1,8(sp)
    800036b8:	e04a                	sd	s2,0(sp)
    800036ba:	1000                	addi	s0,sp,32
    800036bc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036be:	415c                	lw	a5,4(a0)
    800036c0:	0047d79b          	srliw	a5,a5,0x4
    800036c4:	0001c597          	auipc	a1,0x1c
    800036c8:	0fc5a583          	lw	a1,252(a1) # 8001f7c0 <sb+0x18>
    800036cc:	9dbd                	addw	a1,a1,a5
    800036ce:	4108                	lw	a0,0(a0)
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	8aa080e7          	jalr	-1878(ra) # 80002f7a <bread>
    800036d8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036da:	05850793          	addi	a5,a0,88
    800036de:	40d8                	lw	a4,4(s1)
    800036e0:	8b3d                	andi	a4,a4,15
    800036e2:	071a                	slli	a4,a4,0x6
    800036e4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036e6:	04449703          	lh	a4,68(s1)
    800036ea:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036ee:	04649703          	lh	a4,70(s1)
    800036f2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036f6:	04849703          	lh	a4,72(s1)
    800036fa:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036fe:	04a49703          	lh	a4,74(s1)
    80003702:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003706:	44f8                	lw	a4,76(s1)
    80003708:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000370a:	03400613          	li	a2,52
    8000370e:	05048593          	addi	a1,s1,80
    80003712:	00c78513          	addi	a0,a5,12
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	65c080e7          	jalr	1628(ra) # 80000d72 <memmove>
  log_write(bp);
    8000371e:	854a                	mv	a0,s2
    80003720:	00001097          	auipc	ra,0x1
    80003724:	c0e080e7          	jalr	-1010(ra) # 8000432e <log_write>
  brelse(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	980080e7          	jalr	-1664(ra) # 800030aa <brelse>
}
    80003732:	60e2                	ld	ra,24(sp)
    80003734:	6442                	ld	s0,16(sp)
    80003736:	64a2                	ld	s1,8(sp)
    80003738:	6902                	ld	s2,0(sp)
    8000373a:	6105                	addi	sp,sp,32
    8000373c:	8082                	ret

000000008000373e <idup>:
{
    8000373e:	1101                	addi	sp,sp,-32
    80003740:	ec06                	sd	ra,24(sp)
    80003742:	e822                	sd	s0,16(sp)
    80003744:	e426                	sd	s1,8(sp)
    80003746:	1000                	addi	s0,sp,32
    80003748:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000374a:	0001c517          	auipc	a0,0x1c
    8000374e:	07e50513          	addi	a0,a0,126 # 8001f7c8 <itable>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	4c8080e7          	jalr	1224(ra) # 80000c1a <acquire>
  ip->ref++;
    8000375a:	449c                	lw	a5,8(s1)
    8000375c:	2785                	addiw	a5,a5,1
    8000375e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003760:	0001c517          	auipc	a0,0x1c
    80003764:	06850513          	addi	a0,a0,104 # 8001f7c8 <itable>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	566080e7          	jalr	1382(ra) # 80000cce <release>
}
    80003770:	8526                	mv	a0,s1
    80003772:	60e2                	ld	ra,24(sp)
    80003774:	6442                	ld	s0,16(sp)
    80003776:	64a2                	ld	s1,8(sp)
    80003778:	6105                	addi	sp,sp,32
    8000377a:	8082                	ret

000000008000377c <ilock>:
{
    8000377c:	1101                	addi	sp,sp,-32
    8000377e:	ec06                	sd	ra,24(sp)
    80003780:	e822                	sd	s0,16(sp)
    80003782:	e426                	sd	s1,8(sp)
    80003784:	e04a                	sd	s2,0(sp)
    80003786:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003788:	c115                	beqz	a0,800037ac <ilock+0x30>
    8000378a:	84aa                	mv	s1,a0
    8000378c:	451c                	lw	a5,8(a0)
    8000378e:	00f05f63          	blez	a5,800037ac <ilock+0x30>
  acquiresleep(&ip->lock);
    80003792:	0541                	addi	a0,a0,16
    80003794:	00001097          	auipc	ra,0x1
    80003798:	cb8080e7          	jalr	-840(ra) # 8000444c <acquiresleep>
  if(ip->valid == 0){
    8000379c:	40bc                	lw	a5,64(s1)
    8000379e:	cf99                	beqz	a5,800037bc <ilock+0x40>
}
    800037a0:	60e2                	ld	ra,24(sp)
    800037a2:	6442                	ld	s0,16(sp)
    800037a4:	64a2                	ld	s1,8(sp)
    800037a6:	6902                	ld	s2,0(sp)
    800037a8:	6105                	addi	sp,sp,32
    800037aa:	8082                	ret
    panic("ilock");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	e5c50513          	addi	a0,a0,-420 # 80008608 <syscalls+0x190>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	d86080e7          	jalr	-634(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037bc:	40dc                	lw	a5,4(s1)
    800037be:	0047d79b          	srliw	a5,a5,0x4
    800037c2:	0001c597          	auipc	a1,0x1c
    800037c6:	ffe5a583          	lw	a1,-2(a1) # 8001f7c0 <sb+0x18>
    800037ca:	9dbd                	addw	a1,a1,a5
    800037cc:	4088                	lw	a0,0(s1)
    800037ce:	fffff097          	auipc	ra,0xfffff
    800037d2:	7ac080e7          	jalr	1964(ra) # 80002f7a <bread>
    800037d6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037d8:	05850593          	addi	a1,a0,88
    800037dc:	40dc                	lw	a5,4(s1)
    800037de:	8bbd                	andi	a5,a5,15
    800037e0:	079a                	slli	a5,a5,0x6
    800037e2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037e4:	00059783          	lh	a5,0(a1)
    800037e8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037ec:	00259783          	lh	a5,2(a1)
    800037f0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037f4:	00459783          	lh	a5,4(a1)
    800037f8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037fc:	00659783          	lh	a5,6(a1)
    80003800:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003804:	459c                	lw	a5,8(a1)
    80003806:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003808:	03400613          	li	a2,52
    8000380c:	05b1                	addi	a1,a1,12
    8000380e:	05048513          	addi	a0,s1,80
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	560080e7          	jalr	1376(ra) # 80000d72 <memmove>
    brelse(bp);
    8000381a:	854a                	mv	a0,s2
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	88e080e7          	jalr	-1906(ra) # 800030aa <brelse>
    ip->valid = 1;
    80003824:	4785                	li	a5,1
    80003826:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003828:	04449783          	lh	a5,68(s1)
    8000382c:	fbb5                	bnez	a5,800037a0 <ilock+0x24>
      panic("ilock: no type");
    8000382e:	00005517          	auipc	a0,0x5
    80003832:	de250513          	addi	a0,a0,-542 # 80008610 <syscalls+0x198>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	d04080e7          	jalr	-764(ra) # 8000053a <panic>

000000008000383e <iunlock>:
{
    8000383e:	1101                	addi	sp,sp,-32
    80003840:	ec06                	sd	ra,24(sp)
    80003842:	e822                	sd	s0,16(sp)
    80003844:	e426                	sd	s1,8(sp)
    80003846:	e04a                	sd	s2,0(sp)
    80003848:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000384a:	c905                	beqz	a0,8000387a <iunlock+0x3c>
    8000384c:	84aa                	mv	s1,a0
    8000384e:	01050913          	addi	s2,a0,16
    80003852:	854a                	mv	a0,s2
    80003854:	00001097          	auipc	ra,0x1
    80003858:	c92080e7          	jalr	-878(ra) # 800044e6 <holdingsleep>
    8000385c:	cd19                	beqz	a0,8000387a <iunlock+0x3c>
    8000385e:	449c                	lw	a5,8(s1)
    80003860:	00f05d63          	blez	a5,8000387a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003864:	854a                	mv	a0,s2
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	c3c080e7          	jalr	-964(ra) # 800044a2 <releasesleep>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret
    panic("iunlock");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	da650513          	addi	a0,a0,-602 # 80008620 <syscalls+0x1a8>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cb8080e7          	jalr	-840(ra) # 8000053a <panic>

000000008000388a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000388a:	7179                	addi	sp,sp,-48
    8000388c:	f406                	sd	ra,40(sp)
    8000388e:	f022                	sd	s0,32(sp)
    80003890:	ec26                	sd	s1,24(sp)
    80003892:	e84a                	sd	s2,16(sp)
    80003894:	e44e                	sd	s3,8(sp)
    80003896:	e052                	sd	s4,0(sp)
    80003898:	1800                	addi	s0,sp,48
    8000389a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000389c:	05050493          	addi	s1,a0,80
    800038a0:	08050913          	addi	s2,a0,128
    800038a4:	a021                	j	800038ac <itrunc+0x22>
    800038a6:	0491                	addi	s1,s1,4
    800038a8:	01248d63          	beq	s1,s2,800038c2 <itrunc+0x38>
    if(ip->addrs[i]){
    800038ac:	408c                	lw	a1,0(s1)
    800038ae:	dde5                	beqz	a1,800038a6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038b0:	0009a503          	lw	a0,0(s3)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	90c080e7          	jalr	-1780(ra) # 800031c0 <bfree>
      ip->addrs[i] = 0;
    800038bc:	0004a023          	sw	zero,0(s1)
    800038c0:	b7dd                	j	800038a6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038c2:	0809a583          	lw	a1,128(s3)
    800038c6:	e185                	bnez	a1,800038e6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038c8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038cc:	854e                	mv	a0,s3
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	de2080e7          	jalr	-542(ra) # 800036b0 <iupdate>
}
    800038d6:	70a2                	ld	ra,40(sp)
    800038d8:	7402                	ld	s0,32(sp)
    800038da:	64e2                	ld	s1,24(sp)
    800038dc:	6942                	ld	s2,16(sp)
    800038de:	69a2                	ld	s3,8(sp)
    800038e0:	6a02                	ld	s4,0(sp)
    800038e2:	6145                	addi	sp,sp,48
    800038e4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038e6:	0009a503          	lw	a0,0(s3)
    800038ea:	fffff097          	auipc	ra,0xfffff
    800038ee:	690080e7          	jalr	1680(ra) # 80002f7a <bread>
    800038f2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038f4:	05850493          	addi	s1,a0,88
    800038f8:	45850913          	addi	s2,a0,1112
    800038fc:	a021                	j	80003904 <itrunc+0x7a>
    800038fe:	0491                	addi	s1,s1,4
    80003900:	01248b63          	beq	s1,s2,80003916 <itrunc+0x8c>
      if(a[j])
    80003904:	408c                	lw	a1,0(s1)
    80003906:	dde5                	beqz	a1,800038fe <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003908:	0009a503          	lw	a0,0(s3)
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	8b4080e7          	jalr	-1868(ra) # 800031c0 <bfree>
    80003914:	b7ed                	j	800038fe <itrunc+0x74>
    brelse(bp);
    80003916:	8552                	mv	a0,s4
    80003918:	fffff097          	auipc	ra,0xfffff
    8000391c:	792080e7          	jalr	1938(ra) # 800030aa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003920:	0809a583          	lw	a1,128(s3)
    80003924:	0009a503          	lw	a0,0(s3)
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	898080e7          	jalr	-1896(ra) # 800031c0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003930:	0809a023          	sw	zero,128(s3)
    80003934:	bf51                	j	800038c8 <itrunc+0x3e>

0000000080003936 <iput>:
{
    80003936:	1101                	addi	sp,sp,-32
    80003938:	ec06                	sd	ra,24(sp)
    8000393a:	e822                	sd	s0,16(sp)
    8000393c:	e426                	sd	s1,8(sp)
    8000393e:	e04a                	sd	s2,0(sp)
    80003940:	1000                	addi	s0,sp,32
    80003942:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003944:	0001c517          	auipc	a0,0x1c
    80003948:	e8450513          	addi	a0,a0,-380 # 8001f7c8 <itable>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	2ce080e7          	jalr	718(ra) # 80000c1a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003954:	4498                	lw	a4,8(s1)
    80003956:	4785                	li	a5,1
    80003958:	02f70363          	beq	a4,a5,8000397e <iput+0x48>
  ip->ref--;
    8000395c:	449c                	lw	a5,8(s1)
    8000395e:	37fd                	addiw	a5,a5,-1
    80003960:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003962:	0001c517          	auipc	a0,0x1c
    80003966:	e6650513          	addi	a0,a0,-410 # 8001f7c8 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	364080e7          	jalr	868(ra) # 80000cce <release>
}
    80003972:	60e2                	ld	ra,24(sp)
    80003974:	6442                	ld	s0,16(sp)
    80003976:	64a2                	ld	s1,8(sp)
    80003978:	6902                	ld	s2,0(sp)
    8000397a:	6105                	addi	sp,sp,32
    8000397c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000397e:	40bc                	lw	a5,64(s1)
    80003980:	dff1                	beqz	a5,8000395c <iput+0x26>
    80003982:	04a49783          	lh	a5,74(s1)
    80003986:	fbf9                	bnez	a5,8000395c <iput+0x26>
    acquiresleep(&ip->lock);
    80003988:	01048913          	addi	s2,s1,16
    8000398c:	854a                	mv	a0,s2
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	abe080e7          	jalr	-1346(ra) # 8000444c <acquiresleep>
    release(&itable.lock);
    80003996:	0001c517          	auipc	a0,0x1c
    8000399a:	e3250513          	addi	a0,a0,-462 # 8001f7c8 <itable>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	330080e7          	jalr	816(ra) # 80000cce <release>
    itrunc(ip);
    800039a6:	8526                	mv	a0,s1
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	ee2080e7          	jalr	-286(ra) # 8000388a <itrunc>
    ip->type = 0;
    800039b0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039b4:	8526                	mv	a0,s1
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	cfa080e7          	jalr	-774(ra) # 800036b0 <iupdate>
    ip->valid = 0;
    800039be:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039c2:	854a                	mv	a0,s2
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	ade080e7          	jalr	-1314(ra) # 800044a2 <releasesleep>
    acquire(&itable.lock);
    800039cc:	0001c517          	auipc	a0,0x1c
    800039d0:	dfc50513          	addi	a0,a0,-516 # 8001f7c8 <itable>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	246080e7          	jalr	582(ra) # 80000c1a <acquire>
    800039dc:	b741                	j	8000395c <iput+0x26>

00000000800039de <iunlockput>:
{
    800039de:	1101                	addi	sp,sp,-32
    800039e0:	ec06                	sd	ra,24(sp)
    800039e2:	e822                	sd	s0,16(sp)
    800039e4:	e426                	sd	s1,8(sp)
    800039e6:	1000                	addi	s0,sp,32
    800039e8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	e54080e7          	jalr	-428(ra) # 8000383e <iunlock>
  iput(ip);
    800039f2:	8526                	mv	a0,s1
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	f42080e7          	jalr	-190(ra) # 80003936 <iput>
}
    800039fc:	60e2                	ld	ra,24(sp)
    800039fe:	6442                	ld	s0,16(sp)
    80003a00:	64a2                	ld	s1,8(sp)
    80003a02:	6105                	addi	sp,sp,32
    80003a04:	8082                	ret

0000000080003a06 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a06:	1141                	addi	sp,sp,-16
    80003a08:	e422                	sd	s0,8(sp)
    80003a0a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a0c:	411c                	lw	a5,0(a0)
    80003a0e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a10:	415c                	lw	a5,4(a0)
    80003a12:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a14:	04451783          	lh	a5,68(a0)
    80003a18:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a1c:	04a51783          	lh	a5,74(a0)
    80003a20:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a24:	04c56783          	lwu	a5,76(a0)
    80003a28:	e99c                	sd	a5,16(a1)
}
    80003a2a:	6422                	ld	s0,8(sp)
    80003a2c:	0141                	addi	sp,sp,16
    80003a2e:	8082                	ret

0000000080003a30 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a30:	457c                	lw	a5,76(a0)
    80003a32:	0ed7e963          	bltu	a5,a3,80003b24 <readi+0xf4>
{
    80003a36:	7159                	addi	sp,sp,-112
    80003a38:	f486                	sd	ra,104(sp)
    80003a3a:	f0a2                	sd	s0,96(sp)
    80003a3c:	eca6                	sd	s1,88(sp)
    80003a3e:	e8ca                	sd	s2,80(sp)
    80003a40:	e4ce                	sd	s3,72(sp)
    80003a42:	e0d2                	sd	s4,64(sp)
    80003a44:	fc56                	sd	s5,56(sp)
    80003a46:	f85a                	sd	s6,48(sp)
    80003a48:	f45e                	sd	s7,40(sp)
    80003a4a:	f062                	sd	s8,32(sp)
    80003a4c:	ec66                	sd	s9,24(sp)
    80003a4e:	e86a                	sd	s10,16(sp)
    80003a50:	e46e                	sd	s11,8(sp)
    80003a52:	1880                	addi	s0,sp,112
    80003a54:	8baa                	mv	s7,a0
    80003a56:	8c2e                	mv	s8,a1
    80003a58:	8ab2                	mv	s5,a2
    80003a5a:	84b6                	mv	s1,a3
    80003a5c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a5e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a60:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a62:	0ad76063          	bltu	a4,a3,80003b02 <readi+0xd2>
  if(off + n > ip->size)
    80003a66:	00e7f463          	bgeu	a5,a4,80003a6e <readi+0x3e>
    n = ip->size - off;
    80003a6a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a6e:	0a0b0963          	beqz	s6,80003b20 <readi+0xf0>
    80003a72:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a74:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a78:	5cfd                	li	s9,-1
    80003a7a:	a82d                	j	80003ab4 <readi+0x84>
    80003a7c:	020a1d93          	slli	s11,s4,0x20
    80003a80:	020ddd93          	srli	s11,s11,0x20
    80003a84:	05890613          	addi	a2,s2,88
    80003a88:	86ee                	mv	a3,s11
    80003a8a:	963a                	add	a2,a2,a4
    80003a8c:	85d6                	mv	a1,s5
    80003a8e:	8562                	mv	a0,s8
    80003a90:	fffff097          	auipc	ra,0xfffff
    80003a94:	98e080e7          	jalr	-1650(ra) # 8000241e <either_copyout>
    80003a98:	05950d63          	beq	a0,s9,80003af2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	60c080e7          	jalr	1548(ra) # 800030aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa6:	013a09bb          	addw	s3,s4,s3
    80003aaa:	009a04bb          	addw	s1,s4,s1
    80003aae:	9aee                	add	s5,s5,s11
    80003ab0:	0569f763          	bgeu	s3,s6,80003afe <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ab4:	000ba903          	lw	s2,0(s7)
    80003ab8:	00a4d59b          	srliw	a1,s1,0xa
    80003abc:	855e                	mv	a0,s7
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	8ac080e7          	jalr	-1876(ra) # 8000336a <bmap>
    80003ac6:	0005059b          	sext.w	a1,a0
    80003aca:	854a                	mv	a0,s2
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	4ae080e7          	jalr	1198(ra) # 80002f7a <bread>
    80003ad4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad6:	3ff4f713          	andi	a4,s1,1023
    80003ada:	40ed07bb          	subw	a5,s10,a4
    80003ade:	413b06bb          	subw	a3,s6,s3
    80003ae2:	8a3e                	mv	s4,a5
    80003ae4:	2781                	sext.w	a5,a5
    80003ae6:	0006861b          	sext.w	a2,a3
    80003aea:	f8f679e3          	bgeu	a2,a5,80003a7c <readi+0x4c>
    80003aee:	8a36                	mv	s4,a3
    80003af0:	b771                	j	80003a7c <readi+0x4c>
      brelse(bp);
    80003af2:	854a                	mv	a0,s2
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	5b6080e7          	jalr	1462(ra) # 800030aa <brelse>
      tot = -1;
    80003afc:	59fd                	li	s3,-1
  }
  return tot;
    80003afe:	0009851b          	sext.w	a0,s3
}
    80003b02:	70a6                	ld	ra,104(sp)
    80003b04:	7406                	ld	s0,96(sp)
    80003b06:	64e6                	ld	s1,88(sp)
    80003b08:	6946                	ld	s2,80(sp)
    80003b0a:	69a6                	ld	s3,72(sp)
    80003b0c:	6a06                	ld	s4,64(sp)
    80003b0e:	7ae2                	ld	s5,56(sp)
    80003b10:	7b42                	ld	s6,48(sp)
    80003b12:	7ba2                	ld	s7,40(sp)
    80003b14:	7c02                	ld	s8,32(sp)
    80003b16:	6ce2                	ld	s9,24(sp)
    80003b18:	6d42                	ld	s10,16(sp)
    80003b1a:	6da2                	ld	s11,8(sp)
    80003b1c:	6165                	addi	sp,sp,112
    80003b1e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b20:	89da                	mv	s3,s6
    80003b22:	bff1                	j	80003afe <readi+0xce>
    return 0;
    80003b24:	4501                	li	a0,0
}
    80003b26:	8082                	ret

0000000080003b28 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b28:	457c                	lw	a5,76(a0)
    80003b2a:	10d7e863          	bltu	a5,a3,80003c3a <writei+0x112>
{
    80003b2e:	7159                	addi	sp,sp,-112
    80003b30:	f486                	sd	ra,104(sp)
    80003b32:	f0a2                	sd	s0,96(sp)
    80003b34:	eca6                	sd	s1,88(sp)
    80003b36:	e8ca                	sd	s2,80(sp)
    80003b38:	e4ce                	sd	s3,72(sp)
    80003b3a:	e0d2                	sd	s4,64(sp)
    80003b3c:	fc56                	sd	s5,56(sp)
    80003b3e:	f85a                	sd	s6,48(sp)
    80003b40:	f45e                	sd	s7,40(sp)
    80003b42:	f062                	sd	s8,32(sp)
    80003b44:	ec66                	sd	s9,24(sp)
    80003b46:	e86a                	sd	s10,16(sp)
    80003b48:	e46e                	sd	s11,8(sp)
    80003b4a:	1880                	addi	s0,sp,112
    80003b4c:	8b2a                	mv	s6,a0
    80003b4e:	8c2e                	mv	s8,a1
    80003b50:	8ab2                	mv	s5,a2
    80003b52:	8936                	mv	s2,a3
    80003b54:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b56:	00e687bb          	addw	a5,a3,a4
    80003b5a:	0ed7e263          	bltu	a5,a3,80003c3e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b5e:	00043737          	lui	a4,0x43
    80003b62:	0ef76063          	bltu	a4,a5,80003c42 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b66:	0c0b8863          	beqz	s7,80003c36 <writei+0x10e>
    80003b6a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b70:	5cfd                	li	s9,-1
    80003b72:	a091                	j	80003bb6 <writei+0x8e>
    80003b74:	02099d93          	slli	s11,s3,0x20
    80003b78:	020ddd93          	srli	s11,s11,0x20
    80003b7c:	05848513          	addi	a0,s1,88
    80003b80:	86ee                	mv	a3,s11
    80003b82:	8656                	mv	a2,s5
    80003b84:	85e2                	mv	a1,s8
    80003b86:	953a                	add	a0,a0,a4
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	8ec080e7          	jalr	-1812(ra) # 80002474 <either_copyin>
    80003b90:	07950263          	beq	a0,s9,80003bf4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b94:	8526                	mv	a0,s1
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	798080e7          	jalr	1944(ra) # 8000432e <log_write>
    brelse(bp);
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	50a080e7          	jalr	1290(ra) # 800030aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba8:	01498a3b          	addw	s4,s3,s4
    80003bac:	0129893b          	addw	s2,s3,s2
    80003bb0:	9aee                	add	s5,s5,s11
    80003bb2:	057a7663          	bgeu	s4,s7,80003bfe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bb6:	000b2483          	lw	s1,0(s6)
    80003bba:	00a9559b          	srliw	a1,s2,0xa
    80003bbe:	855a                	mv	a0,s6
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	7aa080e7          	jalr	1962(ra) # 8000336a <bmap>
    80003bc8:	0005059b          	sext.w	a1,a0
    80003bcc:	8526                	mv	a0,s1
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	3ac080e7          	jalr	940(ra) # 80002f7a <bread>
    80003bd6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd8:	3ff97713          	andi	a4,s2,1023
    80003bdc:	40ed07bb          	subw	a5,s10,a4
    80003be0:	414b86bb          	subw	a3,s7,s4
    80003be4:	89be                	mv	s3,a5
    80003be6:	2781                	sext.w	a5,a5
    80003be8:	0006861b          	sext.w	a2,a3
    80003bec:	f8f674e3          	bgeu	a2,a5,80003b74 <writei+0x4c>
    80003bf0:	89b6                	mv	s3,a3
    80003bf2:	b749                	j	80003b74 <writei+0x4c>
      brelse(bp);
    80003bf4:	8526                	mv	a0,s1
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	4b4080e7          	jalr	1204(ra) # 800030aa <brelse>
  }

  if(off > ip->size)
    80003bfe:	04cb2783          	lw	a5,76(s6)
    80003c02:	0127f463          	bgeu	a5,s2,80003c0a <writei+0xe2>
    ip->size = off;
    80003c06:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c0a:	855a                	mv	a0,s6
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	aa4080e7          	jalr	-1372(ra) # 800036b0 <iupdate>

  return tot;
    80003c14:	000a051b          	sext.w	a0,s4
}
    80003c18:	70a6                	ld	ra,104(sp)
    80003c1a:	7406                	ld	s0,96(sp)
    80003c1c:	64e6                	ld	s1,88(sp)
    80003c1e:	6946                	ld	s2,80(sp)
    80003c20:	69a6                	ld	s3,72(sp)
    80003c22:	6a06                	ld	s4,64(sp)
    80003c24:	7ae2                	ld	s5,56(sp)
    80003c26:	7b42                	ld	s6,48(sp)
    80003c28:	7ba2                	ld	s7,40(sp)
    80003c2a:	7c02                	ld	s8,32(sp)
    80003c2c:	6ce2                	ld	s9,24(sp)
    80003c2e:	6d42                	ld	s10,16(sp)
    80003c30:	6da2                	ld	s11,8(sp)
    80003c32:	6165                	addi	sp,sp,112
    80003c34:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c36:	8a5e                	mv	s4,s7
    80003c38:	bfc9                	j	80003c0a <writei+0xe2>
    return -1;
    80003c3a:	557d                	li	a0,-1
}
    80003c3c:	8082                	ret
    return -1;
    80003c3e:	557d                	li	a0,-1
    80003c40:	bfe1                	j	80003c18 <writei+0xf0>
    return -1;
    80003c42:	557d                	li	a0,-1
    80003c44:	bfd1                	j	80003c18 <writei+0xf0>

0000000080003c46 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c46:	1141                	addi	sp,sp,-16
    80003c48:	e406                	sd	ra,8(sp)
    80003c4a:	e022                	sd	s0,0(sp)
    80003c4c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c4e:	4639                	li	a2,14
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	196080e7          	jalr	406(ra) # 80000de6 <strncmp>
}
    80003c58:	60a2                	ld	ra,8(sp)
    80003c5a:	6402                	ld	s0,0(sp)
    80003c5c:	0141                	addi	sp,sp,16
    80003c5e:	8082                	ret

0000000080003c60 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c60:	7139                	addi	sp,sp,-64
    80003c62:	fc06                	sd	ra,56(sp)
    80003c64:	f822                	sd	s0,48(sp)
    80003c66:	f426                	sd	s1,40(sp)
    80003c68:	f04a                	sd	s2,32(sp)
    80003c6a:	ec4e                	sd	s3,24(sp)
    80003c6c:	e852                	sd	s4,16(sp)
    80003c6e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c70:	04451703          	lh	a4,68(a0)
    80003c74:	4785                	li	a5,1
    80003c76:	00f71a63          	bne	a4,a5,80003c8a <dirlookup+0x2a>
    80003c7a:	892a                	mv	s2,a0
    80003c7c:	89ae                	mv	s3,a1
    80003c7e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c80:	457c                	lw	a5,76(a0)
    80003c82:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c84:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c86:	e79d                	bnez	a5,80003cb4 <dirlookup+0x54>
    80003c88:	a8a5                	j	80003d00 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c8a:	00005517          	auipc	a0,0x5
    80003c8e:	99e50513          	addi	a0,a0,-1634 # 80008628 <syscalls+0x1b0>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	8a8080e7          	jalr	-1880(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003c9a:	00005517          	auipc	a0,0x5
    80003c9e:	9a650513          	addi	a0,a0,-1626 # 80008640 <syscalls+0x1c8>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	898080e7          	jalr	-1896(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003caa:	24c1                	addiw	s1,s1,16
    80003cac:	04c92783          	lw	a5,76(s2)
    80003cb0:	04f4f763          	bgeu	s1,a5,80003cfe <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cb4:	4741                	li	a4,16
    80003cb6:	86a6                	mv	a3,s1
    80003cb8:	fc040613          	addi	a2,s0,-64
    80003cbc:	4581                	li	a1,0
    80003cbe:	854a                	mv	a0,s2
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	d70080e7          	jalr	-656(ra) # 80003a30 <readi>
    80003cc8:	47c1                	li	a5,16
    80003cca:	fcf518e3          	bne	a0,a5,80003c9a <dirlookup+0x3a>
    if(de.inum == 0)
    80003cce:	fc045783          	lhu	a5,-64(s0)
    80003cd2:	dfe1                	beqz	a5,80003caa <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cd4:	fc240593          	addi	a1,s0,-62
    80003cd8:	854e                	mv	a0,s3
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	f6c080e7          	jalr	-148(ra) # 80003c46 <namecmp>
    80003ce2:	f561                	bnez	a0,80003caa <dirlookup+0x4a>
      if(poff)
    80003ce4:	000a0463          	beqz	s4,80003cec <dirlookup+0x8c>
        *poff = off;
    80003ce8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cec:	fc045583          	lhu	a1,-64(s0)
    80003cf0:	00092503          	lw	a0,0(s2)
    80003cf4:	fffff097          	auipc	ra,0xfffff
    80003cf8:	752080e7          	jalr	1874(ra) # 80003446 <iget>
    80003cfc:	a011                	j	80003d00 <dirlookup+0xa0>
  return 0;
    80003cfe:	4501                	li	a0,0
}
    80003d00:	70e2                	ld	ra,56(sp)
    80003d02:	7442                	ld	s0,48(sp)
    80003d04:	74a2                	ld	s1,40(sp)
    80003d06:	7902                	ld	s2,32(sp)
    80003d08:	69e2                	ld	s3,24(sp)
    80003d0a:	6a42                	ld	s4,16(sp)
    80003d0c:	6121                	addi	sp,sp,64
    80003d0e:	8082                	ret

0000000080003d10 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d10:	711d                	addi	sp,sp,-96
    80003d12:	ec86                	sd	ra,88(sp)
    80003d14:	e8a2                	sd	s0,80(sp)
    80003d16:	e4a6                	sd	s1,72(sp)
    80003d18:	e0ca                	sd	s2,64(sp)
    80003d1a:	fc4e                	sd	s3,56(sp)
    80003d1c:	f852                	sd	s4,48(sp)
    80003d1e:	f456                	sd	s5,40(sp)
    80003d20:	f05a                	sd	s6,32(sp)
    80003d22:	ec5e                	sd	s7,24(sp)
    80003d24:	e862                	sd	s8,16(sp)
    80003d26:	e466                	sd	s9,8(sp)
    80003d28:	e06a                	sd	s10,0(sp)
    80003d2a:	1080                	addi	s0,sp,96
    80003d2c:	84aa                	mv	s1,a0
    80003d2e:	8b2e                	mv	s6,a1
    80003d30:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d32:	00054703          	lbu	a4,0(a0)
    80003d36:	02f00793          	li	a5,47
    80003d3a:	02f70363          	beq	a4,a5,80003d60 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d3e:	ffffe097          	auipc	ra,0xffffe
    80003d42:	c78080e7          	jalr	-904(ra) # 800019b6 <myproc>
    80003d46:	15053503          	ld	a0,336(a0)
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	9f4080e7          	jalr	-1548(ra) # 8000373e <idup>
    80003d52:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d54:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d58:	4cb5                	li	s9,13
  len = path - s;
    80003d5a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d5c:	4c05                	li	s8,1
    80003d5e:	a87d                	j	80003e1c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d60:	4585                	li	a1,1
    80003d62:	4505                	li	a0,1
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	6e2080e7          	jalr	1762(ra) # 80003446 <iget>
    80003d6c:	8a2a                	mv	s4,a0
    80003d6e:	b7dd                	j	80003d54 <namex+0x44>
      iunlockput(ip);
    80003d70:	8552                	mv	a0,s4
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	c6c080e7          	jalr	-916(ra) # 800039de <iunlockput>
      return 0;
    80003d7a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d7c:	8552                	mv	a0,s4
    80003d7e:	60e6                	ld	ra,88(sp)
    80003d80:	6446                	ld	s0,80(sp)
    80003d82:	64a6                	ld	s1,72(sp)
    80003d84:	6906                	ld	s2,64(sp)
    80003d86:	79e2                	ld	s3,56(sp)
    80003d88:	7a42                	ld	s4,48(sp)
    80003d8a:	7aa2                	ld	s5,40(sp)
    80003d8c:	7b02                	ld	s6,32(sp)
    80003d8e:	6be2                	ld	s7,24(sp)
    80003d90:	6c42                	ld	s8,16(sp)
    80003d92:	6ca2                	ld	s9,8(sp)
    80003d94:	6d02                	ld	s10,0(sp)
    80003d96:	6125                	addi	sp,sp,96
    80003d98:	8082                	ret
      iunlock(ip);
    80003d9a:	8552                	mv	a0,s4
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	aa2080e7          	jalr	-1374(ra) # 8000383e <iunlock>
      return ip;
    80003da4:	bfe1                	j	80003d7c <namex+0x6c>
      iunlockput(ip);
    80003da6:	8552                	mv	a0,s4
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	c36080e7          	jalr	-970(ra) # 800039de <iunlockput>
      return 0;
    80003db0:	8a4e                	mv	s4,s3
    80003db2:	b7e9                	j	80003d7c <namex+0x6c>
  len = path - s;
    80003db4:	40998633          	sub	a2,s3,s1
    80003db8:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003dbc:	09acd863          	bge	s9,s10,80003e4c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003dc0:	4639                	li	a2,14
    80003dc2:	85a6                	mv	a1,s1
    80003dc4:	8556                	mv	a0,s5
    80003dc6:	ffffd097          	auipc	ra,0xffffd
    80003dca:	fac080e7          	jalr	-84(ra) # 80000d72 <memmove>
    80003dce:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dd0:	0004c783          	lbu	a5,0(s1)
    80003dd4:	01279763          	bne	a5,s2,80003de2 <namex+0xd2>
    path++;
    80003dd8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dda:	0004c783          	lbu	a5,0(s1)
    80003dde:	ff278de3          	beq	a5,s2,80003dd8 <namex+0xc8>
    ilock(ip);
    80003de2:	8552                	mv	a0,s4
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	998080e7          	jalr	-1640(ra) # 8000377c <ilock>
    if(ip->type != T_DIR){
    80003dec:	044a1783          	lh	a5,68(s4)
    80003df0:	f98790e3          	bne	a5,s8,80003d70 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003df4:	000b0563          	beqz	s6,80003dfe <namex+0xee>
    80003df8:	0004c783          	lbu	a5,0(s1)
    80003dfc:	dfd9                	beqz	a5,80003d9a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dfe:	865e                	mv	a2,s7
    80003e00:	85d6                	mv	a1,s5
    80003e02:	8552                	mv	a0,s4
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	e5c080e7          	jalr	-420(ra) # 80003c60 <dirlookup>
    80003e0c:	89aa                	mv	s3,a0
    80003e0e:	dd41                	beqz	a0,80003da6 <namex+0x96>
    iunlockput(ip);
    80003e10:	8552                	mv	a0,s4
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	bcc080e7          	jalr	-1076(ra) # 800039de <iunlockput>
    ip = next;
    80003e1a:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e1c:	0004c783          	lbu	a5,0(s1)
    80003e20:	01279763          	bne	a5,s2,80003e2e <namex+0x11e>
    path++;
    80003e24:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	ff278de3          	beq	a5,s2,80003e24 <namex+0x114>
  if(*path == 0)
    80003e2e:	cb9d                	beqz	a5,80003e64 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e30:	0004c783          	lbu	a5,0(s1)
    80003e34:	89a6                	mv	s3,s1
  len = path - s;
    80003e36:	8d5e                	mv	s10,s7
    80003e38:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e3a:	01278963          	beq	a5,s2,80003e4c <namex+0x13c>
    80003e3e:	dbbd                	beqz	a5,80003db4 <namex+0xa4>
    path++;
    80003e40:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e42:	0009c783          	lbu	a5,0(s3)
    80003e46:	ff279ce3          	bne	a5,s2,80003e3e <namex+0x12e>
    80003e4a:	b7ad                	j	80003db4 <namex+0xa4>
    memmove(name, s, len);
    80003e4c:	2601                	sext.w	a2,a2
    80003e4e:	85a6                	mv	a1,s1
    80003e50:	8556                	mv	a0,s5
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	f20080e7          	jalr	-224(ra) # 80000d72 <memmove>
    name[len] = 0;
    80003e5a:	9d56                	add	s10,s10,s5
    80003e5c:	000d0023          	sb	zero,0(s10)
    80003e60:	84ce                	mv	s1,s3
    80003e62:	b7bd                	j	80003dd0 <namex+0xc0>
  if(nameiparent){
    80003e64:	f00b0ce3          	beqz	s6,80003d7c <namex+0x6c>
    iput(ip);
    80003e68:	8552                	mv	a0,s4
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	acc080e7          	jalr	-1332(ra) # 80003936 <iput>
    return 0;
    80003e72:	4a01                	li	s4,0
    80003e74:	b721                	j	80003d7c <namex+0x6c>

0000000080003e76 <dirlink>:
{
    80003e76:	7139                	addi	sp,sp,-64
    80003e78:	fc06                	sd	ra,56(sp)
    80003e7a:	f822                	sd	s0,48(sp)
    80003e7c:	f426                	sd	s1,40(sp)
    80003e7e:	f04a                	sd	s2,32(sp)
    80003e80:	ec4e                	sd	s3,24(sp)
    80003e82:	e852                	sd	s4,16(sp)
    80003e84:	0080                	addi	s0,sp,64
    80003e86:	892a                	mv	s2,a0
    80003e88:	8a2e                	mv	s4,a1
    80003e8a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e8c:	4601                	li	a2,0
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	dd2080e7          	jalr	-558(ra) # 80003c60 <dirlookup>
    80003e96:	e93d                	bnez	a0,80003f0c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e98:	04c92483          	lw	s1,76(s2)
    80003e9c:	c49d                	beqz	s1,80003eca <dirlink+0x54>
    80003e9e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea0:	4741                	li	a4,16
    80003ea2:	86a6                	mv	a3,s1
    80003ea4:	fc040613          	addi	a2,s0,-64
    80003ea8:	4581                	li	a1,0
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	b84080e7          	jalr	-1148(ra) # 80003a30 <readi>
    80003eb4:	47c1                	li	a5,16
    80003eb6:	06f51163          	bne	a0,a5,80003f18 <dirlink+0xa2>
    if(de.inum == 0)
    80003eba:	fc045783          	lhu	a5,-64(s0)
    80003ebe:	c791                	beqz	a5,80003eca <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec0:	24c1                	addiw	s1,s1,16
    80003ec2:	04c92783          	lw	a5,76(s2)
    80003ec6:	fcf4ede3          	bltu	s1,a5,80003ea0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eca:	4639                	li	a2,14
    80003ecc:	85d2                	mv	a1,s4
    80003ece:	fc240513          	addi	a0,s0,-62
    80003ed2:	ffffd097          	auipc	ra,0xffffd
    80003ed6:	f50080e7          	jalr	-176(ra) # 80000e22 <strncpy>
  de.inum = inum;
    80003eda:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ede:	4741                	li	a4,16
    80003ee0:	86a6                	mv	a3,s1
    80003ee2:	fc040613          	addi	a2,s0,-64
    80003ee6:	4581                	li	a1,0
    80003ee8:	854a                	mv	a0,s2
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	c3e080e7          	jalr	-962(ra) # 80003b28 <writei>
    80003ef2:	872a                	mv	a4,a0
    80003ef4:	47c1                	li	a5,16
  return 0;
    80003ef6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef8:	02f71863          	bne	a4,a5,80003f28 <dirlink+0xb2>
}
    80003efc:	70e2                	ld	ra,56(sp)
    80003efe:	7442                	ld	s0,48(sp)
    80003f00:	74a2                	ld	s1,40(sp)
    80003f02:	7902                	ld	s2,32(sp)
    80003f04:	69e2                	ld	s3,24(sp)
    80003f06:	6a42                	ld	s4,16(sp)
    80003f08:	6121                	addi	sp,sp,64
    80003f0a:	8082                	ret
    iput(ip);
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	a2a080e7          	jalr	-1494(ra) # 80003936 <iput>
    return -1;
    80003f14:	557d                	li	a0,-1
    80003f16:	b7dd                	j	80003efc <dirlink+0x86>
      panic("dirlink read");
    80003f18:	00004517          	auipc	a0,0x4
    80003f1c:	73850513          	addi	a0,a0,1848 # 80008650 <syscalls+0x1d8>
    80003f20:	ffffc097          	auipc	ra,0xffffc
    80003f24:	61a080e7          	jalr	1562(ra) # 8000053a <panic>
    panic("dirlink");
    80003f28:	00005517          	auipc	a0,0x5
    80003f2c:	83850513          	addi	a0,a0,-1992 # 80008760 <syscalls+0x2e8>
    80003f30:	ffffc097          	auipc	ra,0xffffc
    80003f34:	60a080e7          	jalr	1546(ra) # 8000053a <panic>

0000000080003f38 <namei>:

struct inode*
namei(char *path)
{
    80003f38:	1101                	addi	sp,sp,-32
    80003f3a:	ec06                	sd	ra,24(sp)
    80003f3c:	e822                	sd	s0,16(sp)
    80003f3e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f40:	fe040613          	addi	a2,s0,-32
    80003f44:	4581                	li	a1,0
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	dca080e7          	jalr	-566(ra) # 80003d10 <namex>
}
    80003f4e:	60e2                	ld	ra,24(sp)
    80003f50:	6442                	ld	s0,16(sp)
    80003f52:	6105                	addi	sp,sp,32
    80003f54:	8082                	ret

0000000080003f56 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f56:	1141                	addi	sp,sp,-16
    80003f58:	e406                	sd	ra,8(sp)
    80003f5a:	e022                	sd	s0,0(sp)
    80003f5c:	0800                	addi	s0,sp,16
    80003f5e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f60:	4585                	li	a1,1
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	dae080e7          	jalr	-594(ra) # 80003d10 <namex>
}
    80003f6a:	60a2                	ld	ra,8(sp)
    80003f6c:	6402                	ld	s0,0(sp)
    80003f6e:	0141                	addi	sp,sp,16
    80003f70:	8082                	ret

0000000080003f72 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	e426                	sd	s1,8(sp)
    80003f7a:	e04a                	sd	s2,0(sp)
    80003f7c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f7e:	0001d917          	auipc	s2,0x1d
    80003f82:	2f290913          	addi	s2,s2,754 # 80021270 <log>
    80003f86:	01892583          	lw	a1,24(s2)
    80003f8a:	02892503          	lw	a0,40(s2)
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	fec080e7          	jalr	-20(ra) # 80002f7a <bread>
    80003f96:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f98:	02c92683          	lw	a3,44(s2)
    80003f9c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f9e:	02d05863          	blez	a3,80003fce <write_head+0x5c>
    80003fa2:	0001d797          	auipc	a5,0x1d
    80003fa6:	2fe78793          	addi	a5,a5,766 # 800212a0 <log+0x30>
    80003faa:	05c50713          	addi	a4,a0,92
    80003fae:	36fd                	addiw	a3,a3,-1
    80003fb0:	02069613          	slli	a2,a3,0x20
    80003fb4:	01e65693          	srli	a3,a2,0x1e
    80003fb8:	0001d617          	auipc	a2,0x1d
    80003fbc:	2ec60613          	addi	a2,a2,748 # 800212a4 <log+0x34>
    80003fc0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fc2:	4390                	lw	a2,0(a5)
    80003fc4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fc6:	0791                	addi	a5,a5,4
    80003fc8:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fca:	fed79ce3          	bne	a5,a3,80003fc2 <write_head+0x50>
  }
  bwrite(buf);
    80003fce:	8526                	mv	a0,s1
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	09c080e7          	jalr	156(ra) # 8000306c <bwrite>
  brelse(buf);
    80003fd8:	8526                	mv	a0,s1
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	0d0080e7          	jalr	208(ra) # 800030aa <brelse>
}
    80003fe2:	60e2                	ld	ra,24(sp)
    80003fe4:	6442                	ld	s0,16(sp)
    80003fe6:	64a2                	ld	s1,8(sp)
    80003fe8:	6902                	ld	s2,0(sp)
    80003fea:	6105                	addi	sp,sp,32
    80003fec:	8082                	ret

0000000080003fee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fee:	0001d797          	auipc	a5,0x1d
    80003ff2:	2ae7a783          	lw	a5,686(a5) # 8002129c <log+0x2c>
    80003ff6:	0af05d63          	blez	a5,800040b0 <install_trans+0xc2>
{
    80003ffa:	7139                	addi	sp,sp,-64
    80003ffc:	fc06                	sd	ra,56(sp)
    80003ffe:	f822                	sd	s0,48(sp)
    80004000:	f426                	sd	s1,40(sp)
    80004002:	f04a                	sd	s2,32(sp)
    80004004:	ec4e                	sd	s3,24(sp)
    80004006:	e852                	sd	s4,16(sp)
    80004008:	e456                	sd	s5,8(sp)
    8000400a:	e05a                	sd	s6,0(sp)
    8000400c:	0080                	addi	s0,sp,64
    8000400e:	8b2a                	mv	s6,a0
    80004010:	0001da97          	auipc	s5,0x1d
    80004014:	290a8a93          	addi	s5,s5,656 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004018:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000401a:	0001d997          	auipc	s3,0x1d
    8000401e:	25698993          	addi	s3,s3,598 # 80021270 <log>
    80004022:	a00d                	j	80004044 <install_trans+0x56>
    brelse(lbuf);
    80004024:	854a                	mv	a0,s2
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	084080e7          	jalr	132(ra) # 800030aa <brelse>
    brelse(dbuf);
    8000402e:	8526                	mv	a0,s1
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	07a080e7          	jalr	122(ra) # 800030aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004038:	2a05                	addiw	s4,s4,1
    8000403a:	0a91                	addi	s5,s5,4
    8000403c:	02c9a783          	lw	a5,44(s3)
    80004040:	04fa5e63          	bge	s4,a5,8000409c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004044:	0189a583          	lw	a1,24(s3)
    80004048:	014585bb          	addw	a1,a1,s4
    8000404c:	2585                	addiw	a1,a1,1
    8000404e:	0289a503          	lw	a0,40(s3)
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	f28080e7          	jalr	-216(ra) # 80002f7a <bread>
    8000405a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000405c:	000aa583          	lw	a1,0(s5)
    80004060:	0289a503          	lw	a0,40(s3)
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	f16080e7          	jalr	-234(ra) # 80002f7a <bread>
    8000406c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000406e:	40000613          	li	a2,1024
    80004072:	05890593          	addi	a1,s2,88
    80004076:	05850513          	addi	a0,a0,88
    8000407a:	ffffd097          	auipc	ra,0xffffd
    8000407e:	cf8080e7          	jalr	-776(ra) # 80000d72 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004082:	8526                	mv	a0,s1
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	fe8080e7          	jalr	-24(ra) # 8000306c <bwrite>
    if(recovering == 0)
    8000408c:	f80b1ce3          	bnez	s6,80004024 <install_trans+0x36>
      bunpin(dbuf);
    80004090:	8526                	mv	a0,s1
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	0f2080e7          	jalr	242(ra) # 80003184 <bunpin>
    8000409a:	b769                	j	80004024 <install_trans+0x36>
}
    8000409c:	70e2                	ld	ra,56(sp)
    8000409e:	7442                	ld	s0,48(sp)
    800040a0:	74a2                	ld	s1,40(sp)
    800040a2:	7902                	ld	s2,32(sp)
    800040a4:	69e2                	ld	s3,24(sp)
    800040a6:	6a42                	ld	s4,16(sp)
    800040a8:	6aa2                	ld	s5,8(sp)
    800040aa:	6b02                	ld	s6,0(sp)
    800040ac:	6121                	addi	sp,sp,64
    800040ae:	8082                	ret
    800040b0:	8082                	ret

00000000800040b2 <initlog>:
{
    800040b2:	7179                	addi	sp,sp,-48
    800040b4:	f406                	sd	ra,40(sp)
    800040b6:	f022                	sd	s0,32(sp)
    800040b8:	ec26                	sd	s1,24(sp)
    800040ba:	e84a                	sd	s2,16(sp)
    800040bc:	e44e                	sd	s3,8(sp)
    800040be:	1800                	addi	s0,sp,48
    800040c0:	892a                	mv	s2,a0
    800040c2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040c4:	0001d497          	auipc	s1,0x1d
    800040c8:	1ac48493          	addi	s1,s1,428 # 80021270 <log>
    800040cc:	00004597          	auipc	a1,0x4
    800040d0:	59458593          	addi	a1,a1,1428 # 80008660 <syscalls+0x1e8>
    800040d4:	8526                	mv	a0,s1
    800040d6:	ffffd097          	auipc	ra,0xffffd
    800040da:	ab4080e7          	jalr	-1356(ra) # 80000b8a <initlock>
  log.start = sb->logstart;
    800040de:	0149a583          	lw	a1,20(s3)
    800040e2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040e4:	0109a783          	lw	a5,16(s3)
    800040e8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040ee:	854a                	mv	a0,s2
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	e8a080e7          	jalr	-374(ra) # 80002f7a <bread>
  log.lh.n = lh->n;
    800040f8:	4d34                	lw	a3,88(a0)
    800040fa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040fc:	02d05663          	blez	a3,80004128 <initlog+0x76>
    80004100:	05c50793          	addi	a5,a0,92
    80004104:	0001d717          	auipc	a4,0x1d
    80004108:	19c70713          	addi	a4,a4,412 # 800212a0 <log+0x30>
    8000410c:	36fd                	addiw	a3,a3,-1
    8000410e:	02069613          	slli	a2,a3,0x20
    80004112:	01e65693          	srli	a3,a2,0x1e
    80004116:	06050613          	addi	a2,a0,96
    8000411a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000411c:	4390                	lw	a2,0(a5)
    8000411e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004120:	0791                	addi	a5,a5,4
    80004122:	0711                	addi	a4,a4,4
    80004124:	fed79ce3          	bne	a5,a3,8000411c <initlog+0x6a>
  brelse(buf);
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	f82080e7          	jalr	-126(ra) # 800030aa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004130:	4505                	li	a0,1
    80004132:	00000097          	auipc	ra,0x0
    80004136:	ebc080e7          	jalr	-324(ra) # 80003fee <install_trans>
  log.lh.n = 0;
    8000413a:	0001d797          	auipc	a5,0x1d
    8000413e:	1607a123          	sw	zero,354(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004142:	00000097          	auipc	ra,0x0
    80004146:	e30080e7          	jalr	-464(ra) # 80003f72 <write_head>
}
    8000414a:	70a2                	ld	ra,40(sp)
    8000414c:	7402                	ld	s0,32(sp)
    8000414e:	64e2                	ld	s1,24(sp)
    80004150:	6942                	ld	s2,16(sp)
    80004152:	69a2                	ld	s3,8(sp)
    80004154:	6145                	addi	sp,sp,48
    80004156:	8082                	ret

0000000080004158 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004158:	1101                	addi	sp,sp,-32
    8000415a:	ec06                	sd	ra,24(sp)
    8000415c:	e822                	sd	s0,16(sp)
    8000415e:	e426                	sd	s1,8(sp)
    80004160:	e04a                	sd	s2,0(sp)
    80004162:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004164:	0001d517          	auipc	a0,0x1d
    80004168:	10c50513          	addi	a0,a0,268 # 80021270 <log>
    8000416c:	ffffd097          	auipc	ra,0xffffd
    80004170:	aae080e7          	jalr	-1362(ra) # 80000c1a <acquire>
  while(1){
    if(log.committing){
    80004174:	0001d497          	auipc	s1,0x1d
    80004178:	0fc48493          	addi	s1,s1,252 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000417c:	4979                	li	s2,30
    8000417e:	a039                	j	8000418c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004180:	85a6                	mv	a1,s1
    80004182:	8526                	mv	a0,s1
    80004184:	ffffe097          	auipc	ra,0xffffe
    80004188:	ef6080e7          	jalr	-266(ra) # 8000207a <sleep>
    if(log.committing){
    8000418c:	50dc                	lw	a5,36(s1)
    8000418e:	fbed                	bnez	a5,80004180 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004190:	5098                	lw	a4,32(s1)
    80004192:	2705                	addiw	a4,a4,1
    80004194:	0007069b          	sext.w	a3,a4
    80004198:	0027179b          	slliw	a5,a4,0x2
    8000419c:	9fb9                	addw	a5,a5,a4
    8000419e:	0017979b          	slliw	a5,a5,0x1
    800041a2:	54d8                	lw	a4,44(s1)
    800041a4:	9fb9                	addw	a5,a5,a4
    800041a6:	00f95963          	bge	s2,a5,800041b8 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041aa:	85a6                	mv	a1,s1
    800041ac:	8526                	mv	a0,s1
    800041ae:	ffffe097          	auipc	ra,0xffffe
    800041b2:	ecc080e7          	jalr	-308(ra) # 8000207a <sleep>
    800041b6:	bfd9                	j	8000418c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041b8:	0001d517          	auipc	a0,0x1d
    800041bc:	0b850513          	addi	a0,a0,184 # 80021270 <log>
    800041c0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	b0c080e7          	jalr	-1268(ra) # 80000cce <release>
      break;
    }
  }
}
    800041ca:	60e2                	ld	ra,24(sp)
    800041cc:	6442                	ld	s0,16(sp)
    800041ce:	64a2                	ld	s1,8(sp)
    800041d0:	6902                	ld	s2,0(sp)
    800041d2:	6105                	addi	sp,sp,32
    800041d4:	8082                	ret

00000000800041d6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041d6:	7139                	addi	sp,sp,-64
    800041d8:	fc06                	sd	ra,56(sp)
    800041da:	f822                	sd	s0,48(sp)
    800041dc:	f426                	sd	s1,40(sp)
    800041de:	f04a                	sd	s2,32(sp)
    800041e0:	ec4e                	sd	s3,24(sp)
    800041e2:	e852                	sd	s4,16(sp)
    800041e4:	e456                	sd	s5,8(sp)
    800041e6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041e8:	0001d497          	auipc	s1,0x1d
    800041ec:	08848493          	addi	s1,s1,136 # 80021270 <log>
    800041f0:	8526                	mv	a0,s1
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	a28080e7          	jalr	-1496(ra) # 80000c1a <acquire>
  log.outstanding -= 1;
    800041fa:	509c                	lw	a5,32(s1)
    800041fc:	37fd                	addiw	a5,a5,-1
    800041fe:	0007891b          	sext.w	s2,a5
    80004202:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004204:	50dc                	lw	a5,36(s1)
    80004206:	e7b9                	bnez	a5,80004254 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004208:	04091e63          	bnez	s2,80004264 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000420c:	0001d497          	auipc	s1,0x1d
    80004210:	06448493          	addi	s1,s1,100 # 80021270 <log>
    80004214:	4785                	li	a5,1
    80004216:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	ab4080e7          	jalr	-1356(ra) # 80000cce <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004222:	54dc                	lw	a5,44(s1)
    80004224:	06f04763          	bgtz	a5,80004292 <end_op+0xbc>
    acquire(&log.lock);
    80004228:	0001d497          	auipc	s1,0x1d
    8000422c:	04848493          	addi	s1,s1,72 # 80021270 <log>
    80004230:	8526                	mv	a0,s1
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	9e8080e7          	jalr	-1560(ra) # 80000c1a <acquire>
    log.committing = 0;
    8000423a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffe097          	auipc	ra,0xffffe
    80004244:	fc6080e7          	jalr	-58(ra) # 80002206 <wakeup>
    release(&log.lock);
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	a84080e7          	jalr	-1404(ra) # 80000cce <release>
}
    80004252:	a03d                	j	80004280 <end_op+0xaa>
    panic("log.committing");
    80004254:	00004517          	auipc	a0,0x4
    80004258:	41450513          	addi	a0,a0,1044 # 80008668 <syscalls+0x1f0>
    8000425c:	ffffc097          	auipc	ra,0xffffc
    80004260:	2de080e7          	jalr	734(ra) # 8000053a <panic>
    wakeup(&log);
    80004264:	0001d497          	auipc	s1,0x1d
    80004268:	00c48493          	addi	s1,s1,12 # 80021270 <log>
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffe097          	auipc	ra,0xffffe
    80004272:	f98080e7          	jalr	-104(ra) # 80002206 <wakeup>
  release(&log.lock);
    80004276:	8526                	mv	a0,s1
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	a56080e7          	jalr	-1450(ra) # 80000cce <release>
}
    80004280:	70e2                	ld	ra,56(sp)
    80004282:	7442                	ld	s0,48(sp)
    80004284:	74a2                	ld	s1,40(sp)
    80004286:	7902                	ld	s2,32(sp)
    80004288:	69e2                	ld	s3,24(sp)
    8000428a:	6a42                	ld	s4,16(sp)
    8000428c:	6aa2                	ld	s5,8(sp)
    8000428e:	6121                	addi	sp,sp,64
    80004290:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004292:	0001da97          	auipc	s5,0x1d
    80004296:	00ea8a93          	addi	s5,s5,14 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000429a:	0001da17          	auipc	s4,0x1d
    8000429e:	fd6a0a13          	addi	s4,s4,-42 # 80021270 <log>
    800042a2:	018a2583          	lw	a1,24(s4)
    800042a6:	012585bb          	addw	a1,a1,s2
    800042aa:	2585                	addiw	a1,a1,1
    800042ac:	028a2503          	lw	a0,40(s4)
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	cca080e7          	jalr	-822(ra) # 80002f7a <bread>
    800042b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ba:	000aa583          	lw	a1,0(s5)
    800042be:	028a2503          	lw	a0,40(s4)
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	cb8080e7          	jalr	-840(ra) # 80002f7a <bread>
    800042ca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042cc:	40000613          	li	a2,1024
    800042d0:	05850593          	addi	a1,a0,88
    800042d4:	05848513          	addi	a0,s1,88
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	a9a080e7          	jalr	-1382(ra) # 80000d72 <memmove>
    bwrite(to);  // write the log
    800042e0:	8526                	mv	a0,s1
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	d8a080e7          	jalr	-630(ra) # 8000306c <bwrite>
    brelse(from);
    800042ea:	854e                	mv	a0,s3
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	dbe080e7          	jalr	-578(ra) # 800030aa <brelse>
    brelse(to);
    800042f4:	8526                	mv	a0,s1
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	db4080e7          	jalr	-588(ra) # 800030aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042fe:	2905                	addiw	s2,s2,1
    80004300:	0a91                	addi	s5,s5,4
    80004302:	02ca2783          	lw	a5,44(s4)
    80004306:	f8f94ee3          	blt	s2,a5,800042a2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	c68080e7          	jalr	-920(ra) # 80003f72 <write_head>
    install_trans(0); // Now install writes to home locations
    80004312:	4501                	li	a0,0
    80004314:	00000097          	auipc	ra,0x0
    80004318:	cda080e7          	jalr	-806(ra) # 80003fee <install_trans>
    log.lh.n = 0;
    8000431c:	0001d797          	auipc	a5,0x1d
    80004320:	f807a023          	sw	zero,-128(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004324:	00000097          	auipc	ra,0x0
    80004328:	c4e080e7          	jalr	-946(ra) # 80003f72 <write_head>
    8000432c:	bdf5                	j	80004228 <end_op+0x52>

000000008000432e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000432e:	1101                	addi	sp,sp,-32
    80004330:	ec06                	sd	ra,24(sp)
    80004332:	e822                	sd	s0,16(sp)
    80004334:	e426                	sd	s1,8(sp)
    80004336:	e04a                	sd	s2,0(sp)
    80004338:	1000                	addi	s0,sp,32
    8000433a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000433c:	0001d917          	auipc	s2,0x1d
    80004340:	f3490913          	addi	s2,s2,-204 # 80021270 <log>
    80004344:	854a                	mv	a0,s2
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	8d4080e7          	jalr	-1836(ra) # 80000c1a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000434e:	02c92603          	lw	a2,44(s2)
    80004352:	47f5                	li	a5,29
    80004354:	06c7c563          	blt	a5,a2,800043be <log_write+0x90>
    80004358:	0001d797          	auipc	a5,0x1d
    8000435c:	f347a783          	lw	a5,-204(a5) # 8002128c <log+0x1c>
    80004360:	37fd                	addiw	a5,a5,-1
    80004362:	04f65e63          	bge	a2,a5,800043be <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004366:	0001d797          	auipc	a5,0x1d
    8000436a:	f2a7a783          	lw	a5,-214(a5) # 80021290 <log+0x20>
    8000436e:	06f05063          	blez	a5,800043ce <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004372:	4781                	li	a5,0
    80004374:	06c05563          	blez	a2,800043de <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004378:	44cc                	lw	a1,12(s1)
    8000437a:	0001d717          	auipc	a4,0x1d
    8000437e:	f2670713          	addi	a4,a4,-218 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004382:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004384:	4314                	lw	a3,0(a4)
    80004386:	04b68c63          	beq	a3,a1,800043de <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000438a:	2785                	addiw	a5,a5,1
    8000438c:	0711                	addi	a4,a4,4
    8000438e:	fef61be3          	bne	a2,a5,80004384 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004392:	0621                	addi	a2,a2,8
    80004394:	060a                	slli	a2,a2,0x2
    80004396:	0001d797          	auipc	a5,0x1d
    8000439a:	eda78793          	addi	a5,a5,-294 # 80021270 <log>
    8000439e:	97b2                	add	a5,a5,a2
    800043a0:	44d8                	lw	a4,12(s1)
    800043a2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043a4:	8526                	mv	a0,s1
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	da2080e7          	jalr	-606(ra) # 80003148 <bpin>
    log.lh.n++;
    800043ae:	0001d717          	auipc	a4,0x1d
    800043b2:	ec270713          	addi	a4,a4,-318 # 80021270 <log>
    800043b6:	575c                	lw	a5,44(a4)
    800043b8:	2785                	addiw	a5,a5,1
    800043ba:	d75c                	sw	a5,44(a4)
    800043bc:	a82d                	j	800043f6 <log_write+0xc8>
    panic("too big a transaction");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	2ba50513          	addi	a0,a0,698 # 80008678 <syscalls+0x200>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	174080e7          	jalr	372(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	2c250513          	addi	a0,a0,706 # 80008690 <syscalls+0x218>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	164080e7          	jalr	356(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    800043de:	00878693          	addi	a3,a5,8
    800043e2:	068a                	slli	a3,a3,0x2
    800043e4:	0001d717          	auipc	a4,0x1d
    800043e8:	e8c70713          	addi	a4,a4,-372 # 80021270 <log>
    800043ec:	9736                	add	a4,a4,a3
    800043ee:	44d4                	lw	a3,12(s1)
    800043f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043f2:	faf609e3          	beq	a2,a5,800043a4 <log_write+0x76>
  }
  release(&log.lock);
    800043f6:	0001d517          	auipc	a0,0x1d
    800043fa:	e7a50513          	addi	a0,a0,-390 # 80021270 <log>
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	8d0080e7          	jalr	-1840(ra) # 80000cce <release>
}
    80004406:	60e2                	ld	ra,24(sp)
    80004408:	6442                	ld	s0,16(sp)
    8000440a:	64a2                	ld	s1,8(sp)
    8000440c:	6902                	ld	s2,0(sp)
    8000440e:	6105                	addi	sp,sp,32
    80004410:	8082                	ret

0000000080004412 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004412:	1101                	addi	sp,sp,-32
    80004414:	ec06                	sd	ra,24(sp)
    80004416:	e822                	sd	s0,16(sp)
    80004418:	e426                	sd	s1,8(sp)
    8000441a:	e04a                	sd	s2,0(sp)
    8000441c:	1000                	addi	s0,sp,32
    8000441e:	84aa                	mv	s1,a0
    80004420:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004422:	00004597          	auipc	a1,0x4
    80004426:	28e58593          	addi	a1,a1,654 # 800086b0 <syscalls+0x238>
    8000442a:	0521                	addi	a0,a0,8
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	75e080e7          	jalr	1886(ra) # 80000b8a <initlock>
  lk->name = name;
    80004434:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004438:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000443c:	0204a423          	sw	zero,40(s1)
}
    80004440:	60e2                	ld	ra,24(sp)
    80004442:	6442                	ld	s0,16(sp)
    80004444:	64a2                	ld	s1,8(sp)
    80004446:	6902                	ld	s2,0(sp)
    80004448:	6105                	addi	sp,sp,32
    8000444a:	8082                	ret

000000008000444c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000444c:	1101                	addi	sp,sp,-32
    8000444e:	ec06                	sd	ra,24(sp)
    80004450:	e822                	sd	s0,16(sp)
    80004452:	e426                	sd	s1,8(sp)
    80004454:	e04a                	sd	s2,0(sp)
    80004456:	1000                	addi	s0,sp,32
    80004458:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000445a:	00850913          	addi	s2,a0,8
    8000445e:	854a                	mv	a0,s2
    80004460:	ffffc097          	auipc	ra,0xffffc
    80004464:	7ba080e7          	jalr	1978(ra) # 80000c1a <acquire>
  while (lk->locked) {
    80004468:	409c                	lw	a5,0(s1)
    8000446a:	cb89                	beqz	a5,8000447c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000446c:	85ca                	mv	a1,s2
    8000446e:	8526                	mv	a0,s1
    80004470:	ffffe097          	auipc	ra,0xffffe
    80004474:	c0a080e7          	jalr	-1014(ra) # 8000207a <sleep>
  while (lk->locked) {
    80004478:	409c                	lw	a5,0(s1)
    8000447a:	fbed                	bnez	a5,8000446c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000447c:	4785                	li	a5,1
    8000447e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	536080e7          	jalr	1334(ra) # 800019b6 <myproc>
    80004488:	591c                	lw	a5,48(a0)
    8000448a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000448c:	854a                	mv	a0,s2
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	840080e7          	jalr	-1984(ra) # 80000cce <release>
}
    80004496:	60e2                	ld	ra,24(sp)
    80004498:	6442                	ld	s0,16(sp)
    8000449a:	64a2                	ld	s1,8(sp)
    8000449c:	6902                	ld	s2,0(sp)
    8000449e:	6105                	addi	sp,sp,32
    800044a0:	8082                	ret

00000000800044a2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044a2:	1101                	addi	sp,sp,-32
    800044a4:	ec06                	sd	ra,24(sp)
    800044a6:	e822                	sd	s0,16(sp)
    800044a8:	e426                	sd	s1,8(sp)
    800044aa:	e04a                	sd	s2,0(sp)
    800044ac:	1000                	addi	s0,sp,32
    800044ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044b0:	00850913          	addi	s2,a0,8
    800044b4:	854a                	mv	a0,s2
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	764080e7          	jalr	1892(ra) # 80000c1a <acquire>
  lk->locked = 0;
    800044be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044c2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffe097          	auipc	ra,0xffffe
    800044cc:	d3e080e7          	jalr	-706(ra) # 80002206 <wakeup>
  release(&lk->lk);
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7fc080e7          	jalr	2044(ra) # 80000cce <release>
}
    800044da:	60e2                	ld	ra,24(sp)
    800044dc:	6442                	ld	s0,16(sp)
    800044de:	64a2                	ld	s1,8(sp)
    800044e0:	6902                	ld	s2,0(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret

00000000800044e6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044e6:	7179                	addi	sp,sp,-48
    800044e8:	f406                	sd	ra,40(sp)
    800044ea:	f022                	sd	s0,32(sp)
    800044ec:	ec26                	sd	s1,24(sp)
    800044ee:	e84a                	sd	s2,16(sp)
    800044f0:	e44e                	sd	s3,8(sp)
    800044f2:	1800                	addi	s0,sp,48
    800044f4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044f6:	00850913          	addi	s2,a0,8
    800044fa:	854a                	mv	a0,s2
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	71e080e7          	jalr	1822(ra) # 80000c1a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004504:	409c                	lw	a5,0(s1)
    80004506:	ef99                	bnez	a5,80004524 <holdingsleep+0x3e>
    80004508:	4481                	li	s1,0
  release(&lk->lk);
    8000450a:	854a                	mv	a0,s2
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	7c2080e7          	jalr	1986(ra) # 80000cce <release>
  return r;
}
    80004514:	8526                	mv	a0,s1
    80004516:	70a2                	ld	ra,40(sp)
    80004518:	7402                	ld	s0,32(sp)
    8000451a:	64e2                	ld	s1,24(sp)
    8000451c:	6942                	ld	s2,16(sp)
    8000451e:	69a2                	ld	s3,8(sp)
    80004520:	6145                	addi	sp,sp,48
    80004522:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004524:	0284a983          	lw	s3,40(s1)
    80004528:	ffffd097          	auipc	ra,0xffffd
    8000452c:	48e080e7          	jalr	1166(ra) # 800019b6 <myproc>
    80004530:	5904                	lw	s1,48(a0)
    80004532:	413484b3          	sub	s1,s1,s3
    80004536:	0014b493          	seqz	s1,s1
    8000453a:	bfc1                	j	8000450a <holdingsleep+0x24>

000000008000453c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000453c:	1141                	addi	sp,sp,-16
    8000453e:	e406                	sd	ra,8(sp)
    80004540:	e022                	sd	s0,0(sp)
    80004542:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004544:	00004597          	auipc	a1,0x4
    80004548:	17c58593          	addi	a1,a1,380 # 800086c0 <syscalls+0x248>
    8000454c:	0001d517          	auipc	a0,0x1d
    80004550:	e6c50513          	addi	a0,a0,-404 # 800213b8 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	636080e7          	jalr	1590(ra) # 80000b8a <initlock>
}
    8000455c:	60a2                	ld	ra,8(sp)
    8000455e:	6402                	ld	s0,0(sp)
    80004560:	0141                	addi	sp,sp,16
    80004562:	8082                	ret

0000000080004564 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	e426                	sd	s1,8(sp)
    8000456c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000456e:	0001d517          	auipc	a0,0x1d
    80004572:	e4a50513          	addi	a0,a0,-438 # 800213b8 <ftable>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	6a4080e7          	jalr	1700(ra) # 80000c1a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000457e:	0001d497          	auipc	s1,0x1d
    80004582:	e5248493          	addi	s1,s1,-430 # 800213d0 <ftable+0x18>
    80004586:	0001e717          	auipc	a4,0x1e
    8000458a:	dea70713          	addi	a4,a4,-534 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000458e:	40dc                	lw	a5,4(s1)
    80004590:	cf99                	beqz	a5,800045ae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004592:	02848493          	addi	s1,s1,40
    80004596:	fee49ce3          	bne	s1,a4,8000458e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000459a:	0001d517          	auipc	a0,0x1d
    8000459e:	e1e50513          	addi	a0,a0,-482 # 800213b8 <ftable>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	72c080e7          	jalr	1836(ra) # 80000cce <release>
  return 0;
    800045aa:	4481                	li	s1,0
    800045ac:	a819                	j	800045c2 <filealloc+0x5e>
      f->ref = 1;
    800045ae:	4785                	li	a5,1
    800045b0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045b2:	0001d517          	auipc	a0,0x1d
    800045b6:	e0650513          	addi	a0,a0,-506 # 800213b8 <ftable>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	714080e7          	jalr	1812(ra) # 80000cce <release>
}
    800045c2:	8526                	mv	a0,s1
    800045c4:	60e2                	ld	ra,24(sp)
    800045c6:	6442                	ld	s0,16(sp)
    800045c8:	64a2                	ld	s1,8(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret

00000000800045ce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ce:	1101                	addi	sp,sp,-32
    800045d0:	ec06                	sd	ra,24(sp)
    800045d2:	e822                	sd	s0,16(sp)
    800045d4:	e426                	sd	s1,8(sp)
    800045d6:	1000                	addi	s0,sp,32
    800045d8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045da:	0001d517          	auipc	a0,0x1d
    800045de:	dde50513          	addi	a0,a0,-546 # 800213b8 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	638080e7          	jalr	1592(ra) # 80000c1a <acquire>
  if(f->ref < 1)
    800045ea:	40dc                	lw	a5,4(s1)
    800045ec:	02f05263          	blez	a5,80004610 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045f0:	2785                	addiw	a5,a5,1
    800045f2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045f4:	0001d517          	auipc	a0,0x1d
    800045f8:	dc450513          	addi	a0,a0,-572 # 800213b8 <ftable>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	6d2080e7          	jalr	1746(ra) # 80000cce <release>
  return f;
}
    80004604:	8526                	mv	a0,s1
    80004606:	60e2                	ld	ra,24(sp)
    80004608:	6442                	ld	s0,16(sp)
    8000460a:	64a2                	ld	s1,8(sp)
    8000460c:	6105                	addi	sp,sp,32
    8000460e:	8082                	ret
    panic("filedup");
    80004610:	00004517          	auipc	a0,0x4
    80004614:	0b850513          	addi	a0,a0,184 # 800086c8 <syscalls+0x250>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	f22080e7          	jalr	-222(ra) # 8000053a <panic>

0000000080004620 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004620:	7139                	addi	sp,sp,-64
    80004622:	fc06                	sd	ra,56(sp)
    80004624:	f822                	sd	s0,48(sp)
    80004626:	f426                	sd	s1,40(sp)
    80004628:	f04a                	sd	s2,32(sp)
    8000462a:	ec4e                	sd	s3,24(sp)
    8000462c:	e852                	sd	s4,16(sp)
    8000462e:	e456                	sd	s5,8(sp)
    80004630:	0080                	addi	s0,sp,64
    80004632:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004634:	0001d517          	auipc	a0,0x1d
    80004638:	d8450513          	addi	a0,a0,-636 # 800213b8 <ftable>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	5de080e7          	jalr	1502(ra) # 80000c1a <acquire>
  if(f->ref < 1)
    80004644:	40dc                	lw	a5,4(s1)
    80004646:	06f05163          	blez	a5,800046a8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000464a:	37fd                	addiw	a5,a5,-1
    8000464c:	0007871b          	sext.w	a4,a5
    80004650:	c0dc                	sw	a5,4(s1)
    80004652:	06e04363          	bgtz	a4,800046b8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004656:	0004a903          	lw	s2,0(s1)
    8000465a:	0094ca83          	lbu	s5,9(s1)
    8000465e:	0104ba03          	ld	s4,16(s1)
    80004662:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004666:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000466a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000466e:	0001d517          	auipc	a0,0x1d
    80004672:	d4a50513          	addi	a0,a0,-694 # 800213b8 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	658080e7          	jalr	1624(ra) # 80000cce <release>

  if(ff.type == FD_PIPE){
    8000467e:	4785                	li	a5,1
    80004680:	04f90d63          	beq	s2,a5,800046da <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004684:	3979                	addiw	s2,s2,-2
    80004686:	4785                	li	a5,1
    80004688:	0527e063          	bltu	a5,s2,800046c8 <fileclose+0xa8>
    begin_op();
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	acc080e7          	jalr	-1332(ra) # 80004158 <begin_op>
    iput(ff.ip);
    80004694:	854e                	mv	a0,s3
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	2a0080e7          	jalr	672(ra) # 80003936 <iput>
    end_op();
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	b38080e7          	jalr	-1224(ra) # 800041d6 <end_op>
    800046a6:	a00d                	j	800046c8 <fileclose+0xa8>
    panic("fileclose");
    800046a8:	00004517          	auipc	a0,0x4
    800046ac:	02850513          	addi	a0,a0,40 # 800086d0 <syscalls+0x258>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	e8a080e7          	jalr	-374(ra) # 8000053a <panic>
    release(&ftable.lock);
    800046b8:	0001d517          	auipc	a0,0x1d
    800046bc:	d0050513          	addi	a0,a0,-768 # 800213b8 <ftable>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	60e080e7          	jalr	1550(ra) # 80000cce <release>
  }
}
    800046c8:	70e2                	ld	ra,56(sp)
    800046ca:	7442                	ld	s0,48(sp)
    800046cc:	74a2                	ld	s1,40(sp)
    800046ce:	7902                	ld	s2,32(sp)
    800046d0:	69e2                	ld	s3,24(sp)
    800046d2:	6a42                	ld	s4,16(sp)
    800046d4:	6aa2                	ld	s5,8(sp)
    800046d6:	6121                	addi	sp,sp,64
    800046d8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046da:	85d6                	mv	a1,s5
    800046dc:	8552                	mv	a0,s4
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	34c080e7          	jalr	844(ra) # 80004a2a <pipeclose>
    800046e6:	b7cd                	j	800046c8 <fileclose+0xa8>

00000000800046e8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046e8:	715d                	addi	sp,sp,-80
    800046ea:	e486                	sd	ra,72(sp)
    800046ec:	e0a2                	sd	s0,64(sp)
    800046ee:	fc26                	sd	s1,56(sp)
    800046f0:	f84a                	sd	s2,48(sp)
    800046f2:	f44e                	sd	s3,40(sp)
    800046f4:	0880                	addi	s0,sp,80
    800046f6:	84aa                	mv	s1,a0
    800046f8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046fa:	ffffd097          	auipc	ra,0xffffd
    800046fe:	2bc080e7          	jalr	700(ra) # 800019b6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004702:	409c                	lw	a5,0(s1)
    80004704:	37f9                	addiw	a5,a5,-2
    80004706:	4705                	li	a4,1
    80004708:	04f76763          	bltu	a4,a5,80004756 <filestat+0x6e>
    8000470c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000470e:	6c88                	ld	a0,24(s1)
    80004710:	fffff097          	auipc	ra,0xfffff
    80004714:	06c080e7          	jalr	108(ra) # 8000377c <ilock>
    stati(f->ip, &st);
    80004718:	fb840593          	addi	a1,s0,-72
    8000471c:	6c88                	ld	a0,24(s1)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	2e8080e7          	jalr	744(ra) # 80003a06 <stati>
    iunlock(f->ip);
    80004726:	6c88                	ld	a0,24(s1)
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	116080e7          	jalr	278(ra) # 8000383e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004730:	46e1                	li	a3,24
    80004732:	fb840613          	addi	a2,s0,-72
    80004736:	85ce                	mv	a1,s3
    80004738:	05093503          	ld	a0,80(s2)
    8000473c:	ffffd097          	auipc	ra,0xffffd
    80004740:	f3e080e7          	jalr	-194(ra) # 8000167a <copyout>
    80004744:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004748:	60a6                	ld	ra,72(sp)
    8000474a:	6406                	ld	s0,64(sp)
    8000474c:	74e2                	ld	s1,56(sp)
    8000474e:	7942                	ld	s2,48(sp)
    80004750:	79a2                	ld	s3,40(sp)
    80004752:	6161                	addi	sp,sp,80
    80004754:	8082                	ret
  return -1;
    80004756:	557d                	li	a0,-1
    80004758:	bfc5                	j	80004748 <filestat+0x60>

000000008000475a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000475a:	7179                	addi	sp,sp,-48
    8000475c:	f406                	sd	ra,40(sp)
    8000475e:	f022                	sd	s0,32(sp)
    80004760:	ec26                	sd	s1,24(sp)
    80004762:	e84a                	sd	s2,16(sp)
    80004764:	e44e                	sd	s3,8(sp)
    80004766:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004768:	00854783          	lbu	a5,8(a0)
    8000476c:	c3d5                	beqz	a5,80004810 <fileread+0xb6>
    8000476e:	84aa                	mv	s1,a0
    80004770:	89ae                	mv	s3,a1
    80004772:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004774:	411c                	lw	a5,0(a0)
    80004776:	4705                	li	a4,1
    80004778:	04e78963          	beq	a5,a4,800047ca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000477c:	470d                	li	a4,3
    8000477e:	04e78d63          	beq	a5,a4,800047d8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004782:	4709                	li	a4,2
    80004784:	06e79e63          	bne	a5,a4,80004800 <fileread+0xa6>
    ilock(f->ip);
    80004788:	6d08                	ld	a0,24(a0)
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	ff2080e7          	jalr	-14(ra) # 8000377c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004792:	874a                	mv	a4,s2
    80004794:	5094                	lw	a3,32(s1)
    80004796:	864e                	mv	a2,s3
    80004798:	4585                	li	a1,1
    8000479a:	6c88                	ld	a0,24(s1)
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	294080e7          	jalr	660(ra) # 80003a30 <readi>
    800047a4:	892a                	mv	s2,a0
    800047a6:	00a05563          	blez	a0,800047b0 <fileread+0x56>
      f->off += r;
    800047aa:	509c                	lw	a5,32(s1)
    800047ac:	9fa9                	addw	a5,a5,a0
    800047ae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047b0:	6c88                	ld	a0,24(s1)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	08c080e7          	jalr	140(ra) # 8000383e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047ba:	854a                	mv	a0,s2
    800047bc:	70a2                	ld	ra,40(sp)
    800047be:	7402                	ld	s0,32(sp)
    800047c0:	64e2                	ld	s1,24(sp)
    800047c2:	6942                	ld	s2,16(sp)
    800047c4:	69a2                	ld	s3,8(sp)
    800047c6:	6145                	addi	sp,sp,48
    800047c8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047ca:	6908                	ld	a0,16(a0)
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	3c0080e7          	jalr	960(ra) # 80004b8c <piperead>
    800047d4:	892a                	mv	s2,a0
    800047d6:	b7d5                	j	800047ba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047d8:	02451783          	lh	a5,36(a0)
    800047dc:	03079693          	slli	a3,a5,0x30
    800047e0:	92c1                	srli	a3,a3,0x30
    800047e2:	4725                	li	a4,9
    800047e4:	02d76863          	bltu	a4,a3,80004814 <fileread+0xba>
    800047e8:	0792                	slli	a5,a5,0x4
    800047ea:	0001d717          	auipc	a4,0x1d
    800047ee:	b2e70713          	addi	a4,a4,-1234 # 80021318 <devsw>
    800047f2:	97ba                	add	a5,a5,a4
    800047f4:	639c                	ld	a5,0(a5)
    800047f6:	c38d                	beqz	a5,80004818 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047f8:	4505                	li	a0,1
    800047fa:	9782                	jalr	a5
    800047fc:	892a                	mv	s2,a0
    800047fe:	bf75                	j	800047ba <fileread+0x60>
    panic("fileread");
    80004800:	00004517          	auipc	a0,0x4
    80004804:	ee050513          	addi	a0,a0,-288 # 800086e0 <syscalls+0x268>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	d32080e7          	jalr	-718(ra) # 8000053a <panic>
    return -1;
    80004810:	597d                	li	s2,-1
    80004812:	b765                	j	800047ba <fileread+0x60>
      return -1;
    80004814:	597d                	li	s2,-1
    80004816:	b755                	j	800047ba <fileread+0x60>
    80004818:	597d                	li	s2,-1
    8000481a:	b745                	j	800047ba <fileread+0x60>

000000008000481c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000481c:	715d                	addi	sp,sp,-80
    8000481e:	e486                	sd	ra,72(sp)
    80004820:	e0a2                	sd	s0,64(sp)
    80004822:	fc26                	sd	s1,56(sp)
    80004824:	f84a                	sd	s2,48(sp)
    80004826:	f44e                	sd	s3,40(sp)
    80004828:	f052                	sd	s4,32(sp)
    8000482a:	ec56                	sd	s5,24(sp)
    8000482c:	e85a                	sd	s6,16(sp)
    8000482e:	e45e                	sd	s7,8(sp)
    80004830:	e062                	sd	s8,0(sp)
    80004832:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004834:	00954783          	lbu	a5,9(a0)
    80004838:	10078663          	beqz	a5,80004944 <filewrite+0x128>
    8000483c:	892a                	mv	s2,a0
    8000483e:	8b2e                	mv	s6,a1
    80004840:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004842:	411c                	lw	a5,0(a0)
    80004844:	4705                	li	a4,1
    80004846:	02e78263          	beq	a5,a4,8000486a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000484a:	470d                	li	a4,3
    8000484c:	02e78663          	beq	a5,a4,80004878 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004850:	4709                	li	a4,2
    80004852:	0ee79163          	bne	a5,a4,80004934 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004856:	0ac05d63          	blez	a2,80004910 <filewrite+0xf4>
    int i = 0;
    8000485a:	4981                	li	s3,0
    8000485c:	6b85                	lui	s7,0x1
    8000485e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004862:	6c05                	lui	s8,0x1
    80004864:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004868:	a861                	j	80004900 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000486a:	6908                	ld	a0,16(a0)
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	22e080e7          	jalr	558(ra) # 80004a9a <pipewrite>
    80004874:	8a2a                	mv	s4,a0
    80004876:	a045                	j	80004916 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004878:	02451783          	lh	a5,36(a0)
    8000487c:	03079693          	slli	a3,a5,0x30
    80004880:	92c1                	srli	a3,a3,0x30
    80004882:	4725                	li	a4,9
    80004884:	0cd76263          	bltu	a4,a3,80004948 <filewrite+0x12c>
    80004888:	0792                	slli	a5,a5,0x4
    8000488a:	0001d717          	auipc	a4,0x1d
    8000488e:	a8e70713          	addi	a4,a4,-1394 # 80021318 <devsw>
    80004892:	97ba                	add	a5,a5,a4
    80004894:	679c                	ld	a5,8(a5)
    80004896:	cbdd                	beqz	a5,8000494c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004898:	4505                	li	a0,1
    8000489a:	9782                	jalr	a5
    8000489c:	8a2a                	mv	s4,a0
    8000489e:	a8a5                	j	80004916 <filewrite+0xfa>
    800048a0:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	8b4080e7          	jalr	-1868(ra) # 80004158 <begin_op>
      ilock(f->ip);
    800048ac:	01893503          	ld	a0,24(s2)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	ecc080e7          	jalr	-308(ra) # 8000377c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048b8:	8756                	mv	a4,s5
    800048ba:	02092683          	lw	a3,32(s2)
    800048be:	01698633          	add	a2,s3,s6
    800048c2:	4585                	li	a1,1
    800048c4:	01893503          	ld	a0,24(s2)
    800048c8:	fffff097          	auipc	ra,0xfffff
    800048cc:	260080e7          	jalr	608(ra) # 80003b28 <writei>
    800048d0:	84aa                	mv	s1,a0
    800048d2:	00a05763          	blez	a0,800048e0 <filewrite+0xc4>
        f->off += r;
    800048d6:	02092783          	lw	a5,32(s2)
    800048da:	9fa9                	addw	a5,a5,a0
    800048dc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048e0:	01893503          	ld	a0,24(s2)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	f5a080e7          	jalr	-166(ra) # 8000383e <iunlock>
      end_op();
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	8ea080e7          	jalr	-1814(ra) # 800041d6 <end_op>

      if(r != n1){
    800048f4:	009a9f63          	bne	s5,s1,80004912 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048f8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048fc:	0149db63          	bge	s3,s4,80004912 <filewrite+0xf6>
      int n1 = n - i;
    80004900:	413a04bb          	subw	s1,s4,s3
    80004904:	0004879b          	sext.w	a5,s1
    80004908:	f8fbdce3          	bge	s7,a5,800048a0 <filewrite+0x84>
    8000490c:	84e2                	mv	s1,s8
    8000490e:	bf49                	j	800048a0 <filewrite+0x84>
    int i = 0;
    80004910:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004912:	013a1f63          	bne	s4,s3,80004930 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004916:	8552                	mv	a0,s4
    80004918:	60a6                	ld	ra,72(sp)
    8000491a:	6406                	ld	s0,64(sp)
    8000491c:	74e2                	ld	s1,56(sp)
    8000491e:	7942                	ld	s2,48(sp)
    80004920:	79a2                	ld	s3,40(sp)
    80004922:	7a02                	ld	s4,32(sp)
    80004924:	6ae2                	ld	s5,24(sp)
    80004926:	6b42                	ld	s6,16(sp)
    80004928:	6ba2                	ld	s7,8(sp)
    8000492a:	6c02                	ld	s8,0(sp)
    8000492c:	6161                	addi	sp,sp,80
    8000492e:	8082                	ret
    ret = (i == n ? n : -1);
    80004930:	5a7d                	li	s4,-1
    80004932:	b7d5                	j	80004916 <filewrite+0xfa>
    panic("filewrite");
    80004934:	00004517          	auipc	a0,0x4
    80004938:	dbc50513          	addi	a0,a0,-580 # 800086f0 <syscalls+0x278>
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	bfe080e7          	jalr	-1026(ra) # 8000053a <panic>
    return -1;
    80004944:	5a7d                	li	s4,-1
    80004946:	bfc1                	j	80004916 <filewrite+0xfa>
      return -1;
    80004948:	5a7d                	li	s4,-1
    8000494a:	b7f1                	j	80004916 <filewrite+0xfa>
    8000494c:	5a7d                	li	s4,-1
    8000494e:	b7e1                	j	80004916 <filewrite+0xfa>

0000000080004950 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004950:	7179                	addi	sp,sp,-48
    80004952:	f406                	sd	ra,40(sp)
    80004954:	f022                	sd	s0,32(sp)
    80004956:	ec26                	sd	s1,24(sp)
    80004958:	e84a                	sd	s2,16(sp)
    8000495a:	e44e                	sd	s3,8(sp)
    8000495c:	e052                	sd	s4,0(sp)
    8000495e:	1800                	addi	s0,sp,48
    80004960:	84aa                	mv	s1,a0
    80004962:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004964:	0005b023          	sd	zero,0(a1)
    80004968:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	bf8080e7          	jalr	-1032(ra) # 80004564 <filealloc>
    80004974:	e088                	sd	a0,0(s1)
    80004976:	c551                	beqz	a0,80004a02 <pipealloc+0xb2>
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	bec080e7          	jalr	-1044(ra) # 80004564 <filealloc>
    80004980:	00aa3023          	sd	a0,0(s4)
    80004984:	c92d                	beqz	a0,800049f6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	15a080e7          	jalr	346(ra) # 80000ae0 <kalloc>
    8000498e:	892a                	mv	s2,a0
    80004990:	c125                	beqz	a0,800049f0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004992:	4985                	li	s3,1
    80004994:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004998:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000499c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049a0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049a4:	00004597          	auipc	a1,0x4
    800049a8:	d5c58593          	addi	a1,a1,-676 # 80008700 <syscalls+0x288>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	1de080e7          	jalr	478(ra) # 80000b8a <initlock>
  (*f0)->type = FD_PIPE;
    800049b4:	609c                	ld	a5,0(s1)
    800049b6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ba:	609c                	ld	a5,0(s1)
    800049bc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049c0:	609c                	ld	a5,0(s1)
    800049c2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049c6:	609c                	ld	a5,0(s1)
    800049c8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049cc:	000a3783          	ld	a5,0(s4)
    800049d0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049d4:	000a3783          	ld	a5,0(s4)
    800049d8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049dc:	000a3783          	ld	a5,0(s4)
    800049e0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049e4:	000a3783          	ld	a5,0(s4)
    800049e8:	0127b823          	sd	s2,16(a5)
  return 0;
    800049ec:	4501                	li	a0,0
    800049ee:	a025                	j	80004a16 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049f0:	6088                	ld	a0,0(s1)
    800049f2:	e501                	bnez	a0,800049fa <pipealloc+0xaa>
    800049f4:	a039                	j	80004a02 <pipealloc+0xb2>
    800049f6:	6088                	ld	a0,0(s1)
    800049f8:	c51d                	beqz	a0,80004a26 <pipealloc+0xd6>
    fileclose(*f0);
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	c26080e7          	jalr	-986(ra) # 80004620 <fileclose>
  if(*f1)
    80004a02:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a06:	557d                	li	a0,-1
  if(*f1)
    80004a08:	c799                	beqz	a5,80004a16 <pipealloc+0xc6>
    fileclose(*f1);
    80004a0a:	853e                	mv	a0,a5
    80004a0c:	00000097          	auipc	ra,0x0
    80004a10:	c14080e7          	jalr	-1004(ra) # 80004620 <fileclose>
  return -1;
    80004a14:	557d                	li	a0,-1
}
    80004a16:	70a2                	ld	ra,40(sp)
    80004a18:	7402                	ld	s0,32(sp)
    80004a1a:	64e2                	ld	s1,24(sp)
    80004a1c:	6942                	ld	s2,16(sp)
    80004a1e:	69a2                	ld	s3,8(sp)
    80004a20:	6a02                	ld	s4,0(sp)
    80004a22:	6145                	addi	sp,sp,48
    80004a24:	8082                	ret
  return -1;
    80004a26:	557d                	li	a0,-1
    80004a28:	b7fd                	j	80004a16 <pipealloc+0xc6>

0000000080004a2a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a2a:	1101                	addi	sp,sp,-32
    80004a2c:	ec06                	sd	ra,24(sp)
    80004a2e:	e822                	sd	s0,16(sp)
    80004a30:	e426                	sd	s1,8(sp)
    80004a32:	e04a                	sd	s2,0(sp)
    80004a34:	1000                	addi	s0,sp,32
    80004a36:	84aa                	mv	s1,a0
    80004a38:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	1e0080e7          	jalr	480(ra) # 80000c1a <acquire>
  if(writable){
    80004a42:	02090d63          	beqz	s2,80004a7c <pipeclose+0x52>
    pi->writeopen = 0;
    80004a46:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a4a:	21848513          	addi	a0,s1,536
    80004a4e:	ffffd097          	auipc	ra,0xffffd
    80004a52:	7b8080e7          	jalr	1976(ra) # 80002206 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a56:	2204b783          	ld	a5,544(s1)
    80004a5a:	eb95                	bnez	a5,80004a8e <pipeclose+0x64>
    release(&pi->lock);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	270080e7          	jalr	624(ra) # 80000cce <release>
    kfree((char*)pi);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	f7a080e7          	jalr	-134(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004a70:	60e2                	ld	ra,24(sp)
    80004a72:	6442                	ld	s0,16(sp)
    80004a74:	64a2                	ld	s1,8(sp)
    80004a76:	6902                	ld	s2,0(sp)
    80004a78:	6105                	addi	sp,sp,32
    80004a7a:	8082                	ret
    pi->readopen = 0;
    80004a7c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a80:	21c48513          	addi	a0,s1,540
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	782080e7          	jalr	1922(ra) # 80002206 <wakeup>
    80004a8c:	b7e9                	j	80004a56 <pipeclose+0x2c>
    release(&pi->lock);
    80004a8e:	8526                	mv	a0,s1
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	23e080e7          	jalr	574(ra) # 80000cce <release>
}
    80004a98:	bfe1                	j	80004a70 <pipeclose+0x46>

0000000080004a9a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a9a:	711d                	addi	sp,sp,-96
    80004a9c:	ec86                	sd	ra,88(sp)
    80004a9e:	e8a2                	sd	s0,80(sp)
    80004aa0:	e4a6                	sd	s1,72(sp)
    80004aa2:	e0ca                	sd	s2,64(sp)
    80004aa4:	fc4e                	sd	s3,56(sp)
    80004aa6:	f852                	sd	s4,48(sp)
    80004aa8:	f456                	sd	s5,40(sp)
    80004aaa:	f05a                	sd	s6,32(sp)
    80004aac:	ec5e                	sd	s7,24(sp)
    80004aae:	e862                	sd	s8,16(sp)
    80004ab0:	1080                	addi	s0,sp,96
    80004ab2:	84aa                	mv	s1,a0
    80004ab4:	8aae                	mv	s5,a1
    80004ab6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ab8:	ffffd097          	auipc	ra,0xffffd
    80004abc:	efe080e7          	jalr	-258(ra) # 800019b6 <myproc>
    80004ac0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	156080e7          	jalr	342(ra) # 80000c1a <acquire>
  while(i < n){
    80004acc:	0b405363          	blez	s4,80004b72 <pipewrite+0xd8>
  int i = 0;
    80004ad0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ad4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ad8:	21c48b93          	addi	s7,s1,540
    80004adc:	a089                	j	80004b1e <pipewrite+0x84>
      release(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	1ee080e7          	jalr	494(ra) # 80000cce <release>
      return -1;
    80004ae8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004aea:	854a                	mv	a0,s2
    80004aec:	60e6                	ld	ra,88(sp)
    80004aee:	6446                	ld	s0,80(sp)
    80004af0:	64a6                	ld	s1,72(sp)
    80004af2:	6906                	ld	s2,64(sp)
    80004af4:	79e2                	ld	s3,56(sp)
    80004af6:	7a42                	ld	s4,48(sp)
    80004af8:	7aa2                	ld	s5,40(sp)
    80004afa:	7b02                	ld	s6,32(sp)
    80004afc:	6be2                	ld	s7,24(sp)
    80004afe:	6c42                	ld	s8,16(sp)
    80004b00:	6125                	addi	sp,sp,96
    80004b02:	8082                	ret
      wakeup(&pi->nread);
    80004b04:	8562                	mv	a0,s8
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	700080e7          	jalr	1792(ra) # 80002206 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b0e:	85a6                	mv	a1,s1
    80004b10:	855e                	mv	a0,s7
    80004b12:	ffffd097          	auipc	ra,0xffffd
    80004b16:	568080e7          	jalr	1384(ra) # 8000207a <sleep>
  while(i < n){
    80004b1a:	05495d63          	bge	s2,s4,80004b74 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004b1e:	2204a783          	lw	a5,544(s1)
    80004b22:	dfd5                	beqz	a5,80004ade <pipewrite+0x44>
    80004b24:	0289a783          	lw	a5,40(s3)
    80004b28:	fbdd                	bnez	a5,80004ade <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b2a:	2184a783          	lw	a5,536(s1)
    80004b2e:	21c4a703          	lw	a4,540(s1)
    80004b32:	2007879b          	addiw	a5,a5,512
    80004b36:	fcf707e3          	beq	a4,a5,80004b04 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3a:	4685                	li	a3,1
    80004b3c:	01590633          	add	a2,s2,s5
    80004b40:	faf40593          	addi	a1,s0,-81
    80004b44:	0509b503          	ld	a0,80(s3)
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	bbe080e7          	jalr	-1090(ra) # 80001706 <copyin>
    80004b50:	03650263          	beq	a0,s6,80004b74 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b54:	21c4a783          	lw	a5,540(s1)
    80004b58:	0017871b          	addiw	a4,a5,1
    80004b5c:	20e4ae23          	sw	a4,540(s1)
    80004b60:	1ff7f793          	andi	a5,a5,511
    80004b64:	97a6                	add	a5,a5,s1
    80004b66:	faf44703          	lbu	a4,-81(s0)
    80004b6a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b6e:	2905                	addiw	s2,s2,1
    80004b70:	b76d                	j	80004b1a <pipewrite+0x80>
  int i = 0;
    80004b72:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b74:	21848513          	addi	a0,s1,536
    80004b78:	ffffd097          	auipc	ra,0xffffd
    80004b7c:	68e080e7          	jalr	1678(ra) # 80002206 <wakeup>
  release(&pi->lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	14c080e7          	jalr	332(ra) # 80000cce <release>
  return i;
    80004b8a:	b785                	j	80004aea <pipewrite+0x50>

0000000080004b8c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b8c:	715d                	addi	sp,sp,-80
    80004b8e:	e486                	sd	ra,72(sp)
    80004b90:	e0a2                	sd	s0,64(sp)
    80004b92:	fc26                	sd	s1,56(sp)
    80004b94:	f84a                	sd	s2,48(sp)
    80004b96:	f44e                	sd	s3,40(sp)
    80004b98:	f052                	sd	s4,32(sp)
    80004b9a:	ec56                	sd	s5,24(sp)
    80004b9c:	e85a                	sd	s6,16(sp)
    80004b9e:	0880                	addi	s0,sp,80
    80004ba0:	84aa                	mv	s1,a0
    80004ba2:	892e                	mv	s2,a1
    80004ba4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	e10080e7          	jalr	-496(ra) # 800019b6 <myproc>
    80004bae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	068080e7          	jalr	104(ra) # 80000c1a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bba:	2184a703          	lw	a4,536(s1)
    80004bbe:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bc6:	02f71463          	bne	a4,a5,80004bee <piperead+0x62>
    80004bca:	2244a783          	lw	a5,548(s1)
    80004bce:	c385                	beqz	a5,80004bee <piperead+0x62>
    if(pr->killed){
    80004bd0:	028a2783          	lw	a5,40(s4)
    80004bd4:	ebc9                	bnez	a5,80004c66 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bd6:	85a6                	mv	a1,s1
    80004bd8:	854e                	mv	a0,s3
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	4a0080e7          	jalr	1184(ra) # 8000207a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be2:	2184a703          	lw	a4,536(s1)
    80004be6:	21c4a783          	lw	a5,540(s1)
    80004bea:	fef700e3          	beq	a4,a5,80004bca <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bee:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bf0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf2:	05505463          	blez	s5,80004c3a <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004bf6:	2184a783          	lw	a5,536(s1)
    80004bfa:	21c4a703          	lw	a4,540(s1)
    80004bfe:	02f70e63          	beq	a4,a5,80004c3a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c02:	0017871b          	addiw	a4,a5,1
    80004c06:	20e4ac23          	sw	a4,536(s1)
    80004c0a:	1ff7f793          	andi	a5,a5,511
    80004c0e:	97a6                	add	a5,a5,s1
    80004c10:	0187c783          	lbu	a5,24(a5)
    80004c14:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c18:	4685                	li	a3,1
    80004c1a:	fbf40613          	addi	a2,s0,-65
    80004c1e:	85ca                	mv	a1,s2
    80004c20:	050a3503          	ld	a0,80(s4)
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	a56080e7          	jalr	-1450(ra) # 8000167a <copyout>
    80004c2c:	01650763          	beq	a0,s6,80004c3a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c30:	2985                	addiw	s3,s3,1
    80004c32:	0905                	addi	s2,s2,1
    80004c34:	fd3a91e3          	bne	s5,s3,80004bf6 <piperead+0x6a>
    80004c38:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c3a:	21c48513          	addi	a0,s1,540
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	5c8080e7          	jalr	1480(ra) # 80002206 <wakeup>
  release(&pi->lock);
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	086080e7          	jalr	134(ra) # 80000cce <release>
  return i;
}
    80004c50:	854e                	mv	a0,s3
    80004c52:	60a6                	ld	ra,72(sp)
    80004c54:	6406                	ld	s0,64(sp)
    80004c56:	74e2                	ld	s1,56(sp)
    80004c58:	7942                	ld	s2,48(sp)
    80004c5a:	79a2                	ld	s3,40(sp)
    80004c5c:	7a02                	ld	s4,32(sp)
    80004c5e:	6ae2                	ld	s5,24(sp)
    80004c60:	6b42                	ld	s6,16(sp)
    80004c62:	6161                	addi	sp,sp,80
    80004c64:	8082                	ret
      release(&pi->lock);
    80004c66:	8526                	mv	a0,s1
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	066080e7          	jalr	102(ra) # 80000cce <release>
      return -1;
    80004c70:	59fd                	li	s3,-1
    80004c72:	bff9                	j	80004c50 <piperead+0xc4>

0000000080004c74 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c74:	de010113          	addi	sp,sp,-544
    80004c78:	20113c23          	sd	ra,536(sp)
    80004c7c:	20813823          	sd	s0,528(sp)
    80004c80:	20913423          	sd	s1,520(sp)
    80004c84:	21213023          	sd	s2,512(sp)
    80004c88:	ffce                	sd	s3,504(sp)
    80004c8a:	fbd2                	sd	s4,496(sp)
    80004c8c:	f7d6                	sd	s5,488(sp)
    80004c8e:	f3da                	sd	s6,480(sp)
    80004c90:	efde                	sd	s7,472(sp)
    80004c92:	ebe2                	sd	s8,464(sp)
    80004c94:	e7e6                	sd	s9,456(sp)
    80004c96:	e3ea                	sd	s10,448(sp)
    80004c98:	ff6e                	sd	s11,440(sp)
    80004c9a:	1400                	addi	s0,sp,544
    80004c9c:	892a                	mv	s2,a0
    80004c9e:	dea43423          	sd	a0,-536(s0)
    80004ca2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	d10080e7          	jalr	-752(ra) # 800019b6 <myproc>
    80004cae:	84aa                	mv	s1,a0

  begin_op();
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	4a8080e7          	jalr	1192(ra) # 80004158 <begin_op>

  if((ip = namei(path)) == 0){
    80004cb8:	854a                	mv	a0,s2
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	27e080e7          	jalr	638(ra) # 80003f38 <namei>
    80004cc2:	c93d                	beqz	a0,80004d38 <exec+0xc4>
    80004cc4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	ab6080e7          	jalr	-1354(ra) # 8000377c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cce:	04000713          	li	a4,64
    80004cd2:	4681                	li	a3,0
    80004cd4:	e5040613          	addi	a2,s0,-432
    80004cd8:	4581                	li	a1,0
    80004cda:	8556                	mv	a0,s5
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	d54080e7          	jalr	-684(ra) # 80003a30 <readi>
    80004ce4:	04000793          	li	a5,64
    80004ce8:	00f51a63          	bne	a0,a5,80004cfc <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cec:	e5042703          	lw	a4,-432(s0)
    80004cf0:	464c47b7          	lui	a5,0x464c4
    80004cf4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cf8:	04f70663          	beq	a4,a5,80004d44 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cfc:	8556                	mv	a0,s5
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	ce0080e7          	jalr	-800(ra) # 800039de <iunlockput>
    end_op();
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	4d0080e7          	jalr	1232(ra) # 800041d6 <end_op>
  }
  return -1;
    80004d0e:	557d                	li	a0,-1
}
    80004d10:	21813083          	ld	ra,536(sp)
    80004d14:	21013403          	ld	s0,528(sp)
    80004d18:	20813483          	ld	s1,520(sp)
    80004d1c:	20013903          	ld	s2,512(sp)
    80004d20:	79fe                	ld	s3,504(sp)
    80004d22:	7a5e                	ld	s4,496(sp)
    80004d24:	7abe                	ld	s5,488(sp)
    80004d26:	7b1e                	ld	s6,480(sp)
    80004d28:	6bfe                	ld	s7,472(sp)
    80004d2a:	6c5e                	ld	s8,464(sp)
    80004d2c:	6cbe                	ld	s9,456(sp)
    80004d2e:	6d1e                	ld	s10,448(sp)
    80004d30:	7dfa                	ld	s11,440(sp)
    80004d32:	22010113          	addi	sp,sp,544
    80004d36:	8082                	ret
    end_op();
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	49e080e7          	jalr	1182(ra) # 800041d6 <end_op>
    return -1;
    80004d40:	557d                	li	a0,-1
    80004d42:	b7f9                	j	80004d10 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d44:	8526                	mv	a0,s1
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	d34080e7          	jalr	-716(ra) # 80001a7a <proc_pagetable>
    80004d4e:	8b2a                	mv	s6,a0
    80004d50:	d555                	beqz	a0,80004cfc <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d52:	e7042783          	lw	a5,-400(s0)
    80004d56:	e8845703          	lhu	a4,-376(s0)
    80004d5a:	c735                	beqz	a4,80004dc6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d5c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d5e:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004d62:	6a05                	lui	s4,0x1
    80004d64:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d68:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d6c:	6d85                	lui	s11,0x1
    80004d6e:	7d7d                	lui	s10,0xfffff
    80004d70:	ac1d                	j	80004fa6 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d72:	00004517          	auipc	a0,0x4
    80004d76:	99650513          	addi	a0,a0,-1642 # 80008708 <syscalls+0x290>
    80004d7a:	ffffb097          	auipc	ra,0xffffb
    80004d7e:	7c0080e7          	jalr	1984(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d82:	874a                	mv	a4,s2
    80004d84:	009c86bb          	addw	a3,s9,s1
    80004d88:	4581                	li	a1,0
    80004d8a:	8556                	mv	a0,s5
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	ca4080e7          	jalr	-860(ra) # 80003a30 <readi>
    80004d94:	2501                	sext.w	a0,a0
    80004d96:	1aa91863          	bne	s2,a0,80004f46 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d9a:	009d84bb          	addw	s1,s11,s1
    80004d9e:	013d09bb          	addw	s3,s10,s3
    80004da2:	1f74f263          	bgeu	s1,s7,80004f86 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004da6:	02049593          	slli	a1,s1,0x20
    80004daa:	9181                	srli	a1,a1,0x20
    80004dac:	95e2                	add	a1,a1,s8
    80004dae:	855a                	mv	a0,s6
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	2ec080e7          	jalr	748(ra) # 8000109c <walkaddr>
    80004db8:	862a                	mv	a2,a0
    if(pa == 0)
    80004dba:	dd45                	beqz	a0,80004d72 <exec+0xfe>
      n = PGSIZE;
    80004dbc:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dbe:	fd49f2e3          	bgeu	s3,s4,80004d82 <exec+0x10e>
      n = sz - i;
    80004dc2:	894e                	mv	s2,s3
    80004dc4:	bf7d                	j	80004d82 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dc6:	4481                	li	s1,0
  iunlockput(ip);
    80004dc8:	8556                	mv	a0,s5
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	c14080e7          	jalr	-1004(ra) # 800039de <iunlockput>
  end_op();
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	404080e7          	jalr	1028(ra) # 800041d6 <end_op>
  p = myproc();
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	bdc080e7          	jalr	-1060(ra) # 800019b6 <myproc>
    80004de2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004de4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004de8:	6785                	lui	a5,0x1
    80004dea:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004dec:	97a6                	add	a5,a5,s1
    80004dee:	777d                	lui	a4,0xfffff
    80004df0:	8ff9                	and	a5,a5,a4
    80004df2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004df6:	6609                	lui	a2,0x2
    80004df8:	963e                	add	a2,a2,a5
    80004dfa:	85be                	mv	a1,a5
    80004dfc:	855a                	mv	a0,s6
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	634080e7          	jalr	1588(ra) # 80001432 <uvmalloc>
    80004e06:	8c2a                	mv	s8,a0
  ip = 0;
    80004e08:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e0a:	12050e63          	beqz	a0,80004f46 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e0e:	75f9                	lui	a1,0xffffe
    80004e10:	95aa                	add	a1,a1,a0
    80004e12:	855a                	mv	a0,s6
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	834080e7          	jalr	-1996(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e1c:	7afd                	lui	s5,0xfffff
    80004e1e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e20:	df043783          	ld	a5,-528(s0)
    80004e24:	6388                	ld	a0,0(a5)
    80004e26:	c925                	beqz	a0,80004e96 <exec+0x222>
    80004e28:	e9040993          	addi	s3,s0,-368
    80004e2c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e30:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e32:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e34:	ffffc097          	auipc	ra,0xffffc
    80004e38:	05e080e7          	jalr	94(ra) # 80000e92 <strlen>
    80004e3c:	0015079b          	addiw	a5,a0,1
    80004e40:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e44:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e48:	13596363          	bltu	s2,s5,80004f6e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e4c:	df043d83          	ld	s11,-528(s0)
    80004e50:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e54:	8552                	mv	a0,s4
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	03c080e7          	jalr	60(ra) # 80000e92 <strlen>
    80004e5e:	0015069b          	addiw	a3,a0,1
    80004e62:	8652                	mv	a2,s4
    80004e64:	85ca                	mv	a1,s2
    80004e66:	855a                	mv	a0,s6
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	812080e7          	jalr	-2030(ra) # 8000167a <copyout>
    80004e70:	10054363          	bltz	a0,80004f76 <exec+0x302>
    ustack[argc] = sp;
    80004e74:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e78:	0485                	addi	s1,s1,1
    80004e7a:	008d8793          	addi	a5,s11,8
    80004e7e:	def43823          	sd	a5,-528(s0)
    80004e82:	008db503          	ld	a0,8(s11)
    80004e86:	c911                	beqz	a0,80004e9a <exec+0x226>
    if(argc >= MAXARG)
    80004e88:	09a1                	addi	s3,s3,8
    80004e8a:	fb3c95e3          	bne	s9,s3,80004e34 <exec+0x1c0>
  sz = sz1;
    80004e8e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e92:	4a81                	li	s5,0
    80004e94:	a84d                	j	80004f46 <exec+0x2d2>
  sp = sz;
    80004e96:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e98:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e9a:	00349793          	slli	a5,s1,0x3
    80004e9e:	f9078793          	addi	a5,a5,-112
    80004ea2:	97a2                	add	a5,a5,s0
    80004ea4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ea8:	00148693          	addi	a3,s1,1
    80004eac:	068e                	slli	a3,a3,0x3
    80004eae:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eb2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eb6:	01597663          	bgeu	s2,s5,80004ec2 <exec+0x24e>
  sz = sz1;
    80004eba:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ebe:	4a81                	li	s5,0
    80004ec0:	a059                	j	80004f46 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ec2:	e9040613          	addi	a2,s0,-368
    80004ec6:	85ca                	mv	a1,s2
    80004ec8:	855a                	mv	a0,s6
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	7b0080e7          	jalr	1968(ra) # 8000167a <copyout>
    80004ed2:	0a054663          	bltz	a0,80004f7e <exec+0x30a>
  p->trapframe->a1 = sp;
    80004ed6:	058bb783          	ld	a5,88(s7)
    80004eda:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ede:	de843783          	ld	a5,-536(s0)
    80004ee2:	0007c703          	lbu	a4,0(a5)
    80004ee6:	cf11                	beqz	a4,80004f02 <exec+0x28e>
    80004ee8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eea:	02f00693          	li	a3,47
    80004eee:	a039                	j	80004efc <exec+0x288>
      last = s+1;
    80004ef0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ef4:	0785                	addi	a5,a5,1
    80004ef6:	fff7c703          	lbu	a4,-1(a5)
    80004efa:	c701                	beqz	a4,80004f02 <exec+0x28e>
    if(*s == '/')
    80004efc:	fed71ce3          	bne	a4,a3,80004ef4 <exec+0x280>
    80004f00:	bfc5                	j	80004ef0 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f02:	4641                	li	a2,16
    80004f04:	de843583          	ld	a1,-536(s0)
    80004f08:	158b8513          	addi	a0,s7,344
    80004f0c:	ffffc097          	auipc	ra,0xffffc
    80004f10:	f54080e7          	jalr	-172(ra) # 80000e60 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f14:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f18:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f1c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f20:	058bb783          	ld	a5,88(s7)
    80004f24:	e6843703          	ld	a4,-408(s0)
    80004f28:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f2a:	058bb783          	ld	a5,88(s7)
    80004f2e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f32:	85ea                	mv	a1,s10
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	be2080e7          	jalr	-1054(ra) # 80001b16 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f3c:	0004851b          	sext.w	a0,s1
    80004f40:	bbc1                	j	80004d10 <exec+0x9c>
    80004f42:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f46:	df843583          	ld	a1,-520(s0)
    80004f4a:	855a                	mv	a0,s6
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	bca080e7          	jalr	-1078(ra) # 80001b16 <proc_freepagetable>
  if(ip){
    80004f54:	da0a94e3          	bnez	s5,80004cfc <exec+0x88>
  return -1;
    80004f58:	557d                	li	a0,-1
    80004f5a:	bb5d                	j	80004d10 <exec+0x9c>
    80004f5c:	de943c23          	sd	s1,-520(s0)
    80004f60:	b7dd                	j	80004f46 <exec+0x2d2>
    80004f62:	de943c23          	sd	s1,-520(s0)
    80004f66:	b7c5                	j	80004f46 <exec+0x2d2>
    80004f68:	de943c23          	sd	s1,-520(s0)
    80004f6c:	bfe9                	j	80004f46 <exec+0x2d2>
  sz = sz1;
    80004f6e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f72:	4a81                	li	s5,0
    80004f74:	bfc9                	j	80004f46 <exec+0x2d2>
  sz = sz1;
    80004f76:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f7a:	4a81                	li	s5,0
    80004f7c:	b7e9                	j	80004f46 <exec+0x2d2>
  sz = sz1;
    80004f7e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f82:	4a81                	li	s5,0
    80004f84:	b7c9                	j	80004f46 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f86:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f8a:	e0843783          	ld	a5,-504(s0)
    80004f8e:	0017869b          	addiw	a3,a5,1
    80004f92:	e0d43423          	sd	a3,-504(s0)
    80004f96:	e0043783          	ld	a5,-512(s0)
    80004f9a:	0387879b          	addiw	a5,a5,56
    80004f9e:	e8845703          	lhu	a4,-376(s0)
    80004fa2:	e2e6d3e3          	bge	a3,a4,80004dc8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fa6:	2781                	sext.w	a5,a5
    80004fa8:	e0f43023          	sd	a5,-512(s0)
    80004fac:	03800713          	li	a4,56
    80004fb0:	86be                	mv	a3,a5
    80004fb2:	e1840613          	addi	a2,s0,-488
    80004fb6:	4581                	li	a1,0
    80004fb8:	8556                	mv	a0,s5
    80004fba:	fffff097          	auipc	ra,0xfffff
    80004fbe:	a76080e7          	jalr	-1418(ra) # 80003a30 <readi>
    80004fc2:	03800793          	li	a5,56
    80004fc6:	f6f51ee3          	bne	a0,a5,80004f42 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004fca:	e1842783          	lw	a5,-488(s0)
    80004fce:	4705                	li	a4,1
    80004fd0:	fae79de3          	bne	a5,a4,80004f8a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004fd4:	e4043603          	ld	a2,-448(s0)
    80004fd8:	e3843783          	ld	a5,-456(s0)
    80004fdc:	f8f660e3          	bltu	a2,a5,80004f5c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fe0:	e2843783          	ld	a5,-472(s0)
    80004fe4:	963e                	add	a2,a2,a5
    80004fe6:	f6f66ee3          	bltu	a2,a5,80004f62 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fea:	85a6                	mv	a1,s1
    80004fec:	855a                	mv	a0,s6
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	444080e7          	jalr	1092(ra) # 80001432 <uvmalloc>
    80004ff6:	dea43c23          	sd	a0,-520(s0)
    80004ffa:	d53d                	beqz	a0,80004f68 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004ffc:	e2843c03          	ld	s8,-472(s0)
    80005000:	de043783          	ld	a5,-544(s0)
    80005004:	00fc77b3          	and	a5,s8,a5
    80005008:	ff9d                	bnez	a5,80004f46 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000500a:	e2042c83          	lw	s9,-480(s0)
    8000500e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005012:	f60b8ae3          	beqz	s7,80004f86 <exec+0x312>
    80005016:	89de                	mv	s3,s7
    80005018:	4481                	li	s1,0
    8000501a:	b371                	j	80004da6 <exec+0x132>

000000008000501c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000501c:	7179                	addi	sp,sp,-48
    8000501e:	f406                	sd	ra,40(sp)
    80005020:	f022                	sd	s0,32(sp)
    80005022:	ec26                	sd	s1,24(sp)
    80005024:	e84a                	sd	s2,16(sp)
    80005026:	1800                	addi	s0,sp,48
    80005028:	892e                	mv	s2,a1
    8000502a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000502c:	fdc40593          	addi	a1,s0,-36
    80005030:	ffffe097          	auipc	ra,0xffffe
    80005034:	b8a080e7          	jalr	-1142(ra) # 80002bba <argint>
    80005038:	04054063          	bltz	a0,80005078 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000503c:	fdc42703          	lw	a4,-36(s0)
    80005040:	47bd                	li	a5,15
    80005042:	02e7ed63          	bltu	a5,a4,8000507c <argfd+0x60>
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	970080e7          	jalr	-1680(ra) # 800019b6 <myproc>
    8000504e:	fdc42703          	lw	a4,-36(s0)
    80005052:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80005056:	078e                	slli	a5,a5,0x3
    80005058:	953e                	add	a0,a0,a5
    8000505a:	611c                	ld	a5,0(a0)
    8000505c:	c395                	beqz	a5,80005080 <argfd+0x64>
    return -1;
  if(pfd)
    8000505e:	00090463          	beqz	s2,80005066 <argfd+0x4a>
    *pfd = fd;
    80005062:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005066:	4501                	li	a0,0
  if(pf)
    80005068:	c091                	beqz	s1,8000506c <argfd+0x50>
    *pf = f;
    8000506a:	e09c                	sd	a5,0(s1)
}
    8000506c:	70a2                	ld	ra,40(sp)
    8000506e:	7402                	ld	s0,32(sp)
    80005070:	64e2                	ld	s1,24(sp)
    80005072:	6942                	ld	s2,16(sp)
    80005074:	6145                	addi	sp,sp,48
    80005076:	8082                	ret
    return -1;
    80005078:	557d                	li	a0,-1
    8000507a:	bfcd                	j	8000506c <argfd+0x50>
    return -1;
    8000507c:	557d                	li	a0,-1
    8000507e:	b7fd                	j	8000506c <argfd+0x50>
    80005080:	557d                	li	a0,-1
    80005082:	b7ed                	j	8000506c <argfd+0x50>

0000000080005084 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005084:	1101                	addi	sp,sp,-32
    80005086:	ec06                	sd	ra,24(sp)
    80005088:	e822                	sd	s0,16(sp)
    8000508a:	e426                	sd	s1,8(sp)
    8000508c:	1000                	addi	s0,sp,32
    8000508e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	926080e7          	jalr	-1754(ra) # 800019b6 <myproc>
    80005098:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000509a:	0d050793          	addi	a5,a0,208
    8000509e:	4501                	li	a0,0
    800050a0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050a2:	6398                	ld	a4,0(a5)
    800050a4:	cb19                	beqz	a4,800050ba <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050a6:	2505                	addiw	a0,a0,1
    800050a8:	07a1                	addi	a5,a5,8
    800050aa:	fed51ce3          	bne	a0,a3,800050a2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ae:	557d                	li	a0,-1
}
    800050b0:	60e2                	ld	ra,24(sp)
    800050b2:	6442                	ld	s0,16(sp)
    800050b4:	64a2                	ld	s1,8(sp)
    800050b6:	6105                	addi	sp,sp,32
    800050b8:	8082                	ret
      p->ofile[fd] = f;
    800050ba:	01a50793          	addi	a5,a0,26
    800050be:	078e                	slli	a5,a5,0x3
    800050c0:	963e                	add	a2,a2,a5
    800050c2:	e204                	sd	s1,0(a2)
      return fd;
    800050c4:	b7f5                	j	800050b0 <fdalloc+0x2c>

00000000800050c6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050c6:	715d                	addi	sp,sp,-80
    800050c8:	e486                	sd	ra,72(sp)
    800050ca:	e0a2                	sd	s0,64(sp)
    800050cc:	fc26                	sd	s1,56(sp)
    800050ce:	f84a                	sd	s2,48(sp)
    800050d0:	f44e                	sd	s3,40(sp)
    800050d2:	f052                	sd	s4,32(sp)
    800050d4:	ec56                	sd	s5,24(sp)
    800050d6:	0880                	addi	s0,sp,80
    800050d8:	89ae                	mv	s3,a1
    800050da:	8ab2                	mv	s5,a2
    800050dc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050de:	fb040593          	addi	a1,s0,-80
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	e74080e7          	jalr	-396(ra) # 80003f56 <nameiparent>
    800050ea:	892a                	mv	s2,a0
    800050ec:	12050e63          	beqz	a0,80005228 <create+0x162>
    return 0;

  ilock(dp);
    800050f0:	ffffe097          	auipc	ra,0xffffe
    800050f4:	68c080e7          	jalr	1676(ra) # 8000377c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050f8:	4601                	li	a2,0
    800050fa:	fb040593          	addi	a1,s0,-80
    800050fe:	854a                	mv	a0,s2
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	b60080e7          	jalr	-1184(ra) # 80003c60 <dirlookup>
    80005108:	84aa                	mv	s1,a0
    8000510a:	c921                	beqz	a0,8000515a <create+0x94>
    iunlockput(dp);
    8000510c:	854a                	mv	a0,s2
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	8d0080e7          	jalr	-1840(ra) # 800039de <iunlockput>
    ilock(ip);
    80005116:	8526                	mv	a0,s1
    80005118:	ffffe097          	auipc	ra,0xffffe
    8000511c:	664080e7          	jalr	1636(ra) # 8000377c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005120:	2981                	sext.w	s3,s3
    80005122:	4789                	li	a5,2
    80005124:	02f99463          	bne	s3,a5,8000514c <create+0x86>
    80005128:	0444d783          	lhu	a5,68(s1)
    8000512c:	37f9                	addiw	a5,a5,-2
    8000512e:	17c2                	slli	a5,a5,0x30
    80005130:	93c1                	srli	a5,a5,0x30
    80005132:	4705                	li	a4,1
    80005134:	00f76c63          	bltu	a4,a5,8000514c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005138:	8526                	mv	a0,s1
    8000513a:	60a6                	ld	ra,72(sp)
    8000513c:	6406                	ld	s0,64(sp)
    8000513e:	74e2                	ld	s1,56(sp)
    80005140:	7942                	ld	s2,48(sp)
    80005142:	79a2                	ld	s3,40(sp)
    80005144:	7a02                	ld	s4,32(sp)
    80005146:	6ae2                	ld	s5,24(sp)
    80005148:	6161                	addi	sp,sp,80
    8000514a:	8082                	ret
    iunlockput(ip);
    8000514c:	8526                	mv	a0,s1
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	890080e7          	jalr	-1904(ra) # 800039de <iunlockput>
    return 0;
    80005156:	4481                	li	s1,0
    80005158:	b7c5                	j	80005138 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000515a:	85ce                	mv	a1,s3
    8000515c:	00092503          	lw	a0,0(s2)
    80005160:	ffffe097          	auipc	ra,0xffffe
    80005164:	482080e7          	jalr	1154(ra) # 800035e2 <ialloc>
    80005168:	84aa                	mv	s1,a0
    8000516a:	c521                	beqz	a0,800051b2 <create+0xec>
  ilock(ip);
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	610080e7          	jalr	1552(ra) # 8000377c <ilock>
  ip->major = major;
    80005174:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005178:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000517c:	4a05                	li	s4,1
    8000517e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005182:	8526                	mv	a0,s1
    80005184:	ffffe097          	auipc	ra,0xffffe
    80005188:	52c080e7          	jalr	1324(ra) # 800036b0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000518c:	2981                	sext.w	s3,s3
    8000518e:	03498a63          	beq	s3,s4,800051c2 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005192:	40d0                	lw	a2,4(s1)
    80005194:	fb040593          	addi	a1,s0,-80
    80005198:	854a                	mv	a0,s2
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	cdc080e7          	jalr	-804(ra) # 80003e76 <dirlink>
    800051a2:	06054b63          	bltz	a0,80005218 <create+0x152>
  iunlockput(dp);
    800051a6:	854a                	mv	a0,s2
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	836080e7          	jalr	-1994(ra) # 800039de <iunlockput>
  return ip;
    800051b0:	b761                	j	80005138 <create+0x72>
    panic("create: ialloc");
    800051b2:	00003517          	auipc	a0,0x3
    800051b6:	57650513          	addi	a0,a0,1398 # 80008728 <syscalls+0x2b0>
    800051ba:	ffffb097          	auipc	ra,0xffffb
    800051be:	380080e7          	jalr	896(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    800051c2:	04a95783          	lhu	a5,74(s2)
    800051c6:	2785                	addiw	a5,a5,1
    800051c8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051cc:	854a                	mv	a0,s2
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	4e2080e7          	jalr	1250(ra) # 800036b0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051d6:	40d0                	lw	a2,4(s1)
    800051d8:	00003597          	auipc	a1,0x3
    800051dc:	56058593          	addi	a1,a1,1376 # 80008738 <syscalls+0x2c0>
    800051e0:	8526                	mv	a0,s1
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	c94080e7          	jalr	-876(ra) # 80003e76 <dirlink>
    800051ea:	00054f63          	bltz	a0,80005208 <create+0x142>
    800051ee:	00492603          	lw	a2,4(s2)
    800051f2:	00003597          	auipc	a1,0x3
    800051f6:	54e58593          	addi	a1,a1,1358 # 80008740 <syscalls+0x2c8>
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	c7a080e7          	jalr	-902(ra) # 80003e76 <dirlink>
    80005204:	f80557e3          	bgez	a0,80005192 <create+0xcc>
      panic("create dots");
    80005208:	00003517          	auipc	a0,0x3
    8000520c:	54050513          	addi	a0,a0,1344 # 80008748 <syscalls+0x2d0>
    80005210:	ffffb097          	auipc	ra,0xffffb
    80005214:	32a080e7          	jalr	810(ra) # 8000053a <panic>
    panic("create: dirlink");
    80005218:	00003517          	auipc	a0,0x3
    8000521c:	54050513          	addi	a0,a0,1344 # 80008758 <syscalls+0x2e0>
    80005220:	ffffb097          	auipc	ra,0xffffb
    80005224:	31a080e7          	jalr	794(ra) # 8000053a <panic>
    return 0;
    80005228:	84aa                	mv	s1,a0
    8000522a:	b739                	j	80005138 <create+0x72>

000000008000522c <sys_dup>:
{
    8000522c:	7179                	addi	sp,sp,-48
    8000522e:	f406                	sd	ra,40(sp)
    80005230:	f022                	sd	s0,32(sp)
    80005232:	ec26                	sd	s1,24(sp)
    80005234:	e84a                	sd	s2,16(sp)
    80005236:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005238:	fd840613          	addi	a2,s0,-40
    8000523c:	4581                	li	a1,0
    8000523e:	4501                	li	a0,0
    80005240:	00000097          	auipc	ra,0x0
    80005244:	ddc080e7          	jalr	-548(ra) # 8000501c <argfd>
    return -1;
    80005248:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000524a:	02054363          	bltz	a0,80005270 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000524e:	fd843903          	ld	s2,-40(s0)
    80005252:	854a                	mv	a0,s2
    80005254:	00000097          	auipc	ra,0x0
    80005258:	e30080e7          	jalr	-464(ra) # 80005084 <fdalloc>
    8000525c:	84aa                	mv	s1,a0
    return -1;
    8000525e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005260:	00054863          	bltz	a0,80005270 <sys_dup+0x44>
  filedup(f);
    80005264:	854a                	mv	a0,s2
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	368080e7          	jalr	872(ra) # 800045ce <filedup>
  return fd;
    8000526e:	87a6                	mv	a5,s1
}
    80005270:	853e                	mv	a0,a5
    80005272:	70a2                	ld	ra,40(sp)
    80005274:	7402                	ld	s0,32(sp)
    80005276:	64e2                	ld	s1,24(sp)
    80005278:	6942                	ld	s2,16(sp)
    8000527a:	6145                	addi	sp,sp,48
    8000527c:	8082                	ret

000000008000527e <sys_read>:
{
    8000527e:	7179                	addi	sp,sp,-48
    80005280:	f406                	sd	ra,40(sp)
    80005282:	f022                	sd	s0,32(sp)
    80005284:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005286:	fe840613          	addi	a2,s0,-24
    8000528a:	4581                	li	a1,0
    8000528c:	4501                	li	a0,0
    8000528e:	00000097          	auipc	ra,0x0
    80005292:	d8e080e7          	jalr	-626(ra) # 8000501c <argfd>
    return -1;
    80005296:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005298:	04054163          	bltz	a0,800052da <sys_read+0x5c>
    8000529c:	fe440593          	addi	a1,s0,-28
    800052a0:	4509                	li	a0,2
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	918080e7          	jalr	-1768(ra) # 80002bba <argint>
    return -1;
    800052aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ac:	02054763          	bltz	a0,800052da <sys_read+0x5c>
    800052b0:	fd840593          	addi	a1,s0,-40
    800052b4:	4505                	li	a0,1
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	926080e7          	jalr	-1754(ra) # 80002bdc <argaddr>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	00054d63          	bltz	a0,800052da <sys_read+0x5c>
  return fileread(f, p, n);
    800052c4:	fe442603          	lw	a2,-28(s0)
    800052c8:	fd843583          	ld	a1,-40(s0)
    800052cc:	fe843503          	ld	a0,-24(s0)
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	48a080e7          	jalr	1162(ra) # 8000475a <fileread>
    800052d8:	87aa                	mv	a5,a0
}
    800052da:	853e                	mv	a0,a5
    800052dc:	70a2                	ld	ra,40(sp)
    800052de:	7402                	ld	s0,32(sp)
    800052e0:	6145                	addi	sp,sp,48
    800052e2:	8082                	ret

00000000800052e4 <sys_write>:
{
    800052e4:	7179                	addi	sp,sp,-48
    800052e6:	f406                	sd	ra,40(sp)
    800052e8:	f022                	sd	s0,32(sp)
    800052ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ec:	fe840613          	addi	a2,s0,-24
    800052f0:	4581                	li	a1,0
    800052f2:	4501                	li	a0,0
    800052f4:	00000097          	auipc	ra,0x0
    800052f8:	d28080e7          	jalr	-728(ra) # 8000501c <argfd>
    return -1;
    800052fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fe:	04054163          	bltz	a0,80005340 <sys_write+0x5c>
    80005302:	fe440593          	addi	a1,s0,-28
    80005306:	4509                	li	a0,2
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	8b2080e7          	jalr	-1870(ra) # 80002bba <argint>
    return -1;
    80005310:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005312:	02054763          	bltz	a0,80005340 <sys_write+0x5c>
    80005316:	fd840593          	addi	a1,s0,-40
    8000531a:	4505                	li	a0,1
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	8c0080e7          	jalr	-1856(ra) # 80002bdc <argaddr>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	00054d63          	bltz	a0,80005340 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000532a:	fe442603          	lw	a2,-28(s0)
    8000532e:	fd843583          	ld	a1,-40(s0)
    80005332:	fe843503          	ld	a0,-24(s0)
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	4e6080e7          	jalr	1254(ra) # 8000481c <filewrite>
    8000533e:	87aa                	mv	a5,a0
}
    80005340:	853e                	mv	a0,a5
    80005342:	70a2                	ld	ra,40(sp)
    80005344:	7402                	ld	s0,32(sp)
    80005346:	6145                	addi	sp,sp,48
    80005348:	8082                	ret

000000008000534a <sys_close>:
{
    8000534a:	1101                	addi	sp,sp,-32
    8000534c:	ec06                	sd	ra,24(sp)
    8000534e:	e822                	sd	s0,16(sp)
    80005350:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005352:	fe040613          	addi	a2,s0,-32
    80005356:	fec40593          	addi	a1,s0,-20
    8000535a:	4501                	li	a0,0
    8000535c:	00000097          	auipc	ra,0x0
    80005360:	cc0080e7          	jalr	-832(ra) # 8000501c <argfd>
    return -1;
    80005364:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005366:	02054463          	bltz	a0,8000538e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	64c080e7          	jalr	1612(ra) # 800019b6 <myproc>
    80005372:	fec42783          	lw	a5,-20(s0)
    80005376:	07e9                	addi	a5,a5,26
    80005378:	078e                	slli	a5,a5,0x3
    8000537a:	953e                	add	a0,a0,a5
    8000537c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005380:	fe043503          	ld	a0,-32(s0)
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	29c080e7          	jalr	668(ra) # 80004620 <fileclose>
  return 0;
    8000538c:	4781                	li	a5,0
}
    8000538e:	853e                	mv	a0,a5
    80005390:	60e2                	ld	ra,24(sp)
    80005392:	6442                	ld	s0,16(sp)
    80005394:	6105                	addi	sp,sp,32
    80005396:	8082                	ret

0000000080005398 <sys_fstat>:
{
    80005398:	1101                	addi	sp,sp,-32
    8000539a:	ec06                	sd	ra,24(sp)
    8000539c:	e822                	sd	s0,16(sp)
    8000539e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053a0:	fe840613          	addi	a2,s0,-24
    800053a4:	4581                	li	a1,0
    800053a6:	4501                	li	a0,0
    800053a8:	00000097          	auipc	ra,0x0
    800053ac:	c74080e7          	jalr	-908(ra) # 8000501c <argfd>
    return -1;
    800053b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053b2:	02054563          	bltz	a0,800053dc <sys_fstat+0x44>
    800053b6:	fe040593          	addi	a1,s0,-32
    800053ba:	4505                	li	a0,1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	820080e7          	jalr	-2016(ra) # 80002bdc <argaddr>
    return -1;
    800053c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c6:	00054b63          	bltz	a0,800053dc <sys_fstat+0x44>
  return filestat(f, st);
    800053ca:	fe043583          	ld	a1,-32(s0)
    800053ce:	fe843503          	ld	a0,-24(s0)
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	316080e7          	jalr	790(ra) # 800046e8 <filestat>
    800053da:	87aa                	mv	a5,a0
}
    800053dc:	853e                	mv	a0,a5
    800053de:	60e2                	ld	ra,24(sp)
    800053e0:	6442                	ld	s0,16(sp)
    800053e2:	6105                	addi	sp,sp,32
    800053e4:	8082                	ret

00000000800053e6 <sys_link>:
{
    800053e6:	7169                	addi	sp,sp,-304
    800053e8:	f606                	sd	ra,296(sp)
    800053ea:	f222                	sd	s0,288(sp)
    800053ec:	ee26                	sd	s1,280(sp)
    800053ee:	ea4a                	sd	s2,272(sp)
    800053f0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f2:	08000613          	li	a2,128
    800053f6:	ed040593          	addi	a1,s0,-304
    800053fa:	4501                	li	a0,0
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	802080e7          	jalr	-2046(ra) # 80002bfe <argstr>
    return -1;
    80005404:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005406:	10054e63          	bltz	a0,80005522 <sys_link+0x13c>
    8000540a:	08000613          	li	a2,128
    8000540e:	f5040593          	addi	a1,s0,-176
    80005412:	4505                	li	a0,1
    80005414:	ffffd097          	auipc	ra,0xffffd
    80005418:	7ea080e7          	jalr	2026(ra) # 80002bfe <argstr>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541e:	10054263          	bltz	a0,80005522 <sys_link+0x13c>
  begin_op();
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	d36080e7          	jalr	-714(ra) # 80004158 <begin_op>
  if((ip = namei(old)) == 0){
    8000542a:	ed040513          	addi	a0,s0,-304
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	b0a080e7          	jalr	-1270(ra) # 80003f38 <namei>
    80005436:	84aa                	mv	s1,a0
    80005438:	c551                	beqz	a0,800054c4 <sys_link+0xde>
  ilock(ip);
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	342080e7          	jalr	834(ra) # 8000377c <ilock>
  if(ip->type == T_DIR){
    80005442:	04449703          	lh	a4,68(s1)
    80005446:	4785                	li	a5,1
    80005448:	08f70463          	beq	a4,a5,800054d0 <sys_link+0xea>
  ip->nlink++;
    8000544c:	04a4d783          	lhu	a5,74(s1)
    80005450:	2785                	addiw	a5,a5,1
    80005452:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005456:	8526                	mv	a0,s1
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	258080e7          	jalr	600(ra) # 800036b0 <iupdate>
  iunlock(ip);
    80005460:	8526                	mv	a0,s1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	3dc080e7          	jalr	988(ra) # 8000383e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000546a:	fd040593          	addi	a1,s0,-48
    8000546e:	f5040513          	addi	a0,s0,-176
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	ae4080e7          	jalr	-1308(ra) # 80003f56 <nameiparent>
    8000547a:	892a                	mv	s2,a0
    8000547c:	c935                	beqz	a0,800054f0 <sys_link+0x10a>
  ilock(dp);
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	2fe080e7          	jalr	766(ra) # 8000377c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005486:	00092703          	lw	a4,0(s2)
    8000548a:	409c                	lw	a5,0(s1)
    8000548c:	04f71d63          	bne	a4,a5,800054e6 <sys_link+0x100>
    80005490:	40d0                	lw	a2,4(s1)
    80005492:	fd040593          	addi	a1,s0,-48
    80005496:	854a                	mv	a0,s2
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	9de080e7          	jalr	-1570(ra) # 80003e76 <dirlink>
    800054a0:	04054363          	bltz	a0,800054e6 <sys_link+0x100>
  iunlockput(dp);
    800054a4:	854a                	mv	a0,s2
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	538080e7          	jalr	1336(ra) # 800039de <iunlockput>
  iput(ip);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	486080e7          	jalr	1158(ra) # 80003936 <iput>
  end_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	d1e080e7          	jalr	-738(ra) # 800041d6 <end_op>
  return 0;
    800054c0:	4781                	li	a5,0
    800054c2:	a085                	j	80005522 <sys_link+0x13c>
    end_op();
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	d12080e7          	jalr	-750(ra) # 800041d6 <end_op>
    return -1;
    800054cc:	57fd                	li	a5,-1
    800054ce:	a891                	j	80005522 <sys_link+0x13c>
    iunlockput(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	50c080e7          	jalr	1292(ra) # 800039de <iunlockput>
    end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	cfc080e7          	jalr	-772(ra) # 800041d6 <end_op>
    return -1;
    800054e2:	57fd                	li	a5,-1
    800054e4:	a83d                	j	80005522 <sys_link+0x13c>
    iunlockput(dp);
    800054e6:	854a                	mv	a0,s2
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	4f6080e7          	jalr	1270(ra) # 800039de <iunlockput>
  ilock(ip);
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	28a080e7          	jalr	650(ra) # 8000377c <ilock>
  ip->nlink--;
    800054fa:	04a4d783          	lhu	a5,74(s1)
    800054fe:	37fd                	addiw	a5,a5,-1
    80005500:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	1aa080e7          	jalr	426(ra) # 800036b0 <iupdate>
  iunlockput(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	4ce080e7          	jalr	1230(ra) # 800039de <iunlockput>
  end_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	cbe080e7          	jalr	-834(ra) # 800041d6 <end_op>
  return -1;
    80005520:	57fd                	li	a5,-1
}
    80005522:	853e                	mv	a0,a5
    80005524:	70b2                	ld	ra,296(sp)
    80005526:	7412                	ld	s0,288(sp)
    80005528:	64f2                	ld	s1,280(sp)
    8000552a:	6952                	ld	s2,272(sp)
    8000552c:	6155                	addi	sp,sp,304
    8000552e:	8082                	ret

0000000080005530 <sys_unlink>:
{
    80005530:	7151                	addi	sp,sp,-240
    80005532:	f586                	sd	ra,232(sp)
    80005534:	f1a2                	sd	s0,224(sp)
    80005536:	eda6                	sd	s1,216(sp)
    80005538:	e9ca                	sd	s2,208(sp)
    8000553a:	e5ce                	sd	s3,200(sp)
    8000553c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000553e:	08000613          	li	a2,128
    80005542:	f3040593          	addi	a1,s0,-208
    80005546:	4501                	li	a0,0
    80005548:	ffffd097          	auipc	ra,0xffffd
    8000554c:	6b6080e7          	jalr	1718(ra) # 80002bfe <argstr>
    80005550:	18054163          	bltz	a0,800056d2 <sys_unlink+0x1a2>
  begin_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	c04080e7          	jalr	-1020(ra) # 80004158 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000555c:	fb040593          	addi	a1,s0,-80
    80005560:	f3040513          	addi	a0,s0,-208
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	9f2080e7          	jalr	-1550(ra) # 80003f56 <nameiparent>
    8000556c:	84aa                	mv	s1,a0
    8000556e:	c979                	beqz	a0,80005644 <sys_unlink+0x114>
  ilock(dp);
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	20c080e7          	jalr	524(ra) # 8000377c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005578:	00003597          	auipc	a1,0x3
    8000557c:	1c058593          	addi	a1,a1,448 # 80008738 <syscalls+0x2c0>
    80005580:	fb040513          	addi	a0,s0,-80
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	6c2080e7          	jalr	1730(ra) # 80003c46 <namecmp>
    8000558c:	14050a63          	beqz	a0,800056e0 <sys_unlink+0x1b0>
    80005590:	00003597          	auipc	a1,0x3
    80005594:	1b058593          	addi	a1,a1,432 # 80008740 <syscalls+0x2c8>
    80005598:	fb040513          	addi	a0,s0,-80
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	6aa080e7          	jalr	1706(ra) # 80003c46 <namecmp>
    800055a4:	12050e63          	beqz	a0,800056e0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a8:	f2c40613          	addi	a2,s0,-212
    800055ac:	fb040593          	addi	a1,s0,-80
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	6ae080e7          	jalr	1710(ra) # 80003c60 <dirlookup>
    800055ba:	892a                	mv	s2,a0
    800055bc:	12050263          	beqz	a0,800056e0 <sys_unlink+0x1b0>
  ilock(ip);
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	1bc080e7          	jalr	444(ra) # 8000377c <ilock>
  if(ip->nlink < 1)
    800055c8:	04a91783          	lh	a5,74(s2)
    800055cc:	08f05263          	blez	a5,80005650 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055d0:	04491703          	lh	a4,68(s2)
    800055d4:	4785                	li	a5,1
    800055d6:	08f70563          	beq	a4,a5,80005660 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055da:	4641                	li	a2,16
    800055dc:	4581                	li	a1,0
    800055de:	fc040513          	addi	a0,s0,-64
    800055e2:	ffffb097          	auipc	ra,0xffffb
    800055e6:	734080e7          	jalr	1844(ra) # 80000d16 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ea:	4741                	li	a4,16
    800055ec:	f2c42683          	lw	a3,-212(s0)
    800055f0:	fc040613          	addi	a2,s0,-64
    800055f4:	4581                	li	a1,0
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	530080e7          	jalr	1328(ra) # 80003b28 <writei>
    80005600:	47c1                	li	a5,16
    80005602:	0af51563          	bne	a0,a5,800056ac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005606:	04491703          	lh	a4,68(s2)
    8000560a:	4785                	li	a5,1
    8000560c:	0af70863          	beq	a4,a5,800056bc <sys_unlink+0x18c>
  iunlockput(dp);
    80005610:	8526                	mv	a0,s1
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	3cc080e7          	jalr	972(ra) # 800039de <iunlockput>
  ip->nlink--;
    8000561a:	04a95783          	lhu	a5,74(s2)
    8000561e:	37fd                	addiw	a5,a5,-1
    80005620:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005624:	854a                	mv	a0,s2
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	08a080e7          	jalr	138(ra) # 800036b0 <iupdate>
  iunlockput(ip);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	3ae080e7          	jalr	942(ra) # 800039de <iunlockput>
  end_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	b9e080e7          	jalr	-1122(ra) # 800041d6 <end_op>
  return 0;
    80005640:	4501                	li	a0,0
    80005642:	a84d                	j	800056f4 <sys_unlink+0x1c4>
    end_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	b92080e7          	jalr	-1134(ra) # 800041d6 <end_op>
    return -1;
    8000564c:	557d                	li	a0,-1
    8000564e:	a05d                	j	800056f4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005650:	00003517          	auipc	a0,0x3
    80005654:	11850513          	addi	a0,a0,280 # 80008768 <syscalls+0x2f0>
    80005658:	ffffb097          	auipc	ra,0xffffb
    8000565c:	ee2080e7          	jalr	-286(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005660:	04c92703          	lw	a4,76(s2)
    80005664:	02000793          	li	a5,32
    80005668:	f6e7f9e3          	bgeu	a5,a4,800055da <sys_unlink+0xaa>
    8000566c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005670:	4741                	li	a4,16
    80005672:	86ce                	mv	a3,s3
    80005674:	f1840613          	addi	a2,s0,-232
    80005678:	4581                	li	a1,0
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	3b4080e7          	jalr	948(ra) # 80003a30 <readi>
    80005684:	47c1                	li	a5,16
    80005686:	00f51b63          	bne	a0,a5,8000569c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000568a:	f1845783          	lhu	a5,-232(s0)
    8000568e:	e7a1                	bnez	a5,800056d6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005690:	29c1                	addiw	s3,s3,16
    80005692:	04c92783          	lw	a5,76(s2)
    80005696:	fcf9ede3          	bltu	s3,a5,80005670 <sys_unlink+0x140>
    8000569a:	b781                	j	800055da <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000569c:	00003517          	auipc	a0,0x3
    800056a0:	0e450513          	addi	a0,a0,228 # 80008780 <syscalls+0x308>
    800056a4:	ffffb097          	auipc	ra,0xffffb
    800056a8:	e96080e7          	jalr	-362(ra) # 8000053a <panic>
    panic("unlink: writei");
    800056ac:	00003517          	auipc	a0,0x3
    800056b0:	0ec50513          	addi	a0,a0,236 # 80008798 <syscalls+0x320>
    800056b4:	ffffb097          	auipc	ra,0xffffb
    800056b8:	e86080e7          	jalr	-378(ra) # 8000053a <panic>
    dp->nlink--;
    800056bc:	04a4d783          	lhu	a5,74(s1)
    800056c0:	37fd                	addiw	a5,a5,-1
    800056c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	fe8080e7          	jalr	-24(ra) # 800036b0 <iupdate>
    800056d0:	b781                	j	80005610 <sys_unlink+0xe0>
    return -1;
    800056d2:	557d                	li	a0,-1
    800056d4:	a005                	j	800056f4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d6:	854a                	mv	a0,s2
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	306080e7          	jalr	774(ra) # 800039de <iunlockput>
  iunlockput(dp);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	2fc080e7          	jalr	764(ra) # 800039de <iunlockput>
  end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	aec080e7          	jalr	-1300(ra) # 800041d6 <end_op>
  return -1;
    800056f2:	557d                	li	a0,-1
}
    800056f4:	70ae                	ld	ra,232(sp)
    800056f6:	740e                	ld	s0,224(sp)
    800056f8:	64ee                	ld	s1,216(sp)
    800056fa:	694e                	ld	s2,208(sp)
    800056fc:	69ae                	ld	s3,200(sp)
    800056fe:	616d                	addi	sp,sp,240
    80005700:	8082                	ret

0000000080005702 <sys_open>:

uint64
sys_open(void)
{
    80005702:	7131                	addi	sp,sp,-192
    80005704:	fd06                	sd	ra,184(sp)
    80005706:	f922                	sd	s0,176(sp)
    80005708:	f526                	sd	s1,168(sp)
    8000570a:	f14a                	sd	s2,160(sp)
    8000570c:	ed4e                	sd	s3,152(sp)
    8000570e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005710:	08000613          	li	a2,128
    80005714:	f5040593          	addi	a1,s0,-176
    80005718:	4501                	li	a0,0
    8000571a:	ffffd097          	auipc	ra,0xffffd
    8000571e:	4e4080e7          	jalr	1252(ra) # 80002bfe <argstr>
    return -1;
    80005722:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005724:	0c054163          	bltz	a0,800057e6 <sys_open+0xe4>
    80005728:	f4c40593          	addi	a1,s0,-180
    8000572c:	4505                	li	a0,1
    8000572e:	ffffd097          	auipc	ra,0xffffd
    80005732:	48c080e7          	jalr	1164(ra) # 80002bba <argint>
    80005736:	0a054863          	bltz	a0,800057e6 <sys_open+0xe4>

  begin_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	a1e080e7          	jalr	-1506(ra) # 80004158 <begin_op>

  if(omode & O_CREATE){
    80005742:	f4c42783          	lw	a5,-180(s0)
    80005746:	2007f793          	andi	a5,a5,512
    8000574a:	cbdd                	beqz	a5,80005800 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000574c:	4681                	li	a3,0
    8000574e:	4601                	li	a2,0
    80005750:	4589                	li	a1,2
    80005752:	f5040513          	addi	a0,s0,-176
    80005756:	00000097          	auipc	ra,0x0
    8000575a:	970080e7          	jalr	-1680(ra) # 800050c6 <create>
    8000575e:	892a                	mv	s2,a0
    if(ip == 0){
    80005760:	c959                	beqz	a0,800057f6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005762:	04491703          	lh	a4,68(s2)
    80005766:	478d                	li	a5,3
    80005768:	00f71763          	bne	a4,a5,80005776 <sys_open+0x74>
    8000576c:	04695703          	lhu	a4,70(s2)
    80005770:	47a5                	li	a5,9
    80005772:	0ce7ec63          	bltu	a5,a4,8000584a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	dee080e7          	jalr	-530(ra) # 80004564 <filealloc>
    8000577e:	89aa                	mv	s3,a0
    80005780:	10050263          	beqz	a0,80005884 <sys_open+0x182>
    80005784:	00000097          	auipc	ra,0x0
    80005788:	900080e7          	jalr	-1792(ra) # 80005084 <fdalloc>
    8000578c:	84aa                	mv	s1,a0
    8000578e:	0e054663          	bltz	a0,8000587a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005792:	04491703          	lh	a4,68(s2)
    80005796:	478d                	li	a5,3
    80005798:	0cf70463          	beq	a4,a5,80005860 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000579c:	4789                	li	a5,2
    8000579e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057a2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057a6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057aa:	f4c42783          	lw	a5,-180(s0)
    800057ae:	0017c713          	xori	a4,a5,1
    800057b2:	8b05                	andi	a4,a4,1
    800057b4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b8:	0037f713          	andi	a4,a5,3
    800057bc:	00e03733          	snez	a4,a4
    800057c0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057c4:	4007f793          	andi	a5,a5,1024
    800057c8:	c791                	beqz	a5,800057d4 <sys_open+0xd2>
    800057ca:	04491703          	lh	a4,68(s2)
    800057ce:	4789                	li	a5,2
    800057d0:	08f70f63          	beq	a4,a5,8000586e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057d4:	854a                	mv	a0,s2
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	068080e7          	jalr	104(ra) # 8000383e <iunlock>
  end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	9f8080e7          	jalr	-1544(ra) # 800041d6 <end_op>

  return fd;
}
    800057e6:	8526                	mv	a0,s1
    800057e8:	70ea                	ld	ra,184(sp)
    800057ea:	744a                	ld	s0,176(sp)
    800057ec:	74aa                	ld	s1,168(sp)
    800057ee:	790a                	ld	s2,160(sp)
    800057f0:	69ea                	ld	s3,152(sp)
    800057f2:	6129                	addi	sp,sp,192
    800057f4:	8082                	ret
      end_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	9e0080e7          	jalr	-1568(ra) # 800041d6 <end_op>
      return -1;
    800057fe:	b7e5                	j	800057e6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005800:	f5040513          	addi	a0,s0,-176
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	734080e7          	jalr	1844(ra) # 80003f38 <namei>
    8000580c:	892a                	mv	s2,a0
    8000580e:	c905                	beqz	a0,8000583e <sys_open+0x13c>
    ilock(ip);
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	f6c080e7          	jalr	-148(ra) # 8000377c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005818:	04491703          	lh	a4,68(s2)
    8000581c:	4785                	li	a5,1
    8000581e:	f4f712e3          	bne	a4,a5,80005762 <sys_open+0x60>
    80005822:	f4c42783          	lw	a5,-180(s0)
    80005826:	dba1                	beqz	a5,80005776 <sys_open+0x74>
      iunlockput(ip);
    80005828:	854a                	mv	a0,s2
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	1b4080e7          	jalr	436(ra) # 800039de <iunlockput>
      end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	9a4080e7          	jalr	-1628(ra) # 800041d6 <end_op>
      return -1;
    8000583a:	54fd                	li	s1,-1
    8000583c:	b76d                	j	800057e6 <sys_open+0xe4>
      end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	998080e7          	jalr	-1640(ra) # 800041d6 <end_op>
      return -1;
    80005846:	54fd                	li	s1,-1
    80005848:	bf79                	j	800057e6 <sys_open+0xe4>
    iunlockput(ip);
    8000584a:	854a                	mv	a0,s2
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	192080e7          	jalr	402(ra) # 800039de <iunlockput>
    end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	982080e7          	jalr	-1662(ra) # 800041d6 <end_op>
    return -1;
    8000585c:	54fd                	li	s1,-1
    8000585e:	b761                	j	800057e6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005860:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005864:	04691783          	lh	a5,70(s2)
    80005868:	02f99223          	sh	a5,36(s3)
    8000586c:	bf2d                	j	800057a6 <sys_open+0xa4>
    itrunc(ip);
    8000586e:	854a                	mv	a0,s2
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	01a080e7          	jalr	26(ra) # 8000388a <itrunc>
    80005878:	bfb1                	j	800057d4 <sys_open+0xd2>
      fileclose(f);
    8000587a:	854e                	mv	a0,s3
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	da4080e7          	jalr	-604(ra) # 80004620 <fileclose>
    iunlockput(ip);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	158080e7          	jalr	344(ra) # 800039de <iunlockput>
    end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	948080e7          	jalr	-1720(ra) # 800041d6 <end_op>
    return -1;
    80005896:	54fd                	li	s1,-1
    80005898:	b7b9                	j	800057e6 <sys_open+0xe4>

000000008000589a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000589a:	7175                	addi	sp,sp,-144
    8000589c:	e506                	sd	ra,136(sp)
    8000589e:	e122                	sd	s0,128(sp)
    800058a0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	8b6080e7          	jalr	-1866(ra) # 80004158 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058aa:	08000613          	li	a2,128
    800058ae:	f7040593          	addi	a1,s0,-144
    800058b2:	4501                	li	a0,0
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	34a080e7          	jalr	842(ra) # 80002bfe <argstr>
    800058bc:	02054963          	bltz	a0,800058ee <sys_mkdir+0x54>
    800058c0:	4681                	li	a3,0
    800058c2:	4601                	li	a2,0
    800058c4:	4585                	li	a1,1
    800058c6:	f7040513          	addi	a0,s0,-144
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	7fc080e7          	jalr	2044(ra) # 800050c6 <create>
    800058d2:	cd11                	beqz	a0,800058ee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	10a080e7          	jalr	266(ra) # 800039de <iunlockput>
  end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	8fa080e7          	jalr	-1798(ra) # 800041d6 <end_op>
  return 0;
    800058e4:	4501                	li	a0,0
}
    800058e6:	60aa                	ld	ra,136(sp)
    800058e8:	640a                	ld	s0,128(sp)
    800058ea:	6149                	addi	sp,sp,144
    800058ec:	8082                	ret
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	8e8080e7          	jalr	-1816(ra) # 800041d6 <end_op>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	b7fd                	j	800058e6 <sys_mkdir+0x4c>

00000000800058fa <sys_mknod>:

uint64
sys_mknod(void)
{
    800058fa:	7135                	addi	sp,sp,-160
    800058fc:	ed06                	sd	ra,152(sp)
    800058fe:	e922                	sd	s0,144(sp)
    80005900:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	856080e7          	jalr	-1962(ra) # 80004158 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000590a:	08000613          	li	a2,128
    8000590e:	f7040593          	addi	a1,s0,-144
    80005912:	4501                	li	a0,0
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	2ea080e7          	jalr	746(ra) # 80002bfe <argstr>
    8000591c:	04054a63          	bltz	a0,80005970 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005920:	f6c40593          	addi	a1,s0,-148
    80005924:	4505                	li	a0,1
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	294080e7          	jalr	660(ra) # 80002bba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592e:	04054163          	bltz	a0,80005970 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005932:	f6840593          	addi	a1,s0,-152
    80005936:	4509                	li	a0,2
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	282080e7          	jalr	642(ra) # 80002bba <argint>
     argint(1, &major) < 0 ||
    80005940:	02054863          	bltz	a0,80005970 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005944:	f6841683          	lh	a3,-152(s0)
    80005948:	f6c41603          	lh	a2,-148(s0)
    8000594c:	458d                	li	a1,3
    8000594e:	f7040513          	addi	a0,s0,-144
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	774080e7          	jalr	1908(ra) # 800050c6 <create>
     argint(2, &minor) < 0 ||
    8000595a:	c919                	beqz	a0,80005970 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	082080e7          	jalr	130(ra) # 800039de <iunlockput>
  end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	872080e7          	jalr	-1934(ra) # 800041d6 <end_op>
  return 0;
    8000596c:	4501                	li	a0,0
    8000596e:	a031                	j	8000597a <sys_mknod+0x80>
    end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	866080e7          	jalr	-1946(ra) # 800041d6 <end_op>
    return -1;
    80005978:	557d                	li	a0,-1
}
    8000597a:	60ea                	ld	ra,152(sp)
    8000597c:	644a                	ld	s0,144(sp)
    8000597e:	610d                	addi	sp,sp,160
    80005980:	8082                	ret

0000000080005982 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005982:	7135                	addi	sp,sp,-160
    80005984:	ed06                	sd	ra,152(sp)
    80005986:	e922                	sd	s0,144(sp)
    80005988:	e526                	sd	s1,136(sp)
    8000598a:	e14a                	sd	s2,128(sp)
    8000598c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000598e:	ffffc097          	auipc	ra,0xffffc
    80005992:	028080e7          	jalr	40(ra) # 800019b6 <myproc>
    80005996:	892a                	mv	s2,a0
  
  begin_op();
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	7c0080e7          	jalr	1984(ra) # 80004158 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059a0:	08000613          	li	a2,128
    800059a4:	f6040593          	addi	a1,s0,-160
    800059a8:	4501                	li	a0,0
    800059aa:	ffffd097          	auipc	ra,0xffffd
    800059ae:	254080e7          	jalr	596(ra) # 80002bfe <argstr>
    800059b2:	04054b63          	bltz	a0,80005a08 <sys_chdir+0x86>
    800059b6:	f6040513          	addi	a0,s0,-160
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	57e080e7          	jalr	1406(ra) # 80003f38 <namei>
    800059c2:	84aa                	mv	s1,a0
    800059c4:	c131                	beqz	a0,80005a08 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	db6080e7          	jalr	-586(ra) # 8000377c <ilock>
  if(ip->type != T_DIR){
    800059ce:	04449703          	lh	a4,68(s1)
    800059d2:	4785                	li	a5,1
    800059d4:	04f71063          	bne	a4,a5,80005a14 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059d8:	8526                	mv	a0,s1
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	e64080e7          	jalr	-412(ra) # 8000383e <iunlock>
  iput(p->cwd);
    800059e2:	15093503          	ld	a0,336(s2)
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	f50080e7          	jalr	-176(ra) # 80003936 <iput>
  end_op();
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	7e8080e7          	jalr	2024(ra) # 800041d6 <end_op>
  p->cwd = ip;
    800059f6:	14993823          	sd	s1,336(s2)
  return 0;
    800059fa:	4501                	li	a0,0
}
    800059fc:	60ea                	ld	ra,152(sp)
    800059fe:	644a                	ld	s0,144(sp)
    80005a00:	64aa                	ld	s1,136(sp)
    80005a02:	690a                	ld	s2,128(sp)
    80005a04:	610d                	addi	sp,sp,160
    80005a06:	8082                	ret
    end_op();
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	7ce080e7          	jalr	1998(ra) # 800041d6 <end_op>
    return -1;
    80005a10:	557d                	li	a0,-1
    80005a12:	b7ed                	j	800059fc <sys_chdir+0x7a>
    iunlockput(ip);
    80005a14:	8526                	mv	a0,s1
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	fc8080e7          	jalr	-56(ra) # 800039de <iunlockput>
    end_op();
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	7b8080e7          	jalr	1976(ra) # 800041d6 <end_op>
    return -1;
    80005a26:	557d                	li	a0,-1
    80005a28:	bfd1                	j	800059fc <sys_chdir+0x7a>

0000000080005a2a <sys_exec>:

uint64
sys_exec(void)
{
    80005a2a:	7145                	addi	sp,sp,-464
    80005a2c:	e786                	sd	ra,456(sp)
    80005a2e:	e3a2                	sd	s0,448(sp)
    80005a30:	ff26                	sd	s1,440(sp)
    80005a32:	fb4a                	sd	s2,432(sp)
    80005a34:	f74e                	sd	s3,424(sp)
    80005a36:	f352                	sd	s4,416(sp)
    80005a38:	ef56                	sd	s5,408(sp)
    80005a3a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a3c:	08000613          	li	a2,128
    80005a40:	f4040593          	addi	a1,s0,-192
    80005a44:	4501                	li	a0,0
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	1b8080e7          	jalr	440(ra) # 80002bfe <argstr>
    return -1;
    80005a4e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a50:	0c054b63          	bltz	a0,80005b26 <sys_exec+0xfc>
    80005a54:	e3840593          	addi	a1,s0,-456
    80005a58:	4505                	li	a0,1
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	182080e7          	jalr	386(ra) # 80002bdc <argaddr>
    80005a62:	0c054263          	bltz	a0,80005b26 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a66:	10000613          	li	a2,256
    80005a6a:	4581                	li	a1,0
    80005a6c:	e4040513          	addi	a0,s0,-448
    80005a70:	ffffb097          	auipc	ra,0xffffb
    80005a74:	2a6080e7          	jalr	678(ra) # 80000d16 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a78:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a7c:	89a6                	mv	s3,s1
    80005a7e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a80:	02000a13          	li	s4,32
    80005a84:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a88:	00391513          	slli	a0,s2,0x3
    80005a8c:	e3040593          	addi	a1,s0,-464
    80005a90:	e3843783          	ld	a5,-456(s0)
    80005a94:	953e                	add	a0,a0,a5
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	08a080e7          	jalr	138(ra) # 80002b20 <fetchaddr>
    80005a9e:	02054a63          	bltz	a0,80005ad2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005aa2:	e3043783          	ld	a5,-464(s0)
    80005aa6:	c3b9                	beqz	a5,80005aec <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aa8:	ffffb097          	auipc	ra,0xffffb
    80005aac:	038080e7          	jalr	56(ra) # 80000ae0 <kalloc>
    80005ab0:	85aa                	mv	a1,a0
    80005ab2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ab6:	cd11                	beqz	a0,80005ad2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ab8:	6605                	lui	a2,0x1
    80005aba:	e3043503          	ld	a0,-464(s0)
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	0b4080e7          	jalr	180(ra) # 80002b72 <fetchstr>
    80005ac6:	00054663          	bltz	a0,80005ad2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005aca:	0905                	addi	s2,s2,1
    80005acc:	09a1                	addi	s3,s3,8
    80005ace:	fb491be3          	bne	s2,s4,80005a84 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad2:	f4040913          	addi	s2,s0,-192
    80005ad6:	6088                	ld	a0,0(s1)
    80005ad8:	c531                	beqz	a0,80005b24 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ada:	ffffb097          	auipc	ra,0xffffb
    80005ade:	f08080e7          	jalr	-248(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae2:	04a1                	addi	s1,s1,8
    80005ae4:	ff2499e3          	bne	s1,s2,80005ad6 <sys_exec+0xac>
  return -1;
    80005ae8:	597d                	li	s2,-1
    80005aea:	a835                	j	80005b26 <sys_exec+0xfc>
      argv[i] = 0;
    80005aec:	0a8e                	slli	s5,s5,0x3
    80005aee:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005af2:	00878ab3          	add	s5,a5,s0
    80005af6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005afa:	e4040593          	addi	a1,s0,-448
    80005afe:	f4040513          	addi	a0,s0,-192
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	172080e7          	jalr	370(ra) # 80004c74 <exec>
    80005b0a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0c:	f4040993          	addi	s3,s0,-192
    80005b10:	6088                	ld	a0,0(s1)
    80005b12:	c911                	beqz	a0,80005b26 <sys_exec+0xfc>
    kfree(argv[i]);
    80005b14:	ffffb097          	auipc	ra,0xffffb
    80005b18:	ece080e7          	jalr	-306(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1c:	04a1                	addi	s1,s1,8
    80005b1e:	ff3499e3          	bne	s1,s3,80005b10 <sys_exec+0xe6>
    80005b22:	a011                	j	80005b26 <sys_exec+0xfc>
  return -1;
    80005b24:	597d                	li	s2,-1
}
    80005b26:	854a                	mv	a0,s2
    80005b28:	60be                	ld	ra,456(sp)
    80005b2a:	641e                	ld	s0,448(sp)
    80005b2c:	74fa                	ld	s1,440(sp)
    80005b2e:	795a                	ld	s2,432(sp)
    80005b30:	79ba                	ld	s3,424(sp)
    80005b32:	7a1a                	ld	s4,416(sp)
    80005b34:	6afa                	ld	s5,408(sp)
    80005b36:	6179                	addi	sp,sp,464
    80005b38:	8082                	ret

0000000080005b3a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b3a:	7139                	addi	sp,sp,-64
    80005b3c:	fc06                	sd	ra,56(sp)
    80005b3e:	f822                	sd	s0,48(sp)
    80005b40:	f426                	sd	s1,40(sp)
    80005b42:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b44:	ffffc097          	auipc	ra,0xffffc
    80005b48:	e72080e7          	jalr	-398(ra) # 800019b6 <myproc>
    80005b4c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b4e:	fd840593          	addi	a1,s0,-40
    80005b52:	4501                	li	a0,0
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	088080e7          	jalr	136(ra) # 80002bdc <argaddr>
    return -1;
    80005b5c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b5e:	0e054063          	bltz	a0,80005c3e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b62:	fc840593          	addi	a1,s0,-56
    80005b66:	fd040513          	addi	a0,s0,-48
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	de6080e7          	jalr	-538(ra) # 80004950 <pipealloc>
    return -1;
    80005b72:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b74:	0c054563          	bltz	a0,80005c3e <sys_pipe+0x104>
  fd0 = -1;
    80005b78:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b7c:	fd043503          	ld	a0,-48(s0)
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	504080e7          	jalr	1284(ra) # 80005084 <fdalloc>
    80005b88:	fca42223          	sw	a0,-60(s0)
    80005b8c:	08054c63          	bltz	a0,80005c24 <sys_pipe+0xea>
    80005b90:	fc843503          	ld	a0,-56(s0)
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	4f0080e7          	jalr	1264(ra) # 80005084 <fdalloc>
    80005b9c:	fca42023          	sw	a0,-64(s0)
    80005ba0:	06054963          	bltz	a0,80005c12 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ba4:	4691                	li	a3,4
    80005ba6:	fc440613          	addi	a2,s0,-60
    80005baa:	fd843583          	ld	a1,-40(s0)
    80005bae:	68a8                	ld	a0,80(s1)
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	aca080e7          	jalr	-1334(ra) # 8000167a <copyout>
    80005bb8:	02054063          	bltz	a0,80005bd8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bbc:	4691                	li	a3,4
    80005bbe:	fc040613          	addi	a2,s0,-64
    80005bc2:	fd843583          	ld	a1,-40(s0)
    80005bc6:	0591                	addi	a1,a1,4
    80005bc8:	68a8                	ld	a0,80(s1)
    80005bca:	ffffc097          	auipc	ra,0xffffc
    80005bce:	ab0080e7          	jalr	-1360(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bd2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd4:	06055563          	bgez	a0,80005c3e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bd8:	fc442783          	lw	a5,-60(s0)
    80005bdc:	07e9                	addi	a5,a5,26
    80005bde:	078e                	slli	a5,a5,0x3
    80005be0:	97a6                	add	a5,a5,s1
    80005be2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005be6:	fc042783          	lw	a5,-64(s0)
    80005bea:	07e9                	addi	a5,a5,26
    80005bec:	078e                	slli	a5,a5,0x3
    80005bee:	00f48533          	add	a0,s1,a5
    80005bf2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bf6:	fd043503          	ld	a0,-48(s0)
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	a26080e7          	jalr	-1498(ra) # 80004620 <fileclose>
    fileclose(wf);
    80005c02:	fc843503          	ld	a0,-56(s0)
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	a1a080e7          	jalr	-1510(ra) # 80004620 <fileclose>
    return -1;
    80005c0e:	57fd                	li	a5,-1
    80005c10:	a03d                	j	80005c3e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c12:	fc442783          	lw	a5,-60(s0)
    80005c16:	0007c763          	bltz	a5,80005c24 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c1a:	07e9                	addi	a5,a5,26
    80005c1c:	078e                	slli	a5,a5,0x3
    80005c1e:	97a6                	add	a5,a5,s1
    80005c20:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c24:	fd043503          	ld	a0,-48(s0)
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	9f8080e7          	jalr	-1544(ra) # 80004620 <fileclose>
    fileclose(wf);
    80005c30:	fc843503          	ld	a0,-56(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	9ec080e7          	jalr	-1556(ra) # 80004620 <fileclose>
    return -1;
    80005c3c:	57fd                	li	a5,-1
}
    80005c3e:	853e                	mv	a0,a5
    80005c40:	70e2                	ld	ra,56(sp)
    80005c42:	7442                	ld	s0,48(sp)
    80005c44:	74a2                	ld	s1,40(sp)
    80005c46:	6121                	addi	sp,sp,64
    80005c48:	8082                	ret
    80005c4a:	0000                	unimp
    80005c4c:	0000                	unimp
	...

0000000080005c50 <kernelvec>:
    80005c50:	7111                	addi	sp,sp,-256
    80005c52:	e006                	sd	ra,0(sp)
    80005c54:	e40a                	sd	sp,8(sp)
    80005c56:	e80e                	sd	gp,16(sp)
    80005c58:	ec12                	sd	tp,24(sp)
    80005c5a:	f016                	sd	t0,32(sp)
    80005c5c:	f41a                	sd	t1,40(sp)
    80005c5e:	f81e                	sd	t2,48(sp)
    80005c60:	fc22                	sd	s0,56(sp)
    80005c62:	e0a6                	sd	s1,64(sp)
    80005c64:	e4aa                	sd	a0,72(sp)
    80005c66:	e8ae                	sd	a1,80(sp)
    80005c68:	ecb2                	sd	a2,88(sp)
    80005c6a:	f0b6                	sd	a3,96(sp)
    80005c6c:	f4ba                	sd	a4,104(sp)
    80005c6e:	f8be                	sd	a5,112(sp)
    80005c70:	fcc2                	sd	a6,120(sp)
    80005c72:	e146                	sd	a7,128(sp)
    80005c74:	e54a                	sd	s2,136(sp)
    80005c76:	e94e                	sd	s3,144(sp)
    80005c78:	ed52                	sd	s4,152(sp)
    80005c7a:	f156                	sd	s5,160(sp)
    80005c7c:	f55a                	sd	s6,168(sp)
    80005c7e:	f95e                	sd	s7,176(sp)
    80005c80:	fd62                	sd	s8,184(sp)
    80005c82:	e1e6                	sd	s9,192(sp)
    80005c84:	e5ea                	sd	s10,200(sp)
    80005c86:	e9ee                	sd	s11,208(sp)
    80005c88:	edf2                	sd	t3,216(sp)
    80005c8a:	f1f6                	sd	t4,224(sp)
    80005c8c:	f5fa                	sd	t5,232(sp)
    80005c8e:	f9fe                	sd	t6,240(sp)
    80005c90:	d5dfc0ef          	jal	ra,800029ec <kerneltrap>
    80005c94:	6082                	ld	ra,0(sp)
    80005c96:	6122                	ld	sp,8(sp)
    80005c98:	61c2                	ld	gp,16(sp)
    80005c9a:	7282                	ld	t0,32(sp)
    80005c9c:	7322                	ld	t1,40(sp)
    80005c9e:	73c2                	ld	t2,48(sp)
    80005ca0:	7462                	ld	s0,56(sp)
    80005ca2:	6486                	ld	s1,64(sp)
    80005ca4:	6526                	ld	a0,72(sp)
    80005ca6:	65c6                	ld	a1,80(sp)
    80005ca8:	6666                	ld	a2,88(sp)
    80005caa:	7686                	ld	a3,96(sp)
    80005cac:	7726                	ld	a4,104(sp)
    80005cae:	77c6                	ld	a5,112(sp)
    80005cb0:	7866                	ld	a6,120(sp)
    80005cb2:	688a                	ld	a7,128(sp)
    80005cb4:	692a                	ld	s2,136(sp)
    80005cb6:	69ca                	ld	s3,144(sp)
    80005cb8:	6a6a                	ld	s4,152(sp)
    80005cba:	7a8a                	ld	s5,160(sp)
    80005cbc:	7b2a                	ld	s6,168(sp)
    80005cbe:	7bca                	ld	s7,176(sp)
    80005cc0:	7c6a                	ld	s8,184(sp)
    80005cc2:	6c8e                	ld	s9,192(sp)
    80005cc4:	6d2e                	ld	s10,200(sp)
    80005cc6:	6dce                	ld	s11,208(sp)
    80005cc8:	6e6e                	ld	t3,216(sp)
    80005cca:	7e8e                	ld	t4,224(sp)
    80005ccc:	7f2e                	ld	t5,232(sp)
    80005cce:	7fce                	ld	t6,240(sp)
    80005cd0:	6111                	addi	sp,sp,256
    80005cd2:	10200073          	sret
    80005cd6:	00000013          	nop
    80005cda:	00000013          	nop
    80005cde:	0001                	nop

0000000080005ce0 <timervec>:
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	e10c                	sd	a1,0(a0)
    80005ce6:	e510                	sd	a2,8(a0)
    80005ce8:	e914                	sd	a3,16(a0)
    80005cea:	6d0c                	ld	a1,24(a0)
    80005cec:	7110                	ld	a2,32(a0)
    80005cee:	6194                	ld	a3,0(a1)
    80005cf0:	96b2                	add	a3,a3,a2
    80005cf2:	e194                	sd	a3,0(a1)
    80005cf4:	4589                	li	a1,2
    80005cf6:	14459073          	csrw	sip,a1
    80005cfa:	6914                	ld	a3,16(a0)
    80005cfc:	6510                	ld	a2,8(a0)
    80005cfe:	610c                	ld	a1,0(a0)
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	30200073          	mret
	...

0000000080005d0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d0a:	1141                	addi	sp,sp,-16
    80005d0c:	e422                	sd	s0,8(sp)
    80005d0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d10:	0c0007b7          	lui	a5,0xc000
    80005d14:	4705                	li	a4,1
    80005d16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d18:	c3d8                	sw	a4,4(a5)
}
    80005d1a:	6422                	ld	s0,8(sp)
    80005d1c:	0141                	addi	sp,sp,16
    80005d1e:	8082                	ret

0000000080005d20 <plicinithart>:

void
plicinithart(void)
{
    80005d20:	1141                	addi	sp,sp,-16
    80005d22:	e406                	sd	ra,8(sp)
    80005d24:	e022                	sd	s0,0(sp)
    80005d26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	c62080e7          	jalr	-926(ra) # 8000198a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d30:	0085171b          	slliw	a4,a0,0x8
    80005d34:	0c0027b7          	lui	a5,0xc002
    80005d38:	97ba                	add	a5,a5,a4
    80005d3a:	40200713          	li	a4,1026
    80005d3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d42:	00d5151b          	slliw	a0,a0,0xd
    80005d46:	0c2017b7          	lui	a5,0xc201
    80005d4a:	97aa                	add	a5,a5,a0
    80005d4c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret

0000000080005d58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d58:	1141                	addi	sp,sp,-16
    80005d5a:	e406                	sd	ra,8(sp)
    80005d5c:	e022                	sd	s0,0(sp)
    80005d5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	c2a080e7          	jalr	-982(ra) # 8000198a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d68:	00d5151b          	slliw	a0,a0,0xd
    80005d6c:	0c2017b7          	lui	a5,0xc201
    80005d70:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d72:	43c8                	lw	a0,4(a5)
    80005d74:	60a2                	ld	ra,8(sp)
    80005d76:	6402                	ld	s0,0(sp)
    80005d78:	0141                	addi	sp,sp,16
    80005d7a:	8082                	ret

0000000080005d7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d7c:	1101                	addi	sp,sp,-32
    80005d7e:	ec06                	sd	ra,24(sp)
    80005d80:	e822                	sd	s0,16(sp)
    80005d82:	e426                	sd	s1,8(sp)
    80005d84:	1000                	addi	s0,sp,32
    80005d86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	c02080e7          	jalr	-1022(ra) # 8000198a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d90:	00d5151b          	slliw	a0,a0,0xd
    80005d94:	0c2017b7          	lui	a5,0xc201
    80005d98:	97aa                	add	a5,a5,a0
    80005d9a:	c3c4                	sw	s1,4(a5)
}
    80005d9c:	60e2                	ld	ra,24(sp)
    80005d9e:	6442                	ld	s0,16(sp)
    80005da0:	64a2                	ld	s1,8(sp)
    80005da2:	6105                	addi	sp,sp,32
    80005da4:	8082                	ret

0000000080005da6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005da6:	1141                	addi	sp,sp,-16
    80005da8:	e406                	sd	ra,8(sp)
    80005daa:	e022                	sd	s0,0(sp)
    80005dac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dae:	479d                	li	a5,7
    80005db0:	06a7c863          	blt	a5,a0,80005e20 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005db4:	0001d717          	auipc	a4,0x1d
    80005db8:	24c70713          	addi	a4,a4,588 # 80023000 <disk>
    80005dbc:	972a                	add	a4,a4,a0
    80005dbe:	6789                	lui	a5,0x2
    80005dc0:	97ba                	add	a5,a5,a4
    80005dc2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dc6:	e7ad                	bnez	a5,80005e30 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dc8:	00451793          	slli	a5,a0,0x4
    80005dcc:	0001f717          	auipc	a4,0x1f
    80005dd0:	23470713          	addi	a4,a4,564 # 80025000 <disk+0x2000>
    80005dd4:	6314                	ld	a3,0(a4)
    80005dd6:	96be                	add	a3,a3,a5
    80005dd8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ddc:	6314                	ld	a3,0(a4)
    80005dde:	96be                	add	a3,a3,a5
    80005de0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005de4:	6314                	ld	a3,0(a4)
    80005de6:	96be                	add	a3,a3,a5
    80005de8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dec:	6318                	ld	a4,0(a4)
    80005dee:	97ba                	add	a5,a5,a4
    80005df0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005df4:	0001d717          	auipc	a4,0x1d
    80005df8:	20c70713          	addi	a4,a4,524 # 80023000 <disk>
    80005dfc:	972a                	add	a4,a4,a0
    80005dfe:	6789                	lui	a5,0x2
    80005e00:	97ba                	add	a5,a5,a4
    80005e02:	4705                	li	a4,1
    80005e04:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e08:	0001f517          	auipc	a0,0x1f
    80005e0c:	21050513          	addi	a0,a0,528 # 80025018 <disk+0x2018>
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	3f6080e7          	jalr	1014(ra) # 80002206 <wakeup>
}
    80005e18:	60a2                	ld	ra,8(sp)
    80005e1a:	6402                	ld	s0,0(sp)
    80005e1c:	0141                	addi	sp,sp,16
    80005e1e:	8082                	ret
    panic("free_desc 1");
    80005e20:	00003517          	auipc	a0,0x3
    80005e24:	98850513          	addi	a0,a0,-1656 # 800087a8 <syscalls+0x330>
    80005e28:	ffffa097          	auipc	ra,0xffffa
    80005e2c:	712080e7          	jalr	1810(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005e30:	00003517          	auipc	a0,0x3
    80005e34:	98850513          	addi	a0,a0,-1656 # 800087b8 <syscalls+0x340>
    80005e38:	ffffa097          	auipc	ra,0xffffa
    80005e3c:	702080e7          	jalr	1794(ra) # 8000053a <panic>

0000000080005e40 <virtio_disk_init>:
{
    80005e40:	1101                	addi	sp,sp,-32
    80005e42:	ec06                	sd	ra,24(sp)
    80005e44:	e822                	sd	s0,16(sp)
    80005e46:	e426                	sd	s1,8(sp)
    80005e48:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e4a:	00003597          	auipc	a1,0x3
    80005e4e:	97e58593          	addi	a1,a1,-1666 # 800087c8 <syscalls+0x350>
    80005e52:	0001f517          	auipc	a0,0x1f
    80005e56:	2d650513          	addi	a0,a0,726 # 80025128 <disk+0x2128>
    80005e5a:	ffffb097          	auipc	ra,0xffffb
    80005e5e:	d30080e7          	jalr	-720(ra) # 80000b8a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e62:	100017b7          	lui	a5,0x10001
    80005e66:	4398                	lw	a4,0(a5)
    80005e68:	2701                	sext.w	a4,a4
    80005e6a:	747277b7          	lui	a5,0x74727
    80005e6e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e72:	0ef71063          	bne	a4,a5,80005f52 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e76:	100017b7          	lui	a5,0x10001
    80005e7a:	43dc                	lw	a5,4(a5)
    80005e7c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e7e:	4705                	li	a4,1
    80005e80:	0ce79963          	bne	a5,a4,80005f52 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e84:	100017b7          	lui	a5,0x10001
    80005e88:	479c                	lw	a5,8(a5)
    80005e8a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e8c:	4709                	li	a4,2
    80005e8e:	0ce79263          	bne	a5,a4,80005f52 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e92:	100017b7          	lui	a5,0x10001
    80005e96:	47d8                	lw	a4,12(a5)
    80005e98:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e9a:	554d47b7          	lui	a5,0x554d4
    80005e9e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ea2:	0af71863          	bne	a4,a5,80005f52 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea6:	100017b7          	lui	a5,0x10001
    80005eaa:	4705                	li	a4,1
    80005eac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	470d                	li	a4,3
    80005eb0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eb2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eb4:	c7ffe6b7          	lui	a3,0xc7ffe
    80005eb8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ebc:	8f75                	and	a4,a4,a3
    80005ebe:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec0:	472d                	li	a4,11
    80005ec2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec4:	473d                	li	a4,15
    80005ec6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ec8:	6705                	lui	a4,0x1
    80005eca:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ecc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ed0:	5bdc                	lw	a5,52(a5)
    80005ed2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ed4:	c7d9                	beqz	a5,80005f62 <virtio_disk_init+0x122>
  if(max < NUM)
    80005ed6:	471d                	li	a4,7
    80005ed8:	08f77d63          	bgeu	a4,a5,80005f72 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005edc:	100014b7          	lui	s1,0x10001
    80005ee0:	47a1                	li	a5,8
    80005ee2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ee4:	6609                	lui	a2,0x2
    80005ee6:	4581                	li	a1,0
    80005ee8:	0001d517          	auipc	a0,0x1d
    80005eec:	11850513          	addi	a0,a0,280 # 80023000 <disk>
    80005ef0:	ffffb097          	auipc	ra,0xffffb
    80005ef4:	e26080e7          	jalr	-474(ra) # 80000d16 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ef8:	0001d717          	auipc	a4,0x1d
    80005efc:	10870713          	addi	a4,a4,264 # 80023000 <disk>
    80005f00:	00c75793          	srli	a5,a4,0xc
    80005f04:	2781                	sext.w	a5,a5
    80005f06:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f08:	0001f797          	auipc	a5,0x1f
    80005f0c:	0f878793          	addi	a5,a5,248 # 80025000 <disk+0x2000>
    80005f10:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f12:	0001d717          	auipc	a4,0x1d
    80005f16:	16e70713          	addi	a4,a4,366 # 80023080 <disk+0x80>
    80005f1a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f1c:	0001e717          	auipc	a4,0x1e
    80005f20:	0e470713          	addi	a4,a4,228 # 80024000 <disk+0x1000>
    80005f24:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f26:	4705                	li	a4,1
    80005f28:	00e78c23          	sb	a4,24(a5)
    80005f2c:	00e78ca3          	sb	a4,25(a5)
    80005f30:	00e78d23          	sb	a4,26(a5)
    80005f34:	00e78da3          	sb	a4,27(a5)
    80005f38:	00e78e23          	sb	a4,28(a5)
    80005f3c:	00e78ea3          	sb	a4,29(a5)
    80005f40:	00e78f23          	sb	a4,30(a5)
    80005f44:	00e78fa3          	sb	a4,31(a5)
}
    80005f48:	60e2                	ld	ra,24(sp)
    80005f4a:	6442                	ld	s0,16(sp)
    80005f4c:	64a2                	ld	s1,8(sp)
    80005f4e:	6105                	addi	sp,sp,32
    80005f50:	8082                	ret
    panic("could not find virtio disk");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	88650513          	addi	a0,a0,-1914 # 800087d8 <syscalls+0x360>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e0080e7          	jalr	1504(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	89650513          	addi	a0,a0,-1898 # 800087f8 <syscalls+0x380>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d0080e7          	jalr	1488(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	8a650513          	addi	a0,a0,-1882 # 80008818 <syscalls+0x3a0>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c0080e7          	jalr	1472(ra) # 8000053a <panic>

0000000080005f82 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f82:	7119                	addi	sp,sp,-128
    80005f84:	fc86                	sd	ra,120(sp)
    80005f86:	f8a2                	sd	s0,112(sp)
    80005f88:	f4a6                	sd	s1,104(sp)
    80005f8a:	f0ca                	sd	s2,96(sp)
    80005f8c:	ecce                	sd	s3,88(sp)
    80005f8e:	e8d2                	sd	s4,80(sp)
    80005f90:	e4d6                	sd	s5,72(sp)
    80005f92:	e0da                	sd	s6,64(sp)
    80005f94:	fc5e                	sd	s7,56(sp)
    80005f96:	f862                	sd	s8,48(sp)
    80005f98:	f466                	sd	s9,40(sp)
    80005f9a:	f06a                	sd	s10,32(sp)
    80005f9c:	ec6e                	sd	s11,24(sp)
    80005f9e:	0100                	addi	s0,sp,128
    80005fa0:	8aaa                	mv	s5,a0
    80005fa2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fa4:	00c52c83          	lw	s9,12(a0)
    80005fa8:	001c9c9b          	slliw	s9,s9,0x1
    80005fac:	1c82                	slli	s9,s9,0x20
    80005fae:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fb2:	0001f517          	auipc	a0,0x1f
    80005fb6:	17650513          	addi	a0,a0,374 # 80025128 <disk+0x2128>
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	c60080e7          	jalr	-928(ra) # 80000c1a <acquire>
  for(int i = 0; i < 3; i++){
    80005fc2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fc4:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fc6:	0001dc17          	auipc	s8,0x1d
    80005fca:	03ac0c13          	addi	s8,s8,58 # 80023000 <disk>
    80005fce:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005fd0:	4b0d                	li	s6,3
    80005fd2:	a0ad                	j	8000603c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005fd4:	00fc0733          	add	a4,s8,a5
    80005fd8:	975e                	add	a4,a4,s7
    80005fda:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fde:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fe0:	0207c563          	bltz	a5,8000600a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fe4:	2905                	addiw	s2,s2,1
    80005fe6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005fe8:	19690c63          	beq	s2,s6,80006180 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005fec:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005fee:	0001f717          	auipc	a4,0x1f
    80005ff2:	02a70713          	addi	a4,a4,42 # 80025018 <disk+0x2018>
    80005ff6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005ff8:	00074683          	lbu	a3,0(a4)
    80005ffc:	fee1                	bnez	a3,80005fd4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005ffe:	2785                	addiw	a5,a5,1
    80006000:	0705                	addi	a4,a4,1
    80006002:	fe979be3          	bne	a5,s1,80005ff8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006006:	57fd                	li	a5,-1
    80006008:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000600a:	01205d63          	blez	s2,80006024 <virtio_disk_rw+0xa2>
    8000600e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006010:	000a2503          	lw	a0,0(s4)
    80006014:	00000097          	auipc	ra,0x0
    80006018:	d92080e7          	jalr	-622(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    8000601c:	2d85                	addiw	s11,s11,1
    8000601e:	0a11                	addi	s4,s4,4
    80006020:	ff2d98e3          	bne	s11,s2,80006010 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006024:	0001f597          	auipc	a1,0x1f
    80006028:	10458593          	addi	a1,a1,260 # 80025128 <disk+0x2128>
    8000602c:	0001f517          	auipc	a0,0x1f
    80006030:	fec50513          	addi	a0,a0,-20 # 80025018 <disk+0x2018>
    80006034:	ffffc097          	auipc	ra,0xffffc
    80006038:	046080e7          	jalr	70(ra) # 8000207a <sleep>
  for(int i = 0; i < 3; i++){
    8000603c:	f8040a13          	addi	s4,s0,-128
{
    80006040:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006042:	894e                	mv	s2,s3
    80006044:	b765                	j	80005fec <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006046:	0001f697          	auipc	a3,0x1f
    8000604a:	fba6b683          	ld	a3,-70(a3) # 80025000 <disk+0x2000>
    8000604e:	96ba                	add	a3,a3,a4
    80006050:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006054:	0001d817          	auipc	a6,0x1d
    80006058:	fac80813          	addi	a6,a6,-84 # 80023000 <disk>
    8000605c:	0001f697          	auipc	a3,0x1f
    80006060:	fa468693          	addi	a3,a3,-92 # 80025000 <disk+0x2000>
    80006064:	6290                	ld	a2,0(a3)
    80006066:	963a                	add	a2,a2,a4
    80006068:	00c65583          	lhu	a1,12(a2)
    8000606c:	0015e593          	ori	a1,a1,1
    80006070:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006074:	f8842603          	lw	a2,-120(s0)
    80006078:	628c                	ld	a1,0(a3)
    8000607a:	972e                	add	a4,a4,a1
    8000607c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006080:	20050593          	addi	a1,a0,512
    80006084:	0592                	slli	a1,a1,0x4
    80006086:	95c2                	add	a1,a1,a6
    80006088:	577d                	li	a4,-1
    8000608a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000608e:	00461713          	slli	a4,a2,0x4
    80006092:	6290                	ld	a2,0(a3)
    80006094:	963a                	add	a2,a2,a4
    80006096:	03078793          	addi	a5,a5,48
    8000609a:	97c2                	add	a5,a5,a6
    8000609c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000609e:	629c                	ld	a5,0(a3)
    800060a0:	97ba                	add	a5,a5,a4
    800060a2:	4605                	li	a2,1
    800060a4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060a6:	629c                	ld	a5,0(a3)
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	4809                	li	a6,2
    800060ac:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060b0:	629c                	ld	a5,0(a3)
    800060b2:	97ba                	add	a5,a5,a4
    800060b4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060b8:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800060bc:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060c0:	6698                	ld	a4,8(a3)
    800060c2:	00275783          	lhu	a5,2(a4)
    800060c6:	8b9d                	andi	a5,a5,7
    800060c8:	0786                	slli	a5,a5,0x1
    800060ca:	973e                	add	a4,a4,a5
    800060cc:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800060d0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060d4:	6698                	ld	a4,8(a3)
    800060d6:	00275783          	lhu	a5,2(a4)
    800060da:	2785                	addiw	a5,a5,1
    800060dc:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060e0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060e4:	100017b7          	lui	a5,0x10001
    800060e8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060ec:	004aa783          	lw	a5,4(s5)
    800060f0:	02c79163          	bne	a5,a2,80006112 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800060f4:	0001f917          	auipc	s2,0x1f
    800060f8:	03490913          	addi	s2,s2,52 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800060fc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060fe:	85ca                	mv	a1,s2
    80006100:	8556                	mv	a0,s5
    80006102:	ffffc097          	auipc	ra,0xffffc
    80006106:	f78080e7          	jalr	-136(ra) # 8000207a <sleep>
  while(b->disk == 1) {
    8000610a:	004aa783          	lw	a5,4(s5)
    8000610e:	fe9788e3          	beq	a5,s1,800060fe <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006112:	f8042903          	lw	s2,-128(s0)
    80006116:	20090713          	addi	a4,s2,512
    8000611a:	0712                	slli	a4,a4,0x4
    8000611c:	0001d797          	auipc	a5,0x1d
    80006120:	ee478793          	addi	a5,a5,-284 # 80023000 <disk>
    80006124:	97ba                	add	a5,a5,a4
    80006126:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000612a:	0001f997          	auipc	s3,0x1f
    8000612e:	ed698993          	addi	s3,s3,-298 # 80025000 <disk+0x2000>
    80006132:	00491713          	slli	a4,s2,0x4
    80006136:	0009b783          	ld	a5,0(s3)
    8000613a:	97ba                	add	a5,a5,a4
    8000613c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006140:	854a                	mv	a0,s2
    80006142:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006146:	00000097          	auipc	ra,0x0
    8000614a:	c60080e7          	jalr	-928(ra) # 80005da6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000614e:	8885                	andi	s1,s1,1
    80006150:	f0ed                	bnez	s1,80006132 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006152:	0001f517          	auipc	a0,0x1f
    80006156:	fd650513          	addi	a0,a0,-42 # 80025128 <disk+0x2128>
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	b74080e7          	jalr	-1164(ra) # 80000cce <release>
}
    80006162:	70e6                	ld	ra,120(sp)
    80006164:	7446                	ld	s0,112(sp)
    80006166:	74a6                	ld	s1,104(sp)
    80006168:	7906                	ld	s2,96(sp)
    8000616a:	69e6                	ld	s3,88(sp)
    8000616c:	6a46                	ld	s4,80(sp)
    8000616e:	6aa6                	ld	s5,72(sp)
    80006170:	6b06                	ld	s6,64(sp)
    80006172:	7be2                	ld	s7,56(sp)
    80006174:	7c42                	ld	s8,48(sp)
    80006176:	7ca2                	ld	s9,40(sp)
    80006178:	7d02                	ld	s10,32(sp)
    8000617a:	6de2                	ld	s11,24(sp)
    8000617c:	6109                	addi	sp,sp,128
    8000617e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006180:	f8042503          	lw	a0,-128(s0)
    80006184:	20050793          	addi	a5,a0,512
    80006188:	0792                	slli	a5,a5,0x4
  if(write)
    8000618a:	0001d817          	auipc	a6,0x1d
    8000618e:	e7680813          	addi	a6,a6,-394 # 80023000 <disk>
    80006192:	00f80733          	add	a4,a6,a5
    80006196:	01a036b3          	snez	a3,s10
    8000619a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000619e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061a2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061a6:	7679                	lui	a2,0xffffe
    800061a8:	963e                	add	a2,a2,a5
    800061aa:	0001f697          	auipc	a3,0x1f
    800061ae:	e5668693          	addi	a3,a3,-426 # 80025000 <disk+0x2000>
    800061b2:	6298                	ld	a4,0(a3)
    800061b4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061b6:	0a878593          	addi	a1,a5,168
    800061ba:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061bc:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061be:	6298                	ld	a4,0(a3)
    800061c0:	9732                	add	a4,a4,a2
    800061c2:	45c1                	li	a1,16
    800061c4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061c6:	6298                	ld	a4,0(a3)
    800061c8:	9732                	add	a4,a4,a2
    800061ca:	4585                	li	a1,1
    800061cc:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061d0:	f8442703          	lw	a4,-124(s0)
    800061d4:	628c                	ld	a1,0(a3)
    800061d6:	962e                	add	a2,a2,a1
    800061d8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800061dc:	0712                	slli	a4,a4,0x4
    800061de:	6290                	ld	a2,0(a3)
    800061e0:	963a                	add	a2,a2,a4
    800061e2:	058a8593          	addi	a1,s5,88
    800061e6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061e8:	6294                	ld	a3,0(a3)
    800061ea:	96ba                	add	a3,a3,a4
    800061ec:	40000613          	li	a2,1024
    800061f0:	c690                	sw	a2,8(a3)
  if(write)
    800061f2:	e40d1ae3          	bnez	s10,80006046 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061f6:	0001f697          	auipc	a3,0x1f
    800061fa:	e0a6b683          	ld	a3,-502(a3) # 80025000 <disk+0x2000>
    800061fe:	96ba                	add	a3,a3,a4
    80006200:	4609                	li	a2,2
    80006202:	00c69623          	sh	a2,12(a3)
    80006206:	b5b9                	j	80006054 <virtio_disk_rw+0xd2>

0000000080006208 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006208:	1101                	addi	sp,sp,-32
    8000620a:	ec06                	sd	ra,24(sp)
    8000620c:	e822                	sd	s0,16(sp)
    8000620e:	e426                	sd	s1,8(sp)
    80006210:	e04a                	sd	s2,0(sp)
    80006212:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006214:	0001f517          	auipc	a0,0x1f
    80006218:	f1450513          	addi	a0,a0,-236 # 80025128 <disk+0x2128>
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	9fe080e7          	jalr	-1538(ra) # 80000c1a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006224:	10001737          	lui	a4,0x10001
    80006228:	533c                	lw	a5,96(a4)
    8000622a:	8b8d                	andi	a5,a5,3
    8000622c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000622e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006232:	0001f797          	auipc	a5,0x1f
    80006236:	dce78793          	addi	a5,a5,-562 # 80025000 <disk+0x2000>
    8000623a:	6b94                	ld	a3,16(a5)
    8000623c:	0207d703          	lhu	a4,32(a5)
    80006240:	0026d783          	lhu	a5,2(a3)
    80006244:	06f70163          	beq	a4,a5,800062a6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006248:	0001d917          	auipc	s2,0x1d
    8000624c:	db890913          	addi	s2,s2,-584 # 80023000 <disk>
    80006250:	0001f497          	auipc	s1,0x1f
    80006254:	db048493          	addi	s1,s1,-592 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006258:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000625c:	6898                	ld	a4,16(s1)
    8000625e:	0204d783          	lhu	a5,32(s1)
    80006262:	8b9d                	andi	a5,a5,7
    80006264:	078e                	slli	a5,a5,0x3
    80006266:	97ba                	add	a5,a5,a4
    80006268:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000626a:	20078713          	addi	a4,a5,512
    8000626e:	0712                	slli	a4,a4,0x4
    80006270:	974a                	add	a4,a4,s2
    80006272:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006276:	e731                	bnez	a4,800062c2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006278:	20078793          	addi	a5,a5,512
    8000627c:	0792                	slli	a5,a5,0x4
    8000627e:	97ca                	add	a5,a5,s2
    80006280:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006282:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006286:	ffffc097          	auipc	ra,0xffffc
    8000628a:	f80080e7          	jalr	-128(ra) # 80002206 <wakeup>

    disk.used_idx += 1;
    8000628e:	0204d783          	lhu	a5,32(s1)
    80006292:	2785                	addiw	a5,a5,1
    80006294:	17c2                	slli	a5,a5,0x30
    80006296:	93c1                	srli	a5,a5,0x30
    80006298:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000629c:	6898                	ld	a4,16(s1)
    8000629e:	00275703          	lhu	a4,2(a4)
    800062a2:	faf71be3          	bne	a4,a5,80006258 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800062a6:	0001f517          	auipc	a0,0x1f
    800062aa:	e8250513          	addi	a0,a0,-382 # 80025128 <disk+0x2128>
    800062ae:	ffffb097          	auipc	ra,0xffffb
    800062b2:	a20080e7          	jalr	-1504(ra) # 80000cce <release>
}
    800062b6:	60e2                	ld	ra,24(sp)
    800062b8:	6442                	ld	s0,16(sp)
    800062ba:	64a2                	ld	s1,8(sp)
    800062bc:	6902                	ld	s2,0(sp)
    800062be:	6105                	addi	sp,sp,32
    800062c0:	8082                	ret
      panic("virtio_disk_intr status");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	57650513          	addi	a0,a0,1398 # 80008838 <syscalls+0x3c0>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	270080e7          	jalr	624(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
