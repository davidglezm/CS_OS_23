
user/_free:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
    uint64 divisor = 1;

    if (argc == 2) {
   a:	4789                	li	a5,2
    uint64 divisor = 1;
   c:	4485                	li	s1,1
    if (argc == 2) {
   e:	02f50563          	beq	a0,a5,38 <main+0x38>
	    divisor = 1024*1024;
	    break;
	}
    }

    printf("%l\n", freepmem()/divisor);
  12:	00000097          	auipc	ra,0x0
  16:	35c080e7          	jalr	860(ra) # 36e <freepmem>
  1a:	029555b3          	divu	a1,a0,s1
  1e:	00000517          	auipc	a0,0x0
  22:	7e250513          	addi	a0,a0,2018 # 800 <malloc+0xe8>
  26:	00000097          	auipc	ra,0x0
  2a:	63a080e7          	jalr	1594(ra) # 660 <printf>

    exit(0);
  2e:	4501                	li	a0,0
  30:	00000097          	auipc	ra,0x0
  34:	296080e7          	jalr	662(ra) # 2c6 <exit>
        switch (argv[1][1]) {
  38:	659c                	ld	a5,8(a1)
  3a:	0017c783          	lbu	a5,1(a5)
  3e:	06b00713          	li	a4,107
  42:	00e78963          	beq	a5,a4,54 <main+0x54>
  46:	06d00713          	li	a4,109
  4a:	fce794e3          	bne	a5,a4,12 <main+0x12>
	    divisor = 1024*1024;
  4e:	001004b7          	lui	s1,0x100
  52:	b7c1                	j	12 <main+0x12>
        switch (argv[1][1]) {
  54:	40000493          	li	s1,1024
  58:	bf6d                	j	12 <main+0x12>

000000000000005a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  5a:	1141                	addi	sp,sp,-16
  5c:	e422                	sd	s0,8(sp)
  5e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  60:	87aa                	mv	a5,a0
  62:	0585                	addi	a1,a1,1
  64:	0785                	addi	a5,a5,1
  66:	fff5c703          	lbu	a4,-1(a1)
  6a:	fee78fa3          	sb	a4,-1(a5)
  6e:	fb75                	bnez	a4,62 <strcpy+0x8>
    ;
  return os;
}
  70:	6422                	ld	s0,8(sp)
  72:	0141                	addi	sp,sp,16
  74:	8082                	ret

0000000000000076 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  76:	1141                	addi	sp,sp,-16
  78:	e422                	sd	s0,8(sp)
  7a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  7c:	00054783          	lbu	a5,0(a0)
  80:	cb91                	beqz	a5,94 <strcmp+0x1e>
  82:	0005c703          	lbu	a4,0(a1)
  86:	00f71763          	bne	a4,a5,94 <strcmp+0x1e>
    p++, q++;
  8a:	0505                	addi	a0,a0,1
  8c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  8e:	00054783          	lbu	a5,0(a0)
  92:	fbe5                	bnez	a5,82 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  94:	0005c503          	lbu	a0,0(a1)
}
  98:	40a7853b          	subw	a0,a5,a0
  9c:	6422                	ld	s0,8(sp)
  9e:	0141                	addi	sp,sp,16
  a0:	8082                	ret

00000000000000a2 <strlen>:

uint
strlen(const char *s)
{
  a2:	1141                	addi	sp,sp,-16
  a4:	e422                	sd	s0,8(sp)
  a6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  a8:	00054783          	lbu	a5,0(a0)
  ac:	cf91                	beqz	a5,c8 <strlen+0x26>
  ae:	0505                	addi	a0,a0,1
  b0:	87aa                	mv	a5,a0
  b2:	4685                	li	a3,1
  b4:	9e89                	subw	a3,a3,a0
  b6:	00f6853b          	addw	a0,a3,a5
  ba:	0785                	addi	a5,a5,1
  bc:	fff7c703          	lbu	a4,-1(a5)
  c0:	fb7d                	bnez	a4,b6 <strlen+0x14>
    ;
  return n;
}
  c2:	6422                	ld	s0,8(sp)
  c4:	0141                	addi	sp,sp,16
  c6:	8082                	ret
  for(n = 0; s[n]; n++)
  c8:	4501                	li	a0,0
  ca:	bfe5                	j	c2 <strlen+0x20>

00000000000000cc <memset>:

void*
memset(void *dst, int c, uint n)
{
  cc:	1141                	addi	sp,sp,-16
  ce:	e422                	sd	s0,8(sp)
  d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  d2:	ca19                	beqz	a2,e8 <memset+0x1c>
  d4:	87aa                	mv	a5,a0
  d6:	1602                	slli	a2,a2,0x20
  d8:	9201                	srli	a2,a2,0x20
  da:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  de:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  e2:	0785                	addi	a5,a5,1
  e4:	fee79de3          	bne	a5,a4,de <memset+0x12>
  }
  return dst;
}
  e8:	6422                	ld	s0,8(sp)
  ea:	0141                	addi	sp,sp,16
  ec:	8082                	ret

