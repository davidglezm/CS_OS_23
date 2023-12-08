
user/_pstree:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <mktree>:

struct pstat uproc[NPROC];
int nprocs;

void mktree(int indent, int pid)
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	e852                	sd	s4,16(sp)
   e:	e456                	sd	s5,8(sp)
  10:	e05a                	sd	s6,0(sp)
  12:	0080                	addi	s0,sp,64
  14:	89ae                	mv	s3,a1
  int found = 0;
  int i = 0;

  while (!found && i<nprocs) {
  16:	00001697          	auipc	a3,0x1
  1a:	9a26a683          	lw	a3,-1630(a3) # 9b8 <nprocs>
  1e:	02d05163          	blez	a3,40 <mktree+0x40>
  22:	8a2a                	mv	s4,a0
  24:	00001a97          	auipc	s5,0x1
  28:	9a4a8a93          	addi	s5,s5,-1628 # 9c8 <uproc>
  2c:	87d6                	mv	a5,s5
  int i = 0;
  2e:	4481                	li	s1,0
    if (uproc[i].pid == pid)
  30:	4398                	lw	a4,0(a5)
  32:	03370963          	beq	a4,s3,64 <mktree+0x64>
      found = 1;
    else
      i++;
  36:	2485                	addiw	s1,s1,1
  while (!found && i<nprocs) {
  38:	02878793          	addi	a5,a5,40
  3c:	fed49ae3          	bne	s1,a3,30 <mktree+0x30>
  }
  if (!found) {
    printf("pid %d not found\n", pid);
  40:	85ce                	mv	a1,s3
  42:	00001517          	auipc	a0,0x1
  46:	8e650513          	addi	a0,a0,-1818 # 928 <malloc+0xfc>
  4a:	00000097          	auipc	ra,0x0
  4e:	72a080e7          	jalr	1834(ra) # 774 <printf>
    return;
  52:	a071                	j	de <mktree+0xde>
  for (int j=0; j<indent; j++)
    printf("  ");
  printf("%s(%d)\n", uproc[i].name, uproc[i].pid);
  for (i=0; i<nprocs; i++)
    if (uproc[i].ppid == pid) {
      mktree(indent+1, uproc[i].pid);
  54:	000aa583          	lw	a1,0(s5)
  58:	8552                	mv	a0,s4
  5a:	00000097          	auipc	ra,0x0
  5e:	fa6080e7          	jalr	-90(ra) # 0 <mktree>
  62:	a0bd                	j	d0 <mktree+0xd0>
  for (int j=0; j<indent; j++)
  64:	4901                	li	s2,0
    printf("  ");
  66:	00001b17          	auipc	s6,0x1
  6a:	8b2b0b13          	addi	s6,s6,-1870 # 918 <malloc+0xec>
  for (int j=0; j<indent; j++)
  6e:	01405a63          	blez	s4,82 <mktree+0x82>
    printf("  ");
  72:	855a                	mv	a0,s6
  74:	00000097          	auipc	ra,0x0
  78:	700080e7          	jalr	1792(ra) # 774 <printf>
  for (int j=0; j<indent; j++)
  7c:	2905                	addiw	s2,s2,1
  7e:	ff2a1ae3          	bne	s4,s2,72 <mktree+0x72>
  printf("%s(%d)\n", uproc[i].name, uproc[i].pid);
  82:	00001597          	auipc	a1,0x1
  86:	94658593          	addi	a1,a1,-1722 # 9c8 <uproc>
  8a:	00249793          	slli	a5,s1,0x2
  8e:	00978733          	add	a4,a5,s1
  92:	070e                	slli	a4,a4,0x3
  94:	972e                	add	a4,a4,a1
  96:	97a6                	add	a5,a5,s1
  98:	078e                	slli	a5,a5,0x3
  9a:	07d1                	addi	a5,a5,20
  9c:	4310                	lw	a2,0(a4)
  9e:	95be                	add	a1,a1,a5
  a0:	00001517          	auipc	a0,0x1
  a4:	88050513          	addi	a0,a0,-1920 # 920 <malloc+0xf4>
  a8:	00000097          	auipc	ra,0x0
  ac:	6cc080e7          	jalr	1740(ra) # 774 <printf>
  for (i=0; i<nprocs; i++)
  b0:	00001797          	auipc	a5,0x1
  b4:	9087a783          	lw	a5,-1784(a5) # 9b8 <nprocs>
  b8:	02f05363          	blez	a5,de <mktree+0xde>
  bc:	4481                	li	s1,0
      mktree(indent+1, uproc[i].pid);
  be:	2a05                	addiw	s4,s4,1
  for (i=0; i<nprocs; i++)
  c0:	00001917          	auipc	s2,0x1
  c4:	8f890913          	addi	s2,s2,-1800 # 9b8 <nprocs>
    if (uproc[i].ppid == pid) {
  c8:	010aa783          	lw	a5,16(s5)
  cc:	f93784e3          	beq	a5,s3,54 <mktree+0x54>
  for (i=0; i<nprocs; i++)
  d0:	2485                	addiw	s1,s1,1
  d2:	028a8a93          	addi	s5,s5,40
  d6:	00092783          	lw	a5,0(s2)
  da:	fef4c7e3          	blt	s1,a5,c8 <mktree+0xc8>
    }
  return;
}
  de:	70e2                	ld	ra,56(sp)
  e0:	7442                	ld	s0,48(sp)
  e2:	74a2                	ld	s1,40(sp)
  e4:	7902                	ld	s2,32(sp)
  e6:	69e2                	ld	s3,24(sp)
  e8:	6a42                	ld	s4,16(sp)
  ea:	6aa2                	ld	s5,8(sp)
  ec:	6b02                	ld	s6,0(sp)
  ee:	6121                	addi	sp,sp,64
  f0:	8082                	ret

00000000000000f2 <main>:

int
main(int argc, char **argv)
{
  f2:	1101                	addi	sp,sp,-32
  f4:	ec06                	sd	ra,24(sp)
  f6:	e822                	sd	s0,16(sp)
  f8:	e426                	sd	s1,8(sp)
  fa:	1000                	addi	s0,sp,32
  int pid = 1;

  if (argc == 2)
  fc:	4789                	li	a5,2
  int pid = 1;
  fe:	4485                	li	s1,1
  if (argc == 2)
 100:	02f50b63          	beq	a0,a5,136 <main+0x44>
    pid = atoi(argv[1]);
  nprocs = getprocs(uproc);
 104:	00001517          	auipc	a0,0x1
 108:	8c450513          	addi	a0,a0,-1852 # 9c8 <uproc>
 10c:	00000097          	auipc	ra,0x0
 110:	34e080e7          	jalr	846(ra) # 45a <getprocs>
 114:	00001797          	auipc	a5,0x1
 118:	8aa7a223          	sw	a0,-1884(a5) # 9b8 <nprocs>
  if (nprocs < 0)
 11c:	02054463          	bltz	a0,144 <main+0x52>
    exit(-1);
  mktree(0, pid);
 120:	85a6                	mv	a1,s1
 122:	4501                	li	a0,0
 124:	00000097          	auipc	ra,0x0
 128:	edc080e7          	jalr	-292(ra) # 0 <mktree>
  exit(0);
 12c:	4501                	li	a0,0
 12e:	00000097          	auipc	ra,0x0
 132:	28c080e7          	jalr	652(ra) # 3ba <exit>
    pid = atoi(argv[1]);
 136:	6588                	ld	a0,8(a1)
 138:	00000097          	auipc	ra,0x0
 13c:	188080e7          	jalr	392(ra) # 2c0 <atoi>
 140:	84aa                	mv	s1,a0
 142:	b7c9                	j	104 <main+0x12>
    exit(-1);
 144:	557d                	li	a0,-1
 146:	00000097          	auipc	ra,0x0
 14a:	274080e7          	jalr	628(ra) # 3ba <exit>

000000000000014e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 14e:	1141                	addi	sp,sp,-16
 150:	e422                	sd	s0,8(sp)
 152:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 154:	87aa                	mv	a5,a0
 156:	0585                	addi	a1,a1,1
 158:	0785                	addi	a5,a5,1
 15a:	fff5c703          	lbu	a4,-1(a1)
 15e:	fee78fa3          	sb	a4,-1(a5)
 162:	fb75                	bnez	a4,156 <strcpy+0x8>
    ;
  return os;
}
 164:	6422                	ld	s0,8(sp)
 166:	0141                	addi	sp,sp,16
 168:	8082                	ret

000000000000016a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 16a:	1141                	addi	sp,sp,-16
 16c:	e422                	sd	s0,8(sp)
 16e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 170:	00054783          	lbu	a5,0(a0)
 174:	cb91                	beqz	a5,188 <strcmp+0x1e>
 176:	0005c703          	lbu	a4,0(a1)
 17a:	00f71763          	bne	a4,a5,188 <strcmp+0x1e>
    p++, q++;
 17e:	0505                	addi	a0,a0,1
 180:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 182:	00054783          	lbu	a5,0(a0)
 186:	fbe5                	bnez	a5,176 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 188:	0005c503          	lbu	a0,0(a1)
}
 18c:	40a7853b          	subw	a0,a5,a0
 190:	6422                	ld	s0,8(sp)
 192:	0141                	addi	sp,sp,16
 194:	8082                	ret

0000000000000196 <strlen>:

uint
strlen(const char *s)
{
 196:	1141                	addi	sp,sp,-16
 198:	e422                	sd	s0,8(sp)
 19a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 19c:	00054783          	lbu	a5,0(a0)
 1a0:	cf91                	beqz	a5,1bc <strlen+0x26>
 1a2:	0505                	addi	a0,a0,1
 1a4:	87aa                	mv	a5,a0
 1a6:	4685                	li	a3,1
 1a8:	9e89                	subw	a3,a3,a0
 1aa:	00f6853b          	addw	a0,a3,a5
 1ae:	0785                	addi	a5,a5,1
 1b0:	fff7c703          	lbu	a4,-1(a5)
 1b4:	fb7d                	bnez	a4,1aa <strlen+0x14>
    ;
  return n;
}
 1b6:	6422                	ld	s0,8(sp)
 1b8:	0141                	addi	sp,sp,16
 1ba:	8082                	ret
  for(n = 0; s[n]; n++)
 1bc:	4501                	li	a0,0
 1be:	bfe5                	j	1b6 <strlen+0x20>

00000000000001c0 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1c0:	1141                	addi	sp,sp,-16
 1c2:	e422                	sd	s0,8(sp)
 1c4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1c6:	ca19                	beqz	a2,1dc <memset+0x1c>
 1c8:	87aa                	mv	a5,a0
 1ca:	1602                	slli	a2,a2,0x20
 1cc:	9201                	srli	a2,a2,0x20
 1ce:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 1d2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1d6:	0785                	addi	a5,a5,1
 1d8:	fee79de3          	bne	a5,a4,1d2 <memset+0x12>
  }
  return dst;
}
 1dc:	6422                	ld	s0,8(sp)
 1de:	0141                	addi	sp,sp,16
 1e0:	8082                	ret

