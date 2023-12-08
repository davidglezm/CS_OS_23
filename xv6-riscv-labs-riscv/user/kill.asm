
user/_kill:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char **argv)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
   c:	4785                	li	a5,1
   e:	02a7dd63          	bge	a5,a0,48 <main+0x48>
  12:	00858493          	addi	s1,a1,8
  16:	ffe5091b          	addiw	s2,a0,-2
  1a:	02091793          	slli	a5,s2,0x20
  1e:	01d7d913          	srli	s2,a5,0x1d
  22:	05c1                	addi	a1,a1,16
  24:	992e                	add	s2,s2,a1
    fprintf(2, "usage: kill pid...\n");
    exit(1);
  }
  for(i=1; i<argc; i++)
    kill(atoi(argv[i]));
  26:	6088                	ld	a0,0(s1)
  28:	00000097          	auipc	ra,0x0
  2c:	1ae080e7          	jalr	430(ra) # 1d6 <atoi>
  30:	00000097          	auipc	ra,0x0
  34:	2d0080e7          	jalr	720(ra) # 300 <kill>
  for(i=1; i<argc; i++)
  38:	04a1                	addi	s1,s1,8
  3a:	ff2496e3          	bne	s1,s2,26 <main+0x26>
  exit(0);
  3e:	4501                	li	a0,0
  40:	00000097          	auipc	ra,0x0
  44:	290080e7          	jalr	656(ra) # 2d0 <exit>
    fprintf(2, "usage: kill pid...\n");
  48:	00000597          	auipc	a1,0x0
  4c:	7e058593          	addi	a1,a1,2016 # 828 <malloc+0xe6>
  50:	4509                	li	a0,2
  52:	00000097          	auipc	ra,0x0
  56:	60a080e7          	jalr	1546(ra) # 65c <fprintf>
    exit(1);
  5a:	4505                	li	a0,1
  5c:	00000097          	auipc	ra,0x0
  60:	274080e7          	jalr	628(ra) # 2d0 <exit>

0000000000000064 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  64:	1141                	addi	sp,sp,-16
  66:	e422                	sd	s0,8(sp)
  68:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  6a:	87aa                	mv	a5,a0
  6c:	0585                	addi	a1,a1,1
  6e:	0785                	addi	a5,a5,1
  70:	fff5c703          	lbu	a4,-1(a1)
  74:	fee78fa3          	sb	a4,-1(a5)
  78:	fb75                	bnez	a4,6c <strcpy+0x8>
    ;
  return os;
}
  7a:	6422                	ld	s0,8(sp)
  7c:	0141                	addi	sp,sp,16
  7e:	8082                	ret

0000000000000080 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80:	1141                	addi	sp,sp,-16
  82:	e422                	sd	s0,8(sp)
  84:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  86:	00054783          	lbu	a5,0(a0)
  8a:	cb91                	beqz	a5,9e <strcmp+0x1e>
  8c:	0005c703          	lbu	a4,0(a1)
  90:	00f71763          	bne	a4,a5,9e <strcmp+0x1e>
    p++, q++;
  94:	0505                	addi	a0,a0,1
  96:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  98:	00054783          	lbu	a5,0(a0)
  9c:	fbe5                	bnez	a5,8c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  9e:	0005c503          	lbu	a0,0(a1)
}
  a2:	40a7853b          	subw	a0,a5,a0
  a6:	6422                	ld	s0,8(sp)
  a8:	0141                	addi	sp,sp,16
  aa:	8082                	ret

00000000000000ac <strlen>:

uint
strlen(const char *s)
{
  ac:	1141                	addi	sp,sp,-16
  ae:	e422                	sd	s0,8(sp)
  b0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  b2:	00054783          	lbu	a5,0(a0)
  b6:	cf91                	beqz	a5,d2 <strlen+0x26>
  b8:	0505                	addi	a0,a0,1
  ba:	87aa                	mv	a5,a0
  bc:	4685                	li	a3,1
  be:	9e89                	subw	a3,a3,a0
  c0:	00f6853b          	addw	a0,a3,a5
  c4:	0785                	addi	a5,a5,1
  c6:	fff7c703          	lbu	a4,-1(a5)
  ca:	fb7d                	bnez	a4,c0 <strlen+0x14>
    ;
  return n;
}
  cc:	6422                	ld	s0,8(sp)
  ce:	0141                	addi	sp,sp,16
  d0:	8082                	ret
  for(n = 0; s[n]; n++)
  d2:	4501                	li	a0,0
  d4:	bfe5                	j	cc <strlen+0x20>

00000000000000d6 <memset>:

void*
memset(void *dst, int c, uint n)
{
  d6:	1141                	addi	sp,sp,-16
  d8:	e422                	sd	s0,8(sp)
  da:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  dc:	ca19                	beqz	a2,f2 <memset+0x1c>
  de:	87aa                	mv	a5,a0
  e0:	1602                	slli	a2,a2,0x20
  e2:	9201                	srli	a2,a2,0x20
  e4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  e8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  ec:	0785                	addi	a5,a5,1
  ee:	fee79de3          	bne	a5,a4,e8 <memset+0x12>
  }
  return dst;
}
  f2:	6422                	ld	s0,8(sp)
  f4:	0141                	addi	sp,sp,16
  f6:	8082                	ret

