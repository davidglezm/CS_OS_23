
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/pstat.h"
#include "user/user.h"

int
main(int argc, char **argv)
{
   0:	81010113          	addi	sp,sp,-2032
   4:	7e113423          	sd	ra,2024(sp)
   8:	7e813023          	sd	s0,2016(sp)
   c:	7c913c23          	sd	s1,2008(sp)
  10:	7d213823          	sd	s2,2000(sp)
  14:	7d313423          	sd	s3,1992(sp)
  18:	7d413023          	sd	s4,1984(sp)
  1c:	7f010413          	addi	s0,sp,2032
  20:	dc010113          	addi	sp,sp,-576
    [RUNNABLE]  "runnable",
    [RUNNING]   "running ",
    [ZOMBIE]    "zombie  "
  };

  nprocs = getprocs(uproc);
  24:	757d                	lui	a0,0xfffff
  26:	5d050793          	addi	a5,a0,1488 # fffffffffffff5d0 <__global_pointer$+0xffffffffffffe437>
  2a:	00878533          	add	a0,a5,s0
  2e:	00000097          	auipc	ra,0x0
  32:	39e080e7          	jalr	926(ra) # 3cc <getprocs>
  if (nprocs < 0)
  36:	08054063          	bltz	a0,b6 <main+0xb6>
  3a:	892a                	mv	s2,a0
    exit(-1);

  printf("pid\tstate\t\tsize\tppid\tname\n");
  3c:	00001517          	auipc	a0,0x1
  40:	84c50513          	addi	a0,a0,-1972 # 888 <malloc+0xea>
  44:	00000097          	auipc	ra,0x0
  48:	6a2080e7          	jalr	1698(ra) # 6e6 <printf>
  for (i=0; i<nprocs; i++) {
  4c:	07205063          	blez	s2,ac <main+0xac>
  50:	77fd                	lui	a5,0xfffff
  52:	5d078793          	addi	a5,a5,1488 # fffffffffffff5d0 <__global_pointer$+0xffffffffffffe437>
  56:	97a2                	add	a5,a5,s0
  58:	01478493          	addi	s1,a5,20
  5c:	397d                	addiw	s2,s2,-1
  5e:	1902                	slli	s2,s2,0x20
  60:	02095913          	srli	s2,s2,0x20
  64:	02800713          	li	a4,40
  68:	02e90933          	mul	s2,s2,a4
  6c:	03c78793          	addi	a5,a5,60
  70:	993e                	add	s2,s2,a5
    state = states[uproc[i].state];
  72:	00001a17          	auipc	s4,0x1
  76:	886a0a13          	addi	s4,s4,-1914 # 8f8 <states.0>
    printf("%d\t%s\t%l\t%d\t%s\n", uproc[i].pid, state,
  7a:	00001997          	auipc	s3,0x1
  7e:	82e98993          	addi	s3,s3,-2002 # 8a8 <malloc+0x10a>
    state = states[uproc[i].state];
  82:	ff04e603          	lwu	a2,-16(s1)
  86:	060e                	slli	a2,a2,0x3
  88:	9652                	add	a2,a2,s4
    printf("%d\t%s\t%l\t%d\t%s\n", uproc[i].pid, state,
  8a:	87a6                	mv	a5,s1
  8c:	ffc4a703          	lw	a4,-4(s1)
  90:	ff44b683          	ld	a3,-12(s1)
  94:	6210                	ld	a2,0(a2)
  96:	fec4a583          	lw	a1,-20(s1)
  9a:	854e                	mv	a0,s3
  9c:	00000097          	auipc	ra,0x0
  a0:	64a080e7          	jalr	1610(ra) # 6e6 <printf>
  for (i=0; i<nprocs; i++) {
  a4:	02848493          	addi	s1,s1,40
  a8:	fd249de3          	bne	s1,s2,82 <main+0x82>
                   uproc[i].size, uproc[i].ppid, uproc[i].name);
  }

  exit(0);
  ac:	4501                	li	a0,0
  ae:	00000097          	auipc	ra,0x0
  b2:	27e080e7          	jalr	638(ra) # 32c <exit>
    exit(-1);
  b6:	557d                	li	a0,-1
  b8:	00000097          	auipc	ra,0x0
  bc:	274080e7          	jalr	628(ra) # 32c <exit>

00000000000000c0 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  c0:	1141                	addi	sp,sp,-16
  c2:	e422                	sd	s0,8(sp)
  c4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  c6:	87aa                	mv	a5,a0
  c8:	0585                	addi	a1,a1,1
  ca:	0785                	addi	a5,a5,1
  cc:	fff5c703          	lbu	a4,-1(a1)
  d0:	fee78fa3          	sb	a4,-1(a5)
  d4:	fb75                	bnez	a4,c8 <strcpy+0x8>
    ;
  return os;
}
  d6:	6422                	ld	s0,8(sp)
  d8:	0141                	addi	sp,sp,16
  da:	8082                	ret

00000000000000dc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  dc:	1141                	addi	sp,sp,-16
  de:	e422                	sd	s0,8(sp)
  e0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  e2:	00054783          	lbu	a5,0(a0)
  e6:	cb91                	beqz	a5,fa <strcmp+0x1e>
  e8:	0005c703          	lbu	a4,0(a1)
  ec:	00f71763          	bne	a4,a5,fa <strcmp+0x1e>
    p++, q++;
  f0:	0505                	addi	a0,a0,1
  f2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  f4:	00054783          	lbu	a5,0(a0)
  f8:	fbe5                	bnez	a5,e8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  fa:	0005c503          	lbu	a0,0(a1)
}
  fe:	40a7853b          	subw	a0,a5,a0
 102:	6422                	ld	s0,8(sp)
 104:	0141                	addi	sp,sp,16
 106:	8082                	ret

