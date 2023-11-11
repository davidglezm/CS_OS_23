
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8d013103          	ld	sp,-1840(sp) # 800088d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	c9e78793          	addi	a5,a5,-866 # 80005d00 <timervec>
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
    8000012e:	366080e7          	jalr	870(ra) # 80002490 <either_copyin>
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
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	812080e7          	jalr	-2030(ra) # 800019d2 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	ec6080e7          	jalr	-314(ra) # 80002096 <sleep>
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
    80000210:	22e080e7          	jalr	558(ra) # 8000243a <either_copyout>
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
    800002f0:	1fa080e7          	jalr	506(ra) # 800024e6 <procdump>
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
    80000444:	de2080e7          	jalr	-542(ra) # 80002222 <wakeup>
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
    80000892:	994080e7          	jalr	-1644(ra) # 80002222 <wakeup>
    
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
    8000091e:	77c080e7          	jalr	1916(ra) # 80002096 <sleep>
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
    80000bb8:	e02080e7          	jalr	-510(ra) # 800019b6 <mycpu>
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
    80000bea:	dd0080e7          	jalr	-560(ra) # 800019b6 <mycpu>
    80000bee:	5d3c                	lw	a5,120(a0)
    80000bf0:	cf89                	beqz	a5,80000c0a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	dc4080e7          	jalr	-572(ra) # 800019b6 <mycpu>
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
    80000c0e:	dac080e7          	jalr	-596(ra) # 800019b6 <mycpu>
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
    80000c4e:	d6c080e7          	jalr	-660(ra) # 800019b6 <mycpu>
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
    80000c7a:	d40080e7          	jalr	-704(ra) # 800019b6 <mycpu>
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
    80000ec8:	ae2080e7          	jalr	-1310(ra) # 800019a6 <cpuid>
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
    80000ee4:	ac6080e7          	jalr	-1338(ra) # 800019a6 <cpuid>
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
    80000f06:	7e4080e7          	jalr	2020(ra) # 800026e6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0a:	00005097          	auipc	ra,0x5
    80000f0e:	e36080e7          	jalr	-458(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000f12:	00001097          	auipc	ra,0x1
    80000f16:	fd2080e7          	jalr	-46(ra) # 80001ee4 <scheduler>
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
    80000f76:	984080e7          	jalr	-1660(ra) # 800018f6 <procinit>
    trapinit();      // trap vectors
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	744080e7          	jalr	1860(ra) # 800026be <trapinit>
    trapinithart();  // install kernel trap vector
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	764080e7          	jalr	1892(ra) # 800026e6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	da0080e7          	jalr	-608(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f92:	00005097          	auipc	ra,0x5
    80000f96:	dae080e7          	jalr	-594(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	f6e080e7          	jalr	-146(ra) # 80002f08 <binit>
    iinit();         // inode table
    80000fa2:	00002097          	auipc	ra,0x2
    80000fa6:	5fc080e7          	jalr	1532(ra) # 8000359e <iinit>
    fileinit();      // file table
    80000faa:	00003097          	auipc	ra,0x3
    80000fae:	5ae080e7          	jalr	1454(ra) # 80004558 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb2:	00005097          	auipc	ra,0x5
    80000fb6:	eae080e7          	jalr	-338(ra) # 80005e60 <virtio_disk_init>
    userinit();      // first user process
    80000fba:	00001097          	auipc	ra,0x1
    80000fbe:	cf0080e7          	jalr	-784(ra) # 80001caa <userinit>
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
    80001272:	5f2080e7          	jalr	1522(ra) # 80001860 <proc_mapstacks>
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
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012cc:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ce:	6a85                	lui	s5,0x1
    800012d0:	0535ea63          	bltu	a1,s3,80001324 <uvmunmap+0x80>
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
      panic("uvmunmap: walk");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e1e50513          	addi	a0,a0,-482 # 80008118 <digits+0xd8>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	238080e7          	jalr	568(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    8000130a:	00007517          	auipc	a0,0x7
    8000130e:	e1e50513          	addi	a0,a0,-482 # 80008128 <digits+0xe8>
    80001312:	fffff097          	auipc	ra,0xfffff
    80001316:	228080e7          	jalr	552(ra) # 8000053a <panic>
    *pte = 0;
    8000131a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131e:	9956                	add	s2,s2,s5
    80001320:	fb397ae3          	bgeu	s2,s3,800012d4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001324:	4601                	li	a2,0
    80001326:	85ca                	mv	a1,s2
    80001328:	8552                	mv	a0,s4
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	ccc080e7          	jalr	-820(ra) # 80000ff6 <walk>
    80001332:	84aa                	mv	s1,a0
    80001334:	d179                	beqz	a0,800012fa <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001336:	611c                	ld	a5,0(a0)
    80001338:	0017f713          	andi	a4,a5,1
    8000133c:	d36d                	beqz	a4,8000131e <uvmunmap+0x7a>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133e:	3ff7f713          	andi	a4,a5,1023
    80001342:	fd7704e3          	beq	a4,s7,8000130a <uvmunmap+0x66>
    if(do_free){
    80001346:	fc0b0ae3          	beqz	s6,8000131a <uvmunmap+0x76>
      uint64 pa = PTE2PA(*pte);
    8000134a:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000134c:	00c79513          	slli	a0,a5,0xc
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	692080e7          	jalr	1682(ra) # 800009e2 <kfree>
    80001358:	b7c9                	j	8000131a <uvmunmap+0x76>

000000008000135a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135a:	1101                	addi	sp,sp,-32
    8000135c:	ec06                	sd	ra,24(sp)
    8000135e:	e822                	sd	s0,16(sp)
    80001360:	e426                	sd	s1,8(sp)
    80001362:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001364:	fffff097          	auipc	ra,0xfffff
    80001368:	77c080e7          	jalr	1916(ra) # 80000ae0 <kalloc>
    8000136c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000136e:	c519                	beqz	a0,8000137c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001370:	6605                	lui	a2,0x1
    80001372:	4581                	li	a1,0
    80001374:	00000097          	auipc	ra,0x0
    80001378:	9a2080e7          	jalr	-1630(ra) # 80000d16 <memset>
  return pagetable;
}
    8000137c:	8526                	mv	a0,s1
    8000137e:	60e2                	ld	ra,24(sp)
    80001380:	6442                	ld	s0,16(sp)
    80001382:	64a2                	ld	s1,8(sp)
    80001384:	6105                	addi	sp,sp,32
    80001386:	8082                	ret

0000000080001388 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001388:	7179                	addi	sp,sp,-48
    8000138a:	f406                	sd	ra,40(sp)
    8000138c:	f022                	sd	s0,32(sp)
    8000138e:	ec26                	sd	s1,24(sp)
    80001390:	e84a                	sd	s2,16(sp)
    80001392:	e44e                	sd	s3,8(sp)
    80001394:	e052                	sd	s4,0(sp)
    80001396:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001398:	6785                	lui	a5,0x1
    8000139a:	04f67863          	bgeu	a2,a5,800013ea <uvminit+0x62>
    8000139e:	8a2a                	mv	s4,a0
    800013a0:	89ae                	mv	s3,a1
    800013a2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	73c080e7          	jalr	1852(ra) # 80000ae0 <kalloc>
    800013ac:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ae:	6605                	lui	a2,0x1
    800013b0:	4581                	li	a1,0
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	964080e7          	jalr	-1692(ra) # 80000d16 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ba:	4779                	li	a4,30
    800013bc:	86ca                	mv	a3,s2
    800013be:	6605                	lui	a2,0x1
    800013c0:	4581                	li	a1,0
    800013c2:	8552                	mv	a0,s4
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	d1a080e7          	jalr	-742(ra) # 800010de <mappages>
  memmove(mem, src, sz);
    800013cc:	8626                	mv	a2,s1
    800013ce:	85ce                	mv	a1,s3
    800013d0:	854a                	mv	a0,s2
    800013d2:	00000097          	auipc	ra,0x0
    800013d6:	9a0080e7          	jalr	-1632(ra) # 80000d72 <memmove>
}
    800013da:	70a2                	ld	ra,40(sp)
    800013dc:	7402                	ld	s0,32(sp)
    800013de:	64e2                	ld	s1,24(sp)
    800013e0:	6942                	ld	s2,16(sp)
    800013e2:	69a2                	ld	s3,8(sp)
    800013e4:	6a02                	ld	s4,0(sp)
    800013e6:	6145                	addi	sp,sp,48
    800013e8:	8082                	ret
    panic("inituvm: more than a page");
    800013ea:	00007517          	auipc	a0,0x7
    800013ee:	d5650513          	addi	a0,a0,-682 # 80008140 <digits+0x100>
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	148080e7          	jalr	328(ra) # 8000053a <panic>

00000000800013fa <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fa:	1101                	addi	sp,sp,-32
    800013fc:	ec06                	sd	ra,24(sp)
    800013fe:	e822                	sd	s0,16(sp)
    80001400:	e426                	sd	s1,8(sp)
    80001402:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001404:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001406:	00b67d63          	bgeu	a2,a1,80001420 <uvmdealloc+0x26>
    8000140a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000140c:	6785                	lui	a5,0x1
    8000140e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001410:	00f60733          	add	a4,a2,a5
    80001414:	76fd                	lui	a3,0xfffff
    80001416:	8f75                	and	a4,a4,a3
    80001418:	97ae                	add	a5,a5,a1
    8000141a:	8ff5                	and	a5,a5,a3
    8000141c:	00f76863          	bltu	a4,a5,8000142c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001420:	8526                	mv	a0,s1
    80001422:	60e2                	ld	ra,24(sp)
    80001424:	6442                	ld	s0,16(sp)
    80001426:	64a2                	ld	s1,8(sp)
    80001428:	6105                	addi	sp,sp,32
    8000142a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000142c:	8f99                	sub	a5,a5,a4
    8000142e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001430:	4685                	li	a3,1
    80001432:	0007861b          	sext.w	a2,a5
    80001436:	85ba                	mv	a1,a4
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	e6c080e7          	jalr	-404(ra) # 800012a4 <uvmunmap>
    80001440:	b7c5                	j	80001420 <uvmdealloc+0x26>

0000000080001442 <uvmalloc>:
  if(newsz < oldsz)
    80001442:	0ab66163          	bltu	a2,a1,800014e4 <uvmalloc+0xa2>
{
    80001446:	7139                	addi	sp,sp,-64
    80001448:	fc06                	sd	ra,56(sp)
    8000144a:	f822                	sd	s0,48(sp)
    8000144c:	f426                	sd	s1,40(sp)
    8000144e:	f04a                	sd	s2,32(sp)
    80001450:	ec4e                	sd	s3,24(sp)
    80001452:	e852                	sd	s4,16(sp)
    80001454:	e456                	sd	s5,8(sp)
    80001456:	0080                	addi	s0,sp,64
    80001458:	8aaa                	mv	s5,a0
    8000145a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000145c:	6785                	lui	a5,0x1
    8000145e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001460:	95be                	add	a1,a1,a5
    80001462:	77fd                	lui	a5,0xfffff
    80001464:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	08c9f063          	bgeu	s3,a2,800014e8 <uvmalloc+0xa6>
    8000146c:	894e                	mv	s2,s3
    mem = kalloc();
    8000146e:	fffff097          	auipc	ra,0xfffff
    80001472:	672080e7          	jalr	1650(ra) # 80000ae0 <kalloc>
    80001476:	84aa                	mv	s1,a0
    if(mem == 0){
    80001478:	c51d                	beqz	a0,800014a6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000147a:	6605                	lui	a2,0x1
    8000147c:	4581                	li	a1,0
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	898080e7          	jalr	-1896(ra) # 80000d16 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001486:	4779                	li	a4,30
    80001488:	86a6                	mv	a3,s1
    8000148a:	6605                	lui	a2,0x1
    8000148c:	85ca                	mv	a1,s2
    8000148e:	8556                	mv	a0,s5
    80001490:	00000097          	auipc	ra,0x0
    80001494:	c4e080e7          	jalr	-946(ra) # 800010de <mappages>
    80001498:	e905                	bnez	a0,800014c8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149a:	6785                	lui	a5,0x1
    8000149c:	993e                	add	s2,s2,a5
    8000149e:	fd4968e3          	bltu	s2,s4,8000146e <uvmalloc+0x2c>
  return newsz;
    800014a2:	8552                	mv	a0,s4
    800014a4:	a809                	j	800014b6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014a6:	864e                	mv	a2,s3
    800014a8:	85ca                	mv	a1,s2
    800014aa:	8556                	mv	a0,s5
    800014ac:	00000097          	auipc	ra,0x0
    800014b0:	f4e080e7          	jalr	-178(ra) # 800013fa <uvmdealloc>
      return 0;
    800014b4:	4501                	li	a0,0
}
    800014b6:	70e2                	ld	ra,56(sp)
    800014b8:	7442                	ld	s0,48(sp)
    800014ba:	74a2                	ld	s1,40(sp)
    800014bc:	7902                	ld	s2,32(sp)
    800014be:	69e2                	ld	s3,24(sp)
    800014c0:	6a42                	ld	s4,16(sp)
    800014c2:	6aa2                	ld	s5,8(sp)
    800014c4:	6121                	addi	sp,sp,64
    800014c6:	8082                	ret
      kfree(mem);
    800014c8:	8526                	mv	a0,s1
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	518080e7          	jalr	1304(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014d2:	864e                	mv	a2,s3
    800014d4:	85ca                	mv	a1,s2
    800014d6:	8556                	mv	a0,s5
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	f22080e7          	jalr	-222(ra) # 800013fa <uvmdealloc>
      return 0;
    800014e0:	4501                	li	a0,0
    800014e2:	bfd1                	j	800014b6 <uvmalloc+0x74>
    return oldsz;
    800014e4:	852e                	mv	a0,a1
}
    800014e6:	8082                	ret
  return newsz;
    800014e8:	8532                	mv	a0,a2
    800014ea:	b7f1                	j	800014b6 <uvmalloc+0x74>

00000000800014ec <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ec:	7179                	addi	sp,sp,-48
    800014ee:	f406                	sd	ra,40(sp)
    800014f0:	f022                	sd	s0,32(sp)
    800014f2:	ec26                	sd	s1,24(sp)
    800014f4:	e84a                	sd	s2,16(sp)
    800014f6:	e44e                	sd	s3,8(sp)
    800014f8:	e052                	sd	s4,0(sp)
    800014fa:	1800                	addi	s0,sp,48
    800014fc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014fe:	84aa                	mv	s1,a0
    80001500:	6905                	lui	s2,0x1
    80001502:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001504:	4985                	li	s3,1
    80001506:	a829                	j	80001520 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001508:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000150a:	00c79513          	slli	a0,a5,0xc
    8000150e:	00000097          	auipc	ra,0x0
    80001512:	fde080e7          	jalr	-34(ra) # 800014ec <freewalk>
      pagetable[i] = 0;
    80001516:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000151a:	04a1                	addi	s1,s1,8
    8000151c:	03248163          	beq	s1,s2,8000153e <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001520:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001522:	00f7f713          	andi	a4,a5,15
    80001526:	ff3701e3          	beq	a4,s3,80001508 <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000152a:	8b85                	andi	a5,a5,1
    8000152c:	d7fd                	beqz	a5,8000151a <freewalk+0x2e>
      panic("freewalk: leaf");
    8000152e:	00007517          	auipc	a0,0x7
    80001532:	c3250513          	addi	a0,a0,-974 # 80008160 <digits+0x120>
    80001536:	fffff097          	auipc	ra,0xfffff
    8000153a:	004080e7          	jalr	4(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    8000153e:	8552                	mv	a0,s4
    80001540:	fffff097          	auipc	ra,0xfffff
    80001544:	4a2080e7          	jalr	1186(ra) # 800009e2 <kfree>
}
    80001548:	70a2                	ld	ra,40(sp)
    8000154a:	7402                	ld	s0,32(sp)
    8000154c:	64e2                	ld	s1,24(sp)
    8000154e:	6942                	ld	s2,16(sp)
    80001550:	69a2                	ld	s3,8(sp)
    80001552:	6a02                	ld	s4,0(sp)
    80001554:	6145                	addi	sp,sp,48
    80001556:	8082                	ret

0000000080001558 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001558:	1101                	addi	sp,sp,-32
    8000155a:	ec06                	sd	ra,24(sp)
    8000155c:	e822                	sd	s0,16(sp)
    8000155e:	e426                	sd	s1,8(sp)
    80001560:	1000                	addi	s0,sp,32
    80001562:	84aa                	mv	s1,a0
  if(sz > 0)
    80001564:	e999                	bnez	a1,8000157a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001566:	8526                	mv	a0,s1
    80001568:	00000097          	auipc	ra,0x0
    8000156c:	f84080e7          	jalr	-124(ra) # 800014ec <freewalk>
}
    80001570:	60e2                	ld	ra,24(sp)
    80001572:	6442                	ld	s0,16(sp)
    80001574:	64a2                	ld	s1,8(sp)
    80001576:	6105                	addi	sp,sp,32
    80001578:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000157a:	6785                	lui	a5,0x1
    8000157c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000157e:	95be                	add	a1,a1,a5
    80001580:	4685                	li	a3,1
    80001582:	00c5d613          	srli	a2,a1,0xc
    80001586:	4581                	li	a1,0
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	d1c080e7          	jalr	-740(ra) # 800012a4 <uvmunmap>
    80001590:	bfd9                	j	80001566 <uvmfree+0xe>

0000000080001592 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001592:	c679                	beqz	a2,80001660 <uvmcopy+0xce>
{
    80001594:	715d                	addi	sp,sp,-80
    80001596:	e486                	sd	ra,72(sp)
    80001598:	e0a2                	sd	s0,64(sp)
    8000159a:	fc26                	sd	s1,56(sp)
    8000159c:	f84a                	sd	s2,48(sp)
    8000159e:	f44e                	sd	s3,40(sp)
    800015a0:	f052                	sd	s4,32(sp)
    800015a2:	ec56                	sd	s5,24(sp)
    800015a4:	e85a                	sd	s6,16(sp)
    800015a6:	e45e                	sd	s7,8(sp)
    800015a8:	0880                	addi	s0,sp,80
    800015aa:	8b2a                	mv	s6,a0
    800015ac:	8aae                	mv	s5,a1
    800015ae:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015b2:	4601                	li	a2,0
    800015b4:	85ce                	mv	a1,s3
    800015b6:	855a                	mv	a0,s6
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	a3e080e7          	jalr	-1474(ra) # 80000ff6 <walk>
    800015c0:	c531                	beqz	a0,8000160c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015c2:	6118                	ld	a4,0(a0)
    800015c4:	00177793          	andi	a5,a4,1
    800015c8:	cbb1                	beqz	a5,8000161c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ca:	00a75593          	srli	a1,a4,0xa
    800015ce:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015d2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	50a080e7          	jalr	1290(ra) # 80000ae0 <kalloc>
    800015de:	892a                	mv	s2,a0
    800015e0:	c939                	beqz	a0,80001636 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015e2:	6605                	lui	a2,0x1
    800015e4:	85de                	mv	a1,s7
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	78c080e7          	jalr	1932(ra) # 80000d72 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ee:	8726                	mv	a4,s1
    800015f0:	86ca                	mv	a3,s2
    800015f2:	6605                	lui	a2,0x1
    800015f4:	85ce                	mv	a1,s3
    800015f6:	8556                	mv	a0,s5
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	ae6080e7          	jalr	-1306(ra) # 800010de <mappages>
    80001600:	e515                	bnez	a0,8000162c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001602:	6785                	lui	a5,0x1
    80001604:	99be                	add	s3,s3,a5
    80001606:	fb49e6e3          	bltu	s3,s4,800015b2 <uvmcopy+0x20>
    8000160a:	a081                	j	8000164a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000160c:	00007517          	auipc	a0,0x7
    80001610:	b6450513          	addi	a0,a0,-1180 # 80008170 <digits+0x130>
    80001614:	fffff097          	auipc	ra,0xfffff
    80001618:	f26080e7          	jalr	-218(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    8000161c:	00007517          	auipc	a0,0x7
    80001620:	b7450513          	addi	a0,a0,-1164 # 80008190 <digits+0x150>
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	f16080e7          	jalr	-234(ra) # 8000053a <panic>
      kfree(mem);
    8000162c:	854a                	mv	a0,s2
    8000162e:	fffff097          	auipc	ra,0xfffff
    80001632:	3b4080e7          	jalr	948(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001636:	4685                	li	a3,1
    80001638:	00c9d613          	srli	a2,s3,0xc
    8000163c:	4581                	li	a1,0
    8000163e:	8556                	mv	a0,s5
    80001640:	00000097          	auipc	ra,0x0
    80001644:	c64080e7          	jalr	-924(ra) # 800012a4 <uvmunmap>
  return -1;
    80001648:	557d                	li	a0,-1
}
    8000164a:	60a6                	ld	ra,72(sp)
    8000164c:	6406                	ld	s0,64(sp)
    8000164e:	74e2                	ld	s1,56(sp)
    80001650:	7942                	ld	s2,48(sp)
    80001652:	79a2                	ld	s3,40(sp)
    80001654:	7a02                	ld	s4,32(sp)
    80001656:	6ae2                	ld	s5,24(sp)
    80001658:	6b42                	ld	s6,16(sp)
    8000165a:	6ba2                	ld	s7,8(sp)
    8000165c:	6161                	addi	sp,sp,80
    8000165e:	8082                	ret
  return 0;
    80001660:	4501                	li	a0,0
}
    80001662:	8082                	ret

0000000080001664 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001664:	1141                	addi	sp,sp,-16
    80001666:	e406                	sd	ra,8(sp)
    80001668:	e022                	sd	s0,0(sp)
    8000166a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000166c:	4601                	li	a2,0
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	988080e7          	jalr	-1656(ra) # 80000ff6 <walk>
  if(pte == 0)
    80001676:	c901                	beqz	a0,80001686 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001678:	611c                	ld	a5,0(a0)
    8000167a:	9bbd                	andi	a5,a5,-17
    8000167c:	e11c                	sd	a5,0(a0)
}
    8000167e:	60a2                	ld	ra,8(sp)
    80001680:	6402                	ld	s0,0(sp)
    80001682:	0141                	addi	sp,sp,16
    80001684:	8082                	ret
    panic("uvmclear");
    80001686:	00007517          	auipc	a0,0x7
    8000168a:	b2a50513          	addi	a0,a0,-1238 # 800081b0 <digits+0x170>
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	eac080e7          	jalr	-340(ra) # 8000053a <panic>

0000000080001696 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001696:	c6bd                	beqz	a3,80001704 <copyout+0x6e>
{
    80001698:	715d                	addi	sp,sp,-80
    8000169a:	e486                	sd	ra,72(sp)
    8000169c:	e0a2                	sd	s0,64(sp)
    8000169e:	fc26                	sd	s1,56(sp)
    800016a0:	f84a                	sd	s2,48(sp)
    800016a2:	f44e                	sd	s3,40(sp)
    800016a4:	f052                	sd	s4,32(sp)
    800016a6:	ec56                	sd	s5,24(sp)
    800016a8:	e85a                	sd	s6,16(sp)
    800016aa:	e45e                	sd	s7,8(sp)
    800016ac:	e062                	sd	s8,0(sp)
    800016ae:	0880                	addi	s0,sp,80
    800016b0:	8b2a                	mv	s6,a0
    800016b2:	8c2e                	mv	s8,a1
    800016b4:	8a32                	mv	s4,a2
    800016b6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ba:	6a85                	lui	s5,0x1
    800016bc:	a015                	j	800016e0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016be:	9562                	add	a0,a0,s8
    800016c0:	0004861b          	sext.w	a2,s1
    800016c4:	85d2                	mv	a1,s4
    800016c6:	41250533          	sub	a0,a0,s2
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	6a8080e7          	jalr	1704(ra) # 80000d72 <memmove>

    len -= n;
    800016d2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016dc:	02098263          	beqz	s3,80001700 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016e0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e4:	85ca                	mv	a1,s2
    800016e6:	855a                	mv	a0,s6
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	9b4080e7          	jalr	-1612(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    800016f0:	cd01                	beqz	a0,80001708 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016f2:	418904b3          	sub	s1,s2,s8
    800016f6:	94d6                	add	s1,s1,s5
    800016f8:	fc99f3e3          	bgeu	s3,s1,800016be <copyout+0x28>
    800016fc:	84ce                	mv	s1,s3
    800016fe:	b7c1                	j	800016be <copyout+0x28>
  }
  return 0;
    80001700:	4501                	li	a0,0
    80001702:	a021                	j	8000170a <copyout+0x74>
    80001704:	4501                	li	a0,0
}
    80001706:	8082                	ret
      return -1;
    80001708:	557d                	li	a0,-1
}
    8000170a:	60a6                	ld	ra,72(sp)
    8000170c:	6406                	ld	s0,64(sp)
    8000170e:	74e2                	ld	s1,56(sp)
    80001710:	7942                	ld	s2,48(sp)
    80001712:	79a2                	ld	s3,40(sp)
    80001714:	7a02                	ld	s4,32(sp)
    80001716:	6ae2                	ld	s5,24(sp)
    80001718:	6b42                	ld	s6,16(sp)
    8000171a:	6ba2                	ld	s7,8(sp)
    8000171c:	6c02                	ld	s8,0(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret

0000000080001722 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001722:	caa5                	beqz	a3,80001792 <copyin+0x70>
{
    80001724:	715d                	addi	sp,sp,-80
    80001726:	e486                	sd	ra,72(sp)
    80001728:	e0a2                	sd	s0,64(sp)
    8000172a:	fc26                	sd	s1,56(sp)
    8000172c:	f84a                	sd	s2,48(sp)
    8000172e:	f44e                	sd	s3,40(sp)
    80001730:	f052                	sd	s4,32(sp)
    80001732:	ec56                	sd	s5,24(sp)
    80001734:	e85a                	sd	s6,16(sp)
    80001736:	e45e                	sd	s7,8(sp)
    80001738:	e062                	sd	s8,0(sp)
    8000173a:	0880                	addi	s0,sp,80
    8000173c:	8b2a                	mv	s6,a0
    8000173e:	8a2e                	mv	s4,a1
    80001740:	8c32                	mv	s8,a2
    80001742:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001744:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001746:	6a85                	lui	s5,0x1
    80001748:	a01d                	j	8000176e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000174a:	018505b3          	add	a1,a0,s8
    8000174e:	0004861b          	sext.w	a2,s1
    80001752:	412585b3          	sub	a1,a1,s2
    80001756:	8552                	mv	a0,s4
    80001758:	fffff097          	auipc	ra,0xfffff
    8000175c:	61a080e7          	jalr	1562(ra) # 80000d72 <memmove>

    len -= n;
    80001760:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001764:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001766:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000176a:	02098263          	beqz	s3,8000178e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000176e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001772:	85ca                	mv	a1,s2
    80001774:	855a                	mv	a0,s6
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	926080e7          	jalr	-1754(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    8000177e:	cd01                	beqz	a0,80001796 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001780:	418904b3          	sub	s1,s2,s8
    80001784:	94d6                	add	s1,s1,s5
    80001786:	fc99f2e3          	bgeu	s3,s1,8000174a <copyin+0x28>
    8000178a:	84ce                	mv	s1,s3
    8000178c:	bf7d                	j	8000174a <copyin+0x28>
  }
  return 0;
    8000178e:	4501                	li	a0,0
    80001790:	a021                	j	80001798 <copyin+0x76>
    80001792:	4501                	li	a0,0
}
    80001794:	8082                	ret
      return -1;
    80001796:	557d                	li	a0,-1
}
    80001798:	60a6                	ld	ra,72(sp)
    8000179a:	6406                	ld	s0,64(sp)
    8000179c:	74e2                	ld	s1,56(sp)
    8000179e:	7942                	ld	s2,48(sp)
    800017a0:	79a2                	ld	s3,40(sp)
    800017a2:	7a02                	ld	s4,32(sp)
    800017a4:	6ae2                	ld	s5,24(sp)
    800017a6:	6b42                	ld	s6,16(sp)
    800017a8:	6ba2                	ld	s7,8(sp)
    800017aa:	6c02                	ld	s8,0(sp)
    800017ac:	6161                	addi	sp,sp,80
    800017ae:	8082                	ret

00000000800017b0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017b0:	c2dd                	beqz	a3,80001856 <copyinstr+0xa6>
{
    800017b2:	715d                	addi	sp,sp,-80
    800017b4:	e486                	sd	ra,72(sp)
    800017b6:	e0a2                	sd	s0,64(sp)
    800017b8:	fc26                	sd	s1,56(sp)
    800017ba:	f84a                	sd	s2,48(sp)
    800017bc:	f44e                	sd	s3,40(sp)
    800017be:	f052                	sd	s4,32(sp)
    800017c0:	ec56                	sd	s5,24(sp)
    800017c2:	e85a                	sd	s6,16(sp)
    800017c4:	e45e                	sd	s7,8(sp)
    800017c6:	0880                	addi	s0,sp,80
    800017c8:	8a2a                	mv	s4,a0
    800017ca:	8b2e                	mv	s6,a1
    800017cc:	8bb2                	mv	s7,a2
    800017ce:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017d0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d2:	6985                	lui	s3,0x1
    800017d4:	a02d                	j	800017fe <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017da:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017dc:	37fd                	addiw	a5,a5,-1
    800017de:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6161                	addi	sp,sp,80
    800017f6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017fc:	c8a9                	beqz	s1,8000184e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017fe:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001802:	85ca                	mv	a1,s2
    80001804:	8552                	mv	a0,s4
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	896080e7          	jalr	-1898(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    8000180e:	c131                	beqz	a0,80001852 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001810:	417906b3          	sub	a3,s2,s7
    80001814:	96ce                	add	a3,a3,s3
    80001816:	00d4f363          	bgeu	s1,a3,8000181c <copyinstr+0x6c>
    8000181a:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000181c:	955e                	add	a0,a0,s7
    8000181e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001822:	daf9                	beqz	a3,800017f8 <copyinstr+0x48>
    80001824:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001826:	41650633          	sub	a2,a0,s6
    8000182a:	fff48593          	addi	a1,s1,-1
    8000182e:	95da                	add	a1,a1,s6
    while(n > 0){
    80001830:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001832:	00f60733          	add	a4,a2,a5
    80001836:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    8000183a:	df51                	beqz	a4,800017d6 <copyinstr+0x26>
        *dst = *p;
    8000183c:	00e78023          	sb	a4,0(a5)
      --max;
    80001840:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001844:	0785                	addi	a5,a5,1
    while(n > 0){
    80001846:	fed796e3          	bne	a5,a3,80001832 <copyinstr+0x82>
      dst++;
    8000184a:	8b3e                	mv	s6,a5
    8000184c:	b775                	j	800017f8 <copyinstr+0x48>
    8000184e:	4781                	li	a5,0
    80001850:	b771                	j	800017dc <copyinstr+0x2c>
      return -1;
    80001852:	557d                	li	a0,-1
    80001854:	b779                	j	800017e2 <copyinstr+0x32>
  int got_null = 0;
    80001856:	4781                	li	a5,0
  if(got_null){
    80001858:	37fd                	addiw	a5,a5,-1
    8000185a:	0007851b          	sext.w	a0,a5
}
    8000185e:	8082                	ret

0000000080001860 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001860:	7139                	addi	sp,sp,-64
    80001862:	fc06                	sd	ra,56(sp)
    80001864:	f822                	sd	s0,48(sp)
    80001866:	f426                	sd	s1,40(sp)
    80001868:	f04a                	sd	s2,32(sp)
    8000186a:	ec4e                	sd	s3,24(sp)
    8000186c:	e852                	sd	s4,16(sp)
    8000186e:	e456                	sd	s5,8(sp)
    80001870:	e05a                	sd	s6,0(sp)
    80001872:	0080                	addi	s0,sp,64
    80001874:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	00010497          	auipc	s1,0x10
    8000187a:	e5a48493          	addi	s1,s1,-422 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000187e:	8b26                	mv	s6,s1
    80001880:	00006a97          	auipc	s5,0x6
    80001884:	780a8a93          	addi	s5,s5,1920 # 80008000 <etext>
    80001888:	04000937          	lui	s2,0x4000
    8000188c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000188e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001890:	00016a17          	auipc	s4,0x16
    80001894:	840a0a13          	addi	s4,s4,-1984 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001898:	fffff097          	auipc	ra,0xfffff
    8000189c:	248080e7          	jalr	584(ra) # 80000ae0 <kalloc>
    800018a0:	862a                	mv	a2,a0
    if(pa == 0)
    800018a2:	c131                	beqz	a0,800018e6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018a4:	416485b3          	sub	a1,s1,s6
    800018a8:	858d                	srai	a1,a1,0x3
    800018aa:	000ab783          	ld	a5,0(s5)
    800018ae:	02f585b3          	mul	a1,a1,a5
    800018b2:	2585                	addiw	a1,a1,1
    800018b4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b8:	4719                	li	a4,6
    800018ba:	6685                	lui	a3,0x1
    800018bc:	40b905b3          	sub	a1,s2,a1
    800018c0:	854e                	mv	a0,s3
    800018c2:	00000097          	auipc	ra,0x0
    800018c6:	8bc080e7          	jalr	-1860(ra) # 8000117e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ca:	16848493          	addi	s1,s1,360
    800018ce:	fd4495e3          	bne	s1,s4,80001898 <proc_mapstacks+0x38>
  }
}
    800018d2:	70e2                	ld	ra,56(sp)
    800018d4:	7442                	ld	s0,48(sp)
    800018d6:	74a2                	ld	s1,40(sp)
    800018d8:	7902                	ld	s2,32(sp)
    800018da:	69e2                	ld	s3,24(sp)
    800018dc:	6a42                	ld	s4,16(sp)
    800018de:	6aa2                	ld	s5,8(sp)
    800018e0:	6b02                	ld	s6,0(sp)
    800018e2:	6121                	addi	sp,sp,64
    800018e4:	8082                	ret
      panic("kalloc");
    800018e6:	00007517          	auipc	a0,0x7
    800018ea:	8da50513          	addi	a0,a0,-1830 # 800081c0 <digits+0x180>
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	c4c080e7          	jalr	-948(ra) # 8000053a <panic>

00000000800018f6 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018f6:	7139                	addi	sp,sp,-64
    800018f8:	fc06                	sd	ra,56(sp)
    800018fa:	f822                	sd	s0,48(sp)
    800018fc:	f426                	sd	s1,40(sp)
    800018fe:	f04a                	sd	s2,32(sp)
    80001900:	ec4e                	sd	s3,24(sp)
    80001902:	e852                	sd	s4,16(sp)
    80001904:	e456                	sd	s5,8(sp)
    80001906:	e05a                	sd	s6,0(sp)
    80001908:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000190a:	00007597          	auipc	a1,0x7
    8000190e:	8be58593          	addi	a1,a1,-1858 # 800081c8 <digits+0x188>
    80001912:	00010517          	auipc	a0,0x10
    80001916:	98e50513          	addi	a0,a0,-1650 # 800112a0 <pid_lock>
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	270080e7          	jalr	624(ra) # 80000b8a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001922:	00007597          	auipc	a1,0x7
    80001926:	8ae58593          	addi	a1,a1,-1874 # 800081d0 <digits+0x190>
    8000192a:	00010517          	auipc	a0,0x10
    8000192e:	98e50513          	addi	a0,a0,-1650 # 800112b8 <wait_lock>
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	258080e7          	jalr	600(ra) # 80000b8a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00010497          	auipc	s1,0x10
    8000193e:	d9648493          	addi	s1,s1,-618 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001942:	00007b17          	auipc	s6,0x7
    80001946:	89eb0b13          	addi	s6,s6,-1890 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	8aa6                	mv	s5,s1
    8000194c:	00006a17          	auipc	s4,0x6
    80001950:	6b4a0a13          	addi	s4,s4,1716 # 80008000 <etext>
    80001954:	04000937          	lui	s2,0x4000
    80001958:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000195a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	00015997          	auipc	s3,0x15
    80001960:	77498993          	addi	s3,s3,1908 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001964:	85da                	mv	a1,s6
    80001966:	8526                	mv	a0,s1
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	222080e7          	jalr	546(ra) # 80000b8a <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001970:	415487b3          	sub	a5,s1,s5
    80001974:	878d                	srai	a5,a5,0x3
    80001976:	000a3703          	ld	a4,0(s4)
    8000197a:	02e787b3          	mul	a5,a5,a4
    8000197e:	2785                	addiw	a5,a5,1
    80001980:	00d7979b          	slliw	a5,a5,0xd
    80001984:	40f907b3          	sub	a5,s2,a5
    80001988:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198a:	16848493          	addi	s1,s1,360
    8000198e:	fd349be3          	bne	s1,s3,80001964 <procinit+0x6e>
  }
}
    80001992:	70e2                	ld	ra,56(sp)
    80001994:	7442                	ld	s0,48(sp)
    80001996:	74a2                	ld	s1,40(sp)
    80001998:	7902                	ld	s2,32(sp)
    8000199a:	69e2                	ld	s3,24(sp)
    8000199c:	6a42                	ld	s4,16(sp)
    8000199e:	6aa2                	ld	s5,8(sp)
    800019a0:	6b02                	ld	s6,0(sp)
    800019a2:	6121                	addi	sp,sp,64
    800019a4:	8082                	ret

00000000800019a6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a6:	1141                	addi	sp,sp,-16
    800019a8:	e422                	sd	s0,8(sp)
    800019aa:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ac:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ae:	2501                	sext.w	a0,a0
    800019b0:	6422                	ld	s0,8(sp)
    800019b2:	0141                	addi	sp,sp,16
    800019b4:	8082                	ret

00000000800019b6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e422                	sd	s0,8(sp)
    800019ba:	0800                	addi	s0,sp,16
    800019bc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019be:	2781                	sext.w	a5,a5
    800019c0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c2:	00010517          	auipc	a0,0x10
    800019c6:	90e50513          	addi	a0,a0,-1778 # 800112d0 <cpus>
    800019ca:	953e                	add	a0,a0,a5
    800019cc:	6422                	ld	s0,8(sp)
    800019ce:	0141                	addi	sp,sp,16
    800019d0:	8082                	ret

00000000800019d2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019d2:	1101                	addi	sp,sp,-32
    800019d4:	ec06                	sd	ra,24(sp)
    800019d6:	e822                	sd	s0,16(sp)
    800019d8:	e426                	sd	s1,8(sp)
    800019da:	1000                	addi	s0,sp,32
  push_off();
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	1f2080e7          	jalr	498(ra) # 80000bce <push_off>
    800019e4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e6:	2781                	sext.w	a5,a5
    800019e8:	079e                	slli	a5,a5,0x7
    800019ea:	00010717          	auipc	a4,0x10
    800019ee:	8b670713          	addi	a4,a4,-1866 # 800112a0 <pid_lock>
    800019f2:	97ba                	add	a5,a5,a4
    800019f4:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	278080e7          	jalr	632(ra) # 80000c6e <pop_off>
  return p;
}
    800019fe:	8526                	mv	a0,s1
    80001a00:	60e2                	ld	ra,24(sp)
    80001a02:	6442                	ld	s0,16(sp)
    80001a04:	64a2                	ld	s1,8(sp)
    80001a06:	6105                	addi	sp,sp,32
    80001a08:	8082                	ret

0000000080001a0a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e406                	sd	ra,8(sp)
    80001a0e:	e022                	sd	s0,0(sp)
    80001a10:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a12:	00000097          	auipc	ra,0x0
    80001a16:	fc0080e7          	jalr	-64(ra) # 800019d2 <myproc>
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	2b4080e7          	jalr	692(ra) # 80000cce <release>

  if (first) {
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	e5e7a783          	lw	a5,-418(a5) # 80008880 <first.1>
    80001a2a:	eb89                	bnez	a5,80001a3c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2c:	00001097          	auipc	ra,0x1
    80001a30:	cd2080e7          	jalr	-814(ra) # 800026fe <usertrapret>
}
    80001a34:	60a2                	ld	ra,8(sp)
    80001a36:	6402                	ld	s0,0(sp)
    80001a38:	0141                	addi	sp,sp,16
    80001a3a:	8082                	ret
    first = 0;
    80001a3c:	00007797          	auipc	a5,0x7
    80001a40:	e407a223          	sw	zero,-444(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001a44:	4505                	li	a0,1
    80001a46:	00002097          	auipc	ra,0x2
    80001a4a:	ad8080e7          	jalr	-1320(ra) # 8000351e <fsinit>
    80001a4e:	bff9                	j	80001a2c <forkret+0x22>

0000000080001a50 <allocpid>:
allocpid() {
    80001a50:	1101                	addi	sp,sp,-32
    80001a52:	ec06                	sd	ra,24(sp)
    80001a54:	e822                	sd	s0,16(sp)
    80001a56:	e426                	sd	s1,8(sp)
    80001a58:	e04a                	sd	s2,0(sp)
    80001a5a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a5c:	00010917          	auipc	s2,0x10
    80001a60:	84490913          	addi	s2,s2,-1980 # 800112a0 <pid_lock>
    80001a64:	854a                	mv	a0,s2
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	1b4080e7          	jalr	436(ra) # 80000c1a <acquire>
  pid = nextpid;
    80001a6e:	00007797          	auipc	a5,0x7
    80001a72:	e1678793          	addi	a5,a5,-490 # 80008884 <nextpid>
    80001a76:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a78:	0014871b          	addiw	a4,s1,1
    80001a7c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7e:	854a                	mv	a0,s2
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	24e080e7          	jalr	590(ra) # 80000cce <release>
}
    80001a88:	8526                	mv	a0,s1
    80001a8a:	60e2                	ld	ra,24(sp)
    80001a8c:	6442                	ld	s0,16(sp)
    80001a8e:	64a2                	ld	s1,8(sp)
    80001a90:	6902                	ld	s2,0(sp)
    80001a92:	6105                	addi	sp,sp,32
    80001a94:	8082                	ret

0000000080001a96 <proc_pagetable>:
{
    80001a96:	1101                	addi	sp,sp,-32
    80001a98:	ec06                	sd	ra,24(sp)
    80001a9a:	e822                	sd	s0,16(sp)
    80001a9c:	e426                	sd	s1,8(sp)
    80001a9e:	e04a                	sd	s2,0(sp)
    80001aa0:	1000                	addi	s0,sp,32
    80001aa2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa4:	00000097          	auipc	ra,0x0
    80001aa8:	8b6080e7          	jalr	-1866(ra) # 8000135a <uvmcreate>
    80001aac:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aae:	c121                	beqz	a0,80001aee <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ab0:	4729                	li	a4,10
    80001ab2:	00005697          	auipc	a3,0x5
    80001ab6:	54e68693          	addi	a3,a3,1358 # 80007000 <_trampoline>
    80001aba:	6605                	lui	a2,0x1
    80001abc:	040005b7          	lui	a1,0x4000
    80001ac0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ac2:	05b2                	slli	a1,a1,0xc
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	61a080e7          	jalr	1562(ra) # 800010de <mappages>
    80001acc:	02054863          	bltz	a0,80001afc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ad0:	4719                	li	a4,6
    80001ad2:	05893683          	ld	a3,88(s2)
    80001ad6:	6605                	lui	a2,0x1
    80001ad8:	020005b7          	lui	a1,0x2000
    80001adc:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ade:	05b6                	slli	a1,a1,0xd
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	5fc080e7          	jalr	1532(ra) # 800010de <mappages>
    80001aea:	02054163          	bltz	a0,80001b0c <proc_pagetable+0x76>
}
    80001aee:	8526                	mv	a0,s1
    80001af0:	60e2                	ld	ra,24(sp)
    80001af2:	6442                	ld	s0,16(sp)
    80001af4:	64a2                	ld	s1,8(sp)
    80001af6:	6902                	ld	s2,0(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a58080e7          	jalr	-1448(ra) # 80001558 <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	b7d5                	j	80001aee <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0c:	4681                	li	a3,0
    80001b0e:	4605                	li	a2,1
    80001b10:	040005b7          	lui	a1,0x4000
    80001b14:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b16:	05b2                	slli	a1,a1,0xc
    80001b18:	8526                	mv	a0,s1
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	78a080e7          	jalr	1930(ra) # 800012a4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b22:	4581                	li	a1,0
    80001b24:	8526                	mv	a0,s1
    80001b26:	00000097          	auipc	ra,0x0
    80001b2a:	a32080e7          	jalr	-1486(ra) # 80001558 <uvmfree>
    return 0;
    80001b2e:	4481                	li	s1,0
    80001b30:	bf7d                	j	80001aee <proc_pagetable+0x58>

0000000080001b32 <proc_freepagetable>:
{
    80001b32:	1101                	addi	sp,sp,-32
    80001b34:	ec06                	sd	ra,24(sp)
    80001b36:	e822                	sd	s0,16(sp)
    80001b38:	e426                	sd	s1,8(sp)
    80001b3a:	e04a                	sd	s2,0(sp)
    80001b3c:	1000                	addi	s0,sp,32
    80001b3e:	84aa                	mv	s1,a0
    80001b40:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b42:	4681                	li	a3,0
    80001b44:	4605                	li	a2,1
    80001b46:	040005b7          	lui	a1,0x4000
    80001b4a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b4c:	05b2                	slli	a1,a1,0xc
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	756080e7          	jalr	1878(ra) # 800012a4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b56:	4681                	li	a3,0
    80001b58:	4605                	li	a2,1
    80001b5a:	020005b7          	lui	a1,0x2000
    80001b5e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b60:	05b6                	slli	a1,a1,0xd
    80001b62:	8526                	mv	a0,s1
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	740080e7          	jalr	1856(ra) # 800012a4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6c:	85ca                	mv	a1,s2
    80001b6e:	8526                	mv	a0,s1
    80001b70:	00000097          	auipc	ra,0x0
    80001b74:	9e8080e7          	jalr	-1560(ra) # 80001558 <uvmfree>
}
    80001b78:	60e2                	ld	ra,24(sp)
    80001b7a:	6442                	ld	s0,16(sp)
    80001b7c:	64a2                	ld	s1,8(sp)
    80001b7e:	6902                	ld	s2,0(sp)
    80001b80:	6105                	addi	sp,sp,32
    80001b82:	8082                	ret

0000000080001b84 <freeproc>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	1000                	addi	s0,sp,32
    80001b8e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b90:	6d28                	ld	a0,88(a0)
    80001b92:	c509                	beqz	a0,80001b9c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	e4e080e7          	jalr	-434(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b9c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ba0:	68a8                	ld	a0,80(s1)
    80001ba2:	c511                	beqz	a0,80001bae <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba4:	64ac                	ld	a1,72(s1)
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	f8c080e7          	jalr	-116(ra) # 80001b32 <proc_freepagetable>
  p->pagetable = 0;
    80001bae:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bba:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bbe:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bca:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bce:	0004ac23          	sw	zero,24(s1)
}
    80001bd2:	60e2                	ld	ra,24(sp)
    80001bd4:	6442                	ld	s0,16(sp)
    80001bd6:	64a2                	ld	s1,8(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret

0000000080001bdc <allocproc>:
{
    80001bdc:	1101                	addi	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	e04a                	sd	s2,0(sp)
    80001be6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be8:	00010497          	auipc	s1,0x10
    80001bec:	ae848493          	addi	s1,s1,-1304 # 800116d0 <proc>
    80001bf0:	00015917          	auipc	s2,0x15
    80001bf4:	4e090913          	addi	s2,s2,1248 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	020080e7          	jalr	32(ra) # 80000c1a <acquire>
    if(p->state == UNUSED) {
    80001c02:	4c9c                	lw	a5,24(s1)
    80001c04:	cf81                	beqz	a5,80001c1c <allocproc+0x40>
      release(&p->lock);
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	0c6080e7          	jalr	198(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c10:	16848493          	addi	s1,s1,360
    80001c14:	ff2492e3          	bne	s1,s2,80001bf8 <allocproc+0x1c>
  return 0;
    80001c18:	4481                	li	s1,0
    80001c1a:	a889                	j	80001c6c <allocproc+0x90>
  p->pid = allocpid();
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	e34080e7          	jalr	-460(ra) # 80001a50 <allocpid>
    80001c24:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c26:	4785                	li	a5,1
    80001c28:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	eb6080e7          	jalr	-330(ra) # 80000ae0 <kalloc>
    80001c32:	892a                	mv	s2,a0
    80001c34:	eca8                	sd	a0,88(s1)
    80001c36:	c131                	beqz	a0,80001c7a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	e5c080e7          	jalr	-420(ra) # 80001a96 <proc_pagetable>
    80001c42:	892a                	mv	s2,a0
    80001c44:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c46:	c531                	beqz	a0,80001c92 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c48:	07000613          	li	a2,112
    80001c4c:	4581                	li	a1,0
    80001c4e:	06048513          	addi	a0,s1,96
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	0c4080e7          	jalr	196(ra) # 80000d16 <memset>
  p->context.ra = (uint64)forkret;
    80001c5a:	00000797          	auipc	a5,0x0
    80001c5e:	db078793          	addi	a5,a5,-592 # 80001a0a <forkret>
    80001c62:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c64:	60bc                	ld	a5,64(s1)
    80001c66:	6705                	lui	a4,0x1
    80001c68:	97ba                	add	a5,a5,a4
    80001c6a:	f4bc                	sd	a5,104(s1)
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
    freeproc(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	f08080e7          	jalr	-248(ra) # 80001b84 <freeproc>
    release(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	048080e7          	jalr	72(ra) # 80000cce <release>
    return 0;
    80001c8e:	84ca                	mv	s1,s2
    80001c90:	bff1                	j	80001c6c <allocproc+0x90>
    freeproc(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	ef0080e7          	jalr	-272(ra) # 80001b84 <freeproc>
    release(&p->lock);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	030080e7          	jalr	48(ra) # 80000cce <release>
    return 0;
    80001ca6:	84ca                	mv	s1,s2
    80001ca8:	b7d1                	j	80001c6c <allocproc+0x90>

0000000080001caa <userinit>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	f28080e7          	jalr	-216(ra) # 80001bdc <allocproc>
    80001cbc:	84aa                	mv	s1,a0
  initproc = p;
    80001cbe:	00007797          	auipc	a5,0x7
    80001cc2:	36a7b523          	sd	a0,874(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc6:	03400613          	li	a2,52
    80001cca:	00007597          	auipc	a1,0x7
    80001cce:	bc658593          	addi	a1,a1,-1082 # 80008890 <initcode>
    80001cd2:	6928                	ld	a0,80(a0)
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	6b4080e7          	jalr	1716(ra) # 80001388 <uvminit>
  p->sz = PGSIZE;
    80001cdc:	6785                	lui	a5,0x1
    80001cde:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cea:	4641                	li	a2,16
    80001cec:	00006597          	auipc	a1,0x6
    80001cf0:	4fc58593          	addi	a1,a1,1276 # 800081e8 <digits+0x1a8>
    80001cf4:	15848513          	addi	a0,s1,344
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	168080e7          	jalr	360(ra) # 80000e60 <safestrcpy>
  p->cwd = namei("/");
    80001d00:	00006517          	auipc	a0,0x6
    80001d04:	4f850513          	addi	a0,a0,1272 # 800081f8 <digits+0x1b8>
    80001d08:	00002097          	auipc	ra,0x2
    80001d0c:	24c080e7          	jalr	588(ra) # 80003f54 <namei>
    80001d10:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d14:	478d                	li	a5,3
    80001d16:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	fb4080e7          	jalr	-76(ra) # 80000cce <release>
}
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret

0000000080001d2c <growproc>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	e04a                	sd	s2,0(sp)
    80001d36:	1000                	addi	s0,sp,32
    80001d38:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	c98080e7          	jalr	-872(ra) # 800019d2 <myproc>
    80001d42:	892a                	mv	s2,a0
  sz = p->sz;
    80001d44:	652c                	ld	a1,72(a0)
    80001d46:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d4a:	00904f63          	bgtz	s1,80001d68 <growproc+0x3c>
  } else if(n < 0){
    80001d4e:	0204cd63          	bltz	s1,80001d88 <growproc+0x5c>
  p->sz = sz;
    80001d52:	1782                	slli	a5,a5,0x20
    80001d54:	9381                	srli	a5,a5,0x20
    80001d56:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d5a:	4501                	li	a0,0
}
    80001d5c:	60e2                	ld	ra,24(sp)
    80001d5e:	6442                	ld	s0,16(sp)
    80001d60:	64a2                	ld	s1,8(sp)
    80001d62:	6902                	ld	s2,0(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d68:	00f4863b          	addw	a2,s1,a5
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	6cc080e7          	jalr	1740(ra) # 80001442 <uvmalloc>
    80001d7e:	0005079b          	sext.w	a5,a0
    80001d82:	fbe1                	bnez	a5,80001d52 <growproc+0x26>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bfd9                	j	80001d5c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	00f4863b          	addw	a2,s1,a5
    80001d8c:	1602                	slli	a2,a2,0x20
    80001d8e:	9201                	srli	a2,a2,0x20
    80001d90:	1582                	slli	a1,a1,0x20
    80001d92:	9181                	srli	a1,a1,0x20
    80001d94:	6928                	ld	a0,80(a0)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	664080e7          	jalr	1636(ra) # 800013fa <uvmdealloc>
    80001d9e:	0005079b          	sext.w	a5,a0
    80001da2:	bf45                	j	80001d52 <growproc+0x26>

0000000080001da4 <fork>:
{
    80001da4:	7139                	addi	sp,sp,-64
    80001da6:	fc06                	sd	ra,56(sp)
    80001da8:	f822                	sd	s0,48(sp)
    80001daa:	f426                	sd	s1,40(sp)
    80001dac:	f04a                	sd	s2,32(sp)
    80001dae:	ec4e                	sd	s3,24(sp)
    80001db0:	e852                	sd	s4,16(sp)
    80001db2:	e456                	sd	s5,8(sp)
    80001db4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	c1c080e7          	jalr	-996(ra) # 800019d2 <myproc>
    80001dbe:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	e1c080e7          	jalr	-484(ra) # 80001bdc <allocproc>
    80001dc8:	10050c63          	beqz	a0,80001ee0 <fork+0x13c>
    80001dcc:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dce:	048ab603          	ld	a2,72(s5)
    80001dd2:	692c                	ld	a1,80(a0)
    80001dd4:	050ab503          	ld	a0,80(s5)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	7ba080e7          	jalr	1978(ra) # 80001592 <uvmcopy>
    80001de0:	04054863          	bltz	a0,80001e30 <fork+0x8c>
  np->sz = p->sz;
    80001de4:	048ab783          	ld	a5,72(s5)
    80001de8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dec:	058ab683          	ld	a3,88(s5)
    80001df0:	87b6                	mv	a5,a3
    80001df2:	058a3703          	ld	a4,88(s4)
    80001df6:	12068693          	addi	a3,a3,288
    80001dfa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfe:	6788                	ld	a0,8(a5)
    80001e00:	6b8c                	ld	a1,16(a5)
    80001e02:	6f90                	ld	a2,24(a5)
    80001e04:	01073023          	sd	a6,0(a4)
    80001e08:	e708                	sd	a0,8(a4)
    80001e0a:	eb0c                	sd	a1,16(a4)
    80001e0c:	ef10                	sd	a2,24(a4)
    80001e0e:	02078793          	addi	a5,a5,32
    80001e12:	02070713          	addi	a4,a4,32
    80001e16:	fed792e3          	bne	a5,a3,80001dfa <fork+0x56>
  np->trapframe->a0 = 0;
    80001e1a:	058a3783          	ld	a5,88(s4)
    80001e1e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e22:	0d0a8493          	addi	s1,s5,208
    80001e26:	0d0a0913          	addi	s2,s4,208
    80001e2a:	150a8993          	addi	s3,s5,336
    80001e2e:	a00d                	j	80001e50 <fork+0xac>
    freeproc(np);
    80001e30:	8552                	mv	a0,s4
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	d52080e7          	jalr	-686(ra) # 80001b84 <freeproc>
    release(&np->lock);
    80001e3a:	8552                	mv	a0,s4
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e92080e7          	jalr	-366(ra) # 80000cce <release>
    return -1;
    80001e44:	597d                	li	s2,-1
    80001e46:	a059                	j	80001ecc <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e48:	04a1                	addi	s1,s1,8
    80001e4a:	0921                	addi	s2,s2,8
    80001e4c:	01348b63          	beq	s1,s3,80001e62 <fork+0xbe>
    if(p->ofile[i])
    80001e50:	6088                	ld	a0,0(s1)
    80001e52:	d97d                	beqz	a0,80001e48 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e54:	00002097          	auipc	ra,0x2
    80001e58:	796080e7          	jalr	1942(ra) # 800045ea <filedup>
    80001e5c:	00a93023          	sd	a0,0(s2)
    80001e60:	b7e5                	j	80001e48 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e62:	150ab503          	ld	a0,336(s5)
    80001e66:	00002097          	auipc	ra,0x2
    80001e6a:	8f4080e7          	jalr	-1804(ra) # 8000375a <idup>
    80001e6e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e72:	4641                	li	a2,16
    80001e74:	158a8593          	addi	a1,s5,344
    80001e78:	158a0513          	addi	a0,s4,344
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	fe4080e7          	jalr	-28(ra) # 80000e60 <safestrcpy>
  pid = np->pid;
    80001e84:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e88:	8552                	mv	a0,s4
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e44080e7          	jalr	-444(ra) # 80000cce <release>
  acquire(&wait_lock);
    80001e92:	0000f497          	auipc	s1,0xf
    80001e96:	42648493          	addi	s1,s1,1062 # 800112b8 <wait_lock>
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	d7e080e7          	jalr	-642(ra) # 80000c1a <acquire>
  np->parent = p;
    80001ea4:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	e24080e7          	jalr	-476(ra) # 80000cce <release>
  acquire(&np->lock);
    80001eb2:	8552                	mv	a0,s4
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	d66080e7          	jalr	-666(ra) # 80000c1a <acquire>
  np->state = RUNNABLE;
    80001ebc:	478d                	li	a5,3
    80001ebe:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ec2:	8552                	mv	a0,s4
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	e0a080e7          	jalr	-502(ra) # 80000cce <release>
}
    80001ecc:	854a                	mv	a0,s2
    80001ece:	70e2                	ld	ra,56(sp)
    80001ed0:	7442                	ld	s0,48(sp)
    80001ed2:	74a2                	ld	s1,40(sp)
    80001ed4:	7902                	ld	s2,32(sp)
    80001ed6:	69e2                	ld	s3,24(sp)
    80001ed8:	6a42                	ld	s4,16(sp)
    80001eda:	6aa2                	ld	s5,8(sp)
    80001edc:	6121                	addi	sp,sp,64
    80001ede:	8082                	ret
    return -1;
    80001ee0:	597d                	li	s2,-1
    80001ee2:	b7ed                	j	80001ecc <fork+0x128>

0000000080001ee4 <scheduler>:
{
    80001ee4:	7139                	addi	sp,sp,-64
    80001ee6:	fc06                	sd	ra,56(sp)
    80001ee8:	f822                	sd	s0,48(sp)
    80001eea:	f426                	sd	s1,40(sp)
    80001eec:	f04a                	sd	s2,32(sp)
    80001eee:	ec4e                	sd	s3,24(sp)
    80001ef0:	e852                	sd	s4,16(sp)
    80001ef2:	e456                	sd	s5,8(sp)
    80001ef4:	e05a                	sd	s6,0(sp)
    80001ef6:	0080                	addi	s0,sp,64
    80001ef8:	8792                	mv	a5,tp
  int id = r_tp();
    80001efa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efc:	00779a93          	slli	s5,a5,0x7
    80001f00:	0000f717          	auipc	a4,0xf
    80001f04:	3a070713          	addi	a4,a4,928 # 800112a0 <pid_lock>
    80001f08:	9756                	add	a4,a4,s5
    80001f0a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f0e:	0000f717          	auipc	a4,0xf
    80001f12:	3ca70713          	addi	a4,a4,970 # 800112d8 <cpus+0x8>
    80001f16:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f18:	498d                	li	s3,3
        p->state = RUNNING;
    80001f1a:	4b11                	li	s6,4
        c->proc = p;
    80001f1c:	079e                	slli	a5,a5,0x7
    80001f1e:	0000fa17          	auipc	s4,0xf
    80001f22:	382a0a13          	addi	s4,s4,898 # 800112a0 <pid_lock>
    80001f26:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f28:	00015917          	auipc	s2,0x15
    80001f2c:	1a890913          	addi	s2,s2,424 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f38:	10079073          	csrw	sstatus,a5
    80001f3c:	0000f497          	auipc	s1,0xf
    80001f40:	79448493          	addi	s1,s1,1940 # 800116d0 <proc>
    80001f44:	a811                	j	80001f58 <scheduler+0x74>
      release(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	d86080e7          	jalr	-634(ra) # 80000cce <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f50:	16848493          	addi	s1,s1,360
    80001f54:	fd248ee3          	beq	s1,s2,80001f30 <scheduler+0x4c>
      acquire(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	cc0080e7          	jalr	-832(ra) # 80000c1a <acquire>
      if(p->state == RUNNABLE) {
    80001f62:	4c9c                	lw	a5,24(s1)
    80001f64:	ff3791e3          	bne	a5,s3,80001f46 <scheduler+0x62>
        p->state = RUNNING;
    80001f68:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f6c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f70:	06048593          	addi	a1,s1,96
    80001f74:	8556                	mv	a0,s5
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	6de080e7          	jalr	1758(ra) # 80002654 <swtch>
        c->proc = 0;
    80001f7e:	020a3823          	sd	zero,48(s4)
    80001f82:	b7d1                	j	80001f46 <scheduler+0x62>

0000000080001f84 <sched>:
{
    80001f84:	7179                	addi	sp,sp,-48
    80001f86:	f406                	sd	ra,40(sp)
    80001f88:	f022                	sd	s0,32(sp)
    80001f8a:	ec26                	sd	s1,24(sp)
    80001f8c:	e84a                	sd	s2,16(sp)
    80001f8e:	e44e                	sd	s3,8(sp)
    80001f90:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f92:	00000097          	auipc	ra,0x0
    80001f96:	a40080e7          	jalr	-1472(ra) # 800019d2 <myproc>
    80001f9a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	c04080e7          	jalr	-1020(ra) # 80000ba0 <holding>
    80001fa4:	c93d                	beqz	a0,8000201a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fa8:	2781                	sext.w	a5,a5
    80001faa:	079e                	slli	a5,a5,0x7
    80001fac:	0000f717          	auipc	a4,0xf
    80001fb0:	2f470713          	addi	a4,a4,756 # 800112a0 <pid_lock>
    80001fb4:	97ba                	add	a5,a5,a4
    80001fb6:	0a87a703          	lw	a4,168(a5)
    80001fba:	4785                	li	a5,1
    80001fbc:	06f71763          	bne	a4,a5,8000202a <sched+0xa6>
  if(p->state == RUNNING)
    80001fc0:	4c98                	lw	a4,24(s1)
    80001fc2:	4791                	li	a5,4
    80001fc4:	06f70b63          	beq	a4,a5,8000203a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fcc:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fce:	efb5                	bnez	a5,8000204a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fd0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fd2:	0000f917          	auipc	s2,0xf
    80001fd6:	2ce90913          	addi	s2,s2,718 # 800112a0 <pid_lock>
    80001fda:	2781                	sext.w	a5,a5
    80001fdc:	079e                	slli	a5,a5,0x7
    80001fde:	97ca                	add	a5,a5,s2
    80001fe0:	0ac7a983          	lw	s3,172(a5)
    80001fe4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fe6:	2781                	sext.w	a5,a5
    80001fe8:	079e                	slli	a5,a5,0x7
    80001fea:	0000f597          	auipc	a1,0xf
    80001fee:	2ee58593          	addi	a1,a1,750 # 800112d8 <cpus+0x8>
    80001ff2:	95be                	add	a1,a1,a5
    80001ff4:	06048513          	addi	a0,s1,96
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	65c080e7          	jalr	1628(ra) # 80002654 <swtch>
    80002000:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002002:	2781                	sext.w	a5,a5
    80002004:	079e                	slli	a5,a5,0x7
    80002006:	993e                	add	s2,s2,a5
    80002008:	0b392623          	sw	s3,172(s2)
}
    8000200c:	70a2                	ld	ra,40(sp)
    8000200e:	7402                	ld	s0,32(sp)
    80002010:	64e2                	ld	s1,24(sp)
    80002012:	6942                	ld	s2,16(sp)
    80002014:	69a2                	ld	s3,8(sp)
    80002016:	6145                	addi	sp,sp,48
    80002018:	8082                	ret
    panic("sched p->lock");
    8000201a:	00006517          	auipc	a0,0x6
    8000201e:	1e650513          	addi	a0,a0,486 # 80008200 <digits+0x1c0>
    80002022:	ffffe097          	auipc	ra,0xffffe
    80002026:	518080e7          	jalr	1304(ra) # 8000053a <panic>
    panic("sched locks");
    8000202a:	00006517          	auipc	a0,0x6
    8000202e:	1e650513          	addi	a0,a0,486 # 80008210 <digits+0x1d0>
    80002032:	ffffe097          	auipc	ra,0xffffe
    80002036:	508080e7          	jalr	1288(ra) # 8000053a <panic>
    panic("sched running");
    8000203a:	00006517          	auipc	a0,0x6
    8000203e:	1e650513          	addi	a0,a0,486 # 80008220 <digits+0x1e0>
    80002042:	ffffe097          	auipc	ra,0xffffe
    80002046:	4f8080e7          	jalr	1272(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000204a:	00006517          	auipc	a0,0x6
    8000204e:	1e650513          	addi	a0,a0,486 # 80008230 <digits+0x1f0>
    80002052:	ffffe097          	auipc	ra,0xffffe
    80002056:	4e8080e7          	jalr	1256(ra) # 8000053a <panic>

000000008000205a <yield>:
{
    8000205a:	1101                	addi	sp,sp,-32
    8000205c:	ec06                	sd	ra,24(sp)
    8000205e:	e822                	sd	s0,16(sp)
    80002060:	e426                	sd	s1,8(sp)
    80002062:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002064:	00000097          	auipc	ra,0x0
    80002068:	96e080e7          	jalr	-1682(ra) # 800019d2 <myproc>
    8000206c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	bac080e7          	jalr	-1108(ra) # 80000c1a <acquire>
  p->state = RUNNABLE;
    80002076:	478d                	li	a5,3
    80002078:	cc9c                	sw	a5,24(s1)
  sched();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	f0a080e7          	jalr	-246(ra) # 80001f84 <sched>
  release(&p->lock);
    80002082:	8526                	mv	a0,s1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	c4a080e7          	jalr	-950(ra) # 80000cce <release>
}
    8000208c:	60e2                	ld	ra,24(sp)
    8000208e:	6442                	ld	s0,16(sp)
    80002090:	64a2                	ld	s1,8(sp)
    80002092:	6105                	addi	sp,sp,32
    80002094:	8082                	ret

0000000080002096 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002096:	7179                	addi	sp,sp,-48
    80002098:	f406                	sd	ra,40(sp)
    8000209a:	f022                	sd	s0,32(sp)
    8000209c:	ec26                	sd	s1,24(sp)
    8000209e:	e84a                	sd	s2,16(sp)
    800020a0:	e44e                	sd	s3,8(sp)
    800020a2:	1800                	addi	s0,sp,48
    800020a4:	89aa                	mv	s3,a0
    800020a6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020a8:	00000097          	auipc	ra,0x0
    800020ac:	92a080e7          	jalr	-1750(ra) # 800019d2 <myproc>
    800020b0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	b68080e7          	jalr	-1176(ra) # 80000c1a <acquire>
  release(lk);
    800020ba:	854a                	mv	a0,s2
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	c12080e7          	jalr	-1006(ra) # 80000cce <release>

  // Go to sleep.
  p->chan = chan;
    800020c4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020c8:	4789                	li	a5,2
    800020ca:	cc9c                	sw	a5,24(s1)

  sched();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	eb8080e7          	jalr	-328(ra) # 80001f84 <sched>

  // Tidy up.
  p->chan = 0;
    800020d4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	bf4080e7          	jalr	-1036(ra) # 80000cce <release>
  acquire(lk);
    800020e2:	854a                	mv	a0,s2
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	b36080e7          	jalr	-1226(ra) # 80000c1a <acquire>
}
    800020ec:	70a2                	ld	ra,40(sp)
    800020ee:	7402                	ld	s0,32(sp)
    800020f0:	64e2                	ld	s1,24(sp)
    800020f2:	6942                	ld	s2,16(sp)
    800020f4:	69a2                	ld	s3,8(sp)
    800020f6:	6145                	addi	sp,sp,48
    800020f8:	8082                	ret

00000000800020fa <wait>:
{
    800020fa:	715d                	addi	sp,sp,-80
    800020fc:	e486                	sd	ra,72(sp)
    800020fe:	e0a2                	sd	s0,64(sp)
    80002100:	fc26                	sd	s1,56(sp)
    80002102:	f84a                	sd	s2,48(sp)
    80002104:	f44e                	sd	s3,40(sp)
    80002106:	f052                	sd	s4,32(sp)
    80002108:	ec56                	sd	s5,24(sp)
    8000210a:	e85a                	sd	s6,16(sp)
    8000210c:	e45e                	sd	s7,8(sp)
    8000210e:	e062                	sd	s8,0(sp)
    80002110:	0880                	addi	s0,sp,80
    80002112:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002114:	00000097          	auipc	ra,0x0
    80002118:	8be080e7          	jalr	-1858(ra) # 800019d2 <myproc>
    8000211c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000211e:	0000f517          	auipc	a0,0xf
    80002122:	19a50513          	addi	a0,a0,410 # 800112b8 <wait_lock>
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	af4080e7          	jalr	-1292(ra) # 80000c1a <acquire>
    havekids = 0;
    8000212e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002130:	4a15                	li	s4,5
        havekids = 1;
    80002132:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002134:	00015997          	auipc	s3,0x15
    80002138:	f9c98993          	addi	s3,s3,-100 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000213c:	0000fc17          	auipc	s8,0xf
    80002140:	17cc0c13          	addi	s8,s8,380 # 800112b8 <wait_lock>
    havekids = 0;
    80002144:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002146:	0000f497          	auipc	s1,0xf
    8000214a:	58a48493          	addi	s1,s1,1418 # 800116d0 <proc>
    8000214e:	a0bd                	j	800021bc <wait+0xc2>
          pid = np->pid;
    80002150:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002154:	000b0e63          	beqz	s6,80002170 <wait+0x76>
    80002158:	4691                	li	a3,4
    8000215a:	02c48613          	addi	a2,s1,44
    8000215e:	85da                	mv	a1,s6
    80002160:	05093503          	ld	a0,80(s2)
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	532080e7          	jalr	1330(ra) # 80001696 <copyout>
    8000216c:	02054563          	bltz	a0,80002196 <wait+0x9c>
          freeproc(np);
    80002170:	8526                	mv	a0,s1
    80002172:	00000097          	auipc	ra,0x0
    80002176:	a12080e7          	jalr	-1518(ra) # 80001b84 <freeproc>
          release(&np->lock);
    8000217a:	8526                	mv	a0,s1
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b52080e7          	jalr	-1198(ra) # 80000cce <release>
          release(&wait_lock);
    80002184:	0000f517          	auipc	a0,0xf
    80002188:	13450513          	addi	a0,a0,308 # 800112b8 <wait_lock>
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b42080e7          	jalr	-1214(ra) # 80000cce <release>
          return pid;
    80002194:	a09d                	j	800021fa <wait+0x100>
            release(&np->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	b36080e7          	jalr	-1226(ra) # 80000cce <release>
            release(&wait_lock);
    800021a0:	0000f517          	auipc	a0,0xf
    800021a4:	11850513          	addi	a0,a0,280 # 800112b8 <wait_lock>
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	b26080e7          	jalr	-1242(ra) # 80000cce <release>
            return -1;
    800021b0:	59fd                	li	s3,-1
    800021b2:	a0a1                	j	800021fa <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021b4:	16848493          	addi	s1,s1,360
    800021b8:	03348463          	beq	s1,s3,800021e0 <wait+0xe6>
      if(np->parent == p){
    800021bc:	7c9c                	ld	a5,56(s1)
    800021be:	ff279be3          	bne	a5,s2,800021b4 <wait+0xba>
        acquire(&np->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	a56080e7          	jalr	-1450(ra) # 80000c1a <acquire>
        if(np->state == ZOMBIE){
    800021cc:	4c9c                	lw	a5,24(s1)
    800021ce:	f94781e3          	beq	a5,s4,80002150 <wait+0x56>
        release(&np->lock);
    800021d2:	8526                	mv	a0,s1
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	afa080e7          	jalr	-1286(ra) # 80000cce <release>
        havekids = 1;
    800021dc:	8756                	mv	a4,s5
    800021de:	bfd9                	j	800021b4 <wait+0xba>
    if(!havekids || p->killed){
    800021e0:	c701                	beqz	a4,800021e8 <wait+0xee>
    800021e2:	02892783          	lw	a5,40(s2)
    800021e6:	c79d                	beqz	a5,80002214 <wait+0x11a>
      release(&wait_lock);
    800021e8:	0000f517          	auipc	a0,0xf
    800021ec:	0d050513          	addi	a0,a0,208 # 800112b8 <wait_lock>
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	ade080e7          	jalr	-1314(ra) # 80000cce <release>
      return -1;
    800021f8:	59fd                	li	s3,-1
}
    800021fa:	854e                	mv	a0,s3
    800021fc:	60a6                	ld	ra,72(sp)
    800021fe:	6406                	ld	s0,64(sp)
    80002200:	74e2                	ld	s1,56(sp)
    80002202:	7942                	ld	s2,48(sp)
    80002204:	79a2                	ld	s3,40(sp)
    80002206:	7a02                	ld	s4,32(sp)
    80002208:	6ae2                	ld	s5,24(sp)
    8000220a:	6b42                	ld	s6,16(sp)
    8000220c:	6ba2                	ld	s7,8(sp)
    8000220e:	6c02                	ld	s8,0(sp)
    80002210:	6161                	addi	sp,sp,80
    80002212:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002214:	85e2                	mv	a1,s8
    80002216:	854a                	mv	a0,s2
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	e7e080e7          	jalr	-386(ra) # 80002096 <sleep>
    havekids = 0;
    80002220:	b715                	j	80002144 <wait+0x4a>

0000000080002222 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002222:	7139                	addi	sp,sp,-64
    80002224:	fc06                	sd	ra,56(sp)
    80002226:	f822                	sd	s0,48(sp)
    80002228:	f426                	sd	s1,40(sp)
    8000222a:	f04a                	sd	s2,32(sp)
    8000222c:	ec4e                	sd	s3,24(sp)
    8000222e:	e852                	sd	s4,16(sp)
    80002230:	e456                	sd	s5,8(sp)
    80002232:	0080                	addi	s0,sp,64
    80002234:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002236:	0000f497          	auipc	s1,0xf
    8000223a:	49a48493          	addi	s1,s1,1178 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000223e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002240:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002242:	00015917          	auipc	s2,0x15
    80002246:	e8e90913          	addi	s2,s2,-370 # 800170d0 <tickslock>
    8000224a:	a811                	j	8000225e <wakeup+0x3c>
      }
      release(&p->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	a80080e7          	jalr	-1408(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002256:	16848493          	addi	s1,s1,360
    8000225a:	03248663          	beq	s1,s2,80002286 <wakeup+0x64>
    if(p != myproc()){
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	774080e7          	jalr	1908(ra) # 800019d2 <myproc>
    80002266:	fea488e3          	beq	s1,a0,80002256 <wakeup+0x34>
      acquire(&p->lock);
    8000226a:	8526                	mv	a0,s1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	9ae080e7          	jalr	-1618(ra) # 80000c1a <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002274:	4c9c                	lw	a5,24(s1)
    80002276:	fd379be3          	bne	a5,s3,8000224c <wakeup+0x2a>
    8000227a:	709c                	ld	a5,32(s1)
    8000227c:	fd4798e3          	bne	a5,s4,8000224c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002280:	0154ac23          	sw	s5,24(s1)
    80002284:	b7e1                	j	8000224c <wakeup+0x2a>
    }
  }
}
    80002286:	70e2                	ld	ra,56(sp)
    80002288:	7442                	ld	s0,48(sp)
    8000228a:	74a2                	ld	s1,40(sp)
    8000228c:	7902                	ld	s2,32(sp)
    8000228e:	69e2                	ld	s3,24(sp)
    80002290:	6a42                	ld	s4,16(sp)
    80002292:	6aa2                	ld	s5,8(sp)
    80002294:	6121                	addi	sp,sp,64
    80002296:	8082                	ret

0000000080002298 <reparent>:
{
    80002298:	7179                	addi	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	e052                	sd	s4,0(sp)
    800022a6:	1800                	addi	s0,sp,48
    800022a8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022aa:	0000f497          	auipc	s1,0xf
    800022ae:	42648493          	addi	s1,s1,1062 # 800116d0 <proc>
      pp->parent = initproc;
    800022b2:	00007a17          	auipc	s4,0x7
    800022b6:	d76a0a13          	addi	s4,s4,-650 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022ba:	00015997          	auipc	s3,0x15
    800022be:	e1698993          	addi	s3,s3,-490 # 800170d0 <tickslock>
    800022c2:	a029                	j	800022cc <reparent+0x34>
    800022c4:	16848493          	addi	s1,s1,360
    800022c8:	01348d63          	beq	s1,s3,800022e2 <reparent+0x4a>
    if(pp->parent == p){
    800022cc:	7c9c                	ld	a5,56(s1)
    800022ce:	ff279be3          	bne	a5,s2,800022c4 <reparent+0x2c>
      pp->parent = initproc;
    800022d2:	000a3503          	ld	a0,0(s4)
    800022d6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	f4a080e7          	jalr	-182(ra) # 80002222 <wakeup>
    800022e0:	b7d5                	j	800022c4 <reparent+0x2c>
}
    800022e2:	70a2                	ld	ra,40(sp)
    800022e4:	7402                	ld	s0,32(sp)
    800022e6:	64e2                	ld	s1,24(sp)
    800022e8:	6942                	ld	s2,16(sp)
    800022ea:	69a2                	ld	s3,8(sp)
    800022ec:	6a02                	ld	s4,0(sp)
    800022ee:	6145                	addi	sp,sp,48
    800022f0:	8082                	ret

00000000800022f2 <exit>:
{
    800022f2:	7179                	addi	sp,sp,-48
    800022f4:	f406                	sd	ra,40(sp)
    800022f6:	f022                	sd	s0,32(sp)
    800022f8:	ec26                	sd	s1,24(sp)
    800022fa:	e84a                	sd	s2,16(sp)
    800022fc:	e44e                	sd	s3,8(sp)
    800022fe:	e052                	sd	s4,0(sp)
    80002300:	1800                	addi	s0,sp,48
    80002302:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	6ce080e7          	jalr	1742(ra) # 800019d2 <myproc>
    8000230c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000230e:	00007797          	auipc	a5,0x7
    80002312:	d1a7b783          	ld	a5,-742(a5) # 80009028 <initproc>
    80002316:	0d050493          	addi	s1,a0,208
    8000231a:	15050913          	addi	s2,a0,336
    8000231e:	02a79363          	bne	a5,a0,80002344 <exit+0x52>
    panic("init exiting");
    80002322:	00006517          	auipc	a0,0x6
    80002326:	f2650513          	addi	a0,a0,-218 # 80008248 <digits+0x208>
    8000232a:	ffffe097          	auipc	ra,0xffffe
    8000232e:	210080e7          	jalr	528(ra) # 8000053a <panic>
      fileclose(f);
    80002332:	00002097          	auipc	ra,0x2
    80002336:	30a080e7          	jalr	778(ra) # 8000463c <fileclose>
      p->ofile[fd] = 0;
    8000233a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000233e:	04a1                	addi	s1,s1,8
    80002340:	01248563          	beq	s1,s2,8000234a <exit+0x58>
    if(p->ofile[fd]){
    80002344:	6088                	ld	a0,0(s1)
    80002346:	f575                	bnez	a0,80002332 <exit+0x40>
    80002348:	bfdd                	j	8000233e <exit+0x4c>
  begin_op();
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	e2a080e7          	jalr	-470(ra) # 80004174 <begin_op>
  iput(p->cwd);
    80002352:	1509b503          	ld	a0,336(s3)
    80002356:	00001097          	auipc	ra,0x1
    8000235a:	5fc080e7          	jalr	1532(ra) # 80003952 <iput>
  end_op();
    8000235e:	00002097          	auipc	ra,0x2
    80002362:	e94080e7          	jalr	-364(ra) # 800041f2 <end_op>
  p->cwd = 0;
    80002366:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000236a:	0000f497          	auipc	s1,0xf
    8000236e:	f4e48493          	addi	s1,s1,-178 # 800112b8 <wait_lock>
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	8a6080e7          	jalr	-1882(ra) # 80000c1a <acquire>
  reparent(p);
    8000237c:	854e                	mv	a0,s3
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	f1a080e7          	jalr	-230(ra) # 80002298 <reparent>
  wakeup(p->parent);
    80002386:	0389b503          	ld	a0,56(s3)
    8000238a:	00000097          	auipc	ra,0x0
    8000238e:	e98080e7          	jalr	-360(ra) # 80002222 <wakeup>
  acquire(&p->lock);
    80002392:	854e                	mv	a0,s3
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	886080e7          	jalr	-1914(ra) # 80000c1a <acquire>
  p->xstate = status;
    8000239c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023a0:	4795                	li	a5,5
    800023a2:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	926080e7          	jalr	-1754(ra) # 80000cce <release>
  sched();
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	bd4080e7          	jalr	-1068(ra) # 80001f84 <sched>
  panic("zombie exit");
    800023b8:	00006517          	auipc	a0,0x6
    800023bc:	ea050513          	addi	a0,a0,-352 # 80008258 <digits+0x218>
    800023c0:	ffffe097          	auipc	ra,0xffffe
    800023c4:	17a080e7          	jalr	378(ra) # 8000053a <panic>

00000000800023c8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023c8:	7179                	addi	sp,sp,-48
    800023ca:	f406                	sd	ra,40(sp)
    800023cc:	f022                	sd	s0,32(sp)
    800023ce:	ec26                	sd	s1,24(sp)
    800023d0:	e84a                	sd	s2,16(sp)
    800023d2:	e44e                	sd	s3,8(sp)
    800023d4:	1800                	addi	s0,sp,48
    800023d6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023d8:	0000f497          	auipc	s1,0xf
    800023dc:	2f848493          	addi	s1,s1,760 # 800116d0 <proc>
    800023e0:	00015997          	auipc	s3,0x15
    800023e4:	cf098993          	addi	s3,s3,-784 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	830080e7          	jalr	-2000(ra) # 80000c1a <acquire>
    if(p->pid == pid){
    800023f2:	589c                	lw	a5,48(s1)
    800023f4:	01278d63          	beq	a5,s2,8000240e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	8d4080e7          	jalr	-1836(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002402:	16848493          	addi	s1,s1,360
    80002406:	ff3491e3          	bne	s1,s3,800023e8 <kill+0x20>
  }
  return -1;
    8000240a:	557d                	li	a0,-1
    8000240c:	a829                	j	80002426 <kill+0x5e>
      p->killed = 1;
    8000240e:	4785                	li	a5,1
    80002410:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002412:	4c98                	lw	a4,24(s1)
    80002414:	4789                	li	a5,2
    80002416:	00f70f63          	beq	a4,a5,80002434 <kill+0x6c>
      release(&p->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	8b2080e7          	jalr	-1870(ra) # 80000cce <release>
      return 0;
    80002424:	4501                	li	a0,0
}
    80002426:	70a2                	ld	ra,40(sp)
    80002428:	7402                	ld	s0,32(sp)
    8000242a:	64e2                	ld	s1,24(sp)
    8000242c:	6942                	ld	s2,16(sp)
    8000242e:	69a2                	ld	s3,8(sp)
    80002430:	6145                	addi	sp,sp,48
    80002432:	8082                	ret
        p->state = RUNNABLE;
    80002434:	478d                	li	a5,3
    80002436:	cc9c                	sw	a5,24(s1)
    80002438:	b7cd                	j	8000241a <kill+0x52>

000000008000243a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000243a:	7179                	addi	sp,sp,-48
    8000243c:	f406                	sd	ra,40(sp)
    8000243e:	f022                	sd	s0,32(sp)
    80002440:	ec26                	sd	s1,24(sp)
    80002442:	e84a                	sd	s2,16(sp)
    80002444:	e44e                	sd	s3,8(sp)
    80002446:	e052                	sd	s4,0(sp)
    80002448:	1800                	addi	s0,sp,48
    8000244a:	84aa                	mv	s1,a0
    8000244c:	892e                	mv	s2,a1
    8000244e:	89b2                	mv	s3,a2
    80002450:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	580080e7          	jalr	1408(ra) # 800019d2 <myproc>
  if(user_dst){
    8000245a:	c08d                	beqz	s1,8000247c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000245c:	86d2                	mv	a3,s4
    8000245e:	864e                	mv	a2,s3
    80002460:	85ca                	mv	a1,s2
    80002462:	6928                	ld	a0,80(a0)
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	232080e7          	jalr	562(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000246c:	70a2                	ld	ra,40(sp)
    8000246e:	7402                	ld	s0,32(sp)
    80002470:	64e2                	ld	s1,24(sp)
    80002472:	6942                	ld	s2,16(sp)
    80002474:	69a2                	ld	s3,8(sp)
    80002476:	6a02                	ld	s4,0(sp)
    80002478:	6145                	addi	sp,sp,48
    8000247a:	8082                	ret
    memmove((char *)dst, src, len);
    8000247c:	000a061b          	sext.w	a2,s4
    80002480:	85ce                	mv	a1,s3
    80002482:	854a                	mv	a0,s2
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	8ee080e7          	jalr	-1810(ra) # 80000d72 <memmove>
    return 0;
    8000248c:	8526                	mv	a0,s1
    8000248e:	bff9                	j	8000246c <either_copyout+0x32>

0000000080002490 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002490:	7179                	addi	sp,sp,-48
    80002492:	f406                	sd	ra,40(sp)
    80002494:	f022                	sd	s0,32(sp)
    80002496:	ec26                	sd	s1,24(sp)
    80002498:	e84a                	sd	s2,16(sp)
    8000249a:	e44e                	sd	s3,8(sp)
    8000249c:	e052                	sd	s4,0(sp)
    8000249e:	1800                	addi	s0,sp,48
    800024a0:	892a                	mv	s2,a0
    800024a2:	84ae                	mv	s1,a1
    800024a4:	89b2                	mv	s3,a2
    800024a6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	52a080e7          	jalr	1322(ra) # 800019d2 <myproc>
  if(user_src){
    800024b0:	c08d                	beqz	s1,800024d2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024b2:	86d2                	mv	a3,s4
    800024b4:	864e                	mv	a2,s3
    800024b6:	85ca                	mv	a1,s2
    800024b8:	6928                	ld	a0,80(a0)
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	268080e7          	jalr	616(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024c2:	70a2                	ld	ra,40(sp)
    800024c4:	7402                	ld	s0,32(sp)
    800024c6:	64e2                	ld	s1,24(sp)
    800024c8:	6942                	ld	s2,16(sp)
    800024ca:	69a2                	ld	s3,8(sp)
    800024cc:	6a02                	ld	s4,0(sp)
    800024ce:	6145                	addi	sp,sp,48
    800024d0:	8082                	ret
    memmove(dst, (char*)src, len);
    800024d2:	000a061b          	sext.w	a2,s4
    800024d6:	85ce                	mv	a1,s3
    800024d8:	854a                	mv	a0,s2
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	898080e7          	jalr	-1896(ra) # 80000d72 <memmove>
    return 0;
    800024e2:	8526                	mv	a0,s1
    800024e4:	bff9                	j	800024c2 <either_copyin+0x32>

00000000800024e6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024e6:	715d                	addi	sp,sp,-80
    800024e8:	e486                	sd	ra,72(sp)
    800024ea:	e0a2                	sd	s0,64(sp)
    800024ec:	fc26                	sd	s1,56(sp)
    800024ee:	f84a                	sd	s2,48(sp)
    800024f0:	f44e                	sd	s3,40(sp)
    800024f2:	f052                	sd	s4,32(sp)
    800024f4:	ec56                	sd	s5,24(sp)
    800024f6:	e85a                	sd	s6,16(sp)
    800024f8:	e45e                	sd	s7,8(sp)
    800024fa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024fc:	00006517          	auipc	a0,0x6
    80002500:	bcc50513          	addi	a0,a0,-1076 # 800080c8 <digits+0x88>
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	080080e7          	jalr	128(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000250c:	0000f497          	auipc	s1,0xf
    80002510:	31c48493          	addi	s1,s1,796 # 80011828 <proc+0x158>
    80002514:	00015917          	auipc	s2,0x15
    80002518:	d1490913          	addi	s2,s2,-748 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000251c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000251e:	00006997          	auipc	s3,0x6
    80002522:	d4a98993          	addi	s3,s3,-694 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002526:	00006a97          	auipc	s5,0x6
    8000252a:	d4aa8a93          	addi	s5,s5,-694 # 80008270 <digits+0x230>
    printf("\n");
    8000252e:	00006a17          	auipc	s4,0x6
    80002532:	b9aa0a13          	addi	s4,s4,-1126 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002536:	00006b97          	auipc	s7,0x6
    8000253a:	d72b8b93          	addi	s7,s7,-654 # 800082a8 <states.0>
    8000253e:	a00d                	j	80002560 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002540:	ed86a583          	lw	a1,-296(a3)
    80002544:	8556                	mv	a0,s5
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	03e080e7          	jalr	62(ra) # 80000584 <printf>
    printf("\n");
    8000254e:	8552                	mv	a0,s4
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	034080e7          	jalr	52(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002558:	16848493          	addi	s1,s1,360
    8000255c:	03248263          	beq	s1,s2,80002580 <procdump+0x9a>
    if(p->state == UNUSED)
    80002560:	86a6                	mv	a3,s1
    80002562:	ec04a783          	lw	a5,-320(s1)
    80002566:	dbed                	beqz	a5,80002558 <procdump+0x72>
      state = "???";
    80002568:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256a:	fcfb6be3          	bltu	s6,a5,80002540 <procdump+0x5a>
    8000256e:	02079713          	slli	a4,a5,0x20
    80002572:	01d75793          	srli	a5,a4,0x1d
    80002576:	97de                	add	a5,a5,s7
    80002578:	6390                	ld	a2,0(a5)
    8000257a:	f279                	bnez	a2,80002540 <procdump+0x5a>
      state = "???";
    8000257c:	864e                	mv	a2,s3
    8000257e:	b7c9                	j	80002540 <procdump+0x5a>
  }
}
    80002580:	60a6                	ld	ra,72(sp)
    80002582:	6406                	ld	s0,64(sp)
    80002584:	74e2                	ld	s1,56(sp)
    80002586:	7942                	ld	s2,48(sp)
    80002588:	79a2                	ld	s3,40(sp)
    8000258a:	7a02                	ld	s4,32(sp)
    8000258c:	6ae2                	ld	s5,24(sp)
    8000258e:	6b42                	ld	s6,16(sp)
    80002590:	6ba2                	ld	s7,8(sp)
    80002592:	6161                	addi	sp,sp,80
    80002594:	8082                	ret

0000000080002596 <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    80002596:	7119                	addi	sp,sp,-128
    80002598:	fc86                	sd	ra,120(sp)
    8000259a:	f8a2                	sd	s0,112(sp)
    8000259c:	f4a6                	sd	s1,104(sp)
    8000259e:	f0ca                	sd	s2,96(sp)
    800025a0:	ecce                	sd	s3,88(sp)
    800025a2:	e8d2                	sd	s4,80(sp)
    800025a4:	e4d6                	sd	s5,72(sp)
    800025a6:	e0da                	sd	s6,64(sp)
    800025a8:	fc5e                	sd	s7,56(sp)
    800025aa:	0100                	addi	s0,sp,128
    800025ac:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    800025ae:	fffff097          	auipc	ra,0xfffff
    800025b2:	424080e7          	jalr	1060(ra) # 800019d2 <myproc>
    800025b6:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    800025b8:	0000f917          	auipc	s2,0xf
    800025bc:	27090913          	addi	s2,s2,624 # 80011828 <proc+0x158>
    800025c0:	00015a17          	auipc	s4,0x15
    800025c4:	c68a0a13          	addi	s4,s4,-920 # 80017228 <bcache+0x140>
  int nprocs = 0;
    800025c8:	4a81                	li	s5,0
    procinfo.state = p->state;
    procinfo.size = p->sz;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    800025ca:	4b81                	li	s7,0
    800025cc:	fac40493          	addi	s1,s0,-84
    800025d0:	a089                	j	80002612 <procinfo+0x7c>
    800025d2:	f8f42c23          	sw	a5,-104(s0)
    for (int i=0; i<16; i++)
    800025d6:	f9c40793          	addi	a5,s0,-100
      procinfo.ppid = 0;
    800025da:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    800025dc:	00074683          	lbu	a3,0(a4)
    800025e0:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    800025e4:	0705                	addi	a4,a4,1
    800025e6:	0785                	addi	a5,a5,1
    800025e8:	fe979ae3          	bne	a5,s1,800025dc <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    800025ec:	02800693          	li	a3,40
    800025f0:	f8840613          	addi	a2,s0,-120
    800025f4:	85ce                	mv	a1,s3
    800025f6:	050b3503          	ld	a0,80(s6)
    800025fa:	fffff097          	auipc	ra,0xfffff
    800025fe:	09c080e7          	jalr	156(ra) # 80001696 <copyout>
    80002602:	02054c63          	bltz	a0,8000263a <procinfo+0xa4>
      return -1;
    addr += sizeof(procinfo);
    80002606:	02898993          	addi	s3,s3,40
  for(p = proc; p < &proc[NPROC]; p++){ 
    8000260a:	16890913          	addi	s2,s2,360
    8000260e:	03490763          	beq	s2,s4,8000263c <procinfo+0xa6>
    if(p->state == UNUSED)
    80002612:	ec092783          	lw	a5,-320(s2)
    80002616:	dbf5                	beqz	a5,8000260a <procinfo+0x74>
    nprocs++;
    80002618:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    8000261a:	ed892703          	lw	a4,-296(s2)
    8000261e:	f8e42423          	sw	a4,-120(s0)
    procinfo.state = p->state;
    80002622:	f8f42623          	sw	a5,-116(s0)
    procinfo.size = p->sz;
    80002626:	ef093783          	ld	a5,-272(s2)
    8000262a:	f8f43823          	sd	a5,-112(s0)
    if (p->parent)
    8000262e:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    80002632:	87de                	mv	a5,s7
    if (p->parent)
    80002634:	df59                	beqz	a4,800025d2 <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    80002636:	5b1c                	lw	a5,48(a4)
    80002638:	bf69                	j	800025d2 <procinfo+0x3c>
      return -1;
    8000263a:	5afd                	li	s5,-1
  }
  return nprocs;
}
    8000263c:	8556                	mv	a0,s5
    8000263e:	70e6                	ld	ra,120(sp)
    80002640:	7446                	ld	s0,112(sp)
    80002642:	74a6                	ld	s1,104(sp)
    80002644:	7906                	ld	s2,96(sp)
    80002646:	69e6                	ld	s3,88(sp)
    80002648:	6a46                	ld	s4,80(sp)
    8000264a:	6aa6                	ld	s5,72(sp)
    8000264c:	6b06                	ld	s6,64(sp)
    8000264e:	7be2                	ld	s7,56(sp)
    80002650:	6109                	addi	sp,sp,128
    80002652:	8082                	ret

0000000080002654 <swtch>:
    80002654:	00153023          	sd	ra,0(a0)
    80002658:	00253423          	sd	sp,8(a0)
    8000265c:	e900                	sd	s0,16(a0)
    8000265e:	ed04                	sd	s1,24(a0)
    80002660:	03253023          	sd	s2,32(a0)
    80002664:	03353423          	sd	s3,40(a0)
    80002668:	03453823          	sd	s4,48(a0)
    8000266c:	03553c23          	sd	s5,56(a0)
    80002670:	05653023          	sd	s6,64(a0)
    80002674:	05753423          	sd	s7,72(a0)
    80002678:	05853823          	sd	s8,80(a0)
    8000267c:	05953c23          	sd	s9,88(a0)
    80002680:	07a53023          	sd	s10,96(a0)
    80002684:	07b53423          	sd	s11,104(a0)
    80002688:	0005b083          	ld	ra,0(a1)
    8000268c:	0085b103          	ld	sp,8(a1)
    80002690:	6980                	ld	s0,16(a1)
    80002692:	6d84                	ld	s1,24(a1)
    80002694:	0205b903          	ld	s2,32(a1)
    80002698:	0285b983          	ld	s3,40(a1)
    8000269c:	0305ba03          	ld	s4,48(a1)
    800026a0:	0385ba83          	ld	s5,56(a1)
    800026a4:	0405bb03          	ld	s6,64(a1)
    800026a8:	0485bb83          	ld	s7,72(a1)
    800026ac:	0505bc03          	ld	s8,80(a1)
    800026b0:	0585bc83          	ld	s9,88(a1)
    800026b4:	0605bd03          	ld	s10,96(a1)
    800026b8:	0685bd83          	ld	s11,104(a1)
    800026bc:	8082                	ret

00000000800026be <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026be:	1141                	addi	sp,sp,-16
    800026c0:	e406                	sd	ra,8(sp)
    800026c2:	e022                	sd	s0,0(sp)
    800026c4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c6:	00006597          	auipc	a1,0x6
    800026ca:	c1258593          	addi	a1,a1,-1006 # 800082d8 <states.0+0x30>
    800026ce:	00015517          	auipc	a0,0x15
    800026d2:	a0250513          	addi	a0,a0,-1534 # 800170d0 <tickslock>
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	4b4080e7          	jalr	1204(ra) # 80000b8a <initlock>
}
    800026de:	60a2                	ld	ra,8(sp)
    800026e0:	6402                	ld	s0,0(sp)
    800026e2:	0141                	addi	sp,sp,16
    800026e4:	8082                	ret

00000000800026e6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e6:	1141                	addi	sp,sp,-16
    800026e8:	e422                	sd	s0,8(sp)
    800026ea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ec:	00003797          	auipc	a5,0x3
    800026f0:	58478793          	addi	a5,a5,1412 # 80005c70 <kernelvec>
    800026f4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f8:	6422                	ld	s0,8(sp)
    800026fa:	0141                	addi	sp,sp,16
    800026fc:	8082                	ret

00000000800026fe <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026fe:	1141                	addi	sp,sp,-16
    80002700:	e406                	sd	ra,8(sp)
    80002702:	e022                	sd	s0,0(sp)
    80002704:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	2cc080e7          	jalr	716(ra) # 800019d2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002712:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002714:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002718:	00005697          	auipc	a3,0x5
    8000271c:	8e868693          	addi	a3,a3,-1816 # 80007000 <_trampoline>
    80002720:	00005717          	auipc	a4,0x5
    80002724:	8e070713          	addi	a4,a4,-1824 # 80007000 <_trampoline>
    80002728:	8f15                	sub	a4,a4,a3
    8000272a:	040007b7          	lui	a5,0x4000
    8000272e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002730:	07b2                	slli	a5,a5,0xc
    80002732:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002734:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002738:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000273a:	18002673          	csrr	a2,satp
    8000273e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002740:	6d30                	ld	a2,88(a0)
    80002742:	6138                	ld	a4,64(a0)
    80002744:	6585                	lui	a1,0x1
    80002746:	972e                	add	a4,a4,a1
    80002748:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000274a:	6d38                	ld	a4,88(a0)
    8000274c:	00000617          	auipc	a2,0x0
    80002750:	13860613          	addi	a2,a2,312 # 80002884 <usertrap>
    80002754:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002756:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002758:	8612                	mv	a2,tp
    8000275a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000275c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002760:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002764:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002768:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000276c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000276e:	6f18                	ld	a4,24(a4)
    80002770:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002774:	692c                	ld	a1,80(a0)
    80002776:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002778:	00005717          	auipc	a4,0x5
    8000277c:	91870713          	addi	a4,a4,-1768 # 80007090 <userret>
    80002780:	8f15                	sub	a4,a4,a3
    80002782:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002784:	577d                	li	a4,-1
    80002786:	177e                	slli	a4,a4,0x3f
    80002788:	8dd9                	or	a1,a1,a4
    8000278a:	02000537          	lui	a0,0x2000
    8000278e:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002790:	0536                	slli	a0,a0,0xd
    80002792:	9782                	jalr	a5
}
    80002794:	60a2                	ld	ra,8(sp)
    80002796:	6402                	ld	s0,0(sp)
    80002798:	0141                	addi	sp,sp,16
    8000279a:	8082                	ret

000000008000279c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279c:	1101                	addi	sp,sp,-32
    8000279e:	ec06                	sd	ra,24(sp)
    800027a0:	e822                	sd	s0,16(sp)
    800027a2:	e426                	sd	s1,8(sp)
    800027a4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a6:	00015497          	auipc	s1,0x15
    800027aa:	92a48493          	addi	s1,s1,-1750 # 800170d0 <tickslock>
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	46a080e7          	jalr	1130(ra) # 80000c1a <acquire>
  ticks++;
    800027b8:	00007517          	auipc	a0,0x7
    800027bc:	87850513          	addi	a0,a0,-1928 # 80009030 <ticks>
    800027c0:	411c                	lw	a5,0(a0)
    800027c2:	2785                	addiw	a5,a5,1
    800027c4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c6:	00000097          	auipc	ra,0x0
    800027ca:	a5c080e7          	jalr	-1444(ra) # 80002222 <wakeup>
  release(&tickslock);
    800027ce:	8526                	mv	a0,s1
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	4fe080e7          	jalr	1278(ra) # 80000cce <release>
}
    800027d8:	60e2                	ld	ra,24(sp)
    800027da:	6442                	ld	s0,16(sp)
    800027dc:	64a2                	ld	s1,8(sp)
    800027de:	6105                	addi	sp,sp,32
    800027e0:	8082                	ret

00000000800027e2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027e2:	1101                	addi	sp,sp,-32
    800027e4:	ec06                	sd	ra,24(sp)
    800027e6:	e822                	sd	s0,16(sp)
    800027e8:	e426                	sd	s1,8(sp)
    800027ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ec:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027f0:	00074d63          	bltz	a4,8000280a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027f4:	57fd                	li	a5,-1
    800027f6:	17fe                	slli	a5,a5,0x3f
    800027f8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027fa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027fc:	06f70363          	beq	a4,a5,80002862 <devintr+0x80>
  }
}
    80002800:	60e2                	ld	ra,24(sp)
    80002802:	6442                	ld	s0,16(sp)
    80002804:	64a2                	ld	s1,8(sp)
    80002806:	6105                	addi	sp,sp,32
    80002808:	8082                	ret
     (scause & 0xff) == 9){
    8000280a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000280e:	46a5                	li	a3,9
    80002810:	fed792e3          	bne	a5,a3,800027f4 <devintr+0x12>
    int irq = plic_claim();
    80002814:	00003097          	auipc	ra,0x3
    80002818:	564080e7          	jalr	1380(ra) # 80005d78 <plic_claim>
    8000281c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000281e:	47a9                	li	a5,10
    80002820:	02f50763          	beq	a0,a5,8000284e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002824:	4785                	li	a5,1
    80002826:	02f50963          	beq	a0,a5,80002858 <devintr+0x76>
    return 1;
    8000282a:	4505                	li	a0,1
    } else if(irq){
    8000282c:	d8f1                	beqz	s1,80002800 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000282e:	85a6                	mv	a1,s1
    80002830:	00006517          	auipc	a0,0x6
    80002834:	ab050513          	addi	a0,a0,-1360 # 800082e0 <states.0+0x38>
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	d4c080e7          	jalr	-692(ra) # 80000584 <printf>
      plic_complete(irq);
    80002840:	8526                	mv	a0,s1
    80002842:	00003097          	auipc	ra,0x3
    80002846:	55a080e7          	jalr	1370(ra) # 80005d9c <plic_complete>
    return 1;
    8000284a:	4505                	li	a0,1
    8000284c:	bf55                	j	80002800 <devintr+0x1e>
      uartintr();
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	144080e7          	jalr	324(ra) # 80000992 <uartintr>
    80002856:	b7ed                	j	80002840 <devintr+0x5e>
      virtio_disk_intr();
    80002858:	00004097          	auipc	ra,0x4
    8000285c:	9d0080e7          	jalr	-1584(ra) # 80006228 <virtio_disk_intr>
    80002860:	b7c5                	j	80002840 <devintr+0x5e>
    if(cpuid() == 0){
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	144080e7          	jalr	324(ra) # 800019a6 <cpuid>
    8000286a:	c901                	beqz	a0,8000287a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000286c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002870:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002872:	14479073          	csrw	sip,a5
    return 2;
    80002876:	4509                	li	a0,2
    80002878:	b761                	j	80002800 <devintr+0x1e>
      clockintr();
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	f22080e7          	jalr	-222(ra) # 8000279c <clockintr>
    80002882:	b7ed                	j	8000286c <devintr+0x8a>

0000000080002884 <usertrap>:
{
    80002884:	1101                	addi	sp,sp,-32
    80002886:	ec06                	sd	ra,24(sp)
    80002888:	e822                	sd	s0,16(sp)
    8000288a:	e426                	sd	s1,8(sp)
    8000288c:	e04a                	sd	s2,0(sp)
    8000288e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002890:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002894:	1007f793          	andi	a5,a5,256
    80002898:	e3b5                	bnez	a5,800028fc <usertrap+0x78>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000289a:	00003797          	auipc	a5,0x3
    8000289e:	3d678793          	addi	a5,a5,982 # 80005c70 <kernelvec>
    800028a2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a6:	fffff097          	auipc	ra,0xfffff
    800028aa:	12c080e7          	jalr	300(ra) # 800019d2 <myproc>
    800028ae:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b2:	14102773          	csrr	a4,sepc
    800028b6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028bc:	47a1                	li	a5,8
    800028be:	04f71d63          	bne	a4,a5,80002918 <usertrap+0x94>
    if(p->killed)
    800028c2:	551c                	lw	a5,40(a0)
    800028c4:	e7a1                	bnez	a5,8000290c <usertrap+0x88>
    p->trapframe->epc += 4;
    800028c6:	6cb8                	ld	a4,88(s1)
    800028c8:	6f1c                	ld	a5,24(a4)
    800028ca:	0791                	addi	a5,a5,4
    800028cc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d6:	10079073          	csrw	sstatus,a5
    syscall();
    800028da:	00000097          	auipc	ra,0x0
    800028de:	370080e7          	jalr	880(ra) # 80002c4a <syscall>
  if(p->killed)
    800028e2:	549c                	lw	a5,40(s1)
    800028e4:	12079063          	bnez	a5,80002a04 <usertrap+0x180>
  usertrapret();
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	e16080e7          	jalr	-490(ra) # 800026fe <usertrapret>
}
    800028f0:	60e2                	ld	ra,24(sp)
    800028f2:	6442                	ld	s0,16(sp)
    800028f4:	64a2                	ld	s1,8(sp)
    800028f6:	6902                	ld	s2,0(sp)
    800028f8:	6105                	addi	sp,sp,32
    800028fa:	8082                	ret
    panic("usertrap: not from user mode");
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a0450513          	addi	a0,a0,-1532 # 80008300 <states.0+0x58>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c36080e7          	jalr	-970(ra) # 8000053a <panic>
      exit(-1);
    8000290c:	557d                	li	a0,-1
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	9e4080e7          	jalr	-1564(ra) # 800022f2 <exit>
    80002916:	bf45                	j	800028c6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	eca080e7          	jalr	-310(ra) # 800027e2 <devintr>
    80002920:	892a                	mv	s2,a0
    80002922:	ed71                	bnez	a0,800029fe <usertrap+0x17a>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002924:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    80002928:	47b5                	li	a5,13
    8000292a:	00f70763          	beq	a4,a5,80002938 <usertrap+0xb4>
    8000292e:	14202773          	csrr	a4,scause
    80002932:	47bd                	li	a5,15
    80002934:	08f71d63          	bne	a4,a5,800029ce <usertrap+0x14a>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002938:	143027f3          	csrr	a5,stval
  if (r_stval() < p->sz){
    8000293c:	64b8                	ld	a4,72(s1)
    8000293e:	04e7fe63          	bgeu	a5,a4,8000299a <usertrap+0x116>
    char* physical_frame = kalloc();
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	19e080e7          	jalr	414(ra) # 80000ae0 <kalloc>
    8000294a:	892a                	mv	s2,a0
    if(physical_frame == 0){
    8000294c:	c505                	beqz	a0,80002974 <usertrap+0xf0>
        memset((void*)physical_frame, 0, PGSIZE);
    8000294e:	6605                	lui	a2,0x1
    80002950:	4581                	li	a1,0
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	3c4080e7          	jalr	964(ra) # 80000d16 <memset>
    8000295a:	143025f3          	csrr	a1,stval
        mappages(p->pagetable, PGROUNDDOWN(r_stval()), PGSIZE, (uint64)physical_frame, (PTE_R | PTE_W | PTE_X | PTE_U));
    8000295e:	4779                	li	a4,30
    80002960:	86ca                	mv	a3,s2
    80002962:	6605                	lui	a2,0x1
    80002964:	77fd                	lui	a5,0xfffff
    80002966:	8dfd                	and	a1,a1,a5
    80002968:	68a8                	ld	a0,80(s1)
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	774080e7          	jalr	1908(ra) # 800010de <mappages>
    80002972:	bf85                	j	800028e2 <usertrap+0x5e>
    80002974:	14302673          	csrr	a2,stval
      printf("usertrap(): out of memory, pid=%d, fault_address=%p\n", p->pid, r_stval());
    80002978:	588c                	lw	a1,48(s1)
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	9a650513          	addi	a0,a0,-1626 # 80008320 <states.0+0x78>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c02080e7          	jalr	-1022(ra) # 80000584 <printf>
      p->killed = 1;
    8000298a:	4785                	li	a5,1
    8000298c:	d49c                	sw	a5,40(s1)
      exit(-1);
    8000298e:	557d                	li	a0,-1
    80002990:	00000097          	auipc	ra,0x0
    80002994:	962080e7          	jalr	-1694(ra) # 800022f2 <exit>
    80002998:	b7a9                	j	800028e2 <usertrap+0x5e>
    8000299a:	14302673          	csrr	a2,stval
      printf("usertrap(): unexpected page fault, pid=%d, fault_address=%p\n", p->pid, r_stval());
    8000299e:	588c                	lw	a1,48(s1)
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	9b850513          	addi	a0,a0,-1608 # 80008358 <states.0+0xb0>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	bdc080e7          	jalr	-1060(ra) # 80000584 <printf>
    p->killed = 1;
    800029b0:	4785                	li	a5,1
    800029b2:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029b4:	557d                	li	a0,-1
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	93c080e7          	jalr	-1732(ra) # 800022f2 <exit>
  if(which_dev == 2)
    800029be:	4789                	li	a5,2
    800029c0:	f2f914e3          	bne	s2,a5,800028e8 <usertrap+0x64>
    yield();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	696080e7          	jalr	1686(ra) # 8000205a <yield>
    800029cc:	bf31                	j	800028e8 <usertrap+0x64>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029d2:	5890                	lw	a2,48(s1)
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9c450513          	addi	a0,a0,-1596 # 80008398 <states.0+0xf0>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	ba8080e7          	jalr	-1112(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029e8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	9dc50513          	addi	a0,a0,-1572 # 800083c8 <states.0+0x120>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b90080e7          	jalr	-1136(ra) # 80000584 <printf>
    p->killed = 1;
    800029fc:	bf55                	j	800029b0 <usertrap+0x12c>
  if(p->killed)
    800029fe:	549c                	lw	a5,40(s1)
    80002a00:	dfdd                	beqz	a5,800029be <usertrap+0x13a>
    80002a02:	bf4d                	j	800029b4 <usertrap+0x130>
    80002a04:	4901                	li	s2,0
    80002a06:	b77d                	j	800029b4 <usertrap+0x130>

0000000080002a08 <kerneltrap>:
{
    80002a08:	7179                	addi	sp,sp,-48
    80002a0a:	f406                	sd	ra,40(sp)
    80002a0c:	f022                	sd	s0,32(sp)
    80002a0e:	ec26                	sd	s1,24(sp)
    80002a10:	e84a                	sd	s2,16(sp)
    80002a12:	e44e                	sd	s3,8(sp)
    80002a14:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a16:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a22:	1004f793          	andi	a5,s1,256
    80002a26:	cb85                	beqz	a5,80002a56 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a28:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a2c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a2e:	ef85                	bnez	a5,80002a66 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a30:	00000097          	auipc	ra,0x0
    80002a34:	db2080e7          	jalr	-590(ra) # 800027e2 <devintr>
    80002a38:	cd1d                	beqz	a0,80002a76 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a3a:	4789                	li	a5,2
    80002a3c:	06f50a63          	beq	a0,a5,80002ab0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a40:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a44:	10049073          	csrw	sstatus,s1
}
    80002a48:	70a2                	ld	ra,40(sp)
    80002a4a:	7402                	ld	s0,32(sp)
    80002a4c:	64e2                	ld	s1,24(sp)
    80002a4e:	6942                	ld	s2,16(sp)
    80002a50:	69a2                	ld	s3,8(sp)
    80002a52:	6145                	addi	sp,sp,48
    80002a54:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	99250513          	addi	a0,a0,-1646 # 800083e8 <states.0+0x140>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	adc080e7          	jalr	-1316(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	9aa50513          	addi	a0,a0,-1622 # 80008410 <states.0+0x168>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	acc080e7          	jalr	-1332(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002a76:	85ce                	mv	a1,s3
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	9b850513          	addi	a0,a0,-1608 # 80008430 <states.0+0x188>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	b04080e7          	jalr	-1276(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a8c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	9b050513          	addi	a0,a0,-1616 # 80008440 <states.0+0x198>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	aec080e7          	jalr	-1300(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	9b850513          	addi	a0,a0,-1608 # 80008458 <states.0+0x1b0>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	a92080e7          	jalr	-1390(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	f22080e7          	jalr	-222(ra) # 800019d2 <myproc>
    80002ab8:	d541                	beqz	a0,80002a40 <kerneltrap+0x38>
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	f18080e7          	jalr	-232(ra) # 800019d2 <myproc>
    80002ac2:	4d18                	lw	a4,24(a0)
    80002ac4:	4791                	li	a5,4
    80002ac6:	f6f71de3          	bne	a4,a5,80002a40 <kerneltrap+0x38>
    yield();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	590080e7          	jalr	1424(ra) # 8000205a <yield>
    80002ad2:	b7bd                	j	80002a40 <kerneltrap+0x38>

0000000080002ad4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ad4:	1101                	addi	sp,sp,-32
    80002ad6:	ec06                	sd	ra,24(sp)
    80002ad8:	e822                	sd	s0,16(sp)
    80002ada:	e426                	sd	s1,8(sp)
    80002adc:	1000                	addi	s0,sp,32
    80002ade:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	ef2080e7          	jalr	-270(ra) # 800019d2 <myproc>
  switch (n) {
    80002ae8:	4795                	li	a5,5
    80002aea:	0497e163          	bltu	a5,s1,80002b2c <argraw+0x58>
    80002aee:	048a                	slli	s1,s1,0x2
    80002af0:	00006717          	auipc	a4,0x6
    80002af4:	9a070713          	addi	a4,a4,-1632 # 80008490 <states.0+0x1e8>
    80002af8:	94ba                	add	s1,s1,a4
    80002afa:	409c                	lw	a5,0(s1)
    80002afc:	97ba                	add	a5,a5,a4
    80002afe:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	64a2                	ld	s1,8(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret
    return p->trapframe->a1;
    80002b0e:	6d3c                	ld	a5,88(a0)
    80002b10:	7fa8                	ld	a0,120(a5)
    80002b12:	bfcd                	j	80002b04 <argraw+0x30>
    return p->trapframe->a2;
    80002b14:	6d3c                	ld	a5,88(a0)
    80002b16:	63c8                	ld	a0,128(a5)
    80002b18:	b7f5                	j	80002b04 <argraw+0x30>
    return p->trapframe->a3;
    80002b1a:	6d3c                	ld	a5,88(a0)
    80002b1c:	67c8                	ld	a0,136(a5)
    80002b1e:	b7dd                	j	80002b04 <argraw+0x30>
    return p->trapframe->a4;
    80002b20:	6d3c                	ld	a5,88(a0)
    80002b22:	6bc8                	ld	a0,144(a5)
    80002b24:	b7c5                	j	80002b04 <argraw+0x30>
    return p->trapframe->a5;
    80002b26:	6d3c                	ld	a5,88(a0)
    80002b28:	6fc8                	ld	a0,152(a5)
    80002b2a:	bfe9                	j	80002b04 <argraw+0x30>
  panic("argraw");
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	93c50513          	addi	a0,a0,-1732 # 80008468 <states.0+0x1c0>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a06080e7          	jalr	-1530(ra) # 8000053a <panic>

0000000080002b3c <fetchaddr>:
{
    80002b3c:	1101                	addi	sp,sp,-32
    80002b3e:	ec06                	sd	ra,24(sp)
    80002b40:	e822                	sd	s0,16(sp)
    80002b42:	e426                	sd	s1,8(sp)
    80002b44:	e04a                	sd	s2,0(sp)
    80002b46:	1000                	addi	s0,sp,32
    80002b48:	84aa                	mv	s1,a0
    80002b4a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	e86080e7          	jalr	-378(ra) # 800019d2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b54:	653c                	ld	a5,72(a0)
    80002b56:	02f4f863          	bgeu	s1,a5,80002b86 <fetchaddr+0x4a>
    80002b5a:	00848713          	addi	a4,s1,8
    80002b5e:	02e7e663          	bltu	a5,a4,80002b8a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b62:	46a1                	li	a3,8
    80002b64:	8626                	mv	a2,s1
    80002b66:	85ca                	mv	a1,s2
    80002b68:	6928                	ld	a0,80(a0)
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	bb8080e7          	jalr	-1096(ra) # 80001722 <copyin>
    80002b72:	00a03533          	snez	a0,a0
    80002b76:	40a00533          	neg	a0,a0
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6902                	ld	s2,0(sp)
    80002b82:	6105                	addi	sp,sp,32
    80002b84:	8082                	ret
    return -1;
    80002b86:	557d                	li	a0,-1
    80002b88:	bfcd                	j	80002b7a <fetchaddr+0x3e>
    80002b8a:	557d                	li	a0,-1
    80002b8c:	b7fd                	j	80002b7a <fetchaddr+0x3e>

0000000080002b8e <fetchstr>:
{
    80002b8e:	7179                	addi	sp,sp,-48
    80002b90:	f406                	sd	ra,40(sp)
    80002b92:	f022                	sd	s0,32(sp)
    80002b94:	ec26                	sd	s1,24(sp)
    80002b96:	e84a                	sd	s2,16(sp)
    80002b98:	e44e                	sd	s3,8(sp)
    80002b9a:	1800                	addi	s0,sp,48
    80002b9c:	892a                	mv	s2,a0
    80002b9e:	84ae                	mv	s1,a1
    80002ba0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	e30080e7          	jalr	-464(ra) # 800019d2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002baa:	86ce                	mv	a3,s3
    80002bac:	864a                	mv	a2,s2
    80002bae:	85a6                	mv	a1,s1
    80002bb0:	6928                	ld	a0,80(a0)
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	bfe080e7          	jalr	-1026(ra) # 800017b0 <copyinstr>
  if(err < 0)
    80002bba:	00054763          	bltz	a0,80002bc8 <fetchstr+0x3a>
  return strlen(buf);
    80002bbe:	8526                	mv	a0,s1
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	2d2080e7          	jalr	722(ra) # 80000e92 <strlen>
}
    80002bc8:	70a2                	ld	ra,40(sp)
    80002bca:	7402                	ld	s0,32(sp)
    80002bcc:	64e2                	ld	s1,24(sp)
    80002bce:	6942                	ld	s2,16(sp)
    80002bd0:	69a2                	ld	s3,8(sp)
    80002bd2:	6145                	addi	sp,sp,48
    80002bd4:	8082                	ret

0000000080002bd6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bd6:	1101                	addi	sp,sp,-32
    80002bd8:	ec06                	sd	ra,24(sp)
    80002bda:	e822                	sd	s0,16(sp)
    80002bdc:	e426                	sd	s1,8(sp)
    80002bde:	1000                	addi	s0,sp,32
    80002be0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	ef2080e7          	jalr	-270(ra) # 80002ad4 <argraw>
    80002bea:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bec:	4501                	li	a0,0
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret

0000000080002bf8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bf8:	1101                	addi	sp,sp,-32
    80002bfa:	ec06                	sd	ra,24(sp)
    80002bfc:	e822                	sd	s0,16(sp)
    80002bfe:	e426                	sd	s1,8(sp)
    80002c00:	1000                	addi	s0,sp,32
    80002c02:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	ed0080e7          	jalr	-304(ra) # 80002ad4 <argraw>
    80002c0c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c0e:	4501                	li	a0,0
    80002c10:	60e2                	ld	ra,24(sp)
    80002c12:	6442                	ld	s0,16(sp)
    80002c14:	64a2                	ld	s1,8(sp)
    80002c16:	6105                	addi	sp,sp,32
    80002c18:	8082                	ret

0000000080002c1a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c1a:	1101                	addi	sp,sp,-32
    80002c1c:	ec06                	sd	ra,24(sp)
    80002c1e:	e822                	sd	s0,16(sp)
    80002c20:	e426                	sd	s1,8(sp)
    80002c22:	e04a                	sd	s2,0(sp)
    80002c24:	1000                	addi	s0,sp,32
    80002c26:	84ae                	mv	s1,a1
    80002c28:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	eaa080e7          	jalr	-342(ra) # 80002ad4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c32:	864a                	mv	a2,s2
    80002c34:	85a6                	mv	a1,s1
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	f58080e7          	jalr	-168(ra) # 80002b8e <fetchstr>
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	64a2                	ld	s1,8(sp)
    80002c44:	6902                	ld	s2,0(sp)
    80002c46:	6105                	addi	sp,sp,32
    80002c48:	8082                	ret

0000000080002c4a <syscall>:
[SYS_freepmem]   sys_freepmem,
};

void
syscall(void)
{
    80002c4a:	1101                	addi	sp,sp,-32
    80002c4c:	ec06                	sd	ra,24(sp)
    80002c4e:	e822                	sd	s0,16(sp)
    80002c50:	e426                	sd	s1,8(sp)
    80002c52:	e04a                	sd	s2,0(sp)
    80002c54:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	d7c080e7          	jalr	-644(ra) # 800019d2 <myproc>
    80002c5e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c60:	05853903          	ld	s2,88(a0)
    80002c64:	0a893783          	ld	a5,168(s2)
    80002c68:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c6c:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffd8fff>
    80002c6e:	4759                	li	a4,22
    80002c70:	00f76f63          	bltu	a4,a5,80002c8e <syscall+0x44>
    80002c74:	00369713          	slli	a4,a3,0x3
    80002c78:	00006797          	auipc	a5,0x6
    80002c7c:	83078793          	addi	a5,a5,-2000 # 800084a8 <syscalls>
    80002c80:	97ba                	add	a5,a5,a4
    80002c82:	639c                	ld	a5,0(a5)
    80002c84:	c789                	beqz	a5,80002c8e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c86:	9782                	jalr	a5
    80002c88:	06a93823          	sd	a0,112(s2)
    80002c8c:	a839                	j	80002caa <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c8e:	15848613          	addi	a2,s1,344
    80002c92:	588c                	lw	a1,48(s1)
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	7dc50513          	addi	a0,a0,2012 # 80008470 <states.0+0x1c8>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8e8080e7          	jalr	-1816(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ca4:	6cbc                	ld	a5,88(s1)
    80002ca6:	577d                	li	a4,-1
    80002ca8:	fbb8                	sd	a4,112(a5)
  }
}
    80002caa:	60e2                	ld	ra,24(sp)
    80002cac:	6442                	ld	s0,16(sp)
    80002cae:	64a2                	ld	s1,8(sp)
    80002cb0:	6902                	ld	s2,0(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret

0000000080002cb6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cbe:	fec40593          	addi	a1,s0,-20
    80002cc2:	4501                	li	a0,0
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	f12080e7          	jalr	-238(ra) # 80002bd6 <argint>
    return -1;
    80002ccc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cce:	00054963          	bltz	a0,80002ce0 <sys_exit+0x2a>
  exit(n);
    80002cd2:	fec42503          	lw	a0,-20(s0)
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	61c080e7          	jalr	1564(ra) # 800022f2 <exit>
  return 0;  // not reached
    80002cde:	4781                	li	a5,0
}
    80002ce0:	853e                	mv	a0,a5
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret

0000000080002cea <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cea:	1141                	addi	sp,sp,-16
    80002cec:	e406                	sd	ra,8(sp)
    80002cee:	e022                	sd	s0,0(sp)
    80002cf0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	ce0080e7          	jalr	-800(ra) # 800019d2 <myproc>
}
    80002cfa:	5908                	lw	a0,48(a0)
    80002cfc:	60a2                	ld	ra,8(sp)
    80002cfe:	6402                	ld	s0,0(sp)
    80002d00:	0141                	addi	sp,sp,16
    80002d02:	8082                	ret

0000000080002d04 <sys_fork>:

uint64
sys_fork(void)
{
    80002d04:	1141                	addi	sp,sp,-16
    80002d06:	e406                	sd	ra,8(sp)
    80002d08:	e022                	sd	s0,0(sp)
    80002d0a:	0800                	addi	s0,sp,16
  return fork();
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	098080e7          	jalr	152(ra) # 80001da4 <fork>
}
    80002d14:	60a2                	ld	ra,8(sp)
    80002d16:	6402                	ld	s0,0(sp)
    80002d18:	0141                	addi	sp,sp,16
    80002d1a:	8082                	ret

0000000080002d1c <sys_wait>:

uint64
sys_wait(void)
{
    80002d1c:	1101                	addi	sp,sp,-32
    80002d1e:	ec06                	sd	ra,24(sp)
    80002d20:	e822                	sd	s0,16(sp)
    80002d22:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d24:	fe840593          	addi	a1,s0,-24
    80002d28:	4501                	li	a0,0
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	ece080e7          	jalr	-306(ra) # 80002bf8 <argaddr>
    80002d32:	87aa                	mv	a5,a0
    return -1;
    80002d34:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d36:	0007c863          	bltz	a5,80002d46 <sys_wait+0x2a>
  return wait(p);
    80002d3a:	fe843503          	ld	a0,-24(s0)
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	3bc080e7          	jalr	956(ra) # 800020fa <wait>
}
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d4e:	7139                	addi	sp,sp,-64
    80002d50:	fc06                	sd	ra,56(sp)
    80002d52:	f822                	sd	s0,48(sp)
    80002d54:	f426                	sd	s1,40(sp)
    80002d56:	f04a                	sd	s2,32(sp)
    80002d58:	ec4e                	sd	s3,24(sp)
    80002d5a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d5c:	fcc40593          	addi	a1,s0,-52
    80002d60:	4501                	li	a0,0
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	e74080e7          	jalr	-396(ra) # 80002bd6 <argint>
    return -1;
    80002d6a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d6c:	06054563          	bltz	a0,80002dd6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d70:	00014517          	auipc	a0,0x14
    80002d74:	36050513          	addi	a0,a0,864 # 800170d0 <tickslock>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	ea2080e7          	jalr	-350(ra) # 80000c1a <acquire>
  ticks0 = ticks;
    80002d80:	00006917          	auipc	s2,0x6
    80002d84:	2b092903          	lw	s2,688(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d88:	fcc42783          	lw	a5,-52(s0)
    80002d8c:	cf85                	beqz	a5,80002dc4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d8e:	00014997          	auipc	s3,0x14
    80002d92:	34298993          	addi	s3,s3,834 # 800170d0 <tickslock>
    80002d96:	00006497          	auipc	s1,0x6
    80002d9a:	29a48493          	addi	s1,s1,666 # 80009030 <ticks>
    if(myproc()->killed){
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	c34080e7          	jalr	-972(ra) # 800019d2 <myproc>
    80002da6:	551c                	lw	a5,40(a0)
    80002da8:	ef9d                	bnez	a5,80002de6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002daa:	85ce                	mv	a1,s3
    80002dac:	8526                	mv	a0,s1
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	2e8080e7          	jalr	744(ra) # 80002096 <sleep>
  while(ticks - ticks0 < n){
    80002db6:	409c                	lw	a5,0(s1)
    80002db8:	412787bb          	subw	a5,a5,s2
    80002dbc:	fcc42703          	lw	a4,-52(s0)
    80002dc0:	fce7efe3          	bltu	a5,a4,80002d9e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dc4:	00014517          	auipc	a0,0x14
    80002dc8:	30c50513          	addi	a0,a0,780 # 800170d0 <tickslock>
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	f02080e7          	jalr	-254(ra) # 80000cce <release>
  return 0;
    80002dd4:	4781                	li	a5,0
}
    80002dd6:	853e                	mv	a0,a5
    80002dd8:	70e2                	ld	ra,56(sp)
    80002dda:	7442                	ld	s0,48(sp)
    80002ddc:	74a2                	ld	s1,40(sp)
    80002dde:	7902                	ld	s2,32(sp)
    80002de0:	69e2                	ld	s3,24(sp)
    80002de2:	6121                	addi	sp,sp,64
    80002de4:	8082                	ret
      release(&tickslock);
    80002de6:	00014517          	auipc	a0,0x14
    80002dea:	2ea50513          	addi	a0,a0,746 # 800170d0 <tickslock>
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	ee0080e7          	jalr	-288(ra) # 80000cce <release>
      return -1;
    80002df6:	57fd                	li	a5,-1
    80002df8:	bff9                	j	80002dd6 <sys_sleep+0x88>

0000000080002dfa <sys_kill>:

uint64
sys_kill(void)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e02:	fec40593          	addi	a1,s0,-20
    80002e06:	4501                	li	a0,0
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	dce080e7          	jalr	-562(ra) # 80002bd6 <argint>
    80002e10:	87aa                	mv	a5,a0
    return -1;
    80002e12:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e14:	0007c863          	bltz	a5,80002e24 <sys_kill+0x2a>
  return kill(pid);
    80002e18:	fec42503          	lw	a0,-20(s0)
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	5ac080e7          	jalr	1452(ra) # 800023c8 <kill>
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	6105                	addi	sp,sp,32
    80002e2a:	8082                	ret

0000000080002e2c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e2c:	1101                	addi	sp,sp,-32
    80002e2e:	ec06                	sd	ra,24(sp)
    80002e30:	e822                	sd	s0,16(sp)
    80002e32:	e426                	sd	s1,8(sp)
    80002e34:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e36:	00014517          	auipc	a0,0x14
    80002e3a:	29a50513          	addi	a0,a0,666 # 800170d0 <tickslock>
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	ddc080e7          	jalr	-548(ra) # 80000c1a <acquire>
  xticks = ticks;
    80002e46:	00006497          	auipc	s1,0x6
    80002e4a:	1ea4a483          	lw	s1,490(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e4e:	00014517          	auipc	a0,0x14
    80002e52:	28250513          	addi	a0,a0,642 # 800170d0 <tickslock>
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	e78080e7          	jalr	-392(ra) # 80000cce <release>
  return xticks;
}
    80002e5e:	02049513          	slli	a0,s1,0x20
    80002e62:	9101                	srli	a0,a0,0x20
    80002e64:	60e2                	ld	ra,24(sp)
    80002e66:	6442                	ld	s0,16(sp)
    80002e68:	64a2                	ld	s1,8(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    80002e76:	fe840593          	addi	a1,s0,-24
    80002e7a:	4501                	li	a0,0
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	d7c080e7          	jalr	-644(ra) # 80002bf8 <argaddr>
    80002e84:	87aa                	mv	a5,a0
    return -1;
    80002e86:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80002e88:	0007c863          	bltz	a5,80002e98 <sys_getprocs+0x2a>
  return(procinfo(addr));
    80002e8c:	fe843503          	ld	a0,-24(s0)
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	706080e7          	jalr	1798(ra) # 80002596 <procinfo>
}
    80002e98:	60e2                	ld	ra,24(sp)
    80002e9a:	6442                	ld	s0,16(sp)
    80002e9c:	6105                	addi	sp,sp,32
    80002e9e:	8082                	ret

0000000080002ea0 <sys_freepmem>:

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
    80002ea0:	1141                	addi	sp,sp,-16
    80002ea2:	e406                	sd	ra,8(sp)
    80002ea4:	e022                	sd	s0,0(sp)
    80002ea6:	0800                	addi	s0,sp,16
  int res = freepmem();
    80002ea8:	ffffe097          	auipc	ra,0xffffe
    80002eac:	c98080e7          	jalr	-872(ra) # 80000b40 <freepmem>
  return res;
}
    80002eb0:	2501                	sext.w	a0,a0
    80002eb2:	60a2                	ld	ra,8(sp)
    80002eb4:	6402                	ld	s0,0(sp)
    80002eb6:	0141                	addi	sp,sp,16
    80002eb8:	8082                	ret

0000000080002eba <sys_sbrk>:

// HW 4 - Task 2
// system call to allocate VIRTUAL memory on the disk
uint64
sys_sbrk(void){
    80002eba:	7179                	addi	sp,sp,-48
    80002ebc:	f406                	sd	ra,40(sp)
    80002ebe:	f022                	sd	s0,32(sp)
    80002ec0:	ec26                	sd	s1,24(sp)
    80002ec2:	e84a                	sd	s2,16(sp)
    80002ec4:	1800                	addi	s0,sp,48
  int new_size;
  int increment;

  // Retrieve the first system call argument, which is the number 
  // of bytes to increase the heap by, and store it in 'increment'
  if(argint(0, &increment) < 0){
    80002ec6:	fdc40593          	addi	a1,s0,-36
    80002eca:	4501                	li	a0,0
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	d0a080e7          	jalr	-758(ra) # 80002bd6 <argint>
    80002ed4:	87aa                	mv	a5,a0
    return -1;
    80002ed6:	557d                	li	a0,-1
  if(argint(0, &increment) < 0){
    80002ed8:	0207c263          	bltz	a5,80002efc <sys_sbrk+0x42>
  }

  // Get the current size of the process's heap from its process structure.]
  curr_size = myproc()->sz;
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	af6080e7          	jalr	-1290(ra) # 800019d2 <myproc>
    80002ee4:	4524                	lw	s1,72(a0)

  // Calculate the new size of the heap by adding 'increment' to the current size
  new_size = curr_size + increment;
    80002ee6:	fdc42903          	lw	s2,-36(s0)
    80002eea:	0099093b          	addw	s2,s2,s1

  // Check if the new size is below a memory safety threshold ('TRAPFRAME')
  // This is to ensure the heap does not overlap with the trap frame
  if(new_size < TRAPFRAME){
    // If the new size is valid, update the process's heap size to -> new_size
    myproc()->sz = new_size;
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	ae4080e7          	jalr	-1308(ra) # 800019d2 <myproc>
    80002ef6:	05253423          	sd	s2,72(a0)
    
    // Return the old heap end address before the increment
    return curr_size;
    80002efa:	8526                	mv	a0,s1
  }

  // If the new size is not valid or exceeds the memory safety threshold
  return -1;
}
    80002efc:	70a2                	ld	ra,40(sp)
    80002efe:	7402                	ld	s0,32(sp)
    80002f00:	64e2                	ld	s1,24(sp)
    80002f02:	6942                	ld	s2,16(sp)
    80002f04:	6145                	addi	sp,sp,48
    80002f06:	8082                	ret

0000000080002f08 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	e84a                	sd	s2,16(sp)
    80002f12:	e44e                	sd	s3,8(sp)
    80002f14:	e052                	sd	s4,0(sp)
    80002f16:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f18:	00005597          	auipc	a1,0x5
    80002f1c:	65058593          	addi	a1,a1,1616 # 80008568 <syscalls+0xc0>
    80002f20:	00014517          	auipc	a0,0x14
    80002f24:	1c850513          	addi	a0,a0,456 # 800170e8 <bcache>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	c62080e7          	jalr	-926(ra) # 80000b8a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f30:	0001c797          	auipc	a5,0x1c
    80002f34:	1b878793          	addi	a5,a5,440 # 8001f0e8 <bcache+0x8000>
    80002f38:	0001c717          	auipc	a4,0x1c
    80002f3c:	41870713          	addi	a4,a4,1048 # 8001f350 <bcache+0x8268>
    80002f40:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f44:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f48:	00014497          	auipc	s1,0x14
    80002f4c:	1b848493          	addi	s1,s1,440 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f50:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f52:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f54:	00005a17          	auipc	s4,0x5
    80002f58:	61ca0a13          	addi	s4,s4,1564 # 80008570 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f5c:	2b893783          	ld	a5,696(s2)
    80002f60:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f62:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f66:	85d2                	mv	a1,s4
    80002f68:	01048513          	addi	a0,s1,16
    80002f6c:	00001097          	auipc	ra,0x1
    80002f70:	4c2080e7          	jalr	1218(ra) # 8000442e <initsleeplock>
    bcache.head.next->prev = b;
    80002f74:	2b893783          	ld	a5,696(s2)
    80002f78:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f7a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7e:	45848493          	addi	s1,s1,1112
    80002f82:	fd349de3          	bne	s1,s3,80002f5c <binit+0x54>
  }
}
    80002f86:	70a2                	ld	ra,40(sp)
    80002f88:	7402                	ld	s0,32(sp)
    80002f8a:	64e2                	ld	s1,24(sp)
    80002f8c:	6942                	ld	s2,16(sp)
    80002f8e:	69a2                	ld	s3,8(sp)
    80002f90:	6a02                	ld	s4,0(sp)
    80002f92:	6145                	addi	sp,sp,48
    80002f94:	8082                	ret

0000000080002f96 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f96:	7179                	addi	sp,sp,-48
    80002f98:	f406                	sd	ra,40(sp)
    80002f9a:	f022                	sd	s0,32(sp)
    80002f9c:	ec26                	sd	s1,24(sp)
    80002f9e:	e84a                	sd	s2,16(sp)
    80002fa0:	e44e                	sd	s3,8(sp)
    80002fa2:	1800                	addi	s0,sp,48
    80002fa4:	892a                	mv	s2,a0
    80002fa6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fa8:	00014517          	auipc	a0,0x14
    80002fac:	14050513          	addi	a0,a0,320 # 800170e8 <bcache>
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	c6a080e7          	jalr	-918(ra) # 80000c1a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb8:	0001c497          	auipc	s1,0x1c
    80002fbc:	3e84b483          	ld	s1,1000(s1) # 8001f3a0 <bcache+0x82b8>
    80002fc0:	0001c797          	auipc	a5,0x1c
    80002fc4:	39078793          	addi	a5,a5,912 # 8001f350 <bcache+0x8268>
    80002fc8:	02f48f63          	beq	s1,a5,80003006 <bread+0x70>
    80002fcc:	873e                	mv	a4,a5
    80002fce:	a021                	j	80002fd6 <bread+0x40>
    80002fd0:	68a4                	ld	s1,80(s1)
    80002fd2:	02e48a63          	beq	s1,a4,80003006 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd6:	449c                	lw	a5,8(s1)
    80002fd8:	ff279ce3          	bne	a5,s2,80002fd0 <bread+0x3a>
    80002fdc:	44dc                	lw	a5,12(s1)
    80002fde:	ff3799e3          	bne	a5,s3,80002fd0 <bread+0x3a>
      b->refcnt++;
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	2785                	addiw	a5,a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	10050513          	addi	a0,a0,256 # 800170e8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	cde080e7          	jalr	-802(ra) # 80000cce <release>
      acquiresleep(&b->lock);
    80002ff8:	01048513          	addi	a0,s1,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	46c080e7          	jalr	1132(ra) # 80004468 <acquiresleep>
      return b;
    80003004:	a8b9                	j	80003062 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003006:	0001c497          	auipc	s1,0x1c
    8000300a:	3924b483          	ld	s1,914(s1) # 8001f398 <bcache+0x82b0>
    8000300e:	0001c797          	auipc	a5,0x1c
    80003012:	34278793          	addi	a5,a5,834 # 8001f350 <bcache+0x8268>
    80003016:	00f48863          	beq	s1,a5,80003026 <bread+0x90>
    8000301a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000301c:	40bc                	lw	a5,64(s1)
    8000301e:	cf81                	beqz	a5,80003036 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003020:	64a4                	ld	s1,72(s1)
    80003022:	fee49de3          	bne	s1,a4,8000301c <bread+0x86>
  panic("bget: no buffers");
    80003026:	00005517          	auipc	a0,0x5
    8000302a:	55250513          	addi	a0,a0,1362 # 80008578 <syscalls+0xd0>
    8000302e:	ffffd097          	auipc	ra,0xffffd
    80003032:	50c080e7          	jalr	1292(ra) # 8000053a <panic>
      b->dev = dev;
    80003036:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000303a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000303e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003042:	4785                	li	a5,1
    80003044:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	0a250513          	addi	a0,a0,162 # 800170e8 <bcache>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	c80080e7          	jalr	-896(ra) # 80000cce <release>
      acquiresleep(&b->lock);
    80003056:	01048513          	addi	a0,s1,16
    8000305a:	00001097          	auipc	ra,0x1
    8000305e:	40e080e7          	jalr	1038(ra) # 80004468 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003062:	409c                	lw	a5,0(s1)
    80003064:	cb89                	beqz	a5,80003076 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003066:	8526                	mv	a0,s1
    80003068:	70a2                	ld	ra,40(sp)
    8000306a:	7402                	ld	s0,32(sp)
    8000306c:	64e2                	ld	s1,24(sp)
    8000306e:	6942                	ld	s2,16(sp)
    80003070:	69a2                	ld	s3,8(sp)
    80003072:	6145                	addi	sp,sp,48
    80003074:	8082                	ret
    virtio_disk_rw(b, 0);
    80003076:	4581                	li	a1,0
    80003078:	8526                	mv	a0,s1
    8000307a:	00003097          	auipc	ra,0x3
    8000307e:	f28080e7          	jalr	-216(ra) # 80005fa2 <virtio_disk_rw>
    b->valid = 1;
    80003082:	4785                	li	a5,1
    80003084:	c09c                	sw	a5,0(s1)
  return b;
    80003086:	b7c5                	j	80003066 <bread+0xd0>

0000000080003088 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003094:	0541                	addi	a0,a0,16
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	46c080e7          	jalr	1132(ra) # 80004502 <holdingsleep>
    8000309e:	cd01                	beqz	a0,800030b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030a0:	4585                	li	a1,1
    800030a2:	8526                	mv	a0,s1
    800030a4:	00003097          	auipc	ra,0x3
    800030a8:	efe080e7          	jalr	-258(ra) # 80005fa2 <virtio_disk_rw>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret
    panic("bwrite");
    800030b6:	00005517          	auipc	a0,0x5
    800030ba:	4da50513          	addi	a0,a0,1242 # 80008590 <syscalls+0xe8>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	47c080e7          	jalr	1148(ra) # 8000053a <panic>

00000000800030c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030d4:	01050913          	addi	s2,a0,16
    800030d8:	854a                	mv	a0,s2
    800030da:	00001097          	auipc	ra,0x1
    800030de:	428080e7          	jalr	1064(ra) # 80004502 <holdingsleep>
    800030e2:	c92d                	beqz	a0,80003154 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030e4:	854a                	mv	a0,s2
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	3d8080e7          	jalr	984(ra) # 800044be <releasesleep>

  acquire(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	ffa50513          	addi	a0,a0,-6 # 800170e8 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	b24080e7          	jalr	-1244(ra) # 80000c1a <acquire>
  b->refcnt--;
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	37fd                	addiw	a5,a5,-1
    80003102:	0007871b          	sext.w	a4,a5
    80003106:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003108:	eb05                	bnez	a4,80003138 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000310a:	68bc                	ld	a5,80(s1)
    8000310c:	64b8                	ld	a4,72(s1)
    8000310e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003110:	64bc                	ld	a5,72(s1)
    80003112:	68b8                	ld	a4,80(s1)
    80003114:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003116:	0001c797          	auipc	a5,0x1c
    8000311a:	fd278793          	addi	a5,a5,-46 # 8001f0e8 <bcache+0x8000>
    8000311e:	2b87b703          	ld	a4,696(a5)
    80003122:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003124:	0001c717          	auipc	a4,0x1c
    80003128:	22c70713          	addi	a4,a4,556 # 8001f350 <bcache+0x8268>
    8000312c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000312e:	2b87b703          	ld	a4,696(a5)
    80003132:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003134:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003138:	00014517          	auipc	a0,0x14
    8000313c:	fb050513          	addi	a0,a0,-80 # 800170e8 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	b8e080e7          	jalr	-1138(ra) # 80000cce <release>
}
    80003148:	60e2                	ld	ra,24(sp)
    8000314a:	6442                	ld	s0,16(sp)
    8000314c:	64a2                	ld	s1,8(sp)
    8000314e:	6902                	ld	s2,0(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret
    panic("brelse");
    80003154:	00005517          	auipc	a0,0x5
    80003158:	44450513          	addi	a0,a0,1092 # 80008598 <syscalls+0xf0>
    8000315c:	ffffd097          	auipc	ra,0xffffd
    80003160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080003164 <bpin>:

void
bpin(struct buf *b) {
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003170:	00014517          	auipc	a0,0x14
    80003174:	f7850513          	addi	a0,a0,-136 # 800170e8 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	aa2080e7          	jalr	-1374(ra) # 80000c1a <acquire>
  b->refcnt++;
    80003180:	40bc                	lw	a5,64(s1)
    80003182:	2785                	addiw	a5,a5,1
    80003184:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003186:	00014517          	auipc	a0,0x14
    8000318a:	f6250513          	addi	a0,a0,-158 # 800170e8 <bcache>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	b40080e7          	jalr	-1216(ra) # 80000cce <release>
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <bunpin>:

void
bunpin(struct buf *b) {
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	1000                	addi	s0,sp,32
    800031aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	f3c50513          	addi	a0,a0,-196 # 800170e8 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	a66080e7          	jalr	-1434(ra) # 80000c1a <acquire>
  b->refcnt--;
    800031bc:	40bc                	lw	a5,64(s1)
    800031be:	37fd                	addiw	a5,a5,-1
    800031c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	f2650513          	addi	a0,a0,-218 # 800170e8 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	b04080e7          	jalr	-1276(ra) # 80000cce <release>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ea:	00d5d59b          	srliw	a1,a1,0xd
    800031ee:	0001c797          	auipc	a5,0x1c
    800031f2:	5d67a783          	lw	a5,1494(a5) # 8001f7c4 <sb+0x1c>
    800031f6:	9dbd                	addw	a1,a1,a5
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	d9e080e7          	jalr	-610(ra) # 80002f96 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003200:	0074f713          	andi	a4,s1,7
    80003204:	4785                	li	a5,1
    80003206:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000320a:	14ce                	slli	s1,s1,0x33
    8000320c:	90d9                	srli	s1,s1,0x36
    8000320e:	00950733          	add	a4,a0,s1
    80003212:	05874703          	lbu	a4,88(a4)
    80003216:	00e7f6b3          	and	a3,a5,a4
    8000321a:	c69d                	beqz	a3,80003248 <bfree+0x6c>
    8000321c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000321e:	94aa                	add	s1,s1,a0
    80003220:	fff7c793          	not	a5,a5
    80003224:	8f7d                	and	a4,a4,a5
    80003226:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000322a:	00001097          	auipc	ra,0x1
    8000322e:	120080e7          	jalr	288(ra) # 8000434a <log_write>
  brelse(bp);
    80003232:	854a                	mv	a0,s2
    80003234:	00000097          	auipc	ra,0x0
    80003238:	e92080e7          	jalr	-366(ra) # 800030c6 <brelse>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6902                	ld	s2,0(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret
    panic("freeing free block");
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	35850513          	addi	a0,a0,856 # 800085a0 <syscalls+0xf8>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	2ea080e7          	jalr	746(ra) # 8000053a <panic>

0000000080003258 <balloc>:
{
    80003258:	711d                	addi	sp,sp,-96
    8000325a:	ec86                	sd	ra,88(sp)
    8000325c:	e8a2                	sd	s0,80(sp)
    8000325e:	e4a6                	sd	s1,72(sp)
    80003260:	e0ca                	sd	s2,64(sp)
    80003262:	fc4e                	sd	s3,56(sp)
    80003264:	f852                	sd	s4,48(sp)
    80003266:	f456                	sd	s5,40(sp)
    80003268:	f05a                	sd	s6,32(sp)
    8000326a:	ec5e                	sd	s7,24(sp)
    8000326c:	e862                	sd	s8,16(sp)
    8000326e:	e466                	sd	s9,8(sp)
    80003270:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003272:	0001c797          	auipc	a5,0x1c
    80003276:	53a7a783          	lw	a5,1338(a5) # 8001f7ac <sb+0x4>
    8000327a:	cbc1                	beqz	a5,8000330a <balloc+0xb2>
    8000327c:	8baa                	mv	s7,a0
    8000327e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003280:	0001cb17          	auipc	s6,0x1c
    80003284:	528b0b13          	addi	s6,s6,1320 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003288:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000328a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000328e:	6c89                	lui	s9,0x2
    80003290:	a831                	j	800032ac <balloc+0x54>
    brelse(bp);
    80003292:	854a                	mv	a0,s2
    80003294:	00000097          	auipc	ra,0x0
    80003298:	e32080e7          	jalr	-462(ra) # 800030c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000329c:	015c87bb          	addw	a5,s9,s5
    800032a0:	00078a9b          	sext.w	s5,a5
    800032a4:	004b2703          	lw	a4,4(s6)
    800032a8:	06eaf163          	bgeu	s5,a4,8000330a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800032ac:	41fad79b          	sraiw	a5,s5,0x1f
    800032b0:	0137d79b          	srliw	a5,a5,0x13
    800032b4:	015787bb          	addw	a5,a5,s5
    800032b8:	40d7d79b          	sraiw	a5,a5,0xd
    800032bc:	01cb2583          	lw	a1,28(s6)
    800032c0:	9dbd                	addw	a1,a1,a5
    800032c2:	855e                	mv	a0,s7
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	cd2080e7          	jalr	-814(ra) # 80002f96 <bread>
    800032cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ce:	004b2503          	lw	a0,4(s6)
    800032d2:	000a849b          	sext.w	s1,s5
    800032d6:	8762                	mv	a4,s8
    800032d8:	faa4fde3          	bgeu	s1,a0,80003292 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032dc:	00777693          	andi	a3,a4,7
    800032e0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032e4:	41f7579b          	sraiw	a5,a4,0x1f
    800032e8:	01d7d79b          	srliw	a5,a5,0x1d
    800032ec:	9fb9                	addw	a5,a5,a4
    800032ee:	4037d79b          	sraiw	a5,a5,0x3
    800032f2:	00f90633          	add	a2,s2,a5
    800032f6:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800032fa:	00c6f5b3          	and	a1,a3,a2
    800032fe:	cd91                	beqz	a1,8000331a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003300:	2705                	addiw	a4,a4,1
    80003302:	2485                	addiw	s1,s1,1
    80003304:	fd471ae3          	bne	a4,s4,800032d8 <balloc+0x80>
    80003308:	b769                	j	80003292 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000330a:	00005517          	auipc	a0,0x5
    8000330e:	2ae50513          	addi	a0,a0,686 # 800085b8 <syscalls+0x110>
    80003312:	ffffd097          	auipc	ra,0xffffd
    80003316:	228080e7          	jalr	552(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000331a:	97ca                	add	a5,a5,s2
    8000331c:	8e55                	or	a2,a2,a3
    8000331e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003322:	854a                	mv	a0,s2
    80003324:	00001097          	auipc	ra,0x1
    80003328:	026080e7          	jalr	38(ra) # 8000434a <log_write>
        brelse(bp);
    8000332c:	854a                	mv	a0,s2
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	d98080e7          	jalr	-616(ra) # 800030c6 <brelse>
  bp = bread(dev, bno);
    80003336:	85a6                	mv	a1,s1
    80003338:	855e                	mv	a0,s7
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	c5c080e7          	jalr	-932(ra) # 80002f96 <bread>
    80003342:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003344:	40000613          	li	a2,1024
    80003348:	4581                	li	a1,0
    8000334a:	05850513          	addi	a0,a0,88
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	9c8080e7          	jalr	-1592(ra) # 80000d16 <memset>
  log_write(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	ff2080e7          	jalr	-14(ra) # 8000434a <log_write>
  brelse(bp);
    80003360:	854a                	mv	a0,s2
    80003362:	00000097          	auipc	ra,0x0
    80003366:	d64080e7          	jalr	-668(ra) # 800030c6 <brelse>
}
    8000336a:	8526                	mv	a0,s1
    8000336c:	60e6                	ld	ra,88(sp)
    8000336e:	6446                	ld	s0,80(sp)
    80003370:	64a6                	ld	s1,72(sp)
    80003372:	6906                	ld	s2,64(sp)
    80003374:	79e2                	ld	s3,56(sp)
    80003376:	7a42                	ld	s4,48(sp)
    80003378:	7aa2                	ld	s5,40(sp)
    8000337a:	7b02                	ld	s6,32(sp)
    8000337c:	6be2                	ld	s7,24(sp)
    8000337e:	6c42                	ld	s8,16(sp)
    80003380:	6ca2                	ld	s9,8(sp)
    80003382:	6125                	addi	sp,sp,96
    80003384:	8082                	ret

0000000080003386 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003386:	7179                	addi	sp,sp,-48
    80003388:	f406                	sd	ra,40(sp)
    8000338a:	f022                	sd	s0,32(sp)
    8000338c:	ec26                	sd	s1,24(sp)
    8000338e:	e84a                	sd	s2,16(sp)
    80003390:	e44e                	sd	s3,8(sp)
    80003392:	e052                	sd	s4,0(sp)
    80003394:	1800                	addi	s0,sp,48
    80003396:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003398:	47ad                	li	a5,11
    8000339a:	04b7fe63          	bgeu	a5,a1,800033f6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000339e:	ff45849b          	addiw	s1,a1,-12
    800033a2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033a6:	0ff00793          	li	a5,255
    800033aa:	0ae7e463          	bltu	a5,a4,80003452 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033ae:	08052583          	lw	a1,128(a0)
    800033b2:	c5b5                	beqz	a1,8000341e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033b4:	00092503          	lw	a0,0(s2)
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	bde080e7          	jalr	-1058(ra) # 80002f96 <bread>
    800033c0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033c2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033c6:	02049713          	slli	a4,s1,0x20
    800033ca:	01e75593          	srli	a1,a4,0x1e
    800033ce:	00b784b3          	add	s1,a5,a1
    800033d2:	0004a983          	lw	s3,0(s1)
    800033d6:	04098e63          	beqz	s3,80003432 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033da:	8552                	mv	a0,s4
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	cea080e7          	jalr	-790(ra) # 800030c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e4:	854e                	mv	a0,s3
    800033e6:	70a2                	ld	ra,40(sp)
    800033e8:	7402                	ld	s0,32(sp)
    800033ea:	64e2                	ld	s1,24(sp)
    800033ec:	6942                	ld	s2,16(sp)
    800033ee:	69a2                	ld	s3,8(sp)
    800033f0:	6a02                	ld	s4,0(sp)
    800033f2:	6145                	addi	sp,sp,48
    800033f4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033f6:	02059793          	slli	a5,a1,0x20
    800033fa:	01e7d593          	srli	a1,a5,0x1e
    800033fe:	00b504b3          	add	s1,a0,a1
    80003402:	0504a983          	lw	s3,80(s1)
    80003406:	fc099fe3          	bnez	s3,800033e4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000340a:	4108                	lw	a0,0(a0)
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	e4c080e7          	jalr	-436(ra) # 80003258 <balloc>
    80003414:	0005099b          	sext.w	s3,a0
    80003418:	0534a823          	sw	s3,80(s1)
    8000341c:	b7e1                	j	800033e4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000341e:	4108                	lw	a0,0(a0)
    80003420:	00000097          	auipc	ra,0x0
    80003424:	e38080e7          	jalr	-456(ra) # 80003258 <balloc>
    80003428:	0005059b          	sext.w	a1,a0
    8000342c:	08b92023          	sw	a1,128(s2)
    80003430:	b751                	j	800033b4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003432:	00092503          	lw	a0,0(s2)
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	e22080e7          	jalr	-478(ra) # 80003258 <balloc>
    8000343e:	0005099b          	sext.w	s3,a0
    80003442:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003446:	8552                	mv	a0,s4
    80003448:	00001097          	auipc	ra,0x1
    8000344c:	f02080e7          	jalr	-254(ra) # 8000434a <log_write>
    80003450:	b769                	j	800033da <bmap+0x54>
  panic("bmap: out of range");
    80003452:	00005517          	auipc	a0,0x5
    80003456:	17e50513          	addi	a0,a0,382 # 800085d0 <syscalls+0x128>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	0e0080e7          	jalr	224(ra) # 8000053a <panic>

0000000080003462 <iget>:
{
    80003462:	7179                	addi	sp,sp,-48
    80003464:	f406                	sd	ra,40(sp)
    80003466:	f022                	sd	s0,32(sp)
    80003468:	ec26                	sd	s1,24(sp)
    8000346a:	e84a                	sd	s2,16(sp)
    8000346c:	e44e                	sd	s3,8(sp)
    8000346e:	e052                	sd	s4,0(sp)
    80003470:	1800                	addi	s0,sp,48
    80003472:	89aa                	mv	s3,a0
    80003474:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003476:	0001c517          	auipc	a0,0x1c
    8000347a:	35250513          	addi	a0,a0,850 # 8001f7c8 <itable>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	79c080e7          	jalr	1948(ra) # 80000c1a <acquire>
  empty = 0;
    80003486:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003488:	0001c497          	auipc	s1,0x1c
    8000348c:	35848493          	addi	s1,s1,856 # 8001f7e0 <itable+0x18>
    80003490:	0001e697          	auipc	a3,0x1e
    80003494:	de068693          	addi	a3,a3,-544 # 80021270 <log>
    80003498:	a039                	j	800034a6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349a:	02090b63          	beqz	s2,800034d0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349e:	08848493          	addi	s1,s1,136
    800034a2:	02d48a63          	beq	s1,a3,800034d6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a6:	449c                	lw	a5,8(s1)
    800034a8:	fef059e3          	blez	a5,8000349a <iget+0x38>
    800034ac:	4098                	lw	a4,0(s1)
    800034ae:	ff3716e3          	bne	a4,s3,8000349a <iget+0x38>
    800034b2:	40d8                	lw	a4,4(s1)
    800034b4:	ff4713e3          	bne	a4,s4,8000349a <iget+0x38>
      ip->ref++;
    800034b8:	2785                	addiw	a5,a5,1
    800034ba:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034bc:	0001c517          	auipc	a0,0x1c
    800034c0:	30c50513          	addi	a0,a0,780 # 8001f7c8 <itable>
    800034c4:	ffffe097          	auipc	ra,0xffffe
    800034c8:	80a080e7          	jalr	-2038(ra) # 80000cce <release>
      return ip;
    800034cc:	8926                	mv	s2,s1
    800034ce:	a03d                	j	800034fc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d0:	f7f9                	bnez	a5,8000349e <iget+0x3c>
    800034d2:	8926                	mv	s2,s1
    800034d4:	b7e9                	j	8000349e <iget+0x3c>
  if(empty == 0)
    800034d6:	02090c63          	beqz	s2,8000350e <iget+0xac>
  ip->dev = dev;
    800034da:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034de:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034e2:	4785                	li	a5,1
    800034e4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034e8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034ec:	0001c517          	auipc	a0,0x1c
    800034f0:	2dc50513          	addi	a0,a0,732 # 8001f7c8 <itable>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	7da080e7          	jalr	2010(ra) # 80000cce <release>
}
    800034fc:	854a                	mv	a0,s2
    800034fe:	70a2                	ld	ra,40(sp)
    80003500:	7402                	ld	s0,32(sp)
    80003502:	64e2                	ld	s1,24(sp)
    80003504:	6942                	ld	s2,16(sp)
    80003506:	69a2                	ld	s3,8(sp)
    80003508:	6a02                	ld	s4,0(sp)
    8000350a:	6145                	addi	sp,sp,48
    8000350c:	8082                	ret
    panic("iget: no inodes");
    8000350e:	00005517          	auipc	a0,0x5
    80003512:	0da50513          	addi	a0,a0,218 # 800085e8 <syscalls+0x140>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	024080e7          	jalr	36(ra) # 8000053a <panic>

000000008000351e <fsinit>:
fsinit(int dev) {
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	e84a                	sd	s2,16(sp)
    80003528:	e44e                	sd	s3,8(sp)
    8000352a:	1800                	addi	s0,sp,48
    8000352c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000352e:	4585                	li	a1,1
    80003530:	00000097          	auipc	ra,0x0
    80003534:	a66080e7          	jalr	-1434(ra) # 80002f96 <bread>
    80003538:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000353a:	0001c997          	auipc	s3,0x1c
    8000353e:	26e98993          	addi	s3,s3,622 # 8001f7a8 <sb>
    80003542:	02000613          	li	a2,32
    80003546:	05850593          	addi	a1,a0,88
    8000354a:	854e                	mv	a0,s3
    8000354c:	ffffe097          	auipc	ra,0xffffe
    80003550:	826080e7          	jalr	-2010(ra) # 80000d72 <memmove>
  brelse(bp);
    80003554:	8526                	mv	a0,s1
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	b70080e7          	jalr	-1168(ra) # 800030c6 <brelse>
  if(sb.magic != FSMAGIC)
    8000355e:	0009a703          	lw	a4,0(s3)
    80003562:	102037b7          	lui	a5,0x10203
    80003566:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000356a:	02f71263          	bne	a4,a5,8000358e <fsinit+0x70>
  initlog(dev, &sb);
    8000356e:	0001c597          	auipc	a1,0x1c
    80003572:	23a58593          	addi	a1,a1,570 # 8001f7a8 <sb>
    80003576:	854a                	mv	a0,s2
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	b56080e7          	jalr	-1194(ra) # 800040ce <initlog>
}
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    panic("invalid file system");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	06a50513          	addi	a0,a0,106 # 800085f8 <syscalls+0x150>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	fa4080e7          	jalr	-92(ra) # 8000053a <panic>

000000008000359e <iinit>:
{
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035ac:	00005597          	auipc	a1,0x5
    800035b0:	06458593          	addi	a1,a1,100 # 80008610 <syscalls+0x168>
    800035b4:	0001c517          	auipc	a0,0x1c
    800035b8:	21450513          	addi	a0,a0,532 # 8001f7c8 <itable>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	5ce080e7          	jalr	1486(ra) # 80000b8a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035c4:	0001c497          	auipc	s1,0x1c
    800035c8:	22c48493          	addi	s1,s1,556 # 8001f7f0 <itable+0x28>
    800035cc:	0001e997          	auipc	s3,0x1e
    800035d0:	cb498993          	addi	s3,s3,-844 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035d4:	00005917          	auipc	s2,0x5
    800035d8:	04490913          	addi	s2,s2,68 # 80008618 <syscalls+0x170>
    800035dc:	85ca                	mv	a1,s2
    800035de:	8526                	mv	a0,s1
    800035e0:	00001097          	auipc	ra,0x1
    800035e4:	e4e080e7          	jalr	-434(ra) # 8000442e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035e8:	08848493          	addi	s1,s1,136
    800035ec:	ff3498e3          	bne	s1,s3,800035dc <iinit+0x3e>
}
    800035f0:	70a2                	ld	ra,40(sp)
    800035f2:	7402                	ld	s0,32(sp)
    800035f4:	64e2                	ld	s1,24(sp)
    800035f6:	6942                	ld	s2,16(sp)
    800035f8:	69a2                	ld	s3,8(sp)
    800035fa:	6145                	addi	sp,sp,48
    800035fc:	8082                	ret

00000000800035fe <ialloc>:
{
    800035fe:	715d                	addi	sp,sp,-80
    80003600:	e486                	sd	ra,72(sp)
    80003602:	e0a2                	sd	s0,64(sp)
    80003604:	fc26                	sd	s1,56(sp)
    80003606:	f84a                	sd	s2,48(sp)
    80003608:	f44e                	sd	s3,40(sp)
    8000360a:	f052                	sd	s4,32(sp)
    8000360c:	ec56                	sd	s5,24(sp)
    8000360e:	e85a                	sd	s6,16(sp)
    80003610:	e45e                	sd	s7,8(sp)
    80003612:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003614:	0001c717          	auipc	a4,0x1c
    80003618:	1a072703          	lw	a4,416(a4) # 8001f7b4 <sb+0xc>
    8000361c:	4785                	li	a5,1
    8000361e:	04e7fa63          	bgeu	a5,a4,80003672 <ialloc+0x74>
    80003622:	8aaa                	mv	s5,a0
    80003624:	8bae                	mv	s7,a1
    80003626:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003628:	0001ca17          	auipc	s4,0x1c
    8000362c:	180a0a13          	addi	s4,s4,384 # 8001f7a8 <sb>
    80003630:	00048b1b          	sext.w	s6,s1
    80003634:	0044d593          	srli	a1,s1,0x4
    80003638:	018a2783          	lw	a5,24(s4)
    8000363c:	9dbd                	addw	a1,a1,a5
    8000363e:	8556                	mv	a0,s5
    80003640:	00000097          	auipc	ra,0x0
    80003644:	956080e7          	jalr	-1706(ra) # 80002f96 <bread>
    80003648:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000364a:	05850993          	addi	s3,a0,88
    8000364e:	00f4f793          	andi	a5,s1,15
    80003652:	079a                	slli	a5,a5,0x6
    80003654:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003656:	00099783          	lh	a5,0(s3)
    8000365a:	c785                	beqz	a5,80003682 <ialloc+0x84>
    brelse(bp);
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	a6a080e7          	jalr	-1430(ra) # 800030c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003664:	0485                	addi	s1,s1,1
    80003666:	00ca2703          	lw	a4,12(s4)
    8000366a:	0004879b          	sext.w	a5,s1
    8000366e:	fce7e1e3          	bltu	a5,a4,80003630 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	fae50513          	addi	a0,a0,-82 # 80008620 <syscalls+0x178>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ec0080e7          	jalr	-320(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003682:	04000613          	li	a2,64
    80003686:	4581                	li	a1,0
    80003688:	854e                	mv	a0,s3
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	68c080e7          	jalr	1676(ra) # 80000d16 <memset>
      dip->type = type;
    80003692:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003696:	854a                	mv	a0,s2
    80003698:	00001097          	auipc	ra,0x1
    8000369c:	cb2080e7          	jalr	-846(ra) # 8000434a <log_write>
      brelse(bp);
    800036a0:	854a                	mv	a0,s2
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	a24080e7          	jalr	-1500(ra) # 800030c6 <brelse>
      return iget(dev, inum);
    800036aa:	85da                	mv	a1,s6
    800036ac:	8556                	mv	a0,s5
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	db4080e7          	jalr	-588(ra) # 80003462 <iget>
}
    800036b6:	60a6                	ld	ra,72(sp)
    800036b8:	6406                	ld	s0,64(sp)
    800036ba:	74e2                	ld	s1,56(sp)
    800036bc:	7942                	ld	s2,48(sp)
    800036be:	79a2                	ld	s3,40(sp)
    800036c0:	7a02                	ld	s4,32(sp)
    800036c2:	6ae2                	ld	s5,24(sp)
    800036c4:	6b42                	ld	s6,16(sp)
    800036c6:	6ba2                	ld	s7,8(sp)
    800036c8:	6161                	addi	sp,sp,80
    800036ca:	8082                	ret

00000000800036cc <iupdate>:
{
    800036cc:	1101                	addi	sp,sp,-32
    800036ce:	ec06                	sd	ra,24(sp)
    800036d0:	e822                	sd	s0,16(sp)
    800036d2:	e426                	sd	s1,8(sp)
    800036d4:	e04a                	sd	s2,0(sp)
    800036d6:	1000                	addi	s0,sp,32
    800036d8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036da:	415c                	lw	a5,4(a0)
    800036dc:	0047d79b          	srliw	a5,a5,0x4
    800036e0:	0001c597          	auipc	a1,0x1c
    800036e4:	0e05a583          	lw	a1,224(a1) # 8001f7c0 <sb+0x18>
    800036e8:	9dbd                	addw	a1,a1,a5
    800036ea:	4108                	lw	a0,0(a0)
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	8aa080e7          	jalr	-1878(ra) # 80002f96 <bread>
    800036f4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f6:	05850793          	addi	a5,a0,88
    800036fa:	40d8                	lw	a4,4(s1)
    800036fc:	8b3d                	andi	a4,a4,15
    800036fe:	071a                	slli	a4,a4,0x6
    80003700:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003702:	04449703          	lh	a4,68(s1)
    80003706:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000370a:	04649703          	lh	a4,70(s1)
    8000370e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003712:	04849703          	lh	a4,72(s1)
    80003716:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000371a:	04a49703          	lh	a4,74(s1)
    8000371e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003722:	44f8                	lw	a4,76(s1)
    80003724:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003726:	03400613          	li	a2,52
    8000372a:	05048593          	addi	a1,s1,80
    8000372e:	00c78513          	addi	a0,a5,12
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	640080e7          	jalr	1600(ra) # 80000d72 <memmove>
  log_write(bp);
    8000373a:	854a                	mv	a0,s2
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	c0e080e7          	jalr	-1010(ra) # 8000434a <log_write>
  brelse(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	980080e7          	jalr	-1664(ra) # 800030c6 <brelse>
}
    8000374e:	60e2                	ld	ra,24(sp)
    80003750:	6442                	ld	s0,16(sp)
    80003752:	64a2                	ld	s1,8(sp)
    80003754:	6902                	ld	s2,0(sp)
    80003756:	6105                	addi	sp,sp,32
    80003758:	8082                	ret

000000008000375a <idup>:
{
    8000375a:	1101                	addi	sp,sp,-32
    8000375c:	ec06                	sd	ra,24(sp)
    8000375e:	e822                	sd	s0,16(sp)
    80003760:	e426                	sd	s1,8(sp)
    80003762:	1000                	addi	s0,sp,32
    80003764:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003766:	0001c517          	auipc	a0,0x1c
    8000376a:	06250513          	addi	a0,a0,98 # 8001f7c8 <itable>
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	4ac080e7          	jalr	1196(ra) # 80000c1a <acquire>
  ip->ref++;
    80003776:	449c                	lw	a5,8(s1)
    80003778:	2785                	addiw	a5,a5,1
    8000377a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000377c:	0001c517          	auipc	a0,0x1c
    80003780:	04c50513          	addi	a0,a0,76 # 8001f7c8 <itable>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	54a080e7          	jalr	1354(ra) # 80000cce <release>
}
    8000378c:	8526                	mv	a0,s1
    8000378e:	60e2                	ld	ra,24(sp)
    80003790:	6442                	ld	s0,16(sp)
    80003792:	64a2                	ld	s1,8(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret

0000000080003798 <ilock>:
{
    80003798:	1101                	addi	sp,sp,-32
    8000379a:	ec06                	sd	ra,24(sp)
    8000379c:	e822                	sd	s0,16(sp)
    8000379e:	e426                	sd	s1,8(sp)
    800037a0:	e04a                	sd	s2,0(sp)
    800037a2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a4:	c115                	beqz	a0,800037c8 <ilock+0x30>
    800037a6:	84aa                	mv	s1,a0
    800037a8:	451c                	lw	a5,8(a0)
    800037aa:	00f05f63          	blez	a5,800037c8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037ae:	0541                	addi	a0,a0,16
    800037b0:	00001097          	auipc	ra,0x1
    800037b4:	cb8080e7          	jalr	-840(ra) # 80004468 <acquiresleep>
  if(ip->valid == 0){
    800037b8:	40bc                	lw	a5,64(s1)
    800037ba:	cf99                	beqz	a5,800037d8 <ilock+0x40>
}
    800037bc:	60e2                	ld	ra,24(sp)
    800037be:	6442                	ld	s0,16(sp)
    800037c0:	64a2                	ld	s1,8(sp)
    800037c2:	6902                	ld	s2,0(sp)
    800037c4:	6105                	addi	sp,sp,32
    800037c6:	8082                	ret
    panic("ilock");
    800037c8:	00005517          	auipc	a0,0x5
    800037cc:	e7050513          	addi	a0,a0,-400 # 80008638 <syscalls+0x190>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	d6a080e7          	jalr	-662(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d8:	40dc                	lw	a5,4(s1)
    800037da:	0047d79b          	srliw	a5,a5,0x4
    800037de:	0001c597          	auipc	a1,0x1c
    800037e2:	fe25a583          	lw	a1,-30(a1) # 8001f7c0 <sb+0x18>
    800037e6:	9dbd                	addw	a1,a1,a5
    800037e8:	4088                	lw	a0,0(s1)
    800037ea:	fffff097          	auipc	ra,0xfffff
    800037ee:	7ac080e7          	jalr	1964(ra) # 80002f96 <bread>
    800037f2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f4:	05850593          	addi	a1,a0,88
    800037f8:	40dc                	lw	a5,4(s1)
    800037fa:	8bbd                	andi	a5,a5,15
    800037fc:	079a                	slli	a5,a5,0x6
    800037fe:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003800:	00059783          	lh	a5,0(a1)
    80003804:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003808:	00259783          	lh	a5,2(a1)
    8000380c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003810:	00459783          	lh	a5,4(a1)
    80003814:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003818:	00659783          	lh	a5,6(a1)
    8000381c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003820:	459c                	lw	a5,8(a1)
    80003822:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003824:	03400613          	li	a2,52
    80003828:	05b1                	addi	a1,a1,12
    8000382a:	05048513          	addi	a0,s1,80
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	544080e7          	jalr	1348(ra) # 80000d72 <memmove>
    brelse(bp);
    80003836:	854a                	mv	a0,s2
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	88e080e7          	jalr	-1906(ra) # 800030c6 <brelse>
    ip->valid = 1;
    80003840:	4785                	li	a5,1
    80003842:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003844:	04449783          	lh	a5,68(s1)
    80003848:	fbb5                	bnez	a5,800037bc <ilock+0x24>
      panic("ilock: no type");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	df650513          	addi	a0,a0,-522 # 80008640 <syscalls+0x198>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	ce8080e7          	jalr	-792(ra) # 8000053a <panic>

000000008000385a <iunlock>:
{
    8000385a:	1101                	addi	sp,sp,-32
    8000385c:	ec06                	sd	ra,24(sp)
    8000385e:	e822                	sd	s0,16(sp)
    80003860:	e426                	sd	s1,8(sp)
    80003862:	e04a                	sd	s2,0(sp)
    80003864:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003866:	c905                	beqz	a0,80003896 <iunlock+0x3c>
    80003868:	84aa                	mv	s1,a0
    8000386a:	01050913          	addi	s2,a0,16
    8000386e:	854a                	mv	a0,s2
    80003870:	00001097          	auipc	ra,0x1
    80003874:	c92080e7          	jalr	-878(ra) # 80004502 <holdingsleep>
    80003878:	cd19                	beqz	a0,80003896 <iunlock+0x3c>
    8000387a:	449c                	lw	a5,8(s1)
    8000387c:	00f05d63          	blez	a5,80003896 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003880:	854a                	mv	a0,s2
    80003882:	00001097          	auipc	ra,0x1
    80003886:	c3c080e7          	jalr	-964(ra) # 800044be <releasesleep>
}
    8000388a:	60e2                	ld	ra,24(sp)
    8000388c:	6442                	ld	s0,16(sp)
    8000388e:	64a2                	ld	s1,8(sp)
    80003890:	6902                	ld	s2,0(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret
    panic("iunlock");
    80003896:	00005517          	auipc	a0,0x5
    8000389a:	dba50513          	addi	a0,a0,-582 # 80008650 <syscalls+0x1a8>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	c9c080e7          	jalr	-868(ra) # 8000053a <panic>

00000000800038a6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038a6:	7179                	addi	sp,sp,-48
    800038a8:	f406                	sd	ra,40(sp)
    800038aa:	f022                	sd	s0,32(sp)
    800038ac:	ec26                	sd	s1,24(sp)
    800038ae:	e84a                	sd	s2,16(sp)
    800038b0:	e44e                	sd	s3,8(sp)
    800038b2:	e052                	sd	s4,0(sp)
    800038b4:	1800                	addi	s0,sp,48
    800038b6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038b8:	05050493          	addi	s1,a0,80
    800038bc:	08050913          	addi	s2,a0,128
    800038c0:	a021                	j	800038c8 <itrunc+0x22>
    800038c2:	0491                	addi	s1,s1,4
    800038c4:	01248d63          	beq	s1,s2,800038de <itrunc+0x38>
    if(ip->addrs[i]){
    800038c8:	408c                	lw	a1,0(s1)
    800038ca:	dde5                	beqz	a1,800038c2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	90c080e7          	jalr	-1780(ra) # 800031dc <bfree>
      ip->addrs[i] = 0;
    800038d8:	0004a023          	sw	zero,0(s1)
    800038dc:	b7dd                	j	800038c2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038de:	0809a583          	lw	a1,128(s3)
    800038e2:	e185                	bnez	a1,80003902 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038e8:	854e                	mv	a0,s3
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	de2080e7          	jalr	-542(ra) # 800036cc <iupdate>
}
    800038f2:	70a2                	ld	ra,40(sp)
    800038f4:	7402                	ld	s0,32(sp)
    800038f6:	64e2                	ld	s1,24(sp)
    800038f8:	6942                	ld	s2,16(sp)
    800038fa:	69a2                	ld	s3,8(sp)
    800038fc:	6a02                	ld	s4,0(sp)
    800038fe:	6145                	addi	sp,sp,48
    80003900:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003902:	0009a503          	lw	a0,0(s3)
    80003906:	fffff097          	auipc	ra,0xfffff
    8000390a:	690080e7          	jalr	1680(ra) # 80002f96 <bread>
    8000390e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003910:	05850493          	addi	s1,a0,88
    80003914:	45850913          	addi	s2,a0,1112
    80003918:	a021                	j	80003920 <itrunc+0x7a>
    8000391a:	0491                	addi	s1,s1,4
    8000391c:	01248b63          	beq	s1,s2,80003932 <itrunc+0x8c>
      if(a[j])
    80003920:	408c                	lw	a1,0(s1)
    80003922:	dde5                	beqz	a1,8000391a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003924:	0009a503          	lw	a0,0(s3)
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	8b4080e7          	jalr	-1868(ra) # 800031dc <bfree>
    80003930:	b7ed                	j	8000391a <itrunc+0x74>
    brelse(bp);
    80003932:	8552                	mv	a0,s4
    80003934:	fffff097          	auipc	ra,0xfffff
    80003938:	792080e7          	jalr	1938(ra) # 800030c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000393c:	0809a583          	lw	a1,128(s3)
    80003940:	0009a503          	lw	a0,0(s3)
    80003944:	00000097          	auipc	ra,0x0
    80003948:	898080e7          	jalr	-1896(ra) # 800031dc <bfree>
    ip->addrs[NDIRECT] = 0;
    8000394c:	0809a023          	sw	zero,128(s3)
    80003950:	bf51                	j	800038e4 <itrunc+0x3e>

0000000080003952 <iput>:
{
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	e426                	sd	s1,8(sp)
    8000395a:	e04a                	sd	s2,0(sp)
    8000395c:	1000                	addi	s0,sp,32
    8000395e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003960:	0001c517          	auipc	a0,0x1c
    80003964:	e6850513          	addi	a0,a0,-408 # 8001f7c8 <itable>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	2b2080e7          	jalr	690(ra) # 80000c1a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003970:	4498                	lw	a4,8(s1)
    80003972:	4785                	li	a5,1
    80003974:	02f70363          	beq	a4,a5,8000399a <iput+0x48>
  ip->ref--;
    80003978:	449c                	lw	a5,8(s1)
    8000397a:	37fd                	addiw	a5,a5,-1
    8000397c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000397e:	0001c517          	auipc	a0,0x1c
    80003982:	e4a50513          	addi	a0,a0,-438 # 8001f7c8 <itable>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	348080e7          	jalr	840(ra) # 80000cce <release>
}
    8000398e:	60e2                	ld	ra,24(sp)
    80003990:	6442                	ld	s0,16(sp)
    80003992:	64a2                	ld	s1,8(sp)
    80003994:	6902                	ld	s2,0(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000399a:	40bc                	lw	a5,64(s1)
    8000399c:	dff1                	beqz	a5,80003978 <iput+0x26>
    8000399e:	04a49783          	lh	a5,74(s1)
    800039a2:	fbf9                	bnez	a5,80003978 <iput+0x26>
    acquiresleep(&ip->lock);
    800039a4:	01048913          	addi	s2,s1,16
    800039a8:	854a                	mv	a0,s2
    800039aa:	00001097          	auipc	ra,0x1
    800039ae:	abe080e7          	jalr	-1346(ra) # 80004468 <acquiresleep>
    release(&itable.lock);
    800039b2:	0001c517          	auipc	a0,0x1c
    800039b6:	e1650513          	addi	a0,a0,-490 # 8001f7c8 <itable>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	314080e7          	jalr	788(ra) # 80000cce <release>
    itrunc(ip);
    800039c2:	8526                	mv	a0,s1
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	ee2080e7          	jalr	-286(ra) # 800038a6 <itrunc>
    ip->type = 0;
    800039cc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039d0:	8526                	mv	a0,s1
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	cfa080e7          	jalr	-774(ra) # 800036cc <iupdate>
    ip->valid = 0;
    800039da:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039de:	854a                	mv	a0,s2
    800039e0:	00001097          	auipc	ra,0x1
    800039e4:	ade080e7          	jalr	-1314(ra) # 800044be <releasesleep>
    acquire(&itable.lock);
    800039e8:	0001c517          	auipc	a0,0x1c
    800039ec:	de050513          	addi	a0,a0,-544 # 8001f7c8 <itable>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	22a080e7          	jalr	554(ra) # 80000c1a <acquire>
    800039f8:	b741                	j	80003978 <iput+0x26>

00000000800039fa <iunlockput>:
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	e426                	sd	s1,8(sp)
    80003a02:	1000                	addi	s0,sp,32
    80003a04:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	e54080e7          	jalr	-428(ra) # 8000385a <iunlock>
  iput(ip);
    80003a0e:	8526                	mv	a0,s1
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	f42080e7          	jalr	-190(ra) # 80003952 <iput>
}
    80003a18:	60e2                	ld	ra,24(sp)
    80003a1a:	6442                	ld	s0,16(sp)
    80003a1c:	64a2                	ld	s1,8(sp)
    80003a1e:	6105                	addi	sp,sp,32
    80003a20:	8082                	ret

0000000080003a22 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a22:	1141                	addi	sp,sp,-16
    80003a24:	e422                	sd	s0,8(sp)
    80003a26:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a28:	411c                	lw	a5,0(a0)
    80003a2a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a2c:	415c                	lw	a5,4(a0)
    80003a2e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a30:	04451783          	lh	a5,68(a0)
    80003a34:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a38:	04a51783          	lh	a5,74(a0)
    80003a3c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a40:	04c56783          	lwu	a5,76(a0)
    80003a44:	e99c                	sd	a5,16(a1)
}
    80003a46:	6422                	ld	s0,8(sp)
    80003a48:	0141                	addi	sp,sp,16
    80003a4a:	8082                	ret

0000000080003a4c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a4c:	457c                	lw	a5,76(a0)
    80003a4e:	0ed7e963          	bltu	a5,a3,80003b40 <readi+0xf4>
{
    80003a52:	7159                	addi	sp,sp,-112
    80003a54:	f486                	sd	ra,104(sp)
    80003a56:	f0a2                	sd	s0,96(sp)
    80003a58:	eca6                	sd	s1,88(sp)
    80003a5a:	e8ca                	sd	s2,80(sp)
    80003a5c:	e4ce                	sd	s3,72(sp)
    80003a5e:	e0d2                	sd	s4,64(sp)
    80003a60:	fc56                	sd	s5,56(sp)
    80003a62:	f85a                	sd	s6,48(sp)
    80003a64:	f45e                	sd	s7,40(sp)
    80003a66:	f062                	sd	s8,32(sp)
    80003a68:	ec66                	sd	s9,24(sp)
    80003a6a:	e86a                	sd	s10,16(sp)
    80003a6c:	e46e                	sd	s11,8(sp)
    80003a6e:	1880                	addi	s0,sp,112
    80003a70:	8baa                	mv	s7,a0
    80003a72:	8c2e                	mv	s8,a1
    80003a74:	8ab2                	mv	s5,a2
    80003a76:	84b6                	mv	s1,a3
    80003a78:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a7a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a7c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a7e:	0ad76063          	bltu	a4,a3,80003b1e <readi+0xd2>
  if(off + n > ip->size)
    80003a82:	00e7f463          	bgeu	a5,a4,80003a8a <readi+0x3e>
    n = ip->size - off;
    80003a86:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8a:	0a0b0963          	beqz	s6,80003b3c <readi+0xf0>
    80003a8e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a90:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a94:	5cfd                	li	s9,-1
    80003a96:	a82d                	j	80003ad0 <readi+0x84>
    80003a98:	020a1d93          	slli	s11,s4,0x20
    80003a9c:	020ddd93          	srli	s11,s11,0x20
    80003aa0:	05890613          	addi	a2,s2,88
    80003aa4:	86ee                	mv	a3,s11
    80003aa6:	963a                	add	a2,a2,a4
    80003aa8:	85d6                	mv	a1,s5
    80003aaa:	8562                	mv	a0,s8
    80003aac:	fffff097          	auipc	ra,0xfffff
    80003ab0:	98e080e7          	jalr	-1650(ra) # 8000243a <either_copyout>
    80003ab4:	05950d63          	beq	a0,s9,80003b0e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ab8:	854a                	mv	a0,s2
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	60c080e7          	jalr	1548(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac2:	013a09bb          	addw	s3,s4,s3
    80003ac6:	009a04bb          	addw	s1,s4,s1
    80003aca:	9aee                	add	s5,s5,s11
    80003acc:	0569f763          	bgeu	s3,s6,80003b1a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ad0:	000ba903          	lw	s2,0(s7)
    80003ad4:	00a4d59b          	srliw	a1,s1,0xa
    80003ad8:	855e                	mv	a0,s7
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	8ac080e7          	jalr	-1876(ra) # 80003386 <bmap>
    80003ae2:	0005059b          	sext.w	a1,a0
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	4ae080e7          	jalr	1198(ra) # 80002f96 <bread>
    80003af0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af2:	3ff4f713          	andi	a4,s1,1023
    80003af6:	40ed07bb          	subw	a5,s10,a4
    80003afa:	413b06bb          	subw	a3,s6,s3
    80003afe:	8a3e                	mv	s4,a5
    80003b00:	2781                	sext.w	a5,a5
    80003b02:	0006861b          	sext.w	a2,a3
    80003b06:	f8f679e3          	bgeu	a2,a5,80003a98 <readi+0x4c>
    80003b0a:	8a36                	mv	s4,a3
    80003b0c:	b771                	j	80003a98 <readi+0x4c>
      brelse(bp);
    80003b0e:	854a                	mv	a0,s2
    80003b10:	fffff097          	auipc	ra,0xfffff
    80003b14:	5b6080e7          	jalr	1462(ra) # 800030c6 <brelse>
      tot = -1;
    80003b18:	59fd                	li	s3,-1
  }
  return tot;
    80003b1a:	0009851b          	sext.w	a0,s3
}
    80003b1e:	70a6                	ld	ra,104(sp)
    80003b20:	7406                	ld	s0,96(sp)
    80003b22:	64e6                	ld	s1,88(sp)
    80003b24:	6946                	ld	s2,80(sp)
    80003b26:	69a6                	ld	s3,72(sp)
    80003b28:	6a06                	ld	s4,64(sp)
    80003b2a:	7ae2                	ld	s5,56(sp)
    80003b2c:	7b42                	ld	s6,48(sp)
    80003b2e:	7ba2                	ld	s7,40(sp)
    80003b30:	7c02                	ld	s8,32(sp)
    80003b32:	6ce2                	ld	s9,24(sp)
    80003b34:	6d42                	ld	s10,16(sp)
    80003b36:	6da2                	ld	s11,8(sp)
    80003b38:	6165                	addi	sp,sp,112
    80003b3a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3c:	89da                	mv	s3,s6
    80003b3e:	bff1                	j	80003b1a <readi+0xce>
    return 0;
    80003b40:	4501                	li	a0,0
}
    80003b42:	8082                	ret

0000000080003b44 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b44:	457c                	lw	a5,76(a0)
    80003b46:	10d7e863          	bltu	a5,a3,80003c56 <writei+0x112>
{
    80003b4a:	7159                	addi	sp,sp,-112
    80003b4c:	f486                	sd	ra,104(sp)
    80003b4e:	f0a2                	sd	s0,96(sp)
    80003b50:	eca6                	sd	s1,88(sp)
    80003b52:	e8ca                	sd	s2,80(sp)
    80003b54:	e4ce                	sd	s3,72(sp)
    80003b56:	e0d2                	sd	s4,64(sp)
    80003b58:	fc56                	sd	s5,56(sp)
    80003b5a:	f85a                	sd	s6,48(sp)
    80003b5c:	f45e                	sd	s7,40(sp)
    80003b5e:	f062                	sd	s8,32(sp)
    80003b60:	ec66                	sd	s9,24(sp)
    80003b62:	e86a                	sd	s10,16(sp)
    80003b64:	e46e                	sd	s11,8(sp)
    80003b66:	1880                	addi	s0,sp,112
    80003b68:	8b2a                	mv	s6,a0
    80003b6a:	8c2e                	mv	s8,a1
    80003b6c:	8ab2                	mv	s5,a2
    80003b6e:	8936                	mv	s2,a3
    80003b70:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b72:	00e687bb          	addw	a5,a3,a4
    80003b76:	0ed7e263          	bltu	a5,a3,80003c5a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b7a:	00043737          	lui	a4,0x43
    80003b7e:	0ef76063          	bltu	a4,a5,80003c5e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b82:	0c0b8863          	beqz	s7,80003c52 <writei+0x10e>
    80003b86:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b88:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b8c:	5cfd                	li	s9,-1
    80003b8e:	a091                	j	80003bd2 <writei+0x8e>
    80003b90:	02099d93          	slli	s11,s3,0x20
    80003b94:	020ddd93          	srli	s11,s11,0x20
    80003b98:	05848513          	addi	a0,s1,88
    80003b9c:	86ee                	mv	a3,s11
    80003b9e:	8656                	mv	a2,s5
    80003ba0:	85e2                	mv	a1,s8
    80003ba2:	953a                	add	a0,a0,a4
    80003ba4:	fffff097          	auipc	ra,0xfffff
    80003ba8:	8ec080e7          	jalr	-1812(ra) # 80002490 <either_copyin>
    80003bac:	07950263          	beq	a0,s9,80003c10 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	798080e7          	jalr	1944(ra) # 8000434a <log_write>
    brelse(bp);
    80003bba:	8526                	mv	a0,s1
    80003bbc:	fffff097          	auipc	ra,0xfffff
    80003bc0:	50a080e7          	jalr	1290(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc4:	01498a3b          	addw	s4,s3,s4
    80003bc8:	0129893b          	addw	s2,s3,s2
    80003bcc:	9aee                	add	s5,s5,s11
    80003bce:	057a7663          	bgeu	s4,s7,80003c1a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bd2:	000b2483          	lw	s1,0(s6)
    80003bd6:	00a9559b          	srliw	a1,s2,0xa
    80003bda:	855a                	mv	a0,s6
    80003bdc:	fffff097          	auipc	ra,0xfffff
    80003be0:	7aa080e7          	jalr	1962(ra) # 80003386 <bmap>
    80003be4:	0005059b          	sext.w	a1,a0
    80003be8:	8526                	mv	a0,s1
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	3ac080e7          	jalr	940(ra) # 80002f96 <bread>
    80003bf2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf4:	3ff97713          	andi	a4,s2,1023
    80003bf8:	40ed07bb          	subw	a5,s10,a4
    80003bfc:	414b86bb          	subw	a3,s7,s4
    80003c00:	89be                	mv	s3,a5
    80003c02:	2781                	sext.w	a5,a5
    80003c04:	0006861b          	sext.w	a2,a3
    80003c08:	f8f674e3          	bgeu	a2,a5,80003b90 <writei+0x4c>
    80003c0c:	89b6                	mv	s3,a3
    80003c0e:	b749                	j	80003b90 <writei+0x4c>
      brelse(bp);
    80003c10:	8526                	mv	a0,s1
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	4b4080e7          	jalr	1204(ra) # 800030c6 <brelse>
  }

  if(off > ip->size)
    80003c1a:	04cb2783          	lw	a5,76(s6)
    80003c1e:	0127f463          	bgeu	a5,s2,80003c26 <writei+0xe2>
    ip->size = off;
    80003c22:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c26:	855a                	mv	a0,s6
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	aa4080e7          	jalr	-1372(ra) # 800036cc <iupdate>

  return tot;
    80003c30:	000a051b          	sext.w	a0,s4
}
    80003c34:	70a6                	ld	ra,104(sp)
    80003c36:	7406                	ld	s0,96(sp)
    80003c38:	64e6                	ld	s1,88(sp)
    80003c3a:	6946                	ld	s2,80(sp)
    80003c3c:	69a6                	ld	s3,72(sp)
    80003c3e:	6a06                	ld	s4,64(sp)
    80003c40:	7ae2                	ld	s5,56(sp)
    80003c42:	7b42                	ld	s6,48(sp)
    80003c44:	7ba2                	ld	s7,40(sp)
    80003c46:	7c02                	ld	s8,32(sp)
    80003c48:	6ce2                	ld	s9,24(sp)
    80003c4a:	6d42                	ld	s10,16(sp)
    80003c4c:	6da2                	ld	s11,8(sp)
    80003c4e:	6165                	addi	sp,sp,112
    80003c50:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c52:	8a5e                	mv	s4,s7
    80003c54:	bfc9                	j	80003c26 <writei+0xe2>
    return -1;
    80003c56:	557d                	li	a0,-1
}
    80003c58:	8082                	ret
    return -1;
    80003c5a:	557d                	li	a0,-1
    80003c5c:	bfe1                	j	80003c34 <writei+0xf0>
    return -1;
    80003c5e:	557d                	li	a0,-1
    80003c60:	bfd1                	j	80003c34 <writei+0xf0>

0000000080003c62 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c62:	1141                	addi	sp,sp,-16
    80003c64:	e406                	sd	ra,8(sp)
    80003c66:	e022                	sd	s0,0(sp)
    80003c68:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c6a:	4639                	li	a2,14
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	17a080e7          	jalr	378(ra) # 80000de6 <strncmp>
}
    80003c74:	60a2                	ld	ra,8(sp)
    80003c76:	6402                	ld	s0,0(sp)
    80003c78:	0141                	addi	sp,sp,16
    80003c7a:	8082                	ret

0000000080003c7c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c7c:	7139                	addi	sp,sp,-64
    80003c7e:	fc06                	sd	ra,56(sp)
    80003c80:	f822                	sd	s0,48(sp)
    80003c82:	f426                	sd	s1,40(sp)
    80003c84:	f04a                	sd	s2,32(sp)
    80003c86:	ec4e                	sd	s3,24(sp)
    80003c88:	e852                	sd	s4,16(sp)
    80003c8a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c8c:	04451703          	lh	a4,68(a0)
    80003c90:	4785                	li	a5,1
    80003c92:	00f71a63          	bne	a4,a5,80003ca6 <dirlookup+0x2a>
    80003c96:	892a                	mv	s2,a0
    80003c98:	89ae                	mv	s3,a1
    80003c9a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9c:	457c                	lw	a5,76(a0)
    80003c9e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ca0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca2:	e79d                	bnez	a5,80003cd0 <dirlookup+0x54>
    80003ca4:	a8a5                	j	80003d1c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca6:	00005517          	auipc	a0,0x5
    80003caa:	9b250513          	addi	a0,a0,-1614 # 80008658 <syscalls+0x1b0>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	88c080e7          	jalr	-1908(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003cb6:	00005517          	auipc	a0,0x5
    80003cba:	9ba50513          	addi	a0,a0,-1606 # 80008670 <syscalls+0x1c8>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	87c080e7          	jalr	-1924(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc6:	24c1                	addiw	s1,s1,16
    80003cc8:	04c92783          	lw	a5,76(s2)
    80003ccc:	04f4f763          	bgeu	s1,a5,80003d1a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cd0:	4741                	li	a4,16
    80003cd2:	86a6                	mv	a3,s1
    80003cd4:	fc040613          	addi	a2,s0,-64
    80003cd8:	4581                	li	a1,0
    80003cda:	854a                	mv	a0,s2
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	d70080e7          	jalr	-656(ra) # 80003a4c <readi>
    80003ce4:	47c1                	li	a5,16
    80003ce6:	fcf518e3          	bne	a0,a5,80003cb6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cea:	fc045783          	lhu	a5,-64(s0)
    80003cee:	dfe1                	beqz	a5,80003cc6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cf0:	fc240593          	addi	a1,s0,-62
    80003cf4:	854e                	mv	a0,s3
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	f6c080e7          	jalr	-148(ra) # 80003c62 <namecmp>
    80003cfe:	f561                	bnez	a0,80003cc6 <dirlookup+0x4a>
      if(poff)
    80003d00:	000a0463          	beqz	s4,80003d08 <dirlookup+0x8c>
        *poff = off;
    80003d04:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d08:	fc045583          	lhu	a1,-64(s0)
    80003d0c:	00092503          	lw	a0,0(s2)
    80003d10:	fffff097          	auipc	ra,0xfffff
    80003d14:	752080e7          	jalr	1874(ra) # 80003462 <iget>
    80003d18:	a011                	j	80003d1c <dirlookup+0xa0>
  return 0;
    80003d1a:	4501                	li	a0,0
}
    80003d1c:	70e2                	ld	ra,56(sp)
    80003d1e:	7442                	ld	s0,48(sp)
    80003d20:	74a2                	ld	s1,40(sp)
    80003d22:	7902                	ld	s2,32(sp)
    80003d24:	69e2                	ld	s3,24(sp)
    80003d26:	6a42                	ld	s4,16(sp)
    80003d28:	6121                	addi	sp,sp,64
    80003d2a:	8082                	ret

0000000080003d2c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d2c:	711d                	addi	sp,sp,-96
    80003d2e:	ec86                	sd	ra,88(sp)
    80003d30:	e8a2                	sd	s0,80(sp)
    80003d32:	e4a6                	sd	s1,72(sp)
    80003d34:	e0ca                	sd	s2,64(sp)
    80003d36:	fc4e                	sd	s3,56(sp)
    80003d38:	f852                	sd	s4,48(sp)
    80003d3a:	f456                	sd	s5,40(sp)
    80003d3c:	f05a                	sd	s6,32(sp)
    80003d3e:	ec5e                	sd	s7,24(sp)
    80003d40:	e862                	sd	s8,16(sp)
    80003d42:	e466                	sd	s9,8(sp)
    80003d44:	e06a                	sd	s10,0(sp)
    80003d46:	1080                	addi	s0,sp,96
    80003d48:	84aa                	mv	s1,a0
    80003d4a:	8b2e                	mv	s6,a1
    80003d4c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d4e:	00054703          	lbu	a4,0(a0)
    80003d52:	02f00793          	li	a5,47
    80003d56:	02f70363          	beq	a4,a5,80003d7c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d5a:	ffffe097          	auipc	ra,0xffffe
    80003d5e:	c78080e7          	jalr	-904(ra) # 800019d2 <myproc>
    80003d62:	15053503          	ld	a0,336(a0)
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	9f4080e7          	jalr	-1548(ra) # 8000375a <idup>
    80003d6e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d70:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d74:	4cb5                	li	s9,13
  len = path - s;
    80003d76:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d78:	4c05                	li	s8,1
    80003d7a:	a87d                	j	80003e38 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d7c:	4585                	li	a1,1
    80003d7e:	4505                	li	a0,1
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	6e2080e7          	jalr	1762(ra) # 80003462 <iget>
    80003d88:	8a2a                	mv	s4,a0
    80003d8a:	b7dd                	j	80003d70 <namex+0x44>
      iunlockput(ip);
    80003d8c:	8552                	mv	a0,s4
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	c6c080e7          	jalr	-916(ra) # 800039fa <iunlockput>
      return 0;
    80003d96:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d98:	8552                	mv	a0,s4
    80003d9a:	60e6                	ld	ra,88(sp)
    80003d9c:	6446                	ld	s0,80(sp)
    80003d9e:	64a6                	ld	s1,72(sp)
    80003da0:	6906                	ld	s2,64(sp)
    80003da2:	79e2                	ld	s3,56(sp)
    80003da4:	7a42                	ld	s4,48(sp)
    80003da6:	7aa2                	ld	s5,40(sp)
    80003da8:	7b02                	ld	s6,32(sp)
    80003daa:	6be2                	ld	s7,24(sp)
    80003dac:	6c42                	ld	s8,16(sp)
    80003dae:	6ca2                	ld	s9,8(sp)
    80003db0:	6d02                	ld	s10,0(sp)
    80003db2:	6125                	addi	sp,sp,96
    80003db4:	8082                	ret
      iunlock(ip);
    80003db6:	8552                	mv	a0,s4
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	aa2080e7          	jalr	-1374(ra) # 8000385a <iunlock>
      return ip;
    80003dc0:	bfe1                	j	80003d98 <namex+0x6c>
      iunlockput(ip);
    80003dc2:	8552                	mv	a0,s4
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	c36080e7          	jalr	-970(ra) # 800039fa <iunlockput>
      return 0;
    80003dcc:	8a4e                	mv	s4,s3
    80003dce:	b7e9                	j	80003d98 <namex+0x6c>
  len = path - s;
    80003dd0:	40998633          	sub	a2,s3,s1
    80003dd4:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003dd8:	09acd863          	bge	s9,s10,80003e68 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003ddc:	4639                	li	a2,14
    80003dde:	85a6                	mv	a1,s1
    80003de0:	8556                	mv	a0,s5
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	f90080e7          	jalr	-112(ra) # 80000d72 <memmove>
    80003dea:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dec:	0004c783          	lbu	a5,0(s1)
    80003df0:	01279763          	bne	a5,s2,80003dfe <namex+0xd2>
    path++;
    80003df4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df6:	0004c783          	lbu	a5,0(s1)
    80003dfa:	ff278de3          	beq	a5,s2,80003df4 <namex+0xc8>
    ilock(ip);
    80003dfe:	8552                	mv	a0,s4
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	998080e7          	jalr	-1640(ra) # 80003798 <ilock>
    if(ip->type != T_DIR){
    80003e08:	044a1783          	lh	a5,68(s4)
    80003e0c:	f98790e3          	bne	a5,s8,80003d8c <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e10:	000b0563          	beqz	s6,80003e1a <namex+0xee>
    80003e14:	0004c783          	lbu	a5,0(s1)
    80003e18:	dfd9                	beqz	a5,80003db6 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e1a:	865e                	mv	a2,s7
    80003e1c:	85d6                	mv	a1,s5
    80003e1e:	8552                	mv	a0,s4
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	e5c080e7          	jalr	-420(ra) # 80003c7c <dirlookup>
    80003e28:	89aa                	mv	s3,a0
    80003e2a:	dd41                	beqz	a0,80003dc2 <namex+0x96>
    iunlockput(ip);
    80003e2c:	8552                	mv	a0,s4
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	bcc080e7          	jalr	-1076(ra) # 800039fa <iunlockput>
    ip = next;
    80003e36:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e38:	0004c783          	lbu	a5,0(s1)
    80003e3c:	01279763          	bne	a5,s2,80003e4a <namex+0x11e>
    path++;
    80003e40:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e42:	0004c783          	lbu	a5,0(s1)
    80003e46:	ff278de3          	beq	a5,s2,80003e40 <namex+0x114>
  if(*path == 0)
    80003e4a:	cb9d                	beqz	a5,80003e80 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e4c:	0004c783          	lbu	a5,0(s1)
    80003e50:	89a6                	mv	s3,s1
  len = path - s;
    80003e52:	8d5e                	mv	s10,s7
    80003e54:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e56:	01278963          	beq	a5,s2,80003e68 <namex+0x13c>
    80003e5a:	dbbd                	beqz	a5,80003dd0 <namex+0xa4>
    path++;
    80003e5c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e5e:	0009c783          	lbu	a5,0(s3)
    80003e62:	ff279ce3          	bne	a5,s2,80003e5a <namex+0x12e>
    80003e66:	b7ad                	j	80003dd0 <namex+0xa4>
    memmove(name, s, len);
    80003e68:	2601                	sext.w	a2,a2
    80003e6a:	85a6                	mv	a1,s1
    80003e6c:	8556                	mv	a0,s5
    80003e6e:	ffffd097          	auipc	ra,0xffffd
    80003e72:	f04080e7          	jalr	-252(ra) # 80000d72 <memmove>
    name[len] = 0;
    80003e76:	9d56                	add	s10,s10,s5
    80003e78:	000d0023          	sb	zero,0(s10)
    80003e7c:	84ce                	mv	s1,s3
    80003e7e:	b7bd                	j	80003dec <namex+0xc0>
  if(nameiparent){
    80003e80:	f00b0ce3          	beqz	s6,80003d98 <namex+0x6c>
    iput(ip);
    80003e84:	8552                	mv	a0,s4
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	acc080e7          	jalr	-1332(ra) # 80003952 <iput>
    return 0;
    80003e8e:	4a01                	li	s4,0
    80003e90:	b721                	j	80003d98 <namex+0x6c>

0000000080003e92 <dirlink>:
{
    80003e92:	7139                	addi	sp,sp,-64
    80003e94:	fc06                	sd	ra,56(sp)
    80003e96:	f822                	sd	s0,48(sp)
    80003e98:	f426                	sd	s1,40(sp)
    80003e9a:	f04a                	sd	s2,32(sp)
    80003e9c:	ec4e                	sd	s3,24(sp)
    80003e9e:	e852                	sd	s4,16(sp)
    80003ea0:	0080                	addi	s0,sp,64
    80003ea2:	892a                	mv	s2,a0
    80003ea4:	8a2e                	mv	s4,a1
    80003ea6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ea8:	4601                	li	a2,0
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	dd2080e7          	jalr	-558(ra) # 80003c7c <dirlookup>
    80003eb2:	e93d                	bnez	a0,80003f28 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb4:	04c92483          	lw	s1,76(s2)
    80003eb8:	c49d                	beqz	s1,80003ee6 <dirlink+0x54>
    80003eba:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ebc:	4741                	li	a4,16
    80003ebe:	86a6                	mv	a3,s1
    80003ec0:	fc040613          	addi	a2,s0,-64
    80003ec4:	4581                	li	a1,0
    80003ec6:	854a                	mv	a0,s2
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	b84080e7          	jalr	-1148(ra) # 80003a4c <readi>
    80003ed0:	47c1                	li	a5,16
    80003ed2:	06f51163          	bne	a0,a5,80003f34 <dirlink+0xa2>
    if(de.inum == 0)
    80003ed6:	fc045783          	lhu	a5,-64(s0)
    80003eda:	c791                	beqz	a5,80003ee6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003edc:	24c1                	addiw	s1,s1,16
    80003ede:	04c92783          	lw	a5,76(s2)
    80003ee2:	fcf4ede3          	bltu	s1,a5,80003ebc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ee6:	4639                	li	a2,14
    80003ee8:	85d2                	mv	a1,s4
    80003eea:	fc240513          	addi	a0,s0,-62
    80003eee:	ffffd097          	auipc	ra,0xffffd
    80003ef2:	f34080e7          	jalr	-204(ra) # 80000e22 <strncpy>
  de.inum = inum;
    80003ef6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efa:	4741                	li	a4,16
    80003efc:	86a6                	mv	a3,s1
    80003efe:	fc040613          	addi	a2,s0,-64
    80003f02:	4581                	li	a1,0
    80003f04:	854a                	mv	a0,s2
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	c3e080e7          	jalr	-962(ra) # 80003b44 <writei>
    80003f0e:	872a                	mv	a4,a0
    80003f10:	47c1                	li	a5,16
  return 0;
    80003f12:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f14:	02f71863          	bne	a4,a5,80003f44 <dirlink+0xb2>
}
    80003f18:	70e2                	ld	ra,56(sp)
    80003f1a:	7442                	ld	s0,48(sp)
    80003f1c:	74a2                	ld	s1,40(sp)
    80003f1e:	7902                	ld	s2,32(sp)
    80003f20:	69e2                	ld	s3,24(sp)
    80003f22:	6a42                	ld	s4,16(sp)
    80003f24:	6121                	addi	sp,sp,64
    80003f26:	8082                	ret
    iput(ip);
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	a2a080e7          	jalr	-1494(ra) # 80003952 <iput>
    return -1;
    80003f30:	557d                	li	a0,-1
    80003f32:	b7dd                	j	80003f18 <dirlink+0x86>
      panic("dirlink read");
    80003f34:	00004517          	auipc	a0,0x4
    80003f38:	74c50513          	addi	a0,a0,1868 # 80008680 <syscalls+0x1d8>
    80003f3c:	ffffc097          	auipc	ra,0xffffc
    80003f40:	5fe080e7          	jalr	1534(ra) # 8000053a <panic>
    panic("dirlink");
    80003f44:	00005517          	auipc	a0,0x5
    80003f48:	84c50513          	addi	a0,a0,-1972 # 80008790 <syscalls+0x2e8>
    80003f4c:	ffffc097          	auipc	ra,0xffffc
    80003f50:	5ee080e7          	jalr	1518(ra) # 8000053a <panic>

0000000080003f54 <namei>:

struct inode*
namei(char *path)
{
    80003f54:	1101                	addi	sp,sp,-32
    80003f56:	ec06                	sd	ra,24(sp)
    80003f58:	e822                	sd	s0,16(sp)
    80003f5a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f5c:	fe040613          	addi	a2,s0,-32
    80003f60:	4581                	li	a1,0
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	dca080e7          	jalr	-566(ra) # 80003d2c <namex>
}
    80003f6a:	60e2                	ld	ra,24(sp)
    80003f6c:	6442                	ld	s0,16(sp)
    80003f6e:	6105                	addi	sp,sp,32
    80003f70:	8082                	ret

0000000080003f72 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f72:	1141                	addi	sp,sp,-16
    80003f74:	e406                	sd	ra,8(sp)
    80003f76:	e022                	sd	s0,0(sp)
    80003f78:	0800                	addi	s0,sp,16
    80003f7a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f7c:	4585                	li	a1,1
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	dae080e7          	jalr	-594(ra) # 80003d2c <namex>
}
    80003f86:	60a2                	ld	ra,8(sp)
    80003f88:	6402                	ld	s0,0(sp)
    80003f8a:	0141                	addi	sp,sp,16
    80003f8c:	8082                	ret

0000000080003f8e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f8e:	1101                	addi	sp,sp,-32
    80003f90:	ec06                	sd	ra,24(sp)
    80003f92:	e822                	sd	s0,16(sp)
    80003f94:	e426                	sd	s1,8(sp)
    80003f96:	e04a                	sd	s2,0(sp)
    80003f98:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f9a:	0001d917          	auipc	s2,0x1d
    80003f9e:	2d690913          	addi	s2,s2,726 # 80021270 <log>
    80003fa2:	01892583          	lw	a1,24(s2)
    80003fa6:	02892503          	lw	a0,40(s2)
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	fec080e7          	jalr	-20(ra) # 80002f96 <bread>
    80003fb2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb4:	02c92683          	lw	a3,44(s2)
    80003fb8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fba:	02d05863          	blez	a3,80003fea <write_head+0x5c>
    80003fbe:	0001d797          	auipc	a5,0x1d
    80003fc2:	2e278793          	addi	a5,a5,738 # 800212a0 <log+0x30>
    80003fc6:	05c50713          	addi	a4,a0,92
    80003fca:	36fd                	addiw	a3,a3,-1
    80003fcc:	02069613          	slli	a2,a3,0x20
    80003fd0:	01e65693          	srli	a3,a2,0x1e
    80003fd4:	0001d617          	auipc	a2,0x1d
    80003fd8:	2d060613          	addi	a2,a2,720 # 800212a4 <log+0x34>
    80003fdc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fde:	4390                	lw	a2,0(a5)
    80003fe0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe2:	0791                	addi	a5,a5,4
    80003fe4:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fe6:	fed79ce3          	bne	a5,a3,80003fde <write_head+0x50>
  }
  bwrite(buf);
    80003fea:	8526                	mv	a0,s1
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	09c080e7          	jalr	156(ra) # 80003088 <bwrite>
  brelse(buf);
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	0d0080e7          	jalr	208(ra) # 800030c6 <brelse>
}
    80003ffe:	60e2                	ld	ra,24(sp)
    80004000:	6442                	ld	s0,16(sp)
    80004002:	64a2                	ld	s1,8(sp)
    80004004:	6902                	ld	s2,0(sp)
    80004006:	6105                	addi	sp,sp,32
    80004008:	8082                	ret

000000008000400a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000400a:	0001d797          	auipc	a5,0x1d
    8000400e:	2927a783          	lw	a5,658(a5) # 8002129c <log+0x2c>
    80004012:	0af05d63          	blez	a5,800040cc <install_trans+0xc2>
{
    80004016:	7139                	addi	sp,sp,-64
    80004018:	fc06                	sd	ra,56(sp)
    8000401a:	f822                	sd	s0,48(sp)
    8000401c:	f426                	sd	s1,40(sp)
    8000401e:	f04a                	sd	s2,32(sp)
    80004020:	ec4e                	sd	s3,24(sp)
    80004022:	e852                	sd	s4,16(sp)
    80004024:	e456                	sd	s5,8(sp)
    80004026:	e05a                	sd	s6,0(sp)
    80004028:	0080                	addi	s0,sp,64
    8000402a:	8b2a                	mv	s6,a0
    8000402c:	0001da97          	auipc	s5,0x1d
    80004030:	274a8a93          	addi	s5,s5,628 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004034:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004036:	0001d997          	auipc	s3,0x1d
    8000403a:	23a98993          	addi	s3,s3,570 # 80021270 <log>
    8000403e:	a00d                	j	80004060 <install_trans+0x56>
    brelse(lbuf);
    80004040:	854a                	mv	a0,s2
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	084080e7          	jalr	132(ra) # 800030c6 <brelse>
    brelse(dbuf);
    8000404a:	8526                	mv	a0,s1
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	07a080e7          	jalr	122(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004054:	2a05                	addiw	s4,s4,1
    80004056:	0a91                	addi	s5,s5,4
    80004058:	02c9a783          	lw	a5,44(s3)
    8000405c:	04fa5e63          	bge	s4,a5,800040b8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004060:	0189a583          	lw	a1,24(s3)
    80004064:	014585bb          	addw	a1,a1,s4
    80004068:	2585                	addiw	a1,a1,1
    8000406a:	0289a503          	lw	a0,40(s3)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	f28080e7          	jalr	-216(ra) # 80002f96 <bread>
    80004076:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004078:	000aa583          	lw	a1,0(s5)
    8000407c:	0289a503          	lw	a0,40(s3)
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	f16080e7          	jalr	-234(ra) # 80002f96 <bread>
    80004088:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000408a:	40000613          	li	a2,1024
    8000408e:	05890593          	addi	a1,s2,88
    80004092:	05850513          	addi	a0,a0,88
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	cdc080e7          	jalr	-804(ra) # 80000d72 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000409e:	8526                	mv	a0,s1
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	fe8080e7          	jalr	-24(ra) # 80003088 <bwrite>
    if(recovering == 0)
    800040a8:	f80b1ce3          	bnez	s6,80004040 <install_trans+0x36>
      bunpin(dbuf);
    800040ac:	8526                	mv	a0,s1
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	0f2080e7          	jalr	242(ra) # 800031a0 <bunpin>
    800040b6:	b769                	j	80004040 <install_trans+0x36>
}
    800040b8:	70e2                	ld	ra,56(sp)
    800040ba:	7442                	ld	s0,48(sp)
    800040bc:	74a2                	ld	s1,40(sp)
    800040be:	7902                	ld	s2,32(sp)
    800040c0:	69e2                	ld	s3,24(sp)
    800040c2:	6a42                	ld	s4,16(sp)
    800040c4:	6aa2                	ld	s5,8(sp)
    800040c6:	6b02                	ld	s6,0(sp)
    800040c8:	6121                	addi	sp,sp,64
    800040ca:	8082                	ret
    800040cc:	8082                	ret

00000000800040ce <initlog>:
{
    800040ce:	7179                	addi	sp,sp,-48
    800040d0:	f406                	sd	ra,40(sp)
    800040d2:	f022                	sd	s0,32(sp)
    800040d4:	ec26                	sd	s1,24(sp)
    800040d6:	e84a                	sd	s2,16(sp)
    800040d8:	e44e                	sd	s3,8(sp)
    800040da:	1800                	addi	s0,sp,48
    800040dc:	892a                	mv	s2,a0
    800040de:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e0:	0001d497          	auipc	s1,0x1d
    800040e4:	19048493          	addi	s1,s1,400 # 80021270 <log>
    800040e8:	00004597          	auipc	a1,0x4
    800040ec:	5a858593          	addi	a1,a1,1448 # 80008690 <syscalls+0x1e8>
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	a98080e7          	jalr	-1384(ra) # 80000b8a <initlock>
  log.start = sb->logstart;
    800040fa:	0149a583          	lw	a1,20(s3)
    800040fe:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004100:	0109a783          	lw	a5,16(s3)
    80004104:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004106:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000410a:	854a                	mv	a0,s2
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	e8a080e7          	jalr	-374(ra) # 80002f96 <bread>
  log.lh.n = lh->n;
    80004114:	4d34                	lw	a3,88(a0)
    80004116:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004118:	02d05663          	blez	a3,80004144 <initlog+0x76>
    8000411c:	05c50793          	addi	a5,a0,92
    80004120:	0001d717          	auipc	a4,0x1d
    80004124:	18070713          	addi	a4,a4,384 # 800212a0 <log+0x30>
    80004128:	36fd                	addiw	a3,a3,-1
    8000412a:	02069613          	slli	a2,a3,0x20
    8000412e:	01e65693          	srli	a3,a2,0x1e
    80004132:	06050613          	addi	a2,a0,96
    80004136:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004138:	4390                	lw	a2,0(a5)
    8000413a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000413c:	0791                	addi	a5,a5,4
    8000413e:	0711                	addi	a4,a4,4
    80004140:	fed79ce3          	bne	a5,a3,80004138 <initlog+0x6a>
  brelse(buf);
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	f82080e7          	jalr	-126(ra) # 800030c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000414c:	4505                	li	a0,1
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	ebc080e7          	jalr	-324(ra) # 8000400a <install_trans>
  log.lh.n = 0;
    80004156:	0001d797          	auipc	a5,0x1d
    8000415a:	1407a323          	sw	zero,326(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	e30080e7          	jalr	-464(ra) # 80003f8e <write_head>
}
    80004166:	70a2                	ld	ra,40(sp)
    80004168:	7402                	ld	s0,32(sp)
    8000416a:	64e2                	ld	s1,24(sp)
    8000416c:	6942                	ld	s2,16(sp)
    8000416e:	69a2                	ld	s3,8(sp)
    80004170:	6145                	addi	sp,sp,48
    80004172:	8082                	ret

0000000080004174 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004174:	1101                	addi	sp,sp,-32
    80004176:	ec06                	sd	ra,24(sp)
    80004178:	e822                	sd	s0,16(sp)
    8000417a:	e426                	sd	s1,8(sp)
    8000417c:	e04a                	sd	s2,0(sp)
    8000417e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004180:	0001d517          	auipc	a0,0x1d
    80004184:	0f050513          	addi	a0,a0,240 # 80021270 <log>
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	a92080e7          	jalr	-1390(ra) # 80000c1a <acquire>
  while(1){
    if(log.committing){
    80004190:	0001d497          	auipc	s1,0x1d
    80004194:	0e048493          	addi	s1,s1,224 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004198:	4979                	li	s2,30
    8000419a:	a039                	j	800041a8 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000419c:	85a6                	mv	a1,s1
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	ef6080e7          	jalr	-266(ra) # 80002096 <sleep>
    if(log.committing){
    800041a8:	50dc                	lw	a5,36(s1)
    800041aa:	fbed                	bnez	a5,8000419c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ac:	5098                	lw	a4,32(s1)
    800041ae:	2705                	addiw	a4,a4,1
    800041b0:	0007069b          	sext.w	a3,a4
    800041b4:	0027179b          	slliw	a5,a4,0x2
    800041b8:	9fb9                	addw	a5,a5,a4
    800041ba:	0017979b          	slliw	a5,a5,0x1
    800041be:	54d8                	lw	a4,44(s1)
    800041c0:	9fb9                	addw	a5,a5,a4
    800041c2:	00f95963          	bge	s2,a5,800041d4 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041c6:	85a6                	mv	a1,s1
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	ecc080e7          	jalr	-308(ra) # 80002096 <sleep>
    800041d2:	bfd9                	j	800041a8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041d4:	0001d517          	auipc	a0,0x1d
    800041d8:	09c50513          	addi	a0,a0,156 # 80021270 <log>
    800041dc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	af0080e7          	jalr	-1296(ra) # 80000cce <release>
      break;
    }
  }
}
    800041e6:	60e2                	ld	ra,24(sp)
    800041e8:	6442                	ld	s0,16(sp)
    800041ea:	64a2                	ld	s1,8(sp)
    800041ec:	6902                	ld	s2,0(sp)
    800041ee:	6105                	addi	sp,sp,32
    800041f0:	8082                	ret

00000000800041f2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f2:	7139                	addi	sp,sp,-64
    800041f4:	fc06                	sd	ra,56(sp)
    800041f6:	f822                	sd	s0,48(sp)
    800041f8:	f426                	sd	s1,40(sp)
    800041fa:	f04a                	sd	s2,32(sp)
    800041fc:	ec4e                	sd	s3,24(sp)
    800041fe:	e852                	sd	s4,16(sp)
    80004200:	e456                	sd	s5,8(sp)
    80004202:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004204:	0001d497          	auipc	s1,0x1d
    80004208:	06c48493          	addi	s1,s1,108 # 80021270 <log>
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	a0c080e7          	jalr	-1524(ra) # 80000c1a <acquire>
  log.outstanding -= 1;
    80004216:	509c                	lw	a5,32(s1)
    80004218:	37fd                	addiw	a5,a5,-1
    8000421a:	0007891b          	sext.w	s2,a5
    8000421e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004220:	50dc                	lw	a5,36(s1)
    80004222:	e7b9                	bnez	a5,80004270 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004224:	04091e63          	bnez	s2,80004280 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004228:	0001d497          	auipc	s1,0x1d
    8000422c:	04848493          	addi	s1,s1,72 # 80021270 <log>
    80004230:	4785                	li	a5,1
    80004232:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004234:	8526                	mv	a0,s1
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	a98080e7          	jalr	-1384(ra) # 80000cce <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000423e:	54dc                	lw	a5,44(s1)
    80004240:	06f04763          	bgtz	a5,800042ae <end_op+0xbc>
    acquire(&log.lock);
    80004244:	0001d497          	auipc	s1,0x1d
    80004248:	02c48493          	addi	s1,s1,44 # 80021270 <log>
    8000424c:	8526                	mv	a0,s1
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	9cc080e7          	jalr	-1588(ra) # 80000c1a <acquire>
    log.committing = 0;
    80004256:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffe097          	auipc	ra,0xffffe
    80004260:	fc6080e7          	jalr	-58(ra) # 80002222 <wakeup>
    release(&log.lock);
    80004264:	8526                	mv	a0,s1
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a68080e7          	jalr	-1432(ra) # 80000cce <release>
}
    8000426e:	a03d                	j	8000429c <end_op+0xaa>
    panic("log.committing");
    80004270:	00004517          	auipc	a0,0x4
    80004274:	42850513          	addi	a0,a0,1064 # 80008698 <syscalls+0x1f0>
    80004278:	ffffc097          	auipc	ra,0xffffc
    8000427c:	2c2080e7          	jalr	706(ra) # 8000053a <panic>
    wakeup(&log);
    80004280:	0001d497          	auipc	s1,0x1d
    80004284:	ff048493          	addi	s1,s1,-16 # 80021270 <log>
    80004288:	8526                	mv	a0,s1
    8000428a:	ffffe097          	auipc	ra,0xffffe
    8000428e:	f98080e7          	jalr	-104(ra) # 80002222 <wakeup>
  release(&log.lock);
    80004292:	8526                	mv	a0,s1
    80004294:	ffffd097          	auipc	ra,0xffffd
    80004298:	a3a080e7          	jalr	-1478(ra) # 80000cce <release>
}
    8000429c:	70e2                	ld	ra,56(sp)
    8000429e:	7442                	ld	s0,48(sp)
    800042a0:	74a2                	ld	s1,40(sp)
    800042a2:	7902                	ld	s2,32(sp)
    800042a4:	69e2                	ld	s3,24(sp)
    800042a6:	6a42                	ld	s4,16(sp)
    800042a8:	6aa2                	ld	s5,8(sp)
    800042aa:	6121                	addi	sp,sp,64
    800042ac:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ae:	0001da97          	auipc	s5,0x1d
    800042b2:	ff2a8a93          	addi	s5,s5,-14 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042b6:	0001da17          	auipc	s4,0x1d
    800042ba:	fbaa0a13          	addi	s4,s4,-70 # 80021270 <log>
    800042be:	018a2583          	lw	a1,24(s4)
    800042c2:	012585bb          	addw	a1,a1,s2
    800042c6:	2585                	addiw	a1,a1,1
    800042c8:	028a2503          	lw	a0,40(s4)
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	cca080e7          	jalr	-822(ra) # 80002f96 <bread>
    800042d4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042d6:	000aa583          	lw	a1,0(s5)
    800042da:	028a2503          	lw	a0,40(s4)
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	cb8080e7          	jalr	-840(ra) # 80002f96 <bread>
    800042e6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042e8:	40000613          	li	a2,1024
    800042ec:	05850593          	addi	a1,a0,88
    800042f0:	05848513          	addi	a0,s1,88
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	a7e080e7          	jalr	-1410(ra) # 80000d72 <memmove>
    bwrite(to);  // write the log
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	d8a080e7          	jalr	-630(ra) # 80003088 <bwrite>
    brelse(from);
    80004306:	854e                	mv	a0,s3
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	dbe080e7          	jalr	-578(ra) # 800030c6 <brelse>
    brelse(to);
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	db4080e7          	jalr	-588(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431a:	2905                	addiw	s2,s2,1
    8000431c:	0a91                	addi	s5,s5,4
    8000431e:	02ca2783          	lw	a5,44(s4)
    80004322:	f8f94ee3          	blt	s2,a5,800042be <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	c68080e7          	jalr	-920(ra) # 80003f8e <write_head>
    install_trans(0); // Now install writes to home locations
    8000432e:	4501                	li	a0,0
    80004330:	00000097          	auipc	ra,0x0
    80004334:	cda080e7          	jalr	-806(ra) # 8000400a <install_trans>
    log.lh.n = 0;
    80004338:	0001d797          	auipc	a5,0x1d
    8000433c:	f607a223          	sw	zero,-156(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004340:	00000097          	auipc	ra,0x0
    80004344:	c4e080e7          	jalr	-946(ra) # 80003f8e <write_head>
    80004348:	bdf5                	j	80004244 <end_op+0x52>

000000008000434a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000434a:	1101                	addi	sp,sp,-32
    8000434c:	ec06                	sd	ra,24(sp)
    8000434e:	e822                	sd	s0,16(sp)
    80004350:	e426                	sd	s1,8(sp)
    80004352:	e04a                	sd	s2,0(sp)
    80004354:	1000                	addi	s0,sp,32
    80004356:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004358:	0001d917          	auipc	s2,0x1d
    8000435c:	f1890913          	addi	s2,s2,-232 # 80021270 <log>
    80004360:	854a                	mv	a0,s2
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	8b8080e7          	jalr	-1864(ra) # 80000c1a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000436a:	02c92603          	lw	a2,44(s2)
    8000436e:	47f5                	li	a5,29
    80004370:	06c7c563          	blt	a5,a2,800043da <log_write+0x90>
    80004374:	0001d797          	auipc	a5,0x1d
    80004378:	f187a783          	lw	a5,-232(a5) # 8002128c <log+0x1c>
    8000437c:	37fd                	addiw	a5,a5,-1
    8000437e:	04f65e63          	bge	a2,a5,800043da <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004382:	0001d797          	auipc	a5,0x1d
    80004386:	f0e7a783          	lw	a5,-242(a5) # 80021290 <log+0x20>
    8000438a:	06f05063          	blez	a5,800043ea <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000438e:	4781                	li	a5,0
    80004390:	06c05563          	blez	a2,800043fa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004394:	44cc                	lw	a1,12(s1)
    80004396:	0001d717          	auipc	a4,0x1d
    8000439a:	f0a70713          	addi	a4,a4,-246 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000439e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a0:	4314                	lw	a3,0(a4)
    800043a2:	04b68c63          	beq	a3,a1,800043fa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043a6:	2785                	addiw	a5,a5,1
    800043a8:	0711                	addi	a4,a4,4
    800043aa:	fef61be3          	bne	a2,a5,800043a0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ae:	0621                	addi	a2,a2,8
    800043b0:	060a                	slli	a2,a2,0x2
    800043b2:	0001d797          	auipc	a5,0x1d
    800043b6:	ebe78793          	addi	a5,a5,-322 # 80021270 <log>
    800043ba:	97b2                	add	a5,a5,a2
    800043bc:	44d8                	lw	a4,12(s1)
    800043be:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	da2080e7          	jalr	-606(ra) # 80003164 <bpin>
    log.lh.n++;
    800043ca:	0001d717          	auipc	a4,0x1d
    800043ce:	ea670713          	addi	a4,a4,-346 # 80021270 <log>
    800043d2:	575c                	lw	a5,44(a4)
    800043d4:	2785                	addiw	a5,a5,1
    800043d6:	d75c                	sw	a5,44(a4)
    800043d8:	a82d                	j	80004412 <log_write+0xc8>
    panic("too big a transaction");
    800043da:	00004517          	auipc	a0,0x4
    800043de:	2ce50513          	addi	a0,a0,718 # 800086a8 <syscalls+0x200>
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	158080e7          	jalr	344(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    800043ea:	00004517          	auipc	a0,0x4
    800043ee:	2d650513          	addi	a0,a0,726 # 800086c0 <syscalls+0x218>
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	148080e7          	jalr	328(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    800043fa:	00878693          	addi	a3,a5,8
    800043fe:	068a                	slli	a3,a3,0x2
    80004400:	0001d717          	auipc	a4,0x1d
    80004404:	e7070713          	addi	a4,a4,-400 # 80021270 <log>
    80004408:	9736                	add	a4,a4,a3
    8000440a:	44d4                	lw	a3,12(s1)
    8000440c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000440e:	faf609e3          	beq	a2,a5,800043c0 <log_write+0x76>
  }
  release(&log.lock);
    80004412:	0001d517          	auipc	a0,0x1d
    80004416:	e5e50513          	addi	a0,a0,-418 # 80021270 <log>
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	8b4080e7          	jalr	-1868(ra) # 80000cce <release>
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec06                	sd	ra,24(sp)
    80004432:	e822                	sd	s0,16(sp)
    80004434:	e426                	sd	s1,8(sp)
    80004436:	e04a                	sd	s2,0(sp)
    80004438:	1000                	addi	s0,sp,32
    8000443a:	84aa                	mv	s1,a0
    8000443c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000443e:	00004597          	auipc	a1,0x4
    80004442:	2a258593          	addi	a1,a1,674 # 800086e0 <syscalls+0x238>
    80004446:	0521                	addi	a0,a0,8
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	742080e7          	jalr	1858(ra) # 80000b8a <initlock>
  lk->name = name;
    80004450:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004454:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004458:	0204a423          	sw	zero,40(s1)
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004468:	1101                	addi	sp,sp,-32
    8000446a:	ec06                	sd	ra,24(sp)
    8000446c:	e822                	sd	s0,16(sp)
    8000446e:	e426                	sd	s1,8(sp)
    80004470:	e04a                	sd	s2,0(sp)
    80004472:	1000                	addi	s0,sp,32
    80004474:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	79e080e7          	jalr	1950(ra) # 80000c1a <acquire>
  while (lk->locked) {
    80004484:	409c                	lw	a5,0(s1)
    80004486:	cb89                	beqz	a5,80004498 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004488:	85ca                	mv	a1,s2
    8000448a:	8526                	mv	a0,s1
    8000448c:	ffffe097          	auipc	ra,0xffffe
    80004490:	c0a080e7          	jalr	-1014(ra) # 80002096 <sleep>
  while (lk->locked) {
    80004494:	409c                	lw	a5,0(s1)
    80004496:	fbed                	bnez	a5,80004488 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004498:	4785                	li	a5,1
    8000449a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	536080e7          	jalr	1334(ra) # 800019d2 <myproc>
    800044a4:	591c                	lw	a5,48(a0)
    800044a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a8:	854a                	mv	a0,s2
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	824080e7          	jalr	-2012(ra) # 80000cce <release>
}
    800044b2:	60e2                	ld	ra,24(sp)
    800044b4:	6442                	ld	s0,16(sp)
    800044b6:	64a2                	ld	s1,8(sp)
    800044b8:	6902                	ld	s2,0(sp)
    800044ba:	6105                	addi	sp,sp,32
    800044bc:	8082                	ret

00000000800044be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	e04a                	sd	s2,0(sp)
    800044c8:	1000                	addi	s0,sp,32
    800044ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044cc:	00850913          	addi	s2,a0,8
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	748080e7          	jalr	1864(ra) # 80000c1a <acquire>
  lk->locked = 0;
    800044da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044e2:	8526                	mv	a0,s1
    800044e4:	ffffe097          	auipc	ra,0xffffe
    800044e8:	d3e080e7          	jalr	-706(ra) # 80002222 <wakeup>
  release(&lk->lk);
    800044ec:	854a                	mv	a0,s2
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	7e0080e7          	jalr	2016(ra) # 80000cce <release>
}
    800044f6:	60e2                	ld	ra,24(sp)
    800044f8:	6442                	ld	s0,16(sp)
    800044fa:	64a2                	ld	s1,8(sp)
    800044fc:	6902                	ld	s2,0(sp)
    800044fe:	6105                	addi	sp,sp,32
    80004500:	8082                	ret

0000000080004502 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004502:	7179                	addi	sp,sp,-48
    80004504:	f406                	sd	ra,40(sp)
    80004506:	f022                	sd	s0,32(sp)
    80004508:	ec26                	sd	s1,24(sp)
    8000450a:	e84a                	sd	s2,16(sp)
    8000450c:	e44e                	sd	s3,8(sp)
    8000450e:	1800                	addi	s0,sp,48
    80004510:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004512:	00850913          	addi	s2,a0,8
    80004516:	854a                	mv	a0,s2
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	702080e7          	jalr	1794(ra) # 80000c1a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004520:	409c                	lw	a5,0(s1)
    80004522:	ef99                	bnez	a5,80004540 <holdingsleep+0x3e>
    80004524:	4481                	li	s1,0
  release(&lk->lk);
    80004526:	854a                	mv	a0,s2
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	7a6080e7          	jalr	1958(ra) # 80000cce <release>
  return r;
}
    80004530:	8526                	mv	a0,s1
    80004532:	70a2                	ld	ra,40(sp)
    80004534:	7402                	ld	s0,32(sp)
    80004536:	64e2                	ld	s1,24(sp)
    80004538:	6942                	ld	s2,16(sp)
    8000453a:	69a2                	ld	s3,8(sp)
    8000453c:	6145                	addi	sp,sp,48
    8000453e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004540:	0284a983          	lw	s3,40(s1)
    80004544:	ffffd097          	auipc	ra,0xffffd
    80004548:	48e080e7          	jalr	1166(ra) # 800019d2 <myproc>
    8000454c:	5904                	lw	s1,48(a0)
    8000454e:	413484b3          	sub	s1,s1,s3
    80004552:	0014b493          	seqz	s1,s1
    80004556:	bfc1                	j	80004526 <holdingsleep+0x24>

0000000080004558 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004558:	1141                	addi	sp,sp,-16
    8000455a:	e406                	sd	ra,8(sp)
    8000455c:	e022                	sd	s0,0(sp)
    8000455e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004560:	00004597          	auipc	a1,0x4
    80004564:	19058593          	addi	a1,a1,400 # 800086f0 <syscalls+0x248>
    80004568:	0001d517          	auipc	a0,0x1d
    8000456c:	e5050513          	addi	a0,a0,-432 # 800213b8 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	61a080e7          	jalr	1562(ra) # 80000b8a <initlock>
}
    80004578:	60a2                	ld	ra,8(sp)
    8000457a:	6402                	ld	s0,0(sp)
    8000457c:	0141                	addi	sp,sp,16
    8000457e:	8082                	ret

0000000080004580 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	e426                	sd	s1,8(sp)
    80004588:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000458a:	0001d517          	auipc	a0,0x1d
    8000458e:	e2e50513          	addi	a0,a0,-466 # 800213b8 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	688080e7          	jalr	1672(ra) # 80000c1a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459a:	0001d497          	auipc	s1,0x1d
    8000459e:	e3648493          	addi	s1,s1,-458 # 800213d0 <ftable+0x18>
    800045a2:	0001e717          	auipc	a4,0x1e
    800045a6:	dce70713          	addi	a4,a4,-562 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800045aa:	40dc                	lw	a5,4(s1)
    800045ac:	cf99                	beqz	a5,800045ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ae:	02848493          	addi	s1,s1,40
    800045b2:	fee49ce3          	bne	s1,a4,800045aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045b6:	0001d517          	auipc	a0,0x1d
    800045ba:	e0250513          	addi	a0,a0,-510 # 800213b8 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	710080e7          	jalr	1808(ra) # 80000cce <release>
  return 0;
    800045c6:	4481                	li	s1,0
    800045c8:	a819                	j	800045de <filealloc+0x5e>
      f->ref = 1;
    800045ca:	4785                	li	a5,1
    800045cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	dea50513          	addi	a0,a0,-534 # 800213b8 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6f8080e7          	jalr	1784(ra) # 80000cce <release>
}
    800045de:	8526                	mv	a0,s1
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ea:	1101                	addi	sp,sp,-32
    800045ec:	ec06                	sd	ra,24(sp)
    800045ee:	e822                	sd	s0,16(sp)
    800045f0:	e426                	sd	s1,8(sp)
    800045f2:	1000                	addi	s0,sp,32
    800045f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045f6:	0001d517          	auipc	a0,0x1d
    800045fa:	dc250513          	addi	a0,a0,-574 # 800213b8 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	61c080e7          	jalr	1564(ra) # 80000c1a <acquire>
  if(f->ref < 1)
    80004606:	40dc                	lw	a5,4(s1)
    80004608:	02f05263          	blez	a5,8000462c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000460c:	2785                	addiw	a5,a5,1
    8000460e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004610:	0001d517          	auipc	a0,0x1d
    80004614:	da850513          	addi	a0,a0,-600 # 800213b8 <ftable>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	6b6080e7          	jalr	1718(ra) # 80000cce <release>
  return f;
}
    80004620:	8526                	mv	a0,s1
    80004622:	60e2                	ld	ra,24(sp)
    80004624:	6442                	ld	s0,16(sp)
    80004626:	64a2                	ld	s1,8(sp)
    80004628:	6105                	addi	sp,sp,32
    8000462a:	8082                	ret
    panic("filedup");
    8000462c:	00004517          	auipc	a0,0x4
    80004630:	0cc50513          	addi	a0,a0,204 # 800086f8 <syscalls+0x250>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	f06080e7          	jalr	-250(ra) # 8000053a <panic>

000000008000463c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000463c:	7139                	addi	sp,sp,-64
    8000463e:	fc06                	sd	ra,56(sp)
    80004640:	f822                	sd	s0,48(sp)
    80004642:	f426                	sd	s1,40(sp)
    80004644:	f04a                	sd	s2,32(sp)
    80004646:	ec4e                	sd	s3,24(sp)
    80004648:	e852                	sd	s4,16(sp)
    8000464a:	e456                	sd	s5,8(sp)
    8000464c:	0080                	addi	s0,sp,64
    8000464e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004650:	0001d517          	auipc	a0,0x1d
    80004654:	d6850513          	addi	a0,a0,-664 # 800213b8 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	5c2080e7          	jalr	1474(ra) # 80000c1a <acquire>
  if(f->ref < 1)
    80004660:	40dc                	lw	a5,4(s1)
    80004662:	06f05163          	blez	a5,800046c4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004666:	37fd                	addiw	a5,a5,-1
    80004668:	0007871b          	sext.w	a4,a5
    8000466c:	c0dc                	sw	a5,4(s1)
    8000466e:	06e04363          	bgtz	a4,800046d4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004672:	0004a903          	lw	s2,0(s1)
    80004676:	0094ca83          	lbu	s5,9(s1)
    8000467a:	0104ba03          	ld	s4,16(s1)
    8000467e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004682:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004686:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000468a:	0001d517          	auipc	a0,0x1d
    8000468e:	d2e50513          	addi	a0,a0,-722 # 800213b8 <ftable>
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	63c080e7          	jalr	1596(ra) # 80000cce <release>

  if(ff.type == FD_PIPE){
    8000469a:	4785                	li	a5,1
    8000469c:	04f90d63          	beq	s2,a5,800046f6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a0:	3979                	addiw	s2,s2,-2
    800046a2:	4785                	li	a5,1
    800046a4:	0527e063          	bltu	a5,s2,800046e4 <fileclose+0xa8>
    begin_op();
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	acc080e7          	jalr	-1332(ra) # 80004174 <begin_op>
    iput(ff.ip);
    800046b0:	854e                	mv	a0,s3
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	2a0080e7          	jalr	672(ra) # 80003952 <iput>
    end_op();
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	b38080e7          	jalr	-1224(ra) # 800041f2 <end_op>
    800046c2:	a00d                	j	800046e4 <fileclose+0xa8>
    panic("fileclose");
    800046c4:	00004517          	auipc	a0,0x4
    800046c8:	03c50513          	addi	a0,a0,60 # 80008700 <syscalls+0x258>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	e6e080e7          	jalr	-402(ra) # 8000053a <panic>
    release(&ftable.lock);
    800046d4:	0001d517          	auipc	a0,0x1d
    800046d8:	ce450513          	addi	a0,a0,-796 # 800213b8 <ftable>
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	5f2080e7          	jalr	1522(ra) # 80000cce <release>
  }
}
    800046e4:	70e2                	ld	ra,56(sp)
    800046e6:	7442                	ld	s0,48(sp)
    800046e8:	74a2                	ld	s1,40(sp)
    800046ea:	7902                	ld	s2,32(sp)
    800046ec:	69e2                	ld	s3,24(sp)
    800046ee:	6a42                	ld	s4,16(sp)
    800046f0:	6aa2                	ld	s5,8(sp)
    800046f2:	6121                	addi	sp,sp,64
    800046f4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046f6:	85d6                	mv	a1,s5
    800046f8:	8552                	mv	a0,s4
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	34c080e7          	jalr	844(ra) # 80004a46 <pipeclose>
    80004702:	b7cd                	j	800046e4 <fileclose+0xa8>

0000000080004704 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004704:	715d                	addi	sp,sp,-80
    80004706:	e486                	sd	ra,72(sp)
    80004708:	e0a2                	sd	s0,64(sp)
    8000470a:	fc26                	sd	s1,56(sp)
    8000470c:	f84a                	sd	s2,48(sp)
    8000470e:	f44e                	sd	s3,40(sp)
    80004710:	0880                	addi	s0,sp,80
    80004712:	84aa                	mv	s1,a0
    80004714:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004716:	ffffd097          	auipc	ra,0xffffd
    8000471a:	2bc080e7          	jalr	700(ra) # 800019d2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000471e:	409c                	lw	a5,0(s1)
    80004720:	37f9                	addiw	a5,a5,-2
    80004722:	4705                	li	a4,1
    80004724:	04f76763          	bltu	a4,a5,80004772 <filestat+0x6e>
    80004728:	892a                	mv	s2,a0
    ilock(f->ip);
    8000472a:	6c88                	ld	a0,24(s1)
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	06c080e7          	jalr	108(ra) # 80003798 <ilock>
    stati(f->ip, &st);
    80004734:	fb840593          	addi	a1,s0,-72
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	2e8080e7          	jalr	744(ra) # 80003a22 <stati>
    iunlock(f->ip);
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	116080e7          	jalr	278(ra) # 8000385a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000474c:	46e1                	li	a3,24
    8000474e:	fb840613          	addi	a2,s0,-72
    80004752:	85ce                	mv	a1,s3
    80004754:	05093503          	ld	a0,80(s2)
    80004758:	ffffd097          	auipc	ra,0xffffd
    8000475c:	f3e080e7          	jalr	-194(ra) # 80001696 <copyout>
    80004760:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004764:	60a6                	ld	ra,72(sp)
    80004766:	6406                	ld	s0,64(sp)
    80004768:	74e2                	ld	s1,56(sp)
    8000476a:	7942                	ld	s2,48(sp)
    8000476c:	79a2                	ld	s3,40(sp)
    8000476e:	6161                	addi	sp,sp,80
    80004770:	8082                	ret
  return -1;
    80004772:	557d                	li	a0,-1
    80004774:	bfc5                	j	80004764 <filestat+0x60>

0000000080004776 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004776:	7179                	addi	sp,sp,-48
    80004778:	f406                	sd	ra,40(sp)
    8000477a:	f022                	sd	s0,32(sp)
    8000477c:	ec26                	sd	s1,24(sp)
    8000477e:	e84a                	sd	s2,16(sp)
    80004780:	e44e                	sd	s3,8(sp)
    80004782:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004784:	00854783          	lbu	a5,8(a0)
    80004788:	c3d5                	beqz	a5,8000482c <fileread+0xb6>
    8000478a:	84aa                	mv	s1,a0
    8000478c:	89ae                	mv	s3,a1
    8000478e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004790:	411c                	lw	a5,0(a0)
    80004792:	4705                	li	a4,1
    80004794:	04e78963          	beq	a5,a4,800047e6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004798:	470d                	li	a4,3
    8000479a:	04e78d63          	beq	a5,a4,800047f4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000479e:	4709                	li	a4,2
    800047a0:	06e79e63          	bne	a5,a4,8000481c <fileread+0xa6>
    ilock(f->ip);
    800047a4:	6d08                	ld	a0,24(a0)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	ff2080e7          	jalr	-14(ra) # 80003798 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ae:	874a                	mv	a4,s2
    800047b0:	5094                	lw	a3,32(s1)
    800047b2:	864e                	mv	a2,s3
    800047b4:	4585                	li	a1,1
    800047b6:	6c88                	ld	a0,24(s1)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	294080e7          	jalr	660(ra) # 80003a4c <readi>
    800047c0:	892a                	mv	s2,a0
    800047c2:	00a05563          	blez	a0,800047cc <fileread+0x56>
      f->off += r;
    800047c6:	509c                	lw	a5,32(s1)
    800047c8:	9fa9                	addw	a5,a5,a0
    800047ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047cc:	6c88                	ld	a0,24(s1)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	08c080e7          	jalr	140(ra) # 8000385a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047d6:	854a                	mv	a0,s2
    800047d8:	70a2                	ld	ra,40(sp)
    800047da:	7402                	ld	s0,32(sp)
    800047dc:	64e2                	ld	s1,24(sp)
    800047de:	6942                	ld	s2,16(sp)
    800047e0:	69a2                	ld	s3,8(sp)
    800047e2:	6145                	addi	sp,sp,48
    800047e4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047e6:	6908                	ld	a0,16(a0)
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	3c0080e7          	jalr	960(ra) # 80004ba8 <piperead>
    800047f0:	892a                	mv	s2,a0
    800047f2:	b7d5                	j	800047d6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047f4:	02451783          	lh	a5,36(a0)
    800047f8:	03079693          	slli	a3,a5,0x30
    800047fc:	92c1                	srli	a3,a3,0x30
    800047fe:	4725                	li	a4,9
    80004800:	02d76863          	bltu	a4,a3,80004830 <fileread+0xba>
    80004804:	0792                	slli	a5,a5,0x4
    80004806:	0001d717          	auipc	a4,0x1d
    8000480a:	b1270713          	addi	a4,a4,-1262 # 80021318 <devsw>
    8000480e:	97ba                	add	a5,a5,a4
    80004810:	639c                	ld	a5,0(a5)
    80004812:	c38d                	beqz	a5,80004834 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004814:	4505                	li	a0,1
    80004816:	9782                	jalr	a5
    80004818:	892a                	mv	s2,a0
    8000481a:	bf75                	j	800047d6 <fileread+0x60>
    panic("fileread");
    8000481c:	00004517          	auipc	a0,0x4
    80004820:	ef450513          	addi	a0,a0,-268 # 80008710 <syscalls+0x268>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	d16080e7          	jalr	-746(ra) # 8000053a <panic>
    return -1;
    8000482c:	597d                	li	s2,-1
    8000482e:	b765                	j	800047d6 <fileread+0x60>
      return -1;
    80004830:	597d                	li	s2,-1
    80004832:	b755                	j	800047d6 <fileread+0x60>
    80004834:	597d                	li	s2,-1
    80004836:	b745                	j	800047d6 <fileread+0x60>

0000000080004838 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004838:	715d                	addi	sp,sp,-80
    8000483a:	e486                	sd	ra,72(sp)
    8000483c:	e0a2                	sd	s0,64(sp)
    8000483e:	fc26                	sd	s1,56(sp)
    80004840:	f84a                	sd	s2,48(sp)
    80004842:	f44e                	sd	s3,40(sp)
    80004844:	f052                	sd	s4,32(sp)
    80004846:	ec56                	sd	s5,24(sp)
    80004848:	e85a                	sd	s6,16(sp)
    8000484a:	e45e                	sd	s7,8(sp)
    8000484c:	e062                	sd	s8,0(sp)
    8000484e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004850:	00954783          	lbu	a5,9(a0)
    80004854:	10078663          	beqz	a5,80004960 <filewrite+0x128>
    80004858:	892a                	mv	s2,a0
    8000485a:	8b2e                	mv	s6,a1
    8000485c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000485e:	411c                	lw	a5,0(a0)
    80004860:	4705                	li	a4,1
    80004862:	02e78263          	beq	a5,a4,80004886 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004866:	470d                	li	a4,3
    80004868:	02e78663          	beq	a5,a4,80004894 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000486c:	4709                	li	a4,2
    8000486e:	0ee79163          	bne	a5,a4,80004950 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004872:	0ac05d63          	blez	a2,8000492c <filewrite+0xf4>
    int i = 0;
    80004876:	4981                	li	s3,0
    80004878:	6b85                	lui	s7,0x1
    8000487a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000487e:	6c05                	lui	s8,0x1
    80004880:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004884:	a861                	j	8000491c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004886:	6908                	ld	a0,16(a0)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	22e080e7          	jalr	558(ra) # 80004ab6 <pipewrite>
    80004890:	8a2a                	mv	s4,a0
    80004892:	a045                	j	80004932 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004894:	02451783          	lh	a5,36(a0)
    80004898:	03079693          	slli	a3,a5,0x30
    8000489c:	92c1                	srli	a3,a3,0x30
    8000489e:	4725                	li	a4,9
    800048a0:	0cd76263          	bltu	a4,a3,80004964 <filewrite+0x12c>
    800048a4:	0792                	slli	a5,a5,0x4
    800048a6:	0001d717          	auipc	a4,0x1d
    800048aa:	a7270713          	addi	a4,a4,-1422 # 80021318 <devsw>
    800048ae:	97ba                	add	a5,a5,a4
    800048b0:	679c                	ld	a5,8(a5)
    800048b2:	cbdd                	beqz	a5,80004968 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048b4:	4505                	li	a0,1
    800048b6:	9782                	jalr	a5
    800048b8:	8a2a                	mv	s4,a0
    800048ba:	a8a5                	j	80004932 <filewrite+0xfa>
    800048bc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	8b4080e7          	jalr	-1868(ra) # 80004174 <begin_op>
      ilock(f->ip);
    800048c8:	01893503          	ld	a0,24(s2)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	ecc080e7          	jalr	-308(ra) # 80003798 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048d4:	8756                	mv	a4,s5
    800048d6:	02092683          	lw	a3,32(s2)
    800048da:	01698633          	add	a2,s3,s6
    800048de:	4585                	li	a1,1
    800048e0:	01893503          	ld	a0,24(s2)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	260080e7          	jalr	608(ra) # 80003b44 <writei>
    800048ec:	84aa                	mv	s1,a0
    800048ee:	00a05763          	blez	a0,800048fc <filewrite+0xc4>
        f->off += r;
    800048f2:	02092783          	lw	a5,32(s2)
    800048f6:	9fa9                	addw	a5,a5,a0
    800048f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048fc:	01893503          	ld	a0,24(s2)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	f5a080e7          	jalr	-166(ra) # 8000385a <iunlock>
      end_op();
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	8ea080e7          	jalr	-1814(ra) # 800041f2 <end_op>

      if(r != n1){
    80004910:	009a9f63          	bne	s5,s1,8000492e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004914:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004918:	0149db63          	bge	s3,s4,8000492e <filewrite+0xf6>
      int n1 = n - i;
    8000491c:	413a04bb          	subw	s1,s4,s3
    80004920:	0004879b          	sext.w	a5,s1
    80004924:	f8fbdce3          	bge	s7,a5,800048bc <filewrite+0x84>
    80004928:	84e2                	mv	s1,s8
    8000492a:	bf49                	j	800048bc <filewrite+0x84>
    int i = 0;
    8000492c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000492e:	013a1f63          	bne	s4,s3,8000494c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004932:	8552                	mv	a0,s4
    80004934:	60a6                	ld	ra,72(sp)
    80004936:	6406                	ld	s0,64(sp)
    80004938:	74e2                	ld	s1,56(sp)
    8000493a:	7942                	ld	s2,48(sp)
    8000493c:	79a2                	ld	s3,40(sp)
    8000493e:	7a02                	ld	s4,32(sp)
    80004940:	6ae2                	ld	s5,24(sp)
    80004942:	6b42                	ld	s6,16(sp)
    80004944:	6ba2                	ld	s7,8(sp)
    80004946:	6c02                	ld	s8,0(sp)
    80004948:	6161                	addi	sp,sp,80
    8000494a:	8082                	ret
    ret = (i == n ? n : -1);
    8000494c:	5a7d                	li	s4,-1
    8000494e:	b7d5                	j	80004932 <filewrite+0xfa>
    panic("filewrite");
    80004950:	00004517          	auipc	a0,0x4
    80004954:	dd050513          	addi	a0,a0,-560 # 80008720 <syscalls+0x278>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	be2080e7          	jalr	-1054(ra) # 8000053a <panic>
    return -1;
    80004960:	5a7d                	li	s4,-1
    80004962:	bfc1                	j	80004932 <filewrite+0xfa>
      return -1;
    80004964:	5a7d                	li	s4,-1
    80004966:	b7f1                	j	80004932 <filewrite+0xfa>
    80004968:	5a7d                	li	s4,-1
    8000496a:	b7e1                	j	80004932 <filewrite+0xfa>

000000008000496c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000496c:	7179                	addi	sp,sp,-48
    8000496e:	f406                	sd	ra,40(sp)
    80004970:	f022                	sd	s0,32(sp)
    80004972:	ec26                	sd	s1,24(sp)
    80004974:	e84a                	sd	s2,16(sp)
    80004976:	e44e                	sd	s3,8(sp)
    80004978:	e052                	sd	s4,0(sp)
    8000497a:	1800                	addi	s0,sp,48
    8000497c:	84aa                	mv	s1,a0
    8000497e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004980:	0005b023          	sd	zero,0(a1)
    80004984:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	bf8080e7          	jalr	-1032(ra) # 80004580 <filealloc>
    80004990:	e088                	sd	a0,0(s1)
    80004992:	c551                	beqz	a0,80004a1e <pipealloc+0xb2>
    80004994:	00000097          	auipc	ra,0x0
    80004998:	bec080e7          	jalr	-1044(ra) # 80004580 <filealloc>
    8000499c:	00aa3023          	sd	a0,0(s4)
    800049a0:	c92d                	beqz	a0,80004a12 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	13e080e7          	jalr	318(ra) # 80000ae0 <kalloc>
    800049aa:	892a                	mv	s2,a0
    800049ac:	c125                	beqz	a0,80004a0c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ae:	4985                	li	s3,1
    800049b0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049b4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049b8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049bc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c0:	00004597          	auipc	a1,0x4
    800049c4:	d7058593          	addi	a1,a1,-656 # 80008730 <syscalls+0x288>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	1c2080e7          	jalr	450(ra) # 80000b8a <initlock>
  (*f0)->type = FD_PIPE;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049d6:	609c                	ld	a5,0(s1)
    800049d8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049dc:	609c                	ld	a5,0(s1)
    800049de:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e2:	609c                	ld	a5,0(s1)
    800049e4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049e8:	000a3783          	ld	a5,0(s4)
    800049ec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a08:	4501                	li	a0,0
    80004a0a:	a025                	j	80004a32 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a0c:	6088                	ld	a0,0(s1)
    80004a0e:	e501                	bnez	a0,80004a16 <pipealloc+0xaa>
    80004a10:	a039                	j	80004a1e <pipealloc+0xb2>
    80004a12:	6088                	ld	a0,0(s1)
    80004a14:	c51d                	beqz	a0,80004a42 <pipealloc+0xd6>
    fileclose(*f0);
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	c26080e7          	jalr	-986(ra) # 8000463c <fileclose>
  if(*f1)
    80004a1e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a22:	557d                	li	a0,-1
  if(*f1)
    80004a24:	c799                	beqz	a5,80004a32 <pipealloc+0xc6>
    fileclose(*f1);
    80004a26:	853e                	mv	a0,a5
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	c14080e7          	jalr	-1004(ra) # 8000463c <fileclose>
  return -1;
    80004a30:	557d                	li	a0,-1
}
    80004a32:	70a2                	ld	ra,40(sp)
    80004a34:	7402                	ld	s0,32(sp)
    80004a36:	64e2                	ld	s1,24(sp)
    80004a38:	6942                	ld	s2,16(sp)
    80004a3a:	69a2                	ld	s3,8(sp)
    80004a3c:	6a02                	ld	s4,0(sp)
    80004a3e:	6145                	addi	sp,sp,48
    80004a40:	8082                	ret
  return -1;
    80004a42:	557d                	li	a0,-1
    80004a44:	b7fd                	j	80004a32 <pipealloc+0xc6>

0000000080004a46 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a46:	1101                	addi	sp,sp,-32
    80004a48:	ec06                	sd	ra,24(sp)
    80004a4a:	e822                	sd	s0,16(sp)
    80004a4c:	e426                	sd	s1,8(sp)
    80004a4e:	e04a                	sd	s2,0(sp)
    80004a50:	1000                	addi	s0,sp,32
    80004a52:	84aa                	mv	s1,a0
    80004a54:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	1c4080e7          	jalr	452(ra) # 80000c1a <acquire>
  if(writable){
    80004a5e:	02090d63          	beqz	s2,80004a98 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a62:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a66:	21848513          	addi	a0,s1,536
    80004a6a:	ffffd097          	auipc	ra,0xffffd
    80004a6e:	7b8080e7          	jalr	1976(ra) # 80002222 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a72:	2204b783          	ld	a5,544(s1)
    80004a76:	eb95                	bnez	a5,80004aaa <pipeclose+0x64>
    release(&pi->lock);
    80004a78:	8526                	mv	a0,s1
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	254080e7          	jalr	596(ra) # 80000cce <release>
    kfree((char*)pi);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	f5e080e7          	jalr	-162(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret
    pi->readopen = 0;
    80004a98:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a9c:	21c48513          	addi	a0,s1,540
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	782080e7          	jalr	1922(ra) # 80002222 <wakeup>
    80004aa8:	b7e9                	j	80004a72 <pipeclose+0x2c>
    release(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	222080e7          	jalr	546(ra) # 80000cce <release>
}
    80004ab4:	bfe1                	j	80004a8c <pipeclose+0x46>

0000000080004ab6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ab6:	711d                	addi	sp,sp,-96
    80004ab8:	ec86                	sd	ra,88(sp)
    80004aba:	e8a2                	sd	s0,80(sp)
    80004abc:	e4a6                	sd	s1,72(sp)
    80004abe:	e0ca                	sd	s2,64(sp)
    80004ac0:	fc4e                	sd	s3,56(sp)
    80004ac2:	f852                	sd	s4,48(sp)
    80004ac4:	f456                	sd	s5,40(sp)
    80004ac6:	f05a                	sd	s6,32(sp)
    80004ac8:	ec5e                	sd	s7,24(sp)
    80004aca:	e862                	sd	s8,16(sp)
    80004acc:	1080                	addi	s0,sp,96
    80004ace:	84aa                	mv	s1,a0
    80004ad0:	8aae                	mv	s5,a1
    80004ad2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	efe080e7          	jalr	-258(ra) # 800019d2 <myproc>
    80004adc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	13a080e7          	jalr	314(ra) # 80000c1a <acquire>
  while(i < n){
    80004ae8:	0b405363          	blez	s4,80004b8e <pipewrite+0xd8>
  int i = 0;
    80004aec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004af0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af4:	21c48b93          	addi	s7,s1,540
    80004af8:	a089                	j	80004b3a <pipewrite+0x84>
      release(&pi->lock);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	1d2080e7          	jalr	466(ra) # 80000cce <release>
      return -1;
    80004b04:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b06:	854a                	mv	a0,s2
    80004b08:	60e6                	ld	ra,88(sp)
    80004b0a:	6446                	ld	s0,80(sp)
    80004b0c:	64a6                	ld	s1,72(sp)
    80004b0e:	6906                	ld	s2,64(sp)
    80004b10:	79e2                	ld	s3,56(sp)
    80004b12:	7a42                	ld	s4,48(sp)
    80004b14:	7aa2                	ld	s5,40(sp)
    80004b16:	7b02                	ld	s6,32(sp)
    80004b18:	6be2                	ld	s7,24(sp)
    80004b1a:	6c42                	ld	s8,16(sp)
    80004b1c:	6125                	addi	sp,sp,96
    80004b1e:	8082                	ret
      wakeup(&pi->nread);
    80004b20:	8562                	mv	a0,s8
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	700080e7          	jalr	1792(ra) # 80002222 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b2a:	85a6                	mv	a1,s1
    80004b2c:	855e                	mv	a0,s7
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	568080e7          	jalr	1384(ra) # 80002096 <sleep>
  while(i < n){
    80004b36:	05495d63          	bge	s2,s4,80004b90 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004b3a:	2204a783          	lw	a5,544(s1)
    80004b3e:	dfd5                	beqz	a5,80004afa <pipewrite+0x44>
    80004b40:	0289a783          	lw	a5,40(s3)
    80004b44:	fbdd                	bnez	a5,80004afa <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b46:	2184a783          	lw	a5,536(s1)
    80004b4a:	21c4a703          	lw	a4,540(s1)
    80004b4e:	2007879b          	addiw	a5,a5,512
    80004b52:	fcf707e3          	beq	a4,a5,80004b20 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b56:	4685                	li	a3,1
    80004b58:	01590633          	add	a2,s2,s5
    80004b5c:	faf40593          	addi	a1,s0,-81
    80004b60:	0509b503          	ld	a0,80(s3)
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	bbe080e7          	jalr	-1090(ra) # 80001722 <copyin>
    80004b6c:	03650263          	beq	a0,s6,80004b90 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b70:	21c4a783          	lw	a5,540(s1)
    80004b74:	0017871b          	addiw	a4,a5,1
    80004b78:	20e4ae23          	sw	a4,540(s1)
    80004b7c:	1ff7f793          	andi	a5,a5,511
    80004b80:	97a6                	add	a5,a5,s1
    80004b82:	faf44703          	lbu	a4,-81(s0)
    80004b86:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b8a:	2905                	addiw	s2,s2,1
    80004b8c:	b76d                	j	80004b36 <pipewrite+0x80>
  int i = 0;
    80004b8e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b90:	21848513          	addi	a0,s1,536
    80004b94:	ffffd097          	auipc	ra,0xffffd
    80004b98:	68e080e7          	jalr	1678(ra) # 80002222 <wakeup>
  release(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	130080e7          	jalr	304(ra) # 80000cce <release>
  return i;
    80004ba6:	b785                	j	80004b06 <pipewrite+0x50>

0000000080004ba8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba8:	715d                	addi	sp,sp,-80
    80004baa:	e486                	sd	ra,72(sp)
    80004bac:	e0a2                	sd	s0,64(sp)
    80004bae:	fc26                	sd	s1,56(sp)
    80004bb0:	f84a                	sd	s2,48(sp)
    80004bb2:	f44e                	sd	s3,40(sp)
    80004bb4:	f052                	sd	s4,32(sp)
    80004bb6:	ec56                	sd	s5,24(sp)
    80004bb8:	e85a                	sd	s6,16(sp)
    80004bba:	0880                	addi	s0,sp,80
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	892e                	mv	s2,a1
    80004bc0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	e10080e7          	jalr	-496(ra) # 800019d2 <myproc>
    80004bca:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	04c080e7          	jalr	76(ra) # 80000c1a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd6:	2184a703          	lw	a4,536(s1)
    80004bda:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bde:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be2:	02f71463          	bne	a4,a5,80004c0a <piperead+0x62>
    80004be6:	2244a783          	lw	a5,548(s1)
    80004bea:	c385                	beqz	a5,80004c0a <piperead+0x62>
    if(pr->killed){
    80004bec:	028a2783          	lw	a5,40(s4)
    80004bf0:	ebc9                	bnez	a5,80004c82 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf2:	85a6                	mv	a1,s1
    80004bf4:	854e                	mv	a0,s3
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	4a0080e7          	jalr	1184(ra) # 80002096 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfe:	2184a703          	lw	a4,536(s1)
    80004c02:	21c4a783          	lw	a5,540(s1)
    80004c06:	fef700e3          	beq	a4,a5,80004be6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c0c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0e:	05505463          	blez	s5,80004c56 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004c12:	2184a783          	lw	a5,536(s1)
    80004c16:	21c4a703          	lw	a4,540(s1)
    80004c1a:	02f70e63          	beq	a4,a5,80004c56 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c1e:	0017871b          	addiw	a4,a5,1
    80004c22:	20e4ac23          	sw	a4,536(s1)
    80004c26:	1ff7f793          	andi	a5,a5,511
    80004c2a:	97a6                	add	a5,a5,s1
    80004c2c:	0187c783          	lbu	a5,24(a5)
    80004c30:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c34:	4685                	li	a3,1
    80004c36:	fbf40613          	addi	a2,s0,-65
    80004c3a:	85ca                	mv	a1,s2
    80004c3c:	050a3503          	ld	a0,80(s4)
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	a56080e7          	jalr	-1450(ra) # 80001696 <copyout>
    80004c48:	01650763          	beq	a0,s6,80004c56 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4c:	2985                	addiw	s3,s3,1
    80004c4e:	0905                	addi	s2,s2,1
    80004c50:	fd3a91e3          	bne	s5,s3,80004c12 <piperead+0x6a>
    80004c54:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c56:	21c48513          	addi	a0,s1,540
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	5c8080e7          	jalr	1480(ra) # 80002222 <wakeup>
  release(&pi->lock);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	06a080e7          	jalr	106(ra) # 80000cce <release>
  return i;
}
    80004c6c:	854e                	mv	a0,s3
    80004c6e:	60a6                	ld	ra,72(sp)
    80004c70:	6406                	ld	s0,64(sp)
    80004c72:	74e2                	ld	s1,56(sp)
    80004c74:	7942                	ld	s2,48(sp)
    80004c76:	79a2                	ld	s3,40(sp)
    80004c78:	7a02                	ld	s4,32(sp)
    80004c7a:	6ae2                	ld	s5,24(sp)
    80004c7c:	6b42                	ld	s6,16(sp)
    80004c7e:	6161                	addi	sp,sp,80
    80004c80:	8082                	ret
      release(&pi->lock);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	04a080e7          	jalr	74(ra) # 80000cce <release>
      return -1;
    80004c8c:	59fd                	li	s3,-1
    80004c8e:	bff9                	j	80004c6c <piperead+0xc4>

0000000080004c90 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c90:	de010113          	addi	sp,sp,-544
    80004c94:	20113c23          	sd	ra,536(sp)
    80004c98:	20813823          	sd	s0,528(sp)
    80004c9c:	20913423          	sd	s1,520(sp)
    80004ca0:	21213023          	sd	s2,512(sp)
    80004ca4:	ffce                	sd	s3,504(sp)
    80004ca6:	fbd2                	sd	s4,496(sp)
    80004ca8:	f7d6                	sd	s5,488(sp)
    80004caa:	f3da                	sd	s6,480(sp)
    80004cac:	efde                	sd	s7,472(sp)
    80004cae:	ebe2                	sd	s8,464(sp)
    80004cb0:	e7e6                	sd	s9,456(sp)
    80004cb2:	e3ea                	sd	s10,448(sp)
    80004cb4:	ff6e                	sd	s11,440(sp)
    80004cb6:	1400                	addi	s0,sp,544
    80004cb8:	892a                	mv	s2,a0
    80004cba:	dea43423          	sd	a0,-536(s0)
    80004cbe:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	d10080e7          	jalr	-752(ra) # 800019d2 <myproc>
    80004cca:	84aa                	mv	s1,a0

  begin_op();
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	4a8080e7          	jalr	1192(ra) # 80004174 <begin_op>

  if((ip = namei(path)) == 0){
    80004cd4:	854a                	mv	a0,s2
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	27e080e7          	jalr	638(ra) # 80003f54 <namei>
    80004cde:	c93d                	beqz	a0,80004d54 <exec+0xc4>
    80004ce0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	ab6080e7          	jalr	-1354(ra) # 80003798 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cea:	04000713          	li	a4,64
    80004cee:	4681                	li	a3,0
    80004cf0:	e5040613          	addi	a2,s0,-432
    80004cf4:	4581                	li	a1,0
    80004cf6:	8556                	mv	a0,s5
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	d54080e7          	jalr	-684(ra) # 80003a4c <readi>
    80004d00:	04000793          	li	a5,64
    80004d04:	00f51a63          	bne	a0,a5,80004d18 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d08:	e5042703          	lw	a4,-432(s0)
    80004d0c:	464c47b7          	lui	a5,0x464c4
    80004d10:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d14:	04f70663          	beq	a4,a5,80004d60 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d18:	8556                	mv	a0,s5
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	ce0080e7          	jalr	-800(ra) # 800039fa <iunlockput>
    end_op();
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	4d0080e7          	jalr	1232(ra) # 800041f2 <end_op>
  }
  return -1;
    80004d2a:	557d                	li	a0,-1
}
    80004d2c:	21813083          	ld	ra,536(sp)
    80004d30:	21013403          	ld	s0,528(sp)
    80004d34:	20813483          	ld	s1,520(sp)
    80004d38:	20013903          	ld	s2,512(sp)
    80004d3c:	79fe                	ld	s3,504(sp)
    80004d3e:	7a5e                	ld	s4,496(sp)
    80004d40:	7abe                	ld	s5,488(sp)
    80004d42:	7b1e                	ld	s6,480(sp)
    80004d44:	6bfe                	ld	s7,472(sp)
    80004d46:	6c5e                	ld	s8,464(sp)
    80004d48:	6cbe                	ld	s9,456(sp)
    80004d4a:	6d1e                	ld	s10,448(sp)
    80004d4c:	7dfa                	ld	s11,440(sp)
    80004d4e:	22010113          	addi	sp,sp,544
    80004d52:	8082                	ret
    end_op();
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	49e080e7          	jalr	1182(ra) # 800041f2 <end_op>
    return -1;
    80004d5c:	557d                	li	a0,-1
    80004d5e:	b7f9                	j	80004d2c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffd097          	auipc	ra,0xffffd
    80004d66:	d34080e7          	jalr	-716(ra) # 80001a96 <proc_pagetable>
    80004d6a:	8b2a                	mv	s6,a0
    80004d6c:	d555                	beqz	a0,80004d18 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d6e:	e7042783          	lw	a5,-400(s0)
    80004d72:	e8845703          	lhu	a4,-376(s0)
    80004d76:	c735                	beqz	a4,80004de2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d78:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d7a:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004d7e:	6a05                	lui	s4,0x1
    80004d80:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d84:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d88:	6d85                	lui	s11,0x1
    80004d8a:	7d7d                	lui	s10,0xfffff
    80004d8c:	ac1d                	j	80004fc2 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d8e:	00004517          	auipc	a0,0x4
    80004d92:	9aa50513          	addi	a0,a0,-1622 # 80008738 <syscalls+0x290>
    80004d96:	ffffb097          	auipc	ra,0xffffb
    80004d9a:	7a4080e7          	jalr	1956(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d9e:	874a                	mv	a4,s2
    80004da0:	009c86bb          	addw	a3,s9,s1
    80004da4:	4581                	li	a1,0
    80004da6:	8556                	mv	a0,s5
    80004da8:	fffff097          	auipc	ra,0xfffff
    80004dac:	ca4080e7          	jalr	-860(ra) # 80003a4c <readi>
    80004db0:	2501                	sext.w	a0,a0
    80004db2:	1aa91863          	bne	s2,a0,80004f62 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004db6:	009d84bb          	addw	s1,s11,s1
    80004dba:	013d09bb          	addw	s3,s10,s3
    80004dbe:	1f74f263          	bgeu	s1,s7,80004fa2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004dc2:	02049593          	slli	a1,s1,0x20
    80004dc6:	9181                	srli	a1,a1,0x20
    80004dc8:	95e2                	add	a1,a1,s8
    80004dca:	855a                	mv	a0,s6
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	2d0080e7          	jalr	720(ra) # 8000109c <walkaddr>
    80004dd4:	862a                	mv	a2,a0
    if(pa == 0)
    80004dd6:	dd45                	beqz	a0,80004d8e <exec+0xfe>
      n = PGSIZE;
    80004dd8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dda:	fd49f2e3          	bgeu	s3,s4,80004d9e <exec+0x10e>
      n = sz - i;
    80004dde:	894e                	mv	s2,s3
    80004de0:	bf7d                	j	80004d9e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004de2:	4481                	li	s1,0
  iunlockput(ip);
    80004de4:	8556                	mv	a0,s5
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	c14080e7          	jalr	-1004(ra) # 800039fa <iunlockput>
  end_op();
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	404080e7          	jalr	1028(ra) # 800041f2 <end_op>
  p = myproc();
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	bdc080e7          	jalr	-1060(ra) # 800019d2 <myproc>
    80004dfe:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e00:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e04:	6785                	lui	a5,0x1
    80004e06:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e08:	97a6                	add	a5,a5,s1
    80004e0a:	777d                	lui	a4,0xfffff
    80004e0c:	8ff9                	and	a5,a5,a4
    80004e0e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e12:	6609                	lui	a2,0x2
    80004e14:	963e                	add	a2,a2,a5
    80004e16:	85be                	mv	a1,a5
    80004e18:	855a                	mv	a0,s6
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	628080e7          	jalr	1576(ra) # 80001442 <uvmalloc>
    80004e22:	8c2a                	mv	s8,a0
  ip = 0;
    80004e24:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e26:	12050e63          	beqz	a0,80004f62 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e2a:	75f9                	lui	a1,0xffffe
    80004e2c:	95aa                	add	a1,a1,a0
    80004e2e:	855a                	mv	a0,s6
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	834080e7          	jalr	-1996(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e38:	7afd                	lui	s5,0xfffff
    80004e3a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e3c:	df043783          	ld	a5,-528(s0)
    80004e40:	6388                	ld	a0,0(a5)
    80004e42:	c925                	beqz	a0,80004eb2 <exec+0x222>
    80004e44:	e9040993          	addi	s3,s0,-368
    80004e48:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e4c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e4e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	042080e7          	jalr	66(ra) # 80000e92 <strlen>
    80004e58:	0015079b          	addiw	a5,a0,1
    80004e5c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e60:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e64:	13596363          	bltu	s2,s5,80004f8a <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e68:	df043d83          	ld	s11,-528(s0)
    80004e6c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e70:	8552                	mv	a0,s4
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	020080e7          	jalr	32(ra) # 80000e92 <strlen>
    80004e7a:	0015069b          	addiw	a3,a0,1
    80004e7e:	8652                	mv	a2,s4
    80004e80:	85ca                	mv	a1,s2
    80004e82:	855a                	mv	a0,s6
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	812080e7          	jalr	-2030(ra) # 80001696 <copyout>
    80004e8c:	10054363          	bltz	a0,80004f92 <exec+0x302>
    ustack[argc] = sp;
    80004e90:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e94:	0485                	addi	s1,s1,1
    80004e96:	008d8793          	addi	a5,s11,8
    80004e9a:	def43823          	sd	a5,-528(s0)
    80004e9e:	008db503          	ld	a0,8(s11)
    80004ea2:	c911                	beqz	a0,80004eb6 <exec+0x226>
    if(argc >= MAXARG)
    80004ea4:	09a1                	addi	s3,s3,8
    80004ea6:	fb3c95e3          	bne	s9,s3,80004e50 <exec+0x1c0>
  sz = sz1;
    80004eaa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eae:	4a81                	li	s5,0
    80004eb0:	a84d                	j	80004f62 <exec+0x2d2>
  sp = sz;
    80004eb2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eb4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eb6:	00349793          	slli	a5,s1,0x3
    80004eba:	f9078793          	addi	a5,a5,-112
    80004ebe:	97a2                	add	a5,a5,s0
    80004ec0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ec4:	00148693          	addi	a3,s1,1
    80004ec8:	068e                	slli	a3,a3,0x3
    80004eca:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ece:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ed2:	01597663          	bgeu	s2,s5,80004ede <exec+0x24e>
  sz = sz1;
    80004ed6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eda:	4a81                	li	s5,0
    80004edc:	a059                	j	80004f62 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ede:	e9040613          	addi	a2,s0,-368
    80004ee2:	85ca                	mv	a1,s2
    80004ee4:	855a                	mv	a0,s6
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	7b0080e7          	jalr	1968(ra) # 80001696 <copyout>
    80004eee:	0a054663          	bltz	a0,80004f9a <exec+0x30a>
  p->trapframe->a1 = sp;
    80004ef2:	058bb783          	ld	a5,88(s7)
    80004ef6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004efa:	de843783          	ld	a5,-536(s0)
    80004efe:	0007c703          	lbu	a4,0(a5)
    80004f02:	cf11                	beqz	a4,80004f1e <exec+0x28e>
    80004f04:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f06:	02f00693          	li	a3,47
    80004f0a:	a039                	j	80004f18 <exec+0x288>
      last = s+1;
    80004f0c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f10:	0785                	addi	a5,a5,1
    80004f12:	fff7c703          	lbu	a4,-1(a5)
    80004f16:	c701                	beqz	a4,80004f1e <exec+0x28e>
    if(*s == '/')
    80004f18:	fed71ce3          	bne	a4,a3,80004f10 <exec+0x280>
    80004f1c:	bfc5                	j	80004f0c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f1e:	4641                	li	a2,16
    80004f20:	de843583          	ld	a1,-536(s0)
    80004f24:	158b8513          	addi	a0,s7,344
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	f38080e7          	jalr	-200(ra) # 80000e60 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f30:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f34:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f38:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f3c:	058bb783          	ld	a5,88(s7)
    80004f40:	e6843703          	ld	a4,-408(s0)
    80004f44:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f46:	058bb783          	ld	a5,88(s7)
    80004f4a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f4e:	85ea                	mv	a1,s10
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	be2080e7          	jalr	-1054(ra) # 80001b32 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f58:	0004851b          	sext.w	a0,s1
    80004f5c:	bbc1                	j	80004d2c <exec+0x9c>
    80004f5e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f62:	df843583          	ld	a1,-520(s0)
    80004f66:	855a                	mv	a0,s6
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	bca080e7          	jalr	-1078(ra) # 80001b32 <proc_freepagetable>
  if(ip){
    80004f70:	da0a94e3          	bnez	s5,80004d18 <exec+0x88>
  return -1;
    80004f74:	557d                	li	a0,-1
    80004f76:	bb5d                	j	80004d2c <exec+0x9c>
    80004f78:	de943c23          	sd	s1,-520(s0)
    80004f7c:	b7dd                	j	80004f62 <exec+0x2d2>
    80004f7e:	de943c23          	sd	s1,-520(s0)
    80004f82:	b7c5                	j	80004f62 <exec+0x2d2>
    80004f84:	de943c23          	sd	s1,-520(s0)
    80004f88:	bfe9                	j	80004f62 <exec+0x2d2>
  sz = sz1;
    80004f8a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f8e:	4a81                	li	s5,0
    80004f90:	bfc9                	j	80004f62 <exec+0x2d2>
  sz = sz1;
    80004f92:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f96:	4a81                	li	s5,0
    80004f98:	b7e9                	j	80004f62 <exec+0x2d2>
  sz = sz1;
    80004f9a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f9e:	4a81                	li	s5,0
    80004fa0:	b7c9                	j	80004f62 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fa2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa6:	e0843783          	ld	a5,-504(s0)
    80004faa:	0017869b          	addiw	a3,a5,1
    80004fae:	e0d43423          	sd	a3,-504(s0)
    80004fb2:	e0043783          	ld	a5,-512(s0)
    80004fb6:	0387879b          	addiw	a5,a5,56
    80004fba:	e8845703          	lhu	a4,-376(s0)
    80004fbe:	e2e6d3e3          	bge	a3,a4,80004de4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fc2:	2781                	sext.w	a5,a5
    80004fc4:	e0f43023          	sd	a5,-512(s0)
    80004fc8:	03800713          	li	a4,56
    80004fcc:	86be                	mv	a3,a5
    80004fce:	e1840613          	addi	a2,s0,-488
    80004fd2:	4581                	li	a1,0
    80004fd4:	8556                	mv	a0,s5
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	a76080e7          	jalr	-1418(ra) # 80003a4c <readi>
    80004fde:	03800793          	li	a5,56
    80004fe2:	f6f51ee3          	bne	a0,a5,80004f5e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004fe6:	e1842783          	lw	a5,-488(s0)
    80004fea:	4705                	li	a4,1
    80004fec:	fae79de3          	bne	a5,a4,80004fa6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004ff0:	e4043603          	ld	a2,-448(s0)
    80004ff4:	e3843783          	ld	a5,-456(s0)
    80004ff8:	f8f660e3          	bltu	a2,a5,80004f78 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ffc:	e2843783          	ld	a5,-472(s0)
    80005000:	963e                	add	a2,a2,a5
    80005002:	f6f66ee3          	bltu	a2,a5,80004f7e <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005006:	85a6                	mv	a1,s1
    80005008:	855a                	mv	a0,s6
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	438080e7          	jalr	1080(ra) # 80001442 <uvmalloc>
    80005012:	dea43c23          	sd	a0,-520(s0)
    80005016:	d53d                	beqz	a0,80004f84 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80005018:	e2843c03          	ld	s8,-472(s0)
    8000501c:	de043783          	ld	a5,-544(s0)
    80005020:	00fc77b3          	and	a5,s8,a5
    80005024:	ff9d                	bnez	a5,80004f62 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005026:	e2042c83          	lw	s9,-480(s0)
    8000502a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000502e:	f60b8ae3          	beqz	s7,80004fa2 <exec+0x312>
    80005032:	89de                	mv	s3,s7
    80005034:	4481                	li	s1,0
    80005036:	b371                	j	80004dc2 <exec+0x132>

0000000080005038 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005038:	7179                	addi	sp,sp,-48
    8000503a:	f406                	sd	ra,40(sp)
    8000503c:	f022                	sd	s0,32(sp)
    8000503e:	ec26                	sd	s1,24(sp)
    80005040:	e84a                	sd	s2,16(sp)
    80005042:	1800                	addi	s0,sp,48
    80005044:	892e                	mv	s2,a1
    80005046:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005048:	fdc40593          	addi	a1,s0,-36
    8000504c:	ffffe097          	auipc	ra,0xffffe
    80005050:	b8a080e7          	jalr	-1142(ra) # 80002bd6 <argint>
    80005054:	04054063          	bltz	a0,80005094 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005058:	fdc42703          	lw	a4,-36(s0)
    8000505c:	47bd                	li	a5,15
    8000505e:	02e7ed63          	bltu	a5,a4,80005098 <argfd+0x60>
    80005062:	ffffd097          	auipc	ra,0xffffd
    80005066:	970080e7          	jalr	-1680(ra) # 800019d2 <myproc>
    8000506a:	fdc42703          	lw	a4,-36(s0)
    8000506e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80005072:	078e                	slli	a5,a5,0x3
    80005074:	953e                	add	a0,a0,a5
    80005076:	611c                	ld	a5,0(a0)
    80005078:	c395                	beqz	a5,8000509c <argfd+0x64>
    return -1;
  if(pfd)
    8000507a:	00090463          	beqz	s2,80005082 <argfd+0x4a>
    *pfd = fd;
    8000507e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005082:	4501                	li	a0,0
  if(pf)
    80005084:	c091                	beqz	s1,80005088 <argfd+0x50>
    *pf = f;
    80005086:	e09c                	sd	a5,0(s1)
}
    80005088:	70a2                	ld	ra,40(sp)
    8000508a:	7402                	ld	s0,32(sp)
    8000508c:	64e2                	ld	s1,24(sp)
    8000508e:	6942                	ld	s2,16(sp)
    80005090:	6145                	addi	sp,sp,48
    80005092:	8082                	ret
    return -1;
    80005094:	557d                	li	a0,-1
    80005096:	bfcd                	j	80005088 <argfd+0x50>
    return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	b7fd                	j	80005088 <argfd+0x50>
    8000509c:	557d                	li	a0,-1
    8000509e:	b7ed                	j	80005088 <argfd+0x50>

00000000800050a0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050a0:	1101                	addi	sp,sp,-32
    800050a2:	ec06                	sd	ra,24(sp)
    800050a4:	e822                	sd	s0,16(sp)
    800050a6:	e426                	sd	s1,8(sp)
    800050a8:	1000                	addi	s0,sp,32
    800050aa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	926080e7          	jalr	-1754(ra) # 800019d2 <myproc>
    800050b4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050b6:	0d050793          	addi	a5,a0,208
    800050ba:	4501                	li	a0,0
    800050bc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050be:	6398                	ld	a4,0(a5)
    800050c0:	cb19                	beqz	a4,800050d6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050c2:	2505                	addiw	a0,a0,1
    800050c4:	07a1                	addi	a5,a5,8
    800050c6:	fed51ce3          	bne	a0,a3,800050be <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ca:	557d                	li	a0,-1
}
    800050cc:	60e2                	ld	ra,24(sp)
    800050ce:	6442                	ld	s0,16(sp)
    800050d0:	64a2                	ld	s1,8(sp)
    800050d2:	6105                	addi	sp,sp,32
    800050d4:	8082                	ret
      p->ofile[fd] = f;
    800050d6:	01a50793          	addi	a5,a0,26
    800050da:	078e                	slli	a5,a5,0x3
    800050dc:	963e                	add	a2,a2,a5
    800050de:	e204                	sd	s1,0(a2)
      return fd;
    800050e0:	b7f5                	j	800050cc <fdalloc+0x2c>

00000000800050e2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050e2:	715d                	addi	sp,sp,-80
    800050e4:	e486                	sd	ra,72(sp)
    800050e6:	e0a2                	sd	s0,64(sp)
    800050e8:	fc26                	sd	s1,56(sp)
    800050ea:	f84a                	sd	s2,48(sp)
    800050ec:	f44e                	sd	s3,40(sp)
    800050ee:	f052                	sd	s4,32(sp)
    800050f0:	ec56                	sd	s5,24(sp)
    800050f2:	0880                	addi	s0,sp,80
    800050f4:	89ae                	mv	s3,a1
    800050f6:	8ab2                	mv	s5,a2
    800050f8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050fa:	fb040593          	addi	a1,s0,-80
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	e74080e7          	jalr	-396(ra) # 80003f72 <nameiparent>
    80005106:	892a                	mv	s2,a0
    80005108:	12050e63          	beqz	a0,80005244 <create+0x162>
    return 0;

  ilock(dp);
    8000510c:	ffffe097          	auipc	ra,0xffffe
    80005110:	68c080e7          	jalr	1676(ra) # 80003798 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005114:	4601                	li	a2,0
    80005116:	fb040593          	addi	a1,s0,-80
    8000511a:	854a                	mv	a0,s2
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	b60080e7          	jalr	-1184(ra) # 80003c7c <dirlookup>
    80005124:	84aa                	mv	s1,a0
    80005126:	c921                	beqz	a0,80005176 <create+0x94>
    iunlockput(dp);
    80005128:	854a                	mv	a0,s2
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	8d0080e7          	jalr	-1840(ra) # 800039fa <iunlockput>
    ilock(ip);
    80005132:	8526                	mv	a0,s1
    80005134:	ffffe097          	auipc	ra,0xffffe
    80005138:	664080e7          	jalr	1636(ra) # 80003798 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000513c:	2981                	sext.w	s3,s3
    8000513e:	4789                	li	a5,2
    80005140:	02f99463          	bne	s3,a5,80005168 <create+0x86>
    80005144:	0444d783          	lhu	a5,68(s1)
    80005148:	37f9                	addiw	a5,a5,-2
    8000514a:	17c2                	slli	a5,a5,0x30
    8000514c:	93c1                	srli	a5,a5,0x30
    8000514e:	4705                	li	a4,1
    80005150:	00f76c63          	bltu	a4,a5,80005168 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005154:	8526                	mv	a0,s1
    80005156:	60a6                	ld	ra,72(sp)
    80005158:	6406                	ld	s0,64(sp)
    8000515a:	74e2                	ld	s1,56(sp)
    8000515c:	7942                	ld	s2,48(sp)
    8000515e:	79a2                	ld	s3,40(sp)
    80005160:	7a02                	ld	s4,32(sp)
    80005162:	6ae2                	ld	s5,24(sp)
    80005164:	6161                	addi	sp,sp,80
    80005166:	8082                	ret
    iunlockput(ip);
    80005168:	8526                	mv	a0,s1
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	890080e7          	jalr	-1904(ra) # 800039fa <iunlockput>
    return 0;
    80005172:	4481                	li	s1,0
    80005174:	b7c5                	j	80005154 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005176:	85ce                	mv	a1,s3
    80005178:	00092503          	lw	a0,0(s2)
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	482080e7          	jalr	1154(ra) # 800035fe <ialloc>
    80005184:	84aa                	mv	s1,a0
    80005186:	c521                	beqz	a0,800051ce <create+0xec>
  ilock(ip);
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	610080e7          	jalr	1552(ra) # 80003798 <ilock>
  ip->major = major;
    80005190:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005194:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005198:	4a05                	li	s4,1
    8000519a:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000519e:	8526                	mv	a0,s1
    800051a0:	ffffe097          	auipc	ra,0xffffe
    800051a4:	52c080e7          	jalr	1324(ra) # 800036cc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051a8:	2981                	sext.w	s3,s3
    800051aa:	03498a63          	beq	s3,s4,800051de <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ae:	40d0                	lw	a2,4(s1)
    800051b0:	fb040593          	addi	a1,s0,-80
    800051b4:	854a                	mv	a0,s2
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	cdc080e7          	jalr	-804(ra) # 80003e92 <dirlink>
    800051be:	06054b63          	bltz	a0,80005234 <create+0x152>
  iunlockput(dp);
    800051c2:	854a                	mv	a0,s2
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	836080e7          	jalr	-1994(ra) # 800039fa <iunlockput>
  return ip;
    800051cc:	b761                	j	80005154 <create+0x72>
    panic("create: ialloc");
    800051ce:	00003517          	auipc	a0,0x3
    800051d2:	58a50513          	addi	a0,a0,1418 # 80008758 <syscalls+0x2b0>
    800051d6:	ffffb097          	auipc	ra,0xffffb
    800051da:	364080e7          	jalr	868(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    800051de:	04a95783          	lhu	a5,74(s2)
    800051e2:	2785                	addiw	a5,a5,1
    800051e4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051e8:	854a                	mv	a0,s2
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	4e2080e7          	jalr	1250(ra) # 800036cc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f2:	40d0                	lw	a2,4(s1)
    800051f4:	00003597          	auipc	a1,0x3
    800051f8:	57458593          	addi	a1,a1,1396 # 80008768 <syscalls+0x2c0>
    800051fc:	8526                	mv	a0,s1
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	c94080e7          	jalr	-876(ra) # 80003e92 <dirlink>
    80005206:	00054f63          	bltz	a0,80005224 <create+0x142>
    8000520a:	00492603          	lw	a2,4(s2)
    8000520e:	00003597          	auipc	a1,0x3
    80005212:	56258593          	addi	a1,a1,1378 # 80008770 <syscalls+0x2c8>
    80005216:	8526                	mv	a0,s1
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	c7a080e7          	jalr	-902(ra) # 80003e92 <dirlink>
    80005220:	f80557e3          	bgez	a0,800051ae <create+0xcc>
      panic("create dots");
    80005224:	00003517          	auipc	a0,0x3
    80005228:	55450513          	addi	a0,a0,1364 # 80008778 <syscalls+0x2d0>
    8000522c:	ffffb097          	auipc	ra,0xffffb
    80005230:	30e080e7          	jalr	782(ra) # 8000053a <panic>
    panic("create: dirlink");
    80005234:	00003517          	auipc	a0,0x3
    80005238:	55450513          	addi	a0,a0,1364 # 80008788 <syscalls+0x2e0>
    8000523c:	ffffb097          	auipc	ra,0xffffb
    80005240:	2fe080e7          	jalr	766(ra) # 8000053a <panic>
    return 0;
    80005244:	84aa                	mv	s1,a0
    80005246:	b739                	j	80005154 <create+0x72>

0000000080005248 <sys_dup>:
{
    80005248:	7179                	addi	sp,sp,-48
    8000524a:	f406                	sd	ra,40(sp)
    8000524c:	f022                	sd	s0,32(sp)
    8000524e:	ec26                	sd	s1,24(sp)
    80005250:	e84a                	sd	s2,16(sp)
    80005252:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005254:	fd840613          	addi	a2,s0,-40
    80005258:	4581                	li	a1,0
    8000525a:	4501                	li	a0,0
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	ddc080e7          	jalr	-548(ra) # 80005038 <argfd>
    return -1;
    80005264:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005266:	02054363          	bltz	a0,8000528c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000526a:	fd843903          	ld	s2,-40(s0)
    8000526e:	854a                	mv	a0,s2
    80005270:	00000097          	auipc	ra,0x0
    80005274:	e30080e7          	jalr	-464(ra) # 800050a0 <fdalloc>
    80005278:	84aa                	mv	s1,a0
    return -1;
    8000527a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000527c:	00054863          	bltz	a0,8000528c <sys_dup+0x44>
  filedup(f);
    80005280:	854a                	mv	a0,s2
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	368080e7          	jalr	872(ra) # 800045ea <filedup>
  return fd;
    8000528a:	87a6                	mv	a5,s1
}
    8000528c:	853e                	mv	a0,a5
    8000528e:	70a2                	ld	ra,40(sp)
    80005290:	7402                	ld	s0,32(sp)
    80005292:	64e2                	ld	s1,24(sp)
    80005294:	6942                	ld	s2,16(sp)
    80005296:	6145                	addi	sp,sp,48
    80005298:	8082                	ret

000000008000529a <sys_read>:
{
    8000529a:	7179                	addi	sp,sp,-48
    8000529c:	f406                	sd	ra,40(sp)
    8000529e:	f022                	sd	s0,32(sp)
    800052a0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a2:	fe840613          	addi	a2,s0,-24
    800052a6:	4581                	li	a1,0
    800052a8:	4501                	li	a0,0
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	d8e080e7          	jalr	-626(ra) # 80005038 <argfd>
    return -1;
    800052b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b4:	04054163          	bltz	a0,800052f6 <sys_read+0x5c>
    800052b8:	fe440593          	addi	a1,s0,-28
    800052bc:	4509                	li	a0,2
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	918080e7          	jalr	-1768(ra) # 80002bd6 <argint>
    return -1;
    800052c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c8:	02054763          	bltz	a0,800052f6 <sys_read+0x5c>
    800052cc:	fd840593          	addi	a1,s0,-40
    800052d0:	4505                	li	a0,1
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	926080e7          	jalr	-1754(ra) # 80002bf8 <argaddr>
    return -1;
    800052da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052dc:	00054d63          	bltz	a0,800052f6 <sys_read+0x5c>
  return fileread(f, p, n);
    800052e0:	fe442603          	lw	a2,-28(s0)
    800052e4:	fd843583          	ld	a1,-40(s0)
    800052e8:	fe843503          	ld	a0,-24(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	48a080e7          	jalr	1162(ra) # 80004776 <fileread>
    800052f4:	87aa                	mv	a5,a0
}
    800052f6:	853e                	mv	a0,a5
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	6145                	addi	sp,sp,48
    800052fe:	8082                	ret

0000000080005300 <sys_write>:
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005308:	fe840613          	addi	a2,s0,-24
    8000530c:	4581                	li	a1,0
    8000530e:	4501                	li	a0,0
    80005310:	00000097          	auipc	ra,0x0
    80005314:	d28080e7          	jalr	-728(ra) # 80005038 <argfd>
    return -1;
    80005318:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531a:	04054163          	bltz	a0,8000535c <sys_write+0x5c>
    8000531e:	fe440593          	addi	a1,s0,-28
    80005322:	4509                	li	a0,2
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	8b2080e7          	jalr	-1870(ra) # 80002bd6 <argint>
    return -1;
    8000532c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532e:	02054763          	bltz	a0,8000535c <sys_write+0x5c>
    80005332:	fd840593          	addi	a1,s0,-40
    80005336:	4505                	li	a0,1
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	8c0080e7          	jalr	-1856(ra) # 80002bf8 <argaddr>
    return -1;
    80005340:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005342:	00054d63          	bltz	a0,8000535c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005346:	fe442603          	lw	a2,-28(s0)
    8000534a:	fd843583          	ld	a1,-40(s0)
    8000534e:	fe843503          	ld	a0,-24(s0)
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	4e6080e7          	jalr	1254(ra) # 80004838 <filewrite>
    8000535a:	87aa                	mv	a5,a0
}
    8000535c:	853e                	mv	a0,a5
    8000535e:	70a2                	ld	ra,40(sp)
    80005360:	7402                	ld	s0,32(sp)
    80005362:	6145                	addi	sp,sp,48
    80005364:	8082                	ret

0000000080005366 <sys_close>:
{
    80005366:	1101                	addi	sp,sp,-32
    80005368:	ec06                	sd	ra,24(sp)
    8000536a:	e822                	sd	s0,16(sp)
    8000536c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000536e:	fe040613          	addi	a2,s0,-32
    80005372:	fec40593          	addi	a1,s0,-20
    80005376:	4501                	li	a0,0
    80005378:	00000097          	auipc	ra,0x0
    8000537c:	cc0080e7          	jalr	-832(ra) # 80005038 <argfd>
    return -1;
    80005380:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005382:	02054463          	bltz	a0,800053aa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	64c080e7          	jalr	1612(ra) # 800019d2 <myproc>
    8000538e:	fec42783          	lw	a5,-20(s0)
    80005392:	07e9                	addi	a5,a5,26
    80005394:	078e                	slli	a5,a5,0x3
    80005396:	953e                	add	a0,a0,a5
    80005398:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000539c:	fe043503          	ld	a0,-32(s0)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	29c080e7          	jalr	668(ra) # 8000463c <fileclose>
  return 0;
    800053a8:	4781                	li	a5,0
}
    800053aa:	853e                	mv	a0,a5
    800053ac:	60e2                	ld	ra,24(sp)
    800053ae:	6442                	ld	s0,16(sp)
    800053b0:	6105                	addi	sp,sp,32
    800053b2:	8082                	ret

00000000800053b4 <sys_fstat>:
{
    800053b4:	1101                	addi	sp,sp,-32
    800053b6:	ec06                	sd	ra,24(sp)
    800053b8:	e822                	sd	s0,16(sp)
    800053ba:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053bc:	fe840613          	addi	a2,s0,-24
    800053c0:	4581                	li	a1,0
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	c74080e7          	jalr	-908(ra) # 80005038 <argfd>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ce:	02054563          	bltz	a0,800053f8 <sys_fstat+0x44>
    800053d2:	fe040593          	addi	a1,s0,-32
    800053d6:	4505                	li	a0,1
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	820080e7          	jalr	-2016(ra) # 80002bf8 <argaddr>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e2:	00054b63          	bltz	a0,800053f8 <sys_fstat+0x44>
  return filestat(f, st);
    800053e6:	fe043583          	ld	a1,-32(s0)
    800053ea:	fe843503          	ld	a0,-24(s0)
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	316080e7          	jalr	790(ra) # 80004704 <filestat>
    800053f6:	87aa                	mv	a5,a0
}
    800053f8:	853e                	mv	a0,a5
    800053fa:	60e2                	ld	ra,24(sp)
    800053fc:	6442                	ld	s0,16(sp)
    800053fe:	6105                	addi	sp,sp,32
    80005400:	8082                	ret

0000000080005402 <sys_link>:
{
    80005402:	7169                	addi	sp,sp,-304
    80005404:	f606                	sd	ra,296(sp)
    80005406:	f222                	sd	s0,288(sp)
    80005408:	ee26                	sd	s1,280(sp)
    8000540a:	ea4a                	sd	s2,272(sp)
    8000540c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000540e:	08000613          	li	a2,128
    80005412:	ed040593          	addi	a1,s0,-304
    80005416:	4501                	li	a0,0
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	802080e7          	jalr	-2046(ra) # 80002c1a <argstr>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005422:	10054e63          	bltz	a0,8000553e <sys_link+0x13c>
    80005426:	08000613          	li	a2,128
    8000542a:	f5040593          	addi	a1,s0,-176
    8000542e:	4505                	li	a0,1
    80005430:	ffffd097          	auipc	ra,0xffffd
    80005434:	7ea080e7          	jalr	2026(ra) # 80002c1a <argstr>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543a:	10054263          	bltz	a0,8000553e <sys_link+0x13c>
  begin_op();
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	d36080e7          	jalr	-714(ra) # 80004174 <begin_op>
  if((ip = namei(old)) == 0){
    80005446:	ed040513          	addi	a0,s0,-304
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	b0a080e7          	jalr	-1270(ra) # 80003f54 <namei>
    80005452:	84aa                	mv	s1,a0
    80005454:	c551                	beqz	a0,800054e0 <sys_link+0xde>
  ilock(ip);
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	342080e7          	jalr	834(ra) # 80003798 <ilock>
  if(ip->type == T_DIR){
    8000545e:	04449703          	lh	a4,68(s1)
    80005462:	4785                	li	a5,1
    80005464:	08f70463          	beq	a4,a5,800054ec <sys_link+0xea>
  ip->nlink++;
    80005468:	04a4d783          	lhu	a5,74(s1)
    8000546c:	2785                	addiw	a5,a5,1
    8000546e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005472:	8526                	mv	a0,s1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	258080e7          	jalr	600(ra) # 800036cc <iupdate>
  iunlock(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	3dc080e7          	jalr	988(ra) # 8000385a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005486:	fd040593          	addi	a1,s0,-48
    8000548a:	f5040513          	addi	a0,s0,-176
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	ae4080e7          	jalr	-1308(ra) # 80003f72 <nameiparent>
    80005496:	892a                	mv	s2,a0
    80005498:	c935                	beqz	a0,8000550c <sys_link+0x10a>
  ilock(dp);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	2fe080e7          	jalr	766(ra) # 80003798 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054a2:	00092703          	lw	a4,0(s2)
    800054a6:	409c                	lw	a5,0(s1)
    800054a8:	04f71d63          	bne	a4,a5,80005502 <sys_link+0x100>
    800054ac:	40d0                	lw	a2,4(s1)
    800054ae:	fd040593          	addi	a1,s0,-48
    800054b2:	854a                	mv	a0,s2
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	9de080e7          	jalr	-1570(ra) # 80003e92 <dirlink>
    800054bc:	04054363          	bltz	a0,80005502 <sys_link+0x100>
  iunlockput(dp);
    800054c0:	854a                	mv	a0,s2
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	538080e7          	jalr	1336(ra) # 800039fa <iunlockput>
  iput(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	486080e7          	jalr	1158(ra) # 80003952 <iput>
  end_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	d1e080e7          	jalr	-738(ra) # 800041f2 <end_op>
  return 0;
    800054dc:	4781                	li	a5,0
    800054de:	a085                	j	8000553e <sys_link+0x13c>
    end_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	d12080e7          	jalr	-750(ra) # 800041f2 <end_op>
    return -1;
    800054e8:	57fd                	li	a5,-1
    800054ea:	a891                	j	8000553e <sys_link+0x13c>
    iunlockput(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	50c080e7          	jalr	1292(ra) # 800039fa <iunlockput>
    end_op();
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	cfc080e7          	jalr	-772(ra) # 800041f2 <end_op>
    return -1;
    800054fe:	57fd                	li	a5,-1
    80005500:	a83d                	j	8000553e <sys_link+0x13c>
    iunlockput(dp);
    80005502:	854a                	mv	a0,s2
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	4f6080e7          	jalr	1270(ra) # 800039fa <iunlockput>
  ilock(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	28a080e7          	jalr	650(ra) # 80003798 <ilock>
  ip->nlink--;
    80005516:	04a4d783          	lhu	a5,74(s1)
    8000551a:	37fd                	addiw	a5,a5,-1
    8000551c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	1aa080e7          	jalr	426(ra) # 800036cc <iupdate>
  iunlockput(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	4ce080e7          	jalr	1230(ra) # 800039fa <iunlockput>
  end_op();
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	cbe080e7          	jalr	-834(ra) # 800041f2 <end_op>
  return -1;
    8000553c:	57fd                	li	a5,-1
}
    8000553e:	853e                	mv	a0,a5
    80005540:	70b2                	ld	ra,296(sp)
    80005542:	7412                	ld	s0,288(sp)
    80005544:	64f2                	ld	s1,280(sp)
    80005546:	6952                	ld	s2,272(sp)
    80005548:	6155                	addi	sp,sp,304
    8000554a:	8082                	ret

000000008000554c <sys_unlink>:
{
    8000554c:	7151                	addi	sp,sp,-240
    8000554e:	f586                	sd	ra,232(sp)
    80005550:	f1a2                	sd	s0,224(sp)
    80005552:	eda6                	sd	s1,216(sp)
    80005554:	e9ca                	sd	s2,208(sp)
    80005556:	e5ce                	sd	s3,200(sp)
    80005558:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000555a:	08000613          	li	a2,128
    8000555e:	f3040593          	addi	a1,s0,-208
    80005562:	4501                	li	a0,0
    80005564:	ffffd097          	auipc	ra,0xffffd
    80005568:	6b6080e7          	jalr	1718(ra) # 80002c1a <argstr>
    8000556c:	18054163          	bltz	a0,800056ee <sys_unlink+0x1a2>
  begin_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	c04080e7          	jalr	-1020(ra) # 80004174 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005578:	fb040593          	addi	a1,s0,-80
    8000557c:	f3040513          	addi	a0,s0,-208
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	9f2080e7          	jalr	-1550(ra) # 80003f72 <nameiparent>
    80005588:	84aa                	mv	s1,a0
    8000558a:	c979                	beqz	a0,80005660 <sys_unlink+0x114>
  ilock(dp);
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	20c080e7          	jalr	524(ra) # 80003798 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005594:	00003597          	auipc	a1,0x3
    80005598:	1d458593          	addi	a1,a1,468 # 80008768 <syscalls+0x2c0>
    8000559c:	fb040513          	addi	a0,s0,-80
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	6c2080e7          	jalr	1730(ra) # 80003c62 <namecmp>
    800055a8:	14050a63          	beqz	a0,800056fc <sys_unlink+0x1b0>
    800055ac:	00003597          	auipc	a1,0x3
    800055b0:	1c458593          	addi	a1,a1,452 # 80008770 <syscalls+0x2c8>
    800055b4:	fb040513          	addi	a0,s0,-80
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	6aa080e7          	jalr	1706(ra) # 80003c62 <namecmp>
    800055c0:	12050e63          	beqz	a0,800056fc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055c4:	f2c40613          	addi	a2,s0,-212
    800055c8:	fb040593          	addi	a1,s0,-80
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	6ae080e7          	jalr	1710(ra) # 80003c7c <dirlookup>
    800055d6:	892a                	mv	s2,a0
    800055d8:	12050263          	beqz	a0,800056fc <sys_unlink+0x1b0>
  ilock(ip);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	1bc080e7          	jalr	444(ra) # 80003798 <ilock>
  if(ip->nlink < 1)
    800055e4:	04a91783          	lh	a5,74(s2)
    800055e8:	08f05263          	blez	a5,8000566c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055ec:	04491703          	lh	a4,68(s2)
    800055f0:	4785                	li	a5,1
    800055f2:	08f70563          	beq	a4,a5,8000567c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055f6:	4641                	li	a2,16
    800055f8:	4581                	li	a1,0
    800055fa:	fc040513          	addi	a0,s0,-64
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	718080e7          	jalr	1816(ra) # 80000d16 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005606:	4741                	li	a4,16
    80005608:	f2c42683          	lw	a3,-212(s0)
    8000560c:	fc040613          	addi	a2,s0,-64
    80005610:	4581                	li	a1,0
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	530080e7          	jalr	1328(ra) # 80003b44 <writei>
    8000561c:	47c1                	li	a5,16
    8000561e:	0af51563          	bne	a0,a5,800056c8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005622:	04491703          	lh	a4,68(s2)
    80005626:	4785                	li	a5,1
    80005628:	0af70863          	beq	a4,a5,800056d8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	3cc080e7          	jalr	972(ra) # 800039fa <iunlockput>
  ip->nlink--;
    80005636:	04a95783          	lhu	a5,74(s2)
    8000563a:	37fd                	addiw	a5,a5,-1
    8000563c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005640:	854a                	mv	a0,s2
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	08a080e7          	jalr	138(ra) # 800036cc <iupdate>
  iunlockput(ip);
    8000564a:	854a                	mv	a0,s2
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	3ae080e7          	jalr	942(ra) # 800039fa <iunlockput>
  end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	b9e080e7          	jalr	-1122(ra) # 800041f2 <end_op>
  return 0;
    8000565c:	4501                	li	a0,0
    8000565e:	a84d                	j	80005710 <sys_unlink+0x1c4>
    end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	b92080e7          	jalr	-1134(ra) # 800041f2 <end_op>
    return -1;
    80005668:	557d                	li	a0,-1
    8000566a:	a05d                	j	80005710 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000566c:	00003517          	auipc	a0,0x3
    80005670:	12c50513          	addi	a0,a0,300 # 80008798 <syscalls+0x2f0>
    80005674:	ffffb097          	auipc	ra,0xffffb
    80005678:	ec6080e7          	jalr	-314(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000567c:	04c92703          	lw	a4,76(s2)
    80005680:	02000793          	li	a5,32
    80005684:	f6e7f9e3          	bgeu	a5,a4,800055f6 <sys_unlink+0xaa>
    80005688:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000568c:	4741                	li	a4,16
    8000568e:	86ce                	mv	a3,s3
    80005690:	f1840613          	addi	a2,s0,-232
    80005694:	4581                	li	a1,0
    80005696:	854a                	mv	a0,s2
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	3b4080e7          	jalr	948(ra) # 80003a4c <readi>
    800056a0:	47c1                	li	a5,16
    800056a2:	00f51b63          	bne	a0,a5,800056b8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056a6:	f1845783          	lhu	a5,-232(s0)
    800056aa:	e7a1                	bnez	a5,800056f2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ac:	29c1                	addiw	s3,s3,16
    800056ae:	04c92783          	lw	a5,76(s2)
    800056b2:	fcf9ede3          	bltu	s3,a5,8000568c <sys_unlink+0x140>
    800056b6:	b781                	j	800055f6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056b8:	00003517          	auipc	a0,0x3
    800056bc:	0f850513          	addi	a0,a0,248 # 800087b0 <syscalls+0x308>
    800056c0:	ffffb097          	auipc	ra,0xffffb
    800056c4:	e7a080e7          	jalr	-390(ra) # 8000053a <panic>
    panic("unlink: writei");
    800056c8:	00003517          	auipc	a0,0x3
    800056cc:	10050513          	addi	a0,a0,256 # 800087c8 <syscalls+0x320>
    800056d0:	ffffb097          	auipc	ra,0xffffb
    800056d4:	e6a080e7          	jalr	-406(ra) # 8000053a <panic>
    dp->nlink--;
    800056d8:	04a4d783          	lhu	a5,74(s1)
    800056dc:	37fd                	addiw	a5,a5,-1
    800056de:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	fe8080e7          	jalr	-24(ra) # 800036cc <iupdate>
    800056ec:	b781                	j	8000562c <sys_unlink+0xe0>
    return -1;
    800056ee:	557d                	li	a0,-1
    800056f0:	a005                	j	80005710 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056f2:	854a                	mv	a0,s2
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	306080e7          	jalr	774(ra) # 800039fa <iunlockput>
  iunlockput(dp);
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	2fc080e7          	jalr	764(ra) # 800039fa <iunlockput>
  end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	aec080e7          	jalr	-1300(ra) # 800041f2 <end_op>
  return -1;
    8000570e:	557d                	li	a0,-1
}
    80005710:	70ae                	ld	ra,232(sp)
    80005712:	740e                	ld	s0,224(sp)
    80005714:	64ee                	ld	s1,216(sp)
    80005716:	694e                	ld	s2,208(sp)
    80005718:	69ae                	ld	s3,200(sp)
    8000571a:	616d                	addi	sp,sp,240
    8000571c:	8082                	ret

000000008000571e <sys_open>:

uint64
sys_open(void)
{
    8000571e:	7131                	addi	sp,sp,-192
    80005720:	fd06                	sd	ra,184(sp)
    80005722:	f922                	sd	s0,176(sp)
    80005724:	f526                	sd	s1,168(sp)
    80005726:	f14a                	sd	s2,160(sp)
    80005728:	ed4e                	sd	s3,152(sp)
    8000572a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000572c:	08000613          	li	a2,128
    80005730:	f5040593          	addi	a1,s0,-176
    80005734:	4501                	li	a0,0
    80005736:	ffffd097          	auipc	ra,0xffffd
    8000573a:	4e4080e7          	jalr	1252(ra) # 80002c1a <argstr>
    return -1;
    8000573e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005740:	0c054163          	bltz	a0,80005802 <sys_open+0xe4>
    80005744:	f4c40593          	addi	a1,s0,-180
    80005748:	4505                	li	a0,1
    8000574a:	ffffd097          	auipc	ra,0xffffd
    8000574e:	48c080e7          	jalr	1164(ra) # 80002bd6 <argint>
    80005752:	0a054863          	bltz	a0,80005802 <sys_open+0xe4>

  begin_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	a1e080e7          	jalr	-1506(ra) # 80004174 <begin_op>

  if(omode & O_CREATE){
    8000575e:	f4c42783          	lw	a5,-180(s0)
    80005762:	2007f793          	andi	a5,a5,512
    80005766:	cbdd                	beqz	a5,8000581c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005768:	4681                	li	a3,0
    8000576a:	4601                	li	a2,0
    8000576c:	4589                	li	a1,2
    8000576e:	f5040513          	addi	a0,s0,-176
    80005772:	00000097          	auipc	ra,0x0
    80005776:	970080e7          	jalr	-1680(ra) # 800050e2 <create>
    8000577a:	892a                	mv	s2,a0
    if(ip == 0){
    8000577c:	c959                	beqz	a0,80005812 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000577e:	04491703          	lh	a4,68(s2)
    80005782:	478d                	li	a5,3
    80005784:	00f71763          	bne	a4,a5,80005792 <sys_open+0x74>
    80005788:	04695703          	lhu	a4,70(s2)
    8000578c:	47a5                	li	a5,9
    8000578e:	0ce7ec63          	bltu	a5,a4,80005866 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	dee080e7          	jalr	-530(ra) # 80004580 <filealloc>
    8000579a:	89aa                	mv	s3,a0
    8000579c:	10050263          	beqz	a0,800058a0 <sys_open+0x182>
    800057a0:	00000097          	auipc	ra,0x0
    800057a4:	900080e7          	jalr	-1792(ra) # 800050a0 <fdalloc>
    800057a8:	84aa                	mv	s1,a0
    800057aa:	0e054663          	bltz	a0,80005896 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ae:	04491703          	lh	a4,68(s2)
    800057b2:	478d                	li	a5,3
    800057b4:	0cf70463          	beq	a4,a5,8000587c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057b8:	4789                	li	a5,2
    800057ba:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057be:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057c2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057c6:	f4c42783          	lw	a5,-180(s0)
    800057ca:	0017c713          	xori	a4,a5,1
    800057ce:	8b05                	andi	a4,a4,1
    800057d0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057d4:	0037f713          	andi	a4,a5,3
    800057d8:	00e03733          	snez	a4,a4
    800057dc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057e0:	4007f793          	andi	a5,a5,1024
    800057e4:	c791                	beqz	a5,800057f0 <sys_open+0xd2>
    800057e6:	04491703          	lh	a4,68(s2)
    800057ea:	4789                	li	a5,2
    800057ec:	08f70f63          	beq	a4,a5,8000588a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	068080e7          	jalr	104(ra) # 8000385a <iunlock>
  end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	9f8080e7          	jalr	-1544(ra) # 800041f2 <end_op>

  return fd;
}
    80005802:	8526                	mv	a0,s1
    80005804:	70ea                	ld	ra,184(sp)
    80005806:	744a                	ld	s0,176(sp)
    80005808:	74aa                	ld	s1,168(sp)
    8000580a:	790a                	ld	s2,160(sp)
    8000580c:	69ea                	ld	s3,152(sp)
    8000580e:	6129                	addi	sp,sp,192
    80005810:	8082                	ret
      end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	9e0080e7          	jalr	-1568(ra) # 800041f2 <end_op>
      return -1;
    8000581a:	b7e5                	j	80005802 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000581c:	f5040513          	addi	a0,s0,-176
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	734080e7          	jalr	1844(ra) # 80003f54 <namei>
    80005828:	892a                	mv	s2,a0
    8000582a:	c905                	beqz	a0,8000585a <sys_open+0x13c>
    ilock(ip);
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	f6c080e7          	jalr	-148(ra) # 80003798 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005834:	04491703          	lh	a4,68(s2)
    80005838:	4785                	li	a5,1
    8000583a:	f4f712e3          	bne	a4,a5,8000577e <sys_open+0x60>
    8000583e:	f4c42783          	lw	a5,-180(s0)
    80005842:	dba1                	beqz	a5,80005792 <sys_open+0x74>
      iunlockput(ip);
    80005844:	854a                	mv	a0,s2
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	1b4080e7          	jalr	436(ra) # 800039fa <iunlockput>
      end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	9a4080e7          	jalr	-1628(ra) # 800041f2 <end_op>
      return -1;
    80005856:	54fd                	li	s1,-1
    80005858:	b76d                	j	80005802 <sys_open+0xe4>
      end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	998080e7          	jalr	-1640(ra) # 800041f2 <end_op>
      return -1;
    80005862:	54fd                	li	s1,-1
    80005864:	bf79                	j	80005802 <sys_open+0xe4>
    iunlockput(ip);
    80005866:	854a                	mv	a0,s2
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	192080e7          	jalr	402(ra) # 800039fa <iunlockput>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	982080e7          	jalr	-1662(ra) # 800041f2 <end_op>
    return -1;
    80005878:	54fd                	li	s1,-1
    8000587a:	b761                	j	80005802 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000587c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005880:	04691783          	lh	a5,70(s2)
    80005884:	02f99223          	sh	a5,36(s3)
    80005888:	bf2d                	j	800057c2 <sys_open+0xa4>
    itrunc(ip);
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	01a080e7          	jalr	26(ra) # 800038a6 <itrunc>
    80005894:	bfb1                	j	800057f0 <sys_open+0xd2>
      fileclose(f);
    80005896:	854e                	mv	a0,s3
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	da4080e7          	jalr	-604(ra) # 8000463c <fileclose>
    iunlockput(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	158080e7          	jalr	344(ra) # 800039fa <iunlockput>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	948080e7          	jalr	-1720(ra) # 800041f2 <end_op>
    return -1;
    800058b2:	54fd                	li	s1,-1
    800058b4:	b7b9                	j	80005802 <sys_open+0xe4>

00000000800058b6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058b6:	7175                	addi	sp,sp,-144
    800058b8:	e506                	sd	ra,136(sp)
    800058ba:	e122                	sd	s0,128(sp)
    800058bc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	8b6080e7          	jalr	-1866(ra) # 80004174 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058c6:	08000613          	li	a2,128
    800058ca:	f7040593          	addi	a1,s0,-144
    800058ce:	4501                	li	a0,0
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	34a080e7          	jalr	842(ra) # 80002c1a <argstr>
    800058d8:	02054963          	bltz	a0,8000590a <sys_mkdir+0x54>
    800058dc:	4681                	li	a3,0
    800058de:	4601                	li	a2,0
    800058e0:	4585                	li	a1,1
    800058e2:	f7040513          	addi	a0,s0,-144
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	7fc080e7          	jalr	2044(ra) # 800050e2 <create>
    800058ee:	cd11                	beqz	a0,8000590a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	10a080e7          	jalr	266(ra) # 800039fa <iunlockput>
  end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	8fa080e7          	jalr	-1798(ra) # 800041f2 <end_op>
  return 0;
    80005900:	4501                	li	a0,0
}
    80005902:	60aa                	ld	ra,136(sp)
    80005904:	640a                	ld	s0,128(sp)
    80005906:	6149                	addi	sp,sp,144
    80005908:	8082                	ret
    end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	8e8080e7          	jalr	-1816(ra) # 800041f2 <end_op>
    return -1;
    80005912:	557d                	li	a0,-1
    80005914:	b7fd                	j	80005902 <sys_mkdir+0x4c>

0000000080005916 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005916:	7135                	addi	sp,sp,-160
    80005918:	ed06                	sd	ra,152(sp)
    8000591a:	e922                	sd	s0,144(sp)
    8000591c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	856080e7          	jalr	-1962(ra) # 80004174 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005926:	08000613          	li	a2,128
    8000592a:	f7040593          	addi	a1,s0,-144
    8000592e:	4501                	li	a0,0
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	2ea080e7          	jalr	746(ra) # 80002c1a <argstr>
    80005938:	04054a63          	bltz	a0,8000598c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000593c:	f6c40593          	addi	a1,s0,-148
    80005940:	4505                	li	a0,1
    80005942:	ffffd097          	auipc	ra,0xffffd
    80005946:	294080e7          	jalr	660(ra) # 80002bd6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594a:	04054163          	bltz	a0,8000598c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000594e:	f6840593          	addi	a1,s0,-152
    80005952:	4509                	li	a0,2
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	282080e7          	jalr	642(ra) # 80002bd6 <argint>
     argint(1, &major) < 0 ||
    8000595c:	02054863          	bltz	a0,8000598c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005960:	f6841683          	lh	a3,-152(s0)
    80005964:	f6c41603          	lh	a2,-148(s0)
    80005968:	458d                	li	a1,3
    8000596a:	f7040513          	addi	a0,s0,-144
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	774080e7          	jalr	1908(ra) # 800050e2 <create>
     argint(2, &minor) < 0 ||
    80005976:	c919                	beqz	a0,8000598c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	082080e7          	jalr	130(ra) # 800039fa <iunlockput>
  end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	872080e7          	jalr	-1934(ra) # 800041f2 <end_op>
  return 0;
    80005988:	4501                	li	a0,0
    8000598a:	a031                	j	80005996 <sys_mknod+0x80>
    end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	866080e7          	jalr	-1946(ra) # 800041f2 <end_op>
    return -1;
    80005994:	557d                	li	a0,-1
}
    80005996:	60ea                	ld	ra,152(sp)
    80005998:	644a                	ld	s0,144(sp)
    8000599a:	610d                	addi	sp,sp,160
    8000599c:	8082                	ret

000000008000599e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000599e:	7135                	addi	sp,sp,-160
    800059a0:	ed06                	sd	ra,152(sp)
    800059a2:	e922                	sd	s0,144(sp)
    800059a4:	e526                	sd	s1,136(sp)
    800059a6:	e14a                	sd	s2,128(sp)
    800059a8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059aa:	ffffc097          	auipc	ra,0xffffc
    800059ae:	028080e7          	jalr	40(ra) # 800019d2 <myproc>
    800059b2:	892a                	mv	s2,a0
  
  begin_op();
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	7c0080e7          	jalr	1984(ra) # 80004174 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059bc:	08000613          	li	a2,128
    800059c0:	f6040593          	addi	a1,s0,-160
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	254080e7          	jalr	596(ra) # 80002c1a <argstr>
    800059ce:	04054b63          	bltz	a0,80005a24 <sys_chdir+0x86>
    800059d2:	f6040513          	addi	a0,s0,-160
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	57e080e7          	jalr	1406(ra) # 80003f54 <namei>
    800059de:	84aa                	mv	s1,a0
    800059e0:	c131                	beqz	a0,80005a24 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	db6080e7          	jalr	-586(ra) # 80003798 <ilock>
  if(ip->type != T_DIR){
    800059ea:	04449703          	lh	a4,68(s1)
    800059ee:	4785                	li	a5,1
    800059f0:	04f71063          	bne	a4,a5,80005a30 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	e64080e7          	jalr	-412(ra) # 8000385a <iunlock>
  iput(p->cwd);
    800059fe:	15093503          	ld	a0,336(s2)
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	f50080e7          	jalr	-176(ra) # 80003952 <iput>
  end_op();
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	7e8080e7          	jalr	2024(ra) # 800041f2 <end_op>
  p->cwd = ip;
    80005a12:	14993823          	sd	s1,336(s2)
  return 0;
    80005a16:	4501                	li	a0,0
}
    80005a18:	60ea                	ld	ra,152(sp)
    80005a1a:	644a                	ld	s0,144(sp)
    80005a1c:	64aa                	ld	s1,136(sp)
    80005a1e:	690a                	ld	s2,128(sp)
    80005a20:	610d                	addi	sp,sp,160
    80005a22:	8082                	ret
    end_op();
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	7ce080e7          	jalr	1998(ra) # 800041f2 <end_op>
    return -1;
    80005a2c:	557d                	li	a0,-1
    80005a2e:	b7ed                	j	80005a18 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	fc8080e7          	jalr	-56(ra) # 800039fa <iunlockput>
    end_op();
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	7b8080e7          	jalr	1976(ra) # 800041f2 <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	bfd1                	j	80005a18 <sys_chdir+0x7a>

0000000080005a46 <sys_exec>:

uint64
sys_exec(void)
{
    80005a46:	7145                	addi	sp,sp,-464
    80005a48:	e786                	sd	ra,456(sp)
    80005a4a:	e3a2                	sd	s0,448(sp)
    80005a4c:	ff26                	sd	s1,440(sp)
    80005a4e:	fb4a                	sd	s2,432(sp)
    80005a50:	f74e                	sd	s3,424(sp)
    80005a52:	f352                	sd	s4,416(sp)
    80005a54:	ef56                	sd	s5,408(sp)
    80005a56:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a58:	08000613          	li	a2,128
    80005a5c:	f4040593          	addi	a1,s0,-192
    80005a60:	4501                	li	a0,0
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	1b8080e7          	jalr	440(ra) # 80002c1a <argstr>
    return -1;
    80005a6a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a6c:	0c054b63          	bltz	a0,80005b42 <sys_exec+0xfc>
    80005a70:	e3840593          	addi	a1,s0,-456
    80005a74:	4505                	li	a0,1
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	182080e7          	jalr	386(ra) # 80002bf8 <argaddr>
    80005a7e:	0c054263          	bltz	a0,80005b42 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a82:	10000613          	li	a2,256
    80005a86:	4581                	li	a1,0
    80005a88:	e4040513          	addi	a0,s0,-448
    80005a8c:	ffffb097          	auipc	ra,0xffffb
    80005a90:	28a080e7          	jalr	650(ra) # 80000d16 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a94:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a98:	89a6                	mv	s3,s1
    80005a9a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a9c:	02000a13          	li	s4,32
    80005aa0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aa4:	00391513          	slli	a0,s2,0x3
    80005aa8:	e3040593          	addi	a1,s0,-464
    80005aac:	e3843783          	ld	a5,-456(s0)
    80005ab0:	953e                	add	a0,a0,a5
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	08a080e7          	jalr	138(ra) # 80002b3c <fetchaddr>
    80005aba:	02054a63          	bltz	a0,80005aee <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005abe:	e3043783          	ld	a5,-464(s0)
    80005ac2:	c3b9                	beqz	a5,80005b08 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ac4:	ffffb097          	auipc	ra,0xffffb
    80005ac8:	01c080e7          	jalr	28(ra) # 80000ae0 <kalloc>
    80005acc:	85aa                	mv	a1,a0
    80005ace:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad2:	cd11                	beqz	a0,80005aee <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ad4:	6605                	lui	a2,0x1
    80005ad6:	e3043503          	ld	a0,-464(s0)
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	0b4080e7          	jalr	180(ra) # 80002b8e <fetchstr>
    80005ae2:	00054663          	bltz	a0,80005aee <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ae6:	0905                	addi	s2,s2,1
    80005ae8:	09a1                	addi	s3,s3,8
    80005aea:	fb491be3          	bne	s2,s4,80005aa0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aee:	f4040913          	addi	s2,s0,-192
    80005af2:	6088                	ld	a0,0(s1)
    80005af4:	c531                	beqz	a0,80005b40 <sys_exec+0xfa>
    kfree(argv[i]);
    80005af6:	ffffb097          	auipc	ra,0xffffb
    80005afa:	eec080e7          	jalr	-276(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afe:	04a1                	addi	s1,s1,8
    80005b00:	ff2499e3          	bne	s1,s2,80005af2 <sys_exec+0xac>
  return -1;
    80005b04:	597d                	li	s2,-1
    80005b06:	a835                	j	80005b42 <sys_exec+0xfc>
      argv[i] = 0;
    80005b08:	0a8e                	slli	s5,s5,0x3
    80005b0a:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005b0e:	00878ab3          	add	s5,a5,s0
    80005b12:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b16:	e4040593          	addi	a1,s0,-448
    80005b1a:	f4040513          	addi	a0,s0,-192
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	172080e7          	jalr	370(ra) # 80004c90 <exec>
    80005b26:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b28:	f4040993          	addi	s3,s0,-192
    80005b2c:	6088                	ld	a0,0(s1)
    80005b2e:	c911                	beqz	a0,80005b42 <sys_exec+0xfc>
    kfree(argv[i]);
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	eb2080e7          	jalr	-334(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b38:	04a1                	addi	s1,s1,8
    80005b3a:	ff3499e3          	bne	s1,s3,80005b2c <sys_exec+0xe6>
    80005b3e:	a011                	j	80005b42 <sys_exec+0xfc>
  return -1;
    80005b40:	597d                	li	s2,-1
}
    80005b42:	854a                	mv	a0,s2
    80005b44:	60be                	ld	ra,456(sp)
    80005b46:	641e                	ld	s0,448(sp)
    80005b48:	74fa                	ld	s1,440(sp)
    80005b4a:	795a                	ld	s2,432(sp)
    80005b4c:	79ba                	ld	s3,424(sp)
    80005b4e:	7a1a                	ld	s4,416(sp)
    80005b50:	6afa                	ld	s5,408(sp)
    80005b52:	6179                	addi	sp,sp,464
    80005b54:	8082                	ret

0000000080005b56 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b56:	7139                	addi	sp,sp,-64
    80005b58:	fc06                	sd	ra,56(sp)
    80005b5a:	f822                	sd	s0,48(sp)
    80005b5c:	f426                	sd	s1,40(sp)
    80005b5e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	e72080e7          	jalr	-398(ra) # 800019d2 <myproc>
    80005b68:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b6a:	fd840593          	addi	a1,s0,-40
    80005b6e:	4501                	li	a0,0
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	088080e7          	jalr	136(ra) # 80002bf8 <argaddr>
    return -1;
    80005b78:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b7a:	0e054063          	bltz	a0,80005c5a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b7e:	fc840593          	addi	a1,s0,-56
    80005b82:	fd040513          	addi	a0,s0,-48
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	de6080e7          	jalr	-538(ra) # 8000496c <pipealloc>
    return -1;
    80005b8e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b90:	0c054563          	bltz	a0,80005c5a <sys_pipe+0x104>
  fd0 = -1;
    80005b94:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b98:	fd043503          	ld	a0,-48(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	504080e7          	jalr	1284(ra) # 800050a0 <fdalloc>
    80005ba4:	fca42223          	sw	a0,-60(s0)
    80005ba8:	08054c63          	bltz	a0,80005c40 <sys_pipe+0xea>
    80005bac:	fc843503          	ld	a0,-56(s0)
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	4f0080e7          	jalr	1264(ra) # 800050a0 <fdalloc>
    80005bb8:	fca42023          	sw	a0,-64(s0)
    80005bbc:	06054963          	bltz	a0,80005c2e <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc0:	4691                	li	a3,4
    80005bc2:	fc440613          	addi	a2,s0,-60
    80005bc6:	fd843583          	ld	a1,-40(s0)
    80005bca:	68a8                	ld	a0,80(s1)
    80005bcc:	ffffc097          	auipc	ra,0xffffc
    80005bd0:	aca080e7          	jalr	-1334(ra) # 80001696 <copyout>
    80005bd4:	02054063          	bltz	a0,80005bf4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd8:	4691                	li	a3,4
    80005bda:	fc040613          	addi	a2,s0,-64
    80005bde:	fd843583          	ld	a1,-40(s0)
    80005be2:	0591                	addi	a1,a1,4
    80005be4:	68a8                	ld	a0,80(s1)
    80005be6:	ffffc097          	auipc	ra,0xffffc
    80005bea:	ab0080e7          	jalr	-1360(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf0:	06055563          	bgez	a0,80005c5a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bf4:	fc442783          	lw	a5,-60(s0)
    80005bf8:	07e9                	addi	a5,a5,26
    80005bfa:	078e                	slli	a5,a5,0x3
    80005bfc:	97a6                	add	a5,a5,s1
    80005bfe:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c02:	fc042783          	lw	a5,-64(s0)
    80005c06:	07e9                	addi	a5,a5,26
    80005c08:	078e                	slli	a5,a5,0x3
    80005c0a:	00f48533          	add	a0,s1,a5
    80005c0e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c12:	fd043503          	ld	a0,-48(s0)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	a26080e7          	jalr	-1498(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c1e:	fc843503          	ld	a0,-56(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	a1a080e7          	jalr	-1510(ra) # 8000463c <fileclose>
    return -1;
    80005c2a:	57fd                	li	a5,-1
    80005c2c:	a03d                	j	80005c5a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c2e:	fc442783          	lw	a5,-60(s0)
    80005c32:	0007c763          	bltz	a5,80005c40 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c36:	07e9                	addi	a5,a5,26
    80005c38:	078e                	slli	a5,a5,0x3
    80005c3a:	97a6                	add	a5,a5,s1
    80005c3c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c40:	fd043503          	ld	a0,-48(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	9f8080e7          	jalr	-1544(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c4c:	fc843503          	ld	a0,-56(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	9ec080e7          	jalr	-1556(ra) # 8000463c <fileclose>
    return -1;
    80005c58:	57fd                	li	a5,-1
}
    80005c5a:	853e                	mv	a0,a5
    80005c5c:	70e2                	ld	ra,56(sp)
    80005c5e:	7442                	ld	s0,48(sp)
    80005c60:	74a2                	ld	s1,40(sp)
    80005c62:	6121                	addi	sp,sp,64
    80005c64:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	d59fc0ef          	jal	ra,80002a08 <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	6d0c                	ld	a1,24(a0)
    80005d0c:	7110                	ld	a2,32(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c5e080e7          	jalr	-930(ra) # 800019a6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	97aa                	add	a5,a5,a0
    80005d6c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	c26080e7          	jalr	-986(ra) # 800019a6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5151b          	slliw	a0,a0,0xd
    80005d8c:	0c2017b7          	lui	a5,0xc201
    80005d90:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d92:	43c8                	lw	a0,4(a5)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	bfe080e7          	jalr	-1026(ra) # 800019a6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	06a7c863          	blt	a5,a0,80005e40 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005dd4:	0001d717          	auipc	a4,0x1d
    80005dd8:	22c70713          	addi	a4,a4,556 # 80023000 <disk>
    80005ddc:	972a                	add	a4,a4,a0
    80005dde:	6789                	lui	a5,0x2
    80005de0:	97ba                	add	a5,a5,a4
    80005de2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de6:	e7ad                	bnez	a5,80005e50 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005de8:	00451793          	slli	a5,a0,0x4
    80005dec:	0001f717          	auipc	a4,0x1f
    80005df0:	21470713          	addi	a4,a4,532 # 80025000 <disk+0x2000>
    80005df4:	6314                	ld	a3,0(a4)
    80005df6:	96be                	add	a3,a3,a5
    80005df8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dfc:	6314                	ld	a3,0(a4)
    80005dfe:	96be                	add	a3,a3,a5
    80005e00:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e04:	6314                	ld	a3,0(a4)
    80005e06:	96be                	add	a3,a3,a5
    80005e08:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e0c:	6318                	ld	a4,0(a4)
    80005e0e:	97ba                	add	a5,a5,a4
    80005e10:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e14:	0001d717          	auipc	a4,0x1d
    80005e18:	1ec70713          	addi	a4,a4,492 # 80023000 <disk>
    80005e1c:	972a                	add	a4,a4,a0
    80005e1e:	6789                	lui	a5,0x2
    80005e20:	97ba                	add	a5,a5,a4
    80005e22:	4705                	li	a4,1
    80005e24:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e28:	0001f517          	auipc	a0,0x1f
    80005e2c:	1f050513          	addi	a0,a0,496 # 80025018 <disk+0x2018>
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	3f2080e7          	jalr	1010(ra) # 80002222 <wakeup>
}
    80005e38:	60a2                	ld	ra,8(sp)
    80005e3a:	6402                	ld	s0,0(sp)
    80005e3c:	0141                	addi	sp,sp,16
    80005e3e:	8082                	ret
    panic("free_desc 1");
    80005e40:	00003517          	auipc	a0,0x3
    80005e44:	99850513          	addi	a0,a0,-1640 # 800087d8 <syscalls+0x330>
    80005e48:	ffffa097          	auipc	ra,0xffffa
    80005e4c:	6f2080e7          	jalr	1778(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005e50:	00003517          	auipc	a0,0x3
    80005e54:	99850513          	addi	a0,a0,-1640 # 800087e8 <syscalls+0x340>
    80005e58:	ffffa097          	auipc	ra,0xffffa
    80005e5c:	6e2080e7          	jalr	1762(ra) # 8000053a <panic>

0000000080005e60 <virtio_disk_init>:
{
    80005e60:	1101                	addi	sp,sp,-32
    80005e62:	ec06                	sd	ra,24(sp)
    80005e64:	e822                	sd	s0,16(sp)
    80005e66:	e426                	sd	s1,8(sp)
    80005e68:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e6a:	00003597          	auipc	a1,0x3
    80005e6e:	98e58593          	addi	a1,a1,-1650 # 800087f8 <syscalls+0x350>
    80005e72:	0001f517          	auipc	a0,0x1f
    80005e76:	2b650513          	addi	a0,a0,694 # 80025128 <disk+0x2128>
    80005e7a:	ffffb097          	auipc	ra,0xffffb
    80005e7e:	d10080e7          	jalr	-752(ra) # 80000b8a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e82:	100017b7          	lui	a5,0x10001
    80005e86:	4398                	lw	a4,0(a5)
    80005e88:	2701                	sext.w	a4,a4
    80005e8a:	747277b7          	lui	a5,0x74727
    80005e8e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e92:	0ef71063          	bne	a4,a5,80005f72 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e96:	100017b7          	lui	a5,0x10001
    80005e9a:	43dc                	lw	a5,4(a5)
    80005e9c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e9e:	4705                	li	a4,1
    80005ea0:	0ce79963          	bne	a5,a4,80005f72 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea4:	100017b7          	lui	a5,0x10001
    80005ea8:	479c                	lw	a5,8(a5)
    80005eaa:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eac:	4709                	li	a4,2
    80005eae:	0ce79263          	bne	a5,a4,80005f72 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eb2:	100017b7          	lui	a5,0x10001
    80005eb6:	47d8                	lw	a4,12(a5)
    80005eb8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eba:	554d47b7          	lui	a5,0x554d4
    80005ebe:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ec2:	0af71863          	bne	a4,a5,80005f72 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec6:	100017b7          	lui	a5,0x10001
    80005eca:	4705                	li	a4,1
    80005ecc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	470d                	li	a4,3
    80005ed0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ed2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ed4:	c7ffe6b7          	lui	a3,0xc7ffe
    80005ed8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005edc:	8f75                	and	a4,a4,a3
    80005ede:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee0:	472d                	li	a4,11
    80005ee2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee4:	473d                	li	a4,15
    80005ee6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ee8:	6705                	lui	a4,0x1
    80005eea:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eec:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ef0:	5bdc                	lw	a5,52(a5)
    80005ef2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ef4:	c7d9                	beqz	a5,80005f82 <virtio_disk_init+0x122>
  if(max < NUM)
    80005ef6:	471d                	li	a4,7
    80005ef8:	08f77d63          	bgeu	a4,a5,80005f92 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005efc:	100014b7          	lui	s1,0x10001
    80005f00:	47a1                	li	a5,8
    80005f02:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f04:	6609                	lui	a2,0x2
    80005f06:	4581                	li	a1,0
    80005f08:	0001d517          	auipc	a0,0x1d
    80005f0c:	0f850513          	addi	a0,a0,248 # 80023000 <disk>
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	e06080e7          	jalr	-506(ra) # 80000d16 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f18:	0001d717          	auipc	a4,0x1d
    80005f1c:	0e870713          	addi	a4,a4,232 # 80023000 <disk>
    80005f20:	00c75793          	srli	a5,a4,0xc
    80005f24:	2781                	sext.w	a5,a5
    80005f26:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f28:	0001f797          	auipc	a5,0x1f
    80005f2c:	0d878793          	addi	a5,a5,216 # 80025000 <disk+0x2000>
    80005f30:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f32:	0001d717          	auipc	a4,0x1d
    80005f36:	14e70713          	addi	a4,a4,334 # 80023080 <disk+0x80>
    80005f3a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f3c:	0001e717          	auipc	a4,0x1e
    80005f40:	0c470713          	addi	a4,a4,196 # 80024000 <disk+0x1000>
    80005f44:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f46:	4705                	li	a4,1
    80005f48:	00e78c23          	sb	a4,24(a5)
    80005f4c:	00e78ca3          	sb	a4,25(a5)
    80005f50:	00e78d23          	sb	a4,26(a5)
    80005f54:	00e78da3          	sb	a4,27(a5)
    80005f58:	00e78e23          	sb	a4,28(a5)
    80005f5c:	00e78ea3          	sb	a4,29(a5)
    80005f60:	00e78f23          	sb	a4,30(a5)
    80005f64:	00e78fa3          	sb	a4,31(a5)
}
    80005f68:	60e2                	ld	ra,24(sp)
    80005f6a:	6442                	ld	s0,16(sp)
    80005f6c:	64a2                	ld	s1,8(sp)
    80005f6e:	6105                	addi	sp,sp,32
    80005f70:	8082                	ret
    panic("could not find virtio disk");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	89650513          	addi	a0,a0,-1898 # 80008808 <syscalls+0x360>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c0080e7          	jalr	1472(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	8a650513          	addi	a0,a0,-1882 # 80008828 <syscalls+0x380>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b0080e7          	jalr	1456(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	8b650513          	addi	a0,a0,-1866 # 80008848 <syscalls+0x3a0>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a0080e7          	jalr	1440(ra) # 8000053a <panic>

0000000080005fa2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fa2:	7119                	addi	sp,sp,-128
    80005fa4:	fc86                	sd	ra,120(sp)
    80005fa6:	f8a2                	sd	s0,112(sp)
    80005fa8:	f4a6                	sd	s1,104(sp)
    80005faa:	f0ca                	sd	s2,96(sp)
    80005fac:	ecce                	sd	s3,88(sp)
    80005fae:	e8d2                	sd	s4,80(sp)
    80005fb0:	e4d6                	sd	s5,72(sp)
    80005fb2:	e0da                	sd	s6,64(sp)
    80005fb4:	fc5e                	sd	s7,56(sp)
    80005fb6:	f862                	sd	s8,48(sp)
    80005fb8:	f466                	sd	s9,40(sp)
    80005fba:	f06a                	sd	s10,32(sp)
    80005fbc:	ec6e                	sd	s11,24(sp)
    80005fbe:	0100                	addi	s0,sp,128
    80005fc0:	8aaa                	mv	s5,a0
    80005fc2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fc4:	00c52c83          	lw	s9,12(a0)
    80005fc8:	001c9c9b          	slliw	s9,s9,0x1
    80005fcc:	1c82                	slli	s9,s9,0x20
    80005fce:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fd2:	0001f517          	auipc	a0,0x1f
    80005fd6:	15650513          	addi	a0,a0,342 # 80025128 <disk+0x2128>
    80005fda:	ffffb097          	auipc	ra,0xffffb
    80005fde:	c40080e7          	jalr	-960(ra) # 80000c1a <acquire>
  for(int i = 0; i < 3; i++){
    80005fe2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fe4:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fe6:	0001dc17          	auipc	s8,0x1d
    80005fea:	01ac0c13          	addi	s8,s8,26 # 80023000 <disk>
    80005fee:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005ff0:	4b0d                	li	s6,3
    80005ff2:	a0ad                	j	8000605c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005ff4:	00fc0733          	add	a4,s8,a5
    80005ff8:	975e                	add	a4,a4,s7
    80005ffa:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ffe:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006000:	0207c563          	bltz	a5,8000602a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006004:	2905                	addiw	s2,s2,1
    80006006:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006008:	19690c63          	beq	s2,s6,800061a0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000600c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000600e:	0001f717          	auipc	a4,0x1f
    80006012:	00a70713          	addi	a4,a4,10 # 80025018 <disk+0x2018>
    80006016:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006018:	00074683          	lbu	a3,0(a4)
    8000601c:	fee1                	bnez	a3,80005ff4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000601e:	2785                	addiw	a5,a5,1
    80006020:	0705                	addi	a4,a4,1
    80006022:	fe979be3          	bne	a5,s1,80006018 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006026:	57fd                	li	a5,-1
    80006028:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000602a:	01205d63          	blez	s2,80006044 <virtio_disk_rw+0xa2>
    8000602e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006030:	000a2503          	lw	a0,0(s4)
    80006034:	00000097          	auipc	ra,0x0
    80006038:	d92080e7          	jalr	-622(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    8000603c:	2d85                	addiw	s11,s11,1
    8000603e:	0a11                	addi	s4,s4,4
    80006040:	ff2d98e3          	bne	s11,s2,80006030 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006044:	0001f597          	auipc	a1,0x1f
    80006048:	0e458593          	addi	a1,a1,228 # 80025128 <disk+0x2128>
    8000604c:	0001f517          	auipc	a0,0x1f
    80006050:	fcc50513          	addi	a0,a0,-52 # 80025018 <disk+0x2018>
    80006054:	ffffc097          	auipc	ra,0xffffc
    80006058:	042080e7          	jalr	66(ra) # 80002096 <sleep>
  for(int i = 0; i < 3; i++){
    8000605c:	f8040a13          	addi	s4,s0,-128
{
    80006060:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006062:	894e                	mv	s2,s3
    80006064:	b765                	j	8000600c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006066:	0001f697          	auipc	a3,0x1f
    8000606a:	f9a6b683          	ld	a3,-102(a3) # 80025000 <disk+0x2000>
    8000606e:	96ba                	add	a3,a3,a4
    80006070:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006074:	0001d817          	auipc	a6,0x1d
    80006078:	f8c80813          	addi	a6,a6,-116 # 80023000 <disk>
    8000607c:	0001f697          	auipc	a3,0x1f
    80006080:	f8468693          	addi	a3,a3,-124 # 80025000 <disk+0x2000>
    80006084:	6290                	ld	a2,0(a3)
    80006086:	963a                	add	a2,a2,a4
    80006088:	00c65583          	lhu	a1,12(a2)
    8000608c:	0015e593          	ori	a1,a1,1
    80006090:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006094:	f8842603          	lw	a2,-120(s0)
    80006098:	628c                	ld	a1,0(a3)
    8000609a:	972e                	add	a4,a4,a1
    8000609c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060a0:	20050593          	addi	a1,a0,512
    800060a4:	0592                	slli	a1,a1,0x4
    800060a6:	95c2                	add	a1,a1,a6
    800060a8:	577d                	li	a4,-1
    800060aa:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060ae:	00461713          	slli	a4,a2,0x4
    800060b2:	6290                	ld	a2,0(a3)
    800060b4:	963a                	add	a2,a2,a4
    800060b6:	03078793          	addi	a5,a5,48
    800060ba:	97c2                	add	a5,a5,a6
    800060bc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800060be:	629c                	ld	a5,0(a3)
    800060c0:	97ba                	add	a5,a5,a4
    800060c2:	4605                	li	a2,1
    800060c4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060c6:	629c                	ld	a5,0(a3)
    800060c8:	97ba                	add	a5,a5,a4
    800060ca:	4809                	li	a6,2
    800060cc:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060d0:	629c                	ld	a5,0(a3)
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060d8:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800060dc:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060e0:	6698                	ld	a4,8(a3)
    800060e2:	00275783          	lhu	a5,2(a4)
    800060e6:	8b9d                	andi	a5,a5,7
    800060e8:	0786                	slli	a5,a5,0x1
    800060ea:	973e                	add	a4,a4,a5
    800060ec:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800060f0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060f4:	6698                	ld	a4,8(a3)
    800060f6:	00275783          	lhu	a5,2(a4)
    800060fa:	2785                	addiw	a5,a5,1
    800060fc:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006100:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006104:	100017b7          	lui	a5,0x10001
    80006108:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000610c:	004aa783          	lw	a5,4(s5)
    80006110:	02c79163          	bne	a5,a2,80006132 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006114:	0001f917          	auipc	s2,0x1f
    80006118:	01490913          	addi	s2,s2,20 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000611c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000611e:	85ca                	mv	a1,s2
    80006120:	8556                	mv	a0,s5
    80006122:	ffffc097          	auipc	ra,0xffffc
    80006126:	f74080e7          	jalr	-140(ra) # 80002096 <sleep>
  while(b->disk == 1) {
    8000612a:	004aa783          	lw	a5,4(s5)
    8000612e:	fe9788e3          	beq	a5,s1,8000611e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006132:	f8042903          	lw	s2,-128(s0)
    80006136:	20090713          	addi	a4,s2,512
    8000613a:	0712                	slli	a4,a4,0x4
    8000613c:	0001d797          	auipc	a5,0x1d
    80006140:	ec478793          	addi	a5,a5,-316 # 80023000 <disk>
    80006144:	97ba                	add	a5,a5,a4
    80006146:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000614a:	0001f997          	auipc	s3,0x1f
    8000614e:	eb698993          	addi	s3,s3,-330 # 80025000 <disk+0x2000>
    80006152:	00491713          	slli	a4,s2,0x4
    80006156:	0009b783          	ld	a5,0(s3)
    8000615a:	97ba                	add	a5,a5,a4
    8000615c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006160:	854a                	mv	a0,s2
    80006162:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006166:	00000097          	auipc	ra,0x0
    8000616a:	c60080e7          	jalr	-928(ra) # 80005dc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000616e:	8885                	andi	s1,s1,1
    80006170:	f0ed                	bnez	s1,80006152 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006172:	0001f517          	auipc	a0,0x1f
    80006176:	fb650513          	addi	a0,a0,-74 # 80025128 <disk+0x2128>
    8000617a:	ffffb097          	auipc	ra,0xffffb
    8000617e:	b54080e7          	jalr	-1196(ra) # 80000cce <release>
}
    80006182:	70e6                	ld	ra,120(sp)
    80006184:	7446                	ld	s0,112(sp)
    80006186:	74a6                	ld	s1,104(sp)
    80006188:	7906                	ld	s2,96(sp)
    8000618a:	69e6                	ld	s3,88(sp)
    8000618c:	6a46                	ld	s4,80(sp)
    8000618e:	6aa6                	ld	s5,72(sp)
    80006190:	6b06                	ld	s6,64(sp)
    80006192:	7be2                	ld	s7,56(sp)
    80006194:	7c42                	ld	s8,48(sp)
    80006196:	7ca2                	ld	s9,40(sp)
    80006198:	7d02                	ld	s10,32(sp)
    8000619a:	6de2                	ld	s11,24(sp)
    8000619c:	6109                	addi	sp,sp,128
    8000619e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061a0:	f8042503          	lw	a0,-128(s0)
    800061a4:	20050793          	addi	a5,a0,512
    800061a8:	0792                	slli	a5,a5,0x4
  if(write)
    800061aa:	0001d817          	auipc	a6,0x1d
    800061ae:	e5680813          	addi	a6,a6,-426 # 80023000 <disk>
    800061b2:	00f80733          	add	a4,a6,a5
    800061b6:	01a036b3          	snez	a3,s10
    800061ba:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800061be:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061c2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061c6:	7679                	lui	a2,0xffffe
    800061c8:	963e                	add	a2,a2,a5
    800061ca:	0001f697          	auipc	a3,0x1f
    800061ce:	e3668693          	addi	a3,a3,-458 # 80025000 <disk+0x2000>
    800061d2:	6298                	ld	a4,0(a3)
    800061d4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061d6:	0a878593          	addi	a1,a5,168
    800061da:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061dc:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061de:	6298                	ld	a4,0(a3)
    800061e0:	9732                	add	a4,a4,a2
    800061e2:	45c1                	li	a1,16
    800061e4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061e6:	6298                	ld	a4,0(a3)
    800061e8:	9732                	add	a4,a4,a2
    800061ea:	4585                	li	a1,1
    800061ec:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061f0:	f8442703          	lw	a4,-124(s0)
    800061f4:	628c                	ld	a1,0(a3)
    800061f6:	962e                	add	a2,a2,a1
    800061f8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800061fc:	0712                	slli	a4,a4,0x4
    800061fe:	6290                	ld	a2,0(a3)
    80006200:	963a                	add	a2,a2,a4
    80006202:	058a8593          	addi	a1,s5,88
    80006206:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006208:	6294                	ld	a3,0(a3)
    8000620a:	96ba                	add	a3,a3,a4
    8000620c:	40000613          	li	a2,1024
    80006210:	c690                	sw	a2,8(a3)
  if(write)
    80006212:	e40d1ae3          	bnez	s10,80006066 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006216:	0001f697          	auipc	a3,0x1f
    8000621a:	dea6b683          	ld	a3,-534(a3) # 80025000 <disk+0x2000>
    8000621e:	96ba                	add	a3,a3,a4
    80006220:	4609                	li	a2,2
    80006222:	00c69623          	sh	a2,12(a3)
    80006226:	b5b9                	j	80006074 <virtio_disk_rw+0xd2>

0000000080006228 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006228:	1101                	addi	sp,sp,-32
    8000622a:	ec06                	sd	ra,24(sp)
    8000622c:	e822                	sd	s0,16(sp)
    8000622e:	e426                	sd	s1,8(sp)
    80006230:	e04a                	sd	s2,0(sp)
    80006232:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006234:	0001f517          	auipc	a0,0x1f
    80006238:	ef450513          	addi	a0,a0,-268 # 80025128 <disk+0x2128>
    8000623c:	ffffb097          	auipc	ra,0xffffb
    80006240:	9de080e7          	jalr	-1570(ra) # 80000c1a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006244:	10001737          	lui	a4,0x10001
    80006248:	533c                	lw	a5,96(a4)
    8000624a:	8b8d                	andi	a5,a5,3
    8000624c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000624e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006252:	0001f797          	auipc	a5,0x1f
    80006256:	dae78793          	addi	a5,a5,-594 # 80025000 <disk+0x2000>
    8000625a:	6b94                	ld	a3,16(a5)
    8000625c:	0207d703          	lhu	a4,32(a5)
    80006260:	0026d783          	lhu	a5,2(a3)
    80006264:	06f70163          	beq	a4,a5,800062c6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006268:	0001d917          	auipc	s2,0x1d
    8000626c:	d9890913          	addi	s2,s2,-616 # 80023000 <disk>
    80006270:	0001f497          	auipc	s1,0x1f
    80006274:	d9048493          	addi	s1,s1,-624 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006278:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000627c:	6898                	ld	a4,16(s1)
    8000627e:	0204d783          	lhu	a5,32(s1)
    80006282:	8b9d                	andi	a5,a5,7
    80006284:	078e                	slli	a5,a5,0x3
    80006286:	97ba                	add	a5,a5,a4
    80006288:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000628a:	20078713          	addi	a4,a5,512
    8000628e:	0712                	slli	a4,a4,0x4
    80006290:	974a                	add	a4,a4,s2
    80006292:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006296:	e731                	bnez	a4,800062e2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006298:	20078793          	addi	a5,a5,512
    8000629c:	0792                	slli	a5,a5,0x4
    8000629e:	97ca                	add	a5,a5,s2
    800062a0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062a2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062a6:	ffffc097          	auipc	ra,0xffffc
    800062aa:	f7c080e7          	jalr	-132(ra) # 80002222 <wakeup>

    disk.used_idx += 1;
    800062ae:	0204d783          	lhu	a5,32(s1)
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	17c2                	slli	a5,a5,0x30
    800062b6:	93c1                	srli	a5,a5,0x30
    800062b8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062bc:	6898                	ld	a4,16(s1)
    800062be:	00275703          	lhu	a4,2(a4)
    800062c2:	faf71be3          	bne	a4,a5,80006278 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800062c6:	0001f517          	auipc	a0,0x1f
    800062ca:	e6250513          	addi	a0,a0,-414 # 80025128 <disk+0x2128>
    800062ce:	ffffb097          	auipc	ra,0xffffb
    800062d2:	a00080e7          	jalr	-1536(ra) # 80000cce <release>
}
    800062d6:	60e2                	ld	ra,24(sp)
    800062d8:	6442                	ld	s0,16(sp)
    800062da:	64a2                	ld	s1,8(sp)
    800062dc:	6902                	ld	s2,0(sp)
    800062de:	6105                	addi	sp,sp,32
    800062e0:	8082                	ret
      panic("virtio_disk_intr status");
    800062e2:	00002517          	auipc	a0,0x2
    800062e6:	58650513          	addi	a0,a0,1414 # 80008868 <syscalls+0x3c0>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	250080e7          	jalr	592(ra) # 8000053a <panic>
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