00000000000001e2 <strchr>:

char*
strchr(const char *s, char c)
{
 1e2:	1141                	addi	sp,sp,-16
 1e4:	e422                	sd	s0,8(sp)
 1e6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1e8:	00054783          	lbu	a5,0(a0)
 1ec:	cb99                	beqz	a5,202 <strchr+0x20>
    if(*s == c)
 1ee:	00f58763          	beq	a1,a5,1fc <strchr+0x1a>
  for(; *s; s++)
 1f2:	0505                	addi	a0,a0,1
 1f4:	00054783          	lbu	a5,0(a0)
 1f8:	fbfd                	bnez	a5,1ee <strchr+0xc>
      return (char*)s;
  return 0;
 1fa:	4501                	li	a0,0
}
 1fc:	6422                	ld	s0,8(sp)
 1fe:	0141                	addi	sp,sp,16
 200:	8082                	ret
  return 0;
 202:	4501                	li	a0,0
 204:	bfe5                	j	1fc <strchr+0x1a>

0000000000000206 <gets>:

char*
gets(char *buf, int max)
{
 206:	711d                	addi	sp,sp,-96
 208:	ec86                	sd	ra,88(sp)
 20a:	e8a2                	sd	s0,80(sp)
 20c:	e4a6                	sd	s1,72(sp)
 20e:	e0ca                	sd	s2,64(sp)
 210:	fc4e                	sd	s3,56(sp)
 212:	f852                	sd	s4,48(sp)
 214:	f456                	sd	s5,40(sp)
 216:	f05a                	sd	s6,32(sp)
 218:	ec5e                	sd	s7,24(sp)
 21a:	1080                	addi	s0,sp,96
 21c:	8baa                	mv	s7,a0
 21e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 220:	892a                	mv	s2,a0
 222:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 224:	4aa9                	li	s5,10
 226:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 228:	89a6                	mv	s3,s1
 22a:	2485                	addiw	s1,s1,1
 22c:	0344d863          	bge	s1,s4,25c <gets+0x56>
    cc = read(0, &c, 1);
 230:	4605                	li	a2,1
 232:	faf40593          	addi	a1,s0,-81
 236:	4501                	li	a0,0
 238:	00000097          	auipc	ra,0x0
 23c:	19a080e7          	jalr	410(ra) # 3d2 <read>
    if(cc < 1)
 240:	00a05e63          	blez	a0,25c <gets+0x56>
    buf[i++] = c;
 244:	faf44783          	lbu	a5,-81(s0)
 248:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 24c:	01578763          	beq	a5,s5,25a <gets+0x54>
 250:	0905                	addi	s2,s2,1
 252:	fd679be3          	bne	a5,s6,228 <gets+0x22>
  for(i=0; i+1 < max; ){
 256:	89a6                	mv	s3,s1
 258:	a011                	j	25c <gets+0x56>
 25a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 25c:	99de                	add	s3,s3,s7
 25e:	00098023          	sb	zero,0(s3)
  return buf;
}
 262:	855e                	mv	a0,s7
 264:	60e6                	ld	ra,88(sp)
 266:	6446                	ld	s0,80(sp)
 268:	64a6                	ld	s1,72(sp)
 26a:	6906                	ld	s2,64(sp)
 26c:	79e2                	ld	s3,56(sp)
 26e:	7a42                	ld	s4,48(sp)
 270:	7aa2                	ld	s5,40(sp)
 272:	7b02                	ld	s6,32(sp)
 274:	6be2                	ld	s7,24(sp)
 276:	6125                	addi	sp,sp,96
 278:	8082                	ret

000000000000027a <stat>:

int
stat(const char *n, struct stat *st)
{
 27a:	1101                	addi	sp,sp,-32
 27c:	ec06                	sd	ra,24(sp)
 27e:	e822                	sd	s0,16(sp)
 280:	e426                	sd	s1,8(sp)
 282:	e04a                	sd	s2,0(sp)
 284:	1000                	addi	s0,sp,32
 286:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 288:	4581                	li	a1,0
 28a:	00000097          	auipc	ra,0x0
 28e:	170080e7          	jalr	368(ra) # 3fa <open>
  if(fd < 0)
 292:	02054563          	bltz	a0,2bc <stat+0x42>
 296:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 298:	85ca                	mv	a1,s2
 29a:	00000097          	auipc	ra,0x0
 29e:	178080e7          	jalr	376(ra) # 412 <fstat>
 2a2:	892a                	mv	s2,a0
  close(fd);
 2a4:	8526                	mv	a0,s1
 2a6:	00000097          	auipc	ra,0x0
 2aa:	13c080e7          	jalr	316(ra) # 3e2 <close>
  return r;
}
 2ae:	854a                	mv	a0,s2
 2b0:	60e2                	ld	ra,24(sp)
 2b2:	6442                	ld	s0,16(sp)
 2b4:	64a2                	ld	s1,8(sp)
 2b6:	6902                	ld	s2,0(sp)
 2b8:	6105                	addi	sp,sp,32
 2ba:	8082                	ret
    return -1;
 2bc:	597d                	li	s2,-1
 2be:	bfc5                	j	2ae <stat+0x34>

00000000000002c0 <atoi>:

int
atoi(const char *s)
{
 2c0:	1141                	addi	sp,sp,-16
 2c2:	e422                	sd	s0,8(sp)
 2c4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2c6:	00054683          	lbu	a3,0(a0)
 2ca:	fd06879b          	addiw	a5,a3,-48
 2ce:	0ff7f793          	zext.b	a5,a5
 2d2:	4625                	li	a2,9
 2d4:	02f66863          	bltu	a2,a5,304 <atoi+0x44>
 2d8:	872a                	mv	a4,a0
  n = 0;
 2da:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 2dc:	0705                	addi	a4,a4,1
 2de:	0025179b          	slliw	a5,a0,0x2
 2e2:	9fa9                	addw	a5,a5,a0
 2e4:	0017979b          	slliw	a5,a5,0x1
 2e8:	9fb5                	addw	a5,a5,a3
 2ea:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2ee:	00074683          	lbu	a3,0(a4)
 2f2:	fd06879b          	addiw	a5,a3,-48
 2f6:	0ff7f793          	zext.b	a5,a5
 2fa:	fef671e3          	bgeu	a2,a5,2dc <atoi+0x1c>
  return n;
}
 2fe:	6422                	ld	s0,8(sp)
 300:	0141                	addi	sp,sp,16
 302:	8082                	ret
  n = 0;
 304:	4501                	li	a0,0
 306:	bfe5                	j	2fe <atoi+0x3e>

0000000000000308 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e422                	sd	s0,8(sp)
 30c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 30e:	02b57463          	bgeu	a0,a1,336 <memmove+0x2e>
    while(n-- > 0)
 312:	00c05f63          	blez	a2,330 <memmove+0x28>
 316:	1602                	slli	a2,a2,0x20
 318:	9201                	srli	a2,a2,0x20
 31a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 31e:	872a                	mv	a4,a0
      *dst++ = *src++;
 320:	0585                	addi	a1,a1,1
 322:	0705                	addi	a4,a4,1
 324:	fff5c683          	lbu	a3,-1(a1)
 328:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 32c:	fee79ae3          	bne	a5,a4,320 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 330:	6422                	ld	s0,8(sp)
 332:	0141                	addi	sp,sp,16
 334:	8082                	ret
    dst += n;
 336:	00c50733          	add	a4,a0,a2
    src += n;
 33a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 33c:	fec05ae3          	blez	a2,330 <memmove+0x28>
 340:	fff6079b          	addiw	a5,a2,-1
 344:	1782                	slli	a5,a5,0x20
 346:	9381                	srli	a5,a5,0x20
 348:	fff7c793          	not	a5,a5
 34c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 34e:	15fd                	addi	a1,a1,-1
 350:	177d                	addi	a4,a4,-1
 352:	0005c683          	lbu	a3,0(a1)
 356:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 35a:	fee79ae3          	bne	a5,a4,34e <memmove+0x46>
 35e:	bfc9                	j	330 <memmove+0x28>

0000000000000360 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 360:	1141                	addi	sp,sp,-16
 362:	e422                	sd	s0,8(sp)
 364:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 366:	ca05                	beqz	a2,396 <memcmp+0x36>
 368:	fff6069b          	addiw	a3,a2,-1
 36c:	1682                	slli	a3,a3,0x20
 36e:	9281                	srli	a3,a3,0x20
 370:	0685                	addi	a3,a3,1
 372:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 374:	00054783          	lbu	a5,0(a0)
 378:	0005c703          	lbu	a4,0(a1)
 37c:	00e79863          	bne	a5,a4,38c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 380:	0505                	addi	a0,a0,1
    p2++;
 382:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 384:	fed518e3          	bne	a0,a3,374 <memcmp+0x14>
  }
  return 0;
 388:	4501                	li	a0,0
 38a:	a019                	j	390 <memcmp+0x30>
      return *p1 - *p2;
 38c:	40e7853b          	subw	a0,a5,a4
}
 390:	6422                	ld	s0,8(sp)
 392:	0141                	addi	sp,sp,16
 394:	8082                	ret
  return 0;
 396:	4501                	li	a0,0
 398:	bfe5                	j	390 <memcmp+0x30>