00000000000000ee <strchr>:

char*
strchr(const char *s, char c)
{
  ee:	1141                	addi	sp,sp,-16
  f0:	e422                	sd	s0,8(sp)
  f2:	0800                	addi	s0,sp,16
  for(; *s; s++)
  f4:	00054783          	lbu	a5,0(a0)
  f8:	cb99                	beqz	a5,10e <strchr+0x20>
    if(*s == c)
  fa:	00f58763          	beq	a1,a5,108 <strchr+0x1a>
  for(; *s; s++)
  fe:	0505                	addi	a0,a0,1
 100:	00054783          	lbu	a5,0(a0)
 104:	fbfd                	bnez	a5,fa <strchr+0xc>
      return (char*)s;
  return 0;
 106:	4501                	li	a0,0
}
 108:	6422                	ld	s0,8(sp)
 10a:	0141                	addi	sp,sp,16
 10c:	8082                	ret
  return 0;
 10e:	4501                	li	a0,0
 110:	bfe5                	j	108 <strchr+0x1a>

0000000000000112 <gets>:

char*
gets(char *buf, int max)
{
 112:	711d                	addi	sp,sp,-96
 114:	ec86                	sd	ra,88(sp)
 116:	e8a2                	sd	s0,80(sp)
 118:	e4a6                	sd	s1,72(sp)
 11a:	e0ca                	sd	s2,64(sp)
 11c:	fc4e                	sd	s3,56(sp)
 11e:	f852                	sd	s4,48(sp)
 120:	f456                	sd	s5,40(sp)
 122:	f05a                	sd	s6,32(sp)
 124:	ec5e                	sd	s7,24(sp)
 126:	1080                	addi	s0,sp,96
 128:	8baa                	mv	s7,a0
 12a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 12c:	892a                	mv	s2,a0
 12e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 130:	4aa9                	li	s5,10
 132:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 134:	89a6                	mv	s3,s1
 136:	2485                	addiw	s1,s1,1 # 100001 <__global_pointer$+0xfef88>
 138:	0344d863          	bge	s1,s4,168 <gets+0x56>
    cc = read(0, &c, 1);
 13c:	4605                	li	a2,1
 13e:	faf40593          	addi	a1,s0,-81
 142:	4501                	li	a0,0
 144:	00000097          	auipc	ra,0x0
 148:	19a080e7          	jalr	410(ra) # 2de <read>
    if(cc < 1)
 14c:	00a05e63          	blez	a0,168 <gets+0x56>
    buf[i++] = c;
 150:	faf44783          	lbu	a5,-81(s0)
 154:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 158:	01578763          	beq	a5,s5,166 <gets+0x54>
 15c:	0905                	addi	s2,s2,1
 15e:	fd679be3          	bne	a5,s6,134 <gets+0x22>
  for(i=0; i+1 < max; ){
 162:	89a6                	mv	s3,s1
 164:	a011                	j	168 <gets+0x56>
 166:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 168:	99de                	add	s3,s3,s7
 16a:	00098023          	sb	zero,0(s3)
  return buf;
}
 16e:	855e                	mv	a0,s7
 170:	60e6                	ld	ra,88(sp)
 172:	6446                	ld	s0,80(sp)
 174:	64a6                	ld	s1,72(sp)
 176:	6906                	ld	s2,64(sp)
 178:	79e2                	ld	s3,56(sp)
 17a:	7a42                	ld	s4,48(sp)
 17c:	7aa2                	ld	s5,40(sp)
 17e:	7b02                	ld	s6,32(sp)
 180:	6be2                	ld	s7,24(sp)
 182:	6125                	addi	sp,sp,96
 184:	8082                	ret

0000000000000186 <stat>:

int
stat(const char *n, struct stat *st)
{
 186:	1101                	addi	sp,sp,-32
 188:	ec06                	sd	ra,24(sp)
 18a:	e822                	sd	s0,16(sp)
 18c:	e426                	sd	s1,8(sp)
 18e:	e04a                	sd	s2,0(sp)
 190:	1000                	addi	s0,sp,32
 192:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 194:	4581                	li	a1,0
 196:	00000097          	auipc	ra,0x0
 19a:	170080e7          	jalr	368(ra) # 306 <open>
  if(fd < 0)
 19e:	02054563          	bltz	a0,1c8 <stat+0x42>
 1a2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a4:	85ca                	mv	a1,s2
 1a6:	00000097          	auipc	ra,0x0
 1aa:	178080e7          	jalr	376(ra) # 31e <fstat>
 1ae:	892a                	mv	s2,a0
  close(fd);
 1b0:	8526                	mv	a0,s1
 1b2:	00000097          	auipc	ra,0x0
 1b6:	13c080e7          	jalr	316(ra) # 2ee <close>
  return r;
}
 1ba:	854a                	mv	a0,s2
 1bc:	60e2                	ld	ra,24(sp)
 1be:	6442                	ld	s0,16(sp)
 1c0:	64a2                	ld	s1,8(sp)
 1c2:	6902                	ld	s2,0(sp)
 1c4:	6105                	addi	sp,sp,32
 1c6:	8082                	ret
    return -1;
 1c8:	597d                	li	s2,-1
 1ca:	bfc5                	j	1ba <stat+0x34>

00000000000001cc <atoi>:

int
atoi(const char *s)
{
 1cc:	1141                	addi	sp,sp,-16
 1ce:	e422                	sd	s0,8(sp)
 1d0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1d2:	00054683          	lbu	a3,0(a0)
 1d6:	fd06879b          	addiw	a5,a3,-48
 1da:	0ff7f793          	zext.b	a5,a5
 1de:	4625                	li	a2,9
 1e0:	02f66863          	bltu	a2,a5,210 <atoi+0x44>
 1e4:	872a                	mv	a4,a0
  n = 0;
 1e6:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1e8:	0705                	addi	a4,a4,1
 1ea:	0025179b          	slliw	a5,a0,0x2
 1ee:	9fa9                	addw	a5,a5,a0
 1f0:	0017979b          	slliw	a5,a5,0x1
 1f4:	9fb5                	addw	a5,a5,a3
 1f6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1fa:	00074683          	lbu	a3,0(a4)
 1fe:	fd06879b          	addiw	a5,a3,-48
 202:	0ff7f793          	zext.b	a5,a5
 206:	fef671e3          	bgeu	a2,a5,1e8 <atoi+0x1c>
  return n;
}
 20a:	6422                	ld	s0,8(sp)
 20c:	0141                	addi	sp,sp,16
 20e:	8082                	ret
  n = 0;
 210:	4501                	li	a0,0
 212:	bfe5                	j	20a <atoi+0x3e>

0000000000000214 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 214:	1141                	addi	sp,sp,-16
 216:	e422                	sd	s0,8(sp)
 218:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 21a:	02b57463          	bgeu	a0,a1,242 <memmove+0x2e>
    while(n-- > 0)
 21e:	00c05f63          	blez	a2,23c <memmove+0x28>
 222:	1602                	slli	a2,a2,0x20
 224:	9201                	srli	a2,a2,0x20
 226:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 22a:	872a                	mv	a4,a0
      *dst++ = *src++;
 22c:	0585                	addi	a1,a1,1
 22e:	0705                	addi	a4,a4,1
 230:	fff5c683          	lbu	a3,-1(a1)
 234:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 238:	fee79ae3          	bne	a5,a4,22c <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 23c:	6422                	ld	s0,8(sp)
 23e:	0141                	addi	sp,sp,16
 240:	8082                	ret
    dst += n;
 242:	00c50733          	add	a4,a0,a2
    src += n;
 246:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 248:	fec05ae3          	blez	a2,23c <memmove+0x28>
 24c:	fff6079b          	addiw	a5,a2,-1
 250:	1782                	slli	a5,a5,0x20
 252:	9381                	srli	a5,a5,0x20
 254:	fff7c793          	not	a5,a5
 258:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 25a:	15fd                	addi	a1,a1,-1
 25c:	177d                	addi	a4,a4,-1
 25e:	0005c683          	lbu	a3,0(a1)
 262:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 266:	fee79ae3          	bne	a5,a4,25a <memmove+0x46>
 26a:	bfc9                	j	23c <memmove+0x28>

000000000000026c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 26c:	1141                	addi	sp,sp,-16
 26e:	e422                	sd	s0,8(sp)
 270:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 272:	ca05                	beqz	a2,2a2 <memcmp+0x36>
 274:	fff6069b          	addiw	a3,a2,-1
 278:	1682                	slli	a3,a3,0x20
 27a:	9281                	srli	a3,a3,0x20
 27c:	0685                	addi	a3,a3,1
 27e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 280:	00054783          	lbu	a5,0(a0)
 284:	0005c703          	lbu	a4,0(a1)
 288:	00e79863          	bne	a5,a4,298 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 28c:	0505                	addi	a0,a0,1
    p2++;
 28e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 290:	fed518e3          	bne	a0,a3,280 <memcmp+0x14>
  }
  return 0;
 294:	4501                	li	a0,0
 296:	a019                	j	29c <memcmp+0x30>
      return *p1 - *p2;
 298:	40e7853b          	subw	a0,a5,a4
}
 29c:	6422                	ld	s0,8(sp)
 29e:	0141                	addi	sp,sp,16
 2a0:	8082                	ret
  return 0;
 2a2:	4501                	li	a0,0
 2a4:	bfe5                	j	29c <memcmp+0x30>

