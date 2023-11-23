
user/_memory-user:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	0880                	addi	s0,sp,80
    if (argc != 4) {
  16:	4791                	li	a5,4
  18:	00f50f63          	beq	a0,a5,36 <main+0x36>
        printf("Usage: memory-user <start> <limit> <increment>, where <start> is initial mebibytes to allocate which is then incremented up to limit mebibytes\n");
  1c:	00001517          	auipc	a0,0x1
  20:	89c50513          	addi	a0,a0,-1892 # 8b8 <malloc+0xe6>
  24:	00000097          	auipc	ra,0x0
  28:	6f6080e7          	jalr	1782(ra) # 71a <printf>
        exit(-1);
  2c:	557d                	li	a0,-1
  2e:	00000097          	auipc	ra,0x0
  32:	352080e7          	jalr	850(ra) # 380 <exit>
  36:	892e                	mv	s2,a1
    }
    uint start = atoi(argv[1]);
  38:	6588                	ld	a0,8(a1)
  3a:	00000097          	auipc	ra,0x0
  3e:	24c080e7          	jalr	588(ra) # 286 <atoi>
  42:	84aa                	mv	s1,a0
    uint limit = atoi(argv[2]);
  44:	01093503          	ld	a0,16(s2)
  48:	00000097          	auipc	ra,0x0
  4c:	23e080e7          	jalr	574(ra) # 286 <atoi>
  50:	89aa                	mv	s3,a0
    uint increment = atoi(argv[3]);
  52:	01893503          	ld	a0,24(s2)
  56:	00000097          	auipc	ra,0x0
  5a:	230080e7          	jalr	560(ra) # 286 <atoi>
  5e:	00050a1b          	sext.w	s4,a0
    if (increment == 0){
  62:	080a0763          	beqz	s4,f0 <main+0xf0>
    uint start = atoi(argv[1]);
  66:	2481                	sext.w	s1,s1
    uint limit = atoi(argv[2]);
  68:	2981                	sext.w	s3,s3
        exit(0);
    }
    uint i;
    // uint j;
    int *array;
    for (i=start; i<=limit; i+=increment) {
  6a:	0699ee63          	bltu	s3,s1,e6 <main+0xe6>
	printf("allocating %p mebibytes\n", i); 
  6e:	00001b17          	auipc	s6,0x1
  72:	8dab0b13          	addi	s6,s6,-1830 # 948 <malloc+0x176>
	array = (int *) malloc(i*1024*1024);
	printf("malloc returned %p\n", array);
  76:	00001a97          	auipc	s5,0x1
  7a:	8f2a8a93          	addi	s5,s5,-1806 # 968 <malloc+0x196>
        }
/*	for (j = 0; j <= i*1024*1024/4; j++)
	    array[j] = j;
	    */
	sleep(50);
	printf("freeing %p mebibytes\n", i); 
  7e:	00001b97          	auipc	s7,0x1
  82:	912b8b93          	addi	s7,s7,-1774 # 990 <malloc+0x1be>
	printf("allocating %p mebibytes\n", i); 
  86:	85a6                	mv	a1,s1
  88:	855a                	mv	a0,s6
  8a:	00000097          	auipc	ra,0x0
  8e:	690080e7          	jalr	1680(ra) # 71a <printf>
	array = (int *) malloc(i*1024*1024);
  92:	0144951b          	slliw	a0,s1,0x14
  96:	00000097          	auipc	ra,0x0
  9a:	73c080e7          	jalr	1852(ra) # 7d2 <malloc>
  9e:	892a                	mv	s2,a0
	printf("malloc returned %p\n", array);
  a0:	85aa                	mv	a1,a0
  a2:	8556                	mv	a0,s5
  a4:	00000097          	auipc	ra,0x0
  a8:	676080e7          	jalr	1654(ra) # 71a <printf>
        if (!array) {
  ac:	04090763          	beqz	s2,fa <main+0xfa>
	sleep(50);
  b0:	03200513          	li	a0,50
  b4:	00000097          	auipc	ra,0x0
  b8:	35c080e7          	jalr	860(ra) # 410 <sleep>
	printf("freeing %p mebibytes\n", i); 
  bc:	85a6                	mv	a1,s1
  be:	855e                	mv	a0,s7
  c0:	00000097          	auipc	ra,0x0
  c4:	65a080e7          	jalr	1626(ra) # 71a <printf>
	free(array);
  c8:	854a                	mv	a0,s2
  ca:	00000097          	auipc	ra,0x0
  ce:	686080e7          	jalr	1670(ra) # 750 <free>
	sleep(50);
  d2:	03200513          	li	a0,50
  d6:	00000097          	auipc	ra,0x0
  da:	33a080e7          	jalr	826(ra) # 410 <sleep>
    for (i=start; i<=limit; i+=increment) {
  de:	009a04bb          	addw	s1,s4,s1
  e2:	fa99f2e3          	bgeu	s3,s1,86 <main+0x86>
    }

    exit(0);
  e6:	4501                	li	a0,0
  e8:	00000097          	auipc	ra,0x0
  ec:	298080e7          	jalr	664(ra) # 380 <exit>
        exit(0);
  f0:	4501                	li	a0,0
  f2:	00000097          	auipc	ra,0x0
  f6:	28e080e7          	jalr	654(ra) # 380 <exit>
            printf("malloc failed\n");
  fa:	00001517          	auipc	a0,0x1
  fe:	88650513          	addi	a0,a0,-1914 # 980 <malloc+0x1ae>
 102:	00000097          	auipc	ra,0x0
 106:	618080e7          	jalr	1560(ra) # 71a <printf>
	    exit(-1);
 10a:	557d                	li	a0,-1
 10c:	00000097          	auipc	ra,0x0
 110:	274080e7          	jalr	628(ra) # 380 <exit>

0000000000000114 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 11a:	87aa                	mv	a5,a0
 11c:	0585                	addi	a1,a1,1
 11e:	0785                	addi	a5,a5,1
 120:	fff5c703          	lbu	a4,-1(a1)
 124:	fee78fa3          	sb	a4,-1(a5)
 128:	fb75                	bnez	a4,11c <strcpy+0x8>
    ;
  return os;
}
 12a:	6422                	ld	s0,8(sp)
 12c:	0141                	addi	sp,sp,16
 12e:	8082                	ret