00000000000000f8 <strchr>:

char*
strchr(const char *s, char c)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e422                	sd	s0,8(sp)
  fc:	0800                	addi	s0,sp,16
  for(; *s; s++)
  fe:	00054783          	lbu	a5,0(a0)
 102:	cb99                	beqz	a5,118 <strchr+0x20>
    if(*s == c)
 104:	00f58763          	beq	a1,a5,112 <strchr+0x1a>
  for(; *s; s++)
 108:	0505                	addi	a0,a0,1
 10a:	00054783          	lbu	a5,0(a0)
 10e:	fbfd                	bnez	a5,104 <strchr+0xc>
      return (char*)s;
  return 0;
 110:	4501                	li	a0,0
}
 112:	6422                	ld	s0,8(sp)
 114:	0141                	addi	sp,sp,16
 116:	8082                	ret
  return 0;
 118:	4501                	li	a0,0
 11a:	bfe5                	j	112 <strchr+0x1a>

000000000000011c <gets>:

char*
gets(char *buf, int max)
{
 11c:	711d                	addi	sp,sp,-96
 11e:	ec86                	sd	ra,88(sp)
 120:	e8a2                	sd	s0,80(sp)
 122:	e4a6                	sd	s1,72(sp)
 124:	e0ca                	sd	s2,64(sp)
 126:	fc4e                	sd	s3,56(sp)
 128:	f852                	sd	s4,48(sp)
 12a:	f456                	sd	s5,40(sp)
 12c:	f05a                	sd	s6,32(sp)
 12e:	ec5e                	sd	s7,24(sp)
 130:	1080                	addi	s0,sp,96
 132:	8baa                	mv	s7,a0
 134:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 136:	892a                	mv	s2,a0
 138:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 13a:	4aa9                	li	s5,10
 13c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 13e:	89a6                	mv	s3,s1
 140:	2485                	addiw	s1,s1,1
 142:	0344d863          	bge	s1,s4,172 <gets+0x56>
    cc = read(0, &c, 1);
 146:	4605                	li	a2,1
 148:	faf40593          	addi	a1,s0,-81
 14c:	4501                	li	a0,0
 14e:	00000097          	auipc	ra,0x0
 152:	19a080e7          	jalr	410(ra) # 2e8 <read>
    if(cc < 1)
 156:	00a05e63          	blez	a0,172 <gets+0x56>
    buf[i++] = c;
 15a:	faf44783          	lbu	a5,-81(s0)
 15e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 162:	01578763          	beq	a5,s5,170 <gets+0x54>
 166:	0905                	addi	s2,s2,1
 168:	fd679be3          	bne	a5,s6,13e <gets+0x22>
  for(i=0; i+1 < max; ){
 16c:	89a6                	mv	s3,s1
 16e:	a011                	j	172 <gets+0x56>
 170:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 172:	99de                	add	s3,s3,s7
 174:	00098023          	sb	zero,0(s3)
  return buf;
}
 178:	855e                	mv	a0,s7
 17a:	60e6                	ld	ra,88(sp)
 17c:	6446                	ld	s0,80(sp)
 17e:	64a6                	ld	s1,72(sp)
 180:	6906                	ld	s2,64(sp)
 182:	79e2                	ld	s3,56(sp)
 184:	7a42                	ld	s4,48(sp)
 186:	7aa2                	ld	s5,40(sp)
 188:	7b02                	ld	s6,32(sp)
 18a:	6be2                	ld	s7,24(sp)
 18c:	6125                	addi	sp,sp,96
 18e:	8082                	ret

0000000000000190 <stat>:

int
stat(const char *n, struct stat *st)
{
 190:	1101                	addi	sp,sp,-32
 192:	ec06                	sd	ra,24(sp)
 194:	e822                	sd	s0,16(sp)
 196:	e426                	sd	s1,8(sp)
 198:	e04a                	sd	s2,0(sp)
 19a:	1000                	addi	s0,sp,32
 19c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 19e:	4581                	li	a1,0
 1a0:	00000097          	auipc	ra,0x0
 1a4:	170080e7          	jalr	368(ra) # 310 <open>
  if(fd < 0)
 1a8:	02054563          	bltz	a0,1d2 <stat+0x42>
 1ac:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ae:	85ca                	mv	a1,s2
 1b0:	00000097          	auipc	ra,0x0
 1b4:	178080e7          	jalr	376(ra) # 328 <fstat>
 1b8:	892a                	mv	s2,a0
  close(fd);
 1ba:	8526                	mv	a0,s1
 1bc:	00000097          	auipc	ra,0x0
 1c0:	13c080e7          	jalr	316(ra) # 2f8 <close>
  return r;
}
 1c4:	854a                	mv	a0,s2
 1c6:	60e2                	ld	ra,24(sp)
 1c8:	6442                	ld	s0,16(sp)
 1ca:	64a2                	ld	s1,8(sp)
 1cc:	6902                	ld	s2,0(sp)
 1ce:	6105                	addi	sp,sp,32
 1d0:	8082                	ret
    return -1;
 1d2:	597d                	li	s2,-1
 1d4:	bfc5                	j	1c4 <stat+0x34>

00000000000001d6 <atoi>:

int
atoi(const char *s)
{
 1d6:	1141                	addi	sp,sp,-16
 1d8:	e422                	sd	s0,8(sp)
 1da:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1dc:	00054683          	lbu	a3,0(a0)
 1e0:	fd06879b          	addiw	a5,a3,-48
 1e4:	0ff7f793          	zext.b	a5,a5
 1e8:	4625                	li	a2,9
 1ea:	02f66863          	bltu	a2,a5,21a <atoi+0x44>
 1ee:	872a                	mv	a4,a0
  n = 0;
 1f0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1f2:	0705                	addi	a4,a4,1
 1f4:	0025179b          	slliw	a5,a0,0x2
 1f8:	9fa9                	addw	a5,a5,a0
 1fa:	0017979b          	slliw	a5,a5,0x1
 1fe:	9fb5                	addw	a5,a5,a3
 200:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 204:	00074683          	lbu	a3,0(a4)
 208:	fd06879b          	addiw	a5,a3,-48
 20c:	0ff7f793          	zext.b	a5,a5
 210:	fef671e3          	bgeu	a2,a5,1f2 <atoi+0x1c>
  return n;
}
 214:	6422                	ld	s0,8(sp)
 216:	0141                	addi	sp,sp,16
 218:	8082                	ret
  n = 0;
 21a:	4501                	li	a0,0
 21c:	bfe5                	j	214 <atoi+0x3e>

000000000000021e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 21e:	1141                	addi	sp,sp,-16
 220:	e422                	sd	s0,8(sp)
 222:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 224:	02b57463          	bgeu	a0,a1,24c <memmove+0x2e>
    while(n-- > 0)
 228:	00c05f63          	blez	a2,246 <memmove+0x28>
 22c:	1602                	slli	a2,a2,0x20
 22e:	9201                	srli	a2,a2,0x20
 230:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 234:	872a                	mv	a4,a0
      *dst++ = *src++;
 236:	0585                	addi	a1,a1,1
 238:	0705                	addi	a4,a4,1
 23a:	fff5c683          	lbu	a3,-1(a1)
 23e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 242:	fee79ae3          	bne	a5,a4,236 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 246:	6422                	ld	s0,8(sp)
 248:	0141                	addi	sp,sp,16
 24a:	8082                	ret
    dst += n;
 24c:	00c50733          	add	a4,a0,a2
    src += n;
 250:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 252:	fec05ae3          	blez	a2,246 <memmove+0x28>
 256:	fff6079b          	addiw	a5,a2,-1
 25a:	1782                	slli	a5,a5,0x20
 25c:	9381                	srli	a5,a5,0x20
 25e:	fff7c793          	not	a5,a5
 262:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 264:	15fd                	addi	a1,a1,-1
 266:	177d                	addi	a4,a4,-1
 268:	0005c683          	lbu	a3,0(a1)
 26c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 270:	fee79ae3          	bne	a5,a4,264 <memmove+0x46>
 274:	bfc9                	j	246 <memmove+0x28>

0000000000000276 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 276:	1141                	addi	sp,sp,-16
 278:	e422                	sd	s0,8(sp)
 27a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 27c:	ca05                	beqz	a2,2ac <memcmp+0x36>
 27e:	fff6069b          	addiw	a3,a2,-1
 282:	1682                	slli	a3,a3,0x20
 284:	9281                	srli	a3,a3,0x20
 286:	0685                	addi	a3,a3,1
 288:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 28a:	00054783          	lbu	a5,0(a0)
 28e:	0005c703          	lbu	a4,0(a1)
 292:	00e79863          	bne	a5,a4,2a2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 296:	0505                	addi	a0,a0,1
    p2++;
 298:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 29a:	fed518e3          	bne	a0,a3,28a <memcmp+0x14>
  }
  return 0;
 29e:	4501                	li	a0,0
 2a0:	a019                	j	2a6 <memcmp+0x30>
      return *p1 - *p2;
 2a2:	40e7853b          	subw	a0,a5,a4
}
 2a6:	6422                	ld	s0,8(sp)
 2a8:	0141                	addi	sp,sp,16
 2aa:	8082                	ret
  return 0;
 2ac:	4501                	li	a0,0
 2ae:	bfe5                	j	2a6 <memcmp+0x30>