000000000000039a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 39a:	1141                	addi	sp,sp,-16
 39c:	e406                	sd	ra,8(sp)
 39e:	e022                	sd	s0,0(sp)
 3a0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3a2:	00000097          	auipc	ra,0x0
 3a6:	f66080e7          	jalr	-154(ra) # 308 <memmove>
}
 3aa:	60a2                	ld	ra,8(sp)
 3ac:	6402                	ld	s0,0(sp)
 3ae:	0141                	addi	sp,sp,16
 3b0:	8082                	ret

00000000000003b2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3b2:	4885                	li	a7,1
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <exit>:
.global exit
exit:
 li a7, SYS_exit
 3ba:	4889                	li	a7,2
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3c2:	488d                	li	a7,3
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3ca:	4891                	li	a7,4
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <read>:
.global read
read:
 li a7, SYS_read
 3d2:	4895                	li	a7,5
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <write>:
.global write
write:
 li a7, SYS_write
 3da:	48c1                	li	a7,16
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <close>:
.global close
close:
 li a7, SYS_close
 3e2:	48d5                	li	a7,21
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <kill>:
.global kill
kill:
 li a7, SYS_kill
 3ea:	4899                	li	a7,6
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3f2:	489d                	li	a7,7
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <open>:
.global open
open:
 li a7, SYS_open
 3fa:	48bd                	li	a7,15
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 402:	48c5                	li	a7,17
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 40a:	48c9                	li	a7,18
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 412:	48a1                	li	a7,8
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <link>:
.global link
link:
 li a7, SYS_link
 41a:	48cd                	li	a7,19
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 422:	48d1                	li	a7,20
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 42a:	48a5                	li	a7,9
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <dup>:
.global dup
dup:
 li a7, SYS_dup
 432:	48a9                	li	a7,10
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 43a:	48ad                	li	a7,11
 ecall
 43c:	00000073          	ecall
 ret
 440:	8082                	ret