0000000000000130 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 130:	1141                	addi	sp,sp,-16
 132:	e422                	sd	s0,8(sp)
 134:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 136:	00054783          	lbu	a5,0(a0)
 13a:	cb91                	beqz	a5,14e <strcmp+0x1e>
 13c:	0005c703          	lbu	a4,0(a1)
 140:	00f71763          	bne	a4,a5,14e <strcmp+0x1e>
    p++, q++;
 144:	0505                	addi	a0,a0,1
 146:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 148:	00054783          	lbu	a5,0(a0)
 14c:	fbe5                	bnez	a5,13c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 14e:	0005c503          	lbu	a0,0(a1)
}
 152:	40a7853b          	subw	a0,a5,a0
 156:	6422                	ld	s0,8(sp)
 158:	0141                	addi	sp,sp,16
 15a:	8082                	ret

000000000000015c <strlen>:

uint
strlen(const char *s)
{
 15c:	1141                	addi	sp,sp,-16
 15e:	e422                	sd	s0,8(sp)
 160:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 162:	00054783          	lbu	a5,0(a0)
 166:	cf91                	beqz	a5,182 <strlen+0x26>
 168:	0505                	addi	a0,a0,1
 16a:	87aa                	mv	a5,a0
 16c:	4685                	li	a3,1
 16e:	9e89                	subw	a3,a3,a0
 170:	00f6853b          	addw	a0,a3,a5
 174:	0785                	addi	a5,a5,1
 176:	fff7c703          	lbu	a4,-1(a5)
 17a:	fb7d                	bnez	a4,170 <strlen+0x14>
    ;
  return n;
}
 17c:	6422                	ld	s0,8(sp)
 17e:	0141                	addi	sp,sp,16
 180:	8082                	ret
  for(n = 0; s[n]; n++)
 182:	4501                	li	a0,0
 184:	bfe5                	j	17c <strlen+0x20>

0000000000000186 <memset>:

void*
memset(void *dst, int c, uint n)
{
 186:	1141                	addi	sp,sp,-16
 188:	e422                	sd	s0,8(sp)
 18a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 18c:	ca19                	beqz	a2,1a2 <memset+0x1c>
 18e:	87aa                	mv	a5,a0
 190:	1602                	slli	a2,a2,0x20
 192:	9201                	srli	a2,a2,0x20
 194:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 198:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 19c:	0785                	addi	a5,a5,1
 19e:	fee79de3          	bne	a5,a4,198 <memset+0x12>
  }
  return dst;
}
 1a2:	6422                	ld	s0,8(sp)
 1a4:	0141                	addi	sp,sp,16
 1a6:	8082                	ret

00000000000001a8 <strchr>:

char*
strchr(const char *s, char c)
{
 1a8:	1141                	addi	sp,sp,-16
 1aa:	e422                	sd	s0,8(sp)
 1ac:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1ae:	00054783          	lbu	a5,0(a0)
 1b2:	cb99                	beqz	a5,1c8 <strchr+0x20>
    if(*s == c)
 1b4:	00f58763          	beq	a1,a5,1c2 <strchr+0x1a>
  for(; *s; s++)
 1b8:	0505                	addi	a0,a0,1
 1ba:	00054783          	lbu	a5,0(a0)
 1be:	fbfd                	bnez	a5,1b4 <strchr+0xc>
      return (char*)s;
  return 0;
 1c0:	4501                	li	a0,0
}
 1c2:	6422                	ld	s0,8(sp)
 1c4:	0141                	addi	sp,sp,16
 1c6:	8082                	ret
  return 0;
 1c8:	4501                	li	a0,0
 1ca:	bfe5                	j	1c2 <strchr+0x1a>

00000000000001cc <gets>:

char*
gets(char *buf, int max)
{
 1cc:	711d                	addi	sp,sp,-96
 1ce:	ec86                	sd	ra,88(sp)
 1d0:	e8a2                	sd	s0,80(sp)
 1d2:	e4a6                	sd	s1,72(sp)
 1d4:	e0ca                	sd	s2,64(sp)
 1d6:	fc4e                	sd	s3,56(sp)
 1d8:	f852                	sd	s4,48(sp)
 1da:	f456                	sd	s5,40(sp)
 1dc:	f05a                	sd	s6,32(sp)
 1de:	ec5e                	sd	s7,24(sp)
 1e0:	1080                	addi	s0,sp,96
 1e2:	8baa                	mv	s7,a0
 1e4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1e6:	892a                	mv	s2,a0
 1e8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1ea:	4aa9                	li	s5,10
 1ec:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1ee:	89a6                	mv	s3,s1
 1f0:	2485                	addiw	s1,s1,1
 1f2:	0344d863          	bge	s1,s4,222 <gets+0x56>
    cc = read(0, &c, 1);
 1f6:	4605                	li	a2,1
 1f8:	faf40593          	addi	a1,s0,-81
 1fc:	4501                	li	a0,0
 1fe:	00000097          	auipc	ra,0x0
 202:	19a080e7          	jalr	410(ra) # 398 <read>
    if(cc < 1)
 206:	00a05e63          	blez	a0,222 <gets+0x56>
    buf[i++] = c;
 20a:	faf44783          	lbu	a5,-81(s0)
 20e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 212:	01578763          	beq	a5,s5,220 <gets+0x54>
 216:	0905                	addi	s2,s2,1
 218:	fd679be3          	bne	a5,s6,1ee <gets+0x22>
  for(i=0; i+1 < max; ){
 21c:	89a6                	mv	s3,s1
 21e:	a011                	j	222 <gets+0x56>
 220:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 222:	99de                	add	s3,s3,s7
 224:	00098023          	sb	zero,0(s3)
  return buf;
}
 228:	855e                	mv	a0,s7
 22a:	60e6                	ld	ra,88(sp)
 22c:	6446                	ld	s0,80(sp)
 22e:	64a6                	ld	s1,72(sp)
 230:	6906                	ld	s2,64(sp)
 232:	79e2                	ld	s3,56(sp)
 234:	7a42                	ld	s4,48(sp)
 236:	7aa2                	ld	s5,40(sp)
 238:	7b02                	ld	s6,32(sp)
 23a:	6be2                	ld	s7,24(sp)
 23c:	6125                	addi	sp,sp,96
 23e:	8082                	ret

0000000000000240 <stat>:

int
stat(const char *n, struct stat *st)
{
 240:	1101                	addi	sp,sp,-32
 242:	ec06                	sd	ra,24(sp)
 244:	e822                	sd	s0,16(sp)
 246:	e426                	sd	s1,8(sp)
 248:	e04a                	sd	s2,0(sp)
 24a:	1000                	addi	s0,sp,32
 24c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 24e:	4581                	li	a1,0
 250:	00000097          	auipc	ra,0x0
 254:	170080e7          	jalr	368(ra) # 3c0 <open>
  if(fd < 0)
 258:	02054563          	bltz	a0,282 <stat+0x42>
 25c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 25e:	85ca                	mv	a1,s2
 260:	00000097          	auipc	ra,0x0
 264:	178080e7          	jalr	376(ra) # 3d8 <fstat>
 268:	892a                	mv	s2,a0
  close(fd);
 26a:	8526                	mv	a0,s1
 26c:	00000097          	auipc	ra,0x0
 270:	13c080e7          	jalr	316(ra) # 3a8 <close>
  return r;
}
 274:	854a                	mv	a0,s2
 276:	60e2                	ld	ra,24(sp)
 278:	6442                	ld	s0,16(sp)
 27a:	64a2                	ld	s1,8(sp)
 27c:	6902                	ld	s2,0(sp)
 27e:	6105                	addi	sp,sp,32
 280:	8082                	ret
    return -1;
 282:	597d                	li	s2,-1
 284:	bfc5                	j	274 <stat+0x34>

0000000000000286 <atoi>:

int
atoi(const char *s)
{
 286:	1141                	addi	sp,sp,-16
 288:	e422                	sd	s0,8(sp)
 28a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 28c:	00054683          	lbu	a3,0(a0)
 290:	fd06879b          	addiw	a5,a3,-48
 294:	0ff7f793          	zext.b	a5,a5
 298:	4625                	li	a2,9
 29a:	02f66863          	bltu	a2,a5,2ca <atoi+0x44>
 29e:	872a                	mv	a4,a0
  n = 0;
 2a0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 2a2:	0705                	addi	a4,a4,1
 2a4:	0025179b          	slliw	a5,a0,0x2
 2a8:	9fa9                	addw	a5,a5,a0
 2aa:	0017979b          	slliw	a5,a5,0x1
 2ae:	9fb5                	addw	a5,a5,a3
 2b0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2b4:	00074683          	lbu	a3,0(a4)
 2b8:	fd06879b          	addiw	a5,a3,-48
 2bc:	0ff7f793          	zext.b	a5,a5
 2c0:	fef671e3          	bgeu	a2,a5,2a2 <atoi+0x1c>
  return n;
}
 2c4:	6422                	ld	s0,8(sp)
 2c6:	0141                	addi	sp,sp,16
 2c8:	8082                	ret
  n = 0;
 2ca:	4501                	li	a0,0
 2cc:	bfe5                	j	2c4 <atoi+0x3e>

00000000000002ce <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ce:	1141                	addi	sp,sp,-16
 2d0:	e422                	sd	s0,8(sp)
 2d2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2d4:	02b57463          	bgeu	a0,a1,2fc <memmove+0x2e>
    while(n-- > 0)
 2d8:	00c05f63          	blez	a2,2f6 <memmove+0x28>
 2dc:	1602                	slli	a2,a2,0x20
 2de:	9201                	srli	a2,a2,0x20
 2e0:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2e4:	872a                	mv	a4,a0
      *dst++ = *src++;
 2e6:	0585                	addi	a1,a1,1
 2e8:	0705                	addi	a4,a4,1
 2ea:	fff5c683          	lbu	a3,-1(a1)
 2ee:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2f2:	fee79ae3          	bne	a5,a4,2e6 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2f6:	6422                	ld	s0,8(sp)
 2f8:	0141                	addi	sp,sp,16
 2fa:	8082                	ret
    dst += n;
 2fc:	00c50733          	add	a4,a0,a2
    src += n;
 300:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 302:	fec05ae3          	blez	a2,2f6 <memmove+0x28>
 306:	fff6079b          	addiw	a5,a2,-1
 30a:	1782                	slli	a5,a5,0x20
 30c:	9381                	srli	a5,a5,0x20
 30e:	fff7c793          	not	a5,a5
 312:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 314:	15fd                	addi	a1,a1,-1
 316:	177d                	addi	a4,a4,-1
 318:	0005c683          	lbu	a3,0(a1)
 31c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 320:	fee79ae3          	bne	a5,a4,314 <memmove+0x46>
 324:	bfc9                	j	2f6 <memmove+0x28>

0000000000000326 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 326:	1141                	addi	sp,sp,-16
 328:	e422                	sd	s0,8(sp)
 32a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 32c:	ca05                	beqz	a2,35c <memcmp+0x36>
 32e:	fff6069b          	addiw	a3,a2,-1
 332:	1682                	slli	a3,a3,0x20
 334:	9281                	srli	a3,a3,0x20
 336:	0685                	addi	a3,a3,1
 338:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 33a:	00054783          	lbu	a5,0(a0)
 33e:	0005c703          	lbu	a4,0(a1)
 342:	00e79863          	bne	a5,a4,352 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 346:	0505                	addi	a0,a0,1
    p2++;
 348:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 34a:	fed518e3          	bne	a0,a3,33a <memcmp+0x14>
  }
  return 0;
 34e:	4501                	li	a0,0
 350:	a019                	j	356 <memcmp+0x30>
      return *p1 - *p2;
 352:	40e7853b          	subw	a0,a5,a4
}
 356:	6422                	ld	s0,8(sp)
 358:	0141                	addi	sp,sp,16
 35a:	8082                	ret
  return 0;
 35c:	4501                	li	a0,0
 35e:	bfe5                	j	356 <memcmp+0x30>