0000000000000108 <strlen>:

uint
strlen(const char *s)
{
 108:	1141                	addi	sp,sp,-16
 10a:	e422                	sd	s0,8(sp)
 10c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 10e:	00054783          	lbu	a5,0(a0)
 112:	cf91                	beqz	a5,12e <strlen+0x26>
 114:	0505                	addi	a0,a0,1
 116:	87aa                	mv	a5,a0
 118:	4685                	li	a3,1
 11a:	9e89                	subw	a3,a3,a0
 11c:	00f6853b          	addw	a0,a3,a5
 120:	0785                	addi	a5,a5,1
 122:	fff7c703          	lbu	a4,-1(a5)
 126:	fb7d                	bnez	a4,11c <strlen+0x14>
    ;
  return n;
}
 128:	6422                	ld	s0,8(sp)
 12a:	0141                	addi	sp,sp,16
 12c:	8082                	ret
  for(n = 0; s[n]; n++)
 12e:	4501                	li	a0,0
 130:	bfe5                	j	128 <strlen+0x20>

0000000000000132 <memset>:

void*
memset(void *dst, int c, uint n)
{
 132:	1141                	addi	sp,sp,-16
 134:	e422                	sd	s0,8(sp)
 136:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 138:	ca19                	beqz	a2,14e <memset+0x1c>
 13a:	87aa                	mv	a5,a0
 13c:	1602                	slli	a2,a2,0x20
 13e:	9201                	srli	a2,a2,0x20
 140:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 144:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 148:	0785                	addi	a5,a5,1
 14a:	fee79de3          	bne	a5,a4,144 <memset+0x12>
  }
  return dst;
}
 14e:	6422                	ld	s0,8(sp)
 150:	0141                	addi	sp,sp,16
 152:	8082                	ret

0000000000000154 <strchr>:

char*
strchr(const char *s, char c)
{
 154:	1141                	addi	sp,sp,-16
 156:	e422                	sd	s0,8(sp)
 158:	0800                	addi	s0,sp,16
  for(; *s; s++)
 15a:	00054783          	lbu	a5,0(a0)
 15e:	cb99                	beqz	a5,174 <strchr+0x20>
    if(*s == c)
 160:	00f58763          	beq	a1,a5,16e <strchr+0x1a>
  for(; *s; s++)
 164:	0505                	addi	a0,a0,1
 166:	00054783          	lbu	a5,0(a0)
 16a:	fbfd                	bnez	a5,160 <strchr+0xc>
      return (char*)s;
  return 0;
 16c:	4501                	li	a0,0
}
 16e:	6422                	ld	s0,8(sp)
 170:	0141                	addi	sp,sp,16
 172:	8082                	ret
  return 0;
 174:	4501                	li	a0,0
 176:	bfe5                	j	16e <strchr+0x1a>

0000000000000178 <gets>:

char*
gets(char *buf, int max)
{
 178:	711d                	addi	sp,sp,-96
 17a:	ec86                	sd	ra,88(sp)
 17c:	e8a2                	sd	s0,80(sp)
 17e:	e4a6                	sd	s1,72(sp)
 180:	e0ca                	sd	s2,64(sp)
 182:	fc4e                	sd	s3,56(sp)
 184:	f852                	sd	s4,48(sp)
 186:	f456                	sd	s5,40(sp)
 188:	f05a                	sd	s6,32(sp)
 18a:	ec5e                	sd	s7,24(sp)
 18c:	1080                	addi	s0,sp,96
 18e:	8baa                	mv	s7,a0
 190:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 192:	892a                	mv	s2,a0
 194:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 196:	4aa9                	li	s5,10
 198:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 19a:	89a6                	mv	s3,s1
 19c:	2485                	addiw	s1,s1,1
 19e:	0344d863          	bge	s1,s4,1ce <gets+0x56>
    cc = read(0, &c, 1);
 1a2:	4605                	li	a2,1
 1a4:	faf40593          	addi	a1,s0,-81
 1a8:	4501                	li	a0,0
 1aa:	00000097          	auipc	ra,0x0
 1ae:	19a080e7          	jalr	410(ra) # 344 <read>
    if(cc < 1)
 1b2:	00a05e63          	blez	a0,1ce <gets+0x56>
    buf[i++] = c;
 1b6:	faf44783          	lbu	a5,-81(s0)
 1ba:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1be:	01578763          	beq	a5,s5,1cc <gets+0x54>
 1c2:	0905                	addi	s2,s2,1
 1c4:	fd679be3          	bne	a5,s6,19a <gets+0x22>
  for(i=0; i+1 < max; ){
 1c8:	89a6                	mv	s3,s1
 1ca:	a011                	j	1ce <gets+0x56>
 1cc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ce:	99de                	add	s3,s3,s7
 1d0:	00098023          	sb	zero,0(s3)
  return buf;
}
 1d4:	855e                	mv	a0,s7
 1d6:	60e6                	ld	ra,88(sp)
 1d8:	6446                	ld	s0,80(sp)
 1da:	64a6                	ld	s1,72(sp)
 1dc:	6906                	ld	s2,64(sp)
 1de:	79e2                	ld	s3,56(sp)
 1e0:	7a42                	ld	s4,48(sp)
 1e2:	7aa2                	ld	s5,40(sp)
 1e4:	7b02                	ld	s6,32(sp)
 1e6:	6be2                	ld	s7,24(sp)
 1e8:	6125                	addi	sp,sp,96
 1ea:	8082                	ret

00000000000001ec <stat>:

int
stat(const char *n, struct stat *st)
{
 1ec:	1101                	addi	sp,sp,-32
 1ee:	ec06                	sd	ra,24(sp)
 1f0:	e822                	sd	s0,16(sp)
 1f2:	e426                	sd	s1,8(sp)
 1f4:	e04a                	sd	s2,0(sp)
 1f6:	1000                	addi	s0,sp,32
 1f8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1fa:	4581                	li	a1,0
 1fc:	00000097          	auipc	ra,0x0
 200:	170080e7          	jalr	368(ra) # 36c <open>
  if(fd < 0)
 204:	02054563          	bltz	a0,22e <stat+0x42>
 208:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 20a:	85ca                	mv	a1,s2
 20c:	00000097          	auipc	ra,0x0
 210:	178080e7          	jalr	376(ra) # 384 <fstat>
 214:	892a                	mv	s2,a0
  close(fd);
 216:	8526                	mv	a0,s1
 218:	00000097          	auipc	ra,0x0
 21c:	13c080e7          	jalr	316(ra) # 354 <close>
  return r;
}
 220:	854a                	mv	a0,s2
 222:	60e2                	ld	ra,24(sp)
 224:	6442                	ld	s0,16(sp)
 226:	64a2                	ld	s1,8(sp)
 228:	6902                	ld	s2,0(sp)
 22a:	6105                	addi	sp,sp,32
 22c:	8082                	ret
    return -1;
 22e:	597d                	li	s2,-1
 230:	bfc5                	j	220 <stat+0x34>

0000000000000232 <atoi>:

int
atoi(const char *s)
{
 232:	1141                	addi	sp,sp,-16
 234:	e422                	sd	s0,8(sp)
 236:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 238:	00054683          	lbu	a3,0(a0)
 23c:	fd06879b          	addiw	a5,a3,-48
 240:	0ff7f793          	zext.b	a5,a5
 244:	4625                	li	a2,9
 246:	02f66863          	bltu	a2,a5,276 <atoi+0x44>
 24a:	872a                	mv	a4,a0
  n = 0;
 24c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 24e:	0705                	addi	a4,a4,1
 250:	0025179b          	slliw	a5,a0,0x2
 254:	9fa9                	addw	a5,a5,a0
 256:	0017979b          	slliw	a5,a5,0x1
 25a:	9fb5                	addw	a5,a5,a3
 25c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 260:	00074683          	lbu	a3,0(a4)
 264:	fd06879b          	addiw	a5,a3,-48
 268:	0ff7f793          	zext.b	a5,a5
 26c:	fef671e3          	bgeu	a2,a5,24e <atoi+0x1c>
  return n;
}
 270:	6422                	ld	s0,8(sp)
 272:	0141                	addi	sp,sp,16
 274:	8082                	ret
  n = 0;
 276:	4501                	li	a0,0
 278:	bfe5                	j	270 <atoi+0x3e>

000000000000027a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 27a:	1141                	addi	sp,sp,-16
 27c:	e422                	sd	s0,8(sp)
 27e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 280:	02b57463          	bgeu	a0,a1,2a8 <memmove+0x2e>
    while(n-- > 0)
 284:	00c05f63          	blez	a2,2a2 <memmove+0x28>
 288:	1602                	slli	a2,a2,0x20
 28a:	9201                	srli	a2,a2,0x20
 28c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 290:	872a                	mv	a4,a0
      *dst++ = *src++;
 292:	0585                	addi	a1,a1,1
 294:	0705                	addi	a4,a4,1
 296:	fff5c683          	lbu	a3,-1(a1)
 29a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 29e:	fee79ae3          	bne	a5,a4,292 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2a2:	6422                	ld	s0,8(sp)
 2a4:	0141                	addi	sp,sp,16
 2a6:	8082                	ret
    dst += n;
 2a8:	00c50733          	add	a4,a0,a2
    src += n;
 2ac:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ae:	fec05ae3          	blez	a2,2a2 <memmove+0x28>
 2b2:	fff6079b          	addiw	a5,a2,-1
 2b6:	1782                	slli	a5,a5,0x20
 2b8:	9381                	srli	a5,a5,0x20
 2ba:	fff7c793          	not	a5,a5
 2be:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2c0:	15fd                	addi	a1,a1,-1
 2c2:	177d                	addi	a4,a4,-1
 2c4:	0005c683          	lbu	a3,0(a1)
 2c8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2cc:	fee79ae3          	bne	a5,a4,2c0 <memmove+0x46>
 2d0:	bfc9                	j	2a2 <memmove+0x28>

00000000000002d2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2d2:	1141                	addi	sp,sp,-16
 2d4:	e422                	sd	s0,8(sp)
 2d6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2d8:	ca05                	beqz	a2,308 <memcmp+0x36>
 2da:	fff6069b          	addiw	a3,a2,-1
 2de:	1682                	slli	a3,a3,0x20
 2e0:	9281                	srli	a3,a3,0x20
 2e2:	0685                	addi	a3,a3,1
 2e4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2e6:	00054783          	lbu	a5,0(a0)
 2ea:	0005c703          	lbu	a4,0(a1)
 2ee:	00e79863          	bne	a5,a4,2fe <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2f2:	0505                	addi	a0,a0,1
    p2++;
 2f4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2f6:	fed518e3          	bne	a0,a3,2e6 <memcmp+0x14>
  }
  return 0;
 2fa:	4501                	li	a0,0
 2fc:	a019                	j	302 <memcmp+0x30>
      return *p1 - *p2;
 2fe:	40e7853b          	subw	a0,a5,a4
}
 302:	6422                	ld	s0,8(sp)
 304:	0141                	addi	sp,sp,16
 306:	8082                	ret
  return 0;
 308:	4501                	li	a0,0
 30a:	bfe5                	j	302 <memcmp+0x30>

