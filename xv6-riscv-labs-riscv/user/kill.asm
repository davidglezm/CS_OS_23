
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
  4c:	7c058593          	addi	a1,a1,1984 # 808 <malloc+0xe6>
  50:	4509                	li	a0,2
  52:	00000097          	auipc	ra,0x0
  56:	5ea080e7          	jalr	1514(ra) # 63c <fprintf>
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

0000000000000390 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 390:	1101                	addi	sp,sp,-32
 392:	ec06                	sd	ra,24(sp)
 394:	e822                	sd	s0,16(sp)
 396:	1000                	addi	s0,sp,32
 398:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 39c:	4605                	li	a2,1
 39e:	fef40593          	addi	a1,s0,-17
 3a2:	00000097          	auipc	ra,0x0
 3a6:	f4e080e7          	jalr	-178(ra) # 2f0 <write>
}
 3aa:	60e2                	ld	ra,24(sp)
 3ac:	6442                	ld	s0,16(sp)
 3ae:	6105                	addi	sp,sp,32
 3b0:	8082                	ret

00000000000003b2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3b2:	7139                	addi	sp,sp,-64
 3b4:	fc06                	sd	ra,56(sp)
 3b6:	f822                	sd	s0,48(sp)
 3b8:	f426                	sd	s1,40(sp)
 3ba:	f04a                	sd	s2,32(sp)
 3bc:	ec4e                	sd	s3,24(sp)
 3be:	0080                	addi	s0,sp,64
 3c0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3c2:	c299                	beqz	a3,3c8 <printint+0x16>
 3c4:	0805c963          	bltz	a1,456 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3c8:	2581                	sext.w	a1,a1
  neg = 0;
 3ca:	4881                	li	a7,0
 3cc:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3d0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3d2:	2601                	sext.w	a2,a2
 3d4:	00000517          	auipc	a0,0x0
 3d8:	4ac50513          	addi	a0,a0,1196 # 880 <digits>
 3dc:	883a                	mv	a6,a4
 3de:	2705                	addiw	a4,a4,1
 3e0:	02c5f7bb          	remuw	a5,a1,a2
 3e4:	1782                	slli	a5,a5,0x20
 3e6:	9381                	srli	a5,a5,0x20
 3e8:	97aa                	add	a5,a5,a0
 3ea:	0007c783          	lbu	a5,0(a5)
 3ee:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3f2:	0005879b          	sext.w	a5,a1
 3f6:	02c5d5bb          	divuw	a1,a1,a2
 3fa:	0685                	addi	a3,a3,1
 3fc:	fec7f0e3          	bgeu	a5,a2,3dc <printint+0x2a>
  if(neg)
 400:	00088c63          	beqz	a7,418 <printint+0x66>
    buf[i++] = '-';
 404:	fd070793          	addi	a5,a4,-48
 408:	00878733          	add	a4,a5,s0
 40c:	02d00793          	li	a5,45
 410:	fef70823          	sb	a5,-16(a4)
 414:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 418:	02e05863          	blez	a4,448 <printint+0x96>
 41c:	fc040793          	addi	a5,s0,-64
 420:	00e78933          	add	s2,a5,a4
 424:	fff78993          	addi	s3,a5,-1
 428:	99ba                	add	s3,s3,a4
 42a:	377d                	addiw	a4,a4,-1
 42c:	1702                	slli	a4,a4,0x20
 42e:	9301                	srli	a4,a4,0x20
 430:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 434:	fff94583          	lbu	a1,-1(s2)
 438:	8526                	mv	a0,s1
 43a:	00000097          	auipc	ra,0x0
 43e:	f56080e7          	jalr	-170(ra) # 390 <putc>
  while(--i >= 0)
 442:	197d                	addi	s2,s2,-1
 444:	ff3918e3          	bne	s2,s3,434 <printint+0x82>
}
 448:	70e2                	ld	ra,56(sp)
 44a:	7442                	ld	s0,48(sp)
 44c:	74a2                	ld	s1,40(sp)
 44e:	7902                	ld	s2,32(sp)
 450:	69e2                	ld	s3,24(sp)
 452:	6121                	addi	sp,sp,64
 454:	8082                	ret
    x = -xx;
 456:	40b005bb          	negw	a1,a1
    neg = 1;
 45a:	4885                	li	a7,1
    x = -xx;
 45c:	bf85                	j	3cc <printint+0x1a>