00000000000002b0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2b0:	1141                	addi	sp,sp,-16
 2b2:	e406                	sd	ra,8(sp)
 2b4:	e022                	sd	s0,0(sp)
 2b6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2b8:	00000097          	auipc	ra,0x0
 2bc:	f66080e7          	jalr	-154(ra) # 21e <memmove>
}
 2c0:	60a2                	ld	ra,8(sp)
 2c2:	6402                	ld	s0,0(sp)
 2c4:	0141                	addi	sp,sp,16
 2c6:	8082                	ret

00000000000002c8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2c8:	4885                	li	a7,1
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2d0:	4889                	li	a7,2
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2d8:	488d                	li	a7,3
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2e0:	4891                	li	a7,4
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <read>:
.global read
read:
 li a7, SYS_read
 2e8:	4895                	li	a7,5
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <write>:
.global write
write:
 li a7, SYS_write
 2f0:	48c1                	li	a7,16
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <close>:
.global close
close:
 li a7, SYS_close
 2f8:	48d5                	li	a7,21
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <kill>:
.global kill
kill:
 li a7, SYS_kill
 300:	4899                	li	a7,6
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <exec>:
.global exec
exec:
 li a7, SYS_exec
 308:	489d                	li	a7,7
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <open>:
.global open
open:
 li a7, SYS_open
 310:	48bd                	li	a7,15
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 318:	48c5                	li	a7,17
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 320:	48c9                	li	a7,18
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 328:	48a1                	li	a7,8
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <link>:
.global link
link:
 li a7, SYS_link
 330:	48cd                	li	a7,19
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 338:	48d1                	li	a7,20
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 340:	48a5                	li	a7,9
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <dup>:
.global dup
dup:
 li a7, SYS_dup
 348:	48a9                	li	a7,10
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 350:	48ad                	li	a7,11
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 358:	48b1                	li	a7,12
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 360:	48b5                	li	a7,13
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 368:	48b9                	li	a7,14
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 370:	48d9                	li	a7,22
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 378:	48dd                	li	a7,23
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 380:	48e1                	li	a7,24
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 388:	48e5                	li	a7,25
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <sem_init>:
.global sem_init
sem_init:
 li a7, SYS_sem_init
 390:	48e9                	li	a7,26
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <sem_destroy>:
.global sem_destroy
sem_destroy:
 li a7, SYS_sem_destroy
 398:	48ed                	li	a7,27
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <sem_wait>:
.global sem_wait
sem_wait:
 li a7, SYS_sem_wait
 3a0:	48f1                	li	a7,28
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <sem_post>:
.global sem_post
sem_post:
 li a7, SYS_sem_post
 3a8:	48f5                	li	a7,29
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3b0:	1101                	addi	sp,sp,-32
 3b2:	ec06                	sd	ra,24(sp)
 3b4:	e822                	sd	s0,16(sp)
 3b6:	1000                	addi	s0,sp,32
 3b8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3bc:	4605                	li	a2,1
 3be:	fef40593          	addi	a1,s0,-17
 3c2:	00000097          	auipc	ra,0x0
 3c6:	f2e080e7          	jalr	-210(ra) # 2f0 <write>
}
 3ca:	60e2                	ld	ra,24(sp)
 3cc:	6442                	ld	s0,16(sp)
 3ce:	6105                	addi	sp,sp,32
 3d0:	8082                	ret

