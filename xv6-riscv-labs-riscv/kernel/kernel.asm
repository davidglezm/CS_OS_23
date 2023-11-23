
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	23e78793          	addi	a5,a5,574 # 800062a0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffc87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e1278793          	addi	a5,a5,-494 # 80000ebe <main>
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
    8000012e:	470080e7          	jalr	1136(ra) # 8000259a <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
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
    80000196:	a8a080e7          	jalr	-1398(ra) # 80000c1c <acquire>
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
    800001b0:	07305963          	blez	s3,80000222 <consoleread+0xbe>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71563          	bne	a4,a5,800001e6 <consoleread+0x82>
      if(myproc()->killed){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	876080e7          	jalr	-1930(ra) # 80001a36 <myproc>
    800001c8:	30052783          	lw	a5,768(a0)
    800001cc:	e7b5                	bnez	a5,80000238 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	f92080e7          	jalr	-110(ra) # 80002164 <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fcf70fe3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e6:	0017871b          	addiw	a4,a5,1
    800001ea:	08e4ac23          	sw	a4,152(s1)
    800001ee:	07f7f713          	andi	a4,a5,127
    800001f2:	9726                	add	a4,a4,s1
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fc:	077d0563          	beq	s10,s7,80000266 <consoleread+0x102>
    cbuf = c;
    80000200:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000204:	4685                	li	a3,1
    80000206:	f9f40613          	addi	a2,s0,-97
    8000020a:	85d2                	mv	a1,s4
    8000020c:	8556                	mv	a0,s5
    8000020e:	00002097          	auipc	ra,0x2
    80000212:	334080e7          	jalr	820(ra) # 80002542 <either_copyout>
    80000216:	01850663          	beq	a0,s8,80000222 <consoleread+0xbe>
    dst++;
    8000021a:	0a05                	addi	s4,s4,1
    --n;
    8000021c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021e:	f99d19e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000222:	00011517          	auipc	a0,0x11
    80000226:	f5e50513          	addi	a0,a0,-162 # 80011180 <cons>
    8000022a:	00001097          	auipc	ra,0x1
    8000022e:	aa6080e7          	jalr	-1370(ra) # 80000cd0 <release>

  return target - n;
    80000232:	413b053b          	subw	a0,s6,s3
    80000236:	a811                	j	8000024a <consoleread+0xe6>
        release(&cons.lock);
    80000238:	00011517          	auipc	a0,0x11
    8000023c:	f4850513          	addi	a0,a0,-184 # 80011180 <cons>
    80000240:	00001097          	auipc	ra,0x1
    80000244:	a90080e7          	jalr	-1392(ra) # 80000cd0 <release>
        return -1;
    80000248:	557d                	li	a0,-1
}
    8000024a:	70a6                	ld	ra,104(sp)
    8000024c:	7406                	ld	s0,96(sp)
    8000024e:	64e6                	ld	s1,88(sp)
    80000250:	6946                	ld	s2,80(sp)
    80000252:	69a6                	ld	s3,72(sp)
    80000254:	6a06                	ld	s4,64(sp)
    80000256:	7ae2                	ld	s5,56(sp)
    80000258:	7b42                	ld	s6,48(sp)
    8000025a:	7ba2                	ld	s7,40(sp)
    8000025c:	7c02                	ld	s8,32(sp)
    8000025e:	6ce2                	ld	s9,24(sp)
    80000260:	6d42                	ld	s10,16(sp)
    80000262:	6165                	addi	sp,sp,112
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677ce3          	bgeu	a4,s6,80000222 <consoleread+0xbe>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	faf72523          	sw	a5,-86(a4) # 80011218 <cons+0x98>
    80000276:	b775                	j	80000222 <consoleread+0xbe>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	eb850513          	addi	a0,a0,-328 # 80011180 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	94c080e7          	jalr	-1716(ra) # 80000c1c <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	304080e7          	jalr	772(ra) # 800025f2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	e8a50513          	addi	a0,a0,-374 # 80011180 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	9d2080e7          	jalr	-1582(ra) # 80000cd0 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	e6670713          	addi	a4,a4,-410 # 80011180 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000344:	00011797          	auipc	a5,0x11
    80000348:	e3c78793          	addi	a5,a5,-452 # 80011180 <cons>
    8000034c:	0a07a703          	lw	a4,160(a5)
    80000350:	0017069b          	addiw	a3,a4,1
    80000354:	0006861b          	sext.w	a2,a3
    80000358:	0ad7a023          	sw	a3,160(a5)
    8000035c:	07f77713          	andi	a4,a4,127
    80000360:	97ba                	add	a5,a5,a4
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	ea67a783          	lw	a5,-346(a5) # 80011218 <cons+0x98>
    8000037a:	0807879b          	addiw	a5,a5,128
    8000037e:	f6f61ce3          	bne	a2,a5,800002f6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000382:	863e                	mv	a2,a5
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	dfa70713          	addi	a4,a4,-518 # 80011180 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	dea48493          	addi	s1,s1,-534 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00011717          	auipc	a4,0x11
    800003d6:	dae70713          	addi	a4,a4,-594 # 80011180 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	e2f72c23          	sw	a5,-456(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040e:	00011797          	auipc	a5,0x11
    80000412:	d7278793          	addi	a5,a5,-654 # 80011180 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00011797          	auipc	a5,0x11
    80000436:	dec7a523          	sw	a2,-534(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	dde50513          	addi	a0,a0,-546 # 80011218 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	ec6080e7          	jalr	-314(ra) # 80002308 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00011517          	auipc	a0,0x11
    80000460:	d2450513          	addi	a0,a0,-732 # 80011180 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	728080e7          	jalr	1832(ra) # 80000b8c <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00031797          	auipc	a5,0x31
    80000478:	4bc78793          	addi	a5,a5,1212 # 80031930 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	addi	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	addi	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00011797          	auipc	a5,0x11
    8000054c:	ce07ac23          	sw	zero,-776(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	addi	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	addi	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00009717          	auipc	a4,0x9
    80000580:	a8f72223          	sw	a5,-1404(a4) # 80009000 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	addi	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	addi	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00011d97          	auipc	s11,0x11
    800005bc:	c88dad83          	lw	s11,-888(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	addi	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	addi	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00011517          	auipc	a0,0x11
    800005fa:	c3250513          	addi	a0,a0,-974 # 80011228 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	61e080e7          	jalr	1566(ra) # 80000c1c <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	addi	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	addi	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srli	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	slli	s2,s2,0x4
    800006d4:	34fd                	addiw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	addi	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	addi	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	addi	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	addi	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00011517          	auipc	a0,0x11
    80000758:	ad450513          	addi	a0,a0,-1324 # 80011228 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	574080e7          	jalr	1396(ra) # 80000cd0 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	addi	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00011497          	auipc	s1,0x11
    80000774:	ab848493          	addi	s1,s1,-1352 # 80011228 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	addi	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	40a080e7          	jalr	1034(ra) # 80000b8c <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	addi	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	addi	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	addi	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00011517          	auipc	a0,0x11
    800007d4:	a7850513          	addi	a0,a0,-1416 # 80011248 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	3b4080e7          	jalr	948(ra) # 80000b8c <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	addi	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	3dc080e7          	jalr	988(ra) # 80000bd0 <push_off>

  if(panicked){
    800007fc:	00009797          	auipc	a5,0x9
    80000800:	8047a783          	lw	a5,-2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	andi	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	44e080e7          	jalr	1102(ra) # 80000c70 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	addi	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	7d47b783          	ld	a5,2004(a5) # 80009008 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	7d473703          	ld	a4,2004(a4) # 80009010 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	addi	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00011a17          	auipc	s4,0x11
    80000862:	9eaa0a13          	addi	s4,s4,-1558 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	7a248493          	addi	s1,s1,1954 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	7a298993          	addi	s3,s3,1954 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	andi	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	andi	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	addi	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	a78080e7          	jalr	-1416(ra) # 80002308 <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	addi	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	addi	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	addi	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00011517          	auipc	a0,0x11
    800008d0:	97c50513          	addi	a0,a0,-1668 # 80011248 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	348080e7          	jalr	840(ra) # 80000c1c <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	7247a783          	lw	a5,1828(a5) # 80009000 <panicked>
    800008e4:	c391                	beqz	a5,800008e8 <uartputc+0x2e>
    for(;;)
    800008e6:	a001                	j	800008e6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	72873703          	ld	a4,1832(a4) # 80009010 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	7187b783          	ld	a5,1816(a5) # 80009008 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    800008fc:	02e79b63          	bne	a5,a4,80000932 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000900:	00011997          	auipc	s3,0x11
    80000904:	94898993          	addi	s3,s3,-1720 # 80011248 <uart_tx_lock>
    80000908:	00008497          	auipc	s1,0x8
    8000090c:	70048493          	addi	s1,s1,1792 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000910:	00008917          	auipc	s2,0x8
    80000914:	70090913          	addi	s2,s2,1792 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	848080e7          	jalr	-1976(ra) # 80002164 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00011497          	auipc	s1,0x11
    80000936:	91648493          	addi	s1,s1,-1770 # 80011248 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	6ce7b523          	sd	a4,1738(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee6080e7          	jalr	-282(ra) # 80000834 <uartstart>
      release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	378080e7          	jalr	888(ra) # 80000cd0 <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	addi	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	andi	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00011497          	auipc	s1,0x11
    800009ba:	89248493          	addi	s1,s1,-1902 # 80011248 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	25c080e7          	jalr	604(ra) # 80000c1c <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2fe080e7          	jalr	766(ra) # 80000cd0 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00035797          	auipc	a5,0x35
    800009fc:	60878793          	addi	a5,a5,1544 # 80036000 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	308080e7          	jalr	776(ra) # 80000d18 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00011917          	auipc	s2,0x11
    80000a1c:	86890913          	addi	s2,s2,-1944 # 80011280 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1fa080e7          	jalr	506(ra) # 80000c1c <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	29a080e7          	jalr	666(ra) # 80000cd0 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	addi	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	addi	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	7ca50513          	addi	a0,a0,1994 # 80011280 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	0ce080e7          	jalr	206(ra) # 80000b8c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00035517          	auipc	a0,0x35
    80000ace:	53650513          	addi	a0,a0,1334 # 80036000 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	addi	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	addi	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	79448493          	addi	s1,s1,1940 # 80011280 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	126080e7          	jalr	294(ra) # 80000c1c <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	77c50513          	addi	a0,a0,1916 # 80011280 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	1c2080e7          	jalr	450(ra) # 80000cd0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1fc080e7          	jalr	508(ra) # 80000d18 <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	addi	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	75050513          	addi	a0,a0,1872 # 80011280 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	198080e7          	jalr	408(ra) # 80000cd0 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <freepmem>:

// HW 4 - Task 1
// Function for returning total free memory 
uint64 freepmem(void){
    80000b42:	1101                	addi	sp,sp,-32
    80000b44:	ec06                	sd	ra,24(sp)
    80000b46:	e822                	sd	s0,16(sp)
    80000b48:	e426                	sd	s1,8(sp)
    80000b4a:	1000                	addi	s0,sp,32
  
  int numOfPages = 0;
  struct run *ptr;

  // Acquire a lock to ensure exclusive access to kernel memory management
  acquire(&kmem.lock);
    80000b4c:	00010497          	auipc	s1,0x10
    80000b50:	73448493          	addi	s1,s1,1844 # 80011280 <kmem>
    80000b54:	8526                	mv	a0,s1
    80000b56:	00000097          	auipc	ra,0x0
    80000b5a:	0c6080e7          	jalr	198(ra) # 80000c1c <acquire>
  
  // Initialize a pointer 'r' to the head of the free memory list
  ptr = kmem.freelist;
    80000b5e:	6c9c                	ld	a5,24(s1)

  // Traverse the free memory list and count the number of pages
  while(ptr){
    80000b60:	c785                	beqz	a5,80000b88 <freepmem+0x46>
  int numOfPages = 0;
    80000b62:	4481                	li	s1,0
    numOfPages++;
    80000b64:	2485                	addiw	s1,s1,1
    ptr = ptr->next;
    80000b66:	639c                	ld	a5,0(a5)
  while(ptr){
    80000b68:	fff5                	bnez	a5,80000b64 <freepmem+0x22>
  }
  
  // Release the lock to allow other threads to access the memory management
  release(&kmem.lock);
    80000b6a:	00010517          	auipc	a0,0x10
    80000b6e:	71650513          	addi	a0,a0,1814 # 80011280 <kmem>
    80000b72:	00000097          	auipc	ra,0x0
    80000b76:	15e080e7          	jalr	350(ra) # 80000cd0 <release>
  // times the total number of pages availble
  int totalFreeMem = numOfPages * PGSIZE;

  // Return the total amount of free memory in bytes
  return totalFreeMem;
}
    80000b7a:	00c4951b          	slliw	a0,s1,0xc
    80000b7e:	60e2                	ld	ra,24(sp)
    80000b80:	6442                	ld	s0,16(sp)
    80000b82:	64a2                	ld	s1,8(sp)
    80000b84:	6105                	addi	sp,sp,32
    80000b86:	8082                	ret
  int numOfPages = 0;
    80000b88:	4481                	li	s1,0
    80000b8a:	b7c5                	j	80000b6a <freepmem+0x28>

0000000080000b8c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b8c:	1141                	addi	sp,sp,-16
    80000b8e:	e422                	sd	s0,8(sp)
    80000b90:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b92:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b94:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b98:	00053823          	sd	zero,16(a0)
}
    80000b9c:	6422                	ld	s0,8(sp)
    80000b9e:	0141                	addi	sp,sp,16
    80000ba0:	8082                	ret

0000000080000ba2 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba2:	411c                	lw	a5,0(a0)
    80000ba4:	e399                	bnez	a5,80000baa <holding+0x8>
    80000ba6:	4501                	li	a0,0
  return r;
}
    80000ba8:	8082                	ret
{
    80000baa:	1101                	addi	sp,sp,-32
    80000bac:	ec06                	sd	ra,24(sp)
    80000bae:	e822                	sd	s0,16(sp)
    80000bb0:	e426                	sd	s1,8(sp)
    80000bb2:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb4:	6904                	ld	s1,16(a0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	e64080e7          	jalr	-412(ra) # 80001a1a <mycpu>
    80000bbe:	40a48533          	sub	a0,s1,a0
    80000bc2:	00153513          	seqz	a0,a0
}
    80000bc6:	60e2                	ld	ra,24(sp)
    80000bc8:	6442                	ld	s0,16(sp)
    80000bca:	64a2                	ld	s1,8(sp)
    80000bcc:	6105                	addi	sp,sp,32
    80000bce:	8082                	ret

0000000080000bd0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bda:	100024f3          	csrr	s1,sstatus
    80000bde:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	e32080e7          	jalr	-462(ra) # 80001a1a <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	cf89                	beqz	a5,80000c0c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e26080e7          	jalr	-474(ra) # 80001a1a <mycpu>
    80000bfc:	5d3c                	lw	a5,120(a0)
    80000bfe:	2785                	addiw	a5,a5,1
    80000c00:	dd3c                	sw	a5,120(a0)
}
    80000c02:	60e2                	ld	ra,24(sp)
    80000c04:	6442                	ld	s0,16(sp)
    80000c06:	64a2                	ld	s1,8(sp)
    80000c08:	6105                	addi	sp,sp,32
    80000c0a:	8082                	ret
    mycpu()->intena = old;
    80000c0c:	00001097          	auipc	ra,0x1
    80000c10:	e0e080e7          	jalr	-498(ra) # 80001a1a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c14:	8085                	srli	s1,s1,0x1
    80000c16:	8885                	andi	s1,s1,1
    80000c18:	dd64                	sw	s1,124(a0)
    80000c1a:	bfe9                	j	80000bf4 <push_off+0x24>

0000000080000c1c <acquire>:
{
    80000c1c:	1101                	addi	sp,sp,-32
    80000c1e:	ec06                	sd	ra,24(sp)
    80000c20:	e822                	sd	s0,16(sp)
    80000c22:	e426                	sd	s1,8(sp)
    80000c24:	1000                	addi	s0,sp,32
    80000c26:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c28:	00000097          	auipc	ra,0x0
    80000c2c:	fa8080e7          	jalr	-88(ra) # 80000bd0 <push_off>
  if(holding(lk))
    80000c30:	8526                	mv	a0,s1
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	f70080e7          	jalr	-144(ra) # 80000ba2 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3a:	4705                	li	a4,1
  if(holding(lk))
    80000c3c:	e115                	bnez	a0,80000c60 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3e:	87ba                	mv	a5,a4
    80000c40:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c44:	2781                	sext.w	a5,a5
    80000c46:	ffe5                	bnez	a5,80000c3e <acquire+0x22>
  __sync_synchronize();
    80000c48:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c4c:	00001097          	auipc	ra,0x1
    80000c50:	dce080e7          	jalr	-562(ra) # 80001a1a <mycpu>
    80000c54:	e888                	sd	a0,16(s1)
}
    80000c56:	60e2                	ld	ra,24(sp)
    80000c58:	6442                	ld	s0,16(sp)
    80000c5a:	64a2                	ld	s1,8(sp)
    80000c5c:	6105                	addi	sp,sp,32
    80000c5e:	8082                	ret
    panic("acquire");
    80000c60:	00007517          	auipc	a0,0x7
    80000c64:	41050513          	addi	a0,a0,1040 # 80008070 <digits+0x30>
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	8d4080e7          	jalr	-1836(ra) # 8000053c <panic>

0000000080000c70 <pop_off>:

void
pop_off(void)
{
    80000c70:	1141                	addi	sp,sp,-16
    80000c72:	e406                	sd	ra,8(sp)
    80000c74:	e022                	sd	s0,0(sp)
    80000c76:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	da2080e7          	jalr	-606(ra) # 80001a1a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c80:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c84:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c86:	e78d                	bnez	a5,80000cb0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c88:	5d3c                	lw	a5,120(a0)
    80000c8a:	02f05b63          	blez	a5,80000cc0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c8e:	37fd                	addiw	a5,a5,-1
    80000c90:	0007871b          	sext.w	a4,a5
    80000c94:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c96:	eb09                	bnez	a4,80000ca8 <pop_off+0x38>
    80000c98:	5d7c                	lw	a5,124(a0)
    80000c9a:	c799                	beqz	a5,80000ca8 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ca8:	60a2                	ld	ra,8(sp)
    80000caa:	6402                	ld	s0,0(sp)
    80000cac:	0141                	addi	sp,sp,16
    80000cae:	8082                	ret
    panic("pop_off - interruptible");
    80000cb0:	00007517          	auipc	a0,0x7
    80000cb4:	3c850513          	addi	a0,a0,968 # 80008078 <digits+0x38>
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	884080e7          	jalr	-1916(ra) # 8000053c <panic>
    panic("pop_off");
    80000cc0:	00007517          	auipc	a0,0x7
    80000cc4:	3d050513          	addi	a0,a0,976 # 80008090 <digits+0x50>
    80000cc8:	00000097          	auipc	ra,0x0
    80000ccc:	874080e7          	jalr	-1932(ra) # 8000053c <panic>

0000000080000cd0 <release>:
{
    80000cd0:	1101                	addi	sp,sp,-32
    80000cd2:	ec06                	sd	ra,24(sp)
    80000cd4:	e822                	sd	s0,16(sp)
    80000cd6:	e426                	sd	s1,8(sp)
    80000cd8:	1000                	addi	s0,sp,32
    80000cda:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cdc:	00000097          	auipc	ra,0x0
    80000ce0:	ec6080e7          	jalr	-314(ra) # 80000ba2 <holding>
    80000ce4:	c115                	beqz	a0,80000d08 <release+0x38>
  lk->cpu = 0;
    80000ce6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cea:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cee:	0f50000f          	fence	iorw,ow
    80000cf2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	f7a080e7          	jalr	-134(ra) # 80000c70 <pop_off>
}
    80000cfe:	60e2                	ld	ra,24(sp)
    80000d00:	6442                	ld	s0,16(sp)
    80000d02:	64a2                	ld	s1,8(sp)
    80000d04:	6105                	addi	sp,sp,32
    80000d06:	8082                	ret
    panic("release");
    80000d08:	00007517          	auipc	a0,0x7
    80000d0c:	39050513          	addi	a0,a0,912 # 80008098 <digits+0x58>
    80000d10:	00000097          	auipc	ra,0x0
    80000d14:	82c080e7          	jalr	-2004(ra) # 8000053c <panic>

0000000080000d18 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d18:	1141                	addi	sp,sp,-16
    80000d1a:	e422                	sd	s0,8(sp)
    80000d1c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d1e:	ca19                	beqz	a2,80000d34 <memset+0x1c>
    80000d20:	87aa                	mv	a5,a0
    80000d22:	1602                	slli	a2,a2,0x20
    80000d24:	9201                	srli	a2,a2,0x20
    80000d26:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d2a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d2e:	0785                	addi	a5,a5,1
    80000d30:	fee79de3          	bne	a5,a4,80000d2a <memset+0x12>
  }
  return dst;
}
    80000d34:	6422                	ld	s0,8(sp)
    80000d36:	0141                	addi	sp,sp,16
    80000d38:	8082                	ret

0000000080000d3a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d3a:	1141                	addi	sp,sp,-16
    80000d3c:	e422                	sd	s0,8(sp)
    80000d3e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d40:	ca05                	beqz	a2,80000d70 <memcmp+0x36>
    80000d42:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d46:	1682                	slli	a3,a3,0x20
    80000d48:	9281                	srli	a3,a3,0x20
    80000d4a:	0685                	addi	a3,a3,1
    80000d4c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d4e:	00054783          	lbu	a5,0(a0)
    80000d52:	0005c703          	lbu	a4,0(a1)
    80000d56:	00e79863          	bne	a5,a4,80000d66 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d5a:	0505                	addi	a0,a0,1
    80000d5c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d5e:	fed518e3          	bne	a0,a3,80000d4e <memcmp+0x14>
  }

  return 0;
    80000d62:	4501                	li	a0,0
    80000d64:	a019                	j	80000d6a <memcmp+0x30>
      return *s1 - *s2;
    80000d66:	40e7853b          	subw	a0,a5,a4
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
  return 0;
    80000d70:	4501                	li	a0,0
    80000d72:	bfe5                	j	80000d6a <memcmp+0x30>

0000000080000d74 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d74:	1141                	addi	sp,sp,-16
    80000d76:	e422                	sd	s0,8(sp)
    80000d78:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d7a:	c205                	beqz	a2,80000d9a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d7c:	02a5e263          	bltu	a1,a0,80000da0 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d80:	1602                	slli	a2,a2,0x20
    80000d82:	9201                	srli	a2,a2,0x20
    80000d84:	00c587b3          	add	a5,a1,a2
{
    80000d88:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d8a:	0585                	addi	a1,a1,1
    80000d8c:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffc9001>
    80000d8e:	fff5c683          	lbu	a3,-1(a1)
    80000d92:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d96:	fef59ae3          	bne	a1,a5,80000d8a <memmove+0x16>

  return dst;
}
    80000d9a:	6422                	ld	s0,8(sp)
    80000d9c:	0141                	addi	sp,sp,16
    80000d9e:	8082                	ret
  if(s < d && s + n > d){
    80000da0:	02061693          	slli	a3,a2,0x20
    80000da4:	9281                	srli	a3,a3,0x20
    80000da6:	00d58733          	add	a4,a1,a3
    80000daa:	fce57be3          	bgeu	a0,a4,80000d80 <memmove+0xc>
    d += n;
    80000dae:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000db0:	fff6079b          	addiw	a5,a2,-1
    80000db4:	1782                	slli	a5,a5,0x20
    80000db6:	9381                	srli	a5,a5,0x20
    80000db8:	fff7c793          	not	a5,a5
    80000dbc:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dbe:	177d                	addi	a4,a4,-1
    80000dc0:	16fd                	addi	a3,a3,-1
    80000dc2:	00074603          	lbu	a2,0(a4)
    80000dc6:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dca:	fee79ae3          	bne	a5,a4,80000dbe <memmove+0x4a>
    80000dce:	b7f1                	j	80000d9a <memmove+0x26>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f9c080e7          	jalr	-100(ra) # 80000d74 <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	86ba                	mv	a3,a4
    80000e44:	00c05c63          	blez	a2,80000e5c <strncpy+0x38>
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	40d707bb          	subw	a5,a4,a3
    80000e52:	37fd                	addiw	a5,a5,-1
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	b44080e7          	jalr	-1212(ra) # 80001a0a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	14a70713          	addi	a4,a4,330 # 80009018 <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	b28080e7          	jalr	-1240(ra) # 80001a0a <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	692080e7          	jalr	1682(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	a78080e7          	jalr	-1416(ra) # 8000297c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	3d4080e7          	jalr	980(ra) # 800062e0 <plicinithart>
  }

  scheduler();  
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	084080e7          	jalr	132(ra) # 80001f98 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	530080e7          	jalr	1328(ra) # 8000044c <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	842080e7          	jalr	-1982(ra) # 80000766 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	652080e7          	jalr	1618(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	642080e7          	jalr	1602(ra) # 80000586 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	632080e7          	jalr	1586(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b4a080e7          	jalr	-1206(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	322080e7          	jalr	802(ra) # 80001286 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	9e2080e7          	jalr	-1566(ra) # 80001956 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	9d8080e7          	jalr	-1576(ra) # 80002954 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	9f8080e7          	jalr	-1544(ra) # 8000297c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	33e080e7          	jalr	830(ra) # 800062ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	34c080e7          	jalr	844(ra) # 800062e0 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	246080e7          	jalr	582(ra) # 800031e2 <binit>
    iinit();         // inode table
    80000fa4:	00003097          	auipc	ra,0x3
    80000fa8:	8d4080e7          	jalr	-1836(ra) # 80003878 <iinit>
    fileinit();      // file table
    80000fac:	00004097          	auipc	ra,0x4
    80000fb0:	88a080e7          	jalr	-1910(ra) # 80004836 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	44c080e7          	jalr	1100(ra) # 80006400 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	d74080e7          	jalr	-652(ra) # 80001d30 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72723          	sw	a5,78(a4) # 80009018 <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0467b783          	ld	a5,70(a5) # 80009020 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	516080e7          	jalr	1302(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	ab0080e7          	jalr	-1360(ra) # 80000ae2 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cd6080e7          	jalr	-810(ra) # 80000d18 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffc8ff7>
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109e:	57fd                	li	a5,-1
    800010a0:	83e9                	srli	a5,a5,0x1a
    800010a2:	00b7f463          	bgeu	a5,a1,800010aa <walkaddr+0xc>
    return 0;
    800010a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b2:	4601                	li	a2,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f44080e7          	jalr	-188(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010bc:	c105                	beqz	a0,800010dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c0:	0117f693          	andi	a3,a5,17
    800010c4:	4745                	li	a4,17
    return 0;
    800010c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c8:	00e68663          	beq	a3,a4,800010d4 <walkaddr+0x36>
}
    800010cc:	60a2                	ld	ra,8(sp)
    800010ce:	6402                	ld	s0,0(sp)
    800010d0:	0141                	addi	sp,sp,16
    800010d2:	8082                	ret
  pa = PTE2PA(*pte);
    800010d4:	83a9                	srli	a5,a5,0xa
    800010d6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010da:	bfcd                	j	800010cc <walkaddr+0x2e>
    return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7fd                	j	800010cc <walkaddr+0x2e>

00000000800010e0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e0:	715d                	addi	sp,sp,-80
    800010e2:	e486                	sd	ra,72(sp)
    800010e4:	e0a2                	sd	s0,64(sp)
    800010e6:	fc26                	sd	s1,56(sp)
    800010e8:	f84a                	sd	s2,48(sp)
    800010ea:	f44e                	sd	s3,40(sp)
    800010ec:	f052                	sd	s4,32(sp)
    800010ee:	ec56                	sd	s5,24(sp)
    800010f0:	e85a                	sd	s6,16(sp)
    800010f2:	e45e                	sd	s7,8(sp)
    800010f4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010f6:	c639                	beqz	a2,80001144 <mappages+0x64>
    800010f8:	8aaa                	mv	s5,a0
    800010fa:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010fc:	777d                	lui	a4,0xfffff
    800010fe:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001102:	fff58993          	addi	s3,a1,-1
    80001106:	99b2                	add	s3,s3,a2
    80001108:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000110c:	893e                	mv	s2,a5
    8000110e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001112:	6b85                	lui	s7,0x1
    80001114:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001118:	4605                	li	a2,1
    8000111a:	85ca                	mv	a1,s2
    8000111c:	8556                	mv	a0,s5
    8000111e:	00000097          	auipc	ra,0x0
    80001122:	eda080e7          	jalr	-294(ra) # 80000ff8 <walk>
    80001126:	cd1d                	beqz	a0,80001164 <mappages+0x84>
    if(*pte & PTE_V)
    80001128:	611c                	ld	a5,0(a0)
    8000112a:	8b85                	andi	a5,a5,1
    8000112c:	e785                	bnez	a5,80001154 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112e:	80b1                	srli	s1,s1,0xc
    80001130:	04aa                	slli	s1,s1,0xa
    80001132:	0164e4b3          	or	s1,s1,s6
    80001136:	0014e493          	ori	s1,s1,1
    8000113a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113c:	05390063          	beq	s2,s3,8000117c <mappages+0x9c>
    a += PGSIZE;
    80001140:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001142:	bfc9                	j	80001114 <mappages+0x34>
    panic("mappages: size");
    80001144:	00007517          	auipc	a0,0x7
    80001148:	f9450513          	addi	a0,a0,-108 # 800080d8 <digits+0x98>
    8000114c:	fffff097          	auipc	ra,0xfffff
    80001150:	3f0080e7          	jalr	1008(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f9450513          	addi	a0,a0,-108 # 800080e8 <digits+0xa8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3e0080e7          	jalr	992(ra) # 8000053c <panic>
      return -1;
    80001164:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001166:	60a6                	ld	ra,72(sp)
    80001168:	6406                	ld	s0,64(sp)
    8000116a:	74e2                	ld	s1,56(sp)
    8000116c:	7942                	ld	s2,48(sp)
    8000116e:	79a2                	ld	s3,40(sp)
    80001170:	7a02                	ld	s4,32(sp)
    80001172:	6ae2                	ld	s5,24(sp)
    80001174:	6b42                	ld	s6,16(sp)
    80001176:	6ba2                	ld	s7,8(sp)
    80001178:	6161                	addi	sp,sp,80
    8000117a:	8082                	ret
  return 0;
    8000117c:	4501                	li	a0,0
    8000117e:	b7e5                	j	80001166 <mappages+0x86>

0000000080001180 <kvmmap>:
{
    80001180:	1141                	addi	sp,sp,-16
    80001182:	e406                	sd	ra,8(sp)
    80001184:	e022                	sd	s0,0(sp)
    80001186:	0800                	addi	s0,sp,16
    80001188:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000118a:	86b2                	mv	a3,a2
    8000118c:	863e                	mv	a2,a5
    8000118e:	00000097          	auipc	ra,0x0
    80001192:	f52080e7          	jalr	-174(ra) # 800010e0 <mappages>
    80001196:	e509                	bnez	a0,800011a0 <kvmmap+0x20>
}
    80001198:	60a2                	ld	ra,8(sp)
    8000119a:	6402                	ld	s0,0(sp)
    8000119c:	0141                	addi	sp,sp,16
    8000119e:	8082                	ret
    panic("kvmmap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f5850513          	addi	a0,a0,-168 # 800080f8 <digits+0xb8>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	394080e7          	jalr	916(ra) # 8000053c <panic>

00000000800011b0 <kvmmake>:
{
    800011b0:	1101                	addi	sp,sp,-32
    800011b2:	ec06                	sd	ra,24(sp)
    800011b4:	e822                	sd	s0,16(sp)
    800011b6:	e426                	sd	s1,8(sp)
    800011b8:	e04a                	sd	s2,0(sp)
    800011ba:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011bc:	00000097          	auipc	ra,0x0
    800011c0:	926080e7          	jalr	-1754(ra) # 80000ae2 <kalloc>
    800011c4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011c6:	6605                	lui	a2,0x1
    800011c8:	4581                	li	a1,0
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	b4e080e7          	jalr	-1202(ra) # 80000d18 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011d2:	4719                	li	a4,6
    800011d4:	6685                	lui	a3,0x1
    800011d6:	10000637          	lui	a2,0x10000
    800011da:	100005b7          	lui	a1,0x10000
    800011de:	8526                	mv	a0,s1
    800011e0:	00000097          	auipc	ra,0x0
    800011e4:	fa0080e7          	jalr	-96(ra) # 80001180 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011e8:	4719                	li	a4,6
    800011ea:	6685                	lui	a3,0x1
    800011ec:	10001637          	lui	a2,0x10001
    800011f0:	100015b7          	lui	a1,0x10001
    800011f4:	8526                	mv	a0,s1
    800011f6:	00000097          	auipc	ra,0x0
    800011fa:	f8a080e7          	jalr	-118(ra) # 80001180 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011fe:	4719                	li	a4,6
    80001200:	004006b7          	lui	a3,0x400
    80001204:	0c000637          	lui	a2,0xc000
    80001208:	0c0005b7          	lui	a1,0xc000
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f72080e7          	jalr	-142(ra) # 80001180 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001216:	00007917          	auipc	s2,0x7
    8000121a:	dea90913          	addi	s2,s2,-534 # 80008000 <etext>
    8000121e:	4729                	li	a4,10
    80001220:	80007697          	auipc	a3,0x80007
    80001224:	de068693          	addi	a3,a3,-544 # 8000 <_entry-0x7fff8000>
    80001228:	4605                	li	a2,1
    8000122a:	067e                	slli	a2,a2,0x1f
    8000122c:	85b2                	mv	a1,a2
    8000122e:	8526                	mv	a0,s1
    80001230:	00000097          	auipc	ra,0x0
    80001234:	f50080e7          	jalr	-176(ra) # 80001180 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001238:	4719                	li	a4,6
    8000123a:	46c5                	li	a3,17
    8000123c:	06ee                	slli	a3,a3,0x1b
    8000123e:	412686b3          	sub	a3,a3,s2
    80001242:	864a                	mv	a2,s2
    80001244:	85ca                	mv	a1,s2
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f38080e7          	jalr	-200(ra) # 80001180 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001250:	4729                	li	a4,10
    80001252:	6685                	lui	a3,0x1
    80001254:	00006617          	auipc	a2,0x6
    80001258:	dac60613          	addi	a2,a2,-596 # 80007000 <_trampoline>
    8000125c:	040005b7          	lui	a1,0x4000
    80001260:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001262:	05b2                	slli	a1,a1,0xc
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f1a080e7          	jalr	-230(ra) # 80001180 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000126e:	8526                	mv	a0,s1
    80001270:	00000097          	auipc	ra,0x0
    80001274:	650080e7          	jalr	1616(ra) # 800018c0 <proc_mapstacks>
}
    80001278:	8526                	mv	a0,s1
    8000127a:	60e2                	ld	ra,24(sp)
    8000127c:	6442                	ld	s0,16(sp)
    8000127e:	64a2                	ld	s1,8(sp)
    80001280:	6902                	ld	s2,0(sp)
    80001282:	6105                	addi	sp,sp,32
    80001284:	8082                	ret

0000000080001286 <kvminit>:
{
    80001286:	1141                	addi	sp,sp,-16
    80001288:	e406                	sd	ra,8(sp)
    8000128a:	e022                	sd	s0,0(sp)
    8000128c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f22080e7          	jalr	-222(ra) # 800011b0 <kvmmake>
    80001296:	00008797          	auipc	a5,0x8
    8000129a:	d8a7b523          	sd	a0,-630(a5) # 80009020 <kernel_pagetable>
}
    8000129e:	60a2                	ld	ra,8(sp)
    800012a0:	6402                	ld	s0,0(sp)
    800012a2:	0141                	addi	sp,sp,16
    800012a4:	8082                	ret

00000000800012a6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012a6:	715d                	addi	sp,sp,-80
    800012a8:	e486                	sd	ra,72(sp)
    800012aa:	e0a2                	sd	s0,64(sp)
    800012ac:	fc26                	sd	s1,56(sp)
    800012ae:	f84a                	sd	s2,48(sp)
    800012b0:	f44e                	sd	s3,40(sp)
    800012b2:	f052                	sd	s4,32(sp)
    800012b4:	ec56                	sd	s5,24(sp)
    800012b6:	e85a                	sd	s6,16(sp)
    800012b8:	e45e                	sd	s7,8(sp)
    800012ba:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012bc:	03459793          	slli	a5,a1,0x34
    800012c0:	e795                	bnez	a5,800012ec <uvmunmap+0x46>
    800012c2:	8a2a                	mv	s4,a0
    800012c4:	892e                	mv	s2,a1
    800012c6:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c8:	0632                	slli	a2,a2,0xc
    800012ca:	00b609b3          	add	s3,a2,a1
      // panic("uvmunmap: walk");
      continue;
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped"); -- HW 4 - TASK 4
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ce:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	6a85                	lui	s5,0x1
    800012d2:	0535e263          	bltu	a1,s3,80001316 <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012d6:	60a6                	ld	ra,72(sp)
    800012d8:	6406                	ld	s0,64(sp)
    800012da:	74e2                	ld	s1,56(sp)
    800012dc:	7942                	ld	s2,48(sp)
    800012de:	79a2                	ld	s3,40(sp)
    800012e0:	7a02                	ld	s4,32(sp)
    800012e2:	6ae2                	ld	s5,24(sp)
    800012e4:	6b42                	ld	s6,16(sp)
    800012e6:	6ba2                	ld	s7,8(sp)
    800012e8:	6161                	addi	sp,sp,80
    800012ea:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e1450513          	addi	a0,a0,-492 # 80008100 <digits+0xc0>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	248080e7          	jalr	584(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e1c50513          	addi	a0,a0,-484 # 80008118 <digits+0xd8>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	238080e7          	jalr	568(ra) # 8000053c <panic>
    *pte = 0;
    8000130c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001310:	9956                	add	s2,s2,s5
    80001312:	fd3972e3          	bgeu	s2,s3,800012d6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001316:	4601                	li	a2,0
    80001318:	85ca                	mv	a1,s2
    8000131a:	8552                	mv	a0,s4
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	cdc080e7          	jalr	-804(ra) # 80000ff8 <walk>
    80001324:	84aa                	mv	s1,a0
    80001326:	d56d                	beqz	a0,80001310 <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    80001328:	611c                	ld	a5,0(a0)
    8000132a:	0017f713          	andi	a4,a5,1
    8000132e:	d36d                	beqz	a4,80001310 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001330:	3ff7f713          	andi	a4,a5,1023
    80001334:	fd7704e3          	beq	a4,s7,800012fc <uvmunmap+0x56>
    if(do_free){
    80001338:	fc0b0ae3          	beqz	s6,8000130c <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    8000133c:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000133e:	00c79513          	slli	a0,a5,0xc
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	6a2080e7          	jalr	1698(ra) # 800009e4 <kfree>
    8000134a:	b7c9                	j	8000130c <uvmunmap+0x66>

000000008000134c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134c:	1101                	addi	sp,sp,-32
    8000134e:	ec06                	sd	ra,24(sp)
    80001350:	e822                	sd	s0,16(sp)
    80001352:	e426                	sd	s1,8(sp)
    80001354:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	78c080e7          	jalr	1932(ra) # 80000ae2 <kalloc>
    8000135e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001360:	c519                	beqz	a0,8000136e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001362:	6605                	lui	a2,0x1
    80001364:	4581                	li	a1,0
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	9b2080e7          	jalr	-1614(ra) # 80000d18 <memset>
  return pagetable;
}
    8000136e:	8526                	mv	a0,s1
    80001370:	60e2                	ld	ra,24(sp)
    80001372:	6442                	ld	s0,16(sp)
    80001374:	64a2                	ld	s1,8(sp)
    80001376:	6105                	addi	sp,sp,32
    80001378:	8082                	ret

000000008000137a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000137a:	7179                	addi	sp,sp,-48
    8000137c:	f406                	sd	ra,40(sp)
    8000137e:	f022                	sd	s0,32(sp)
    80001380:	ec26                	sd	s1,24(sp)
    80001382:	e84a                	sd	s2,16(sp)
    80001384:	e44e                	sd	s3,8(sp)
    80001386:	e052                	sd	s4,0(sp)
    80001388:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000138a:	6785                	lui	a5,0x1
    8000138c:	04f67863          	bgeu	a2,a5,800013dc <uvminit+0x62>
    80001390:	8a2a                	mv	s4,a0
    80001392:	89ae                	mv	s3,a1
    80001394:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	74c080e7          	jalr	1868(ra) # 80000ae2 <kalloc>
    8000139e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013a0:	6605                	lui	a2,0x1
    800013a2:	4581                	li	a1,0
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	974080e7          	jalr	-1676(ra) # 80000d18 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ac:	4779                	li	a4,30
    800013ae:	86ca                	mv	a3,s2
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	8552                	mv	a0,s4
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	d2a080e7          	jalr	-726(ra) # 800010e0 <mappages>
  memmove(mem, src, sz);
    800013be:	8626                	mv	a2,s1
    800013c0:	85ce                	mv	a1,s3
    800013c2:	854a                	mv	a0,s2
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	9b0080e7          	jalr	-1616(ra) # 80000d74 <memmove>
}
    800013cc:	70a2                	ld	ra,40(sp)
    800013ce:	7402                	ld	s0,32(sp)
    800013d0:	64e2                	ld	s1,24(sp)
    800013d2:	6942                	ld	s2,16(sp)
    800013d4:	69a2                	ld	s3,8(sp)
    800013d6:	6a02                	ld	s4,0(sp)
    800013d8:	6145                	addi	sp,sp,48
    800013da:	8082                	ret
    panic("inituvm: more than a page");
    800013dc:	00007517          	auipc	a0,0x7
    800013e0:	d5450513          	addi	a0,a0,-684 # 80008130 <digits+0xf0>
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	158080e7          	jalr	344(ra) # 8000053c <panic>

00000000800013ec <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ec:	1101                	addi	sp,sp,-32
    800013ee:	ec06                	sd	ra,24(sp)
    800013f0:	e822                	sd	s0,16(sp)
    800013f2:	e426                	sd	s1,8(sp)
    800013f4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f8:	00b67d63          	bgeu	a2,a1,80001412 <uvmdealloc+0x26>
    800013fc:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fe:	6785                	lui	a5,0x1
    80001400:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001402:	00f60733          	add	a4,a2,a5
    80001406:	76fd                	lui	a3,0xfffff
    80001408:	8f75                	and	a4,a4,a3
    8000140a:	97ae                	add	a5,a5,a1
    8000140c:	8ff5                	and	a5,a5,a3
    8000140e:	00f76863          	bltu	a4,a5,8000141e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001412:	8526                	mv	a0,s1
    80001414:	60e2                	ld	ra,24(sp)
    80001416:	6442                	ld	s0,16(sp)
    80001418:	64a2                	ld	s1,8(sp)
    8000141a:	6105                	addi	sp,sp,32
    8000141c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141e:	8f99                	sub	a5,a5,a4
    80001420:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001422:	4685                	li	a3,1
    80001424:	0007861b          	sext.w	a2,a5
    80001428:	85ba                	mv	a1,a4
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	e7c080e7          	jalr	-388(ra) # 800012a6 <uvmunmap>
    80001432:	b7c5                	j	80001412 <uvmdealloc+0x26>

0000000080001434 <uvmalloc>:
  if(newsz < oldsz)
    80001434:	0ab66163          	bltu	a2,a1,800014d6 <uvmalloc+0xa2>
{
    80001438:	7139                	addi	sp,sp,-64
    8000143a:	fc06                	sd	ra,56(sp)
    8000143c:	f822                	sd	s0,48(sp)
    8000143e:	f426                	sd	s1,40(sp)
    80001440:	f04a                	sd	s2,32(sp)
    80001442:	ec4e                	sd	s3,24(sp)
    80001444:	e852                	sd	s4,16(sp)
    80001446:	e456                	sd	s5,8(sp)
    80001448:	0080                	addi	s0,sp,64
    8000144a:	8aaa                	mv	s5,a0
    8000144c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144e:	6785                	lui	a5,0x1
    80001450:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001452:	95be                	add	a1,a1,a5
    80001454:	77fd                	lui	a5,0xfffff
    80001456:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145a:	08c9f063          	bgeu	s3,a2,800014da <uvmalloc+0xa6>
    8000145e:	894e                	mv	s2,s3
    mem = kalloc();
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	682080e7          	jalr	1666(ra) # 80000ae2 <kalloc>
    80001468:	84aa                	mv	s1,a0
    if(mem == 0){
    8000146a:	c51d                	beqz	a0,80001498 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000146c:	6605                	lui	a2,0x1
    8000146e:	4581                	li	a1,0
    80001470:	00000097          	auipc	ra,0x0
    80001474:	8a8080e7          	jalr	-1880(ra) # 80000d18 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001478:	4779                	li	a4,30
    8000147a:	86a6                	mv	a3,s1
    8000147c:	6605                	lui	a2,0x1
    8000147e:	85ca                	mv	a1,s2
    80001480:	8556                	mv	a0,s5
    80001482:	00000097          	auipc	ra,0x0
    80001486:	c5e080e7          	jalr	-930(ra) # 800010e0 <mappages>
    8000148a:	e905                	bnez	a0,800014ba <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148c:	6785                	lui	a5,0x1
    8000148e:	993e                	add	s2,s2,a5
    80001490:	fd4968e3          	bltu	s2,s4,80001460 <uvmalloc+0x2c>
  return newsz;
    80001494:	8552                	mv	a0,s4
    80001496:	a809                	j	800014a8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001498:	864e                	mv	a2,s3
    8000149a:	85ca                	mv	a1,s2
    8000149c:	8556                	mv	a0,s5
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	f4e080e7          	jalr	-178(ra) # 800013ec <uvmdealloc>
      return 0;
    800014a6:	4501                	li	a0,0
}
    800014a8:	70e2                	ld	ra,56(sp)
    800014aa:	7442                	ld	s0,48(sp)
    800014ac:	74a2                	ld	s1,40(sp)
    800014ae:	7902                	ld	s2,32(sp)
    800014b0:	69e2                	ld	s3,24(sp)
    800014b2:	6a42                	ld	s4,16(sp)
    800014b4:	6aa2                	ld	s5,8(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	528080e7          	jalr	1320(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f22080e7          	jalr	-222(ra) # 800013ec <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfd1                	j	800014a8 <uvmalloc+0x74>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7f1                	j	800014a8 <uvmalloc+0x74>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a829                	j	80001512 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014fc:	00c79513          	slli	a0,a5,0xc
    80001500:	00000097          	auipc	ra,0x0
    80001504:	fde080e7          	jalr	-34(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001508:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150c:	04a1                	addi	s1,s1,8
    8000150e:	03248163          	beq	s1,s2,80001530 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001512:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001514:	00f7f713          	andi	a4,a5,15
    80001518:	ff3701e3          	beq	a4,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151c:	8b85                	andi	a5,a5,1
    8000151e:	d7fd                	beqz	a5,8000150c <freewalk+0x2e>
      panic("freewalk: leaf");
    80001520:	00007517          	auipc	a0,0x7
    80001524:	c3050513          	addi	a0,a0,-976 # 80008150 <digits+0x110>
    80001528:	fffff097          	auipc	ra,0xfffff
    8000152c:	014080e7          	jalr	20(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001530:	8552                	mv	a0,s4
    80001532:	fffff097          	auipc	ra,0xfffff
    80001536:	4b2080e7          	jalr	1202(ra) # 800009e4 <kfree>
}
    8000153a:	70a2                	ld	ra,40(sp)
    8000153c:	7402                	ld	s0,32(sp)
    8000153e:	64e2                	ld	s1,24(sp)
    80001540:	6942                	ld	s2,16(sp)
    80001542:	69a2                	ld	s3,8(sp)
    80001544:	6a02                	ld	s4,0(sp)
    80001546:	6145                	addi	sp,sp,48
    80001548:	8082                	ret

000000008000154a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000154a:	1101                	addi	sp,sp,-32
    8000154c:	ec06                	sd	ra,24(sp)
    8000154e:	e822                	sd	s0,16(sp)
    80001550:	e426                	sd	s1,8(sp)
    80001552:	1000                	addi	s0,sp,32
    80001554:	84aa                	mv	s1,a0
  if(sz > 0)
    80001556:	e999                	bnez	a1,8000156c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001558:	8526                	mv	a0,s1
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	f84080e7          	jalr	-124(ra) # 800014de <freewalk>
}
    80001562:	60e2                	ld	ra,24(sp)
    80001564:	6442                	ld	s0,16(sp)
    80001566:	64a2                	ld	s1,8(sp)
    80001568:	6105                	addi	sp,sp,32
    8000156a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156c:	6785                	lui	a5,0x1
    8000156e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001570:	95be                	add	a1,a1,a5
    80001572:	4685                	li	a3,1
    80001574:	00c5d613          	srli	a2,a1,0xc
    80001578:	4581                	li	a1,0
    8000157a:	00000097          	auipc	ra,0x0
    8000157e:	d2c080e7          	jalr	-724(ra) # 800012a6 <uvmunmap>
    80001582:	bfd9                	j	80001558 <uvmfree+0xe>

0000000080001584 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001584:	c269                	beqz	a2,80001646 <uvmcopy+0xc2>
{
    80001586:	715d                	addi	sp,sp,-80
    80001588:	e486                	sd	ra,72(sp)
    8000158a:	e0a2                	sd	s0,64(sp)
    8000158c:	fc26                	sd	s1,56(sp)
    8000158e:	f84a                	sd	s2,48(sp)
    80001590:	f44e                	sd	s3,40(sp)
    80001592:	f052                	sd	s4,32(sp)
    80001594:	ec56                	sd	s5,24(sp)
    80001596:	e85a                	sd	s6,16(sp)
    80001598:	e45e                	sd	s7,8(sp)
    8000159a:	0880                	addi	s0,sp,80
    8000159c:	8aaa                	mv	s5,a0
    8000159e:	8b2e                	mv	s6,a1
    800015a0:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015a2:	4481                	li	s1,0
    800015a4:	a829                	j	800015be <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015a6:	00007517          	auipc	a0,0x7
    800015aa:	bba50513          	addi	a0,a0,-1094 # 80008160 <digits+0x120>
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	f8e080e7          	jalr	-114(ra) # 8000053c <panic>
  for(i = 0; i < sz; i += PGSIZE){
    800015b6:	6785                	lui	a5,0x1
    800015b8:	94be                	add	s1,s1,a5
    800015ba:	0944f463          	bgeu	s1,s4,80001642 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800015be:	4601                	li	a2,0
    800015c0:	85a6                	mv	a1,s1
    800015c2:	8556                	mv	a0,s5
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	a34080e7          	jalr	-1484(ra) # 80000ff8 <walk>
    800015cc:	dd69                	beqz	a0,800015a6 <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    800015ce:	6118                	ld	a4,0(a0)
    800015d0:	00177793          	andi	a5,a4,1
    800015d4:	d3ed                	beqz	a5,800015b6 <uvmcopy+0x32>
      // panic("uvmcopy: page not present"); -- HW 4 - TASK 4
      continue;
    pa = PTE2PA(*pte);
    800015d6:	00a75593          	srli	a1,a4,0xa
    800015da:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015de:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	500080e7          	jalr	1280(ra) # 80000ae2 <kalloc>
    800015ea:	89aa                	mv	s3,a0
    800015ec:	c515                	beqz	a0,80001618 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ee:	6605                	lui	a2,0x1
    800015f0:	85de                	mv	a1,s7
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	782080e7          	jalr	1922(ra) # 80000d74 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015fa:	874a                	mv	a4,s2
    800015fc:	86ce                	mv	a3,s3
    800015fe:	6605                	lui	a2,0x1
    80001600:	85a6                	mv	a1,s1
    80001602:	855a                	mv	a0,s6
    80001604:	00000097          	auipc	ra,0x0
    80001608:	adc080e7          	jalr	-1316(ra) # 800010e0 <mappages>
    8000160c:	d54d                	beqz	a0,800015b6 <uvmcopy+0x32>
      kfree(mem);
    8000160e:	854e                	mv	a0,s3
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	3d4080e7          	jalr	980(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001618:	4685                	li	a3,1
    8000161a:	00c4d613          	srli	a2,s1,0xc
    8000161e:	4581                	li	a1,0
    80001620:	855a                	mv	a0,s6
    80001622:	00000097          	auipc	ra,0x0
    80001626:	c84080e7          	jalr	-892(ra) # 800012a6 <uvmunmap>
  return -1;
    8000162a:	557d                	li	a0,-1
}
    8000162c:	60a6                	ld	ra,72(sp)
    8000162e:	6406                	ld	s0,64(sp)
    80001630:	74e2                	ld	s1,56(sp)
    80001632:	7942                	ld	s2,48(sp)
    80001634:	79a2                	ld	s3,40(sp)
    80001636:	7a02                	ld	s4,32(sp)
    80001638:	6ae2                	ld	s5,24(sp)
    8000163a:	6b42                	ld	s6,16(sp)
    8000163c:	6ba2                	ld	s7,8(sp)
    8000163e:	6161                	addi	sp,sp,80
    80001640:	8082                	ret
  return 0;
    80001642:	4501                	li	a0,0
    80001644:	b7e5                	j	8000162c <uvmcopy+0xa8>
    80001646:	4501                	li	a0,0
}
    80001648:	8082                	ret

000000008000164a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000164a:	1141                	addi	sp,sp,-16
    8000164c:	e406                	sd	ra,8(sp)
    8000164e:	e022                	sd	s0,0(sp)
    80001650:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001652:	4601                	li	a2,0
    80001654:	00000097          	auipc	ra,0x0
    80001658:	9a4080e7          	jalr	-1628(ra) # 80000ff8 <walk>
  if(pte == 0)
    8000165c:	c901                	beqz	a0,8000166c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165e:	611c                	ld	a5,0(a0)
    80001660:	9bbd                	andi	a5,a5,-17
    80001662:	e11c                	sd	a5,0(a0)
}
    80001664:	60a2                	ld	ra,8(sp)
    80001666:	6402                	ld	s0,0(sp)
    80001668:	0141                	addi	sp,sp,16
    8000166a:	8082                	ret
    panic("uvmclear");
    8000166c:	00007517          	auipc	a0,0x7
    80001670:	b1450513          	addi	a0,a0,-1260 # 80008180 <digits+0x140>
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	ec8080e7          	jalr	-312(ra) # 8000053c <panic>

000000008000167c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167c:	c6bd                	beqz	a3,800016ea <copyout+0x6e>
{
    8000167e:	715d                	addi	sp,sp,-80
    80001680:	e486                	sd	ra,72(sp)
    80001682:	e0a2                	sd	s0,64(sp)
    80001684:	fc26                	sd	s1,56(sp)
    80001686:	f84a                	sd	s2,48(sp)
    80001688:	f44e                	sd	s3,40(sp)
    8000168a:	f052                	sd	s4,32(sp)
    8000168c:	ec56                	sd	s5,24(sp)
    8000168e:	e85a                	sd	s6,16(sp)
    80001690:	e45e                	sd	s7,8(sp)
    80001692:	e062                	sd	s8,0(sp)
    80001694:	0880                	addi	s0,sp,80
    80001696:	8b2a                	mv	s6,a0
    80001698:	8c2e                	mv	s8,a1
    8000169a:	8a32                	mv	s4,a2
    8000169c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a0:	6a85                	lui	s5,0x1
    800016a2:	a015                	j	800016c6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a4:	9562                	add	a0,a0,s8
    800016a6:	0004861b          	sext.w	a2,s1
    800016aa:	85d2                	mv	a1,s4
    800016ac:	41250533          	sub	a0,a0,s2
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	6c4080e7          	jalr	1732(ra) # 80000d74 <memmove>

    len -= n;
    800016b8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016bc:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016be:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c2:	02098263          	beqz	s3,800016e6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ca:	85ca                	mv	a1,s2
    800016cc:	855a                	mv	a0,s6
    800016ce:	00000097          	auipc	ra,0x0
    800016d2:	9d0080e7          	jalr	-1584(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800016d6:	cd01                	beqz	a0,800016ee <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d8:	418904b3          	sub	s1,s2,s8
    800016dc:	94d6                	add	s1,s1,s5
    800016de:	fc99f3e3          	bgeu	s3,s1,800016a4 <copyout+0x28>
    800016e2:	84ce                	mv	s1,s3
    800016e4:	b7c1                	j	800016a4 <copyout+0x28>
  }
  return 0;
    800016e6:	4501                	li	a0,0
    800016e8:	a021                	j	800016f0 <copyout+0x74>
    800016ea:	4501                	li	a0,0
}
    800016ec:	8082                	ret
      return -1;
    800016ee:	557d                	li	a0,-1
}
    800016f0:	60a6                	ld	ra,72(sp)
    800016f2:	6406                	ld	s0,64(sp)
    800016f4:	74e2                	ld	s1,56(sp)
    800016f6:	7942                	ld	s2,48(sp)
    800016f8:	79a2                	ld	s3,40(sp)
    800016fa:	7a02                	ld	s4,32(sp)
    800016fc:	6ae2                	ld	s5,24(sp)
    800016fe:	6b42                	ld	s6,16(sp)
    80001700:	6ba2                	ld	s7,8(sp)
    80001702:	6c02                	ld	s8,0(sp)
    80001704:	6161                	addi	sp,sp,80
    80001706:	8082                	ret

0000000080001708 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001708:	caa5                	beqz	a3,80001778 <copyin+0x70>
{
    8000170a:	715d                	addi	sp,sp,-80
    8000170c:	e486                	sd	ra,72(sp)
    8000170e:	e0a2                	sd	s0,64(sp)
    80001710:	fc26                	sd	s1,56(sp)
    80001712:	f84a                	sd	s2,48(sp)
    80001714:	f44e                	sd	s3,40(sp)
    80001716:	f052                	sd	s4,32(sp)
    80001718:	ec56                	sd	s5,24(sp)
    8000171a:	e85a                	sd	s6,16(sp)
    8000171c:	e45e                	sd	s7,8(sp)
    8000171e:	e062                	sd	s8,0(sp)
    80001720:	0880                	addi	s0,sp,80
    80001722:	8b2a                	mv	s6,a0
    80001724:	8a2e                	mv	s4,a1
    80001726:	8c32                	mv	s8,a2
    80001728:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000172a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172c:	6a85                	lui	s5,0x1
    8000172e:	a01d                	j	80001754 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001730:	018505b3          	add	a1,a0,s8
    80001734:	0004861b          	sext.w	a2,s1
    80001738:	412585b3          	sub	a1,a1,s2
    8000173c:	8552                	mv	a0,s4
    8000173e:	fffff097          	auipc	ra,0xfffff
    80001742:	636080e7          	jalr	1590(ra) # 80000d74 <memmove>

    len -= n;
    80001746:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000174a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000174c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001750:	02098263          	beqz	s3,80001774 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001754:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001758:	85ca                	mv	a1,s2
    8000175a:	855a                	mv	a0,s6
    8000175c:	00000097          	auipc	ra,0x0
    80001760:	942080e7          	jalr	-1726(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    80001764:	cd01                	beqz	a0,8000177c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001766:	418904b3          	sub	s1,s2,s8
    8000176a:	94d6                	add	s1,s1,s5
    8000176c:	fc99f2e3          	bgeu	s3,s1,80001730 <copyin+0x28>
    80001770:	84ce                	mv	s1,s3
    80001772:	bf7d                	j	80001730 <copyin+0x28>
  }
  return 0;
    80001774:	4501                	li	a0,0
    80001776:	a021                	j	8000177e <copyin+0x76>
    80001778:	4501                	li	a0,0
}
    8000177a:	8082                	ret
      return -1;
    8000177c:	557d                	li	a0,-1
}
    8000177e:	60a6                	ld	ra,72(sp)
    80001780:	6406                	ld	s0,64(sp)
    80001782:	74e2                	ld	s1,56(sp)
    80001784:	7942                	ld	s2,48(sp)
    80001786:	79a2                	ld	s3,40(sp)
    80001788:	7a02                	ld	s4,32(sp)
    8000178a:	6ae2                	ld	s5,24(sp)
    8000178c:	6b42                	ld	s6,16(sp)
    8000178e:	6ba2                	ld	s7,8(sp)
    80001790:	6c02                	ld	s8,0(sp)
    80001792:	6161                	addi	sp,sp,80
    80001794:	8082                	ret

0000000080001796 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001796:	c2dd                	beqz	a3,8000183c <copyinstr+0xa6>
{
    80001798:	715d                	addi	sp,sp,-80
    8000179a:	e486                	sd	ra,72(sp)
    8000179c:	e0a2                	sd	s0,64(sp)
    8000179e:	fc26                	sd	s1,56(sp)
    800017a0:	f84a                	sd	s2,48(sp)
    800017a2:	f44e                	sd	s3,40(sp)
    800017a4:	f052                	sd	s4,32(sp)
    800017a6:	ec56                	sd	s5,24(sp)
    800017a8:	e85a                	sd	s6,16(sp)
    800017aa:	e45e                	sd	s7,8(sp)
    800017ac:	0880                	addi	s0,sp,80
    800017ae:	8a2a                	mv	s4,a0
    800017b0:	8b2e                	mv	s6,a1
    800017b2:	8bb2                	mv	s7,a2
    800017b4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b8:	6985                	lui	s3,0x1
    800017ba:	a02d                	j	800017e4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017bc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c2:	37fd                	addiw	a5,a5,-1
    800017c4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c8:	60a6                	ld	ra,72(sp)
    800017ca:	6406                	ld	s0,64(sp)
    800017cc:	74e2                	ld	s1,56(sp)
    800017ce:	7942                	ld	s2,48(sp)
    800017d0:	79a2                	ld	s3,40(sp)
    800017d2:	7a02                	ld	s4,32(sp)
    800017d4:	6ae2                	ld	s5,24(sp)
    800017d6:	6b42                	ld	s6,16(sp)
    800017d8:	6ba2                	ld	s7,8(sp)
    800017da:	6161                	addi	sp,sp,80
    800017dc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017de:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e2:	c8a9                	beqz	s1,80001834 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017e4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e8:	85ca                	mv	a1,s2
    800017ea:	8552                	mv	a0,s4
    800017ec:	00000097          	auipc	ra,0x0
    800017f0:	8b2080e7          	jalr	-1870(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800017f4:	c131                	beqz	a0,80001838 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017f6:	417906b3          	sub	a3,s2,s7
    800017fa:	96ce                	add	a3,a3,s3
    800017fc:	00d4f363          	bgeu	s1,a3,80001802 <copyinstr+0x6c>
    80001800:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001802:	955e                	add	a0,a0,s7
    80001804:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001808:	daf9                	beqz	a3,800017de <copyinstr+0x48>
    8000180a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180c:	41650633          	sub	a2,a0,s6
    80001810:	fff48593          	addi	a1,s1,-1
    80001814:	95da                	add	a1,a1,s6
    while(n > 0){
    80001816:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001818:	00f60733          	add	a4,a2,a5
    8000181c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffc9000>
    80001820:	df51                	beqz	a4,800017bc <copyinstr+0x26>
        *dst = *p;
    80001822:	00e78023          	sb	a4,0(a5)
      --max;
    80001826:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000182a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182c:	fed796e3          	bne	a5,a3,80001818 <copyinstr+0x82>
      dst++;
    80001830:	8b3e                	mv	s6,a5
    80001832:	b775                	j	800017de <copyinstr+0x48>
    80001834:	4781                	li	a5,0
    80001836:	b771                	j	800017c2 <copyinstr+0x2c>
      return -1;
    80001838:	557d                	li	a0,-1
    8000183a:	b779                	j	800017c8 <copyinstr+0x32>
  int got_null = 0;
    8000183c:	4781                	li	a5,0
  if(got_null){
    8000183e:	37fd                	addiw	a5,a5,-1
    80001840:	0007851b          	sext.w	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <mapvpages>:
// HW5 - Task 1a
// Allocate page table pages for PTEs if needed but leave valid bits unchanged
int
mapvpages(pagetable_t pagetable, uint64 va, uint64 size)
{
    80001846:	7179                	addi	sp,sp,-48
    80001848:	f406                	sd	ra,40(sp)
    8000184a:	f022                	sd	s0,32(sp)
    8000184c:	ec26                	sd	s1,24(sp)
    8000184e:	e84a                	sd	s2,16(sp)
    80001850:	e44e                	sd	s3,8(sp)
    80001852:	e052                	sd	s4,0(sp)
    80001854:	1800                	addi	s0,sp,48
  uint64 a, last;
  pte_t *pte;
  if(size == 0)
    80001856:	ca15                	beqz	a2,8000188a <mapvpages+0x44>
    80001858:	89aa                	mv	s3,a0
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    8000185a:	77fd                	lui	a5,0xfffff
    8000185c:	00f5f4b3          	and	s1,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001860:	fff58913          	addi	s2,a1,-1
    80001864:	9932                	add	s2,s2,a2
    80001866:	00f97933          	and	s2,s2,a5
      return -1;
    if(*pte & PTE_V)
      panic("mappages: remap");
    if(a == last)
      break;
    a += PGSIZE;
    8000186a:	6a05                	lui	s4,0x1
    if((pte = walk(pagetable, a, 1)) == 0)
    8000186c:	4605                	li	a2,1
    8000186e:	85a6                	mv	a1,s1
    80001870:	854e                	mv	a0,s3
    80001872:	fffff097          	auipc	ra,0xfffff
    80001876:	786080e7          	jalr	1926(ra) # 80000ff8 <walk>
    8000187a:	c905                	beqz	a0,800018aa <mapvpages+0x64>
    if(*pte & PTE_V)
    8000187c:	611c                	ld	a5,0(a0)
    8000187e:	8b85                	andi	a5,a5,1
    80001880:	ef89                	bnez	a5,8000189a <mapvpages+0x54>
    if(a == last)
    80001882:	03248d63          	beq	s1,s2,800018bc <mapvpages+0x76>
    a += PGSIZE;
    80001886:	94d2                	add	s1,s1,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001888:	b7d5                	j	8000186c <mapvpages+0x26>
    panic("mappages: size");
    8000188a:	00007517          	auipc	a0,0x7
    8000188e:	84e50513          	addi	a0,a0,-1970 # 800080d8 <digits+0x98>
    80001892:	fffff097          	auipc	ra,0xfffff
    80001896:	caa080e7          	jalr	-854(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000189a:	00007517          	auipc	a0,0x7
    8000189e:	84e50513          	addi	a0,a0,-1970 # 800080e8 <digits+0xa8>
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	c9a080e7          	jalr	-870(ra) # 8000053c <panic>
      return -1;
    800018aa:	557d                	li	a0,-1
  }
  return 0;
    800018ac:	70a2                	ld	ra,40(sp)
    800018ae:	7402                	ld	s0,32(sp)
    800018b0:	64e2                	ld	s1,24(sp)
    800018b2:	6942                	ld	s2,16(sp)
    800018b4:	69a2                	ld	s3,8(sp)
    800018b6:	6a02                	ld	s4,0(sp)
    800018b8:	6145                	addi	sp,sp,48
    800018ba:	8082                	ret
  return 0;
    800018bc:	4501                	li	a0,0
    800018be:	b7fd                	j	800018ac <mapvpages+0x66>

00000000800018c0 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018c0:	7139                	addi	sp,sp,-64
    800018c2:	fc06                	sd	ra,56(sp)
    800018c4:	f822                	sd	s0,48(sp)
    800018c6:	f426                	sd	s1,40(sp)
    800018c8:	f04a                	sd	s2,32(sp)
    800018ca:	ec4e                	sd	s3,24(sp)
    800018cc:	e852                	sd	s4,16(sp)
    800018ce:	e456                	sd	s5,8(sp)
    800018d0:	e05a                	sd	s6,0(sp)
    800018d2:	0080                	addi	s0,sp,64
    800018d4:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d6:	00010497          	auipc	s1,0x10
    800018da:	e1248493          	addi	s1,s1,-494 # 800116e8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018de:	8b26                	mv	s6,s1
    800018e0:	00006a97          	auipc	s5,0x6
    800018e4:	720a8a93          	addi	s5,s5,1824 # 80008000 <etext>
    800018e8:	04000937          	lui	s2,0x4000
    800018ec:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018ee:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018f0:	00021a17          	auipc	s4,0x21
    800018f4:	df8a0a13          	addi	s4,s4,-520 # 800226e8 <mmr_list>
    char *pa = kalloc();
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	1ea080e7          	jalr	490(ra) # 80000ae2 <kalloc>
    80001900:	862a                	mv	a2,a0
    if(pa == 0)
    80001902:	c131                	beqz	a0,80001946 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001904:	416485b3          	sub	a1,s1,s6
    80001908:	8599                	srai	a1,a1,0x6
    8000190a:	000ab783          	ld	a5,0(s5)
    8000190e:	02f585b3          	mul	a1,a1,a5
    80001912:	2585                	addiw	a1,a1,1
    80001914:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001918:	4719                	li	a4,6
    8000191a:	6685                	lui	a3,0x1
    8000191c:	40b905b3          	sub	a1,s2,a1
    80001920:	854e                	mv	a0,s3
    80001922:	00000097          	auipc	ra,0x0
    80001926:	85e080e7          	jalr	-1954(ra) # 80001180 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	44048493          	addi	s1,s1,1088
    8000192e:	fd4495e3          	bne	s1,s4,800018f8 <proc_mapstacks+0x38>
  }
}
    80001932:	70e2                	ld	ra,56(sp)
    80001934:	7442                	ld	s0,48(sp)
    80001936:	74a2                	ld	s1,40(sp)
    80001938:	7902                	ld	s2,32(sp)
    8000193a:	69e2                	ld	s3,24(sp)
    8000193c:	6a42                	ld	s4,16(sp)
    8000193e:	6aa2                	ld	s5,8(sp)
    80001940:	6b02                	ld	s6,0(sp)
    80001942:	6121                	addi	sp,sp,64
    80001944:	8082                	ret
      panic("kalloc");
    80001946:	00007517          	auipc	a0,0x7
    8000194a:	84a50513          	addi	a0,a0,-1974 # 80008190 <digits+0x150>
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	bee080e7          	jalr	-1042(ra) # 8000053c <panic>

0000000080001956 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001956:	7139                	addi	sp,sp,-64
    80001958:	fc06                	sd	ra,56(sp)
    8000195a:	f822                	sd	s0,48(sp)
    8000195c:	f426                	sd	s1,40(sp)
    8000195e:	f04a                	sd	s2,32(sp)
    80001960:	ec4e                	sd	s3,24(sp)
    80001962:	e852                	sd	s4,16(sp)
    80001964:	e456                	sd	s5,8(sp)
    80001966:	e05a                	sd	s6,0(sp)
    80001968:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000196a:	00007597          	auipc	a1,0x7
    8000196e:	82e58593          	addi	a1,a1,-2002 # 80008198 <digits+0x158>
    80001972:	00010517          	auipc	a0,0x10
    80001976:	92e50513          	addi	a0,a0,-1746 # 800112a0 <pid_lock>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	212080e7          	jalr	530(ra) # 80000b8c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001982:	00007597          	auipc	a1,0x7
    80001986:	81e58593          	addi	a1,a1,-2018 # 800081a0 <digits+0x160>
    8000198a:	00010517          	auipc	a0,0x10
    8000198e:	92e50513          	addi	a0,a0,-1746 # 800112b8 <wait_lock>
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	1fa080e7          	jalr	506(ra) # 80000b8c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199a:	00010497          	auipc	s1,0x10
    8000199e:	d4e48493          	addi	s1,s1,-690 # 800116e8 <proc>
      initlock(&p->lock, "proc");
    800019a2:	00007b17          	auipc	s6,0x7
    800019a6:	80eb0b13          	addi	s6,s6,-2034 # 800081b0 <digits+0x170>
      p->kstack = KSTACK((int) (p - proc));
    800019aa:	8aa6                	mv	s5,s1
    800019ac:	00006a17          	auipc	s4,0x6
    800019b0:	654a0a13          	addi	s4,s4,1620 # 80008000 <etext>
    800019b4:	04000937          	lui	s2,0x4000
    800019b8:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019ba:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019bc:	00021997          	auipc	s3,0x21
    800019c0:	d2c98993          	addi	s3,s3,-724 # 800226e8 <mmr_list>
      initlock(&p->lock, "proc");
    800019c4:	85da                	mv	a1,s6
    800019c6:	2d848513          	addi	a0,s1,728
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	1c2080e7          	jalr	450(ra) # 80000b8c <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019d2:	415487b3          	sub	a5,s1,s5
    800019d6:	8799                	srai	a5,a5,0x6
    800019d8:	000a3703          	ld	a4,0(s4)
    800019dc:	02e787b3          	mul	a5,a5,a4
    800019e0:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffc9001>
    800019e2:	00d7979b          	slliw	a5,a5,0xd
    800019e6:	40f907b3          	sub	a5,s2,a5
    800019ea:	30f4bc23          	sd	a5,792(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ee:	44048493          	addi	s1,s1,1088
    800019f2:	fd3499e3          	bne	s1,s3,800019c4 <procinit+0x6e>
  }
}
    800019f6:	70e2                	ld	ra,56(sp)
    800019f8:	7442                	ld	s0,48(sp)
    800019fa:	74a2                	ld	s1,40(sp)
    800019fc:	7902                	ld	s2,32(sp)
    800019fe:	69e2                	ld	s3,24(sp)
    80001a00:	6a42                	ld	s4,16(sp)
    80001a02:	6aa2                	ld	s5,8(sp)
    80001a04:	6b02                	ld	s6,0(sp)
    80001a06:	6121                	addi	sp,sp,64
    80001a08:	8082                	ret

0000000080001a0a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e422                	sd	s0,8(sp)
    80001a0e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a10:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a12:	2501                	sext.w	a0,a0
    80001a14:	6422                	ld	s0,8(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret

0000000080001a1a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a1a:	1141                	addi	sp,sp,-16
    80001a1c:	e422                	sd	s0,8(sp)
    80001a1e:	0800                	addi	s0,sp,16
    80001a20:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a22:	2781                	sext.w	a5,a5
    80001a24:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a26:	00010517          	auipc	a0,0x10
    80001a2a:	8aa50513          	addi	a0,a0,-1878 # 800112d0 <cpus>
    80001a2e:	953e                	add	a0,a0,a5
    80001a30:	6422                	ld	s0,8(sp)
    80001a32:	0141                	addi	sp,sp,16
    80001a34:	8082                	ret

0000000080001a36 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a36:	1101                	addi	sp,sp,-32
    80001a38:	ec06                	sd	ra,24(sp)
    80001a3a:	e822                	sd	s0,16(sp)
    80001a3c:	e426                	sd	s1,8(sp)
    80001a3e:	1000                	addi	s0,sp,32
  push_off();
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	190080e7          	jalr	400(ra) # 80000bd0 <push_off>
    80001a48:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a4a:	2781                	sext.w	a5,a5
    80001a4c:	079e                	slli	a5,a5,0x7
    80001a4e:	00010717          	auipc	a4,0x10
    80001a52:	85270713          	addi	a4,a4,-1966 # 800112a0 <pid_lock>
    80001a56:	97ba                	add	a5,a5,a4
    80001a58:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	216080e7          	jalr	534(ra) # 80000c70 <pop_off>
  return p;
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6105                	addi	sp,sp,32
    80001a6c:	8082                	ret

0000000080001a6e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a6e:	1141                	addi	sp,sp,-16
    80001a70:	e406                	sd	ra,8(sp)
    80001a72:	e022                	sd	s0,0(sp)
    80001a74:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a76:	00000097          	auipc	ra,0x0
    80001a7a:	fc0080e7          	jalr	-64(ra) # 80001a36 <myproc>
    80001a7e:	2d850513          	addi	a0,a0,728
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	24e080e7          	jalr	590(ra) # 80000cd0 <release>

  if (first) {
    80001a8a:	00007797          	auipc	a5,0x7
    80001a8e:	de67a783          	lw	a5,-538(a5) # 80008870 <first.1>
    80001a92:	eb89                	bnez	a5,80001aa4 <forkret+0x36>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a94:	00001097          	auipc	ra,0x1
    80001a98:	f00080e7          	jalr	-256(ra) # 80002994 <usertrapret>
}
    80001a9c:	60a2                	ld	ra,8(sp)
    80001a9e:	6402                	ld	s0,0(sp)
    80001aa0:	0141                	addi	sp,sp,16
    80001aa2:	8082                	ret
    first = 0;
    80001aa4:	00007797          	auipc	a5,0x7
    80001aa8:	dc07a623          	sw	zero,-564(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001aac:	4505                	li	a0,1
    80001aae:	00002097          	auipc	ra,0x2
    80001ab2:	d4a080e7          	jalr	-694(ra) # 800037f8 <fsinit>
    80001ab6:	bff9                	j	80001a94 <forkret+0x26>

0000000080001ab8 <allocpid>:
allocpid() {
    80001ab8:	1101                	addi	sp,sp,-32
    80001aba:	ec06                	sd	ra,24(sp)
    80001abc:	e822                	sd	s0,16(sp)
    80001abe:	e426                	sd	s1,8(sp)
    80001ac0:	e04a                	sd	s2,0(sp)
    80001ac2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ac4:	0000f917          	auipc	s2,0xf
    80001ac8:	7dc90913          	addi	s2,s2,2012 # 800112a0 <pid_lock>
    80001acc:	854a                	mv	a0,s2
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	14e080e7          	jalr	334(ra) # 80000c1c <acquire>
  pid = nextpid;
    80001ad6:	00007797          	auipc	a5,0x7
    80001ada:	d9e78793          	addi	a5,a5,-610 # 80008874 <nextpid>
    80001ade:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae0:	0014871b          	addiw	a4,s1,1
    80001ae4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae6:	854a                	mv	a0,s2
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	1e8080e7          	jalr	488(ra) # 80000cd0 <release>
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6902                	ld	s2,0(sp)
    80001afa:	6105                	addi	sp,sp,32
    80001afc:	8082                	ret

0000000080001afe <proc_pagetable>:
{
    80001afe:	1101                	addi	sp,sp,-32
    80001b00:	ec06                	sd	ra,24(sp)
    80001b02:	e822                	sd	s0,16(sp)
    80001b04:	e426                	sd	s1,8(sp)
    80001b06:	e04a                	sd	s2,0(sp)
    80001b08:	1000                	addi	s0,sp,32
    80001b0a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	840080e7          	jalr	-1984(ra) # 8000134c <uvmcreate>
    80001b14:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b16:	c121                	beqz	a0,80001b56 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b18:	4729                	li	a4,10
    80001b1a:	00005697          	auipc	a3,0x5
    80001b1e:	4e668693          	addi	a3,a3,1254 # 80007000 <_trampoline>
    80001b22:	6605                	lui	a2,0x1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	5b4080e7          	jalr	1460(ra) # 800010e0 <mappages>
    80001b34:	02054863          	bltz	a0,80001b64 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b38:	4719                	li	a4,6
    80001b3a:	33093683          	ld	a3,816(s2)
    80001b3e:	6605                	lui	a2,0x1
    80001b40:	020005b7          	lui	a1,0x2000
    80001b44:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b46:	05b6                	slli	a1,a1,0xd
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	596080e7          	jalr	1430(ra) # 800010e0 <mappages>
    80001b52:	02054163          	bltz	a0,80001b74 <proc_pagetable+0x76>
}
    80001b56:	8526                	mv	a0,s1
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6902                	ld	s2,0(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret
    uvmfree(pagetable, 0);
    80001b64:	4581                	li	a1,0
    80001b66:	8526                	mv	a0,s1
    80001b68:	00000097          	auipc	ra,0x0
    80001b6c:	9e2080e7          	jalr	-1566(ra) # 8000154a <uvmfree>
    return 0;
    80001b70:	4481                	li	s1,0
    80001b72:	b7d5                	j	80001b56 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b74:	4681                	li	a3,0
    80001b76:	4605                	li	a2,1
    80001b78:	040005b7          	lui	a1,0x4000
    80001b7c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b7e:	05b2                	slli	a1,a1,0xc
    80001b80:	8526                	mv	a0,s1
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	724080e7          	jalr	1828(ra) # 800012a6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b8a:	4581                	li	a1,0
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	00000097          	auipc	ra,0x0
    80001b92:	9bc080e7          	jalr	-1604(ra) # 8000154a <uvmfree>
    return 0;
    80001b96:	4481                	li	s1,0
    80001b98:	bf7d                	j	80001b56 <proc_pagetable+0x58>

0000000080001b9a <proc_freepagetable>:
{
    80001b9a:	1101                	addi	sp,sp,-32
    80001b9c:	ec06                	sd	ra,24(sp)
    80001b9e:	e822                	sd	s0,16(sp)
    80001ba0:	e426                	sd	s1,8(sp)
    80001ba2:	e04a                	sd	s2,0(sp)
    80001ba4:	1000                	addi	s0,sp,32
    80001ba6:	84aa                	mv	s1,a0
    80001ba8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001baa:	4681                	li	a3,0
    80001bac:	4605                	li	a2,1
    80001bae:	040005b7          	lui	a1,0x4000
    80001bb2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bb4:	05b2                	slli	a1,a1,0xc
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	6f0080e7          	jalr	1776(ra) # 800012a6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bbe:	4681                	li	a3,0
    80001bc0:	4605                	li	a2,1
    80001bc2:	020005b7          	lui	a1,0x2000
    80001bc6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bc8:	05b6                	slli	a1,a1,0xd
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	6da080e7          	jalr	1754(ra) # 800012a6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd4:	85ca                	mv	a1,s2
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	00000097          	auipc	ra,0x0
    80001bdc:	972080e7          	jalr	-1678(ra) # 8000154a <uvmfree>
}
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6902                	ld	s2,0(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret

0000000080001bec <freeproc>:
{
    80001bec:	1101                	addi	sp,sp,-32
    80001bee:	ec06                	sd	ra,24(sp)
    80001bf0:	e822                	sd	s0,16(sp)
    80001bf2:	e426                	sd	s1,8(sp)
    80001bf4:	1000                	addi	s0,sp,32
    80001bf6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bf8:	33053503          	ld	a0,816(a0)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x1a>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	de6080e7          	jalr	-538(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001c06:	3204b823          	sd	zero,816(s1)
  if(p->pagetable)
    80001c0a:	3284b503          	ld	a0,808(s1)
    80001c0e:	c519                	beqz	a0,80001c1c <freeproc+0x30>
    proc_freepagetable(p->pagetable, p->sz);
    80001c10:	3204b583          	ld	a1,800(s1)
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	f86080e7          	jalr	-122(ra) # 80001b9a <proc_freepagetable>
  p->pagetable = 0;
    80001c1c:	3204b423          	sd	zero,808(s1)
  p->sz = 0;
    80001c20:	3204b023          	sd	zero,800(s1)
  p->pid = 0;
    80001c24:	3004a423          	sw	zero,776(s1)
  p->parent = 0;
    80001c28:	3004b823          	sd	zero,784(s1)
  p->name[0] = 0;
    80001c2c:	42048823          	sb	zero,1072(s1)
  p->chan = 0;
    80001c30:	2e04bc23          	sd	zero,760(s1)
  p->killed = 0;
    80001c34:	3004a023          	sw	zero,768(s1)
  p->xstate = 0;
    80001c38:	3004a223          	sw	zero,772(s1)
  p->state = UNUSED;
    80001c3c:	2e04a823          	sw	zero,752(s1)
}
    80001c40:	60e2                	ld	ra,24(sp)
    80001c42:	6442                	ld	s0,16(sp)
    80001c44:	64a2                	ld	s1,8(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret

0000000080001c4a <allocproc>:
{
    80001c4a:	7179                	addi	sp,sp,-48
    80001c4c:	f406                	sd	ra,40(sp)
    80001c4e:	f022                	sd	s0,32(sp)
    80001c50:	ec26                	sd	s1,24(sp)
    80001c52:	e84a                	sd	s2,16(sp)
    80001c54:	e44e                	sd	s3,8(sp)
    80001c56:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	00010497          	auipc	s1,0x10
    80001c5c:	a9048493          	addi	s1,s1,-1392 # 800116e8 <proc>
    80001c60:	00021997          	auipc	s3,0x21
    80001c64:	a8898993          	addi	s3,s3,-1400 # 800226e8 <mmr_list>
    acquire(&p->lock);
    80001c68:	2d848913          	addi	s2,s1,728
    80001c6c:	854a                	mv	a0,s2
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	fae080e7          	jalr	-82(ra) # 80000c1c <acquire>
    if(p->state == UNUSED) {
    80001c76:	2f04a783          	lw	a5,752(s1)
    80001c7a:	cf81                	beqz	a5,80001c92 <allocproc+0x48>
      release(&p->lock);
    80001c7c:	854a                	mv	a0,s2
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	052080e7          	jalr	82(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c86:	44048493          	addi	s1,s1,1088
    80001c8a:	fd349fe3          	bne	s1,s3,80001c68 <allocproc+0x1e>
  return 0;
    80001c8e:	4481                	li	s1,0
    80001c90:	a085                	j	80001cf0 <allocproc+0xa6>
  p->pid = allocpid();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	e26080e7          	jalr	-474(ra) # 80001ab8 <allocpid>
    80001c9a:	30a4a423          	sw	a0,776(s1)
  p->state = USED;
    80001c9e:	4785                	li	a5,1
    80001ca0:	2ef4a823          	sw	a5,752(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	e3e080e7          	jalr	-450(ra) # 80000ae2 <kalloc>
    80001cac:	89aa                	mv	s3,a0
    80001cae:	32a4b823          	sd	a0,816(s1)
    80001cb2:	c539                	beqz	a0,80001d00 <allocproc+0xb6>
  p->pagetable = proc_pagetable(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	e48080e7          	jalr	-440(ra) # 80001afe <proc_pagetable>
    80001cbe:	89aa                	mv	s3,a0
    80001cc0:	32a4b423          	sd	a0,808(s1)
  if(p->pagetable == 0){
    80001cc4:	c931                	beqz	a0,80001d18 <allocproc+0xce>
  memset(&p->context, 0, sizeof(p->context));
    80001cc6:	07000613          	li	a2,112
    80001cca:	4581                	li	a1,0
    80001ccc:	33848513          	addi	a0,s1,824
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	048080e7          	jalr	72(ra) # 80000d18 <memset>
  p->context.ra = (uint64)forkret;
    80001cd8:	00000797          	auipc	a5,0x0
    80001cdc:	d9678793          	addi	a5,a5,-618 # 80001a6e <forkret>
    80001ce0:	32f4bc23          	sd	a5,824(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	3184b783          	ld	a5,792(s1)
    80001ce8:	6705                	lui	a4,0x1
    80001cea:	97ba                	add	a5,a5,a4
    80001cec:	34f4b023          	sd	a5,832(s1)
}
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	70a2                	ld	ra,40(sp)
    80001cf4:	7402                	ld	s0,32(sp)
    80001cf6:	64e2                	ld	s1,24(sp)
    80001cf8:	6942                	ld	s2,16(sp)
    80001cfa:	69a2                	ld	s3,8(sp)
    80001cfc:	6145                	addi	sp,sp,48
    80001cfe:	8082                	ret
    freeproc(p);
    80001d00:	8526                	mv	a0,s1
    80001d02:	00000097          	auipc	ra,0x0
    80001d06:	eea080e7          	jalr	-278(ra) # 80001bec <freeproc>
    release(&p->lock);
    80001d0a:	854a                	mv	a0,s2
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	fc4080e7          	jalr	-60(ra) # 80000cd0 <release>
    return 0;
    80001d14:	84ce                	mv	s1,s3
    80001d16:	bfe9                	j	80001cf0 <allocproc+0xa6>
    freeproc(p);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	ed2080e7          	jalr	-302(ra) # 80001bec <freeproc>
    release(&p->lock);
    80001d22:	854a                	mv	a0,s2
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	fac080e7          	jalr	-84(ra) # 80000cd0 <release>
    return 0;
    80001d2c:	84ce                	mv	s1,s3
    80001d2e:	b7c9                	j	80001cf0 <allocproc+0xa6>

0000000080001d30 <userinit>:
{
    80001d30:	1101                	addi	sp,sp,-32
    80001d32:	ec06                	sd	ra,24(sp)
    80001d34:	e822                	sd	s0,16(sp)
    80001d36:	e426                	sd	s1,8(sp)
    80001d38:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	f10080e7          	jalr	-240(ra) # 80001c4a <allocproc>
    80001d42:	84aa                	mv	s1,a0
  initproc = p;
    80001d44:	00007797          	auipc	a5,0x7
    80001d48:	2ea7b223          	sd	a0,740(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d4c:	03400613          	li	a2,52
    80001d50:	00007597          	auipc	a1,0x7
    80001d54:	b3058593          	addi	a1,a1,-1232 # 80008880 <initcode>
    80001d58:	32853503          	ld	a0,808(a0)
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	61e080e7          	jalr	1566(ra) # 8000137a <uvminit>
  p->sz = PGSIZE;
    80001d64:	6785                	lui	a5,0x1
    80001d66:	32f4b023          	sd	a5,800(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d6a:	3304b703          	ld	a4,816(s1)
    80001d6e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d72:	3304b703          	ld	a4,816(s1)
    80001d76:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d78:	4641                	li	a2,16
    80001d7a:	00006597          	auipc	a1,0x6
    80001d7e:	43e58593          	addi	a1,a1,1086 # 800081b8 <digits+0x178>
    80001d82:	43048513          	addi	a0,s1,1072
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	0dc080e7          	jalr	220(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001d8e:	00006517          	auipc	a0,0x6
    80001d92:	43a50513          	addi	a0,a0,1082 # 800081c8 <digits+0x188>
    80001d96:	00002097          	auipc	ra,0x2
    80001d9a:	498080e7          	jalr	1176(ra) # 8000422e <namei>
    80001d9e:	42a4b423          	sd	a0,1064(s1)
  p->state = RUNNABLE;
    80001da2:	478d                	li	a5,3
    80001da4:	2ef4a823          	sw	a5,752(s1)
  p->cur_max = MAXVA - 2*PGSIZE;
    80001da8:	020007b7          	lui	a5,0x2000
    80001dac:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001dae:	07b6                	slli	a5,a5,0xd
    80001db0:	2cf4b823          	sd	a5,720(s1)
  release(&p->lock);
    80001db4:	2d848513          	addi	a0,s1,728
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	f18080e7          	jalr	-232(ra) # 80000cd0 <release>
}
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret

0000000080001dca <growproc>:
{
    80001dca:	1101                	addi	sp,sp,-32
    80001dcc:	ec06                	sd	ra,24(sp)
    80001dce:	e822                	sd	s0,16(sp)
    80001dd0:	e426                	sd	s1,8(sp)
    80001dd2:	e04a                	sd	s2,0(sp)
    80001dd4:	1000                	addi	s0,sp,32
    80001dd6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	c5e080e7          	jalr	-930(ra) # 80001a36 <myproc>
    80001de0:	892a                	mv	s2,a0
  sz = p->sz;
    80001de2:	32053583          	ld	a1,800(a0)
    80001de6:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001dea:	00904f63          	bgtz	s1,80001e08 <growproc+0x3e>
  } else if(n < 0){
    80001dee:	0204ce63          	bltz	s1,80001e2a <growproc+0x60>
  p->sz = sz;
    80001df2:	1782                	slli	a5,a5,0x20
    80001df4:	9381                	srli	a5,a5,0x20
    80001df6:	32f93023          	sd	a5,800(s2)
  return 0;
    80001dfa:	4501                	li	a0,0
}
    80001dfc:	60e2                	ld	ra,24(sp)
    80001dfe:	6442                	ld	s0,16(sp)
    80001e00:	64a2                	ld	s1,8(sp)
    80001e02:	6902                	ld	s2,0(sp)
    80001e04:	6105                	addi	sp,sp,32
    80001e06:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e08:	00f4863b          	addw	a2,s1,a5
    80001e0c:	1602                	slli	a2,a2,0x20
    80001e0e:	9201                	srli	a2,a2,0x20
    80001e10:	1582                	slli	a1,a1,0x20
    80001e12:	9181                	srli	a1,a1,0x20
    80001e14:	32853503          	ld	a0,808(a0)
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	61c080e7          	jalr	1564(ra) # 80001434 <uvmalloc>
    80001e20:	0005079b          	sext.w	a5,a0
    80001e24:	f7f9                	bnez	a5,80001df2 <growproc+0x28>
      return -1;
    80001e26:	557d                	li	a0,-1
    80001e28:	bfd1                	j	80001dfc <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e2a:	00f4863b          	addw	a2,s1,a5
    80001e2e:	1602                	slli	a2,a2,0x20
    80001e30:	9201                	srli	a2,a2,0x20
    80001e32:	1582                	slli	a1,a1,0x20
    80001e34:	9181                	srli	a1,a1,0x20
    80001e36:	32853503          	ld	a0,808(a0)
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	5b2080e7          	jalr	1458(ra) # 800013ec <uvmdealloc>
    80001e42:	0005079b          	sext.w	a5,a0
    80001e46:	b775                	j	80001df2 <growproc+0x28>

0000000080001e48 <fork>:
{
    80001e48:	7139                	addi	sp,sp,-64
    80001e4a:	fc06                	sd	ra,56(sp)
    80001e4c:	f822                	sd	s0,48(sp)
    80001e4e:	f426                	sd	s1,40(sp)
    80001e50:	f04a                	sd	s2,32(sp)
    80001e52:	ec4e                	sd	s3,24(sp)
    80001e54:	e852                	sd	s4,16(sp)
    80001e56:	e456                	sd	s5,8(sp)
    80001e58:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	bdc080e7          	jalr	-1060(ra) # 80001a36 <myproc>
    80001e62:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	de6080e7          	jalr	-538(ra) # 80001c4a <allocproc>
    80001e6c:	12050463          	beqz	a0,80001f94 <fork+0x14c>
    80001e70:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e72:	320ab603          	ld	a2,800(s5)
    80001e76:	32853583          	ld	a1,808(a0)
    80001e7a:	328ab503          	ld	a0,808(s5)
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	706080e7          	jalr	1798(ra) # 80001584 <uvmcopy>
    80001e86:	04054c63          	bltz	a0,80001ede <fork+0x96>
  np->sz = p->sz;
    80001e8a:	320ab783          	ld	a5,800(s5)
    80001e8e:	32fa3023          	sd	a5,800(s4)
  np->cur_max = p->cur_max;
    80001e92:	2d0ab783          	ld	a5,720(s5)
    80001e96:	2cfa3823          	sd	a5,720(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e9a:	330ab683          	ld	a3,816(s5)
    80001e9e:	87b6                	mv	a5,a3
    80001ea0:	330a3703          	ld	a4,816(s4)
    80001ea4:	12068693          	addi	a3,a3,288
    80001ea8:	0007b803          	ld	a6,0(a5)
    80001eac:	6788                	ld	a0,8(a5)
    80001eae:	6b8c                	ld	a1,16(a5)
    80001eb0:	6f90                	ld	a2,24(a5)
    80001eb2:	01073023          	sd	a6,0(a4)
    80001eb6:	e708                	sd	a0,8(a4)
    80001eb8:	eb0c                	sd	a1,16(a4)
    80001eba:	ef10                	sd	a2,24(a4)
    80001ebc:	02078793          	addi	a5,a5,32
    80001ec0:	02070713          	addi	a4,a4,32
    80001ec4:	fed792e3          	bne	a5,a3,80001ea8 <fork+0x60>
  np->trapframe->a0 = 0;
    80001ec8:	330a3783          	ld	a5,816(s4)
    80001ecc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ed0:	3a8a8493          	addi	s1,s5,936
    80001ed4:	3a8a0913          	addi	s2,s4,936
    80001ed8:	428a8993          	addi	s3,s5,1064
    80001edc:	a015                	j	80001f00 <fork+0xb8>
    freeproc(np);
    80001ede:	8552                	mv	a0,s4
    80001ee0:	00000097          	auipc	ra,0x0
    80001ee4:	d0c080e7          	jalr	-756(ra) # 80001bec <freeproc>
    release(&np->lock);
    80001ee8:	2d8a0513          	addi	a0,s4,728
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	de4080e7          	jalr	-540(ra) # 80000cd0 <release>
    return -1;
    80001ef4:	59fd                	li	s3,-1
    80001ef6:	a069                	j	80001f80 <fork+0x138>
  for(i = 0; i < NOFILE; i++)
    80001ef8:	04a1                	addi	s1,s1,8
    80001efa:	0921                	addi	s2,s2,8
    80001efc:	01348b63          	beq	s1,s3,80001f12 <fork+0xca>
    if(p->ofile[i])
    80001f00:	6088                	ld	a0,0(s1)
    80001f02:	d97d                	beqz	a0,80001ef8 <fork+0xb0>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f04:	00003097          	auipc	ra,0x3
    80001f08:	9c4080e7          	jalr	-1596(ra) # 800048c8 <filedup>
    80001f0c:	00a93023          	sd	a0,0(s2)
    80001f10:	b7e5                	j	80001ef8 <fork+0xb0>
  np->cwd = idup(p->cwd);
    80001f12:	428ab503          	ld	a0,1064(s5)
    80001f16:	00002097          	auipc	ra,0x2
    80001f1a:	b1e080e7          	jalr	-1250(ra) # 80003a34 <idup>
    80001f1e:	42aa3423          	sd	a0,1064(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f22:	4641                	li	a2,16
    80001f24:	430a8593          	addi	a1,s5,1072
    80001f28:	430a0513          	addi	a0,s4,1072
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	f36080e7          	jalr	-202(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001f34:	308a2983          	lw	s3,776(s4)
  release(&np->lock);
    80001f38:	2d8a0493          	addi	s1,s4,728
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d92080e7          	jalr	-622(ra) # 80000cd0 <release>
  acquire(&wait_lock);
    80001f46:	0000f917          	auipc	s2,0xf
    80001f4a:	37290913          	addi	s2,s2,882 # 800112b8 <wait_lock>
    80001f4e:	854a                	mv	a0,s2
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	ccc080e7          	jalr	-820(ra) # 80000c1c <acquire>
  np->parent = p;
    80001f58:	315a3823          	sd	s5,784(s4)
  release(&wait_lock);
    80001f5c:	854a                	mv	a0,s2
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	d72080e7          	jalr	-654(ra) # 80000cd0 <release>
  acquire(&np->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	cb4080e7          	jalr	-844(ra) # 80000c1c <acquire>
  np->state = RUNNABLE;
    80001f70:	478d                	li	a5,3
    80001f72:	2efa2823          	sw	a5,752(s4)
  release(&np->lock);
    80001f76:	8526                	mv	a0,s1
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	d58080e7          	jalr	-680(ra) # 80000cd0 <release>
}
    80001f80:	854e                	mv	a0,s3
    80001f82:	70e2                	ld	ra,56(sp)
    80001f84:	7442                	ld	s0,48(sp)
    80001f86:	74a2                	ld	s1,40(sp)
    80001f88:	7902                	ld	s2,32(sp)
    80001f8a:	69e2                	ld	s3,24(sp)
    80001f8c:	6a42                	ld	s4,16(sp)
    80001f8e:	6aa2                	ld	s5,8(sp)
    80001f90:	6121                	addi	sp,sp,64
    80001f92:	8082                	ret
    return -1;
    80001f94:	59fd                	li	s3,-1
    80001f96:	b7ed                	j	80001f80 <fork+0x138>

0000000080001f98 <scheduler>:
{
    80001f98:	715d                	addi	sp,sp,-80
    80001f9a:	e486                	sd	ra,72(sp)
    80001f9c:	e0a2                	sd	s0,64(sp)
    80001f9e:	fc26                	sd	s1,56(sp)
    80001fa0:	f84a                	sd	s2,48(sp)
    80001fa2:	f44e                	sd	s3,40(sp)
    80001fa4:	f052                	sd	s4,32(sp)
    80001fa6:	ec56                	sd	s5,24(sp)
    80001fa8:	e85a                	sd	s6,16(sp)
    80001faa:	e45e                	sd	s7,8(sp)
    80001fac:	0880                	addi	s0,sp,80
    80001fae:	8792                	mv	a5,tp
  int id = r_tp();
    80001fb0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fb2:	00779b13          	slli	s6,a5,0x7
    80001fb6:	0000f717          	auipc	a4,0xf
    80001fba:	2ea70713          	addi	a4,a4,746 # 800112a0 <pid_lock>
    80001fbe:	975a                	add	a4,a4,s6
    80001fc0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fc4:	0000f717          	auipc	a4,0xf
    80001fc8:	31470713          	addi	a4,a4,788 # 800112d8 <cpus+0x8>
    80001fcc:	9b3a                	add	s6,s6,a4
      if(p->state == RUNNABLE) {
    80001fce:	4a0d                	li	s4,3
        p->state = RUNNING;
    80001fd0:	4b91                	li	s7,4
        c->proc = p;
    80001fd2:	079e                	slli	a5,a5,0x7
    80001fd4:	0000fa97          	auipc	s5,0xf
    80001fd8:	2cca8a93          	addi	s5,s5,716 # 800112a0 <pid_lock>
    80001fdc:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fde:	00020997          	auipc	s3,0x20
    80001fe2:	70a98993          	addi	s3,s3,1802 # 800226e8 <mmr_list>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fee:	10079073          	csrw	sstatus,a5
    80001ff2:	0000f497          	auipc	s1,0xf
    80001ff6:	6f648493          	addi	s1,s1,1782 # 800116e8 <proc>
    80001ffa:	a811                	j	8000200e <scheduler+0x76>
      release(&p->lock);
    80001ffc:	854a                	mv	a0,s2
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	cd2080e7          	jalr	-814(ra) # 80000cd0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002006:	44048493          	addi	s1,s1,1088
    8000200a:	fd348ee3          	beq	s1,s3,80001fe6 <scheduler+0x4e>
      acquire(&p->lock);
    8000200e:	2d848913          	addi	s2,s1,728
    80002012:	854a                	mv	a0,s2
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	c08080e7          	jalr	-1016(ra) # 80000c1c <acquire>
      if(p->state == RUNNABLE) {
    8000201c:	2f04a783          	lw	a5,752(s1)
    80002020:	fd479ee3          	bne	a5,s4,80001ffc <scheduler+0x64>
        p->state = RUNNING;
    80002024:	2f74a823          	sw	s7,752(s1)
        c->proc = p;
    80002028:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    8000202c:	33848593          	addi	a1,s1,824
    80002030:	855a                	mv	a0,s6
    80002032:	00001097          	auipc	ra,0x1
    80002036:	8b8080e7          	jalr	-1864(ra) # 800028ea <swtch>
        c->proc = 0;
    8000203a:	020ab823          	sd	zero,48(s5)
    8000203e:	bf7d                	j	80001ffc <scheduler+0x64>

0000000080002040 <sched>:
{
    80002040:	7179                	addi	sp,sp,-48
    80002042:	f406                	sd	ra,40(sp)
    80002044:	f022                	sd	s0,32(sp)
    80002046:	ec26                	sd	s1,24(sp)
    80002048:	e84a                	sd	s2,16(sp)
    8000204a:	e44e                	sd	s3,8(sp)
    8000204c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	9e8080e7          	jalr	-1560(ra) # 80001a36 <myproc>
    80002056:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002058:	2d850513          	addi	a0,a0,728
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b46080e7          	jalr	-1210(ra) # 80000ba2 <holding>
    80002064:	cd25                	beqz	a0,800020dc <sched+0x9c>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002066:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	0000f717          	auipc	a4,0xf
    80002070:	23470713          	addi	a4,a4,564 # 800112a0 <pid_lock>
    80002074:	97ba                	add	a5,a5,a4
    80002076:	0a87a703          	lw	a4,168(a5)
    8000207a:	4785                	li	a5,1
    8000207c:	06f71863          	bne	a4,a5,800020ec <sched+0xac>
  if(p->state == RUNNING)
    80002080:	2f04a703          	lw	a4,752(s1)
    80002084:	4791                	li	a5,4
    80002086:	06f70b63          	beq	a4,a5,800020fc <sched+0xbc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000208a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002090:	efb5                	bnez	a5,8000210c <sched+0xcc>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002092:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002094:	0000f917          	auipc	s2,0xf
    80002098:	20c90913          	addi	s2,s2,524 # 800112a0 <pid_lock>
    8000209c:	2781                	sext.w	a5,a5
    8000209e:	079e                	slli	a5,a5,0x7
    800020a0:	97ca                	add	a5,a5,s2
    800020a2:	0ac7a983          	lw	s3,172(a5)
    800020a6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a8:	2781                	sext.w	a5,a5
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	0000f597          	auipc	a1,0xf
    800020b0:	22c58593          	addi	a1,a1,556 # 800112d8 <cpus+0x8>
    800020b4:	95be                	add	a1,a1,a5
    800020b6:	33848513          	addi	a0,s1,824
    800020ba:	00001097          	auipc	ra,0x1
    800020be:	830080e7          	jalr	-2000(ra) # 800028ea <swtch>
    800020c2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	993e                	add	s2,s2,a5
    800020ca:	0b392623          	sw	s3,172(s2)
}
    800020ce:	70a2                	ld	ra,40(sp)
    800020d0:	7402                	ld	s0,32(sp)
    800020d2:	64e2                	ld	s1,24(sp)
    800020d4:	6942                	ld	s2,16(sp)
    800020d6:	69a2                	ld	s3,8(sp)
    800020d8:	6145                	addi	sp,sp,48
    800020da:	8082                	ret
    panic("sched p->lock");
    800020dc:	00006517          	auipc	a0,0x6
    800020e0:	0f450513          	addi	a0,a0,244 # 800081d0 <digits+0x190>
    800020e4:	ffffe097          	auipc	ra,0xffffe
    800020e8:	458080e7          	jalr	1112(ra) # 8000053c <panic>
    panic("sched locks");
    800020ec:	00006517          	auipc	a0,0x6
    800020f0:	0f450513          	addi	a0,a0,244 # 800081e0 <digits+0x1a0>
    800020f4:	ffffe097          	auipc	ra,0xffffe
    800020f8:	448080e7          	jalr	1096(ra) # 8000053c <panic>
    panic("sched running");
    800020fc:	00006517          	auipc	a0,0x6
    80002100:	0f450513          	addi	a0,a0,244 # 800081f0 <digits+0x1b0>
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
    panic("sched interruptible");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	0f450513          	addi	a0,a0,244 # 80008200 <digits+0x1c0>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	428080e7          	jalr	1064(ra) # 8000053c <panic>

000000008000211c <yield>:
{
    8000211c:	1101                	addi	sp,sp,-32
    8000211e:	ec06                	sd	ra,24(sp)
    80002120:	e822                	sd	s0,16(sp)
    80002122:	e426                	sd	s1,8(sp)
    80002124:	e04a                	sd	s2,0(sp)
    80002126:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	90e080e7          	jalr	-1778(ra) # 80001a36 <myproc>
    80002130:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002132:	2d850913          	addi	s2,a0,728
    80002136:	854a                	mv	a0,s2
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	ae4080e7          	jalr	-1308(ra) # 80000c1c <acquire>
  p->state = RUNNABLE;
    80002140:	478d                	li	a5,3
    80002142:	2ef4a823          	sw	a5,752(s1)
  sched();
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	efa080e7          	jalr	-262(ra) # 80002040 <sched>
  release(&p->lock);
    8000214e:	854a                	mv	a0,s2
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b80080e7          	jalr	-1152(ra) # 80000cd0 <release>
}
    80002158:	60e2                	ld	ra,24(sp)
    8000215a:	6442                	ld	s0,16(sp)
    8000215c:	64a2                	ld	s1,8(sp)
    8000215e:	6902                	ld	s2,0(sp)
    80002160:	6105                	addi	sp,sp,32
    80002162:	8082                	ret

0000000080002164 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002164:	7179                	addi	sp,sp,-48
    80002166:	f406                	sd	ra,40(sp)
    80002168:	f022                	sd	s0,32(sp)
    8000216a:	ec26                	sd	s1,24(sp)
    8000216c:	e84a                	sd	s2,16(sp)
    8000216e:	e44e                	sd	s3,8(sp)
    80002170:	e052                	sd	s4,0(sp)
    80002172:	1800                	addi	s0,sp,48
    80002174:	89aa                	mv	s3,a0
    80002176:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	8be080e7          	jalr	-1858(ra) # 80001a36 <myproc>
    80002180:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002182:	2d850a13          	addi	s4,a0,728
    80002186:	8552                	mv	a0,s4
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a94080e7          	jalr	-1388(ra) # 80000c1c <acquire>
  release(lk);
    80002190:	854a                	mv	a0,s2
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b3e080e7          	jalr	-1218(ra) # 80000cd0 <release>

  // Go to sleep.
  p->chan = chan;
    8000219a:	2f34bc23          	sd	s3,760(s1)
  p->state = SLEEPING;
    8000219e:	4789                	li	a5,2
    800021a0:	2ef4a823          	sw	a5,752(s1)

  sched();
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	e9c080e7          	jalr	-356(ra) # 80002040 <sched>

  // Tidy up.
  p->chan = 0;
    800021ac:	2e04bc23          	sd	zero,760(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021b0:	8552                	mv	a0,s4
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	b1e080e7          	jalr	-1250(ra) # 80000cd0 <release>
  acquire(lk);
    800021ba:	854a                	mv	a0,s2
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a60080e7          	jalr	-1440(ra) # 80000c1c <acquire>
}
    800021c4:	70a2                	ld	ra,40(sp)
    800021c6:	7402                	ld	s0,32(sp)
    800021c8:	64e2                	ld	s1,24(sp)
    800021ca:	6942                	ld	s2,16(sp)
    800021cc:	69a2                	ld	s3,8(sp)
    800021ce:	6a02                	ld	s4,0(sp)
    800021d0:	6145                	addi	sp,sp,48
    800021d2:	8082                	ret

00000000800021d4 <wait>:
{
    800021d4:	711d                	addi	sp,sp,-96
    800021d6:	ec86                	sd	ra,88(sp)
    800021d8:	e8a2                	sd	s0,80(sp)
    800021da:	e4a6                	sd	s1,72(sp)
    800021dc:	e0ca                	sd	s2,64(sp)
    800021de:	fc4e                	sd	s3,56(sp)
    800021e0:	f852                	sd	s4,48(sp)
    800021e2:	f456                	sd	s5,40(sp)
    800021e4:	f05a                	sd	s6,32(sp)
    800021e6:	ec5e                	sd	s7,24(sp)
    800021e8:	e862                	sd	s8,16(sp)
    800021ea:	e466                	sd	s9,8(sp)
    800021ec:	1080                	addi	s0,sp,96
    800021ee:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    800021f0:	00000097          	auipc	ra,0x0
    800021f4:	846080e7          	jalr	-1978(ra) # 80001a36 <myproc>
    800021f8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021fa:	0000f517          	auipc	a0,0xf
    800021fe:	0be50513          	addi	a0,a0,190 # 800112b8 <wait_lock>
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	a1a080e7          	jalr	-1510(ra) # 80000c1c <acquire>
    havekids = 0;
    8000220a:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    8000220c:	4a95                	li	s5,5
        havekids = 1;
    8000220e:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002210:	00020997          	auipc	s3,0x20
    80002214:	4d898993          	addi	s3,s3,1240 # 800226e8 <mmr_list>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002218:	0000fc97          	auipc	s9,0xf
    8000221c:	0a0c8c93          	addi	s9,s9,160 # 800112b8 <wait_lock>
    havekids = 0;
    80002220:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    80002222:	0000f497          	auipc	s1,0xf
    80002226:	4c648493          	addi	s1,s1,1222 # 800116e8 <proc>
    8000222a:	a0bd                	j	80002298 <wait+0xc4>
          pid = np->pid;
    8000222c:	3084a983          	lw	s3,776(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002230:	000b8e63          	beqz	s7,8000224c <wait+0x78>
    80002234:	4691                	li	a3,4
    80002236:	30448613          	addi	a2,s1,772
    8000223a:	85de                	mv	a1,s7
    8000223c:	32893503          	ld	a0,808(s2)
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	43c080e7          	jalr	1084(ra) # 8000167c <copyout>
    80002248:	02054563          	bltz	a0,80002272 <wait+0x9e>
          freeproc(np);
    8000224c:	8526                	mv	a0,s1
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	99e080e7          	jalr	-1634(ra) # 80001bec <freeproc>
          release(&np->lock);
    80002256:	8552                	mv	a0,s4
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a78080e7          	jalr	-1416(ra) # 80000cd0 <release>
          release(&wait_lock);
    80002260:	0000f517          	auipc	a0,0xf
    80002264:	05850513          	addi	a0,a0,88 # 800112b8 <wait_lock>
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a68080e7          	jalr	-1432(ra) # 80000cd0 <release>
          return pid;
    80002270:	a0bd                	j	800022de <wait+0x10a>
            release(&np->lock);
    80002272:	8552                	mv	a0,s4
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a5c080e7          	jalr	-1444(ra) # 80000cd0 <release>
            release(&wait_lock);
    8000227c:	0000f517          	auipc	a0,0xf
    80002280:	03c50513          	addi	a0,a0,60 # 800112b8 <wait_lock>
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a4c080e7          	jalr	-1460(ra) # 80000cd0 <release>
            return -1;
    8000228c:	59fd                	li	s3,-1
    8000228e:	a881                	j	800022de <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002290:	44048493          	addi	s1,s1,1088
    80002294:	03348863          	beq	s1,s3,800022c4 <wait+0xf0>
      if(np->parent == p){
    80002298:	3104b783          	ld	a5,784(s1)
    8000229c:	ff279ae3          	bne	a5,s2,80002290 <wait+0xbc>
        acquire(&np->lock);
    800022a0:	2d848a13          	addi	s4,s1,728
    800022a4:	8552                	mv	a0,s4
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	976080e7          	jalr	-1674(ra) # 80000c1c <acquire>
        if(np->state == ZOMBIE){
    800022ae:	2f04a783          	lw	a5,752(s1)
    800022b2:	f7578de3          	beq	a5,s5,8000222c <wait+0x58>
        release(&np->lock);
    800022b6:	8552                	mv	a0,s4
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	a18080e7          	jalr	-1512(ra) # 80000cd0 <release>
        havekids = 1;
    800022c0:	875a                	mv	a4,s6
    800022c2:	b7f9                	j	80002290 <wait+0xbc>
    if(!havekids || p->killed){
    800022c4:	c701                	beqz	a4,800022cc <wait+0xf8>
    800022c6:	30092783          	lw	a5,768(s2)
    800022ca:	cb85                	beqz	a5,800022fa <wait+0x126>
      release(&wait_lock);
    800022cc:	0000f517          	auipc	a0,0xf
    800022d0:	fec50513          	addi	a0,a0,-20 # 800112b8 <wait_lock>
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9fc080e7          	jalr	-1540(ra) # 80000cd0 <release>
      return -1;
    800022dc:	59fd                	li	s3,-1
}
    800022de:	854e                	mv	a0,s3
    800022e0:	60e6                	ld	ra,88(sp)
    800022e2:	6446                	ld	s0,80(sp)
    800022e4:	64a6                	ld	s1,72(sp)
    800022e6:	6906                	ld	s2,64(sp)
    800022e8:	79e2                	ld	s3,56(sp)
    800022ea:	7a42                	ld	s4,48(sp)
    800022ec:	7aa2                	ld	s5,40(sp)
    800022ee:	7b02                	ld	s6,32(sp)
    800022f0:	6be2                	ld	s7,24(sp)
    800022f2:	6c42                	ld	s8,16(sp)
    800022f4:	6ca2                	ld	s9,8(sp)
    800022f6:	6125                	addi	sp,sp,96
    800022f8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022fa:	85e6                	mv	a1,s9
    800022fc:	854a                	mv	a0,s2
    800022fe:	00000097          	auipc	ra,0x0
    80002302:	e66080e7          	jalr	-410(ra) # 80002164 <sleep>
    havekids = 0;
    80002306:	bf29                	j	80002220 <wait+0x4c>

0000000080002308 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002308:	7139                	addi	sp,sp,-64
    8000230a:	fc06                	sd	ra,56(sp)
    8000230c:	f822                	sd	s0,48(sp)
    8000230e:	f426                	sd	s1,40(sp)
    80002310:	f04a                	sd	s2,32(sp)
    80002312:	ec4e                	sd	s3,24(sp)
    80002314:	e852                	sd	s4,16(sp)
    80002316:	e456                	sd	s5,8(sp)
    80002318:	e05a                	sd	s6,0(sp)
    8000231a:	0080                	addi	s0,sp,64
    8000231c:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000231e:	0000f497          	auipc	s1,0xf
    80002322:	3ca48493          	addi	s1,s1,970 # 800116e8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002326:	4a09                	li	s4,2
        p->state = RUNNABLE;
    80002328:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000232a:	00020997          	auipc	s3,0x20
    8000232e:	3be98993          	addi	s3,s3,958 # 800226e8 <mmr_list>
    80002332:	a811                	j	80002346 <wakeup+0x3e>
      }
      release(&p->lock);
    80002334:	854a                	mv	a0,s2
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	99a080e7          	jalr	-1638(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000233e:	44048493          	addi	s1,s1,1088
    80002342:	03348a63          	beq	s1,s3,80002376 <wakeup+0x6e>
    if(p != myproc()){
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	6f0080e7          	jalr	1776(ra) # 80001a36 <myproc>
    8000234e:	fea488e3          	beq	s1,a0,8000233e <wakeup+0x36>
      acquire(&p->lock);
    80002352:	2d848913          	addi	s2,s1,728
    80002356:	854a                	mv	a0,s2
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	8c4080e7          	jalr	-1852(ra) # 80000c1c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002360:	2f04a783          	lw	a5,752(s1)
    80002364:	fd4798e3          	bne	a5,s4,80002334 <wakeup+0x2c>
    80002368:	2f84b783          	ld	a5,760(s1)
    8000236c:	fd5794e3          	bne	a5,s5,80002334 <wakeup+0x2c>
        p->state = RUNNABLE;
    80002370:	2f64a823          	sw	s6,752(s1)
    80002374:	b7c1                	j	80002334 <wakeup+0x2c>
    }
  }
}
    80002376:	70e2                	ld	ra,56(sp)
    80002378:	7442                	ld	s0,48(sp)
    8000237a:	74a2                	ld	s1,40(sp)
    8000237c:	7902                	ld	s2,32(sp)
    8000237e:	69e2                	ld	s3,24(sp)
    80002380:	6a42                	ld	s4,16(sp)
    80002382:	6aa2                	ld	s5,8(sp)
    80002384:	6b02                	ld	s6,0(sp)
    80002386:	6121                	addi	sp,sp,64
    80002388:	8082                	ret

000000008000238a <reparent>:
{
    8000238a:	7179                	addi	sp,sp,-48
    8000238c:	f406                	sd	ra,40(sp)
    8000238e:	f022                	sd	s0,32(sp)
    80002390:	ec26                	sd	s1,24(sp)
    80002392:	e84a                	sd	s2,16(sp)
    80002394:	e44e                	sd	s3,8(sp)
    80002396:	e052                	sd	s4,0(sp)
    80002398:	1800                	addi	s0,sp,48
    8000239a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	34c48493          	addi	s1,s1,844 # 800116e8 <proc>
      pp->parent = initproc;
    800023a4:	00007a17          	auipc	s4,0x7
    800023a8:	c84a0a13          	addi	s4,s4,-892 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ac:	00020997          	auipc	s3,0x20
    800023b0:	33c98993          	addi	s3,s3,828 # 800226e8 <mmr_list>
    800023b4:	a029                	j	800023be <reparent+0x34>
    800023b6:	44048493          	addi	s1,s1,1088
    800023ba:	01348f63          	beq	s1,s3,800023d8 <reparent+0x4e>
    if(pp->parent == p){
    800023be:	3104b783          	ld	a5,784(s1)
    800023c2:	ff279ae3          	bne	a5,s2,800023b6 <reparent+0x2c>
      pp->parent = initproc;
    800023c6:	000a3503          	ld	a0,0(s4)
    800023ca:	30a4b823          	sd	a0,784(s1)
      wakeup(initproc);
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	f3a080e7          	jalr	-198(ra) # 80002308 <wakeup>
    800023d6:	b7c5                	j	800023b6 <reparent+0x2c>
}
    800023d8:	70a2                	ld	ra,40(sp)
    800023da:	7402                	ld	s0,32(sp)
    800023dc:	64e2                	ld	s1,24(sp)
    800023de:	6942                	ld	s2,16(sp)
    800023e0:	69a2                	ld	s3,8(sp)
    800023e2:	6a02                	ld	s4,0(sp)
    800023e4:	6145                	addi	sp,sp,48
    800023e6:	8082                	ret

00000000800023e8 <exit>:
{
    800023e8:	7179                	addi	sp,sp,-48
    800023ea:	f406                	sd	ra,40(sp)
    800023ec:	f022                	sd	s0,32(sp)
    800023ee:	ec26                	sd	s1,24(sp)
    800023f0:	e84a                	sd	s2,16(sp)
    800023f2:	e44e                	sd	s3,8(sp)
    800023f4:	e052                	sd	s4,0(sp)
    800023f6:	1800                	addi	s0,sp,48
    800023f8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	63c080e7          	jalr	1596(ra) # 80001a36 <myproc>
    80002402:	89aa                	mv	s3,a0
  if(p == initproc)
    80002404:	00007797          	auipc	a5,0x7
    80002408:	c247b783          	ld	a5,-988(a5) # 80009028 <initproc>
    8000240c:	3a850493          	addi	s1,a0,936
    80002410:	42850913          	addi	s2,a0,1064
    80002414:	02a79363          	bne	a5,a0,8000243a <exit+0x52>
    panic("init exiting");
    80002418:	00006517          	auipc	a0,0x6
    8000241c:	e0050513          	addi	a0,a0,-512 # 80008218 <digits+0x1d8>
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	11c080e7          	jalr	284(ra) # 8000053c <panic>
      fileclose(f);
    80002428:	00002097          	auipc	ra,0x2
    8000242c:	4f2080e7          	jalr	1266(ra) # 8000491a <fileclose>
      p->ofile[fd] = 0;
    80002430:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002434:	04a1                	addi	s1,s1,8
    80002436:	01248563          	beq	s1,s2,80002440 <exit+0x58>
    if(p->ofile[fd]){
    8000243a:	6088                	ld	a0,0(s1)
    8000243c:	f575                	bnez	a0,80002428 <exit+0x40>
    8000243e:	bfdd                	j	80002434 <exit+0x4c>
  begin_op();
    80002440:	00002097          	auipc	ra,0x2
    80002444:	00e080e7          	jalr	14(ra) # 8000444e <begin_op>
  iput(p->cwd);
    80002448:	4289b503          	ld	a0,1064(s3)
    8000244c:	00001097          	auipc	ra,0x1
    80002450:	7e0080e7          	jalr	2016(ra) # 80003c2c <iput>
  end_op();
    80002454:	00002097          	auipc	ra,0x2
    80002458:	078080e7          	jalr	120(ra) # 800044cc <end_op>
  p->cwd = 0;
    8000245c:	4209b423          	sd	zero,1064(s3)
  acquire(&wait_lock);
    80002460:	0000f497          	auipc	s1,0xf
    80002464:	e5848493          	addi	s1,s1,-424 # 800112b8 <wait_lock>
    80002468:	8526                	mv	a0,s1
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	7b2080e7          	jalr	1970(ra) # 80000c1c <acquire>
  reparent(p);
    80002472:	854e                	mv	a0,s3
    80002474:	00000097          	auipc	ra,0x0
    80002478:	f16080e7          	jalr	-234(ra) # 8000238a <reparent>
  wakeup(p->parent);
    8000247c:	3109b503          	ld	a0,784(s3)
    80002480:	00000097          	auipc	ra,0x0
    80002484:	e88080e7          	jalr	-376(ra) # 80002308 <wakeup>
  acquire(&p->lock);
    80002488:	2d898513          	addi	a0,s3,728
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	790080e7          	jalr	1936(ra) # 80000c1c <acquire>
  p->xstate = status;
    80002494:	3149a223          	sw	s4,772(s3)
  p->state = ZOMBIE;
    80002498:	4795                	li	a5,5
    8000249a:	2ef9a823          	sw	a5,752(s3)
  release(&wait_lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	830080e7          	jalr	-2000(ra) # 80000cd0 <release>
  sched();
    800024a8:	00000097          	auipc	ra,0x0
    800024ac:	b98080e7          	jalr	-1128(ra) # 80002040 <sched>
  panic("zombie exit");
    800024b0:	00006517          	auipc	a0,0x6
    800024b4:	d7850513          	addi	a0,a0,-648 # 80008228 <digits+0x1e8>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	084080e7          	jalr	132(ra) # 8000053c <panic>

00000000800024c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	e052                	sd	s4,0(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024d2:	0000f497          	auipc	s1,0xf
    800024d6:	21648493          	addi	s1,s1,534 # 800116e8 <proc>
    800024da:	00020a17          	auipc	s4,0x20
    800024de:	20ea0a13          	addi	s4,s4,526 # 800226e8 <mmr_list>
    acquire(&p->lock);
    800024e2:	2d848913          	addi	s2,s1,728
    800024e6:	854a                	mv	a0,s2
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	734080e7          	jalr	1844(ra) # 80000c1c <acquire>
    if(p->pid == pid){
    800024f0:	3084a783          	lw	a5,776(s1)
    800024f4:	01378d63          	beq	a5,s3,8000250e <kill+0x4e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024f8:	854a                	mv	a0,s2
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	7d6080e7          	jalr	2006(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002502:	44048493          	addi	s1,s1,1088
    80002506:	fd449ee3          	bne	s1,s4,800024e2 <kill+0x22>
  }
  return -1;
    8000250a:	557d                	li	a0,-1
    8000250c:	a839                	j	8000252a <kill+0x6a>
      p->killed = 1;
    8000250e:	4785                	li	a5,1
    80002510:	30f4a023          	sw	a5,768(s1)
      if(p->state == SLEEPING){
    80002514:	2f04a703          	lw	a4,752(s1)
    80002518:	4789                	li	a5,2
    8000251a:	02f70063          	beq	a4,a5,8000253a <kill+0x7a>
      release(&p->lock);
    8000251e:	854a                	mv	a0,s2
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	7b0080e7          	jalr	1968(ra) # 80000cd0 <release>
      return 0;
    80002528:	4501                	li	a0,0
}
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6a02                	ld	s4,0(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
        p->state = RUNNABLE;
    8000253a:	478d                	li	a5,3
    8000253c:	2ef4a823          	sw	a5,752(s1)
    80002540:	bff9                	j	8000251e <kill+0x5e>

0000000080002542 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002542:	7179                	addi	sp,sp,-48
    80002544:	f406                	sd	ra,40(sp)
    80002546:	f022                	sd	s0,32(sp)
    80002548:	ec26                	sd	s1,24(sp)
    8000254a:	e84a                	sd	s2,16(sp)
    8000254c:	e44e                	sd	s3,8(sp)
    8000254e:	e052                	sd	s4,0(sp)
    80002550:	1800                	addi	s0,sp,48
    80002552:	84aa                	mv	s1,a0
    80002554:	892e                	mv	s2,a1
    80002556:	89b2                	mv	s3,a2
    80002558:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	4dc080e7          	jalr	1244(ra) # 80001a36 <myproc>
  if(user_dst){
    80002562:	c095                	beqz	s1,80002586 <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    80002564:	86d2                	mv	a3,s4
    80002566:	864e                	mv	a2,s3
    80002568:	85ca                	mv	a1,s2
    8000256a:	32853503          	ld	a0,808(a0)
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	10e080e7          	jalr	270(ra) # 8000167c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002576:	70a2                	ld	ra,40(sp)
    80002578:	7402                	ld	s0,32(sp)
    8000257a:	64e2                	ld	s1,24(sp)
    8000257c:	6942                	ld	s2,16(sp)
    8000257e:	69a2                	ld	s3,8(sp)
    80002580:	6a02                	ld	s4,0(sp)
    80002582:	6145                	addi	sp,sp,48
    80002584:	8082                	ret
    memmove((char *)dst, src, len);
    80002586:	000a061b          	sext.w	a2,s4
    8000258a:	85ce                	mv	a1,s3
    8000258c:	854a                	mv	a0,s2
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	7e6080e7          	jalr	2022(ra) # 80000d74 <memmove>
    return 0;
    80002596:	8526                	mv	a0,s1
    80002598:	bff9                	j	80002576 <either_copyout+0x34>

000000008000259a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000259a:	7179                	addi	sp,sp,-48
    8000259c:	f406                	sd	ra,40(sp)
    8000259e:	f022                	sd	s0,32(sp)
    800025a0:	ec26                	sd	s1,24(sp)
    800025a2:	e84a                	sd	s2,16(sp)
    800025a4:	e44e                	sd	s3,8(sp)
    800025a6:	e052                	sd	s4,0(sp)
    800025a8:	1800                	addi	s0,sp,48
    800025aa:	892a                	mv	s2,a0
    800025ac:	84ae                	mv	s1,a1
    800025ae:	89b2                	mv	s3,a2
    800025b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	484080e7          	jalr	1156(ra) # 80001a36 <myproc>
  if(user_src){
    800025ba:	c095                	beqz	s1,800025de <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    800025bc:	86d2                	mv	a3,s4
    800025be:	864e                	mv	a2,s3
    800025c0:	85ca                	mv	a1,s2
    800025c2:	32853503          	ld	a0,808(a0)
    800025c6:	fffff097          	auipc	ra,0xfffff
    800025ca:	142080e7          	jalr	322(ra) # 80001708 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025ce:	70a2                	ld	ra,40(sp)
    800025d0:	7402                	ld	s0,32(sp)
    800025d2:	64e2                	ld	s1,24(sp)
    800025d4:	6942                	ld	s2,16(sp)
    800025d6:	69a2                	ld	s3,8(sp)
    800025d8:	6a02                	ld	s4,0(sp)
    800025da:	6145                	addi	sp,sp,48
    800025dc:	8082                	ret
    memmove(dst, (char*)src, len);
    800025de:	000a061b          	sext.w	a2,s4
    800025e2:	85ce                	mv	a1,s3
    800025e4:	854a                	mv	a0,s2
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	78e080e7          	jalr	1934(ra) # 80000d74 <memmove>
    return 0;
    800025ee:	8526                	mv	a0,s1
    800025f0:	bff9                	j	800025ce <either_copyin+0x34>

00000000800025f2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025f2:	715d                	addi	sp,sp,-80
    800025f4:	e486                	sd	ra,72(sp)
    800025f6:	e0a2                	sd	s0,64(sp)
    800025f8:	fc26                	sd	s1,56(sp)
    800025fa:	f84a                	sd	s2,48(sp)
    800025fc:	f44e                	sd	s3,40(sp)
    800025fe:	f052                	sd	s4,32(sp)
    80002600:	ec56                	sd	s5,24(sp)
    80002602:	e85a                	sd	s6,16(sp)
    80002604:	e45e                	sd	s7,8(sp)
    80002606:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002608:	00006517          	auipc	a0,0x6
    8000260c:	ac050513          	addi	a0,a0,-1344 # 800080c8 <digits+0x88>
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	f76080e7          	jalr	-138(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002618:	0000f497          	auipc	s1,0xf
    8000261c:	50048493          	addi	s1,s1,1280 # 80011b18 <proc+0x430>
    80002620:	00020917          	auipc	s2,0x20
    80002624:	4f890913          	addi	s2,s2,1272 # 80022b18 <mmr_list+0x430>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002628:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000262a:	00006997          	auipc	s3,0x6
    8000262e:	c0e98993          	addi	s3,s3,-1010 # 80008238 <digits+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    80002632:	00006a97          	auipc	s5,0x6
    80002636:	c0ea8a93          	addi	s5,s5,-1010 # 80008240 <digits+0x200>
    printf("\n");
    8000263a:	00006a17          	auipc	s4,0x6
    8000263e:	a8ea0a13          	addi	s4,s4,-1394 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002642:	00006b97          	auipc	s7,0x6
    80002646:	c46b8b93          	addi	s7,s7,-954 # 80008288 <states.0>
    8000264a:	a00d                	j	8000266c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000264c:	ed86a583          	lw	a1,-296(a3)
    80002650:	8556                	mv	a0,s5
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	f34080e7          	jalr	-204(ra) # 80000586 <printf>
    printf("\n");
    8000265a:	8552                	mv	a0,s4
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	f2a080e7          	jalr	-214(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002664:	44048493          	addi	s1,s1,1088
    80002668:	03248263          	beq	s1,s2,8000268c <procdump+0x9a>
    if(p->state == UNUSED)
    8000266c:	86a6                	mv	a3,s1
    8000266e:	ec04a783          	lw	a5,-320(s1)
    80002672:	dbed                	beqz	a5,80002664 <procdump+0x72>
      state = "???";
    80002674:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002676:	fcfb6be3          	bltu	s6,a5,8000264c <procdump+0x5a>
    8000267a:	02079713          	slli	a4,a5,0x20
    8000267e:	01d75793          	srli	a5,a4,0x1d
    80002682:	97de                	add	a5,a5,s7
    80002684:	6390                	ld	a2,0(a5)
    80002686:	f279                	bnez	a2,8000264c <procdump+0x5a>
      state = "???";
    80002688:	864e                	mv	a2,s3
    8000268a:	b7c9                	j	8000264c <procdump+0x5a>
  }
}
    8000268c:	60a6                	ld	ra,72(sp)
    8000268e:	6406                	ld	s0,64(sp)
    80002690:	74e2                	ld	s1,56(sp)
    80002692:	7942                	ld	s2,48(sp)
    80002694:	79a2                	ld	s3,40(sp)
    80002696:	7a02                	ld	s4,32(sp)
    80002698:	6ae2                	ld	s5,24(sp)
    8000269a:	6b42                	ld	s6,16(sp)
    8000269c:	6ba2                	ld	s7,8(sp)
    8000269e:	6161                	addi	sp,sp,80
    800026a0:	8082                	ret

00000000800026a2 <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    800026a2:	7119                	addi	sp,sp,-128
    800026a4:	fc86                	sd	ra,120(sp)
    800026a6:	f8a2                	sd	s0,112(sp)
    800026a8:	f4a6                	sd	s1,104(sp)
    800026aa:	f0ca                	sd	s2,96(sp)
    800026ac:	ecce                	sd	s3,88(sp)
    800026ae:	e8d2                	sd	s4,80(sp)
    800026b0:	e4d6                	sd	s5,72(sp)
    800026b2:	e0da                	sd	s6,64(sp)
    800026b4:	fc5e                	sd	s7,56(sp)
    800026b6:	0100                	addi	s0,sp,128
    800026b8:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	37c080e7          	jalr	892(ra) # 80001a36 <myproc>
    800026c2:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    800026c4:	0000f917          	auipc	s2,0xf
    800026c8:	45490913          	addi	s2,s2,1108 # 80011b18 <proc+0x430>
    800026cc:	00020a17          	auipc	s4,0x20
    800026d0:	44ca0a13          	addi	s4,s4,1100 # 80022b18 <mmr_list+0x430>
  int nprocs = 0;
    800026d4:	4a81                	li	s5,0
    procinfo.state = p->state;
    procinfo.size = p->sz;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    800026d6:	4b81                	li	s7,0
    800026d8:	fac40493          	addi	s1,s0,-84
    800026dc:	a089                	j	8000271e <procinfo+0x7c>
    800026de:	f8f42c23          	sw	a5,-104(s0)
    for (int i=0; i<16; i++)
    800026e2:	f9c40793          	addi	a5,s0,-100
      procinfo.ppid = 0;
    800026e6:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    800026e8:	00074683          	lbu	a3,0(a4)
    800026ec:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    800026f0:	0705                	addi	a4,a4,1
    800026f2:	0785                	addi	a5,a5,1
    800026f4:	fe979ae3          	bne	a5,s1,800026e8 <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    800026f8:	02800693          	li	a3,40
    800026fc:	f8840613          	addi	a2,s0,-120
    80002700:	85ce                	mv	a1,s3
    80002702:	328b3503          	ld	a0,808(s6)
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	f76080e7          	jalr	-138(ra) # 8000167c <copyout>
    8000270e:	02054d63          	bltz	a0,80002748 <procinfo+0xa6>
      return -1;
    addr += sizeof(procinfo);
    80002712:	02898993          	addi	s3,s3,40
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002716:	44090913          	addi	s2,s2,1088
    8000271a:	03490863          	beq	s2,s4,8000274a <procinfo+0xa8>
    if(p->state == UNUSED)
    8000271e:	ec092783          	lw	a5,-320(s2)
    80002722:	dbf5                	beqz	a5,80002716 <procinfo+0x74>
    nprocs++;
    80002724:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    80002726:	ed892703          	lw	a4,-296(s2)
    8000272a:	f8e42423          	sw	a4,-120(s0)
    procinfo.state = p->state;
    8000272e:	f8f42623          	sw	a5,-116(s0)
    procinfo.size = p->sz;
    80002732:	ef093783          	ld	a5,-272(s2)
    80002736:	f8f43823          	sd	a5,-112(s0)
    if (p->parent)
    8000273a:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    8000273e:	87de                	mv	a5,s7
    if (p->parent)
    80002740:	df59                	beqz	a4,800026de <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    80002742:	30872783          	lw	a5,776(a4)
    80002746:	bf61                	j	800026de <procinfo+0x3c>
      return -1;
    80002748:	5afd                	li	s5,-1
  }
  return nprocs;
}
    8000274a:	8556                	mv	a0,s5
    8000274c:	70e6                	ld	ra,120(sp)
    8000274e:	7446                	ld	s0,112(sp)
    80002750:	74a6                	ld	s1,104(sp)
    80002752:	7906                	ld	s2,96(sp)
    80002754:	69e6                	ld	s3,88(sp)
    80002756:	6a46                	ld	s4,80(sp)
    80002758:	6aa6                	ld	s5,72(sp)
    8000275a:	6b06                	ld	s6,64(sp)
    8000275c:	7be2                	ld	s7,56(sp)
    8000275e:	6109                	addi	sp,sp,128
    80002760:	8082                	ret

0000000080002762 <mmrlistinit>:

// HW5 - Task 1a
// Initialize mmr_list
void
mmrlistinit(void)
{
    80002762:	7179                	addi	sp,sp,-48
    80002764:	f406                	sd	ra,40(sp)
    80002766:	f022                	sd	s0,32(sp)
    80002768:	ec26                	sd	s1,24(sp)
    8000276a:	e84a                	sd	s2,16(sp)
    8000276c:	e44e                	sd	s3,8(sp)
    8000276e:	1800                	addi	s0,sp,48
  struct mmr_list *pmmrlist;
  initlock(&listid_lock,"listid");
    80002770:	00006597          	auipc	a1,0x6
    80002774:	ae058593          	addi	a1,a1,-1312 # 80008250 <digits+0x210>
    80002778:	0000f517          	auipc	a0,0xf
    8000277c:	f5850513          	addi	a0,a0,-168 # 800116d0 <listid_lock>
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	40c080e7          	jalr	1036(ra) # 80000b8c <initlock>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    80002788:	00020497          	auipc	s1,0x20
    8000278c:	f6048493          	addi	s1,s1,-160 # 800226e8 <mmr_list>
    initlock(&pmmrlist->lock, "mmrlist");
    80002790:	00006997          	auipc	s3,0x6
    80002794:	ac898993          	addi	s3,s3,-1336 # 80008258 <digits+0x218>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    80002798:	00025917          	auipc	s2,0x25
    8000279c:	f5090913          	addi	s2,s2,-176 # 800276e8 <tickslock>
    initlock(&pmmrlist->lock, "mmrlist");
    800027a0:	85ce                	mv	a1,s3
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	3e8080e7          	jalr	1000(ra) # 80000b8c <initlock>
    pmmrlist->valid = 0;
    800027ac:	0004ac23          	sw	zero,24(s1)
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    800027b0:	02048493          	addi	s1,s1,32
    800027b4:	ff2496e3          	bne	s1,s2,800027a0 <mmrlistinit+0x3e>
  }
}
    800027b8:	70a2                	ld	ra,40(sp)
    800027ba:	7402                	ld	s0,32(sp)
    800027bc:	64e2                	ld	s1,24(sp)
    800027be:	6942                	ld	s2,16(sp)
    800027c0:	69a2                	ld	s3,8(sp)
    800027c2:	6145                	addi	sp,sp,48
    800027c4:	8082                	ret

00000000800027c6 <get_mmr_list>:

// find the mmr_list for a given listid
struct mmr_list*
get_mmr_list(int listid) {
    800027c6:	1101                	addi	sp,sp,-32
    800027c8:	ec06                	sd	ra,24(sp)
    800027ca:	e822                	sd	s0,16(sp)
    800027cc:	e426                	sd	s1,8(sp)
    800027ce:	1000                	addi	s0,sp,32
    800027d0:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    800027d2:	0000f517          	auipc	a0,0xf
    800027d6:	efe50513          	addi	a0,a0,-258 # 800116d0 <listid_lock>
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	442080e7          	jalr	1090(ra) # 80000c1c <acquire>
  if (listid >=0 && listid < NPROC*MAX_MMR && mmr_list[listid].valid) {
    800027e2:	0004871b          	sext.w	a4,s1
    800027e6:	27f00793          	li	a5,639
    800027ea:	02e7eb63          	bltu	a5,a4,80002820 <get_mmr_list+0x5a>
    800027ee:	00549713          	slli	a4,s1,0x5
    800027f2:	00020797          	auipc	a5,0x20
    800027f6:	ef678793          	addi	a5,a5,-266 # 800226e8 <mmr_list>
    800027fa:	97ba                	add	a5,a5,a4
    800027fc:	4f9c                	lw	a5,24(a5)
    800027fe:	c38d                	beqz	a5,80002820 <get_mmr_list+0x5a>
    release(&listid_lock);
    80002800:	0000f517          	auipc	a0,0xf
    80002804:	ed050513          	addi	a0,a0,-304 # 800116d0 <listid_lock>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	4c8080e7          	jalr	1224(ra) # 80000cd0 <release>
    return(&mmr_list[listid]);
    80002810:	00549513          	slli	a0,s1,0x5
    80002814:	00020797          	auipc	a5,0x20
    80002818:	ed478793          	addi	a5,a5,-300 # 800226e8 <mmr_list>
    8000281c:	953e                	add	a0,a0,a5
    8000281e:	a811                	j	80002832 <get_mmr_list+0x6c>
  }
  else {
    release(&listid_lock);
    80002820:	0000f517          	auipc	a0,0xf
    80002824:	eb050513          	addi	a0,a0,-336 # 800116d0 <listid_lock>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	4a8080e7          	jalr	1192(ra) # 80000cd0 <release>
    return 0;
    80002830:	4501                	li	a0,0
  }
}
    80002832:	60e2                	ld	ra,24(sp)
    80002834:	6442                	ld	s0,16(sp)
    80002836:	64a2                	ld	s1,8(sp)
    80002838:	6105                	addi	sp,sp,32
    8000283a:	8082                	ret

000000008000283c <dealloc_mmr_listid>:

// free up entry in mmr_list array
void
dealloc_mmr_listid(int listid) {
    8000283c:	1101                	addi	sp,sp,-32
    8000283e:	ec06                	sd	ra,24(sp)
    80002840:	e822                	sd	s0,16(sp)
    80002842:	e426                	sd	s1,8(sp)
    80002844:	e04a                	sd	s2,0(sp)
    80002846:	1000                	addi	s0,sp,32
    80002848:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    8000284a:	0000f917          	auipc	s2,0xf
    8000284e:	e8690913          	addi	s2,s2,-378 # 800116d0 <listid_lock>
    80002852:	854a                	mv	a0,s2
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	3c8080e7          	jalr	968(ra) # 80000c1c <acquire>
  mmr_list[listid].valid = 0;
    8000285c:	0496                	slli	s1,s1,0x5
    8000285e:	00020797          	auipc	a5,0x20
    80002862:	e8a78793          	addi	a5,a5,-374 # 800226e8 <mmr_list>
    80002866:	97a6                	add	a5,a5,s1
    80002868:	0007ac23          	sw	zero,24(a5)
  release(&listid_lock);
    8000286c:	854a                	mv	a0,s2
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	462080e7          	jalr	1122(ra) # 80000cd0 <release>
}
    80002876:	60e2                	ld	ra,24(sp)
    80002878:	6442                	ld	s0,16(sp)
    8000287a:	64a2                	ld	s1,8(sp)
    8000287c:	6902                	ld	s2,0(sp)
    8000287e:	6105                	addi	sp,sp,32
    80002880:	8082                	ret

0000000080002882 <alloc_mmr_listid>:

// find an unused entry in the mmr_list array
int
alloc_mmr_listid() {
    80002882:	1101                	addi	sp,sp,-32
    80002884:	ec06                	sd	ra,24(sp)
    80002886:	e822                	sd	s0,16(sp)
    80002888:	e426                	sd	s1,8(sp)
    8000288a:	1000                	addi	s0,sp,32
  acquire(&listid_lock);
    8000288c:	0000f517          	auipc	a0,0xf
    80002890:	e4450513          	addi	a0,a0,-444 # 800116d0 <listid_lock>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	388080e7          	jalr	904(ra) # 80000c1c <acquire>
  int listid = -1;
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    8000289c:	00020797          	auipc	a5,0x20
    800028a0:	e6478793          	addi	a5,a5,-412 # 80022700 <mmr_list+0x18>
    800028a4:	4481                	li	s1,0
    800028a6:	28000693          	li	a3,640
    if (mmr_list[i].valid == 0) {
    800028aa:	4398                	lw	a4,0(a5)
    800028ac:	cb01                	beqz	a4,800028bc <alloc_mmr_listid+0x3a>
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    800028ae:	2485                	addiw	s1,s1,1
    800028b0:	02078793          	addi	a5,a5,32
    800028b4:	fed49be3          	bne	s1,a3,800028aa <alloc_mmr_listid+0x28>
  int listid = -1;
    800028b8:	54fd                	li	s1,-1
    800028ba:	a811                	j	800028ce <alloc_mmr_listid+0x4c>
      mmr_list[i].valid = 1;
    800028bc:	00549713          	slli	a4,s1,0x5
    800028c0:	00020797          	auipc	a5,0x20
    800028c4:	e2878793          	addi	a5,a5,-472 # 800226e8 <mmr_list>
    800028c8:	97ba                	add	a5,a5,a4
    800028ca:	4705                	li	a4,1
    800028cc:	cf98                	sw	a4,24(a5)
      listid = i;
      break;
    }
  }
  release(&listid_lock);
    800028ce:	0000f517          	auipc	a0,0xf
    800028d2:	e0250513          	addi	a0,a0,-510 # 800116d0 <listid_lock>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	3fa080e7          	jalr	1018(ra) # 80000cd0 <release>
  return(listid);
    800028de:	8526                	mv	a0,s1
    800028e0:	60e2                	ld	ra,24(sp)
    800028e2:	6442                	ld	s0,16(sp)
    800028e4:	64a2                	ld	s1,8(sp)
    800028e6:	6105                	addi	sp,sp,32
    800028e8:	8082                	ret

00000000800028ea <swtch>:
    800028ea:	00153023          	sd	ra,0(a0)
    800028ee:	00253423          	sd	sp,8(a0)
    800028f2:	e900                	sd	s0,16(a0)
    800028f4:	ed04                	sd	s1,24(a0)
    800028f6:	03253023          	sd	s2,32(a0)
    800028fa:	03353423          	sd	s3,40(a0)
    800028fe:	03453823          	sd	s4,48(a0)
    80002902:	03553c23          	sd	s5,56(a0)
    80002906:	05653023          	sd	s6,64(a0)
    8000290a:	05753423          	sd	s7,72(a0)
    8000290e:	05853823          	sd	s8,80(a0)
    80002912:	05953c23          	sd	s9,88(a0)
    80002916:	07a53023          	sd	s10,96(a0)
    8000291a:	07b53423          	sd	s11,104(a0)
    8000291e:	0005b083          	ld	ra,0(a1)
    80002922:	0085b103          	ld	sp,8(a1)
    80002926:	6980                	ld	s0,16(a1)
    80002928:	6d84                	ld	s1,24(a1)
    8000292a:	0205b903          	ld	s2,32(a1)
    8000292e:	0285b983          	ld	s3,40(a1)
    80002932:	0305ba03          	ld	s4,48(a1)
    80002936:	0385ba83          	ld	s5,56(a1)
    8000293a:	0405bb03          	ld	s6,64(a1)
    8000293e:	0485bb83          	ld	s7,72(a1)
    80002942:	0505bc03          	ld	s8,80(a1)
    80002946:	0585bc83          	ld	s9,88(a1)
    8000294a:	0605bd03          	ld	s10,96(a1)
    8000294e:	0685bd83          	ld	s11,104(a1)
    80002952:	8082                	ret

0000000080002954 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002954:	1141                	addi	sp,sp,-16
    80002956:	e406                	sd	ra,8(sp)
    80002958:	e022                	sd	s0,0(sp)
    8000295a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000295c:	00006597          	auipc	a1,0x6
    80002960:	95c58593          	addi	a1,a1,-1700 # 800082b8 <states.0+0x30>
    80002964:	00025517          	auipc	a0,0x25
    80002968:	d8450513          	addi	a0,a0,-636 # 800276e8 <tickslock>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	220080e7          	jalr	544(ra) # 80000b8c <initlock>
}
    80002974:	60a2                	ld	ra,8(sp)
    80002976:	6402                	ld	s0,0(sp)
    80002978:	0141                	addi	sp,sp,16
    8000297a:	8082                	ret

000000008000297c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000297c:	1141                	addi	sp,sp,-16
    8000297e:	e422                	sd	s0,8(sp)
    80002980:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002982:	00004797          	auipc	a5,0x4
    80002986:	88e78793          	addi	a5,a5,-1906 # 80006210 <kernelvec>
    8000298a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000298e:	6422                	ld	s0,8(sp)
    80002990:	0141                	addi	sp,sp,16
    80002992:	8082                	ret

0000000080002994 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002994:	1141                	addi	sp,sp,-16
    80002996:	e406                	sd	ra,8(sp)
    80002998:	e022                	sd	s0,0(sp)
    8000299a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000299c:	fffff097          	auipc	ra,0xfffff
    800029a0:	09a080e7          	jalr	154(ra) # 80001a36 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029a8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029aa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ae:	00004697          	auipc	a3,0x4
    800029b2:	65268693          	addi	a3,a3,1618 # 80007000 <_trampoline>
    800029b6:	00004717          	auipc	a4,0x4
    800029ba:	64a70713          	addi	a4,a4,1610 # 80007000 <_trampoline>
    800029be:	8f15                	sub	a4,a4,a3
    800029c0:	040007b7          	lui	a5,0x4000
    800029c4:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029c6:	07b2                	slli	a5,a5,0xc
    800029c8:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ca:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029ce:	33053703          	ld	a4,816(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029d2:	18002673          	csrr	a2,satp
    800029d6:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029d8:	33053603          	ld	a2,816(a0)
    800029dc:	31853703          	ld	a4,792(a0)
    800029e0:	6585                	lui	a1,0x1
    800029e2:	972e                	add	a4,a4,a1
    800029e4:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029e6:	33053703          	ld	a4,816(a0)
    800029ea:	00000617          	auipc	a2,0x0
    800029ee:	13e60613          	addi	a2,a2,318 # 80002b28 <usertrap>
    800029f2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029f4:	33053703          	ld	a4,816(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029f8:	8612                	mv	a2,tp
    800029fa:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fc:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a00:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a04:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a08:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a0c:	33053703          	ld	a4,816(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a10:	6f18                	ld	a4,24(a4)
    80002a12:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a16:	32853583          	ld	a1,808(a0)
    80002a1a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a1c:	00004717          	auipc	a4,0x4
    80002a20:	67470713          	addi	a4,a4,1652 # 80007090 <userret>
    80002a24:	8f15                	sub	a4,a4,a3
    80002a26:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a28:	577d                	li	a4,-1
    80002a2a:	177e                	slli	a4,a4,0x3f
    80002a2c:	8dd9                	or	a1,a1,a4
    80002a2e:	02000537          	lui	a0,0x2000
    80002a32:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a34:	0536                	slli	a0,a0,0xd
    80002a36:	9782                	jalr	a5
}
    80002a38:	60a2                	ld	ra,8(sp)
    80002a3a:	6402                	ld	s0,0(sp)
    80002a3c:	0141                	addi	sp,sp,16
    80002a3e:	8082                	ret

0000000080002a40 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4a:	00025497          	auipc	s1,0x25
    80002a4e:	c9e48493          	addi	s1,s1,-866 # 800276e8 <tickslock>
    80002a52:	8526                	mv	a0,s1
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	1c8080e7          	jalr	456(ra) # 80000c1c <acquire>
  ticks++;
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	5d450513          	addi	a0,a0,1492 # 80009030 <ticks>
    80002a64:	411c                	lw	a5,0(a0)
    80002a66:	2785                	addiw	a5,a5,1
    80002a68:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	89e080e7          	jalr	-1890(ra) # 80002308 <wakeup>
  release(&tickslock);
    80002a72:	8526                	mv	a0,s1
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	25c080e7          	jalr	604(ra) # 80000cd0 <release>
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6105                	addi	sp,sp,32
    80002a84:	8082                	ret

0000000080002a86 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a86:	1101                	addi	sp,sp,-32
    80002a88:	ec06                	sd	ra,24(sp)
    80002a8a:	e822                	sd	s0,16(sp)
    80002a8c:	e426                	sd	s1,8(sp)
    80002a8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a90:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a94:	00074d63          	bltz	a4,80002aae <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a98:	57fd                	li	a5,-1
    80002a9a:	17fe                	slli	a5,a5,0x3f
    80002a9c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a9e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa0:	06f70363          	beq	a4,a5,80002b06 <devintr+0x80>
  }
    80002aa4:	60e2                	ld	ra,24(sp)
    80002aa6:	6442                	ld	s0,16(sp)
    80002aa8:	64a2                	ld	s1,8(sp)
    80002aaa:	6105                	addi	sp,sp,32
    80002aac:	8082                	ret
     (scause & 0xff) == 9){
    80002aae:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002ab2:	46a5                	li	a3,9
    80002ab4:	fed792e3          	bne	a5,a3,80002a98 <devintr+0x12>
    int irq = plic_claim();
    80002ab8:	00004097          	auipc	ra,0x4
    80002abc:	860080e7          	jalr	-1952(ra) # 80006318 <plic_claim>
    80002ac0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac2:	47a9                	li	a5,10
    80002ac4:	02f50763          	beq	a0,a5,80002af2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ac8:	4785                	li	a5,1
    80002aca:	02f50963          	beq	a0,a5,80002afc <devintr+0x76>
    return 1;
    80002ace:	4505                	li	a0,1
    } else if(irq){
    80002ad0:	d8f1                	beqz	s1,80002aa4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad2:	85a6                	mv	a1,s1
    80002ad4:	00005517          	auipc	a0,0x5
    80002ad8:	7ec50513          	addi	a0,a0,2028 # 800082c0 <states.0+0x38>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	aaa080e7          	jalr	-1366(ra) # 80000586 <printf>
      plic_complete(irq);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	00004097          	auipc	ra,0x4
    80002aea:	856080e7          	jalr	-1962(ra) # 8000633c <plic_complete>
    return 1;
    80002aee:	4505                	li	a0,1
    80002af0:	bf55                	j	80002aa4 <devintr+0x1e>
      uartintr();
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	ea2080e7          	jalr	-350(ra) # 80000994 <uartintr>
    80002afa:	b7ed                	j	80002ae4 <devintr+0x5e>
      virtio_disk_intr();
    80002afc:	00004097          	auipc	ra,0x4
    80002b00:	ccc080e7          	jalr	-820(ra) # 800067c8 <virtio_disk_intr>
    80002b04:	b7c5                	j	80002ae4 <devintr+0x5e>
    if(cpuid() == 0){
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	f04080e7          	jalr	-252(ra) # 80001a0a <cpuid>
    80002b0e:	c901                	beqz	a0,80002b1e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b10:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b16:	14479073          	csrw	sip,a5
    return 2;
    80002b1a:	4509                	li	a0,2
    80002b1c:	b761                	j	80002aa4 <devintr+0x1e>
      clockintr();
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	f22080e7          	jalr	-222(ra) # 80002a40 <clockintr>
    80002b26:	b7ed                	j	80002b10 <devintr+0x8a>

0000000080002b28 <usertrap>:
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	e04a                	sd	s2,0(sp)
    80002b32:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b34:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b38:	1007f793          	andi	a5,a5,256
    80002b3c:	e7b5                	bnez	a5,80002ba8 <usertrap+0x80>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3e:	00003797          	auipc	a5,0x3
    80002b42:	6d278793          	addi	a5,a5,1746 # 80006210 <kernelvec>
    80002b46:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	eec080e7          	jalr	-276(ra) # 80001a36 <myproc>
    80002b52:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b54:	33053783          	ld	a5,816(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	14102773          	csrr	a4,sepc
    80002b5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b62:	47a1                	li	a5,8
    80002b64:	06f71063          	bne	a4,a5,80002bc4 <usertrap+0x9c>
    if(p->killed)
    80002b68:	30052783          	lw	a5,768(a0)
    80002b6c:	e7b1                	bnez	a5,80002bb8 <usertrap+0x90>
    p->trapframe->epc += 4;
    80002b6e:	3304b703          	ld	a4,816(s1)
    80002b72:	6f1c                	ld	a5,24(a4)
    80002b74:	0791                	addi	a5,a5,4
    80002b76:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b78:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b7c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b80:	10079073          	csrw	sstatus,a5
    syscall();
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	396080e7          	jalr	918(ra) # 80002f1a <syscall>
  if(p->killed)
    80002b8c:	3004a783          	lw	a5,768(s1)
    80002b90:	12079863          	bnez	a5,80002cc0 <usertrap+0x198>
  usertrapret();
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	e00080e7          	jalr	-512(ra) # 80002994 <usertrapret>
}
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6902                	ld	s2,0(sp)
    80002ba4:	6105                	addi	sp,sp,32
    80002ba6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ba8:	00005517          	auipc	a0,0x5
    80002bac:	73850513          	addi	a0,a0,1848 # 800082e0 <states.0+0x58>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	98c080e7          	jalr	-1652(ra) # 8000053c <panic>
      exit(-1);
    80002bb8:	557d                	li	a0,-1
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	82e080e7          	jalr	-2002(ra) # 800023e8 <exit>
    80002bc2:	b775                	j	80002b6e <usertrap+0x46>
  } else if((which_dev = devintr()) != 0){
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	ec2080e7          	jalr	-318(ra) # 80002a86 <devintr>
    80002bcc:	892a                	mv	s2,a0
    80002bce:	e56d                	bnez	a0,80002cb8 <usertrap+0x190>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd0:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    80002bd4:	47b5                	li	a5,13
    80002bd6:	00f70763          	beq	a4,a5,80002be4 <usertrap+0xbc>
    80002bda:	14202773          	csrr	a4,scause
    80002bde:	47bd                	li	a5,15
    80002be0:	0af71363          	bne	a4,a5,80002c86 <usertrap+0x15e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002be4:	143027f3          	csrr	a5,stval
  if (r_stval() < p->sz){
    80002be8:	3204b703          	ld	a4,800(s1)
    80002bec:	06e7f163          	bgeu	a5,a4,80002c4e <usertrap+0x126>
    char* physical_frame = kalloc();
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	ef2080e7          	jalr	-270(ra) # 80000ae2 <kalloc>
    80002bf8:	892a                	mv	s2,a0
    if(physical_frame == 0){
    80002bfa:	c50d                	beqz	a0,80002c24 <usertrap+0xfc>
        memset((void*)physical_frame, 0, PGSIZE);
    80002bfc:	6605                	lui	a2,0x1
    80002bfe:	4581                	li	a1,0
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	118080e7          	jalr	280(ra) # 80000d18 <memset>
    80002c08:	143025f3          	csrr	a1,stval
        mappages(p->pagetable, PGROUNDDOWN(r_stval()), PGSIZE, (uint64)physical_frame, (PTE_R | PTE_W | PTE_X | PTE_U));
    80002c0c:	4779                	li	a4,30
    80002c0e:	86ca                	mv	a3,s2
    80002c10:	6605                	lui	a2,0x1
    80002c12:	77fd                	lui	a5,0xfffff
    80002c14:	8dfd                	and	a1,a1,a5
    80002c16:	3284b503          	ld	a0,808(s1)
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	4c6080e7          	jalr	1222(ra) # 800010e0 <mappages>
    80002c22:	b7ad                	j	80002b8c <usertrap+0x64>
    80002c24:	14302673          	csrr	a2,stval
      printf("usertrap(): out of memory, pid=%d, fault_address=%p\n", p->pid, r_stval());
    80002c28:	3084a583          	lw	a1,776(s1)
    80002c2c:	00005517          	auipc	a0,0x5
    80002c30:	6d450513          	addi	a0,a0,1748 # 80008300 <states.0+0x78>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	952080e7          	jalr	-1710(ra) # 80000586 <printf>
      p->killed = 1;
    80002c3c:	4785                	li	a5,1
    80002c3e:	30f4a023          	sw	a5,768(s1)
      exit(-1);
    80002c42:	557d                	li	a0,-1
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	7a4080e7          	jalr	1956(ra) # 800023e8 <exit>
    80002c4c:	b781                	j	80002b8c <usertrap+0x64>
    80002c4e:	14302673          	csrr	a2,stval
      printf("usertrap(): unexpected page fault, pid=%d, fault_address=%p\n", p->pid, r_stval());
    80002c52:	3084a583          	lw	a1,776(s1)
    80002c56:	00005517          	auipc	a0,0x5
    80002c5a:	6e250513          	addi	a0,a0,1762 # 80008338 <states.0+0xb0>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	928080e7          	jalr	-1752(ra) # 80000586 <printf>
    p->killed = 1;
    80002c66:	4785                	li	a5,1
    80002c68:	30f4a023          	sw	a5,768(s1)
    exit(-1);
    80002c6c:	557d                	li	a0,-1
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	77a080e7          	jalr	1914(ra) # 800023e8 <exit>
  if(which_dev == 2)
    80002c76:	4789                	li	a5,2
    80002c78:	f0f91ee3          	bne	s2,a5,80002b94 <usertrap+0x6c>
    yield();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	4a0080e7          	jalr	1184(ra) # 8000211c <yield>
    80002c84:	bf01                	j	80002b94 <usertrap+0x6c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c86:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c8a:	3084a603          	lw	a2,776(s1)
    80002c8e:	00005517          	auipc	a0,0x5
    80002c92:	6ea50513          	addi	a0,a0,1770 # 80008378 <states.0+0xf0>
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	8f0080e7          	jalr	-1808(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c9e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	70250513          	addi	a0,a0,1794 # 800083a8 <states.0+0x120>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	8d8080e7          	jalr	-1832(ra) # 80000586 <printf>
    p->killed = 1;
    80002cb6:	bf45                	j	80002c66 <usertrap+0x13e>
  if(p->killed)
    80002cb8:	3004a783          	lw	a5,768(s1)
    80002cbc:	dfcd                	beqz	a5,80002c76 <usertrap+0x14e>
    80002cbe:	b77d                	j	80002c6c <usertrap+0x144>
    80002cc0:	4901                	li	s2,0
    80002cc2:	b76d                	j	80002c6c <usertrap+0x144>

0000000080002cc4 <kerneltrap>:
{
    80002cc4:	7179                	addi	sp,sp,-48
    80002cc6:	f406                	sd	ra,40(sp)
    80002cc8:	f022                	sd	s0,32(sp)
    80002cca:	ec26                	sd	s1,24(sp)
    80002ccc:	e84a                	sd	s2,16(sp)
    80002cce:	e44e                	sd	s3,8(sp)
    80002cd0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cda:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cde:	1004f793          	andi	a5,s1,256
    80002ce2:	cb85                	beqz	a5,80002d12 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ce4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ce8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cea:	ef85                	bnez	a5,80002d22 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	d9a080e7          	jalr	-614(ra) # 80002a86 <devintr>
    80002cf4:	cd1d                	beqz	a0,80002d32 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cf6:	4789                	li	a5,2
    80002cf8:	06f50a63          	beq	a0,a5,80002d6c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cfc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d00:	10049073          	csrw	sstatus,s1
}
    80002d04:	70a2                	ld	ra,40(sp)
    80002d06:	7402                	ld	s0,32(sp)
    80002d08:	64e2                	ld	s1,24(sp)
    80002d0a:	6942                	ld	s2,16(sp)
    80002d0c:	69a2                	ld	s3,8(sp)
    80002d0e:	6145                	addi	sp,sp,48
    80002d10:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d12:	00005517          	auipc	a0,0x5
    80002d16:	6b650513          	addi	a0,a0,1718 # 800083c8 <states.0+0x140>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	822080e7          	jalr	-2014(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002d22:	00005517          	auipc	a0,0x5
    80002d26:	6ce50513          	addi	a0,a0,1742 # 800083f0 <states.0+0x168>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	812080e7          	jalr	-2030(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002d32:	85ce                	mv	a1,s3
    80002d34:	00005517          	auipc	a0,0x5
    80002d38:	6dc50513          	addi	a0,a0,1756 # 80008410 <states.0+0x188>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	84a080e7          	jalr	-1974(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d44:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d48:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d4c:	00005517          	auipc	a0,0x5
    80002d50:	6d450513          	addi	a0,a0,1748 # 80008420 <states.0+0x198>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	832080e7          	jalr	-1998(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	6dc50513          	addi	a0,a0,1756 # 80008438 <states.0+0x1b0>
    80002d64:	ffffd097          	auipc	ra,0xffffd
    80002d68:	7d8080e7          	jalr	2008(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	cca080e7          	jalr	-822(ra) # 80001a36 <myproc>
    80002d74:	d541                	beqz	a0,80002cfc <kerneltrap+0x38>
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	cc0080e7          	jalr	-832(ra) # 80001a36 <myproc>
    80002d7e:	2f052703          	lw	a4,752(a0)
    80002d82:	4791                	li	a5,4
    80002d84:	f6f71ce3          	bne	a4,a5,80002cfc <kerneltrap+0x38>
    yield();
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	394080e7          	jalr	916(ra) # 8000211c <yield>
    80002d90:	b7b5                	j	80002cfc <kerneltrap+0x38>

0000000080002d92 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	e426                	sd	s1,8(sp)
    80002d9a:	1000                	addi	s0,sp,32
    80002d9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	c98080e7          	jalr	-872(ra) # 80001a36 <myproc>
  switch (n) {
    80002da6:	4795                	li	a5,5
    80002da8:	0497e763          	bltu	a5,s1,80002df6 <argraw+0x64>
    80002dac:	048a                	slli	s1,s1,0x2
    80002dae:	00005717          	auipc	a4,0x5
    80002db2:	6c270713          	addi	a4,a4,1730 # 80008470 <states.0+0x1e8>
    80002db6:	94ba                	add	s1,s1,a4
    80002db8:	409c                	lw	a5,0(s1)
    80002dba:	97ba                	add	a5,a5,a4
    80002dbc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002dbe:	33053783          	ld	a5,816(a0)
    80002dc2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	64a2                	ld	s1,8(sp)
    80002dca:	6105                	addi	sp,sp,32
    80002dcc:	8082                	ret
    return p->trapframe->a1;
    80002dce:	33053783          	ld	a5,816(a0)
    80002dd2:	7fa8                	ld	a0,120(a5)
    80002dd4:	bfc5                	j	80002dc4 <argraw+0x32>
    return p->trapframe->a2;
    80002dd6:	33053783          	ld	a5,816(a0)
    80002dda:	63c8                	ld	a0,128(a5)
    80002ddc:	b7e5                	j	80002dc4 <argraw+0x32>
    return p->trapframe->a3;
    80002dde:	33053783          	ld	a5,816(a0)
    80002de2:	67c8                	ld	a0,136(a5)
    80002de4:	b7c5                	j	80002dc4 <argraw+0x32>
    return p->trapframe->a4;
    80002de6:	33053783          	ld	a5,816(a0)
    80002dea:	6bc8                	ld	a0,144(a5)
    80002dec:	bfe1                	j	80002dc4 <argraw+0x32>
    return p->trapframe->a5;
    80002dee:	33053783          	ld	a5,816(a0)
    80002df2:	6fc8                	ld	a0,152(a5)
    80002df4:	bfc1                	j	80002dc4 <argraw+0x32>
  panic("argraw");
    80002df6:	00005517          	auipc	a0,0x5
    80002dfa:	65250513          	addi	a0,a0,1618 # 80008448 <states.0+0x1c0>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	73e080e7          	jalr	1854(ra) # 8000053c <panic>

0000000080002e06 <fetchaddr>:
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	e04a                	sd	s2,0(sp)
    80002e10:	1000                	addi	s0,sp,32
    80002e12:	84aa                	mv	s1,a0
    80002e14:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	c20080e7          	jalr	-992(ra) # 80001a36 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e1e:	32053783          	ld	a5,800(a0)
    80002e22:	02f4f963          	bgeu	s1,a5,80002e54 <fetchaddr+0x4e>
    80002e26:	00848713          	addi	a4,s1,8
    80002e2a:	02e7e763          	bltu	a5,a4,80002e58 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e2e:	46a1                	li	a3,8
    80002e30:	8626                	mv	a2,s1
    80002e32:	85ca                	mv	a1,s2
    80002e34:	32853503          	ld	a0,808(a0)
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	8d0080e7          	jalr	-1840(ra) # 80001708 <copyin>
    80002e40:	00a03533          	snez	a0,a0
    80002e44:	40a00533          	neg	a0,a0
}
    80002e48:	60e2                	ld	ra,24(sp)
    80002e4a:	6442                	ld	s0,16(sp)
    80002e4c:	64a2                	ld	s1,8(sp)
    80002e4e:	6902                	ld	s2,0(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret
    return -1;
    80002e54:	557d                	li	a0,-1
    80002e56:	bfcd                	j	80002e48 <fetchaddr+0x42>
    80002e58:	557d                	li	a0,-1
    80002e5a:	b7fd                	j	80002e48 <fetchaddr+0x42>

0000000080002e5c <fetchstr>:
{
    80002e5c:	7179                	addi	sp,sp,-48
    80002e5e:	f406                	sd	ra,40(sp)
    80002e60:	f022                	sd	s0,32(sp)
    80002e62:	ec26                	sd	s1,24(sp)
    80002e64:	e84a                	sd	s2,16(sp)
    80002e66:	e44e                	sd	s3,8(sp)
    80002e68:	1800                	addi	s0,sp,48
    80002e6a:	892a                	mv	s2,a0
    80002e6c:	84ae                	mv	s1,a1
    80002e6e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	bc6080e7          	jalr	-1082(ra) # 80001a36 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e78:	86ce                	mv	a3,s3
    80002e7a:	864a                	mv	a2,s2
    80002e7c:	85a6                	mv	a1,s1
    80002e7e:	32853503          	ld	a0,808(a0)
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	914080e7          	jalr	-1772(ra) # 80001796 <copyinstr>
  if(err < 0)
    80002e8a:	00054763          	bltz	a0,80002e98 <fetchstr+0x3c>
  return strlen(buf);
    80002e8e:	8526                	mv	a0,s1
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	004080e7          	jalr	4(ra) # 80000e94 <strlen>
}
    80002e98:	70a2                	ld	ra,40(sp)
    80002e9a:	7402                	ld	s0,32(sp)
    80002e9c:	64e2                	ld	s1,24(sp)
    80002e9e:	6942                	ld	s2,16(sp)
    80002ea0:	69a2                	ld	s3,8(sp)
    80002ea2:	6145                	addi	sp,sp,48
    80002ea4:	8082                	ret

0000000080002ea6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	e426                	sd	s1,8(sp)
    80002eae:	1000                	addi	s0,sp,32
    80002eb0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002eb2:	00000097          	auipc	ra,0x0
    80002eb6:	ee0080e7          	jalr	-288(ra) # 80002d92 <argraw>
    80002eba:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ebc:	4501                	li	a0,0
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	e426                	sd	s1,8(sp)
    80002ed0:	1000                	addi	s0,sp,32
    80002ed2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	ebe080e7          	jalr	-322(ra) # 80002d92 <argraw>
    80002edc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ede:	4501                	li	a0,0
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	64a2                	ld	s1,8(sp)
    80002ee6:	6105                	addi	sp,sp,32
    80002ee8:	8082                	ret

0000000080002eea <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002eea:	1101                	addi	sp,sp,-32
    80002eec:	ec06                	sd	ra,24(sp)
    80002eee:	e822                	sd	s0,16(sp)
    80002ef0:	e426                	sd	s1,8(sp)
    80002ef2:	e04a                	sd	s2,0(sp)
    80002ef4:	1000                	addi	s0,sp,32
    80002ef6:	84ae                	mv	s1,a1
    80002ef8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	e98080e7          	jalr	-360(ra) # 80002d92 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f02:	864a                	mv	a2,s2
    80002f04:	85a6                	mv	a1,s1
    80002f06:	00000097          	auipc	ra,0x0
    80002f0a:	f56080e7          	jalr	-170(ra) # 80002e5c <fetchstr>
}
    80002f0e:	60e2                	ld	ra,24(sp)
    80002f10:	6442                	ld	s0,16(sp)
    80002f12:	64a2                	ld	s1,8(sp)
    80002f14:	6902                	ld	s2,0(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret

0000000080002f1a <syscall>:
[SYS_munmap] sys_munmap,
};

void
syscall(void)
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	e04a                	sd	s2,0(sp)
    80002f24:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	b10080e7          	jalr	-1264(ra) # 80001a36 <myproc>
    80002f2e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f30:	33053903          	ld	s2,816(a0)
    80002f34:	0a893783          	ld	a5,168(s2)
    80002f38:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f3c:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffc8fff>
    80002f3e:	4761                	li	a4,24
    80002f40:	00f76f63          	bltu	a4,a5,80002f5e <syscall+0x44>
    80002f44:	00369713          	slli	a4,a3,0x3
    80002f48:	00005797          	auipc	a5,0x5
    80002f4c:	54078793          	addi	a5,a5,1344 # 80008488 <syscalls>
    80002f50:	97ba                	add	a5,a5,a4
    80002f52:	639c                	ld	a5,0(a5)
    80002f54:	c789                	beqz	a5,80002f5e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f56:	9782                	jalr	a5
    80002f58:	06a93823          	sd	a0,112(s2)
    80002f5c:	a00d                	j	80002f7e <syscall+0x64>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f5e:	43048613          	addi	a2,s1,1072
    80002f62:	3084a583          	lw	a1,776(s1)
    80002f66:	00005517          	auipc	a0,0x5
    80002f6a:	4ea50513          	addi	a0,a0,1258 # 80008450 <states.0+0x1c8>
    80002f6e:	ffffd097          	auipc	ra,0xffffd
    80002f72:	618080e7          	jalr	1560(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f76:	3304b783          	ld	a5,816(s1)
    80002f7a:	577d                	li	a4,-1
    80002f7c:	fbb8                	sd	a4,112(a5)
  }
}
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	64a2                	ld	s1,8(sp)
    80002f84:	6902                	ld	s2,0(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret

0000000080002f8a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f8a:	1101                	addi	sp,sp,-32
    80002f8c:	ec06                	sd	ra,24(sp)
    80002f8e:	e822                	sd	s0,16(sp)
    80002f90:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f92:	fec40593          	addi	a1,s0,-20
    80002f96:	4501                	li	a0,0
    80002f98:	00000097          	auipc	ra,0x0
    80002f9c:	f0e080e7          	jalr	-242(ra) # 80002ea6 <argint>
    return -1;
    80002fa0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fa2:	00054963          	bltz	a0,80002fb4 <sys_exit+0x2a>
  exit(n);
    80002fa6:	fec42503          	lw	a0,-20(s0)
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	43e080e7          	jalr	1086(ra) # 800023e8 <exit>
  return 0;  // not reached
    80002fb2:	4781                	li	a5,0
}
    80002fb4:	853e                	mv	a0,a5
    80002fb6:	60e2                	ld	ra,24(sp)
    80002fb8:	6442                	ld	s0,16(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret

0000000080002fbe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fbe:	1141                	addi	sp,sp,-16
    80002fc0:	e406                	sd	ra,8(sp)
    80002fc2:	e022                	sd	s0,0(sp)
    80002fc4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	a70080e7          	jalr	-1424(ra) # 80001a36 <myproc>
}
    80002fce:	30852503          	lw	a0,776(a0)
    80002fd2:	60a2                	ld	ra,8(sp)
    80002fd4:	6402                	ld	s0,0(sp)
    80002fd6:	0141                	addi	sp,sp,16
    80002fd8:	8082                	ret

0000000080002fda <sys_fork>:

uint64
sys_fork(void)
{
    80002fda:	1141                	addi	sp,sp,-16
    80002fdc:	e406                	sd	ra,8(sp)
    80002fde:	e022                	sd	s0,0(sp)
    80002fe0:	0800                	addi	s0,sp,16
  return fork();
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	e66080e7          	jalr	-410(ra) # 80001e48 <fork>
}
    80002fea:	60a2                	ld	ra,8(sp)
    80002fec:	6402                	ld	s0,0(sp)
    80002fee:	0141                	addi	sp,sp,16
    80002ff0:	8082                	ret

0000000080002ff2 <sys_wait>:

uint64
sys_wait(void)
{
    80002ff2:	1101                	addi	sp,sp,-32
    80002ff4:	ec06                	sd	ra,24(sp)
    80002ff6:	e822                	sd	s0,16(sp)
    80002ff8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ffa:	fe840593          	addi	a1,s0,-24
    80002ffe:	4501                	li	a0,0
    80003000:	00000097          	auipc	ra,0x0
    80003004:	ec8080e7          	jalr	-312(ra) # 80002ec8 <argaddr>
    80003008:	87aa                	mv	a5,a0
    return -1;
    8000300a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000300c:	0007c863          	bltz	a5,8000301c <sys_wait+0x2a>
  return wait(p);
    80003010:	fe843503          	ld	a0,-24(s0)
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	1c0080e7          	jalr	448(ra) # 800021d4 <wait>
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	6105                	addi	sp,sp,32
    80003022:	8082                	ret

0000000080003024 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003024:	7139                	addi	sp,sp,-64
    80003026:	fc06                	sd	ra,56(sp)
    80003028:	f822                	sd	s0,48(sp)
    8000302a:	f426                	sd	s1,40(sp)
    8000302c:	f04a                	sd	s2,32(sp)
    8000302e:	ec4e                	sd	s3,24(sp)
    80003030:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003032:	fcc40593          	addi	a1,s0,-52
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	e6e080e7          	jalr	-402(ra) # 80002ea6 <argint>
    return -1;
    80003040:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003042:	06054663          	bltz	a0,800030ae <sys_sleep+0x8a>
  acquire(&tickslock);
    80003046:	00024517          	auipc	a0,0x24
    8000304a:	6a250513          	addi	a0,a0,1698 # 800276e8 <tickslock>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	bce080e7          	jalr	-1074(ra) # 80000c1c <acquire>
  ticks0 = ticks;
    80003056:	00006917          	auipc	s2,0x6
    8000305a:	fda92903          	lw	s2,-38(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000305e:	fcc42783          	lw	a5,-52(s0)
    80003062:	cf8d                	beqz	a5,8000309c <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003064:	00024997          	auipc	s3,0x24
    80003068:	68498993          	addi	s3,s3,1668 # 800276e8 <tickslock>
    8000306c:	00006497          	auipc	s1,0x6
    80003070:	fc448493          	addi	s1,s1,-60 # 80009030 <ticks>
    if(myproc()->killed){
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	9c2080e7          	jalr	-1598(ra) # 80001a36 <myproc>
    8000307c:	30052783          	lw	a5,768(a0)
    80003080:	ef9d                	bnez	a5,800030be <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    80003082:	85ce                	mv	a1,s3
    80003084:	8526                	mv	a0,s1
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	0de080e7          	jalr	222(ra) # 80002164 <sleep>
  while(ticks - ticks0 < n){
    8000308e:	409c                	lw	a5,0(s1)
    80003090:	412787bb          	subw	a5,a5,s2
    80003094:	fcc42703          	lw	a4,-52(s0)
    80003098:	fce7eee3          	bltu	a5,a4,80003074 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000309c:	00024517          	auipc	a0,0x24
    800030a0:	64c50513          	addi	a0,a0,1612 # 800276e8 <tickslock>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	c2c080e7          	jalr	-980(ra) # 80000cd0 <release>
  return 0;
    800030ac:	4781                	li	a5,0
}
    800030ae:	853e                	mv	a0,a5
    800030b0:	70e2                	ld	ra,56(sp)
    800030b2:	7442                	ld	s0,48(sp)
    800030b4:	74a2                	ld	s1,40(sp)
    800030b6:	7902                	ld	s2,32(sp)
    800030b8:	69e2                	ld	s3,24(sp)
    800030ba:	6121                	addi	sp,sp,64
    800030bc:	8082                	ret
      release(&tickslock);
    800030be:	00024517          	auipc	a0,0x24
    800030c2:	62a50513          	addi	a0,a0,1578 # 800276e8 <tickslock>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	c0a080e7          	jalr	-1014(ra) # 80000cd0 <release>
      return -1;
    800030ce:	57fd                	li	a5,-1
    800030d0:	bff9                	j	800030ae <sys_sleep+0x8a>

00000000800030d2 <sys_kill>:

uint64
sys_kill(void)
{
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030da:	fec40593          	addi	a1,s0,-20
    800030de:	4501                	li	a0,0
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	dc6080e7          	jalr	-570(ra) # 80002ea6 <argint>
    800030e8:	87aa                	mv	a5,a0
    return -1;
    800030ea:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030ec:	0007c863          	bltz	a5,800030fc <sys_kill+0x2a>
  return kill(pid);
    800030f0:	fec42503          	lw	a0,-20(s0)
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	3cc080e7          	jalr	972(ra) # 800024c0 <kill>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	6105                	addi	sp,sp,32
    80003102:	8082                	ret

0000000080003104 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	e426                	sd	s1,8(sp)
    8000310c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000310e:	00024517          	auipc	a0,0x24
    80003112:	5da50513          	addi	a0,a0,1498 # 800276e8 <tickslock>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b06080e7          	jalr	-1274(ra) # 80000c1c <acquire>
  xticks = ticks;
    8000311e:	00006497          	auipc	s1,0x6
    80003122:	f124a483          	lw	s1,-238(s1) # 80009030 <ticks>
  release(&tickslock);
    80003126:	00024517          	auipc	a0,0x24
    8000312a:	5c250513          	addi	a0,a0,1474 # 800276e8 <tickslock>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	ba2080e7          	jalr	-1118(ra) # 80000cd0 <release>
  return xticks;
}
    80003136:	02049513          	slli	a0,s1,0x20
    8000313a:	9101                	srli	a0,a0,0x20
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6105                	addi	sp,sp,32
    80003144:	8082                	ret

0000000080003146 <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    8000314e:	fe840593          	addi	a1,s0,-24
    80003152:	4501                	li	a0,0
    80003154:	00000097          	auipc	ra,0x0
    80003158:	d74080e7          	jalr	-652(ra) # 80002ec8 <argaddr>
    8000315c:	87aa                	mv	a5,a0
    return -1;
    8000315e:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80003160:	0007c863          	bltz	a5,80003170 <sys_getprocs+0x2a>
  return(procinfo(addr));
    80003164:	fe843503          	ld	a0,-24(s0)
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	53a080e7          	jalr	1338(ra) # 800026a2 <procinfo>
}
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <sys_freepmem>:

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
    80003178:	1141                	addi	sp,sp,-16
    8000317a:	e406                	sd	ra,8(sp)
    8000317c:	e022                	sd	s0,0(sp)
    8000317e:	0800                	addi	s0,sp,16
  int res = freepmem();
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	9c2080e7          	jalr	-1598(ra) # 80000b42 <freepmem>
  return res;
}
    80003188:	2501                	sext.w	a0,a0
    8000318a:	60a2                	ld	ra,8(sp)
    8000318c:	6402                	ld	s0,0(sp)
    8000318e:	0141                	addi	sp,sp,16
    80003190:	8082                	ret

0000000080003192 <sys_sbrk>:

// HW 4 - Task 2
// system call to allocate VIRTUAL memory on the disk
uint64
sys_sbrk(void){
    80003192:	7179                	addi	sp,sp,-48
    80003194:	f406                	sd	ra,40(sp)
    80003196:	f022                	sd	s0,32(sp)
    80003198:	ec26                	sd	s1,24(sp)
    8000319a:	e84a                	sd	s2,16(sp)
    8000319c:	1800                	addi	s0,sp,48
  int new_size;
  int increment;

  // Retrieve the first system call argument, which is the number 
  // of bytes to increase the heap by, and store it in 'increment'
  if(argint(0, &increment) < 0){
    8000319e:	fdc40593          	addi	a1,s0,-36
    800031a2:	4501                	li	a0,0
    800031a4:	00000097          	auipc	ra,0x0
    800031a8:	d02080e7          	jalr	-766(ra) # 80002ea6 <argint>
    800031ac:	87aa                	mv	a5,a0
    return -1;
    800031ae:	557d                	li	a0,-1
  if(argint(0, &increment) < 0){
    800031b0:	0207c363          	bltz	a5,800031d6 <sys_sbrk+0x44>
  }

  // Get the current size of the process's heap from its process structure.]
  curr_size = myproc()->sz;
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	882080e7          	jalr	-1918(ra) # 80001a36 <myproc>
    800031bc:	32052483          	lw	s1,800(a0)

  // Calculate the new size of the heap by adding 'increment' to the current size
  new_size = curr_size + increment;
    800031c0:	fdc42903          	lw	s2,-36(s0)
    800031c4:	0099093b          	addw	s2,s2,s1

  // Check if the new size is below a memory safety threshold ('TRAPFRAME')
  // This is to ensure the heap does not overlap with the trap frame
  if(new_size < TRAPFRAME){
    // If the new size is valid, update the process's heap size to -> new_size
    myproc()->sz = new_size;
    800031c8:	fffff097          	auipc	ra,0xfffff
    800031cc:	86e080e7          	jalr	-1938(ra) # 80001a36 <myproc>
    800031d0:	33253023          	sd	s2,800(a0)
    
    // Return the old heap end address before the increment
    return curr_size;
    800031d4:	8526                	mv	a0,s1
  }

  // If the new size is not valid or exceeds the memory safety threshold
  return -1;
}
    800031d6:	70a2                	ld	ra,40(sp)
    800031d8:	7402                	ld	s0,32(sp)
    800031da:	64e2                	ld	s1,24(sp)
    800031dc:	6942                	ld	s2,16(sp)
    800031de:	6145                	addi	sp,sp,48
    800031e0:	8082                	ret

00000000800031e2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031e2:	7179                	addi	sp,sp,-48
    800031e4:	f406                	sd	ra,40(sp)
    800031e6:	f022                	sd	s0,32(sp)
    800031e8:	ec26                	sd	s1,24(sp)
    800031ea:	e84a                	sd	s2,16(sp)
    800031ec:	e44e                	sd	s3,8(sp)
    800031ee:	e052                	sd	s4,0(sp)
    800031f0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031f2:	00005597          	auipc	a1,0x5
    800031f6:	36658593          	addi	a1,a1,870 # 80008558 <syscalls+0xd0>
    800031fa:	00024517          	auipc	a0,0x24
    800031fe:	50650513          	addi	a0,a0,1286 # 80027700 <bcache>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	98a080e7          	jalr	-1654(ra) # 80000b8c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000320a:	0002c797          	auipc	a5,0x2c
    8000320e:	4f678793          	addi	a5,a5,1270 # 8002f700 <bcache+0x8000>
    80003212:	0002c717          	auipc	a4,0x2c
    80003216:	75670713          	addi	a4,a4,1878 # 8002f968 <bcache+0x8268>
    8000321a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000321e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003222:	00024497          	auipc	s1,0x24
    80003226:	4f648493          	addi	s1,s1,1270 # 80027718 <bcache+0x18>
    b->next = bcache.head.next;
    8000322a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000322c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000322e:	00005a17          	auipc	s4,0x5
    80003232:	332a0a13          	addi	s4,s4,818 # 80008560 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003236:	2b893783          	ld	a5,696(s2)
    8000323a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000323c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003240:	85d2                	mv	a1,s4
    80003242:	01048513          	addi	a0,s1,16
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	4c2080e7          	jalr	1218(ra) # 80004708 <initsleeplock>
    bcache.head.next->prev = b;
    8000324e:	2b893783          	ld	a5,696(s2)
    80003252:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003254:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003258:	45848493          	addi	s1,s1,1112
    8000325c:	fd349de3          	bne	s1,s3,80003236 <binit+0x54>
  }
}
    80003260:	70a2                	ld	ra,40(sp)
    80003262:	7402                	ld	s0,32(sp)
    80003264:	64e2                	ld	s1,24(sp)
    80003266:	6942                	ld	s2,16(sp)
    80003268:	69a2                	ld	s3,8(sp)
    8000326a:	6a02                	ld	s4,0(sp)
    8000326c:	6145                	addi	sp,sp,48
    8000326e:	8082                	ret

0000000080003270 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003270:	7179                	addi	sp,sp,-48
    80003272:	f406                	sd	ra,40(sp)
    80003274:	f022                	sd	s0,32(sp)
    80003276:	ec26                	sd	s1,24(sp)
    80003278:	e84a                	sd	s2,16(sp)
    8000327a:	e44e                	sd	s3,8(sp)
    8000327c:	1800                	addi	s0,sp,48
    8000327e:	892a                	mv	s2,a0
    80003280:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003282:	00024517          	auipc	a0,0x24
    80003286:	47e50513          	addi	a0,a0,1150 # 80027700 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	992080e7          	jalr	-1646(ra) # 80000c1c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003292:	0002c497          	auipc	s1,0x2c
    80003296:	7264b483          	ld	s1,1830(s1) # 8002f9b8 <bcache+0x82b8>
    8000329a:	0002c797          	auipc	a5,0x2c
    8000329e:	6ce78793          	addi	a5,a5,1742 # 8002f968 <bcache+0x8268>
    800032a2:	02f48f63          	beq	s1,a5,800032e0 <bread+0x70>
    800032a6:	873e                	mv	a4,a5
    800032a8:	a021                	j	800032b0 <bread+0x40>
    800032aa:	68a4                	ld	s1,80(s1)
    800032ac:	02e48a63          	beq	s1,a4,800032e0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032b0:	449c                	lw	a5,8(s1)
    800032b2:	ff279ce3          	bne	a5,s2,800032aa <bread+0x3a>
    800032b6:	44dc                	lw	a5,12(s1)
    800032b8:	ff3799e3          	bne	a5,s3,800032aa <bread+0x3a>
      b->refcnt++;
    800032bc:	40bc                	lw	a5,64(s1)
    800032be:	2785                	addiw	a5,a5,1
    800032c0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032c2:	00024517          	auipc	a0,0x24
    800032c6:	43e50513          	addi	a0,a0,1086 # 80027700 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	a06080e7          	jalr	-1530(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    800032d2:	01048513          	addi	a0,s1,16
    800032d6:	00001097          	auipc	ra,0x1
    800032da:	46c080e7          	jalr	1132(ra) # 80004742 <acquiresleep>
      return b;
    800032de:	a8b9                	j	8000333c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032e0:	0002c497          	auipc	s1,0x2c
    800032e4:	6d04b483          	ld	s1,1744(s1) # 8002f9b0 <bcache+0x82b0>
    800032e8:	0002c797          	auipc	a5,0x2c
    800032ec:	68078793          	addi	a5,a5,1664 # 8002f968 <bcache+0x8268>
    800032f0:	00f48863          	beq	s1,a5,80003300 <bread+0x90>
    800032f4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032f6:	40bc                	lw	a5,64(s1)
    800032f8:	cf81                	beqz	a5,80003310 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032fa:	64a4                	ld	s1,72(s1)
    800032fc:	fee49de3          	bne	s1,a4,800032f6 <bread+0x86>
  panic("bget: no buffers");
    80003300:	00005517          	auipc	a0,0x5
    80003304:	26850513          	addi	a0,a0,616 # 80008568 <syscalls+0xe0>
    80003308:	ffffd097          	auipc	ra,0xffffd
    8000330c:	234080e7          	jalr	564(ra) # 8000053c <panic>
      b->dev = dev;
    80003310:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003314:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003318:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000331c:	4785                	li	a5,1
    8000331e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003320:	00024517          	auipc	a0,0x24
    80003324:	3e050513          	addi	a0,a0,992 # 80027700 <bcache>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	9a8080e7          	jalr	-1624(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    80003330:	01048513          	addi	a0,s1,16
    80003334:	00001097          	auipc	ra,0x1
    80003338:	40e080e7          	jalr	1038(ra) # 80004742 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000333c:	409c                	lw	a5,0(s1)
    8000333e:	cb89                	beqz	a5,80003350 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003340:	8526                	mv	a0,s1
    80003342:	70a2                	ld	ra,40(sp)
    80003344:	7402                	ld	s0,32(sp)
    80003346:	64e2                	ld	s1,24(sp)
    80003348:	6942                	ld	s2,16(sp)
    8000334a:	69a2                	ld	s3,8(sp)
    8000334c:	6145                	addi	sp,sp,48
    8000334e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003350:	4581                	li	a1,0
    80003352:	8526                	mv	a0,s1
    80003354:	00003097          	auipc	ra,0x3
    80003358:	1ee080e7          	jalr	494(ra) # 80006542 <virtio_disk_rw>
    b->valid = 1;
    8000335c:	4785                	li	a5,1
    8000335e:	c09c                	sw	a5,0(s1)
  return b;
    80003360:	b7c5                	j	80003340 <bread+0xd0>

0000000080003362 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003362:	1101                	addi	sp,sp,-32
    80003364:	ec06                	sd	ra,24(sp)
    80003366:	e822                	sd	s0,16(sp)
    80003368:	e426                	sd	s1,8(sp)
    8000336a:	1000                	addi	s0,sp,32
    8000336c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000336e:	0541                	addi	a0,a0,16
    80003370:	00001097          	auipc	ra,0x1
    80003374:	46e080e7          	jalr	1134(ra) # 800047de <holdingsleep>
    80003378:	cd01                	beqz	a0,80003390 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000337a:	4585                	li	a1,1
    8000337c:	8526                	mv	a0,s1
    8000337e:	00003097          	auipc	ra,0x3
    80003382:	1c4080e7          	jalr	452(ra) # 80006542 <virtio_disk_rw>
}
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    panic("bwrite");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	1f050513          	addi	a0,a0,496 # 80008580 <syscalls+0xf8>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	1a4080e7          	jalr	420(ra) # 8000053c <panic>

00000000800033a0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	e04a                	sd	s2,0(sp)
    800033aa:	1000                	addi	s0,sp,32
    800033ac:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033ae:	01050913          	addi	s2,a0,16
    800033b2:	854a                	mv	a0,s2
    800033b4:	00001097          	auipc	ra,0x1
    800033b8:	42a080e7          	jalr	1066(ra) # 800047de <holdingsleep>
    800033bc:	c92d                	beqz	a0,8000342e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800033be:	854a                	mv	a0,s2
    800033c0:	00001097          	auipc	ra,0x1
    800033c4:	3da080e7          	jalr	986(ra) # 8000479a <releasesleep>

  acquire(&bcache.lock);
    800033c8:	00024517          	auipc	a0,0x24
    800033cc:	33850513          	addi	a0,a0,824 # 80027700 <bcache>
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	84c080e7          	jalr	-1972(ra) # 80000c1c <acquire>
  b->refcnt--;
    800033d8:	40bc                	lw	a5,64(s1)
    800033da:	37fd                	addiw	a5,a5,-1
    800033dc:	0007871b          	sext.w	a4,a5
    800033e0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033e2:	eb05                	bnez	a4,80003412 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033e4:	68bc                	ld	a5,80(s1)
    800033e6:	64b8                	ld	a4,72(s1)
    800033e8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033ea:	64bc                	ld	a5,72(s1)
    800033ec:	68b8                	ld	a4,80(s1)
    800033ee:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033f0:	0002c797          	auipc	a5,0x2c
    800033f4:	31078793          	addi	a5,a5,784 # 8002f700 <bcache+0x8000>
    800033f8:	2b87b703          	ld	a4,696(a5)
    800033fc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033fe:	0002c717          	auipc	a4,0x2c
    80003402:	56a70713          	addi	a4,a4,1386 # 8002f968 <bcache+0x8268>
    80003406:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003408:	2b87b703          	ld	a4,696(a5)
    8000340c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000340e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003412:	00024517          	auipc	a0,0x24
    80003416:	2ee50513          	addi	a0,a0,750 # 80027700 <bcache>
    8000341a:	ffffe097          	auipc	ra,0xffffe
    8000341e:	8b6080e7          	jalr	-1866(ra) # 80000cd0 <release>
}
    80003422:	60e2                	ld	ra,24(sp)
    80003424:	6442                	ld	s0,16(sp)
    80003426:	64a2                	ld	s1,8(sp)
    80003428:	6902                	ld	s2,0(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret
    panic("brelse");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	15a50513          	addi	a0,a0,346 # 80008588 <syscalls+0x100>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	106080e7          	jalr	262(ra) # 8000053c <panic>

000000008000343e <bpin>:

void
bpin(struct buf *b) {
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	1000                	addi	s0,sp,32
    80003448:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000344a:	00024517          	auipc	a0,0x24
    8000344e:	2b650513          	addi	a0,a0,694 # 80027700 <bcache>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	7ca080e7          	jalr	1994(ra) # 80000c1c <acquire>
  b->refcnt++;
    8000345a:	40bc                	lw	a5,64(s1)
    8000345c:	2785                	addiw	a5,a5,1
    8000345e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003460:	00024517          	auipc	a0,0x24
    80003464:	2a050513          	addi	a0,a0,672 # 80027700 <bcache>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	868080e7          	jalr	-1944(ra) # 80000cd0 <release>
}
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	64a2                	ld	s1,8(sp)
    80003476:	6105                	addi	sp,sp,32
    80003478:	8082                	ret

000000008000347a <bunpin>:

void
bunpin(struct buf *b) {
    8000347a:	1101                	addi	sp,sp,-32
    8000347c:	ec06                	sd	ra,24(sp)
    8000347e:	e822                	sd	s0,16(sp)
    80003480:	e426                	sd	s1,8(sp)
    80003482:	1000                	addi	s0,sp,32
    80003484:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003486:	00024517          	auipc	a0,0x24
    8000348a:	27a50513          	addi	a0,a0,634 # 80027700 <bcache>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	78e080e7          	jalr	1934(ra) # 80000c1c <acquire>
  b->refcnt--;
    80003496:	40bc                	lw	a5,64(s1)
    80003498:	37fd                	addiw	a5,a5,-1
    8000349a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000349c:	00024517          	auipc	a0,0x24
    800034a0:	26450513          	addi	a0,a0,612 # 80027700 <bcache>
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	82c080e7          	jalr	-2004(ra) # 80000cd0 <release>
}
    800034ac:	60e2                	ld	ra,24(sp)
    800034ae:	6442                	ld	s0,16(sp)
    800034b0:	64a2                	ld	s1,8(sp)
    800034b2:	6105                	addi	sp,sp,32
    800034b4:	8082                	ret

00000000800034b6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	e04a                	sd	s2,0(sp)
    800034c0:	1000                	addi	s0,sp,32
    800034c2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034c4:	00d5d59b          	srliw	a1,a1,0xd
    800034c8:	0002d797          	auipc	a5,0x2d
    800034cc:	9147a783          	lw	a5,-1772(a5) # 8002fddc <sb+0x1c>
    800034d0:	9dbd                	addw	a1,a1,a5
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	d9e080e7          	jalr	-610(ra) # 80003270 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034da:	0074f713          	andi	a4,s1,7
    800034de:	4785                	li	a5,1
    800034e0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034e4:	14ce                	slli	s1,s1,0x33
    800034e6:	90d9                	srli	s1,s1,0x36
    800034e8:	00950733          	add	a4,a0,s1
    800034ec:	05874703          	lbu	a4,88(a4)
    800034f0:	00e7f6b3          	and	a3,a5,a4
    800034f4:	c69d                	beqz	a3,80003522 <bfree+0x6c>
    800034f6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034f8:	94aa                	add	s1,s1,a0
    800034fa:	fff7c793          	not	a5,a5
    800034fe:	8f7d                	and	a4,a4,a5
    80003500:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003504:	00001097          	auipc	ra,0x1
    80003508:	120080e7          	jalr	288(ra) # 80004624 <log_write>
  brelse(bp);
    8000350c:	854a                	mv	a0,s2
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	e92080e7          	jalr	-366(ra) # 800033a0 <brelse>
}
    80003516:	60e2                	ld	ra,24(sp)
    80003518:	6442                	ld	s0,16(sp)
    8000351a:	64a2                	ld	s1,8(sp)
    8000351c:	6902                	ld	s2,0(sp)
    8000351e:	6105                	addi	sp,sp,32
    80003520:	8082                	ret
    panic("freeing free block");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	06e50513          	addi	a0,a0,110 # 80008590 <syscalls+0x108>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	012080e7          	jalr	18(ra) # 8000053c <panic>

0000000080003532 <balloc>:
{
    80003532:	711d                	addi	sp,sp,-96
    80003534:	ec86                	sd	ra,88(sp)
    80003536:	e8a2                	sd	s0,80(sp)
    80003538:	e4a6                	sd	s1,72(sp)
    8000353a:	e0ca                	sd	s2,64(sp)
    8000353c:	fc4e                	sd	s3,56(sp)
    8000353e:	f852                	sd	s4,48(sp)
    80003540:	f456                	sd	s5,40(sp)
    80003542:	f05a                	sd	s6,32(sp)
    80003544:	ec5e                	sd	s7,24(sp)
    80003546:	e862                	sd	s8,16(sp)
    80003548:	e466                	sd	s9,8(sp)
    8000354a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000354c:	0002d797          	auipc	a5,0x2d
    80003550:	8787a783          	lw	a5,-1928(a5) # 8002fdc4 <sb+0x4>
    80003554:	cbc1                	beqz	a5,800035e4 <balloc+0xb2>
    80003556:	8baa                	mv	s7,a0
    80003558:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000355a:	0002db17          	auipc	s6,0x2d
    8000355e:	866b0b13          	addi	s6,s6,-1946 # 8002fdc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003562:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003564:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003566:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003568:	6c89                	lui	s9,0x2
    8000356a:	a831                	j	80003586 <balloc+0x54>
    brelse(bp);
    8000356c:	854a                	mv	a0,s2
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	e32080e7          	jalr	-462(ra) # 800033a0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003576:	015c87bb          	addw	a5,s9,s5
    8000357a:	00078a9b          	sext.w	s5,a5
    8000357e:	004b2703          	lw	a4,4(s6)
    80003582:	06eaf163          	bgeu	s5,a4,800035e4 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003586:	41fad79b          	sraiw	a5,s5,0x1f
    8000358a:	0137d79b          	srliw	a5,a5,0x13
    8000358e:	015787bb          	addw	a5,a5,s5
    80003592:	40d7d79b          	sraiw	a5,a5,0xd
    80003596:	01cb2583          	lw	a1,28(s6)
    8000359a:	9dbd                	addw	a1,a1,a5
    8000359c:	855e                	mv	a0,s7
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	cd2080e7          	jalr	-814(ra) # 80003270 <bread>
    800035a6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035a8:	004b2503          	lw	a0,4(s6)
    800035ac:	000a849b          	sext.w	s1,s5
    800035b0:	8762                	mv	a4,s8
    800035b2:	faa4fde3          	bgeu	s1,a0,8000356c <balloc+0x3a>
      m = 1 << (bi % 8);
    800035b6:	00777693          	andi	a3,a4,7
    800035ba:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035be:	41f7579b          	sraiw	a5,a4,0x1f
    800035c2:	01d7d79b          	srliw	a5,a5,0x1d
    800035c6:	9fb9                	addw	a5,a5,a4
    800035c8:	4037d79b          	sraiw	a5,a5,0x3
    800035cc:	00f90633          	add	a2,s2,a5
    800035d0:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800035d4:	00c6f5b3          	and	a1,a3,a2
    800035d8:	cd91                	beqz	a1,800035f4 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035da:	2705                	addiw	a4,a4,1
    800035dc:	2485                	addiw	s1,s1,1
    800035de:	fd471ae3          	bne	a4,s4,800035b2 <balloc+0x80>
    800035e2:	b769                	j	8000356c <balloc+0x3a>
  panic("balloc: out of blocks");
    800035e4:	00005517          	auipc	a0,0x5
    800035e8:	fc450513          	addi	a0,a0,-60 # 800085a8 <syscalls+0x120>
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	f50080e7          	jalr	-176(ra) # 8000053c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035f4:	97ca                	add	a5,a5,s2
    800035f6:	8e55                	or	a2,a2,a3
    800035f8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035fc:	854a                	mv	a0,s2
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	026080e7          	jalr	38(ra) # 80004624 <log_write>
        brelse(bp);
    80003606:	854a                	mv	a0,s2
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	d98080e7          	jalr	-616(ra) # 800033a0 <brelse>
  bp = bread(dev, bno);
    80003610:	85a6                	mv	a1,s1
    80003612:	855e                	mv	a0,s7
    80003614:	00000097          	auipc	ra,0x0
    80003618:	c5c080e7          	jalr	-932(ra) # 80003270 <bread>
    8000361c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000361e:	40000613          	li	a2,1024
    80003622:	4581                	li	a1,0
    80003624:	05850513          	addi	a0,a0,88
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	6f0080e7          	jalr	1776(ra) # 80000d18 <memset>
  log_write(bp);
    80003630:	854a                	mv	a0,s2
    80003632:	00001097          	auipc	ra,0x1
    80003636:	ff2080e7          	jalr	-14(ra) # 80004624 <log_write>
  brelse(bp);
    8000363a:	854a                	mv	a0,s2
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	d64080e7          	jalr	-668(ra) # 800033a0 <brelse>
}
    80003644:	8526                	mv	a0,s1
    80003646:	60e6                	ld	ra,88(sp)
    80003648:	6446                	ld	s0,80(sp)
    8000364a:	64a6                	ld	s1,72(sp)
    8000364c:	6906                	ld	s2,64(sp)
    8000364e:	79e2                	ld	s3,56(sp)
    80003650:	7a42                	ld	s4,48(sp)
    80003652:	7aa2                	ld	s5,40(sp)
    80003654:	7b02                	ld	s6,32(sp)
    80003656:	6be2                	ld	s7,24(sp)
    80003658:	6c42                	ld	s8,16(sp)
    8000365a:	6ca2                	ld	s9,8(sp)
    8000365c:	6125                	addi	sp,sp,96
    8000365e:	8082                	ret

0000000080003660 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003660:	7179                	addi	sp,sp,-48
    80003662:	f406                	sd	ra,40(sp)
    80003664:	f022                	sd	s0,32(sp)
    80003666:	ec26                	sd	s1,24(sp)
    80003668:	e84a                	sd	s2,16(sp)
    8000366a:	e44e                	sd	s3,8(sp)
    8000366c:	e052                	sd	s4,0(sp)
    8000366e:	1800                	addi	s0,sp,48
    80003670:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003672:	47ad                	li	a5,11
    80003674:	04b7fe63          	bgeu	a5,a1,800036d0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003678:	ff45849b          	addiw	s1,a1,-12
    8000367c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003680:	0ff00793          	li	a5,255
    80003684:	0ae7e463          	bltu	a5,a4,8000372c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003688:	08052583          	lw	a1,128(a0)
    8000368c:	c5b5                	beqz	a1,800036f8 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000368e:	00092503          	lw	a0,0(s2)
    80003692:	00000097          	auipc	ra,0x0
    80003696:	bde080e7          	jalr	-1058(ra) # 80003270 <bread>
    8000369a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000369c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036a0:	02049713          	slli	a4,s1,0x20
    800036a4:	01e75593          	srli	a1,a4,0x1e
    800036a8:	00b784b3          	add	s1,a5,a1
    800036ac:	0004a983          	lw	s3,0(s1)
    800036b0:	04098e63          	beqz	s3,8000370c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800036b4:	8552                	mv	a0,s4
    800036b6:	00000097          	auipc	ra,0x0
    800036ba:	cea080e7          	jalr	-790(ra) # 800033a0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036be:	854e                	mv	a0,s3
    800036c0:	70a2                	ld	ra,40(sp)
    800036c2:	7402                	ld	s0,32(sp)
    800036c4:	64e2                	ld	s1,24(sp)
    800036c6:	6942                	ld	s2,16(sp)
    800036c8:	69a2                	ld	s3,8(sp)
    800036ca:	6a02                	ld	s4,0(sp)
    800036cc:	6145                	addi	sp,sp,48
    800036ce:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800036d0:	02059793          	slli	a5,a1,0x20
    800036d4:	01e7d593          	srli	a1,a5,0x1e
    800036d8:	00b504b3          	add	s1,a0,a1
    800036dc:	0504a983          	lw	s3,80(s1)
    800036e0:	fc099fe3          	bnez	s3,800036be <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800036e4:	4108                	lw	a0,0(a0)
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	e4c080e7          	jalr	-436(ra) # 80003532 <balloc>
    800036ee:	0005099b          	sext.w	s3,a0
    800036f2:	0534a823          	sw	s3,80(s1)
    800036f6:	b7e1                	j	800036be <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800036f8:	4108                	lw	a0,0(a0)
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	e38080e7          	jalr	-456(ra) # 80003532 <balloc>
    80003702:	0005059b          	sext.w	a1,a0
    80003706:	08b92023          	sw	a1,128(s2)
    8000370a:	b751                	j	8000368e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000370c:	00092503          	lw	a0,0(s2)
    80003710:	00000097          	auipc	ra,0x0
    80003714:	e22080e7          	jalr	-478(ra) # 80003532 <balloc>
    80003718:	0005099b          	sext.w	s3,a0
    8000371c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003720:	8552                	mv	a0,s4
    80003722:	00001097          	auipc	ra,0x1
    80003726:	f02080e7          	jalr	-254(ra) # 80004624 <log_write>
    8000372a:	b769                	j	800036b4 <bmap+0x54>
  panic("bmap: out of range");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	e9450513          	addi	a0,a0,-364 # 800085c0 <syscalls+0x138>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e08080e7          	jalr	-504(ra) # 8000053c <panic>

000000008000373c <iget>:
{
    8000373c:	7179                	addi	sp,sp,-48
    8000373e:	f406                	sd	ra,40(sp)
    80003740:	f022                	sd	s0,32(sp)
    80003742:	ec26                	sd	s1,24(sp)
    80003744:	e84a                	sd	s2,16(sp)
    80003746:	e44e                	sd	s3,8(sp)
    80003748:	e052                	sd	s4,0(sp)
    8000374a:	1800                	addi	s0,sp,48
    8000374c:	89aa                	mv	s3,a0
    8000374e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003750:	0002c517          	auipc	a0,0x2c
    80003754:	69050513          	addi	a0,a0,1680 # 8002fde0 <itable>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	4c4080e7          	jalr	1220(ra) # 80000c1c <acquire>
  empty = 0;
    80003760:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003762:	0002c497          	auipc	s1,0x2c
    80003766:	69648493          	addi	s1,s1,1686 # 8002fdf8 <itable+0x18>
    8000376a:	0002e697          	auipc	a3,0x2e
    8000376e:	11e68693          	addi	a3,a3,286 # 80031888 <log>
    80003772:	a039                	j	80003780 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003774:	02090b63          	beqz	s2,800037aa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003778:	08848493          	addi	s1,s1,136
    8000377c:	02d48a63          	beq	s1,a3,800037b0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003780:	449c                	lw	a5,8(s1)
    80003782:	fef059e3          	blez	a5,80003774 <iget+0x38>
    80003786:	4098                	lw	a4,0(s1)
    80003788:	ff3716e3          	bne	a4,s3,80003774 <iget+0x38>
    8000378c:	40d8                	lw	a4,4(s1)
    8000378e:	ff4713e3          	bne	a4,s4,80003774 <iget+0x38>
      ip->ref++;
    80003792:	2785                	addiw	a5,a5,1
    80003794:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003796:	0002c517          	auipc	a0,0x2c
    8000379a:	64a50513          	addi	a0,a0,1610 # 8002fde0 <itable>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	532080e7          	jalr	1330(ra) # 80000cd0 <release>
      return ip;
    800037a6:	8926                	mv	s2,s1
    800037a8:	a03d                	j	800037d6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037aa:	f7f9                	bnez	a5,80003778 <iget+0x3c>
    800037ac:	8926                	mv	s2,s1
    800037ae:	b7e9                	j	80003778 <iget+0x3c>
  if(empty == 0)
    800037b0:	02090c63          	beqz	s2,800037e8 <iget+0xac>
  ip->dev = dev;
    800037b4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037b8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037bc:	4785                	li	a5,1
    800037be:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037c2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037c6:	0002c517          	auipc	a0,0x2c
    800037ca:	61a50513          	addi	a0,a0,1562 # 8002fde0 <itable>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	502080e7          	jalr	1282(ra) # 80000cd0 <release>
}
    800037d6:	854a                	mv	a0,s2
    800037d8:	70a2                	ld	ra,40(sp)
    800037da:	7402                	ld	s0,32(sp)
    800037dc:	64e2                	ld	s1,24(sp)
    800037de:	6942                	ld	s2,16(sp)
    800037e0:	69a2                	ld	s3,8(sp)
    800037e2:	6a02                	ld	s4,0(sp)
    800037e4:	6145                	addi	sp,sp,48
    800037e6:	8082                	ret
    panic("iget: no inodes");
    800037e8:	00005517          	auipc	a0,0x5
    800037ec:	df050513          	addi	a0,a0,-528 # 800085d8 <syscalls+0x150>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	d4c080e7          	jalr	-692(ra) # 8000053c <panic>

00000000800037f8 <fsinit>:
fsinit(int dev) {
    800037f8:	7179                	addi	sp,sp,-48
    800037fa:	f406                	sd	ra,40(sp)
    800037fc:	f022                	sd	s0,32(sp)
    800037fe:	ec26                	sd	s1,24(sp)
    80003800:	e84a                	sd	s2,16(sp)
    80003802:	e44e                	sd	s3,8(sp)
    80003804:	1800                	addi	s0,sp,48
    80003806:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003808:	4585                	li	a1,1
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	a66080e7          	jalr	-1434(ra) # 80003270 <bread>
    80003812:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003814:	0002c997          	auipc	s3,0x2c
    80003818:	5ac98993          	addi	s3,s3,1452 # 8002fdc0 <sb>
    8000381c:	02000613          	li	a2,32
    80003820:	05850593          	addi	a1,a0,88
    80003824:	854e                	mv	a0,s3
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	54e080e7          	jalr	1358(ra) # 80000d74 <memmove>
  brelse(bp);
    8000382e:	8526                	mv	a0,s1
    80003830:	00000097          	auipc	ra,0x0
    80003834:	b70080e7          	jalr	-1168(ra) # 800033a0 <brelse>
  if(sb.magic != FSMAGIC)
    80003838:	0009a703          	lw	a4,0(s3)
    8000383c:	102037b7          	lui	a5,0x10203
    80003840:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003844:	02f71263          	bne	a4,a5,80003868 <fsinit+0x70>
  initlog(dev, &sb);
    80003848:	0002c597          	auipc	a1,0x2c
    8000384c:	57858593          	addi	a1,a1,1400 # 8002fdc0 <sb>
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	b56080e7          	jalr	-1194(ra) # 800043a8 <initlog>
}
    8000385a:	70a2                	ld	ra,40(sp)
    8000385c:	7402                	ld	s0,32(sp)
    8000385e:	64e2                	ld	s1,24(sp)
    80003860:	6942                	ld	s2,16(sp)
    80003862:	69a2                	ld	s3,8(sp)
    80003864:	6145                	addi	sp,sp,48
    80003866:	8082                	ret
    panic("invalid file system");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	d8050513          	addi	a0,a0,-640 # 800085e8 <syscalls+0x160>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	ccc080e7          	jalr	-820(ra) # 8000053c <panic>

0000000080003878 <iinit>:
{
    80003878:	7179                	addi	sp,sp,-48
    8000387a:	f406                	sd	ra,40(sp)
    8000387c:	f022                	sd	s0,32(sp)
    8000387e:	ec26                	sd	s1,24(sp)
    80003880:	e84a                	sd	s2,16(sp)
    80003882:	e44e                	sd	s3,8(sp)
    80003884:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003886:	00005597          	auipc	a1,0x5
    8000388a:	d7a58593          	addi	a1,a1,-646 # 80008600 <syscalls+0x178>
    8000388e:	0002c517          	auipc	a0,0x2c
    80003892:	55250513          	addi	a0,a0,1362 # 8002fde0 <itable>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	2f6080e7          	jalr	758(ra) # 80000b8c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000389e:	0002c497          	auipc	s1,0x2c
    800038a2:	56a48493          	addi	s1,s1,1386 # 8002fe08 <itable+0x28>
    800038a6:	0002e997          	auipc	s3,0x2e
    800038aa:	ff298993          	addi	s3,s3,-14 # 80031898 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038ae:	00005917          	auipc	s2,0x5
    800038b2:	d5a90913          	addi	s2,s2,-678 # 80008608 <syscalls+0x180>
    800038b6:	85ca                	mv	a1,s2
    800038b8:	8526                	mv	a0,s1
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	e4e080e7          	jalr	-434(ra) # 80004708 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038c2:	08848493          	addi	s1,s1,136
    800038c6:	ff3498e3          	bne	s1,s3,800038b6 <iinit+0x3e>
}
    800038ca:	70a2                	ld	ra,40(sp)
    800038cc:	7402                	ld	s0,32(sp)
    800038ce:	64e2                	ld	s1,24(sp)
    800038d0:	6942                	ld	s2,16(sp)
    800038d2:	69a2                	ld	s3,8(sp)
    800038d4:	6145                	addi	sp,sp,48
    800038d6:	8082                	ret

00000000800038d8 <ialloc>:
{
    800038d8:	715d                	addi	sp,sp,-80
    800038da:	e486                	sd	ra,72(sp)
    800038dc:	e0a2                	sd	s0,64(sp)
    800038de:	fc26                	sd	s1,56(sp)
    800038e0:	f84a                	sd	s2,48(sp)
    800038e2:	f44e                	sd	s3,40(sp)
    800038e4:	f052                	sd	s4,32(sp)
    800038e6:	ec56                	sd	s5,24(sp)
    800038e8:	e85a                	sd	s6,16(sp)
    800038ea:	e45e                	sd	s7,8(sp)
    800038ec:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ee:	0002c717          	auipc	a4,0x2c
    800038f2:	4de72703          	lw	a4,1246(a4) # 8002fdcc <sb+0xc>
    800038f6:	4785                	li	a5,1
    800038f8:	04e7fa63          	bgeu	a5,a4,8000394c <ialloc+0x74>
    800038fc:	8aaa                	mv	s5,a0
    800038fe:	8bae                	mv	s7,a1
    80003900:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003902:	0002ca17          	auipc	s4,0x2c
    80003906:	4bea0a13          	addi	s4,s4,1214 # 8002fdc0 <sb>
    8000390a:	00048b1b          	sext.w	s6,s1
    8000390e:	0044d593          	srli	a1,s1,0x4
    80003912:	018a2783          	lw	a5,24(s4)
    80003916:	9dbd                	addw	a1,a1,a5
    80003918:	8556                	mv	a0,s5
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	956080e7          	jalr	-1706(ra) # 80003270 <bread>
    80003922:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003924:	05850993          	addi	s3,a0,88
    80003928:	00f4f793          	andi	a5,s1,15
    8000392c:	079a                	slli	a5,a5,0x6
    8000392e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003930:	00099783          	lh	a5,0(s3)
    80003934:	c785                	beqz	a5,8000395c <ialloc+0x84>
    brelse(bp);
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	a6a080e7          	jalr	-1430(ra) # 800033a0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000393e:	0485                	addi	s1,s1,1
    80003940:	00ca2703          	lw	a4,12(s4)
    80003944:	0004879b          	sext.w	a5,s1
    80003948:	fce7e1e3          	bltu	a5,a4,8000390a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000394c:	00005517          	auipc	a0,0x5
    80003950:	cc450513          	addi	a0,a0,-828 # 80008610 <syscalls+0x188>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	be8080e7          	jalr	-1048(ra) # 8000053c <panic>
      memset(dip, 0, sizeof(*dip));
    8000395c:	04000613          	li	a2,64
    80003960:	4581                	li	a1,0
    80003962:	854e                	mv	a0,s3
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	3b4080e7          	jalr	948(ra) # 80000d18 <memset>
      dip->type = type;
    8000396c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003970:	854a                	mv	a0,s2
    80003972:	00001097          	auipc	ra,0x1
    80003976:	cb2080e7          	jalr	-846(ra) # 80004624 <log_write>
      brelse(bp);
    8000397a:	854a                	mv	a0,s2
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	a24080e7          	jalr	-1500(ra) # 800033a0 <brelse>
      return iget(dev, inum);
    80003984:	85da                	mv	a1,s6
    80003986:	8556                	mv	a0,s5
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	db4080e7          	jalr	-588(ra) # 8000373c <iget>
}
    80003990:	60a6                	ld	ra,72(sp)
    80003992:	6406                	ld	s0,64(sp)
    80003994:	74e2                	ld	s1,56(sp)
    80003996:	7942                	ld	s2,48(sp)
    80003998:	79a2                	ld	s3,40(sp)
    8000399a:	7a02                	ld	s4,32(sp)
    8000399c:	6ae2                	ld	s5,24(sp)
    8000399e:	6b42                	ld	s6,16(sp)
    800039a0:	6ba2                	ld	s7,8(sp)
    800039a2:	6161                	addi	sp,sp,80
    800039a4:	8082                	ret

00000000800039a6 <iupdate>:
{
    800039a6:	1101                	addi	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	e426                	sd	s1,8(sp)
    800039ae:	e04a                	sd	s2,0(sp)
    800039b0:	1000                	addi	s0,sp,32
    800039b2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039b4:	415c                	lw	a5,4(a0)
    800039b6:	0047d79b          	srliw	a5,a5,0x4
    800039ba:	0002c597          	auipc	a1,0x2c
    800039be:	41e5a583          	lw	a1,1054(a1) # 8002fdd8 <sb+0x18>
    800039c2:	9dbd                	addw	a1,a1,a5
    800039c4:	4108                	lw	a0,0(a0)
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	8aa080e7          	jalr	-1878(ra) # 80003270 <bread>
    800039ce:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039d0:	05850793          	addi	a5,a0,88
    800039d4:	40d8                	lw	a4,4(s1)
    800039d6:	8b3d                	andi	a4,a4,15
    800039d8:	071a                	slli	a4,a4,0x6
    800039da:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039dc:	04449703          	lh	a4,68(s1)
    800039e0:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039e4:	04649703          	lh	a4,70(s1)
    800039e8:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039ec:	04849703          	lh	a4,72(s1)
    800039f0:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039f4:	04a49703          	lh	a4,74(s1)
    800039f8:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039fc:	44f8                	lw	a4,76(s1)
    800039fe:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a00:	03400613          	li	a2,52
    80003a04:	05048593          	addi	a1,s1,80
    80003a08:	00c78513          	addi	a0,a5,12
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	368080e7          	jalr	872(ra) # 80000d74 <memmove>
  log_write(bp);
    80003a14:	854a                	mv	a0,s2
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	c0e080e7          	jalr	-1010(ra) # 80004624 <log_write>
  brelse(bp);
    80003a1e:	854a                	mv	a0,s2
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	980080e7          	jalr	-1664(ra) # 800033a0 <brelse>
}
    80003a28:	60e2                	ld	ra,24(sp)
    80003a2a:	6442                	ld	s0,16(sp)
    80003a2c:	64a2                	ld	s1,8(sp)
    80003a2e:	6902                	ld	s2,0(sp)
    80003a30:	6105                	addi	sp,sp,32
    80003a32:	8082                	ret

0000000080003a34 <idup>:
{
    80003a34:	1101                	addi	sp,sp,-32
    80003a36:	ec06                	sd	ra,24(sp)
    80003a38:	e822                	sd	s0,16(sp)
    80003a3a:	e426                	sd	s1,8(sp)
    80003a3c:	1000                	addi	s0,sp,32
    80003a3e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a40:	0002c517          	auipc	a0,0x2c
    80003a44:	3a050513          	addi	a0,a0,928 # 8002fde0 <itable>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	1d4080e7          	jalr	468(ra) # 80000c1c <acquire>
  ip->ref++;
    80003a50:	449c                	lw	a5,8(s1)
    80003a52:	2785                	addiw	a5,a5,1
    80003a54:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a56:	0002c517          	auipc	a0,0x2c
    80003a5a:	38a50513          	addi	a0,a0,906 # 8002fde0 <itable>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	272080e7          	jalr	626(ra) # 80000cd0 <release>
}
    80003a66:	8526                	mv	a0,s1
    80003a68:	60e2                	ld	ra,24(sp)
    80003a6a:	6442                	ld	s0,16(sp)
    80003a6c:	64a2                	ld	s1,8(sp)
    80003a6e:	6105                	addi	sp,sp,32
    80003a70:	8082                	ret

0000000080003a72 <ilock>:
{
    80003a72:	1101                	addi	sp,sp,-32
    80003a74:	ec06                	sd	ra,24(sp)
    80003a76:	e822                	sd	s0,16(sp)
    80003a78:	e426                	sd	s1,8(sp)
    80003a7a:	e04a                	sd	s2,0(sp)
    80003a7c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a7e:	c115                	beqz	a0,80003aa2 <ilock+0x30>
    80003a80:	84aa                	mv	s1,a0
    80003a82:	451c                	lw	a5,8(a0)
    80003a84:	00f05f63          	blez	a5,80003aa2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a88:	0541                	addi	a0,a0,16
    80003a8a:	00001097          	auipc	ra,0x1
    80003a8e:	cb8080e7          	jalr	-840(ra) # 80004742 <acquiresleep>
  if(ip->valid == 0){
    80003a92:	40bc                	lw	a5,64(s1)
    80003a94:	cf99                	beqz	a5,80003ab2 <ilock+0x40>
}
    80003a96:	60e2                	ld	ra,24(sp)
    80003a98:	6442                	ld	s0,16(sp)
    80003a9a:	64a2                	ld	s1,8(sp)
    80003a9c:	6902                	ld	s2,0(sp)
    80003a9e:	6105                	addi	sp,sp,32
    80003aa0:	8082                	ret
    panic("ilock");
    80003aa2:	00005517          	auipc	a0,0x5
    80003aa6:	b8650513          	addi	a0,a0,-1146 # 80008628 <syscalls+0x1a0>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	a92080e7          	jalr	-1390(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ab2:	40dc                	lw	a5,4(s1)
    80003ab4:	0047d79b          	srliw	a5,a5,0x4
    80003ab8:	0002c597          	auipc	a1,0x2c
    80003abc:	3205a583          	lw	a1,800(a1) # 8002fdd8 <sb+0x18>
    80003ac0:	9dbd                	addw	a1,a1,a5
    80003ac2:	4088                	lw	a0,0(s1)
    80003ac4:	fffff097          	auipc	ra,0xfffff
    80003ac8:	7ac080e7          	jalr	1964(ra) # 80003270 <bread>
    80003acc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ace:	05850593          	addi	a1,a0,88
    80003ad2:	40dc                	lw	a5,4(s1)
    80003ad4:	8bbd                	andi	a5,a5,15
    80003ad6:	079a                	slli	a5,a5,0x6
    80003ad8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ada:	00059783          	lh	a5,0(a1)
    80003ade:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ae2:	00259783          	lh	a5,2(a1)
    80003ae6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003aea:	00459783          	lh	a5,4(a1)
    80003aee:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003af2:	00659783          	lh	a5,6(a1)
    80003af6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003afa:	459c                	lw	a5,8(a1)
    80003afc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003afe:	03400613          	li	a2,52
    80003b02:	05b1                	addi	a1,a1,12
    80003b04:	05048513          	addi	a0,s1,80
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	26c080e7          	jalr	620(ra) # 80000d74 <memmove>
    brelse(bp);
    80003b10:	854a                	mv	a0,s2
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	88e080e7          	jalr	-1906(ra) # 800033a0 <brelse>
    ip->valid = 1;
    80003b1a:	4785                	li	a5,1
    80003b1c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b1e:	04449783          	lh	a5,68(s1)
    80003b22:	fbb5                	bnez	a5,80003a96 <ilock+0x24>
      panic("ilock: no type");
    80003b24:	00005517          	auipc	a0,0x5
    80003b28:	b0c50513          	addi	a0,a0,-1268 # 80008630 <syscalls+0x1a8>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	a10080e7          	jalr	-1520(ra) # 8000053c <panic>

0000000080003b34 <iunlock>:
{
    80003b34:	1101                	addi	sp,sp,-32
    80003b36:	ec06                	sd	ra,24(sp)
    80003b38:	e822                	sd	s0,16(sp)
    80003b3a:	e426                	sd	s1,8(sp)
    80003b3c:	e04a                	sd	s2,0(sp)
    80003b3e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b40:	c905                	beqz	a0,80003b70 <iunlock+0x3c>
    80003b42:	84aa                	mv	s1,a0
    80003b44:	01050913          	addi	s2,a0,16
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00001097          	auipc	ra,0x1
    80003b4e:	c94080e7          	jalr	-876(ra) # 800047de <holdingsleep>
    80003b52:	cd19                	beqz	a0,80003b70 <iunlock+0x3c>
    80003b54:	449c                	lw	a5,8(s1)
    80003b56:	00f05d63          	blez	a5,80003b70 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	00001097          	auipc	ra,0x1
    80003b60:	c3e080e7          	jalr	-962(ra) # 8000479a <releasesleep>
}
    80003b64:	60e2                	ld	ra,24(sp)
    80003b66:	6442                	ld	s0,16(sp)
    80003b68:	64a2                	ld	s1,8(sp)
    80003b6a:	6902                	ld	s2,0(sp)
    80003b6c:	6105                	addi	sp,sp,32
    80003b6e:	8082                	ret
    panic("iunlock");
    80003b70:	00005517          	auipc	a0,0x5
    80003b74:	ad050513          	addi	a0,a0,-1328 # 80008640 <syscalls+0x1b8>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	9c4080e7          	jalr	-1596(ra) # 8000053c <panic>

0000000080003b80 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b80:	7179                	addi	sp,sp,-48
    80003b82:	f406                	sd	ra,40(sp)
    80003b84:	f022                	sd	s0,32(sp)
    80003b86:	ec26                	sd	s1,24(sp)
    80003b88:	e84a                	sd	s2,16(sp)
    80003b8a:	e44e                	sd	s3,8(sp)
    80003b8c:	e052                	sd	s4,0(sp)
    80003b8e:	1800                	addi	s0,sp,48
    80003b90:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b92:	05050493          	addi	s1,a0,80
    80003b96:	08050913          	addi	s2,a0,128
    80003b9a:	a021                	j	80003ba2 <itrunc+0x22>
    80003b9c:	0491                	addi	s1,s1,4
    80003b9e:	01248d63          	beq	s1,s2,80003bb8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ba2:	408c                	lw	a1,0(s1)
    80003ba4:	dde5                	beqz	a1,80003b9c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ba6:	0009a503          	lw	a0,0(s3)
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	90c080e7          	jalr	-1780(ra) # 800034b6 <bfree>
      ip->addrs[i] = 0;
    80003bb2:	0004a023          	sw	zero,0(s1)
    80003bb6:	b7dd                	j	80003b9c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003bb8:	0809a583          	lw	a1,128(s3)
    80003bbc:	e185                	bnez	a1,80003bdc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bbe:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003bc2:	854e                	mv	a0,s3
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	de2080e7          	jalr	-542(ra) # 800039a6 <iupdate>
}
    80003bcc:	70a2                	ld	ra,40(sp)
    80003bce:	7402                	ld	s0,32(sp)
    80003bd0:	64e2                	ld	s1,24(sp)
    80003bd2:	6942                	ld	s2,16(sp)
    80003bd4:	69a2                	ld	s3,8(sp)
    80003bd6:	6a02                	ld	s4,0(sp)
    80003bd8:	6145                	addi	sp,sp,48
    80003bda:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bdc:	0009a503          	lw	a0,0(s3)
    80003be0:	fffff097          	auipc	ra,0xfffff
    80003be4:	690080e7          	jalr	1680(ra) # 80003270 <bread>
    80003be8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bea:	05850493          	addi	s1,a0,88
    80003bee:	45850913          	addi	s2,a0,1112
    80003bf2:	a021                	j	80003bfa <itrunc+0x7a>
    80003bf4:	0491                	addi	s1,s1,4
    80003bf6:	01248b63          	beq	s1,s2,80003c0c <itrunc+0x8c>
      if(a[j])
    80003bfa:	408c                	lw	a1,0(s1)
    80003bfc:	dde5                	beqz	a1,80003bf4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bfe:	0009a503          	lw	a0,0(s3)
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	8b4080e7          	jalr	-1868(ra) # 800034b6 <bfree>
    80003c0a:	b7ed                	j	80003bf4 <itrunc+0x74>
    brelse(bp);
    80003c0c:	8552                	mv	a0,s4
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	792080e7          	jalr	1938(ra) # 800033a0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c16:	0809a583          	lw	a1,128(s3)
    80003c1a:	0009a503          	lw	a0,0(s3)
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	898080e7          	jalr	-1896(ra) # 800034b6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c26:	0809a023          	sw	zero,128(s3)
    80003c2a:	bf51                	j	80003bbe <itrunc+0x3e>

0000000080003c2c <iput>:
{
    80003c2c:	1101                	addi	sp,sp,-32
    80003c2e:	ec06                	sd	ra,24(sp)
    80003c30:	e822                	sd	s0,16(sp)
    80003c32:	e426                	sd	s1,8(sp)
    80003c34:	e04a                	sd	s2,0(sp)
    80003c36:	1000                	addi	s0,sp,32
    80003c38:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c3a:	0002c517          	auipc	a0,0x2c
    80003c3e:	1a650513          	addi	a0,a0,422 # 8002fde0 <itable>
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	fda080e7          	jalr	-38(ra) # 80000c1c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c4a:	4498                	lw	a4,8(s1)
    80003c4c:	4785                	li	a5,1
    80003c4e:	02f70363          	beq	a4,a5,80003c74 <iput+0x48>
  ip->ref--;
    80003c52:	449c                	lw	a5,8(s1)
    80003c54:	37fd                	addiw	a5,a5,-1
    80003c56:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c58:	0002c517          	auipc	a0,0x2c
    80003c5c:	18850513          	addi	a0,a0,392 # 8002fde0 <itable>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	070080e7          	jalr	112(ra) # 80000cd0 <release>
}
    80003c68:	60e2                	ld	ra,24(sp)
    80003c6a:	6442                	ld	s0,16(sp)
    80003c6c:	64a2                	ld	s1,8(sp)
    80003c6e:	6902                	ld	s2,0(sp)
    80003c70:	6105                	addi	sp,sp,32
    80003c72:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c74:	40bc                	lw	a5,64(s1)
    80003c76:	dff1                	beqz	a5,80003c52 <iput+0x26>
    80003c78:	04a49783          	lh	a5,74(s1)
    80003c7c:	fbf9                	bnez	a5,80003c52 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c7e:	01048913          	addi	s2,s1,16
    80003c82:	854a                	mv	a0,s2
    80003c84:	00001097          	auipc	ra,0x1
    80003c88:	abe080e7          	jalr	-1346(ra) # 80004742 <acquiresleep>
    release(&itable.lock);
    80003c8c:	0002c517          	auipc	a0,0x2c
    80003c90:	15450513          	addi	a0,a0,340 # 8002fde0 <itable>
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	03c080e7          	jalr	60(ra) # 80000cd0 <release>
    itrunc(ip);
    80003c9c:	8526                	mv	a0,s1
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	ee2080e7          	jalr	-286(ra) # 80003b80 <itrunc>
    ip->type = 0;
    80003ca6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003caa:	8526                	mv	a0,s1
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	cfa080e7          	jalr	-774(ra) # 800039a6 <iupdate>
    ip->valid = 0;
    80003cb4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00001097          	auipc	ra,0x1
    80003cbe:	ae0080e7          	jalr	-1312(ra) # 8000479a <releasesleep>
    acquire(&itable.lock);
    80003cc2:	0002c517          	auipc	a0,0x2c
    80003cc6:	11e50513          	addi	a0,a0,286 # 8002fde0 <itable>
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	f52080e7          	jalr	-174(ra) # 80000c1c <acquire>
    80003cd2:	b741                	j	80003c52 <iput+0x26>

0000000080003cd4 <iunlockput>:
{
    80003cd4:	1101                	addi	sp,sp,-32
    80003cd6:	ec06                	sd	ra,24(sp)
    80003cd8:	e822                	sd	s0,16(sp)
    80003cda:	e426                	sd	s1,8(sp)
    80003cdc:	1000                	addi	s0,sp,32
    80003cde:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	e54080e7          	jalr	-428(ra) # 80003b34 <iunlock>
  iput(ip);
    80003ce8:	8526                	mv	a0,s1
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	f42080e7          	jalr	-190(ra) # 80003c2c <iput>
}
    80003cf2:	60e2                	ld	ra,24(sp)
    80003cf4:	6442                	ld	s0,16(sp)
    80003cf6:	64a2                	ld	s1,8(sp)
    80003cf8:	6105                	addi	sp,sp,32
    80003cfa:	8082                	ret

0000000080003cfc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cfc:	1141                	addi	sp,sp,-16
    80003cfe:	e422                	sd	s0,8(sp)
    80003d00:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d02:	411c                	lw	a5,0(a0)
    80003d04:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d06:	415c                	lw	a5,4(a0)
    80003d08:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d0a:	04451783          	lh	a5,68(a0)
    80003d0e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d12:	04a51783          	lh	a5,74(a0)
    80003d16:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d1a:	04c56783          	lwu	a5,76(a0)
    80003d1e:	e99c                	sd	a5,16(a1)
}
    80003d20:	6422                	ld	s0,8(sp)
    80003d22:	0141                	addi	sp,sp,16
    80003d24:	8082                	ret

0000000080003d26 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d26:	457c                	lw	a5,76(a0)
    80003d28:	0ed7e963          	bltu	a5,a3,80003e1a <readi+0xf4>
{
    80003d2c:	7159                	addi	sp,sp,-112
    80003d2e:	f486                	sd	ra,104(sp)
    80003d30:	f0a2                	sd	s0,96(sp)
    80003d32:	eca6                	sd	s1,88(sp)
    80003d34:	e8ca                	sd	s2,80(sp)
    80003d36:	e4ce                	sd	s3,72(sp)
    80003d38:	e0d2                	sd	s4,64(sp)
    80003d3a:	fc56                	sd	s5,56(sp)
    80003d3c:	f85a                	sd	s6,48(sp)
    80003d3e:	f45e                	sd	s7,40(sp)
    80003d40:	f062                	sd	s8,32(sp)
    80003d42:	ec66                	sd	s9,24(sp)
    80003d44:	e86a                	sd	s10,16(sp)
    80003d46:	e46e                	sd	s11,8(sp)
    80003d48:	1880                	addi	s0,sp,112
    80003d4a:	8baa                	mv	s7,a0
    80003d4c:	8c2e                	mv	s8,a1
    80003d4e:	8ab2                	mv	s5,a2
    80003d50:	84b6                	mv	s1,a3
    80003d52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d54:	9f35                	addw	a4,a4,a3
    return 0;
    80003d56:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d58:	0ad76063          	bltu	a4,a3,80003df8 <readi+0xd2>
  if(off + n > ip->size)
    80003d5c:	00e7f463          	bgeu	a5,a4,80003d64 <readi+0x3e>
    n = ip->size - off;
    80003d60:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d64:	0a0b0963          	beqz	s6,80003e16 <readi+0xf0>
    80003d68:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d6e:	5cfd                	li	s9,-1
    80003d70:	a82d                	j	80003daa <readi+0x84>
    80003d72:	020a1d93          	slli	s11,s4,0x20
    80003d76:	020ddd93          	srli	s11,s11,0x20
    80003d7a:	05890613          	addi	a2,s2,88
    80003d7e:	86ee                	mv	a3,s11
    80003d80:	963a                	add	a2,a2,a4
    80003d82:	85d6                	mv	a1,s5
    80003d84:	8562                	mv	a0,s8
    80003d86:	ffffe097          	auipc	ra,0xffffe
    80003d8a:	7bc080e7          	jalr	1980(ra) # 80002542 <either_copyout>
    80003d8e:	05950d63          	beq	a0,s9,80003de8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d92:	854a                	mv	a0,s2
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	60c080e7          	jalr	1548(ra) # 800033a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d9c:	013a09bb          	addw	s3,s4,s3
    80003da0:	009a04bb          	addw	s1,s4,s1
    80003da4:	9aee                	add	s5,s5,s11
    80003da6:	0569f763          	bgeu	s3,s6,80003df4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003daa:	000ba903          	lw	s2,0(s7)
    80003dae:	00a4d59b          	srliw	a1,s1,0xa
    80003db2:	855e                	mv	a0,s7
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	8ac080e7          	jalr	-1876(ra) # 80003660 <bmap>
    80003dbc:	0005059b          	sext.w	a1,a0
    80003dc0:	854a                	mv	a0,s2
    80003dc2:	fffff097          	auipc	ra,0xfffff
    80003dc6:	4ae080e7          	jalr	1198(ra) # 80003270 <bread>
    80003dca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dcc:	3ff4f713          	andi	a4,s1,1023
    80003dd0:	40ed07bb          	subw	a5,s10,a4
    80003dd4:	413b06bb          	subw	a3,s6,s3
    80003dd8:	8a3e                	mv	s4,a5
    80003dda:	2781                	sext.w	a5,a5
    80003ddc:	0006861b          	sext.w	a2,a3
    80003de0:	f8f679e3          	bgeu	a2,a5,80003d72 <readi+0x4c>
    80003de4:	8a36                	mv	s4,a3
    80003de6:	b771                	j	80003d72 <readi+0x4c>
      brelse(bp);
    80003de8:	854a                	mv	a0,s2
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	5b6080e7          	jalr	1462(ra) # 800033a0 <brelse>
      tot = -1;
    80003df2:	59fd                	li	s3,-1
  }
  return tot;
    80003df4:	0009851b          	sext.w	a0,s3
}
    80003df8:	70a6                	ld	ra,104(sp)
    80003dfa:	7406                	ld	s0,96(sp)
    80003dfc:	64e6                	ld	s1,88(sp)
    80003dfe:	6946                	ld	s2,80(sp)
    80003e00:	69a6                	ld	s3,72(sp)
    80003e02:	6a06                	ld	s4,64(sp)
    80003e04:	7ae2                	ld	s5,56(sp)
    80003e06:	7b42                	ld	s6,48(sp)
    80003e08:	7ba2                	ld	s7,40(sp)
    80003e0a:	7c02                	ld	s8,32(sp)
    80003e0c:	6ce2                	ld	s9,24(sp)
    80003e0e:	6d42                	ld	s10,16(sp)
    80003e10:	6da2                	ld	s11,8(sp)
    80003e12:	6165                	addi	sp,sp,112
    80003e14:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e16:	89da                	mv	s3,s6
    80003e18:	bff1                	j	80003df4 <readi+0xce>
    return 0;
    80003e1a:	4501                	li	a0,0
}
    80003e1c:	8082                	ret

0000000080003e1e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e1e:	457c                	lw	a5,76(a0)
    80003e20:	10d7e863          	bltu	a5,a3,80003f30 <writei+0x112>
{
    80003e24:	7159                	addi	sp,sp,-112
    80003e26:	f486                	sd	ra,104(sp)
    80003e28:	f0a2                	sd	s0,96(sp)
    80003e2a:	eca6                	sd	s1,88(sp)
    80003e2c:	e8ca                	sd	s2,80(sp)
    80003e2e:	e4ce                	sd	s3,72(sp)
    80003e30:	e0d2                	sd	s4,64(sp)
    80003e32:	fc56                	sd	s5,56(sp)
    80003e34:	f85a                	sd	s6,48(sp)
    80003e36:	f45e                	sd	s7,40(sp)
    80003e38:	f062                	sd	s8,32(sp)
    80003e3a:	ec66                	sd	s9,24(sp)
    80003e3c:	e86a                	sd	s10,16(sp)
    80003e3e:	e46e                	sd	s11,8(sp)
    80003e40:	1880                	addi	s0,sp,112
    80003e42:	8b2a                	mv	s6,a0
    80003e44:	8c2e                	mv	s8,a1
    80003e46:	8ab2                	mv	s5,a2
    80003e48:	8936                	mv	s2,a3
    80003e4a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e4c:	00e687bb          	addw	a5,a3,a4
    80003e50:	0ed7e263          	bltu	a5,a3,80003f34 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e54:	00043737          	lui	a4,0x43
    80003e58:	0ef76063          	bltu	a4,a5,80003f38 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e5c:	0c0b8863          	beqz	s7,80003f2c <writei+0x10e>
    80003e60:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e62:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e66:	5cfd                	li	s9,-1
    80003e68:	a091                	j	80003eac <writei+0x8e>
    80003e6a:	02099d93          	slli	s11,s3,0x20
    80003e6e:	020ddd93          	srli	s11,s11,0x20
    80003e72:	05848513          	addi	a0,s1,88
    80003e76:	86ee                	mv	a3,s11
    80003e78:	8656                	mv	a2,s5
    80003e7a:	85e2                	mv	a1,s8
    80003e7c:	953a                	add	a0,a0,a4
    80003e7e:	ffffe097          	auipc	ra,0xffffe
    80003e82:	71c080e7          	jalr	1820(ra) # 8000259a <either_copyin>
    80003e86:	07950263          	beq	a0,s9,80003eea <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	798080e7          	jalr	1944(ra) # 80004624 <log_write>
    brelse(bp);
    80003e94:	8526                	mv	a0,s1
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	50a080e7          	jalr	1290(ra) # 800033a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e9e:	01498a3b          	addw	s4,s3,s4
    80003ea2:	0129893b          	addw	s2,s3,s2
    80003ea6:	9aee                	add	s5,s5,s11
    80003ea8:	057a7663          	bgeu	s4,s7,80003ef4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eac:	000b2483          	lw	s1,0(s6)
    80003eb0:	00a9559b          	srliw	a1,s2,0xa
    80003eb4:	855a                	mv	a0,s6
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	7aa080e7          	jalr	1962(ra) # 80003660 <bmap>
    80003ebe:	0005059b          	sext.w	a1,a0
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	fffff097          	auipc	ra,0xfffff
    80003ec8:	3ac080e7          	jalr	940(ra) # 80003270 <bread>
    80003ecc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ece:	3ff97713          	andi	a4,s2,1023
    80003ed2:	40ed07bb          	subw	a5,s10,a4
    80003ed6:	414b86bb          	subw	a3,s7,s4
    80003eda:	89be                	mv	s3,a5
    80003edc:	2781                	sext.w	a5,a5
    80003ede:	0006861b          	sext.w	a2,a3
    80003ee2:	f8f674e3          	bgeu	a2,a5,80003e6a <writei+0x4c>
    80003ee6:	89b6                	mv	s3,a3
    80003ee8:	b749                	j	80003e6a <writei+0x4c>
      brelse(bp);
    80003eea:	8526                	mv	a0,s1
    80003eec:	fffff097          	auipc	ra,0xfffff
    80003ef0:	4b4080e7          	jalr	1204(ra) # 800033a0 <brelse>
  }

  if(off > ip->size)
    80003ef4:	04cb2783          	lw	a5,76(s6)
    80003ef8:	0127f463          	bgeu	a5,s2,80003f00 <writei+0xe2>
    ip->size = off;
    80003efc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f00:	855a                	mv	a0,s6
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	aa4080e7          	jalr	-1372(ra) # 800039a6 <iupdate>

  return tot;
    80003f0a:	000a051b          	sext.w	a0,s4
}
    80003f0e:	70a6                	ld	ra,104(sp)
    80003f10:	7406                	ld	s0,96(sp)
    80003f12:	64e6                	ld	s1,88(sp)
    80003f14:	6946                	ld	s2,80(sp)
    80003f16:	69a6                	ld	s3,72(sp)
    80003f18:	6a06                	ld	s4,64(sp)
    80003f1a:	7ae2                	ld	s5,56(sp)
    80003f1c:	7b42                	ld	s6,48(sp)
    80003f1e:	7ba2                	ld	s7,40(sp)
    80003f20:	7c02                	ld	s8,32(sp)
    80003f22:	6ce2                	ld	s9,24(sp)
    80003f24:	6d42                	ld	s10,16(sp)
    80003f26:	6da2                	ld	s11,8(sp)
    80003f28:	6165                	addi	sp,sp,112
    80003f2a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f2c:	8a5e                	mv	s4,s7
    80003f2e:	bfc9                	j	80003f00 <writei+0xe2>
    return -1;
    80003f30:	557d                	li	a0,-1
}
    80003f32:	8082                	ret
    return -1;
    80003f34:	557d                	li	a0,-1
    80003f36:	bfe1                	j	80003f0e <writei+0xf0>
    return -1;
    80003f38:	557d                	li	a0,-1
    80003f3a:	bfd1                	j	80003f0e <writei+0xf0>

0000000080003f3c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f3c:	1141                	addi	sp,sp,-16
    80003f3e:	e406                	sd	ra,8(sp)
    80003f40:	e022                	sd	s0,0(sp)
    80003f42:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f44:	4639                	li	a2,14
    80003f46:	ffffd097          	auipc	ra,0xffffd
    80003f4a:	ea2080e7          	jalr	-350(ra) # 80000de8 <strncmp>
}
    80003f4e:	60a2                	ld	ra,8(sp)
    80003f50:	6402                	ld	s0,0(sp)
    80003f52:	0141                	addi	sp,sp,16
    80003f54:	8082                	ret

0000000080003f56 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f56:	7139                	addi	sp,sp,-64
    80003f58:	fc06                	sd	ra,56(sp)
    80003f5a:	f822                	sd	s0,48(sp)
    80003f5c:	f426                	sd	s1,40(sp)
    80003f5e:	f04a                	sd	s2,32(sp)
    80003f60:	ec4e                	sd	s3,24(sp)
    80003f62:	e852                	sd	s4,16(sp)
    80003f64:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f66:	04451703          	lh	a4,68(a0)
    80003f6a:	4785                	li	a5,1
    80003f6c:	00f71a63          	bne	a4,a5,80003f80 <dirlookup+0x2a>
    80003f70:	892a                	mv	s2,a0
    80003f72:	89ae                	mv	s3,a1
    80003f74:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f76:	457c                	lw	a5,76(a0)
    80003f78:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f7a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7c:	e79d                	bnez	a5,80003faa <dirlookup+0x54>
    80003f7e:	a8a5                	j	80003ff6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f80:	00004517          	auipc	a0,0x4
    80003f84:	6c850513          	addi	a0,a0,1736 # 80008648 <syscalls+0x1c0>
    80003f88:	ffffc097          	auipc	ra,0xffffc
    80003f8c:	5b4080e7          	jalr	1460(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003f90:	00004517          	auipc	a0,0x4
    80003f94:	6d050513          	addi	a0,a0,1744 # 80008660 <syscalls+0x1d8>
    80003f98:	ffffc097          	auipc	ra,0xffffc
    80003f9c:	5a4080e7          	jalr	1444(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fa0:	24c1                	addiw	s1,s1,16
    80003fa2:	04c92783          	lw	a5,76(s2)
    80003fa6:	04f4f763          	bgeu	s1,a5,80003ff4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003faa:	4741                	li	a4,16
    80003fac:	86a6                	mv	a3,s1
    80003fae:	fc040613          	addi	a2,s0,-64
    80003fb2:	4581                	li	a1,0
    80003fb4:	854a                	mv	a0,s2
    80003fb6:	00000097          	auipc	ra,0x0
    80003fba:	d70080e7          	jalr	-656(ra) # 80003d26 <readi>
    80003fbe:	47c1                	li	a5,16
    80003fc0:	fcf518e3          	bne	a0,a5,80003f90 <dirlookup+0x3a>
    if(de.inum == 0)
    80003fc4:	fc045783          	lhu	a5,-64(s0)
    80003fc8:	dfe1                	beqz	a5,80003fa0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fca:	fc240593          	addi	a1,s0,-62
    80003fce:	854e                	mv	a0,s3
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	f6c080e7          	jalr	-148(ra) # 80003f3c <namecmp>
    80003fd8:	f561                	bnez	a0,80003fa0 <dirlookup+0x4a>
      if(poff)
    80003fda:	000a0463          	beqz	s4,80003fe2 <dirlookup+0x8c>
        *poff = off;
    80003fde:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fe2:	fc045583          	lhu	a1,-64(s0)
    80003fe6:	00092503          	lw	a0,0(s2)
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	752080e7          	jalr	1874(ra) # 8000373c <iget>
    80003ff2:	a011                	j	80003ff6 <dirlookup+0xa0>
  return 0;
    80003ff4:	4501                	li	a0,0
}
    80003ff6:	70e2                	ld	ra,56(sp)
    80003ff8:	7442                	ld	s0,48(sp)
    80003ffa:	74a2                	ld	s1,40(sp)
    80003ffc:	7902                	ld	s2,32(sp)
    80003ffe:	69e2                	ld	s3,24(sp)
    80004000:	6a42                	ld	s4,16(sp)
    80004002:	6121                	addi	sp,sp,64
    80004004:	8082                	ret

0000000080004006 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004006:	711d                	addi	sp,sp,-96
    80004008:	ec86                	sd	ra,88(sp)
    8000400a:	e8a2                	sd	s0,80(sp)
    8000400c:	e4a6                	sd	s1,72(sp)
    8000400e:	e0ca                	sd	s2,64(sp)
    80004010:	fc4e                	sd	s3,56(sp)
    80004012:	f852                	sd	s4,48(sp)
    80004014:	f456                	sd	s5,40(sp)
    80004016:	f05a                	sd	s6,32(sp)
    80004018:	ec5e                	sd	s7,24(sp)
    8000401a:	e862                	sd	s8,16(sp)
    8000401c:	e466                	sd	s9,8(sp)
    8000401e:	e06a                	sd	s10,0(sp)
    80004020:	1080                	addi	s0,sp,96
    80004022:	84aa                	mv	s1,a0
    80004024:	8b2e                	mv	s6,a1
    80004026:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004028:	00054703          	lbu	a4,0(a0)
    8000402c:	02f00793          	li	a5,47
    80004030:	02f70363          	beq	a4,a5,80004056 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004034:	ffffe097          	auipc	ra,0xffffe
    80004038:	a02080e7          	jalr	-1534(ra) # 80001a36 <myproc>
    8000403c:	42853503          	ld	a0,1064(a0)
    80004040:	00000097          	auipc	ra,0x0
    80004044:	9f4080e7          	jalr	-1548(ra) # 80003a34 <idup>
    80004048:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000404a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000404e:	4cb5                	li	s9,13
  len = path - s;
    80004050:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004052:	4c05                	li	s8,1
    80004054:	a87d                	j	80004112 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004056:	4585                	li	a1,1
    80004058:	4505                	li	a0,1
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	6e2080e7          	jalr	1762(ra) # 8000373c <iget>
    80004062:	8a2a                	mv	s4,a0
    80004064:	b7dd                	j	8000404a <namex+0x44>
      iunlockput(ip);
    80004066:	8552                	mv	a0,s4
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	c6c080e7          	jalr	-916(ra) # 80003cd4 <iunlockput>
      return 0;
    80004070:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004072:	8552                	mv	a0,s4
    80004074:	60e6                	ld	ra,88(sp)
    80004076:	6446                	ld	s0,80(sp)
    80004078:	64a6                	ld	s1,72(sp)
    8000407a:	6906                	ld	s2,64(sp)
    8000407c:	79e2                	ld	s3,56(sp)
    8000407e:	7a42                	ld	s4,48(sp)
    80004080:	7aa2                	ld	s5,40(sp)
    80004082:	7b02                	ld	s6,32(sp)
    80004084:	6be2                	ld	s7,24(sp)
    80004086:	6c42                	ld	s8,16(sp)
    80004088:	6ca2                	ld	s9,8(sp)
    8000408a:	6d02                	ld	s10,0(sp)
    8000408c:	6125                	addi	sp,sp,96
    8000408e:	8082                	ret
      iunlock(ip);
    80004090:	8552                	mv	a0,s4
    80004092:	00000097          	auipc	ra,0x0
    80004096:	aa2080e7          	jalr	-1374(ra) # 80003b34 <iunlock>
      return ip;
    8000409a:	bfe1                	j	80004072 <namex+0x6c>
      iunlockput(ip);
    8000409c:	8552                	mv	a0,s4
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	c36080e7          	jalr	-970(ra) # 80003cd4 <iunlockput>
      return 0;
    800040a6:	8a4e                	mv	s4,s3
    800040a8:	b7e9                	j	80004072 <namex+0x6c>
  len = path - s;
    800040aa:	40998633          	sub	a2,s3,s1
    800040ae:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800040b2:	09acd863          	bge	s9,s10,80004142 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800040b6:	4639                	li	a2,14
    800040b8:	85a6                	mv	a1,s1
    800040ba:	8556                	mv	a0,s5
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	cb8080e7          	jalr	-840(ra) # 80000d74 <memmove>
    800040c4:	84ce                	mv	s1,s3
  while(*path == '/')
    800040c6:	0004c783          	lbu	a5,0(s1)
    800040ca:	01279763          	bne	a5,s2,800040d8 <namex+0xd2>
    path++;
    800040ce:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040d0:	0004c783          	lbu	a5,0(s1)
    800040d4:	ff278de3          	beq	a5,s2,800040ce <namex+0xc8>
    ilock(ip);
    800040d8:	8552                	mv	a0,s4
    800040da:	00000097          	auipc	ra,0x0
    800040de:	998080e7          	jalr	-1640(ra) # 80003a72 <ilock>
    if(ip->type != T_DIR){
    800040e2:	044a1783          	lh	a5,68(s4)
    800040e6:	f98790e3          	bne	a5,s8,80004066 <namex+0x60>
    if(nameiparent && *path == '\0'){
    800040ea:	000b0563          	beqz	s6,800040f4 <namex+0xee>
    800040ee:	0004c783          	lbu	a5,0(s1)
    800040f2:	dfd9                	beqz	a5,80004090 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040f4:	865e                	mv	a2,s7
    800040f6:	85d6                	mv	a1,s5
    800040f8:	8552                	mv	a0,s4
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	e5c080e7          	jalr	-420(ra) # 80003f56 <dirlookup>
    80004102:	89aa                	mv	s3,a0
    80004104:	dd41                	beqz	a0,8000409c <namex+0x96>
    iunlockput(ip);
    80004106:	8552                	mv	a0,s4
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	bcc080e7          	jalr	-1076(ra) # 80003cd4 <iunlockput>
    ip = next;
    80004110:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004112:	0004c783          	lbu	a5,0(s1)
    80004116:	01279763          	bne	a5,s2,80004124 <namex+0x11e>
    path++;
    8000411a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000411c:	0004c783          	lbu	a5,0(s1)
    80004120:	ff278de3          	beq	a5,s2,8000411a <namex+0x114>
  if(*path == 0)
    80004124:	cb9d                	beqz	a5,8000415a <namex+0x154>
  while(*path != '/' && *path != 0)
    80004126:	0004c783          	lbu	a5,0(s1)
    8000412a:	89a6                	mv	s3,s1
  len = path - s;
    8000412c:	8d5e                	mv	s10,s7
    8000412e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004130:	01278963          	beq	a5,s2,80004142 <namex+0x13c>
    80004134:	dbbd                	beqz	a5,800040aa <namex+0xa4>
    path++;
    80004136:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004138:	0009c783          	lbu	a5,0(s3)
    8000413c:	ff279ce3          	bne	a5,s2,80004134 <namex+0x12e>
    80004140:	b7ad                	j	800040aa <namex+0xa4>
    memmove(name, s, len);
    80004142:	2601                	sext.w	a2,a2
    80004144:	85a6                	mv	a1,s1
    80004146:	8556                	mv	a0,s5
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	c2c080e7          	jalr	-980(ra) # 80000d74 <memmove>
    name[len] = 0;
    80004150:	9d56                	add	s10,s10,s5
    80004152:	000d0023          	sb	zero,0(s10)
    80004156:	84ce                	mv	s1,s3
    80004158:	b7bd                	j	800040c6 <namex+0xc0>
  if(nameiparent){
    8000415a:	f00b0ce3          	beqz	s6,80004072 <namex+0x6c>
    iput(ip);
    8000415e:	8552                	mv	a0,s4
    80004160:	00000097          	auipc	ra,0x0
    80004164:	acc080e7          	jalr	-1332(ra) # 80003c2c <iput>
    return 0;
    80004168:	4a01                	li	s4,0
    8000416a:	b721                	j	80004072 <namex+0x6c>

000000008000416c <dirlink>:
{
    8000416c:	7139                	addi	sp,sp,-64
    8000416e:	fc06                	sd	ra,56(sp)
    80004170:	f822                	sd	s0,48(sp)
    80004172:	f426                	sd	s1,40(sp)
    80004174:	f04a                	sd	s2,32(sp)
    80004176:	ec4e                	sd	s3,24(sp)
    80004178:	e852                	sd	s4,16(sp)
    8000417a:	0080                	addi	s0,sp,64
    8000417c:	892a                	mv	s2,a0
    8000417e:	8a2e                	mv	s4,a1
    80004180:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004182:	4601                	li	a2,0
    80004184:	00000097          	auipc	ra,0x0
    80004188:	dd2080e7          	jalr	-558(ra) # 80003f56 <dirlookup>
    8000418c:	e93d                	bnez	a0,80004202 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000418e:	04c92483          	lw	s1,76(s2)
    80004192:	c49d                	beqz	s1,800041c0 <dirlink+0x54>
    80004194:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004196:	4741                	li	a4,16
    80004198:	86a6                	mv	a3,s1
    8000419a:	fc040613          	addi	a2,s0,-64
    8000419e:	4581                	li	a1,0
    800041a0:	854a                	mv	a0,s2
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	b84080e7          	jalr	-1148(ra) # 80003d26 <readi>
    800041aa:	47c1                	li	a5,16
    800041ac:	06f51163          	bne	a0,a5,8000420e <dirlink+0xa2>
    if(de.inum == 0)
    800041b0:	fc045783          	lhu	a5,-64(s0)
    800041b4:	c791                	beqz	a5,800041c0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b6:	24c1                	addiw	s1,s1,16
    800041b8:	04c92783          	lw	a5,76(s2)
    800041bc:	fcf4ede3          	bltu	s1,a5,80004196 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041c0:	4639                	li	a2,14
    800041c2:	85d2                	mv	a1,s4
    800041c4:	fc240513          	addi	a0,s0,-62
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	c5c080e7          	jalr	-932(ra) # 80000e24 <strncpy>
  de.inum = inum;
    800041d0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d4:	4741                	li	a4,16
    800041d6:	86a6                	mv	a3,s1
    800041d8:	fc040613          	addi	a2,s0,-64
    800041dc:	4581                	li	a1,0
    800041de:	854a                	mv	a0,s2
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	c3e080e7          	jalr	-962(ra) # 80003e1e <writei>
    800041e8:	872a                	mv	a4,a0
    800041ea:	47c1                	li	a5,16
  return 0;
    800041ec:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ee:	02f71863          	bne	a4,a5,8000421e <dirlink+0xb2>
}
    800041f2:	70e2                	ld	ra,56(sp)
    800041f4:	7442                	ld	s0,48(sp)
    800041f6:	74a2                	ld	s1,40(sp)
    800041f8:	7902                	ld	s2,32(sp)
    800041fa:	69e2                	ld	s3,24(sp)
    800041fc:	6a42                	ld	s4,16(sp)
    800041fe:	6121                	addi	sp,sp,64
    80004200:	8082                	ret
    iput(ip);
    80004202:	00000097          	auipc	ra,0x0
    80004206:	a2a080e7          	jalr	-1494(ra) # 80003c2c <iput>
    return -1;
    8000420a:	557d                	li	a0,-1
    8000420c:	b7dd                	j	800041f2 <dirlink+0x86>
      panic("dirlink read");
    8000420e:	00004517          	auipc	a0,0x4
    80004212:	46250513          	addi	a0,a0,1122 # 80008670 <syscalls+0x1e8>
    80004216:	ffffc097          	auipc	ra,0xffffc
    8000421a:	326080e7          	jalr	806(ra) # 8000053c <panic>
    panic("dirlink");
    8000421e:	00004517          	auipc	a0,0x4
    80004222:	56250513          	addi	a0,a0,1378 # 80008780 <syscalls+0x2f8>
    80004226:	ffffc097          	auipc	ra,0xffffc
    8000422a:	316080e7          	jalr	790(ra) # 8000053c <panic>

000000008000422e <namei>:

struct inode*
namei(char *path)
{
    8000422e:	1101                	addi	sp,sp,-32
    80004230:	ec06                	sd	ra,24(sp)
    80004232:	e822                	sd	s0,16(sp)
    80004234:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004236:	fe040613          	addi	a2,s0,-32
    8000423a:	4581                	li	a1,0
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	dca080e7          	jalr	-566(ra) # 80004006 <namex>
}
    80004244:	60e2                	ld	ra,24(sp)
    80004246:	6442                	ld	s0,16(sp)
    80004248:	6105                	addi	sp,sp,32
    8000424a:	8082                	ret

000000008000424c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000424c:	1141                	addi	sp,sp,-16
    8000424e:	e406                	sd	ra,8(sp)
    80004250:	e022                	sd	s0,0(sp)
    80004252:	0800                	addi	s0,sp,16
    80004254:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004256:	4585                	li	a1,1
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	dae080e7          	jalr	-594(ra) # 80004006 <namex>
}
    80004260:	60a2                	ld	ra,8(sp)
    80004262:	6402                	ld	s0,0(sp)
    80004264:	0141                	addi	sp,sp,16
    80004266:	8082                	ret

0000000080004268 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004268:	1101                	addi	sp,sp,-32
    8000426a:	ec06                	sd	ra,24(sp)
    8000426c:	e822                	sd	s0,16(sp)
    8000426e:	e426                	sd	s1,8(sp)
    80004270:	e04a                	sd	s2,0(sp)
    80004272:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004274:	0002d917          	auipc	s2,0x2d
    80004278:	61490913          	addi	s2,s2,1556 # 80031888 <log>
    8000427c:	01892583          	lw	a1,24(s2)
    80004280:	02892503          	lw	a0,40(s2)
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	fec080e7          	jalr	-20(ra) # 80003270 <bread>
    8000428c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000428e:	02c92683          	lw	a3,44(s2)
    80004292:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004294:	02d05863          	blez	a3,800042c4 <write_head+0x5c>
    80004298:	0002d797          	auipc	a5,0x2d
    8000429c:	62078793          	addi	a5,a5,1568 # 800318b8 <log+0x30>
    800042a0:	05c50713          	addi	a4,a0,92
    800042a4:	36fd                	addiw	a3,a3,-1
    800042a6:	02069613          	slli	a2,a3,0x20
    800042aa:	01e65693          	srli	a3,a2,0x1e
    800042ae:	0002d617          	auipc	a2,0x2d
    800042b2:	60e60613          	addi	a2,a2,1550 # 800318bc <log+0x34>
    800042b6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042b8:	4390                	lw	a2,0(a5)
    800042ba:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042bc:	0791                	addi	a5,a5,4
    800042be:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800042c0:	fed79ce3          	bne	a5,a3,800042b8 <write_head+0x50>
  }
  bwrite(buf);
    800042c4:	8526                	mv	a0,s1
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	09c080e7          	jalr	156(ra) # 80003362 <bwrite>
  brelse(buf);
    800042ce:	8526                	mv	a0,s1
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	0d0080e7          	jalr	208(ra) # 800033a0 <brelse>
}
    800042d8:	60e2                	ld	ra,24(sp)
    800042da:	6442                	ld	s0,16(sp)
    800042dc:	64a2                	ld	s1,8(sp)
    800042de:	6902                	ld	s2,0(sp)
    800042e0:	6105                	addi	sp,sp,32
    800042e2:	8082                	ret

00000000800042e4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e4:	0002d797          	auipc	a5,0x2d
    800042e8:	5d07a783          	lw	a5,1488(a5) # 800318b4 <log+0x2c>
    800042ec:	0af05d63          	blez	a5,800043a6 <install_trans+0xc2>
{
    800042f0:	7139                	addi	sp,sp,-64
    800042f2:	fc06                	sd	ra,56(sp)
    800042f4:	f822                	sd	s0,48(sp)
    800042f6:	f426                	sd	s1,40(sp)
    800042f8:	f04a                	sd	s2,32(sp)
    800042fa:	ec4e                	sd	s3,24(sp)
    800042fc:	e852                	sd	s4,16(sp)
    800042fe:	e456                	sd	s5,8(sp)
    80004300:	e05a                	sd	s6,0(sp)
    80004302:	0080                	addi	s0,sp,64
    80004304:	8b2a                	mv	s6,a0
    80004306:	0002da97          	auipc	s5,0x2d
    8000430a:	5b2a8a93          	addi	s5,s5,1458 # 800318b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000430e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004310:	0002d997          	auipc	s3,0x2d
    80004314:	57898993          	addi	s3,s3,1400 # 80031888 <log>
    80004318:	a00d                	j	8000433a <install_trans+0x56>
    brelse(lbuf);
    8000431a:	854a                	mv	a0,s2
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	084080e7          	jalr	132(ra) # 800033a0 <brelse>
    brelse(dbuf);
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	07a080e7          	jalr	122(ra) # 800033a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000432e:	2a05                	addiw	s4,s4,1
    80004330:	0a91                	addi	s5,s5,4
    80004332:	02c9a783          	lw	a5,44(s3)
    80004336:	04fa5e63          	bge	s4,a5,80004392 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000433a:	0189a583          	lw	a1,24(s3)
    8000433e:	014585bb          	addw	a1,a1,s4
    80004342:	2585                	addiw	a1,a1,1
    80004344:	0289a503          	lw	a0,40(s3)
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	f28080e7          	jalr	-216(ra) # 80003270 <bread>
    80004350:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004352:	000aa583          	lw	a1,0(s5)
    80004356:	0289a503          	lw	a0,40(s3)
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	f16080e7          	jalr	-234(ra) # 80003270 <bread>
    80004362:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004364:	40000613          	li	a2,1024
    80004368:	05890593          	addi	a1,s2,88
    8000436c:	05850513          	addi	a0,a0,88
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	a04080e7          	jalr	-1532(ra) # 80000d74 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004378:	8526                	mv	a0,s1
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	fe8080e7          	jalr	-24(ra) # 80003362 <bwrite>
    if(recovering == 0)
    80004382:	f80b1ce3          	bnez	s6,8000431a <install_trans+0x36>
      bunpin(dbuf);
    80004386:	8526                	mv	a0,s1
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	0f2080e7          	jalr	242(ra) # 8000347a <bunpin>
    80004390:	b769                	j	8000431a <install_trans+0x36>
}
    80004392:	70e2                	ld	ra,56(sp)
    80004394:	7442                	ld	s0,48(sp)
    80004396:	74a2                	ld	s1,40(sp)
    80004398:	7902                	ld	s2,32(sp)
    8000439a:	69e2                	ld	s3,24(sp)
    8000439c:	6a42                	ld	s4,16(sp)
    8000439e:	6aa2                	ld	s5,8(sp)
    800043a0:	6b02                	ld	s6,0(sp)
    800043a2:	6121                	addi	sp,sp,64
    800043a4:	8082                	ret
    800043a6:	8082                	ret

00000000800043a8 <initlog>:
{
    800043a8:	7179                	addi	sp,sp,-48
    800043aa:	f406                	sd	ra,40(sp)
    800043ac:	f022                	sd	s0,32(sp)
    800043ae:	ec26                	sd	s1,24(sp)
    800043b0:	e84a                	sd	s2,16(sp)
    800043b2:	e44e                	sd	s3,8(sp)
    800043b4:	1800                	addi	s0,sp,48
    800043b6:	892a                	mv	s2,a0
    800043b8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043ba:	0002d497          	auipc	s1,0x2d
    800043be:	4ce48493          	addi	s1,s1,1230 # 80031888 <log>
    800043c2:	00004597          	auipc	a1,0x4
    800043c6:	2be58593          	addi	a1,a1,702 # 80008680 <syscalls+0x1f8>
    800043ca:	8526                	mv	a0,s1
    800043cc:	ffffc097          	auipc	ra,0xffffc
    800043d0:	7c0080e7          	jalr	1984(ra) # 80000b8c <initlock>
  log.start = sb->logstart;
    800043d4:	0149a583          	lw	a1,20(s3)
    800043d8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043da:	0109a783          	lw	a5,16(s3)
    800043de:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043e0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043e4:	854a                	mv	a0,s2
    800043e6:	fffff097          	auipc	ra,0xfffff
    800043ea:	e8a080e7          	jalr	-374(ra) # 80003270 <bread>
  log.lh.n = lh->n;
    800043ee:	4d34                	lw	a3,88(a0)
    800043f0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043f2:	02d05663          	blez	a3,8000441e <initlog+0x76>
    800043f6:	05c50793          	addi	a5,a0,92
    800043fa:	0002d717          	auipc	a4,0x2d
    800043fe:	4be70713          	addi	a4,a4,1214 # 800318b8 <log+0x30>
    80004402:	36fd                	addiw	a3,a3,-1
    80004404:	02069613          	slli	a2,a3,0x20
    80004408:	01e65693          	srli	a3,a2,0x1e
    8000440c:	06050613          	addi	a2,a0,96
    80004410:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004412:	4390                	lw	a2,0(a5)
    80004414:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004416:	0791                	addi	a5,a5,4
    80004418:	0711                	addi	a4,a4,4
    8000441a:	fed79ce3          	bne	a5,a3,80004412 <initlog+0x6a>
  brelse(buf);
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	f82080e7          	jalr	-126(ra) # 800033a0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004426:	4505                	li	a0,1
    80004428:	00000097          	auipc	ra,0x0
    8000442c:	ebc080e7          	jalr	-324(ra) # 800042e4 <install_trans>
  log.lh.n = 0;
    80004430:	0002d797          	auipc	a5,0x2d
    80004434:	4807a223          	sw	zero,1156(a5) # 800318b4 <log+0x2c>
  write_head(); // clear the log
    80004438:	00000097          	auipc	ra,0x0
    8000443c:	e30080e7          	jalr	-464(ra) # 80004268 <write_head>
}
    80004440:	70a2                	ld	ra,40(sp)
    80004442:	7402                	ld	s0,32(sp)
    80004444:	64e2                	ld	s1,24(sp)
    80004446:	6942                	ld	s2,16(sp)
    80004448:	69a2                	ld	s3,8(sp)
    8000444a:	6145                	addi	sp,sp,48
    8000444c:	8082                	ret

000000008000444e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	e426                	sd	s1,8(sp)
    80004456:	e04a                	sd	s2,0(sp)
    80004458:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000445a:	0002d517          	auipc	a0,0x2d
    8000445e:	42e50513          	addi	a0,a0,1070 # 80031888 <log>
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	7ba080e7          	jalr	1978(ra) # 80000c1c <acquire>
  while(1){
    if(log.committing){
    8000446a:	0002d497          	auipc	s1,0x2d
    8000446e:	41e48493          	addi	s1,s1,1054 # 80031888 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004472:	4979                	li	s2,30
    80004474:	a039                	j	80004482 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004476:	85a6                	mv	a1,s1
    80004478:	8526                	mv	a0,s1
    8000447a:	ffffe097          	auipc	ra,0xffffe
    8000447e:	cea080e7          	jalr	-790(ra) # 80002164 <sleep>
    if(log.committing){
    80004482:	50dc                	lw	a5,36(s1)
    80004484:	fbed                	bnez	a5,80004476 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004486:	5098                	lw	a4,32(s1)
    80004488:	2705                	addiw	a4,a4,1
    8000448a:	0007069b          	sext.w	a3,a4
    8000448e:	0027179b          	slliw	a5,a4,0x2
    80004492:	9fb9                	addw	a5,a5,a4
    80004494:	0017979b          	slliw	a5,a5,0x1
    80004498:	54d8                	lw	a4,44(s1)
    8000449a:	9fb9                	addw	a5,a5,a4
    8000449c:	00f95963          	bge	s2,a5,800044ae <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044a0:	85a6                	mv	a1,s1
    800044a2:	8526                	mv	a0,s1
    800044a4:	ffffe097          	auipc	ra,0xffffe
    800044a8:	cc0080e7          	jalr	-832(ra) # 80002164 <sleep>
    800044ac:	bfd9                	j	80004482 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044ae:	0002d517          	auipc	a0,0x2d
    800044b2:	3da50513          	addi	a0,a0,986 # 80031888 <log>
    800044b6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	818080e7          	jalr	-2024(ra) # 80000cd0 <release>
      break;
    }
  }
}
    800044c0:	60e2                	ld	ra,24(sp)
    800044c2:	6442                	ld	s0,16(sp)
    800044c4:	64a2                	ld	s1,8(sp)
    800044c6:	6902                	ld	s2,0(sp)
    800044c8:	6105                	addi	sp,sp,32
    800044ca:	8082                	ret

00000000800044cc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044cc:	7139                	addi	sp,sp,-64
    800044ce:	fc06                	sd	ra,56(sp)
    800044d0:	f822                	sd	s0,48(sp)
    800044d2:	f426                	sd	s1,40(sp)
    800044d4:	f04a                	sd	s2,32(sp)
    800044d6:	ec4e                	sd	s3,24(sp)
    800044d8:	e852                	sd	s4,16(sp)
    800044da:	e456                	sd	s5,8(sp)
    800044dc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044de:	0002d497          	auipc	s1,0x2d
    800044e2:	3aa48493          	addi	s1,s1,938 # 80031888 <log>
    800044e6:	8526                	mv	a0,s1
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	734080e7          	jalr	1844(ra) # 80000c1c <acquire>
  log.outstanding -= 1;
    800044f0:	509c                	lw	a5,32(s1)
    800044f2:	37fd                	addiw	a5,a5,-1
    800044f4:	0007891b          	sext.w	s2,a5
    800044f8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044fa:	50dc                	lw	a5,36(s1)
    800044fc:	e7b9                	bnez	a5,8000454a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044fe:	04091e63          	bnez	s2,8000455a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004502:	0002d497          	auipc	s1,0x2d
    80004506:	38648493          	addi	s1,s1,902 # 80031888 <log>
    8000450a:	4785                	li	a5,1
    8000450c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000450e:	8526                	mv	a0,s1
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	7c0080e7          	jalr	1984(ra) # 80000cd0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004518:	54dc                	lw	a5,44(s1)
    8000451a:	06f04763          	bgtz	a5,80004588 <end_op+0xbc>
    acquire(&log.lock);
    8000451e:	0002d497          	auipc	s1,0x2d
    80004522:	36a48493          	addi	s1,s1,874 # 80031888 <log>
    80004526:	8526                	mv	a0,s1
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	6f4080e7          	jalr	1780(ra) # 80000c1c <acquire>
    log.committing = 0;
    80004530:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004534:	8526                	mv	a0,s1
    80004536:	ffffe097          	auipc	ra,0xffffe
    8000453a:	dd2080e7          	jalr	-558(ra) # 80002308 <wakeup>
    release(&log.lock);
    8000453e:	8526                	mv	a0,s1
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	790080e7          	jalr	1936(ra) # 80000cd0 <release>
}
    80004548:	a03d                	j	80004576 <end_op+0xaa>
    panic("log.committing");
    8000454a:	00004517          	auipc	a0,0x4
    8000454e:	13e50513          	addi	a0,a0,318 # 80008688 <syscalls+0x200>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	fea080e7          	jalr	-22(ra) # 8000053c <panic>
    wakeup(&log);
    8000455a:	0002d497          	auipc	s1,0x2d
    8000455e:	32e48493          	addi	s1,s1,814 # 80031888 <log>
    80004562:	8526                	mv	a0,s1
    80004564:	ffffe097          	auipc	ra,0xffffe
    80004568:	da4080e7          	jalr	-604(ra) # 80002308 <wakeup>
  release(&log.lock);
    8000456c:	8526                	mv	a0,s1
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	762080e7          	jalr	1890(ra) # 80000cd0 <release>
}
    80004576:	70e2                	ld	ra,56(sp)
    80004578:	7442                	ld	s0,48(sp)
    8000457a:	74a2                	ld	s1,40(sp)
    8000457c:	7902                	ld	s2,32(sp)
    8000457e:	69e2                	ld	s3,24(sp)
    80004580:	6a42                	ld	s4,16(sp)
    80004582:	6aa2                	ld	s5,8(sp)
    80004584:	6121                	addi	sp,sp,64
    80004586:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004588:	0002da97          	auipc	s5,0x2d
    8000458c:	330a8a93          	addi	s5,s5,816 # 800318b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004590:	0002da17          	auipc	s4,0x2d
    80004594:	2f8a0a13          	addi	s4,s4,760 # 80031888 <log>
    80004598:	018a2583          	lw	a1,24(s4)
    8000459c:	012585bb          	addw	a1,a1,s2
    800045a0:	2585                	addiw	a1,a1,1
    800045a2:	028a2503          	lw	a0,40(s4)
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	cca080e7          	jalr	-822(ra) # 80003270 <bread>
    800045ae:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045b0:	000aa583          	lw	a1,0(s5)
    800045b4:	028a2503          	lw	a0,40(s4)
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	cb8080e7          	jalr	-840(ra) # 80003270 <bread>
    800045c0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045c2:	40000613          	li	a2,1024
    800045c6:	05850593          	addi	a1,a0,88
    800045ca:	05848513          	addi	a0,s1,88
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	7a6080e7          	jalr	1958(ra) # 80000d74 <memmove>
    bwrite(to);  // write the log
    800045d6:	8526                	mv	a0,s1
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	d8a080e7          	jalr	-630(ra) # 80003362 <bwrite>
    brelse(from);
    800045e0:	854e                	mv	a0,s3
    800045e2:	fffff097          	auipc	ra,0xfffff
    800045e6:	dbe080e7          	jalr	-578(ra) # 800033a0 <brelse>
    brelse(to);
    800045ea:	8526                	mv	a0,s1
    800045ec:	fffff097          	auipc	ra,0xfffff
    800045f0:	db4080e7          	jalr	-588(ra) # 800033a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045f4:	2905                	addiw	s2,s2,1
    800045f6:	0a91                	addi	s5,s5,4
    800045f8:	02ca2783          	lw	a5,44(s4)
    800045fc:	f8f94ee3          	blt	s2,a5,80004598 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004600:	00000097          	auipc	ra,0x0
    80004604:	c68080e7          	jalr	-920(ra) # 80004268 <write_head>
    install_trans(0); // Now install writes to home locations
    80004608:	4501                	li	a0,0
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	cda080e7          	jalr	-806(ra) # 800042e4 <install_trans>
    log.lh.n = 0;
    80004612:	0002d797          	auipc	a5,0x2d
    80004616:	2a07a123          	sw	zero,674(a5) # 800318b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	c4e080e7          	jalr	-946(ra) # 80004268 <write_head>
    80004622:	bdf5                	j	8000451e <end_op+0x52>

0000000080004624 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	e04a                	sd	s2,0(sp)
    8000462e:	1000                	addi	s0,sp,32
    80004630:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004632:	0002d917          	auipc	s2,0x2d
    80004636:	25690913          	addi	s2,s2,598 # 80031888 <log>
    8000463a:	854a                	mv	a0,s2
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	5e0080e7          	jalr	1504(ra) # 80000c1c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004644:	02c92603          	lw	a2,44(s2)
    80004648:	47f5                	li	a5,29
    8000464a:	06c7c563          	blt	a5,a2,800046b4 <log_write+0x90>
    8000464e:	0002d797          	auipc	a5,0x2d
    80004652:	2567a783          	lw	a5,598(a5) # 800318a4 <log+0x1c>
    80004656:	37fd                	addiw	a5,a5,-1
    80004658:	04f65e63          	bge	a2,a5,800046b4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000465c:	0002d797          	auipc	a5,0x2d
    80004660:	24c7a783          	lw	a5,588(a5) # 800318a8 <log+0x20>
    80004664:	06f05063          	blez	a5,800046c4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004668:	4781                	li	a5,0
    8000466a:	06c05563          	blez	a2,800046d4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000466e:	44cc                	lw	a1,12(s1)
    80004670:	0002d717          	auipc	a4,0x2d
    80004674:	24870713          	addi	a4,a4,584 # 800318b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004678:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000467a:	4314                	lw	a3,0(a4)
    8000467c:	04b68c63          	beq	a3,a1,800046d4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004680:	2785                	addiw	a5,a5,1
    80004682:	0711                	addi	a4,a4,4
    80004684:	fef61be3          	bne	a2,a5,8000467a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004688:	0621                	addi	a2,a2,8
    8000468a:	060a                	slli	a2,a2,0x2
    8000468c:	0002d797          	auipc	a5,0x2d
    80004690:	1fc78793          	addi	a5,a5,508 # 80031888 <log>
    80004694:	97b2                	add	a5,a5,a2
    80004696:	44d8                	lw	a4,12(s1)
    80004698:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000469a:	8526                	mv	a0,s1
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	da2080e7          	jalr	-606(ra) # 8000343e <bpin>
    log.lh.n++;
    800046a4:	0002d717          	auipc	a4,0x2d
    800046a8:	1e470713          	addi	a4,a4,484 # 80031888 <log>
    800046ac:	575c                	lw	a5,44(a4)
    800046ae:	2785                	addiw	a5,a5,1
    800046b0:	d75c                	sw	a5,44(a4)
    800046b2:	a82d                	j	800046ec <log_write+0xc8>
    panic("too big a transaction");
    800046b4:	00004517          	auipc	a0,0x4
    800046b8:	fe450513          	addi	a0,a0,-28 # 80008698 <syscalls+0x210>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	e80080e7          	jalr	-384(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800046c4:	00004517          	auipc	a0,0x4
    800046c8:	fec50513          	addi	a0,a0,-20 # 800086b0 <syscalls+0x228>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	e70080e7          	jalr	-400(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800046d4:	00878693          	addi	a3,a5,8
    800046d8:	068a                	slli	a3,a3,0x2
    800046da:	0002d717          	auipc	a4,0x2d
    800046de:	1ae70713          	addi	a4,a4,430 # 80031888 <log>
    800046e2:	9736                	add	a4,a4,a3
    800046e4:	44d4                	lw	a3,12(s1)
    800046e6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046e8:	faf609e3          	beq	a2,a5,8000469a <log_write+0x76>
  }
  release(&log.lock);
    800046ec:	0002d517          	auipc	a0,0x2d
    800046f0:	19c50513          	addi	a0,a0,412 # 80031888 <log>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	5dc080e7          	jalr	1500(ra) # 80000cd0 <release>
}
    800046fc:	60e2                	ld	ra,24(sp)
    800046fe:	6442                	ld	s0,16(sp)
    80004700:	64a2                	ld	s1,8(sp)
    80004702:	6902                	ld	s2,0(sp)
    80004704:	6105                	addi	sp,sp,32
    80004706:	8082                	ret

0000000080004708 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004708:	1101                	addi	sp,sp,-32
    8000470a:	ec06                	sd	ra,24(sp)
    8000470c:	e822                	sd	s0,16(sp)
    8000470e:	e426                	sd	s1,8(sp)
    80004710:	e04a                	sd	s2,0(sp)
    80004712:	1000                	addi	s0,sp,32
    80004714:	84aa                	mv	s1,a0
    80004716:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004718:	00004597          	auipc	a1,0x4
    8000471c:	fb858593          	addi	a1,a1,-72 # 800086d0 <syscalls+0x248>
    80004720:	0521                	addi	a0,a0,8
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	46a080e7          	jalr	1130(ra) # 80000b8c <initlock>
  lk->name = name;
    8000472a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000472e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004732:	0204a423          	sw	zero,40(s1)
}
    80004736:	60e2                	ld	ra,24(sp)
    80004738:	6442                	ld	s0,16(sp)
    8000473a:	64a2                	ld	s1,8(sp)
    8000473c:	6902                	ld	s2,0(sp)
    8000473e:	6105                	addi	sp,sp,32
    80004740:	8082                	ret

0000000080004742 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004742:	1101                	addi	sp,sp,-32
    80004744:	ec06                	sd	ra,24(sp)
    80004746:	e822                	sd	s0,16(sp)
    80004748:	e426                	sd	s1,8(sp)
    8000474a:	e04a                	sd	s2,0(sp)
    8000474c:	1000                	addi	s0,sp,32
    8000474e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004750:	00850913          	addi	s2,a0,8
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	4c6080e7          	jalr	1222(ra) # 80000c1c <acquire>
  while (lk->locked) {
    8000475e:	409c                	lw	a5,0(s1)
    80004760:	cb89                	beqz	a5,80004772 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004762:	85ca                	mv	a1,s2
    80004764:	8526                	mv	a0,s1
    80004766:	ffffe097          	auipc	ra,0xffffe
    8000476a:	9fe080e7          	jalr	-1538(ra) # 80002164 <sleep>
  while (lk->locked) {
    8000476e:	409c                	lw	a5,0(s1)
    80004770:	fbed                	bnez	a5,80004762 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004772:	4785                	li	a5,1
    80004774:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004776:	ffffd097          	auipc	ra,0xffffd
    8000477a:	2c0080e7          	jalr	704(ra) # 80001a36 <myproc>
    8000477e:	30852783          	lw	a5,776(a0)
    80004782:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004784:	854a                	mv	a0,s2
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	54a080e7          	jalr	1354(ra) # 80000cd0 <release>
}
    8000478e:	60e2                	ld	ra,24(sp)
    80004790:	6442                	ld	s0,16(sp)
    80004792:	64a2                	ld	s1,8(sp)
    80004794:	6902                	ld	s2,0(sp)
    80004796:	6105                	addi	sp,sp,32
    80004798:	8082                	ret

000000008000479a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000479a:	1101                	addi	sp,sp,-32
    8000479c:	ec06                	sd	ra,24(sp)
    8000479e:	e822                	sd	s0,16(sp)
    800047a0:	e426                	sd	s1,8(sp)
    800047a2:	e04a                	sd	s2,0(sp)
    800047a4:	1000                	addi	s0,sp,32
    800047a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047a8:	00850913          	addi	s2,a0,8
    800047ac:	854a                	mv	a0,s2
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	46e080e7          	jalr	1134(ra) # 80000c1c <acquire>
  lk->locked = 0;
    800047b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047ba:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800047be:	8526                	mv	a0,s1
    800047c0:	ffffe097          	auipc	ra,0xffffe
    800047c4:	b48080e7          	jalr	-1208(ra) # 80002308 <wakeup>
  release(&lk->lk);
    800047c8:	854a                	mv	a0,s2
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	506080e7          	jalr	1286(ra) # 80000cd0 <release>
}
    800047d2:	60e2                	ld	ra,24(sp)
    800047d4:	6442                	ld	s0,16(sp)
    800047d6:	64a2                	ld	s1,8(sp)
    800047d8:	6902                	ld	s2,0(sp)
    800047da:	6105                	addi	sp,sp,32
    800047dc:	8082                	ret

00000000800047de <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047de:	7179                	addi	sp,sp,-48
    800047e0:	f406                	sd	ra,40(sp)
    800047e2:	f022                	sd	s0,32(sp)
    800047e4:	ec26                	sd	s1,24(sp)
    800047e6:	e84a                	sd	s2,16(sp)
    800047e8:	e44e                	sd	s3,8(sp)
    800047ea:	1800                	addi	s0,sp,48
    800047ec:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047ee:	00850913          	addi	s2,a0,8
    800047f2:	854a                	mv	a0,s2
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	428080e7          	jalr	1064(ra) # 80000c1c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047fc:	409c                	lw	a5,0(s1)
    800047fe:	ef99                	bnez	a5,8000481c <holdingsleep+0x3e>
    80004800:	4481                	li	s1,0
  release(&lk->lk);
    80004802:	854a                	mv	a0,s2
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	4cc080e7          	jalr	1228(ra) # 80000cd0 <release>
  return r;
}
    8000480c:	8526                	mv	a0,s1
    8000480e:	70a2                	ld	ra,40(sp)
    80004810:	7402                	ld	s0,32(sp)
    80004812:	64e2                	ld	s1,24(sp)
    80004814:	6942                	ld	s2,16(sp)
    80004816:	69a2                	ld	s3,8(sp)
    80004818:	6145                	addi	sp,sp,48
    8000481a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000481c:	0284a983          	lw	s3,40(s1)
    80004820:	ffffd097          	auipc	ra,0xffffd
    80004824:	216080e7          	jalr	534(ra) # 80001a36 <myproc>
    80004828:	30852483          	lw	s1,776(a0)
    8000482c:	413484b3          	sub	s1,s1,s3
    80004830:	0014b493          	seqz	s1,s1
    80004834:	b7f9                	j	80004802 <holdingsleep+0x24>

0000000080004836 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004836:	1141                	addi	sp,sp,-16
    80004838:	e406                	sd	ra,8(sp)
    8000483a:	e022                	sd	s0,0(sp)
    8000483c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000483e:	00004597          	auipc	a1,0x4
    80004842:	ea258593          	addi	a1,a1,-350 # 800086e0 <syscalls+0x258>
    80004846:	0002d517          	auipc	a0,0x2d
    8000484a:	18a50513          	addi	a0,a0,394 # 800319d0 <ftable>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	33e080e7          	jalr	830(ra) # 80000b8c <initlock>
}
    80004856:	60a2                	ld	ra,8(sp)
    80004858:	6402                	ld	s0,0(sp)
    8000485a:	0141                	addi	sp,sp,16
    8000485c:	8082                	ret

000000008000485e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000485e:	1101                	addi	sp,sp,-32
    80004860:	ec06                	sd	ra,24(sp)
    80004862:	e822                	sd	s0,16(sp)
    80004864:	e426                	sd	s1,8(sp)
    80004866:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004868:	0002d517          	auipc	a0,0x2d
    8000486c:	16850513          	addi	a0,a0,360 # 800319d0 <ftable>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	3ac080e7          	jalr	940(ra) # 80000c1c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004878:	0002d497          	auipc	s1,0x2d
    8000487c:	17048493          	addi	s1,s1,368 # 800319e8 <ftable+0x18>
    80004880:	0002e717          	auipc	a4,0x2e
    80004884:	10870713          	addi	a4,a4,264 # 80032988 <ftable+0xfb8>
    if(f->ref == 0){
    80004888:	40dc                	lw	a5,4(s1)
    8000488a:	cf99                	beqz	a5,800048a8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000488c:	02848493          	addi	s1,s1,40
    80004890:	fee49ce3          	bne	s1,a4,80004888 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004894:	0002d517          	auipc	a0,0x2d
    80004898:	13c50513          	addi	a0,a0,316 # 800319d0 <ftable>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	434080e7          	jalr	1076(ra) # 80000cd0 <release>
  return 0;
    800048a4:	4481                	li	s1,0
    800048a6:	a819                	j	800048bc <filealloc+0x5e>
      f->ref = 1;
    800048a8:	4785                	li	a5,1
    800048aa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048ac:	0002d517          	auipc	a0,0x2d
    800048b0:	12450513          	addi	a0,a0,292 # 800319d0 <ftable>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	41c080e7          	jalr	1052(ra) # 80000cd0 <release>
}
    800048bc:	8526                	mv	a0,s1
    800048be:	60e2                	ld	ra,24(sp)
    800048c0:	6442                	ld	s0,16(sp)
    800048c2:	64a2                	ld	s1,8(sp)
    800048c4:	6105                	addi	sp,sp,32
    800048c6:	8082                	ret

00000000800048c8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800048c8:	1101                	addi	sp,sp,-32
    800048ca:	ec06                	sd	ra,24(sp)
    800048cc:	e822                	sd	s0,16(sp)
    800048ce:	e426                	sd	s1,8(sp)
    800048d0:	1000                	addi	s0,sp,32
    800048d2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800048d4:	0002d517          	auipc	a0,0x2d
    800048d8:	0fc50513          	addi	a0,a0,252 # 800319d0 <ftable>
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	340080e7          	jalr	832(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    800048e4:	40dc                	lw	a5,4(s1)
    800048e6:	02f05263          	blez	a5,8000490a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048ea:	2785                	addiw	a5,a5,1
    800048ec:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048ee:	0002d517          	auipc	a0,0x2d
    800048f2:	0e250513          	addi	a0,a0,226 # 800319d0 <ftable>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	3da080e7          	jalr	986(ra) # 80000cd0 <release>
  return f;
}
    800048fe:	8526                	mv	a0,s1
    80004900:	60e2                	ld	ra,24(sp)
    80004902:	6442                	ld	s0,16(sp)
    80004904:	64a2                	ld	s1,8(sp)
    80004906:	6105                	addi	sp,sp,32
    80004908:	8082                	ret
    panic("filedup");
    8000490a:	00004517          	auipc	a0,0x4
    8000490e:	dde50513          	addi	a0,a0,-546 # 800086e8 <syscalls+0x260>
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	c2a080e7          	jalr	-982(ra) # 8000053c <panic>

000000008000491a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000491a:	7139                	addi	sp,sp,-64
    8000491c:	fc06                	sd	ra,56(sp)
    8000491e:	f822                	sd	s0,48(sp)
    80004920:	f426                	sd	s1,40(sp)
    80004922:	f04a                	sd	s2,32(sp)
    80004924:	ec4e                	sd	s3,24(sp)
    80004926:	e852                	sd	s4,16(sp)
    80004928:	e456                	sd	s5,8(sp)
    8000492a:	0080                	addi	s0,sp,64
    8000492c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000492e:	0002d517          	auipc	a0,0x2d
    80004932:	0a250513          	addi	a0,a0,162 # 800319d0 <ftable>
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	2e6080e7          	jalr	742(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    8000493e:	40dc                	lw	a5,4(s1)
    80004940:	06f05163          	blez	a5,800049a2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004944:	37fd                	addiw	a5,a5,-1
    80004946:	0007871b          	sext.w	a4,a5
    8000494a:	c0dc                	sw	a5,4(s1)
    8000494c:	06e04363          	bgtz	a4,800049b2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004950:	0004a903          	lw	s2,0(s1)
    80004954:	0094ca83          	lbu	s5,9(s1)
    80004958:	0104ba03          	ld	s4,16(s1)
    8000495c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004960:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004964:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004968:	0002d517          	auipc	a0,0x2d
    8000496c:	06850513          	addi	a0,a0,104 # 800319d0 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	360080e7          	jalr	864(ra) # 80000cd0 <release>

  if(ff.type == FD_PIPE){
    80004978:	4785                	li	a5,1
    8000497a:	04f90d63          	beq	s2,a5,800049d4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000497e:	3979                	addiw	s2,s2,-2
    80004980:	4785                	li	a5,1
    80004982:	0527e063          	bltu	a5,s2,800049c2 <fileclose+0xa8>
    begin_op();
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	ac8080e7          	jalr	-1336(ra) # 8000444e <begin_op>
    iput(ff.ip);
    8000498e:	854e                	mv	a0,s3
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	29c080e7          	jalr	668(ra) # 80003c2c <iput>
    end_op();
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	b34080e7          	jalr	-1228(ra) # 800044cc <end_op>
    800049a0:	a00d                	j	800049c2 <fileclose+0xa8>
    panic("fileclose");
    800049a2:	00004517          	auipc	a0,0x4
    800049a6:	d4e50513          	addi	a0,a0,-690 # 800086f0 <syscalls+0x268>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	b92080e7          	jalr	-1134(ra) # 8000053c <panic>
    release(&ftable.lock);
    800049b2:	0002d517          	auipc	a0,0x2d
    800049b6:	01e50513          	addi	a0,a0,30 # 800319d0 <ftable>
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	316080e7          	jalr	790(ra) # 80000cd0 <release>
  }
}
    800049c2:	70e2                	ld	ra,56(sp)
    800049c4:	7442                	ld	s0,48(sp)
    800049c6:	74a2                	ld	s1,40(sp)
    800049c8:	7902                	ld	s2,32(sp)
    800049ca:	69e2                	ld	s3,24(sp)
    800049cc:	6a42                	ld	s4,16(sp)
    800049ce:	6aa2                	ld	s5,8(sp)
    800049d0:	6121                	addi	sp,sp,64
    800049d2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800049d4:	85d6                	mv	a1,s5
    800049d6:	8552                	mv	a0,s4
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	34c080e7          	jalr	844(ra) # 80004d24 <pipeclose>
    800049e0:	b7cd                	j	800049c2 <fileclose+0xa8>

00000000800049e2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049e2:	715d                	addi	sp,sp,-80
    800049e4:	e486                	sd	ra,72(sp)
    800049e6:	e0a2                	sd	s0,64(sp)
    800049e8:	fc26                	sd	s1,56(sp)
    800049ea:	f84a                	sd	s2,48(sp)
    800049ec:	f44e                	sd	s3,40(sp)
    800049ee:	0880                	addi	s0,sp,80
    800049f0:	84aa                	mv	s1,a0
    800049f2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049f4:	ffffd097          	auipc	ra,0xffffd
    800049f8:	042080e7          	jalr	66(ra) # 80001a36 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049fc:	409c                	lw	a5,0(s1)
    800049fe:	37f9                	addiw	a5,a5,-2
    80004a00:	4705                	li	a4,1
    80004a02:	04f76763          	bltu	a4,a5,80004a50 <filestat+0x6e>
    80004a06:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a08:	6c88                	ld	a0,24(s1)
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	068080e7          	jalr	104(ra) # 80003a72 <ilock>
    stati(f->ip, &st);
    80004a12:	fb840593          	addi	a1,s0,-72
    80004a16:	6c88                	ld	a0,24(s1)
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	2e4080e7          	jalr	740(ra) # 80003cfc <stati>
    iunlock(f->ip);
    80004a20:	6c88                	ld	a0,24(s1)
    80004a22:	fffff097          	auipc	ra,0xfffff
    80004a26:	112080e7          	jalr	274(ra) # 80003b34 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a2a:	46e1                	li	a3,24
    80004a2c:	fb840613          	addi	a2,s0,-72
    80004a30:	85ce                	mv	a1,s3
    80004a32:	32893503          	ld	a0,808(s2)
    80004a36:	ffffd097          	auipc	ra,0xffffd
    80004a3a:	c46080e7          	jalr	-954(ra) # 8000167c <copyout>
    80004a3e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a42:	60a6                	ld	ra,72(sp)
    80004a44:	6406                	ld	s0,64(sp)
    80004a46:	74e2                	ld	s1,56(sp)
    80004a48:	7942                	ld	s2,48(sp)
    80004a4a:	79a2                	ld	s3,40(sp)
    80004a4c:	6161                	addi	sp,sp,80
    80004a4e:	8082                	ret
  return -1;
    80004a50:	557d                	li	a0,-1
    80004a52:	bfc5                	j	80004a42 <filestat+0x60>

0000000080004a54 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a54:	7179                	addi	sp,sp,-48
    80004a56:	f406                	sd	ra,40(sp)
    80004a58:	f022                	sd	s0,32(sp)
    80004a5a:	ec26                	sd	s1,24(sp)
    80004a5c:	e84a                	sd	s2,16(sp)
    80004a5e:	e44e                	sd	s3,8(sp)
    80004a60:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a62:	00854783          	lbu	a5,8(a0)
    80004a66:	c3d5                	beqz	a5,80004b0a <fileread+0xb6>
    80004a68:	84aa                	mv	s1,a0
    80004a6a:	89ae                	mv	s3,a1
    80004a6c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a6e:	411c                	lw	a5,0(a0)
    80004a70:	4705                	li	a4,1
    80004a72:	04e78963          	beq	a5,a4,80004ac4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a76:	470d                	li	a4,3
    80004a78:	04e78d63          	beq	a5,a4,80004ad2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a7c:	4709                	li	a4,2
    80004a7e:	06e79e63          	bne	a5,a4,80004afa <fileread+0xa6>
    ilock(f->ip);
    80004a82:	6d08                	ld	a0,24(a0)
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	fee080e7          	jalr	-18(ra) # 80003a72 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a8c:	874a                	mv	a4,s2
    80004a8e:	5094                	lw	a3,32(s1)
    80004a90:	864e                	mv	a2,s3
    80004a92:	4585                	li	a1,1
    80004a94:	6c88                	ld	a0,24(s1)
    80004a96:	fffff097          	auipc	ra,0xfffff
    80004a9a:	290080e7          	jalr	656(ra) # 80003d26 <readi>
    80004a9e:	892a                	mv	s2,a0
    80004aa0:	00a05563          	blez	a0,80004aaa <fileread+0x56>
      f->off += r;
    80004aa4:	509c                	lw	a5,32(s1)
    80004aa6:	9fa9                	addw	a5,a5,a0
    80004aa8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004aaa:	6c88                	ld	a0,24(s1)
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	088080e7          	jalr	136(ra) # 80003b34 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ab4:	854a                	mv	a0,s2
    80004ab6:	70a2                	ld	ra,40(sp)
    80004ab8:	7402                	ld	s0,32(sp)
    80004aba:	64e2                	ld	s1,24(sp)
    80004abc:	6942                	ld	s2,16(sp)
    80004abe:	69a2                	ld	s3,8(sp)
    80004ac0:	6145                	addi	sp,sp,48
    80004ac2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ac4:	6908                	ld	a0,16(a0)
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	3c0080e7          	jalr	960(ra) # 80004e86 <piperead>
    80004ace:	892a                	mv	s2,a0
    80004ad0:	b7d5                	j	80004ab4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ad2:	02451783          	lh	a5,36(a0)
    80004ad6:	03079693          	slli	a3,a5,0x30
    80004ada:	92c1                	srli	a3,a3,0x30
    80004adc:	4725                	li	a4,9
    80004ade:	02d76863          	bltu	a4,a3,80004b0e <fileread+0xba>
    80004ae2:	0792                	slli	a5,a5,0x4
    80004ae4:	0002d717          	auipc	a4,0x2d
    80004ae8:	e4c70713          	addi	a4,a4,-436 # 80031930 <devsw>
    80004aec:	97ba                	add	a5,a5,a4
    80004aee:	639c                	ld	a5,0(a5)
    80004af0:	c38d                	beqz	a5,80004b12 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004af2:	4505                	li	a0,1
    80004af4:	9782                	jalr	a5
    80004af6:	892a                	mv	s2,a0
    80004af8:	bf75                	j	80004ab4 <fileread+0x60>
    panic("fileread");
    80004afa:	00004517          	auipc	a0,0x4
    80004afe:	c0650513          	addi	a0,a0,-1018 # 80008700 <syscalls+0x278>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	a3a080e7          	jalr	-1478(ra) # 8000053c <panic>
    return -1;
    80004b0a:	597d                	li	s2,-1
    80004b0c:	b765                	j	80004ab4 <fileread+0x60>
      return -1;
    80004b0e:	597d                	li	s2,-1
    80004b10:	b755                	j	80004ab4 <fileread+0x60>
    80004b12:	597d                	li	s2,-1
    80004b14:	b745                	j	80004ab4 <fileread+0x60>

0000000080004b16 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b16:	715d                	addi	sp,sp,-80
    80004b18:	e486                	sd	ra,72(sp)
    80004b1a:	e0a2                	sd	s0,64(sp)
    80004b1c:	fc26                	sd	s1,56(sp)
    80004b1e:	f84a                	sd	s2,48(sp)
    80004b20:	f44e                	sd	s3,40(sp)
    80004b22:	f052                	sd	s4,32(sp)
    80004b24:	ec56                	sd	s5,24(sp)
    80004b26:	e85a                	sd	s6,16(sp)
    80004b28:	e45e                	sd	s7,8(sp)
    80004b2a:	e062                	sd	s8,0(sp)
    80004b2c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b2e:	00954783          	lbu	a5,9(a0)
    80004b32:	10078663          	beqz	a5,80004c3e <filewrite+0x128>
    80004b36:	892a                	mv	s2,a0
    80004b38:	8b2e                	mv	s6,a1
    80004b3a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b3c:	411c                	lw	a5,0(a0)
    80004b3e:	4705                	li	a4,1
    80004b40:	02e78263          	beq	a5,a4,80004b64 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b44:	470d                	li	a4,3
    80004b46:	02e78663          	beq	a5,a4,80004b72 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b4a:	4709                	li	a4,2
    80004b4c:	0ee79163          	bne	a5,a4,80004c2e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b50:	0ac05d63          	blez	a2,80004c0a <filewrite+0xf4>
    int i = 0;
    80004b54:	4981                	li	s3,0
    80004b56:	6b85                	lui	s7,0x1
    80004b58:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004b5c:	6c05                	lui	s8,0x1
    80004b5e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b62:	a861                	j	80004bfa <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b64:	6908                	ld	a0,16(a0)
    80004b66:	00000097          	auipc	ra,0x0
    80004b6a:	22e080e7          	jalr	558(ra) # 80004d94 <pipewrite>
    80004b6e:	8a2a                	mv	s4,a0
    80004b70:	a045                	j	80004c10 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b72:	02451783          	lh	a5,36(a0)
    80004b76:	03079693          	slli	a3,a5,0x30
    80004b7a:	92c1                	srli	a3,a3,0x30
    80004b7c:	4725                	li	a4,9
    80004b7e:	0cd76263          	bltu	a4,a3,80004c42 <filewrite+0x12c>
    80004b82:	0792                	slli	a5,a5,0x4
    80004b84:	0002d717          	auipc	a4,0x2d
    80004b88:	dac70713          	addi	a4,a4,-596 # 80031930 <devsw>
    80004b8c:	97ba                	add	a5,a5,a4
    80004b8e:	679c                	ld	a5,8(a5)
    80004b90:	cbdd                	beqz	a5,80004c46 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b92:	4505                	li	a0,1
    80004b94:	9782                	jalr	a5
    80004b96:	8a2a                	mv	s4,a0
    80004b98:	a8a5                	j	80004c10 <filewrite+0xfa>
    80004b9a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	8b0080e7          	jalr	-1872(ra) # 8000444e <begin_op>
      ilock(f->ip);
    80004ba6:	01893503          	ld	a0,24(s2)
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	ec8080e7          	jalr	-312(ra) # 80003a72 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004bb2:	8756                	mv	a4,s5
    80004bb4:	02092683          	lw	a3,32(s2)
    80004bb8:	01698633          	add	a2,s3,s6
    80004bbc:	4585                	li	a1,1
    80004bbe:	01893503          	ld	a0,24(s2)
    80004bc2:	fffff097          	auipc	ra,0xfffff
    80004bc6:	25c080e7          	jalr	604(ra) # 80003e1e <writei>
    80004bca:	84aa                	mv	s1,a0
    80004bcc:	00a05763          	blez	a0,80004bda <filewrite+0xc4>
        f->off += r;
    80004bd0:	02092783          	lw	a5,32(s2)
    80004bd4:	9fa9                	addw	a5,a5,a0
    80004bd6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004bda:	01893503          	ld	a0,24(s2)
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	f56080e7          	jalr	-170(ra) # 80003b34 <iunlock>
      end_op();
    80004be6:	00000097          	auipc	ra,0x0
    80004bea:	8e6080e7          	jalr	-1818(ra) # 800044cc <end_op>

      if(r != n1){
    80004bee:	009a9f63          	bne	s5,s1,80004c0c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004bf2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bf6:	0149db63          	bge	s3,s4,80004c0c <filewrite+0xf6>
      int n1 = n - i;
    80004bfa:	413a04bb          	subw	s1,s4,s3
    80004bfe:	0004879b          	sext.w	a5,s1
    80004c02:	f8fbdce3          	bge	s7,a5,80004b9a <filewrite+0x84>
    80004c06:	84e2                	mv	s1,s8
    80004c08:	bf49                	j	80004b9a <filewrite+0x84>
    int i = 0;
    80004c0a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c0c:	013a1f63          	bne	s4,s3,80004c2a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c10:	8552                	mv	a0,s4
    80004c12:	60a6                	ld	ra,72(sp)
    80004c14:	6406                	ld	s0,64(sp)
    80004c16:	74e2                	ld	s1,56(sp)
    80004c18:	7942                	ld	s2,48(sp)
    80004c1a:	79a2                	ld	s3,40(sp)
    80004c1c:	7a02                	ld	s4,32(sp)
    80004c1e:	6ae2                	ld	s5,24(sp)
    80004c20:	6b42                	ld	s6,16(sp)
    80004c22:	6ba2                	ld	s7,8(sp)
    80004c24:	6c02                	ld	s8,0(sp)
    80004c26:	6161                	addi	sp,sp,80
    80004c28:	8082                	ret
    ret = (i == n ? n : -1);
    80004c2a:	5a7d                	li	s4,-1
    80004c2c:	b7d5                	j	80004c10 <filewrite+0xfa>
    panic("filewrite");
    80004c2e:	00004517          	auipc	a0,0x4
    80004c32:	ae250513          	addi	a0,a0,-1310 # 80008710 <syscalls+0x288>
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	906080e7          	jalr	-1786(ra) # 8000053c <panic>
    return -1;
    80004c3e:	5a7d                	li	s4,-1
    80004c40:	bfc1                	j	80004c10 <filewrite+0xfa>
      return -1;
    80004c42:	5a7d                	li	s4,-1
    80004c44:	b7f1                	j	80004c10 <filewrite+0xfa>
    80004c46:	5a7d                	li	s4,-1
    80004c48:	b7e1                	j	80004c10 <filewrite+0xfa>

0000000080004c4a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c4a:	7179                	addi	sp,sp,-48
    80004c4c:	f406                	sd	ra,40(sp)
    80004c4e:	f022                	sd	s0,32(sp)
    80004c50:	ec26                	sd	s1,24(sp)
    80004c52:	e84a                	sd	s2,16(sp)
    80004c54:	e44e                	sd	s3,8(sp)
    80004c56:	e052                	sd	s4,0(sp)
    80004c58:	1800                	addi	s0,sp,48
    80004c5a:	84aa                	mv	s1,a0
    80004c5c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c5e:	0005b023          	sd	zero,0(a1)
    80004c62:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c66:	00000097          	auipc	ra,0x0
    80004c6a:	bf8080e7          	jalr	-1032(ra) # 8000485e <filealloc>
    80004c6e:	e088                	sd	a0,0(s1)
    80004c70:	c551                	beqz	a0,80004cfc <pipealloc+0xb2>
    80004c72:	00000097          	auipc	ra,0x0
    80004c76:	bec080e7          	jalr	-1044(ra) # 8000485e <filealloc>
    80004c7a:	00aa3023          	sd	a0,0(s4)
    80004c7e:	c92d                	beqz	a0,80004cf0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	e62080e7          	jalr	-414(ra) # 80000ae2 <kalloc>
    80004c88:	892a                	mv	s2,a0
    80004c8a:	c125                	beqz	a0,80004cea <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c8c:	4985                	li	s3,1
    80004c8e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c92:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c96:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c9a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c9e:	00004597          	auipc	a1,0x4
    80004ca2:	a8258593          	addi	a1,a1,-1406 # 80008720 <syscalls+0x298>
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	ee6080e7          	jalr	-282(ra) # 80000b8c <initlock>
  (*f0)->type = FD_PIPE;
    80004cae:	609c                	ld	a5,0(s1)
    80004cb0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004cb4:	609c                	ld	a5,0(s1)
    80004cb6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004cba:	609c                	ld	a5,0(s1)
    80004cbc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cc0:	609c                	ld	a5,0(s1)
    80004cc2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cc6:	000a3783          	ld	a5,0(s4)
    80004cca:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004cce:	000a3783          	ld	a5,0(s4)
    80004cd2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004cd6:	000a3783          	ld	a5,0(s4)
    80004cda:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004cde:	000a3783          	ld	a5,0(s4)
    80004ce2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ce6:	4501                	li	a0,0
    80004ce8:	a025                	j	80004d10 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cea:	6088                	ld	a0,0(s1)
    80004cec:	e501                	bnez	a0,80004cf4 <pipealloc+0xaa>
    80004cee:	a039                	j	80004cfc <pipealloc+0xb2>
    80004cf0:	6088                	ld	a0,0(s1)
    80004cf2:	c51d                	beqz	a0,80004d20 <pipealloc+0xd6>
    fileclose(*f0);
    80004cf4:	00000097          	auipc	ra,0x0
    80004cf8:	c26080e7          	jalr	-986(ra) # 8000491a <fileclose>
  if(*f1)
    80004cfc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d00:	557d                	li	a0,-1
  if(*f1)
    80004d02:	c799                	beqz	a5,80004d10 <pipealloc+0xc6>
    fileclose(*f1);
    80004d04:	853e                	mv	a0,a5
    80004d06:	00000097          	auipc	ra,0x0
    80004d0a:	c14080e7          	jalr	-1004(ra) # 8000491a <fileclose>
  return -1;
    80004d0e:	557d                	li	a0,-1
}
    80004d10:	70a2                	ld	ra,40(sp)
    80004d12:	7402                	ld	s0,32(sp)
    80004d14:	64e2                	ld	s1,24(sp)
    80004d16:	6942                	ld	s2,16(sp)
    80004d18:	69a2                	ld	s3,8(sp)
    80004d1a:	6a02                	ld	s4,0(sp)
    80004d1c:	6145                	addi	sp,sp,48
    80004d1e:	8082                	ret
  return -1;
    80004d20:	557d                	li	a0,-1
    80004d22:	b7fd                	j	80004d10 <pipealloc+0xc6>

0000000080004d24 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d24:	1101                	addi	sp,sp,-32
    80004d26:	ec06                	sd	ra,24(sp)
    80004d28:	e822                	sd	s0,16(sp)
    80004d2a:	e426                	sd	s1,8(sp)
    80004d2c:	e04a                	sd	s2,0(sp)
    80004d2e:	1000                	addi	s0,sp,32
    80004d30:	84aa                	mv	s1,a0
    80004d32:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	ee8080e7          	jalr	-280(ra) # 80000c1c <acquire>
  if(writable){
    80004d3c:	02090d63          	beqz	s2,80004d76 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d40:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d44:	21848513          	addi	a0,s1,536
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	5c0080e7          	jalr	1472(ra) # 80002308 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d50:	2204b783          	ld	a5,544(s1)
    80004d54:	eb95                	bnez	a5,80004d88 <pipeclose+0x64>
    release(&pi->lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	f78080e7          	jalr	-136(ra) # 80000cd0 <release>
    kfree((char*)pi);
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	c82080e7          	jalr	-894(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004d6a:	60e2                	ld	ra,24(sp)
    80004d6c:	6442                	ld	s0,16(sp)
    80004d6e:	64a2                	ld	s1,8(sp)
    80004d70:	6902                	ld	s2,0(sp)
    80004d72:	6105                	addi	sp,sp,32
    80004d74:	8082                	ret
    pi->readopen = 0;
    80004d76:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d7a:	21c48513          	addi	a0,s1,540
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	58a080e7          	jalr	1418(ra) # 80002308 <wakeup>
    80004d86:	b7e9                	j	80004d50 <pipeclose+0x2c>
    release(&pi->lock);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	f46080e7          	jalr	-186(ra) # 80000cd0 <release>
}
    80004d92:	bfe1                	j	80004d6a <pipeclose+0x46>

0000000080004d94 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d94:	711d                	addi	sp,sp,-96
    80004d96:	ec86                	sd	ra,88(sp)
    80004d98:	e8a2                	sd	s0,80(sp)
    80004d9a:	e4a6                	sd	s1,72(sp)
    80004d9c:	e0ca                	sd	s2,64(sp)
    80004d9e:	fc4e                	sd	s3,56(sp)
    80004da0:	f852                	sd	s4,48(sp)
    80004da2:	f456                	sd	s5,40(sp)
    80004da4:	f05a                	sd	s6,32(sp)
    80004da6:	ec5e                	sd	s7,24(sp)
    80004da8:	e862                	sd	s8,16(sp)
    80004daa:	1080                	addi	s0,sp,96
    80004dac:	84aa                	mv	s1,a0
    80004dae:	8aae                	mv	s5,a1
    80004db0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	c84080e7          	jalr	-892(ra) # 80001a36 <myproc>
    80004dba:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004dbc:	8526                	mv	a0,s1
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	e5e080e7          	jalr	-418(ra) # 80000c1c <acquire>
  while(i < n){
    80004dc6:	0b405363          	blez	s4,80004e6c <pipewrite+0xd8>
  int i = 0;
    80004dca:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dcc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004dce:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004dd2:	21c48b93          	addi	s7,s1,540
    80004dd6:	a089                	j	80004e18 <pipewrite+0x84>
      release(&pi->lock);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffc097          	auipc	ra,0xffffc
    80004dde:	ef6080e7          	jalr	-266(ra) # 80000cd0 <release>
      return -1;
    80004de2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004de4:	854a                	mv	a0,s2
    80004de6:	60e6                	ld	ra,88(sp)
    80004de8:	6446                	ld	s0,80(sp)
    80004dea:	64a6                	ld	s1,72(sp)
    80004dec:	6906                	ld	s2,64(sp)
    80004dee:	79e2                	ld	s3,56(sp)
    80004df0:	7a42                	ld	s4,48(sp)
    80004df2:	7aa2                	ld	s5,40(sp)
    80004df4:	7b02                	ld	s6,32(sp)
    80004df6:	6be2                	ld	s7,24(sp)
    80004df8:	6c42                	ld	s8,16(sp)
    80004dfa:	6125                	addi	sp,sp,96
    80004dfc:	8082                	ret
      wakeup(&pi->nread);
    80004dfe:	8562                	mv	a0,s8
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	508080e7          	jalr	1288(ra) # 80002308 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e08:	85a6                	mv	a1,s1
    80004e0a:	855e                	mv	a0,s7
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	358080e7          	jalr	856(ra) # 80002164 <sleep>
  while(i < n){
    80004e14:	05495d63          	bge	s2,s4,80004e6e <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004e18:	2204a783          	lw	a5,544(s1)
    80004e1c:	dfd5                	beqz	a5,80004dd8 <pipewrite+0x44>
    80004e1e:	3009a783          	lw	a5,768(s3)
    80004e22:	fbdd                	bnez	a5,80004dd8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e24:	2184a783          	lw	a5,536(s1)
    80004e28:	21c4a703          	lw	a4,540(s1)
    80004e2c:	2007879b          	addiw	a5,a5,512
    80004e30:	fcf707e3          	beq	a4,a5,80004dfe <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e34:	4685                	li	a3,1
    80004e36:	01590633          	add	a2,s2,s5
    80004e3a:	faf40593          	addi	a1,s0,-81
    80004e3e:	3289b503          	ld	a0,808(s3)
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	8c6080e7          	jalr	-1850(ra) # 80001708 <copyin>
    80004e4a:	03650263          	beq	a0,s6,80004e6e <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e4e:	21c4a783          	lw	a5,540(s1)
    80004e52:	0017871b          	addiw	a4,a5,1
    80004e56:	20e4ae23          	sw	a4,540(s1)
    80004e5a:	1ff7f793          	andi	a5,a5,511
    80004e5e:	97a6                	add	a5,a5,s1
    80004e60:	faf44703          	lbu	a4,-81(s0)
    80004e64:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e68:	2905                	addiw	s2,s2,1
    80004e6a:	b76d                	j	80004e14 <pipewrite+0x80>
  int i = 0;
    80004e6c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e6e:	21848513          	addi	a0,s1,536
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	496080e7          	jalr	1174(ra) # 80002308 <wakeup>
  release(&pi->lock);
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	e54080e7          	jalr	-428(ra) # 80000cd0 <release>
  return i;
    80004e84:	b785                	j	80004de4 <pipewrite+0x50>

0000000080004e86 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e86:	715d                	addi	sp,sp,-80
    80004e88:	e486                	sd	ra,72(sp)
    80004e8a:	e0a2                	sd	s0,64(sp)
    80004e8c:	fc26                	sd	s1,56(sp)
    80004e8e:	f84a                	sd	s2,48(sp)
    80004e90:	f44e                	sd	s3,40(sp)
    80004e92:	f052                	sd	s4,32(sp)
    80004e94:	ec56                	sd	s5,24(sp)
    80004e96:	e85a                	sd	s6,16(sp)
    80004e98:	0880                	addi	s0,sp,80
    80004e9a:	84aa                	mv	s1,a0
    80004e9c:	892e                	mv	s2,a1
    80004e9e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ea0:	ffffd097          	auipc	ra,0xffffd
    80004ea4:	b96080e7          	jalr	-1130(ra) # 80001a36 <myproc>
    80004ea8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004eaa:	8526                	mv	a0,s1
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	d70080e7          	jalr	-656(ra) # 80000c1c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eb4:	2184a703          	lw	a4,536(s1)
    80004eb8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ebc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ec0:	02f71463          	bne	a4,a5,80004ee8 <piperead+0x62>
    80004ec4:	2244a783          	lw	a5,548(s1)
    80004ec8:	c385                	beqz	a5,80004ee8 <piperead+0x62>
    if(pr->killed){
    80004eca:	300a2783          	lw	a5,768(s4)
    80004ece:	ebc9                	bnez	a5,80004f60 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ed0:	85a6                	mv	a1,s1
    80004ed2:	854e                	mv	a0,s3
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	290080e7          	jalr	656(ra) # 80002164 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004edc:	2184a703          	lw	a4,536(s1)
    80004ee0:	21c4a783          	lw	a5,540(s1)
    80004ee4:	fef700e3          	beq	a4,a5,80004ec4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ee8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eea:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eec:	05505463          	blez	s5,80004f34 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004ef0:	2184a783          	lw	a5,536(s1)
    80004ef4:	21c4a703          	lw	a4,540(s1)
    80004ef8:	02f70e63          	beq	a4,a5,80004f34 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004efc:	0017871b          	addiw	a4,a5,1
    80004f00:	20e4ac23          	sw	a4,536(s1)
    80004f04:	1ff7f793          	andi	a5,a5,511
    80004f08:	97a6                	add	a5,a5,s1
    80004f0a:	0187c783          	lbu	a5,24(a5)
    80004f0e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f12:	4685                	li	a3,1
    80004f14:	fbf40613          	addi	a2,s0,-65
    80004f18:	85ca                	mv	a1,s2
    80004f1a:	328a3503          	ld	a0,808(s4)
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	75e080e7          	jalr	1886(ra) # 8000167c <copyout>
    80004f26:	01650763          	beq	a0,s6,80004f34 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f2a:	2985                	addiw	s3,s3,1
    80004f2c:	0905                	addi	s2,s2,1
    80004f2e:	fd3a91e3          	bne	s5,s3,80004ef0 <piperead+0x6a>
    80004f32:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f34:	21c48513          	addi	a0,s1,540
    80004f38:	ffffd097          	auipc	ra,0xffffd
    80004f3c:	3d0080e7          	jalr	976(ra) # 80002308 <wakeup>
  release(&pi->lock);
    80004f40:	8526                	mv	a0,s1
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	d8e080e7          	jalr	-626(ra) # 80000cd0 <release>
  return i;
}
    80004f4a:	854e                	mv	a0,s3
    80004f4c:	60a6                	ld	ra,72(sp)
    80004f4e:	6406                	ld	s0,64(sp)
    80004f50:	74e2                	ld	s1,56(sp)
    80004f52:	7942                	ld	s2,48(sp)
    80004f54:	79a2                	ld	s3,40(sp)
    80004f56:	7a02                	ld	s4,32(sp)
    80004f58:	6ae2                	ld	s5,24(sp)
    80004f5a:	6b42                	ld	s6,16(sp)
    80004f5c:	6161                	addi	sp,sp,80
    80004f5e:	8082                	ret
      release(&pi->lock);
    80004f60:	8526                	mv	a0,s1
    80004f62:	ffffc097          	auipc	ra,0xffffc
    80004f66:	d6e080e7          	jalr	-658(ra) # 80000cd0 <release>
      return -1;
    80004f6a:	59fd                	li	s3,-1
    80004f6c:	bff9                	j	80004f4a <piperead+0xc4>

0000000080004f6e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f6e:	de010113          	addi	sp,sp,-544
    80004f72:	20113c23          	sd	ra,536(sp)
    80004f76:	20813823          	sd	s0,528(sp)
    80004f7a:	20913423          	sd	s1,520(sp)
    80004f7e:	21213023          	sd	s2,512(sp)
    80004f82:	ffce                	sd	s3,504(sp)
    80004f84:	fbd2                	sd	s4,496(sp)
    80004f86:	f7d6                	sd	s5,488(sp)
    80004f88:	f3da                	sd	s6,480(sp)
    80004f8a:	efde                	sd	s7,472(sp)
    80004f8c:	ebe2                	sd	s8,464(sp)
    80004f8e:	e7e6                	sd	s9,456(sp)
    80004f90:	e3ea                	sd	s10,448(sp)
    80004f92:	ff6e                	sd	s11,440(sp)
    80004f94:	1400                	addi	s0,sp,544
    80004f96:	892a                	mv	s2,a0
    80004f98:	dea43423          	sd	a0,-536(s0)
    80004f9c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	a96080e7          	jalr	-1386(ra) # 80001a36 <myproc>
    80004fa8:	84aa                	mv	s1,a0

  begin_op();
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	4a4080e7          	jalr	1188(ra) # 8000444e <begin_op>

  if((ip = namei(path)) == 0){
    80004fb2:	854a                	mv	a0,s2
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	27a080e7          	jalr	634(ra) # 8000422e <namei>
    80004fbc:	c93d                	beqz	a0,80005032 <exec+0xc4>
    80004fbe:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	ab2080e7          	jalr	-1358(ra) # 80003a72 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fc8:	04000713          	li	a4,64
    80004fcc:	4681                	li	a3,0
    80004fce:	e5040613          	addi	a2,s0,-432
    80004fd2:	4581                	li	a1,0
    80004fd4:	8556                	mv	a0,s5
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	d50080e7          	jalr	-688(ra) # 80003d26 <readi>
    80004fde:	04000793          	li	a5,64
    80004fe2:	00f51a63          	bne	a0,a5,80004ff6 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004fe6:	e5042703          	lw	a4,-432(s0)
    80004fea:	464c47b7          	lui	a5,0x464c4
    80004fee:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ff2:	04f70663          	beq	a4,a5,8000503e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ff6:	8556                	mv	a0,s5
    80004ff8:	fffff097          	auipc	ra,0xfffff
    80004ffc:	cdc080e7          	jalr	-804(ra) # 80003cd4 <iunlockput>
    end_op();
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	4cc080e7          	jalr	1228(ra) # 800044cc <end_op>
  }
  return -1;
    80005008:	557d                	li	a0,-1
}
    8000500a:	21813083          	ld	ra,536(sp)
    8000500e:	21013403          	ld	s0,528(sp)
    80005012:	20813483          	ld	s1,520(sp)
    80005016:	20013903          	ld	s2,512(sp)
    8000501a:	79fe                	ld	s3,504(sp)
    8000501c:	7a5e                	ld	s4,496(sp)
    8000501e:	7abe                	ld	s5,488(sp)
    80005020:	7b1e                	ld	s6,480(sp)
    80005022:	6bfe                	ld	s7,472(sp)
    80005024:	6c5e                	ld	s8,464(sp)
    80005026:	6cbe                	ld	s9,456(sp)
    80005028:	6d1e                	ld	s10,448(sp)
    8000502a:	7dfa                	ld	s11,440(sp)
    8000502c:	22010113          	addi	sp,sp,544
    80005030:	8082                	ret
    end_op();
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	49a080e7          	jalr	1178(ra) # 800044cc <end_op>
    return -1;
    8000503a:	557d                	li	a0,-1
    8000503c:	b7f9                	j	8000500a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000503e:	8526                	mv	a0,s1
    80005040:	ffffd097          	auipc	ra,0xffffd
    80005044:	abe080e7          	jalr	-1346(ra) # 80001afe <proc_pagetable>
    80005048:	8b2a                	mv	s6,a0
    8000504a:	d555                	beqz	a0,80004ff6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000504c:	e7042783          	lw	a5,-400(s0)
    80005050:	e8845703          	lhu	a4,-376(s0)
    80005054:	c735                	beqz	a4,800050c0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005056:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005058:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    8000505c:	6a05                	lui	s4,0x1
    8000505e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005062:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005066:	6d85                	lui	s11,0x1
    80005068:	7d7d                	lui	s10,0xfffff
    8000506a:	ac1d                	j	800052a0 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000506c:	00003517          	auipc	a0,0x3
    80005070:	6bc50513          	addi	a0,a0,1724 # 80008728 <syscalls+0x2a0>
    80005074:	ffffb097          	auipc	ra,0xffffb
    80005078:	4c8080e7          	jalr	1224(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000507c:	874a                	mv	a4,s2
    8000507e:	009c86bb          	addw	a3,s9,s1
    80005082:	4581                	li	a1,0
    80005084:	8556                	mv	a0,s5
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	ca0080e7          	jalr	-864(ra) # 80003d26 <readi>
    8000508e:	2501                	sext.w	a0,a0
    80005090:	1aa91863          	bne	s2,a0,80005240 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005094:	009d84bb          	addw	s1,s11,s1
    80005098:	013d09bb          	addw	s3,s10,s3
    8000509c:	1f74f263          	bgeu	s1,s7,80005280 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800050a0:	02049593          	slli	a1,s1,0x20
    800050a4:	9181                	srli	a1,a1,0x20
    800050a6:	95e2                	add	a1,a1,s8
    800050a8:	855a                	mv	a0,s6
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	ff4080e7          	jalr	-12(ra) # 8000109e <walkaddr>
    800050b2:	862a                	mv	a2,a0
    if(pa == 0)
    800050b4:	dd45                	beqz	a0,8000506c <exec+0xfe>
      n = PGSIZE;
    800050b6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800050b8:	fd49f2e3          	bgeu	s3,s4,8000507c <exec+0x10e>
      n = sz - i;
    800050bc:	894e                	mv	s2,s3
    800050be:	bf7d                	j	8000507c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050c0:	4481                	li	s1,0
  iunlockput(ip);
    800050c2:	8556                	mv	a0,s5
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	c10080e7          	jalr	-1008(ra) # 80003cd4 <iunlockput>
  end_op();
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	400080e7          	jalr	1024(ra) # 800044cc <end_op>
  p = myproc();
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	962080e7          	jalr	-1694(ra) # 80001a36 <myproc>
    800050dc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800050de:	32053d03          	ld	s10,800(a0)
  sz = PGROUNDUP(sz);
    800050e2:	6785                	lui	a5,0x1
    800050e4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800050e6:	97a6                	add	a5,a5,s1
    800050e8:	777d                	lui	a4,0xfffff
    800050ea:	8ff9                	and	a5,a5,a4
    800050ec:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050f0:	6609                	lui	a2,0x2
    800050f2:	963e                	add	a2,a2,a5
    800050f4:	85be                	mv	a1,a5
    800050f6:	855a                	mv	a0,s6
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	33c080e7          	jalr	828(ra) # 80001434 <uvmalloc>
    80005100:	8c2a                	mv	s8,a0
  ip = 0;
    80005102:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005104:	12050e63          	beqz	a0,80005240 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005108:	75f9                	lui	a1,0xffffe
    8000510a:	95aa                	add	a1,a1,a0
    8000510c:	855a                	mv	a0,s6
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	53c080e7          	jalr	1340(ra) # 8000164a <uvmclear>
  stackbase = sp - PGSIZE;
    80005116:	7afd                	lui	s5,0xfffff
    80005118:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000511a:	df043783          	ld	a5,-528(s0)
    8000511e:	6388                	ld	a0,0(a5)
    80005120:	c925                	beqz	a0,80005190 <exec+0x222>
    80005122:	e9040993          	addi	s3,s0,-368
    80005126:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000512a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000512c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	d66080e7          	jalr	-666(ra) # 80000e94 <strlen>
    80005136:	0015079b          	addiw	a5,a0,1
    8000513a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000513e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005142:	13596363          	bltu	s2,s5,80005268 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005146:	df043d83          	ld	s11,-528(s0)
    8000514a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000514e:	8552                	mv	a0,s4
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	d44080e7          	jalr	-700(ra) # 80000e94 <strlen>
    80005158:	0015069b          	addiw	a3,a0,1
    8000515c:	8652                	mv	a2,s4
    8000515e:	85ca                	mv	a1,s2
    80005160:	855a                	mv	a0,s6
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	51a080e7          	jalr	1306(ra) # 8000167c <copyout>
    8000516a:	10054363          	bltz	a0,80005270 <exec+0x302>
    ustack[argc] = sp;
    8000516e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005172:	0485                	addi	s1,s1,1
    80005174:	008d8793          	addi	a5,s11,8
    80005178:	def43823          	sd	a5,-528(s0)
    8000517c:	008db503          	ld	a0,8(s11)
    80005180:	c911                	beqz	a0,80005194 <exec+0x226>
    if(argc >= MAXARG)
    80005182:	09a1                	addi	s3,s3,8
    80005184:	fb3c95e3          	bne	s9,s3,8000512e <exec+0x1c0>
  sz = sz1;
    80005188:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000518c:	4a81                	li	s5,0
    8000518e:	a84d                	j	80005240 <exec+0x2d2>
  sp = sz;
    80005190:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005192:	4481                	li	s1,0
  ustack[argc] = 0;
    80005194:	00349793          	slli	a5,s1,0x3
    80005198:	f9078793          	addi	a5,a5,-112
    8000519c:	97a2                	add	a5,a5,s0
    8000519e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800051a2:	00148693          	addi	a3,s1,1
    800051a6:	068e                	slli	a3,a3,0x3
    800051a8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051ac:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051b0:	01597663          	bgeu	s2,s5,800051bc <exec+0x24e>
  sz = sz1;
    800051b4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051b8:	4a81                	li	s5,0
    800051ba:	a059                	j	80005240 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051bc:	e9040613          	addi	a2,s0,-368
    800051c0:	85ca                	mv	a1,s2
    800051c2:	855a                	mv	a0,s6
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	4b8080e7          	jalr	1208(ra) # 8000167c <copyout>
    800051cc:	0a054663          	bltz	a0,80005278 <exec+0x30a>
  p->trapframe->a1 = sp;
    800051d0:	330bb783          	ld	a5,816(s7)
    800051d4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051d8:	de843783          	ld	a5,-536(s0)
    800051dc:	0007c703          	lbu	a4,0(a5)
    800051e0:	cf11                	beqz	a4,800051fc <exec+0x28e>
    800051e2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051e4:	02f00693          	li	a3,47
    800051e8:	a039                	j	800051f6 <exec+0x288>
      last = s+1;
    800051ea:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051ee:	0785                	addi	a5,a5,1
    800051f0:	fff7c703          	lbu	a4,-1(a5)
    800051f4:	c701                	beqz	a4,800051fc <exec+0x28e>
    if(*s == '/')
    800051f6:	fed71ce3          	bne	a4,a3,800051ee <exec+0x280>
    800051fa:	bfc5                	j	800051ea <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800051fc:	4641                	li	a2,16
    800051fe:	de843583          	ld	a1,-536(s0)
    80005202:	430b8513          	addi	a0,s7,1072
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	c5c080e7          	jalr	-932(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    8000520e:	328bb503          	ld	a0,808(s7)
  p->pagetable = pagetable;
    80005212:	336bb423          	sd	s6,808(s7)
  p->sz = sz;
    80005216:	338bb023          	sd	s8,800(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000521a:	330bb783          	ld	a5,816(s7)
    8000521e:	e6843703          	ld	a4,-408(s0)
    80005222:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005224:	330bb783          	ld	a5,816(s7)
    80005228:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000522c:	85ea                	mv	a1,s10
    8000522e:	ffffd097          	auipc	ra,0xffffd
    80005232:	96c080e7          	jalr	-1684(ra) # 80001b9a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005236:	0004851b          	sext.w	a0,s1
    8000523a:	bbc1                	j	8000500a <exec+0x9c>
    8000523c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005240:	df843583          	ld	a1,-520(s0)
    80005244:	855a                	mv	a0,s6
    80005246:	ffffd097          	auipc	ra,0xffffd
    8000524a:	954080e7          	jalr	-1708(ra) # 80001b9a <proc_freepagetable>
  if(ip){
    8000524e:	da0a94e3          	bnez	s5,80004ff6 <exec+0x88>
  return -1;
    80005252:	557d                	li	a0,-1
    80005254:	bb5d                	j	8000500a <exec+0x9c>
    80005256:	de943c23          	sd	s1,-520(s0)
    8000525a:	b7dd                	j	80005240 <exec+0x2d2>
    8000525c:	de943c23          	sd	s1,-520(s0)
    80005260:	b7c5                	j	80005240 <exec+0x2d2>
    80005262:	de943c23          	sd	s1,-520(s0)
    80005266:	bfe9                	j	80005240 <exec+0x2d2>
  sz = sz1;
    80005268:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000526c:	4a81                	li	s5,0
    8000526e:	bfc9                	j	80005240 <exec+0x2d2>
  sz = sz1;
    80005270:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005274:	4a81                	li	s5,0
    80005276:	b7e9                	j	80005240 <exec+0x2d2>
  sz = sz1;
    80005278:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000527c:	4a81                	li	s5,0
    8000527e:	b7c9                	j	80005240 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005280:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005284:	e0843783          	ld	a5,-504(s0)
    80005288:	0017869b          	addiw	a3,a5,1
    8000528c:	e0d43423          	sd	a3,-504(s0)
    80005290:	e0043783          	ld	a5,-512(s0)
    80005294:	0387879b          	addiw	a5,a5,56
    80005298:	e8845703          	lhu	a4,-376(s0)
    8000529c:	e2e6d3e3          	bge	a3,a4,800050c2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052a0:	2781                	sext.w	a5,a5
    800052a2:	e0f43023          	sd	a5,-512(s0)
    800052a6:	03800713          	li	a4,56
    800052aa:	86be                	mv	a3,a5
    800052ac:	e1840613          	addi	a2,s0,-488
    800052b0:	4581                	li	a1,0
    800052b2:	8556                	mv	a0,s5
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	a72080e7          	jalr	-1422(ra) # 80003d26 <readi>
    800052bc:	03800793          	li	a5,56
    800052c0:	f6f51ee3          	bne	a0,a5,8000523c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800052c4:	e1842783          	lw	a5,-488(s0)
    800052c8:	4705                	li	a4,1
    800052ca:	fae79de3          	bne	a5,a4,80005284 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800052ce:	e4043603          	ld	a2,-448(s0)
    800052d2:	e3843783          	ld	a5,-456(s0)
    800052d6:	f8f660e3          	bltu	a2,a5,80005256 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052da:	e2843783          	ld	a5,-472(s0)
    800052de:	963e                	add	a2,a2,a5
    800052e0:	f6f66ee3          	bltu	a2,a5,8000525c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052e4:	85a6                	mv	a1,s1
    800052e6:	855a                	mv	a0,s6
    800052e8:	ffffc097          	auipc	ra,0xffffc
    800052ec:	14c080e7          	jalr	332(ra) # 80001434 <uvmalloc>
    800052f0:	dea43c23          	sd	a0,-520(s0)
    800052f4:	d53d                	beqz	a0,80005262 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    800052f6:	e2843c03          	ld	s8,-472(s0)
    800052fa:	de043783          	ld	a5,-544(s0)
    800052fe:	00fc77b3          	and	a5,s8,a5
    80005302:	ff9d                	bnez	a5,80005240 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005304:	e2042c83          	lw	s9,-480(s0)
    80005308:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000530c:	f60b8ae3          	beqz	s7,80005280 <exec+0x312>
    80005310:	89de                	mv	s3,s7
    80005312:	4481                	li	s1,0
    80005314:	b371                	j	800050a0 <exec+0x132>

0000000080005316 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005316:	7179                	addi	sp,sp,-48
    80005318:	f406                	sd	ra,40(sp)
    8000531a:	f022                	sd	s0,32(sp)
    8000531c:	ec26                	sd	s1,24(sp)
    8000531e:	e84a                	sd	s2,16(sp)
    80005320:	1800                	addi	s0,sp,48
    80005322:	892e                	mv	s2,a1
    80005324:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005326:	fdc40593          	addi	a1,s0,-36
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	b7c080e7          	jalr	-1156(ra) # 80002ea6 <argint>
    80005332:	04054063          	bltz	a0,80005372 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005336:	fdc42703          	lw	a4,-36(s0)
    8000533a:	47bd                	li	a5,15
    8000533c:	02e7ed63          	bltu	a5,a4,80005376 <argfd+0x60>
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	6f6080e7          	jalr	1782(ra) # 80001a36 <myproc>
    80005348:	fdc42703          	lw	a4,-36(s0)
    8000534c:	07470793          	addi	a5,a4,116 # fffffffffffff074 <end+0xffffffff7ffc9074>
    80005350:	078e                	slli	a5,a5,0x3
    80005352:	953e                	add	a0,a0,a5
    80005354:	651c                	ld	a5,8(a0)
    80005356:	c395                	beqz	a5,8000537a <argfd+0x64>
    return -1;
  if(pfd)
    80005358:	00090463          	beqz	s2,80005360 <argfd+0x4a>
    *pfd = fd;
    8000535c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005360:	4501                	li	a0,0
  if(pf)
    80005362:	c091                	beqz	s1,80005366 <argfd+0x50>
    *pf = f;
    80005364:	e09c                	sd	a5,0(s1)
}
    80005366:	70a2                	ld	ra,40(sp)
    80005368:	7402                	ld	s0,32(sp)
    8000536a:	64e2                	ld	s1,24(sp)
    8000536c:	6942                	ld	s2,16(sp)
    8000536e:	6145                	addi	sp,sp,48
    80005370:	8082                	ret
    return -1;
    80005372:	557d                	li	a0,-1
    80005374:	bfcd                	j	80005366 <argfd+0x50>
    return -1;
    80005376:	557d                	li	a0,-1
    80005378:	b7fd                	j	80005366 <argfd+0x50>
    8000537a:	557d                	li	a0,-1
    8000537c:	b7ed                	j	80005366 <argfd+0x50>

000000008000537e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000537e:	1101                	addi	sp,sp,-32
    80005380:	ec06                	sd	ra,24(sp)
    80005382:	e822                	sd	s0,16(sp)
    80005384:	e426                	sd	s1,8(sp)
    80005386:	1000                	addi	s0,sp,32
    80005388:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	6ac080e7          	jalr	1708(ra) # 80001a36 <myproc>
    80005392:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005394:	3a850793          	addi	a5,a0,936
    80005398:	4501                	li	a0,0
    8000539a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000539c:	6398                	ld	a4,0(a5)
    8000539e:	cb19                	beqz	a4,800053b4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053a0:	2505                	addiw	a0,a0,1
    800053a2:	07a1                	addi	a5,a5,8
    800053a4:	fed51ce3          	bne	a0,a3,8000539c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053a8:	557d                	li	a0,-1
}
    800053aa:	60e2                	ld	ra,24(sp)
    800053ac:	6442                	ld	s0,16(sp)
    800053ae:	64a2                	ld	s1,8(sp)
    800053b0:	6105                	addi	sp,sp,32
    800053b2:	8082                	ret
      p->ofile[fd] = f;
    800053b4:	07450793          	addi	a5,a0,116
    800053b8:	078e                	slli	a5,a5,0x3
    800053ba:	963e                	add	a2,a2,a5
    800053bc:	e604                	sd	s1,8(a2)
      return fd;
    800053be:	b7f5                	j	800053aa <fdalloc+0x2c>

00000000800053c0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053c0:	715d                	addi	sp,sp,-80
    800053c2:	e486                	sd	ra,72(sp)
    800053c4:	e0a2                	sd	s0,64(sp)
    800053c6:	fc26                	sd	s1,56(sp)
    800053c8:	f84a                	sd	s2,48(sp)
    800053ca:	f44e                	sd	s3,40(sp)
    800053cc:	f052                	sd	s4,32(sp)
    800053ce:	ec56                	sd	s5,24(sp)
    800053d0:	0880                	addi	s0,sp,80
    800053d2:	89ae                	mv	s3,a1
    800053d4:	8ab2                	mv	s5,a2
    800053d6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053d8:	fb040593          	addi	a1,s0,-80
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	e70080e7          	jalr	-400(ra) # 8000424c <nameiparent>
    800053e4:	892a                	mv	s2,a0
    800053e6:	12050e63          	beqz	a0,80005522 <create+0x162>
    return 0;

  ilock(dp);
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	688080e7          	jalr	1672(ra) # 80003a72 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053f2:	4601                	li	a2,0
    800053f4:	fb040593          	addi	a1,s0,-80
    800053f8:	854a                	mv	a0,s2
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	b5c080e7          	jalr	-1188(ra) # 80003f56 <dirlookup>
    80005402:	84aa                	mv	s1,a0
    80005404:	c921                	beqz	a0,80005454 <create+0x94>
    iunlockput(dp);
    80005406:	854a                	mv	a0,s2
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	8cc080e7          	jalr	-1844(ra) # 80003cd4 <iunlockput>
    ilock(ip);
    80005410:	8526                	mv	a0,s1
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	660080e7          	jalr	1632(ra) # 80003a72 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000541a:	2981                	sext.w	s3,s3
    8000541c:	4789                	li	a5,2
    8000541e:	02f99463          	bne	s3,a5,80005446 <create+0x86>
    80005422:	0444d783          	lhu	a5,68(s1)
    80005426:	37f9                	addiw	a5,a5,-2
    80005428:	17c2                	slli	a5,a5,0x30
    8000542a:	93c1                	srli	a5,a5,0x30
    8000542c:	4705                	li	a4,1
    8000542e:	00f76c63          	bltu	a4,a5,80005446 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005432:	8526                	mv	a0,s1
    80005434:	60a6                	ld	ra,72(sp)
    80005436:	6406                	ld	s0,64(sp)
    80005438:	74e2                	ld	s1,56(sp)
    8000543a:	7942                	ld	s2,48(sp)
    8000543c:	79a2                	ld	s3,40(sp)
    8000543e:	7a02                	ld	s4,32(sp)
    80005440:	6ae2                	ld	s5,24(sp)
    80005442:	6161                	addi	sp,sp,80
    80005444:	8082                	ret
    iunlockput(ip);
    80005446:	8526                	mv	a0,s1
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	88c080e7          	jalr	-1908(ra) # 80003cd4 <iunlockput>
    return 0;
    80005450:	4481                	li	s1,0
    80005452:	b7c5                	j	80005432 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005454:	85ce                	mv	a1,s3
    80005456:	00092503          	lw	a0,0(s2)
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	47e080e7          	jalr	1150(ra) # 800038d8 <ialloc>
    80005462:	84aa                	mv	s1,a0
    80005464:	c521                	beqz	a0,800054ac <create+0xec>
  ilock(ip);
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	60c080e7          	jalr	1548(ra) # 80003a72 <ilock>
  ip->major = major;
    8000546e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005472:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005476:	4a05                	li	s4,1
    80005478:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	528080e7          	jalr	1320(ra) # 800039a6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005486:	2981                	sext.w	s3,s3
    80005488:	03498a63          	beq	s3,s4,800054bc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000548c:	40d0                	lw	a2,4(s1)
    8000548e:	fb040593          	addi	a1,s0,-80
    80005492:	854a                	mv	a0,s2
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	cd8080e7          	jalr	-808(ra) # 8000416c <dirlink>
    8000549c:	06054b63          	bltz	a0,80005512 <create+0x152>
  iunlockput(dp);
    800054a0:	854a                	mv	a0,s2
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	832080e7          	jalr	-1998(ra) # 80003cd4 <iunlockput>
  return ip;
    800054aa:	b761                	j	80005432 <create+0x72>
    panic("create: ialloc");
    800054ac:	00003517          	auipc	a0,0x3
    800054b0:	29c50513          	addi	a0,a0,668 # 80008748 <syscalls+0x2c0>
    800054b4:	ffffb097          	auipc	ra,0xffffb
    800054b8:	088080e7          	jalr	136(ra) # 8000053c <panic>
    dp->nlink++;  // for ".."
    800054bc:	04a95783          	lhu	a5,74(s2)
    800054c0:	2785                	addiw	a5,a5,1
    800054c2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800054c6:	854a                	mv	a0,s2
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	4de080e7          	jalr	1246(ra) # 800039a6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054d0:	40d0                	lw	a2,4(s1)
    800054d2:	00003597          	auipc	a1,0x3
    800054d6:	28658593          	addi	a1,a1,646 # 80008758 <syscalls+0x2d0>
    800054da:	8526                	mv	a0,s1
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	c90080e7          	jalr	-880(ra) # 8000416c <dirlink>
    800054e4:	00054f63          	bltz	a0,80005502 <create+0x142>
    800054e8:	00492603          	lw	a2,4(s2)
    800054ec:	00003597          	auipc	a1,0x3
    800054f0:	27458593          	addi	a1,a1,628 # 80008760 <syscalls+0x2d8>
    800054f4:	8526                	mv	a0,s1
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	c76080e7          	jalr	-906(ra) # 8000416c <dirlink>
    800054fe:	f80557e3          	bgez	a0,8000548c <create+0xcc>
      panic("create dots");
    80005502:	00003517          	auipc	a0,0x3
    80005506:	26650513          	addi	a0,a0,614 # 80008768 <syscalls+0x2e0>
    8000550a:	ffffb097          	auipc	ra,0xffffb
    8000550e:	032080e7          	jalr	50(ra) # 8000053c <panic>
    panic("create: dirlink");
    80005512:	00003517          	auipc	a0,0x3
    80005516:	26650513          	addi	a0,a0,614 # 80008778 <syscalls+0x2f0>
    8000551a:	ffffb097          	auipc	ra,0xffffb
    8000551e:	022080e7          	jalr	34(ra) # 8000053c <panic>
    return 0;
    80005522:	84aa                	mv	s1,a0
    80005524:	b739                	j	80005432 <create+0x72>

0000000080005526 <sys_dup>:
{
    80005526:	7179                	addi	sp,sp,-48
    80005528:	f406                	sd	ra,40(sp)
    8000552a:	f022                	sd	s0,32(sp)
    8000552c:	ec26                	sd	s1,24(sp)
    8000552e:	e84a                	sd	s2,16(sp)
    80005530:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005532:	fd840613          	addi	a2,s0,-40
    80005536:	4581                	li	a1,0
    80005538:	4501                	li	a0,0
    8000553a:	00000097          	auipc	ra,0x0
    8000553e:	ddc080e7          	jalr	-548(ra) # 80005316 <argfd>
    return -1;
    80005542:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005544:	02054363          	bltz	a0,8000556a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005548:	fd843903          	ld	s2,-40(s0)
    8000554c:	854a                	mv	a0,s2
    8000554e:	00000097          	auipc	ra,0x0
    80005552:	e30080e7          	jalr	-464(ra) # 8000537e <fdalloc>
    80005556:	84aa                	mv	s1,a0
    return -1;
    80005558:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000555a:	00054863          	bltz	a0,8000556a <sys_dup+0x44>
  filedup(f);
    8000555e:	854a                	mv	a0,s2
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	368080e7          	jalr	872(ra) # 800048c8 <filedup>
  return fd;
    80005568:	87a6                	mv	a5,s1
}
    8000556a:	853e                	mv	a0,a5
    8000556c:	70a2                	ld	ra,40(sp)
    8000556e:	7402                	ld	s0,32(sp)
    80005570:	64e2                	ld	s1,24(sp)
    80005572:	6942                	ld	s2,16(sp)
    80005574:	6145                	addi	sp,sp,48
    80005576:	8082                	ret

0000000080005578 <sys_read>:
{
    80005578:	7179                	addi	sp,sp,-48
    8000557a:	f406                	sd	ra,40(sp)
    8000557c:	f022                	sd	s0,32(sp)
    8000557e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005580:	fe840613          	addi	a2,s0,-24
    80005584:	4581                	li	a1,0
    80005586:	4501                	li	a0,0
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	d8e080e7          	jalr	-626(ra) # 80005316 <argfd>
    return -1;
    80005590:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005592:	04054163          	bltz	a0,800055d4 <sys_read+0x5c>
    80005596:	fe440593          	addi	a1,s0,-28
    8000559a:	4509                	li	a0,2
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	90a080e7          	jalr	-1782(ra) # 80002ea6 <argint>
    return -1;
    800055a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a6:	02054763          	bltz	a0,800055d4 <sys_read+0x5c>
    800055aa:	fd840593          	addi	a1,s0,-40
    800055ae:	4505                	li	a0,1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	918080e7          	jalr	-1768(ra) # 80002ec8 <argaddr>
    return -1;
    800055b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ba:	00054d63          	bltz	a0,800055d4 <sys_read+0x5c>
  return fileread(f, p, n);
    800055be:	fe442603          	lw	a2,-28(s0)
    800055c2:	fd843583          	ld	a1,-40(s0)
    800055c6:	fe843503          	ld	a0,-24(s0)
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	48a080e7          	jalr	1162(ra) # 80004a54 <fileread>
    800055d2:	87aa                	mv	a5,a0
}
    800055d4:	853e                	mv	a0,a5
    800055d6:	70a2                	ld	ra,40(sp)
    800055d8:	7402                	ld	s0,32(sp)
    800055da:	6145                	addi	sp,sp,48
    800055dc:	8082                	ret

00000000800055de <sys_write>:
{
    800055de:	7179                	addi	sp,sp,-48
    800055e0:	f406                	sd	ra,40(sp)
    800055e2:	f022                	sd	s0,32(sp)
    800055e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055e6:	fe840613          	addi	a2,s0,-24
    800055ea:	4581                	li	a1,0
    800055ec:	4501                	li	a0,0
    800055ee:	00000097          	auipc	ra,0x0
    800055f2:	d28080e7          	jalr	-728(ra) # 80005316 <argfd>
    return -1;
    800055f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055f8:	04054163          	bltz	a0,8000563a <sys_write+0x5c>
    800055fc:	fe440593          	addi	a1,s0,-28
    80005600:	4509                	li	a0,2
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	8a4080e7          	jalr	-1884(ra) # 80002ea6 <argint>
    return -1;
    8000560a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000560c:	02054763          	bltz	a0,8000563a <sys_write+0x5c>
    80005610:	fd840593          	addi	a1,s0,-40
    80005614:	4505                	li	a0,1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	8b2080e7          	jalr	-1870(ra) # 80002ec8 <argaddr>
    return -1;
    8000561e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005620:	00054d63          	bltz	a0,8000563a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005624:	fe442603          	lw	a2,-28(s0)
    80005628:	fd843583          	ld	a1,-40(s0)
    8000562c:	fe843503          	ld	a0,-24(s0)
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	4e6080e7          	jalr	1254(ra) # 80004b16 <filewrite>
    80005638:	87aa                	mv	a5,a0
}
    8000563a:	853e                	mv	a0,a5
    8000563c:	70a2                	ld	ra,40(sp)
    8000563e:	7402                	ld	s0,32(sp)
    80005640:	6145                	addi	sp,sp,48
    80005642:	8082                	ret

0000000080005644 <sys_close>:
{
    80005644:	1101                	addi	sp,sp,-32
    80005646:	ec06                	sd	ra,24(sp)
    80005648:	e822                	sd	s0,16(sp)
    8000564a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000564c:	fe040613          	addi	a2,s0,-32
    80005650:	fec40593          	addi	a1,s0,-20
    80005654:	4501                	li	a0,0
    80005656:	00000097          	auipc	ra,0x0
    8000565a:	cc0080e7          	jalr	-832(ra) # 80005316 <argfd>
    return -1;
    8000565e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005660:	02054563          	bltz	a0,8000568a <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005664:	ffffc097          	auipc	ra,0xffffc
    80005668:	3d2080e7          	jalr	978(ra) # 80001a36 <myproc>
    8000566c:	fec42783          	lw	a5,-20(s0)
    80005670:	07478793          	addi	a5,a5,116
    80005674:	078e                	slli	a5,a5,0x3
    80005676:	953e                	add	a0,a0,a5
    80005678:	00053423          	sd	zero,8(a0)
  fileclose(f);
    8000567c:	fe043503          	ld	a0,-32(s0)
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	29a080e7          	jalr	666(ra) # 8000491a <fileclose>
  return 0;
    80005688:	4781                	li	a5,0
}
    8000568a:	853e                	mv	a0,a5
    8000568c:	60e2                	ld	ra,24(sp)
    8000568e:	6442                	ld	s0,16(sp)
    80005690:	6105                	addi	sp,sp,32
    80005692:	8082                	ret

0000000080005694 <sys_fstat>:
{
    80005694:	1101                	addi	sp,sp,-32
    80005696:	ec06                	sd	ra,24(sp)
    80005698:	e822                	sd	s0,16(sp)
    8000569a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000569c:	fe840613          	addi	a2,s0,-24
    800056a0:	4581                	li	a1,0
    800056a2:	4501                	li	a0,0
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	c72080e7          	jalr	-910(ra) # 80005316 <argfd>
    return -1;
    800056ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056ae:	02054563          	bltz	a0,800056d8 <sys_fstat+0x44>
    800056b2:	fe040593          	addi	a1,s0,-32
    800056b6:	4505                	li	a0,1
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	810080e7          	jalr	-2032(ra) # 80002ec8 <argaddr>
    return -1;
    800056c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056c2:	00054b63          	bltz	a0,800056d8 <sys_fstat+0x44>
  return filestat(f, st);
    800056c6:	fe043583          	ld	a1,-32(s0)
    800056ca:	fe843503          	ld	a0,-24(s0)
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	314080e7          	jalr	788(ra) # 800049e2 <filestat>
    800056d6:	87aa                	mv	a5,a0
}
    800056d8:	853e                	mv	a0,a5
    800056da:	60e2                	ld	ra,24(sp)
    800056dc:	6442                	ld	s0,16(sp)
    800056de:	6105                	addi	sp,sp,32
    800056e0:	8082                	ret

00000000800056e2 <sys_link>:
{
    800056e2:	7169                	addi	sp,sp,-304
    800056e4:	f606                	sd	ra,296(sp)
    800056e6:	f222                	sd	s0,288(sp)
    800056e8:	ee26                	sd	s1,280(sp)
    800056ea:	ea4a                	sd	s2,272(sp)
    800056ec:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ee:	08000613          	li	a2,128
    800056f2:	ed040593          	addi	a1,s0,-304
    800056f6:	4501                	li	a0,0
    800056f8:	ffffd097          	auipc	ra,0xffffd
    800056fc:	7f2080e7          	jalr	2034(ra) # 80002eea <argstr>
    return -1;
    80005700:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005702:	10054e63          	bltz	a0,8000581e <sys_link+0x13c>
    80005706:	08000613          	li	a2,128
    8000570a:	f5040593          	addi	a1,s0,-176
    8000570e:	4505                	li	a0,1
    80005710:	ffffd097          	auipc	ra,0xffffd
    80005714:	7da080e7          	jalr	2010(ra) # 80002eea <argstr>
    return -1;
    80005718:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000571a:	10054263          	bltz	a0,8000581e <sys_link+0x13c>
  begin_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	d30080e7          	jalr	-720(ra) # 8000444e <begin_op>
  if((ip = namei(old)) == 0){
    80005726:	ed040513          	addi	a0,s0,-304
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	b04080e7          	jalr	-1276(ra) # 8000422e <namei>
    80005732:	84aa                	mv	s1,a0
    80005734:	c551                	beqz	a0,800057c0 <sys_link+0xde>
  ilock(ip);
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	33c080e7          	jalr	828(ra) # 80003a72 <ilock>
  if(ip->type == T_DIR){
    8000573e:	04449703          	lh	a4,68(s1)
    80005742:	4785                	li	a5,1
    80005744:	08f70463          	beq	a4,a5,800057cc <sys_link+0xea>
  ip->nlink++;
    80005748:	04a4d783          	lhu	a5,74(s1)
    8000574c:	2785                	addiw	a5,a5,1
    8000574e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	252080e7          	jalr	594(ra) # 800039a6 <iupdate>
  iunlock(ip);
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	3d6080e7          	jalr	982(ra) # 80003b34 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005766:	fd040593          	addi	a1,s0,-48
    8000576a:	f5040513          	addi	a0,s0,-176
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	ade080e7          	jalr	-1314(ra) # 8000424c <nameiparent>
    80005776:	892a                	mv	s2,a0
    80005778:	c935                	beqz	a0,800057ec <sys_link+0x10a>
  ilock(dp);
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	2f8080e7          	jalr	760(ra) # 80003a72 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005782:	00092703          	lw	a4,0(s2)
    80005786:	409c                	lw	a5,0(s1)
    80005788:	04f71d63          	bne	a4,a5,800057e2 <sys_link+0x100>
    8000578c:	40d0                	lw	a2,4(s1)
    8000578e:	fd040593          	addi	a1,s0,-48
    80005792:	854a                	mv	a0,s2
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	9d8080e7          	jalr	-1576(ra) # 8000416c <dirlink>
    8000579c:	04054363          	bltz	a0,800057e2 <sys_link+0x100>
  iunlockput(dp);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	532080e7          	jalr	1330(ra) # 80003cd4 <iunlockput>
  iput(ip);
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	480080e7          	jalr	1152(ra) # 80003c2c <iput>
  end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	d18080e7          	jalr	-744(ra) # 800044cc <end_op>
  return 0;
    800057bc:	4781                	li	a5,0
    800057be:	a085                	j	8000581e <sys_link+0x13c>
    end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	d0c080e7          	jalr	-756(ra) # 800044cc <end_op>
    return -1;
    800057c8:	57fd                	li	a5,-1
    800057ca:	a891                	j	8000581e <sys_link+0x13c>
    iunlockput(ip);
    800057cc:	8526                	mv	a0,s1
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	506080e7          	jalr	1286(ra) # 80003cd4 <iunlockput>
    end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	cf6080e7          	jalr	-778(ra) # 800044cc <end_op>
    return -1;
    800057de:	57fd                	li	a5,-1
    800057e0:	a83d                	j	8000581e <sys_link+0x13c>
    iunlockput(dp);
    800057e2:	854a                	mv	a0,s2
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	4f0080e7          	jalr	1264(ra) # 80003cd4 <iunlockput>
  ilock(ip);
    800057ec:	8526                	mv	a0,s1
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	284080e7          	jalr	644(ra) # 80003a72 <ilock>
  ip->nlink--;
    800057f6:	04a4d783          	lhu	a5,74(s1)
    800057fa:	37fd                	addiw	a5,a5,-1
    800057fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	1a4080e7          	jalr	420(ra) # 800039a6 <iupdate>
  iunlockput(ip);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	4c8080e7          	jalr	1224(ra) # 80003cd4 <iunlockput>
  end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	cb8080e7          	jalr	-840(ra) # 800044cc <end_op>
  return -1;
    8000581c:	57fd                	li	a5,-1
}
    8000581e:	853e                	mv	a0,a5
    80005820:	70b2                	ld	ra,296(sp)
    80005822:	7412                	ld	s0,288(sp)
    80005824:	64f2                	ld	s1,280(sp)
    80005826:	6952                	ld	s2,272(sp)
    80005828:	6155                	addi	sp,sp,304
    8000582a:	8082                	ret

000000008000582c <sys_unlink>:
{
    8000582c:	7151                	addi	sp,sp,-240
    8000582e:	f586                	sd	ra,232(sp)
    80005830:	f1a2                	sd	s0,224(sp)
    80005832:	eda6                	sd	s1,216(sp)
    80005834:	e9ca                	sd	s2,208(sp)
    80005836:	e5ce                	sd	s3,200(sp)
    80005838:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000583a:	08000613          	li	a2,128
    8000583e:	f3040593          	addi	a1,s0,-208
    80005842:	4501                	li	a0,0
    80005844:	ffffd097          	auipc	ra,0xffffd
    80005848:	6a6080e7          	jalr	1702(ra) # 80002eea <argstr>
    8000584c:	18054163          	bltz	a0,800059ce <sys_unlink+0x1a2>
  begin_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	bfe080e7          	jalr	-1026(ra) # 8000444e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005858:	fb040593          	addi	a1,s0,-80
    8000585c:	f3040513          	addi	a0,s0,-208
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	9ec080e7          	jalr	-1556(ra) # 8000424c <nameiparent>
    80005868:	84aa                	mv	s1,a0
    8000586a:	c979                	beqz	a0,80005940 <sys_unlink+0x114>
  ilock(dp);
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	206080e7          	jalr	518(ra) # 80003a72 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005874:	00003597          	auipc	a1,0x3
    80005878:	ee458593          	addi	a1,a1,-284 # 80008758 <syscalls+0x2d0>
    8000587c:	fb040513          	addi	a0,s0,-80
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	6bc080e7          	jalr	1724(ra) # 80003f3c <namecmp>
    80005888:	14050a63          	beqz	a0,800059dc <sys_unlink+0x1b0>
    8000588c:	00003597          	auipc	a1,0x3
    80005890:	ed458593          	addi	a1,a1,-300 # 80008760 <syscalls+0x2d8>
    80005894:	fb040513          	addi	a0,s0,-80
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	6a4080e7          	jalr	1700(ra) # 80003f3c <namecmp>
    800058a0:	12050e63          	beqz	a0,800059dc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058a4:	f2c40613          	addi	a2,s0,-212
    800058a8:	fb040593          	addi	a1,s0,-80
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	6a8080e7          	jalr	1704(ra) # 80003f56 <dirlookup>
    800058b6:	892a                	mv	s2,a0
    800058b8:	12050263          	beqz	a0,800059dc <sys_unlink+0x1b0>
  ilock(ip);
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	1b6080e7          	jalr	438(ra) # 80003a72 <ilock>
  if(ip->nlink < 1)
    800058c4:	04a91783          	lh	a5,74(s2)
    800058c8:	08f05263          	blez	a5,8000594c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058cc:	04491703          	lh	a4,68(s2)
    800058d0:	4785                	li	a5,1
    800058d2:	08f70563          	beq	a4,a5,8000595c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058d6:	4641                	li	a2,16
    800058d8:	4581                	li	a1,0
    800058da:	fc040513          	addi	a0,s0,-64
    800058de:	ffffb097          	auipc	ra,0xffffb
    800058e2:	43a080e7          	jalr	1082(ra) # 80000d18 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058e6:	4741                	li	a4,16
    800058e8:	f2c42683          	lw	a3,-212(s0)
    800058ec:	fc040613          	addi	a2,s0,-64
    800058f0:	4581                	li	a1,0
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	52a080e7          	jalr	1322(ra) # 80003e1e <writei>
    800058fc:	47c1                	li	a5,16
    800058fe:	0af51563          	bne	a0,a5,800059a8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005902:	04491703          	lh	a4,68(s2)
    80005906:	4785                	li	a5,1
    80005908:	0af70863          	beq	a4,a5,800059b8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	3c6080e7          	jalr	966(ra) # 80003cd4 <iunlockput>
  ip->nlink--;
    80005916:	04a95783          	lhu	a5,74(s2)
    8000591a:	37fd                	addiw	a5,a5,-1
    8000591c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005920:	854a                	mv	a0,s2
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	084080e7          	jalr	132(ra) # 800039a6 <iupdate>
  iunlockput(ip);
    8000592a:	854a                	mv	a0,s2
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	3a8080e7          	jalr	936(ra) # 80003cd4 <iunlockput>
  end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	b98080e7          	jalr	-1128(ra) # 800044cc <end_op>
  return 0;
    8000593c:	4501                	li	a0,0
    8000593e:	a84d                	j	800059f0 <sys_unlink+0x1c4>
    end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	b8c080e7          	jalr	-1140(ra) # 800044cc <end_op>
    return -1;
    80005948:	557d                	li	a0,-1
    8000594a:	a05d                	j	800059f0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000594c:	00003517          	auipc	a0,0x3
    80005950:	e3c50513          	addi	a0,a0,-452 # 80008788 <syscalls+0x300>
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	be8080e7          	jalr	-1048(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000595c:	04c92703          	lw	a4,76(s2)
    80005960:	02000793          	li	a5,32
    80005964:	f6e7f9e3          	bgeu	a5,a4,800058d6 <sys_unlink+0xaa>
    80005968:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000596c:	4741                	li	a4,16
    8000596e:	86ce                	mv	a3,s3
    80005970:	f1840613          	addi	a2,s0,-232
    80005974:	4581                	li	a1,0
    80005976:	854a                	mv	a0,s2
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	3ae080e7          	jalr	942(ra) # 80003d26 <readi>
    80005980:	47c1                	li	a5,16
    80005982:	00f51b63          	bne	a0,a5,80005998 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005986:	f1845783          	lhu	a5,-232(s0)
    8000598a:	e7a1                	bnez	a5,800059d2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000598c:	29c1                	addiw	s3,s3,16
    8000598e:	04c92783          	lw	a5,76(s2)
    80005992:	fcf9ede3          	bltu	s3,a5,8000596c <sys_unlink+0x140>
    80005996:	b781                	j	800058d6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005998:	00003517          	auipc	a0,0x3
    8000599c:	e0850513          	addi	a0,a0,-504 # 800087a0 <syscalls+0x318>
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	b9c080e7          	jalr	-1124(ra) # 8000053c <panic>
    panic("unlink: writei");
    800059a8:	00003517          	auipc	a0,0x3
    800059ac:	e1050513          	addi	a0,a0,-496 # 800087b8 <syscalls+0x330>
    800059b0:	ffffb097          	auipc	ra,0xffffb
    800059b4:	b8c080e7          	jalr	-1140(ra) # 8000053c <panic>
    dp->nlink--;
    800059b8:	04a4d783          	lhu	a5,74(s1)
    800059bc:	37fd                	addiw	a5,a5,-1
    800059be:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059c2:	8526                	mv	a0,s1
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	fe2080e7          	jalr	-30(ra) # 800039a6 <iupdate>
    800059cc:	b781                	j	8000590c <sys_unlink+0xe0>
    return -1;
    800059ce:	557d                	li	a0,-1
    800059d0:	a005                	j	800059f0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800059d2:	854a                	mv	a0,s2
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	300080e7          	jalr	768(ra) # 80003cd4 <iunlockput>
  iunlockput(dp);
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	2f6080e7          	jalr	758(ra) # 80003cd4 <iunlockput>
  end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	ae6080e7          	jalr	-1306(ra) # 800044cc <end_op>
  return -1;
    800059ee:	557d                	li	a0,-1
}
    800059f0:	70ae                	ld	ra,232(sp)
    800059f2:	740e                	ld	s0,224(sp)
    800059f4:	64ee                	ld	s1,216(sp)
    800059f6:	694e                	ld	s2,208(sp)
    800059f8:	69ae                	ld	s3,200(sp)
    800059fa:	616d                	addi	sp,sp,240
    800059fc:	8082                	ret

00000000800059fe <sys_open>:

uint64
sys_open(void)
{
    800059fe:	7131                	addi	sp,sp,-192
    80005a00:	fd06                	sd	ra,184(sp)
    80005a02:	f922                	sd	s0,176(sp)
    80005a04:	f526                	sd	s1,168(sp)
    80005a06:	f14a                	sd	s2,160(sp)
    80005a08:	ed4e                	sd	s3,152(sp)
    80005a0a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a0c:	08000613          	li	a2,128
    80005a10:	f5040593          	addi	a1,s0,-176
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	4d4080e7          	jalr	1236(ra) # 80002eea <argstr>
    return -1;
    80005a1e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a20:	0c054163          	bltz	a0,80005ae2 <sys_open+0xe4>
    80005a24:	f4c40593          	addi	a1,s0,-180
    80005a28:	4505                	li	a0,1
    80005a2a:	ffffd097          	auipc	ra,0xffffd
    80005a2e:	47c080e7          	jalr	1148(ra) # 80002ea6 <argint>
    80005a32:	0a054863          	bltz	a0,80005ae2 <sys_open+0xe4>

  begin_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	a18080e7          	jalr	-1512(ra) # 8000444e <begin_op>

  if(omode & O_CREATE){
    80005a3e:	f4c42783          	lw	a5,-180(s0)
    80005a42:	2007f793          	andi	a5,a5,512
    80005a46:	cbdd                	beqz	a5,80005afc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a48:	4681                	li	a3,0
    80005a4a:	4601                	li	a2,0
    80005a4c:	4589                	li	a1,2
    80005a4e:	f5040513          	addi	a0,s0,-176
    80005a52:	00000097          	auipc	ra,0x0
    80005a56:	96e080e7          	jalr	-1682(ra) # 800053c0 <create>
    80005a5a:	892a                	mv	s2,a0
    if(ip == 0){
    80005a5c:	c959                	beqz	a0,80005af2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a5e:	04491703          	lh	a4,68(s2)
    80005a62:	478d                	li	a5,3
    80005a64:	00f71763          	bne	a4,a5,80005a72 <sys_open+0x74>
    80005a68:	04695703          	lhu	a4,70(s2)
    80005a6c:	47a5                	li	a5,9
    80005a6e:	0ce7ec63          	bltu	a5,a4,80005b46 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	dec080e7          	jalr	-532(ra) # 8000485e <filealloc>
    80005a7a:	89aa                	mv	s3,a0
    80005a7c:	10050263          	beqz	a0,80005b80 <sys_open+0x182>
    80005a80:	00000097          	auipc	ra,0x0
    80005a84:	8fe080e7          	jalr	-1794(ra) # 8000537e <fdalloc>
    80005a88:	84aa                	mv	s1,a0
    80005a8a:	0e054663          	bltz	a0,80005b76 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a8e:	04491703          	lh	a4,68(s2)
    80005a92:	478d                	li	a5,3
    80005a94:	0cf70463          	beq	a4,a5,80005b5c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a98:	4789                	li	a5,2
    80005a9a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a9e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005aa2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005aa6:	f4c42783          	lw	a5,-180(s0)
    80005aaa:	0017c713          	xori	a4,a5,1
    80005aae:	8b05                	andi	a4,a4,1
    80005ab0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ab4:	0037f713          	andi	a4,a5,3
    80005ab8:	00e03733          	snez	a4,a4
    80005abc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ac0:	4007f793          	andi	a5,a5,1024
    80005ac4:	c791                	beqz	a5,80005ad0 <sys_open+0xd2>
    80005ac6:	04491703          	lh	a4,68(s2)
    80005aca:	4789                	li	a5,2
    80005acc:	08f70f63          	beq	a4,a5,80005b6a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ad0:	854a                	mv	a0,s2
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	062080e7          	jalr	98(ra) # 80003b34 <iunlock>
  end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	9f2080e7          	jalr	-1550(ra) # 800044cc <end_op>

  return fd;
}
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	70ea                	ld	ra,184(sp)
    80005ae6:	744a                	ld	s0,176(sp)
    80005ae8:	74aa                	ld	s1,168(sp)
    80005aea:	790a                	ld	s2,160(sp)
    80005aec:	69ea                	ld	s3,152(sp)
    80005aee:	6129                	addi	sp,sp,192
    80005af0:	8082                	ret
      end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	9da080e7          	jalr	-1574(ra) # 800044cc <end_op>
      return -1;
    80005afa:	b7e5                	j	80005ae2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005afc:	f5040513          	addi	a0,s0,-176
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	72e080e7          	jalr	1838(ra) # 8000422e <namei>
    80005b08:	892a                	mv	s2,a0
    80005b0a:	c905                	beqz	a0,80005b3a <sys_open+0x13c>
    ilock(ip);
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	f66080e7          	jalr	-154(ra) # 80003a72 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b14:	04491703          	lh	a4,68(s2)
    80005b18:	4785                	li	a5,1
    80005b1a:	f4f712e3          	bne	a4,a5,80005a5e <sys_open+0x60>
    80005b1e:	f4c42783          	lw	a5,-180(s0)
    80005b22:	dba1                	beqz	a5,80005a72 <sys_open+0x74>
      iunlockput(ip);
    80005b24:	854a                	mv	a0,s2
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	1ae080e7          	jalr	430(ra) # 80003cd4 <iunlockput>
      end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	99e080e7          	jalr	-1634(ra) # 800044cc <end_op>
      return -1;
    80005b36:	54fd                	li	s1,-1
    80005b38:	b76d                	j	80005ae2 <sys_open+0xe4>
      end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	992080e7          	jalr	-1646(ra) # 800044cc <end_op>
      return -1;
    80005b42:	54fd                	li	s1,-1
    80005b44:	bf79                	j	80005ae2 <sys_open+0xe4>
    iunlockput(ip);
    80005b46:	854a                	mv	a0,s2
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	18c080e7          	jalr	396(ra) # 80003cd4 <iunlockput>
    end_op();
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	97c080e7          	jalr	-1668(ra) # 800044cc <end_op>
    return -1;
    80005b58:	54fd                	li	s1,-1
    80005b5a:	b761                	j	80005ae2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b5c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b60:	04691783          	lh	a5,70(s2)
    80005b64:	02f99223          	sh	a5,36(s3)
    80005b68:	bf2d                	j	80005aa2 <sys_open+0xa4>
    itrunc(ip);
    80005b6a:	854a                	mv	a0,s2
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	014080e7          	jalr	20(ra) # 80003b80 <itrunc>
    80005b74:	bfb1                	j	80005ad0 <sys_open+0xd2>
      fileclose(f);
    80005b76:	854e                	mv	a0,s3
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	da2080e7          	jalr	-606(ra) # 8000491a <fileclose>
    iunlockput(ip);
    80005b80:	854a                	mv	a0,s2
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	152080e7          	jalr	338(ra) # 80003cd4 <iunlockput>
    end_op();
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	942080e7          	jalr	-1726(ra) # 800044cc <end_op>
    return -1;
    80005b92:	54fd                	li	s1,-1
    80005b94:	b7b9                	j	80005ae2 <sys_open+0xe4>

0000000080005b96 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b96:	7175                	addi	sp,sp,-144
    80005b98:	e506                	sd	ra,136(sp)
    80005b9a:	e122                	sd	s0,128(sp)
    80005b9c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	8b0080e7          	jalr	-1872(ra) # 8000444e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ba6:	08000613          	li	a2,128
    80005baa:	f7040593          	addi	a1,s0,-144
    80005bae:	4501                	li	a0,0
    80005bb0:	ffffd097          	auipc	ra,0xffffd
    80005bb4:	33a080e7          	jalr	826(ra) # 80002eea <argstr>
    80005bb8:	02054963          	bltz	a0,80005bea <sys_mkdir+0x54>
    80005bbc:	4681                	li	a3,0
    80005bbe:	4601                	li	a2,0
    80005bc0:	4585                	li	a1,1
    80005bc2:	f7040513          	addi	a0,s0,-144
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	7fa080e7          	jalr	2042(ra) # 800053c0 <create>
    80005bce:	cd11                	beqz	a0,80005bea <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	104080e7          	jalr	260(ra) # 80003cd4 <iunlockput>
  end_op();
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	8f4080e7          	jalr	-1804(ra) # 800044cc <end_op>
  return 0;
    80005be0:	4501                	li	a0,0
}
    80005be2:	60aa                	ld	ra,136(sp)
    80005be4:	640a                	ld	s0,128(sp)
    80005be6:	6149                	addi	sp,sp,144
    80005be8:	8082                	ret
    end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	8e2080e7          	jalr	-1822(ra) # 800044cc <end_op>
    return -1;
    80005bf2:	557d                	li	a0,-1
    80005bf4:	b7fd                	j	80005be2 <sys_mkdir+0x4c>

0000000080005bf6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bf6:	7135                	addi	sp,sp,-160
    80005bf8:	ed06                	sd	ra,152(sp)
    80005bfa:	e922                	sd	s0,144(sp)
    80005bfc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	850080e7          	jalr	-1968(ra) # 8000444e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c06:	08000613          	li	a2,128
    80005c0a:	f7040593          	addi	a1,s0,-144
    80005c0e:	4501                	li	a0,0
    80005c10:	ffffd097          	auipc	ra,0xffffd
    80005c14:	2da080e7          	jalr	730(ra) # 80002eea <argstr>
    80005c18:	04054a63          	bltz	a0,80005c6c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c1c:	f6c40593          	addi	a1,s0,-148
    80005c20:	4505                	li	a0,1
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	284080e7          	jalr	644(ra) # 80002ea6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c2a:	04054163          	bltz	a0,80005c6c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c2e:	f6840593          	addi	a1,s0,-152
    80005c32:	4509                	li	a0,2
    80005c34:	ffffd097          	auipc	ra,0xffffd
    80005c38:	272080e7          	jalr	626(ra) # 80002ea6 <argint>
     argint(1, &major) < 0 ||
    80005c3c:	02054863          	bltz	a0,80005c6c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c40:	f6841683          	lh	a3,-152(s0)
    80005c44:	f6c41603          	lh	a2,-148(s0)
    80005c48:	458d                	li	a1,3
    80005c4a:	f7040513          	addi	a0,s0,-144
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	772080e7          	jalr	1906(ra) # 800053c0 <create>
     argint(2, &minor) < 0 ||
    80005c56:	c919                	beqz	a0,80005c6c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	07c080e7          	jalr	124(ra) # 80003cd4 <iunlockput>
  end_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	86c080e7          	jalr	-1940(ra) # 800044cc <end_op>
  return 0;
    80005c68:	4501                	li	a0,0
    80005c6a:	a031                	j	80005c76 <sys_mknod+0x80>
    end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	860080e7          	jalr	-1952(ra) # 800044cc <end_op>
    return -1;
    80005c74:	557d                	li	a0,-1
}
    80005c76:	60ea                	ld	ra,152(sp)
    80005c78:	644a                	ld	s0,144(sp)
    80005c7a:	610d                	addi	sp,sp,160
    80005c7c:	8082                	ret

0000000080005c7e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c7e:	7135                	addi	sp,sp,-160
    80005c80:	ed06                	sd	ra,152(sp)
    80005c82:	e922                	sd	s0,144(sp)
    80005c84:	e526                	sd	s1,136(sp)
    80005c86:	e14a                	sd	s2,128(sp)
    80005c88:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c8a:	ffffc097          	auipc	ra,0xffffc
    80005c8e:	dac080e7          	jalr	-596(ra) # 80001a36 <myproc>
    80005c92:	892a                	mv	s2,a0
  
  begin_op();
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	7ba080e7          	jalr	1978(ra) # 8000444e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c9c:	08000613          	li	a2,128
    80005ca0:	f6040593          	addi	a1,s0,-160
    80005ca4:	4501                	li	a0,0
    80005ca6:	ffffd097          	auipc	ra,0xffffd
    80005caa:	244080e7          	jalr	580(ra) # 80002eea <argstr>
    80005cae:	04054b63          	bltz	a0,80005d04 <sys_chdir+0x86>
    80005cb2:	f6040513          	addi	a0,s0,-160
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	578080e7          	jalr	1400(ra) # 8000422e <namei>
    80005cbe:	84aa                	mv	s1,a0
    80005cc0:	c131                	beqz	a0,80005d04 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	db0080e7          	jalr	-592(ra) # 80003a72 <ilock>
  if(ip->type != T_DIR){
    80005cca:	04449703          	lh	a4,68(s1)
    80005cce:	4785                	li	a5,1
    80005cd0:	04f71063          	bne	a4,a5,80005d10 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cd4:	8526                	mv	a0,s1
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	e5e080e7          	jalr	-418(ra) # 80003b34 <iunlock>
  iput(p->cwd);
    80005cde:	42893503          	ld	a0,1064(s2)
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	f4a080e7          	jalr	-182(ra) # 80003c2c <iput>
  end_op();
    80005cea:	ffffe097          	auipc	ra,0xffffe
    80005cee:	7e2080e7          	jalr	2018(ra) # 800044cc <end_op>
  p->cwd = ip;
    80005cf2:	42993423          	sd	s1,1064(s2)
  return 0;
    80005cf6:	4501                	li	a0,0
}
    80005cf8:	60ea                	ld	ra,152(sp)
    80005cfa:	644a                	ld	s0,144(sp)
    80005cfc:	64aa                	ld	s1,136(sp)
    80005cfe:	690a                	ld	s2,128(sp)
    80005d00:	610d                	addi	sp,sp,160
    80005d02:	8082                	ret
    end_op();
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	7c8080e7          	jalr	1992(ra) # 800044cc <end_op>
    return -1;
    80005d0c:	557d                	li	a0,-1
    80005d0e:	b7ed                	j	80005cf8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d10:	8526                	mv	a0,s1
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	fc2080e7          	jalr	-62(ra) # 80003cd4 <iunlockput>
    end_op();
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	7b2080e7          	jalr	1970(ra) # 800044cc <end_op>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	bfd1                	j	80005cf8 <sys_chdir+0x7a>

0000000080005d26 <sys_exec>:

uint64
sys_exec(void)
{
    80005d26:	7145                	addi	sp,sp,-464
    80005d28:	e786                	sd	ra,456(sp)
    80005d2a:	e3a2                	sd	s0,448(sp)
    80005d2c:	ff26                	sd	s1,440(sp)
    80005d2e:	fb4a                	sd	s2,432(sp)
    80005d30:	f74e                	sd	s3,424(sp)
    80005d32:	f352                	sd	s4,416(sp)
    80005d34:	ef56                	sd	s5,408(sp)
    80005d36:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d38:	08000613          	li	a2,128
    80005d3c:	f4040593          	addi	a1,s0,-192
    80005d40:	4501                	li	a0,0
    80005d42:	ffffd097          	auipc	ra,0xffffd
    80005d46:	1a8080e7          	jalr	424(ra) # 80002eea <argstr>
    return -1;
    80005d4a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d4c:	0c054b63          	bltz	a0,80005e22 <sys_exec+0xfc>
    80005d50:	e3840593          	addi	a1,s0,-456
    80005d54:	4505                	li	a0,1
    80005d56:	ffffd097          	auipc	ra,0xffffd
    80005d5a:	172080e7          	jalr	370(ra) # 80002ec8 <argaddr>
    80005d5e:	0c054263          	bltz	a0,80005e22 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005d62:	10000613          	li	a2,256
    80005d66:	4581                	li	a1,0
    80005d68:	e4040513          	addi	a0,s0,-448
    80005d6c:	ffffb097          	auipc	ra,0xffffb
    80005d70:	fac080e7          	jalr	-84(ra) # 80000d18 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d74:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d78:	89a6                	mv	s3,s1
    80005d7a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d7c:	02000a13          	li	s4,32
    80005d80:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d84:	00391513          	slli	a0,s2,0x3
    80005d88:	e3040593          	addi	a1,s0,-464
    80005d8c:	e3843783          	ld	a5,-456(s0)
    80005d90:	953e                	add	a0,a0,a5
    80005d92:	ffffd097          	auipc	ra,0xffffd
    80005d96:	074080e7          	jalr	116(ra) # 80002e06 <fetchaddr>
    80005d9a:	02054a63          	bltz	a0,80005dce <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d9e:	e3043783          	ld	a5,-464(s0)
    80005da2:	c3b9                	beqz	a5,80005de8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005da4:	ffffb097          	auipc	ra,0xffffb
    80005da8:	d3e080e7          	jalr	-706(ra) # 80000ae2 <kalloc>
    80005dac:	85aa                	mv	a1,a0
    80005dae:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005db2:	cd11                	beqz	a0,80005dce <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005db4:	6605                	lui	a2,0x1
    80005db6:	e3043503          	ld	a0,-464(s0)
    80005dba:	ffffd097          	auipc	ra,0xffffd
    80005dbe:	0a2080e7          	jalr	162(ra) # 80002e5c <fetchstr>
    80005dc2:	00054663          	bltz	a0,80005dce <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005dc6:	0905                	addi	s2,s2,1
    80005dc8:	09a1                	addi	s3,s3,8
    80005dca:	fb491be3          	bne	s2,s4,80005d80 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dce:	f4040913          	addi	s2,s0,-192
    80005dd2:	6088                	ld	a0,0(s1)
    80005dd4:	c531                	beqz	a0,80005e20 <sys_exec+0xfa>
    kfree(argv[i]);
    80005dd6:	ffffb097          	auipc	ra,0xffffb
    80005dda:	c0e080e7          	jalr	-1010(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dde:	04a1                	addi	s1,s1,8
    80005de0:	ff2499e3          	bne	s1,s2,80005dd2 <sys_exec+0xac>
  return -1;
    80005de4:	597d                	li	s2,-1
    80005de6:	a835                	j	80005e22 <sys_exec+0xfc>
      argv[i] = 0;
    80005de8:	0a8e                	slli	s5,s5,0x3
    80005dea:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffc8fc0>
    80005dee:	00878ab3          	add	s5,a5,s0
    80005df2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005df6:	e4040593          	addi	a1,s0,-448
    80005dfa:	f4040513          	addi	a0,s0,-192
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	170080e7          	jalr	368(ra) # 80004f6e <exec>
    80005e06:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e08:	f4040993          	addi	s3,s0,-192
    80005e0c:	6088                	ld	a0,0(s1)
    80005e0e:	c911                	beqz	a0,80005e22 <sys_exec+0xfc>
    kfree(argv[i]);
    80005e10:	ffffb097          	auipc	ra,0xffffb
    80005e14:	bd4080e7          	jalr	-1068(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e18:	04a1                	addi	s1,s1,8
    80005e1a:	ff3499e3          	bne	s1,s3,80005e0c <sys_exec+0xe6>
    80005e1e:	a011                	j	80005e22 <sys_exec+0xfc>
  return -1;
    80005e20:	597d                	li	s2,-1
}
    80005e22:	854a                	mv	a0,s2
    80005e24:	60be                	ld	ra,456(sp)
    80005e26:	641e                	ld	s0,448(sp)
    80005e28:	74fa                	ld	s1,440(sp)
    80005e2a:	795a                	ld	s2,432(sp)
    80005e2c:	79ba                	ld	s3,424(sp)
    80005e2e:	7a1a                	ld	s4,416(sp)
    80005e30:	6afa                	ld	s5,408(sp)
    80005e32:	6179                	addi	sp,sp,464
    80005e34:	8082                	ret

0000000080005e36 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e36:	7139                	addi	sp,sp,-64
    80005e38:	fc06                	sd	ra,56(sp)
    80005e3a:	f822                	sd	s0,48(sp)
    80005e3c:	f426                	sd	s1,40(sp)
    80005e3e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e40:	ffffc097          	auipc	ra,0xffffc
    80005e44:	bf6080e7          	jalr	-1034(ra) # 80001a36 <myproc>
    80005e48:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e4a:	fd840593          	addi	a1,s0,-40
    80005e4e:	4501                	li	a0,0
    80005e50:	ffffd097          	auipc	ra,0xffffd
    80005e54:	078080e7          	jalr	120(ra) # 80002ec8 <argaddr>
    return -1;
    80005e58:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e5a:	0e054563          	bltz	a0,80005f44 <sys_pipe+0x10e>
  if(pipealloc(&rf, &wf) < 0)
    80005e5e:	fc840593          	addi	a1,s0,-56
    80005e62:	fd040513          	addi	a0,s0,-48
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	de4080e7          	jalr	-540(ra) # 80004c4a <pipealloc>
    return -1;
    80005e6e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e70:	0c054a63          	bltz	a0,80005f44 <sys_pipe+0x10e>
  fd0 = -1;
    80005e74:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e78:	fd043503          	ld	a0,-48(s0)
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	502080e7          	jalr	1282(ra) # 8000537e <fdalloc>
    80005e84:	fca42223          	sw	a0,-60(s0)
    80005e88:	0a054163          	bltz	a0,80005f2a <sys_pipe+0xf4>
    80005e8c:	fc843503          	ld	a0,-56(s0)
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	4ee080e7          	jalr	1262(ra) # 8000537e <fdalloc>
    80005e98:	fca42023          	sw	a0,-64(s0)
    80005e9c:	06054d63          	bltz	a0,80005f16 <sys_pipe+0xe0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ea0:	4691                	li	a3,4
    80005ea2:	fc440613          	addi	a2,s0,-60
    80005ea6:	fd843583          	ld	a1,-40(s0)
    80005eaa:	3284b503          	ld	a0,808(s1)
    80005eae:	ffffb097          	auipc	ra,0xffffb
    80005eb2:	7ce080e7          	jalr	1998(ra) # 8000167c <copyout>
    80005eb6:	02054163          	bltz	a0,80005ed8 <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005eba:	4691                	li	a3,4
    80005ebc:	fc040613          	addi	a2,s0,-64
    80005ec0:	fd843583          	ld	a1,-40(s0)
    80005ec4:	0591                	addi	a1,a1,4
    80005ec6:	3284b503          	ld	a0,808(s1)
    80005eca:	ffffb097          	auipc	ra,0xffffb
    80005ece:	7b2080e7          	jalr	1970(ra) # 8000167c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ed2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ed4:	06055863          	bgez	a0,80005f44 <sys_pipe+0x10e>
    p->ofile[fd0] = 0;
    80005ed8:	fc442783          	lw	a5,-60(s0)
    80005edc:	07478793          	addi	a5,a5,116
    80005ee0:	078e                	slli	a5,a5,0x3
    80005ee2:	97a6                	add	a5,a5,s1
    80005ee4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005ee8:	fc042783          	lw	a5,-64(s0)
    80005eec:	07478793          	addi	a5,a5,116
    80005ef0:	078e                	slli	a5,a5,0x3
    80005ef2:	00f48533          	add	a0,s1,a5
    80005ef6:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005efa:	fd043503          	ld	a0,-48(s0)
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	a1c080e7          	jalr	-1508(ra) # 8000491a <fileclose>
    fileclose(wf);
    80005f06:	fc843503          	ld	a0,-56(s0)
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	a10080e7          	jalr	-1520(ra) # 8000491a <fileclose>
    return -1;
    80005f12:	57fd                	li	a5,-1
    80005f14:	a805                	j	80005f44 <sys_pipe+0x10e>
    if(fd0 >= 0)
    80005f16:	fc442783          	lw	a5,-60(s0)
    80005f1a:	0007c863          	bltz	a5,80005f2a <sys_pipe+0xf4>
      p->ofile[fd0] = 0;
    80005f1e:	07478793          	addi	a5,a5,116
    80005f22:	078e                	slli	a5,a5,0x3
    80005f24:	97a6                	add	a5,a5,s1
    80005f26:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005f2a:	fd043503          	ld	a0,-48(s0)
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	9ec080e7          	jalr	-1556(ra) # 8000491a <fileclose>
    fileclose(wf);
    80005f36:	fc843503          	ld	a0,-56(s0)
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	9e0080e7          	jalr	-1568(ra) # 8000491a <fileclose>
    return -1;
    80005f42:	57fd                	li	a5,-1
}
    80005f44:	853e                	mv	a0,a5
    80005f46:	70e2                	ld	ra,56(sp)
    80005f48:	7442                	ld	s0,48(sp)
    80005f4a:	74a2                	ld	s1,40(sp)
    80005f4c:	6121                	addi	sp,sp,64
    80005f4e:	8082                	ret

0000000080005f50 <sys_mmap>:

// HW5 - Task 1a
// Create a new mapped memory region
uint64
sys_mmap()
{
    80005f50:	7139                	addi	sp,sp,-64
    80005f52:	fc06                	sd	ra,56(sp)
    80005f54:	f822                	sd	s0,48(sp)
    80005f56:	f426                	sd	s1,40(sp)
    80005f58:	f04a                	sd	s2,32(sp)
    80005f5a:	ec4e                	sd	s3,24(sp)
    80005f5c:	0080                	addi	s0,sp,64
  uint64 length;
  int    prot;
  int    flags;
  struct proc *p = myproc();
    80005f5e:	ffffc097          	auipc	ra,0xffffc
    80005f62:	ad8080e7          	jalr	-1320(ra) # 80001a36 <myproc>
    80005f66:	89aa                	mv	s3,a0
  struct mmr *newmmr = 0;
  uint64 start_addr;

  /* Add error checking for length, prot, and flags arguments */

  if (argaddr(1, &length) < 0)
    80005f68:	fc840593          	addi	a1,s0,-56
    80005f6c:	4505                	li	a0,1
    80005f6e:	ffffd097          	auipc	ra,0xffffd
    80005f72:	f5a080e7          	jalr	-166(ra) # 80002ec8 <argaddr>
    return -1;
    80005f76:	597d                	li	s2,-1
  if (argaddr(1, &length) < 0)
    80005f78:	0a054863          	bltz	a0,80006028 <sys_mmap+0xd8>
  if (argint(2, &prot) < 0)
    80005f7c:	fc440593          	addi	a1,s0,-60
    80005f80:	4509                	li	a0,2
    80005f82:	ffffd097          	auipc	ra,0xffffd
    80005f86:	f24080e7          	jalr	-220(ra) # 80002ea6 <argint>
    80005f8a:	08054f63          	bltz	a0,80006028 <sys_mmap+0xd8>
    return -1;
  if (argint(3, &flags) <0)
    80005f8e:	fc040593          	addi	a1,s0,-64
    80005f92:	450d                	li	a0,3
    80005f94:	ffffd097          	auipc	ra,0xffffd
    80005f98:	f12080e7          	jalr	-238(ra) # 80002ea6 <argint>
    80005f9c:	0c054263          	bltz	a0,80006060 <sys_mmap+0x110>
    80005fa0:	01498793          	addi	a5,s3,20
    return -1;
  // Search p->mmr[] for unused location 
  for (int i = 0; i < MAX_MMR; i++) {
    80005fa4:	4481                	li	s1,0
    80005fa6:	46a9                	li	a3,10
    if (p->mmr[i].valid == 0) {
    80005fa8:	4398                	lw	a4,0(a5)
    80005faa:	cb01                	beqz	a4,80005fba <sys_mmap+0x6a>
  for (int i = 0; i < MAX_MMR; i++) {
    80005fac:	2485                	addiw	s1,s1,1
    80005fae:	04878793          	addi	a5,a5,72
    80005fb2:	fed49be3          	bne	s1,a3,80005fa8 <sys_mmap+0x58>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
      newmmr->mmr_family.listid = alloc_mmr_listid();
    p->cur_max = start_addr;
    return start_addr;
  } else {
    return -1;
    80005fb6:	597d                	li	s2,-1
    80005fb8:	a885                	j	80006028 <sys_mmap+0xd8>
    start_addr = PGROUNDDOWN(p->cur_max-length);
    80005fba:	2d09b903          	ld	s2,720(s3)
    80005fbe:	fc843783          	ld	a5,-56(s0)
    80005fc2:	40f90933          	sub	s2,s2,a5
    80005fc6:	77fd                	lui	a5,0xfffff
    80005fc8:	00f97933          	and	s2,s2,a5
    newmmr->valid = 1;
    80005fcc:	00349713          	slli	a4,s1,0x3
    80005fd0:	009707b3          	add	a5,a4,s1
    80005fd4:	078e                	slli	a5,a5,0x3
    80005fd6:	97ce                	add	a5,a5,s3
    80005fd8:	4685                	li	a3,1
    80005fda:	cbd4                	sw	a3,20(a5)
    newmmr->addr = start_addr;
    80005fdc:	0127b023          	sd	s2,0(a5) # fffffffffffff000 <end+0xffffffff7ffc9000>
    newmmr->length = p->cur_max - start_addr;
    80005fe0:	2d09b603          	ld	a2,720(s3)
    80005fe4:	4126063b          	subw	a2,a2,s2
    80005fe8:	c790                	sw	a2,8(a5)
    newmmr->prot = prot;
    80005fea:	fc442683          	lw	a3,-60(s0)
    80005fee:	c7d4                	sw	a3,12(a5)
    newmmr->flags = flags;
    80005ff0:	fc042683          	lw	a3,-64(s0)
    80005ff4:	cb94                	sw	a3,16(a5)
    newmmr->mmr_family.proc = p;
    80005ff6:	9726                	add	a4,a4,s1
    80005ff8:	070e                	slli	a4,a4,0x3
    80005ffa:	0337b823          	sd	s3,48(a5)
    newmmr->mmr_family.next = &(newmmr->mmr_family);  // next points to its own mmr_node
    80005ffe:	02870713          	addi	a4,a4,40
    80006002:	974e                	add	a4,a4,s3
    80006004:	ff98                	sd	a4,56(a5)
    newmmr->mmr_family.prev = &(newmmr->mmr_family);  // prev points to its own mmr_node
    80006006:	e3b8                	sd	a4,64(a5)
    if (mapvpages(p->pagetable, newmmr->addr, newmmr->length) < 0) {
    80006008:	2601                	sext.w	a2,a2
    8000600a:	85ca                	mv	a1,s2
    8000600c:	3289b503          	ld	a0,808(s3)
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	836080e7          	jalr	-1994(ra) # 80001846 <mapvpages>
    80006018:	02054063          	bltz	a0,80006038 <sys_mmap+0xe8>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
    8000601c:	fc042783          	lw	a5,-64(s0)
    80006020:	8b85                	andi	a5,a5,1
    80006022:	e785                	bnez	a5,8000604a <sys_mmap+0xfa>
    p->cur_max = start_addr;
    80006024:	2d29b823          	sd	s2,720(s3)
  }
}
    80006028:	854a                	mv	a0,s2
    8000602a:	70e2                	ld	ra,56(sp)
    8000602c:	7442                	ld	s0,48(sp)
    8000602e:	74a2                	ld	s1,40(sp)
    80006030:	7902                	ld	s2,32(sp)
    80006032:	69e2                	ld	s3,24(sp)
    80006034:	6121                	addi	sp,sp,64
    80006036:	8082                	ret
      newmmr->valid = 0;
    80006038:	00349793          	slli	a5,s1,0x3
    8000603c:	97a6                	add	a5,a5,s1
    8000603e:	078e                	slli	a5,a5,0x3
    80006040:	97ce                	add	a5,a5,s3
    80006042:	0007aa23          	sw	zero,20(a5)
      return -1;
    80006046:	597d                	li	s2,-1
    80006048:	b7c5                	j	80006028 <sys_mmap+0xd8>
      newmmr->mmr_family.listid = alloc_mmr_listid();
    8000604a:	ffffd097          	auipc	ra,0xffffd
    8000604e:	838080e7          	jalr	-1992(ra) # 80002882 <alloc_mmr_listid>
    80006052:	00349793          	slli	a5,s1,0x3
    80006056:	97a6                	add	a5,a5,s1
    80006058:	078e                	slli	a5,a5,0x3
    8000605a:	97ce                	add	a5,a5,s3
    8000605c:	d788                	sw	a0,40(a5)
    8000605e:	b7d9                	j	80006024 <sys_mmap+0xd4>
    return -1;
    80006060:	597d                	li	s2,-1
    80006062:	b7d9                	j	80006028 <sys_mmap+0xd8>

0000000080006064 <munmap>:
// HW5 - Task 1a
// Unmap memory region if it exists
// Free physical memory if no other process has the region mapped
int
munmap(uint64 addr, uint64 length)
{
    80006064:	715d                	addi	sp,sp,-80
    80006066:	e486                	sd	ra,72(sp)
    80006068:	e0a2                	sd	s0,64(sp)
    8000606a:	fc26                	sd	s1,56(sp)
    8000606c:	f84a                	sd	s2,48(sp)
    8000606e:	f44e                	sd	s3,40(sp)
    80006070:	f052                	sd	s4,32(sp)
    80006072:	ec56                	sd	s5,24(sp)
    80006074:	e85a                	sd	s6,16(sp)
    80006076:	e45e                	sd	s7,8(sp)
    80006078:	e062                	sd	s8,0(sp)
    8000607a:	0880                	addi	s0,sp,80
    8000607c:	84aa                	mv	s1,a0
    8000607e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80006080:	ffffc097          	auipc	ra,0xffffc
    80006084:	9b6080e7          	jalr	-1610(ra) # 80001a36 <myproc>
    80006088:	8a2a                	mv	s4,a0
  struct mmr *mmr = 0;
  int dofree = 0;
  int i;

  // Search proc->mmr for addr
  for (i = 0; i < MAX_MMR; i++)
    8000608a:	87aa                	mv	a5,a0
    8000608c:	4901                	li	s2,0
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    8000608e:	4685                	li	a3,1
        (PGROUNDUP(length) == p->mmr[i].length)) {
    80006090:	6705                	lui	a4,0x1
    80006092:	177d                	addi	a4,a4,-1 # fff <_entry-0x7ffff001>
    80006094:	00e985b3          	add	a1,s3,a4
    80006098:	777d                	lui	a4,0xfffff
    8000609a:	8df9                	and	a1,a1,a4
  for (i = 0; i < MAX_MMR; i++)
    8000609c:	4629                	li	a2,10
    8000609e:	a031                	j	800060aa <munmap+0x46>
    800060a0:	2905                	addiw	s2,s2,1
    800060a2:	04878793          	addi	a5,a5,72
    800060a6:	04c90763          	beq	s2,a2,800060f4 <munmap+0x90>
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    800060aa:	0147a983          	lw	s3,20(a5)
    800060ae:	fed999e3          	bne	s3,a3,800060a0 <munmap+0x3c>
    800060b2:	6388                	ld	a0,0(a5)
    800060b4:	fe9516e3          	bne	a0,s1,800060a0 <munmap+0x3c>
        (PGROUNDUP(length) == p->mmr[i].length)) {
    800060b8:	4798                	lw	a4,8(a5)
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    800060ba:	fee593e3          	bne	a1,a4,800060a0 <munmap+0x3c>
      break;
    }
  if (!mmr) {
    return -1;
  }
  mmr->valid = 0;
    800060be:	00391793          	slli	a5,s2,0x3
    800060c2:	97ca                	add	a5,a5,s2
    800060c4:	078e                	slli	a5,a5,0x3
    800060c6:	97d2                	add	a5,a5,s4
    800060c8:	0007aa23          	sw	zero,20(a5)
  if (mmr->flags & MAP_PRIVATE)
    800060cc:	0107aa83          	lw	s5,16(a5)
    800060d0:	002afa93          	andi	s5,s5,2
    800060d4:	020a8263          	beqz	s5,800060f8 <munmap+0x94>
      release(&pmmrlist->lock);
    }
  }
  // Remove mappings from page table
  // Also free physical memory if no other process has this region mapped
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    800060d8:	00391793          	slli	a5,s2,0x3
    800060dc:	993e                	add	s2,s2,a5
    800060de:	090e                	slli	s2,s2,0x3
    800060e0:	9952                	add	s2,s2,s4
    800060e2:	00892783          	lw	a5,8(s2)
    800060e6:	00093703          	ld	a4,0(s2)
    800060ea:	97ba                	add	a5,a5,a4
    800060ec:	0cf4f463          	bgeu	s1,a5,800061b4 <munmap+0x150>
    800060f0:	6a85                	lui	s5,0x1
    800060f2:	a051                	j	80006176 <munmap+0x112>
    return -1;
    800060f4:	557d                	li	a0,-1
    800060f6:	a05d                	j	8000619c <munmap+0x138>
    struct mmr_list *pmmrlist = get_mmr_list(mmr->mmr_family.listid);
    800060f8:	00391b13          	slli	s6,s2,0x3
    800060fc:	012b0c33          	add	s8,s6,s2
    80006100:	0c0e                	slli	s8,s8,0x3
    80006102:	9c52                	add	s8,s8,s4
    80006104:	028c2503          	lw	a0,40(s8)
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	6be080e7          	jalr	1726(ra) # 800027c6 <get_mmr_list>
    80006110:	8baa                	mv	s7,a0
    acquire(&pmmrlist->lock);
    80006112:	ffffb097          	auipc	ra,0xffffb
    80006116:	b0a080e7          	jalr	-1270(ra) # 80000c1c <acquire>
    if (mmr->mmr_family.next == &(mmr->mmr_family)) { // no other family members
    8000611a:	038c3703          	ld	a4,56(s8)
    8000611e:	012b07b3          	add	a5,s6,s2
    80006122:	078e                	slli	a5,a5,0x3
    80006124:	02878793          	addi	a5,a5,40
    80006128:	97d2                	add	a5,a5,s4
    8000612a:	02f70263          	beq	a4,a5,8000614e <munmap+0xea>
      (mmr->mmr_family.next)->prev = mmr->mmr_family.prev;
    8000612e:	00391793          	slli	a5,s2,0x3
    80006132:	97ca                	add	a5,a5,s2
    80006134:	078e                	slli	a5,a5,0x3
    80006136:	97d2                	add	a5,a5,s4
    80006138:	63b4                	ld	a3,64(a5)
    8000613a:	ef14                	sd	a3,24(a4)
      (mmr->mmr_family.prev)->next = mmr->mmr_family.next;
    8000613c:	7f9c                	ld	a5,56(a5)
    8000613e:	ea9c                	sd	a5,16(a3)
      release(&pmmrlist->lock);
    80006140:	855e                	mv	a0,s7
    80006142:	ffffb097          	auipc	ra,0xffffb
    80006146:	b8e080e7          	jalr	-1138(ra) # 80000cd0 <release>
  int dofree = 0;
    8000614a:	89d6                	mv	s3,s5
    8000614c:	b771                	j	800060d8 <munmap+0x74>
      release(&pmmrlist->lock);
    8000614e:	855e                	mv	a0,s7
    80006150:	ffffb097          	auipc	ra,0xffffb
    80006154:	b80080e7          	jalr	-1152(ra) # 80000cd0 <release>
      dealloc_mmr_listid(mmr->mmr_family.listid);
    80006158:	028c2503          	lw	a0,40(s8)
    8000615c:	ffffc097          	auipc	ra,0xffffc
    80006160:	6e0080e7          	jalr	1760(ra) # 8000283c <dealloc_mmr_listid>
    80006164:	bf95                	j	800060d8 <munmap+0x74>
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    80006166:	94d6                	add	s1,s1,s5
    80006168:	00892783          	lw	a5,8(s2)
    8000616c:	00093703          	ld	a4,0(s2)
    80006170:	97ba                	add	a5,a5,a4
    80006172:	02f4f463          	bgeu	s1,a5,8000619a <munmap+0x136>
    if (walkaddr(p->pagetable, pageaddr)) {
    80006176:	85a6                	mv	a1,s1
    80006178:	328a3503          	ld	a0,808(s4)
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	f22080e7          	jalr	-222(ra) # 8000109e <walkaddr>
    80006184:	d16d                	beqz	a0,80006166 <munmap+0x102>
      uvmunmap(p->pagetable, pageaddr, 1, dofree);
    80006186:	86ce                	mv	a3,s3
    80006188:	4605                	li	a2,1
    8000618a:	85a6                	mv	a1,s1
    8000618c:	328a3503          	ld	a0,808(s4)
    80006190:	ffffb097          	auipc	ra,0xffffb
    80006194:	116080e7          	jalr	278(ra) # 800012a6 <uvmunmap>
    80006198:	b7f9                	j	80006166 <munmap+0x102>
    }
  }
  return 0;
    8000619a:	4501                	li	a0,0
}
    8000619c:	60a6                	ld	ra,72(sp)
    8000619e:	6406                	ld	s0,64(sp)
    800061a0:	74e2                	ld	s1,56(sp)
    800061a2:	7942                	ld	s2,48(sp)
    800061a4:	79a2                	ld	s3,40(sp)
    800061a6:	7a02                	ld	s4,32(sp)
    800061a8:	6ae2                	ld	s5,24(sp)
    800061aa:	6b42                	ld	s6,16(sp)
    800061ac:	6ba2                	ld	s7,8(sp)
    800061ae:	6c02                	ld	s8,0(sp)
    800061b0:	6161                	addi	sp,sp,80
    800061b2:	8082                	ret
  return 0;
    800061b4:	4501                	li	a0,0
    800061b6:	b7dd                	j	8000619c <munmap+0x138>

00000000800061b8 <sys_munmap>:

// Get arguments and call munmap() helper function
uint64
sys_munmap(void)
{
    800061b8:	1101                	addi	sp,sp,-32
    800061ba:	ec06                	sd	ra,24(sp)
    800061bc:	e822                	sd	s0,16(sp)
    800061be:	1000                	addi	s0,sp,32
  uint64 addr;
  uint64 length;

  // HW5 - Task 1a
  if(argaddr(0, &addr) < 0)
    800061c0:	fe840593          	addi	a1,s0,-24
    800061c4:	4501                	li	a0,0
    800061c6:	ffffd097          	auipc	ra,0xffffd
    800061ca:	d02080e7          	jalr	-766(ra) # 80002ec8 <argaddr>
        return -1;
    800061ce:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    800061d0:	02054563          	bltz	a0,800061fa <sys_munmap+0x42>
  if(argaddr(1, &length) < 0)
    800061d4:	fe040593          	addi	a1,s0,-32
    800061d8:	4505                	li	a0,1
    800061da:	ffffd097          	auipc	ra,0xffffd
    800061de:	cee080e7          	jalr	-786(ra) # 80002ec8 <argaddr>
       return -1;
    800061e2:	57fd                	li	a5,-1
  if(argaddr(1, &length) < 0)
    800061e4:	00054b63          	bltz	a0,800061fa <sys_munmap+0x42>
  munmap(addr, length);
    800061e8:	fe043583          	ld	a1,-32(s0)
    800061ec:	fe843503          	ld	a0,-24(s0)
    800061f0:	00000097          	auipc	ra,0x0
    800061f4:	e74080e7          	jalr	-396(ra) # 80006064 <munmap>
  return 0;
    800061f8:	4781                	li	a5,0
    800061fa:	853e                	mv	a0,a5
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	6105                	addi	sp,sp,32
    80006202:	8082                	ret
	...

0000000080006210 <kernelvec>:
    80006210:	7111                	addi	sp,sp,-256
    80006212:	e006                	sd	ra,0(sp)
    80006214:	e40a                	sd	sp,8(sp)
    80006216:	e80e                	sd	gp,16(sp)
    80006218:	ec12                	sd	tp,24(sp)
    8000621a:	f016                	sd	t0,32(sp)
    8000621c:	f41a                	sd	t1,40(sp)
    8000621e:	f81e                	sd	t2,48(sp)
    80006220:	fc22                	sd	s0,56(sp)
    80006222:	e0a6                	sd	s1,64(sp)
    80006224:	e4aa                	sd	a0,72(sp)
    80006226:	e8ae                	sd	a1,80(sp)
    80006228:	ecb2                	sd	a2,88(sp)
    8000622a:	f0b6                	sd	a3,96(sp)
    8000622c:	f4ba                	sd	a4,104(sp)
    8000622e:	f8be                	sd	a5,112(sp)
    80006230:	fcc2                	sd	a6,120(sp)
    80006232:	e146                	sd	a7,128(sp)
    80006234:	e54a                	sd	s2,136(sp)
    80006236:	e94e                	sd	s3,144(sp)
    80006238:	ed52                	sd	s4,152(sp)
    8000623a:	f156                	sd	s5,160(sp)
    8000623c:	f55a                	sd	s6,168(sp)
    8000623e:	f95e                	sd	s7,176(sp)
    80006240:	fd62                	sd	s8,184(sp)
    80006242:	e1e6                	sd	s9,192(sp)
    80006244:	e5ea                	sd	s10,200(sp)
    80006246:	e9ee                	sd	s11,208(sp)
    80006248:	edf2                	sd	t3,216(sp)
    8000624a:	f1f6                	sd	t4,224(sp)
    8000624c:	f5fa                	sd	t5,232(sp)
    8000624e:	f9fe                	sd	t6,240(sp)
    80006250:	a75fc0ef          	jal	ra,80002cc4 <kerneltrap>
    80006254:	6082                	ld	ra,0(sp)
    80006256:	6122                	ld	sp,8(sp)
    80006258:	61c2                	ld	gp,16(sp)
    8000625a:	7282                	ld	t0,32(sp)
    8000625c:	7322                	ld	t1,40(sp)
    8000625e:	73c2                	ld	t2,48(sp)
    80006260:	7462                	ld	s0,56(sp)
    80006262:	6486                	ld	s1,64(sp)
    80006264:	6526                	ld	a0,72(sp)
    80006266:	65c6                	ld	a1,80(sp)
    80006268:	6666                	ld	a2,88(sp)
    8000626a:	7686                	ld	a3,96(sp)
    8000626c:	7726                	ld	a4,104(sp)
    8000626e:	77c6                	ld	a5,112(sp)
    80006270:	7866                	ld	a6,120(sp)
    80006272:	688a                	ld	a7,128(sp)
    80006274:	692a                	ld	s2,136(sp)
    80006276:	69ca                	ld	s3,144(sp)
    80006278:	6a6a                	ld	s4,152(sp)
    8000627a:	7a8a                	ld	s5,160(sp)
    8000627c:	7b2a                	ld	s6,168(sp)
    8000627e:	7bca                	ld	s7,176(sp)
    80006280:	7c6a                	ld	s8,184(sp)
    80006282:	6c8e                	ld	s9,192(sp)
    80006284:	6d2e                	ld	s10,200(sp)
    80006286:	6dce                	ld	s11,208(sp)
    80006288:	6e6e                	ld	t3,216(sp)
    8000628a:	7e8e                	ld	t4,224(sp)
    8000628c:	7f2e                	ld	t5,232(sp)
    8000628e:	7fce                	ld	t6,240(sp)
    80006290:	6111                	addi	sp,sp,256
    80006292:	10200073          	sret
    80006296:	00000013          	nop
    8000629a:	00000013          	nop
    8000629e:	0001                	nop

00000000800062a0 <timervec>:
    800062a0:	34051573          	csrrw	a0,mscratch,a0
    800062a4:	e10c                	sd	a1,0(a0)
    800062a6:	e510                	sd	a2,8(a0)
    800062a8:	e914                	sd	a3,16(a0)
    800062aa:	6d0c                	ld	a1,24(a0)
    800062ac:	7110                	ld	a2,32(a0)
    800062ae:	6194                	ld	a3,0(a1)
    800062b0:	96b2                	add	a3,a3,a2
    800062b2:	e194                	sd	a3,0(a1)
    800062b4:	4589                	li	a1,2
    800062b6:	14459073          	csrw	sip,a1
    800062ba:	6914                	ld	a3,16(a0)
    800062bc:	6510                	ld	a2,8(a0)
    800062be:	610c                	ld	a1,0(a0)
    800062c0:	34051573          	csrrw	a0,mscratch,a0
    800062c4:	30200073          	mret
	...

00000000800062ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ca:	1141                	addi	sp,sp,-16
    800062cc:	e422                	sd	s0,8(sp)
    800062ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062d0:	0c0007b7          	lui	a5,0xc000
    800062d4:	4705                	li	a4,1
    800062d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062d8:	c3d8                	sw	a4,4(a5)
}
    800062da:	6422                	ld	s0,8(sp)
    800062dc:	0141                	addi	sp,sp,16
    800062de:	8082                	ret

00000000800062e0 <plicinithart>:

void
plicinithart(void)
{
    800062e0:	1141                	addi	sp,sp,-16
    800062e2:	e406                	sd	ra,8(sp)
    800062e4:	e022                	sd	s0,0(sp)
    800062e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062e8:	ffffb097          	auipc	ra,0xffffb
    800062ec:	722080e7          	jalr	1826(ra) # 80001a0a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062f0:	0085171b          	slliw	a4,a0,0x8
    800062f4:	0c0027b7          	lui	a5,0xc002
    800062f8:	97ba                	add	a5,a5,a4
    800062fa:	40200713          	li	a4,1026
    800062fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006302:	00d5151b          	slliw	a0,a0,0xd
    80006306:	0c2017b7          	lui	a5,0xc201
    8000630a:	97aa                	add	a5,a5,a0
    8000630c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006310:	60a2                	ld	ra,8(sp)
    80006312:	6402                	ld	s0,0(sp)
    80006314:	0141                	addi	sp,sp,16
    80006316:	8082                	ret

0000000080006318 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006318:	1141                	addi	sp,sp,-16
    8000631a:	e406                	sd	ra,8(sp)
    8000631c:	e022                	sd	s0,0(sp)
    8000631e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	6ea080e7          	jalr	1770(ra) # 80001a0a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006328:	00d5151b          	slliw	a0,a0,0xd
    8000632c:	0c2017b7          	lui	a5,0xc201
    80006330:	97aa                	add	a5,a5,a0
  return irq;
}
    80006332:	43c8                	lw	a0,4(a5)
    80006334:	60a2                	ld	ra,8(sp)
    80006336:	6402                	ld	s0,0(sp)
    80006338:	0141                	addi	sp,sp,16
    8000633a:	8082                	ret

000000008000633c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000633c:	1101                	addi	sp,sp,-32
    8000633e:	ec06                	sd	ra,24(sp)
    80006340:	e822                	sd	s0,16(sp)
    80006342:	e426                	sd	s1,8(sp)
    80006344:	1000                	addi	s0,sp,32
    80006346:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	6c2080e7          	jalr	1730(ra) # 80001a0a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006350:	00d5151b          	slliw	a0,a0,0xd
    80006354:	0c2017b7          	lui	a5,0xc201
    80006358:	97aa                	add	a5,a5,a0
    8000635a:	c3c4                	sw	s1,4(a5)
}
    8000635c:	60e2                	ld	ra,24(sp)
    8000635e:	6442                	ld	s0,16(sp)
    80006360:	64a2                	ld	s1,8(sp)
    80006362:	6105                	addi	sp,sp,32
    80006364:	8082                	ret

0000000080006366 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006366:	1141                	addi	sp,sp,-16
    80006368:	e406                	sd	ra,8(sp)
    8000636a:	e022                	sd	s0,0(sp)
    8000636c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000636e:	479d                	li	a5,7
    80006370:	06a7c863          	blt	a5,a0,800063e0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006374:	0002d717          	auipc	a4,0x2d
    80006378:	c8c70713          	addi	a4,a4,-884 # 80033000 <disk>
    8000637c:	972a                	add	a4,a4,a0
    8000637e:	6789                	lui	a5,0x2
    80006380:	97ba                	add	a5,a5,a4
    80006382:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006386:	e7ad                	bnez	a5,800063f0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006388:	00451793          	slli	a5,a0,0x4
    8000638c:	0002f717          	auipc	a4,0x2f
    80006390:	c7470713          	addi	a4,a4,-908 # 80035000 <disk+0x2000>
    80006394:	6314                	ld	a3,0(a4)
    80006396:	96be                	add	a3,a3,a5
    80006398:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000639c:	6314                	ld	a3,0(a4)
    8000639e:	96be                	add	a3,a3,a5
    800063a0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800063a4:	6314                	ld	a3,0(a4)
    800063a6:	96be                	add	a3,a3,a5
    800063a8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800063ac:	6318                	ld	a4,0(a4)
    800063ae:	97ba                	add	a5,a5,a4
    800063b0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800063b4:	0002d717          	auipc	a4,0x2d
    800063b8:	c4c70713          	addi	a4,a4,-948 # 80033000 <disk>
    800063bc:	972a                	add	a4,a4,a0
    800063be:	6789                	lui	a5,0x2
    800063c0:	97ba                	add	a5,a5,a4
    800063c2:	4705                	li	a4,1
    800063c4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800063c8:	0002f517          	auipc	a0,0x2f
    800063cc:	c5050513          	addi	a0,a0,-944 # 80035018 <disk+0x2018>
    800063d0:	ffffc097          	auipc	ra,0xffffc
    800063d4:	f38080e7          	jalr	-200(ra) # 80002308 <wakeup>
}
    800063d8:	60a2                	ld	ra,8(sp)
    800063da:	6402                	ld	s0,0(sp)
    800063dc:	0141                	addi	sp,sp,16
    800063de:	8082                	ret
    panic("free_desc 1");
    800063e0:	00002517          	auipc	a0,0x2
    800063e4:	3e850513          	addi	a0,a0,1000 # 800087c8 <syscalls+0x340>
    800063e8:	ffffa097          	auipc	ra,0xffffa
    800063ec:	154080e7          	jalr	340(ra) # 8000053c <panic>
    panic("free_desc 2");
    800063f0:	00002517          	auipc	a0,0x2
    800063f4:	3e850513          	addi	a0,a0,1000 # 800087d8 <syscalls+0x350>
    800063f8:	ffffa097          	auipc	ra,0xffffa
    800063fc:	144080e7          	jalr	324(ra) # 8000053c <panic>

0000000080006400 <virtio_disk_init>:
{
    80006400:	1101                	addi	sp,sp,-32
    80006402:	ec06                	sd	ra,24(sp)
    80006404:	e822                	sd	s0,16(sp)
    80006406:	e426                	sd	s1,8(sp)
    80006408:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000640a:	00002597          	auipc	a1,0x2
    8000640e:	3de58593          	addi	a1,a1,990 # 800087e8 <syscalls+0x360>
    80006412:	0002f517          	auipc	a0,0x2f
    80006416:	d1650513          	addi	a0,a0,-746 # 80035128 <disk+0x2128>
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	772080e7          	jalr	1906(ra) # 80000b8c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006422:	100017b7          	lui	a5,0x10001
    80006426:	4398                	lw	a4,0(a5)
    80006428:	2701                	sext.w	a4,a4
    8000642a:	747277b7          	lui	a5,0x74727
    8000642e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006432:	0ef71063          	bne	a4,a5,80006512 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006436:	100017b7          	lui	a5,0x10001
    8000643a:	43dc                	lw	a5,4(a5)
    8000643c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000643e:	4705                	li	a4,1
    80006440:	0ce79963          	bne	a5,a4,80006512 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006444:	100017b7          	lui	a5,0x10001
    80006448:	479c                	lw	a5,8(a5)
    8000644a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000644c:	4709                	li	a4,2
    8000644e:	0ce79263          	bne	a5,a4,80006512 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006452:	100017b7          	lui	a5,0x10001
    80006456:	47d8                	lw	a4,12(a5)
    80006458:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000645a:	554d47b7          	lui	a5,0x554d4
    8000645e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006462:	0af71863          	bne	a4,a5,80006512 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006466:	100017b7          	lui	a5,0x10001
    8000646a:	4705                	li	a4,1
    8000646c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000646e:	470d                	li	a4,3
    80006470:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006472:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006474:	c7ffe6b7          	lui	a3,0xc7ffe
    80006478:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fc875f>
    8000647c:	8f75                	and	a4,a4,a3
    8000647e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006480:	472d                	li	a4,11
    80006482:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006484:	473d                	li	a4,15
    80006486:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006488:	6705                	lui	a4,0x1
    8000648a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000648c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006490:	5bdc                	lw	a5,52(a5)
    80006492:	2781                	sext.w	a5,a5
  if(max == 0)
    80006494:	c7d9                	beqz	a5,80006522 <virtio_disk_init+0x122>
  if(max < NUM)
    80006496:	471d                	li	a4,7
    80006498:	08f77d63          	bgeu	a4,a5,80006532 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000649c:	100014b7          	lui	s1,0x10001
    800064a0:	47a1                	li	a5,8
    800064a2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800064a4:	6609                	lui	a2,0x2
    800064a6:	4581                	li	a1,0
    800064a8:	0002d517          	auipc	a0,0x2d
    800064ac:	b5850513          	addi	a0,a0,-1192 # 80033000 <disk>
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	868080e7          	jalr	-1944(ra) # 80000d18 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800064b8:	0002d717          	auipc	a4,0x2d
    800064bc:	b4870713          	addi	a4,a4,-1208 # 80033000 <disk>
    800064c0:	00c75793          	srli	a5,a4,0xc
    800064c4:	2781                	sext.w	a5,a5
    800064c6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800064c8:	0002f797          	auipc	a5,0x2f
    800064cc:	b3878793          	addi	a5,a5,-1224 # 80035000 <disk+0x2000>
    800064d0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064d2:	0002d717          	auipc	a4,0x2d
    800064d6:	bae70713          	addi	a4,a4,-1106 # 80033080 <disk+0x80>
    800064da:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064dc:	0002e717          	auipc	a4,0x2e
    800064e0:	b2470713          	addi	a4,a4,-1244 # 80034000 <disk+0x1000>
    800064e4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064e6:	4705                	li	a4,1
    800064e8:	00e78c23          	sb	a4,24(a5)
    800064ec:	00e78ca3          	sb	a4,25(a5)
    800064f0:	00e78d23          	sb	a4,26(a5)
    800064f4:	00e78da3          	sb	a4,27(a5)
    800064f8:	00e78e23          	sb	a4,28(a5)
    800064fc:	00e78ea3          	sb	a4,29(a5)
    80006500:	00e78f23          	sb	a4,30(a5)
    80006504:	00e78fa3          	sb	a4,31(a5)
}
    80006508:	60e2                	ld	ra,24(sp)
    8000650a:	6442                	ld	s0,16(sp)
    8000650c:	64a2                	ld	s1,8(sp)
    8000650e:	6105                	addi	sp,sp,32
    80006510:	8082                	ret
    panic("could not find virtio disk");
    80006512:	00002517          	auipc	a0,0x2
    80006516:	2e650513          	addi	a0,a0,742 # 800087f8 <syscalls+0x370>
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	022080e7          	jalr	34(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006522:	00002517          	auipc	a0,0x2
    80006526:	2f650513          	addi	a0,a0,758 # 80008818 <syscalls+0x390>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	012080e7          	jalr	18(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006532:	00002517          	auipc	a0,0x2
    80006536:	30650513          	addi	a0,a0,774 # 80008838 <syscalls+0x3b0>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	002080e7          	jalr	2(ra) # 8000053c <panic>

0000000080006542 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006542:	7119                	addi	sp,sp,-128
    80006544:	fc86                	sd	ra,120(sp)
    80006546:	f8a2                	sd	s0,112(sp)
    80006548:	f4a6                	sd	s1,104(sp)
    8000654a:	f0ca                	sd	s2,96(sp)
    8000654c:	ecce                	sd	s3,88(sp)
    8000654e:	e8d2                	sd	s4,80(sp)
    80006550:	e4d6                	sd	s5,72(sp)
    80006552:	e0da                	sd	s6,64(sp)
    80006554:	fc5e                	sd	s7,56(sp)
    80006556:	f862                	sd	s8,48(sp)
    80006558:	f466                	sd	s9,40(sp)
    8000655a:	f06a                	sd	s10,32(sp)
    8000655c:	ec6e                	sd	s11,24(sp)
    8000655e:	0100                	addi	s0,sp,128
    80006560:	8aaa                	mv	s5,a0
    80006562:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006564:	00c52c83          	lw	s9,12(a0)
    80006568:	001c9c9b          	slliw	s9,s9,0x1
    8000656c:	1c82                	slli	s9,s9,0x20
    8000656e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006572:	0002f517          	auipc	a0,0x2f
    80006576:	bb650513          	addi	a0,a0,-1098 # 80035128 <disk+0x2128>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	6a2080e7          	jalr	1698(ra) # 80000c1c <acquire>
  for(int i = 0; i < 3; i++){
    80006582:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006584:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006586:	0002dc17          	auipc	s8,0x2d
    8000658a:	a7ac0c13          	addi	s8,s8,-1414 # 80033000 <disk>
    8000658e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006590:	4b0d                	li	s6,3
    80006592:	a0ad                	j	800065fc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006594:	00fc0733          	add	a4,s8,a5
    80006598:	975e                	add	a4,a4,s7
    8000659a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000659e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800065a0:	0207c563          	bltz	a5,800065ca <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800065a4:	2905                	addiw	s2,s2,1
    800065a6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800065a8:	19690c63          	beq	s2,s6,80006740 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800065ac:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800065ae:	0002f717          	auipc	a4,0x2f
    800065b2:	a6a70713          	addi	a4,a4,-1430 # 80035018 <disk+0x2018>
    800065b6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800065b8:	00074683          	lbu	a3,0(a4)
    800065bc:	fee1                	bnez	a3,80006594 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800065be:	2785                	addiw	a5,a5,1
    800065c0:	0705                	addi	a4,a4,1
    800065c2:	fe979be3          	bne	a5,s1,800065b8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800065c6:	57fd                	li	a5,-1
    800065c8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800065ca:	01205d63          	blez	s2,800065e4 <virtio_disk_rw+0xa2>
    800065ce:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800065d0:	000a2503          	lw	a0,0(s4)
    800065d4:	00000097          	auipc	ra,0x0
    800065d8:	d92080e7          	jalr	-622(ra) # 80006366 <free_desc>
      for(int j = 0; j < i; j++)
    800065dc:	2d85                	addiw	s11,s11,1
    800065de:	0a11                	addi	s4,s4,4
    800065e0:	ff2d98e3          	bne	s11,s2,800065d0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065e4:	0002f597          	auipc	a1,0x2f
    800065e8:	b4458593          	addi	a1,a1,-1212 # 80035128 <disk+0x2128>
    800065ec:	0002f517          	auipc	a0,0x2f
    800065f0:	a2c50513          	addi	a0,a0,-1492 # 80035018 <disk+0x2018>
    800065f4:	ffffc097          	auipc	ra,0xffffc
    800065f8:	b70080e7          	jalr	-1168(ra) # 80002164 <sleep>
  for(int i = 0; i < 3; i++){
    800065fc:	f8040a13          	addi	s4,s0,-128
{
    80006600:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006602:	894e                	mv	s2,s3
    80006604:	b765                	j	800065ac <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006606:	0002f697          	auipc	a3,0x2f
    8000660a:	9fa6b683          	ld	a3,-1542(a3) # 80035000 <disk+0x2000>
    8000660e:	96ba                	add	a3,a3,a4
    80006610:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006614:	0002d817          	auipc	a6,0x2d
    80006618:	9ec80813          	addi	a6,a6,-1556 # 80033000 <disk>
    8000661c:	0002f697          	auipc	a3,0x2f
    80006620:	9e468693          	addi	a3,a3,-1564 # 80035000 <disk+0x2000>
    80006624:	6290                	ld	a2,0(a3)
    80006626:	963a                	add	a2,a2,a4
    80006628:	00c65583          	lhu	a1,12(a2)
    8000662c:	0015e593          	ori	a1,a1,1
    80006630:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006634:	f8842603          	lw	a2,-120(s0)
    80006638:	628c                	ld	a1,0(a3)
    8000663a:	972e                	add	a4,a4,a1
    8000663c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006640:	20050593          	addi	a1,a0,512
    80006644:	0592                	slli	a1,a1,0x4
    80006646:	95c2                	add	a1,a1,a6
    80006648:	577d                	li	a4,-1
    8000664a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000664e:	00461713          	slli	a4,a2,0x4
    80006652:	6290                	ld	a2,0(a3)
    80006654:	963a                	add	a2,a2,a4
    80006656:	03078793          	addi	a5,a5,48
    8000665a:	97c2                	add	a5,a5,a6
    8000665c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000665e:	629c                	ld	a5,0(a3)
    80006660:	97ba                	add	a5,a5,a4
    80006662:	4605                	li	a2,1
    80006664:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006666:	629c                	ld	a5,0(a3)
    80006668:	97ba                	add	a5,a5,a4
    8000666a:	4809                	li	a6,2
    8000666c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006670:	629c                	ld	a5,0(a3)
    80006672:	97ba                	add	a5,a5,a4
    80006674:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006678:	00caa223          	sw	a2,4(s5) # 1004 <_entry-0x7fffeffc>
  disk.info[idx[0]].b = b;
    8000667c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006680:	6698                	ld	a4,8(a3)
    80006682:	00275783          	lhu	a5,2(a4)
    80006686:	8b9d                	andi	a5,a5,7
    80006688:	0786                	slli	a5,a5,0x1
    8000668a:	973e                	add	a4,a4,a5
    8000668c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006690:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006694:	6698                	ld	a4,8(a3)
    80006696:	00275783          	lhu	a5,2(a4)
    8000669a:	2785                	addiw	a5,a5,1
    8000669c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066a0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066a4:	100017b7          	lui	a5,0x10001
    800066a8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066ac:	004aa783          	lw	a5,4(s5)
    800066b0:	02c79163          	bne	a5,a2,800066d2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800066b4:	0002f917          	auipc	s2,0x2f
    800066b8:	a7490913          	addi	s2,s2,-1420 # 80035128 <disk+0x2128>
  while(b->disk == 1) {
    800066bc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066be:	85ca                	mv	a1,s2
    800066c0:	8556                	mv	a0,s5
    800066c2:	ffffc097          	auipc	ra,0xffffc
    800066c6:	aa2080e7          	jalr	-1374(ra) # 80002164 <sleep>
  while(b->disk == 1) {
    800066ca:	004aa783          	lw	a5,4(s5)
    800066ce:	fe9788e3          	beq	a5,s1,800066be <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800066d2:	f8042903          	lw	s2,-128(s0)
    800066d6:	20090713          	addi	a4,s2,512
    800066da:	0712                	slli	a4,a4,0x4
    800066dc:	0002d797          	auipc	a5,0x2d
    800066e0:	92478793          	addi	a5,a5,-1756 # 80033000 <disk>
    800066e4:	97ba                	add	a5,a5,a4
    800066e6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066ea:	0002f997          	auipc	s3,0x2f
    800066ee:	91698993          	addi	s3,s3,-1770 # 80035000 <disk+0x2000>
    800066f2:	00491713          	slli	a4,s2,0x4
    800066f6:	0009b783          	ld	a5,0(s3)
    800066fa:	97ba                	add	a5,a5,a4
    800066fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006700:	854a                	mv	a0,s2
    80006702:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006706:	00000097          	auipc	ra,0x0
    8000670a:	c60080e7          	jalr	-928(ra) # 80006366 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000670e:	8885                	andi	s1,s1,1
    80006710:	f0ed                	bnez	s1,800066f2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006712:	0002f517          	auipc	a0,0x2f
    80006716:	a1650513          	addi	a0,a0,-1514 # 80035128 <disk+0x2128>
    8000671a:	ffffa097          	auipc	ra,0xffffa
    8000671e:	5b6080e7          	jalr	1462(ra) # 80000cd0 <release>
}
    80006722:	70e6                	ld	ra,120(sp)
    80006724:	7446                	ld	s0,112(sp)
    80006726:	74a6                	ld	s1,104(sp)
    80006728:	7906                	ld	s2,96(sp)
    8000672a:	69e6                	ld	s3,88(sp)
    8000672c:	6a46                	ld	s4,80(sp)
    8000672e:	6aa6                	ld	s5,72(sp)
    80006730:	6b06                	ld	s6,64(sp)
    80006732:	7be2                	ld	s7,56(sp)
    80006734:	7c42                	ld	s8,48(sp)
    80006736:	7ca2                	ld	s9,40(sp)
    80006738:	7d02                	ld	s10,32(sp)
    8000673a:	6de2                	ld	s11,24(sp)
    8000673c:	6109                	addi	sp,sp,128
    8000673e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006740:	f8042503          	lw	a0,-128(s0)
    80006744:	20050793          	addi	a5,a0,512
    80006748:	0792                	slli	a5,a5,0x4
  if(write)
    8000674a:	0002d817          	auipc	a6,0x2d
    8000674e:	8b680813          	addi	a6,a6,-1866 # 80033000 <disk>
    80006752:	00f80733          	add	a4,a6,a5
    80006756:	01a036b3          	snez	a3,s10
    8000675a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000675e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006762:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006766:	7679                	lui	a2,0xffffe
    80006768:	963e                	add	a2,a2,a5
    8000676a:	0002f697          	auipc	a3,0x2f
    8000676e:	89668693          	addi	a3,a3,-1898 # 80035000 <disk+0x2000>
    80006772:	6298                	ld	a4,0(a3)
    80006774:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006776:	0a878593          	addi	a1,a5,168
    8000677a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000677c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000677e:	6298                	ld	a4,0(a3)
    80006780:	9732                	add	a4,a4,a2
    80006782:	45c1                	li	a1,16
    80006784:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006786:	6298                	ld	a4,0(a3)
    80006788:	9732                	add	a4,a4,a2
    8000678a:	4585                	li	a1,1
    8000678c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006790:	f8442703          	lw	a4,-124(s0)
    80006794:	628c                	ld	a1,0(a3)
    80006796:	962e                	add	a2,a2,a1
    80006798:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffc800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000679c:	0712                	slli	a4,a4,0x4
    8000679e:	6290                	ld	a2,0(a3)
    800067a0:	963a                	add	a2,a2,a4
    800067a2:	058a8593          	addi	a1,s5,88
    800067a6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800067a8:	6294                	ld	a3,0(a3)
    800067aa:	96ba                	add	a3,a3,a4
    800067ac:	40000613          	li	a2,1024
    800067b0:	c690                	sw	a2,8(a3)
  if(write)
    800067b2:	e40d1ae3          	bnez	s10,80006606 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800067b6:	0002f697          	auipc	a3,0x2f
    800067ba:	84a6b683          	ld	a3,-1974(a3) # 80035000 <disk+0x2000>
    800067be:	96ba                	add	a3,a3,a4
    800067c0:	4609                	li	a2,2
    800067c2:	00c69623          	sh	a2,12(a3)
    800067c6:	b5b9                	j	80006614 <virtio_disk_rw+0xd2>

00000000800067c8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067c8:	1101                	addi	sp,sp,-32
    800067ca:	ec06                	sd	ra,24(sp)
    800067cc:	e822                	sd	s0,16(sp)
    800067ce:	e426                	sd	s1,8(sp)
    800067d0:	e04a                	sd	s2,0(sp)
    800067d2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067d4:	0002f517          	auipc	a0,0x2f
    800067d8:	95450513          	addi	a0,a0,-1708 # 80035128 <disk+0x2128>
    800067dc:	ffffa097          	auipc	ra,0xffffa
    800067e0:	440080e7          	jalr	1088(ra) # 80000c1c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067e4:	10001737          	lui	a4,0x10001
    800067e8:	533c                	lw	a5,96(a4)
    800067ea:	8b8d                	andi	a5,a5,3
    800067ec:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067ee:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067f2:	0002f797          	auipc	a5,0x2f
    800067f6:	80e78793          	addi	a5,a5,-2034 # 80035000 <disk+0x2000>
    800067fa:	6b94                	ld	a3,16(a5)
    800067fc:	0207d703          	lhu	a4,32(a5)
    80006800:	0026d783          	lhu	a5,2(a3)
    80006804:	06f70163          	beq	a4,a5,80006866 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006808:	0002c917          	auipc	s2,0x2c
    8000680c:	7f890913          	addi	s2,s2,2040 # 80033000 <disk>
    80006810:	0002e497          	auipc	s1,0x2e
    80006814:	7f048493          	addi	s1,s1,2032 # 80035000 <disk+0x2000>
    __sync_synchronize();
    80006818:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000681c:	6898                	ld	a4,16(s1)
    8000681e:	0204d783          	lhu	a5,32(s1)
    80006822:	8b9d                	andi	a5,a5,7
    80006824:	078e                	slli	a5,a5,0x3
    80006826:	97ba                	add	a5,a5,a4
    80006828:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000682a:	20078713          	addi	a4,a5,512
    8000682e:	0712                	slli	a4,a4,0x4
    80006830:	974a                	add	a4,a4,s2
    80006832:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006836:	e731                	bnez	a4,80006882 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006838:	20078793          	addi	a5,a5,512
    8000683c:	0792                	slli	a5,a5,0x4
    8000683e:	97ca                	add	a5,a5,s2
    80006840:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006842:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006846:	ffffc097          	auipc	ra,0xffffc
    8000684a:	ac2080e7          	jalr	-1342(ra) # 80002308 <wakeup>

    disk.used_idx += 1;
    8000684e:	0204d783          	lhu	a5,32(s1)
    80006852:	2785                	addiw	a5,a5,1
    80006854:	17c2                	slli	a5,a5,0x30
    80006856:	93c1                	srli	a5,a5,0x30
    80006858:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000685c:	6898                	ld	a4,16(s1)
    8000685e:	00275703          	lhu	a4,2(a4)
    80006862:	faf71be3          	bne	a4,a5,80006818 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006866:	0002f517          	auipc	a0,0x2f
    8000686a:	8c250513          	addi	a0,a0,-1854 # 80035128 <disk+0x2128>
    8000686e:	ffffa097          	auipc	ra,0xffffa
    80006872:	462080e7          	jalr	1122(ra) # 80000cd0 <release>
}
    80006876:	60e2                	ld	ra,24(sp)
    80006878:	6442                	ld	s0,16(sp)
    8000687a:	64a2                	ld	s1,8(sp)
    8000687c:	6902                	ld	s2,0(sp)
    8000687e:	6105                	addi	sp,sp,32
    80006880:	8082                	ret
      panic("virtio_disk_intr status");
    80006882:	00002517          	auipc	a0,0x2
    80006886:	fd650513          	addi	a0,a0,-42 # 80008858 <syscalls+0x3d0>
    8000688a:	ffffa097          	auipc	ra,0xffffa
    8000688e:	cb2080e7          	jalr	-846(ra) # 8000053c <panic>
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