00000000000002a6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2a6:	1141                	addi	sp,sp,-16
 2a8:	e406                	sd	ra,8(sp)
 2aa:	e022                	sd	s0,0(sp)
 2ac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2ae:	00000097          	auipc	ra,0x0
 2b2:	f66080e7          	jalr	-154(ra) # 214 <memmove>
}
 2b6:	60a2                	ld	ra,8(sp)
 2b8:	6402                	ld	s0,0(sp)
 2ba:	0141                	addi	sp,sp,16
 2bc:	8082                	ret

00000000000002be <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2be:	4885                	li	a7,1
 ecall
 2c0:	00000073          	ecall
 ret
 2c4:	8082                	ret

00000000000002c6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2c6:	4889                	li	a7,2
 ecall
 2c8:	00000073          	ecall
 ret
 2cc:	8082                	ret

00000000000002ce <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ce:	488d                	li	a7,3
 ecall
 2d0:	00000073          	ecall
 ret
 2d4:	8082                	ret

00000000000002d6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2d6:	4891                	li	a7,4
 ecall
 2d8:	00000073          	ecall
 ret
 2dc:	8082                	ret

00000000000002de <read>:
.global read
read:
 li a7, SYS_read
 2de:	4895                	li	a7,5
 ecall
 2e0:	00000073          	ecall
 ret
 2e4:	8082                	ret