00000000000003d2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3d2:	7139                	addi	sp,sp,-64
 3d4:	fc06                	sd	ra,56(sp)
 3d6:	f822                	sd	s0,48(sp)
 3d8:	f426                	sd	s1,40(sp)
 3da:	f04a                	sd	s2,32(sp)
 3dc:	ec4e                	sd	s3,24(sp)
 3de:	0080                	addi	s0,sp,64
 3e0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3e2:	c299                	beqz	a3,3e8 <printint+0x16>
 3e4:	0805c963          	bltz	a1,476 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3e8:	2581                	sext.w	a1,a1
  neg = 0;
 3ea:	4881                	li	a7,0
 3ec:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3f0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3f2:	2601                	sext.w	a2,a2
 3f4:	00000517          	auipc	a0,0x0
 3f8:	4ac50513          	addi	a0,a0,1196 # 8a0 <digits>
 3fc:	883a                	mv	a6,a4
 3fe:	2705                	addiw	a4,a4,1
 400:	02c5f7bb          	remuw	a5,a1,a2
 404:	1782                	slli	a5,a5,0x20
 406:	9381                	srli	a5,a5,0x20
 408:	97aa                	add	a5,a5,a0
 40a:	0007c783          	lbu	a5,0(a5)
 40e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 412:	0005879b          	sext.w	a5,a1
 416:	02c5d5bb          	divuw	a1,a1,a2
 41a:	0685                	addi	a3,a3,1
 41c:	fec7f0e3          	bgeu	a5,a2,3fc <printint+0x2a>
  if(neg)
 420:	00088c63          	beqz	a7,438 <printint+0x66>
    buf[i++] = '-';
 424:	fd070793          	addi	a5,a4,-48
 428:	00878733          	add	a4,a5,s0
 42c:	02d00793          	li	a5,45
 430:	fef70823          	sb	a5,-16(a4)
 434:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 438:	02e05863          	blez	a4,468 <printint+0x96>
 43c:	fc040793          	addi	a5,s0,-64
 440:	00e78933          	add	s2,a5,a4
 444:	fff78993          	addi	s3,a5,-1
 448:	99ba                	add	s3,s3,a4
 44a:	377d                	addiw	a4,a4,-1
 44c:	1702                	slli	a4,a4,0x20
 44e:	9301                	srli	a4,a4,0x20
 450:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 454:	fff94583          	lbu	a1,-1(s2)
 458:	8526                	mv	a0,s1
 45a:	00000097          	auipc	ra,0x0
 45e:	f56080e7          	jalr	-170(ra) # 3b0 <putc>
  while(--i >= 0)
 462:	197d                	addi	s2,s2,-1
 464:	ff3918e3          	bne	s2,s3,454 <printint+0x82>
}
 468:	70e2                	ld	ra,56(sp)
 46a:	7442                	ld	s0,48(sp)
 46c:	74a2                	ld	s1,40(sp)
 46e:	7902                	ld	s2,32(sp)
 470:	69e2                	ld	s3,24(sp)
 472:	6121                	addi	sp,sp,64
 474:	8082                	ret
    x = -xx;
 476:	40b005bb          	negw	a1,a1
    neg = 1;
 47a:	4885                	li	a7,1
    x = -xx;
 47c:	bf85                	j	3ec <printint+0x1a>

