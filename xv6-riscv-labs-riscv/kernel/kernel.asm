
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
    80000066:	5de78793          	addi	a5,a5,1502 # 80006640 <timervec>
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
    8000012e:	0c4080e7          	jalr	196(ra) # 800021ee <either_copyin>
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
    800001c4:	92c080e7          	jalr	-1748(ra) # 80001aec <myproc>
    800001c8:	30052783          	lw	a5,768(a0)
    800001cc:	e7b5                	bnez	a5,80000238 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	d1a080e7          	jalr	-742(ra) # 80001eec <sleep>
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
    80000212:	f88080e7          	jalr	-120(ra) # 80002196 <either_copyout>
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
    800002f2:	f58080e7          	jalr	-168(ra) # 80002246 <procdump>
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
    80000446:	b1a080e7          	jalr	-1254(ra) # 80001f5c <wakeup>
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
    80000894:	6cc080e7          	jalr	1740(ra) # 80001f5c <wakeup>
    
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
    80000920:	5d0080e7          	jalr	1488(ra) # 80001eec <sleep>
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
    80000bba:	f1a080e7          	jalr	-230(ra) # 80001ad0 <mycpu>
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
    80000bec:	ee8080e7          	jalr	-280(ra) # 80001ad0 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	cf89                	beqz	a5,80000c0c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	edc080e7          	jalr	-292(ra) # 80001ad0 <mycpu>
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
    80000c10:	ec4080e7          	jalr	-316(ra) # 80001ad0 <mycpu>
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
    80000c50:	e84080e7          	jalr	-380(ra) # 80001ad0 <mycpu>
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
    80000c7c:	e58080e7          	jalr	-424(ra) # 80001ad0 <mycpu>
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
    80000eca:	bfa080e7          	jalr	-1030(ra) # 80001ac0 <cpuid>
    userinit();      // first user process
    mmrlistinit();   //  HW5 - Task 1a
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
    80000ee6:	bde080e7          	jalr	-1058(ra) # 80001ac0 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	692080e7          	jalr	1682(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	d92080e7          	jalr	-622(ra) # 80002c96 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	774080e7          	jalr	1908(ra) # 80006680 <plicinithart>
  }

  scheduler();  
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	e0c080e7          	jalr	-500(ra) # 80001d20 <scheduler>
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
    80000f68:	32a080e7          	jalr	810(ra) # 8000128e <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	070080e7          	jalr	112(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	a98080e7          	jalr	-1384(ra) # 80001a0c <procinit>
    trapinit();      // trap vectors
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	cf2080e7          	jalr	-782(ra) # 80002c6e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	d12080e7          	jalr	-750(ra) # 80002c96 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	6de080e7          	jalr	1758(ra) # 8000666a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	6ec080e7          	jalr	1772(ra) # 80006680 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	5ee080e7          	jalr	1518(ra) # 8000358a <binit>
    iinit();         // inode table
    80000fa4:	00003097          	auipc	ra,0x3
    80000fa8:	c7c080e7          	jalr	-900(ra) # 80003c20 <iinit>
    fileinit();      // file table
    80000fac:	00004097          	auipc	ra,0x4
    80000fb0:	c32080e7          	jalr	-974(ra) # 80004bde <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	7ec080e7          	jalr	2028(ra) # 800067a0 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	748080e7          	jalr	1864(ra) # 80002704 <userinit>
    mmrlistinit();   //  HW5 - Task 1a
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	3f2080e7          	jalr	1010(ra) # 800023b6 <mmrlistinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	04f72323          	sw	a5,70(a4) # 80009018 <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	03e7b783          	ld	a5,62(a5) # 80009020 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	50e080e7          	jalr	1294(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	aa8080e7          	jalr	-1368(ra) # 80000ae2 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cce080e7          	jalr	-818(ra) # 80000d18 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffc8ff7>
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	83a9                	srli	a5,a5,0xa
    800010de:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e8:	715d                	addi	sp,sp,-80
    800010ea:	e486                	sd	ra,72(sp)
    800010ec:	e0a2                	sd	s0,64(sp)
    800010ee:	fc26                	sd	s1,56(sp)
    800010f0:	f84a                	sd	s2,48(sp)
    800010f2:	f44e                	sd	s3,40(sp)
    800010f4:	f052                	sd	s4,32(sp)
    800010f6:	ec56                	sd	s5,24(sp)
    800010f8:	e85a                	sd	s6,16(sp)
    800010fa:	e45e                	sd	s7,8(sp)
    800010fc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010fe:	c639                	beqz	a2,8000114c <mappages+0x64>
    80001100:	8aaa                	mv	s5,a0
    80001102:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001104:	777d                	lui	a4,0xfffff
    80001106:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000110a:	fff58993          	addi	s3,a1,-1
    8000110e:	99b2                	add	s3,s3,a2
    80001110:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001114:	893e                	mv	s2,a5
    80001116:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000111a:	6b85                	lui	s7,0x1
    8000111c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001120:	4605                	li	a2,1
    80001122:	85ca                	mv	a1,s2
    80001124:	8556                	mv	a0,s5
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	eda080e7          	jalr	-294(ra) # 80001000 <walk>
    8000112e:	cd1d                	beqz	a0,8000116c <mappages+0x84>
    if(*pte & PTE_V)
    80001130:	611c                	ld	a5,0(a0)
    80001132:	8b85                	andi	a5,a5,1
    80001134:	e785                	bnez	a5,8000115c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001136:	80b1                	srli	s1,s1,0xc
    80001138:	04aa                	slli	s1,s1,0xa
    8000113a:	0164e4b3          	or	s1,s1,s6
    8000113e:	0014e493          	ori	s1,s1,1
    80001142:	e104                	sd	s1,0(a0)
    if(a == last)
    80001144:	05390063          	beq	s2,s3,80001184 <mappages+0x9c>
    a += PGSIZE;
    80001148:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114a:	bfc9                	j	8000111c <mappages+0x34>
    panic("mappages: size");
    8000114c:	00007517          	auipc	a0,0x7
    80001150:	f8c50513          	addi	a0,a0,-116 # 800080d8 <digits+0x98>
    80001154:	fffff097          	auipc	ra,0xfffff
    80001158:	3e8080e7          	jalr	1000(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f8c50513          	addi	a0,a0,-116 # 800080e8 <digits+0xa8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3d8080e7          	jalr	984(ra) # 8000053c <panic>
      return -1;
    8000116c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000116e:	60a6                	ld	ra,72(sp)
    80001170:	6406                	ld	s0,64(sp)
    80001172:	74e2                	ld	s1,56(sp)
    80001174:	7942                	ld	s2,48(sp)
    80001176:	79a2                	ld	s3,40(sp)
    80001178:	7a02                	ld	s4,32(sp)
    8000117a:	6ae2                	ld	s5,24(sp)
    8000117c:	6b42                	ld	s6,16(sp)
    8000117e:	6ba2                	ld	s7,8(sp)
    80001180:	6161                	addi	sp,sp,80
    80001182:	8082                	ret
  return 0;
    80001184:	4501                	li	a0,0
    80001186:	b7e5                	j	8000116e <mappages+0x86>

0000000080001188 <kvmmap>:
{
    80001188:	1141                	addi	sp,sp,-16
    8000118a:	e406                	sd	ra,8(sp)
    8000118c:	e022                	sd	s0,0(sp)
    8000118e:	0800                	addi	s0,sp,16
    80001190:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001192:	86b2                	mv	a3,a2
    80001194:	863e                	mv	a2,a5
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	f52080e7          	jalr	-174(ra) # 800010e8 <mappages>
    8000119e:	e509                	bnez	a0,800011a8 <kvmmap+0x20>
}
    800011a0:	60a2                	ld	ra,8(sp)
    800011a2:	6402                	ld	s0,0(sp)
    800011a4:	0141                	addi	sp,sp,16
    800011a6:	8082                	ret
    panic("kvmmap");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f5050513          	addi	a0,a0,-176 # 800080f8 <digits+0xb8>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	38c080e7          	jalr	908(ra) # 8000053c <panic>

00000000800011b8 <kvmmake>:
{
    800011b8:	1101                	addi	sp,sp,-32
    800011ba:	ec06                	sd	ra,24(sp)
    800011bc:	e822                	sd	s0,16(sp)
    800011be:	e426                	sd	s1,8(sp)
    800011c0:	e04a                	sd	s2,0(sp)
    800011c2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	91e080e7          	jalr	-1762(ra) # 80000ae2 <kalloc>
    800011cc:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ce:	6605                	lui	a2,0x1
    800011d0:	4581                	li	a1,0
    800011d2:	00000097          	auipc	ra,0x0
    800011d6:	b46080e7          	jalr	-1210(ra) # 80000d18 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011da:	4719                	li	a4,6
    800011dc:	6685                	lui	a3,0x1
    800011de:	10000637          	lui	a2,0x10000
    800011e2:	100005b7          	lui	a1,0x10000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	fa0080e7          	jalr	-96(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	6685                	lui	a3,0x1
    800011f4:	10001637          	lui	a2,0x10001
    800011f8:	100015b7          	lui	a1,0x10001
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f8a080e7          	jalr	-118(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001206:	4719                	li	a4,6
    80001208:	004006b7          	lui	a3,0x400
    8000120c:	0c000637          	lui	a2,0xc000
    80001210:	0c0005b7          	lui	a1,0xc000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f72080e7          	jalr	-142(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000121e:	00007917          	auipc	s2,0x7
    80001222:	de290913          	addi	s2,s2,-542 # 80008000 <etext>
    80001226:	4729                	li	a4,10
    80001228:	80007697          	auipc	a3,0x80007
    8000122c:	dd868693          	addi	a3,a3,-552 # 8000 <_entry-0x7fff8000>
    80001230:	4605                	li	a2,1
    80001232:	067e                	slli	a2,a2,0x1f
    80001234:	85b2                	mv	a1,a2
    80001236:	8526                	mv	a0,s1
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f50080e7          	jalr	-176(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001240:	4719                	li	a4,6
    80001242:	46c5                	li	a3,17
    80001244:	06ee                	slli	a3,a3,0x1b
    80001246:	412686b3          	sub	a3,a3,s2
    8000124a:	864a                	mv	a2,s2
    8000124c:	85ca                	mv	a1,s2
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	f38080e7          	jalr	-200(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001258:	4729                	li	a4,10
    8000125a:	6685                	lui	a3,0x1
    8000125c:	00006617          	auipc	a2,0x6
    80001260:	da460613          	addi	a2,a2,-604 # 80007000 <_trampoline>
    80001264:	040005b7          	lui	a1,0x4000
    80001268:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000126a:	05b2                	slli	a1,a1,0xc
    8000126c:	8526                	mv	a0,s1
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f1a080e7          	jalr	-230(ra) # 80001188 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001276:	8526                	mv	a0,s1
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	6fe080e7          	jalr	1790(ra) # 80001976 <proc_mapstacks>
}
    80001280:	8526                	mv	a0,s1
    80001282:	60e2                	ld	ra,24(sp)
    80001284:	6442                	ld	s0,16(sp)
    80001286:	64a2                	ld	s1,8(sp)
    80001288:	6902                	ld	s2,0(sp)
    8000128a:	6105                	addi	sp,sp,32
    8000128c:	8082                	ret

000000008000128e <kvminit>:
{
    8000128e:	1141                	addi	sp,sp,-16
    80001290:	e406                	sd	ra,8(sp)
    80001292:	e022                	sd	s0,0(sp)
    80001294:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	f22080e7          	jalr	-222(ra) # 800011b8 <kvmmake>
    8000129e:	00008797          	auipc	a5,0x8
    800012a2:	d8a7b123          	sd	a0,-638(a5) # 80009020 <kernel_pagetable>
}
    800012a6:	60a2                	ld	ra,8(sp)
    800012a8:	6402                	ld	s0,0(sp)
    800012aa:	0141                	addi	sp,sp,16
    800012ac:	8082                	ret

00000000800012ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ae:	715d                	addi	sp,sp,-80
    800012b0:	e486                	sd	ra,72(sp)
    800012b2:	e0a2                	sd	s0,64(sp)
    800012b4:	fc26                	sd	s1,56(sp)
    800012b6:	f84a                	sd	s2,48(sp)
    800012b8:	f44e                	sd	s3,40(sp)
    800012ba:	f052                	sd	s4,32(sp)
    800012bc:	ec56                	sd	s5,24(sp)
    800012be:	e85a                	sd	s6,16(sp)
    800012c0:	e45e                	sd	s7,8(sp)
    800012c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c4:	03459793          	slli	a5,a1,0x34
    800012c8:	e795                	bnez	a5,800012f4 <uvmunmap+0x46>
    800012ca:	8a2a                	mv	s4,a0
    800012cc:	892e                	mv	s2,a1
    800012ce:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	0632                	slli	a2,a2,0xc
    800012d2:	00b609b3          	add	s3,a2,a1
      // panic("uvmunmap: walk");
      continue;
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped"); -- HW 4 - TASK 4
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	6a85                	lui	s5,0x1
    800012da:	0535e263          	bltu	a1,s3,8000131e <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e0c50513          	addi	a0,a0,-500 # 80008100 <digits+0xc0>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	240080e7          	jalr	576(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e1450513          	addi	a0,a0,-492 # 80008118 <digits+0xd8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	230080e7          	jalr	560(ra) # 8000053c <panic>
    *pte = 0;
    80001314:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001318:	9956                	add	s2,s2,s5
    8000131a:	fd3972e3          	bgeu	s2,s3,800012de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131e:	4601                	li	a2,0
    80001320:	85ca                	mv	a1,s2
    80001322:	8552                	mv	a0,s4
    80001324:	00000097          	auipc	ra,0x0
    80001328:	cdc080e7          	jalr	-804(ra) # 80001000 <walk>
    8000132c:	84aa                	mv	s1,a0
    8000132e:	d56d                	beqz	a0,80001318 <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    80001330:	611c                	ld	a5,0(a0)
    80001332:	0017f713          	andi	a4,a5,1
    80001336:	d36d                	beqz	a4,80001318 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001338:	3ff7f713          	andi	a4,a5,1023
    8000133c:	fd7704e3          	beq	a4,s7,80001304 <uvmunmap+0x56>
    if(do_free){
    80001340:	fc0b0ae3          	beqz	s6,80001314 <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    80001344:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001346:	00c79513          	slli	a0,a5,0xc
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	69a080e7          	jalr	1690(ra) # 800009e4 <kfree>
    80001352:	b7c9                	j	80001314 <uvmunmap+0x66>

0000000080001354 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001354:	1101                	addi	sp,sp,-32
    80001356:	ec06                	sd	ra,24(sp)
    80001358:	e822                	sd	s0,16(sp)
    8000135a:	e426                	sd	s1,8(sp)
    8000135c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000135e:	fffff097          	auipc	ra,0xfffff
    80001362:	784080e7          	jalr	1924(ra) # 80000ae2 <kalloc>
    80001366:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001368:	c519                	beqz	a0,80001376 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	00000097          	auipc	ra,0x0
    80001372:	9aa080e7          	jalr	-1622(ra) # 80000d18 <memset>
  return pagetable;
}
    80001376:	8526                	mv	a0,s1
    80001378:	60e2                	ld	ra,24(sp)
    8000137a:	6442                	ld	s0,16(sp)
    8000137c:	64a2                	ld	s1,8(sp)
    8000137e:	6105                	addi	sp,sp,32
    80001380:	8082                	ret

0000000080001382 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001382:	7179                	addi	sp,sp,-48
    80001384:	f406                	sd	ra,40(sp)
    80001386:	f022                	sd	s0,32(sp)
    80001388:	ec26                	sd	s1,24(sp)
    8000138a:	e84a                	sd	s2,16(sp)
    8000138c:	e44e                	sd	s3,8(sp)
    8000138e:	e052                	sd	s4,0(sp)
    80001390:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001392:	6785                	lui	a5,0x1
    80001394:	04f67863          	bgeu	a2,a5,800013e4 <uvminit+0x62>
    80001398:	8a2a                	mv	s4,a0
    8000139a:	89ae                	mv	s3,a1
    8000139c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	744080e7          	jalr	1860(ra) # 80000ae2 <kalloc>
    800013a6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	96c080e7          	jalr	-1684(ra) # 80000d18 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013b4:	4779                	li	a4,30
    800013b6:	86ca                	mv	a3,s2
    800013b8:	6605                	lui	a2,0x1
    800013ba:	4581                	li	a1,0
    800013bc:	8552                	mv	a0,s4
    800013be:	00000097          	auipc	ra,0x0
    800013c2:	d2a080e7          	jalr	-726(ra) # 800010e8 <mappages>
  memmove(mem, src, sz);
    800013c6:	8626                	mv	a2,s1
    800013c8:	85ce                	mv	a1,s3
    800013ca:	854a                	mv	a0,s2
    800013cc:	00000097          	auipc	ra,0x0
    800013d0:	9a8080e7          	jalr	-1624(ra) # 80000d74 <memmove>
}
    800013d4:	70a2                	ld	ra,40(sp)
    800013d6:	7402                	ld	s0,32(sp)
    800013d8:	64e2                	ld	s1,24(sp)
    800013da:	6942                	ld	s2,16(sp)
    800013dc:	69a2                	ld	s3,8(sp)
    800013de:	6a02                	ld	s4,0(sp)
    800013e0:	6145                	addi	sp,sp,48
    800013e2:	8082                	ret
    panic("inituvm: more than a page");
    800013e4:	00007517          	auipc	a0,0x7
    800013e8:	d4c50513          	addi	a0,a0,-692 # 80008130 <digits+0xf0>
    800013ec:	fffff097          	auipc	ra,0xfffff
    800013f0:	150080e7          	jalr	336(ra) # 8000053c <panic>

00000000800013f4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013f4:	1101                	addi	sp,sp,-32
    800013f6:	ec06                	sd	ra,24(sp)
    800013f8:	e822                	sd	s0,16(sp)
    800013fa:	e426                	sd	s1,8(sp)
    800013fc:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013fe:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001400:	00b67d63          	bgeu	a2,a1,8000141a <uvmdealloc+0x26>
    80001404:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001406:	6785                	lui	a5,0x1
    80001408:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000140a:	00f60733          	add	a4,a2,a5
    8000140e:	76fd                	lui	a3,0xfffff
    80001410:	8f75                	and	a4,a4,a3
    80001412:	97ae                	add	a5,a5,a1
    80001414:	8ff5                	and	a5,a5,a3
    80001416:	00f76863          	bltu	a4,a5,80001426 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000141a:	8526                	mv	a0,s1
    8000141c:	60e2                	ld	ra,24(sp)
    8000141e:	6442                	ld	s0,16(sp)
    80001420:	64a2                	ld	s1,8(sp)
    80001422:	6105                	addi	sp,sp,32
    80001424:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001426:	8f99                	sub	a5,a5,a4
    80001428:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000142a:	4685                	li	a3,1
    8000142c:	0007861b          	sext.w	a2,a5
    80001430:	85ba                	mv	a1,a4
    80001432:	00000097          	auipc	ra,0x0
    80001436:	e7c080e7          	jalr	-388(ra) # 800012ae <uvmunmap>
    8000143a:	b7c5                	j	8000141a <uvmdealloc+0x26>

000000008000143c <uvmalloc>:
  if(newsz < oldsz)
    8000143c:	0ab66163          	bltu	a2,a1,800014de <uvmalloc+0xa2>
{
    80001440:	7139                	addi	sp,sp,-64
    80001442:	fc06                	sd	ra,56(sp)
    80001444:	f822                	sd	s0,48(sp)
    80001446:	f426                	sd	s1,40(sp)
    80001448:	f04a                	sd	s2,32(sp)
    8000144a:	ec4e                	sd	s3,24(sp)
    8000144c:	e852                	sd	s4,16(sp)
    8000144e:	e456                	sd	s5,8(sp)
    80001450:	0080                	addi	s0,sp,64
    80001452:	8aaa                	mv	s5,a0
    80001454:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001456:	6785                	lui	a5,0x1
    80001458:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000145a:	95be                	add	a1,a1,a5
    8000145c:	77fd                	lui	a5,0xfffff
    8000145e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001462:	08c9f063          	bgeu	s3,a2,800014e2 <uvmalloc+0xa6>
    80001466:	894e                	mv	s2,s3
    mem = kalloc();
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	67a080e7          	jalr	1658(ra) # 80000ae2 <kalloc>
    80001470:	84aa                	mv	s1,a0
    if(mem == 0){
    80001472:	c51d                	beqz	a0,800014a0 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001474:	6605                	lui	a2,0x1
    80001476:	4581                	li	a1,0
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	8a0080e7          	jalr	-1888(ra) # 80000d18 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001480:	4779                	li	a4,30
    80001482:	86a6                	mv	a3,s1
    80001484:	6605                	lui	a2,0x1
    80001486:	85ca                	mv	a1,s2
    80001488:	8556                	mv	a0,s5
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	c5e080e7          	jalr	-930(ra) # 800010e8 <mappages>
    80001492:	e905                	bnez	a0,800014c2 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001494:	6785                	lui	a5,0x1
    80001496:	993e                	add	s2,s2,a5
    80001498:	fd4968e3          	bltu	s2,s4,80001468 <uvmalloc+0x2c>
  return newsz;
    8000149c:	8552                	mv	a0,s4
    8000149e:	a809                	j	800014b0 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014a0:	864e                	mv	a2,s3
    800014a2:	85ca                	mv	a1,s2
    800014a4:	8556                	mv	a0,s5
    800014a6:	00000097          	auipc	ra,0x0
    800014aa:	f4e080e7          	jalr	-178(ra) # 800013f4 <uvmdealloc>
      return 0;
    800014ae:	4501                	li	a0,0
}
    800014b0:	70e2                	ld	ra,56(sp)
    800014b2:	7442                	ld	s0,48(sp)
    800014b4:	74a2                	ld	s1,40(sp)
    800014b6:	7902                	ld	s2,32(sp)
    800014b8:	69e2                	ld	s3,24(sp)
    800014ba:	6a42                	ld	s4,16(sp)
    800014bc:	6aa2                	ld	s5,8(sp)
    800014be:	6121                	addi	sp,sp,64
    800014c0:	8082                	ret
      kfree(mem);
    800014c2:	8526                	mv	a0,s1
    800014c4:	fffff097          	auipc	ra,0xfffff
    800014c8:	520080e7          	jalr	1312(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014cc:	864e                	mv	a2,s3
    800014ce:	85ca                	mv	a1,s2
    800014d0:	8556                	mv	a0,s5
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	f22080e7          	jalr	-222(ra) # 800013f4 <uvmdealloc>
      return 0;
    800014da:	4501                	li	a0,0
    800014dc:	bfd1                	j	800014b0 <uvmalloc+0x74>
    return oldsz;
    800014de:	852e                	mv	a0,a1
}
    800014e0:	8082                	ret
  return newsz;
    800014e2:	8532                	mv	a0,a2
    800014e4:	b7f1                	j	800014b0 <uvmalloc+0x74>

00000000800014e6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014e6:	7179                	addi	sp,sp,-48
    800014e8:	f406                	sd	ra,40(sp)
    800014ea:	f022                	sd	s0,32(sp)
    800014ec:	ec26                	sd	s1,24(sp)
    800014ee:	e84a                	sd	s2,16(sp)
    800014f0:	e44e                	sd	s3,8(sp)
    800014f2:	e052                	sd	s4,0(sp)
    800014f4:	1800                	addi	s0,sp,48
    800014f6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f8:	84aa                	mv	s1,a0
    800014fa:	6905                	lui	s2,0x1
    800014fc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fe:	4985                	li	s3,1
    80001500:	a829                	j	8000151a <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001502:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001504:	00c79513          	slli	a0,a5,0xc
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	fde080e7          	jalr	-34(ra) # 800014e6 <freewalk>
      pagetable[i] = 0;
    80001510:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001514:	04a1                	addi	s1,s1,8
    80001516:	03248163          	beq	s1,s2,80001538 <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000151a:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151c:	00f7f713          	andi	a4,a5,15
    80001520:	ff3701e3          	beq	a4,s3,80001502 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001524:	8b85                	andi	a5,a5,1
    80001526:	d7fd                	beqz	a5,80001514 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001528:	00007517          	auipc	a0,0x7
    8000152c:	c2850513          	addi	a0,a0,-984 # 80008150 <digits+0x110>
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	00c080e7          	jalr	12(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001538:	8552                	mv	a0,s4
    8000153a:	fffff097          	auipc	ra,0xfffff
    8000153e:	4aa080e7          	jalr	1194(ra) # 800009e4 <kfree>
}
    80001542:	70a2                	ld	ra,40(sp)
    80001544:	7402                	ld	s0,32(sp)
    80001546:	64e2                	ld	s1,24(sp)
    80001548:	6942                	ld	s2,16(sp)
    8000154a:	69a2                	ld	s3,8(sp)
    8000154c:	6a02                	ld	s4,0(sp)
    8000154e:	6145                	addi	sp,sp,48
    80001550:	8082                	ret

0000000080001552 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001552:	1101                	addi	sp,sp,-32
    80001554:	ec06                	sd	ra,24(sp)
    80001556:	e822                	sd	s0,16(sp)
    80001558:	e426                	sd	s1,8(sp)
    8000155a:	1000                	addi	s0,sp,32
    8000155c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000155e:	e999                	bnez	a1,80001574 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001560:	8526                	mv	a0,s1
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f84080e7          	jalr	-124(ra) # 800014e6 <freewalk>
}
    8000156a:	60e2                	ld	ra,24(sp)
    8000156c:	6442                	ld	s0,16(sp)
    8000156e:	64a2                	ld	s1,8(sp)
    80001570:	6105                	addi	sp,sp,32
    80001572:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001574:	6785                	lui	a5,0x1
    80001576:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001578:	95be                	add	a1,a1,a5
    8000157a:	4685                	li	a3,1
    8000157c:	00c5d613          	srli	a2,a1,0xc
    80001580:	4581                	li	a1,0
    80001582:	00000097          	auipc	ra,0x0
    80001586:	d2c080e7          	jalr	-724(ra) # 800012ae <uvmunmap>
    8000158a:	bfd9                	j	80001560 <uvmfree+0xe>

000000008000158c <uvmcopy>:
//   return -1;
// }
// HW5-TASK 2 change
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 start, uint64 end)
{
    8000158c:	715d                	addi	sp,sp,-80
    8000158e:	e486                	sd	ra,72(sp)
    80001590:	e0a2                	sd	s0,64(sp)
    80001592:	fc26                	sd	s1,56(sp)
    80001594:	f84a                	sd	s2,48(sp)
    80001596:	f44e                	sd	s3,40(sp)
    80001598:	f052                	sd	s4,32(sp)
    8000159a:	ec56                	sd	s5,24(sp)
    8000159c:	e85a                	sd	s6,16(sp)
    8000159e:	e45e                	sd	s7,8(sp)
    800015a0:	0880                	addi	s0,sp,80
    800015a2:	8b2a                	mv	s6,a0
    800015a4:	8aae                	mv	s5,a1
    800015a6:	89b2                	mv	s3,a2
    800015a8:	8a36                	mv	s4,a3
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = start; i < end; i += PGSIZE){
    800015aa:	0ad67963          	bgeu	a2,a3,8000165c <uvmcopy+0xd0>
    if((pte = walk(old, i, 0)) == 0)
    800015ae:	4601                	li	a2,0
    800015b0:	85ce                	mv	a1,s3
    800015b2:	855a                	mv	a0,s6
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	a4c080e7          	jalr	-1460(ra) # 80001000 <walk>
    800015bc:	c531                	beqz	a0,80001608 <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015be:	6118                	ld	a4,0(a0)
    800015c0:	00177793          	andi	a5,a4,1
    800015c4:	cbb1                	beqz	a5,80001618 <uvmcopy+0x8c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015c6:	00a75593          	srli	a1,a4,0xa
    800015ca:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ce:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	510080e7          	jalr	1296(ra) # 80000ae2 <kalloc>
    800015da:	892a                	mv	s2,a0
    800015dc:	c939                	beqz	a0,80001632 <uvmcopy+0xa6>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015de:	6605                	lui	a2,0x1
    800015e0:	85de                	mv	a1,s7
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	792080e7          	jalr	1938(ra) # 80000d74 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ea:	8726                	mv	a4,s1
    800015ec:	86ca                	mv	a3,s2
    800015ee:	6605                	lui	a2,0x1
    800015f0:	85ce                	mv	a1,s3
    800015f2:	8556                	mv	a0,s5
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	af4080e7          	jalr	-1292(ra) # 800010e8 <mappages>
    800015fc:	e515                	bnez	a0,80001628 <uvmcopy+0x9c>
  for(i = start; i < end; i += PGSIZE){
    800015fe:	6785                	lui	a5,0x1
    80001600:	99be                	add	s3,s3,a5
    80001602:	fb49e6e3          	bltu	s3,s4,800015ae <uvmcopy+0x22>
    80001606:	a081                	j	80001646 <uvmcopy+0xba>
      panic("uvmcopy: pte should exist");
    80001608:	00007517          	auipc	a0,0x7
    8000160c:	b5850513          	addi	a0,a0,-1192 # 80008160 <digits+0x120>
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001618:	00007517          	auipc	a0,0x7
    8000161c:	b6850513          	addi	a0,a0,-1176 # 80008180 <digits+0x140>
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	f1c080e7          	jalr	-228(ra) # 8000053c <panic>
      kfree(mem);
    80001628:	854a                	mv	a0,s2
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	3ba080e7          	jalr	954(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001632:	4685                	li	a3,1
    80001634:	00c9d613          	srli	a2,s3,0xc
    80001638:	4581                	li	a1,0
    8000163a:	8556                	mv	a0,s5
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	c72080e7          	jalr	-910(ra) # 800012ae <uvmunmap>
  return -1;
    80001644:	557d                	li	a0,-1
}
    80001646:	60a6                	ld	ra,72(sp)
    80001648:	6406                	ld	s0,64(sp)
    8000164a:	74e2                	ld	s1,56(sp)
    8000164c:	7942                	ld	s2,48(sp)
    8000164e:	79a2                	ld	s3,40(sp)
    80001650:	7a02                	ld	s4,32(sp)
    80001652:	6ae2                	ld	s5,24(sp)
    80001654:	6b42                	ld	s6,16(sp)
    80001656:	6ba2                	ld	s7,8(sp)
    80001658:	6161                	addi	sp,sp,80
    8000165a:	8082                	ret
  return 0;
    8000165c:	4501                	li	a0,0
    8000165e:	b7e5                	j	80001646 <uvmcopy+0xba>

0000000080001660 <uvmcopyshared>:
// Copies the parent process’s page table to the child
// Duplicates the page table mappings so that the physical memory is shared
// Returns 0 on success, -1 on failure
int
uvmcopyshared(pagetable_t old, pagetable_t new, uint64 start, uint64 end)
{
    80001660:	7179                	addi	sp,sp,-48
    80001662:	f406                	sd	ra,40(sp)
    80001664:	f022                	sd	s0,32(sp)
    80001666:	ec26                	sd	s1,24(sp)
    80001668:	e84a                	sd	s2,16(sp)
    8000166a:	e44e                	sd	s3,8(sp)
    8000166c:	e052                	sd	s4,0(sp)
    8000166e:	1800                	addi	s0,sp,48
    80001670:	8a2a                	mv	s4,a0
    80001672:	89ae                	mv	s3,a1
    80001674:	84b2                	mv	s1,a2
    80001676:	8936                	mv	s2,a3
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = start; i < end; i += PGSIZE){
    80001678:	08d67263          	bgeu	a2,a3,800016fc <uvmcopyshared+0x9c>
    if((pte = walk(old, i, 0)) == 0)
    8000167c:	4601                	li	a2,0
    8000167e:	85a6                	mv	a1,s1
    80001680:	8552                	mv	a0,s4
    80001682:	00000097          	auipc	ra,0x0
    80001686:	97e080e7          	jalr	-1666(ra) # 80001000 <walk>
    8000168a:	c51d                	beqz	a0,800016b8 <uvmcopyshared+0x58>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000168c:	6118                	ld	a4,0(a0)
    8000168e:	00177793          	andi	a5,a4,1
    80001692:	cb9d                	beqz	a5,800016c8 <uvmcopyshared+0x68>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001694:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    80001698:	3ff77713          	andi	a4,a4,1023
    8000169c:	06b2                	slli	a3,a3,0xc
    8000169e:	6605                	lui	a2,0x1
    800016a0:	85a6                	mv	a1,s1
    800016a2:	854e                	mv	a0,s3
    800016a4:	00000097          	auipc	ra,0x0
    800016a8:	a44080e7          	jalr	-1468(ra) # 800010e8 <mappages>
    800016ac:	e515                	bnez	a0,800016d8 <uvmcopyshared+0x78>
  for(i = start; i < end; i += PGSIZE){
    800016ae:	6785                	lui	a5,0x1
    800016b0:	94be                	add	s1,s1,a5
    800016b2:	fd24e5e3          	bltu	s1,s2,8000167c <uvmcopyshared+0x1c>
    800016b6:	a81d                	j	800016ec <uvmcopyshared+0x8c>
      panic("uvmcopy: pte should exist");
    800016b8:	00007517          	auipc	a0,0x7
    800016bc:	aa850513          	addi	a0,a0,-1368 # 80008160 <digits+0x120>
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	e7c080e7          	jalr	-388(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800016c8:	00007517          	auipc	a0,0x7
    800016cc:	ab850513          	addi	a0,a0,-1352 # 80008180 <digits+0x140>
    800016d0:	fffff097          	auipc	ra,0xfffff
    800016d4:	e6c080e7          	jalr	-404(ra) # 8000053c <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016d8:	4685                	li	a3,1
    800016da:	00c4d613          	srli	a2,s1,0xc
    800016de:	4581                	li	a1,0
    800016e0:	854e                	mv	a0,s3
    800016e2:	00000097          	auipc	ra,0x0
    800016e6:	bcc080e7          	jalr	-1076(ra) # 800012ae <uvmunmap>
  return -1;
    800016ea:	557d                	li	a0,-1
}
    800016ec:	70a2                	ld	ra,40(sp)
    800016ee:	7402                	ld	s0,32(sp)
    800016f0:	64e2                	ld	s1,24(sp)
    800016f2:	6942                	ld	s2,16(sp)
    800016f4:	69a2                	ld	s3,8(sp)
    800016f6:	6a02                	ld	s4,0(sp)
    800016f8:	6145                	addi	sp,sp,48
    800016fa:	8082                	ret
  return 0;
    800016fc:	4501                	li	a0,0
    800016fe:	b7fd                	j	800016ec <uvmcopyshared+0x8c>

0000000080001700 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001700:	1141                	addi	sp,sp,-16
    80001702:	e406                	sd	ra,8(sp)
    80001704:	e022                	sd	s0,0(sp)
    80001706:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001708:	4601                	li	a2,0
    8000170a:	00000097          	auipc	ra,0x0
    8000170e:	8f6080e7          	jalr	-1802(ra) # 80001000 <walk>
  if(pte == 0)
    80001712:	c901                	beqz	a0,80001722 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001714:	611c                	ld	a5,0(a0)
    80001716:	9bbd                	andi	a5,a5,-17
    80001718:	e11c                	sd	a5,0(a0)
}
    8000171a:	60a2                	ld	ra,8(sp)
    8000171c:	6402                	ld	s0,0(sp)
    8000171e:	0141                	addi	sp,sp,16
    80001720:	8082                	ret
    panic("uvmclear");
    80001722:	00007517          	auipc	a0,0x7
    80001726:	a7e50513          	addi	a0,a0,-1410 # 800081a0 <digits+0x160>
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	e12080e7          	jalr	-494(ra) # 8000053c <panic>

0000000080001732 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001732:	c6bd                	beqz	a3,800017a0 <copyout+0x6e>
{
    80001734:	715d                	addi	sp,sp,-80
    80001736:	e486                	sd	ra,72(sp)
    80001738:	e0a2                	sd	s0,64(sp)
    8000173a:	fc26                	sd	s1,56(sp)
    8000173c:	f84a                	sd	s2,48(sp)
    8000173e:	f44e                	sd	s3,40(sp)
    80001740:	f052                	sd	s4,32(sp)
    80001742:	ec56                	sd	s5,24(sp)
    80001744:	e85a                	sd	s6,16(sp)
    80001746:	e45e                	sd	s7,8(sp)
    80001748:	e062                	sd	s8,0(sp)
    8000174a:	0880                	addi	s0,sp,80
    8000174c:	8b2a                	mv	s6,a0
    8000174e:	8c2e                	mv	s8,a1
    80001750:	8a32                	mv	s4,a2
    80001752:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001754:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001756:	6a85                	lui	s5,0x1
    80001758:	a015                	j	8000177c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000175a:	9562                	add	a0,a0,s8
    8000175c:	0004861b          	sext.w	a2,s1
    80001760:	85d2                	mv	a1,s4
    80001762:	41250533          	sub	a0,a0,s2
    80001766:	fffff097          	auipc	ra,0xfffff
    8000176a:	60e080e7          	jalr	1550(ra) # 80000d74 <memmove>

    len -= n;
    8000176e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001772:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001774:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001778:	02098263          	beqz	s3,8000179c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000177c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001780:	85ca                	mv	a1,s2
    80001782:	855a                	mv	a0,s6
    80001784:	00000097          	auipc	ra,0x0
    80001788:	922080e7          	jalr	-1758(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000178c:	cd01                	beqz	a0,800017a4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000178e:	418904b3          	sub	s1,s2,s8
    80001792:	94d6                	add	s1,s1,s5
    80001794:	fc99f3e3          	bgeu	s3,s1,8000175a <copyout+0x28>
    80001798:	84ce                	mv	s1,s3
    8000179a:	b7c1                	j	8000175a <copyout+0x28>
  }
  return 0;
    8000179c:	4501                	li	a0,0
    8000179e:	a021                	j	800017a6 <copyout+0x74>
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

00000000800017be <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017be:	caa5                	beqz	a3,8000182e <copyin+0x70>
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
    800017d4:	e062                	sd	s8,0(sp)
    800017d6:	0880                	addi	s0,sp,80
    800017d8:	8b2a                	mv	s6,a0
    800017da:	8a2e                	mv	s4,a1
    800017dc:	8c32                	mv	s8,a2
    800017de:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017e0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e2:	6a85                	lui	s5,0x1
    800017e4:	a01d                	j	8000180a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e6:	018505b3          	add	a1,a0,s8
    800017ea:	0004861b          	sext.w	a2,s1
    800017ee:	412585b3          	sub	a1,a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	fffff097          	auipc	ra,0xfffff
    800017f8:	580080e7          	jalr	1408(ra) # 80000d74 <memmove>

    len -= n;
    800017fc:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001800:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001802:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001806:	02098263          	beqz	s3,8000182a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000180a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000180e:	85ca                	mv	a1,s2
    80001810:	855a                	mv	a0,s6
    80001812:	00000097          	auipc	ra,0x0
    80001816:	894080e7          	jalr	-1900(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000181a:	cd01                	beqz	a0,80001832 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000181c:	418904b3          	sub	s1,s2,s8
    80001820:	94d6                	add	s1,s1,s5
    80001822:	fc99f2e3          	bgeu	s3,s1,800017e6 <copyin+0x28>
    80001826:	84ce                	mv	s1,s3
    80001828:	bf7d                	j	800017e6 <copyin+0x28>
  }
  return 0;
    8000182a:	4501                	li	a0,0
    8000182c:	a021                	j	80001834 <copyin+0x76>
    8000182e:	4501                	li	a0,0
}
    80001830:	8082                	ret
      return -1;
    80001832:	557d                	li	a0,-1
}
    80001834:	60a6                	ld	ra,72(sp)
    80001836:	6406                	ld	s0,64(sp)
    80001838:	74e2                	ld	s1,56(sp)
    8000183a:	7942                	ld	s2,48(sp)
    8000183c:	79a2                	ld	s3,40(sp)
    8000183e:	7a02                	ld	s4,32(sp)
    80001840:	6ae2                	ld	s5,24(sp)
    80001842:	6b42                	ld	s6,16(sp)
    80001844:	6ba2                	ld	s7,8(sp)
    80001846:	6c02                	ld	s8,0(sp)
    80001848:	6161                	addi	sp,sp,80
    8000184a:	8082                	ret

000000008000184c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000184c:	c2dd                	beqz	a3,800018f2 <copyinstr+0xa6>
{
    8000184e:	715d                	addi	sp,sp,-80
    80001850:	e486                	sd	ra,72(sp)
    80001852:	e0a2                	sd	s0,64(sp)
    80001854:	fc26                	sd	s1,56(sp)
    80001856:	f84a                	sd	s2,48(sp)
    80001858:	f44e                	sd	s3,40(sp)
    8000185a:	f052                	sd	s4,32(sp)
    8000185c:	ec56                	sd	s5,24(sp)
    8000185e:	e85a                	sd	s6,16(sp)
    80001860:	e45e                	sd	s7,8(sp)
    80001862:	0880                	addi	s0,sp,80
    80001864:	8a2a                	mv	s4,a0
    80001866:	8b2e                	mv	s6,a1
    80001868:	8bb2                	mv	s7,a2
    8000186a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000186c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186e:	6985                	lui	s3,0x1
    80001870:	a02d                	j	8000189a <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001872:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001876:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001878:	37fd                	addiw	a5,a5,-1
    8000187a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000187e:	60a6                	ld	ra,72(sp)
    80001880:	6406                	ld	s0,64(sp)
    80001882:	74e2                	ld	s1,56(sp)
    80001884:	7942                	ld	s2,48(sp)
    80001886:	79a2                	ld	s3,40(sp)
    80001888:	7a02                	ld	s4,32(sp)
    8000188a:	6ae2                	ld	s5,24(sp)
    8000188c:	6b42                	ld	s6,16(sp)
    8000188e:	6ba2                	ld	s7,8(sp)
    80001890:	6161                	addi	sp,sp,80
    80001892:	8082                	ret
    srcva = va0 + PGSIZE;
    80001894:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001898:	c8a9                	beqz	s1,800018ea <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000189a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000189e:	85ca                	mv	a1,s2
    800018a0:	8552                	mv	a0,s4
    800018a2:	00000097          	auipc	ra,0x0
    800018a6:	804080e7          	jalr	-2044(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    800018aa:	c131                	beqz	a0,800018ee <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800018ac:	417906b3          	sub	a3,s2,s7
    800018b0:	96ce                	add	a3,a3,s3
    800018b2:	00d4f363          	bgeu	s1,a3,800018b8 <copyinstr+0x6c>
    800018b6:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018b8:	955e                	add	a0,a0,s7
    800018ba:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018be:	daf9                	beqz	a3,80001894 <copyinstr+0x48>
    800018c0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018c2:	41650633          	sub	a2,a0,s6
    800018c6:	fff48593          	addi	a1,s1,-1
    800018ca:	95da                	add	a1,a1,s6
    while(n > 0){
    800018cc:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800018ce:	00f60733          	add	a4,a2,a5
    800018d2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffc9000>
    800018d6:	df51                	beqz	a4,80001872 <copyinstr+0x26>
        *dst = *p;
    800018d8:	00e78023          	sb	a4,0(a5)
      --max;
    800018dc:	40f584b3          	sub	s1,a1,a5
      dst++;
    800018e0:	0785                	addi	a5,a5,1
    while(n > 0){
    800018e2:	fed796e3          	bne	a5,a3,800018ce <copyinstr+0x82>
      dst++;
    800018e6:	8b3e                	mv	s6,a5
    800018e8:	b775                	j	80001894 <copyinstr+0x48>
    800018ea:	4781                	li	a5,0
    800018ec:	b771                	j	80001878 <copyinstr+0x2c>
      return -1;
    800018ee:	557d                	li	a0,-1
    800018f0:	b779                	j	8000187e <copyinstr+0x32>
  int got_null = 0;
    800018f2:	4781                	li	a5,0
  if(got_null){
    800018f4:	37fd                	addiw	a5,a5,-1
    800018f6:	0007851b          	sext.w	a0,a5
}
    800018fa:	8082                	ret

00000000800018fc <mapvpages>:
// HW5 - Task 1a
// Allocate page table pages for PTEs if needed but leave valid bits unchanged
int
mapvpages(pagetable_t pagetable, uint64 va, uint64 size)
{
    800018fc:	7179                	addi	sp,sp,-48
    800018fe:	f406                	sd	ra,40(sp)
    80001900:	f022                	sd	s0,32(sp)
    80001902:	ec26                	sd	s1,24(sp)
    80001904:	e84a                	sd	s2,16(sp)
    80001906:	e44e                	sd	s3,8(sp)
    80001908:	e052                	sd	s4,0(sp)
    8000190a:	1800                	addi	s0,sp,48
  uint64 a, last;
  pte_t *pte;
  if(size == 0)
    8000190c:	ca15                	beqz	a2,80001940 <mapvpages+0x44>
    8000190e:	89aa                	mv	s3,a0
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001910:	77fd                	lui	a5,0xfffff
    80001912:	00f5f4b3          	and	s1,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001916:	fff58913          	addi	s2,a1,-1
    8000191a:	9932                	add	s2,s2,a2
    8000191c:	00f97933          	and	s2,s2,a5
      return -1;
    if(*pte & PTE_V)
      panic("mappages: remap");
    if(a == last)
      break;
    a += PGSIZE;
    80001920:	6a05                	lui	s4,0x1
    if((pte = walk(pagetable, a, 1)) == 0)
    80001922:	4605                	li	a2,1
    80001924:	85a6                	mv	a1,s1
    80001926:	854e                	mv	a0,s3
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	6d8080e7          	jalr	1752(ra) # 80001000 <walk>
    80001930:	c905                	beqz	a0,80001960 <mapvpages+0x64>
    if(*pte & PTE_V)
    80001932:	611c                	ld	a5,0(a0)
    80001934:	8b85                	andi	a5,a5,1
    80001936:	ef89                	bnez	a5,80001950 <mapvpages+0x54>
    if(a == last)
    80001938:	03248d63          	beq	s1,s2,80001972 <mapvpages+0x76>
    a += PGSIZE;
    8000193c:	94d2                	add	s1,s1,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000193e:	b7d5                	j	80001922 <mapvpages+0x26>
    panic("mappages: size");
    80001940:	00006517          	auipc	a0,0x6
    80001944:	79850513          	addi	a0,a0,1944 # 800080d8 <digits+0x98>
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	bf4080e7          	jalr	-1036(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001950:	00006517          	auipc	a0,0x6
    80001954:	79850513          	addi	a0,a0,1944 # 800080e8 <digits+0xa8>
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	be4080e7          	jalr	-1052(ra) # 8000053c <panic>
      return -1;
    80001960:	557d                	li	a0,-1
  }
  return 0;
    80001962:	70a2                	ld	ra,40(sp)
    80001964:	7402                	ld	s0,32(sp)
    80001966:	64e2                	ld	s1,24(sp)
    80001968:	6942                	ld	s2,16(sp)
    8000196a:	69a2                	ld	s3,8(sp)
    8000196c:	6a02                	ld	s4,0(sp)
    8000196e:	6145                	addi	sp,sp,48
    80001970:	8082                	ret
  return 0;
    80001972:	4501                	li	a0,0
    80001974:	b7fd                	j	80001962 <mapvpages+0x66>

0000000080001976 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001976:	7139                	addi	sp,sp,-64
    80001978:	fc06                	sd	ra,56(sp)
    8000197a:	f822                	sd	s0,48(sp)
    8000197c:	f426                	sd	s1,40(sp)
    8000197e:	f04a                	sd	s2,32(sp)
    80001980:	ec4e                	sd	s3,24(sp)
    80001982:	e852                	sd	s4,16(sp)
    80001984:	e456                	sd	s5,8(sp)
    80001986:	e05a                	sd	s6,0(sp)
    80001988:	0080                	addi	s0,sp,64
    8000198a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198c:	00010497          	auipc	s1,0x10
    80001990:	d5c48493          	addi	s1,s1,-676 # 800116e8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001994:	8b26                	mv	s6,s1
    80001996:	00006a97          	auipc	s5,0x6
    8000199a:	66aa8a93          	addi	s5,s5,1642 # 80008000 <etext>
    8000199e:	04000937          	lui	s2,0x4000
    800019a2:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a6:	00021a17          	auipc	s4,0x21
    800019aa:	d42a0a13          	addi	s4,s4,-702 # 800226e8 <mmr_list>
    char *pa = kalloc();
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	134080e7          	jalr	308(ra) # 80000ae2 <kalloc>
    800019b6:	862a                	mv	a2,a0
    if(pa == 0)
    800019b8:	c131                	beqz	a0,800019fc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019ba:	416485b3          	sub	a1,s1,s6
    800019be:	8599                	srai	a1,a1,0x6
    800019c0:	000ab783          	ld	a5,0(s5)
    800019c4:	02f585b3          	mul	a1,a1,a5
    800019c8:	2585                	addiw	a1,a1,1
    800019ca:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ce:	4719                	li	a4,6
    800019d0:	6685                	lui	a3,0x1
    800019d2:	40b905b3          	sub	a1,s2,a1
    800019d6:	854e                	mv	a0,s3
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	7b0080e7          	jalr	1968(ra) # 80001188 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e0:	44048493          	addi	s1,s1,1088
    800019e4:	fd4495e3          	bne	s1,s4,800019ae <proc_mapstacks+0x38>
  }
}
    800019e8:	70e2                	ld	ra,56(sp)
    800019ea:	7442                	ld	s0,48(sp)
    800019ec:	74a2                	ld	s1,40(sp)
    800019ee:	7902                	ld	s2,32(sp)
    800019f0:	69e2                	ld	s3,24(sp)
    800019f2:	6a42                	ld	s4,16(sp)
    800019f4:	6aa2                	ld	s5,8(sp)
    800019f6:	6b02                	ld	s6,0(sp)
    800019f8:	6121                	addi	sp,sp,64
    800019fa:	8082                	ret
      panic("kalloc");
    800019fc:	00006517          	auipc	a0,0x6
    80001a00:	7b450513          	addi	a0,a0,1972 # 800081b0 <digits+0x170>
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	b38080e7          	jalr	-1224(ra) # 8000053c <panic>

0000000080001a0c <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a0c:	7139                	addi	sp,sp,-64
    80001a0e:	fc06                	sd	ra,56(sp)
    80001a10:	f822                	sd	s0,48(sp)
    80001a12:	f426                	sd	s1,40(sp)
    80001a14:	f04a                	sd	s2,32(sp)
    80001a16:	ec4e                	sd	s3,24(sp)
    80001a18:	e852                	sd	s4,16(sp)
    80001a1a:	e456                	sd	s5,8(sp)
    80001a1c:	e05a                	sd	s6,0(sp)
    80001a1e:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a20:	00006597          	auipc	a1,0x6
    80001a24:	79858593          	addi	a1,a1,1944 # 800081b8 <digits+0x178>
    80001a28:	00010517          	auipc	a0,0x10
    80001a2c:	87850513          	addi	a0,a0,-1928 # 800112a0 <pid_lock>
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	15c080e7          	jalr	348(ra) # 80000b8c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a38:	00006597          	auipc	a1,0x6
    80001a3c:	78858593          	addi	a1,a1,1928 # 800081c0 <digits+0x180>
    80001a40:	00010517          	auipc	a0,0x10
    80001a44:	87850513          	addi	a0,a0,-1928 # 800112b8 <wait_lock>
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	144080e7          	jalr	324(ra) # 80000b8c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a50:	00010497          	auipc	s1,0x10
    80001a54:	c9848493          	addi	s1,s1,-872 # 800116e8 <proc>
      initlock(&p->lock, "proc");
    80001a58:	00006b17          	auipc	s6,0x6
    80001a5c:	778b0b13          	addi	s6,s6,1912 # 800081d0 <digits+0x190>
      p->kstack = KSTACK((int) (p - proc));
    80001a60:	8aa6                	mv	s5,s1
    80001a62:	00006a17          	auipc	s4,0x6
    80001a66:	59ea0a13          	addi	s4,s4,1438 # 80008000 <etext>
    80001a6a:	04000937          	lui	s2,0x4000
    80001a6e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a70:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a72:	00021997          	auipc	s3,0x21
    80001a76:	c7698993          	addi	s3,s3,-906 # 800226e8 <mmr_list>
      initlock(&p->lock, "proc");
    80001a7a:	85da                	mv	a1,s6
    80001a7c:	2d848513          	addi	a0,s1,728
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	10c080e7          	jalr	268(ra) # 80000b8c <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a88:	415487b3          	sub	a5,s1,s5
    80001a8c:	8799                	srai	a5,a5,0x6
    80001a8e:	000a3703          	ld	a4,0(s4)
    80001a92:	02e787b3          	mul	a5,a5,a4
    80001a96:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffc9001>
    80001a98:	00d7979b          	slliw	a5,a5,0xd
    80001a9c:	40f907b3          	sub	a5,s2,a5
    80001aa0:	30f4bc23          	sd	a5,792(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa4:	44048493          	addi	s1,s1,1088
    80001aa8:	fd3499e3          	bne	s1,s3,80001a7a <procinit+0x6e>
  }
}
    80001aac:	70e2                	ld	ra,56(sp)
    80001aae:	7442                	ld	s0,48(sp)
    80001ab0:	74a2                	ld	s1,40(sp)
    80001ab2:	7902                	ld	s2,32(sp)
    80001ab4:	69e2                	ld	s3,24(sp)
    80001ab6:	6a42                	ld	s4,16(sp)
    80001ab8:	6aa2                	ld	s5,8(sp)
    80001aba:	6b02                	ld	s6,0(sp)
    80001abc:	6121                	addi	sp,sp,64
    80001abe:	8082                	ret

0000000080001ac0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ac0:	1141                	addi	sp,sp,-16
    80001ac2:	e422                	sd	s0,8(sp)
    80001ac4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ac6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ac8:	2501                	sext.w	a0,a0
    80001aca:	6422                	ld	s0,8(sp)
    80001acc:	0141                	addi	sp,sp,16
    80001ace:	8082                	ret

0000000080001ad0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ad0:	1141                	addi	sp,sp,-16
    80001ad2:	e422                	sd	s0,8(sp)
    80001ad4:	0800                	addi	s0,sp,16
    80001ad6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ad8:	2781                	sext.w	a5,a5
    80001ada:	079e                	slli	a5,a5,0x7
  return c;
}
    80001adc:	0000f517          	auipc	a0,0xf
    80001ae0:	7f450513          	addi	a0,a0,2036 # 800112d0 <cpus>
    80001ae4:	953e                	add	a0,a0,a5
    80001ae6:	6422                	ld	s0,8(sp)
    80001ae8:	0141                	addi	sp,sp,16
    80001aea:	8082                	ret

0000000080001aec <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001aec:	1101                	addi	sp,sp,-32
    80001aee:	ec06                	sd	ra,24(sp)
    80001af0:	e822                	sd	s0,16(sp)
    80001af2:	e426                	sd	s1,8(sp)
    80001af4:	1000                	addi	s0,sp,32
  push_off();
    80001af6:	fffff097          	auipc	ra,0xfffff
    80001afa:	0da080e7          	jalr	218(ra) # 80000bd0 <push_off>
    80001afe:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b00:	2781                	sext.w	a5,a5
    80001b02:	079e                	slli	a5,a5,0x7
    80001b04:	0000f717          	auipc	a4,0xf
    80001b08:	79c70713          	addi	a4,a4,1948 # 800112a0 <pid_lock>
    80001b0c:	97ba                	add	a5,a5,a4
    80001b0e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	160080e7          	jalr	352(ra) # 80000c70 <pop_off>
  return p;
}
    80001b18:	8526                	mv	a0,s1
    80001b1a:	60e2                	ld	ra,24(sp)
    80001b1c:	6442                	ld	s0,16(sp)
    80001b1e:	64a2                	ld	s1,8(sp)
    80001b20:	6105                	addi	sp,sp,32
    80001b22:	8082                	ret

0000000080001b24 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b24:	1141                	addi	sp,sp,-16
    80001b26:	e406                	sd	ra,8(sp)
    80001b28:	e022                	sd	s0,0(sp)
    80001b2a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b2c:	00000097          	auipc	ra,0x0
    80001b30:	fc0080e7          	jalr	-64(ra) # 80001aec <myproc>
    80001b34:	2d850513          	addi	a0,a0,728
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	198080e7          	jalr	408(ra) # 80000cd0 <release>

  if (first) {
    80001b40:	00007797          	auipc	a5,0x7
    80001b44:	d107a783          	lw	a5,-752(a5) # 80008850 <first.1>
    80001b48:	eb89                	bnez	a5,80001b5a <forkret+0x36>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b4a:	00001097          	auipc	ra,0x1
    80001b4e:	164080e7          	jalr	356(ra) # 80002cae <usertrapret>
}
    80001b52:	60a2                	ld	ra,8(sp)
    80001b54:	6402                	ld	s0,0(sp)
    80001b56:	0141                	addi	sp,sp,16
    80001b58:	8082                	ret
    first = 0;
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	ce07ab23          	sw	zero,-778(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001b62:	4505                	li	a0,1
    80001b64:	00002097          	auipc	ra,0x2
    80001b68:	03c080e7          	jalr	60(ra) # 80003ba0 <fsinit>
    80001b6c:	bff9                	j	80001b4a <forkret+0x26>

0000000080001b6e <allocpid>:
allocpid() {
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	e04a                	sd	s2,0(sp)
    80001b78:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b7a:	0000f917          	auipc	s2,0xf
    80001b7e:	72690913          	addi	s2,s2,1830 # 800112a0 <pid_lock>
    80001b82:	854a                	mv	a0,s2
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	098080e7          	jalr	152(ra) # 80000c1c <acquire>
  pid = nextpid;
    80001b8c:	00007797          	auipc	a5,0x7
    80001b90:	cc878793          	addi	a5,a5,-824 # 80008854 <nextpid>
    80001b94:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b96:	0014871b          	addiw	a4,s1,1
    80001b9a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b9c:	854a                	mv	a0,s2
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	132080e7          	jalr	306(ra) # 80000cd0 <release>
}
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <proc_pagetable>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	e04a                	sd	s2,0(sp)
    80001bbe:	1000                	addi	s0,sp,32
    80001bc0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	792080e7          	jalr	1938(ra) # 80001354 <uvmcreate>
    80001bca:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bcc:	c121                	beqz	a0,80001c0c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bce:	4729                	li	a4,10
    80001bd0:	00005697          	auipc	a3,0x5
    80001bd4:	43068693          	addi	a3,a3,1072 # 80007000 <_trampoline>
    80001bd8:	6605                	lui	a2,0x1
    80001bda:	040005b7          	lui	a1,0x4000
    80001bde:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001be0:	05b2                	slli	a1,a1,0xc
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	506080e7          	jalr	1286(ra) # 800010e8 <mappages>
    80001bea:	02054863          	bltz	a0,80001c1a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bee:	4719                	li	a4,6
    80001bf0:	33093683          	ld	a3,816(s2)
    80001bf4:	6605                	lui	a2,0x1
    80001bf6:	020005b7          	lui	a1,0x2000
    80001bfa:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bfc:	05b6                	slli	a1,a1,0xd
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	4e8080e7          	jalr	1256(ra) # 800010e8 <mappages>
    80001c08:	02054163          	bltz	a0,80001c2a <proc_pagetable+0x76>
}
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6902                	ld	s2,0(sp)
    80001c16:	6105                	addi	sp,sp,32
    80001c18:	8082                	ret
    uvmfree(pagetable, 0);
    80001c1a:	4581                	li	a1,0
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	934080e7          	jalr	-1740(ra) # 80001552 <uvmfree>
    return 0;
    80001c26:	4481                	li	s1,0
    80001c28:	b7d5                	j	80001c0c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2a:	4681                	li	a3,0
    80001c2c:	4605                	li	a2,1
    80001c2e:	040005b7          	lui	a1,0x4000
    80001c32:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c34:	05b2                	slli	a1,a1,0xc
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	676080e7          	jalr	1654(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c40:	4581                	li	a1,0
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	90e080e7          	jalr	-1778(ra) # 80001552 <uvmfree>
    return 0;
    80001c4c:	4481                	li	s1,0
    80001c4e:	bf7d                	j	80001c0c <proc_pagetable+0x58>

0000000080001c50 <proc_freepagetable>:
{
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	e04a                	sd	s2,0(sp)
    80001c5a:	1000                	addi	s0,sp,32
    80001c5c:	84aa                	mv	s1,a0
    80001c5e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c60:	4681                	li	a3,0
    80001c62:	4605                	li	a2,1
    80001c64:	040005b7          	lui	a1,0x4000
    80001c68:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c6a:	05b2                	slli	a1,a1,0xc
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	642080e7          	jalr	1602(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c74:	4681                	li	a3,0
    80001c76:	4605                	li	a2,1
    80001c78:	020005b7          	lui	a1,0x2000
    80001c7c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c7e:	05b6                	slli	a1,a1,0xd
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	62c080e7          	jalr	1580(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001c8a:	85ca                	mv	a1,s2
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	8c4080e7          	jalr	-1852(ra) # 80001552 <uvmfree>
}
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret

0000000080001ca2 <growproc>:
{
    80001ca2:	1101                	addi	sp,sp,-32
    80001ca4:	ec06                	sd	ra,24(sp)
    80001ca6:	e822                	sd	s0,16(sp)
    80001ca8:	e426                	sd	s1,8(sp)
    80001caa:	e04a                	sd	s2,0(sp)
    80001cac:	1000                	addi	s0,sp,32
    80001cae:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	e3c080e7          	jalr	-452(ra) # 80001aec <myproc>
    80001cb8:	892a                	mv	s2,a0
  sz = p->sz;
    80001cba:	32053583          	ld	a1,800(a0)
    80001cbe:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001cc2:	00904f63          	bgtz	s1,80001ce0 <growproc+0x3e>
  } else if(n < 0){
    80001cc6:	0204ce63          	bltz	s1,80001d02 <growproc+0x60>
  p->sz = sz;
    80001cca:	1782                	slli	a5,a5,0x20
    80001ccc:	9381                	srli	a5,a5,0x20
    80001cce:	32f93023          	sd	a5,800(s2)
  return 0;
    80001cd2:	4501                	li	a0,0
}
    80001cd4:	60e2                	ld	ra,24(sp)
    80001cd6:	6442                	ld	s0,16(sp)
    80001cd8:	64a2                	ld	s1,8(sp)
    80001cda:	6902                	ld	s2,0(sp)
    80001cdc:	6105                	addi	sp,sp,32
    80001cde:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ce0:	00f4863b          	addw	a2,s1,a5
    80001ce4:	1602                	slli	a2,a2,0x20
    80001ce6:	9201                	srli	a2,a2,0x20
    80001ce8:	1582                	slli	a1,a1,0x20
    80001cea:	9181                	srli	a1,a1,0x20
    80001cec:	32853503          	ld	a0,808(a0)
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	74c080e7          	jalr	1868(ra) # 8000143c <uvmalloc>
    80001cf8:	0005079b          	sext.w	a5,a0
    80001cfc:	f7f9                	bnez	a5,80001cca <growproc+0x28>
      return -1;
    80001cfe:	557d                	li	a0,-1
    80001d00:	bfd1                	j	80001cd4 <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d02:	00f4863b          	addw	a2,s1,a5
    80001d06:	1602                	slli	a2,a2,0x20
    80001d08:	9201                	srli	a2,a2,0x20
    80001d0a:	1582                	slli	a1,a1,0x20
    80001d0c:	9181                	srli	a1,a1,0x20
    80001d0e:	32853503          	ld	a0,808(a0)
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	6e2080e7          	jalr	1762(ra) # 800013f4 <uvmdealloc>
    80001d1a:	0005079b          	sext.w	a5,a0
    80001d1e:	b775                	j	80001cca <growproc+0x28>

0000000080001d20 <scheduler>:
{
    80001d20:	715d                	addi	sp,sp,-80
    80001d22:	e486                	sd	ra,72(sp)
    80001d24:	e0a2                	sd	s0,64(sp)
    80001d26:	fc26                	sd	s1,56(sp)
    80001d28:	f84a                	sd	s2,48(sp)
    80001d2a:	f44e                	sd	s3,40(sp)
    80001d2c:	f052                	sd	s4,32(sp)
    80001d2e:	ec56                	sd	s5,24(sp)
    80001d30:	e85a                	sd	s6,16(sp)
    80001d32:	e45e                	sd	s7,8(sp)
    80001d34:	0880                	addi	s0,sp,80
    80001d36:	8792                	mv	a5,tp
  int id = r_tp();
    80001d38:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d3a:	00779b13          	slli	s6,a5,0x7
    80001d3e:	0000f717          	auipc	a4,0xf
    80001d42:	56270713          	addi	a4,a4,1378 # 800112a0 <pid_lock>
    80001d46:	975a                	add	a4,a4,s6
    80001d48:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001d4c:	0000f717          	auipc	a4,0xf
    80001d50:	58c70713          	addi	a4,a4,1420 # 800112d8 <cpus+0x8>
    80001d54:	9b3a                	add	s6,s6,a4
      if(p->state == RUNNABLE) {
    80001d56:	4a0d                	li	s4,3
        p->state = RUNNING;
    80001d58:	4b91                	li	s7,4
        c->proc = p;
    80001d5a:	079e                	slli	a5,a5,0x7
    80001d5c:	0000fa97          	auipc	s5,0xf
    80001d60:	544a8a93          	addi	s5,s5,1348 # 800112a0 <pid_lock>
    80001d64:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d66:	00021997          	auipc	s3,0x21
    80001d6a:	98298993          	addi	s3,s3,-1662 # 800226e8 <mmr_list>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d6e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001d72:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d76:	10079073          	csrw	sstatus,a5
    80001d7a:	00010497          	auipc	s1,0x10
    80001d7e:	96e48493          	addi	s1,s1,-1682 # 800116e8 <proc>
    80001d82:	a811                	j	80001d96 <scheduler+0x76>
      release(&p->lock);
    80001d84:	854a                	mv	a0,s2
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	f4a080e7          	jalr	-182(ra) # 80000cd0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d8e:	44048493          	addi	s1,s1,1088
    80001d92:	fd348ee3          	beq	s1,s3,80001d6e <scheduler+0x4e>
      acquire(&p->lock);
    80001d96:	2d848913          	addi	s2,s1,728
    80001d9a:	854a                	mv	a0,s2
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	e80080e7          	jalr	-384(ra) # 80000c1c <acquire>
      if(p->state == RUNNABLE) {
    80001da4:	2f04a783          	lw	a5,752(s1)
    80001da8:	fd479ee3          	bne	a5,s4,80001d84 <scheduler+0x64>
        p->state = RUNNING;
    80001dac:	2f74a823          	sw	s7,752(s1)
        c->proc = p;
    80001db0:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001db4:	33848593          	addi	a1,s1,824
    80001db8:	855a                	mv	a0,s6
    80001dba:	00001097          	auipc	ra,0x1
    80001dbe:	e4a080e7          	jalr	-438(ra) # 80002c04 <swtch>
        c->proc = 0;
    80001dc2:	020ab823          	sd	zero,48(s5)
    80001dc6:	bf7d                	j	80001d84 <scheduler+0x64>

0000000080001dc8 <sched>:
{
    80001dc8:	7179                	addi	sp,sp,-48
    80001dca:	f406                	sd	ra,40(sp)
    80001dcc:	f022                	sd	s0,32(sp)
    80001dce:	ec26                	sd	s1,24(sp)
    80001dd0:	e84a                	sd	s2,16(sp)
    80001dd2:	e44e                	sd	s3,8(sp)
    80001dd4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	d16080e7          	jalr	-746(ra) # 80001aec <myproc>
    80001dde:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001de0:	2d850513          	addi	a0,a0,728
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	dbe080e7          	jalr	-578(ra) # 80000ba2 <holding>
    80001dec:	cd25                	beqz	a0,80001e64 <sched+0x9c>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dee:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001df0:	2781                	sext.w	a5,a5
    80001df2:	079e                	slli	a5,a5,0x7
    80001df4:	0000f717          	auipc	a4,0xf
    80001df8:	4ac70713          	addi	a4,a4,1196 # 800112a0 <pid_lock>
    80001dfc:	97ba                	add	a5,a5,a4
    80001dfe:	0a87a703          	lw	a4,168(a5)
    80001e02:	4785                	li	a5,1
    80001e04:	06f71863          	bne	a4,a5,80001e74 <sched+0xac>
  if(p->state == RUNNING)
    80001e08:	2f04a703          	lw	a4,752(s1)
    80001e0c:	4791                	li	a5,4
    80001e0e:	06f70b63          	beq	a4,a5,80001e84 <sched+0xbc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e16:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e18:	efb5                	bnez	a5,80001e94 <sched+0xcc>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e1a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e1c:	0000f917          	auipc	s2,0xf
    80001e20:	48490913          	addi	s2,s2,1156 # 800112a0 <pid_lock>
    80001e24:	2781                	sext.w	a5,a5
    80001e26:	079e                	slli	a5,a5,0x7
    80001e28:	97ca                	add	a5,a5,s2
    80001e2a:	0ac7a983          	lw	s3,172(a5)
    80001e2e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e30:	2781                	sext.w	a5,a5
    80001e32:	079e                	slli	a5,a5,0x7
    80001e34:	0000f597          	auipc	a1,0xf
    80001e38:	4a458593          	addi	a1,a1,1188 # 800112d8 <cpus+0x8>
    80001e3c:	95be                	add	a1,a1,a5
    80001e3e:	33848513          	addi	a0,s1,824
    80001e42:	00001097          	auipc	ra,0x1
    80001e46:	dc2080e7          	jalr	-574(ra) # 80002c04 <swtch>
    80001e4a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001e4c:	2781                	sext.w	a5,a5
    80001e4e:	079e                	slli	a5,a5,0x7
    80001e50:	993e                	add	s2,s2,a5
    80001e52:	0b392623          	sw	s3,172(s2)
}
    80001e56:	70a2                	ld	ra,40(sp)
    80001e58:	7402                	ld	s0,32(sp)
    80001e5a:	64e2                	ld	s1,24(sp)
    80001e5c:	6942                	ld	s2,16(sp)
    80001e5e:	69a2                	ld	s3,8(sp)
    80001e60:	6145                	addi	sp,sp,48
    80001e62:	8082                	ret
    panic("sched p->lock");
    80001e64:	00006517          	auipc	a0,0x6
    80001e68:	37450513          	addi	a0,a0,884 # 800081d8 <digits+0x198>
    80001e6c:	ffffe097          	auipc	ra,0xffffe
    80001e70:	6d0080e7          	jalr	1744(ra) # 8000053c <panic>
    panic("sched locks");
    80001e74:	00006517          	auipc	a0,0x6
    80001e78:	37450513          	addi	a0,a0,884 # 800081e8 <digits+0x1a8>
    80001e7c:	ffffe097          	auipc	ra,0xffffe
    80001e80:	6c0080e7          	jalr	1728(ra) # 8000053c <panic>
    panic("sched running");
    80001e84:	00006517          	auipc	a0,0x6
    80001e88:	37450513          	addi	a0,a0,884 # 800081f8 <digits+0x1b8>
    80001e8c:	ffffe097          	auipc	ra,0xffffe
    80001e90:	6b0080e7          	jalr	1712(ra) # 8000053c <panic>
    panic("sched interruptible");
    80001e94:	00006517          	auipc	a0,0x6
    80001e98:	37450513          	addi	a0,a0,884 # 80008208 <digits+0x1c8>
    80001e9c:	ffffe097          	auipc	ra,0xffffe
    80001ea0:	6a0080e7          	jalr	1696(ra) # 8000053c <panic>

0000000080001ea4 <yield>:
{
    80001ea4:	1101                	addi	sp,sp,-32
    80001ea6:	ec06                	sd	ra,24(sp)
    80001ea8:	e822                	sd	s0,16(sp)
    80001eaa:	e426                	sd	s1,8(sp)
    80001eac:	e04a                	sd	s2,0(sp)
    80001eae:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	c3c080e7          	jalr	-964(ra) # 80001aec <myproc>
    80001eb8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001eba:	2d850913          	addi	s2,a0,728
    80001ebe:	854a                	mv	a0,s2
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	d5c080e7          	jalr	-676(ra) # 80000c1c <acquire>
  p->state = RUNNABLE;
    80001ec8:	478d                	li	a5,3
    80001eca:	2ef4a823          	sw	a5,752(s1)
  sched();
    80001ece:	00000097          	auipc	ra,0x0
    80001ed2:	efa080e7          	jalr	-262(ra) # 80001dc8 <sched>
  release(&p->lock);
    80001ed6:	854a                	mv	a0,s2
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	df8080e7          	jalr	-520(ra) # 80000cd0 <release>
}
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6902                	ld	s2,0(sp)
    80001ee8:	6105                	addi	sp,sp,32
    80001eea:	8082                	ret

0000000080001eec <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001eec:	7179                	addi	sp,sp,-48
    80001eee:	f406                	sd	ra,40(sp)
    80001ef0:	f022                	sd	s0,32(sp)
    80001ef2:	ec26                	sd	s1,24(sp)
    80001ef4:	e84a                	sd	s2,16(sp)
    80001ef6:	e44e                	sd	s3,8(sp)
    80001ef8:	e052                	sd	s4,0(sp)
    80001efa:	1800                	addi	s0,sp,48
    80001efc:	89aa                	mv	s3,a0
    80001efe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f00:	00000097          	auipc	ra,0x0
    80001f04:	bec080e7          	jalr	-1044(ra) # 80001aec <myproc>
    80001f08:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001f0a:	2d850a13          	addi	s4,a0,728
    80001f0e:	8552                	mv	a0,s4
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	d0c080e7          	jalr	-756(ra) # 80000c1c <acquire>
  release(lk);
    80001f18:	854a                	mv	a0,s2
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	db6080e7          	jalr	-586(ra) # 80000cd0 <release>

  // Go to sleep.
  p->chan = chan;
    80001f22:	2f34bc23          	sd	s3,760(s1)
  p->state = SLEEPING;
    80001f26:	4789                	li	a5,2
    80001f28:	2ef4a823          	sw	a5,752(s1)

  sched();
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	e9c080e7          	jalr	-356(ra) # 80001dc8 <sched>

  // Tidy up.
  p->chan = 0;
    80001f34:	2e04bc23          	sd	zero,760(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f38:	8552                	mv	a0,s4
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d96080e7          	jalr	-618(ra) # 80000cd0 <release>
  acquire(lk);
    80001f42:	854a                	mv	a0,s2
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	cd8080e7          	jalr	-808(ra) # 80000c1c <acquire>
}
    80001f4c:	70a2                	ld	ra,40(sp)
    80001f4e:	7402                	ld	s0,32(sp)
    80001f50:	64e2                	ld	s1,24(sp)
    80001f52:	6942                	ld	s2,16(sp)
    80001f54:	69a2                	ld	s3,8(sp)
    80001f56:	6a02                	ld	s4,0(sp)
    80001f58:	6145                	addi	sp,sp,48
    80001f5a:	8082                	ret

0000000080001f5c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80001f5c:	7139                	addi	sp,sp,-64
    80001f5e:	fc06                	sd	ra,56(sp)
    80001f60:	f822                	sd	s0,48(sp)
    80001f62:	f426                	sd	s1,40(sp)
    80001f64:	f04a                	sd	s2,32(sp)
    80001f66:	ec4e                	sd	s3,24(sp)
    80001f68:	e852                	sd	s4,16(sp)
    80001f6a:	e456                	sd	s5,8(sp)
    80001f6c:	e05a                	sd	s6,0(sp)
    80001f6e:	0080                	addi	s0,sp,64
    80001f70:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f72:	0000f497          	auipc	s1,0xf
    80001f76:	77648493          	addi	s1,s1,1910 # 800116e8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001f7a:	4a09                	li	s4,2
        p->state = RUNNABLE;
    80001f7c:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f7e:	00020997          	auipc	s3,0x20
    80001f82:	76a98993          	addi	s3,s3,1898 # 800226e8 <mmr_list>
    80001f86:	a811                	j	80001f9a <wakeup+0x3e>
      }
      release(&p->lock);
    80001f88:	854a                	mv	a0,s2
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	d46080e7          	jalr	-698(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f92:	44048493          	addi	s1,s1,1088
    80001f96:	03348a63          	beq	s1,s3,80001fca <wakeup+0x6e>
    if(p != myproc()){
    80001f9a:	00000097          	auipc	ra,0x0
    80001f9e:	b52080e7          	jalr	-1198(ra) # 80001aec <myproc>
    80001fa2:	fea488e3          	beq	s1,a0,80001f92 <wakeup+0x36>
      acquire(&p->lock);
    80001fa6:	2d848913          	addi	s2,s1,728
    80001faa:	854a                	mv	a0,s2
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	c70080e7          	jalr	-912(ra) # 80000c1c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001fb4:	2f04a783          	lw	a5,752(s1)
    80001fb8:	fd4798e3          	bne	a5,s4,80001f88 <wakeup+0x2c>
    80001fbc:	2f84b783          	ld	a5,760(s1)
    80001fc0:	fd5794e3          	bne	a5,s5,80001f88 <wakeup+0x2c>
        p->state = RUNNABLE;
    80001fc4:	2f64a823          	sw	s6,752(s1)
    80001fc8:	b7c1                	j	80001f88 <wakeup+0x2c>
    }
  }
}
    80001fca:	70e2                	ld	ra,56(sp)
    80001fcc:	7442                	ld	s0,48(sp)
    80001fce:	74a2                	ld	s1,40(sp)
    80001fd0:	7902                	ld	s2,32(sp)
    80001fd2:	69e2                	ld	s3,24(sp)
    80001fd4:	6a42                	ld	s4,16(sp)
    80001fd6:	6aa2                	ld	s5,8(sp)
    80001fd8:	6b02                	ld	s6,0(sp)
    80001fda:	6121                	addi	sp,sp,64
    80001fdc:	8082                	ret

0000000080001fde <reparent>:
{
    80001fde:	7179                	addi	sp,sp,-48
    80001fe0:	f406                	sd	ra,40(sp)
    80001fe2:	f022                	sd	s0,32(sp)
    80001fe4:	ec26                	sd	s1,24(sp)
    80001fe6:	e84a                	sd	s2,16(sp)
    80001fe8:	e44e                	sd	s3,8(sp)
    80001fea:	e052                	sd	s4,0(sp)
    80001fec:	1800                	addi	s0,sp,48
    80001fee:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ff0:	0000f497          	auipc	s1,0xf
    80001ff4:	6f848493          	addi	s1,s1,1784 # 800116e8 <proc>
      pp->parent = initproc;
    80001ff8:	00007a17          	auipc	s4,0x7
    80001ffc:	030a0a13          	addi	s4,s4,48 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002000:	00020997          	auipc	s3,0x20
    80002004:	6e898993          	addi	s3,s3,1768 # 800226e8 <mmr_list>
    80002008:	a029                	j	80002012 <reparent+0x34>
    8000200a:	44048493          	addi	s1,s1,1088
    8000200e:	01348f63          	beq	s1,s3,8000202c <reparent+0x4e>
    if(pp->parent == p){
    80002012:	3104b783          	ld	a5,784(s1)
    80002016:	ff279ae3          	bne	a5,s2,8000200a <reparent+0x2c>
      pp->parent = initproc;
    8000201a:	000a3503          	ld	a0,0(s4)
    8000201e:	30a4b823          	sd	a0,784(s1)
      wakeup(initproc);
    80002022:	00000097          	auipc	ra,0x0
    80002026:	f3a080e7          	jalr	-198(ra) # 80001f5c <wakeup>
    8000202a:	b7c5                	j	8000200a <reparent+0x2c>
}
    8000202c:	70a2                	ld	ra,40(sp)
    8000202e:	7402                	ld	s0,32(sp)
    80002030:	64e2                	ld	s1,24(sp)
    80002032:	6942                	ld	s2,16(sp)
    80002034:	69a2                	ld	s3,8(sp)
    80002036:	6a02                	ld	s4,0(sp)
    80002038:	6145                	addi	sp,sp,48
    8000203a:	8082                	ret

000000008000203c <exit>:
{
    8000203c:	7179                	addi	sp,sp,-48
    8000203e:	f406                	sd	ra,40(sp)
    80002040:	f022                	sd	s0,32(sp)
    80002042:	ec26                	sd	s1,24(sp)
    80002044:	e84a                	sd	s2,16(sp)
    80002046:	e44e                	sd	s3,8(sp)
    80002048:	e052                	sd	s4,0(sp)
    8000204a:	1800                	addi	s0,sp,48
    8000204c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	a9e080e7          	jalr	-1378(ra) # 80001aec <myproc>
    80002056:	89aa                	mv	s3,a0
  if(p == initproc)
    80002058:	00007797          	auipc	a5,0x7
    8000205c:	fd07b783          	ld	a5,-48(a5) # 80009028 <initproc>
    80002060:	3a850493          	addi	s1,a0,936
    80002064:	42850913          	addi	s2,a0,1064
    80002068:	02a79363          	bne	a5,a0,8000208e <exit+0x52>
    panic("init exiting");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	1b450513          	addi	a0,a0,436 # 80008220 <digits+0x1e0>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4c8080e7          	jalr	1224(ra) # 8000053c <panic>
      fileclose(f);
    8000207c:	00003097          	auipc	ra,0x3
    80002080:	c46080e7          	jalr	-954(ra) # 80004cc2 <fileclose>
      p->ofile[fd] = 0;
    80002084:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002088:	04a1                	addi	s1,s1,8
    8000208a:	01248563          	beq	s1,s2,80002094 <exit+0x58>
    if(p->ofile[fd]){
    8000208e:	6088                	ld	a0,0(s1)
    80002090:	f575                	bnez	a0,8000207c <exit+0x40>
    80002092:	bfdd                	j	80002088 <exit+0x4c>
  begin_op();
    80002094:	00002097          	auipc	ra,0x2
    80002098:	762080e7          	jalr	1890(ra) # 800047f6 <begin_op>
  iput(p->cwd);
    8000209c:	4289b503          	ld	a0,1064(s3)
    800020a0:	00002097          	auipc	ra,0x2
    800020a4:	f34080e7          	jalr	-204(ra) # 80003fd4 <iput>
  end_op();
    800020a8:	00002097          	auipc	ra,0x2
    800020ac:	7cc080e7          	jalr	1996(ra) # 80004874 <end_op>
  p->cwd = 0;
    800020b0:	4209b423          	sd	zero,1064(s3)
  acquire(&wait_lock);
    800020b4:	0000f497          	auipc	s1,0xf
    800020b8:	20448493          	addi	s1,s1,516 # 800112b8 <wait_lock>
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b5e080e7          	jalr	-1186(ra) # 80000c1c <acquire>
  reparent(p);
    800020c6:	854e                	mv	a0,s3
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	f16080e7          	jalr	-234(ra) # 80001fde <reparent>
  wakeup(p->parent);
    800020d0:	3109b503          	ld	a0,784(s3)
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	e88080e7          	jalr	-376(ra) # 80001f5c <wakeup>
  acquire(&p->lock);
    800020dc:	2d898513          	addi	a0,s3,728
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	b3c080e7          	jalr	-1220(ra) # 80000c1c <acquire>
  p->xstate = status;
    800020e8:	3149a223          	sw	s4,772(s3)
  p->state = ZOMBIE;
    800020ec:	4795                	li	a5,5
    800020ee:	2ef9a823          	sw	a5,752(s3)
  release(&wait_lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	bdc080e7          	jalr	-1060(ra) # 80000cd0 <release>
  sched();
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	ccc080e7          	jalr	-820(ra) # 80001dc8 <sched>
  panic("zombie exit");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	12c50513          	addi	a0,a0,300 # 80008230 <digits+0x1f0>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	430080e7          	jalr	1072(ra) # 8000053c <panic>

0000000080002114 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002114:	7179                	addi	sp,sp,-48
    80002116:	f406                	sd	ra,40(sp)
    80002118:	f022                	sd	s0,32(sp)
    8000211a:	ec26                	sd	s1,24(sp)
    8000211c:	e84a                	sd	s2,16(sp)
    8000211e:	e44e                	sd	s3,8(sp)
    80002120:	e052                	sd	s4,0(sp)
    80002122:	1800                	addi	s0,sp,48
    80002124:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002126:	0000f497          	auipc	s1,0xf
    8000212a:	5c248493          	addi	s1,s1,1474 # 800116e8 <proc>
    8000212e:	00020a17          	auipc	s4,0x20
    80002132:	5baa0a13          	addi	s4,s4,1466 # 800226e8 <mmr_list>
    acquire(&p->lock);
    80002136:	2d848913          	addi	s2,s1,728
    8000213a:	854a                	mv	a0,s2
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	ae0080e7          	jalr	-1312(ra) # 80000c1c <acquire>
    if(p->pid == pid){
    80002144:	3084a783          	lw	a5,776(s1)
    80002148:	01378d63          	beq	a5,s3,80002162 <kill+0x4e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000214c:	854a                	mv	a0,s2
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	b82080e7          	jalr	-1150(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002156:	44048493          	addi	s1,s1,1088
    8000215a:	fd449ee3          	bne	s1,s4,80002136 <kill+0x22>
  }
  return -1;
    8000215e:	557d                	li	a0,-1
    80002160:	a839                	j	8000217e <kill+0x6a>
      p->killed = 1;
    80002162:	4785                	li	a5,1
    80002164:	30f4a023          	sw	a5,768(s1)
      if(p->state == SLEEPING){
    80002168:	2f04a703          	lw	a4,752(s1)
    8000216c:	4789                	li	a5,2
    8000216e:	02f70063          	beq	a4,a5,8000218e <kill+0x7a>
      release(&p->lock);
    80002172:	854a                	mv	a0,s2
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	b5c080e7          	jalr	-1188(ra) # 80000cd0 <release>
      return 0;
    8000217c:	4501                	li	a0,0
}
    8000217e:	70a2                	ld	ra,40(sp)
    80002180:	7402                	ld	s0,32(sp)
    80002182:	64e2                	ld	s1,24(sp)
    80002184:	6942                	ld	s2,16(sp)
    80002186:	69a2                	ld	s3,8(sp)
    80002188:	6a02                	ld	s4,0(sp)
    8000218a:	6145                	addi	sp,sp,48
    8000218c:	8082                	ret
        p->state = RUNNABLE;
    8000218e:	478d                	li	a5,3
    80002190:	2ef4a823          	sw	a5,752(s1)
    80002194:	bff9                	j	80002172 <kill+0x5e>

0000000080002196 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002196:	7179                	addi	sp,sp,-48
    80002198:	f406                	sd	ra,40(sp)
    8000219a:	f022                	sd	s0,32(sp)
    8000219c:	ec26                	sd	s1,24(sp)
    8000219e:	e84a                	sd	s2,16(sp)
    800021a0:	e44e                	sd	s3,8(sp)
    800021a2:	e052                	sd	s4,0(sp)
    800021a4:	1800                	addi	s0,sp,48
    800021a6:	84aa                	mv	s1,a0
    800021a8:	892e                	mv	s2,a1
    800021aa:	89b2                	mv	s3,a2
    800021ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	93e080e7          	jalr	-1730(ra) # 80001aec <myproc>
  if(user_dst){
    800021b6:	c095                	beqz	s1,800021da <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    800021b8:	86d2                	mv	a3,s4
    800021ba:	864e                	mv	a2,s3
    800021bc:	85ca                	mv	a1,s2
    800021be:	32853503          	ld	a0,808(a0)
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	570080e7          	jalr	1392(ra) # 80001732 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800021ca:	70a2                	ld	ra,40(sp)
    800021cc:	7402                	ld	s0,32(sp)
    800021ce:	64e2                	ld	s1,24(sp)
    800021d0:	6942                	ld	s2,16(sp)
    800021d2:	69a2                	ld	s3,8(sp)
    800021d4:	6a02                	ld	s4,0(sp)
    800021d6:	6145                	addi	sp,sp,48
    800021d8:	8082                	ret
    memmove((char *)dst, src, len);
    800021da:	000a061b          	sext.w	a2,s4
    800021de:	85ce                	mv	a1,s3
    800021e0:	854a                	mv	a0,s2
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	b92080e7          	jalr	-1134(ra) # 80000d74 <memmove>
    return 0;
    800021ea:	8526                	mv	a0,s1
    800021ec:	bff9                	j	800021ca <either_copyout+0x34>

00000000800021ee <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800021ee:	7179                	addi	sp,sp,-48
    800021f0:	f406                	sd	ra,40(sp)
    800021f2:	f022                	sd	s0,32(sp)
    800021f4:	ec26                	sd	s1,24(sp)
    800021f6:	e84a                	sd	s2,16(sp)
    800021f8:	e44e                	sd	s3,8(sp)
    800021fa:	e052                	sd	s4,0(sp)
    800021fc:	1800                	addi	s0,sp,48
    800021fe:	892a                	mv	s2,a0
    80002200:	84ae                	mv	s1,a1
    80002202:	89b2                	mv	s3,a2
    80002204:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	8e6080e7          	jalr	-1818(ra) # 80001aec <myproc>
  if(user_src){
    8000220e:	c095                	beqz	s1,80002232 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    80002210:	86d2                	mv	a3,s4
    80002212:	864e                	mv	a2,s3
    80002214:	85ca                	mv	a1,s2
    80002216:	32853503          	ld	a0,808(a0)
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	5a4080e7          	jalr	1444(ra) # 800017be <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002222:	70a2                	ld	ra,40(sp)
    80002224:	7402                	ld	s0,32(sp)
    80002226:	64e2                	ld	s1,24(sp)
    80002228:	6942                	ld	s2,16(sp)
    8000222a:	69a2                	ld	s3,8(sp)
    8000222c:	6a02                	ld	s4,0(sp)
    8000222e:	6145                	addi	sp,sp,48
    80002230:	8082                	ret
    memmove(dst, (char*)src, len);
    80002232:	000a061b          	sext.w	a2,s4
    80002236:	85ce                	mv	a1,s3
    80002238:	854a                	mv	a0,s2
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	b3a080e7          	jalr	-1222(ra) # 80000d74 <memmove>
    return 0;
    80002242:	8526                	mv	a0,s1
    80002244:	bff9                	j	80002222 <either_copyin+0x34>

0000000080002246 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002246:	715d                	addi	sp,sp,-80
    80002248:	e486                	sd	ra,72(sp)
    8000224a:	e0a2                	sd	s0,64(sp)
    8000224c:	fc26                	sd	s1,56(sp)
    8000224e:	f84a                	sd	s2,48(sp)
    80002250:	f44e                	sd	s3,40(sp)
    80002252:	f052                	sd	s4,32(sp)
    80002254:	ec56                	sd	s5,24(sp)
    80002256:	e85a                	sd	s6,16(sp)
    80002258:	e45e                	sd	s7,8(sp)
    8000225a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000225c:	00006517          	auipc	a0,0x6
    80002260:	e6c50513          	addi	a0,a0,-404 # 800080c8 <digits+0x88>
    80002264:	ffffe097          	auipc	ra,0xffffe
    80002268:	322080e7          	jalr	802(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000226c:	00010497          	auipc	s1,0x10
    80002270:	8ac48493          	addi	s1,s1,-1876 # 80011b18 <proc+0x430>
    80002274:	00021917          	auipc	s2,0x21
    80002278:	8a490913          	addi	s2,s2,-1884 # 80022b18 <mmr_list+0x430>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000227c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000227e:	00006997          	auipc	s3,0x6
    80002282:	fc298993          	addi	s3,s3,-62 # 80008240 <digits+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    80002286:	00006a97          	auipc	s5,0x6
    8000228a:	fc2a8a93          	addi	s5,s5,-62 # 80008248 <digits+0x208>
    printf("\n");
    8000228e:	00006a17          	auipc	s4,0x6
    80002292:	e3aa0a13          	addi	s4,s4,-454 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002296:	00006b97          	auipc	s7,0x6
    8000229a:	012b8b93          	addi	s7,s7,18 # 800082a8 <states.0>
    8000229e:	a00d                	j	800022c0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800022a0:	ed86a583          	lw	a1,-296(a3)
    800022a4:	8556                	mv	a0,s5
    800022a6:	ffffe097          	auipc	ra,0xffffe
    800022aa:	2e0080e7          	jalr	736(ra) # 80000586 <printf>
    printf("\n");
    800022ae:	8552                	mv	a0,s4
    800022b0:	ffffe097          	auipc	ra,0xffffe
    800022b4:	2d6080e7          	jalr	726(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022b8:	44048493          	addi	s1,s1,1088
    800022bc:	03248263          	beq	s1,s2,800022e0 <procdump+0x9a>
    if(p->state == UNUSED)
    800022c0:	86a6                	mv	a3,s1
    800022c2:	ec04a783          	lw	a5,-320(s1)
    800022c6:	dbed                	beqz	a5,800022b8 <procdump+0x72>
      state = "???";
    800022c8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022ca:	fcfb6be3          	bltu	s6,a5,800022a0 <procdump+0x5a>
    800022ce:	02079713          	slli	a4,a5,0x20
    800022d2:	01d75793          	srli	a5,a4,0x1d
    800022d6:	97de                	add	a5,a5,s7
    800022d8:	6390                	ld	a2,0(a5)
    800022da:	f279                	bnez	a2,800022a0 <procdump+0x5a>
      state = "???";
    800022dc:	864e                	mv	a2,s3
    800022de:	b7c9                	j	800022a0 <procdump+0x5a>
  }
}
    800022e0:	60a6                	ld	ra,72(sp)
    800022e2:	6406                	ld	s0,64(sp)
    800022e4:	74e2                	ld	s1,56(sp)
    800022e6:	7942                	ld	s2,48(sp)
    800022e8:	79a2                	ld	s3,40(sp)
    800022ea:	7a02                	ld	s4,32(sp)
    800022ec:	6ae2                	ld	s5,24(sp)
    800022ee:	6b42                	ld	s6,16(sp)
    800022f0:	6ba2                	ld	s7,8(sp)
    800022f2:	6161                	addi	sp,sp,80
    800022f4:	8082                	ret

00000000800022f6 <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    800022f6:	7119                	addi	sp,sp,-128
    800022f8:	fc86                	sd	ra,120(sp)
    800022fa:	f8a2                	sd	s0,112(sp)
    800022fc:	f4a6                	sd	s1,104(sp)
    800022fe:	f0ca                	sd	s2,96(sp)
    80002300:	ecce                	sd	s3,88(sp)
    80002302:	e8d2                	sd	s4,80(sp)
    80002304:	e4d6                	sd	s5,72(sp)
    80002306:	e0da                	sd	s6,64(sp)
    80002308:	fc5e                	sd	s7,56(sp)
    8000230a:	0100                	addi	s0,sp,128
    8000230c:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	7de080e7          	jalr	2014(ra) # 80001aec <myproc>
    80002316:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002318:	00010917          	auipc	s2,0x10
    8000231c:	80090913          	addi	s2,s2,-2048 # 80011b18 <proc+0x430>
    80002320:	00020a17          	auipc	s4,0x20
    80002324:	7f8a0a13          	addi	s4,s4,2040 # 80022b18 <mmr_list+0x430>
  int nprocs = 0;
    80002328:	4a81                	li	s5,0
    procinfo.state = p->state;
    procinfo.size = p->sz;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    8000232a:	4b81                	li	s7,0
    8000232c:	fac40493          	addi	s1,s0,-84
    80002330:	a089                	j	80002372 <procinfo+0x7c>
    80002332:	f8f42c23          	sw	a5,-104(s0)
    for (int i=0; i<16; i++)
    80002336:	f9c40793          	addi	a5,s0,-100
      procinfo.ppid = 0;
    8000233a:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    8000233c:	00074683          	lbu	a3,0(a4)
    80002340:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    80002344:	0705                	addi	a4,a4,1
    80002346:	0785                	addi	a5,a5,1
    80002348:	fe979ae3          	bne	a5,s1,8000233c <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    8000234c:	02800693          	li	a3,40
    80002350:	f8840613          	addi	a2,s0,-120
    80002354:	85ce                	mv	a1,s3
    80002356:	328b3503          	ld	a0,808(s6)
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	3d8080e7          	jalr	984(ra) # 80001732 <copyout>
    80002362:	02054d63          	bltz	a0,8000239c <procinfo+0xa6>
      return -1;
    addr += sizeof(procinfo);
    80002366:	02898993          	addi	s3,s3,40
  for(p = proc; p < &proc[NPROC]; p++){ 
    8000236a:	44090913          	addi	s2,s2,1088
    8000236e:	03490863          	beq	s2,s4,8000239e <procinfo+0xa8>
    if(p->state == UNUSED)
    80002372:	ec092783          	lw	a5,-320(s2)
    80002376:	dbf5                	beqz	a5,8000236a <procinfo+0x74>
    nprocs++;
    80002378:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    8000237a:	ed892703          	lw	a4,-296(s2)
    8000237e:	f8e42423          	sw	a4,-120(s0)
    procinfo.state = p->state;
    80002382:	f8f42623          	sw	a5,-116(s0)
    procinfo.size = p->sz;
    80002386:	ef093783          	ld	a5,-272(s2)
    8000238a:	f8f43823          	sd	a5,-112(s0)
    if (p->parent)
    8000238e:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    80002392:	87de                	mv	a5,s7
    if (p->parent)
    80002394:	df59                	beqz	a4,80002332 <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    80002396:	30872783          	lw	a5,776(a4)
    8000239a:	bf61                	j	80002332 <procinfo+0x3c>
      return -1;
    8000239c:	5afd                	li	s5,-1
  }
  return nprocs;
}
    8000239e:	8556                	mv	a0,s5
    800023a0:	70e6                	ld	ra,120(sp)
    800023a2:	7446                	ld	s0,112(sp)
    800023a4:	74a6                	ld	s1,104(sp)
    800023a6:	7906                	ld	s2,96(sp)
    800023a8:	69e6                	ld	s3,88(sp)
    800023aa:	6a46                	ld	s4,80(sp)
    800023ac:	6aa6                	ld	s5,72(sp)
    800023ae:	6b06                	ld	s6,64(sp)
    800023b0:	7be2                	ld	s7,56(sp)
    800023b2:	6109                	addi	sp,sp,128
    800023b4:	8082                	ret

00000000800023b6 <mmrlistinit>:

// HW5 - Task 1a
// Initialize mmr_list
void
mmrlistinit(void)
{
    800023b6:	7179                	addi	sp,sp,-48
    800023b8:	f406                	sd	ra,40(sp)
    800023ba:	f022                	sd	s0,32(sp)
    800023bc:	ec26                	sd	s1,24(sp)
    800023be:	e84a                	sd	s2,16(sp)
    800023c0:	e44e                	sd	s3,8(sp)
    800023c2:	1800                	addi	s0,sp,48
  struct mmr_list *pmmrlist;
  initlock(&listid_lock,"listid");
    800023c4:	00006597          	auipc	a1,0x6
    800023c8:	e9458593          	addi	a1,a1,-364 # 80008258 <digits+0x218>
    800023cc:	0000f517          	auipc	a0,0xf
    800023d0:	30450513          	addi	a0,a0,772 # 800116d0 <listid_lock>
    800023d4:	ffffe097          	auipc	ra,0xffffe
    800023d8:	7b8080e7          	jalr	1976(ra) # 80000b8c <initlock>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    800023dc:	00020497          	auipc	s1,0x20
    800023e0:	30c48493          	addi	s1,s1,780 # 800226e8 <mmr_list>
    initlock(&pmmrlist->lock, "mmrlist");
    800023e4:	00006997          	auipc	s3,0x6
    800023e8:	e7c98993          	addi	s3,s3,-388 # 80008260 <digits+0x220>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    800023ec:	00025917          	auipc	s2,0x25
    800023f0:	2fc90913          	addi	s2,s2,764 # 800276e8 <tickslock>
    initlock(&pmmrlist->lock, "mmrlist");
    800023f4:	85ce                	mv	a1,s3
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	794080e7          	jalr	1940(ra) # 80000b8c <initlock>
    pmmrlist->valid = 0;
    80002400:	0004ac23          	sw	zero,24(s1)
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    80002404:	02048493          	addi	s1,s1,32
    80002408:	ff2496e3          	bne	s1,s2,800023f4 <mmrlistinit+0x3e>
  }
}
    8000240c:	70a2                	ld	ra,40(sp)
    8000240e:	7402                	ld	s0,32(sp)
    80002410:	64e2                	ld	s1,24(sp)
    80002412:	6942                	ld	s2,16(sp)
    80002414:	69a2                	ld	s3,8(sp)
    80002416:	6145                	addi	sp,sp,48
    80002418:	8082                	ret

000000008000241a <get_mmr_list>:

// find the mmr_list for a given listid
struct mmr_list*
get_mmr_list(int listid) {
    8000241a:	1101                	addi	sp,sp,-32
    8000241c:	ec06                	sd	ra,24(sp)
    8000241e:	e822                	sd	s0,16(sp)
    80002420:	e426                	sd	s1,8(sp)
    80002422:	1000                	addi	s0,sp,32
    80002424:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    80002426:	0000f517          	auipc	a0,0xf
    8000242a:	2aa50513          	addi	a0,a0,682 # 800116d0 <listid_lock>
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7ee080e7          	jalr	2030(ra) # 80000c1c <acquire>
  if (listid >=0 && listid < NPROC*MAX_MMR && mmr_list[listid].valid) {
    80002436:	0004871b          	sext.w	a4,s1
    8000243a:	27f00793          	li	a5,639
    8000243e:	02e7eb63          	bltu	a5,a4,80002474 <get_mmr_list+0x5a>
    80002442:	00549713          	slli	a4,s1,0x5
    80002446:	00020797          	auipc	a5,0x20
    8000244a:	2a278793          	addi	a5,a5,674 # 800226e8 <mmr_list>
    8000244e:	97ba                	add	a5,a5,a4
    80002450:	4f9c                	lw	a5,24(a5)
    80002452:	c38d                	beqz	a5,80002474 <get_mmr_list+0x5a>
    release(&listid_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	27c50513          	addi	a0,a0,636 # 800116d0 <listid_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	874080e7          	jalr	-1932(ra) # 80000cd0 <release>
    return(&mmr_list[listid]);
    80002464:	00549513          	slli	a0,s1,0x5
    80002468:	00020797          	auipc	a5,0x20
    8000246c:	28078793          	addi	a5,a5,640 # 800226e8 <mmr_list>
    80002470:	953e                	add	a0,a0,a5
    80002472:	a811                	j	80002486 <get_mmr_list+0x6c>
  }
  else {
    release(&listid_lock);
    80002474:	0000f517          	auipc	a0,0xf
    80002478:	25c50513          	addi	a0,a0,604 # 800116d0 <listid_lock>
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	854080e7          	jalr	-1964(ra) # 80000cd0 <release>
    return 0;
    80002484:	4501                	li	a0,0
  }
}
    80002486:	60e2                	ld	ra,24(sp)
    80002488:	6442                	ld	s0,16(sp)
    8000248a:	64a2                	ld	s1,8(sp)
    8000248c:	6105                	addi	sp,sp,32
    8000248e:	8082                	ret

0000000080002490 <dealloc_mmr_listid>:

// free up entry in mmr_list array
void
dealloc_mmr_listid(int listid) {
    80002490:	1101                	addi	sp,sp,-32
    80002492:	ec06                	sd	ra,24(sp)
    80002494:	e822                	sd	s0,16(sp)
    80002496:	e426                	sd	s1,8(sp)
    80002498:	e04a                	sd	s2,0(sp)
    8000249a:	1000                	addi	s0,sp,32
    8000249c:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    8000249e:	0000f917          	auipc	s2,0xf
    800024a2:	23290913          	addi	s2,s2,562 # 800116d0 <listid_lock>
    800024a6:	854a                	mv	a0,s2
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	774080e7          	jalr	1908(ra) # 80000c1c <acquire>
  mmr_list[listid].valid = 0;
    800024b0:	0496                	slli	s1,s1,0x5
    800024b2:	00020797          	auipc	a5,0x20
    800024b6:	23678793          	addi	a5,a5,566 # 800226e8 <mmr_list>
    800024ba:	97a6                	add	a5,a5,s1
    800024bc:	0007ac23          	sw	zero,24(a5)
  release(&listid_lock);
    800024c0:	854a                	mv	a0,s2
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	80e080e7          	jalr	-2034(ra) # 80000cd0 <release>
}
    800024ca:	60e2                	ld	ra,24(sp)
    800024cc:	6442                	ld	s0,16(sp)
    800024ce:	64a2                	ld	s1,8(sp)
    800024d0:	6902                	ld	s2,0(sp)
    800024d2:	6105                	addi	sp,sp,32
    800024d4:	8082                	ret

00000000800024d6 <freeproc>:
{
    800024d6:	711d                	addi	sp,sp,-96
    800024d8:	ec86                	sd	ra,88(sp)
    800024da:	e8a2                	sd	s0,80(sp)
    800024dc:	e4a6                	sd	s1,72(sp)
    800024de:	e0ca                	sd	s2,64(sp)
    800024e0:	fc4e                	sd	s3,56(sp)
    800024e2:	f852                	sd	s4,48(sp)
    800024e4:	f456                	sd	s5,40(sp)
    800024e6:	f05a                	sd	s6,32(sp)
    800024e8:	ec5e                	sd	s7,24(sp)
    800024ea:	e862                	sd	s8,16(sp)
    800024ec:	e466                	sd	s9,8(sp)
    800024ee:	1080                	addi	s0,sp,96
    800024f0:	8a2a                	mv	s4,a0
  if(p->trapframe)
    800024f2:	33053503          	ld	a0,816(a0)
    800024f6:	c509                	beqz	a0,80002500 <freeproc+0x2a>
    kfree((void*)p->trapframe);
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	4ec080e7          	jalr	1260(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80002500:	320a3823          	sd	zero,816(s4)
  for (int i = 0; i < MAX_MMR; i++) {
    80002504:	028a0913          	addi	s2,s4,40
    80002508:	2f8a0c13          	addi	s8,s4,760
    if (p->mmr[i].valid == 1) {
    8000250c:	4b05                	li	s6,1
      for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr + p->mmr[i].length; addr += PGSIZE)
    8000250e:	6b85                	lui	s7,0x1
        acquire(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    80002510:	00020c97          	auipc	s9,0x20
    80002514:	1d8c8c93          	addi	s9,s9,472 # 800226e8 <mmr_list>
    80002518:	a851                	j	800025ac <freeproc+0xd6>
    8000251a:	00092503          	lw	a0,0(s2)
    8000251e:	0516                	slli	a0,a0,0x5
    80002520:	9566                	add	a0,a0,s9
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	6fa080e7          	jalr	1786(ra) # 80000c1c <acquire>
        if (p->mmr[i].mmr_family.next == &(p->mmr[i].mmr_family)) { // no other family members
    8000252a:	01093783          	ld	a5,16(s2)
    8000252e:	03278263          	beq	a5,s2,80002552 <freeproc+0x7c>
          (p->mmr[i].mmr_family.next)->prev = p->mmr[i].mmr_family.prev;
    80002532:	01893703          	ld	a4,24(s2)
    80002536:	ef98                	sd	a4,24(a5)
          (p->mmr[i].mmr_family.prev)->next = p->mmr[i].mmr_family.next;
    80002538:	01093783          	ld	a5,16(s2)
    8000253c:	eb1c                	sd	a5,16(a4)
          release(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    8000253e:	00092503          	lw	a0,0(s2)
    80002542:	0516                	slli	a0,a0,0x5
    80002544:	9566                	add	a0,a0,s9
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	78a080e7          	jalr	1930(ra) # 80000cd0 <release>
    int dofree = 0;
    8000254e:	8aa6                	mv	s5,s1
    80002550:	a0bd                	j	800025be <freeproc+0xe8>
          release(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    80002552:	00092503          	lw	a0,0(s2)
    80002556:	0516                	slli	a0,a0,0x5
    80002558:	9566                	add	a0,a0,s9
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	776080e7          	jalr	1910(ra) # 80000cd0 <release>
          dealloc_mmr_listid(p->mmr[i].mmr_family.listid);
    80002562:	00092503          	lw	a0,0(s2)
    80002566:	00000097          	auipc	ra,0x0
    8000256a:	f2a080e7          	jalr	-214(ra) # 80002490 <dealloc_mmr_listid>
    8000256e:	a881                	j	800025be <freeproc+0xe8>
      for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr + p->mmr[i].length; addr += PGSIZE)
    80002570:	94de                	add	s1,s1,s7
    80002572:	fe09a783          	lw	a5,-32(s3)
    80002576:	fd89b703          	ld	a4,-40(s3)
    8000257a:	97ba                	add	a5,a5,a4
    8000257c:	02f4f463          	bgeu	s1,a5,800025a4 <freeproc+0xce>
        if (walkaddr(p->pagetable, addr))
    80002580:	85a6                	mv	a1,s1
    80002582:	328a3503          	ld	a0,808(s4)
    80002586:	fffff097          	auipc	ra,0xfffff
    8000258a:	b20080e7          	jalr	-1248(ra) # 800010a6 <walkaddr>
    8000258e:	d16d                	beqz	a0,80002570 <freeproc+0x9a>
          uvmunmap(p->pagetable, addr, 1, dofree);
    80002590:	86d6                	mv	a3,s5
    80002592:	865a                	mv	a2,s6
    80002594:	85a6                	mv	a1,s1
    80002596:	328a3503          	ld	a0,808(s4)
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	d14080e7          	jalr	-748(ra) # 800012ae <uvmunmap>
    800025a2:	b7f9                	j	80002570 <freeproc+0x9a>
  for (int i = 0; i < MAX_MMR; i++) {
    800025a4:	04890913          	addi	s2,s2,72
    800025a8:	03890363          	beq	s2,s8,800025ce <freeproc+0xf8>
    if (p->mmr[i].valid == 1) {
    800025ac:	89ca                	mv	s3,s2
    800025ae:	fec92a83          	lw	s5,-20(s2)
    800025b2:	ff6a99e3          	bne	s5,s6,800025a4 <freeproc+0xce>
      if (p->mmr[i].flags & MAP_PRIVATE)
    800025b6:	fe892483          	lw	s1,-24(s2)
    800025ba:	8889                	andi	s1,s1,2
    800025bc:	dcb9                	beqz	s1,8000251a <freeproc+0x44>
      for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr + p->mmr[i].length; addr += PGSIZE)
    800025be:	fd89b483          	ld	s1,-40(s3)
    800025c2:	fe09a783          	lw	a5,-32(s3)
    800025c6:	97a6                	add	a5,a5,s1
    800025c8:	faf4ece3          	bltu	s1,a5,80002580 <freeproc+0xaa>
    800025cc:	bfe1                	j	800025a4 <freeproc+0xce>
  if(p->pagetable)
    800025ce:	328a3503          	ld	a0,808(s4)
    800025d2:	c519                	beqz	a0,800025e0 <freeproc+0x10a>
    proc_freepagetable(p->pagetable, p->sz);
    800025d4:	320a3583          	ld	a1,800(s4)
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	678080e7          	jalr	1656(ra) # 80001c50 <proc_freepagetable>
  p->pagetable = 0;
    800025e0:	320a3423          	sd	zero,808(s4)
  p->sz = 0;
    800025e4:	320a3023          	sd	zero,800(s4)
  p->pid = 0;
    800025e8:	300a2423          	sw	zero,776(s4)
  p->parent = 0;
    800025ec:	300a3823          	sd	zero,784(s4)
  p->name[0] = 0;
    800025f0:	420a0823          	sb	zero,1072(s4)
  p->chan = 0;
    800025f4:	2e0a3c23          	sd	zero,760(s4)
  p->killed = 0;
    800025f8:	300a2023          	sw	zero,768(s4)
  p->xstate = 0;
    800025fc:	300a2223          	sw	zero,772(s4)
  p->state = UNUSED;
    80002600:	2e0a2823          	sw	zero,752(s4)
}
    80002604:	60e6                	ld	ra,88(sp)
    80002606:	6446                	ld	s0,80(sp)
    80002608:	64a6                	ld	s1,72(sp)
    8000260a:	6906                	ld	s2,64(sp)
    8000260c:	79e2                	ld	s3,56(sp)
    8000260e:	7a42                	ld	s4,48(sp)
    80002610:	7aa2                	ld	s5,40(sp)
    80002612:	7b02                	ld	s6,32(sp)
    80002614:	6be2                	ld	s7,24(sp)
    80002616:	6c42                	ld	s8,16(sp)
    80002618:	6ca2                	ld	s9,8(sp)
    8000261a:	6125                	addi	sp,sp,96
    8000261c:	8082                	ret

000000008000261e <allocproc>:
{
    8000261e:	7179                	addi	sp,sp,-48
    80002620:	f406                	sd	ra,40(sp)
    80002622:	f022                	sd	s0,32(sp)
    80002624:	ec26                	sd	s1,24(sp)
    80002626:	e84a                	sd	s2,16(sp)
    80002628:	e44e                	sd	s3,8(sp)
    8000262a:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    8000262c:	0000f497          	auipc	s1,0xf
    80002630:	0bc48493          	addi	s1,s1,188 # 800116e8 <proc>
    80002634:	00020997          	auipc	s3,0x20
    80002638:	0b498993          	addi	s3,s3,180 # 800226e8 <mmr_list>
    acquire(&p->lock);
    8000263c:	2d848913          	addi	s2,s1,728
    80002640:	854a                	mv	a0,s2
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	5da080e7          	jalr	1498(ra) # 80000c1c <acquire>
    if(p->state == UNUSED) {
    8000264a:	2f04a783          	lw	a5,752(s1)
    8000264e:	cf81                	beqz	a5,80002666 <allocproc+0x48>
      release(&p->lock);
    80002650:	854a                	mv	a0,s2
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	67e080e7          	jalr	1662(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000265a:	44048493          	addi	s1,s1,1088
    8000265e:	fd349fe3          	bne	s1,s3,8000263c <allocproc+0x1e>
  return 0;
    80002662:	4481                	li	s1,0
    80002664:	a085                	j	800026c4 <allocproc+0xa6>
  p->pid = allocpid();
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	508080e7          	jalr	1288(ra) # 80001b6e <allocpid>
    8000266e:	30a4a423          	sw	a0,776(s1)
  p->state = USED;
    80002672:	4785                	li	a5,1
    80002674:	2ef4a823          	sw	a5,752(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	46a080e7          	jalr	1130(ra) # 80000ae2 <kalloc>
    80002680:	89aa                	mv	s3,a0
    80002682:	32a4b823          	sd	a0,816(s1)
    80002686:	c539                	beqz	a0,800026d4 <allocproc+0xb6>
  p->pagetable = proc_pagetable(p);
    80002688:	8526                	mv	a0,s1
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	52a080e7          	jalr	1322(ra) # 80001bb4 <proc_pagetable>
    80002692:	89aa                	mv	s3,a0
    80002694:	32a4b423          	sd	a0,808(s1)
  if(p->pagetable == 0){
    80002698:	c931                	beqz	a0,800026ec <allocproc+0xce>
  memset(&p->context, 0, sizeof(p->context));
    8000269a:	07000613          	li	a2,112
    8000269e:	4581                	li	a1,0
    800026a0:	33848513          	addi	a0,s1,824
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	674080e7          	jalr	1652(ra) # 80000d18 <memset>
  p->context.ra = (uint64)forkret;
    800026ac:	fffff797          	auipc	a5,0xfffff
    800026b0:	47878793          	addi	a5,a5,1144 # 80001b24 <forkret>
    800026b4:	32f4bc23          	sd	a5,824(s1)
  p->context.sp = p->kstack + PGSIZE;
    800026b8:	3184b783          	ld	a5,792(s1)
    800026bc:	6705                	lui	a4,0x1
    800026be:	97ba                	add	a5,a5,a4
    800026c0:	34f4b023          	sd	a5,832(s1)
}
    800026c4:	8526                	mv	a0,s1
    800026c6:	70a2                	ld	ra,40(sp)
    800026c8:	7402                	ld	s0,32(sp)
    800026ca:	64e2                	ld	s1,24(sp)
    800026cc:	6942                	ld	s2,16(sp)
    800026ce:	69a2                	ld	s3,8(sp)
    800026d0:	6145                	addi	sp,sp,48
    800026d2:	8082                	ret
    freeproc(p);
    800026d4:	8526                	mv	a0,s1
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	e00080e7          	jalr	-512(ra) # 800024d6 <freeproc>
    release(&p->lock);
    800026de:	854a                	mv	a0,s2
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	5f0080e7          	jalr	1520(ra) # 80000cd0 <release>
    return 0;
    800026e8:	84ce                	mv	s1,s3
    800026ea:	bfe9                	j	800026c4 <allocproc+0xa6>
    freeproc(p);
    800026ec:	8526                	mv	a0,s1
    800026ee:	00000097          	auipc	ra,0x0
    800026f2:	de8080e7          	jalr	-536(ra) # 800024d6 <freeproc>
    release(&p->lock);
    800026f6:	854a                	mv	a0,s2
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	5d8080e7          	jalr	1496(ra) # 80000cd0 <release>
    return 0;
    80002700:	84ce                	mv	s1,s3
    80002702:	b7c9                	j	800026c4 <allocproc+0xa6>

0000000080002704 <userinit>:
{
    80002704:	1101                	addi	sp,sp,-32
    80002706:	ec06                	sd	ra,24(sp)
    80002708:	e822                	sd	s0,16(sp)
    8000270a:	e426                	sd	s1,8(sp)
    8000270c:	1000                	addi	s0,sp,32
  p = allocproc();
    8000270e:	00000097          	auipc	ra,0x0
    80002712:	f10080e7          	jalr	-240(ra) # 8000261e <allocproc>
    80002716:	84aa                	mv	s1,a0
  initproc = p;
    80002718:	00007797          	auipc	a5,0x7
    8000271c:	90a7b823          	sd	a0,-1776(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002720:	03400613          	li	a2,52
    80002724:	00006597          	auipc	a1,0x6
    80002728:	13c58593          	addi	a1,a1,316 # 80008860 <initcode>
    8000272c:	32853503          	ld	a0,808(a0)
    80002730:	fffff097          	auipc	ra,0xfffff
    80002734:	c52080e7          	jalr	-942(ra) # 80001382 <uvminit>
  p->sz = PGSIZE;
    80002738:	6785                	lui	a5,0x1
    8000273a:	32f4b023          	sd	a5,800(s1)
  p->trapframe->epc = 0;      // user program counter
    8000273e:	3304b703          	ld	a4,816(s1)
    80002742:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002746:	3304b703          	ld	a4,816(s1)
    8000274a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000274c:	4641                	li	a2,16
    8000274e:	00006597          	auipc	a1,0x6
    80002752:	b1a58593          	addi	a1,a1,-1254 # 80008268 <digits+0x228>
    80002756:	43048513          	addi	a0,s1,1072
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	708080e7          	jalr	1800(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80002762:	00006517          	auipc	a0,0x6
    80002766:	b1650513          	addi	a0,a0,-1258 # 80008278 <digits+0x238>
    8000276a:	00002097          	auipc	ra,0x2
    8000276e:	e6c080e7          	jalr	-404(ra) # 800045d6 <namei>
    80002772:	42a4b423          	sd	a0,1064(s1)
  p->state = RUNNABLE;
    80002776:	478d                	li	a5,3
    80002778:	2ef4a823          	sw	a5,752(s1)
  p->cur_max = MAXVA - 2*PGSIZE;
    8000277c:	020007b7          	lui	a5,0x2000
    80002780:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80002782:	07b6                	slli	a5,a5,0xd
    80002784:	2cf4b823          	sd	a5,720(s1)
  release(&p->lock);
    80002788:	2d848513          	addi	a0,s1,728
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	544080e7          	jalr	1348(ra) # 80000cd0 <release>
}
    80002794:	60e2                	ld	ra,24(sp)
    80002796:	6442                	ld	s0,16(sp)
    80002798:	64a2                	ld	s1,8(sp)
    8000279a:	6105                	addi	sp,sp,32
    8000279c:	8082                	ret

000000008000279e <fork>:
{
    8000279e:	7159                	addi	sp,sp,-112
    800027a0:	f486                	sd	ra,104(sp)
    800027a2:	f0a2                	sd	s0,96(sp)
    800027a4:	eca6                	sd	s1,88(sp)
    800027a6:	e8ca                	sd	s2,80(sp)
    800027a8:	e4ce                	sd	s3,72(sp)
    800027aa:	e0d2                	sd	s4,64(sp)
    800027ac:	fc56                	sd	s5,56(sp)
    800027ae:	f85a                	sd	s6,48(sp)
    800027b0:	f45e                	sd	s7,40(sp)
    800027b2:	f062                	sd	s8,32(sp)
    800027b4:	ec66                	sd	s9,24(sp)
    800027b6:	e86a                	sd	s10,16(sp)
    800027b8:	e46e                	sd	s11,8(sp)
    800027ba:	1880                	addi	s0,sp,112
  struct proc *p = myproc();
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	330080e7          	jalr	816(ra) # 80001aec <myproc>
    800027c4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800027c6:	00000097          	auipc	ra,0x0
    800027ca:	e58080e7          	jalr	-424(ra) # 8000261e <allocproc>
    800027ce:	28050b63          	beqz	a0,80002a64 <fork+0x2c6>
    800027d2:	8b2a                	mv	s6,a0
  if(uvmcopy(p->pagetable, np->pagetable,0, p->sz) < 0){
    800027d4:	3209b683          	ld	a3,800(s3)
    800027d8:	4601                	li	a2,0
    800027da:	32853583          	ld	a1,808(a0)
    800027de:	3289b503          	ld	a0,808(s3)
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	daa080e7          	jalr	-598(ra) # 8000158c <uvmcopy>
    800027ea:	04054c63          	bltz	a0,80002842 <fork+0xa4>
  np->sz = p->sz;
    800027ee:	3209b783          	ld	a5,800(s3)
    800027f2:	32fb3023          	sd	a5,800(s6)
  np->cur_max = p->cur_max;
    800027f6:	2d09b783          	ld	a5,720(s3)
    800027fa:	2cfb3823          	sd	a5,720(s6)
  *(np->trapframe) = *(p->trapframe);
    800027fe:	3309b683          	ld	a3,816(s3)
    80002802:	87b6                	mv	a5,a3
    80002804:	330b3703          	ld	a4,816(s6)
    80002808:	12068693          	addi	a3,a3,288
    8000280c:	0007b803          	ld	a6,0(a5)
    80002810:	6788                	ld	a0,8(a5)
    80002812:	6b8c                	ld	a1,16(a5)
    80002814:	6f90                	ld	a2,24(a5)
    80002816:	01073023          	sd	a6,0(a4)
    8000281a:	e708                	sd	a0,8(a4)
    8000281c:	eb0c                	sd	a1,16(a4)
    8000281e:	ef10                	sd	a2,24(a4)
    80002820:	02078793          	addi	a5,a5,32
    80002824:	02070713          	addi	a4,a4,32
    80002828:	fed792e3          	bne	a5,a3,8000280c <fork+0x6e>
  np->trapframe->a0 = 0;
    8000282c:	330b3783          	ld	a5,816(s6)
    80002830:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002834:	3a898493          	addi	s1,s3,936
    80002838:	3a8b0913          	addi	s2,s6,936
    8000283c:	42898a13          	addi	s4,s3,1064
    80002840:	a015                	j	80002864 <fork+0xc6>
    freeproc(np);
    80002842:	855a                	mv	a0,s6
    80002844:	00000097          	auipc	ra,0x0
    80002848:	c92080e7          	jalr	-878(ra) # 800024d6 <freeproc>
    release(&np->lock);
    8000284c:	2d8b0513          	addi	a0,s6,728
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	480080e7          	jalr	1152(ra) # 80000cd0 <release>
    return -1;
    80002858:	5d7d                	li	s10,-1
    8000285a:	a2ed                	j	80002a44 <fork+0x2a6>
  for(i = 0; i < NOFILE; i++)
    8000285c:	04a1                	addi	s1,s1,8
    8000285e:	0921                	addi	s2,s2,8
    80002860:	01448b63          	beq	s1,s4,80002876 <fork+0xd8>
    if(p->ofile[i])
    80002864:	6088                	ld	a0,0(s1)
    80002866:	d97d                	beqz	a0,8000285c <fork+0xbe>
      np->ofile[i] = filedup(p->ofile[i]);
    80002868:	00002097          	auipc	ra,0x2
    8000286c:	408080e7          	jalr	1032(ra) # 80004c70 <filedup>
    80002870:	00a93023          	sd	a0,0(s2)
    80002874:	b7e5                	j	8000285c <fork+0xbe>
  np->cwd = idup(p->cwd);
    80002876:	4289b503          	ld	a0,1064(s3)
    8000287a:	00001097          	auipc	ra,0x1
    8000287e:	562080e7          	jalr	1378(ra) # 80003ddc <idup>
    80002882:	42ab3423          	sd	a0,1064(s6)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002886:	4641                	li	a2,16
    80002888:	43098593          	addi	a1,s3,1072
    8000288c:	430b0513          	addi	a0,s6,1072
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	5d2080e7          	jalr	1490(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80002898:	308b2d03          	lw	s10,776(s6)
  memmove((char*)np->mmr, (char *)p->mmr, MAX_MMR*sizeof(struct mmr));
    8000289c:	2d000613          	li	a2,720
    800028a0:	85ce                	mv	a1,s3
    800028a2:	855a                	mv	a0,s6
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	4d0080e7          	jalr	1232(ra) # 80000d74 <memmove>
  for (int i = 0; i < MAX_MMR; i++) {
    800028ac:	028b0b93          	addi	s7,s6,40
    800028b0:	02898a93          	addi	s5,s3,40
    800028b4:	2f898c93          	addi	s9,s3,760
    if(p->mmr[i].valid == 1) {
    800028b8:	4c05                	li	s8,1
            if(uvmcopyshared(p->pagetable, np->pagetable, addr, addr+PGSIZE) < 0) {
    800028ba:	6a05                	lui	s4,0x1
        acquire(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    800028bc:	00020d97          	auipc	s11,0x20
    800028c0:	e2cd8d93          	addi	s11,s11,-468 # 800226e8 <mmr_list>
    800028c4:	a895                	j	80002938 <fork+0x19a>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    800028c6:	9952                	add	s2,s2,s4
    800028c8:	fe04a783          	lw	a5,-32(s1)
    800028cc:	fd84b703          	ld	a4,-40(s1)
    800028d0:	97ba                	add	a5,a5,a4
    800028d2:	04f97463          	bgeu	s2,a5,8000291a <fork+0x17c>
          if(walkaddr(p->pagetable, addr))
    800028d6:	85ca                	mv	a1,s2
    800028d8:	3289b503          	ld	a0,808(s3)
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	7ca080e7          	jalr	1994(ra) # 800010a6 <walkaddr>
    800028e4:	d16d                	beqz	a0,800028c6 <fork+0x128>
            if(uvmcopy(p->pagetable, np->pagetable, addr, addr+PGSIZE) < 0) {
    800028e6:	014906b3          	add	a3,s2,s4
    800028ea:	864a                	mv	a2,s2
    800028ec:	328b3583          	ld	a1,808(s6)
    800028f0:	3289b503          	ld	a0,808(s3)
    800028f4:	fffff097          	auipc	ra,0xfffff
    800028f8:	c98080e7          	jalr	-872(ra) # 8000158c <uvmcopy>
    800028fc:	fc0555e3          	bgez	a0,800028c6 <fork+0x128>
              freeproc(np);
    80002900:	855a                	mv	a0,s6
    80002902:	00000097          	auipc	ra,0x0
    80002906:	bd4080e7          	jalr	-1068(ra) # 800024d6 <freeproc>
              release(&np->lock);
    8000290a:	2d8b0513          	addi	a0,s6,728
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	3c2080e7          	jalr	962(ra) # 80000cd0 <release>
              return -1;
    80002916:	5d7d                	li	s10,-1
    80002918:	a235                	j	80002a44 <fork+0x2a6>
        np->mmr[i].mmr_family.proc = np;
    8000291a:	016bb423          	sd	s6,8(s7) # 1008 <_entry-0x7fffeff8>
        np->mmr[i].mmr_family.listid = -1;
    8000291e:	57fd                	li	a5,-1
    80002920:	00fba023          	sw	a5,0(s7)
        np->mmr[i].mmr_family.next = &(np->mmr[i].mmr_family);
    80002924:	017bb823          	sd	s7,16(s7)
        np->mmr[i].mmr_family.prev = &(np->mmr[i].mmr_family);
    80002928:	017bbc23          	sd	s7,24(s7)
  for (int i = 0; i < MAX_MMR; i++) {
    8000292c:	048b8b93          	addi	s7,s7,72
    80002930:	048a8a93          	addi	s5,s5,72
    80002934:	0d9a8463          	beq	s5,s9,800029fc <fork+0x25e>
    if(p->mmr[i].valid == 1) {
    80002938:	84d6                	mv	s1,s5
    8000293a:	fecaa783          	lw	a5,-20(s5)
    8000293e:	ff8797e3          	bne	a5,s8,8000292c <fork+0x18e>
      if(p->mmr[i].flags & MAP_PRIVATE) {
    80002942:	fe8aa783          	lw	a5,-24(s5)
    80002946:	8b89                	andi	a5,a5,2
    80002948:	cb89                	beqz	a5,8000295a <fork+0x1bc>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    8000294a:	fd8ab903          	ld	s2,-40(s5)
    8000294e:	fe0aa783          	lw	a5,-32(s5)
    80002952:	97ca                	add	a5,a5,s2
    80002954:	f8f961e3          	bltu	s2,a5,800028d6 <fork+0x138>
    80002958:	b7c9                	j	8000291a <fork+0x17c>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    8000295a:	fd8ab903          	ld	s2,-40(s5)
    8000295e:	fe0aa783          	lw	a5,-32(s5)
    80002962:	97ca                	add	a5,a5,s2
    80002964:	04f96763          	bltu	s2,a5,800029b2 <fork+0x214>
        np->mmr[i].mmr_family.proc = np;
    80002968:	016bb423          	sd	s6,8(s7)
        np->mmr[i].mmr_family.listid = p->mmr[i].mmr_family.listid;
    8000296c:	4088                	lw	a0,0(s1)
    8000296e:	00aba023          	sw	a0,0(s7)
        acquire(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    80002972:	0516                	slli	a0,a0,0x5
    80002974:	956e                	add	a0,a0,s11
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	2a6080e7          	jalr	678(ra) # 80000c1c <acquire>
        np->mmr[i].mmr_family.next = p->mmr[i].mmr_family.next;
    8000297e:	689c                	ld	a5,16(s1)
    80002980:	00fbb823          	sd	a5,16(s7)
        p->mmr[i].mmr_family.next = &(np->mmr[i].mmr_family);
    80002984:	0174b823          	sd	s7,16(s1)
        np->mmr[i].mmr_family.prev = &(p->mmr[i].mmr_family);
    80002988:	009bbc23          	sd	s1,24(s7)
        if (p->mmr[i].mmr_family.prev == &(p->mmr[i].mmr_family))
    8000298c:	6c9c                	ld	a5,24(s1)
    8000298e:	06978463          	beq	a5,s1,800029f6 <fork+0x258>
        release(&mmr_list[p->mmr[i].mmr_family.listid].lock);
    80002992:	4088                	lw	a0,0(s1)
    80002994:	0516                	slli	a0,a0,0x5
    80002996:	956e                	add	a0,a0,s11
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	338080e7          	jalr	824(ra) # 80000cd0 <release>
    800029a0:	b771                	j	8000292c <fork+0x18e>
        for (uint64 addr = p->mmr[i].addr; addr < p->mmr[i].addr+p->mmr[i].length; addr += PGSIZE)
    800029a2:	9952                	add	s2,s2,s4
    800029a4:	fe04a783          	lw	a5,-32(s1)
    800029a8:	fd84b703          	ld	a4,-40(s1)
    800029ac:	97ba                	add	a5,a5,a4
    800029ae:	faf97de3          	bgeu	s2,a5,80002968 <fork+0x1ca>
          if(walkaddr(p->pagetable, addr))
    800029b2:	85ca                	mv	a1,s2
    800029b4:	3289b503          	ld	a0,808(s3)
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	6ee080e7          	jalr	1774(ra) # 800010a6 <walkaddr>
    800029c0:	d16d                	beqz	a0,800029a2 <fork+0x204>
            if(uvmcopyshared(p->pagetable, np->pagetable, addr, addr+PGSIZE) < 0) {
    800029c2:	014906b3          	add	a3,s2,s4
    800029c6:	864a                	mv	a2,s2
    800029c8:	328b3583          	ld	a1,808(s6)
    800029cc:	3289b503          	ld	a0,808(s3)
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	c90080e7          	jalr	-880(ra) # 80001660 <uvmcopyshared>
    800029d8:	fc0555e3          	bgez	a0,800029a2 <fork+0x204>
              freeproc(np);
    800029dc:	855a                	mv	a0,s6
    800029de:	00000097          	auipc	ra,0x0
    800029e2:	af8080e7          	jalr	-1288(ra) # 800024d6 <freeproc>
              release(&np->lock);
    800029e6:	2d8b0513          	addi	a0,s6,728
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	2e6080e7          	jalr	742(ra) # 80000cd0 <release>
              return -1;
    800029f2:	5d7d                	li	s10,-1
    800029f4:	a881                	j	80002a44 <fork+0x2a6>
          p->mmr[i].mmr_family.prev = &(np->mmr[i].mmr_family);
    800029f6:	0174bc23          	sd	s7,24(s1)
    800029fa:	bf61                	j	80002992 <fork+0x1f4>
  release(&np->lock);
    800029fc:	2d8b0493          	addi	s1,s6,728
    80002a00:	8526                	mv	a0,s1
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	2ce080e7          	jalr	718(ra) # 80000cd0 <release>
  acquire(&wait_lock);
    80002a0a:	0000f917          	auipc	s2,0xf
    80002a0e:	8ae90913          	addi	s2,s2,-1874 # 800112b8 <wait_lock>
    80002a12:	854a                	mv	a0,s2
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	208080e7          	jalr	520(ra) # 80000c1c <acquire>
  np->parent = p;
    80002a1c:	313b3823          	sd	s3,784(s6)
  release(&wait_lock);
    80002a20:	854a                	mv	a0,s2
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	2ae080e7          	jalr	686(ra) # 80000cd0 <release>
  acquire(&np->lock);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	1f0080e7          	jalr	496(ra) # 80000c1c <acquire>
  np->state = RUNNABLE;
    80002a34:	478d                	li	a5,3
    80002a36:	2efb2823          	sw	a5,752(s6)
  release(&np->lock);
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	294080e7          	jalr	660(ra) # 80000cd0 <release>
}
    80002a44:	856a                	mv	a0,s10
    80002a46:	70a6                	ld	ra,104(sp)
    80002a48:	7406                	ld	s0,96(sp)
    80002a4a:	64e6                	ld	s1,88(sp)
    80002a4c:	6946                	ld	s2,80(sp)
    80002a4e:	69a6                	ld	s3,72(sp)
    80002a50:	6a06                	ld	s4,64(sp)
    80002a52:	7ae2                	ld	s5,56(sp)
    80002a54:	7b42                	ld	s6,48(sp)
    80002a56:	7ba2                	ld	s7,40(sp)
    80002a58:	7c02                	ld	s8,32(sp)
    80002a5a:	6ce2                	ld	s9,24(sp)
    80002a5c:	6d42                	ld	s10,16(sp)
    80002a5e:	6da2                	ld	s11,8(sp)
    80002a60:	6165                	addi	sp,sp,112
    80002a62:	8082                	ret
    return -1;
    80002a64:	5d7d                	li	s10,-1
    80002a66:	bff9                	j	80002a44 <fork+0x2a6>

0000000080002a68 <wait>:
{
    80002a68:	711d                	addi	sp,sp,-96
    80002a6a:	ec86                	sd	ra,88(sp)
    80002a6c:	e8a2                	sd	s0,80(sp)
    80002a6e:	e4a6                	sd	s1,72(sp)
    80002a70:	e0ca                	sd	s2,64(sp)
    80002a72:	fc4e                	sd	s3,56(sp)
    80002a74:	f852                	sd	s4,48(sp)
    80002a76:	f456                	sd	s5,40(sp)
    80002a78:	f05a                	sd	s6,32(sp)
    80002a7a:	ec5e                	sd	s7,24(sp)
    80002a7c:	e862                	sd	s8,16(sp)
    80002a7e:	e466                	sd	s9,8(sp)
    80002a80:	1080                	addi	s0,sp,96
    80002a82:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	068080e7          	jalr	104(ra) # 80001aec <myproc>
    80002a8c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002a8e:	0000f517          	auipc	a0,0xf
    80002a92:	82a50513          	addi	a0,a0,-2006 # 800112b8 <wait_lock>
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	186080e7          	jalr	390(ra) # 80000c1c <acquire>
    havekids = 0;
    80002a9e:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    80002aa0:	4a95                	li	s5,5
        havekids = 1;
    80002aa2:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002aa4:	00020997          	auipc	s3,0x20
    80002aa8:	c4498993          	addi	s3,s3,-956 # 800226e8 <mmr_list>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002aac:	0000fc97          	auipc	s9,0xf
    80002ab0:	80cc8c93          	addi	s9,s9,-2036 # 800112b8 <wait_lock>
    havekids = 0;
    80002ab4:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    80002ab6:	0000f497          	auipc	s1,0xf
    80002aba:	c3248493          	addi	s1,s1,-974 # 800116e8 <proc>
    80002abe:	a0bd                	j	80002b2c <wait+0xc4>
          pid = np->pid;
    80002ac0:	3084a983          	lw	s3,776(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002ac4:	000b8e63          	beqz	s7,80002ae0 <wait+0x78>
    80002ac8:	4691                	li	a3,4
    80002aca:	30448613          	addi	a2,s1,772
    80002ace:	85de                	mv	a1,s7
    80002ad0:	32893503          	ld	a0,808(s2)
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	c5e080e7          	jalr	-930(ra) # 80001732 <copyout>
    80002adc:	02054563          	bltz	a0,80002b06 <wait+0x9e>
          freeproc(np);
    80002ae0:	8526                	mv	a0,s1
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	9f4080e7          	jalr	-1548(ra) # 800024d6 <freeproc>
          release(&np->lock);
    80002aea:	8552                	mv	a0,s4
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	1e4080e7          	jalr	484(ra) # 80000cd0 <release>
          release(&wait_lock);
    80002af4:	0000e517          	auipc	a0,0xe
    80002af8:	7c450513          	addi	a0,a0,1988 # 800112b8 <wait_lock>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	1d4080e7          	jalr	468(ra) # 80000cd0 <release>
          return pid;
    80002b04:	a0bd                	j	80002b72 <wait+0x10a>
            release(&np->lock);
    80002b06:	8552                	mv	a0,s4
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	1c8080e7          	jalr	456(ra) # 80000cd0 <release>
            release(&wait_lock);
    80002b10:	0000e517          	auipc	a0,0xe
    80002b14:	7a850513          	addi	a0,a0,1960 # 800112b8 <wait_lock>
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	1b8080e7          	jalr	440(ra) # 80000cd0 <release>
            return -1;
    80002b20:	59fd                	li	s3,-1
    80002b22:	a881                	j	80002b72 <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002b24:	44048493          	addi	s1,s1,1088
    80002b28:	03348863          	beq	s1,s3,80002b58 <wait+0xf0>
      if(np->parent == p){
    80002b2c:	3104b783          	ld	a5,784(s1)
    80002b30:	ff279ae3          	bne	a5,s2,80002b24 <wait+0xbc>
        acquire(&np->lock);
    80002b34:	2d848a13          	addi	s4,s1,728
    80002b38:	8552                	mv	a0,s4
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	0e2080e7          	jalr	226(ra) # 80000c1c <acquire>
        if(np->state == ZOMBIE){
    80002b42:	2f04a783          	lw	a5,752(s1)
    80002b46:	f7578de3          	beq	a5,s5,80002ac0 <wait+0x58>
        release(&np->lock);
    80002b4a:	8552                	mv	a0,s4
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	184080e7          	jalr	388(ra) # 80000cd0 <release>
        havekids = 1;
    80002b54:	875a                	mv	a4,s6
    80002b56:	b7f9                	j	80002b24 <wait+0xbc>
    if(!havekids || p->killed){
    80002b58:	c701                	beqz	a4,80002b60 <wait+0xf8>
    80002b5a:	30092783          	lw	a5,768(s2)
    80002b5e:	cb85                	beqz	a5,80002b8e <wait+0x126>
      release(&wait_lock);
    80002b60:	0000e517          	auipc	a0,0xe
    80002b64:	75850513          	addi	a0,a0,1880 # 800112b8 <wait_lock>
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	168080e7          	jalr	360(ra) # 80000cd0 <release>
      return -1;
    80002b70:	59fd                	li	s3,-1
}
    80002b72:	854e                	mv	a0,s3
    80002b74:	60e6                	ld	ra,88(sp)
    80002b76:	6446                	ld	s0,80(sp)
    80002b78:	64a6                	ld	s1,72(sp)
    80002b7a:	6906                	ld	s2,64(sp)
    80002b7c:	79e2                	ld	s3,56(sp)
    80002b7e:	7a42                	ld	s4,48(sp)
    80002b80:	7aa2                	ld	s5,40(sp)
    80002b82:	7b02                	ld	s6,32(sp)
    80002b84:	6be2                	ld	s7,24(sp)
    80002b86:	6c42                	ld	s8,16(sp)
    80002b88:	6ca2                	ld	s9,8(sp)
    80002b8a:	6125                	addi	sp,sp,96
    80002b8c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b8e:	85e6                	mv	a1,s9
    80002b90:	854a                	mv	a0,s2
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	35a080e7          	jalr	858(ra) # 80001eec <sleep>
    havekids = 0;
    80002b9a:	bf29                	j	80002ab4 <wait+0x4c>

0000000080002b9c <alloc_mmr_listid>:

// find an unused entry in the mmr_list array
int
alloc_mmr_listid() {
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	1000                	addi	s0,sp,32
  acquire(&listid_lock);
    80002ba6:	0000f517          	auipc	a0,0xf
    80002baa:	b2a50513          	addi	a0,a0,-1238 # 800116d0 <listid_lock>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	06e080e7          	jalr	110(ra) # 80000c1c <acquire>
  int listid = -1;
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    80002bb6:	00020797          	auipc	a5,0x20
    80002bba:	b4a78793          	addi	a5,a5,-1206 # 80022700 <mmr_list+0x18>
    80002bbe:	4481                	li	s1,0
    80002bc0:	28000693          	li	a3,640
    if (mmr_list[i].valid == 0) {
    80002bc4:	4398                	lw	a4,0(a5)
    80002bc6:	cb01                	beqz	a4,80002bd6 <alloc_mmr_listid+0x3a>
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    80002bc8:	2485                	addiw	s1,s1,1
    80002bca:	02078793          	addi	a5,a5,32
    80002bce:	fed49be3          	bne	s1,a3,80002bc4 <alloc_mmr_listid+0x28>
  int listid = -1;
    80002bd2:	54fd                	li	s1,-1
    80002bd4:	a811                	j	80002be8 <alloc_mmr_listid+0x4c>
      mmr_list[i].valid = 1;
    80002bd6:	00549713          	slli	a4,s1,0x5
    80002bda:	00020797          	auipc	a5,0x20
    80002bde:	b0e78793          	addi	a5,a5,-1266 # 800226e8 <mmr_list>
    80002be2:	97ba                	add	a5,a5,a4
    80002be4:	4705                	li	a4,1
    80002be6:	cf98                	sw	a4,24(a5)
      listid = i;
      break;
    }
  }
  release(&listid_lock);
    80002be8:	0000f517          	auipc	a0,0xf
    80002bec:	ae850513          	addi	a0,a0,-1304 # 800116d0 <listid_lock>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	0e0080e7          	jalr	224(ra) # 80000cd0 <release>
  return(listid);
    80002bf8:	8526                	mv	a0,s1
    80002bfa:	60e2                	ld	ra,24(sp)
    80002bfc:	6442                	ld	s0,16(sp)
    80002bfe:	64a2                	ld	s1,8(sp)
    80002c00:	6105                	addi	sp,sp,32
    80002c02:	8082                	ret

0000000080002c04 <swtch>:
    80002c04:	00153023          	sd	ra,0(a0)
    80002c08:	00253423          	sd	sp,8(a0)
    80002c0c:	e900                	sd	s0,16(a0)
    80002c0e:	ed04                	sd	s1,24(a0)
    80002c10:	03253023          	sd	s2,32(a0)
    80002c14:	03353423          	sd	s3,40(a0)
    80002c18:	03453823          	sd	s4,48(a0)
    80002c1c:	03553c23          	sd	s5,56(a0)
    80002c20:	05653023          	sd	s6,64(a0)
    80002c24:	05753423          	sd	s7,72(a0)
    80002c28:	05853823          	sd	s8,80(a0)
    80002c2c:	05953c23          	sd	s9,88(a0)
    80002c30:	07a53023          	sd	s10,96(a0)
    80002c34:	07b53423          	sd	s11,104(a0)
    80002c38:	0005b083          	ld	ra,0(a1)
    80002c3c:	0085b103          	ld	sp,8(a1)
    80002c40:	6980                	ld	s0,16(a1)
    80002c42:	6d84                	ld	s1,24(a1)
    80002c44:	0205b903          	ld	s2,32(a1)
    80002c48:	0285b983          	ld	s3,40(a1)
    80002c4c:	0305ba03          	ld	s4,48(a1)
    80002c50:	0385ba83          	ld	s5,56(a1)
    80002c54:	0405bb03          	ld	s6,64(a1)
    80002c58:	0485bb83          	ld	s7,72(a1)
    80002c5c:	0505bc03          	ld	s8,80(a1)
    80002c60:	0585bc83          	ld	s9,88(a1)
    80002c64:	0605bd03          	ld	s10,96(a1)
    80002c68:	0685bd83          	ld	s11,104(a1)
    80002c6c:	8082                	ret

0000000080002c6e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c6e:	1141                	addi	sp,sp,-16
    80002c70:	e406                	sd	ra,8(sp)
    80002c72:	e022                	sd	s0,0(sp)
    80002c74:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c76:	00005597          	auipc	a1,0x5
    80002c7a:	66258593          	addi	a1,a1,1634 # 800082d8 <states.0+0x30>
    80002c7e:	00025517          	auipc	a0,0x25
    80002c82:	a6a50513          	addi	a0,a0,-1430 # 800276e8 <tickslock>
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	f06080e7          	jalr	-250(ra) # 80000b8c <initlock>
}
    80002c8e:	60a2                	ld	ra,8(sp)
    80002c90:	6402                	ld	s0,0(sp)
    80002c92:	0141                	addi	sp,sp,16
    80002c94:	8082                	ret

0000000080002c96 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c96:	1141                	addi	sp,sp,-16
    80002c98:	e422                	sd	s0,8(sp)
    80002c9a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c9c:	00004797          	auipc	a5,0x4
    80002ca0:	91478793          	addi	a5,a5,-1772 # 800065b0 <kernelvec>
    80002ca4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ca8:	6422                	ld	s0,8(sp)
    80002caa:	0141                	addi	sp,sp,16
    80002cac:	8082                	ret

0000000080002cae <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cae:	1141                	addi	sp,sp,-16
    80002cb0:	e406                	sd	ra,8(sp)
    80002cb2:	e022                	sd	s0,0(sp)
    80002cb4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	e36080e7          	jalr	-458(ra) # 80001aec <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cc2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cc8:	00004697          	auipc	a3,0x4
    80002ccc:	33868693          	addi	a3,a3,824 # 80007000 <_trampoline>
    80002cd0:	00004717          	auipc	a4,0x4
    80002cd4:	33070713          	addi	a4,a4,816 # 80007000 <_trampoline>
    80002cd8:	8f15                	sub	a4,a4,a3
    80002cda:	040007b7          	lui	a5,0x4000
    80002cde:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ce0:	07b2                	slli	a5,a5,0xc
    80002ce2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ce4:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ce8:	33053703          	ld	a4,816(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cec:	18002673          	csrr	a2,satp
    80002cf0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cf2:	33053603          	ld	a2,816(a0)
    80002cf6:	31853703          	ld	a4,792(a0)
    80002cfa:	6585                	lui	a1,0x1
    80002cfc:	972e                	add	a4,a4,a1
    80002cfe:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d00:	33053703          	ld	a4,816(a0)
    80002d04:	00000617          	auipc	a2,0x0
    80002d08:	13e60613          	addi	a2,a2,318 # 80002e42 <usertrap>
    80002d0c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d0e:	33053703          	ld	a4,816(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d12:	8612                	mv	a2,tp
    80002d14:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d16:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d1a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d1e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d22:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d26:	33053703          	ld	a4,816(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d2a:	6f18                	ld	a4,24(a4)
    80002d2c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d30:	32853583          	ld	a1,808(a0)
    80002d34:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d36:	00004717          	auipc	a4,0x4
    80002d3a:	35a70713          	addi	a4,a4,858 # 80007090 <userret>
    80002d3e:	8f15                	sub	a4,a4,a3
    80002d40:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d42:	577d                	li	a4,-1
    80002d44:	177e                	slli	a4,a4,0x3f
    80002d46:	8dd9                	or	a1,a1,a4
    80002d48:	02000537          	lui	a0,0x2000
    80002d4c:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002d4e:	0536                	slli	a0,a0,0xd
    80002d50:	9782                	jalr	a5
}
    80002d52:	60a2                	ld	ra,8(sp)
    80002d54:	6402                	ld	s0,0(sp)
    80002d56:	0141                	addi	sp,sp,16
    80002d58:	8082                	ret

0000000080002d5a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d5a:	1101                	addi	sp,sp,-32
    80002d5c:	ec06                	sd	ra,24(sp)
    80002d5e:	e822                	sd	s0,16(sp)
    80002d60:	e426                	sd	s1,8(sp)
    80002d62:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d64:	00025497          	auipc	s1,0x25
    80002d68:	98448493          	addi	s1,s1,-1660 # 800276e8 <tickslock>
    80002d6c:	8526                	mv	a0,s1
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	eae080e7          	jalr	-338(ra) # 80000c1c <acquire>
  ticks++;
    80002d76:	00006517          	auipc	a0,0x6
    80002d7a:	2ba50513          	addi	a0,a0,698 # 80009030 <ticks>
    80002d7e:	411c                	lw	a5,0(a0)
    80002d80:	2785                	addiw	a5,a5,1
    80002d82:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	1d8080e7          	jalr	472(ra) # 80001f5c <wakeup>
  release(&tickslock);
    80002d8c:	8526                	mv	a0,s1
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	f42080e7          	jalr	-190(ra) # 80000cd0 <release>
}
    80002d96:	60e2                	ld	ra,24(sp)
    80002d98:	6442                	ld	s0,16(sp)
    80002d9a:	64a2                	ld	s1,8(sp)
    80002d9c:	6105                	addi	sp,sp,32
    80002d9e:	8082                	ret

0000000080002da0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	e426                	sd	s1,8(sp)
    80002da8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002daa:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002dae:	00074d63          	bltz	a4,80002dc8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002db2:	57fd                	li	a5,-1
    80002db4:	17fe                	slli	a5,a5,0x3f
    80002db6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002db8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dba:	06f70363          	beq	a4,a5,80002e20 <devintr+0x80>
  }
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	64a2                	ld	s1,8(sp)
    80002dc4:	6105                	addi	sp,sp,32
    80002dc6:	8082                	ret
     (scause & 0xff) == 9){
    80002dc8:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002dcc:	46a5                	li	a3,9
    80002dce:	fed792e3          	bne	a5,a3,80002db2 <devintr+0x12>
    int irq = plic_claim();
    80002dd2:	00004097          	auipc	ra,0x4
    80002dd6:	8e6080e7          	jalr	-1818(ra) # 800066b8 <plic_claim>
    80002dda:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ddc:	47a9                	li	a5,10
    80002dde:	02f50763          	beq	a0,a5,80002e0c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002de2:	4785                	li	a5,1
    80002de4:	02f50963          	beq	a0,a5,80002e16 <devintr+0x76>
    return 1;
    80002de8:	4505                	li	a0,1
    } else if(irq){
    80002dea:	d8f1                	beqz	s1,80002dbe <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002dec:	85a6                	mv	a1,s1
    80002dee:	00005517          	auipc	a0,0x5
    80002df2:	4f250513          	addi	a0,a0,1266 # 800082e0 <states.0+0x38>
    80002df6:	ffffd097          	auipc	ra,0xffffd
    80002dfa:	790080e7          	jalr	1936(ra) # 80000586 <printf>
      plic_complete(irq);
    80002dfe:	8526                	mv	a0,s1
    80002e00:	00004097          	auipc	ra,0x4
    80002e04:	8dc080e7          	jalr	-1828(ra) # 800066dc <plic_complete>
    return 1;
    80002e08:	4505                	li	a0,1
    80002e0a:	bf55                	j	80002dbe <devintr+0x1e>
      uartintr();
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	b88080e7          	jalr	-1144(ra) # 80000994 <uartintr>
    80002e14:	b7ed                	j	80002dfe <devintr+0x5e>
      virtio_disk_intr();
    80002e16:	00004097          	auipc	ra,0x4
    80002e1a:	d52080e7          	jalr	-686(ra) # 80006b68 <virtio_disk_intr>
    80002e1e:	b7c5                	j	80002dfe <devintr+0x5e>
    if(cpuid() == 0){
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	ca0080e7          	jalr	-864(ra) # 80001ac0 <cpuid>
    80002e28:	c901                	beqz	a0,80002e38 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e2a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e2e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e30:	14479073          	csrw	sip,a5
    return 2;
    80002e34:	4509                	li	a0,2
    80002e36:	b761                	j	80002dbe <devintr+0x1e>
      clockintr();
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	f22080e7          	jalr	-222(ra) # 80002d5a <clockintr>
    80002e40:	b7ed                	j	80002e2a <devintr+0x8a>

0000000080002e42 <usertrap>:
{
    80002e42:	715d                	addi	sp,sp,-80
    80002e44:	e486                	sd	ra,72(sp)
    80002e46:	e0a2                	sd	s0,64(sp)
    80002e48:	fc26                	sd	s1,56(sp)
    80002e4a:	f84a                	sd	s2,48(sp)
    80002e4c:	f44e                	sd	s3,40(sp)
    80002e4e:	f052                	sd	s4,32(sp)
    80002e50:	ec56                	sd	s5,24(sp)
    80002e52:	e85a                	sd	s6,16(sp)
    80002e54:	e45e                	sd	s7,8(sp)
    80002e56:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e58:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e5c:	1007f793          	andi	a5,a5,256
    80002e60:	ebbd                	bnez	a5,80002ed6 <usertrap+0x94>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e62:	00003797          	auipc	a5,0x3
    80002e66:	74e78793          	addi	a5,a5,1870 # 800065b0 <kernelvec>
    80002e6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	c7e080e7          	jalr	-898(ra) # 80001aec <myproc>
    80002e76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e78:	33053783          	ld	a5,816(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e7c:	14102773          	csrr	a4,sepc
    80002e80:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e82:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e86:	47a1                	li	a5,8
    80002e88:	06f71563          	bne	a4,a5,80002ef2 <usertrap+0xb0>
    if(p->killed)
    80002e8c:	30052783          	lw	a5,768(a0)
    80002e90:	ebb9                	bnez	a5,80002ee6 <usertrap+0xa4>
    p->trapframe->epc += 4;
    80002e92:	3304b703          	ld	a4,816(s1)
    80002e96:	6f1c                	ld	a5,24(a4)
    80002e98:	0791                	addi	a5,a5,4
    80002e9a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ea0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ea4:	10079073          	csrw	sstatus,a5
    syscall();
    80002ea8:	00000097          	auipc	ra,0x0
    80002eac:	41a080e7          	jalr	1050(ra) # 800032c2 <syscall>
  if(p->killed)
    80002eb0:	3004a783          	lw	a5,768(s1)
    80002eb4:	18079e63          	bnez	a5,80003050 <usertrap+0x20e>
  usertrapret();
    80002eb8:	00000097          	auipc	ra,0x0
    80002ebc:	df6080e7          	jalr	-522(ra) # 80002cae <usertrapret>
}
    80002ec0:	60a6                	ld	ra,72(sp)
    80002ec2:	6406                	ld	s0,64(sp)
    80002ec4:	74e2                	ld	s1,56(sp)
    80002ec6:	7942                	ld	s2,48(sp)
    80002ec8:	79a2                	ld	s3,40(sp)
    80002eca:	7a02                	ld	s4,32(sp)
    80002ecc:	6ae2                	ld	s5,24(sp)
    80002ece:	6b42                	ld	s6,16(sp)
    80002ed0:	6ba2                	ld	s7,8(sp)
    80002ed2:	6161                	addi	sp,sp,80
    80002ed4:	8082                	ret
    panic("usertrap: Not user mode");
    80002ed6:	00005517          	auipc	a0,0x5
    80002eda:	42a50513          	addi	a0,a0,1066 # 80008300 <states.0+0x58>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	65e080e7          	jalr	1630(ra) # 8000053c <panic>
      exit(-1);
    80002ee6:	557d                	li	a0,-1
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	154080e7          	jalr	340(ra) # 8000203c <exit>
    80002ef0:	b74d                	j	80002e92 <usertrap+0x50>
  } else if((which_dev = devintr()) != 0){
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	eae080e7          	jalr	-338(ra) # 80002da0 <devintr>
    80002efa:	892a                	mv	s2,a0
    80002efc:	14051663          	bnez	a0,80003048 <usertrap+0x206>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f00:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15){
    80002f04:	47b5                	li	a5,13
    80002f06:	00f70763          	beq	a4,a5,80002f14 <usertrap+0xd2>
    80002f0a:	14202773          	csrr	a4,scause
    80002f0e:	47bd                	li	a5,15
    80002f10:	10f71063          	bne	a4,a5,80003010 <usertrap+0x1ce>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f14:	143027f3          	csrr	a5,stval
    if(r_stval() >= p->sz){
    80002f18:	3204b703          	ld	a4,800(s1)
    80002f1c:	06e7ee63          	bltu	a5,a4,80002f98 <usertrap+0x156>
    80002f20:	8926                	mv	s2,s1
    80002f22:	2d048a13          	addi	s4,s1,720
          if(r_scause() == 13){
    80002f26:	4b35                	li	s6,13
          if(r_scause() == 15){
    80002f28:	4abd                	li	s5,15
              p->killed = 1;
    80002f2a:	4b85                	li	s7,1
    80002f2c:	a00d                	j	80002f4e <usertrap+0x10c>
            if((p->mmr[i].prot & PROT_READ) == 0){
    80002f2e:	00c92783          	lw	a5,12(s2)
    80002f32:	8b89                	andi	a5,a5,2
    80002f34:	e3b1                	bnez	a5,80002f78 <usertrap+0x136>
              p->killed = 1;
    80002f36:	3174a023          	sw	s7,768(s1)
              exit(-1);
    80002f3a:	557d                	li	a0,-1
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	100080e7          	jalr	256(ra) # 8000203c <exit>
    80002f44:	a815                	j	80002f78 <usertrap+0x136>
      for(int i=0; i<MAX_MMR; i++){
    80002f46:	04890913          	addi	s2,s2,72
    80002f4a:	05490763          	beq	s2,s4,80002f98 <usertrap+0x156>
        if(p->mmr[i].valid && p->mmr[i].addr < r_stval() && p->mmr[i].addr+p->mmr[i].length > r_stval()){
    80002f4e:	89ca                	mv	s3,s2
    80002f50:	01492783          	lw	a5,20(s2)
    80002f54:	dbed                	beqz	a5,80002f46 <usertrap+0x104>
    80002f56:	00093783          	ld	a5,0(s2)
    80002f5a:	14302773          	csrr	a4,stval
    80002f5e:	fee7f4e3          	bgeu	a5,a4,80002f46 <usertrap+0x104>
    80002f62:	143026f3          	csrr	a3,stval
    80002f66:	00892703          	lw	a4,8(s2)
    80002f6a:	97ba                	add	a5,a5,a4
    80002f6c:	fcf6fde3          	bgeu	a3,a5,80002f46 <usertrap+0x104>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f70:	142027f3          	csrr	a5,scause
          if(r_scause() == 13){
    80002f74:	fb678de3          	beq	a5,s6,80002f2e <usertrap+0xec>
    80002f78:	142027f3          	csrr	a5,scause
          if(r_scause() == 15){
    80002f7c:	fd5795e3          	bne	a5,s5,80002f46 <usertrap+0x104>
            if((p->mmr[i].prot & PROT_WRITE) == 0){
    80002f80:	00c9a783          	lw	a5,12(s3)
    80002f84:	8b91                	andi	a5,a5,4
    80002f86:	f3e1                	bnez	a5,80002f46 <usertrap+0x104>
              p->killed = 1;
    80002f88:	3174a023          	sw	s7,768(s1)
              exit(-1);
    80002f8c:	557d                	li	a0,-1
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	0ae080e7          	jalr	174(ra) # 8000203c <exit>
    80002f96:	bf45                	j	80002f46 <usertrap+0x104>
      void *physical_mem = kalloc();
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	b4a080e7          	jalr	-1206(ra) # 80000ae2 <kalloc>
    80002fa0:	892a                	mv	s2,a0
      if(physical_mem){
    80002fa2:	c531                	beqz	a0,80002fee <usertrap+0x1ac>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fa4:	143025f3          	csrr	a1,stval
        if(mappages(p->pagetable, PGROUNDDOWN(r_stval()), PGSIZE, (uint64)physical_mem, (PTE_R | PTE_W | PTE_X | PTE_U)) < 0){ 
    80002fa8:	4779                	li	a4,30
    80002faa:	86aa                	mv	a3,a0
    80002fac:	6605                	lui	a2,0x1
    80002fae:	77fd                	lui	a5,0xfffff
    80002fb0:	8dfd                	and	a1,a1,a5
    80002fb2:	3284b503          	ld	a0,808(s1)
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	132080e7          	jalr	306(ra) # 800010e8 <mappages>
    80002fbe:	ee0559e3          	bgez	a0,80002eb0 <usertrap+0x6e>
          kfree(physical_mem);
    80002fc2:	854a                	mv	a0,s2
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	a20080e7          	jalr	-1504(ra) # 800009e4 <kfree>
          printf("mappages didn't work\n");
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	34c50513          	addi	a0,a0,844 # 80008318 <states.0+0x70>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	5b2080e7          	jalr	1458(ra) # 80000586 <printf>
          p->killed = 1;
    80002fdc:	4785                	li	a5,1
    80002fde:	30f4a023          	sw	a5,768(s1)
          exit(-1);
    80002fe2:	557d                	li	a0,-1
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	058080e7          	jalr	88(ra) # 8000203c <exit>
    80002fec:	b5d1                	j	80002eb0 <usertrap+0x6e>
      printf("usertrap(): Out of memory\n");
    80002fee:	00005517          	auipc	a0,0x5
    80002ff2:	34250513          	addi	a0,a0,834 # 80008330 <states.0+0x88>
    80002ff6:	ffffd097          	auipc	ra,0xffffd
    80002ffa:	590080e7          	jalr	1424(ra) # 80000586 <printf>
        p->killed = 1;
    80002ffe:	4785                	li	a5,1
    80003000:	30f4a023          	sw	a5,768(s1)
        exit(-1);
    80003004:	557d                	li	a0,-1
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	036080e7          	jalr	54(ra) # 8000203c <exit>
    8000300e:	b54d                	j	80002eb0 <usertrap+0x6e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003010:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003014:	3084a603          	lw	a2,776(s1)
    80003018:	00005517          	auipc	a0,0x5
    8000301c:	33850513          	addi	a0,a0,824 # 80008350 <states.0+0xa8>
    80003020:	ffffd097          	auipc	ra,0xffffd
    80003024:	566080e7          	jalr	1382(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003028:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000302c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003030:	00005517          	auipc	a0,0x5
    80003034:	35050513          	addi	a0,a0,848 # 80008380 <states.0+0xd8>
    80003038:	ffffd097          	auipc	ra,0xffffd
    8000303c:	54e080e7          	jalr	1358(ra) # 80000586 <printf>
    p->killed = 1;
    80003040:	4785                	li	a5,1
    80003042:	30f4a023          	sw	a5,768(s1)
  if(p->killed)
    80003046:	a031                	j	80003052 <usertrap+0x210>
    80003048:	3004a783          	lw	a5,768(s1)
    8000304c:	cb81                	beqz	a5,8000305c <usertrap+0x21a>
    8000304e:	a011                	j	80003052 <usertrap+0x210>
    80003050:	4901                	li	s2,0
    exit(-1);
    80003052:	557d                	li	a0,-1
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	fe8080e7          	jalr	-24(ra) # 8000203c <exit>
  if(which_dev == 2)
    8000305c:	4789                	li	a5,2
    8000305e:	e4f91de3          	bne	s2,a5,80002eb8 <usertrap+0x76>
    yield();
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	e42080e7          	jalr	-446(ra) # 80001ea4 <yield>
    8000306a:	b5b9                	j	80002eb8 <usertrap+0x76>

000000008000306c <kerneltrap>:
{
    8000306c:	7179                	addi	sp,sp,-48
    8000306e:	f406                	sd	ra,40(sp)
    80003070:	f022                	sd	s0,32(sp)
    80003072:	ec26                	sd	s1,24(sp)
    80003074:	e84a                	sd	s2,16(sp)
    80003076:	e44e                	sd	s3,8(sp)
    80003078:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000307a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000307e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003082:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003086:	1004f793          	andi	a5,s1,256
    8000308a:	cb85                	beqz	a5,800030ba <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000308c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003090:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003092:	ef85                	bnez	a5,800030ca <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003094:	00000097          	auipc	ra,0x0
    80003098:	d0c080e7          	jalr	-756(ra) # 80002da0 <devintr>
    8000309c:	cd1d                	beqz	a0,800030da <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000309e:	4789                	li	a5,2
    800030a0:	06f50a63          	beq	a0,a5,80003114 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030a4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030a8:	10049073          	csrw	sstatus,s1
}
    800030ac:	70a2                	ld	ra,40(sp)
    800030ae:	7402                	ld	s0,32(sp)
    800030b0:	64e2                	ld	s1,24(sp)
    800030b2:	6942                	ld	s2,16(sp)
    800030b4:	69a2                	ld	s3,8(sp)
    800030b6:	6145                	addi	sp,sp,48
    800030b8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030ba:	00005517          	auipc	a0,0x5
    800030be:	2e650513          	addi	a0,a0,742 # 800083a0 <states.0+0xf8>
    800030c2:	ffffd097          	auipc	ra,0xffffd
    800030c6:	47a080e7          	jalr	1146(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    800030ca:	00005517          	auipc	a0,0x5
    800030ce:	2fe50513          	addi	a0,a0,766 # 800083c8 <states.0+0x120>
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	46a080e7          	jalr	1130(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    800030da:	85ce                	mv	a1,s3
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	30c50513          	addi	a0,a0,780 # 800083e8 <states.0+0x140>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	4a2080e7          	jalr	1186(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030f0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030f4:	00005517          	auipc	a0,0x5
    800030f8:	30450513          	addi	a0,a0,772 # 800083f8 <states.0+0x150>
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	48a080e7          	jalr	1162(ra) # 80000586 <printf>
    panic("kerneltrap");
    80003104:	00005517          	auipc	a0,0x5
    80003108:	30c50513          	addi	a0,a0,780 # 80008410 <states.0+0x168>
    8000310c:	ffffd097          	auipc	ra,0xffffd
    80003110:	430080e7          	jalr	1072(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	9d8080e7          	jalr	-1576(ra) # 80001aec <myproc>
    8000311c:	d541                	beqz	a0,800030a4 <kerneltrap+0x38>
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	9ce080e7          	jalr	-1586(ra) # 80001aec <myproc>
    80003126:	2f052703          	lw	a4,752(a0)
    8000312a:	4791                	li	a5,4
    8000312c:	f6f71ce3          	bne	a4,a5,800030a4 <kerneltrap+0x38>
    yield();
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	d74080e7          	jalr	-652(ra) # 80001ea4 <yield>
    80003138:	b7b5                	j	800030a4 <kerneltrap+0x38>

000000008000313a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000313a:	1101                	addi	sp,sp,-32
    8000313c:	ec06                	sd	ra,24(sp)
    8000313e:	e822                	sd	s0,16(sp)
    80003140:	e426                	sd	s1,8(sp)
    80003142:	1000                	addi	s0,sp,32
    80003144:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	9a6080e7          	jalr	-1626(ra) # 80001aec <myproc>
  switch (n) {
    8000314e:	4795                	li	a5,5
    80003150:	0497e763          	bltu	a5,s1,8000319e <argraw+0x64>
    80003154:	048a                	slli	s1,s1,0x2
    80003156:	00005717          	auipc	a4,0x5
    8000315a:	2f270713          	addi	a4,a4,754 # 80008448 <states.0+0x1a0>
    8000315e:	94ba                	add	s1,s1,a4
    80003160:	409c                	lw	a5,0(s1)
    80003162:	97ba                	add	a5,a5,a4
    80003164:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003166:	33053783          	ld	a5,816(a0)
    8000316a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	64a2                	ld	s1,8(sp)
    80003172:	6105                	addi	sp,sp,32
    80003174:	8082                	ret
    return p->trapframe->a1;
    80003176:	33053783          	ld	a5,816(a0)
    8000317a:	7fa8                	ld	a0,120(a5)
    8000317c:	bfc5                	j	8000316c <argraw+0x32>
    return p->trapframe->a2;
    8000317e:	33053783          	ld	a5,816(a0)
    80003182:	63c8                	ld	a0,128(a5)
    80003184:	b7e5                	j	8000316c <argraw+0x32>
    return p->trapframe->a3;
    80003186:	33053783          	ld	a5,816(a0)
    8000318a:	67c8                	ld	a0,136(a5)
    8000318c:	b7c5                	j	8000316c <argraw+0x32>
    return p->trapframe->a4;
    8000318e:	33053783          	ld	a5,816(a0)
    80003192:	6bc8                	ld	a0,144(a5)
    80003194:	bfe1                	j	8000316c <argraw+0x32>
    return p->trapframe->a5;
    80003196:	33053783          	ld	a5,816(a0)
    8000319a:	6fc8                	ld	a0,152(a5)
    8000319c:	bfc1                	j	8000316c <argraw+0x32>
  panic("argraw");
    8000319e:	00005517          	auipc	a0,0x5
    800031a2:	28250513          	addi	a0,a0,642 # 80008420 <states.0+0x178>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	396080e7          	jalr	918(ra) # 8000053c <panic>

00000000800031ae <fetchaddr>:
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	e04a                	sd	s2,0(sp)
    800031b8:	1000                	addi	s0,sp,32
    800031ba:	84aa                	mv	s1,a0
    800031bc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031be:	fffff097          	auipc	ra,0xfffff
    800031c2:	92e080e7          	jalr	-1746(ra) # 80001aec <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031c6:	32053783          	ld	a5,800(a0)
    800031ca:	02f4f963          	bgeu	s1,a5,800031fc <fetchaddr+0x4e>
    800031ce:	00848713          	addi	a4,s1,8
    800031d2:	02e7e763          	bltu	a5,a4,80003200 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031d6:	46a1                	li	a3,8
    800031d8:	8626                	mv	a2,s1
    800031da:	85ca                	mv	a1,s2
    800031dc:	32853503          	ld	a0,808(a0)
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	5de080e7          	jalr	1502(ra) # 800017be <copyin>
    800031e8:	00a03533          	snez	a0,a0
    800031ec:	40a00533          	neg	a0,a0
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6902                	ld	s2,0(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret
    return -1;
    800031fc:	557d                	li	a0,-1
    800031fe:	bfcd                	j	800031f0 <fetchaddr+0x42>
    80003200:	557d                	li	a0,-1
    80003202:	b7fd                	j	800031f0 <fetchaddr+0x42>

0000000080003204 <fetchstr>:
{
    80003204:	7179                	addi	sp,sp,-48
    80003206:	f406                	sd	ra,40(sp)
    80003208:	f022                	sd	s0,32(sp)
    8000320a:	ec26                	sd	s1,24(sp)
    8000320c:	e84a                	sd	s2,16(sp)
    8000320e:	e44e                	sd	s3,8(sp)
    80003210:	1800                	addi	s0,sp,48
    80003212:	892a                	mv	s2,a0
    80003214:	84ae                	mv	s1,a1
    80003216:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	8d4080e7          	jalr	-1836(ra) # 80001aec <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003220:	86ce                	mv	a3,s3
    80003222:	864a                	mv	a2,s2
    80003224:	85a6                	mv	a1,s1
    80003226:	32853503          	ld	a0,808(a0)
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	622080e7          	jalr	1570(ra) # 8000184c <copyinstr>
  if(err < 0)
    80003232:	00054763          	bltz	a0,80003240 <fetchstr+0x3c>
  return strlen(buf);
    80003236:	8526                	mv	a0,s1
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	c5c080e7          	jalr	-932(ra) # 80000e94 <strlen>
}
    80003240:	70a2                	ld	ra,40(sp)
    80003242:	7402                	ld	s0,32(sp)
    80003244:	64e2                	ld	s1,24(sp)
    80003246:	6942                	ld	s2,16(sp)
    80003248:	69a2                	ld	s3,8(sp)
    8000324a:	6145                	addi	sp,sp,48
    8000324c:	8082                	ret

000000008000324e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000324e:	1101                	addi	sp,sp,-32
    80003250:	ec06                	sd	ra,24(sp)
    80003252:	e822                	sd	s0,16(sp)
    80003254:	e426                	sd	s1,8(sp)
    80003256:	1000                	addi	s0,sp,32
    80003258:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	ee0080e7          	jalr	-288(ra) # 8000313a <argraw>
    80003262:	c088                	sw	a0,0(s1)
  return 0;
}
    80003264:	4501                	li	a0,0
    80003266:	60e2                	ld	ra,24(sp)
    80003268:	6442                	ld	s0,16(sp)
    8000326a:	64a2                	ld	s1,8(sp)
    8000326c:	6105                	addi	sp,sp,32
    8000326e:	8082                	ret

0000000080003270 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	e426                	sd	s1,8(sp)
    80003278:	1000                	addi	s0,sp,32
    8000327a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000327c:	00000097          	auipc	ra,0x0
    80003280:	ebe080e7          	jalr	-322(ra) # 8000313a <argraw>
    80003284:	e088                	sd	a0,0(s1)
  return 0;
}
    80003286:	4501                	li	a0,0
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	64a2                	ld	s1,8(sp)
    8000328e:	6105                	addi	sp,sp,32
    80003290:	8082                	ret

0000000080003292 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003292:	1101                	addi	sp,sp,-32
    80003294:	ec06                	sd	ra,24(sp)
    80003296:	e822                	sd	s0,16(sp)
    80003298:	e426                	sd	s1,8(sp)
    8000329a:	e04a                	sd	s2,0(sp)
    8000329c:	1000                	addi	s0,sp,32
    8000329e:	84ae                	mv	s1,a1
    800032a0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	e98080e7          	jalr	-360(ra) # 8000313a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032aa:	864a                	mv	a2,s2
    800032ac:	85a6                	mv	a1,s1
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	f56080e7          	jalr	-170(ra) # 80003204 <fetchstr>
}
    800032b6:	60e2                	ld	ra,24(sp)
    800032b8:	6442                	ld	s0,16(sp)
    800032ba:	64a2                	ld	s1,8(sp)
    800032bc:	6902                	ld	s2,0(sp)
    800032be:	6105                	addi	sp,sp,32
    800032c0:	8082                	ret

00000000800032c2 <syscall>:
[SYS_munmap] sys_munmap,
};

void
syscall(void)
{
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	e04a                	sd	s2,0(sp)
    800032cc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	81e080e7          	jalr	-2018(ra) # 80001aec <myproc>
    800032d6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032d8:	33053903          	ld	s2,816(a0)
    800032dc:	0a893783          	ld	a5,168(s2)
    800032e0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032e4:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffc8fff>
    800032e6:	4761                	li	a4,24
    800032e8:	00f76f63          	bltu	a4,a5,80003306 <syscall+0x44>
    800032ec:	00369713          	slli	a4,a3,0x3
    800032f0:	00005797          	auipc	a5,0x5
    800032f4:	17078793          	addi	a5,a5,368 # 80008460 <syscalls>
    800032f8:	97ba                	add	a5,a5,a4
    800032fa:	639c                	ld	a5,0(a5)
    800032fc:	c789                	beqz	a5,80003306 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032fe:	9782                	jalr	a5
    80003300:	06a93823          	sd	a0,112(s2)
    80003304:	a00d                	j	80003326 <syscall+0x64>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003306:	43048613          	addi	a2,s1,1072
    8000330a:	3084a583          	lw	a1,776(s1)
    8000330e:	00005517          	auipc	a0,0x5
    80003312:	11a50513          	addi	a0,a0,282 # 80008428 <states.0+0x180>
    80003316:	ffffd097          	auipc	ra,0xffffd
    8000331a:	270080e7          	jalr	624(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000331e:	3304b783          	ld	a5,816(s1)
    80003322:	577d                	li	a4,-1
    80003324:	fbb8                	sd	a4,112(a5)
  }
}
    80003326:	60e2                	ld	ra,24(sp)
    80003328:	6442                	ld	s0,16(sp)
    8000332a:	64a2                	ld	s1,8(sp)
    8000332c:	6902                	ld	s2,0(sp)
    8000332e:	6105                	addi	sp,sp,32
    80003330:	8082                	ret

0000000080003332 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003332:	1101                	addi	sp,sp,-32
    80003334:	ec06                	sd	ra,24(sp)
    80003336:	e822                	sd	s0,16(sp)
    80003338:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000333a:	fec40593          	addi	a1,s0,-20
    8000333e:	4501                	li	a0,0
    80003340:	00000097          	auipc	ra,0x0
    80003344:	f0e080e7          	jalr	-242(ra) # 8000324e <argint>
    return -1;
    80003348:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000334a:	00054963          	bltz	a0,8000335c <sys_exit+0x2a>
  exit(n);
    8000334e:	fec42503          	lw	a0,-20(s0)
    80003352:	fffff097          	auipc	ra,0xfffff
    80003356:	cea080e7          	jalr	-790(ra) # 8000203c <exit>
  return 0;  // not reached
    8000335a:	4781                	li	a5,0
}
    8000335c:	853e                	mv	a0,a5
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	6105                	addi	sp,sp,32
    80003364:	8082                	ret

0000000080003366 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003366:	1141                	addi	sp,sp,-16
    80003368:	e406                	sd	ra,8(sp)
    8000336a:	e022                	sd	s0,0(sp)
    8000336c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	77e080e7          	jalr	1918(ra) # 80001aec <myproc>
}
    80003376:	30852503          	lw	a0,776(a0)
    8000337a:	60a2                	ld	ra,8(sp)
    8000337c:	6402                	ld	s0,0(sp)
    8000337e:	0141                	addi	sp,sp,16
    80003380:	8082                	ret

0000000080003382 <sys_fork>:

uint64
sys_fork(void)
{
    80003382:	1141                	addi	sp,sp,-16
    80003384:	e406                	sd	ra,8(sp)
    80003386:	e022                	sd	s0,0(sp)
    80003388:	0800                	addi	s0,sp,16
  return fork();
    8000338a:	fffff097          	auipc	ra,0xfffff
    8000338e:	414080e7          	jalr	1044(ra) # 8000279e <fork>
}
    80003392:	60a2                	ld	ra,8(sp)
    80003394:	6402                	ld	s0,0(sp)
    80003396:	0141                	addi	sp,sp,16
    80003398:	8082                	ret

000000008000339a <sys_wait>:

uint64
sys_wait(void)
{
    8000339a:	1101                	addi	sp,sp,-32
    8000339c:	ec06                	sd	ra,24(sp)
    8000339e:	e822                	sd	s0,16(sp)
    800033a0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033a2:	fe840593          	addi	a1,s0,-24
    800033a6:	4501                	li	a0,0
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	ec8080e7          	jalr	-312(ra) # 80003270 <argaddr>
    800033b0:	87aa                	mv	a5,a0
    return -1;
    800033b2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033b4:	0007c863          	bltz	a5,800033c4 <sys_wait+0x2a>
  return wait(p);
    800033b8:	fe843503          	ld	a0,-24(s0)
    800033bc:	fffff097          	auipc	ra,0xfffff
    800033c0:	6ac080e7          	jalr	1708(ra) # 80002a68 <wait>
}
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	6105                	addi	sp,sp,32
    800033ca:	8082                	ret

00000000800033cc <sys_sleep>:

uint64
sys_sleep(void)
{
    800033cc:	7139                	addi	sp,sp,-64
    800033ce:	fc06                	sd	ra,56(sp)
    800033d0:	f822                	sd	s0,48(sp)
    800033d2:	f426                	sd	s1,40(sp)
    800033d4:	f04a                	sd	s2,32(sp)
    800033d6:	ec4e                	sd	s3,24(sp)
    800033d8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033da:	fcc40593          	addi	a1,s0,-52
    800033de:	4501                	li	a0,0
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	e6e080e7          	jalr	-402(ra) # 8000324e <argint>
    return -1;
    800033e8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033ea:	06054663          	bltz	a0,80003456 <sys_sleep+0x8a>
  acquire(&tickslock);
    800033ee:	00024517          	auipc	a0,0x24
    800033f2:	2fa50513          	addi	a0,a0,762 # 800276e8 <tickslock>
    800033f6:	ffffe097          	auipc	ra,0xffffe
    800033fa:	826080e7          	jalr	-2010(ra) # 80000c1c <acquire>
  ticks0 = ticks;
    800033fe:	00006917          	auipc	s2,0x6
    80003402:	c3292903          	lw	s2,-974(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003406:	fcc42783          	lw	a5,-52(s0)
    8000340a:	cf8d                	beqz	a5,80003444 <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000340c:	00024997          	auipc	s3,0x24
    80003410:	2dc98993          	addi	s3,s3,732 # 800276e8 <tickslock>
    80003414:	00006497          	auipc	s1,0x6
    80003418:	c1c48493          	addi	s1,s1,-996 # 80009030 <ticks>
    if(myproc()->killed){
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	6d0080e7          	jalr	1744(ra) # 80001aec <myproc>
    80003424:	30052783          	lw	a5,768(a0)
    80003428:	ef9d                	bnez	a5,80003466 <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    8000342a:	85ce                	mv	a1,s3
    8000342c:	8526                	mv	a0,s1
    8000342e:	fffff097          	auipc	ra,0xfffff
    80003432:	abe080e7          	jalr	-1346(ra) # 80001eec <sleep>
  while(ticks - ticks0 < n){
    80003436:	409c                	lw	a5,0(s1)
    80003438:	412787bb          	subw	a5,a5,s2
    8000343c:	fcc42703          	lw	a4,-52(s0)
    80003440:	fce7eee3          	bltu	a5,a4,8000341c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003444:	00024517          	auipc	a0,0x24
    80003448:	2a450513          	addi	a0,a0,676 # 800276e8 <tickslock>
    8000344c:	ffffe097          	auipc	ra,0xffffe
    80003450:	884080e7          	jalr	-1916(ra) # 80000cd0 <release>
  return 0;
    80003454:	4781                	li	a5,0
}
    80003456:	853e                	mv	a0,a5
    80003458:	70e2                	ld	ra,56(sp)
    8000345a:	7442                	ld	s0,48(sp)
    8000345c:	74a2                	ld	s1,40(sp)
    8000345e:	7902                	ld	s2,32(sp)
    80003460:	69e2                	ld	s3,24(sp)
    80003462:	6121                	addi	sp,sp,64
    80003464:	8082                	ret
      release(&tickslock);
    80003466:	00024517          	auipc	a0,0x24
    8000346a:	28250513          	addi	a0,a0,642 # 800276e8 <tickslock>
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	862080e7          	jalr	-1950(ra) # 80000cd0 <release>
      return -1;
    80003476:	57fd                	li	a5,-1
    80003478:	bff9                	j	80003456 <sys_sleep+0x8a>

000000008000347a <sys_kill>:

uint64
sys_kill(void)
{
    8000347a:	1101                	addi	sp,sp,-32
    8000347c:	ec06                	sd	ra,24(sp)
    8000347e:	e822                	sd	s0,16(sp)
    80003480:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003482:	fec40593          	addi	a1,s0,-20
    80003486:	4501                	li	a0,0
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	dc6080e7          	jalr	-570(ra) # 8000324e <argint>
    80003490:	87aa                	mv	a5,a0
    return -1;
    80003492:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003494:	0007c863          	bltz	a5,800034a4 <sys_kill+0x2a>
  return kill(pid);
    80003498:	fec42503          	lw	a0,-20(s0)
    8000349c:	fffff097          	auipc	ra,0xfffff
    800034a0:	c78080e7          	jalr	-904(ra) # 80002114 <kill>
}
    800034a4:	60e2                	ld	ra,24(sp)
    800034a6:	6442                	ld	s0,16(sp)
    800034a8:	6105                	addi	sp,sp,32
    800034aa:	8082                	ret

00000000800034ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034ac:	1101                	addi	sp,sp,-32
    800034ae:	ec06                	sd	ra,24(sp)
    800034b0:	e822                	sd	s0,16(sp)
    800034b2:	e426                	sd	s1,8(sp)
    800034b4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034b6:	00024517          	auipc	a0,0x24
    800034ba:	23250513          	addi	a0,a0,562 # 800276e8 <tickslock>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	75e080e7          	jalr	1886(ra) # 80000c1c <acquire>
  xticks = ticks;
    800034c6:	00006497          	auipc	s1,0x6
    800034ca:	b6a4a483          	lw	s1,-1174(s1) # 80009030 <ticks>
  release(&tickslock);
    800034ce:	00024517          	auipc	a0,0x24
    800034d2:	21a50513          	addi	a0,a0,538 # 800276e8 <tickslock>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7fa080e7          	jalr	2042(ra) # 80000cd0 <release>
  return xticks;
}
    800034de:	02049513          	slli	a0,s1,0x20
    800034e2:	9101                	srli	a0,a0,0x20
    800034e4:	60e2                	ld	ra,24(sp)
    800034e6:	6442                	ld	s0,16(sp)
    800034e8:	64a2                	ld	s1,8(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret

00000000800034ee <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    800034ee:	1101                	addi	sp,sp,-32
    800034f0:	ec06                	sd	ra,24(sp)
    800034f2:	e822                	sd	s0,16(sp)
    800034f4:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    800034f6:	fe840593          	addi	a1,s0,-24
    800034fa:	4501                	li	a0,0
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	d74080e7          	jalr	-652(ra) # 80003270 <argaddr>
    80003504:	87aa                	mv	a5,a0
    return -1;
    80003506:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80003508:	0007c863          	bltz	a5,80003518 <sys_getprocs+0x2a>
  return(procinfo(addr));
    8000350c:	fe843503          	ld	a0,-24(s0)
    80003510:	fffff097          	auipc	ra,0xfffff
    80003514:	de6080e7          	jalr	-538(ra) # 800022f6 <procinfo>
}
    80003518:	60e2                	ld	ra,24(sp)
    8000351a:	6442                	ld	s0,16(sp)
    8000351c:	6105                	addi	sp,sp,32
    8000351e:	8082                	ret

0000000080003520 <sys_freepmem>:

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
    80003520:	1141                	addi	sp,sp,-16
    80003522:	e406                	sd	ra,8(sp)
    80003524:	e022                	sd	s0,0(sp)
    80003526:	0800                	addi	s0,sp,16
  int res = freepmem();
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	61a080e7          	jalr	1562(ra) # 80000b42 <freepmem>
  return res;
}
    80003530:	2501                	sext.w	a0,a0
    80003532:	60a2                	ld	ra,8(sp)
    80003534:	6402                	ld	s0,0(sp)
    80003536:	0141                	addi	sp,sp,16
    80003538:	8082                	ret

000000008000353a <sys_sbrk>:

// HW 4 - Task 2
// system call to allocate VIRTUAL memory on the disk
uint64
sys_sbrk(void){
    8000353a:	7179                	addi	sp,sp,-48
    8000353c:	f406                	sd	ra,40(sp)
    8000353e:	f022                	sd	s0,32(sp)
    80003540:	ec26                	sd	s1,24(sp)
    80003542:	e84a                	sd	s2,16(sp)
    80003544:	1800                	addi	s0,sp,48
  int new_size;
  int increment;

  // Retrieve the first system call argument, which is the number 
  // of bytes to increase the heap by, and store it in 'increment'
  if(argint(0, &increment) < 0){
    80003546:	fdc40593          	addi	a1,s0,-36
    8000354a:	4501                	li	a0,0
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	d02080e7          	jalr	-766(ra) # 8000324e <argint>
    80003554:	87aa                	mv	a5,a0
    return -1;
    80003556:	557d                	li	a0,-1
  if(argint(0, &increment) < 0){
    80003558:	0207c363          	bltz	a5,8000357e <sys_sbrk+0x44>
  }

  // Get the current size of the process's heap from its process structure.]
  curr_size = myproc()->sz;
    8000355c:	ffffe097          	auipc	ra,0xffffe
    80003560:	590080e7          	jalr	1424(ra) # 80001aec <myproc>
    80003564:	32052483          	lw	s1,800(a0)

  // Calculate the new size of the heap by adding 'increment' to the current size
  new_size = curr_size + increment;
    80003568:	fdc42903          	lw	s2,-36(s0)
    8000356c:	0099093b          	addw	s2,s2,s1

  // Check if the new size is below a memory safety threshold ('TRAPFRAME')
  // This is to ensure the heap does not overlap with the trap frame
  if(new_size < TRAPFRAME){
    // If the new size is valid, update the process's heap size to -> new_size
    myproc()->sz = new_size;
    80003570:	ffffe097          	auipc	ra,0xffffe
    80003574:	57c080e7          	jalr	1404(ra) # 80001aec <myproc>
    80003578:	33253023          	sd	s2,800(a0)
    
    // Return the old heap end address before the increment
    return curr_size;
    8000357c:	8526                	mv	a0,s1
  }

  // If the new size is not valid or exceeds the memory safety threshold
  return -1;
}
    8000357e:	70a2                	ld	ra,40(sp)
    80003580:	7402                	ld	s0,32(sp)
    80003582:	64e2                	ld	s1,24(sp)
    80003584:	6942                	ld	s2,16(sp)
    80003586:	6145                	addi	sp,sp,48
    80003588:	8082                	ret

000000008000358a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000358a:	7179                	addi	sp,sp,-48
    8000358c:	f406                	sd	ra,40(sp)
    8000358e:	f022                	sd	s0,32(sp)
    80003590:	ec26                	sd	s1,24(sp)
    80003592:	e84a                	sd	s2,16(sp)
    80003594:	e44e                	sd	s3,8(sp)
    80003596:	e052                	sd	s4,0(sp)
    80003598:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000359a:	00005597          	auipc	a1,0x5
    8000359e:	f9658593          	addi	a1,a1,-106 # 80008530 <syscalls+0xd0>
    800035a2:	00024517          	auipc	a0,0x24
    800035a6:	15e50513          	addi	a0,a0,350 # 80027700 <bcache>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	5e2080e7          	jalr	1506(ra) # 80000b8c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035b2:	0002c797          	auipc	a5,0x2c
    800035b6:	14e78793          	addi	a5,a5,334 # 8002f700 <bcache+0x8000>
    800035ba:	0002c717          	auipc	a4,0x2c
    800035be:	3ae70713          	addi	a4,a4,942 # 8002f968 <bcache+0x8268>
    800035c2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035c6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035ca:	00024497          	auipc	s1,0x24
    800035ce:	14e48493          	addi	s1,s1,334 # 80027718 <bcache+0x18>
    b->next = bcache.head.next;
    800035d2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035d4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035d6:	00005a17          	auipc	s4,0x5
    800035da:	f62a0a13          	addi	s4,s4,-158 # 80008538 <syscalls+0xd8>
    b->next = bcache.head.next;
    800035de:	2b893783          	ld	a5,696(s2)
    800035e2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035e4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035e8:	85d2                	mv	a1,s4
    800035ea:	01048513          	addi	a0,s1,16
    800035ee:	00001097          	auipc	ra,0x1
    800035f2:	4c2080e7          	jalr	1218(ra) # 80004ab0 <initsleeplock>
    bcache.head.next->prev = b;
    800035f6:	2b893783          	ld	a5,696(s2)
    800035fa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035fc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003600:	45848493          	addi	s1,s1,1112
    80003604:	fd349de3          	bne	s1,s3,800035de <binit+0x54>
  }
}
    80003608:	70a2                	ld	ra,40(sp)
    8000360a:	7402                	ld	s0,32(sp)
    8000360c:	64e2                	ld	s1,24(sp)
    8000360e:	6942                	ld	s2,16(sp)
    80003610:	69a2                	ld	s3,8(sp)
    80003612:	6a02                	ld	s4,0(sp)
    80003614:	6145                	addi	sp,sp,48
    80003616:	8082                	ret

0000000080003618 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003618:	7179                	addi	sp,sp,-48
    8000361a:	f406                	sd	ra,40(sp)
    8000361c:	f022                	sd	s0,32(sp)
    8000361e:	ec26                	sd	s1,24(sp)
    80003620:	e84a                	sd	s2,16(sp)
    80003622:	e44e                	sd	s3,8(sp)
    80003624:	1800                	addi	s0,sp,48
    80003626:	892a                	mv	s2,a0
    80003628:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000362a:	00024517          	auipc	a0,0x24
    8000362e:	0d650513          	addi	a0,a0,214 # 80027700 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	5ea080e7          	jalr	1514(ra) # 80000c1c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000363a:	0002c497          	auipc	s1,0x2c
    8000363e:	37e4b483          	ld	s1,894(s1) # 8002f9b8 <bcache+0x82b8>
    80003642:	0002c797          	auipc	a5,0x2c
    80003646:	32678793          	addi	a5,a5,806 # 8002f968 <bcache+0x8268>
    8000364a:	02f48f63          	beq	s1,a5,80003688 <bread+0x70>
    8000364e:	873e                	mv	a4,a5
    80003650:	a021                	j	80003658 <bread+0x40>
    80003652:	68a4                	ld	s1,80(s1)
    80003654:	02e48a63          	beq	s1,a4,80003688 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003658:	449c                	lw	a5,8(s1)
    8000365a:	ff279ce3          	bne	a5,s2,80003652 <bread+0x3a>
    8000365e:	44dc                	lw	a5,12(s1)
    80003660:	ff3799e3          	bne	a5,s3,80003652 <bread+0x3a>
      b->refcnt++;
    80003664:	40bc                	lw	a5,64(s1)
    80003666:	2785                	addiw	a5,a5,1
    80003668:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000366a:	00024517          	auipc	a0,0x24
    8000366e:	09650513          	addi	a0,a0,150 # 80027700 <bcache>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	65e080e7          	jalr	1630(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    8000367a:	01048513          	addi	a0,s1,16
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	46c080e7          	jalr	1132(ra) # 80004aea <acquiresleep>
      return b;
    80003686:	a8b9                	j	800036e4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003688:	0002c497          	auipc	s1,0x2c
    8000368c:	3284b483          	ld	s1,808(s1) # 8002f9b0 <bcache+0x82b0>
    80003690:	0002c797          	auipc	a5,0x2c
    80003694:	2d878793          	addi	a5,a5,728 # 8002f968 <bcache+0x8268>
    80003698:	00f48863          	beq	s1,a5,800036a8 <bread+0x90>
    8000369c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000369e:	40bc                	lw	a5,64(s1)
    800036a0:	cf81                	beqz	a5,800036b8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036a2:	64a4                	ld	s1,72(s1)
    800036a4:	fee49de3          	bne	s1,a4,8000369e <bread+0x86>
  panic("bget: no buffers");
    800036a8:	00005517          	auipc	a0,0x5
    800036ac:	e9850513          	addi	a0,a0,-360 # 80008540 <syscalls+0xe0>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	e8c080e7          	jalr	-372(ra) # 8000053c <panic>
      b->dev = dev;
    800036b8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800036bc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800036c0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036c4:	4785                	li	a5,1
    800036c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036c8:	00024517          	auipc	a0,0x24
    800036cc:	03850513          	addi	a0,a0,56 # 80027700 <bcache>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	600080e7          	jalr	1536(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    800036d8:	01048513          	addi	a0,s1,16
    800036dc:	00001097          	auipc	ra,0x1
    800036e0:	40e080e7          	jalr	1038(ra) # 80004aea <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036e4:	409c                	lw	a5,0(s1)
    800036e6:	cb89                	beqz	a5,800036f8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036e8:	8526                	mv	a0,s1
    800036ea:	70a2                	ld	ra,40(sp)
    800036ec:	7402                	ld	s0,32(sp)
    800036ee:	64e2                	ld	s1,24(sp)
    800036f0:	6942                	ld	s2,16(sp)
    800036f2:	69a2                	ld	s3,8(sp)
    800036f4:	6145                	addi	sp,sp,48
    800036f6:	8082                	ret
    virtio_disk_rw(b, 0);
    800036f8:	4581                	li	a1,0
    800036fa:	8526                	mv	a0,s1
    800036fc:	00003097          	auipc	ra,0x3
    80003700:	1e6080e7          	jalr	486(ra) # 800068e2 <virtio_disk_rw>
    b->valid = 1;
    80003704:	4785                	li	a5,1
    80003706:	c09c                	sw	a5,0(s1)
  return b;
    80003708:	b7c5                	j	800036e8 <bread+0xd0>

000000008000370a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	1000                	addi	s0,sp,32
    80003714:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003716:	0541                	addi	a0,a0,16
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	46e080e7          	jalr	1134(ra) # 80004b86 <holdingsleep>
    80003720:	cd01                	beqz	a0,80003738 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003722:	4585                	li	a1,1
    80003724:	8526                	mv	a0,s1
    80003726:	00003097          	auipc	ra,0x3
    8000372a:	1bc080e7          	jalr	444(ra) # 800068e2 <virtio_disk_rw>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6105                	addi	sp,sp,32
    80003736:	8082                	ret
    panic("bwrite");
    80003738:	00005517          	auipc	a0,0x5
    8000373c:	e2050513          	addi	a0,a0,-480 # 80008558 <syscalls+0xf8>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	dfc080e7          	jalr	-516(ra) # 8000053c <panic>

0000000080003748 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003748:	1101                	addi	sp,sp,-32
    8000374a:	ec06                	sd	ra,24(sp)
    8000374c:	e822                	sd	s0,16(sp)
    8000374e:	e426                	sd	s1,8(sp)
    80003750:	e04a                	sd	s2,0(sp)
    80003752:	1000                	addi	s0,sp,32
    80003754:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003756:	01050913          	addi	s2,a0,16
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	42a080e7          	jalr	1066(ra) # 80004b86 <holdingsleep>
    80003764:	c92d                	beqz	a0,800037d6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003766:	854a                	mv	a0,s2
    80003768:	00001097          	auipc	ra,0x1
    8000376c:	3da080e7          	jalr	986(ra) # 80004b42 <releasesleep>

  acquire(&bcache.lock);
    80003770:	00024517          	auipc	a0,0x24
    80003774:	f9050513          	addi	a0,a0,-112 # 80027700 <bcache>
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	4a4080e7          	jalr	1188(ra) # 80000c1c <acquire>
  b->refcnt--;
    80003780:	40bc                	lw	a5,64(s1)
    80003782:	37fd                	addiw	a5,a5,-1
    80003784:	0007871b          	sext.w	a4,a5
    80003788:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000378a:	eb05                	bnez	a4,800037ba <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000378c:	68bc                	ld	a5,80(s1)
    8000378e:	64b8                	ld	a4,72(s1)
    80003790:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003792:	64bc                	ld	a5,72(s1)
    80003794:	68b8                	ld	a4,80(s1)
    80003796:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003798:	0002c797          	auipc	a5,0x2c
    8000379c:	f6878793          	addi	a5,a5,-152 # 8002f700 <bcache+0x8000>
    800037a0:	2b87b703          	ld	a4,696(a5)
    800037a4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037a6:	0002c717          	auipc	a4,0x2c
    800037aa:	1c270713          	addi	a4,a4,450 # 8002f968 <bcache+0x8268>
    800037ae:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037b0:	2b87b703          	ld	a4,696(a5)
    800037b4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037b6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037ba:	00024517          	auipc	a0,0x24
    800037be:	f4650513          	addi	a0,a0,-186 # 80027700 <bcache>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	50e080e7          	jalr	1294(ra) # 80000cd0 <release>
}
    800037ca:	60e2                	ld	ra,24(sp)
    800037cc:	6442                	ld	s0,16(sp)
    800037ce:	64a2                	ld	s1,8(sp)
    800037d0:	6902                	ld	s2,0(sp)
    800037d2:	6105                	addi	sp,sp,32
    800037d4:	8082                	ret
    panic("brelse");
    800037d6:	00005517          	auipc	a0,0x5
    800037da:	d8a50513          	addi	a0,a0,-630 # 80008560 <syscalls+0x100>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	d5e080e7          	jalr	-674(ra) # 8000053c <panic>

00000000800037e6 <bpin>:

void
bpin(struct buf *b) {
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	e426                	sd	s1,8(sp)
    800037ee:	1000                	addi	s0,sp,32
    800037f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037f2:	00024517          	auipc	a0,0x24
    800037f6:	f0e50513          	addi	a0,a0,-242 # 80027700 <bcache>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	422080e7          	jalr	1058(ra) # 80000c1c <acquire>
  b->refcnt++;
    80003802:	40bc                	lw	a5,64(s1)
    80003804:	2785                	addiw	a5,a5,1
    80003806:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003808:	00024517          	auipc	a0,0x24
    8000380c:	ef850513          	addi	a0,a0,-264 # 80027700 <bcache>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	4c0080e7          	jalr	1216(ra) # 80000cd0 <release>
}
    80003818:	60e2                	ld	ra,24(sp)
    8000381a:	6442                	ld	s0,16(sp)
    8000381c:	64a2                	ld	s1,8(sp)
    8000381e:	6105                	addi	sp,sp,32
    80003820:	8082                	ret

0000000080003822 <bunpin>:

void
bunpin(struct buf *b) {
    80003822:	1101                	addi	sp,sp,-32
    80003824:	ec06                	sd	ra,24(sp)
    80003826:	e822                	sd	s0,16(sp)
    80003828:	e426                	sd	s1,8(sp)
    8000382a:	1000                	addi	s0,sp,32
    8000382c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000382e:	00024517          	auipc	a0,0x24
    80003832:	ed250513          	addi	a0,a0,-302 # 80027700 <bcache>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	3e6080e7          	jalr	998(ra) # 80000c1c <acquire>
  b->refcnt--;
    8000383e:	40bc                	lw	a5,64(s1)
    80003840:	37fd                	addiw	a5,a5,-1
    80003842:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003844:	00024517          	auipc	a0,0x24
    80003848:	ebc50513          	addi	a0,a0,-324 # 80027700 <bcache>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	484080e7          	jalr	1156(ra) # 80000cd0 <release>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	64a2                	ld	s1,8(sp)
    8000385a:	6105                	addi	sp,sp,32
    8000385c:	8082                	ret

000000008000385e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000385e:	1101                	addi	sp,sp,-32
    80003860:	ec06                	sd	ra,24(sp)
    80003862:	e822                	sd	s0,16(sp)
    80003864:	e426                	sd	s1,8(sp)
    80003866:	e04a                	sd	s2,0(sp)
    80003868:	1000                	addi	s0,sp,32
    8000386a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000386c:	00d5d59b          	srliw	a1,a1,0xd
    80003870:	0002c797          	auipc	a5,0x2c
    80003874:	56c7a783          	lw	a5,1388(a5) # 8002fddc <sb+0x1c>
    80003878:	9dbd                	addw	a1,a1,a5
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	d9e080e7          	jalr	-610(ra) # 80003618 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003882:	0074f713          	andi	a4,s1,7
    80003886:	4785                	li	a5,1
    80003888:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000388c:	14ce                	slli	s1,s1,0x33
    8000388e:	90d9                	srli	s1,s1,0x36
    80003890:	00950733          	add	a4,a0,s1
    80003894:	05874703          	lbu	a4,88(a4)
    80003898:	00e7f6b3          	and	a3,a5,a4
    8000389c:	c69d                	beqz	a3,800038ca <bfree+0x6c>
    8000389e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038a0:	94aa                	add	s1,s1,a0
    800038a2:	fff7c793          	not	a5,a5
    800038a6:	8f7d                	and	a4,a4,a5
    800038a8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800038ac:	00001097          	auipc	ra,0x1
    800038b0:	120080e7          	jalr	288(ra) # 800049cc <log_write>
  brelse(bp);
    800038b4:	854a                	mv	a0,s2
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	e92080e7          	jalr	-366(ra) # 80003748 <brelse>
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6902                	ld	s2,0(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret
    panic("freeing free block");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	c9e50513          	addi	a0,a0,-866 # 80008568 <syscalls+0x108>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	c6a080e7          	jalr	-918(ra) # 8000053c <panic>

00000000800038da <balloc>:
{
    800038da:	711d                	addi	sp,sp,-96
    800038dc:	ec86                	sd	ra,88(sp)
    800038de:	e8a2                	sd	s0,80(sp)
    800038e0:	e4a6                	sd	s1,72(sp)
    800038e2:	e0ca                	sd	s2,64(sp)
    800038e4:	fc4e                	sd	s3,56(sp)
    800038e6:	f852                	sd	s4,48(sp)
    800038e8:	f456                	sd	s5,40(sp)
    800038ea:	f05a                	sd	s6,32(sp)
    800038ec:	ec5e                	sd	s7,24(sp)
    800038ee:	e862                	sd	s8,16(sp)
    800038f0:	e466                	sd	s9,8(sp)
    800038f2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038f4:	0002c797          	auipc	a5,0x2c
    800038f8:	4d07a783          	lw	a5,1232(a5) # 8002fdc4 <sb+0x4>
    800038fc:	cbc1                	beqz	a5,8000398c <balloc+0xb2>
    800038fe:	8baa                	mv	s7,a0
    80003900:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003902:	0002cb17          	auipc	s6,0x2c
    80003906:	4beb0b13          	addi	s6,s6,1214 # 8002fdc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000390a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000390c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000390e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003910:	6c89                	lui	s9,0x2
    80003912:	a831                	j	8000392e <balloc+0x54>
    brelse(bp);
    80003914:	854a                	mv	a0,s2
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	e32080e7          	jalr	-462(ra) # 80003748 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000391e:	015c87bb          	addw	a5,s9,s5
    80003922:	00078a9b          	sext.w	s5,a5
    80003926:	004b2703          	lw	a4,4(s6)
    8000392a:	06eaf163          	bgeu	s5,a4,8000398c <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000392e:	41fad79b          	sraiw	a5,s5,0x1f
    80003932:	0137d79b          	srliw	a5,a5,0x13
    80003936:	015787bb          	addw	a5,a5,s5
    8000393a:	40d7d79b          	sraiw	a5,a5,0xd
    8000393e:	01cb2583          	lw	a1,28(s6)
    80003942:	9dbd                	addw	a1,a1,a5
    80003944:	855e                	mv	a0,s7
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	cd2080e7          	jalr	-814(ra) # 80003618 <bread>
    8000394e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003950:	004b2503          	lw	a0,4(s6)
    80003954:	000a849b          	sext.w	s1,s5
    80003958:	8762                	mv	a4,s8
    8000395a:	faa4fde3          	bgeu	s1,a0,80003914 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000395e:	00777693          	andi	a3,a4,7
    80003962:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003966:	41f7579b          	sraiw	a5,a4,0x1f
    8000396a:	01d7d79b          	srliw	a5,a5,0x1d
    8000396e:	9fb9                	addw	a5,a5,a4
    80003970:	4037d79b          	sraiw	a5,a5,0x3
    80003974:	00f90633          	add	a2,s2,a5
    80003978:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000397c:	00c6f5b3          	and	a1,a3,a2
    80003980:	cd91                	beqz	a1,8000399c <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003982:	2705                	addiw	a4,a4,1
    80003984:	2485                	addiw	s1,s1,1
    80003986:	fd471ae3          	bne	a4,s4,8000395a <balloc+0x80>
    8000398a:	b769                	j	80003914 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	bf450513          	addi	a0,a0,-1036 # 80008580 <syscalls+0x120>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	ba8080e7          	jalr	-1112(ra) # 8000053c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000399c:	97ca                	add	a5,a5,s2
    8000399e:	8e55                	or	a2,a2,a3
    800039a0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800039a4:	854a                	mv	a0,s2
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	026080e7          	jalr	38(ra) # 800049cc <log_write>
        brelse(bp);
    800039ae:	854a                	mv	a0,s2
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	d98080e7          	jalr	-616(ra) # 80003748 <brelse>
  bp = bread(dev, bno);
    800039b8:	85a6                	mv	a1,s1
    800039ba:	855e                	mv	a0,s7
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	c5c080e7          	jalr	-932(ra) # 80003618 <bread>
    800039c4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039c6:	40000613          	li	a2,1024
    800039ca:	4581                	li	a1,0
    800039cc:	05850513          	addi	a0,a0,88
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	348080e7          	jalr	840(ra) # 80000d18 <memset>
  log_write(bp);
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	ff2080e7          	jalr	-14(ra) # 800049cc <log_write>
  brelse(bp);
    800039e2:	854a                	mv	a0,s2
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	d64080e7          	jalr	-668(ra) # 80003748 <brelse>
}
    800039ec:	8526                	mv	a0,s1
    800039ee:	60e6                	ld	ra,88(sp)
    800039f0:	6446                	ld	s0,80(sp)
    800039f2:	64a6                	ld	s1,72(sp)
    800039f4:	6906                	ld	s2,64(sp)
    800039f6:	79e2                	ld	s3,56(sp)
    800039f8:	7a42                	ld	s4,48(sp)
    800039fa:	7aa2                	ld	s5,40(sp)
    800039fc:	7b02                	ld	s6,32(sp)
    800039fe:	6be2                	ld	s7,24(sp)
    80003a00:	6c42                	ld	s8,16(sp)
    80003a02:	6ca2                	ld	s9,8(sp)
    80003a04:	6125                	addi	sp,sp,96
    80003a06:	8082                	ret

0000000080003a08 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a08:	7179                	addi	sp,sp,-48
    80003a0a:	f406                	sd	ra,40(sp)
    80003a0c:	f022                	sd	s0,32(sp)
    80003a0e:	ec26                	sd	s1,24(sp)
    80003a10:	e84a                	sd	s2,16(sp)
    80003a12:	e44e                	sd	s3,8(sp)
    80003a14:	e052                	sd	s4,0(sp)
    80003a16:	1800                	addi	s0,sp,48
    80003a18:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a1a:	47ad                	li	a5,11
    80003a1c:	04b7fe63          	bgeu	a5,a1,80003a78 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a20:	ff45849b          	addiw	s1,a1,-12
    80003a24:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a28:	0ff00793          	li	a5,255
    80003a2c:	0ae7e463          	bltu	a5,a4,80003ad4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a30:	08052583          	lw	a1,128(a0)
    80003a34:	c5b5                	beqz	a1,80003aa0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a36:	00092503          	lw	a0,0(s2)
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	bde080e7          	jalr	-1058(ra) # 80003618 <bread>
    80003a42:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a44:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a48:	02049713          	slli	a4,s1,0x20
    80003a4c:	01e75593          	srli	a1,a4,0x1e
    80003a50:	00b784b3          	add	s1,a5,a1
    80003a54:	0004a983          	lw	s3,0(s1)
    80003a58:	04098e63          	beqz	s3,80003ab4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a5c:	8552                	mv	a0,s4
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	cea080e7          	jalr	-790(ra) # 80003748 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a66:	854e                	mv	a0,s3
    80003a68:	70a2                	ld	ra,40(sp)
    80003a6a:	7402                	ld	s0,32(sp)
    80003a6c:	64e2                	ld	s1,24(sp)
    80003a6e:	6942                	ld	s2,16(sp)
    80003a70:	69a2                	ld	s3,8(sp)
    80003a72:	6a02                	ld	s4,0(sp)
    80003a74:	6145                	addi	sp,sp,48
    80003a76:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a78:	02059793          	slli	a5,a1,0x20
    80003a7c:	01e7d593          	srli	a1,a5,0x1e
    80003a80:	00b504b3          	add	s1,a0,a1
    80003a84:	0504a983          	lw	s3,80(s1)
    80003a88:	fc099fe3          	bnez	s3,80003a66 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a8c:	4108                	lw	a0,0(a0)
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	e4c080e7          	jalr	-436(ra) # 800038da <balloc>
    80003a96:	0005099b          	sext.w	s3,a0
    80003a9a:	0534a823          	sw	s3,80(s1)
    80003a9e:	b7e1                	j	80003a66 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003aa0:	4108                	lw	a0,0(a0)
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	e38080e7          	jalr	-456(ra) # 800038da <balloc>
    80003aaa:	0005059b          	sext.w	a1,a0
    80003aae:	08b92023          	sw	a1,128(s2)
    80003ab2:	b751                	j	80003a36 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ab4:	00092503          	lw	a0,0(s2)
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	e22080e7          	jalr	-478(ra) # 800038da <balloc>
    80003ac0:	0005099b          	sext.w	s3,a0
    80003ac4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003ac8:	8552                	mv	a0,s4
    80003aca:	00001097          	auipc	ra,0x1
    80003ace:	f02080e7          	jalr	-254(ra) # 800049cc <log_write>
    80003ad2:	b769                	j	80003a5c <bmap+0x54>
  panic("bmap: out of range");
    80003ad4:	00005517          	auipc	a0,0x5
    80003ad8:	ac450513          	addi	a0,a0,-1340 # 80008598 <syscalls+0x138>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	a60080e7          	jalr	-1440(ra) # 8000053c <panic>

0000000080003ae4 <iget>:
{
    80003ae4:	7179                	addi	sp,sp,-48
    80003ae6:	f406                	sd	ra,40(sp)
    80003ae8:	f022                	sd	s0,32(sp)
    80003aea:	ec26                	sd	s1,24(sp)
    80003aec:	e84a                	sd	s2,16(sp)
    80003aee:	e44e                	sd	s3,8(sp)
    80003af0:	e052                	sd	s4,0(sp)
    80003af2:	1800                	addi	s0,sp,48
    80003af4:	89aa                	mv	s3,a0
    80003af6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003af8:	0002c517          	auipc	a0,0x2c
    80003afc:	2e850513          	addi	a0,a0,744 # 8002fde0 <itable>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	11c080e7          	jalr	284(ra) # 80000c1c <acquire>
  empty = 0;
    80003b08:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b0a:	0002c497          	auipc	s1,0x2c
    80003b0e:	2ee48493          	addi	s1,s1,750 # 8002fdf8 <itable+0x18>
    80003b12:	0002e697          	auipc	a3,0x2e
    80003b16:	d7668693          	addi	a3,a3,-650 # 80031888 <log>
    80003b1a:	a039                	j	80003b28 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b1c:	02090b63          	beqz	s2,80003b52 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b20:	08848493          	addi	s1,s1,136
    80003b24:	02d48a63          	beq	s1,a3,80003b58 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b28:	449c                	lw	a5,8(s1)
    80003b2a:	fef059e3          	blez	a5,80003b1c <iget+0x38>
    80003b2e:	4098                	lw	a4,0(s1)
    80003b30:	ff3716e3          	bne	a4,s3,80003b1c <iget+0x38>
    80003b34:	40d8                	lw	a4,4(s1)
    80003b36:	ff4713e3          	bne	a4,s4,80003b1c <iget+0x38>
      ip->ref++;
    80003b3a:	2785                	addiw	a5,a5,1
    80003b3c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b3e:	0002c517          	auipc	a0,0x2c
    80003b42:	2a250513          	addi	a0,a0,674 # 8002fde0 <itable>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	18a080e7          	jalr	394(ra) # 80000cd0 <release>
      return ip;
    80003b4e:	8926                	mv	s2,s1
    80003b50:	a03d                	j	80003b7e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b52:	f7f9                	bnez	a5,80003b20 <iget+0x3c>
    80003b54:	8926                	mv	s2,s1
    80003b56:	b7e9                	j	80003b20 <iget+0x3c>
  if(empty == 0)
    80003b58:	02090c63          	beqz	s2,80003b90 <iget+0xac>
  ip->dev = dev;
    80003b5c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b60:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b64:	4785                	li	a5,1
    80003b66:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b6a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b6e:	0002c517          	auipc	a0,0x2c
    80003b72:	27250513          	addi	a0,a0,626 # 8002fde0 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	15a080e7          	jalr	346(ra) # 80000cd0 <release>
}
    80003b7e:	854a                	mv	a0,s2
    80003b80:	70a2                	ld	ra,40(sp)
    80003b82:	7402                	ld	s0,32(sp)
    80003b84:	64e2                	ld	s1,24(sp)
    80003b86:	6942                	ld	s2,16(sp)
    80003b88:	69a2                	ld	s3,8(sp)
    80003b8a:	6a02                	ld	s4,0(sp)
    80003b8c:	6145                	addi	sp,sp,48
    80003b8e:	8082                	ret
    panic("iget: no inodes");
    80003b90:	00005517          	auipc	a0,0x5
    80003b94:	a2050513          	addi	a0,a0,-1504 # 800085b0 <syscalls+0x150>
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	9a4080e7          	jalr	-1628(ra) # 8000053c <panic>

0000000080003ba0 <fsinit>:
fsinit(int dev) {
    80003ba0:	7179                	addi	sp,sp,-48
    80003ba2:	f406                	sd	ra,40(sp)
    80003ba4:	f022                	sd	s0,32(sp)
    80003ba6:	ec26                	sd	s1,24(sp)
    80003ba8:	e84a                	sd	s2,16(sp)
    80003baa:	e44e                	sd	s3,8(sp)
    80003bac:	1800                	addi	s0,sp,48
    80003bae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bb0:	4585                	li	a1,1
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	a66080e7          	jalr	-1434(ra) # 80003618 <bread>
    80003bba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bbc:	0002c997          	auipc	s3,0x2c
    80003bc0:	20498993          	addi	s3,s3,516 # 8002fdc0 <sb>
    80003bc4:	02000613          	li	a2,32
    80003bc8:	05850593          	addi	a1,a0,88
    80003bcc:	854e                	mv	a0,s3
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	1a6080e7          	jalr	422(ra) # 80000d74 <memmove>
  brelse(bp);
    80003bd6:	8526                	mv	a0,s1
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	b70080e7          	jalr	-1168(ra) # 80003748 <brelse>
  if(sb.magic != FSMAGIC)
    80003be0:	0009a703          	lw	a4,0(s3)
    80003be4:	102037b7          	lui	a5,0x10203
    80003be8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bec:	02f71263          	bne	a4,a5,80003c10 <fsinit+0x70>
  initlog(dev, &sb);
    80003bf0:	0002c597          	auipc	a1,0x2c
    80003bf4:	1d058593          	addi	a1,a1,464 # 8002fdc0 <sb>
    80003bf8:	854a                	mv	a0,s2
    80003bfa:	00001097          	auipc	ra,0x1
    80003bfe:	b56080e7          	jalr	-1194(ra) # 80004750 <initlog>
}
    80003c02:	70a2                	ld	ra,40(sp)
    80003c04:	7402                	ld	s0,32(sp)
    80003c06:	64e2                	ld	s1,24(sp)
    80003c08:	6942                	ld	s2,16(sp)
    80003c0a:	69a2                	ld	s3,8(sp)
    80003c0c:	6145                	addi	sp,sp,48
    80003c0e:	8082                	ret
    panic("invalid file system");
    80003c10:	00005517          	auipc	a0,0x5
    80003c14:	9b050513          	addi	a0,a0,-1616 # 800085c0 <syscalls+0x160>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	924080e7          	jalr	-1756(ra) # 8000053c <panic>

0000000080003c20 <iinit>:
{
    80003c20:	7179                	addi	sp,sp,-48
    80003c22:	f406                	sd	ra,40(sp)
    80003c24:	f022                	sd	s0,32(sp)
    80003c26:	ec26                	sd	s1,24(sp)
    80003c28:	e84a                	sd	s2,16(sp)
    80003c2a:	e44e                	sd	s3,8(sp)
    80003c2c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c2e:	00005597          	auipc	a1,0x5
    80003c32:	9aa58593          	addi	a1,a1,-1622 # 800085d8 <syscalls+0x178>
    80003c36:	0002c517          	auipc	a0,0x2c
    80003c3a:	1aa50513          	addi	a0,a0,426 # 8002fde0 <itable>
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	f4e080e7          	jalr	-178(ra) # 80000b8c <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c46:	0002c497          	auipc	s1,0x2c
    80003c4a:	1c248493          	addi	s1,s1,450 # 8002fe08 <itable+0x28>
    80003c4e:	0002e997          	auipc	s3,0x2e
    80003c52:	c4a98993          	addi	s3,s3,-950 # 80031898 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c56:	00005917          	auipc	s2,0x5
    80003c5a:	98a90913          	addi	s2,s2,-1654 # 800085e0 <syscalls+0x180>
    80003c5e:	85ca                	mv	a1,s2
    80003c60:	8526                	mv	a0,s1
    80003c62:	00001097          	auipc	ra,0x1
    80003c66:	e4e080e7          	jalr	-434(ra) # 80004ab0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c6a:	08848493          	addi	s1,s1,136
    80003c6e:	ff3498e3          	bne	s1,s3,80003c5e <iinit+0x3e>
}
    80003c72:	70a2                	ld	ra,40(sp)
    80003c74:	7402                	ld	s0,32(sp)
    80003c76:	64e2                	ld	s1,24(sp)
    80003c78:	6942                	ld	s2,16(sp)
    80003c7a:	69a2                	ld	s3,8(sp)
    80003c7c:	6145                	addi	sp,sp,48
    80003c7e:	8082                	ret

0000000080003c80 <ialloc>:
{
    80003c80:	715d                	addi	sp,sp,-80
    80003c82:	e486                	sd	ra,72(sp)
    80003c84:	e0a2                	sd	s0,64(sp)
    80003c86:	fc26                	sd	s1,56(sp)
    80003c88:	f84a                	sd	s2,48(sp)
    80003c8a:	f44e                	sd	s3,40(sp)
    80003c8c:	f052                	sd	s4,32(sp)
    80003c8e:	ec56                	sd	s5,24(sp)
    80003c90:	e85a                	sd	s6,16(sp)
    80003c92:	e45e                	sd	s7,8(sp)
    80003c94:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c96:	0002c717          	auipc	a4,0x2c
    80003c9a:	13672703          	lw	a4,310(a4) # 8002fdcc <sb+0xc>
    80003c9e:	4785                	li	a5,1
    80003ca0:	04e7fa63          	bgeu	a5,a4,80003cf4 <ialloc+0x74>
    80003ca4:	8aaa                	mv	s5,a0
    80003ca6:	8bae                	mv	s7,a1
    80003ca8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003caa:	0002ca17          	auipc	s4,0x2c
    80003cae:	116a0a13          	addi	s4,s4,278 # 8002fdc0 <sb>
    80003cb2:	00048b1b          	sext.w	s6,s1
    80003cb6:	0044d593          	srli	a1,s1,0x4
    80003cba:	018a2783          	lw	a5,24(s4)
    80003cbe:	9dbd                	addw	a1,a1,a5
    80003cc0:	8556                	mv	a0,s5
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	956080e7          	jalr	-1706(ra) # 80003618 <bread>
    80003cca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ccc:	05850993          	addi	s3,a0,88
    80003cd0:	00f4f793          	andi	a5,s1,15
    80003cd4:	079a                	slli	a5,a5,0x6
    80003cd6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cd8:	00099783          	lh	a5,0(s3)
    80003cdc:	c785                	beqz	a5,80003d04 <ialloc+0x84>
    brelse(bp);
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	a6a080e7          	jalr	-1430(ra) # 80003748 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ce6:	0485                	addi	s1,s1,1
    80003ce8:	00ca2703          	lw	a4,12(s4)
    80003cec:	0004879b          	sext.w	a5,s1
    80003cf0:	fce7e1e3          	bltu	a5,a4,80003cb2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cf4:	00005517          	auipc	a0,0x5
    80003cf8:	8f450513          	addi	a0,a0,-1804 # 800085e8 <syscalls+0x188>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	840080e7          	jalr	-1984(ra) # 8000053c <panic>
      memset(dip, 0, sizeof(*dip));
    80003d04:	04000613          	li	a2,64
    80003d08:	4581                	li	a1,0
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	00c080e7          	jalr	12(ra) # 80000d18 <memset>
      dip->type = type;
    80003d14:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00001097          	auipc	ra,0x1
    80003d1e:	cb2080e7          	jalr	-846(ra) # 800049cc <log_write>
      brelse(bp);
    80003d22:	854a                	mv	a0,s2
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	a24080e7          	jalr	-1500(ra) # 80003748 <brelse>
      return iget(dev, inum);
    80003d2c:	85da                	mv	a1,s6
    80003d2e:	8556                	mv	a0,s5
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	db4080e7          	jalr	-588(ra) # 80003ae4 <iget>
}
    80003d38:	60a6                	ld	ra,72(sp)
    80003d3a:	6406                	ld	s0,64(sp)
    80003d3c:	74e2                	ld	s1,56(sp)
    80003d3e:	7942                	ld	s2,48(sp)
    80003d40:	79a2                	ld	s3,40(sp)
    80003d42:	7a02                	ld	s4,32(sp)
    80003d44:	6ae2                	ld	s5,24(sp)
    80003d46:	6b42                	ld	s6,16(sp)
    80003d48:	6ba2                	ld	s7,8(sp)
    80003d4a:	6161                	addi	sp,sp,80
    80003d4c:	8082                	ret

0000000080003d4e <iupdate>:
{
    80003d4e:	1101                	addi	sp,sp,-32
    80003d50:	ec06                	sd	ra,24(sp)
    80003d52:	e822                	sd	s0,16(sp)
    80003d54:	e426                	sd	s1,8(sp)
    80003d56:	e04a                	sd	s2,0(sp)
    80003d58:	1000                	addi	s0,sp,32
    80003d5a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d5c:	415c                	lw	a5,4(a0)
    80003d5e:	0047d79b          	srliw	a5,a5,0x4
    80003d62:	0002c597          	auipc	a1,0x2c
    80003d66:	0765a583          	lw	a1,118(a1) # 8002fdd8 <sb+0x18>
    80003d6a:	9dbd                	addw	a1,a1,a5
    80003d6c:	4108                	lw	a0,0(a0)
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	8aa080e7          	jalr	-1878(ra) # 80003618 <bread>
    80003d76:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d78:	05850793          	addi	a5,a0,88
    80003d7c:	40d8                	lw	a4,4(s1)
    80003d7e:	8b3d                	andi	a4,a4,15
    80003d80:	071a                	slli	a4,a4,0x6
    80003d82:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003d84:	04449703          	lh	a4,68(s1)
    80003d88:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003d8c:	04649703          	lh	a4,70(s1)
    80003d90:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d94:	04849703          	lh	a4,72(s1)
    80003d98:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d9c:	04a49703          	lh	a4,74(s1)
    80003da0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003da4:	44f8                	lw	a4,76(s1)
    80003da6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003da8:	03400613          	li	a2,52
    80003dac:	05048593          	addi	a1,s1,80
    80003db0:	00c78513          	addi	a0,a5,12
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	fc0080e7          	jalr	-64(ra) # 80000d74 <memmove>
  log_write(bp);
    80003dbc:	854a                	mv	a0,s2
    80003dbe:	00001097          	auipc	ra,0x1
    80003dc2:	c0e080e7          	jalr	-1010(ra) # 800049cc <log_write>
  brelse(bp);
    80003dc6:	854a                	mv	a0,s2
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	980080e7          	jalr	-1664(ra) # 80003748 <brelse>
}
    80003dd0:	60e2                	ld	ra,24(sp)
    80003dd2:	6442                	ld	s0,16(sp)
    80003dd4:	64a2                	ld	s1,8(sp)
    80003dd6:	6902                	ld	s2,0(sp)
    80003dd8:	6105                	addi	sp,sp,32
    80003dda:	8082                	ret

0000000080003ddc <idup>:
{
    80003ddc:	1101                	addi	sp,sp,-32
    80003dde:	ec06                	sd	ra,24(sp)
    80003de0:	e822                	sd	s0,16(sp)
    80003de2:	e426                	sd	s1,8(sp)
    80003de4:	1000                	addi	s0,sp,32
    80003de6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003de8:	0002c517          	auipc	a0,0x2c
    80003dec:	ff850513          	addi	a0,a0,-8 # 8002fde0 <itable>
    80003df0:	ffffd097          	auipc	ra,0xffffd
    80003df4:	e2c080e7          	jalr	-468(ra) # 80000c1c <acquire>
  ip->ref++;
    80003df8:	449c                	lw	a5,8(s1)
    80003dfa:	2785                	addiw	a5,a5,1
    80003dfc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dfe:	0002c517          	auipc	a0,0x2c
    80003e02:	fe250513          	addi	a0,a0,-30 # 8002fde0 <itable>
    80003e06:	ffffd097          	auipc	ra,0xffffd
    80003e0a:	eca080e7          	jalr	-310(ra) # 80000cd0 <release>
}
    80003e0e:	8526                	mv	a0,s1
    80003e10:	60e2                	ld	ra,24(sp)
    80003e12:	6442                	ld	s0,16(sp)
    80003e14:	64a2                	ld	s1,8(sp)
    80003e16:	6105                	addi	sp,sp,32
    80003e18:	8082                	ret

0000000080003e1a <ilock>:
{
    80003e1a:	1101                	addi	sp,sp,-32
    80003e1c:	ec06                	sd	ra,24(sp)
    80003e1e:	e822                	sd	s0,16(sp)
    80003e20:	e426                	sd	s1,8(sp)
    80003e22:	e04a                	sd	s2,0(sp)
    80003e24:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e26:	c115                	beqz	a0,80003e4a <ilock+0x30>
    80003e28:	84aa                	mv	s1,a0
    80003e2a:	451c                	lw	a5,8(a0)
    80003e2c:	00f05f63          	blez	a5,80003e4a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e30:	0541                	addi	a0,a0,16
    80003e32:	00001097          	auipc	ra,0x1
    80003e36:	cb8080e7          	jalr	-840(ra) # 80004aea <acquiresleep>
  if(ip->valid == 0){
    80003e3a:	40bc                	lw	a5,64(s1)
    80003e3c:	cf99                	beqz	a5,80003e5a <ilock+0x40>
}
    80003e3e:	60e2                	ld	ra,24(sp)
    80003e40:	6442                	ld	s0,16(sp)
    80003e42:	64a2                	ld	s1,8(sp)
    80003e44:	6902                	ld	s2,0(sp)
    80003e46:	6105                	addi	sp,sp,32
    80003e48:	8082                	ret
    panic("ilock");
    80003e4a:	00004517          	auipc	a0,0x4
    80003e4e:	7b650513          	addi	a0,a0,1974 # 80008600 <syscalls+0x1a0>
    80003e52:	ffffc097          	auipc	ra,0xffffc
    80003e56:	6ea080e7          	jalr	1770(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e5a:	40dc                	lw	a5,4(s1)
    80003e5c:	0047d79b          	srliw	a5,a5,0x4
    80003e60:	0002c597          	auipc	a1,0x2c
    80003e64:	f785a583          	lw	a1,-136(a1) # 8002fdd8 <sb+0x18>
    80003e68:	9dbd                	addw	a1,a1,a5
    80003e6a:	4088                	lw	a0,0(s1)
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	7ac080e7          	jalr	1964(ra) # 80003618 <bread>
    80003e74:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e76:	05850593          	addi	a1,a0,88
    80003e7a:	40dc                	lw	a5,4(s1)
    80003e7c:	8bbd                	andi	a5,a5,15
    80003e7e:	079a                	slli	a5,a5,0x6
    80003e80:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e82:	00059783          	lh	a5,0(a1)
    80003e86:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e8a:	00259783          	lh	a5,2(a1)
    80003e8e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e92:	00459783          	lh	a5,4(a1)
    80003e96:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e9a:	00659783          	lh	a5,6(a1)
    80003e9e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ea2:	459c                	lw	a5,8(a1)
    80003ea4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ea6:	03400613          	li	a2,52
    80003eaa:	05b1                	addi	a1,a1,12
    80003eac:	05048513          	addi	a0,s1,80
    80003eb0:	ffffd097          	auipc	ra,0xffffd
    80003eb4:	ec4080e7          	jalr	-316(ra) # 80000d74 <memmove>
    brelse(bp);
    80003eb8:	854a                	mv	a0,s2
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	88e080e7          	jalr	-1906(ra) # 80003748 <brelse>
    ip->valid = 1;
    80003ec2:	4785                	li	a5,1
    80003ec4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ec6:	04449783          	lh	a5,68(s1)
    80003eca:	fbb5                	bnez	a5,80003e3e <ilock+0x24>
      panic("ilock: no type");
    80003ecc:	00004517          	auipc	a0,0x4
    80003ed0:	73c50513          	addi	a0,a0,1852 # 80008608 <syscalls+0x1a8>
    80003ed4:	ffffc097          	auipc	ra,0xffffc
    80003ed8:	668080e7          	jalr	1640(ra) # 8000053c <panic>

0000000080003edc <iunlock>:
{
    80003edc:	1101                	addi	sp,sp,-32
    80003ede:	ec06                	sd	ra,24(sp)
    80003ee0:	e822                	sd	s0,16(sp)
    80003ee2:	e426                	sd	s1,8(sp)
    80003ee4:	e04a                	sd	s2,0(sp)
    80003ee6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ee8:	c905                	beqz	a0,80003f18 <iunlock+0x3c>
    80003eea:	84aa                	mv	s1,a0
    80003eec:	01050913          	addi	s2,a0,16
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	00001097          	auipc	ra,0x1
    80003ef6:	c94080e7          	jalr	-876(ra) # 80004b86 <holdingsleep>
    80003efa:	cd19                	beqz	a0,80003f18 <iunlock+0x3c>
    80003efc:	449c                	lw	a5,8(s1)
    80003efe:	00f05d63          	blez	a5,80003f18 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f02:	854a                	mv	a0,s2
    80003f04:	00001097          	auipc	ra,0x1
    80003f08:	c3e080e7          	jalr	-962(ra) # 80004b42 <releasesleep>
}
    80003f0c:	60e2                	ld	ra,24(sp)
    80003f0e:	6442                	ld	s0,16(sp)
    80003f10:	64a2                	ld	s1,8(sp)
    80003f12:	6902                	ld	s2,0(sp)
    80003f14:	6105                	addi	sp,sp,32
    80003f16:	8082                	ret
    panic("iunlock");
    80003f18:	00004517          	auipc	a0,0x4
    80003f1c:	70050513          	addi	a0,a0,1792 # 80008618 <syscalls+0x1b8>
    80003f20:	ffffc097          	auipc	ra,0xffffc
    80003f24:	61c080e7          	jalr	1564(ra) # 8000053c <panic>

0000000080003f28 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f28:	7179                	addi	sp,sp,-48
    80003f2a:	f406                	sd	ra,40(sp)
    80003f2c:	f022                	sd	s0,32(sp)
    80003f2e:	ec26                	sd	s1,24(sp)
    80003f30:	e84a                	sd	s2,16(sp)
    80003f32:	e44e                	sd	s3,8(sp)
    80003f34:	e052                	sd	s4,0(sp)
    80003f36:	1800                	addi	s0,sp,48
    80003f38:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f3a:	05050493          	addi	s1,a0,80
    80003f3e:	08050913          	addi	s2,a0,128
    80003f42:	a021                	j	80003f4a <itrunc+0x22>
    80003f44:	0491                	addi	s1,s1,4
    80003f46:	01248d63          	beq	s1,s2,80003f60 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f4a:	408c                	lw	a1,0(s1)
    80003f4c:	dde5                	beqz	a1,80003f44 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f4e:	0009a503          	lw	a0,0(s3)
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	90c080e7          	jalr	-1780(ra) # 8000385e <bfree>
      ip->addrs[i] = 0;
    80003f5a:	0004a023          	sw	zero,0(s1)
    80003f5e:	b7dd                	j	80003f44 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f60:	0809a583          	lw	a1,128(s3)
    80003f64:	e185                	bnez	a1,80003f84 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f66:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f6a:	854e                	mv	a0,s3
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	de2080e7          	jalr	-542(ra) # 80003d4e <iupdate>
}
    80003f74:	70a2                	ld	ra,40(sp)
    80003f76:	7402                	ld	s0,32(sp)
    80003f78:	64e2                	ld	s1,24(sp)
    80003f7a:	6942                	ld	s2,16(sp)
    80003f7c:	69a2                	ld	s3,8(sp)
    80003f7e:	6a02                	ld	s4,0(sp)
    80003f80:	6145                	addi	sp,sp,48
    80003f82:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f84:	0009a503          	lw	a0,0(s3)
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	690080e7          	jalr	1680(ra) # 80003618 <bread>
    80003f90:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f92:	05850493          	addi	s1,a0,88
    80003f96:	45850913          	addi	s2,a0,1112
    80003f9a:	a021                	j	80003fa2 <itrunc+0x7a>
    80003f9c:	0491                	addi	s1,s1,4
    80003f9e:	01248b63          	beq	s1,s2,80003fb4 <itrunc+0x8c>
      if(a[j])
    80003fa2:	408c                	lw	a1,0(s1)
    80003fa4:	dde5                	beqz	a1,80003f9c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003fa6:	0009a503          	lw	a0,0(s3)
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	8b4080e7          	jalr	-1868(ra) # 8000385e <bfree>
    80003fb2:	b7ed                	j	80003f9c <itrunc+0x74>
    brelse(bp);
    80003fb4:	8552                	mv	a0,s4
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	792080e7          	jalr	1938(ra) # 80003748 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fbe:	0809a583          	lw	a1,128(s3)
    80003fc2:	0009a503          	lw	a0,0(s3)
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	898080e7          	jalr	-1896(ra) # 8000385e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fce:	0809a023          	sw	zero,128(s3)
    80003fd2:	bf51                	j	80003f66 <itrunc+0x3e>

0000000080003fd4 <iput>:
{
    80003fd4:	1101                	addi	sp,sp,-32
    80003fd6:	ec06                	sd	ra,24(sp)
    80003fd8:	e822                	sd	s0,16(sp)
    80003fda:	e426                	sd	s1,8(sp)
    80003fdc:	e04a                	sd	s2,0(sp)
    80003fde:	1000                	addi	s0,sp,32
    80003fe0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fe2:	0002c517          	auipc	a0,0x2c
    80003fe6:	dfe50513          	addi	a0,a0,-514 # 8002fde0 <itable>
    80003fea:	ffffd097          	auipc	ra,0xffffd
    80003fee:	c32080e7          	jalr	-974(ra) # 80000c1c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ff2:	4498                	lw	a4,8(s1)
    80003ff4:	4785                	li	a5,1
    80003ff6:	02f70363          	beq	a4,a5,8000401c <iput+0x48>
  ip->ref--;
    80003ffa:	449c                	lw	a5,8(s1)
    80003ffc:	37fd                	addiw	a5,a5,-1
    80003ffe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004000:	0002c517          	auipc	a0,0x2c
    80004004:	de050513          	addi	a0,a0,-544 # 8002fde0 <itable>
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	cc8080e7          	jalr	-824(ra) # 80000cd0 <release>
}
    80004010:	60e2                	ld	ra,24(sp)
    80004012:	6442                	ld	s0,16(sp)
    80004014:	64a2                	ld	s1,8(sp)
    80004016:	6902                	ld	s2,0(sp)
    80004018:	6105                	addi	sp,sp,32
    8000401a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000401c:	40bc                	lw	a5,64(s1)
    8000401e:	dff1                	beqz	a5,80003ffa <iput+0x26>
    80004020:	04a49783          	lh	a5,74(s1)
    80004024:	fbf9                	bnez	a5,80003ffa <iput+0x26>
    acquiresleep(&ip->lock);
    80004026:	01048913          	addi	s2,s1,16
    8000402a:	854a                	mv	a0,s2
    8000402c:	00001097          	auipc	ra,0x1
    80004030:	abe080e7          	jalr	-1346(ra) # 80004aea <acquiresleep>
    release(&itable.lock);
    80004034:	0002c517          	auipc	a0,0x2c
    80004038:	dac50513          	addi	a0,a0,-596 # 8002fde0 <itable>
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	c94080e7          	jalr	-876(ra) # 80000cd0 <release>
    itrunc(ip);
    80004044:	8526                	mv	a0,s1
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	ee2080e7          	jalr	-286(ra) # 80003f28 <itrunc>
    ip->type = 0;
    8000404e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004052:	8526                	mv	a0,s1
    80004054:	00000097          	auipc	ra,0x0
    80004058:	cfa080e7          	jalr	-774(ra) # 80003d4e <iupdate>
    ip->valid = 0;
    8000405c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004060:	854a                	mv	a0,s2
    80004062:	00001097          	auipc	ra,0x1
    80004066:	ae0080e7          	jalr	-1312(ra) # 80004b42 <releasesleep>
    acquire(&itable.lock);
    8000406a:	0002c517          	auipc	a0,0x2c
    8000406e:	d7650513          	addi	a0,a0,-650 # 8002fde0 <itable>
    80004072:	ffffd097          	auipc	ra,0xffffd
    80004076:	baa080e7          	jalr	-1110(ra) # 80000c1c <acquire>
    8000407a:	b741                	j	80003ffa <iput+0x26>

000000008000407c <iunlockput>:
{
    8000407c:	1101                	addi	sp,sp,-32
    8000407e:	ec06                	sd	ra,24(sp)
    80004080:	e822                	sd	s0,16(sp)
    80004082:	e426                	sd	s1,8(sp)
    80004084:	1000                	addi	s0,sp,32
    80004086:	84aa                	mv	s1,a0
  iunlock(ip);
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	e54080e7          	jalr	-428(ra) # 80003edc <iunlock>
  iput(ip);
    80004090:	8526                	mv	a0,s1
    80004092:	00000097          	auipc	ra,0x0
    80004096:	f42080e7          	jalr	-190(ra) # 80003fd4 <iput>
}
    8000409a:	60e2                	ld	ra,24(sp)
    8000409c:	6442                	ld	s0,16(sp)
    8000409e:	64a2                	ld	s1,8(sp)
    800040a0:	6105                	addi	sp,sp,32
    800040a2:	8082                	ret

00000000800040a4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040a4:	1141                	addi	sp,sp,-16
    800040a6:	e422                	sd	s0,8(sp)
    800040a8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040aa:	411c                	lw	a5,0(a0)
    800040ac:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040ae:	415c                	lw	a5,4(a0)
    800040b0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040b2:	04451783          	lh	a5,68(a0)
    800040b6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040ba:	04a51783          	lh	a5,74(a0)
    800040be:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040c2:	04c56783          	lwu	a5,76(a0)
    800040c6:	e99c                	sd	a5,16(a1)
}
    800040c8:	6422                	ld	s0,8(sp)
    800040ca:	0141                	addi	sp,sp,16
    800040cc:	8082                	ret

00000000800040ce <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040ce:	457c                	lw	a5,76(a0)
    800040d0:	0ed7e963          	bltu	a5,a3,800041c2 <readi+0xf4>
{
    800040d4:	7159                	addi	sp,sp,-112
    800040d6:	f486                	sd	ra,104(sp)
    800040d8:	f0a2                	sd	s0,96(sp)
    800040da:	eca6                	sd	s1,88(sp)
    800040dc:	e8ca                	sd	s2,80(sp)
    800040de:	e4ce                	sd	s3,72(sp)
    800040e0:	e0d2                	sd	s4,64(sp)
    800040e2:	fc56                	sd	s5,56(sp)
    800040e4:	f85a                	sd	s6,48(sp)
    800040e6:	f45e                	sd	s7,40(sp)
    800040e8:	f062                	sd	s8,32(sp)
    800040ea:	ec66                	sd	s9,24(sp)
    800040ec:	e86a                	sd	s10,16(sp)
    800040ee:	e46e                	sd	s11,8(sp)
    800040f0:	1880                	addi	s0,sp,112
    800040f2:	8baa                	mv	s7,a0
    800040f4:	8c2e                	mv	s8,a1
    800040f6:	8ab2                	mv	s5,a2
    800040f8:	84b6                	mv	s1,a3
    800040fa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040fc:	9f35                	addw	a4,a4,a3
    return 0;
    800040fe:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004100:	0ad76063          	bltu	a4,a3,800041a0 <readi+0xd2>
  if(off + n > ip->size)
    80004104:	00e7f463          	bgeu	a5,a4,8000410c <readi+0x3e>
    n = ip->size - off;
    80004108:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000410c:	0a0b0963          	beqz	s6,800041be <readi+0xf0>
    80004110:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004112:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004116:	5cfd                	li	s9,-1
    80004118:	a82d                	j	80004152 <readi+0x84>
    8000411a:	020a1d93          	slli	s11,s4,0x20
    8000411e:	020ddd93          	srli	s11,s11,0x20
    80004122:	05890613          	addi	a2,s2,88
    80004126:	86ee                	mv	a3,s11
    80004128:	963a                	add	a2,a2,a4
    8000412a:	85d6                	mv	a1,s5
    8000412c:	8562                	mv	a0,s8
    8000412e:	ffffe097          	auipc	ra,0xffffe
    80004132:	068080e7          	jalr	104(ra) # 80002196 <either_copyout>
    80004136:	05950d63          	beq	a0,s9,80004190 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000413a:	854a                	mv	a0,s2
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	60c080e7          	jalr	1548(ra) # 80003748 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004144:	013a09bb          	addw	s3,s4,s3
    80004148:	009a04bb          	addw	s1,s4,s1
    8000414c:	9aee                	add	s5,s5,s11
    8000414e:	0569f763          	bgeu	s3,s6,8000419c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004152:	000ba903          	lw	s2,0(s7)
    80004156:	00a4d59b          	srliw	a1,s1,0xa
    8000415a:	855e                	mv	a0,s7
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	8ac080e7          	jalr	-1876(ra) # 80003a08 <bmap>
    80004164:	0005059b          	sext.w	a1,a0
    80004168:	854a                	mv	a0,s2
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	4ae080e7          	jalr	1198(ra) # 80003618 <bread>
    80004172:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004174:	3ff4f713          	andi	a4,s1,1023
    80004178:	40ed07bb          	subw	a5,s10,a4
    8000417c:	413b06bb          	subw	a3,s6,s3
    80004180:	8a3e                	mv	s4,a5
    80004182:	2781                	sext.w	a5,a5
    80004184:	0006861b          	sext.w	a2,a3
    80004188:	f8f679e3          	bgeu	a2,a5,8000411a <readi+0x4c>
    8000418c:	8a36                	mv	s4,a3
    8000418e:	b771                	j	8000411a <readi+0x4c>
      brelse(bp);
    80004190:	854a                	mv	a0,s2
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	5b6080e7          	jalr	1462(ra) # 80003748 <brelse>
      tot = -1;
    8000419a:	59fd                	li	s3,-1
  }
  return tot;
    8000419c:	0009851b          	sext.w	a0,s3
}
    800041a0:	70a6                	ld	ra,104(sp)
    800041a2:	7406                	ld	s0,96(sp)
    800041a4:	64e6                	ld	s1,88(sp)
    800041a6:	6946                	ld	s2,80(sp)
    800041a8:	69a6                	ld	s3,72(sp)
    800041aa:	6a06                	ld	s4,64(sp)
    800041ac:	7ae2                	ld	s5,56(sp)
    800041ae:	7b42                	ld	s6,48(sp)
    800041b0:	7ba2                	ld	s7,40(sp)
    800041b2:	7c02                	ld	s8,32(sp)
    800041b4:	6ce2                	ld	s9,24(sp)
    800041b6:	6d42                	ld	s10,16(sp)
    800041b8:	6da2                	ld	s11,8(sp)
    800041ba:	6165                	addi	sp,sp,112
    800041bc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041be:	89da                	mv	s3,s6
    800041c0:	bff1                	j	8000419c <readi+0xce>
    return 0;
    800041c2:	4501                	li	a0,0
}
    800041c4:	8082                	ret

00000000800041c6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041c6:	457c                	lw	a5,76(a0)
    800041c8:	10d7e863          	bltu	a5,a3,800042d8 <writei+0x112>
{
    800041cc:	7159                	addi	sp,sp,-112
    800041ce:	f486                	sd	ra,104(sp)
    800041d0:	f0a2                	sd	s0,96(sp)
    800041d2:	eca6                	sd	s1,88(sp)
    800041d4:	e8ca                	sd	s2,80(sp)
    800041d6:	e4ce                	sd	s3,72(sp)
    800041d8:	e0d2                	sd	s4,64(sp)
    800041da:	fc56                	sd	s5,56(sp)
    800041dc:	f85a                	sd	s6,48(sp)
    800041de:	f45e                	sd	s7,40(sp)
    800041e0:	f062                	sd	s8,32(sp)
    800041e2:	ec66                	sd	s9,24(sp)
    800041e4:	e86a                	sd	s10,16(sp)
    800041e6:	e46e                	sd	s11,8(sp)
    800041e8:	1880                	addi	s0,sp,112
    800041ea:	8b2a                	mv	s6,a0
    800041ec:	8c2e                	mv	s8,a1
    800041ee:	8ab2                	mv	s5,a2
    800041f0:	8936                	mv	s2,a3
    800041f2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041f4:	00e687bb          	addw	a5,a3,a4
    800041f8:	0ed7e263          	bltu	a5,a3,800042dc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041fc:	00043737          	lui	a4,0x43
    80004200:	0ef76063          	bltu	a4,a5,800042e0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004204:	0c0b8863          	beqz	s7,800042d4 <writei+0x10e>
    80004208:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000420a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000420e:	5cfd                	li	s9,-1
    80004210:	a091                	j	80004254 <writei+0x8e>
    80004212:	02099d93          	slli	s11,s3,0x20
    80004216:	020ddd93          	srli	s11,s11,0x20
    8000421a:	05848513          	addi	a0,s1,88
    8000421e:	86ee                	mv	a3,s11
    80004220:	8656                	mv	a2,s5
    80004222:	85e2                	mv	a1,s8
    80004224:	953a                	add	a0,a0,a4
    80004226:	ffffe097          	auipc	ra,0xffffe
    8000422a:	fc8080e7          	jalr	-56(ra) # 800021ee <either_copyin>
    8000422e:	07950263          	beq	a0,s9,80004292 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004232:	8526                	mv	a0,s1
    80004234:	00000097          	auipc	ra,0x0
    80004238:	798080e7          	jalr	1944(ra) # 800049cc <log_write>
    brelse(bp);
    8000423c:	8526                	mv	a0,s1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	50a080e7          	jalr	1290(ra) # 80003748 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004246:	01498a3b          	addw	s4,s3,s4
    8000424a:	0129893b          	addw	s2,s3,s2
    8000424e:	9aee                	add	s5,s5,s11
    80004250:	057a7663          	bgeu	s4,s7,8000429c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004254:	000b2483          	lw	s1,0(s6)
    80004258:	00a9559b          	srliw	a1,s2,0xa
    8000425c:	855a                	mv	a0,s6
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	7aa080e7          	jalr	1962(ra) # 80003a08 <bmap>
    80004266:	0005059b          	sext.w	a1,a0
    8000426a:	8526                	mv	a0,s1
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	3ac080e7          	jalr	940(ra) # 80003618 <bread>
    80004274:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004276:	3ff97713          	andi	a4,s2,1023
    8000427a:	40ed07bb          	subw	a5,s10,a4
    8000427e:	414b86bb          	subw	a3,s7,s4
    80004282:	89be                	mv	s3,a5
    80004284:	2781                	sext.w	a5,a5
    80004286:	0006861b          	sext.w	a2,a3
    8000428a:	f8f674e3          	bgeu	a2,a5,80004212 <writei+0x4c>
    8000428e:	89b6                	mv	s3,a3
    80004290:	b749                	j	80004212 <writei+0x4c>
      brelse(bp);
    80004292:	8526                	mv	a0,s1
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	4b4080e7          	jalr	1204(ra) # 80003748 <brelse>
  }

  if(off > ip->size)
    8000429c:	04cb2783          	lw	a5,76(s6)
    800042a0:	0127f463          	bgeu	a5,s2,800042a8 <writei+0xe2>
    ip->size = off;
    800042a4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042a8:	855a                	mv	a0,s6
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	aa4080e7          	jalr	-1372(ra) # 80003d4e <iupdate>

  return tot;
    800042b2:	000a051b          	sext.w	a0,s4
}
    800042b6:	70a6                	ld	ra,104(sp)
    800042b8:	7406                	ld	s0,96(sp)
    800042ba:	64e6                	ld	s1,88(sp)
    800042bc:	6946                	ld	s2,80(sp)
    800042be:	69a6                	ld	s3,72(sp)
    800042c0:	6a06                	ld	s4,64(sp)
    800042c2:	7ae2                	ld	s5,56(sp)
    800042c4:	7b42                	ld	s6,48(sp)
    800042c6:	7ba2                	ld	s7,40(sp)
    800042c8:	7c02                	ld	s8,32(sp)
    800042ca:	6ce2                	ld	s9,24(sp)
    800042cc:	6d42                	ld	s10,16(sp)
    800042ce:	6da2                	ld	s11,8(sp)
    800042d0:	6165                	addi	sp,sp,112
    800042d2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042d4:	8a5e                	mv	s4,s7
    800042d6:	bfc9                	j	800042a8 <writei+0xe2>
    return -1;
    800042d8:	557d                	li	a0,-1
}
    800042da:	8082                	ret
    return -1;
    800042dc:	557d                	li	a0,-1
    800042de:	bfe1                	j	800042b6 <writei+0xf0>
    return -1;
    800042e0:	557d                	li	a0,-1
    800042e2:	bfd1                	j	800042b6 <writei+0xf0>

00000000800042e4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042e4:	1141                	addi	sp,sp,-16
    800042e6:	e406                	sd	ra,8(sp)
    800042e8:	e022                	sd	s0,0(sp)
    800042ea:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042ec:	4639                	li	a2,14
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	afa080e7          	jalr	-1286(ra) # 80000de8 <strncmp>
}
    800042f6:	60a2                	ld	ra,8(sp)
    800042f8:	6402                	ld	s0,0(sp)
    800042fa:	0141                	addi	sp,sp,16
    800042fc:	8082                	ret

00000000800042fe <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042fe:	7139                	addi	sp,sp,-64
    80004300:	fc06                	sd	ra,56(sp)
    80004302:	f822                	sd	s0,48(sp)
    80004304:	f426                	sd	s1,40(sp)
    80004306:	f04a                	sd	s2,32(sp)
    80004308:	ec4e                	sd	s3,24(sp)
    8000430a:	e852                	sd	s4,16(sp)
    8000430c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000430e:	04451703          	lh	a4,68(a0)
    80004312:	4785                	li	a5,1
    80004314:	00f71a63          	bne	a4,a5,80004328 <dirlookup+0x2a>
    80004318:	892a                	mv	s2,a0
    8000431a:	89ae                	mv	s3,a1
    8000431c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000431e:	457c                	lw	a5,76(a0)
    80004320:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004322:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004324:	e79d                	bnez	a5,80004352 <dirlookup+0x54>
    80004326:	a8a5                	j	8000439e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	2f850513          	addi	a0,a0,760 # 80008620 <syscalls+0x1c0>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	20c080e7          	jalr	524(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004338:	00004517          	auipc	a0,0x4
    8000433c:	30050513          	addi	a0,a0,768 # 80008638 <syscalls+0x1d8>
    80004340:	ffffc097          	auipc	ra,0xffffc
    80004344:	1fc080e7          	jalr	508(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004348:	24c1                	addiw	s1,s1,16
    8000434a:	04c92783          	lw	a5,76(s2)
    8000434e:	04f4f763          	bgeu	s1,a5,8000439c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004352:	4741                	li	a4,16
    80004354:	86a6                	mv	a3,s1
    80004356:	fc040613          	addi	a2,s0,-64
    8000435a:	4581                	li	a1,0
    8000435c:	854a                	mv	a0,s2
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	d70080e7          	jalr	-656(ra) # 800040ce <readi>
    80004366:	47c1                	li	a5,16
    80004368:	fcf518e3          	bne	a0,a5,80004338 <dirlookup+0x3a>
    if(de.inum == 0)
    8000436c:	fc045783          	lhu	a5,-64(s0)
    80004370:	dfe1                	beqz	a5,80004348 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004372:	fc240593          	addi	a1,s0,-62
    80004376:	854e                	mv	a0,s3
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	f6c080e7          	jalr	-148(ra) # 800042e4 <namecmp>
    80004380:	f561                	bnez	a0,80004348 <dirlookup+0x4a>
      if(poff)
    80004382:	000a0463          	beqz	s4,8000438a <dirlookup+0x8c>
        *poff = off;
    80004386:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000438a:	fc045583          	lhu	a1,-64(s0)
    8000438e:	00092503          	lw	a0,0(s2)
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	752080e7          	jalr	1874(ra) # 80003ae4 <iget>
    8000439a:	a011                	j	8000439e <dirlookup+0xa0>
  return 0;
    8000439c:	4501                	li	a0,0
}
    8000439e:	70e2                	ld	ra,56(sp)
    800043a0:	7442                	ld	s0,48(sp)
    800043a2:	74a2                	ld	s1,40(sp)
    800043a4:	7902                	ld	s2,32(sp)
    800043a6:	69e2                	ld	s3,24(sp)
    800043a8:	6a42                	ld	s4,16(sp)
    800043aa:	6121                	addi	sp,sp,64
    800043ac:	8082                	ret

00000000800043ae <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043ae:	711d                	addi	sp,sp,-96
    800043b0:	ec86                	sd	ra,88(sp)
    800043b2:	e8a2                	sd	s0,80(sp)
    800043b4:	e4a6                	sd	s1,72(sp)
    800043b6:	e0ca                	sd	s2,64(sp)
    800043b8:	fc4e                	sd	s3,56(sp)
    800043ba:	f852                	sd	s4,48(sp)
    800043bc:	f456                	sd	s5,40(sp)
    800043be:	f05a                	sd	s6,32(sp)
    800043c0:	ec5e                	sd	s7,24(sp)
    800043c2:	e862                	sd	s8,16(sp)
    800043c4:	e466                	sd	s9,8(sp)
    800043c6:	e06a                	sd	s10,0(sp)
    800043c8:	1080                	addi	s0,sp,96
    800043ca:	84aa                	mv	s1,a0
    800043cc:	8b2e                	mv	s6,a1
    800043ce:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043d0:	00054703          	lbu	a4,0(a0)
    800043d4:	02f00793          	li	a5,47
    800043d8:	02f70363          	beq	a4,a5,800043fe <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	710080e7          	jalr	1808(ra) # 80001aec <myproc>
    800043e4:	42853503          	ld	a0,1064(a0)
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	9f4080e7          	jalr	-1548(ra) # 80003ddc <idup>
    800043f0:	8a2a                	mv	s4,a0
  while(*path == '/')
    800043f2:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800043f6:	4cb5                	li	s9,13
  len = path - s;
    800043f8:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043fa:	4c05                	li	s8,1
    800043fc:	a87d                	j	800044ba <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800043fe:	4585                	li	a1,1
    80004400:	4505                	li	a0,1
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	6e2080e7          	jalr	1762(ra) # 80003ae4 <iget>
    8000440a:	8a2a                	mv	s4,a0
    8000440c:	b7dd                	j	800043f2 <namex+0x44>
      iunlockput(ip);
    8000440e:	8552                	mv	a0,s4
    80004410:	00000097          	auipc	ra,0x0
    80004414:	c6c080e7          	jalr	-916(ra) # 8000407c <iunlockput>
      return 0;
    80004418:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000441a:	8552                	mv	a0,s4
    8000441c:	60e6                	ld	ra,88(sp)
    8000441e:	6446                	ld	s0,80(sp)
    80004420:	64a6                	ld	s1,72(sp)
    80004422:	6906                	ld	s2,64(sp)
    80004424:	79e2                	ld	s3,56(sp)
    80004426:	7a42                	ld	s4,48(sp)
    80004428:	7aa2                	ld	s5,40(sp)
    8000442a:	7b02                	ld	s6,32(sp)
    8000442c:	6be2                	ld	s7,24(sp)
    8000442e:	6c42                	ld	s8,16(sp)
    80004430:	6ca2                	ld	s9,8(sp)
    80004432:	6d02                	ld	s10,0(sp)
    80004434:	6125                	addi	sp,sp,96
    80004436:	8082                	ret
      iunlock(ip);
    80004438:	8552                	mv	a0,s4
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	aa2080e7          	jalr	-1374(ra) # 80003edc <iunlock>
      return ip;
    80004442:	bfe1                	j	8000441a <namex+0x6c>
      iunlockput(ip);
    80004444:	8552                	mv	a0,s4
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	c36080e7          	jalr	-970(ra) # 8000407c <iunlockput>
      return 0;
    8000444e:	8a4e                	mv	s4,s3
    80004450:	b7e9                	j	8000441a <namex+0x6c>
  len = path - s;
    80004452:	40998633          	sub	a2,s3,s1
    80004456:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000445a:	09acd863          	bge	s9,s10,800044ea <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000445e:	4639                	li	a2,14
    80004460:	85a6                	mv	a1,s1
    80004462:	8556                	mv	a0,s5
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	910080e7          	jalr	-1776(ra) # 80000d74 <memmove>
    8000446c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000446e:	0004c783          	lbu	a5,0(s1)
    80004472:	01279763          	bne	a5,s2,80004480 <namex+0xd2>
    path++;
    80004476:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004478:	0004c783          	lbu	a5,0(s1)
    8000447c:	ff278de3          	beq	a5,s2,80004476 <namex+0xc8>
    ilock(ip);
    80004480:	8552                	mv	a0,s4
    80004482:	00000097          	auipc	ra,0x0
    80004486:	998080e7          	jalr	-1640(ra) # 80003e1a <ilock>
    if(ip->type != T_DIR){
    8000448a:	044a1783          	lh	a5,68(s4)
    8000448e:	f98790e3          	bne	a5,s8,8000440e <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004492:	000b0563          	beqz	s6,8000449c <namex+0xee>
    80004496:	0004c783          	lbu	a5,0(s1)
    8000449a:	dfd9                	beqz	a5,80004438 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000449c:	865e                	mv	a2,s7
    8000449e:	85d6                	mv	a1,s5
    800044a0:	8552                	mv	a0,s4
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	e5c080e7          	jalr	-420(ra) # 800042fe <dirlookup>
    800044aa:	89aa                	mv	s3,a0
    800044ac:	dd41                	beqz	a0,80004444 <namex+0x96>
    iunlockput(ip);
    800044ae:	8552                	mv	a0,s4
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	bcc080e7          	jalr	-1076(ra) # 8000407c <iunlockput>
    ip = next;
    800044b8:	8a4e                	mv	s4,s3
  while(*path == '/')
    800044ba:	0004c783          	lbu	a5,0(s1)
    800044be:	01279763          	bne	a5,s2,800044cc <namex+0x11e>
    path++;
    800044c2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044c4:	0004c783          	lbu	a5,0(s1)
    800044c8:	ff278de3          	beq	a5,s2,800044c2 <namex+0x114>
  if(*path == 0)
    800044cc:	cb9d                	beqz	a5,80004502 <namex+0x154>
  while(*path != '/' && *path != 0)
    800044ce:	0004c783          	lbu	a5,0(s1)
    800044d2:	89a6                	mv	s3,s1
  len = path - s;
    800044d4:	8d5e                	mv	s10,s7
    800044d6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044d8:	01278963          	beq	a5,s2,800044ea <namex+0x13c>
    800044dc:	dbbd                	beqz	a5,80004452 <namex+0xa4>
    path++;
    800044de:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800044e0:	0009c783          	lbu	a5,0(s3)
    800044e4:	ff279ce3          	bne	a5,s2,800044dc <namex+0x12e>
    800044e8:	b7ad                	j	80004452 <namex+0xa4>
    memmove(name, s, len);
    800044ea:	2601                	sext.w	a2,a2
    800044ec:	85a6                	mv	a1,s1
    800044ee:	8556                	mv	a0,s5
    800044f0:	ffffd097          	auipc	ra,0xffffd
    800044f4:	884080e7          	jalr	-1916(ra) # 80000d74 <memmove>
    name[len] = 0;
    800044f8:	9d56                	add	s10,s10,s5
    800044fa:	000d0023          	sb	zero,0(s10)
    800044fe:	84ce                	mv	s1,s3
    80004500:	b7bd                	j	8000446e <namex+0xc0>
  if(nameiparent){
    80004502:	f00b0ce3          	beqz	s6,8000441a <namex+0x6c>
    iput(ip);
    80004506:	8552                	mv	a0,s4
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	acc080e7          	jalr	-1332(ra) # 80003fd4 <iput>
    return 0;
    80004510:	4a01                	li	s4,0
    80004512:	b721                	j	8000441a <namex+0x6c>

0000000080004514 <dirlink>:
{
    80004514:	7139                	addi	sp,sp,-64
    80004516:	fc06                	sd	ra,56(sp)
    80004518:	f822                	sd	s0,48(sp)
    8000451a:	f426                	sd	s1,40(sp)
    8000451c:	f04a                	sd	s2,32(sp)
    8000451e:	ec4e                	sd	s3,24(sp)
    80004520:	e852                	sd	s4,16(sp)
    80004522:	0080                	addi	s0,sp,64
    80004524:	892a                	mv	s2,a0
    80004526:	8a2e                	mv	s4,a1
    80004528:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000452a:	4601                	li	a2,0
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	dd2080e7          	jalr	-558(ra) # 800042fe <dirlookup>
    80004534:	e93d                	bnez	a0,800045aa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004536:	04c92483          	lw	s1,76(s2)
    8000453a:	c49d                	beqz	s1,80004568 <dirlink+0x54>
    8000453c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000453e:	4741                	li	a4,16
    80004540:	86a6                	mv	a3,s1
    80004542:	fc040613          	addi	a2,s0,-64
    80004546:	4581                	li	a1,0
    80004548:	854a                	mv	a0,s2
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	b84080e7          	jalr	-1148(ra) # 800040ce <readi>
    80004552:	47c1                	li	a5,16
    80004554:	06f51163          	bne	a0,a5,800045b6 <dirlink+0xa2>
    if(de.inum == 0)
    80004558:	fc045783          	lhu	a5,-64(s0)
    8000455c:	c791                	beqz	a5,80004568 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000455e:	24c1                	addiw	s1,s1,16
    80004560:	04c92783          	lw	a5,76(s2)
    80004564:	fcf4ede3          	bltu	s1,a5,8000453e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004568:	4639                	li	a2,14
    8000456a:	85d2                	mv	a1,s4
    8000456c:	fc240513          	addi	a0,s0,-62
    80004570:	ffffd097          	auipc	ra,0xffffd
    80004574:	8b4080e7          	jalr	-1868(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80004578:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000457c:	4741                	li	a4,16
    8000457e:	86a6                	mv	a3,s1
    80004580:	fc040613          	addi	a2,s0,-64
    80004584:	4581                	li	a1,0
    80004586:	854a                	mv	a0,s2
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	c3e080e7          	jalr	-962(ra) # 800041c6 <writei>
    80004590:	872a                	mv	a4,a0
    80004592:	47c1                	li	a5,16
  return 0;
    80004594:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004596:	02f71863          	bne	a4,a5,800045c6 <dirlink+0xb2>
}
    8000459a:	70e2                	ld	ra,56(sp)
    8000459c:	7442                	ld	s0,48(sp)
    8000459e:	74a2                	ld	s1,40(sp)
    800045a0:	7902                	ld	s2,32(sp)
    800045a2:	69e2                	ld	s3,24(sp)
    800045a4:	6a42                	ld	s4,16(sp)
    800045a6:	6121                	addi	sp,sp,64
    800045a8:	8082                	ret
    iput(ip);
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	a2a080e7          	jalr	-1494(ra) # 80003fd4 <iput>
    return -1;
    800045b2:	557d                	li	a0,-1
    800045b4:	b7dd                	j	8000459a <dirlink+0x86>
      panic("dirlink read");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	09250513          	addi	a0,a0,146 # 80008648 <syscalls+0x1e8>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f7e080e7          	jalr	-130(ra) # 8000053c <panic>
    panic("dirlink");
    800045c6:	00004517          	auipc	a0,0x4
    800045ca:	19250513          	addi	a0,a0,402 # 80008758 <syscalls+0x2f8>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	f6e080e7          	jalr	-146(ra) # 8000053c <panic>

00000000800045d6 <namei>:

struct inode*
namei(char *path)
{
    800045d6:	1101                	addi	sp,sp,-32
    800045d8:	ec06                	sd	ra,24(sp)
    800045da:	e822                	sd	s0,16(sp)
    800045dc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045de:	fe040613          	addi	a2,s0,-32
    800045e2:	4581                	li	a1,0
    800045e4:	00000097          	auipc	ra,0x0
    800045e8:	dca080e7          	jalr	-566(ra) # 800043ae <namex>
}
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045f4:	1141                	addi	sp,sp,-16
    800045f6:	e406                	sd	ra,8(sp)
    800045f8:	e022                	sd	s0,0(sp)
    800045fa:	0800                	addi	s0,sp,16
    800045fc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045fe:	4585                	li	a1,1
    80004600:	00000097          	auipc	ra,0x0
    80004604:	dae080e7          	jalr	-594(ra) # 800043ae <namex>
}
    80004608:	60a2                	ld	ra,8(sp)
    8000460a:	6402                	ld	s0,0(sp)
    8000460c:	0141                	addi	sp,sp,16
    8000460e:	8082                	ret

0000000080004610 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	e04a                	sd	s2,0(sp)
    8000461a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000461c:	0002d917          	auipc	s2,0x2d
    80004620:	26c90913          	addi	s2,s2,620 # 80031888 <log>
    80004624:	01892583          	lw	a1,24(s2)
    80004628:	02892503          	lw	a0,40(s2)
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	fec080e7          	jalr	-20(ra) # 80003618 <bread>
    80004634:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004636:	02c92683          	lw	a3,44(s2)
    8000463a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000463c:	02d05863          	blez	a3,8000466c <write_head+0x5c>
    80004640:	0002d797          	auipc	a5,0x2d
    80004644:	27878793          	addi	a5,a5,632 # 800318b8 <log+0x30>
    80004648:	05c50713          	addi	a4,a0,92
    8000464c:	36fd                	addiw	a3,a3,-1
    8000464e:	02069613          	slli	a2,a3,0x20
    80004652:	01e65693          	srli	a3,a2,0x1e
    80004656:	0002d617          	auipc	a2,0x2d
    8000465a:	26660613          	addi	a2,a2,614 # 800318bc <log+0x34>
    8000465e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004660:	4390                	lw	a2,0(a5)
    80004662:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004664:	0791                	addi	a5,a5,4
    80004666:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004668:	fed79ce3          	bne	a5,a3,80004660 <write_head+0x50>
  }
  bwrite(buf);
    8000466c:	8526                	mv	a0,s1
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	09c080e7          	jalr	156(ra) # 8000370a <bwrite>
  brelse(buf);
    80004676:	8526                	mv	a0,s1
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	0d0080e7          	jalr	208(ra) # 80003748 <brelse>
}
    80004680:	60e2                	ld	ra,24(sp)
    80004682:	6442                	ld	s0,16(sp)
    80004684:	64a2                	ld	s1,8(sp)
    80004686:	6902                	ld	s2,0(sp)
    80004688:	6105                	addi	sp,sp,32
    8000468a:	8082                	ret

000000008000468c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000468c:	0002d797          	auipc	a5,0x2d
    80004690:	2287a783          	lw	a5,552(a5) # 800318b4 <log+0x2c>
    80004694:	0af05d63          	blez	a5,8000474e <install_trans+0xc2>
{
    80004698:	7139                	addi	sp,sp,-64
    8000469a:	fc06                	sd	ra,56(sp)
    8000469c:	f822                	sd	s0,48(sp)
    8000469e:	f426                	sd	s1,40(sp)
    800046a0:	f04a                	sd	s2,32(sp)
    800046a2:	ec4e                	sd	s3,24(sp)
    800046a4:	e852                	sd	s4,16(sp)
    800046a6:	e456                	sd	s5,8(sp)
    800046a8:	e05a                	sd	s6,0(sp)
    800046aa:	0080                	addi	s0,sp,64
    800046ac:	8b2a                	mv	s6,a0
    800046ae:	0002da97          	auipc	s5,0x2d
    800046b2:	20aa8a93          	addi	s5,s5,522 # 800318b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046b8:	0002d997          	auipc	s3,0x2d
    800046bc:	1d098993          	addi	s3,s3,464 # 80031888 <log>
    800046c0:	a00d                	j	800046e2 <install_trans+0x56>
    brelse(lbuf);
    800046c2:	854a                	mv	a0,s2
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	084080e7          	jalr	132(ra) # 80003748 <brelse>
    brelse(dbuf);
    800046cc:	8526                	mv	a0,s1
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	07a080e7          	jalr	122(ra) # 80003748 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046d6:	2a05                	addiw	s4,s4,1
    800046d8:	0a91                	addi	s5,s5,4
    800046da:	02c9a783          	lw	a5,44(s3)
    800046de:	04fa5e63          	bge	s4,a5,8000473a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046e2:	0189a583          	lw	a1,24(s3)
    800046e6:	014585bb          	addw	a1,a1,s4
    800046ea:	2585                	addiw	a1,a1,1
    800046ec:	0289a503          	lw	a0,40(s3)
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	f28080e7          	jalr	-216(ra) # 80003618 <bread>
    800046f8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046fa:	000aa583          	lw	a1,0(s5)
    800046fe:	0289a503          	lw	a0,40(s3)
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	f16080e7          	jalr	-234(ra) # 80003618 <bread>
    8000470a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000470c:	40000613          	li	a2,1024
    80004710:	05890593          	addi	a1,s2,88
    80004714:	05850513          	addi	a0,a0,88
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	65c080e7          	jalr	1628(ra) # 80000d74 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004720:	8526                	mv	a0,s1
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	fe8080e7          	jalr	-24(ra) # 8000370a <bwrite>
    if(recovering == 0)
    8000472a:	f80b1ce3          	bnez	s6,800046c2 <install_trans+0x36>
      bunpin(dbuf);
    8000472e:	8526                	mv	a0,s1
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	0f2080e7          	jalr	242(ra) # 80003822 <bunpin>
    80004738:	b769                	j	800046c2 <install_trans+0x36>
}
    8000473a:	70e2                	ld	ra,56(sp)
    8000473c:	7442                	ld	s0,48(sp)
    8000473e:	74a2                	ld	s1,40(sp)
    80004740:	7902                	ld	s2,32(sp)
    80004742:	69e2                	ld	s3,24(sp)
    80004744:	6a42                	ld	s4,16(sp)
    80004746:	6aa2                	ld	s5,8(sp)
    80004748:	6b02                	ld	s6,0(sp)
    8000474a:	6121                	addi	sp,sp,64
    8000474c:	8082                	ret
    8000474e:	8082                	ret

0000000080004750 <initlog>:
{
    80004750:	7179                	addi	sp,sp,-48
    80004752:	f406                	sd	ra,40(sp)
    80004754:	f022                	sd	s0,32(sp)
    80004756:	ec26                	sd	s1,24(sp)
    80004758:	e84a                	sd	s2,16(sp)
    8000475a:	e44e                	sd	s3,8(sp)
    8000475c:	1800                	addi	s0,sp,48
    8000475e:	892a                	mv	s2,a0
    80004760:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004762:	0002d497          	auipc	s1,0x2d
    80004766:	12648493          	addi	s1,s1,294 # 80031888 <log>
    8000476a:	00004597          	auipc	a1,0x4
    8000476e:	eee58593          	addi	a1,a1,-274 # 80008658 <syscalls+0x1f8>
    80004772:	8526                	mv	a0,s1
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	418080e7          	jalr	1048(ra) # 80000b8c <initlock>
  log.start = sb->logstart;
    8000477c:	0149a583          	lw	a1,20(s3)
    80004780:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004782:	0109a783          	lw	a5,16(s3)
    80004786:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004788:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000478c:	854a                	mv	a0,s2
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	e8a080e7          	jalr	-374(ra) # 80003618 <bread>
  log.lh.n = lh->n;
    80004796:	4d34                	lw	a3,88(a0)
    80004798:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000479a:	02d05663          	blez	a3,800047c6 <initlog+0x76>
    8000479e:	05c50793          	addi	a5,a0,92
    800047a2:	0002d717          	auipc	a4,0x2d
    800047a6:	11670713          	addi	a4,a4,278 # 800318b8 <log+0x30>
    800047aa:	36fd                	addiw	a3,a3,-1
    800047ac:	02069613          	slli	a2,a3,0x20
    800047b0:	01e65693          	srli	a3,a2,0x1e
    800047b4:	06050613          	addi	a2,a0,96
    800047b8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800047ba:	4390                	lw	a2,0(a5)
    800047bc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047be:	0791                	addi	a5,a5,4
    800047c0:	0711                	addi	a4,a4,4
    800047c2:	fed79ce3          	bne	a5,a3,800047ba <initlog+0x6a>
  brelse(buf);
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	f82080e7          	jalr	-126(ra) # 80003748 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047ce:	4505                	li	a0,1
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	ebc080e7          	jalr	-324(ra) # 8000468c <install_trans>
  log.lh.n = 0;
    800047d8:	0002d797          	auipc	a5,0x2d
    800047dc:	0c07ae23          	sw	zero,220(a5) # 800318b4 <log+0x2c>
  write_head(); // clear the log
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	e30080e7          	jalr	-464(ra) # 80004610 <write_head>
}
    800047e8:	70a2                	ld	ra,40(sp)
    800047ea:	7402                	ld	s0,32(sp)
    800047ec:	64e2                	ld	s1,24(sp)
    800047ee:	6942                	ld	s2,16(sp)
    800047f0:	69a2                	ld	s3,8(sp)
    800047f2:	6145                	addi	sp,sp,48
    800047f4:	8082                	ret

00000000800047f6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047f6:	1101                	addi	sp,sp,-32
    800047f8:	ec06                	sd	ra,24(sp)
    800047fa:	e822                	sd	s0,16(sp)
    800047fc:	e426                	sd	s1,8(sp)
    800047fe:	e04a                	sd	s2,0(sp)
    80004800:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004802:	0002d517          	auipc	a0,0x2d
    80004806:	08650513          	addi	a0,a0,134 # 80031888 <log>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	412080e7          	jalr	1042(ra) # 80000c1c <acquire>
  while(1){
    if(log.committing){
    80004812:	0002d497          	auipc	s1,0x2d
    80004816:	07648493          	addi	s1,s1,118 # 80031888 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000481a:	4979                	li	s2,30
    8000481c:	a039                	j	8000482a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000481e:	85a6                	mv	a1,s1
    80004820:	8526                	mv	a0,s1
    80004822:	ffffd097          	auipc	ra,0xffffd
    80004826:	6ca080e7          	jalr	1738(ra) # 80001eec <sleep>
    if(log.committing){
    8000482a:	50dc                	lw	a5,36(s1)
    8000482c:	fbed                	bnez	a5,8000481e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000482e:	5098                	lw	a4,32(s1)
    80004830:	2705                	addiw	a4,a4,1
    80004832:	0007069b          	sext.w	a3,a4
    80004836:	0027179b          	slliw	a5,a4,0x2
    8000483a:	9fb9                	addw	a5,a5,a4
    8000483c:	0017979b          	slliw	a5,a5,0x1
    80004840:	54d8                	lw	a4,44(s1)
    80004842:	9fb9                	addw	a5,a5,a4
    80004844:	00f95963          	bge	s2,a5,80004856 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004848:	85a6                	mv	a1,s1
    8000484a:	8526                	mv	a0,s1
    8000484c:	ffffd097          	auipc	ra,0xffffd
    80004850:	6a0080e7          	jalr	1696(ra) # 80001eec <sleep>
    80004854:	bfd9                	j	8000482a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004856:	0002d517          	auipc	a0,0x2d
    8000485a:	03250513          	addi	a0,a0,50 # 80031888 <log>
    8000485e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	470080e7          	jalr	1136(ra) # 80000cd0 <release>
      break;
    }
  }
}
    80004868:	60e2                	ld	ra,24(sp)
    8000486a:	6442                	ld	s0,16(sp)
    8000486c:	64a2                	ld	s1,8(sp)
    8000486e:	6902                	ld	s2,0(sp)
    80004870:	6105                	addi	sp,sp,32
    80004872:	8082                	ret

0000000080004874 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004874:	7139                	addi	sp,sp,-64
    80004876:	fc06                	sd	ra,56(sp)
    80004878:	f822                	sd	s0,48(sp)
    8000487a:	f426                	sd	s1,40(sp)
    8000487c:	f04a                	sd	s2,32(sp)
    8000487e:	ec4e                	sd	s3,24(sp)
    80004880:	e852                	sd	s4,16(sp)
    80004882:	e456                	sd	s5,8(sp)
    80004884:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004886:	0002d497          	auipc	s1,0x2d
    8000488a:	00248493          	addi	s1,s1,2 # 80031888 <log>
    8000488e:	8526                	mv	a0,s1
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	38c080e7          	jalr	908(ra) # 80000c1c <acquire>
  log.outstanding -= 1;
    80004898:	509c                	lw	a5,32(s1)
    8000489a:	37fd                	addiw	a5,a5,-1
    8000489c:	0007891b          	sext.w	s2,a5
    800048a0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048a2:	50dc                	lw	a5,36(s1)
    800048a4:	e7b9                	bnez	a5,800048f2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048a6:	04091e63          	bnez	s2,80004902 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800048aa:	0002d497          	auipc	s1,0x2d
    800048ae:	fde48493          	addi	s1,s1,-34 # 80031888 <log>
    800048b2:	4785                	li	a5,1
    800048b4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048b6:	8526                	mv	a0,s1
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	418080e7          	jalr	1048(ra) # 80000cd0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048c0:	54dc                	lw	a5,44(s1)
    800048c2:	06f04763          	bgtz	a5,80004930 <end_op+0xbc>
    acquire(&log.lock);
    800048c6:	0002d497          	auipc	s1,0x2d
    800048ca:	fc248493          	addi	s1,s1,-62 # 80031888 <log>
    800048ce:	8526                	mv	a0,s1
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	34c080e7          	jalr	844(ra) # 80000c1c <acquire>
    log.committing = 0;
    800048d8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048dc:	8526                	mv	a0,s1
    800048de:	ffffd097          	auipc	ra,0xffffd
    800048e2:	67e080e7          	jalr	1662(ra) # 80001f5c <wakeup>
    release(&log.lock);
    800048e6:	8526                	mv	a0,s1
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	3e8080e7          	jalr	1000(ra) # 80000cd0 <release>
}
    800048f0:	a03d                	j	8000491e <end_op+0xaa>
    panic("log.committing");
    800048f2:	00004517          	auipc	a0,0x4
    800048f6:	d6e50513          	addi	a0,a0,-658 # 80008660 <syscalls+0x200>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	c42080e7          	jalr	-958(ra) # 8000053c <panic>
    wakeup(&log);
    80004902:	0002d497          	auipc	s1,0x2d
    80004906:	f8648493          	addi	s1,s1,-122 # 80031888 <log>
    8000490a:	8526                	mv	a0,s1
    8000490c:	ffffd097          	auipc	ra,0xffffd
    80004910:	650080e7          	jalr	1616(ra) # 80001f5c <wakeup>
  release(&log.lock);
    80004914:	8526                	mv	a0,s1
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	3ba080e7          	jalr	954(ra) # 80000cd0 <release>
}
    8000491e:	70e2                	ld	ra,56(sp)
    80004920:	7442                	ld	s0,48(sp)
    80004922:	74a2                	ld	s1,40(sp)
    80004924:	7902                	ld	s2,32(sp)
    80004926:	69e2                	ld	s3,24(sp)
    80004928:	6a42                	ld	s4,16(sp)
    8000492a:	6aa2                	ld	s5,8(sp)
    8000492c:	6121                	addi	sp,sp,64
    8000492e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004930:	0002da97          	auipc	s5,0x2d
    80004934:	f88a8a93          	addi	s5,s5,-120 # 800318b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004938:	0002da17          	auipc	s4,0x2d
    8000493c:	f50a0a13          	addi	s4,s4,-176 # 80031888 <log>
    80004940:	018a2583          	lw	a1,24(s4)
    80004944:	012585bb          	addw	a1,a1,s2
    80004948:	2585                	addiw	a1,a1,1
    8000494a:	028a2503          	lw	a0,40(s4)
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	cca080e7          	jalr	-822(ra) # 80003618 <bread>
    80004956:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004958:	000aa583          	lw	a1,0(s5)
    8000495c:	028a2503          	lw	a0,40(s4)
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	cb8080e7          	jalr	-840(ra) # 80003618 <bread>
    80004968:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000496a:	40000613          	li	a2,1024
    8000496e:	05850593          	addi	a1,a0,88
    80004972:	05848513          	addi	a0,s1,88
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	3fe080e7          	jalr	1022(ra) # 80000d74 <memmove>
    bwrite(to);  // write the log
    8000497e:	8526                	mv	a0,s1
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	d8a080e7          	jalr	-630(ra) # 8000370a <bwrite>
    brelse(from);
    80004988:	854e                	mv	a0,s3
    8000498a:	fffff097          	auipc	ra,0xfffff
    8000498e:	dbe080e7          	jalr	-578(ra) # 80003748 <brelse>
    brelse(to);
    80004992:	8526                	mv	a0,s1
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	db4080e7          	jalr	-588(ra) # 80003748 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000499c:	2905                	addiw	s2,s2,1
    8000499e:	0a91                	addi	s5,s5,4
    800049a0:	02ca2783          	lw	a5,44(s4)
    800049a4:	f8f94ee3          	blt	s2,a5,80004940 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	c68080e7          	jalr	-920(ra) # 80004610 <write_head>
    install_trans(0); // Now install writes to home locations
    800049b0:	4501                	li	a0,0
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	cda080e7          	jalr	-806(ra) # 8000468c <install_trans>
    log.lh.n = 0;
    800049ba:	0002d797          	auipc	a5,0x2d
    800049be:	ee07ad23          	sw	zero,-262(a5) # 800318b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	c4e080e7          	jalr	-946(ra) # 80004610 <write_head>
    800049ca:	bdf5                	j	800048c6 <end_op+0x52>

00000000800049cc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049cc:	1101                	addi	sp,sp,-32
    800049ce:	ec06                	sd	ra,24(sp)
    800049d0:	e822                	sd	s0,16(sp)
    800049d2:	e426                	sd	s1,8(sp)
    800049d4:	e04a                	sd	s2,0(sp)
    800049d6:	1000                	addi	s0,sp,32
    800049d8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049da:	0002d917          	auipc	s2,0x2d
    800049de:	eae90913          	addi	s2,s2,-338 # 80031888 <log>
    800049e2:	854a                	mv	a0,s2
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	238080e7          	jalr	568(ra) # 80000c1c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049ec:	02c92603          	lw	a2,44(s2)
    800049f0:	47f5                	li	a5,29
    800049f2:	06c7c563          	blt	a5,a2,80004a5c <log_write+0x90>
    800049f6:	0002d797          	auipc	a5,0x2d
    800049fa:	eae7a783          	lw	a5,-338(a5) # 800318a4 <log+0x1c>
    800049fe:	37fd                	addiw	a5,a5,-1
    80004a00:	04f65e63          	bge	a2,a5,80004a5c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a04:	0002d797          	auipc	a5,0x2d
    80004a08:	ea47a783          	lw	a5,-348(a5) # 800318a8 <log+0x20>
    80004a0c:	06f05063          	blez	a5,80004a6c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a10:	4781                	li	a5,0
    80004a12:	06c05563          	blez	a2,80004a7c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a16:	44cc                	lw	a1,12(s1)
    80004a18:	0002d717          	auipc	a4,0x2d
    80004a1c:	ea070713          	addi	a4,a4,-352 # 800318b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a20:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a22:	4314                	lw	a3,0(a4)
    80004a24:	04b68c63          	beq	a3,a1,80004a7c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a28:	2785                	addiw	a5,a5,1
    80004a2a:	0711                	addi	a4,a4,4
    80004a2c:	fef61be3          	bne	a2,a5,80004a22 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a30:	0621                	addi	a2,a2,8
    80004a32:	060a                	slli	a2,a2,0x2
    80004a34:	0002d797          	auipc	a5,0x2d
    80004a38:	e5478793          	addi	a5,a5,-428 # 80031888 <log>
    80004a3c:	97b2                	add	a5,a5,a2
    80004a3e:	44d8                	lw	a4,12(s1)
    80004a40:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a42:	8526                	mv	a0,s1
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	da2080e7          	jalr	-606(ra) # 800037e6 <bpin>
    log.lh.n++;
    80004a4c:	0002d717          	auipc	a4,0x2d
    80004a50:	e3c70713          	addi	a4,a4,-452 # 80031888 <log>
    80004a54:	575c                	lw	a5,44(a4)
    80004a56:	2785                	addiw	a5,a5,1
    80004a58:	d75c                	sw	a5,44(a4)
    80004a5a:	a82d                	j	80004a94 <log_write+0xc8>
    panic("too big a transaction");
    80004a5c:	00004517          	auipc	a0,0x4
    80004a60:	c1450513          	addi	a0,a0,-1004 # 80008670 <syscalls+0x210>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	ad8080e7          	jalr	-1320(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004a6c:	00004517          	auipc	a0,0x4
    80004a70:	c1c50513          	addi	a0,a0,-996 # 80008688 <syscalls+0x228>
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	ac8080e7          	jalr	-1336(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004a7c:	00878693          	addi	a3,a5,8
    80004a80:	068a                	slli	a3,a3,0x2
    80004a82:	0002d717          	auipc	a4,0x2d
    80004a86:	e0670713          	addi	a4,a4,-506 # 80031888 <log>
    80004a8a:	9736                	add	a4,a4,a3
    80004a8c:	44d4                	lw	a3,12(s1)
    80004a8e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a90:	faf609e3          	beq	a2,a5,80004a42 <log_write+0x76>
  }
  release(&log.lock);
    80004a94:	0002d517          	auipc	a0,0x2d
    80004a98:	df450513          	addi	a0,a0,-524 # 80031888 <log>
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	234080e7          	jalr	564(ra) # 80000cd0 <release>
}
    80004aa4:	60e2                	ld	ra,24(sp)
    80004aa6:	6442                	ld	s0,16(sp)
    80004aa8:	64a2                	ld	s1,8(sp)
    80004aaa:	6902                	ld	s2,0(sp)
    80004aac:	6105                	addi	sp,sp,32
    80004aae:	8082                	ret

0000000080004ab0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ab0:	1101                	addi	sp,sp,-32
    80004ab2:	ec06                	sd	ra,24(sp)
    80004ab4:	e822                	sd	s0,16(sp)
    80004ab6:	e426                	sd	s1,8(sp)
    80004ab8:	e04a                	sd	s2,0(sp)
    80004aba:	1000                	addi	s0,sp,32
    80004abc:	84aa                	mv	s1,a0
    80004abe:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ac0:	00004597          	auipc	a1,0x4
    80004ac4:	be858593          	addi	a1,a1,-1048 # 800086a8 <syscalls+0x248>
    80004ac8:	0521                	addi	a0,a0,8
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	0c2080e7          	jalr	194(ra) # 80000b8c <initlock>
  lk->name = name;
    80004ad2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ad6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ada:	0204a423          	sw	zero,40(s1)
}
    80004ade:	60e2                	ld	ra,24(sp)
    80004ae0:	6442                	ld	s0,16(sp)
    80004ae2:	64a2                	ld	s1,8(sp)
    80004ae4:	6902                	ld	s2,0(sp)
    80004ae6:	6105                	addi	sp,sp,32
    80004ae8:	8082                	ret

0000000080004aea <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004aea:	1101                	addi	sp,sp,-32
    80004aec:	ec06                	sd	ra,24(sp)
    80004aee:	e822                	sd	s0,16(sp)
    80004af0:	e426                	sd	s1,8(sp)
    80004af2:	e04a                	sd	s2,0(sp)
    80004af4:	1000                	addi	s0,sp,32
    80004af6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004af8:	00850913          	addi	s2,a0,8
    80004afc:	854a                	mv	a0,s2
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	11e080e7          	jalr	286(ra) # 80000c1c <acquire>
  while (lk->locked) {
    80004b06:	409c                	lw	a5,0(s1)
    80004b08:	cb89                	beqz	a5,80004b1a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b0a:	85ca                	mv	a1,s2
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	3de080e7          	jalr	990(ra) # 80001eec <sleep>
  while (lk->locked) {
    80004b16:	409c                	lw	a5,0(s1)
    80004b18:	fbed                	bnez	a5,80004b0a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b1a:	4785                	li	a5,1
    80004b1c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	fce080e7          	jalr	-50(ra) # 80001aec <myproc>
    80004b26:	30852783          	lw	a5,776(a0)
    80004b2a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b2c:	854a                	mv	a0,s2
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	1a2080e7          	jalr	418(ra) # 80000cd0 <release>
}
    80004b36:	60e2                	ld	ra,24(sp)
    80004b38:	6442                	ld	s0,16(sp)
    80004b3a:	64a2                	ld	s1,8(sp)
    80004b3c:	6902                	ld	s2,0(sp)
    80004b3e:	6105                	addi	sp,sp,32
    80004b40:	8082                	ret

0000000080004b42 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b42:	1101                	addi	sp,sp,-32
    80004b44:	ec06                	sd	ra,24(sp)
    80004b46:	e822                	sd	s0,16(sp)
    80004b48:	e426                	sd	s1,8(sp)
    80004b4a:	e04a                	sd	s2,0(sp)
    80004b4c:	1000                	addi	s0,sp,32
    80004b4e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b50:	00850913          	addi	s2,a0,8
    80004b54:	854a                	mv	a0,s2
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	0c6080e7          	jalr	198(ra) # 80000c1c <acquire>
  lk->locked = 0;
    80004b5e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b62:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b66:	8526                	mv	a0,s1
    80004b68:	ffffd097          	auipc	ra,0xffffd
    80004b6c:	3f4080e7          	jalr	1012(ra) # 80001f5c <wakeup>
  release(&lk->lk);
    80004b70:	854a                	mv	a0,s2
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	15e080e7          	jalr	350(ra) # 80000cd0 <release>
}
    80004b7a:	60e2                	ld	ra,24(sp)
    80004b7c:	6442                	ld	s0,16(sp)
    80004b7e:	64a2                	ld	s1,8(sp)
    80004b80:	6902                	ld	s2,0(sp)
    80004b82:	6105                	addi	sp,sp,32
    80004b84:	8082                	ret

0000000080004b86 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b86:	7179                	addi	sp,sp,-48
    80004b88:	f406                	sd	ra,40(sp)
    80004b8a:	f022                	sd	s0,32(sp)
    80004b8c:	ec26                	sd	s1,24(sp)
    80004b8e:	e84a                	sd	s2,16(sp)
    80004b90:	e44e                	sd	s3,8(sp)
    80004b92:	1800                	addi	s0,sp,48
    80004b94:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b96:	00850913          	addi	s2,a0,8
    80004b9a:	854a                	mv	a0,s2
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	080080e7          	jalr	128(ra) # 80000c1c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ba4:	409c                	lw	a5,0(s1)
    80004ba6:	ef99                	bnez	a5,80004bc4 <holdingsleep+0x3e>
    80004ba8:	4481                	li	s1,0
  release(&lk->lk);
    80004baa:	854a                	mv	a0,s2
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	124080e7          	jalr	292(ra) # 80000cd0 <release>
  return r;
}
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	70a2                	ld	ra,40(sp)
    80004bb8:	7402                	ld	s0,32(sp)
    80004bba:	64e2                	ld	s1,24(sp)
    80004bbc:	6942                	ld	s2,16(sp)
    80004bbe:	69a2                	ld	s3,8(sp)
    80004bc0:	6145                	addi	sp,sp,48
    80004bc2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bc4:	0284a983          	lw	s3,40(s1)
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	f24080e7          	jalr	-220(ra) # 80001aec <myproc>
    80004bd0:	30852483          	lw	s1,776(a0)
    80004bd4:	413484b3          	sub	s1,s1,s3
    80004bd8:	0014b493          	seqz	s1,s1
    80004bdc:	b7f9                	j	80004baa <holdingsleep+0x24>

0000000080004bde <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bde:	1141                	addi	sp,sp,-16
    80004be0:	e406                	sd	ra,8(sp)
    80004be2:	e022                	sd	s0,0(sp)
    80004be4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004be6:	00004597          	auipc	a1,0x4
    80004bea:	ad258593          	addi	a1,a1,-1326 # 800086b8 <syscalls+0x258>
    80004bee:	0002d517          	auipc	a0,0x2d
    80004bf2:	de250513          	addi	a0,a0,-542 # 800319d0 <ftable>
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	f96080e7          	jalr	-106(ra) # 80000b8c <initlock>
}
    80004bfe:	60a2                	ld	ra,8(sp)
    80004c00:	6402                	ld	s0,0(sp)
    80004c02:	0141                	addi	sp,sp,16
    80004c04:	8082                	ret

0000000080004c06 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c06:	1101                	addi	sp,sp,-32
    80004c08:	ec06                	sd	ra,24(sp)
    80004c0a:	e822                	sd	s0,16(sp)
    80004c0c:	e426                	sd	s1,8(sp)
    80004c0e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c10:	0002d517          	auipc	a0,0x2d
    80004c14:	dc050513          	addi	a0,a0,-576 # 800319d0 <ftable>
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	004080e7          	jalr	4(ra) # 80000c1c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c20:	0002d497          	auipc	s1,0x2d
    80004c24:	dc848493          	addi	s1,s1,-568 # 800319e8 <ftable+0x18>
    80004c28:	0002e717          	auipc	a4,0x2e
    80004c2c:	d6070713          	addi	a4,a4,-672 # 80032988 <ftable+0xfb8>
    if(f->ref == 0){
    80004c30:	40dc                	lw	a5,4(s1)
    80004c32:	cf99                	beqz	a5,80004c50 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c34:	02848493          	addi	s1,s1,40
    80004c38:	fee49ce3          	bne	s1,a4,80004c30 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c3c:	0002d517          	auipc	a0,0x2d
    80004c40:	d9450513          	addi	a0,a0,-620 # 800319d0 <ftable>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	08c080e7          	jalr	140(ra) # 80000cd0 <release>
  return 0;
    80004c4c:	4481                	li	s1,0
    80004c4e:	a819                	j	80004c64 <filealloc+0x5e>
      f->ref = 1;
    80004c50:	4785                	li	a5,1
    80004c52:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c54:	0002d517          	auipc	a0,0x2d
    80004c58:	d7c50513          	addi	a0,a0,-644 # 800319d0 <ftable>
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	074080e7          	jalr	116(ra) # 80000cd0 <release>
}
    80004c64:	8526                	mv	a0,s1
    80004c66:	60e2                	ld	ra,24(sp)
    80004c68:	6442                	ld	s0,16(sp)
    80004c6a:	64a2                	ld	s1,8(sp)
    80004c6c:	6105                	addi	sp,sp,32
    80004c6e:	8082                	ret

0000000080004c70 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c70:	1101                	addi	sp,sp,-32
    80004c72:	ec06                	sd	ra,24(sp)
    80004c74:	e822                	sd	s0,16(sp)
    80004c76:	e426                	sd	s1,8(sp)
    80004c78:	1000                	addi	s0,sp,32
    80004c7a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c7c:	0002d517          	auipc	a0,0x2d
    80004c80:	d5450513          	addi	a0,a0,-684 # 800319d0 <ftable>
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	f98080e7          	jalr	-104(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    80004c8c:	40dc                	lw	a5,4(s1)
    80004c8e:	02f05263          	blez	a5,80004cb2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c92:	2785                	addiw	a5,a5,1
    80004c94:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c96:	0002d517          	auipc	a0,0x2d
    80004c9a:	d3a50513          	addi	a0,a0,-710 # 800319d0 <ftable>
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	032080e7          	jalr	50(ra) # 80000cd0 <release>
  return f;
}
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	60e2                	ld	ra,24(sp)
    80004caa:	6442                	ld	s0,16(sp)
    80004cac:	64a2                	ld	s1,8(sp)
    80004cae:	6105                	addi	sp,sp,32
    80004cb0:	8082                	ret
    panic("filedup");
    80004cb2:	00004517          	auipc	a0,0x4
    80004cb6:	a0e50513          	addi	a0,a0,-1522 # 800086c0 <syscalls+0x260>
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	882080e7          	jalr	-1918(ra) # 8000053c <panic>

0000000080004cc2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cc2:	7139                	addi	sp,sp,-64
    80004cc4:	fc06                	sd	ra,56(sp)
    80004cc6:	f822                	sd	s0,48(sp)
    80004cc8:	f426                	sd	s1,40(sp)
    80004cca:	f04a                	sd	s2,32(sp)
    80004ccc:	ec4e                	sd	s3,24(sp)
    80004cce:	e852                	sd	s4,16(sp)
    80004cd0:	e456                	sd	s5,8(sp)
    80004cd2:	0080                	addi	s0,sp,64
    80004cd4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cd6:	0002d517          	auipc	a0,0x2d
    80004cda:	cfa50513          	addi	a0,a0,-774 # 800319d0 <ftable>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	f3e080e7          	jalr	-194(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    80004ce6:	40dc                	lw	a5,4(s1)
    80004ce8:	06f05163          	blez	a5,80004d4a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cec:	37fd                	addiw	a5,a5,-1
    80004cee:	0007871b          	sext.w	a4,a5
    80004cf2:	c0dc                	sw	a5,4(s1)
    80004cf4:	06e04363          	bgtz	a4,80004d5a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cf8:	0004a903          	lw	s2,0(s1)
    80004cfc:	0094ca83          	lbu	s5,9(s1)
    80004d00:	0104ba03          	ld	s4,16(s1)
    80004d04:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d08:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d0c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d10:	0002d517          	auipc	a0,0x2d
    80004d14:	cc050513          	addi	a0,a0,-832 # 800319d0 <ftable>
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	fb8080e7          	jalr	-72(ra) # 80000cd0 <release>

  if(ff.type == FD_PIPE){
    80004d20:	4785                	li	a5,1
    80004d22:	04f90d63          	beq	s2,a5,80004d7c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d26:	3979                	addiw	s2,s2,-2
    80004d28:	4785                	li	a5,1
    80004d2a:	0527e063          	bltu	a5,s2,80004d6a <fileclose+0xa8>
    begin_op();
    80004d2e:	00000097          	auipc	ra,0x0
    80004d32:	ac8080e7          	jalr	-1336(ra) # 800047f6 <begin_op>
    iput(ff.ip);
    80004d36:	854e                	mv	a0,s3
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	29c080e7          	jalr	668(ra) # 80003fd4 <iput>
    end_op();
    80004d40:	00000097          	auipc	ra,0x0
    80004d44:	b34080e7          	jalr	-1228(ra) # 80004874 <end_op>
    80004d48:	a00d                	j	80004d6a <fileclose+0xa8>
    panic("fileclose");
    80004d4a:	00004517          	auipc	a0,0x4
    80004d4e:	97e50513          	addi	a0,a0,-1666 # 800086c8 <syscalls+0x268>
    80004d52:	ffffb097          	auipc	ra,0xffffb
    80004d56:	7ea080e7          	jalr	2026(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004d5a:	0002d517          	auipc	a0,0x2d
    80004d5e:	c7650513          	addi	a0,a0,-906 # 800319d0 <ftable>
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	f6e080e7          	jalr	-146(ra) # 80000cd0 <release>
  }
}
    80004d6a:	70e2                	ld	ra,56(sp)
    80004d6c:	7442                	ld	s0,48(sp)
    80004d6e:	74a2                	ld	s1,40(sp)
    80004d70:	7902                	ld	s2,32(sp)
    80004d72:	69e2                	ld	s3,24(sp)
    80004d74:	6a42                	ld	s4,16(sp)
    80004d76:	6aa2                	ld	s5,8(sp)
    80004d78:	6121                	addi	sp,sp,64
    80004d7a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d7c:	85d6                	mv	a1,s5
    80004d7e:	8552                	mv	a0,s4
    80004d80:	00000097          	auipc	ra,0x0
    80004d84:	34c080e7          	jalr	844(ra) # 800050cc <pipeclose>
    80004d88:	b7cd                	j	80004d6a <fileclose+0xa8>

0000000080004d8a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d8a:	715d                	addi	sp,sp,-80
    80004d8c:	e486                	sd	ra,72(sp)
    80004d8e:	e0a2                	sd	s0,64(sp)
    80004d90:	fc26                	sd	s1,56(sp)
    80004d92:	f84a                	sd	s2,48(sp)
    80004d94:	f44e                	sd	s3,40(sp)
    80004d96:	0880                	addi	s0,sp,80
    80004d98:	84aa                	mv	s1,a0
    80004d9a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	d50080e7          	jalr	-688(ra) # 80001aec <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004da4:	409c                	lw	a5,0(s1)
    80004da6:	37f9                	addiw	a5,a5,-2
    80004da8:	4705                	li	a4,1
    80004daa:	04f76763          	bltu	a4,a5,80004df8 <filestat+0x6e>
    80004dae:	892a                	mv	s2,a0
    ilock(f->ip);
    80004db0:	6c88                	ld	a0,24(s1)
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	068080e7          	jalr	104(ra) # 80003e1a <ilock>
    stati(f->ip, &st);
    80004dba:	fb840593          	addi	a1,s0,-72
    80004dbe:	6c88                	ld	a0,24(s1)
    80004dc0:	fffff097          	auipc	ra,0xfffff
    80004dc4:	2e4080e7          	jalr	740(ra) # 800040a4 <stati>
    iunlock(f->ip);
    80004dc8:	6c88                	ld	a0,24(s1)
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	112080e7          	jalr	274(ra) # 80003edc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004dd2:	46e1                	li	a3,24
    80004dd4:	fb840613          	addi	a2,s0,-72
    80004dd8:	85ce                	mv	a1,s3
    80004dda:	32893503          	ld	a0,808(s2)
    80004dde:	ffffd097          	auipc	ra,0xffffd
    80004de2:	954080e7          	jalr	-1708(ra) # 80001732 <copyout>
    80004de6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dea:	60a6                	ld	ra,72(sp)
    80004dec:	6406                	ld	s0,64(sp)
    80004dee:	74e2                	ld	s1,56(sp)
    80004df0:	7942                	ld	s2,48(sp)
    80004df2:	79a2                	ld	s3,40(sp)
    80004df4:	6161                	addi	sp,sp,80
    80004df6:	8082                	ret
  return -1;
    80004df8:	557d                	li	a0,-1
    80004dfa:	bfc5                	j	80004dea <filestat+0x60>

0000000080004dfc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dfc:	7179                	addi	sp,sp,-48
    80004dfe:	f406                	sd	ra,40(sp)
    80004e00:	f022                	sd	s0,32(sp)
    80004e02:	ec26                	sd	s1,24(sp)
    80004e04:	e84a                	sd	s2,16(sp)
    80004e06:	e44e                	sd	s3,8(sp)
    80004e08:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e0a:	00854783          	lbu	a5,8(a0)
    80004e0e:	c3d5                	beqz	a5,80004eb2 <fileread+0xb6>
    80004e10:	84aa                	mv	s1,a0
    80004e12:	89ae                	mv	s3,a1
    80004e14:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e16:	411c                	lw	a5,0(a0)
    80004e18:	4705                	li	a4,1
    80004e1a:	04e78963          	beq	a5,a4,80004e6c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e1e:	470d                	li	a4,3
    80004e20:	04e78d63          	beq	a5,a4,80004e7a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e24:	4709                	li	a4,2
    80004e26:	06e79e63          	bne	a5,a4,80004ea2 <fileread+0xa6>
    ilock(f->ip);
    80004e2a:	6d08                	ld	a0,24(a0)
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	fee080e7          	jalr	-18(ra) # 80003e1a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e34:	874a                	mv	a4,s2
    80004e36:	5094                	lw	a3,32(s1)
    80004e38:	864e                	mv	a2,s3
    80004e3a:	4585                	li	a1,1
    80004e3c:	6c88                	ld	a0,24(s1)
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	290080e7          	jalr	656(ra) # 800040ce <readi>
    80004e46:	892a                	mv	s2,a0
    80004e48:	00a05563          	blez	a0,80004e52 <fileread+0x56>
      f->off += r;
    80004e4c:	509c                	lw	a5,32(s1)
    80004e4e:	9fa9                	addw	a5,a5,a0
    80004e50:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e52:	6c88                	ld	a0,24(s1)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	088080e7          	jalr	136(ra) # 80003edc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	70a2                	ld	ra,40(sp)
    80004e60:	7402                	ld	s0,32(sp)
    80004e62:	64e2                	ld	s1,24(sp)
    80004e64:	6942                	ld	s2,16(sp)
    80004e66:	69a2                	ld	s3,8(sp)
    80004e68:	6145                	addi	sp,sp,48
    80004e6a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e6c:	6908                	ld	a0,16(a0)
    80004e6e:	00000097          	auipc	ra,0x0
    80004e72:	3c0080e7          	jalr	960(ra) # 8000522e <piperead>
    80004e76:	892a                	mv	s2,a0
    80004e78:	b7d5                	j	80004e5c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e7a:	02451783          	lh	a5,36(a0)
    80004e7e:	03079693          	slli	a3,a5,0x30
    80004e82:	92c1                	srli	a3,a3,0x30
    80004e84:	4725                	li	a4,9
    80004e86:	02d76863          	bltu	a4,a3,80004eb6 <fileread+0xba>
    80004e8a:	0792                	slli	a5,a5,0x4
    80004e8c:	0002d717          	auipc	a4,0x2d
    80004e90:	aa470713          	addi	a4,a4,-1372 # 80031930 <devsw>
    80004e94:	97ba                	add	a5,a5,a4
    80004e96:	639c                	ld	a5,0(a5)
    80004e98:	c38d                	beqz	a5,80004eba <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e9a:	4505                	li	a0,1
    80004e9c:	9782                	jalr	a5
    80004e9e:	892a                	mv	s2,a0
    80004ea0:	bf75                	j	80004e5c <fileread+0x60>
    panic("fileread");
    80004ea2:	00004517          	auipc	a0,0x4
    80004ea6:	83650513          	addi	a0,a0,-1994 # 800086d8 <syscalls+0x278>
    80004eaa:	ffffb097          	auipc	ra,0xffffb
    80004eae:	692080e7          	jalr	1682(ra) # 8000053c <panic>
    return -1;
    80004eb2:	597d                	li	s2,-1
    80004eb4:	b765                	j	80004e5c <fileread+0x60>
      return -1;
    80004eb6:	597d                	li	s2,-1
    80004eb8:	b755                	j	80004e5c <fileread+0x60>
    80004eba:	597d                	li	s2,-1
    80004ebc:	b745                	j	80004e5c <fileread+0x60>

0000000080004ebe <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ebe:	715d                	addi	sp,sp,-80
    80004ec0:	e486                	sd	ra,72(sp)
    80004ec2:	e0a2                	sd	s0,64(sp)
    80004ec4:	fc26                	sd	s1,56(sp)
    80004ec6:	f84a                	sd	s2,48(sp)
    80004ec8:	f44e                	sd	s3,40(sp)
    80004eca:	f052                	sd	s4,32(sp)
    80004ecc:	ec56                	sd	s5,24(sp)
    80004ece:	e85a                	sd	s6,16(sp)
    80004ed0:	e45e                	sd	s7,8(sp)
    80004ed2:	e062                	sd	s8,0(sp)
    80004ed4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ed6:	00954783          	lbu	a5,9(a0)
    80004eda:	10078663          	beqz	a5,80004fe6 <filewrite+0x128>
    80004ede:	892a                	mv	s2,a0
    80004ee0:	8b2e                	mv	s6,a1
    80004ee2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ee4:	411c                	lw	a5,0(a0)
    80004ee6:	4705                	li	a4,1
    80004ee8:	02e78263          	beq	a5,a4,80004f0c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eec:	470d                	li	a4,3
    80004eee:	02e78663          	beq	a5,a4,80004f1a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ef2:	4709                	li	a4,2
    80004ef4:	0ee79163          	bne	a5,a4,80004fd6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ef8:	0ac05d63          	blez	a2,80004fb2 <filewrite+0xf4>
    int i = 0;
    80004efc:	4981                	li	s3,0
    80004efe:	6b85                	lui	s7,0x1
    80004f00:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004f04:	6c05                	lui	s8,0x1
    80004f06:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004f0a:	a861                	j	80004fa2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f0c:	6908                	ld	a0,16(a0)
    80004f0e:	00000097          	auipc	ra,0x0
    80004f12:	22e080e7          	jalr	558(ra) # 8000513c <pipewrite>
    80004f16:	8a2a                	mv	s4,a0
    80004f18:	a045                	j	80004fb8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f1a:	02451783          	lh	a5,36(a0)
    80004f1e:	03079693          	slli	a3,a5,0x30
    80004f22:	92c1                	srli	a3,a3,0x30
    80004f24:	4725                	li	a4,9
    80004f26:	0cd76263          	bltu	a4,a3,80004fea <filewrite+0x12c>
    80004f2a:	0792                	slli	a5,a5,0x4
    80004f2c:	0002d717          	auipc	a4,0x2d
    80004f30:	a0470713          	addi	a4,a4,-1532 # 80031930 <devsw>
    80004f34:	97ba                	add	a5,a5,a4
    80004f36:	679c                	ld	a5,8(a5)
    80004f38:	cbdd                	beqz	a5,80004fee <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f3a:	4505                	li	a0,1
    80004f3c:	9782                	jalr	a5
    80004f3e:	8a2a                	mv	s4,a0
    80004f40:	a8a5                	j	80004fb8 <filewrite+0xfa>
    80004f42:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f46:	00000097          	auipc	ra,0x0
    80004f4a:	8b0080e7          	jalr	-1872(ra) # 800047f6 <begin_op>
      ilock(f->ip);
    80004f4e:	01893503          	ld	a0,24(s2)
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	ec8080e7          	jalr	-312(ra) # 80003e1a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f5a:	8756                	mv	a4,s5
    80004f5c:	02092683          	lw	a3,32(s2)
    80004f60:	01698633          	add	a2,s3,s6
    80004f64:	4585                	li	a1,1
    80004f66:	01893503          	ld	a0,24(s2)
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	25c080e7          	jalr	604(ra) # 800041c6 <writei>
    80004f72:	84aa                	mv	s1,a0
    80004f74:	00a05763          	blez	a0,80004f82 <filewrite+0xc4>
        f->off += r;
    80004f78:	02092783          	lw	a5,32(s2)
    80004f7c:	9fa9                	addw	a5,a5,a0
    80004f7e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f82:	01893503          	ld	a0,24(s2)
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	f56080e7          	jalr	-170(ra) # 80003edc <iunlock>
      end_op();
    80004f8e:	00000097          	auipc	ra,0x0
    80004f92:	8e6080e7          	jalr	-1818(ra) # 80004874 <end_op>

      if(r != n1){
    80004f96:	009a9f63          	bne	s5,s1,80004fb4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f9a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f9e:	0149db63          	bge	s3,s4,80004fb4 <filewrite+0xf6>
      int n1 = n - i;
    80004fa2:	413a04bb          	subw	s1,s4,s3
    80004fa6:	0004879b          	sext.w	a5,s1
    80004faa:	f8fbdce3          	bge	s7,a5,80004f42 <filewrite+0x84>
    80004fae:	84e2                	mv	s1,s8
    80004fb0:	bf49                	j	80004f42 <filewrite+0x84>
    int i = 0;
    80004fb2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fb4:	013a1f63          	bne	s4,s3,80004fd2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fb8:	8552                	mv	a0,s4
    80004fba:	60a6                	ld	ra,72(sp)
    80004fbc:	6406                	ld	s0,64(sp)
    80004fbe:	74e2                	ld	s1,56(sp)
    80004fc0:	7942                	ld	s2,48(sp)
    80004fc2:	79a2                	ld	s3,40(sp)
    80004fc4:	7a02                	ld	s4,32(sp)
    80004fc6:	6ae2                	ld	s5,24(sp)
    80004fc8:	6b42                	ld	s6,16(sp)
    80004fca:	6ba2                	ld	s7,8(sp)
    80004fcc:	6c02                	ld	s8,0(sp)
    80004fce:	6161                	addi	sp,sp,80
    80004fd0:	8082                	ret
    ret = (i == n ? n : -1);
    80004fd2:	5a7d                	li	s4,-1
    80004fd4:	b7d5                	j	80004fb8 <filewrite+0xfa>
    panic("filewrite");
    80004fd6:	00003517          	auipc	a0,0x3
    80004fda:	71250513          	addi	a0,a0,1810 # 800086e8 <syscalls+0x288>
    80004fde:	ffffb097          	auipc	ra,0xffffb
    80004fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    return -1;
    80004fe6:	5a7d                	li	s4,-1
    80004fe8:	bfc1                	j	80004fb8 <filewrite+0xfa>
      return -1;
    80004fea:	5a7d                	li	s4,-1
    80004fec:	b7f1                	j	80004fb8 <filewrite+0xfa>
    80004fee:	5a7d                	li	s4,-1
    80004ff0:	b7e1                	j	80004fb8 <filewrite+0xfa>

0000000080004ff2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ff2:	7179                	addi	sp,sp,-48
    80004ff4:	f406                	sd	ra,40(sp)
    80004ff6:	f022                	sd	s0,32(sp)
    80004ff8:	ec26                	sd	s1,24(sp)
    80004ffa:	e84a                	sd	s2,16(sp)
    80004ffc:	e44e                	sd	s3,8(sp)
    80004ffe:	e052                	sd	s4,0(sp)
    80005000:	1800                	addi	s0,sp,48
    80005002:	84aa                	mv	s1,a0
    80005004:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005006:	0005b023          	sd	zero,0(a1)
    8000500a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000500e:	00000097          	auipc	ra,0x0
    80005012:	bf8080e7          	jalr	-1032(ra) # 80004c06 <filealloc>
    80005016:	e088                	sd	a0,0(s1)
    80005018:	c551                	beqz	a0,800050a4 <pipealloc+0xb2>
    8000501a:	00000097          	auipc	ra,0x0
    8000501e:	bec080e7          	jalr	-1044(ra) # 80004c06 <filealloc>
    80005022:	00aa3023          	sd	a0,0(s4)
    80005026:	c92d                	beqz	a0,80005098 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	aba080e7          	jalr	-1350(ra) # 80000ae2 <kalloc>
    80005030:	892a                	mv	s2,a0
    80005032:	c125                	beqz	a0,80005092 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005034:	4985                	li	s3,1
    80005036:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000503a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000503e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005042:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005046:	00003597          	auipc	a1,0x3
    8000504a:	6b258593          	addi	a1,a1,1714 # 800086f8 <syscalls+0x298>
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	b3e080e7          	jalr	-1218(ra) # 80000b8c <initlock>
  (*f0)->type = FD_PIPE;
    80005056:	609c                	ld	a5,0(s1)
    80005058:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000505c:	609c                	ld	a5,0(s1)
    8000505e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005062:	609c                	ld	a5,0(s1)
    80005064:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005068:	609c                	ld	a5,0(s1)
    8000506a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000506e:	000a3783          	ld	a5,0(s4)
    80005072:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005076:	000a3783          	ld	a5,0(s4)
    8000507a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000507e:	000a3783          	ld	a5,0(s4)
    80005082:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005086:	000a3783          	ld	a5,0(s4)
    8000508a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000508e:	4501                	li	a0,0
    80005090:	a025                	j	800050b8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005092:	6088                	ld	a0,0(s1)
    80005094:	e501                	bnez	a0,8000509c <pipealloc+0xaa>
    80005096:	a039                	j	800050a4 <pipealloc+0xb2>
    80005098:	6088                	ld	a0,0(s1)
    8000509a:	c51d                	beqz	a0,800050c8 <pipealloc+0xd6>
    fileclose(*f0);
    8000509c:	00000097          	auipc	ra,0x0
    800050a0:	c26080e7          	jalr	-986(ra) # 80004cc2 <fileclose>
  if(*f1)
    800050a4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050a8:	557d                	li	a0,-1
  if(*f1)
    800050aa:	c799                	beqz	a5,800050b8 <pipealloc+0xc6>
    fileclose(*f1);
    800050ac:	853e                	mv	a0,a5
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	c14080e7          	jalr	-1004(ra) # 80004cc2 <fileclose>
  return -1;
    800050b6:	557d                	li	a0,-1
}
    800050b8:	70a2                	ld	ra,40(sp)
    800050ba:	7402                	ld	s0,32(sp)
    800050bc:	64e2                	ld	s1,24(sp)
    800050be:	6942                	ld	s2,16(sp)
    800050c0:	69a2                	ld	s3,8(sp)
    800050c2:	6a02                	ld	s4,0(sp)
    800050c4:	6145                	addi	sp,sp,48
    800050c6:	8082                	ret
  return -1;
    800050c8:	557d                	li	a0,-1
    800050ca:	b7fd                	j	800050b8 <pipealloc+0xc6>

00000000800050cc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050cc:	1101                	addi	sp,sp,-32
    800050ce:	ec06                	sd	ra,24(sp)
    800050d0:	e822                	sd	s0,16(sp)
    800050d2:	e426                	sd	s1,8(sp)
    800050d4:	e04a                	sd	s2,0(sp)
    800050d6:	1000                	addi	s0,sp,32
    800050d8:	84aa                	mv	s1,a0
    800050da:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	b40080e7          	jalr	-1216(ra) # 80000c1c <acquire>
  if(writable){
    800050e4:	02090d63          	beqz	s2,8000511e <pipeclose+0x52>
    pi->writeopen = 0;
    800050e8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050ec:	21848513          	addi	a0,s1,536
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	e6c080e7          	jalr	-404(ra) # 80001f5c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050f8:	2204b783          	ld	a5,544(s1)
    800050fc:	eb95                	bnez	a5,80005130 <pipeclose+0x64>
    release(&pi->lock);
    800050fe:	8526                	mv	a0,s1
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	bd0080e7          	jalr	-1072(ra) # 80000cd0 <release>
    kfree((char*)pi);
    80005108:	8526                	mv	a0,s1
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	8da080e7          	jalr	-1830(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80005112:	60e2                	ld	ra,24(sp)
    80005114:	6442                	ld	s0,16(sp)
    80005116:	64a2                	ld	s1,8(sp)
    80005118:	6902                	ld	s2,0(sp)
    8000511a:	6105                	addi	sp,sp,32
    8000511c:	8082                	ret
    pi->readopen = 0;
    8000511e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005122:	21c48513          	addi	a0,s1,540
    80005126:	ffffd097          	auipc	ra,0xffffd
    8000512a:	e36080e7          	jalr	-458(ra) # 80001f5c <wakeup>
    8000512e:	b7e9                	j	800050f8 <pipeclose+0x2c>
    release(&pi->lock);
    80005130:	8526                	mv	a0,s1
    80005132:	ffffc097          	auipc	ra,0xffffc
    80005136:	b9e080e7          	jalr	-1122(ra) # 80000cd0 <release>
}
    8000513a:	bfe1                	j	80005112 <pipeclose+0x46>

000000008000513c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000513c:	711d                	addi	sp,sp,-96
    8000513e:	ec86                	sd	ra,88(sp)
    80005140:	e8a2                	sd	s0,80(sp)
    80005142:	e4a6                	sd	s1,72(sp)
    80005144:	e0ca                	sd	s2,64(sp)
    80005146:	fc4e                	sd	s3,56(sp)
    80005148:	f852                	sd	s4,48(sp)
    8000514a:	f456                	sd	s5,40(sp)
    8000514c:	f05a                	sd	s6,32(sp)
    8000514e:	ec5e                	sd	s7,24(sp)
    80005150:	e862                	sd	s8,16(sp)
    80005152:	1080                	addi	s0,sp,96
    80005154:	84aa                	mv	s1,a0
    80005156:	8aae                	mv	s5,a1
    80005158:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	992080e7          	jalr	-1646(ra) # 80001aec <myproc>
    80005162:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005164:	8526                	mv	a0,s1
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	ab6080e7          	jalr	-1354(ra) # 80000c1c <acquire>
  while(i < n){
    8000516e:	0b405363          	blez	s4,80005214 <pipewrite+0xd8>
  int i = 0;
    80005172:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005174:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005176:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000517a:	21c48b93          	addi	s7,s1,540
    8000517e:	a089                	j	800051c0 <pipewrite+0x84>
      release(&pi->lock);
    80005180:	8526                	mv	a0,s1
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	b4e080e7          	jalr	-1202(ra) # 80000cd0 <release>
      return -1;
    8000518a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000518c:	854a                	mv	a0,s2
    8000518e:	60e6                	ld	ra,88(sp)
    80005190:	6446                	ld	s0,80(sp)
    80005192:	64a6                	ld	s1,72(sp)
    80005194:	6906                	ld	s2,64(sp)
    80005196:	79e2                	ld	s3,56(sp)
    80005198:	7a42                	ld	s4,48(sp)
    8000519a:	7aa2                	ld	s5,40(sp)
    8000519c:	7b02                	ld	s6,32(sp)
    8000519e:	6be2                	ld	s7,24(sp)
    800051a0:	6c42                	ld	s8,16(sp)
    800051a2:	6125                	addi	sp,sp,96
    800051a4:	8082                	ret
      wakeup(&pi->nread);
    800051a6:	8562                	mv	a0,s8
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	db4080e7          	jalr	-588(ra) # 80001f5c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051b0:	85a6                	mv	a1,s1
    800051b2:	855e                	mv	a0,s7
    800051b4:	ffffd097          	auipc	ra,0xffffd
    800051b8:	d38080e7          	jalr	-712(ra) # 80001eec <sleep>
  while(i < n){
    800051bc:	05495d63          	bge	s2,s4,80005216 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800051c0:	2204a783          	lw	a5,544(s1)
    800051c4:	dfd5                	beqz	a5,80005180 <pipewrite+0x44>
    800051c6:	3009a783          	lw	a5,768(s3)
    800051ca:	fbdd                	bnez	a5,80005180 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051cc:	2184a783          	lw	a5,536(s1)
    800051d0:	21c4a703          	lw	a4,540(s1)
    800051d4:	2007879b          	addiw	a5,a5,512
    800051d8:	fcf707e3          	beq	a4,a5,800051a6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051dc:	4685                	li	a3,1
    800051de:	01590633          	add	a2,s2,s5
    800051e2:	faf40593          	addi	a1,s0,-81
    800051e6:	3289b503          	ld	a0,808(s3)
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	5d4080e7          	jalr	1492(ra) # 800017be <copyin>
    800051f2:	03650263          	beq	a0,s6,80005216 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051f6:	21c4a783          	lw	a5,540(s1)
    800051fa:	0017871b          	addiw	a4,a5,1
    800051fe:	20e4ae23          	sw	a4,540(s1)
    80005202:	1ff7f793          	andi	a5,a5,511
    80005206:	97a6                	add	a5,a5,s1
    80005208:	faf44703          	lbu	a4,-81(s0)
    8000520c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005210:	2905                	addiw	s2,s2,1
    80005212:	b76d                	j	800051bc <pipewrite+0x80>
  int i = 0;
    80005214:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005216:	21848513          	addi	a0,s1,536
    8000521a:	ffffd097          	auipc	ra,0xffffd
    8000521e:	d42080e7          	jalr	-702(ra) # 80001f5c <wakeup>
  release(&pi->lock);
    80005222:	8526                	mv	a0,s1
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	aac080e7          	jalr	-1364(ra) # 80000cd0 <release>
  return i;
    8000522c:	b785                	j	8000518c <pipewrite+0x50>

000000008000522e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000522e:	715d                	addi	sp,sp,-80
    80005230:	e486                	sd	ra,72(sp)
    80005232:	e0a2                	sd	s0,64(sp)
    80005234:	fc26                	sd	s1,56(sp)
    80005236:	f84a                	sd	s2,48(sp)
    80005238:	f44e                	sd	s3,40(sp)
    8000523a:	f052                	sd	s4,32(sp)
    8000523c:	ec56                	sd	s5,24(sp)
    8000523e:	e85a                	sd	s6,16(sp)
    80005240:	0880                	addi	s0,sp,80
    80005242:	84aa                	mv	s1,a0
    80005244:	892e                	mv	s2,a1
    80005246:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	8a4080e7          	jalr	-1884(ra) # 80001aec <myproc>
    80005250:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005252:	8526                	mv	a0,s1
    80005254:	ffffc097          	auipc	ra,0xffffc
    80005258:	9c8080e7          	jalr	-1592(ra) # 80000c1c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000525c:	2184a703          	lw	a4,536(s1)
    80005260:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005264:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005268:	02f71463          	bne	a4,a5,80005290 <piperead+0x62>
    8000526c:	2244a783          	lw	a5,548(s1)
    80005270:	c385                	beqz	a5,80005290 <piperead+0x62>
    if(pr->killed){
    80005272:	300a2783          	lw	a5,768(s4)
    80005276:	ebc9                	bnez	a5,80005308 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005278:	85a6                	mv	a1,s1
    8000527a:	854e                	mv	a0,s3
    8000527c:	ffffd097          	auipc	ra,0xffffd
    80005280:	c70080e7          	jalr	-912(ra) # 80001eec <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005284:	2184a703          	lw	a4,536(s1)
    80005288:	21c4a783          	lw	a5,540(s1)
    8000528c:	fef700e3          	beq	a4,a5,8000526c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005290:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005292:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005294:	05505463          	blez	s5,800052dc <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80005298:	2184a783          	lw	a5,536(s1)
    8000529c:	21c4a703          	lw	a4,540(s1)
    800052a0:	02f70e63          	beq	a4,a5,800052dc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052a4:	0017871b          	addiw	a4,a5,1
    800052a8:	20e4ac23          	sw	a4,536(s1)
    800052ac:	1ff7f793          	andi	a5,a5,511
    800052b0:	97a6                	add	a5,a5,s1
    800052b2:	0187c783          	lbu	a5,24(a5)
    800052b6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052ba:	4685                	li	a3,1
    800052bc:	fbf40613          	addi	a2,s0,-65
    800052c0:	85ca                	mv	a1,s2
    800052c2:	328a3503          	ld	a0,808(s4)
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	46c080e7          	jalr	1132(ra) # 80001732 <copyout>
    800052ce:	01650763          	beq	a0,s6,800052dc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052d2:	2985                	addiw	s3,s3,1
    800052d4:	0905                	addi	s2,s2,1
    800052d6:	fd3a91e3          	bne	s5,s3,80005298 <piperead+0x6a>
    800052da:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052dc:	21c48513          	addi	a0,s1,540
    800052e0:	ffffd097          	auipc	ra,0xffffd
    800052e4:	c7c080e7          	jalr	-900(ra) # 80001f5c <wakeup>
  release(&pi->lock);
    800052e8:	8526                	mv	a0,s1
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	9e6080e7          	jalr	-1562(ra) # 80000cd0 <release>
  return i;
}
    800052f2:	854e                	mv	a0,s3
    800052f4:	60a6                	ld	ra,72(sp)
    800052f6:	6406                	ld	s0,64(sp)
    800052f8:	74e2                	ld	s1,56(sp)
    800052fa:	7942                	ld	s2,48(sp)
    800052fc:	79a2                	ld	s3,40(sp)
    800052fe:	7a02                	ld	s4,32(sp)
    80005300:	6ae2                	ld	s5,24(sp)
    80005302:	6b42                	ld	s6,16(sp)
    80005304:	6161                	addi	sp,sp,80
    80005306:	8082                	ret
      release(&pi->lock);
    80005308:	8526                	mv	a0,s1
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	9c6080e7          	jalr	-1594(ra) # 80000cd0 <release>
      return -1;
    80005312:	59fd                	li	s3,-1
    80005314:	bff9                	j	800052f2 <piperead+0xc4>

0000000080005316 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005316:	de010113          	addi	sp,sp,-544
    8000531a:	20113c23          	sd	ra,536(sp)
    8000531e:	20813823          	sd	s0,528(sp)
    80005322:	20913423          	sd	s1,520(sp)
    80005326:	21213023          	sd	s2,512(sp)
    8000532a:	ffce                	sd	s3,504(sp)
    8000532c:	fbd2                	sd	s4,496(sp)
    8000532e:	f7d6                	sd	s5,488(sp)
    80005330:	f3da                	sd	s6,480(sp)
    80005332:	efde                	sd	s7,472(sp)
    80005334:	ebe2                	sd	s8,464(sp)
    80005336:	e7e6                	sd	s9,456(sp)
    80005338:	e3ea                	sd	s10,448(sp)
    8000533a:	ff6e                	sd	s11,440(sp)
    8000533c:	1400                	addi	s0,sp,544
    8000533e:	892a                	mv	s2,a0
    80005340:	dea43423          	sd	a0,-536(s0)
    80005344:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	7a4080e7          	jalr	1956(ra) # 80001aec <myproc>
    80005350:	84aa                	mv	s1,a0

  begin_op();
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	4a4080e7          	jalr	1188(ra) # 800047f6 <begin_op>

  if((ip = namei(path)) == 0){
    8000535a:	854a                	mv	a0,s2
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	27a080e7          	jalr	634(ra) # 800045d6 <namei>
    80005364:	c93d                	beqz	a0,800053da <exec+0xc4>
    80005366:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	ab2080e7          	jalr	-1358(ra) # 80003e1a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005370:	04000713          	li	a4,64
    80005374:	4681                	li	a3,0
    80005376:	e5040613          	addi	a2,s0,-432
    8000537a:	4581                	li	a1,0
    8000537c:	8556                	mv	a0,s5
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	d50080e7          	jalr	-688(ra) # 800040ce <readi>
    80005386:	04000793          	li	a5,64
    8000538a:	00f51a63          	bne	a0,a5,8000539e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000538e:	e5042703          	lw	a4,-432(s0)
    80005392:	464c47b7          	lui	a5,0x464c4
    80005396:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000539a:	04f70663          	beq	a4,a5,800053e6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000539e:	8556                	mv	a0,s5
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	cdc080e7          	jalr	-804(ra) # 8000407c <iunlockput>
    end_op();
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	4cc080e7          	jalr	1228(ra) # 80004874 <end_op>
  }
  return -1;
    800053b0:	557d                	li	a0,-1
}
    800053b2:	21813083          	ld	ra,536(sp)
    800053b6:	21013403          	ld	s0,528(sp)
    800053ba:	20813483          	ld	s1,520(sp)
    800053be:	20013903          	ld	s2,512(sp)
    800053c2:	79fe                	ld	s3,504(sp)
    800053c4:	7a5e                	ld	s4,496(sp)
    800053c6:	7abe                	ld	s5,488(sp)
    800053c8:	7b1e                	ld	s6,480(sp)
    800053ca:	6bfe                	ld	s7,472(sp)
    800053cc:	6c5e                	ld	s8,464(sp)
    800053ce:	6cbe                	ld	s9,456(sp)
    800053d0:	6d1e                	ld	s10,448(sp)
    800053d2:	7dfa                	ld	s11,440(sp)
    800053d4:	22010113          	addi	sp,sp,544
    800053d8:	8082                	ret
    end_op();
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	49a080e7          	jalr	1178(ra) # 80004874 <end_op>
    return -1;
    800053e2:	557d                	li	a0,-1
    800053e4:	b7f9                	j	800053b2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800053e6:	8526                	mv	a0,s1
    800053e8:	ffffc097          	auipc	ra,0xffffc
    800053ec:	7cc080e7          	jalr	1996(ra) # 80001bb4 <proc_pagetable>
    800053f0:	8b2a                	mv	s6,a0
    800053f2:	d555                	beqz	a0,8000539e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053f4:	e7042783          	lw	a5,-400(s0)
    800053f8:	e8845703          	lhu	a4,-376(s0)
    800053fc:	c735                	beqz	a4,80005468 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053fe:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005400:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80005404:	6a05                	lui	s4,0x1
    80005406:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000540a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000540e:	6d85                	lui	s11,0x1
    80005410:	7d7d                	lui	s10,0xfffff
    80005412:	ac1d                	j	80005648 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005414:	00003517          	auipc	a0,0x3
    80005418:	2ec50513          	addi	a0,a0,748 # 80008700 <syscalls+0x2a0>
    8000541c:	ffffb097          	auipc	ra,0xffffb
    80005420:	120080e7          	jalr	288(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005424:	874a                	mv	a4,s2
    80005426:	009c86bb          	addw	a3,s9,s1
    8000542a:	4581                	li	a1,0
    8000542c:	8556                	mv	a0,s5
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	ca0080e7          	jalr	-864(ra) # 800040ce <readi>
    80005436:	2501                	sext.w	a0,a0
    80005438:	1aa91863          	bne	s2,a0,800055e8 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000543c:	009d84bb          	addw	s1,s11,s1
    80005440:	013d09bb          	addw	s3,s10,s3
    80005444:	1f74f263          	bgeu	s1,s7,80005628 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005448:	02049593          	slli	a1,s1,0x20
    8000544c:	9181                	srli	a1,a1,0x20
    8000544e:	95e2                	add	a1,a1,s8
    80005450:	855a                	mv	a0,s6
    80005452:	ffffc097          	auipc	ra,0xffffc
    80005456:	c54080e7          	jalr	-940(ra) # 800010a6 <walkaddr>
    8000545a:	862a                	mv	a2,a0
    if(pa == 0)
    8000545c:	dd45                	beqz	a0,80005414 <exec+0xfe>
      n = PGSIZE;
    8000545e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005460:	fd49f2e3          	bgeu	s3,s4,80005424 <exec+0x10e>
      n = sz - i;
    80005464:	894e                	mv	s2,s3
    80005466:	bf7d                	j	80005424 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005468:	4481                	li	s1,0
  iunlockput(ip);
    8000546a:	8556                	mv	a0,s5
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	c10080e7          	jalr	-1008(ra) # 8000407c <iunlockput>
  end_op();
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	400080e7          	jalr	1024(ra) # 80004874 <end_op>
  p = myproc();
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	670080e7          	jalr	1648(ra) # 80001aec <myproc>
    80005484:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005486:	32053d03          	ld	s10,800(a0)
  sz = PGROUNDUP(sz);
    8000548a:	6785                	lui	a5,0x1
    8000548c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000548e:	97a6                	add	a5,a5,s1
    80005490:	777d                	lui	a4,0xfffff
    80005492:	8ff9                	and	a5,a5,a4
    80005494:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005498:	6609                	lui	a2,0x2
    8000549a:	963e                	add	a2,a2,a5
    8000549c:	85be                	mv	a1,a5
    8000549e:	855a                	mv	a0,s6
    800054a0:	ffffc097          	auipc	ra,0xffffc
    800054a4:	f9c080e7          	jalr	-100(ra) # 8000143c <uvmalloc>
    800054a8:	8c2a                	mv	s8,a0
  ip = 0;
    800054aa:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054ac:	12050e63          	beqz	a0,800055e8 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054b0:	75f9                	lui	a1,0xffffe
    800054b2:	95aa                	add	a1,a1,a0
    800054b4:	855a                	mv	a0,s6
    800054b6:	ffffc097          	auipc	ra,0xffffc
    800054ba:	24a080e7          	jalr	586(ra) # 80001700 <uvmclear>
  stackbase = sp - PGSIZE;
    800054be:	7afd                	lui	s5,0xfffff
    800054c0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800054c2:	df043783          	ld	a5,-528(s0)
    800054c6:	6388                	ld	a0,0(a5)
    800054c8:	c925                	beqz	a0,80005538 <exec+0x222>
    800054ca:	e9040993          	addi	s3,s0,-368
    800054ce:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054d2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054d4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054d6:	ffffc097          	auipc	ra,0xffffc
    800054da:	9be080e7          	jalr	-1602(ra) # 80000e94 <strlen>
    800054de:	0015079b          	addiw	a5,a0,1
    800054e2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054e6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800054ea:	13596363          	bltu	s2,s5,80005610 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054ee:	df043d83          	ld	s11,-528(s0)
    800054f2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800054f6:	8552                	mv	a0,s4
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	99c080e7          	jalr	-1636(ra) # 80000e94 <strlen>
    80005500:	0015069b          	addiw	a3,a0,1
    80005504:	8652                	mv	a2,s4
    80005506:	85ca                	mv	a1,s2
    80005508:	855a                	mv	a0,s6
    8000550a:	ffffc097          	auipc	ra,0xffffc
    8000550e:	228080e7          	jalr	552(ra) # 80001732 <copyout>
    80005512:	10054363          	bltz	a0,80005618 <exec+0x302>
    ustack[argc] = sp;
    80005516:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000551a:	0485                	addi	s1,s1,1
    8000551c:	008d8793          	addi	a5,s11,8
    80005520:	def43823          	sd	a5,-528(s0)
    80005524:	008db503          	ld	a0,8(s11)
    80005528:	c911                	beqz	a0,8000553c <exec+0x226>
    if(argc >= MAXARG)
    8000552a:	09a1                	addi	s3,s3,8
    8000552c:	fb3c95e3          	bne	s9,s3,800054d6 <exec+0x1c0>
  sz = sz1;
    80005530:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005534:	4a81                	li	s5,0
    80005536:	a84d                	j	800055e8 <exec+0x2d2>
  sp = sz;
    80005538:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000553a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000553c:	00349793          	slli	a5,s1,0x3
    80005540:	f9078793          	addi	a5,a5,-112
    80005544:	97a2                	add	a5,a5,s0
    80005546:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000554a:	00148693          	addi	a3,s1,1
    8000554e:	068e                	slli	a3,a3,0x3
    80005550:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005554:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005558:	01597663          	bgeu	s2,s5,80005564 <exec+0x24e>
  sz = sz1;
    8000555c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005560:	4a81                	li	s5,0
    80005562:	a059                	j	800055e8 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005564:	e9040613          	addi	a2,s0,-368
    80005568:	85ca                	mv	a1,s2
    8000556a:	855a                	mv	a0,s6
    8000556c:	ffffc097          	auipc	ra,0xffffc
    80005570:	1c6080e7          	jalr	454(ra) # 80001732 <copyout>
    80005574:	0a054663          	bltz	a0,80005620 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005578:	330bb783          	ld	a5,816(s7)
    8000557c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005580:	de843783          	ld	a5,-536(s0)
    80005584:	0007c703          	lbu	a4,0(a5)
    80005588:	cf11                	beqz	a4,800055a4 <exec+0x28e>
    8000558a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000558c:	02f00693          	li	a3,47
    80005590:	a039                	j	8000559e <exec+0x288>
      last = s+1;
    80005592:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005596:	0785                	addi	a5,a5,1
    80005598:	fff7c703          	lbu	a4,-1(a5)
    8000559c:	c701                	beqz	a4,800055a4 <exec+0x28e>
    if(*s == '/')
    8000559e:	fed71ce3          	bne	a4,a3,80005596 <exec+0x280>
    800055a2:	bfc5                	j	80005592 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800055a4:	4641                	li	a2,16
    800055a6:	de843583          	ld	a1,-536(s0)
    800055aa:	430b8513          	addi	a0,s7,1072
    800055ae:	ffffc097          	auipc	ra,0xffffc
    800055b2:	8b4080e7          	jalr	-1868(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    800055b6:	328bb503          	ld	a0,808(s7)
  p->pagetable = pagetable;
    800055ba:	336bb423          	sd	s6,808(s7)
  p->sz = sz;
    800055be:	338bb023          	sd	s8,800(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055c2:	330bb783          	ld	a5,816(s7)
    800055c6:	e6843703          	ld	a4,-408(s0)
    800055ca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055cc:	330bb783          	ld	a5,816(s7)
    800055d0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055d4:	85ea                	mv	a1,s10
    800055d6:	ffffc097          	auipc	ra,0xffffc
    800055da:	67a080e7          	jalr	1658(ra) # 80001c50 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055de:	0004851b          	sext.w	a0,s1
    800055e2:	bbc1                	j	800053b2 <exec+0x9c>
    800055e4:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800055e8:	df843583          	ld	a1,-520(s0)
    800055ec:	855a                	mv	a0,s6
    800055ee:	ffffc097          	auipc	ra,0xffffc
    800055f2:	662080e7          	jalr	1634(ra) # 80001c50 <proc_freepagetable>
  if(ip){
    800055f6:	da0a94e3          	bnez	s5,8000539e <exec+0x88>
  return -1;
    800055fa:	557d                	li	a0,-1
    800055fc:	bb5d                	j	800053b2 <exec+0x9c>
    800055fe:	de943c23          	sd	s1,-520(s0)
    80005602:	b7dd                	j	800055e8 <exec+0x2d2>
    80005604:	de943c23          	sd	s1,-520(s0)
    80005608:	b7c5                	j	800055e8 <exec+0x2d2>
    8000560a:	de943c23          	sd	s1,-520(s0)
    8000560e:	bfe9                	j	800055e8 <exec+0x2d2>
  sz = sz1;
    80005610:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005614:	4a81                	li	s5,0
    80005616:	bfc9                	j	800055e8 <exec+0x2d2>
  sz = sz1;
    80005618:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000561c:	4a81                	li	s5,0
    8000561e:	b7e9                	j	800055e8 <exec+0x2d2>
  sz = sz1;
    80005620:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005624:	4a81                	li	s5,0
    80005626:	b7c9                	j	800055e8 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005628:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000562c:	e0843783          	ld	a5,-504(s0)
    80005630:	0017869b          	addiw	a3,a5,1
    80005634:	e0d43423          	sd	a3,-504(s0)
    80005638:	e0043783          	ld	a5,-512(s0)
    8000563c:	0387879b          	addiw	a5,a5,56
    80005640:	e8845703          	lhu	a4,-376(s0)
    80005644:	e2e6d3e3          	bge	a3,a4,8000546a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005648:	2781                	sext.w	a5,a5
    8000564a:	e0f43023          	sd	a5,-512(s0)
    8000564e:	03800713          	li	a4,56
    80005652:	86be                	mv	a3,a5
    80005654:	e1840613          	addi	a2,s0,-488
    80005658:	4581                	li	a1,0
    8000565a:	8556                	mv	a0,s5
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	a72080e7          	jalr	-1422(ra) # 800040ce <readi>
    80005664:	03800793          	li	a5,56
    80005668:	f6f51ee3          	bne	a0,a5,800055e4 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000566c:	e1842783          	lw	a5,-488(s0)
    80005670:	4705                	li	a4,1
    80005672:	fae79de3          	bne	a5,a4,8000562c <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005676:	e4043603          	ld	a2,-448(s0)
    8000567a:	e3843783          	ld	a5,-456(s0)
    8000567e:	f8f660e3          	bltu	a2,a5,800055fe <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005682:	e2843783          	ld	a5,-472(s0)
    80005686:	963e                	add	a2,a2,a5
    80005688:	f6f66ee3          	bltu	a2,a5,80005604 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000568c:	85a6                	mv	a1,s1
    8000568e:	855a                	mv	a0,s6
    80005690:	ffffc097          	auipc	ra,0xffffc
    80005694:	dac080e7          	jalr	-596(ra) # 8000143c <uvmalloc>
    80005698:	dea43c23          	sd	a0,-520(s0)
    8000569c:	d53d                	beqz	a0,8000560a <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000569e:	e2843c03          	ld	s8,-472(s0)
    800056a2:	de043783          	ld	a5,-544(s0)
    800056a6:	00fc77b3          	and	a5,s8,a5
    800056aa:	ff9d                	bnez	a5,800055e8 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056ac:	e2042c83          	lw	s9,-480(s0)
    800056b0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056b4:	f60b8ae3          	beqz	s7,80005628 <exec+0x312>
    800056b8:	89de                	mv	s3,s7
    800056ba:	4481                	li	s1,0
    800056bc:	b371                	j	80005448 <exec+0x132>

00000000800056be <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056be:	7179                	addi	sp,sp,-48
    800056c0:	f406                	sd	ra,40(sp)
    800056c2:	f022                	sd	s0,32(sp)
    800056c4:	ec26                	sd	s1,24(sp)
    800056c6:	e84a                	sd	s2,16(sp)
    800056c8:	1800                	addi	s0,sp,48
    800056ca:	892e                	mv	s2,a1
    800056cc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056ce:	fdc40593          	addi	a1,s0,-36
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	b7c080e7          	jalr	-1156(ra) # 8000324e <argint>
    800056da:	04054063          	bltz	a0,8000571a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056de:	fdc42703          	lw	a4,-36(s0)
    800056e2:	47bd                	li	a5,15
    800056e4:	02e7ed63          	bltu	a5,a4,8000571e <argfd+0x60>
    800056e8:	ffffc097          	auipc	ra,0xffffc
    800056ec:	404080e7          	jalr	1028(ra) # 80001aec <myproc>
    800056f0:	fdc42703          	lw	a4,-36(s0)
    800056f4:	07470793          	addi	a5,a4,116 # fffffffffffff074 <end+0xffffffff7ffc9074>
    800056f8:	078e                	slli	a5,a5,0x3
    800056fa:	953e                	add	a0,a0,a5
    800056fc:	651c                	ld	a5,8(a0)
    800056fe:	c395                	beqz	a5,80005722 <argfd+0x64>
    return -1;
  if(pfd)
    80005700:	00090463          	beqz	s2,80005708 <argfd+0x4a>
    *pfd = fd;
    80005704:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005708:	4501                	li	a0,0
  if(pf)
    8000570a:	c091                	beqz	s1,8000570e <argfd+0x50>
    *pf = f;
    8000570c:	e09c                	sd	a5,0(s1)
}
    8000570e:	70a2                	ld	ra,40(sp)
    80005710:	7402                	ld	s0,32(sp)
    80005712:	64e2                	ld	s1,24(sp)
    80005714:	6942                	ld	s2,16(sp)
    80005716:	6145                	addi	sp,sp,48
    80005718:	8082                	ret
    return -1;
    8000571a:	557d                	li	a0,-1
    8000571c:	bfcd                	j	8000570e <argfd+0x50>
    return -1;
    8000571e:	557d                	li	a0,-1
    80005720:	b7fd                	j	8000570e <argfd+0x50>
    80005722:	557d                	li	a0,-1
    80005724:	b7ed                	j	8000570e <argfd+0x50>

0000000080005726 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005726:	1101                	addi	sp,sp,-32
    80005728:	ec06                	sd	ra,24(sp)
    8000572a:	e822                	sd	s0,16(sp)
    8000572c:	e426                	sd	s1,8(sp)
    8000572e:	1000                	addi	s0,sp,32
    80005730:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005732:	ffffc097          	auipc	ra,0xffffc
    80005736:	3ba080e7          	jalr	954(ra) # 80001aec <myproc>
    8000573a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000573c:	3a850793          	addi	a5,a0,936
    80005740:	4501                	li	a0,0
    80005742:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005744:	6398                	ld	a4,0(a5)
    80005746:	cb19                	beqz	a4,8000575c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005748:	2505                	addiw	a0,a0,1
    8000574a:	07a1                	addi	a5,a5,8
    8000574c:	fed51ce3          	bne	a0,a3,80005744 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005750:	557d                	li	a0,-1
}
    80005752:	60e2                	ld	ra,24(sp)
    80005754:	6442                	ld	s0,16(sp)
    80005756:	64a2                	ld	s1,8(sp)
    80005758:	6105                	addi	sp,sp,32
    8000575a:	8082                	ret
      p->ofile[fd] = f;
    8000575c:	07450793          	addi	a5,a0,116
    80005760:	078e                	slli	a5,a5,0x3
    80005762:	963e                	add	a2,a2,a5
    80005764:	e604                	sd	s1,8(a2)
      return fd;
    80005766:	b7f5                	j	80005752 <fdalloc+0x2c>

0000000080005768 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005768:	715d                	addi	sp,sp,-80
    8000576a:	e486                	sd	ra,72(sp)
    8000576c:	e0a2                	sd	s0,64(sp)
    8000576e:	fc26                	sd	s1,56(sp)
    80005770:	f84a                	sd	s2,48(sp)
    80005772:	f44e                	sd	s3,40(sp)
    80005774:	f052                	sd	s4,32(sp)
    80005776:	ec56                	sd	s5,24(sp)
    80005778:	0880                	addi	s0,sp,80
    8000577a:	89ae                	mv	s3,a1
    8000577c:	8ab2                	mv	s5,a2
    8000577e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005780:	fb040593          	addi	a1,s0,-80
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	e70080e7          	jalr	-400(ra) # 800045f4 <nameiparent>
    8000578c:	892a                	mv	s2,a0
    8000578e:	12050e63          	beqz	a0,800058ca <create+0x162>
    return 0;

  ilock(dp);
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	688080e7          	jalr	1672(ra) # 80003e1a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000579a:	4601                	li	a2,0
    8000579c:	fb040593          	addi	a1,s0,-80
    800057a0:	854a                	mv	a0,s2
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	b5c080e7          	jalr	-1188(ra) # 800042fe <dirlookup>
    800057aa:	84aa                	mv	s1,a0
    800057ac:	c921                	beqz	a0,800057fc <create+0x94>
    iunlockput(dp);
    800057ae:	854a                	mv	a0,s2
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	8cc080e7          	jalr	-1844(ra) # 8000407c <iunlockput>
    ilock(ip);
    800057b8:	8526                	mv	a0,s1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	660080e7          	jalr	1632(ra) # 80003e1a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057c2:	2981                	sext.w	s3,s3
    800057c4:	4789                	li	a5,2
    800057c6:	02f99463          	bne	s3,a5,800057ee <create+0x86>
    800057ca:	0444d783          	lhu	a5,68(s1)
    800057ce:	37f9                	addiw	a5,a5,-2
    800057d0:	17c2                	slli	a5,a5,0x30
    800057d2:	93c1                	srli	a5,a5,0x30
    800057d4:	4705                	li	a4,1
    800057d6:	00f76c63          	bltu	a4,a5,800057ee <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057da:	8526                	mv	a0,s1
    800057dc:	60a6                	ld	ra,72(sp)
    800057de:	6406                	ld	s0,64(sp)
    800057e0:	74e2                	ld	s1,56(sp)
    800057e2:	7942                	ld	s2,48(sp)
    800057e4:	79a2                	ld	s3,40(sp)
    800057e6:	7a02                	ld	s4,32(sp)
    800057e8:	6ae2                	ld	s5,24(sp)
    800057ea:	6161                	addi	sp,sp,80
    800057ec:	8082                	ret
    iunlockput(ip);
    800057ee:	8526                	mv	a0,s1
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	88c080e7          	jalr	-1908(ra) # 8000407c <iunlockput>
    return 0;
    800057f8:	4481                	li	s1,0
    800057fa:	b7c5                	j	800057da <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057fc:	85ce                	mv	a1,s3
    800057fe:	00092503          	lw	a0,0(s2)
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	47e080e7          	jalr	1150(ra) # 80003c80 <ialloc>
    8000580a:	84aa                	mv	s1,a0
    8000580c:	c521                	beqz	a0,80005854 <create+0xec>
  ilock(ip);
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	60c080e7          	jalr	1548(ra) # 80003e1a <ilock>
  ip->major = major;
    80005816:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000581a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000581e:	4a05                	li	s4,1
    80005820:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	528080e7          	jalr	1320(ra) # 80003d4e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000582e:	2981                	sext.w	s3,s3
    80005830:	03498a63          	beq	s3,s4,80005864 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005834:	40d0                	lw	a2,4(s1)
    80005836:	fb040593          	addi	a1,s0,-80
    8000583a:	854a                	mv	a0,s2
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	cd8080e7          	jalr	-808(ra) # 80004514 <dirlink>
    80005844:	06054b63          	bltz	a0,800058ba <create+0x152>
  iunlockput(dp);
    80005848:	854a                	mv	a0,s2
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	832080e7          	jalr	-1998(ra) # 8000407c <iunlockput>
  return ip;
    80005852:	b761                	j	800057da <create+0x72>
    panic("create: ialloc");
    80005854:	00003517          	auipc	a0,0x3
    80005858:	ecc50513          	addi	a0,a0,-308 # 80008720 <syscalls+0x2c0>
    8000585c:	ffffb097          	auipc	ra,0xffffb
    80005860:	ce0080e7          	jalr	-800(ra) # 8000053c <panic>
    dp->nlink++;  // for ".."
    80005864:	04a95783          	lhu	a5,74(s2)
    80005868:	2785                	addiw	a5,a5,1
    8000586a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000586e:	854a                	mv	a0,s2
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	4de080e7          	jalr	1246(ra) # 80003d4e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005878:	40d0                	lw	a2,4(s1)
    8000587a:	00003597          	auipc	a1,0x3
    8000587e:	eb658593          	addi	a1,a1,-330 # 80008730 <syscalls+0x2d0>
    80005882:	8526                	mv	a0,s1
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	c90080e7          	jalr	-880(ra) # 80004514 <dirlink>
    8000588c:	00054f63          	bltz	a0,800058aa <create+0x142>
    80005890:	00492603          	lw	a2,4(s2)
    80005894:	00003597          	auipc	a1,0x3
    80005898:	ea458593          	addi	a1,a1,-348 # 80008738 <syscalls+0x2d8>
    8000589c:	8526                	mv	a0,s1
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	c76080e7          	jalr	-906(ra) # 80004514 <dirlink>
    800058a6:	f80557e3          	bgez	a0,80005834 <create+0xcc>
      panic("create dots");
    800058aa:	00003517          	auipc	a0,0x3
    800058ae:	e9650513          	addi	a0,a0,-362 # 80008740 <syscalls+0x2e0>
    800058b2:	ffffb097          	auipc	ra,0xffffb
    800058b6:	c8a080e7          	jalr	-886(ra) # 8000053c <panic>
    panic("create: dirlink");
    800058ba:	00003517          	auipc	a0,0x3
    800058be:	e9650513          	addi	a0,a0,-362 # 80008750 <syscalls+0x2f0>
    800058c2:	ffffb097          	auipc	ra,0xffffb
    800058c6:	c7a080e7          	jalr	-902(ra) # 8000053c <panic>
    return 0;
    800058ca:	84aa                	mv	s1,a0
    800058cc:	b739                	j	800057da <create+0x72>

00000000800058ce <sys_dup>:
{
    800058ce:	7179                	addi	sp,sp,-48
    800058d0:	f406                	sd	ra,40(sp)
    800058d2:	f022                	sd	s0,32(sp)
    800058d4:	ec26                	sd	s1,24(sp)
    800058d6:	e84a                	sd	s2,16(sp)
    800058d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058da:	fd840613          	addi	a2,s0,-40
    800058de:	4581                	li	a1,0
    800058e0:	4501                	li	a0,0
    800058e2:	00000097          	auipc	ra,0x0
    800058e6:	ddc080e7          	jalr	-548(ra) # 800056be <argfd>
    return -1;
    800058ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058ec:	02054363          	bltz	a0,80005912 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800058f0:	fd843903          	ld	s2,-40(s0)
    800058f4:	854a                	mv	a0,s2
    800058f6:	00000097          	auipc	ra,0x0
    800058fa:	e30080e7          	jalr	-464(ra) # 80005726 <fdalloc>
    800058fe:	84aa                	mv	s1,a0
    return -1;
    80005900:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005902:	00054863          	bltz	a0,80005912 <sys_dup+0x44>
  filedup(f);
    80005906:	854a                	mv	a0,s2
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	368080e7          	jalr	872(ra) # 80004c70 <filedup>
  return fd;
    80005910:	87a6                	mv	a5,s1
}
    80005912:	853e                	mv	a0,a5
    80005914:	70a2                	ld	ra,40(sp)
    80005916:	7402                	ld	s0,32(sp)
    80005918:	64e2                	ld	s1,24(sp)
    8000591a:	6942                	ld	s2,16(sp)
    8000591c:	6145                	addi	sp,sp,48
    8000591e:	8082                	ret

0000000080005920 <sys_read>:
{
    80005920:	7179                	addi	sp,sp,-48
    80005922:	f406                	sd	ra,40(sp)
    80005924:	f022                	sd	s0,32(sp)
    80005926:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005928:	fe840613          	addi	a2,s0,-24
    8000592c:	4581                	li	a1,0
    8000592e:	4501                	li	a0,0
    80005930:	00000097          	auipc	ra,0x0
    80005934:	d8e080e7          	jalr	-626(ra) # 800056be <argfd>
    return -1;
    80005938:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000593a:	04054163          	bltz	a0,8000597c <sys_read+0x5c>
    8000593e:	fe440593          	addi	a1,s0,-28
    80005942:	4509                	li	a0,2
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	90a080e7          	jalr	-1782(ra) # 8000324e <argint>
    return -1;
    8000594c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000594e:	02054763          	bltz	a0,8000597c <sys_read+0x5c>
    80005952:	fd840593          	addi	a1,s0,-40
    80005956:	4505                	li	a0,1
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	918080e7          	jalr	-1768(ra) # 80003270 <argaddr>
    return -1;
    80005960:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005962:	00054d63          	bltz	a0,8000597c <sys_read+0x5c>
  return fileread(f, p, n);
    80005966:	fe442603          	lw	a2,-28(s0)
    8000596a:	fd843583          	ld	a1,-40(s0)
    8000596e:	fe843503          	ld	a0,-24(s0)
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	48a080e7          	jalr	1162(ra) # 80004dfc <fileread>
    8000597a:	87aa                	mv	a5,a0
}
    8000597c:	853e                	mv	a0,a5
    8000597e:	70a2                	ld	ra,40(sp)
    80005980:	7402                	ld	s0,32(sp)
    80005982:	6145                	addi	sp,sp,48
    80005984:	8082                	ret

0000000080005986 <sys_write>:
{
    80005986:	7179                	addi	sp,sp,-48
    80005988:	f406                	sd	ra,40(sp)
    8000598a:	f022                	sd	s0,32(sp)
    8000598c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000598e:	fe840613          	addi	a2,s0,-24
    80005992:	4581                	li	a1,0
    80005994:	4501                	li	a0,0
    80005996:	00000097          	auipc	ra,0x0
    8000599a:	d28080e7          	jalr	-728(ra) # 800056be <argfd>
    return -1;
    8000599e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059a0:	04054163          	bltz	a0,800059e2 <sys_write+0x5c>
    800059a4:	fe440593          	addi	a1,s0,-28
    800059a8:	4509                	li	a0,2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	8a4080e7          	jalr	-1884(ra) # 8000324e <argint>
    return -1;
    800059b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b4:	02054763          	bltz	a0,800059e2 <sys_write+0x5c>
    800059b8:	fd840593          	addi	a1,s0,-40
    800059bc:	4505                	li	a0,1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	8b2080e7          	jalr	-1870(ra) # 80003270 <argaddr>
    return -1;
    800059c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c8:	00054d63          	bltz	a0,800059e2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800059cc:	fe442603          	lw	a2,-28(s0)
    800059d0:	fd843583          	ld	a1,-40(s0)
    800059d4:	fe843503          	ld	a0,-24(s0)
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	4e6080e7          	jalr	1254(ra) # 80004ebe <filewrite>
    800059e0:	87aa                	mv	a5,a0
}
    800059e2:	853e                	mv	a0,a5
    800059e4:	70a2                	ld	ra,40(sp)
    800059e6:	7402                	ld	s0,32(sp)
    800059e8:	6145                	addi	sp,sp,48
    800059ea:	8082                	ret

00000000800059ec <sys_close>:
{
    800059ec:	1101                	addi	sp,sp,-32
    800059ee:	ec06                	sd	ra,24(sp)
    800059f0:	e822                	sd	s0,16(sp)
    800059f2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059f4:	fe040613          	addi	a2,s0,-32
    800059f8:	fec40593          	addi	a1,s0,-20
    800059fc:	4501                	li	a0,0
    800059fe:	00000097          	auipc	ra,0x0
    80005a02:	cc0080e7          	jalr	-832(ra) # 800056be <argfd>
    return -1;
    80005a06:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a08:	02054563          	bltz	a0,80005a32 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005a0c:	ffffc097          	auipc	ra,0xffffc
    80005a10:	0e0080e7          	jalr	224(ra) # 80001aec <myproc>
    80005a14:	fec42783          	lw	a5,-20(s0)
    80005a18:	07478793          	addi	a5,a5,116
    80005a1c:	078e                	slli	a5,a5,0x3
    80005a1e:	953e                	add	a0,a0,a5
    80005a20:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005a24:	fe043503          	ld	a0,-32(s0)
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	29a080e7          	jalr	666(ra) # 80004cc2 <fileclose>
  return 0;
    80005a30:	4781                	li	a5,0
}
    80005a32:	853e                	mv	a0,a5
    80005a34:	60e2                	ld	ra,24(sp)
    80005a36:	6442                	ld	s0,16(sp)
    80005a38:	6105                	addi	sp,sp,32
    80005a3a:	8082                	ret

0000000080005a3c <sys_fstat>:
{
    80005a3c:	1101                	addi	sp,sp,-32
    80005a3e:	ec06                	sd	ra,24(sp)
    80005a40:	e822                	sd	s0,16(sp)
    80005a42:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a44:	fe840613          	addi	a2,s0,-24
    80005a48:	4581                	li	a1,0
    80005a4a:	4501                	li	a0,0
    80005a4c:	00000097          	auipc	ra,0x0
    80005a50:	c72080e7          	jalr	-910(ra) # 800056be <argfd>
    return -1;
    80005a54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a56:	02054563          	bltz	a0,80005a80 <sys_fstat+0x44>
    80005a5a:	fe040593          	addi	a1,s0,-32
    80005a5e:	4505                	li	a0,1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	810080e7          	jalr	-2032(ra) # 80003270 <argaddr>
    return -1;
    80005a68:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a6a:	00054b63          	bltz	a0,80005a80 <sys_fstat+0x44>
  return filestat(f, st);
    80005a6e:	fe043583          	ld	a1,-32(s0)
    80005a72:	fe843503          	ld	a0,-24(s0)
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	314080e7          	jalr	788(ra) # 80004d8a <filestat>
    80005a7e:	87aa                	mv	a5,a0
}
    80005a80:	853e                	mv	a0,a5
    80005a82:	60e2                	ld	ra,24(sp)
    80005a84:	6442                	ld	s0,16(sp)
    80005a86:	6105                	addi	sp,sp,32
    80005a88:	8082                	ret

0000000080005a8a <sys_link>:
{
    80005a8a:	7169                	addi	sp,sp,-304
    80005a8c:	f606                	sd	ra,296(sp)
    80005a8e:	f222                	sd	s0,288(sp)
    80005a90:	ee26                	sd	s1,280(sp)
    80005a92:	ea4a                	sd	s2,272(sp)
    80005a94:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a96:	08000613          	li	a2,128
    80005a9a:	ed040593          	addi	a1,s0,-304
    80005a9e:	4501                	li	a0,0
    80005aa0:	ffffd097          	auipc	ra,0xffffd
    80005aa4:	7f2080e7          	jalr	2034(ra) # 80003292 <argstr>
    return -1;
    80005aa8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aaa:	10054e63          	bltz	a0,80005bc6 <sys_link+0x13c>
    80005aae:	08000613          	li	a2,128
    80005ab2:	f5040593          	addi	a1,s0,-176
    80005ab6:	4505                	li	a0,1
    80005ab8:	ffffd097          	auipc	ra,0xffffd
    80005abc:	7da080e7          	jalr	2010(ra) # 80003292 <argstr>
    return -1;
    80005ac0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ac2:	10054263          	bltz	a0,80005bc6 <sys_link+0x13c>
  begin_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	d30080e7          	jalr	-720(ra) # 800047f6 <begin_op>
  if((ip = namei(old)) == 0){
    80005ace:	ed040513          	addi	a0,s0,-304
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	b04080e7          	jalr	-1276(ra) # 800045d6 <namei>
    80005ada:	84aa                	mv	s1,a0
    80005adc:	c551                	beqz	a0,80005b68 <sys_link+0xde>
  ilock(ip);
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	33c080e7          	jalr	828(ra) # 80003e1a <ilock>
  if(ip->type == T_DIR){
    80005ae6:	04449703          	lh	a4,68(s1)
    80005aea:	4785                	li	a5,1
    80005aec:	08f70463          	beq	a4,a5,80005b74 <sys_link+0xea>
  ip->nlink++;
    80005af0:	04a4d783          	lhu	a5,74(s1)
    80005af4:	2785                	addiw	a5,a5,1
    80005af6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	252080e7          	jalr	594(ra) # 80003d4e <iupdate>
  iunlock(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	3d6080e7          	jalr	982(ra) # 80003edc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b0e:	fd040593          	addi	a1,s0,-48
    80005b12:	f5040513          	addi	a0,s0,-176
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	ade080e7          	jalr	-1314(ra) # 800045f4 <nameiparent>
    80005b1e:	892a                	mv	s2,a0
    80005b20:	c935                	beqz	a0,80005b94 <sys_link+0x10a>
  ilock(dp);
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	2f8080e7          	jalr	760(ra) # 80003e1a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b2a:	00092703          	lw	a4,0(s2)
    80005b2e:	409c                	lw	a5,0(s1)
    80005b30:	04f71d63          	bne	a4,a5,80005b8a <sys_link+0x100>
    80005b34:	40d0                	lw	a2,4(s1)
    80005b36:	fd040593          	addi	a1,s0,-48
    80005b3a:	854a                	mv	a0,s2
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	9d8080e7          	jalr	-1576(ra) # 80004514 <dirlink>
    80005b44:	04054363          	bltz	a0,80005b8a <sys_link+0x100>
  iunlockput(dp);
    80005b48:	854a                	mv	a0,s2
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	532080e7          	jalr	1330(ra) # 8000407c <iunlockput>
  iput(ip);
    80005b52:	8526                	mv	a0,s1
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	480080e7          	jalr	1152(ra) # 80003fd4 <iput>
  end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	d18080e7          	jalr	-744(ra) # 80004874 <end_op>
  return 0;
    80005b64:	4781                	li	a5,0
    80005b66:	a085                	j	80005bc6 <sys_link+0x13c>
    end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	d0c080e7          	jalr	-756(ra) # 80004874 <end_op>
    return -1;
    80005b70:	57fd                	li	a5,-1
    80005b72:	a891                	j	80005bc6 <sys_link+0x13c>
    iunlockput(ip);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	506080e7          	jalr	1286(ra) # 8000407c <iunlockput>
    end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	cf6080e7          	jalr	-778(ra) # 80004874 <end_op>
    return -1;
    80005b86:	57fd                	li	a5,-1
    80005b88:	a83d                	j	80005bc6 <sys_link+0x13c>
    iunlockput(dp);
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	4f0080e7          	jalr	1264(ra) # 8000407c <iunlockput>
  ilock(ip);
    80005b94:	8526                	mv	a0,s1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	284080e7          	jalr	644(ra) # 80003e1a <ilock>
  ip->nlink--;
    80005b9e:	04a4d783          	lhu	a5,74(s1)
    80005ba2:	37fd                	addiw	a5,a5,-1
    80005ba4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ba8:	8526                	mv	a0,s1
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	1a4080e7          	jalr	420(ra) # 80003d4e <iupdate>
  iunlockput(ip);
    80005bb2:	8526                	mv	a0,s1
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	4c8080e7          	jalr	1224(ra) # 8000407c <iunlockput>
  end_op();
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	cb8080e7          	jalr	-840(ra) # 80004874 <end_op>
  return -1;
    80005bc4:	57fd                	li	a5,-1
}
    80005bc6:	853e                	mv	a0,a5
    80005bc8:	70b2                	ld	ra,296(sp)
    80005bca:	7412                	ld	s0,288(sp)
    80005bcc:	64f2                	ld	s1,280(sp)
    80005bce:	6952                	ld	s2,272(sp)
    80005bd0:	6155                	addi	sp,sp,304
    80005bd2:	8082                	ret

0000000080005bd4 <sys_unlink>:
{
    80005bd4:	7151                	addi	sp,sp,-240
    80005bd6:	f586                	sd	ra,232(sp)
    80005bd8:	f1a2                	sd	s0,224(sp)
    80005bda:	eda6                	sd	s1,216(sp)
    80005bdc:	e9ca                	sd	s2,208(sp)
    80005bde:	e5ce                	sd	s3,200(sp)
    80005be0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005be2:	08000613          	li	a2,128
    80005be6:	f3040593          	addi	a1,s0,-208
    80005bea:	4501                	li	a0,0
    80005bec:	ffffd097          	auipc	ra,0xffffd
    80005bf0:	6a6080e7          	jalr	1702(ra) # 80003292 <argstr>
    80005bf4:	18054163          	bltz	a0,80005d76 <sys_unlink+0x1a2>
  begin_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	bfe080e7          	jalr	-1026(ra) # 800047f6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c00:	fb040593          	addi	a1,s0,-80
    80005c04:	f3040513          	addi	a0,s0,-208
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	9ec080e7          	jalr	-1556(ra) # 800045f4 <nameiparent>
    80005c10:	84aa                	mv	s1,a0
    80005c12:	c979                	beqz	a0,80005ce8 <sys_unlink+0x114>
  ilock(dp);
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	206080e7          	jalr	518(ra) # 80003e1a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c1c:	00003597          	auipc	a1,0x3
    80005c20:	b1458593          	addi	a1,a1,-1260 # 80008730 <syscalls+0x2d0>
    80005c24:	fb040513          	addi	a0,s0,-80
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	6bc080e7          	jalr	1724(ra) # 800042e4 <namecmp>
    80005c30:	14050a63          	beqz	a0,80005d84 <sys_unlink+0x1b0>
    80005c34:	00003597          	auipc	a1,0x3
    80005c38:	b0458593          	addi	a1,a1,-1276 # 80008738 <syscalls+0x2d8>
    80005c3c:	fb040513          	addi	a0,s0,-80
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	6a4080e7          	jalr	1700(ra) # 800042e4 <namecmp>
    80005c48:	12050e63          	beqz	a0,80005d84 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c4c:	f2c40613          	addi	a2,s0,-212
    80005c50:	fb040593          	addi	a1,s0,-80
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	6a8080e7          	jalr	1704(ra) # 800042fe <dirlookup>
    80005c5e:	892a                	mv	s2,a0
    80005c60:	12050263          	beqz	a0,80005d84 <sys_unlink+0x1b0>
  ilock(ip);
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	1b6080e7          	jalr	438(ra) # 80003e1a <ilock>
  if(ip->nlink < 1)
    80005c6c:	04a91783          	lh	a5,74(s2)
    80005c70:	08f05263          	blez	a5,80005cf4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c74:	04491703          	lh	a4,68(s2)
    80005c78:	4785                	li	a5,1
    80005c7a:	08f70563          	beq	a4,a5,80005d04 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c7e:	4641                	li	a2,16
    80005c80:	4581                	li	a1,0
    80005c82:	fc040513          	addi	a0,s0,-64
    80005c86:	ffffb097          	auipc	ra,0xffffb
    80005c8a:	092080e7          	jalr	146(ra) # 80000d18 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c8e:	4741                	li	a4,16
    80005c90:	f2c42683          	lw	a3,-212(s0)
    80005c94:	fc040613          	addi	a2,s0,-64
    80005c98:	4581                	li	a1,0
    80005c9a:	8526                	mv	a0,s1
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	52a080e7          	jalr	1322(ra) # 800041c6 <writei>
    80005ca4:	47c1                	li	a5,16
    80005ca6:	0af51563          	bne	a0,a5,80005d50 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005caa:	04491703          	lh	a4,68(s2)
    80005cae:	4785                	li	a5,1
    80005cb0:	0af70863          	beq	a4,a5,80005d60 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	3c6080e7          	jalr	966(ra) # 8000407c <iunlockput>
  ip->nlink--;
    80005cbe:	04a95783          	lhu	a5,74(s2)
    80005cc2:	37fd                	addiw	a5,a5,-1
    80005cc4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cc8:	854a                	mv	a0,s2
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	084080e7          	jalr	132(ra) # 80003d4e <iupdate>
  iunlockput(ip);
    80005cd2:	854a                	mv	a0,s2
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	3a8080e7          	jalr	936(ra) # 8000407c <iunlockput>
  end_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	b98080e7          	jalr	-1128(ra) # 80004874 <end_op>
  return 0;
    80005ce4:	4501                	li	a0,0
    80005ce6:	a84d                	j	80005d98 <sys_unlink+0x1c4>
    end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	b8c080e7          	jalr	-1140(ra) # 80004874 <end_op>
    return -1;
    80005cf0:	557d                	li	a0,-1
    80005cf2:	a05d                	j	80005d98 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cf4:	00003517          	auipc	a0,0x3
    80005cf8:	a6c50513          	addi	a0,a0,-1428 # 80008760 <syscalls+0x300>
    80005cfc:	ffffb097          	auipc	ra,0xffffb
    80005d00:	840080e7          	jalr	-1984(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d04:	04c92703          	lw	a4,76(s2)
    80005d08:	02000793          	li	a5,32
    80005d0c:	f6e7f9e3          	bgeu	a5,a4,80005c7e <sys_unlink+0xaa>
    80005d10:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d14:	4741                	li	a4,16
    80005d16:	86ce                	mv	a3,s3
    80005d18:	f1840613          	addi	a2,s0,-232
    80005d1c:	4581                	li	a1,0
    80005d1e:	854a                	mv	a0,s2
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	3ae080e7          	jalr	942(ra) # 800040ce <readi>
    80005d28:	47c1                	li	a5,16
    80005d2a:	00f51b63          	bne	a0,a5,80005d40 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d2e:	f1845783          	lhu	a5,-232(s0)
    80005d32:	e7a1                	bnez	a5,80005d7a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d34:	29c1                	addiw	s3,s3,16
    80005d36:	04c92783          	lw	a5,76(s2)
    80005d3a:	fcf9ede3          	bltu	s3,a5,80005d14 <sys_unlink+0x140>
    80005d3e:	b781                	j	80005c7e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d40:	00003517          	auipc	a0,0x3
    80005d44:	a3850513          	addi	a0,a0,-1480 # 80008778 <syscalls+0x318>
    80005d48:	ffffa097          	auipc	ra,0xffffa
    80005d4c:	7f4080e7          	jalr	2036(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005d50:	00003517          	auipc	a0,0x3
    80005d54:	a4050513          	addi	a0,a0,-1472 # 80008790 <syscalls+0x330>
    80005d58:	ffffa097          	auipc	ra,0xffffa
    80005d5c:	7e4080e7          	jalr	2020(ra) # 8000053c <panic>
    dp->nlink--;
    80005d60:	04a4d783          	lhu	a5,74(s1)
    80005d64:	37fd                	addiw	a5,a5,-1
    80005d66:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d6a:	8526                	mv	a0,s1
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	fe2080e7          	jalr	-30(ra) # 80003d4e <iupdate>
    80005d74:	b781                	j	80005cb4 <sys_unlink+0xe0>
    return -1;
    80005d76:	557d                	li	a0,-1
    80005d78:	a005                	j	80005d98 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d7a:	854a                	mv	a0,s2
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	300080e7          	jalr	768(ra) # 8000407c <iunlockput>
  iunlockput(dp);
    80005d84:	8526                	mv	a0,s1
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	2f6080e7          	jalr	758(ra) # 8000407c <iunlockput>
  end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	ae6080e7          	jalr	-1306(ra) # 80004874 <end_op>
  return -1;
    80005d96:	557d                	li	a0,-1
}
    80005d98:	70ae                	ld	ra,232(sp)
    80005d9a:	740e                	ld	s0,224(sp)
    80005d9c:	64ee                	ld	s1,216(sp)
    80005d9e:	694e                	ld	s2,208(sp)
    80005da0:	69ae                	ld	s3,200(sp)
    80005da2:	616d                	addi	sp,sp,240
    80005da4:	8082                	ret

0000000080005da6 <sys_open>:

uint64
sys_open(void)
{
    80005da6:	7131                	addi	sp,sp,-192
    80005da8:	fd06                	sd	ra,184(sp)
    80005daa:	f922                	sd	s0,176(sp)
    80005dac:	f526                	sd	s1,168(sp)
    80005dae:	f14a                	sd	s2,160(sp)
    80005db0:	ed4e                	sd	s3,152(sp)
    80005db2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005db4:	08000613          	li	a2,128
    80005db8:	f5040593          	addi	a1,s0,-176
    80005dbc:	4501                	li	a0,0
    80005dbe:	ffffd097          	auipc	ra,0xffffd
    80005dc2:	4d4080e7          	jalr	1236(ra) # 80003292 <argstr>
    return -1;
    80005dc6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dc8:	0c054163          	bltz	a0,80005e8a <sys_open+0xe4>
    80005dcc:	f4c40593          	addi	a1,s0,-180
    80005dd0:	4505                	li	a0,1
    80005dd2:	ffffd097          	auipc	ra,0xffffd
    80005dd6:	47c080e7          	jalr	1148(ra) # 8000324e <argint>
    80005dda:	0a054863          	bltz	a0,80005e8a <sys_open+0xe4>

  begin_op();
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	a18080e7          	jalr	-1512(ra) # 800047f6 <begin_op>

  if(omode & O_CREATE){
    80005de6:	f4c42783          	lw	a5,-180(s0)
    80005dea:	2007f793          	andi	a5,a5,512
    80005dee:	cbdd                	beqz	a5,80005ea4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005df0:	4681                	li	a3,0
    80005df2:	4601                	li	a2,0
    80005df4:	4589                	li	a1,2
    80005df6:	f5040513          	addi	a0,s0,-176
    80005dfa:	00000097          	auipc	ra,0x0
    80005dfe:	96e080e7          	jalr	-1682(ra) # 80005768 <create>
    80005e02:	892a                	mv	s2,a0
    if(ip == 0){
    80005e04:	c959                	beqz	a0,80005e9a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e06:	04491703          	lh	a4,68(s2)
    80005e0a:	478d                	li	a5,3
    80005e0c:	00f71763          	bne	a4,a5,80005e1a <sys_open+0x74>
    80005e10:	04695703          	lhu	a4,70(s2)
    80005e14:	47a5                	li	a5,9
    80005e16:	0ce7ec63          	bltu	a5,a4,80005eee <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	dec080e7          	jalr	-532(ra) # 80004c06 <filealloc>
    80005e22:	89aa                	mv	s3,a0
    80005e24:	10050263          	beqz	a0,80005f28 <sys_open+0x182>
    80005e28:	00000097          	auipc	ra,0x0
    80005e2c:	8fe080e7          	jalr	-1794(ra) # 80005726 <fdalloc>
    80005e30:	84aa                	mv	s1,a0
    80005e32:	0e054663          	bltz	a0,80005f1e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e36:	04491703          	lh	a4,68(s2)
    80005e3a:	478d                	li	a5,3
    80005e3c:	0cf70463          	beq	a4,a5,80005f04 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e40:	4789                	li	a5,2
    80005e42:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e46:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e4a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e4e:	f4c42783          	lw	a5,-180(s0)
    80005e52:	0017c713          	xori	a4,a5,1
    80005e56:	8b05                	andi	a4,a4,1
    80005e58:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e5c:	0037f713          	andi	a4,a5,3
    80005e60:	00e03733          	snez	a4,a4
    80005e64:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e68:	4007f793          	andi	a5,a5,1024
    80005e6c:	c791                	beqz	a5,80005e78 <sys_open+0xd2>
    80005e6e:	04491703          	lh	a4,68(s2)
    80005e72:	4789                	li	a5,2
    80005e74:	08f70f63          	beq	a4,a5,80005f12 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e78:	854a                	mv	a0,s2
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	062080e7          	jalr	98(ra) # 80003edc <iunlock>
  end_op();
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	9f2080e7          	jalr	-1550(ra) # 80004874 <end_op>

  return fd;
}
    80005e8a:	8526                	mv	a0,s1
    80005e8c:	70ea                	ld	ra,184(sp)
    80005e8e:	744a                	ld	s0,176(sp)
    80005e90:	74aa                	ld	s1,168(sp)
    80005e92:	790a                	ld	s2,160(sp)
    80005e94:	69ea                	ld	s3,152(sp)
    80005e96:	6129                	addi	sp,sp,192
    80005e98:	8082                	ret
      end_op();
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	9da080e7          	jalr	-1574(ra) # 80004874 <end_op>
      return -1;
    80005ea2:	b7e5                	j	80005e8a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ea4:	f5040513          	addi	a0,s0,-176
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	72e080e7          	jalr	1838(ra) # 800045d6 <namei>
    80005eb0:	892a                	mv	s2,a0
    80005eb2:	c905                	beqz	a0,80005ee2 <sys_open+0x13c>
    ilock(ip);
    80005eb4:	ffffe097          	auipc	ra,0xffffe
    80005eb8:	f66080e7          	jalr	-154(ra) # 80003e1a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ebc:	04491703          	lh	a4,68(s2)
    80005ec0:	4785                	li	a5,1
    80005ec2:	f4f712e3          	bne	a4,a5,80005e06 <sys_open+0x60>
    80005ec6:	f4c42783          	lw	a5,-180(s0)
    80005eca:	dba1                	beqz	a5,80005e1a <sys_open+0x74>
      iunlockput(ip);
    80005ecc:	854a                	mv	a0,s2
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	1ae080e7          	jalr	430(ra) # 8000407c <iunlockput>
      end_op();
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	99e080e7          	jalr	-1634(ra) # 80004874 <end_op>
      return -1;
    80005ede:	54fd                	li	s1,-1
    80005ee0:	b76d                	j	80005e8a <sys_open+0xe4>
      end_op();
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	992080e7          	jalr	-1646(ra) # 80004874 <end_op>
      return -1;
    80005eea:	54fd                	li	s1,-1
    80005eec:	bf79                	j	80005e8a <sys_open+0xe4>
    iunlockput(ip);
    80005eee:	854a                	mv	a0,s2
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	18c080e7          	jalr	396(ra) # 8000407c <iunlockput>
    end_op();
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	97c080e7          	jalr	-1668(ra) # 80004874 <end_op>
    return -1;
    80005f00:	54fd                	li	s1,-1
    80005f02:	b761                	j	80005e8a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f04:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f08:	04691783          	lh	a5,70(s2)
    80005f0c:	02f99223          	sh	a5,36(s3)
    80005f10:	bf2d                	j	80005e4a <sys_open+0xa4>
    itrunc(ip);
    80005f12:	854a                	mv	a0,s2
    80005f14:	ffffe097          	auipc	ra,0xffffe
    80005f18:	014080e7          	jalr	20(ra) # 80003f28 <itrunc>
    80005f1c:	bfb1                	j	80005e78 <sys_open+0xd2>
      fileclose(f);
    80005f1e:	854e                	mv	a0,s3
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	da2080e7          	jalr	-606(ra) # 80004cc2 <fileclose>
    iunlockput(ip);
    80005f28:	854a                	mv	a0,s2
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	152080e7          	jalr	338(ra) # 8000407c <iunlockput>
    end_op();
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	942080e7          	jalr	-1726(ra) # 80004874 <end_op>
    return -1;
    80005f3a:	54fd                	li	s1,-1
    80005f3c:	b7b9                	j	80005e8a <sys_open+0xe4>

0000000080005f3e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f3e:	7175                	addi	sp,sp,-144
    80005f40:	e506                	sd	ra,136(sp)
    80005f42:	e122                	sd	s0,128(sp)
    80005f44:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f46:	fffff097          	auipc	ra,0xfffff
    80005f4a:	8b0080e7          	jalr	-1872(ra) # 800047f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f4e:	08000613          	li	a2,128
    80005f52:	f7040593          	addi	a1,s0,-144
    80005f56:	4501                	li	a0,0
    80005f58:	ffffd097          	auipc	ra,0xffffd
    80005f5c:	33a080e7          	jalr	826(ra) # 80003292 <argstr>
    80005f60:	02054963          	bltz	a0,80005f92 <sys_mkdir+0x54>
    80005f64:	4681                	li	a3,0
    80005f66:	4601                	li	a2,0
    80005f68:	4585                	li	a1,1
    80005f6a:	f7040513          	addi	a0,s0,-144
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	7fa080e7          	jalr	2042(ra) # 80005768 <create>
    80005f76:	cd11                	beqz	a0,80005f92 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	104080e7          	jalr	260(ra) # 8000407c <iunlockput>
  end_op();
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	8f4080e7          	jalr	-1804(ra) # 80004874 <end_op>
  return 0;
    80005f88:	4501                	li	a0,0
}
    80005f8a:	60aa                	ld	ra,136(sp)
    80005f8c:	640a                	ld	s0,128(sp)
    80005f8e:	6149                	addi	sp,sp,144
    80005f90:	8082                	ret
    end_op();
    80005f92:	fffff097          	auipc	ra,0xfffff
    80005f96:	8e2080e7          	jalr	-1822(ra) # 80004874 <end_op>
    return -1;
    80005f9a:	557d                	li	a0,-1
    80005f9c:	b7fd                	j	80005f8a <sys_mkdir+0x4c>

0000000080005f9e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f9e:	7135                	addi	sp,sp,-160
    80005fa0:	ed06                	sd	ra,152(sp)
    80005fa2:	e922                	sd	s0,144(sp)
    80005fa4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	850080e7          	jalr	-1968(ra) # 800047f6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fae:	08000613          	li	a2,128
    80005fb2:	f7040593          	addi	a1,s0,-144
    80005fb6:	4501                	li	a0,0
    80005fb8:	ffffd097          	auipc	ra,0xffffd
    80005fbc:	2da080e7          	jalr	730(ra) # 80003292 <argstr>
    80005fc0:	04054a63          	bltz	a0,80006014 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fc4:	f6c40593          	addi	a1,s0,-148
    80005fc8:	4505                	li	a0,1
    80005fca:	ffffd097          	auipc	ra,0xffffd
    80005fce:	284080e7          	jalr	644(ra) # 8000324e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fd2:	04054163          	bltz	a0,80006014 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005fd6:	f6840593          	addi	a1,s0,-152
    80005fda:	4509                	li	a0,2
    80005fdc:	ffffd097          	auipc	ra,0xffffd
    80005fe0:	272080e7          	jalr	626(ra) # 8000324e <argint>
     argint(1, &major) < 0 ||
    80005fe4:	02054863          	bltz	a0,80006014 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fe8:	f6841683          	lh	a3,-152(s0)
    80005fec:	f6c41603          	lh	a2,-148(s0)
    80005ff0:	458d                	li	a1,3
    80005ff2:	f7040513          	addi	a0,s0,-144
    80005ff6:	fffff097          	auipc	ra,0xfffff
    80005ffa:	772080e7          	jalr	1906(ra) # 80005768 <create>
     argint(2, &minor) < 0 ||
    80005ffe:	c919                	beqz	a0,80006014 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	07c080e7          	jalr	124(ra) # 8000407c <iunlockput>
  end_op();
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	86c080e7          	jalr	-1940(ra) # 80004874 <end_op>
  return 0;
    80006010:	4501                	li	a0,0
    80006012:	a031                	j	8000601e <sys_mknod+0x80>
    end_op();
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	860080e7          	jalr	-1952(ra) # 80004874 <end_op>
    return -1;
    8000601c:	557d                	li	a0,-1
}
    8000601e:	60ea                	ld	ra,152(sp)
    80006020:	644a                	ld	s0,144(sp)
    80006022:	610d                	addi	sp,sp,160
    80006024:	8082                	ret

0000000080006026 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006026:	7135                	addi	sp,sp,-160
    80006028:	ed06                	sd	ra,152(sp)
    8000602a:	e922                	sd	s0,144(sp)
    8000602c:	e526                	sd	s1,136(sp)
    8000602e:	e14a                	sd	s2,128(sp)
    80006030:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006032:	ffffc097          	auipc	ra,0xffffc
    80006036:	aba080e7          	jalr	-1350(ra) # 80001aec <myproc>
    8000603a:	892a                	mv	s2,a0
  
  begin_op();
    8000603c:	ffffe097          	auipc	ra,0xffffe
    80006040:	7ba080e7          	jalr	1978(ra) # 800047f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006044:	08000613          	li	a2,128
    80006048:	f6040593          	addi	a1,s0,-160
    8000604c:	4501                	li	a0,0
    8000604e:	ffffd097          	auipc	ra,0xffffd
    80006052:	244080e7          	jalr	580(ra) # 80003292 <argstr>
    80006056:	04054b63          	bltz	a0,800060ac <sys_chdir+0x86>
    8000605a:	f6040513          	addi	a0,s0,-160
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	578080e7          	jalr	1400(ra) # 800045d6 <namei>
    80006066:	84aa                	mv	s1,a0
    80006068:	c131                	beqz	a0,800060ac <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	db0080e7          	jalr	-592(ra) # 80003e1a <ilock>
  if(ip->type != T_DIR){
    80006072:	04449703          	lh	a4,68(s1)
    80006076:	4785                	li	a5,1
    80006078:	04f71063          	bne	a4,a5,800060b8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000607c:	8526                	mv	a0,s1
    8000607e:	ffffe097          	auipc	ra,0xffffe
    80006082:	e5e080e7          	jalr	-418(ra) # 80003edc <iunlock>
  iput(p->cwd);
    80006086:	42893503          	ld	a0,1064(s2)
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	f4a080e7          	jalr	-182(ra) # 80003fd4 <iput>
  end_op();
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	7e2080e7          	jalr	2018(ra) # 80004874 <end_op>
  p->cwd = ip;
    8000609a:	42993423          	sd	s1,1064(s2)
  return 0;
    8000609e:	4501                	li	a0,0
}
    800060a0:	60ea                	ld	ra,152(sp)
    800060a2:	644a                	ld	s0,144(sp)
    800060a4:	64aa                	ld	s1,136(sp)
    800060a6:	690a                	ld	s2,128(sp)
    800060a8:	610d                	addi	sp,sp,160
    800060aa:	8082                	ret
    end_op();
    800060ac:	ffffe097          	auipc	ra,0xffffe
    800060b0:	7c8080e7          	jalr	1992(ra) # 80004874 <end_op>
    return -1;
    800060b4:	557d                	li	a0,-1
    800060b6:	b7ed                	j	800060a0 <sys_chdir+0x7a>
    iunlockput(ip);
    800060b8:	8526                	mv	a0,s1
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	fc2080e7          	jalr	-62(ra) # 8000407c <iunlockput>
    end_op();
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	7b2080e7          	jalr	1970(ra) # 80004874 <end_op>
    return -1;
    800060ca:	557d                	li	a0,-1
    800060cc:	bfd1                	j	800060a0 <sys_chdir+0x7a>

00000000800060ce <sys_exec>:

uint64
sys_exec(void)
{
    800060ce:	7145                	addi	sp,sp,-464
    800060d0:	e786                	sd	ra,456(sp)
    800060d2:	e3a2                	sd	s0,448(sp)
    800060d4:	ff26                	sd	s1,440(sp)
    800060d6:	fb4a                	sd	s2,432(sp)
    800060d8:	f74e                	sd	s3,424(sp)
    800060da:	f352                	sd	s4,416(sp)
    800060dc:	ef56                	sd	s5,408(sp)
    800060de:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060e0:	08000613          	li	a2,128
    800060e4:	f4040593          	addi	a1,s0,-192
    800060e8:	4501                	li	a0,0
    800060ea:	ffffd097          	auipc	ra,0xffffd
    800060ee:	1a8080e7          	jalr	424(ra) # 80003292 <argstr>
    return -1;
    800060f2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060f4:	0c054b63          	bltz	a0,800061ca <sys_exec+0xfc>
    800060f8:	e3840593          	addi	a1,s0,-456
    800060fc:	4505                	li	a0,1
    800060fe:	ffffd097          	auipc	ra,0xffffd
    80006102:	172080e7          	jalr	370(ra) # 80003270 <argaddr>
    80006106:	0c054263          	bltz	a0,800061ca <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000610a:	10000613          	li	a2,256
    8000610e:	4581                	li	a1,0
    80006110:	e4040513          	addi	a0,s0,-448
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	c04080e7          	jalr	-1020(ra) # 80000d18 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000611c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006120:	89a6                	mv	s3,s1
    80006122:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006124:	02000a13          	li	s4,32
    80006128:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000612c:	00391513          	slli	a0,s2,0x3
    80006130:	e3040593          	addi	a1,s0,-464
    80006134:	e3843783          	ld	a5,-456(s0)
    80006138:	953e                	add	a0,a0,a5
    8000613a:	ffffd097          	auipc	ra,0xffffd
    8000613e:	074080e7          	jalr	116(ra) # 800031ae <fetchaddr>
    80006142:	02054a63          	bltz	a0,80006176 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006146:	e3043783          	ld	a5,-464(s0)
    8000614a:	c3b9                	beqz	a5,80006190 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	996080e7          	jalr	-1642(ra) # 80000ae2 <kalloc>
    80006154:	85aa                	mv	a1,a0
    80006156:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000615a:	cd11                	beqz	a0,80006176 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000615c:	6605                	lui	a2,0x1
    8000615e:	e3043503          	ld	a0,-464(s0)
    80006162:	ffffd097          	auipc	ra,0xffffd
    80006166:	0a2080e7          	jalr	162(ra) # 80003204 <fetchstr>
    8000616a:	00054663          	bltz	a0,80006176 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000616e:	0905                	addi	s2,s2,1
    80006170:	09a1                	addi	s3,s3,8
    80006172:	fb491be3          	bne	s2,s4,80006128 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006176:	f4040913          	addi	s2,s0,-192
    8000617a:	6088                	ld	a0,0(s1)
    8000617c:	c531                	beqz	a0,800061c8 <sys_exec+0xfa>
    kfree(argv[i]);
    8000617e:	ffffb097          	auipc	ra,0xffffb
    80006182:	866080e7          	jalr	-1946(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006186:	04a1                	addi	s1,s1,8
    80006188:	ff2499e3          	bne	s1,s2,8000617a <sys_exec+0xac>
  return -1;
    8000618c:	597d                	li	s2,-1
    8000618e:	a835                	j	800061ca <sys_exec+0xfc>
      argv[i] = 0;
    80006190:	0a8e                	slli	s5,s5,0x3
    80006192:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffc8fc0>
    80006196:	00878ab3          	add	s5,a5,s0
    8000619a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000619e:	e4040593          	addi	a1,s0,-448
    800061a2:	f4040513          	addi	a0,s0,-192
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	170080e7          	jalr	368(ra) # 80005316 <exec>
    800061ae:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061b0:	f4040993          	addi	s3,s0,-192
    800061b4:	6088                	ld	a0,0(s1)
    800061b6:	c911                	beqz	a0,800061ca <sys_exec+0xfc>
    kfree(argv[i]);
    800061b8:	ffffb097          	auipc	ra,0xffffb
    800061bc:	82c080e7          	jalr	-2004(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061c0:	04a1                	addi	s1,s1,8
    800061c2:	ff3499e3          	bne	s1,s3,800061b4 <sys_exec+0xe6>
    800061c6:	a011                	j	800061ca <sys_exec+0xfc>
  return -1;
    800061c8:	597d                	li	s2,-1
}
    800061ca:	854a                	mv	a0,s2
    800061cc:	60be                	ld	ra,456(sp)
    800061ce:	641e                	ld	s0,448(sp)
    800061d0:	74fa                	ld	s1,440(sp)
    800061d2:	795a                	ld	s2,432(sp)
    800061d4:	79ba                	ld	s3,424(sp)
    800061d6:	7a1a                	ld	s4,416(sp)
    800061d8:	6afa                	ld	s5,408(sp)
    800061da:	6179                	addi	sp,sp,464
    800061dc:	8082                	ret

00000000800061de <sys_pipe>:

uint64
sys_pipe(void)
{
    800061de:	7139                	addi	sp,sp,-64
    800061e0:	fc06                	sd	ra,56(sp)
    800061e2:	f822                	sd	s0,48(sp)
    800061e4:	f426                	sd	s1,40(sp)
    800061e6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	904080e7          	jalr	-1788(ra) # 80001aec <myproc>
    800061f0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061f2:	fd840593          	addi	a1,s0,-40
    800061f6:	4501                	li	a0,0
    800061f8:	ffffd097          	auipc	ra,0xffffd
    800061fc:	078080e7          	jalr	120(ra) # 80003270 <argaddr>
    return -1;
    80006200:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006202:	0e054563          	bltz	a0,800062ec <sys_pipe+0x10e>
  if(pipealloc(&rf, &wf) < 0)
    80006206:	fc840593          	addi	a1,s0,-56
    8000620a:	fd040513          	addi	a0,s0,-48
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	de4080e7          	jalr	-540(ra) # 80004ff2 <pipealloc>
    return -1;
    80006216:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006218:	0c054a63          	bltz	a0,800062ec <sys_pipe+0x10e>
  fd0 = -1;
    8000621c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006220:	fd043503          	ld	a0,-48(s0)
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	502080e7          	jalr	1282(ra) # 80005726 <fdalloc>
    8000622c:	fca42223          	sw	a0,-60(s0)
    80006230:	0a054163          	bltz	a0,800062d2 <sys_pipe+0xf4>
    80006234:	fc843503          	ld	a0,-56(s0)
    80006238:	fffff097          	auipc	ra,0xfffff
    8000623c:	4ee080e7          	jalr	1262(ra) # 80005726 <fdalloc>
    80006240:	fca42023          	sw	a0,-64(s0)
    80006244:	06054d63          	bltz	a0,800062be <sys_pipe+0xe0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006248:	4691                	li	a3,4
    8000624a:	fc440613          	addi	a2,s0,-60
    8000624e:	fd843583          	ld	a1,-40(s0)
    80006252:	3284b503          	ld	a0,808(s1)
    80006256:	ffffb097          	auipc	ra,0xffffb
    8000625a:	4dc080e7          	jalr	1244(ra) # 80001732 <copyout>
    8000625e:	02054163          	bltz	a0,80006280 <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006262:	4691                	li	a3,4
    80006264:	fc040613          	addi	a2,s0,-64
    80006268:	fd843583          	ld	a1,-40(s0)
    8000626c:	0591                	addi	a1,a1,4
    8000626e:	3284b503          	ld	a0,808(s1)
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	4c0080e7          	jalr	1216(ra) # 80001732 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000627a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000627c:	06055863          	bgez	a0,800062ec <sys_pipe+0x10e>
    p->ofile[fd0] = 0;
    80006280:	fc442783          	lw	a5,-60(s0)
    80006284:	07478793          	addi	a5,a5,116
    80006288:	078e                	slli	a5,a5,0x3
    8000628a:	97a6                	add	a5,a5,s1
    8000628c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006290:	fc042783          	lw	a5,-64(s0)
    80006294:	07478793          	addi	a5,a5,116
    80006298:	078e                	slli	a5,a5,0x3
    8000629a:	00f48533          	add	a0,s1,a5
    8000629e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800062a2:	fd043503          	ld	a0,-48(s0)
    800062a6:	fffff097          	auipc	ra,0xfffff
    800062aa:	a1c080e7          	jalr	-1508(ra) # 80004cc2 <fileclose>
    fileclose(wf);
    800062ae:	fc843503          	ld	a0,-56(s0)
    800062b2:	fffff097          	auipc	ra,0xfffff
    800062b6:	a10080e7          	jalr	-1520(ra) # 80004cc2 <fileclose>
    return -1;
    800062ba:	57fd                	li	a5,-1
    800062bc:	a805                	j	800062ec <sys_pipe+0x10e>
    if(fd0 >= 0)
    800062be:	fc442783          	lw	a5,-60(s0)
    800062c2:	0007c863          	bltz	a5,800062d2 <sys_pipe+0xf4>
      p->ofile[fd0] = 0;
    800062c6:	07478793          	addi	a5,a5,116
    800062ca:	078e                	slli	a5,a5,0x3
    800062cc:	97a6                	add	a5,a5,s1
    800062ce:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    800062d2:	fd043503          	ld	a0,-48(s0)
    800062d6:	fffff097          	auipc	ra,0xfffff
    800062da:	9ec080e7          	jalr	-1556(ra) # 80004cc2 <fileclose>
    fileclose(wf);
    800062de:	fc843503          	ld	a0,-56(s0)
    800062e2:	fffff097          	auipc	ra,0xfffff
    800062e6:	9e0080e7          	jalr	-1568(ra) # 80004cc2 <fileclose>
    return -1;
    800062ea:	57fd                	li	a5,-1
}
    800062ec:	853e                	mv	a0,a5
    800062ee:	70e2                	ld	ra,56(sp)
    800062f0:	7442                	ld	s0,48(sp)
    800062f2:	74a2                	ld	s1,40(sp)
    800062f4:	6121                	addi	sp,sp,64
    800062f6:	8082                	ret

00000000800062f8 <sys_mmap>:

// HW5 - Task 1a
// Create a new mapped memory region
uint64
sys_mmap()
{
    800062f8:	7139                	addi	sp,sp,-64
    800062fa:	fc06                	sd	ra,56(sp)
    800062fc:	f822                	sd	s0,48(sp)
    800062fe:	f426                	sd	s1,40(sp)
    80006300:	f04a                	sd	s2,32(sp)
    80006302:	ec4e                	sd	s3,24(sp)
    80006304:	0080                	addi	s0,sp,64
  uint64 length;
  int    prot;
  int    flags;
  struct proc *p = myproc();
    80006306:	ffffb097          	auipc	ra,0xffffb
    8000630a:	7e6080e7          	jalr	2022(ra) # 80001aec <myproc>
    8000630e:	89aa                	mv	s3,a0
  struct mmr *newmmr = 0;
  uint64 start_addr;

  /* Add error checking for length, prot, and flags arguments */

  if (argaddr(1, &length) < 0)
    80006310:	fc840593          	addi	a1,s0,-56
    80006314:	4505                	li	a0,1
    80006316:	ffffd097          	auipc	ra,0xffffd
    8000631a:	f5a080e7          	jalr	-166(ra) # 80003270 <argaddr>
    return -1;
    8000631e:	597d                	li	s2,-1
  if (argaddr(1, &length) < 0)
    80006320:	0a054863          	bltz	a0,800063d0 <sys_mmap+0xd8>
  if (argint(2, &prot) < 0)
    80006324:	fc440593          	addi	a1,s0,-60
    80006328:	4509                	li	a0,2
    8000632a:	ffffd097          	auipc	ra,0xffffd
    8000632e:	f24080e7          	jalr	-220(ra) # 8000324e <argint>
    80006332:	08054f63          	bltz	a0,800063d0 <sys_mmap+0xd8>
    return -1;
  if (argint(3, &flags) <0)
    80006336:	fc040593          	addi	a1,s0,-64
    8000633a:	450d                	li	a0,3
    8000633c:	ffffd097          	auipc	ra,0xffffd
    80006340:	f12080e7          	jalr	-238(ra) # 8000324e <argint>
    80006344:	0c054263          	bltz	a0,80006408 <sys_mmap+0x110>
    80006348:	01498793          	addi	a5,s3,20
    return -1;
  // Search p->mmr[] for unused location 
  for (int i = 0; i < MAX_MMR; i++) {
    8000634c:	4481                	li	s1,0
    8000634e:	46a9                	li	a3,10
    if (p->mmr[i].valid == 0) {
    80006350:	4398                	lw	a4,0(a5)
    80006352:	cb01                	beqz	a4,80006362 <sys_mmap+0x6a>
  for (int i = 0; i < MAX_MMR; i++) {
    80006354:	2485                	addiw	s1,s1,1
    80006356:	04878793          	addi	a5,a5,72
    8000635a:	fed49be3          	bne	s1,a3,80006350 <sys_mmap+0x58>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
      newmmr->mmr_family.listid = alloc_mmr_listid();
    p->cur_max = start_addr;
    return start_addr;
  } else {
    return -1;
    8000635e:	597d                	li	s2,-1
    80006360:	a885                	j	800063d0 <sys_mmap+0xd8>
    start_addr = PGROUNDDOWN(p->cur_max-length);
    80006362:	2d09b903          	ld	s2,720(s3)
    80006366:	fc843783          	ld	a5,-56(s0)
    8000636a:	40f90933          	sub	s2,s2,a5
    8000636e:	77fd                	lui	a5,0xfffff
    80006370:	00f97933          	and	s2,s2,a5
    newmmr->valid = 1;
    80006374:	00349713          	slli	a4,s1,0x3
    80006378:	009707b3          	add	a5,a4,s1
    8000637c:	078e                	slli	a5,a5,0x3
    8000637e:	97ce                	add	a5,a5,s3
    80006380:	4685                	li	a3,1
    80006382:	cbd4                	sw	a3,20(a5)
    newmmr->addr = start_addr;
    80006384:	0127b023          	sd	s2,0(a5) # fffffffffffff000 <end+0xffffffff7ffc9000>
    newmmr->length = p->cur_max - start_addr;
    80006388:	2d09b603          	ld	a2,720(s3)
    8000638c:	4126063b          	subw	a2,a2,s2
    80006390:	c790                	sw	a2,8(a5)
    newmmr->prot = prot;
    80006392:	fc442683          	lw	a3,-60(s0)
    80006396:	c7d4                	sw	a3,12(a5)
    newmmr->flags = flags;
    80006398:	fc042683          	lw	a3,-64(s0)
    8000639c:	cb94                	sw	a3,16(a5)
    newmmr->mmr_family.proc = p;
    8000639e:	9726                	add	a4,a4,s1
    800063a0:	070e                	slli	a4,a4,0x3
    800063a2:	0337b823          	sd	s3,48(a5)
    newmmr->mmr_family.next = &(newmmr->mmr_family);  // next points to its own mmr_node
    800063a6:	02870713          	addi	a4,a4,40
    800063aa:	974e                	add	a4,a4,s3
    800063ac:	ff98                	sd	a4,56(a5)
    newmmr->mmr_family.prev = &(newmmr->mmr_family);  // prev points to its own mmr_node
    800063ae:	e3b8                	sd	a4,64(a5)
    if (mapvpages(p->pagetable, newmmr->addr, newmmr->length) < 0) {
    800063b0:	2601                	sext.w	a2,a2
    800063b2:	85ca                	mv	a1,s2
    800063b4:	3289b503          	ld	a0,808(s3)
    800063b8:	ffffb097          	auipc	ra,0xffffb
    800063bc:	544080e7          	jalr	1348(ra) # 800018fc <mapvpages>
    800063c0:	02054063          	bltz	a0,800063e0 <sys_mmap+0xe8>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
    800063c4:	fc042783          	lw	a5,-64(s0)
    800063c8:	8b85                	andi	a5,a5,1
    800063ca:	e785                	bnez	a5,800063f2 <sys_mmap+0xfa>
    p->cur_max = start_addr;
    800063cc:	2d29b823          	sd	s2,720(s3)
  }
}
    800063d0:	854a                	mv	a0,s2
    800063d2:	70e2                	ld	ra,56(sp)
    800063d4:	7442                	ld	s0,48(sp)
    800063d6:	74a2                	ld	s1,40(sp)
    800063d8:	7902                	ld	s2,32(sp)
    800063da:	69e2                	ld	s3,24(sp)
    800063dc:	6121                	addi	sp,sp,64
    800063de:	8082                	ret
      newmmr->valid = 0;
    800063e0:	00349793          	slli	a5,s1,0x3
    800063e4:	97a6                	add	a5,a5,s1
    800063e6:	078e                	slli	a5,a5,0x3
    800063e8:	97ce                	add	a5,a5,s3
    800063ea:	0007aa23          	sw	zero,20(a5)
      return -1;
    800063ee:	597d                	li	s2,-1
    800063f0:	b7c5                	j	800063d0 <sys_mmap+0xd8>
      newmmr->mmr_family.listid = alloc_mmr_listid();
    800063f2:	ffffc097          	auipc	ra,0xffffc
    800063f6:	7aa080e7          	jalr	1962(ra) # 80002b9c <alloc_mmr_listid>
    800063fa:	00349793          	slli	a5,s1,0x3
    800063fe:	97a6                	add	a5,a5,s1
    80006400:	078e                	slli	a5,a5,0x3
    80006402:	97ce                	add	a5,a5,s3
    80006404:	d788                	sw	a0,40(a5)
    80006406:	b7d9                	j	800063cc <sys_mmap+0xd4>
    return -1;
    80006408:	597d                	li	s2,-1
    8000640a:	b7d9                	j	800063d0 <sys_mmap+0xd8>

000000008000640c <munmap>:
// HW5 - Task 1a
// Unmap memory region if it exists
// Free physical memory if no other process has the region mapped
int
munmap(uint64 addr, uint64 length)
{
    8000640c:	715d                	addi	sp,sp,-80
    8000640e:	e486                	sd	ra,72(sp)
    80006410:	e0a2                	sd	s0,64(sp)
    80006412:	fc26                	sd	s1,56(sp)
    80006414:	f84a                	sd	s2,48(sp)
    80006416:	f44e                	sd	s3,40(sp)
    80006418:	f052                	sd	s4,32(sp)
    8000641a:	ec56                	sd	s5,24(sp)
    8000641c:	e85a                	sd	s6,16(sp)
    8000641e:	e45e                	sd	s7,8(sp)
    80006420:	e062                	sd	s8,0(sp)
    80006422:	0880                	addi	s0,sp,80
    80006424:	84aa                	mv	s1,a0
    80006426:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80006428:	ffffb097          	auipc	ra,0xffffb
    8000642c:	6c4080e7          	jalr	1732(ra) # 80001aec <myproc>
    80006430:	8a2a                	mv	s4,a0
  struct mmr *mmr = 0;
  int dofree = 0;
  int i;

  // Search proc->mmr for addr
  for (i = 0; i < MAX_MMR; i++)
    80006432:	87aa                	mv	a5,a0
    80006434:	4901                	li	s2,0
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    80006436:	4685                	li	a3,1
        (PGROUNDUP(length) == p->mmr[i].length)) {
    80006438:	6705                	lui	a4,0x1
    8000643a:	177d                	addi	a4,a4,-1 # fff <_entry-0x7ffff001>
    8000643c:	00e985b3          	add	a1,s3,a4
    80006440:	777d                	lui	a4,0xfffff
    80006442:	8df9                	and	a1,a1,a4
  for (i = 0; i < MAX_MMR; i++)
    80006444:	4629                	li	a2,10
    80006446:	a031                	j	80006452 <munmap+0x46>
    80006448:	2905                	addiw	s2,s2,1
    8000644a:	04878793          	addi	a5,a5,72
    8000644e:	04c90763          	beq	s2,a2,8000649c <munmap+0x90>
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    80006452:	0147a983          	lw	s3,20(a5)
    80006456:	fed999e3          	bne	s3,a3,80006448 <munmap+0x3c>
    8000645a:	6388                	ld	a0,0(a5)
    8000645c:	fe9516e3          	bne	a0,s1,80006448 <munmap+0x3c>
        (PGROUNDUP(length) == p->mmr[i].length)) {
    80006460:	4798                	lw	a4,8(a5)
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    80006462:	fee593e3          	bne	a1,a4,80006448 <munmap+0x3c>
      break;
    }
  if (!mmr) {
    return -1;
  }
  mmr->valid = 0;
    80006466:	00391793          	slli	a5,s2,0x3
    8000646a:	97ca                	add	a5,a5,s2
    8000646c:	078e                	slli	a5,a5,0x3
    8000646e:	97d2                	add	a5,a5,s4
    80006470:	0007aa23          	sw	zero,20(a5)
  if (mmr->flags & MAP_PRIVATE)
    80006474:	0107aa83          	lw	s5,16(a5)
    80006478:	002afa93          	andi	s5,s5,2
    8000647c:	020a8263          	beqz	s5,800064a0 <munmap+0x94>
      release(&pmmrlist->lock);
    }
  }
  // Remove mappings from page table
  // Also free physical memory if no other process has this region mapped
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    80006480:	00391793          	slli	a5,s2,0x3
    80006484:	993e                	add	s2,s2,a5
    80006486:	090e                	slli	s2,s2,0x3
    80006488:	9952                	add	s2,s2,s4
    8000648a:	00892783          	lw	a5,8(s2)
    8000648e:	00093703          	ld	a4,0(s2)
    80006492:	97ba                	add	a5,a5,a4
    80006494:	0cf4f463          	bgeu	s1,a5,8000655c <munmap+0x150>
    80006498:	6a85                	lui	s5,0x1
    8000649a:	a051                	j	8000651e <munmap+0x112>
    return -1;
    8000649c:	557d                	li	a0,-1
    8000649e:	a05d                	j	80006544 <munmap+0x138>
    struct mmr_list *pmmrlist = get_mmr_list(mmr->mmr_family.listid);
    800064a0:	00391b13          	slli	s6,s2,0x3
    800064a4:	012b0c33          	add	s8,s6,s2
    800064a8:	0c0e                	slli	s8,s8,0x3
    800064aa:	9c52                	add	s8,s8,s4
    800064ac:	028c2503          	lw	a0,40(s8)
    800064b0:	ffffc097          	auipc	ra,0xffffc
    800064b4:	f6a080e7          	jalr	-150(ra) # 8000241a <get_mmr_list>
    800064b8:	8baa                	mv	s7,a0
    acquire(&pmmrlist->lock);
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	762080e7          	jalr	1890(ra) # 80000c1c <acquire>
    if (mmr->mmr_family.next == &(mmr->mmr_family)) { // no other family members
    800064c2:	038c3703          	ld	a4,56(s8)
    800064c6:	012b07b3          	add	a5,s6,s2
    800064ca:	078e                	slli	a5,a5,0x3
    800064cc:	02878793          	addi	a5,a5,40
    800064d0:	97d2                	add	a5,a5,s4
    800064d2:	02f70263          	beq	a4,a5,800064f6 <munmap+0xea>
      (mmr->mmr_family.next)->prev = mmr->mmr_family.prev;
    800064d6:	00391793          	slli	a5,s2,0x3
    800064da:	97ca                	add	a5,a5,s2
    800064dc:	078e                	slli	a5,a5,0x3
    800064de:	97d2                	add	a5,a5,s4
    800064e0:	63b4                	ld	a3,64(a5)
    800064e2:	ef14                	sd	a3,24(a4)
      (mmr->mmr_family.prev)->next = mmr->mmr_family.next;
    800064e4:	7f9c                	ld	a5,56(a5)
    800064e6:	ea9c                	sd	a5,16(a3)
      release(&pmmrlist->lock);
    800064e8:	855e                	mv	a0,s7
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	7e6080e7          	jalr	2022(ra) # 80000cd0 <release>
  int dofree = 0;
    800064f2:	89d6                	mv	s3,s5
    800064f4:	b771                	j	80006480 <munmap+0x74>
      release(&pmmrlist->lock);
    800064f6:	855e                	mv	a0,s7
    800064f8:	ffffa097          	auipc	ra,0xffffa
    800064fc:	7d8080e7          	jalr	2008(ra) # 80000cd0 <release>
      dealloc_mmr_listid(mmr->mmr_family.listid);
    80006500:	028c2503          	lw	a0,40(s8)
    80006504:	ffffc097          	auipc	ra,0xffffc
    80006508:	f8c080e7          	jalr	-116(ra) # 80002490 <dealloc_mmr_listid>
    8000650c:	bf95                	j	80006480 <munmap+0x74>
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    8000650e:	94d6                	add	s1,s1,s5
    80006510:	00892783          	lw	a5,8(s2)
    80006514:	00093703          	ld	a4,0(s2)
    80006518:	97ba                	add	a5,a5,a4
    8000651a:	02f4f463          	bgeu	s1,a5,80006542 <munmap+0x136>
    if (walkaddr(p->pagetable, pageaddr)) {
    8000651e:	85a6                	mv	a1,s1
    80006520:	328a3503          	ld	a0,808(s4)
    80006524:	ffffb097          	auipc	ra,0xffffb
    80006528:	b82080e7          	jalr	-1150(ra) # 800010a6 <walkaddr>
    8000652c:	d16d                	beqz	a0,8000650e <munmap+0x102>
      uvmunmap(p->pagetable, pageaddr, 1, dofree);
    8000652e:	86ce                	mv	a3,s3
    80006530:	4605                	li	a2,1
    80006532:	85a6                	mv	a1,s1
    80006534:	328a3503          	ld	a0,808(s4)
    80006538:	ffffb097          	auipc	ra,0xffffb
    8000653c:	d76080e7          	jalr	-650(ra) # 800012ae <uvmunmap>
    80006540:	b7f9                	j	8000650e <munmap+0x102>
    }
  }
  return 0;
    80006542:	4501                	li	a0,0
}
    80006544:	60a6                	ld	ra,72(sp)
    80006546:	6406                	ld	s0,64(sp)
    80006548:	74e2                	ld	s1,56(sp)
    8000654a:	7942                	ld	s2,48(sp)
    8000654c:	79a2                	ld	s3,40(sp)
    8000654e:	7a02                	ld	s4,32(sp)
    80006550:	6ae2                	ld	s5,24(sp)
    80006552:	6b42                	ld	s6,16(sp)
    80006554:	6ba2                	ld	s7,8(sp)
    80006556:	6c02                	ld	s8,0(sp)
    80006558:	6161                	addi	sp,sp,80
    8000655a:	8082                	ret
  return 0;
    8000655c:	4501                	li	a0,0
    8000655e:	b7dd                	j	80006544 <munmap+0x138>

0000000080006560 <sys_munmap>:

// Get arguments and call munmap() helper function
uint64
sys_munmap(void)
{
    80006560:	1101                	addi	sp,sp,-32
    80006562:	ec06                	sd	ra,24(sp)
    80006564:	e822                	sd	s0,16(sp)
    80006566:	1000                	addi	s0,sp,32
  uint64 addr;
  uint64 length;

  // HW5 - Task 1a
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    80006568:	fe840593          	addi	a1,s0,-24
    8000656c:	4501                	li	a0,0
    8000656e:	ffffd097          	auipc	ra,0xffffd
    80006572:	d02080e7          	jalr	-766(ra) # 80003270 <argaddr>
        return -1;
    80006576:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    80006578:	02054563          	bltz	a0,800065a2 <sys_munmap+0x42>
    8000657c:	fe040593          	addi	a1,s0,-32
    80006580:	4505                	li	a0,1
    80006582:	ffffd097          	auipc	ra,0xffffd
    80006586:	cee080e7          	jalr	-786(ra) # 80003270 <argaddr>
        return -1;
    8000658a:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    8000658c:	00054b63          	bltz	a0,800065a2 <sys_munmap+0x42>
  return munmap(addr, length);
    80006590:	fe043583          	ld	a1,-32(s0)
    80006594:	fe843503          	ld	a0,-24(s0)
    80006598:	00000097          	auipc	ra,0x0
    8000659c:	e74080e7          	jalr	-396(ra) # 8000640c <munmap>
    800065a0:	87aa                	mv	a5,a0
  // return 0;
    800065a2:	853e                	mv	a0,a5
    800065a4:	60e2                	ld	ra,24(sp)
    800065a6:	6442                	ld	s0,16(sp)
    800065a8:	6105                	addi	sp,sp,32
    800065aa:	8082                	ret
    800065ac:	0000                	unimp
	...

00000000800065b0 <kernelvec>:
    800065b0:	7111                	addi	sp,sp,-256
    800065b2:	e006                	sd	ra,0(sp)
    800065b4:	e40a                	sd	sp,8(sp)
    800065b6:	e80e                	sd	gp,16(sp)
    800065b8:	ec12                	sd	tp,24(sp)
    800065ba:	f016                	sd	t0,32(sp)
    800065bc:	f41a                	sd	t1,40(sp)
    800065be:	f81e                	sd	t2,48(sp)
    800065c0:	fc22                	sd	s0,56(sp)
    800065c2:	e0a6                	sd	s1,64(sp)
    800065c4:	e4aa                	sd	a0,72(sp)
    800065c6:	e8ae                	sd	a1,80(sp)
    800065c8:	ecb2                	sd	a2,88(sp)
    800065ca:	f0b6                	sd	a3,96(sp)
    800065cc:	f4ba                	sd	a4,104(sp)
    800065ce:	f8be                	sd	a5,112(sp)
    800065d0:	fcc2                	sd	a6,120(sp)
    800065d2:	e146                	sd	a7,128(sp)
    800065d4:	e54a                	sd	s2,136(sp)
    800065d6:	e94e                	sd	s3,144(sp)
    800065d8:	ed52                	sd	s4,152(sp)
    800065da:	f156                	sd	s5,160(sp)
    800065dc:	f55a                	sd	s6,168(sp)
    800065de:	f95e                	sd	s7,176(sp)
    800065e0:	fd62                	sd	s8,184(sp)
    800065e2:	e1e6                	sd	s9,192(sp)
    800065e4:	e5ea                	sd	s10,200(sp)
    800065e6:	e9ee                	sd	s11,208(sp)
    800065e8:	edf2                	sd	t3,216(sp)
    800065ea:	f1f6                	sd	t4,224(sp)
    800065ec:	f5fa                	sd	t5,232(sp)
    800065ee:	f9fe                	sd	t6,240(sp)
    800065f0:	a7dfc0ef          	jal	ra,8000306c <kerneltrap>
    800065f4:	6082                	ld	ra,0(sp)
    800065f6:	6122                	ld	sp,8(sp)
    800065f8:	61c2                	ld	gp,16(sp)
    800065fa:	7282                	ld	t0,32(sp)
    800065fc:	7322                	ld	t1,40(sp)
    800065fe:	73c2                	ld	t2,48(sp)
    80006600:	7462                	ld	s0,56(sp)
    80006602:	6486                	ld	s1,64(sp)
    80006604:	6526                	ld	a0,72(sp)
    80006606:	65c6                	ld	a1,80(sp)
    80006608:	6666                	ld	a2,88(sp)
    8000660a:	7686                	ld	a3,96(sp)
    8000660c:	7726                	ld	a4,104(sp)
    8000660e:	77c6                	ld	a5,112(sp)
    80006610:	7866                	ld	a6,120(sp)
    80006612:	688a                	ld	a7,128(sp)
    80006614:	692a                	ld	s2,136(sp)
    80006616:	69ca                	ld	s3,144(sp)
    80006618:	6a6a                	ld	s4,152(sp)
    8000661a:	7a8a                	ld	s5,160(sp)
    8000661c:	7b2a                	ld	s6,168(sp)
    8000661e:	7bca                	ld	s7,176(sp)
    80006620:	7c6a                	ld	s8,184(sp)
    80006622:	6c8e                	ld	s9,192(sp)
    80006624:	6d2e                	ld	s10,200(sp)
    80006626:	6dce                	ld	s11,208(sp)
    80006628:	6e6e                	ld	t3,216(sp)
    8000662a:	7e8e                	ld	t4,224(sp)
    8000662c:	7f2e                	ld	t5,232(sp)
    8000662e:	7fce                	ld	t6,240(sp)
    80006630:	6111                	addi	sp,sp,256
    80006632:	10200073          	sret
    80006636:	00000013          	nop
    8000663a:	00000013          	nop
    8000663e:	0001                	nop

0000000080006640 <timervec>:
    80006640:	34051573          	csrrw	a0,mscratch,a0
    80006644:	e10c                	sd	a1,0(a0)
    80006646:	e510                	sd	a2,8(a0)
    80006648:	e914                	sd	a3,16(a0)
    8000664a:	6d0c                	ld	a1,24(a0)
    8000664c:	7110                	ld	a2,32(a0)
    8000664e:	6194                	ld	a3,0(a1)
    80006650:	96b2                	add	a3,a3,a2
    80006652:	e194                	sd	a3,0(a1)
    80006654:	4589                	li	a1,2
    80006656:	14459073          	csrw	sip,a1
    8000665a:	6914                	ld	a3,16(a0)
    8000665c:	6510                	ld	a2,8(a0)
    8000665e:	610c                	ld	a1,0(a0)
    80006660:	34051573          	csrrw	a0,mscratch,a0
    80006664:	30200073          	mret
	...

000000008000666a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000666a:	1141                	addi	sp,sp,-16
    8000666c:	e422                	sd	s0,8(sp)
    8000666e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006670:	0c0007b7          	lui	a5,0xc000
    80006674:	4705                	li	a4,1
    80006676:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006678:	c3d8                	sw	a4,4(a5)
}
    8000667a:	6422                	ld	s0,8(sp)
    8000667c:	0141                	addi	sp,sp,16
    8000667e:	8082                	ret

0000000080006680 <plicinithart>:

void
plicinithart(void)
{
    80006680:	1141                	addi	sp,sp,-16
    80006682:	e406                	sd	ra,8(sp)
    80006684:	e022                	sd	s0,0(sp)
    80006686:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006688:	ffffb097          	auipc	ra,0xffffb
    8000668c:	438080e7          	jalr	1080(ra) # 80001ac0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006690:	0085171b          	slliw	a4,a0,0x8
    80006694:	0c0027b7          	lui	a5,0xc002
    80006698:	97ba                	add	a5,a5,a4
    8000669a:	40200713          	li	a4,1026
    8000669e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066a2:	00d5151b          	slliw	a0,a0,0xd
    800066a6:	0c2017b7          	lui	a5,0xc201
    800066aa:	97aa                	add	a5,a5,a0
    800066ac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800066b0:	60a2                	ld	ra,8(sp)
    800066b2:	6402                	ld	s0,0(sp)
    800066b4:	0141                	addi	sp,sp,16
    800066b6:	8082                	ret

00000000800066b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800066b8:	1141                	addi	sp,sp,-16
    800066ba:	e406                	sd	ra,8(sp)
    800066bc:	e022                	sd	s0,0(sp)
    800066be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066c0:	ffffb097          	auipc	ra,0xffffb
    800066c4:	400080e7          	jalr	1024(ra) # 80001ac0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800066c8:	00d5151b          	slliw	a0,a0,0xd
    800066cc:	0c2017b7          	lui	a5,0xc201
    800066d0:	97aa                	add	a5,a5,a0
  return irq;
}
    800066d2:	43c8                	lw	a0,4(a5)
    800066d4:	60a2                	ld	ra,8(sp)
    800066d6:	6402                	ld	s0,0(sp)
    800066d8:	0141                	addi	sp,sp,16
    800066da:	8082                	ret

00000000800066dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800066dc:	1101                	addi	sp,sp,-32
    800066de:	ec06                	sd	ra,24(sp)
    800066e0:	e822                	sd	s0,16(sp)
    800066e2:	e426                	sd	s1,8(sp)
    800066e4:	1000                	addi	s0,sp,32
    800066e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800066e8:	ffffb097          	auipc	ra,0xffffb
    800066ec:	3d8080e7          	jalr	984(ra) # 80001ac0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800066f0:	00d5151b          	slliw	a0,a0,0xd
    800066f4:	0c2017b7          	lui	a5,0xc201
    800066f8:	97aa                	add	a5,a5,a0
    800066fa:	c3c4                	sw	s1,4(a5)
}
    800066fc:	60e2                	ld	ra,24(sp)
    800066fe:	6442                	ld	s0,16(sp)
    80006700:	64a2                	ld	s1,8(sp)
    80006702:	6105                	addi	sp,sp,32
    80006704:	8082                	ret

0000000080006706 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006706:	1141                	addi	sp,sp,-16
    80006708:	e406                	sd	ra,8(sp)
    8000670a:	e022                	sd	s0,0(sp)
    8000670c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000670e:	479d                	li	a5,7
    80006710:	06a7c863          	blt	a5,a0,80006780 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006714:	0002d717          	auipc	a4,0x2d
    80006718:	8ec70713          	addi	a4,a4,-1812 # 80033000 <disk>
    8000671c:	972a                	add	a4,a4,a0
    8000671e:	6789                	lui	a5,0x2
    80006720:	97ba                	add	a5,a5,a4
    80006722:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006726:	e7ad                	bnez	a5,80006790 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006728:	00451793          	slli	a5,a0,0x4
    8000672c:	0002f717          	auipc	a4,0x2f
    80006730:	8d470713          	addi	a4,a4,-1836 # 80035000 <disk+0x2000>
    80006734:	6314                	ld	a3,0(a4)
    80006736:	96be                	add	a3,a3,a5
    80006738:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000673c:	6314                	ld	a3,0(a4)
    8000673e:	96be                	add	a3,a3,a5
    80006740:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006744:	6314                	ld	a3,0(a4)
    80006746:	96be                	add	a3,a3,a5
    80006748:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000674c:	6318                	ld	a4,0(a4)
    8000674e:	97ba                	add	a5,a5,a4
    80006750:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006754:	0002d717          	auipc	a4,0x2d
    80006758:	8ac70713          	addi	a4,a4,-1876 # 80033000 <disk>
    8000675c:	972a                	add	a4,a4,a0
    8000675e:	6789                	lui	a5,0x2
    80006760:	97ba                	add	a5,a5,a4
    80006762:	4705                	li	a4,1
    80006764:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006768:	0002f517          	auipc	a0,0x2f
    8000676c:	8b050513          	addi	a0,a0,-1872 # 80035018 <disk+0x2018>
    80006770:	ffffb097          	auipc	ra,0xffffb
    80006774:	7ec080e7          	jalr	2028(ra) # 80001f5c <wakeup>
}
    80006778:	60a2                	ld	ra,8(sp)
    8000677a:	6402                	ld	s0,0(sp)
    8000677c:	0141                	addi	sp,sp,16
    8000677e:	8082                	ret
    panic("free_desc 1");
    80006780:	00002517          	auipc	a0,0x2
    80006784:	02050513          	addi	a0,a0,32 # 800087a0 <syscalls+0x340>
    80006788:	ffffa097          	auipc	ra,0xffffa
    8000678c:	db4080e7          	jalr	-588(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006790:	00002517          	auipc	a0,0x2
    80006794:	02050513          	addi	a0,a0,32 # 800087b0 <syscalls+0x350>
    80006798:	ffffa097          	auipc	ra,0xffffa
    8000679c:	da4080e7          	jalr	-604(ra) # 8000053c <panic>

00000000800067a0 <virtio_disk_init>:
{
    800067a0:	1101                	addi	sp,sp,-32
    800067a2:	ec06                	sd	ra,24(sp)
    800067a4:	e822                	sd	s0,16(sp)
    800067a6:	e426                	sd	s1,8(sp)
    800067a8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800067aa:	00002597          	auipc	a1,0x2
    800067ae:	01658593          	addi	a1,a1,22 # 800087c0 <syscalls+0x360>
    800067b2:	0002f517          	auipc	a0,0x2f
    800067b6:	97650513          	addi	a0,a0,-1674 # 80035128 <disk+0x2128>
    800067ba:	ffffa097          	auipc	ra,0xffffa
    800067be:	3d2080e7          	jalr	978(ra) # 80000b8c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067c2:	100017b7          	lui	a5,0x10001
    800067c6:	4398                	lw	a4,0(a5)
    800067c8:	2701                	sext.w	a4,a4
    800067ca:	747277b7          	lui	a5,0x74727
    800067ce:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067d2:	0ef71063          	bne	a4,a5,800068b2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800067d6:	100017b7          	lui	a5,0x10001
    800067da:	43dc                	lw	a5,4(a5)
    800067dc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067de:	4705                	li	a4,1
    800067e0:	0ce79963          	bne	a5,a4,800068b2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067e4:	100017b7          	lui	a5,0x10001
    800067e8:	479c                	lw	a5,8(a5)
    800067ea:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800067ec:	4709                	li	a4,2
    800067ee:	0ce79263          	bne	a5,a4,800068b2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800067f2:	100017b7          	lui	a5,0x10001
    800067f6:	47d8                	lw	a4,12(a5)
    800067f8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067fa:	554d47b7          	lui	a5,0x554d4
    800067fe:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006802:	0af71863          	bne	a4,a5,800068b2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006806:	100017b7          	lui	a5,0x10001
    8000680a:	4705                	li	a4,1
    8000680c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000680e:	470d                	li	a4,3
    80006810:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006812:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006814:	c7ffe6b7          	lui	a3,0xc7ffe
    80006818:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fc875f>
    8000681c:	8f75                	and	a4,a4,a3
    8000681e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006820:	472d                	li	a4,11
    80006822:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006824:	473d                	li	a4,15
    80006826:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006828:	6705                	lui	a4,0x1
    8000682a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000682c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006830:	5bdc                	lw	a5,52(a5)
    80006832:	2781                	sext.w	a5,a5
  if(max == 0)
    80006834:	c7d9                	beqz	a5,800068c2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006836:	471d                	li	a4,7
    80006838:	08f77d63          	bgeu	a4,a5,800068d2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000683c:	100014b7          	lui	s1,0x10001
    80006840:	47a1                	li	a5,8
    80006842:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006844:	6609                	lui	a2,0x2
    80006846:	4581                	li	a1,0
    80006848:	0002c517          	auipc	a0,0x2c
    8000684c:	7b850513          	addi	a0,a0,1976 # 80033000 <disk>
    80006850:	ffffa097          	auipc	ra,0xffffa
    80006854:	4c8080e7          	jalr	1224(ra) # 80000d18 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006858:	0002c717          	auipc	a4,0x2c
    8000685c:	7a870713          	addi	a4,a4,1960 # 80033000 <disk>
    80006860:	00c75793          	srli	a5,a4,0xc
    80006864:	2781                	sext.w	a5,a5
    80006866:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006868:	0002e797          	auipc	a5,0x2e
    8000686c:	79878793          	addi	a5,a5,1944 # 80035000 <disk+0x2000>
    80006870:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006872:	0002d717          	auipc	a4,0x2d
    80006876:	80e70713          	addi	a4,a4,-2034 # 80033080 <disk+0x80>
    8000687a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000687c:	0002d717          	auipc	a4,0x2d
    80006880:	78470713          	addi	a4,a4,1924 # 80034000 <disk+0x1000>
    80006884:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006886:	4705                	li	a4,1
    80006888:	00e78c23          	sb	a4,24(a5)
    8000688c:	00e78ca3          	sb	a4,25(a5)
    80006890:	00e78d23          	sb	a4,26(a5)
    80006894:	00e78da3          	sb	a4,27(a5)
    80006898:	00e78e23          	sb	a4,28(a5)
    8000689c:	00e78ea3          	sb	a4,29(a5)
    800068a0:	00e78f23          	sb	a4,30(a5)
    800068a4:	00e78fa3          	sb	a4,31(a5)
}
    800068a8:	60e2                	ld	ra,24(sp)
    800068aa:	6442                	ld	s0,16(sp)
    800068ac:	64a2                	ld	s1,8(sp)
    800068ae:	6105                	addi	sp,sp,32
    800068b0:	8082                	ret
    panic("could not find virtio disk");
    800068b2:	00002517          	auipc	a0,0x2
    800068b6:	f1e50513          	addi	a0,a0,-226 # 800087d0 <syscalls+0x370>
    800068ba:	ffffa097          	auipc	ra,0xffffa
    800068be:	c82080e7          	jalr	-894(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800068c2:	00002517          	auipc	a0,0x2
    800068c6:	f2e50513          	addi	a0,a0,-210 # 800087f0 <syscalls+0x390>
    800068ca:	ffffa097          	auipc	ra,0xffffa
    800068ce:	c72080e7          	jalr	-910(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800068d2:	00002517          	auipc	a0,0x2
    800068d6:	f3e50513          	addi	a0,a0,-194 # 80008810 <syscalls+0x3b0>
    800068da:	ffffa097          	auipc	ra,0xffffa
    800068de:	c62080e7          	jalr	-926(ra) # 8000053c <panic>

00000000800068e2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800068e2:	7119                	addi	sp,sp,-128
    800068e4:	fc86                	sd	ra,120(sp)
    800068e6:	f8a2                	sd	s0,112(sp)
    800068e8:	f4a6                	sd	s1,104(sp)
    800068ea:	f0ca                	sd	s2,96(sp)
    800068ec:	ecce                	sd	s3,88(sp)
    800068ee:	e8d2                	sd	s4,80(sp)
    800068f0:	e4d6                	sd	s5,72(sp)
    800068f2:	e0da                	sd	s6,64(sp)
    800068f4:	fc5e                	sd	s7,56(sp)
    800068f6:	f862                	sd	s8,48(sp)
    800068f8:	f466                	sd	s9,40(sp)
    800068fa:	f06a                	sd	s10,32(sp)
    800068fc:	ec6e                	sd	s11,24(sp)
    800068fe:	0100                	addi	s0,sp,128
    80006900:	8aaa                	mv	s5,a0
    80006902:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006904:	00c52c83          	lw	s9,12(a0)
    80006908:	001c9c9b          	slliw	s9,s9,0x1
    8000690c:	1c82                	slli	s9,s9,0x20
    8000690e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006912:	0002f517          	auipc	a0,0x2f
    80006916:	81650513          	addi	a0,a0,-2026 # 80035128 <disk+0x2128>
    8000691a:	ffffa097          	auipc	ra,0xffffa
    8000691e:	302080e7          	jalr	770(ra) # 80000c1c <acquire>
  for(int i = 0; i < 3; i++){
    80006922:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006924:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006926:	0002cc17          	auipc	s8,0x2c
    8000692a:	6dac0c13          	addi	s8,s8,1754 # 80033000 <disk>
    8000692e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006930:	4b0d                	li	s6,3
    80006932:	a0ad                	j	8000699c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006934:	00fc0733          	add	a4,s8,a5
    80006938:	975e                	add	a4,a4,s7
    8000693a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000693e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006940:	0207c563          	bltz	a5,8000696a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006944:	2905                	addiw	s2,s2,1
    80006946:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006948:	19690c63          	beq	s2,s6,80006ae0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000694c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000694e:	0002e717          	auipc	a4,0x2e
    80006952:	6ca70713          	addi	a4,a4,1738 # 80035018 <disk+0x2018>
    80006956:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006958:	00074683          	lbu	a3,0(a4)
    8000695c:	fee1                	bnez	a3,80006934 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000695e:	2785                	addiw	a5,a5,1
    80006960:	0705                	addi	a4,a4,1
    80006962:	fe979be3          	bne	a5,s1,80006958 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006966:	57fd                	li	a5,-1
    80006968:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000696a:	01205d63          	blez	s2,80006984 <virtio_disk_rw+0xa2>
    8000696e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006970:	000a2503          	lw	a0,0(s4)
    80006974:	00000097          	auipc	ra,0x0
    80006978:	d92080e7          	jalr	-622(ra) # 80006706 <free_desc>
      for(int j = 0; j < i; j++)
    8000697c:	2d85                	addiw	s11,s11,1
    8000697e:	0a11                	addi	s4,s4,4
    80006980:	ff2d98e3          	bne	s11,s2,80006970 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006984:	0002e597          	auipc	a1,0x2e
    80006988:	7a458593          	addi	a1,a1,1956 # 80035128 <disk+0x2128>
    8000698c:	0002e517          	auipc	a0,0x2e
    80006990:	68c50513          	addi	a0,a0,1676 # 80035018 <disk+0x2018>
    80006994:	ffffb097          	auipc	ra,0xffffb
    80006998:	558080e7          	jalr	1368(ra) # 80001eec <sleep>
  for(int i = 0; i < 3; i++){
    8000699c:	f8040a13          	addi	s4,s0,-128
{
    800069a0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800069a2:	894e                	mv	s2,s3
    800069a4:	b765                	j	8000694c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800069a6:	0002e697          	auipc	a3,0x2e
    800069aa:	65a6b683          	ld	a3,1626(a3) # 80035000 <disk+0x2000>
    800069ae:	96ba                	add	a3,a3,a4
    800069b0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800069b4:	0002c817          	auipc	a6,0x2c
    800069b8:	64c80813          	addi	a6,a6,1612 # 80033000 <disk>
    800069bc:	0002e697          	auipc	a3,0x2e
    800069c0:	64468693          	addi	a3,a3,1604 # 80035000 <disk+0x2000>
    800069c4:	6290                	ld	a2,0(a3)
    800069c6:	963a                	add	a2,a2,a4
    800069c8:	00c65583          	lhu	a1,12(a2)
    800069cc:	0015e593          	ori	a1,a1,1
    800069d0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800069d4:	f8842603          	lw	a2,-120(s0)
    800069d8:	628c                	ld	a1,0(a3)
    800069da:	972e                	add	a4,a4,a1
    800069dc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069e0:	20050593          	addi	a1,a0,512
    800069e4:	0592                	slli	a1,a1,0x4
    800069e6:	95c2                	add	a1,a1,a6
    800069e8:	577d                	li	a4,-1
    800069ea:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069ee:	00461713          	slli	a4,a2,0x4
    800069f2:	6290                	ld	a2,0(a3)
    800069f4:	963a                	add	a2,a2,a4
    800069f6:	03078793          	addi	a5,a5,48
    800069fa:	97c2                	add	a5,a5,a6
    800069fc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800069fe:	629c                	ld	a5,0(a3)
    80006a00:	97ba                	add	a5,a5,a4
    80006a02:	4605                	li	a2,1
    80006a04:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006a06:	629c                	ld	a5,0(a3)
    80006a08:	97ba                	add	a5,a5,a4
    80006a0a:	4809                	li	a6,2
    80006a0c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006a10:	629c                	ld	a5,0(a3)
    80006a12:	97ba                	add	a5,a5,a4
    80006a14:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006a18:	00caa223          	sw	a2,4(s5) # 1004 <_entry-0x7fffeffc>
  disk.info[idx[0]].b = b;
    80006a1c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006a20:	6698                	ld	a4,8(a3)
    80006a22:	00275783          	lhu	a5,2(a4)
    80006a26:	8b9d                	andi	a5,a5,7
    80006a28:	0786                	slli	a5,a5,0x1
    80006a2a:	973e                	add	a4,a4,a5
    80006a2c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006a30:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a34:	6698                	ld	a4,8(a3)
    80006a36:	00275783          	lhu	a5,2(a4)
    80006a3a:	2785                	addiw	a5,a5,1
    80006a3c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a40:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a44:	100017b7          	lui	a5,0x10001
    80006a48:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a4c:	004aa783          	lw	a5,4(s5)
    80006a50:	02c79163          	bne	a5,a2,80006a72 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006a54:	0002e917          	auipc	s2,0x2e
    80006a58:	6d490913          	addi	s2,s2,1748 # 80035128 <disk+0x2128>
  while(b->disk == 1) {
    80006a5c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a5e:	85ca                	mv	a1,s2
    80006a60:	8556                	mv	a0,s5
    80006a62:	ffffb097          	auipc	ra,0xffffb
    80006a66:	48a080e7          	jalr	1162(ra) # 80001eec <sleep>
  while(b->disk == 1) {
    80006a6a:	004aa783          	lw	a5,4(s5)
    80006a6e:	fe9788e3          	beq	a5,s1,80006a5e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006a72:	f8042903          	lw	s2,-128(s0)
    80006a76:	20090713          	addi	a4,s2,512
    80006a7a:	0712                	slli	a4,a4,0x4
    80006a7c:	0002c797          	auipc	a5,0x2c
    80006a80:	58478793          	addi	a5,a5,1412 # 80033000 <disk>
    80006a84:	97ba                	add	a5,a5,a4
    80006a86:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006a8a:	0002e997          	auipc	s3,0x2e
    80006a8e:	57698993          	addi	s3,s3,1398 # 80035000 <disk+0x2000>
    80006a92:	00491713          	slli	a4,s2,0x4
    80006a96:	0009b783          	ld	a5,0(s3)
    80006a9a:	97ba                	add	a5,a5,a4
    80006a9c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006aa0:	854a                	mv	a0,s2
    80006aa2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006aa6:	00000097          	auipc	ra,0x0
    80006aaa:	c60080e7          	jalr	-928(ra) # 80006706 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006aae:	8885                	andi	s1,s1,1
    80006ab0:	f0ed                	bnez	s1,80006a92 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006ab2:	0002e517          	auipc	a0,0x2e
    80006ab6:	67650513          	addi	a0,a0,1654 # 80035128 <disk+0x2128>
    80006aba:	ffffa097          	auipc	ra,0xffffa
    80006abe:	216080e7          	jalr	534(ra) # 80000cd0 <release>
}
    80006ac2:	70e6                	ld	ra,120(sp)
    80006ac4:	7446                	ld	s0,112(sp)
    80006ac6:	74a6                	ld	s1,104(sp)
    80006ac8:	7906                	ld	s2,96(sp)
    80006aca:	69e6                	ld	s3,88(sp)
    80006acc:	6a46                	ld	s4,80(sp)
    80006ace:	6aa6                	ld	s5,72(sp)
    80006ad0:	6b06                	ld	s6,64(sp)
    80006ad2:	7be2                	ld	s7,56(sp)
    80006ad4:	7c42                	ld	s8,48(sp)
    80006ad6:	7ca2                	ld	s9,40(sp)
    80006ad8:	7d02                	ld	s10,32(sp)
    80006ada:	6de2                	ld	s11,24(sp)
    80006adc:	6109                	addi	sp,sp,128
    80006ade:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006ae0:	f8042503          	lw	a0,-128(s0)
    80006ae4:	20050793          	addi	a5,a0,512
    80006ae8:	0792                	slli	a5,a5,0x4
  if(write)
    80006aea:	0002c817          	auipc	a6,0x2c
    80006aee:	51680813          	addi	a6,a6,1302 # 80033000 <disk>
    80006af2:	00f80733          	add	a4,a6,a5
    80006af6:	01a036b3          	snez	a3,s10
    80006afa:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006afe:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006b02:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b06:	7679                	lui	a2,0xffffe
    80006b08:	963e                	add	a2,a2,a5
    80006b0a:	0002e697          	auipc	a3,0x2e
    80006b0e:	4f668693          	addi	a3,a3,1270 # 80035000 <disk+0x2000>
    80006b12:	6298                	ld	a4,0(a3)
    80006b14:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b16:	0a878593          	addi	a1,a5,168
    80006b1a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b1c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006b1e:	6298                	ld	a4,0(a3)
    80006b20:	9732                	add	a4,a4,a2
    80006b22:	45c1                	li	a1,16
    80006b24:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006b26:	6298                	ld	a4,0(a3)
    80006b28:	9732                	add	a4,a4,a2
    80006b2a:	4585                	li	a1,1
    80006b2c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006b30:	f8442703          	lw	a4,-124(s0)
    80006b34:	628c                	ld	a1,0(a3)
    80006b36:	962e                	add	a2,a2,a1
    80006b38:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffc800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006b3c:	0712                	slli	a4,a4,0x4
    80006b3e:	6290                	ld	a2,0(a3)
    80006b40:	963a                	add	a2,a2,a4
    80006b42:	058a8593          	addi	a1,s5,88
    80006b46:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006b48:	6294                	ld	a3,0(a3)
    80006b4a:	96ba                	add	a3,a3,a4
    80006b4c:	40000613          	li	a2,1024
    80006b50:	c690                	sw	a2,8(a3)
  if(write)
    80006b52:	e40d1ae3          	bnez	s10,800069a6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006b56:	0002e697          	auipc	a3,0x2e
    80006b5a:	4aa6b683          	ld	a3,1194(a3) # 80035000 <disk+0x2000>
    80006b5e:	96ba                	add	a3,a3,a4
    80006b60:	4609                	li	a2,2
    80006b62:	00c69623          	sh	a2,12(a3)
    80006b66:	b5b9                	j	800069b4 <virtio_disk_rw+0xd2>

0000000080006b68 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006b68:	1101                	addi	sp,sp,-32
    80006b6a:	ec06                	sd	ra,24(sp)
    80006b6c:	e822                	sd	s0,16(sp)
    80006b6e:	e426                	sd	s1,8(sp)
    80006b70:	e04a                	sd	s2,0(sp)
    80006b72:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006b74:	0002e517          	auipc	a0,0x2e
    80006b78:	5b450513          	addi	a0,a0,1460 # 80035128 <disk+0x2128>
    80006b7c:	ffffa097          	auipc	ra,0xffffa
    80006b80:	0a0080e7          	jalr	160(ra) # 80000c1c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006b84:	10001737          	lui	a4,0x10001
    80006b88:	533c                	lw	a5,96(a4)
    80006b8a:	8b8d                	andi	a5,a5,3
    80006b8c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006b8e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b92:	0002e797          	auipc	a5,0x2e
    80006b96:	46e78793          	addi	a5,a5,1134 # 80035000 <disk+0x2000>
    80006b9a:	6b94                	ld	a3,16(a5)
    80006b9c:	0207d703          	lhu	a4,32(a5)
    80006ba0:	0026d783          	lhu	a5,2(a3)
    80006ba4:	06f70163          	beq	a4,a5,80006c06 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ba8:	0002c917          	auipc	s2,0x2c
    80006bac:	45890913          	addi	s2,s2,1112 # 80033000 <disk>
    80006bb0:	0002e497          	auipc	s1,0x2e
    80006bb4:	45048493          	addi	s1,s1,1104 # 80035000 <disk+0x2000>
    __sync_synchronize();
    80006bb8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006bbc:	6898                	ld	a4,16(s1)
    80006bbe:	0204d783          	lhu	a5,32(s1)
    80006bc2:	8b9d                	andi	a5,a5,7
    80006bc4:	078e                	slli	a5,a5,0x3
    80006bc6:	97ba                	add	a5,a5,a4
    80006bc8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006bca:	20078713          	addi	a4,a5,512
    80006bce:	0712                	slli	a4,a4,0x4
    80006bd0:	974a                	add	a4,a4,s2
    80006bd2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006bd6:	e731                	bnez	a4,80006c22 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006bd8:	20078793          	addi	a5,a5,512
    80006bdc:	0792                	slli	a5,a5,0x4
    80006bde:	97ca                	add	a5,a5,s2
    80006be0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006be2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006be6:	ffffb097          	auipc	ra,0xffffb
    80006bea:	376080e7          	jalr	886(ra) # 80001f5c <wakeup>

    disk.used_idx += 1;
    80006bee:	0204d783          	lhu	a5,32(s1)
    80006bf2:	2785                	addiw	a5,a5,1
    80006bf4:	17c2                	slli	a5,a5,0x30
    80006bf6:	93c1                	srli	a5,a5,0x30
    80006bf8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006bfc:	6898                	ld	a4,16(s1)
    80006bfe:	00275703          	lhu	a4,2(a4)
    80006c02:	faf71be3          	bne	a4,a5,80006bb8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006c06:	0002e517          	auipc	a0,0x2e
    80006c0a:	52250513          	addi	a0,a0,1314 # 80035128 <disk+0x2128>
    80006c0e:	ffffa097          	auipc	ra,0xffffa
    80006c12:	0c2080e7          	jalr	194(ra) # 80000cd0 <release>
}
    80006c16:	60e2                	ld	ra,24(sp)
    80006c18:	6442                	ld	s0,16(sp)
    80006c1a:	64a2                	ld	s1,8(sp)
    80006c1c:	6902                	ld	s2,0(sp)
    80006c1e:	6105                	addi	sp,sp,32
    80006c20:	8082                	ret
      panic("virtio_disk_intr status");
    80006c22:	00002517          	auipc	a0,0x2
    80006c26:	c0e50513          	addi	a0,a0,-1010 # 80008830 <syscalls+0x3d0>
    80006c2a:	ffffa097          	auipc	ra,0xffffa
    80006c2e:	912080e7          	jalr	-1774(ra) # 8000053c <panic>
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