0000000000000442 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 442:	48b1                	li	a7,12
 ecall
 444:	00000073          	ecall
 ret
 448:	8082                	ret

000000000000044a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 44a:	48b5                	li	a7,13
 ecall
 44c:	00000073          	ecall
 ret
 450:	8082                	ret

0000000000000452 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 452:	48b9                	li	a7,14
 ecall
 454:	00000073          	ecall
 ret
 458:	8082                	ret

000000000000045a <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 45a:	48d9                	li	a7,22
 ecall
 45c:	00000073          	ecall
 ret
 460:	8082                	ret

0000000000000462 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 462:	48dd                	li	a7,23
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 46a:	48e1                	li	a7,24
 ecall
 46c:	00000073          	ecall
 ret
 470:	8082                	ret

0000000000000472 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 472:	48e5                	li	a7,25
 ecall
 474:	00000073          	ecall
 ret
 478:	8082                	ret

000000000000047a <sem_init>:
.global sem_init
sem_init:
 li a7, SYS_sem_init
 47a:	48e9                	li	a7,26
 ecall
 47c:	00000073          	ecall
 ret
 480:	8082                	ret

0000000000000482 <sem_destroy>:
.global sem_destroy
sem_destroy:
 li a7, SYS_sem_destroy
 482:	48ed                	li	a7,27
 ecall
 484:	00000073          	ecall
 ret
 488:	8082                	ret