00000000000002e6 <write>:
.global write
write:
 li a7, SYS_write
 2e6:	48c1                	li	a7,16
 ecall
 2e8:	00000073          	ecall
 ret
 2ec:	8082                	ret

00000000000002ee <close>:
.global close
close:
 li a7, SYS_close
 2ee:	48d5                	li	a7,21
 ecall
 2f0:	00000073          	ecall
 ret
 2f4:	8082                	ret

00000000000002f6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2f6:	4899                	li	a7,6
 ecall
 2f8:	00000073          	ecall
 ret
 2fc:	8082                	ret

00000000000002fe <exec>:
.global exec
exec:
 li a7, SYS_exec
 2fe:	489d                	li	a7,7
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <open>:
.global open
open:
 li a7, SYS_open
 306:	48bd                	li	a7,15
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 30e:	48c5                	li	a7,17
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 316:	48c9                	li	a7,18
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 31e:	48a1                	li	a7,8
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <link>:
.global link
link:
 li a7, SYS_link
 326:	48cd                	li	a7,19
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 32e:	48d1                	li	a7,20
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 336:	48a5                	li	a7,9
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <dup>:
.global dup
dup:
 li a7, SYS_dup
 33e:	48a9                	li	a7,10
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 346:	48ad                	li	a7,11
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 34e:	48b1                	li	a7,12
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 356:	48b5                	li	a7,13
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 35e:	48b9                	li	a7,14
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 366:	48d9                	li	a7,22
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 36e:	48dd                	li	a7,23
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 376:	48e1                	li	a7,24
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 37e:	48e5                	li	a7,25
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 386:	1101                	addi	sp,sp,-32
 388:	ec06                	sd	ra,24(sp)
 38a:	e822                	sd	s0,16(sp)
 38c:	1000                	addi	s0,sp,32
 38e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 392:	4605                	li	a2,1
 394:	fef40593          	addi	a1,s0,-17
 398:	00000097          	auipc	ra,0x0
 39c:	f4e080e7          	jalr	-178(ra) # 2e6 <write>
}
 3a0:	60e2                	ld	ra,24(sp)
 3a2:	6442                	ld	s0,16(sp)
 3a4:	6105                	addi	sp,sp,32
 3a6:	8082                	ret

