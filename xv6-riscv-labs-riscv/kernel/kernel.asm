
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	2ce78793          	addi	a5,a5,718 # 80006330 <timervec>
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
    8000012e:	478080e7          	jalr	1144(ra) # 800025a2 <either_copyin>
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
    800001c4:	87e080e7          	jalr	-1922(ra) # 80001a3e <myproc>
    800001c8:	30052783          	lw	a5,768(a0)
    800001cc:	e7b5                	bnez	a5,80000238 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	f9a080e7          	jalr	-102(ra) # 8000216c <sleep>
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
    80000212:	33c080e7          	jalr	828(ra) # 8000254a <either_copyout>
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
    800002f2:	30c080e7          	jalr	780(ra) # 800025fa <procdump>
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
    80000446:	ece080e7          	jalr	-306(ra) # 80002310 <wakeup>
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
    80000894:	a80080e7          	jalr	-1408(ra) # 80002310 <wakeup>
    
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
    80000920:	850080e7          	jalr	-1968(ra) # 8000216c <sleep>
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
    80000bba:	e6c080e7          	jalr	-404(ra) # 80001a22 <mycpu>
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
    80000bec:	e3a080e7          	jalr	-454(ra) # 80001a22 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	cf89                	beqz	a5,80000c0c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e2e080e7          	jalr	-466(ra) # 80001a22 <mycpu>
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
    80000c10:	e16080e7          	jalr	-490(ra) # 80001a22 <mycpu>
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
    80000c50:	dd6080e7          	jalr	-554(ra) # 80001a22 <mycpu>
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
    80000c7c:	daa080e7          	jalr	-598(ra) # 80001a22 <mycpu>
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
    80000eca:	b4c080e7          	jalr	-1204(ra) # 80001a12 <cpuid>
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
    80000ee6:	b30080e7          	jalr	-1232(ra) # 80001a12 <cpuid>
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
    80000f08:	a80080e7          	jalr	-1408(ra) # 80002984 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	464080e7          	jalr	1124(ra) # 80006370 <plicinithart>
  }

  scheduler();  
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	08c080e7          	jalr	140(ra) # 80001fa0 <scheduler>
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
    80000f78:	9ea080e7          	jalr	-1558(ra) # 8000195e <procinit>
    trapinit();      // trap vectors
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	9e0080e7          	jalr	-1568(ra) # 8000295c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	a00080e7          	jalr	-1536(ra) # 80002984 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	3ce080e7          	jalr	974(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	3dc080e7          	jalr	988(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	2dc080e7          	jalr	732(ra) # 80003278 <binit>
    iinit();         // inode table
    80000fa4:	00003097          	auipc	ra,0x3
    80000fa8:	96a080e7          	jalr	-1686(ra) # 8000390e <iinit>
    fileinit();      // file table
    80000fac:	00004097          	auipc	ra,0x4
    80000fb0:	920080e7          	jalr	-1760(ra) # 800048cc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	4dc080e7          	jalr	1244(ra) # 80006490 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	d7c080e7          	jalr	-644(ra) # 80001d38 <userinit>
    mmrlistinit();   //  HW5 - Task 1a
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	7a6080e7          	jalr	1958(ra) # 8000276a <mmrlistinit>
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
    8000127c:	650080e7          	jalr	1616(ra) # 800018c8 <proc_mapstacks>
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
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	c269                	beqz	a2,8000164e <uvmcopy+0xc2>
{
    8000158e:	715d                	addi	sp,sp,-80
    80001590:	e486                	sd	ra,72(sp)
    80001592:	e0a2                	sd	s0,64(sp)
    80001594:	fc26                	sd	s1,56(sp)
    80001596:	f84a                	sd	s2,48(sp)
    80001598:	f44e                	sd	s3,40(sp)
    8000159a:	f052                	sd	s4,32(sp)
    8000159c:	ec56                	sd	s5,24(sp)
    8000159e:	e85a                	sd	s6,16(sp)
    800015a0:	e45e                	sd	s7,8(sp)
    800015a2:	0880                	addi	s0,sp,80
    800015a4:	8aaa                	mv	s5,a0
    800015a6:	8b2e                	mv	s6,a1
    800015a8:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	4481                	li	s1,0
    800015ac:	a829                	j	800015c6 <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015ae:	00007517          	auipc	a0,0x7
    800015b2:	bb250513          	addi	a0,a0,-1102 # 80008160 <digits+0x120>
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	f86080e7          	jalr	-122(ra) # 8000053c <panic>
  for(i = 0; i < sz; i += PGSIZE){
    800015be:	6785                	lui	a5,0x1
    800015c0:	94be                	add	s1,s1,a5
    800015c2:	0944f463          	bgeu	s1,s4,8000164a <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800015c6:	4601                	li	a2,0
    800015c8:	85a6                	mv	a1,s1
    800015ca:	8556                	mv	a0,s5
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	a34080e7          	jalr	-1484(ra) # 80001000 <walk>
    800015d4:	dd69                	beqz	a0,800015ae <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    800015d6:	6118                	ld	a4,0(a0)
    800015d8:	00177793          	andi	a5,a4,1
    800015dc:	d3ed                	beqz	a5,800015be <uvmcopy+0x32>
      // panic("uvmcopy: page not present"); -- HW 4 - TASK 4
      continue;
    pa = PTE2PA(*pte);
    800015de:	00a75593          	srli	a1,a4,0xa
    800015e2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e6:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	4f8080e7          	jalr	1272(ra) # 80000ae2 <kalloc>
    800015f2:	89aa                	mv	s3,a0
    800015f4:	c515                	beqz	a0,80001620 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f6:	6605                	lui	a2,0x1
    800015f8:	85de                	mv	a1,s7
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	77a080e7          	jalr	1914(ra) # 80000d74 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001602:	874a                	mv	a4,s2
    80001604:	86ce                	mv	a3,s3
    80001606:	6605                	lui	a2,0x1
    80001608:	85a6                	mv	a1,s1
    8000160a:	855a                	mv	a0,s6
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	adc080e7          	jalr	-1316(ra) # 800010e8 <mappages>
    80001614:	d54d                	beqz	a0,800015be <uvmcopy+0x32>
      kfree(mem);
    80001616:	854e                	mv	a0,s3
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	3cc080e7          	jalr	972(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001620:	4685                	li	a3,1
    80001622:	00c4d613          	srli	a2,s1,0xc
    80001626:	4581                	li	a1,0
    80001628:	855a                	mv	a0,s6
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	c84080e7          	jalr	-892(ra) # 800012ae <uvmunmap>
  return -1;
    80001632:	557d                	li	a0,-1
}
    80001634:	60a6                	ld	ra,72(sp)
    80001636:	6406                	ld	s0,64(sp)
    80001638:	74e2                	ld	s1,56(sp)
    8000163a:	7942                	ld	s2,48(sp)
    8000163c:	79a2                	ld	s3,40(sp)
    8000163e:	7a02                	ld	s4,32(sp)
    80001640:	6ae2                	ld	s5,24(sp)
    80001642:	6b42                	ld	s6,16(sp)
    80001644:	6ba2                	ld	s7,8(sp)
    80001646:	6161                	addi	sp,sp,80
    80001648:	8082                	ret
  return 0;
    8000164a:	4501                	li	a0,0
    8000164c:	b7e5                	j	80001634 <uvmcopy+0xa8>
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	9a4080e7          	jalr	-1628(ra) # 80001000 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b0c50513          	addi	a0,a0,-1268 # 80008180 <digits+0x140>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec0080e7          	jalr	-320(ra) # 8000053c <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	6bc080e7          	jalr	1724(ra) # 80000d74 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9d0080e7          	jalr	-1584(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	caa5                	beqz	a3,80001780 <copyin+0x70>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a01d                	j	8000175c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	018505b3          	add	a1,a0,s8
    8000173c:	0004861b          	sext.w	a2,s1
    80001740:	412585b3          	sub	a1,a1,s2
    80001744:	8552                	mv	a0,s4
    80001746:	fffff097          	auipc	ra,0xfffff
    8000174a:	62e080e7          	jalr	1582(ra) # 80000d74 <memmove>

    len -= n;
    8000174e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001752:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001754:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001758:	02098263          	beqz	s3,8000177c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000175c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001760:	85ca                	mv	a1,s2
    80001762:	855a                	mv	a0,s6
    80001764:	00000097          	auipc	ra,0x0
    80001768:	942080e7          	jalr	-1726(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000176c:	cd01                	beqz	a0,80001784 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000176e:	418904b3          	sub	s1,s2,s8
    80001772:	94d6                	add	s1,s1,s5
    80001774:	fc99f2e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001778:	84ce                	mv	s1,s3
    8000177a:	bf7d                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177c:	4501                	li	a0,0
    8000177e:	a021                	j	80001786 <copyin+0x76>
    80001780:	4501                	li	a0,0
}
    80001782:	8082                	ret
      return -1;
    80001784:	557d                	li	a0,-1
}
    80001786:	60a6                	ld	ra,72(sp)
    80001788:	6406                	ld	s0,64(sp)
    8000178a:	74e2                	ld	s1,56(sp)
    8000178c:	7942                	ld	s2,48(sp)
    8000178e:	79a2                	ld	s3,40(sp)
    80001790:	7a02                	ld	s4,32(sp)
    80001792:	6ae2                	ld	s5,24(sp)
    80001794:	6b42                	ld	s6,16(sp)
    80001796:	6ba2                	ld	s7,8(sp)
    80001798:	6c02                	ld	s8,0(sp)
    8000179a:	6161                	addi	sp,sp,80
    8000179c:	8082                	ret

000000008000179e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179e:	c2dd                	beqz	a3,80001844 <copyinstr+0xa6>
{
    800017a0:	715d                	addi	sp,sp,-80
    800017a2:	e486                	sd	ra,72(sp)
    800017a4:	e0a2                	sd	s0,64(sp)
    800017a6:	fc26                	sd	s1,56(sp)
    800017a8:	f84a                	sd	s2,48(sp)
    800017aa:	f44e                	sd	s3,40(sp)
    800017ac:	f052                	sd	s4,32(sp)
    800017ae:	ec56                	sd	s5,24(sp)
    800017b0:	e85a                	sd	s6,16(sp)
    800017b2:	e45e                	sd	s7,8(sp)
    800017b4:	0880                	addi	s0,sp,80
    800017b6:	8a2a                	mv	s4,a0
    800017b8:	8b2e                	mv	s6,a1
    800017ba:	8bb2                	mv	s7,a2
    800017bc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017be:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017c0:	6985                	lui	s3,0x1
    800017c2:	a02d                	j	800017ec <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ca:	37fd                	addiw	a5,a5,-1
    800017cc:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	8b2080e7          	jalr	-1870(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017fe:	417906b3          	sub	a3,s2,s7
    80001802:	96ce                	add	a3,a3,s3
    80001804:	00d4f363          	bgeu	s1,a3,8000180a <copyinstr+0x6c>
    80001808:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	daf9                	beqz	a3,800017e6 <copyinstr+0x48>
    80001812:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001814:	41650633          	sub	a2,a0,s6
    80001818:	fff48593          	addi	a1,s1,-1
    8000181c:	95da                	add	a1,a1,s6
    while(n > 0){
    8000181e:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffc9000>
    80001828:	df51                	beqz	a4,800017c4 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	fed796e3          	bne	a5,a3,80001820 <copyinstr+0x82>
      dst++;
    80001838:	8b3e                	mv	s6,a5
    8000183a:	b775                	j	800017e6 <copyinstr+0x48>
    8000183c:	4781                	li	a5,0
    8000183e:	b771                	j	800017ca <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x32>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	37fd                	addiw	a5,a5,-1
    80001848:	0007851b          	sext.w	a0,a5
}
    8000184c:	8082                	ret

000000008000184e <mapvpages>:
// HW5 - Task 1a
// Allocate page table pages for PTEs if needed but leave valid bits unchanged
int
mapvpages(pagetable_t pagetable, uint64 va, uint64 size)
{
    8000184e:	7179                	addi	sp,sp,-48
    80001850:	f406                	sd	ra,40(sp)
    80001852:	f022                	sd	s0,32(sp)
    80001854:	ec26                	sd	s1,24(sp)
    80001856:	e84a                	sd	s2,16(sp)
    80001858:	e44e                	sd	s3,8(sp)
    8000185a:	e052                	sd	s4,0(sp)
    8000185c:	1800                	addi	s0,sp,48
  uint64 a, last;
  pte_t *pte;
  if(size == 0)
    8000185e:	ca15                	beqz	a2,80001892 <mapvpages+0x44>
    80001860:	89aa                	mv	s3,a0
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001862:	77fd                	lui	a5,0xfffff
    80001864:	00f5f4b3          	and	s1,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001868:	fff58913          	addi	s2,a1,-1
    8000186c:	9932                	add	s2,s2,a2
    8000186e:	00f97933          	and	s2,s2,a5
      return -1;
    if(*pte & PTE_V)
      panic("mappages: remap");
    if(a == last)
      break;
    a += PGSIZE;
    80001872:	6a05                	lui	s4,0x1
    if((pte = walk(pagetable, a, 1)) == 0)
    80001874:	4605                	li	a2,1
    80001876:	85a6                	mv	a1,s1
    80001878:	854e                	mv	a0,s3
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	786080e7          	jalr	1926(ra) # 80001000 <walk>
    80001882:	c905                	beqz	a0,800018b2 <mapvpages+0x64>
    if(*pte & PTE_V)
    80001884:	611c                	ld	a5,0(a0)
    80001886:	8b85                	andi	a5,a5,1
    80001888:	ef89                	bnez	a5,800018a2 <mapvpages+0x54>
    if(a == last)
    8000188a:	03248d63          	beq	s1,s2,800018c4 <mapvpages+0x76>
    a += PGSIZE;
    8000188e:	94d2                	add	s1,s1,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001890:	b7d5                	j	80001874 <mapvpages+0x26>
    panic("mappages: size");
    80001892:	00007517          	auipc	a0,0x7
    80001896:	84650513          	addi	a0,a0,-1978 # 800080d8 <digits+0x98>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	ca2080e7          	jalr	-862(ra) # 8000053c <panic>
      panic("mappages: remap");
    800018a2:	00007517          	auipc	a0,0x7
    800018a6:	84650513          	addi	a0,a0,-1978 # 800080e8 <digits+0xa8>
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	c92080e7          	jalr	-878(ra) # 8000053c <panic>
      return -1;
    800018b2:	557d                	li	a0,-1
  }
  return 0;
    800018b4:	70a2                	ld	ra,40(sp)
    800018b6:	7402                	ld	s0,32(sp)
    800018b8:	64e2                	ld	s1,24(sp)
    800018ba:	6942                	ld	s2,16(sp)
    800018bc:	69a2                	ld	s3,8(sp)
    800018be:	6a02                	ld	s4,0(sp)
    800018c0:	6145                	addi	sp,sp,48
    800018c2:	8082                	ret
  return 0;
    800018c4:	4501                	li	a0,0
    800018c6:	b7fd                	j	800018b4 <mapvpages+0x66>

00000000800018c8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018c8:	7139                	addi	sp,sp,-64
    800018ca:	fc06                	sd	ra,56(sp)
    800018cc:	f822                	sd	s0,48(sp)
    800018ce:	f426                	sd	s1,40(sp)
    800018d0:	f04a                	sd	s2,32(sp)
    800018d2:	ec4e                	sd	s3,24(sp)
    800018d4:	e852                	sd	s4,16(sp)
    800018d6:	e456                	sd	s5,8(sp)
    800018d8:	e05a                	sd	s6,0(sp)
    800018da:	0080                	addi	s0,sp,64
    800018dc:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	00010497          	auipc	s1,0x10
    800018e2:	e0a48493          	addi	s1,s1,-502 # 800116e8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018e6:	8b26                	mv	s6,s1
    800018e8:	00006a97          	auipc	s5,0x6
    800018ec:	718a8a93          	addi	s5,s5,1816 # 80008000 <etext>
    800018f0:	04000937          	lui	s2,0x4000
    800018f4:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018f6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018f8:	00021a17          	auipc	s4,0x21
    800018fc:	df0a0a13          	addi	s4,s4,-528 # 800226e8 <mmr_list>
    char *pa = kalloc();
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	1e2080e7          	jalr	482(ra) # 80000ae2 <kalloc>
    80001908:	862a                	mv	a2,a0
    if(pa == 0)
    8000190a:	c131                	beqz	a0,8000194e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000190c:	416485b3          	sub	a1,s1,s6
    80001910:	8599                	srai	a1,a1,0x6
    80001912:	000ab783          	ld	a5,0(s5)
    80001916:	02f585b3          	mul	a1,a1,a5
    8000191a:	2585                	addiw	a1,a1,1
    8000191c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001920:	4719                	li	a4,6
    80001922:	6685                	lui	a3,0x1
    80001924:	40b905b3          	sub	a1,s2,a1
    80001928:	854e                	mv	a0,s3
    8000192a:	00000097          	auipc	ra,0x0
    8000192e:	85e080e7          	jalr	-1954(ra) # 80001188 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	44048493          	addi	s1,s1,1088
    80001936:	fd4495e3          	bne	s1,s4,80001900 <proc_mapstacks+0x38>
  }
}
    8000193a:	70e2                	ld	ra,56(sp)
    8000193c:	7442                	ld	s0,48(sp)
    8000193e:	74a2                	ld	s1,40(sp)
    80001940:	7902                	ld	s2,32(sp)
    80001942:	69e2                	ld	s3,24(sp)
    80001944:	6a42                	ld	s4,16(sp)
    80001946:	6aa2                	ld	s5,8(sp)
    80001948:	6b02                	ld	s6,0(sp)
    8000194a:	6121                	addi	sp,sp,64
    8000194c:	8082                	ret
      panic("kalloc");
    8000194e:	00007517          	auipc	a0,0x7
    80001952:	84250513          	addi	a0,a0,-1982 # 80008190 <digits+0x150>
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	be6080e7          	jalr	-1050(ra) # 8000053c <panic>

000000008000195e <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    8000195e:	7139                	addi	sp,sp,-64
    80001960:	fc06                	sd	ra,56(sp)
    80001962:	f822                	sd	s0,48(sp)
    80001964:	f426                	sd	s1,40(sp)
    80001966:	f04a                	sd	s2,32(sp)
    80001968:	ec4e                	sd	s3,24(sp)
    8000196a:	e852                	sd	s4,16(sp)
    8000196c:	e456                	sd	s5,8(sp)
    8000196e:	e05a                	sd	s6,0(sp)
    80001970:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001972:	00007597          	auipc	a1,0x7
    80001976:	82658593          	addi	a1,a1,-2010 # 80008198 <digits+0x158>
    8000197a:	00010517          	auipc	a0,0x10
    8000197e:	92650513          	addi	a0,a0,-1754 # 800112a0 <pid_lock>
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	20a080e7          	jalr	522(ra) # 80000b8c <initlock>
  initlock(&wait_lock, "wait_lock");
    8000198a:	00007597          	auipc	a1,0x7
    8000198e:	81658593          	addi	a1,a1,-2026 # 800081a0 <digits+0x160>
    80001992:	00010517          	auipc	a0,0x10
    80001996:	92650513          	addi	a0,a0,-1754 # 800112b8 <wait_lock>
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	1f2080e7          	jalr	498(ra) # 80000b8c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a2:	00010497          	auipc	s1,0x10
    800019a6:	d4648493          	addi	s1,s1,-698 # 800116e8 <proc>
      initlock(&p->lock, "proc");
    800019aa:	00007b17          	auipc	s6,0x7
    800019ae:	806b0b13          	addi	s6,s6,-2042 # 800081b0 <digits+0x170>
      p->kstack = KSTACK((int) (p - proc));
    800019b2:	8aa6                	mv	s5,s1
    800019b4:	00006a17          	auipc	s4,0x6
    800019b8:	64ca0a13          	addi	s4,s4,1612 # 80008000 <etext>
    800019bc:	04000937          	lui	s2,0x4000
    800019c0:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019c2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	00021997          	auipc	s3,0x21
    800019c8:	d2498993          	addi	s3,s3,-732 # 800226e8 <mmr_list>
      initlock(&p->lock, "proc");
    800019cc:	85da                	mv	a1,s6
    800019ce:	2d848513          	addi	a0,s1,728
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	1ba080e7          	jalr	442(ra) # 80000b8c <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019da:	415487b3          	sub	a5,s1,s5
    800019de:	8799                	srai	a5,a5,0x6
    800019e0:	000a3703          	ld	a4,0(s4)
    800019e4:	02e787b3          	mul	a5,a5,a4
    800019e8:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffc9001>
    800019ea:	00d7979b          	slliw	a5,a5,0xd
    800019ee:	40f907b3          	sub	a5,s2,a5
    800019f2:	30f4bc23          	sd	a5,792(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f6:	44048493          	addi	s1,s1,1088
    800019fa:	fd3499e3          	bne	s1,s3,800019cc <procinit+0x6e>
  }
}
    800019fe:	70e2                	ld	ra,56(sp)
    80001a00:	7442                	ld	s0,48(sp)
    80001a02:	74a2                	ld	s1,40(sp)
    80001a04:	7902                	ld	s2,32(sp)
    80001a06:	69e2                	ld	s3,24(sp)
    80001a08:	6a42                	ld	s4,16(sp)
    80001a0a:	6aa2                	ld	s5,8(sp)
    80001a0c:	6b02                	ld	s6,0(sp)
    80001a0e:	6121                	addi	sp,sp,64
    80001a10:	8082                	ret

0000000080001a12 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a12:	1141                	addi	sp,sp,-16
    80001a14:	e422                	sd	s0,8(sp)
    80001a16:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a18:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a1a:	2501                	sext.w	a0,a0
    80001a1c:	6422                	ld	s0,8(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret

0000000080001a22 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a22:	1141                	addi	sp,sp,-16
    80001a24:	e422                	sd	s0,8(sp)
    80001a26:	0800                	addi	s0,sp,16
    80001a28:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a2a:	2781                	sext.w	a5,a5
    80001a2c:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a2e:	00010517          	auipc	a0,0x10
    80001a32:	8a250513          	addi	a0,a0,-1886 # 800112d0 <cpus>
    80001a36:	953e                	add	a0,a0,a5
    80001a38:	6422                	ld	s0,8(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret

0000000080001a3e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	1000                	addi	s0,sp,32
  push_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	188080e7          	jalr	392(ra) # 80000bd0 <push_off>
    80001a50:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a52:	2781                	sext.w	a5,a5
    80001a54:	079e                	slli	a5,a5,0x7
    80001a56:	00010717          	auipc	a4,0x10
    80001a5a:	84a70713          	addi	a4,a4,-1974 # 800112a0 <pid_lock>
    80001a5e:	97ba                	add	a5,a5,a4
    80001a60:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	20e080e7          	jalr	526(ra) # 80000c70 <pop_off>
  return p;
}
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	60e2                	ld	ra,24(sp)
    80001a6e:	6442                	ld	s0,16(sp)
    80001a70:	64a2                	ld	s1,8(sp)
    80001a72:	6105                	addi	sp,sp,32
    80001a74:	8082                	ret

0000000080001a76 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a76:	1141                	addi	sp,sp,-16
    80001a78:	e406                	sd	ra,8(sp)
    80001a7a:	e022                	sd	s0,0(sp)
    80001a7c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	fc0080e7          	jalr	-64(ra) # 80001a3e <myproc>
    80001a86:	2d850513          	addi	a0,a0,728
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	246080e7          	jalr	582(ra) # 80000cd0 <release>

  if (first) {
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	d9e7a783          	lw	a5,-610(a5) # 80008830 <first.1>
    80001a9a:	eb89                	bnez	a5,80001aac <forkret+0x36>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a9c:	00001097          	auipc	ra,0x1
    80001aa0:	f00080e7          	jalr	-256(ra) # 8000299c <usertrapret>
}
    80001aa4:	60a2                	ld	ra,8(sp)
    80001aa6:	6402                	ld	s0,0(sp)
    80001aa8:	0141                	addi	sp,sp,16
    80001aaa:	8082                	ret
    first = 0;
    80001aac:	00007797          	auipc	a5,0x7
    80001ab0:	d807a223          	sw	zero,-636(a5) # 80008830 <first.1>
    fsinit(ROOTDEV);
    80001ab4:	4505                	li	a0,1
    80001ab6:	00002097          	auipc	ra,0x2
    80001aba:	dd8080e7          	jalr	-552(ra) # 8000388e <fsinit>
    80001abe:	bff9                	j	80001a9c <forkret+0x26>

0000000080001ac0 <allocpid>:
allocpid() {
    80001ac0:	1101                	addi	sp,sp,-32
    80001ac2:	ec06                	sd	ra,24(sp)
    80001ac4:	e822                	sd	s0,16(sp)
    80001ac6:	e426                	sd	s1,8(sp)
    80001ac8:	e04a                	sd	s2,0(sp)
    80001aca:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001acc:	0000f917          	auipc	s2,0xf
    80001ad0:	7d490913          	addi	s2,s2,2004 # 800112a0 <pid_lock>
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	146080e7          	jalr	326(ra) # 80000c1c <acquire>
  pid = nextpid;
    80001ade:	00007797          	auipc	a5,0x7
    80001ae2:	d5678793          	addi	a5,a5,-682 # 80008834 <nextpid>
    80001ae6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae8:	0014871b          	addiw	a4,s1,1
    80001aec:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aee:	854a                	mv	a0,s2
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	1e0080e7          	jalr	480(ra) # 80000cd0 <release>
}
    80001af8:	8526                	mv	a0,s1
    80001afa:	60e2                	ld	ra,24(sp)
    80001afc:	6442                	ld	s0,16(sp)
    80001afe:	64a2                	ld	s1,8(sp)
    80001b00:	6902                	ld	s2,0(sp)
    80001b02:	6105                	addi	sp,sp,32
    80001b04:	8082                	ret

0000000080001b06 <proc_pagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	840080e7          	jalr	-1984(ra) # 80001354 <uvmcreate>
    80001b1c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b1e:	c121                	beqz	a0,80001b5e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b20:	4729                	li	a4,10
    80001b22:	00005697          	auipc	a3,0x5
    80001b26:	4de68693          	addi	a3,a3,1246 # 80007000 <_trampoline>
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5b4080e7          	jalr	1460(ra) # 800010e8 <mappages>
    80001b3c:	02054863          	bltz	a0,80001b6c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b40:	4719                	li	a4,6
    80001b42:	33093683          	ld	a3,816(s2)
    80001b46:	6605                	lui	a2,0x1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	596080e7          	jalr	1430(ra) # 800010e8 <mappages>
    80001b5a:	02054163          	bltz	a0,80001b7c <proc_pagetable+0x76>
}
    80001b5e:	8526                	mv	a0,s1
    80001b60:	60e2                	ld	ra,24(sp)
    80001b62:	6442                	ld	s0,16(sp)
    80001b64:	64a2                	ld	s1,8(sp)
    80001b66:	6902                	ld	s2,0(sp)
    80001b68:	6105                	addi	sp,sp,32
    80001b6a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b6c:	4581                	li	a1,0
    80001b6e:	8526                	mv	a0,s1
    80001b70:	00000097          	auipc	ra,0x0
    80001b74:	9e2080e7          	jalr	-1566(ra) # 80001552 <uvmfree>
    return 0;
    80001b78:	4481                	li	s1,0
    80001b7a:	b7d5                	j	80001b5e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7c:	4681                	li	a3,0
    80001b7e:	4605                	li	a2,1
    80001b80:	040005b7          	lui	a1,0x4000
    80001b84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b86:	05b2                	slli	a1,a1,0xc
    80001b88:	8526                	mv	a0,s1
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	724080e7          	jalr	1828(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001b92:	4581                	li	a1,0
    80001b94:	8526                	mv	a0,s1
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	9bc080e7          	jalr	-1604(ra) # 80001552 <uvmfree>
    return 0;
    80001b9e:	4481                	li	s1,0
    80001ba0:	bf7d                	j	80001b5e <proc_pagetable+0x58>

0000000080001ba2 <proc_freepagetable>:
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	e04a                	sd	s2,0(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	84aa                	mv	s1,a0
    80001bb0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb2:	4681                	li	a3,0
    80001bb4:	4605                	li	a2,1
    80001bb6:	040005b7          	lui	a1,0x4000
    80001bba:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bbc:	05b2                	slli	a1,a1,0xc
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	6f0080e7          	jalr	1776(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc6:	4681                	li	a3,0
    80001bc8:	4605                	li	a2,1
    80001bca:	020005b7          	lui	a1,0x2000
    80001bce:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bd0:	05b6                	slli	a1,a1,0xd
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	6da080e7          	jalr	1754(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001bdc:	85ca                	mv	a1,s2
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	972080e7          	jalr	-1678(ra) # 80001552 <uvmfree>
}
    80001be8:	60e2                	ld	ra,24(sp)
    80001bea:	6442                	ld	s0,16(sp)
    80001bec:	64a2                	ld	s1,8(sp)
    80001bee:	6902                	ld	s2,0(sp)
    80001bf0:	6105                	addi	sp,sp,32
    80001bf2:	8082                	ret

0000000080001bf4 <freeproc>:
{
    80001bf4:	1101                	addi	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	1000                	addi	s0,sp,32
    80001bfe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c00:	33053503          	ld	a0,816(a0)
    80001c04:	c509                	beqz	a0,80001c0e <freeproc+0x1a>
    kfree((void*)p->trapframe);
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	dde080e7          	jalr	-546(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001c0e:	3204b823          	sd	zero,816(s1)
  if(p->pagetable)
    80001c12:	3284b503          	ld	a0,808(s1)
    80001c16:	c519                	beqz	a0,80001c24 <freeproc+0x30>
    proc_freepagetable(p->pagetable, p->sz);
    80001c18:	3204b583          	ld	a1,800(s1)
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	f86080e7          	jalr	-122(ra) # 80001ba2 <proc_freepagetable>
  p->pagetable = 0;
    80001c24:	3204b423          	sd	zero,808(s1)
  p->sz = 0;
    80001c28:	3204b023          	sd	zero,800(s1)
  p->pid = 0;
    80001c2c:	3004a423          	sw	zero,776(s1)
  p->parent = 0;
    80001c30:	3004b823          	sd	zero,784(s1)
  p->name[0] = 0;
    80001c34:	42048823          	sb	zero,1072(s1)
  p->chan = 0;
    80001c38:	2e04bc23          	sd	zero,760(s1)
  p->killed = 0;
    80001c3c:	3004a023          	sw	zero,768(s1)
  p->xstate = 0;
    80001c40:	3004a223          	sw	zero,772(s1)
  p->state = UNUSED;
    80001c44:	2e04a823          	sw	zero,752(s1)
}
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6105                	addi	sp,sp,32
    80001c50:	8082                	ret

0000000080001c52 <allocproc>:
{
    80001c52:	7179                	addi	sp,sp,-48
    80001c54:	f406                	sd	ra,40(sp)
    80001c56:	f022                	sd	s0,32(sp)
    80001c58:	ec26                	sd	s1,24(sp)
    80001c5a:	e84a                	sd	s2,16(sp)
    80001c5c:	e44e                	sd	s3,8(sp)
    80001c5e:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c60:	00010497          	auipc	s1,0x10
    80001c64:	a8848493          	addi	s1,s1,-1400 # 800116e8 <proc>
    80001c68:	00021997          	auipc	s3,0x21
    80001c6c:	a8098993          	addi	s3,s3,-1408 # 800226e8 <mmr_list>
    acquire(&p->lock);
    80001c70:	2d848913          	addi	s2,s1,728
    80001c74:	854a                	mv	a0,s2
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	fa6080e7          	jalr	-90(ra) # 80000c1c <acquire>
    if(p->state == UNUSED) {
    80001c7e:	2f04a783          	lw	a5,752(s1)
    80001c82:	cf81                	beqz	a5,80001c9a <allocproc+0x48>
      release(&p->lock);
    80001c84:	854a                	mv	a0,s2
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	04a080e7          	jalr	74(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c8e:	44048493          	addi	s1,s1,1088
    80001c92:	fd349fe3          	bne	s1,s3,80001c70 <allocproc+0x1e>
  return 0;
    80001c96:	4481                	li	s1,0
    80001c98:	a085                	j	80001cf8 <allocproc+0xa6>
  p->pid = allocpid();
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	e26080e7          	jalr	-474(ra) # 80001ac0 <allocpid>
    80001ca2:	30a4a423          	sw	a0,776(s1)
  p->state = USED;
    80001ca6:	4785                	li	a5,1
    80001ca8:	2ef4a823          	sw	a5,752(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	e36080e7          	jalr	-458(ra) # 80000ae2 <kalloc>
    80001cb4:	89aa                	mv	s3,a0
    80001cb6:	32a4b823          	sd	a0,816(s1)
    80001cba:	c539                	beqz	a0,80001d08 <allocproc+0xb6>
  p->pagetable = proc_pagetable(p);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	e48080e7          	jalr	-440(ra) # 80001b06 <proc_pagetable>
    80001cc6:	89aa                	mv	s3,a0
    80001cc8:	32a4b423          	sd	a0,808(s1)
  if(p->pagetable == 0){
    80001ccc:	c931                	beqz	a0,80001d20 <allocproc+0xce>
  memset(&p->context, 0, sizeof(p->context));
    80001cce:	07000613          	li	a2,112
    80001cd2:	4581                	li	a1,0
    80001cd4:	33848513          	addi	a0,s1,824
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	040080e7          	jalr	64(ra) # 80000d18 <memset>
  p->context.ra = (uint64)forkret;
    80001ce0:	00000797          	auipc	a5,0x0
    80001ce4:	d9678793          	addi	a5,a5,-618 # 80001a76 <forkret>
    80001ce8:	32f4bc23          	sd	a5,824(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cec:	3184b783          	ld	a5,792(s1)
    80001cf0:	6705                	lui	a4,0x1
    80001cf2:	97ba                	add	a5,a5,a4
    80001cf4:	34f4b023          	sd	a5,832(s1)
}
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	70a2                	ld	ra,40(sp)
    80001cfc:	7402                	ld	s0,32(sp)
    80001cfe:	64e2                	ld	s1,24(sp)
    80001d00:	6942                	ld	s2,16(sp)
    80001d02:	69a2                	ld	s3,8(sp)
    80001d04:	6145                	addi	sp,sp,48
    80001d06:	8082                	ret
    freeproc(p);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	eea080e7          	jalr	-278(ra) # 80001bf4 <freeproc>
    release(&p->lock);
    80001d12:	854a                	mv	a0,s2
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	fbc080e7          	jalr	-68(ra) # 80000cd0 <release>
    return 0;
    80001d1c:	84ce                	mv	s1,s3
    80001d1e:	bfe9                	j	80001cf8 <allocproc+0xa6>
    freeproc(p);
    80001d20:	8526                	mv	a0,s1
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	ed2080e7          	jalr	-302(ra) # 80001bf4 <freeproc>
    release(&p->lock);
    80001d2a:	854a                	mv	a0,s2
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	fa4080e7          	jalr	-92(ra) # 80000cd0 <release>
    return 0;
    80001d34:	84ce                	mv	s1,s3
    80001d36:	b7c9                	j	80001cf8 <allocproc+0xa6>

0000000080001d38 <userinit>:
{
    80001d38:	1101                	addi	sp,sp,-32
    80001d3a:	ec06                	sd	ra,24(sp)
    80001d3c:	e822                	sd	s0,16(sp)
    80001d3e:	e426                	sd	s1,8(sp)
    80001d40:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	f10080e7          	jalr	-240(ra) # 80001c52 <allocproc>
    80001d4a:	84aa                	mv	s1,a0
  initproc = p;
    80001d4c:	00007797          	auipc	a5,0x7
    80001d50:	2ca7be23          	sd	a0,732(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d54:	03400613          	li	a2,52
    80001d58:	00007597          	auipc	a1,0x7
    80001d5c:	ae858593          	addi	a1,a1,-1304 # 80008840 <initcode>
    80001d60:	32853503          	ld	a0,808(a0)
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	61e080e7          	jalr	1566(ra) # 80001382 <uvminit>
  p->sz = PGSIZE;
    80001d6c:	6785                	lui	a5,0x1
    80001d6e:	32f4b023          	sd	a5,800(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d72:	3304b703          	ld	a4,816(s1)
    80001d76:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d7a:	3304b703          	ld	a4,816(s1)
    80001d7e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d80:	4641                	li	a2,16
    80001d82:	00006597          	auipc	a1,0x6
    80001d86:	43658593          	addi	a1,a1,1078 # 800081b8 <digits+0x178>
    80001d8a:	43048513          	addi	a0,s1,1072
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	0d4080e7          	jalr	212(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001d96:	00006517          	auipc	a0,0x6
    80001d9a:	43250513          	addi	a0,a0,1074 # 800081c8 <digits+0x188>
    80001d9e:	00002097          	auipc	ra,0x2
    80001da2:	526080e7          	jalr	1318(ra) # 800042c4 <namei>
    80001da6:	42a4b423          	sd	a0,1064(s1)
  p->state = RUNNABLE;
    80001daa:	478d                	li	a5,3
    80001dac:	2ef4a823          	sw	a5,752(s1)
  p->cur_max = MAXVA - 2*PGSIZE;
    80001db0:	020007b7          	lui	a5,0x2000
    80001db4:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001db6:	07b6                	slli	a5,a5,0xd
    80001db8:	2cf4b823          	sd	a5,720(s1)
  release(&p->lock);
    80001dbc:	2d848513          	addi	a0,s1,728
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	f10080e7          	jalr	-240(ra) # 80000cd0 <release>
}
    80001dc8:	60e2                	ld	ra,24(sp)
    80001dca:	6442                	ld	s0,16(sp)
    80001dcc:	64a2                	ld	s1,8(sp)
    80001dce:	6105                	addi	sp,sp,32
    80001dd0:	8082                	ret

0000000080001dd2 <growproc>:
{
    80001dd2:	1101                	addi	sp,sp,-32
    80001dd4:	ec06                	sd	ra,24(sp)
    80001dd6:	e822                	sd	s0,16(sp)
    80001dd8:	e426                	sd	s1,8(sp)
    80001dda:	e04a                	sd	s2,0(sp)
    80001ddc:	1000                	addi	s0,sp,32
    80001dde:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001de0:	00000097          	auipc	ra,0x0
    80001de4:	c5e080e7          	jalr	-930(ra) # 80001a3e <myproc>
    80001de8:	892a                	mv	s2,a0
  sz = p->sz;
    80001dea:	32053583          	ld	a1,800(a0)
    80001dee:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001df2:	00904f63          	bgtz	s1,80001e10 <growproc+0x3e>
  } else if(n < 0){
    80001df6:	0204ce63          	bltz	s1,80001e32 <growproc+0x60>
  p->sz = sz;
    80001dfa:	1782                	slli	a5,a5,0x20
    80001dfc:	9381                	srli	a5,a5,0x20
    80001dfe:	32f93023          	sd	a5,800(s2)
  return 0;
    80001e02:	4501                	li	a0,0
}
    80001e04:	60e2                	ld	ra,24(sp)
    80001e06:	6442                	ld	s0,16(sp)
    80001e08:	64a2                	ld	s1,8(sp)
    80001e0a:	6902                	ld	s2,0(sp)
    80001e0c:	6105                	addi	sp,sp,32
    80001e0e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e10:	00f4863b          	addw	a2,s1,a5
    80001e14:	1602                	slli	a2,a2,0x20
    80001e16:	9201                	srli	a2,a2,0x20
    80001e18:	1582                	slli	a1,a1,0x20
    80001e1a:	9181                	srli	a1,a1,0x20
    80001e1c:	32853503          	ld	a0,808(a0)
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	61c080e7          	jalr	1564(ra) # 8000143c <uvmalloc>
    80001e28:	0005079b          	sext.w	a5,a0
    80001e2c:	f7f9                	bnez	a5,80001dfa <growproc+0x28>
      return -1;
    80001e2e:	557d                	li	a0,-1
    80001e30:	bfd1                	j	80001e04 <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e32:	00f4863b          	addw	a2,s1,a5
    80001e36:	1602                	slli	a2,a2,0x20
    80001e38:	9201                	srli	a2,a2,0x20
    80001e3a:	1582                	slli	a1,a1,0x20
    80001e3c:	9181                	srli	a1,a1,0x20
    80001e3e:	32853503          	ld	a0,808(a0)
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	5b2080e7          	jalr	1458(ra) # 800013f4 <uvmdealloc>
    80001e4a:	0005079b          	sext.w	a5,a0
    80001e4e:	b775                	j	80001dfa <growproc+0x28>

0000000080001e50 <fork>:
{
    80001e50:	7139                	addi	sp,sp,-64
    80001e52:	fc06                	sd	ra,56(sp)
    80001e54:	f822                	sd	s0,48(sp)
    80001e56:	f426                	sd	s1,40(sp)
    80001e58:	f04a                	sd	s2,32(sp)
    80001e5a:	ec4e                	sd	s3,24(sp)
    80001e5c:	e852                	sd	s4,16(sp)
    80001e5e:	e456                	sd	s5,8(sp)
    80001e60:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	bdc080e7          	jalr	-1060(ra) # 80001a3e <myproc>
    80001e6a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	de6080e7          	jalr	-538(ra) # 80001c52 <allocproc>
    80001e74:	12050463          	beqz	a0,80001f9c <fork+0x14c>
    80001e78:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e7a:	320ab603          	ld	a2,800(s5)
    80001e7e:	32853583          	ld	a1,808(a0)
    80001e82:	328ab503          	ld	a0,808(s5)
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	706080e7          	jalr	1798(ra) # 8000158c <uvmcopy>
    80001e8e:	04054c63          	bltz	a0,80001ee6 <fork+0x96>
  np->sz = p->sz;
    80001e92:	320ab783          	ld	a5,800(s5)
    80001e96:	32fa3023          	sd	a5,800(s4)
  np->cur_max = p->cur_max;
    80001e9a:	2d0ab783          	ld	a5,720(s5)
    80001e9e:	2cfa3823          	sd	a5,720(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ea2:	330ab683          	ld	a3,816(s5)
    80001ea6:	87b6                	mv	a5,a3
    80001ea8:	330a3703          	ld	a4,816(s4)
    80001eac:	12068693          	addi	a3,a3,288
    80001eb0:	0007b803          	ld	a6,0(a5)
    80001eb4:	6788                	ld	a0,8(a5)
    80001eb6:	6b8c                	ld	a1,16(a5)
    80001eb8:	6f90                	ld	a2,24(a5)
    80001eba:	01073023          	sd	a6,0(a4)
    80001ebe:	e708                	sd	a0,8(a4)
    80001ec0:	eb0c                	sd	a1,16(a4)
    80001ec2:	ef10                	sd	a2,24(a4)
    80001ec4:	02078793          	addi	a5,a5,32
    80001ec8:	02070713          	addi	a4,a4,32
    80001ecc:	fed792e3          	bne	a5,a3,80001eb0 <fork+0x60>
  np->trapframe->a0 = 0;
    80001ed0:	330a3783          	ld	a5,816(s4)
    80001ed4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ed8:	3a8a8493          	addi	s1,s5,936
    80001edc:	3a8a0913          	addi	s2,s4,936
    80001ee0:	428a8993          	addi	s3,s5,1064
    80001ee4:	a015                	j	80001f08 <fork+0xb8>
    freeproc(np);
    80001ee6:	8552                	mv	a0,s4
    80001ee8:	00000097          	auipc	ra,0x0
    80001eec:	d0c080e7          	jalr	-756(ra) # 80001bf4 <freeproc>
    release(&np->lock);
    80001ef0:	2d8a0513          	addi	a0,s4,728
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	ddc080e7          	jalr	-548(ra) # 80000cd0 <release>
    return -1;
    80001efc:	59fd                	li	s3,-1
    80001efe:	a069                	j	80001f88 <fork+0x138>
  for(i = 0; i < NOFILE; i++)
    80001f00:	04a1                	addi	s1,s1,8
    80001f02:	0921                	addi	s2,s2,8
    80001f04:	01348b63          	beq	s1,s3,80001f1a <fork+0xca>
    if(p->ofile[i])
    80001f08:	6088                	ld	a0,0(s1)
    80001f0a:	d97d                	beqz	a0,80001f00 <fork+0xb0>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f0c:	00003097          	auipc	ra,0x3
    80001f10:	a52080e7          	jalr	-1454(ra) # 8000495e <filedup>
    80001f14:	00a93023          	sd	a0,0(s2)
    80001f18:	b7e5                	j	80001f00 <fork+0xb0>
  np->cwd = idup(p->cwd);
    80001f1a:	428ab503          	ld	a0,1064(s5)
    80001f1e:	00002097          	auipc	ra,0x2
    80001f22:	bac080e7          	jalr	-1108(ra) # 80003aca <idup>
    80001f26:	42aa3423          	sd	a0,1064(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f2a:	4641                	li	a2,16
    80001f2c:	430a8593          	addi	a1,s5,1072
    80001f30:	430a0513          	addi	a0,s4,1072
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	f2e080e7          	jalr	-210(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001f3c:	308a2983          	lw	s3,776(s4)
  release(&np->lock);
    80001f40:	2d8a0493          	addi	s1,s4,728
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	d8a080e7          	jalr	-630(ra) # 80000cd0 <release>
  acquire(&wait_lock);
    80001f4e:	0000f917          	auipc	s2,0xf
    80001f52:	36a90913          	addi	s2,s2,874 # 800112b8 <wait_lock>
    80001f56:	854a                	mv	a0,s2
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	cc4080e7          	jalr	-828(ra) # 80000c1c <acquire>
  np->parent = p;
    80001f60:	315a3823          	sd	s5,784(s4)
  release(&wait_lock);
    80001f64:	854a                	mv	a0,s2
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d6a080e7          	jalr	-662(ra) # 80000cd0 <release>
  acquire(&np->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	cac080e7          	jalr	-852(ra) # 80000c1c <acquire>
  np->state = RUNNABLE;
    80001f78:	478d                	li	a5,3
    80001f7a:	2efa2823          	sw	a5,752(s4)
  release(&np->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d50080e7          	jalr	-688(ra) # 80000cd0 <release>
}
    80001f88:	854e                	mv	a0,s3
    80001f8a:	70e2                	ld	ra,56(sp)
    80001f8c:	7442                	ld	s0,48(sp)
    80001f8e:	74a2                	ld	s1,40(sp)
    80001f90:	7902                	ld	s2,32(sp)
    80001f92:	69e2                	ld	s3,24(sp)
    80001f94:	6a42                	ld	s4,16(sp)
    80001f96:	6aa2                	ld	s5,8(sp)
    80001f98:	6121                	addi	sp,sp,64
    80001f9a:	8082                	ret
    return -1;
    80001f9c:	59fd                	li	s3,-1
    80001f9e:	b7ed                	j	80001f88 <fork+0x138>

0000000080001fa0 <scheduler>:
{
    80001fa0:	715d                	addi	sp,sp,-80
    80001fa2:	e486                	sd	ra,72(sp)
    80001fa4:	e0a2                	sd	s0,64(sp)
    80001fa6:	fc26                	sd	s1,56(sp)
    80001fa8:	f84a                	sd	s2,48(sp)
    80001faa:	f44e                	sd	s3,40(sp)
    80001fac:	f052                	sd	s4,32(sp)
    80001fae:	ec56                	sd	s5,24(sp)
    80001fb0:	e85a                	sd	s6,16(sp)
    80001fb2:	e45e                	sd	s7,8(sp)
    80001fb4:	0880                	addi	s0,sp,80
    80001fb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001fb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fba:	00779b13          	slli	s6,a5,0x7
    80001fbe:	0000f717          	auipc	a4,0xf
    80001fc2:	2e270713          	addi	a4,a4,738 # 800112a0 <pid_lock>
    80001fc6:	975a                	add	a4,a4,s6
    80001fc8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fcc:	0000f717          	auipc	a4,0xf
    80001fd0:	30c70713          	addi	a4,a4,780 # 800112d8 <cpus+0x8>
    80001fd4:	9b3a                	add	s6,s6,a4
      if(p->state == RUNNABLE) {
    80001fd6:	4a0d                	li	s4,3
        p->state = RUNNING;
    80001fd8:	4b91                	li	s7,4
        c->proc = p;
    80001fda:	079e                	slli	a5,a5,0x7
    80001fdc:	0000fa97          	auipc	s5,0xf
    80001fe0:	2c4a8a93          	addi	s5,s5,708 # 800112a0 <pid_lock>
    80001fe4:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe6:	00020997          	auipc	s3,0x20
    80001fea:	70298993          	addi	s3,s3,1794 # 800226e8 <mmr_list>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff6:	10079073          	csrw	sstatus,a5
    80001ffa:	0000f497          	auipc	s1,0xf
    80001ffe:	6ee48493          	addi	s1,s1,1774 # 800116e8 <proc>
    80002002:	a811                	j	80002016 <scheduler+0x76>
      release(&p->lock);
    80002004:	854a                	mv	a0,s2
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	cca080e7          	jalr	-822(ra) # 80000cd0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200e:	44048493          	addi	s1,s1,1088
    80002012:	fd348ee3          	beq	s1,s3,80001fee <scheduler+0x4e>
      acquire(&p->lock);
    80002016:	2d848913          	addi	s2,s1,728
    8000201a:	854a                	mv	a0,s2
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	c00080e7          	jalr	-1024(ra) # 80000c1c <acquire>
      if(p->state == RUNNABLE) {
    80002024:	2f04a783          	lw	a5,752(s1)
    80002028:	fd479ee3          	bne	a5,s4,80002004 <scheduler+0x64>
        p->state = RUNNING;
    8000202c:	2f74a823          	sw	s7,752(s1)
        c->proc = p;
    80002030:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80002034:	33848593          	addi	a1,s1,824
    80002038:	855a                	mv	a0,s6
    8000203a:	00001097          	auipc	ra,0x1
    8000203e:	8b8080e7          	jalr	-1864(ra) # 800028f2 <swtch>
        c->proc = 0;
    80002042:	020ab823          	sd	zero,48(s5)
    80002046:	bf7d                	j	80002004 <scheduler+0x64>

0000000080002048 <sched>:
{
    80002048:	7179                	addi	sp,sp,-48
    8000204a:	f406                	sd	ra,40(sp)
    8000204c:	f022                	sd	s0,32(sp)
    8000204e:	ec26                	sd	s1,24(sp)
    80002050:	e84a                	sd	s2,16(sp)
    80002052:	e44e                	sd	s3,8(sp)
    80002054:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	9e8080e7          	jalr	-1560(ra) # 80001a3e <myproc>
    8000205e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002060:	2d850513          	addi	a0,a0,728
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	b3e080e7          	jalr	-1218(ra) # 80000ba2 <holding>
    8000206c:	cd25                	beqz	a0,800020e4 <sched+0x9c>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000206e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002070:	2781                	sext.w	a5,a5
    80002072:	079e                	slli	a5,a5,0x7
    80002074:	0000f717          	auipc	a4,0xf
    80002078:	22c70713          	addi	a4,a4,556 # 800112a0 <pid_lock>
    8000207c:	97ba                	add	a5,a5,a4
    8000207e:	0a87a703          	lw	a4,168(a5)
    80002082:	4785                	li	a5,1
    80002084:	06f71863          	bne	a4,a5,800020f4 <sched+0xac>
  if(p->state == RUNNING)
    80002088:	2f04a703          	lw	a4,752(s1)
    8000208c:	4791                	li	a5,4
    8000208e:	06f70b63          	beq	a4,a5,80002104 <sched+0xbc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002092:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002096:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002098:	efb5                	bnez	a5,80002114 <sched+0xcc>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000209a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000209c:	0000f917          	auipc	s2,0xf
    800020a0:	20490913          	addi	s2,s2,516 # 800112a0 <pid_lock>
    800020a4:	2781                	sext.w	a5,a5
    800020a6:	079e                	slli	a5,a5,0x7
    800020a8:	97ca                	add	a5,a5,s2
    800020aa:	0ac7a983          	lw	s3,172(a5)
    800020ae:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b0:	2781                	sext.w	a5,a5
    800020b2:	079e                	slli	a5,a5,0x7
    800020b4:	0000f597          	auipc	a1,0xf
    800020b8:	22458593          	addi	a1,a1,548 # 800112d8 <cpus+0x8>
    800020bc:	95be                	add	a1,a1,a5
    800020be:	33848513          	addi	a0,s1,824
    800020c2:	00001097          	auipc	ra,0x1
    800020c6:	830080e7          	jalr	-2000(ra) # 800028f2 <swtch>
    800020ca:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020cc:	2781                	sext.w	a5,a5
    800020ce:	079e                	slli	a5,a5,0x7
    800020d0:	993e                	add	s2,s2,a5
    800020d2:	0b392623          	sw	s3,172(s2)
}
    800020d6:	70a2                	ld	ra,40(sp)
    800020d8:	7402                	ld	s0,32(sp)
    800020da:	64e2                	ld	s1,24(sp)
    800020dc:	6942                	ld	s2,16(sp)
    800020de:	69a2                	ld	s3,8(sp)
    800020e0:	6145                	addi	sp,sp,48
    800020e2:	8082                	ret
    panic("sched p->lock");
    800020e4:	00006517          	auipc	a0,0x6
    800020e8:	0ec50513          	addi	a0,a0,236 # 800081d0 <digits+0x190>
    800020ec:	ffffe097          	auipc	ra,0xffffe
    800020f0:	450080e7          	jalr	1104(ra) # 8000053c <panic>
    panic("sched locks");
    800020f4:	00006517          	auipc	a0,0x6
    800020f8:	0ec50513          	addi	a0,a0,236 # 800081e0 <digits+0x1a0>
    800020fc:	ffffe097          	auipc	ra,0xffffe
    80002100:	440080e7          	jalr	1088(ra) # 8000053c <panic>
    panic("sched running");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	0ec50513          	addi	a0,a0,236 # 800081f0 <digits+0x1b0>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	430080e7          	jalr	1072(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002114:	00006517          	auipc	a0,0x6
    80002118:	0ec50513          	addi	a0,a0,236 # 80008200 <digits+0x1c0>
    8000211c:	ffffe097          	auipc	ra,0xffffe
    80002120:	420080e7          	jalr	1056(ra) # 8000053c <panic>

0000000080002124 <yield>:
{
    80002124:	1101                	addi	sp,sp,-32
    80002126:	ec06                	sd	ra,24(sp)
    80002128:	e822                	sd	s0,16(sp)
    8000212a:	e426                	sd	s1,8(sp)
    8000212c:	e04a                	sd	s2,0(sp)
    8000212e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	90e080e7          	jalr	-1778(ra) # 80001a3e <myproc>
    80002138:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000213a:	2d850913          	addi	s2,a0,728
    8000213e:	854a                	mv	a0,s2
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	adc080e7          	jalr	-1316(ra) # 80000c1c <acquire>
  p->state = RUNNABLE;
    80002148:	478d                	li	a5,3
    8000214a:	2ef4a823          	sw	a5,752(s1)
  sched();
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	efa080e7          	jalr	-262(ra) # 80002048 <sched>
  release(&p->lock);
    80002156:	854a                	mv	a0,s2
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b78080e7          	jalr	-1160(ra) # 80000cd0 <release>
}
    80002160:	60e2                	ld	ra,24(sp)
    80002162:	6442                	ld	s0,16(sp)
    80002164:	64a2                	ld	s1,8(sp)
    80002166:	6902                	ld	s2,0(sp)
    80002168:	6105                	addi	sp,sp,32
    8000216a:	8082                	ret

000000008000216c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000216c:	7179                	addi	sp,sp,-48
    8000216e:	f406                	sd	ra,40(sp)
    80002170:	f022                	sd	s0,32(sp)
    80002172:	ec26                	sd	s1,24(sp)
    80002174:	e84a                	sd	s2,16(sp)
    80002176:	e44e                	sd	s3,8(sp)
    80002178:	e052                	sd	s4,0(sp)
    8000217a:	1800                	addi	s0,sp,48
    8000217c:	89aa                	mv	s3,a0
    8000217e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002180:	00000097          	auipc	ra,0x0
    80002184:	8be080e7          	jalr	-1858(ra) # 80001a3e <myproc>
    80002188:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000218a:	2d850a13          	addi	s4,a0,728
    8000218e:	8552                	mv	a0,s4
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	a8c080e7          	jalr	-1396(ra) # 80000c1c <acquire>
  release(lk);
    80002198:	854a                	mv	a0,s2
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	b36080e7          	jalr	-1226(ra) # 80000cd0 <release>

  // Go to sleep.
  p->chan = chan;
    800021a2:	2f34bc23          	sd	s3,760(s1)
  p->state = SLEEPING;
    800021a6:	4789                	li	a5,2
    800021a8:	2ef4a823          	sw	a5,752(s1)

  sched();
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	e9c080e7          	jalr	-356(ra) # 80002048 <sched>

  // Tidy up.
  p->chan = 0;
    800021b4:	2e04bc23          	sd	zero,760(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021b8:	8552                	mv	a0,s4
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	b16080e7          	jalr	-1258(ra) # 80000cd0 <release>
  acquire(lk);
    800021c2:	854a                	mv	a0,s2
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	a58080e7          	jalr	-1448(ra) # 80000c1c <acquire>
}
    800021cc:	70a2                	ld	ra,40(sp)
    800021ce:	7402                	ld	s0,32(sp)
    800021d0:	64e2                	ld	s1,24(sp)
    800021d2:	6942                	ld	s2,16(sp)
    800021d4:	69a2                	ld	s3,8(sp)
    800021d6:	6a02                	ld	s4,0(sp)
    800021d8:	6145                	addi	sp,sp,48
    800021da:	8082                	ret

00000000800021dc <wait>:
{
    800021dc:	711d                	addi	sp,sp,-96
    800021de:	ec86                	sd	ra,88(sp)
    800021e0:	e8a2                	sd	s0,80(sp)
    800021e2:	e4a6                	sd	s1,72(sp)
    800021e4:	e0ca                	sd	s2,64(sp)
    800021e6:	fc4e                	sd	s3,56(sp)
    800021e8:	f852                	sd	s4,48(sp)
    800021ea:	f456                	sd	s5,40(sp)
    800021ec:	f05a                	sd	s6,32(sp)
    800021ee:	ec5e                	sd	s7,24(sp)
    800021f0:	e862                	sd	s8,16(sp)
    800021f2:	e466                	sd	s9,8(sp)
    800021f4:	1080                	addi	s0,sp,96
    800021f6:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    800021f8:	00000097          	auipc	ra,0x0
    800021fc:	846080e7          	jalr	-1978(ra) # 80001a3e <myproc>
    80002200:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002202:	0000f517          	auipc	a0,0xf
    80002206:	0b650513          	addi	a0,a0,182 # 800112b8 <wait_lock>
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a12080e7          	jalr	-1518(ra) # 80000c1c <acquire>
    havekids = 0;
    80002212:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    80002214:	4a95                	li	s5,5
        havekids = 1;
    80002216:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002218:	00020997          	auipc	s3,0x20
    8000221c:	4d098993          	addi	s3,s3,1232 # 800226e8 <mmr_list>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002220:	0000fc97          	auipc	s9,0xf
    80002224:	098c8c93          	addi	s9,s9,152 # 800112b8 <wait_lock>
    havekids = 0;
    80002228:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    8000222a:	0000f497          	auipc	s1,0xf
    8000222e:	4be48493          	addi	s1,s1,1214 # 800116e8 <proc>
    80002232:	a0bd                	j	800022a0 <wait+0xc4>
          pid = np->pid;
    80002234:	3084a983          	lw	s3,776(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002238:	000b8e63          	beqz	s7,80002254 <wait+0x78>
    8000223c:	4691                	li	a3,4
    8000223e:	30448613          	addi	a2,s1,772
    80002242:	85de                	mv	a1,s7
    80002244:	32893503          	ld	a0,808(s2)
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	43c080e7          	jalr	1084(ra) # 80001684 <copyout>
    80002250:	02054563          	bltz	a0,8000227a <wait+0x9e>
          freeproc(np);
    80002254:	8526                	mv	a0,s1
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	99e080e7          	jalr	-1634(ra) # 80001bf4 <freeproc>
          release(&np->lock);
    8000225e:	8552                	mv	a0,s4
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a70080e7          	jalr	-1424(ra) # 80000cd0 <release>
          release(&wait_lock);
    80002268:	0000f517          	auipc	a0,0xf
    8000226c:	05050513          	addi	a0,a0,80 # 800112b8 <wait_lock>
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a60080e7          	jalr	-1440(ra) # 80000cd0 <release>
          return pid;
    80002278:	a0bd                	j	800022e6 <wait+0x10a>
            release(&np->lock);
    8000227a:	8552                	mv	a0,s4
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	a54080e7          	jalr	-1452(ra) # 80000cd0 <release>
            release(&wait_lock);
    80002284:	0000f517          	auipc	a0,0xf
    80002288:	03450513          	addi	a0,a0,52 # 800112b8 <wait_lock>
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	a44080e7          	jalr	-1468(ra) # 80000cd0 <release>
            return -1;
    80002294:	59fd                	li	s3,-1
    80002296:	a881                	j	800022e6 <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002298:	44048493          	addi	s1,s1,1088
    8000229c:	03348863          	beq	s1,s3,800022cc <wait+0xf0>
      if(np->parent == p){
    800022a0:	3104b783          	ld	a5,784(s1)
    800022a4:	ff279ae3          	bne	a5,s2,80002298 <wait+0xbc>
        acquire(&np->lock);
    800022a8:	2d848a13          	addi	s4,s1,728
    800022ac:	8552                	mv	a0,s4
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	96e080e7          	jalr	-1682(ra) # 80000c1c <acquire>
        if(np->state == ZOMBIE){
    800022b6:	2f04a783          	lw	a5,752(s1)
    800022ba:	f7578de3          	beq	a5,s5,80002234 <wait+0x58>
        release(&np->lock);
    800022be:	8552                	mv	a0,s4
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	a10080e7          	jalr	-1520(ra) # 80000cd0 <release>
        havekids = 1;
    800022c8:	875a                	mv	a4,s6
    800022ca:	b7f9                	j	80002298 <wait+0xbc>
    if(!havekids || p->killed){
    800022cc:	c701                	beqz	a4,800022d4 <wait+0xf8>
    800022ce:	30092783          	lw	a5,768(s2)
    800022d2:	cb85                	beqz	a5,80002302 <wait+0x126>
      release(&wait_lock);
    800022d4:	0000f517          	auipc	a0,0xf
    800022d8:	fe450513          	addi	a0,a0,-28 # 800112b8 <wait_lock>
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9f4080e7          	jalr	-1548(ra) # 80000cd0 <release>
      return -1;
    800022e4:	59fd                	li	s3,-1
}
    800022e6:	854e                	mv	a0,s3
    800022e8:	60e6                	ld	ra,88(sp)
    800022ea:	6446                	ld	s0,80(sp)
    800022ec:	64a6                	ld	s1,72(sp)
    800022ee:	6906                	ld	s2,64(sp)
    800022f0:	79e2                	ld	s3,56(sp)
    800022f2:	7a42                	ld	s4,48(sp)
    800022f4:	7aa2                	ld	s5,40(sp)
    800022f6:	7b02                	ld	s6,32(sp)
    800022f8:	6be2                	ld	s7,24(sp)
    800022fa:	6c42                	ld	s8,16(sp)
    800022fc:	6ca2                	ld	s9,8(sp)
    800022fe:	6125                	addi	sp,sp,96
    80002300:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002302:	85e6                	mv	a1,s9
    80002304:	854a                	mv	a0,s2
    80002306:	00000097          	auipc	ra,0x0
    8000230a:	e66080e7          	jalr	-410(ra) # 8000216c <sleep>
    havekids = 0;
    8000230e:	bf29                	j	80002228 <wait+0x4c>

0000000080002310 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002310:	7139                	addi	sp,sp,-64
    80002312:	fc06                	sd	ra,56(sp)
    80002314:	f822                	sd	s0,48(sp)
    80002316:	f426                	sd	s1,40(sp)
    80002318:	f04a                	sd	s2,32(sp)
    8000231a:	ec4e                	sd	s3,24(sp)
    8000231c:	e852                	sd	s4,16(sp)
    8000231e:	e456                	sd	s5,8(sp)
    80002320:	e05a                	sd	s6,0(sp)
    80002322:	0080                	addi	s0,sp,64
    80002324:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002326:	0000f497          	auipc	s1,0xf
    8000232a:	3c248493          	addi	s1,s1,962 # 800116e8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000232e:	4a09                	li	s4,2
        p->state = RUNNABLE;
    80002330:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002332:	00020997          	auipc	s3,0x20
    80002336:	3b698993          	addi	s3,s3,950 # 800226e8 <mmr_list>
    8000233a:	a811                	j	8000234e <wakeup+0x3e>
      }
      release(&p->lock);
    8000233c:	854a                	mv	a0,s2
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	992080e7          	jalr	-1646(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002346:	44048493          	addi	s1,s1,1088
    8000234a:	03348a63          	beq	s1,s3,8000237e <wakeup+0x6e>
    if(p != myproc()){
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	6f0080e7          	jalr	1776(ra) # 80001a3e <myproc>
    80002356:	fea488e3          	beq	s1,a0,80002346 <wakeup+0x36>
      acquire(&p->lock);
    8000235a:	2d848913          	addi	s2,s1,728
    8000235e:	854a                	mv	a0,s2
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	8bc080e7          	jalr	-1860(ra) # 80000c1c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002368:	2f04a783          	lw	a5,752(s1)
    8000236c:	fd4798e3          	bne	a5,s4,8000233c <wakeup+0x2c>
    80002370:	2f84b783          	ld	a5,760(s1)
    80002374:	fd5794e3          	bne	a5,s5,8000233c <wakeup+0x2c>
        p->state = RUNNABLE;
    80002378:	2f64a823          	sw	s6,752(s1)
    8000237c:	b7c1                	j	8000233c <wakeup+0x2c>
    }
  }
}
    8000237e:	70e2                	ld	ra,56(sp)
    80002380:	7442                	ld	s0,48(sp)
    80002382:	74a2                	ld	s1,40(sp)
    80002384:	7902                	ld	s2,32(sp)
    80002386:	69e2                	ld	s3,24(sp)
    80002388:	6a42                	ld	s4,16(sp)
    8000238a:	6aa2                	ld	s5,8(sp)
    8000238c:	6b02                	ld	s6,0(sp)
    8000238e:	6121                	addi	sp,sp,64
    80002390:	8082                	ret

0000000080002392 <reparent>:
{
    80002392:	7179                	addi	sp,sp,-48
    80002394:	f406                	sd	ra,40(sp)
    80002396:	f022                	sd	s0,32(sp)
    80002398:	ec26                	sd	s1,24(sp)
    8000239a:	e84a                	sd	s2,16(sp)
    8000239c:	e44e                	sd	s3,8(sp)
    8000239e:	e052                	sd	s4,0(sp)
    800023a0:	1800                	addi	s0,sp,48
    800023a2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a4:	0000f497          	auipc	s1,0xf
    800023a8:	34448493          	addi	s1,s1,836 # 800116e8 <proc>
      pp->parent = initproc;
    800023ac:	00007a17          	auipc	s4,0x7
    800023b0:	c7ca0a13          	addi	s4,s4,-900 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b4:	00020997          	auipc	s3,0x20
    800023b8:	33498993          	addi	s3,s3,820 # 800226e8 <mmr_list>
    800023bc:	a029                	j	800023c6 <reparent+0x34>
    800023be:	44048493          	addi	s1,s1,1088
    800023c2:	01348f63          	beq	s1,s3,800023e0 <reparent+0x4e>
    if(pp->parent == p){
    800023c6:	3104b783          	ld	a5,784(s1)
    800023ca:	ff279ae3          	bne	a5,s2,800023be <reparent+0x2c>
      pp->parent = initproc;
    800023ce:	000a3503          	ld	a0,0(s4)
    800023d2:	30a4b823          	sd	a0,784(s1)
      wakeup(initproc);
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	f3a080e7          	jalr	-198(ra) # 80002310 <wakeup>
    800023de:	b7c5                	j	800023be <reparent+0x2c>
}
    800023e0:	70a2                	ld	ra,40(sp)
    800023e2:	7402                	ld	s0,32(sp)
    800023e4:	64e2                	ld	s1,24(sp)
    800023e6:	6942                	ld	s2,16(sp)
    800023e8:	69a2                	ld	s3,8(sp)
    800023ea:	6a02                	ld	s4,0(sp)
    800023ec:	6145                	addi	sp,sp,48
    800023ee:	8082                	ret

00000000800023f0 <exit>:
{
    800023f0:	7179                	addi	sp,sp,-48
    800023f2:	f406                	sd	ra,40(sp)
    800023f4:	f022                	sd	s0,32(sp)
    800023f6:	ec26                	sd	s1,24(sp)
    800023f8:	e84a                	sd	s2,16(sp)
    800023fa:	e44e                	sd	s3,8(sp)
    800023fc:	e052                	sd	s4,0(sp)
    800023fe:	1800                	addi	s0,sp,48
    80002400:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	63c080e7          	jalr	1596(ra) # 80001a3e <myproc>
    8000240a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000240c:	00007797          	auipc	a5,0x7
    80002410:	c1c7b783          	ld	a5,-996(a5) # 80009028 <initproc>
    80002414:	3a850493          	addi	s1,a0,936
    80002418:	42850913          	addi	s2,a0,1064
    8000241c:	02a79363          	bne	a5,a0,80002442 <exit+0x52>
    panic("init exiting");
    80002420:	00006517          	auipc	a0,0x6
    80002424:	df850513          	addi	a0,a0,-520 # 80008218 <digits+0x1d8>
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	114080e7          	jalr	276(ra) # 8000053c <panic>
      fileclose(f);
    80002430:	00002097          	auipc	ra,0x2
    80002434:	580080e7          	jalr	1408(ra) # 800049b0 <fileclose>
      p->ofile[fd] = 0;
    80002438:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000243c:	04a1                	addi	s1,s1,8
    8000243e:	01248563          	beq	s1,s2,80002448 <exit+0x58>
    if(p->ofile[fd]){
    80002442:	6088                	ld	a0,0(s1)
    80002444:	f575                	bnez	a0,80002430 <exit+0x40>
    80002446:	bfdd                	j	8000243c <exit+0x4c>
  begin_op();
    80002448:	00002097          	auipc	ra,0x2
    8000244c:	09c080e7          	jalr	156(ra) # 800044e4 <begin_op>
  iput(p->cwd);
    80002450:	4289b503          	ld	a0,1064(s3)
    80002454:	00002097          	auipc	ra,0x2
    80002458:	86e080e7          	jalr	-1938(ra) # 80003cc2 <iput>
  end_op();
    8000245c:	00002097          	auipc	ra,0x2
    80002460:	106080e7          	jalr	262(ra) # 80004562 <end_op>
  p->cwd = 0;
    80002464:	4209b423          	sd	zero,1064(s3)
  acquire(&wait_lock);
    80002468:	0000f497          	auipc	s1,0xf
    8000246c:	e5048493          	addi	s1,s1,-432 # 800112b8 <wait_lock>
    80002470:	8526                	mv	a0,s1
    80002472:	ffffe097          	auipc	ra,0xffffe
    80002476:	7aa080e7          	jalr	1962(ra) # 80000c1c <acquire>
  reparent(p);
    8000247a:	854e                	mv	a0,s3
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	f16080e7          	jalr	-234(ra) # 80002392 <reparent>
  wakeup(p->parent);
    80002484:	3109b503          	ld	a0,784(s3)
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	e88080e7          	jalr	-376(ra) # 80002310 <wakeup>
  acquire(&p->lock);
    80002490:	2d898513          	addi	a0,s3,728
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	788080e7          	jalr	1928(ra) # 80000c1c <acquire>
  p->xstate = status;
    8000249c:	3149a223          	sw	s4,772(s3)
  p->state = ZOMBIE;
    800024a0:	4795                	li	a5,5
    800024a2:	2ef9a823          	sw	a5,752(s3)
  release(&wait_lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	828080e7          	jalr	-2008(ra) # 80000cd0 <release>
  sched();
    800024b0:	00000097          	auipc	ra,0x0
    800024b4:	b98080e7          	jalr	-1128(ra) # 80002048 <sched>
  panic("zombie exit");
    800024b8:	00006517          	auipc	a0,0x6
    800024bc:	d7050513          	addi	a0,a0,-656 # 80008228 <digits+0x1e8>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	07c080e7          	jalr	124(ra) # 8000053c <panic>

00000000800024c8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024c8:	7179                	addi	sp,sp,-48
    800024ca:	f406                	sd	ra,40(sp)
    800024cc:	f022                	sd	s0,32(sp)
    800024ce:	ec26                	sd	s1,24(sp)
    800024d0:	e84a                	sd	s2,16(sp)
    800024d2:	e44e                	sd	s3,8(sp)
    800024d4:	e052                	sd	s4,0(sp)
    800024d6:	1800                	addi	s0,sp,48
    800024d8:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024da:	0000f497          	auipc	s1,0xf
    800024de:	20e48493          	addi	s1,s1,526 # 800116e8 <proc>
    800024e2:	00020a17          	auipc	s4,0x20
    800024e6:	206a0a13          	addi	s4,s4,518 # 800226e8 <mmr_list>
    acquire(&p->lock);
    800024ea:	2d848913          	addi	s2,s1,728
    800024ee:	854a                	mv	a0,s2
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	72c080e7          	jalr	1836(ra) # 80000c1c <acquire>
    if(p->pid == pid){
    800024f8:	3084a783          	lw	a5,776(s1)
    800024fc:	01378d63          	beq	a5,s3,80002516 <kill+0x4e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002500:	854a                	mv	a0,s2
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	7ce080e7          	jalr	1998(ra) # 80000cd0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000250a:	44048493          	addi	s1,s1,1088
    8000250e:	fd449ee3          	bne	s1,s4,800024ea <kill+0x22>
  }
  return -1;
    80002512:	557d                	li	a0,-1
    80002514:	a839                	j	80002532 <kill+0x6a>
      p->killed = 1;
    80002516:	4785                	li	a5,1
    80002518:	30f4a023          	sw	a5,768(s1)
      if(p->state == SLEEPING){
    8000251c:	2f04a703          	lw	a4,752(s1)
    80002520:	4789                	li	a5,2
    80002522:	02f70063          	beq	a4,a5,80002542 <kill+0x7a>
      release(&p->lock);
    80002526:	854a                	mv	a0,s2
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	7a8080e7          	jalr	1960(ra) # 80000cd0 <release>
      return 0;
    80002530:	4501                	li	a0,0
}
    80002532:	70a2                	ld	ra,40(sp)
    80002534:	7402                	ld	s0,32(sp)
    80002536:	64e2                	ld	s1,24(sp)
    80002538:	6942                	ld	s2,16(sp)
    8000253a:	69a2                	ld	s3,8(sp)
    8000253c:	6a02                	ld	s4,0(sp)
    8000253e:	6145                	addi	sp,sp,48
    80002540:	8082                	ret
        p->state = RUNNABLE;
    80002542:	478d                	li	a5,3
    80002544:	2ef4a823          	sw	a5,752(s1)
    80002548:	bff9                	j	80002526 <kill+0x5e>

000000008000254a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	e052                	sd	s4,0(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	84aa                	mv	s1,a0
    8000255c:	892e                	mv	s2,a1
    8000255e:	89b2                	mv	s3,a2
    80002560:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	4dc080e7          	jalr	1244(ra) # 80001a3e <myproc>
  if(user_dst){
    8000256a:	c095                	beqz	s1,8000258e <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    8000256c:	86d2                	mv	a3,s4
    8000256e:	864e                	mv	a2,s3
    80002570:	85ca                	mv	a1,s2
    80002572:	32853503          	ld	a0,808(a0)
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	10e080e7          	jalr	270(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000257e:	70a2                	ld	ra,40(sp)
    80002580:	7402                	ld	s0,32(sp)
    80002582:	64e2                	ld	s1,24(sp)
    80002584:	6942                	ld	s2,16(sp)
    80002586:	69a2                	ld	s3,8(sp)
    80002588:	6a02                	ld	s4,0(sp)
    8000258a:	6145                	addi	sp,sp,48
    8000258c:	8082                	ret
    memmove((char *)dst, src, len);
    8000258e:	000a061b          	sext.w	a2,s4
    80002592:	85ce                	mv	a1,s3
    80002594:	854a                	mv	a0,s2
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	7de080e7          	jalr	2014(ra) # 80000d74 <memmove>
    return 0;
    8000259e:	8526                	mv	a0,s1
    800025a0:	bff9                	j	8000257e <either_copyout+0x34>

00000000800025a2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025a2:	7179                	addi	sp,sp,-48
    800025a4:	f406                	sd	ra,40(sp)
    800025a6:	f022                	sd	s0,32(sp)
    800025a8:	ec26                	sd	s1,24(sp)
    800025aa:	e84a                	sd	s2,16(sp)
    800025ac:	e44e                	sd	s3,8(sp)
    800025ae:	e052                	sd	s4,0(sp)
    800025b0:	1800                	addi	s0,sp,48
    800025b2:	892a                	mv	s2,a0
    800025b4:	84ae                	mv	s1,a1
    800025b6:	89b2                	mv	s3,a2
    800025b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	484080e7          	jalr	1156(ra) # 80001a3e <myproc>
  if(user_src){
    800025c2:	c095                	beqz	s1,800025e6 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    800025c4:	86d2                	mv	a3,s4
    800025c6:	864e                	mv	a2,s3
    800025c8:	85ca                	mv	a1,s2
    800025ca:	32853503          	ld	a0,808(a0)
    800025ce:	fffff097          	auipc	ra,0xfffff
    800025d2:	142080e7          	jalr	322(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025d6:	70a2                	ld	ra,40(sp)
    800025d8:	7402                	ld	s0,32(sp)
    800025da:	64e2                	ld	s1,24(sp)
    800025dc:	6942                	ld	s2,16(sp)
    800025de:	69a2                	ld	s3,8(sp)
    800025e0:	6a02                	ld	s4,0(sp)
    800025e2:	6145                	addi	sp,sp,48
    800025e4:	8082                	ret
    memmove(dst, (char*)src, len);
    800025e6:	000a061b          	sext.w	a2,s4
    800025ea:	85ce                	mv	a1,s3
    800025ec:	854a                	mv	a0,s2
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	786080e7          	jalr	1926(ra) # 80000d74 <memmove>
    return 0;
    800025f6:	8526                	mv	a0,s1
    800025f8:	bff9                	j	800025d6 <either_copyin+0x34>

00000000800025fa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025fa:	715d                	addi	sp,sp,-80
    800025fc:	e486                	sd	ra,72(sp)
    800025fe:	e0a2                	sd	s0,64(sp)
    80002600:	fc26                	sd	s1,56(sp)
    80002602:	f84a                	sd	s2,48(sp)
    80002604:	f44e                	sd	s3,40(sp)
    80002606:	f052                	sd	s4,32(sp)
    80002608:	ec56                	sd	s5,24(sp)
    8000260a:	e85a                	sd	s6,16(sp)
    8000260c:	e45e                	sd	s7,8(sp)
    8000260e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002610:	00006517          	auipc	a0,0x6
    80002614:	ab850513          	addi	a0,a0,-1352 # 800080c8 <digits+0x88>
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f6e080e7          	jalr	-146(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	0000f497          	auipc	s1,0xf
    80002624:	4f848493          	addi	s1,s1,1272 # 80011b18 <proc+0x430>
    80002628:	00020917          	auipc	s2,0x20
    8000262c:	4f090913          	addi	s2,s2,1264 # 80022b18 <mmr_list+0x430>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002630:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002632:	00006997          	auipc	s3,0x6
    80002636:	c0698993          	addi	s3,s3,-1018 # 80008238 <digits+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    8000263a:	00006a97          	auipc	s5,0x6
    8000263e:	c06a8a93          	addi	s5,s5,-1018 # 80008240 <digits+0x200>
    printf("\n");
    80002642:	00006a17          	auipc	s4,0x6
    80002646:	a86a0a13          	addi	s4,s4,-1402 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264a:	00006b97          	auipc	s7,0x6
    8000264e:	c3eb8b93          	addi	s7,s7,-962 # 80008288 <states.0>
    80002652:	a00d                	j	80002674 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002654:	ed86a583          	lw	a1,-296(a3)
    80002658:	8556                	mv	a0,s5
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	f2c080e7          	jalr	-212(ra) # 80000586 <printf>
    printf("\n");
    80002662:	8552                	mv	a0,s4
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	f22080e7          	jalr	-222(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000266c:	44048493          	addi	s1,s1,1088
    80002670:	03248263          	beq	s1,s2,80002694 <procdump+0x9a>
    if(p->state == UNUSED)
    80002674:	86a6                	mv	a3,s1
    80002676:	ec04a783          	lw	a5,-320(s1)
    8000267a:	dbed                	beqz	a5,8000266c <procdump+0x72>
      state = "???";
    8000267c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000267e:	fcfb6be3          	bltu	s6,a5,80002654 <procdump+0x5a>
    80002682:	02079713          	slli	a4,a5,0x20
    80002686:	01d75793          	srli	a5,a4,0x1d
    8000268a:	97de                	add	a5,a5,s7
    8000268c:	6390                	ld	a2,0(a5)
    8000268e:	f279                	bnez	a2,80002654 <procdump+0x5a>
      state = "???";
    80002690:	864e                	mv	a2,s3
    80002692:	b7c9                	j	80002654 <procdump+0x5a>
  }
}
    80002694:	60a6                	ld	ra,72(sp)
    80002696:	6406                	ld	s0,64(sp)
    80002698:	74e2                	ld	s1,56(sp)
    8000269a:	7942                	ld	s2,48(sp)
    8000269c:	79a2                	ld	s3,40(sp)
    8000269e:	7a02                	ld	s4,32(sp)
    800026a0:	6ae2                	ld	s5,24(sp)
    800026a2:	6b42                	ld	s6,16(sp)
    800026a4:	6ba2                	ld	s7,8(sp)
    800026a6:	6161                	addi	sp,sp,80
    800026a8:	8082                	ret

00000000800026aa <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    800026aa:	7119                	addi	sp,sp,-128
    800026ac:	fc86                	sd	ra,120(sp)
    800026ae:	f8a2                	sd	s0,112(sp)
    800026b0:	f4a6                	sd	s1,104(sp)
    800026b2:	f0ca                	sd	s2,96(sp)
    800026b4:	ecce                	sd	s3,88(sp)
    800026b6:	e8d2                	sd	s4,80(sp)
    800026b8:	e4d6                	sd	s5,72(sp)
    800026ba:	e0da                	sd	s6,64(sp)
    800026bc:	fc5e                	sd	s7,56(sp)
    800026be:	0100                	addi	s0,sp,128
    800026c0:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	37c080e7          	jalr	892(ra) # 80001a3e <myproc>
    800026ca:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    800026cc:	0000f917          	auipc	s2,0xf
    800026d0:	44c90913          	addi	s2,s2,1100 # 80011b18 <proc+0x430>
    800026d4:	00020a17          	auipc	s4,0x20
    800026d8:	444a0a13          	addi	s4,s4,1092 # 80022b18 <mmr_list+0x430>
  int nprocs = 0;
    800026dc:	4a81                	li	s5,0
    procinfo.state = p->state;
    procinfo.size = p->sz;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    800026de:	4b81                	li	s7,0
    800026e0:	fac40493          	addi	s1,s0,-84
    800026e4:	a089                	j	80002726 <procinfo+0x7c>
    800026e6:	f8f42c23          	sw	a5,-104(s0)
    for (int i=0; i<16; i++)
    800026ea:	f9c40793          	addi	a5,s0,-100
      procinfo.ppid = 0;
    800026ee:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    800026f0:	00074683          	lbu	a3,0(a4)
    800026f4:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    800026f8:	0705                	addi	a4,a4,1
    800026fa:	0785                	addi	a5,a5,1
    800026fc:	fe979ae3          	bne	a5,s1,800026f0 <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    80002700:	02800693          	li	a3,40
    80002704:	f8840613          	addi	a2,s0,-120
    80002708:	85ce                	mv	a1,s3
    8000270a:	328b3503          	ld	a0,808(s6)
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	f76080e7          	jalr	-138(ra) # 80001684 <copyout>
    80002716:	02054d63          	bltz	a0,80002750 <procinfo+0xa6>
      return -1;
    addr += sizeof(procinfo);
    8000271a:	02898993          	addi	s3,s3,40
  for(p = proc; p < &proc[NPROC]; p++){ 
    8000271e:	44090913          	addi	s2,s2,1088
    80002722:	03490863          	beq	s2,s4,80002752 <procinfo+0xa8>
    if(p->state == UNUSED)
    80002726:	ec092783          	lw	a5,-320(s2)
    8000272a:	dbf5                	beqz	a5,8000271e <procinfo+0x74>
    nprocs++;
    8000272c:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    8000272e:	ed892703          	lw	a4,-296(s2)
    80002732:	f8e42423          	sw	a4,-120(s0)
    procinfo.state = p->state;
    80002736:	f8f42623          	sw	a5,-116(s0)
    procinfo.size = p->sz;
    8000273a:	ef093783          	ld	a5,-272(s2)
    8000273e:	f8f43823          	sd	a5,-112(s0)
    if (p->parent)
    80002742:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    80002746:	87de                	mv	a5,s7
    if (p->parent)
    80002748:	df59                	beqz	a4,800026e6 <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    8000274a:	30872783          	lw	a5,776(a4)
    8000274e:	bf61                	j	800026e6 <procinfo+0x3c>
      return -1;
    80002750:	5afd                	li	s5,-1
  }
  return nprocs;
}
    80002752:	8556                	mv	a0,s5
    80002754:	70e6                	ld	ra,120(sp)
    80002756:	7446                	ld	s0,112(sp)
    80002758:	74a6                	ld	s1,104(sp)
    8000275a:	7906                	ld	s2,96(sp)
    8000275c:	69e6                	ld	s3,88(sp)
    8000275e:	6a46                	ld	s4,80(sp)
    80002760:	6aa6                	ld	s5,72(sp)
    80002762:	6b06                	ld	s6,64(sp)
    80002764:	7be2                	ld	s7,56(sp)
    80002766:	6109                	addi	sp,sp,128
    80002768:	8082                	ret

000000008000276a <mmrlistinit>:

// HW5 - Task 1a
// Initialize mmr_list
void
mmrlistinit(void)
{
    8000276a:	7179                	addi	sp,sp,-48
    8000276c:	f406                	sd	ra,40(sp)
    8000276e:	f022                	sd	s0,32(sp)
    80002770:	ec26                	sd	s1,24(sp)
    80002772:	e84a                	sd	s2,16(sp)
    80002774:	e44e                	sd	s3,8(sp)
    80002776:	1800                	addi	s0,sp,48
  struct mmr_list *pmmrlist;
  initlock(&listid_lock,"listid");
    80002778:	00006597          	auipc	a1,0x6
    8000277c:	ad858593          	addi	a1,a1,-1320 # 80008250 <digits+0x210>
    80002780:	0000f517          	auipc	a0,0xf
    80002784:	f5050513          	addi	a0,a0,-176 # 800116d0 <listid_lock>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	404080e7          	jalr	1028(ra) # 80000b8c <initlock>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    80002790:	00020497          	auipc	s1,0x20
    80002794:	f5848493          	addi	s1,s1,-168 # 800226e8 <mmr_list>
    initlock(&pmmrlist->lock, "mmrlist");
    80002798:	00006997          	auipc	s3,0x6
    8000279c:	ac098993          	addi	s3,s3,-1344 # 80008258 <digits+0x218>
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    800027a0:	00025917          	auipc	s2,0x25
    800027a4:	f4890913          	addi	s2,s2,-184 # 800276e8 <tickslock>
    initlock(&pmmrlist->lock, "mmrlist");
    800027a8:	85ce                	mv	a1,s3
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	3e0080e7          	jalr	992(ra) # 80000b8c <initlock>
    pmmrlist->valid = 0;
    800027b4:	0004ac23          	sw	zero,24(s1)
  for (pmmrlist = mmr_list; pmmrlist < &mmr_list[NPROC*MAX_MMR]; pmmrlist++) {
    800027b8:	02048493          	addi	s1,s1,32
    800027bc:	ff2496e3          	bne	s1,s2,800027a8 <mmrlistinit+0x3e>
  }
}
    800027c0:	70a2                	ld	ra,40(sp)
    800027c2:	7402                	ld	s0,32(sp)
    800027c4:	64e2                	ld	s1,24(sp)
    800027c6:	6942                	ld	s2,16(sp)
    800027c8:	69a2                	ld	s3,8(sp)
    800027ca:	6145                	addi	sp,sp,48
    800027cc:	8082                	ret

00000000800027ce <get_mmr_list>:

// find the mmr_list for a given listid
struct mmr_list*
get_mmr_list(int listid) {
    800027ce:	1101                	addi	sp,sp,-32
    800027d0:	ec06                	sd	ra,24(sp)
    800027d2:	e822                	sd	s0,16(sp)
    800027d4:	e426                	sd	s1,8(sp)
    800027d6:	1000                	addi	s0,sp,32
    800027d8:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    800027da:	0000f517          	auipc	a0,0xf
    800027de:	ef650513          	addi	a0,a0,-266 # 800116d0 <listid_lock>
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	43a080e7          	jalr	1082(ra) # 80000c1c <acquire>
  if (listid >=0 && listid < NPROC*MAX_MMR && mmr_list[listid].valid) {
    800027ea:	0004871b          	sext.w	a4,s1
    800027ee:	27f00793          	li	a5,639
    800027f2:	02e7eb63          	bltu	a5,a4,80002828 <get_mmr_list+0x5a>
    800027f6:	00549713          	slli	a4,s1,0x5
    800027fa:	00020797          	auipc	a5,0x20
    800027fe:	eee78793          	addi	a5,a5,-274 # 800226e8 <mmr_list>
    80002802:	97ba                	add	a5,a5,a4
    80002804:	4f9c                	lw	a5,24(a5)
    80002806:	c38d                	beqz	a5,80002828 <get_mmr_list+0x5a>
    release(&listid_lock);
    80002808:	0000f517          	auipc	a0,0xf
    8000280c:	ec850513          	addi	a0,a0,-312 # 800116d0 <listid_lock>
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	4c0080e7          	jalr	1216(ra) # 80000cd0 <release>
    return(&mmr_list[listid]);
    80002818:	00549513          	slli	a0,s1,0x5
    8000281c:	00020797          	auipc	a5,0x20
    80002820:	ecc78793          	addi	a5,a5,-308 # 800226e8 <mmr_list>
    80002824:	953e                	add	a0,a0,a5
    80002826:	a811                	j	8000283a <get_mmr_list+0x6c>
  }
  else {
    release(&listid_lock);
    80002828:	0000f517          	auipc	a0,0xf
    8000282c:	ea850513          	addi	a0,a0,-344 # 800116d0 <listid_lock>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	4a0080e7          	jalr	1184(ra) # 80000cd0 <release>
    return 0;
    80002838:	4501                	li	a0,0
  }
}
    8000283a:	60e2                	ld	ra,24(sp)
    8000283c:	6442                	ld	s0,16(sp)
    8000283e:	64a2                	ld	s1,8(sp)
    80002840:	6105                	addi	sp,sp,32
    80002842:	8082                	ret

0000000080002844 <dealloc_mmr_listid>:

// free up entry in mmr_list array
void
dealloc_mmr_listid(int listid) {
    80002844:	1101                	addi	sp,sp,-32
    80002846:	ec06                	sd	ra,24(sp)
    80002848:	e822                	sd	s0,16(sp)
    8000284a:	e426                	sd	s1,8(sp)
    8000284c:	e04a                	sd	s2,0(sp)
    8000284e:	1000                	addi	s0,sp,32
    80002850:	84aa                	mv	s1,a0
  acquire(&listid_lock);
    80002852:	0000f917          	auipc	s2,0xf
    80002856:	e7e90913          	addi	s2,s2,-386 # 800116d0 <listid_lock>
    8000285a:	854a                	mv	a0,s2
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	3c0080e7          	jalr	960(ra) # 80000c1c <acquire>
  mmr_list[listid].valid = 0;
    80002864:	0496                	slli	s1,s1,0x5
    80002866:	00020797          	auipc	a5,0x20
    8000286a:	e8278793          	addi	a5,a5,-382 # 800226e8 <mmr_list>
    8000286e:	97a6                	add	a5,a5,s1
    80002870:	0007ac23          	sw	zero,24(a5)
  release(&listid_lock);
    80002874:	854a                	mv	a0,s2
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	45a080e7          	jalr	1114(ra) # 80000cd0 <release>
}
    8000287e:	60e2                	ld	ra,24(sp)
    80002880:	6442                	ld	s0,16(sp)
    80002882:	64a2                	ld	s1,8(sp)
    80002884:	6902                	ld	s2,0(sp)
    80002886:	6105                	addi	sp,sp,32
    80002888:	8082                	ret

000000008000288a <alloc_mmr_listid>:

// find an unused entry in the mmr_list array
int
alloc_mmr_listid() {
    8000288a:	1101                	addi	sp,sp,-32
    8000288c:	ec06                	sd	ra,24(sp)
    8000288e:	e822                	sd	s0,16(sp)
    80002890:	e426                	sd	s1,8(sp)
    80002892:	1000                	addi	s0,sp,32
  acquire(&listid_lock);
    80002894:	0000f517          	auipc	a0,0xf
    80002898:	e3c50513          	addi	a0,a0,-452 # 800116d0 <listid_lock>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	380080e7          	jalr	896(ra) # 80000c1c <acquire>
  int listid = -1;
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    800028a4:	00020797          	auipc	a5,0x20
    800028a8:	e5c78793          	addi	a5,a5,-420 # 80022700 <mmr_list+0x18>
    800028ac:	4481                	li	s1,0
    800028ae:	28000693          	li	a3,640
    if (mmr_list[i].valid == 0) {
    800028b2:	4398                	lw	a4,0(a5)
    800028b4:	cb01                	beqz	a4,800028c4 <alloc_mmr_listid+0x3a>
  for (int i = 0; i < NPROC*MAX_MMR; i++) {
    800028b6:	2485                	addiw	s1,s1,1
    800028b8:	02078793          	addi	a5,a5,32
    800028bc:	fed49be3          	bne	s1,a3,800028b2 <alloc_mmr_listid+0x28>
  int listid = -1;
    800028c0:	54fd                	li	s1,-1
    800028c2:	a811                	j	800028d6 <alloc_mmr_listid+0x4c>
      mmr_list[i].valid = 1;
    800028c4:	00549713          	slli	a4,s1,0x5
    800028c8:	00020797          	auipc	a5,0x20
    800028cc:	e2078793          	addi	a5,a5,-480 # 800226e8 <mmr_list>
    800028d0:	97ba                	add	a5,a5,a4
    800028d2:	4705                	li	a4,1
    800028d4:	cf98                	sw	a4,24(a5)
      listid = i;
      break;
    }
  }
  release(&listid_lock);
    800028d6:	0000f517          	auipc	a0,0xf
    800028da:	dfa50513          	addi	a0,a0,-518 # 800116d0 <listid_lock>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	3f2080e7          	jalr	1010(ra) # 80000cd0 <release>
  return(listid);
    800028e6:	8526                	mv	a0,s1
    800028e8:	60e2                	ld	ra,24(sp)
    800028ea:	6442                	ld	s0,16(sp)
    800028ec:	64a2                	ld	s1,8(sp)
    800028ee:	6105                	addi	sp,sp,32
    800028f0:	8082                	ret

00000000800028f2 <swtch>:
    800028f2:	00153023          	sd	ra,0(a0)
    800028f6:	00253423          	sd	sp,8(a0)
    800028fa:	e900                	sd	s0,16(a0)
    800028fc:	ed04                	sd	s1,24(a0)
    800028fe:	03253023          	sd	s2,32(a0)
    80002902:	03353423          	sd	s3,40(a0)
    80002906:	03453823          	sd	s4,48(a0)
    8000290a:	03553c23          	sd	s5,56(a0)
    8000290e:	05653023          	sd	s6,64(a0)
    80002912:	05753423          	sd	s7,72(a0)
    80002916:	05853823          	sd	s8,80(a0)
    8000291a:	05953c23          	sd	s9,88(a0)
    8000291e:	07a53023          	sd	s10,96(a0)
    80002922:	07b53423          	sd	s11,104(a0)
    80002926:	0005b083          	ld	ra,0(a1)
    8000292a:	0085b103          	ld	sp,8(a1)
    8000292e:	6980                	ld	s0,16(a1)
    80002930:	6d84                	ld	s1,24(a1)
    80002932:	0205b903          	ld	s2,32(a1)
    80002936:	0285b983          	ld	s3,40(a1)
    8000293a:	0305ba03          	ld	s4,48(a1)
    8000293e:	0385ba83          	ld	s5,56(a1)
    80002942:	0405bb03          	ld	s6,64(a1)
    80002946:	0485bb83          	ld	s7,72(a1)
    8000294a:	0505bc03          	ld	s8,80(a1)
    8000294e:	0585bc83          	ld	s9,88(a1)
    80002952:	0605bd03          	ld	s10,96(a1)
    80002956:	0685bd83          	ld	s11,104(a1)
    8000295a:	8082                	ret

000000008000295c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000295c:	1141                	addi	sp,sp,-16
    8000295e:	e406                	sd	ra,8(sp)
    80002960:	e022                	sd	s0,0(sp)
    80002962:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002964:	00006597          	auipc	a1,0x6
    80002968:	95458593          	addi	a1,a1,-1708 # 800082b8 <states.0+0x30>
    8000296c:	00025517          	auipc	a0,0x25
    80002970:	d7c50513          	addi	a0,a0,-644 # 800276e8 <tickslock>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	218080e7          	jalr	536(ra) # 80000b8c <initlock>
}
    8000297c:	60a2                	ld	ra,8(sp)
    8000297e:	6402                	ld	s0,0(sp)
    80002980:	0141                	addi	sp,sp,16
    80002982:	8082                	ret

0000000080002984 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002984:	1141                	addi	sp,sp,-16
    80002986:	e422                	sd	s0,8(sp)
    80002988:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000298a:	00004797          	auipc	a5,0x4
    8000298e:	91678793          	addi	a5,a5,-1770 # 800062a0 <kernelvec>
    80002992:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002996:	6422                	ld	s0,8(sp)
    80002998:	0141                	addi	sp,sp,16
    8000299a:	8082                	ret

000000008000299c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000299c:	1141                	addi	sp,sp,-16
    8000299e:	e406                	sd	ra,8(sp)
    800029a0:	e022                	sd	s0,0(sp)
    800029a2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029a4:	fffff097          	auipc	ra,0xfffff
    800029a8:	09a080e7          	jalr	154(ra) # 80001a3e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029b6:	00004697          	auipc	a3,0x4
    800029ba:	64a68693          	addi	a3,a3,1610 # 80007000 <_trampoline>
    800029be:	00004717          	auipc	a4,0x4
    800029c2:	64270713          	addi	a4,a4,1602 # 80007000 <_trampoline>
    800029c6:	8f15                	sub	a4,a4,a3
    800029c8:	040007b7          	lui	a5,0x4000
    800029cc:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029ce:	07b2                	slli	a5,a5,0xc
    800029d0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d2:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029d6:	33053703          	ld	a4,816(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029da:	18002673          	csrr	a2,satp
    800029de:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e0:	33053603          	ld	a2,816(a0)
    800029e4:	31853703          	ld	a4,792(a0)
    800029e8:	6585                	lui	a1,0x1
    800029ea:	972e                	add	a4,a4,a1
    800029ec:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ee:	33053703          	ld	a4,816(a0)
    800029f2:	00000617          	auipc	a2,0x0
    800029f6:	13e60613          	addi	a2,a2,318 # 80002b30 <usertrap>
    800029fa:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029fc:	33053703          	ld	a4,816(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a00:	8612                	mv	a2,tp
    80002a02:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a04:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a08:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a0c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a10:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a14:	33053703          	ld	a4,816(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a18:	6f18                	ld	a4,24(a4)
    80002a1a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a1e:	32853583          	ld	a1,808(a0)
    80002a22:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a24:	00004717          	auipc	a4,0x4
    80002a28:	66c70713          	addi	a4,a4,1644 # 80007090 <userret>
    80002a2c:	8f15                	sub	a4,a4,a3
    80002a2e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a30:	577d                	li	a4,-1
    80002a32:	177e                	slli	a4,a4,0x3f
    80002a34:	8dd9                	or	a1,a1,a4
    80002a36:	02000537          	lui	a0,0x2000
    80002a3a:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a3c:	0536                	slli	a0,a0,0xd
    80002a3e:	9782                	jalr	a5
}
    80002a40:	60a2                	ld	ra,8(sp)
    80002a42:	6402                	ld	s0,0(sp)
    80002a44:	0141                	addi	sp,sp,16
    80002a46:	8082                	ret

0000000080002a48 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a48:	1101                	addi	sp,sp,-32
    80002a4a:	ec06                	sd	ra,24(sp)
    80002a4c:	e822                	sd	s0,16(sp)
    80002a4e:	e426                	sd	s1,8(sp)
    80002a50:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a52:	00025497          	auipc	s1,0x25
    80002a56:	c9648493          	addi	s1,s1,-874 # 800276e8 <tickslock>
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	1c0080e7          	jalr	448(ra) # 80000c1c <acquire>
  ticks++;
    80002a64:	00006517          	auipc	a0,0x6
    80002a68:	5cc50513          	addi	a0,a0,1484 # 80009030 <ticks>
    80002a6c:	411c                	lw	a5,0(a0)
    80002a6e:	2785                	addiw	a5,a5,1
    80002a70:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	89e080e7          	jalr	-1890(ra) # 80002310 <wakeup>
  release(&tickslock);
    80002a7a:	8526                	mv	a0,s1
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	254080e7          	jalr	596(ra) # 80000cd0 <release>
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6105                	addi	sp,sp,32
    80002a8c:	8082                	ret

0000000080002a8e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a8e:	1101                	addi	sp,sp,-32
    80002a90:	ec06                	sd	ra,24(sp)
    80002a92:	e822                	sd	s0,16(sp)
    80002a94:	e426                	sd	s1,8(sp)
    80002a96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a98:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a9c:	00074d63          	bltz	a4,80002ab6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aa0:	57fd                	li	a5,-1
    80002aa2:	17fe                	slli	a5,a5,0x3f
    80002aa4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aa6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa8:	06f70363          	beq	a4,a5,80002b0e <devintr+0x80>
  }
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret
     (scause & 0xff) == 9){
    80002ab6:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002aba:	46a5                	li	a3,9
    80002abc:	fed792e3          	bne	a5,a3,80002aa0 <devintr+0x12>
    int irq = plic_claim();
    80002ac0:	00004097          	auipc	ra,0x4
    80002ac4:	8e8080e7          	jalr	-1816(ra) # 800063a8 <plic_claim>
    80002ac8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aca:	47a9                	li	a5,10
    80002acc:	02f50763          	beq	a0,a5,80002afa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ad0:	4785                	li	a5,1
    80002ad2:	02f50963          	beq	a0,a5,80002b04 <devintr+0x76>
    return 1;
    80002ad6:	4505                	li	a0,1
    } else if(irq){
    80002ad8:	d8f1                	beqz	s1,80002aac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ada:	85a6                	mv	a1,s1
    80002adc:	00005517          	auipc	a0,0x5
    80002ae0:	7e450513          	addi	a0,a0,2020 # 800082c0 <states.0+0x38>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	aa2080e7          	jalr	-1374(ra) # 80000586 <printf>
      plic_complete(irq);
    80002aec:	8526                	mv	a0,s1
    80002aee:	00004097          	auipc	ra,0x4
    80002af2:	8de080e7          	jalr	-1826(ra) # 800063cc <plic_complete>
    return 1;
    80002af6:	4505                	li	a0,1
    80002af8:	bf55                	j	80002aac <devintr+0x1e>
      uartintr();
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	e9a080e7          	jalr	-358(ra) # 80000994 <uartintr>
    80002b02:	b7ed                	j	80002aec <devintr+0x5e>
      virtio_disk_intr();
    80002b04:	00004097          	auipc	ra,0x4
    80002b08:	d54080e7          	jalr	-684(ra) # 80006858 <virtio_disk_intr>
    80002b0c:	b7c5                	j	80002aec <devintr+0x5e>
    if(cpuid() == 0){
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	f04080e7          	jalr	-252(ra) # 80001a12 <cpuid>
    80002b16:	c901                	beqz	a0,80002b26 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b18:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b1e:	14479073          	csrw	sip,a5
    return 2;
    80002b22:	4509                	li	a0,2
    80002b24:	b761                	j	80002aac <devintr+0x1e>
      clockintr();
    80002b26:	00000097          	auipc	ra,0x0
    80002b2a:	f22080e7          	jalr	-222(ra) # 80002a48 <clockintr>
    80002b2e:	b7ed                	j	80002b18 <devintr+0x8a>

0000000080002b30 <usertrap>:
{
    80002b30:	715d                	addi	sp,sp,-80
    80002b32:	e486                	sd	ra,72(sp)
    80002b34:	e0a2                	sd	s0,64(sp)
    80002b36:	fc26                	sd	s1,56(sp)
    80002b38:	f84a                	sd	s2,48(sp)
    80002b3a:	f44e                	sd	s3,40(sp)
    80002b3c:	f052                	sd	s4,32(sp)
    80002b3e:	ec56                	sd	s5,24(sp)
    80002b40:	e85a                	sd	s6,16(sp)
    80002b42:	e45e                	sd	s7,8(sp)
    80002b44:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b46:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b4a:	1007f793          	andi	a5,a5,256
    80002b4e:	ebbd                	bnez	a5,80002bc4 <usertrap+0x94>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b50:	00003797          	auipc	a5,0x3
    80002b54:	75078793          	addi	a5,a5,1872 # 800062a0 <kernelvec>
    80002b58:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	ee2080e7          	jalr	-286(ra) # 80001a3e <myproc>
    80002b64:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b66:	33053783          	ld	a5,816(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6a:	14102773          	csrr	a4,sepc
    80002b6e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b70:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b74:	47a1                	li	a5,8
    80002b76:	06f71563          	bne	a4,a5,80002be0 <usertrap+0xb0>
    if(p->killed)
    80002b7a:	30052783          	lw	a5,768(a0)
    80002b7e:	ebb9                	bnez	a5,80002bd4 <usertrap+0xa4>
    p->trapframe->epc += 4;
    80002b80:	3304b703          	ld	a4,816(s1)
    80002b84:	6f1c                	ld	a5,24(a4)
    80002b86:	0791                	addi	a5,a5,4
    80002b88:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b8e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b92:	10079073          	csrw	sstatus,a5
    syscall();
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	41a080e7          	jalr	1050(ra) # 80002fb0 <syscall>
  if(p->killed)
    80002b9e:	3004a783          	lw	a5,768(s1)
    80002ba2:	18079e63          	bnez	a5,80002d3e <usertrap+0x20e>
  usertrapret();
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	df6080e7          	jalr	-522(ra) # 8000299c <usertrapret>
}
    80002bae:	60a6                	ld	ra,72(sp)
    80002bb0:	6406                	ld	s0,64(sp)
    80002bb2:	74e2                	ld	s1,56(sp)
    80002bb4:	7942                	ld	s2,48(sp)
    80002bb6:	79a2                	ld	s3,40(sp)
    80002bb8:	7a02                	ld	s4,32(sp)
    80002bba:	6ae2                	ld	s5,24(sp)
    80002bbc:	6b42                	ld	s6,16(sp)
    80002bbe:	6ba2                	ld	s7,8(sp)
    80002bc0:	6161                	addi	sp,sp,80
    80002bc2:	8082                	ret
    panic("usertrap: not from user mode");
    80002bc4:	00005517          	auipc	a0,0x5
    80002bc8:	71c50513          	addi	a0,a0,1820 # 800082e0 <states.0+0x58>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	970080e7          	jalr	-1680(ra) # 8000053c <panic>
      exit(-1);
    80002bd4:	557d                	li	a0,-1
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	81a080e7          	jalr	-2022(ra) # 800023f0 <exit>
    80002bde:	b74d                	j	80002b80 <usertrap+0x50>
  } else if((which_dev = devintr()) != 0){
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	eae080e7          	jalr	-338(ra) # 80002a8e <devintr>
    80002be8:	892a                	mv	s2,a0
    80002bea:	14051663          	bnez	a0,80002d36 <usertrap+0x206>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bee:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15){
    80002bf2:	47b5                	li	a5,13
    80002bf4:	00f70763          	beq	a4,a5,80002c02 <usertrap+0xd2>
    80002bf8:	14202773          	csrr	a4,scause
    80002bfc:	47bd                	li	a5,15
    80002bfe:	10f71063          	bne	a4,a5,80002cfe <usertrap+0x1ce>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c02:	143027f3          	csrr	a5,stval
    if(r_stval() >= p->sz){
    80002c06:	3204b703          	ld	a4,800(s1)
    80002c0a:	06e7ee63          	bltu	a5,a4,80002c86 <usertrap+0x156>
    80002c0e:	8926                	mv	s2,s1
    80002c10:	2d048a13          	addi	s4,s1,720
          if(r_scause() == 13){
    80002c14:	4b35                	li	s6,13
          if(r_scause() == 15){
    80002c16:	4abd                	li	s5,15
              p->killed = 1;
    80002c18:	4b85                	li	s7,1
    80002c1a:	a00d                	j	80002c3c <usertrap+0x10c>
            if((p->mmr[i].prot & PROT_READ) == 0){
    80002c1c:	00c92783          	lw	a5,12(s2)
    80002c20:	8b89                	andi	a5,a5,2
    80002c22:	e3b1                	bnez	a5,80002c66 <usertrap+0x136>
              p->killed = 1;
    80002c24:	3174a023          	sw	s7,768(s1)
              exit(-1);
    80002c28:	557d                	li	a0,-1
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	7c6080e7          	jalr	1990(ra) # 800023f0 <exit>
    80002c32:	a815                	j	80002c66 <usertrap+0x136>
      for(int i=0; i<MAX_MMR; i++){
    80002c34:	04890913          	addi	s2,s2,72
    80002c38:	05490763          	beq	s2,s4,80002c86 <usertrap+0x156>
        if(p->mmr[i].valid && p->mmr[i].addr < r_stval() && p->mmr[i].addr+p->mmr[i].length > r_stval()){
    80002c3c:	89ca                	mv	s3,s2
    80002c3e:	01492783          	lw	a5,20(s2)
    80002c42:	dbed                	beqz	a5,80002c34 <usertrap+0x104>
    80002c44:	00093783          	ld	a5,0(s2)
    80002c48:	14302773          	csrr	a4,stval
    80002c4c:	fee7f4e3          	bgeu	a5,a4,80002c34 <usertrap+0x104>
    80002c50:	143026f3          	csrr	a3,stval
    80002c54:	00892703          	lw	a4,8(s2)
    80002c58:	97ba                	add	a5,a5,a4
    80002c5a:	fcf6fde3          	bgeu	a3,a5,80002c34 <usertrap+0x104>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5e:	142027f3          	csrr	a5,scause
          if(r_scause() == 13){
    80002c62:	fb678de3          	beq	a5,s6,80002c1c <usertrap+0xec>
    80002c66:	142027f3          	csrr	a5,scause
          if(r_scause() == 15){
    80002c6a:	fd5795e3          	bne	a5,s5,80002c34 <usertrap+0x104>
            if((p->mmr[i].prot & PROT_WRITE) == 0){
    80002c6e:	00c9a783          	lw	a5,12(s3)
    80002c72:	8b91                	andi	a5,a5,4
    80002c74:	f3e1                	bnez	a5,80002c34 <usertrap+0x104>
              p->killed = 1;
    80002c76:	3174a023          	sw	s7,768(s1)
              exit(-1);
    80002c7a:	557d                	li	a0,-1
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	774080e7          	jalr	1908(ra) # 800023f0 <exit>
    80002c84:	bf45                	j	80002c34 <usertrap+0x104>
      void *physical_mem = kalloc();
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	e5c080e7          	jalr	-420(ra) # 80000ae2 <kalloc>
    80002c8e:	892a                	mv	s2,a0
      if(physical_mem){
    80002c90:	c531                	beqz	a0,80002cdc <usertrap+0x1ac>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c92:	143025f3          	csrr	a1,stval
        if(mappages(p->pagetable, PGROUNDDOWN(r_stval()), PGSIZE, (uint64)physical_mem, (PTE_R | PTE_W | PTE_X | PTE_U)) < 0){ 
    80002c96:	4779                	li	a4,30
    80002c98:	86aa                	mv	a3,a0
    80002c9a:	6605                	lui	a2,0x1
    80002c9c:	77fd                	lui	a5,0xfffff
    80002c9e:	8dfd                	and	a1,a1,a5
    80002ca0:	3284b503          	ld	a0,808(s1)
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	444080e7          	jalr	1092(ra) # 800010e8 <mappages>
    80002cac:	ee0559e3          	bgez	a0,80002b9e <usertrap+0x6e>
          kfree(physical_mem);
    80002cb0:	854a                	mv	a0,s2
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	d32080e7          	jalr	-718(ra) # 800009e4 <kfree>
          printf("mappages didn't work\n");
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	64650513          	addi	a0,a0,1606 # 80008300 <states.0+0x78>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c4080e7          	jalr	-1852(ra) # 80000586 <printf>
          p->killed = 1;
    80002cca:	4785                	li	a5,1
    80002ccc:	30f4a023          	sw	a5,768(s1)
          exit(-1);
    80002cd0:	557d                	li	a0,-1
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	71e080e7          	jalr	1822(ra) # 800023f0 <exit>
    80002cda:	b5d1                	j	80002b9e <usertrap+0x6e>
      printf("usertrap(): Out of memory\n");
    80002cdc:	00005517          	auipc	a0,0x5
    80002ce0:	63c50513          	addi	a0,a0,1596 # 80008318 <states.0+0x90>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	8a2080e7          	jalr	-1886(ra) # 80000586 <printf>
        p->killed = 1;
    80002cec:	4785                	li	a5,1
    80002cee:	30f4a023          	sw	a5,768(s1)
        exit(-1);
    80002cf2:	557d                	li	a0,-1
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	6fc080e7          	jalr	1788(ra) # 800023f0 <exit>
    80002cfc:	b54d                	j	80002b9e <usertrap+0x6e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cfe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d02:	3084a603          	lw	a2,776(s1)
    80002d06:	00005517          	auipc	a0,0x5
    80002d0a:	63250513          	addi	a0,a0,1586 # 80008338 <states.0+0xb0>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	878080e7          	jalr	-1928(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d16:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d1a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d1e:	00005517          	auipc	a0,0x5
    80002d22:	64a50513          	addi	a0,a0,1610 # 80008368 <states.0+0xe0>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	860080e7          	jalr	-1952(ra) # 80000586 <printf>
    p->killed = 1;
    80002d2e:	4785                	li	a5,1
    80002d30:	30f4a023          	sw	a5,768(s1)
  if(p->killed)
    80002d34:	a031                	j	80002d40 <usertrap+0x210>
    80002d36:	3004a783          	lw	a5,768(s1)
    80002d3a:	cb81                	beqz	a5,80002d4a <usertrap+0x21a>
    80002d3c:	a011                	j	80002d40 <usertrap+0x210>
    80002d3e:	4901                	li	s2,0
    exit(-1);
    80002d40:	557d                	li	a0,-1
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	6ae080e7          	jalr	1710(ra) # 800023f0 <exit>
  if(which_dev == 2)
    80002d4a:	4789                	li	a5,2
    80002d4c:	e4f91de3          	bne	s2,a5,80002ba6 <usertrap+0x76>
    yield();
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	3d4080e7          	jalr	980(ra) # 80002124 <yield>
    80002d58:	b5b9                	j	80002ba6 <usertrap+0x76>

0000000080002d5a <kerneltrap>:
{
    80002d5a:	7179                	addi	sp,sp,-48
    80002d5c:	f406                	sd	ra,40(sp)
    80002d5e:	f022                	sd	s0,32(sp)
    80002d60:	ec26                	sd	s1,24(sp)
    80002d62:	e84a                	sd	s2,16(sp)
    80002d64:	e44e                	sd	s3,8(sp)
    80002d66:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d68:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d70:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d74:	1004f793          	andi	a5,s1,256
    80002d78:	cb85                	beqz	a5,80002da8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d7a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d7e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d80:	ef85                	bnez	a5,80002db8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	d0c080e7          	jalr	-756(ra) # 80002a8e <devintr>
    80002d8a:	cd1d                	beqz	a0,80002dc8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d8c:	4789                	li	a5,2
    80002d8e:	06f50a63          	beq	a0,a5,80002e02 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d92:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d96:	10049073          	csrw	sstatus,s1
}
    80002d9a:	70a2                	ld	ra,40(sp)
    80002d9c:	7402                	ld	s0,32(sp)
    80002d9e:	64e2                	ld	s1,24(sp)
    80002da0:	6942                	ld	s2,16(sp)
    80002da2:	69a2                	ld	s3,8(sp)
    80002da4:	6145                	addi	sp,sp,48
    80002da6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	5e050513          	addi	a0,a0,1504 # 80008388 <states.0+0x100>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	78c080e7          	jalr	1932(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	5f850513          	addi	a0,a0,1528 # 800083b0 <states.0+0x128>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	77c080e7          	jalr	1916(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002dc8:	85ce                	mv	a1,s3
    80002dca:	00005517          	auipc	a0,0x5
    80002dce:	60650513          	addi	a0,a0,1542 # 800083d0 <states.0+0x148>
    80002dd2:	ffffd097          	auipc	ra,0xffffd
    80002dd6:	7b4080e7          	jalr	1972(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dda:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dde:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	5fe50513          	addi	a0,a0,1534 # 800083e0 <states.0+0x158>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	79c080e7          	jalr	1948(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	60650513          	addi	a0,a0,1542 # 800083f8 <states.0+0x170>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	742080e7          	jalr	1858(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	c3c080e7          	jalr	-964(ra) # 80001a3e <myproc>
    80002e0a:	d541                	beqz	a0,80002d92 <kerneltrap+0x38>
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	c32080e7          	jalr	-974(ra) # 80001a3e <myproc>
    80002e14:	2f052703          	lw	a4,752(a0)
    80002e18:	4791                	li	a5,4
    80002e1a:	f6f71ce3          	bne	a4,a5,80002d92 <kerneltrap+0x38>
    yield();
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	306080e7          	jalr	774(ra) # 80002124 <yield>
    80002e26:	b7b5                	j	80002d92 <kerneltrap+0x38>

0000000080002e28 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	e426                	sd	s1,8(sp)
    80002e30:	1000                	addi	s0,sp,32
    80002e32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	c0a080e7          	jalr	-1014(ra) # 80001a3e <myproc>
  switch (n) {
    80002e3c:	4795                	li	a5,5
    80002e3e:	0497e763          	bltu	a5,s1,80002e8c <argraw+0x64>
    80002e42:	048a                	slli	s1,s1,0x2
    80002e44:	00005717          	auipc	a4,0x5
    80002e48:	5ec70713          	addi	a4,a4,1516 # 80008430 <states.0+0x1a8>
    80002e4c:	94ba                	add	s1,s1,a4
    80002e4e:	409c                	lw	a5,0(s1)
    80002e50:	97ba                	add	a5,a5,a4
    80002e52:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e54:	33053783          	ld	a5,816(a0)
    80002e58:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e5a:	60e2                	ld	ra,24(sp)
    80002e5c:	6442                	ld	s0,16(sp)
    80002e5e:	64a2                	ld	s1,8(sp)
    80002e60:	6105                	addi	sp,sp,32
    80002e62:	8082                	ret
    return p->trapframe->a1;
    80002e64:	33053783          	ld	a5,816(a0)
    80002e68:	7fa8                	ld	a0,120(a5)
    80002e6a:	bfc5                	j	80002e5a <argraw+0x32>
    return p->trapframe->a2;
    80002e6c:	33053783          	ld	a5,816(a0)
    80002e70:	63c8                	ld	a0,128(a5)
    80002e72:	b7e5                	j	80002e5a <argraw+0x32>
    return p->trapframe->a3;
    80002e74:	33053783          	ld	a5,816(a0)
    80002e78:	67c8                	ld	a0,136(a5)
    80002e7a:	b7c5                	j	80002e5a <argraw+0x32>
    return p->trapframe->a4;
    80002e7c:	33053783          	ld	a5,816(a0)
    80002e80:	6bc8                	ld	a0,144(a5)
    80002e82:	bfe1                	j	80002e5a <argraw+0x32>
    return p->trapframe->a5;
    80002e84:	33053783          	ld	a5,816(a0)
    80002e88:	6fc8                	ld	a0,152(a5)
    80002e8a:	bfc1                	j	80002e5a <argraw+0x32>
  panic("argraw");
    80002e8c:	00005517          	auipc	a0,0x5
    80002e90:	57c50513          	addi	a0,a0,1404 # 80008408 <states.0+0x180>
    80002e94:	ffffd097          	auipc	ra,0xffffd
    80002e98:	6a8080e7          	jalr	1704(ra) # 8000053c <panic>

0000000080002e9c <fetchaddr>:
{
    80002e9c:	1101                	addi	sp,sp,-32
    80002e9e:	ec06                	sd	ra,24(sp)
    80002ea0:	e822                	sd	s0,16(sp)
    80002ea2:	e426                	sd	s1,8(sp)
    80002ea4:	e04a                	sd	s2,0(sp)
    80002ea6:	1000                	addi	s0,sp,32
    80002ea8:	84aa                	mv	s1,a0
    80002eaa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	b92080e7          	jalr	-1134(ra) # 80001a3e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002eb4:	32053783          	ld	a5,800(a0)
    80002eb8:	02f4f963          	bgeu	s1,a5,80002eea <fetchaddr+0x4e>
    80002ebc:	00848713          	addi	a4,s1,8
    80002ec0:	02e7e763          	bltu	a5,a4,80002eee <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ec4:	46a1                	li	a3,8
    80002ec6:	8626                	mv	a2,s1
    80002ec8:	85ca                	mv	a1,s2
    80002eca:	32853503          	ld	a0,808(a0)
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	842080e7          	jalr	-1982(ra) # 80001710 <copyin>
    80002ed6:	00a03533          	snez	a0,a0
    80002eda:	40a00533          	neg	a0,a0
}
    80002ede:	60e2                	ld	ra,24(sp)
    80002ee0:	6442                	ld	s0,16(sp)
    80002ee2:	64a2                	ld	s1,8(sp)
    80002ee4:	6902                	ld	s2,0(sp)
    80002ee6:	6105                	addi	sp,sp,32
    80002ee8:	8082                	ret
    return -1;
    80002eea:	557d                	li	a0,-1
    80002eec:	bfcd                	j	80002ede <fetchaddr+0x42>
    80002eee:	557d                	li	a0,-1
    80002ef0:	b7fd                	j	80002ede <fetchaddr+0x42>

0000000080002ef2 <fetchstr>:
{
    80002ef2:	7179                	addi	sp,sp,-48
    80002ef4:	f406                	sd	ra,40(sp)
    80002ef6:	f022                	sd	s0,32(sp)
    80002ef8:	ec26                	sd	s1,24(sp)
    80002efa:	e84a                	sd	s2,16(sp)
    80002efc:	e44e                	sd	s3,8(sp)
    80002efe:	1800                	addi	s0,sp,48
    80002f00:	892a                	mv	s2,a0
    80002f02:	84ae                	mv	s1,a1
    80002f04:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	b38080e7          	jalr	-1224(ra) # 80001a3e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f0e:	86ce                	mv	a3,s3
    80002f10:	864a                	mv	a2,s2
    80002f12:	85a6                	mv	a1,s1
    80002f14:	32853503          	ld	a0,808(a0)
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	886080e7          	jalr	-1914(ra) # 8000179e <copyinstr>
  if(err < 0)
    80002f20:	00054763          	bltz	a0,80002f2e <fetchstr+0x3c>
  return strlen(buf);
    80002f24:	8526                	mv	a0,s1
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	f6e080e7          	jalr	-146(ra) # 80000e94 <strlen>
}
    80002f2e:	70a2                	ld	ra,40(sp)
    80002f30:	7402                	ld	s0,32(sp)
    80002f32:	64e2                	ld	s1,24(sp)
    80002f34:	6942                	ld	s2,16(sp)
    80002f36:	69a2                	ld	s3,8(sp)
    80002f38:	6145                	addi	sp,sp,48
    80002f3a:	8082                	ret

0000000080002f3c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	1000                	addi	s0,sp,32
    80002f46:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	ee0080e7          	jalr	-288(ra) # 80002e28 <argraw>
    80002f50:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f52:	4501                	li	a0,0
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	64a2                	ld	s1,8(sp)
    80002f5a:	6105                	addi	sp,sp,32
    80002f5c:	8082                	ret

0000000080002f5e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	e426                	sd	s1,8(sp)
    80002f66:	1000                	addi	s0,sp,32
    80002f68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	ebe080e7          	jalr	-322(ra) # 80002e28 <argraw>
    80002f72:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f74:	4501                	li	a0,0
    80002f76:	60e2                	ld	ra,24(sp)
    80002f78:	6442                	ld	s0,16(sp)
    80002f7a:	64a2                	ld	s1,8(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	e426                	sd	s1,8(sp)
    80002f88:	e04a                	sd	s2,0(sp)
    80002f8a:	1000                	addi	s0,sp,32
    80002f8c:	84ae                	mv	s1,a1
    80002f8e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	e98080e7          	jalr	-360(ra) # 80002e28 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f98:	864a                	mv	a2,s2
    80002f9a:	85a6                	mv	a1,s1
    80002f9c:	00000097          	auipc	ra,0x0
    80002fa0:	f56080e7          	jalr	-170(ra) # 80002ef2 <fetchstr>
}
    80002fa4:	60e2                	ld	ra,24(sp)
    80002fa6:	6442                	ld	s0,16(sp)
    80002fa8:	64a2                	ld	s1,8(sp)
    80002faa:	6902                	ld	s2,0(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret

0000000080002fb0 <syscall>:
[SYS_munmap] sys_munmap,
};

void
syscall(void)
{
    80002fb0:	1101                	addi	sp,sp,-32
    80002fb2:	ec06                	sd	ra,24(sp)
    80002fb4:	e822                	sd	s0,16(sp)
    80002fb6:	e426                	sd	s1,8(sp)
    80002fb8:	e04a                	sd	s2,0(sp)
    80002fba:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fbc:	fffff097          	auipc	ra,0xfffff
    80002fc0:	a82080e7          	jalr	-1406(ra) # 80001a3e <myproc>
    80002fc4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fc6:	33053903          	ld	s2,816(a0)
    80002fca:	0a893783          	ld	a5,168(s2)
    80002fce:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fd2:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffc8fff>
    80002fd4:	4761                	li	a4,24
    80002fd6:	00f76f63          	bltu	a4,a5,80002ff4 <syscall+0x44>
    80002fda:	00369713          	slli	a4,a3,0x3
    80002fde:	00005797          	auipc	a5,0x5
    80002fe2:	46a78793          	addi	a5,a5,1130 # 80008448 <syscalls>
    80002fe6:	97ba                	add	a5,a5,a4
    80002fe8:	639c                	ld	a5,0(a5)
    80002fea:	c789                	beqz	a5,80002ff4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002fec:	9782                	jalr	a5
    80002fee:	06a93823          	sd	a0,112(s2)
    80002ff2:	a00d                	j	80003014 <syscall+0x64>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ff4:	43048613          	addi	a2,s1,1072
    80002ff8:	3084a583          	lw	a1,776(s1)
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	41450513          	addi	a0,a0,1044 # 80008410 <states.0+0x188>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	582080e7          	jalr	1410(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000300c:	3304b783          	ld	a5,816(s1)
    80003010:	577d                	li	a4,-1
    80003012:	fbb8                	sd	a4,112(a5)
  }
}
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6902                	ld	s2,0(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret

0000000080003020 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003028:	fec40593          	addi	a1,s0,-20
    8000302c:	4501                	li	a0,0
    8000302e:	00000097          	auipc	ra,0x0
    80003032:	f0e080e7          	jalr	-242(ra) # 80002f3c <argint>
    return -1;
    80003036:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003038:	00054963          	bltz	a0,8000304a <sys_exit+0x2a>
  exit(n);
    8000303c:	fec42503          	lw	a0,-20(s0)
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	3b0080e7          	jalr	944(ra) # 800023f0 <exit>
  return 0;  // not reached
    80003048:	4781                	li	a5,0
}
    8000304a:	853e                	mv	a0,a5
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret

0000000080003054 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003054:	1141                	addi	sp,sp,-16
    80003056:	e406                	sd	ra,8(sp)
    80003058:	e022                	sd	s0,0(sp)
    8000305a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	9e2080e7          	jalr	-1566(ra) # 80001a3e <myproc>
}
    80003064:	30852503          	lw	a0,776(a0)
    80003068:	60a2                	ld	ra,8(sp)
    8000306a:	6402                	ld	s0,0(sp)
    8000306c:	0141                	addi	sp,sp,16
    8000306e:	8082                	ret

0000000080003070 <sys_fork>:

uint64
sys_fork(void)
{
    80003070:	1141                	addi	sp,sp,-16
    80003072:	e406                	sd	ra,8(sp)
    80003074:	e022                	sd	s0,0(sp)
    80003076:	0800                	addi	s0,sp,16
  return fork();
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	dd8080e7          	jalr	-552(ra) # 80001e50 <fork>
}
    80003080:	60a2                	ld	ra,8(sp)
    80003082:	6402                	ld	s0,0(sp)
    80003084:	0141                	addi	sp,sp,16
    80003086:	8082                	ret

0000000080003088 <sys_wait>:

uint64
sys_wait(void)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003090:	fe840593          	addi	a1,s0,-24
    80003094:	4501                	li	a0,0
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	ec8080e7          	jalr	-312(ra) # 80002f5e <argaddr>
    8000309e:	87aa                	mv	a5,a0
    return -1;
    800030a0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800030a2:	0007c863          	bltz	a5,800030b2 <sys_wait+0x2a>
  return wait(p);
    800030a6:	fe843503          	ld	a0,-24(s0)
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	132080e7          	jalr	306(ra) # 800021dc <wait>
}
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	6105                	addi	sp,sp,32
    800030b8:	8082                	ret

00000000800030ba <sys_sleep>:

uint64
sys_sleep(void)
{
    800030ba:	7139                	addi	sp,sp,-64
    800030bc:	fc06                	sd	ra,56(sp)
    800030be:	f822                	sd	s0,48(sp)
    800030c0:	f426                	sd	s1,40(sp)
    800030c2:	f04a                	sd	s2,32(sp)
    800030c4:	ec4e                	sd	s3,24(sp)
    800030c6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800030c8:	fcc40593          	addi	a1,s0,-52
    800030cc:	4501                	li	a0,0
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	e6e080e7          	jalr	-402(ra) # 80002f3c <argint>
    return -1;
    800030d6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030d8:	06054663          	bltz	a0,80003144 <sys_sleep+0x8a>
  acquire(&tickslock);
    800030dc:	00024517          	auipc	a0,0x24
    800030e0:	60c50513          	addi	a0,a0,1548 # 800276e8 <tickslock>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	b38080e7          	jalr	-1224(ra) # 80000c1c <acquire>
  ticks0 = ticks;
    800030ec:	00006917          	auipc	s2,0x6
    800030f0:	f4492903          	lw	s2,-188(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800030f4:	fcc42783          	lw	a5,-52(s0)
    800030f8:	cf8d                	beqz	a5,80003132 <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030fa:	00024997          	auipc	s3,0x24
    800030fe:	5ee98993          	addi	s3,s3,1518 # 800276e8 <tickslock>
    80003102:	00006497          	auipc	s1,0x6
    80003106:	f2e48493          	addi	s1,s1,-210 # 80009030 <ticks>
    if(myproc()->killed){
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	934080e7          	jalr	-1740(ra) # 80001a3e <myproc>
    80003112:	30052783          	lw	a5,768(a0)
    80003116:	ef9d                	bnez	a5,80003154 <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    80003118:	85ce                	mv	a1,s3
    8000311a:	8526                	mv	a0,s1
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	050080e7          	jalr	80(ra) # 8000216c <sleep>
  while(ticks - ticks0 < n){
    80003124:	409c                	lw	a5,0(s1)
    80003126:	412787bb          	subw	a5,a5,s2
    8000312a:	fcc42703          	lw	a4,-52(s0)
    8000312e:	fce7eee3          	bltu	a5,a4,8000310a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003132:	00024517          	auipc	a0,0x24
    80003136:	5b650513          	addi	a0,a0,1462 # 800276e8 <tickslock>
    8000313a:	ffffe097          	auipc	ra,0xffffe
    8000313e:	b96080e7          	jalr	-1130(ra) # 80000cd0 <release>
  return 0;
    80003142:	4781                	li	a5,0
}
    80003144:	853e                	mv	a0,a5
    80003146:	70e2                	ld	ra,56(sp)
    80003148:	7442                	ld	s0,48(sp)
    8000314a:	74a2                	ld	s1,40(sp)
    8000314c:	7902                	ld	s2,32(sp)
    8000314e:	69e2                	ld	s3,24(sp)
    80003150:	6121                	addi	sp,sp,64
    80003152:	8082                	ret
      release(&tickslock);
    80003154:	00024517          	auipc	a0,0x24
    80003158:	59450513          	addi	a0,a0,1428 # 800276e8 <tickslock>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	b74080e7          	jalr	-1164(ra) # 80000cd0 <release>
      return -1;
    80003164:	57fd                	li	a5,-1
    80003166:	bff9                	j	80003144 <sys_sleep+0x8a>

0000000080003168 <sys_kill>:

uint64
sys_kill(void)
{
    80003168:	1101                	addi	sp,sp,-32
    8000316a:	ec06                	sd	ra,24(sp)
    8000316c:	e822                	sd	s0,16(sp)
    8000316e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003170:	fec40593          	addi	a1,s0,-20
    80003174:	4501                	li	a0,0
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	dc6080e7          	jalr	-570(ra) # 80002f3c <argint>
    8000317e:	87aa                	mv	a5,a0
    return -1;
    80003180:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003182:	0007c863          	bltz	a5,80003192 <sys_kill+0x2a>
  return kill(pid);
    80003186:	fec42503          	lw	a0,-20(s0)
    8000318a:	fffff097          	auipc	ra,0xfffff
    8000318e:	33e080e7          	jalr	830(ra) # 800024c8 <kill>
}
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret

000000008000319a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000319a:	1101                	addi	sp,sp,-32
    8000319c:	ec06                	sd	ra,24(sp)
    8000319e:	e822                	sd	s0,16(sp)
    800031a0:	e426                	sd	s1,8(sp)
    800031a2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031a4:	00024517          	auipc	a0,0x24
    800031a8:	54450513          	addi	a0,a0,1348 # 800276e8 <tickslock>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	a70080e7          	jalr	-1424(ra) # 80000c1c <acquire>
  xticks = ticks;
    800031b4:	00006497          	auipc	s1,0x6
    800031b8:	e7c4a483          	lw	s1,-388(s1) # 80009030 <ticks>
  release(&tickslock);
    800031bc:	00024517          	auipc	a0,0x24
    800031c0:	52c50513          	addi	a0,a0,1324 # 800276e8 <tickslock>
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	b0c080e7          	jalr	-1268(ra) # 80000cd0 <release>
  return xticks;
}
    800031cc:	02049513          	slli	a0,s1,0x20
    800031d0:	9101                	srli	a0,a0,0x20
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    800031e4:	fe840593          	addi	a1,s0,-24
    800031e8:	4501                	li	a0,0
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	d74080e7          	jalr	-652(ra) # 80002f5e <argaddr>
    800031f2:	87aa                	mv	a5,a0
    return -1;
    800031f4:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    800031f6:	0007c863          	bltz	a5,80003206 <sys_getprocs+0x2a>
  return(procinfo(addr));
    800031fa:	fe843503          	ld	a0,-24(s0)
    800031fe:	fffff097          	auipc	ra,0xfffff
    80003202:	4ac080e7          	jalr	1196(ra) # 800026aa <procinfo>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret

000000008000320e <sys_freepmem>:

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
    8000320e:	1141                	addi	sp,sp,-16
    80003210:	e406                	sd	ra,8(sp)
    80003212:	e022                	sd	s0,0(sp)
    80003214:	0800                	addi	s0,sp,16
  int res = freepmem();
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	92c080e7          	jalr	-1748(ra) # 80000b42 <freepmem>
  return res;
}
    8000321e:	2501                	sext.w	a0,a0
    80003220:	60a2                	ld	ra,8(sp)
    80003222:	6402                	ld	s0,0(sp)
    80003224:	0141                	addi	sp,sp,16
    80003226:	8082                	ret

0000000080003228 <sys_sbrk>:

// HW 4 - Task 2
// system call to allocate VIRTUAL memory on the disk
uint64
sys_sbrk(void){
    80003228:	7179                	addi	sp,sp,-48
    8000322a:	f406                	sd	ra,40(sp)
    8000322c:	f022                	sd	s0,32(sp)
    8000322e:	ec26                	sd	s1,24(sp)
    80003230:	e84a                	sd	s2,16(sp)
    80003232:	1800                	addi	s0,sp,48
  int new_size;
  int increment;

  // Retrieve the first system call argument, which is the number 
  // of bytes to increase the heap by, and store it in 'increment'
  if(argint(0, &increment) < 0){
    80003234:	fdc40593          	addi	a1,s0,-36
    80003238:	4501                	li	a0,0
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	d02080e7          	jalr	-766(ra) # 80002f3c <argint>
    80003242:	87aa                	mv	a5,a0
    return -1;
    80003244:	557d                	li	a0,-1
  if(argint(0, &increment) < 0){
    80003246:	0207c363          	bltz	a5,8000326c <sys_sbrk+0x44>
  }

  // Get the current size of the process's heap from its process structure.]
  curr_size = myproc()->sz;
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	7f4080e7          	jalr	2036(ra) # 80001a3e <myproc>
    80003252:	32052483          	lw	s1,800(a0)

  // Calculate the new size of the heap by adding 'increment' to the current size
  new_size = curr_size + increment;
    80003256:	fdc42903          	lw	s2,-36(s0)
    8000325a:	0099093b          	addw	s2,s2,s1

  // Check if the new size is below a memory safety threshold ('TRAPFRAME')
  // This is to ensure the heap does not overlap with the trap frame
  if(new_size < TRAPFRAME){
    // If the new size is valid, update the process's heap size to -> new_size
    myproc()->sz = new_size;
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	7e0080e7          	jalr	2016(ra) # 80001a3e <myproc>
    80003266:	33253023          	sd	s2,800(a0)
    
    // Return the old heap end address before the increment
    return curr_size;
    8000326a:	8526                	mv	a0,s1
  }

  // If the new size is not valid or exceeds the memory safety threshold
  return -1;
}
    8000326c:	70a2                	ld	ra,40(sp)
    8000326e:	7402                	ld	s0,32(sp)
    80003270:	64e2                	ld	s1,24(sp)
    80003272:	6942                	ld	s2,16(sp)
    80003274:	6145                	addi	sp,sp,48
    80003276:	8082                	ret

0000000080003278 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003278:	7179                	addi	sp,sp,-48
    8000327a:	f406                	sd	ra,40(sp)
    8000327c:	f022                	sd	s0,32(sp)
    8000327e:	ec26                	sd	s1,24(sp)
    80003280:	e84a                	sd	s2,16(sp)
    80003282:	e44e                	sd	s3,8(sp)
    80003284:	e052                	sd	s4,0(sp)
    80003286:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003288:	00005597          	auipc	a1,0x5
    8000328c:	29058593          	addi	a1,a1,656 # 80008518 <syscalls+0xd0>
    80003290:	00024517          	auipc	a0,0x24
    80003294:	47050513          	addi	a0,a0,1136 # 80027700 <bcache>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	8f4080e7          	jalr	-1804(ra) # 80000b8c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032a0:	0002c797          	auipc	a5,0x2c
    800032a4:	46078793          	addi	a5,a5,1120 # 8002f700 <bcache+0x8000>
    800032a8:	0002c717          	auipc	a4,0x2c
    800032ac:	6c070713          	addi	a4,a4,1728 # 8002f968 <bcache+0x8268>
    800032b0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032b4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032b8:	00024497          	auipc	s1,0x24
    800032bc:	46048493          	addi	s1,s1,1120 # 80027718 <bcache+0x18>
    b->next = bcache.head.next;
    800032c0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032c2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032c4:	00005a17          	auipc	s4,0x5
    800032c8:	25ca0a13          	addi	s4,s4,604 # 80008520 <syscalls+0xd8>
    b->next = bcache.head.next;
    800032cc:	2b893783          	ld	a5,696(s2)
    800032d0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032d2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032d6:	85d2                	mv	a1,s4
    800032d8:	01048513          	addi	a0,s1,16
    800032dc:	00001097          	auipc	ra,0x1
    800032e0:	4c2080e7          	jalr	1218(ra) # 8000479e <initsleeplock>
    bcache.head.next->prev = b;
    800032e4:	2b893783          	ld	a5,696(s2)
    800032e8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032ea:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032ee:	45848493          	addi	s1,s1,1112
    800032f2:	fd349de3          	bne	s1,s3,800032cc <binit+0x54>
  }
}
    800032f6:	70a2                	ld	ra,40(sp)
    800032f8:	7402                	ld	s0,32(sp)
    800032fa:	64e2                	ld	s1,24(sp)
    800032fc:	6942                	ld	s2,16(sp)
    800032fe:	69a2                	ld	s3,8(sp)
    80003300:	6a02                	ld	s4,0(sp)
    80003302:	6145                	addi	sp,sp,48
    80003304:	8082                	ret

0000000080003306 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003306:	7179                	addi	sp,sp,-48
    80003308:	f406                	sd	ra,40(sp)
    8000330a:	f022                	sd	s0,32(sp)
    8000330c:	ec26                	sd	s1,24(sp)
    8000330e:	e84a                	sd	s2,16(sp)
    80003310:	e44e                	sd	s3,8(sp)
    80003312:	1800                	addi	s0,sp,48
    80003314:	892a                	mv	s2,a0
    80003316:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003318:	00024517          	auipc	a0,0x24
    8000331c:	3e850513          	addi	a0,a0,1000 # 80027700 <bcache>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	8fc080e7          	jalr	-1796(ra) # 80000c1c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003328:	0002c497          	auipc	s1,0x2c
    8000332c:	6904b483          	ld	s1,1680(s1) # 8002f9b8 <bcache+0x82b8>
    80003330:	0002c797          	auipc	a5,0x2c
    80003334:	63878793          	addi	a5,a5,1592 # 8002f968 <bcache+0x8268>
    80003338:	02f48f63          	beq	s1,a5,80003376 <bread+0x70>
    8000333c:	873e                	mv	a4,a5
    8000333e:	a021                	j	80003346 <bread+0x40>
    80003340:	68a4                	ld	s1,80(s1)
    80003342:	02e48a63          	beq	s1,a4,80003376 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003346:	449c                	lw	a5,8(s1)
    80003348:	ff279ce3          	bne	a5,s2,80003340 <bread+0x3a>
    8000334c:	44dc                	lw	a5,12(s1)
    8000334e:	ff3799e3          	bne	a5,s3,80003340 <bread+0x3a>
      b->refcnt++;
    80003352:	40bc                	lw	a5,64(s1)
    80003354:	2785                	addiw	a5,a5,1
    80003356:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003358:	00024517          	auipc	a0,0x24
    8000335c:	3a850513          	addi	a0,a0,936 # 80027700 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	970080e7          	jalr	-1680(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    80003368:	01048513          	addi	a0,s1,16
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	46c080e7          	jalr	1132(ra) # 800047d8 <acquiresleep>
      return b;
    80003374:	a8b9                	j	800033d2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003376:	0002c497          	auipc	s1,0x2c
    8000337a:	63a4b483          	ld	s1,1594(s1) # 8002f9b0 <bcache+0x82b0>
    8000337e:	0002c797          	auipc	a5,0x2c
    80003382:	5ea78793          	addi	a5,a5,1514 # 8002f968 <bcache+0x8268>
    80003386:	00f48863          	beq	s1,a5,80003396 <bread+0x90>
    8000338a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000338c:	40bc                	lw	a5,64(s1)
    8000338e:	cf81                	beqz	a5,800033a6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003390:	64a4                	ld	s1,72(s1)
    80003392:	fee49de3          	bne	s1,a4,8000338c <bread+0x86>
  panic("bget: no buffers");
    80003396:	00005517          	auipc	a0,0x5
    8000339a:	19250513          	addi	a0,a0,402 # 80008528 <syscalls+0xe0>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	19e080e7          	jalr	414(ra) # 8000053c <panic>
      b->dev = dev;
    800033a6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033aa:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800033ae:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033b2:	4785                	li	a5,1
    800033b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033b6:	00024517          	auipc	a0,0x24
    800033ba:	34a50513          	addi	a0,a0,842 # 80027700 <bcache>
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	912080e7          	jalr	-1774(ra) # 80000cd0 <release>
      acquiresleep(&b->lock);
    800033c6:	01048513          	addi	a0,s1,16
    800033ca:	00001097          	auipc	ra,0x1
    800033ce:	40e080e7          	jalr	1038(ra) # 800047d8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033d2:	409c                	lw	a5,0(s1)
    800033d4:	cb89                	beqz	a5,800033e6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033d6:	8526                	mv	a0,s1
    800033d8:	70a2                	ld	ra,40(sp)
    800033da:	7402                	ld	s0,32(sp)
    800033dc:	64e2                	ld	s1,24(sp)
    800033de:	6942                	ld	s2,16(sp)
    800033e0:	69a2                	ld	s3,8(sp)
    800033e2:	6145                	addi	sp,sp,48
    800033e4:	8082                	ret
    virtio_disk_rw(b, 0);
    800033e6:	4581                	li	a1,0
    800033e8:	8526                	mv	a0,s1
    800033ea:	00003097          	auipc	ra,0x3
    800033ee:	1e8080e7          	jalr	488(ra) # 800065d2 <virtio_disk_rw>
    b->valid = 1;
    800033f2:	4785                	li	a5,1
    800033f4:	c09c                	sw	a5,0(s1)
  return b;
    800033f6:	b7c5                	j	800033d6 <bread+0xd0>

00000000800033f8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	e426                	sd	s1,8(sp)
    80003400:	1000                	addi	s0,sp,32
    80003402:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003404:	0541                	addi	a0,a0,16
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	46e080e7          	jalr	1134(ra) # 80004874 <holdingsleep>
    8000340e:	cd01                	beqz	a0,80003426 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003410:	4585                	li	a1,1
    80003412:	8526                	mv	a0,s1
    80003414:	00003097          	auipc	ra,0x3
    80003418:	1be080e7          	jalr	446(ra) # 800065d2 <virtio_disk_rw>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret
    panic("bwrite");
    80003426:	00005517          	auipc	a0,0x5
    8000342a:	11a50513          	addi	a0,a0,282 # 80008540 <syscalls+0xf8>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	10e080e7          	jalr	270(ra) # 8000053c <panic>

0000000080003436 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003436:	1101                	addi	sp,sp,-32
    80003438:	ec06                	sd	ra,24(sp)
    8000343a:	e822                	sd	s0,16(sp)
    8000343c:	e426                	sd	s1,8(sp)
    8000343e:	e04a                	sd	s2,0(sp)
    80003440:	1000                	addi	s0,sp,32
    80003442:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003444:	01050913          	addi	s2,a0,16
    80003448:	854a                	mv	a0,s2
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	42a080e7          	jalr	1066(ra) # 80004874 <holdingsleep>
    80003452:	c92d                	beqz	a0,800034c4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003454:	854a                	mv	a0,s2
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	3da080e7          	jalr	986(ra) # 80004830 <releasesleep>

  acquire(&bcache.lock);
    8000345e:	00024517          	auipc	a0,0x24
    80003462:	2a250513          	addi	a0,a0,674 # 80027700 <bcache>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	7b6080e7          	jalr	1974(ra) # 80000c1c <acquire>
  b->refcnt--;
    8000346e:	40bc                	lw	a5,64(s1)
    80003470:	37fd                	addiw	a5,a5,-1
    80003472:	0007871b          	sext.w	a4,a5
    80003476:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003478:	eb05                	bnez	a4,800034a8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000347a:	68bc                	ld	a5,80(s1)
    8000347c:	64b8                	ld	a4,72(s1)
    8000347e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003480:	64bc                	ld	a5,72(s1)
    80003482:	68b8                	ld	a4,80(s1)
    80003484:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003486:	0002c797          	auipc	a5,0x2c
    8000348a:	27a78793          	addi	a5,a5,634 # 8002f700 <bcache+0x8000>
    8000348e:	2b87b703          	ld	a4,696(a5)
    80003492:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003494:	0002c717          	auipc	a4,0x2c
    80003498:	4d470713          	addi	a4,a4,1236 # 8002f968 <bcache+0x8268>
    8000349c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000349e:	2b87b703          	ld	a4,696(a5)
    800034a2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034a4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034a8:	00024517          	auipc	a0,0x24
    800034ac:	25850513          	addi	a0,a0,600 # 80027700 <bcache>
    800034b0:	ffffe097          	auipc	ra,0xffffe
    800034b4:	820080e7          	jalr	-2016(ra) # 80000cd0 <release>
}
    800034b8:	60e2                	ld	ra,24(sp)
    800034ba:	6442                	ld	s0,16(sp)
    800034bc:	64a2                	ld	s1,8(sp)
    800034be:	6902                	ld	s2,0(sp)
    800034c0:	6105                	addi	sp,sp,32
    800034c2:	8082                	ret
    panic("brelse");
    800034c4:	00005517          	auipc	a0,0x5
    800034c8:	08450513          	addi	a0,a0,132 # 80008548 <syscalls+0x100>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	070080e7          	jalr	112(ra) # 8000053c <panic>

00000000800034d4 <bpin>:

void
bpin(struct buf *b) {
    800034d4:	1101                	addi	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	e426                	sd	s1,8(sp)
    800034dc:	1000                	addi	s0,sp,32
    800034de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034e0:	00024517          	auipc	a0,0x24
    800034e4:	22050513          	addi	a0,a0,544 # 80027700 <bcache>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	734080e7          	jalr	1844(ra) # 80000c1c <acquire>
  b->refcnt++;
    800034f0:	40bc                	lw	a5,64(s1)
    800034f2:	2785                	addiw	a5,a5,1
    800034f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034f6:	00024517          	auipc	a0,0x24
    800034fa:	20a50513          	addi	a0,a0,522 # 80027700 <bcache>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	7d2080e7          	jalr	2002(ra) # 80000cd0 <release>
}
    80003506:	60e2                	ld	ra,24(sp)
    80003508:	6442                	ld	s0,16(sp)
    8000350a:	64a2                	ld	s1,8(sp)
    8000350c:	6105                	addi	sp,sp,32
    8000350e:	8082                	ret

0000000080003510 <bunpin>:

void
bunpin(struct buf *b) {
    80003510:	1101                	addi	sp,sp,-32
    80003512:	ec06                	sd	ra,24(sp)
    80003514:	e822                	sd	s0,16(sp)
    80003516:	e426                	sd	s1,8(sp)
    80003518:	1000                	addi	s0,sp,32
    8000351a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000351c:	00024517          	auipc	a0,0x24
    80003520:	1e450513          	addi	a0,a0,484 # 80027700 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	6f8080e7          	jalr	1784(ra) # 80000c1c <acquire>
  b->refcnt--;
    8000352c:	40bc                	lw	a5,64(s1)
    8000352e:	37fd                	addiw	a5,a5,-1
    80003530:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003532:	00024517          	auipc	a0,0x24
    80003536:	1ce50513          	addi	a0,a0,462 # 80027700 <bcache>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	796080e7          	jalr	1942(ra) # 80000cd0 <release>
}
    80003542:	60e2                	ld	ra,24(sp)
    80003544:	6442                	ld	s0,16(sp)
    80003546:	64a2                	ld	s1,8(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret

000000008000354c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000354c:	1101                	addi	sp,sp,-32
    8000354e:	ec06                	sd	ra,24(sp)
    80003550:	e822                	sd	s0,16(sp)
    80003552:	e426                	sd	s1,8(sp)
    80003554:	e04a                	sd	s2,0(sp)
    80003556:	1000                	addi	s0,sp,32
    80003558:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000355a:	00d5d59b          	srliw	a1,a1,0xd
    8000355e:	0002d797          	auipc	a5,0x2d
    80003562:	87e7a783          	lw	a5,-1922(a5) # 8002fddc <sb+0x1c>
    80003566:	9dbd                	addw	a1,a1,a5
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	d9e080e7          	jalr	-610(ra) # 80003306 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003570:	0074f713          	andi	a4,s1,7
    80003574:	4785                	li	a5,1
    80003576:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000357a:	14ce                	slli	s1,s1,0x33
    8000357c:	90d9                	srli	s1,s1,0x36
    8000357e:	00950733          	add	a4,a0,s1
    80003582:	05874703          	lbu	a4,88(a4)
    80003586:	00e7f6b3          	and	a3,a5,a4
    8000358a:	c69d                	beqz	a3,800035b8 <bfree+0x6c>
    8000358c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000358e:	94aa                	add	s1,s1,a0
    80003590:	fff7c793          	not	a5,a5
    80003594:	8f7d                	and	a4,a4,a5
    80003596:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000359a:	00001097          	auipc	ra,0x1
    8000359e:	120080e7          	jalr	288(ra) # 800046ba <log_write>
  brelse(bp);
    800035a2:	854a                	mv	a0,s2
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	e92080e7          	jalr	-366(ra) # 80003436 <brelse>
}
    800035ac:	60e2                	ld	ra,24(sp)
    800035ae:	6442                	ld	s0,16(sp)
    800035b0:	64a2                	ld	s1,8(sp)
    800035b2:	6902                	ld	s2,0(sp)
    800035b4:	6105                	addi	sp,sp,32
    800035b6:	8082                	ret
    panic("freeing free block");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	f9850513          	addi	a0,a0,-104 # 80008550 <syscalls+0x108>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f7c080e7          	jalr	-132(ra) # 8000053c <panic>

00000000800035c8 <balloc>:
{
    800035c8:	711d                	addi	sp,sp,-96
    800035ca:	ec86                	sd	ra,88(sp)
    800035cc:	e8a2                	sd	s0,80(sp)
    800035ce:	e4a6                	sd	s1,72(sp)
    800035d0:	e0ca                	sd	s2,64(sp)
    800035d2:	fc4e                	sd	s3,56(sp)
    800035d4:	f852                	sd	s4,48(sp)
    800035d6:	f456                	sd	s5,40(sp)
    800035d8:	f05a                	sd	s6,32(sp)
    800035da:	ec5e                	sd	s7,24(sp)
    800035dc:	e862                	sd	s8,16(sp)
    800035de:	e466                	sd	s9,8(sp)
    800035e0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035e2:	0002c797          	auipc	a5,0x2c
    800035e6:	7e27a783          	lw	a5,2018(a5) # 8002fdc4 <sb+0x4>
    800035ea:	cbc1                	beqz	a5,8000367a <balloc+0xb2>
    800035ec:	8baa                	mv	s7,a0
    800035ee:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035f0:	0002cb17          	auipc	s6,0x2c
    800035f4:	7d0b0b13          	addi	s6,s6,2000 # 8002fdc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035f8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035fa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035fc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035fe:	6c89                	lui	s9,0x2
    80003600:	a831                	j	8000361c <balloc+0x54>
    brelse(bp);
    80003602:	854a                	mv	a0,s2
    80003604:	00000097          	auipc	ra,0x0
    80003608:	e32080e7          	jalr	-462(ra) # 80003436 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000360c:	015c87bb          	addw	a5,s9,s5
    80003610:	00078a9b          	sext.w	s5,a5
    80003614:	004b2703          	lw	a4,4(s6)
    80003618:	06eaf163          	bgeu	s5,a4,8000367a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000361c:	41fad79b          	sraiw	a5,s5,0x1f
    80003620:	0137d79b          	srliw	a5,a5,0x13
    80003624:	015787bb          	addw	a5,a5,s5
    80003628:	40d7d79b          	sraiw	a5,a5,0xd
    8000362c:	01cb2583          	lw	a1,28(s6)
    80003630:	9dbd                	addw	a1,a1,a5
    80003632:	855e                	mv	a0,s7
    80003634:	00000097          	auipc	ra,0x0
    80003638:	cd2080e7          	jalr	-814(ra) # 80003306 <bread>
    8000363c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000363e:	004b2503          	lw	a0,4(s6)
    80003642:	000a849b          	sext.w	s1,s5
    80003646:	8762                	mv	a4,s8
    80003648:	faa4fde3          	bgeu	s1,a0,80003602 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000364c:	00777693          	andi	a3,a4,7
    80003650:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003654:	41f7579b          	sraiw	a5,a4,0x1f
    80003658:	01d7d79b          	srliw	a5,a5,0x1d
    8000365c:	9fb9                	addw	a5,a5,a4
    8000365e:	4037d79b          	sraiw	a5,a5,0x3
    80003662:	00f90633          	add	a2,s2,a5
    80003666:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000366a:	00c6f5b3          	and	a1,a3,a2
    8000366e:	cd91                	beqz	a1,8000368a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003670:	2705                	addiw	a4,a4,1
    80003672:	2485                	addiw	s1,s1,1
    80003674:	fd471ae3          	bne	a4,s4,80003648 <balloc+0x80>
    80003678:	b769                	j	80003602 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000367a:	00005517          	auipc	a0,0x5
    8000367e:	eee50513          	addi	a0,a0,-274 # 80008568 <syscalls+0x120>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	eba080e7          	jalr	-326(ra) # 8000053c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000368a:	97ca                	add	a5,a5,s2
    8000368c:	8e55                	or	a2,a2,a3
    8000368e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	00001097          	auipc	ra,0x1
    80003698:	026080e7          	jalr	38(ra) # 800046ba <log_write>
        brelse(bp);
    8000369c:	854a                	mv	a0,s2
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	d98080e7          	jalr	-616(ra) # 80003436 <brelse>
  bp = bread(dev, bno);
    800036a6:	85a6                	mv	a1,s1
    800036a8:	855e                	mv	a0,s7
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	c5c080e7          	jalr	-932(ra) # 80003306 <bread>
    800036b2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036b4:	40000613          	li	a2,1024
    800036b8:	4581                	li	a1,0
    800036ba:	05850513          	addi	a0,a0,88
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	65a080e7          	jalr	1626(ra) # 80000d18 <memset>
  log_write(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	ff2080e7          	jalr	-14(ra) # 800046ba <log_write>
  brelse(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	d64080e7          	jalr	-668(ra) # 80003436 <brelse>
}
    800036da:	8526                	mv	a0,s1
    800036dc:	60e6                	ld	ra,88(sp)
    800036de:	6446                	ld	s0,80(sp)
    800036e0:	64a6                	ld	s1,72(sp)
    800036e2:	6906                	ld	s2,64(sp)
    800036e4:	79e2                	ld	s3,56(sp)
    800036e6:	7a42                	ld	s4,48(sp)
    800036e8:	7aa2                	ld	s5,40(sp)
    800036ea:	7b02                	ld	s6,32(sp)
    800036ec:	6be2                	ld	s7,24(sp)
    800036ee:	6c42                	ld	s8,16(sp)
    800036f0:	6ca2                	ld	s9,8(sp)
    800036f2:	6125                	addi	sp,sp,96
    800036f4:	8082                	ret

00000000800036f6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036f6:	7179                	addi	sp,sp,-48
    800036f8:	f406                	sd	ra,40(sp)
    800036fa:	f022                	sd	s0,32(sp)
    800036fc:	ec26                	sd	s1,24(sp)
    800036fe:	e84a                	sd	s2,16(sp)
    80003700:	e44e                	sd	s3,8(sp)
    80003702:	e052                	sd	s4,0(sp)
    80003704:	1800                	addi	s0,sp,48
    80003706:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003708:	47ad                	li	a5,11
    8000370a:	04b7fe63          	bgeu	a5,a1,80003766 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000370e:	ff45849b          	addiw	s1,a1,-12
    80003712:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003716:	0ff00793          	li	a5,255
    8000371a:	0ae7e463          	bltu	a5,a4,800037c2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000371e:	08052583          	lw	a1,128(a0)
    80003722:	c5b5                	beqz	a1,8000378e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003724:	00092503          	lw	a0,0(s2)
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	bde080e7          	jalr	-1058(ra) # 80003306 <bread>
    80003730:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003732:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003736:	02049713          	slli	a4,s1,0x20
    8000373a:	01e75593          	srli	a1,a4,0x1e
    8000373e:	00b784b3          	add	s1,a5,a1
    80003742:	0004a983          	lw	s3,0(s1)
    80003746:	04098e63          	beqz	s3,800037a2 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000374a:	8552                	mv	a0,s4
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	cea080e7          	jalr	-790(ra) # 80003436 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003754:	854e                	mv	a0,s3
    80003756:	70a2                	ld	ra,40(sp)
    80003758:	7402                	ld	s0,32(sp)
    8000375a:	64e2                	ld	s1,24(sp)
    8000375c:	6942                	ld	s2,16(sp)
    8000375e:	69a2                	ld	s3,8(sp)
    80003760:	6a02                	ld	s4,0(sp)
    80003762:	6145                	addi	sp,sp,48
    80003764:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003766:	02059793          	slli	a5,a1,0x20
    8000376a:	01e7d593          	srli	a1,a5,0x1e
    8000376e:	00b504b3          	add	s1,a0,a1
    80003772:	0504a983          	lw	s3,80(s1)
    80003776:	fc099fe3          	bnez	s3,80003754 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000377a:	4108                	lw	a0,0(a0)
    8000377c:	00000097          	auipc	ra,0x0
    80003780:	e4c080e7          	jalr	-436(ra) # 800035c8 <balloc>
    80003784:	0005099b          	sext.w	s3,a0
    80003788:	0534a823          	sw	s3,80(s1)
    8000378c:	b7e1                	j	80003754 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000378e:	4108                	lw	a0,0(a0)
    80003790:	00000097          	auipc	ra,0x0
    80003794:	e38080e7          	jalr	-456(ra) # 800035c8 <balloc>
    80003798:	0005059b          	sext.w	a1,a0
    8000379c:	08b92023          	sw	a1,128(s2)
    800037a0:	b751                	j	80003724 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037a2:	00092503          	lw	a0,0(s2)
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	e22080e7          	jalr	-478(ra) # 800035c8 <balloc>
    800037ae:	0005099b          	sext.w	s3,a0
    800037b2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037b6:	8552                	mv	a0,s4
    800037b8:	00001097          	auipc	ra,0x1
    800037bc:	f02080e7          	jalr	-254(ra) # 800046ba <log_write>
    800037c0:	b769                	j	8000374a <bmap+0x54>
  panic("bmap: out of range");
    800037c2:	00005517          	auipc	a0,0x5
    800037c6:	dbe50513          	addi	a0,a0,-578 # 80008580 <syscalls+0x138>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	d72080e7          	jalr	-654(ra) # 8000053c <panic>

00000000800037d2 <iget>:
{
    800037d2:	7179                	addi	sp,sp,-48
    800037d4:	f406                	sd	ra,40(sp)
    800037d6:	f022                	sd	s0,32(sp)
    800037d8:	ec26                	sd	s1,24(sp)
    800037da:	e84a                	sd	s2,16(sp)
    800037dc:	e44e                	sd	s3,8(sp)
    800037de:	e052                	sd	s4,0(sp)
    800037e0:	1800                	addi	s0,sp,48
    800037e2:	89aa                	mv	s3,a0
    800037e4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037e6:	0002c517          	auipc	a0,0x2c
    800037ea:	5fa50513          	addi	a0,a0,1530 # 8002fde0 <itable>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	42e080e7          	jalr	1070(ra) # 80000c1c <acquire>
  empty = 0;
    800037f6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037f8:	0002c497          	auipc	s1,0x2c
    800037fc:	60048493          	addi	s1,s1,1536 # 8002fdf8 <itable+0x18>
    80003800:	0002e697          	auipc	a3,0x2e
    80003804:	08868693          	addi	a3,a3,136 # 80031888 <log>
    80003808:	a039                	j	80003816 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000380a:	02090b63          	beqz	s2,80003840 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000380e:	08848493          	addi	s1,s1,136
    80003812:	02d48a63          	beq	s1,a3,80003846 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003816:	449c                	lw	a5,8(s1)
    80003818:	fef059e3          	blez	a5,8000380a <iget+0x38>
    8000381c:	4098                	lw	a4,0(s1)
    8000381e:	ff3716e3          	bne	a4,s3,8000380a <iget+0x38>
    80003822:	40d8                	lw	a4,4(s1)
    80003824:	ff4713e3          	bne	a4,s4,8000380a <iget+0x38>
      ip->ref++;
    80003828:	2785                	addiw	a5,a5,1
    8000382a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000382c:	0002c517          	auipc	a0,0x2c
    80003830:	5b450513          	addi	a0,a0,1460 # 8002fde0 <itable>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	49c080e7          	jalr	1180(ra) # 80000cd0 <release>
      return ip;
    8000383c:	8926                	mv	s2,s1
    8000383e:	a03d                	j	8000386c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003840:	f7f9                	bnez	a5,8000380e <iget+0x3c>
    80003842:	8926                	mv	s2,s1
    80003844:	b7e9                	j	8000380e <iget+0x3c>
  if(empty == 0)
    80003846:	02090c63          	beqz	s2,8000387e <iget+0xac>
  ip->dev = dev;
    8000384a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000384e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003852:	4785                	li	a5,1
    80003854:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003858:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000385c:	0002c517          	auipc	a0,0x2c
    80003860:	58450513          	addi	a0,a0,1412 # 8002fde0 <itable>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	46c080e7          	jalr	1132(ra) # 80000cd0 <release>
}
    8000386c:	854a                	mv	a0,s2
    8000386e:	70a2                	ld	ra,40(sp)
    80003870:	7402                	ld	s0,32(sp)
    80003872:	64e2                	ld	s1,24(sp)
    80003874:	6942                	ld	s2,16(sp)
    80003876:	69a2                	ld	s3,8(sp)
    80003878:	6a02                	ld	s4,0(sp)
    8000387a:	6145                	addi	sp,sp,48
    8000387c:	8082                	ret
    panic("iget: no inodes");
    8000387e:	00005517          	auipc	a0,0x5
    80003882:	d1a50513          	addi	a0,a0,-742 # 80008598 <syscalls+0x150>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	cb6080e7          	jalr	-842(ra) # 8000053c <panic>

000000008000388e <fsinit>:
fsinit(int dev) {
    8000388e:	7179                	addi	sp,sp,-48
    80003890:	f406                	sd	ra,40(sp)
    80003892:	f022                	sd	s0,32(sp)
    80003894:	ec26                	sd	s1,24(sp)
    80003896:	e84a                	sd	s2,16(sp)
    80003898:	e44e                	sd	s3,8(sp)
    8000389a:	1800                	addi	s0,sp,48
    8000389c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000389e:	4585                	li	a1,1
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	a66080e7          	jalr	-1434(ra) # 80003306 <bread>
    800038a8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038aa:	0002c997          	auipc	s3,0x2c
    800038ae:	51698993          	addi	s3,s3,1302 # 8002fdc0 <sb>
    800038b2:	02000613          	li	a2,32
    800038b6:	05850593          	addi	a1,a0,88
    800038ba:	854e                	mv	a0,s3
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	4b8080e7          	jalr	1208(ra) # 80000d74 <memmove>
  brelse(bp);
    800038c4:	8526                	mv	a0,s1
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	b70080e7          	jalr	-1168(ra) # 80003436 <brelse>
  if(sb.magic != FSMAGIC)
    800038ce:	0009a703          	lw	a4,0(s3)
    800038d2:	102037b7          	lui	a5,0x10203
    800038d6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038da:	02f71263          	bne	a4,a5,800038fe <fsinit+0x70>
  initlog(dev, &sb);
    800038de:	0002c597          	auipc	a1,0x2c
    800038e2:	4e258593          	addi	a1,a1,1250 # 8002fdc0 <sb>
    800038e6:	854a                	mv	a0,s2
    800038e8:	00001097          	auipc	ra,0x1
    800038ec:	b56080e7          	jalr	-1194(ra) # 8000443e <initlog>
}
    800038f0:	70a2                	ld	ra,40(sp)
    800038f2:	7402                	ld	s0,32(sp)
    800038f4:	64e2                	ld	s1,24(sp)
    800038f6:	6942                	ld	s2,16(sp)
    800038f8:	69a2                	ld	s3,8(sp)
    800038fa:	6145                	addi	sp,sp,48
    800038fc:	8082                	ret
    panic("invalid file system");
    800038fe:	00005517          	auipc	a0,0x5
    80003902:	caa50513          	addi	a0,a0,-854 # 800085a8 <syscalls+0x160>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	c36080e7          	jalr	-970(ra) # 8000053c <panic>

000000008000390e <iinit>:
{
    8000390e:	7179                	addi	sp,sp,-48
    80003910:	f406                	sd	ra,40(sp)
    80003912:	f022                	sd	s0,32(sp)
    80003914:	ec26                	sd	s1,24(sp)
    80003916:	e84a                	sd	s2,16(sp)
    80003918:	e44e                	sd	s3,8(sp)
    8000391a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000391c:	00005597          	auipc	a1,0x5
    80003920:	ca458593          	addi	a1,a1,-860 # 800085c0 <syscalls+0x178>
    80003924:	0002c517          	auipc	a0,0x2c
    80003928:	4bc50513          	addi	a0,a0,1212 # 8002fde0 <itable>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	260080e7          	jalr	608(ra) # 80000b8c <initlock>
  for(i = 0; i < NINODE; i++) {
    80003934:	0002c497          	auipc	s1,0x2c
    80003938:	4d448493          	addi	s1,s1,1236 # 8002fe08 <itable+0x28>
    8000393c:	0002e997          	auipc	s3,0x2e
    80003940:	f5c98993          	addi	s3,s3,-164 # 80031898 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003944:	00005917          	auipc	s2,0x5
    80003948:	c8490913          	addi	s2,s2,-892 # 800085c8 <syscalls+0x180>
    8000394c:	85ca                	mv	a1,s2
    8000394e:	8526                	mv	a0,s1
    80003950:	00001097          	auipc	ra,0x1
    80003954:	e4e080e7          	jalr	-434(ra) # 8000479e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003958:	08848493          	addi	s1,s1,136
    8000395c:	ff3498e3          	bne	s1,s3,8000394c <iinit+0x3e>
}
    80003960:	70a2                	ld	ra,40(sp)
    80003962:	7402                	ld	s0,32(sp)
    80003964:	64e2                	ld	s1,24(sp)
    80003966:	6942                	ld	s2,16(sp)
    80003968:	69a2                	ld	s3,8(sp)
    8000396a:	6145                	addi	sp,sp,48
    8000396c:	8082                	ret

000000008000396e <ialloc>:
{
    8000396e:	715d                	addi	sp,sp,-80
    80003970:	e486                	sd	ra,72(sp)
    80003972:	e0a2                	sd	s0,64(sp)
    80003974:	fc26                	sd	s1,56(sp)
    80003976:	f84a                	sd	s2,48(sp)
    80003978:	f44e                	sd	s3,40(sp)
    8000397a:	f052                	sd	s4,32(sp)
    8000397c:	ec56                	sd	s5,24(sp)
    8000397e:	e85a                	sd	s6,16(sp)
    80003980:	e45e                	sd	s7,8(sp)
    80003982:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003984:	0002c717          	auipc	a4,0x2c
    80003988:	44872703          	lw	a4,1096(a4) # 8002fdcc <sb+0xc>
    8000398c:	4785                	li	a5,1
    8000398e:	04e7fa63          	bgeu	a5,a4,800039e2 <ialloc+0x74>
    80003992:	8aaa                	mv	s5,a0
    80003994:	8bae                	mv	s7,a1
    80003996:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003998:	0002ca17          	auipc	s4,0x2c
    8000399c:	428a0a13          	addi	s4,s4,1064 # 8002fdc0 <sb>
    800039a0:	00048b1b          	sext.w	s6,s1
    800039a4:	0044d593          	srli	a1,s1,0x4
    800039a8:	018a2783          	lw	a5,24(s4)
    800039ac:	9dbd                	addw	a1,a1,a5
    800039ae:	8556                	mv	a0,s5
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	956080e7          	jalr	-1706(ra) # 80003306 <bread>
    800039b8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039ba:	05850993          	addi	s3,a0,88
    800039be:	00f4f793          	andi	a5,s1,15
    800039c2:	079a                	slli	a5,a5,0x6
    800039c4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039c6:	00099783          	lh	a5,0(s3)
    800039ca:	c785                	beqz	a5,800039f2 <ialloc+0x84>
    brelse(bp);
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	a6a080e7          	jalr	-1430(ra) # 80003436 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039d4:	0485                	addi	s1,s1,1
    800039d6:	00ca2703          	lw	a4,12(s4)
    800039da:	0004879b          	sext.w	a5,s1
    800039de:	fce7e1e3          	bltu	a5,a4,800039a0 <ialloc+0x32>
  panic("ialloc: no inodes");
    800039e2:	00005517          	auipc	a0,0x5
    800039e6:	bee50513          	addi	a0,a0,-1042 # 800085d0 <syscalls+0x188>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	b52080e7          	jalr	-1198(ra) # 8000053c <panic>
      memset(dip, 0, sizeof(*dip));
    800039f2:	04000613          	li	a2,64
    800039f6:	4581                	li	a1,0
    800039f8:	854e                	mv	a0,s3
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	31e080e7          	jalr	798(ra) # 80000d18 <memset>
      dip->type = type;
    80003a02:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a06:	854a                	mv	a0,s2
    80003a08:	00001097          	auipc	ra,0x1
    80003a0c:	cb2080e7          	jalr	-846(ra) # 800046ba <log_write>
      brelse(bp);
    80003a10:	854a                	mv	a0,s2
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	a24080e7          	jalr	-1500(ra) # 80003436 <brelse>
      return iget(dev, inum);
    80003a1a:	85da                	mv	a1,s6
    80003a1c:	8556                	mv	a0,s5
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	db4080e7          	jalr	-588(ra) # 800037d2 <iget>
}
    80003a26:	60a6                	ld	ra,72(sp)
    80003a28:	6406                	ld	s0,64(sp)
    80003a2a:	74e2                	ld	s1,56(sp)
    80003a2c:	7942                	ld	s2,48(sp)
    80003a2e:	79a2                	ld	s3,40(sp)
    80003a30:	7a02                	ld	s4,32(sp)
    80003a32:	6ae2                	ld	s5,24(sp)
    80003a34:	6b42                	ld	s6,16(sp)
    80003a36:	6ba2                	ld	s7,8(sp)
    80003a38:	6161                	addi	sp,sp,80
    80003a3a:	8082                	ret

0000000080003a3c <iupdate>:
{
    80003a3c:	1101                	addi	sp,sp,-32
    80003a3e:	ec06                	sd	ra,24(sp)
    80003a40:	e822                	sd	s0,16(sp)
    80003a42:	e426                	sd	s1,8(sp)
    80003a44:	e04a                	sd	s2,0(sp)
    80003a46:	1000                	addi	s0,sp,32
    80003a48:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a4a:	415c                	lw	a5,4(a0)
    80003a4c:	0047d79b          	srliw	a5,a5,0x4
    80003a50:	0002c597          	auipc	a1,0x2c
    80003a54:	3885a583          	lw	a1,904(a1) # 8002fdd8 <sb+0x18>
    80003a58:	9dbd                	addw	a1,a1,a5
    80003a5a:	4108                	lw	a0,0(a0)
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	8aa080e7          	jalr	-1878(ra) # 80003306 <bread>
    80003a64:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a66:	05850793          	addi	a5,a0,88
    80003a6a:	40d8                	lw	a4,4(s1)
    80003a6c:	8b3d                	andi	a4,a4,15
    80003a6e:	071a                	slli	a4,a4,0x6
    80003a70:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a72:	04449703          	lh	a4,68(s1)
    80003a76:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a7a:	04649703          	lh	a4,70(s1)
    80003a7e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a82:	04849703          	lh	a4,72(s1)
    80003a86:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a8a:	04a49703          	lh	a4,74(s1)
    80003a8e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a92:	44f8                	lw	a4,76(s1)
    80003a94:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a96:	03400613          	li	a2,52
    80003a9a:	05048593          	addi	a1,s1,80
    80003a9e:	00c78513          	addi	a0,a5,12
    80003aa2:	ffffd097          	auipc	ra,0xffffd
    80003aa6:	2d2080e7          	jalr	722(ra) # 80000d74 <memmove>
  log_write(bp);
    80003aaa:	854a                	mv	a0,s2
    80003aac:	00001097          	auipc	ra,0x1
    80003ab0:	c0e080e7          	jalr	-1010(ra) # 800046ba <log_write>
  brelse(bp);
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	980080e7          	jalr	-1664(ra) # 80003436 <brelse>
}
    80003abe:	60e2                	ld	ra,24(sp)
    80003ac0:	6442                	ld	s0,16(sp)
    80003ac2:	64a2                	ld	s1,8(sp)
    80003ac4:	6902                	ld	s2,0(sp)
    80003ac6:	6105                	addi	sp,sp,32
    80003ac8:	8082                	ret

0000000080003aca <idup>:
{
    80003aca:	1101                	addi	sp,sp,-32
    80003acc:	ec06                	sd	ra,24(sp)
    80003ace:	e822                	sd	s0,16(sp)
    80003ad0:	e426                	sd	s1,8(sp)
    80003ad2:	1000                	addi	s0,sp,32
    80003ad4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ad6:	0002c517          	auipc	a0,0x2c
    80003ada:	30a50513          	addi	a0,a0,778 # 8002fde0 <itable>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	13e080e7          	jalr	318(ra) # 80000c1c <acquire>
  ip->ref++;
    80003ae6:	449c                	lw	a5,8(s1)
    80003ae8:	2785                	addiw	a5,a5,1
    80003aea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aec:	0002c517          	auipc	a0,0x2c
    80003af0:	2f450513          	addi	a0,a0,756 # 8002fde0 <itable>
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	1dc080e7          	jalr	476(ra) # 80000cd0 <release>
}
    80003afc:	8526                	mv	a0,s1
    80003afe:	60e2                	ld	ra,24(sp)
    80003b00:	6442                	ld	s0,16(sp)
    80003b02:	64a2                	ld	s1,8(sp)
    80003b04:	6105                	addi	sp,sp,32
    80003b06:	8082                	ret

0000000080003b08 <ilock>:
{
    80003b08:	1101                	addi	sp,sp,-32
    80003b0a:	ec06                	sd	ra,24(sp)
    80003b0c:	e822                	sd	s0,16(sp)
    80003b0e:	e426                	sd	s1,8(sp)
    80003b10:	e04a                	sd	s2,0(sp)
    80003b12:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b14:	c115                	beqz	a0,80003b38 <ilock+0x30>
    80003b16:	84aa                	mv	s1,a0
    80003b18:	451c                	lw	a5,8(a0)
    80003b1a:	00f05f63          	blez	a5,80003b38 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b1e:	0541                	addi	a0,a0,16
    80003b20:	00001097          	auipc	ra,0x1
    80003b24:	cb8080e7          	jalr	-840(ra) # 800047d8 <acquiresleep>
  if(ip->valid == 0){
    80003b28:	40bc                	lw	a5,64(s1)
    80003b2a:	cf99                	beqz	a5,80003b48 <ilock+0x40>
}
    80003b2c:	60e2                	ld	ra,24(sp)
    80003b2e:	6442                	ld	s0,16(sp)
    80003b30:	64a2                	ld	s1,8(sp)
    80003b32:	6902                	ld	s2,0(sp)
    80003b34:	6105                	addi	sp,sp,32
    80003b36:	8082                	ret
    panic("ilock");
    80003b38:	00005517          	auipc	a0,0x5
    80003b3c:	ab050513          	addi	a0,a0,-1360 # 800085e8 <syscalls+0x1a0>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	9fc080e7          	jalr	-1540(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b48:	40dc                	lw	a5,4(s1)
    80003b4a:	0047d79b          	srliw	a5,a5,0x4
    80003b4e:	0002c597          	auipc	a1,0x2c
    80003b52:	28a5a583          	lw	a1,650(a1) # 8002fdd8 <sb+0x18>
    80003b56:	9dbd                	addw	a1,a1,a5
    80003b58:	4088                	lw	a0,0(s1)
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	7ac080e7          	jalr	1964(ra) # 80003306 <bread>
    80003b62:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b64:	05850593          	addi	a1,a0,88
    80003b68:	40dc                	lw	a5,4(s1)
    80003b6a:	8bbd                	andi	a5,a5,15
    80003b6c:	079a                	slli	a5,a5,0x6
    80003b6e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b70:	00059783          	lh	a5,0(a1)
    80003b74:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b78:	00259783          	lh	a5,2(a1)
    80003b7c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b80:	00459783          	lh	a5,4(a1)
    80003b84:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b88:	00659783          	lh	a5,6(a1)
    80003b8c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b90:	459c                	lw	a5,8(a1)
    80003b92:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b94:	03400613          	li	a2,52
    80003b98:	05b1                	addi	a1,a1,12
    80003b9a:	05048513          	addi	a0,s1,80
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	1d6080e7          	jalr	470(ra) # 80000d74 <memmove>
    brelse(bp);
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	88e080e7          	jalr	-1906(ra) # 80003436 <brelse>
    ip->valid = 1;
    80003bb0:	4785                	li	a5,1
    80003bb2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bb4:	04449783          	lh	a5,68(s1)
    80003bb8:	fbb5                	bnez	a5,80003b2c <ilock+0x24>
      panic("ilock: no type");
    80003bba:	00005517          	auipc	a0,0x5
    80003bbe:	a3650513          	addi	a0,a0,-1482 # 800085f0 <syscalls+0x1a8>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	97a080e7          	jalr	-1670(ra) # 8000053c <panic>

0000000080003bca <iunlock>:
{
    80003bca:	1101                	addi	sp,sp,-32
    80003bcc:	ec06                	sd	ra,24(sp)
    80003bce:	e822                	sd	s0,16(sp)
    80003bd0:	e426                	sd	s1,8(sp)
    80003bd2:	e04a                	sd	s2,0(sp)
    80003bd4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bd6:	c905                	beqz	a0,80003c06 <iunlock+0x3c>
    80003bd8:	84aa                	mv	s1,a0
    80003bda:	01050913          	addi	s2,a0,16
    80003bde:	854a                	mv	a0,s2
    80003be0:	00001097          	auipc	ra,0x1
    80003be4:	c94080e7          	jalr	-876(ra) # 80004874 <holdingsleep>
    80003be8:	cd19                	beqz	a0,80003c06 <iunlock+0x3c>
    80003bea:	449c                	lw	a5,8(s1)
    80003bec:	00f05d63          	blez	a5,80003c06 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bf0:	854a                	mv	a0,s2
    80003bf2:	00001097          	auipc	ra,0x1
    80003bf6:	c3e080e7          	jalr	-962(ra) # 80004830 <releasesleep>
}
    80003bfa:	60e2                	ld	ra,24(sp)
    80003bfc:	6442                	ld	s0,16(sp)
    80003bfe:	64a2                	ld	s1,8(sp)
    80003c00:	6902                	ld	s2,0(sp)
    80003c02:	6105                	addi	sp,sp,32
    80003c04:	8082                	ret
    panic("iunlock");
    80003c06:	00005517          	auipc	a0,0x5
    80003c0a:	9fa50513          	addi	a0,a0,-1542 # 80008600 <syscalls+0x1b8>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	92e080e7          	jalr	-1746(ra) # 8000053c <panic>

0000000080003c16 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c16:	7179                	addi	sp,sp,-48
    80003c18:	f406                	sd	ra,40(sp)
    80003c1a:	f022                	sd	s0,32(sp)
    80003c1c:	ec26                	sd	s1,24(sp)
    80003c1e:	e84a                	sd	s2,16(sp)
    80003c20:	e44e                	sd	s3,8(sp)
    80003c22:	e052                	sd	s4,0(sp)
    80003c24:	1800                	addi	s0,sp,48
    80003c26:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c28:	05050493          	addi	s1,a0,80
    80003c2c:	08050913          	addi	s2,a0,128
    80003c30:	a021                	j	80003c38 <itrunc+0x22>
    80003c32:	0491                	addi	s1,s1,4
    80003c34:	01248d63          	beq	s1,s2,80003c4e <itrunc+0x38>
    if(ip->addrs[i]){
    80003c38:	408c                	lw	a1,0(s1)
    80003c3a:	dde5                	beqz	a1,80003c32 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c3c:	0009a503          	lw	a0,0(s3)
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	90c080e7          	jalr	-1780(ra) # 8000354c <bfree>
      ip->addrs[i] = 0;
    80003c48:	0004a023          	sw	zero,0(s1)
    80003c4c:	b7dd                	j	80003c32 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c4e:	0809a583          	lw	a1,128(s3)
    80003c52:	e185                	bnez	a1,80003c72 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c54:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c58:	854e                	mv	a0,s3
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	de2080e7          	jalr	-542(ra) # 80003a3c <iupdate>
}
    80003c62:	70a2                	ld	ra,40(sp)
    80003c64:	7402                	ld	s0,32(sp)
    80003c66:	64e2                	ld	s1,24(sp)
    80003c68:	6942                	ld	s2,16(sp)
    80003c6a:	69a2                	ld	s3,8(sp)
    80003c6c:	6a02                	ld	s4,0(sp)
    80003c6e:	6145                	addi	sp,sp,48
    80003c70:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c72:	0009a503          	lw	a0,0(s3)
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	690080e7          	jalr	1680(ra) # 80003306 <bread>
    80003c7e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c80:	05850493          	addi	s1,a0,88
    80003c84:	45850913          	addi	s2,a0,1112
    80003c88:	a021                	j	80003c90 <itrunc+0x7a>
    80003c8a:	0491                	addi	s1,s1,4
    80003c8c:	01248b63          	beq	s1,s2,80003ca2 <itrunc+0x8c>
      if(a[j])
    80003c90:	408c                	lw	a1,0(s1)
    80003c92:	dde5                	beqz	a1,80003c8a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c94:	0009a503          	lw	a0,0(s3)
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	8b4080e7          	jalr	-1868(ra) # 8000354c <bfree>
    80003ca0:	b7ed                	j	80003c8a <itrunc+0x74>
    brelse(bp);
    80003ca2:	8552                	mv	a0,s4
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	792080e7          	jalr	1938(ra) # 80003436 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cac:	0809a583          	lw	a1,128(s3)
    80003cb0:	0009a503          	lw	a0,0(s3)
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	898080e7          	jalr	-1896(ra) # 8000354c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cbc:	0809a023          	sw	zero,128(s3)
    80003cc0:	bf51                	j	80003c54 <itrunc+0x3e>

0000000080003cc2 <iput>:
{
    80003cc2:	1101                	addi	sp,sp,-32
    80003cc4:	ec06                	sd	ra,24(sp)
    80003cc6:	e822                	sd	s0,16(sp)
    80003cc8:	e426                	sd	s1,8(sp)
    80003cca:	e04a                	sd	s2,0(sp)
    80003ccc:	1000                	addi	s0,sp,32
    80003cce:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cd0:	0002c517          	auipc	a0,0x2c
    80003cd4:	11050513          	addi	a0,a0,272 # 8002fde0 <itable>
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	f44080e7          	jalr	-188(ra) # 80000c1c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ce0:	4498                	lw	a4,8(s1)
    80003ce2:	4785                	li	a5,1
    80003ce4:	02f70363          	beq	a4,a5,80003d0a <iput+0x48>
  ip->ref--;
    80003ce8:	449c                	lw	a5,8(s1)
    80003cea:	37fd                	addiw	a5,a5,-1
    80003cec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cee:	0002c517          	auipc	a0,0x2c
    80003cf2:	0f250513          	addi	a0,a0,242 # 8002fde0 <itable>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	fda080e7          	jalr	-38(ra) # 80000cd0 <release>
}
    80003cfe:	60e2                	ld	ra,24(sp)
    80003d00:	6442                	ld	s0,16(sp)
    80003d02:	64a2                	ld	s1,8(sp)
    80003d04:	6902                	ld	s2,0(sp)
    80003d06:	6105                	addi	sp,sp,32
    80003d08:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d0a:	40bc                	lw	a5,64(s1)
    80003d0c:	dff1                	beqz	a5,80003ce8 <iput+0x26>
    80003d0e:	04a49783          	lh	a5,74(s1)
    80003d12:	fbf9                	bnez	a5,80003ce8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d14:	01048913          	addi	s2,s1,16
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00001097          	auipc	ra,0x1
    80003d1e:	abe080e7          	jalr	-1346(ra) # 800047d8 <acquiresleep>
    release(&itable.lock);
    80003d22:	0002c517          	auipc	a0,0x2c
    80003d26:	0be50513          	addi	a0,a0,190 # 8002fde0 <itable>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	fa6080e7          	jalr	-90(ra) # 80000cd0 <release>
    itrunc(ip);
    80003d32:	8526                	mv	a0,s1
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	ee2080e7          	jalr	-286(ra) # 80003c16 <itrunc>
    ip->type = 0;
    80003d3c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d40:	8526                	mv	a0,s1
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	cfa080e7          	jalr	-774(ra) # 80003a3c <iupdate>
    ip->valid = 0;
    80003d4a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d4e:	854a                	mv	a0,s2
    80003d50:	00001097          	auipc	ra,0x1
    80003d54:	ae0080e7          	jalr	-1312(ra) # 80004830 <releasesleep>
    acquire(&itable.lock);
    80003d58:	0002c517          	auipc	a0,0x2c
    80003d5c:	08850513          	addi	a0,a0,136 # 8002fde0 <itable>
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	ebc080e7          	jalr	-324(ra) # 80000c1c <acquire>
    80003d68:	b741                	j	80003ce8 <iput+0x26>

0000000080003d6a <iunlockput>:
{
    80003d6a:	1101                	addi	sp,sp,-32
    80003d6c:	ec06                	sd	ra,24(sp)
    80003d6e:	e822                	sd	s0,16(sp)
    80003d70:	e426                	sd	s1,8(sp)
    80003d72:	1000                	addi	s0,sp,32
    80003d74:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	e54080e7          	jalr	-428(ra) # 80003bca <iunlock>
  iput(ip);
    80003d7e:	8526                	mv	a0,s1
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	f42080e7          	jalr	-190(ra) # 80003cc2 <iput>
}
    80003d88:	60e2                	ld	ra,24(sp)
    80003d8a:	6442                	ld	s0,16(sp)
    80003d8c:	64a2                	ld	s1,8(sp)
    80003d8e:	6105                	addi	sp,sp,32
    80003d90:	8082                	ret

0000000080003d92 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d92:	1141                	addi	sp,sp,-16
    80003d94:	e422                	sd	s0,8(sp)
    80003d96:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d98:	411c                	lw	a5,0(a0)
    80003d9a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d9c:	415c                	lw	a5,4(a0)
    80003d9e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003da0:	04451783          	lh	a5,68(a0)
    80003da4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003da8:	04a51783          	lh	a5,74(a0)
    80003dac:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003db0:	04c56783          	lwu	a5,76(a0)
    80003db4:	e99c                	sd	a5,16(a1)
}
    80003db6:	6422                	ld	s0,8(sp)
    80003db8:	0141                	addi	sp,sp,16
    80003dba:	8082                	ret

0000000080003dbc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dbc:	457c                	lw	a5,76(a0)
    80003dbe:	0ed7e963          	bltu	a5,a3,80003eb0 <readi+0xf4>
{
    80003dc2:	7159                	addi	sp,sp,-112
    80003dc4:	f486                	sd	ra,104(sp)
    80003dc6:	f0a2                	sd	s0,96(sp)
    80003dc8:	eca6                	sd	s1,88(sp)
    80003dca:	e8ca                	sd	s2,80(sp)
    80003dcc:	e4ce                	sd	s3,72(sp)
    80003dce:	e0d2                	sd	s4,64(sp)
    80003dd0:	fc56                	sd	s5,56(sp)
    80003dd2:	f85a                	sd	s6,48(sp)
    80003dd4:	f45e                	sd	s7,40(sp)
    80003dd6:	f062                	sd	s8,32(sp)
    80003dd8:	ec66                	sd	s9,24(sp)
    80003dda:	e86a                	sd	s10,16(sp)
    80003ddc:	e46e                	sd	s11,8(sp)
    80003dde:	1880                	addi	s0,sp,112
    80003de0:	8baa                	mv	s7,a0
    80003de2:	8c2e                	mv	s8,a1
    80003de4:	8ab2                	mv	s5,a2
    80003de6:	84b6                	mv	s1,a3
    80003de8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dea:	9f35                	addw	a4,a4,a3
    return 0;
    80003dec:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dee:	0ad76063          	bltu	a4,a3,80003e8e <readi+0xd2>
  if(off + n > ip->size)
    80003df2:	00e7f463          	bgeu	a5,a4,80003dfa <readi+0x3e>
    n = ip->size - off;
    80003df6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dfa:	0a0b0963          	beqz	s6,80003eac <readi+0xf0>
    80003dfe:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e00:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e04:	5cfd                	li	s9,-1
    80003e06:	a82d                	j	80003e40 <readi+0x84>
    80003e08:	020a1d93          	slli	s11,s4,0x20
    80003e0c:	020ddd93          	srli	s11,s11,0x20
    80003e10:	05890613          	addi	a2,s2,88
    80003e14:	86ee                	mv	a3,s11
    80003e16:	963a                	add	a2,a2,a4
    80003e18:	85d6                	mv	a1,s5
    80003e1a:	8562                	mv	a0,s8
    80003e1c:	ffffe097          	auipc	ra,0xffffe
    80003e20:	72e080e7          	jalr	1838(ra) # 8000254a <either_copyout>
    80003e24:	05950d63          	beq	a0,s9,80003e7e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e28:	854a                	mv	a0,s2
    80003e2a:	fffff097          	auipc	ra,0xfffff
    80003e2e:	60c080e7          	jalr	1548(ra) # 80003436 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e32:	013a09bb          	addw	s3,s4,s3
    80003e36:	009a04bb          	addw	s1,s4,s1
    80003e3a:	9aee                	add	s5,s5,s11
    80003e3c:	0569f763          	bgeu	s3,s6,80003e8a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e40:	000ba903          	lw	s2,0(s7)
    80003e44:	00a4d59b          	srliw	a1,s1,0xa
    80003e48:	855e                	mv	a0,s7
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	8ac080e7          	jalr	-1876(ra) # 800036f6 <bmap>
    80003e52:	0005059b          	sext.w	a1,a0
    80003e56:	854a                	mv	a0,s2
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	4ae080e7          	jalr	1198(ra) # 80003306 <bread>
    80003e60:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e62:	3ff4f713          	andi	a4,s1,1023
    80003e66:	40ed07bb          	subw	a5,s10,a4
    80003e6a:	413b06bb          	subw	a3,s6,s3
    80003e6e:	8a3e                	mv	s4,a5
    80003e70:	2781                	sext.w	a5,a5
    80003e72:	0006861b          	sext.w	a2,a3
    80003e76:	f8f679e3          	bgeu	a2,a5,80003e08 <readi+0x4c>
    80003e7a:	8a36                	mv	s4,a3
    80003e7c:	b771                	j	80003e08 <readi+0x4c>
      brelse(bp);
    80003e7e:	854a                	mv	a0,s2
    80003e80:	fffff097          	auipc	ra,0xfffff
    80003e84:	5b6080e7          	jalr	1462(ra) # 80003436 <brelse>
      tot = -1;
    80003e88:	59fd                	li	s3,-1
  }
  return tot;
    80003e8a:	0009851b          	sext.w	a0,s3
}
    80003e8e:	70a6                	ld	ra,104(sp)
    80003e90:	7406                	ld	s0,96(sp)
    80003e92:	64e6                	ld	s1,88(sp)
    80003e94:	6946                	ld	s2,80(sp)
    80003e96:	69a6                	ld	s3,72(sp)
    80003e98:	6a06                	ld	s4,64(sp)
    80003e9a:	7ae2                	ld	s5,56(sp)
    80003e9c:	7b42                	ld	s6,48(sp)
    80003e9e:	7ba2                	ld	s7,40(sp)
    80003ea0:	7c02                	ld	s8,32(sp)
    80003ea2:	6ce2                	ld	s9,24(sp)
    80003ea4:	6d42                	ld	s10,16(sp)
    80003ea6:	6da2                	ld	s11,8(sp)
    80003ea8:	6165                	addi	sp,sp,112
    80003eaa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eac:	89da                	mv	s3,s6
    80003eae:	bff1                	j	80003e8a <readi+0xce>
    return 0;
    80003eb0:	4501                	li	a0,0
}
    80003eb2:	8082                	ret

0000000080003eb4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eb4:	457c                	lw	a5,76(a0)
    80003eb6:	10d7e863          	bltu	a5,a3,80003fc6 <writei+0x112>
{
    80003eba:	7159                	addi	sp,sp,-112
    80003ebc:	f486                	sd	ra,104(sp)
    80003ebe:	f0a2                	sd	s0,96(sp)
    80003ec0:	eca6                	sd	s1,88(sp)
    80003ec2:	e8ca                	sd	s2,80(sp)
    80003ec4:	e4ce                	sd	s3,72(sp)
    80003ec6:	e0d2                	sd	s4,64(sp)
    80003ec8:	fc56                	sd	s5,56(sp)
    80003eca:	f85a                	sd	s6,48(sp)
    80003ecc:	f45e                	sd	s7,40(sp)
    80003ece:	f062                	sd	s8,32(sp)
    80003ed0:	ec66                	sd	s9,24(sp)
    80003ed2:	e86a                	sd	s10,16(sp)
    80003ed4:	e46e                	sd	s11,8(sp)
    80003ed6:	1880                	addi	s0,sp,112
    80003ed8:	8b2a                	mv	s6,a0
    80003eda:	8c2e                	mv	s8,a1
    80003edc:	8ab2                	mv	s5,a2
    80003ede:	8936                	mv	s2,a3
    80003ee0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ee2:	00e687bb          	addw	a5,a3,a4
    80003ee6:	0ed7e263          	bltu	a5,a3,80003fca <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003eea:	00043737          	lui	a4,0x43
    80003eee:	0ef76063          	bltu	a4,a5,80003fce <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ef2:	0c0b8863          	beqz	s7,80003fc2 <writei+0x10e>
    80003ef6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003efc:	5cfd                	li	s9,-1
    80003efe:	a091                	j	80003f42 <writei+0x8e>
    80003f00:	02099d93          	slli	s11,s3,0x20
    80003f04:	020ddd93          	srli	s11,s11,0x20
    80003f08:	05848513          	addi	a0,s1,88
    80003f0c:	86ee                	mv	a3,s11
    80003f0e:	8656                	mv	a2,s5
    80003f10:	85e2                	mv	a1,s8
    80003f12:	953a                	add	a0,a0,a4
    80003f14:	ffffe097          	auipc	ra,0xffffe
    80003f18:	68e080e7          	jalr	1678(ra) # 800025a2 <either_copyin>
    80003f1c:	07950263          	beq	a0,s9,80003f80 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f20:	8526                	mv	a0,s1
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	798080e7          	jalr	1944(ra) # 800046ba <log_write>
    brelse(bp);
    80003f2a:	8526                	mv	a0,s1
    80003f2c:	fffff097          	auipc	ra,0xfffff
    80003f30:	50a080e7          	jalr	1290(ra) # 80003436 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f34:	01498a3b          	addw	s4,s3,s4
    80003f38:	0129893b          	addw	s2,s3,s2
    80003f3c:	9aee                	add	s5,s5,s11
    80003f3e:	057a7663          	bgeu	s4,s7,80003f8a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f42:	000b2483          	lw	s1,0(s6)
    80003f46:	00a9559b          	srliw	a1,s2,0xa
    80003f4a:	855a                	mv	a0,s6
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	7aa080e7          	jalr	1962(ra) # 800036f6 <bmap>
    80003f54:	0005059b          	sext.w	a1,a0
    80003f58:	8526                	mv	a0,s1
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	3ac080e7          	jalr	940(ra) # 80003306 <bread>
    80003f62:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f64:	3ff97713          	andi	a4,s2,1023
    80003f68:	40ed07bb          	subw	a5,s10,a4
    80003f6c:	414b86bb          	subw	a3,s7,s4
    80003f70:	89be                	mv	s3,a5
    80003f72:	2781                	sext.w	a5,a5
    80003f74:	0006861b          	sext.w	a2,a3
    80003f78:	f8f674e3          	bgeu	a2,a5,80003f00 <writei+0x4c>
    80003f7c:	89b6                	mv	s3,a3
    80003f7e:	b749                	j	80003f00 <writei+0x4c>
      brelse(bp);
    80003f80:	8526                	mv	a0,s1
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	4b4080e7          	jalr	1204(ra) # 80003436 <brelse>
  }

  if(off > ip->size)
    80003f8a:	04cb2783          	lw	a5,76(s6)
    80003f8e:	0127f463          	bgeu	a5,s2,80003f96 <writei+0xe2>
    ip->size = off;
    80003f92:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f96:	855a                	mv	a0,s6
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	aa4080e7          	jalr	-1372(ra) # 80003a3c <iupdate>

  return tot;
    80003fa0:	000a051b          	sext.w	a0,s4
}
    80003fa4:	70a6                	ld	ra,104(sp)
    80003fa6:	7406                	ld	s0,96(sp)
    80003fa8:	64e6                	ld	s1,88(sp)
    80003faa:	6946                	ld	s2,80(sp)
    80003fac:	69a6                	ld	s3,72(sp)
    80003fae:	6a06                	ld	s4,64(sp)
    80003fb0:	7ae2                	ld	s5,56(sp)
    80003fb2:	7b42                	ld	s6,48(sp)
    80003fb4:	7ba2                	ld	s7,40(sp)
    80003fb6:	7c02                	ld	s8,32(sp)
    80003fb8:	6ce2                	ld	s9,24(sp)
    80003fba:	6d42                	ld	s10,16(sp)
    80003fbc:	6da2                	ld	s11,8(sp)
    80003fbe:	6165                	addi	sp,sp,112
    80003fc0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fc2:	8a5e                	mv	s4,s7
    80003fc4:	bfc9                	j	80003f96 <writei+0xe2>
    return -1;
    80003fc6:	557d                	li	a0,-1
}
    80003fc8:	8082                	ret
    return -1;
    80003fca:	557d                	li	a0,-1
    80003fcc:	bfe1                	j	80003fa4 <writei+0xf0>
    return -1;
    80003fce:	557d                	li	a0,-1
    80003fd0:	bfd1                	j	80003fa4 <writei+0xf0>

0000000080003fd2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fd2:	1141                	addi	sp,sp,-16
    80003fd4:	e406                	sd	ra,8(sp)
    80003fd6:	e022                	sd	s0,0(sp)
    80003fd8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fda:	4639                	li	a2,14
    80003fdc:	ffffd097          	auipc	ra,0xffffd
    80003fe0:	e0c080e7          	jalr	-500(ra) # 80000de8 <strncmp>
}
    80003fe4:	60a2                	ld	ra,8(sp)
    80003fe6:	6402                	ld	s0,0(sp)
    80003fe8:	0141                	addi	sp,sp,16
    80003fea:	8082                	ret

0000000080003fec <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fec:	7139                	addi	sp,sp,-64
    80003fee:	fc06                	sd	ra,56(sp)
    80003ff0:	f822                	sd	s0,48(sp)
    80003ff2:	f426                	sd	s1,40(sp)
    80003ff4:	f04a                	sd	s2,32(sp)
    80003ff6:	ec4e                	sd	s3,24(sp)
    80003ff8:	e852                	sd	s4,16(sp)
    80003ffa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ffc:	04451703          	lh	a4,68(a0)
    80004000:	4785                	li	a5,1
    80004002:	00f71a63          	bne	a4,a5,80004016 <dirlookup+0x2a>
    80004006:	892a                	mv	s2,a0
    80004008:	89ae                	mv	s3,a1
    8000400a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400c:	457c                	lw	a5,76(a0)
    8000400e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004010:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004012:	e79d                	bnez	a5,80004040 <dirlookup+0x54>
    80004014:	a8a5                	j	8000408c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004016:	00004517          	auipc	a0,0x4
    8000401a:	5f250513          	addi	a0,a0,1522 # 80008608 <syscalls+0x1c0>
    8000401e:	ffffc097          	auipc	ra,0xffffc
    80004022:	51e080e7          	jalr	1310(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004026:	00004517          	auipc	a0,0x4
    8000402a:	5fa50513          	addi	a0,a0,1530 # 80008620 <syscalls+0x1d8>
    8000402e:	ffffc097          	auipc	ra,0xffffc
    80004032:	50e080e7          	jalr	1294(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004036:	24c1                	addiw	s1,s1,16
    80004038:	04c92783          	lw	a5,76(s2)
    8000403c:	04f4f763          	bgeu	s1,a5,8000408a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004040:	4741                	li	a4,16
    80004042:	86a6                	mv	a3,s1
    80004044:	fc040613          	addi	a2,s0,-64
    80004048:	4581                	li	a1,0
    8000404a:	854a                	mv	a0,s2
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	d70080e7          	jalr	-656(ra) # 80003dbc <readi>
    80004054:	47c1                	li	a5,16
    80004056:	fcf518e3          	bne	a0,a5,80004026 <dirlookup+0x3a>
    if(de.inum == 0)
    8000405a:	fc045783          	lhu	a5,-64(s0)
    8000405e:	dfe1                	beqz	a5,80004036 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004060:	fc240593          	addi	a1,s0,-62
    80004064:	854e                	mv	a0,s3
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	f6c080e7          	jalr	-148(ra) # 80003fd2 <namecmp>
    8000406e:	f561                	bnez	a0,80004036 <dirlookup+0x4a>
      if(poff)
    80004070:	000a0463          	beqz	s4,80004078 <dirlookup+0x8c>
        *poff = off;
    80004074:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004078:	fc045583          	lhu	a1,-64(s0)
    8000407c:	00092503          	lw	a0,0(s2)
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	752080e7          	jalr	1874(ra) # 800037d2 <iget>
    80004088:	a011                	j	8000408c <dirlookup+0xa0>
  return 0;
    8000408a:	4501                	li	a0,0
}
    8000408c:	70e2                	ld	ra,56(sp)
    8000408e:	7442                	ld	s0,48(sp)
    80004090:	74a2                	ld	s1,40(sp)
    80004092:	7902                	ld	s2,32(sp)
    80004094:	69e2                	ld	s3,24(sp)
    80004096:	6a42                	ld	s4,16(sp)
    80004098:	6121                	addi	sp,sp,64
    8000409a:	8082                	ret

000000008000409c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000409c:	711d                	addi	sp,sp,-96
    8000409e:	ec86                	sd	ra,88(sp)
    800040a0:	e8a2                	sd	s0,80(sp)
    800040a2:	e4a6                	sd	s1,72(sp)
    800040a4:	e0ca                	sd	s2,64(sp)
    800040a6:	fc4e                	sd	s3,56(sp)
    800040a8:	f852                	sd	s4,48(sp)
    800040aa:	f456                	sd	s5,40(sp)
    800040ac:	f05a                	sd	s6,32(sp)
    800040ae:	ec5e                	sd	s7,24(sp)
    800040b0:	e862                	sd	s8,16(sp)
    800040b2:	e466                	sd	s9,8(sp)
    800040b4:	e06a                	sd	s10,0(sp)
    800040b6:	1080                	addi	s0,sp,96
    800040b8:	84aa                	mv	s1,a0
    800040ba:	8b2e                	mv	s6,a1
    800040bc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040be:	00054703          	lbu	a4,0(a0)
    800040c2:	02f00793          	li	a5,47
    800040c6:	02f70363          	beq	a4,a5,800040ec <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040ca:	ffffe097          	auipc	ra,0xffffe
    800040ce:	974080e7          	jalr	-1676(ra) # 80001a3e <myproc>
    800040d2:	42853503          	ld	a0,1064(a0)
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	9f4080e7          	jalr	-1548(ra) # 80003aca <idup>
    800040de:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040e0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040e4:	4cb5                	li	s9,13
  len = path - s;
    800040e6:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040e8:	4c05                	li	s8,1
    800040ea:	a87d                	j	800041a8 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040ec:	4585                	li	a1,1
    800040ee:	4505                	li	a0,1
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	6e2080e7          	jalr	1762(ra) # 800037d2 <iget>
    800040f8:	8a2a                	mv	s4,a0
    800040fa:	b7dd                	j	800040e0 <namex+0x44>
      iunlockput(ip);
    800040fc:	8552                	mv	a0,s4
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	c6c080e7          	jalr	-916(ra) # 80003d6a <iunlockput>
      return 0;
    80004106:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004108:	8552                	mv	a0,s4
    8000410a:	60e6                	ld	ra,88(sp)
    8000410c:	6446                	ld	s0,80(sp)
    8000410e:	64a6                	ld	s1,72(sp)
    80004110:	6906                	ld	s2,64(sp)
    80004112:	79e2                	ld	s3,56(sp)
    80004114:	7a42                	ld	s4,48(sp)
    80004116:	7aa2                	ld	s5,40(sp)
    80004118:	7b02                	ld	s6,32(sp)
    8000411a:	6be2                	ld	s7,24(sp)
    8000411c:	6c42                	ld	s8,16(sp)
    8000411e:	6ca2                	ld	s9,8(sp)
    80004120:	6d02                	ld	s10,0(sp)
    80004122:	6125                	addi	sp,sp,96
    80004124:	8082                	ret
      iunlock(ip);
    80004126:	8552                	mv	a0,s4
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	aa2080e7          	jalr	-1374(ra) # 80003bca <iunlock>
      return ip;
    80004130:	bfe1                	j	80004108 <namex+0x6c>
      iunlockput(ip);
    80004132:	8552                	mv	a0,s4
    80004134:	00000097          	auipc	ra,0x0
    80004138:	c36080e7          	jalr	-970(ra) # 80003d6a <iunlockput>
      return 0;
    8000413c:	8a4e                	mv	s4,s3
    8000413e:	b7e9                	j	80004108 <namex+0x6c>
  len = path - s;
    80004140:	40998633          	sub	a2,s3,s1
    80004144:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004148:	09acd863          	bge	s9,s10,800041d8 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000414c:	4639                	li	a2,14
    8000414e:	85a6                	mv	a1,s1
    80004150:	8556                	mv	a0,s5
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	c22080e7          	jalr	-990(ra) # 80000d74 <memmove>
    8000415a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000415c:	0004c783          	lbu	a5,0(s1)
    80004160:	01279763          	bne	a5,s2,8000416e <namex+0xd2>
    path++;
    80004164:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004166:	0004c783          	lbu	a5,0(s1)
    8000416a:	ff278de3          	beq	a5,s2,80004164 <namex+0xc8>
    ilock(ip);
    8000416e:	8552                	mv	a0,s4
    80004170:	00000097          	auipc	ra,0x0
    80004174:	998080e7          	jalr	-1640(ra) # 80003b08 <ilock>
    if(ip->type != T_DIR){
    80004178:	044a1783          	lh	a5,68(s4)
    8000417c:	f98790e3          	bne	a5,s8,800040fc <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004180:	000b0563          	beqz	s6,8000418a <namex+0xee>
    80004184:	0004c783          	lbu	a5,0(s1)
    80004188:	dfd9                	beqz	a5,80004126 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000418a:	865e                	mv	a2,s7
    8000418c:	85d6                	mv	a1,s5
    8000418e:	8552                	mv	a0,s4
    80004190:	00000097          	auipc	ra,0x0
    80004194:	e5c080e7          	jalr	-420(ra) # 80003fec <dirlookup>
    80004198:	89aa                	mv	s3,a0
    8000419a:	dd41                	beqz	a0,80004132 <namex+0x96>
    iunlockput(ip);
    8000419c:	8552                	mv	a0,s4
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	bcc080e7          	jalr	-1076(ra) # 80003d6a <iunlockput>
    ip = next;
    800041a6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041a8:	0004c783          	lbu	a5,0(s1)
    800041ac:	01279763          	bne	a5,s2,800041ba <namex+0x11e>
    path++;
    800041b0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041b2:	0004c783          	lbu	a5,0(s1)
    800041b6:	ff278de3          	beq	a5,s2,800041b0 <namex+0x114>
  if(*path == 0)
    800041ba:	cb9d                	beqz	a5,800041f0 <namex+0x154>
  while(*path != '/' && *path != 0)
    800041bc:	0004c783          	lbu	a5,0(s1)
    800041c0:	89a6                	mv	s3,s1
  len = path - s;
    800041c2:	8d5e                	mv	s10,s7
    800041c4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041c6:	01278963          	beq	a5,s2,800041d8 <namex+0x13c>
    800041ca:	dbbd                	beqz	a5,80004140 <namex+0xa4>
    path++;
    800041cc:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041ce:	0009c783          	lbu	a5,0(s3)
    800041d2:	ff279ce3          	bne	a5,s2,800041ca <namex+0x12e>
    800041d6:	b7ad                	j	80004140 <namex+0xa4>
    memmove(name, s, len);
    800041d8:	2601                	sext.w	a2,a2
    800041da:	85a6                	mv	a1,s1
    800041dc:	8556                	mv	a0,s5
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	b96080e7          	jalr	-1130(ra) # 80000d74 <memmove>
    name[len] = 0;
    800041e6:	9d56                	add	s10,s10,s5
    800041e8:	000d0023          	sb	zero,0(s10)
    800041ec:	84ce                	mv	s1,s3
    800041ee:	b7bd                	j	8000415c <namex+0xc0>
  if(nameiparent){
    800041f0:	f00b0ce3          	beqz	s6,80004108 <namex+0x6c>
    iput(ip);
    800041f4:	8552                	mv	a0,s4
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	acc080e7          	jalr	-1332(ra) # 80003cc2 <iput>
    return 0;
    800041fe:	4a01                	li	s4,0
    80004200:	b721                	j	80004108 <namex+0x6c>

0000000080004202 <dirlink>:
{
    80004202:	7139                	addi	sp,sp,-64
    80004204:	fc06                	sd	ra,56(sp)
    80004206:	f822                	sd	s0,48(sp)
    80004208:	f426                	sd	s1,40(sp)
    8000420a:	f04a                	sd	s2,32(sp)
    8000420c:	ec4e                	sd	s3,24(sp)
    8000420e:	e852                	sd	s4,16(sp)
    80004210:	0080                	addi	s0,sp,64
    80004212:	892a                	mv	s2,a0
    80004214:	8a2e                	mv	s4,a1
    80004216:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004218:	4601                	li	a2,0
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	dd2080e7          	jalr	-558(ra) # 80003fec <dirlookup>
    80004222:	e93d                	bnez	a0,80004298 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004224:	04c92483          	lw	s1,76(s2)
    80004228:	c49d                	beqz	s1,80004256 <dirlink+0x54>
    8000422a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000422c:	4741                	li	a4,16
    8000422e:	86a6                	mv	a3,s1
    80004230:	fc040613          	addi	a2,s0,-64
    80004234:	4581                	li	a1,0
    80004236:	854a                	mv	a0,s2
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	b84080e7          	jalr	-1148(ra) # 80003dbc <readi>
    80004240:	47c1                	li	a5,16
    80004242:	06f51163          	bne	a0,a5,800042a4 <dirlink+0xa2>
    if(de.inum == 0)
    80004246:	fc045783          	lhu	a5,-64(s0)
    8000424a:	c791                	beqz	a5,80004256 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000424c:	24c1                	addiw	s1,s1,16
    8000424e:	04c92783          	lw	a5,76(s2)
    80004252:	fcf4ede3          	bltu	s1,a5,8000422c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004256:	4639                	li	a2,14
    80004258:	85d2                	mv	a1,s4
    8000425a:	fc240513          	addi	a0,s0,-62
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	bc6080e7          	jalr	-1082(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80004266:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000426a:	4741                	li	a4,16
    8000426c:	86a6                	mv	a3,s1
    8000426e:	fc040613          	addi	a2,s0,-64
    80004272:	4581                	li	a1,0
    80004274:	854a                	mv	a0,s2
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	c3e080e7          	jalr	-962(ra) # 80003eb4 <writei>
    8000427e:	872a                	mv	a4,a0
    80004280:	47c1                	li	a5,16
  return 0;
    80004282:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004284:	02f71863          	bne	a4,a5,800042b4 <dirlink+0xb2>
}
    80004288:	70e2                	ld	ra,56(sp)
    8000428a:	7442                	ld	s0,48(sp)
    8000428c:	74a2                	ld	s1,40(sp)
    8000428e:	7902                	ld	s2,32(sp)
    80004290:	69e2                	ld	s3,24(sp)
    80004292:	6a42                	ld	s4,16(sp)
    80004294:	6121                	addi	sp,sp,64
    80004296:	8082                	ret
    iput(ip);
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	a2a080e7          	jalr	-1494(ra) # 80003cc2 <iput>
    return -1;
    800042a0:	557d                	li	a0,-1
    800042a2:	b7dd                	j	80004288 <dirlink+0x86>
      panic("dirlink read");
    800042a4:	00004517          	auipc	a0,0x4
    800042a8:	38c50513          	addi	a0,a0,908 # 80008630 <syscalls+0x1e8>
    800042ac:	ffffc097          	auipc	ra,0xffffc
    800042b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
    panic("dirlink");
    800042b4:	00004517          	auipc	a0,0x4
    800042b8:	48c50513          	addi	a0,a0,1164 # 80008740 <syscalls+0x2f8>
    800042bc:	ffffc097          	auipc	ra,0xffffc
    800042c0:	280080e7          	jalr	640(ra) # 8000053c <panic>

00000000800042c4 <namei>:

struct inode*
namei(char *path)
{
    800042c4:	1101                	addi	sp,sp,-32
    800042c6:	ec06                	sd	ra,24(sp)
    800042c8:	e822                	sd	s0,16(sp)
    800042ca:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042cc:	fe040613          	addi	a2,s0,-32
    800042d0:	4581                	li	a1,0
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	dca080e7          	jalr	-566(ra) # 8000409c <namex>
}
    800042da:	60e2                	ld	ra,24(sp)
    800042dc:	6442                	ld	s0,16(sp)
    800042de:	6105                	addi	sp,sp,32
    800042e0:	8082                	ret

00000000800042e2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042e2:	1141                	addi	sp,sp,-16
    800042e4:	e406                	sd	ra,8(sp)
    800042e6:	e022                	sd	s0,0(sp)
    800042e8:	0800                	addi	s0,sp,16
    800042ea:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042ec:	4585                	li	a1,1
    800042ee:	00000097          	auipc	ra,0x0
    800042f2:	dae080e7          	jalr	-594(ra) # 8000409c <namex>
}
    800042f6:	60a2                	ld	ra,8(sp)
    800042f8:	6402                	ld	s0,0(sp)
    800042fa:	0141                	addi	sp,sp,16
    800042fc:	8082                	ret

00000000800042fe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042fe:	1101                	addi	sp,sp,-32
    80004300:	ec06                	sd	ra,24(sp)
    80004302:	e822                	sd	s0,16(sp)
    80004304:	e426                	sd	s1,8(sp)
    80004306:	e04a                	sd	s2,0(sp)
    80004308:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000430a:	0002d917          	auipc	s2,0x2d
    8000430e:	57e90913          	addi	s2,s2,1406 # 80031888 <log>
    80004312:	01892583          	lw	a1,24(s2)
    80004316:	02892503          	lw	a0,40(s2)
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	fec080e7          	jalr	-20(ra) # 80003306 <bread>
    80004322:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004324:	02c92683          	lw	a3,44(s2)
    80004328:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000432a:	02d05863          	blez	a3,8000435a <write_head+0x5c>
    8000432e:	0002d797          	auipc	a5,0x2d
    80004332:	58a78793          	addi	a5,a5,1418 # 800318b8 <log+0x30>
    80004336:	05c50713          	addi	a4,a0,92
    8000433a:	36fd                	addiw	a3,a3,-1
    8000433c:	02069613          	slli	a2,a3,0x20
    80004340:	01e65693          	srli	a3,a2,0x1e
    80004344:	0002d617          	auipc	a2,0x2d
    80004348:	57860613          	addi	a2,a2,1400 # 800318bc <log+0x34>
    8000434c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000434e:	4390                	lw	a2,0(a5)
    80004350:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004352:	0791                	addi	a5,a5,4
    80004354:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004356:	fed79ce3          	bne	a5,a3,8000434e <write_head+0x50>
  }
  bwrite(buf);
    8000435a:	8526                	mv	a0,s1
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	09c080e7          	jalr	156(ra) # 800033f8 <bwrite>
  brelse(buf);
    80004364:	8526                	mv	a0,s1
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	0d0080e7          	jalr	208(ra) # 80003436 <brelse>
}
    8000436e:	60e2                	ld	ra,24(sp)
    80004370:	6442                	ld	s0,16(sp)
    80004372:	64a2                	ld	s1,8(sp)
    80004374:	6902                	ld	s2,0(sp)
    80004376:	6105                	addi	sp,sp,32
    80004378:	8082                	ret

000000008000437a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000437a:	0002d797          	auipc	a5,0x2d
    8000437e:	53a7a783          	lw	a5,1338(a5) # 800318b4 <log+0x2c>
    80004382:	0af05d63          	blez	a5,8000443c <install_trans+0xc2>
{
    80004386:	7139                	addi	sp,sp,-64
    80004388:	fc06                	sd	ra,56(sp)
    8000438a:	f822                	sd	s0,48(sp)
    8000438c:	f426                	sd	s1,40(sp)
    8000438e:	f04a                	sd	s2,32(sp)
    80004390:	ec4e                	sd	s3,24(sp)
    80004392:	e852                	sd	s4,16(sp)
    80004394:	e456                	sd	s5,8(sp)
    80004396:	e05a                	sd	s6,0(sp)
    80004398:	0080                	addi	s0,sp,64
    8000439a:	8b2a                	mv	s6,a0
    8000439c:	0002da97          	auipc	s5,0x2d
    800043a0:	51ca8a93          	addi	s5,s5,1308 # 800318b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043a6:	0002d997          	auipc	s3,0x2d
    800043aa:	4e298993          	addi	s3,s3,1250 # 80031888 <log>
    800043ae:	a00d                	j	800043d0 <install_trans+0x56>
    brelse(lbuf);
    800043b0:	854a                	mv	a0,s2
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	084080e7          	jalr	132(ra) # 80003436 <brelse>
    brelse(dbuf);
    800043ba:	8526                	mv	a0,s1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	07a080e7          	jalr	122(ra) # 80003436 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c4:	2a05                	addiw	s4,s4,1
    800043c6:	0a91                	addi	s5,s5,4
    800043c8:	02c9a783          	lw	a5,44(s3)
    800043cc:	04fa5e63          	bge	s4,a5,80004428 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043d0:	0189a583          	lw	a1,24(s3)
    800043d4:	014585bb          	addw	a1,a1,s4
    800043d8:	2585                	addiw	a1,a1,1
    800043da:	0289a503          	lw	a0,40(s3)
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	f28080e7          	jalr	-216(ra) # 80003306 <bread>
    800043e6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043e8:	000aa583          	lw	a1,0(s5)
    800043ec:	0289a503          	lw	a0,40(s3)
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	f16080e7          	jalr	-234(ra) # 80003306 <bread>
    800043f8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043fa:	40000613          	li	a2,1024
    800043fe:	05890593          	addi	a1,s2,88
    80004402:	05850513          	addi	a0,a0,88
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	96e080e7          	jalr	-1682(ra) # 80000d74 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000440e:	8526                	mv	a0,s1
    80004410:	fffff097          	auipc	ra,0xfffff
    80004414:	fe8080e7          	jalr	-24(ra) # 800033f8 <bwrite>
    if(recovering == 0)
    80004418:	f80b1ce3          	bnez	s6,800043b0 <install_trans+0x36>
      bunpin(dbuf);
    8000441c:	8526                	mv	a0,s1
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	0f2080e7          	jalr	242(ra) # 80003510 <bunpin>
    80004426:	b769                	j	800043b0 <install_trans+0x36>
}
    80004428:	70e2                	ld	ra,56(sp)
    8000442a:	7442                	ld	s0,48(sp)
    8000442c:	74a2                	ld	s1,40(sp)
    8000442e:	7902                	ld	s2,32(sp)
    80004430:	69e2                	ld	s3,24(sp)
    80004432:	6a42                	ld	s4,16(sp)
    80004434:	6aa2                	ld	s5,8(sp)
    80004436:	6b02                	ld	s6,0(sp)
    80004438:	6121                	addi	sp,sp,64
    8000443a:	8082                	ret
    8000443c:	8082                	ret

000000008000443e <initlog>:
{
    8000443e:	7179                	addi	sp,sp,-48
    80004440:	f406                	sd	ra,40(sp)
    80004442:	f022                	sd	s0,32(sp)
    80004444:	ec26                	sd	s1,24(sp)
    80004446:	e84a                	sd	s2,16(sp)
    80004448:	e44e                	sd	s3,8(sp)
    8000444a:	1800                	addi	s0,sp,48
    8000444c:	892a                	mv	s2,a0
    8000444e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004450:	0002d497          	auipc	s1,0x2d
    80004454:	43848493          	addi	s1,s1,1080 # 80031888 <log>
    80004458:	00004597          	auipc	a1,0x4
    8000445c:	1e858593          	addi	a1,a1,488 # 80008640 <syscalls+0x1f8>
    80004460:	8526                	mv	a0,s1
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	72a080e7          	jalr	1834(ra) # 80000b8c <initlock>
  log.start = sb->logstart;
    8000446a:	0149a583          	lw	a1,20(s3)
    8000446e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004470:	0109a783          	lw	a5,16(s3)
    80004474:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004476:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000447a:	854a                	mv	a0,s2
    8000447c:	fffff097          	auipc	ra,0xfffff
    80004480:	e8a080e7          	jalr	-374(ra) # 80003306 <bread>
  log.lh.n = lh->n;
    80004484:	4d34                	lw	a3,88(a0)
    80004486:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004488:	02d05663          	blez	a3,800044b4 <initlog+0x76>
    8000448c:	05c50793          	addi	a5,a0,92
    80004490:	0002d717          	auipc	a4,0x2d
    80004494:	42870713          	addi	a4,a4,1064 # 800318b8 <log+0x30>
    80004498:	36fd                	addiw	a3,a3,-1
    8000449a:	02069613          	slli	a2,a3,0x20
    8000449e:	01e65693          	srli	a3,a2,0x1e
    800044a2:	06050613          	addi	a2,a0,96
    800044a6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044a8:	4390                	lw	a2,0(a5)
    800044aa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044ac:	0791                	addi	a5,a5,4
    800044ae:	0711                	addi	a4,a4,4
    800044b0:	fed79ce3          	bne	a5,a3,800044a8 <initlog+0x6a>
  brelse(buf);
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	f82080e7          	jalr	-126(ra) # 80003436 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044bc:	4505                	li	a0,1
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	ebc080e7          	jalr	-324(ra) # 8000437a <install_trans>
  log.lh.n = 0;
    800044c6:	0002d797          	auipc	a5,0x2d
    800044ca:	3e07a723          	sw	zero,1006(a5) # 800318b4 <log+0x2c>
  write_head(); // clear the log
    800044ce:	00000097          	auipc	ra,0x0
    800044d2:	e30080e7          	jalr	-464(ra) # 800042fe <write_head>
}
    800044d6:	70a2                	ld	ra,40(sp)
    800044d8:	7402                	ld	s0,32(sp)
    800044da:	64e2                	ld	s1,24(sp)
    800044dc:	6942                	ld	s2,16(sp)
    800044de:	69a2                	ld	s3,8(sp)
    800044e0:	6145                	addi	sp,sp,48
    800044e2:	8082                	ret

00000000800044e4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044e4:	1101                	addi	sp,sp,-32
    800044e6:	ec06                	sd	ra,24(sp)
    800044e8:	e822                	sd	s0,16(sp)
    800044ea:	e426                	sd	s1,8(sp)
    800044ec:	e04a                	sd	s2,0(sp)
    800044ee:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044f0:	0002d517          	auipc	a0,0x2d
    800044f4:	39850513          	addi	a0,a0,920 # 80031888 <log>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	724080e7          	jalr	1828(ra) # 80000c1c <acquire>
  while(1){
    if(log.committing){
    80004500:	0002d497          	auipc	s1,0x2d
    80004504:	38848493          	addi	s1,s1,904 # 80031888 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004508:	4979                	li	s2,30
    8000450a:	a039                	j	80004518 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000450c:	85a6                	mv	a1,s1
    8000450e:	8526                	mv	a0,s1
    80004510:	ffffe097          	auipc	ra,0xffffe
    80004514:	c5c080e7          	jalr	-932(ra) # 8000216c <sleep>
    if(log.committing){
    80004518:	50dc                	lw	a5,36(s1)
    8000451a:	fbed                	bnez	a5,8000450c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000451c:	5098                	lw	a4,32(s1)
    8000451e:	2705                	addiw	a4,a4,1
    80004520:	0007069b          	sext.w	a3,a4
    80004524:	0027179b          	slliw	a5,a4,0x2
    80004528:	9fb9                	addw	a5,a5,a4
    8000452a:	0017979b          	slliw	a5,a5,0x1
    8000452e:	54d8                	lw	a4,44(s1)
    80004530:	9fb9                	addw	a5,a5,a4
    80004532:	00f95963          	bge	s2,a5,80004544 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004536:	85a6                	mv	a1,s1
    80004538:	8526                	mv	a0,s1
    8000453a:	ffffe097          	auipc	ra,0xffffe
    8000453e:	c32080e7          	jalr	-974(ra) # 8000216c <sleep>
    80004542:	bfd9                	j	80004518 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004544:	0002d517          	auipc	a0,0x2d
    80004548:	34450513          	addi	a0,a0,836 # 80031888 <log>
    8000454c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	782080e7          	jalr	1922(ra) # 80000cd0 <release>
      break;
    }
  }
}
    80004556:	60e2                	ld	ra,24(sp)
    80004558:	6442                	ld	s0,16(sp)
    8000455a:	64a2                	ld	s1,8(sp)
    8000455c:	6902                	ld	s2,0(sp)
    8000455e:	6105                	addi	sp,sp,32
    80004560:	8082                	ret

0000000080004562 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004562:	7139                	addi	sp,sp,-64
    80004564:	fc06                	sd	ra,56(sp)
    80004566:	f822                	sd	s0,48(sp)
    80004568:	f426                	sd	s1,40(sp)
    8000456a:	f04a                	sd	s2,32(sp)
    8000456c:	ec4e                	sd	s3,24(sp)
    8000456e:	e852                	sd	s4,16(sp)
    80004570:	e456                	sd	s5,8(sp)
    80004572:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004574:	0002d497          	auipc	s1,0x2d
    80004578:	31448493          	addi	s1,s1,788 # 80031888 <log>
    8000457c:	8526                	mv	a0,s1
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	69e080e7          	jalr	1694(ra) # 80000c1c <acquire>
  log.outstanding -= 1;
    80004586:	509c                	lw	a5,32(s1)
    80004588:	37fd                	addiw	a5,a5,-1
    8000458a:	0007891b          	sext.w	s2,a5
    8000458e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004590:	50dc                	lw	a5,36(s1)
    80004592:	e7b9                	bnez	a5,800045e0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004594:	04091e63          	bnez	s2,800045f0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004598:	0002d497          	auipc	s1,0x2d
    8000459c:	2f048493          	addi	s1,s1,752 # 80031888 <log>
    800045a0:	4785                	li	a5,1
    800045a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045a4:	8526                	mv	a0,s1
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	72a080e7          	jalr	1834(ra) # 80000cd0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045ae:	54dc                	lw	a5,44(s1)
    800045b0:	06f04763          	bgtz	a5,8000461e <end_op+0xbc>
    acquire(&log.lock);
    800045b4:	0002d497          	auipc	s1,0x2d
    800045b8:	2d448493          	addi	s1,s1,724 # 80031888 <log>
    800045bc:	8526                	mv	a0,s1
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	65e080e7          	jalr	1630(ra) # 80000c1c <acquire>
    log.committing = 0;
    800045c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffe097          	auipc	ra,0xffffe
    800045d0:	d44080e7          	jalr	-700(ra) # 80002310 <wakeup>
    release(&log.lock);
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6fa080e7          	jalr	1786(ra) # 80000cd0 <release>
}
    800045de:	a03d                	j	8000460c <end_op+0xaa>
    panic("log.committing");
    800045e0:	00004517          	auipc	a0,0x4
    800045e4:	06850513          	addi	a0,a0,104 # 80008648 <syscalls+0x200>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	f54080e7          	jalr	-172(ra) # 8000053c <panic>
    wakeup(&log);
    800045f0:	0002d497          	auipc	s1,0x2d
    800045f4:	29848493          	addi	s1,s1,664 # 80031888 <log>
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffe097          	auipc	ra,0xffffe
    800045fe:	d16080e7          	jalr	-746(ra) # 80002310 <wakeup>
  release(&log.lock);
    80004602:	8526                	mv	a0,s1
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	6cc080e7          	jalr	1740(ra) # 80000cd0 <release>
}
    8000460c:	70e2                	ld	ra,56(sp)
    8000460e:	7442                	ld	s0,48(sp)
    80004610:	74a2                	ld	s1,40(sp)
    80004612:	7902                	ld	s2,32(sp)
    80004614:	69e2                	ld	s3,24(sp)
    80004616:	6a42                	ld	s4,16(sp)
    80004618:	6aa2                	ld	s5,8(sp)
    8000461a:	6121                	addi	sp,sp,64
    8000461c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000461e:	0002da97          	auipc	s5,0x2d
    80004622:	29aa8a93          	addi	s5,s5,666 # 800318b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004626:	0002da17          	auipc	s4,0x2d
    8000462a:	262a0a13          	addi	s4,s4,610 # 80031888 <log>
    8000462e:	018a2583          	lw	a1,24(s4)
    80004632:	012585bb          	addw	a1,a1,s2
    80004636:	2585                	addiw	a1,a1,1
    80004638:	028a2503          	lw	a0,40(s4)
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	cca080e7          	jalr	-822(ra) # 80003306 <bread>
    80004644:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004646:	000aa583          	lw	a1,0(s5)
    8000464a:	028a2503          	lw	a0,40(s4)
    8000464e:	fffff097          	auipc	ra,0xfffff
    80004652:	cb8080e7          	jalr	-840(ra) # 80003306 <bread>
    80004656:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004658:	40000613          	li	a2,1024
    8000465c:	05850593          	addi	a1,a0,88
    80004660:	05848513          	addi	a0,s1,88
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	710080e7          	jalr	1808(ra) # 80000d74 <memmove>
    bwrite(to);  // write the log
    8000466c:	8526                	mv	a0,s1
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	d8a080e7          	jalr	-630(ra) # 800033f8 <bwrite>
    brelse(from);
    80004676:	854e                	mv	a0,s3
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	dbe080e7          	jalr	-578(ra) # 80003436 <brelse>
    brelse(to);
    80004680:	8526                	mv	a0,s1
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	db4080e7          	jalr	-588(ra) # 80003436 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000468a:	2905                	addiw	s2,s2,1
    8000468c:	0a91                	addi	s5,s5,4
    8000468e:	02ca2783          	lw	a5,44(s4)
    80004692:	f8f94ee3          	blt	s2,a5,8000462e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	c68080e7          	jalr	-920(ra) # 800042fe <write_head>
    install_trans(0); // Now install writes to home locations
    8000469e:	4501                	li	a0,0
    800046a0:	00000097          	auipc	ra,0x0
    800046a4:	cda080e7          	jalr	-806(ra) # 8000437a <install_trans>
    log.lh.n = 0;
    800046a8:	0002d797          	auipc	a5,0x2d
    800046ac:	2007a623          	sw	zero,524(a5) # 800318b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	c4e080e7          	jalr	-946(ra) # 800042fe <write_head>
    800046b8:	bdf5                	j	800045b4 <end_op+0x52>

00000000800046ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046ba:	1101                	addi	sp,sp,-32
    800046bc:	ec06                	sd	ra,24(sp)
    800046be:	e822                	sd	s0,16(sp)
    800046c0:	e426                	sd	s1,8(sp)
    800046c2:	e04a                	sd	s2,0(sp)
    800046c4:	1000                	addi	s0,sp,32
    800046c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046c8:	0002d917          	auipc	s2,0x2d
    800046cc:	1c090913          	addi	s2,s2,448 # 80031888 <log>
    800046d0:	854a                	mv	a0,s2
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	54a080e7          	jalr	1354(ra) # 80000c1c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046da:	02c92603          	lw	a2,44(s2)
    800046de:	47f5                	li	a5,29
    800046e0:	06c7c563          	blt	a5,a2,8000474a <log_write+0x90>
    800046e4:	0002d797          	auipc	a5,0x2d
    800046e8:	1c07a783          	lw	a5,448(a5) # 800318a4 <log+0x1c>
    800046ec:	37fd                	addiw	a5,a5,-1
    800046ee:	04f65e63          	bge	a2,a5,8000474a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046f2:	0002d797          	auipc	a5,0x2d
    800046f6:	1b67a783          	lw	a5,438(a5) # 800318a8 <log+0x20>
    800046fa:	06f05063          	blez	a5,8000475a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046fe:	4781                	li	a5,0
    80004700:	06c05563          	blez	a2,8000476a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004704:	44cc                	lw	a1,12(s1)
    80004706:	0002d717          	auipc	a4,0x2d
    8000470a:	1b270713          	addi	a4,a4,434 # 800318b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000470e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004710:	4314                	lw	a3,0(a4)
    80004712:	04b68c63          	beq	a3,a1,8000476a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004716:	2785                	addiw	a5,a5,1
    80004718:	0711                	addi	a4,a4,4
    8000471a:	fef61be3          	bne	a2,a5,80004710 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000471e:	0621                	addi	a2,a2,8
    80004720:	060a                	slli	a2,a2,0x2
    80004722:	0002d797          	auipc	a5,0x2d
    80004726:	16678793          	addi	a5,a5,358 # 80031888 <log>
    8000472a:	97b2                	add	a5,a5,a2
    8000472c:	44d8                	lw	a4,12(s1)
    8000472e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004730:	8526                	mv	a0,s1
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	da2080e7          	jalr	-606(ra) # 800034d4 <bpin>
    log.lh.n++;
    8000473a:	0002d717          	auipc	a4,0x2d
    8000473e:	14e70713          	addi	a4,a4,334 # 80031888 <log>
    80004742:	575c                	lw	a5,44(a4)
    80004744:	2785                	addiw	a5,a5,1
    80004746:	d75c                	sw	a5,44(a4)
    80004748:	a82d                	j	80004782 <log_write+0xc8>
    panic("too big a transaction");
    8000474a:	00004517          	auipc	a0,0x4
    8000474e:	f0e50513          	addi	a0,a0,-242 # 80008658 <syscalls+0x210>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	dea080e7          	jalr	-534(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	f1650513          	addi	a0,a0,-234 # 80008670 <syscalls+0x228>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	dda080e7          	jalr	-550(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    8000476a:	00878693          	addi	a3,a5,8
    8000476e:	068a                	slli	a3,a3,0x2
    80004770:	0002d717          	auipc	a4,0x2d
    80004774:	11870713          	addi	a4,a4,280 # 80031888 <log>
    80004778:	9736                	add	a4,a4,a3
    8000477a:	44d4                	lw	a3,12(s1)
    8000477c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000477e:	faf609e3          	beq	a2,a5,80004730 <log_write+0x76>
  }
  release(&log.lock);
    80004782:	0002d517          	auipc	a0,0x2d
    80004786:	10650513          	addi	a0,a0,262 # 80031888 <log>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	546080e7          	jalr	1350(ra) # 80000cd0 <release>
}
    80004792:	60e2                	ld	ra,24(sp)
    80004794:	6442                	ld	s0,16(sp)
    80004796:	64a2                	ld	s1,8(sp)
    80004798:	6902                	ld	s2,0(sp)
    8000479a:	6105                	addi	sp,sp,32
    8000479c:	8082                	ret

000000008000479e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000479e:	1101                	addi	sp,sp,-32
    800047a0:	ec06                	sd	ra,24(sp)
    800047a2:	e822                	sd	s0,16(sp)
    800047a4:	e426                	sd	s1,8(sp)
    800047a6:	e04a                	sd	s2,0(sp)
    800047a8:	1000                	addi	s0,sp,32
    800047aa:	84aa                	mv	s1,a0
    800047ac:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047ae:	00004597          	auipc	a1,0x4
    800047b2:	ee258593          	addi	a1,a1,-286 # 80008690 <syscalls+0x248>
    800047b6:	0521                	addi	a0,a0,8
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	3d4080e7          	jalr	980(ra) # 80000b8c <initlock>
  lk->name = name;
    800047c0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047c8:	0204a423          	sw	zero,40(s1)
}
    800047cc:	60e2                	ld	ra,24(sp)
    800047ce:	6442                	ld	s0,16(sp)
    800047d0:	64a2                	ld	s1,8(sp)
    800047d2:	6902                	ld	s2,0(sp)
    800047d4:	6105                	addi	sp,sp,32
    800047d6:	8082                	ret

00000000800047d8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047d8:	1101                	addi	sp,sp,-32
    800047da:	ec06                	sd	ra,24(sp)
    800047dc:	e822                	sd	s0,16(sp)
    800047de:	e426                	sd	s1,8(sp)
    800047e0:	e04a                	sd	s2,0(sp)
    800047e2:	1000                	addi	s0,sp,32
    800047e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047e6:	00850913          	addi	s2,a0,8
    800047ea:	854a                	mv	a0,s2
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	430080e7          	jalr	1072(ra) # 80000c1c <acquire>
  while (lk->locked) {
    800047f4:	409c                	lw	a5,0(s1)
    800047f6:	cb89                	beqz	a5,80004808 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047f8:	85ca                	mv	a1,s2
    800047fa:	8526                	mv	a0,s1
    800047fc:	ffffe097          	auipc	ra,0xffffe
    80004800:	970080e7          	jalr	-1680(ra) # 8000216c <sleep>
  while (lk->locked) {
    80004804:	409c                	lw	a5,0(s1)
    80004806:	fbed                	bnez	a5,800047f8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004808:	4785                	li	a5,1
    8000480a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000480c:	ffffd097          	auipc	ra,0xffffd
    80004810:	232080e7          	jalr	562(ra) # 80001a3e <myproc>
    80004814:	30852783          	lw	a5,776(a0)
    80004818:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000481a:	854a                	mv	a0,s2
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	4b4080e7          	jalr	1204(ra) # 80000cd0 <release>
}
    80004824:	60e2                	ld	ra,24(sp)
    80004826:	6442                	ld	s0,16(sp)
    80004828:	64a2                	ld	s1,8(sp)
    8000482a:	6902                	ld	s2,0(sp)
    8000482c:	6105                	addi	sp,sp,32
    8000482e:	8082                	ret

0000000080004830 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004830:	1101                	addi	sp,sp,-32
    80004832:	ec06                	sd	ra,24(sp)
    80004834:	e822                	sd	s0,16(sp)
    80004836:	e426                	sd	s1,8(sp)
    80004838:	e04a                	sd	s2,0(sp)
    8000483a:	1000                	addi	s0,sp,32
    8000483c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000483e:	00850913          	addi	s2,a0,8
    80004842:	854a                	mv	a0,s2
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	3d8080e7          	jalr	984(ra) # 80000c1c <acquire>
  lk->locked = 0;
    8000484c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004850:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004854:	8526                	mv	a0,s1
    80004856:	ffffe097          	auipc	ra,0xffffe
    8000485a:	aba080e7          	jalr	-1350(ra) # 80002310 <wakeup>
  release(&lk->lk);
    8000485e:	854a                	mv	a0,s2
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	470080e7          	jalr	1136(ra) # 80000cd0 <release>
}
    80004868:	60e2                	ld	ra,24(sp)
    8000486a:	6442                	ld	s0,16(sp)
    8000486c:	64a2                	ld	s1,8(sp)
    8000486e:	6902                	ld	s2,0(sp)
    80004870:	6105                	addi	sp,sp,32
    80004872:	8082                	ret

0000000080004874 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004874:	7179                	addi	sp,sp,-48
    80004876:	f406                	sd	ra,40(sp)
    80004878:	f022                	sd	s0,32(sp)
    8000487a:	ec26                	sd	s1,24(sp)
    8000487c:	e84a                	sd	s2,16(sp)
    8000487e:	e44e                	sd	s3,8(sp)
    80004880:	1800                	addi	s0,sp,48
    80004882:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004884:	00850913          	addi	s2,a0,8
    80004888:	854a                	mv	a0,s2
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	392080e7          	jalr	914(ra) # 80000c1c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004892:	409c                	lw	a5,0(s1)
    80004894:	ef99                	bnez	a5,800048b2 <holdingsleep+0x3e>
    80004896:	4481                	li	s1,0
  release(&lk->lk);
    80004898:	854a                	mv	a0,s2
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	436080e7          	jalr	1078(ra) # 80000cd0 <release>
  return r;
}
    800048a2:	8526                	mv	a0,s1
    800048a4:	70a2                	ld	ra,40(sp)
    800048a6:	7402                	ld	s0,32(sp)
    800048a8:	64e2                	ld	s1,24(sp)
    800048aa:	6942                	ld	s2,16(sp)
    800048ac:	69a2                	ld	s3,8(sp)
    800048ae:	6145                	addi	sp,sp,48
    800048b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048b2:	0284a983          	lw	s3,40(s1)
    800048b6:	ffffd097          	auipc	ra,0xffffd
    800048ba:	188080e7          	jalr	392(ra) # 80001a3e <myproc>
    800048be:	30852483          	lw	s1,776(a0)
    800048c2:	413484b3          	sub	s1,s1,s3
    800048c6:	0014b493          	seqz	s1,s1
    800048ca:	b7f9                	j	80004898 <holdingsleep+0x24>

00000000800048cc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048cc:	1141                	addi	sp,sp,-16
    800048ce:	e406                	sd	ra,8(sp)
    800048d0:	e022                	sd	s0,0(sp)
    800048d2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048d4:	00004597          	auipc	a1,0x4
    800048d8:	dcc58593          	addi	a1,a1,-564 # 800086a0 <syscalls+0x258>
    800048dc:	0002d517          	auipc	a0,0x2d
    800048e0:	0f450513          	addi	a0,a0,244 # 800319d0 <ftable>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	2a8080e7          	jalr	680(ra) # 80000b8c <initlock>
}
    800048ec:	60a2                	ld	ra,8(sp)
    800048ee:	6402                	ld	s0,0(sp)
    800048f0:	0141                	addi	sp,sp,16
    800048f2:	8082                	ret

00000000800048f4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048f4:	1101                	addi	sp,sp,-32
    800048f6:	ec06                	sd	ra,24(sp)
    800048f8:	e822                	sd	s0,16(sp)
    800048fa:	e426                	sd	s1,8(sp)
    800048fc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048fe:	0002d517          	auipc	a0,0x2d
    80004902:	0d250513          	addi	a0,a0,210 # 800319d0 <ftable>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	316080e7          	jalr	790(ra) # 80000c1c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000490e:	0002d497          	auipc	s1,0x2d
    80004912:	0da48493          	addi	s1,s1,218 # 800319e8 <ftable+0x18>
    80004916:	0002e717          	auipc	a4,0x2e
    8000491a:	07270713          	addi	a4,a4,114 # 80032988 <ftable+0xfb8>
    if(f->ref == 0){
    8000491e:	40dc                	lw	a5,4(s1)
    80004920:	cf99                	beqz	a5,8000493e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004922:	02848493          	addi	s1,s1,40
    80004926:	fee49ce3          	bne	s1,a4,8000491e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000492a:	0002d517          	auipc	a0,0x2d
    8000492e:	0a650513          	addi	a0,a0,166 # 800319d0 <ftable>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	39e080e7          	jalr	926(ra) # 80000cd0 <release>
  return 0;
    8000493a:	4481                	li	s1,0
    8000493c:	a819                	j	80004952 <filealloc+0x5e>
      f->ref = 1;
    8000493e:	4785                	li	a5,1
    80004940:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004942:	0002d517          	auipc	a0,0x2d
    80004946:	08e50513          	addi	a0,a0,142 # 800319d0 <ftable>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	386080e7          	jalr	902(ra) # 80000cd0 <release>
}
    80004952:	8526                	mv	a0,s1
    80004954:	60e2                	ld	ra,24(sp)
    80004956:	6442                	ld	s0,16(sp)
    80004958:	64a2                	ld	s1,8(sp)
    8000495a:	6105                	addi	sp,sp,32
    8000495c:	8082                	ret

000000008000495e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000495e:	1101                	addi	sp,sp,-32
    80004960:	ec06                	sd	ra,24(sp)
    80004962:	e822                	sd	s0,16(sp)
    80004964:	e426                	sd	s1,8(sp)
    80004966:	1000                	addi	s0,sp,32
    80004968:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000496a:	0002d517          	auipc	a0,0x2d
    8000496e:	06650513          	addi	a0,a0,102 # 800319d0 <ftable>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	2aa080e7          	jalr	682(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    8000497a:	40dc                	lw	a5,4(s1)
    8000497c:	02f05263          	blez	a5,800049a0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004980:	2785                	addiw	a5,a5,1
    80004982:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004984:	0002d517          	auipc	a0,0x2d
    80004988:	04c50513          	addi	a0,a0,76 # 800319d0 <ftable>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	344080e7          	jalr	836(ra) # 80000cd0 <release>
  return f;
}
    80004994:	8526                	mv	a0,s1
    80004996:	60e2                	ld	ra,24(sp)
    80004998:	6442                	ld	s0,16(sp)
    8000499a:	64a2                	ld	s1,8(sp)
    8000499c:	6105                	addi	sp,sp,32
    8000499e:	8082                	ret
    panic("filedup");
    800049a0:	00004517          	auipc	a0,0x4
    800049a4:	d0850513          	addi	a0,a0,-760 # 800086a8 <syscalls+0x260>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	b94080e7          	jalr	-1132(ra) # 8000053c <panic>

00000000800049b0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049b0:	7139                	addi	sp,sp,-64
    800049b2:	fc06                	sd	ra,56(sp)
    800049b4:	f822                	sd	s0,48(sp)
    800049b6:	f426                	sd	s1,40(sp)
    800049b8:	f04a                	sd	s2,32(sp)
    800049ba:	ec4e                	sd	s3,24(sp)
    800049bc:	e852                	sd	s4,16(sp)
    800049be:	e456                	sd	s5,8(sp)
    800049c0:	0080                	addi	s0,sp,64
    800049c2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049c4:	0002d517          	auipc	a0,0x2d
    800049c8:	00c50513          	addi	a0,a0,12 # 800319d0 <ftable>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	250080e7          	jalr	592(ra) # 80000c1c <acquire>
  if(f->ref < 1)
    800049d4:	40dc                	lw	a5,4(s1)
    800049d6:	06f05163          	blez	a5,80004a38 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049da:	37fd                	addiw	a5,a5,-1
    800049dc:	0007871b          	sext.w	a4,a5
    800049e0:	c0dc                	sw	a5,4(s1)
    800049e2:	06e04363          	bgtz	a4,80004a48 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049e6:	0004a903          	lw	s2,0(s1)
    800049ea:	0094ca83          	lbu	s5,9(s1)
    800049ee:	0104ba03          	ld	s4,16(s1)
    800049f2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049f6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049fa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049fe:	0002d517          	auipc	a0,0x2d
    80004a02:	fd250513          	addi	a0,a0,-46 # 800319d0 <ftable>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	2ca080e7          	jalr	714(ra) # 80000cd0 <release>

  if(ff.type == FD_PIPE){
    80004a0e:	4785                	li	a5,1
    80004a10:	04f90d63          	beq	s2,a5,80004a6a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a14:	3979                	addiw	s2,s2,-2
    80004a16:	4785                	li	a5,1
    80004a18:	0527e063          	bltu	a5,s2,80004a58 <fileclose+0xa8>
    begin_op();
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	ac8080e7          	jalr	-1336(ra) # 800044e4 <begin_op>
    iput(ff.ip);
    80004a24:	854e                	mv	a0,s3
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	29c080e7          	jalr	668(ra) # 80003cc2 <iput>
    end_op();
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	b34080e7          	jalr	-1228(ra) # 80004562 <end_op>
    80004a36:	a00d                	j	80004a58 <fileclose+0xa8>
    panic("fileclose");
    80004a38:	00004517          	auipc	a0,0x4
    80004a3c:	c7850513          	addi	a0,a0,-904 # 800086b0 <syscalls+0x268>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	afc080e7          	jalr	-1284(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004a48:	0002d517          	auipc	a0,0x2d
    80004a4c:	f8850513          	addi	a0,a0,-120 # 800319d0 <ftable>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	280080e7          	jalr	640(ra) # 80000cd0 <release>
  }
}
    80004a58:	70e2                	ld	ra,56(sp)
    80004a5a:	7442                	ld	s0,48(sp)
    80004a5c:	74a2                	ld	s1,40(sp)
    80004a5e:	7902                	ld	s2,32(sp)
    80004a60:	69e2                	ld	s3,24(sp)
    80004a62:	6a42                	ld	s4,16(sp)
    80004a64:	6aa2                	ld	s5,8(sp)
    80004a66:	6121                	addi	sp,sp,64
    80004a68:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a6a:	85d6                	mv	a1,s5
    80004a6c:	8552                	mv	a0,s4
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	34c080e7          	jalr	844(ra) # 80004dba <pipeclose>
    80004a76:	b7cd                	j	80004a58 <fileclose+0xa8>

0000000080004a78 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a78:	715d                	addi	sp,sp,-80
    80004a7a:	e486                	sd	ra,72(sp)
    80004a7c:	e0a2                	sd	s0,64(sp)
    80004a7e:	fc26                	sd	s1,56(sp)
    80004a80:	f84a                	sd	s2,48(sp)
    80004a82:	f44e                	sd	s3,40(sp)
    80004a84:	0880                	addi	s0,sp,80
    80004a86:	84aa                	mv	s1,a0
    80004a88:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a8a:	ffffd097          	auipc	ra,0xffffd
    80004a8e:	fb4080e7          	jalr	-76(ra) # 80001a3e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a92:	409c                	lw	a5,0(s1)
    80004a94:	37f9                	addiw	a5,a5,-2
    80004a96:	4705                	li	a4,1
    80004a98:	04f76763          	bltu	a4,a5,80004ae6 <filestat+0x6e>
    80004a9c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a9e:	6c88                	ld	a0,24(s1)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	068080e7          	jalr	104(ra) # 80003b08 <ilock>
    stati(f->ip, &st);
    80004aa8:	fb840593          	addi	a1,s0,-72
    80004aac:	6c88                	ld	a0,24(s1)
    80004aae:	fffff097          	auipc	ra,0xfffff
    80004ab2:	2e4080e7          	jalr	740(ra) # 80003d92 <stati>
    iunlock(f->ip);
    80004ab6:	6c88                	ld	a0,24(s1)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	112080e7          	jalr	274(ra) # 80003bca <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ac0:	46e1                	li	a3,24
    80004ac2:	fb840613          	addi	a2,s0,-72
    80004ac6:	85ce                	mv	a1,s3
    80004ac8:	32893503          	ld	a0,808(s2)
    80004acc:	ffffd097          	auipc	ra,0xffffd
    80004ad0:	bb8080e7          	jalr	-1096(ra) # 80001684 <copyout>
    80004ad4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ad8:	60a6                	ld	ra,72(sp)
    80004ada:	6406                	ld	s0,64(sp)
    80004adc:	74e2                	ld	s1,56(sp)
    80004ade:	7942                	ld	s2,48(sp)
    80004ae0:	79a2                	ld	s3,40(sp)
    80004ae2:	6161                	addi	sp,sp,80
    80004ae4:	8082                	ret
  return -1;
    80004ae6:	557d                	li	a0,-1
    80004ae8:	bfc5                	j	80004ad8 <filestat+0x60>

0000000080004aea <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004aea:	7179                	addi	sp,sp,-48
    80004aec:	f406                	sd	ra,40(sp)
    80004aee:	f022                	sd	s0,32(sp)
    80004af0:	ec26                	sd	s1,24(sp)
    80004af2:	e84a                	sd	s2,16(sp)
    80004af4:	e44e                	sd	s3,8(sp)
    80004af6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004af8:	00854783          	lbu	a5,8(a0)
    80004afc:	c3d5                	beqz	a5,80004ba0 <fileread+0xb6>
    80004afe:	84aa                	mv	s1,a0
    80004b00:	89ae                	mv	s3,a1
    80004b02:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b04:	411c                	lw	a5,0(a0)
    80004b06:	4705                	li	a4,1
    80004b08:	04e78963          	beq	a5,a4,80004b5a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b0c:	470d                	li	a4,3
    80004b0e:	04e78d63          	beq	a5,a4,80004b68 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b12:	4709                	li	a4,2
    80004b14:	06e79e63          	bne	a5,a4,80004b90 <fileread+0xa6>
    ilock(f->ip);
    80004b18:	6d08                	ld	a0,24(a0)
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	fee080e7          	jalr	-18(ra) # 80003b08 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b22:	874a                	mv	a4,s2
    80004b24:	5094                	lw	a3,32(s1)
    80004b26:	864e                	mv	a2,s3
    80004b28:	4585                	li	a1,1
    80004b2a:	6c88                	ld	a0,24(s1)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	290080e7          	jalr	656(ra) # 80003dbc <readi>
    80004b34:	892a                	mv	s2,a0
    80004b36:	00a05563          	blez	a0,80004b40 <fileread+0x56>
      f->off += r;
    80004b3a:	509c                	lw	a5,32(s1)
    80004b3c:	9fa9                	addw	a5,a5,a0
    80004b3e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b40:	6c88                	ld	a0,24(s1)
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	088080e7          	jalr	136(ra) # 80003bca <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b4a:	854a                	mv	a0,s2
    80004b4c:	70a2                	ld	ra,40(sp)
    80004b4e:	7402                	ld	s0,32(sp)
    80004b50:	64e2                	ld	s1,24(sp)
    80004b52:	6942                	ld	s2,16(sp)
    80004b54:	69a2                	ld	s3,8(sp)
    80004b56:	6145                	addi	sp,sp,48
    80004b58:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b5a:	6908                	ld	a0,16(a0)
    80004b5c:	00000097          	auipc	ra,0x0
    80004b60:	3c0080e7          	jalr	960(ra) # 80004f1c <piperead>
    80004b64:	892a                	mv	s2,a0
    80004b66:	b7d5                	j	80004b4a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b68:	02451783          	lh	a5,36(a0)
    80004b6c:	03079693          	slli	a3,a5,0x30
    80004b70:	92c1                	srli	a3,a3,0x30
    80004b72:	4725                	li	a4,9
    80004b74:	02d76863          	bltu	a4,a3,80004ba4 <fileread+0xba>
    80004b78:	0792                	slli	a5,a5,0x4
    80004b7a:	0002d717          	auipc	a4,0x2d
    80004b7e:	db670713          	addi	a4,a4,-586 # 80031930 <devsw>
    80004b82:	97ba                	add	a5,a5,a4
    80004b84:	639c                	ld	a5,0(a5)
    80004b86:	c38d                	beqz	a5,80004ba8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b88:	4505                	li	a0,1
    80004b8a:	9782                	jalr	a5
    80004b8c:	892a                	mv	s2,a0
    80004b8e:	bf75                	j	80004b4a <fileread+0x60>
    panic("fileread");
    80004b90:	00004517          	auipc	a0,0x4
    80004b94:	b3050513          	addi	a0,a0,-1232 # 800086c0 <syscalls+0x278>
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	9a4080e7          	jalr	-1628(ra) # 8000053c <panic>
    return -1;
    80004ba0:	597d                	li	s2,-1
    80004ba2:	b765                	j	80004b4a <fileread+0x60>
      return -1;
    80004ba4:	597d                	li	s2,-1
    80004ba6:	b755                	j	80004b4a <fileread+0x60>
    80004ba8:	597d                	li	s2,-1
    80004baa:	b745                	j	80004b4a <fileread+0x60>

0000000080004bac <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bac:	715d                	addi	sp,sp,-80
    80004bae:	e486                	sd	ra,72(sp)
    80004bb0:	e0a2                	sd	s0,64(sp)
    80004bb2:	fc26                	sd	s1,56(sp)
    80004bb4:	f84a                	sd	s2,48(sp)
    80004bb6:	f44e                	sd	s3,40(sp)
    80004bb8:	f052                	sd	s4,32(sp)
    80004bba:	ec56                	sd	s5,24(sp)
    80004bbc:	e85a                	sd	s6,16(sp)
    80004bbe:	e45e                	sd	s7,8(sp)
    80004bc0:	e062                	sd	s8,0(sp)
    80004bc2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bc4:	00954783          	lbu	a5,9(a0)
    80004bc8:	10078663          	beqz	a5,80004cd4 <filewrite+0x128>
    80004bcc:	892a                	mv	s2,a0
    80004bce:	8b2e                	mv	s6,a1
    80004bd0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bd2:	411c                	lw	a5,0(a0)
    80004bd4:	4705                	li	a4,1
    80004bd6:	02e78263          	beq	a5,a4,80004bfa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bda:	470d                	li	a4,3
    80004bdc:	02e78663          	beq	a5,a4,80004c08 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be0:	4709                	li	a4,2
    80004be2:	0ee79163          	bne	a5,a4,80004cc4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004be6:	0ac05d63          	blez	a2,80004ca0 <filewrite+0xf4>
    int i = 0;
    80004bea:	4981                	li	s3,0
    80004bec:	6b85                	lui	s7,0x1
    80004bee:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bf2:	6c05                	lui	s8,0x1
    80004bf4:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bf8:	a861                	j	80004c90 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bfa:	6908                	ld	a0,16(a0)
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	22e080e7          	jalr	558(ra) # 80004e2a <pipewrite>
    80004c04:	8a2a                	mv	s4,a0
    80004c06:	a045                	j	80004ca6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c08:	02451783          	lh	a5,36(a0)
    80004c0c:	03079693          	slli	a3,a5,0x30
    80004c10:	92c1                	srli	a3,a3,0x30
    80004c12:	4725                	li	a4,9
    80004c14:	0cd76263          	bltu	a4,a3,80004cd8 <filewrite+0x12c>
    80004c18:	0792                	slli	a5,a5,0x4
    80004c1a:	0002d717          	auipc	a4,0x2d
    80004c1e:	d1670713          	addi	a4,a4,-746 # 80031930 <devsw>
    80004c22:	97ba                	add	a5,a5,a4
    80004c24:	679c                	ld	a5,8(a5)
    80004c26:	cbdd                	beqz	a5,80004cdc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c28:	4505                	li	a0,1
    80004c2a:	9782                	jalr	a5
    80004c2c:	8a2a                	mv	s4,a0
    80004c2e:	a8a5                	j	80004ca6 <filewrite+0xfa>
    80004c30:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c34:	00000097          	auipc	ra,0x0
    80004c38:	8b0080e7          	jalr	-1872(ra) # 800044e4 <begin_op>
      ilock(f->ip);
    80004c3c:	01893503          	ld	a0,24(s2)
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	ec8080e7          	jalr	-312(ra) # 80003b08 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c48:	8756                	mv	a4,s5
    80004c4a:	02092683          	lw	a3,32(s2)
    80004c4e:	01698633          	add	a2,s3,s6
    80004c52:	4585                	li	a1,1
    80004c54:	01893503          	ld	a0,24(s2)
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	25c080e7          	jalr	604(ra) # 80003eb4 <writei>
    80004c60:	84aa                	mv	s1,a0
    80004c62:	00a05763          	blez	a0,80004c70 <filewrite+0xc4>
        f->off += r;
    80004c66:	02092783          	lw	a5,32(s2)
    80004c6a:	9fa9                	addw	a5,a5,a0
    80004c6c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c70:	01893503          	ld	a0,24(s2)
    80004c74:	fffff097          	auipc	ra,0xfffff
    80004c78:	f56080e7          	jalr	-170(ra) # 80003bca <iunlock>
      end_op();
    80004c7c:	00000097          	auipc	ra,0x0
    80004c80:	8e6080e7          	jalr	-1818(ra) # 80004562 <end_op>

      if(r != n1){
    80004c84:	009a9f63          	bne	s5,s1,80004ca2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c88:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c8c:	0149db63          	bge	s3,s4,80004ca2 <filewrite+0xf6>
      int n1 = n - i;
    80004c90:	413a04bb          	subw	s1,s4,s3
    80004c94:	0004879b          	sext.w	a5,s1
    80004c98:	f8fbdce3          	bge	s7,a5,80004c30 <filewrite+0x84>
    80004c9c:	84e2                	mv	s1,s8
    80004c9e:	bf49                	j	80004c30 <filewrite+0x84>
    int i = 0;
    80004ca0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ca2:	013a1f63          	bne	s4,s3,80004cc0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ca6:	8552                	mv	a0,s4
    80004ca8:	60a6                	ld	ra,72(sp)
    80004caa:	6406                	ld	s0,64(sp)
    80004cac:	74e2                	ld	s1,56(sp)
    80004cae:	7942                	ld	s2,48(sp)
    80004cb0:	79a2                	ld	s3,40(sp)
    80004cb2:	7a02                	ld	s4,32(sp)
    80004cb4:	6ae2                	ld	s5,24(sp)
    80004cb6:	6b42                	ld	s6,16(sp)
    80004cb8:	6ba2                	ld	s7,8(sp)
    80004cba:	6c02                	ld	s8,0(sp)
    80004cbc:	6161                	addi	sp,sp,80
    80004cbe:	8082                	ret
    ret = (i == n ? n : -1);
    80004cc0:	5a7d                	li	s4,-1
    80004cc2:	b7d5                	j	80004ca6 <filewrite+0xfa>
    panic("filewrite");
    80004cc4:	00004517          	auipc	a0,0x4
    80004cc8:	a0c50513          	addi	a0,a0,-1524 # 800086d0 <syscalls+0x288>
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	870080e7          	jalr	-1936(ra) # 8000053c <panic>
    return -1;
    80004cd4:	5a7d                	li	s4,-1
    80004cd6:	bfc1                	j	80004ca6 <filewrite+0xfa>
      return -1;
    80004cd8:	5a7d                	li	s4,-1
    80004cda:	b7f1                	j	80004ca6 <filewrite+0xfa>
    80004cdc:	5a7d                	li	s4,-1
    80004cde:	b7e1                	j	80004ca6 <filewrite+0xfa>

0000000080004ce0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ce0:	7179                	addi	sp,sp,-48
    80004ce2:	f406                	sd	ra,40(sp)
    80004ce4:	f022                	sd	s0,32(sp)
    80004ce6:	ec26                	sd	s1,24(sp)
    80004ce8:	e84a                	sd	s2,16(sp)
    80004cea:	e44e                	sd	s3,8(sp)
    80004cec:	e052                	sd	s4,0(sp)
    80004cee:	1800                	addi	s0,sp,48
    80004cf0:	84aa                	mv	s1,a0
    80004cf2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cf4:	0005b023          	sd	zero,0(a1)
    80004cf8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cfc:	00000097          	auipc	ra,0x0
    80004d00:	bf8080e7          	jalr	-1032(ra) # 800048f4 <filealloc>
    80004d04:	e088                	sd	a0,0(s1)
    80004d06:	c551                	beqz	a0,80004d92 <pipealloc+0xb2>
    80004d08:	00000097          	auipc	ra,0x0
    80004d0c:	bec080e7          	jalr	-1044(ra) # 800048f4 <filealloc>
    80004d10:	00aa3023          	sd	a0,0(s4)
    80004d14:	c92d                	beqz	a0,80004d86 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	dcc080e7          	jalr	-564(ra) # 80000ae2 <kalloc>
    80004d1e:	892a                	mv	s2,a0
    80004d20:	c125                	beqz	a0,80004d80 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d22:	4985                	li	s3,1
    80004d24:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d28:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d2c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d30:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d34:	00004597          	auipc	a1,0x4
    80004d38:	9ac58593          	addi	a1,a1,-1620 # 800086e0 <syscalls+0x298>
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	e50080e7          	jalr	-432(ra) # 80000b8c <initlock>
  (*f0)->type = FD_PIPE;
    80004d44:	609c                	ld	a5,0(s1)
    80004d46:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d4a:	609c                	ld	a5,0(s1)
    80004d4c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d50:	609c                	ld	a5,0(s1)
    80004d52:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d56:	609c                	ld	a5,0(s1)
    80004d58:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d5c:	000a3783          	ld	a5,0(s4)
    80004d60:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d64:	000a3783          	ld	a5,0(s4)
    80004d68:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d6c:	000a3783          	ld	a5,0(s4)
    80004d70:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d74:	000a3783          	ld	a5,0(s4)
    80004d78:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d7c:	4501                	li	a0,0
    80004d7e:	a025                	j	80004da6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d80:	6088                	ld	a0,0(s1)
    80004d82:	e501                	bnez	a0,80004d8a <pipealloc+0xaa>
    80004d84:	a039                	j	80004d92 <pipealloc+0xb2>
    80004d86:	6088                	ld	a0,0(s1)
    80004d88:	c51d                	beqz	a0,80004db6 <pipealloc+0xd6>
    fileclose(*f0);
    80004d8a:	00000097          	auipc	ra,0x0
    80004d8e:	c26080e7          	jalr	-986(ra) # 800049b0 <fileclose>
  if(*f1)
    80004d92:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d96:	557d                	li	a0,-1
  if(*f1)
    80004d98:	c799                	beqz	a5,80004da6 <pipealloc+0xc6>
    fileclose(*f1);
    80004d9a:	853e                	mv	a0,a5
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	c14080e7          	jalr	-1004(ra) # 800049b0 <fileclose>
  return -1;
    80004da4:	557d                	li	a0,-1
}
    80004da6:	70a2                	ld	ra,40(sp)
    80004da8:	7402                	ld	s0,32(sp)
    80004daa:	64e2                	ld	s1,24(sp)
    80004dac:	6942                	ld	s2,16(sp)
    80004dae:	69a2                	ld	s3,8(sp)
    80004db0:	6a02                	ld	s4,0(sp)
    80004db2:	6145                	addi	sp,sp,48
    80004db4:	8082                	ret
  return -1;
    80004db6:	557d                	li	a0,-1
    80004db8:	b7fd                	j	80004da6 <pipealloc+0xc6>

0000000080004dba <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dba:	1101                	addi	sp,sp,-32
    80004dbc:	ec06                	sd	ra,24(sp)
    80004dbe:	e822                	sd	s0,16(sp)
    80004dc0:	e426                	sd	s1,8(sp)
    80004dc2:	e04a                	sd	s2,0(sp)
    80004dc4:	1000                	addi	s0,sp,32
    80004dc6:	84aa                	mv	s1,a0
    80004dc8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	e52080e7          	jalr	-430(ra) # 80000c1c <acquire>
  if(writable){
    80004dd2:	02090d63          	beqz	s2,80004e0c <pipeclose+0x52>
    pi->writeopen = 0;
    80004dd6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dda:	21848513          	addi	a0,s1,536
    80004dde:	ffffd097          	auipc	ra,0xffffd
    80004de2:	532080e7          	jalr	1330(ra) # 80002310 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004de6:	2204b783          	ld	a5,544(s1)
    80004dea:	eb95                	bnez	a5,80004e1e <pipeclose+0x64>
    release(&pi->lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	ee2080e7          	jalr	-286(ra) # 80000cd0 <release>
    kfree((char*)pi);
    80004df6:	8526                	mv	a0,s1
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	bec080e7          	jalr	-1044(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e00:	60e2                	ld	ra,24(sp)
    80004e02:	6442                	ld	s0,16(sp)
    80004e04:	64a2                	ld	s1,8(sp)
    80004e06:	6902                	ld	s2,0(sp)
    80004e08:	6105                	addi	sp,sp,32
    80004e0a:	8082                	ret
    pi->readopen = 0;
    80004e0c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e10:	21c48513          	addi	a0,s1,540
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	4fc080e7          	jalr	1276(ra) # 80002310 <wakeup>
    80004e1c:	b7e9                	j	80004de6 <pipeclose+0x2c>
    release(&pi->lock);
    80004e1e:	8526                	mv	a0,s1
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	eb0080e7          	jalr	-336(ra) # 80000cd0 <release>
}
    80004e28:	bfe1                	j	80004e00 <pipeclose+0x46>

0000000080004e2a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e2a:	711d                	addi	sp,sp,-96
    80004e2c:	ec86                	sd	ra,88(sp)
    80004e2e:	e8a2                	sd	s0,80(sp)
    80004e30:	e4a6                	sd	s1,72(sp)
    80004e32:	e0ca                	sd	s2,64(sp)
    80004e34:	fc4e                	sd	s3,56(sp)
    80004e36:	f852                	sd	s4,48(sp)
    80004e38:	f456                	sd	s5,40(sp)
    80004e3a:	f05a                	sd	s6,32(sp)
    80004e3c:	ec5e                	sd	s7,24(sp)
    80004e3e:	e862                	sd	s8,16(sp)
    80004e40:	1080                	addi	s0,sp,96
    80004e42:	84aa                	mv	s1,a0
    80004e44:	8aae                	mv	s5,a1
    80004e46:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	bf6080e7          	jalr	-1034(ra) # 80001a3e <myproc>
    80004e50:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e52:	8526                	mv	a0,s1
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	dc8080e7          	jalr	-568(ra) # 80000c1c <acquire>
  while(i < n){
    80004e5c:	0b405363          	blez	s4,80004f02 <pipewrite+0xd8>
  int i = 0;
    80004e60:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e62:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e64:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e68:	21c48b93          	addi	s7,s1,540
    80004e6c:	a089                	j	80004eae <pipewrite+0x84>
      release(&pi->lock);
    80004e6e:	8526                	mv	a0,s1
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	e60080e7          	jalr	-416(ra) # 80000cd0 <release>
      return -1;
    80004e78:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e7a:	854a                	mv	a0,s2
    80004e7c:	60e6                	ld	ra,88(sp)
    80004e7e:	6446                	ld	s0,80(sp)
    80004e80:	64a6                	ld	s1,72(sp)
    80004e82:	6906                	ld	s2,64(sp)
    80004e84:	79e2                	ld	s3,56(sp)
    80004e86:	7a42                	ld	s4,48(sp)
    80004e88:	7aa2                	ld	s5,40(sp)
    80004e8a:	7b02                	ld	s6,32(sp)
    80004e8c:	6be2                	ld	s7,24(sp)
    80004e8e:	6c42                	ld	s8,16(sp)
    80004e90:	6125                	addi	sp,sp,96
    80004e92:	8082                	ret
      wakeup(&pi->nread);
    80004e94:	8562                	mv	a0,s8
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	47a080e7          	jalr	1146(ra) # 80002310 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e9e:	85a6                	mv	a1,s1
    80004ea0:	855e                	mv	a0,s7
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	2ca080e7          	jalr	714(ra) # 8000216c <sleep>
  while(i < n){
    80004eaa:	05495d63          	bge	s2,s4,80004f04 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004eae:	2204a783          	lw	a5,544(s1)
    80004eb2:	dfd5                	beqz	a5,80004e6e <pipewrite+0x44>
    80004eb4:	3009a783          	lw	a5,768(s3)
    80004eb8:	fbdd                	bnez	a5,80004e6e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004eba:	2184a783          	lw	a5,536(s1)
    80004ebe:	21c4a703          	lw	a4,540(s1)
    80004ec2:	2007879b          	addiw	a5,a5,512
    80004ec6:	fcf707e3          	beq	a4,a5,80004e94 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eca:	4685                	li	a3,1
    80004ecc:	01590633          	add	a2,s2,s5
    80004ed0:	faf40593          	addi	a1,s0,-81
    80004ed4:	3289b503          	ld	a0,808(s3)
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	838080e7          	jalr	-1992(ra) # 80001710 <copyin>
    80004ee0:	03650263          	beq	a0,s6,80004f04 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ee4:	21c4a783          	lw	a5,540(s1)
    80004ee8:	0017871b          	addiw	a4,a5,1
    80004eec:	20e4ae23          	sw	a4,540(s1)
    80004ef0:	1ff7f793          	andi	a5,a5,511
    80004ef4:	97a6                	add	a5,a5,s1
    80004ef6:	faf44703          	lbu	a4,-81(s0)
    80004efa:	00e78c23          	sb	a4,24(a5)
      i++;
    80004efe:	2905                	addiw	s2,s2,1
    80004f00:	b76d                	j	80004eaa <pipewrite+0x80>
  int i = 0;
    80004f02:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f04:	21848513          	addi	a0,s1,536
    80004f08:	ffffd097          	auipc	ra,0xffffd
    80004f0c:	408080e7          	jalr	1032(ra) # 80002310 <wakeup>
  release(&pi->lock);
    80004f10:	8526                	mv	a0,s1
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	dbe080e7          	jalr	-578(ra) # 80000cd0 <release>
  return i;
    80004f1a:	b785                	j	80004e7a <pipewrite+0x50>

0000000080004f1c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f1c:	715d                	addi	sp,sp,-80
    80004f1e:	e486                	sd	ra,72(sp)
    80004f20:	e0a2                	sd	s0,64(sp)
    80004f22:	fc26                	sd	s1,56(sp)
    80004f24:	f84a                	sd	s2,48(sp)
    80004f26:	f44e                	sd	s3,40(sp)
    80004f28:	f052                	sd	s4,32(sp)
    80004f2a:	ec56                	sd	s5,24(sp)
    80004f2c:	e85a                	sd	s6,16(sp)
    80004f2e:	0880                	addi	s0,sp,80
    80004f30:	84aa                	mv	s1,a0
    80004f32:	892e                	mv	s2,a1
    80004f34:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	b08080e7          	jalr	-1272(ra) # 80001a3e <myproc>
    80004f3e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f40:	8526                	mv	a0,s1
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	cda080e7          	jalr	-806(ra) # 80000c1c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f4a:	2184a703          	lw	a4,536(s1)
    80004f4e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f52:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f56:	02f71463          	bne	a4,a5,80004f7e <piperead+0x62>
    80004f5a:	2244a783          	lw	a5,548(s1)
    80004f5e:	c385                	beqz	a5,80004f7e <piperead+0x62>
    if(pr->killed){
    80004f60:	300a2783          	lw	a5,768(s4)
    80004f64:	ebc9                	bnez	a5,80004ff6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f66:	85a6                	mv	a1,s1
    80004f68:	854e                	mv	a0,s3
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	202080e7          	jalr	514(ra) # 8000216c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f72:	2184a703          	lw	a4,536(s1)
    80004f76:	21c4a783          	lw	a5,540(s1)
    80004f7a:	fef700e3          	beq	a4,a5,80004f5a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f7e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f80:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f82:	05505463          	blez	s5,80004fca <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004f86:	2184a783          	lw	a5,536(s1)
    80004f8a:	21c4a703          	lw	a4,540(s1)
    80004f8e:	02f70e63          	beq	a4,a5,80004fca <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f92:	0017871b          	addiw	a4,a5,1
    80004f96:	20e4ac23          	sw	a4,536(s1)
    80004f9a:	1ff7f793          	andi	a5,a5,511
    80004f9e:	97a6                	add	a5,a5,s1
    80004fa0:	0187c783          	lbu	a5,24(a5)
    80004fa4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fa8:	4685                	li	a3,1
    80004faa:	fbf40613          	addi	a2,s0,-65
    80004fae:	85ca                	mv	a1,s2
    80004fb0:	328a3503          	ld	a0,808(s4)
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	6d0080e7          	jalr	1744(ra) # 80001684 <copyout>
    80004fbc:	01650763          	beq	a0,s6,80004fca <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fc0:	2985                	addiw	s3,s3,1
    80004fc2:	0905                	addi	s2,s2,1
    80004fc4:	fd3a91e3          	bne	s5,s3,80004f86 <piperead+0x6a>
    80004fc8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fca:	21c48513          	addi	a0,s1,540
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	342080e7          	jalr	834(ra) # 80002310 <wakeup>
  release(&pi->lock);
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	cf8080e7          	jalr	-776(ra) # 80000cd0 <release>
  return i;
}
    80004fe0:	854e                	mv	a0,s3
    80004fe2:	60a6                	ld	ra,72(sp)
    80004fe4:	6406                	ld	s0,64(sp)
    80004fe6:	74e2                	ld	s1,56(sp)
    80004fe8:	7942                	ld	s2,48(sp)
    80004fea:	79a2                	ld	s3,40(sp)
    80004fec:	7a02                	ld	s4,32(sp)
    80004fee:	6ae2                	ld	s5,24(sp)
    80004ff0:	6b42                	ld	s6,16(sp)
    80004ff2:	6161                	addi	sp,sp,80
    80004ff4:	8082                	ret
      release(&pi->lock);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	cd8080e7          	jalr	-808(ra) # 80000cd0 <release>
      return -1;
    80005000:	59fd                	li	s3,-1
    80005002:	bff9                	j	80004fe0 <piperead+0xc4>

0000000080005004 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005004:	de010113          	addi	sp,sp,-544
    80005008:	20113c23          	sd	ra,536(sp)
    8000500c:	20813823          	sd	s0,528(sp)
    80005010:	20913423          	sd	s1,520(sp)
    80005014:	21213023          	sd	s2,512(sp)
    80005018:	ffce                	sd	s3,504(sp)
    8000501a:	fbd2                	sd	s4,496(sp)
    8000501c:	f7d6                	sd	s5,488(sp)
    8000501e:	f3da                	sd	s6,480(sp)
    80005020:	efde                	sd	s7,472(sp)
    80005022:	ebe2                	sd	s8,464(sp)
    80005024:	e7e6                	sd	s9,456(sp)
    80005026:	e3ea                	sd	s10,448(sp)
    80005028:	ff6e                	sd	s11,440(sp)
    8000502a:	1400                	addi	s0,sp,544
    8000502c:	892a                	mv	s2,a0
    8000502e:	dea43423          	sd	a0,-536(s0)
    80005032:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	a08080e7          	jalr	-1528(ra) # 80001a3e <myproc>
    8000503e:	84aa                	mv	s1,a0

  begin_op();
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	4a4080e7          	jalr	1188(ra) # 800044e4 <begin_op>

  if((ip = namei(path)) == 0){
    80005048:	854a                	mv	a0,s2
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	27a080e7          	jalr	634(ra) # 800042c4 <namei>
    80005052:	c93d                	beqz	a0,800050c8 <exec+0xc4>
    80005054:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	ab2080e7          	jalr	-1358(ra) # 80003b08 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000505e:	04000713          	li	a4,64
    80005062:	4681                	li	a3,0
    80005064:	e5040613          	addi	a2,s0,-432
    80005068:	4581                	li	a1,0
    8000506a:	8556                	mv	a0,s5
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	d50080e7          	jalr	-688(ra) # 80003dbc <readi>
    80005074:	04000793          	li	a5,64
    80005078:	00f51a63          	bne	a0,a5,8000508c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000507c:	e5042703          	lw	a4,-432(s0)
    80005080:	464c47b7          	lui	a5,0x464c4
    80005084:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005088:	04f70663          	beq	a4,a5,800050d4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000508c:	8556                	mv	a0,s5
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	cdc080e7          	jalr	-804(ra) # 80003d6a <iunlockput>
    end_op();
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	4cc080e7          	jalr	1228(ra) # 80004562 <end_op>
  }
  return -1;
    8000509e:	557d                	li	a0,-1
}
    800050a0:	21813083          	ld	ra,536(sp)
    800050a4:	21013403          	ld	s0,528(sp)
    800050a8:	20813483          	ld	s1,520(sp)
    800050ac:	20013903          	ld	s2,512(sp)
    800050b0:	79fe                	ld	s3,504(sp)
    800050b2:	7a5e                	ld	s4,496(sp)
    800050b4:	7abe                	ld	s5,488(sp)
    800050b6:	7b1e                	ld	s6,480(sp)
    800050b8:	6bfe                	ld	s7,472(sp)
    800050ba:	6c5e                	ld	s8,464(sp)
    800050bc:	6cbe                	ld	s9,456(sp)
    800050be:	6d1e                	ld	s10,448(sp)
    800050c0:	7dfa                	ld	s11,440(sp)
    800050c2:	22010113          	addi	sp,sp,544
    800050c6:	8082                	ret
    end_op();
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	49a080e7          	jalr	1178(ra) # 80004562 <end_op>
    return -1;
    800050d0:	557d                	li	a0,-1
    800050d2:	b7f9                	j	800050a0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050d4:	8526                	mv	a0,s1
    800050d6:	ffffd097          	auipc	ra,0xffffd
    800050da:	a30080e7          	jalr	-1488(ra) # 80001b06 <proc_pagetable>
    800050de:	8b2a                	mv	s6,a0
    800050e0:	d555                	beqz	a0,8000508c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050e2:	e7042783          	lw	a5,-400(s0)
    800050e6:	e8845703          	lhu	a4,-376(s0)
    800050ea:	c735                	beqz	a4,80005156 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050ec:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ee:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    800050f2:	6a05                	lui	s4,0x1
    800050f4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050f8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050fc:	6d85                	lui	s11,0x1
    800050fe:	7d7d                	lui	s10,0xfffff
    80005100:	ac1d                	j	80005336 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005102:	00003517          	auipc	a0,0x3
    80005106:	5e650513          	addi	a0,a0,1510 # 800086e8 <syscalls+0x2a0>
    8000510a:	ffffb097          	auipc	ra,0xffffb
    8000510e:	432080e7          	jalr	1074(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005112:	874a                	mv	a4,s2
    80005114:	009c86bb          	addw	a3,s9,s1
    80005118:	4581                	li	a1,0
    8000511a:	8556                	mv	a0,s5
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	ca0080e7          	jalr	-864(ra) # 80003dbc <readi>
    80005124:	2501                	sext.w	a0,a0
    80005126:	1aa91863          	bne	s2,a0,800052d6 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000512a:	009d84bb          	addw	s1,s11,s1
    8000512e:	013d09bb          	addw	s3,s10,s3
    80005132:	1f74f263          	bgeu	s1,s7,80005316 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005136:	02049593          	slli	a1,s1,0x20
    8000513a:	9181                	srli	a1,a1,0x20
    8000513c:	95e2                	add	a1,a1,s8
    8000513e:	855a                	mv	a0,s6
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	f66080e7          	jalr	-154(ra) # 800010a6 <walkaddr>
    80005148:	862a                	mv	a2,a0
    if(pa == 0)
    8000514a:	dd45                	beqz	a0,80005102 <exec+0xfe>
      n = PGSIZE;
    8000514c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000514e:	fd49f2e3          	bgeu	s3,s4,80005112 <exec+0x10e>
      n = sz - i;
    80005152:	894e                	mv	s2,s3
    80005154:	bf7d                	j	80005112 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005156:	4481                	li	s1,0
  iunlockput(ip);
    80005158:	8556                	mv	a0,s5
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	c10080e7          	jalr	-1008(ra) # 80003d6a <iunlockput>
  end_op();
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	400080e7          	jalr	1024(ra) # 80004562 <end_op>
  p = myproc();
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	8d4080e7          	jalr	-1836(ra) # 80001a3e <myproc>
    80005172:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005174:	32053d03          	ld	s10,800(a0)
  sz = PGROUNDUP(sz);
    80005178:	6785                	lui	a5,0x1
    8000517a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000517c:	97a6                	add	a5,a5,s1
    8000517e:	777d                	lui	a4,0xfffff
    80005180:	8ff9                	and	a5,a5,a4
    80005182:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005186:	6609                	lui	a2,0x2
    80005188:	963e                	add	a2,a2,a5
    8000518a:	85be                	mv	a1,a5
    8000518c:	855a                	mv	a0,s6
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	2ae080e7          	jalr	686(ra) # 8000143c <uvmalloc>
    80005196:	8c2a                	mv	s8,a0
  ip = 0;
    80005198:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000519a:	12050e63          	beqz	a0,800052d6 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000519e:	75f9                	lui	a1,0xffffe
    800051a0:	95aa                	add	a1,a1,a0
    800051a2:	855a                	mv	a0,s6
    800051a4:	ffffc097          	auipc	ra,0xffffc
    800051a8:	4ae080e7          	jalr	1198(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    800051ac:	7afd                	lui	s5,0xfffff
    800051ae:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051b0:	df043783          	ld	a5,-528(s0)
    800051b4:	6388                	ld	a0,0(a5)
    800051b6:	c925                	beqz	a0,80005226 <exec+0x222>
    800051b8:	e9040993          	addi	s3,s0,-368
    800051bc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051c0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051c2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	cd0080e7          	jalr	-816(ra) # 80000e94 <strlen>
    800051cc:	0015079b          	addiw	a5,a0,1
    800051d0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051d4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051d8:	13596363          	bltu	s2,s5,800052fe <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051dc:	df043d83          	ld	s11,-528(s0)
    800051e0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051e4:	8552                	mv	a0,s4
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	cae080e7          	jalr	-850(ra) # 80000e94 <strlen>
    800051ee:	0015069b          	addiw	a3,a0,1
    800051f2:	8652                	mv	a2,s4
    800051f4:	85ca                	mv	a1,s2
    800051f6:	855a                	mv	a0,s6
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	48c080e7          	jalr	1164(ra) # 80001684 <copyout>
    80005200:	10054363          	bltz	a0,80005306 <exec+0x302>
    ustack[argc] = sp;
    80005204:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005208:	0485                	addi	s1,s1,1
    8000520a:	008d8793          	addi	a5,s11,8
    8000520e:	def43823          	sd	a5,-528(s0)
    80005212:	008db503          	ld	a0,8(s11)
    80005216:	c911                	beqz	a0,8000522a <exec+0x226>
    if(argc >= MAXARG)
    80005218:	09a1                	addi	s3,s3,8
    8000521a:	fb3c95e3          	bne	s9,s3,800051c4 <exec+0x1c0>
  sz = sz1;
    8000521e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005222:	4a81                	li	s5,0
    80005224:	a84d                	j	800052d6 <exec+0x2d2>
  sp = sz;
    80005226:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005228:	4481                	li	s1,0
  ustack[argc] = 0;
    8000522a:	00349793          	slli	a5,s1,0x3
    8000522e:	f9078793          	addi	a5,a5,-112
    80005232:	97a2                	add	a5,a5,s0
    80005234:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005238:	00148693          	addi	a3,s1,1
    8000523c:	068e                	slli	a3,a3,0x3
    8000523e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005242:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005246:	01597663          	bgeu	s2,s5,80005252 <exec+0x24e>
  sz = sz1;
    8000524a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000524e:	4a81                	li	s5,0
    80005250:	a059                	j	800052d6 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005252:	e9040613          	addi	a2,s0,-368
    80005256:	85ca                	mv	a1,s2
    80005258:	855a                	mv	a0,s6
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	42a080e7          	jalr	1066(ra) # 80001684 <copyout>
    80005262:	0a054663          	bltz	a0,8000530e <exec+0x30a>
  p->trapframe->a1 = sp;
    80005266:	330bb783          	ld	a5,816(s7)
    8000526a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000526e:	de843783          	ld	a5,-536(s0)
    80005272:	0007c703          	lbu	a4,0(a5)
    80005276:	cf11                	beqz	a4,80005292 <exec+0x28e>
    80005278:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000527a:	02f00693          	li	a3,47
    8000527e:	a039                	j	8000528c <exec+0x288>
      last = s+1;
    80005280:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005284:	0785                	addi	a5,a5,1
    80005286:	fff7c703          	lbu	a4,-1(a5)
    8000528a:	c701                	beqz	a4,80005292 <exec+0x28e>
    if(*s == '/')
    8000528c:	fed71ce3          	bne	a4,a3,80005284 <exec+0x280>
    80005290:	bfc5                	j	80005280 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005292:	4641                	li	a2,16
    80005294:	de843583          	ld	a1,-536(s0)
    80005298:	430b8513          	addi	a0,s7,1072
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	bc6080e7          	jalr	-1082(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    800052a4:	328bb503          	ld	a0,808(s7)
  p->pagetable = pagetable;
    800052a8:	336bb423          	sd	s6,808(s7)
  p->sz = sz;
    800052ac:	338bb023          	sd	s8,800(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052b0:	330bb783          	ld	a5,816(s7)
    800052b4:	e6843703          	ld	a4,-408(s0)
    800052b8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052ba:	330bb783          	ld	a5,816(s7)
    800052be:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052c2:	85ea                	mv	a1,s10
    800052c4:	ffffd097          	auipc	ra,0xffffd
    800052c8:	8de080e7          	jalr	-1826(ra) # 80001ba2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052cc:	0004851b          	sext.w	a0,s1
    800052d0:	bbc1                	j	800050a0 <exec+0x9c>
    800052d2:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052d6:	df843583          	ld	a1,-520(s0)
    800052da:	855a                	mv	a0,s6
    800052dc:	ffffd097          	auipc	ra,0xffffd
    800052e0:	8c6080e7          	jalr	-1850(ra) # 80001ba2 <proc_freepagetable>
  if(ip){
    800052e4:	da0a94e3          	bnez	s5,8000508c <exec+0x88>
  return -1;
    800052e8:	557d                	li	a0,-1
    800052ea:	bb5d                	j	800050a0 <exec+0x9c>
    800052ec:	de943c23          	sd	s1,-520(s0)
    800052f0:	b7dd                	j	800052d6 <exec+0x2d2>
    800052f2:	de943c23          	sd	s1,-520(s0)
    800052f6:	b7c5                	j	800052d6 <exec+0x2d2>
    800052f8:	de943c23          	sd	s1,-520(s0)
    800052fc:	bfe9                	j	800052d6 <exec+0x2d2>
  sz = sz1;
    800052fe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005302:	4a81                	li	s5,0
    80005304:	bfc9                	j	800052d6 <exec+0x2d2>
  sz = sz1;
    80005306:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000530a:	4a81                	li	s5,0
    8000530c:	b7e9                	j	800052d6 <exec+0x2d2>
  sz = sz1;
    8000530e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005312:	4a81                	li	s5,0
    80005314:	b7c9                	j	800052d6 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005316:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000531a:	e0843783          	ld	a5,-504(s0)
    8000531e:	0017869b          	addiw	a3,a5,1
    80005322:	e0d43423          	sd	a3,-504(s0)
    80005326:	e0043783          	ld	a5,-512(s0)
    8000532a:	0387879b          	addiw	a5,a5,56
    8000532e:	e8845703          	lhu	a4,-376(s0)
    80005332:	e2e6d3e3          	bge	a3,a4,80005158 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005336:	2781                	sext.w	a5,a5
    80005338:	e0f43023          	sd	a5,-512(s0)
    8000533c:	03800713          	li	a4,56
    80005340:	86be                	mv	a3,a5
    80005342:	e1840613          	addi	a2,s0,-488
    80005346:	4581                	li	a1,0
    80005348:	8556                	mv	a0,s5
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	a72080e7          	jalr	-1422(ra) # 80003dbc <readi>
    80005352:	03800793          	li	a5,56
    80005356:	f6f51ee3          	bne	a0,a5,800052d2 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000535a:	e1842783          	lw	a5,-488(s0)
    8000535e:	4705                	li	a4,1
    80005360:	fae79de3          	bne	a5,a4,8000531a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005364:	e4043603          	ld	a2,-448(s0)
    80005368:	e3843783          	ld	a5,-456(s0)
    8000536c:	f8f660e3          	bltu	a2,a5,800052ec <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005370:	e2843783          	ld	a5,-472(s0)
    80005374:	963e                	add	a2,a2,a5
    80005376:	f6f66ee3          	bltu	a2,a5,800052f2 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000537a:	85a6                	mv	a1,s1
    8000537c:	855a                	mv	a0,s6
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	0be080e7          	jalr	190(ra) # 8000143c <uvmalloc>
    80005386:	dea43c23          	sd	a0,-520(s0)
    8000538a:	d53d                	beqz	a0,800052f8 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000538c:	e2843c03          	ld	s8,-472(s0)
    80005390:	de043783          	ld	a5,-544(s0)
    80005394:	00fc77b3          	and	a5,s8,a5
    80005398:	ff9d                	bnez	a5,800052d6 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000539a:	e2042c83          	lw	s9,-480(s0)
    8000539e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053a2:	f60b8ae3          	beqz	s7,80005316 <exec+0x312>
    800053a6:	89de                	mv	s3,s7
    800053a8:	4481                	li	s1,0
    800053aa:	b371                	j	80005136 <exec+0x132>

00000000800053ac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053ac:	7179                	addi	sp,sp,-48
    800053ae:	f406                	sd	ra,40(sp)
    800053b0:	f022                	sd	s0,32(sp)
    800053b2:	ec26                	sd	s1,24(sp)
    800053b4:	e84a                	sd	s2,16(sp)
    800053b6:	1800                	addi	s0,sp,48
    800053b8:	892e                	mv	s2,a1
    800053ba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053bc:	fdc40593          	addi	a1,s0,-36
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	b7c080e7          	jalr	-1156(ra) # 80002f3c <argint>
    800053c8:	04054063          	bltz	a0,80005408 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053cc:	fdc42703          	lw	a4,-36(s0)
    800053d0:	47bd                	li	a5,15
    800053d2:	02e7ed63          	bltu	a5,a4,8000540c <argfd+0x60>
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	668080e7          	jalr	1640(ra) # 80001a3e <myproc>
    800053de:	fdc42703          	lw	a4,-36(s0)
    800053e2:	07470793          	addi	a5,a4,116 # fffffffffffff074 <end+0xffffffff7ffc9074>
    800053e6:	078e                	slli	a5,a5,0x3
    800053e8:	953e                	add	a0,a0,a5
    800053ea:	651c                	ld	a5,8(a0)
    800053ec:	c395                	beqz	a5,80005410 <argfd+0x64>
    return -1;
  if(pfd)
    800053ee:	00090463          	beqz	s2,800053f6 <argfd+0x4a>
    *pfd = fd;
    800053f2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053f6:	4501                	li	a0,0
  if(pf)
    800053f8:	c091                	beqz	s1,800053fc <argfd+0x50>
    *pf = f;
    800053fa:	e09c                	sd	a5,0(s1)
}
    800053fc:	70a2                	ld	ra,40(sp)
    800053fe:	7402                	ld	s0,32(sp)
    80005400:	64e2                	ld	s1,24(sp)
    80005402:	6942                	ld	s2,16(sp)
    80005404:	6145                	addi	sp,sp,48
    80005406:	8082                	ret
    return -1;
    80005408:	557d                	li	a0,-1
    8000540a:	bfcd                	j	800053fc <argfd+0x50>
    return -1;
    8000540c:	557d                	li	a0,-1
    8000540e:	b7fd                	j	800053fc <argfd+0x50>
    80005410:	557d                	li	a0,-1
    80005412:	b7ed                	j	800053fc <argfd+0x50>

0000000080005414 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005414:	1101                	addi	sp,sp,-32
    80005416:	ec06                	sd	ra,24(sp)
    80005418:	e822                	sd	s0,16(sp)
    8000541a:	e426                	sd	s1,8(sp)
    8000541c:	1000                	addi	s0,sp,32
    8000541e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005420:	ffffc097          	auipc	ra,0xffffc
    80005424:	61e080e7          	jalr	1566(ra) # 80001a3e <myproc>
    80005428:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000542a:	3a850793          	addi	a5,a0,936
    8000542e:	4501                	li	a0,0
    80005430:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005432:	6398                	ld	a4,0(a5)
    80005434:	cb19                	beqz	a4,8000544a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005436:	2505                	addiw	a0,a0,1
    80005438:	07a1                	addi	a5,a5,8
    8000543a:	fed51ce3          	bne	a0,a3,80005432 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000543e:	557d                	li	a0,-1
}
    80005440:	60e2                	ld	ra,24(sp)
    80005442:	6442                	ld	s0,16(sp)
    80005444:	64a2                	ld	s1,8(sp)
    80005446:	6105                	addi	sp,sp,32
    80005448:	8082                	ret
      p->ofile[fd] = f;
    8000544a:	07450793          	addi	a5,a0,116
    8000544e:	078e                	slli	a5,a5,0x3
    80005450:	963e                	add	a2,a2,a5
    80005452:	e604                	sd	s1,8(a2)
      return fd;
    80005454:	b7f5                	j	80005440 <fdalloc+0x2c>

0000000080005456 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005456:	715d                	addi	sp,sp,-80
    80005458:	e486                	sd	ra,72(sp)
    8000545a:	e0a2                	sd	s0,64(sp)
    8000545c:	fc26                	sd	s1,56(sp)
    8000545e:	f84a                	sd	s2,48(sp)
    80005460:	f44e                	sd	s3,40(sp)
    80005462:	f052                	sd	s4,32(sp)
    80005464:	ec56                	sd	s5,24(sp)
    80005466:	0880                	addi	s0,sp,80
    80005468:	89ae                	mv	s3,a1
    8000546a:	8ab2                	mv	s5,a2
    8000546c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000546e:	fb040593          	addi	a1,s0,-80
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	e70080e7          	jalr	-400(ra) # 800042e2 <nameiparent>
    8000547a:	892a                	mv	s2,a0
    8000547c:	12050e63          	beqz	a0,800055b8 <create+0x162>
    return 0;

  ilock(dp);
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	688080e7          	jalr	1672(ra) # 80003b08 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005488:	4601                	li	a2,0
    8000548a:	fb040593          	addi	a1,s0,-80
    8000548e:	854a                	mv	a0,s2
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	b5c080e7          	jalr	-1188(ra) # 80003fec <dirlookup>
    80005498:	84aa                	mv	s1,a0
    8000549a:	c921                	beqz	a0,800054ea <create+0x94>
    iunlockput(dp);
    8000549c:	854a                	mv	a0,s2
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	8cc080e7          	jalr	-1844(ra) # 80003d6a <iunlockput>
    ilock(ip);
    800054a6:	8526                	mv	a0,s1
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	660080e7          	jalr	1632(ra) # 80003b08 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054b0:	2981                	sext.w	s3,s3
    800054b2:	4789                	li	a5,2
    800054b4:	02f99463          	bne	s3,a5,800054dc <create+0x86>
    800054b8:	0444d783          	lhu	a5,68(s1)
    800054bc:	37f9                	addiw	a5,a5,-2
    800054be:	17c2                	slli	a5,a5,0x30
    800054c0:	93c1                	srli	a5,a5,0x30
    800054c2:	4705                	li	a4,1
    800054c4:	00f76c63          	bltu	a4,a5,800054dc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054c8:	8526                	mv	a0,s1
    800054ca:	60a6                	ld	ra,72(sp)
    800054cc:	6406                	ld	s0,64(sp)
    800054ce:	74e2                	ld	s1,56(sp)
    800054d0:	7942                	ld	s2,48(sp)
    800054d2:	79a2                	ld	s3,40(sp)
    800054d4:	7a02                	ld	s4,32(sp)
    800054d6:	6ae2                	ld	s5,24(sp)
    800054d8:	6161                	addi	sp,sp,80
    800054da:	8082                	ret
    iunlockput(ip);
    800054dc:	8526                	mv	a0,s1
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	88c080e7          	jalr	-1908(ra) # 80003d6a <iunlockput>
    return 0;
    800054e6:	4481                	li	s1,0
    800054e8:	b7c5                	j	800054c8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054ea:	85ce                	mv	a1,s3
    800054ec:	00092503          	lw	a0,0(s2)
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	47e080e7          	jalr	1150(ra) # 8000396e <ialloc>
    800054f8:	84aa                	mv	s1,a0
    800054fa:	c521                	beqz	a0,80005542 <create+0xec>
  ilock(ip);
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	60c080e7          	jalr	1548(ra) # 80003b08 <ilock>
  ip->major = major;
    80005504:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005508:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000550c:	4a05                	li	s4,1
    8000550e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	528080e7          	jalr	1320(ra) # 80003a3c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000551c:	2981                	sext.w	s3,s3
    8000551e:	03498a63          	beq	s3,s4,80005552 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005522:	40d0                	lw	a2,4(s1)
    80005524:	fb040593          	addi	a1,s0,-80
    80005528:	854a                	mv	a0,s2
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	cd8080e7          	jalr	-808(ra) # 80004202 <dirlink>
    80005532:	06054b63          	bltz	a0,800055a8 <create+0x152>
  iunlockput(dp);
    80005536:	854a                	mv	a0,s2
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	832080e7          	jalr	-1998(ra) # 80003d6a <iunlockput>
  return ip;
    80005540:	b761                	j	800054c8 <create+0x72>
    panic("create: ialloc");
    80005542:	00003517          	auipc	a0,0x3
    80005546:	1c650513          	addi	a0,a0,454 # 80008708 <syscalls+0x2c0>
    8000554a:	ffffb097          	auipc	ra,0xffffb
    8000554e:	ff2080e7          	jalr	-14(ra) # 8000053c <panic>
    dp->nlink++;  // for ".."
    80005552:	04a95783          	lhu	a5,74(s2)
    80005556:	2785                	addiw	a5,a5,1
    80005558:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000555c:	854a                	mv	a0,s2
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	4de080e7          	jalr	1246(ra) # 80003a3c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005566:	40d0                	lw	a2,4(s1)
    80005568:	00003597          	auipc	a1,0x3
    8000556c:	1b058593          	addi	a1,a1,432 # 80008718 <syscalls+0x2d0>
    80005570:	8526                	mv	a0,s1
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	c90080e7          	jalr	-880(ra) # 80004202 <dirlink>
    8000557a:	00054f63          	bltz	a0,80005598 <create+0x142>
    8000557e:	00492603          	lw	a2,4(s2)
    80005582:	00003597          	auipc	a1,0x3
    80005586:	19e58593          	addi	a1,a1,414 # 80008720 <syscalls+0x2d8>
    8000558a:	8526                	mv	a0,s1
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	c76080e7          	jalr	-906(ra) # 80004202 <dirlink>
    80005594:	f80557e3          	bgez	a0,80005522 <create+0xcc>
      panic("create dots");
    80005598:	00003517          	auipc	a0,0x3
    8000559c:	19050513          	addi	a0,a0,400 # 80008728 <syscalls+0x2e0>
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	f9c080e7          	jalr	-100(ra) # 8000053c <panic>
    panic("create: dirlink");
    800055a8:	00003517          	auipc	a0,0x3
    800055ac:	19050513          	addi	a0,a0,400 # 80008738 <syscalls+0x2f0>
    800055b0:	ffffb097          	auipc	ra,0xffffb
    800055b4:	f8c080e7          	jalr	-116(ra) # 8000053c <panic>
    return 0;
    800055b8:	84aa                	mv	s1,a0
    800055ba:	b739                	j	800054c8 <create+0x72>

00000000800055bc <sys_dup>:
{
    800055bc:	7179                	addi	sp,sp,-48
    800055be:	f406                	sd	ra,40(sp)
    800055c0:	f022                	sd	s0,32(sp)
    800055c2:	ec26                	sd	s1,24(sp)
    800055c4:	e84a                	sd	s2,16(sp)
    800055c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055c8:	fd840613          	addi	a2,s0,-40
    800055cc:	4581                	li	a1,0
    800055ce:	4501                	li	a0,0
    800055d0:	00000097          	auipc	ra,0x0
    800055d4:	ddc080e7          	jalr	-548(ra) # 800053ac <argfd>
    return -1;
    800055d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055da:	02054363          	bltz	a0,80005600 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800055de:	fd843903          	ld	s2,-40(s0)
    800055e2:	854a                	mv	a0,s2
    800055e4:	00000097          	auipc	ra,0x0
    800055e8:	e30080e7          	jalr	-464(ra) # 80005414 <fdalloc>
    800055ec:	84aa                	mv	s1,a0
    return -1;
    800055ee:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055f0:	00054863          	bltz	a0,80005600 <sys_dup+0x44>
  filedup(f);
    800055f4:	854a                	mv	a0,s2
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	368080e7          	jalr	872(ra) # 8000495e <filedup>
  return fd;
    800055fe:	87a6                	mv	a5,s1
}
    80005600:	853e                	mv	a0,a5
    80005602:	70a2                	ld	ra,40(sp)
    80005604:	7402                	ld	s0,32(sp)
    80005606:	64e2                	ld	s1,24(sp)
    80005608:	6942                	ld	s2,16(sp)
    8000560a:	6145                	addi	sp,sp,48
    8000560c:	8082                	ret

000000008000560e <sys_read>:
{
    8000560e:	7179                	addi	sp,sp,-48
    80005610:	f406                	sd	ra,40(sp)
    80005612:	f022                	sd	s0,32(sp)
    80005614:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005616:	fe840613          	addi	a2,s0,-24
    8000561a:	4581                	li	a1,0
    8000561c:	4501                	li	a0,0
    8000561e:	00000097          	auipc	ra,0x0
    80005622:	d8e080e7          	jalr	-626(ra) # 800053ac <argfd>
    return -1;
    80005626:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005628:	04054163          	bltz	a0,8000566a <sys_read+0x5c>
    8000562c:	fe440593          	addi	a1,s0,-28
    80005630:	4509                	li	a0,2
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	90a080e7          	jalr	-1782(ra) # 80002f3c <argint>
    return -1;
    8000563a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563c:	02054763          	bltz	a0,8000566a <sys_read+0x5c>
    80005640:	fd840593          	addi	a1,s0,-40
    80005644:	4505                	li	a0,1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	918080e7          	jalr	-1768(ra) # 80002f5e <argaddr>
    return -1;
    8000564e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005650:	00054d63          	bltz	a0,8000566a <sys_read+0x5c>
  return fileread(f, p, n);
    80005654:	fe442603          	lw	a2,-28(s0)
    80005658:	fd843583          	ld	a1,-40(s0)
    8000565c:	fe843503          	ld	a0,-24(s0)
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	48a080e7          	jalr	1162(ra) # 80004aea <fileread>
    80005668:	87aa                	mv	a5,a0
}
    8000566a:	853e                	mv	a0,a5
    8000566c:	70a2                	ld	ra,40(sp)
    8000566e:	7402                	ld	s0,32(sp)
    80005670:	6145                	addi	sp,sp,48
    80005672:	8082                	ret

0000000080005674 <sys_write>:
{
    80005674:	7179                	addi	sp,sp,-48
    80005676:	f406                	sd	ra,40(sp)
    80005678:	f022                	sd	s0,32(sp)
    8000567a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567c:	fe840613          	addi	a2,s0,-24
    80005680:	4581                	li	a1,0
    80005682:	4501                	li	a0,0
    80005684:	00000097          	auipc	ra,0x0
    80005688:	d28080e7          	jalr	-728(ra) # 800053ac <argfd>
    return -1;
    8000568c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000568e:	04054163          	bltz	a0,800056d0 <sys_write+0x5c>
    80005692:	fe440593          	addi	a1,s0,-28
    80005696:	4509                	li	a0,2
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	8a4080e7          	jalr	-1884(ra) # 80002f3c <argint>
    return -1;
    800056a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a2:	02054763          	bltz	a0,800056d0 <sys_write+0x5c>
    800056a6:	fd840593          	addi	a1,s0,-40
    800056aa:	4505                	li	a0,1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	8b2080e7          	jalr	-1870(ra) # 80002f5e <argaddr>
    return -1;
    800056b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056b6:	00054d63          	bltz	a0,800056d0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800056ba:	fe442603          	lw	a2,-28(s0)
    800056be:	fd843583          	ld	a1,-40(s0)
    800056c2:	fe843503          	ld	a0,-24(s0)
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	4e6080e7          	jalr	1254(ra) # 80004bac <filewrite>
    800056ce:	87aa                	mv	a5,a0
}
    800056d0:	853e                	mv	a0,a5
    800056d2:	70a2                	ld	ra,40(sp)
    800056d4:	7402                	ld	s0,32(sp)
    800056d6:	6145                	addi	sp,sp,48
    800056d8:	8082                	ret

00000000800056da <sys_close>:
{
    800056da:	1101                	addi	sp,sp,-32
    800056dc:	ec06                	sd	ra,24(sp)
    800056de:	e822                	sd	s0,16(sp)
    800056e0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056e2:	fe040613          	addi	a2,s0,-32
    800056e6:	fec40593          	addi	a1,s0,-20
    800056ea:	4501                	li	a0,0
    800056ec:	00000097          	auipc	ra,0x0
    800056f0:	cc0080e7          	jalr	-832(ra) # 800053ac <argfd>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056f6:	02054563          	bltz	a0,80005720 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    800056fa:	ffffc097          	auipc	ra,0xffffc
    800056fe:	344080e7          	jalr	836(ra) # 80001a3e <myproc>
    80005702:	fec42783          	lw	a5,-20(s0)
    80005706:	07478793          	addi	a5,a5,116
    8000570a:	078e                	slli	a5,a5,0x3
    8000570c:	953e                	add	a0,a0,a5
    8000570e:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005712:	fe043503          	ld	a0,-32(s0)
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	29a080e7          	jalr	666(ra) # 800049b0 <fileclose>
  return 0;
    8000571e:	4781                	li	a5,0
}
    80005720:	853e                	mv	a0,a5
    80005722:	60e2                	ld	ra,24(sp)
    80005724:	6442                	ld	s0,16(sp)
    80005726:	6105                	addi	sp,sp,32
    80005728:	8082                	ret

000000008000572a <sys_fstat>:
{
    8000572a:	1101                	addi	sp,sp,-32
    8000572c:	ec06                	sd	ra,24(sp)
    8000572e:	e822                	sd	s0,16(sp)
    80005730:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005732:	fe840613          	addi	a2,s0,-24
    80005736:	4581                	li	a1,0
    80005738:	4501                	li	a0,0
    8000573a:	00000097          	auipc	ra,0x0
    8000573e:	c72080e7          	jalr	-910(ra) # 800053ac <argfd>
    return -1;
    80005742:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005744:	02054563          	bltz	a0,8000576e <sys_fstat+0x44>
    80005748:	fe040593          	addi	a1,s0,-32
    8000574c:	4505                	li	a0,1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	810080e7          	jalr	-2032(ra) # 80002f5e <argaddr>
    return -1;
    80005756:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005758:	00054b63          	bltz	a0,8000576e <sys_fstat+0x44>
  return filestat(f, st);
    8000575c:	fe043583          	ld	a1,-32(s0)
    80005760:	fe843503          	ld	a0,-24(s0)
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	314080e7          	jalr	788(ra) # 80004a78 <filestat>
    8000576c:	87aa                	mv	a5,a0
}
    8000576e:	853e                	mv	a0,a5
    80005770:	60e2                	ld	ra,24(sp)
    80005772:	6442                	ld	s0,16(sp)
    80005774:	6105                	addi	sp,sp,32
    80005776:	8082                	ret

0000000080005778 <sys_link>:
{
    80005778:	7169                	addi	sp,sp,-304
    8000577a:	f606                	sd	ra,296(sp)
    8000577c:	f222                	sd	s0,288(sp)
    8000577e:	ee26                	sd	s1,280(sp)
    80005780:	ea4a                	sd	s2,272(sp)
    80005782:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005784:	08000613          	li	a2,128
    80005788:	ed040593          	addi	a1,s0,-304
    8000578c:	4501                	li	a0,0
    8000578e:	ffffd097          	auipc	ra,0xffffd
    80005792:	7f2080e7          	jalr	2034(ra) # 80002f80 <argstr>
    return -1;
    80005796:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005798:	10054e63          	bltz	a0,800058b4 <sys_link+0x13c>
    8000579c:	08000613          	li	a2,128
    800057a0:	f5040593          	addi	a1,s0,-176
    800057a4:	4505                	li	a0,1
    800057a6:	ffffd097          	auipc	ra,0xffffd
    800057aa:	7da080e7          	jalr	2010(ra) # 80002f80 <argstr>
    return -1;
    800057ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057b0:	10054263          	bltz	a0,800058b4 <sys_link+0x13c>
  begin_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	d30080e7          	jalr	-720(ra) # 800044e4 <begin_op>
  if((ip = namei(old)) == 0){
    800057bc:	ed040513          	addi	a0,s0,-304
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	b04080e7          	jalr	-1276(ra) # 800042c4 <namei>
    800057c8:	84aa                	mv	s1,a0
    800057ca:	c551                	beqz	a0,80005856 <sys_link+0xde>
  ilock(ip);
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	33c080e7          	jalr	828(ra) # 80003b08 <ilock>
  if(ip->type == T_DIR){
    800057d4:	04449703          	lh	a4,68(s1)
    800057d8:	4785                	li	a5,1
    800057da:	08f70463          	beq	a4,a5,80005862 <sys_link+0xea>
  ip->nlink++;
    800057de:	04a4d783          	lhu	a5,74(s1)
    800057e2:	2785                	addiw	a5,a5,1
    800057e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057e8:	8526                	mv	a0,s1
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	252080e7          	jalr	594(ra) # 80003a3c <iupdate>
  iunlock(ip);
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	3d6080e7          	jalr	982(ra) # 80003bca <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057fc:	fd040593          	addi	a1,s0,-48
    80005800:	f5040513          	addi	a0,s0,-176
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	ade080e7          	jalr	-1314(ra) # 800042e2 <nameiparent>
    8000580c:	892a                	mv	s2,a0
    8000580e:	c935                	beqz	a0,80005882 <sys_link+0x10a>
  ilock(dp);
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	2f8080e7          	jalr	760(ra) # 80003b08 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005818:	00092703          	lw	a4,0(s2)
    8000581c:	409c                	lw	a5,0(s1)
    8000581e:	04f71d63          	bne	a4,a5,80005878 <sys_link+0x100>
    80005822:	40d0                	lw	a2,4(s1)
    80005824:	fd040593          	addi	a1,s0,-48
    80005828:	854a                	mv	a0,s2
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	9d8080e7          	jalr	-1576(ra) # 80004202 <dirlink>
    80005832:	04054363          	bltz	a0,80005878 <sys_link+0x100>
  iunlockput(dp);
    80005836:	854a                	mv	a0,s2
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	532080e7          	jalr	1330(ra) # 80003d6a <iunlockput>
  iput(ip);
    80005840:	8526                	mv	a0,s1
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	480080e7          	jalr	1152(ra) # 80003cc2 <iput>
  end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	d18080e7          	jalr	-744(ra) # 80004562 <end_op>
  return 0;
    80005852:	4781                	li	a5,0
    80005854:	a085                	j	800058b4 <sys_link+0x13c>
    end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	d0c080e7          	jalr	-756(ra) # 80004562 <end_op>
    return -1;
    8000585e:	57fd                	li	a5,-1
    80005860:	a891                	j	800058b4 <sys_link+0x13c>
    iunlockput(ip);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	506080e7          	jalr	1286(ra) # 80003d6a <iunlockput>
    end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	cf6080e7          	jalr	-778(ra) # 80004562 <end_op>
    return -1;
    80005874:	57fd                	li	a5,-1
    80005876:	a83d                	j	800058b4 <sys_link+0x13c>
    iunlockput(dp);
    80005878:	854a                	mv	a0,s2
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	4f0080e7          	jalr	1264(ra) # 80003d6a <iunlockput>
  ilock(ip);
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	284080e7          	jalr	644(ra) # 80003b08 <ilock>
  ip->nlink--;
    8000588c:	04a4d783          	lhu	a5,74(s1)
    80005890:	37fd                	addiw	a5,a5,-1
    80005892:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	1a4080e7          	jalr	420(ra) # 80003a3c <iupdate>
  iunlockput(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	4c8080e7          	jalr	1224(ra) # 80003d6a <iunlockput>
  end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	cb8080e7          	jalr	-840(ra) # 80004562 <end_op>
  return -1;
    800058b2:	57fd                	li	a5,-1
}
    800058b4:	853e                	mv	a0,a5
    800058b6:	70b2                	ld	ra,296(sp)
    800058b8:	7412                	ld	s0,288(sp)
    800058ba:	64f2                	ld	s1,280(sp)
    800058bc:	6952                	ld	s2,272(sp)
    800058be:	6155                	addi	sp,sp,304
    800058c0:	8082                	ret

00000000800058c2 <sys_unlink>:
{
    800058c2:	7151                	addi	sp,sp,-240
    800058c4:	f586                	sd	ra,232(sp)
    800058c6:	f1a2                	sd	s0,224(sp)
    800058c8:	eda6                	sd	s1,216(sp)
    800058ca:	e9ca                	sd	s2,208(sp)
    800058cc:	e5ce                	sd	s3,200(sp)
    800058ce:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058d0:	08000613          	li	a2,128
    800058d4:	f3040593          	addi	a1,s0,-208
    800058d8:	4501                	li	a0,0
    800058da:	ffffd097          	auipc	ra,0xffffd
    800058de:	6a6080e7          	jalr	1702(ra) # 80002f80 <argstr>
    800058e2:	18054163          	bltz	a0,80005a64 <sys_unlink+0x1a2>
  begin_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	bfe080e7          	jalr	-1026(ra) # 800044e4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058ee:	fb040593          	addi	a1,s0,-80
    800058f2:	f3040513          	addi	a0,s0,-208
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	9ec080e7          	jalr	-1556(ra) # 800042e2 <nameiparent>
    800058fe:	84aa                	mv	s1,a0
    80005900:	c979                	beqz	a0,800059d6 <sys_unlink+0x114>
  ilock(dp);
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	206080e7          	jalr	518(ra) # 80003b08 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000590a:	00003597          	auipc	a1,0x3
    8000590e:	e0e58593          	addi	a1,a1,-498 # 80008718 <syscalls+0x2d0>
    80005912:	fb040513          	addi	a0,s0,-80
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	6bc080e7          	jalr	1724(ra) # 80003fd2 <namecmp>
    8000591e:	14050a63          	beqz	a0,80005a72 <sys_unlink+0x1b0>
    80005922:	00003597          	auipc	a1,0x3
    80005926:	dfe58593          	addi	a1,a1,-514 # 80008720 <syscalls+0x2d8>
    8000592a:	fb040513          	addi	a0,s0,-80
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	6a4080e7          	jalr	1700(ra) # 80003fd2 <namecmp>
    80005936:	12050e63          	beqz	a0,80005a72 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000593a:	f2c40613          	addi	a2,s0,-212
    8000593e:	fb040593          	addi	a1,s0,-80
    80005942:	8526                	mv	a0,s1
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	6a8080e7          	jalr	1704(ra) # 80003fec <dirlookup>
    8000594c:	892a                	mv	s2,a0
    8000594e:	12050263          	beqz	a0,80005a72 <sys_unlink+0x1b0>
  ilock(ip);
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	1b6080e7          	jalr	438(ra) # 80003b08 <ilock>
  if(ip->nlink < 1)
    8000595a:	04a91783          	lh	a5,74(s2)
    8000595e:	08f05263          	blez	a5,800059e2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005962:	04491703          	lh	a4,68(s2)
    80005966:	4785                	li	a5,1
    80005968:	08f70563          	beq	a4,a5,800059f2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000596c:	4641                	li	a2,16
    8000596e:	4581                	li	a1,0
    80005970:	fc040513          	addi	a0,s0,-64
    80005974:	ffffb097          	auipc	ra,0xffffb
    80005978:	3a4080e7          	jalr	932(ra) # 80000d18 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000597c:	4741                	li	a4,16
    8000597e:	f2c42683          	lw	a3,-212(s0)
    80005982:	fc040613          	addi	a2,s0,-64
    80005986:	4581                	li	a1,0
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	52a080e7          	jalr	1322(ra) # 80003eb4 <writei>
    80005992:	47c1                	li	a5,16
    80005994:	0af51563          	bne	a0,a5,80005a3e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005998:	04491703          	lh	a4,68(s2)
    8000599c:	4785                	li	a5,1
    8000599e:	0af70863          	beq	a4,a5,80005a4e <sys_unlink+0x18c>
  iunlockput(dp);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	3c6080e7          	jalr	966(ra) # 80003d6a <iunlockput>
  ip->nlink--;
    800059ac:	04a95783          	lhu	a5,74(s2)
    800059b0:	37fd                	addiw	a5,a5,-1
    800059b2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059b6:	854a                	mv	a0,s2
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	084080e7          	jalr	132(ra) # 80003a3c <iupdate>
  iunlockput(ip);
    800059c0:	854a                	mv	a0,s2
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	3a8080e7          	jalr	936(ra) # 80003d6a <iunlockput>
  end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	b98080e7          	jalr	-1128(ra) # 80004562 <end_op>
  return 0;
    800059d2:	4501                	li	a0,0
    800059d4:	a84d                	j	80005a86 <sys_unlink+0x1c4>
    end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	b8c080e7          	jalr	-1140(ra) # 80004562 <end_op>
    return -1;
    800059de:	557d                	li	a0,-1
    800059e0:	a05d                	j	80005a86 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059e2:	00003517          	auipc	a0,0x3
    800059e6:	d6650513          	addi	a0,a0,-666 # 80008748 <syscalls+0x300>
    800059ea:	ffffb097          	auipc	ra,0xffffb
    800059ee:	b52080e7          	jalr	-1198(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059f2:	04c92703          	lw	a4,76(s2)
    800059f6:	02000793          	li	a5,32
    800059fa:	f6e7f9e3          	bgeu	a5,a4,8000596c <sys_unlink+0xaa>
    800059fe:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a02:	4741                	li	a4,16
    80005a04:	86ce                	mv	a3,s3
    80005a06:	f1840613          	addi	a2,s0,-232
    80005a0a:	4581                	li	a1,0
    80005a0c:	854a                	mv	a0,s2
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	3ae080e7          	jalr	942(ra) # 80003dbc <readi>
    80005a16:	47c1                	li	a5,16
    80005a18:	00f51b63          	bne	a0,a5,80005a2e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a1c:	f1845783          	lhu	a5,-232(s0)
    80005a20:	e7a1                	bnez	a5,80005a68 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a22:	29c1                	addiw	s3,s3,16
    80005a24:	04c92783          	lw	a5,76(s2)
    80005a28:	fcf9ede3          	bltu	s3,a5,80005a02 <sys_unlink+0x140>
    80005a2c:	b781                	j	8000596c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a2e:	00003517          	auipc	a0,0x3
    80005a32:	d3250513          	addi	a0,a0,-718 # 80008760 <syscalls+0x318>
    80005a36:	ffffb097          	auipc	ra,0xffffb
    80005a3a:	b06080e7          	jalr	-1274(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005a3e:	00003517          	auipc	a0,0x3
    80005a42:	d3a50513          	addi	a0,a0,-710 # 80008778 <syscalls+0x330>
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	af6080e7          	jalr	-1290(ra) # 8000053c <panic>
    dp->nlink--;
    80005a4e:	04a4d783          	lhu	a5,74(s1)
    80005a52:	37fd                	addiw	a5,a5,-1
    80005a54:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a58:	8526                	mv	a0,s1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	fe2080e7          	jalr	-30(ra) # 80003a3c <iupdate>
    80005a62:	b781                	j	800059a2 <sys_unlink+0xe0>
    return -1;
    80005a64:	557d                	li	a0,-1
    80005a66:	a005                	j	80005a86 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a68:	854a                	mv	a0,s2
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	300080e7          	jalr	768(ra) # 80003d6a <iunlockput>
  iunlockput(dp);
    80005a72:	8526                	mv	a0,s1
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	2f6080e7          	jalr	758(ra) # 80003d6a <iunlockput>
  end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	ae6080e7          	jalr	-1306(ra) # 80004562 <end_op>
  return -1;
    80005a84:	557d                	li	a0,-1
}
    80005a86:	70ae                	ld	ra,232(sp)
    80005a88:	740e                	ld	s0,224(sp)
    80005a8a:	64ee                	ld	s1,216(sp)
    80005a8c:	694e                	ld	s2,208(sp)
    80005a8e:	69ae                	ld	s3,200(sp)
    80005a90:	616d                	addi	sp,sp,240
    80005a92:	8082                	ret

0000000080005a94 <sys_open>:

uint64
sys_open(void)
{
    80005a94:	7131                	addi	sp,sp,-192
    80005a96:	fd06                	sd	ra,184(sp)
    80005a98:	f922                	sd	s0,176(sp)
    80005a9a:	f526                	sd	s1,168(sp)
    80005a9c:	f14a                	sd	s2,160(sp)
    80005a9e:	ed4e                	sd	s3,152(sp)
    80005aa0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aa2:	08000613          	li	a2,128
    80005aa6:	f5040593          	addi	a1,s0,-176
    80005aaa:	4501                	li	a0,0
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	4d4080e7          	jalr	1236(ra) # 80002f80 <argstr>
    return -1;
    80005ab4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ab6:	0c054163          	bltz	a0,80005b78 <sys_open+0xe4>
    80005aba:	f4c40593          	addi	a1,s0,-180
    80005abe:	4505                	li	a0,1
    80005ac0:	ffffd097          	auipc	ra,0xffffd
    80005ac4:	47c080e7          	jalr	1148(ra) # 80002f3c <argint>
    80005ac8:	0a054863          	bltz	a0,80005b78 <sys_open+0xe4>

  begin_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	a18080e7          	jalr	-1512(ra) # 800044e4 <begin_op>

  if(omode & O_CREATE){
    80005ad4:	f4c42783          	lw	a5,-180(s0)
    80005ad8:	2007f793          	andi	a5,a5,512
    80005adc:	cbdd                	beqz	a5,80005b92 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ade:	4681                	li	a3,0
    80005ae0:	4601                	li	a2,0
    80005ae2:	4589                	li	a1,2
    80005ae4:	f5040513          	addi	a0,s0,-176
    80005ae8:	00000097          	auipc	ra,0x0
    80005aec:	96e080e7          	jalr	-1682(ra) # 80005456 <create>
    80005af0:	892a                	mv	s2,a0
    if(ip == 0){
    80005af2:	c959                	beqz	a0,80005b88 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005af4:	04491703          	lh	a4,68(s2)
    80005af8:	478d                	li	a5,3
    80005afa:	00f71763          	bne	a4,a5,80005b08 <sys_open+0x74>
    80005afe:	04695703          	lhu	a4,70(s2)
    80005b02:	47a5                	li	a5,9
    80005b04:	0ce7ec63          	bltu	a5,a4,80005bdc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	dec080e7          	jalr	-532(ra) # 800048f4 <filealloc>
    80005b10:	89aa                	mv	s3,a0
    80005b12:	10050263          	beqz	a0,80005c16 <sys_open+0x182>
    80005b16:	00000097          	auipc	ra,0x0
    80005b1a:	8fe080e7          	jalr	-1794(ra) # 80005414 <fdalloc>
    80005b1e:	84aa                	mv	s1,a0
    80005b20:	0e054663          	bltz	a0,80005c0c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b24:	04491703          	lh	a4,68(s2)
    80005b28:	478d                	li	a5,3
    80005b2a:	0cf70463          	beq	a4,a5,80005bf2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b2e:	4789                	li	a5,2
    80005b30:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b34:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b38:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b3c:	f4c42783          	lw	a5,-180(s0)
    80005b40:	0017c713          	xori	a4,a5,1
    80005b44:	8b05                	andi	a4,a4,1
    80005b46:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b4a:	0037f713          	andi	a4,a5,3
    80005b4e:	00e03733          	snez	a4,a4
    80005b52:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b56:	4007f793          	andi	a5,a5,1024
    80005b5a:	c791                	beqz	a5,80005b66 <sys_open+0xd2>
    80005b5c:	04491703          	lh	a4,68(s2)
    80005b60:	4789                	li	a5,2
    80005b62:	08f70f63          	beq	a4,a5,80005c00 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b66:	854a                	mv	a0,s2
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	062080e7          	jalr	98(ra) # 80003bca <iunlock>
  end_op();
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	9f2080e7          	jalr	-1550(ra) # 80004562 <end_op>

  return fd;
}
    80005b78:	8526                	mv	a0,s1
    80005b7a:	70ea                	ld	ra,184(sp)
    80005b7c:	744a                	ld	s0,176(sp)
    80005b7e:	74aa                	ld	s1,168(sp)
    80005b80:	790a                	ld	s2,160(sp)
    80005b82:	69ea                	ld	s3,152(sp)
    80005b84:	6129                	addi	sp,sp,192
    80005b86:	8082                	ret
      end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	9da080e7          	jalr	-1574(ra) # 80004562 <end_op>
      return -1;
    80005b90:	b7e5                	j	80005b78 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b92:	f5040513          	addi	a0,s0,-176
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	72e080e7          	jalr	1838(ra) # 800042c4 <namei>
    80005b9e:	892a                	mv	s2,a0
    80005ba0:	c905                	beqz	a0,80005bd0 <sys_open+0x13c>
    ilock(ip);
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	f66080e7          	jalr	-154(ra) # 80003b08 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005baa:	04491703          	lh	a4,68(s2)
    80005bae:	4785                	li	a5,1
    80005bb0:	f4f712e3          	bne	a4,a5,80005af4 <sys_open+0x60>
    80005bb4:	f4c42783          	lw	a5,-180(s0)
    80005bb8:	dba1                	beqz	a5,80005b08 <sys_open+0x74>
      iunlockput(ip);
    80005bba:	854a                	mv	a0,s2
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	1ae080e7          	jalr	430(ra) # 80003d6a <iunlockput>
      end_op();
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	99e080e7          	jalr	-1634(ra) # 80004562 <end_op>
      return -1;
    80005bcc:	54fd                	li	s1,-1
    80005bce:	b76d                	j	80005b78 <sys_open+0xe4>
      end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	992080e7          	jalr	-1646(ra) # 80004562 <end_op>
      return -1;
    80005bd8:	54fd                	li	s1,-1
    80005bda:	bf79                	j	80005b78 <sys_open+0xe4>
    iunlockput(ip);
    80005bdc:	854a                	mv	a0,s2
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	18c080e7          	jalr	396(ra) # 80003d6a <iunlockput>
    end_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	97c080e7          	jalr	-1668(ra) # 80004562 <end_op>
    return -1;
    80005bee:	54fd                	li	s1,-1
    80005bf0:	b761                	j	80005b78 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bf2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bf6:	04691783          	lh	a5,70(s2)
    80005bfa:	02f99223          	sh	a5,36(s3)
    80005bfe:	bf2d                	j	80005b38 <sys_open+0xa4>
    itrunc(ip);
    80005c00:	854a                	mv	a0,s2
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	014080e7          	jalr	20(ra) # 80003c16 <itrunc>
    80005c0a:	bfb1                	j	80005b66 <sys_open+0xd2>
      fileclose(f);
    80005c0c:	854e                	mv	a0,s3
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	da2080e7          	jalr	-606(ra) # 800049b0 <fileclose>
    iunlockput(ip);
    80005c16:	854a                	mv	a0,s2
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	152080e7          	jalr	338(ra) # 80003d6a <iunlockput>
    end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	942080e7          	jalr	-1726(ra) # 80004562 <end_op>
    return -1;
    80005c28:	54fd                	li	s1,-1
    80005c2a:	b7b9                	j	80005b78 <sys_open+0xe4>

0000000080005c2c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c2c:	7175                	addi	sp,sp,-144
    80005c2e:	e506                	sd	ra,136(sp)
    80005c30:	e122                	sd	s0,128(sp)
    80005c32:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	8b0080e7          	jalr	-1872(ra) # 800044e4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c3c:	08000613          	li	a2,128
    80005c40:	f7040593          	addi	a1,s0,-144
    80005c44:	4501                	li	a0,0
    80005c46:	ffffd097          	auipc	ra,0xffffd
    80005c4a:	33a080e7          	jalr	826(ra) # 80002f80 <argstr>
    80005c4e:	02054963          	bltz	a0,80005c80 <sys_mkdir+0x54>
    80005c52:	4681                	li	a3,0
    80005c54:	4601                	li	a2,0
    80005c56:	4585                	li	a1,1
    80005c58:	f7040513          	addi	a0,s0,-144
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	7fa080e7          	jalr	2042(ra) # 80005456 <create>
    80005c64:	cd11                	beqz	a0,80005c80 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	104080e7          	jalr	260(ra) # 80003d6a <iunlockput>
  end_op();
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	8f4080e7          	jalr	-1804(ra) # 80004562 <end_op>
  return 0;
    80005c76:	4501                	li	a0,0
}
    80005c78:	60aa                	ld	ra,136(sp)
    80005c7a:	640a                	ld	s0,128(sp)
    80005c7c:	6149                	addi	sp,sp,144
    80005c7e:	8082                	ret
    end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	8e2080e7          	jalr	-1822(ra) # 80004562 <end_op>
    return -1;
    80005c88:	557d                	li	a0,-1
    80005c8a:	b7fd                	j	80005c78 <sys_mkdir+0x4c>

0000000080005c8c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c8c:	7135                	addi	sp,sp,-160
    80005c8e:	ed06                	sd	ra,152(sp)
    80005c90:	e922                	sd	s0,144(sp)
    80005c92:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	850080e7          	jalr	-1968(ra) # 800044e4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c9c:	08000613          	li	a2,128
    80005ca0:	f7040593          	addi	a1,s0,-144
    80005ca4:	4501                	li	a0,0
    80005ca6:	ffffd097          	auipc	ra,0xffffd
    80005caa:	2da080e7          	jalr	730(ra) # 80002f80 <argstr>
    80005cae:	04054a63          	bltz	a0,80005d02 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cb2:	f6c40593          	addi	a1,s0,-148
    80005cb6:	4505                	li	a0,1
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	284080e7          	jalr	644(ra) # 80002f3c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cc0:	04054163          	bltz	a0,80005d02 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005cc4:	f6840593          	addi	a1,s0,-152
    80005cc8:	4509                	li	a0,2
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	272080e7          	jalr	626(ra) # 80002f3c <argint>
     argint(1, &major) < 0 ||
    80005cd2:	02054863          	bltz	a0,80005d02 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cd6:	f6841683          	lh	a3,-152(s0)
    80005cda:	f6c41603          	lh	a2,-148(s0)
    80005cde:	458d                	li	a1,3
    80005ce0:	f7040513          	addi	a0,s0,-144
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	772080e7          	jalr	1906(ra) # 80005456 <create>
     argint(2, &minor) < 0 ||
    80005cec:	c919                	beqz	a0,80005d02 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	07c080e7          	jalr	124(ra) # 80003d6a <iunlockput>
  end_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	86c080e7          	jalr	-1940(ra) # 80004562 <end_op>
  return 0;
    80005cfe:	4501                	li	a0,0
    80005d00:	a031                	j	80005d0c <sys_mknod+0x80>
    end_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	860080e7          	jalr	-1952(ra) # 80004562 <end_op>
    return -1;
    80005d0a:	557d                	li	a0,-1
}
    80005d0c:	60ea                	ld	ra,152(sp)
    80005d0e:	644a                	ld	s0,144(sp)
    80005d10:	610d                	addi	sp,sp,160
    80005d12:	8082                	ret

0000000080005d14 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d14:	7135                	addi	sp,sp,-160
    80005d16:	ed06                	sd	ra,152(sp)
    80005d18:	e922                	sd	s0,144(sp)
    80005d1a:	e526                	sd	s1,136(sp)
    80005d1c:	e14a                	sd	s2,128(sp)
    80005d1e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	d1e080e7          	jalr	-738(ra) # 80001a3e <myproc>
    80005d28:	892a                	mv	s2,a0
  
  begin_op();
    80005d2a:	ffffe097          	auipc	ra,0xffffe
    80005d2e:	7ba080e7          	jalr	1978(ra) # 800044e4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d32:	08000613          	li	a2,128
    80005d36:	f6040593          	addi	a1,s0,-160
    80005d3a:	4501                	li	a0,0
    80005d3c:	ffffd097          	auipc	ra,0xffffd
    80005d40:	244080e7          	jalr	580(ra) # 80002f80 <argstr>
    80005d44:	04054b63          	bltz	a0,80005d9a <sys_chdir+0x86>
    80005d48:	f6040513          	addi	a0,s0,-160
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	578080e7          	jalr	1400(ra) # 800042c4 <namei>
    80005d54:	84aa                	mv	s1,a0
    80005d56:	c131                	beqz	a0,80005d9a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	db0080e7          	jalr	-592(ra) # 80003b08 <ilock>
  if(ip->type != T_DIR){
    80005d60:	04449703          	lh	a4,68(s1)
    80005d64:	4785                	li	a5,1
    80005d66:	04f71063          	bne	a4,a5,80005da6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d6a:	8526                	mv	a0,s1
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	e5e080e7          	jalr	-418(ra) # 80003bca <iunlock>
  iput(p->cwd);
    80005d74:	42893503          	ld	a0,1064(s2)
    80005d78:	ffffe097          	auipc	ra,0xffffe
    80005d7c:	f4a080e7          	jalr	-182(ra) # 80003cc2 <iput>
  end_op();
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	7e2080e7          	jalr	2018(ra) # 80004562 <end_op>
  p->cwd = ip;
    80005d88:	42993423          	sd	s1,1064(s2)
  return 0;
    80005d8c:	4501                	li	a0,0
}
    80005d8e:	60ea                	ld	ra,152(sp)
    80005d90:	644a                	ld	s0,144(sp)
    80005d92:	64aa                	ld	s1,136(sp)
    80005d94:	690a                	ld	s2,128(sp)
    80005d96:	610d                	addi	sp,sp,160
    80005d98:	8082                	ret
    end_op();
    80005d9a:	ffffe097          	auipc	ra,0xffffe
    80005d9e:	7c8080e7          	jalr	1992(ra) # 80004562 <end_op>
    return -1;
    80005da2:	557d                	li	a0,-1
    80005da4:	b7ed                	j	80005d8e <sys_chdir+0x7a>
    iunlockput(ip);
    80005da6:	8526                	mv	a0,s1
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	fc2080e7          	jalr	-62(ra) # 80003d6a <iunlockput>
    end_op();
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	7b2080e7          	jalr	1970(ra) # 80004562 <end_op>
    return -1;
    80005db8:	557d                	li	a0,-1
    80005dba:	bfd1                	j	80005d8e <sys_chdir+0x7a>

0000000080005dbc <sys_exec>:

uint64
sys_exec(void)
{
    80005dbc:	7145                	addi	sp,sp,-464
    80005dbe:	e786                	sd	ra,456(sp)
    80005dc0:	e3a2                	sd	s0,448(sp)
    80005dc2:	ff26                	sd	s1,440(sp)
    80005dc4:	fb4a                	sd	s2,432(sp)
    80005dc6:	f74e                	sd	s3,424(sp)
    80005dc8:	f352                	sd	s4,416(sp)
    80005dca:	ef56                	sd	s5,408(sp)
    80005dcc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dce:	08000613          	li	a2,128
    80005dd2:	f4040593          	addi	a1,s0,-192
    80005dd6:	4501                	li	a0,0
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	1a8080e7          	jalr	424(ra) # 80002f80 <argstr>
    return -1;
    80005de0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005de2:	0c054b63          	bltz	a0,80005eb8 <sys_exec+0xfc>
    80005de6:	e3840593          	addi	a1,s0,-456
    80005dea:	4505                	li	a0,1
    80005dec:	ffffd097          	auipc	ra,0xffffd
    80005df0:	172080e7          	jalr	370(ra) # 80002f5e <argaddr>
    80005df4:	0c054263          	bltz	a0,80005eb8 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005df8:	10000613          	li	a2,256
    80005dfc:	4581                	li	a1,0
    80005dfe:	e4040513          	addi	a0,s0,-448
    80005e02:	ffffb097          	auipc	ra,0xffffb
    80005e06:	f16080e7          	jalr	-234(ra) # 80000d18 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e0a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e0e:	89a6                	mv	s3,s1
    80005e10:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e12:	02000a13          	li	s4,32
    80005e16:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e1a:	00391513          	slli	a0,s2,0x3
    80005e1e:	e3040593          	addi	a1,s0,-464
    80005e22:	e3843783          	ld	a5,-456(s0)
    80005e26:	953e                	add	a0,a0,a5
    80005e28:	ffffd097          	auipc	ra,0xffffd
    80005e2c:	074080e7          	jalr	116(ra) # 80002e9c <fetchaddr>
    80005e30:	02054a63          	bltz	a0,80005e64 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e34:	e3043783          	ld	a5,-464(s0)
    80005e38:	c3b9                	beqz	a5,80005e7e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e3a:	ffffb097          	auipc	ra,0xffffb
    80005e3e:	ca8080e7          	jalr	-856(ra) # 80000ae2 <kalloc>
    80005e42:	85aa                	mv	a1,a0
    80005e44:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e48:	cd11                	beqz	a0,80005e64 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e4a:	6605                	lui	a2,0x1
    80005e4c:	e3043503          	ld	a0,-464(s0)
    80005e50:	ffffd097          	auipc	ra,0xffffd
    80005e54:	0a2080e7          	jalr	162(ra) # 80002ef2 <fetchstr>
    80005e58:	00054663          	bltz	a0,80005e64 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e5c:	0905                	addi	s2,s2,1
    80005e5e:	09a1                	addi	s3,s3,8
    80005e60:	fb491be3          	bne	s2,s4,80005e16 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e64:	f4040913          	addi	s2,s0,-192
    80005e68:	6088                	ld	a0,0(s1)
    80005e6a:	c531                	beqz	a0,80005eb6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	b78080e7          	jalr	-1160(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e74:	04a1                	addi	s1,s1,8
    80005e76:	ff2499e3          	bne	s1,s2,80005e68 <sys_exec+0xac>
  return -1;
    80005e7a:	597d                	li	s2,-1
    80005e7c:	a835                	j	80005eb8 <sys_exec+0xfc>
      argv[i] = 0;
    80005e7e:	0a8e                	slli	s5,s5,0x3
    80005e80:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffc8fc0>
    80005e84:	00878ab3          	add	s5,a5,s0
    80005e88:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e8c:	e4040593          	addi	a1,s0,-448
    80005e90:	f4040513          	addi	a0,s0,-192
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	170080e7          	jalr	368(ra) # 80005004 <exec>
    80005e9c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e9e:	f4040993          	addi	s3,s0,-192
    80005ea2:	6088                	ld	a0,0(s1)
    80005ea4:	c911                	beqz	a0,80005eb8 <sys_exec+0xfc>
    kfree(argv[i]);
    80005ea6:	ffffb097          	auipc	ra,0xffffb
    80005eaa:	b3e080e7          	jalr	-1218(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eae:	04a1                	addi	s1,s1,8
    80005eb0:	ff3499e3          	bne	s1,s3,80005ea2 <sys_exec+0xe6>
    80005eb4:	a011                	j	80005eb8 <sys_exec+0xfc>
  return -1;
    80005eb6:	597d                	li	s2,-1
}
    80005eb8:	854a                	mv	a0,s2
    80005eba:	60be                	ld	ra,456(sp)
    80005ebc:	641e                	ld	s0,448(sp)
    80005ebe:	74fa                	ld	s1,440(sp)
    80005ec0:	795a                	ld	s2,432(sp)
    80005ec2:	79ba                	ld	s3,424(sp)
    80005ec4:	7a1a                	ld	s4,416(sp)
    80005ec6:	6afa                	ld	s5,408(sp)
    80005ec8:	6179                	addi	sp,sp,464
    80005eca:	8082                	ret

0000000080005ecc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ecc:	7139                	addi	sp,sp,-64
    80005ece:	fc06                	sd	ra,56(sp)
    80005ed0:	f822                	sd	s0,48(sp)
    80005ed2:	f426                	sd	s1,40(sp)
    80005ed4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ed6:	ffffc097          	auipc	ra,0xffffc
    80005eda:	b68080e7          	jalr	-1176(ra) # 80001a3e <myproc>
    80005ede:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ee0:	fd840593          	addi	a1,s0,-40
    80005ee4:	4501                	li	a0,0
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	078080e7          	jalr	120(ra) # 80002f5e <argaddr>
    return -1;
    80005eee:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ef0:	0e054563          	bltz	a0,80005fda <sys_pipe+0x10e>
  if(pipealloc(&rf, &wf) < 0)
    80005ef4:	fc840593          	addi	a1,s0,-56
    80005ef8:	fd040513          	addi	a0,s0,-48
    80005efc:	fffff097          	auipc	ra,0xfffff
    80005f00:	de4080e7          	jalr	-540(ra) # 80004ce0 <pipealloc>
    return -1;
    80005f04:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f06:	0c054a63          	bltz	a0,80005fda <sys_pipe+0x10e>
  fd0 = -1;
    80005f0a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f0e:	fd043503          	ld	a0,-48(s0)
    80005f12:	fffff097          	auipc	ra,0xfffff
    80005f16:	502080e7          	jalr	1282(ra) # 80005414 <fdalloc>
    80005f1a:	fca42223          	sw	a0,-60(s0)
    80005f1e:	0a054163          	bltz	a0,80005fc0 <sys_pipe+0xf4>
    80005f22:	fc843503          	ld	a0,-56(s0)
    80005f26:	fffff097          	auipc	ra,0xfffff
    80005f2a:	4ee080e7          	jalr	1262(ra) # 80005414 <fdalloc>
    80005f2e:	fca42023          	sw	a0,-64(s0)
    80005f32:	06054d63          	bltz	a0,80005fac <sys_pipe+0xe0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f36:	4691                	li	a3,4
    80005f38:	fc440613          	addi	a2,s0,-60
    80005f3c:	fd843583          	ld	a1,-40(s0)
    80005f40:	3284b503          	ld	a0,808(s1)
    80005f44:	ffffb097          	auipc	ra,0xffffb
    80005f48:	740080e7          	jalr	1856(ra) # 80001684 <copyout>
    80005f4c:	02054163          	bltz	a0,80005f6e <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f50:	4691                	li	a3,4
    80005f52:	fc040613          	addi	a2,s0,-64
    80005f56:	fd843583          	ld	a1,-40(s0)
    80005f5a:	0591                	addi	a1,a1,4
    80005f5c:	3284b503          	ld	a0,808(s1)
    80005f60:	ffffb097          	auipc	ra,0xffffb
    80005f64:	724080e7          	jalr	1828(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f68:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f6a:	06055863          	bgez	a0,80005fda <sys_pipe+0x10e>
    p->ofile[fd0] = 0;
    80005f6e:	fc442783          	lw	a5,-60(s0)
    80005f72:	07478793          	addi	a5,a5,116
    80005f76:	078e                	slli	a5,a5,0x3
    80005f78:	97a6                	add	a5,a5,s1
    80005f7a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f7e:	fc042783          	lw	a5,-64(s0)
    80005f82:	07478793          	addi	a5,a5,116
    80005f86:	078e                	slli	a5,a5,0x3
    80005f88:	00f48533          	add	a0,s1,a5
    80005f8c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f90:	fd043503          	ld	a0,-48(s0)
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	a1c080e7          	jalr	-1508(ra) # 800049b0 <fileclose>
    fileclose(wf);
    80005f9c:	fc843503          	ld	a0,-56(s0)
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	a10080e7          	jalr	-1520(ra) # 800049b0 <fileclose>
    return -1;
    80005fa8:	57fd                	li	a5,-1
    80005faa:	a805                	j	80005fda <sys_pipe+0x10e>
    if(fd0 >= 0)
    80005fac:	fc442783          	lw	a5,-60(s0)
    80005fb0:	0007c863          	bltz	a5,80005fc0 <sys_pipe+0xf4>
      p->ofile[fd0] = 0;
    80005fb4:	07478793          	addi	a5,a5,116
    80005fb8:	078e                	slli	a5,a5,0x3
    80005fba:	97a6                	add	a5,a5,s1
    80005fbc:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005fc0:	fd043503          	ld	a0,-48(s0)
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	9ec080e7          	jalr	-1556(ra) # 800049b0 <fileclose>
    fileclose(wf);
    80005fcc:	fc843503          	ld	a0,-56(s0)
    80005fd0:	fffff097          	auipc	ra,0xfffff
    80005fd4:	9e0080e7          	jalr	-1568(ra) # 800049b0 <fileclose>
    return -1;
    80005fd8:	57fd                	li	a5,-1
}
    80005fda:	853e                	mv	a0,a5
    80005fdc:	70e2                	ld	ra,56(sp)
    80005fde:	7442                	ld	s0,48(sp)
    80005fe0:	74a2                	ld	s1,40(sp)
    80005fe2:	6121                	addi	sp,sp,64
    80005fe4:	8082                	ret

0000000080005fe6 <sys_mmap>:

// HW5 - Task 1a
// Create a new mapped memory region
uint64
sys_mmap()
{
    80005fe6:	7139                	addi	sp,sp,-64
    80005fe8:	fc06                	sd	ra,56(sp)
    80005fea:	f822                	sd	s0,48(sp)
    80005fec:	f426                	sd	s1,40(sp)
    80005fee:	f04a                	sd	s2,32(sp)
    80005ff0:	ec4e                	sd	s3,24(sp)
    80005ff2:	0080                	addi	s0,sp,64
  uint64 length;
  int    prot;
  int    flags;
  struct proc *p = myproc();
    80005ff4:	ffffc097          	auipc	ra,0xffffc
    80005ff8:	a4a080e7          	jalr	-1462(ra) # 80001a3e <myproc>
    80005ffc:	89aa                	mv	s3,a0
  struct mmr *newmmr = 0;
  uint64 start_addr;

  /* Add error checking for length, prot, and flags arguments */

  if (argaddr(1, &length) < 0)
    80005ffe:	fc840593          	addi	a1,s0,-56
    80006002:	4505                	li	a0,1
    80006004:	ffffd097          	auipc	ra,0xffffd
    80006008:	f5a080e7          	jalr	-166(ra) # 80002f5e <argaddr>
    return -1;
    8000600c:	597d                	li	s2,-1
  if (argaddr(1, &length) < 0)
    8000600e:	0a054863          	bltz	a0,800060be <sys_mmap+0xd8>
  if (argint(2, &prot) < 0)
    80006012:	fc440593          	addi	a1,s0,-60
    80006016:	4509                	li	a0,2
    80006018:	ffffd097          	auipc	ra,0xffffd
    8000601c:	f24080e7          	jalr	-220(ra) # 80002f3c <argint>
    80006020:	08054f63          	bltz	a0,800060be <sys_mmap+0xd8>
    return -1;
  if (argint(3, &flags) <0)
    80006024:	fc040593          	addi	a1,s0,-64
    80006028:	450d                	li	a0,3
    8000602a:	ffffd097          	auipc	ra,0xffffd
    8000602e:	f12080e7          	jalr	-238(ra) # 80002f3c <argint>
    80006032:	0c054263          	bltz	a0,800060f6 <sys_mmap+0x110>
    80006036:	01498793          	addi	a5,s3,20
    return -1;
  // Search p->mmr[] for unused location 
  for (int i = 0; i < MAX_MMR; i++) {
    8000603a:	4481                	li	s1,0
    8000603c:	46a9                	li	a3,10
    if (p->mmr[i].valid == 0) {
    8000603e:	4398                	lw	a4,0(a5)
    80006040:	cb01                	beqz	a4,80006050 <sys_mmap+0x6a>
  for (int i = 0; i < MAX_MMR; i++) {
    80006042:	2485                	addiw	s1,s1,1
    80006044:	04878793          	addi	a5,a5,72
    80006048:	fed49be3          	bne	s1,a3,8000603e <sys_mmap+0x58>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
      newmmr->mmr_family.listid = alloc_mmr_listid();
    p->cur_max = start_addr;
    return start_addr;
  } else {
    return -1;
    8000604c:	597d                	li	s2,-1
    8000604e:	a885                	j	800060be <sys_mmap+0xd8>
    start_addr = PGROUNDDOWN(p->cur_max-length);
    80006050:	2d09b903          	ld	s2,720(s3)
    80006054:	fc843783          	ld	a5,-56(s0)
    80006058:	40f90933          	sub	s2,s2,a5
    8000605c:	77fd                	lui	a5,0xfffff
    8000605e:	00f97933          	and	s2,s2,a5
    newmmr->valid = 1;
    80006062:	00349713          	slli	a4,s1,0x3
    80006066:	009707b3          	add	a5,a4,s1
    8000606a:	078e                	slli	a5,a5,0x3
    8000606c:	97ce                	add	a5,a5,s3
    8000606e:	4685                	li	a3,1
    80006070:	cbd4                	sw	a3,20(a5)
    newmmr->addr = start_addr;
    80006072:	0127b023          	sd	s2,0(a5) # fffffffffffff000 <end+0xffffffff7ffc9000>
    newmmr->length = p->cur_max - start_addr;
    80006076:	2d09b603          	ld	a2,720(s3)
    8000607a:	4126063b          	subw	a2,a2,s2
    8000607e:	c790                	sw	a2,8(a5)
    newmmr->prot = prot;
    80006080:	fc442683          	lw	a3,-60(s0)
    80006084:	c7d4                	sw	a3,12(a5)
    newmmr->flags = flags;
    80006086:	fc042683          	lw	a3,-64(s0)
    8000608a:	cb94                	sw	a3,16(a5)
    newmmr->mmr_family.proc = p;
    8000608c:	9726                	add	a4,a4,s1
    8000608e:	070e                	slli	a4,a4,0x3
    80006090:	0337b823          	sd	s3,48(a5)
    newmmr->mmr_family.next = &(newmmr->mmr_family);  // next points to its own mmr_node
    80006094:	02870713          	addi	a4,a4,40
    80006098:	974e                	add	a4,a4,s3
    8000609a:	ff98                	sd	a4,56(a5)
    newmmr->mmr_family.prev = &(newmmr->mmr_family);  // prev points to its own mmr_node
    8000609c:	e3b8                	sd	a4,64(a5)
    if (mapvpages(p->pagetable, newmmr->addr, newmmr->length) < 0) {
    8000609e:	2601                	sext.w	a2,a2
    800060a0:	85ca                	mv	a1,s2
    800060a2:	3289b503          	ld	a0,808(s3)
    800060a6:	ffffb097          	auipc	ra,0xffffb
    800060aa:	7a8080e7          	jalr	1960(ra) # 8000184e <mapvpages>
    800060ae:	02054063          	bltz	a0,800060ce <sys_mmap+0xe8>
    if (flags & MAP_SHARED)    // start an mmr_list if region is shared
    800060b2:	fc042783          	lw	a5,-64(s0)
    800060b6:	8b85                	andi	a5,a5,1
    800060b8:	e785                	bnez	a5,800060e0 <sys_mmap+0xfa>
    p->cur_max = start_addr;
    800060ba:	2d29b823          	sd	s2,720(s3)
  }
}
    800060be:	854a                	mv	a0,s2
    800060c0:	70e2                	ld	ra,56(sp)
    800060c2:	7442                	ld	s0,48(sp)
    800060c4:	74a2                	ld	s1,40(sp)
    800060c6:	7902                	ld	s2,32(sp)
    800060c8:	69e2                	ld	s3,24(sp)
    800060ca:	6121                	addi	sp,sp,64
    800060cc:	8082                	ret
      newmmr->valid = 0;
    800060ce:	00349793          	slli	a5,s1,0x3
    800060d2:	97a6                	add	a5,a5,s1
    800060d4:	078e                	slli	a5,a5,0x3
    800060d6:	97ce                	add	a5,a5,s3
    800060d8:	0007aa23          	sw	zero,20(a5)
      return -1;
    800060dc:	597d                	li	s2,-1
    800060de:	b7c5                	j	800060be <sys_mmap+0xd8>
      newmmr->mmr_family.listid = alloc_mmr_listid();
    800060e0:	ffffc097          	auipc	ra,0xffffc
    800060e4:	7aa080e7          	jalr	1962(ra) # 8000288a <alloc_mmr_listid>
    800060e8:	00349793          	slli	a5,s1,0x3
    800060ec:	97a6                	add	a5,a5,s1
    800060ee:	078e                	slli	a5,a5,0x3
    800060f0:	97ce                	add	a5,a5,s3
    800060f2:	d788                	sw	a0,40(a5)
    800060f4:	b7d9                	j	800060ba <sys_mmap+0xd4>
    return -1;
    800060f6:	597d                	li	s2,-1
    800060f8:	b7d9                	j	800060be <sys_mmap+0xd8>

00000000800060fa <munmap>:
// HW5 - Task 1a
// Unmap memory region if it exists
// Free physical memory if no other process has the region mapped
int
munmap(uint64 addr, uint64 length)
{
    800060fa:	715d                	addi	sp,sp,-80
    800060fc:	e486                	sd	ra,72(sp)
    800060fe:	e0a2                	sd	s0,64(sp)
    80006100:	fc26                	sd	s1,56(sp)
    80006102:	f84a                	sd	s2,48(sp)
    80006104:	f44e                	sd	s3,40(sp)
    80006106:	f052                	sd	s4,32(sp)
    80006108:	ec56                	sd	s5,24(sp)
    8000610a:	e85a                	sd	s6,16(sp)
    8000610c:	e45e                	sd	s7,8(sp)
    8000610e:	e062                	sd	s8,0(sp)
    80006110:	0880                	addi	s0,sp,80
    80006112:	84aa                	mv	s1,a0
    80006114:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80006116:	ffffc097          	auipc	ra,0xffffc
    8000611a:	928080e7          	jalr	-1752(ra) # 80001a3e <myproc>
    8000611e:	8a2a                	mv	s4,a0
  struct mmr *mmr = 0;
  int dofree = 0;
  int i;

  // Search proc->mmr for addr
  for (i = 0; i < MAX_MMR; i++)
    80006120:	87aa                	mv	a5,a0
    80006122:	4901                	li	s2,0
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    80006124:	4685                	li	a3,1
        (PGROUNDUP(length) == p->mmr[i].length)) {
    80006126:	6705                	lui	a4,0x1
    80006128:	177d                	addi	a4,a4,-1 # fff <_entry-0x7ffff001>
    8000612a:	00e985b3          	add	a1,s3,a4
    8000612e:	777d                	lui	a4,0xfffff
    80006130:	8df9                	and	a1,a1,a4
  for (i = 0; i < MAX_MMR; i++)
    80006132:	4629                	li	a2,10
    80006134:	a031                	j	80006140 <munmap+0x46>
    80006136:	2905                	addiw	s2,s2,1
    80006138:	04878793          	addi	a5,a5,72
    8000613c:	04c90763          	beq	s2,a2,8000618a <munmap+0x90>
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    80006140:	0147a983          	lw	s3,20(a5)
    80006144:	fed999e3          	bne	s3,a3,80006136 <munmap+0x3c>
    80006148:	6388                	ld	a0,0(a5)
    8000614a:	fe9516e3          	bne	a0,s1,80006136 <munmap+0x3c>
        (PGROUNDUP(length) == p->mmr[i].length)) {
    8000614e:	4798                	lw	a4,8(a5)
    if ((p->mmr[i].valid == 1) && (addr == p->mmr[i].addr) &&
    80006150:	fee593e3          	bne	a1,a4,80006136 <munmap+0x3c>
      break;
    }
  if (!mmr) {
    return -1;
  }
  mmr->valid = 0;
    80006154:	00391793          	slli	a5,s2,0x3
    80006158:	97ca                	add	a5,a5,s2
    8000615a:	078e                	slli	a5,a5,0x3
    8000615c:	97d2                	add	a5,a5,s4
    8000615e:	0007aa23          	sw	zero,20(a5)
  if (mmr->flags & MAP_PRIVATE)
    80006162:	0107aa83          	lw	s5,16(a5)
    80006166:	002afa93          	andi	s5,s5,2
    8000616a:	020a8263          	beqz	s5,8000618e <munmap+0x94>
      release(&pmmrlist->lock);
    }
  }
  // Remove mappings from page table
  // Also free physical memory if no other process has this region mapped
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    8000616e:	00391793          	slli	a5,s2,0x3
    80006172:	993e                	add	s2,s2,a5
    80006174:	090e                	slli	s2,s2,0x3
    80006176:	9952                	add	s2,s2,s4
    80006178:	00892783          	lw	a5,8(s2)
    8000617c:	00093703          	ld	a4,0(s2)
    80006180:	97ba                	add	a5,a5,a4
    80006182:	0cf4f463          	bgeu	s1,a5,8000624a <munmap+0x150>
    80006186:	6a85                	lui	s5,0x1
    80006188:	a051                	j	8000620c <munmap+0x112>
    return -1;
    8000618a:	557d                	li	a0,-1
    8000618c:	a05d                	j	80006232 <munmap+0x138>
    struct mmr_list *pmmrlist = get_mmr_list(mmr->mmr_family.listid);
    8000618e:	00391b13          	slli	s6,s2,0x3
    80006192:	012b0c33          	add	s8,s6,s2
    80006196:	0c0e                	slli	s8,s8,0x3
    80006198:	9c52                	add	s8,s8,s4
    8000619a:	028c2503          	lw	a0,40(s8)
    8000619e:	ffffc097          	auipc	ra,0xffffc
    800061a2:	630080e7          	jalr	1584(ra) # 800027ce <get_mmr_list>
    800061a6:	8baa                	mv	s7,a0
    acquire(&pmmrlist->lock);
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	a74080e7          	jalr	-1420(ra) # 80000c1c <acquire>
    if (mmr->mmr_family.next == &(mmr->mmr_family)) { // no other family members
    800061b0:	038c3703          	ld	a4,56(s8)
    800061b4:	012b07b3          	add	a5,s6,s2
    800061b8:	078e                	slli	a5,a5,0x3
    800061ba:	02878793          	addi	a5,a5,40
    800061be:	97d2                	add	a5,a5,s4
    800061c0:	02f70263          	beq	a4,a5,800061e4 <munmap+0xea>
      (mmr->mmr_family.next)->prev = mmr->mmr_family.prev;
    800061c4:	00391793          	slli	a5,s2,0x3
    800061c8:	97ca                	add	a5,a5,s2
    800061ca:	078e                	slli	a5,a5,0x3
    800061cc:	97d2                	add	a5,a5,s4
    800061ce:	63b4                	ld	a3,64(a5)
    800061d0:	ef14                	sd	a3,24(a4)
      (mmr->mmr_family.prev)->next = mmr->mmr_family.next;
    800061d2:	7f9c                	ld	a5,56(a5)
    800061d4:	ea9c                	sd	a5,16(a3)
      release(&pmmrlist->lock);
    800061d6:	855e                	mv	a0,s7
    800061d8:	ffffb097          	auipc	ra,0xffffb
    800061dc:	af8080e7          	jalr	-1288(ra) # 80000cd0 <release>
  int dofree = 0;
    800061e0:	89d6                	mv	s3,s5
    800061e2:	b771                	j	8000616e <munmap+0x74>
      release(&pmmrlist->lock);
    800061e4:	855e                	mv	a0,s7
    800061e6:	ffffb097          	auipc	ra,0xffffb
    800061ea:	aea080e7          	jalr	-1302(ra) # 80000cd0 <release>
      dealloc_mmr_listid(mmr->mmr_family.listid);
    800061ee:	028c2503          	lw	a0,40(s8)
    800061f2:	ffffc097          	auipc	ra,0xffffc
    800061f6:	652080e7          	jalr	1618(ra) # 80002844 <dealloc_mmr_listid>
    800061fa:	bf95                	j	8000616e <munmap+0x74>
  for (uint64 pageaddr = addr; pageaddr < p->mmr[i].addr+p->mmr[i].length; pageaddr += PGSIZE) {
    800061fc:	94d6                	add	s1,s1,s5
    800061fe:	00892783          	lw	a5,8(s2)
    80006202:	00093703          	ld	a4,0(s2)
    80006206:	97ba                	add	a5,a5,a4
    80006208:	02f4f463          	bgeu	s1,a5,80006230 <munmap+0x136>
    if (walkaddr(p->pagetable, pageaddr)) {
    8000620c:	85a6                	mv	a1,s1
    8000620e:	328a3503          	ld	a0,808(s4)
    80006212:	ffffb097          	auipc	ra,0xffffb
    80006216:	e94080e7          	jalr	-364(ra) # 800010a6 <walkaddr>
    8000621a:	d16d                	beqz	a0,800061fc <munmap+0x102>
      uvmunmap(p->pagetable, pageaddr, 1, dofree);
    8000621c:	86ce                	mv	a3,s3
    8000621e:	4605                	li	a2,1
    80006220:	85a6                	mv	a1,s1
    80006222:	328a3503          	ld	a0,808(s4)
    80006226:	ffffb097          	auipc	ra,0xffffb
    8000622a:	088080e7          	jalr	136(ra) # 800012ae <uvmunmap>
    8000622e:	b7f9                	j	800061fc <munmap+0x102>
    }
  }
  return 0;
    80006230:	4501                	li	a0,0
}
    80006232:	60a6                	ld	ra,72(sp)
    80006234:	6406                	ld	s0,64(sp)
    80006236:	74e2                	ld	s1,56(sp)
    80006238:	7942                	ld	s2,48(sp)
    8000623a:	79a2                	ld	s3,40(sp)
    8000623c:	7a02                	ld	s4,32(sp)
    8000623e:	6ae2                	ld	s5,24(sp)
    80006240:	6b42                	ld	s6,16(sp)
    80006242:	6ba2                	ld	s7,8(sp)
    80006244:	6c02                	ld	s8,0(sp)
    80006246:	6161                	addi	sp,sp,80
    80006248:	8082                	ret
  return 0;
    8000624a:	4501                	li	a0,0
    8000624c:	b7dd                	j	80006232 <munmap+0x138>

000000008000624e <sys_munmap>:

// Get arguments and call munmap() helper function
uint64
sys_munmap(void)
{
    8000624e:	1101                	addi	sp,sp,-32
    80006250:	ec06                	sd	ra,24(sp)
    80006252:	e822                	sd	s0,16(sp)
    80006254:	1000                	addi	s0,sp,32
  uint64 addr;
  uint64 length;

  // HW5 - Task 1a
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    80006256:	fe840593          	addi	a1,s0,-24
    8000625a:	4501                	li	a0,0
    8000625c:	ffffd097          	auipc	ra,0xffffd
    80006260:	d02080e7          	jalr	-766(ra) # 80002f5e <argaddr>
        return -1;
    80006264:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    80006266:	02054563          	bltz	a0,80006290 <sys_munmap+0x42>
    8000626a:	fe040593          	addi	a1,s0,-32
    8000626e:	4505                	li	a0,1
    80006270:	ffffd097          	auipc	ra,0xffffd
    80006274:	cee080e7          	jalr	-786(ra) # 80002f5e <argaddr>
        return -1;
    80006278:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argaddr(1, &length) < 0)
    8000627a:	00054b63          	bltz	a0,80006290 <sys_munmap+0x42>
  return munmap(addr, length);
    8000627e:	fe043583          	ld	a1,-32(s0)
    80006282:	fe843503          	ld	a0,-24(s0)
    80006286:	00000097          	auipc	ra,0x0
    8000628a:	e74080e7          	jalr	-396(ra) # 800060fa <munmap>
    8000628e:	87aa                	mv	a5,a0
  // return 0;
    80006290:	853e                	mv	a0,a5
    80006292:	60e2                	ld	ra,24(sp)
    80006294:	6442                	ld	s0,16(sp)
    80006296:	6105                	addi	sp,sp,32
    80006298:	8082                	ret
    8000629a:	0000                	unimp
    8000629c:	0000                	unimp
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	a7bfc0ef          	jal	ra,80002d5a <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffb097          	auipc	ra,0xffffb
    8000637c:	69a080e7          	jalr	1690(ra) # 80001a12 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	97aa                	add	a5,a5,a0
    8000639c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	662080e7          	jalr	1634(ra) # 80001a12 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5151b          	slliw	a0,a0,0xd
    800063bc:	0c2017b7          	lui	a5,0xc201
    800063c0:	97aa                	add	a5,a5,a0
  return irq;
}
    800063c2:	43c8                	lw	a0,4(a5)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffb097          	auipc	ra,0xffffb
    800063dc:	63a080e7          	jalr	1594(ra) # 80001a12 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	06a7c863          	blt	a5,a0,80006470 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	0002d717          	auipc	a4,0x2d
    80006408:	bfc70713          	addi	a4,a4,-1028 # 80033000 <disk>
    8000640c:	972a                	add	a4,a4,a0
    8000640e:	6789                	lui	a5,0x2
    80006410:	97ba                	add	a5,a5,a4
    80006412:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006416:	e7ad                	bnez	a5,80006480 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006418:	00451793          	slli	a5,a0,0x4
    8000641c:	0002f717          	auipc	a4,0x2f
    80006420:	be470713          	addi	a4,a4,-1052 # 80035000 <disk+0x2000>
    80006424:	6314                	ld	a3,0(a4)
    80006426:	96be                	add	a3,a3,a5
    80006428:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000642c:	6314                	ld	a3,0(a4)
    8000642e:	96be                	add	a3,a3,a5
    80006430:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006434:	6314                	ld	a3,0(a4)
    80006436:	96be                	add	a3,a3,a5
    80006438:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000643c:	6318                	ld	a4,0(a4)
    8000643e:	97ba                	add	a5,a5,a4
    80006440:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006444:	0002d717          	auipc	a4,0x2d
    80006448:	bbc70713          	addi	a4,a4,-1092 # 80033000 <disk>
    8000644c:	972a                	add	a4,a4,a0
    8000644e:	6789                	lui	a5,0x2
    80006450:	97ba                	add	a5,a5,a4
    80006452:	4705                	li	a4,1
    80006454:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006458:	0002f517          	auipc	a0,0x2f
    8000645c:	bc050513          	addi	a0,a0,-1088 # 80035018 <disk+0x2018>
    80006460:	ffffc097          	auipc	ra,0xffffc
    80006464:	eb0080e7          	jalr	-336(ra) # 80002310 <wakeup>
}
    80006468:	60a2                	ld	ra,8(sp)
    8000646a:	6402                	ld	s0,0(sp)
    8000646c:	0141                	addi	sp,sp,16
    8000646e:	8082                	ret
    panic("free_desc 1");
    80006470:	00002517          	auipc	a0,0x2
    80006474:	31850513          	addi	a0,a0,792 # 80008788 <syscalls+0x340>
    80006478:	ffffa097          	auipc	ra,0xffffa
    8000647c:	0c4080e7          	jalr	196(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006480:	00002517          	auipc	a0,0x2
    80006484:	31850513          	addi	a0,a0,792 # 80008798 <syscalls+0x350>
    80006488:	ffffa097          	auipc	ra,0xffffa
    8000648c:	0b4080e7          	jalr	180(ra) # 8000053c <panic>

0000000080006490 <virtio_disk_init>:
{
    80006490:	1101                	addi	sp,sp,-32
    80006492:	ec06                	sd	ra,24(sp)
    80006494:	e822                	sd	s0,16(sp)
    80006496:	e426                	sd	s1,8(sp)
    80006498:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000649a:	00002597          	auipc	a1,0x2
    8000649e:	30e58593          	addi	a1,a1,782 # 800087a8 <syscalls+0x360>
    800064a2:	0002f517          	auipc	a0,0x2f
    800064a6:	c8650513          	addi	a0,a0,-890 # 80035128 <disk+0x2128>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	6e2080e7          	jalr	1762(ra) # 80000b8c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b2:	100017b7          	lui	a5,0x10001
    800064b6:	4398                	lw	a4,0(a5)
    800064b8:	2701                	sext.w	a4,a4
    800064ba:	747277b7          	lui	a5,0x74727
    800064be:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064c2:	0ef71063          	bne	a4,a5,800065a2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064c6:	100017b7          	lui	a5,0x10001
    800064ca:	43dc                	lw	a5,4(a5)
    800064cc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064ce:	4705                	li	a4,1
    800064d0:	0ce79963          	bne	a5,a4,800065a2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d4:	100017b7          	lui	a5,0x10001
    800064d8:	479c                	lw	a5,8(a5)
    800064da:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064dc:	4709                	li	a4,2
    800064de:	0ce79263          	bne	a5,a4,800065a2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064e2:	100017b7          	lui	a5,0x10001
    800064e6:	47d8                	lw	a4,12(a5)
    800064e8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ea:	554d47b7          	lui	a5,0x554d4
    800064ee:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064f2:	0af71863          	bne	a4,a5,800065a2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f6:	100017b7          	lui	a5,0x10001
    800064fa:	4705                	li	a4,1
    800064fc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064fe:	470d                	li	a4,3
    80006500:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006502:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006504:	c7ffe6b7          	lui	a3,0xc7ffe
    80006508:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fc875f>
    8000650c:	8f75                	and	a4,a4,a3
    8000650e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006510:	472d                	li	a4,11
    80006512:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006514:	473d                	li	a4,15
    80006516:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006518:	6705                	lui	a4,0x1
    8000651a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000651c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006520:	5bdc                	lw	a5,52(a5)
    80006522:	2781                	sext.w	a5,a5
  if(max == 0)
    80006524:	c7d9                	beqz	a5,800065b2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006526:	471d                	li	a4,7
    80006528:	08f77d63          	bgeu	a4,a5,800065c2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000652c:	100014b7          	lui	s1,0x10001
    80006530:	47a1                	li	a5,8
    80006532:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006534:	6609                	lui	a2,0x2
    80006536:	4581                	li	a1,0
    80006538:	0002d517          	auipc	a0,0x2d
    8000653c:	ac850513          	addi	a0,a0,-1336 # 80033000 <disk>
    80006540:	ffffa097          	auipc	ra,0xffffa
    80006544:	7d8080e7          	jalr	2008(ra) # 80000d18 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006548:	0002d717          	auipc	a4,0x2d
    8000654c:	ab870713          	addi	a4,a4,-1352 # 80033000 <disk>
    80006550:	00c75793          	srli	a5,a4,0xc
    80006554:	2781                	sext.w	a5,a5
    80006556:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006558:	0002f797          	auipc	a5,0x2f
    8000655c:	aa878793          	addi	a5,a5,-1368 # 80035000 <disk+0x2000>
    80006560:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006562:	0002d717          	auipc	a4,0x2d
    80006566:	b1e70713          	addi	a4,a4,-1250 # 80033080 <disk+0x80>
    8000656a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000656c:	0002e717          	auipc	a4,0x2e
    80006570:	a9470713          	addi	a4,a4,-1388 # 80034000 <disk+0x1000>
    80006574:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006576:	4705                	li	a4,1
    80006578:	00e78c23          	sb	a4,24(a5)
    8000657c:	00e78ca3          	sb	a4,25(a5)
    80006580:	00e78d23          	sb	a4,26(a5)
    80006584:	00e78da3          	sb	a4,27(a5)
    80006588:	00e78e23          	sb	a4,28(a5)
    8000658c:	00e78ea3          	sb	a4,29(a5)
    80006590:	00e78f23          	sb	a4,30(a5)
    80006594:	00e78fa3          	sb	a4,31(a5)
}
    80006598:	60e2                	ld	ra,24(sp)
    8000659a:	6442                	ld	s0,16(sp)
    8000659c:	64a2                	ld	s1,8(sp)
    8000659e:	6105                	addi	sp,sp,32
    800065a0:	8082                	ret
    panic("could not find virtio disk");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	21650513          	addi	a0,a0,534 # 800087b8 <syscalls+0x370>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f92080e7          	jalr	-110(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	22650513          	addi	a0,a0,550 # 800087d8 <syscalls+0x390>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f82080e7          	jalr	-126(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	23650513          	addi	a0,a0,566 # 800087f8 <syscalls+0x3b0>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f72080e7          	jalr	-142(ra) # 8000053c <panic>

00000000800065d2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065d2:	7119                	addi	sp,sp,-128
    800065d4:	fc86                	sd	ra,120(sp)
    800065d6:	f8a2                	sd	s0,112(sp)
    800065d8:	f4a6                	sd	s1,104(sp)
    800065da:	f0ca                	sd	s2,96(sp)
    800065dc:	ecce                	sd	s3,88(sp)
    800065de:	e8d2                	sd	s4,80(sp)
    800065e0:	e4d6                	sd	s5,72(sp)
    800065e2:	e0da                	sd	s6,64(sp)
    800065e4:	fc5e                	sd	s7,56(sp)
    800065e6:	f862                	sd	s8,48(sp)
    800065e8:	f466                	sd	s9,40(sp)
    800065ea:	f06a                	sd	s10,32(sp)
    800065ec:	ec6e                	sd	s11,24(sp)
    800065ee:	0100                	addi	s0,sp,128
    800065f0:	8aaa                	mv	s5,a0
    800065f2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065f4:	00c52c83          	lw	s9,12(a0)
    800065f8:	001c9c9b          	slliw	s9,s9,0x1
    800065fc:	1c82                	slli	s9,s9,0x20
    800065fe:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006602:	0002f517          	auipc	a0,0x2f
    80006606:	b2650513          	addi	a0,a0,-1242 # 80035128 <disk+0x2128>
    8000660a:	ffffa097          	auipc	ra,0xffffa
    8000660e:	612080e7          	jalr	1554(ra) # 80000c1c <acquire>
  for(int i = 0; i < 3; i++){
    80006612:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006614:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006616:	0002dc17          	auipc	s8,0x2d
    8000661a:	9eac0c13          	addi	s8,s8,-1558 # 80033000 <disk>
    8000661e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006620:	4b0d                	li	s6,3
    80006622:	a0ad                	j	8000668c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006624:	00fc0733          	add	a4,s8,a5
    80006628:	975e                	add	a4,a4,s7
    8000662a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000662e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006630:	0207c563          	bltz	a5,8000665a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006634:	2905                	addiw	s2,s2,1
    80006636:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006638:	19690c63          	beq	s2,s6,800067d0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000663c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000663e:	0002f717          	auipc	a4,0x2f
    80006642:	9da70713          	addi	a4,a4,-1574 # 80035018 <disk+0x2018>
    80006646:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006648:	00074683          	lbu	a3,0(a4)
    8000664c:	fee1                	bnez	a3,80006624 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000664e:	2785                	addiw	a5,a5,1
    80006650:	0705                	addi	a4,a4,1
    80006652:	fe979be3          	bne	a5,s1,80006648 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006656:	57fd                	li	a5,-1
    80006658:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000665a:	01205d63          	blez	s2,80006674 <virtio_disk_rw+0xa2>
    8000665e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006660:	000a2503          	lw	a0,0(s4)
    80006664:	00000097          	auipc	ra,0x0
    80006668:	d92080e7          	jalr	-622(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000666c:	2d85                	addiw	s11,s11,1
    8000666e:	0a11                	addi	s4,s4,4
    80006670:	ff2d98e3          	bne	s11,s2,80006660 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006674:	0002f597          	auipc	a1,0x2f
    80006678:	ab458593          	addi	a1,a1,-1356 # 80035128 <disk+0x2128>
    8000667c:	0002f517          	auipc	a0,0x2f
    80006680:	99c50513          	addi	a0,a0,-1636 # 80035018 <disk+0x2018>
    80006684:	ffffc097          	auipc	ra,0xffffc
    80006688:	ae8080e7          	jalr	-1304(ra) # 8000216c <sleep>
  for(int i = 0; i < 3; i++){
    8000668c:	f8040a13          	addi	s4,s0,-128
{
    80006690:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006692:	894e                	mv	s2,s3
    80006694:	b765                	j	8000663c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006696:	0002f697          	auipc	a3,0x2f
    8000669a:	96a6b683          	ld	a3,-1686(a3) # 80035000 <disk+0x2000>
    8000669e:	96ba                	add	a3,a3,a4
    800066a0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066a4:	0002d817          	auipc	a6,0x2d
    800066a8:	95c80813          	addi	a6,a6,-1700 # 80033000 <disk>
    800066ac:	0002f697          	auipc	a3,0x2f
    800066b0:	95468693          	addi	a3,a3,-1708 # 80035000 <disk+0x2000>
    800066b4:	6290                	ld	a2,0(a3)
    800066b6:	963a                	add	a2,a2,a4
    800066b8:	00c65583          	lhu	a1,12(a2)
    800066bc:	0015e593          	ori	a1,a1,1
    800066c0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800066c4:	f8842603          	lw	a2,-120(s0)
    800066c8:	628c                	ld	a1,0(a3)
    800066ca:	972e                	add	a4,a4,a1
    800066cc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066d0:	20050593          	addi	a1,a0,512
    800066d4:	0592                	slli	a1,a1,0x4
    800066d6:	95c2                	add	a1,a1,a6
    800066d8:	577d                	li	a4,-1
    800066da:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066de:	00461713          	slli	a4,a2,0x4
    800066e2:	6290                	ld	a2,0(a3)
    800066e4:	963a                	add	a2,a2,a4
    800066e6:	03078793          	addi	a5,a5,48
    800066ea:	97c2                	add	a5,a5,a6
    800066ec:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800066ee:	629c                	ld	a5,0(a3)
    800066f0:	97ba                	add	a5,a5,a4
    800066f2:	4605                	li	a2,1
    800066f4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066f6:	629c                	ld	a5,0(a3)
    800066f8:	97ba                	add	a5,a5,a4
    800066fa:	4809                	li	a6,2
    800066fc:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006700:	629c                	ld	a5,0(a3)
    80006702:	97ba                	add	a5,a5,a4
    80006704:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006708:	00caa223          	sw	a2,4(s5) # 1004 <_entry-0x7fffeffc>
  disk.info[idx[0]].b = b;
    8000670c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006710:	6698                	ld	a4,8(a3)
    80006712:	00275783          	lhu	a5,2(a4)
    80006716:	8b9d                	andi	a5,a5,7
    80006718:	0786                	slli	a5,a5,0x1
    8000671a:	973e                	add	a4,a4,a5
    8000671c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006720:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006724:	6698                	ld	a4,8(a3)
    80006726:	00275783          	lhu	a5,2(a4)
    8000672a:	2785                	addiw	a5,a5,1
    8000672c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006730:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006734:	100017b7          	lui	a5,0x10001
    80006738:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000673c:	004aa783          	lw	a5,4(s5)
    80006740:	02c79163          	bne	a5,a2,80006762 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006744:	0002f917          	auipc	s2,0x2f
    80006748:	9e490913          	addi	s2,s2,-1564 # 80035128 <disk+0x2128>
  while(b->disk == 1) {
    8000674c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000674e:	85ca                	mv	a1,s2
    80006750:	8556                	mv	a0,s5
    80006752:	ffffc097          	auipc	ra,0xffffc
    80006756:	a1a080e7          	jalr	-1510(ra) # 8000216c <sleep>
  while(b->disk == 1) {
    8000675a:	004aa783          	lw	a5,4(s5)
    8000675e:	fe9788e3          	beq	a5,s1,8000674e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006762:	f8042903          	lw	s2,-128(s0)
    80006766:	20090713          	addi	a4,s2,512
    8000676a:	0712                	slli	a4,a4,0x4
    8000676c:	0002d797          	auipc	a5,0x2d
    80006770:	89478793          	addi	a5,a5,-1900 # 80033000 <disk>
    80006774:	97ba                	add	a5,a5,a4
    80006776:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000677a:	0002f997          	auipc	s3,0x2f
    8000677e:	88698993          	addi	s3,s3,-1914 # 80035000 <disk+0x2000>
    80006782:	00491713          	slli	a4,s2,0x4
    80006786:	0009b783          	ld	a5,0(s3)
    8000678a:	97ba                	add	a5,a5,a4
    8000678c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006790:	854a                	mv	a0,s2
    80006792:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006796:	00000097          	auipc	ra,0x0
    8000679a:	c60080e7          	jalr	-928(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000679e:	8885                	andi	s1,s1,1
    800067a0:	f0ed                	bnez	s1,80006782 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067a2:	0002f517          	auipc	a0,0x2f
    800067a6:	98650513          	addi	a0,a0,-1658 # 80035128 <disk+0x2128>
    800067aa:	ffffa097          	auipc	ra,0xffffa
    800067ae:	526080e7          	jalr	1318(ra) # 80000cd0 <release>
}
    800067b2:	70e6                	ld	ra,120(sp)
    800067b4:	7446                	ld	s0,112(sp)
    800067b6:	74a6                	ld	s1,104(sp)
    800067b8:	7906                	ld	s2,96(sp)
    800067ba:	69e6                	ld	s3,88(sp)
    800067bc:	6a46                	ld	s4,80(sp)
    800067be:	6aa6                	ld	s5,72(sp)
    800067c0:	6b06                	ld	s6,64(sp)
    800067c2:	7be2                	ld	s7,56(sp)
    800067c4:	7c42                	ld	s8,48(sp)
    800067c6:	7ca2                	ld	s9,40(sp)
    800067c8:	7d02                	ld	s10,32(sp)
    800067ca:	6de2                	ld	s11,24(sp)
    800067cc:	6109                	addi	sp,sp,128
    800067ce:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067d0:	f8042503          	lw	a0,-128(s0)
    800067d4:	20050793          	addi	a5,a0,512
    800067d8:	0792                	slli	a5,a5,0x4
  if(write)
    800067da:	0002d817          	auipc	a6,0x2d
    800067de:	82680813          	addi	a6,a6,-2010 # 80033000 <disk>
    800067e2:	00f80733          	add	a4,a6,a5
    800067e6:	01a036b3          	snez	a3,s10
    800067ea:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800067ee:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800067f2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800067f6:	7679                	lui	a2,0xffffe
    800067f8:	963e                	add	a2,a2,a5
    800067fa:	0002f697          	auipc	a3,0x2f
    800067fe:	80668693          	addi	a3,a3,-2042 # 80035000 <disk+0x2000>
    80006802:	6298                	ld	a4,0(a3)
    80006804:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006806:	0a878593          	addi	a1,a5,168
    8000680a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000680c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000680e:	6298                	ld	a4,0(a3)
    80006810:	9732                	add	a4,a4,a2
    80006812:	45c1                	li	a1,16
    80006814:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006816:	6298                	ld	a4,0(a3)
    80006818:	9732                	add	a4,a4,a2
    8000681a:	4585                	li	a1,1
    8000681c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006820:	f8442703          	lw	a4,-124(s0)
    80006824:	628c                	ld	a1,0(a3)
    80006826:	962e                	add	a2,a2,a1
    80006828:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffc800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000682c:	0712                	slli	a4,a4,0x4
    8000682e:	6290                	ld	a2,0(a3)
    80006830:	963a                	add	a2,a2,a4
    80006832:	058a8593          	addi	a1,s5,88
    80006836:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006838:	6294                	ld	a3,0(a3)
    8000683a:	96ba                	add	a3,a3,a4
    8000683c:	40000613          	li	a2,1024
    80006840:	c690                	sw	a2,8(a3)
  if(write)
    80006842:	e40d1ae3          	bnez	s10,80006696 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006846:	0002e697          	auipc	a3,0x2e
    8000684a:	7ba6b683          	ld	a3,1978(a3) # 80035000 <disk+0x2000>
    8000684e:	96ba                	add	a3,a3,a4
    80006850:	4609                	li	a2,2
    80006852:	00c69623          	sh	a2,12(a3)
    80006856:	b5b9                	j	800066a4 <virtio_disk_rw+0xd2>

0000000080006858 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006858:	1101                	addi	sp,sp,-32
    8000685a:	ec06                	sd	ra,24(sp)
    8000685c:	e822                	sd	s0,16(sp)
    8000685e:	e426                	sd	s1,8(sp)
    80006860:	e04a                	sd	s2,0(sp)
    80006862:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006864:	0002f517          	auipc	a0,0x2f
    80006868:	8c450513          	addi	a0,a0,-1852 # 80035128 <disk+0x2128>
    8000686c:	ffffa097          	auipc	ra,0xffffa
    80006870:	3b0080e7          	jalr	944(ra) # 80000c1c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006874:	10001737          	lui	a4,0x10001
    80006878:	533c                	lw	a5,96(a4)
    8000687a:	8b8d                	andi	a5,a5,3
    8000687c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000687e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006882:	0002e797          	auipc	a5,0x2e
    80006886:	77e78793          	addi	a5,a5,1918 # 80035000 <disk+0x2000>
    8000688a:	6b94                	ld	a3,16(a5)
    8000688c:	0207d703          	lhu	a4,32(a5)
    80006890:	0026d783          	lhu	a5,2(a3)
    80006894:	06f70163          	beq	a4,a5,800068f6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006898:	0002c917          	auipc	s2,0x2c
    8000689c:	76890913          	addi	s2,s2,1896 # 80033000 <disk>
    800068a0:	0002e497          	auipc	s1,0x2e
    800068a4:	76048493          	addi	s1,s1,1888 # 80035000 <disk+0x2000>
    __sync_synchronize();
    800068a8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ac:	6898                	ld	a4,16(s1)
    800068ae:	0204d783          	lhu	a5,32(s1)
    800068b2:	8b9d                	andi	a5,a5,7
    800068b4:	078e                	slli	a5,a5,0x3
    800068b6:	97ba                	add	a5,a5,a4
    800068b8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068ba:	20078713          	addi	a4,a5,512
    800068be:	0712                	slli	a4,a4,0x4
    800068c0:	974a                	add	a4,a4,s2
    800068c2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800068c6:	e731                	bnez	a4,80006912 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068c8:	20078793          	addi	a5,a5,512
    800068cc:	0792                	slli	a5,a5,0x4
    800068ce:	97ca                	add	a5,a5,s2
    800068d0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800068d2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068d6:	ffffc097          	auipc	ra,0xffffc
    800068da:	a3a080e7          	jalr	-1478(ra) # 80002310 <wakeup>

    disk.used_idx += 1;
    800068de:	0204d783          	lhu	a5,32(s1)
    800068e2:	2785                	addiw	a5,a5,1
    800068e4:	17c2                	slli	a5,a5,0x30
    800068e6:	93c1                	srli	a5,a5,0x30
    800068e8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068ec:	6898                	ld	a4,16(s1)
    800068ee:	00275703          	lhu	a4,2(a4)
    800068f2:	faf71be3          	bne	a4,a5,800068a8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800068f6:	0002f517          	auipc	a0,0x2f
    800068fa:	83250513          	addi	a0,a0,-1998 # 80035128 <disk+0x2128>
    800068fe:	ffffa097          	auipc	ra,0xffffa
    80006902:	3d2080e7          	jalr	978(ra) # 80000cd0 <release>
}
    80006906:	60e2                	ld	ra,24(sp)
    80006908:	6442                	ld	s0,16(sp)
    8000690a:	64a2                	ld	s1,8(sp)
    8000690c:	6902                	ld	s2,0(sp)
    8000690e:	6105                	addi	sp,sp,32
    80006910:	8082                	ret
      panic("virtio_disk_intr status");
    80006912:	00002517          	auipc	a0,0x2
    80006916:	f0650513          	addi	a0,a0,-250 # 80008818 <syscalls+0x3d0>
    8000691a:	ffffa097          	auipc	ra,0xffffa
    8000691e:	c22080e7          	jalr	-990(ra) # 8000053c <panic>
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