000000000000048a <sem_wait>:
.global sem_wait
sem_wait:
 li a7, SYS_sem_wait
 48a:	48f1                	li	a7,28
 ecall
 48c:	00000073          	ecall
 ret
 490:	8082                	ret

0000000000000492 <sem_post>:
.global sem_post
sem_post:
 li a7, SYS_sem_post
 492:	48f5                	li	a7,29
 ecall
 494:	00000073          	ecall
 ret
 498:	8082                	ret

000000000000049a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 49a:	1101                	addi	sp,sp,-32
 49c:	ec06                	sd	ra,24(sp)
 49e:	e822                	sd	s0,16(sp)
 4a0:	1000                	addi	s0,sp,32
 4a2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4a6:	4605                	li	a2,1
 4a8:	fef40593          	addi	a1,s0,-17
 4ac:	00000097          	auipc	ra,0x0
 4b0:	f2e080e7          	jalr	-210(ra) # 3da <write>
}
 4b4:	60e2                	ld	ra,24(sp)
 4b6:	6442                	ld	s0,16(sp)
 4b8:	6105                	addi	sp,sp,32
 4ba:	8082                	ret

00000000000004bc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4bc:	7139                	addi	sp,sp,-64
 4be:	fc06                	sd	ra,56(sp)
 4c0:	f822                	sd	s0,48(sp)
 4c2:	f426                	sd	s1,40(sp)
 4c4:	f04a                	sd	s2,32(sp)
 4c6:	ec4e                	sd	s3,24(sp)
 4c8:	0080                	addi	s0,sp,64
 4ca:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4cc:	c299                	beqz	a3,4d2 <printint+0x16>
 4ce:	0805c963          	bltz	a1,560 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4d2:	2581                	sext.w	a1,a1
  neg = 0;
 4d4:	4881                	li	a7,0
 4d6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4da:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4dc:	2601                	sext.w	a2,a2
 4de:	00000517          	auipc	a0,0x0
 4e2:	4c250513          	addi	a0,a0,1218 # 9a0 <digits>
 4e6:	883a                	mv	a6,a4
 4e8:	2705                	addiw	a4,a4,1
 4ea:	02c5f7bb          	remuw	a5,a1,a2
 4ee:	1782                	slli	a5,a5,0x20
 4f0:	9381                	srli	a5,a5,0x20
 4f2:	97aa                	add	a5,a5,a0
 4f4:	0007c783          	lbu	a5,0(a5)
 4f8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4fc:	0005879b          	sext.w	a5,a1
 500:	02c5d5bb          	divuw	a1,a1,a2
 504:	0685                	addi	a3,a3,1
 506:	fec7f0e3          	bgeu	a5,a2,4e6 <printint+0x2a>
  if(neg)
 50a:	00088c63          	beqz	a7,522 <printint+0x66>
    buf[i++] = '-';
 50e:	fd070793          	addi	a5,a4,-48
 512:	00878733          	add	a4,a5,s0
 516:	02d00793          	li	a5,45
 51a:	fef70823          	sb	a5,-16(a4)
 51e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 522:	02e05863          	blez	a4,552 <printint+0x96>
 526:	fc040793          	addi	a5,s0,-64
 52a:	00e78933          	add	s2,a5,a4
 52e:	fff78993          	addi	s3,a5,-1
 532:	99ba                	add	s3,s3,a4
 534:	377d                	addiw	a4,a4,-1
 536:	1702                	slli	a4,a4,0x20
 538:	9301                	srli	a4,a4,0x20
 53a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 53e:	fff94583          	lbu	a1,-1(s2)
 542:	8526                	mv	a0,s1
 544:	00000097          	auipc	ra,0x0
 548:	f56080e7          	jalr	-170(ra) # 49a <putc>
  while(--i >= 0)
 54c:	197d                	addi	s2,s2,-1
 54e:	ff3918e3          	bne	s2,s3,53e <printint+0x82>
}
 552:	70e2                	ld	ra,56(sp)
 554:	7442                	ld	s0,48(sp)
 556:	74a2                	ld	s1,40(sp)
 558:	7902                	ld	s2,32(sp)
 55a:	69e2                	ld	s3,24(sp)
 55c:	6121                	addi	sp,sp,64
 55e:	8082                	ret
    x = -xx;
 560:	40b005bb          	negw	a1,a1
    neg = 1;
 564:	4885                	li	a7,1
    x = -xx;
 566:	bf85                	j	4d6 <printint+0x1a>