000000000000030c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 30c:	1141                	addi	sp,sp,-16
 30e:	e406                	sd	ra,8(sp)
 310:	e022                	sd	s0,0(sp)
 312:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 314:	00000097          	auipc	ra,0x0
 318:	f66080e7          	jalr	-154(ra) # 27a <memmove>
}
 31c:	60a2                	ld	ra,8(sp)
 31e:	6402                	ld	s0,0(sp)
 320:	0141                	addi	sp,sp,16
 322:	8082                	ret

0000000000000324 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 324:	4885                	li	a7,1
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <exit>:
.global exit
exit:
 li a7, SYS_exit
 32c:	4889                	li	a7,2
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <wait>:
.global wait
wait:
 li a7, SYS_wait
 334:	488d                	li	a7,3
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 33c:	4891                	li	a7,4
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <read>:
.global read
read:
 li a7, SYS_read
 344:	4895                	li	a7,5
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <write>:
.global write
write:
 li a7, SYS_write
 34c:	48c1                	li	a7,16
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <close>:
.global close
close:
 li a7, SYS_close
 354:	48d5                	li	a7,21
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <kill>:
.global kill
kill:
 li a7, SYS_kill
 35c:	4899                	li	a7,6
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <exec>:
.global exec
exec:
 li a7, SYS_exec
 364:	489d                	li	a7,7
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <open>:
.global open
open:
 li a7, SYS_open
 36c:	48bd                	li	a7,15
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 374:	48c5                	li	a7,17
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 37c:	48c9                	li	a7,18
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 384:	48a1                	li	a7,8
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <link>:
.global link
link:
 li a7, SYS_link
 38c:	48cd                	li	a7,19
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 394:	48d1                	li	a7,20
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 39c:	48a5                	li	a7,9
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3a4:	48a9                	li	a7,10
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3ac:	48ad                	li	a7,11
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3b4:	48b1                	li	a7,12
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3bc:	48b5                	li	a7,13
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3c4:	48b9                	li	a7,14
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 3cc:	48d9                	li	a7,22
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 3d4:	48dd                	li	a7,23
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 3dc:	48e1                	li	a7,24
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 3e4:	48e5                	li	a7,25
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <sem_init>:
.global sem_init
sem_init:
 li a7, SYS_sem_init
 3ec:	48e9                	li	a7,26
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <sem_destroy>:
.global sem_destroy
sem_destroy:
 li a7, SYS_sem_destroy
 3f4:	48ed                	li	a7,27
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <sem_wait>:
.global sem_wait
sem_wait:
 li a7, SYS_sem_wait
 3fc:	48f1                	li	a7,28
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <sem_post>:
.global sem_post
sem_post:
 li a7, SYS_sem_post
 404:	48f5                	li	a7,29
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 40c:	1101                	addi	sp,sp,-32
 40e:	ec06                	sd	ra,24(sp)
 410:	e822                	sd	s0,16(sp)
 412:	1000                	addi	s0,sp,32
 414:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 418:	4605                	li	a2,1
 41a:	fef40593          	addi	a1,s0,-17
 41e:	00000097          	auipc	ra,0x0
 422:	f2e080e7          	jalr	-210(ra) # 34c <write>
}
 426:	60e2                	ld	ra,24(sp)
 428:	6442                	ld	s0,16(sp)
 42a:	6105                	addi	sp,sp,32
 42c:	8082                	ret

