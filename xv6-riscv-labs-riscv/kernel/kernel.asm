
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	c0e78793          	addi	a5,a5,-1010 # 80005c70 <timervec>
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
    8000012e:	374080e7          	jalr	884(ra) # 8000249e <either_copyin>
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
    800001c4:	820080e7          	jalr	-2016(ra) # 800019e0 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	ed4080e7          	jalr	-300(ra) # 800020a4 <sleep>
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
    80000210:	23c080e7          	jalr	572(ra) # 80002448 <either_copyout>
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
    800002f0:	208080e7          	jalr	520(ra) # 800024f4 <procdump>
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
    80000444:	df0080e7          	jalr	-528(ra) # 80002230 <wakeup>
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
    80000892:	9a2080e7          	jalr	-1630(ra) # 80002230 <wakeup>
    
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
    8000091e:	78a080e7          	jalr	1930(ra) # 800020a4 <sleep>
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
  struct run *r;

  // Acquire a lock to ensure exclusive access to kernel memory management.
  acquire(&kmem.lock);
    80000b4a:	00010497          	auipc	s1,0x10
    80000b4e:	73648493          	addi	s1,s1,1846 # 80011280 <kmem>
    80000b52:	8526                	mv	a0,s1
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	0c6080e7          	jalr	198(ra) # 80000c1a <acquire>
  
  // Initialize a pointer 'r' to the head of the free memory list.
  r = kmem.freelist;
    80000b5c:	6c9c                	ld	a5,24(s1)

  // Traverse the free memory list and count the number of pages.
  while(r){
    80000b5e:	c785                	beqz	a5,80000b86 <freepmem+0x46>
  int numOfPages = 0;
    80000b60:	4481                	li	s1,0
    numOfPages++;
    80000b62:	2485                	addiw	s1,s1,1
    r = r->next;
    80000b64:	639c                	ld	a5,0(a5)
  while(r){
    80000b66:	fff5                	bnez	a5,80000b62 <freepmem+0x22>
  }
  
  // Release the lock to allow other threads to access the memory management.
  release(&kmem.lock);
    80000b68:	00010517          	auipc	a0,0x10
    80000b6c:	71850513          	addi	a0,a0,1816 # 80011280 <kmem>
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	15e080e7          	jalr	350(ra) # 80000cce <release>
  // times the total number of pages availble.
  int totalFreeMem = numOfPages * PGSIZE;

  // Return the total amount of free memory in bytes.
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
    80000bb8:	e10080e7          	jalr	-496(ra) # 800019c4 <mycpu>
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
    80000bea:	dde080e7          	jalr	-546(ra) # 800019c4 <mycpu>
    80000bee:	5d3c                	lw	a5,120(a0)
    80000bf0:	cf89                	beqz	a5,80000c0a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	dd2080e7          	jalr	-558(ra) # 800019c4 <mycpu>
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
    80000c0e:	dba080e7          	jalr	-582(ra) # 800019c4 <mycpu>
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
    80000c4e:	d7a080e7          	jalr	-646(ra) # 800019c4 <mycpu>
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
    80000c7a:	d4e080e7          	jalr	-690(ra) # 800019c4 <mycpu>
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
    80000ec8:	af0080e7          	jalr	-1296(ra) # 800019b4 <cpuid>
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
    80000ee4:	ad4080e7          	jalr	-1324(ra) # 800019b4 <cpuid>
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
    80000f06:	7f2080e7          	jalr	2034(ra) # 800026f4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0a:	00005097          	auipc	ra,0x5
    80000f0e:	da6080e7          	jalr	-602(ra) # 80005cb0 <plicinithart>
  }

  scheduler();        
    80000f12:	00001097          	auipc	ra,0x1
    80000f16:	fe0080e7          	jalr	-32(ra) # 80001ef2 <scheduler>
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
    80000f76:	992080e7          	jalr	-1646(ra) # 80001904 <procinit>
    trapinit();      // trap vectors
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	752080e7          	jalr	1874(ra) # 800026cc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	772080e7          	jalr	1906(ra) # 800026f4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	d10080e7          	jalr	-752(ra) # 80005c9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f92:	00005097          	auipc	ra,0x5
    80000f96:	d1e080e7          	jalr	-738(ra) # 80005cb0 <plicinithart>
    binit();         // buffer cache
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	ee8080e7          	jalr	-280(ra) # 80002e82 <binit>
    iinit();         // inode table
    80000fa2:	00002097          	auipc	ra,0x2
    80000fa6:	576080e7          	jalr	1398(ra) # 80003518 <iinit>
    fileinit();      // file table
    80000faa:	00003097          	auipc	ra,0x3
    80000fae:	528080e7          	jalr	1320(ra) # 800044d2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb2:	00005097          	auipc	ra,0x5
    80000fb6:	e1e080e7          	jalr	-482(ra) # 80005dd0 <virtio_disk_init>
    userinit();      // first user process
    80000fba:	00001097          	auipc	ra,0x1
    80000fbe:	cfe080e7          	jalr	-770(ra) # 80001cb8 <userinit>
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
    80001272:	600080e7          	jalr	1536(ra) # 8000186e <proc_mapstacks>
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
    800012c4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c6:	0632                	slli	a2,a2,0xc
    800012c8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012cc:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ce:	6b05                	lui	s6,0x1
    800012d0:	0735e263          	bltu	a1,s3,80001334 <uvmunmap+0x90>
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
      panic("uvmunmap: not mapped");
    8000130a:	00007517          	auipc	a0,0x7
    8000130e:	e1e50513          	addi	a0,a0,-482 # 80008128 <digits+0xe8>
    80001312:	fffff097          	auipc	ra,0xfffff
    80001316:	228080e7          	jalr	552(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    8000131a:	00007517          	auipc	a0,0x7
    8000131e:	e2650513          	addi	a0,a0,-474 # 80008140 <digits+0x100>
    80001322:	fffff097          	auipc	ra,0xfffff
    80001326:	218080e7          	jalr	536(ra) # 8000053a <panic>
    *pte = 0;
    8000132a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000132e:	995a                	add	s2,s2,s6
    80001330:	fb3972e3          	bgeu	s2,s3,800012d4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001334:	4601                	li	a2,0
    80001336:	85ca                	mv	a1,s2
    80001338:	8552                	mv	a0,s4
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	cbc080e7          	jalr	-836(ra) # 80000ff6 <walk>
    80001342:	84aa                	mv	s1,a0
    80001344:	d95d                	beqz	a0,800012fa <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001346:	6108                	ld	a0,0(a0)
    80001348:	00157793          	andi	a5,a0,1
    8000134c:	dfdd                	beqz	a5,8000130a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134e:	3ff57793          	andi	a5,a0,1023
    80001352:	fd7784e3          	beq	a5,s7,8000131a <uvmunmap+0x76>
    if(do_free){
    80001356:	fc0a8ae3          	beqz	s5,8000132a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000135a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000135c:	0532                	slli	a0,a0,0xc
    8000135e:	fffff097          	auipc	ra,0xfffff
    80001362:	684080e7          	jalr	1668(ra) # 800009e2 <kfree>
    80001366:	b7d1                	j	8000132a <uvmunmap+0x86>

0000000080001368 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001368:	1101                	addi	sp,sp,-32
    8000136a:	ec06                	sd	ra,24(sp)
    8000136c:	e822                	sd	s0,16(sp)
    8000136e:	e426                	sd	s1,8(sp)
    80001370:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	76e080e7          	jalr	1902(ra) # 80000ae0 <kalloc>
    8000137a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000137c:	c519                	beqz	a0,8000138a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000137e:	6605                	lui	a2,0x1
    80001380:	4581                	li	a1,0
    80001382:	00000097          	auipc	ra,0x0
    80001386:	994080e7          	jalr	-1644(ra) # 80000d16 <memset>
  return pagetable;
}
    8000138a:	8526                	mv	a0,s1
    8000138c:	60e2                	ld	ra,24(sp)
    8000138e:	6442                	ld	s0,16(sp)
    80001390:	64a2                	ld	s1,8(sp)
    80001392:	6105                	addi	sp,sp,32
    80001394:	8082                	ret

0000000080001396 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001396:	7179                	addi	sp,sp,-48
    80001398:	f406                	sd	ra,40(sp)
    8000139a:	f022                	sd	s0,32(sp)
    8000139c:	ec26                	sd	s1,24(sp)
    8000139e:	e84a                	sd	s2,16(sp)
    800013a0:	e44e                	sd	s3,8(sp)
    800013a2:	e052                	sd	s4,0(sp)
    800013a4:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013a6:	6785                	lui	a5,0x1
    800013a8:	04f67863          	bgeu	a2,a5,800013f8 <uvminit+0x62>
    800013ac:	8a2a                	mv	s4,a0
    800013ae:	89ae                	mv	s3,a1
    800013b0:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	72e080e7          	jalr	1838(ra) # 80000ae0 <kalloc>
    800013ba:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013bc:	6605                	lui	a2,0x1
    800013be:	4581                	li	a1,0
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	956080e7          	jalr	-1706(ra) # 80000d16 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013c8:	4779                	li	a4,30
    800013ca:	86ca                	mv	a3,s2
    800013cc:	6605                	lui	a2,0x1
    800013ce:	4581                	li	a1,0
    800013d0:	8552                	mv	a0,s4
    800013d2:	00000097          	auipc	ra,0x0
    800013d6:	d0c080e7          	jalr	-756(ra) # 800010de <mappages>
  memmove(mem, src, sz);
    800013da:	8626                	mv	a2,s1
    800013dc:	85ce                	mv	a1,s3
    800013de:	854a                	mv	a0,s2
    800013e0:	00000097          	auipc	ra,0x0
    800013e4:	992080e7          	jalr	-1646(ra) # 80000d72 <memmove>
}
    800013e8:	70a2                	ld	ra,40(sp)
    800013ea:	7402                	ld	s0,32(sp)
    800013ec:	64e2                	ld	s1,24(sp)
    800013ee:	6942                	ld	s2,16(sp)
    800013f0:	69a2                	ld	s3,8(sp)
    800013f2:	6a02                	ld	s4,0(sp)
    800013f4:	6145                	addi	sp,sp,48
    800013f6:	8082                	ret
    panic("inituvm: more than a page");
    800013f8:	00007517          	auipc	a0,0x7
    800013fc:	d6050513          	addi	a0,a0,-672 # 80008158 <digits+0x118>
    80001400:	fffff097          	auipc	ra,0xfffff
    80001404:	13a080e7          	jalr	314(ra) # 8000053a <panic>

0000000080001408 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001408:	1101                	addi	sp,sp,-32
    8000140a:	ec06                	sd	ra,24(sp)
    8000140c:	e822                	sd	s0,16(sp)
    8000140e:	e426                	sd	s1,8(sp)
    80001410:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001412:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001414:	00b67d63          	bgeu	a2,a1,8000142e <uvmdealloc+0x26>
    80001418:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000141a:	6785                	lui	a5,0x1
    8000141c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000141e:	00f60733          	add	a4,a2,a5
    80001422:	76fd                	lui	a3,0xfffff
    80001424:	8f75                	and	a4,a4,a3
    80001426:	97ae                	add	a5,a5,a1
    80001428:	8ff5                	and	a5,a5,a3
    8000142a:	00f76863          	bltu	a4,a5,8000143a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000142e:	8526                	mv	a0,s1
    80001430:	60e2                	ld	ra,24(sp)
    80001432:	6442                	ld	s0,16(sp)
    80001434:	64a2                	ld	s1,8(sp)
    80001436:	6105                	addi	sp,sp,32
    80001438:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000143a:	8f99                	sub	a5,a5,a4
    8000143c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000143e:	4685                	li	a3,1
    80001440:	0007861b          	sext.w	a2,a5
    80001444:	85ba                	mv	a1,a4
    80001446:	00000097          	auipc	ra,0x0
    8000144a:	e5e080e7          	jalr	-418(ra) # 800012a4 <uvmunmap>
    8000144e:	b7c5                	j	8000142e <uvmdealloc+0x26>

0000000080001450 <uvmalloc>:
  if(newsz < oldsz)
    80001450:	0ab66163          	bltu	a2,a1,800014f2 <uvmalloc+0xa2>
{
    80001454:	7139                	addi	sp,sp,-64
    80001456:	fc06                	sd	ra,56(sp)
    80001458:	f822                	sd	s0,48(sp)
    8000145a:	f426                	sd	s1,40(sp)
    8000145c:	f04a                	sd	s2,32(sp)
    8000145e:	ec4e                	sd	s3,24(sp)
    80001460:	e852                	sd	s4,16(sp)
    80001462:	e456                	sd	s5,8(sp)
    80001464:	0080                	addi	s0,sp,64
    80001466:	8aaa                	mv	s5,a0
    80001468:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000146a:	6785                	lui	a5,0x1
    8000146c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000146e:	95be                	add	a1,a1,a5
    80001470:	77fd                	lui	a5,0xfffff
    80001472:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001476:	08c9f063          	bgeu	s3,a2,800014f6 <uvmalloc+0xa6>
    8000147a:	894e                	mv	s2,s3
    mem = kalloc();
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	664080e7          	jalr	1636(ra) # 80000ae0 <kalloc>
    80001484:	84aa                	mv	s1,a0
    if(mem == 0){
    80001486:	c51d                	beqz	a0,800014b4 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001488:	6605                	lui	a2,0x1
    8000148a:	4581                	li	a1,0
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	88a080e7          	jalr	-1910(ra) # 80000d16 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001494:	4779                	li	a4,30
    80001496:	86a6                	mv	a3,s1
    80001498:	6605                	lui	a2,0x1
    8000149a:	85ca                	mv	a1,s2
    8000149c:	8556                	mv	a0,s5
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	c40080e7          	jalr	-960(ra) # 800010de <mappages>
    800014a6:	e905                	bnez	a0,800014d6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a8:	6785                	lui	a5,0x1
    800014aa:	993e                	add	s2,s2,a5
    800014ac:	fd4968e3          	bltu	s2,s4,8000147c <uvmalloc+0x2c>
  return newsz;
    800014b0:	8552                	mv	a0,s4
    800014b2:	a809                	j	800014c4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014b4:	864e                	mv	a2,s3
    800014b6:	85ca                	mv	a1,s2
    800014b8:	8556                	mv	a0,s5
    800014ba:	00000097          	auipc	ra,0x0
    800014be:	f4e080e7          	jalr	-178(ra) # 80001408 <uvmdealloc>
      return 0;
    800014c2:	4501                	li	a0,0
}
    800014c4:	70e2                	ld	ra,56(sp)
    800014c6:	7442                	ld	s0,48(sp)
    800014c8:	74a2                	ld	s1,40(sp)
    800014ca:	7902                	ld	s2,32(sp)
    800014cc:	69e2                	ld	s3,24(sp)
    800014ce:	6a42                	ld	s4,16(sp)
    800014d0:	6aa2                	ld	s5,8(sp)
    800014d2:	6121                	addi	sp,sp,64
    800014d4:	8082                	ret
      kfree(mem);
    800014d6:	8526                	mv	a0,s1
    800014d8:	fffff097          	auipc	ra,0xfffff
    800014dc:	50a080e7          	jalr	1290(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014e0:	864e                	mv	a2,s3
    800014e2:	85ca                	mv	a1,s2
    800014e4:	8556                	mv	a0,s5
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	f22080e7          	jalr	-222(ra) # 80001408 <uvmdealloc>
      return 0;
    800014ee:	4501                	li	a0,0
    800014f0:	bfd1                	j	800014c4 <uvmalloc+0x74>
    return oldsz;
    800014f2:	852e                	mv	a0,a1
}
    800014f4:	8082                	ret
  return newsz;
    800014f6:	8532                	mv	a0,a2
    800014f8:	b7f1                	j	800014c4 <uvmalloc+0x74>

00000000800014fa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014fa:	7179                	addi	sp,sp,-48
    800014fc:	f406                	sd	ra,40(sp)
    800014fe:	f022                	sd	s0,32(sp)
    80001500:	ec26                	sd	s1,24(sp)
    80001502:	e84a                	sd	s2,16(sp)
    80001504:	e44e                	sd	s3,8(sp)
    80001506:	e052                	sd	s4,0(sp)
    80001508:	1800                	addi	s0,sp,48
    8000150a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000150c:	84aa                	mv	s1,a0
    8000150e:	6905                	lui	s2,0x1
    80001510:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	4985                	li	s3,1
    80001514:	a829                	j	8000152e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001516:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001518:	00c79513          	slli	a0,a5,0xc
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	fde080e7          	jalr	-34(ra) # 800014fa <freewalk>
      pagetable[i] = 0;
    80001524:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001528:	04a1                	addi	s1,s1,8
    8000152a:	03248163          	beq	s1,s2,8000154c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000152e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001530:	00f7f713          	andi	a4,a5,15
    80001534:	ff3701e3          	beq	a4,s3,80001516 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001538:	8b85                	andi	a5,a5,1
    8000153a:	d7fd                	beqz	a5,80001528 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000153c:	00007517          	auipc	a0,0x7
    80001540:	c3c50513          	addi	a0,a0,-964 # 80008178 <digits+0x138>
    80001544:	fffff097          	auipc	ra,0xfffff
    80001548:	ff6080e7          	jalr	-10(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    8000154c:	8552                	mv	a0,s4
    8000154e:	fffff097          	auipc	ra,0xfffff
    80001552:	494080e7          	jalr	1172(ra) # 800009e2 <kfree>
}
    80001556:	70a2                	ld	ra,40(sp)
    80001558:	7402                	ld	s0,32(sp)
    8000155a:	64e2                	ld	s1,24(sp)
    8000155c:	6942                	ld	s2,16(sp)
    8000155e:	69a2                	ld	s3,8(sp)
    80001560:	6a02                	ld	s4,0(sp)
    80001562:	6145                	addi	sp,sp,48
    80001564:	8082                	ret

0000000080001566 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001566:	1101                	addi	sp,sp,-32
    80001568:	ec06                	sd	ra,24(sp)
    8000156a:	e822                	sd	s0,16(sp)
    8000156c:	e426                	sd	s1,8(sp)
    8000156e:	1000                	addi	s0,sp,32
    80001570:	84aa                	mv	s1,a0
  if(sz > 0)
    80001572:	e999                	bnez	a1,80001588 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001574:	8526                	mv	a0,s1
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	f84080e7          	jalr	-124(ra) # 800014fa <freewalk>
}
    8000157e:	60e2                	ld	ra,24(sp)
    80001580:	6442                	ld	s0,16(sp)
    80001582:	64a2                	ld	s1,8(sp)
    80001584:	6105                	addi	sp,sp,32
    80001586:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001588:	6785                	lui	a5,0x1
    8000158a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000158c:	95be                	add	a1,a1,a5
    8000158e:	4685                	li	a3,1
    80001590:	00c5d613          	srli	a2,a1,0xc
    80001594:	4581                	li	a1,0
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	d0e080e7          	jalr	-754(ra) # 800012a4 <uvmunmap>
    8000159e:	bfd9                	j	80001574 <uvmfree+0xe>

00000000800015a0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a0:	c679                	beqz	a2,8000166e <uvmcopy+0xce>
{
    800015a2:	715d                	addi	sp,sp,-80
    800015a4:	e486                	sd	ra,72(sp)
    800015a6:	e0a2                	sd	s0,64(sp)
    800015a8:	fc26                	sd	s1,56(sp)
    800015aa:	f84a                	sd	s2,48(sp)
    800015ac:	f44e                	sd	s3,40(sp)
    800015ae:	f052                	sd	s4,32(sp)
    800015b0:	ec56                	sd	s5,24(sp)
    800015b2:	e85a                	sd	s6,16(sp)
    800015b4:	e45e                	sd	s7,8(sp)
    800015b6:	0880                	addi	s0,sp,80
    800015b8:	8b2a                	mv	s6,a0
    800015ba:	8aae                	mv	s5,a1
    800015bc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015be:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c0:	4601                	li	a2,0
    800015c2:	85ce                	mv	a1,s3
    800015c4:	855a                	mv	a0,s6
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	a30080e7          	jalr	-1488(ra) # 80000ff6 <walk>
    800015ce:	c531                	beqz	a0,8000161a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d0:	6118                	ld	a4,0(a0)
    800015d2:	00177793          	andi	a5,a4,1
    800015d6:	cbb1                	beqz	a5,8000162a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015d8:	00a75593          	srli	a1,a4,0xa
    800015dc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	4fc080e7          	jalr	1276(ra) # 80000ae0 <kalloc>
    800015ec:	892a                	mv	s2,a0
    800015ee:	c939                	beqz	a0,80001644 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f0:	6605                	lui	a2,0x1
    800015f2:	85de                	mv	a1,s7
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	77e080e7          	jalr	1918(ra) # 80000d72 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015fc:	8726                	mv	a4,s1
    800015fe:	86ca                	mv	a3,s2
    80001600:	6605                	lui	a2,0x1
    80001602:	85ce                	mv	a1,s3
    80001604:	8556                	mv	a0,s5
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	ad8080e7          	jalr	-1320(ra) # 800010de <mappages>
    8000160e:	e515                	bnez	a0,8000163a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001610:	6785                	lui	a5,0x1
    80001612:	99be                	add	s3,s3,a5
    80001614:	fb49e6e3          	bltu	s3,s4,800015c0 <uvmcopy+0x20>
    80001618:	a081                	j	80001658 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000161a:	00007517          	auipc	a0,0x7
    8000161e:	b6e50513          	addi	a0,a0,-1170 # 80008188 <digits+0x148>
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	f18080e7          	jalr	-232(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    8000162a:	00007517          	auipc	a0,0x7
    8000162e:	b7e50513          	addi	a0,a0,-1154 # 800081a8 <digits+0x168>
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	f08080e7          	jalr	-248(ra) # 8000053a <panic>
      kfree(mem);
    8000163a:	854a                	mv	a0,s2
    8000163c:	fffff097          	auipc	ra,0xfffff
    80001640:	3a6080e7          	jalr	934(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001644:	4685                	li	a3,1
    80001646:	00c9d613          	srli	a2,s3,0xc
    8000164a:	4581                	li	a1,0
    8000164c:	8556                	mv	a0,s5
    8000164e:	00000097          	auipc	ra,0x0
    80001652:	c56080e7          	jalr	-938(ra) # 800012a4 <uvmunmap>
  return -1;
    80001656:	557d                	li	a0,-1
}
    80001658:	60a6                	ld	ra,72(sp)
    8000165a:	6406                	ld	s0,64(sp)
    8000165c:	74e2                	ld	s1,56(sp)
    8000165e:	7942                	ld	s2,48(sp)
    80001660:	79a2                	ld	s3,40(sp)
    80001662:	7a02                	ld	s4,32(sp)
    80001664:	6ae2                	ld	s5,24(sp)
    80001666:	6b42                	ld	s6,16(sp)
    80001668:	6ba2                	ld	s7,8(sp)
    8000166a:	6161                	addi	sp,sp,80
    8000166c:	8082                	ret
  return 0;
    8000166e:	4501                	li	a0,0
}
    80001670:	8082                	ret

0000000080001672 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001672:	1141                	addi	sp,sp,-16
    80001674:	e406                	sd	ra,8(sp)
    80001676:	e022                	sd	s0,0(sp)
    80001678:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000167a:	4601                	li	a2,0
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	97a080e7          	jalr	-1670(ra) # 80000ff6 <walk>
  if(pte == 0)
    80001684:	c901                	beqz	a0,80001694 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001686:	611c                	ld	a5,0(a0)
    80001688:	9bbd                	andi	a5,a5,-17
    8000168a:	e11c                	sd	a5,0(a0)
}
    8000168c:	60a2                	ld	ra,8(sp)
    8000168e:	6402                	ld	s0,0(sp)
    80001690:	0141                	addi	sp,sp,16
    80001692:	8082                	ret
    panic("uvmclear");
    80001694:	00007517          	auipc	a0,0x7
    80001698:	b3450513          	addi	a0,a0,-1228 # 800081c8 <digits+0x188>
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	e9e080e7          	jalr	-354(ra) # 8000053a <panic>

00000000800016a4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016a4:	c6bd                	beqz	a3,80001712 <copyout+0x6e>
{
    800016a6:	715d                	addi	sp,sp,-80
    800016a8:	e486                	sd	ra,72(sp)
    800016aa:	e0a2                	sd	s0,64(sp)
    800016ac:	fc26                	sd	s1,56(sp)
    800016ae:	f84a                	sd	s2,48(sp)
    800016b0:	f44e                	sd	s3,40(sp)
    800016b2:	f052                	sd	s4,32(sp)
    800016b4:	ec56                	sd	s5,24(sp)
    800016b6:	e85a                	sd	s6,16(sp)
    800016b8:	e45e                	sd	s7,8(sp)
    800016ba:	e062                	sd	s8,0(sp)
    800016bc:	0880                	addi	s0,sp,80
    800016be:	8b2a                	mv	s6,a0
    800016c0:	8c2e                	mv	s8,a1
    800016c2:	8a32                	mv	s4,a2
    800016c4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016c6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016c8:	6a85                	lui	s5,0x1
    800016ca:	a015                	j	800016ee <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016cc:	9562                	add	a0,a0,s8
    800016ce:	0004861b          	sext.w	a2,s1
    800016d2:	85d2                	mv	a1,s4
    800016d4:	41250533          	sub	a0,a0,s2
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	69a080e7          	jalr	1690(ra) # 80000d72 <memmove>

    len -= n;
    800016e0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016e4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016e6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ea:	02098263          	beqz	s3,8000170e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ee:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f2:	85ca                	mv	a1,s2
    800016f4:	855a                	mv	a0,s6
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	9a6080e7          	jalr	-1626(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    800016fe:	cd01                	beqz	a0,80001716 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001700:	418904b3          	sub	s1,s2,s8
    80001704:	94d6                	add	s1,s1,s5
    80001706:	fc99f3e3          	bgeu	s3,s1,800016cc <copyout+0x28>
    8000170a:	84ce                	mv	s1,s3
    8000170c:	b7c1                	j	800016cc <copyout+0x28>
  }
  return 0;
    8000170e:	4501                	li	a0,0
    80001710:	a021                	j	80001718 <copyout+0x74>
    80001712:	4501                	li	a0,0
}
    80001714:	8082                	ret
      return -1;
    80001716:	557d                	li	a0,-1
}
    80001718:	60a6                	ld	ra,72(sp)
    8000171a:	6406                	ld	s0,64(sp)
    8000171c:	74e2                	ld	s1,56(sp)
    8000171e:	7942                	ld	s2,48(sp)
    80001720:	79a2                	ld	s3,40(sp)
    80001722:	7a02                	ld	s4,32(sp)
    80001724:	6ae2                	ld	s5,24(sp)
    80001726:	6b42                	ld	s6,16(sp)
    80001728:	6ba2                	ld	s7,8(sp)
    8000172a:	6c02                	ld	s8,0(sp)
    8000172c:	6161                	addi	sp,sp,80
    8000172e:	8082                	ret

0000000080001730 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001730:	caa5                	beqz	a3,800017a0 <copyin+0x70>
{
    80001732:	715d                	addi	sp,sp,-80
    80001734:	e486                	sd	ra,72(sp)
    80001736:	e0a2                	sd	s0,64(sp)
    80001738:	fc26                	sd	s1,56(sp)
    8000173a:	f84a                	sd	s2,48(sp)
    8000173c:	f44e                	sd	s3,40(sp)
    8000173e:	f052                	sd	s4,32(sp)
    80001740:	ec56                	sd	s5,24(sp)
    80001742:	e85a                	sd	s6,16(sp)
    80001744:	e45e                	sd	s7,8(sp)
    80001746:	e062                	sd	s8,0(sp)
    80001748:	0880                	addi	s0,sp,80
    8000174a:	8b2a                	mv	s6,a0
    8000174c:	8a2e                	mv	s4,a1
    8000174e:	8c32                	mv	s8,a2
    80001750:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001752:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001754:	6a85                	lui	s5,0x1
    80001756:	a01d                	j	8000177c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001758:	018505b3          	add	a1,a0,s8
    8000175c:	0004861b          	sext.w	a2,s1
    80001760:	412585b3          	sub	a1,a1,s2
    80001764:	8552                	mv	a0,s4
    80001766:	fffff097          	auipc	ra,0xfffff
    8000176a:	60c080e7          	jalr	1548(ra) # 80000d72 <memmove>

    len -= n;
    8000176e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001772:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001774:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001778:	02098263          	beqz	s3,8000179c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000177c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001780:	85ca                	mv	a1,s2
    80001782:	855a                	mv	a0,s6
    80001784:	00000097          	auipc	ra,0x0
    80001788:	918080e7          	jalr	-1768(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    8000178c:	cd01                	beqz	a0,800017a4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000178e:	418904b3          	sub	s1,s2,s8
    80001792:	94d6                	add	s1,s1,s5
    80001794:	fc99f2e3          	bgeu	s3,s1,80001758 <copyin+0x28>
    80001798:	84ce                	mv	s1,s3
    8000179a:	bf7d                	j	80001758 <copyin+0x28>
  }
  return 0;
    8000179c:	4501                	li	a0,0
    8000179e:	a021                	j	800017a6 <copyin+0x76>
    800017a0:	4501                	li	a0,0
}
    800017a2:	8082                	ret
      return -1;
    800017a4:	557d                	li	a0,-1
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6c02                	ld	s8,0(sp)
    800017ba:	6161                	addi	sp,sp,80
    800017bc:	8082                	ret

00000000800017be <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017be:	c2dd                	beqz	a3,80001864 <copyinstr+0xa6>
{
    800017c0:	715d                	addi	sp,sp,-80
    800017c2:	e486                	sd	ra,72(sp)
    800017c4:	e0a2                	sd	s0,64(sp)
    800017c6:	fc26                	sd	s1,56(sp)
    800017c8:	f84a                	sd	s2,48(sp)
    800017ca:	f44e                	sd	s3,40(sp)
    800017cc:	f052                	sd	s4,32(sp)
    800017ce:	ec56                	sd	s5,24(sp)
    800017d0:	e85a                	sd	s6,16(sp)
    800017d2:	e45e                	sd	s7,8(sp)
    800017d4:	0880                	addi	s0,sp,80
    800017d6:	8a2a                	mv	s4,a0
    800017d8:	8b2e                	mv	s6,a1
    800017da:	8bb2                	mv	s7,a2
    800017dc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017de:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e0:	6985                	lui	s3,0x1
    800017e2:	a02d                	j	8000180c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017e4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017e8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ea:	37fd                	addiw	a5,a5,-1
    800017ec:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f0:	60a6                	ld	ra,72(sp)
    800017f2:	6406                	ld	s0,64(sp)
    800017f4:	74e2                	ld	s1,56(sp)
    800017f6:	7942                	ld	s2,48(sp)
    800017f8:	79a2                	ld	s3,40(sp)
    800017fa:	7a02                	ld	s4,32(sp)
    800017fc:	6ae2                	ld	s5,24(sp)
    800017fe:	6b42                	ld	s6,16(sp)
    80001800:	6ba2                	ld	s7,8(sp)
    80001802:	6161                	addi	sp,sp,80
    80001804:	8082                	ret
    srcva = va0 + PGSIZE;
    80001806:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000180a:	c8a9                	beqz	s1,8000185c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000180c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001810:	85ca                	mv	a1,s2
    80001812:	8552                	mv	a0,s4
    80001814:	00000097          	auipc	ra,0x0
    80001818:	888080e7          	jalr	-1912(ra) # 8000109c <walkaddr>
    if(pa0 == 0)
    8000181c:	c131                	beqz	a0,80001860 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000181e:	417906b3          	sub	a3,s2,s7
    80001822:	96ce                	add	a3,a3,s3
    80001824:	00d4f363          	bgeu	s1,a3,8000182a <copyinstr+0x6c>
    80001828:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000182a:	955e                	add	a0,a0,s7
    8000182c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001830:	daf9                	beqz	a3,80001806 <copyinstr+0x48>
    80001832:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001834:	41650633          	sub	a2,a0,s6
    80001838:	fff48593          	addi	a1,s1,-1
    8000183c:	95da                	add	a1,a1,s6
    while(n > 0){
    8000183e:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001840:	00f60733          	add	a4,a2,a5
    80001844:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001848:	df51                	beqz	a4,800017e4 <copyinstr+0x26>
        *dst = *p;
    8000184a:	00e78023          	sb	a4,0(a5)
      --max;
    8000184e:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001852:	0785                	addi	a5,a5,1
    while(n > 0){
    80001854:	fed796e3          	bne	a5,a3,80001840 <copyinstr+0x82>
      dst++;
    80001858:	8b3e                	mv	s6,a5
    8000185a:	b775                	j	80001806 <copyinstr+0x48>
    8000185c:	4781                	li	a5,0
    8000185e:	b771                	j	800017ea <copyinstr+0x2c>
      return -1;
    80001860:	557d                	li	a0,-1
    80001862:	b779                	j	800017f0 <copyinstr+0x32>
  int got_null = 0;
    80001864:	4781                	li	a5,0
  if(got_null){
    80001866:	37fd                	addiw	a5,a5,-1
    80001868:	0007851b          	sext.w	a0,a5
}
    8000186c:	8082                	ret

000000008000186e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000186e:	7139                	addi	sp,sp,-64
    80001870:	fc06                	sd	ra,56(sp)
    80001872:	f822                	sd	s0,48(sp)
    80001874:	f426                	sd	s1,40(sp)
    80001876:	f04a                	sd	s2,32(sp)
    80001878:	ec4e                	sd	s3,24(sp)
    8000187a:	e852                	sd	s4,16(sp)
    8000187c:	e456                	sd	s5,8(sp)
    8000187e:	e05a                	sd	s6,0(sp)
    80001880:	0080                	addi	s0,sp,64
    80001882:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001884:	00010497          	auipc	s1,0x10
    80001888:	e4c48493          	addi	s1,s1,-436 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000188c:	8b26                	mv	s6,s1
    8000188e:	00006a97          	auipc	s5,0x6
    80001892:	772a8a93          	addi	s5,s5,1906 # 80008000 <etext>
    80001896:	04000937          	lui	s2,0x4000
    8000189a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000189c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189e:	00016a17          	auipc	s4,0x16
    800018a2:	832a0a13          	addi	s4,s4,-1998 # 800170d0 <tickslock>
    char *pa = kalloc();
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	23a080e7          	jalr	570(ra) # 80000ae0 <kalloc>
    800018ae:	862a                	mv	a2,a0
    if(pa == 0)
    800018b0:	c131                	beqz	a0,800018f4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018b2:	416485b3          	sub	a1,s1,s6
    800018b6:	858d                	srai	a1,a1,0x3
    800018b8:	000ab783          	ld	a5,0(s5)
    800018bc:	02f585b3          	mul	a1,a1,a5
    800018c0:	2585                	addiw	a1,a1,1
    800018c2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018c6:	4719                	li	a4,6
    800018c8:	6685                	lui	a3,0x1
    800018ca:	40b905b3          	sub	a1,s2,a1
    800018ce:	854e                	mv	a0,s3
    800018d0:	00000097          	auipc	ra,0x0
    800018d4:	8ae080e7          	jalr	-1874(ra) # 8000117e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d8:	16848493          	addi	s1,s1,360
    800018dc:	fd4495e3          	bne	s1,s4,800018a6 <proc_mapstacks+0x38>
  }
}
    800018e0:	70e2                	ld	ra,56(sp)
    800018e2:	7442                	ld	s0,48(sp)
    800018e4:	74a2                	ld	s1,40(sp)
    800018e6:	7902                	ld	s2,32(sp)
    800018e8:	69e2                	ld	s3,24(sp)
    800018ea:	6a42                	ld	s4,16(sp)
    800018ec:	6aa2                	ld	s5,8(sp)
    800018ee:	6b02                	ld	s6,0(sp)
    800018f0:	6121                	addi	sp,sp,64
    800018f2:	8082                	ret
      panic("kalloc");
    800018f4:	00007517          	auipc	a0,0x7
    800018f8:	8e450513          	addi	a0,a0,-1820 # 800081d8 <digits+0x198>
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	c3e080e7          	jalr	-962(ra) # 8000053a <panic>

0000000080001904 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001904:	7139                	addi	sp,sp,-64
    80001906:	fc06                	sd	ra,56(sp)
    80001908:	f822                	sd	s0,48(sp)
    8000190a:	f426                	sd	s1,40(sp)
    8000190c:	f04a                	sd	s2,32(sp)
    8000190e:	ec4e                	sd	s3,24(sp)
    80001910:	e852                	sd	s4,16(sp)
    80001912:	e456                	sd	s5,8(sp)
    80001914:	e05a                	sd	s6,0(sp)
    80001916:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001918:	00007597          	auipc	a1,0x7
    8000191c:	8c858593          	addi	a1,a1,-1848 # 800081e0 <digits+0x1a0>
    80001920:	00010517          	auipc	a0,0x10
    80001924:	98050513          	addi	a0,a0,-1664 # 800112a0 <pid_lock>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	262080e7          	jalr	610(ra) # 80000b8a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001930:	00007597          	auipc	a1,0x7
    80001934:	8b858593          	addi	a1,a1,-1864 # 800081e8 <digits+0x1a8>
    80001938:	00010517          	auipc	a0,0x10
    8000193c:	98050513          	addi	a0,a0,-1664 # 800112b8 <wait_lock>
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	24a080e7          	jalr	586(ra) # 80000b8a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001948:	00010497          	auipc	s1,0x10
    8000194c:	d8848493          	addi	s1,s1,-632 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001950:	00007b17          	auipc	s6,0x7
    80001954:	8a8b0b13          	addi	s6,s6,-1880 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001958:	8aa6                	mv	s5,s1
    8000195a:	00006a17          	auipc	s4,0x6
    8000195e:	6a6a0a13          	addi	s4,s4,1702 # 80008000 <etext>
    80001962:	04000937          	lui	s2,0x4000
    80001966:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001968:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	00015997          	auipc	s3,0x15
    8000196e:	76698993          	addi	s3,s3,1894 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001972:	85da                	mv	a1,s6
    80001974:	8526                	mv	a0,s1
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	214080e7          	jalr	532(ra) # 80000b8a <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000197e:	415487b3          	sub	a5,s1,s5
    80001982:	878d                	srai	a5,a5,0x3
    80001984:	000a3703          	ld	a4,0(s4)
    80001988:	02e787b3          	mul	a5,a5,a4
    8000198c:	2785                	addiw	a5,a5,1
    8000198e:	00d7979b          	slliw	a5,a5,0xd
    80001992:	40f907b3          	sub	a5,s2,a5
    80001996:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001998:	16848493          	addi	s1,s1,360
    8000199c:	fd349be3          	bne	s1,s3,80001972 <procinit+0x6e>
  }
}
    800019a0:	70e2                	ld	ra,56(sp)
    800019a2:	7442                	ld	s0,48(sp)
    800019a4:	74a2                	ld	s1,40(sp)
    800019a6:	7902                	ld	s2,32(sp)
    800019a8:	69e2                	ld	s3,24(sp)
    800019aa:	6a42                	ld	s4,16(sp)
    800019ac:	6aa2                	ld	s5,8(sp)
    800019ae:	6b02                	ld	s6,0(sp)
    800019b0:	6121                	addi	sp,sp,64
    800019b2:	8082                	ret

00000000800019b4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019b4:	1141                	addi	sp,sp,-16
    800019b6:	e422                	sd	s0,8(sp)
    800019b8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ba:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019bc:	2501                	sext.w	a0,a0
    800019be:	6422                	ld	s0,8(sp)
    800019c0:	0141                	addi	sp,sp,16
    800019c2:	8082                	ret

00000000800019c4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019c4:	1141                	addi	sp,sp,-16
    800019c6:	e422                	sd	s0,8(sp)
    800019c8:	0800                	addi	s0,sp,16
    800019ca:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019cc:	2781                	sext.w	a5,a5
    800019ce:	079e                	slli	a5,a5,0x7
  return c;
}
    800019d0:	00010517          	auipc	a0,0x10
    800019d4:	90050513          	addi	a0,a0,-1792 # 800112d0 <cpus>
    800019d8:	953e                	add	a0,a0,a5
    800019da:	6422                	ld	s0,8(sp)
    800019dc:	0141                	addi	sp,sp,16
    800019de:	8082                	ret

00000000800019e0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019e0:	1101                	addi	sp,sp,-32
    800019e2:	ec06                	sd	ra,24(sp)
    800019e4:	e822                	sd	s0,16(sp)
    800019e6:	e426                	sd	s1,8(sp)
    800019e8:	1000                	addi	s0,sp,32
  push_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	1e4080e7          	jalr	484(ra) # 80000bce <push_off>
    800019f2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019f4:	2781                	sext.w	a5,a5
    800019f6:	079e                	slli	a5,a5,0x7
    800019f8:	00010717          	auipc	a4,0x10
    800019fc:	8a870713          	addi	a4,a4,-1880 # 800112a0 <pid_lock>
    80001a00:	97ba                	add	a5,a5,a4
    80001a02:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	26a080e7          	jalr	618(ra) # 80000c6e <pop_off>
  return p;
}
    80001a0c:	8526                	mv	a0,s1
    80001a0e:	60e2                	ld	ra,24(sp)
    80001a10:	6442                	ld	s0,16(sp)
    80001a12:	64a2                	ld	s1,8(sp)
    80001a14:	6105                	addi	sp,sp,32
    80001a16:	8082                	ret

0000000080001a18 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a18:	1141                	addi	sp,sp,-16
    80001a1a:	e406                	sd	ra,8(sp)
    80001a1c:	e022                	sd	s0,0(sp)
    80001a1e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a20:	00000097          	auipc	ra,0x0
    80001a24:	fc0080e7          	jalr	-64(ra) # 800019e0 <myproc>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	2a6080e7          	jalr	678(ra) # 80000cce <release>

  if (first) {
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	df07a783          	lw	a5,-528(a5) # 80008820 <first.1>
    80001a38:	eb89                	bnez	a5,80001a4a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a3a:	00001097          	auipc	ra,0x1
    80001a3e:	cd2080e7          	jalr	-814(ra) # 8000270c <usertrapret>
}
    80001a42:	60a2                	ld	ra,8(sp)
    80001a44:	6402                	ld	s0,0(sp)
    80001a46:	0141                	addi	sp,sp,16
    80001a48:	8082                	ret
    first = 0;
    80001a4a:	00007797          	auipc	a5,0x7
    80001a4e:	dc07ab23          	sw	zero,-554(a5) # 80008820 <first.1>
    fsinit(ROOTDEV);
    80001a52:	4505                	li	a0,1
    80001a54:	00002097          	auipc	ra,0x2
    80001a58:	a44080e7          	jalr	-1468(ra) # 80003498 <fsinit>
    80001a5c:	bff9                	j	80001a3a <forkret+0x22>

0000000080001a5e <allocpid>:
allocpid() {
    80001a5e:	1101                	addi	sp,sp,-32
    80001a60:	ec06                	sd	ra,24(sp)
    80001a62:	e822                	sd	s0,16(sp)
    80001a64:	e426                	sd	s1,8(sp)
    80001a66:	e04a                	sd	s2,0(sp)
    80001a68:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a6a:	00010917          	auipc	s2,0x10
    80001a6e:	83690913          	addi	s2,s2,-1994 # 800112a0 <pid_lock>
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	1a6080e7          	jalr	422(ra) # 80000c1a <acquire>
  pid = nextpid;
    80001a7c:	00007797          	auipc	a5,0x7
    80001a80:	da878793          	addi	a5,a5,-600 # 80008824 <nextpid>
    80001a84:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a86:	0014871b          	addiw	a4,s1,1
    80001a8a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a8c:	854a                	mv	a0,s2
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	240080e7          	jalr	576(ra) # 80000cce <release>
}
    80001a96:	8526                	mv	a0,s1
    80001a98:	60e2                	ld	ra,24(sp)
    80001a9a:	6442                	ld	s0,16(sp)
    80001a9c:	64a2                	ld	s1,8(sp)
    80001a9e:	6902                	ld	s2,0(sp)
    80001aa0:	6105                	addi	sp,sp,32
    80001aa2:	8082                	ret

0000000080001aa4 <proc_pagetable>:
{
    80001aa4:	1101                	addi	sp,sp,-32
    80001aa6:	ec06                	sd	ra,24(sp)
    80001aa8:	e822                	sd	s0,16(sp)
    80001aaa:	e426                	sd	s1,8(sp)
    80001aac:	e04a                	sd	s2,0(sp)
    80001aae:	1000                	addi	s0,sp,32
    80001ab0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab2:	00000097          	auipc	ra,0x0
    80001ab6:	8b6080e7          	jalr	-1866(ra) # 80001368 <uvmcreate>
    80001aba:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001abc:	c121                	beqz	a0,80001afc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001abe:	4729                	li	a4,10
    80001ac0:	00005697          	auipc	a3,0x5
    80001ac4:	54068693          	addi	a3,a3,1344 # 80007000 <_trampoline>
    80001ac8:	6605                	lui	a2,0x1
    80001aca:	040005b7          	lui	a1,0x4000
    80001ace:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ad0:	05b2                	slli	a1,a1,0xc
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	60c080e7          	jalr	1548(ra) # 800010de <mappages>
    80001ada:	02054863          	bltz	a0,80001b0a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ade:	4719                	li	a4,6
    80001ae0:	05893683          	ld	a3,88(s2)
    80001ae4:	6605                	lui	a2,0x1
    80001ae6:	020005b7          	lui	a1,0x2000
    80001aea:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aec:	05b6                	slli	a1,a1,0xd
    80001aee:	8526                	mv	a0,s1
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	5ee080e7          	jalr	1518(ra) # 800010de <mappages>
    80001af8:	02054163          	bltz	a0,80001b1a <proc_pagetable+0x76>
}
    80001afc:	8526                	mv	a0,s1
    80001afe:	60e2                	ld	ra,24(sp)
    80001b00:	6442                	ld	s0,16(sp)
    80001b02:	64a2                	ld	s1,8(sp)
    80001b04:	6902                	ld	s2,0(sp)
    80001b06:	6105                	addi	sp,sp,32
    80001b08:	8082                	ret
    uvmfree(pagetable, 0);
    80001b0a:	4581                	li	a1,0
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	a58080e7          	jalr	-1448(ra) # 80001566 <uvmfree>
    return 0;
    80001b16:	4481                	li	s1,0
    80001b18:	b7d5                	j	80001afc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	040005b7          	lui	a1,0x4000
    80001b22:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b24:	05b2                	slli	a1,a1,0xc
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	77c080e7          	jalr	1916(ra) # 800012a4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b30:	4581                	li	a1,0
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	a32080e7          	jalr	-1486(ra) # 80001566 <uvmfree>
    return 0;
    80001b3c:	4481                	li	s1,0
    80001b3e:	bf7d                	j	80001afc <proc_pagetable+0x58>

0000000080001b40 <proc_freepagetable>:
{
    80001b40:	1101                	addi	sp,sp,-32
    80001b42:	ec06                	sd	ra,24(sp)
    80001b44:	e822                	sd	s0,16(sp)
    80001b46:	e426                	sd	s1,8(sp)
    80001b48:	e04a                	sd	s2,0(sp)
    80001b4a:	1000                	addi	s0,sp,32
    80001b4c:	84aa                	mv	s1,a0
    80001b4e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b50:	4681                	li	a3,0
    80001b52:	4605                	li	a2,1
    80001b54:	040005b7          	lui	a1,0x4000
    80001b58:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b5a:	05b2                	slli	a1,a1,0xc
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	748080e7          	jalr	1864(ra) # 800012a4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b64:	4681                	li	a3,0
    80001b66:	4605                	li	a2,1
    80001b68:	020005b7          	lui	a1,0x2000
    80001b6c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b6e:	05b6                	slli	a1,a1,0xd
    80001b70:	8526                	mv	a0,s1
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	732080e7          	jalr	1842(ra) # 800012a4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b7a:	85ca                	mv	a1,s2
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	00000097          	auipc	ra,0x0
    80001b82:	9e8080e7          	jalr	-1560(ra) # 80001566 <uvmfree>
}
    80001b86:	60e2                	ld	ra,24(sp)
    80001b88:	6442                	ld	s0,16(sp)
    80001b8a:	64a2                	ld	s1,8(sp)
    80001b8c:	6902                	ld	s2,0(sp)
    80001b8e:	6105                	addi	sp,sp,32
    80001b90:	8082                	ret

0000000080001b92 <freeproc>:
{
    80001b92:	1101                	addi	sp,sp,-32
    80001b94:	ec06                	sd	ra,24(sp)
    80001b96:	e822                	sd	s0,16(sp)
    80001b98:	e426                	sd	s1,8(sp)
    80001b9a:	1000                	addi	s0,sp,32
    80001b9c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b9e:	6d28                	ld	a0,88(a0)
    80001ba0:	c509                	beqz	a0,80001baa <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	e40080e7          	jalr	-448(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001baa:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bae:	68a8                	ld	a0,80(s1)
    80001bb0:	c511                	beqz	a0,80001bbc <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bb2:	64ac                	ld	a1,72(s1)
    80001bb4:	00000097          	auipc	ra,0x0
    80001bb8:	f8c080e7          	jalr	-116(ra) # 80001b40 <proc_freepagetable>
  p->pagetable = 0;
    80001bbc:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bc0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bc4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bc8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bcc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bd0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bd4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bd8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bdc:	0004ac23          	sw	zero,24(s1)
}
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6105                	addi	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <allocproc>:
{
    80001bea:	1101                	addi	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	e04a                	sd	s2,0(sp)
    80001bf4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf6:	00010497          	auipc	s1,0x10
    80001bfa:	ada48493          	addi	s1,s1,-1318 # 800116d0 <proc>
    80001bfe:	00015917          	auipc	s2,0x15
    80001c02:	4d290913          	addi	s2,s2,1234 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	012080e7          	jalr	18(ra) # 80000c1a <acquire>
    if(p->state == UNUSED) {
    80001c10:	4c9c                	lw	a5,24(s1)
    80001c12:	cf81                	beqz	a5,80001c2a <allocproc+0x40>
      release(&p->lock);
    80001c14:	8526                	mv	a0,s1
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b8080e7          	jalr	184(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1e:	16848493          	addi	s1,s1,360
    80001c22:	ff2492e3          	bne	s1,s2,80001c06 <allocproc+0x1c>
  return 0;
    80001c26:	4481                	li	s1,0
    80001c28:	a889                	j	80001c7a <allocproc+0x90>
  p->pid = allocpid();
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	e34080e7          	jalr	-460(ra) # 80001a5e <allocpid>
    80001c32:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c34:	4785                	li	a5,1
    80001c36:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	ea8080e7          	jalr	-344(ra) # 80000ae0 <kalloc>
    80001c40:	892a                	mv	s2,a0
    80001c42:	eca8                	sd	a0,88(s1)
    80001c44:	c131                	beqz	a0,80001c88 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	e5c080e7          	jalr	-420(ra) # 80001aa4 <proc_pagetable>
    80001c50:	892a                	mv	s2,a0
    80001c52:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c54:	c531                	beqz	a0,80001ca0 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c56:	07000613          	li	a2,112
    80001c5a:	4581                	li	a1,0
    80001c5c:	06048513          	addi	a0,s1,96
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	0b6080e7          	jalr	182(ra) # 80000d16 <memset>
  p->context.ra = (uint64)forkret;
    80001c68:	00000797          	auipc	a5,0x0
    80001c6c:	db078793          	addi	a5,a5,-592 # 80001a18 <forkret>
    80001c70:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c72:	60bc                	ld	a5,64(s1)
    80001c74:	6705                	lui	a4,0x1
    80001c76:	97ba                	add	a5,a5,a4
    80001c78:	f4bc                	sd	a5,104(s1)
}
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	60e2                	ld	ra,24(sp)
    80001c7e:	6442                	ld	s0,16(sp)
    80001c80:	64a2                	ld	s1,8(sp)
    80001c82:	6902                	ld	s2,0(sp)
    80001c84:	6105                	addi	sp,sp,32
    80001c86:	8082                	ret
    freeproc(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	f08080e7          	jalr	-248(ra) # 80001b92 <freeproc>
    release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	03a080e7          	jalr	58(ra) # 80000cce <release>
    return 0;
    80001c9c:	84ca                	mv	s1,s2
    80001c9e:	bff1                	j	80001c7a <allocproc+0x90>
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	ef0080e7          	jalr	-272(ra) # 80001b92 <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	022080e7          	jalr	34(ra) # 80000cce <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	b7d1                	j	80001c7a <allocproc+0x90>

0000000080001cb8 <userinit>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	f28080e7          	jalr	-216(ra) # 80001bea <allocproc>
    80001cca:	84aa                	mv	s1,a0
  initproc = p;
    80001ccc:	00007797          	auipc	a5,0x7
    80001cd0:	34a7be23          	sd	a0,860(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd4:	03400613          	li	a2,52
    80001cd8:	00007597          	auipc	a1,0x7
    80001cdc:	b5858593          	addi	a1,a1,-1192 # 80008830 <initcode>
    80001ce0:	6928                	ld	a0,80(a0)
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	6b4080e7          	jalr	1716(ra) # 80001396 <uvminit>
  p->sz = PGSIZE;
    80001cea:	6785                	lui	a5,0x1
    80001cec:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cee:	6cb8                	ld	a4,88(s1)
    80001cf0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf4:	6cb8                	ld	a4,88(s1)
    80001cf6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf8:	4641                	li	a2,16
    80001cfa:	00006597          	auipc	a1,0x6
    80001cfe:	50658593          	addi	a1,a1,1286 # 80008200 <digits+0x1c0>
    80001d02:	15848513          	addi	a0,s1,344
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	15a080e7          	jalr	346(ra) # 80000e60 <safestrcpy>
  p->cwd = namei("/");
    80001d0e:	00006517          	auipc	a0,0x6
    80001d12:	50250513          	addi	a0,a0,1282 # 80008210 <digits+0x1d0>
    80001d16:	00002097          	auipc	ra,0x2
    80001d1a:	1b8080e7          	jalr	440(ra) # 80003ece <namei>
    80001d1e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d22:	478d                	li	a5,3
    80001d24:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	fa6080e7          	jalr	-90(ra) # 80000cce <release>
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret

0000000080001d3a <growproc>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	e04a                	sd	s2,0(sp)
    80001d44:	1000                	addi	s0,sp,32
    80001d46:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	c98080e7          	jalr	-872(ra) # 800019e0 <myproc>
    80001d50:	892a                	mv	s2,a0
  sz = p->sz;
    80001d52:	652c                	ld	a1,72(a0)
    80001d54:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d58:	00904f63          	bgtz	s1,80001d76 <growproc+0x3c>
  } else if(n < 0){
    80001d5c:	0204cd63          	bltz	s1,80001d96 <growproc+0x5c>
  p->sz = sz;
    80001d60:	1782                	slli	a5,a5,0x20
    80001d62:	9381                	srli	a5,a5,0x20
    80001d64:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d68:	4501                	li	a0,0
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6902                	ld	s2,0(sp)
    80001d72:	6105                	addi	sp,sp,32
    80001d74:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d76:	00f4863b          	addw	a2,s1,a5
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	6cc080e7          	jalr	1740(ra) # 80001450 <uvmalloc>
    80001d8c:	0005079b          	sext.w	a5,a0
    80001d90:	fbe1                	bnez	a5,80001d60 <growproc+0x26>
      return -1;
    80001d92:	557d                	li	a0,-1
    80001d94:	bfd9                	j	80001d6a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d96:	00f4863b          	addw	a2,s1,a5
    80001d9a:	1602                	slli	a2,a2,0x20
    80001d9c:	9201                	srli	a2,a2,0x20
    80001d9e:	1582                	slli	a1,a1,0x20
    80001da0:	9181                	srli	a1,a1,0x20
    80001da2:	6928                	ld	a0,80(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	664080e7          	jalr	1636(ra) # 80001408 <uvmdealloc>
    80001dac:	0005079b          	sext.w	a5,a0
    80001db0:	bf45                	j	80001d60 <growproc+0x26>

0000000080001db2 <fork>:
{
    80001db2:	7139                	addi	sp,sp,-64
    80001db4:	fc06                	sd	ra,56(sp)
    80001db6:	f822                	sd	s0,48(sp)
    80001db8:	f426                	sd	s1,40(sp)
    80001dba:	f04a                	sd	s2,32(sp)
    80001dbc:	ec4e                	sd	s3,24(sp)
    80001dbe:	e852                	sd	s4,16(sp)
    80001dc0:	e456                	sd	s5,8(sp)
    80001dc2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	c1c080e7          	jalr	-996(ra) # 800019e0 <myproc>
    80001dcc:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	e1c080e7          	jalr	-484(ra) # 80001bea <allocproc>
    80001dd6:	10050c63          	beqz	a0,80001eee <fork+0x13c>
    80001dda:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ddc:	048ab603          	ld	a2,72(s5)
    80001de0:	692c                	ld	a1,80(a0)
    80001de2:	050ab503          	ld	a0,80(s5)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	7ba080e7          	jalr	1978(ra) # 800015a0 <uvmcopy>
    80001dee:	04054863          	bltz	a0,80001e3e <fork+0x8c>
  np->sz = p->sz;
    80001df2:	048ab783          	ld	a5,72(s5)
    80001df6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dfa:	058ab683          	ld	a3,88(s5)
    80001dfe:	87b6                	mv	a5,a3
    80001e00:	058a3703          	ld	a4,88(s4)
    80001e04:	12068693          	addi	a3,a3,288
    80001e08:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0c:	6788                	ld	a0,8(a5)
    80001e0e:	6b8c                	ld	a1,16(a5)
    80001e10:	6f90                	ld	a2,24(a5)
    80001e12:	01073023          	sd	a6,0(a4)
    80001e16:	e708                	sd	a0,8(a4)
    80001e18:	eb0c                	sd	a1,16(a4)
    80001e1a:	ef10                	sd	a2,24(a4)
    80001e1c:	02078793          	addi	a5,a5,32
    80001e20:	02070713          	addi	a4,a4,32
    80001e24:	fed792e3          	bne	a5,a3,80001e08 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e28:	058a3783          	ld	a5,88(s4)
    80001e2c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e30:	0d0a8493          	addi	s1,s5,208
    80001e34:	0d0a0913          	addi	s2,s4,208
    80001e38:	150a8993          	addi	s3,s5,336
    80001e3c:	a00d                	j	80001e5e <fork+0xac>
    freeproc(np);
    80001e3e:	8552                	mv	a0,s4
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	d52080e7          	jalr	-686(ra) # 80001b92 <freeproc>
    release(&np->lock);
    80001e48:	8552                	mv	a0,s4
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e84080e7          	jalr	-380(ra) # 80000cce <release>
    return -1;
    80001e52:	597d                	li	s2,-1
    80001e54:	a059                	j	80001eda <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e56:	04a1                	addi	s1,s1,8
    80001e58:	0921                	addi	s2,s2,8
    80001e5a:	01348b63          	beq	s1,s3,80001e70 <fork+0xbe>
    if(p->ofile[i])
    80001e5e:	6088                	ld	a0,0(s1)
    80001e60:	d97d                	beqz	a0,80001e56 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e62:	00002097          	auipc	ra,0x2
    80001e66:	702080e7          	jalr	1794(ra) # 80004564 <filedup>
    80001e6a:	00a93023          	sd	a0,0(s2)
    80001e6e:	b7e5                	j	80001e56 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e70:	150ab503          	ld	a0,336(s5)
    80001e74:	00002097          	auipc	ra,0x2
    80001e78:	860080e7          	jalr	-1952(ra) # 800036d4 <idup>
    80001e7c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e80:	4641                	li	a2,16
    80001e82:	158a8593          	addi	a1,s5,344
    80001e86:	158a0513          	addi	a0,s4,344
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	fd6080e7          	jalr	-42(ra) # 80000e60 <safestrcpy>
  pid = np->pid;
    80001e92:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e96:	8552                	mv	a0,s4
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	e36080e7          	jalr	-458(ra) # 80000cce <release>
  acquire(&wait_lock);
    80001ea0:	0000f497          	auipc	s1,0xf
    80001ea4:	41848493          	addi	s1,s1,1048 # 800112b8 <wait_lock>
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	d70080e7          	jalr	-656(ra) # 80000c1a <acquire>
  np->parent = p;
    80001eb2:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	e16080e7          	jalr	-490(ra) # 80000cce <release>
  acquire(&np->lock);
    80001ec0:	8552                	mv	a0,s4
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	d58080e7          	jalr	-680(ra) # 80000c1a <acquire>
  np->state = RUNNABLE;
    80001eca:	478d                	li	a5,3
    80001ecc:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ed0:	8552                	mv	a0,s4
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	dfc080e7          	jalr	-516(ra) # 80000cce <release>
}
    80001eda:	854a                	mv	a0,s2
    80001edc:	70e2                	ld	ra,56(sp)
    80001ede:	7442                	ld	s0,48(sp)
    80001ee0:	74a2                	ld	s1,40(sp)
    80001ee2:	7902                	ld	s2,32(sp)
    80001ee4:	69e2                	ld	s3,24(sp)
    80001ee6:	6a42                	ld	s4,16(sp)
    80001ee8:	6aa2                	ld	s5,8(sp)
    80001eea:	6121                	addi	sp,sp,64
    80001eec:	8082                	ret
    return -1;
    80001eee:	597d                	li	s2,-1
    80001ef0:	b7ed                	j	80001eda <fork+0x128>

0000000080001ef2 <scheduler>:
{
    80001ef2:	7139                	addi	sp,sp,-64
    80001ef4:	fc06                	sd	ra,56(sp)
    80001ef6:	f822                	sd	s0,48(sp)
    80001ef8:	f426                	sd	s1,40(sp)
    80001efa:	f04a                	sd	s2,32(sp)
    80001efc:	ec4e                	sd	s3,24(sp)
    80001efe:	e852                	sd	s4,16(sp)
    80001f00:	e456                	sd	s5,8(sp)
    80001f02:	e05a                	sd	s6,0(sp)
    80001f04:	0080                	addi	s0,sp,64
    80001f06:	8792                	mv	a5,tp
  int id = r_tp();
    80001f08:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0a:	00779a93          	slli	s5,a5,0x7
    80001f0e:	0000f717          	auipc	a4,0xf
    80001f12:	39270713          	addi	a4,a4,914 # 800112a0 <pid_lock>
    80001f16:	9756                	add	a4,a4,s5
    80001f18:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f1c:	0000f717          	auipc	a4,0xf
    80001f20:	3bc70713          	addi	a4,a4,956 # 800112d8 <cpus+0x8>
    80001f24:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f26:	498d                	li	s3,3
        p->state = RUNNING;
    80001f28:	4b11                	li	s6,4
        c->proc = p;
    80001f2a:	079e                	slli	a5,a5,0x7
    80001f2c:	0000fa17          	auipc	s4,0xf
    80001f30:	374a0a13          	addi	s4,s4,884 # 800112a0 <pid_lock>
    80001f34:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f36:	00015917          	auipc	s2,0x15
    80001f3a:	19a90913          	addi	s2,s2,410 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f46:	10079073          	csrw	sstatus,a5
    80001f4a:	0000f497          	auipc	s1,0xf
    80001f4e:	78648493          	addi	s1,s1,1926 # 800116d0 <proc>
    80001f52:	a811                	j	80001f66 <scheduler+0x74>
      release(&p->lock);
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d78080e7          	jalr	-648(ra) # 80000cce <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5e:	16848493          	addi	s1,s1,360
    80001f62:	fd248ee3          	beq	s1,s2,80001f3e <scheduler+0x4c>
      acquire(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	cb2080e7          	jalr	-846(ra) # 80000c1a <acquire>
      if(p->state == RUNNABLE) {
    80001f70:	4c9c                	lw	a5,24(s1)
    80001f72:	ff3791e3          	bne	a5,s3,80001f54 <scheduler+0x62>
        p->state = RUNNING;
    80001f76:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f7a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f7e:	06048593          	addi	a1,s1,96
    80001f82:	8556                	mv	a0,s5
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	6de080e7          	jalr	1758(ra) # 80002662 <swtch>
        c->proc = 0;
    80001f8c:	020a3823          	sd	zero,48(s4)
    80001f90:	b7d1                	j	80001f54 <scheduler+0x62>

0000000080001f92 <sched>:
{
    80001f92:	7179                	addi	sp,sp,-48
    80001f94:	f406                	sd	ra,40(sp)
    80001f96:	f022                	sd	s0,32(sp)
    80001f98:	ec26                	sd	s1,24(sp)
    80001f9a:	e84a                	sd	s2,16(sp)
    80001f9c:	e44e                	sd	s3,8(sp)
    80001f9e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	a40080e7          	jalr	-1472(ra) # 800019e0 <myproc>
    80001fa8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	bf6080e7          	jalr	-1034(ra) # 80000ba0 <holding>
    80001fb2:	c93d                	beqz	a0,80002028 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	0000f717          	auipc	a4,0xf
    80001fbe:	2e670713          	addi	a4,a4,742 # 800112a0 <pid_lock>
    80001fc2:	97ba                	add	a5,a5,a4
    80001fc4:	0a87a703          	lw	a4,168(a5)
    80001fc8:	4785                	li	a5,1
    80001fca:	06f71763          	bne	a4,a5,80002038 <sched+0xa6>
  if(p->state == RUNNING)
    80001fce:	4c98                	lw	a4,24(s1)
    80001fd0:	4791                	li	a5,4
    80001fd2:	06f70b63          	beq	a4,a5,80002048 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fda:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fdc:	efb5                	bnez	a5,80002058 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fde:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe0:	0000f917          	auipc	s2,0xf
    80001fe4:	2c090913          	addi	s2,s2,704 # 800112a0 <pid_lock>
    80001fe8:	2781                	sext.w	a5,a5
    80001fea:	079e                	slli	a5,a5,0x7
    80001fec:	97ca                	add	a5,a5,s2
    80001fee:	0ac7a983          	lw	s3,172(a5)
    80001ff2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff4:	2781                	sext.w	a5,a5
    80001ff6:	079e                	slli	a5,a5,0x7
    80001ff8:	0000f597          	auipc	a1,0xf
    80001ffc:	2e058593          	addi	a1,a1,736 # 800112d8 <cpus+0x8>
    80002000:	95be                	add	a1,a1,a5
    80002002:	06048513          	addi	a0,s1,96
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	65c080e7          	jalr	1628(ra) # 80002662 <swtch>
    8000200e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	993e                	add	s2,s2,a5
    80002016:	0b392623          	sw	s3,172(s2)
}
    8000201a:	70a2                	ld	ra,40(sp)
    8000201c:	7402                	ld	s0,32(sp)
    8000201e:	64e2                	ld	s1,24(sp)
    80002020:	6942                	ld	s2,16(sp)
    80002022:	69a2                	ld	s3,8(sp)
    80002024:	6145                	addi	sp,sp,48
    80002026:	8082                	ret
    panic("sched p->lock");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	1f050513          	addi	a0,a0,496 # 80008218 <digits+0x1d8>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	50a080e7          	jalr	1290(ra) # 8000053a <panic>
    panic("sched locks");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	1f050513          	addi	a0,a0,496 # 80008228 <digits+0x1e8>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4fa080e7          	jalr	1274(ra) # 8000053a <panic>
    panic("sched running");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	1f050513          	addi	a0,a0,496 # 80008238 <digits+0x1f8>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4ea080e7          	jalr	1258(ra) # 8000053a <panic>
    panic("sched interruptible");
    80002058:	00006517          	auipc	a0,0x6
    8000205c:	1f050513          	addi	a0,a0,496 # 80008248 <digits+0x208>
    80002060:	ffffe097          	auipc	ra,0xffffe
    80002064:	4da080e7          	jalr	1242(ra) # 8000053a <panic>

0000000080002068 <yield>:
{
    80002068:	1101                	addi	sp,sp,-32
    8000206a:	ec06                	sd	ra,24(sp)
    8000206c:	e822                	sd	s0,16(sp)
    8000206e:	e426                	sd	s1,8(sp)
    80002070:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	96e080e7          	jalr	-1682(ra) # 800019e0 <myproc>
    8000207a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b9e080e7          	jalr	-1122(ra) # 80000c1a <acquire>
  p->state = RUNNABLE;
    80002084:	478d                	li	a5,3
    80002086:	cc9c                	sw	a5,24(s1)
  sched();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	f0a080e7          	jalr	-246(ra) # 80001f92 <sched>
  release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c3c080e7          	jalr	-964(ra) # 80000cce <release>
}
    8000209a:	60e2                	ld	ra,24(sp)
    8000209c:	6442                	ld	s0,16(sp)
    8000209e:	64a2                	ld	s1,8(sp)
    800020a0:	6105                	addi	sp,sp,32
    800020a2:	8082                	ret

00000000800020a4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020a4:	7179                	addi	sp,sp,-48
    800020a6:	f406                	sd	ra,40(sp)
    800020a8:	f022                	sd	s0,32(sp)
    800020aa:	ec26                	sd	s1,24(sp)
    800020ac:	e84a                	sd	s2,16(sp)
    800020ae:	e44e                	sd	s3,8(sp)
    800020b0:	1800                	addi	s0,sp,48
    800020b2:	89aa                	mv	s3,a0
    800020b4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	92a080e7          	jalr	-1750(ra) # 800019e0 <myproc>
    800020be:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b5a080e7          	jalr	-1190(ra) # 80000c1a <acquire>
  release(lk);
    800020c8:	854a                	mv	a0,s2
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	c04080e7          	jalr	-1020(ra) # 80000cce <release>

  // Go to sleep.
  p->chan = chan;
    800020d2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d6:	4789                	li	a5,2
    800020d8:	cc9c                	sw	a5,24(s1)

  sched();
    800020da:	00000097          	auipc	ra,0x0
    800020de:	eb8080e7          	jalr	-328(ra) # 80001f92 <sched>

  // Tidy up.
  p->chan = 0;
    800020e2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	be6080e7          	jalr	-1050(ra) # 80000cce <release>
  acquire(lk);
    800020f0:	854a                	mv	a0,s2
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	b28080e7          	jalr	-1240(ra) # 80000c1a <acquire>
}
    800020fa:	70a2                	ld	ra,40(sp)
    800020fc:	7402                	ld	s0,32(sp)
    800020fe:	64e2                	ld	s1,24(sp)
    80002100:	6942                	ld	s2,16(sp)
    80002102:	69a2                	ld	s3,8(sp)
    80002104:	6145                	addi	sp,sp,48
    80002106:	8082                	ret

0000000080002108 <wait>:
{
    80002108:	715d                	addi	sp,sp,-80
    8000210a:	e486                	sd	ra,72(sp)
    8000210c:	e0a2                	sd	s0,64(sp)
    8000210e:	fc26                	sd	s1,56(sp)
    80002110:	f84a                	sd	s2,48(sp)
    80002112:	f44e                	sd	s3,40(sp)
    80002114:	f052                	sd	s4,32(sp)
    80002116:	ec56                	sd	s5,24(sp)
    80002118:	e85a                	sd	s6,16(sp)
    8000211a:	e45e                	sd	s7,8(sp)
    8000211c:	e062                	sd	s8,0(sp)
    8000211e:	0880                	addi	s0,sp,80
    80002120:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	8be080e7          	jalr	-1858(ra) # 800019e0 <myproc>
    8000212a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000212c:	0000f517          	auipc	a0,0xf
    80002130:	18c50513          	addi	a0,a0,396 # 800112b8 <wait_lock>
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	ae6080e7          	jalr	-1306(ra) # 80000c1a <acquire>
    havekids = 0;
    8000213c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000213e:	4a15                	li	s4,5
        havekids = 1;
    80002140:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002142:	00015997          	auipc	s3,0x15
    80002146:	f8e98993          	addi	s3,s3,-114 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000214a:	0000fc17          	auipc	s8,0xf
    8000214e:	16ec0c13          	addi	s8,s8,366 # 800112b8 <wait_lock>
    havekids = 0;
    80002152:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002154:	0000f497          	auipc	s1,0xf
    80002158:	57c48493          	addi	s1,s1,1404 # 800116d0 <proc>
    8000215c:	a0bd                	j	800021ca <wait+0xc2>
          pid = np->pid;
    8000215e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002162:	000b0e63          	beqz	s6,8000217e <wait+0x76>
    80002166:	4691                	li	a3,4
    80002168:	02c48613          	addi	a2,s1,44
    8000216c:	85da                	mv	a1,s6
    8000216e:	05093503          	ld	a0,80(s2)
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	532080e7          	jalr	1330(ra) # 800016a4 <copyout>
    8000217a:	02054563          	bltz	a0,800021a4 <wait+0x9c>
          freeproc(np);
    8000217e:	8526                	mv	a0,s1
    80002180:	00000097          	auipc	ra,0x0
    80002184:	a12080e7          	jalr	-1518(ra) # 80001b92 <freeproc>
          release(&np->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b44080e7          	jalr	-1212(ra) # 80000cce <release>
          release(&wait_lock);
    80002192:	0000f517          	auipc	a0,0xf
    80002196:	12650513          	addi	a0,a0,294 # 800112b8 <wait_lock>
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	b34080e7          	jalr	-1228(ra) # 80000cce <release>
          return pid;
    800021a2:	a09d                	j	80002208 <wait+0x100>
            release(&np->lock);
    800021a4:	8526                	mv	a0,s1
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	b28080e7          	jalr	-1240(ra) # 80000cce <release>
            release(&wait_lock);
    800021ae:	0000f517          	auipc	a0,0xf
    800021b2:	10a50513          	addi	a0,a0,266 # 800112b8 <wait_lock>
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	b18080e7          	jalr	-1256(ra) # 80000cce <release>
            return -1;
    800021be:	59fd                	li	s3,-1
    800021c0:	a0a1                	j	80002208 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021c2:	16848493          	addi	s1,s1,360
    800021c6:	03348463          	beq	s1,s3,800021ee <wait+0xe6>
      if(np->parent == p){
    800021ca:	7c9c                	ld	a5,56(s1)
    800021cc:	ff279be3          	bne	a5,s2,800021c2 <wait+0xba>
        acquire(&np->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	a48080e7          	jalr	-1464(ra) # 80000c1a <acquire>
        if(np->state == ZOMBIE){
    800021da:	4c9c                	lw	a5,24(s1)
    800021dc:	f94781e3          	beq	a5,s4,8000215e <wait+0x56>
        release(&np->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	aec080e7          	jalr	-1300(ra) # 80000cce <release>
        havekids = 1;
    800021ea:	8756                	mv	a4,s5
    800021ec:	bfd9                	j	800021c2 <wait+0xba>
    if(!havekids || p->killed){
    800021ee:	c701                	beqz	a4,800021f6 <wait+0xee>
    800021f0:	02892783          	lw	a5,40(s2)
    800021f4:	c79d                	beqz	a5,80002222 <wait+0x11a>
      release(&wait_lock);
    800021f6:	0000f517          	auipc	a0,0xf
    800021fa:	0c250513          	addi	a0,a0,194 # 800112b8 <wait_lock>
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	ad0080e7          	jalr	-1328(ra) # 80000cce <release>
      return -1;
    80002206:	59fd                	li	s3,-1
}
    80002208:	854e                	mv	a0,s3
    8000220a:	60a6                	ld	ra,72(sp)
    8000220c:	6406                	ld	s0,64(sp)
    8000220e:	74e2                	ld	s1,56(sp)
    80002210:	7942                	ld	s2,48(sp)
    80002212:	79a2                	ld	s3,40(sp)
    80002214:	7a02                	ld	s4,32(sp)
    80002216:	6ae2                	ld	s5,24(sp)
    80002218:	6b42                	ld	s6,16(sp)
    8000221a:	6ba2                	ld	s7,8(sp)
    8000221c:	6c02                	ld	s8,0(sp)
    8000221e:	6161                	addi	sp,sp,80
    80002220:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002222:	85e2                	mv	a1,s8
    80002224:	854a                	mv	a0,s2
    80002226:	00000097          	auipc	ra,0x0
    8000222a:	e7e080e7          	jalr	-386(ra) # 800020a4 <sleep>
    havekids = 0;
    8000222e:	b715                	j	80002152 <wait+0x4a>

0000000080002230 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002230:	7139                	addi	sp,sp,-64
    80002232:	fc06                	sd	ra,56(sp)
    80002234:	f822                	sd	s0,48(sp)
    80002236:	f426                	sd	s1,40(sp)
    80002238:	f04a                	sd	s2,32(sp)
    8000223a:	ec4e                	sd	s3,24(sp)
    8000223c:	e852                	sd	s4,16(sp)
    8000223e:	e456                	sd	s5,8(sp)
    80002240:	0080                	addi	s0,sp,64
    80002242:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002244:	0000f497          	auipc	s1,0xf
    80002248:	48c48493          	addi	s1,s1,1164 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000224c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000224e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002250:	00015917          	auipc	s2,0x15
    80002254:	e8090913          	addi	s2,s2,-384 # 800170d0 <tickslock>
    80002258:	a811                	j	8000226c <wakeup+0x3c>
      }
      release(&p->lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	a72080e7          	jalr	-1422(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002264:	16848493          	addi	s1,s1,360
    80002268:	03248663          	beq	s1,s2,80002294 <wakeup+0x64>
    if(p != myproc()){
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	774080e7          	jalr	1908(ra) # 800019e0 <myproc>
    80002274:	fea488e3          	beq	s1,a0,80002264 <wakeup+0x34>
      acquire(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	9a0080e7          	jalr	-1632(ra) # 80000c1a <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002282:	4c9c                	lw	a5,24(s1)
    80002284:	fd379be3          	bne	a5,s3,8000225a <wakeup+0x2a>
    80002288:	709c                	ld	a5,32(s1)
    8000228a:	fd4798e3          	bne	a5,s4,8000225a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000228e:	0154ac23          	sw	s5,24(s1)
    80002292:	b7e1                	j	8000225a <wakeup+0x2a>
    }
  }
}
    80002294:	70e2                	ld	ra,56(sp)
    80002296:	7442                	ld	s0,48(sp)
    80002298:	74a2                	ld	s1,40(sp)
    8000229a:	7902                	ld	s2,32(sp)
    8000229c:	69e2                	ld	s3,24(sp)
    8000229e:	6a42                	ld	s4,16(sp)
    800022a0:	6aa2                	ld	s5,8(sp)
    800022a2:	6121                	addi	sp,sp,64
    800022a4:	8082                	ret

00000000800022a6 <reparent>:
{
    800022a6:	7179                	addi	sp,sp,-48
    800022a8:	f406                	sd	ra,40(sp)
    800022aa:	f022                	sd	s0,32(sp)
    800022ac:	ec26                	sd	s1,24(sp)
    800022ae:	e84a                	sd	s2,16(sp)
    800022b0:	e44e                	sd	s3,8(sp)
    800022b2:	e052                	sd	s4,0(sp)
    800022b4:	1800                	addi	s0,sp,48
    800022b6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022b8:	0000f497          	auipc	s1,0xf
    800022bc:	41848493          	addi	s1,s1,1048 # 800116d0 <proc>
      pp->parent = initproc;
    800022c0:	00007a17          	auipc	s4,0x7
    800022c4:	d68a0a13          	addi	s4,s4,-664 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c8:	00015997          	auipc	s3,0x15
    800022cc:	e0898993          	addi	s3,s3,-504 # 800170d0 <tickslock>
    800022d0:	a029                	j	800022da <reparent+0x34>
    800022d2:	16848493          	addi	s1,s1,360
    800022d6:	01348d63          	beq	s1,s3,800022f0 <reparent+0x4a>
    if(pp->parent == p){
    800022da:	7c9c                	ld	a5,56(s1)
    800022dc:	ff279be3          	bne	a5,s2,800022d2 <reparent+0x2c>
      pp->parent = initproc;
    800022e0:	000a3503          	ld	a0,0(s4)
    800022e4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022e6:	00000097          	auipc	ra,0x0
    800022ea:	f4a080e7          	jalr	-182(ra) # 80002230 <wakeup>
    800022ee:	b7d5                	j	800022d2 <reparent+0x2c>
}
    800022f0:	70a2                	ld	ra,40(sp)
    800022f2:	7402                	ld	s0,32(sp)
    800022f4:	64e2                	ld	s1,24(sp)
    800022f6:	6942                	ld	s2,16(sp)
    800022f8:	69a2                	ld	s3,8(sp)
    800022fa:	6a02                	ld	s4,0(sp)
    800022fc:	6145                	addi	sp,sp,48
    800022fe:	8082                	ret

0000000080002300 <exit>:
{
    80002300:	7179                	addi	sp,sp,-48
    80002302:	f406                	sd	ra,40(sp)
    80002304:	f022                	sd	s0,32(sp)
    80002306:	ec26                	sd	s1,24(sp)
    80002308:	e84a                	sd	s2,16(sp)
    8000230a:	e44e                	sd	s3,8(sp)
    8000230c:	e052                	sd	s4,0(sp)
    8000230e:	1800                	addi	s0,sp,48
    80002310:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	6ce080e7          	jalr	1742(ra) # 800019e0 <myproc>
    8000231a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000231c:	00007797          	auipc	a5,0x7
    80002320:	d0c7b783          	ld	a5,-756(a5) # 80009028 <initproc>
    80002324:	0d050493          	addi	s1,a0,208
    80002328:	15050913          	addi	s2,a0,336
    8000232c:	02a79363          	bne	a5,a0,80002352 <exit+0x52>
    panic("init exiting");
    80002330:	00006517          	auipc	a0,0x6
    80002334:	f3050513          	addi	a0,a0,-208 # 80008260 <digits+0x220>
    80002338:	ffffe097          	auipc	ra,0xffffe
    8000233c:	202080e7          	jalr	514(ra) # 8000053a <panic>
      fileclose(f);
    80002340:	00002097          	auipc	ra,0x2
    80002344:	276080e7          	jalr	630(ra) # 800045b6 <fileclose>
      p->ofile[fd] = 0;
    80002348:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000234c:	04a1                	addi	s1,s1,8
    8000234e:	01248563          	beq	s1,s2,80002358 <exit+0x58>
    if(p->ofile[fd]){
    80002352:	6088                	ld	a0,0(s1)
    80002354:	f575                	bnez	a0,80002340 <exit+0x40>
    80002356:	bfdd                	j	8000234c <exit+0x4c>
  begin_op();
    80002358:	00002097          	auipc	ra,0x2
    8000235c:	d96080e7          	jalr	-618(ra) # 800040ee <begin_op>
  iput(p->cwd);
    80002360:	1509b503          	ld	a0,336(s3)
    80002364:	00001097          	auipc	ra,0x1
    80002368:	568080e7          	jalr	1384(ra) # 800038cc <iput>
  end_op();
    8000236c:	00002097          	auipc	ra,0x2
    80002370:	e00080e7          	jalr	-512(ra) # 8000416c <end_op>
  p->cwd = 0;
    80002374:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002378:	0000f497          	auipc	s1,0xf
    8000237c:	f4048493          	addi	s1,s1,-192 # 800112b8 <wait_lock>
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	898080e7          	jalr	-1896(ra) # 80000c1a <acquire>
  reparent(p);
    8000238a:	854e                	mv	a0,s3
    8000238c:	00000097          	auipc	ra,0x0
    80002390:	f1a080e7          	jalr	-230(ra) # 800022a6 <reparent>
  wakeup(p->parent);
    80002394:	0389b503          	ld	a0,56(s3)
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	e98080e7          	jalr	-360(ra) # 80002230 <wakeup>
  acquire(&p->lock);
    800023a0:	854e                	mv	a0,s3
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	878080e7          	jalr	-1928(ra) # 80000c1a <acquire>
  p->xstate = status;
    800023aa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023ae:	4795                	li	a5,5
    800023b0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	918080e7          	jalr	-1768(ra) # 80000cce <release>
  sched();
    800023be:	00000097          	auipc	ra,0x0
    800023c2:	bd4080e7          	jalr	-1068(ra) # 80001f92 <sched>
  panic("zombie exit");
    800023c6:	00006517          	auipc	a0,0x6
    800023ca:	eaa50513          	addi	a0,a0,-342 # 80008270 <digits+0x230>
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	16c080e7          	jalr	364(ra) # 8000053a <panic>

00000000800023d6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023d6:	7179                	addi	sp,sp,-48
    800023d8:	f406                	sd	ra,40(sp)
    800023da:	f022                	sd	s0,32(sp)
    800023dc:	ec26                	sd	s1,24(sp)
    800023de:	e84a                	sd	s2,16(sp)
    800023e0:	e44e                	sd	s3,8(sp)
    800023e2:	1800                	addi	s0,sp,48
    800023e4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023e6:	0000f497          	auipc	s1,0xf
    800023ea:	2ea48493          	addi	s1,s1,746 # 800116d0 <proc>
    800023ee:	00015997          	auipc	s3,0x15
    800023f2:	ce298993          	addi	s3,s3,-798 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	822080e7          	jalr	-2014(ra) # 80000c1a <acquire>
    if(p->pid == pid){
    80002400:	589c                	lw	a5,48(s1)
    80002402:	01278d63          	beq	a5,s2,8000241c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	8c6080e7          	jalr	-1850(ra) # 80000cce <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002410:	16848493          	addi	s1,s1,360
    80002414:	ff3491e3          	bne	s1,s3,800023f6 <kill+0x20>
  }
  return -1;
    80002418:	557d                	li	a0,-1
    8000241a:	a829                	j	80002434 <kill+0x5e>
      p->killed = 1;
    8000241c:	4785                	li	a5,1
    8000241e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002420:	4c98                	lw	a4,24(s1)
    80002422:	4789                	li	a5,2
    80002424:	00f70f63          	beq	a4,a5,80002442 <kill+0x6c>
      release(&p->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	8a4080e7          	jalr	-1884(ra) # 80000cce <release>
      return 0;
    80002432:	4501                	li	a0,0
}
    80002434:	70a2                	ld	ra,40(sp)
    80002436:	7402                	ld	s0,32(sp)
    80002438:	64e2                	ld	s1,24(sp)
    8000243a:	6942                	ld	s2,16(sp)
    8000243c:	69a2                	ld	s3,8(sp)
    8000243e:	6145                	addi	sp,sp,48
    80002440:	8082                	ret
        p->state = RUNNABLE;
    80002442:	478d                	li	a5,3
    80002444:	cc9c                	sw	a5,24(s1)
    80002446:	b7cd                	j	80002428 <kill+0x52>

0000000080002448 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002448:	7179                	addi	sp,sp,-48
    8000244a:	f406                	sd	ra,40(sp)
    8000244c:	f022                	sd	s0,32(sp)
    8000244e:	ec26                	sd	s1,24(sp)
    80002450:	e84a                	sd	s2,16(sp)
    80002452:	e44e                	sd	s3,8(sp)
    80002454:	e052                	sd	s4,0(sp)
    80002456:	1800                	addi	s0,sp,48
    80002458:	84aa                	mv	s1,a0
    8000245a:	892e                	mv	s2,a1
    8000245c:	89b2                	mv	s3,a2
    8000245e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	580080e7          	jalr	1408(ra) # 800019e0 <myproc>
  if(user_dst){
    80002468:	c08d                	beqz	s1,8000248a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000246a:	86d2                	mv	a3,s4
    8000246c:	864e                	mv	a2,s3
    8000246e:	85ca                	mv	a1,s2
    80002470:	6928                	ld	a0,80(a0)
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	232080e7          	jalr	562(ra) # 800016a4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000247a:	70a2                	ld	ra,40(sp)
    8000247c:	7402                	ld	s0,32(sp)
    8000247e:	64e2                	ld	s1,24(sp)
    80002480:	6942                	ld	s2,16(sp)
    80002482:	69a2                	ld	s3,8(sp)
    80002484:	6a02                	ld	s4,0(sp)
    80002486:	6145                	addi	sp,sp,48
    80002488:	8082                	ret
    memmove((char *)dst, src, len);
    8000248a:	000a061b          	sext.w	a2,s4
    8000248e:	85ce                	mv	a1,s3
    80002490:	854a                	mv	a0,s2
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	8e0080e7          	jalr	-1824(ra) # 80000d72 <memmove>
    return 0;
    8000249a:	8526                	mv	a0,s1
    8000249c:	bff9                	j	8000247a <either_copyout+0x32>

000000008000249e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000249e:	7179                	addi	sp,sp,-48
    800024a0:	f406                	sd	ra,40(sp)
    800024a2:	f022                	sd	s0,32(sp)
    800024a4:	ec26                	sd	s1,24(sp)
    800024a6:	e84a                	sd	s2,16(sp)
    800024a8:	e44e                	sd	s3,8(sp)
    800024aa:	e052                	sd	s4,0(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	892a                	mv	s2,a0
    800024b0:	84ae                	mv	s1,a1
    800024b2:	89b2                	mv	s3,a2
    800024b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	52a080e7          	jalr	1322(ra) # 800019e0 <myproc>
  if(user_src){
    800024be:	c08d                	beqz	s1,800024e0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024c0:	86d2                	mv	a3,s4
    800024c2:	864e                	mv	a2,s3
    800024c4:	85ca                	mv	a1,s2
    800024c6:	6928                	ld	a0,80(a0)
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	268080e7          	jalr	616(ra) # 80001730 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024d0:	70a2                	ld	ra,40(sp)
    800024d2:	7402                	ld	s0,32(sp)
    800024d4:	64e2                	ld	s1,24(sp)
    800024d6:	6942                	ld	s2,16(sp)
    800024d8:	69a2                	ld	s3,8(sp)
    800024da:	6a02                	ld	s4,0(sp)
    800024dc:	6145                	addi	sp,sp,48
    800024de:	8082                	ret
    memmove(dst, (char*)src, len);
    800024e0:	000a061b          	sext.w	a2,s4
    800024e4:	85ce                	mv	a1,s3
    800024e6:	854a                	mv	a0,s2
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	88a080e7          	jalr	-1910(ra) # 80000d72 <memmove>
    return 0;
    800024f0:	8526                	mv	a0,s1
    800024f2:	bff9                	j	800024d0 <either_copyin+0x32>

00000000800024f4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024f4:	715d                	addi	sp,sp,-80
    800024f6:	e486                	sd	ra,72(sp)
    800024f8:	e0a2                	sd	s0,64(sp)
    800024fa:	fc26                	sd	s1,56(sp)
    800024fc:	f84a                	sd	s2,48(sp)
    800024fe:	f44e                	sd	s3,40(sp)
    80002500:	f052                	sd	s4,32(sp)
    80002502:	ec56                	sd	s5,24(sp)
    80002504:	e85a                	sd	s6,16(sp)
    80002506:	e45e                	sd	s7,8(sp)
    80002508:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000250a:	00006517          	auipc	a0,0x6
    8000250e:	bbe50513          	addi	a0,a0,-1090 # 800080c8 <digits+0x88>
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	072080e7          	jalr	114(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251a:	0000f497          	auipc	s1,0xf
    8000251e:	30e48493          	addi	s1,s1,782 # 80011828 <proc+0x158>
    80002522:	00015917          	auipc	s2,0x15
    80002526:	d0690913          	addi	s2,s2,-762 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000252c:	00006997          	auipc	s3,0x6
    80002530:	d5498993          	addi	s3,s3,-684 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002534:	00006a97          	auipc	s5,0x6
    80002538:	d54a8a93          	addi	s5,s5,-684 # 80008288 <digits+0x248>
    printf("\n");
    8000253c:	00006a17          	auipc	s4,0x6
    80002540:	b8ca0a13          	addi	s4,s4,-1140 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002544:	00006b97          	auipc	s7,0x6
    80002548:	d7cb8b93          	addi	s7,s7,-644 # 800082c0 <states.0>
    8000254c:	a00d                	j	8000256e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000254e:	ed86a583          	lw	a1,-296(a3)
    80002552:	8556                	mv	a0,s5
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	030080e7          	jalr	48(ra) # 80000584 <printf>
    printf("\n");
    8000255c:	8552                	mv	a0,s4
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	026080e7          	jalr	38(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002566:	16848493          	addi	s1,s1,360
    8000256a:	03248263          	beq	s1,s2,8000258e <procdump+0x9a>
    if(p->state == UNUSED)
    8000256e:	86a6                	mv	a3,s1
    80002570:	ec04a783          	lw	a5,-320(s1)
    80002574:	dbed                	beqz	a5,80002566 <procdump+0x72>
      state = "???";
    80002576:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002578:	fcfb6be3          	bltu	s6,a5,8000254e <procdump+0x5a>
    8000257c:	02079713          	slli	a4,a5,0x20
    80002580:	01d75793          	srli	a5,a4,0x1d
    80002584:	97de                	add	a5,a5,s7
    80002586:	6390                	ld	a2,0(a5)
    80002588:	f279                	bnez	a2,8000254e <procdump+0x5a>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    8000258c:	b7c9                	j	8000254e <procdump+0x5a>
  }
}
    8000258e:	60a6                	ld	ra,72(sp)
    80002590:	6406                	ld	s0,64(sp)
    80002592:	74e2                	ld	s1,56(sp)
    80002594:	7942                	ld	s2,48(sp)
    80002596:	79a2                	ld	s3,40(sp)
    80002598:	7a02                	ld	s4,32(sp)
    8000259a:	6ae2                	ld	s5,24(sp)
    8000259c:	6b42                	ld	s6,16(sp)
    8000259e:	6ba2                	ld	s7,8(sp)
    800025a0:	6161                	addi	sp,sp,80
    800025a2:	8082                	ret

00000000800025a4 <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    800025a4:	7119                	addi	sp,sp,-128
    800025a6:	fc86                	sd	ra,120(sp)
    800025a8:	f8a2                	sd	s0,112(sp)
    800025aa:	f4a6                	sd	s1,104(sp)
    800025ac:	f0ca                	sd	s2,96(sp)
    800025ae:	ecce                	sd	s3,88(sp)
    800025b0:	e8d2                	sd	s4,80(sp)
    800025b2:	e4d6                	sd	s5,72(sp)
    800025b4:	e0da                	sd	s6,64(sp)
    800025b6:	fc5e                	sd	s7,56(sp)
    800025b8:	0100                	addi	s0,sp,128
    800025ba:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    800025bc:	fffff097          	auipc	ra,0xfffff
    800025c0:	424080e7          	jalr	1060(ra) # 800019e0 <myproc>
    800025c4:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    800025c6:	0000f917          	auipc	s2,0xf
    800025ca:	26290913          	addi	s2,s2,610 # 80011828 <proc+0x158>
    800025ce:	00015a17          	auipc	s4,0x15
    800025d2:	c5aa0a13          	addi	s4,s4,-934 # 80017228 <bcache+0x140>
  int nprocs = 0;
    800025d6:	4a81                	li	s5,0
    procinfo.state = p->state;
    procinfo.size = p->sz;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    800025d8:	4b81                	li	s7,0
    800025da:	fac40493          	addi	s1,s0,-84
    800025de:	a089                	j	80002620 <procinfo+0x7c>
    800025e0:	f8f42c23          	sw	a5,-104(s0)
    for (int i=0; i<16; i++)
    800025e4:	f9c40793          	addi	a5,s0,-100
      procinfo.ppid = 0;
    800025e8:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    800025ea:	00074683          	lbu	a3,0(a4)
    800025ee:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    800025f2:	0705                	addi	a4,a4,1
    800025f4:	0785                	addi	a5,a5,1
    800025f6:	fe979ae3          	bne	a5,s1,800025ea <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    800025fa:	02800693          	li	a3,40
    800025fe:	f8840613          	addi	a2,s0,-120
    80002602:	85ce                	mv	a1,s3
    80002604:	050b3503          	ld	a0,80(s6)
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	09c080e7          	jalr	156(ra) # 800016a4 <copyout>
    80002610:	02054c63          	bltz	a0,80002648 <procinfo+0xa4>
      return -1;
    addr += sizeof(procinfo);
    80002614:	02898993          	addi	s3,s3,40
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002618:	16890913          	addi	s2,s2,360
    8000261c:	03490763          	beq	s2,s4,8000264a <procinfo+0xa6>
    if(p->state == UNUSED)
    80002620:	ec092783          	lw	a5,-320(s2)
    80002624:	dbf5                	beqz	a5,80002618 <procinfo+0x74>
    nprocs++;
    80002626:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    80002628:	ed892703          	lw	a4,-296(s2)
    8000262c:	f8e42423          	sw	a4,-120(s0)
    procinfo.state = p->state;
    80002630:	f8f42623          	sw	a5,-116(s0)
    procinfo.size = p->sz;
    80002634:	ef093783          	ld	a5,-272(s2)
    80002638:	f8f43823          	sd	a5,-112(s0)
    if (p->parent)
    8000263c:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    80002640:	87de                	mv	a5,s7
    if (p->parent)
    80002642:	df59                	beqz	a4,800025e0 <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    80002644:	5b1c                	lw	a5,48(a4)
    80002646:	bf69                	j	800025e0 <procinfo+0x3c>
      return -1;
    80002648:	5afd                	li	s5,-1
  }
  return nprocs;
}
    8000264a:	8556                	mv	a0,s5
    8000264c:	70e6                	ld	ra,120(sp)
    8000264e:	7446                	ld	s0,112(sp)
    80002650:	74a6                	ld	s1,104(sp)
    80002652:	7906                	ld	s2,96(sp)
    80002654:	69e6                	ld	s3,88(sp)
    80002656:	6a46                	ld	s4,80(sp)
    80002658:	6aa6                	ld	s5,72(sp)
    8000265a:	6b06                	ld	s6,64(sp)
    8000265c:	7be2                	ld	s7,56(sp)
    8000265e:	6109                	addi	sp,sp,128
    80002660:	8082                	ret

0000000080002662 <swtch>:
    80002662:	00153023          	sd	ra,0(a0)
    80002666:	00253423          	sd	sp,8(a0)
    8000266a:	e900                	sd	s0,16(a0)
    8000266c:	ed04                	sd	s1,24(a0)
    8000266e:	03253023          	sd	s2,32(a0)
    80002672:	03353423          	sd	s3,40(a0)
    80002676:	03453823          	sd	s4,48(a0)
    8000267a:	03553c23          	sd	s5,56(a0)
    8000267e:	05653023          	sd	s6,64(a0)
    80002682:	05753423          	sd	s7,72(a0)
    80002686:	05853823          	sd	s8,80(a0)
    8000268a:	05953c23          	sd	s9,88(a0)
    8000268e:	07a53023          	sd	s10,96(a0)
    80002692:	07b53423          	sd	s11,104(a0)
    80002696:	0005b083          	ld	ra,0(a1)
    8000269a:	0085b103          	ld	sp,8(a1)
    8000269e:	6980                	ld	s0,16(a1)
    800026a0:	6d84                	ld	s1,24(a1)
    800026a2:	0205b903          	ld	s2,32(a1)
    800026a6:	0285b983          	ld	s3,40(a1)
    800026aa:	0305ba03          	ld	s4,48(a1)
    800026ae:	0385ba83          	ld	s5,56(a1)
    800026b2:	0405bb03          	ld	s6,64(a1)
    800026b6:	0485bb83          	ld	s7,72(a1)
    800026ba:	0505bc03          	ld	s8,80(a1)
    800026be:	0585bc83          	ld	s9,88(a1)
    800026c2:	0605bd03          	ld	s10,96(a1)
    800026c6:	0685bd83          	ld	s11,104(a1)
    800026ca:	8082                	ret

00000000800026cc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026cc:	1141                	addi	sp,sp,-16
    800026ce:	e406                	sd	ra,8(sp)
    800026d0:	e022                	sd	s0,0(sp)
    800026d2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d4:	00006597          	auipc	a1,0x6
    800026d8:	c1c58593          	addi	a1,a1,-996 # 800082f0 <states.0+0x30>
    800026dc:	00015517          	auipc	a0,0x15
    800026e0:	9f450513          	addi	a0,a0,-1548 # 800170d0 <tickslock>
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	4a6080e7          	jalr	1190(ra) # 80000b8a <initlock>
}
    800026ec:	60a2                	ld	ra,8(sp)
    800026ee:	6402                	ld	s0,0(sp)
    800026f0:	0141                	addi	sp,sp,16
    800026f2:	8082                	ret

00000000800026f4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e422                	sd	s0,8(sp)
    800026f8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fa:	00003797          	auipc	a5,0x3
    800026fe:	4e678793          	addi	a5,a5,1254 # 80005be0 <kernelvec>
    80002702:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002706:	6422                	ld	s0,8(sp)
    80002708:	0141                	addi	sp,sp,16
    8000270a:	8082                	ret

000000008000270c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000270c:	1141                	addi	sp,sp,-16
    8000270e:	e406                	sd	ra,8(sp)
    80002710:	e022                	sd	s0,0(sp)
    80002712:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	2cc080e7          	jalr	716(ra) # 800019e0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000271c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002720:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002722:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002726:	00005697          	auipc	a3,0x5
    8000272a:	8da68693          	addi	a3,a3,-1830 # 80007000 <_trampoline>
    8000272e:	00005717          	auipc	a4,0x5
    80002732:	8d270713          	addi	a4,a4,-1838 # 80007000 <_trampoline>
    80002736:	8f15                	sub	a4,a4,a3
    80002738:	040007b7          	lui	a5,0x4000
    8000273c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273e:	07b2                	slli	a5,a5,0xc
    80002740:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002742:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002746:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002748:	18002673          	csrr	a2,satp
    8000274c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274e:	6d30                	ld	a2,88(a0)
    80002750:	6138                	ld	a4,64(a0)
    80002752:	6585                	lui	a1,0x1
    80002754:	972e                	add	a4,a4,a1
    80002756:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002758:	6d38                	ld	a4,88(a0)
    8000275a:	00000617          	auipc	a2,0x0
    8000275e:	13860613          	addi	a2,a2,312 # 80002892 <usertrap>
    80002762:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002764:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002766:	8612                	mv	a2,tp
    80002768:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002772:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002776:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000277c:	6f18                	ld	a4,24(a4)
    8000277e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002782:	692c                	ld	a1,80(a0)
    80002784:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002786:	00005717          	auipc	a4,0x5
    8000278a:	90a70713          	addi	a4,a4,-1782 # 80007090 <userret>
    8000278e:	8f15                	sub	a4,a4,a3
    80002790:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002792:	577d                	li	a4,-1
    80002794:	177e                	slli	a4,a4,0x3f
    80002796:	8dd9                	or	a1,a1,a4
    80002798:	02000537          	lui	a0,0x2000
    8000279c:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000279e:	0536                	slli	a0,a0,0xd
    800027a0:	9782                	jalr	a5
}
    800027a2:	60a2                	ld	ra,8(sp)
    800027a4:	6402                	ld	s0,0(sp)
    800027a6:	0141                	addi	sp,sp,16
    800027a8:	8082                	ret

00000000800027aa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027aa:	1101                	addi	sp,sp,-32
    800027ac:	ec06                	sd	ra,24(sp)
    800027ae:	e822                	sd	s0,16(sp)
    800027b0:	e426                	sd	s1,8(sp)
    800027b2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b4:	00015497          	auipc	s1,0x15
    800027b8:	91c48493          	addi	s1,s1,-1764 # 800170d0 <tickslock>
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	45c080e7          	jalr	1116(ra) # 80000c1a <acquire>
  ticks++;
    800027c6:	00007517          	auipc	a0,0x7
    800027ca:	86a50513          	addi	a0,a0,-1942 # 80009030 <ticks>
    800027ce:	411c                	lw	a5,0(a0)
    800027d0:	2785                	addiw	a5,a5,1
    800027d2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	a5c080e7          	jalr	-1444(ra) # 80002230 <wakeup>
  release(&tickslock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	4f0080e7          	jalr	1264(ra) # 80000cce <release>
}
    800027e6:	60e2                	ld	ra,24(sp)
    800027e8:	6442                	ld	s0,16(sp)
    800027ea:	64a2                	ld	s1,8(sp)
    800027ec:	6105                	addi	sp,sp,32
    800027ee:	8082                	ret

00000000800027f0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027f0:	1101                	addi	sp,sp,-32
    800027f2:	ec06                	sd	ra,24(sp)
    800027f4:	e822                	sd	s0,16(sp)
    800027f6:	e426                	sd	s1,8(sp)
    800027f8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027fa:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027fe:	00074d63          	bltz	a4,80002818 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002802:	57fd                	li	a5,-1
    80002804:	17fe                	slli	a5,a5,0x3f
    80002806:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002808:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280a:	06f70363          	beq	a4,a5,80002870 <devintr+0x80>
  }
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret
     (scause & 0xff) == 9){
    80002818:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000281c:	46a5                	li	a3,9
    8000281e:	fed792e3          	bne	a5,a3,80002802 <devintr+0x12>
    int irq = plic_claim();
    80002822:	00003097          	auipc	ra,0x3
    80002826:	4c6080e7          	jalr	1222(ra) # 80005ce8 <plic_claim>
    8000282a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000282c:	47a9                	li	a5,10
    8000282e:	02f50763          	beq	a0,a5,8000285c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002832:	4785                	li	a5,1
    80002834:	02f50963          	beq	a0,a5,80002866 <devintr+0x76>
    return 1;
    80002838:	4505                	li	a0,1
    } else if(irq){
    8000283a:	d8f1                	beqz	s1,8000280e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000283c:	85a6                	mv	a1,s1
    8000283e:	00006517          	auipc	a0,0x6
    80002842:	aba50513          	addi	a0,a0,-1350 # 800082f8 <states.0+0x38>
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	d3e080e7          	jalr	-706(ra) # 80000584 <printf>
      plic_complete(irq);
    8000284e:	8526                	mv	a0,s1
    80002850:	00003097          	auipc	ra,0x3
    80002854:	4bc080e7          	jalr	1212(ra) # 80005d0c <plic_complete>
    return 1;
    80002858:	4505                	li	a0,1
    8000285a:	bf55                	j	8000280e <devintr+0x1e>
      uartintr();
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	136080e7          	jalr	310(ra) # 80000992 <uartintr>
    80002864:	b7ed                	j	8000284e <devintr+0x5e>
      virtio_disk_intr();
    80002866:	00004097          	auipc	ra,0x4
    8000286a:	932080e7          	jalr	-1742(ra) # 80006198 <virtio_disk_intr>
    8000286e:	b7c5                	j	8000284e <devintr+0x5e>
    if(cpuid() == 0){
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	144080e7          	jalr	324(ra) # 800019b4 <cpuid>
    80002878:	c901                	beqz	a0,80002888 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000287a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000287e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002880:	14479073          	csrw	sip,a5
    return 2;
    80002884:	4509                	li	a0,2
    80002886:	b761                	j	8000280e <devintr+0x1e>
      clockintr();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	f22080e7          	jalr	-222(ra) # 800027aa <clockintr>
    80002890:	b7ed                	j	8000287a <devintr+0x8a>

0000000080002892 <usertrap>:
{
    80002892:	1101                	addi	sp,sp,-32
    80002894:	ec06                	sd	ra,24(sp)
    80002896:	e822                	sd	s0,16(sp)
    80002898:	e426                	sd	s1,8(sp)
    8000289a:	e04a                	sd	s2,0(sp)
    8000289c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a2:	1007f793          	andi	a5,a5,256
    800028a6:	e3ad                	bnez	a5,80002908 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a8:	00003797          	auipc	a5,0x3
    800028ac:	33878793          	addi	a5,a5,824 # 80005be0 <kernelvec>
    800028b0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	12c080e7          	jalr	300(ra) # 800019e0 <myproc>
    800028bc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028be:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c0:	14102773          	csrr	a4,sepc
    800028c4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ca:	47a1                	li	a5,8
    800028cc:	04f71c63          	bne	a4,a5,80002924 <usertrap+0x92>
    if(p->killed)
    800028d0:	551c                	lw	a5,40(a0)
    800028d2:	e3b9                	bnez	a5,80002918 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028d4:	6cb8                	ld	a4,88(s1)
    800028d6:	6f1c                	ld	a5,24(a4)
    800028d8:	0791                	addi	a5,a5,4
    800028da:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e4:	10079073          	csrw	sstatus,a5
    syscall();
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	2e0080e7          	jalr	736(ra) # 80002bc8 <syscall>
  if(p->killed)
    800028f0:	549c                	lw	a5,40(s1)
    800028f2:	ebc1                	bnez	a5,80002982 <usertrap+0xf0>
  usertrapret();
    800028f4:	00000097          	auipc	ra,0x0
    800028f8:	e18080e7          	jalr	-488(ra) # 8000270c <usertrapret>
}
    800028fc:	60e2                	ld	ra,24(sp)
    800028fe:	6442                	ld	s0,16(sp)
    80002900:	64a2                	ld	s1,8(sp)
    80002902:	6902                	ld	s2,0(sp)
    80002904:	6105                	addi	sp,sp,32
    80002906:	8082                	ret
    panic("usertrap: not from user mode");
    80002908:	00006517          	auipc	a0,0x6
    8000290c:	a1050513          	addi	a0,a0,-1520 # 80008318 <states.0+0x58>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c2a080e7          	jalr	-982(ra) # 8000053a <panic>
      exit(-1);
    80002918:	557d                	li	a0,-1
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	9e6080e7          	jalr	-1562(ra) # 80002300 <exit>
    80002922:	bf4d                	j	800028d4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002924:	00000097          	auipc	ra,0x0
    80002928:	ecc080e7          	jalr	-308(ra) # 800027f0 <devintr>
    8000292c:	892a                	mv	s2,a0
    8000292e:	c501                	beqz	a0,80002936 <usertrap+0xa4>
  if(p->killed)
    80002930:	549c                	lw	a5,40(s1)
    80002932:	c3a1                	beqz	a5,80002972 <usertrap+0xe0>
    80002934:	a815                	j	80002968 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002936:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000293a:	5890                	lw	a2,48(s1)
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	9fc50513          	addi	a0,a0,-1540 # 80008338 <states.0+0x78>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c40080e7          	jalr	-960(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000294c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002950:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002954:	00006517          	auipc	a0,0x6
    80002958:	a1450513          	addi	a0,a0,-1516 # 80008368 <states.0+0xa8>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	c28080e7          	jalr	-984(ra) # 80000584 <printf>
    p->killed = 1;
    80002964:	4785                	li	a5,1
    80002966:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002968:	557d                	li	a0,-1
    8000296a:	00000097          	auipc	ra,0x0
    8000296e:	996080e7          	jalr	-1642(ra) # 80002300 <exit>
  if(which_dev == 2)
    80002972:	4789                	li	a5,2
    80002974:	f8f910e3          	bne	s2,a5,800028f4 <usertrap+0x62>
    yield();
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	6f0080e7          	jalr	1776(ra) # 80002068 <yield>
    80002980:	bf95                	j	800028f4 <usertrap+0x62>
  int which_dev = 0;
    80002982:	4901                	li	s2,0
    80002984:	b7d5                	j	80002968 <usertrap+0xd6>

0000000080002986 <kerneltrap>:
{
    80002986:	7179                	addi	sp,sp,-48
    80002988:	f406                	sd	ra,40(sp)
    8000298a:	f022                	sd	s0,32(sp)
    8000298c:	ec26                	sd	s1,24(sp)
    8000298e:	e84a                	sd	s2,16(sp)
    80002990:	e44e                	sd	s3,8(sp)
    80002992:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002994:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002998:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029a0:	1004f793          	andi	a5,s1,256
    800029a4:	cb85                	beqz	a5,800029d4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029aa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ac:	ef85                	bnez	a5,800029e4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	e42080e7          	jalr	-446(ra) # 800027f0 <devintr>
    800029b6:	cd1d                	beqz	a0,800029f4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b8:	4789                	li	a5,2
    800029ba:	06f50a63          	beq	a0,a5,80002a2e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029be:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c2:	10049073          	csrw	sstatus,s1
}
    800029c6:	70a2                	ld	ra,40(sp)
    800029c8:	7402                	ld	s0,32(sp)
    800029ca:	64e2                	ld	s1,24(sp)
    800029cc:	6942                	ld	s2,16(sp)
    800029ce:	69a2                	ld	s3,8(sp)
    800029d0:	6145                	addi	sp,sp,48
    800029d2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9b450513          	addi	a0,a0,-1612 # 80008388 <states.0+0xc8>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	b5e080e7          	jalr	-1186(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	9cc50513          	addi	a0,a0,-1588 # 800083b0 <states.0+0xf0>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b4e080e7          	jalr	-1202(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    800029f4:	85ce                	mv	a1,s3
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	9da50513          	addi	a0,a0,-1574 # 800083d0 <states.0+0x110>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b86080e7          	jalr	-1146(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	9d250513          	addi	a0,a0,-1582 # 800083e0 <states.0+0x120>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b6e080e7          	jalr	-1170(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002a1e:	00006517          	auipc	a0,0x6
    80002a22:	9da50513          	addi	a0,a0,-1574 # 800083f8 <states.0+0x138>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b14080e7          	jalr	-1260(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	fb2080e7          	jalr	-78(ra) # 800019e0 <myproc>
    80002a36:	d541                	beqz	a0,800029be <kerneltrap+0x38>
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	fa8080e7          	jalr	-88(ra) # 800019e0 <myproc>
    80002a40:	4d18                	lw	a4,24(a0)
    80002a42:	4791                	li	a5,4
    80002a44:	f6f71de3          	bne	a4,a5,800029be <kerneltrap+0x38>
    yield();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	620080e7          	jalr	1568(ra) # 80002068 <yield>
    80002a50:	b7bd                	j	800029be <kerneltrap+0x38>

0000000080002a52 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	1000                	addi	s0,sp,32
    80002a5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	f82080e7          	jalr	-126(ra) # 800019e0 <myproc>
  switch (n) {
    80002a66:	4795                	li	a5,5
    80002a68:	0497e163          	bltu	a5,s1,80002aaa <argraw+0x58>
    80002a6c:	048a                	slli	s1,s1,0x2
    80002a6e:	00006717          	auipc	a4,0x6
    80002a72:	9c270713          	addi	a4,a4,-1598 # 80008430 <states.0+0x170>
    80002a76:	94ba                	add	s1,s1,a4
    80002a78:	409c                	lw	a5,0(s1)
    80002a7a:	97ba                	add	a5,a5,a4
    80002a7c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	64a2                	ld	s1,8(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
    return p->trapframe->a1;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	7fa8                	ld	a0,120(a5)
    80002a90:	bfcd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a2;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	63c8                	ld	a0,128(a5)
    80002a96:	b7f5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a3;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	67c8                	ld	a0,136(a5)
    80002a9c:	b7dd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a4;
    80002a9e:	6d3c                	ld	a5,88(a0)
    80002aa0:	6bc8                	ld	a0,144(a5)
    80002aa2:	b7c5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a5;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	6fc8                	ld	a0,152(a5)
    80002aa8:	bfe9                	j	80002a82 <argraw+0x30>
  panic("argraw");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	95e50513          	addi	a0,a0,-1698 # 80008408 <states.0+0x148>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a88080e7          	jalr	-1400(ra) # 8000053a <panic>

0000000080002aba <fetchaddr>:
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	e04a                	sd	s2,0(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84aa                	mv	s1,a0
    80002ac8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	f16080e7          	jalr	-234(ra) # 800019e0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ad2:	653c                	ld	a5,72(a0)
    80002ad4:	02f4f863          	bgeu	s1,a5,80002b04 <fetchaddr+0x4a>
    80002ad8:	00848713          	addi	a4,s1,8
    80002adc:	02e7e663          	bltu	a5,a4,80002b08 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ae0:	46a1                	li	a3,8
    80002ae2:	8626                	mv	a2,s1
    80002ae4:	85ca                	mv	a1,s2
    80002ae6:	6928                	ld	a0,80(a0)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	c48080e7          	jalr	-952(ra) # 80001730 <copyin>
    80002af0:	00a03533          	snez	a0,a0
    80002af4:	40a00533          	neg	a0,a0
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6902                	ld	s2,0(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret
    return -1;
    80002b04:	557d                	li	a0,-1
    80002b06:	bfcd                	j	80002af8 <fetchaddr+0x3e>
    80002b08:	557d                	li	a0,-1
    80002b0a:	b7fd                	j	80002af8 <fetchaddr+0x3e>

0000000080002b0c <fetchstr>:
{
    80002b0c:	7179                	addi	sp,sp,-48
    80002b0e:	f406                	sd	ra,40(sp)
    80002b10:	f022                	sd	s0,32(sp)
    80002b12:	ec26                	sd	s1,24(sp)
    80002b14:	e84a                	sd	s2,16(sp)
    80002b16:	e44e                	sd	s3,8(sp)
    80002b18:	1800                	addi	s0,sp,48
    80002b1a:	892a                	mv	s2,a0
    80002b1c:	84ae                	mv	s1,a1
    80002b1e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	ec0080e7          	jalr	-320(ra) # 800019e0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b28:	86ce                	mv	a3,s3
    80002b2a:	864a                	mv	a2,s2
    80002b2c:	85a6                	mv	a1,s1
    80002b2e:	6928                	ld	a0,80(a0)
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	c8e080e7          	jalr	-882(ra) # 800017be <copyinstr>
  if(err < 0)
    80002b38:	00054763          	bltz	a0,80002b46 <fetchstr+0x3a>
  return strlen(buf);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	354080e7          	jalr	852(ra) # 80000e92 <strlen>
}
    80002b46:	70a2                	ld	ra,40(sp)
    80002b48:	7402                	ld	s0,32(sp)
    80002b4a:	64e2                	ld	s1,24(sp)
    80002b4c:	6942                	ld	s2,16(sp)
    80002b4e:	69a2                	ld	s3,8(sp)
    80002b50:	6145                	addi	sp,sp,48
    80002b52:	8082                	ret

0000000080002b54 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b54:	1101                	addi	sp,sp,-32
    80002b56:	ec06                	sd	ra,24(sp)
    80002b58:	e822                	sd	s0,16(sp)
    80002b5a:	e426                	sd	s1,8(sp)
    80002b5c:	1000                	addi	s0,sp,32
    80002b5e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	ef2080e7          	jalr	-270(ra) # 80002a52 <argraw>
    80002b68:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b6a:	4501                	li	a0,0
    80002b6c:	60e2                	ld	ra,24(sp)
    80002b6e:	6442                	ld	s0,16(sp)
    80002b70:	64a2                	ld	s1,8(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret

0000000080002b76 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	1000                	addi	s0,sp,32
    80002b80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	ed0080e7          	jalr	-304(ra) # 80002a52 <argraw>
    80002b8a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b8c:	4501                	li	a0,0
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6105                	addi	sp,sp,32
    80002b96:	8082                	ret

0000000080002b98 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b98:	1101                	addi	sp,sp,-32
    80002b9a:	ec06                	sd	ra,24(sp)
    80002b9c:	e822                	sd	s0,16(sp)
    80002b9e:	e426                	sd	s1,8(sp)
    80002ba0:	e04a                	sd	s2,0(sp)
    80002ba2:	1000                	addi	s0,sp,32
    80002ba4:	84ae                	mv	s1,a1
    80002ba6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	eaa080e7          	jalr	-342(ra) # 80002a52 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bb0:	864a                	mv	a2,s2
    80002bb2:	85a6                	mv	a1,s1
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	f58080e7          	jalr	-168(ra) # 80002b0c <fetchstr>
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6902                	ld	s2,0(sp)
    80002bc4:	6105                	addi	sp,sp,32
    80002bc6:	8082                	ret

0000000080002bc8 <syscall>:
[SYS_freepmem]   sys_freepmem,
};

void
syscall(void)
{
    80002bc8:	1101                	addi	sp,sp,-32
    80002bca:	ec06                	sd	ra,24(sp)
    80002bcc:	e822                	sd	s0,16(sp)
    80002bce:	e426                	sd	s1,8(sp)
    80002bd0:	e04a                	sd	s2,0(sp)
    80002bd2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	e0c080e7          	jalr	-500(ra) # 800019e0 <myproc>
    80002bdc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bde:	05853903          	ld	s2,88(a0)
    80002be2:	0a893783          	ld	a5,168(s2)
    80002be6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bea:	37fd                	addiw	a5,a5,-1
    80002bec:	4759                	li	a4,22
    80002bee:	00f76f63          	bltu	a4,a5,80002c0c <syscall+0x44>
    80002bf2:	00369713          	slli	a4,a3,0x3
    80002bf6:	00006797          	auipc	a5,0x6
    80002bfa:	85278793          	addi	a5,a5,-1966 # 80008448 <syscalls>
    80002bfe:	97ba                	add	a5,a5,a4
    80002c00:	639c                	ld	a5,0(a5)
    80002c02:	c789                	beqz	a5,80002c0c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c04:	9782                	jalr	a5
    80002c06:	06a93823          	sd	a0,112(s2)
    80002c0a:	a839                	j	80002c28 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c0c:	15848613          	addi	a2,s1,344
    80002c10:	588c                	lw	a1,48(s1)
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	7fe50513          	addi	a0,a0,2046 # 80008410 <states.0+0x150>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	96a080e7          	jalr	-1686(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c22:	6cbc                	ld	a5,88(s1)
    80002c24:	577d                	li	a4,-1
    80002c26:	fbb8                	sd	a4,112(a5)
  }
}
    80002c28:	60e2                	ld	ra,24(sp)
    80002c2a:	6442                	ld	s0,16(sp)
    80002c2c:	64a2                	ld	s1,8(sp)
    80002c2e:	6902                	ld	s2,0(sp)
    80002c30:	6105                	addi	sp,sp,32
    80002c32:	8082                	ret

0000000080002c34 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c34:	1101                	addi	sp,sp,-32
    80002c36:	ec06                	sd	ra,24(sp)
    80002c38:	e822                	sd	s0,16(sp)
    80002c3a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c3c:	fec40593          	addi	a1,s0,-20
    80002c40:	4501                	li	a0,0
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	f12080e7          	jalr	-238(ra) # 80002b54 <argint>
    return -1;
    80002c4a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c4c:	00054963          	bltz	a0,80002c5e <sys_exit+0x2a>
  exit(n);
    80002c50:	fec42503          	lw	a0,-20(s0)
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	6ac080e7          	jalr	1708(ra) # 80002300 <exit>
  return 0;  // not reached
    80002c5c:	4781                	li	a5,0
}
    80002c5e:	853e                	mv	a0,a5
    80002c60:	60e2                	ld	ra,24(sp)
    80002c62:	6442                	ld	s0,16(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret

0000000080002c68 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c68:	1141                	addi	sp,sp,-16
    80002c6a:	e406                	sd	ra,8(sp)
    80002c6c:	e022                	sd	s0,0(sp)
    80002c6e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	d70080e7          	jalr	-656(ra) # 800019e0 <myproc>
}
    80002c78:	5908                	lw	a0,48(a0)
    80002c7a:	60a2                	ld	ra,8(sp)
    80002c7c:	6402                	ld	s0,0(sp)
    80002c7e:	0141                	addi	sp,sp,16
    80002c80:	8082                	ret

0000000080002c82 <sys_fork>:

uint64
sys_fork(void)
{
    80002c82:	1141                	addi	sp,sp,-16
    80002c84:	e406                	sd	ra,8(sp)
    80002c86:	e022                	sd	s0,0(sp)
    80002c88:	0800                	addi	s0,sp,16
  return fork();
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	128080e7          	jalr	296(ra) # 80001db2 <fork>
}
    80002c92:	60a2                	ld	ra,8(sp)
    80002c94:	6402                	ld	s0,0(sp)
    80002c96:	0141                	addi	sp,sp,16
    80002c98:	8082                	ret

0000000080002c9a <sys_wait>:

uint64
sys_wait(void)
{
    80002c9a:	1101                	addi	sp,sp,-32
    80002c9c:	ec06                	sd	ra,24(sp)
    80002c9e:	e822                	sd	s0,16(sp)
    80002ca0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ca2:	fe840593          	addi	a1,s0,-24
    80002ca6:	4501                	li	a0,0
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	ece080e7          	jalr	-306(ra) # 80002b76 <argaddr>
    80002cb0:	87aa                	mv	a5,a0
    return -1;
    80002cb2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cb4:	0007c863          	bltz	a5,80002cc4 <sys_wait+0x2a>
  return wait(p);
    80002cb8:	fe843503          	ld	a0,-24(s0)
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	44c080e7          	jalr	1100(ra) # 80002108 <wait>
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret

0000000080002ccc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ccc:	7179                	addi	sp,sp,-48
    80002cce:	f406                	sd	ra,40(sp)
    80002cd0:	f022                	sd	s0,32(sp)
    80002cd2:	ec26                	sd	s1,24(sp)
    80002cd4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cd6:	fdc40593          	addi	a1,s0,-36
    80002cda:	4501                	li	a0,0
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	e78080e7          	jalr	-392(ra) # 80002b54 <argint>
    80002ce4:	87aa                	mv	a5,a0
    return -1;
    80002ce6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ce8:	0207c063          	bltz	a5,80002d08 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	cf4080e7          	jalr	-780(ra) # 800019e0 <myproc>
    80002cf4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cf6:	fdc42503          	lw	a0,-36(s0)
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	040080e7          	jalr	64(ra) # 80001d3a <growproc>
    80002d02:	00054863          	bltz	a0,80002d12 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d06:	8526                	mv	a0,s1
}
    80002d08:	70a2                	ld	ra,40(sp)
    80002d0a:	7402                	ld	s0,32(sp)
    80002d0c:	64e2                	ld	s1,24(sp)
    80002d0e:	6145                	addi	sp,sp,48
    80002d10:	8082                	ret
    return -1;
    80002d12:	557d                	li	a0,-1
    80002d14:	bfd5                	j	80002d08 <sys_sbrk+0x3c>

0000000080002d16 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d16:	7139                	addi	sp,sp,-64
    80002d18:	fc06                	sd	ra,56(sp)
    80002d1a:	f822                	sd	s0,48(sp)
    80002d1c:	f426                	sd	s1,40(sp)
    80002d1e:	f04a                	sd	s2,32(sp)
    80002d20:	ec4e                	sd	s3,24(sp)
    80002d22:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d24:	fcc40593          	addi	a1,s0,-52
    80002d28:	4501                	li	a0,0
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	e2a080e7          	jalr	-470(ra) # 80002b54 <argint>
    return -1;
    80002d32:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d34:	06054563          	bltz	a0,80002d9e <sys_sleep+0x88>
  acquire(&tickslock);
    80002d38:	00014517          	auipc	a0,0x14
    80002d3c:	39850513          	addi	a0,a0,920 # 800170d0 <tickslock>
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	eda080e7          	jalr	-294(ra) # 80000c1a <acquire>
  ticks0 = ticks;
    80002d48:	00006917          	auipc	s2,0x6
    80002d4c:	2e892903          	lw	s2,744(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d50:	fcc42783          	lw	a5,-52(s0)
    80002d54:	cf85                	beqz	a5,80002d8c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d56:	00014997          	auipc	s3,0x14
    80002d5a:	37a98993          	addi	s3,s3,890 # 800170d0 <tickslock>
    80002d5e:	00006497          	auipc	s1,0x6
    80002d62:	2d248493          	addi	s1,s1,722 # 80009030 <ticks>
    if(myproc()->killed){
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	c7a080e7          	jalr	-902(ra) # 800019e0 <myproc>
    80002d6e:	551c                	lw	a5,40(a0)
    80002d70:	ef9d                	bnez	a5,80002dae <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d72:	85ce                	mv	a1,s3
    80002d74:	8526                	mv	a0,s1
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	32e080e7          	jalr	814(ra) # 800020a4 <sleep>
  while(ticks - ticks0 < n){
    80002d7e:	409c                	lw	a5,0(s1)
    80002d80:	412787bb          	subw	a5,a5,s2
    80002d84:	fcc42703          	lw	a4,-52(s0)
    80002d88:	fce7efe3          	bltu	a5,a4,80002d66 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d8c:	00014517          	auipc	a0,0x14
    80002d90:	34450513          	addi	a0,a0,836 # 800170d0 <tickslock>
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	f3a080e7          	jalr	-198(ra) # 80000cce <release>
  return 0;
    80002d9c:	4781                	li	a5,0
}
    80002d9e:	853e                	mv	a0,a5
    80002da0:	70e2                	ld	ra,56(sp)
    80002da2:	7442                	ld	s0,48(sp)
    80002da4:	74a2                	ld	s1,40(sp)
    80002da6:	7902                	ld	s2,32(sp)
    80002da8:	69e2                	ld	s3,24(sp)
    80002daa:	6121                	addi	sp,sp,64
    80002dac:	8082                	ret
      release(&tickslock);
    80002dae:	00014517          	auipc	a0,0x14
    80002db2:	32250513          	addi	a0,a0,802 # 800170d0 <tickslock>
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	f18080e7          	jalr	-232(ra) # 80000cce <release>
      return -1;
    80002dbe:	57fd                	li	a5,-1
    80002dc0:	bff9                	j	80002d9e <sys_sleep+0x88>

0000000080002dc2 <sys_kill>:

uint64
sys_kill(void)
{
    80002dc2:	1101                	addi	sp,sp,-32
    80002dc4:	ec06                	sd	ra,24(sp)
    80002dc6:	e822                	sd	s0,16(sp)
    80002dc8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dca:	fec40593          	addi	a1,s0,-20
    80002dce:	4501                	li	a0,0
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	d84080e7          	jalr	-636(ra) # 80002b54 <argint>
    80002dd8:	87aa                	mv	a5,a0
    return -1;
    80002dda:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ddc:	0007c863          	bltz	a5,80002dec <sys_kill+0x2a>
  return kill(pid);
    80002de0:	fec42503          	lw	a0,-20(s0)
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	5f2080e7          	jalr	1522(ra) # 800023d6 <kill>
}
    80002dec:	60e2                	ld	ra,24(sp)
    80002dee:	6442                	ld	s0,16(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret

0000000080002df4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	e426                	sd	s1,8(sp)
    80002dfc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dfe:	00014517          	auipc	a0,0x14
    80002e02:	2d250513          	addi	a0,a0,722 # 800170d0 <tickslock>
    80002e06:	ffffe097          	auipc	ra,0xffffe
    80002e0a:	e14080e7          	jalr	-492(ra) # 80000c1a <acquire>
  xticks = ticks;
    80002e0e:	00006497          	auipc	s1,0x6
    80002e12:	2224a483          	lw	s1,546(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e16:	00014517          	auipc	a0,0x14
    80002e1a:	2ba50513          	addi	a0,a0,698 # 800170d0 <tickslock>
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	eb0080e7          	jalr	-336(ra) # 80000cce <release>
  return xticks;
}
    80002e26:	02049513          	slli	a0,s1,0x20
    80002e2a:	9101                	srli	a0,a0,0x20
    80002e2c:	60e2                	ld	ra,24(sp)
    80002e2e:	6442                	ld	s0,16(sp)
    80002e30:	64a2                	ld	s1,8(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret

0000000080002e36 <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    80002e3e:	fe840593          	addi	a1,s0,-24
    80002e42:	4501                	li	a0,0
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	d32080e7          	jalr	-718(ra) # 80002b76 <argaddr>
    80002e4c:	87aa                	mv	a5,a0
    return -1;
    80002e4e:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80002e50:	0007c863          	bltz	a5,80002e60 <sys_getprocs+0x2a>
  return(procinfo(addr));
    80002e54:	fe843503          	ld	a0,-24(s0)
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	74c080e7          	jalr	1868(ra) # 800025a4 <procinfo>
}
    80002e60:	60e2                	ld	ra,24(sp)
    80002e62:	6442                	ld	s0,16(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <sys_freepmem>:

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
    80002e68:	1141                	addi	sp,sp,-16
    80002e6a:	e406                	sd	ra,8(sp)
    80002e6c:	e022                	sd	s0,0(sp)
    80002e6e:	0800                	addi	s0,sp,16
  int res = freepmem();
    80002e70:	ffffe097          	auipc	ra,0xffffe
    80002e74:	cd0080e7          	jalr	-816(ra) # 80000b40 <freepmem>
  return res;
    80002e78:	2501                	sext.w	a0,a0
    80002e7a:	60a2                	ld	ra,8(sp)
    80002e7c:	6402                	ld	s0,0(sp)
    80002e7e:	0141                	addi	sp,sp,16
    80002e80:	8082                	ret

0000000080002e82 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e82:	7179                	addi	sp,sp,-48
    80002e84:	f406                	sd	ra,40(sp)
    80002e86:	f022                	sd	s0,32(sp)
    80002e88:	ec26                	sd	s1,24(sp)
    80002e8a:	e84a                	sd	s2,16(sp)
    80002e8c:	e44e                	sd	s3,8(sp)
    80002e8e:	e052                	sd	s4,0(sp)
    80002e90:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e92:	00005597          	auipc	a1,0x5
    80002e96:	67658593          	addi	a1,a1,1654 # 80008508 <syscalls+0xc0>
    80002e9a:	00014517          	auipc	a0,0x14
    80002e9e:	24e50513          	addi	a0,a0,590 # 800170e8 <bcache>
    80002ea2:	ffffe097          	auipc	ra,0xffffe
    80002ea6:	ce8080e7          	jalr	-792(ra) # 80000b8a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eaa:	0001c797          	auipc	a5,0x1c
    80002eae:	23e78793          	addi	a5,a5,574 # 8001f0e8 <bcache+0x8000>
    80002eb2:	0001c717          	auipc	a4,0x1c
    80002eb6:	49e70713          	addi	a4,a4,1182 # 8001f350 <bcache+0x8268>
    80002eba:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ebe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ec2:	00014497          	auipc	s1,0x14
    80002ec6:	23e48493          	addi	s1,s1,574 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002eca:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ecc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ece:	00005a17          	auipc	s4,0x5
    80002ed2:	642a0a13          	addi	s4,s4,1602 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ed6:	2b893783          	ld	a5,696(s2)
    80002eda:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002edc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ee0:	85d2                	mv	a1,s4
    80002ee2:	01048513          	addi	a0,s1,16
    80002ee6:	00001097          	auipc	ra,0x1
    80002eea:	4c2080e7          	jalr	1218(ra) # 800043a8 <initsleeplock>
    bcache.head.next->prev = b;
    80002eee:	2b893783          	ld	a5,696(s2)
    80002ef2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ef4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ef8:	45848493          	addi	s1,s1,1112
    80002efc:	fd349de3          	bne	s1,s3,80002ed6 <binit+0x54>
  }
}
    80002f00:	70a2                	ld	ra,40(sp)
    80002f02:	7402                	ld	s0,32(sp)
    80002f04:	64e2                	ld	s1,24(sp)
    80002f06:	6942                	ld	s2,16(sp)
    80002f08:	69a2                	ld	s3,8(sp)
    80002f0a:	6a02                	ld	s4,0(sp)
    80002f0c:	6145                	addi	sp,sp,48
    80002f0e:	8082                	ret

0000000080002f10 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f10:	7179                	addi	sp,sp,-48
    80002f12:	f406                	sd	ra,40(sp)
    80002f14:	f022                	sd	s0,32(sp)
    80002f16:	ec26                	sd	s1,24(sp)
    80002f18:	e84a                	sd	s2,16(sp)
    80002f1a:	e44e                	sd	s3,8(sp)
    80002f1c:	1800                	addi	s0,sp,48
    80002f1e:	892a                	mv	s2,a0
    80002f20:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f22:	00014517          	auipc	a0,0x14
    80002f26:	1c650513          	addi	a0,a0,454 # 800170e8 <bcache>
    80002f2a:	ffffe097          	auipc	ra,0xffffe
    80002f2e:	cf0080e7          	jalr	-784(ra) # 80000c1a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f32:	0001c497          	auipc	s1,0x1c
    80002f36:	46e4b483          	ld	s1,1134(s1) # 8001f3a0 <bcache+0x82b8>
    80002f3a:	0001c797          	auipc	a5,0x1c
    80002f3e:	41678793          	addi	a5,a5,1046 # 8001f350 <bcache+0x8268>
    80002f42:	02f48f63          	beq	s1,a5,80002f80 <bread+0x70>
    80002f46:	873e                	mv	a4,a5
    80002f48:	a021                	j	80002f50 <bread+0x40>
    80002f4a:	68a4                	ld	s1,80(s1)
    80002f4c:	02e48a63          	beq	s1,a4,80002f80 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f50:	449c                	lw	a5,8(s1)
    80002f52:	ff279ce3          	bne	a5,s2,80002f4a <bread+0x3a>
    80002f56:	44dc                	lw	a5,12(s1)
    80002f58:	ff3799e3          	bne	a5,s3,80002f4a <bread+0x3a>
      b->refcnt++;
    80002f5c:	40bc                	lw	a5,64(s1)
    80002f5e:	2785                	addiw	a5,a5,1
    80002f60:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f62:	00014517          	auipc	a0,0x14
    80002f66:	18650513          	addi	a0,a0,390 # 800170e8 <bcache>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	d64080e7          	jalr	-668(ra) # 80000cce <release>
      acquiresleep(&b->lock);
    80002f72:	01048513          	addi	a0,s1,16
    80002f76:	00001097          	auipc	ra,0x1
    80002f7a:	46c080e7          	jalr	1132(ra) # 800043e2 <acquiresleep>
      return b;
    80002f7e:	a8b9                	j	80002fdc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f80:	0001c497          	auipc	s1,0x1c
    80002f84:	4184b483          	ld	s1,1048(s1) # 8001f398 <bcache+0x82b0>
    80002f88:	0001c797          	auipc	a5,0x1c
    80002f8c:	3c878793          	addi	a5,a5,968 # 8001f350 <bcache+0x8268>
    80002f90:	00f48863          	beq	s1,a5,80002fa0 <bread+0x90>
    80002f94:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f96:	40bc                	lw	a5,64(s1)
    80002f98:	cf81                	beqz	a5,80002fb0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f9a:	64a4                	ld	s1,72(s1)
    80002f9c:	fee49de3          	bne	s1,a4,80002f96 <bread+0x86>
  panic("bget: no buffers");
    80002fa0:	00005517          	auipc	a0,0x5
    80002fa4:	57850513          	addi	a0,a0,1400 # 80008518 <syscalls+0xd0>
    80002fa8:	ffffd097          	auipc	ra,0xffffd
    80002fac:	592080e7          	jalr	1426(ra) # 8000053a <panic>
      b->dev = dev;
    80002fb0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fb4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fb8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fbc:	4785                	li	a5,1
    80002fbe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc0:	00014517          	auipc	a0,0x14
    80002fc4:	12850513          	addi	a0,a0,296 # 800170e8 <bcache>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	d06080e7          	jalr	-762(ra) # 80000cce <release>
      acquiresleep(&b->lock);
    80002fd0:	01048513          	addi	a0,s1,16
    80002fd4:	00001097          	auipc	ra,0x1
    80002fd8:	40e080e7          	jalr	1038(ra) # 800043e2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fdc:	409c                	lw	a5,0(s1)
    80002fde:	cb89                	beqz	a5,80002ff0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	70a2                	ld	ra,40(sp)
    80002fe4:	7402                	ld	s0,32(sp)
    80002fe6:	64e2                	ld	s1,24(sp)
    80002fe8:	6942                	ld	s2,16(sp)
    80002fea:	69a2                	ld	s3,8(sp)
    80002fec:	6145                	addi	sp,sp,48
    80002fee:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ff0:	4581                	li	a1,0
    80002ff2:	8526                	mv	a0,s1
    80002ff4:	00003097          	auipc	ra,0x3
    80002ff8:	f1e080e7          	jalr	-226(ra) # 80005f12 <virtio_disk_rw>
    b->valid = 1;
    80002ffc:	4785                	li	a5,1
    80002ffe:	c09c                	sw	a5,0(s1)
  return b;
    80003000:	b7c5                	j	80002fe0 <bread+0xd0>

0000000080003002 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003002:	1101                	addi	sp,sp,-32
    80003004:	ec06                	sd	ra,24(sp)
    80003006:	e822                	sd	s0,16(sp)
    80003008:	e426                	sd	s1,8(sp)
    8000300a:	1000                	addi	s0,sp,32
    8000300c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000300e:	0541                	addi	a0,a0,16
    80003010:	00001097          	auipc	ra,0x1
    80003014:	46c080e7          	jalr	1132(ra) # 8000447c <holdingsleep>
    80003018:	cd01                	beqz	a0,80003030 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000301a:	4585                	li	a1,1
    8000301c:	8526                	mv	a0,s1
    8000301e:	00003097          	auipc	ra,0x3
    80003022:	ef4080e7          	jalr	-268(ra) # 80005f12 <virtio_disk_rw>
}
    80003026:	60e2                	ld	ra,24(sp)
    80003028:	6442                	ld	s0,16(sp)
    8000302a:	64a2                	ld	s1,8(sp)
    8000302c:	6105                	addi	sp,sp,32
    8000302e:	8082                	ret
    panic("bwrite");
    80003030:	00005517          	auipc	a0,0x5
    80003034:	50050513          	addi	a0,a0,1280 # 80008530 <syscalls+0xe8>
    80003038:	ffffd097          	auipc	ra,0xffffd
    8000303c:	502080e7          	jalr	1282(ra) # 8000053a <panic>

0000000080003040 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	e04a                	sd	s2,0(sp)
    8000304a:	1000                	addi	s0,sp,32
    8000304c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000304e:	01050913          	addi	s2,a0,16
    80003052:	854a                	mv	a0,s2
    80003054:	00001097          	auipc	ra,0x1
    80003058:	428080e7          	jalr	1064(ra) # 8000447c <holdingsleep>
    8000305c:	c92d                	beqz	a0,800030ce <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000305e:	854a                	mv	a0,s2
    80003060:	00001097          	auipc	ra,0x1
    80003064:	3d8080e7          	jalr	984(ra) # 80004438 <releasesleep>

  acquire(&bcache.lock);
    80003068:	00014517          	auipc	a0,0x14
    8000306c:	08050513          	addi	a0,a0,128 # 800170e8 <bcache>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	baa080e7          	jalr	-1110(ra) # 80000c1a <acquire>
  b->refcnt--;
    80003078:	40bc                	lw	a5,64(s1)
    8000307a:	37fd                	addiw	a5,a5,-1
    8000307c:	0007871b          	sext.w	a4,a5
    80003080:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003082:	eb05                	bnez	a4,800030b2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003084:	68bc                	ld	a5,80(s1)
    80003086:	64b8                	ld	a4,72(s1)
    80003088:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000308a:	64bc                	ld	a5,72(s1)
    8000308c:	68b8                	ld	a4,80(s1)
    8000308e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003090:	0001c797          	auipc	a5,0x1c
    80003094:	05878793          	addi	a5,a5,88 # 8001f0e8 <bcache+0x8000>
    80003098:	2b87b703          	ld	a4,696(a5)
    8000309c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000309e:	0001c717          	auipc	a4,0x1c
    800030a2:	2b270713          	addi	a4,a4,690 # 8001f350 <bcache+0x8268>
    800030a6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030a8:	2b87b703          	ld	a4,696(a5)
    800030ac:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ae:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	03650513          	addi	a0,a0,54 # 800170e8 <bcache>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	c14080e7          	jalr	-1004(ra) # 80000cce <release>
}
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6902                	ld	s2,0(sp)
    800030ca:	6105                	addi	sp,sp,32
    800030cc:	8082                	ret
    panic("brelse");
    800030ce:	00005517          	auipc	a0,0x5
    800030d2:	46a50513          	addi	a0,a0,1130 # 80008538 <syscalls+0xf0>
    800030d6:	ffffd097          	auipc	ra,0xffffd
    800030da:	464080e7          	jalr	1124(ra) # 8000053a <panic>

00000000800030de <bpin>:

void
bpin(struct buf *b) {
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	1000                	addi	s0,sp,32
    800030e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	ffe50513          	addi	a0,a0,-2 # 800170e8 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	b28080e7          	jalr	-1240(ra) # 80000c1a <acquire>
  b->refcnt++;
    800030fa:	40bc                	lw	a5,64(s1)
    800030fc:	2785                	addiw	a5,a5,1
    800030fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003100:	00014517          	auipc	a0,0x14
    80003104:	fe850513          	addi	a0,a0,-24 # 800170e8 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	bc6080e7          	jalr	-1082(ra) # 80000cce <release>
}
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	64a2                	ld	s1,8(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <bunpin>:

void
bunpin(struct buf *b) {
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
    80003124:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003126:	00014517          	auipc	a0,0x14
    8000312a:	fc250513          	addi	a0,a0,-62 # 800170e8 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	aec080e7          	jalr	-1300(ra) # 80000c1a <acquire>
  b->refcnt--;
    80003136:	40bc                	lw	a5,64(s1)
    80003138:	37fd                	addiw	a5,a5,-1
    8000313a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000313c:	00014517          	auipc	a0,0x14
    80003140:	fac50513          	addi	a0,a0,-84 # 800170e8 <bcache>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	b8a080e7          	jalr	-1142(ra) # 80000cce <release>
}
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	e04a                	sd	s2,0(sp)
    80003160:	1000                	addi	s0,sp,32
    80003162:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003164:	00d5d59b          	srliw	a1,a1,0xd
    80003168:	0001c797          	auipc	a5,0x1c
    8000316c:	65c7a783          	lw	a5,1628(a5) # 8001f7c4 <sb+0x1c>
    80003170:	9dbd                	addw	a1,a1,a5
    80003172:	00000097          	auipc	ra,0x0
    80003176:	d9e080e7          	jalr	-610(ra) # 80002f10 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000317a:	0074f713          	andi	a4,s1,7
    8000317e:	4785                	li	a5,1
    80003180:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003184:	14ce                	slli	s1,s1,0x33
    80003186:	90d9                	srli	s1,s1,0x36
    80003188:	00950733          	add	a4,a0,s1
    8000318c:	05874703          	lbu	a4,88(a4)
    80003190:	00e7f6b3          	and	a3,a5,a4
    80003194:	c69d                	beqz	a3,800031c2 <bfree+0x6c>
    80003196:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003198:	94aa                	add	s1,s1,a0
    8000319a:	fff7c793          	not	a5,a5
    8000319e:	8f7d                	and	a4,a4,a5
    800031a0:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031a4:	00001097          	auipc	ra,0x1
    800031a8:	120080e7          	jalr	288(ra) # 800042c4 <log_write>
  brelse(bp);
    800031ac:	854a                	mv	a0,s2
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	e92080e7          	jalr	-366(ra) # 80003040 <brelse>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6902                	ld	s2,0(sp)
    800031be:	6105                	addi	sp,sp,32
    800031c0:	8082                	ret
    panic("freeing free block");
    800031c2:	00005517          	auipc	a0,0x5
    800031c6:	37e50513          	addi	a0,a0,894 # 80008540 <syscalls+0xf8>
    800031ca:	ffffd097          	auipc	ra,0xffffd
    800031ce:	370080e7          	jalr	880(ra) # 8000053a <panic>

00000000800031d2 <balloc>:
{
    800031d2:	711d                	addi	sp,sp,-96
    800031d4:	ec86                	sd	ra,88(sp)
    800031d6:	e8a2                	sd	s0,80(sp)
    800031d8:	e4a6                	sd	s1,72(sp)
    800031da:	e0ca                	sd	s2,64(sp)
    800031dc:	fc4e                	sd	s3,56(sp)
    800031de:	f852                	sd	s4,48(sp)
    800031e0:	f456                	sd	s5,40(sp)
    800031e2:	f05a                	sd	s6,32(sp)
    800031e4:	ec5e                	sd	s7,24(sp)
    800031e6:	e862                	sd	s8,16(sp)
    800031e8:	e466                	sd	s9,8(sp)
    800031ea:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031ec:	0001c797          	auipc	a5,0x1c
    800031f0:	5c07a783          	lw	a5,1472(a5) # 8001f7ac <sb+0x4>
    800031f4:	cbc1                	beqz	a5,80003284 <balloc+0xb2>
    800031f6:	8baa                	mv	s7,a0
    800031f8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031fa:	0001cb17          	auipc	s6,0x1c
    800031fe:	5aeb0b13          	addi	s6,s6,1454 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003202:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003204:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003206:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003208:	6c89                	lui	s9,0x2
    8000320a:	a831                	j	80003226 <balloc+0x54>
    brelse(bp);
    8000320c:	854a                	mv	a0,s2
    8000320e:	00000097          	auipc	ra,0x0
    80003212:	e32080e7          	jalr	-462(ra) # 80003040 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003216:	015c87bb          	addw	a5,s9,s5
    8000321a:	00078a9b          	sext.w	s5,a5
    8000321e:	004b2703          	lw	a4,4(s6)
    80003222:	06eaf163          	bgeu	s5,a4,80003284 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003226:	41fad79b          	sraiw	a5,s5,0x1f
    8000322a:	0137d79b          	srliw	a5,a5,0x13
    8000322e:	015787bb          	addw	a5,a5,s5
    80003232:	40d7d79b          	sraiw	a5,a5,0xd
    80003236:	01cb2583          	lw	a1,28(s6)
    8000323a:	9dbd                	addw	a1,a1,a5
    8000323c:	855e                	mv	a0,s7
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	cd2080e7          	jalr	-814(ra) # 80002f10 <bread>
    80003246:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003248:	004b2503          	lw	a0,4(s6)
    8000324c:	000a849b          	sext.w	s1,s5
    80003250:	8762                	mv	a4,s8
    80003252:	faa4fde3          	bgeu	s1,a0,8000320c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003256:	00777693          	andi	a3,a4,7
    8000325a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000325e:	41f7579b          	sraiw	a5,a4,0x1f
    80003262:	01d7d79b          	srliw	a5,a5,0x1d
    80003266:	9fb9                	addw	a5,a5,a4
    80003268:	4037d79b          	sraiw	a5,a5,0x3
    8000326c:	00f90633          	add	a2,s2,a5
    80003270:	05864603          	lbu	a2,88(a2)
    80003274:	00c6f5b3          	and	a1,a3,a2
    80003278:	cd91                	beqz	a1,80003294 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000327a:	2705                	addiw	a4,a4,1
    8000327c:	2485                	addiw	s1,s1,1
    8000327e:	fd471ae3          	bne	a4,s4,80003252 <balloc+0x80>
    80003282:	b769                	j	8000320c <balloc+0x3a>
  panic("balloc: out of blocks");
    80003284:	00005517          	auipc	a0,0x5
    80003288:	2d450513          	addi	a0,a0,724 # 80008558 <syscalls+0x110>
    8000328c:	ffffd097          	auipc	ra,0xffffd
    80003290:	2ae080e7          	jalr	686(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003294:	97ca                	add	a5,a5,s2
    80003296:	8e55                	or	a2,a2,a3
    80003298:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	026080e7          	jalr	38(ra) # 800042c4 <log_write>
        brelse(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	d98080e7          	jalr	-616(ra) # 80003040 <brelse>
  bp = bread(dev, bno);
    800032b0:	85a6                	mv	a1,s1
    800032b2:	855e                	mv	a0,s7
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	c5c080e7          	jalr	-932(ra) # 80002f10 <bread>
    800032bc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032be:	40000613          	li	a2,1024
    800032c2:	4581                	li	a1,0
    800032c4:	05850513          	addi	a0,a0,88
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	a4e080e7          	jalr	-1458(ra) # 80000d16 <memset>
  log_write(bp);
    800032d0:	854a                	mv	a0,s2
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	ff2080e7          	jalr	-14(ra) # 800042c4 <log_write>
  brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	d64080e7          	jalr	-668(ra) # 80003040 <brelse>
}
    800032e4:	8526                	mv	a0,s1
    800032e6:	60e6                	ld	ra,88(sp)
    800032e8:	6446                	ld	s0,80(sp)
    800032ea:	64a6                	ld	s1,72(sp)
    800032ec:	6906                	ld	s2,64(sp)
    800032ee:	79e2                	ld	s3,56(sp)
    800032f0:	7a42                	ld	s4,48(sp)
    800032f2:	7aa2                	ld	s5,40(sp)
    800032f4:	7b02                	ld	s6,32(sp)
    800032f6:	6be2                	ld	s7,24(sp)
    800032f8:	6c42                	ld	s8,16(sp)
    800032fa:	6ca2                	ld	s9,8(sp)
    800032fc:	6125                	addi	sp,sp,96
    800032fe:	8082                	ret

0000000080003300 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003300:	7179                	addi	sp,sp,-48
    80003302:	f406                	sd	ra,40(sp)
    80003304:	f022                	sd	s0,32(sp)
    80003306:	ec26                	sd	s1,24(sp)
    80003308:	e84a                	sd	s2,16(sp)
    8000330a:	e44e                	sd	s3,8(sp)
    8000330c:	e052                	sd	s4,0(sp)
    8000330e:	1800                	addi	s0,sp,48
    80003310:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003312:	47ad                	li	a5,11
    80003314:	04b7fe63          	bgeu	a5,a1,80003370 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003318:	ff45849b          	addiw	s1,a1,-12
    8000331c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003320:	0ff00793          	li	a5,255
    80003324:	0ae7e463          	bltu	a5,a4,800033cc <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003328:	08052583          	lw	a1,128(a0)
    8000332c:	c5b5                	beqz	a1,80003398 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000332e:	00092503          	lw	a0,0(s2)
    80003332:	00000097          	auipc	ra,0x0
    80003336:	bde080e7          	jalr	-1058(ra) # 80002f10 <bread>
    8000333a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000333c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003340:	02049713          	slli	a4,s1,0x20
    80003344:	01e75593          	srli	a1,a4,0x1e
    80003348:	00b784b3          	add	s1,a5,a1
    8000334c:	0004a983          	lw	s3,0(s1)
    80003350:	04098e63          	beqz	s3,800033ac <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003354:	8552                	mv	a0,s4
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	cea080e7          	jalr	-790(ra) # 80003040 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000335e:	854e                	mv	a0,s3
    80003360:	70a2                	ld	ra,40(sp)
    80003362:	7402                	ld	s0,32(sp)
    80003364:	64e2                	ld	s1,24(sp)
    80003366:	6942                	ld	s2,16(sp)
    80003368:	69a2                	ld	s3,8(sp)
    8000336a:	6a02                	ld	s4,0(sp)
    8000336c:	6145                	addi	sp,sp,48
    8000336e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003370:	02059793          	slli	a5,a1,0x20
    80003374:	01e7d593          	srli	a1,a5,0x1e
    80003378:	00b504b3          	add	s1,a0,a1
    8000337c:	0504a983          	lw	s3,80(s1)
    80003380:	fc099fe3          	bnez	s3,8000335e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003384:	4108                	lw	a0,0(a0)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e4c080e7          	jalr	-436(ra) # 800031d2 <balloc>
    8000338e:	0005099b          	sext.w	s3,a0
    80003392:	0534a823          	sw	s3,80(s1)
    80003396:	b7e1                	j	8000335e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003398:	4108                	lw	a0,0(a0)
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	e38080e7          	jalr	-456(ra) # 800031d2 <balloc>
    800033a2:	0005059b          	sext.w	a1,a0
    800033a6:	08b92023          	sw	a1,128(s2)
    800033aa:	b751                	j	8000332e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033ac:	00092503          	lw	a0,0(s2)
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e22080e7          	jalr	-478(ra) # 800031d2 <balloc>
    800033b8:	0005099b          	sext.w	s3,a0
    800033bc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033c0:	8552                	mv	a0,s4
    800033c2:	00001097          	auipc	ra,0x1
    800033c6:	f02080e7          	jalr	-254(ra) # 800042c4 <log_write>
    800033ca:	b769                	j	80003354 <bmap+0x54>
  panic("bmap: out of range");
    800033cc:	00005517          	auipc	a0,0x5
    800033d0:	1a450513          	addi	a0,a0,420 # 80008570 <syscalls+0x128>
    800033d4:	ffffd097          	auipc	ra,0xffffd
    800033d8:	166080e7          	jalr	358(ra) # 8000053a <panic>

00000000800033dc <iget>:
{
    800033dc:	7179                	addi	sp,sp,-48
    800033de:	f406                	sd	ra,40(sp)
    800033e0:	f022                	sd	s0,32(sp)
    800033e2:	ec26                	sd	s1,24(sp)
    800033e4:	e84a                	sd	s2,16(sp)
    800033e6:	e44e                	sd	s3,8(sp)
    800033e8:	e052                	sd	s4,0(sp)
    800033ea:	1800                	addi	s0,sp,48
    800033ec:	89aa                	mv	s3,a0
    800033ee:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033f0:	0001c517          	auipc	a0,0x1c
    800033f4:	3d850513          	addi	a0,a0,984 # 8001f7c8 <itable>
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	822080e7          	jalr	-2014(ra) # 80000c1a <acquire>
  empty = 0;
    80003400:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003402:	0001c497          	auipc	s1,0x1c
    80003406:	3de48493          	addi	s1,s1,990 # 8001f7e0 <itable+0x18>
    8000340a:	0001e697          	auipc	a3,0x1e
    8000340e:	e6668693          	addi	a3,a3,-410 # 80021270 <log>
    80003412:	a039                	j	80003420 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003414:	02090b63          	beqz	s2,8000344a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003418:	08848493          	addi	s1,s1,136
    8000341c:	02d48a63          	beq	s1,a3,80003450 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003420:	449c                	lw	a5,8(s1)
    80003422:	fef059e3          	blez	a5,80003414 <iget+0x38>
    80003426:	4098                	lw	a4,0(s1)
    80003428:	ff3716e3          	bne	a4,s3,80003414 <iget+0x38>
    8000342c:	40d8                	lw	a4,4(s1)
    8000342e:	ff4713e3          	bne	a4,s4,80003414 <iget+0x38>
      ip->ref++;
    80003432:	2785                	addiw	a5,a5,1
    80003434:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003436:	0001c517          	auipc	a0,0x1c
    8000343a:	39250513          	addi	a0,a0,914 # 8001f7c8 <itable>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	890080e7          	jalr	-1904(ra) # 80000cce <release>
      return ip;
    80003446:	8926                	mv	s2,s1
    80003448:	a03d                	j	80003476 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000344a:	f7f9                	bnez	a5,80003418 <iget+0x3c>
    8000344c:	8926                	mv	s2,s1
    8000344e:	b7e9                	j	80003418 <iget+0x3c>
  if(empty == 0)
    80003450:	02090c63          	beqz	s2,80003488 <iget+0xac>
  ip->dev = dev;
    80003454:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003458:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000345c:	4785                	li	a5,1
    8000345e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003462:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003466:	0001c517          	auipc	a0,0x1c
    8000346a:	36250513          	addi	a0,a0,866 # 8001f7c8 <itable>
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	860080e7          	jalr	-1952(ra) # 80000cce <release>
}
    80003476:	854a                	mv	a0,s2
    80003478:	70a2                	ld	ra,40(sp)
    8000347a:	7402                	ld	s0,32(sp)
    8000347c:	64e2                	ld	s1,24(sp)
    8000347e:	6942                	ld	s2,16(sp)
    80003480:	69a2                	ld	s3,8(sp)
    80003482:	6a02                	ld	s4,0(sp)
    80003484:	6145                	addi	sp,sp,48
    80003486:	8082                	ret
    panic("iget: no inodes");
    80003488:	00005517          	auipc	a0,0x5
    8000348c:	10050513          	addi	a0,a0,256 # 80008588 <syscalls+0x140>
    80003490:	ffffd097          	auipc	ra,0xffffd
    80003494:	0aa080e7          	jalr	170(ra) # 8000053a <panic>

0000000080003498 <fsinit>:
fsinit(int dev) {
    80003498:	7179                	addi	sp,sp,-48
    8000349a:	f406                	sd	ra,40(sp)
    8000349c:	f022                	sd	s0,32(sp)
    8000349e:	ec26                	sd	s1,24(sp)
    800034a0:	e84a                	sd	s2,16(sp)
    800034a2:	e44e                	sd	s3,8(sp)
    800034a4:	1800                	addi	s0,sp,48
    800034a6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034a8:	4585                	li	a1,1
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	a66080e7          	jalr	-1434(ra) # 80002f10 <bread>
    800034b2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034b4:	0001c997          	auipc	s3,0x1c
    800034b8:	2f498993          	addi	s3,s3,756 # 8001f7a8 <sb>
    800034bc:	02000613          	li	a2,32
    800034c0:	05850593          	addi	a1,a0,88
    800034c4:	854e                	mv	a0,s3
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	8ac080e7          	jalr	-1876(ra) # 80000d72 <memmove>
  brelse(bp);
    800034ce:	8526                	mv	a0,s1
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	b70080e7          	jalr	-1168(ra) # 80003040 <brelse>
  if(sb.magic != FSMAGIC)
    800034d8:	0009a703          	lw	a4,0(s3)
    800034dc:	102037b7          	lui	a5,0x10203
    800034e0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034e4:	02f71263          	bne	a4,a5,80003508 <fsinit+0x70>
  initlog(dev, &sb);
    800034e8:	0001c597          	auipc	a1,0x1c
    800034ec:	2c058593          	addi	a1,a1,704 # 8001f7a8 <sb>
    800034f0:	854a                	mv	a0,s2
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	b56080e7          	jalr	-1194(ra) # 80004048 <initlog>
}
    800034fa:	70a2                	ld	ra,40(sp)
    800034fc:	7402                	ld	s0,32(sp)
    800034fe:	64e2                	ld	s1,24(sp)
    80003500:	6942                	ld	s2,16(sp)
    80003502:	69a2                	ld	s3,8(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret
    panic("invalid file system");
    80003508:	00005517          	auipc	a0,0x5
    8000350c:	09050513          	addi	a0,a0,144 # 80008598 <syscalls+0x150>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	02a080e7          	jalr	42(ra) # 8000053a <panic>

0000000080003518 <iinit>:
{
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003526:	00005597          	auipc	a1,0x5
    8000352a:	08a58593          	addi	a1,a1,138 # 800085b0 <syscalls+0x168>
    8000352e:	0001c517          	auipc	a0,0x1c
    80003532:	29a50513          	addi	a0,a0,666 # 8001f7c8 <itable>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	654080e7          	jalr	1620(ra) # 80000b8a <initlock>
  for(i = 0; i < NINODE; i++) {
    8000353e:	0001c497          	auipc	s1,0x1c
    80003542:	2b248493          	addi	s1,s1,690 # 8001f7f0 <itable+0x28>
    80003546:	0001e997          	auipc	s3,0x1e
    8000354a:	d3a98993          	addi	s3,s3,-710 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000354e:	00005917          	auipc	s2,0x5
    80003552:	06a90913          	addi	s2,s2,106 # 800085b8 <syscalls+0x170>
    80003556:	85ca                	mv	a1,s2
    80003558:	8526                	mv	a0,s1
    8000355a:	00001097          	auipc	ra,0x1
    8000355e:	e4e080e7          	jalr	-434(ra) # 800043a8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003562:	08848493          	addi	s1,s1,136
    80003566:	ff3498e3          	bne	s1,s3,80003556 <iinit+0x3e>
}
    8000356a:	70a2                	ld	ra,40(sp)
    8000356c:	7402                	ld	s0,32(sp)
    8000356e:	64e2                	ld	s1,24(sp)
    80003570:	6942                	ld	s2,16(sp)
    80003572:	69a2                	ld	s3,8(sp)
    80003574:	6145                	addi	sp,sp,48
    80003576:	8082                	ret

0000000080003578 <ialloc>:
{
    80003578:	715d                	addi	sp,sp,-80
    8000357a:	e486                	sd	ra,72(sp)
    8000357c:	e0a2                	sd	s0,64(sp)
    8000357e:	fc26                	sd	s1,56(sp)
    80003580:	f84a                	sd	s2,48(sp)
    80003582:	f44e                	sd	s3,40(sp)
    80003584:	f052                	sd	s4,32(sp)
    80003586:	ec56                	sd	s5,24(sp)
    80003588:	e85a                	sd	s6,16(sp)
    8000358a:	e45e                	sd	s7,8(sp)
    8000358c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000358e:	0001c717          	auipc	a4,0x1c
    80003592:	22672703          	lw	a4,550(a4) # 8001f7b4 <sb+0xc>
    80003596:	4785                	li	a5,1
    80003598:	04e7fa63          	bgeu	a5,a4,800035ec <ialloc+0x74>
    8000359c:	8aaa                	mv	s5,a0
    8000359e:	8bae                	mv	s7,a1
    800035a0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035a2:	0001ca17          	auipc	s4,0x1c
    800035a6:	206a0a13          	addi	s4,s4,518 # 8001f7a8 <sb>
    800035aa:	00048b1b          	sext.w	s6,s1
    800035ae:	0044d593          	srli	a1,s1,0x4
    800035b2:	018a2783          	lw	a5,24(s4)
    800035b6:	9dbd                	addw	a1,a1,a5
    800035b8:	8556                	mv	a0,s5
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	956080e7          	jalr	-1706(ra) # 80002f10 <bread>
    800035c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035c4:	05850993          	addi	s3,a0,88
    800035c8:	00f4f793          	andi	a5,s1,15
    800035cc:	079a                	slli	a5,a5,0x6
    800035ce:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035d0:	00099783          	lh	a5,0(s3)
    800035d4:	c785                	beqz	a5,800035fc <ialloc+0x84>
    brelse(bp);
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	a6a080e7          	jalr	-1430(ra) # 80003040 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035de:	0485                	addi	s1,s1,1
    800035e0:	00ca2703          	lw	a4,12(s4)
    800035e4:	0004879b          	sext.w	a5,s1
    800035e8:	fce7e1e3          	bltu	a5,a4,800035aa <ialloc+0x32>
  panic("ialloc: no inodes");
    800035ec:	00005517          	auipc	a0,0x5
    800035f0:	fd450513          	addi	a0,a0,-44 # 800085c0 <syscalls+0x178>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	f46080e7          	jalr	-186(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800035fc:	04000613          	li	a2,64
    80003600:	4581                	li	a1,0
    80003602:	854e                	mv	a0,s3
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	712080e7          	jalr	1810(ra) # 80000d16 <memset>
      dip->type = type;
    8000360c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003610:	854a                	mv	a0,s2
    80003612:	00001097          	auipc	ra,0x1
    80003616:	cb2080e7          	jalr	-846(ra) # 800042c4 <log_write>
      brelse(bp);
    8000361a:	854a                	mv	a0,s2
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	a24080e7          	jalr	-1500(ra) # 80003040 <brelse>
      return iget(dev, inum);
    80003624:	85da                	mv	a1,s6
    80003626:	8556                	mv	a0,s5
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	db4080e7          	jalr	-588(ra) # 800033dc <iget>
}
    80003630:	60a6                	ld	ra,72(sp)
    80003632:	6406                	ld	s0,64(sp)
    80003634:	74e2                	ld	s1,56(sp)
    80003636:	7942                	ld	s2,48(sp)
    80003638:	79a2                	ld	s3,40(sp)
    8000363a:	7a02                	ld	s4,32(sp)
    8000363c:	6ae2                	ld	s5,24(sp)
    8000363e:	6b42                	ld	s6,16(sp)
    80003640:	6ba2                	ld	s7,8(sp)
    80003642:	6161                	addi	sp,sp,80
    80003644:	8082                	ret

0000000080003646 <iupdate>:
{
    80003646:	1101                	addi	sp,sp,-32
    80003648:	ec06                	sd	ra,24(sp)
    8000364a:	e822                	sd	s0,16(sp)
    8000364c:	e426                	sd	s1,8(sp)
    8000364e:	e04a                	sd	s2,0(sp)
    80003650:	1000                	addi	s0,sp,32
    80003652:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003654:	415c                	lw	a5,4(a0)
    80003656:	0047d79b          	srliw	a5,a5,0x4
    8000365a:	0001c597          	auipc	a1,0x1c
    8000365e:	1665a583          	lw	a1,358(a1) # 8001f7c0 <sb+0x18>
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	4108                	lw	a0,0(a0)
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	8aa080e7          	jalr	-1878(ra) # 80002f10 <bread>
    8000366e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003670:	05850793          	addi	a5,a0,88
    80003674:	40d8                	lw	a4,4(s1)
    80003676:	8b3d                	andi	a4,a4,15
    80003678:	071a                	slli	a4,a4,0x6
    8000367a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000367c:	04449703          	lh	a4,68(s1)
    80003680:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003684:	04649703          	lh	a4,70(s1)
    80003688:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000368c:	04849703          	lh	a4,72(s1)
    80003690:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003694:	04a49703          	lh	a4,74(s1)
    80003698:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000369c:	44f8                	lw	a4,76(s1)
    8000369e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036a0:	03400613          	li	a2,52
    800036a4:	05048593          	addi	a1,s1,80
    800036a8:	00c78513          	addi	a0,a5,12
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	6c6080e7          	jalr	1734(ra) # 80000d72 <memmove>
  log_write(bp);
    800036b4:	854a                	mv	a0,s2
    800036b6:	00001097          	auipc	ra,0x1
    800036ba:	c0e080e7          	jalr	-1010(ra) # 800042c4 <log_write>
  brelse(bp);
    800036be:	854a                	mv	a0,s2
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	980080e7          	jalr	-1664(ra) # 80003040 <brelse>
}
    800036c8:	60e2                	ld	ra,24(sp)
    800036ca:	6442                	ld	s0,16(sp)
    800036cc:	64a2                	ld	s1,8(sp)
    800036ce:	6902                	ld	s2,0(sp)
    800036d0:	6105                	addi	sp,sp,32
    800036d2:	8082                	ret

00000000800036d4 <idup>:
{
    800036d4:	1101                	addi	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	e426                	sd	s1,8(sp)
    800036dc:	1000                	addi	s0,sp,32
    800036de:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036e0:	0001c517          	auipc	a0,0x1c
    800036e4:	0e850513          	addi	a0,a0,232 # 8001f7c8 <itable>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	532080e7          	jalr	1330(ra) # 80000c1a <acquire>
  ip->ref++;
    800036f0:	449c                	lw	a5,8(s1)
    800036f2:	2785                	addiw	a5,a5,1
    800036f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036f6:	0001c517          	auipc	a0,0x1c
    800036fa:	0d250513          	addi	a0,a0,210 # 8001f7c8 <itable>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	5d0080e7          	jalr	1488(ra) # 80000cce <release>
}
    80003706:	8526                	mv	a0,s1
    80003708:	60e2                	ld	ra,24(sp)
    8000370a:	6442                	ld	s0,16(sp)
    8000370c:	64a2                	ld	s1,8(sp)
    8000370e:	6105                	addi	sp,sp,32
    80003710:	8082                	ret

0000000080003712 <ilock>:
{
    80003712:	1101                	addi	sp,sp,-32
    80003714:	ec06                	sd	ra,24(sp)
    80003716:	e822                	sd	s0,16(sp)
    80003718:	e426                	sd	s1,8(sp)
    8000371a:	e04a                	sd	s2,0(sp)
    8000371c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000371e:	c115                	beqz	a0,80003742 <ilock+0x30>
    80003720:	84aa                	mv	s1,a0
    80003722:	451c                	lw	a5,8(a0)
    80003724:	00f05f63          	blez	a5,80003742 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003728:	0541                	addi	a0,a0,16
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	cb8080e7          	jalr	-840(ra) # 800043e2 <acquiresleep>
  if(ip->valid == 0){
    80003732:	40bc                	lw	a5,64(s1)
    80003734:	cf99                	beqz	a5,80003752 <ilock+0x40>
}
    80003736:	60e2                	ld	ra,24(sp)
    80003738:	6442                	ld	s0,16(sp)
    8000373a:	64a2                	ld	s1,8(sp)
    8000373c:	6902                	ld	s2,0(sp)
    8000373e:	6105                	addi	sp,sp,32
    80003740:	8082                	ret
    panic("ilock");
    80003742:	00005517          	auipc	a0,0x5
    80003746:	e9650513          	addi	a0,a0,-362 # 800085d8 <syscalls+0x190>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	df0080e7          	jalr	-528(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003752:	40dc                	lw	a5,4(s1)
    80003754:	0047d79b          	srliw	a5,a5,0x4
    80003758:	0001c597          	auipc	a1,0x1c
    8000375c:	0685a583          	lw	a1,104(a1) # 8001f7c0 <sb+0x18>
    80003760:	9dbd                	addw	a1,a1,a5
    80003762:	4088                	lw	a0,0(s1)
    80003764:	fffff097          	auipc	ra,0xfffff
    80003768:	7ac080e7          	jalr	1964(ra) # 80002f10 <bread>
    8000376c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000376e:	05850593          	addi	a1,a0,88
    80003772:	40dc                	lw	a5,4(s1)
    80003774:	8bbd                	andi	a5,a5,15
    80003776:	079a                	slli	a5,a5,0x6
    80003778:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000377a:	00059783          	lh	a5,0(a1)
    8000377e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003782:	00259783          	lh	a5,2(a1)
    80003786:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000378a:	00459783          	lh	a5,4(a1)
    8000378e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003792:	00659783          	lh	a5,6(a1)
    80003796:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000379a:	459c                	lw	a5,8(a1)
    8000379c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000379e:	03400613          	li	a2,52
    800037a2:	05b1                	addi	a1,a1,12
    800037a4:	05048513          	addi	a0,s1,80
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	5ca080e7          	jalr	1482(ra) # 80000d72 <memmove>
    brelse(bp);
    800037b0:	854a                	mv	a0,s2
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	88e080e7          	jalr	-1906(ra) # 80003040 <brelse>
    ip->valid = 1;
    800037ba:	4785                	li	a5,1
    800037bc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037be:	04449783          	lh	a5,68(s1)
    800037c2:	fbb5                	bnez	a5,80003736 <ilock+0x24>
      panic("ilock: no type");
    800037c4:	00005517          	auipc	a0,0x5
    800037c8:	e1c50513          	addi	a0,a0,-484 # 800085e0 <syscalls+0x198>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	d6e080e7          	jalr	-658(ra) # 8000053a <panic>

00000000800037d4 <iunlock>:
{
    800037d4:	1101                	addi	sp,sp,-32
    800037d6:	ec06                	sd	ra,24(sp)
    800037d8:	e822                	sd	s0,16(sp)
    800037da:	e426                	sd	s1,8(sp)
    800037dc:	e04a                	sd	s2,0(sp)
    800037de:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037e0:	c905                	beqz	a0,80003810 <iunlock+0x3c>
    800037e2:	84aa                	mv	s1,a0
    800037e4:	01050913          	addi	s2,a0,16
    800037e8:	854a                	mv	a0,s2
    800037ea:	00001097          	auipc	ra,0x1
    800037ee:	c92080e7          	jalr	-878(ra) # 8000447c <holdingsleep>
    800037f2:	cd19                	beqz	a0,80003810 <iunlock+0x3c>
    800037f4:	449c                	lw	a5,8(s1)
    800037f6:	00f05d63          	blez	a5,80003810 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037fa:	854a                	mv	a0,s2
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	c3c080e7          	jalr	-964(ra) # 80004438 <releasesleep>
}
    80003804:	60e2                	ld	ra,24(sp)
    80003806:	6442                	ld	s0,16(sp)
    80003808:	64a2                	ld	s1,8(sp)
    8000380a:	6902                	ld	s2,0(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret
    panic("iunlock");
    80003810:	00005517          	auipc	a0,0x5
    80003814:	de050513          	addi	a0,a0,-544 # 800085f0 <syscalls+0x1a8>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	d22080e7          	jalr	-734(ra) # 8000053a <panic>

0000000080003820 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003820:	7179                	addi	sp,sp,-48
    80003822:	f406                	sd	ra,40(sp)
    80003824:	f022                	sd	s0,32(sp)
    80003826:	ec26                	sd	s1,24(sp)
    80003828:	e84a                	sd	s2,16(sp)
    8000382a:	e44e                	sd	s3,8(sp)
    8000382c:	e052                	sd	s4,0(sp)
    8000382e:	1800                	addi	s0,sp,48
    80003830:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003832:	05050493          	addi	s1,a0,80
    80003836:	08050913          	addi	s2,a0,128
    8000383a:	a021                	j	80003842 <itrunc+0x22>
    8000383c:	0491                	addi	s1,s1,4
    8000383e:	01248d63          	beq	s1,s2,80003858 <itrunc+0x38>
    if(ip->addrs[i]){
    80003842:	408c                	lw	a1,0(s1)
    80003844:	dde5                	beqz	a1,8000383c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003846:	0009a503          	lw	a0,0(s3)
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	90c080e7          	jalr	-1780(ra) # 80003156 <bfree>
      ip->addrs[i] = 0;
    80003852:	0004a023          	sw	zero,0(s1)
    80003856:	b7dd                	j	8000383c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003858:	0809a583          	lw	a1,128(s3)
    8000385c:	e185                	bnez	a1,8000387c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000385e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003862:	854e                	mv	a0,s3
    80003864:	00000097          	auipc	ra,0x0
    80003868:	de2080e7          	jalr	-542(ra) # 80003646 <iupdate>
}
    8000386c:	70a2                	ld	ra,40(sp)
    8000386e:	7402                	ld	s0,32(sp)
    80003870:	64e2                	ld	s1,24(sp)
    80003872:	6942                	ld	s2,16(sp)
    80003874:	69a2                	ld	s3,8(sp)
    80003876:	6a02                	ld	s4,0(sp)
    80003878:	6145                	addi	sp,sp,48
    8000387a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000387c:	0009a503          	lw	a0,0(s3)
    80003880:	fffff097          	auipc	ra,0xfffff
    80003884:	690080e7          	jalr	1680(ra) # 80002f10 <bread>
    80003888:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000388a:	05850493          	addi	s1,a0,88
    8000388e:	45850913          	addi	s2,a0,1112
    80003892:	a021                	j	8000389a <itrunc+0x7a>
    80003894:	0491                	addi	s1,s1,4
    80003896:	01248b63          	beq	s1,s2,800038ac <itrunc+0x8c>
      if(a[j])
    8000389a:	408c                	lw	a1,0(s1)
    8000389c:	dde5                	beqz	a1,80003894 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000389e:	0009a503          	lw	a0,0(s3)
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	8b4080e7          	jalr	-1868(ra) # 80003156 <bfree>
    800038aa:	b7ed                	j	80003894 <itrunc+0x74>
    brelse(bp);
    800038ac:	8552                	mv	a0,s4
    800038ae:	fffff097          	auipc	ra,0xfffff
    800038b2:	792080e7          	jalr	1938(ra) # 80003040 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038b6:	0809a583          	lw	a1,128(s3)
    800038ba:	0009a503          	lw	a0,0(s3)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	898080e7          	jalr	-1896(ra) # 80003156 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038c6:	0809a023          	sw	zero,128(s3)
    800038ca:	bf51                	j	8000385e <itrunc+0x3e>

00000000800038cc <iput>:
{
    800038cc:	1101                	addi	sp,sp,-32
    800038ce:	ec06                	sd	ra,24(sp)
    800038d0:	e822                	sd	s0,16(sp)
    800038d2:	e426                	sd	s1,8(sp)
    800038d4:	e04a                	sd	s2,0(sp)
    800038d6:	1000                	addi	s0,sp,32
    800038d8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038da:	0001c517          	auipc	a0,0x1c
    800038de:	eee50513          	addi	a0,a0,-274 # 8001f7c8 <itable>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	338080e7          	jalr	824(ra) # 80000c1a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ea:	4498                	lw	a4,8(s1)
    800038ec:	4785                	li	a5,1
    800038ee:	02f70363          	beq	a4,a5,80003914 <iput+0x48>
  ip->ref--;
    800038f2:	449c                	lw	a5,8(s1)
    800038f4:	37fd                	addiw	a5,a5,-1
    800038f6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f8:	0001c517          	auipc	a0,0x1c
    800038fc:	ed050513          	addi	a0,a0,-304 # 8001f7c8 <itable>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	3ce080e7          	jalr	974(ra) # 80000cce <release>
}
    80003908:	60e2                	ld	ra,24(sp)
    8000390a:	6442                	ld	s0,16(sp)
    8000390c:	64a2                	ld	s1,8(sp)
    8000390e:	6902                	ld	s2,0(sp)
    80003910:	6105                	addi	sp,sp,32
    80003912:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003914:	40bc                	lw	a5,64(s1)
    80003916:	dff1                	beqz	a5,800038f2 <iput+0x26>
    80003918:	04a49783          	lh	a5,74(s1)
    8000391c:	fbf9                	bnez	a5,800038f2 <iput+0x26>
    acquiresleep(&ip->lock);
    8000391e:	01048913          	addi	s2,s1,16
    80003922:	854a                	mv	a0,s2
    80003924:	00001097          	auipc	ra,0x1
    80003928:	abe080e7          	jalr	-1346(ra) # 800043e2 <acquiresleep>
    release(&itable.lock);
    8000392c:	0001c517          	auipc	a0,0x1c
    80003930:	e9c50513          	addi	a0,a0,-356 # 8001f7c8 <itable>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	39a080e7          	jalr	922(ra) # 80000cce <release>
    itrunc(ip);
    8000393c:	8526                	mv	a0,s1
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	ee2080e7          	jalr	-286(ra) # 80003820 <itrunc>
    ip->type = 0;
    80003946:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000394a:	8526                	mv	a0,s1
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	cfa080e7          	jalr	-774(ra) # 80003646 <iupdate>
    ip->valid = 0;
    80003954:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003958:	854a                	mv	a0,s2
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	ade080e7          	jalr	-1314(ra) # 80004438 <releasesleep>
    acquire(&itable.lock);
    80003962:	0001c517          	auipc	a0,0x1c
    80003966:	e6650513          	addi	a0,a0,-410 # 8001f7c8 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	2b0080e7          	jalr	688(ra) # 80000c1a <acquire>
    80003972:	b741                	j	800038f2 <iput+0x26>

0000000080003974 <iunlockput>:
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	1000                	addi	s0,sp,32
    8000397e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003980:	00000097          	auipc	ra,0x0
    80003984:	e54080e7          	jalr	-428(ra) # 800037d4 <iunlock>
  iput(ip);
    80003988:	8526                	mv	a0,s1
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	f42080e7          	jalr	-190(ra) # 800038cc <iput>
}
    80003992:	60e2                	ld	ra,24(sp)
    80003994:	6442                	ld	s0,16(sp)
    80003996:	64a2                	ld	s1,8(sp)
    80003998:	6105                	addi	sp,sp,32
    8000399a:	8082                	ret

000000008000399c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000399c:	1141                	addi	sp,sp,-16
    8000399e:	e422                	sd	s0,8(sp)
    800039a0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039a2:	411c                	lw	a5,0(a0)
    800039a4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039a6:	415c                	lw	a5,4(a0)
    800039a8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039aa:	04451783          	lh	a5,68(a0)
    800039ae:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039b2:	04a51783          	lh	a5,74(a0)
    800039b6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039ba:	04c56783          	lwu	a5,76(a0)
    800039be:	e99c                	sd	a5,16(a1)
}
    800039c0:	6422                	ld	s0,8(sp)
    800039c2:	0141                	addi	sp,sp,16
    800039c4:	8082                	ret

00000000800039c6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039c6:	457c                	lw	a5,76(a0)
    800039c8:	0ed7e963          	bltu	a5,a3,80003aba <readi+0xf4>
{
    800039cc:	7159                	addi	sp,sp,-112
    800039ce:	f486                	sd	ra,104(sp)
    800039d0:	f0a2                	sd	s0,96(sp)
    800039d2:	eca6                	sd	s1,88(sp)
    800039d4:	e8ca                	sd	s2,80(sp)
    800039d6:	e4ce                	sd	s3,72(sp)
    800039d8:	e0d2                	sd	s4,64(sp)
    800039da:	fc56                	sd	s5,56(sp)
    800039dc:	f85a                	sd	s6,48(sp)
    800039de:	f45e                	sd	s7,40(sp)
    800039e0:	f062                	sd	s8,32(sp)
    800039e2:	ec66                	sd	s9,24(sp)
    800039e4:	e86a                	sd	s10,16(sp)
    800039e6:	e46e                	sd	s11,8(sp)
    800039e8:	1880                	addi	s0,sp,112
    800039ea:	8baa                	mv	s7,a0
    800039ec:	8c2e                	mv	s8,a1
    800039ee:	8ab2                	mv	s5,a2
    800039f0:	84b6                	mv	s1,a3
    800039f2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039f4:	9f35                	addw	a4,a4,a3
    return 0;
    800039f6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039f8:	0ad76063          	bltu	a4,a3,80003a98 <readi+0xd2>
  if(off + n > ip->size)
    800039fc:	00e7f463          	bgeu	a5,a4,80003a04 <readi+0x3e>
    n = ip->size - off;
    80003a00:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a04:	0a0b0963          	beqz	s6,80003ab6 <readi+0xf0>
    80003a08:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a0a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a0e:	5cfd                	li	s9,-1
    80003a10:	a82d                	j	80003a4a <readi+0x84>
    80003a12:	020a1d93          	slli	s11,s4,0x20
    80003a16:	020ddd93          	srli	s11,s11,0x20
    80003a1a:	05890613          	addi	a2,s2,88
    80003a1e:	86ee                	mv	a3,s11
    80003a20:	963a                	add	a2,a2,a4
    80003a22:	85d6                	mv	a1,s5
    80003a24:	8562                	mv	a0,s8
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	a22080e7          	jalr	-1502(ra) # 80002448 <either_copyout>
    80003a2e:	05950d63          	beq	a0,s9,80003a88 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a32:	854a                	mv	a0,s2
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	60c080e7          	jalr	1548(ra) # 80003040 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3c:	013a09bb          	addw	s3,s4,s3
    80003a40:	009a04bb          	addw	s1,s4,s1
    80003a44:	9aee                	add	s5,s5,s11
    80003a46:	0569f763          	bgeu	s3,s6,80003a94 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a4a:	000ba903          	lw	s2,0(s7)
    80003a4e:	00a4d59b          	srliw	a1,s1,0xa
    80003a52:	855e                	mv	a0,s7
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	8ac080e7          	jalr	-1876(ra) # 80003300 <bmap>
    80003a5c:	0005059b          	sext.w	a1,a0
    80003a60:	854a                	mv	a0,s2
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	4ae080e7          	jalr	1198(ra) # 80002f10 <bread>
    80003a6a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6c:	3ff4f713          	andi	a4,s1,1023
    80003a70:	40ed07bb          	subw	a5,s10,a4
    80003a74:	413b06bb          	subw	a3,s6,s3
    80003a78:	8a3e                	mv	s4,a5
    80003a7a:	2781                	sext.w	a5,a5
    80003a7c:	0006861b          	sext.w	a2,a3
    80003a80:	f8f679e3          	bgeu	a2,a5,80003a12 <readi+0x4c>
    80003a84:	8a36                	mv	s4,a3
    80003a86:	b771                	j	80003a12 <readi+0x4c>
      brelse(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	5b6080e7          	jalr	1462(ra) # 80003040 <brelse>
      tot = -1;
    80003a92:	59fd                	li	s3,-1
  }
  return tot;
    80003a94:	0009851b          	sext.w	a0,s3
}
    80003a98:	70a6                	ld	ra,104(sp)
    80003a9a:	7406                	ld	s0,96(sp)
    80003a9c:	64e6                	ld	s1,88(sp)
    80003a9e:	6946                	ld	s2,80(sp)
    80003aa0:	69a6                	ld	s3,72(sp)
    80003aa2:	6a06                	ld	s4,64(sp)
    80003aa4:	7ae2                	ld	s5,56(sp)
    80003aa6:	7b42                	ld	s6,48(sp)
    80003aa8:	7ba2                	ld	s7,40(sp)
    80003aaa:	7c02                	ld	s8,32(sp)
    80003aac:	6ce2                	ld	s9,24(sp)
    80003aae:	6d42                	ld	s10,16(sp)
    80003ab0:	6da2                	ld	s11,8(sp)
    80003ab2:	6165                	addi	sp,sp,112
    80003ab4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab6:	89da                	mv	s3,s6
    80003ab8:	bff1                	j	80003a94 <readi+0xce>
    return 0;
    80003aba:	4501                	li	a0,0
}
    80003abc:	8082                	ret

0000000080003abe <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003abe:	457c                	lw	a5,76(a0)
    80003ac0:	10d7e863          	bltu	a5,a3,80003bd0 <writei+0x112>
{
    80003ac4:	7159                	addi	sp,sp,-112
    80003ac6:	f486                	sd	ra,104(sp)
    80003ac8:	f0a2                	sd	s0,96(sp)
    80003aca:	eca6                	sd	s1,88(sp)
    80003acc:	e8ca                	sd	s2,80(sp)
    80003ace:	e4ce                	sd	s3,72(sp)
    80003ad0:	e0d2                	sd	s4,64(sp)
    80003ad2:	fc56                	sd	s5,56(sp)
    80003ad4:	f85a                	sd	s6,48(sp)
    80003ad6:	f45e                	sd	s7,40(sp)
    80003ad8:	f062                	sd	s8,32(sp)
    80003ada:	ec66                	sd	s9,24(sp)
    80003adc:	e86a                	sd	s10,16(sp)
    80003ade:	e46e                	sd	s11,8(sp)
    80003ae0:	1880                	addi	s0,sp,112
    80003ae2:	8b2a                	mv	s6,a0
    80003ae4:	8c2e                	mv	s8,a1
    80003ae6:	8ab2                	mv	s5,a2
    80003ae8:	8936                	mv	s2,a3
    80003aea:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003aec:	00e687bb          	addw	a5,a3,a4
    80003af0:	0ed7e263          	bltu	a5,a3,80003bd4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003af4:	00043737          	lui	a4,0x43
    80003af8:	0ef76063          	bltu	a4,a5,80003bd8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003afc:	0c0b8863          	beqz	s7,80003bcc <writei+0x10e>
    80003b00:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b02:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b06:	5cfd                	li	s9,-1
    80003b08:	a091                	j	80003b4c <writei+0x8e>
    80003b0a:	02099d93          	slli	s11,s3,0x20
    80003b0e:	020ddd93          	srli	s11,s11,0x20
    80003b12:	05848513          	addi	a0,s1,88
    80003b16:	86ee                	mv	a3,s11
    80003b18:	8656                	mv	a2,s5
    80003b1a:	85e2                	mv	a1,s8
    80003b1c:	953a                	add	a0,a0,a4
    80003b1e:	fffff097          	auipc	ra,0xfffff
    80003b22:	980080e7          	jalr	-1664(ra) # 8000249e <either_copyin>
    80003b26:	07950263          	beq	a0,s9,80003b8a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	798080e7          	jalr	1944(ra) # 800042c4 <log_write>
    brelse(bp);
    80003b34:	8526                	mv	a0,s1
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	50a080e7          	jalr	1290(ra) # 80003040 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b3e:	01498a3b          	addw	s4,s3,s4
    80003b42:	0129893b          	addw	s2,s3,s2
    80003b46:	9aee                	add	s5,s5,s11
    80003b48:	057a7663          	bgeu	s4,s7,80003b94 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b4c:	000b2483          	lw	s1,0(s6)
    80003b50:	00a9559b          	srliw	a1,s2,0xa
    80003b54:	855a                	mv	a0,s6
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	7aa080e7          	jalr	1962(ra) # 80003300 <bmap>
    80003b5e:	0005059b          	sext.w	a1,a0
    80003b62:	8526                	mv	a0,s1
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	3ac080e7          	jalr	940(ra) # 80002f10 <bread>
    80003b6c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6e:	3ff97713          	andi	a4,s2,1023
    80003b72:	40ed07bb          	subw	a5,s10,a4
    80003b76:	414b86bb          	subw	a3,s7,s4
    80003b7a:	89be                	mv	s3,a5
    80003b7c:	2781                	sext.w	a5,a5
    80003b7e:	0006861b          	sext.w	a2,a3
    80003b82:	f8f674e3          	bgeu	a2,a5,80003b0a <writei+0x4c>
    80003b86:	89b6                	mv	s3,a3
    80003b88:	b749                	j	80003b0a <writei+0x4c>
      brelse(bp);
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	4b4080e7          	jalr	1204(ra) # 80003040 <brelse>
  }

  if(off > ip->size)
    80003b94:	04cb2783          	lw	a5,76(s6)
    80003b98:	0127f463          	bgeu	a5,s2,80003ba0 <writei+0xe2>
    ip->size = off;
    80003b9c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ba0:	855a                	mv	a0,s6
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	aa4080e7          	jalr	-1372(ra) # 80003646 <iupdate>

  return tot;
    80003baa:	000a051b          	sext.w	a0,s4
}
    80003bae:	70a6                	ld	ra,104(sp)
    80003bb0:	7406                	ld	s0,96(sp)
    80003bb2:	64e6                	ld	s1,88(sp)
    80003bb4:	6946                	ld	s2,80(sp)
    80003bb6:	69a6                	ld	s3,72(sp)
    80003bb8:	6a06                	ld	s4,64(sp)
    80003bba:	7ae2                	ld	s5,56(sp)
    80003bbc:	7b42                	ld	s6,48(sp)
    80003bbe:	7ba2                	ld	s7,40(sp)
    80003bc0:	7c02                	ld	s8,32(sp)
    80003bc2:	6ce2                	ld	s9,24(sp)
    80003bc4:	6d42                	ld	s10,16(sp)
    80003bc6:	6da2                	ld	s11,8(sp)
    80003bc8:	6165                	addi	sp,sp,112
    80003bca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bcc:	8a5e                	mv	s4,s7
    80003bce:	bfc9                	j	80003ba0 <writei+0xe2>
    return -1;
    80003bd0:	557d                	li	a0,-1
}
    80003bd2:	8082                	ret
    return -1;
    80003bd4:	557d                	li	a0,-1
    80003bd6:	bfe1                	j	80003bae <writei+0xf0>
    return -1;
    80003bd8:	557d                	li	a0,-1
    80003bda:	bfd1                	j	80003bae <writei+0xf0>

0000000080003bdc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bdc:	1141                	addi	sp,sp,-16
    80003bde:	e406                	sd	ra,8(sp)
    80003be0:	e022                	sd	s0,0(sp)
    80003be2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003be4:	4639                	li	a2,14
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	200080e7          	jalr	512(ra) # 80000de6 <strncmp>
}
    80003bee:	60a2                	ld	ra,8(sp)
    80003bf0:	6402                	ld	s0,0(sp)
    80003bf2:	0141                	addi	sp,sp,16
    80003bf4:	8082                	ret

0000000080003bf6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bf6:	7139                	addi	sp,sp,-64
    80003bf8:	fc06                	sd	ra,56(sp)
    80003bfa:	f822                	sd	s0,48(sp)
    80003bfc:	f426                	sd	s1,40(sp)
    80003bfe:	f04a                	sd	s2,32(sp)
    80003c00:	ec4e                	sd	s3,24(sp)
    80003c02:	e852                	sd	s4,16(sp)
    80003c04:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c06:	04451703          	lh	a4,68(a0)
    80003c0a:	4785                	li	a5,1
    80003c0c:	00f71a63          	bne	a4,a5,80003c20 <dirlookup+0x2a>
    80003c10:	892a                	mv	s2,a0
    80003c12:	89ae                	mv	s3,a1
    80003c14:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c16:	457c                	lw	a5,76(a0)
    80003c18:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c1a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c1c:	e79d                	bnez	a5,80003c4a <dirlookup+0x54>
    80003c1e:	a8a5                	j	80003c96 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c20:	00005517          	auipc	a0,0x5
    80003c24:	9d850513          	addi	a0,a0,-1576 # 800085f8 <syscalls+0x1b0>
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	912080e7          	jalr	-1774(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003c30:	00005517          	auipc	a0,0x5
    80003c34:	9e050513          	addi	a0,a0,-1568 # 80008610 <syscalls+0x1c8>
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	902080e7          	jalr	-1790(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c40:	24c1                	addiw	s1,s1,16
    80003c42:	04c92783          	lw	a5,76(s2)
    80003c46:	04f4f763          	bgeu	s1,a5,80003c94 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c4a:	4741                	li	a4,16
    80003c4c:	86a6                	mv	a3,s1
    80003c4e:	fc040613          	addi	a2,s0,-64
    80003c52:	4581                	li	a1,0
    80003c54:	854a                	mv	a0,s2
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	d70080e7          	jalr	-656(ra) # 800039c6 <readi>
    80003c5e:	47c1                	li	a5,16
    80003c60:	fcf518e3          	bne	a0,a5,80003c30 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c64:	fc045783          	lhu	a5,-64(s0)
    80003c68:	dfe1                	beqz	a5,80003c40 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c6a:	fc240593          	addi	a1,s0,-62
    80003c6e:	854e                	mv	a0,s3
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	f6c080e7          	jalr	-148(ra) # 80003bdc <namecmp>
    80003c78:	f561                	bnez	a0,80003c40 <dirlookup+0x4a>
      if(poff)
    80003c7a:	000a0463          	beqz	s4,80003c82 <dirlookup+0x8c>
        *poff = off;
    80003c7e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c82:	fc045583          	lhu	a1,-64(s0)
    80003c86:	00092503          	lw	a0,0(s2)
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	752080e7          	jalr	1874(ra) # 800033dc <iget>
    80003c92:	a011                	j	80003c96 <dirlookup+0xa0>
  return 0;
    80003c94:	4501                	li	a0,0
}
    80003c96:	70e2                	ld	ra,56(sp)
    80003c98:	7442                	ld	s0,48(sp)
    80003c9a:	74a2                	ld	s1,40(sp)
    80003c9c:	7902                	ld	s2,32(sp)
    80003c9e:	69e2                	ld	s3,24(sp)
    80003ca0:	6a42                	ld	s4,16(sp)
    80003ca2:	6121                	addi	sp,sp,64
    80003ca4:	8082                	ret

0000000080003ca6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ca6:	711d                	addi	sp,sp,-96
    80003ca8:	ec86                	sd	ra,88(sp)
    80003caa:	e8a2                	sd	s0,80(sp)
    80003cac:	e4a6                	sd	s1,72(sp)
    80003cae:	e0ca                	sd	s2,64(sp)
    80003cb0:	fc4e                	sd	s3,56(sp)
    80003cb2:	f852                	sd	s4,48(sp)
    80003cb4:	f456                	sd	s5,40(sp)
    80003cb6:	f05a                	sd	s6,32(sp)
    80003cb8:	ec5e                	sd	s7,24(sp)
    80003cba:	e862                	sd	s8,16(sp)
    80003cbc:	e466                	sd	s9,8(sp)
    80003cbe:	e06a                	sd	s10,0(sp)
    80003cc0:	1080                	addi	s0,sp,96
    80003cc2:	84aa                	mv	s1,a0
    80003cc4:	8b2e                	mv	s6,a1
    80003cc6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cc8:	00054703          	lbu	a4,0(a0)
    80003ccc:	02f00793          	li	a5,47
    80003cd0:	02f70363          	beq	a4,a5,80003cf6 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cd4:	ffffe097          	auipc	ra,0xffffe
    80003cd8:	d0c080e7          	jalr	-756(ra) # 800019e0 <myproc>
    80003cdc:	15053503          	ld	a0,336(a0)
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	9f4080e7          	jalr	-1548(ra) # 800036d4 <idup>
    80003ce8:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cea:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cee:	4cb5                	li	s9,13
  len = path - s;
    80003cf0:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cf2:	4c05                	li	s8,1
    80003cf4:	a87d                	j	80003db2 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003cf6:	4585                	li	a1,1
    80003cf8:	4505                	li	a0,1
    80003cfa:	fffff097          	auipc	ra,0xfffff
    80003cfe:	6e2080e7          	jalr	1762(ra) # 800033dc <iget>
    80003d02:	8a2a                	mv	s4,a0
    80003d04:	b7dd                	j	80003cea <namex+0x44>
      iunlockput(ip);
    80003d06:	8552                	mv	a0,s4
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	c6c080e7          	jalr	-916(ra) # 80003974 <iunlockput>
      return 0;
    80003d10:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d12:	8552                	mv	a0,s4
    80003d14:	60e6                	ld	ra,88(sp)
    80003d16:	6446                	ld	s0,80(sp)
    80003d18:	64a6                	ld	s1,72(sp)
    80003d1a:	6906                	ld	s2,64(sp)
    80003d1c:	79e2                	ld	s3,56(sp)
    80003d1e:	7a42                	ld	s4,48(sp)
    80003d20:	7aa2                	ld	s5,40(sp)
    80003d22:	7b02                	ld	s6,32(sp)
    80003d24:	6be2                	ld	s7,24(sp)
    80003d26:	6c42                	ld	s8,16(sp)
    80003d28:	6ca2                	ld	s9,8(sp)
    80003d2a:	6d02                	ld	s10,0(sp)
    80003d2c:	6125                	addi	sp,sp,96
    80003d2e:	8082                	ret
      iunlock(ip);
    80003d30:	8552                	mv	a0,s4
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	aa2080e7          	jalr	-1374(ra) # 800037d4 <iunlock>
      return ip;
    80003d3a:	bfe1                	j	80003d12 <namex+0x6c>
      iunlockput(ip);
    80003d3c:	8552                	mv	a0,s4
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	c36080e7          	jalr	-970(ra) # 80003974 <iunlockput>
      return 0;
    80003d46:	8a4e                	mv	s4,s3
    80003d48:	b7e9                	j	80003d12 <namex+0x6c>
  len = path - s;
    80003d4a:	40998633          	sub	a2,s3,s1
    80003d4e:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d52:	09acd863          	bge	s9,s10,80003de2 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d56:	4639                	li	a2,14
    80003d58:	85a6                	mv	a1,s1
    80003d5a:	8556                	mv	a0,s5
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	016080e7          	jalr	22(ra) # 80000d72 <memmove>
    80003d64:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d66:	0004c783          	lbu	a5,0(s1)
    80003d6a:	01279763          	bne	a5,s2,80003d78 <namex+0xd2>
    path++;
    80003d6e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d70:	0004c783          	lbu	a5,0(s1)
    80003d74:	ff278de3          	beq	a5,s2,80003d6e <namex+0xc8>
    ilock(ip);
    80003d78:	8552                	mv	a0,s4
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	998080e7          	jalr	-1640(ra) # 80003712 <ilock>
    if(ip->type != T_DIR){
    80003d82:	044a1783          	lh	a5,68(s4)
    80003d86:	f98790e3          	bne	a5,s8,80003d06 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d8a:	000b0563          	beqz	s6,80003d94 <namex+0xee>
    80003d8e:	0004c783          	lbu	a5,0(s1)
    80003d92:	dfd9                	beqz	a5,80003d30 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d94:	865e                	mv	a2,s7
    80003d96:	85d6                	mv	a1,s5
    80003d98:	8552                	mv	a0,s4
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	e5c080e7          	jalr	-420(ra) # 80003bf6 <dirlookup>
    80003da2:	89aa                	mv	s3,a0
    80003da4:	dd41                	beqz	a0,80003d3c <namex+0x96>
    iunlockput(ip);
    80003da6:	8552                	mv	a0,s4
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	bcc080e7          	jalr	-1076(ra) # 80003974 <iunlockput>
    ip = next;
    80003db0:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003db2:	0004c783          	lbu	a5,0(s1)
    80003db6:	01279763          	bne	a5,s2,80003dc4 <namex+0x11e>
    path++;
    80003dba:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	ff278de3          	beq	a5,s2,80003dba <namex+0x114>
  if(*path == 0)
    80003dc4:	cb9d                	beqz	a5,80003dfa <namex+0x154>
  while(*path != '/' && *path != 0)
    80003dc6:	0004c783          	lbu	a5,0(s1)
    80003dca:	89a6                	mv	s3,s1
  len = path - s;
    80003dcc:	8d5e                	mv	s10,s7
    80003dce:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dd0:	01278963          	beq	a5,s2,80003de2 <namex+0x13c>
    80003dd4:	dbbd                	beqz	a5,80003d4a <namex+0xa4>
    path++;
    80003dd6:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003dd8:	0009c783          	lbu	a5,0(s3)
    80003ddc:	ff279ce3          	bne	a5,s2,80003dd4 <namex+0x12e>
    80003de0:	b7ad                	j	80003d4a <namex+0xa4>
    memmove(name, s, len);
    80003de2:	2601                	sext.w	a2,a2
    80003de4:	85a6                	mv	a1,s1
    80003de6:	8556                	mv	a0,s5
    80003de8:	ffffd097          	auipc	ra,0xffffd
    80003dec:	f8a080e7          	jalr	-118(ra) # 80000d72 <memmove>
    name[len] = 0;
    80003df0:	9d56                	add	s10,s10,s5
    80003df2:	000d0023          	sb	zero,0(s10)
    80003df6:	84ce                	mv	s1,s3
    80003df8:	b7bd                	j	80003d66 <namex+0xc0>
  if(nameiparent){
    80003dfa:	f00b0ce3          	beqz	s6,80003d12 <namex+0x6c>
    iput(ip);
    80003dfe:	8552                	mv	a0,s4
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	acc080e7          	jalr	-1332(ra) # 800038cc <iput>
    return 0;
    80003e08:	4a01                	li	s4,0
    80003e0a:	b721                	j	80003d12 <namex+0x6c>

0000000080003e0c <dirlink>:
{
    80003e0c:	7139                	addi	sp,sp,-64
    80003e0e:	fc06                	sd	ra,56(sp)
    80003e10:	f822                	sd	s0,48(sp)
    80003e12:	f426                	sd	s1,40(sp)
    80003e14:	f04a                	sd	s2,32(sp)
    80003e16:	ec4e                	sd	s3,24(sp)
    80003e18:	e852                	sd	s4,16(sp)
    80003e1a:	0080                	addi	s0,sp,64
    80003e1c:	892a                	mv	s2,a0
    80003e1e:	8a2e                	mv	s4,a1
    80003e20:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e22:	4601                	li	a2,0
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	dd2080e7          	jalr	-558(ra) # 80003bf6 <dirlookup>
    80003e2c:	e93d                	bnez	a0,80003ea2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2e:	04c92483          	lw	s1,76(s2)
    80003e32:	c49d                	beqz	s1,80003e60 <dirlink+0x54>
    80003e34:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e36:	4741                	li	a4,16
    80003e38:	86a6                	mv	a3,s1
    80003e3a:	fc040613          	addi	a2,s0,-64
    80003e3e:	4581                	li	a1,0
    80003e40:	854a                	mv	a0,s2
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	b84080e7          	jalr	-1148(ra) # 800039c6 <readi>
    80003e4a:	47c1                	li	a5,16
    80003e4c:	06f51163          	bne	a0,a5,80003eae <dirlink+0xa2>
    if(de.inum == 0)
    80003e50:	fc045783          	lhu	a5,-64(s0)
    80003e54:	c791                	beqz	a5,80003e60 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e56:	24c1                	addiw	s1,s1,16
    80003e58:	04c92783          	lw	a5,76(s2)
    80003e5c:	fcf4ede3          	bltu	s1,a5,80003e36 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e60:	4639                	li	a2,14
    80003e62:	85d2                	mv	a1,s4
    80003e64:	fc240513          	addi	a0,s0,-62
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	fba080e7          	jalr	-70(ra) # 80000e22 <strncpy>
  de.inum = inum;
    80003e70:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e74:	4741                	li	a4,16
    80003e76:	86a6                	mv	a3,s1
    80003e78:	fc040613          	addi	a2,s0,-64
    80003e7c:	4581                	li	a1,0
    80003e7e:	854a                	mv	a0,s2
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	c3e080e7          	jalr	-962(ra) # 80003abe <writei>
    80003e88:	872a                	mv	a4,a0
    80003e8a:	47c1                	li	a5,16
  return 0;
    80003e8c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8e:	02f71863          	bne	a4,a5,80003ebe <dirlink+0xb2>
}
    80003e92:	70e2                	ld	ra,56(sp)
    80003e94:	7442                	ld	s0,48(sp)
    80003e96:	74a2                	ld	s1,40(sp)
    80003e98:	7902                	ld	s2,32(sp)
    80003e9a:	69e2                	ld	s3,24(sp)
    80003e9c:	6a42                	ld	s4,16(sp)
    80003e9e:	6121                	addi	sp,sp,64
    80003ea0:	8082                	ret
    iput(ip);
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	a2a080e7          	jalr	-1494(ra) # 800038cc <iput>
    return -1;
    80003eaa:	557d                	li	a0,-1
    80003eac:	b7dd                	j	80003e92 <dirlink+0x86>
      panic("dirlink read");
    80003eae:	00004517          	auipc	a0,0x4
    80003eb2:	77250513          	addi	a0,a0,1906 # 80008620 <syscalls+0x1d8>
    80003eb6:	ffffc097          	auipc	ra,0xffffc
    80003eba:	684080e7          	jalr	1668(ra) # 8000053a <panic>
    panic("dirlink");
    80003ebe:	00005517          	auipc	a0,0x5
    80003ec2:	87250513          	addi	a0,a0,-1934 # 80008730 <syscalls+0x2e8>
    80003ec6:	ffffc097          	auipc	ra,0xffffc
    80003eca:	674080e7          	jalr	1652(ra) # 8000053a <panic>

0000000080003ece <namei>:

struct inode*
namei(char *path)
{
    80003ece:	1101                	addi	sp,sp,-32
    80003ed0:	ec06                	sd	ra,24(sp)
    80003ed2:	e822                	sd	s0,16(sp)
    80003ed4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ed6:	fe040613          	addi	a2,s0,-32
    80003eda:	4581                	li	a1,0
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	dca080e7          	jalr	-566(ra) # 80003ca6 <namex>
}
    80003ee4:	60e2                	ld	ra,24(sp)
    80003ee6:	6442                	ld	s0,16(sp)
    80003ee8:	6105                	addi	sp,sp,32
    80003eea:	8082                	ret

0000000080003eec <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003eec:	1141                	addi	sp,sp,-16
    80003eee:	e406                	sd	ra,8(sp)
    80003ef0:	e022                	sd	s0,0(sp)
    80003ef2:	0800                	addi	s0,sp,16
    80003ef4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ef6:	4585                	li	a1,1
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	dae080e7          	jalr	-594(ra) # 80003ca6 <namex>
}
    80003f00:	60a2                	ld	ra,8(sp)
    80003f02:	6402                	ld	s0,0(sp)
    80003f04:	0141                	addi	sp,sp,16
    80003f06:	8082                	ret

0000000080003f08 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f08:	1101                	addi	sp,sp,-32
    80003f0a:	ec06                	sd	ra,24(sp)
    80003f0c:	e822                	sd	s0,16(sp)
    80003f0e:	e426                	sd	s1,8(sp)
    80003f10:	e04a                	sd	s2,0(sp)
    80003f12:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f14:	0001d917          	auipc	s2,0x1d
    80003f18:	35c90913          	addi	s2,s2,860 # 80021270 <log>
    80003f1c:	01892583          	lw	a1,24(s2)
    80003f20:	02892503          	lw	a0,40(s2)
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	fec080e7          	jalr	-20(ra) # 80002f10 <bread>
    80003f2c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f2e:	02c92683          	lw	a3,44(s2)
    80003f32:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f34:	02d05863          	blez	a3,80003f64 <write_head+0x5c>
    80003f38:	0001d797          	auipc	a5,0x1d
    80003f3c:	36878793          	addi	a5,a5,872 # 800212a0 <log+0x30>
    80003f40:	05c50713          	addi	a4,a0,92
    80003f44:	36fd                	addiw	a3,a3,-1
    80003f46:	02069613          	slli	a2,a3,0x20
    80003f4a:	01e65693          	srli	a3,a2,0x1e
    80003f4e:	0001d617          	auipc	a2,0x1d
    80003f52:	35660613          	addi	a2,a2,854 # 800212a4 <log+0x34>
    80003f56:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f58:	4390                	lw	a2,0(a5)
    80003f5a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f5c:	0791                	addi	a5,a5,4
    80003f5e:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f60:	fed79ce3          	bne	a5,a3,80003f58 <write_head+0x50>
  }
  bwrite(buf);
    80003f64:	8526                	mv	a0,s1
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	09c080e7          	jalr	156(ra) # 80003002 <bwrite>
  brelse(buf);
    80003f6e:	8526                	mv	a0,s1
    80003f70:	fffff097          	auipc	ra,0xfffff
    80003f74:	0d0080e7          	jalr	208(ra) # 80003040 <brelse>
}
    80003f78:	60e2                	ld	ra,24(sp)
    80003f7a:	6442                	ld	s0,16(sp)
    80003f7c:	64a2                	ld	s1,8(sp)
    80003f7e:	6902                	ld	s2,0(sp)
    80003f80:	6105                	addi	sp,sp,32
    80003f82:	8082                	ret

0000000080003f84 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f84:	0001d797          	auipc	a5,0x1d
    80003f88:	3187a783          	lw	a5,792(a5) # 8002129c <log+0x2c>
    80003f8c:	0af05d63          	blez	a5,80004046 <install_trans+0xc2>
{
    80003f90:	7139                	addi	sp,sp,-64
    80003f92:	fc06                	sd	ra,56(sp)
    80003f94:	f822                	sd	s0,48(sp)
    80003f96:	f426                	sd	s1,40(sp)
    80003f98:	f04a                	sd	s2,32(sp)
    80003f9a:	ec4e                	sd	s3,24(sp)
    80003f9c:	e852                	sd	s4,16(sp)
    80003f9e:	e456                	sd	s5,8(sp)
    80003fa0:	e05a                	sd	s6,0(sp)
    80003fa2:	0080                	addi	s0,sp,64
    80003fa4:	8b2a                	mv	s6,a0
    80003fa6:	0001da97          	auipc	s5,0x1d
    80003faa:	2faa8a93          	addi	s5,s5,762 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fae:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fb0:	0001d997          	auipc	s3,0x1d
    80003fb4:	2c098993          	addi	s3,s3,704 # 80021270 <log>
    80003fb8:	a00d                	j	80003fda <install_trans+0x56>
    brelse(lbuf);
    80003fba:	854a                	mv	a0,s2
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	084080e7          	jalr	132(ra) # 80003040 <brelse>
    brelse(dbuf);
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	07a080e7          	jalr	122(ra) # 80003040 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fce:	2a05                	addiw	s4,s4,1
    80003fd0:	0a91                	addi	s5,s5,4
    80003fd2:	02c9a783          	lw	a5,44(s3)
    80003fd6:	04fa5e63          	bge	s4,a5,80004032 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fda:	0189a583          	lw	a1,24(s3)
    80003fde:	014585bb          	addw	a1,a1,s4
    80003fe2:	2585                	addiw	a1,a1,1
    80003fe4:	0289a503          	lw	a0,40(s3)
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	f28080e7          	jalr	-216(ra) # 80002f10 <bread>
    80003ff0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ff2:	000aa583          	lw	a1,0(s5)
    80003ff6:	0289a503          	lw	a0,40(s3)
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	f16080e7          	jalr	-234(ra) # 80002f10 <bread>
    80004002:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004004:	40000613          	li	a2,1024
    80004008:	05890593          	addi	a1,s2,88
    8000400c:	05850513          	addi	a0,a0,88
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	d62080e7          	jalr	-670(ra) # 80000d72 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004018:	8526                	mv	a0,s1
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	fe8080e7          	jalr	-24(ra) # 80003002 <bwrite>
    if(recovering == 0)
    80004022:	f80b1ce3          	bnez	s6,80003fba <install_trans+0x36>
      bunpin(dbuf);
    80004026:	8526                	mv	a0,s1
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	0f2080e7          	jalr	242(ra) # 8000311a <bunpin>
    80004030:	b769                	j	80003fba <install_trans+0x36>
}
    80004032:	70e2                	ld	ra,56(sp)
    80004034:	7442                	ld	s0,48(sp)
    80004036:	74a2                	ld	s1,40(sp)
    80004038:	7902                	ld	s2,32(sp)
    8000403a:	69e2                	ld	s3,24(sp)
    8000403c:	6a42                	ld	s4,16(sp)
    8000403e:	6aa2                	ld	s5,8(sp)
    80004040:	6b02                	ld	s6,0(sp)
    80004042:	6121                	addi	sp,sp,64
    80004044:	8082                	ret
    80004046:	8082                	ret

0000000080004048 <initlog>:
{
    80004048:	7179                	addi	sp,sp,-48
    8000404a:	f406                	sd	ra,40(sp)
    8000404c:	f022                	sd	s0,32(sp)
    8000404e:	ec26                	sd	s1,24(sp)
    80004050:	e84a                	sd	s2,16(sp)
    80004052:	e44e                	sd	s3,8(sp)
    80004054:	1800                	addi	s0,sp,48
    80004056:	892a                	mv	s2,a0
    80004058:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000405a:	0001d497          	auipc	s1,0x1d
    8000405e:	21648493          	addi	s1,s1,534 # 80021270 <log>
    80004062:	00004597          	auipc	a1,0x4
    80004066:	5ce58593          	addi	a1,a1,1486 # 80008630 <syscalls+0x1e8>
    8000406a:	8526                	mv	a0,s1
    8000406c:	ffffd097          	auipc	ra,0xffffd
    80004070:	b1e080e7          	jalr	-1250(ra) # 80000b8a <initlock>
  log.start = sb->logstart;
    80004074:	0149a583          	lw	a1,20(s3)
    80004078:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000407a:	0109a783          	lw	a5,16(s3)
    8000407e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004080:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004084:	854a                	mv	a0,s2
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	e8a080e7          	jalr	-374(ra) # 80002f10 <bread>
  log.lh.n = lh->n;
    8000408e:	4d34                	lw	a3,88(a0)
    80004090:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004092:	02d05663          	blez	a3,800040be <initlog+0x76>
    80004096:	05c50793          	addi	a5,a0,92
    8000409a:	0001d717          	auipc	a4,0x1d
    8000409e:	20670713          	addi	a4,a4,518 # 800212a0 <log+0x30>
    800040a2:	36fd                	addiw	a3,a3,-1
    800040a4:	02069613          	slli	a2,a3,0x20
    800040a8:	01e65693          	srli	a3,a2,0x1e
    800040ac:	06050613          	addi	a2,a0,96
    800040b0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040b2:	4390                	lw	a2,0(a5)
    800040b4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040b6:	0791                	addi	a5,a5,4
    800040b8:	0711                	addi	a4,a4,4
    800040ba:	fed79ce3          	bne	a5,a3,800040b2 <initlog+0x6a>
  brelse(buf);
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	f82080e7          	jalr	-126(ra) # 80003040 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040c6:	4505                	li	a0,1
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	ebc080e7          	jalr	-324(ra) # 80003f84 <install_trans>
  log.lh.n = 0;
    800040d0:	0001d797          	auipc	a5,0x1d
    800040d4:	1c07a623          	sw	zero,460(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	e30080e7          	jalr	-464(ra) # 80003f08 <write_head>
}
    800040e0:	70a2                	ld	ra,40(sp)
    800040e2:	7402                	ld	s0,32(sp)
    800040e4:	64e2                	ld	s1,24(sp)
    800040e6:	6942                	ld	s2,16(sp)
    800040e8:	69a2                	ld	s3,8(sp)
    800040ea:	6145                	addi	sp,sp,48
    800040ec:	8082                	ret

00000000800040ee <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040ee:	1101                	addi	sp,sp,-32
    800040f0:	ec06                	sd	ra,24(sp)
    800040f2:	e822                	sd	s0,16(sp)
    800040f4:	e426                	sd	s1,8(sp)
    800040f6:	e04a                	sd	s2,0(sp)
    800040f8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040fa:	0001d517          	auipc	a0,0x1d
    800040fe:	17650513          	addi	a0,a0,374 # 80021270 <log>
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	b18080e7          	jalr	-1256(ra) # 80000c1a <acquire>
  while(1){
    if(log.committing){
    8000410a:	0001d497          	auipc	s1,0x1d
    8000410e:	16648493          	addi	s1,s1,358 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004112:	4979                	li	s2,30
    80004114:	a039                	j	80004122 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004116:	85a6                	mv	a1,s1
    80004118:	8526                	mv	a0,s1
    8000411a:	ffffe097          	auipc	ra,0xffffe
    8000411e:	f8a080e7          	jalr	-118(ra) # 800020a4 <sleep>
    if(log.committing){
    80004122:	50dc                	lw	a5,36(s1)
    80004124:	fbed                	bnez	a5,80004116 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004126:	5098                	lw	a4,32(s1)
    80004128:	2705                	addiw	a4,a4,1
    8000412a:	0007069b          	sext.w	a3,a4
    8000412e:	0027179b          	slliw	a5,a4,0x2
    80004132:	9fb9                	addw	a5,a5,a4
    80004134:	0017979b          	slliw	a5,a5,0x1
    80004138:	54d8                	lw	a4,44(s1)
    8000413a:	9fb9                	addw	a5,a5,a4
    8000413c:	00f95963          	bge	s2,a5,8000414e <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004140:	85a6                	mv	a1,s1
    80004142:	8526                	mv	a0,s1
    80004144:	ffffe097          	auipc	ra,0xffffe
    80004148:	f60080e7          	jalr	-160(ra) # 800020a4 <sleep>
    8000414c:	bfd9                	j	80004122 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000414e:	0001d517          	auipc	a0,0x1d
    80004152:	12250513          	addi	a0,a0,290 # 80021270 <log>
    80004156:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	b76080e7          	jalr	-1162(ra) # 80000cce <release>
      break;
    }
  }
}
    80004160:	60e2                	ld	ra,24(sp)
    80004162:	6442                	ld	s0,16(sp)
    80004164:	64a2                	ld	s1,8(sp)
    80004166:	6902                	ld	s2,0(sp)
    80004168:	6105                	addi	sp,sp,32
    8000416a:	8082                	ret

000000008000416c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000416c:	7139                	addi	sp,sp,-64
    8000416e:	fc06                	sd	ra,56(sp)
    80004170:	f822                	sd	s0,48(sp)
    80004172:	f426                	sd	s1,40(sp)
    80004174:	f04a                	sd	s2,32(sp)
    80004176:	ec4e                	sd	s3,24(sp)
    80004178:	e852                	sd	s4,16(sp)
    8000417a:	e456                	sd	s5,8(sp)
    8000417c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000417e:	0001d497          	auipc	s1,0x1d
    80004182:	0f248493          	addi	s1,s1,242 # 80021270 <log>
    80004186:	8526                	mv	a0,s1
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	a92080e7          	jalr	-1390(ra) # 80000c1a <acquire>
  log.outstanding -= 1;
    80004190:	509c                	lw	a5,32(s1)
    80004192:	37fd                	addiw	a5,a5,-1
    80004194:	0007891b          	sext.w	s2,a5
    80004198:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000419a:	50dc                	lw	a5,36(s1)
    8000419c:	e7b9                	bnez	a5,800041ea <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000419e:	04091e63          	bnez	s2,800041fa <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041a2:	0001d497          	auipc	s1,0x1d
    800041a6:	0ce48493          	addi	s1,s1,206 # 80021270 <log>
    800041aa:	4785                	li	a5,1
    800041ac:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	b1e080e7          	jalr	-1250(ra) # 80000cce <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041b8:	54dc                	lw	a5,44(s1)
    800041ba:	06f04763          	bgtz	a5,80004228 <end_op+0xbc>
    acquire(&log.lock);
    800041be:	0001d497          	auipc	s1,0x1d
    800041c2:	0b248493          	addi	s1,s1,178 # 80021270 <log>
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	a52080e7          	jalr	-1454(ra) # 80000c1a <acquire>
    log.committing = 0;
    800041d0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffe097          	auipc	ra,0xffffe
    800041da:	05a080e7          	jalr	90(ra) # 80002230 <wakeup>
    release(&log.lock);
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	aee080e7          	jalr	-1298(ra) # 80000cce <release>
}
    800041e8:	a03d                	j	80004216 <end_op+0xaa>
    panic("log.committing");
    800041ea:	00004517          	auipc	a0,0x4
    800041ee:	44e50513          	addi	a0,a0,1102 # 80008638 <syscalls+0x1f0>
    800041f2:	ffffc097          	auipc	ra,0xffffc
    800041f6:	348080e7          	jalr	840(ra) # 8000053a <panic>
    wakeup(&log);
    800041fa:	0001d497          	auipc	s1,0x1d
    800041fe:	07648493          	addi	s1,s1,118 # 80021270 <log>
    80004202:	8526                	mv	a0,s1
    80004204:	ffffe097          	auipc	ra,0xffffe
    80004208:	02c080e7          	jalr	44(ra) # 80002230 <wakeup>
  release(&log.lock);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	ac0080e7          	jalr	-1344(ra) # 80000cce <release>
}
    80004216:	70e2                	ld	ra,56(sp)
    80004218:	7442                	ld	s0,48(sp)
    8000421a:	74a2                	ld	s1,40(sp)
    8000421c:	7902                	ld	s2,32(sp)
    8000421e:	69e2                	ld	s3,24(sp)
    80004220:	6a42                	ld	s4,16(sp)
    80004222:	6aa2                	ld	s5,8(sp)
    80004224:	6121                	addi	sp,sp,64
    80004226:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004228:	0001da97          	auipc	s5,0x1d
    8000422c:	078a8a93          	addi	s5,s5,120 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004230:	0001da17          	auipc	s4,0x1d
    80004234:	040a0a13          	addi	s4,s4,64 # 80021270 <log>
    80004238:	018a2583          	lw	a1,24(s4)
    8000423c:	012585bb          	addw	a1,a1,s2
    80004240:	2585                	addiw	a1,a1,1
    80004242:	028a2503          	lw	a0,40(s4)
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	cca080e7          	jalr	-822(ra) # 80002f10 <bread>
    8000424e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004250:	000aa583          	lw	a1,0(s5)
    80004254:	028a2503          	lw	a0,40(s4)
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	cb8080e7          	jalr	-840(ra) # 80002f10 <bread>
    80004260:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004262:	40000613          	li	a2,1024
    80004266:	05850593          	addi	a1,a0,88
    8000426a:	05848513          	addi	a0,s1,88
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	b04080e7          	jalr	-1276(ra) # 80000d72 <memmove>
    bwrite(to);  // write the log
    80004276:	8526                	mv	a0,s1
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	d8a080e7          	jalr	-630(ra) # 80003002 <bwrite>
    brelse(from);
    80004280:	854e                	mv	a0,s3
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	dbe080e7          	jalr	-578(ra) # 80003040 <brelse>
    brelse(to);
    8000428a:	8526                	mv	a0,s1
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	db4080e7          	jalr	-588(ra) # 80003040 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004294:	2905                	addiw	s2,s2,1
    80004296:	0a91                	addi	s5,s5,4
    80004298:	02ca2783          	lw	a5,44(s4)
    8000429c:	f8f94ee3          	blt	s2,a5,80004238 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	c68080e7          	jalr	-920(ra) # 80003f08 <write_head>
    install_trans(0); // Now install writes to home locations
    800042a8:	4501                	li	a0,0
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	cda080e7          	jalr	-806(ra) # 80003f84 <install_trans>
    log.lh.n = 0;
    800042b2:	0001d797          	auipc	a5,0x1d
    800042b6:	fe07a523          	sw	zero,-22(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	c4e080e7          	jalr	-946(ra) # 80003f08 <write_head>
    800042c2:	bdf5                	j	800041be <end_op+0x52>

00000000800042c4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042c4:	1101                	addi	sp,sp,-32
    800042c6:	ec06                	sd	ra,24(sp)
    800042c8:	e822                	sd	s0,16(sp)
    800042ca:	e426                	sd	s1,8(sp)
    800042cc:	e04a                	sd	s2,0(sp)
    800042ce:	1000                	addi	s0,sp,32
    800042d0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042d2:	0001d917          	auipc	s2,0x1d
    800042d6:	f9e90913          	addi	s2,s2,-98 # 80021270 <log>
    800042da:	854a                	mv	a0,s2
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	93e080e7          	jalr	-1730(ra) # 80000c1a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042e4:	02c92603          	lw	a2,44(s2)
    800042e8:	47f5                	li	a5,29
    800042ea:	06c7c563          	blt	a5,a2,80004354 <log_write+0x90>
    800042ee:	0001d797          	auipc	a5,0x1d
    800042f2:	f9e7a783          	lw	a5,-98(a5) # 8002128c <log+0x1c>
    800042f6:	37fd                	addiw	a5,a5,-1
    800042f8:	04f65e63          	bge	a2,a5,80004354 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042fc:	0001d797          	auipc	a5,0x1d
    80004300:	f947a783          	lw	a5,-108(a5) # 80021290 <log+0x20>
    80004304:	06f05063          	blez	a5,80004364 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004308:	4781                	li	a5,0
    8000430a:	06c05563          	blez	a2,80004374 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000430e:	44cc                	lw	a1,12(s1)
    80004310:	0001d717          	auipc	a4,0x1d
    80004314:	f9070713          	addi	a4,a4,-112 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004318:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000431a:	4314                	lw	a3,0(a4)
    8000431c:	04b68c63          	beq	a3,a1,80004374 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004320:	2785                	addiw	a5,a5,1
    80004322:	0711                	addi	a4,a4,4
    80004324:	fef61be3          	bne	a2,a5,8000431a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004328:	0621                	addi	a2,a2,8
    8000432a:	060a                	slli	a2,a2,0x2
    8000432c:	0001d797          	auipc	a5,0x1d
    80004330:	f4478793          	addi	a5,a5,-188 # 80021270 <log>
    80004334:	97b2                	add	a5,a5,a2
    80004336:	44d8                	lw	a4,12(s1)
    80004338:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000433a:	8526                	mv	a0,s1
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	da2080e7          	jalr	-606(ra) # 800030de <bpin>
    log.lh.n++;
    80004344:	0001d717          	auipc	a4,0x1d
    80004348:	f2c70713          	addi	a4,a4,-212 # 80021270 <log>
    8000434c:	575c                	lw	a5,44(a4)
    8000434e:	2785                	addiw	a5,a5,1
    80004350:	d75c                	sw	a5,44(a4)
    80004352:	a82d                	j	8000438c <log_write+0xc8>
    panic("too big a transaction");
    80004354:	00004517          	auipc	a0,0x4
    80004358:	2f450513          	addi	a0,a0,756 # 80008648 <syscalls+0x200>
    8000435c:	ffffc097          	auipc	ra,0xffffc
    80004360:	1de080e7          	jalr	478(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004364:	00004517          	auipc	a0,0x4
    80004368:	2fc50513          	addi	a0,a0,764 # 80008660 <syscalls+0x218>
    8000436c:	ffffc097          	auipc	ra,0xffffc
    80004370:	1ce080e7          	jalr	462(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004374:	00878693          	addi	a3,a5,8
    80004378:	068a                	slli	a3,a3,0x2
    8000437a:	0001d717          	auipc	a4,0x1d
    8000437e:	ef670713          	addi	a4,a4,-266 # 80021270 <log>
    80004382:	9736                	add	a4,a4,a3
    80004384:	44d4                	lw	a3,12(s1)
    80004386:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004388:	faf609e3          	beq	a2,a5,8000433a <log_write+0x76>
  }
  release(&log.lock);
    8000438c:	0001d517          	auipc	a0,0x1d
    80004390:	ee450513          	addi	a0,a0,-284 # 80021270 <log>
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	93a080e7          	jalr	-1734(ra) # 80000cce <release>
}
    8000439c:	60e2                	ld	ra,24(sp)
    8000439e:	6442                	ld	s0,16(sp)
    800043a0:	64a2                	ld	s1,8(sp)
    800043a2:	6902                	ld	s2,0(sp)
    800043a4:	6105                	addi	sp,sp,32
    800043a6:	8082                	ret

00000000800043a8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043a8:	1101                	addi	sp,sp,-32
    800043aa:	ec06                	sd	ra,24(sp)
    800043ac:	e822                	sd	s0,16(sp)
    800043ae:	e426                	sd	s1,8(sp)
    800043b0:	e04a                	sd	s2,0(sp)
    800043b2:	1000                	addi	s0,sp,32
    800043b4:	84aa                	mv	s1,a0
    800043b6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043b8:	00004597          	auipc	a1,0x4
    800043bc:	2c858593          	addi	a1,a1,712 # 80008680 <syscalls+0x238>
    800043c0:	0521                	addi	a0,a0,8
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	7c8080e7          	jalr	1992(ra) # 80000b8a <initlock>
  lk->name = name;
    800043ca:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043ce:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043d2:	0204a423          	sw	zero,40(s1)
}
    800043d6:	60e2                	ld	ra,24(sp)
    800043d8:	6442                	ld	s0,16(sp)
    800043da:	64a2                	ld	s1,8(sp)
    800043dc:	6902                	ld	s2,0(sp)
    800043de:	6105                	addi	sp,sp,32
    800043e0:	8082                	ret

00000000800043e2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043e2:	1101                	addi	sp,sp,-32
    800043e4:	ec06                	sd	ra,24(sp)
    800043e6:	e822                	sd	s0,16(sp)
    800043e8:	e426                	sd	s1,8(sp)
    800043ea:	e04a                	sd	s2,0(sp)
    800043ec:	1000                	addi	s0,sp,32
    800043ee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043f0:	00850913          	addi	s2,a0,8
    800043f4:	854a                	mv	a0,s2
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	824080e7          	jalr	-2012(ra) # 80000c1a <acquire>
  while (lk->locked) {
    800043fe:	409c                	lw	a5,0(s1)
    80004400:	cb89                	beqz	a5,80004412 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004402:	85ca                	mv	a1,s2
    80004404:	8526                	mv	a0,s1
    80004406:	ffffe097          	auipc	ra,0xffffe
    8000440a:	c9e080e7          	jalr	-866(ra) # 800020a4 <sleep>
  while (lk->locked) {
    8000440e:	409c                	lw	a5,0(s1)
    80004410:	fbed                	bnez	a5,80004402 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004412:	4785                	li	a5,1
    80004414:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	5ca080e7          	jalr	1482(ra) # 800019e0 <myproc>
    8000441e:	591c                	lw	a5,48(a0)
    80004420:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004422:	854a                	mv	a0,s2
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	8aa080e7          	jalr	-1878(ra) # 80000cce <release>
}
    8000442c:	60e2                	ld	ra,24(sp)
    8000442e:	6442                	ld	s0,16(sp)
    80004430:	64a2                	ld	s1,8(sp)
    80004432:	6902                	ld	s2,0(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004438:	1101                	addi	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	e426                	sd	s1,8(sp)
    80004440:	e04a                	sd	s2,0(sp)
    80004442:	1000                	addi	s0,sp,32
    80004444:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004446:	00850913          	addi	s2,a0,8
    8000444a:	854a                	mv	a0,s2
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	7ce080e7          	jalr	1998(ra) # 80000c1a <acquire>
  lk->locked = 0;
    80004454:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004458:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffe097          	auipc	ra,0xffffe
    80004462:	dd2080e7          	jalr	-558(ra) # 80002230 <wakeup>
  release(&lk->lk);
    80004466:	854a                	mv	a0,s2
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	866080e7          	jalr	-1946(ra) # 80000cce <release>
}
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6902                	ld	s2,0(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret

000000008000447c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000447c:	7179                	addi	sp,sp,-48
    8000447e:	f406                	sd	ra,40(sp)
    80004480:	f022                	sd	s0,32(sp)
    80004482:	ec26                	sd	s1,24(sp)
    80004484:	e84a                	sd	s2,16(sp)
    80004486:	e44e                	sd	s3,8(sp)
    80004488:	1800                	addi	s0,sp,48
    8000448a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000448c:	00850913          	addi	s2,a0,8
    80004490:	854a                	mv	a0,s2
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	788080e7          	jalr	1928(ra) # 80000c1a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000449a:	409c                	lw	a5,0(s1)
    8000449c:	ef99                	bnez	a5,800044ba <holdingsleep+0x3e>
    8000449e:	4481                	li	s1,0
  release(&lk->lk);
    800044a0:	854a                	mv	a0,s2
    800044a2:	ffffd097          	auipc	ra,0xffffd
    800044a6:	82c080e7          	jalr	-2004(ra) # 80000cce <release>
  return r;
}
    800044aa:	8526                	mv	a0,s1
    800044ac:	70a2                	ld	ra,40(sp)
    800044ae:	7402                	ld	s0,32(sp)
    800044b0:	64e2                	ld	s1,24(sp)
    800044b2:	6942                	ld	s2,16(sp)
    800044b4:	69a2                	ld	s3,8(sp)
    800044b6:	6145                	addi	sp,sp,48
    800044b8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ba:	0284a983          	lw	s3,40(s1)
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	522080e7          	jalr	1314(ra) # 800019e0 <myproc>
    800044c6:	5904                	lw	s1,48(a0)
    800044c8:	413484b3          	sub	s1,s1,s3
    800044cc:	0014b493          	seqz	s1,s1
    800044d0:	bfc1                	j	800044a0 <holdingsleep+0x24>

00000000800044d2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044d2:	1141                	addi	sp,sp,-16
    800044d4:	e406                	sd	ra,8(sp)
    800044d6:	e022                	sd	s0,0(sp)
    800044d8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044da:	00004597          	auipc	a1,0x4
    800044de:	1b658593          	addi	a1,a1,438 # 80008690 <syscalls+0x248>
    800044e2:	0001d517          	auipc	a0,0x1d
    800044e6:	ed650513          	addi	a0,a0,-298 # 800213b8 <ftable>
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	6a0080e7          	jalr	1696(ra) # 80000b8a <initlock>
}
    800044f2:	60a2                	ld	ra,8(sp)
    800044f4:	6402                	ld	s0,0(sp)
    800044f6:	0141                	addi	sp,sp,16
    800044f8:	8082                	ret

00000000800044fa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044fa:	1101                	addi	sp,sp,-32
    800044fc:	ec06                	sd	ra,24(sp)
    800044fe:	e822                	sd	s0,16(sp)
    80004500:	e426                	sd	s1,8(sp)
    80004502:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004504:	0001d517          	auipc	a0,0x1d
    80004508:	eb450513          	addi	a0,a0,-332 # 800213b8 <ftable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	70e080e7          	jalr	1806(ra) # 80000c1a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004514:	0001d497          	auipc	s1,0x1d
    80004518:	ebc48493          	addi	s1,s1,-324 # 800213d0 <ftable+0x18>
    8000451c:	0001e717          	auipc	a4,0x1e
    80004520:	e5470713          	addi	a4,a4,-428 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004524:	40dc                	lw	a5,4(s1)
    80004526:	cf99                	beqz	a5,80004544 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004528:	02848493          	addi	s1,s1,40
    8000452c:	fee49ce3          	bne	s1,a4,80004524 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004530:	0001d517          	auipc	a0,0x1d
    80004534:	e8850513          	addi	a0,a0,-376 # 800213b8 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	796080e7          	jalr	1942(ra) # 80000cce <release>
  return 0;
    80004540:	4481                	li	s1,0
    80004542:	a819                	j	80004558 <filealloc+0x5e>
      f->ref = 1;
    80004544:	4785                	li	a5,1
    80004546:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004548:	0001d517          	auipc	a0,0x1d
    8000454c:	e7050513          	addi	a0,a0,-400 # 800213b8 <ftable>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	77e080e7          	jalr	1918(ra) # 80000cce <release>
}
    80004558:	8526                	mv	a0,s1
    8000455a:	60e2                	ld	ra,24(sp)
    8000455c:	6442                	ld	s0,16(sp)
    8000455e:	64a2                	ld	s1,8(sp)
    80004560:	6105                	addi	sp,sp,32
    80004562:	8082                	ret

0000000080004564 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	e426                	sd	s1,8(sp)
    8000456c:	1000                	addi	s0,sp,32
    8000456e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	e4850513          	addi	a0,a0,-440 # 800213b8 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	6a2080e7          	jalr	1698(ra) # 80000c1a <acquire>
  if(f->ref < 1)
    80004580:	40dc                	lw	a5,4(s1)
    80004582:	02f05263          	blez	a5,800045a6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004586:	2785                	addiw	a5,a5,1
    80004588:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000458a:	0001d517          	auipc	a0,0x1d
    8000458e:	e2e50513          	addi	a0,a0,-466 # 800213b8 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	73c080e7          	jalr	1852(ra) # 80000cce <release>
  return f;
}
    8000459a:	8526                	mv	a0,s1
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret
    panic("filedup");
    800045a6:	00004517          	auipc	a0,0x4
    800045aa:	0f250513          	addi	a0,a0,242 # 80008698 <syscalls+0x250>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	f8c080e7          	jalr	-116(ra) # 8000053a <panic>

00000000800045b6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045b6:	7139                	addi	sp,sp,-64
    800045b8:	fc06                	sd	ra,56(sp)
    800045ba:	f822                	sd	s0,48(sp)
    800045bc:	f426                	sd	s1,40(sp)
    800045be:	f04a                	sd	s2,32(sp)
    800045c0:	ec4e                	sd	s3,24(sp)
    800045c2:	e852                	sd	s4,16(sp)
    800045c4:	e456                	sd	s5,8(sp)
    800045c6:	0080                	addi	s0,sp,64
    800045c8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ca:	0001d517          	auipc	a0,0x1d
    800045ce:	dee50513          	addi	a0,a0,-530 # 800213b8 <ftable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	648080e7          	jalr	1608(ra) # 80000c1a <acquire>
  if(f->ref < 1)
    800045da:	40dc                	lw	a5,4(s1)
    800045dc:	06f05163          	blez	a5,8000463e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045e0:	37fd                	addiw	a5,a5,-1
    800045e2:	0007871b          	sext.w	a4,a5
    800045e6:	c0dc                	sw	a5,4(s1)
    800045e8:	06e04363          	bgtz	a4,8000464e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045ec:	0004a903          	lw	s2,0(s1)
    800045f0:	0094ca83          	lbu	s5,9(s1)
    800045f4:	0104ba03          	ld	s4,16(s1)
    800045f8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045fc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004600:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004604:	0001d517          	auipc	a0,0x1d
    80004608:	db450513          	addi	a0,a0,-588 # 800213b8 <ftable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	6c2080e7          	jalr	1730(ra) # 80000cce <release>

  if(ff.type == FD_PIPE){
    80004614:	4785                	li	a5,1
    80004616:	04f90d63          	beq	s2,a5,80004670 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000461a:	3979                	addiw	s2,s2,-2
    8000461c:	4785                	li	a5,1
    8000461e:	0527e063          	bltu	a5,s2,8000465e <fileclose+0xa8>
    begin_op();
    80004622:	00000097          	auipc	ra,0x0
    80004626:	acc080e7          	jalr	-1332(ra) # 800040ee <begin_op>
    iput(ff.ip);
    8000462a:	854e                	mv	a0,s3
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	2a0080e7          	jalr	672(ra) # 800038cc <iput>
    end_op();
    80004634:	00000097          	auipc	ra,0x0
    80004638:	b38080e7          	jalr	-1224(ra) # 8000416c <end_op>
    8000463c:	a00d                	j	8000465e <fileclose+0xa8>
    panic("fileclose");
    8000463e:	00004517          	auipc	a0,0x4
    80004642:	06250513          	addi	a0,a0,98 # 800086a0 <syscalls+0x258>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	ef4080e7          	jalr	-268(ra) # 8000053a <panic>
    release(&ftable.lock);
    8000464e:	0001d517          	auipc	a0,0x1d
    80004652:	d6a50513          	addi	a0,a0,-662 # 800213b8 <ftable>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	678080e7          	jalr	1656(ra) # 80000cce <release>
  }
}
    8000465e:	70e2                	ld	ra,56(sp)
    80004660:	7442                	ld	s0,48(sp)
    80004662:	74a2                	ld	s1,40(sp)
    80004664:	7902                	ld	s2,32(sp)
    80004666:	69e2                	ld	s3,24(sp)
    80004668:	6a42                	ld	s4,16(sp)
    8000466a:	6aa2                	ld	s5,8(sp)
    8000466c:	6121                	addi	sp,sp,64
    8000466e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004670:	85d6                	mv	a1,s5
    80004672:	8552                	mv	a0,s4
    80004674:	00000097          	auipc	ra,0x0
    80004678:	34c080e7          	jalr	844(ra) # 800049c0 <pipeclose>
    8000467c:	b7cd                	j	8000465e <fileclose+0xa8>

000000008000467e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000467e:	715d                	addi	sp,sp,-80
    80004680:	e486                	sd	ra,72(sp)
    80004682:	e0a2                	sd	s0,64(sp)
    80004684:	fc26                	sd	s1,56(sp)
    80004686:	f84a                	sd	s2,48(sp)
    80004688:	f44e                	sd	s3,40(sp)
    8000468a:	0880                	addi	s0,sp,80
    8000468c:	84aa                	mv	s1,a0
    8000468e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004690:	ffffd097          	auipc	ra,0xffffd
    80004694:	350080e7          	jalr	848(ra) # 800019e0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004698:	409c                	lw	a5,0(s1)
    8000469a:	37f9                	addiw	a5,a5,-2
    8000469c:	4705                	li	a4,1
    8000469e:	04f76763          	bltu	a4,a5,800046ec <filestat+0x6e>
    800046a2:	892a                	mv	s2,a0
    ilock(f->ip);
    800046a4:	6c88                	ld	a0,24(s1)
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	06c080e7          	jalr	108(ra) # 80003712 <ilock>
    stati(f->ip, &st);
    800046ae:	fb840593          	addi	a1,s0,-72
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	2e8080e7          	jalr	744(ra) # 8000399c <stati>
    iunlock(f->ip);
    800046bc:	6c88                	ld	a0,24(s1)
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	116080e7          	jalr	278(ra) # 800037d4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046c6:	46e1                	li	a3,24
    800046c8:	fb840613          	addi	a2,s0,-72
    800046cc:	85ce                	mv	a1,s3
    800046ce:	05093503          	ld	a0,80(s2)
    800046d2:	ffffd097          	auipc	ra,0xffffd
    800046d6:	fd2080e7          	jalr	-46(ra) # 800016a4 <copyout>
    800046da:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046de:	60a6                	ld	ra,72(sp)
    800046e0:	6406                	ld	s0,64(sp)
    800046e2:	74e2                	ld	s1,56(sp)
    800046e4:	7942                	ld	s2,48(sp)
    800046e6:	79a2                	ld	s3,40(sp)
    800046e8:	6161                	addi	sp,sp,80
    800046ea:	8082                	ret
  return -1;
    800046ec:	557d                	li	a0,-1
    800046ee:	bfc5                	j	800046de <filestat+0x60>

00000000800046f0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046f0:	7179                	addi	sp,sp,-48
    800046f2:	f406                	sd	ra,40(sp)
    800046f4:	f022                	sd	s0,32(sp)
    800046f6:	ec26                	sd	s1,24(sp)
    800046f8:	e84a                	sd	s2,16(sp)
    800046fa:	e44e                	sd	s3,8(sp)
    800046fc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046fe:	00854783          	lbu	a5,8(a0)
    80004702:	c3d5                	beqz	a5,800047a6 <fileread+0xb6>
    80004704:	84aa                	mv	s1,a0
    80004706:	89ae                	mv	s3,a1
    80004708:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000470a:	411c                	lw	a5,0(a0)
    8000470c:	4705                	li	a4,1
    8000470e:	04e78963          	beq	a5,a4,80004760 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004712:	470d                	li	a4,3
    80004714:	04e78d63          	beq	a5,a4,8000476e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004718:	4709                	li	a4,2
    8000471a:	06e79e63          	bne	a5,a4,80004796 <fileread+0xa6>
    ilock(f->ip);
    8000471e:	6d08                	ld	a0,24(a0)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	ff2080e7          	jalr	-14(ra) # 80003712 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004728:	874a                	mv	a4,s2
    8000472a:	5094                	lw	a3,32(s1)
    8000472c:	864e                	mv	a2,s3
    8000472e:	4585                	li	a1,1
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	294080e7          	jalr	660(ra) # 800039c6 <readi>
    8000473a:	892a                	mv	s2,a0
    8000473c:	00a05563          	blez	a0,80004746 <fileread+0x56>
      f->off += r;
    80004740:	509c                	lw	a5,32(s1)
    80004742:	9fa9                	addw	a5,a5,a0
    80004744:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	08c080e7          	jalr	140(ra) # 800037d4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004750:	854a                	mv	a0,s2
    80004752:	70a2                	ld	ra,40(sp)
    80004754:	7402                	ld	s0,32(sp)
    80004756:	64e2                	ld	s1,24(sp)
    80004758:	6942                	ld	s2,16(sp)
    8000475a:	69a2                	ld	s3,8(sp)
    8000475c:	6145                	addi	sp,sp,48
    8000475e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004760:	6908                	ld	a0,16(a0)
    80004762:	00000097          	auipc	ra,0x0
    80004766:	3c0080e7          	jalr	960(ra) # 80004b22 <piperead>
    8000476a:	892a                	mv	s2,a0
    8000476c:	b7d5                	j	80004750 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000476e:	02451783          	lh	a5,36(a0)
    80004772:	03079693          	slli	a3,a5,0x30
    80004776:	92c1                	srli	a3,a3,0x30
    80004778:	4725                	li	a4,9
    8000477a:	02d76863          	bltu	a4,a3,800047aa <fileread+0xba>
    8000477e:	0792                	slli	a5,a5,0x4
    80004780:	0001d717          	auipc	a4,0x1d
    80004784:	b9870713          	addi	a4,a4,-1128 # 80021318 <devsw>
    80004788:	97ba                	add	a5,a5,a4
    8000478a:	639c                	ld	a5,0(a5)
    8000478c:	c38d                	beqz	a5,800047ae <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000478e:	4505                	li	a0,1
    80004790:	9782                	jalr	a5
    80004792:	892a                	mv	s2,a0
    80004794:	bf75                	j	80004750 <fileread+0x60>
    panic("fileread");
    80004796:	00004517          	auipc	a0,0x4
    8000479a:	f1a50513          	addi	a0,a0,-230 # 800086b0 <syscalls+0x268>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	d9c080e7          	jalr	-612(ra) # 8000053a <panic>
    return -1;
    800047a6:	597d                	li	s2,-1
    800047a8:	b765                	j	80004750 <fileread+0x60>
      return -1;
    800047aa:	597d                	li	s2,-1
    800047ac:	b755                	j	80004750 <fileread+0x60>
    800047ae:	597d                	li	s2,-1
    800047b0:	b745                	j	80004750 <fileread+0x60>

00000000800047b2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047b2:	715d                	addi	sp,sp,-80
    800047b4:	e486                	sd	ra,72(sp)
    800047b6:	e0a2                	sd	s0,64(sp)
    800047b8:	fc26                	sd	s1,56(sp)
    800047ba:	f84a                	sd	s2,48(sp)
    800047bc:	f44e                	sd	s3,40(sp)
    800047be:	f052                	sd	s4,32(sp)
    800047c0:	ec56                	sd	s5,24(sp)
    800047c2:	e85a                	sd	s6,16(sp)
    800047c4:	e45e                	sd	s7,8(sp)
    800047c6:	e062                	sd	s8,0(sp)
    800047c8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047ca:	00954783          	lbu	a5,9(a0)
    800047ce:	10078663          	beqz	a5,800048da <filewrite+0x128>
    800047d2:	892a                	mv	s2,a0
    800047d4:	8b2e                	mv	s6,a1
    800047d6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047d8:	411c                	lw	a5,0(a0)
    800047da:	4705                	li	a4,1
    800047dc:	02e78263          	beq	a5,a4,80004800 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e0:	470d                	li	a4,3
    800047e2:	02e78663          	beq	a5,a4,8000480e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047e6:	4709                	li	a4,2
    800047e8:	0ee79163          	bne	a5,a4,800048ca <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047ec:	0ac05d63          	blez	a2,800048a6 <filewrite+0xf4>
    int i = 0;
    800047f0:	4981                	li	s3,0
    800047f2:	6b85                	lui	s7,0x1
    800047f4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047f8:	6c05                	lui	s8,0x1
    800047fa:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047fe:	a861                	j	80004896 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004800:	6908                	ld	a0,16(a0)
    80004802:	00000097          	auipc	ra,0x0
    80004806:	22e080e7          	jalr	558(ra) # 80004a30 <pipewrite>
    8000480a:	8a2a                	mv	s4,a0
    8000480c:	a045                	j	800048ac <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000480e:	02451783          	lh	a5,36(a0)
    80004812:	03079693          	slli	a3,a5,0x30
    80004816:	92c1                	srli	a3,a3,0x30
    80004818:	4725                	li	a4,9
    8000481a:	0cd76263          	bltu	a4,a3,800048de <filewrite+0x12c>
    8000481e:	0792                	slli	a5,a5,0x4
    80004820:	0001d717          	auipc	a4,0x1d
    80004824:	af870713          	addi	a4,a4,-1288 # 80021318 <devsw>
    80004828:	97ba                	add	a5,a5,a4
    8000482a:	679c                	ld	a5,8(a5)
    8000482c:	cbdd                	beqz	a5,800048e2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000482e:	4505                	li	a0,1
    80004830:	9782                	jalr	a5
    80004832:	8a2a                	mv	s4,a0
    80004834:	a8a5                	j	800048ac <filewrite+0xfa>
    80004836:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	8b4080e7          	jalr	-1868(ra) # 800040ee <begin_op>
      ilock(f->ip);
    80004842:	01893503          	ld	a0,24(s2)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	ecc080e7          	jalr	-308(ra) # 80003712 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000484e:	8756                	mv	a4,s5
    80004850:	02092683          	lw	a3,32(s2)
    80004854:	01698633          	add	a2,s3,s6
    80004858:	4585                	li	a1,1
    8000485a:	01893503          	ld	a0,24(s2)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	260080e7          	jalr	608(ra) # 80003abe <writei>
    80004866:	84aa                	mv	s1,a0
    80004868:	00a05763          	blez	a0,80004876 <filewrite+0xc4>
        f->off += r;
    8000486c:	02092783          	lw	a5,32(s2)
    80004870:	9fa9                	addw	a5,a5,a0
    80004872:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004876:	01893503          	ld	a0,24(s2)
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	f5a080e7          	jalr	-166(ra) # 800037d4 <iunlock>
      end_op();
    80004882:	00000097          	auipc	ra,0x0
    80004886:	8ea080e7          	jalr	-1814(ra) # 8000416c <end_op>

      if(r != n1){
    8000488a:	009a9f63          	bne	s5,s1,800048a8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000488e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004892:	0149db63          	bge	s3,s4,800048a8 <filewrite+0xf6>
      int n1 = n - i;
    80004896:	413a04bb          	subw	s1,s4,s3
    8000489a:	0004879b          	sext.w	a5,s1
    8000489e:	f8fbdce3          	bge	s7,a5,80004836 <filewrite+0x84>
    800048a2:	84e2                	mv	s1,s8
    800048a4:	bf49                	j	80004836 <filewrite+0x84>
    int i = 0;
    800048a6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048a8:	013a1f63          	bne	s4,s3,800048c6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ac:	8552                	mv	a0,s4
    800048ae:	60a6                	ld	ra,72(sp)
    800048b0:	6406                	ld	s0,64(sp)
    800048b2:	74e2                	ld	s1,56(sp)
    800048b4:	7942                	ld	s2,48(sp)
    800048b6:	79a2                	ld	s3,40(sp)
    800048b8:	7a02                	ld	s4,32(sp)
    800048ba:	6ae2                	ld	s5,24(sp)
    800048bc:	6b42                	ld	s6,16(sp)
    800048be:	6ba2                	ld	s7,8(sp)
    800048c0:	6c02                	ld	s8,0(sp)
    800048c2:	6161                	addi	sp,sp,80
    800048c4:	8082                	ret
    ret = (i == n ? n : -1);
    800048c6:	5a7d                	li	s4,-1
    800048c8:	b7d5                	j	800048ac <filewrite+0xfa>
    panic("filewrite");
    800048ca:	00004517          	auipc	a0,0x4
    800048ce:	df650513          	addi	a0,a0,-522 # 800086c0 <syscalls+0x278>
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	c68080e7          	jalr	-920(ra) # 8000053a <panic>
    return -1;
    800048da:	5a7d                	li	s4,-1
    800048dc:	bfc1                	j	800048ac <filewrite+0xfa>
      return -1;
    800048de:	5a7d                	li	s4,-1
    800048e0:	b7f1                	j	800048ac <filewrite+0xfa>
    800048e2:	5a7d                	li	s4,-1
    800048e4:	b7e1                	j	800048ac <filewrite+0xfa>

00000000800048e6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048e6:	7179                	addi	sp,sp,-48
    800048e8:	f406                	sd	ra,40(sp)
    800048ea:	f022                	sd	s0,32(sp)
    800048ec:	ec26                	sd	s1,24(sp)
    800048ee:	e84a                	sd	s2,16(sp)
    800048f0:	e44e                	sd	s3,8(sp)
    800048f2:	e052                	sd	s4,0(sp)
    800048f4:	1800                	addi	s0,sp,48
    800048f6:	84aa                	mv	s1,a0
    800048f8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048fa:	0005b023          	sd	zero,0(a1)
    800048fe:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004902:	00000097          	auipc	ra,0x0
    80004906:	bf8080e7          	jalr	-1032(ra) # 800044fa <filealloc>
    8000490a:	e088                	sd	a0,0(s1)
    8000490c:	c551                	beqz	a0,80004998 <pipealloc+0xb2>
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	bec080e7          	jalr	-1044(ra) # 800044fa <filealloc>
    80004916:	00aa3023          	sd	a0,0(s4)
    8000491a:	c92d                	beqz	a0,8000498c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	1c4080e7          	jalr	452(ra) # 80000ae0 <kalloc>
    80004924:	892a                	mv	s2,a0
    80004926:	c125                	beqz	a0,80004986 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004928:	4985                	li	s3,1
    8000492a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000492e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004932:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004936:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000493a:	00004597          	auipc	a1,0x4
    8000493e:	d9658593          	addi	a1,a1,-618 # 800086d0 <syscalls+0x288>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	248080e7          	jalr	584(ra) # 80000b8a <initlock>
  (*f0)->type = FD_PIPE;
    8000494a:	609c                	ld	a5,0(s1)
    8000494c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004950:	609c                	ld	a5,0(s1)
    80004952:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004956:	609c                	ld	a5,0(s1)
    80004958:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000495c:	609c                	ld	a5,0(s1)
    8000495e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004962:	000a3783          	ld	a5,0(s4)
    80004966:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000496a:	000a3783          	ld	a5,0(s4)
    8000496e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004972:	000a3783          	ld	a5,0(s4)
    80004976:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000497a:	000a3783          	ld	a5,0(s4)
    8000497e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004982:	4501                	li	a0,0
    80004984:	a025                	j	800049ac <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004986:	6088                	ld	a0,0(s1)
    80004988:	e501                	bnez	a0,80004990 <pipealloc+0xaa>
    8000498a:	a039                	j	80004998 <pipealloc+0xb2>
    8000498c:	6088                	ld	a0,0(s1)
    8000498e:	c51d                	beqz	a0,800049bc <pipealloc+0xd6>
    fileclose(*f0);
    80004990:	00000097          	auipc	ra,0x0
    80004994:	c26080e7          	jalr	-986(ra) # 800045b6 <fileclose>
  if(*f1)
    80004998:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000499c:	557d                	li	a0,-1
  if(*f1)
    8000499e:	c799                	beqz	a5,800049ac <pipealloc+0xc6>
    fileclose(*f1);
    800049a0:	853e                	mv	a0,a5
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	c14080e7          	jalr	-1004(ra) # 800045b6 <fileclose>
  return -1;
    800049aa:	557d                	li	a0,-1
}
    800049ac:	70a2                	ld	ra,40(sp)
    800049ae:	7402                	ld	s0,32(sp)
    800049b0:	64e2                	ld	s1,24(sp)
    800049b2:	6942                	ld	s2,16(sp)
    800049b4:	69a2                	ld	s3,8(sp)
    800049b6:	6a02                	ld	s4,0(sp)
    800049b8:	6145                	addi	sp,sp,48
    800049ba:	8082                	ret
  return -1;
    800049bc:	557d                	li	a0,-1
    800049be:	b7fd                	j	800049ac <pipealloc+0xc6>

00000000800049c0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049c0:	1101                	addi	sp,sp,-32
    800049c2:	ec06                	sd	ra,24(sp)
    800049c4:	e822                	sd	s0,16(sp)
    800049c6:	e426                	sd	s1,8(sp)
    800049c8:	e04a                	sd	s2,0(sp)
    800049ca:	1000                	addi	s0,sp,32
    800049cc:	84aa                	mv	s1,a0
    800049ce:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	24a080e7          	jalr	586(ra) # 80000c1a <acquire>
  if(writable){
    800049d8:	02090d63          	beqz	s2,80004a12 <pipeclose+0x52>
    pi->writeopen = 0;
    800049dc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049e0:	21848513          	addi	a0,s1,536
    800049e4:	ffffe097          	auipc	ra,0xffffe
    800049e8:	84c080e7          	jalr	-1972(ra) # 80002230 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049ec:	2204b783          	ld	a5,544(s1)
    800049f0:	eb95                	bnez	a5,80004a24 <pipeclose+0x64>
    release(&pi->lock);
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	2da080e7          	jalr	730(ra) # 80000cce <release>
    kfree((char*)pi);
    800049fc:	8526                	mv	a0,s1
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	fe4080e7          	jalr	-28(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004a06:	60e2                	ld	ra,24(sp)
    80004a08:	6442                	ld	s0,16(sp)
    80004a0a:	64a2                	ld	s1,8(sp)
    80004a0c:	6902                	ld	s2,0(sp)
    80004a0e:	6105                	addi	sp,sp,32
    80004a10:	8082                	ret
    pi->readopen = 0;
    80004a12:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a16:	21c48513          	addi	a0,s1,540
    80004a1a:	ffffe097          	auipc	ra,0xffffe
    80004a1e:	816080e7          	jalr	-2026(ra) # 80002230 <wakeup>
    80004a22:	b7e9                	j	800049ec <pipeclose+0x2c>
    release(&pi->lock);
    80004a24:	8526                	mv	a0,s1
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	2a8080e7          	jalr	680(ra) # 80000cce <release>
}
    80004a2e:	bfe1                	j	80004a06 <pipeclose+0x46>

0000000080004a30 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a30:	711d                	addi	sp,sp,-96
    80004a32:	ec86                	sd	ra,88(sp)
    80004a34:	e8a2                	sd	s0,80(sp)
    80004a36:	e4a6                	sd	s1,72(sp)
    80004a38:	e0ca                	sd	s2,64(sp)
    80004a3a:	fc4e                	sd	s3,56(sp)
    80004a3c:	f852                	sd	s4,48(sp)
    80004a3e:	f456                	sd	s5,40(sp)
    80004a40:	f05a                	sd	s6,32(sp)
    80004a42:	ec5e                	sd	s7,24(sp)
    80004a44:	e862                	sd	s8,16(sp)
    80004a46:	1080                	addi	s0,sp,96
    80004a48:	84aa                	mv	s1,a0
    80004a4a:	8aae                	mv	s5,a1
    80004a4c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a4e:	ffffd097          	auipc	ra,0xffffd
    80004a52:	f92080e7          	jalr	-110(ra) # 800019e0 <myproc>
    80004a56:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a58:	8526                	mv	a0,s1
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	1c0080e7          	jalr	448(ra) # 80000c1a <acquire>
  while(i < n){
    80004a62:	0b405363          	blez	s4,80004b08 <pipewrite+0xd8>
  int i = 0;
    80004a66:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a68:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a6a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a6e:	21c48b93          	addi	s7,s1,540
    80004a72:	a089                	j	80004ab4 <pipewrite+0x84>
      release(&pi->lock);
    80004a74:	8526                	mv	a0,s1
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	258080e7          	jalr	600(ra) # 80000cce <release>
      return -1;
    80004a7e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a80:	854a                	mv	a0,s2
    80004a82:	60e6                	ld	ra,88(sp)
    80004a84:	6446                	ld	s0,80(sp)
    80004a86:	64a6                	ld	s1,72(sp)
    80004a88:	6906                	ld	s2,64(sp)
    80004a8a:	79e2                	ld	s3,56(sp)
    80004a8c:	7a42                	ld	s4,48(sp)
    80004a8e:	7aa2                	ld	s5,40(sp)
    80004a90:	7b02                	ld	s6,32(sp)
    80004a92:	6be2                	ld	s7,24(sp)
    80004a94:	6c42                	ld	s8,16(sp)
    80004a96:	6125                	addi	sp,sp,96
    80004a98:	8082                	ret
      wakeup(&pi->nread);
    80004a9a:	8562                	mv	a0,s8
    80004a9c:	ffffd097          	auipc	ra,0xffffd
    80004aa0:	794080e7          	jalr	1940(ra) # 80002230 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004aa4:	85a6                	mv	a1,s1
    80004aa6:	855e                	mv	a0,s7
    80004aa8:	ffffd097          	auipc	ra,0xffffd
    80004aac:	5fc080e7          	jalr	1532(ra) # 800020a4 <sleep>
  while(i < n){
    80004ab0:	05495d63          	bge	s2,s4,80004b0a <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004ab4:	2204a783          	lw	a5,544(s1)
    80004ab8:	dfd5                	beqz	a5,80004a74 <pipewrite+0x44>
    80004aba:	0289a783          	lw	a5,40(s3)
    80004abe:	fbdd                	bnez	a5,80004a74 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ac0:	2184a783          	lw	a5,536(s1)
    80004ac4:	21c4a703          	lw	a4,540(s1)
    80004ac8:	2007879b          	addiw	a5,a5,512
    80004acc:	fcf707e3          	beq	a4,a5,80004a9a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad0:	4685                	li	a3,1
    80004ad2:	01590633          	add	a2,s2,s5
    80004ad6:	faf40593          	addi	a1,s0,-81
    80004ada:	0509b503          	ld	a0,80(s3)
    80004ade:	ffffd097          	auipc	ra,0xffffd
    80004ae2:	c52080e7          	jalr	-942(ra) # 80001730 <copyin>
    80004ae6:	03650263          	beq	a0,s6,80004b0a <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aea:	21c4a783          	lw	a5,540(s1)
    80004aee:	0017871b          	addiw	a4,a5,1
    80004af2:	20e4ae23          	sw	a4,540(s1)
    80004af6:	1ff7f793          	andi	a5,a5,511
    80004afa:	97a6                	add	a5,a5,s1
    80004afc:	faf44703          	lbu	a4,-81(s0)
    80004b00:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b04:	2905                	addiw	s2,s2,1
    80004b06:	b76d                	j	80004ab0 <pipewrite+0x80>
  int i = 0;
    80004b08:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b0a:	21848513          	addi	a0,s1,536
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	722080e7          	jalr	1826(ra) # 80002230 <wakeup>
  release(&pi->lock);
    80004b16:	8526                	mv	a0,s1
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	1b6080e7          	jalr	438(ra) # 80000cce <release>
  return i;
    80004b20:	b785                	j	80004a80 <pipewrite+0x50>

0000000080004b22 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b22:	715d                	addi	sp,sp,-80
    80004b24:	e486                	sd	ra,72(sp)
    80004b26:	e0a2                	sd	s0,64(sp)
    80004b28:	fc26                	sd	s1,56(sp)
    80004b2a:	f84a                	sd	s2,48(sp)
    80004b2c:	f44e                	sd	s3,40(sp)
    80004b2e:	f052                	sd	s4,32(sp)
    80004b30:	ec56                	sd	s5,24(sp)
    80004b32:	e85a                	sd	s6,16(sp)
    80004b34:	0880                	addi	s0,sp,80
    80004b36:	84aa                	mv	s1,a0
    80004b38:	892e                	mv	s2,a1
    80004b3a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	ea4080e7          	jalr	-348(ra) # 800019e0 <myproc>
    80004b44:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	0d2080e7          	jalr	210(ra) # 80000c1a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b50:	2184a703          	lw	a4,536(s1)
    80004b54:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b58:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5c:	02f71463          	bne	a4,a5,80004b84 <piperead+0x62>
    80004b60:	2244a783          	lw	a5,548(s1)
    80004b64:	c385                	beqz	a5,80004b84 <piperead+0x62>
    if(pr->killed){
    80004b66:	028a2783          	lw	a5,40(s4)
    80004b6a:	ebc9                	bnez	a5,80004bfc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b6c:	85a6                	mv	a1,s1
    80004b6e:	854e                	mv	a0,s3
    80004b70:	ffffd097          	auipc	ra,0xffffd
    80004b74:	534080e7          	jalr	1332(ra) # 800020a4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b78:	2184a703          	lw	a4,536(s1)
    80004b7c:	21c4a783          	lw	a5,540(s1)
    80004b80:	fef700e3          	beq	a4,a5,80004b60 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b84:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b86:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b88:	05505463          	blez	s5,80004bd0 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004b8c:	2184a783          	lw	a5,536(s1)
    80004b90:	21c4a703          	lw	a4,540(s1)
    80004b94:	02f70e63          	beq	a4,a5,80004bd0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b98:	0017871b          	addiw	a4,a5,1
    80004b9c:	20e4ac23          	sw	a4,536(s1)
    80004ba0:	1ff7f793          	andi	a5,a5,511
    80004ba4:	97a6                	add	a5,a5,s1
    80004ba6:	0187c783          	lbu	a5,24(a5)
    80004baa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bae:	4685                	li	a3,1
    80004bb0:	fbf40613          	addi	a2,s0,-65
    80004bb4:	85ca                	mv	a1,s2
    80004bb6:	050a3503          	ld	a0,80(s4)
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	aea080e7          	jalr	-1302(ra) # 800016a4 <copyout>
    80004bc2:	01650763          	beq	a0,s6,80004bd0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc6:	2985                	addiw	s3,s3,1
    80004bc8:	0905                	addi	s2,s2,1
    80004bca:	fd3a91e3          	bne	s5,s3,80004b8c <piperead+0x6a>
    80004bce:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bd0:	21c48513          	addi	a0,s1,540
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	65c080e7          	jalr	1628(ra) # 80002230 <wakeup>
  release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0f0080e7          	jalr	240(ra) # 80000cce <release>
  return i;
}
    80004be6:	854e                	mv	a0,s3
    80004be8:	60a6                	ld	ra,72(sp)
    80004bea:	6406                	ld	s0,64(sp)
    80004bec:	74e2                	ld	s1,56(sp)
    80004bee:	7942                	ld	s2,48(sp)
    80004bf0:	79a2                	ld	s3,40(sp)
    80004bf2:	7a02                	ld	s4,32(sp)
    80004bf4:	6ae2                	ld	s5,24(sp)
    80004bf6:	6b42                	ld	s6,16(sp)
    80004bf8:	6161                	addi	sp,sp,80
    80004bfa:	8082                	ret
      release(&pi->lock);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	0d0080e7          	jalr	208(ra) # 80000cce <release>
      return -1;
    80004c06:	59fd                	li	s3,-1
    80004c08:	bff9                	j	80004be6 <piperead+0xc4>

0000000080004c0a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c0a:	de010113          	addi	sp,sp,-544
    80004c0e:	20113c23          	sd	ra,536(sp)
    80004c12:	20813823          	sd	s0,528(sp)
    80004c16:	20913423          	sd	s1,520(sp)
    80004c1a:	21213023          	sd	s2,512(sp)
    80004c1e:	ffce                	sd	s3,504(sp)
    80004c20:	fbd2                	sd	s4,496(sp)
    80004c22:	f7d6                	sd	s5,488(sp)
    80004c24:	f3da                	sd	s6,480(sp)
    80004c26:	efde                	sd	s7,472(sp)
    80004c28:	ebe2                	sd	s8,464(sp)
    80004c2a:	e7e6                	sd	s9,456(sp)
    80004c2c:	e3ea                	sd	s10,448(sp)
    80004c2e:	ff6e                	sd	s11,440(sp)
    80004c30:	1400                	addi	s0,sp,544
    80004c32:	892a                	mv	s2,a0
    80004c34:	dea43423          	sd	a0,-536(s0)
    80004c38:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	da4080e7          	jalr	-604(ra) # 800019e0 <myproc>
    80004c44:	84aa                	mv	s1,a0

  begin_op();
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	4a8080e7          	jalr	1192(ra) # 800040ee <begin_op>

  if((ip = namei(path)) == 0){
    80004c4e:	854a                	mv	a0,s2
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	27e080e7          	jalr	638(ra) # 80003ece <namei>
    80004c58:	c93d                	beqz	a0,80004cce <exec+0xc4>
    80004c5a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	ab6080e7          	jalr	-1354(ra) # 80003712 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c64:	04000713          	li	a4,64
    80004c68:	4681                	li	a3,0
    80004c6a:	e5040613          	addi	a2,s0,-432
    80004c6e:	4581                	li	a1,0
    80004c70:	8556                	mv	a0,s5
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	d54080e7          	jalr	-684(ra) # 800039c6 <readi>
    80004c7a:	04000793          	li	a5,64
    80004c7e:	00f51a63          	bne	a0,a5,80004c92 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c82:	e5042703          	lw	a4,-432(s0)
    80004c86:	464c47b7          	lui	a5,0x464c4
    80004c8a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c8e:	04f70663          	beq	a4,a5,80004cda <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c92:	8556                	mv	a0,s5
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	ce0080e7          	jalr	-800(ra) # 80003974 <iunlockput>
    end_op();
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	4d0080e7          	jalr	1232(ra) # 8000416c <end_op>
  }
  return -1;
    80004ca4:	557d                	li	a0,-1
}
    80004ca6:	21813083          	ld	ra,536(sp)
    80004caa:	21013403          	ld	s0,528(sp)
    80004cae:	20813483          	ld	s1,520(sp)
    80004cb2:	20013903          	ld	s2,512(sp)
    80004cb6:	79fe                	ld	s3,504(sp)
    80004cb8:	7a5e                	ld	s4,496(sp)
    80004cba:	7abe                	ld	s5,488(sp)
    80004cbc:	7b1e                	ld	s6,480(sp)
    80004cbe:	6bfe                	ld	s7,472(sp)
    80004cc0:	6c5e                	ld	s8,464(sp)
    80004cc2:	6cbe                	ld	s9,456(sp)
    80004cc4:	6d1e                	ld	s10,448(sp)
    80004cc6:	7dfa                	ld	s11,440(sp)
    80004cc8:	22010113          	addi	sp,sp,544
    80004ccc:	8082                	ret
    end_op();
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	49e080e7          	jalr	1182(ra) # 8000416c <end_op>
    return -1;
    80004cd6:	557d                	li	a0,-1
    80004cd8:	b7f9                	j	80004ca6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	dc8080e7          	jalr	-568(ra) # 80001aa4 <proc_pagetable>
    80004ce4:	8b2a                	mv	s6,a0
    80004ce6:	d555                	beqz	a0,80004c92 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ce8:	e7042783          	lw	a5,-400(s0)
    80004cec:	e8845703          	lhu	a4,-376(s0)
    80004cf0:	c735                	beqz	a4,80004d5c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cf2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cf4:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004cf8:	6a05                	lui	s4,0x1
    80004cfa:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cfe:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d02:	6d85                	lui	s11,0x1
    80004d04:	7d7d                	lui	s10,0xfffff
    80004d06:	ac1d                	j	80004f3c <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d08:	00004517          	auipc	a0,0x4
    80004d0c:	9d050513          	addi	a0,a0,-1584 # 800086d8 <syscalls+0x290>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	82a080e7          	jalr	-2006(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d18:	874a                	mv	a4,s2
    80004d1a:	009c86bb          	addw	a3,s9,s1
    80004d1e:	4581                	li	a1,0
    80004d20:	8556                	mv	a0,s5
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	ca4080e7          	jalr	-860(ra) # 800039c6 <readi>
    80004d2a:	2501                	sext.w	a0,a0
    80004d2c:	1aa91863          	bne	s2,a0,80004edc <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d30:	009d84bb          	addw	s1,s11,s1
    80004d34:	013d09bb          	addw	s3,s10,s3
    80004d38:	1f74f263          	bgeu	s1,s7,80004f1c <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d3c:	02049593          	slli	a1,s1,0x20
    80004d40:	9181                	srli	a1,a1,0x20
    80004d42:	95e2                	add	a1,a1,s8
    80004d44:	855a                	mv	a0,s6
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	356080e7          	jalr	854(ra) # 8000109c <walkaddr>
    80004d4e:	862a                	mv	a2,a0
    if(pa == 0)
    80004d50:	dd45                	beqz	a0,80004d08 <exec+0xfe>
      n = PGSIZE;
    80004d52:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d54:	fd49f2e3          	bgeu	s3,s4,80004d18 <exec+0x10e>
      n = sz - i;
    80004d58:	894e                	mv	s2,s3
    80004d5a:	bf7d                	j	80004d18 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d5c:	4481                	li	s1,0
  iunlockput(ip);
    80004d5e:	8556                	mv	a0,s5
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	c14080e7          	jalr	-1004(ra) # 80003974 <iunlockput>
  end_op();
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	404080e7          	jalr	1028(ra) # 8000416c <end_op>
  p = myproc();
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	c70080e7          	jalr	-912(ra) # 800019e0 <myproc>
    80004d78:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d7a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d7e:	6785                	lui	a5,0x1
    80004d80:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d82:	97a6                	add	a5,a5,s1
    80004d84:	777d                	lui	a4,0xfffff
    80004d86:	8ff9                	and	a5,a5,a4
    80004d88:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d8c:	6609                	lui	a2,0x2
    80004d8e:	963e                	add	a2,a2,a5
    80004d90:	85be                	mv	a1,a5
    80004d92:	855a                	mv	a0,s6
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	6bc080e7          	jalr	1724(ra) # 80001450 <uvmalloc>
    80004d9c:	8c2a                	mv	s8,a0
  ip = 0;
    80004d9e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004da0:	12050e63          	beqz	a0,80004edc <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004da4:	75f9                	lui	a1,0xffffe
    80004da6:	95aa                	add	a1,a1,a0
    80004da8:	855a                	mv	a0,s6
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	8c8080e7          	jalr	-1848(ra) # 80001672 <uvmclear>
  stackbase = sp - PGSIZE;
    80004db2:	7afd                	lui	s5,0xfffff
    80004db4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004db6:	df043783          	ld	a5,-528(s0)
    80004dba:	6388                	ld	a0,0(a5)
    80004dbc:	c925                	beqz	a0,80004e2c <exec+0x222>
    80004dbe:	e9040993          	addi	s3,s0,-368
    80004dc2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dc6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dc8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	0c8080e7          	jalr	200(ra) # 80000e92 <strlen>
    80004dd2:	0015079b          	addiw	a5,a0,1
    80004dd6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dda:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004dde:	13596363          	bltu	s2,s5,80004f04 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004de2:	df043d83          	ld	s11,-528(s0)
    80004de6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dea:	8552                	mv	a0,s4
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	0a6080e7          	jalr	166(ra) # 80000e92 <strlen>
    80004df4:	0015069b          	addiw	a3,a0,1
    80004df8:	8652                	mv	a2,s4
    80004dfa:	85ca                	mv	a1,s2
    80004dfc:	855a                	mv	a0,s6
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	8a6080e7          	jalr	-1882(ra) # 800016a4 <copyout>
    80004e06:	10054363          	bltz	a0,80004f0c <exec+0x302>
    ustack[argc] = sp;
    80004e0a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e0e:	0485                	addi	s1,s1,1
    80004e10:	008d8793          	addi	a5,s11,8
    80004e14:	def43823          	sd	a5,-528(s0)
    80004e18:	008db503          	ld	a0,8(s11)
    80004e1c:	c911                	beqz	a0,80004e30 <exec+0x226>
    if(argc >= MAXARG)
    80004e1e:	09a1                	addi	s3,s3,8
    80004e20:	fb3c95e3          	bne	s9,s3,80004dca <exec+0x1c0>
  sz = sz1;
    80004e24:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e28:	4a81                	li	s5,0
    80004e2a:	a84d                	j	80004edc <exec+0x2d2>
  sp = sz;
    80004e2c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e2e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e30:	00349793          	slli	a5,s1,0x3
    80004e34:	f9078793          	addi	a5,a5,-112
    80004e38:	97a2                	add	a5,a5,s0
    80004e3a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e3e:	00148693          	addi	a3,s1,1
    80004e42:	068e                	slli	a3,a3,0x3
    80004e44:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e48:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e4c:	01597663          	bgeu	s2,s5,80004e58 <exec+0x24e>
  sz = sz1;
    80004e50:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e54:	4a81                	li	s5,0
    80004e56:	a059                	j	80004edc <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e58:	e9040613          	addi	a2,s0,-368
    80004e5c:	85ca                	mv	a1,s2
    80004e5e:	855a                	mv	a0,s6
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	844080e7          	jalr	-1980(ra) # 800016a4 <copyout>
    80004e68:	0a054663          	bltz	a0,80004f14 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e6c:	058bb783          	ld	a5,88(s7)
    80004e70:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e74:	de843783          	ld	a5,-536(s0)
    80004e78:	0007c703          	lbu	a4,0(a5)
    80004e7c:	cf11                	beqz	a4,80004e98 <exec+0x28e>
    80004e7e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e80:	02f00693          	li	a3,47
    80004e84:	a039                	j	80004e92 <exec+0x288>
      last = s+1;
    80004e86:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e8a:	0785                	addi	a5,a5,1
    80004e8c:	fff7c703          	lbu	a4,-1(a5)
    80004e90:	c701                	beqz	a4,80004e98 <exec+0x28e>
    if(*s == '/')
    80004e92:	fed71ce3          	bne	a4,a3,80004e8a <exec+0x280>
    80004e96:	bfc5                	j	80004e86 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e98:	4641                	li	a2,16
    80004e9a:	de843583          	ld	a1,-536(s0)
    80004e9e:	158b8513          	addi	a0,s7,344
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	fbe080e7          	jalr	-66(ra) # 80000e60 <safestrcpy>
  oldpagetable = p->pagetable;
    80004eaa:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004eae:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004eb2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004eb6:	058bb783          	ld	a5,88(s7)
    80004eba:	e6843703          	ld	a4,-408(s0)
    80004ebe:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ec0:	058bb783          	ld	a5,88(s7)
    80004ec4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ec8:	85ea                	mv	a1,s10
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	c76080e7          	jalr	-906(ra) # 80001b40 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ed2:	0004851b          	sext.w	a0,s1
    80004ed6:	bbc1                	j	80004ca6 <exec+0x9c>
    80004ed8:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004edc:	df843583          	ld	a1,-520(s0)
    80004ee0:	855a                	mv	a0,s6
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	c5e080e7          	jalr	-930(ra) # 80001b40 <proc_freepagetable>
  if(ip){
    80004eea:	da0a94e3          	bnez	s5,80004c92 <exec+0x88>
  return -1;
    80004eee:	557d                	li	a0,-1
    80004ef0:	bb5d                	j	80004ca6 <exec+0x9c>
    80004ef2:	de943c23          	sd	s1,-520(s0)
    80004ef6:	b7dd                	j	80004edc <exec+0x2d2>
    80004ef8:	de943c23          	sd	s1,-520(s0)
    80004efc:	b7c5                	j	80004edc <exec+0x2d2>
    80004efe:	de943c23          	sd	s1,-520(s0)
    80004f02:	bfe9                	j	80004edc <exec+0x2d2>
  sz = sz1;
    80004f04:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f08:	4a81                	li	s5,0
    80004f0a:	bfc9                	j	80004edc <exec+0x2d2>
  sz = sz1;
    80004f0c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f10:	4a81                	li	s5,0
    80004f12:	b7e9                	j	80004edc <exec+0x2d2>
  sz = sz1;
    80004f14:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f18:	4a81                	li	s5,0
    80004f1a:	b7c9                	j	80004edc <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f1c:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f20:	e0843783          	ld	a5,-504(s0)
    80004f24:	0017869b          	addiw	a3,a5,1
    80004f28:	e0d43423          	sd	a3,-504(s0)
    80004f2c:	e0043783          	ld	a5,-512(s0)
    80004f30:	0387879b          	addiw	a5,a5,56
    80004f34:	e8845703          	lhu	a4,-376(s0)
    80004f38:	e2e6d3e3          	bge	a3,a4,80004d5e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f3c:	2781                	sext.w	a5,a5
    80004f3e:	e0f43023          	sd	a5,-512(s0)
    80004f42:	03800713          	li	a4,56
    80004f46:	86be                	mv	a3,a5
    80004f48:	e1840613          	addi	a2,s0,-488
    80004f4c:	4581                	li	a1,0
    80004f4e:	8556                	mv	a0,s5
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	a76080e7          	jalr	-1418(ra) # 800039c6 <readi>
    80004f58:	03800793          	li	a5,56
    80004f5c:	f6f51ee3          	bne	a0,a5,80004ed8 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f60:	e1842783          	lw	a5,-488(s0)
    80004f64:	4705                	li	a4,1
    80004f66:	fae79de3          	bne	a5,a4,80004f20 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f6a:	e4043603          	ld	a2,-448(s0)
    80004f6e:	e3843783          	ld	a5,-456(s0)
    80004f72:	f8f660e3          	bltu	a2,a5,80004ef2 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f76:	e2843783          	ld	a5,-472(s0)
    80004f7a:	963e                	add	a2,a2,a5
    80004f7c:	f6f66ee3          	bltu	a2,a5,80004ef8 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f80:	85a6                	mv	a1,s1
    80004f82:	855a                	mv	a0,s6
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	4cc080e7          	jalr	1228(ra) # 80001450 <uvmalloc>
    80004f8c:	dea43c23          	sd	a0,-520(s0)
    80004f90:	d53d                	beqz	a0,80004efe <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004f92:	e2843c03          	ld	s8,-472(s0)
    80004f96:	de043783          	ld	a5,-544(s0)
    80004f9a:	00fc77b3          	and	a5,s8,a5
    80004f9e:	ff9d                	bnez	a5,80004edc <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fa0:	e2042c83          	lw	s9,-480(s0)
    80004fa4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fa8:	f60b8ae3          	beqz	s7,80004f1c <exec+0x312>
    80004fac:	89de                	mv	s3,s7
    80004fae:	4481                	li	s1,0
    80004fb0:	b371                	j	80004d3c <exec+0x132>

0000000080004fb2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fb2:	7179                	addi	sp,sp,-48
    80004fb4:	f406                	sd	ra,40(sp)
    80004fb6:	f022                	sd	s0,32(sp)
    80004fb8:	ec26                	sd	s1,24(sp)
    80004fba:	e84a                	sd	s2,16(sp)
    80004fbc:	1800                	addi	s0,sp,48
    80004fbe:	892e                	mv	s2,a1
    80004fc0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fc2:	fdc40593          	addi	a1,s0,-36
    80004fc6:	ffffe097          	auipc	ra,0xffffe
    80004fca:	b8e080e7          	jalr	-1138(ra) # 80002b54 <argint>
    80004fce:	04054063          	bltz	a0,8000500e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fd2:	fdc42703          	lw	a4,-36(s0)
    80004fd6:	47bd                	li	a5,15
    80004fd8:	02e7ed63          	bltu	a5,a4,80005012 <argfd+0x60>
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	a04080e7          	jalr	-1532(ra) # 800019e0 <myproc>
    80004fe4:	fdc42703          	lw	a4,-36(s0)
    80004fe8:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004fec:	078e                	slli	a5,a5,0x3
    80004fee:	953e                	add	a0,a0,a5
    80004ff0:	611c                	ld	a5,0(a0)
    80004ff2:	c395                	beqz	a5,80005016 <argfd+0x64>
    return -1;
  if(pfd)
    80004ff4:	00090463          	beqz	s2,80004ffc <argfd+0x4a>
    *pfd = fd;
    80004ff8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ffc:	4501                	li	a0,0
  if(pf)
    80004ffe:	c091                	beqz	s1,80005002 <argfd+0x50>
    *pf = f;
    80005000:	e09c                	sd	a5,0(s1)
}
    80005002:	70a2                	ld	ra,40(sp)
    80005004:	7402                	ld	s0,32(sp)
    80005006:	64e2                	ld	s1,24(sp)
    80005008:	6942                	ld	s2,16(sp)
    8000500a:	6145                	addi	sp,sp,48
    8000500c:	8082                	ret
    return -1;
    8000500e:	557d                	li	a0,-1
    80005010:	bfcd                	j	80005002 <argfd+0x50>
    return -1;
    80005012:	557d                	li	a0,-1
    80005014:	b7fd                	j	80005002 <argfd+0x50>
    80005016:	557d                	li	a0,-1
    80005018:	b7ed                	j	80005002 <argfd+0x50>

000000008000501a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000501a:	1101                	addi	sp,sp,-32
    8000501c:	ec06                	sd	ra,24(sp)
    8000501e:	e822                	sd	s0,16(sp)
    80005020:	e426                	sd	s1,8(sp)
    80005022:	1000                	addi	s0,sp,32
    80005024:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	9ba080e7          	jalr	-1606(ra) # 800019e0 <myproc>
    8000502e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005030:	0d050793          	addi	a5,a0,208
    80005034:	4501                	li	a0,0
    80005036:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005038:	6398                	ld	a4,0(a5)
    8000503a:	cb19                	beqz	a4,80005050 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000503c:	2505                	addiw	a0,a0,1
    8000503e:	07a1                	addi	a5,a5,8
    80005040:	fed51ce3          	bne	a0,a3,80005038 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005044:	557d                	li	a0,-1
}
    80005046:	60e2                	ld	ra,24(sp)
    80005048:	6442                	ld	s0,16(sp)
    8000504a:	64a2                	ld	s1,8(sp)
    8000504c:	6105                	addi	sp,sp,32
    8000504e:	8082                	ret
      p->ofile[fd] = f;
    80005050:	01a50793          	addi	a5,a0,26
    80005054:	078e                	slli	a5,a5,0x3
    80005056:	963e                	add	a2,a2,a5
    80005058:	e204                	sd	s1,0(a2)
      return fd;
    8000505a:	b7f5                	j	80005046 <fdalloc+0x2c>

000000008000505c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000505c:	715d                	addi	sp,sp,-80
    8000505e:	e486                	sd	ra,72(sp)
    80005060:	e0a2                	sd	s0,64(sp)
    80005062:	fc26                	sd	s1,56(sp)
    80005064:	f84a                	sd	s2,48(sp)
    80005066:	f44e                	sd	s3,40(sp)
    80005068:	f052                	sd	s4,32(sp)
    8000506a:	ec56                	sd	s5,24(sp)
    8000506c:	0880                	addi	s0,sp,80
    8000506e:	89ae                	mv	s3,a1
    80005070:	8ab2                	mv	s5,a2
    80005072:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005074:	fb040593          	addi	a1,s0,-80
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	e74080e7          	jalr	-396(ra) # 80003eec <nameiparent>
    80005080:	892a                	mv	s2,a0
    80005082:	12050e63          	beqz	a0,800051be <create+0x162>
    return 0;

  ilock(dp);
    80005086:	ffffe097          	auipc	ra,0xffffe
    8000508a:	68c080e7          	jalr	1676(ra) # 80003712 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000508e:	4601                	li	a2,0
    80005090:	fb040593          	addi	a1,s0,-80
    80005094:	854a                	mv	a0,s2
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	b60080e7          	jalr	-1184(ra) # 80003bf6 <dirlookup>
    8000509e:	84aa                	mv	s1,a0
    800050a0:	c921                	beqz	a0,800050f0 <create+0x94>
    iunlockput(dp);
    800050a2:	854a                	mv	a0,s2
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	8d0080e7          	jalr	-1840(ra) # 80003974 <iunlockput>
    ilock(ip);
    800050ac:	8526                	mv	a0,s1
    800050ae:	ffffe097          	auipc	ra,0xffffe
    800050b2:	664080e7          	jalr	1636(ra) # 80003712 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050b6:	2981                	sext.w	s3,s3
    800050b8:	4789                	li	a5,2
    800050ba:	02f99463          	bne	s3,a5,800050e2 <create+0x86>
    800050be:	0444d783          	lhu	a5,68(s1)
    800050c2:	37f9                	addiw	a5,a5,-2
    800050c4:	17c2                	slli	a5,a5,0x30
    800050c6:	93c1                	srli	a5,a5,0x30
    800050c8:	4705                	li	a4,1
    800050ca:	00f76c63          	bltu	a4,a5,800050e2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050ce:	8526                	mv	a0,s1
    800050d0:	60a6                	ld	ra,72(sp)
    800050d2:	6406                	ld	s0,64(sp)
    800050d4:	74e2                	ld	s1,56(sp)
    800050d6:	7942                	ld	s2,48(sp)
    800050d8:	79a2                	ld	s3,40(sp)
    800050da:	7a02                	ld	s4,32(sp)
    800050dc:	6ae2                	ld	s5,24(sp)
    800050de:	6161                	addi	sp,sp,80
    800050e0:	8082                	ret
    iunlockput(ip);
    800050e2:	8526                	mv	a0,s1
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	890080e7          	jalr	-1904(ra) # 80003974 <iunlockput>
    return 0;
    800050ec:	4481                	li	s1,0
    800050ee:	b7c5                	j	800050ce <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050f0:	85ce                	mv	a1,s3
    800050f2:	00092503          	lw	a0,0(s2)
    800050f6:	ffffe097          	auipc	ra,0xffffe
    800050fa:	482080e7          	jalr	1154(ra) # 80003578 <ialloc>
    800050fe:	84aa                	mv	s1,a0
    80005100:	c521                	beqz	a0,80005148 <create+0xec>
  ilock(ip);
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	610080e7          	jalr	1552(ra) # 80003712 <ilock>
  ip->major = major;
    8000510a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000510e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005112:	4a05                	li	s4,1
    80005114:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	52c080e7          	jalr	1324(ra) # 80003646 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005122:	2981                	sext.w	s3,s3
    80005124:	03498a63          	beq	s3,s4,80005158 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005128:	40d0                	lw	a2,4(s1)
    8000512a:	fb040593          	addi	a1,s0,-80
    8000512e:	854a                	mv	a0,s2
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	cdc080e7          	jalr	-804(ra) # 80003e0c <dirlink>
    80005138:	06054b63          	bltz	a0,800051ae <create+0x152>
  iunlockput(dp);
    8000513c:	854a                	mv	a0,s2
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	836080e7          	jalr	-1994(ra) # 80003974 <iunlockput>
  return ip;
    80005146:	b761                	j	800050ce <create+0x72>
    panic("create: ialloc");
    80005148:	00003517          	auipc	a0,0x3
    8000514c:	5b050513          	addi	a0,a0,1456 # 800086f8 <syscalls+0x2b0>
    80005150:	ffffb097          	auipc	ra,0xffffb
    80005154:	3ea080e7          	jalr	1002(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005158:	04a95783          	lhu	a5,74(s2)
    8000515c:	2785                	addiw	a5,a5,1
    8000515e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005162:	854a                	mv	a0,s2
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	4e2080e7          	jalr	1250(ra) # 80003646 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000516c:	40d0                	lw	a2,4(s1)
    8000516e:	00003597          	auipc	a1,0x3
    80005172:	59a58593          	addi	a1,a1,1434 # 80008708 <syscalls+0x2c0>
    80005176:	8526                	mv	a0,s1
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	c94080e7          	jalr	-876(ra) # 80003e0c <dirlink>
    80005180:	00054f63          	bltz	a0,8000519e <create+0x142>
    80005184:	00492603          	lw	a2,4(s2)
    80005188:	00003597          	auipc	a1,0x3
    8000518c:	58858593          	addi	a1,a1,1416 # 80008710 <syscalls+0x2c8>
    80005190:	8526                	mv	a0,s1
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	c7a080e7          	jalr	-902(ra) # 80003e0c <dirlink>
    8000519a:	f80557e3          	bgez	a0,80005128 <create+0xcc>
      panic("create dots");
    8000519e:	00003517          	auipc	a0,0x3
    800051a2:	57a50513          	addi	a0,a0,1402 # 80008718 <syscalls+0x2d0>
    800051a6:	ffffb097          	auipc	ra,0xffffb
    800051aa:	394080e7          	jalr	916(ra) # 8000053a <panic>
    panic("create: dirlink");
    800051ae:	00003517          	auipc	a0,0x3
    800051b2:	57a50513          	addi	a0,a0,1402 # 80008728 <syscalls+0x2e0>
    800051b6:	ffffb097          	auipc	ra,0xffffb
    800051ba:	384080e7          	jalr	900(ra) # 8000053a <panic>
    return 0;
    800051be:	84aa                	mv	s1,a0
    800051c0:	b739                	j	800050ce <create+0x72>

00000000800051c2 <sys_dup>:
{
    800051c2:	7179                	addi	sp,sp,-48
    800051c4:	f406                	sd	ra,40(sp)
    800051c6:	f022                	sd	s0,32(sp)
    800051c8:	ec26                	sd	s1,24(sp)
    800051ca:	e84a                	sd	s2,16(sp)
    800051cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051ce:	fd840613          	addi	a2,s0,-40
    800051d2:	4581                	li	a1,0
    800051d4:	4501                	li	a0,0
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	ddc080e7          	jalr	-548(ra) # 80004fb2 <argfd>
    return -1;
    800051de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051e0:	02054363          	bltz	a0,80005206 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051e4:	fd843903          	ld	s2,-40(s0)
    800051e8:	854a                	mv	a0,s2
    800051ea:	00000097          	auipc	ra,0x0
    800051ee:	e30080e7          	jalr	-464(ra) # 8000501a <fdalloc>
    800051f2:	84aa                	mv	s1,a0
    return -1;
    800051f4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051f6:	00054863          	bltz	a0,80005206 <sys_dup+0x44>
  filedup(f);
    800051fa:	854a                	mv	a0,s2
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	368080e7          	jalr	872(ra) # 80004564 <filedup>
  return fd;
    80005204:	87a6                	mv	a5,s1
}
    80005206:	853e                	mv	a0,a5
    80005208:	70a2                	ld	ra,40(sp)
    8000520a:	7402                	ld	s0,32(sp)
    8000520c:	64e2                	ld	s1,24(sp)
    8000520e:	6942                	ld	s2,16(sp)
    80005210:	6145                	addi	sp,sp,48
    80005212:	8082                	ret

0000000080005214 <sys_read>:
{
    80005214:	7179                	addi	sp,sp,-48
    80005216:	f406                	sd	ra,40(sp)
    80005218:	f022                	sd	s0,32(sp)
    8000521a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521c:	fe840613          	addi	a2,s0,-24
    80005220:	4581                	li	a1,0
    80005222:	4501                	li	a0,0
    80005224:	00000097          	auipc	ra,0x0
    80005228:	d8e080e7          	jalr	-626(ra) # 80004fb2 <argfd>
    return -1;
    8000522c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522e:	04054163          	bltz	a0,80005270 <sys_read+0x5c>
    80005232:	fe440593          	addi	a1,s0,-28
    80005236:	4509                	li	a0,2
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	91c080e7          	jalr	-1764(ra) # 80002b54 <argint>
    return -1;
    80005240:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005242:	02054763          	bltz	a0,80005270 <sys_read+0x5c>
    80005246:	fd840593          	addi	a1,s0,-40
    8000524a:	4505                	li	a0,1
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	92a080e7          	jalr	-1750(ra) # 80002b76 <argaddr>
    return -1;
    80005254:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005256:	00054d63          	bltz	a0,80005270 <sys_read+0x5c>
  return fileread(f, p, n);
    8000525a:	fe442603          	lw	a2,-28(s0)
    8000525e:	fd843583          	ld	a1,-40(s0)
    80005262:	fe843503          	ld	a0,-24(s0)
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	48a080e7          	jalr	1162(ra) # 800046f0 <fileread>
    8000526e:	87aa                	mv	a5,a0
}
    80005270:	853e                	mv	a0,a5
    80005272:	70a2                	ld	ra,40(sp)
    80005274:	7402                	ld	s0,32(sp)
    80005276:	6145                	addi	sp,sp,48
    80005278:	8082                	ret

000000008000527a <sys_write>:
{
    8000527a:	7179                	addi	sp,sp,-48
    8000527c:	f406                	sd	ra,40(sp)
    8000527e:	f022                	sd	s0,32(sp)
    80005280:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005282:	fe840613          	addi	a2,s0,-24
    80005286:	4581                	li	a1,0
    80005288:	4501                	li	a0,0
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	d28080e7          	jalr	-728(ra) # 80004fb2 <argfd>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005294:	04054163          	bltz	a0,800052d6 <sys_write+0x5c>
    80005298:	fe440593          	addi	a1,s0,-28
    8000529c:	4509                	li	a0,2
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	8b6080e7          	jalr	-1866(ra) # 80002b54 <argint>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	02054763          	bltz	a0,800052d6 <sys_write+0x5c>
    800052ac:	fd840593          	addi	a1,s0,-40
    800052b0:	4505                	li	a0,1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	8c4080e7          	jalr	-1852(ra) # 80002b76 <argaddr>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	00054d63          	bltz	a0,800052d6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052c0:	fe442603          	lw	a2,-28(s0)
    800052c4:	fd843583          	ld	a1,-40(s0)
    800052c8:	fe843503          	ld	a0,-24(s0)
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	4e6080e7          	jalr	1254(ra) # 800047b2 <filewrite>
    800052d4:	87aa                	mv	a5,a0
}
    800052d6:	853e                	mv	a0,a5
    800052d8:	70a2                	ld	ra,40(sp)
    800052da:	7402                	ld	s0,32(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_close>:
{
    800052e0:	1101                	addi	sp,sp,-32
    800052e2:	ec06                	sd	ra,24(sp)
    800052e4:	e822                	sd	s0,16(sp)
    800052e6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052e8:	fe040613          	addi	a2,s0,-32
    800052ec:	fec40593          	addi	a1,s0,-20
    800052f0:	4501                	li	a0,0
    800052f2:	00000097          	auipc	ra,0x0
    800052f6:	cc0080e7          	jalr	-832(ra) # 80004fb2 <argfd>
    return -1;
    800052fa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052fc:	02054463          	bltz	a0,80005324 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	6e0080e7          	jalr	1760(ra) # 800019e0 <myproc>
    80005308:	fec42783          	lw	a5,-20(s0)
    8000530c:	07e9                	addi	a5,a5,26
    8000530e:	078e                	slli	a5,a5,0x3
    80005310:	953e                	add	a0,a0,a5
    80005312:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005316:	fe043503          	ld	a0,-32(s0)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	29c080e7          	jalr	668(ra) # 800045b6 <fileclose>
  return 0;
    80005322:	4781                	li	a5,0
}
    80005324:	853e                	mv	a0,a5
    80005326:	60e2                	ld	ra,24(sp)
    80005328:	6442                	ld	s0,16(sp)
    8000532a:	6105                	addi	sp,sp,32
    8000532c:	8082                	ret

000000008000532e <sys_fstat>:
{
    8000532e:	1101                	addi	sp,sp,-32
    80005330:	ec06                	sd	ra,24(sp)
    80005332:	e822                	sd	s0,16(sp)
    80005334:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005336:	fe840613          	addi	a2,s0,-24
    8000533a:	4581                	li	a1,0
    8000533c:	4501                	li	a0,0
    8000533e:	00000097          	auipc	ra,0x0
    80005342:	c74080e7          	jalr	-908(ra) # 80004fb2 <argfd>
    return -1;
    80005346:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005348:	02054563          	bltz	a0,80005372 <sys_fstat+0x44>
    8000534c:	fe040593          	addi	a1,s0,-32
    80005350:	4505                	li	a0,1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	824080e7          	jalr	-2012(ra) # 80002b76 <argaddr>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000535c:	00054b63          	bltz	a0,80005372 <sys_fstat+0x44>
  return filestat(f, st);
    80005360:	fe043583          	ld	a1,-32(s0)
    80005364:	fe843503          	ld	a0,-24(s0)
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	316080e7          	jalr	790(ra) # 8000467e <filestat>
    80005370:	87aa                	mv	a5,a0
}
    80005372:	853e                	mv	a0,a5
    80005374:	60e2                	ld	ra,24(sp)
    80005376:	6442                	ld	s0,16(sp)
    80005378:	6105                	addi	sp,sp,32
    8000537a:	8082                	ret

000000008000537c <sys_link>:
{
    8000537c:	7169                	addi	sp,sp,-304
    8000537e:	f606                	sd	ra,296(sp)
    80005380:	f222                	sd	s0,288(sp)
    80005382:	ee26                	sd	s1,280(sp)
    80005384:	ea4a                	sd	s2,272(sp)
    80005386:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005388:	08000613          	li	a2,128
    8000538c:	ed040593          	addi	a1,s0,-304
    80005390:	4501                	li	a0,0
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	806080e7          	jalr	-2042(ra) # 80002b98 <argstr>
    return -1;
    8000539a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000539c:	10054e63          	bltz	a0,800054b8 <sys_link+0x13c>
    800053a0:	08000613          	li	a2,128
    800053a4:	f5040593          	addi	a1,s0,-176
    800053a8:	4505                	li	a0,1
    800053aa:	ffffd097          	auipc	ra,0xffffd
    800053ae:	7ee080e7          	jalr	2030(ra) # 80002b98 <argstr>
    return -1;
    800053b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b4:	10054263          	bltz	a0,800054b8 <sys_link+0x13c>
  begin_op();
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	d36080e7          	jalr	-714(ra) # 800040ee <begin_op>
  if((ip = namei(old)) == 0){
    800053c0:	ed040513          	addi	a0,s0,-304
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	b0a080e7          	jalr	-1270(ra) # 80003ece <namei>
    800053cc:	84aa                	mv	s1,a0
    800053ce:	c551                	beqz	a0,8000545a <sys_link+0xde>
  ilock(ip);
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	342080e7          	jalr	834(ra) # 80003712 <ilock>
  if(ip->type == T_DIR){
    800053d8:	04449703          	lh	a4,68(s1)
    800053dc:	4785                	li	a5,1
    800053de:	08f70463          	beq	a4,a5,80005466 <sys_link+0xea>
  ip->nlink++;
    800053e2:	04a4d783          	lhu	a5,74(s1)
    800053e6:	2785                	addiw	a5,a5,1
    800053e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053ec:	8526                	mv	a0,s1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	258080e7          	jalr	600(ra) # 80003646 <iupdate>
  iunlock(ip);
    800053f6:	8526                	mv	a0,s1
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	3dc080e7          	jalr	988(ra) # 800037d4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005400:	fd040593          	addi	a1,s0,-48
    80005404:	f5040513          	addi	a0,s0,-176
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	ae4080e7          	jalr	-1308(ra) # 80003eec <nameiparent>
    80005410:	892a                	mv	s2,a0
    80005412:	c935                	beqz	a0,80005486 <sys_link+0x10a>
  ilock(dp);
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	2fe080e7          	jalr	766(ra) # 80003712 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000541c:	00092703          	lw	a4,0(s2)
    80005420:	409c                	lw	a5,0(s1)
    80005422:	04f71d63          	bne	a4,a5,8000547c <sys_link+0x100>
    80005426:	40d0                	lw	a2,4(s1)
    80005428:	fd040593          	addi	a1,s0,-48
    8000542c:	854a                	mv	a0,s2
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	9de080e7          	jalr	-1570(ra) # 80003e0c <dirlink>
    80005436:	04054363          	bltz	a0,8000547c <sys_link+0x100>
  iunlockput(dp);
    8000543a:	854a                	mv	a0,s2
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	538080e7          	jalr	1336(ra) # 80003974 <iunlockput>
  iput(ip);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	486080e7          	jalr	1158(ra) # 800038cc <iput>
  end_op();
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	d1e080e7          	jalr	-738(ra) # 8000416c <end_op>
  return 0;
    80005456:	4781                	li	a5,0
    80005458:	a085                	j	800054b8 <sys_link+0x13c>
    end_op();
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	d12080e7          	jalr	-750(ra) # 8000416c <end_op>
    return -1;
    80005462:	57fd                	li	a5,-1
    80005464:	a891                	j	800054b8 <sys_link+0x13c>
    iunlockput(ip);
    80005466:	8526                	mv	a0,s1
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	50c080e7          	jalr	1292(ra) # 80003974 <iunlockput>
    end_op();
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	cfc080e7          	jalr	-772(ra) # 8000416c <end_op>
    return -1;
    80005478:	57fd                	li	a5,-1
    8000547a:	a83d                	j	800054b8 <sys_link+0x13c>
    iunlockput(dp);
    8000547c:	854a                	mv	a0,s2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	4f6080e7          	jalr	1270(ra) # 80003974 <iunlockput>
  ilock(ip);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	28a080e7          	jalr	650(ra) # 80003712 <ilock>
  ip->nlink--;
    80005490:	04a4d783          	lhu	a5,74(s1)
    80005494:	37fd                	addiw	a5,a5,-1
    80005496:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	1aa080e7          	jalr	426(ra) # 80003646 <iupdate>
  iunlockput(ip);
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	4ce080e7          	jalr	1230(ra) # 80003974 <iunlockput>
  end_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	cbe080e7          	jalr	-834(ra) # 8000416c <end_op>
  return -1;
    800054b6:	57fd                	li	a5,-1
}
    800054b8:	853e                	mv	a0,a5
    800054ba:	70b2                	ld	ra,296(sp)
    800054bc:	7412                	ld	s0,288(sp)
    800054be:	64f2                	ld	s1,280(sp)
    800054c0:	6952                	ld	s2,272(sp)
    800054c2:	6155                	addi	sp,sp,304
    800054c4:	8082                	ret

00000000800054c6 <sys_unlink>:
{
    800054c6:	7151                	addi	sp,sp,-240
    800054c8:	f586                	sd	ra,232(sp)
    800054ca:	f1a2                	sd	s0,224(sp)
    800054cc:	eda6                	sd	s1,216(sp)
    800054ce:	e9ca                	sd	s2,208(sp)
    800054d0:	e5ce                	sd	s3,200(sp)
    800054d2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054d4:	08000613          	li	a2,128
    800054d8:	f3040593          	addi	a1,s0,-208
    800054dc:	4501                	li	a0,0
    800054de:	ffffd097          	auipc	ra,0xffffd
    800054e2:	6ba080e7          	jalr	1722(ra) # 80002b98 <argstr>
    800054e6:	18054163          	bltz	a0,80005668 <sys_unlink+0x1a2>
  begin_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	c04080e7          	jalr	-1020(ra) # 800040ee <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054f2:	fb040593          	addi	a1,s0,-80
    800054f6:	f3040513          	addi	a0,s0,-208
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	9f2080e7          	jalr	-1550(ra) # 80003eec <nameiparent>
    80005502:	84aa                	mv	s1,a0
    80005504:	c979                	beqz	a0,800055da <sys_unlink+0x114>
  ilock(dp);
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	20c080e7          	jalr	524(ra) # 80003712 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000550e:	00003597          	auipc	a1,0x3
    80005512:	1fa58593          	addi	a1,a1,506 # 80008708 <syscalls+0x2c0>
    80005516:	fb040513          	addi	a0,s0,-80
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	6c2080e7          	jalr	1730(ra) # 80003bdc <namecmp>
    80005522:	14050a63          	beqz	a0,80005676 <sys_unlink+0x1b0>
    80005526:	00003597          	auipc	a1,0x3
    8000552a:	1ea58593          	addi	a1,a1,490 # 80008710 <syscalls+0x2c8>
    8000552e:	fb040513          	addi	a0,s0,-80
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	6aa080e7          	jalr	1706(ra) # 80003bdc <namecmp>
    8000553a:	12050e63          	beqz	a0,80005676 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000553e:	f2c40613          	addi	a2,s0,-212
    80005542:	fb040593          	addi	a1,s0,-80
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	6ae080e7          	jalr	1710(ra) # 80003bf6 <dirlookup>
    80005550:	892a                	mv	s2,a0
    80005552:	12050263          	beqz	a0,80005676 <sys_unlink+0x1b0>
  ilock(ip);
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	1bc080e7          	jalr	444(ra) # 80003712 <ilock>
  if(ip->nlink < 1)
    8000555e:	04a91783          	lh	a5,74(s2)
    80005562:	08f05263          	blez	a5,800055e6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005566:	04491703          	lh	a4,68(s2)
    8000556a:	4785                	li	a5,1
    8000556c:	08f70563          	beq	a4,a5,800055f6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005570:	4641                	li	a2,16
    80005572:	4581                	li	a1,0
    80005574:	fc040513          	addi	a0,s0,-64
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	79e080e7          	jalr	1950(ra) # 80000d16 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005580:	4741                	li	a4,16
    80005582:	f2c42683          	lw	a3,-212(s0)
    80005586:	fc040613          	addi	a2,s0,-64
    8000558a:	4581                	li	a1,0
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	530080e7          	jalr	1328(ra) # 80003abe <writei>
    80005596:	47c1                	li	a5,16
    80005598:	0af51563          	bne	a0,a5,80005642 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000559c:	04491703          	lh	a4,68(s2)
    800055a0:	4785                	li	a5,1
    800055a2:	0af70863          	beq	a4,a5,80005652 <sys_unlink+0x18c>
  iunlockput(dp);
    800055a6:	8526                	mv	a0,s1
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	3cc080e7          	jalr	972(ra) # 80003974 <iunlockput>
  ip->nlink--;
    800055b0:	04a95783          	lhu	a5,74(s2)
    800055b4:	37fd                	addiw	a5,a5,-1
    800055b6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055ba:	854a                	mv	a0,s2
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	08a080e7          	jalr	138(ra) # 80003646 <iupdate>
  iunlockput(ip);
    800055c4:	854a                	mv	a0,s2
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	3ae080e7          	jalr	942(ra) # 80003974 <iunlockput>
  end_op();
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	b9e080e7          	jalr	-1122(ra) # 8000416c <end_op>
  return 0;
    800055d6:	4501                	li	a0,0
    800055d8:	a84d                	j	8000568a <sys_unlink+0x1c4>
    end_op();
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	b92080e7          	jalr	-1134(ra) # 8000416c <end_op>
    return -1;
    800055e2:	557d                	li	a0,-1
    800055e4:	a05d                	j	8000568a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055e6:	00003517          	auipc	a0,0x3
    800055ea:	15250513          	addi	a0,a0,338 # 80008738 <syscalls+0x2f0>
    800055ee:	ffffb097          	auipc	ra,0xffffb
    800055f2:	f4c080e7          	jalr	-180(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055f6:	04c92703          	lw	a4,76(s2)
    800055fa:	02000793          	li	a5,32
    800055fe:	f6e7f9e3          	bgeu	a5,a4,80005570 <sys_unlink+0xaa>
    80005602:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005606:	4741                	li	a4,16
    80005608:	86ce                	mv	a3,s3
    8000560a:	f1840613          	addi	a2,s0,-232
    8000560e:	4581                	li	a1,0
    80005610:	854a                	mv	a0,s2
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	3b4080e7          	jalr	948(ra) # 800039c6 <readi>
    8000561a:	47c1                	li	a5,16
    8000561c:	00f51b63          	bne	a0,a5,80005632 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005620:	f1845783          	lhu	a5,-232(s0)
    80005624:	e7a1                	bnez	a5,8000566c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005626:	29c1                	addiw	s3,s3,16
    80005628:	04c92783          	lw	a5,76(s2)
    8000562c:	fcf9ede3          	bltu	s3,a5,80005606 <sys_unlink+0x140>
    80005630:	b781                	j	80005570 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005632:	00003517          	auipc	a0,0x3
    80005636:	11e50513          	addi	a0,a0,286 # 80008750 <syscalls+0x308>
    8000563a:	ffffb097          	auipc	ra,0xffffb
    8000563e:	f00080e7          	jalr	-256(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005642:	00003517          	auipc	a0,0x3
    80005646:	12650513          	addi	a0,a0,294 # 80008768 <syscalls+0x320>
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	ef0080e7          	jalr	-272(ra) # 8000053a <panic>
    dp->nlink--;
    80005652:	04a4d783          	lhu	a5,74(s1)
    80005656:	37fd                	addiw	a5,a5,-1
    80005658:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	fe8080e7          	jalr	-24(ra) # 80003646 <iupdate>
    80005666:	b781                	j	800055a6 <sys_unlink+0xe0>
    return -1;
    80005668:	557d                	li	a0,-1
    8000566a:	a005                	j	8000568a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000566c:	854a                	mv	a0,s2
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	306080e7          	jalr	774(ra) # 80003974 <iunlockput>
  iunlockput(dp);
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	2fc080e7          	jalr	764(ra) # 80003974 <iunlockput>
  end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	aec080e7          	jalr	-1300(ra) # 8000416c <end_op>
  return -1;
    80005688:	557d                	li	a0,-1
}
    8000568a:	70ae                	ld	ra,232(sp)
    8000568c:	740e                	ld	s0,224(sp)
    8000568e:	64ee                	ld	s1,216(sp)
    80005690:	694e                	ld	s2,208(sp)
    80005692:	69ae                	ld	s3,200(sp)
    80005694:	616d                	addi	sp,sp,240
    80005696:	8082                	ret

0000000080005698 <sys_open>:

uint64
sys_open(void)
{
    80005698:	7131                	addi	sp,sp,-192
    8000569a:	fd06                	sd	ra,184(sp)
    8000569c:	f922                	sd	s0,176(sp)
    8000569e:	f526                	sd	s1,168(sp)
    800056a0:	f14a                	sd	s2,160(sp)
    800056a2:	ed4e                	sd	s3,152(sp)
    800056a4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056a6:	08000613          	li	a2,128
    800056aa:	f5040593          	addi	a1,s0,-176
    800056ae:	4501                	li	a0,0
    800056b0:	ffffd097          	auipc	ra,0xffffd
    800056b4:	4e8080e7          	jalr	1256(ra) # 80002b98 <argstr>
    return -1;
    800056b8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ba:	0c054163          	bltz	a0,8000577c <sys_open+0xe4>
    800056be:	f4c40593          	addi	a1,s0,-180
    800056c2:	4505                	li	a0,1
    800056c4:	ffffd097          	auipc	ra,0xffffd
    800056c8:	490080e7          	jalr	1168(ra) # 80002b54 <argint>
    800056cc:	0a054863          	bltz	a0,8000577c <sys_open+0xe4>

  begin_op();
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	a1e080e7          	jalr	-1506(ra) # 800040ee <begin_op>

  if(omode & O_CREATE){
    800056d8:	f4c42783          	lw	a5,-180(s0)
    800056dc:	2007f793          	andi	a5,a5,512
    800056e0:	cbdd                	beqz	a5,80005796 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056e2:	4681                	li	a3,0
    800056e4:	4601                	li	a2,0
    800056e6:	4589                	li	a1,2
    800056e8:	f5040513          	addi	a0,s0,-176
    800056ec:	00000097          	auipc	ra,0x0
    800056f0:	970080e7          	jalr	-1680(ra) # 8000505c <create>
    800056f4:	892a                	mv	s2,a0
    if(ip == 0){
    800056f6:	c959                	beqz	a0,8000578c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056f8:	04491703          	lh	a4,68(s2)
    800056fc:	478d                	li	a5,3
    800056fe:	00f71763          	bne	a4,a5,8000570c <sys_open+0x74>
    80005702:	04695703          	lhu	a4,70(s2)
    80005706:	47a5                	li	a5,9
    80005708:	0ce7ec63          	bltu	a5,a4,800057e0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	dee080e7          	jalr	-530(ra) # 800044fa <filealloc>
    80005714:	89aa                	mv	s3,a0
    80005716:	10050263          	beqz	a0,8000581a <sys_open+0x182>
    8000571a:	00000097          	auipc	ra,0x0
    8000571e:	900080e7          	jalr	-1792(ra) # 8000501a <fdalloc>
    80005722:	84aa                	mv	s1,a0
    80005724:	0e054663          	bltz	a0,80005810 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005728:	04491703          	lh	a4,68(s2)
    8000572c:	478d                	li	a5,3
    8000572e:	0cf70463          	beq	a4,a5,800057f6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005732:	4789                	li	a5,2
    80005734:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005738:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000573c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005740:	f4c42783          	lw	a5,-180(s0)
    80005744:	0017c713          	xori	a4,a5,1
    80005748:	8b05                	andi	a4,a4,1
    8000574a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000574e:	0037f713          	andi	a4,a5,3
    80005752:	00e03733          	snez	a4,a4
    80005756:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000575a:	4007f793          	andi	a5,a5,1024
    8000575e:	c791                	beqz	a5,8000576a <sys_open+0xd2>
    80005760:	04491703          	lh	a4,68(s2)
    80005764:	4789                	li	a5,2
    80005766:	08f70f63          	beq	a4,a5,80005804 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000576a:	854a                	mv	a0,s2
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	068080e7          	jalr	104(ra) # 800037d4 <iunlock>
  end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	9f8080e7          	jalr	-1544(ra) # 8000416c <end_op>

  return fd;
}
    8000577c:	8526                	mv	a0,s1
    8000577e:	70ea                	ld	ra,184(sp)
    80005780:	744a                	ld	s0,176(sp)
    80005782:	74aa                	ld	s1,168(sp)
    80005784:	790a                	ld	s2,160(sp)
    80005786:	69ea                	ld	s3,152(sp)
    80005788:	6129                	addi	sp,sp,192
    8000578a:	8082                	ret
      end_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	9e0080e7          	jalr	-1568(ra) # 8000416c <end_op>
      return -1;
    80005794:	b7e5                	j	8000577c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005796:	f5040513          	addi	a0,s0,-176
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	734080e7          	jalr	1844(ra) # 80003ece <namei>
    800057a2:	892a                	mv	s2,a0
    800057a4:	c905                	beqz	a0,800057d4 <sys_open+0x13c>
    ilock(ip);
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	f6c080e7          	jalr	-148(ra) # 80003712 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057ae:	04491703          	lh	a4,68(s2)
    800057b2:	4785                	li	a5,1
    800057b4:	f4f712e3          	bne	a4,a5,800056f8 <sys_open+0x60>
    800057b8:	f4c42783          	lw	a5,-180(s0)
    800057bc:	dba1                	beqz	a5,8000570c <sys_open+0x74>
      iunlockput(ip);
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	1b4080e7          	jalr	436(ra) # 80003974 <iunlockput>
      end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	9a4080e7          	jalr	-1628(ra) # 8000416c <end_op>
      return -1;
    800057d0:	54fd                	li	s1,-1
    800057d2:	b76d                	j	8000577c <sys_open+0xe4>
      end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	998080e7          	jalr	-1640(ra) # 8000416c <end_op>
      return -1;
    800057dc:	54fd                	li	s1,-1
    800057de:	bf79                	j	8000577c <sys_open+0xe4>
    iunlockput(ip);
    800057e0:	854a                	mv	a0,s2
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	192080e7          	jalr	402(ra) # 80003974 <iunlockput>
    end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	982080e7          	jalr	-1662(ra) # 8000416c <end_op>
    return -1;
    800057f2:	54fd                	li	s1,-1
    800057f4:	b761                	j	8000577c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057f6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057fa:	04691783          	lh	a5,70(s2)
    800057fe:	02f99223          	sh	a5,36(s3)
    80005802:	bf2d                	j	8000573c <sys_open+0xa4>
    itrunc(ip);
    80005804:	854a                	mv	a0,s2
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	01a080e7          	jalr	26(ra) # 80003820 <itrunc>
    8000580e:	bfb1                	j	8000576a <sys_open+0xd2>
      fileclose(f);
    80005810:	854e                	mv	a0,s3
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	da4080e7          	jalr	-604(ra) # 800045b6 <fileclose>
    iunlockput(ip);
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	158080e7          	jalr	344(ra) # 80003974 <iunlockput>
    end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	948080e7          	jalr	-1720(ra) # 8000416c <end_op>
    return -1;
    8000582c:	54fd                	li	s1,-1
    8000582e:	b7b9                	j	8000577c <sys_open+0xe4>

0000000080005830 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005830:	7175                	addi	sp,sp,-144
    80005832:	e506                	sd	ra,136(sp)
    80005834:	e122                	sd	s0,128(sp)
    80005836:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	8b6080e7          	jalr	-1866(ra) # 800040ee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005840:	08000613          	li	a2,128
    80005844:	f7040593          	addi	a1,s0,-144
    80005848:	4501                	li	a0,0
    8000584a:	ffffd097          	auipc	ra,0xffffd
    8000584e:	34e080e7          	jalr	846(ra) # 80002b98 <argstr>
    80005852:	02054963          	bltz	a0,80005884 <sys_mkdir+0x54>
    80005856:	4681                	li	a3,0
    80005858:	4601                	li	a2,0
    8000585a:	4585                	li	a1,1
    8000585c:	f7040513          	addi	a0,s0,-144
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	7fc080e7          	jalr	2044(ra) # 8000505c <create>
    80005868:	cd11                	beqz	a0,80005884 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	10a080e7          	jalr	266(ra) # 80003974 <iunlockput>
  end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	8fa080e7          	jalr	-1798(ra) # 8000416c <end_op>
  return 0;
    8000587a:	4501                	li	a0,0
}
    8000587c:	60aa                	ld	ra,136(sp)
    8000587e:	640a                	ld	s0,128(sp)
    80005880:	6149                	addi	sp,sp,144
    80005882:	8082                	ret
    end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	8e8080e7          	jalr	-1816(ra) # 8000416c <end_op>
    return -1;
    8000588c:	557d                	li	a0,-1
    8000588e:	b7fd                	j	8000587c <sys_mkdir+0x4c>

0000000080005890 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005890:	7135                	addi	sp,sp,-160
    80005892:	ed06                	sd	ra,152(sp)
    80005894:	e922                	sd	s0,144(sp)
    80005896:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	856080e7          	jalr	-1962(ra) # 800040ee <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a0:	08000613          	li	a2,128
    800058a4:	f7040593          	addi	a1,s0,-144
    800058a8:	4501                	li	a0,0
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	2ee080e7          	jalr	750(ra) # 80002b98 <argstr>
    800058b2:	04054a63          	bltz	a0,80005906 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058b6:	f6c40593          	addi	a1,s0,-148
    800058ba:	4505                	li	a0,1
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	298080e7          	jalr	664(ra) # 80002b54 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058c4:	04054163          	bltz	a0,80005906 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058c8:	f6840593          	addi	a1,s0,-152
    800058cc:	4509                	li	a0,2
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	286080e7          	jalr	646(ra) # 80002b54 <argint>
     argint(1, &major) < 0 ||
    800058d6:	02054863          	bltz	a0,80005906 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058da:	f6841683          	lh	a3,-152(s0)
    800058de:	f6c41603          	lh	a2,-148(s0)
    800058e2:	458d                	li	a1,3
    800058e4:	f7040513          	addi	a0,s0,-144
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	774080e7          	jalr	1908(ra) # 8000505c <create>
     argint(2, &minor) < 0 ||
    800058f0:	c919                	beqz	a0,80005906 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	082080e7          	jalr	130(ra) # 80003974 <iunlockput>
  end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	872080e7          	jalr	-1934(ra) # 8000416c <end_op>
  return 0;
    80005902:	4501                	li	a0,0
    80005904:	a031                	j	80005910 <sys_mknod+0x80>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	866080e7          	jalr	-1946(ra) # 8000416c <end_op>
    return -1;
    8000590e:	557d                	li	a0,-1
}
    80005910:	60ea                	ld	ra,152(sp)
    80005912:	644a                	ld	s0,144(sp)
    80005914:	610d                	addi	sp,sp,160
    80005916:	8082                	ret

0000000080005918 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005918:	7135                	addi	sp,sp,-160
    8000591a:	ed06                	sd	ra,152(sp)
    8000591c:	e922                	sd	s0,144(sp)
    8000591e:	e526                	sd	s1,136(sp)
    80005920:	e14a                	sd	s2,128(sp)
    80005922:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005924:	ffffc097          	auipc	ra,0xffffc
    80005928:	0bc080e7          	jalr	188(ra) # 800019e0 <myproc>
    8000592c:	892a                	mv	s2,a0
  
  begin_op();
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	7c0080e7          	jalr	1984(ra) # 800040ee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005936:	08000613          	li	a2,128
    8000593a:	f6040593          	addi	a1,s0,-160
    8000593e:	4501                	li	a0,0
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	258080e7          	jalr	600(ra) # 80002b98 <argstr>
    80005948:	04054b63          	bltz	a0,8000599e <sys_chdir+0x86>
    8000594c:	f6040513          	addi	a0,s0,-160
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	57e080e7          	jalr	1406(ra) # 80003ece <namei>
    80005958:	84aa                	mv	s1,a0
    8000595a:	c131                	beqz	a0,8000599e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	db6080e7          	jalr	-586(ra) # 80003712 <ilock>
  if(ip->type != T_DIR){
    80005964:	04449703          	lh	a4,68(s1)
    80005968:	4785                	li	a5,1
    8000596a:	04f71063          	bne	a4,a5,800059aa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	e64080e7          	jalr	-412(ra) # 800037d4 <iunlock>
  iput(p->cwd);
    80005978:	15093503          	ld	a0,336(s2)
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	f50080e7          	jalr	-176(ra) # 800038cc <iput>
  end_op();
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	7e8080e7          	jalr	2024(ra) # 8000416c <end_op>
  p->cwd = ip;
    8000598c:	14993823          	sd	s1,336(s2)
  return 0;
    80005990:	4501                	li	a0,0
}
    80005992:	60ea                	ld	ra,152(sp)
    80005994:	644a                	ld	s0,144(sp)
    80005996:	64aa                	ld	s1,136(sp)
    80005998:	690a                	ld	s2,128(sp)
    8000599a:	610d                	addi	sp,sp,160
    8000599c:	8082                	ret
    end_op();
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	7ce080e7          	jalr	1998(ra) # 8000416c <end_op>
    return -1;
    800059a6:	557d                	li	a0,-1
    800059a8:	b7ed                	j	80005992 <sys_chdir+0x7a>
    iunlockput(ip);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	fc8080e7          	jalr	-56(ra) # 80003974 <iunlockput>
    end_op();
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	7b8080e7          	jalr	1976(ra) # 8000416c <end_op>
    return -1;
    800059bc:	557d                	li	a0,-1
    800059be:	bfd1                	j	80005992 <sys_chdir+0x7a>

00000000800059c0 <sys_exec>:

uint64
sys_exec(void)
{
    800059c0:	7145                	addi	sp,sp,-464
    800059c2:	e786                	sd	ra,456(sp)
    800059c4:	e3a2                	sd	s0,448(sp)
    800059c6:	ff26                	sd	s1,440(sp)
    800059c8:	fb4a                	sd	s2,432(sp)
    800059ca:	f74e                	sd	s3,424(sp)
    800059cc:	f352                	sd	s4,416(sp)
    800059ce:	ef56                	sd	s5,408(sp)
    800059d0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059d2:	08000613          	li	a2,128
    800059d6:	f4040593          	addi	a1,s0,-192
    800059da:	4501                	li	a0,0
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	1bc080e7          	jalr	444(ra) # 80002b98 <argstr>
    return -1;
    800059e4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059e6:	0c054b63          	bltz	a0,80005abc <sys_exec+0xfc>
    800059ea:	e3840593          	addi	a1,s0,-456
    800059ee:	4505                	li	a0,1
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	186080e7          	jalr	390(ra) # 80002b76 <argaddr>
    800059f8:	0c054263          	bltz	a0,80005abc <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059fc:	10000613          	li	a2,256
    80005a00:	4581                	li	a1,0
    80005a02:	e4040513          	addi	a0,s0,-448
    80005a06:	ffffb097          	auipc	ra,0xffffb
    80005a0a:	310080e7          	jalr	784(ra) # 80000d16 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a0e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a12:	89a6                	mv	s3,s1
    80005a14:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a16:	02000a13          	li	s4,32
    80005a1a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a1e:	00391513          	slli	a0,s2,0x3
    80005a22:	e3040593          	addi	a1,s0,-464
    80005a26:	e3843783          	ld	a5,-456(s0)
    80005a2a:	953e                	add	a0,a0,a5
    80005a2c:	ffffd097          	auipc	ra,0xffffd
    80005a30:	08e080e7          	jalr	142(ra) # 80002aba <fetchaddr>
    80005a34:	02054a63          	bltz	a0,80005a68 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a38:	e3043783          	ld	a5,-464(s0)
    80005a3c:	c3b9                	beqz	a5,80005a82 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	0a2080e7          	jalr	162(ra) # 80000ae0 <kalloc>
    80005a46:	85aa                	mv	a1,a0
    80005a48:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a4c:	cd11                	beqz	a0,80005a68 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a4e:	6605                	lui	a2,0x1
    80005a50:	e3043503          	ld	a0,-464(s0)
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	0b8080e7          	jalr	184(ra) # 80002b0c <fetchstr>
    80005a5c:	00054663          	bltz	a0,80005a68 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a60:	0905                	addi	s2,s2,1
    80005a62:	09a1                	addi	s3,s3,8
    80005a64:	fb491be3          	bne	s2,s4,80005a1a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a68:	f4040913          	addi	s2,s0,-192
    80005a6c:	6088                	ld	a0,0(s1)
    80005a6e:	c531                	beqz	a0,80005aba <sys_exec+0xfa>
    kfree(argv[i]);
    80005a70:	ffffb097          	auipc	ra,0xffffb
    80005a74:	f72080e7          	jalr	-142(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a78:	04a1                	addi	s1,s1,8
    80005a7a:	ff2499e3          	bne	s1,s2,80005a6c <sys_exec+0xac>
  return -1;
    80005a7e:	597d                	li	s2,-1
    80005a80:	a835                	j	80005abc <sys_exec+0xfc>
      argv[i] = 0;
    80005a82:	0a8e                	slli	s5,s5,0x3
    80005a84:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005a88:	00878ab3          	add	s5,a5,s0
    80005a8c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a90:	e4040593          	addi	a1,s0,-448
    80005a94:	f4040513          	addi	a0,s0,-192
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	172080e7          	jalr	370(ra) # 80004c0a <exec>
    80005aa0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa2:	f4040993          	addi	s3,s0,-192
    80005aa6:	6088                	ld	a0,0(s1)
    80005aa8:	c911                	beqz	a0,80005abc <sys_exec+0xfc>
    kfree(argv[i]);
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	f38080e7          	jalr	-200(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab2:	04a1                	addi	s1,s1,8
    80005ab4:	ff3499e3          	bne	s1,s3,80005aa6 <sys_exec+0xe6>
    80005ab8:	a011                	j	80005abc <sys_exec+0xfc>
  return -1;
    80005aba:	597d                	li	s2,-1
}
    80005abc:	854a                	mv	a0,s2
    80005abe:	60be                	ld	ra,456(sp)
    80005ac0:	641e                	ld	s0,448(sp)
    80005ac2:	74fa                	ld	s1,440(sp)
    80005ac4:	795a                	ld	s2,432(sp)
    80005ac6:	79ba                	ld	s3,424(sp)
    80005ac8:	7a1a                	ld	s4,416(sp)
    80005aca:	6afa                	ld	s5,408(sp)
    80005acc:	6179                	addi	sp,sp,464
    80005ace:	8082                	ret

0000000080005ad0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ad0:	7139                	addi	sp,sp,-64
    80005ad2:	fc06                	sd	ra,56(sp)
    80005ad4:	f822                	sd	s0,48(sp)
    80005ad6:	f426                	sd	s1,40(sp)
    80005ad8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ada:	ffffc097          	auipc	ra,0xffffc
    80005ade:	f06080e7          	jalr	-250(ra) # 800019e0 <myproc>
    80005ae2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ae4:	fd840593          	addi	a1,s0,-40
    80005ae8:	4501                	li	a0,0
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	08c080e7          	jalr	140(ra) # 80002b76 <argaddr>
    return -1;
    80005af2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005af4:	0e054063          	bltz	a0,80005bd4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005af8:	fc840593          	addi	a1,s0,-56
    80005afc:	fd040513          	addi	a0,s0,-48
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	de6080e7          	jalr	-538(ra) # 800048e6 <pipealloc>
    return -1;
    80005b08:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b0a:	0c054563          	bltz	a0,80005bd4 <sys_pipe+0x104>
  fd0 = -1;
    80005b0e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b12:	fd043503          	ld	a0,-48(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	504080e7          	jalr	1284(ra) # 8000501a <fdalloc>
    80005b1e:	fca42223          	sw	a0,-60(s0)
    80005b22:	08054c63          	bltz	a0,80005bba <sys_pipe+0xea>
    80005b26:	fc843503          	ld	a0,-56(s0)
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	4f0080e7          	jalr	1264(ra) # 8000501a <fdalloc>
    80005b32:	fca42023          	sw	a0,-64(s0)
    80005b36:	06054963          	bltz	a0,80005ba8 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b3a:	4691                	li	a3,4
    80005b3c:	fc440613          	addi	a2,s0,-60
    80005b40:	fd843583          	ld	a1,-40(s0)
    80005b44:	68a8                	ld	a0,80(s1)
    80005b46:	ffffc097          	auipc	ra,0xffffc
    80005b4a:	b5e080e7          	jalr	-1186(ra) # 800016a4 <copyout>
    80005b4e:	02054063          	bltz	a0,80005b6e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b52:	4691                	li	a3,4
    80005b54:	fc040613          	addi	a2,s0,-64
    80005b58:	fd843583          	ld	a1,-40(s0)
    80005b5c:	0591                	addi	a1,a1,4
    80005b5e:	68a8                	ld	a0,80(s1)
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	b44080e7          	jalr	-1212(ra) # 800016a4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b68:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b6a:	06055563          	bgez	a0,80005bd4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b6e:	fc442783          	lw	a5,-60(s0)
    80005b72:	07e9                	addi	a5,a5,26
    80005b74:	078e                	slli	a5,a5,0x3
    80005b76:	97a6                	add	a5,a5,s1
    80005b78:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b7c:	fc042783          	lw	a5,-64(s0)
    80005b80:	07e9                	addi	a5,a5,26
    80005b82:	078e                	slli	a5,a5,0x3
    80005b84:	00f48533          	add	a0,s1,a5
    80005b88:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b8c:	fd043503          	ld	a0,-48(s0)
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	a26080e7          	jalr	-1498(ra) # 800045b6 <fileclose>
    fileclose(wf);
    80005b98:	fc843503          	ld	a0,-56(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	a1a080e7          	jalr	-1510(ra) # 800045b6 <fileclose>
    return -1;
    80005ba4:	57fd                	li	a5,-1
    80005ba6:	a03d                	j	80005bd4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ba8:	fc442783          	lw	a5,-60(s0)
    80005bac:	0007c763          	bltz	a5,80005bba <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bb0:	07e9                	addi	a5,a5,26
    80005bb2:	078e                	slli	a5,a5,0x3
    80005bb4:	97a6                	add	a5,a5,s1
    80005bb6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bba:	fd043503          	ld	a0,-48(s0)
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	9f8080e7          	jalr	-1544(ra) # 800045b6 <fileclose>
    fileclose(wf);
    80005bc6:	fc843503          	ld	a0,-56(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	9ec080e7          	jalr	-1556(ra) # 800045b6 <fileclose>
    return -1;
    80005bd2:	57fd                	li	a5,-1
}
    80005bd4:	853e                	mv	a0,a5
    80005bd6:	70e2                	ld	ra,56(sp)
    80005bd8:	7442                	ld	s0,48(sp)
    80005bda:	74a2                	ld	s1,40(sp)
    80005bdc:	6121                	addi	sp,sp,64
    80005bde:	8082                	ret

0000000080005be0 <kernelvec>:
    80005be0:	7111                	addi	sp,sp,-256
    80005be2:	e006                	sd	ra,0(sp)
    80005be4:	e40a                	sd	sp,8(sp)
    80005be6:	e80e                	sd	gp,16(sp)
    80005be8:	ec12                	sd	tp,24(sp)
    80005bea:	f016                	sd	t0,32(sp)
    80005bec:	f41a                	sd	t1,40(sp)
    80005bee:	f81e                	sd	t2,48(sp)
    80005bf0:	fc22                	sd	s0,56(sp)
    80005bf2:	e0a6                	sd	s1,64(sp)
    80005bf4:	e4aa                	sd	a0,72(sp)
    80005bf6:	e8ae                	sd	a1,80(sp)
    80005bf8:	ecb2                	sd	a2,88(sp)
    80005bfa:	f0b6                	sd	a3,96(sp)
    80005bfc:	f4ba                	sd	a4,104(sp)
    80005bfe:	f8be                	sd	a5,112(sp)
    80005c00:	fcc2                	sd	a6,120(sp)
    80005c02:	e146                	sd	a7,128(sp)
    80005c04:	e54a                	sd	s2,136(sp)
    80005c06:	e94e                	sd	s3,144(sp)
    80005c08:	ed52                	sd	s4,152(sp)
    80005c0a:	f156                	sd	s5,160(sp)
    80005c0c:	f55a                	sd	s6,168(sp)
    80005c0e:	f95e                	sd	s7,176(sp)
    80005c10:	fd62                	sd	s8,184(sp)
    80005c12:	e1e6                	sd	s9,192(sp)
    80005c14:	e5ea                	sd	s10,200(sp)
    80005c16:	e9ee                	sd	s11,208(sp)
    80005c18:	edf2                	sd	t3,216(sp)
    80005c1a:	f1f6                	sd	t4,224(sp)
    80005c1c:	f5fa                	sd	t5,232(sp)
    80005c1e:	f9fe                	sd	t6,240(sp)
    80005c20:	d67fc0ef          	jal	ra,80002986 <kerneltrap>
    80005c24:	6082                	ld	ra,0(sp)
    80005c26:	6122                	ld	sp,8(sp)
    80005c28:	61c2                	ld	gp,16(sp)
    80005c2a:	7282                	ld	t0,32(sp)
    80005c2c:	7322                	ld	t1,40(sp)
    80005c2e:	73c2                	ld	t2,48(sp)
    80005c30:	7462                	ld	s0,56(sp)
    80005c32:	6486                	ld	s1,64(sp)
    80005c34:	6526                	ld	a0,72(sp)
    80005c36:	65c6                	ld	a1,80(sp)
    80005c38:	6666                	ld	a2,88(sp)
    80005c3a:	7686                	ld	a3,96(sp)
    80005c3c:	7726                	ld	a4,104(sp)
    80005c3e:	77c6                	ld	a5,112(sp)
    80005c40:	7866                	ld	a6,120(sp)
    80005c42:	688a                	ld	a7,128(sp)
    80005c44:	692a                	ld	s2,136(sp)
    80005c46:	69ca                	ld	s3,144(sp)
    80005c48:	6a6a                	ld	s4,152(sp)
    80005c4a:	7a8a                	ld	s5,160(sp)
    80005c4c:	7b2a                	ld	s6,168(sp)
    80005c4e:	7bca                	ld	s7,176(sp)
    80005c50:	7c6a                	ld	s8,184(sp)
    80005c52:	6c8e                	ld	s9,192(sp)
    80005c54:	6d2e                	ld	s10,200(sp)
    80005c56:	6dce                	ld	s11,208(sp)
    80005c58:	6e6e                	ld	t3,216(sp)
    80005c5a:	7e8e                	ld	t4,224(sp)
    80005c5c:	7f2e                	ld	t5,232(sp)
    80005c5e:	7fce                	ld	t6,240(sp)
    80005c60:	6111                	addi	sp,sp,256
    80005c62:	10200073          	sret
    80005c66:	00000013          	nop
    80005c6a:	00000013          	nop
    80005c6e:	0001                	nop

0000000080005c70 <timervec>:
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	e10c                	sd	a1,0(a0)
    80005c76:	e510                	sd	a2,8(a0)
    80005c78:	e914                	sd	a3,16(a0)
    80005c7a:	6d0c                	ld	a1,24(a0)
    80005c7c:	7110                	ld	a2,32(a0)
    80005c7e:	6194                	ld	a3,0(a1)
    80005c80:	96b2                	add	a3,a3,a2
    80005c82:	e194                	sd	a3,0(a1)
    80005c84:	4589                	li	a1,2
    80005c86:	14459073          	csrw	sip,a1
    80005c8a:	6914                	ld	a3,16(a0)
    80005c8c:	6510                	ld	a2,8(a0)
    80005c8e:	610c                	ld	a1,0(a0)
    80005c90:	34051573          	csrrw	a0,mscratch,a0
    80005c94:	30200073          	mret
	...

0000000080005c9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c9a:	1141                	addi	sp,sp,-16
    80005c9c:	e422                	sd	s0,8(sp)
    80005c9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ca0:	0c0007b7          	lui	a5,0xc000
    80005ca4:	4705                	li	a4,1
    80005ca6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ca8:	c3d8                	sw	a4,4(a5)
}
    80005caa:	6422                	ld	s0,8(sp)
    80005cac:	0141                	addi	sp,sp,16
    80005cae:	8082                	ret

0000000080005cb0 <plicinithart>:

void
plicinithart(void)
{
    80005cb0:	1141                	addi	sp,sp,-16
    80005cb2:	e406                	sd	ra,8(sp)
    80005cb4:	e022                	sd	s0,0(sp)
    80005cb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	cfc080e7          	jalr	-772(ra) # 800019b4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cc0:	0085171b          	slliw	a4,a0,0x8
    80005cc4:	0c0027b7          	lui	a5,0xc002
    80005cc8:	97ba                	add	a5,a5,a4
    80005cca:	40200713          	li	a4,1026
    80005cce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cd2:	00d5151b          	slliw	a0,a0,0xd
    80005cd6:	0c2017b7          	lui	a5,0xc201
    80005cda:	97aa                	add	a5,a5,a0
    80005cdc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ce0:	60a2                	ld	ra,8(sp)
    80005ce2:	6402                	ld	s0,0(sp)
    80005ce4:	0141                	addi	sp,sp,16
    80005ce6:	8082                	ret

0000000080005ce8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ce8:	1141                	addi	sp,sp,-16
    80005cea:	e406                	sd	ra,8(sp)
    80005cec:	e022                	sd	s0,0(sp)
    80005cee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf0:	ffffc097          	auipc	ra,0xffffc
    80005cf4:	cc4080e7          	jalr	-828(ra) # 800019b4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cf8:	00d5151b          	slliw	a0,a0,0xd
    80005cfc:	0c2017b7          	lui	a5,0xc201
    80005d00:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d02:	43c8                	lw	a0,4(a5)
    80005d04:	60a2                	ld	ra,8(sp)
    80005d06:	6402                	ld	s0,0(sp)
    80005d08:	0141                	addi	sp,sp,16
    80005d0a:	8082                	ret

0000000080005d0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d0c:	1101                	addi	sp,sp,-32
    80005d0e:	ec06                	sd	ra,24(sp)
    80005d10:	e822                	sd	s0,16(sp)
    80005d12:	e426                	sd	s1,8(sp)
    80005d14:	1000                	addi	s0,sp,32
    80005d16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	c9c080e7          	jalr	-868(ra) # 800019b4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d20:	00d5151b          	slliw	a0,a0,0xd
    80005d24:	0c2017b7          	lui	a5,0xc201
    80005d28:	97aa                	add	a5,a5,a0
    80005d2a:	c3c4                	sw	s1,4(a5)
}
    80005d2c:	60e2                	ld	ra,24(sp)
    80005d2e:	6442                	ld	s0,16(sp)
    80005d30:	64a2                	ld	s1,8(sp)
    80005d32:	6105                	addi	sp,sp,32
    80005d34:	8082                	ret

0000000080005d36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d36:	1141                	addi	sp,sp,-16
    80005d38:	e406                	sd	ra,8(sp)
    80005d3a:	e022                	sd	s0,0(sp)
    80005d3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d3e:	479d                	li	a5,7
    80005d40:	06a7c863          	blt	a5,a0,80005db0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005d44:	0001d717          	auipc	a4,0x1d
    80005d48:	2bc70713          	addi	a4,a4,700 # 80023000 <disk>
    80005d4c:	972a                	add	a4,a4,a0
    80005d4e:	6789                	lui	a5,0x2
    80005d50:	97ba                	add	a5,a5,a4
    80005d52:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d56:	e7ad                	bnez	a5,80005dc0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d58:	00451793          	slli	a5,a0,0x4
    80005d5c:	0001f717          	auipc	a4,0x1f
    80005d60:	2a470713          	addi	a4,a4,676 # 80025000 <disk+0x2000>
    80005d64:	6314                	ld	a3,0(a4)
    80005d66:	96be                	add	a3,a3,a5
    80005d68:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d6c:	6314                	ld	a3,0(a4)
    80005d6e:	96be                	add	a3,a3,a5
    80005d70:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d74:	6314                	ld	a3,0(a4)
    80005d76:	96be                	add	a3,a3,a5
    80005d78:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d7c:	6318                	ld	a4,0(a4)
    80005d7e:	97ba                	add	a5,a5,a4
    80005d80:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d84:	0001d717          	auipc	a4,0x1d
    80005d88:	27c70713          	addi	a4,a4,636 # 80023000 <disk>
    80005d8c:	972a                	add	a4,a4,a0
    80005d8e:	6789                	lui	a5,0x2
    80005d90:	97ba                	add	a5,a5,a4
    80005d92:	4705                	li	a4,1
    80005d94:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d98:	0001f517          	auipc	a0,0x1f
    80005d9c:	28050513          	addi	a0,a0,640 # 80025018 <disk+0x2018>
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	490080e7          	jalr	1168(ra) # 80002230 <wakeup>
}
    80005da8:	60a2                	ld	ra,8(sp)
    80005daa:	6402                	ld	s0,0(sp)
    80005dac:	0141                	addi	sp,sp,16
    80005dae:	8082                	ret
    panic("free_desc 1");
    80005db0:	00003517          	auipc	a0,0x3
    80005db4:	9c850513          	addi	a0,a0,-1592 # 80008778 <syscalls+0x330>
    80005db8:	ffffa097          	auipc	ra,0xffffa
    80005dbc:	782080e7          	jalr	1922(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005dc0:	00003517          	auipc	a0,0x3
    80005dc4:	9c850513          	addi	a0,a0,-1592 # 80008788 <syscalls+0x340>
    80005dc8:	ffffa097          	auipc	ra,0xffffa
    80005dcc:	772080e7          	jalr	1906(ra) # 8000053a <panic>

0000000080005dd0 <virtio_disk_init>:
{
    80005dd0:	1101                	addi	sp,sp,-32
    80005dd2:	ec06                	sd	ra,24(sp)
    80005dd4:	e822                	sd	s0,16(sp)
    80005dd6:	e426                	sd	s1,8(sp)
    80005dd8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dda:	00003597          	auipc	a1,0x3
    80005dde:	9be58593          	addi	a1,a1,-1602 # 80008798 <syscalls+0x350>
    80005de2:	0001f517          	auipc	a0,0x1f
    80005de6:	34650513          	addi	a0,a0,838 # 80025128 <disk+0x2128>
    80005dea:	ffffb097          	auipc	ra,0xffffb
    80005dee:	da0080e7          	jalr	-608(ra) # 80000b8a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005df2:	100017b7          	lui	a5,0x10001
    80005df6:	4398                	lw	a4,0(a5)
    80005df8:	2701                	sext.w	a4,a4
    80005dfa:	747277b7          	lui	a5,0x74727
    80005dfe:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e02:	0ef71063          	bne	a4,a5,80005ee2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e06:	100017b7          	lui	a5,0x10001
    80005e0a:	43dc                	lw	a5,4(a5)
    80005e0c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e0e:	4705                	li	a4,1
    80005e10:	0ce79963          	bne	a5,a4,80005ee2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e14:	100017b7          	lui	a5,0x10001
    80005e18:	479c                	lw	a5,8(a5)
    80005e1a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e1c:	4709                	li	a4,2
    80005e1e:	0ce79263          	bne	a5,a4,80005ee2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e22:	100017b7          	lui	a5,0x10001
    80005e26:	47d8                	lw	a4,12(a5)
    80005e28:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2a:	554d47b7          	lui	a5,0x554d4
    80005e2e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e32:	0af71863          	bne	a4,a5,80005ee2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e36:	100017b7          	lui	a5,0x10001
    80005e3a:	4705                	li	a4,1
    80005e3c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e3e:	470d                	li	a4,3
    80005e40:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e42:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e44:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e48:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e4c:	8f75                	and	a4,a4,a3
    80005e4e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e50:	472d                	li	a4,11
    80005e52:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e54:	473d                	li	a4,15
    80005e56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e58:	6705                	lui	a4,0x1
    80005e5a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e5c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e60:	5bdc                	lw	a5,52(a5)
    80005e62:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e64:	c7d9                	beqz	a5,80005ef2 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e66:	471d                	li	a4,7
    80005e68:	08f77d63          	bgeu	a4,a5,80005f02 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e6c:	100014b7          	lui	s1,0x10001
    80005e70:	47a1                	li	a5,8
    80005e72:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e74:	6609                	lui	a2,0x2
    80005e76:	4581                	li	a1,0
    80005e78:	0001d517          	auipc	a0,0x1d
    80005e7c:	18850513          	addi	a0,a0,392 # 80023000 <disk>
    80005e80:	ffffb097          	auipc	ra,0xffffb
    80005e84:	e96080e7          	jalr	-362(ra) # 80000d16 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e88:	0001d717          	auipc	a4,0x1d
    80005e8c:	17870713          	addi	a4,a4,376 # 80023000 <disk>
    80005e90:	00c75793          	srli	a5,a4,0xc
    80005e94:	2781                	sext.w	a5,a5
    80005e96:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e98:	0001f797          	auipc	a5,0x1f
    80005e9c:	16878793          	addi	a5,a5,360 # 80025000 <disk+0x2000>
    80005ea0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ea2:	0001d717          	auipc	a4,0x1d
    80005ea6:	1de70713          	addi	a4,a4,478 # 80023080 <disk+0x80>
    80005eaa:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005eac:	0001e717          	auipc	a4,0x1e
    80005eb0:	15470713          	addi	a4,a4,340 # 80024000 <disk+0x1000>
    80005eb4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eb6:	4705                	li	a4,1
    80005eb8:	00e78c23          	sb	a4,24(a5)
    80005ebc:	00e78ca3          	sb	a4,25(a5)
    80005ec0:	00e78d23          	sb	a4,26(a5)
    80005ec4:	00e78da3          	sb	a4,27(a5)
    80005ec8:	00e78e23          	sb	a4,28(a5)
    80005ecc:	00e78ea3          	sb	a4,29(a5)
    80005ed0:	00e78f23          	sb	a4,30(a5)
    80005ed4:	00e78fa3          	sb	a4,31(a5)
}
    80005ed8:	60e2                	ld	ra,24(sp)
    80005eda:	6442                	ld	s0,16(sp)
    80005edc:	64a2                	ld	s1,8(sp)
    80005ede:	6105                	addi	sp,sp,32
    80005ee0:	8082                	ret
    panic("could not find virtio disk");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	8c650513          	addi	a0,a0,-1850 # 800087a8 <syscalls+0x360>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	650080e7          	jalr	1616(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	8d650513          	addi	a0,a0,-1834 # 800087c8 <syscalls+0x380>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	640080e7          	jalr	1600(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	8e650513          	addi	a0,a0,-1818 # 800087e8 <syscalls+0x3a0>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	630080e7          	jalr	1584(ra) # 8000053a <panic>

0000000080005f12 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f12:	7119                	addi	sp,sp,-128
    80005f14:	fc86                	sd	ra,120(sp)
    80005f16:	f8a2                	sd	s0,112(sp)
    80005f18:	f4a6                	sd	s1,104(sp)
    80005f1a:	f0ca                	sd	s2,96(sp)
    80005f1c:	ecce                	sd	s3,88(sp)
    80005f1e:	e8d2                	sd	s4,80(sp)
    80005f20:	e4d6                	sd	s5,72(sp)
    80005f22:	e0da                	sd	s6,64(sp)
    80005f24:	fc5e                	sd	s7,56(sp)
    80005f26:	f862                	sd	s8,48(sp)
    80005f28:	f466                	sd	s9,40(sp)
    80005f2a:	f06a                	sd	s10,32(sp)
    80005f2c:	ec6e                	sd	s11,24(sp)
    80005f2e:	0100                	addi	s0,sp,128
    80005f30:	8aaa                	mv	s5,a0
    80005f32:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f34:	00c52c83          	lw	s9,12(a0)
    80005f38:	001c9c9b          	slliw	s9,s9,0x1
    80005f3c:	1c82                	slli	s9,s9,0x20
    80005f3e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f42:	0001f517          	auipc	a0,0x1f
    80005f46:	1e650513          	addi	a0,a0,486 # 80025128 <disk+0x2128>
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	cd0080e7          	jalr	-816(ra) # 80000c1a <acquire>
  for(int i = 0; i < 3; i++){
    80005f52:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f54:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f56:	0001dc17          	auipc	s8,0x1d
    80005f5a:	0aac0c13          	addi	s8,s8,170 # 80023000 <disk>
    80005f5e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f60:	4b0d                	li	s6,3
    80005f62:	a0ad                	j	80005fcc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f64:	00fc0733          	add	a4,s8,a5
    80005f68:	975e                	add	a4,a4,s7
    80005f6a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f6e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f70:	0207c563          	bltz	a5,80005f9a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f74:	2905                	addiw	s2,s2,1
    80005f76:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005f78:	19690c63          	beq	s2,s6,80006110 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005f7c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f7e:	0001f717          	auipc	a4,0x1f
    80005f82:	09a70713          	addi	a4,a4,154 # 80025018 <disk+0x2018>
    80005f86:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f88:	00074683          	lbu	a3,0(a4)
    80005f8c:	fee1                	bnez	a3,80005f64 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f8e:	2785                	addiw	a5,a5,1
    80005f90:	0705                	addi	a4,a4,1
    80005f92:	fe979be3          	bne	a5,s1,80005f88 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f96:	57fd                	li	a5,-1
    80005f98:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f9a:	01205d63          	blez	s2,80005fb4 <virtio_disk_rw+0xa2>
    80005f9e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fa0:	000a2503          	lw	a0,0(s4)
    80005fa4:	00000097          	auipc	ra,0x0
    80005fa8:	d92080e7          	jalr	-622(ra) # 80005d36 <free_desc>
      for(int j = 0; j < i; j++)
    80005fac:	2d85                	addiw	s11,s11,1
    80005fae:	0a11                	addi	s4,s4,4
    80005fb0:	ff2d98e3          	bne	s11,s2,80005fa0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fb4:	0001f597          	auipc	a1,0x1f
    80005fb8:	17458593          	addi	a1,a1,372 # 80025128 <disk+0x2128>
    80005fbc:	0001f517          	auipc	a0,0x1f
    80005fc0:	05c50513          	addi	a0,a0,92 # 80025018 <disk+0x2018>
    80005fc4:	ffffc097          	auipc	ra,0xffffc
    80005fc8:	0e0080e7          	jalr	224(ra) # 800020a4 <sleep>
  for(int i = 0; i < 3; i++){
    80005fcc:	f8040a13          	addi	s4,s0,-128
{
    80005fd0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fd2:	894e                	mv	s2,s3
    80005fd4:	b765                	j	80005f7c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fd6:	0001f697          	auipc	a3,0x1f
    80005fda:	02a6b683          	ld	a3,42(a3) # 80025000 <disk+0x2000>
    80005fde:	96ba                	add	a3,a3,a4
    80005fe0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fe4:	0001d817          	auipc	a6,0x1d
    80005fe8:	01c80813          	addi	a6,a6,28 # 80023000 <disk>
    80005fec:	0001f697          	auipc	a3,0x1f
    80005ff0:	01468693          	addi	a3,a3,20 # 80025000 <disk+0x2000>
    80005ff4:	6290                	ld	a2,0(a3)
    80005ff6:	963a                	add	a2,a2,a4
    80005ff8:	00c65583          	lhu	a1,12(a2)
    80005ffc:	0015e593          	ori	a1,a1,1
    80006000:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006004:	f8842603          	lw	a2,-120(s0)
    80006008:	628c                	ld	a1,0(a3)
    8000600a:	972e                	add	a4,a4,a1
    8000600c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006010:	20050593          	addi	a1,a0,512
    80006014:	0592                	slli	a1,a1,0x4
    80006016:	95c2                	add	a1,a1,a6
    80006018:	577d                	li	a4,-1
    8000601a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000601e:	00461713          	slli	a4,a2,0x4
    80006022:	6290                	ld	a2,0(a3)
    80006024:	963a                	add	a2,a2,a4
    80006026:	03078793          	addi	a5,a5,48
    8000602a:	97c2                	add	a5,a5,a6
    8000602c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000602e:	629c                	ld	a5,0(a3)
    80006030:	97ba                	add	a5,a5,a4
    80006032:	4605                	li	a2,1
    80006034:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006036:	629c                	ld	a5,0(a3)
    80006038:	97ba                	add	a5,a5,a4
    8000603a:	4809                	li	a6,2
    8000603c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006040:	629c                	ld	a5,0(a3)
    80006042:	97ba                	add	a5,a5,a4
    80006044:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006048:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000604c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006050:	6698                	ld	a4,8(a3)
    80006052:	00275783          	lhu	a5,2(a4)
    80006056:	8b9d                	andi	a5,a5,7
    80006058:	0786                	slli	a5,a5,0x1
    8000605a:	973e                	add	a4,a4,a5
    8000605c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006060:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006064:	6698                	ld	a4,8(a3)
    80006066:	00275783          	lhu	a5,2(a4)
    8000606a:	2785                	addiw	a5,a5,1
    8000606c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006070:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006074:	100017b7          	lui	a5,0x10001
    80006078:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000607c:	004aa783          	lw	a5,4(s5)
    80006080:	02c79163          	bne	a5,a2,800060a2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006084:	0001f917          	auipc	s2,0x1f
    80006088:	0a490913          	addi	s2,s2,164 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000608c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000608e:	85ca                	mv	a1,s2
    80006090:	8556                	mv	a0,s5
    80006092:	ffffc097          	auipc	ra,0xffffc
    80006096:	012080e7          	jalr	18(ra) # 800020a4 <sleep>
  while(b->disk == 1) {
    8000609a:	004aa783          	lw	a5,4(s5)
    8000609e:	fe9788e3          	beq	a5,s1,8000608e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060a2:	f8042903          	lw	s2,-128(s0)
    800060a6:	20090713          	addi	a4,s2,512
    800060aa:	0712                	slli	a4,a4,0x4
    800060ac:	0001d797          	auipc	a5,0x1d
    800060b0:	f5478793          	addi	a5,a5,-172 # 80023000 <disk>
    800060b4:	97ba                	add	a5,a5,a4
    800060b6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060ba:	0001f997          	auipc	s3,0x1f
    800060be:	f4698993          	addi	s3,s3,-186 # 80025000 <disk+0x2000>
    800060c2:	00491713          	slli	a4,s2,0x4
    800060c6:	0009b783          	ld	a5,0(s3)
    800060ca:	97ba                	add	a5,a5,a4
    800060cc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060d0:	854a                	mv	a0,s2
    800060d2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060d6:	00000097          	auipc	ra,0x0
    800060da:	c60080e7          	jalr	-928(ra) # 80005d36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060de:	8885                	andi	s1,s1,1
    800060e0:	f0ed                	bnez	s1,800060c2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060e2:	0001f517          	auipc	a0,0x1f
    800060e6:	04650513          	addi	a0,a0,70 # 80025128 <disk+0x2128>
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	be4080e7          	jalr	-1052(ra) # 80000cce <release>
}
    800060f2:	70e6                	ld	ra,120(sp)
    800060f4:	7446                	ld	s0,112(sp)
    800060f6:	74a6                	ld	s1,104(sp)
    800060f8:	7906                	ld	s2,96(sp)
    800060fa:	69e6                	ld	s3,88(sp)
    800060fc:	6a46                	ld	s4,80(sp)
    800060fe:	6aa6                	ld	s5,72(sp)
    80006100:	6b06                	ld	s6,64(sp)
    80006102:	7be2                	ld	s7,56(sp)
    80006104:	7c42                	ld	s8,48(sp)
    80006106:	7ca2                	ld	s9,40(sp)
    80006108:	7d02                	ld	s10,32(sp)
    8000610a:	6de2                	ld	s11,24(sp)
    8000610c:	6109                	addi	sp,sp,128
    8000610e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006110:	f8042503          	lw	a0,-128(s0)
    80006114:	20050793          	addi	a5,a0,512
    80006118:	0792                	slli	a5,a5,0x4
  if(write)
    8000611a:	0001d817          	auipc	a6,0x1d
    8000611e:	ee680813          	addi	a6,a6,-282 # 80023000 <disk>
    80006122:	00f80733          	add	a4,a6,a5
    80006126:	01a036b3          	snez	a3,s10
    8000612a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000612e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006132:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006136:	7679                	lui	a2,0xffffe
    80006138:	963e                	add	a2,a2,a5
    8000613a:	0001f697          	auipc	a3,0x1f
    8000613e:	ec668693          	addi	a3,a3,-314 # 80025000 <disk+0x2000>
    80006142:	6298                	ld	a4,0(a3)
    80006144:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006146:	0a878593          	addi	a1,a5,168
    8000614a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000614c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000614e:	6298                	ld	a4,0(a3)
    80006150:	9732                	add	a4,a4,a2
    80006152:	45c1                	li	a1,16
    80006154:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006156:	6298                	ld	a4,0(a3)
    80006158:	9732                	add	a4,a4,a2
    8000615a:	4585                	li	a1,1
    8000615c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006160:	f8442703          	lw	a4,-124(s0)
    80006164:	628c                	ld	a1,0(a3)
    80006166:	962e                	add	a2,a2,a1
    80006168:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000616c:	0712                	slli	a4,a4,0x4
    8000616e:	6290                	ld	a2,0(a3)
    80006170:	963a                	add	a2,a2,a4
    80006172:	058a8593          	addi	a1,s5,88
    80006176:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006178:	6294                	ld	a3,0(a3)
    8000617a:	96ba                	add	a3,a3,a4
    8000617c:	40000613          	li	a2,1024
    80006180:	c690                	sw	a2,8(a3)
  if(write)
    80006182:	e40d1ae3          	bnez	s10,80005fd6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006186:	0001f697          	auipc	a3,0x1f
    8000618a:	e7a6b683          	ld	a3,-390(a3) # 80025000 <disk+0x2000>
    8000618e:	96ba                	add	a3,a3,a4
    80006190:	4609                	li	a2,2
    80006192:	00c69623          	sh	a2,12(a3)
    80006196:	b5b9                	j	80005fe4 <virtio_disk_rw+0xd2>

0000000080006198 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006198:	1101                	addi	sp,sp,-32
    8000619a:	ec06                	sd	ra,24(sp)
    8000619c:	e822                	sd	s0,16(sp)
    8000619e:	e426                	sd	s1,8(sp)
    800061a0:	e04a                	sd	s2,0(sp)
    800061a2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061a4:	0001f517          	auipc	a0,0x1f
    800061a8:	f8450513          	addi	a0,a0,-124 # 80025128 <disk+0x2128>
    800061ac:	ffffb097          	auipc	ra,0xffffb
    800061b0:	a6e080e7          	jalr	-1426(ra) # 80000c1a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061b4:	10001737          	lui	a4,0x10001
    800061b8:	533c                	lw	a5,96(a4)
    800061ba:	8b8d                	andi	a5,a5,3
    800061bc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061be:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061c2:	0001f797          	auipc	a5,0x1f
    800061c6:	e3e78793          	addi	a5,a5,-450 # 80025000 <disk+0x2000>
    800061ca:	6b94                	ld	a3,16(a5)
    800061cc:	0207d703          	lhu	a4,32(a5)
    800061d0:	0026d783          	lhu	a5,2(a3)
    800061d4:	06f70163          	beq	a4,a5,80006236 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061d8:	0001d917          	auipc	s2,0x1d
    800061dc:	e2890913          	addi	s2,s2,-472 # 80023000 <disk>
    800061e0:	0001f497          	auipc	s1,0x1f
    800061e4:	e2048493          	addi	s1,s1,-480 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061e8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061ec:	6898                	ld	a4,16(s1)
    800061ee:	0204d783          	lhu	a5,32(s1)
    800061f2:	8b9d                	andi	a5,a5,7
    800061f4:	078e                	slli	a5,a5,0x3
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061fa:	20078713          	addi	a4,a5,512
    800061fe:	0712                	slli	a4,a4,0x4
    80006200:	974a                	add	a4,a4,s2
    80006202:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006206:	e731                	bnez	a4,80006252 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006208:	20078793          	addi	a5,a5,512
    8000620c:	0792                	slli	a5,a5,0x4
    8000620e:	97ca                	add	a5,a5,s2
    80006210:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006212:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006216:	ffffc097          	auipc	ra,0xffffc
    8000621a:	01a080e7          	jalr	26(ra) # 80002230 <wakeup>

    disk.used_idx += 1;
    8000621e:	0204d783          	lhu	a5,32(s1)
    80006222:	2785                	addiw	a5,a5,1
    80006224:	17c2                	slli	a5,a5,0x30
    80006226:	93c1                	srli	a5,a5,0x30
    80006228:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000622c:	6898                	ld	a4,16(s1)
    8000622e:	00275703          	lhu	a4,2(a4)
    80006232:	faf71be3          	bne	a4,a5,800061e8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006236:	0001f517          	auipc	a0,0x1f
    8000623a:	ef250513          	addi	a0,a0,-270 # 80025128 <disk+0x2128>
    8000623e:	ffffb097          	auipc	ra,0xffffb
    80006242:	a90080e7          	jalr	-1392(ra) # 80000cce <release>
}
    80006246:	60e2                	ld	ra,24(sp)
    80006248:	6442                	ld	s0,16(sp)
    8000624a:	64a2                	ld	s1,8(sp)
    8000624c:	6902                	ld	s2,0(sp)
    8000624e:	6105                	addi	sp,sp,32
    80006250:	8082                	ret
      panic("virtio_disk_intr status");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	5b650513          	addi	a0,a0,1462 # 80008808 <syscalls+0x3c0>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e0080e7          	jalr	736(ra) # 8000053a <panic>
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