000000000000047e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 47e:	7119                	addi	sp,sp,-128
 480:	fc86                	sd	ra,120(sp)
 482:	f8a2                	sd	s0,112(sp)
 484:	f4a6                	sd	s1,104(sp)
 486:	f0ca                	sd	s2,96(sp)
 488:	ecce                	sd	s3,88(sp)
 48a:	e8d2                	sd	s4,80(sp)
 48c:	e4d6                	sd	s5,72(sp)
 48e:	e0da                	sd	s6,64(sp)
 490:	fc5e                	sd	s7,56(sp)
 492:	f862                	sd	s8,48(sp)
 494:	f466                	sd	s9,40(sp)
 496:	f06a                	sd	s10,32(sp)
 498:	ec6e                	sd	s11,24(sp)
 49a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 49c:	0005c903          	lbu	s2,0(a1)
 4a0:	18090f63          	beqz	s2,63e <vprintf+0x1c0>
 4a4:	8aaa                	mv	s5,a0
 4a6:	8b32                	mv	s6,a2
 4a8:	00158493          	addi	s1,a1,1
  state = 0;
 4ac:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4ae:	02500a13          	li	s4,37
 4b2:	4c55                	li	s8,21
 4b4:	00000c97          	auipc	s9,0x0
 4b8:	394c8c93          	addi	s9,s9,916 # 848 <malloc+0x106>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4bc:	02800d93          	li	s11,40
  putc(fd, 'x');
 4c0:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4c2:	00000b97          	auipc	s7,0x0
 4c6:	3deb8b93          	addi	s7,s7,990 # 8a0 <digits>
 4ca:	a839                	j	4e8 <vprintf+0x6a>
        putc(fd, c);
 4cc:	85ca                	mv	a1,s2
 4ce:	8556                	mv	a0,s5
 4d0:	00000097          	auipc	ra,0x0
 4d4:	ee0080e7          	jalr	-288(ra) # 3b0 <putc>
 4d8:	a019                	j	4de <vprintf+0x60>
    } else if(state == '%'){
 4da:	01498d63          	beq	s3,s4,4f4 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4de:	0485                	addi	s1,s1,1
 4e0:	fff4c903          	lbu	s2,-1(s1)
 4e4:	14090d63          	beqz	s2,63e <vprintf+0x1c0>
    if(state == 0){
 4e8:	fe0999e3          	bnez	s3,4da <vprintf+0x5c>
      if(c == '%'){
 4ec:	ff4910e3          	bne	s2,s4,4cc <vprintf+0x4e>
        state = '%';
 4f0:	89d2                	mv	s3,s4
 4f2:	b7f5                	j	4de <vprintf+0x60>
      if(c == 'd'){
 4f4:	11490c63          	beq	s2,s4,60c <vprintf+0x18e>
 4f8:	f9d9079b          	addiw	a5,s2,-99
 4fc:	0ff7f793          	zext.b	a5,a5
 500:	10fc6e63          	bltu	s8,a5,61c <vprintf+0x19e>
 504:	f9d9079b          	addiw	a5,s2,-99
 508:	0ff7f713          	zext.b	a4,a5
 50c:	10ec6863          	bltu	s8,a4,61c <vprintf+0x19e>
 510:	00271793          	slli	a5,a4,0x2
 514:	97e6                	add	a5,a5,s9
 516:	439c                	lw	a5,0(a5)
 518:	97e6                	add	a5,a5,s9
 51a:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 51c:	008b0913          	addi	s2,s6,8
 520:	4685                	li	a3,1
 522:	4629                	li	a2,10
 524:	000b2583          	lw	a1,0(s6)
 528:	8556                	mv	a0,s5
 52a:	00000097          	auipc	ra,0x0
 52e:	ea8080e7          	jalr	-344(ra) # 3d2 <printint>
 532:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 534:	4981                	li	s3,0
 536:	b765                	j	4de <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 538:	008b0913          	addi	s2,s6,8
 53c:	4681                	li	a3,0
 53e:	4629                	li	a2,10
 540:	000b2583          	lw	a1,0(s6)
 544:	8556                	mv	a0,s5
 546:	00000097          	auipc	ra,0x0
 54a:	e8c080e7          	jalr	-372(ra) # 3d2 <printint>
 54e:	8b4a                	mv	s6,s2
      state = 0;
 550:	4981                	li	s3,0
 552:	b771                	j	4de <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 554:	008b0913          	addi	s2,s6,8
 558:	4681                	li	a3,0
 55a:	866a                	mv	a2,s10
 55c:	000b2583          	lw	a1,0(s6)
 560:	8556                	mv	a0,s5
 562:	00000097          	auipc	ra,0x0
 566:	e70080e7          	jalr	-400(ra) # 3d2 <printint>
 56a:	8b4a                	mv	s6,s2
      state = 0;
 56c:	4981                	li	s3,0
 56e:	bf85                	j	4de <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 570:	008b0793          	addi	a5,s6,8
 574:	f8f43423          	sd	a5,-120(s0)
 578:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 57c:	03000593          	li	a1,48
 580:	8556                	mv	a0,s5
 582:	00000097          	auipc	ra,0x0
 586:	e2e080e7          	jalr	-466(ra) # 3b0 <putc>
  putc(fd, 'x');
 58a:	07800593          	li	a1,120
 58e:	8556                	mv	a0,s5
 590:	00000097          	auipc	ra,0x0
 594:	e20080e7          	jalr	-480(ra) # 3b0 <putc>
 598:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 59a:	03c9d793          	srli	a5,s3,0x3c
 59e:	97de                	add	a5,a5,s7
 5a0:	0007c583          	lbu	a1,0(a5)
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	e0a080e7          	jalr	-502(ra) # 3b0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5ae:	0992                	slli	s3,s3,0x4
 5b0:	397d                	addiw	s2,s2,-1
 5b2:	fe0914e3          	bnez	s2,59a <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5b6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	b70d                	j	4de <vprintf+0x60>
        s = va_arg(ap, char*);
 5be:	008b0913          	addi	s2,s6,8
 5c2:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5c6:	02098163          	beqz	s3,5e8 <vprintf+0x16a>
        while(*s != 0){
 5ca:	0009c583          	lbu	a1,0(s3)
 5ce:	c5ad                	beqz	a1,638 <vprintf+0x1ba>
          putc(fd, *s);
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	dde080e7          	jalr	-546(ra) # 3b0 <putc>
          s++;
 5da:	0985                	addi	s3,s3,1
        while(*s != 0){
 5dc:	0009c583          	lbu	a1,0(s3)
 5e0:	f9e5                	bnez	a1,5d0 <vprintf+0x152>
        s = va_arg(ap, char*);
 5e2:	8b4a                	mv	s6,s2
      state = 0;
 5e4:	4981                	li	s3,0
 5e6:	bde5                	j	4de <vprintf+0x60>
          s = "(null)";
 5e8:	00000997          	auipc	s3,0x0
 5ec:	25898993          	addi	s3,s3,600 # 840 <malloc+0xfe>
        while(*s != 0){
 5f0:	85ee                	mv	a1,s11
 5f2:	bff9                	j	5d0 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5f4:	008b0913          	addi	s2,s6,8
 5f8:	000b4583          	lbu	a1,0(s6)
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	db2080e7          	jalr	-590(ra) # 3b0 <putc>
 606:	8b4a                	mv	s6,s2
      state = 0;
 608:	4981                	li	s3,0
 60a:	bdd1                	j	4de <vprintf+0x60>
        putc(fd, c);
 60c:	85d2                	mv	a1,s4
 60e:	8556                	mv	a0,s5
 610:	00000097          	auipc	ra,0x0
 614:	da0080e7          	jalr	-608(ra) # 3b0 <putc>
      state = 0;
 618:	4981                	li	s3,0
 61a:	b5d1                	j	4de <vprintf+0x60>
        putc(fd, '%');
 61c:	85d2                	mv	a1,s4
 61e:	8556                	mv	a0,s5
 620:	00000097          	auipc	ra,0x0
 624:	d90080e7          	jalr	-624(ra) # 3b0 <putc>
        putc(fd, c);
 628:	85ca                	mv	a1,s2
 62a:	8556                	mv	a0,s5
 62c:	00000097          	auipc	ra,0x0
 630:	d84080e7          	jalr	-636(ra) # 3b0 <putc>
      state = 0;
 634:	4981                	li	s3,0
 636:	b565                	j	4de <vprintf+0x60>
        s = va_arg(ap, char*);
 638:	8b4a                	mv	s6,s2
      state = 0;
 63a:	4981                	li	s3,0
 63c:	b54d                	j	4de <vprintf+0x60>
    }
  }
}
 63e:	70e6                	ld	ra,120(sp)
 640:	7446                	ld	s0,112(sp)
 642:	74a6                	ld	s1,104(sp)
 644:	7906                	ld	s2,96(sp)
 646:	69e6                	ld	s3,88(sp)
 648:	6a46                	ld	s4,80(sp)
 64a:	6aa6                	ld	s5,72(sp)
 64c:	6b06                	ld	s6,64(sp)
 64e:	7be2                	ld	s7,56(sp)
 650:	7c42                	ld	s8,48(sp)
 652:	7ca2                	ld	s9,40(sp)
 654:	7d02                	ld	s10,32(sp)
 656:	6de2                	ld	s11,24(sp)
 658:	6109                	addi	sp,sp,128
 65a:	8082                	ret

000000000000065c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 65c:	715d                	addi	sp,sp,-80
 65e:	ec06                	sd	ra,24(sp)
 660:	e822                	sd	s0,16(sp)
 662:	1000                	addi	s0,sp,32
 664:	e010                	sd	a2,0(s0)
 666:	e414                	sd	a3,8(s0)
 668:	e818                	sd	a4,16(s0)
 66a:	ec1c                	sd	a5,24(s0)
 66c:	03043023          	sd	a6,32(s0)
 670:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 674:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 678:	8622                	mv	a2,s0
 67a:	00000097          	auipc	ra,0x0
 67e:	e04080e7          	jalr	-508(ra) # 47e <vprintf>
}
 682:	60e2                	ld	ra,24(sp)
 684:	6442                	ld	s0,16(sp)
 686:	6161                	addi	sp,sp,80
 688:	8082                	ret

000000000000068a <printf>:

void
printf(const char *fmt, ...)
{
 68a:	711d                	addi	sp,sp,-96
 68c:	ec06                	sd	ra,24(sp)
 68e:	e822                	sd	s0,16(sp)
 690:	1000                	addi	s0,sp,32
 692:	e40c                	sd	a1,8(s0)
 694:	e810                	sd	a2,16(s0)
 696:	ec14                	sd	a3,24(s0)
 698:	f018                	sd	a4,32(s0)
 69a:	f41c                	sd	a5,40(s0)
 69c:	03043823          	sd	a6,48(s0)
 6a0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6a4:	00840613          	addi	a2,s0,8
 6a8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ac:	85aa                	mv	a1,a0
 6ae:	4505                	li	a0,1
 6b0:	00000097          	auipc	ra,0x0
 6b4:	dce080e7          	jalr	-562(ra) # 47e <vprintf>
}
 6b8:	60e2                	ld	ra,24(sp)
 6ba:	6442                	ld	s0,16(sp)
 6bc:	6125                	addi	sp,sp,96
 6be:	8082                	ret

00000000000006c0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6c0:	1141                	addi	sp,sp,-16
 6c2:	e422                	sd	s0,8(sp)
 6c4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6c6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ca:	00000797          	auipc	a5,0x0
 6ce:	1ee7b783          	ld	a5,494(a5) # 8b8 <freep>
 6d2:	a02d                	j	6fc <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6d4:	4618                	lw	a4,8(a2)
 6d6:	9f2d                	addw	a4,a4,a1
 6d8:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6dc:	6398                	ld	a4,0(a5)
 6de:	6310                	ld	a2,0(a4)
 6e0:	a83d                	j	71e <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6e2:	ff852703          	lw	a4,-8(a0)
 6e6:	9f31                	addw	a4,a4,a2
 6e8:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6ea:	ff053683          	ld	a3,-16(a0)
 6ee:	a091                	j	732 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f0:	6398                	ld	a4,0(a5)
 6f2:	00e7e463          	bltu	a5,a4,6fa <free+0x3a>
 6f6:	00e6ea63          	bltu	a3,a4,70a <free+0x4a>
{
 6fa:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6fc:	fed7fae3          	bgeu	a5,a3,6f0 <free+0x30>
 700:	6398                	ld	a4,0(a5)
 702:	00e6e463          	bltu	a3,a4,70a <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 706:	fee7eae3          	bltu	a5,a4,6fa <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 70a:	ff852583          	lw	a1,-8(a0)
 70e:	6390                	ld	a2,0(a5)
 710:	02059813          	slli	a6,a1,0x20
 714:	01c85713          	srli	a4,a6,0x1c
 718:	9736                	add	a4,a4,a3
 71a:	fae60de3          	beq	a2,a4,6d4 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 71e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 722:	4790                	lw	a2,8(a5)
 724:	02061593          	slli	a1,a2,0x20
 728:	01c5d713          	srli	a4,a1,0x1c
 72c:	973e                	add	a4,a4,a5
 72e:	fae68ae3          	beq	a3,a4,6e2 <free+0x22>
    p->s.ptr = bp->s.ptr;
 732:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 734:	00000717          	auipc	a4,0x0
 738:	18f73223          	sd	a5,388(a4) # 8b8 <freep>
}
 73c:	6422                	ld	s0,8(sp)
 73e:	0141                	addi	sp,sp,16
 740:	8082                	ret

0000000000000742 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 742:	7139                	addi	sp,sp,-64
 744:	fc06                	sd	ra,56(sp)
 746:	f822                	sd	s0,48(sp)
 748:	f426                	sd	s1,40(sp)
 74a:	f04a                	sd	s2,32(sp)
 74c:	ec4e                	sd	s3,24(sp)
 74e:	e852                	sd	s4,16(sp)
 750:	e456                	sd	s5,8(sp)
 752:	e05a                	sd	s6,0(sp)
 754:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 756:	02051493          	slli	s1,a0,0x20
 75a:	9081                	srli	s1,s1,0x20
 75c:	04bd                	addi	s1,s1,15
 75e:	8091                	srli	s1,s1,0x4
 760:	0014899b          	addiw	s3,s1,1
 764:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 766:	00000517          	auipc	a0,0x0
 76a:	15253503          	ld	a0,338(a0) # 8b8 <freep>
 76e:	c515                	beqz	a0,79a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 770:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 772:	4798                	lw	a4,8(a5)
 774:	02977f63          	bgeu	a4,s1,7b2 <malloc+0x70>
 778:	8a4e                	mv	s4,s3
 77a:	0009871b          	sext.w	a4,s3
 77e:	6685                	lui	a3,0x1
 780:	00d77363          	bgeu	a4,a3,786 <malloc+0x44>
 784:	6a05                	lui	s4,0x1
 786:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 78a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 78e:	00000917          	auipc	s2,0x0
 792:	12a90913          	addi	s2,s2,298 # 8b8 <freep>
  if(p == (char*)-1)
 796:	5afd                	li	s5,-1
 798:	a895                	j	80c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 79a:	00000797          	auipc	a5,0x0
 79e:	12678793          	addi	a5,a5,294 # 8c0 <base>
 7a2:	00000717          	auipc	a4,0x0
 7a6:	10f73b23          	sd	a5,278(a4) # 8b8 <freep>
 7aa:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ac:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7b0:	b7e1                	j	778 <malloc+0x36>
      if(p->s.size == nunits)
 7b2:	02e48c63          	beq	s1,a4,7ea <malloc+0xa8>
        p->s.size -= nunits;
 7b6:	4137073b          	subw	a4,a4,s3
 7ba:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7bc:	02071693          	slli	a3,a4,0x20
 7c0:	01c6d713          	srli	a4,a3,0x1c
 7c4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7c6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7ca:	00000717          	auipc	a4,0x0
 7ce:	0ea73723          	sd	a0,238(a4) # 8b8 <freep>
      return (void*)(p + 1);
 7d2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7d6:	70e2                	ld	ra,56(sp)
 7d8:	7442                	ld	s0,48(sp)
 7da:	74a2                	ld	s1,40(sp)
 7dc:	7902                	ld	s2,32(sp)
 7de:	69e2                	ld	s3,24(sp)
 7e0:	6a42                	ld	s4,16(sp)
 7e2:	6aa2                	ld	s5,8(sp)
 7e4:	6b02                	ld	s6,0(sp)
 7e6:	6121                	addi	sp,sp,64
 7e8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7ea:	6398                	ld	a4,0(a5)
 7ec:	e118                	sd	a4,0(a0)
 7ee:	bff1                	j	7ca <malloc+0x88>
  hp->s.size = nu;
 7f0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7f4:	0541                	addi	a0,a0,16
 7f6:	00000097          	auipc	ra,0x0
 7fa:	eca080e7          	jalr	-310(ra) # 6c0 <free>
  return freep;
 7fe:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 802:	d971                	beqz	a0,7d6 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 804:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 806:	4798                	lw	a4,8(a5)
 808:	fa9775e3          	bgeu	a4,s1,7b2 <malloc+0x70>
    if(p == freep)
 80c:	00093703          	ld	a4,0(s2)
 810:	853e                	mv	a0,a5
 812:	fef719e3          	bne	a4,a5,804 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 816:	8552                	mv	a0,s4
 818:	00000097          	auipc	ra,0x0
 81c:	b40080e7          	jalr	-1216(ra) # 358 <sbrk>
  if(p == (char*)-1)
 820:	fd5518e3          	bne	a0,s5,7f0 <malloc+0xae>
        return 0;
 824:	4501                	li	a0,0
 826:	bf45                	j	7d6 <malloc+0x94>