00000000000003a8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3a8:	7139                	addi	sp,sp,-64
 3aa:	fc06                	sd	ra,56(sp)
 3ac:	f822                	sd	s0,48(sp)
 3ae:	f426                	sd	s1,40(sp)
 3b0:	f04a                	sd	s2,32(sp)
 3b2:	ec4e                	sd	s3,24(sp)
 3b4:	0080                	addi	s0,sp,64
 3b6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3b8:	c299                	beqz	a3,3be <printint+0x16>
 3ba:	0805c963          	bltz	a1,44c <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3be:	2581                	sext.w	a1,a1
  neg = 0;
 3c0:	4881                	li	a7,0
 3c2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3c6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3c8:	2601                	sext.w	a2,a2
 3ca:	00000517          	auipc	a0,0x0
 3ce:	49e50513          	addi	a0,a0,1182 # 868 <digits>
 3d2:	883a                	mv	a6,a4
 3d4:	2705                	addiw	a4,a4,1
 3d6:	02c5f7bb          	remuw	a5,a1,a2
 3da:	1782                	slli	a5,a5,0x20
 3dc:	9381                	srli	a5,a5,0x20
 3de:	97aa                	add	a5,a5,a0
 3e0:	0007c783          	lbu	a5,0(a5)
 3e4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3e8:	0005879b          	sext.w	a5,a1
 3ec:	02c5d5bb          	divuw	a1,a1,a2
 3f0:	0685                	addi	a3,a3,1
 3f2:	fec7f0e3          	bgeu	a5,a2,3d2 <printint+0x2a>
  if(neg)
 3f6:	00088c63          	beqz	a7,40e <printint+0x66>
    buf[i++] = '-';
 3fa:	fd070793          	addi	a5,a4,-48
 3fe:	00878733          	add	a4,a5,s0
 402:	02d00793          	li	a5,45
 406:	fef70823          	sb	a5,-16(a4)
 40a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 40e:	02e05863          	blez	a4,43e <printint+0x96>
 412:	fc040793          	addi	a5,s0,-64
 416:	00e78933          	add	s2,a5,a4
 41a:	fff78993          	addi	s3,a5,-1
 41e:	99ba                	add	s3,s3,a4
 420:	377d                	addiw	a4,a4,-1
 422:	1702                	slli	a4,a4,0x20
 424:	9301                	srli	a4,a4,0x20
 426:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 42a:	fff94583          	lbu	a1,-1(s2)
 42e:	8526                	mv	a0,s1
 430:	00000097          	auipc	ra,0x0
 434:	f56080e7          	jalr	-170(ra) # 386 <putc>
  while(--i >= 0)
 438:	197d                	addi	s2,s2,-1
 43a:	ff3918e3          	bne	s2,s3,42a <printint+0x82>
}
 43e:	70e2                	ld	ra,56(sp)
 440:	7442                	ld	s0,48(sp)
 442:	74a2                	ld	s1,40(sp)
 444:	7902                	ld	s2,32(sp)
 446:	69e2                	ld	s3,24(sp)
 448:	6121                	addi	sp,sp,64
 44a:	8082                	ret
    x = -xx;
 44c:	40b005bb          	negw	a1,a1
    neg = 1;
 450:	4885                	li	a7,1
    x = -xx;
 452:	bf85                	j	3c2 <printint+0x1a>

