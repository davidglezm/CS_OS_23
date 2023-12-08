
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
    80000062:	00007797          	auipc	a5,0x7
    80000066:	86e78793          	addi	a5,a5,-1938 # 800068d0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffc7b67>
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
    8000012e:	0cc080e7          	jalr	204(ra) # 800021f6 <either_copyin>
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
    800001c4:	934080e7          	jalr	-1740(ra) # 80001af4 <myproc>
    800001c8:	30052783          	lw	a5,768(a0)
    800001cc:	e7b5                	bnez	a5,80000238 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	d22080e7          	jalr	-734(ra) # 80001ef4 <sleep>
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
    80000212:	f90080e7          	jalr	-112(ra) # 8000219e <either_copyout>
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
    800002f2:	f60080e7          	jalr	-160(ra) # 8000224e <procdump>
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
    80000446:	b22080e7          	jalr	-1246(ra) # 80001f64 <wakeup>
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
    80000890:	00001097          	auipc	ra,0x1
    80000894:	6d4080e7          	jalr	1748(ra) # 80001f64 <wakeup>
    
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
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	5d8080e7          	jalr	1496(ra) # 80001ef4 <sleep>
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
    800009f8:	00036797          	auipc	a5,0x36
    800009fc:	2a078793          	addi	a5,a5,672 # 80036c98 <end>
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
    80000aca:	00036517          	auipc	a0,0x36
    80000ace:	1ce50513          	addi	a0,a0,462 # 80036c98 <end>
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
    80000bba:	f22080e7          	jalr	-222(ra) # 80001ad8 <mycpu>
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
    80000bec:	ef0080e7          	jalr	-272(ra) # 80001ad8 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	cf89                	beqz	a5,80000c0c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	ee4080e7          	jalr	-284(ra) # 80001ad8 <mycpu>
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
    80000c10:	ecc080e7          	jalr	-308(ra) # 80001ad8 <mycpu>
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
    80000c50:	e8c080e7          	jalr	-372(ra) # 80001ad8 <mycpu>
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
    80000c7c:	e60080e7          	jalr	-416(ra) # 80001ad8 <mycpu>
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
    80000d8c:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffc8369>
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
    80000eca:	c02080e7          	jalr	-1022(ra) # 80001ac8 <cpuid>
    mmrlistinit();   //  HW5 - Task 1a
    seminit();
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
    80000ee6:	be6080e7          	jalr	-1050(ra) # 80001ac8 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	692080e7          	jalr	1682(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e8080e7          	jalr	232(ra) # 80000fe4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	d9a080e7          	jalr	-614(ra) # 80002c9e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00006097          	auipc	ra,0x6
    80000f10:	a04080e7          	jalr	-1532(ra) # 80006910 <plicinithart>
  }

  scheduler();  
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	e14080e7          	jalr	-492(ra) # 80001d28 <scheduler>
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
    80000f68:	332080e7          	jalr	818(ra) # 80001296 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	078080e7          	jalr	120(ra) # 80000fe4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	aa0080e7          	jalr	-1376(ra) # 80001a14 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	cfa080e7          	jalr	-774(ra) # 80002c76 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	d1a080e7          	jalr	-742(ra) # 80002c9e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00006097          	auipc	ra,0x6
    80000f90:	96e080e7          	jalr	-1682(ra) # 800068fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00006097          	auipc	ra,0x6
    80000f98:	97c080e7          	jalr	-1668(ra) # 80006910 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00003097          	auipc	ra,0x3
    80000fa0:	87c080e7          	jalr	-1924(ra) # 80003818 <binit>
    iinit();         // inode table
    80000fa4:	00003097          	auipc	ra,0x3
    80000fa8:	f0a080e7          	jalr	-246(ra) # 80003eae <iinit>
    fileinit();      // file table
    80000fac:	00004097          	auipc	ra,0x4
    80000fb0:	ec0080e7          	jalr	-320(ra) # 80004e6c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00006097          	auipc	ra,0x6
    80000fb8:	a7c080e7          	jalr	-1412(ra) # 80006a30 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	750080e7          	jalr	1872(ra) # 8000270c <userinit>
    mmrlistinit();   //  HW5 - Task 1a
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	3fa080e7          	jalr	1018(ra) # 800023be <mmrlistinit>
    seminit();
    80000fcc:	00006097          	auipc	ra,0x6
    80000fd0:	ef6080e7          	jalr	-266(ra) # 80006ec2 <seminit>
    __sync_synchronize();
    80000fd4:	0ff0000f          	fence
    started = 1;
    80000fd8:	4785                	li	a5,1
    80000fda:	00008717          	auipc	a4,0x8
    80000fde:	02f72f23          	sw	a5,62(a4) # 80009018 <started>
    80000fe2:	bf0d                	j	80000f14 <main+0x56>

0000000080000fe4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe4:	1141                	addi	sp,sp,-16
    80000fe6:	e422                	sd	s0,8(sp)
    80000fe8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fea:	00008797          	auipc	a5,0x8
    80000fee:	0367b783          	ld	a5,54(a5) # 80009020 <kernel_pagetable>
    80000ff2:	83b1                	srli	a5,a5,0xc
    80000ff4:	577d                	li	a4,-1
    80000ff6:	177e                	slli	a4,a4,0x3f
    80000ff8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ffa:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ffe:	12000073          	sfence.vma
  sfence_vma();
}
    80001002:	6422                	ld	s0,8(sp)
    80001004:	0141                	addi	sp,sp,16
    80001006:	8082                	ret

0000000080001008 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001008:	7139                	addi	sp,sp,-64
    8000100a:	fc06                	sd	ra,56(sp)
    8000100c:	f822                	sd	s0,48(sp)
    8000100e:	f426                	sd	s1,40(sp)
    80001010:	f04a                	sd	s2,32(sp)
    80001012:	ec4e                	sd	s3,24(sp)
    80001014:	e852                	sd	s4,16(sp)
    80001016:	e456                	sd	s5,8(sp)
    80001018:	e05a                	sd	s6,0(sp)
    8000101a:	0080                	addi	s0,sp,64
    8000101c:	84aa                	mv	s1,a0
    8000101e:	89ae                	mv	s3,a1
    80001020:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001022:	57fd                	li	a5,-1
    80001024:	83e9                	srli	a5,a5,0x1a
    80001026:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001028:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000102a:	04b7f263          	bgeu	a5,a1,8000106e <walk+0x66>
    panic("walk");
    8000102e:	00007517          	auipc	a0,0x7
    80001032:	0a250513          	addi	a0,a0,162 # 800080d0 <digits+0x90>
    80001036:	fffff097          	auipc	ra,0xfffff
    8000103a:	506080e7          	jalr	1286(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000103e:	060a8663          	beqz	s5,800010aa <walk+0xa2>
    80001042:	00000097          	auipc	ra,0x0
    80001046:	aa0080e7          	jalr	-1376(ra) # 80000ae2 <kalloc>
    8000104a:	84aa                	mv	s1,a0
    8000104c:	c529                	beqz	a0,80001096 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000104e:	6605                	lui	a2,0x1
    80001050:	4581                	li	a1,0
    80001052:	00000097          	auipc	ra,0x0
    80001056:	cc6080e7          	jalr	-826(ra) # 80000d18 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000105a:	00c4d793          	srli	a5,s1,0xc
    8000105e:	07aa                	slli	a5,a5,0xa
    80001060:	0017e793          	ori	a5,a5,1
    80001064:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001068:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffc835f>
    8000106a:	036a0063          	beq	s4,s6,8000108a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000106e:	0149d933          	srl	s2,s3,s4
    80001072:	1ff97913          	andi	s2,s2,511
    80001076:	090e                	slli	s2,s2,0x3
    80001078:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000107a:	00093483          	ld	s1,0(s2)
    8000107e:	0014f793          	andi	a5,s1,1
    80001082:	dfd5                	beqz	a5,8000103e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001084:	80a9                	srli	s1,s1,0xa
    80001086:	04b2                	slli	s1,s1,0xc
    80001088:	b7c5                	j	80001068 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000108a:	00c9d513          	srli	a0,s3,0xc
    8000108e:	1ff57513          	andi	a0,a0,511
    80001092:	050e                	slli	a0,a0,0x3
    80001094:	9526                	add	a0,a0,s1
}
    80001096:	70e2                	ld	ra,56(sp)
    80001098:	7442                	ld	s0,48(sp)
    8000109a:	74a2                	ld	s1,40(sp)
    8000109c:	7902                	ld	s2,32(sp)
    8000109e:	69e2                	ld	s3,24(sp)
    800010a0:	6a42                	ld	s4,16(sp)
    800010a2:	6aa2                	ld	s5,8(sp)
    800010a4:	6b02                	ld	s6,0(sp)
    800010a6:	6121                	addi	sp,sp,64
    800010a8:	8082                	ret
        return 0;
    800010aa:	4501                	li	a0,0
    800010ac:	b7ed                	j	80001096 <walk+0x8e>

00000000800010ae <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010ae:	57fd                	li	a5,-1
    800010b0:	83e9                	srli	a5,a5,0x1a
    800010b2:	00b7f463          	bgeu	a5,a1,800010ba <walkaddr+0xc>
    return 0;
    800010b6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b8:	8082                	ret
{
    800010ba:	1141                	addi	sp,sp,-16
    800010bc:	e406                	sd	ra,8(sp)
    800010be:	e022                	sd	s0,0(sp)
    800010c0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010c2:	4601                	li	a2,0
    800010c4:	00000097          	auipc	ra,0x0
    800010c8:	f44080e7          	jalr	-188(ra) # 80001008 <walk>
  if(pte == 0)
    800010cc:	c105                	beqz	a0,800010ec <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010ce:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010d0:	0117f693          	andi	a3,a5,17
    800010d4:	4745                	li	a4,17
    return 0;
    800010d6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d8:	00e68663          	beq	a3,a4,800010e4 <walkaddr+0x36>
}
    800010dc:	60a2                	ld	ra,8(sp)
    800010de:	6402                	ld	s0,0(sp)
    800010e0:	0141                	addi	sp,sp,16
    800010e2:	8082                	ret
  pa = PTE2PA(*pte);
    800010e4:	83a9                	srli	a5,a5,0xa
    800010e6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010ea:	bfcd                	j	800010dc <walkaddr+0x2e>
    return 0;
    800010ec:	4501                	li	a0,0
    800010ee:	b7fd                	j	800010dc <walkaddr+0x2e>

00000000800010f0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010f0:	715d                	addi	sp,sp,-80
    800010f2:	e486                	sd	ra,72(sp)
    800010f4:	e0a2                	sd	s0,64(sp)
    800010f6:	fc26                	sd	s1,56(sp)
    800010f8:	f84a                	sd	s2,48(sp)
    800010fa:	f44e                	sd	s3,40(sp)
    800010fc:	f052                	sd	s4,32(sp)
    800010fe:	ec56                	sd	s5,24(sp)
    80001100:	e85a                	sd	s6,16(sp)
    80001102:	e45e                	sd	s7,8(sp)
    80001104:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001106:	c639                	beqz	a2,80001154 <mappages+0x64>
    80001108:	8aaa                	mv	s5,a0
    8000110a:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000110c:	777d                	lui	a4,0xfffff
    8000110e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001112:	fff58993          	addi	s3,a1,-1
    80001116:	99b2                	add	s3,s3,a2
    80001118:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000111c:	893e                	mv	s2,a5
    8000111e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001122:	6b85                	lui	s7,0x1
    80001124:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001128:	4605                	li	a2,1
    8000112a:	85ca                	mv	a1,s2
    8000112c:	8556                	mv	a0,s5
    8000112e:	00000097          	auipc	ra,0x0
    80001132:	eda080e7          	jalr	-294(ra) # 80001008 <walk>
    80001136:	cd1d                	beqz	a0,80001174 <mappages+0x84>
    if(*pte & PTE_V)
    80001138:	611c                	ld	a5,0(a0)
    8000113a:	8b85                	andi	a5,a5,1
    8000113c:	e785                	bnez	a5,80001164 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000113e:	80b1                	srli	s1,s1,0xc
    80001140:	04aa                	slli	s1,s1,0xa
    80001142:	0164e4b3          	or	s1,s1,s6
    80001146:	0014e493          	ori	s1,s1,1
    8000114a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000114c:	05390063          	beq	s2,s3,8000118c <mappages+0x9c>
    a += PGSIZE;
    80001150:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001152:	bfc9                	j	80001124 <mappages+0x34>
    panic("mappages: size");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8450513          	addi	a0,a0,-124 # 800080d8 <digits+0x98>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3e0080e7          	jalr	992(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001164:	00007517          	auipc	a0,0x7
    80001168:	f8450513          	addi	a0,a0,-124 # 800080e8 <digits+0xa8>
    8000116c:	fffff097          	auipc	ra,0xfffff
    80001170:	3d0080e7          	jalr	976(ra) # 8000053c <panic>
      return -1;
    80001174:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001176:	60a6                	ld	ra,72(sp)
    80001178:	6406                	ld	s0,64(sp)
    8000117a:	74e2                	ld	s1,56(sp)
    8000117c:	7942                	ld	s2,48(sp)
    8000117e:	79a2                	ld	s3,40(sp)
    80001180:	7a02                	ld	s4,32(sp)
    80001182:	6ae2                	ld	s5,24(sp)
    80001184:	6b42                	ld	s6,16(sp)
    80001186:	6ba2                	ld	s7,8(sp)
    80001188:	6161                	addi	sp,sp,80
    8000118a:	8082                	ret
  return 0;
    8000118c:	4501                	li	a0,0
    8000118e:	b7e5                	j	80001176 <mappages+0x86>

0000000080001190 <kvmmap>:
{
    80001190:	1141                	addi	sp,sp,-16
    80001192:	e406                	sd	ra,8(sp)
    80001194:	e022                	sd	s0,0(sp)
    80001196:	0800                	addi	s0,sp,16
    80001198:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000119a:	86b2                	mv	a3,a2
    8000119c:	863e                	mv	a2,a5
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	f52080e7          	jalr	-174(ra) # 800010f0 <mappages>
    800011a6:	e509                	bnez	a0,800011b0 <kvmmap+0x20>
}
    800011a8:	60a2                	ld	ra,8(sp)
    800011aa:	6402                	ld	s0,0(sp)
    800011ac:	0141                	addi	sp,sp,16
    800011ae:	8082                	ret
    panic("kvmmap");
    800011b0:	00007517          	auipc	a0,0x7
    800011b4:	f4850513          	addi	a0,a0,-184 # 800080f8 <digits+0xb8>
    800011b8:	fffff097          	auipc	ra,0xfffff
    800011bc:	384080e7          	jalr	900(ra) # 8000053c <panic>

00000000800011c0 <kvmmake>:
{
    800011c0:	1101                	addi	sp,sp,-32
    800011c2:	ec06                	sd	ra,24(sp)
    800011c4:	e822                	sd	s0,16(sp)
    800011c6:	e426                	sd	s1,8(sp)
    800011c8:	e04a                	sd	s2,0(sp)
    800011ca:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	916080e7          	jalr	-1770(ra) # 80000ae2 <kalloc>
    800011d4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011d6:	6605                	lui	a2,0x1
    800011d8:	4581                	li	a1,0
    800011da:	00000097          	auipc	ra,0x0
    800011de:	b3e080e7          	jalr	-1218(ra) # 80000d18 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011e2:	4719                	li	a4,6
    800011e4:	6685                	lui	a3,0x1
    800011e6:	10000637          	lui	a2,0x10000
    800011ea:	100005b7          	lui	a1,0x10000
    800011ee:	8526                	mv	a0,s1
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	fa0080e7          	jalr	-96(ra) # 80001190 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011f8:	4719                	li	a4,6
    800011fa:	6685                	lui	a3,0x1
    800011fc:	10001637          	lui	a2,0x10001
    80001200:	100015b7          	lui	a1,0x10001
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f8a080e7          	jalr	-118(ra) # 80001190 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000120e:	4719                	li	a4,6
    80001210:	004006b7          	lui	a3,0x400
    80001214:	0c000637          	lui	a2,0xc000
    80001218:	0c0005b7          	lui	a1,0xc000
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f72080e7          	jalr	-142(ra) # 80001190 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001226:	00007917          	auipc	s2,0x7
    8000122a:	dda90913          	addi	s2,s2,-550 # 80008000 <etext>
    8000122e:	4729                	li	a4,10
    80001230:	80007697          	auipc	a3,0x80007
    80001234:	dd068693          	addi	a3,a3,-560 # 8000 <_entry-0x7fff8000>
    80001238:	4605                	li	a2,1
    8000123a:	067e                	slli	a2,a2,0x1f
    8000123c:	85b2                	mv	a1,a2
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f50080e7          	jalr	-176(ra) # 80001190 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001248:	4719                	li	a4,6
    8000124a:	46c5                	li	a3,17
    8000124c:	06ee                	slli	a3,a3,0x1b
    8000124e:	412686b3          	sub	a3,a3,s2
    80001252:	864a                	mv	a2,s2
    80001254:	85ca                	mv	a1,s2
    80001256:	8526                	mv	a0,s1
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	f38080e7          	jalr	-200(ra) # 80001190 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001260:	4729                	li	a4,10
    80001262:	6685                	lui	a3,0x1
    80001264:	00006617          	auipc	a2,0x6
    80001268:	d9c60613          	addi	a2,a2,-612 # 80007000 <_trampoline>
    8000126c:	040005b7          	lui	a1,0x4000
    80001270:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001272:	05b2                	slli	a1,a1,0xc
    80001274:	8526                	mv	a0,s1
    80001276:	00000097          	auipc	ra,0x0
    8000127a:	f1a080e7          	jalr	-230(ra) # 80001190 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	6fe080e7          	jalr	1790(ra) # 8000197e <proc_mapstacks>
}
    80001288:	8526                	mv	a0,s1
    8000128a:	60e2                	ld	ra,24(sp)
    8000128c:	6442                	ld	s0,16(sp)
    8000128e:	64a2                	ld	s1,8(sp)
    80001290:	6902                	ld	s2,0(sp)
    80001292:	6105                	addi	sp,sp,32
    80001294:	8082                	ret

0000000080001296 <kvminit>:
{
    80001296:	1141                	addi	sp,sp,-16
    80001298:	e406                	sd	ra,8(sp)
    8000129a:	e022                	sd	s0,0(sp)
    8000129c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	f22080e7          	jalr	-222(ra) # 800011c0 <kvmmake>
    800012a6:	00008797          	auipc	a5,0x8
    800012aa:	d6a7bd23          	sd	a0,-646(a5) # 80009020 <kernel_pagetable>
}
    800012ae:	60a2                	ld	ra,8(sp)
    800012b0:	6402                	ld	s0,0(sp)
    800012b2:	0141                	addi	sp,sp,16
    800012b4:	8082                	ret

00000000800012b6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012b6:	715d                	addi	sp,sp,-80
    800012b8:	e486                	sd	ra,72(sp)
    800012ba:	e0a2                	sd	s0,64(sp)
    800012bc:	fc26                	sd	s1,56(sp)
    800012be:	f84a                	sd	s2,48(sp)
    800012c0:	f44e                	sd	s3,40(sp)
    800012c2:	f052                	sd	s4,32(sp)
    800012c4:	ec56                	sd	s5,24(sp)
    800012c6:	e85a                	sd	s6,16(sp)
    800012c8:	e45e                	sd	s7,8(sp)
    800012ca:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012cc:	03459793          	slli	a5,a1,0x34
    800012d0:	e795                	bnez	a5,800012fc <uvmunmap+0x46>
    800012d2:	8a2a                	mv	s4,a0
    800012d4:	892e                	mv	s2,a1
    800012d6:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	0632                	slli	a2,a2,0xc
    800012da:	00b609b3          	add	s3,a2,a1
      // panic("uvmunmap: walk");
      continue;
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped"); -- HW 4 - TASK 4
    if(PTE_FLAGS(*pte) == PTE_V)
    800012de:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e0:	6a85                	lui	s5,0x1
    800012e2:	0535e263          	bltu	a1,s3,80001326 <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012e6:	60a6                	ld	ra,72(sp)
    800012e8:	6406                	ld	s0,64(sp)
    800012ea:	74e2                	ld	s1,56(sp)
    800012ec:	7942                	ld	s2,48(sp)
    800012ee:	79a2                	ld	s3,40(sp)
    800012f0:	7a02                	ld	s4,32(sp)
    800012f2:	6ae2                	ld	s5,24(sp)
    800012f4:	6b42                	ld	s6,16(sp)
    800012f6:	6ba2                	ld	s7,8(sp)
    800012f8:	6161                	addi	sp,sp,80
    800012fa:	8082                	ret
    panic("uvmunmap: not aligned");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e0450513          	addi	a0,a0,-508 # 80008100 <digits+0xc0>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	238080e7          	jalr	568(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    8000130c:	00007517          	auipc	a0,0x7
    80001310:	e0c50513          	addi	a0,a0,-500 # 80008118 <digits+0xd8>
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	228080e7          	jalr	552(ra) # 8000053c <panic>
    *pte = 0;
    8000131c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001320:	9956                	add	s2,s2,s5
    80001322:	fd3972e3          	bgeu	s2,s3,800012e6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001326:	4601                	li	a2,0
    80001328:	85ca                	mv	a1,s2
    8000132a:	8552                	mv	a0,s4
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	cdc080e7          	jalr	-804(ra) # 80001008 <walk>
    80001334:	84aa                	mv	s1,a0
    80001336:	d56d                	beqz	a0,80001320 <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    80001338:	611c                	ld	a5,0(a0)
    8000133a:	0017f713          	andi	a4,a5,1
    8000133e:	d36d                	beqz	a4,80001320 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001340:	3ff7f713          	andi	a4,a5,1023
    80001344:	fd7704e3          	beq	a4,s7,8000130c <uvmunmap+0x56>
    if(do_free){
    80001348:	fc0b0ae3          	beqz	s6,8000131c <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    8000134c:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000134e:	00c79513          	slli	a0,a5,0xc
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	692080e7          	jalr	1682(ra) # 800009e4 <kfree>
    8000135a:	b7c9                	j	8000131c <uvmunmap+0x66>

000000008000135c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135c:	1101                	addi	sp,sp,-32
    8000135e:	ec06                	sd	ra,24(sp)
    80001360:	e822                	sd	s0,16(sp)
    80001362:	e426                	sd	s1,8(sp)
    80001364:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001366:	fffff097          	auipc	ra,0xfffff
    8000136a:	77c080e7          	jalr	1916(ra) # 80000ae2 <kalloc>
    8000136e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001370:	c519                	beqz	a0,8000137e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	9a2080e7          	jalr	-1630(ra) # 80000d18 <memset>
  return pagetable;
}
    8000137e:	8526                	mv	a0,s1
    80001380:	60e2                	ld	ra,24(sp)
    80001382:	6442                	ld	s0,16(sp)
    80001384:	64a2                	ld	s1,8(sp)
    80001386:	6105                	addi	sp,sp,32
    80001388:	8082                	ret

000000008000138a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138a:	7179                	addi	sp,sp,-48
    8000138c:	f406                	sd	ra,40(sp)
    8000138e:	f022                	sd	s0,32(sp)
    80001390:	ec26                	sd	s1,24(sp)
    80001392:	e84a                	sd	s2,16(sp)
    80001394:	e44e                	sd	s3,8(sp)
    80001396:	e052                	sd	s4,0(sp)
    80001398:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139a:	6785                	lui	a5,0x1
    8000139c:	04f67863          	bgeu	a2,a5,800013ec <uvminit+0x62>
    800013a0:	8a2a                	mv	s4,a0
    800013a2:	89ae                	mv	s3,a1
    800013a4:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	73c080e7          	jalr	1852(ra) # 80000ae2 <kalloc>
    800013ae:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	964080e7          	jalr	-1692(ra) # 80000d18 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013bc:	4779                	li	a4,30
    800013be:	86ca                	mv	a3,s2
    800013c0:	6605                	lui	a2,0x1
    800013c2:	4581                	li	a1,0
    800013c4:	8552                	mv	a0,s4
    800013c6:	00000097          	auipc	ra,0x0
    800013ca:	d2a080e7          	jalr	-726(ra) # 800010f0 <mappages>
  memmove(mem, src, sz);
    800013ce:	8626                	mv	a2,s1
    800013d0:	85ce                	mv	a1,s3
    800013d2:	854a                	mv	a0,s2
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	9a0080e7          	jalr	-1632(ra) # 80000d74 <memmove>
}
    800013dc:	70a2                	ld	ra,40(sp)
    800013de:	7402                	ld	s0,32(sp)
    800013e0:	64e2                	ld	s1,24(sp)
    800013e2:	6942                	ld	s2,16(sp)
    800013e4:	69a2                	ld	s3,8(sp)
    800013e6:	6a02                	ld	s4,0(sp)
    800013e8:	6145                	addi	sp,sp,48
    800013ea:	8082                	ret
    panic("inituvm: more than a page");
    800013ec:	00007517          	auipc	a0,0x7
    800013f0:	d4450513          	addi	a0,a0,-700 # 80008130 <digits+0xf0>
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	148080e7          	jalr	328(ra) # 8000053c <panic>

00000000800013fc <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fc:	1101                	addi	sp,sp,-32
    800013fe:	ec06                	sd	ra,24(sp)
    80001400:	e822                	sd	s0,16(sp)
    80001402:	e426                	sd	s1,8(sp)
    80001404:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001406:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001408:	00b67d63          	bgeu	a2,a1,80001422 <uvmdealloc+0x26>
    8000140c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000140e:	6785                	lui	a5,0x1
    80001410:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001412:	00f60733          	add	a4,a2,a5
    80001416:	76fd                	lui	a3,0xfffff
    80001418:	8f75                	and	a4,a4,a3
    8000141a:	97ae                	add	a5,a5,a1
    8000141c:	8ff5                	and	a5,a5,a3
    8000141e:	00f76863          	bltu	a4,a5,8000142e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001422:	8526                	mv	a0,s1
    80001424:	60e2                	ld	ra,24(sp)
    80001426:	6442                	ld	s0,16(sp)
    80001428:	64a2                	ld	s1,8(sp)
    8000142a:	6105                	addi	sp,sp,32
    8000142c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000142e:	8f99                	sub	a5,a5,a4
    80001430:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001432:	4685                	li	a3,1
    80001434:	0007861b          	sext.w	a2,a5
    80001438:	85ba                	mv	a1,a4
    8000143a:	00000097          	auipc	ra,0x0
    8000143e:	e7c080e7          	jalr	-388(ra) # 800012b6 <uvmunmap>
    80001442:	b7c5                	j	80001422 <uvmdealloc+0x26>

0000000080001444 <uvmalloc>:
  if(newsz < oldsz)
    80001444:	0ab66163          	bltu	a2,a1,800014e6 <uvmalloc+0xa2>
{
    80001448:	7139                	addi	sp,sp,-64
    8000144a:	fc06                	sd	ra,56(sp)
    8000144c:	f822                	sd	s0,48(sp)
    8000144e:	f426                	sd	s1,40(sp)
    80001450:	f04a                	sd	s2,32(sp)
    80001452:	ec4e                	sd	s3,24(sp)
    80001454:	e852                	sd	s4,16(sp)
    80001456:	e456                	sd	s5,8(sp)
    80001458:	0080                	addi	s0,sp,64
    8000145a:	8aaa                	mv	s5,a0
    8000145c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000145e:	6785                	lui	a5,0x1
    80001460:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001462:	95be                	add	a1,a1,a5
    80001464:	77fd                	lui	a5,0xfffff
    80001466:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146a:	08c9f063          	bgeu	s3,a2,800014ea <uvmalloc+0xa6>
    8000146e:	894e                	mv	s2,s3
    mem = kalloc();
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	672080e7          	jalr	1650(ra) # 80000ae2 <kalloc>
    80001478:	84aa                	mv	s1,a0
    if(mem == 0){
    8000147a:	c51d                	beqz	a0,800014a8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000147c:	6605                	lui	a2,0x1
    8000147e:	4581                	li	a1,0
    80001480:	00000097          	auipc	ra,0x0
    80001484:	898080e7          	jalr	-1896(ra) # 80000d18 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001488:	4779                	li	a4,30
    8000148a:	86a6                	mv	a3,s1
    8000148c:	6605                	lui	a2,0x1
    8000148e:	85ca                	mv	a1,s2
    80001490:	8556                	mv	a0,s5
    80001492:	00000097          	auipc	ra,0x0
    80001496:	c5e080e7          	jalr	-930(ra) # 800010f0 <mappages>
    8000149a:	e905                	bnez	a0,800014ca <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149c:	6785                	lui	a5,0x1
    8000149e:	993e                	add	s2,s2,a5
    800014a0:	fd4968e3          	bltu	s2,s4,80001470 <uvmalloc+0x2c>
  return newsz;
    800014a4:	8552                	mv	a0,s4
    800014a6:	a809                	j	800014b8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f4e080e7          	jalr	-178(ra) # 800013fc <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
}
    800014b8:	70e2                	ld	ra,56(sp)
    800014ba:	7442                	ld	s0,48(sp)
    800014bc:	74a2                	ld	s1,40(sp)
    800014be:	7902                	ld	s2,32(sp)
    800014c0:	69e2                	ld	s3,24(sp)
    800014c2:	6a42                	ld	s4,16(sp)
    800014c4:	6aa2                	ld	s5,8(sp)
    800014c6:	6121                	addi	sp,sp,64
    800014c8:	8082                	ret
      kfree(mem);
    800014ca:	8526                	mv	a0,s1
    800014cc:	fffff097          	auipc	ra,0xfffff
    800014d0:	518080e7          	jalr	1304(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014d4:	864e                	mv	a2,s3
    800014d6:	85ca                	mv	a1,s2
    800014d8:	8556                	mv	a0,s5
    800014da:	00000097          	auipc	ra,0x0
    800014de:	f22080e7          	jalr	-222(ra) # 800013fc <uvmdealloc>
      return 0;
    800014e2:	4501                	li	a0,0
    800014e4:	bfd1                	j	800014b8 <uvmalloc+0x74>
    return oldsz;
    800014e6:	852e                	mv	a0,a1
}
    800014e8:	8082                	ret
  return newsz;
    800014ea:	8532                	mv	a0,a2
    800014ec:	b7f1                	j	800014b8 <uvmalloc+0x74>

00000000800014ee <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ee:	7179                	addi	sp,sp,-48
    800014f0:	f406                	sd	ra,40(sp)
    800014f2:	f022                	sd	s0,32(sp)
    800014f4:	ec26                	sd	s1,24(sp)
    800014f6:	e84a                	sd	s2,16(sp)
    800014f8:	e44e                	sd	s3,8(sp)
    800014fa:	e052                	sd	s4,0(sp)
    800014fc:	1800                	addi	s0,sp,48
    800014fe:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001500:	84aa                	mv	s1,a0
    80001502:	6905                	lui	s2,0x1
    80001504:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001506:	4985                	li	s3,1
    80001508:	a829                	j	80001522 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000150a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000150c:	00c79513          	slli	a0,a5,0xc
    80001510:	00000097          	auipc	ra,0x0
    80001514:	fde080e7          	jalr	-34(ra) # 800014ee <freewalk>
      pagetable[i] = 0;
    80001518:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000151c:	04a1                	addi	s1,s1,8
    8000151e:	03248163          	beq	s1,s2,80001540 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001522:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001524:	00f7f713          	andi	a4,a5,15
    80001528:	ff3701e3          	beq	a4,s3,8000150a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000152c:	8b85                	andi	a5,a5,1
    8000152e:	d7fd                	beqz	a5,8000151c <freewalk+0x2e>
      panic("freewalk: leaf");
    80001530:	00007517          	auipc	a0,0x7
    80001534:	c2050513          	addi	a0,a0,-992 # 80008150 <digits+0x110>
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	004080e7          	jalr	4(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001540:	8552                	mv	a0,s4
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	4a2080e7          	jalr	1186(ra) # 800009e4 <kfree>
}
    8000154a:	70a2                	ld	ra,40(sp)
    8000154c:	7402                	ld	s0,32(sp)
    8000154e:	64e2                	ld	s1,24(sp)
    80001550:	6942                	ld	s2,16(sp)
    80001552:	69a2                	ld	s3,8(sp)
    80001554:	6a02                	ld	s4,0(sp)
    80001556:	6145                	addi	sp,sp,48
    80001558:	8082                	ret

000000008000155a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000155a:	1101                	addi	sp,sp,-32
    8000155c:	ec06                	sd	ra,24(sp)
    8000155e:	e822                	sd	s0,16(sp)
    80001560:	e426                	sd	s1,8(sp)
    80001562:	1000                	addi	s0,sp,32
    80001564:	84aa                	mv	s1,a0
  if(sz > 0)
    80001566:	e999                	bnez	a1,8000157c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001568:	8526                	mv	a0,s1
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	f84080e7          	jalr	-124(ra) # 800014ee <freewalk>
}
    80001572:	60e2                	ld	ra,24(sp)
    80001574:	6442                	ld	s0,16(sp)
    80001576:	64a2                	ld	s1,8(sp)
    80001578:	6105                	addi	sp,sp,32
    8000157a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000157c:	6785                	lui	a5,0x1
    8000157e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001580:	95be                	add	a1,a1,a5
    80001582:	4685                	li	a3,1
    80001584:	00c5d613          	srli	a2,a1,0xc
    80001588:	4581                	li	a1,0
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	d2c080e7          	jalr	-724(ra) # 800012b6 <uvmunmap>
    80001592:	bfd9                	j	80001568 <uvmfree+0xe>

0000000080001594 <uvmcopy>:
//   return -1;
// }
// HW5-TASK 2 change
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 start, uint64 end)
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
    800015ae:	89b2                	mv	s3,a2
    800015b0:	8a36                	mv	s4,a3
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = start; i < end; i += PGSIZE){
    800015b2:	0ad67963          	bgeu	a2,a3,80001664 <uvmcopy+0xd0>
    if((pte = walk(old, i, 0)) == 0)
    800015b6:	4601                	li	a2,0
    800015b8:	85ce                	mv	a1,s3
    800015ba:	855a                	mv	a0,s6
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	a4c080e7          	jalr	-1460(ra) # 80001008 <walk>
    800015c4:	c531                	beqz	a0,80001610 <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015c6:	6118                	ld	a4,0(a0)
    800015c8:	00177793          	andi	a5,a4,1
    800015cc:	cbb1                	beqz	a5,80001620 <uvmcopy+0x8c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ce:	00a75593          	srli	a1,a4,0xa
    800015d2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015d6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015da:	fffff097          	auipc	ra,0xfffff
    800015de:	508080e7          	jalr	1288(ra) # 80000ae2 <kalloc>
    800015e2:	892a                	mv	s2,a0
    800015e4:	c939                	beqz	a0,8000163a <uvmcopy+0xa6>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015e6:	6605                	lui	a2,0x1
    800015e8:	85de                	mv	a1,s7
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	78a080e7          	jalr	1930(ra) # 80000d74 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015f2:	8726                	mv	a4,s1
    800015f4:	86ca                	mv	a3,s2
    800015f6:	6605                	lui	a2,0x1
    800015f8:	85ce                	mv	a1,s3
    800015fa:	8556                	mv	a0,s5
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	af4080e7          	jalr	-1292(ra) # 800010f0 <mappages>
    80001604:	e515                	bnez	a0,80001630 <uvmcopy+0x9c>
  for(i = start; i < end; i += PGSIZE){
    80001606:	6785                	lui	a5,0x1
    80001608:	99be                	add	s3,s3,a5
    8000160a:	fb49e6e3          	bltu	s3,s4,800015b6 <uvmcopy+0x22>
    8000160e:	a081                	j	8000164e <uvmcopy+0xba>
      panic("uvmcopy: pte should exist");
    80001610:	00007517          	auipc	a0,0x7
    80001614:	b5050513          	addi	a0,a0,-1200 # 80008160 <digits+0x120>
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	f24080e7          	jalr	-220(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001620:	00007517          	auipc	a0,0x7
    80001624:	b6050513          	addi	a0,a0,-1184 # 80008180 <digits+0x140>
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	f14080e7          	jalr	-236(ra) # 8000053c <panic>
      kfree(mem);
    80001630:	854a                	mv	a0,s2
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	3b2080e7          	jalr	946(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000163a:	4685                	li	a3,1
    8000163c:	00c9d613          	srli	a2,s3,0xc
    80001640:	4581                	li	a1,0
    80001642:	8556                	mv	a0,s5
    80001644:	00000097          	auipc	ra,0x0
    80001648:	c72080e7          	jalr	-910(ra) # 800012b6 <uvmunmap>
  return -1;
    8000164c:	557d                	li	a0,-1
}
    8000164e:	60a6                	ld	ra,72(sp)
    80001650:	6406                	ld	s0,64(sp)
    80001652:	74e2                	ld	s1,56(sp)
    80001654:	7942                	ld	s2,48(sp)
    80001656:	79a2                	ld	s3,40(sp)
    80001658:	7a02                	ld	s4,32(sp)
    8000165a:	6ae2                	ld	s5,24(sp)
    8000165c:	6b42                	ld	s6,16(sp)
    8000165e:	6ba2                	ld	s7,8(sp)
    80001660:	6161                	addi	sp,sp,80
    80001662:	8082                	ret
  return 0;
    80001664:	4501                	li	a0,0
    80001666:	b7e5                	j	8000164e <uvmcopy+0xba>

0000000080001668 <uvmcopyshared>:
// Copies the parent process’s page table to the child
// Duplicates the page table mappings so that the physical memory is shared
// Returns 0 on success, -1 on failure
int
uvmcopyshared(pagetable_t old, pagetable_t new, uint64 start, uint64 end)
{
    80001668:	7179                	addi	sp,sp,-48
    8000166a:	f406                	sd	ra,40(sp)
    8000166c:	f022                	sd	s0,32(sp)
    8000166e:	ec26                	sd	s1,24(sp)
    80001670:	e84a                	sd	s2,16(sp)
    80001672:	e44e                	sd	s3,8(sp)
    80001674:	e052                	sd	s4,0(sp)
    80001676:	1800                	addi	s0,sp,48
    80001678:	8a2a                	mv	s4,a0
    8000167a:	89ae                	mv	s3,a1
    8000167c:	84b2                	mv	s1,a2
    8000167e:	8936                	mv	s2,a3
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = start; i < end; i += PGSIZE){
    80001680:	08d67263          	bgeu	a2,a3,80001704 <uvmcopyshared+0x9c>
    if((pte = walk(old, i, 0)) == 0)
    80001684:	4601                	li	a2,0
    80001686:	85a6                	mv	a1,s1
    80001688:	8552                	mv	a0,s4
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	97e080e7          	jalr	-1666(ra) # 80001008 <walk>
    80001692:	c51d                	beqz	a0,800016c0 <uvmcopyshared+0x58>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001694:	6118                	ld	a4,0(a0)
    80001696:	00177793          	andi	a5,a4,1
    8000169a:	cb9d                	beqz	a5,800016d0 <uvmcopyshared+0x68>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000169c:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    800016a0:	3ff77713          	andi	a4,a4,1023
    800016a4:	06b2                	slli	a3,a3,0xc
    800016a6:	6605                	lui	a2,0x1
    800016a8:	85a6                	mv	a1,s1
    800016aa:	854e                	mv	a0,s3
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	a44080e7          	jalr	-1468(ra) # 800010f0 <mappages>
    800016b4:	e515                	bnez	a0,800016e0 <uvmcopyshared+0x78>
  for(i = start; i < end; i += PGSIZE){
    800016b6:	6785                	lui	a5,0x1
    800016b8:	94be                	add	s1,s1,a5
    800016ba:	fd24e5e3          	bltu	s1,s2,80001684 <uvmcopyshared+0x1c>
    800016be:	a81d                	j	800016f4 <uvmcopyshared+0x8c>
      panic("uvmcopy: pte should exist");
    800016c0:	00007517          	auipc	a0,0x7
    800016c4:	aa050513          	addi	a0,a0,-1376 # 80008160 <digits+0x120>
    800016c8:	fffff097          	auipc	ra,0xfffff
    800016cc:	e74080e7          	jalr	-396(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800016d0:	00007517          	auipc	a0,0x7
    800016d4:	ab050513          	addi	a0,a0,-1360 # 80008180 <digits+0x140>
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	e64080e7          	jalr	-412(ra) # 8000053c <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016e0:	4685                	li	a3,1
    800016e2:	00c4d613          	srli	a2,s1,0xc
    800016e6:	4581                	li	a1,0
    800016e8:	854e                	mv	a0,s3
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	bcc080e7          	jalr	-1076(ra) # 800012b6 <uvmunmap>
  return -1;
    800016f2:	557d                	li	a0,-1
}
    800016f4:	70a2                	ld	ra,40(sp)
    800016f6:	7402                	ld	s0,32(sp)
    800016f8:	64e2                	ld	s1,24(sp)
    800016fa:	6942                	ld	s2,16(sp)
    800016fc:	69a2                	ld	s3,8(sp)
    800016fe:	6a02                	ld	s4,0(sp)
    80001700:	6145                	addi	sp,sp,48
    80001702:	8082                	ret
  return 0;
    80001704:	4501                	li	a0,0
    80001706:	b7fd                	j	800016f4 <uvmcopyshared+0x8c>

0000000080001708 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001708:	1141                	addi	sp,sp,-16
    8000170a:	e406                	sd	ra,8(sp)
    8000170c:	e022                	sd	s0,0(sp)
    8000170e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001710:	4601                	li	a2,0
    80001712:	00000097          	auipc	ra,0x0
    80001716:	8f6080e7          	jalr	-1802(ra) # 80001008 <walk>
  if(pte == 0)
    8000171a:	c901                	beqz	a0,8000172a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000171c:	611c                	ld	a5,0(a0)
    8000171e:	9bbd                	andi	a5,a5,-17
    80001720:	e11c                	sd	a5,0(a0)
}
    80001722:	60a2                	ld	ra,8(sp)
    80001724:	6402                	ld	s0,0(sp)
    80001726:	0141                	addi	sp,sp,16
    80001728:	8082                	ret
    panic("uvmclear");
    8000172a:	00007517          	auipc	a0,0x7
    8000172e:	a7650513          	addi	a0,a0,-1418 # 800081a0 <digits+0x160>
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	e0a080e7          	jalr	-502(ra) # 8000053c <panic>

000000008000173a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000173a:	c6bd                	beqz	a3,800017a8 <copyout+0x6e>
{
    8000173c:	715d                	addi	sp,sp,-80
    8000173e:	e486                	sd	ra,72(sp)
    80001740:	e0a2                	sd	s0,64(sp)
    80001742:	fc26                	sd	s1,56(sp)
    80001744:	f84a                	sd	s2,48(sp)
    80001746:	f44e                	sd	s3,40(sp)
    80001748:	f052                	sd	s4,32(sp)
    8000174a:	ec56                	sd	s5,24(sp)
    8000174c:	e85a                	sd	s6,16(sp)
    8000174e:	e45e                	sd	s7,8(sp)
    80001750:	e062                	sd	s8,0(sp)
    80001752:	0880                	addi	s0,sp,80
    80001754:	8b2a                	mv	s6,a0
    80001756:	8c2e                	mv	s8,a1
    80001758:	8a32                	mv	s4,a2
    8000175a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000175c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000175e:	6a85                	lui	s5,0x1
    80001760:	a015                	j	80001784 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001762:	9562                	add	a0,a0,s8
    80001764:	0004861b          	sext.w	a2,s1
    80001768:	85d2                	mv	a1,s4
    8000176a:	41250533          	sub	a0,a0,s2
    8000176e:	fffff097          	auipc	ra,0xfffff
    80001772:	606080e7          	jalr	1542(ra) # 80000d74 <memmove>

    len -= n;
    80001776:	409989b3          	sub	s3,s3,s1
    src += n;
    8000177a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000177c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001780:	02098263          	beqz	s3,800017a4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001784:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001788:	85ca                	mv	a1,s2
    8000178a:	855a                	mv	a0,s6
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	922080e7          	jalr	-1758(ra) # 800010ae <walkaddr>
    if(pa0 == 0)
    80001794:	cd01                	beqz	a0,800017ac <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001796:	418904b3          	sub	s1,s2,s8
    8000179a:	94d6                	add	s1,s1,s5
    8000179c:	fc99f3e3          	bgeu	s3,s1,80001762 <copyout+0x28>
    800017a0:	84ce                	mv	s1,s3
    800017a2:	b7c1                	j	80001762 <copyout+0x28>
  }
  return 0;
    800017a4:	4501                	li	a0,0
    800017a6:	a021                	j	800017ae <copyout+0x74>
    800017a8:	4501                	li	a0,0
}
    800017aa:	8082                	ret
      return -1;
    800017ac:	557d                	li	a0,-1
}
    800017ae:	60a6                	ld	ra,72(sp)
    800017b0:	6406                	ld	s0,64(sp)
    800017b2:	74e2                	ld	s1,56(sp)
    800017b4:	7942                	ld	s2,48(sp)
    800017b6:	79a2                	ld	s3,40(sp)
    800017b8:	7a02                	ld	s4,32(sp)
    800017ba:	6ae2                	ld	s5,24(sp)
    800017bc:	6b42                	ld	s6,16(sp)
    800017be:	6ba2                	ld	s7,8(sp)
    800017c0:	6c02                	ld	s8,0(sp)
    800017c2:	6161                	addi	sp,sp,80
    800017c4:	8082                	ret

00000000800017c6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017c6:	caa5                	beqz	a3,80001836 <copyin+0x70>
{
    800017c8:	715d                	addi	sp,sp,-80
    800017ca:	e486                	sd	ra,72(sp)
    800017cc:	e0a2                	sd	s0,64(sp)
    800017ce:	fc26                	sd	s1,56(sp)
    800017d0:	f84a                	sd	s2,48(sp)
    800017d2:	f44e                	sd	s3,40(sp)
    800017d4:	f052                	sd	s4,32(sp)
    800017d6:	ec56                	sd	s5,24(sp)
    800017d8:	e85a                	sd	s6,16(sp)
    800017da:	e45e                	sd	s7,8(sp)
    800017dc:	e062                	sd	s8,0(sp)
    800017de:	0880                	addi	s0,sp,80
    800017e0:	8b2a                	mv	s6,a0
    800017e2:	8a2e                	mv	s4,a1
    800017e4:	8c32                	mv	s8,a2
    800017e6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017e8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ea:	6a85                	lui	s5,0x1
    800017ec:	a01d                	j	80001812 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017ee:	018505b3          	add	a1,a0,s8
    800017f2:	0004861b          	sext.w	a2,s1
    800017f6:	412585b3          	sub	a1,a1,s2
    800017fa:	8552                	mv	a0,s4
    800017fc:	fffff097          	auipc	ra,0xfffff
    80001800:	578080e7          	jalr	1400(ra) # 80000d74 <memmove>

    len -= n;
    80001804:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001808:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000180a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000180e:	02098263          	beqz	s3,80001832 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001812:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001816:	85ca                	mv	a1,s2
    80001818:	855a                	mv	a0,s6
    8000181a:	00000097          	auipc	ra,0x0
    8000181e:	894080e7          	jalr	-1900(ra) # 800010ae <walkaddr>
    if(pa0 == 0)
    80001822:	cd01                	beqz	a0,8000183a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001824:	418904b3          	sub	s1,s2,s8
    80001828:	94d6                	add	s1,s1,s5
    8000182a:	fc99f2e3          	bgeu	s3,s1,800017ee <copyin+0x28>
    8000182e:	84ce                	mv	s1,s3
    80001830:	bf7d                	j	800017ee <copyin+0x28>
  }
  return 0;
    80001832:	4501                	li	a0,0
    80001834:	a021                	j	8000183c <copyin+0x76>
    80001836:	4501                	li	a0,0
}
    80001838:	8082                	ret
      return -1;
    8000183a:	557d                	li	a0,-1
}
    8000183c:	60a6                	ld	ra,72(sp)
    8000183e:	6406                	ld	s0,64(sp)
    80001840:	74e2                	ld	s1,56(sp)
    80001842:	7942                	ld	s2,48(sp)
    80001844:	79a2                	ld	s3,40(sp)
    80001846:	7a02                	ld	s4,32(sp)
    80001848:	6ae2                	ld	s5,24(sp)
    8000184a:	6b42                	ld	s6,16(sp)
    8000184c:	6ba2                	ld	s7,8(sp)
    8000184e:	6c02                	ld	s8,0(sp)
    80001850:	6161                	addi	sp,sp,80
    80001852:	8082                	ret

0000000080001854 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001854:	c2dd                	beqz	a3,800018fa <copyinstr+0xa6>
{
    80001856:	715d                	addi	sp,sp,-80
    80001858:	e486                	sd	ra,72(sp)
    8000185a:	e0a2                	sd	s0,64(sp)
    8000185c:	fc26                	sd	s1,56(sp)
    8000185e:	f84a                	sd	s2,48(sp)
    80001860:	f44e                	sd	s3,40(sp)
    80001862:	f052                	sd	s4,32(sp)
    80001864:	ec56                	sd	s5,24(sp)
    80001866:	e85a                	sd	s6,16(sp)
    80001868:	e45e                	sd	s7,8(sp)
    8000186a:	0880                	addi	s0,sp,80
    8000186c:	8a2a                	mv	s4,a0
    8000186e:	8b2e                	mv	s6,a1
    80001870:	8bb2                	mv	s7,a2
    80001872:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001874:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001876:	6985                	lui	s3,0x1
    80001878:	a02d                	j	800018a2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000187a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000187e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001880:	37fd                	addiw	a5,a5,-1
    80001882:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001886:	60a6                	ld	ra,72(sp)
    80001888:	6406                	ld	s0,64(sp)
    8000188a:	74e2                	ld	s1,56(sp)
    8000188c:	7942                	ld	s2,48(sp)
    8000188e:	79a2                	ld	s3,40(sp)
    80001890:	7a02                	ld	s4,32(sp)
    80001892:	6ae2                	ld	s5,24(sp)
    80001894:	6b42                	ld	s6,16(sp)
    80001896:	6ba2                	ld	s7,8(sp)
    80001898:	6161                	addi	sp,sp,80
    8000189a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000189c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018a0:	c8a9                	beqz	s1,800018f2 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800018a2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018a6:	85ca                	mv	a1,s2
    800018a8:	8552                	mv	a0,s4
    800018aa:	00000097          	auipc	ra,0x0
    800018ae:	804080e7          	jalr	-2044(ra) # 800010ae <walkaddr>
    if(pa0 == 0)
    800018b2:	c131                	beqz	a0,800018f6 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800018b4:	417906b3          	sub	a3,s2,s7
    800018b8:	96ce                	add	a3,a3,s3
    800018ba:	00d4f363          	bgeu	s1,a3,800018c0 <copyinstr+0x6c>
    800018be:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018c0:	955e                	add	a0,a0,s7
    800018c2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018c6:	daf9                	beqz	a3,8000189c <copyinstr+0x48>
    800018c8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ca:	41650633          	sub	a2,a0,s6
    800018ce:	fff48593          	addi	a1,s1,-1
    800018d2:	95da                	add	a1,a1,s6
    while(n > 0){
    800018d4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800018d6:	00f60733          	add	a4,a2,a5
    800018da:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffc8368>
    800018de:	df51                	beqz	a4,8000187a <copyinstr+0x26>
        *dst = *p;
    800018e0:	00e78023          	sb	a4,0(a5)
      --max;
    800018e4:	40f584b3          	sub	s1,a1,a5
      dst++;
    800018e8:	0785                	addi	a5,a5,1
    while(n > 0){
    800018ea:	fed796e3          	bne	a5,a3,800018d6 <copyinstr+0x82>
      dst++;
    800018ee:	8b3e                	mv	s6,a5
    800018f0:	b775                	j	8000189c <copyinstr+0x48>
    800018f2:	4781                	li	a5,0
    800018f4:	b771                	j	80001880 <copyinstr+0x2c>
      return -1;
    800018f6:	557d                	li	a0,-1
    800018f8:	b779                	j	80001886 <copyinstr+0x32>
  int got_null = 0;
    800018fa:	4781                	li	a5,0
  if(got_null){
    800018fc:	37fd                	addiw	a5,a5,-1
    800018fe:	0007851b          	sext.w	a0,a5
}
    80001902:	8082                	ret

0000000080001904 <mapvpages>:
// HW5 - Task 1a
// Allocate page table pages for PTEs if needed but leave valid bits unchanged
int
mapvpages(pagetable_t pagetable, uint64 va, uint64 size)
{
    80001904:	7179                	addi	sp,sp,-48
    80001906:	f406                	sd	ra,40(sp)
    80001908:	f022                	sd	s0,32(sp)
    8000190a:	ec26                	sd	s1,24(sp)
    8000190c:	e84a                	sd	s2,16(sp)
    8000190e:	e44e                	sd	s3,8(sp)
    80001910:	e052                	sd	s4,0(sp)
    80001912:	1800                	addi	s0,sp,48
  uint64 a, last;
  pte_t *pte;
  if(size == 0)
    80001914:	ca15                	beqz	a2,80001948 <mapvpages+0x44>
    80001916:	89aa                	mv	s3,a0
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001918:	77fd                	lui	a5,0xfffff
    8000191a:	00f5f4b3          	and	s1,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000191e:	fff58913          	addi	s2,a1,-1
    80001922:	9932                	add	s2,s2,a2
    80001924:	00f97933          	and	s2,s2,a5
      return -1;
    if(*pte & PTE_V)
      panic("mappages: remap");
    if(a == last)
      break;
    a += PGSIZE;
    80001928:	6a05                	lui	s4,0x1
    if((pte = walk(pagetable, a, 1)) == 0)
    8000192a:	4605                	li	a2,1
    8000192c:	85a6                	mv	a1,s1
    8000192e:	854e                	mv	a0,s3
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	6d8080e7          	jalr	1752(ra) # 80001008 <walk>
    80001938:	c905                	beqz	a0,80001968 <mapvpages+0x64>
    if(*pte & PTE_V)
    8000193a:	611c                	ld	a5,0(a0)
    8000193c:	8b85                	andi	a5,a5,1
    8000193e:	ef89                	bnez	a5,80001958 <mapvpages+0x54>
    if(a == last)
    80001940:	03248d63          	beq	s1,s2,8000197a <mapvpages+0x76>
    a += PGSIZE;
    80001944:	94d2                	add	s1,s1,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001946:	b7d5                	j	8000192a <mapvpages+0x26>
    panic("mappages: size");
    80001948:	00006517          	auipc	a0,0x6
    8000194c:	79050513          	addi	a0,a0,1936 # 800080d8 <digits+0x98>
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	bec080e7          	jalr	-1044(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001958:	00006517          	auipc	a0,0x6
    8000195c:	79050513          	addi	a0,a0,1936 # 800080e8 <digits+0xa8>
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	bdc080e7          	jalr	-1060(ra) # 8000053c <panic>
      return -1;
    80001968:	557d                	li	a0,-1
  }
  return 0;
    8000196a:	70a2                	ld	ra,40(sp)
    8000196c:	7402                	ld	s0,32(sp)
    8000196e:	64e2                	ld	s1,24(sp)
    80001970:	6942                	ld	s2,16(sp)
    80001972:	69a2                	ld	s3,8(sp)
    80001974:	6a02                	ld	s4,0(sp)
    80001976:	6145                	addi	sp,sp,48
    80001978:	8082                	ret
  return 0;
    8000197a:	4501                	li	a0,0
    8000197c:	b7fd                	j	8000196a <mapvpages+0x66>

000000008000197e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000197e:	7139                	addi	sp,sp,-64
    80001980:	fc06                	sd	ra,56(sp)
    80001982:	f822                	sd	s0,48(sp)
    80001984:	f426                	sd	s1,40(sp)
    80001986:	f04a                	sd	s2,32(sp)
    80001988:	ec4e                	sd	s3,24(sp)
    8000198a:	e852                	sd	s4,16(sp)
    8000198c:	e456                	sd	s5,8(sp)
    8000198e:	e05a                	sd	s6,0(sp)
    80001990:	0080                	addi	s0,sp,64
    80001992:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	00010497          	auipc	s1,0x10
    80001998:	d5448493          	addi	s1,s1,-684 # 800116e8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000199c:	8b26                	mv	s6,s1
    8000199e:	00006a97          	auipc	s5,0x6
    800019a2:	662a8a93          	addi	s5,s5,1634 # 80008000 <etext>
    800019a6:	04000937          	lui	s2,0x4000
    800019aa:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019ac:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ae:	00021a17          	auipc	s4,0x21
    800019b2:	d3aa0a13          	addi	s4,s4,-710 # 800226e8 <mmr_list>
    char *pa = kalloc();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	12c080e7          	jalr	300(ra) # 80000ae2 <kalloc>
    800019be:	862a                	mv	a2,a0
    if(pa == 0)
    800019c0:	c131                	beqz	a0,80001a04 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019c2:	416485b3          	sub	a1,s1,s6
    800019c6:	8599                	srai	a1,a1,0x6
    800019c8:	000ab783          	ld	a5,0(s5)
    800019cc:	02f585b3          	mul	a1,a1,a5
    800019d0:	2585                	addiw	a1,a1,1
    800019d2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019d6:	4719                	li	a4,6
    800019d8:	6685                	lui	a3,0x1
    800019da:	40b905b3          	sub	a1,s2,a1
    800019de:	854e                	mv	a0,s3
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	7b0080e7          	jalr	1968(ra) # 80001190 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e8:	44048493          	addi	s1,s1,1088
    800019ec:	fd4495e3          	bne	s1,s4,800019b6 <proc_mapstacks+0x38>
  }
}
    800019f0:	70e2                	ld	ra,56(sp)
    800019f2:	7442                	ld	s0,48(sp)
    800019f4:	74a2                	ld	s1,40(sp)
    800019f6:	7902                	ld	s2,32(sp)
    800019f8:	69e2                	ld	s3,24(sp)
    800019fa:	6a42                	ld	s4,16(sp)
    800019fc:	6aa2                	ld	s5,8(sp)
    800019fe:	6b02                	ld	s6,0(sp)
    80001a00:	6121                	addi	sp,sp,64
    80001a02:	8082                	ret
      panic("kalloc");
    80001a04:	00006517          	auipc	a0,0x6
    80001a08:	7ac50513          	addi	a0,a0,1964 # 800081b0 <digits+0x170>
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	b30080e7          	jalr	-1232(ra) # 8000053c <panic>

0000000080001a14 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a14:	7139                	addi	sp,sp,-64
    80001a16:	fc06                	sd	ra,56(sp)
    80001a18:	f822                	sd	s0,48(sp)
    80001a1a:	f426                	sd	s1,40(sp)
    80001a1c:	f04a                	sd	s2,32(sp)
    80001a1e:	ec4e                	sd	s3,24(sp)
    80001a20:	e852                	sd	s4,16(sp)
    80001a22:	e456                	sd	s5,8(sp)
    80001a24:	e05a                	sd	s6,0(sp)
    80001a26:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a28:	00006597          	auipc	a1,0x6
    80001a2c:	79058593          	addi	a1,a1,1936 # 800081b8 <digits+0x178>
    80001a30:	00010517          	auipc	a0,0x10
    80001a34:	87050513          	addi	a0,a0,-1936 # 800112a0 <pid_lock>
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	154080e7          	jalr	340(ra) # 80000b8c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a40:	00006597          	auipc	a1,0x6
    80001a44:	78058593          	addi	a1,a1,1920 # 800081c0 <digits+0x180>
    80001a48:	00010517          	auipc	a0,0x10
    80001a4c:	87050513          	addi	a0,a0,-1936 # 800112b8 <wait_lock>
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	13c080e7          	jalr	316(ra) # 80000b8c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a58:	00010497          	auipc	s1,0x10
    80001a5c:	c9048493          	addi	s1,s1,-880 # 800116e8 <proc>
      initlock(&p->lock, "proc");
    80001a60:	00006b17          	auipc	s6,0x6
    80001a64:	770b0b13          	addi	s6,s6,1904 # 800081d0 <digits+0x190>
      p->kstack = KSTACK((int) (p - proc));
    80001a68:	8aa6                	mv	s5,s1
    80001a6a:	00006a17          	auipc	s4,0x6
    80001a6e:	596a0a13          	addi	s4,s4,1430 # 80008000 <etext>
    80001a72:	04000937          	lui	s2,0x4000
    80001a76:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a78:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a7a:	00021997          	auipc	s3,0x21
    80001a7e:	c6e98993          	addi	s3,s3,-914 # 800226e8 <mmr_list>
      initlock(&p->lock, "proc");
    80001a82:	85da                	mv	a1,s6
    80001a84:	2d848513          	addi	a0,s1,728
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	104080e7          	jalr	260(ra) # 80000b8c <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a90:	415487b3          	sub	a5,s1,s5
    80001a94:	8799                	srai	a5,a5,0x6
    80001a96:	000a3703          	ld	a4,0(s4)
    80001a9a:	02e787b3          	mul	a5,a5,a4
    80001a9e:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffc8369>
    80001aa0:	00d7979b          	slliw	a5,a5,0xd
    80001aa4:	40f907b3          	sub	a5,s2,a5
    80001aa8:	30f4bc23          	sd	a5,792(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aac:	44048493          	addi	s1,s1,1088
    80001ab0:	fd3499e3          	bne	s1,s3,80001a82 <procinit+0x6e>
  }
}
    80001ab4:	70e2                	ld	ra,56(sp)
    80001ab6:	7442                	ld	s0,48(sp)
    80001ab8:	74a2                	ld	s1,40(sp)
    80001aba:	7902                	ld	s2,32(sp)
    80001abc:	69e2                	ld	s3,24(sp)
    80001abe:	6a42                	ld	s4,16(sp)
    80001ac0:	6aa2                	ld	s5,8(sp)
    80001ac2:	6b02                	ld	s6,0(sp)
    80001ac4:	6121                	addi	sp,sp,64
    80001ac6:	8082                	ret

0000000080001ac8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ac8:	1141                	addi	sp,sp,-16
    80001aca:	e422                	sd	s0,8(sp)
    80001acc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ace:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ad0:	2501                	sext.w	a0,a0
    80001ad2:	6422                	ld	s0,8(sp)
    80001ad4:	0141                	addi	sp,sp,16
    80001ad6:	8082                	ret

0000000080001ad8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ad8:	1141                	addi	sp,sp,-16
    80001ada:	e422                	sd	s0,8(sp)
    80001adc:	0800                	addi	s0,sp,16
    80001ade:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ae0:	2781                	sext.w	a5,a5
    80001ae2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ae4:	0000f517          	auipc	a0,0xf
    80001ae8:	7ec50513          	addi	a0,a0,2028 # 800112d0 <cpus>
    80001aec:	953e                	add	a0,a0,a5
    80001aee:	6422                	ld	s0,8(sp)
    80001af0:	0141                	addi	sp,sp,16
    80001af2:	8082                	ret

0000000080001af4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	1000                	addi	s0,sp,32
  push_off();
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	0d2080e7          	jalr	210(ra) # 80000bd0 <push_off>
    80001b06:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b08:	2781                	sext.w	a5,a5
    80001b0a:	079e                	slli	a5,a5,0x7
    80001b0c:	0000f717          	auipc	a4,0xf
    80001b10:	79470713          	addi	a4,a4,1940 # 800112a0 <pid_lock>
    80001b14:	97ba                	add	a5,a5,a4
    80001b16:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	158080e7          	jalr	344(ra) # 80000c70 <pop_off>
  return p;
}
    80001b20:	8526                	mv	a0,s1
    80001b22:	60e2                	ld	ra,24(sp)
    80001b24:	6442                	ld	s0,16(sp)
    80001b26:	64a2                	ld	s1,8(sp)
    80001b28:	6105                	addi	sp,sp,32
    80001b2a:	8082                	ret

0000000080001b2c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b2c:	1141                	addi	sp,sp,-16
    80001b2e:	e406                	sd	ra,8(sp)
    80001b30:	e022                	sd	s0,0(sp)
    80001b32:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	fc0080e7          	jalr	-64(ra) # 80001af4 <myproc>
    80001b3c:	2d850513          	addi	a0,a0,728
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	190080e7          	jalr	400(ra) # 80000cd0 <release>

  if (first) {
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	d387a783          	lw	a5,-712(a5) # 80008880 <first.1>
    80001b50:	eb89                	bnez	a5,80001b62 <forkret+0x36>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b52:	00001097          	auipc	ra,0x1
    80001b56:	164080e7          	jalr	356(ra) # 80002cb6 <usertrapret>
}
    80001b5a:	60a2                	ld	ra,8(sp)
    80001b5c:	6402                	ld	s0,0(sp)
    80001b5e:	0141                	addi	sp,sp,16
    80001b60:	8082                	ret
    first = 0;
    80001b62:	00007797          	auipc	a5,0x7
    80001b66:	d007af23          	sw	zero,-738(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001b6a:	4505                	li	a0,1
    80001b6c:	00002097          	auipc	ra,0x2
    80001b70:	2c2080e7          	jalr	706(ra) # 80003e2e <fsinit>
    80001b74:	bff9                	j	80001b52 <forkret+0x26>

0000000080001b76 <allocpid>:
allocpid() {
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b82:	0000f917          	auipc	s2,0xf
    80001b86:	71e90913          	addi	s2,s2,1822 # 800112a0 <pid_lock>
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	090080e7          	jalr	144(ra) # 80000c1c <acquire>
  pid = nextpid;
    80001b94:	00007797          	auipc	a5,0x7
    80001b98:	cf078793          	addi	a5,a5,-784 # 80008884 <nextpid>
    80001b9c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b9e:	0014871b          	addiw	a4,s1,1
    80001ba2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba4:	854a                	mv	a0,s2
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	12a080e7          	jalr	298(ra) # 80000cd0 <release>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <proc_pagetable>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
    80001bc8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	792080e7          	jalr	1938(ra) # 8000135c <uvmcreate>
    80001bd2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bd4:	c121                	beqz	a0,80001c14 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bd6:	4729                	li	a4,10
    80001bd8:	00005697          	auipc	a3,0x5
    80001bdc:	42868693          	addi	a3,a3,1064 # 80007000 <_trampoline>
    80001be0:	6605                	lui	a2,0x1
    80001be2:	040005b7          	lui	a1,0x4000
    80001be6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001be8:	05b2                	slli	a1,a1,0xc
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	506080e7          	jalr	1286(ra) # 800010f0 <mappages>
    80001bf2:	02054863          	bltz	a0,80001c22 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bf6:	4719                	li	a4,6
    80001bf8:	33093683          	ld	a3,816(s2)
    80001bfc:	6605                	lui	a2,0x1
    80001bfe:	020005b7          	lui	a1,0x2000
    80001c02:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c04:	05b6                	slli	a1,a1,0xd
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	4e8080e7          	jalr	1256(ra) # 800010f0 <mappages>
    80001c10:	02054163          	bltz	a0,80001c32 <proc_pagetable+0x76>
}
    80001c14:	8526                	mv	a0,s1
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6902                	ld	s2,0(sp)
    80001c1e:	6105                	addi	sp,sp,32
    80001c20:	8082                	ret
    uvmfree(pagetable, 0);
    80001c22:	4581                	li	a1,0
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	934080e7          	jalr	-1740(ra) # 8000155a <uvmfree>
    return 0;
    80001c2e:	4481                	li	s1,0
    80001c30:	b7d5                	j	80001c14 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c32:	4681                	li	a3,0
    80001c34:	4605                	li	a2,1
    80001c36:	040005b7          	lui	a1,0x4000
    80001c3a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c3c:	05b2                	slli	a1,a1,0xc
    80001c3e:	8526                	mv	a0,s1
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	676080e7          	jalr	1654(ra) # 800012b6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c48:	4581                	li	a1,0
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	90e080e7          	jalr	-1778(ra) # 8000155a <uvmfree>
    return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	bf7d                	j	80001c14 <proc_pagetable+0x58>

0000000080001c58 <proc_freepagetable>:
{
    80001c58:	1101                	addi	sp,sp,-32
    80001c5a:	ec06                	sd	ra,24(sp)
    80001c5c:	e822                	sd	s0,16(sp)
    80001c5e:	e426                	sd	s1,8(sp)
    80001c60:	e04a                	sd	s2,0(sp)
    80001c62:	1000                	addi	s0,sp,32
    80001c64:	84aa                	mv	s1,a0
    80001c66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c68:	4681                	li	a3,0
    80001c6a:	4605                	li	a2,1
    80001c6c:	040005b7          	lui	a1,0x4000
    80001c70:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c72:	05b2                	slli	a1,a1,0xc
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	642080e7          	jalr	1602(ra) # 800012b6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c7c:	4681                	li	a3,0
    80001c7e:	4605                	li	a2,1
    80001c80:	020005b7          	lui	a1,0x2000
    80001c84:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c86:	05b6                	slli	a1,a1,0xd
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	62c080e7          	jalr	1580(ra) # 800012b6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c92:	85ca                	mv	a1,s2
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	8c4080e7          	jalr	-1852(ra) # 8000155a <uvmfree>
}
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	addi	sp,sp,32
    80001ca8:	8082                	ret

0000000080001caa <growproc>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	e04a                	sd	s2,0(sp)
    80001cb4:	1000                	addi	s0,sp,32
    80001cb6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	e3c080e7          	jalr	-452(ra) # 80001af4 <myproc>
    80001cc0:	892a                	mv	s2,a0
  sz = p->sz;
    80001cc2:	32053583          	ld	a1,800(a0)
    80001cc6:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001cca:	00904f63          	bgtz	s1,80001ce8 <growproc+0x3e>
  } else if(n < 0){
    80001cce:	0204ce63          	bltz	s1,80001d0a <growproc+0x60>
  p->sz = sz;
    80001cd2:	1782                	slli	a5,a5,0x20
    80001cd4:	9381                	srli	a5,a5,0x20
    80001cd6:	32f93023          	sd	a5,800(s2)
  return 0;
    80001cda:	4501                	li	a0,0
}
    80001cdc:	60e2                	ld	ra,24(sp)
    80001cde:	6442                	ld	s0,16(sp)
    80001ce0:	64a2                	ld	s1,8(sp)
    80001ce2:	6902                	ld	s2,0(sp)
    80001ce4:	6105                	addi	sp,sp,32
    80001ce6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ce8:	00f4863b          	addw	a2,s1,a5
    80001cec:	1602                	slli	a2,a2,0x20
    80001cee:	9201                	srli	a2,a2,0x20
    80001cf0:	1582                	slli	a1,a1,0x20
    80001cf2:	9181                	srli	a1,a1,0x20
    80001cf4:	32853503          	ld	a0,808(a0)
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	74c080e7          	jalr	1868(ra) # 80001444 <uvmalloc>
    80001d00:	0005079b          	sext.w	a5,a0
    80001d04:	f7f9                	bnez	a5,80001cd2 <growproc+0x28>
      return -1;
    80001d06:	557d                	li	a0,-1
    80001d08:	bfd1                	j	80001cdc <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d0a:	00f4863b          	addw	a2,s1,a5
    80001d0e:	1602                	slli	a2,a2,0x20
    80001d10:	9201                	srli	a2,a2,0x20
    80001d12:	1582                	slli	a1,a1,0x20
    80001d14:	9181                	srli	a1,a1,0x20
    80001d16:	32853503          	ld	a0,808(a0)
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	6e2080e7          	jalr	1762(ra) # 800013fc <uvmdealloc>
    80001d22:	0005079b          	sext.w	a5,a0
    80001d26:	b775                	j	80001cd2 <growproc+0x28>

0000000080001d28 <scheduler>:
{
    80001d28:	715d                	addi	sp,sp,-80
    80001d2a:	e486                	sd	ra,72(sp)
    80001d2c:	e0a2                	sd	s0,64(sp)
    80001d2e:	fc26                	sd	s1,56(sp)
    80001d30:	f84a                	sd	s2,48(sp)
    80001d32:	f44e                	sd	s3,40(sp)
    80001d34:	f052                	sd	s4,32(sp)
    80001d36:	ec56                	sd	s5,24(sp)
    80001d38:	e85a                	sd	s6,16(sp)
    80001d3a:	e45e                	sd	s7,8(sp)
    80001d3c:	0880                	addi	s0,sp,80
    80001d3e:	8792                	mv	a5,tp
  int id = r_tp();
    80001d40:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d42:	00779b13          	slli	s6,a5,0x7
    80001d46:	0000f717          	auipc	a4,0xf
    80001d4a:	55a70713          	addi	a4,a4,1370 # 800112a0 <pid_lock>
    80001d4e:	975a                	add	a4,a4,s6
    80001d50:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001d54:	0000f717          	auipc	a4,0xf
    80001d58:	58470713          	addi	a4,a4,1412 # 800112d8 <cpus+0x8>
    80001d5c:	9b3a                	add	s6,s6,a4
      if(p->state == RUNNABLE) {
    80001d5e:	4a0d                	li	s4,3
        p->state = RUNNING;
    80001d60:	4b91                	li	s7,4
        c->proc = p;
    80001d62:	079e                	slli	a5,a5,0x7
    80001d64:	0000fa97          	auipc	s5,0xf
    80001d68:	53ca8a93          	addi	s5,s5,1340 # 800112a0 <pid_lock>
    80001d6c:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d6e:	00021997          	auipc	s3,0x21
    80001d72:	97a98993          	addi	s3,s3,-1670 # 800226e8 <mmr_list>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001d7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d7e:	10079073          	csrw	sstatus,a5
    80001d82:	00010497          	auipc	s1,0x10
    80001d86:	96648493          	addi	s1,s1,-1690 # 800116e8 <proc>
    80001d8a:	a811                	j	80001d9e <scheduler+0x76>
      release(&p->lock);
    80001d8c:	854a                	mv	a0,s2
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	f42080e7          	jalr	-190(ra) # 80000cd0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d96:	44048493          	addi	s1,s1,1088
    80001d9a:	fd348ee3          	beq	s1,s3,80001d76 <scheduler+0x4e>
      acquire(&p->lock);
    80001d9e:	2d848913          	addi	s2,s1,728
    80001da2:	854a                	mv	a0,s2
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	e78080e7          	jalr	-392(ra) # 80000c1c <acquire>
      if(p->state == RUNNABLE) {
    80001dac:	2f04a783          	lw	a5,752(s1)
    80001db0:	fd479ee3          	bne	a5,s4,80001d8c <scheduler+0x64>
        p->state = RUNNING;
    80001db4:	2f74a823          	sw	s7,752(s1)
        c->proc = p;
    80001db8:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001dbc:	33848593          	addi	a1,s1,824
    80001dc0:	855a                	mv	a0,s6
    80001dc2:	00001097          	auipc	ra,0x1
    80001dc6:	e4a080e7          	jalr	-438(ra) # 80002c0c <swtch>
        c->proc = 0;
    80001dca:	020ab823          	sd	zero,48(s5)
    80001dce:	bf7d                	j	80001d8c <scheduler+0x64>

0000000080001dd0 <sched>:
{
    80001dd0:	7179                	addi	sp,sp,-48
    80001dd2:	f406                	sd	ra,40(sp)
    80001dd4:	f022                	sd	s0,32(sp)
    80001dd6:	ec26                	sd	s1,24(sp)
    80001dd8:	e84a                	sd	s2,16(sp)
    80001dda:	e44e                	sd	s3,8(sp)
    80001ddc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	d16080e7          	jalr	-746(ra) # 80001af4 <myproc>
    80001de6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001de8:	2d850513          	addi	a0,a0,728
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	db6080e7          	jalr	-586(ra) # 80000ba2 <holding>
    80001df4:	cd25                	beqz	a0,80001e6c <sched+0x9c>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001df6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001df8:	2781                	sext.w	a5,a5
    80001dfa:	079e                	slli	a5,a5,0x7
    80001dfc:	0000f717          	auipc	a4,0xf
    80001e00:	4a470713          	addi	a4,a4,1188 # 800112a0 <pid_lock>
    80001e04:	97ba                	add	a5,a5,a4
    80001e06:	0a87a703          	lw	a4,168(a5)
    80001e0a:	4785                	li	a5,1
    80001e0c:	06f71863          	bne	a4,a5,80001e7c <sched+0xac>
  if(p->state == RUNNING)
    80001e10:	2f04a703          	lw	a4,752(s1)
    80001e14:	4791                	li	a5,4
    80001e16:	06f70b63          	beq	a4,a5,80001e8c <sched+0xbc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e1a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e1e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e20:	efb5                	bnez	a5,80001e9c <sched+0xcc>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e22:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e24:	0000f917          	auipc	s2,0xf
    80001e28:	47c90913          	addi	s2,s2,1148 # 800112a0 <pid_lock>
    80001e2c:	2781                	sext.w	a5,a5
    80001e2e:	079e                	slli	a5,a5,0x7
    80001e30:	97ca                	add	a5,a5,s2
    80001e32:	0ac7a983          	lw	s3,172(a5)
    80001e36:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e38:	2781                	sext.w	a5,a5
    80001e3a:	079e                	slli	a5,a5,0x7
    80001e3c:	0000f597          	auipc	a1,0xf
    80001e40:	49c58593          	addi	a1,a1,1180 # 800112d8 <cpus+0x8>
    80001e44:	95be                	add	a1,a1,a5
    80001e46:	33848513          	addi	a0,s1,824
    80001e4a:	00001097          	auipc	ra,0x1
    80001e4e:	dc2080e7          	jalr	-574(ra) # 80002c0c <swtch>
    80001e52:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001e54:	2781                	sext.w	a5,a5
    80001e56:	079e                	slli	a5,a5,0x7
    80001e58:	993e                	add	s2,s2,a5
    80001e5a:	0b392623          	sw	s3,172(s2)
}
    80001e5e:	70a2                	ld	ra,40(sp)
    80001e60:	7402                	ld	s0,32(sp)
    80001e62:	64e2                	ld	s1,24(sp)
    80001e64:	6942                	ld	s2,16(sp)
    80001e66:	69a2                	ld	s3,8(sp)
    80001e68:	6145                	addi	sp,sp,48
    80001e6a:	8082                	ret
    panic("sched p->lock");
    80001e6c:	00006517          	auipc	a0,0x6
    80001e70:	36c50513          	addi	a0,a0,876 # 800081d8 <digits+0x198>
    80001e74:	ffffe097          	auipc	ra,0xffffe
    80001e78:	6c8080e7          	jalr	1736(ra) # 8000053c <panic>
    panic("sched locks");
    80001e7c:	00006517          	auipc	a0,0x6
    80001e80:	36c50513          	addi	a0,a0,876 # 800081e8 <digits+0x1a8>
    80001e84:	ffffe097          	auipc	ra,0xffffe
    80001e88:	6b8080e7          	jalr	1720(ra) # 8000053c <panic>
    panic("sched running");
    80001e8c:	00006517          	auipc	a0,0x6
    80001e90:	36c50513          	addi	a0,a0,876 # 800081f8 <digits+0x1b8>
    80001e94:	ffffe097          	auipc	ra,0xffffe
    80001e98:	6a8080e7          	jalr	1704(ra) # 8000053c <panic>
    panic("sched interruptible");
    80001e9c:	00006517          	auipc	a0,0x6
    80001ea0:	36c50513          	addi	a0,a0,876 # 80008208 <digits+0x1c8>
    80001ea4:	ffffe097          	auipc	ra,0xffffe
    80001ea8:	698080e7          	jalr	1688(ra) # 8000053c <panic>

0000000080001eac <yield>:
{
    80001eac:	1101                	addi	sp,sp,-32
    80001eae:	ec06                	sd	ra,24(sp)
    80001eb0:	e822                	sd	s0,16(sp)
    80001eb2:	e426                	sd	s1,8(sp)
    80001eb4:	e04a                	sd	s2,0(sp)
    80001eb6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	c3c080e7          	jalr	-964(ra) # 80001af4 <myproc>
    80001ec0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001ec2:	2d850913          	addi	s2,a0,728
    80001ec6:	854a                	mv	a0,s2
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	d54080e7          	jalr	-684(ra) # 80000c1c <acquire>
  p->state = RUNNABLE;
    80001ed0:	478d                	li	a5,3
    80001ed2:	2ef4a823          	sw	a5,752(s1)
  sched();
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	efa080e7          	jalr	-262(ra) # 80001dd0 <sched>
  release(&p->lock);
    80001ede:	854a                	mv	a0,s2
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	df0080e7          	jalr	-528(ra) # 80000cd0 <release>
}
    80001ee8:	60e2                	ld	ra,24(sp)
    80001eea:	6442                	ld	s0,16(sp)
    80001eec:	64a2                	ld	s1,8(sp)
    80001eee:	6902                	ld	s2,0(sp)
    80001ef0:	6105                	addi	sp,sp,32
    80001ef2:	8082                	ret

0000000080001ef4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001ef4:	7179                	addi	sp,sp,-48
    80001ef6:	f406                	sd	ra,40(sp)
    80001ef8:	f022                	sd	s0,32(sp)
    80001efa:	ec26                	sd	s1,24(sp)
    80001efc:	e84a                	sd	s2,16(sp)
    80001efe:	e44e                	sd	s3,8(sp)
    80001f00:	e052                	sd	s4,0(sp)
    80001f02:	1800                	addi	s0,sp,48
    80001f04:	89aa                	mv	s3,a0
    80001f06:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	bec080e7          	jalr	-1044(ra) # 80001af4 <myproc>
    80001f10:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001f12:	2d850a13          	addi	s4,a0,728
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d04080e7          	jalr	-764(ra) # 80000c1c <acquire>
  release(lk);
    80001f20:	854a                	mv	a0,s2
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	dae080e7          	jalr	-594(ra) # 80000cd0 <release>

  // Go to sleep.
  p->chan = chan;
    80001f2a:	2f34bc23          	sd	s3,760(s1)
  p->state = SLEEPING;
    80001f2e:	4789                	li	a5,2
    80001f30:	2ef4a823          	sw	a5,752(s1)

  sched();
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	e9c080e7          	jalr	-356(ra) # 80001dd0 <sched>

  // Tidy up.
  p->chan = 0;
    80001f3c:	2e04bc23          	sd	zero,760(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f40:	8552                	mv	a0,s4
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d8e080e7          	jalr	-626(ra) # 80000cd0 <release>
  acquire(lk);
    80001f4a:	854a                	mv	a0,s2
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	cd0080e7          	jalr	-816(ra) # 80000c1c <acquire>
}
    80001f54:	70a2                	ld	ra,40(sp)
    80001f56:	7402                	ld	s0,32(sp)
    80001f58:	64e2                	ld	s1,24(sp)
    80001f5a:	6942                	ld	s2,16(sp)
    80001f5c:	69a2                	ld	s3,8(sp)
    80001f5e:	6a02                	ld	s4,0(sp)
    80001f60:	6145                	addi	sp,sp,48
    80001f62:	8082                	ret

0000000080001f64 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80001f64:	7139                	addi	sp,sp,-64
    80001f66:	fc06                	sd	ra,56(sp)
    80001f68:	f822                	sd	s0,48(sp)
    80001f6a:	f426                	sd	s1,40(sp)
    80001f6c:	f04a                	sd	s2,32(sp)
    80001f6e:	ec4e                	sd	s3,24(sp)
    80001f70:	e852                	sd	s4,16(sp)
    80001f72:	e456                	sd	s5,8(sp)
    80001f74:	e05a                	sd	s6,0(sp)
    80001f76:	0080                	addi	s0,sp,64
    80001f78:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f7a:	0000f497          	auipc	s1,0xf
    80001f7e:	76e48493          	addi	s1,s1,1902 # 800116e8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001f82:	4a09                	li	s4,2
        p->state = RUNNABLE;
    80001f84:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f86:	00020997          	auipc	s3,0x20
    80001f8a:	76298993          	addi	s3,s3,1890 # 800226e8 <mmr_list>
    80001f8e:	a811                	j	80001fa2 <wakeup+0x3e>
      }
      release(&p->lock);
    80001f90:	854a                	mv	a0,s2
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	d3e080e7          	jalr	-706(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f9a:	44048493          	addi	s1,s1,1088
    80001f9e:	03348a63          	beq	s1,s3,80001fd2 <wakeup+0x6e>
    if(p != myproc()){
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	b52080e7          	jalr	-1198(ra) # 80001af4 <myproc>
    80001faa:	fea488e3          	beq	s1,a0,80001f9a <wakeup+0x36>
      acquire(&p->lock);
    80001fae:	2d848913          	addi	s2,s1,728
    80001fb2:	854a                	mv	a0,s2
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	c68080e7          	jalr	-920(ra) # 80000c1c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001fbc:	2f04a783          	lw	a5,752(s1)
    80001fc0:	fd4798e3          	bne	a5,s4,80001f90 <wakeup+0x2c>
    80001fc4:	2f84b783          	ld	a5,760(s1)
    80001fc8:	fd5794e3          	bne	a5,s5,80001f90 <wakeup+0x2c>
        p->state = RUNNABLE;
    80001fcc:	2f64a823          	sw	s6,752(s1)
    80001fd0:	b7c1                	j	80001f90 <wakeup+0x2c>
    }
  }
}
    80001fd2:	70e2                	ld	ra,56(sp)
    80001fd4:	7442                	ld	s0,48(sp)
    80001fd6:	74a2                	ld	s1,40(sp)
    80001fd8:	7902                	ld	s2,32(sp)
    80001fda:	69e2                	ld	s3,24(sp)
    80001fdc:	6a42                	ld	s4,16(sp)
    80001fde:	6aa2                	ld	s5,8(sp)
    80001fe0:	6b02                	ld	s6,0(sp)
    80001fe2:	6121                	addi	sp,sp,64
    80001fe4:	8082                	ret

0000000080001fe6 <reparent>:
{
    80001fe6:	7179                	addi	sp,sp,-48
    80001fe8:	f406                	sd	ra,40(sp)
    80001fea:	f022                	sd	s0,32(sp)
    80001fec:	ec26                	sd	s1,24(sp)
    80001fee:	e84a                	sd	s2,16(sp)
    80001ff0:	e44e                	sd	s3,8(sp)
    80001ff2:	e052                	sd	s4,0(sp)
    80001ff4:	1800                	addi	s0,sp,48
    80001ff6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ff8:	0000f497          	auipc	s1,0xf
    80001ffc:	6f048493          	addi	s1,s1,1776 # 800116e8 <proc>
      pp->parent = initproc;
    80002000:	00007a17          	auipc	s4,0x7
    80002004:	028a0a13          	addi	s4,s4,40 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002008:	00020997          	auipc	s3,0x20
    8000200c:	6e098993          	addi	s3,s3,1760 # 800226e8 <mmr_list>
    80002010:	a029                	j	8000201a <reparent+0x34>
    80002012:	44048493          	addi	s1,s1,1088
    80002016:	01348f63          	beq	s1,s3,80002034 <reparent+0x4e>
    if(pp->parent == p){
    8000201a:	3104b783          	ld	a5,784(s1)
    8000201e:	ff279ae3          	bne	a5,s2,80002012 <reparent+0x2c>
      pp->parent = initproc;
    80002022:	000a3503          	ld	a0,0(s4)
    80002026:	30a4b823          	sd	a0,784(s1)
      wakeup(initproc);
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	f3a080e7          	jalr	-198(ra) # 80001f64 <wakeup>
    80002032:	b7c5                	j	80002012 <reparent+0x2c>
}
    80002034:	70a2                	ld	ra,40(sp)
    80002036:	7402                	ld	s0,32(sp)
    80002038:	64e2                	ld	s1,24(sp)
    8000203a:	6942                	ld	s2,16(sp)
    8000203c:	69a2                	ld	s3,8(sp)
    8000203e:	6a02                	ld	s4,0(sp)
    80002040:	6145                	addi	sp,sp,48
    80002042:	8082                	ret

0000000080002044 <exit>:
{
    80002044:	7179                	addi	sp,sp,-48
    80002046:	f406                	sd	ra,40(sp)
    80002048:	f022                	sd	s0,32(sp)
    8000204a:	ec26                	sd	s1,24(sp)
    8000204c:	e84a                	sd	s2,16(sp)
    8000204e:	e44e                	sd	s3,8(sp)
    80002050:	e052                	sd	s4,0(sp)
    80002052:	1800                	addi	s0,sp,48
    80002054:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	a9e080e7          	jalr	-1378(ra) # 80001af4 <myproc>
    8000205e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002060:	00007797          	auipc	a5,0x7
    80002064:	fc87b783          	ld	a5,-56(a5) # 80009028 <initproc>
    80002068:	3a850493          	addi	s1,a0,936
    8000206c:	42850913          	addi	s2,a0,1064
    80002070:	02a79363          	bne	a5,a0,80002096 <exit+0x52>
    panic("init exiting");
    80002074:	00006517          	auipc	a0,0x6
    80002078:	1ac50513          	addi	a0,a0,428 # 80008220 <digits+0x1e0>
    8000207c:	ffffe097          	auipc	ra,0xffffe
    80002080:	4c0080e7          	jalr	1216(ra) # 8000053c <panic>
      fileclose(f);
    80002084:	00003097          	auipc	ra,0x3
    80002088:	ecc080e7          	jalr	-308(ra) # 80004f50 <fileclose>
      p->ofile[fd] = 0;
    8000208c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002090:	04a1                	addi	s1,s1,8
    80002092:	01248563          	beq	s1,s2,8000209c <exit+0x58>
    if(p->ofile[fd]){
    80002096:	6088                	ld	a0,0(s1)
    80002098:	f575                	bnez	a0,80002084 <exit+0x40>
    8000209a:	bfdd                	j	80002090 <exit+0x4c>
  begin_op();
    8000209c:	00003097          	auipc	ra,0x3
    800020a0:	9e8080e7          	jalr	-1560(ra) # 80004a84 <begin_op>
  iput(p->cwd);
    800020a4:	4289b503          	ld	a0,1064(s3)
    800020a8:	00002097          	auipc	ra,0x2
    800020ac:	1ba080e7          	jalr	442(ra) # 80004262 <iput>
  end_op();
    800020b0:	00003097          	auipc	ra,0x3
    800020b4:	a52080e7          	jalr	-1454(ra) # 80004b02 <end_op>
  p->cwd = 0;
    800020b8:	4209b423          	sd	zero,1064(s3)
  acquire(&wait_lock);
    800020bc:	0000f497          	auipc	s1,0xf
    800020c0:	1fc48493          	addi	s1,s1,508 # 800112b8 <wait_lock>
    800020c4:	8526                	mv	a0,s1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	b56080e7          	jalr	-1194(ra) # 80000c1c <acquire>
  reparent(p);
    800020ce:	854e                	mv	a0,s3
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	f16080e7          	jalr	-234(ra) # 80001fe6 <reparent>
  wakeup(p->parent);
    800020d8:	3109b503          	ld	a0,784(s3)
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	e88080e7          	jalr	-376(ra) # 80001f64 <wakeup>
  acquire(&p->lock);
    800020e4:	2d898513          	addi	a0,s3,728
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	b34080e7          	jalr	-1228(ra) # 80000c1c <acquire>
  p->xstate = status;
    800020f0:	3149a223          	sw	s4,772(s3)
  p->state = ZOMBIE;
    800020f4:	4795                	li	a5,5
    800020f6:	2ef9a823          	sw	a5,752(s3)
  release(&wait_lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	bd4080e7          	jalr	-1068(ra) # 80000cd0 <release>
  sched();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	ccc080e7          	jalr	-820(ra) # 80001dd0 <sched>
  panic("zombie exit");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	12450513          	addi	a0,a0,292 # 80008230 <digits+0x1f0>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	428080e7          	jalr	1064(ra) # 8000053c <panic>

000000008000211c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000211c:	7179                	addi	sp,sp,-48
    8000211e:	f406                	sd	ra,40(sp)
    80002120:	f022                	sd	s0,32(sp)
    80002122:	ec26                	sd	s1,24(sp)
    80002124:	e84a                	sd	s2,16(sp)
    80002126:	e44e                	sd	s3,8(sp)
    80002128:	e052                	sd	s4,0(sp)
    8000212a:	1800                	addi	s0,sp,48
    8000212c:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000212e:	0000f497          	auipc	s1,0xf
    80002132:	5ba48493          	addi	s1,s1,1466 # 800116e8 <proc>
    80002136:	00020a17          	auipc	s4,0x20
    8000213a:	5b2a0a13          	addi	s4,s4,1458 # 800226e8 <mmr_list>
    acquire(&p->lock);
    8000213e:	2d848913          	addi	s2,s1,728
    80002142:	854a                	mv	a0,s2
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	ad8080e7          	jalr	-1320(ra) # 80000c1c <acquire>
    if(p->pid == pid){
    8000214c:	3084a783          	lw	a5,776(s1)
    80002150:	01378d63          	beq	a5,s3,8000216a <kill+0x4e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002154:	854a                	mv	a0,s2
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b7a080e7          	jalr	-1158(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000215e:	44048493          	addi	s1,s1,1088
    80002162:	fd449ee3          	bne	s1,s4,8000213e <kill+0x22>
  }
  return -1;
    80002166:	557d                	li	a0,-1
    80002168:	a839                	j	80002186 <kill+0x6a>
      p->killed = 1;
    8000216a:	4785                	li	a5,1
    8000216c:	30f4a023          	sw	a5,768(s1)
      if(p->state == SLEEPING){
    80002170:	2f04a703          	lw	a4,752(s1)
    80002174:	4789                	li	a5,2
    80002176:	02f70063          	beq	a4,a5,80002196 <kill+0x7a>
      release(&p->lock);
    8000217a:	854a                	mv	a0,s2
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b54080e7          	jalr	-1196(ra) # 80000cd0 <release>
      return 0;
    80002184:	4501                	li	a0,0
}
    80002186:	70a2                	ld	ra,40(sp)
    80002188:	7402                	ld	s0,32(sp)
    8000218a:	64e2                	ld	s1,24(sp)
    8000218c:	6942                	ld	s2,16(sp)
    8000218e:	69a2                	ld	s3,8(sp)
    80002190:	6a02                	ld	s4,0(sp)
    80002192:	6145                	addi	sp,sp,48
    80002194:	8082                	ret
        p->state = RUNNABLE;
    80002196:	478d                	li	a5,3
    80002198:	2ef4a823          	sw	a5,752(s1)
    8000219c:	bff9                	j	8000217a <kill+0x5e>

000000008000219e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	e052                	sd	s4,0(sp)
    800021ac:	1800                	addi	s0,sp,48
    800021ae:	84aa                	mv	s1,a0
    800021b0:	892e                	mv	s2,a1
    800021b2:	89b2                	mv	s3,a2
    800021b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	93e080e7          	jalr	-1730(ra) # 80001af4 <myproc>
  if(user_dst){
    800021be:	c095                	beqz	s1,800021e2 <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    800021c0:	86d2                	mv	a3,s4
    800021c2:	864e                	mv	a2,s3
    800021c4:	85ca                	mv	a1,s2
    800021c6:	32853503          	ld	a0,808(a0)
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	570080e7          	jalr	1392(ra) # 8000173a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800021d2:	70a2                	ld	ra,40(sp)
    800021d4:	7402                	ld	s0,32(sp)
    800021d6:	64e2                	ld	s1,24(sp)
    800021d8:	6942                	ld	s2,16(sp)
    800021da:	69a2                	ld	s3,8(sp)
    800021dc:	6a02                	ld	s4,0(sp)
    800021de:	6145                	addi	sp,sp,48
    800021e0:	8082                	ret
    memmove((char *)dst, src, len);
    800021e2:	000a061b          	sext.w	a2,s4
    800021e6:	85ce                	mv	a1,s3
    800021e8:	854a                	mv	a0,s2
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	b8a080e7          	jalr	-1142(ra) # 80000d74 <memmove>
    return 0;
    800021f2:	8526                	mv	a0,s1
    800021f4:	bff9                	j	800021d2 <either_copyout+0x34>

00000000800021f6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800021f6:	7179                	addi	sp,sp,-48
    800021f8:	f406                	sd	ra,40(sp)
    800021fa:	f022                	sd	s0,32(sp)
    800021fc:	ec26                	sd	s1,24(sp)
    800021fe:	e84a                	sd	s2,16(sp)
    80002200:	e44e                	sd	s3,8(sp)
    80002202:	e052                	sd	s4,0(sp)
    80002204:	1800                	addi	s0,sp,48
    80002206:	892a                	mv	s2,a0
    80002208:	84ae                	mv	s1,a1
    8000220a:	89b2                	mv	s3,a2
    8000220c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	8e6080e7          	jalr	-1818(ra) # 80001af4 <myproc>
  if(user_src){
    80002216:	c095                	beqz	s1,8000223a <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    80002218:	86d2                	mv	a3,s4
    8000221a:	864e                	mv	a2,s3
    8000221c:	85ca                	mv	a1,s2
    8000221e:	32853503          	ld	a0,808(a0)
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	5a4080e7          	jalr	1444(ra) # 800017c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000222a:	70a2                	ld	ra,40(sp)
    8000222c:	7402                	ld	s0,32(sp)
    8000222e:	64e2                	ld	s1,24(sp)
    80002230:	6942                	ld	s2,16(sp)
    80002232:	69a2                	ld	s3,8(sp)
    80002234:	6a02                	ld	s4,0(sp)
    80002236:	6145                	addi	sp,sp,48
    80002238:	8082                	ret
    memmove(dst, (char*)src, len);
    8000223a:	000a061b          	sext.w	a2,s4
    8000223e:	85ce                	mv	a1,s3
    80002240:	854a                	mv	a0,s2
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	b32080e7          	jalr	-1230(ra) # 80000d74 <memmove>
    return 0;
    8000224a:	8526                	mv	a0,s1
    8000224c:	bff9                	j	8000222a <either_copyin+0x34>

000000008000224e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000224e:	715d                	addi	sp,sp,-80
    80002250:	e486                	sd	ra,72(sp)
    80002252:	e0a2                	sd	s0,64(sp)
    80002254:	fc26                	sd	s1,56(sp)
    80002256:	f84a                	sd	s2,48(sp)
    80002258:	f44e                	sd	s3,40(sp)
    8000225a:	f052                	sd	s4,32(sp)
    8000225c:	ec56                	sd	s5,24(sp)
    8000225e:	e85a                	sd	s6,16(sp)
    80002260:	e45e                	sd	s7,8(sp)
    80002262:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002264:	00006517          	auipc	a0,0x6
    80002268:	e6450513          	addi	a0,a0,-412 # 800080c8 <digits+0x88>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	31a080e7          	jalr	794(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002274:	00010497          	auipc	s1,0x10
    80002278:	8a448493          	addi	s1,s1,-1884 # 80011b18 <proc+0x430>
    8000227c:	00021917          	auipc	s2,0x21
    80002280:	89c90913          	addi	s2,s2,-1892 # 80022b18 <mmr_list+0x430>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002284:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002286:	00006997          	auipc	s3,0x6
    8000228a:	fba98993          	addi	s3,s3,-70 # 80008240 <digits+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    8000228e:	00006a97          	auipc	s5,0x6
    80002292:	fbaa8a93          	addi	s5,s5,-70 # 80008248 <digits+0x208>
    printf("\n");
    80002296:	00006a17          	auipc	s4,0x6
    8000229a:	e32a0a13          	addi	s4,s4,-462 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000229e:	00006b97          	auipc	s7,0x6
    800022a2:	00ab8b93          	addi	s7,s7,10 # 800082a8 <states.0>
    800022a6:	a00d                	j	800022c8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800022a8:	ed86a583          	lw	a1,-296(a3)
    800022ac:	8556                	mv	a0,s5
    800022ae:	ffffe097          	auipc	ra,0xffffe
    800022b2:	2d8080e7          	jalr	728(ra) # 80000586 <printf>
    printf("\n");
    800022b6:	8552                	mv	a0,s4
    800022b8:	ffffe097          	auipc	ra,0xffffe
    800022bc:	2ce080e7          	jalr	718(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022c0:	44048493          	addi	s1,s1,1088
    800022c4:	03248263          	beq	s1,s2,800022e8 <procdump+0x9a>
    if(p->state == UNUSED)
    800022c8:	86a6                	mv	a3,s1
    800022ca:	ec04a783          	lw	a5,-320(s1)
    800022ce:	dbed                	beqz	a5,800022c0 <procdump+0x72>
      state = "???";
    800022d0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022d2:	fcfb6be3          	bltu	s6,a5,800022a8 <procdump+0x5a>
    800022d6:	02079713          	slli	a4,a5,0x20
    800022da:	01d75793          	srli	a5,a4,0x1d
    800022de:	97de                	add	a5,a5,s7
    800022e0:	6390                	ld	a2,0(a5)
    800022e2:	f279                	bnez	a2,800022a8 <procdump+0x5a>
      state = "???";
    800022e4:	864e                	mv	a2,s3
    800022e6:	b7c9                	j	800022a8 <procdump+0x5a>
  }
}
    800022e8:	60a6                	ld	ra,72(sp)
    800022ea:	6406                	ld	s0,64(sp)
    800022ec:	74e2                	ld	s1,56(sp)
    800022ee:	7942                	ld	s2,48(sp)
    800022f0:	79a2                	ld	s3,40(sp)
    800022f2:	7a02                	ld	s4,32(sp)
    800022f4:	6ae2                	ld	s5,24(sp)
    800022f6:	6b42                	ld	s6,16(sp)
    800022f8:	6ba2                	ld	s7,8(sp)
    800022fa:	6161                	addi	sp,sp,80
    800022fc:	8082                	ret

00000000800022fe <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    800022fe:	7119                	addi	sp,sp,-128
    80002300:	fc86                	sd	ra,120(sp)
    80002302:	f8a2                	sd	s0,112(sp)
    80002304:	f4a6                	sd	s1,104(sp)
    80002306:	f0ca                	sd	s2,96(sp)
    80002308:	ecce                	sd	s3,88(sp)
    8000230a:	e8d2                	sd	s4,80(sp)
    8000230c:	e4d6                	sd	s5,72(sp)
    8000230e:	e0da                	sd	s6,64(sp)
    80002310:	fc5e                	sd	s7,56(sp)
    80002312:	0100                	addi	s0,sp,128
    80002314:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	7de080e7          	jalr	2014(ra) # 80001af4 <myproc>
    8000231e:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002320:	0000f917          	auipc	s2,0xf
    80002324:	7f890913          	addi	s2,s2,2040 # 80011b18 <proc+0x430>
    80002328:	00020a17          	auipc	s4,0x20
    8000232c:	7f0a0a13          	addi	s4,s4,2032 # 80022b18 <mmr_list+0x430>
  int nprocs = 0;
    80002330:	4a81                	li	s5,0
    procinfo.state = p->state;
    procinfo.size = p->sz;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    80002332:	4b81                	li	s7,0
    80002334:	fac40493          	addi	s1,s0,-84
    80002338:	a089                	j	8000237a <procinfo+0x7c>
    8000233a:	f8f42c23          	sw	a5,-104(s0)
    for (int i=0; i<16; i++)
    8000233e:	f9c40793          	addi	a5,s0,-100
      procinfo.ppid = 0;
    80002342:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    80002344:	00074683          	lbu	a3,0(a4)
    80002348:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    8000234c:	0705                	addi	a4,a4,1
    8000234e:	0785                	addi	a5,a5,1
    80002350:	fe979ae3          	bne	a5,s1,80002344 <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    80002354:	02800693          	li	a3,40
    80002358:	f8840613          	addi	a2,s0,-120
    8000235c:	85ce                	mv	a1,s3
    8000235e:	328b3503          	ld	a0,808(s6)
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	3d8080e7          	jalr	984(ra) # 8000173a <copyout>
    8000236a:	02054d63          	bltz	a0,800023a4 <procinfo+0xa6>
      return -1;
    addr += sizeof(procinfo);
    8000236e:	02898993          	addi	s3,s3,40
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002372:	44090913          	addi	s2,s2,1088
    80002376:	03490863          	beq	s2,s4,800023a6 <procinfo+0xa8>
    if(p->state == UNUSED)
    8000237a:	ec092783          	lw	a5,-320(s2)
    8000237e:	dbf5                	beqz	a5,80002372 <procinfo+0x74>
    nprocs++;
    80002380:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    80002382:	ed892703          	lw	a4,-296(s2)
    80002386:	f8e42423          	sw	a4,-120(s0)
    procinfo.state = p->state;
    8000238a:	f8f42623          	sw	a5,-116(s0)
    procinfo.size = p->sz;
    8000238e:	ef093783          	ld	a5,-272(s2)
    80002392:	f8f43823          	sd	a5,-112(s0)
    if (p->parent)
    80002396:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    8000239a:	87de                	mv	a5,s7
    if (p->parent)
    8000239c:	df59                	beqz	a4,8000233a <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    8000239e:	30872783          	lw	a5,776(a4)
    800023a2:	bf61                	j	8000233a <procinfo+0x3c>
      return -1;
    800023a4:	5afd                	li	s5,-1
  }
  return nprocs;
}
    800023a6:	8556                	mv	a0,s5
    800023a8:	70e6                	ld	ra,120(sp)
    800023aa:	7446                	ld	s0,112(sp)
    800023ac:	74a6                	ld	s1,104(sp)
    800023ae:	7906                	ld	s2,96(sp)
    800023b0:	69e6                	ld	s3,88(sp)
    800023b2:	6a46                	ld	s4,80(sp)
    800023b4:	6aa6                	ld	s5,72(sp)
    800023b6:	6b06                	ld	s6,64(sp)
    800023b8:	7be2                	ld	s7,56(sp)
    800023ba:	6109                	addi	sp,sp,128
    800023bc:	8082                	ret

00000000800023be <mmrlistinit>:

// HW5 - Task 1a
// Initialize mmr_list
void
mmrlistinit(void)
{
    800023be:	7179                	addi	sp,sp,-48
    800023c0:	f406                	sd	ra,40(sp)
    800023c2:	f022                	sd	s0,32(sp)
    800023c4:	ec26                	sd	s1,24(sp)
    800023c6:	e84a                	sd	s2,16(sp)
    800023c8:	e44e                	sd	s3,8(sp)
    800023ca:	1800                	addi	s0,sp,48
  struct mmr_list *pmmrlist;
  initlock(&listid_lock,"listid");
    800023cc:	00006597          	auipc	a1,0x6
    800023d0:	e8c58593          	addi	a1,a1,-372 # 80008258 <digits+0x218>
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	2fc50513          	addi	a0,a0,764 # 800116d0 <listid_lock>
    800023dc:	ffffe097          	auipc	ra,0xffffe
    800023e0:	7b0080e7          	jalr	1968(ra) # 80000b8c <initlock>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    800023e4:	00020497          	auipc	s1,0x20
    800023e8:	30448493          	addi	s1,s1,772 # 800226e8 <mmr_list>
    initlock(&pmmrlist->lock, "mmrlist");
    800023ec:	00006997          	auipc	s3,0x6
    800023f0:	e7498993          	addi	s3,s3,-396 # 80008260 <digits+0x220>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    800023f4:	00025917          	auipc	s2,0x25
    800023f8:	2f490913          	addi	s2,s2,756 # 800276e8 <tickslock>
    initlock(&pmmrlist->lock, "mmrlist");
    800023fc:	85ce                	mv	a1,s3
    800023fe:	8526                	mv	a0,s1
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	78c080e7          	jalr	1932(ra) # 80000b8c <initlock>
    pmmrlist->valid = 0;
    80002408:	0004ac23          	sw	zero,24(s1)
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    8000240c:	02048493          	addi	s1,s1,32
    80002410:	ff2496e3          	bne	s1,s2,800023fc <mmrlistinit+0x3e>
  }
}
    80002414:	70a2                	ld	ra,40(sp)
    80002416:	7402                	ld	s0,32(sp)
    80002418:	64e2                	ld	s1,24(sp)
    8000241a:	6942                	ld	s2,16(sp)
    8000241c:	69a2                	ld	s3,8(sp)
    8000241e:	6145                	addi	sp,sp,48
    80002420:	8082                	ret

0000000080002422 <get_mmr_list>:

// find the mmr_list for a given listid
struct mmr_list*
get_mmr_list(int listid) {
    80002422:	1101                	addi	sp,sp,-32
    80002424:	ec06                	sd	ra,24(sp)
    80002426:	e822                	sd	s0,16(sp)
    80002428:	e426                	sd	s1,8(sp)
    8000242a:	1000                	addi	s0,sp,32
    8000242c:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    8000242e:	0000f517          	auipc	a0,0xf
    80002432:	2a250513          	addi	a0,a0,674 # 800116d0 <listid_lock>
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7e6080e7          	jalr	2022(ra) # 80000c1c <acquire>
  if (listid >=0 && listid < NPROC*MAX_MMR && mmr_list[listid].valid) {
    8000243e:	0004871b          	sext.w	a4,s1
    80002442:	27f00793          	li	a5,639
    80002446:	02e7eb63          	bltu	a5,a4,8000247c <get_mmr_list+0x5a>
    8000244a:	00549713          	slli	a4,s1,0x5
    8000244e:	00020797          	auipc	a5,0x20
    80002452:	29a78793          	addi	a5,a5,666 # 800226e8 <mmr_list>
    80002456:	97ba                	add	a5,a5,a4
    80002458:	4f9c                	lw	a5,24(a5)
    8000245a:	c38d                	beqz	a5,8000247c <get_mmr_list+0x5a>
    release(&listid_lock);
    8000245c:	0000f517          	auipc	a0,0xf
    80002460:	27450513          	addi	a0,a0,628 # 800116d0 <listid_lock>
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	86c080e7          	jalr	-1940(ra) # 80000cd0 <release>
    return(&mmr_list[listid]);
    8000246c:	00549513          	slli	a0,s1,0x5
    80002470:	00020797          	auipc	a5,0x20
    80002474:	27878793          	addi	a5,a5,632 # 800226e8 <mmr_list>
    80002478:	953e                	add	a0,a0,a5
    8000247a:	a811                	j	8000248e <get_mmr_list+0x6c>
  }
  else {
    release(&listid_lock);
    8000247c:	0000f517          	auipc	a0,0xf
    80002480:	25450513          	addi	a0,a0,596 # 800116d0 <listid_lock>
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	84c080e7          	jalr	-1972(ra) # 80000cd0 <release>
    return 0;
    8000248c:	4501                	li	a0,0
  }
}
    8000248e:	60e2                	ld	ra,24(sp)
    80002490:	6442                	ld	s0,16(sp)
    80002492:	64a2                	ld	s1,8(sp)
    80002494:	6105                	addi	sp,sp,32
    80002496:	8082                	ret

0000000080002498 <dealloc_mmr_listid>:

// free up entry in mmr_list array
void
dealloc_mmr_listid(int listid) {
    80002498:	1101                	addi	sp,sp,-32
    8000249a:	ec06                	sd	ra,24(sp)
    8000249c:	e822                	sd	s0,16(sp)
    8000249e:	e426                	sd	s1,8(sp)
    800024a0:	e04a                	sd	s2,0(sp)
    800024a2:	1000                	addi	s0,sp,32
    800024a4:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    800024a6:	0000f917          	auipc	s2,0xf
    800024aa:	22a90913          	addi	s2,s2,554 # 800116d0 <listid_lock>
    800024ae:	854a                	mv	a0,s2
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	76c080e7          	jalr	1900(ra) # 80000c1c <acquire>
  mmr_list[listid].valid = 0;
    800024b8:	0496                	slli	s1,s1,0x5
    800024ba:	00020797          	auipc	a5,0x20
    800024be:	22e78793          	addi	a5,a5,558 # 800226e8 <mmr_list>
    800024c2:	97a6                	add	a5,a5,s1
    800024c4:	0007ac23          	sw	zero,24(a5)
  release(&listid_lock);
    800024c8:	854a                	mv	a0,s2
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	806080e7          	jalr	-2042(ra) # 80000cd0 <release>
}
    800024d2:	60e2                	ld	ra,24(sp)
    800024d4:	6442                	ld	s0,16(sp)
    800024d6:	64a2                	ld	s1,8(sp)
    800024d8:	6902                	ld	s2,0(sp)
    800024da:	6105                	addi	sp,sp,32
    800024dc:	8082                	ret

00000000800024de <freeproc>:
{
    800024de:	711d                	addi	sp,sp,-96
    800024e0:	ec86                	sd	ra,88(sp)
    800024e2:	e8a2                	sd	s0,80(sp)
    800024e4:	e4a6                	sd	s1,72(sp)
    800024e6:	e0ca                	sd	s2,64(sp)
    800024e8:	fc4e                	sd	s3,56(sp)
    800024ea:	f852                	sd	s4,48(sp)
    800024ec:	f456                	sd	s5,40(sp)
    800024ee:	f05a                	sd	s6,32(sp)
    800024f0:	ec5e                	sd	s7,24(sp)
    800024f2:	e862                	sd	s8,16(sp)
    800024f4:	e466                	sd	s9,8(sp)
    800024f6:	1080                	addi	s0,sp,96
    800024f8:	8a2a                	mv	s4,a0
  if(p->trapframe)
    800024fa:	33053503          	ld	a0,816(a0)
    800024fe:	c509                	beqz	a0,80002508 <freeproc+0x2a>
    kfree((void*)p->trapframe);
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	4e4080e7          	jalr	1252(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80002508:	320a3823          	sd	zero,816(s4)
  for (int i = 0; i < MAX_MMR; i++) {
    8000250c:	028a0913          	addi	s2,s4,40
    80002510:	2f8a0c13          	addi	s8,s4,760
    if (p->mmr[i].valid == 1) {
    80002514:	4b05                	li	s6,1
      for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr + p->mmr[i].length; addr += PGSIZE)
    80002516:	6b85                	lui	s7,0x1
        acquire(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    80002518:	00020c97          	auipc	s9,0x20
    8000251c:	1d0c8c93          	addi	s9,s9,464 # 800226e8 <mmr_list>
    80002520:	a851                	j	800025b4 <freeproc+0xd6>
    80002522:	00092503          	lw	a0,0(s2)
    80002526:	0516                	slli	a0,a0,0x5
    80002528:	9566                	add	a0,a0,s9
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	6f2080e7          	jalr	1778(ra) # 80000c1c <acquire>
        if (p->mmr[i].mmr_family.next == &(p->mmr[i].mmr_family)) { // no other family members
    80002532:	01093783          	ld	a5,16(s2)
    80002536:	03278263          	beq	a5,s2,8000255a <freeproc+0x7c>
          (p->mmr[i].mmr_family.next)->prev = p->mmr[i].mmr_family.prev;
    8000253a:	01893703          	ld	a4,24(s2)
    8000253e:	ef98                	sd	a4,24(a5)
          (p->mmr[i].mmr_family.prev)->next = p->mmr[i].mmr_family.next;
    80002540:	01093783          	ld	a5,16(s2)
    80002544:	eb1c                	sd	a5,16(a4)
          release(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    80002546:	00092503          	lw	a0,0(s2)
    8000254a:	0516                	slli	a0,a0,0x5
    8000254c:	9566                	add	a0,a0,s9
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	782080e7          	jalr	1922(ra) # 80000cd0 <release>
    int dofree = 0;
    80002556:	8aa6                	mv	s5,s1
    80002558:	a0bd                	j	800025c6 <freeproc+0xe8>
          release(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    8000255a:	00092503          	lw	a0,0(s2)
    8000255e:	0516                	slli	a0,a0,0x5
    80002560:	9566                	add	a0,a0,s9
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	76e080e7          	jalr	1902(ra) # 80000cd0 <release>
          dealloc_mmr_listid(p->mmr[i].mmr_family.listid);
    8000256a:	00092503          	lw	a0,0(s2)
    8000256e:	00000097          	auipc	ra,0x0
    80002572:	f2a080e7          	jalr	-214(ra) # 80002498 <dealloc_mmr_listid>
    80002576:	a881                	j	800025c6 <freeproc+0xe8>
      for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr + p->mmr[i].length; addr += PGSIZE)
    80002578:	94de                	add	s1,s1,s7
    8000257a:	fe09a783          	lw	a5,-32(s3)
    8000257e:	fd89b703          	ld	a4,-40(s3)
    80002582:	97ba                	add	a5,a5,a4
    80002584:	02f4f463          	bgeu	s1,a5,800025ac <freeproc+0xce>
        if (walkaddr(p->pagetable, addr))
    80002588:	85a6                	mv	a1,s1
    8000258a:	328a3503          	ld	a0,808(s4)
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	b20080e7          	jalr	-1248(ra) # 800010ae <walkaddr>
    80002596:	d16d                	beqz	a0,80002578 <freeproc+0x9a>
          uvmunmap(p->pagetable, addr, 1, dofree);
    80002598:	86d6                	mv	a3,s5
    8000259a:	865a                	mv	a2,s6
    8000259c:	85a6                	mv	a1,s1
    8000259e:	328a3503          	ld	a0,808(s4)
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	d14080e7          	jalr	-748(ra) # 800012b6 <uvmunmap>
    800025aa:	b7f9                	j	80002578 <freeproc+0x9a>
  for (int i = 0; i < MAX_MMR; i++) {
    800025ac:	04890913          	addi	s2,s2,72
    800025b0:	03890363          	beq	s2,s8,800025d6 <freeproc+0xf8>
    if (p->mmr[i].valid == 1) {
    800025b4:	89ca                	mv	s3,s2
    800025b6:	fec92a83          	lw	s5,-20(s2)
    800025ba:	ff6a99e3          	bne	s5,s6,800025ac <freeproc+0xce>
      if (p->mmr[i].flags & MAP_PRIVATE)
    800025be:	fe892483          	lw	s1,-24(s2)
    800025c2:	8889                	andi	s1,s1,2
    800025c4:	dcb9                	beqz	s1,80002522 <freeproc+0x44>
      for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr + p->mmr[i].length; addr += PGSIZE)
    800025c6:	fd89b483          	ld	s1,-40(s3)
    800025ca:	fe09a783          	lw	a5,-32(s3)
    800025ce:	97a6                	add	a5,a5,s1
    800025d0:	faf4ece3          	bltu	s1,a5,80002588 <freeproc+0xaa>
    800025d4:	bfe1                	j	800025ac <freeproc+0xce>
  if(p->pagetable)
    800025d6:	328a3503          	ld	a0,808(s4)
    800025da:	c519                	beqz	a0,800025e8 <freeproc+0x10a>
    proc_freepagetable(p->pagetable, p->sz);
    800025dc:	320a3583          	ld	a1,800(s4)
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	678080e7          	jalr	1656(ra) # 80001c58 <proc_freepagetable>
  p->pagetable = 0;
    800025e8:	320a3423          	sd	zero,808(s4)
  p->sz = 0;
    800025ec:	320a3023          	sd	zero,800(s4)
  p->pid = 0;
    800025f0:	300a2423          	sw	zero,776(s4)
  p->parent = 0;
    800025f4:	300a3823          	sd	zero,784(s4)
  p->name[0] = 0;
    800025f8:	420a0823          	sb	zero,1072(s4)
  p->chan = 0;
    800025fc:	2e0a3c23          	sd	zero,760(s4)
  p->killed = 0;
    80002600:	300a2023          	sw	zero,768(s4)
  p->xstate = 0;
    80002604:	300a2223          	sw	zero,772(s4)
  p->state = UNUSED;
    80002608:	2e0a2823          	sw	zero,752(s4)
}
    8000260c:	60e6                	ld	ra,88(sp)
    8000260e:	6446                	ld	s0,80(sp)
    80002610:	64a6                	ld	s1,72(sp)
    80002612:	6906                	ld	s2,64(sp)
    80002614:	79e2                	ld	s3,56(sp)
    80002616:	7a42                	ld	s4,48(sp)
    80002618:	7aa2                	ld	s5,40(sp)
    8000261a:	7b02                	ld	s6,32(sp)
    8000261c:	6be2                	ld	s7,24(sp)
    8000261e:	6c42                	ld	s8,16(sp)
    80002620:	6ca2                	ld	s9,8(sp)
    80002622:	6125                	addi	sp,sp,96
    80002624:	8082                	ret

0000000080002626 <allocproc>:
{
    80002626:	7179                	addi	sp,sp,-48
    80002628:	f406                	sd	ra,40(sp)
    8000262a:	f022                	sd	s0,32(sp)
    8000262c:	ec26                	sd	s1,24(sp)
    8000262e:	e84a                	sd	s2,16(sp)
    80002630:	e44e                	sd	s3,8(sp)
    80002632:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80002634:	0000f497          	auipc	s1,0xf
    80002638:	0b448493          	addi	s1,s1,180 # 800116e8 <proc>
    8000263c:	00020997          	auipc	s3,0x20
    80002640:	0ac98993          	addi	s3,s3,172 # 800226e8 <mmr_list>
    acquire(&p->lock);
    80002644:	2d848913          	addi	s2,s1,728
    80002648:	854a                	mv	a0,s2
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	5d2080e7          	jalr	1490(ra) # 80000c1c <acquire>
    if(p->state == UNUSED) {
    80002652:	2f04a783          	lw	a5,752(s1)
    80002656:	cf81                	beqz	a5,8000266e <allocproc+0x48>
      release(&p->lock);
    80002658:	854a                	mv	a0,s2
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	676080e7          	jalr	1654(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002662:	44048493          	addi	s1,s1,1088
    80002666:	fd349fe3          	bne	s1,s3,80002644 <allocproc+0x1e>
  return 0;
    8000266a:	4481                	li	s1,0
    8000266c:	a085                	j	800026cc <allocproc+0xa6>
  p->pid = allocpid();
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	508080e7          	jalr	1288(ra) # 80001b76 <allocpid>
    80002676:	30a4a423          	sw	a0,776(s1)
  p->state = USED;
    8000267a:	4785                	li	a5,1
    8000267c:	2ef4a823          	sw	a5,752(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	462080e7          	jalr	1122(ra) # 80000ae2 <kalloc>
    80002688:	89aa                	mv	s3,a0
    8000268a:	32a4b823          	sd	a0,816(s1)
    8000268e:	c539                	beqz	a0,800026dc <allocproc+0xb6>
  p->pagetable = proc_pagetable(p);
    80002690:	8526                	mv	a0,s1
    80002692:	fffff097          	auipc	ra,0xfffff
    80002696:	52a080e7          	jalr	1322(ra) # 80001bbc <proc_pagetable>
    8000269a:	89aa                	mv	s3,a0
    8000269c:	32a4b423          	sd	a0,808(s1)
  if(p->pagetable == 0){
    800026a0:	c931                	beqz	a0,800026f4 <allocproc+0xce>
  memset(&p->context, 0, sizeof(p->context));
    800026a2:	07000613          	li	a2,112
    800026a6:	4581                	li	a1,0
    800026a8:	33848513          	addi	a0,s1,824
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	66c080e7          	jalr	1644(ra) # 80000d18 <memset>
  p->context.ra = (uint64)forkret;
    800026b4:	fffff797          	auipc	a5,0xfffff
    800026b8:	47878793          	addi	a5,a5,1144 # 80001b2c <forkret>
    800026bc:	32f4bc23          	sd	a5,824(s1)
  p->context.sp = p->kstack + PGSIZE;
    800026c0:	3184b783          	ld	a5,792(s1)
    800026c4:	6705                	lui	a4,0x1
    800026c6:	97ba                	add	a5,a5,a4
    800026c8:	34f4b023          	sd	a5,832(s1)
}
    800026cc:	8526                	mv	a0,s1
    800026ce:	70a2                	ld	ra,40(sp)
    800026d0:	7402                	ld	s0,32(sp)
    800026d2:	64e2                	ld	s1,24(sp)
    800026d4:	6942                	ld	s2,16(sp)
    800026d6:	69a2                	ld	s3,8(sp)
    800026d8:	6145                	addi	sp,sp,48
    800026da:	8082                	ret
    freeproc(p);
    800026dc:	8526                	mv	a0,s1
    800026de:	00000097          	auipc	ra,0x0
    800026e2:	e00080e7          	jalr	-512(ra) # 800024de <freeproc>
    release(&p->lock);
    800026e6:	854a                	mv	a0,s2
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5e8080e7          	jalr	1512(ra) # 80000cd0 <release>
    return 0;
    800026f0:	84ce                	mv	s1,s3
    800026f2:	bfe9                	j	800026cc <allocproc+0xa6>
    freeproc(p);
    800026f4:	8526                	mv	a0,s1
    800026f6:	00000097          	auipc	ra,0x0
    800026fa:	de8080e7          	jalr	-536(ra) # 800024de <freeproc>
    release(&p->lock);
    800026fe:	854a                	mv	a0,s2
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	5d0080e7          	jalr	1488(ra) # 80000cd0 <release>
    return 0;
    80002708:	84ce                	mv	s1,s3
    8000270a:	b7c9                	j	800026cc <allocproc+0xa6>

000000008000270c <userinit>:
{
    8000270c:	1101                	addi	sp,sp,-32
    8000270e:	ec06                	sd	ra,24(sp)
    80002710:	e822                	sd	s0,16(sp)
    80002712:	e426                	sd	s1,8(sp)
    80002714:	1000                	addi	s0,sp,32
  p = allocproc();
    80002716:	00000097          	auipc	ra,0x0
    8000271a:	f10080e7          	jalr	-240(ra) # 80002626 <allocproc>
    8000271e:	84aa                	mv	s1,a0
  initproc = p;
    80002720:	00007797          	auipc	a5,0x7
    80002724:	90a7b423          	sd	a0,-1784(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002728:	03400613          	li	a2,52
    8000272c:	00006597          	auipc	a1,0x6
    80002730:	16458593          	addi	a1,a1,356 # 80008890 <initcode>
    80002734:	32853503          	ld	a0,808(a0)
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	c52080e7          	jalr	-942(ra) # 8000138a <uvminit>
  p->sz = PGSIZE;
    80002740:	6785                	lui	a5,0x1
    80002742:	32f4b023          	sd	a5,800(s1)
  p->trapframe->epc = 0;      // user program counter
    80002746:	3304b703          	ld	a4,816(s1)
    8000274a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000274e:	3304b703          	ld	a4,816(s1)
    80002752:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002754:	4641                	li	a2,16
    80002756:	00006597          	auipc	a1,0x6
    8000275a:	b1258593          	addi	a1,a1,-1262 # 80008268 <digits+0x228>
    8000275e:	43048513          	addi	a0,s1,1072
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	700080e7          	jalr	1792(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    8000276a:	00006517          	auipc	a0,0x6
    8000276e:	b0e50513          	addi	a0,a0,-1266 # 80008278 <digits+0x238>
    80002772:	00002097          	auipc	ra,0x2
    80002776:	0f2080e7          	jalr	242(ra) # 80004864 <namei>
    8000277a:	42a4b423          	sd	a0,1064(s1)
  p->state = RUNNABLE;
    8000277e:	478d                	li	a5,3
    80002780:	2ef4a823          	sw	a5,752(s1)
  p->cur_max = MAXVA - 2*PGSIZE;
    80002784:	020007b7          	lui	a5,0x2000
    80002788:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    8000278a:	07b6                	slli	a5,a5,0xd
    8000278c:	2cf4b823          	sd	a5,720(s1)
  release(&p->lock);
    80002790:	2d848513          	addi	a0,s1,728
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	53c080e7          	jalr	1340(ra) # 80000cd0 <release>
}
    8000279c:	60e2                	ld	ra,24(sp)
    8000279e:	6442                	ld	s0,16(sp)
    800027a0:	64a2                	ld	s1,8(sp)
    800027a2:	6105                	addi	sp,sp,32
    800027a4:	8082                	ret

00000000800027a6 <fork>:
{
    800027a6:	7159                	addi	sp,sp,-112
    800027a8:	f486                	sd	ra,104(sp)
    800027aa:	f0a2                	sd	s0,96(sp)
    800027ac:	eca6                	sd	s1,88(sp)
    800027ae:	e8ca                	sd	s2,80(sp)
    800027b0:	e4ce                	sd	s3,72(sp)
    800027b2:	e0d2                	sd	s4,64(sp)
    800027b4:	fc56                	sd	s5,56(sp)
    800027b6:	f85a                	sd	s6,48(sp)
    800027b8:	f45e                	sd	s7,40(sp)
    800027ba:	f062                	sd	s8,32(sp)
    800027bc:	ec66                	sd	s9,24(sp)
    800027be:	e86a                	sd	s10,16(sp)
    800027c0:	e46e                	sd	s11,8(sp)
    800027c2:	1880                	addi	s0,sp,112
  struct proc *p = myproc();
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	330080e7          	jalr	816(ra) # 80001af4 <myproc>
    800027cc:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800027ce:	00000097          	auipc	ra,0x0
    800027d2:	e58080e7          	jalr	-424(ra) # 80002626 <allocproc>
    800027d6:	28050b63          	beqz	a0,80002a6c <fork+0x2c6>
    800027da:	8b2a                	mv	s6,a0
  if(uvmcopy(p->pagetable, np->pagetable,0, p->sz) < 0){
    800027dc:	3209b683          	ld	a3,800(s3)
    800027e0:	4601                	li	a2,0
    800027e2:	32853583          	ld	a1,808(a0)
    800027e6:	3289b503          	ld	a0,808(s3)
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	daa080e7          	jalr	-598(ra) # 80001594 <uvmcopy>
    800027f2:	04054c63          	bltz	a0,8000284a <fork+0xa4>
  np->sz = p->sz;
    800027f6:	3209b783          	ld	a5,800(s3)
    800027fa:	32fb3023          	sd	a5,800(s6)
  np->cur_max = p->cur_max;
    800027fe:	2d09b783          	ld	a5,720(s3)
    80002802:	2cfb3823          	sd	a5,720(s6)
  *(np->trapframe) = *(p->trapframe);
    80002806:	3309b683          	ld	a3,816(s3)
    8000280a:	87b6                	mv	a5,a3
    8000280c:	330b3703          	ld	a4,816(s6)
    80002810:	12068693          	addi	a3,a3,288
    80002814:	0007b803          	ld	a6,0(a5)
    80002818:	6788                	ld	a0,8(a5)
    8000281a:	6b8c                	ld	a1,16(a5)
    8000281c:	6f90                	ld	a2,24(a5)
    8000281e:	01073023          	sd	a6,0(a4)
    80002822:	e708                	sd	a0,8(a4)
    80002824:	eb0c                	sd	a1,16(a4)
    80002826:	ef10                	sd	a2,24(a4)
    80002828:	02078793          	addi	a5,a5,32
    8000282c:	02070713          	addi	a4,a4,32
    80002830:	fed792e3          	bne	a5,a3,80002814 <fork+0x6e>
  np->trapframe->a0 = 0;
    80002834:	330b3783          	ld	a5,816(s6)
    80002838:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000283c:	3a898493          	addi	s1,s3,936
    80002840:	3a8b0913          	addi	s2,s6,936
    80002844:	42898a13          	addi	s4,s3,1064
    80002848:	a015                	j	8000286c <fork+0xc6>
    freeproc(np);
    8000284a:	855a                	mv	a0,s6
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	c92080e7          	jalr	-878(ra) # 800024de <freeproc>
    release(&np->lock);
    80002854:	2d8b0513          	addi	a0,s6,728
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	478080e7          	jalr	1144(ra) # 80000cd0 <release>
    return -1;
    80002860:	5d7d                	li	s10,-1
    80002862:	a2ed                	j	80002a4c <fork+0x2a6>
  for(i = 0; i < NOFILE; i++)
    80002864:	04a1                	addi	s1,s1,8
    80002866:	0921                	addi	s2,s2,8
    80002868:	01448b63          	beq	s1,s4,8000287e <fork+0xd8>
    if(p->ofile[i])
    8000286c:	6088                	ld	a0,0(s1)
    8000286e:	d97d                	beqz	a0,80002864 <fork+0xbe>
      np->ofile[i] = filedup(p->ofile[i]);
    80002870:	00002097          	auipc	ra,0x2
    80002874:	68e080e7          	jalr	1678(ra) # 80004efe <filedup>
    80002878:	00a93023          	sd	a0,0(s2)
    8000287c:	b7e5                	j	80002864 <fork+0xbe>
  np->cwd = idup(p->cwd);
    8000287e:	4289b503          	ld	a0,1064(s3)
    80002882:	00001097          	auipc	ra,0x1
    80002886:	7e8080e7          	jalr	2024(ra) # 8000406a <idup>
    8000288a:	42ab3423          	sd	a0,1064(s6)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000288e:	4641                	li	a2,16
    80002890:	43098593          	addi	a1,s3,1072
    80002894:	430b0513          	addi	a0,s6,1072
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	5ca080e7          	jalr	1482(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    800028a0:	308b2d03          	lw	s10,776(s6)
  memmove((char*)np->mmr, (char *)p->mmr, MAX_MMR*sizeof(struct mmr));
    800028a4:	2d000613          	li	a2,720
    800028a8:	85ce                	mv	a1,s3
    800028aa:	855a                	mv	a0,s6
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	4c8080e7          	jalr	1224(ra) # 80000d74 <memmove>
  for (int i = 0; i < MAX_MMR; i++) {
    800028b4:	028b0b93          	addi	s7,s6,40
    800028b8:	02898a93          	addi	s5,s3,40
    800028bc:	2f898c93          	addi	s9,s3,760
    if(p->mmr[i].valid == 1) {
    800028c0:	4c05                	li	s8,1
            if(uvmcopyshared(p->pagetable, np->pagetable, addr, addr+PGSIZE) < 0) {
    800028c2:	6a05                	lui	s4,0x1
        acquire(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    800028c4:	00020d97          	auipc	s11,0x20
    800028c8:	e24d8d93          	addi	s11,s11,-476 # 800226e8 <mmr_list>
    800028cc:	a895                	j	80002940 <fork+0x19a>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    800028ce:	9952                	add	s2,s2,s4
    800028d0:	fe04a783          	lw	a5,-32(s1)
    800028d4:	fd84b703          	ld	a4,-40(s1)
    800028d8:	97ba                	add	a5,a5,a4
    800028da:	04f97463          	bgeu	s2,a5,80002922 <fork+0x17c>
          if(walkaddr(p->pagetable, addr))
    800028de:	85ca                	mv	a1,s2
    800028e0:	3289b503          	ld	a0,808(s3)
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	7ca080e7          	jalr	1994(ra) # 800010ae <walkaddr>
    800028ec:	d16d                	beqz	a0,800028ce <fork+0x128>
            if(uvmcopy(p->pagetable, np->pagetable, addr, addr+PGSIZE) < 0) {
    800028ee:	014906b3          	add	a3,s2,s4
    800028f2:	864a                	mv	a2,s2
    800028f4:	328b3583          	ld	a1,808(s6)
    800028f8:	3289b503          	ld	a0,808(s3)
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	c98080e7          	jalr	-872(ra) # 80001594 <uvmcopy>
    80002904:	fc0555e3          	bgez	a0,800028ce <fork+0x128>
              freeproc(np);
    80002908:	855a                	mv	a0,s6
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	bd4080e7          	jalr	-1068(ra) # 800024de <freeproc>
              release(&np->lock);
    80002912:	2d8b0513          	addi	a0,s6,728
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	3ba080e7          	jalr	954(ra) # 80000cd0 <release>
              return -1;
    8000291e:	5d7d                	li	s10,-1
    80002920:	a235                	j	80002a4c <fork+0x2a6>
        np->mmr[i].mmr_family.proc = np;
    80002922:	016bb423          	sd	s6,8(s7) # 1008 <_entry-0x7fffeff8>
        np->mmr[i].mmr_family.listid = -1;
    80002926:	57fd                	li	a5,-1
    80002928:	00fba023          	sw	a5,0(s7)
        np->mmr[i].mmr_family.next = &(np->mmr[i].mmr_family);
    8000292c:	017bb823          	sd	s7,16(s7)
        np->mmr[i].mmr_family.prev = &(np->mmr[i].mmr_family);
    80002930:	017bbc23          	sd	s7,24(s7)
  for (int i = 0; i < MAX_MMR; i++) {
    80002934:	048b8b93          	addi	s7,s7,72
    80002938:	048a8a93          	addi	s5,s5,72
    8000293c:	0d9a8463          	beq	s5,s9,80002a04 <fork+0x25e>
    if(p->mmr[i].valid == 1) {
    80002940:	84d6                	mv	s1,s5
    80002942:	fecaa783          	lw	a5,-20(s5)
    80002946:	ff8797e3          	bne	a5,s8,80002934 <fork+0x18e>
      if(p->mmr[i].flags & MAP_PRIVATE) {
    8000294a:	fe8aa783          	lw	a5,-24(s5)
    8000294e:	8b89                	andi	a5,a5,2
    80002950:	cb89                	beqz	a5,80002962 <fork+0x1bc>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    80002952:	fd8ab903          	ld	s2,-40(s5)
    80002956:	fe0aa783          	lw	a5,-32(s5)
    8000295a:	97ca                	add	a5,a5,s2
    8000295c:	f8f961e3          	bltu	s2,a5,800028de <fork+0x138>
    80002960:	b7c9                	j	80002922 <fork+0x17c>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    80002962:	fd8ab903          	ld	s2,-40(s5)
    80002966:	fe0aa783          	lw	a5,-32(s5)
    8000296a:	97ca                	add	a5,a5,s2
    8000296c:	04f96763          	bltu	s2,a5,800029ba <fork+0x214>
        np->mmr[i].mmr_family.proc = np;
    80002970:	016bb423          	sd	s6,8(s7)
        np->mmr[i].mmr_family.listid = p->mmr[i].mmr_family.listid;
    80002974:	4088                	lw	a0,0(s1)
    80002976:	00aba023          	sw	a0,0(s7)
        acquire(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    8000297a:	0516                	slli	a0,a0,0x5
    8000297c:	956e                	add	a0,a0,s11
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	29e080e7          	jalr	670(ra) # 80000c1c <acquire>
        np->mmr[i].mmr_family.next = p->mmr[i].mmr_family.next;
    80002986:	689c                	ld	a5,16(s1)
    80002988:	00fbb823          	sd	a5,16(s7)
        p->mmr[i].mmr_family.next = &(np->mmr[i].mmr_family);
    8000298c:	0174b823          	sd	s7,16(s1)
        np->mmr[i].mmr_family.prev = &(p->mmr[i].mmr_family);
    80002990:	009bbc23          	sd	s1,24(s7)
        if (p->mmr[i].mmr_family.prev == &(p->mmr[i].mmr_family))
    80002994:	6c9c                	ld	a5,24(s1)
    80002996:	06978463          	beq	a5,s1,800029fe <fork+0x258>
        release(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    8000299a:	4088                	lw	a0,0(s1)
    8000299c:	0516                	slli	a0,a0,0x5
    8000299e:	956e                	add	a0,a0,s11
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	330080e7          	jalr	816(ra) # 80000cd0 <release>
    800029a8:	b771                	j	80002934 <fork+0x18e>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    800029aa:	9952                	add	s2,s2,s4
    800029ac:	fe04a783          	lw	a5,-32(s1)
    800029b0:	fd84b703          	ld	a4,-40(s1)
    800029b4:	97ba                	add	a5,a5,a4
    800029b6:	faf97de3          	bgeu	s2,a5,80002970 <fork+0x1ca>
          if(walkaddr(p->pagetable, addr))
    800029ba:	85ca                	mv	a1,s2
    800029bc:	3289b503          	ld	a0,808(s3)
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	6ee080e7          	jalr	1774(ra) # 800010ae <walkaddr>
    800029c8:	d16d                	beqz	a0,800029aa <fork+0x204>
            if(uvmcopyshared(p->pagetable, np->pagetable, addr, addr+PGSIZE) < 0) {
    800029ca:	014906b3          	add	a3,s2,s4
    800029ce:	864a                	mv	a2,s2
    800029d0:	328b3583          	ld	a1,808(s6)
    800029d4:	3289b503          	ld	a0,808(s3)
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	c90080e7          	jalr	-880(ra) # 80001668 <uvmcopyshared>
    800029e0:	fc0555e3          	bgez	a0,800029aa <fork+0x204>
              freeproc(np);
    800029e4:	855a                	mv	a0,s6
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	af8080e7          	jalr	-1288(ra) # 800024de <freeproc>
              release(&np->lock);
    800029ee:	2d8b0513          	addi	a0,s6,728
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	2de080e7          	jalr	734(ra) # 80000cd0 <release>
              return -1;
    800029fa:	5d7d                	li	s10,-1
    800029fc:	a881                	j	80002a4c <fork+0x2a6>
          p->mmr[i].mmr_family.prev = &(np->mmr[i].mmr_family);
    800029fe:	0174bc23          	sd	s7,24(s1)
    80002a02:	bf61                	j	8000299a <fork+0x1f4>
  release(&np->lock);
    80002a04:	2d8b0493          	addi	s1,s6,728
    80002a08:	8526                	mv	a0,s1
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	2c6080e7          	jalr	710(ra) # 80000cd0 <release>
  acquire(&wait_lock);
    80002a12:	0000f917          	auipc	s2,0xf
    80002a16:	8a690913          	addi	s2,s2,-1882 # 800112b8 <wait_lock>
    80002a1a:	854a                	mv	a0,s2
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	200080e7          	jalr	512(ra) # 80000c1c <acquire>
  np->parent = p;
    80002a24:	313b3823          	sd	s3,784(s6)
  release(&wait_lock);
    80002a28:	854a                	mv	a0,s2
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	2a6080e7          	jalr	678(ra) # 80000cd0 <release>
  acquire(&np->lock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	1e8080e7          	jalr	488(ra) # 80000c1c <acquire>
  np->state = RUNNABLE;
    80002a3c:	478d                	li	a5,3
    80002a3e:	2efb2823          	sw	a5,752(s6)
  release(&np->lock);
    80002a42:	8526                	mv	a0,s1
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	28c080e7          	jalr	652(ra) # 80000cd0 <release>
}
    80002a4c:	856a                	mv	a0,s10
    80002a4e:	70a6                	ld	ra,104(sp)
    80002a50:	7406                	ld	s0,96(sp)
    80002a52:	64e6                	ld	s1,88(sp)
    80002a54:	6946                	ld	s2,80(sp)
    80002a56:	69a6                	ld	s3,72(sp)
    80002a58:	6a06                	ld	s4,64(sp)
    80002a5a:	7ae2                	ld	s5,56(sp)
    80002a5c:	7b42                	ld	s6,48(sp)
    80002a5e:	7ba2                	ld	s7,40(sp)
    80002a60:	7c02                	ld	s8,32(sp)
    80002a62:	6ce2                	ld	s9,24(sp)
    80002a64:	6d42                	ld	s10,16(sp)
    80002a66:	6da2                	ld	s11,8(sp)
    80002a68:	6165                	addi	sp,sp,112
    80002a6a:	8082                	ret
    return -1;
    80002a6c:	5d7d                	li	s10,-1
    80002a6e:	bff9                	j	80002a4c <fork+0x2a6>

0000000080002a70 <wait>:
{
    80002a70:	711d                	addi	sp,sp,-96
    80002a72:	ec86                	sd	ra,88(sp)
    80002a74:	e8a2                	sd	s0,80(sp)
    80002a76:	e4a6                	sd	s1,72(sp)
    80002a78:	e0ca                	sd	s2,64(sp)
    80002a7a:	fc4e                	sd	s3,56(sp)
    80002a7c:	f852                	sd	s4,48(sp)
    80002a7e:	f456                	sd	s5,40(sp)
    80002a80:	f05a                	sd	s6,32(sp)
    80002a82:	ec5e                	sd	s7,24(sp)
    80002a84:	e862                	sd	s8,16(sp)
    80002a86:	e466                	sd	s9,8(sp)
    80002a88:	1080                	addi	s0,sp,96
    80002a8a:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	068080e7          	jalr	104(ra) # 80001af4 <myproc>
    80002a94:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002a96:	0000f517          	auipc	a0,0xf
    80002a9a:	82250513          	addi	a0,a0,-2014 # 800112b8 <wait_lock>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	17e080e7          	jalr	382(ra) # 80000c1c <acquire>
    havekids = 0;
    80002aa6:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    80002aa8:	4a95                	li	s5,5
        havekids = 1;
    80002aaa:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002aac:	00020997          	auipc	s3,0x20
    80002ab0:	c3c98993          	addi	s3,s3,-964 # 800226e8 <mmr_list>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002ab4:	0000fc97          	auipc	s9,0xf
    80002ab8:	804c8c93          	addi	s9,s9,-2044 # 800112b8 <wait_lock>
    havekids = 0;
    80002abc:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    80002abe:	0000f497          	auipc	s1,0xf
    80002ac2:	c2a48493          	addi	s1,s1,-982 # 800116e8 <proc>
    80002ac6:	a0bd                	j	80002b34 <wait+0xc4>
          pid = np->pid;
    80002ac8:	3084a983          	lw	s3,776(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002acc:	000b8e63          	beqz	s7,80002ae8 <wait+0x78>
    80002ad0:	4691                	li	a3,4
    80002ad2:	30448613          	addi	a2,s1,772
    80002ad6:	85de                	mv	a1,s7
    80002ad8:	32893503          	ld	a0,808(s2)
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	c5e080e7          	jalr	-930(ra) # 8000173a <copyout>
    80002ae4:	02054563          	bltz	a0,80002b0e <wait+0x9e>
          freeproc(np);
    80002ae8:	8526                	mv	a0,s1
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	9f4080e7          	jalr	-1548(ra) # 800024de <freeproc>
          release(&np->lock);
    80002af2:	8552                	mv	a0,s4
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	1dc080e7          	jalr	476(ra) # 80000cd0 <release>
          release(&wait_lock);
    80002afc:	0000e517          	auipc	a0,0xe
    80002b00:	7bc50513          	addi	a0,a0,1980 # 800112b8 <wait_lock>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	1cc080e7          	jalr	460(ra) # 80000cd0 <release>
          return pid;
    80002b0c:	a0bd                	j	80002b7a <wait+0x10a>
            release(&np->lock);
    80002b0e:	8552                	mv	a0,s4
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	1c0080e7          	jalr	448(ra) # 80000cd0 <release>
            release(&wait_lock);
    80002b18:	0000e517          	auipc	a0,0xe
    80002b1c:	7a050513          	addi	a0,a0,1952 # 800112b8 <wait_lock>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	1b0080e7          	jalr	432(ra) # 80000cd0 <release>
            return -1;
    80002b28:	59fd                	li	s3,-1
    80002b2a:	a881                	j	80002b7a <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002b2c:	44048493          	addi	s1,s1,1088
    80002b30:	03348863          	beq	s1,s3,80002b60 <wait+0xf0>
      if(np->parent == p){
    80002b34:	3104b783          	ld	a5,784(s1)
    80002b38:	ff279ae3          	bne	a5,s2,80002b2c <wait+0xbc>
        acquire(&np->lock);
    80002b3c:	2d848a13          	addi	s4,s1,728
    80002b40:	8552                	mv	a0,s4
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	0da080e7          	jalr	218(ra) # 80000c1c <acquire>
        if(np->state == ZOMBIE){
    80002b4a:	2f04a783          	lw	a5,752(s1)
    80002b4e:	f7578de3          	beq	a5,s5,80002ac8 <wait+0x58>
        release(&np->lock);
    80002b52:	8552                	mv	a0,s4
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	17c080e7          	jalr	380(ra) # 80000cd0 <release>
        havekids = 1;
    80002b5c:	875a                	mv	a4,s6
    80002b5e:	b7f9                	j	80002b2c <wait+0xbc>
    if(!havekids || p->killed){
    80002b60:	c701                	beqz	a4,80002b68 <wait+0xf8>
    80002b62:	30092783          	lw	a5,768(s2)
    80002b66:	cb85                	beqz	a5,80002b96 <wait+0x126>
      release(&wait_lock);
    80002b68:	0000e517          	auipc	a0,0xe
    80002b6c:	75050513          	addi	a0,a0,1872 # 800112b8 <wait_lock>
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	160080e7          	jalr	352(ra) # 80000cd0 <release>
      return -1;
    80002b78:	59fd                	li	s3,-1
}
    80002b7a:	854e                	mv	a0,s3
    80002b7c:	60e6                	ld	ra,88(sp)
    80002b7e:	6446                	ld	s0,80(sp)
    80002b80:	64a6                	ld	s1,72(sp)
    80002b82:	6906                	ld	s2,64(sp)
    80002b84:	79e2                	ld	s3,56(sp)
    80002b86:	7a42                	ld	s4,48(sp)
    80002b88:	7aa2                	ld	s5,40(sp)
    80002b8a:	7b02                	ld	s6,32(sp)
    80002b8c:	6be2                	ld	s7,24(sp)
    80002b8e:	6c42                	ld	s8,16(sp)
    80002b90:	6ca2                	ld	s9,8(sp)
    80002b92:	6125                	addi	sp,sp,96
    80002b94:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b96:	85e6                	mv	a1,s9
    80002b98:	854a                	mv	a0,s2
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	35a080e7          	jalr	858(ra) # 80001ef4 <sleep>
    havekids = 0;
    80002ba2:	bf29                	j	80002abc <wait+0x4c>

0000000080002ba4 <alloc_mmr_listid>:

// find an unused entry in the mmr_list array
int
alloc_mmr_listid() {
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	1000                	addi	s0,sp,32
  acquire(&listid_lock);
    80002bae:	0000f517          	auipc	a0,0xf
    80002bb2:	b2250513          	addi	a0,a0,-1246 # 800116d0 <listid_lock>
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	066080e7          	jalr	102(ra) # 80000c1c <acquire>
  int listid = -1;
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    80002bbe:	00020797          	auipc	a5,0x20
    80002bc2:	b4278793          	addi	a5,a5,-1214 # 80022700 <mmr_list+0x18>
    80002bc6:	4481                	li	s1,0
    80002bc8:	28000693          	li	a3,640
    if (mmr_list[i].valid == 0) {
    80002bcc:	4398                	lw	a4,0(a5)
    80002bce:	cb01                	beqz	a4,80002bde <alloc_mmr_listid+0x3a>
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    80002bd0:	2485                	addiw	s1,s1,1
    80002bd2:	02078793          	addi	a5,a5,32
    80002bd6:	fed49be3          	bne	s1,a3,80002bcc <alloc_mmr_listid+0x28>
  int listid = -1;
    80002bda:	54fd                	li	s1,-1
    80002bdc:	a811                	j	80002bf0 <alloc_mmr_listid+0x4c>
      mmr_list[i].valid = 1;
    80002bde:	00549713          	slli	a4,s1,0x5
    80002be2:	00020797          	auipc	a5,0x20
    80002be6:	b0678793          	addi	a5,a5,-1274 # 800226e8 <mmr_list>
    80002bea:	97ba                	add	a5,a5,a4
    80002bec:	4705                	li	a4,1
    80002bee:	cf98                	sw	a4,24(a5)
      listid = i;
      break;
    }
  }
  release(&listid_lock);
    80002bf0:	0000f517          	auipc	a0,0xf
    80002bf4:	ae050513          	addi	a0,a0,-1312 # 800116d0 <listid_lock>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	0d8080e7          	jalr	216(ra) # 80000cd0 <release>
  return(listid);
    80002c00:	8526                	mv	a0,s1
    80002c02:	60e2                	ld	ra,24(sp)
    80002c04:	6442                	ld	s0,16(sp)
    80002c06:	64a2                	ld	s1,8(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret

0000000080002c0c <swtch>:
    80002c0c:	00153023          	sd	ra,0(a0)
    80002c10:	00253423          	sd	sp,8(a0)
    80002c14:	e900                	sd	s0,16(a0)
    80002c16:	ed04                	sd	s1,24(a0)
    80002c18:	03253023          	sd	s2,32(a0)
    80002c1c:	03353423          	sd	s3,40(a0)
    80002c20:	03453823          	sd	s4,48(a0)
    80002c24:	03553c23          	sd	s5,56(a0)
    80002c28:	05653023          	sd	s6,64(a0)
    80002c2c:	05753423          	sd	s7,72(a0)
    80002c30:	05853823          	sd	s8,80(a0)
    80002c34:	05953c23          	sd	s9,88(a0)
    80002c38:	07a53023          	sd	s10,96(a0)
    80002c3c:	07b53423          	sd	s11,104(a0)
    80002c40:	0005b083          	ld	ra,0(a1)
    80002c44:	0085b103          	ld	sp,8(a1)
    80002c48:	6980                	ld	s0,16(a1)
    80002c4a:	6d84                	ld	s1,24(a1)
    80002c4c:	0205b903          	ld	s2,32(a1)
    80002c50:	0285b983          	ld	s3,40(a1)
    80002c54:	0305ba03          	ld	s4,48(a1)
    80002c58:	0385ba83          	ld	s5,56(a1)
    80002c5c:	0405bb03          	ld	s6,64(a1)
    80002c60:	0485bb83          	ld	s7,72(a1)
    80002c64:	0505bc03          	ld	s8,80(a1)
    80002c68:	0585bc83          	ld	s9,88(a1)
    80002c6c:	0605bd03          	ld	s10,96(a1)
    80002c70:	0685bd83          	ld	s11,104(a1)
    80002c74:	8082                	ret

0000000080002c76 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c76:	1141                	addi	sp,sp,-16
    80002c78:	e406                	sd	ra,8(sp)
    80002c7a:	e022                	sd	s0,0(sp)
    80002c7c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c7e:	00005597          	auipc	a1,0x5
    80002c82:	65a58593          	addi	a1,a1,1626 # 800082d8 <states.0+0x30>
    80002c86:	00025517          	auipc	a0,0x25
    80002c8a:	a6250513          	addi	a0,a0,-1438 # 800276e8 <tickslock>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	efe080e7          	jalr	-258(ra) # 80000b8c <initlock>
}
    80002c96:	60a2                	ld	ra,8(sp)
    80002c98:	6402                	ld	s0,0(sp)
    80002c9a:	0141                	addi	sp,sp,16
    80002c9c:	8082                	ret

0000000080002c9e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c9e:	1141                	addi	sp,sp,-16
    80002ca0:	e422                	sd	s0,8(sp)
    80002ca2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca4:	00004797          	auipc	a5,0x4
    80002ca8:	b9c78793          	addi	a5,a5,-1124 # 80006840 <kernelvec>
    80002cac:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cb0:	6422                	ld	s0,8(sp)
    80002cb2:	0141                	addi	sp,sp,16
    80002cb4:	8082                	ret

0000000080002cb6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cb6:	1141                	addi	sp,sp,-16
    80002cb8:	e406                	sd	ra,8(sp)
    80002cba:	e022                	sd	s0,0(sp)
    80002cbc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	e36080e7          	jalr	-458(ra) # 80001af4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ccc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cd0:	00004697          	auipc	a3,0x4
    80002cd4:	33068693          	addi	a3,a3,816 # 80007000 <_trampoline>
    80002cd8:	00004717          	auipc	a4,0x4
    80002cdc:	32870713          	addi	a4,a4,808 # 80007000 <_trampoline>
    80002ce0:	8f15                	sub	a4,a4,a3
    80002ce2:	040007b7          	lui	a5,0x4000
    80002ce6:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ce8:	07b2                	slli	a5,a5,0xc
    80002cea:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cec:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cf0:	33053703          	ld	a4,816(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cf4:	18002673          	csrr	a2,satp
    80002cf8:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cfa:	33053603          	ld	a2,816(a0)
    80002cfe:	31853703          	ld	a4,792(a0)
    80002d02:	6585                	lui	a1,0x1
    80002d04:	972e                	add	a4,a4,a1
    80002d06:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d08:	33053703          	ld	a4,816(a0)
    80002d0c:	00000617          	auipc	a2,0x0
    80002d10:	13e60613          	addi	a2,a2,318 # 80002e4a <usertrap>
    80002d14:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d16:	33053703          	ld	a4,816(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d1a:	8612                	mv	a2,tp
    80002d1c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d22:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d26:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d2e:	33053703          	ld	a4,816(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d32:	6f18                	ld	a4,24(a4)
    80002d34:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d38:	32853583          	ld	a1,808(a0)
    80002d3c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d3e:	00004717          	auipc	a4,0x4
    80002d42:	35270713          	addi	a4,a4,850 # 80007090 <userret>
    80002d46:	8f15                	sub	a4,a4,a3
    80002d48:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d4a:	577d                	li	a4,-1
    80002d4c:	177e                	slli	a4,a4,0x3f
    80002d4e:	8dd9                	or	a1,a1,a4
    80002d50:	02000537          	lui	a0,0x2000
    80002d54:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002d56:	0536                	slli	a0,a0,0xd
    80002d58:	9782                	jalr	a5
}
    80002d5a:	60a2                	ld	ra,8(sp)
    80002d5c:	6402                	ld	s0,0(sp)
    80002d5e:	0141                	addi	sp,sp,16
    80002d60:	8082                	ret

0000000080002d62 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d62:	1101                	addi	sp,sp,-32
    80002d64:	ec06                	sd	ra,24(sp)
    80002d66:	e822                	sd	s0,16(sp)
    80002d68:	e426                	sd	s1,8(sp)
    80002d6a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d6c:	00025497          	auipc	s1,0x25
    80002d70:	97c48493          	addi	s1,s1,-1668 # 800276e8 <tickslock>
    80002d74:	8526                	mv	a0,s1
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	ea6080e7          	jalr	-346(ra) # 80000c1c <acquire>
  ticks++;
    80002d7e:	00006517          	auipc	a0,0x6
    80002d82:	2b250513          	addi	a0,a0,690 # 80009030 <ticks>
    80002d86:	411c                	lw	a5,0(a0)
    80002d88:	2785                	addiw	a5,a5,1
    80002d8a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	1d8080e7          	jalr	472(ra) # 80001f64 <wakeup>
  release(&tickslock);
    80002d94:	8526                	mv	a0,s1
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	f3a080e7          	jalr	-198(ra) # 80000cd0 <release>
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002da8:	1101                	addi	sp,sp,-32
    80002daa:	ec06                	sd	ra,24(sp)
    80002dac:	e822                	sd	s0,16(sp)
    80002dae:	e426                	sd	s1,8(sp)
    80002db0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002db6:	00074d63          	bltz	a4,80002dd0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002dba:	57fd                	li	a5,-1
    80002dbc:	17fe                	slli	a5,a5,0x3f
    80002dbe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dc0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dc2:	06f70363          	beq	a4,a5,80002e28 <devintr+0x80>
  }
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret
     (scause & 0xff) == 9){
    80002dd0:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002dd4:	46a5                	li	a3,9
    80002dd6:	fed792e3          	bne	a5,a3,80002dba <devintr+0x12>
    int irq = plic_claim();
    80002dda:	00004097          	auipc	ra,0x4
    80002dde:	b6e080e7          	jalr	-1170(ra) # 80006948 <plic_claim>
    80002de2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002de4:	47a9                	li	a5,10
    80002de6:	02f50763          	beq	a0,a5,80002e14 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002dea:	4785                	li	a5,1
    80002dec:	02f50963          	beq	a0,a5,80002e1e <devintr+0x76>
    return 1;
    80002df0:	4505                	li	a0,1
    } else if(irq){
    80002df2:	d8f1                	beqz	s1,80002dc6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002df4:	85a6                	mv	a1,s1
    80002df6:	00005517          	auipc	a0,0x5
    80002dfa:	4ea50513          	addi	a0,a0,1258 # 800082e0 <states.0+0x38>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	788080e7          	jalr	1928(ra) # 80000586 <printf>
      plic_complete(irq);
    80002e06:	8526                	mv	a0,s1
    80002e08:	00004097          	auipc	ra,0x4
    80002e0c:	b64080e7          	jalr	-1180(ra) # 8000696c <plic_complete>
    return 1;
    80002e10:	4505                	li	a0,1
    80002e12:	bf55                	j	80002dc6 <devintr+0x1e>
      uartintr();
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	b80080e7          	jalr	-1152(ra) # 80000994 <uartintr>
    80002e1c:	b7ed                	j	80002e06 <devintr+0x5e>
      virtio_disk_intr();
    80002e1e:	00004097          	auipc	ra,0x4
    80002e22:	fda080e7          	jalr	-38(ra) # 80006df8 <virtio_disk_intr>
    80002e26:	b7c5                	j	80002e06 <devintr+0x5e>
    if(cpuid() == 0){
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	ca0080e7          	jalr	-864(ra) # 80001ac8 <cpuid>
    80002e30:	c901                	beqz	a0,80002e40 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e32:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e36:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e38:	14479073          	csrw	sip,a5
    return 2;
    80002e3c:	4509                	li	a0,2
    80002e3e:	b761                	j	80002dc6 <devintr+0x1e>
      clockintr();
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	f22080e7          	jalr	-222(ra) # 80002d62 <clockintr>
    80002e48:	b7ed                	j	80002e32 <devintr+0x8a>

0000000080002e4a <usertrap>:
{
    80002e4a:	715d                	addi	sp,sp,-80
    80002e4c:	e486                	sd	ra,72(sp)
    80002e4e:	e0a2                	sd	s0,64(sp)
    80002e50:	fc26                	sd	s1,56(sp)
    80002e52:	f84a                	sd	s2,48(sp)
    80002e54:	f44e                	sd	s3,40(sp)
    80002e56:	f052                	sd	s4,32(sp)
    80002e58:	ec56                	sd	s5,24(sp)
    80002e5a:	e85a                	sd	s6,16(sp)
    80002e5c:	e45e                	sd	s7,8(sp)
    80002e5e:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e60:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e64:	1007f793          	andi	a5,a5,256
    80002e68:	ebbd                	bnez	a5,80002ede <usertrap+0x94>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e6a:	00004797          	auipc	a5,0x4
    80002e6e:	9d678793          	addi	a5,a5,-1578 # 80006840 <kernelvec>
    80002e72:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e76:	fffff097          	auipc	ra,0xfffff
    80002e7a:	c7e080e7          	jalr	-898(ra) # 80001af4 <myproc>
    80002e7e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e80:	33053783          	ld	a5,816(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e84:	14102773          	csrr	a4,sepc
    80002e88:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e8a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e8e:	47a1                	li	a5,8
    80002e90:	06f71563          	bne	a4,a5,80002efa <usertrap+0xb0>
    if(p->killed)
    80002e94:	30052783          	lw	a5,768(a0)
    80002e98:	ebb9                	bnez	a5,80002eee <usertrap+0xa4>
    p->trapframe->epc += 4;
    80002e9a:	3304b703          	ld	a4,816(s1)
    80002e9e:	6f1c                	ld	a5,24(a4)
    80002ea0:	0791                	addi	a5,a5,4
    80002ea2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ea8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eac:	10079073          	csrw	sstatus,a5
    syscall();
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	41a080e7          	jalr	1050(ra) # 800032ca <syscall>
  if(p->killed)
    80002eb8:	3004a783          	lw	a5,768(s1)
    80002ebc:	18079e63          	bnez	a5,80003058 <usertrap+0x20e>
  usertrapret();
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	df6080e7          	jalr	-522(ra) # 80002cb6 <usertrapret>
}
    80002ec8:	60a6                	ld	ra,72(sp)
    80002eca:	6406                	ld	s0,64(sp)
    80002ecc:	74e2                	ld	s1,56(sp)
    80002ece:	7942                	ld	s2,48(sp)
    80002ed0:	79a2                	ld	s3,40(sp)
    80002ed2:	7a02                	ld	s4,32(sp)
    80002ed4:	6ae2                	ld	s5,24(sp)
    80002ed6:	6b42                	ld	s6,16(sp)
    80002ed8:	6ba2                	ld	s7,8(sp)
    80002eda:	6161                	addi	sp,sp,80
    80002edc:	8082                	ret
    panic("usertrap: Not user mode");
    80002ede:	00005517          	auipc	a0,0x5
    80002ee2:	42250513          	addi	a0,a0,1058 # 80008300 <states.0+0x58>
    80002ee6:	ffffd097          	auipc	ra,0xffffd
    80002eea:	656080e7          	jalr	1622(ra) # 8000053c <panic>
      exit(-1);
    80002eee:	557d                	li	a0,-1
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	154080e7          	jalr	340(ra) # 80002044 <exit>
    80002ef8:	b74d                	j	80002e9a <usertrap+0x50>
  } else if((which_dev = devintr()) != 0){
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	eae080e7          	jalr	-338(ra) # 80002da8 <devintr>
    80002f02:	892a                	mv	s2,a0
    80002f04:	14051663          	bnez	a0,80003050 <usertrap+0x206>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f08:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15){
    80002f0c:	47b5                	li	a5,13
    80002f0e:	00f70763          	beq	a4,a5,80002f1c <usertrap+0xd2>
    80002f12:	14202773          	csrr	a4,scause
    80002f16:	47bd                	li	a5,15
    80002f18:	10f71063          	bne	a4,a5,80003018 <usertrap+0x1ce>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f1c:	143027f3          	csrr	a5,stval
    if(r_stval() >= p->sz){
    80002f20:	3204b703          	ld	a4,800(s1)
    80002f24:	06e7ee63          	bltu	a5,a4,80002fa0 <usertrap+0x156>
    80002f28:	8926                	mv	s2,s1
    80002f2a:	2d048a13          	addi	s4,s1,720
          if(r_scause() == 13){
    80002f2e:	4b35                	li	s6,13
          if(r_scause() == 15){
    80002f30:	4abd                	li	s5,15
              p->killed = 1;
    80002f32:	4b85                	li	s7,1
    80002f34:	a00d                	j	80002f56 <usertrap+0x10c>
            if((p->mmr[i].prot & PROT_READ) == 0){
    80002f36:	00c92783          	lw	a5,12(s2)
    80002f3a:	8b89                	andi	a5,a5,2
    80002f3c:	e3b1                	bnez	a5,80002f80 <usertrap+0x136>
              p->killed = 1;
    80002f3e:	3174a023          	sw	s7,768(s1)
              exit(-1);
    80002f42:	557d                	li	a0,-1
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	100080e7          	jalr	256(ra) # 80002044 <exit>
    80002f4c:	a815                	j	80002f80 <usertrap+0x136>
      for(int i=0; i<MAX_MMR; i++){
    80002f4e:	04890913          	addi	s2,s2,72
    80002f52:	05490763          	beq	s2,s4,80002fa0 <usertrap+0x156>
        if(p->mmr[i].valid && p->mmr[i].addr < r_stval() && p->mmr[i].addr+p->mmr[i].length > r_stval()){
    80002f56:	89ca                	mv	s3,s2
    80002f58:	01492783          	lw	a5,20(s2)
    80002f5c:	dbed                	beqz	a5,80002f4e <usertrap+0x104>
    80002f5e:	00093783          	ld	a5,0(s2)
    80002f62:	14302773          	csrr	a4,stval
    80002f66:	fee7f4e3          	bgeu	a5,a4,80002f4e <usertrap+0x104>
    80002f6a:	143026f3          	csrr	a3,stval
    80002f6e:	00892703          	lw	a4,8(s2)
    80002f72:	97ba                	add	a5,a5,a4
    80002f74:	fcf6fde3          	bgeu	a3,a5,80002f4e <usertrap+0x104>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f78:	142027f3          	csrr	a5,scause
          if(r_scause() == 13){
    80002f7c:	fb678de3          	beq	a5,s6,80002f36 <usertrap+0xec>
    80002f80:	142027f3          	csrr	a5,scause
          if(r_scause() == 15){
    80002f84:	fd5795e3          	bne	a5,s5,80002f4e <usertrap+0x104>
            if((p->mmr[i].prot & PROT_WRITE) == 0){
    80002f88:	00c9a783          	lw	a5,12(s3)
    80002f8c:	8b91                	andi	a5,a5,4
    80002f8e:	f3e1                	bnez	a5,80002f4e <usertrap+0x104>
              p->killed = 1;
    80002f90:	3174a023          	sw	s7,768(s1)
              exit(-1);
    80002f94:	557d                	li	a0,-1
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	0ae080e7          	jalr	174(ra) # 80002044 <exit>
    80002f9e:	bf45                	j	80002f4e <usertrap+0x104>
      void *physical_mem = kalloc();
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	b42080e7          	jalr	-1214(ra) # 80000ae2 <kalloc>
    80002fa8:	892a                	mv	s2,a0
      if(physical_mem){
    80002faa:	c531                	beqz	a0,80002ff6 <usertrap+0x1ac>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fac:	143025f3          	csrr	a1,stval
        if(mappages(p->pagetable, PGROUNDDOWN(r_stval()), PGSIZE, (uint64)physical_mem, (PTE_R | PTE_W | PTE_X | PTE_U)) < 0){ 
    80002fb0:	4779                	li	a4,30
    80002fb2:	86aa                	mv	a3,a0
    80002fb4:	6605                	lui	a2,0x1
    80002fb6:	77fd                	lui	a5,0xfffff
    80002fb8:	8dfd                	and	a1,a1,a5
    80002fba:	3284b503          	ld	a0,808(s1)
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	132080e7          	jalr	306(ra) # 800010f0 <mappages>
    80002fc6:	ee0559e3          	bgez	a0,80002eb8 <usertrap+0x6e>
          kfree(physical_mem);
    80002fca:	854a                	mv	a0,s2
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	a18080e7          	jalr	-1512(ra) # 800009e4 <kfree>
          printf("mappages didn't work\n");
    80002fd4:	00005517          	auipc	a0,0x5
    80002fd8:	34450513          	addi	a0,a0,836 # 80008318 <states.0+0x70>
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	5aa080e7          	jalr	1450(ra) # 80000586 <printf>
          p->killed = 1;
    80002fe4:	4785                	li	a5,1
    80002fe6:	30f4a023          	sw	a5,768(s1)
          exit(-1);
    80002fea:	557d                	li	a0,-1
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	058080e7          	jalr	88(ra) # 80002044 <exit>
    80002ff4:	b5d1                	j	80002eb8 <usertrap+0x6e>
      printf("usertrap(): Out of memory\n");
    80002ff6:	00005517          	auipc	a0,0x5
    80002ffa:	33a50513          	addi	a0,a0,826 # 80008330 <states.0+0x88>
    80002ffe:	ffffd097          	auipc	ra,0xffffd
    80003002:	588080e7          	jalr	1416(ra) # 80000586 <printf>
        p->killed = 1;
    80003006:	4785                	li	a5,1
    80003008:	30f4a023          	sw	a5,768(s1)
        exit(-1);
    8000300c:	557d                	li	a0,-1
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	036080e7          	jalr	54(ra) # 80002044 <exit>
    80003016:	b54d                	j	80002eb8 <usertrap+0x6e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003018:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000301c:	3084a603          	lw	a2,776(s1)
    80003020:	00005517          	auipc	a0,0x5
    80003024:	33050513          	addi	a0,a0,816 # 80008350 <states.0+0xa8>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	55e080e7          	jalr	1374(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003030:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003034:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003038:	00005517          	auipc	a0,0x5
    8000303c:	34850513          	addi	a0,a0,840 # 80008380 <states.0+0xd8>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	546080e7          	jalr	1350(ra) # 80000586 <printf>
    p->killed = 1;
    80003048:	4785                	li	a5,1
    8000304a:	30f4a023          	sw	a5,768(s1)
  if(p->killed)
    8000304e:	a031                	j	8000305a <usertrap+0x210>
    80003050:	3004a783          	lw	a5,768(s1)
    80003054:	cb81                	beqz	a5,80003064 <usertrap+0x21a>
    80003056:	a011                	j	8000305a <usertrap+0x210>
    80003058:	4901                	li	s2,0
    exit(-1);
    8000305a:	557d                	li	a0,-1
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	fe8080e7          	jalr	-24(ra) # 80002044 <exit>
  if(which_dev == 2)
    80003064:	4789                	li	a5,2
    80003066:	e4f91de3          	bne	s2,a5,80002ec0 <usertrap+0x76>
    yield();
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	e42080e7          	jalr	-446(ra) # 80001eac <yield>
    80003072:	b5b9                	j	80002ec0 <usertrap+0x76>

0000000080003074 <kerneltrap>:
{
    80003074:	7179                	addi	sp,sp,-48
    80003076:	f406                	sd	ra,40(sp)
    80003078:	f022                	sd	s0,32(sp)
    8000307a:	ec26                	sd	s1,24(sp)
    8000307c:	e84a                	sd	s2,16(sp)
    8000307e:	e44e                	sd	s3,8(sp)
    80003080:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003082:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003086:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000308a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000308e:	1004f793          	andi	a5,s1,256
    80003092:	cb85                	beqz	a5,800030c2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003094:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003098:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000309a:	ef85                	bnez	a5,800030d2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	d0c080e7          	jalr	-756(ra) # 80002da8 <devintr>
    800030a4:	cd1d                	beqz	a0,800030e2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030a6:	4789                	li	a5,2
    800030a8:	06f50a63          	beq	a0,a5,8000311c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030ac:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030b0:	10049073          	csrw	sstatus,s1
}
    800030b4:	70a2                	ld	ra,40(sp)
    800030b6:	7402                	ld	s0,32(sp)
    800030b8:	64e2                	ld	s1,24(sp)
    800030ba:	6942                	ld	s2,16(sp)
    800030bc:	69a2                	ld	s3,8(sp)
    800030be:	6145                	addi	sp,sp,48
    800030c0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030c2:	00005517          	auipc	a0,0x5
    800030c6:	2de50513          	addi	a0,a0,734 # 800083a0 <states.0+0xf8>
    800030ca:	ffffd097          	auipc	ra,0xffffd
    800030ce:	472080e7          	jalr	1138(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    800030d2:	00005517          	auipc	a0,0x5
    800030d6:	2f650513          	addi	a0,a0,758 # 800083c8 <states.0+0x120>
    800030da:	ffffd097          	auipc	ra,0xffffd
    800030de:	462080e7          	jalr	1122(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    800030e2:	85ce                	mv	a1,s3
    800030e4:	00005517          	auipc	a0,0x5
    800030e8:	30450513          	addi	a0,a0,772 # 800083e8 <states.0+0x140>
    800030ec:	ffffd097          	auipc	ra,0xffffd
    800030f0:	49a080e7          	jalr	1178(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030f4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030f8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030fc:	00005517          	auipc	a0,0x5
    80003100:	2fc50513          	addi	a0,a0,764 # 800083f8 <states.0+0x150>
    80003104:	ffffd097          	auipc	ra,0xffffd
    80003108:	482080e7          	jalr	1154(ra) # 80000586 <printf>
    panic("kerneltrap");
    8000310c:	00005517          	auipc	a0,0x5
    80003110:	30450513          	addi	a0,a0,772 # 80008410 <states.0+0x168>
    80003114:	ffffd097          	auipc	ra,0xffffd
    80003118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	9d8080e7          	jalr	-1576(ra) # 80001af4 <myproc>
    80003124:	d541                	beqz	a0,800030ac <kerneltrap+0x38>
    80003126:	fffff097          	auipc	ra,0xfffff
    8000312a:	9ce080e7          	jalr	-1586(ra) # 80001af4 <myproc>
    8000312e:	2f052703          	lw	a4,752(a0)
    80003132:	4791                	li	a5,4
    80003134:	f6f71ce3          	bne	a4,a5,800030ac <kerneltrap+0x38>
    yield();
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	d74080e7          	jalr	-652(ra) # 80001eac <yield>
    80003140:	b7b5                	j	800030ac <kerneltrap+0x38>

0000000080003142 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	9a6080e7          	jalr	-1626(ra) # 80001af4 <myproc>
  switch (n) {
    80003156:	4795                	li	a5,5
    80003158:	0497e763          	bltu	a5,s1,800031a6 <argraw+0x64>
    8000315c:	048a                	slli	s1,s1,0x2
    8000315e:	00005717          	auipc	a4,0x5
    80003162:	2ea70713          	addi	a4,a4,746 # 80008448 <states.0+0x1a0>
    80003166:	94ba                	add	s1,s1,a4
    80003168:	409c                	lw	a5,0(s1)
    8000316a:	97ba                	add	a5,a5,a4
    8000316c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000316e:	33053783          	ld	a5,816(a0)
    80003172:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret
    return p->trapframe->a1;
    8000317e:	33053783          	ld	a5,816(a0)
    80003182:	7fa8                	ld	a0,120(a5)
    80003184:	bfc5                	j	80003174 <argraw+0x32>
    return p->trapframe->a2;
    80003186:	33053783          	ld	a5,816(a0)
    8000318a:	63c8                	ld	a0,128(a5)
    8000318c:	b7e5                	j	80003174 <argraw+0x32>
    return p->trapframe->a3;
    8000318e:	33053783          	ld	a5,816(a0)
    80003192:	67c8                	ld	a0,136(a5)
    80003194:	b7c5                	j	80003174 <argraw+0x32>
    return p->trapframe->a4;
    80003196:	33053783          	ld	a5,816(a0)
    8000319a:	6bc8                	ld	a0,144(a5)
    8000319c:	bfe1                	j	80003174 <argraw+0x32>
    return p->trapframe->a5;
    8000319e:	33053783          	ld	a5,816(a0)
    800031a2:	6fc8                	ld	a0,152(a5)
    800031a4:	bfc1                	j	80003174 <argraw+0x32>
  panic("argraw");
    800031a6:	00005517          	auipc	a0,0x5
    800031aa:	27a50513          	addi	a0,a0,634 # 80008420 <states.0+0x178>
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	38e080e7          	jalr	910(ra) # 8000053c <panic>

00000000800031b6 <fetchaddr>:
{
    800031b6:	1101                	addi	sp,sp,-32
    800031b8:	ec06                	sd	ra,24(sp)
    800031ba:	e822                	sd	s0,16(sp)
    800031bc:	e426                	sd	s1,8(sp)
    800031be:	e04a                	sd	s2,0(sp)
    800031c0:	1000                	addi	s0,sp,32
    800031c2:	84aa                	mv	s1,a0
    800031c4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031c6:	fffff097          	auipc	ra,0xfffff
    800031ca:	92e080e7          	jalr	-1746(ra) # 80001af4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031ce:	32053783          	ld	a5,800(a0)
    800031d2:	02f4f963          	bgeu	s1,a5,80003204 <fetchaddr+0x4e>
    800031d6:	00848713          	addi	a4,s1,8
    800031da:	02e7e763          	bltu	a5,a4,80003208 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031de:	46a1                	li	a3,8
    800031e0:	8626                	mv	a2,s1
    800031e2:	85ca                	mv	a1,s2
    800031e4:	32853503          	ld	a0,808(a0)
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	5de080e7          	jalr	1502(ra) # 800017c6 <copyin>
    800031f0:	00a03533          	snez	a0,a0
    800031f4:	40a00533          	neg	a0,a0
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6902                	ld	s2,0(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret
    return -1;
    80003204:	557d                	li	a0,-1
    80003206:	bfcd                	j	800031f8 <fetchaddr+0x42>
    80003208:	557d                	li	a0,-1
    8000320a:	b7fd                	j	800031f8 <fetchaddr+0x42>

000000008000320c <fetchstr>:
{
    8000320c:	7179                	addi	sp,sp,-48
    8000320e:	f406                	sd	ra,40(sp)
    80003210:	f022                	sd	s0,32(sp)
    80003212:	ec26                	sd	s1,24(sp)
    80003214:	e84a                	sd	s2,16(sp)
    80003216:	e44e                	sd	s3,8(sp)
    80003218:	1800                	addi	s0,sp,48
    8000321a:	892a                	mv	s2,a0
    8000321c:	84ae                	mv	s1,a1
    8000321e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	8d4080e7          	jalr	-1836(ra) # 80001af4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003228:	86ce                	mv	a3,s3
    8000322a:	864a                	mv	a2,s2
    8000322c:	85a6                	mv	a1,s1
    8000322e:	32853503          	ld	a0,808(a0)
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	622080e7          	jalr	1570(ra) # 80001854 <copyinstr>
  if(err < 0)
    8000323a:	00054763          	bltz	a0,80003248 <fetchstr+0x3c>
  return strlen(buf);
    8000323e:	8526                	mv	a0,s1
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	c54080e7          	jalr	-940(ra) # 80000e94 <strlen>
}
    80003248:	70a2                	ld	ra,40(sp)
    8000324a:	7402                	ld	s0,32(sp)
    8000324c:	64e2                	ld	s1,24(sp)
    8000324e:	6942                	ld	s2,16(sp)
    80003250:	69a2                	ld	s3,8(sp)
    80003252:	6145                	addi	sp,sp,48
    80003254:	8082                	ret

0000000080003256 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003256:	1101                	addi	sp,sp,-32
    80003258:	ec06                	sd	ra,24(sp)
    8000325a:	e822                	sd	s0,16(sp)
    8000325c:	e426                	sd	s1,8(sp)
    8000325e:	1000                	addi	s0,sp,32
    80003260:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003262:	00000097          	auipc	ra,0x0
    80003266:	ee0080e7          	jalr	-288(ra) # 80003142 <argraw>
    8000326a:	c088                	sw	a0,0(s1)
  return 0;
}
    8000326c:	4501                	li	a0,0
    8000326e:	60e2                	ld	ra,24(sp)
    80003270:	6442                	ld	s0,16(sp)
    80003272:	64a2                	ld	s1,8(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret

0000000080003278 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	e426                	sd	s1,8(sp)
    80003280:	1000                	addi	s0,sp,32
    80003282:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003284:	00000097          	auipc	ra,0x0
    80003288:	ebe080e7          	jalr	-322(ra) # 80003142 <argraw>
    8000328c:	e088                	sd	a0,0(s1)
  return 0;
}
    8000328e:	4501                	li	a0,0
    80003290:	60e2                	ld	ra,24(sp)
    80003292:	6442                	ld	s0,16(sp)
    80003294:	64a2                	ld	s1,8(sp)
    80003296:	6105                	addi	sp,sp,32
    80003298:	8082                	ret

000000008000329a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	e426                	sd	s1,8(sp)
    800032a2:	e04a                	sd	s2,0(sp)
    800032a4:	1000                	addi	s0,sp,32
    800032a6:	84ae                	mv	s1,a1
    800032a8:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	e98080e7          	jalr	-360(ra) # 80003142 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032b2:	864a                	mv	a2,s2
    800032b4:	85a6                	mv	a1,s1
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	f56080e7          	jalr	-170(ra) # 8000320c <fetchstr>
}
    800032be:	60e2                	ld	ra,24(sp)
    800032c0:	6442                	ld	s0,16(sp)
    800032c2:	64a2                	ld	s1,8(sp)
    800032c4:	6902                	ld	s2,0(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret

00000000800032ca <syscall>:
[SYS_sem_post] sys_sem_post,
};

void
syscall(void)
{
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	e426                	sd	s1,8(sp)
    800032d2:	e04a                	sd	s2,0(sp)
    800032d4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032d6:	fffff097          	auipc	ra,0xfffff
    800032da:	81e080e7          	jalr	-2018(ra) # 80001af4 <myproc>
    800032de:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032e0:	33053903          	ld	s2,816(a0)
    800032e4:	0a893783          	ld	a5,168(s2)
    800032e8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032ec:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffc8367>
    800032ee:	4771                	li	a4,28
    800032f0:	00f76f63          	bltu	a4,a5,8000330e <syscall+0x44>
    800032f4:	00369713          	slli	a4,a3,0x3
    800032f8:	00005797          	auipc	a5,0x5
    800032fc:	16878793          	addi	a5,a5,360 # 80008460 <syscalls>
    80003300:	97ba                	add	a5,a5,a4
    80003302:	639c                	ld	a5,0(a5)
    80003304:	c789                	beqz	a5,8000330e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003306:	9782                	jalr	a5
    80003308:	06a93823          	sd	a0,112(s2)
    8000330c:	a00d                	j	8000332e <syscall+0x64>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000330e:	43048613          	addi	a2,s1,1072
    80003312:	3084a583          	lw	a1,776(s1)
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	11250513          	addi	a0,a0,274 # 80008428 <states.0+0x180>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	268080e7          	jalr	616(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003326:	3304b783          	ld	a5,816(s1)
    8000332a:	577d                	li	a4,-1
    8000332c:	fbb8                	sd	a4,112(a5)
  }
}
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	64a2                	ld	s1,8(sp)
    80003334:	6902                	ld	s2,0(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret

000000008000333a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000333a:	1101                	addi	sp,sp,-32
    8000333c:	ec06                	sd	ra,24(sp)
    8000333e:	e822                	sd	s0,16(sp)
    80003340:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003342:	fec40593          	addi	a1,s0,-20
    80003346:	4501                	li	a0,0
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	f0e080e7          	jalr	-242(ra) # 80003256 <argint>
    return -1;
    80003350:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003352:	00054963          	bltz	a0,80003364 <sys_exit+0x2a>
  exit(n);
    80003356:	fec42503          	lw	a0,-20(s0)
    8000335a:	fffff097          	auipc	ra,0xfffff
    8000335e:	cea080e7          	jalr	-790(ra) # 80002044 <exit>
  return 0;  // not reached
    80003362:	4781                	li	a5,0
}
    80003364:	853e                	mv	a0,a5
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	6105                	addi	sp,sp,32
    8000336c:	8082                	ret

000000008000336e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000336e:	1141                	addi	sp,sp,-16
    80003370:	e406                	sd	ra,8(sp)
    80003372:	e022                	sd	s0,0(sp)
    80003374:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	77e080e7          	jalr	1918(ra) # 80001af4 <myproc>
}
    8000337e:	30852503          	lw	a0,776(a0)
    80003382:	60a2                	ld	ra,8(sp)
    80003384:	6402                	ld	s0,0(sp)
    80003386:	0141                	addi	sp,sp,16
    80003388:	8082                	ret

000000008000338a <sys_fork>:

uint64
sys_fork(void)
{
    8000338a:	1141                	addi	sp,sp,-16
    8000338c:	e406                	sd	ra,8(sp)
    8000338e:	e022                	sd	s0,0(sp)
    80003390:	0800                	addi	s0,sp,16
  return fork();
    80003392:	fffff097          	auipc	ra,0xfffff
    80003396:	414080e7          	jalr	1044(ra) # 800027a6 <fork>
}
    8000339a:	60a2                	ld	ra,8(sp)
    8000339c:	6402                	ld	s0,0(sp)
    8000339e:	0141                	addi	sp,sp,16
    800033a0:	8082                	ret

00000000800033a2 <sys_wait>:

uint64
sys_wait(void)
{
    800033a2:	1101                	addi	sp,sp,-32
    800033a4:	ec06                	sd	ra,24(sp)
    800033a6:	e822                	sd	s0,16(sp)
    800033a8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033aa:	fe840593          	addi	a1,s0,-24
    800033ae:	4501                	li	a0,0
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	ec8080e7          	jalr	-312(ra) # 80003278 <argaddr>
    800033b8:	87aa                	mv	a5,a0
    return -1;
    800033ba:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033bc:	0007c863          	bltz	a5,800033cc <sys_wait+0x2a>
  return wait(p);
    800033c0:	fe843503          	ld	a0,-24(s0)
    800033c4:	fffff097          	auipc	ra,0xfffff
    800033c8:	6ac080e7          	jalr	1708(ra) # 80002a70 <wait>
}
    800033cc:	60e2                	ld	ra,24(sp)
    800033ce:	6442                	ld	s0,16(sp)
    800033d0:	6105                	addi	sp,sp,32
    800033d2:	8082                	ret

00000000800033d4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033d4:	7139                	addi	sp,sp,-64
    800033d6:	fc06                	sd	ra,56(sp)
    800033d8:	f822                	sd	s0,48(sp)
    800033da:	f426                	sd	s1,40(sp)
    800033dc:	f04a                	sd	s2,32(sp)
    800033de:	ec4e                	sd	s3,24(sp)
    800033e0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033e2:	fcc40593          	addi	a1,s0,-52
    800033e6:	4501                	li	a0,0
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	e6e080e7          	jalr	-402(ra) # 80003256 <argint>
    return -1;
    800033f0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033f2:	06054663          	bltz	a0,8000345e <sys_sleep+0x8a>
  acquire(&tickslock);
    800033f6:	00024517          	auipc	a0,0x24
    800033fa:	2f250513          	addi	a0,a0,754 # 800276e8 <tickslock>
    800033fe:	ffffe097          	auipc	ra,0xffffe
    80003402:	81e080e7          	jalr	-2018(ra) # 80000c1c <acquire>
  ticks0 = ticks;
    80003406:	00006917          	auipc	s2,0x6
    8000340a:	c2a92903          	lw	s2,-982(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000340e:	fcc42783          	lw	a5,-52(s0)
    80003412:	cf8d                	beqz	a5,8000344c <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003414:	00024997          	auipc	s3,0x24
    80003418:	2d498993          	addi	s3,s3,724 # 800276e8 <tickslock>
    8000341c:	00006497          	auipc	s1,0x6
    80003420:	c1448493          	addi	s1,s1,-1004 # 80009030 <ticks>
    if(myproc()->killed){
    80003424:	ffffe097          	auipc	ra,0xffffe
    80003428:	6d0080e7          	jalr	1744(ra) # 80001af4 <myproc>
    8000342c:	30052783          	lw	a5,768(a0)
    80003430:	ef9d                	bnez	a5,8000346e <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    80003432:	85ce                	mv	a1,s3
    80003434:	8526                	mv	a0,s1
    80003436:	fffff097          	auipc	ra,0xfffff
    8000343a:	abe080e7          	jalr	-1346(ra) # 80001ef4 <sleep>
  while(ticks - ticks0 < n){
    8000343e:	409c                	lw	a5,0(s1)
    80003440:	412787bb          	subw	a5,a5,s2
    80003444:	fcc42703          	lw	a4,-52(s0)
    80003448:	fce7eee3          	bltu	a5,a4,80003424 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000344c:	00024517          	auipc	a0,0x24
    80003450:	29c50513          	addi	a0,a0,668 # 800276e8 <tickslock>
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	87c080e7          	jalr	-1924(ra) # 80000cd0 <release>
  return 0;
    8000345c:	4781                	li	a5,0
}
    8000345e:	853e                	mv	a0,a5
    80003460:	70e2                	ld	ra,56(sp)
    80003462:	7442                	ld	s0,48(sp)
    80003464:	74a2                	ld	s1,40(sp)
    80003466:	7902                	ld	s2,32(sp)
    80003468:	69e2                	ld	s3,24(sp)
    8000346a:	6121                	addi	sp,sp,64
    8000346c:	8082                	ret
      release(&tickslock);
    8000346e:	00024517          	auipc	a0,0x24
    80003472:	27a50513          	addi	a0,a0,634 # 800276e8 <tickslock>
    80003476:	ffffe097          	auipc	ra,0xffffe
    8000347a:	85a080e7          	jalr	-1958(ra) # 80000cd0 <release>
      return -1;
    8000347e:	57fd                	li	a5,-1
    80003480:	bff9                	j	8000345e <sys_sleep+0x8a>

0000000080003482 <sys_kill>:

uint64
sys_kill(void)
{
    80003482:	1101                	addi	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000348a:	fec40593          	addi	a1,s0,-20
    8000348e:	4501                	li	a0,0
    80003490:	00000097          	auipc	ra,0x0
    80003494:	dc6080e7          	jalr	-570(ra) # 80003256 <argint>
    80003498:	87aa                	mv	a5,a0
    return -1;
    8000349a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000349c:	0007c863          	bltz	a5,800034ac <sys_kill+0x2a>
  return kill(pid);
    800034a0:	fec42503          	lw	a0,-20(s0)
    800034a4:	fffff097          	auipc	ra,0xfffff
    800034a8:	c78080e7          	jalr	-904(ra) # 8000211c <kill>
}
    800034ac:	60e2                	ld	ra,24(sp)
    800034ae:	6442                	ld	s0,16(sp)
    800034b0:	6105                	addi	sp,sp,32
    800034b2:	8082                	ret

00000000800034b4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034be:	00024517          	auipc	a0,0x24
    800034c2:	22a50513          	addi	a0,a0,554 # 800276e8 <tickslock>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	756080e7          	jalr	1878(ra) # 80000c1c <acquire>
  xticks = ticks;
    800034ce:	00006497          	auipc	s1,0x6
    800034d2:	b624a483          	lw	s1,-1182(s1) # 80009030 <ticks>
  release(&tickslock);
    800034d6:	00024517          	auipc	a0,0x24
    800034da:	21250513          	addi	a0,a0,530 # 800276e8 <tickslock>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7f2080e7          	jalr	2034(ra) # 80000cd0 <release>
  return xticks;
}
    800034e6:	02049513          	slli	a0,s1,0x20
    800034ea:	9101                	srli	a0,a0,0x20
    800034ec:	60e2                	ld	ra,24(sp)
    800034ee:	6442                	ld	s0,16(sp)
    800034f0:	64a2                	ld	s1,8(sp)
    800034f2:	6105                	addi	sp,sp,32
    800034f4:	8082                	ret

00000000800034f6 <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    800034f6:	1101                	addi	sp,sp,-32
    800034f8:	ec06                	sd	ra,24(sp)
    800034fa:	e822                	sd	s0,16(sp)
    800034fc:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    800034fe:	fe840593          	addi	a1,s0,-24
    80003502:	4501                	li	a0,0
    80003504:	00000097          	auipc	ra,0x0
    80003508:	d74080e7          	jalr	-652(ra) # 80003278 <argaddr>
    8000350c:	87aa                	mv	a5,a0
    return -1;
    8000350e:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80003510:	0007c863          	bltz	a5,80003520 <sys_getprocs+0x2a>
  return(procinfo(addr));
    80003514:	fe843503          	ld	a0,-24(s0)
    80003518:	fffff097          	auipc	ra,0xfffff
    8000351c:	de6080e7          	jalr	-538(ra) # 800022fe <procinfo>
}
    80003520:	60e2                	ld	ra,24(sp)
    80003522:	6442                	ld	s0,16(sp)
    80003524:	6105                	addi	sp,sp,32
    80003526:	8082                	ret

0000000080003528 <sys_freepmem>:

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
    80003528:	1141                	addi	sp,sp,-16
    8000352a:	e406                	sd	ra,8(sp)
    8000352c:	e022                	sd	s0,0(sp)
    8000352e:	0800                	addi	s0,sp,16
  int res = freepmem();
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	612080e7          	jalr	1554(ra) # 80000b42 <freepmem>
  return res;
}
    80003538:	2501                	sext.w	a0,a0
    8000353a:	60a2                	ld	ra,8(sp)
    8000353c:	6402                	ld	s0,0(sp)
    8000353e:	0141                	addi	sp,sp,16
    80003540:	8082                	ret

0000000080003542 <sys_sbrk>:

// HW 4 - Task 2
// system call to allocate VIRTUAL memory on the disk
uint64
sys_sbrk(void){
    80003542:	7179                	addi	sp,sp,-48
    80003544:	f406                	sd	ra,40(sp)
    80003546:	f022                	sd	s0,32(sp)
    80003548:	ec26                	sd	s1,24(sp)
    8000354a:	e84a                	sd	s2,16(sp)
    8000354c:	1800                	addi	s0,sp,48
  int new_size;
  int increment;

  // Retrieve the first system call argument, which is the number 
  // of bytes to increase the heap by, and store it in 'increment'
  if(argint(0, &increment) < 0){
    8000354e:	fdc40593          	addi	a1,s0,-36
    80003552:	4501                	li	a0,0
    80003554:	00000097          	auipc	ra,0x0
    80003558:	d02080e7          	jalr	-766(ra) # 80003256 <argint>
    8000355c:	87aa                	mv	a5,a0
    return -1;
    8000355e:	557d                	li	a0,-1
  if(argint(0, &increment) < 0){
    80003560:	0207c363          	bltz	a5,80003586 <sys_sbrk+0x44>
  }

  // Get the current size of the process's heap from its process structure.]
  curr_size = myproc()->sz;
    80003564:	ffffe097          	auipc	ra,0xffffe
    80003568:	590080e7          	jalr	1424(ra) # 80001af4 <myproc>
    8000356c:	32052483          	lw	s1,800(a0)

  // Calculate the new size of the heap by adding 'increment' to the current size
  new_size = curr_size + increment;
    80003570:	fdc42903          	lw	s2,-36(s0)
    80003574:	0099093b          	addw	s2,s2,s1

  // Check if the new size is below a memory safety threshold ('TRAPFRAME')
  // This is to ensure the heap does not overlap with the trap frame
  if(new_size < TRAPFRAME){
    // If the new size is valid, update the process's heap size to -> new_size
    myproc()->sz = new_size;
    80003578:	ffffe097          	auipc	ra,0xffffe
    8000357c:	57c080e7          	jalr	1404(ra) # 80001af4 <myproc>
    80003580:	33253023          	sd	s2,800(a0)
    
    // Return the old heap end address before the increment
    return curr_size;
    80003584:	8526                	mv	a0,s1
  }

  // If the new size is not valid or exceeds the memory safety threshold
  return -1;
}
    80003586:	70a2                	ld	ra,40(sp)
    80003588:	7402                	ld	s0,32(sp)
    8000358a:	64e2                	ld	s1,24(sp)
    8000358c:	6942                	ld	s2,16(sp)
    8000358e:	6145                	addi	sp,sp,48
    80003590:	8082                	ret

0000000080003592 <sys_sem_init>:
//     return -1;
//   return addr;
// }

// HW6 - TASK 3
int sys_sem_init(void) {
    80003592:	7179                	addi	sp,sp,-48
    80003594:	f406                	sd	ra,40(sp)
    80003596:	f022                	sd	s0,32(sp)
    80003598:	1800                	addi	s0,sp,48
    uint64 s;
    int index, value, pshared;

    // Retrieve semaphore pointer, pshared flag, and initial value from syscall arguments
    // Return error if any syscall argument retrieval fails or pshared is zero
    if (argaddr(0, &s) < 0 || argint(1, &pshared) < 0 || argint(2, &value) < 0 || pshared == 0) {
    8000359a:	fe840593          	addi	a1,s0,-24
    8000359e:	4501                	li	a0,0
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	cd8080e7          	jalr	-808(ra) # 80003278 <argaddr>
    800035a8:	06054e63          	bltz	a0,80003624 <sys_sem_init+0x92>
    800035ac:	fdc40593          	addi	a1,s0,-36
    800035b0:	4505                	li	a0,1
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	ca4080e7          	jalr	-860(ra) # 80003256 <argint>
    800035ba:	06054763          	bltz	a0,80003628 <sys_sem_init+0x96>
    800035be:	fe040593          	addi	a1,s0,-32
    800035c2:	4509                	li	a0,2
    800035c4:	00000097          	auipc	ra,0x0
    800035c8:	c92080e7          	jalr	-878(ra) # 80003256 <argint>
    800035cc:	06054063          	bltz	a0,8000362c <sys_sem_init+0x9a>
    800035d0:	fdc42783          	lw	a5,-36(s0)
    800035d4:	cfb1                	beqz	a5,80003630 <sys_sem_init+0x9e>
        return -1;
    }

    // Allocate a new semaphore and check for allocation success
    index = semalloc();
    800035d6:	00004097          	auipc	ra,0x4
    800035da:	94c080e7          	jalr	-1716(ra) # 80006f22 <semalloc>
    800035de:	fea42223          	sw	a0,-28(s0)
    if (index < 0) {
    800035e2:	04054963          	bltz	a0,80003634 <sys_sem_init+0xa2>
        return -1;
    }

    // Set the semaphore's initial value
    semtable.sem[index].count = value;
    800035e6:	0505                	addi	a0,a0,1
    800035e8:	0516                	slli	a0,a0,0x5
    800035ea:	00033797          	auipc	a5,0x33
    800035ee:	a1678793          	addi	a5,a5,-1514 # 80036000 <semtable>
    800035f2:	97aa                	add	a5,a5,a0
    800035f4:	fe042703          	lw	a4,-32(s0)
    800035f8:	cb98                	sw	a4,16(a5)

    // Copy the semaphore index back to the user space and return success or error
    return copyout(myproc()->pagetable, s, (char*)&index, sizeof(index)) < 0 ? -1 : 0;
    800035fa:	ffffe097          	auipc	ra,0xffffe
    800035fe:	4fa080e7          	jalr	1274(ra) # 80001af4 <myproc>
    80003602:	4691                	li	a3,4
    80003604:	fe440613          	addi	a2,s0,-28
    80003608:	fe843583          	ld	a1,-24(s0)
    8000360c:	32853503          	ld	a0,808(a0)
    80003610:	ffffe097          	auipc	ra,0xffffe
    80003614:	12a080e7          	jalr	298(ra) # 8000173a <copyout>
    80003618:	41f5551b          	sraiw	a0,a0,0x1f
}
    8000361c:	70a2                	ld	ra,40(sp)
    8000361e:	7402                	ld	s0,32(sp)
    80003620:	6145                	addi	sp,sp,48
    80003622:	8082                	ret
        return -1;
    80003624:	557d                	li	a0,-1
    80003626:	bfdd                	j	8000361c <sys_sem_init+0x8a>
    80003628:	557d                	li	a0,-1
    8000362a:	bfcd                	j	8000361c <sys_sem_init+0x8a>
    8000362c:	557d                	li	a0,-1
    8000362e:	b7fd                	j	8000361c <sys_sem_init+0x8a>
    80003630:	557d                	li	a0,-1
    80003632:	b7ed                	j	8000361c <sys_sem_init+0x8a>
        return -1;
    80003634:	557d                	li	a0,-1
    80003636:	b7dd                	j	8000361c <sys_sem_init+0x8a>

0000000080003638 <sys_sem_destroy>:

int sys_sem_destroy(void) {
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	1000                	addi	s0,sp,32
    uint64 s;
    int addr;

    // Retrieve semaphore pointer from syscall argument
    if (argaddr(0, &s) < 0) {
    80003640:	fe840593          	addi	a1,s0,-24
    80003644:	4501                	li	a0,0
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	c32080e7          	jalr	-974(ra) # 80003278 <argaddr>
    8000364e:	04054e63          	bltz	a0,800036aa <sys_sem_destroy+0x72>
        return -1;
    }

    // Copy semaphore address from user space; return error if copyin fails
    if (copyin(myproc()->pagetable, (char*)&addr, s, sizeof(int)) < 0) {
    80003652:	ffffe097          	auipc	ra,0xffffe
    80003656:	4a2080e7          	jalr	1186(ra) # 80001af4 <myproc>
    8000365a:	4691                	li	a3,4
    8000365c:	fe843603          	ld	a2,-24(s0)
    80003660:	fe440593          	addi	a1,s0,-28
    80003664:	32853503          	ld	a0,808(a0)
    80003668:	ffffe097          	auipc	ra,0xffffe
    8000366c:	15e080e7          	jalr	350(ra) # 800017c6 <copyin>
    80003670:	02054f63          	bltz	a0,800036ae <sys_sem_destroy+0x76>
        return -1;
    }

    // Acquire lock, deallocate the semaphore, and release lock
    acquire(&semtable.lock);
    80003674:	00033517          	auipc	a0,0x33
    80003678:	98c50513          	addi	a0,a0,-1652 # 80036000 <semtable>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	5a0080e7          	jalr	1440(ra) # 80000c1c <acquire>
    semdealloc(addr);
    80003684:	fe442503          	lw	a0,-28(s0)
    80003688:	00004097          	auipc	ra,0x4
    8000368c:	90c080e7          	jalr	-1780(ra) # 80006f94 <semdealloc>
    release(&semtable.lock);
    80003690:	00033517          	auipc	a0,0x33
    80003694:	97050513          	addi	a0,a0,-1680 # 80036000 <semtable>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	638080e7          	jalr	1592(ra) # 80000cd0 <release>

    return 0;
    800036a0:	4501                	li	a0,0
}
    800036a2:	60e2                	ld	ra,24(sp)
    800036a4:	6442                	ld	s0,16(sp)
    800036a6:	6105                	addi	sp,sp,32
    800036a8:	8082                	ret
        return -1;
    800036aa:	557d                	li	a0,-1
    800036ac:	bfdd                	j	800036a2 <sys_sem_destroy+0x6a>
        return -1;
    800036ae:	557d                	li	a0,-1
    800036b0:	bfcd                	j	800036a2 <sys_sem_destroy+0x6a>

00000000800036b2 <sys_sem_wait>:

int sys_sem_wait(void) {
    800036b2:	7179                	addi	sp,sp,-48
    800036b4:	f406                	sd	ra,40(sp)
    800036b6:	f022                	sd	s0,32(sp)
    800036b8:	ec26                	sd	s1,24(sp)
    800036ba:	1800                	addi	s0,sp,48
    uint64 s;
    int addr;

    // Retrieve semaphore pointer from syscall argument and copy address from user space
    if (argaddr(0, &s) < 0 || copyin(myproc()->pagetable, (char*)&addr, s, sizeof(int)) < 0) {
    800036bc:	fd840593          	addi	a1,s0,-40
    800036c0:	4501                	li	a0,0
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	bb6080e7          	jalr	-1098(ra) # 80003278 <argaddr>
    800036ca:	0a054463          	bltz	a0,80003772 <sys_sem_wait+0xc0>
    800036ce:	ffffe097          	auipc	ra,0xffffe
    800036d2:	426080e7          	jalr	1062(ra) # 80001af4 <myproc>
    800036d6:	4691                	li	a3,4
    800036d8:	fd843603          	ld	a2,-40(s0)
    800036dc:	fd440593          	addi	a1,s0,-44
    800036e0:	32853503          	ld	a0,808(a0)
    800036e4:	ffffe097          	auipc	ra,0xffffe
    800036e8:	0e2080e7          	jalr	226(ra) # 800017c6 <copyin>
    800036ec:	08054563          	bltz	a0,80003776 <sys_sem_wait+0xc4>
        return -1;
    }

    // Acquire lock and wait if semaphore count is zero, then decrement count
    acquire(&semtable.sem[addr].lock);
    800036f0:	fd442503          	lw	a0,-44(s0)
    800036f4:	0516                	slli	a0,a0,0x5
    800036f6:	0561                	addi	a0,a0,24
    800036f8:	00033497          	auipc	s1,0x33
    800036fc:	90848493          	addi	s1,s1,-1784 # 80036000 <semtable>
    80003700:	9526                	add	a0,a0,s1
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	51a080e7          	jalr	1306(ra) # 80000c1c <acquire>
    while (semtable.sem[addr].count == 0) {
    8000370a:	fd442783          	lw	a5,-44(s0)
    8000370e:	00178713          	addi	a4,a5,1
    80003712:	0716                	slli	a4,a4,0x5
    80003714:	94ba                	add	s1,s1,a4
    80003716:	4898                	lw	a4,16(s1)
    80003718:	e715                	bnez	a4,80003744 <sys_sem_wait+0x92>
        sleep((void*)&semtable.sem[addr], &semtable.sem[addr].lock);
    8000371a:	00033497          	auipc	s1,0x33
    8000371e:	8e648493          	addi	s1,s1,-1818 # 80036000 <semtable>
    80003722:	00579513          	slli	a0,a5,0x5
    80003726:	0561                	addi	a0,a0,24
    80003728:	9526                	add	a0,a0,s1
    8000372a:	85aa                	mv	a1,a0
    8000372c:	ffffe097          	auipc	ra,0xffffe
    80003730:	7c8080e7          	jalr	1992(ra) # 80001ef4 <sleep>
    while (semtable.sem[addr].count == 0) {
    80003734:	fd442783          	lw	a5,-44(s0)
    80003738:	00178713          	addi	a4,a5,1
    8000373c:	0716                	slli	a4,a4,0x5
    8000373e:	9726                	add	a4,a4,s1
    80003740:	4b18                	lw	a4,16(a4)
    80003742:	d365                	beqz	a4,80003722 <sys_sem_wait+0x70>
    }
    semtable.sem[addr].count--;
    80003744:	00033517          	auipc	a0,0x33
    80003748:	8bc50513          	addi	a0,a0,-1860 # 80036000 <semtable>
    8000374c:	00178693          	addi	a3,a5,1
    80003750:	0696                	slli	a3,a3,0x5
    80003752:	96aa                	add	a3,a3,a0
    80003754:	377d                	addiw	a4,a4,-1
    80003756:	ca98                	sw	a4,16(a3)
    release(&semtable.sem[addr].lock);
    80003758:	0796                	slli	a5,a5,0x5
    8000375a:	07e1                	addi	a5,a5,24
    8000375c:	953e                	add	a0,a0,a5
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	572080e7          	jalr	1394(ra) # 80000cd0 <release>

    return 0;
    80003766:	4501                	li	a0,0
}
    80003768:	70a2                	ld	ra,40(sp)
    8000376a:	7402                	ld	s0,32(sp)
    8000376c:	64e2                	ld	s1,24(sp)
    8000376e:	6145                	addi	sp,sp,48
    80003770:	8082                	ret
        return -1;
    80003772:	557d                	li	a0,-1
    80003774:	bfd5                	j	80003768 <sys_sem_wait+0xb6>
    80003776:	557d                	li	a0,-1
    80003778:	bfc5                	j	80003768 <sys_sem_wait+0xb6>

000000008000377a <sys_sem_post>:

int sys_sem_post(void) {
    8000377a:	7179                	addi	sp,sp,-48
    8000377c:	f406                	sd	ra,40(sp)
    8000377e:	f022                	sd	s0,32(sp)
    80003780:	ec26                	sd	s1,24(sp)
    80003782:	1800                	addi	s0,sp,48
    uint64 s;
    int addr;

    // Retrieve semaphore pointer from syscall argument and copy address from user space
    if (argaddr(0, &s) < 0 || copyin(myproc()->pagetable, (char*)&addr, s, sizeof(int)) < 0) {
    80003784:	fd840593          	addi	a1,s0,-40
    80003788:	4501                	li	a0,0
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	aee080e7          	jalr	-1298(ra) # 80003278 <argaddr>
    80003792:	06054f63          	bltz	a0,80003810 <sys_sem_post+0x96>
    80003796:	ffffe097          	auipc	ra,0xffffe
    8000379a:	35e080e7          	jalr	862(ra) # 80001af4 <myproc>
    8000379e:	4691                	li	a3,4
    800037a0:	fd843603          	ld	a2,-40(s0)
    800037a4:	fd440593          	addi	a1,s0,-44
    800037a8:	32853503          	ld	a0,808(a0)
    800037ac:	ffffe097          	auipc	ra,0xffffe
    800037b0:	01a080e7          	jalr	26(ra) # 800017c6 <copyin>
    800037b4:	06054063          	bltz	a0,80003814 <sys_sem_post+0x9a>
        return -1;
    }

    // Acquire lock, increment semaphore count, signal any waiting process, and release lock
    acquire(&semtable.sem[addr].lock);
    800037b8:	fd442503          	lw	a0,-44(s0)
    800037bc:	0516                	slli	a0,a0,0x5
    800037be:	0561                	addi	a0,a0,24
    800037c0:	00033497          	auipc	s1,0x33
    800037c4:	84048493          	addi	s1,s1,-1984 # 80036000 <semtable>
    800037c8:	9526                	add	a0,a0,s1
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	452080e7          	jalr	1106(ra) # 80000c1c <acquire>
    semtable.sem[addr].count++;
    800037d2:	fd442503          	lw	a0,-44(s0)
    800037d6:	00150793          	addi	a5,a0,1
    800037da:	0796                	slli	a5,a5,0x5
    800037dc:	97a6                	add	a5,a5,s1
    800037de:	4b98                	lw	a4,16(a5)
    800037e0:	2705                	addiw	a4,a4,1
    800037e2:	cb98                	sw	a4,16(a5)
    wakeup((void*)&semtable.sem[addr]);
    800037e4:	0516                	slli	a0,a0,0x5
    800037e6:	0561                	addi	a0,a0,24
    800037e8:	9526                	add	a0,a0,s1
    800037ea:	ffffe097          	auipc	ra,0xffffe
    800037ee:	77a080e7          	jalr	1914(ra) # 80001f64 <wakeup>
    release(&semtable.sem[addr].lock);
    800037f2:	fd442503          	lw	a0,-44(s0)
    800037f6:	0516                	slli	a0,a0,0x5
    800037f8:	0561                	addi	a0,a0,24
    800037fa:	9526                	add	a0,a0,s1
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	4d4080e7          	jalr	1236(ra) # 80000cd0 <release>

    return 0;
    80003804:	4501                	li	a0,0
}
    80003806:	70a2                	ld	ra,40(sp)
    80003808:	7402                	ld	s0,32(sp)
    8000380a:	64e2                	ld	s1,24(sp)
    8000380c:	6145                	addi	sp,sp,48
    8000380e:	8082                	ret
        return -1;
    80003810:	557d                	li	a0,-1
    80003812:	bfd5                	j	80003806 <sys_sem_post+0x8c>
    80003814:	557d                	li	a0,-1
    80003816:	bfc5                	j	80003806 <sys_sem_post+0x8c>

0000000080003818 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003818:	7179                	addi	sp,sp,-48
    8000381a:	f406                	sd	ra,40(sp)
    8000381c:	f022                	sd	s0,32(sp)
    8000381e:	ec26                	sd	s1,24(sp)
    80003820:	e84a                	sd	s2,16(sp)
    80003822:	e44e                	sd	s3,8(sp)
    80003824:	e052                	sd	s4,0(sp)
    80003826:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003828:	00005597          	auipc	a1,0x5
    8000382c:	d2858593          	addi	a1,a1,-728 # 80008550 <syscalls+0xf0>
    80003830:	00024517          	auipc	a0,0x24
    80003834:	ed050513          	addi	a0,a0,-304 # 80027700 <bcache>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	354080e7          	jalr	852(ra) # 80000b8c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003840:	0002c797          	auipc	a5,0x2c
    80003844:	ec078793          	addi	a5,a5,-320 # 8002f700 <bcache+0x8000>
    80003848:	0002c717          	auipc	a4,0x2c
    8000384c:	12070713          	addi	a4,a4,288 # 8002f968 <bcache+0x8268>
    80003850:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003854:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003858:	00024497          	auipc	s1,0x24
    8000385c:	ec048493          	addi	s1,s1,-320 # 80027718 <bcache+0x18>
    b->next = bcache.head.next;
    80003860:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003862:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003864:	00005a17          	auipc	s4,0x5
    80003868:	cf4a0a13          	addi	s4,s4,-780 # 80008558 <syscalls+0xf8>
    b->next = bcache.head.next;
    8000386c:	2b893783          	ld	a5,696(s2)
    80003870:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003872:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003876:	85d2                	mv	a1,s4
    80003878:	01048513          	addi	a0,s1,16
    8000387c:	00001097          	auipc	ra,0x1
    80003880:	4c2080e7          	jalr	1218(ra) # 80004d3e <initsleeplock>
    bcache.head.next->prev = b;
    80003884:	2b893783          	ld	a5,696(s2)
    80003888:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000388a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000388e:	45848493          	addi	s1,s1,1112
    80003892:	fd349de3          	bne	s1,s3,8000386c <binit+0x54>
  }
}
    80003896:	70a2                	ld	ra,40(sp)
    80003898:	7402                	ld	s0,32(sp)
    8000389a:	64e2                	ld	s1,24(sp)
    8000389c:	6942                	ld	s2,16(sp)
    8000389e:	69a2                	ld	s3,8(sp)
    800038a0:	6a02                	ld	s4,0(sp)
    800038a2:	6145                	addi	sp,sp,48
    800038a4:	8082                	ret

00000000800038a6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800038a6:	7179                	addi	sp,sp,-48
    800038a8:	f406                	sd	ra,40(sp)
    800038aa:	f022                	sd	s0,32(sp)
    800038ac:	ec26                	sd	s1,24(sp)
    800038ae:	e84a                	sd	s2,16(sp)
    800038b0:	e44e                	sd	s3,8(sp)
    800038b2:	1800                	addi	s0,sp,48
    800038b4:	892a                	mv	s2,a0
    800038b6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800038b8:	00024517          	auipc	a0,0x24
    800038bc:	e4850513          	addi	a0,a0,-440 # 80027700 <bcache>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	35c080e7          	jalr	860(ra) # 80000c1c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800038c8:	0002c497          	auipc	s1,0x2c
    800038cc:	0f04b483          	ld	s1,240(s1) # 8002f9b8 <bcache+0x82b8>
    800038d0:	0002c797          	auipc	a5,0x2c
    800038d4:	09878793          	addi	a5,a5,152 # 8002f968 <bcache+0x8268>
    800038d8:	02f48f63          	beq	s1,a5,80003916 <bread+0x70>
    800038dc:	873e                	mv	a4,a5
    800038de:	a021                	j	800038e6 <bread+0x40>
    800038e0:	68a4                	ld	s1,80(s1)
    800038e2:	02e48a63          	beq	s1,a4,80003916 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800038e6:	449c                	lw	a5,8(s1)
    800038e8:	ff279ce3          	bne	a5,s2,800038e0 <bread+0x3a>
    800038ec:	44dc                	lw	a5,12(s1)
    800038ee:	ff3799e3          	bne	a5,s3,800038e0 <bread+0x3a>
      b->refcnt++;
    800038f2:	40bc                	lw	a5,64(s1)
    800038f4:	2785                	addiw	a5,a5,1
    800038f6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038f8:	00024517          	auipc	a0,0x24
    800038fc:	e0850513          	addi	a0,a0,-504 # 80027700 <bcache>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	3d0080e7          	jalr	976(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    80003908:	01048513          	addi	a0,s1,16
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	46c080e7          	jalr	1132(ra) # 80004d78 <acquiresleep>
      return b;
    80003914:	a8b9                	j	80003972 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003916:	0002c497          	auipc	s1,0x2c
    8000391a:	09a4b483          	ld	s1,154(s1) # 8002f9b0 <bcache+0x82b0>
    8000391e:	0002c797          	auipc	a5,0x2c
    80003922:	04a78793          	addi	a5,a5,74 # 8002f968 <bcache+0x8268>
    80003926:	00f48863          	beq	s1,a5,80003936 <bread+0x90>
    8000392a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000392c:	40bc                	lw	a5,64(s1)
    8000392e:	cf81                	beqz	a5,80003946 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003930:	64a4                	ld	s1,72(s1)
    80003932:	fee49de3          	bne	s1,a4,8000392c <bread+0x86>
  panic("bget: no buffers");
    80003936:	00005517          	auipc	a0,0x5
    8000393a:	c2a50513          	addi	a0,a0,-982 # 80008560 <syscalls+0x100>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	bfe080e7          	jalr	-1026(ra) # 8000053c <panic>
      b->dev = dev;
    80003946:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000394a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000394e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003952:	4785                	li	a5,1
    80003954:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003956:	00024517          	auipc	a0,0x24
    8000395a:	daa50513          	addi	a0,a0,-598 # 80027700 <bcache>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	372080e7          	jalr	882(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    80003966:	01048513          	addi	a0,s1,16
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	40e080e7          	jalr	1038(ra) # 80004d78 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003972:	409c                	lw	a5,0(s1)
    80003974:	cb89                	beqz	a5,80003986 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003976:	8526                	mv	a0,s1
    80003978:	70a2                	ld	ra,40(sp)
    8000397a:	7402                	ld	s0,32(sp)
    8000397c:	64e2                	ld	s1,24(sp)
    8000397e:	6942                	ld	s2,16(sp)
    80003980:	69a2                	ld	s3,8(sp)
    80003982:	6145                	addi	sp,sp,48
    80003984:	8082                	ret
    virtio_disk_rw(b, 0);
    80003986:	4581                	li	a1,0
    80003988:	8526                	mv	a0,s1
    8000398a:	00003097          	auipc	ra,0x3
    8000398e:	1e8080e7          	jalr	488(ra) # 80006b72 <virtio_disk_rw>
    b->valid = 1;
    80003992:	4785                	li	a5,1
    80003994:	c09c                	sw	a5,0(s1)
  return b;
    80003996:	b7c5                	j	80003976 <bread+0xd0>

0000000080003998 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003998:	1101                	addi	sp,sp,-32
    8000399a:	ec06                	sd	ra,24(sp)
    8000399c:	e822                	sd	s0,16(sp)
    8000399e:	e426                	sd	s1,8(sp)
    800039a0:	1000                	addi	s0,sp,32
    800039a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039a4:	0541                	addi	a0,a0,16
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	46e080e7          	jalr	1134(ra) # 80004e14 <holdingsleep>
    800039ae:	cd01                	beqz	a0,800039c6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800039b0:	4585                	li	a1,1
    800039b2:	8526                	mv	a0,s1
    800039b4:	00003097          	auipc	ra,0x3
    800039b8:	1be080e7          	jalr	446(ra) # 80006b72 <virtio_disk_rw>
}
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6105                	addi	sp,sp,32
    800039c4:	8082                	ret
    panic("bwrite");
    800039c6:	00005517          	auipc	a0,0x5
    800039ca:	bb250513          	addi	a0,a0,-1102 # 80008578 <syscalls+0x118>
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	b6e080e7          	jalr	-1170(ra) # 8000053c <panic>

00000000800039d6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800039d6:	1101                	addi	sp,sp,-32
    800039d8:	ec06                	sd	ra,24(sp)
    800039da:	e822                	sd	s0,16(sp)
    800039dc:	e426                	sd	s1,8(sp)
    800039de:	e04a                	sd	s2,0(sp)
    800039e0:	1000                	addi	s0,sp,32
    800039e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039e4:	01050913          	addi	s2,a0,16
    800039e8:	854a                	mv	a0,s2
    800039ea:	00001097          	auipc	ra,0x1
    800039ee:	42a080e7          	jalr	1066(ra) # 80004e14 <holdingsleep>
    800039f2:	c92d                	beqz	a0,80003a64 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	3da080e7          	jalr	986(ra) # 80004dd0 <releasesleep>

  acquire(&bcache.lock);
    800039fe:	00024517          	auipc	a0,0x24
    80003a02:	d0250513          	addi	a0,a0,-766 # 80027700 <bcache>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	216080e7          	jalr	534(ra) # 80000c1c <acquire>
  b->refcnt--;
    80003a0e:	40bc                	lw	a5,64(s1)
    80003a10:	37fd                	addiw	a5,a5,-1
    80003a12:	0007871b          	sext.w	a4,a5
    80003a16:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003a18:	eb05                	bnez	a4,80003a48 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003a1a:	68bc                	ld	a5,80(s1)
    80003a1c:	64b8                	ld	a4,72(s1)
    80003a1e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003a20:	64bc                	ld	a5,72(s1)
    80003a22:	68b8                	ld	a4,80(s1)
    80003a24:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003a26:	0002c797          	auipc	a5,0x2c
    80003a2a:	cda78793          	addi	a5,a5,-806 # 8002f700 <bcache+0x8000>
    80003a2e:	2b87b703          	ld	a4,696(a5)
    80003a32:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003a34:	0002c717          	auipc	a4,0x2c
    80003a38:	f3470713          	addi	a4,a4,-204 # 8002f968 <bcache+0x8268>
    80003a3c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003a3e:	2b87b703          	ld	a4,696(a5)
    80003a42:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003a44:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003a48:	00024517          	auipc	a0,0x24
    80003a4c:	cb850513          	addi	a0,a0,-840 # 80027700 <bcache>
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	280080e7          	jalr	640(ra) # 80000cd0 <release>
}
    80003a58:	60e2                	ld	ra,24(sp)
    80003a5a:	6442                	ld	s0,16(sp)
    80003a5c:	64a2                	ld	s1,8(sp)
    80003a5e:	6902                	ld	s2,0(sp)
    80003a60:	6105                	addi	sp,sp,32
    80003a62:	8082                	ret
    panic("brelse");
    80003a64:	00005517          	auipc	a0,0x5
    80003a68:	b1c50513          	addi	a0,a0,-1252 # 80008580 <syscalls+0x120>
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	ad0080e7          	jalr	-1328(ra) # 8000053c <panic>

0000000080003a74 <bpin>:

void
bpin(struct buf *b) {
    80003a74:	1101                	addi	sp,sp,-32
    80003a76:	ec06                	sd	ra,24(sp)
    80003a78:	e822                	sd	s0,16(sp)
    80003a7a:	e426                	sd	s1,8(sp)
    80003a7c:	1000                	addi	s0,sp,32
    80003a7e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a80:	00024517          	auipc	a0,0x24
    80003a84:	c8050513          	addi	a0,a0,-896 # 80027700 <bcache>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	194080e7          	jalr	404(ra) # 80000c1c <acquire>
  b->refcnt++;
    80003a90:	40bc                	lw	a5,64(s1)
    80003a92:	2785                	addiw	a5,a5,1
    80003a94:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a96:	00024517          	auipc	a0,0x24
    80003a9a:	c6a50513          	addi	a0,a0,-918 # 80027700 <bcache>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	232080e7          	jalr	562(ra) # 80000cd0 <release>
}
    80003aa6:	60e2                	ld	ra,24(sp)
    80003aa8:	6442                	ld	s0,16(sp)
    80003aaa:	64a2                	ld	s1,8(sp)
    80003aac:	6105                	addi	sp,sp,32
    80003aae:	8082                	ret

0000000080003ab0 <bunpin>:

void
bunpin(struct buf *b) {
    80003ab0:	1101                	addi	sp,sp,-32
    80003ab2:	ec06                	sd	ra,24(sp)
    80003ab4:	e822                	sd	s0,16(sp)
    80003ab6:	e426                	sd	s1,8(sp)
    80003ab8:	1000                	addi	s0,sp,32
    80003aba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003abc:	00024517          	auipc	a0,0x24
    80003ac0:	c4450513          	addi	a0,a0,-956 # 80027700 <bcache>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	158080e7          	jalr	344(ra) # 80000c1c <acquire>
  b->refcnt--;
    80003acc:	40bc                	lw	a5,64(s1)
    80003ace:	37fd                	addiw	a5,a5,-1
    80003ad0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ad2:	00024517          	auipc	a0,0x24
    80003ad6:	c2e50513          	addi	a0,a0,-978 # 80027700 <bcache>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	1f6080e7          	jalr	502(ra) # 80000cd0 <release>
}
    80003ae2:	60e2                	ld	ra,24(sp)
    80003ae4:	6442                	ld	s0,16(sp)
    80003ae6:	64a2                	ld	s1,8(sp)
    80003ae8:	6105                	addi	sp,sp,32
    80003aea:	8082                	ret

0000000080003aec <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003aec:	1101                	addi	sp,sp,-32
    80003aee:	ec06                	sd	ra,24(sp)
    80003af0:	e822                	sd	s0,16(sp)
    80003af2:	e426                	sd	s1,8(sp)
    80003af4:	e04a                	sd	s2,0(sp)
    80003af6:	1000                	addi	s0,sp,32
    80003af8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003afa:	00d5d59b          	srliw	a1,a1,0xd
    80003afe:	0002c797          	auipc	a5,0x2c
    80003b02:	2de7a783          	lw	a5,734(a5) # 8002fddc <sb+0x1c>
    80003b06:	9dbd                	addw	a1,a1,a5
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	d9e080e7          	jalr	-610(ra) # 800038a6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003b10:	0074f713          	andi	a4,s1,7
    80003b14:	4785                	li	a5,1
    80003b16:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003b1a:	14ce                	slli	s1,s1,0x33
    80003b1c:	90d9                	srli	s1,s1,0x36
    80003b1e:	00950733          	add	a4,a0,s1
    80003b22:	05874703          	lbu	a4,88(a4)
    80003b26:	00e7f6b3          	and	a3,a5,a4
    80003b2a:	c69d                	beqz	a3,80003b58 <bfree+0x6c>
    80003b2c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003b2e:	94aa                	add	s1,s1,a0
    80003b30:	fff7c793          	not	a5,a5
    80003b34:	8f7d                	and	a4,a4,a5
    80003b36:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003b3a:	00001097          	auipc	ra,0x1
    80003b3e:	120080e7          	jalr	288(ra) # 80004c5a <log_write>
  brelse(bp);
    80003b42:	854a                	mv	a0,s2
    80003b44:	00000097          	auipc	ra,0x0
    80003b48:	e92080e7          	jalr	-366(ra) # 800039d6 <brelse>
}
    80003b4c:	60e2                	ld	ra,24(sp)
    80003b4e:	6442                	ld	s0,16(sp)
    80003b50:	64a2                	ld	s1,8(sp)
    80003b52:	6902                	ld	s2,0(sp)
    80003b54:	6105                	addi	sp,sp,32
    80003b56:	8082                	ret
    panic("freeing free block");
    80003b58:	00005517          	auipc	a0,0x5
    80003b5c:	a3050513          	addi	a0,a0,-1488 # 80008588 <syscalls+0x128>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	9dc080e7          	jalr	-1572(ra) # 8000053c <panic>

0000000080003b68 <balloc>:
{
    80003b68:	711d                	addi	sp,sp,-96
    80003b6a:	ec86                	sd	ra,88(sp)
    80003b6c:	e8a2                	sd	s0,80(sp)
    80003b6e:	e4a6                	sd	s1,72(sp)
    80003b70:	e0ca                	sd	s2,64(sp)
    80003b72:	fc4e                	sd	s3,56(sp)
    80003b74:	f852                	sd	s4,48(sp)
    80003b76:	f456                	sd	s5,40(sp)
    80003b78:	f05a                	sd	s6,32(sp)
    80003b7a:	ec5e                	sd	s7,24(sp)
    80003b7c:	e862                	sd	s8,16(sp)
    80003b7e:	e466                	sd	s9,8(sp)
    80003b80:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b82:	0002c797          	auipc	a5,0x2c
    80003b86:	2427a783          	lw	a5,578(a5) # 8002fdc4 <sb+0x4>
    80003b8a:	cbc1                	beqz	a5,80003c1a <balloc+0xb2>
    80003b8c:	8baa                	mv	s7,a0
    80003b8e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b90:	0002cb17          	auipc	s6,0x2c
    80003b94:	230b0b13          	addi	s6,s6,560 # 8002fdc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b98:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b9a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b9c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b9e:	6c89                	lui	s9,0x2
    80003ba0:	a831                	j	80003bbc <balloc+0x54>
    brelse(bp);
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	e32080e7          	jalr	-462(ra) # 800039d6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003bac:	015c87bb          	addw	a5,s9,s5
    80003bb0:	00078a9b          	sext.w	s5,a5
    80003bb4:	004b2703          	lw	a4,4(s6)
    80003bb8:	06eaf163          	bgeu	s5,a4,80003c1a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003bbc:	41fad79b          	sraiw	a5,s5,0x1f
    80003bc0:	0137d79b          	srliw	a5,a5,0x13
    80003bc4:	015787bb          	addw	a5,a5,s5
    80003bc8:	40d7d79b          	sraiw	a5,a5,0xd
    80003bcc:	01cb2583          	lw	a1,28(s6)
    80003bd0:	9dbd                	addw	a1,a1,a5
    80003bd2:	855e                	mv	a0,s7
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	cd2080e7          	jalr	-814(ra) # 800038a6 <bread>
    80003bdc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bde:	004b2503          	lw	a0,4(s6)
    80003be2:	000a849b          	sext.w	s1,s5
    80003be6:	8762                	mv	a4,s8
    80003be8:	faa4fde3          	bgeu	s1,a0,80003ba2 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003bec:	00777693          	andi	a3,a4,7
    80003bf0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003bf4:	41f7579b          	sraiw	a5,a4,0x1f
    80003bf8:	01d7d79b          	srliw	a5,a5,0x1d
    80003bfc:	9fb9                	addw	a5,a5,a4
    80003bfe:	4037d79b          	sraiw	a5,a5,0x3
    80003c02:	00f90633          	add	a2,s2,a5
    80003c06:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003c0a:	00c6f5b3          	and	a1,a3,a2
    80003c0e:	cd91                	beqz	a1,80003c2a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c10:	2705                	addiw	a4,a4,1
    80003c12:	2485                	addiw	s1,s1,1
    80003c14:	fd471ae3          	bne	a4,s4,80003be8 <balloc+0x80>
    80003c18:	b769                	j	80003ba2 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003c1a:	00005517          	auipc	a0,0x5
    80003c1e:	98650513          	addi	a0,a0,-1658 # 800085a0 <syscalls+0x140>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	91a080e7          	jalr	-1766(ra) # 8000053c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003c2a:	97ca                	add	a5,a5,s2
    80003c2c:	8e55                	or	a2,a2,a3
    80003c2e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003c32:	854a                	mv	a0,s2
    80003c34:	00001097          	auipc	ra,0x1
    80003c38:	026080e7          	jalr	38(ra) # 80004c5a <log_write>
        brelse(bp);
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	d98080e7          	jalr	-616(ra) # 800039d6 <brelse>
  bp = bread(dev, bno);
    80003c46:	85a6                	mv	a1,s1
    80003c48:	855e                	mv	a0,s7
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	c5c080e7          	jalr	-932(ra) # 800038a6 <bread>
    80003c52:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003c54:	40000613          	li	a2,1024
    80003c58:	4581                	li	a1,0
    80003c5a:	05850513          	addi	a0,a0,88
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	0ba080e7          	jalr	186(ra) # 80000d18 <memset>
  log_write(bp);
    80003c66:	854a                	mv	a0,s2
    80003c68:	00001097          	auipc	ra,0x1
    80003c6c:	ff2080e7          	jalr	-14(ra) # 80004c5a <log_write>
  brelse(bp);
    80003c70:	854a                	mv	a0,s2
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	d64080e7          	jalr	-668(ra) # 800039d6 <brelse>
}
    80003c7a:	8526                	mv	a0,s1
    80003c7c:	60e6                	ld	ra,88(sp)
    80003c7e:	6446                	ld	s0,80(sp)
    80003c80:	64a6                	ld	s1,72(sp)
    80003c82:	6906                	ld	s2,64(sp)
    80003c84:	79e2                	ld	s3,56(sp)
    80003c86:	7a42                	ld	s4,48(sp)
    80003c88:	7aa2                	ld	s5,40(sp)
    80003c8a:	7b02                	ld	s6,32(sp)
    80003c8c:	6be2                	ld	s7,24(sp)
    80003c8e:	6c42                	ld	s8,16(sp)
    80003c90:	6ca2                	ld	s9,8(sp)
    80003c92:	6125                	addi	sp,sp,96
    80003c94:	8082                	ret

0000000080003c96 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c96:	7179                	addi	sp,sp,-48
    80003c98:	f406                	sd	ra,40(sp)
    80003c9a:	f022                	sd	s0,32(sp)
    80003c9c:	ec26                	sd	s1,24(sp)
    80003c9e:	e84a                	sd	s2,16(sp)
    80003ca0:	e44e                	sd	s3,8(sp)
    80003ca2:	e052                	sd	s4,0(sp)
    80003ca4:	1800                	addi	s0,sp,48
    80003ca6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ca8:	47ad                	li	a5,11
    80003caa:	04b7fe63          	bgeu	a5,a1,80003d06 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003cae:	ff45849b          	addiw	s1,a1,-12
    80003cb2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003cb6:	0ff00793          	li	a5,255
    80003cba:	0ae7e463          	bltu	a5,a4,80003d62 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003cbe:	08052583          	lw	a1,128(a0)
    80003cc2:	c5b5                	beqz	a1,80003d2e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003cc4:	00092503          	lw	a0,0(s2)
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	bde080e7          	jalr	-1058(ra) # 800038a6 <bread>
    80003cd0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003cd2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003cd6:	02049713          	slli	a4,s1,0x20
    80003cda:	01e75593          	srli	a1,a4,0x1e
    80003cde:	00b784b3          	add	s1,a5,a1
    80003ce2:	0004a983          	lw	s3,0(s1)
    80003ce6:	04098e63          	beqz	s3,80003d42 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003cea:	8552                	mv	a0,s4
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	cea080e7          	jalr	-790(ra) # 800039d6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003cf4:	854e                	mv	a0,s3
    80003cf6:	70a2                	ld	ra,40(sp)
    80003cf8:	7402                	ld	s0,32(sp)
    80003cfa:	64e2                	ld	s1,24(sp)
    80003cfc:	6942                	ld	s2,16(sp)
    80003cfe:	69a2                	ld	s3,8(sp)
    80003d00:	6a02                	ld	s4,0(sp)
    80003d02:	6145                	addi	sp,sp,48
    80003d04:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003d06:	02059793          	slli	a5,a1,0x20
    80003d0a:	01e7d593          	srli	a1,a5,0x1e
    80003d0e:	00b504b3          	add	s1,a0,a1
    80003d12:	0504a983          	lw	s3,80(s1)
    80003d16:	fc099fe3          	bnez	s3,80003cf4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003d1a:	4108                	lw	a0,0(a0)
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	e4c080e7          	jalr	-436(ra) # 80003b68 <balloc>
    80003d24:	0005099b          	sext.w	s3,a0
    80003d28:	0534a823          	sw	s3,80(s1)
    80003d2c:	b7e1                	j	80003cf4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003d2e:	4108                	lw	a0,0(a0)
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	e38080e7          	jalr	-456(ra) # 80003b68 <balloc>
    80003d38:	0005059b          	sext.w	a1,a0
    80003d3c:	08b92023          	sw	a1,128(s2)
    80003d40:	b751                	j	80003cc4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003d42:	00092503          	lw	a0,0(s2)
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	e22080e7          	jalr	-478(ra) # 80003b68 <balloc>
    80003d4e:	0005099b          	sext.w	s3,a0
    80003d52:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003d56:	8552                	mv	a0,s4
    80003d58:	00001097          	auipc	ra,0x1
    80003d5c:	f02080e7          	jalr	-254(ra) # 80004c5a <log_write>
    80003d60:	b769                	j	80003cea <bmap+0x54>
  panic("bmap: out of range");
    80003d62:	00005517          	auipc	a0,0x5
    80003d66:	85650513          	addi	a0,a0,-1962 # 800085b8 <syscalls+0x158>
    80003d6a:	ffffc097          	auipc	ra,0xffffc
    80003d6e:	7d2080e7          	jalr	2002(ra) # 8000053c <panic>

0000000080003d72 <iget>:
{
    80003d72:	7179                	addi	sp,sp,-48
    80003d74:	f406                	sd	ra,40(sp)
    80003d76:	f022                	sd	s0,32(sp)
    80003d78:	ec26                	sd	s1,24(sp)
    80003d7a:	e84a                	sd	s2,16(sp)
    80003d7c:	e44e                	sd	s3,8(sp)
    80003d7e:	e052                	sd	s4,0(sp)
    80003d80:	1800                	addi	s0,sp,48
    80003d82:	89aa                	mv	s3,a0
    80003d84:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d86:	0002c517          	auipc	a0,0x2c
    80003d8a:	05a50513          	addi	a0,a0,90 # 8002fde0 <itable>
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	e8e080e7          	jalr	-370(ra) # 80000c1c <acquire>
  empty = 0;
    80003d96:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d98:	0002c497          	auipc	s1,0x2c
    80003d9c:	06048493          	addi	s1,s1,96 # 8002fdf8 <itable+0x18>
    80003da0:	0002e697          	auipc	a3,0x2e
    80003da4:	ae868693          	addi	a3,a3,-1304 # 80031888 <log>
    80003da8:	a039                	j	80003db6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003daa:	02090b63          	beqz	s2,80003de0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003dae:	08848493          	addi	s1,s1,136
    80003db2:	02d48a63          	beq	s1,a3,80003de6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003db6:	449c                	lw	a5,8(s1)
    80003db8:	fef059e3          	blez	a5,80003daa <iget+0x38>
    80003dbc:	4098                	lw	a4,0(s1)
    80003dbe:	ff3716e3          	bne	a4,s3,80003daa <iget+0x38>
    80003dc2:	40d8                	lw	a4,4(s1)
    80003dc4:	ff4713e3          	bne	a4,s4,80003daa <iget+0x38>
      ip->ref++;
    80003dc8:	2785                	addiw	a5,a5,1
    80003dca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003dcc:	0002c517          	auipc	a0,0x2c
    80003dd0:	01450513          	addi	a0,a0,20 # 8002fde0 <itable>
    80003dd4:	ffffd097          	auipc	ra,0xffffd
    80003dd8:	efc080e7          	jalr	-260(ra) # 80000cd0 <release>
      return ip;
    80003ddc:	8926                	mv	s2,s1
    80003dde:	a03d                	j	80003e0c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003de0:	f7f9                	bnez	a5,80003dae <iget+0x3c>
    80003de2:	8926                	mv	s2,s1
    80003de4:	b7e9                	j	80003dae <iget+0x3c>
  if(empty == 0)
    80003de6:	02090c63          	beqz	s2,80003e1e <iget+0xac>
  ip->dev = dev;
    80003dea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003dee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003df2:	4785                	li	a5,1
    80003df4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003df8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003dfc:	0002c517          	auipc	a0,0x2c
    80003e00:	fe450513          	addi	a0,a0,-28 # 8002fde0 <itable>
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	ecc080e7          	jalr	-308(ra) # 80000cd0 <release>
}
    80003e0c:	854a                	mv	a0,s2
    80003e0e:	70a2                	ld	ra,40(sp)
    80003e10:	7402                	ld	s0,32(sp)
    80003e12:	64e2                	ld	s1,24(sp)
    80003e14:	6942                	ld	s2,16(sp)
    80003e16:	69a2                	ld	s3,8(sp)
    80003e18:	6a02                	ld	s4,0(sp)
    80003e1a:	6145                	addi	sp,sp,48
    80003e1c:	8082                	ret
    panic("iget: no inodes");
    80003e1e:	00004517          	auipc	a0,0x4
    80003e22:	7b250513          	addi	a0,a0,1970 # 800085d0 <syscalls+0x170>
    80003e26:	ffffc097          	auipc	ra,0xffffc
    80003e2a:	716080e7          	jalr	1814(ra) # 8000053c <panic>

0000000080003e2e <fsinit>:
fsinit(int dev) {
    80003e2e:	7179                	addi	sp,sp,-48
    80003e30:	f406                	sd	ra,40(sp)
    80003e32:	f022                	sd	s0,32(sp)
    80003e34:	ec26                	sd	s1,24(sp)
    80003e36:	e84a                	sd	s2,16(sp)
    80003e38:	e44e                	sd	s3,8(sp)
    80003e3a:	1800                	addi	s0,sp,48
    80003e3c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003e3e:	4585                	li	a1,1
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	a66080e7          	jalr	-1434(ra) # 800038a6 <bread>
    80003e48:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003e4a:	0002c997          	auipc	s3,0x2c
    80003e4e:	f7698993          	addi	s3,s3,-138 # 8002fdc0 <sb>
    80003e52:	02000613          	li	a2,32
    80003e56:	05850593          	addi	a1,a0,88
    80003e5a:	854e                	mv	a0,s3
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	f18080e7          	jalr	-232(ra) # 80000d74 <memmove>
  brelse(bp);
    80003e64:	8526                	mv	a0,s1
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	b70080e7          	jalr	-1168(ra) # 800039d6 <brelse>
  if(sb.magic != FSMAGIC)
    80003e6e:	0009a703          	lw	a4,0(s3)
    80003e72:	102037b7          	lui	a5,0x10203
    80003e76:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e7a:	02f71263          	bne	a4,a5,80003e9e <fsinit+0x70>
  initlog(dev, &sb);
    80003e7e:	0002c597          	auipc	a1,0x2c
    80003e82:	f4258593          	addi	a1,a1,-190 # 8002fdc0 <sb>
    80003e86:	854a                	mv	a0,s2
    80003e88:	00001097          	auipc	ra,0x1
    80003e8c:	b56080e7          	jalr	-1194(ra) # 800049de <initlog>
}
    80003e90:	70a2                	ld	ra,40(sp)
    80003e92:	7402                	ld	s0,32(sp)
    80003e94:	64e2                	ld	s1,24(sp)
    80003e96:	6942                	ld	s2,16(sp)
    80003e98:	69a2                	ld	s3,8(sp)
    80003e9a:	6145                	addi	sp,sp,48
    80003e9c:	8082                	ret
    panic("invalid file system");
    80003e9e:	00004517          	auipc	a0,0x4
    80003ea2:	74250513          	addi	a0,a0,1858 # 800085e0 <syscalls+0x180>
    80003ea6:	ffffc097          	auipc	ra,0xffffc
    80003eaa:	696080e7          	jalr	1686(ra) # 8000053c <panic>

0000000080003eae <iinit>:
{
    80003eae:	7179                	addi	sp,sp,-48
    80003eb0:	f406                	sd	ra,40(sp)
    80003eb2:	f022                	sd	s0,32(sp)
    80003eb4:	ec26                	sd	s1,24(sp)
    80003eb6:	e84a                	sd	s2,16(sp)
    80003eb8:	e44e                	sd	s3,8(sp)
    80003eba:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ebc:	00004597          	auipc	a1,0x4
    80003ec0:	73c58593          	addi	a1,a1,1852 # 800085f8 <syscalls+0x198>
    80003ec4:	0002c517          	auipc	a0,0x2c
    80003ec8:	f1c50513          	addi	a0,a0,-228 # 8002fde0 <itable>
    80003ecc:	ffffd097          	auipc	ra,0xffffd
    80003ed0:	cc0080e7          	jalr	-832(ra) # 80000b8c <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ed4:	0002c497          	auipc	s1,0x2c
    80003ed8:	f3448493          	addi	s1,s1,-204 # 8002fe08 <itable+0x28>
    80003edc:	0002e997          	auipc	s3,0x2e
    80003ee0:	9bc98993          	addi	s3,s3,-1604 # 80031898 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ee4:	00004917          	auipc	s2,0x4
    80003ee8:	71c90913          	addi	s2,s2,1820 # 80008600 <syscalls+0x1a0>
    80003eec:	85ca                	mv	a1,s2
    80003eee:	8526                	mv	a0,s1
    80003ef0:	00001097          	auipc	ra,0x1
    80003ef4:	e4e080e7          	jalr	-434(ra) # 80004d3e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ef8:	08848493          	addi	s1,s1,136
    80003efc:	ff3498e3          	bne	s1,s3,80003eec <iinit+0x3e>
}
    80003f00:	70a2                	ld	ra,40(sp)
    80003f02:	7402                	ld	s0,32(sp)
    80003f04:	64e2                	ld	s1,24(sp)
    80003f06:	6942                	ld	s2,16(sp)
    80003f08:	69a2                	ld	s3,8(sp)
    80003f0a:	6145                	addi	sp,sp,48
    80003f0c:	8082                	ret

0000000080003f0e <ialloc>:
{
    80003f0e:	715d                	addi	sp,sp,-80
    80003f10:	e486                	sd	ra,72(sp)
    80003f12:	e0a2                	sd	s0,64(sp)
    80003f14:	fc26                	sd	s1,56(sp)
    80003f16:	f84a                	sd	s2,48(sp)
    80003f18:	f44e                	sd	s3,40(sp)
    80003f1a:	f052                	sd	s4,32(sp)
    80003f1c:	ec56                	sd	s5,24(sp)
    80003f1e:	e85a                	sd	s6,16(sp)
    80003f20:	e45e                	sd	s7,8(sp)
    80003f22:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f24:	0002c717          	auipc	a4,0x2c
    80003f28:	ea872703          	lw	a4,-344(a4) # 8002fdcc <sb+0xc>
    80003f2c:	4785                	li	a5,1
    80003f2e:	04e7fa63          	bgeu	a5,a4,80003f82 <ialloc+0x74>
    80003f32:	8aaa                	mv	s5,a0
    80003f34:	8bae                	mv	s7,a1
    80003f36:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003f38:	0002ca17          	auipc	s4,0x2c
    80003f3c:	e88a0a13          	addi	s4,s4,-376 # 8002fdc0 <sb>
    80003f40:	00048b1b          	sext.w	s6,s1
    80003f44:	0044d593          	srli	a1,s1,0x4
    80003f48:	018a2783          	lw	a5,24(s4)
    80003f4c:	9dbd                	addw	a1,a1,a5
    80003f4e:	8556                	mv	a0,s5
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	956080e7          	jalr	-1706(ra) # 800038a6 <bread>
    80003f58:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003f5a:	05850993          	addi	s3,a0,88
    80003f5e:	00f4f793          	andi	a5,s1,15
    80003f62:	079a                	slli	a5,a5,0x6
    80003f64:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003f66:	00099783          	lh	a5,0(s3)
    80003f6a:	c785                	beqz	a5,80003f92 <ialloc+0x84>
    brelse(bp);
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	a6a080e7          	jalr	-1430(ra) # 800039d6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f74:	0485                	addi	s1,s1,1
    80003f76:	00ca2703          	lw	a4,12(s4)
    80003f7a:	0004879b          	sext.w	a5,s1
    80003f7e:	fce7e1e3          	bltu	a5,a4,80003f40 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003f82:	00004517          	auipc	a0,0x4
    80003f86:	68650513          	addi	a0,a0,1670 # 80008608 <syscalls+0x1a8>
    80003f8a:	ffffc097          	auipc	ra,0xffffc
    80003f8e:	5b2080e7          	jalr	1458(ra) # 8000053c <panic>
      memset(dip, 0, sizeof(*dip));
    80003f92:	04000613          	li	a2,64
    80003f96:	4581                	li	a1,0
    80003f98:	854e                	mv	a0,s3
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	d7e080e7          	jalr	-642(ra) # 80000d18 <memset>
      dip->type = type;
    80003fa2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003fa6:	854a                	mv	a0,s2
    80003fa8:	00001097          	auipc	ra,0x1
    80003fac:	cb2080e7          	jalr	-846(ra) # 80004c5a <log_write>
      brelse(bp);
    80003fb0:	854a                	mv	a0,s2
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	a24080e7          	jalr	-1500(ra) # 800039d6 <brelse>
      return iget(dev, inum);
    80003fba:	85da                	mv	a1,s6
    80003fbc:	8556                	mv	a0,s5
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	db4080e7          	jalr	-588(ra) # 80003d72 <iget>
}
    80003fc6:	60a6                	ld	ra,72(sp)
    80003fc8:	6406                	ld	s0,64(sp)
    80003fca:	74e2                	ld	s1,56(sp)
    80003fcc:	7942                	ld	s2,48(sp)
    80003fce:	79a2                	ld	s3,40(sp)
    80003fd0:	7a02                	ld	s4,32(sp)
    80003fd2:	6ae2                	ld	s5,24(sp)
    80003fd4:	6b42                	ld	s6,16(sp)
    80003fd6:	6ba2                	ld	s7,8(sp)
    80003fd8:	6161                	addi	sp,sp,80
    80003fda:	8082                	ret

0000000080003fdc <iupdate>:
{
    80003fdc:	1101                	addi	sp,sp,-32
    80003fde:	ec06                	sd	ra,24(sp)
    80003fe0:	e822                	sd	s0,16(sp)
    80003fe2:	e426                	sd	s1,8(sp)
    80003fe4:	e04a                	sd	s2,0(sp)
    80003fe6:	1000                	addi	s0,sp,32
    80003fe8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fea:	415c                	lw	a5,4(a0)
    80003fec:	0047d79b          	srliw	a5,a5,0x4
    80003ff0:	0002c597          	auipc	a1,0x2c
    80003ff4:	de85a583          	lw	a1,-536(a1) # 8002fdd8 <sb+0x18>
    80003ff8:	9dbd                	addw	a1,a1,a5
    80003ffa:	4108                	lw	a0,0(a0)
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	8aa080e7          	jalr	-1878(ra) # 800038a6 <bread>
    80004004:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004006:	05850793          	addi	a5,a0,88
    8000400a:	40d8                	lw	a4,4(s1)
    8000400c:	8b3d                	andi	a4,a4,15
    8000400e:	071a                	slli	a4,a4,0x6
    80004010:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80004012:	04449703          	lh	a4,68(s1)
    80004016:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000401a:	04649703          	lh	a4,70(s1)
    8000401e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80004022:	04849703          	lh	a4,72(s1)
    80004026:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000402a:	04a49703          	lh	a4,74(s1)
    8000402e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80004032:	44f8                	lw	a4,76(s1)
    80004034:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004036:	03400613          	li	a2,52
    8000403a:	05048593          	addi	a1,s1,80
    8000403e:	00c78513          	addi	a0,a5,12
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	d32080e7          	jalr	-718(ra) # 80000d74 <memmove>
  log_write(bp);
    8000404a:	854a                	mv	a0,s2
    8000404c:	00001097          	auipc	ra,0x1
    80004050:	c0e080e7          	jalr	-1010(ra) # 80004c5a <log_write>
  brelse(bp);
    80004054:	854a                	mv	a0,s2
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	980080e7          	jalr	-1664(ra) # 800039d6 <brelse>
}
    8000405e:	60e2                	ld	ra,24(sp)
    80004060:	6442                	ld	s0,16(sp)
    80004062:	64a2                	ld	s1,8(sp)
    80004064:	6902                	ld	s2,0(sp)
    80004066:	6105                	addi	sp,sp,32
    80004068:	8082                	ret

000000008000406a <idup>:
{
    8000406a:	1101                	addi	sp,sp,-32
    8000406c:	ec06                	sd	ra,24(sp)
    8000406e:	e822                	sd	s0,16(sp)
    80004070:	e426                	sd	s1,8(sp)
    80004072:	1000                	addi	s0,sp,32
    80004074:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004076:	0002c517          	auipc	a0,0x2c
    8000407a:	d6a50513          	addi	a0,a0,-662 # 8002fde0 <itable>
    8000407e:	ffffd097          	auipc	ra,0xffffd
    80004082:	b9e080e7          	jalr	-1122(ra) # 80000c1c <acquire>
  ip->ref++;
    80004086:	449c                	lw	a5,8(s1)
    80004088:	2785                	addiw	a5,a5,1
    8000408a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000408c:	0002c517          	auipc	a0,0x2c
    80004090:	d5450513          	addi	a0,a0,-684 # 8002fde0 <itable>
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	c3c080e7          	jalr	-964(ra) # 80000cd0 <release>
}
    8000409c:	8526                	mv	a0,s1
    8000409e:	60e2                	ld	ra,24(sp)
    800040a0:	6442                	ld	s0,16(sp)
    800040a2:	64a2                	ld	s1,8(sp)
    800040a4:	6105                	addi	sp,sp,32
    800040a6:	8082                	ret

00000000800040a8 <ilock>:
{
    800040a8:	1101                	addi	sp,sp,-32
    800040aa:	ec06                	sd	ra,24(sp)
    800040ac:	e822                	sd	s0,16(sp)
    800040ae:	e426                	sd	s1,8(sp)
    800040b0:	e04a                	sd	s2,0(sp)
    800040b2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800040b4:	c115                	beqz	a0,800040d8 <ilock+0x30>
    800040b6:	84aa                	mv	s1,a0
    800040b8:	451c                	lw	a5,8(a0)
    800040ba:	00f05f63          	blez	a5,800040d8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800040be:	0541                	addi	a0,a0,16
    800040c0:	00001097          	auipc	ra,0x1
    800040c4:	cb8080e7          	jalr	-840(ra) # 80004d78 <acquiresleep>
  if(ip->valid == 0){
    800040c8:	40bc                	lw	a5,64(s1)
    800040ca:	cf99                	beqz	a5,800040e8 <ilock+0x40>
}
    800040cc:	60e2                	ld	ra,24(sp)
    800040ce:	6442                	ld	s0,16(sp)
    800040d0:	64a2                	ld	s1,8(sp)
    800040d2:	6902                	ld	s2,0(sp)
    800040d4:	6105                	addi	sp,sp,32
    800040d6:	8082                	ret
    panic("ilock");
    800040d8:	00004517          	auipc	a0,0x4
    800040dc:	54850513          	addi	a0,a0,1352 # 80008620 <syscalls+0x1c0>
    800040e0:	ffffc097          	auipc	ra,0xffffc
    800040e4:	45c080e7          	jalr	1116(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800040e8:	40dc                	lw	a5,4(s1)
    800040ea:	0047d79b          	srliw	a5,a5,0x4
    800040ee:	0002c597          	auipc	a1,0x2c
    800040f2:	cea5a583          	lw	a1,-790(a1) # 8002fdd8 <sb+0x18>
    800040f6:	9dbd                	addw	a1,a1,a5
    800040f8:	4088                	lw	a0,0(s1)
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	7ac080e7          	jalr	1964(ra) # 800038a6 <bread>
    80004102:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004104:	05850593          	addi	a1,a0,88
    80004108:	40dc                	lw	a5,4(s1)
    8000410a:	8bbd                	andi	a5,a5,15
    8000410c:	079a                	slli	a5,a5,0x6
    8000410e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004110:	00059783          	lh	a5,0(a1)
    80004114:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004118:	00259783          	lh	a5,2(a1)
    8000411c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004120:	00459783          	lh	a5,4(a1)
    80004124:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004128:	00659783          	lh	a5,6(a1)
    8000412c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004130:	459c                	lw	a5,8(a1)
    80004132:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004134:	03400613          	li	a2,52
    80004138:	05b1                	addi	a1,a1,12
    8000413a:	05048513          	addi	a0,s1,80
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	c36080e7          	jalr	-970(ra) # 80000d74 <memmove>
    brelse(bp);
    80004146:	854a                	mv	a0,s2
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	88e080e7          	jalr	-1906(ra) # 800039d6 <brelse>
    ip->valid = 1;
    80004150:	4785                	li	a5,1
    80004152:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004154:	04449783          	lh	a5,68(s1)
    80004158:	fbb5                	bnez	a5,800040cc <ilock+0x24>
      panic("ilock: no type");
    8000415a:	00004517          	auipc	a0,0x4
    8000415e:	4ce50513          	addi	a0,a0,1230 # 80008628 <syscalls+0x1c8>
    80004162:	ffffc097          	auipc	ra,0xffffc
    80004166:	3da080e7          	jalr	986(ra) # 8000053c <panic>

000000008000416a <iunlock>:
{
    8000416a:	1101                	addi	sp,sp,-32
    8000416c:	ec06                	sd	ra,24(sp)
    8000416e:	e822                	sd	s0,16(sp)
    80004170:	e426                	sd	s1,8(sp)
    80004172:	e04a                	sd	s2,0(sp)
    80004174:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004176:	c905                	beqz	a0,800041a6 <iunlock+0x3c>
    80004178:	84aa                	mv	s1,a0
    8000417a:	01050913          	addi	s2,a0,16
    8000417e:	854a                	mv	a0,s2
    80004180:	00001097          	auipc	ra,0x1
    80004184:	c94080e7          	jalr	-876(ra) # 80004e14 <holdingsleep>
    80004188:	cd19                	beqz	a0,800041a6 <iunlock+0x3c>
    8000418a:	449c                	lw	a5,8(s1)
    8000418c:	00f05d63          	blez	a5,800041a6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004190:	854a                	mv	a0,s2
    80004192:	00001097          	auipc	ra,0x1
    80004196:	c3e080e7          	jalr	-962(ra) # 80004dd0 <releasesleep>
}
    8000419a:	60e2                	ld	ra,24(sp)
    8000419c:	6442                	ld	s0,16(sp)
    8000419e:	64a2                	ld	s1,8(sp)
    800041a0:	6902                	ld	s2,0(sp)
    800041a2:	6105                	addi	sp,sp,32
    800041a4:	8082                	ret
    panic("iunlock");
    800041a6:	00004517          	auipc	a0,0x4
    800041aa:	49250513          	addi	a0,a0,1170 # 80008638 <syscalls+0x1d8>
    800041ae:	ffffc097          	auipc	ra,0xffffc
    800041b2:	38e080e7          	jalr	910(ra) # 8000053c <panic>

00000000800041b6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800041b6:	7179                	addi	sp,sp,-48
    800041b8:	f406                	sd	ra,40(sp)
    800041ba:	f022                	sd	s0,32(sp)
    800041bc:	ec26                	sd	s1,24(sp)
    800041be:	e84a                	sd	s2,16(sp)
    800041c0:	e44e                	sd	s3,8(sp)
    800041c2:	e052                	sd	s4,0(sp)
    800041c4:	1800                	addi	s0,sp,48
    800041c6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800041c8:	05050493          	addi	s1,a0,80
    800041cc:	08050913          	addi	s2,a0,128
    800041d0:	a021                	j	800041d8 <itrunc+0x22>
    800041d2:	0491                	addi	s1,s1,4
    800041d4:	01248d63          	beq	s1,s2,800041ee <itrunc+0x38>
    if(ip->addrs[i]){
    800041d8:	408c                	lw	a1,0(s1)
    800041da:	dde5                	beqz	a1,800041d2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800041dc:	0009a503          	lw	a0,0(s3)
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	90c080e7          	jalr	-1780(ra) # 80003aec <bfree>
      ip->addrs[i] = 0;
    800041e8:	0004a023          	sw	zero,0(s1)
    800041ec:	b7dd                	j	800041d2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800041ee:	0809a583          	lw	a1,128(s3)
    800041f2:	e185                	bnez	a1,80004212 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800041f4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800041f8:	854e                	mv	a0,s3
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	de2080e7          	jalr	-542(ra) # 80003fdc <iupdate>
}
    80004202:	70a2                	ld	ra,40(sp)
    80004204:	7402                	ld	s0,32(sp)
    80004206:	64e2                	ld	s1,24(sp)
    80004208:	6942                	ld	s2,16(sp)
    8000420a:	69a2                	ld	s3,8(sp)
    8000420c:	6a02                	ld	s4,0(sp)
    8000420e:	6145                	addi	sp,sp,48
    80004210:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004212:	0009a503          	lw	a0,0(s3)
    80004216:	fffff097          	auipc	ra,0xfffff
    8000421a:	690080e7          	jalr	1680(ra) # 800038a6 <bread>
    8000421e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004220:	05850493          	addi	s1,a0,88
    80004224:	45850913          	addi	s2,a0,1112
    80004228:	a021                	j	80004230 <itrunc+0x7a>
    8000422a:	0491                	addi	s1,s1,4
    8000422c:	01248b63          	beq	s1,s2,80004242 <itrunc+0x8c>
      if(a[j])
    80004230:	408c                	lw	a1,0(s1)
    80004232:	dde5                	beqz	a1,8000422a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004234:	0009a503          	lw	a0,0(s3)
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	8b4080e7          	jalr	-1868(ra) # 80003aec <bfree>
    80004240:	b7ed                	j	8000422a <itrunc+0x74>
    brelse(bp);
    80004242:	8552                	mv	a0,s4
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	792080e7          	jalr	1938(ra) # 800039d6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000424c:	0809a583          	lw	a1,128(s3)
    80004250:	0009a503          	lw	a0,0(s3)
    80004254:	00000097          	auipc	ra,0x0
    80004258:	898080e7          	jalr	-1896(ra) # 80003aec <bfree>
    ip->addrs[NDIRECT] = 0;
    8000425c:	0809a023          	sw	zero,128(s3)
    80004260:	bf51                	j	800041f4 <itrunc+0x3e>

0000000080004262 <iput>:
{
    80004262:	1101                	addi	sp,sp,-32
    80004264:	ec06                	sd	ra,24(sp)
    80004266:	e822                	sd	s0,16(sp)
    80004268:	e426                	sd	s1,8(sp)
    8000426a:	e04a                	sd	s2,0(sp)
    8000426c:	1000                	addi	s0,sp,32
    8000426e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004270:	0002c517          	auipc	a0,0x2c
    80004274:	b7050513          	addi	a0,a0,-1168 # 8002fde0 <itable>
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	9a4080e7          	jalr	-1628(ra) # 80000c1c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004280:	4498                	lw	a4,8(s1)
    80004282:	4785                	li	a5,1
    80004284:	02f70363          	beq	a4,a5,800042aa <iput+0x48>
  ip->ref--;
    80004288:	449c                	lw	a5,8(s1)
    8000428a:	37fd                	addiw	a5,a5,-1
    8000428c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000428e:	0002c517          	auipc	a0,0x2c
    80004292:	b5250513          	addi	a0,a0,-1198 # 8002fde0 <itable>
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	a3a080e7          	jalr	-1478(ra) # 80000cd0 <release>
}
    8000429e:	60e2                	ld	ra,24(sp)
    800042a0:	6442                	ld	s0,16(sp)
    800042a2:	64a2                	ld	s1,8(sp)
    800042a4:	6902                	ld	s2,0(sp)
    800042a6:	6105                	addi	sp,sp,32
    800042a8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042aa:	40bc                	lw	a5,64(s1)
    800042ac:	dff1                	beqz	a5,80004288 <iput+0x26>
    800042ae:	04a49783          	lh	a5,74(s1)
    800042b2:	fbf9                	bnez	a5,80004288 <iput+0x26>
    acquiresleep(&ip->lock);
    800042b4:	01048913          	addi	s2,s1,16
    800042b8:	854a                	mv	a0,s2
    800042ba:	00001097          	auipc	ra,0x1
    800042be:	abe080e7          	jalr	-1346(ra) # 80004d78 <acquiresleep>
    release(&itable.lock);
    800042c2:	0002c517          	auipc	a0,0x2c
    800042c6:	b1e50513          	addi	a0,a0,-1250 # 8002fde0 <itable>
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	a06080e7          	jalr	-1530(ra) # 80000cd0 <release>
    itrunc(ip);
    800042d2:	8526                	mv	a0,s1
    800042d4:	00000097          	auipc	ra,0x0
    800042d8:	ee2080e7          	jalr	-286(ra) # 800041b6 <itrunc>
    ip->type = 0;
    800042dc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800042e0:	8526                	mv	a0,s1
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	cfa080e7          	jalr	-774(ra) # 80003fdc <iupdate>
    ip->valid = 0;
    800042ea:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800042ee:	854a                	mv	a0,s2
    800042f0:	00001097          	auipc	ra,0x1
    800042f4:	ae0080e7          	jalr	-1312(ra) # 80004dd0 <releasesleep>
    acquire(&itable.lock);
    800042f8:	0002c517          	auipc	a0,0x2c
    800042fc:	ae850513          	addi	a0,a0,-1304 # 8002fde0 <itable>
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	91c080e7          	jalr	-1764(ra) # 80000c1c <acquire>
    80004308:	b741                	j	80004288 <iput+0x26>

000000008000430a <iunlockput>:
{
    8000430a:	1101                	addi	sp,sp,-32
    8000430c:	ec06                	sd	ra,24(sp)
    8000430e:	e822                	sd	s0,16(sp)
    80004310:	e426                	sd	s1,8(sp)
    80004312:	1000                	addi	s0,sp,32
    80004314:	84aa                	mv	s1,a0
  iunlock(ip);
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	e54080e7          	jalr	-428(ra) # 8000416a <iunlock>
  iput(ip);
    8000431e:	8526                	mv	a0,s1
    80004320:	00000097          	auipc	ra,0x0
    80004324:	f42080e7          	jalr	-190(ra) # 80004262 <iput>
}
    80004328:	60e2                	ld	ra,24(sp)
    8000432a:	6442                	ld	s0,16(sp)
    8000432c:	64a2                	ld	s1,8(sp)
    8000432e:	6105                	addi	sp,sp,32
    80004330:	8082                	ret

0000000080004332 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004332:	1141                	addi	sp,sp,-16
    80004334:	e422                	sd	s0,8(sp)
    80004336:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004338:	411c                	lw	a5,0(a0)
    8000433a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000433c:	415c                	lw	a5,4(a0)
    8000433e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004340:	04451783          	lh	a5,68(a0)
    80004344:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004348:	04a51783          	lh	a5,74(a0)
    8000434c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004350:	04c56783          	lwu	a5,76(a0)
    80004354:	e99c                	sd	a5,16(a1)
}
    80004356:	6422                	ld	s0,8(sp)
    80004358:	0141                	addi	sp,sp,16
    8000435a:	8082                	ret

000000008000435c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000435c:	457c                	lw	a5,76(a0)
    8000435e:	0ed7e963          	bltu	a5,a3,80004450 <readi+0xf4>
{
    80004362:	7159                	addi	sp,sp,-112
    80004364:	f486                	sd	ra,104(sp)
    80004366:	f0a2                	sd	s0,96(sp)
    80004368:	eca6                	sd	s1,88(sp)
    8000436a:	e8ca                	sd	s2,80(sp)
    8000436c:	e4ce                	sd	s3,72(sp)
    8000436e:	e0d2                	sd	s4,64(sp)
    80004370:	fc56                	sd	s5,56(sp)
    80004372:	f85a                	sd	s6,48(sp)
    80004374:	f45e                	sd	s7,40(sp)
    80004376:	f062                	sd	s8,32(sp)
    80004378:	ec66                	sd	s9,24(sp)
    8000437a:	e86a                	sd	s10,16(sp)
    8000437c:	e46e                	sd	s11,8(sp)
    8000437e:	1880                	addi	s0,sp,112
    80004380:	8baa                	mv	s7,a0
    80004382:	8c2e                	mv	s8,a1
    80004384:	8ab2                	mv	s5,a2
    80004386:	84b6                	mv	s1,a3
    80004388:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000438a:	9f35                	addw	a4,a4,a3
    return 0;
    8000438c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000438e:	0ad76063          	bltu	a4,a3,8000442e <readi+0xd2>
  if(off + n > ip->size)
    80004392:	00e7f463          	bgeu	a5,a4,8000439a <readi+0x3e>
    n = ip->size - off;
    80004396:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000439a:	0a0b0963          	beqz	s6,8000444c <readi+0xf0>
    8000439e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800043a0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800043a4:	5cfd                	li	s9,-1
    800043a6:	a82d                	j	800043e0 <readi+0x84>
    800043a8:	020a1d93          	slli	s11,s4,0x20
    800043ac:	020ddd93          	srli	s11,s11,0x20
    800043b0:	05890613          	addi	a2,s2,88
    800043b4:	86ee                	mv	a3,s11
    800043b6:	963a                	add	a2,a2,a4
    800043b8:	85d6                	mv	a1,s5
    800043ba:	8562                	mv	a0,s8
    800043bc:	ffffe097          	auipc	ra,0xffffe
    800043c0:	de2080e7          	jalr	-542(ra) # 8000219e <either_copyout>
    800043c4:	05950d63          	beq	a0,s9,8000441e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800043c8:	854a                	mv	a0,s2
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	60c080e7          	jalr	1548(ra) # 800039d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043d2:	013a09bb          	addw	s3,s4,s3
    800043d6:	009a04bb          	addw	s1,s4,s1
    800043da:	9aee                	add	s5,s5,s11
    800043dc:	0569f763          	bgeu	s3,s6,8000442a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043e0:	000ba903          	lw	s2,0(s7)
    800043e4:	00a4d59b          	srliw	a1,s1,0xa
    800043e8:	855e                	mv	a0,s7
    800043ea:	00000097          	auipc	ra,0x0
    800043ee:	8ac080e7          	jalr	-1876(ra) # 80003c96 <bmap>
    800043f2:	0005059b          	sext.w	a1,a0
    800043f6:	854a                	mv	a0,s2
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	4ae080e7          	jalr	1198(ra) # 800038a6 <bread>
    80004400:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004402:	3ff4f713          	andi	a4,s1,1023
    80004406:	40ed07bb          	subw	a5,s10,a4
    8000440a:	413b06bb          	subw	a3,s6,s3
    8000440e:	8a3e                	mv	s4,a5
    80004410:	2781                	sext.w	a5,a5
    80004412:	0006861b          	sext.w	a2,a3
    80004416:	f8f679e3          	bgeu	a2,a5,800043a8 <readi+0x4c>
    8000441a:	8a36                	mv	s4,a3
    8000441c:	b771                	j	800043a8 <readi+0x4c>
      brelse(bp);
    8000441e:	854a                	mv	a0,s2
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	5b6080e7          	jalr	1462(ra) # 800039d6 <brelse>
      tot = -1;
    80004428:	59fd                	li	s3,-1
  }
  return tot;
    8000442a:	0009851b          	sext.w	a0,s3
}
    8000442e:	70a6                	ld	ra,104(sp)
    80004430:	7406                	ld	s0,96(sp)
    80004432:	64e6                	ld	s1,88(sp)
    80004434:	6946                	ld	s2,80(sp)
    80004436:	69a6                	ld	s3,72(sp)
    80004438:	6a06                	ld	s4,64(sp)
    8000443a:	7ae2                	ld	s5,56(sp)
    8000443c:	7b42                	ld	s6,48(sp)
    8000443e:	7ba2                	ld	s7,40(sp)
    80004440:	7c02                	ld	s8,32(sp)
    80004442:	6ce2                	ld	s9,24(sp)
    80004444:	6d42                	ld	s10,16(sp)
    80004446:	6da2                	ld	s11,8(sp)
    80004448:	6165                	addi	sp,sp,112
    8000444a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000444c:	89da                	mv	s3,s6
    8000444e:	bff1                	j	8000442a <readi+0xce>
    return 0;
    80004450:	4501                	li	a0,0
}
    80004452:	8082                	ret

0000000080004454 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004454:	457c                	lw	a5,76(a0)
    80004456:	10d7e863          	bltu	a5,a3,80004566 <writei+0x112>
{
    8000445a:	7159                	addi	sp,sp,-112
    8000445c:	f486                	sd	ra,104(sp)
    8000445e:	f0a2                	sd	s0,96(sp)
    80004460:	eca6                	sd	s1,88(sp)
    80004462:	e8ca                	sd	s2,80(sp)
    80004464:	e4ce                	sd	s3,72(sp)
    80004466:	e0d2                	sd	s4,64(sp)
    80004468:	fc56                	sd	s5,56(sp)
    8000446a:	f85a                	sd	s6,48(sp)
    8000446c:	f45e                	sd	s7,40(sp)
    8000446e:	f062                	sd	s8,32(sp)
    80004470:	ec66                	sd	s9,24(sp)
    80004472:	e86a                	sd	s10,16(sp)
    80004474:	e46e                	sd	s11,8(sp)
    80004476:	1880                	addi	s0,sp,112
    80004478:	8b2a                	mv	s6,a0
    8000447a:	8c2e                	mv	s8,a1
    8000447c:	8ab2                	mv	s5,a2
    8000447e:	8936                	mv	s2,a3
    80004480:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004482:	00e687bb          	addw	a5,a3,a4
    80004486:	0ed7e263          	bltu	a5,a3,8000456a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000448a:	00043737          	lui	a4,0x43
    8000448e:	0ef76063          	bltu	a4,a5,8000456e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004492:	0c0b8863          	beqz	s7,80004562 <writei+0x10e>
    80004496:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004498:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000449c:	5cfd                	li	s9,-1
    8000449e:	a091                	j	800044e2 <writei+0x8e>
    800044a0:	02099d93          	slli	s11,s3,0x20
    800044a4:	020ddd93          	srli	s11,s11,0x20
    800044a8:	05848513          	addi	a0,s1,88
    800044ac:	86ee                	mv	a3,s11
    800044ae:	8656                	mv	a2,s5
    800044b0:	85e2                	mv	a1,s8
    800044b2:	953a                	add	a0,a0,a4
    800044b4:	ffffe097          	auipc	ra,0xffffe
    800044b8:	d42080e7          	jalr	-702(ra) # 800021f6 <either_copyin>
    800044bc:	07950263          	beq	a0,s9,80004520 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800044c0:	8526                	mv	a0,s1
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	798080e7          	jalr	1944(ra) # 80004c5a <log_write>
    brelse(bp);
    800044ca:	8526                	mv	a0,s1
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	50a080e7          	jalr	1290(ra) # 800039d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044d4:	01498a3b          	addw	s4,s3,s4
    800044d8:	0129893b          	addw	s2,s3,s2
    800044dc:	9aee                	add	s5,s5,s11
    800044de:	057a7663          	bgeu	s4,s7,8000452a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800044e2:	000b2483          	lw	s1,0(s6)
    800044e6:	00a9559b          	srliw	a1,s2,0xa
    800044ea:	855a                	mv	a0,s6
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	7aa080e7          	jalr	1962(ra) # 80003c96 <bmap>
    800044f4:	0005059b          	sext.w	a1,a0
    800044f8:	8526                	mv	a0,s1
    800044fa:	fffff097          	auipc	ra,0xfffff
    800044fe:	3ac080e7          	jalr	940(ra) # 800038a6 <bread>
    80004502:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004504:	3ff97713          	andi	a4,s2,1023
    80004508:	40ed07bb          	subw	a5,s10,a4
    8000450c:	414b86bb          	subw	a3,s7,s4
    80004510:	89be                	mv	s3,a5
    80004512:	2781                	sext.w	a5,a5
    80004514:	0006861b          	sext.w	a2,a3
    80004518:	f8f674e3          	bgeu	a2,a5,800044a0 <writei+0x4c>
    8000451c:	89b6                	mv	s3,a3
    8000451e:	b749                	j	800044a0 <writei+0x4c>
      brelse(bp);
    80004520:	8526                	mv	a0,s1
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	4b4080e7          	jalr	1204(ra) # 800039d6 <brelse>
  }

  if(off > ip->size)
    8000452a:	04cb2783          	lw	a5,76(s6)
    8000452e:	0127f463          	bgeu	a5,s2,80004536 <writei+0xe2>
    ip->size = off;
    80004532:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004536:	855a                	mv	a0,s6
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	aa4080e7          	jalr	-1372(ra) # 80003fdc <iupdate>

  return tot;
    80004540:	000a051b          	sext.w	a0,s4
}
    80004544:	70a6                	ld	ra,104(sp)
    80004546:	7406                	ld	s0,96(sp)
    80004548:	64e6                	ld	s1,88(sp)
    8000454a:	6946                	ld	s2,80(sp)
    8000454c:	69a6                	ld	s3,72(sp)
    8000454e:	6a06                	ld	s4,64(sp)
    80004550:	7ae2                	ld	s5,56(sp)
    80004552:	7b42                	ld	s6,48(sp)
    80004554:	7ba2                	ld	s7,40(sp)
    80004556:	7c02                	ld	s8,32(sp)
    80004558:	6ce2                	ld	s9,24(sp)
    8000455a:	6d42                	ld	s10,16(sp)
    8000455c:	6da2                	ld	s11,8(sp)
    8000455e:	6165                	addi	sp,sp,112
    80004560:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004562:	8a5e                	mv	s4,s7
    80004564:	bfc9                	j	80004536 <writei+0xe2>
    return -1;
    80004566:	557d                	li	a0,-1
}
    80004568:	8082                	ret
    return -1;
    8000456a:	557d                	li	a0,-1
    8000456c:	bfe1                	j	80004544 <writei+0xf0>
    return -1;
    8000456e:	557d                	li	a0,-1
    80004570:	bfd1                	j	80004544 <writei+0xf0>

0000000080004572 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004572:	1141                	addi	sp,sp,-16
    80004574:	e406                	sd	ra,8(sp)
    80004576:	e022                	sd	s0,0(sp)
    80004578:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000457a:	4639                	li	a2,14
    8000457c:	ffffd097          	auipc	ra,0xffffd
    80004580:	86c080e7          	jalr	-1940(ra) # 80000de8 <strncmp>
}
    80004584:	60a2                	ld	ra,8(sp)
    80004586:	6402                	ld	s0,0(sp)
    80004588:	0141                	addi	sp,sp,16
    8000458a:	8082                	ret

000000008000458c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000458c:	7139                	addi	sp,sp,-64
    8000458e:	fc06                	sd	ra,56(sp)
    80004590:	f822                	sd	s0,48(sp)
    80004592:	f426                	sd	s1,40(sp)
    80004594:	f04a                	sd	s2,32(sp)
    80004596:	ec4e                	sd	s3,24(sp)
    80004598:	e852                	sd	s4,16(sp)
    8000459a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000459c:	04451703          	lh	a4,68(a0)
    800045a0:	4785                	li	a5,1
    800045a2:	00f71a63          	bne	a4,a5,800045b6 <dirlookup+0x2a>
    800045a6:	892a                	mv	s2,a0
    800045a8:	89ae                	mv	s3,a1
    800045aa:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ac:	457c                	lw	a5,76(a0)
    800045ae:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800045b0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045b2:	e79d                	bnez	a5,800045e0 <dirlookup+0x54>
    800045b4:	a8a5                	j	8000462c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	08a50513          	addi	a0,a0,138 # 80008640 <syscalls+0x1e0>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f7e080e7          	jalr	-130(ra) # 8000053c <panic>
      panic("dirlookup read");
    800045c6:	00004517          	auipc	a0,0x4
    800045ca:	09250513          	addi	a0,a0,146 # 80008658 <syscalls+0x1f8>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	f6e080e7          	jalr	-146(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045d6:	24c1                	addiw	s1,s1,16
    800045d8:	04c92783          	lw	a5,76(s2)
    800045dc:	04f4f763          	bgeu	s1,a5,8000462a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045e0:	4741                	li	a4,16
    800045e2:	86a6                	mv	a3,s1
    800045e4:	fc040613          	addi	a2,s0,-64
    800045e8:	4581                	li	a1,0
    800045ea:	854a                	mv	a0,s2
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	d70080e7          	jalr	-656(ra) # 8000435c <readi>
    800045f4:	47c1                	li	a5,16
    800045f6:	fcf518e3          	bne	a0,a5,800045c6 <dirlookup+0x3a>
    if(de.inum == 0)
    800045fa:	fc045783          	lhu	a5,-64(s0)
    800045fe:	dfe1                	beqz	a5,800045d6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004600:	fc240593          	addi	a1,s0,-62
    80004604:	854e                	mv	a0,s3
    80004606:	00000097          	auipc	ra,0x0
    8000460a:	f6c080e7          	jalr	-148(ra) # 80004572 <namecmp>
    8000460e:	f561                	bnez	a0,800045d6 <dirlookup+0x4a>
      if(poff)
    80004610:	000a0463          	beqz	s4,80004618 <dirlookup+0x8c>
        *poff = off;
    80004614:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004618:	fc045583          	lhu	a1,-64(s0)
    8000461c:	00092503          	lw	a0,0(s2)
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	752080e7          	jalr	1874(ra) # 80003d72 <iget>
    80004628:	a011                	j	8000462c <dirlookup+0xa0>
  return 0;
    8000462a:	4501                	li	a0,0
}
    8000462c:	70e2                	ld	ra,56(sp)
    8000462e:	7442                	ld	s0,48(sp)
    80004630:	74a2                	ld	s1,40(sp)
    80004632:	7902                	ld	s2,32(sp)
    80004634:	69e2                	ld	s3,24(sp)
    80004636:	6a42                	ld	s4,16(sp)
    80004638:	6121                	addi	sp,sp,64
    8000463a:	8082                	ret

000000008000463c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000463c:	711d                	addi	sp,sp,-96
    8000463e:	ec86                	sd	ra,88(sp)
    80004640:	e8a2                	sd	s0,80(sp)
    80004642:	e4a6                	sd	s1,72(sp)
    80004644:	e0ca                	sd	s2,64(sp)
    80004646:	fc4e                	sd	s3,56(sp)
    80004648:	f852                	sd	s4,48(sp)
    8000464a:	f456                	sd	s5,40(sp)
    8000464c:	f05a                	sd	s6,32(sp)
    8000464e:	ec5e                	sd	s7,24(sp)
    80004650:	e862                	sd	s8,16(sp)
    80004652:	e466                	sd	s9,8(sp)
    80004654:	e06a                	sd	s10,0(sp)
    80004656:	1080                	addi	s0,sp,96
    80004658:	84aa                	mv	s1,a0
    8000465a:	8b2e                	mv	s6,a1
    8000465c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000465e:	00054703          	lbu	a4,0(a0)
    80004662:	02f00793          	li	a5,47
    80004666:	02f70363          	beq	a4,a5,8000468c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000466a:	ffffd097          	auipc	ra,0xffffd
    8000466e:	48a080e7          	jalr	1162(ra) # 80001af4 <myproc>
    80004672:	42853503          	ld	a0,1064(a0)
    80004676:	00000097          	auipc	ra,0x0
    8000467a:	9f4080e7          	jalr	-1548(ra) # 8000406a <idup>
    8000467e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004680:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004684:	4cb5                	li	s9,13
  len = path - s;
    80004686:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004688:	4c05                	li	s8,1
    8000468a:	a87d                	j	80004748 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000468c:	4585                	li	a1,1
    8000468e:	4505                	li	a0,1
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	6e2080e7          	jalr	1762(ra) # 80003d72 <iget>
    80004698:	8a2a                	mv	s4,a0
    8000469a:	b7dd                	j	80004680 <namex+0x44>
      iunlockput(ip);
    8000469c:	8552                	mv	a0,s4
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	c6c080e7          	jalr	-916(ra) # 8000430a <iunlockput>
      return 0;
    800046a6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800046a8:	8552                	mv	a0,s4
    800046aa:	60e6                	ld	ra,88(sp)
    800046ac:	6446                	ld	s0,80(sp)
    800046ae:	64a6                	ld	s1,72(sp)
    800046b0:	6906                	ld	s2,64(sp)
    800046b2:	79e2                	ld	s3,56(sp)
    800046b4:	7a42                	ld	s4,48(sp)
    800046b6:	7aa2                	ld	s5,40(sp)
    800046b8:	7b02                	ld	s6,32(sp)
    800046ba:	6be2                	ld	s7,24(sp)
    800046bc:	6c42                	ld	s8,16(sp)
    800046be:	6ca2                	ld	s9,8(sp)
    800046c0:	6d02                	ld	s10,0(sp)
    800046c2:	6125                	addi	sp,sp,96
    800046c4:	8082                	ret
      iunlock(ip);
    800046c6:	8552                	mv	a0,s4
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	aa2080e7          	jalr	-1374(ra) # 8000416a <iunlock>
      return ip;
    800046d0:	bfe1                	j	800046a8 <namex+0x6c>
      iunlockput(ip);
    800046d2:	8552                	mv	a0,s4
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	c36080e7          	jalr	-970(ra) # 8000430a <iunlockput>
      return 0;
    800046dc:	8a4e                	mv	s4,s3
    800046de:	b7e9                	j	800046a8 <namex+0x6c>
  len = path - s;
    800046e0:	40998633          	sub	a2,s3,s1
    800046e4:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800046e8:	09acd863          	bge	s9,s10,80004778 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800046ec:	4639                	li	a2,14
    800046ee:	85a6                	mv	a1,s1
    800046f0:	8556                	mv	a0,s5
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	682080e7          	jalr	1666(ra) # 80000d74 <memmove>
    800046fa:	84ce                	mv	s1,s3
  while(*path == '/')
    800046fc:	0004c783          	lbu	a5,0(s1)
    80004700:	01279763          	bne	a5,s2,8000470e <namex+0xd2>
    path++;
    80004704:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004706:	0004c783          	lbu	a5,0(s1)
    8000470a:	ff278de3          	beq	a5,s2,80004704 <namex+0xc8>
    ilock(ip);
    8000470e:	8552                	mv	a0,s4
    80004710:	00000097          	auipc	ra,0x0
    80004714:	998080e7          	jalr	-1640(ra) # 800040a8 <ilock>
    if(ip->type != T_DIR){
    80004718:	044a1783          	lh	a5,68(s4)
    8000471c:	f98790e3          	bne	a5,s8,8000469c <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004720:	000b0563          	beqz	s6,8000472a <namex+0xee>
    80004724:	0004c783          	lbu	a5,0(s1)
    80004728:	dfd9                	beqz	a5,800046c6 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000472a:	865e                	mv	a2,s7
    8000472c:	85d6                	mv	a1,s5
    8000472e:	8552                	mv	a0,s4
    80004730:	00000097          	auipc	ra,0x0
    80004734:	e5c080e7          	jalr	-420(ra) # 8000458c <dirlookup>
    80004738:	89aa                	mv	s3,a0
    8000473a:	dd41                	beqz	a0,800046d2 <namex+0x96>
    iunlockput(ip);
    8000473c:	8552                	mv	a0,s4
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	bcc080e7          	jalr	-1076(ra) # 8000430a <iunlockput>
    ip = next;
    80004746:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004748:	0004c783          	lbu	a5,0(s1)
    8000474c:	01279763          	bne	a5,s2,8000475a <namex+0x11e>
    path++;
    80004750:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004752:	0004c783          	lbu	a5,0(s1)
    80004756:	ff278de3          	beq	a5,s2,80004750 <namex+0x114>
  if(*path == 0)
    8000475a:	cb9d                	beqz	a5,80004790 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000475c:	0004c783          	lbu	a5,0(s1)
    80004760:	89a6                	mv	s3,s1
  len = path - s;
    80004762:	8d5e                	mv	s10,s7
    80004764:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004766:	01278963          	beq	a5,s2,80004778 <namex+0x13c>
    8000476a:	dbbd                	beqz	a5,800046e0 <namex+0xa4>
    path++;
    8000476c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000476e:	0009c783          	lbu	a5,0(s3)
    80004772:	ff279ce3          	bne	a5,s2,8000476a <namex+0x12e>
    80004776:	b7ad                	j	800046e0 <namex+0xa4>
    memmove(name, s, len);
    80004778:	2601                	sext.w	a2,a2
    8000477a:	85a6                	mv	a1,s1
    8000477c:	8556                	mv	a0,s5
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	5f6080e7          	jalr	1526(ra) # 80000d74 <memmove>
    name[len] = 0;
    80004786:	9d56                	add	s10,s10,s5
    80004788:	000d0023          	sb	zero,0(s10)
    8000478c:	84ce                	mv	s1,s3
    8000478e:	b7bd                	j	800046fc <namex+0xc0>
  if(nameiparent){
    80004790:	f00b0ce3          	beqz	s6,800046a8 <namex+0x6c>
    iput(ip);
    80004794:	8552                	mv	a0,s4
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	acc080e7          	jalr	-1332(ra) # 80004262 <iput>
    return 0;
    8000479e:	4a01                	li	s4,0
    800047a0:	b721                	j	800046a8 <namex+0x6c>

00000000800047a2 <dirlink>:
{
    800047a2:	7139                	addi	sp,sp,-64
    800047a4:	fc06                	sd	ra,56(sp)
    800047a6:	f822                	sd	s0,48(sp)
    800047a8:	f426                	sd	s1,40(sp)
    800047aa:	f04a                	sd	s2,32(sp)
    800047ac:	ec4e                	sd	s3,24(sp)
    800047ae:	e852                	sd	s4,16(sp)
    800047b0:	0080                	addi	s0,sp,64
    800047b2:	892a                	mv	s2,a0
    800047b4:	8a2e                	mv	s4,a1
    800047b6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800047b8:	4601                	li	a2,0
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	dd2080e7          	jalr	-558(ra) # 8000458c <dirlookup>
    800047c2:	e93d                	bnez	a0,80004838 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047c4:	04c92483          	lw	s1,76(s2)
    800047c8:	c49d                	beqz	s1,800047f6 <dirlink+0x54>
    800047ca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047cc:	4741                	li	a4,16
    800047ce:	86a6                	mv	a3,s1
    800047d0:	fc040613          	addi	a2,s0,-64
    800047d4:	4581                	li	a1,0
    800047d6:	854a                	mv	a0,s2
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	b84080e7          	jalr	-1148(ra) # 8000435c <readi>
    800047e0:	47c1                	li	a5,16
    800047e2:	06f51163          	bne	a0,a5,80004844 <dirlink+0xa2>
    if(de.inum == 0)
    800047e6:	fc045783          	lhu	a5,-64(s0)
    800047ea:	c791                	beqz	a5,800047f6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047ec:	24c1                	addiw	s1,s1,16
    800047ee:	04c92783          	lw	a5,76(s2)
    800047f2:	fcf4ede3          	bltu	s1,a5,800047cc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800047f6:	4639                	li	a2,14
    800047f8:	85d2                	mv	a1,s4
    800047fa:	fc240513          	addi	a0,s0,-62
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	626080e7          	jalr	1574(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80004806:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000480a:	4741                	li	a4,16
    8000480c:	86a6                	mv	a3,s1
    8000480e:	fc040613          	addi	a2,s0,-64
    80004812:	4581                	li	a1,0
    80004814:	854a                	mv	a0,s2
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	c3e080e7          	jalr	-962(ra) # 80004454 <writei>
    8000481e:	872a                	mv	a4,a0
    80004820:	47c1                	li	a5,16
  return 0;
    80004822:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004824:	02f71863          	bne	a4,a5,80004854 <dirlink+0xb2>
}
    80004828:	70e2                	ld	ra,56(sp)
    8000482a:	7442                	ld	s0,48(sp)
    8000482c:	74a2                	ld	s1,40(sp)
    8000482e:	7902                	ld	s2,32(sp)
    80004830:	69e2                	ld	s3,24(sp)
    80004832:	6a42                	ld	s4,16(sp)
    80004834:	6121                	addi	sp,sp,64
    80004836:	8082                	ret
    iput(ip);
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	a2a080e7          	jalr	-1494(ra) # 80004262 <iput>
    return -1;
    80004840:	557d                	li	a0,-1
    80004842:	b7dd                	j	80004828 <dirlink+0x86>
      panic("dirlink read");
    80004844:	00004517          	auipc	a0,0x4
    80004848:	e2450513          	addi	a0,a0,-476 # 80008668 <syscalls+0x208>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	cf0080e7          	jalr	-784(ra) # 8000053c <panic>
    panic("dirlink");
    80004854:	00004517          	auipc	a0,0x4
    80004858:	f2450513          	addi	a0,a0,-220 # 80008778 <syscalls+0x318>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	ce0080e7          	jalr	-800(ra) # 8000053c <panic>

0000000080004864 <namei>:

struct inode*
namei(char *path)
{
    80004864:	1101                	addi	sp,sp,-32
    80004866:	ec06                	sd	ra,24(sp)
    80004868:	e822                	sd	s0,16(sp)
    8000486a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000486c:	fe040613          	addi	a2,s0,-32
    80004870:	4581                	li	a1,0
    80004872:	00000097          	auipc	ra,0x0
    80004876:	dca080e7          	jalr	-566(ra) # 8000463c <namex>
}
    8000487a:	60e2                	ld	ra,24(sp)
    8000487c:	6442                	ld	s0,16(sp)
    8000487e:	6105                	addi	sp,sp,32
    80004880:	8082                	ret

0000000080004882 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004882:	1141                	addi	sp,sp,-16
    80004884:	e406                	sd	ra,8(sp)
    80004886:	e022                	sd	s0,0(sp)
    80004888:	0800                	addi	s0,sp,16
    8000488a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000488c:	4585                	li	a1,1
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	dae080e7          	jalr	-594(ra) # 8000463c <namex>
}
    80004896:	60a2                	ld	ra,8(sp)
    80004898:	6402                	ld	s0,0(sp)
    8000489a:	0141                	addi	sp,sp,16
    8000489c:	8082                	ret

000000008000489e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000489e:	1101                	addi	sp,sp,-32
    800048a0:	ec06                	sd	ra,24(sp)
    800048a2:	e822                	sd	s0,16(sp)
    800048a4:	e426                	sd	s1,8(sp)
    800048a6:	e04a                	sd	s2,0(sp)
    800048a8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800048aa:	0002d917          	auipc	s2,0x2d
    800048ae:	fde90913          	addi	s2,s2,-34 # 80031888 <log>
    800048b2:	01892583          	lw	a1,24(s2)
    800048b6:	02892503          	lw	a0,40(s2)
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	fec080e7          	jalr	-20(ra) # 800038a6 <bread>
    800048c2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800048c4:	02c92683          	lw	a3,44(s2)
    800048c8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800048ca:	02d05863          	blez	a3,800048fa <write_head+0x5c>
    800048ce:	0002d797          	auipc	a5,0x2d
    800048d2:	fea78793          	addi	a5,a5,-22 # 800318b8 <log+0x30>
    800048d6:	05c50713          	addi	a4,a0,92
    800048da:	36fd                	addiw	a3,a3,-1
    800048dc:	02069613          	slli	a2,a3,0x20
    800048e0:	01e65693          	srli	a3,a2,0x1e
    800048e4:	0002d617          	auipc	a2,0x2d
    800048e8:	fd860613          	addi	a2,a2,-40 # 800318bc <log+0x34>
    800048ec:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800048ee:	4390                	lw	a2,0(a5)
    800048f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800048f2:	0791                	addi	a5,a5,4
    800048f4:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800048f6:	fed79ce3          	bne	a5,a3,800048ee <write_head+0x50>
  }
  bwrite(buf);
    800048fa:	8526                	mv	a0,s1
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	09c080e7          	jalr	156(ra) # 80003998 <bwrite>
  brelse(buf);
    80004904:	8526                	mv	a0,s1
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	0d0080e7          	jalr	208(ra) # 800039d6 <brelse>
}
    8000490e:	60e2                	ld	ra,24(sp)
    80004910:	6442                	ld	s0,16(sp)
    80004912:	64a2                	ld	s1,8(sp)
    80004914:	6902                	ld	s2,0(sp)
    80004916:	6105                	addi	sp,sp,32
    80004918:	8082                	ret

000000008000491a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000491a:	0002d797          	auipc	a5,0x2d
    8000491e:	f9a7a783          	lw	a5,-102(a5) # 800318b4 <log+0x2c>
    80004922:	0af05d63          	blez	a5,800049dc <install_trans+0xc2>
{
    80004926:	7139                	addi	sp,sp,-64
    80004928:	fc06                	sd	ra,56(sp)
    8000492a:	f822                	sd	s0,48(sp)
    8000492c:	f426                	sd	s1,40(sp)
    8000492e:	f04a                	sd	s2,32(sp)
    80004930:	ec4e                	sd	s3,24(sp)
    80004932:	e852                	sd	s4,16(sp)
    80004934:	e456                	sd	s5,8(sp)
    80004936:	e05a                	sd	s6,0(sp)
    80004938:	0080                	addi	s0,sp,64
    8000493a:	8b2a                	mv	s6,a0
    8000493c:	0002da97          	auipc	s5,0x2d
    80004940:	f7ca8a93          	addi	s5,s5,-132 # 800318b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004944:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004946:	0002d997          	auipc	s3,0x2d
    8000494a:	f4298993          	addi	s3,s3,-190 # 80031888 <log>
    8000494e:	a00d                	j	80004970 <install_trans+0x56>
    brelse(lbuf);
    80004950:	854a                	mv	a0,s2
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	084080e7          	jalr	132(ra) # 800039d6 <brelse>
    brelse(dbuf);
    8000495a:	8526                	mv	a0,s1
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	07a080e7          	jalr	122(ra) # 800039d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004964:	2a05                	addiw	s4,s4,1
    80004966:	0a91                	addi	s5,s5,4
    80004968:	02c9a783          	lw	a5,44(s3)
    8000496c:	04fa5e63          	bge	s4,a5,800049c8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004970:	0189a583          	lw	a1,24(s3)
    80004974:	014585bb          	addw	a1,a1,s4
    80004978:	2585                	addiw	a1,a1,1
    8000497a:	0289a503          	lw	a0,40(s3)
    8000497e:	fffff097          	auipc	ra,0xfffff
    80004982:	f28080e7          	jalr	-216(ra) # 800038a6 <bread>
    80004986:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004988:	000aa583          	lw	a1,0(s5)
    8000498c:	0289a503          	lw	a0,40(s3)
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	f16080e7          	jalr	-234(ra) # 800038a6 <bread>
    80004998:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000499a:	40000613          	li	a2,1024
    8000499e:	05890593          	addi	a1,s2,88
    800049a2:	05850513          	addi	a0,a0,88
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	3ce080e7          	jalr	974(ra) # 80000d74 <memmove>
    bwrite(dbuf);  // write dst to disk
    800049ae:	8526                	mv	a0,s1
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	fe8080e7          	jalr	-24(ra) # 80003998 <bwrite>
    if(recovering == 0)
    800049b8:	f80b1ce3          	bnez	s6,80004950 <install_trans+0x36>
      bunpin(dbuf);
    800049bc:	8526                	mv	a0,s1
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	0f2080e7          	jalr	242(ra) # 80003ab0 <bunpin>
    800049c6:	b769                	j	80004950 <install_trans+0x36>
}
    800049c8:	70e2                	ld	ra,56(sp)
    800049ca:	7442                	ld	s0,48(sp)
    800049cc:	74a2                	ld	s1,40(sp)
    800049ce:	7902                	ld	s2,32(sp)
    800049d0:	69e2                	ld	s3,24(sp)
    800049d2:	6a42                	ld	s4,16(sp)
    800049d4:	6aa2                	ld	s5,8(sp)
    800049d6:	6b02                	ld	s6,0(sp)
    800049d8:	6121                	addi	sp,sp,64
    800049da:	8082                	ret
    800049dc:	8082                	ret

00000000800049de <initlog>:
{
    800049de:	7179                	addi	sp,sp,-48
    800049e0:	f406                	sd	ra,40(sp)
    800049e2:	f022                	sd	s0,32(sp)
    800049e4:	ec26                	sd	s1,24(sp)
    800049e6:	e84a                	sd	s2,16(sp)
    800049e8:	e44e                	sd	s3,8(sp)
    800049ea:	1800                	addi	s0,sp,48
    800049ec:	892a                	mv	s2,a0
    800049ee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800049f0:	0002d497          	auipc	s1,0x2d
    800049f4:	e9848493          	addi	s1,s1,-360 # 80031888 <log>
    800049f8:	00004597          	auipc	a1,0x4
    800049fc:	c8058593          	addi	a1,a1,-896 # 80008678 <syscalls+0x218>
    80004a00:	8526                	mv	a0,s1
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	18a080e7          	jalr	394(ra) # 80000b8c <initlock>
  log.start = sb->logstart;
    80004a0a:	0149a583          	lw	a1,20(s3)
    80004a0e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004a10:	0109a783          	lw	a5,16(s3)
    80004a14:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004a16:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	e8a080e7          	jalr	-374(ra) # 800038a6 <bread>
  log.lh.n = lh->n;
    80004a24:	4d34                	lw	a3,88(a0)
    80004a26:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004a28:	02d05663          	blez	a3,80004a54 <initlog+0x76>
    80004a2c:	05c50793          	addi	a5,a0,92
    80004a30:	0002d717          	auipc	a4,0x2d
    80004a34:	e8870713          	addi	a4,a4,-376 # 800318b8 <log+0x30>
    80004a38:	36fd                	addiw	a3,a3,-1
    80004a3a:	02069613          	slli	a2,a3,0x20
    80004a3e:	01e65693          	srli	a3,a2,0x1e
    80004a42:	06050613          	addi	a2,a0,96
    80004a46:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004a48:	4390                	lw	a2,0(a5)
    80004a4a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a4c:	0791                	addi	a5,a5,4
    80004a4e:	0711                	addi	a4,a4,4
    80004a50:	fed79ce3          	bne	a5,a3,80004a48 <initlog+0x6a>
  brelse(buf);
    80004a54:	fffff097          	auipc	ra,0xfffff
    80004a58:	f82080e7          	jalr	-126(ra) # 800039d6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004a5c:	4505                	li	a0,1
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	ebc080e7          	jalr	-324(ra) # 8000491a <install_trans>
  log.lh.n = 0;
    80004a66:	0002d797          	auipc	a5,0x2d
    80004a6a:	e407a723          	sw	zero,-434(a5) # 800318b4 <log+0x2c>
  write_head(); // clear the log
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	e30080e7          	jalr	-464(ra) # 8000489e <write_head>
}
    80004a76:	70a2                	ld	ra,40(sp)
    80004a78:	7402                	ld	s0,32(sp)
    80004a7a:	64e2                	ld	s1,24(sp)
    80004a7c:	6942                	ld	s2,16(sp)
    80004a7e:	69a2                	ld	s3,8(sp)
    80004a80:	6145                	addi	sp,sp,48
    80004a82:	8082                	ret

0000000080004a84 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a84:	1101                	addi	sp,sp,-32
    80004a86:	ec06                	sd	ra,24(sp)
    80004a88:	e822                	sd	s0,16(sp)
    80004a8a:	e426                	sd	s1,8(sp)
    80004a8c:	e04a                	sd	s2,0(sp)
    80004a8e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a90:	0002d517          	auipc	a0,0x2d
    80004a94:	df850513          	addi	a0,a0,-520 # 80031888 <log>
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	184080e7          	jalr	388(ra) # 80000c1c <acquire>
  while(1){
    if(log.committing){
    80004aa0:	0002d497          	auipc	s1,0x2d
    80004aa4:	de848493          	addi	s1,s1,-536 # 80031888 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004aa8:	4979                	li	s2,30
    80004aaa:	a039                	j	80004ab8 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004aac:	85a6                	mv	a1,s1
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	444080e7          	jalr	1092(ra) # 80001ef4 <sleep>
    if(log.committing){
    80004ab8:	50dc                	lw	a5,36(s1)
    80004aba:	fbed                	bnez	a5,80004aac <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004abc:	5098                	lw	a4,32(s1)
    80004abe:	2705                	addiw	a4,a4,1
    80004ac0:	0007069b          	sext.w	a3,a4
    80004ac4:	0027179b          	slliw	a5,a4,0x2
    80004ac8:	9fb9                	addw	a5,a5,a4
    80004aca:	0017979b          	slliw	a5,a5,0x1
    80004ace:	54d8                	lw	a4,44(s1)
    80004ad0:	9fb9                	addw	a5,a5,a4
    80004ad2:	00f95963          	bge	s2,a5,80004ae4 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004ad6:	85a6                	mv	a1,s1
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	41a080e7          	jalr	1050(ra) # 80001ef4 <sleep>
    80004ae2:	bfd9                	j	80004ab8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004ae4:	0002d517          	auipc	a0,0x2d
    80004ae8:	da450513          	addi	a0,a0,-604 # 80031888 <log>
    80004aec:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	1e2080e7          	jalr	482(ra) # 80000cd0 <release>
      break;
    }
  }
}
    80004af6:	60e2                	ld	ra,24(sp)
    80004af8:	6442                	ld	s0,16(sp)
    80004afa:	64a2                	ld	s1,8(sp)
    80004afc:	6902                	ld	s2,0(sp)
    80004afe:	6105                	addi	sp,sp,32
    80004b00:	8082                	ret

0000000080004b02 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b02:	7139                	addi	sp,sp,-64
    80004b04:	fc06                	sd	ra,56(sp)
    80004b06:	f822                	sd	s0,48(sp)
    80004b08:	f426                	sd	s1,40(sp)
    80004b0a:	f04a                	sd	s2,32(sp)
    80004b0c:	ec4e                	sd	s3,24(sp)
    80004b0e:	e852                	sd	s4,16(sp)
    80004b10:	e456                	sd	s5,8(sp)
    80004b12:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004b14:	0002d497          	auipc	s1,0x2d
    80004b18:	d7448493          	addi	s1,s1,-652 # 80031888 <log>
    80004b1c:	8526                	mv	a0,s1
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	0fe080e7          	jalr	254(ra) # 80000c1c <acquire>
  log.outstanding -= 1;
    80004b26:	509c                	lw	a5,32(s1)
    80004b28:	37fd                	addiw	a5,a5,-1
    80004b2a:	0007891b          	sext.w	s2,a5
    80004b2e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004b30:	50dc                	lw	a5,36(s1)
    80004b32:	e7b9                	bnez	a5,80004b80 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004b34:	04091e63          	bnez	s2,80004b90 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004b38:	0002d497          	auipc	s1,0x2d
    80004b3c:	d5048493          	addi	s1,s1,-688 # 80031888 <log>
    80004b40:	4785                	li	a5,1
    80004b42:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b44:	8526                	mv	a0,s1
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	18a080e7          	jalr	394(ra) # 80000cd0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b4e:	54dc                	lw	a5,44(s1)
    80004b50:	06f04763          	bgtz	a5,80004bbe <end_op+0xbc>
    acquire(&log.lock);
    80004b54:	0002d497          	auipc	s1,0x2d
    80004b58:	d3448493          	addi	s1,s1,-716 # 80031888 <log>
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	0be080e7          	jalr	190(ra) # 80000c1c <acquire>
    log.committing = 0;
    80004b66:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	3f8080e7          	jalr	1016(ra) # 80001f64 <wakeup>
    release(&log.lock);
    80004b74:	8526                	mv	a0,s1
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	15a080e7          	jalr	346(ra) # 80000cd0 <release>
}
    80004b7e:	a03d                	j	80004bac <end_op+0xaa>
    panic("log.committing");
    80004b80:	00004517          	auipc	a0,0x4
    80004b84:	b0050513          	addi	a0,a0,-1280 # 80008680 <syscalls+0x220>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	9b4080e7          	jalr	-1612(ra) # 8000053c <panic>
    wakeup(&log);
    80004b90:	0002d497          	auipc	s1,0x2d
    80004b94:	cf848493          	addi	s1,s1,-776 # 80031888 <log>
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	3ca080e7          	jalr	970(ra) # 80001f64 <wakeup>
  release(&log.lock);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	12c080e7          	jalr	300(ra) # 80000cd0 <release>
}
    80004bac:	70e2                	ld	ra,56(sp)
    80004bae:	7442                	ld	s0,48(sp)
    80004bb0:	74a2                	ld	s1,40(sp)
    80004bb2:	7902                	ld	s2,32(sp)
    80004bb4:	69e2                	ld	s3,24(sp)
    80004bb6:	6a42                	ld	s4,16(sp)
    80004bb8:	6aa2                	ld	s5,8(sp)
    80004bba:	6121                	addi	sp,sp,64
    80004bbc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bbe:	0002da97          	auipc	s5,0x2d
    80004bc2:	cfaa8a93          	addi	s5,s5,-774 # 800318b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004bc6:	0002da17          	auipc	s4,0x2d
    80004bca:	cc2a0a13          	addi	s4,s4,-830 # 80031888 <log>
    80004bce:	018a2583          	lw	a1,24(s4)
    80004bd2:	012585bb          	addw	a1,a1,s2
    80004bd6:	2585                	addiw	a1,a1,1
    80004bd8:	028a2503          	lw	a0,40(s4)
    80004bdc:	fffff097          	auipc	ra,0xfffff
    80004be0:	cca080e7          	jalr	-822(ra) # 800038a6 <bread>
    80004be4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004be6:	000aa583          	lw	a1,0(s5)
    80004bea:	028a2503          	lw	a0,40(s4)
    80004bee:	fffff097          	auipc	ra,0xfffff
    80004bf2:	cb8080e7          	jalr	-840(ra) # 800038a6 <bread>
    80004bf6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004bf8:	40000613          	li	a2,1024
    80004bfc:	05850593          	addi	a1,a0,88
    80004c00:	05848513          	addi	a0,s1,88
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	170080e7          	jalr	368(ra) # 80000d74 <memmove>
    bwrite(to);  // write the log
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	d8a080e7          	jalr	-630(ra) # 80003998 <bwrite>
    brelse(from);
    80004c16:	854e                	mv	a0,s3
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	dbe080e7          	jalr	-578(ra) # 800039d6 <brelse>
    brelse(to);
    80004c20:	8526                	mv	a0,s1
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	db4080e7          	jalr	-588(ra) # 800039d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c2a:	2905                	addiw	s2,s2,1
    80004c2c:	0a91                	addi	s5,s5,4
    80004c2e:	02ca2783          	lw	a5,44(s4)
    80004c32:	f8f94ee3          	blt	s2,a5,80004bce <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004c36:	00000097          	auipc	ra,0x0
    80004c3a:	c68080e7          	jalr	-920(ra) # 8000489e <write_head>
    install_trans(0); // Now install writes to home locations
    80004c3e:	4501                	li	a0,0
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	cda080e7          	jalr	-806(ra) # 8000491a <install_trans>
    log.lh.n = 0;
    80004c48:	0002d797          	auipc	a5,0x2d
    80004c4c:	c607a623          	sw	zero,-916(a5) # 800318b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c50:	00000097          	auipc	ra,0x0
    80004c54:	c4e080e7          	jalr	-946(ra) # 8000489e <write_head>
    80004c58:	bdf5                	j	80004b54 <end_op+0x52>

0000000080004c5a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004c5a:	1101                	addi	sp,sp,-32
    80004c5c:	ec06                	sd	ra,24(sp)
    80004c5e:	e822                	sd	s0,16(sp)
    80004c60:	e426                	sd	s1,8(sp)
    80004c62:	e04a                	sd	s2,0(sp)
    80004c64:	1000                	addi	s0,sp,32
    80004c66:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004c68:	0002d917          	auipc	s2,0x2d
    80004c6c:	c2090913          	addi	s2,s2,-992 # 80031888 <log>
    80004c70:	854a                	mv	a0,s2
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	faa080e7          	jalr	-86(ra) # 80000c1c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c7a:	02c92603          	lw	a2,44(s2)
    80004c7e:	47f5                	li	a5,29
    80004c80:	06c7c563          	blt	a5,a2,80004cea <log_write+0x90>
    80004c84:	0002d797          	auipc	a5,0x2d
    80004c88:	c207a783          	lw	a5,-992(a5) # 800318a4 <log+0x1c>
    80004c8c:	37fd                	addiw	a5,a5,-1
    80004c8e:	04f65e63          	bge	a2,a5,80004cea <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c92:	0002d797          	auipc	a5,0x2d
    80004c96:	c167a783          	lw	a5,-1002(a5) # 800318a8 <log+0x20>
    80004c9a:	06f05063          	blez	a5,80004cfa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c9e:	4781                	li	a5,0
    80004ca0:	06c05563          	blez	a2,80004d0a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ca4:	44cc                	lw	a1,12(s1)
    80004ca6:	0002d717          	auipc	a4,0x2d
    80004caa:	c1270713          	addi	a4,a4,-1006 # 800318b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004cae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004cb0:	4314                	lw	a3,0(a4)
    80004cb2:	04b68c63          	beq	a3,a1,80004d0a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004cb6:	2785                	addiw	a5,a5,1
    80004cb8:	0711                	addi	a4,a4,4
    80004cba:	fef61be3          	bne	a2,a5,80004cb0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004cbe:	0621                	addi	a2,a2,8
    80004cc0:	060a                	slli	a2,a2,0x2
    80004cc2:	0002d797          	auipc	a5,0x2d
    80004cc6:	bc678793          	addi	a5,a5,-1082 # 80031888 <log>
    80004cca:	97b2                	add	a5,a5,a2
    80004ccc:	44d8                	lw	a4,12(s1)
    80004cce:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	da2080e7          	jalr	-606(ra) # 80003a74 <bpin>
    log.lh.n++;
    80004cda:	0002d717          	auipc	a4,0x2d
    80004cde:	bae70713          	addi	a4,a4,-1106 # 80031888 <log>
    80004ce2:	575c                	lw	a5,44(a4)
    80004ce4:	2785                	addiw	a5,a5,1
    80004ce6:	d75c                	sw	a5,44(a4)
    80004ce8:	a82d                	j	80004d22 <log_write+0xc8>
    panic("too big a transaction");
    80004cea:	00004517          	auipc	a0,0x4
    80004cee:	9a650513          	addi	a0,a0,-1626 # 80008690 <syscalls+0x230>
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	84a080e7          	jalr	-1974(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004cfa:	00004517          	auipc	a0,0x4
    80004cfe:	9ae50513          	addi	a0,a0,-1618 # 800086a8 <syscalls+0x248>
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	83a080e7          	jalr	-1990(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004d0a:	00878693          	addi	a3,a5,8
    80004d0e:	068a                	slli	a3,a3,0x2
    80004d10:	0002d717          	auipc	a4,0x2d
    80004d14:	b7870713          	addi	a4,a4,-1160 # 80031888 <log>
    80004d18:	9736                	add	a4,a4,a3
    80004d1a:	44d4                	lw	a3,12(s1)
    80004d1c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004d1e:	faf609e3          	beq	a2,a5,80004cd0 <log_write+0x76>
  }
  release(&log.lock);
    80004d22:	0002d517          	auipc	a0,0x2d
    80004d26:	b6650513          	addi	a0,a0,-1178 # 80031888 <log>
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	fa6080e7          	jalr	-90(ra) # 80000cd0 <release>
}
    80004d32:	60e2                	ld	ra,24(sp)
    80004d34:	6442                	ld	s0,16(sp)
    80004d36:	64a2                	ld	s1,8(sp)
    80004d38:	6902                	ld	s2,0(sp)
    80004d3a:	6105                	addi	sp,sp,32
    80004d3c:	8082                	ret

0000000080004d3e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004d3e:	1101                	addi	sp,sp,-32
    80004d40:	ec06                	sd	ra,24(sp)
    80004d42:	e822                	sd	s0,16(sp)
    80004d44:	e426                	sd	s1,8(sp)
    80004d46:	e04a                	sd	s2,0(sp)
    80004d48:	1000                	addi	s0,sp,32
    80004d4a:	84aa                	mv	s1,a0
    80004d4c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004d4e:	00004597          	auipc	a1,0x4
    80004d52:	97a58593          	addi	a1,a1,-1670 # 800086c8 <syscalls+0x268>
    80004d56:	0521                	addi	a0,a0,8
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	e34080e7          	jalr	-460(ra) # 80000b8c <initlock>
  lk->name = name;
    80004d60:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004d64:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d68:	0204a423          	sw	zero,40(s1)
}
    80004d6c:	60e2                	ld	ra,24(sp)
    80004d6e:	6442                	ld	s0,16(sp)
    80004d70:	64a2                	ld	s1,8(sp)
    80004d72:	6902                	ld	s2,0(sp)
    80004d74:	6105                	addi	sp,sp,32
    80004d76:	8082                	ret

0000000080004d78 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d78:	1101                	addi	sp,sp,-32
    80004d7a:	ec06                	sd	ra,24(sp)
    80004d7c:	e822                	sd	s0,16(sp)
    80004d7e:	e426                	sd	s1,8(sp)
    80004d80:	e04a                	sd	s2,0(sp)
    80004d82:	1000                	addi	s0,sp,32
    80004d84:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d86:	00850913          	addi	s2,a0,8
    80004d8a:	854a                	mv	a0,s2
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	e90080e7          	jalr	-368(ra) # 80000c1c <acquire>
  while (lk->locked) {
    80004d94:	409c                	lw	a5,0(s1)
    80004d96:	cb89                	beqz	a5,80004da8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d98:	85ca                	mv	a1,s2
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	158080e7          	jalr	344(ra) # 80001ef4 <sleep>
  while (lk->locked) {
    80004da4:	409c                	lw	a5,0(s1)
    80004da6:	fbed                	bnez	a5,80004d98 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004da8:	4785                	li	a5,1
    80004daa:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	d48080e7          	jalr	-696(ra) # 80001af4 <myproc>
    80004db4:	30852783          	lw	a5,776(a0)
    80004db8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004dba:	854a                	mv	a0,s2
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	f14080e7          	jalr	-236(ra) # 80000cd0 <release>
}
    80004dc4:	60e2                	ld	ra,24(sp)
    80004dc6:	6442                	ld	s0,16(sp)
    80004dc8:	64a2                	ld	s1,8(sp)
    80004dca:	6902                	ld	s2,0(sp)
    80004dcc:	6105                	addi	sp,sp,32
    80004dce:	8082                	ret

0000000080004dd0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004dd0:	1101                	addi	sp,sp,-32
    80004dd2:	ec06                	sd	ra,24(sp)
    80004dd4:	e822                	sd	s0,16(sp)
    80004dd6:	e426                	sd	s1,8(sp)
    80004dd8:	e04a                	sd	s2,0(sp)
    80004dda:	1000                	addi	s0,sp,32
    80004ddc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004dde:	00850913          	addi	s2,a0,8
    80004de2:	854a                	mv	a0,s2
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	e38080e7          	jalr	-456(ra) # 80000c1c <acquire>
  lk->locked = 0;
    80004dec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004df0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	16e080e7          	jalr	366(ra) # 80001f64 <wakeup>
  release(&lk->lk);
    80004dfe:	854a                	mv	a0,s2
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	ed0080e7          	jalr	-304(ra) # 80000cd0 <release>
}
    80004e08:	60e2                	ld	ra,24(sp)
    80004e0a:	6442                	ld	s0,16(sp)
    80004e0c:	64a2                	ld	s1,8(sp)
    80004e0e:	6902                	ld	s2,0(sp)
    80004e10:	6105                	addi	sp,sp,32
    80004e12:	8082                	ret

0000000080004e14 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004e14:	7179                	addi	sp,sp,-48
    80004e16:	f406                	sd	ra,40(sp)
    80004e18:	f022                	sd	s0,32(sp)
    80004e1a:	ec26                	sd	s1,24(sp)
    80004e1c:	e84a                	sd	s2,16(sp)
    80004e1e:	e44e                	sd	s3,8(sp)
    80004e20:	1800                	addi	s0,sp,48
    80004e22:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004e24:	00850913          	addi	s2,a0,8
    80004e28:	854a                	mv	a0,s2
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	df2080e7          	jalr	-526(ra) # 80000c1c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e32:	409c                	lw	a5,0(s1)
    80004e34:	ef99                	bnez	a5,80004e52 <holdingsleep+0x3e>
    80004e36:	4481                	li	s1,0
  release(&lk->lk);
    80004e38:	854a                	mv	a0,s2
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	e96080e7          	jalr	-362(ra) # 80000cd0 <release>
  return r;
}
    80004e42:	8526                	mv	a0,s1
    80004e44:	70a2                	ld	ra,40(sp)
    80004e46:	7402                	ld	s0,32(sp)
    80004e48:	64e2                	ld	s1,24(sp)
    80004e4a:	6942                	ld	s2,16(sp)
    80004e4c:	69a2                	ld	s3,8(sp)
    80004e4e:	6145                	addi	sp,sp,48
    80004e50:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e52:	0284a983          	lw	s3,40(s1)
    80004e56:	ffffd097          	auipc	ra,0xffffd
    80004e5a:	c9e080e7          	jalr	-866(ra) # 80001af4 <myproc>
    80004e5e:	30852483          	lw	s1,776(a0)
    80004e62:	413484b3          	sub	s1,s1,s3
    80004e66:	0014b493          	seqz	s1,s1
    80004e6a:	b7f9                	j	80004e38 <holdingsleep+0x24>

0000000080004e6c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004e6c:	1141                	addi	sp,sp,-16
    80004e6e:	e406                	sd	ra,8(sp)
    80004e70:	e022                	sd	s0,0(sp)
    80004e72:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e74:	00004597          	auipc	a1,0x4
    80004e78:	86458593          	addi	a1,a1,-1948 # 800086d8 <syscalls+0x278>
    80004e7c:	0002d517          	auipc	a0,0x2d
    80004e80:	b5450513          	addi	a0,a0,-1196 # 800319d0 <ftable>
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	d08080e7          	jalr	-760(ra) # 80000b8c <initlock>
}
    80004e8c:	60a2                	ld	ra,8(sp)
    80004e8e:	6402                	ld	s0,0(sp)
    80004e90:	0141                	addi	sp,sp,16
    80004e92:	8082                	ret

0000000080004e94 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e94:	1101                	addi	sp,sp,-32
    80004e96:	ec06                	sd	ra,24(sp)
    80004e98:	e822                	sd	s0,16(sp)
    80004e9a:	e426                	sd	s1,8(sp)
    80004e9c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e9e:	0002d517          	auipc	a0,0x2d
    80004ea2:	b3250513          	addi	a0,a0,-1230 # 800319d0 <ftable>
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	d76080e7          	jalr	-650(ra) # 80000c1c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004eae:	0002d497          	auipc	s1,0x2d
    80004eb2:	b3a48493          	addi	s1,s1,-1222 # 800319e8 <ftable+0x18>
    80004eb6:	0002e717          	auipc	a4,0x2e
    80004eba:	ad270713          	addi	a4,a4,-1326 # 80032988 <ftable+0xfb8>
    if(f->ref == 0){
    80004ebe:	40dc                	lw	a5,4(s1)
    80004ec0:	cf99                	beqz	a5,80004ede <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ec2:	02848493          	addi	s1,s1,40
    80004ec6:	fee49ce3          	bne	s1,a4,80004ebe <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004eca:	0002d517          	auipc	a0,0x2d
    80004ece:	b0650513          	addi	a0,a0,-1274 # 800319d0 <ftable>
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	dfe080e7          	jalr	-514(ra) # 80000cd0 <release>
  return 0;
    80004eda:	4481                	li	s1,0
    80004edc:	a819                	j	80004ef2 <filealloc+0x5e>
      f->ref = 1;
    80004ede:	4785                	li	a5,1
    80004ee0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ee2:	0002d517          	auipc	a0,0x2d
    80004ee6:	aee50513          	addi	a0,a0,-1298 # 800319d0 <ftable>
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	de6080e7          	jalr	-538(ra) # 80000cd0 <release>
}
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	60e2                	ld	ra,24(sp)
    80004ef6:	6442                	ld	s0,16(sp)
    80004ef8:	64a2                	ld	s1,8(sp)
    80004efa:	6105                	addi	sp,sp,32
    80004efc:	8082                	ret

0000000080004efe <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004efe:	1101                	addi	sp,sp,-32
    80004f00:	ec06                	sd	ra,24(sp)
    80004f02:	e822                	sd	s0,16(sp)
    80004f04:	e426                	sd	s1,8(sp)
    80004f06:	1000                	addi	s0,sp,32
    80004f08:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f0a:	0002d517          	auipc	a0,0x2d
    80004f0e:	ac650513          	addi	a0,a0,-1338 # 800319d0 <ftable>
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	d0a080e7          	jalr	-758(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    80004f1a:	40dc                	lw	a5,4(s1)
    80004f1c:	02f05263          	blez	a5,80004f40 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004f20:	2785                	addiw	a5,a5,1
    80004f22:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004f24:	0002d517          	auipc	a0,0x2d
    80004f28:	aac50513          	addi	a0,a0,-1364 # 800319d0 <ftable>
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	da4080e7          	jalr	-604(ra) # 80000cd0 <release>
  return f;
}
    80004f34:	8526                	mv	a0,s1
    80004f36:	60e2                	ld	ra,24(sp)
    80004f38:	6442                	ld	s0,16(sp)
    80004f3a:	64a2                	ld	s1,8(sp)
    80004f3c:	6105                	addi	sp,sp,32
    80004f3e:	8082                	ret
    panic("filedup");
    80004f40:	00003517          	auipc	a0,0x3
    80004f44:	7a050513          	addi	a0,a0,1952 # 800086e0 <syscalls+0x280>
    80004f48:	ffffb097          	auipc	ra,0xffffb
    80004f4c:	5f4080e7          	jalr	1524(ra) # 8000053c <panic>

0000000080004f50 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f50:	7139                	addi	sp,sp,-64
    80004f52:	fc06                	sd	ra,56(sp)
    80004f54:	f822                	sd	s0,48(sp)
    80004f56:	f426                	sd	s1,40(sp)
    80004f58:	f04a                	sd	s2,32(sp)
    80004f5a:	ec4e                	sd	s3,24(sp)
    80004f5c:	e852                	sd	s4,16(sp)
    80004f5e:	e456                	sd	s5,8(sp)
    80004f60:	0080                	addi	s0,sp,64
    80004f62:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004f64:	0002d517          	auipc	a0,0x2d
    80004f68:	a6c50513          	addi	a0,a0,-1428 # 800319d0 <ftable>
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	cb0080e7          	jalr	-848(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    80004f74:	40dc                	lw	a5,4(s1)
    80004f76:	06f05163          	blez	a5,80004fd8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f7a:	37fd                	addiw	a5,a5,-1
    80004f7c:	0007871b          	sext.w	a4,a5
    80004f80:	c0dc                	sw	a5,4(s1)
    80004f82:	06e04363          	bgtz	a4,80004fe8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f86:	0004a903          	lw	s2,0(s1)
    80004f8a:	0094ca83          	lbu	s5,9(s1)
    80004f8e:	0104ba03          	ld	s4,16(s1)
    80004f92:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f96:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f9a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f9e:	0002d517          	auipc	a0,0x2d
    80004fa2:	a3250513          	addi	a0,a0,-1486 # 800319d0 <ftable>
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	d2a080e7          	jalr	-726(ra) # 80000cd0 <release>

  if(ff.type == FD_PIPE){
    80004fae:	4785                	li	a5,1
    80004fb0:	04f90d63          	beq	s2,a5,8000500a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004fb4:	3979                	addiw	s2,s2,-2
    80004fb6:	4785                	li	a5,1
    80004fb8:	0527e063          	bltu	a5,s2,80004ff8 <fileclose+0xa8>
    begin_op();
    80004fbc:	00000097          	auipc	ra,0x0
    80004fc0:	ac8080e7          	jalr	-1336(ra) # 80004a84 <begin_op>
    iput(ff.ip);
    80004fc4:	854e                	mv	a0,s3
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	29c080e7          	jalr	668(ra) # 80004262 <iput>
    end_op();
    80004fce:	00000097          	auipc	ra,0x0
    80004fd2:	b34080e7          	jalr	-1228(ra) # 80004b02 <end_op>
    80004fd6:	a00d                	j	80004ff8 <fileclose+0xa8>
    panic("fileclose");
    80004fd8:	00003517          	auipc	a0,0x3
    80004fdc:	71050513          	addi	a0,a0,1808 # 800086e8 <syscalls+0x288>
    80004fe0:	ffffb097          	auipc	ra,0xffffb
    80004fe4:	55c080e7          	jalr	1372(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004fe8:	0002d517          	auipc	a0,0x2d
    80004fec:	9e850513          	addi	a0,a0,-1560 # 800319d0 <ftable>
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	ce0080e7          	jalr	-800(ra) # 80000cd0 <release>
  }
}
    80004ff8:	70e2                	ld	ra,56(sp)
    80004ffa:	7442                	ld	s0,48(sp)
    80004ffc:	74a2                	ld	s1,40(sp)
    80004ffe:	7902                	ld	s2,32(sp)
    80005000:	69e2                	ld	s3,24(sp)
    80005002:	6a42                	ld	s4,16(sp)
    80005004:	6aa2                	ld	s5,8(sp)
    80005006:	6121                	addi	sp,sp,64
    80005008:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000500a:	85d6                	mv	a1,s5
    8000500c:	8552                	mv	a0,s4
    8000500e:	00000097          	auipc	ra,0x0
    80005012:	34c080e7          	jalr	844(ra) # 8000535a <pipeclose>
    80005016:	b7cd                	j	80004ff8 <fileclose+0xa8>

0000000080005018 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005018:	715d                	addi	sp,sp,-80
    8000501a:	e486                	sd	ra,72(sp)
    8000501c:	e0a2                	sd	s0,64(sp)
    8000501e:	fc26                	sd	s1,56(sp)
    80005020:	f84a                	sd	s2,48(sp)
    80005022:	f44e                	sd	s3,40(sp)
    80005024:	0880                	addi	s0,sp,80
    80005026:	84aa                	mv	s1,a0
    80005028:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	aca080e7          	jalr	-1334(ra) # 80001af4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005032:	409c                	lw	a5,0(s1)
    80005034:	37f9                	addiw	a5,a5,-2
    80005036:	4705                	li	a4,1
    80005038:	04f76763          	bltu	a4,a5,80005086 <filestat+0x6e>
    8000503c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000503e:	6c88                	ld	a0,24(s1)
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	068080e7          	jalr	104(ra) # 800040a8 <ilock>
    stati(f->ip, &st);
    80005048:	fb840593          	addi	a1,s0,-72
    8000504c:	6c88                	ld	a0,24(s1)
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	2e4080e7          	jalr	740(ra) # 80004332 <stati>
    iunlock(f->ip);
    80005056:	6c88                	ld	a0,24(s1)
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	112080e7          	jalr	274(ra) # 8000416a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005060:	46e1                	li	a3,24
    80005062:	fb840613          	addi	a2,s0,-72
    80005066:	85ce                	mv	a1,s3
    80005068:	32893503          	ld	a0,808(s2)
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	6ce080e7          	jalr	1742(ra) # 8000173a <copyout>
    80005074:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005078:	60a6                	ld	ra,72(sp)
    8000507a:	6406                	ld	s0,64(sp)
    8000507c:	74e2                	ld	s1,56(sp)
    8000507e:	7942                	ld	s2,48(sp)
    80005080:	79a2                	ld	s3,40(sp)
    80005082:	6161                	addi	sp,sp,80
    80005084:	8082                	ret
  return -1;
    80005086:	557d                	li	a0,-1
    80005088:	bfc5                	j	80005078 <filestat+0x60>

000000008000508a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000508a:	7179                	addi	sp,sp,-48
    8000508c:	f406                	sd	ra,40(sp)
    8000508e:	f022                	sd	s0,32(sp)
    80005090:	ec26                	sd	s1,24(sp)
    80005092:	e84a                	sd	s2,16(sp)
    80005094:	e44e                	sd	s3,8(sp)
    80005096:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005098:	00854783          	lbu	a5,8(a0)
    8000509c:	c3d5                	beqz	a5,80005140 <fileread+0xb6>
    8000509e:	84aa                	mv	s1,a0
    800050a0:	89ae                	mv	s3,a1
    800050a2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800050a4:	411c                	lw	a5,0(a0)
    800050a6:	4705                	li	a4,1
    800050a8:	04e78963          	beq	a5,a4,800050fa <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050ac:	470d                	li	a4,3
    800050ae:	04e78d63          	beq	a5,a4,80005108 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800050b2:	4709                	li	a4,2
    800050b4:	06e79e63          	bne	a5,a4,80005130 <fileread+0xa6>
    ilock(f->ip);
    800050b8:	6d08                	ld	a0,24(a0)
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	fee080e7          	jalr	-18(ra) # 800040a8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800050c2:	874a                	mv	a4,s2
    800050c4:	5094                	lw	a3,32(s1)
    800050c6:	864e                	mv	a2,s3
    800050c8:	4585                	li	a1,1
    800050ca:	6c88                	ld	a0,24(s1)
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	290080e7          	jalr	656(ra) # 8000435c <readi>
    800050d4:	892a                	mv	s2,a0
    800050d6:	00a05563          	blez	a0,800050e0 <fileread+0x56>
      f->off += r;
    800050da:	509c                	lw	a5,32(s1)
    800050dc:	9fa9                	addw	a5,a5,a0
    800050de:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800050e0:	6c88                	ld	a0,24(s1)
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	088080e7          	jalr	136(ra) # 8000416a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800050ea:	854a                	mv	a0,s2
    800050ec:	70a2                	ld	ra,40(sp)
    800050ee:	7402                	ld	s0,32(sp)
    800050f0:	64e2                	ld	s1,24(sp)
    800050f2:	6942                	ld	s2,16(sp)
    800050f4:	69a2                	ld	s3,8(sp)
    800050f6:	6145                	addi	sp,sp,48
    800050f8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800050fa:	6908                	ld	a0,16(a0)
    800050fc:	00000097          	auipc	ra,0x0
    80005100:	3c0080e7          	jalr	960(ra) # 800054bc <piperead>
    80005104:	892a                	mv	s2,a0
    80005106:	b7d5                	j	800050ea <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005108:	02451783          	lh	a5,36(a0)
    8000510c:	03079693          	slli	a3,a5,0x30
    80005110:	92c1                	srli	a3,a3,0x30
    80005112:	4725                	li	a4,9
    80005114:	02d76863          	bltu	a4,a3,80005144 <fileread+0xba>
    80005118:	0792                	slli	a5,a5,0x4
    8000511a:	0002d717          	auipc	a4,0x2d
    8000511e:	81670713          	addi	a4,a4,-2026 # 80031930 <devsw>
    80005122:	97ba                	add	a5,a5,a4
    80005124:	639c                	ld	a5,0(a5)
    80005126:	c38d                	beqz	a5,80005148 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005128:	4505                	li	a0,1
    8000512a:	9782                	jalr	a5
    8000512c:	892a                	mv	s2,a0
    8000512e:	bf75                	j	800050ea <fileread+0x60>
    panic("fileread");
    80005130:	00003517          	auipc	a0,0x3
    80005134:	5c850513          	addi	a0,a0,1480 # 800086f8 <syscalls+0x298>
    80005138:	ffffb097          	auipc	ra,0xffffb
    8000513c:	404080e7          	jalr	1028(ra) # 8000053c <panic>
    return -1;
    80005140:	597d                	li	s2,-1
    80005142:	b765                	j	800050ea <fileread+0x60>
      return -1;
    80005144:	597d                	li	s2,-1
    80005146:	b755                	j	800050ea <fileread+0x60>
    80005148:	597d                	li	s2,-1
    8000514a:	b745                	j	800050ea <fileread+0x60>

000000008000514c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000514c:	715d                	addi	sp,sp,-80
    8000514e:	e486                	sd	ra,72(sp)
    80005150:	e0a2                	sd	s0,64(sp)
    80005152:	fc26                	sd	s1,56(sp)
    80005154:	f84a                	sd	s2,48(sp)
    80005156:	f44e                	sd	s3,40(sp)
    80005158:	f052                	sd	s4,32(sp)
    8000515a:	ec56                	sd	s5,24(sp)
    8000515c:	e85a                	sd	s6,16(sp)
    8000515e:	e45e                	sd	s7,8(sp)
    80005160:	e062                	sd	s8,0(sp)
    80005162:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005164:	00954783          	lbu	a5,9(a0)
    80005168:	10078663          	beqz	a5,80005274 <filewrite+0x128>
    8000516c:	892a                	mv	s2,a0
    8000516e:	8b2e                	mv	s6,a1
    80005170:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005172:	411c                	lw	a5,0(a0)
    80005174:	4705                	li	a4,1
    80005176:	02e78263          	beq	a5,a4,8000519a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000517a:	470d                	li	a4,3
    8000517c:	02e78663          	beq	a5,a4,800051a8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005180:	4709                	li	a4,2
    80005182:	0ee79163          	bne	a5,a4,80005264 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005186:	0ac05d63          	blez	a2,80005240 <filewrite+0xf4>
    int i = 0;
    8000518a:	4981                	li	s3,0
    8000518c:	6b85                	lui	s7,0x1
    8000518e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005192:	6c05                	lui	s8,0x1
    80005194:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005198:	a861                	j	80005230 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000519a:	6908                	ld	a0,16(a0)
    8000519c:	00000097          	auipc	ra,0x0
    800051a0:	22e080e7          	jalr	558(ra) # 800053ca <pipewrite>
    800051a4:	8a2a                	mv	s4,a0
    800051a6:	a045                	j	80005246 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800051a8:	02451783          	lh	a5,36(a0)
    800051ac:	03079693          	slli	a3,a5,0x30
    800051b0:	92c1                	srli	a3,a3,0x30
    800051b2:	4725                	li	a4,9
    800051b4:	0cd76263          	bltu	a4,a3,80005278 <filewrite+0x12c>
    800051b8:	0792                	slli	a5,a5,0x4
    800051ba:	0002c717          	auipc	a4,0x2c
    800051be:	77670713          	addi	a4,a4,1910 # 80031930 <devsw>
    800051c2:	97ba                	add	a5,a5,a4
    800051c4:	679c                	ld	a5,8(a5)
    800051c6:	cbdd                	beqz	a5,8000527c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800051c8:	4505                	li	a0,1
    800051ca:	9782                	jalr	a5
    800051cc:	8a2a                	mv	s4,a0
    800051ce:	a8a5                	j	80005246 <filewrite+0xfa>
    800051d0:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800051d4:	00000097          	auipc	ra,0x0
    800051d8:	8b0080e7          	jalr	-1872(ra) # 80004a84 <begin_op>
      ilock(f->ip);
    800051dc:	01893503          	ld	a0,24(s2)
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	ec8080e7          	jalr	-312(ra) # 800040a8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800051e8:	8756                	mv	a4,s5
    800051ea:	02092683          	lw	a3,32(s2)
    800051ee:	01698633          	add	a2,s3,s6
    800051f2:	4585                	li	a1,1
    800051f4:	01893503          	ld	a0,24(s2)
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	25c080e7          	jalr	604(ra) # 80004454 <writei>
    80005200:	84aa                	mv	s1,a0
    80005202:	00a05763          	blez	a0,80005210 <filewrite+0xc4>
        f->off += r;
    80005206:	02092783          	lw	a5,32(s2)
    8000520a:	9fa9                	addw	a5,a5,a0
    8000520c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005210:	01893503          	ld	a0,24(s2)
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	f56080e7          	jalr	-170(ra) # 8000416a <iunlock>
      end_op();
    8000521c:	00000097          	auipc	ra,0x0
    80005220:	8e6080e7          	jalr	-1818(ra) # 80004b02 <end_op>

      if(r != n1){
    80005224:	009a9f63          	bne	s5,s1,80005242 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005228:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000522c:	0149db63          	bge	s3,s4,80005242 <filewrite+0xf6>
      int n1 = n - i;
    80005230:	413a04bb          	subw	s1,s4,s3
    80005234:	0004879b          	sext.w	a5,s1
    80005238:	f8fbdce3          	bge	s7,a5,800051d0 <filewrite+0x84>
    8000523c:	84e2                	mv	s1,s8
    8000523e:	bf49                	j	800051d0 <filewrite+0x84>
    int i = 0;
    80005240:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005242:	013a1f63          	bne	s4,s3,80005260 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005246:	8552                	mv	a0,s4
    80005248:	60a6                	ld	ra,72(sp)
    8000524a:	6406                	ld	s0,64(sp)
    8000524c:	74e2                	ld	s1,56(sp)
    8000524e:	7942                	ld	s2,48(sp)
    80005250:	79a2                	ld	s3,40(sp)
    80005252:	7a02                	ld	s4,32(sp)
    80005254:	6ae2                	ld	s5,24(sp)
    80005256:	6b42                	ld	s6,16(sp)
    80005258:	6ba2                	ld	s7,8(sp)
    8000525a:	6c02                	ld	s8,0(sp)
    8000525c:	6161                	addi	sp,sp,80
    8000525e:	8082                	ret
    ret = (i == n ? n : -1);
    80005260:	5a7d                	li	s4,-1
    80005262:	b7d5                	j	80005246 <filewrite+0xfa>
    panic("filewrite");
    80005264:	00003517          	auipc	a0,0x3
    80005268:	4a450513          	addi	a0,a0,1188 # 80008708 <syscalls+0x2a8>
    8000526c:	ffffb097          	auipc	ra,0xffffb
    80005270:	2d0080e7          	jalr	720(ra) # 8000053c <panic>
    return -1;
    80005274:	5a7d                	li	s4,-1
    80005276:	bfc1                	j	80005246 <filewrite+0xfa>
      return -1;
    80005278:	5a7d                	li	s4,-1
    8000527a:	b7f1                	j	80005246 <filewrite+0xfa>
    8000527c:	5a7d                	li	s4,-1
    8000527e:	b7e1                	j	80005246 <filewrite+0xfa>

0000000080005280 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005280:	7179                	addi	sp,sp,-48
    80005282:	f406                	sd	ra,40(sp)
    80005284:	f022                	sd	s0,32(sp)
    80005286:	ec26                	sd	s1,24(sp)
    80005288:	e84a                	sd	s2,16(sp)
    8000528a:	e44e                	sd	s3,8(sp)
    8000528c:	e052                	sd	s4,0(sp)
    8000528e:	1800                	addi	s0,sp,48
    80005290:	84aa                	mv	s1,a0
    80005292:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005294:	0005b023          	sd	zero,0(a1)
    80005298:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000529c:	00000097          	auipc	ra,0x0
    800052a0:	bf8080e7          	jalr	-1032(ra) # 80004e94 <filealloc>
    800052a4:	e088                	sd	a0,0(s1)
    800052a6:	c551                	beqz	a0,80005332 <pipealloc+0xb2>
    800052a8:	00000097          	auipc	ra,0x0
    800052ac:	bec080e7          	jalr	-1044(ra) # 80004e94 <filealloc>
    800052b0:	00aa3023          	sd	a0,0(s4)
    800052b4:	c92d                	beqz	a0,80005326 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800052b6:	ffffc097          	auipc	ra,0xffffc
    800052ba:	82c080e7          	jalr	-2004(ra) # 80000ae2 <kalloc>
    800052be:	892a                	mv	s2,a0
    800052c0:	c125                	beqz	a0,80005320 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800052c2:	4985                	li	s3,1
    800052c4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800052c8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800052cc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800052d0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800052d4:	00003597          	auipc	a1,0x3
    800052d8:	44458593          	addi	a1,a1,1092 # 80008718 <syscalls+0x2b8>
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	8b0080e7          	jalr	-1872(ra) # 80000b8c <initlock>
  (*f0)->type = FD_PIPE;
    800052e4:	609c                	ld	a5,0(s1)
    800052e6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800052ea:	609c                	ld	a5,0(s1)
    800052ec:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800052f0:	609c                	ld	a5,0(s1)
    800052f2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800052f6:	609c                	ld	a5,0(s1)
    800052f8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800052fc:	000a3783          	ld	a5,0(s4)
    80005300:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005304:	000a3783          	ld	a5,0(s4)
    80005308:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000530c:	000a3783          	ld	a5,0(s4)
    80005310:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005314:	000a3783          	ld	a5,0(s4)
    80005318:	0127b823          	sd	s2,16(a5)
  return 0;
    8000531c:	4501                	li	a0,0
    8000531e:	a025                	j	80005346 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005320:	6088                	ld	a0,0(s1)
    80005322:	e501                	bnez	a0,8000532a <pipealloc+0xaa>
    80005324:	a039                	j	80005332 <pipealloc+0xb2>
    80005326:	6088                	ld	a0,0(s1)
    80005328:	c51d                	beqz	a0,80005356 <pipealloc+0xd6>
    fileclose(*f0);
    8000532a:	00000097          	auipc	ra,0x0
    8000532e:	c26080e7          	jalr	-986(ra) # 80004f50 <fileclose>
  if(*f1)
    80005332:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005336:	557d                	li	a0,-1
  if(*f1)
    80005338:	c799                	beqz	a5,80005346 <pipealloc+0xc6>
    fileclose(*f1);
    8000533a:	853e                	mv	a0,a5
    8000533c:	00000097          	auipc	ra,0x0
    80005340:	c14080e7          	jalr	-1004(ra) # 80004f50 <fileclose>
  return -1;
    80005344:	557d                	li	a0,-1
}
    80005346:	70a2                	ld	ra,40(sp)
    80005348:	7402                	ld	s0,32(sp)
    8000534a:	64e2                	ld	s1,24(sp)
    8000534c:	6942                	ld	s2,16(sp)
    8000534e:	69a2                	ld	s3,8(sp)
    80005350:	6a02                	ld	s4,0(sp)
    80005352:	6145                	addi	sp,sp,48
    80005354:	8082                	ret
  return -1;
    80005356:	557d                	li	a0,-1
    80005358:	b7fd                	j	80005346 <pipealloc+0xc6>

000000008000535a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000535a:	1101                	addi	sp,sp,-32
    8000535c:	ec06                	sd	ra,24(sp)
    8000535e:	e822                	sd	s0,16(sp)
    80005360:	e426                	sd	s1,8(sp)
    80005362:	e04a                	sd	s2,0(sp)
    80005364:	1000                	addi	s0,sp,32
    80005366:	84aa                	mv	s1,a0
    80005368:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	8b2080e7          	jalr	-1870(ra) # 80000c1c <acquire>
  if(writable){
    80005372:	02090d63          	beqz	s2,800053ac <pipeclose+0x52>
    pi->writeopen = 0;
    80005376:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000537a:	21848513          	addi	a0,s1,536
    8000537e:	ffffd097          	auipc	ra,0xffffd
    80005382:	be6080e7          	jalr	-1050(ra) # 80001f64 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005386:	2204b783          	ld	a5,544(s1)
    8000538a:	eb95                	bnez	a5,800053be <pipeclose+0x64>
    release(&pi->lock);
    8000538c:	8526                	mv	a0,s1
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	942080e7          	jalr	-1726(ra) # 80000cd0 <release>
    kfree((char*)pi);
    80005396:	8526                	mv	a0,s1
    80005398:	ffffb097          	auipc	ra,0xffffb
    8000539c:	64c080e7          	jalr	1612(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    800053a0:	60e2                	ld	ra,24(sp)
    800053a2:	6442                	ld	s0,16(sp)
    800053a4:	64a2                	ld	s1,8(sp)
    800053a6:	6902                	ld	s2,0(sp)
    800053a8:	6105                	addi	sp,sp,32
    800053aa:	8082                	ret
    pi->readopen = 0;
    800053ac:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800053b0:	21c48513          	addi	a0,s1,540
    800053b4:	ffffd097          	auipc	ra,0xffffd
    800053b8:	bb0080e7          	jalr	-1104(ra) # 80001f64 <wakeup>
    800053bc:	b7e9                	j	80005386 <pipeclose+0x2c>
    release(&pi->lock);
    800053be:	8526                	mv	a0,s1
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	910080e7          	jalr	-1776(ra) # 80000cd0 <release>
}
    800053c8:	bfe1                	j	800053a0 <pipeclose+0x46>

00000000800053ca <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800053ca:	711d                	addi	sp,sp,-96
    800053cc:	ec86                	sd	ra,88(sp)
    800053ce:	e8a2                	sd	s0,80(sp)
    800053d0:	e4a6                	sd	s1,72(sp)
    800053d2:	e0ca                	sd	s2,64(sp)
    800053d4:	fc4e                	sd	s3,56(sp)
    800053d6:	f852                	sd	s4,48(sp)
    800053d8:	f456                	sd	s5,40(sp)
    800053da:	f05a                	sd	s6,32(sp)
    800053dc:	ec5e                	sd	s7,24(sp)
    800053de:	e862                	sd	s8,16(sp)
    800053e0:	1080                	addi	s0,sp,96
    800053e2:	84aa                	mv	s1,a0
    800053e4:	8aae                	mv	s5,a1
    800053e6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800053e8:	ffffc097          	auipc	ra,0xffffc
    800053ec:	70c080e7          	jalr	1804(ra) # 80001af4 <myproc>
    800053f0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800053f2:	8526                	mv	a0,s1
    800053f4:	ffffc097          	auipc	ra,0xffffc
    800053f8:	828080e7          	jalr	-2008(ra) # 80000c1c <acquire>
  while(i < n){
    800053fc:	0b405363          	blez	s4,800054a2 <pipewrite+0xd8>
  int i = 0;
    80005400:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005402:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005404:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005408:	21c48b93          	addi	s7,s1,540
    8000540c:	a089                	j	8000544e <pipewrite+0x84>
      release(&pi->lock);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	8c0080e7          	jalr	-1856(ra) # 80000cd0 <release>
      return -1;
    80005418:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000541a:	854a                	mv	a0,s2
    8000541c:	60e6                	ld	ra,88(sp)
    8000541e:	6446                	ld	s0,80(sp)
    80005420:	64a6                	ld	s1,72(sp)
    80005422:	6906                	ld	s2,64(sp)
    80005424:	79e2                	ld	s3,56(sp)
    80005426:	7a42                	ld	s4,48(sp)
    80005428:	7aa2                	ld	s5,40(sp)
    8000542a:	7b02                	ld	s6,32(sp)
    8000542c:	6be2                	ld	s7,24(sp)
    8000542e:	6c42                	ld	s8,16(sp)
    80005430:	6125                	addi	sp,sp,96
    80005432:	8082                	ret
      wakeup(&pi->nread);
    80005434:	8562                	mv	a0,s8
    80005436:	ffffd097          	auipc	ra,0xffffd
    8000543a:	b2e080e7          	jalr	-1234(ra) # 80001f64 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000543e:	85a6                	mv	a1,s1
    80005440:	855e                	mv	a0,s7
    80005442:	ffffd097          	auipc	ra,0xffffd
    80005446:	ab2080e7          	jalr	-1358(ra) # 80001ef4 <sleep>
  while(i < n){
    8000544a:	05495d63          	bge	s2,s4,800054a4 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000544e:	2204a783          	lw	a5,544(s1)
    80005452:	dfd5                	beqz	a5,8000540e <pipewrite+0x44>
    80005454:	3009a783          	lw	a5,768(s3)
    80005458:	fbdd                	bnez	a5,8000540e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000545a:	2184a783          	lw	a5,536(s1)
    8000545e:	21c4a703          	lw	a4,540(s1)
    80005462:	2007879b          	addiw	a5,a5,512
    80005466:	fcf707e3          	beq	a4,a5,80005434 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000546a:	4685                	li	a3,1
    8000546c:	01590633          	add	a2,s2,s5
    80005470:	faf40593          	addi	a1,s0,-81
    80005474:	3289b503          	ld	a0,808(s3)
    80005478:	ffffc097          	auipc	ra,0xffffc
    8000547c:	34e080e7          	jalr	846(ra) # 800017c6 <copyin>
    80005480:	03650263          	beq	a0,s6,800054a4 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005484:	21c4a783          	lw	a5,540(s1)
    80005488:	0017871b          	addiw	a4,a5,1
    8000548c:	20e4ae23          	sw	a4,540(s1)
    80005490:	1ff7f793          	andi	a5,a5,511
    80005494:	97a6                	add	a5,a5,s1
    80005496:	faf44703          	lbu	a4,-81(s0)
    8000549a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000549e:	2905                	addiw	s2,s2,1
    800054a0:	b76d                	j	8000544a <pipewrite+0x80>
  int i = 0;
    800054a2:	4901                	li	s2,0
  wakeup(&pi->nread);
    800054a4:	21848513          	addi	a0,s1,536
    800054a8:	ffffd097          	auipc	ra,0xffffd
    800054ac:	abc080e7          	jalr	-1348(ra) # 80001f64 <wakeup>
  release(&pi->lock);
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffc097          	auipc	ra,0xffffc
    800054b6:	81e080e7          	jalr	-2018(ra) # 80000cd0 <release>
  return i;
    800054ba:	b785                	j	8000541a <pipewrite+0x50>

00000000800054bc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800054bc:	715d                	addi	sp,sp,-80
    800054be:	e486                	sd	ra,72(sp)
    800054c0:	e0a2                	sd	s0,64(sp)
    800054c2:	fc26                	sd	s1,56(sp)
    800054c4:	f84a                	sd	s2,48(sp)
    800054c6:	f44e                	sd	s3,40(sp)
    800054c8:	f052                	sd	s4,32(sp)
    800054ca:	ec56                	sd	s5,24(sp)
    800054cc:	e85a                	sd	s6,16(sp)
    800054ce:	0880                	addi	s0,sp,80
    800054d0:	84aa                	mv	s1,a0
    800054d2:	892e                	mv	s2,a1
    800054d4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800054d6:	ffffc097          	auipc	ra,0xffffc
    800054da:	61e080e7          	jalr	1566(ra) # 80001af4 <myproc>
    800054de:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffb097          	auipc	ra,0xffffb
    800054e6:	73a080e7          	jalr	1850(ra) # 80000c1c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054ea:	2184a703          	lw	a4,536(s1)
    800054ee:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800054f2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054f6:	02f71463          	bne	a4,a5,8000551e <piperead+0x62>
    800054fa:	2244a783          	lw	a5,548(s1)
    800054fe:	c385                	beqz	a5,8000551e <piperead+0x62>
    if(pr->killed){
    80005500:	300a2783          	lw	a5,768(s4)
    80005504:	ebc9                	bnez	a5,80005596 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005506:	85a6                	mv	a1,s1
    80005508:	854e                	mv	a0,s3
    8000550a:	ffffd097          	auipc	ra,0xffffd
    8000550e:	9ea080e7          	jalr	-1558(ra) # 80001ef4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005512:	2184a703          	lw	a4,536(s1)
    80005516:	21c4a783          	lw	a5,540(s1)
    8000551a:	fef700e3          	beq	a4,a5,800054fa <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000551e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005520:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005522:	05505463          	blez	s5,8000556a <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80005526:	2184a783          	lw	a5,536(s1)
    8000552a:	21c4a703          	lw	a4,540(s1)
    8000552e:	02f70e63          	beq	a4,a5,8000556a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005532:	0017871b          	addiw	a4,a5,1
    80005536:	20e4ac23          	sw	a4,536(s1)
    8000553a:	1ff7f793          	andi	a5,a5,511
    8000553e:	97a6                	add	a5,a5,s1
    80005540:	0187c783          	lbu	a5,24(a5)
    80005544:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005548:	4685                	li	a3,1
    8000554a:	fbf40613          	addi	a2,s0,-65
    8000554e:	85ca                	mv	a1,s2
    80005550:	328a3503          	ld	a0,808(s4)
    80005554:	ffffc097          	auipc	ra,0xffffc
    80005558:	1e6080e7          	jalr	486(ra) # 8000173a <copyout>
    8000555c:	01650763          	beq	a0,s6,8000556a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005560:	2985                	addiw	s3,s3,1
    80005562:	0905                	addi	s2,s2,1
    80005564:	fd3a91e3          	bne	s5,s3,80005526 <piperead+0x6a>
    80005568:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000556a:	21c48513          	addi	a0,s1,540
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	9f6080e7          	jalr	-1546(ra) # 80001f64 <wakeup>
  release(&pi->lock);
    80005576:	8526                	mv	a0,s1
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	758080e7          	jalr	1880(ra) # 80000cd0 <release>
  return i;
}
    80005580:	854e                	mv	a0,s3
    80005582:	60a6                	ld	ra,72(sp)
    80005584:	6406                	ld	s0,64(sp)
    80005586:	74e2                	ld	s1,56(sp)
    80005588:	7942                	ld	s2,48(sp)
    8000558a:	79a2                	ld	s3,40(sp)
    8000558c:	7a02                	ld	s4,32(sp)
    8000558e:	6ae2                	ld	s5,24(sp)
    80005590:	6b42                	ld	s6,16(sp)
    80005592:	6161                	addi	sp,sp,80
    80005594:	8082                	ret
      release(&pi->lock);
    80005596:	8526                	mv	a0,s1
    80005598:	ffffb097          	auipc	ra,0xffffb
    8000559c:	738080e7          	jalr	1848(ra) # 80000cd0 <release>
      return -1;
    800055a0:	59fd                	li	s3,-1
    800055a2:	bff9                	j	80005580 <piperead+0xc4>

00000000800055a4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800055a4:	de010113          	addi	sp,sp,-544
    800055a8:	20113c23          	sd	ra,536(sp)
    800055ac:	20813823          	sd	s0,528(sp)
    800055b0:	20913423          	sd	s1,520(sp)
    800055b4:	21213023          	sd	s2,512(sp)
    800055b8:	ffce                	sd	s3,504(sp)
    800055ba:	fbd2                	sd	s4,496(sp)
    800055bc:	f7d6                	sd	s5,488(sp)
    800055be:	f3da                	sd	s6,480(sp)
    800055c0:	efde                	sd	s7,472(sp)
    800055c2:	ebe2                	sd	s8,464(sp)
    800055c4:	e7e6                	sd	s9,456(sp)
    800055c6:	e3ea                	sd	s10,448(sp)
    800055c8:	ff6e                	sd	s11,440(sp)
    800055ca:	1400                	addi	s0,sp,544
    800055cc:	892a                	mv	s2,a0
    800055ce:	dea43423          	sd	a0,-536(s0)
    800055d2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800055d6:	ffffc097          	auipc	ra,0xffffc
    800055da:	51e080e7          	jalr	1310(ra) # 80001af4 <myproc>
    800055de:	84aa                	mv	s1,a0

  begin_op();
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	4a4080e7          	jalr	1188(ra) # 80004a84 <begin_op>

  if((ip = namei(path)) == 0){
    800055e8:	854a                	mv	a0,s2
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	27a080e7          	jalr	634(ra) # 80004864 <namei>
    800055f2:	c93d                	beqz	a0,80005668 <exec+0xc4>
    800055f4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	ab2080e7          	jalr	-1358(ra) # 800040a8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800055fe:	04000713          	li	a4,64
    80005602:	4681                	li	a3,0
    80005604:	e5040613          	addi	a2,s0,-432
    80005608:	4581                	li	a1,0
    8000560a:	8556                	mv	a0,s5
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	d50080e7          	jalr	-688(ra) # 8000435c <readi>
    80005614:	04000793          	li	a5,64
    80005618:	00f51a63          	bne	a0,a5,8000562c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000561c:	e5042703          	lw	a4,-432(s0)
    80005620:	464c47b7          	lui	a5,0x464c4
    80005624:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005628:	04f70663          	beq	a4,a5,80005674 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000562c:	8556                	mv	a0,s5
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	cdc080e7          	jalr	-804(ra) # 8000430a <iunlockput>
    end_op();
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	4cc080e7          	jalr	1228(ra) # 80004b02 <end_op>
  }
  return -1;
    8000563e:	557d                	li	a0,-1
}
    80005640:	21813083          	ld	ra,536(sp)
    80005644:	21013403          	ld	s0,528(sp)
    80005648:	20813483          	ld	s1,520(sp)
    8000564c:	20013903          	ld	s2,512(sp)
    80005650:	79fe                	ld	s3,504(sp)
    80005652:	7a5e                	ld	s4,496(sp)
    80005654:	7abe                	ld	s5,488(sp)
    80005656:	7b1e                	ld	s6,480(sp)
    80005658:	6bfe                	ld	s7,472(sp)
    8000565a:	6c5e                	ld	s8,464(sp)
    8000565c:	6cbe                	ld	s9,456(sp)
    8000565e:	6d1e                	ld	s10,448(sp)
    80005660:	7dfa                	ld	s11,440(sp)
    80005662:	22010113          	addi	sp,sp,544
    80005666:	8082                	ret
    end_op();
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	49a080e7          	jalr	1178(ra) # 80004b02 <end_op>
    return -1;
    80005670:	557d                	li	a0,-1
    80005672:	b7f9                	j	80005640 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005674:	8526                	mv	a0,s1
    80005676:	ffffc097          	auipc	ra,0xffffc
    8000567a:	546080e7          	jalr	1350(ra) # 80001bbc <proc_pagetable>
    8000567e:	8b2a                	mv	s6,a0
    80005680:	d555                	beqz	a0,8000562c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005682:	e7042783          	lw	a5,-400(s0)
    80005686:	e8845703          	lhu	a4,-376(s0)
    8000568a:	c735                	beqz	a4,800056f6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000568c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000568e:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80005692:	6a05                	lui	s4,0x1
    80005694:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005698:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000569c:	6d85                	lui	s11,0x1
    8000569e:	7d7d                	lui	s10,0xfffff
    800056a0:	ac1d                	j	800058d6 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800056a2:	00003517          	auipc	a0,0x3
    800056a6:	07e50513          	addi	a0,a0,126 # 80008720 <syscalls+0x2c0>
    800056aa:	ffffb097          	auipc	ra,0xffffb
    800056ae:	e92080e7          	jalr	-366(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800056b2:	874a                	mv	a4,s2
    800056b4:	009c86bb          	addw	a3,s9,s1
    800056b8:	4581                	li	a1,0
    800056ba:	8556                	mv	a0,s5
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	ca0080e7          	jalr	-864(ra) # 8000435c <readi>
    800056c4:	2501                	sext.w	a0,a0
    800056c6:	1aa91863          	bne	s2,a0,80005876 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800056ca:	009d84bb          	addw	s1,s11,s1
    800056ce:	013d09bb          	addw	s3,s10,s3
    800056d2:	1f74f263          	bgeu	s1,s7,800058b6 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800056d6:	02049593          	slli	a1,s1,0x20
    800056da:	9181                	srli	a1,a1,0x20
    800056dc:	95e2                	add	a1,a1,s8
    800056de:	855a                	mv	a0,s6
    800056e0:	ffffc097          	auipc	ra,0xffffc
    800056e4:	9ce080e7          	jalr	-1586(ra) # 800010ae <walkaddr>
    800056e8:	862a                	mv	a2,a0
    if(pa == 0)
    800056ea:	dd45                	beqz	a0,800056a2 <exec+0xfe>
      n = PGSIZE;
    800056ec:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800056ee:	fd49f2e3          	bgeu	s3,s4,800056b2 <exec+0x10e>
      n = sz - i;
    800056f2:	894e                	mv	s2,s3
    800056f4:	bf7d                	j	800056b2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056f6:	4481                	li	s1,0
  iunlockput(ip);
    800056f8:	8556                	mv	a0,s5
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	c10080e7          	jalr	-1008(ra) # 8000430a <iunlockput>
  end_op();
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	400080e7          	jalr	1024(ra) # 80004b02 <end_op>
  p = myproc();
    8000570a:	ffffc097          	auipc	ra,0xffffc
    8000570e:	3ea080e7          	jalr	1002(ra) # 80001af4 <myproc>
    80005712:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005714:	32053d03          	ld	s10,800(a0)
  sz = PGROUNDUP(sz);
    80005718:	6785                	lui	a5,0x1
    8000571a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000571c:	97a6                	add	a5,a5,s1
    8000571e:	777d                	lui	a4,0xfffff
    80005720:	8ff9                	and	a5,a5,a4
    80005722:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005726:	6609                	lui	a2,0x2
    80005728:	963e                	add	a2,a2,a5
    8000572a:	85be                	mv	a1,a5
    8000572c:	855a                	mv	a0,s6
    8000572e:	ffffc097          	auipc	ra,0xffffc
    80005732:	d16080e7          	jalr	-746(ra) # 80001444 <uvmalloc>
    80005736:	8c2a                	mv	s8,a0
  ip = 0;
    80005738:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000573a:	12050e63          	beqz	a0,80005876 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000573e:	75f9                	lui	a1,0xffffe
    80005740:	95aa                	add	a1,a1,a0
    80005742:	855a                	mv	a0,s6
    80005744:	ffffc097          	auipc	ra,0xffffc
    80005748:	fc4080e7          	jalr	-60(ra) # 80001708 <uvmclear>
  stackbase = sp - PGSIZE;
    8000574c:	7afd                	lui	s5,0xfffff
    8000574e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005750:	df043783          	ld	a5,-528(s0)
    80005754:	6388                	ld	a0,0(a5)
    80005756:	c925                	beqz	a0,800057c6 <exec+0x222>
    80005758:	e9040993          	addi	s3,s0,-368
    8000575c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005760:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005762:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005764:	ffffb097          	auipc	ra,0xffffb
    80005768:	730080e7          	jalr	1840(ra) # 80000e94 <strlen>
    8000576c:	0015079b          	addiw	a5,a0,1
    80005770:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005774:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005778:	13596363          	bltu	s2,s5,8000589e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000577c:	df043d83          	ld	s11,-528(s0)
    80005780:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005784:	8552                	mv	a0,s4
    80005786:	ffffb097          	auipc	ra,0xffffb
    8000578a:	70e080e7          	jalr	1806(ra) # 80000e94 <strlen>
    8000578e:	0015069b          	addiw	a3,a0,1
    80005792:	8652                	mv	a2,s4
    80005794:	85ca                	mv	a1,s2
    80005796:	855a                	mv	a0,s6
    80005798:	ffffc097          	auipc	ra,0xffffc
    8000579c:	fa2080e7          	jalr	-94(ra) # 8000173a <copyout>
    800057a0:	10054363          	bltz	a0,800058a6 <exec+0x302>
    ustack[argc] = sp;
    800057a4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800057a8:	0485                	addi	s1,s1,1
    800057aa:	008d8793          	addi	a5,s11,8
    800057ae:	def43823          	sd	a5,-528(s0)
    800057b2:	008db503          	ld	a0,8(s11)
    800057b6:	c911                	beqz	a0,800057ca <exec+0x226>
    if(argc >= MAXARG)
    800057b8:	09a1                	addi	s3,s3,8
    800057ba:	fb3c95e3          	bne	s9,s3,80005764 <exec+0x1c0>
  sz = sz1;
    800057be:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800057c2:	4a81                	li	s5,0
    800057c4:	a84d                	j	80005876 <exec+0x2d2>
  sp = sz;
    800057c6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800057c8:	4481                	li	s1,0
  ustack[argc] = 0;
    800057ca:	00349793          	slli	a5,s1,0x3
    800057ce:	f9078793          	addi	a5,a5,-112
    800057d2:	97a2                	add	a5,a5,s0
    800057d4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800057d8:	00148693          	addi	a3,s1,1
    800057dc:	068e                	slli	a3,a3,0x3
    800057de:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800057e2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800057e6:	01597663          	bgeu	s2,s5,800057f2 <exec+0x24e>
  sz = sz1;
    800057ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800057ee:	4a81                	li	s5,0
    800057f0:	a059                	j	80005876 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800057f2:	e9040613          	addi	a2,s0,-368
    800057f6:	85ca                	mv	a1,s2
    800057f8:	855a                	mv	a0,s6
    800057fa:	ffffc097          	auipc	ra,0xffffc
    800057fe:	f40080e7          	jalr	-192(ra) # 8000173a <copyout>
    80005802:	0a054663          	bltz	a0,800058ae <exec+0x30a>
  p->trapframe->a1 = sp;
    80005806:	330bb783          	ld	a5,816(s7)
    8000580a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000580e:	de843783          	ld	a5,-536(s0)
    80005812:	0007c703          	lbu	a4,0(a5)
    80005816:	cf11                	beqz	a4,80005832 <exec+0x28e>
    80005818:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000581a:	02f00693          	li	a3,47
    8000581e:	a039                	j	8000582c <exec+0x288>
      last = s+1;
    80005820:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005824:	0785                	addi	a5,a5,1
    80005826:	fff7c703          	lbu	a4,-1(a5)
    8000582a:	c701                	beqz	a4,80005832 <exec+0x28e>
    if(*s == '/')
    8000582c:	fed71ce3          	bne	a4,a3,80005824 <exec+0x280>
    80005830:	bfc5                	j	80005820 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005832:	4641                	li	a2,16
    80005834:	de843583          	ld	a1,-536(s0)
    80005838:	430b8513          	addi	a0,s7,1072
    8000583c:	ffffb097          	auipc	ra,0xffffb
    80005840:	626080e7          	jalr	1574(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80005844:	328bb503          	ld	a0,808(s7)
  p->pagetable = pagetable;
    80005848:	336bb423          	sd	s6,808(s7)
  p->sz = sz;
    8000584c:	338bb023          	sd	s8,800(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005850:	330bb783          	ld	a5,816(s7)
    80005854:	e6843703          	ld	a4,-408(s0)
    80005858:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000585a:	330bb783          	ld	a5,816(s7)
    8000585e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005862:	85ea                	mv	a1,s10
    80005864:	ffffc097          	auipc	ra,0xffffc
    80005868:	3f4080e7          	jalr	1012(ra) # 80001c58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000586c:	0004851b          	sext.w	a0,s1
    80005870:	bbc1                	j	80005640 <exec+0x9c>
    80005872:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005876:	df843583          	ld	a1,-520(s0)
    8000587a:	855a                	mv	a0,s6
    8000587c:	ffffc097          	auipc	ra,0xffffc
    80005880:	3dc080e7          	jalr	988(ra) # 80001c58 <proc_freepagetable>
  if(ip){
    80005884:	da0a94e3          	bnez	s5,8000562c <exec+0x88>
  return -1;
    80005888:	557d                	li	a0,-1
    8000588a:	bb5d                	j	80005640 <exec+0x9c>
    8000588c:	de943c23          	sd	s1,-520(s0)
    80005890:	b7dd                	j	80005876 <exec+0x2d2>
    80005892:	de943c23          	sd	s1,-520(s0)
    80005896:	b7c5                	j	80005876 <exec+0x2d2>
    80005898:	de943c23          	sd	s1,-520(s0)
    8000589c:	bfe9                	j	80005876 <exec+0x2d2>
  sz = sz1;
    8000589e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058a2:	4a81                	li	s5,0
    800058a4:	bfc9                	j	80005876 <exec+0x2d2>
  sz = sz1;
    800058a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058aa:	4a81                	li	s5,0
    800058ac:	b7e9                	j	80005876 <exec+0x2d2>
  sz = sz1;
    800058ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058b2:	4a81                	li	s5,0
    800058b4:	b7c9                	j	80005876 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800058b6:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058ba:	e0843783          	ld	a5,-504(s0)
    800058be:	0017869b          	addiw	a3,a5,1
    800058c2:	e0d43423          	sd	a3,-504(s0)
    800058c6:	e0043783          	ld	a5,-512(s0)
    800058ca:	0387879b          	addiw	a5,a5,56
    800058ce:	e8845703          	lhu	a4,-376(s0)
    800058d2:	e2e6d3e3          	bge	a3,a4,800056f8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800058d6:	2781                	sext.w	a5,a5
    800058d8:	e0f43023          	sd	a5,-512(s0)
    800058dc:	03800713          	li	a4,56
    800058e0:	86be                	mv	a3,a5
    800058e2:	e1840613          	addi	a2,s0,-488
    800058e6:	4581                	li	a1,0
    800058e8:	8556                	mv	a0,s5
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	a72080e7          	jalr	-1422(ra) # 8000435c <readi>
    800058f2:	03800793          	li	a5,56
    800058f6:	f6f51ee3          	bne	a0,a5,80005872 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800058fa:	e1842783          	lw	a5,-488(s0)
    800058fe:	4705                	li	a4,1
    80005900:	fae79de3          	bne	a5,a4,800058ba <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005904:	e4043603          	ld	a2,-448(s0)
    80005908:	e3843783          	ld	a5,-456(s0)
    8000590c:	f8f660e3          	bltu	a2,a5,8000588c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005910:	e2843783          	ld	a5,-472(s0)
    80005914:	963e                	add	a2,a2,a5
    80005916:	f6f66ee3          	bltu	a2,a5,80005892 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000591a:	85a6                	mv	a1,s1
    8000591c:	855a                	mv	a0,s6
    8000591e:	ffffc097          	auipc	ra,0xffffc
    80005922:	b26080e7          	jalr	-1242(ra) # 80001444 <uvmalloc>
    80005926:	dea43c23          	sd	a0,-520(s0)
    8000592a:	d53d                	beqz	a0,80005898 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000592c:	e2843c03          	ld	s8,-472(s0)
    80005930:	de043783          	ld	a5,-544(s0)
    80005934:	00fc77b3          	and	a5,s8,a5
    80005938:	ff9d                	bnez	a5,80005876 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000593a:	e2042c83          	lw	s9,-480(s0)
    8000593e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005942:	f60b8ae3          	beqz	s7,800058b6 <exec+0x312>
    80005946:	89de                	mv	s3,s7
    80005948:	4481                	li	s1,0
    8000594a:	b371                	j	800056d6 <exec+0x132>

000000008000594c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000594c:	7179                	addi	sp,sp,-48
    8000594e:	f406                	sd	ra,40(sp)
    80005950:	f022                	sd	s0,32(sp)
    80005952:	ec26                	sd	s1,24(sp)
    80005954:	e84a                	sd	s2,16(sp)
    80005956:	1800                	addi	s0,sp,48
    80005958:	892e                	mv	s2,a1
    8000595a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000595c:	fdc40593          	addi	a1,s0,-36
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	8f6080e7          	jalr	-1802(ra) # 80003256 <argint>
    80005968:	04054063          	bltz	a0,800059a8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000596c:	fdc42703          	lw	a4,-36(s0)
    80005970:	47bd                	li	a5,15
    80005972:	02e7ed63          	bltu	a5,a4,800059ac <argfd+0x60>
    80005976:	ffffc097          	auipc	ra,0xffffc
    8000597a:	17e080e7          	jalr	382(ra) # 80001af4 <myproc>
    8000597e:	fdc42703          	lw	a4,-36(s0)
    80005982:	07470793          	addi	a5,a4,116 # fffffffffffff074 <end+0xffffffff7ffc83dc>
    80005986:	078e                	slli	a5,a5,0x3
    80005988:	953e                	add	a0,a0,a5
    8000598a:	651c                	ld	a5,8(a0)
    8000598c:	c395                	beqz	a5,800059b0 <argfd+0x64>
    return -1;
  if(pfd)
    8000598e:	00090463          	beqz	s2,80005996 <argfd+0x4a>
    *pfd = fd;
    80005992:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005996:	4501                	li	a0,0
  if(pf)
    80005998:	c091                	beqz	s1,8000599c <argfd+0x50>
    *pf = f;
    8000599a:	e09c                	sd	a5,0(s1)
}
    8000599c:	70a2                	ld	ra,40(sp)
    8000599e:	7402                	ld	s0,32(sp)
    800059a0:	64e2                	ld	s1,24(sp)
    800059a2:	6942                	ld	s2,16(sp)
    800059a4:	6145                	addi	sp,sp,48
    800059a6:	8082                	ret
    return -1;
    800059a8:	557d                	li	a0,-1
    800059aa:	bfcd                	j	8000599c <argfd+0x50>
    return -1;
    800059ac:	557d                	li	a0,-1
    800059ae:	b7fd                	j	8000599c <argfd+0x50>
    800059b0:	557d                	li	a0,-1
    800059b2:	b7ed                	j	8000599c <argfd+0x50>

00000000800059b4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800059b4:	1101                	addi	sp,sp,-32
    800059b6:	ec06                	sd	ra,24(sp)
    800059b8:	e822                	sd	s0,16(sp)
    800059ba:	e426                	sd	s1,8(sp)
    800059bc:	1000                	addi	s0,sp,32
    800059be:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800059c0:	ffffc097          	auipc	ra,0xffffc
    800059c4:	134080e7          	jalr	308(ra) # 80001af4 <myproc>
    800059c8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800059ca:	3a850793          	addi	a5,a0,936
    800059ce:	4501                	li	a0,0
    800059d0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800059d2:	6398                	ld	a4,0(a5)
    800059d4:	cb19                	beqz	a4,800059ea <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800059d6:	2505                	addiw	a0,a0,1
    800059d8:	07a1                	addi	a5,a5,8
    800059da:	fed51ce3          	bne	a0,a3,800059d2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800059de:	557d                	li	a0,-1
}
    800059e0:	60e2                	ld	ra,24(sp)
    800059e2:	6442                	ld	s0,16(sp)
    800059e4:	64a2                	ld	s1,8(sp)
    800059e6:	6105                	addi	sp,sp,32
    800059e8:	8082                	ret
      p->ofile[fd] = f;
    800059ea:	07450793          	addi	a5,a0,116
    800059ee:	078e                	slli	a5,a5,0x3
    800059f0:	963e                	add	a2,a2,a5
    800059f2:	e604                	sd	s1,8(a2)
      return fd;
    800059f4:	b7f5                	j	800059e0 <fdalloc+0x2c>

00000000800059f6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800059f6:	715d                	addi	sp,sp,-80
    800059f8:	e486                	sd	ra,72(sp)
    800059fa:	e0a2                	sd	s0,64(sp)
    800059fc:	fc26                	sd	s1,56(sp)
    800059fe:	f84a                	sd	s2,48(sp)
    80005a00:	f44e                	sd	s3,40(sp)
    80005a02:	f052                	sd	s4,32(sp)
    80005a04:	ec56                	sd	s5,24(sp)
    80005a06:	0880                	addi	s0,sp,80
    80005a08:	89ae                	mv	s3,a1
    80005a0a:	8ab2                	mv	s5,a2
    80005a0c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005a0e:	fb040593          	addi	a1,s0,-80
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	e70080e7          	jalr	-400(ra) # 80004882 <nameiparent>
    80005a1a:	892a                	mv	s2,a0
    80005a1c:	12050e63          	beqz	a0,80005b58 <create+0x162>
    return 0;

  ilock(dp);
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	688080e7          	jalr	1672(ra) # 800040a8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005a28:	4601                	li	a2,0
    80005a2a:	fb040593          	addi	a1,s0,-80
    80005a2e:	854a                	mv	a0,s2
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	b5c080e7          	jalr	-1188(ra) # 8000458c <dirlookup>
    80005a38:	84aa                	mv	s1,a0
    80005a3a:	c921                	beqz	a0,80005a8a <create+0x94>
    iunlockput(dp);
    80005a3c:	854a                	mv	a0,s2
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	8cc080e7          	jalr	-1844(ra) # 8000430a <iunlockput>
    ilock(ip);
    80005a46:	8526                	mv	a0,s1
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	660080e7          	jalr	1632(ra) # 800040a8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005a50:	2981                	sext.w	s3,s3
    80005a52:	4789                	li	a5,2
    80005a54:	02f99463          	bne	s3,a5,80005a7c <create+0x86>
    80005a58:	0444d783          	lhu	a5,68(s1)
    80005a5c:	37f9                	addiw	a5,a5,-2
    80005a5e:	17c2                	slli	a5,a5,0x30
    80005a60:	93c1                	srli	a5,a5,0x30
    80005a62:	4705                	li	a4,1
    80005a64:	00f76c63          	bltu	a4,a5,80005a7c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005a68:	8526                	mv	a0,s1
    80005a6a:	60a6                	ld	ra,72(sp)
    80005a6c:	6406                	ld	s0,64(sp)
    80005a6e:	74e2                	ld	s1,56(sp)
    80005a70:	7942                	ld	s2,48(sp)
    80005a72:	79a2                	ld	s3,40(sp)
    80005a74:	7a02                	ld	s4,32(sp)
    80005a76:	6ae2                	ld	s5,24(sp)
    80005a78:	6161                	addi	sp,sp,80
    80005a7a:	8082                	ret
    iunlockput(ip);
    80005a7c:	8526                	mv	a0,s1
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	88c080e7          	jalr	-1908(ra) # 8000430a <iunlockput>
    return 0;
    80005a86:	4481                	li	s1,0
    80005a88:	b7c5                	j	80005a68 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005a8a:	85ce                	mv	a1,s3
    80005a8c:	00092503          	lw	a0,0(s2)
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	47e080e7          	jalr	1150(ra) # 80003f0e <ialloc>
    80005a98:	84aa                	mv	s1,a0
    80005a9a:	c521                	beqz	a0,80005ae2 <create+0xec>
  ilock(ip);
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	60c080e7          	jalr	1548(ra) # 800040a8 <ilock>
  ip->major = major;
    80005aa4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005aa8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005aac:	4a05                	li	s4,1
    80005aae:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	528080e7          	jalr	1320(ra) # 80003fdc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005abc:	2981                	sext.w	s3,s3
    80005abe:	03498a63          	beq	s3,s4,80005af2 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ac2:	40d0                	lw	a2,4(s1)
    80005ac4:	fb040593          	addi	a1,s0,-80
    80005ac8:	854a                	mv	a0,s2
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	cd8080e7          	jalr	-808(ra) # 800047a2 <dirlink>
    80005ad2:	06054b63          	bltz	a0,80005b48 <create+0x152>
  iunlockput(dp);
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	832080e7          	jalr	-1998(ra) # 8000430a <iunlockput>
  return ip;
    80005ae0:	b761                	j	80005a68 <create+0x72>
    panic("create: ialloc");
    80005ae2:	00003517          	auipc	a0,0x3
    80005ae6:	c5e50513          	addi	a0,a0,-930 # 80008740 <syscalls+0x2e0>
    80005aea:	ffffb097          	auipc	ra,0xffffb
    80005aee:	a52080e7          	jalr	-1454(ra) # 8000053c <panic>
    dp->nlink++;  // for ".."
    80005af2:	04a95783          	lhu	a5,74(s2)
    80005af6:	2785                	addiw	a5,a5,1
    80005af8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005afc:	854a                	mv	a0,s2
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	4de080e7          	jalr	1246(ra) # 80003fdc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005b06:	40d0                	lw	a2,4(s1)
    80005b08:	00003597          	auipc	a1,0x3
    80005b0c:	c4858593          	addi	a1,a1,-952 # 80008750 <syscalls+0x2f0>
    80005b10:	8526                	mv	a0,s1
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	c90080e7          	jalr	-880(ra) # 800047a2 <dirlink>
    80005b1a:	00054f63          	bltz	a0,80005b38 <create+0x142>
    80005b1e:	00492603          	lw	a2,4(s2)
    80005b22:	00003597          	auipc	a1,0x3
    80005b26:	c3658593          	addi	a1,a1,-970 # 80008758 <syscalls+0x2f8>
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	c76080e7          	jalr	-906(ra) # 800047a2 <dirlink>
    80005b34:	f80557e3          	bgez	a0,80005ac2 <create+0xcc>
      panic("create dots");
    80005b38:	00003517          	auipc	a0,0x3
    80005b3c:	c2850513          	addi	a0,a0,-984 # 80008760 <syscalls+0x300>
    80005b40:	ffffb097          	auipc	ra,0xffffb
    80005b44:	9fc080e7          	jalr	-1540(ra) # 8000053c <panic>
    panic("create: dirlink");
    80005b48:	00003517          	auipc	a0,0x3
    80005b4c:	c2850513          	addi	a0,a0,-984 # 80008770 <syscalls+0x310>
    80005b50:	ffffb097          	auipc	ra,0xffffb
    80005b54:	9ec080e7          	jalr	-1556(ra) # 8000053c <panic>
    return 0;
    80005b58:	84aa                	mv	s1,a0
    80005b5a:	b739                	j	80005a68 <create+0x72>

0000000080005b5c <sys_dup>:
{
    80005b5c:	7179                	addi	sp,sp,-48
    80005b5e:	f406                	sd	ra,40(sp)
    80005b60:	f022                	sd	s0,32(sp)
    80005b62:	ec26                	sd	s1,24(sp)
    80005b64:	e84a                	sd	s2,16(sp)
    80005b66:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005b68:	fd840613          	addi	a2,s0,-40
    80005b6c:	4581                	li	a1,0
    80005b6e:	4501                	li	a0,0
    80005b70:	00000097          	auipc	ra,0x0
    80005b74:	ddc080e7          	jalr	-548(ra) # 8000594c <argfd>
    return -1;
    80005b78:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b7a:	02054363          	bltz	a0,80005ba0 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005b7e:	fd843903          	ld	s2,-40(s0)
    80005b82:	854a                	mv	a0,s2
    80005b84:	00000097          	auipc	ra,0x0
    80005b88:	e30080e7          	jalr	-464(ra) # 800059b4 <fdalloc>
    80005b8c:	84aa                	mv	s1,a0
    return -1;
    80005b8e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b90:	00054863          	bltz	a0,80005ba0 <sys_dup+0x44>
  filedup(f);
    80005b94:	854a                	mv	a0,s2
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	368080e7          	jalr	872(ra) # 80004efe <filedup>
  return fd;
    80005b9e:	87a6                	mv	a5,s1
}
    80005ba0:	853e                	mv	a0,a5
    80005ba2:	70a2                	ld	ra,40(sp)
    80005ba4:	7402                	ld	s0,32(sp)
    80005ba6:	64e2                	ld	s1,24(sp)
    80005ba8:	6942                	ld	s2,16(sp)
    80005baa:	6145                	addi	sp,sp,48
    80005bac:	8082                	ret

0000000080005bae <sys_read>:
{
    80005bae:	7179                	addi	sp,sp,-48
    80005bb0:	f406                	sd	ra,40(sp)
    80005bb2:	f022                	sd	s0,32(sp)
    80005bb4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bb6:	fe840613          	addi	a2,s0,-24
    80005bba:	4581                	li	a1,0
    80005bbc:	4501                	li	a0,0
    80005bbe:	00000097          	auipc	ra,0x0
    80005bc2:	d8e080e7          	jalr	-626(ra) # 8000594c <argfd>
    return -1;
    80005bc6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bc8:	04054163          	bltz	a0,80005c0a <sys_read+0x5c>
    80005bcc:	fe440593          	addi	a1,s0,-28
    80005bd0:	4509                	li	a0,2
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	684080e7          	jalr	1668(ra) # 80003256 <argint>
    return -1;
    80005bda:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bdc:	02054763          	bltz	a0,80005c0a <sys_read+0x5c>
    80005be0:	fd840593          	addi	a1,s0,-40
    80005be4:	4505                	li	a0,1
    80005be6:	ffffd097          	auipc	ra,0xffffd
    80005bea:	692080e7          	jalr	1682(ra) # 80003278 <argaddr>
    return -1;
    80005bee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bf0:	00054d63          	bltz	a0,80005c0a <sys_read+0x5c>
  return fileread(f, p, n);
    80005bf4:	fe442603          	lw	a2,-28(s0)
    80005bf8:	fd843583          	ld	a1,-40(s0)
    80005bfc:	fe843503          	ld	a0,-24(s0)
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	48a080e7          	jalr	1162(ra) # 8000508a <fileread>
    80005c08:	87aa                	mv	a5,a0
}
    80005c0a:	853e                	mv	a0,a5
    80005c0c:	70a2                	ld	ra,40(sp)
    80005c0e:	7402                	ld	s0,32(sp)
    80005c10:	6145                	addi	sp,sp,48
    80005c12:	8082                	ret

0000000080005c14 <sys_write>:
{
    80005c14:	7179                	addi	sp,sp,-48
    80005c16:	f406                	sd	ra,40(sp)
    80005c18:	f022                	sd	s0,32(sp)
    80005c1a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c1c:	fe840613          	addi	a2,s0,-24
    80005c20:	4581                	li	a1,0
    80005c22:	4501                	li	a0,0
    80005c24:	00000097          	auipc	ra,0x0
    80005c28:	d28080e7          	jalr	-728(ra) # 8000594c <argfd>
    return -1;
    80005c2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c2e:	04054163          	bltz	a0,80005c70 <sys_write+0x5c>
    80005c32:	fe440593          	addi	a1,s0,-28
    80005c36:	4509                	li	a0,2
    80005c38:	ffffd097          	auipc	ra,0xffffd
    80005c3c:	61e080e7          	jalr	1566(ra) # 80003256 <argint>
    return -1;
    80005c40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c42:	02054763          	bltz	a0,80005c70 <sys_write+0x5c>
    80005c46:	fd840593          	addi	a1,s0,-40
    80005c4a:	4505                	li	a0,1
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	62c080e7          	jalr	1580(ra) # 80003278 <argaddr>
    return -1;
    80005c54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c56:	00054d63          	bltz	a0,80005c70 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005c5a:	fe442603          	lw	a2,-28(s0)
    80005c5e:	fd843583          	ld	a1,-40(s0)
    80005c62:	fe843503          	ld	a0,-24(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	4e6080e7          	jalr	1254(ra) # 8000514c <filewrite>
    80005c6e:	87aa                	mv	a5,a0
}
    80005c70:	853e                	mv	a0,a5
    80005c72:	70a2                	ld	ra,40(sp)
    80005c74:	7402                	ld	s0,32(sp)
    80005c76:	6145                	addi	sp,sp,48
    80005c78:	8082                	ret

0000000080005c7a <sys_close>:
{
    80005c7a:	1101                	addi	sp,sp,-32
    80005c7c:	ec06                	sd	ra,24(sp)
    80005c7e:	e822                	sd	s0,16(sp)
    80005c80:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005c82:	fe040613          	addi	a2,s0,-32
    80005c86:	fec40593          	addi	a1,s0,-20
    80005c8a:	4501                	li	a0,0
    80005c8c:	00000097          	auipc	ra,0x0
    80005c90:	cc0080e7          	jalr	-832(ra) # 8000594c <argfd>
    return -1;
    80005c94:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c96:	02054563          	bltz	a0,80005cc0 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005c9a:	ffffc097          	auipc	ra,0xffffc
    80005c9e:	e5a080e7          	jalr	-422(ra) # 80001af4 <myproc>
    80005ca2:	fec42783          	lw	a5,-20(s0)
    80005ca6:	07478793          	addi	a5,a5,116
    80005caa:	078e                	slli	a5,a5,0x3
    80005cac:	953e                	add	a0,a0,a5
    80005cae:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005cb2:	fe043503          	ld	a0,-32(s0)
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	29a080e7          	jalr	666(ra) # 80004f50 <fileclose>
  return 0;
    80005cbe:	4781                	li	a5,0
}
    80005cc0:	853e                	mv	a0,a5
    80005cc2:	60e2                	ld	ra,24(sp)
    80005cc4:	6442                	ld	s0,16(sp)
    80005cc6:	6105                	addi	sp,sp,32
    80005cc8:	8082                	ret

0000000080005cca <sys_fstat>:
{
    80005cca:	1101                	addi	sp,sp,-32
    80005ccc:	ec06                	sd	ra,24(sp)
    80005cce:	e822                	sd	s0,16(sp)
    80005cd0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cd2:	fe840613          	addi	a2,s0,-24
    80005cd6:	4581                	li	a1,0
    80005cd8:	4501                	li	a0,0
    80005cda:	00000097          	auipc	ra,0x0
    80005cde:	c72080e7          	jalr	-910(ra) # 8000594c <argfd>
    return -1;
    80005ce2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ce4:	02054563          	bltz	a0,80005d0e <sys_fstat+0x44>
    80005ce8:	fe040593          	addi	a1,s0,-32
    80005cec:	4505                	li	a0,1
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	58a080e7          	jalr	1418(ra) # 80003278 <argaddr>
    return -1;
    80005cf6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cf8:	00054b63          	bltz	a0,80005d0e <sys_fstat+0x44>
  return filestat(f, st);
    80005cfc:	fe043583          	ld	a1,-32(s0)
    80005d00:	fe843503          	ld	a0,-24(s0)
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	314080e7          	jalr	788(ra) # 80005018 <filestat>
    80005d0c:	87aa                	mv	a5,a0
}
    80005d0e:	853e                	mv	a0,a5
    80005d10:	60e2                	ld	ra,24(sp)
    80005d12:	6442                	ld	s0,16(sp)
    80005d14:	6105                	addi	sp,sp,32
    80005d16:	8082                	ret

0000000080005d18 <sys_link>:
{
    80005d18:	7169                	addi	sp,sp,-304
    80005d1a:	f606                	sd	ra,296(sp)
    80005d1c:	f222                	sd	s0,288(sp)
    80005d1e:	ee26                	sd	s1,280(sp)
    80005d20:	ea4a                	sd	s2,272(sp)
    80005d22:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d24:	08000613          	li	a2,128
    80005d28:	ed040593          	addi	a1,s0,-304
    80005d2c:	4501                	li	a0,0
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	56c080e7          	jalr	1388(ra) # 8000329a <argstr>
    return -1;
    80005d36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d38:	10054e63          	bltz	a0,80005e54 <sys_link+0x13c>
    80005d3c:	08000613          	li	a2,128
    80005d40:	f5040593          	addi	a1,s0,-176
    80005d44:	4505                	li	a0,1
    80005d46:	ffffd097          	auipc	ra,0xffffd
    80005d4a:	554080e7          	jalr	1364(ra) # 8000329a <argstr>
    return -1;
    80005d4e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d50:	10054263          	bltz	a0,80005e54 <sys_link+0x13c>
  begin_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	d30080e7          	jalr	-720(ra) # 80004a84 <begin_op>
  if((ip = namei(old)) == 0){
    80005d5c:	ed040513          	addi	a0,s0,-304
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	b04080e7          	jalr	-1276(ra) # 80004864 <namei>
    80005d68:	84aa                	mv	s1,a0
    80005d6a:	c551                	beqz	a0,80005df6 <sys_link+0xde>
  ilock(ip);
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	33c080e7          	jalr	828(ra) # 800040a8 <ilock>
  if(ip->type == T_DIR){
    80005d74:	04449703          	lh	a4,68(s1)
    80005d78:	4785                	li	a5,1
    80005d7a:	08f70463          	beq	a4,a5,80005e02 <sys_link+0xea>
  ip->nlink++;
    80005d7e:	04a4d783          	lhu	a5,74(s1)
    80005d82:	2785                	addiw	a5,a5,1
    80005d84:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d88:	8526                	mv	a0,s1
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	252080e7          	jalr	594(ra) # 80003fdc <iupdate>
  iunlock(ip);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	3d6080e7          	jalr	982(ra) # 8000416a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d9c:	fd040593          	addi	a1,s0,-48
    80005da0:	f5040513          	addi	a0,s0,-176
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	ade080e7          	jalr	-1314(ra) # 80004882 <nameiparent>
    80005dac:	892a                	mv	s2,a0
    80005dae:	c935                	beqz	a0,80005e22 <sys_link+0x10a>
  ilock(dp);
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	2f8080e7          	jalr	760(ra) # 800040a8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005db8:	00092703          	lw	a4,0(s2)
    80005dbc:	409c                	lw	a5,0(s1)
    80005dbe:	04f71d63          	bne	a4,a5,80005e18 <sys_link+0x100>
    80005dc2:	40d0                	lw	a2,4(s1)
    80005dc4:	fd040593          	addi	a1,s0,-48
    80005dc8:	854a                	mv	a0,s2
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	9d8080e7          	jalr	-1576(ra) # 800047a2 <dirlink>
    80005dd2:	04054363          	bltz	a0,80005e18 <sys_link+0x100>
  iunlockput(dp);
    80005dd6:	854a                	mv	a0,s2
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	532080e7          	jalr	1330(ra) # 8000430a <iunlockput>
  iput(ip);
    80005de0:	8526                	mv	a0,s1
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	480080e7          	jalr	1152(ra) # 80004262 <iput>
  end_op();
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	d18080e7          	jalr	-744(ra) # 80004b02 <end_op>
  return 0;
    80005df2:	4781                	li	a5,0
    80005df4:	a085                	j	80005e54 <sys_link+0x13c>
    end_op();
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	d0c080e7          	jalr	-756(ra) # 80004b02 <end_op>
    return -1;
    80005dfe:	57fd                	li	a5,-1
    80005e00:	a891                	j	80005e54 <sys_link+0x13c>
    iunlockput(ip);
    80005e02:	8526                	mv	a0,s1
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	506080e7          	jalr	1286(ra) # 8000430a <iunlockput>
    end_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	cf6080e7          	jalr	-778(ra) # 80004b02 <end_op>
    return -1;
    80005e14:	57fd                	li	a5,-1
    80005e16:	a83d                	j	80005e54 <sys_link+0x13c>
    iunlockput(dp);
    80005e18:	854a                	mv	a0,s2
    80005e1a:	ffffe097          	auipc	ra,0xffffe
    80005e1e:	4f0080e7          	jalr	1264(ra) # 8000430a <iunlockput>
  ilock(ip);
    80005e22:	8526                	mv	a0,s1
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	284080e7          	jalr	644(ra) # 800040a8 <ilock>
  ip->nlink--;
    80005e2c:	04a4d783          	lhu	a5,74(s1)
    80005e30:	37fd                	addiw	a5,a5,-1
    80005e32:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e36:	8526                	mv	a0,s1
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	1a4080e7          	jalr	420(ra) # 80003fdc <iupdate>
  iunlockput(ip);
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	4c8080e7          	jalr	1224(ra) # 8000430a <iunlockput>
  end_op();
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	cb8080e7          	jalr	-840(ra) # 80004b02 <end_op>
  return -1;
    80005e52:	57fd                	li	a5,-1
}
    80005e54:	853e                	mv	a0,a5
    80005e56:	70b2                	ld	ra,296(sp)
    80005e58:	7412                	ld	s0,288(sp)
    80005e5a:	64f2                	ld	s1,280(sp)
    80005e5c:	6952                	ld	s2,272(sp)
    80005e5e:	6155                	addi	sp,sp,304
    80005e60:	8082                	ret

0000000080005e62 <sys_unlink>:
{
    80005e62:	7151                	addi	sp,sp,-240
    80005e64:	f586                	sd	ra,232(sp)
    80005e66:	f1a2                	sd	s0,224(sp)
    80005e68:	eda6                	sd	s1,216(sp)
    80005e6a:	e9ca                	sd	s2,208(sp)
    80005e6c:	e5ce                	sd	s3,200(sp)
    80005e6e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005e70:	08000613          	li	a2,128
    80005e74:	f3040593          	addi	a1,s0,-208
    80005e78:	4501                	li	a0,0
    80005e7a:	ffffd097          	auipc	ra,0xffffd
    80005e7e:	420080e7          	jalr	1056(ra) # 8000329a <argstr>
    80005e82:	18054163          	bltz	a0,80006004 <sys_unlink+0x1a2>
  begin_op();
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	bfe080e7          	jalr	-1026(ra) # 80004a84 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e8e:	fb040593          	addi	a1,s0,-80
    80005e92:	f3040513          	addi	a0,s0,-208
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	9ec080e7          	jalr	-1556(ra) # 80004882 <nameiparent>
    80005e9e:	84aa                	mv	s1,a0
    80005ea0:	c979                	beqz	a0,80005f76 <sys_unlink+0x114>
  ilock(dp);
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	206080e7          	jalr	518(ra) # 800040a8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005eaa:	00003597          	auipc	a1,0x3
    80005eae:	8a658593          	addi	a1,a1,-1882 # 80008750 <syscalls+0x2f0>
    80005eb2:	fb040513          	addi	a0,s0,-80
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	6bc080e7          	jalr	1724(ra) # 80004572 <namecmp>
    80005ebe:	14050a63          	beqz	a0,80006012 <sys_unlink+0x1b0>
    80005ec2:	00003597          	auipc	a1,0x3
    80005ec6:	89658593          	addi	a1,a1,-1898 # 80008758 <syscalls+0x2f8>
    80005eca:	fb040513          	addi	a0,s0,-80
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	6a4080e7          	jalr	1700(ra) # 80004572 <namecmp>
    80005ed6:	12050e63          	beqz	a0,80006012 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005eda:	f2c40613          	addi	a2,s0,-212
    80005ede:	fb040593          	addi	a1,s0,-80
    80005ee2:	8526                	mv	a0,s1
    80005ee4:	ffffe097          	auipc	ra,0xffffe
    80005ee8:	6a8080e7          	jalr	1704(ra) # 8000458c <dirlookup>
    80005eec:	892a                	mv	s2,a0
    80005eee:	12050263          	beqz	a0,80006012 <sys_unlink+0x1b0>
  ilock(ip);
    80005ef2:	ffffe097          	auipc	ra,0xffffe
    80005ef6:	1b6080e7          	jalr	438(ra) # 800040a8 <ilock>
  if(ip->nlink < 1)
    80005efa:	04a91783          	lh	a5,74(s2)
    80005efe:	08f05263          	blez	a5,80005f82 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f02:	04491703          	lh	a4,68(s2)
    80005f06:	4785                	li	a5,1
    80005f08:	08f70563          	beq	a4,a5,80005f92 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005f0c:	4641                	li	a2,16
    80005f0e:	4581                	li	a1,0
    80005f10:	fc040513          	addi	a0,s0,-64
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	e04080e7          	jalr	-508(ra) # 80000d18 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f1c:	4741                	li	a4,16
    80005f1e:	f2c42683          	lw	a3,-212(s0)
    80005f22:	fc040613          	addi	a2,s0,-64
    80005f26:	4581                	li	a1,0
    80005f28:	8526                	mv	a0,s1
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	52a080e7          	jalr	1322(ra) # 80004454 <writei>
    80005f32:	47c1                	li	a5,16
    80005f34:	0af51563          	bne	a0,a5,80005fde <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005f38:	04491703          	lh	a4,68(s2)
    80005f3c:	4785                	li	a5,1
    80005f3e:	0af70863          	beq	a4,a5,80005fee <sys_unlink+0x18c>
  iunlockput(dp);
    80005f42:	8526                	mv	a0,s1
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	3c6080e7          	jalr	966(ra) # 8000430a <iunlockput>
  ip->nlink--;
    80005f4c:	04a95783          	lhu	a5,74(s2)
    80005f50:	37fd                	addiw	a5,a5,-1
    80005f52:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005f56:	854a                	mv	a0,s2
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	084080e7          	jalr	132(ra) # 80003fdc <iupdate>
  iunlockput(ip);
    80005f60:	854a                	mv	a0,s2
    80005f62:	ffffe097          	auipc	ra,0xffffe
    80005f66:	3a8080e7          	jalr	936(ra) # 8000430a <iunlockput>
  end_op();
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	b98080e7          	jalr	-1128(ra) # 80004b02 <end_op>
  return 0;
    80005f72:	4501                	li	a0,0
    80005f74:	a84d                	j	80006026 <sys_unlink+0x1c4>
    end_op();
    80005f76:	fffff097          	auipc	ra,0xfffff
    80005f7a:	b8c080e7          	jalr	-1140(ra) # 80004b02 <end_op>
    return -1;
    80005f7e:	557d                	li	a0,-1
    80005f80:	a05d                	j	80006026 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005f82:	00002517          	auipc	a0,0x2
    80005f86:	7fe50513          	addi	a0,a0,2046 # 80008780 <syscalls+0x320>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b2080e7          	jalr	1458(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f92:	04c92703          	lw	a4,76(s2)
    80005f96:	02000793          	li	a5,32
    80005f9a:	f6e7f9e3          	bgeu	a5,a4,80005f0c <sys_unlink+0xaa>
    80005f9e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005fa2:	4741                	li	a4,16
    80005fa4:	86ce                	mv	a3,s3
    80005fa6:	f1840613          	addi	a2,s0,-232
    80005faa:	4581                	li	a1,0
    80005fac:	854a                	mv	a0,s2
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	3ae080e7          	jalr	942(ra) # 8000435c <readi>
    80005fb6:	47c1                	li	a5,16
    80005fb8:	00f51b63          	bne	a0,a5,80005fce <sys_unlink+0x16c>
    if(de.inum != 0)
    80005fbc:	f1845783          	lhu	a5,-232(s0)
    80005fc0:	e7a1                	bnez	a5,80006008 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005fc2:	29c1                	addiw	s3,s3,16
    80005fc4:	04c92783          	lw	a5,76(s2)
    80005fc8:	fcf9ede3          	bltu	s3,a5,80005fa2 <sys_unlink+0x140>
    80005fcc:	b781                	j	80005f0c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005fce:	00002517          	auipc	a0,0x2
    80005fd2:	7ca50513          	addi	a0,a0,1994 # 80008798 <syscalls+0x338>
    80005fd6:	ffffa097          	auipc	ra,0xffffa
    80005fda:	566080e7          	jalr	1382(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005fde:	00002517          	auipc	a0,0x2
    80005fe2:	7d250513          	addi	a0,a0,2002 # 800087b0 <syscalls+0x350>
    80005fe6:	ffffa097          	auipc	ra,0xffffa
    80005fea:	556080e7          	jalr	1366(ra) # 8000053c <panic>
    dp->nlink--;
    80005fee:	04a4d783          	lhu	a5,74(s1)
    80005ff2:	37fd                	addiw	a5,a5,-1
    80005ff4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ff8:	8526                	mv	a0,s1
    80005ffa:	ffffe097          	auipc	ra,0xffffe
    80005ffe:	fe2080e7          	jalr	-30(ra) # 80003fdc <iupdate>
    80006002:	b781                	j	80005f42 <sys_unlink+0xe0>
    return -1;
    80006004:	557d                	li	a0,-1
    80006006:	a005                	j	80006026 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006008:	854a                	mv	a0,s2
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	300080e7          	jalr	768(ra) # 8000430a <iunlockput>
  iunlockput(dp);
    80006012:	8526                	mv	a0,s1
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	2f6080e7          	jalr	758(ra) # 8000430a <iunlockput>
  end_op();
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	ae6080e7          	jalr	-1306(ra) # 80004b02 <end_op>
  return -1;
    80006024:	557d                	li	a0,-1
}
    80006026:	70ae                	ld	ra,232(sp)
    80006028:	740e                	ld	s0,224(sp)
    8000602a:	64ee                	ld	s1,216(sp)
    8000602c:	694e                	ld	s2,208(sp)
    8000602e:	69ae                	ld	s3,200(sp)
    80006030:	616d                	addi	sp,sp,240
    80006032:	8082                	ret

0000000080006034 <sys_open>:

uint64
sys_open(void)
{
    80006034:	7131                	addi	sp,sp,-192
    80006036:	fd06                	sd	ra,184(sp)
    80006038:	f922                	sd	s0,176(sp)
    8000603a:	f526                	sd	s1,168(sp)
    8000603c:	f14a                	sd	s2,160(sp)
    8000603e:	ed4e                	sd	s3,152(sp)
    80006040:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006042:	08000613          	li	a2,128
    80006046:	f5040593          	addi	a1,s0,-176
    8000604a:	4501                	li	a0,0
    8000604c:	ffffd097          	auipc	ra,0xffffd
    80006050:	24e080e7          	jalr	590(ra) # 8000329a <argstr>
    return -1;
    80006054:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006056:	0c054163          	bltz	a0,80006118 <sys_open+0xe4>
    8000605a:	f4c40593          	addi	a1,s0,-180
    8000605e:	4505                	li	a0,1
    80006060:	ffffd097          	auipc	ra,0xffffd
    80006064:	1f6080e7          	jalr	502(ra) # 80003256 <argint>
    80006068:	0a054863          	bltz	a0,80006118 <sys_open+0xe4>

  begin_op();
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	a18080e7          	jalr	-1512(ra) # 80004a84 <begin_op>

  if(omode & O_CREATE){
    80006074:	f4c42783          	lw	a5,-180(s0)
    80006078:	2007f793          	andi	a5,a5,512
    8000607c:	cbdd                	beqz	a5,80006132 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000607e:	4681                	li	a3,0
    80006080:	4601                	li	a2,0
    80006082:	4589                	li	a1,2
    80006084:	f5040513          	addi	a0,s0,-176
    80006088:	00000097          	auipc	ra,0x0
    8000608c:	96e080e7          	jalr	-1682(ra) # 800059f6 <create>
    80006090:	892a                	mv	s2,a0
    if(ip == 0){
    80006092:	c959                	beqz	a0,80006128 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006094:	04491703          	lh	a4,68(s2)
    80006098:	478d                	li	a5,3
    8000609a:	00f71763          	bne	a4,a5,800060a8 <sys_open+0x74>
    8000609e:	04695703          	lhu	a4,70(s2)
    800060a2:	47a5                	li	a5,9
    800060a4:	0ce7ec63          	bltu	a5,a4,8000617c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800060a8:	fffff097          	auipc	ra,0xfffff
    800060ac:	dec080e7          	jalr	-532(ra) # 80004e94 <filealloc>
    800060b0:	89aa                	mv	s3,a0
    800060b2:	10050263          	beqz	a0,800061b6 <sys_open+0x182>
    800060b6:	00000097          	auipc	ra,0x0
    800060ba:	8fe080e7          	jalr	-1794(ra) # 800059b4 <fdalloc>
    800060be:	84aa                	mv	s1,a0
    800060c0:	0e054663          	bltz	a0,800061ac <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800060c4:	04491703          	lh	a4,68(s2)
    800060c8:	478d                	li	a5,3
    800060ca:	0cf70463          	beq	a4,a5,80006192 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800060ce:	4789                	li	a5,2
    800060d0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800060d4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800060d8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800060dc:	f4c42783          	lw	a5,-180(s0)
    800060e0:	0017c713          	xori	a4,a5,1
    800060e4:	8b05                	andi	a4,a4,1
    800060e6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800060ea:	0037f713          	andi	a4,a5,3
    800060ee:	00e03733          	snez	a4,a4
    800060f2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800060f6:	4007f793          	andi	a5,a5,1024
    800060fa:	c791                	beqz	a5,80006106 <sys_open+0xd2>
    800060fc:	04491703          	lh	a4,68(s2)
    80006100:	4789                	li	a5,2
    80006102:	08f70f63          	beq	a4,a5,800061a0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006106:	854a                	mv	a0,s2
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	062080e7          	jalr	98(ra) # 8000416a <iunlock>
  end_op();
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	9f2080e7          	jalr	-1550(ra) # 80004b02 <end_op>

  return fd;
}
    80006118:	8526                	mv	a0,s1
    8000611a:	70ea                	ld	ra,184(sp)
    8000611c:	744a                	ld	s0,176(sp)
    8000611e:	74aa                	ld	s1,168(sp)
    80006120:	790a                	ld	s2,160(sp)
    80006122:	69ea                	ld	s3,152(sp)
    80006124:	6129                	addi	sp,sp,192
    80006126:	8082                	ret
      end_op();
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	9da080e7          	jalr	-1574(ra) # 80004b02 <end_op>
      return -1;
    80006130:	b7e5                	j	80006118 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006132:	f5040513          	addi	a0,s0,-176
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	72e080e7          	jalr	1838(ra) # 80004864 <namei>
    8000613e:	892a                	mv	s2,a0
    80006140:	c905                	beqz	a0,80006170 <sys_open+0x13c>
    ilock(ip);
    80006142:	ffffe097          	auipc	ra,0xffffe
    80006146:	f66080e7          	jalr	-154(ra) # 800040a8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000614a:	04491703          	lh	a4,68(s2)
    8000614e:	4785                	li	a5,1
    80006150:	f4f712e3          	bne	a4,a5,80006094 <sys_open+0x60>
    80006154:	f4c42783          	lw	a5,-180(s0)
    80006158:	dba1                	beqz	a5,800060a8 <sys_open+0x74>
      iunlockput(ip);
    8000615a:	854a                	mv	a0,s2
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	1ae080e7          	jalr	430(ra) # 8000430a <iunlockput>
      end_op();
    80006164:	fffff097          	auipc	ra,0xfffff
    80006168:	99e080e7          	jalr	-1634(ra) # 80004b02 <end_op>
      return -1;
    8000616c:	54fd                	li	s1,-1
    8000616e:	b76d                	j	80006118 <sys_open+0xe4>
      end_op();
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	992080e7          	jalr	-1646(ra) # 80004b02 <end_op>
      return -1;
    80006178:	54fd                	li	s1,-1
    8000617a:	bf79                	j	80006118 <sys_open+0xe4>
    iunlockput(ip);
    8000617c:	854a                	mv	a0,s2
    8000617e:	ffffe097          	auipc	ra,0xffffe
    80006182:	18c080e7          	jalr	396(ra) # 8000430a <iunlockput>
    end_op();
    80006186:	fffff097          	auipc	ra,0xfffff
    8000618a:	97c080e7          	jalr	-1668(ra) # 80004b02 <end_op>
    return -1;
    8000618e:	54fd                	li	s1,-1
    80006190:	b761                	j	80006118 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006192:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006196:	04691783          	lh	a5,70(s2)
    8000619a:	02f99223          	sh	a5,36(s3)
    8000619e:	bf2d                	j	800060d8 <sys_open+0xa4>
    itrunc(ip);
    800061a0:	854a                	mv	a0,s2
    800061a2:	ffffe097          	auipc	ra,0xffffe
    800061a6:	014080e7          	jalr	20(ra) # 800041b6 <itrunc>
    800061aa:	bfb1                	j	80006106 <sys_open+0xd2>
      fileclose(f);
    800061ac:	854e                	mv	a0,s3
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	da2080e7          	jalr	-606(ra) # 80004f50 <fileclose>
    iunlockput(ip);
    800061b6:	854a                	mv	a0,s2
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	152080e7          	jalr	338(ra) # 8000430a <iunlockput>
    end_op();
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	942080e7          	jalr	-1726(ra) # 80004b02 <end_op>
    return -1;
    800061c8:	54fd                	li	s1,-1
    800061ca:	b7b9                	j	80006118 <sys_open+0xe4>

00000000800061cc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800061cc:	7175                	addi	sp,sp,-144
    800061ce:	e506                	sd	ra,136(sp)
    800061d0:	e122                	sd	s0,128(sp)
    800061d2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800061d4:	fffff097          	auipc	ra,0xfffff
    800061d8:	8b0080e7          	jalr	-1872(ra) # 80004a84 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800061dc:	08000613          	li	a2,128
    800061e0:	f7040593          	addi	a1,s0,-144
    800061e4:	4501                	li	a0,0
    800061e6:	ffffd097          	auipc	ra,0xffffd
    800061ea:	0b4080e7          	jalr	180(ra) # 8000329a <argstr>
    800061ee:	02054963          	bltz	a0,80006220 <sys_mkdir+0x54>
    800061f2:	4681                	li	a3,0
    800061f4:	4601                	li	a2,0
    800061f6:	4585                	li	a1,1
    800061f8:	f7040513          	addi	a0,s0,-144
    800061fc:	fffff097          	auipc	ra,0xfffff
    80006200:	7fa080e7          	jalr	2042(ra) # 800059f6 <create>
    80006204:	cd11                	beqz	a0,80006220 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006206:	ffffe097          	auipc	ra,0xffffe
    8000620a:	104080e7          	jalr	260(ra) # 8000430a <iunlockput>
  end_op();
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	8f4080e7          	jalr	-1804(ra) # 80004b02 <end_op>
  return 0;
    80006216:	4501                	li	a0,0
}
    80006218:	60aa                	ld	ra,136(sp)
    8000621a:	640a                	ld	s0,128(sp)
    8000621c:	6149                	addi	sp,sp,144
    8000621e:	8082                	ret
    end_op();
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	8e2080e7          	jalr	-1822(ra) # 80004b02 <end_op>
    return -1;
    80006228:	557d                	li	a0,-1
    8000622a:	b7fd                	j	80006218 <sys_mkdir+0x4c>

000000008000622c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000622c:	7135                	addi	sp,sp,-160
    8000622e:	ed06                	sd	ra,152(sp)
    80006230:	e922                	sd	s0,144(sp)
    80006232:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006234:	fffff097          	auipc	ra,0xfffff
    80006238:	850080e7          	jalr	-1968(ra) # 80004a84 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000623c:	08000613          	li	a2,128
    80006240:	f7040593          	addi	a1,s0,-144
    80006244:	4501                	li	a0,0
    80006246:	ffffd097          	auipc	ra,0xffffd
    8000624a:	054080e7          	jalr	84(ra) # 8000329a <argstr>
    8000624e:	04054a63          	bltz	a0,800062a2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006252:	f6c40593          	addi	a1,s0,-148
    80006256:	4505                	li	a0,1
    80006258:	ffffd097          	auipc	ra,0xffffd
    8000625c:	ffe080e7          	jalr	-2(ra) # 80003256 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006260:	04054163          	bltz	a0,800062a2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006264:	f6840593          	addi	a1,s0,-152
    80006268:	4509                	li	a0,2
    8000626a:	ffffd097          	auipc	ra,0xffffd
    8000626e:	fec080e7          	jalr	-20(ra) # 80003256 <argint>
     argint(1, &major) < 0 ||
    80006272:	02054863          	bltz	a0,800062a2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006276:	f6841683          	lh	a3,-152(s0)
    8000627a:	f6c41603          	lh	a2,-148(s0)
    8000627e:	458d                	li	a1,3
    80006280:	f7040513          	addi	a0,s0,-144
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	772080e7          	jalr	1906(ra) # 800059f6 <create>
     argint(2, &minor) < 0 ||
    8000628c:	c919                	beqz	a0,800062a2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000628e:	ffffe097          	auipc	ra,0xffffe
    80006292:	07c080e7          	jalr	124(ra) # 8000430a <iunlockput>
  end_op();
    80006296:	fffff097          	auipc	ra,0xfffff
    8000629a:	86c080e7          	jalr	-1940(ra) # 80004b02 <end_op>
  return 0;
    8000629e:	4501                	li	a0,0
    800062a0:	a031                	j	800062ac <sys_mknod+0x80>
    end_op();
    800062a2:	fffff097          	auipc	ra,0xfffff
    800062a6:	860080e7          	jalr	-1952(ra) # 80004b02 <end_op>
    return -1;
    800062aa:	557d                	li	a0,-1
}
    800062ac:	60ea                	ld	ra,152(sp)
    800062ae:	644a                	ld	s0,144(sp)
    800062b0:	610d                	addi	sp,sp,160
    800062b2:	8082                	ret

00000000800062b4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800062b4:	7135                	addi	sp,sp,-160
    800062b6:	ed06                	sd	ra,152(sp)
    800062b8:	e922                	sd	s0,144(sp)
    800062ba:	e526                	sd	s1,136(sp)
    800062bc:	e14a                	sd	s2,128(sp)
    800062be:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800062c0:	ffffc097          	auipc	ra,0xffffc
    800062c4:	834080e7          	jalr	-1996(ra) # 80001af4 <myproc>
    800062c8:	892a                	mv	s2,a0
  
  begin_op();
    800062ca:	ffffe097          	auipc	ra,0xffffe
    800062ce:	7ba080e7          	jalr	1978(ra) # 80004a84 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800062d2:	08000613          	li	a2,128
    800062d6:	f6040593          	addi	a1,s0,-160
    800062da:	4501                	li	a0,0
    800062dc:	ffffd097          	auipc	ra,0xffffd
    800062e0:	fbe080e7          	jalr	-66(ra) # 8000329a <argstr>
    800062e4:	04054b63          	bltz	a0,8000633a <sys_chdir+0x86>
    800062e8:	f6040513          	addi	a0,s0,-160
    800062ec:	ffffe097          	auipc	ra,0xffffe
    800062f0:	578080e7          	jalr	1400(ra) # 80004864 <namei>
    800062f4:	84aa                	mv	s1,a0
    800062f6:	c131                	beqz	a0,8000633a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800062f8:	ffffe097          	auipc	ra,0xffffe
    800062fc:	db0080e7          	jalr	-592(ra) # 800040a8 <ilock>
  if(ip->type != T_DIR){
    80006300:	04449703          	lh	a4,68(s1)
    80006304:	4785                	li	a5,1
    80006306:	04f71063          	bne	a4,a5,80006346 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000630a:	8526                	mv	a0,s1
    8000630c:	ffffe097          	auipc	ra,0xffffe
    80006310:	e5e080e7          	jalr	-418(ra) # 8000416a <iunlock>
  iput(p->cwd);
    80006314:	42893503          	ld	a0,1064(s2)
    80006318:	ffffe097          	auipc	ra,0xffffe
    8000631c:	f4a080e7          	jalr	-182(ra) # 80004262 <iput>
  end_op();
    80006320:	ffffe097          	auipc	ra,0xffffe
    80006324:	7e2080e7          	jalr	2018(ra) # 80004b02 <end_op>
  p->cwd = ip;
    80006328:	42993423          	sd	s1,1064(s2)
  return 0;
    8000632c:	4501                	li	a0,0
}
    8000632e:	60ea                	ld	ra,152(sp)
    80006330:	644a                	ld	s0,144(sp)
    80006332:	64aa                	ld	s1,136(sp)
    80006334:	690a                	ld	s2,128(sp)
    80006336:	610d                	addi	sp,sp,160
    80006338:	8082                	ret
    end_op();
    8000633a:	ffffe097          	auipc	ra,0xffffe
    8000633e:	7c8080e7          	jalr	1992(ra) # 80004b02 <end_op>
    return -1;
    80006342:	557d                	li	a0,-1
    80006344:	b7ed                	j	8000632e <sys_chdir+0x7a>
    iunlockput(ip);
    80006346:	8526                	mv	a0,s1
    80006348:	ffffe097          	auipc	ra,0xffffe
    8000634c:	fc2080e7          	jalr	-62(ra) # 8000430a <iunlockput>
    end_op();
    80006350:	ffffe097          	auipc	ra,0xffffe
    80006354:	7b2080e7          	jalr	1970(ra) # 80004b02 <end_op>
    return -1;
    80006358:	557d                	li	a0,-1
    8000635a:	bfd1                	j	8000632e <sys_chdir+0x7a>

000000008000635c <sys_exec>:

uint64
sys_exec(void)
{
    8000635c:	7145                	addi	sp,sp,-464
    8000635e:	e786                	sd	ra,456(sp)
    80006360:	e3a2                	sd	s0,448(sp)
    80006362:	ff26                	sd	s1,440(sp)
    80006364:	fb4a                	sd	s2,432(sp)
    80006366:	f74e                	sd	s3,424(sp)
    80006368:	f352                	sd	s4,416(sp)
    8000636a:	ef56                	sd	s5,408(sp)
    8000636c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000636e:	08000613          	li	a2,128
    80006372:	f4040593          	addi	a1,s0,-192
    80006376:	4501                	li	a0,0
    80006378:	ffffd097          	auipc	ra,0xffffd
    8000637c:	f22080e7          	jalr	-222(ra) # 8000329a <argstr>
    return -1;
    80006380:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006382:	0c054b63          	bltz	a0,80006458 <sys_exec+0xfc>
    80006386:	e3840593          	addi	a1,s0,-456
    8000638a:	4505                	li	a0,1
    8000638c:	ffffd097          	auipc	ra,0xffffd
    80006390:	eec080e7          	jalr	-276(ra) # 80003278 <argaddr>
    80006394:	0c054263          	bltz	a0,80006458 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006398:	10000613          	li	a2,256
    8000639c:	4581                	li	a1,0
    8000639e:	e4040513          	addi	a0,s0,-448
    800063a2:	ffffb097          	auipc	ra,0xffffb
    800063a6:	976080e7          	jalr	-1674(ra) # 80000d18 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800063aa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800063ae:	89a6                	mv	s3,s1
    800063b0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800063b2:	02000a13          	li	s4,32
    800063b6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800063ba:	00391513          	slli	a0,s2,0x3
    800063be:	e3040593          	addi	a1,s0,-464
    800063c2:	e3843783          	ld	a5,-456(s0)
    800063c6:	953e                	add	a0,a0,a5
    800063c8:	ffffd097          	auipc	ra,0xffffd
    800063cc:	dee080e7          	jalr	-530(ra) # 800031b6 <fetchaddr>
    800063d0:	02054a63          	bltz	a0,80006404 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800063d4:	e3043783          	ld	a5,-464(s0)
    800063d8:	c3b9                	beqz	a5,8000641e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	708080e7          	jalr	1800(ra) # 80000ae2 <kalloc>
    800063e2:	85aa                	mv	a1,a0
    800063e4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800063e8:	cd11                	beqz	a0,80006404 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800063ea:	6605                	lui	a2,0x1
    800063ec:	e3043503          	ld	a0,-464(s0)
    800063f0:	ffffd097          	auipc	ra,0xffffd
    800063f4:	e1c080e7          	jalr	-484(ra) # 8000320c <fetchstr>
    800063f8:	00054663          	bltz	a0,80006404 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800063fc:	0905                	addi	s2,s2,1
    800063fe:	09a1                	addi	s3,s3,8
    80006400:	fb491be3          	bne	s2,s4,800063b6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006404:	f4040913          	addi	s2,s0,-192
    80006408:	6088                	ld	a0,0(s1)
    8000640a:	c531                	beqz	a0,80006456 <sys_exec+0xfa>
    kfree(argv[i]);
    8000640c:	ffffa097          	auipc	ra,0xffffa
    80006410:	5d8080e7          	jalr	1496(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006414:	04a1                	addi	s1,s1,8
    80006416:	ff2499e3          	bne	s1,s2,80006408 <sys_exec+0xac>
  return -1;
    8000641a:	597d                	li	s2,-1
    8000641c:	a835                	j	80006458 <sys_exec+0xfc>
      argv[i] = 0;
    8000641e:	0a8e                	slli	s5,s5,0x3
    80006420:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffc8328>
    80006424:	00878ab3          	add	s5,a5,s0
    80006428:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000642c:	e4040593          	addi	a1,s0,-448
    80006430:	f4040513          	addi	a0,s0,-192
    80006434:	fffff097          	auipc	ra,0xfffff
    80006438:	170080e7          	jalr	368(ra) # 800055a4 <exec>
    8000643c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000643e:	f4040993          	addi	s3,s0,-192
    80006442:	6088                	ld	a0,0(s1)
    80006444:	c911                	beqz	a0,80006458 <sys_exec+0xfc>
    kfree(argv[i]);
    80006446:	ffffa097          	auipc	ra,0xffffa
    8000644a:	59e080e7          	jalr	1438(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000644e:	04a1                	addi	s1,s1,8
    80006450:	ff3499e3          	bne	s1,s3,80006442 <sys_exec+0xe6>
    80006454:	a011                	j	80006458 <sys_exec+0xfc>
  return -1;
    80006456:	597d                	li	s2,-1
}
    80006458:	854a                	mv	a0,s2
    8000645a:	60be                	ld	ra,456(sp)
    8000645c:	641e                	ld	s0,448(sp)
    8000645e:	74fa                	ld	s1,440(sp)
    80006460:	795a                	ld	s2,432(sp)
    80006462:	79ba                	ld	s3,424(sp)
    80006464:	7a1a                	ld	s4,416(sp)
    80006466:	6afa                	ld	s5,408(sp)
    80006468:	6179                	addi	sp,sp,464
    8000646a:	8082                	ret

000000008000646c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000646c:	7139                	addi	sp,sp,-64
    8000646e:	fc06                	sd	ra,56(sp)
    80006470:	f822                	sd	s0,48(sp)
    80006472:	f426                	sd	s1,40(sp)
    80006474:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006476:	ffffb097          	auipc	ra,0xffffb
    8000647a:	67e080e7          	jalr	1662(ra) # 80001af4 <myproc>
    8000647e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006480:	fd840593          	addi	a1,s0,-40
    80006484:	4501                	li	a0,0
    80006486:	ffffd097          	auipc	ra,0xffffd
    8000648a:	df2080e7          	jalr	-526(ra) # 80003278 <argaddr>
    return -1;
    8000648e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006490:	0e054563          	bltz	a0,8000657a <sys_pipe+0x10e>
  if(pipealloc(&rf, &wf) < 0)
    80006494:	fc840593          	addi	a1,s0,-56
    80006498:	fd040513          	addi	a0,s0,-48
    8000649c:	fffff097          	auipc	ra,0xfffff
    800064a0:	de4080e7          	jalr	-540(ra) # 80005280 <pipealloc>
    return -1;
    800064a4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800064a6:	0c054a63          	bltz	a0,8000657a <sys_pipe+0x10e>
  fd0 = -1;
    800064aa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800064ae:	fd043503          	ld	a0,-48(s0)
    800064b2:	fffff097          	auipc	ra,0xfffff
    800064b6:	502080e7          	jalr	1282(ra) # 800059b4 <fdalloc>
    800064ba:	fca42223          	sw	a0,-60(s0)
    800064be:	0a054163          	bltz	a0,80006560 <sys_pipe+0xf4>
    800064c2:	fc843503          	ld	a0,-56(s0)
    800064c6:	fffff097          	auipc	ra,0xfffff
    800064ca:	4ee080e7          	jalr	1262(ra) # 800059b4 <fdalloc>
    800064ce:	fca42023          	sw	a0,-64(s0)
    800064d2:	06054d63          	bltz	a0,8000654c <sys_pipe+0xe0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800064d6:	4691                	li	a3,4
    800064d8:	fc440613          	addi	a2,s0,-60
    800064dc:	fd843583          	ld	a1,-40(s0)
    800064e0:	3284b503          	ld	a0,808(s1)
    800064e4:	ffffb097          	auipc	ra,0xffffb
    800064e8:	256080e7          	jalr	598(ra) # 8000173a <copyout>
    800064ec:	02054163          	bltz	a0,8000650e <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800064f0:	4691                	li	a3,4
    800064f2:	fc040613          	addi	a2,s0,-64
    800064f6:	fd843583          	ld	a1,-40(s0)
    800064fa:	0591                	addi	a1,a1,4
    800064fc:	3284b503          	ld	a0,808(s1)
    80006500:	ffffb097          	auipc	ra,0xffffb
    80006504:	23a080e7          	jalr	570(ra) # 8000173a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006508:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000650a:	06055863          	bgez	a0,8000657a <sys_pipe+0x10e>
    p->ofile[fd0] = 0;
    8000650e:	fc442783          	lw	a5,-60(s0)
    80006512:	07478793          	addi	a5,a5,116
    80006516:	078e                	slli	a5,a5,0x3
    80006518:	97a6                	add	a5,a5,s1
    8000651a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000651e:	fc042783          	lw	a5,-64(s0)
    80006522:	07478793          	addi	a5,a5,116
    80006526:	078e                	slli	a5,a5,0x3
    80006528:	00f48533          	add	a0,s1,a5
    8000652c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006530:	fd043503          	ld	a0,-48(s0)
    80006534:	fffff097          	auipc	ra,0xfffff
    80006538:	a1c080e7          	jalr	-1508(ra) # 80004f50 <fileclose>
    fileclose(wf);
    8000653c:	fc843503          	ld	a0,-56(s0)
    80006540:	fffff097          	auipc	ra,0xfffff
    80006544:	a10080e7          	jalr	-1520(ra) # 80004f50 <fileclose>
    return -1;
    80006548:	57fd                	li	a5,-1
    8000654a:	a805                	j	8000657a <sys_pipe+0x10e>
    if(fd0 >= 0)
    8000654c:	fc442783          	lw	a5,-60(s0)
    80006550:	0007c863          	bltz	a5,80006560 <sys_pipe+0xf4>
      p->ofile[fd0] = 0;
    80006554:	07478793          	addi	a5,a5,116
    80006558:	078e                	slli	a5,a5,0x3
    8000655a:	97a6                	add	a5,a5,s1
    8000655c:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80006560:	fd043503          	ld	a0,-48(s0)
    80006564:	fffff097          	auipc	ra,0xfffff
    80006568:	9ec080e7          	jalr	-1556(ra) # 80004f50 <fileclose>
    fileclose(wf);
    8000656c:	fc843503          	ld	a0,-56(s0)
    80006570:	fffff097          	auipc	ra,0xfffff
    80006574:	9e0080e7          	jalr	-1568(ra) # 80004f50 <fileclose>
    return -1;
    80006578:	57fd                	li	a5,-1
}
    8000657a:	853e                	mv	a0,a5
    8000657c:	70e2                	ld	ra,56(sp)
    8000657e:	7442                	ld	s0,48(sp)
    80006580:	74a2                	ld	s1,40(sp)
    80006582:	6121                	addi	sp,sp,64
    80006584:	8082                	ret

0000000080006586 <sys_mmap>:

// HW5 - Task 1a
// Create a new mapped memory region
uint64
sys_mmap()
{
    80006586:	7139                	addi	sp,sp,-64
    80006588:	fc06                	sd	ra,56(sp)
    8000658a:	f822                	sd	s0,48(sp)
    8000658c:	f426                	sd	s1,40(sp)
    8000658e:	f04a                	sd	s2,32(sp)
    80006590:	ec4e                	sd	s3,24(sp)
    80006592:	0080                	addi	s0,sp,64
  uint64 length;
  int    prot;
  int    flags;
  struct proc *p = myproc();
    80006594:	ffffb097          	auipc	ra,0xffffb
    80006598:	560080e7          	jalr	1376(ra) # 80001af4 <myproc>
    8000659c:	89aa                	mv	s3,a0
  struct mmr *newmmr = 0;
  uint64 start_addr;

  /* Add error checking for length, prot, and flags arguments */

  if (argaddr(1, &length) < 0)
    8000659e:	fc840593          	addi	a1,s0,-56
    800065a2:	4505                	li	a0,1
    800065a4:	ffffd097          	auipc	ra,0xffffd
    800065a8:	cd4080e7          	jalr	-812(ra) # 80003278 <argaddr>
    return -1;
    800065ac:	597d                	li	s2,-1
  if (argaddr(1, &length) < 0)
    800065ae:	0a054863          	bltz	a0,8000665e <sys_mmap+0xd8>
  if (argint(2, &prot) < 0)
    800065b2:	fc440593          	addi	a1,s0,-60
    800065b6:	4509                	li	a0,2
    800065b8:	ffffd097          	auipc	ra,0xffffd
    800065bc:	c9e080e7          	jalr	-866(ra) # 80003256 <argint>
    800065c0:	08054f63          	bltz	a0,8000665e <sys_mmap+0xd8>
    return -1;
  if (argint(3, &flags) <0)
    800065c4:	fc040593          	addi	a1,s0,-64
    800065c8:	450d                	li	a0,3
    800065ca:	ffffd097          	auipc	ra,0xffffd
    800065ce:	c8c080e7          	jalr	-884(ra) # 80003256 <argint>
    800065d2:	0c054263          	bltz	a0,80006696 <sys_mmap+0x110>
    800065d6:	01498793          	addi	a5,s3,20
    return -1;
  // Search p->mmr[] for unused location 
  for (int i = 0; i < MAX_MMR; i++) {
    800065da:	4481                	li	s1,0
    800065dc:	46a9                	li	a3,10
    if (p->mmr[i].valid == 0) {
    800065de:	4398                	lw	a4,0(a5)
    800065e0:	cb01                	beqz	a4,800065f0 <sys_mmap+0x6a>
  for (int i = 0; i < MAX_MMR; i++) {
    800065e2:	2485                	addiw	s1,s1,1
    800065e4:	04878793          	addi	a5,a5,72
    800065e8:	fed49be3          	bne	s1,a3,800065de <sys_mmap+0x58>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
      newmmr->mmr_family.listid = alloc_mmr_listid();
    p->cur_max = start_addr;
    return start_addr;
  } else {
    return -1;
    800065ec:	597d                	li	s2,-1
    800065ee:	a885                	j	8000665e <sys_mmap+0xd8>
    start_addr = PGROUNDDOWN(p->cur_max-length);
    800065f0:	2d09b903          	ld	s2,720(s3)
    800065f4:	fc843783          	ld	a5,-56(s0)
    800065f8:	40f90933          	sub	s2,s2,a5
    800065fc:	77fd                	lui	a5,0xfffff
    800065fe:	00f97933          	and	s2,s2,a5
    newmmr->valid = 1;
    80006602:	00349713          	slli	a4,s1,0x3
    80006606:	009707b3          	add	a5,a4,s1
    8000660a:	078e                	slli	a5,a5,0x3
    8000660c:	97ce                	add	a5,a5,s3
    8000660e:	4685                	li	a3,1
    80006610:	cbd4                	sw	a3,20(a5)
    newmmr->addr = start_addr;
    80006612:	0127b023          	sd	s2,0(a5) # fffffffffffff000 <end+0xffffffff7ffc8368>
    newmmr->length = p->cur_max - start_addr;
    80006616:	2d09b603          	ld	a2,720(s3)
    8000661a:	4126063b          	subw	a2,a2,s2
    8000661e:	c790                	sw	a2,8(a5)
    newmmr->prot = prot;
    80006620:	fc442683          	lw	a3,-60(s0)
    80006624:	c7d4                	sw	a3,12(a5)
    newmmr->flags = flags;
    80006626:	fc042683          	lw	a3,-64(s0)
    8000662a:	cb94                	sw	a3,16(a5)
    newmmr->mmr_family.proc = p;
    8000662c:	9726                	add	a4,a4,s1
    8000662e:	070e                	slli	a4,a4,0x3
    80006630:	0337b823          	sd	s3,48(a5)
    newmmr->mmr_family.next = &(newmmr->mmr_family);  // next points to its own mmr_node
    80006634:	02870713          	addi	a4,a4,40
    80006638:	974e                	add	a4,a4,s3
    8000663a:	ff98                	sd	a4,56(a5)
    newmmr->mmr_family.prev = &(newmmr->mmr_family);  // prev points to its own mmr_node
    8000663c:	e3b8                	sd	a4,64(a5)
    if (mapvpages(p->pagetable, newmmr->addr, newmmr->length) < 0) {
    8000663e:	2601                	sext.w	a2,a2
    80006640:	85ca                	mv	a1,s2
    80006642:	3289b503          	ld	a0,808(s3)
    80006646:	ffffb097          	auipc	ra,0xffffb
    8000664a:	2be080e7          	jalr	702(ra) # 80001904 <mapvpages>
    8000664e:	02054063          	bltz	a0,8000666e <sys_mmap+0xe8>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
    80006652:	fc042783          	lw	a5,-64(s0)
    80006656:	8b85                	andi	a5,a5,1
    80006658:	e785                	bnez	a5,80006680 <sys_mmap+0xfa>
    p->cur_max = start_addr;
    8000665a:	2d29b823          	sd	s2,720(s3)
  }
}
    8000665e:	854a                	mv	a0,s2
    80006660:	70e2                	ld	ra,56(sp)
    80006662:	7442                	ld	s0,48(sp)
    80006664:	74a2                	ld	s1,40(sp)
    80006666:	7902                	ld	s2,32(sp)
    80006668:	69e2                	ld	s3,24(sp)
    8000666a:	6121                	addi	sp,sp,64
    8000666c:	8082                	ret
      newmmr->valid = 0;
    8000666e:	00349793          	slli	a5,s1,0x3
    80006672:	97a6                	add	a5,a5,s1
    80006674:	078e                	slli	a5,a5,0x3
    80006676:	97ce                	add	a5,a5,s3
    80006678:	0007aa23          	sw	zero,20(a5)
      return -1;
    8000667c:	597d                	li	s2,-1
    8000667e:	b7c5                	j	8000665e <sys_mmap+0xd8>
      newmmr->mmr_family.listid = alloc_mmr_listid();
    80006680:	ffffc097          	auipc	ra,0xffffc
    80006684:	524080e7          	jalr	1316(ra) # 80002ba4 <alloc_mmr_listid>
    80006688:	00349793          	slli	a5,s1,0x3
    8000668c:	97a6                	add	a5,a5,s1
    8000668e:	078e                	slli	a5,a5,0x3
    80006690:	97ce                	add	a5,a5,s3
    80006692:	d788                	sw	a0,40(a5)
    80006694:	b7d9                	j	8000665a <sys_mmap+0xd4>
    return -1;
    80006696:	597d                	li	s2,-1
    80006698:	b7d9                	j	8000665e <sys_mmap+0xd8>

000000008000669a <munmap>:
// HW5 - Task 1a
// Unmap memory region if it exists
// Free physical memory if no other process has the region mapped
int
munmap(uint64 addr, uint64 length)
{
    8000669a:	715d                	addi	sp,sp,-80
    8000669c:	e486                	sd	ra,72(sp)
    8000669e:	e0a2                	sd	s0,64(sp)
    800066a0:	fc26                	sd	s1,56(sp)
    800066a2:	f84a                	sd	s2,48(sp)
    800066a4:	f44e                	sd	s3,40(sp)
    800066a6:	f052                	sd	s4,32(sp)
    800066a8:	ec56                	sd	s5,24(sp)
    800066aa:	e85a                	sd	s6,16(sp)
    800066ac:	e45e                	sd	s7,8(sp)
    800066ae:	e062                	sd	s8,0(sp)
    800066b0:	0880                	addi	s0,sp,80
    800066b2:	84aa                	mv	s1,a0
    800066b4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800066b6:	ffffb097          	auipc	ra,0xffffb
    800066ba:	43e080e7          	jalr	1086(ra) # 80001af4 <myproc>
    800066be:	8a2a                	mv	s4,a0
  struct mmr *mmr = 0;
  int dofree = 0;
  int i;

  // Search proc->mmr for addr
  for (i = 0; i < MAX_MMR; i++)
    800066c0:	87aa                	mv	a5,a0
    800066c2:	4901                	li	s2,0
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    800066c4:	4685                	li	a3,1
        (PGROUNDUP(length) == p->mmr[i].length)) {
    800066c6:	6705                	lui	a4,0x1
    800066c8:	177d                	addi	a4,a4,-1 # fff <_entry-0x7ffff001>
    800066ca:	00e985b3          	add	a1,s3,a4
    800066ce:	777d                	lui	a4,0xfffff
    800066d0:	8df9                	and	a1,a1,a4
  for (i = 0; i < MAX_MMR; i++)
    800066d2:	4629                	li	a2,10
    800066d4:	a031                	j	800066e0 <munmap+0x46>
    800066d6:	2905                	addiw	s2,s2,1
    800066d8:	04878793          	addi	a5,a5,72
    800066dc:	04c90763          	beq	s2,a2,8000672a <munmap+0x90>
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    800066e0:	0147a983          	lw	s3,20(a5)
    800066e4:	fed999e3          	bne	s3,a3,800066d6 <munmap+0x3c>
    800066e8:	6388                	ld	a0,0(a5)
    800066ea:	fe9516e3          	bne	a0,s1,800066d6 <munmap+0x3c>
        (PGROUNDUP(length) == p->mmr[i].length)) {
    800066ee:	4798                	lw	a4,8(a5)
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    800066f0:	fee593e3          	bne	a1,a4,800066d6 <munmap+0x3c>
      break;
    }
  if (!mmr) {
    return -1;
  }
  mmr->valid = 0;
    800066f4:	00391793          	slli	a5,s2,0x3
    800066f8:	97ca                	add	a5,a5,s2
    800066fa:	078e                	slli	a5,a5,0x3
    800066fc:	97d2                	add	a5,a5,s4
    800066fe:	0007aa23          	sw	zero,20(a5)
  if (mmr->flags & MAP_PRIVATE)
    80006702:	0107aa83          	lw	s5,16(a5)
    80006706:	002afa93          	andi	s5,s5,2
    8000670a:	020a8263          	beqz	s5,8000672e <munmap+0x94>
      release(&pmmrlist->lock);
    }
  }
  // Remove mappings from page table
  // Also free physical memory if no other process has this region mapped
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    8000670e:	00391793          	slli	a5,s2,0x3
    80006712:	993e                	add	s2,s2,a5
    80006714:	090e                	slli	s2,s2,0x3
    80006716:	9952                	add	s2,s2,s4
    80006718:	00892783          	lw	a5,8(s2)
    8000671c:	00093703          	ld	a4,0(s2)
    80006720:	97ba                	add	a5,a5,a4
    80006722:	0cf4f463          	bgeu	s1,a5,800067ea <munmap+0x150>
    80006726:	6a85                	lui	s5,0x1
    80006728:	a051                	j	800067ac <munmap+0x112>
    return -1;
    8000672a:	557d                	li	a0,-1
    8000672c:	a05d                	j	800067d2 <munmap+0x138>
    struct mmr_list *pmmrlist = get_mmr_list(mmr->mmr_family.listid);
    8000672e:	00391b13          	slli	s6,s2,0x3
    80006732:	012b0c33          	add	s8,s6,s2
    80006736:	0c0e                	slli	s8,s8,0x3
    80006738:	9c52                	add	s8,s8,s4
    8000673a:	028c2503          	lw	a0,40(s8)
    8000673e:	ffffc097          	auipc	ra,0xffffc
    80006742:	ce4080e7          	jalr	-796(ra) # 80002422 <get_mmr_list>
    80006746:	8baa                	mv	s7,a0
    acquire(&pmmrlist->lock);
    80006748:	ffffa097          	auipc	ra,0xffffa
    8000674c:	4d4080e7          	jalr	1236(ra) # 80000c1c <acquire>
    if (mmr->mmr_family.next == &(mmr->mmr_family)) { // no other family members
    80006750:	038c3703          	ld	a4,56(s8)
    80006754:	012b07b3          	add	a5,s6,s2
    80006758:	078e                	slli	a5,a5,0x3
    8000675a:	02878793          	addi	a5,a5,40
    8000675e:	97d2                	add	a5,a5,s4
    80006760:	02f70263          	beq	a4,a5,80006784 <munmap+0xea>
      (mmr->mmr_family.next)->prev = mmr->mmr_family.prev;
    80006764:	00391793          	slli	a5,s2,0x3
    80006768:	97ca                	add	a5,a5,s2
    8000676a:	078e                	slli	a5,a5,0x3
    8000676c:	97d2                	add	a5,a5,s4
    8000676e:	63b4                	ld	a3,64(a5)
    80006770:	ef14                	sd	a3,24(a4)
      (mmr->mmr_family.prev)->next = mmr->mmr_family.next;
    80006772:	7f9c                	ld	a5,56(a5)
    80006774:	ea9c                	sd	a5,16(a3)
      release(&pmmrlist->lock);
    80006776:	855e                	mv	a0,s7
    80006778:	ffffa097          	auipc	ra,0xffffa
    8000677c:	558080e7          	jalr	1368(ra) # 80000cd0 <release>
  int dofree = 0;
    80006780:	89d6                	mv	s3,s5
    80006782:	b771                	j	8000670e <munmap+0x74>
      release(&pmmrlist->lock);
    80006784:	855e                	mv	a0,s7
    80006786:	ffffa097          	auipc	ra,0xffffa
    8000678a:	54a080e7          	jalr	1354(ra) # 80000cd0 <release>
      dealloc_mmr_listid(mmr->mmr_family.listid);
    8000678e:	028c2503          	lw	a0,40(s8)
    80006792:	ffffc097          	auipc	ra,0xffffc
    80006796:	d06080e7          	jalr	-762(ra) # 80002498 <dealloc_mmr_listid>
    8000679a:	bf95                	j	8000670e <munmap+0x74>
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    8000679c:	94d6                	add	s1,s1,s5
    8000679e:	00892783          	lw	a5,8(s2)
    800067a2:	00093703          	ld	a4,0(s2)
    800067a6:	97ba                	add	a5,a5,a4
    800067a8:	02f4f463          	bgeu	s1,a5,800067d0 <munmap+0x136>
    if (walkaddr(p->pagetable, pageaddr)) {
    800067ac:	85a6                	mv	a1,s1
    800067ae:	328a3503          	ld	a0,808(s4)
    800067b2:	ffffb097          	auipc	ra,0xffffb
    800067b6:	8fc080e7          	jalr	-1796(ra) # 800010ae <walkaddr>
    800067ba:	d16d                	beqz	a0,8000679c <munmap+0x102>
      uvmunmap(p->pagetable, pageaddr, 1, dofree);
    800067bc:	86ce                	mv	a3,s3
    800067be:	4605                	li	a2,1
    800067c0:	85a6                	mv	a1,s1
    800067c2:	328a3503          	ld	a0,808(s4)
    800067c6:	ffffb097          	auipc	ra,0xffffb
    800067ca:	af0080e7          	jalr	-1296(ra) # 800012b6 <uvmunmap>
    800067ce:	b7f9                	j	8000679c <munmap+0x102>
    }
  }
  return 0;
    800067d0:	4501                	li	a0,0
}
    800067d2:	60a6                	ld	ra,72(sp)
    800067d4:	6406                	ld	s0,64(sp)
    800067d6:	74e2                	ld	s1,56(sp)
    800067d8:	7942                	ld	s2,48(sp)
    800067da:	79a2                	ld	s3,40(sp)
    800067dc:	7a02                	ld	s4,32(sp)
    800067de:	6ae2                	ld	s5,24(sp)
    800067e0:	6b42                	ld	s6,16(sp)
    800067e2:	6ba2                	ld	s7,8(sp)
    800067e4:	6c02                	ld	s8,0(sp)
    800067e6:	6161                	addi	sp,sp,80
    800067e8:	8082                	ret
  return 0;
    800067ea:	4501                	li	a0,0
    800067ec:	b7dd                	j	800067d2 <munmap+0x138>

00000000800067ee <sys_munmap>:

// Get arguments and call munmap() helper function
uint64
sys_munmap(void)
{
    800067ee:	1101                	addi	sp,sp,-32
    800067f0:	ec06                	sd	ra,24(sp)
    800067f2:	e822                	sd	s0,16(sp)
    800067f4:	1000                	addi	s0,sp,32
  uint64 addr;
  uint64 length;

  // HW5 - Task 1a
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    800067f6:	fe840593          	addi	a1,s0,-24
    800067fa:	4501                	li	a0,0
    800067fc:	ffffd097          	auipc	ra,0xffffd
    80006800:	a7c080e7          	jalr	-1412(ra) # 80003278 <argaddr>
        return -1;
    80006804:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    80006806:	02054563          	bltz	a0,80006830 <sys_munmap+0x42>
    8000680a:	fe040593          	addi	a1,s0,-32
    8000680e:	4505                	li	a0,1
    80006810:	ffffd097          	auipc	ra,0xffffd
    80006814:	a68080e7          	jalr	-1432(ra) # 80003278 <argaddr>
        return -1;
    80006818:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    8000681a:	00054b63          	bltz	a0,80006830 <sys_munmap+0x42>
  return munmap(addr, length);
    8000681e:	fe043583          	ld	a1,-32(s0)
    80006822:	fe843503          	ld	a0,-24(s0)
    80006826:	00000097          	auipc	ra,0x0
    8000682a:	e74080e7          	jalr	-396(ra) # 8000669a <munmap>
    8000682e:	87aa                	mv	a5,a0
  // return 0;
    80006830:	853e                	mv	a0,a5
    80006832:	60e2                	ld	ra,24(sp)
    80006834:	6442                	ld	s0,16(sp)
    80006836:	6105                	addi	sp,sp,32
    80006838:	8082                	ret
    8000683a:	0000                	unimp
    8000683c:	0000                	unimp
	...

0000000080006840 <kernelvec>:
    80006840:	7111                	addi	sp,sp,-256
    80006842:	e006                	sd	ra,0(sp)
    80006844:	e40a                	sd	sp,8(sp)
    80006846:	e80e                	sd	gp,16(sp)
    80006848:	ec12                	sd	tp,24(sp)
    8000684a:	f016                	sd	t0,32(sp)
    8000684c:	f41a                	sd	t1,40(sp)
    8000684e:	f81e                	sd	t2,48(sp)
    80006850:	fc22                	sd	s0,56(sp)
    80006852:	e0a6                	sd	s1,64(sp)
    80006854:	e4aa                	sd	a0,72(sp)
    80006856:	e8ae                	sd	a1,80(sp)
    80006858:	ecb2                	sd	a2,88(sp)
    8000685a:	f0b6                	sd	a3,96(sp)
    8000685c:	f4ba                	sd	a4,104(sp)
    8000685e:	f8be                	sd	a5,112(sp)
    80006860:	fcc2                	sd	a6,120(sp)
    80006862:	e146                	sd	a7,128(sp)
    80006864:	e54a                	sd	s2,136(sp)
    80006866:	e94e                	sd	s3,144(sp)
    80006868:	ed52                	sd	s4,152(sp)
    8000686a:	f156                	sd	s5,160(sp)
    8000686c:	f55a                	sd	s6,168(sp)
    8000686e:	f95e                	sd	s7,176(sp)
    80006870:	fd62                	sd	s8,184(sp)
    80006872:	e1e6                	sd	s9,192(sp)
    80006874:	e5ea                	sd	s10,200(sp)
    80006876:	e9ee                	sd	s11,208(sp)
    80006878:	edf2                	sd	t3,216(sp)
    8000687a:	f1f6                	sd	t4,224(sp)
    8000687c:	f5fa                	sd	t5,232(sp)
    8000687e:	f9fe                	sd	t6,240(sp)
    80006880:	ff4fc0ef          	jal	ra,80003074 <kerneltrap>
    80006884:	6082                	ld	ra,0(sp)
    80006886:	6122                	ld	sp,8(sp)
    80006888:	61c2                	ld	gp,16(sp)
    8000688a:	7282                	ld	t0,32(sp)
    8000688c:	7322                	ld	t1,40(sp)
    8000688e:	73c2                	ld	t2,48(sp)
    80006890:	7462                	ld	s0,56(sp)
    80006892:	6486                	ld	s1,64(sp)
    80006894:	6526                	ld	a0,72(sp)
    80006896:	65c6                	ld	a1,80(sp)
    80006898:	6666                	ld	a2,88(sp)
    8000689a:	7686                	ld	a3,96(sp)
    8000689c:	7726                	ld	a4,104(sp)
    8000689e:	77c6                	ld	a5,112(sp)
    800068a0:	7866                	ld	a6,120(sp)
    800068a2:	688a                	ld	a7,128(sp)
    800068a4:	692a                	ld	s2,136(sp)
    800068a6:	69ca                	ld	s3,144(sp)
    800068a8:	6a6a                	ld	s4,152(sp)
    800068aa:	7a8a                	ld	s5,160(sp)
    800068ac:	7b2a                	ld	s6,168(sp)
    800068ae:	7bca                	ld	s7,176(sp)
    800068b0:	7c6a                	ld	s8,184(sp)
    800068b2:	6c8e                	ld	s9,192(sp)
    800068b4:	6d2e                	ld	s10,200(sp)
    800068b6:	6dce                	ld	s11,208(sp)
    800068b8:	6e6e                	ld	t3,216(sp)
    800068ba:	7e8e                	ld	t4,224(sp)
    800068bc:	7f2e                	ld	t5,232(sp)
    800068be:	7fce                	ld	t6,240(sp)
    800068c0:	6111                	addi	sp,sp,256
    800068c2:	10200073          	sret
    800068c6:	00000013          	nop
    800068ca:	00000013          	nop
    800068ce:	0001                	nop

00000000800068d0 <timervec>:
    800068d0:	34051573          	csrrw	a0,mscratch,a0
    800068d4:	e10c                	sd	a1,0(a0)
    800068d6:	e510                	sd	a2,8(a0)
    800068d8:	e914                	sd	a3,16(a0)
    800068da:	6d0c                	ld	a1,24(a0)
    800068dc:	7110                	ld	a2,32(a0)
    800068de:	6194                	ld	a3,0(a1)
    800068e0:	96b2                	add	a3,a3,a2
    800068e2:	e194                	sd	a3,0(a1)
    800068e4:	4589                	li	a1,2
    800068e6:	14459073          	csrw	sip,a1
    800068ea:	6914                	ld	a3,16(a0)
    800068ec:	6510                	ld	a2,8(a0)
    800068ee:	610c                	ld	a1,0(a0)
    800068f0:	34051573          	csrrw	a0,mscratch,a0
    800068f4:	30200073          	mret
	...

00000000800068fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800068fa:	1141                	addi	sp,sp,-16
    800068fc:	e422                	sd	s0,8(sp)
    800068fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006900:	0c0007b7          	lui	a5,0xc000
    80006904:	4705                	li	a4,1
    80006906:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006908:	c3d8                	sw	a4,4(a5)
}
    8000690a:	6422                	ld	s0,8(sp)
    8000690c:	0141                	addi	sp,sp,16
    8000690e:	8082                	ret

0000000080006910 <plicinithart>:

void
plicinithart(void)
{
    80006910:	1141                	addi	sp,sp,-16
    80006912:	e406                	sd	ra,8(sp)
    80006914:	e022                	sd	s0,0(sp)
    80006916:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006918:	ffffb097          	auipc	ra,0xffffb
    8000691c:	1b0080e7          	jalr	432(ra) # 80001ac8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006920:	0085171b          	slliw	a4,a0,0x8
    80006924:	0c0027b7          	lui	a5,0xc002
    80006928:	97ba                	add	a5,a5,a4
    8000692a:	40200713          	li	a4,1026
    8000692e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006932:	00d5151b          	slliw	a0,a0,0xd
    80006936:	0c2017b7          	lui	a5,0xc201
    8000693a:	97aa                	add	a5,a5,a0
    8000693c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006940:	60a2                	ld	ra,8(sp)
    80006942:	6402                	ld	s0,0(sp)
    80006944:	0141                	addi	sp,sp,16
    80006946:	8082                	ret

0000000080006948 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006948:	1141                	addi	sp,sp,-16
    8000694a:	e406                	sd	ra,8(sp)
    8000694c:	e022                	sd	s0,0(sp)
    8000694e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006950:	ffffb097          	auipc	ra,0xffffb
    80006954:	178080e7          	jalr	376(ra) # 80001ac8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006958:	00d5151b          	slliw	a0,a0,0xd
    8000695c:	0c2017b7          	lui	a5,0xc201
    80006960:	97aa                	add	a5,a5,a0
  return irq;
}
    80006962:	43c8                	lw	a0,4(a5)
    80006964:	60a2                	ld	ra,8(sp)
    80006966:	6402                	ld	s0,0(sp)
    80006968:	0141                	addi	sp,sp,16
    8000696a:	8082                	ret

000000008000696c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000696c:	1101                	addi	sp,sp,-32
    8000696e:	ec06                	sd	ra,24(sp)
    80006970:	e822                	sd	s0,16(sp)
    80006972:	e426                	sd	s1,8(sp)
    80006974:	1000                	addi	s0,sp,32
    80006976:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006978:	ffffb097          	auipc	ra,0xffffb
    8000697c:	150080e7          	jalr	336(ra) # 80001ac8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006980:	00d5151b          	slliw	a0,a0,0xd
    80006984:	0c2017b7          	lui	a5,0xc201
    80006988:	97aa                	add	a5,a5,a0
    8000698a:	c3c4                	sw	s1,4(a5)
}
    8000698c:	60e2                	ld	ra,24(sp)
    8000698e:	6442                	ld	s0,16(sp)
    80006990:	64a2                	ld	s1,8(sp)
    80006992:	6105                	addi	sp,sp,32
    80006994:	8082                	ret

0000000080006996 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006996:	1141                	addi	sp,sp,-16
    80006998:	e406                	sd	ra,8(sp)
    8000699a:	e022                	sd	s0,0(sp)
    8000699c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000699e:	479d                	li	a5,7
    800069a0:	06a7c863          	blt	a5,a0,80006a10 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    800069a4:	0002c717          	auipc	a4,0x2c
    800069a8:	65c70713          	addi	a4,a4,1628 # 80033000 <disk>
    800069ac:	972a                	add	a4,a4,a0
    800069ae:	6789                	lui	a5,0x2
    800069b0:	97ba                	add	a5,a5,a4
    800069b2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800069b6:	e7ad                	bnez	a5,80006a20 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800069b8:	00451793          	slli	a5,a0,0x4
    800069bc:	0002e717          	auipc	a4,0x2e
    800069c0:	64470713          	addi	a4,a4,1604 # 80035000 <disk+0x2000>
    800069c4:	6314                	ld	a3,0(a4)
    800069c6:	96be                	add	a3,a3,a5
    800069c8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800069cc:	6314                	ld	a3,0(a4)
    800069ce:	96be                	add	a3,a3,a5
    800069d0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800069d4:	6314                	ld	a3,0(a4)
    800069d6:	96be                	add	a3,a3,a5
    800069d8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800069dc:	6318                	ld	a4,0(a4)
    800069de:	97ba                	add	a5,a5,a4
    800069e0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800069e4:	0002c717          	auipc	a4,0x2c
    800069e8:	61c70713          	addi	a4,a4,1564 # 80033000 <disk>
    800069ec:	972a                	add	a4,a4,a0
    800069ee:	6789                	lui	a5,0x2
    800069f0:	97ba                	add	a5,a5,a4
    800069f2:	4705                	li	a4,1
    800069f4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800069f8:	0002e517          	auipc	a0,0x2e
    800069fc:	62050513          	addi	a0,a0,1568 # 80035018 <disk+0x2018>
    80006a00:	ffffb097          	auipc	ra,0xffffb
    80006a04:	564080e7          	jalr	1380(ra) # 80001f64 <wakeup>
}
    80006a08:	60a2                	ld	ra,8(sp)
    80006a0a:	6402                	ld	s0,0(sp)
    80006a0c:	0141                	addi	sp,sp,16
    80006a0e:	8082                	ret
    panic("free_desc 1");
    80006a10:	00002517          	auipc	a0,0x2
    80006a14:	db050513          	addi	a0,a0,-592 # 800087c0 <syscalls+0x360>
    80006a18:	ffffa097          	auipc	ra,0xffffa
    80006a1c:	b24080e7          	jalr	-1244(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006a20:	00002517          	auipc	a0,0x2
    80006a24:	db050513          	addi	a0,a0,-592 # 800087d0 <syscalls+0x370>
    80006a28:	ffffa097          	auipc	ra,0xffffa
    80006a2c:	b14080e7          	jalr	-1260(ra) # 8000053c <panic>

0000000080006a30 <virtio_disk_init>:
{
    80006a30:	1101                	addi	sp,sp,-32
    80006a32:	ec06                	sd	ra,24(sp)
    80006a34:	e822                	sd	s0,16(sp)
    80006a36:	e426                	sd	s1,8(sp)
    80006a38:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a3a:	00002597          	auipc	a1,0x2
    80006a3e:	da658593          	addi	a1,a1,-602 # 800087e0 <syscalls+0x380>
    80006a42:	0002e517          	auipc	a0,0x2e
    80006a46:	6e650513          	addi	a0,a0,1766 # 80035128 <disk+0x2128>
    80006a4a:	ffffa097          	auipc	ra,0xffffa
    80006a4e:	142080e7          	jalr	322(ra) # 80000b8c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a52:	100017b7          	lui	a5,0x10001
    80006a56:	4398                	lw	a4,0(a5)
    80006a58:	2701                	sext.w	a4,a4
    80006a5a:	747277b7          	lui	a5,0x74727
    80006a5e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a62:	0ef71063          	bne	a4,a5,80006b42 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006a66:	100017b7          	lui	a5,0x10001
    80006a6a:	43dc                	lw	a5,4(a5)
    80006a6c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a6e:	4705                	li	a4,1
    80006a70:	0ce79963          	bne	a5,a4,80006b42 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a74:	100017b7          	lui	a5,0x10001
    80006a78:	479c                	lw	a5,8(a5)
    80006a7a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006a7c:	4709                	li	a4,2
    80006a7e:	0ce79263          	bne	a5,a4,80006b42 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a82:	100017b7          	lui	a5,0x10001
    80006a86:	47d8                	lw	a4,12(a5)
    80006a88:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a8a:	554d47b7          	lui	a5,0x554d4
    80006a8e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a92:	0af71863          	bne	a4,a5,80006b42 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a96:	100017b7          	lui	a5,0x10001
    80006a9a:	4705                	li	a4,1
    80006a9c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a9e:	470d                	li	a4,3
    80006aa0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006aa2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006aa4:	c7ffe6b7          	lui	a3,0xc7ffe
    80006aa8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fc7ac7>
    80006aac:	8f75                	and	a4,a4,a3
    80006aae:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ab0:	472d                	li	a4,11
    80006ab2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ab4:	473d                	li	a4,15
    80006ab6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006ab8:	6705                	lui	a4,0x1
    80006aba:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006abc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006ac0:	5bdc                	lw	a5,52(a5)
    80006ac2:	2781                	sext.w	a5,a5
  if(max == 0)
    80006ac4:	c7d9                	beqz	a5,80006b52 <virtio_disk_init+0x122>
  if(max < NUM)
    80006ac6:	471d                	li	a4,7
    80006ac8:	08f77d63          	bgeu	a4,a5,80006b62 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006acc:	100014b7          	lui	s1,0x10001
    80006ad0:	47a1                	li	a5,8
    80006ad2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006ad4:	6609                	lui	a2,0x2
    80006ad6:	4581                	li	a1,0
    80006ad8:	0002c517          	auipc	a0,0x2c
    80006adc:	52850513          	addi	a0,a0,1320 # 80033000 <disk>
    80006ae0:	ffffa097          	auipc	ra,0xffffa
    80006ae4:	238080e7          	jalr	568(ra) # 80000d18 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006ae8:	0002c717          	auipc	a4,0x2c
    80006aec:	51870713          	addi	a4,a4,1304 # 80033000 <disk>
    80006af0:	00c75793          	srli	a5,a4,0xc
    80006af4:	2781                	sext.w	a5,a5
    80006af6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006af8:	0002e797          	auipc	a5,0x2e
    80006afc:	50878793          	addi	a5,a5,1288 # 80035000 <disk+0x2000>
    80006b00:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006b02:	0002c717          	auipc	a4,0x2c
    80006b06:	57e70713          	addi	a4,a4,1406 # 80033080 <disk+0x80>
    80006b0a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006b0c:	0002d717          	auipc	a4,0x2d
    80006b10:	4f470713          	addi	a4,a4,1268 # 80034000 <disk+0x1000>
    80006b14:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006b16:	4705                	li	a4,1
    80006b18:	00e78c23          	sb	a4,24(a5)
    80006b1c:	00e78ca3          	sb	a4,25(a5)
    80006b20:	00e78d23          	sb	a4,26(a5)
    80006b24:	00e78da3          	sb	a4,27(a5)
    80006b28:	00e78e23          	sb	a4,28(a5)
    80006b2c:	00e78ea3          	sb	a4,29(a5)
    80006b30:	00e78f23          	sb	a4,30(a5)
    80006b34:	00e78fa3          	sb	a4,31(a5)
}
    80006b38:	60e2                	ld	ra,24(sp)
    80006b3a:	6442                	ld	s0,16(sp)
    80006b3c:	64a2                	ld	s1,8(sp)
    80006b3e:	6105                	addi	sp,sp,32
    80006b40:	8082                	ret
    panic("could not find virtio disk");
    80006b42:	00002517          	auipc	a0,0x2
    80006b46:	cae50513          	addi	a0,a0,-850 # 800087f0 <syscalls+0x390>
    80006b4a:	ffffa097          	auipc	ra,0xffffa
    80006b4e:	9f2080e7          	jalr	-1550(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006b52:	00002517          	auipc	a0,0x2
    80006b56:	cbe50513          	addi	a0,a0,-834 # 80008810 <syscalls+0x3b0>
    80006b5a:	ffffa097          	auipc	ra,0xffffa
    80006b5e:	9e2080e7          	jalr	-1566(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006b62:	00002517          	auipc	a0,0x2
    80006b66:	cce50513          	addi	a0,a0,-818 # 80008830 <syscalls+0x3d0>
    80006b6a:	ffffa097          	auipc	ra,0xffffa
    80006b6e:	9d2080e7          	jalr	-1582(ra) # 8000053c <panic>

0000000080006b72 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b72:	7119                	addi	sp,sp,-128
    80006b74:	fc86                	sd	ra,120(sp)
    80006b76:	f8a2                	sd	s0,112(sp)
    80006b78:	f4a6                	sd	s1,104(sp)
    80006b7a:	f0ca                	sd	s2,96(sp)
    80006b7c:	ecce                	sd	s3,88(sp)
    80006b7e:	e8d2                	sd	s4,80(sp)
    80006b80:	e4d6                	sd	s5,72(sp)
    80006b82:	e0da                	sd	s6,64(sp)
    80006b84:	fc5e                	sd	s7,56(sp)
    80006b86:	f862                	sd	s8,48(sp)
    80006b88:	f466                	sd	s9,40(sp)
    80006b8a:	f06a                	sd	s10,32(sp)
    80006b8c:	ec6e                	sd	s11,24(sp)
    80006b8e:	0100                	addi	s0,sp,128
    80006b90:	8aaa                	mv	s5,a0
    80006b92:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b94:	00c52c83          	lw	s9,12(a0)
    80006b98:	001c9c9b          	slliw	s9,s9,0x1
    80006b9c:	1c82                	slli	s9,s9,0x20
    80006b9e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006ba2:	0002e517          	auipc	a0,0x2e
    80006ba6:	58650513          	addi	a0,a0,1414 # 80035128 <disk+0x2128>
    80006baa:	ffffa097          	auipc	ra,0xffffa
    80006bae:	072080e7          	jalr	114(ra) # 80000c1c <acquire>
  for(int i = 0; i < 3; i++){
    80006bb2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006bb4:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006bb6:	0002cc17          	auipc	s8,0x2c
    80006bba:	44ac0c13          	addi	s8,s8,1098 # 80033000 <disk>
    80006bbe:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006bc0:	4b0d                	li	s6,3
    80006bc2:	a0ad                	j	80006c2c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006bc4:	00fc0733          	add	a4,s8,a5
    80006bc8:	975e                	add	a4,a4,s7
    80006bca:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006bce:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006bd0:	0207c563          	bltz	a5,80006bfa <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006bd4:	2905                	addiw	s2,s2,1
    80006bd6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006bd8:	19690c63          	beq	s2,s6,80006d70 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80006bdc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006bde:	0002e717          	auipc	a4,0x2e
    80006be2:	43a70713          	addi	a4,a4,1082 # 80035018 <disk+0x2018>
    80006be6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006be8:	00074683          	lbu	a3,0(a4)
    80006bec:	fee1                	bnez	a3,80006bc4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006bee:	2785                	addiw	a5,a5,1
    80006bf0:	0705                	addi	a4,a4,1
    80006bf2:	fe979be3          	bne	a5,s1,80006be8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006bf6:	57fd                	li	a5,-1
    80006bf8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006bfa:	01205d63          	blez	s2,80006c14 <virtio_disk_rw+0xa2>
    80006bfe:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006c00:	000a2503          	lw	a0,0(s4)
    80006c04:	00000097          	auipc	ra,0x0
    80006c08:	d92080e7          	jalr	-622(ra) # 80006996 <free_desc>
      for(int j = 0; j < i; j++)
    80006c0c:	2d85                	addiw	s11,s11,1
    80006c0e:	0a11                	addi	s4,s4,4
    80006c10:	ff2d98e3          	bne	s11,s2,80006c00 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c14:	0002e597          	auipc	a1,0x2e
    80006c18:	51458593          	addi	a1,a1,1300 # 80035128 <disk+0x2128>
    80006c1c:	0002e517          	auipc	a0,0x2e
    80006c20:	3fc50513          	addi	a0,a0,1020 # 80035018 <disk+0x2018>
    80006c24:	ffffb097          	auipc	ra,0xffffb
    80006c28:	2d0080e7          	jalr	720(ra) # 80001ef4 <sleep>
  for(int i = 0; i < 3; i++){
    80006c2c:	f8040a13          	addi	s4,s0,-128
{
    80006c30:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006c32:	894e                	mv	s2,s3
    80006c34:	b765                	j	80006bdc <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c36:	0002e697          	auipc	a3,0x2e
    80006c3a:	3ca6b683          	ld	a3,970(a3) # 80035000 <disk+0x2000>
    80006c3e:	96ba                	add	a3,a3,a4
    80006c40:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c44:	0002c817          	auipc	a6,0x2c
    80006c48:	3bc80813          	addi	a6,a6,956 # 80033000 <disk>
    80006c4c:	0002e697          	auipc	a3,0x2e
    80006c50:	3b468693          	addi	a3,a3,948 # 80035000 <disk+0x2000>
    80006c54:	6290                	ld	a2,0(a3)
    80006c56:	963a                	add	a2,a2,a4
    80006c58:	00c65583          	lhu	a1,12(a2)
    80006c5c:	0015e593          	ori	a1,a1,1
    80006c60:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006c64:	f8842603          	lw	a2,-120(s0)
    80006c68:	628c                	ld	a1,0(a3)
    80006c6a:	972e                	add	a4,a4,a1
    80006c6c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c70:	20050593          	addi	a1,a0,512
    80006c74:	0592                	slli	a1,a1,0x4
    80006c76:	95c2                	add	a1,a1,a6
    80006c78:	577d                	li	a4,-1
    80006c7a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c7e:	00461713          	slli	a4,a2,0x4
    80006c82:	6290                	ld	a2,0(a3)
    80006c84:	963a                	add	a2,a2,a4
    80006c86:	03078793          	addi	a5,a5,48
    80006c8a:	97c2                	add	a5,a5,a6
    80006c8c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006c8e:	629c                	ld	a5,0(a3)
    80006c90:	97ba                	add	a5,a5,a4
    80006c92:	4605                	li	a2,1
    80006c94:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c96:	629c                	ld	a5,0(a3)
    80006c98:	97ba                	add	a5,a5,a4
    80006c9a:	4809                	li	a6,2
    80006c9c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006ca0:	629c                	ld	a5,0(a3)
    80006ca2:	97ba                	add	a5,a5,a4
    80006ca4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ca8:	00caa223          	sw	a2,4(s5) # 1004 <_entry-0x7fffeffc>
  disk.info[idx[0]].b = b;
    80006cac:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006cb0:	6698                	ld	a4,8(a3)
    80006cb2:	00275783          	lhu	a5,2(a4)
    80006cb6:	8b9d                	andi	a5,a5,7
    80006cb8:	0786                	slli	a5,a5,0x1
    80006cba:	973e                	add	a4,a4,a5
    80006cbc:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006cc0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006cc4:	6698                	ld	a4,8(a3)
    80006cc6:	00275783          	lhu	a5,2(a4)
    80006cca:	2785                	addiw	a5,a5,1
    80006ccc:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006cd0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006cd4:	100017b7          	lui	a5,0x10001
    80006cd8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cdc:	004aa783          	lw	a5,4(s5)
    80006ce0:	02c79163          	bne	a5,a2,80006d02 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006ce4:	0002e917          	auipc	s2,0x2e
    80006ce8:	44490913          	addi	s2,s2,1092 # 80035128 <disk+0x2128>
  while(b->disk == 1) {
    80006cec:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006cee:	85ca                	mv	a1,s2
    80006cf0:	8556                	mv	a0,s5
    80006cf2:	ffffb097          	auipc	ra,0xffffb
    80006cf6:	202080e7          	jalr	514(ra) # 80001ef4 <sleep>
  while(b->disk == 1) {
    80006cfa:	004aa783          	lw	a5,4(s5)
    80006cfe:	fe9788e3          	beq	a5,s1,80006cee <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006d02:	f8042903          	lw	s2,-128(s0)
    80006d06:	20090713          	addi	a4,s2,512
    80006d0a:	0712                	slli	a4,a4,0x4
    80006d0c:	0002c797          	auipc	a5,0x2c
    80006d10:	2f478793          	addi	a5,a5,756 # 80033000 <disk>
    80006d14:	97ba                	add	a5,a5,a4
    80006d16:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d1a:	0002e997          	auipc	s3,0x2e
    80006d1e:	2e698993          	addi	s3,s3,742 # 80035000 <disk+0x2000>
    80006d22:	00491713          	slli	a4,s2,0x4
    80006d26:	0009b783          	ld	a5,0(s3)
    80006d2a:	97ba                	add	a5,a5,a4
    80006d2c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d30:	854a                	mv	a0,s2
    80006d32:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d36:	00000097          	auipc	ra,0x0
    80006d3a:	c60080e7          	jalr	-928(ra) # 80006996 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d3e:	8885                	andi	s1,s1,1
    80006d40:	f0ed                	bnez	s1,80006d22 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d42:	0002e517          	auipc	a0,0x2e
    80006d46:	3e650513          	addi	a0,a0,998 # 80035128 <disk+0x2128>
    80006d4a:	ffffa097          	auipc	ra,0xffffa
    80006d4e:	f86080e7          	jalr	-122(ra) # 80000cd0 <release>
}
    80006d52:	70e6                	ld	ra,120(sp)
    80006d54:	7446                	ld	s0,112(sp)
    80006d56:	74a6                	ld	s1,104(sp)
    80006d58:	7906                	ld	s2,96(sp)
    80006d5a:	69e6                	ld	s3,88(sp)
    80006d5c:	6a46                	ld	s4,80(sp)
    80006d5e:	6aa6                	ld	s5,72(sp)
    80006d60:	6b06                	ld	s6,64(sp)
    80006d62:	7be2                	ld	s7,56(sp)
    80006d64:	7c42                	ld	s8,48(sp)
    80006d66:	7ca2                	ld	s9,40(sp)
    80006d68:	7d02                	ld	s10,32(sp)
    80006d6a:	6de2                	ld	s11,24(sp)
    80006d6c:	6109                	addi	sp,sp,128
    80006d6e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d70:	f8042503          	lw	a0,-128(s0)
    80006d74:	20050793          	addi	a5,a0,512
    80006d78:	0792                	slli	a5,a5,0x4
  if(write)
    80006d7a:	0002c817          	auipc	a6,0x2c
    80006d7e:	28680813          	addi	a6,a6,646 # 80033000 <disk>
    80006d82:	00f80733          	add	a4,a6,a5
    80006d86:	01a036b3          	snez	a3,s10
    80006d8a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006d8e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006d92:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006d96:	7679                	lui	a2,0xffffe
    80006d98:	963e                	add	a2,a2,a5
    80006d9a:	0002e697          	auipc	a3,0x2e
    80006d9e:	26668693          	addi	a3,a3,614 # 80035000 <disk+0x2000>
    80006da2:	6298                	ld	a4,0(a3)
    80006da4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006da6:	0a878593          	addi	a1,a5,168
    80006daa:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006dac:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006dae:	6298                	ld	a4,0(a3)
    80006db0:	9732                	add	a4,a4,a2
    80006db2:	45c1                	li	a1,16
    80006db4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006db6:	6298                	ld	a4,0(a3)
    80006db8:	9732                	add	a4,a4,a2
    80006dba:	4585                	li	a1,1
    80006dbc:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006dc0:	f8442703          	lw	a4,-124(s0)
    80006dc4:	628c                	ld	a1,0(a3)
    80006dc6:	962e                	add	a2,a2,a1
    80006dc8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffc7376>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006dcc:	0712                	slli	a4,a4,0x4
    80006dce:	6290                	ld	a2,0(a3)
    80006dd0:	963a                	add	a2,a2,a4
    80006dd2:	058a8593          	addi	a1,s5,88
    80006dd6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006dd8:	6294                	ld	a3,0(a3)
    80006dda:	96ba                	add	a3,a3,a4
    80006ddc:	40000613          	li	a2,1024
    80006de0:	c690                	sw	a2,8(a3)
  if(write)
    80006de2:	e40d1ae3          	bnez	s10,80006c36 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006de6:	0002e697          	auipc	a3,0x2e
    80006dea:	21a6b683          	ld	a3,538(a3) # 80035000 <disk+0x2000>
    80006dee:	96ba                	add	a3,a3,a4
    80006df0:	4609                	li	a2,2
    80006df2:	00c69623          	sh	a2,12(a3)
    80006df6:	b5b9                	j	80006c44 <virtio_disk_rw+0xd2>

0000000080006df8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006df8:	1101                	addi	sp,sp,-32
    80006dfa:	ec06                	sd	ra,24(sp)
    80006dfc:	e822                	sd	s0,16(sp)
    80006dfe:	e426                	sd	s1,8(sp)
    80006e00:	e04a                	sd	s2,0(sp)
    80006e02:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e04:	0002e517          	auipc	a0,0x2e
    80006e08:	32450513          	addi	a0,a0,804 # 80035128 <disk+0x2128>
    80006e0c:	ffffa097          	auipc	ra,0xffffa
    80006e10:	e10080e7          	jalr	-496(ra) # 80000c1c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e14:	10001737          	lui	a4,0x10001
    80006e18:	533c                	lw	a5,96(a4)
    80006e1a:	8b8d                	andi	a5,a5,3
    80006e1c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e1e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e22:	0002e797          	auipc	a5,0x2e
    80006e26:	1de78793          	addi	a5,a5,478 # 80035000 <disk+0x2000>
    80006e2a:	6b94                	ld	a3,16(a5)
    80006e2c:	0207d703          	lhu	a4,32(a5)
    80006e30:	0026d783          	lhu	a5,2(a3)
    80006e34:	06f70163          	beq	a4,a5,80006e96 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e38:	0002c917          	auipc	s2,0x2c
    80006e3c:	1c890913          	addi	s2,s2,456 # 80033000 <disk>
    80006e40:	0002e497          	auipc	s1,0x2e
    80006e44:	1c048493          	addi	s1,s1,448 # 80035000 <disk+0x2000>
    __sync_synchronize();
    80006e48:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e4c:	6898                	ld	a4,16(s1)
    80006e4e:	0204d783          	lhu	a5,32(s1)
    80006e52:	8b9d                	andi	a5,a5,7
    80006e54:	078e                	slli	a5,a5,0x3
    80006e56:	97ba                	add	a5,a5,a4
    80006e58:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e5a:	20078713          	addi	a4,a5,512
    80006e5e:	0712                	slli	a4,a4,0x4
    80006e60:	974a                	add	a4,a4,s2
    80006e62:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006e66:	e731                	bnez	a4,80006eb2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e68:	20078793          	addi	a5,a5,512
    80006e6c:	0792                	slli	a5,a5,0x4
    80006e6e:	97ca                	add	a5,a5,s2
    80006e70:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006e72:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e76:	ffffb097          	auipc	ra,0xffffb
    80006e7a:	0ee080e7          	jalr	238(ra) # 80001f64 <wakeup>

    disk.used_idx += 1;
    80006e7e:	0204d783          	lhu	a5,32(s1)
    80006e82:	2785                	addiw	a5,a5,1
    80006e84:	17c2                	slli	a5,a5,0x30
    80006e86:	93c1                	srli	a5,a5,0x30
    80006e88:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e8c:	6898                	ld	a4,16(s1)
    80006e8e:	00275703          	lhu	a4,2(a4)
    80006e92:	faf71be3          	bne	a4,a5,80006e48 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e96:	0002e517          	auipc	a0,0x2e
    80006e9a:	29250513          	addi	a0,a0,658 # 80035128 <disk+0x2128>
    80006e9e:	ffffa097          	auipc	ra,0xffffa
    80006ea2:	e32080e7          	jalr	-462(ra) # 80000cd0 <release>
}
    80006ea6:	60e2                	ld	ra,24(sp)
    80006ea8:	6442                	ld	s0,16(sp)
    80006eaa:	64a2                	ld	s1,8(sp)
    80006eac:	6902                	ld	s2,0(sp)
    80006eae:	6105                	addi	sp,sp,32
    80006eb0:	8082                	ret
      panic("virtio_disk_intr status");
    80006eb2:	00002517          	auipc	a0,0x2
    80006eb6:	99e50513          	addi	a0,a0,-1634 # 80008850 <syscalls+0x3f0>
    80006eba:	ffff9097          	auipc	ra,0xffff9
    80006ebe:	682080e7          	jalr	1666(ra) # 8000053c <panic>

0000000080006ec2 <seminit>:

struct semtab semtable;  // Declare a semaphore table

// Initialize the semaphore table
void seminit(void)
{
    80006ec2:	7179                	addi	sp,sp,-48
    80006ec4:	f406                	sd	ra,40(sp)
    80006ec6:	f022                	sd	s0,32(sp)
    80006ec8:	ec26                	sd	s1,24(sp)
    80006eca:	e84a                	sd	s2,16(sp)
    80006ecc:	e44e                	sd	s3,8(sp)
    80006ece:	1800                	addi	s0,sp,48
    initlock(&semtable.lock, "semtable");  // Initialize the lock for the semaphore table
    80006ed0:	00002597          	auipc	a1,0x2
    80006ed4:	99858593          	addi	a1,a1,-1640 # 80008868 <syscalls+0x408>
    80006ed8:	0002f517          	auipc	a0,0x2f
    80006edc:	12850513          	addi	a0,a0,296 # 80036000 <semtable>
    80006ee0:	ffffa097          	auipc	ra,0xffffa
    80006ee4:	cac080e7          	jalr	-852(ra) # 80000b8c <initlock>
    for (int i = 0; i < NSEM; i++)
    80006ee8:	0002f497          	auipc	s1,0x2f
    80006eec:	13048493          	addi	s1,s1,304 # 80036018 <semtable+0x18>
    80006ef0:	00030997          	auipc	s3,0x30
    80006ef4:	da898993          	addi	s3,s3,-600 # 80036c98 <end>
        initlock(&semtable.sem[i].lock, "sem");  // Initialize the lock for each semaphore
    80006ef8:	00002917          	auipc	s2,0x2
    80006efc:	98090913          	addi	s2,s2,-1664 # 80008878 <syscalls+0x418>
    80006f00:	85ca                	mv	a1,s2
    80006f02:	8526                	mv	a0,s1
    80006f04:	ffffa097          	auipc	ra,0xffffa
    80006f08:	c88080e7          	jalr	-888(ra) # 80000b8c <initlock>
    for (int i = 0; i < NSEM; i++)
    80006f0c:	02048493          	addi	s1,s1,32
    80006f10:	ff3498e3          	bne	s1,s3,80006f00 <seminit+0x3e>
};
    80006f14:	70a2                	ld	ra,40(sp)
    80006f16:	7402                	ld	s0,32(sp)
    80006f18:	64e2                	ld	s1,24(sp)
    80006f1a:	6942                	ld	s2,16(sp)
    80006f1c:	69a2                	ld	s3,8(sp)
    80006f1e:	6145                	addi	sp,sp,48
    80006f20:	8082                	ret

0000000080006f22 <semalloc>:

// Allocate a semaphore
int semalloc(void){
    80006f22:	1101                	addi	sp,sp,-32
    80006f24:	ec06                	sd	ra,24(sp)
    80006f26:	e822                	sd	s0,16(sp)
    80006f28:	e426                	sd	s1,8(sp)
    80006f2a:	1000                	addi	s0,sp,32
    acquire(&semtable.lock);  // Acquire the lock for the semaphore table
    80006f2c:	0002f517          	auipc	a0,0x2f
    80006f30:	0d450513          	addi	a0,a0,212 # 80036000 <semtable>
    80006f34:	ffffa097          	auipc	ra,0xffffa
    80006f38:	ce8080e7          	jalr	-792(ra) # 80000c1c <acquire>
    for (int i = 0; i < NSEM; i++){
    80006f3c:	0002f797          	auipc	a5,0x2f
    80006f40:	0f878793          	addi	a5,a5,248 # 80036034 <semtable+0x34>
    80006f44:	4481                	li	s1,0
    80006f46:	06400693          	li	a3,100
        if(!semtable.sem[i].valid){
    80006f4a:	4398                	lw	a4,0(a5)
    80006f4c:	c305                	beqz	a4,80006f6c <semalloc+0x4a>
    for (int i = 0; i < NSEM; i++){
    80006f4e:	2485                	addiw	s1,s1,1
    80006f50:	02078793          	addi	a5,a5,32
    80006f54:	fed49be3          	bne	s1,a3,80006f4a <semalloc+0x28>
            semtable.sem[i].valid = 1;  // Mark the semaphore as valid (in use)
            release(&semtable.lock);    // Release the lock for the semaphore table
            return i;  // Return the index of the allocated semaphore
        }
    }
    release(&semtable.lock);  // Release the lock if no semaphore is available
    80006f58:	0002f517          	auipc	a0,0x2f
    80006f5c:	0a850513          	addi	a0,a0,168 # 80036000 <semtable>
    80006f60:	ffffa097          	auipc	ra,0xffffa
    80006f64:	d70080e7          	jalr	-656(ra) # 80000cd0 <release>
    return -1;  // Return -1 if no semaphore is available
    80006f68:	54fd                	li	s1,-1
    80006f6a:	a839                	j	80006f88 <semalloc+0x66>
            semtable.sem[i].valid = 1;  // Mark the semaphore as valid (in use)
    80006f6c:	0002f517          	auipc	a0,0x2f
    80006f70:	09450513          	addi	a0,a0,148 # 80036000 <semtable>
    80006f74:	00148793          	addi	a5,s1,1
    80006f78:	0796                	slli	a5,a5,0x5
    80006f7a:	97aa                	add	a5,a5,a0
    80006f7c:	4705                	li	a4,1
    80006f7e:	cbd8                	sw	a4,20(a5)
            release(&semtable.lock);    // Release the lock for the semaphore table
    80006f80:	ffffa097          	auipc	ra,0xffffa
    80006f84:	d50080e7          	jalr	-688(ra) # 80000cd0 <release>
};
    80006f88:	8526                	mv	a0,s1
    80006f8a:	60e2                	ld	ra,24(sp)
    80006f8c:	6442                	ld	s0,16(sp)
    80006f8e:	64a2                	ld	s1,8(sp)
    80006f90:	6105                	addi	sp,sp,32
    80006f92:	8082                	ret

0000000080006f94 <semdealloc>:

// Deallocate a semaphore
void semdealloc(int index){
    80006f94:	1101                	addi	sp,sp,-32
    80006f96:	ec06                	sd	ra,24(sp)
    80006f98:	e822                	sd	s0,16(sp)
    80006f9a:	e426                	sd	s1,8(sp)
    80006f9c:	e04a                	sd	s2,0(sp)
    80006f9e:	1000                	addi	s0,sp,32
    80006fa0:	84aa                	mv	s1,a0
    acquire(&semtable.sem[index].lock);  // Acquire the lock for the specified semaphore
    80006fa2:	00551913          	slli	s2,a0,0x5
    80006fa6:	0002f797          	auipc	a5,0x2f
    80006faa:	07278793          	addi	a5,a5,114 # 80036018 <semtable+0x18>
    80006fae:	993e                	add	s2,s2,a5
    80006fb0:	854a                	mv	a0,s2
    80006fb2:	ffffa097          	auipc	ra,0xffffa
    80006fb6:	c6a080e7          	jalr	-918(ra) # 80000c1c <acquire>
    if(index > -1 && index < NSEM){
    80006fba:	0004871b          	sext.w	a4,s1
    80006fbe:	06300793          	li	a5,99
    80006fc2:	00e7eb63          	bltu	a5,a4,80006fd8 <semdealloc+0x44>
        semtable.sem[index].valid = 0;  // Invalidate the semaphore
    80006fc6:	0485                	addi	s1,s1,1
    80006fc8:	0496                	slli	s1,s1,0x5
    80006fca:	0002f797          	auipc	a5,0x2f
    80006fce:	03678793          	addi	a5,a5,54 # 80036000 <semtable>
    80006fd2:	97a6                	add	a5,a5,s1
    80006fd4:	0007aa23          	sw	zero,20(a5)
    }
    release(&semtable.sem[index].lock);  // Release the lock for the semaphore
    80006fd8:	854a                	mv	a0,s2
    80006fda:	ffffa097          	auipc	ra,0xffffa
    80006fde:	cf6080e7          	jalr	-778(ra) # 80000cd0 <release>
};
    80006fe2:	60e2                	ld	ra,24(sp)
    80006fe4:	6442                	ld	s0,16(sp)
    80006fe6:	64a2                	ld	s1,8(sp)
    80006fe8:	6902                	ld	s2,0(sp)
    80006fea:	6105                	addi	sp,sp,32
    80006fec:	8082                	ret
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