000000000000042e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 42e:	7139                	addi	sp,sp,-64
 430:	fc06                	sd	ra,56(sp)
 432:	f822                	sd	s0,48(sp)
 434:	f426                	sd	s1,40(sp)
 436:	f04a                	sd	s2,32(sp)
 438:	ec4e                	sd	s3,24(sp)
 43a:	0080                	addi	s0,sp,64
 43c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 43e:	c299                	beqz	a3,444 <printint+0x16>
 440:	0805c963          	bltz	a1,4d2 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 444:	2581                	sext.w	a1,a1
  neg = 0;
 446:	4881                	li	a7,0
 448:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 44c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 44e:	2601                	sext.w	a2,a2
 450:	00000517          	auipc	a0,0x0
 454:	53850513          	addi	a0,a0,1336 # 988 <digits>
 458:	883a                	mv	a6,a4
 45a:	2705                	addiw	a4,a4,1
 45c:	02c5f7bb          	remuw	a5,a1,a2
 460:	1782                	slli	a5,a5,0x20
 462:	9381                	srli	a5,a5,0x20
 464:	97aa                	add	a5,a5,a0
 466:	0007c783          	lbu	a5,0(a5)
 46a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 46e:	0005879b          	sext.w	a5,a1
 472:	02c5d5bb          	divuw	a1,a1,a2
 476:	0685                	addi	a3,a3,1
 478:	fec7f0e3          	bgeu	a5,a2,458 <printint+0x2a>
  if(neg)
 47c:	00088c63          	beqz	a7,494 <printint+0x66>
    buf[i++] = '-';
 480:	fd070793          	addi	a5,a4,-48
 484:	00878733          	add	a4,a5,s0
 488:	02d00793          	li	a5,45
 48c:	fef70823          	sb	a5,-16(a4)
 490:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 494:	02e05863          	blez	a4,4c4 <printint+0x96>
 498:	fc040793          	addi	a5,s0,-64
 49c:	00e78933          	add	s2,a5,a4
 4a0:	fff78993          	addi	s3,a5,-1
 4a4:	99ba                	add	s3,s3,a4
 4a6:	377d                	addiw	a4,a4,-1
 4a8:	1702                	slli	a4,a4,0x20
 4aa:	9301                	srli	a4,a4,0x20
 4ac:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4b0:	fff94583          	lbu	a1,-1(s2)
 4b4:	8526                	mv	a0,s1
 4b6:	00000097          	auipc	ra,0x0
 4ba:	f56080e7          	jalr	-170(ra) # 40c <putc>
  while(--i >= 0)
 4be:	197d                	addi	s2,s2,-1
 4c0:	ff3918e3          	bne	s2,s3,4b0 <printint+0x82>
}
 4c4:	70e2                	ld	ra,56(sp)
 4c6:	7442                	ld	s0,48(sp)
 4c8:	74a2                	ld	s1,40(sp)
 4ca:	7902                	ld	s2,32(sp)
 4cc:	69e2                	ld	s3,24(sp)
 4ce:	6121                	addi	sp,sp,64
 4d0:	8082                	ret
    x = -xx;
 4d2:	40b005bb          	negw	a1,a1
    neg = 1;
 4d6:	4885                	li	a7,1
    x = -xx;
 4d8:	bf85                	j	448 <printint+0x1a>