0000000000000360 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 360:	1141                	addi	sp,sp,-16
 362:	e406                	sd	ra,8(sp)
 364:	e022                	sd	s0,0(sp)
 366:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 368:	00000097          	auipc	ra,0x0
 36c:	f66080e7          	jalr	-154(ra) # 2ce <memmove>
}
 370:	60a2                	ld	ra,8(sp)
 372:	6402                	ld	s0,0(sp)
 374:	0141                	addi	sp,sp,16
 376:	8082                	ret

0000000000000378 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 378:	4885                	li	a7,1
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <exit>:
.global exit
exit:
 li a7, SYS_exit
 380:	4889                	li	a7,2
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <wait>:
.global wait
wait:
 li a7, SYS_wait
 388:	488d                	li	a7,3
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 390:	4891                	li	a7,4
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <read>:
.global read
read:
 li a7, SYS_read
 398:	4895                	li	a7,5
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <write>:
.global write
write:
 li a7, SYS_write
 3a0:	48c1                	li	a7,16
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <close>:
.global close
close:
 li a7, SYS_close
 3a8:	48d5                	li	a7,21
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3b0:	4899                	li	a7,6
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3b8:	489d                	li	a7,7
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <open>:
.global open
open:
 li a7, SYS_open
 3c0:	48bd                	li	a7,15
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3c8:	48c5                	li	a7,17
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3d0:	48c9                	li	a7,18
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3d8:	48a1                	li	a7,8
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <link>:
.global link
link:
 li a7, SYS_link
 3e0:	48cd                	li	a7,19
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3e8:	48d1                	li	a7,20
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3f0:	48a5                	li	a7,9
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3f8:	48a9                	li	a7,10
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 400:	48ad                	li	a7,11
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 408:	48b1                	li	a7,12
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 410:	48b5                	li	a7,13
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 418:	48b9                	li	a7,14
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 420:	48d9                	li	a7,22
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 428:	48dd                	li	a7,23
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 430:	48e1                	li	a7,24
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 438:	48e5                	li	a7,25
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 440:	1101                	addi	sp,sp,-32
 442:	ec06                	sd	ra,24(sp)
 444:	e822                	sd	s0,16(sp)
 446:	1000                	addi	s0,sp,32
 448:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 44c:	4605                	li	a2,1
 44e:	fef40593          	addi	a1,s0,-17
 452:	00000097          	auipc	ra,0x0
 456:	f4e080e7          	jalr	-178(ra) # 3a0 <write>
}
 45a:	60e2                	ld	ra,24(sp)
 45c:	6442                	ld	s0,16(sp)
 45e:	6105                	addi	sp,sp,32
 460:	8082                	ret

