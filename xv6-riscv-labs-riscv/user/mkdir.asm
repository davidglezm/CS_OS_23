
user/_mkdir:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
  int i;

  if(argc < 2){
   e:	4785                	li	a5,1
  10:	02a7d763          	bge	a5,a0,3e <main+0x3e>
  14:	00858493          	addi	s1,a1,8
  18:	ffe5091b          	addiw	s2,a0,-2
  1c:	02091793          	slli	a5,s2,0x20
  20:	01d7d913          	srli	s2,a5,0x1d
  24:	05c1                	addi	a1,a1,16
  26:	992e                	add	s2,s2,a1
    fprintf(2, "Usage: mkdir files...\n");
    exit(1);
  }

  for(i = 1; i < argc; i++){
    if(mkdir(argv[i]) < 0){
  28:	6088                	ld	a0,0(s1)
  2a:	00000097          	auipc	ra,0x0
  2e:	322080e7          	jalr	802(ra) # 34c <mkdir>
  32:	02054463          	bltz	a0,5a <main+0x5a>
  for(i = 1; i < argc; i++){
  36:	04a1                	addi	s1,s1,8
  38:	ff2498e3          	bne	s1,s2,28 <main+0x28>
  3c:	a80d                	j	6e <main+0x6e>
    fprintf(2, "Usage: mkdir files...\n");
  3e:	00000597          	auipc	a1,0x0
  42:	7e258593          	addi	a1,a1,2018 # 820 <malloc+0xea>
  46:	4509                	li	a0,2
  48:	00000097          	auipc	ra,0x0
  4c:	608080e7          	jalr	1544(ra) # 650 <fprintf>
    exit(1);
  50:	4505                	li	a0,1
  52:	00000097          	auipc	ra,0x0
  56:	292080e7          	jalr	658(ra) # 2e4 <exit>
      fprintf(2, "mkdir: %s failed to create\n", argv[i]);
  5a:	6090                	ld	a2,0(s1)
  5c:	00000597          	auipc	a1,0x0
  60:	7dc58593          	addi	a1,a1,2012 # 838 <malloc+0x102>
  64:	4509                	li	a0,2
  66:	00000097          	auipc	ra,0x0
  6a:	5ea080e7          	jalr	1514(ra) # 650 <fprintf>
      break;
    }
  }

  exit(0);
  6e:	4501                	li	a0,0
  70:	00000097          	auipc	ra,0x0
  74:	274080e7          	jalr	628(ra) # 2e4 <exit>

0000000000000078 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  78:	1141                	addi	sp,sp,-16
  7a:	e422                	sd	s0,8(sp)
  7c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  7e:	87aa                	mv	a5,a0
  80:	0585                	addi	a1,a1,1
  82:	0785                	addi	a5,a5,1
  84:	fff5c703          	lbu	a4,-1(a1)
  88:	fee78fa3          	sb	a4,-1(a5)
  8c:	fb75                	bnez	a4,80 <strcpy+0x8>
    ;
  return os;
}
  8e:	6422                	ld	s0,8(sp)
  90:	0141                	addi	sp,sp,16
  92:	8082                	ret

0000000000000094 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  94:	1141                	addi	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  9a:	00054783          	lbu	a5,0(a0)
  9e:	cb91                	beqz	a5,b2 <strcmp+0x1e>
  a0:	0005c703          	lbu	a4,0(a1)
  a4:	00f71763          	bne	a4,a5,b2 <strcmp+0x1e>
    p++, q++;
  a8:	0505                	addi	a0,a0,1
  aa:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  ac:	00054783          	lbu	a5,0(a0)
  b0:	fbe5                	bnez	a5,a0 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  b2:	0005c503          	lbu	a0,0(a1)
}
  b6:	40a7853b          	subw	a0,a5,a0
  ba:	6422                	ld	s0,8(sp)
  bc:	0141                	addi	sp,sp,16
  be:	8082                	ret

00000000000000c0 <strlen>:

uint
strlen(const char *s)
{
  c0:	1141                	addi	sp,sp,-16
  c2:	e422                	sd	s0,8(sp)
  c4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	cf91                	beqz	a5,e6 <strlen+0x26>
  cc:	0505                	addi	a0,a0,1
  ce:	87aa                	mv	a5,a0
  d0:	4685                	li	a3,1
  d2:	9e89                	subw	a3,a3,a0
  d4:	00f6853b          	addw	a0,a3,a5
  d8:	0785                	addi	a5,a5,1
  da:	fff7c703          	lbu	a4,-1(a5)
  de:	fb7d                	bnez	a4,d4 <strlen+0x14>
    ;
  return n;
}
  e0:	6422                	ld	s0,8(sp)
  e2:	0141                	addi	sp,sp,16
  e4:	8082                	ret
  for(n = 0; s[n]; n++)
  e6:	4501                	li	a0,0
  e8:	bfe5                	j	e0 <strlen+0x20>

00000000000000ea <memset>:

void*
memset(void *dst, int c, uint n)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f0:	ca19                	beqz	a2,106 <memset+0x1c>
  f2:	87aa                	mv	a5,a0
  f4:	1602                	slli	a2,a2,0x20
  f6:	9201                	srli	a2,a2,0x20
  f8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  fc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 100:	0785                	addi	a5,a5,1
 102:	fee79de3          	bne	a5,a4,fc <memset+0x12>
  }
  return dst;
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	addi	sp,sp,16
 10a:	8082                	ret

000000000000010c <strchr>:

char*
strchr(const char *s, char c)
{
 10c:	1141                	addi	sp,sp,-16
 10e:	e422                	sd	s0,8(sp)
 110:	0800                	addi	s0,sp,16
  for(; *s; s++)
 112:	00054783          	lbu	a5,0(a0)
 116:	cb99                	beqz	a5,12c <strchr+0x20>
    if(*s == c)
 118:	00f58763          	beq	a1,a5,126 <strchr+0x1a>
  for(; *s; s++)
 11c:	0505                	addi	a0,a0,1
 11e:	00054783          	lbu	a5,0(a0)
 122:	fbfd                	bnez	a5,118 <strchr+0xc>
      return (char*)s;
  return 0;
 124:	4501                	li	a0,0
}
 126:	6422                	ld	s0,8(sp)
 128:	0141                	addi	sp,sp,16
 12a:	8082                	ret
  return 0;
 12c:	4501                	li	a0,0
 12e:	bfe5                	j	126 <strchr+0x1a>

0000000000000130 <gets>:

char*
gets(char *buf, int max)
{
 130:	711d                	addi	sp,sp,-96
 132:	ec86                	sd	ra,88(sp)
 134:	e8a2                	sd	s0,80(sp)
 136:	e4a6                	sd	s1,72(sp)
 138:	e0ca                	sd	s2,64(sp)
 13a:	fc4e                	sd	s3,56(sp)
 13c:	f852                	sd	s4,48(sp)
 13e:	f456                	sd	s5,40(sp)
 140:	f05a                	sd	s6,32(sp)
 142:	ec5e                	sd	s7,24(sp)
 144:	1080                	addi	s0,sp,96
 146:	8baa                	mv	s7,a0
 148:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 14a:	892a                	mv	s2,a0
 14c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 14e:	4aa9                	li	s5,10
 150:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 152:	89a6                	mv	s3,s1
 154:	2485                	addiw	s1,s1,1
 156:	0344d863          	bge	s1,s4,186 <gets+0x56>
    cc = read(0, &c, 1);
 15a:	4605                	li	a2,1
 15c:	faf40593          	addi	a1,s0,-81
 160:	4501                	li	a0,0
 162:	00000097          	auipc	ra,0x0
 166:	19a080e7          	jalr	410(ra) # 2fc <read>
    if(cc < 1)
 16a:	00a05e63          	blez	a0,186 <gets+0x56>
    buf[i++] = c;
 16e:	faf44783          	lbu	a5,-81(s0)
 172:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 176:	01578763          	beq	a5,s5,184 <gets+0x54>
 17a:	0905                	addi	s2,s2,1
 17c:	fd679be3          	bne	a5,s6,152 <gets+0x22>
  for(i=0; i+1 < max; ){
 180:	89a6                	mv	s3,s1
 182:	a011                	j	186 <gets+0x56>
 184:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 186:	99de                	add	s3,s3,s7
 188:	00098023          	sb	zero,0(s3)
  return buf;
}
 18c:	855e                	mv	a0,s7
 18e:	60e6                	ld	ra,88(sp)
 190:	6446                	ld	s0,80(sp)
 192:	64a6                	ld	s1,72(sp)
 194:	6906                	ld	s2,64(sp)
 196:	79e2                	ld	s3,56(sp)
 198:	7a42                	ld	s4,48(sp)
 19a:	7aa2                	ld	s5,40(sp)
 19c:	7b02                	ld	s6,32(sp)
 19e:	6be2                	ld	s7,24(sp)
 1a0:	6125                	addi	sp,sp,96
 1a2:	8082                	ret

00000000000001a4 <stat>:

int
stat(const char *n, struct stat *st)
{
 1a4:	1101                	addi	sp,sp,-32
 1a6:	ec06                	sd	ra,24(sp)
 1a8:	e822                	sd	s0,16(sp)
 1aa:	e426                	sd	s1,8(sp)
 1ac:	e04a                	sd	s2,0(sp)
 1ae:	1000                	addi	s0,sp,32
 1b0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1b2:	4581                	li	a1,0
 1b4:	00000097          	auipc	ra,0x0
 1b8:	170080e7          	jalr	368(ra) # 324 <open>
  if(fd < 0)
 1bc:	02054563          	bltz	a0,1e6 <stat+0x42>
 1c0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1c2:	85ca                	mv	a1,s2
 1c4:	00000097          	auipc	ra,0x0
 1c8:	178080e7          	jalr	376(ra) # 33c <fstat>
 1cc:	892a                	mv	s2,a0
  close(fd);
 1ce:	8526                	mv	a0,s1
 1d0:	00000097          	auipc	ra,0x0
 1d4:	13c080e7          	jalr	316(ra) # 30c <close>
  return r;
}
 1d8:	854a                	mv	a0,s2
 1da:	60e2                	ld	ra,24(sp)
 1dc:	6442                	ld	s0,16(sp)
 1de:	64a2                	ld	s1,8(sp)
 1e0:	6902                	ld	s2,0(sp)
 1e2:	6105                	addi	sp,sp,32
 1e4:	8082                	ret
    return -1;
 1e6:	597d                	li	s2,-1
 1e8:	bfc5                	j	1d8 <stat+0x34>

00000000000001ea <atoi>:

int
atoi(const char *s)
{
 1ea:	1141                	addi	sp,sp,-16
 1ec:	e422                	sd	s0,8(sp)
 1ee:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f0:	00054683          	lbu	a3,0(a0)
 1f4:	fd06879b          	addiw	a5,a3,-48
 1f8:	0ff7f793          	zext.b	a5,a5
 1fc:	4625                	li	a2,9
 1fe:	02f66863          	bltu	a2,a5,22e <atoi+0x44>
 202:	872a                	mv	a4,a0
  n = 0;
 204:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 206:	0705                	addi	a4,a4,1
 208:	0025179b          	slliw	a5,a0,0x2
 20c:	9fa9                	addw	a5,a5,a0
 20e:	0017979b          	slliw	a5,a5,0x1
 212:	9fb5                	addw	a5,a5,a3
 214:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 218:	00074683          	lbu	a3,0(a4)
 21c:	fd06879b          	addiw	a5,a3,-48
 220:	0ff7f793          	zext.b	a5,a5
 224:	fef671e3          	bgeu	a2,a5,206 <atoi+0x1c>
  return n;
}
 228:	6422                	ld	s0,8(sp)
 22a:	0141                	addi	sp,sp,16
 22c:	8082                	ret
  n = 0;
 22e:	4501                	li	a0,0
 230:	bfe5                	j	228 <atoi+0x3e>

0000000000000232 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 232:	1141                	addi	sp,sp,-16
 234:	e422                	sd	s0,8(sp)
 236:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 238:	02b57463          	bgeu	a0,a1,260 <memmove+0x2e>
    while(n-- > 0)
 23c:	00c05f63          	blez	a2,25a <memmove+0x28>
 240:	1602                	slli	a2,a2,0x20
 242:	9201                	srli	a2,a2,0x20
 244:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 248:	872a                	mv	a4,a0
      *dst++ = *src++;
 24a:	0585                	addi	a1,a1,1
 24c:	0705                	addi	a4,a4,1
 24e:	fff5c683          	lbu	a3,-1(a1)
 252:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 256:	fee79ae3          	bne	a5,a4,24a <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 25a:	6422                	ld	s0,8(sp)
 25c:	0141                	addi	sp,sp,16
 25e:	8082                	ret
    dst += n;
 260:	00c50733          	add	a4,a0,a2
    src += n;
 264:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 266:	fec05ae3          	blez	a2,25a <memmove+0x28>
 26a:	fff6079b          	addiw	a5,a2,-1
 26e:	1782                	slli	a5,a5,0x20
 270:	9381                	srli	a5,a5,0x20
 272:	fff7c793          	not	a5,a5
 276:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 278:	15fd                	addi	a1,a1,-1
 27a:	177d                	addi	a4,a4,-1
 27c:	0005c683          	lbu	a3,0(a1)
 280:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 284:	fee79ae3          	bne	a5,a4,278 <memmove+0x46>
 288:	bfc9                	j	25a <memmove+0x28>

000000000000028a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 28a:	1141                	addi	sp,sp,-16
 28c:	e422                	sd	s0,8(sp)
 28e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 290:	ca05                	beqz	a2,2c0 <memcmp+0x36>
 292:	fff6069b          	addiw	a3,a2,-1
 296:	1682                	slli	a3,a3,0x20
 298:	9281                	srli	a3,a3,0x20
 29a:	0685                	addi	a3,a3,1
 29c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 29e:	00054783          	lbu	a5,0(a0)
 2a2:	0005c703          	lbu	a4,0(a1)
 2a6:	00e79863          	bne	a5,a4,2b6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2aa:	0505                	addi	a0,a0,1
    p2++;
 2ac:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2ae:	fed518e3          	bne	a0,a3,29e <memcmp+0x14>
  }
  return 0;
 2b2:	4501                	li	a0,0
 2b4:	a019                	j	2ba <memcmp+0x30>
      return *p1 - *p2;
 2b6:	40e7853b          	subw	a0,a5,a4
}
 2ba:	6422                	ld	s0,8(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret
  return 0;
 2c0:	4501                	li	a0,0
 2c2:	bfe5                	j	2ba <memcmp+0x30>

00000000000002c4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2c4:	1141                	addi	sp,sp,-16
 2c6:	e406                	sd	ra,8(sp)
 2c8:	e022                	sd	s0,0(sp)
 2ca:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2cc:	00000097          	auipc	ra,0x0
 2d0:	f66080e7          	jalr	-154(ra) # 232 <memmove>
}
 2d4:	60a2                	ld	ra,8(sp)
 2d6:	6402                	ld	s0,0(sp)
 2d8:	0141                	addi	sp,sp,16
 2da:	8082                	ret