00000000000004da <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4da:	7119                	addi	sp,sp,-128
 4dc:	fc86                	sd	ra,120(sp)
 4de:	f8a2                	sd	s0,112(sp)
 4e0:	f4a6                	sd	s1,104(sp)
 4e2:	f0ca                	sd	s2,96(sp)
 4e4:	ecce                	sd	s3,88(sp)
 4e6:	e8d2                	sd	s4,80(sp)
 4e8:	e4d6                	sd	s5,72(sp)
 4ea:	e0da                	sd	s6,64(sp)
 4ec:	fc5e                	sd	s7,56(sp)
 4ee:	f862                	sd	s8,48(sp)
 4f0:	f466                	sd	s9,40(sp)
 4f2:	f06a                	sd	s10,32(sp)
 4f4:	ec6e                	sd	s11,24(sp)
 4f6:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4f8:	0005c903          	lbu	s2,0(a1)
 4fc:	18090f63          	beqz	s2,69a <vprintf+0x1c0>
 500:	8aaa                	mv	s5,a0
 502:	8b32                	mv	s6,a2
 504:	00158493          	addi	s1,a1,1
  state = 0;
 508:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 50a:	02500a13          	li	s4,37
 50e:	4c55                	li	s8,21
 510:	00000c97          	auipc	s9,0x0
 514:	420c8c93          	addi	s9,s9,1056 # 930 <states.0+0x38>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 518:	02800d93          	li	s11,40
  putc(fd, 'x');
 51c:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 51e:	00000b97          	auipc	s7,0x0
 522:	46ab8b93          	addi	s7,s7,1130 # 988 <digits>
 526:	a839                	j	544 <vprintf+0x6a>
        putc(fd, c);
 528:	85ca                	mv	a1,s2
 52a:	8556                	mv	a0,s5
 52c:	00000097          	auipc	ra,0x0
 530:	ee0080e7          	jalr	-288(ra) # 40c <putc>
 534:	a019                	j	53a <vprintf+0x60>
    } else if(state == '%'){
 536:	01498d63          	beq	s3,s4,550 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 53a:	0485                	addi	s1,s1,1
 53c:	fff4c903          	lbu	s2,-1(s1)
 540:	14090d63          	beqz	s2,69a <vprintf+0x1c0>
    if(state == 0){
 544:	fe0999e3          	bnez	s3,536 <vprintf+0x5c>
      if(c == '%'){
 548:	ff4910e3          	bne	s2,s4,528 <vprintf+0x4e>
        state = '%';
 54c:	89d2                	mv	s3,s4
 54e:	b7f5                	j	53a <vprintf+0x60>
      if(c == 'd'){
 550:	11490c63          	beq	s2,s4,668 <vprintf+0x18e>
 554:	f9d9079b          	addiw	a5,s2,-99
 558:	0ff7f793          	zext.b	a5,a5
 55c:	10fc6e63          	bltu	s8,a5,678 <vprintf+0x19e>
 560:	f9d9079b          	addiw	a5,s2,-99
 564:	0ff7f713          	zext.b	a4,a5
 568:	10ec6863          	bltu	s8,a4,678 <vprintf+0x19e>
 56c:	00271793          	slli	a5,a4,0x2
 570:	97e6                	add	a5,a5,s9
 572:	439c                	lw	a5,0(a5)
 574:	97e6                	add	a5,a5,s9
 576:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 578:	008b0913          	addi	s2,s6,8
 57c:	4685                	li	a3,1
 57e:	4629                	li	a2,10
 580:	000b2583          	lw	a1,0(s6)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	ea8080e7          	jalr	-344(ra) # 42e <printint>
 58e:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 590:	4981                	li	s3,0
 592:	b765                	j	53a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 594:	008b0913          	addi	s2,s6,8
 598:	4681                	li	a3,0
 59a:	4629                	li	a2,10
 59c:	000b2583          	lw	a1,0(s6)
 5a0:	8556                	mv	a0,s5
 5a2:	00000097          	auipc	ra,0x0
 5a6:	e8c080e7          	jalr	-372(ra) # 42e <printint>
 5aa:	8b4a                	mv	s6,s2
      state = 0;
 5ac:	4981                	li	s3,0
 5ae:	b771                	j	53a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5b0:	008b0913          	addi	s2,s6,8
 5b4:	4681                	li	a3,0
 5b6:	866a                	mv	a2,s10
 5b8:	000b2583          	lw	a1,0(s6)
 5bc:	8556                	mv	a0,s5
 5be:	00000097          	auipc	ra,0x0
 5c2:	e70080e7          	jalr	-400(ra) # 42e <printint>
 5c6:	8b4a                	mv	s6,s2
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	bf85                	j	53a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5cc:	008b0793          	addi	a5,s6,8
 5d0:	f8f43423          	sd	a5,-120(s0)
 5d4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5d8:	03000593          	li	a1,48
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	e2e080e7          	jalr	-466(ra) # 40c <putc>
  putc(fd, 'x');
 5e6:	07800593          	li	a1,120
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e20080e7          	jalr	-480(ra) # 40c <putc>
 5f4:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f6:	03c9d793          	srli	a5,s3,0x3c
 5fa:	97de                	add	a5,a5,s7
 5fc:	0007c583          	lbu	a1,0(a5)
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	e0a080e7          	jalr	-502(ra) # 40c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 60a:	0992                	slli	s3,s3,0x4
 60c:	397d                	addiw	s2,s2,-1
 60e:	fe0914e3          	bnez	s2,5f6 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 612:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 616:	4981                	li	s3,0
 618:	b70d                	j	53a <vprintf+0x60>
        s = va_arg(ap, char*);
 61a:	008b0913          	addi	s2,s6,8
 61e:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 622:	02098163          	beqz	s3,644 <vprintf+0x16a>
        while(*s != 0){
 626:	0009c583          	lbu	a1,0(s3)
 62a:	c5ad                	beqz	a1,694 <vprintf+0x1ba>
          putc(fd, *s);
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	dde080e7          	jalr	-546(ra) # 40c <putc>
          s++;
 636:	0985                	addi	s3,s3,1
        while(*s != 0){
 638:	0009c583          	lbu	a1,0(s3)
 63c:	f9e5                	bnez	a1,62c <vprintf+0x152>
        s = va_arg(ap, char*);
 63e:	8b4a                	mv	s6,s2
      state = 0;
 640:	4981                	li	s3,0
 642:	bde5                	j	53a <vprintf+0x60>
          s = "(null)";
 644:	00000997          	auipc	s3,0x0
 648:	2e498993          	addi	s3,s3,740 # 928 <states.0+0x30>
        while(*s != 0){
 64c:	85ee                	mv	a1,s11
 64e:	bff9                	j	62c <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 650:	008b0913          	addi	s2,s6,8
 654:	000b4583          	lbu	a1,0(s6)
 658:	8556                	mv	a0,s5
 65a:	00000097          	auipc	ra,0x0
 65e:	db2080e7          	jalr	-590(ra) # 40c <putc>
 662:	8b4a                	mv	s6,s2
      state = 0;
 664:	4981                	li	s3,0
 666:	bdd1                	j	53a <vprintf+0x60>
        putc(fd, c);
 668:	85d2                	mv	a1,s4
 66a:	8556                	mv	a0,s5
 66c:	00000097          	auipc	ra,0x0
 670:	da0080e7          	jalr	-608(ra) # 40c <putc>
      state = 0;
 674:	4981                	li	s3,0
 676:	b5d1                	j	53a <vprintf+0x60>
        putc(fd, '%');
 678:	85d2                	mv	a1,s4
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	d90080e7          	jalr	-624(ra) # 40c <putc>
        putc(fd, c);
 684:	85ca                	mv	a1,s2
 686:	8556                	mv	a0,s5
 688:	00000097          	auipc	ra,0x0
 68c:	d84080e7          	jalr	-636(ra) # 40c <putc>
      state = 0;
 690:	4981                	li	s3,0
 692:	b565                	j	53a <vprintf+0x60>
        s = va_arg(ap, char*);
 694:	8b4a                	mv	s6,s2
      state = 0;
 696:	4981                	li	s3,0
 698:	b54d                	j	53a <vprintf+0x60>
    }
  }
}
 69a:	70e6                	ld	ra,120(sp)
 69c:	7446                	ld	s0,112(sp)
 69e:	74a6                	ld	s1,104(sp)
 6a0:	7906                	ld	s2,96(sp)
 6a2:	69e6                	ld	s3,88(sp)
 6a4:	6a46                	ld	s4,80(sp)
 6a6:	6aa6                	ld	s5,72(sp)
 6a8:	6b06                	ld	s6,64(sp)
 6aa:	7be2                	ld	s7,56(sp)
 6ac:	7c42                	ld	s8,48(sp)
 6ae:	7ca2                	ld	s9,40(sp)
 6b0:	7d02                	ld	s10,32(sp)
 6b2:	6de2                	ld	s11,24(sp)
 6b4:	6109                	addi	sp,sp,128
 6b6:	8082                	ret

00000000000006b8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6b8:	715d                	addi	sp,sp,-80
 6ba:	ec06                	sd	ra,24(sp)
 6bc:	e822                	sd	s0,16(sp)
 6be:	1000                	addi	s0,sp,32
 6c0:	e010                	sd	a2,0(s0)
 6c2:	e414                	sd	a3,8(s0)
 6c4:	e818                	sd	a4,16(s0)
 6c6:	ec1c                	sd	a5,24(s0)
 6c8:	03043023          	sd	a6,32(s0)
 6cc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6d0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6d4:	8622                	mv	a2,s0
 6d6:	00000097          	auipc	ra,0x0
 6da:	e04080e7          	jalr	-508(ra) # 4da <vprintf>
}
 6de:	60e2                	ld	ra,24(sp)
 6e0:	6442                	ld	s0,16(sp)
 6e2:	6161                	addi	sp,sp,80
 6e4:	8082                	ret

00000000000006e6 <printf>:

void
printf(const char *fmt, ...)
{
 6e6:	711d                	addi	sp,sp,-96
 6e8:	ec06                	sd	ra,24(sp)
 6ea:	e822                	sd	s0,16(sp)
 6ec:	1000                	addi	s0,sp,32
 6ee:	e40c                	sd	a1,8(s0)
 6f0:	e810                	sd	a2,16(s0)
 6f2:	ec14                	sd	a3,24(s0)
 6f4:	f018                	sd	a4,32(s0)
 6f6:	f41c                	sd	a5,40(s0)
 6f8:	03043823          	sd	a6,48(s0)
 6fc:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 700:	00840613          	addi	a2,s0,8
 704:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 708:	85aa                	mv	a1,a0
 70a:	4505                	li	a0,1
 70c:	00000097          	auipc	ra,0x0
 710:	dce080e7          	jalr	-562(ra) # 4da <vprintf>
}
 714:	60e2                	ld	ra,24(sp)
 716:	6442                	ld	s0,16(sp)
 718:	6125                	addi	sp,sp,96
 71a:	8082                	ret

000000000000071c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 71c:	1141                	addi	sp,sp,-16
 71e:	e422                	sd	s0,8(sp)
 720:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 722:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 726:	00000797          	auipc	a5,0x0
 72a:	27a7b783          	ld	a5,634(a5) # 9a0 <freep>
 72e:	a02d                	j	758 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 730:	4618                	lw	a4,8(a2)
 732:	9f2d                	addw	a4,a4,a1
 734:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 738:	6398                	ld	a4,0(a5)
 73a:	6310                	ld	a2,0(a4)
 73c:	a83d                	j	77a <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 73e:	ff852703          	lw	a4,-8(a0)
 742:	9f31                	addw	a4,a4,a2
 744:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 746:	ff053683          	ld	a3,-16(a0)
 74a:	a091                	j	78e <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 74c:	6398                	ld	a4,0(a5)
 74e:	00e7e463          	bltu	a5,a4,756 <free+0x3a>
 752:	00e6ea63          	bltu	a3,a4,766 <free+0x4a>
{
 756:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 758:	fed7fae3          	bgeu	a5,a3,74c <free+0x30>
 75c:	6398                	ld	a4,0(a5)
 75e:	00e6e463          	bltu	a3,a4,766 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 762:	fee7eae3          	bltu	a5,a4,756 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 766:	ff852583          	lw	a1,-8(a0)
 76a:	6390                	ld	a2,0(a5)
 76c:	02059813          	slli	a6,a1,0x20
 770:	01c85713          	srli	a4,a6,0x1c
 774:	9736                	add	a4,a4,a3
 776:	fae60de3          	beq	a2,a4,730 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 77a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 77e:	4790                	lw	a2,8(a5)
 780:	02061593          	slli	a1,a2,0x20
 784:	01c5d713          	srli	a4,a1,0x1c
 788:	973e                	add	a4,a4,a5
 78a:	fae68ae3          	beq	a3,a4,73e <free+0x22>
    p->s.ptr = bp->s.ptr;
 78e:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 790:	00000717          	auipc	a4,0x0
 794:	20f73823          	sd	a5,528(a4) # 9a0 <freep>
}
 798:	6422                	ld	s0,8(sp)
 79a:	0141                	addi	sp,sp,16
 79c:	8082                	ret

000000000000079e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 79e:	7139                	addi	sp,sp,-64
 7a0:	fc06                	sd	ra,56(sp)
 7a2:	f822                	sd	s0,48(sp)
 7a4:	f426                	sd	s1,40(sp)
 7a6:	f04a                	sd	s2,32(sp)
 7a8:	ec4e                	sd	s3,24(sp)
 7aa:	e852                	sd	s4,16(sp)
 7ac:	e456                	sd	s5,8(sp)
 7ae:	e05a                	sd	s6,0(sp)
 7b0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7b2:	02051493          	slli	s1,a0,0x20
 7b6:	9081                	srli	s1,s1,0x20
 7b8:	04bd                	addi	s1,s1,15
 7ba:	8091                	srli	s1,s1,0x4
 7bc:	0014899b          	addiw	s3,s1,1
 7c0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7c2:	00000517          	auipc	a0,0x0
 7c6:	1de53503          	ld	a0,478(a0) # 9a0 <freep>
 7ca:	c515                	beqz	a0,7f6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7cc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7ce:	4798                	lw	a4,8(a5)
 7d0:	02977f63          	bgeu	a4,s1,80e <malloc+0x70>
 7d4:	8a4e                	mv	s4,s3
 7d6:	0009871b          	sext.w	a4,s3
 7da:	6685                	lui	a3,0x1
 7dc:	00d77363          	bgeu	a4,a3,7e2 <malloc+0x44>
 7e0:	6a05                	lui	s4,0x1
 7e2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7e6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7ea:	00000917          	auipc	s2,0x0
 7ee:	1b690913          	addi	s2,s2,438 # 9a0 <freep>
  if(p == (char*)-1)
 7f2:	5afd                	li	s5,-1
 7f4:	a895                	j	868 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7f6:	00000797          	auipc	a5,0x0
 7fa:	1b278793          	addi	a5,a5,434 # 9a8 <base>
 7fe:	00000717          	auipc	a4,0x0
 802:	1af73123          	sd	a5,418(a4) # 9a0 <freep>
 806:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 808:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 80c:	b7e1                	j	7d4 <malloc+0x36>
      if(p->s.size == nunits)
 80e:	02e48c63          	beq	s1,a4,846 <malloc+0xa8>
        p->s.size -= nunits;
 812:	4137073b          	subw	a4,a4,s3
 816:	c798                	sw	a4,8(a5)
        p += p->s.size;
 818:	02071693          	slli	a3,a4,0x20
 81c:	01c6d713          	srli	a4,a3,0x1c
 820:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 822:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 826:	00000717          	auipc	a4,0x0
 82a:	16a73d23          	sd	a0,378(a4) # 9a0 <freep>
      return (void*)(p + 1);
 82e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 832:	70e2                	ld	ra,56(sp)
 834:	7442                	ld	s0,48(sp)
 836:	74a2                	ld	s1,40(sp)
 838:	7902                	ld	s2,32(sp)
 83a:	69e2                	ld	s3,24(sp)
 83c:	6a42                	ld	s4,16(sp)
 83e:	6aa2                	ld	s5,8(sp)
 840:	6b02                	ld	s6,0(sp)
 842:	6121                	addi	sp,sp,64
 844:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 846:	6398                	ld	a4,0(a5)
 848:	e118                	sd	a4,0(a0)
 84a:	bff1                	j	826 <malloc+0x88>
  hp->s.size = nu;
 84c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 850:	0541                	addi	a0,a0,16
 852:	00000097          	auipc	ra,0x0
 856:	eca080e7          	jalr	-310(ra) # 71c <free>
  return freep;
 85a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 85e:	d971                	beqz	a0,832 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 860:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 862:	4798                	lw	a4,8(a5)
 864:	fa9775e3          	bgeu	a4,s1,80e <malloc+0x70>
    if(p == freep)
 868:	00093703          	ld	a4,0(s2)
 86c:	853e                	mv	a0,a5
 86e:	fef719e3          	bne	a4,a5,860 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 872:	8552                	mv	a0,s4
 874:	00000097          	auipc	ra,0x0
 878:	b40080e7          	jalr	-1216(ra) # 3b4 <sbrk>
  if(p == (char*)-1)
 87c:	fd5518e3          	bne	a0,s5,84c <malloc+0xae>
        return 0;
 880:	4501                	li	a0,0
 882:	bf45                	j	832 <malloc+0x94>