0000000000000462 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 462:	7139                	addi	sp,sp,-64
 464:	fc06                	sd	ra,56(sp)
 466:	f822                	sd	s0,48(sp)
 468:	f426                	sd	s1,40(sp)
 46a:	f04a                	sd	s2,32(sp)
 46c:	ec4e                	sd	s3,24(sp)
 46e:	0080                	addi	s0,sp,64
 470:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 472:	c299                	beqz	a3,478 <printint+0x16>
 474:	0805c963          	bltz	a1,506 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 478:	2581                	sext.w	a1,a1
  neg = 0;
 47a:	4881                	li	a7,0
 47c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 480:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 482:	2601                	sext.w	a2,a2
 484:	00000517          	auipc	a0,0x0
 488:	58450513          	addi	a0,a0,1412 # a08 <digits>
 48c:	883a                	mv	a6,a4
 48e:	2705                	addiw	a4,a4,1
 490:	02c5f7bb          	remuw	a5,a1,a2
 494:	1782                	slli	a5,a5,0x20
 496:	9381                	srli	a5,a5,0x20
 498:	97aa                	add	a5,a5,a0
 49a:	0007c783          	lbu	a5,0(a5)
 49e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4a2:	0005879b          	sext.w	a5,a1
 4a6:	02c5d5bb          	divuw	a1,a1,a2
 4aa:	0685                	addi	a3,a3,1
 4ac:	fec7f0e3          	bgeu	a5,a2,48c <printint+0x2a>
  if(neg)
 4b0:	00088c63          	beqz	a7,4c8 <printint+0x66>
    buf[i++] = '-';
 4b4:	fd070793          	addi	a5,a4,-48
 4b8:	00878733          	add	a4,a5,s0
 4bc:	02d00793          	li	a5,45
 4c0:	fef70823          	sb	a5,-16(a4)
 4c4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4c8:	02e05863          	blez	a4,4f8 <printint+0x96>
 4cc:	fc040793          	addi	a5,s0,-64
 4d0:	00e78933          	add	s2,a5,a4
 4d4:	fff78993          	addi	s3,a5,-1
 4d8:	99ba                	add	s3,s3,a4
 4da:	377d                	addiw	a4,a4,-1
 4dc:	1702                	slli	a4,a4,0x20
 4de:	9301                	srli	a4,a4,0x20
 4e0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4e4:	fff94583          	lbu	a1,-1(s2)
 4e8:	8526                	mv	a0,s1
 4ea:	00000097          	auipc	ra,0x0
 4ee:	f56080e7          	jalr	-170(ra) # 440 <putc>
  while(--i >= 0)
 4f2:	197d                	addi	s2,s2,-1
 4f4:	ff3918e3          	bne	s2,s3,4e4 <printint+0x82>
}
 4f8:	70e2                	ld	ra,56(sp)
 4fa:	7442                	ld	s0,48(sp)
 4fc:	74a2                	ld	s1,40(sp)
 4fe:	7902                	ld	s2,32(sp)
 500:	69e2                	ld	s3,24(sp)
 502:	6121                	addi	sp,sp,64
 504:	8082                	ret
    x = -xx;
 506:	40b005bb          	negw	a1,a1
    neg = 1;
 50a:	4885                	li	a7,1
    x = -xx;
 50c:	bf85                	j	47c <printint+0x1a>