0000000000000454 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 454:	7119                	addi	sp,sp,-128
 456:	fc86                	sd	ra,120(sp)
 458:	f8a2                	sd	s0,112(sp)
 45a:	f4a6                	sd	s1,104(sp)
 45c:	f0ca                	sd	s2,96(sp)
 45e:	ecce                	sd	s3,88(sp)
 460:	e8d2                	sd	s4,80(sp)
 462:	e4d6                	sd	s5,72(sp)
 464:	e0da                	sd	s6,64(sp)
 466:	fc5e                	sd	s7,56(sp)
 468:	f862                	sd	s8,48(sp)
 46a:	f466                	sd	s9,40(sp)
 46c:	f06a                	sd	s10,32(sp)
 46e:	ec6e                	sd	s11,24(sp)
 470:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 472:	0005c903          	lbu	s2,0(a1)
 476:	18090f63          	beqz	s2,614 <vprintf+0x1c0>
 47a:	8aaa                	mv	s5,a0
 47c:	8b32                	mv	s6,a2
 47e:	00158493          	addi	s1,a1,1
  state = 0;
 482:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 484:	02500a13          	li	s4,37
 488:	4c55                	li	s8,21
 48a:	00000c97          	auipc	s9,0x0
 48e:	386c8c93          	addi	s9,s9,902 # 810 <malloc+0xf8>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 492:	02800d93          	li	s11,40
  putc(fd, 'x');
 496:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 498:	00000b97          	auipc	s7,0x0
 49c:	3d0b8b93          	addi	s7,s7,976 # 868 <digits>
 4a0:	a839                	j	4be <vprintf+0x6a>
        putc(fd, c);
 4a2:	85ca                	mv	a1,s2
 4a4:	8556                	mv	a0,s5
 4a6:	00000097          	auipc	ra,0x0
 4aa:	ee0080e7          	jalr	-288(ra) # 386 <putc>
 4ae:	a019                	j	4b4 <vprintf+0x60>
    } else if(state == '%'){
 4b0:	01498d63          	beq	s3,s4,4ca <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4b4:	0485                	addi	s1,s1,1
 4b6:	fff4c903          	lbu	s2,-1(s1)
 4ba:	14090d63          	beqz	s2,614 <vprintf+0x1c0>
    if(state == 0){
 4be:	fe0999e3          	bnez	s3,4b0 <vprintf+0x5c>
      if(c == '%'){
 4c2:	ff4910e3          	bne	s2,s4,4a2 <vprintf+0x4e>
        state = '%';
 4c6:	89d2                	mv	s3,s4
 4c8:	b7f5                	j	4b4 <vprintf+0x60>
      if(c == 'd'){
 4ca:	11490c63          	beq	s2,s4,5e2 <vprintf+0x18e>
 4ce:	f9d9079b          	addiw	a5,s2,-99
 4d2:	0ff7f793          	zext.b	a5,a5
 4d6:	10fc6e63          	bltu	s8,a5,5f2 <vprintf+0x19e>
 4da:	f9d9079b          	addiw	a5,s2,-99
 4de:	0ff7f713          	zext.b	a4,a5
 4e2:	10ec6863          	bltu	s8,a4,5f2 <vprintf+0x19e>
 4e6:	00271793          	slli	a5,a4,0x2
 4ea:	97e6                	add	a5,a5,s9
 4ec:	439c                	lw	a5,0(a5)
 4ee:	97e6                	add	a5,a5,s9
 4f0:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4f2:	008b0913          	addi	s2,s6,8
 4f6:	4685                	li	a3,1
 4f8:	4629                	li	a2,10
 4fa:	000b2583          	lw	a1,0(s6)
 4fe:	8556                	mv	a0,s5
 500:	00000097          	auipc	ra,0x0
 504:	ea8080e7          	jalr	-344(ra) # 3a8 <printint>
 508:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 50a:	4981                	li	s3,0
 50c:	b765                	j	4b4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 50e:	008b0913          	addi	s2,s6,8
 512:	4681                	li	a3,0
 514:	4629                	li	a2,10
 516:	000b2583          	lw	a1,0(s6)
 51a:	8556                	mv	a0,s5
 51c:	00000097          	auipc	ra,0x0
 520:	e8c080e7          	jalr	-372(ra) # 3a8 <printint>
 524:	8b4a                	mv	s6,s2
      state = 0;
 526:	4981                	li	s3,0
 528:	b771                	j	4b4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 52a:	008b0913          	addi	s2,s6,8
 52e:	4681                	li	a3,0
 530:	866a                	mv	a2,s10
 532:	000b2583          	lw	a1,0(s6)
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	e70080e7          	jalr	-400(ra) # 3a8 <printint>
 540:	8b4a                	mv	s6,s2
      state = 0;
 542:	4981                	li	s3,0
 544:	bf85                	j	4b4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 546:	008b0793          	addi	a5,s6,8
 54a:	f8f43423          	sd	a5,-120(s0)
 54e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 552:	03000593          	li	a1,48
 556:	8556                	mv	a0,s5
 558:	00000097          	auipc	ra,0x0
 55c:	e2e080e7          	jalr	-466(ra) # 386 <putc>
  putc(fd, 'x');
 560:	07800593          	li	a1,120
 564:	8556                	mv	a0,s5
 566:	00000097          	auipc	ra,0x0
 56a:	e20080e7          	jalr	-480(ra) # 386 <putc>
 56e:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 570:	03c9d793          	srli	a5,s3,0x3c
 574:	97de                	add	a5,a5,s7
 576:	0007c583          	lbu	a1,0(a5)
 57a:	8556                	mv	a0,s5
 57c:	00000097          	auipc	ra,0x0
 580:	e0a080e7          	jalr	-502(ra) # 386 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 584:	0992                	slli	s3,s3,0x4
 586:	397d                	addiw	s2,s2,-1
 588:	fe0914e3          	bnez	s2,570 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 58c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 590:	4981                	li	s3,0
 592:	b70d                	j	4b4 <vprintf+0x60>
        s = va_arg(ap, char*);
 594:	008b0913          	addi	s2,s6,8
 598:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 59c:	02098163          	beqz	s3,5be <vprintf+0x16a>
        while(*s != 0){
 5a0:	0009c583          	lbu	a1,0(s3)
 5a4:	c5ad                	beqz	a1,60e <vprintf+0x1ba>
          putc(fd, *s);
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	dde080e7          	jalr	-546(ra) # 386 <putc>
          s++;
 5b0:	0985                	addi	s3,s3,1
        while(*s != 0){
 5b2:	0009c583          	lbu	a1,0(s3)
 5b6:	f9e5                	bnez	a1,5a6 <vprintf+0x152>
        s = va_arg(ap, char*);
 5b8:	8b4a                	mv	s6,s2
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	bde5                	j	4b4 <vprintf+0x60>
          s = "(null)";
 5be:	00000997          	auipc	s3,0x0
 5c2:	24a98993          	addi	s3,s3,586 # 808 <malloc+0xf0>
        while(*s != 0){
 5c6:	85ee                	mv	a1,s11
 5c8:	bff9                	j	5a6 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5ca:	008b0913          	addi	s2,s6,8
 5ce:	000b4583          	lbu	a1,0(s6)
 5d2:	8556                	mv	a0,s5
 5d4:	00000097          	auipc	ra,0x0
 5d8:	db2080e7          	jalr	-590(ra) # 386 <putc>
 5dc:	8b4a                	mv	s6,s2
      state = 0;
 5de:	4981                	li	s3,0
 5e0:	bdd1                	j	4b4 <vprintf+0x60>
        putc(fd, c);
 5e2:	85d2                	mv	a1,s4
 5e4:	8556                	mv	a0,s5
 5e6:	00000097          	auipc	ra,0x0
 5ea:	da0080e7          	jalr	-608(ra) # 386 <putc>
      state = 0;
 5ee:	4981                	li	s3,0
 5f0:	b5d1                	j	4b4 <vprintf+0x60>
        putc(fd, '%');
 5f2:	85d2                	mv	a1,s4
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	d90080e7          	jalr	-624(ra) # 386 <putc>
        putc(fd, c);
 5fe:	85ca                	mv	a1,s2
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	d84080e7          	jalr	-636(ra) # 386 <putc>
      state = 0;
 60a:	4981                	li	s3,0
 60c:	b565                	j	4b4 <vprintf+0x60>
        s = va_arg(ap, char*);
 60e:	8b4a                	mv	s6,s2
      state = 0;
 610:	4981                	li	s3,0
 612:	b54d                	j	4b4 <vprintf+0x60>
    }
  }
}
 614:	70e6                	ld	ra,120(sp)
 616:	7446                	ld	s0,112(sp)
 618:	74a6                	ld	s1,104(sp)
 61a:	7906                	ld	s2,96(sp)
 61c:	69e6                	ld	s3,88(sp)
 61e:	6a46                	ld	s4,80(sp)
 620:	6aa6                	ld	s5,72(sp)
 622:	6b06                	ld	s6,64(sp)
 624:	7be2                	ld	s7,56(sp)
 626:	7c42                	ld	s8,48(sp)
 628:	7ca2                	ld	s9,40(sp)
 62a:	7d02                	ld	s10,32(sp)
 62c:	6de2                	ld	s11,24(sp)
 62e:	6109                	addi	sp,sp,128
 630:	8082                	ret

0000000000000632 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 632:	715d                	addi	sp,sp,-80
 634:	ec06                	sd	ra,24(sp)
 636:	e822                	sd	s0,16(sp)
 638:	1000                	addi	s0,sp,32
 63a:	e010                	sd	a2,0(s0)
 63c:	e414                	sd	a3,8(s0)
 63e:	e818                	sd	a4,16(s0)
 640:	ec1c                	sd	a5,24(s0)
 642:	03043023          	sd	a6,32(s0)
 646:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 64a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 64e:	8622                	mv	a2,s0
 650:	00000097          	auipc	ra,0x0
 654:	e04080e7          	jalr	-508(ra) # 454 <vprintf>
}
 658:	60e2                	ld	ra,24(sp)
 65a:	6442                	ld	s0,16(sp)
 65c:	6161                	addi	sp,sp,80
 65e:	8082                	ret

0000000000000660 <printf>:

void
printf(const char *fmt, ...)
{
 660:	711d                	addi	sp,sp,-96
 662:	ec06                	sd	ra,24(sp)
 664:	e822                	sd	s0,16(sp)
 666:	1000                	addi	s0,sp,32
 668:	e40c                	sd	a1,8(s0)
 66a:	e810                	sd	a2,16(s0)
 66c:	ec14                	sd	a3,24(s0)
 66e:	f018                	sd	a4,32(s0)
 670:	f41c                	sd	a5,40(s0)
 672:	03043823          	sd	a6,48(s0)
 676:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 67a:	00840613          	addi	a2,s0,8
 67e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 682:	85aa                	mv	a1,a0
 684:	4505                	li	a0,1
 686:	00000097          	auipc	ra,0x0
 68a:	dce080e7          	jalr	-562(ra) # 454 <vprintf>
}
 68e:	60e2                	ld	ra,24(sp)
 690:	6442                	ld	s0,16(sp)
 692:	6125                	addi	sp,sp,96
 694:	8082                	ret

0000000000000696 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 696:	1141                	addi	sp,sp,-16
 698:	e422                	sd	s0,8(sp)
 69a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 69c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a0:	00000797          	auipc	a5,0x0
 6a4:	1e07b783          	ld	a5,480(a5) # 880 <freep>
 6a8:	a02d                	j	6d2 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6aa:	4618                	lw	a4,8(a2)
 6ac:	9f2d                	addw	a4,a4,a1
 6ae:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6b2:	6398                	ld	a4,0(a5)
 6b4:	6310                	ld	a2,0(a4)
 6b6:	a83d                	j	6f4 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6b8:	ff852703          	lw	a4,-8(a0)
 6bc:	9f31                	addw	a4,a4,a2
 6be:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6c0:	ff053683          	ld	a3,-16(a0)
 6c4:	a091                	j	708 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6c6:	6398                	ld	a4,0(a5)
 6c8:	00e7e463          	bltu	a5,a4,6d0 <free+0x3a>
 6cc:	00e6ea63          	bltu	a3,a4,6e0 <free+0x4a>
{
 6d0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d2:	fed7fae3          	bgeu	a5,a3,6c6 <free+0x30>
 6d6:	6398                	ld	a4,0(a5)
 6d8:	00e6e463          	bltu	a3,a4,6e0 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6dc:	fee7eae3          	bltu	a5,a4,6d0 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6e0:	ff852583          	lw	a1,-8(a0)
 6e4:	6390                	ld	a2,0(a5)
 6e6:	02059813          	slli	a6,a1,0x20
 6ea:	01c85713          	srli	a4,a6,0x1c
 6ee:	9736                	add	a4,a4,a3
 6f0:	fae60de3          	beq	a2,a4,6aa <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6f4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6f8:	4790                	lw	a2,8(a5)
 6fa:	02061593          	slli	a1,a2,0x20
 6fe:	01c5d713          	srli	a4,a1,0x1c
 702:	973e                	add	a4,a4,a5
 704:	fae68ae3          	beq	a3,a4,6b8 <free+0x22>
    p->s.ptr = bp->s.ptr;
 708:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 70a:	00000717          	auipc	a4,0x0
 70e:	16f73b23          	sd	a5,374(a4) # 880 <freep>
}
 712:	6422                	ld	s0,8(sp)
 714:	0141                	addi	sp,sp,16
 716:	8082                	ret

0000000000000718 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 718:	7139                	addi	sp,sp,-64
 71a:	fc06                	sd	ra,56(sp)
 71c:	f822                	sd	s0,48(sp)
 71e:	f426                	sd	s1,40(sp)
 720:	f04a                	sd	s2,32(sp)
 722:	ec4e                	sd	s3,24(sp)
 724:	e852                	sd	s4,16(sp)
 726:	e456                	sd	s5,8(sp)
 728:	e05a                	sd	s6,0(sp)
 72a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 72c:	02051493          	slli	s1,a0,0x20
 730:	9081                	srli	s1,s1,0x20
 732:	04bd                	addi	s1,s1,15
 734:	8091                	srli	s1,s1,0x4
 736:	0014899b          	addiw	s3,s1,1
 73a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 73c:	00000517          	auipc	a0,0x0
 740:	14453503          	ld	a0,324(a0) # 880 <freep>
 744:	c515                	beqz	a0,770 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 746:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 748:	4798                	lw	a4,8(a5)
 74a:	02977f63          	bgeu	a4,s1,788 <malloc+0x70>
 74e:	8a4e                	mv	s4,s3
 750:	0009871b          	sext.w	a4,s3
 754:	6685                	lui	a3,0x1
 756:	00d77363          	bgeu	a4,a3,75c <malloc+0x44>
 75a:	6a05                	lui	s4,0x1
 75c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 760:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 764:	00000917          	auipc	s2,0x0
 768:	11c90913          	addi	s2,s2,284 # 880 <freep>
  if(p == (char*)-1)
 76c:	5afd                	li	s5,-1
 76e:	a895                	j	7e2 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 770:	00000797          	auipc	a5,0x0
 774:	11878793          	addi	a5,a5,280 # 888 <base>
 778:	00000717          	auipc	a4,0x0
 77c:	10f73423          	sd	a5,264(a4) # 880 <freep>
 780:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 782:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 786:	b7e1                	j	74e <malloc+0x36>
      if(p->s.size == nunits)
 788:	02e48c63          	beq	s1,a4,7c0 <malloc+0xa8>
        p->s.size -= nunits;
 78c:	4137073b          	subw	a4,a4,s3
 790:	c798                	sw	a4,8(a5)
        p += p->s.size;
 792:	02071693          	slli	a3,a4,0x20
 796:	01c6d713          	srli	a4,a3,0x1c
 79a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 79c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7a0:	00000717          	auipc	a4,0x0
 7a4:	0ea73023          	sd	a0,224(a4) # 880 <freep>
      return (void*)(p + 1);
 7a8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ac:	70e2                	ld	ra,56(sp)
 7ae:	7442                	ld	s0,48(sp)
 7b0:	74a2                	ld	s1,40(sp)
 7b2:	7902                	ld	s2,32(sp)
 7b4:	69e2                	ld	s3,24(sp)
 7b6:	6a42                	ld	s4,16(sp)
 7b8:	6aa2                	ld	s5,8(sp)
 7ba:	6b02                	ld	s6,0(sp)
 7bc:	6121                	addi	sp,sp,64
 7be:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7c0:	6398                	ld	a4,0(a5)
 7c2:	e118                	sd	a4,0(a0)
 7c4:	bff1                	j	7a0 <malloc+0x88>
  hp->s.size = nu;
 7c6:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ca:	0541                	addi	a0,a0,16
 7cc:	00000097          	auipc	ra,0x0
 7d0:	eca080e7          	jalr	-310(ra) # 696 <free>
  return freep;
 7d4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7d8:	d971                	beqz	a0,7ac <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7da:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7dc:	4798                	lw	a4,8(a5)
 7de:	fa9775e3          	bgeu	a4,s1,788 <malloc+0x70>
    if(p == freep)
 7e2:	00093703          	ld	a4,0(s2)
 7e6:	853e                	mv	a0,a5
 7e8:	fef719e3          	bne	a4,a5,7da <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7ec:	8552                	mv	a0,s4
 7ee:	00000097          	auipc	ra,0x0
 7f2:	b60080e7          	jalr	-1184(ra) # 34e <sbrk>
  if(p == (char*)-1)
 7f6:	fd5518e3          	bne	a0,s5,7c6 <malloc+0xae>
        return 0;
 7fa:	4501                	li	a0,0
 7fc:	bf45                	j	7ac <malloc+0x94>