000000000000045e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 45e:	7119                	addi	sp,sp,-128
 460:	fc86                	sd	ra,120(sp)
 462:	f8a2                	sd	s0,112(sp)
 464:	f4a6                	sd	s1,104(sp)
 466:	f0ca                	sd	s2,96(sp)
 468:	ecce                	sd	s3,88(sp)
 46a:	e8d2                	sd	s4,80(sp)
 46c:	e4d6                	sd	s5,72(sp)
 46e:	e0da                	sd	s6,64(sp)
 470:	fc5e                	sd	s7,56(sp)
 472:	f862                	sd	s8,48(sp)
 474:	f466                	sd	s9,40(sp)
 476:	f06a                	sd	s10,32(sp)
 478:	ec6e                	sd	s11,24(sp)
 47a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 47c:	0005c903          	lbu	s2,0(a1)
 480:	18090f63          	beqz	s2,61e <vprintf+0x1c0>
 484:	8aaa                	mv	s5,a0
 486:	8b32                	mv	s6,a2
 488:	00158493          	addi	s1,a1,1
  state = 0;
 48c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 48e:	02500a13          	li	s4,37
 492:	4c55                	li	s8,21
 494:	00000c97          	auipc	s9,0x0
 498:	394c8c93          	addi	s9,s9,916 # 828 <malloc+0x106>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 49c:	02800d93          	li	s11,40
  putc(fd, 'x');
 4a0:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4a2:	00000b97          	auipc	s7,0x0
 4a6:	3deb8b93          	addi	s7,s7,990 # 880 <digits>
 4aa:	a839                	j	4c8 <vprintf+0x6a>
        putc(fd, c);
 4ac:	85ca                	mv	a1,s2
 4ae:	8556                	mv	a0,s5
 4b0:	00000097          	auipc	ra,0x0
 4b4:	ee0080e7          	jalr	-288(ra) # 390 <putc>
 4b8:	a019                	j	4be <vprintf+0x60>
    } else if(state == '%'){
 4ba:	01498d63          	beq	s3,s4,4d4 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4be:	0485                	addi	s1,s1,1
 4c0:	fff4c903          	lbu	s2,-1(s1)
 4c4:	14090d63          	beqz	s2,61e <vprintf+0x1c0>
    if(state == 0){
 4c8:	fe0999e3          	bnez	s3,4ba <vprintf+0x5c>
      if(c == '%'){
 4cc:	ff4910e3          	bne	s2,s4,4ac <vprintf+0x4e>
        state = '%';
 4d0:	89d2                	mv	s3,s4
 4d2:	b7f5                	j	4be <vprintf+0x60>
      if(c == 'd'){
 4d4:	11490c63          	beq	s2,s4,5ec <vprintf+0x18e>
 4d8:	f9d9079b          	addiw	a5,s2,-99
 4dc:	0ff7f793          	zext.b	a5,a5
 4e0:	10fc6e63          	bltu	s8,a5,5fc <vprintf+0x19e>
 4e4:	f9d9079b          	addiw	a5,s2,-99
 4e8:	0ff7f713          	zext.b	a4,a5
 4ec:	10ec6863          	bltu	s8,a4,5fc <vprintf+0x19e>
 4f0:	00271793          	slli	a5,a4,0x2
 4f4:	97e6                	add	a5,a5,s9
 4f6:	439c                	lw	a5,0(a5)
 4f8:	97e6                	add	a5,a5,s9
 4fa:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4fc:	008b0913          	addi	s2,s6,8
 500:	4685                	li	a3,1
 502:	4629                	li	a2,10
 504:	000b2583          	lw	a1,0(s6)
 508:	8556                	mv	a0,s5
 50a:	00000097          	auipc	ra,0x0
 50e:	ea8080e7          	jalr	-344(ra) # 3b2 <printint>
 512:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 514:	4981                	li	s3,0
 516:	b765                	j	4be <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 518:	008b0913          	addi	s2,s6,8
 51c:	4681                	li	a3,0
 51e:	4629                	li	a2,10
 520:	000b2583          	lw	a1,0(s6)
 524:	8556                	mv	a0,s5
 526:	00000097          	auipc	ra,0x0
 52a:	e8c080e7          	jalr	-372(ra) # 3b2 <printint>
 52e:	8b4a                	mv	s6,s2
      state = 0;
 530:	4981                	li	s3,0
 532:	b771                	j	4be <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 534:	008b0913          	addi	s2,s6,8
 538:	4681                	li	a3,0
 53a:	866a                	mv	a2,s10
 53c:	000b2583          	lw	a1,0(s6)
 540:	8556                	mv	a0,s5
 542:	00000097          	auipc	ra,0x0
 546:	e70080e7          	jalr	-400(ra) # 3b2 <printint>
 54a:	8b4a                	mv	s6,s2
      state = 0;
 54c:	4981                	li	s3,0
 54e:	bf85                	j	4be <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 550:	008b0793          	addi	a5,s6,8
 554:	f8f43423          	sd	a5,-120(s0)
 558:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 55c:	03000593          	li	a1,48
 560:	8556                	mv	a0,s5
 562:	00000097          	auipc	ra,0x0
 566:	e2e080e7          	jalr	-466(ra) # 390 <putc>
  putc(fd, 'x');
 56a:	07800593          	li	a1,120
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e20080e7          	jalr	-480(ra) # 390 <putc>
 578:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 57a:	03c9d793          	srli	a5,s3,0x3c
 57e:	97de                	add	a5,a5,s7
 580:	0007c583          	lbu	a1,0(a5)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e0a080e7          	jalr	-502(ra) # 390 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 58e:	0992                	slli	s3,s3,0x4
 590:	397d                	addiw	s2,s2,-1
 592:	fe0914e3          	bnez	s2,57a <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 596:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 59a:	4981                	li	s3,0
 59c:	b70d                	j	4be <vprintf+0x60>
        s = va_arg(ap, char*);
 59e:	008b0913          	addi	s2,s6,8
 5a2:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5a6:	02098163          	beqz	s3,5c8 <vprintf+0x16a>
        while(*s != 0){
 5aa:	0009c583          	lbu	a1,0(s3)
 5ae:	c5ad                	beqz	a1,618 <vprintf+0x1ba>
          putc(fd, *s);
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	dde080e7          	jalr	-546(ra) # 390 <putc>
          s++;
 5ba:	0985                	addi	s3,s3,1
        while(*s != 0){
 5bc:	0009c583          	lbu	a1,0(s3)
 5c0:	f9e5                	bnez	a1,5b0 <vprintf+0x152>
        s = va_arg(ap, char*);
 5c2:	8b4a                	mv	s6,s2
      state = 0;
 5c4:	4981                	li	s3,0
 5c6:	bde5                	j	4be <vprintf+0x60>
          s = "(null)";
 5c8:	00000997          	auipc	s3,0x0
 5cc:	25898993          	addi	s3,s3,600 # 820 <malloc+0xfe>
        while(*s != 0){
 5d0:	85ee                	mv	a1,s11
 5d2:	bff9                	j	5b0 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5d4:	008b0913          	addi	s2,s6,8
 5d8:	000b4583          	lbu	a1,0(s6)
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	db2080e7          	jalr	-590(ra) # 390 <putc>
 5e6:	8b4a                	mv	s6,s2
      state = 0;
 5e8:	4981                	li	s3,0
 5ea:	bdd1                	j	4be <vprintf+0x60>
        putc(fd, c);
 5ec:	85d2                	mv	a1,s4
 5ee:	8556                	mv	a0,s5
 5f0:	00000097          	auipc	ra,0x0
 5f4:	da0080e7          	jalr	-608(ra) # 390 <putc>
      state = 0;
 5f8:	4981                	li	s3,0
 5fa:	b5d1                	j	4be <vprintf+0x60>
        putc(fd, '%');
 5fc:	85d2                	mv	a1,s4
 5fe:	8556                	mv	a0,s5
 600:	00000097          	auipc	ra,0x0
 604:	d90080e7          	jalr	-624(ra) # 390 <putc>
        putc(fd, c);
 608:	85ca                	mv	a1,s2
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	d84080e7          	jalr	-636(ra) # 390 <putc>
      state = 0;
 614:	4981                	li	s3,0
 616:	b565                	j	4be <vprintf+0x60>
        s = va_arg(ap, char*);
 618:	8b4a                	mv	s6,s2
      state = 0;
 61a:	4981                	li	s3,0
 61c:	b54d                	j	4be <vprintf+0x60>
    }
  }
}
 61e:	70e6                	ld	ra,120(sp)
 620:	7446                	ld	s0,112(sp)
 622:	74a6                	ld	s1,104(sp)
 624:	7906                	ld	s2,96(sp)
 626:	69e6                	ld	s3,88(sp)
 628:	6a46                	ld	s4,80(sp)
 62a:	6aa6                	ld	s5,72(sp)
 62c:	6b06                	ld	s6,64(sp)
 62e:	7be2                	ld	s7,56(sp)
 630:	7c42                	ld	s8,48(sp)
 632:	7ca2                	ld	s9,40(sp)
 634:	7d02                	ld	s10,32(sp)
 636:	6de2                	ld	s11,24(sp)
 638:	6109                	addi	sp,sp,128
 63a:	8082                	ret

000000000000063c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 63c:	715d                	addi	sp,sp,-80
 63e:	ec06                	sd	ra,24(sp)
 640:	e822                	sd	s0,16(sp)
 642:	1000                	addi	s0,sp,32
 644:	e010                	sd	a2,0(s0)
 646:	e414                	sd	a3,8(s0)
 648:	e818                	sd	a4,16(s0)
 64a:	ec1c                	sd	a5,24(s0)
 64c:	03043023          	sd	a6,32(s0)
 650:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 654:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 658:	8622                	mv	a2,s0
 65a:	00000097          	auipc	ra,0x0
 65e:	e04080e7          	jalr	-508(ra) # 45e <vprintf>
}
 662:	60e2                	ld	ra,24(sp)
 664:	6442                	ld	s0,16(sp)
 666:	6161                	addi	sp,sp,80
 668:	8082                	ret

000000000000066a <printf>:

void
printf(const char *fmt, ...)
{
 66a:	711d                	addi	sp,sp,-96
 66c:	ec06                	sd	ra,24(sp)
 66e:	e822                	sd	s0,16(sp)
 670:	1000                	addi	s0,sp,32
 672:	e40c                	sd	a1,8(s0)
 674:	e810                	sd	a2,16(s0)
 676:	ec14                	sd	a3,24(s0)
 678:	f018                	sd	a4,32(s0)
 67a:	f41c                	sd	a5,40(s0)
 67c:	03043823          	sd	a6,48(s0)
 680:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 684:	00840613          	addi	a2,s0,8
 688:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 68c:	85aa                	mv	a1,a0
 68e:	4505                	li	a0,1
 690:	00000097          	auipc	ra,0x0
 694:	dce080e7          	jalr	-562(ra) # 45e <vprintf>
}
 698:	60e2                	ld	ra,24(sp)
 69a:	6442                	ld	s0,16(sp)
 69c:	6125                	addi	sp,sp,96
 69e:	8082                	ret

00000000000006a0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6a0:	1141                	addi	sp,sp,-16
 6a2:	e422                	sd	s0,8(sp)
 6a4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6a6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6aa:	00000797          	auipc	a5,0x0
 6ae:	1ee7b783          	ld	a5,494(a5) # 898 <freep>
 6b2:	a02d                	j	6dc <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6b4:	4618                	lw	a4,8(a2)
 6b6:	9f2d                	addw	a4,a4,a1
 6b8:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6bc:	6398                	ld	a4,0(a5)
 6be:	6310                	ld	a2,0(a4)
 6c0:	a83d                	j	6fe <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6c2:	ff852703          	lw	a4,-8(a0)
 6c6:	9f31                	addw	a4,a4,a2
 6c8:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6ca:	ff053683          	ld	a3,-16(a0)
 6ce:	a091                	j	712 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6d0:	6398                	ld	a4,0(a5)
 6d2:	00e7e463          	bltu	a5,a4,6da <free+0x3a>
 6d6:	00e6ea63          	bltu	a3,a4,6ea <free+0x4a>
{
 6da:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6dc:	fed7fae3          	bgeu	a5,a3,6d0 <free+0x30>
 6e0:	6398                	ld	a4,0(a5)
 6e2:	00e6e463          	bltu	a3,a4,6ea <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e6:	fee7eae3          	bltu	a5,a4,6da <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6ea:	ff852583          	lw	a1,-8(a0)
 6ee:	6390                	ld	a2,0(a5)
 6f0:	02059813          	slli	a6,a1,0x20
 6f4:	01c85713          	srli	a4,a6,0x1c
 6f8:	9736                	add	a4,a4,a3
 6fa:	fae60de3          	beq	a2,a4,6b4 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6fe:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 702:	4790                	lw	a2,8(a5)
 704:	02061593          	slli	a1,a2,0x20
 708:	01c5d713          	srli	a4,a1,0x1c
 70c:	973e                	add	a4,a4,a5
 70e:	fae68ae3          	beq	a3,a4,6c2 <free+0x22>
    p->s.ptr = bp->s.ptr;
 712:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 714:	00000717          	auipc	a4,0x0
 718:	18f73223          	sd	a5,388(a4) # 898 <freep>
}
 71c:	6422                	ld	s0,8(sp)
 71e:	0141                	addi	sp,sp,16
 720:	8082                	ret

0000000000000722 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 722:	7139                	addi	sp,sp,-64
 724:	fc06                	sd	ra,56(sp)
 726:	f822                	sd	s0,48(sp)
 728:	f426                	sd	s1,40(sp)
 72a:	f04a                	sd	s2,32(sp)
 72c:	ec4e                	sd	s3,24(sp)
 72e:	e852                	sd	s4,16(sp)
 730:	e456                	sd	s5,8(sp)
 732:	e05a                	sd	s6,0(sp)
 734:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 736:	02051493          	slli	s1,a0,0x20
 73a:	9081                	srli	s1,s1,0x20
 73c:	04bd                	addi	s1,s1,15
 73e:	8091                	srli	s1,s1,0x4
 740:	0014899b          	addiw	s3,s1,1
 744:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 746:	00000517          	auipc	a0,0x0
 74a:	15253503          	ld	a0,338(a0) # 898 <freep>
 74e:	c515                	beqz	a0,77a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 750:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 752:	4798                	lw	a4,8(a5)
 754:	02977f63          	bgeu	a4,s1,792 <malloc+0x70>
 758:	8a4e                	mv	s4,s3
 75a:	0009871b          	sext.w	a4,s3
 75e:	6685                	lui	a3,0x1
 760:	00d77363          	bgeu	a4,a3,766 <malloc+0x44>
 764:	6a05                	lui	s4,0x1
 766:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 76a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 76e:	00000917          	auipc	s2,0x0
 772:	12a90913          	addi	s2,s2,298 # 898 <freep>
  if(p == (char*)-1)
 776:	5afd                	li	s5,-1
 778:	a895                	j	7ec <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 77a:	00000797          	auipc	a5,0x0
 77e:	12678793          	addi	a5,a5,294 # 8a0 <base>
 782:	00000717          	auipc	a4,0x0
 786:	10f73b23          	sd	a5,278(a4) # 898 <freep>
 78a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 78c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 790:	b7e1                	j	758 <malloc+0x36>
      if(p->s.size == nunits)
 792:	02e48c63          	beq	s1,a4,7ca <malloc+0xa8>
        p->s.size -= nunits;
 796:	4137073b          	subw	a4,a4,s3
 79a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 79c:	02071693          	slli	a3,a4,0x20
 7a0:	01c6d713          	srli	a4,a3,0x1c
 7a4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7a6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7aa:	00000717          	auipc	a4,0x0
 7ae:	0ea73723          	sd	a0,238(a4) # 898 <freep>
      return (void*)(p + 1);
 7b2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7b6:	70e2                	ld	ra,56(sp)
 7b8:	7442                	ld	s0,48(sp)
 7ba:	74a2                	ld	s1,40(sp)
 7bc:	7902                	ld	s2,32(sp)
 7be:	69e2                	ld	s3,24(sp)
 7c0:	6a42                	ld	s4,16(sp)
 7c2:	6aa2                	ld	s5,8(sp)
 7c4:	6b02                	ld	s6,0(sp)
 7c6:	6121                	addi	sp,sp,64
 7c8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7ca:	6398                	ld	a4,0(a5)
 7cc:	e118                	sd	a4,0(a0)
 7ce:	bff1                	j	7aa <malloc+0x88>
  hp->s.size = nu;
 7d0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7d4:	0541                	addi	a0,a0,16
 7d6:	00000097          	auipc	ra,0x0
 7da:	eca080e7          	jalr	-310(ra) # 6a0 <free>
  return freep;
 7de:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7e2:	d971                	beqz	a0,7b6 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e6:	4798                	lw	a4,8(a5)
 7e8:	fa9775e3          	bgeu	a4,s1,792 <malloc+0x70>
    if(p == freep)
 7ec:	00093703          	ld	a4,0(s2)
 7f0:	853e                	mv	a0,a5
 7f2:	fef719e3          	bne	a4,a5,7e4 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7f6:	8552                	mv	a0,s4
 7f8:	00000097          	auipc	ra,0x0
 7fc:	b60080e7          	jalr	-1184(ra) # 358 <sbrk>
  if(p == (char*)-1)
 800:	fd5518e3          	bne	a0,s5,7d0 <malloc+0xae>
        return 0;
 804:	4501                	li	a0,0
 806:	bf45                	j	7b6 <malloc+0x94>