0000000000000568 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 568:	7119                	addi	sp,sp,-128
 56a:	fc86                	sd	ra,120(sp)
 56c:	f8a2                	sd	s0,112(sp)
 56e:	f4a6                	sd	s1,104(sp)
 570:	f0ca                	sd	s2,96(sp)
 572:	ecce                	sd	s3,88(sp)
 574:	e8d2                	sd	s4,80(sp)
 576:	e4d6                	sd	s5,72(sp)
 578:	e0da                	sd	s6,64(sp)
 57a:	fc5e                	sd	s7,56(sp)
 57c:	f862                	sd	s8,48(sp)
 57e:	f466                	sd	s9,40(sp)
 580:	f06a                	sd	s10,32(sp)
 582:	ec6e                	sd	s11,24(sp)
 584:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 586:	0005c903          	lbu	s2,0(a1)
 58a:	18090f63          	beqz	s2,728 <vprintf+0x1c0>
 58e:	8aaa                	mv	s5,a0
 590:	8b32                	mv	s6,a2
 592:	00158493          	addi	s1,a1,1
  state = 0;
 596:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 598:	02500a13          	li	s4,37
 59c:	4c55                	li	s8,21
 59e:	00000c97          	auipc	s9,0x0
 5a2:	3aac8c93          	addi	s9,s9,938 # 948 <malloc+0x11c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 5a6:	02800d93          	li	s11,40
  putc(fd, 'x');
 5aa:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ac:	00000b97          	auipc	s7,0x0
 5b0:	3f4b8b93          	addi	s7,s7,1012 # 9a0 <digits>
 5b4:	a839                	j	5d2 <vprintf+0x6a>
        putc(fd, c);
 5b6:	85ca                	mv	a1,s2
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	ee0080e7          	jalr	-288(ra) # 49a <putc>
 5c2:	a019                	j	5c8 <vprintf+0x60>
    } else if(state == '%'){
 5c4:	01498d63          	beq	s3,s4,5de <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 5c8:	0485                	addi	s1,s1,1
 5ca:	fff4c903          	lbu	s2,-1(s1)
 5ce:	14090d63          	beqz	s2,728 <vprintf+0x1c0>
    if(state == 0){
 5d2:	fe0999e3          	bnez	s3,5c4 <vprintf+0x5c>
      if(c == '%'){
 5d6:	ff4910e3          	bne	s2,s4,5b6 <vprintf+0x4e>
        state = '%';
 5da:	89d2                	mv	s3,s4
 5dc:	b7f5                	j	5c8 <vprintf+0x60>
      if(c == 'd'){
 5de:	11490c63          	beq	s2,s4,6f6 <vprintf+0x18e>
 5e2:	f9d9079b          	addiw	a5,s2,-99
 5e6:	0ff7f793          	zext.b	a5,a5
 5ea:	10fc6e63          	bltu	s8,a5,706 <vprintf+0x19e>
 5ee:	f9d9079b          	addiw	a5,s2,-99
 5f2:	0ff7f713          	zext.b	a4,a5
 5f6:	10ec6863          	bltu	s8,a4,706 <vprintf+0x19e>
 5fa:	00271793          	slli	a5,a4,0x2
 5fe:	97e6                	add	a5,a5,s9
 600:	439c                	lw	a5,0(a5)
 602:	97e6                	add	a5,a5,s9
 604:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 606:	008b0913          	addi	s2,s6,8
 60a:	4685                	li	a3,1
 60c:	4629                	li	a2,10
 60e:	000b2583          	lw	a1,0(s6)
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	ea8080e7          	jalr	-344(ra) # 4bc <printint>
 61c:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 61e:	4981                	li	s3,0
 620:	b765                	j	5c8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 622:	008b0913          	addi	s2,s6,8
 626:	4681                	li	a3,0
 628:	4629                	li	a2,10
 62a:	000b2583          	lw	a1,0(s6)
 62e:	8556                	mv	a0,s5
 630:	00000097          	auipc	ra,0x0
 634:	e8c080e7          	jalr	-372(ra) # 4bc <printint>
 638:	8b4a                	mv	s6,s2
      state = 0;
 63a:	4981                	li	s3,0
 63c:	b771                	j	5c8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 63e:	008b0913          	addi	s2,s6,8
 642:	4681                	li	a3,0
 644:	866a                	mv	a2,s10
 646:	000b2583          	lw	a1,0(s6)
 64a:	8556                	mv	a0,s5
 64c:	00000097          	auipc	ra,0x0
 650:	e70080e7          	jalr	-400(ra) # 4bc <printint>
 654:	8b4a                	mv	s6,s2
      state = 0;
 656:	4981                	li	s3,0
 658:	bf85                	j	5c8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 65a:	008b0793          	addi	a5,s6,8
 65e:	f8f43423          	sd	a5,-120(s0)
 662:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 666:	03000593          	li	a1,48
 66a:	8556                	mv	a0,s5
 66c:	00000097          	auipc	ra,0x0
 670:	e2e080e7          	jalr	-466(ra) # 49a <putc>
  putc(fd, 'x');
 674:	07800593          	li	a1,120
 678:	8556                	mv	a0,s5
 67a:	00000097          	auipc	ra,0x0
 67e:	e20080e7          	jalr	-480(ra) # 49a <putc>
 682:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 684:	03c9d793          	srli	a5,s3,0x3c
 688:	97de                	add	a5,a5,s7
 68a:	0007c583          	lbu	a1,0(a5)
 68e:	8556                	mv	a0,s5
 690:	00000097          	auipc	ra,0x0
 694:	e0a080e7          	jalr	-502(ra) # 49a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 698:	0992                	slli	s3,s3,0x4
 69a:	397d                	addiw	s2,s2,-1
 69c:	fe0914e3          	bnez	s2,684 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 6a0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6a4:	4981                	li	s3,0
 6a6:	b70d                	j	5c8 <vprintf+0x60>
        s = va_arg(ap, char*);
 6a8:	008b0913          	addi	s2,s6,8
 6ac:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 6b0:	02098163          	beqz	s3,6d2 <vprintf+0x16a>
        while(*s != 0){
 6b4:	0009c583          	lbu	a1,0(s3)
 6b8:	c5ad                	beqz	a1,722 <vprintf+0x1ba>
          putc(fd, *s);
 6ba:	8556                	mv	a0,s5
 6bc:	00000097          	auipc	ra,0x0
 6c0:	dde080e7          	jalr	-546(ra) # 49a <putc>
          s++;
 6c4:	0985                	addi	s3,s3,1
        while(*s != 0){
 6c6:	0009c583          	lbu	a1,0(s3)
 6ca:	f9e5                	bnez	a1,6ba <vprintf+0x152>
        s = va_arg(ap, char*);
 6cc:	8b4a                	mv	s6,s2
      state = 0;
 6ce:	4981                	li	s3,0
 6d0:	bde5                	j	5c8 <vprintf+0x60>
          s = "(null)";
 6d2:	00000997          	auipc	s3,0x0
 6d6:	26e98993          	addi	s3,s3,622 # 940 <malloc+0x114>
        while(*s != 0){
 6da:	85ee                	mv	a1,s11
 6dc:	bff9                	j	6ba <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 6de:	008b0913          	addi	s2,s6,8
 6e2:	000b4583          	lbu	a1,0(s6)
 6e6:	8556                	mv	a0,s5
 6e8:	00000097          	auipc	ra,0x0
 6ec:	db2080e7          	jalr	-590(ra) # 49a <putc>
 6f0:	8b4a                	mv	s6,s2
      state = 0;
 6f2:	4981                	li	s3,0
 6f4:	bdd1                	j	5c8 <vprintf+0x60>
        putc(fd, c);
 6f6:	85d2                	mv	a1,s4
 6f8:	8556                	mv	a0,s5
 6fa:	00000097          	auipc	ra,0x0
 6fe:	da0080e7          	jalr	-608(ra) # 49a <putc>
      state = 0;
 702:	4981                	li	s3,0
 704:	b5d1                	j	5c8 <vprintf+0x60>
        putc(fd, '%');
 706:	85d2                	mv	a1,s4
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	d90080e7          	jalr	-624(ra) # 49a <putc>
        putc(fd, c);
 712:	85ca                	mv	a1,s2
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	d84080e7          	jalr	-636(ra) # 49a <putc>
      state = 0;
 71e:	4981                	li	s3,0
 720:	b565                	j	5c8 <vprintf+0x60>
        s = va_arg(ap, char*);
 722:	8b4a                	mv	s6,s2
      state = 0;
 724:	4981                	li	s3,0
 726:	b54d                	j	5c8 <vprintf+0x60>
    }
  }
}
 728:	70e6                	ld	ra,120(sp)
 72a:	7446                	ld	s0,112(sp)
 72c:	74a6                	ld	s1,104(sp)
 72e:	7906                	ld	s2,96(sp)
 730:	69e6                	ld	s3,88(sp)
 732:	6a46                	ld	s4,80(sp)
 734:	6aa6                	ld	s5,72(sp)
 736:	6b06                	ld	s6,64(sp)
 738:	7be2                	ld	s7,56(sp)
 73a:	7c42                	ld	s8,48(sp)
 73c:	7ca2                	ld	s9,40(sp)
 73e:	7d02                	ld	s10,32(sp)
 740:	6de2                	ld	s11,24(sp)
 742:	6109                	addi	sp,sp,128
 744:	8082                	ret

0000000000000746 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 746:	715d                	addi	sp,sp,-80
 748:	ec06                	sd	ra,24(sp)
 74a:	e822                	sd	s0,16(sp)
 74c:	1000                	addi	s0,sp,32
 74e:	e010                	sd	a2,0(s0)
 750:	e414                	sd	a3,8(s0)
 752:	e818                	sd	a4,16(s0)
 754:	ec1c                	sd	a5,24(s0)
 756:	03043023          	sd	a6,32(s0)
 75a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 75e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 762:	8622                	mv	a2,s0
 764:	00000097          	auipc	ra,0x0
 768:	e04080e7          	jalr	-508(ra) # 568 <vprintf>
}
 76c:	60e2                	ld	ra,24(sp)
 76e:	6442                	ld	s0,16(sp)
 770:	6161                	addi	sp,sp,80
 772:	8082                	ret

0000000000000774 <printf>:

void
printf(const char *fmt, ...)
{
 774:	711d                	addi	sp,sp,-96
 776:	ec06                	sd	ra,24(sp)
 778:	e822                	sd	s0,16(sp)
 77a:	1000                	addi	s0,sp,32
 77c:	e40c                	sd	a1,8(s0)
 77e:	e810                	sd	a2,16(s0)
 780:	ec14                	sd	a3,24(s0)
 782:	f018                	sd	a4,32(s0)
 784:	f41c                	sd	a5,40(s0)
 786:	03043823          	sd	a6,48(s0)
 78a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 78e:	00840613          	addi	a2,s0,8
 792:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 796:	85aa                	mv	a1,a0
 798:	4505                	li	a0,1
 79a:	00000097          	auipc	ra,0x0
 79e:	dce080e7          	jalr	-562(ra) # 568 <vprintf>
}
 7a2:	60e2                	ld	ra,24(sp)
 7a4:	6442                	ld	s0,16(sp)
 7a6:	6125                	addi	sp,sp,96
 7a8:	8082                	ret

00000000000007aa <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7aa:	1141                	addi	sp,sp,-16
 7ac:	e422                	sd	s0,8(sp)
 7ae:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7b0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7b4:	00000797          	auipc	a5,0x0
 7b8:	20c7b783          	ld	a5,524(a5) # 9c0 <freep>
 7bc:	a02d                	j	7e6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7be:	4618                	lw	a4,8(a2)
 7c0:	9f2d                	addw	a4,a4,a1
 7c2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7c6:	6398                	ld	a4,0(a5)
 7c8:	6310                	ld	a2,0(a4)
 7ca:	a83d                	j	808 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7cc:	ff852703          	lw	a4,-8(a0)
 7d0:	9f31                	addw	a4,a4,a2
 7d2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 7d4:	ff053683          	ld	a3,-16(a0)
 7d8:	a091                	j	81c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7da:	6398                	ld	a4,0(a5)
 7dc:	00e7e463          	bltu	a5,a4,7e4 <free+0x3a>
 7e0:	00e6ea63          	bltu	a3,a4,7f4 <free+0x4a>
{
 7e4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7e6:	fed7fae3          	bgeu	a5,a3,7da <free+0x30>
 7ea:	6398                	ld	a4,0(a5)
 7ec:	00e6e463          	bltu	a3,a4,7f4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7f0:	fee7eae3          	bltu	a5,a4,7e4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 7f4:	ff852583          	lw	a1,-8(a0)
 7f8:	6390                	ld	a2,0(a5)
 7fa:	02059813          	slli	a6,a1,0x20
 7fe:	01c85713          	srli	a4,a6,0x1c
 802:	9736                	add	a4,a4,a3
 804:	fae60de3          	beq	a2,a4,7be <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 808:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 80c:	4790                	lw	a2,8(a5)
 80e:	02061593          	slli	a1,a2,0x20
 812:	01c5d713          	srli	a4,a1,0x1c
 816:	973e                	add	a4,a4,a5
 818:	fae68ae3          	beq	a3,a4,7cc <free+0x22>
    p->s.ptr = bp->s.ptr;
 81c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 81e:	00000717          	auipc	a4,0x0
 822:	1af73123          	sd	a5,418(a4) # 9c0 <freep>
}
 826:	6422                	ld	s0,8(sp)
 828:	0141                	addi	sp,sp,16
 82a:	8082                	ret

000000000000082c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 82c:	7139                	addi	sp,sp,-64
 82e:	fc06                	sd	ra,56(sp)
 830:	f822                	sd	s0,48(sp)
 832:	f426                	sd	s1,40(sp)
 834:	f04a                	sd	s2,32(sp)
 836:	ec4e                	sd	s3,24(sp)
 838:	e852                	sd	s4,16(sp)
 83a:	e456                	sd	s5,8(sp)
 83c:	e05a                	sd	s6,0(sp)
 83e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 840:	02051493          	slli	s1,a0,0x20
 844:	9081                	srli	s1,s1,0x20
 846:	04bd                	addi	s1,s1,15
 848:	8091                	srli	s1,s1,0x4
 84a:	0014899b          	addiw	s3,s1,1
 84e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 850:	00000517          	auipc	a0,0x0
 854:	17053503          	ld	a0,368(a0) # 9c0 <freep>
 858:	c515                	beqz	a0,884 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 85a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 85c:	4798                	lw	a4,8(a5)
 85e:	02977f63          	bgeu	a4,s1,89c <malloc+0x70>
 862:	8a4e                	mv	s4,s3
 864:	0009871b          	sext.w	a4,s3
 868:	6685                	lui	a3,0x1
 86a:	00d77363          	bgeu	a4,a3,870 <malloc+0x44>
 86e:	6a05                	lui	s4,0x1
 870:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 874:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 878:	00000917          	auipc	s2,0x0
 87c:	14890913          	addi	s2,s2,328 # 9c0 <freep>
  if(p == (char*)-1)
 880:	5afd                	li	s5,-1
 882:	a895                	j	8f6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 884:	00001797          	auipc	a5,0x1
 888:	b4478793          	addi	a5,a5,-1212 # 13c8 <base>
 88c:	00000717          	auipc	a4,0x0
 890:	12f73a23          	sd	a5,308(a4) # 9c0 <freep>
 894:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 896:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 89a:	b7e1                	j	862 <malloc+0x36>
      if(p->s.size == nunits)
 89c:	02e48c63          	beq	s1,a4,8d4 <malloc+0xa8>
        p->s.size -= nunits;
 8a0:	4137073b          	subw	a4,a4,s3
 8a4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8a6:	02071693          	slli	a3,a4,0x20
 8aa:	01c6d713          	srli	a4,a3,0x1c
 8ae:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8b0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8b4:	00000717          	auipc	a4,0x0
 8b8:	10a73623          	sd	a0,268(a4) # 9c0 <freep>
      return (void*)(p + 1);
 8bc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8c0:	70e2                	ld	ra,56(sp)
 8c2:	7442                	ld	s0,48(sp)
 8c4:	74a2                	ld	s1,40(sp)
 8c6:	7902                	ld	s2,32(sp)
 8c8:	69e2                	ld	s3,24(sp)
 8ca:	6a42                	ld	s4,16(sp)
 8cc:	6aa2                	ld	s5,8(sp)
 8ce:	6b02                	ld	s6,0(sp)
 8d0:	6121                	addi	sp,sp,64
 8d2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8d4:	6398                	ld	a4,0(a5)
 8d6:	e118                	sd	a4,0(a0)
 8d8:	bff1                	j	8b4 <malloc+0x88>
  hp->s.size = nu;
 8da:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8de:	0541                	addi	a0,a0,16
 8e0:	00000097          	auipc	ra,0x0
 8e4:	eca080e7          	jalr	-310(ra) # 7aa <free>
  return freep;
 8e8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8ec:	d971                	beqz	a0,8c0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8ee:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8f0:	4798                	lw	a4,8(a5)
 8f2:	fa9775e3          	bgeu	a4,s1,89c <malloc+0x70>
    if(p == freep)
 8f6:	00093703          	ld	a4,0(s2)
 8fa:	853e                	mv	a0,a5
 8fc:	fef719e3          	bne	a4,a5,8ee <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 900:	8552                	mv	a0,s4
 902:	00000097          	auipc	ra,0x0
 906:	b40080e7          	jalr	-1216(ra) # 442 <sbrk>
  if(p == (char*)-1)
 90a:	fd5518e3          	bne	a0,s5,8da <malloc+0xae>
        return 0;
 90e:	4501                	li	a0,0
 910:	bf45                	j	8c0 <malloc+0x94>