00000000000002dc <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2dc:	4885                	li	a7,1
 ecall
 2de:	00000073          	ecall
 ret
 2e2:	8082                	ret

00000000000002e4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2e4:	4889                	li	a7,2
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ec:	488d                	li	a7,3
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2f4:	4891                	li	a7,4
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <read>:
.global read
read:
 li a7, SYS_read
 2fc:	4895                	li	a7,5
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <write>:
.global write
write:
 li a7, SYS_write
 304:	48c1                	li	a7,16
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <close>:
.global close
close:
 li a7, SYS_close
 30c:	48d5                	li	a7,21
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <kill>:
.global kill
kill:
 li a7, SYS_kill
 314:	4899                	li	a7,6
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <exec>:
.global exec
exec:
 li a7, SYS_exec
 31c:	489d                	li	a7,7
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <open>:
.global open
open:
 li a7, SYS_open
 324:	48bd                	li	a7,15
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 32c:	48c5                	li	a7,17
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 334:	48c9                	li	a7,18
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 33c:	48a1                	li	a7,8
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <link>:
.global link
link:
 li a7, SYS_link
 344:	48cd                	li	a7,19
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 34c:	48d1                	li	a7,20
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 354:	48a5                	li	a7,9
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <dup>:
.global dup
dup:
 li a7, SYS_dup
 35c:	48a9                	li	a7,10
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 364:	48ad                	li	a7,11
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 36c:	48b1                	li	a7,12
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 374:	48b5                	li	a7,13
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 37c:	48b9                	li	a7,14
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 384:	48d9                	li	a7,22
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 38c:	48dd                	li	a7,23
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 394:	48e1                	li	a7,24
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 39c:	48e5                	li	a7,25
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3a4:	1101                	addi	sp,sp,-32
 3a6:	ec06                	sd	ra,24(sp)
 3a8:	e822                	sd	s0,16(sp)
 3aa:	1000                	addi	s0,sp,32
 3ac:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3b0:	4605                	li	a2,1
 3b2:	fef40593          	addi	a1,s0,-17
 3b6:	00000097          	auipc	ra,0x0
 3ba:	f4e080e7          	jalr	-178(ra) # 304 <write>
}
 3be:	60e2                	ld	ra,24(sp)
 3c0:	6442                	ld	s0,16(sp)
 3c2:	6105                	addi	sp,sp,32
 3c4:	8082                	ret

00000000000003c6 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3c6:	7139                	addi	sp,sp,-64
 3c8:	fc06                	sd	ra,56(sp)
 3ca:	f822                	sd	s0,48(sp)
 3cc:	f426                	sd	s1,40(sp)
 3ce:	f04a                	sd	s2,32(sp)
 3d0:	ec4e                	sd	s3,24(sp)
 3d2:	0080                	addi	s0,sp,64
 3d4:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3d6:	c299                	beqz	a3,3dc <printint+0x16>
 3d8:	0805c963          	bltz	a1,46a <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3dc:	2581                	sext.w	a1,a1
  neg = 0;
 3de:	4881                	li	a7,0
 3e0:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3e4:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3e6:	2601                	sext.w	a2,a2
 3e8:	00000517          	auipc	a0,0x0
 3ec:	4d050513          	addi	a0,a0,1232 # 8b8 <digits>
 3f0:	883a                	mv	a6,a4
 3f2:	2705                	addiw	a4,a4,1
 3f4:	02c5f7bb          	remuw	a5,a1,a2
 3f8:	1782                	slli	a5,a5,0x20
 3fa:	9381                	srli	a5,a5,0x20
 3fc:	97aa                	add	a5,a5,a0
 3fe:	0007c783          	lbu	a5,0(a5)
 402:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 406:	0005879b          	sext.w	a5,a1
 40a:	02c5d5bb          	divuw	a1,a1,a2
 40e:	0685                	addi	a3,a3,1
 410:	fec7f0e3          	bgeu	a5,a2,3f0 <printint+0x2a>
  if(neg)
 414:	00088c63          	beqz	a7,42c <printint+0x66>
    buf[i++] = '-';
 418:	fd070793          	addi	a5,a4,-48
 41c:	00878733          	add	a4,a5,s0
 420:	02d00793          	li	a5,45
 424:	fef70823          	sb	a5,-16(a4)
 428:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 42c:	02e05863          	blez	a4,45c <printint+0x96>
 430:	fc040793          	addi	a5,s0,-64
 434:	00e78933          	add	s2,a5,a4
 438:	fff78993          	addi	s3,a5,-1
 43c:	99ba                	add	s3,s3,a4
 43e:	377d                	addiw	a4,a4,-1
 440:	1702                	slli	a4,a4,0x20
 442:	9301                	srli	a4,a4,0x20
 444:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 448:	fff94583          	lbu	a1,-1(s2)
 44c:	8526                	mv	a0,s1
 44e:	00000097          	auipc	ra,0x0
 452:	f56080e7          	jalr	-170(ra) # 3a4 <putc>
  while(--i >= 0)
 456:	197d                	addi	s2,s2,-1
 458:	ff3918e3          	bne	s2,s3,448 <printint+0x82>
}
 45c:	70e2                	ld	ra,56(sp)
 45e:	7442                	ld	s0,48(sp)
 460:	74a2                	ld	s1,40(sp)
 462:	7902                	ld	s2,32(sp)
 464:	69e2                	ld	s3,24(sp)
 466:	6121                	addi	sp,sp,64
 468:	8082                	ret
    x = -xx;
 46a:	40b005bb          	negw	a1,a1
    neg = 1;
 46e:	4885                	li	a7,1
    x = -xx;
 470:	bf85                	j	3e0 <printint+0x1a>