000000000000050e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 50e:	7119                	addi	sp,sp,-128
 510:	fc86                	sd	ra,120(sp)
 512:	f8a2                	sd	s0,112(sp)
 514:	f4a6                	sd	s1,104(sp)
 516:	f0ca                	sd	s2,96(sp)
 518:	ecce                	sd	s3,88(sp)
 51a:	e8d2                	sd	s4,80(sp)
 51c:	e4d6                	sd	s5,72(sp)
 51e:	e0da                	sd	s6,64(sp)
 520:	fc5e                	sd	s7,56(sp)
 522:	f862                	sd	s8,48(sp)
 524:	f466                	sd	s9,40(sp)
 526:	f06a                	sd	s10,32(sp)
 528:	ec6e                	sd	s11,24(sp)
 52a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 52c:	0005c903          	lbu	s2,0(a1)
 530:	18090f63          	beqz	s2,6ce <vprintf+0x1c0>
 534:	8aaa                	mv	s5,a0
 536:	8b32                	mv	s6,a2
 538:	00158493          	addi	s1,a1,1
  state = 0;
 53c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 53e:	02500a13          	li	s4,37
 542:	4c55                	li	s8,21
 544:	00000c97          	auipc	s9,0x0
 548:	46cc8c93          	addi	s9,s9,1132 # 9b0 <malloc+0x1de>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 54c:	02800d93          	li	s11,40
  putc(fd, 'x');
 550:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 552:	00000b97          	auipc	s7,0x0
 556:	4b6b8b93          	addi	s7,s7,1206 # a08 <digits>
 55a:	a839                	j	578 <vprintf+0x6a>
        putc(fd, c);
 55c:	85ca                	mv	a1,s2
 55e:	8556                	mv	a0,s5
 560:	00000097          	auipc	ra,0x0
 564:	ee0080e7          	jalr	-288(ra) # 440 <putc>
 568:	a019                	j	56e <vprintf+0x60>
    } else if(state == '%'){
 56a:	01498d63          	beq	s3,s4,584 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 56e:	0485                	addi	s1,s1,1
 570:	fff4c903          	lbu	s2,-1(s1)
 574:	14090d63          	beqz	s2,6ce <vprintf+0x1c0>
    if(state == 0){
 578:	fe0999e3          	bnez	s3,56a <vprintf+0x5c>
      if(c == '%'){
 57c:	ff4910e3          	bne	s2,s4,55c <vprintf+0x4e>
        state = '%';
 580:	89d2                	mv	s3,s4
 582:	b7f5                	j	56e <vprintf+0x60>
      if(c == 'd'){
 584:	11490c63          	beq	s2,s4,69c <vprintf+0x18e>
 588:	f9d9079b          	addiw	a5,s2,-99
 58c:	0ff7f793          	zext.b	a5,a5
 590:	10fc6e63          	bltu	s8,a5,6ac <vprintf+0x19e>
 594:	f9d9079b          	addiw	a5,s2,-99
 598:	0ff7f713          	zext.b	a4,a5
 59c:	10ec6863          	bltu	s8,a4,6ac <vprintf+0x19e>
 5a0:	00271793          	slli	a5,a4,0x2
 5a4:	97e6                	add	a5,a5,s9
 5a6:	439c                	lw	a5,0(a5)
 5a8:	97e6                	add	a5,a5,s9
 5aa:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 5ac:	008b0913          	addi	s2,s6,8
 5b0:	4685                	li	a3,1
 5b2:	4629                	li	a2,10
 5b4:	000b2583          	lw	a1,0(s6)
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	ea8080e7          	jalr	-344(ra) # 462 <printint>
 5c2:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 5c4:	4981                	li	s3,0
 5c6:	b765                	j	56e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5c8:	008b0913          	addi	s2,s6,8
 5cc:	4681                	li	a3,0
 5ce:	4629                	li	a2,10
 5d0:	000b2583          	lw	a1,0(s6)
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	e8c080e7          	jalr	-372(ra) # 462 <printint>
 5de:	8b4a                	mv	s6,s2
      state = 0;
 5e0:	4981                	li	s3,0
 5e2:	b771                	j	56e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5e4:	008b0913          	addi	s2,s6,8
 5e8:	4681                	li	a3,0
 5ea:	866a                	mv	a2,s10
 5ec:	000b2583          	lw	a1,0(s6)
 5f0:	8556                	mv	a0,s5
 5f2:	00000097          	auipc	ra,0x0
 5f6:	e70080e7          	jalr	-400(ra) # 462 <printint>
 5fa:	8b4a                	mv	s6,s2
      state = 0;
 5fc:	4981                	li	s3,0
 5fe:	bf85                	j	56e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 600:	008b0793          	addi	a5,s6,8
 604:	f8f43423          	sd	a5,-120(s0)
 608:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 60c:	03000593          	li	a1,48
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e2e080e7          	jalr	-466(ra) # 440 <putc>
  putc(fd, 'x');
 61a:	07800593          	li	a1,120
 61e:	8556                	mv	a0,s5
 620:	00000097          	auipc	ra,0x0
 624:	e20080e7          	jalr	-480(ra) # 440 <putc>
 628:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 62a:	03c9d793          	srli	a5,s3,0x3c
 62e:	97de                	add	a5,a5,s7
 630:	0007c583          	lbu	a1,0(a5)
 634:	8556                	mv	a0,s5
 636:	00000097          	auipc	ra,0x0
 63a:	e0a080e7          	jalr	-502(ra) # 440 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 63e:	0992                	slli	s3,s3,0x4
 640:	397d                	addiw	s2,s2,-1
 642:	fe0914e3          	bnez	s2,62a <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 646:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 64a:	4981                	li	s3,0
 64c:	b70d                	j	56e <vprintf+0x60>
        s = va_arg(ap, char*);
 64e:	008b0913          	addi	s2,s6,8
 652:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 656:	02098163          	beqz	s3,678 <vprintf+0x16a>
        while(*s != 0){
 65a:	0009c583          	lbu	a1,0(s3)
 65e:	c5ad                	beqz	a1,6c8 <vprintf+0x1ba>
          putc(fd, *s);
 660:	8556                	mv	a0,s5
 662:	00000097          	auipc	ra,0x0
 666:	dde080e7          	jalr	-546(ra) # 440 <putc>
          s++;
 66a:	0985                	addi	s3,s3,1
        while(*s != 0){
 66c:	0009c583          	lbu	a1,0(s3)
 670:	f9e5                	bnez	a1,660 <vprintf+0x152>
        s = va_arg(ap, char*);
 672:	8b4a                	mv	s6,s2
      state = 0;
 674:	4981                	li	s3,0
 676:	bde5                	j	56e <vprintf+0x60>
          s = "(null)";
 678:	00000997          	auipc	s3,0x0
 67c:	33098993          	addi	s3,s3,816 # 9a8 <malloc+0x1d6>
        while(*s != 0){
 680:	85ee                	mv	a1,s11
 682:	bff9                	j	660 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 684:	008b0913          	addi	s2,s6,8
 688:	000b4583          	lbu	a1,0(s6)
 68c:	8556                	mv	a0,s5
 68e:	00000097          	auipc	ra,0x0
 692:	db2080e7          	jalr	-590(ra) # 440 <putc>
 696:	8b4a                	mv	s6,s2
      state = 0;
 698:	4981                	li	s3,0
 69a:	bdd1                	j	56e <vprintf+0x60>
        putc(fd, c);
 69c:	85d2                	mv	a1,s4
 69e:	8556                	mv	a0,s5
 6a0:	00000097          	auipc	ra,0x0
 6a4:	da0080e7          	jalr	-608(ra) # 440 <putc>
      state = 0;
 6a8:	4981                	li	s3,0
 6aa:	b5d1                	j	56e <vprintf+0x60>
        putc(fd, '%');
 6ac:	85d2                	mv	a1,s4
 6ae:	8556                	mv	a0,s5
 6b0:	00000097          	auipc	ra,0x0
 6b4:	d90080e7          	jalr	-624(ra) # 440 <putc>
        putc(fd, c);
 6b8:	85ca                	mv	a1,s2
 6ba:	8556                	mv	a0,s5
 6bc:	00000097          	auipc	ra,0x0
 6c0:	d84080e7          	jalr	-636(ra) # 440 <putc>
      state = 0;
 6c4:	4981                	li	s3,0
 6c6:	b565                	j	56e <vprintf+0x60>
        s = va_arg(ap, char*);
 6c8:	8b4a                	mv	s6,s2
      state = 0;
 6ca:	4981                	li	s3,0
 6cc:	b54d                	j	56e <vprintf+0x60>
    }
  }
}
 6ce:	70e6                	ld	ra,120(sp)
 6d0:	7446                	ld	s0,112(sp)
 6d2:	74a6                	ld	s1,104(sp)
 6d4:	7906                	ld	s2,96(sp)
 6d6:	69e6                	ld	s3,88(sp)
 6d8:	6a46                	ld	s4,80(sp)
 6da:	6aa6                	ld	s5,72(sp)
 6dc:	6b06                	ld	s6,64(sp)
 6de:	7be2                	ld	s7,56(sp)
 6e0:	7c42                	ld	s8,48(sp)
 6e2:	7ca2                	ld	s9,40(sp)
 6e4:	7d02                	ld	s10,32(sp)
 6e6:	6de2                	ld	s11,24(sp)
 6e8:	6109                	addi	sp,sp,128
 6ea:	8082                	ret

00000000000006ec <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6ec:	715d                	addi	sp,sp,-80
 6ee:	ec06                	sd	ra,24(sp)
 6f0:	e822                	sd	s0,16(sp)
 6f2:	1000                	addi	s0,sp,32
 6f4:	e010                	sd	a2,0(s0)
 6f6:	e414                	sd	a3,8(s0)
 6f8:	e818                	sd	a4,16(s0)
 6fa:	ec1c                	sd	a5,24(s0)
 6fc:	03043023          	sd	a6,32(s0)
 700:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 704:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 708:	8622                	mv	a2,s0
 70a:	00000097          	auipc	ra,0x0
 70e:	e04080e7          	jalr	-508(ra) # 50e <vprintf>
}
 712:	60e2                	ld	ra,24(sp)
 714:	6442                	ld	s0,16(sp)
 716:	6161                	addi	sp,sp,80
 718:	8082                	ret

000000000000071a <printf>:

void
printf(const char *fmt, ...)
{
 71a:	711d                	addi	sp,sp,-96
 71c:	ec06                	sd	ra,24(sp)
 71e:	e822                	sd	s0,16(sp)
 720:	1000                	addi	s0,sp,32
 722:	e40c                	sd	a1,8(s0)
 724:	e810                	sd	a2,16(s0)
 726:	ec14                	sd	a3,24(s0)
 728:	f018                	sd	a4,32(s0)
 72a:	f41c                	sd	a5,40(s0)
 72c:	03043823          	sd	a6,48(s0)
 730:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 734:	00840613          	addi	a2,s0,8
 738:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 73c:	85aa                	mv	a1,a0
 73e:	4505                	li	a0,1
 740:	00000097          	auipc	ra,0x0
 744:	dce080e7          	jalr	-562(ra) # 50e <vprintf>
}
 748:	60e2                	ld	ra,24(sp)
 74a:	6442                	ld	s0,16(sp)
 74c:	6125                	addi	sp,sp,96
 74e:	8082                	ret

0000000000000750 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 750:	1141                	addi	sp,sp,-16
 752:	e422                	sd	s0,8(sp)
 754:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 756:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 75a:	00000797          	auipc	a5,0x0
 75e:	2c67b783          	ld	a5,710(a5) # a20 <freep>
 762:	a02d                	j	78c <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 764:	4618                	lw	a4,8(a2)
 766:	9f2d                	addw	a4,a4,a1
 768:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 76c:	6398                	ld	a4,0(a5)
 76e:	6310                	ld	a2,0(a4)
 770:	a83d                	j	7ae <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 772:	ff852703          	lw	a4,-8(a0)
 776:	9f31                	addw	a4,a4,a2
 778:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 77a:	ff053683          	ld	a3,-16(a0)
 77e:	a091                	j	7c2 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 780:	6398                	ld	a4,0(a5)
 782:	00e7e463          	bltu	a5,a4,78a <free+0x3a>
 786:	00e6ea63          	bltu	a3,a4,79a <free+0x4a>
{
 78a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 78c:	fed7fae3          	bgeu	a5,a3,780 <free+0x30>
 790:	6398                	ld	a4,0(a5)
 792:	00e6e463          	bltu	a3,a4,79a <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 796:	fee7eae3          	bltu	a5,a4,78a <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 79a:	ff852583          	lw	a1,-8(a0)
 79e:	6390                	ld	a2,0(a5)
 7a0:	02059813          	slli	a6,a1,0x20
 7a4:	01c85713          	srli	a4,a6,0x1c
 7a8:	9736                	add	a4,a4,a3
 7aa:	fae60de3          	beq	a2,a4,764 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 7ae:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7b2:	4790                	lw	a2,8(a5)
 7b4:	02061593          	slli	a1,a2,0x20
 7b8:	01c5d713          	srli	a4,a1,0x1c
 7bc:	973e                	add	a4,a4,a5
 7be:	fae68ae3          	beq	a3,a4,772 <free+0x22>
    p->s.ptr = bp->s.ptr;
 7c2:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 7c4:	00000717          	auipc	a4,0x0
 7c8:	24f73e23          	sd	a5,604(a4) # a20 <freep>
}
 7cc:	6422                	ld	s0,8(sp)
 7ce:	0141                	addi	sp,sp,16
 7d0:	8082                	ret

00000000000007d2 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7d2:	7139                	addi	sp,sp,-64
 7d4:	fc06                	sd	ra,56(sp)
 7d6:	f822                	sd	s0,48(sp)
 7d8:	f426                	sd	s1,40(sp)
 7da:	f04a                	sd	s2,32(sp)
 7dc:	ec4e                	sd	s3,24(sp)
 7de:	e852                	sd	s4,16(sp)
 7e0:	e456                	sd	s5,8(sp)
 7e2:	e05a                	sd	s6,0(sp)
 7e4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7e6:	02051493          	slli	s1,a0,0x20
 7ea:	9081                	srli	s1,s1,0x20
 7ec:	04bd                	addi	s1,s1,15
 7ee:	8091                	srli	s1,s1,0x4
 7f0:	0014899b          	addiw	s3,s1,1
 7f4:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7f6:	00000517          	auipc	a0,0x0
 7fa:	22a53503          	ld	a0,554(a0) # a20 <freep>
 7fe:	c515                	beqz	a0,82a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 800:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 802:	4798                	lw	a4,8(a5)
 804:	02977f63          	bgeu	a4,s1,842 <malloc+0x70>
 808:	8a4e                	mv	s4,s3
 80a:	0009871b          	sext.w	a4,s3
 80e:	6685                	lui	a3,0x1
 810:	00d77363          	bgeu	a4,a3,816 <malloc+0x44>
 814:	6a05                	lui	s4,0x1
 816:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 81a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 81e:	00000917          	auipc	s2,0x0
 822:	20290913          	addi	s2,s2,514 # a20 <freep>
  if(p == (char*)-1)
 826:	5afd                	li	s5,-1
 828:	a895                	j	89c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 82a:	00000797          	auipc	a5,0x0
 82e:	1fe78793          	addi	a5,a5,510 # a28 <base>
 832:	00000717          	auipc	a4,0x0
 836:	1ef73723          	sd	a5,494(a4) # a20 <freep>
 83a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 83c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 840:	b7e1                	j	808 <malloc+0x36>
      if(p->s.size == nunits)
 842:	02e48c63          	beq	s1,a4,87a <malloc+0xa8>
        p->s.size -= nunits;
 846:	4137073b          	subw	a4,a4,s3
 84a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 84c:	02071693          	slli	a3,a4,0x20
 850:	01c6d713          	srli	a4,a3,0x1c
 854:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 856:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 85a:	00000717          	auipc	a4,0x0
 85e:	1ca73323          	sd	a0,454(a4) # a20 <freep>
      return (void*)(p + 1);
 862:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 866:	70e2                	ld	ra,56(sp)
 868:	7442                	ld	s0,48(sp)
 86a:	74a2                	ld	s1,40(sp)
 86c:	7902                	ld	s2,32(sp)
 86e:	69e2                	ld	s3,24(sp)
 870:	6a42                	ld	s4,16(sp)
 872:	6aa2                	ld	s5,8(sp)
 874:	6b02                	ld	s6,0(sp)
 876:	6121                	addi	sp,sp,64
 878:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 87a:	6398                	ld	a4,0(a5)
 87c:	e118                	sd	a4,0(a0)
 87e:	bff1                	j	85a <malloc+0x88>
  hp->s.size = nu;
 880:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 884:	0541                	addi	a0,a0,16
 886:	00000097          	auipc	ra,0x0
 88a:	eca080e7          	jalr	-310(ra) # 750 <free>
  return freep;
 88e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 892:	d971                	beqz	a0,866 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 894:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 896:	4798                	lw	a4,8(a5)
 898:	fa9775e3          	bgeu	a4,s1,842 <malloc+0x70>
    if(p == freep)
 89c:	00093703          	ld	a4,0(s2)
 8a0:	853e                	mv	a0,a5
 8a2:	fef719e3          	bne	a4,a5,894 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 8a6:	8552                	mv	a0,s4
 8a8:	00000097          	auipc	ra,0x0
 8ac:	b60080e7          	jalr	-1184(ra) # 408 <sbrk>
  if(p == (char*)-1)
 8b0:	fd5518e3          	bne	a0,s5,880 <malloc+0xae>
        return 0;
 8b4:	4501                	li	a0,0
 8b6:	bf45                	j	866 <malloc+0x94>