0000000000000472 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 472:	7119                	addi	sp,sp,-128
 474:	fc86                	sd	ra,120(sp)
 476:	f8a2                	sd	s0,112(sp)
 478:	f4a6                	sd	s1,104(sp)
 47a:	f0ca                	sd	s2,96(sp)
 47c:	ecce                	sd	s3,88(sp)
 47e:	e8d2                	sd	s4,80(sp)
 480:	e4d6                	sd	s5,72(sp)
 482:	e0da                	sd	s6,64(sp)
 484:	fc5e                	sd	s7,56(sp)
 486:	f862                	sd	s8,48(sp)
 488:	f466                	sd	s9,40(sp)
 48a:	f06a                	sd	s10,32(sp)
 48c:	ec6e                	sd	s11,24(sp)
 48e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 490:	0005c903          	lbu	s2,0(a1)
 494:	18090f63          	beqz	s2,632 <vprintf+0x1c0>
 498:	8aaa                	mv	s5,a0
 49a:	8b32                	mv	s6,a2
 49c:	00158493          	addi	s1,a1,1
  state = 0;
 4a0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4a2:	02500a13          	li	s4,37
 4a6:	4c55                	li	s8,21
 4a8:	00000c97          	auipc	s9,0x0
 4ac:	3b8c8c93          	addi	s9,s9,952 # 860 <malloc+0x12a>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4b0:	02800d93          	li	s11,40
  putc(fd, 'x');
 4b4:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4b6:	00000b97          	auipc	s7,0x0
 4ba:	402b8b93          	addi	s7,s7,1026 # 8b8 <digits>
 4be:	a839                	j	4dc <vprintf+0x6a>
        putc(fd, c);
 4c0:	85ca                	mv	a1,s2
 4c2:	8556                	mv	a0,s5
 4c4:	00000097          	auipc	ra,0x0
 4c8:	ee0080e7          	jalr	-288(ra) # 3a4 <putc>
 4cc:	a019                	j	4d2 <vprintf+0x60>
    } else if(state == '%'){
 4ce:	01498d63          	beq	s3,s4,4e8 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4d2:	0485                	addi	s1,s1,1
 4d4:	fff4c903          	lbu	s2,-1(s1)
 4d8:	14090d63          	beqz	s2,632 <vprintf+0x1c0>
    if(state == 0){
 4dc:	fe0999e3          	bnez	s3,4ce <vprintf+0x5c>
      if(c == '%'){
 4e0:	ff4910e3          	bne	s2,s4,4c0 <vprintf+0x4e>
        state = '%';
 4e4:	89d2                	mv	s3,s4
 4e6:	b7f5                	j	4d2 <vprintf+0x60>
      if(c == 'd'){
 4e8:	11490c63          	beq	s2,s4,600 <vprintf+0x18e>
 4ec:	f9d9079b          	addiw	a5,s2,-99
 4f0:	0ff7f793          	zext.b	a5,a5
 4f4:	10fc6e63          	bltu	s8,a5,610 <vprintf+0x19e>
 4f8:	f9d9079b          	addiw	a5,s2,-99
 4fc:	0ff7f713          	zext.b	a4,a5
 500:	10ec6863          	bltu	s8,a4,610 <vprintf+0x19e>
 504:	00271793          	slli	a5,a4,0x2
 508:	97e6                	add	a5,a5,s9
 50a:	439c                	lw	a5,0(a5)
 50c:	97e6                	add	a5,a5,s9
 50e:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 510:	008b0913          	addi	s2,s6,8
 514:	4685                	li	a3,1
 516:	4629                	li	a2,10
 518:	000b2583          	lw	a1,0(s6)
 51c:	8556                	mv	a0,s5
 51e:	00000097          	auipc	ra,0x0
 522:	ea8080e7          	jalr	-344(ra) # 3c6 <printint>
 526:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 528:	4981                	li	s3,0
 52a:	b765                	j	4d2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 52c:	008b0913          	addi	s2,s6,8
 530:	4681                	li	a3,0
 532:	4629                	li	a2,10
 534:	000b2583          	lw	a1,0(s6)
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	e8c080e7          	jalr	-372(ra) # 3c6 <printint>
 542:	8b4a                	mv	s6,s2
      state = 0;
 544:	4981                	li	s3,0
 546:	b771                	j	4d2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 548:	008b0913          	addi	s2,s6,8
 54c:	4681                	li	a3,0
 54e:	866a                	mv	a2,s10
 550:	000b2583          	lw	a1,0(s6)
 554:	8556                	mv	a0,s5
 556:	00000097          	auipc	ra,0x0
 55a:	e70080e7          	jalr	-400(ra) # 3c6 <printint>
 55e:	8b4a                	mv	s6,s2
      state = 0;
 560:	4981                	li	s3,0
 562:	bf85                	j	4d2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 564:	008b0793          	addi	a5,s6,8
 568:	f8f43423          	sd	a5,-120(s0)
 56c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 570:	03000593          	li	a1,48
 574:	8556                	mv	a0,s5
 576:	00000097          	auipc	ra,0x0
 57a:	e2e080e7          	jalr	-466(ra) # 3a4 <putc>
  putc(fd, 'x');
 57e:	07800593          	li	a1,120
 582:	8556                	mv	a0,s5
 584:	00000097          	auipc	ra,0x0
 588:	e20080e7          	jalr	-480(ra) # 3a4 <putc>
 58c:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 58e:	03c9d793          	srli	a5,s3,0x3c
 592:	97de                	add	a5,a5,s7
 594:	0007c583          	lbu	a1,0(a5)
 598:	8556                	mv	a0,s5
 59a:	00000097          	auipc	ra,0x0
 59e:	e0a080e7          	jalr	-502(ra) # 3a4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5a2:	0992                	slli	s3,s3,0x4
 5a4:	397d                	addiw	s2,s2,-1
 5a6:	fe0914e3          	bnez	s2,58e <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5aa:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5ae:	4981                	li	s3,0
 5b0:	b70d                	j	4d2 <vprintf+0x60>
        s = va_arg(ap, char*);
 5b2:	008b0913          	addi	s2,s6,8
 5b6:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5ba:	02098163          	beqz	s3,5dc <vprintf+0x16a>
        while(*s != 0){
 5be:	0009c583          	lbu	a1,0(s3)
 5c2:	c5ad                	beqz	a1,62c <vprintf+0x1ba>
          putc(fd, *s);
 5c4:	8556                	mv	a0,s5
 5c6:	00000097          	auipc	ra,0x0
 5ca:	dde080e7          	jalr	-546(ra) # 3a4 <putc>
          s++;
 5ce:	0985                	addi	s3,s3,1
        while(*s != 0){
 5d0:	0009c583          	lbu	a1,0(s3)
 5d4:	f9e5                	bnez	a1,5c4 <vprintf+0x152>
        s = va_arg(ap, char*);
 5d6:	8b4a                	mv	s6,s2
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	bde5                	j	4d2 <vprintf+0x60>
          s = "(null)";
 5dc:	00000997          	auipc	s3,0x0
 5e0:	27c98993          	addi	s3,s3,636 # 858 <malloc+0x122>
        while(*s != 0){
 5e4:	85ee                	mv	a1,s11
 5e6:	bff9                	j	5c4 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5e8:	008b0913          	addi	s2,s6,8
 5ec:	000b4583          	lbu	a1,0(s6)
 5f0:	8556                	mv	a0,s5
 5f2:	00000097          	auipc	ra,0x0
 5f6:	db2080e7          	jalr	-590(ra) # 3a4 <putc>
 5fa:	8b4a                	mv	s6,s2
      state = 0;
 5fc:	4981                	li	s3,0
 5fe:	bdd1                	j	4d2 <vprintf+0x60>
        putc(fd, c);
 600:	85d2                	mv	a1,s4
 602:	8556                	mv	a0,s5
 604:	00000097          	auipc	ra,0x0
 608:	da0080e7          	jalr	-608(ra) # 3a4 <putc>
      state = 0;
 60c:	4981                	li	s3,0
 60e:	b5d1                	j	4d2 <vprintf+0x60>
        putc(fd, '%');
 610:	85d2                	mv	a1,s4
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	d90080e7          	jalr	-624(ra) # 3a4 <putc>
        putc(fd, c);
 61c:	85ca                	mv	a1,s2
 61e:	8556                	mv	a0,s5
 620:	00000097          	auipc	ra,0x0
 624:	d84080e7          	jalr	-636(ra) # 3a4 <putc>
      state = 0;
 628:	4981                	li	s3,0
 62a:	b565                	j	4d2 <vprintf+0x60>
        s = va_arg(ap, char*);
 62c:	8b4a                	mv	s6,s2
      state = 0;
 62e:	4981                	li	s3,0
 630:	b54d                	j	4d2 <vprintf+0x60>
    }
  }
}
 632:	70e6                	ld	ra,120(sp)
 634:	7446                	ld	s0,112(sp)
 636:	74a6                	ld	s1,104(sp)
 638:	7906                	ld	s2,96(sp)
 63a:	69e6                	ld	s3,88(sp)
 63c:	6a46                	ld	s4,80(sp)
 63e:	6aa6                	ld	s5,72(sp)
 640:	6b06                	ld	s6,64(sp)
 642:	7be2                	ld	s7,56(sp)
 644:	7c42                	ld	s8,48(sp)
 646:	7ca2                	ld	s9,40(sp)
 648:	7d02                	ld	s10,32(sp)
 64a:	6de2                	ld	s11,24(sp)
 64c:	6109                	addi	sp,sp,128
 64e:	8082                	ret

0000000000000650 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 650:	715d                	addi	sp,sp,-80
 652:	ec06                	sd	ra,24(sp)
 654:	e822                	sd	s0,16(sp)
 656:	1000                	addi	s0,sp,32
 658:	e010                	sd	a2,0(s0)
 65a:	e414                	sd	a3,8(s0)
 65c:	e818                	sd	a4,16(s0)
 65e:	ec1c                	sd	a5,24(s0)
 660:	03043023          	sd	a6,32(s0)
 664:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 668:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 66c:	8622                	mv	a2,s0
 66e:	00000097          	auipc	ra,0x0
 672:	e04080e7          	jalr	-508(ra) # 472 <vprintf>
}
 676:	60e2                	ld	ra,24(sp)
 678:	6442                	ld	s0,16(sp)
 67a:	6161                	addi	sp,sp,80
 67c:	8082                	ret

000000000000067e <printf>:

void
printf(const char *fmt, ...)
{
 67e:	711d                	addi	sp,sp,-96
 680:	ec06                	sd	ra,24(sp)
 682:	e822                	sd	s0,16(sp)
 684:	1000                	addi	s0,sp,32
 686:	e40c                	sd	a1,8(s0)
 688:	e810                	sd	a2,16(s0)
 68a:	ec14                	sd	a3,24(s0)
 68c:	f018                	sd	a4,32(s0)
 68e:	f41c                	sd	a5,40(s0)
 690:	03043823          	sd	a6,48(s0)
 694:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 698:	00840613          	addi	a2,s0,8
 69c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6a0:	85aa                	mv	a1,a0
 6a2:	4505                	li	a0,1
 6a4:	00000097          	auipc	ra,0x0
 6a8:	dce080e7          	jalr	-562(ra) # 472 <vprintf>
}
 6ac:	60e2                	ld	ra,24(sp)
 6ae:	6442                	ld	s0,16(sp)
 6b0:	6125                	addi	sp,sp,96
 6b2:	8082                	ret

00000000000006b4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6b4:	1141                	addi	sp,sp,-16
 6b6:	e422                	sd	s0,8(sp)
 6b8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ba:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6be:	00000797          	auipc	a5,0x0
 6c2:	2127b783          	ld	a5,530(a5) # 8d0 <freep>
 6c6:	a02d                	j	6f0 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6c8:	4618                	lw	a4,8(a2)
 6ca:	9f2d                	addw	a4,a4,a1
 6cc:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6d0:	6398                	ld	a4,0(a5)
 6d2:	6310                	ld	a2,0(a4)
 6d4:	a83d                	j	712 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6d6:	ff852703          	lw	a4,-8(a0)
 6da:	9f31                	addw	a4,a4,a2
 6dc:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6de:	ff053683          	ld	a3,-16(a0)
 6e2:	a091                	j	726 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e4:	6398                	ld	a4,0(a5)
 6e6:	00e7e463          	bltu	a5,a4,6ee <free+0x3a>
 6ea:	00e6ea63          	bltu	a3,a4,6fe <free+0x4a>
{
 6ee:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f0:	fed7fae3          	bgeu	a5,a3,6e4 <free+0x30>
 6f4:	6398                	ld	a4,0(a5)
 6f6:	00e6e463          	bltu	a3,a4,6fe <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6fa:	fee7eae3          	bltu	a5,a4,6ee <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6fe:	ff852583          	lw	a1,-8(a0)
 702:	6390                	ld	a2,0(a5)
 704:	02059813          	slli	a6,a1,0x20
 708:	01c85713          	srli	a4,a6,0x1c
 70c:	9736                	add	a4,a4,a3
 70e:	fae60de3          	beq	a2,a4,6c8 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 712:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 716:	4790                	lw	a2,8(a5)
 718:	02061593          	slli	a1,a2,0x20
 71c:	01c5d713          	srli	a4,a1,0x1c
 720:	973e                	add	a4,a4,a5
 722:	fae68ae3          	beq	a3,a4,6d6 <free+0x22>
    p->s.ptr = bp->s.ptr;
 726:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 728:	00000717          	auipc	a4,0x0
 72c:	1af73423          	sd	a5,424(a4) # 8d0 <freep>
}
 730:	6422                	ld	s0,8(sp)
 732:	0141                	addi	sp,sp,16
 734:	8082                	ret

0000000000000736 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 736:	7139                	addi	sp,sp,-64
 738:	fc06                	sd	ra,56(sp)
 73a:	f822                	sd	s0,48(sp)
 73c:	f426                	sd	s1,40(sp)
 73e:	f04a                	sd	s2,32(sp)
 740:	ec4e                	sd	s3,24(sp)
 742:	e852                	sd	s4,16(sp)
 744:	e456                	sd	s5,8(sp)
 746:	e05a                	sd	s6,0(sp)
 748:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 74a:	02051493          	slli	s1,a0,0x20
 74e:	9081                	srli	s1,s1,0x20
 750:	04bd                	addi	s1,s1,15
 752:	8091                	srli	s1,s1,0x4
 754:	0014899b          	addiw	s3,s1,1
 758:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 75a:	00000517          	auipc	a0,0x0
 75e:	17653503          	ld	a0,374(a0) # 8d0 <freep>
 762:	c515                	beqz	a0,78e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 764:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 766:	4798                	lw	a4,8(a5)
 768:	02977f63          	bgeu	a4,s1,7a6 <malloc+0x70>
 76c:	8a4e                	mv	s4,s3
 76e:	0009871b          	sext.w	a4,s3
 772:	6685                	lui	a3,0x1
 774:	00d77363          	bgeu	a4,a3,77a <malloc+0x44>
 778:	6a05                	lui	s4,0x1
 77a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 77e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 782:	00000917          	auipc	s2,0x0
 786:	14e90913          	addi	s2,s2,334 # 8d0 <freep>
  if(p == (char*)-1)
 78a:	5afd                	li	s5,-1
 78c:	a895                	j	800 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 78e:	00000797          	auipc	a5,0x0
 792:	14a78793          	addi	a5,a5,330 # 8d8 <base>
 796:	00000717          	auipc	a4,0x0
 79a:	12f73d23          	sd	a5,314(a4) # 8d0 <freep>
 79e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7a0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7a4:	b7e1                	j	76c <malloc+0x36>
      if(p->s.size == nunits)
 7a6:	02e48c63          	beq	s1,a4,7de <malloc+0xa8>
        p->s.size -= nunits;
 7aa:	4137073b          	subw	a4,a4,s3
 7ae:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7b0:	02071693          	slli	a3,a4,0x20
 7b4:	01c6d713          	srli	a4,a3,0x1c
 7b8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7ba:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7be:	00000717          	auipc	a4,0x0
 7c2:	10a73923          	sd	a0,274(a4) # 8d0 <freep>
      return (void*)(p + 1);
 7c6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ca:	70e2                	ld	ra,56(sp)
 7cc:	7442                	ld	s0,48(sp)
 7ce:	74a2                	ld	s1,40(sp)
 7d0:	7902                	ld	s2,32(sp)
 7d2:	69e2                	ld	s3,24(sp)
 7d4:	6a42                	ld	s4,16(sp)
 7d6:	6aa2                	ld	s5,8(sp)
 7d8:	6b02                	ld	s6,0(sp)
 7da:	6121                	addi	sp,sp,64
 7dc:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7de:	6398                	ld	a4,0(a5)
 7e0:	e118                	sd	a4,0(a0)
 7e2:	bff1                	j	7be <malloc+0x88>
  hp->s.size = nu;
 7e4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7e8:	0541                	addi	a0,a0,16
 7ea:	00000097          	auipc	ra,0x0
 7ee:	eca080e7          	jalr	-310(ra) # 6b4 <free>
  return freep;
 7f2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7f6:	d971                	beqz	a0,7ca <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7fa:	4798                	lw	a4,8(a5)
 7fc:	fa9775e3          	bgeu	a4,s1,7a6 <malloc+0x70>
    if(p == freep)
 800:	00093703          	ld	a4,0(s2)
 804:	853e                	mv	a0,a5
 806:	fef719e3          	bne	a4,a5,7f8 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 80a:	8552                	mv	a0,s4
 80c:	00000097          	auipc	ra,0x0
 810:	b60080e7          	jalr	-1184(ra) # 36c <sbrk>
  if(p == (char*)-1)
 814:	fd5518e3          	bne	a0,s5,7e4 <malloc+0xae>
        return 0;
 818:	4501                	li	a0,0
 81a:	bf45                	j	7ca <malloc+0x94>
