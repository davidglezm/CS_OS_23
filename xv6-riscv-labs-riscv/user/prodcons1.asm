
user/_prodcons1:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <producer>:
} buffer_t;

buffer_t *buffer;

void *producer()
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    while(1) {
        if (buffer->num_produced >= MAX) {
   8:	00001797          	auipc	a5,0x1
   c:	9587b783          	ld	a5,-1704(a5) # 960 <buffer>
  10:	5b98                	lw	a4,48(a5)
  12:	46a5                	li	a3,9
	    exit(0);
	}
	buffer->num_produced++;
	buffer->buf[buffer->nextin++] = buffer->num_produced;
	buffer->nextin %= BSIZE;
  14:	00001817          	auipc	a6,0x1
  18:	94c80813          	addi	a6,a6,-1716 # 960 <buffer>
  1c:	4529                	li	a0,10
        if (buffer->num_produced >= MAX) {
  1e:	45a5                	li	a1,9
  20:	02e6c463          	blt	a3,a4,48 <producer+0x48>
	buffer->num_produced++;
  24:	2705                	addiw	a4,a4,1
  26:	db98                	sw	a4,48(a5)
	buffer->buf[buffer->nextin++] = buffer->num_produced;
  28:	5794                	lw	a3,40(a5)
  2a:	0016861b          	addiw	a2,a3,1
  2e:	d790                	sw	a2,40(a5)
  30:	068a                	slli	a3,a3,0x2
  32:	97b6                	add	a5,a5,a3
  34:	c398                	sw	a4,0(a5)
	buffer->nextin %= BSIZE;
  36:	00083783          	ld	a5,0(a6)
  3a:	5798                	lw	a4,40(a5)
  3c:	02a7673b          	remw	a4,a4,a0
  40:	d798                	sw	a4,40(a5)
        if (buffer->num_produced >= MAX) {
  42:	5b98                	lw	a4,48(a5)
  44:	fee5d0e3          	bge	a1,a4,24 <producer+0x24>
	    exit(0);
  48:	4501                	li	a0,0
  4a:	00000097          	auipc	ra,0x0
  4e:	356080e7          	jalr	854(ra) # 3a0 <exit>

0000000000000052 <consumer>:
    }
}

void *consumer()
{
  52:	1141                	addi	sp,sp,-16
  54:	e406                	sd	ra,8(sp)
  56:	e022                	sd	s0,0(sp)
  58:	0800                	addi	s0,sp,16
    while(1) {
        if (buffer->num_consumed >= MAX) {
  5a:	00001597          	auipc	a1,0x1
  5e:	9065b583          	ld	a1,-1786(a1) # 960 <buffer>
  62:	59d4                	lw	a3,52(a1)
  64:	47a5                	li	a5,9
  66:	02d7c663          	blt	a5,a3,92 <consumer+0x40>
  6a:	55dc                	lw	a5,44(a1)
  6c:	5d90                	lw	a2,56(a1)
  6e:	2685                	addiw	a3,a3,1
	    exit(0);
	}
	buffer->total += buffer->buf[buffer->nextout++];
	buffer->nextout %= BSIZE;
  70:	4829                	li	a6,10
        if (buffer->num_consumed >= MAX) {
  72:	452d                	li	a0,11
	buffer->total += buffer->buf[buffer->nextout++];
  74:	00279713          	slli	a4,a5,0x2
  78:	972e                	add	a4,a4,a1
  7a:	4318                	lw	a4,0(a4)
  7c:	9e39                	addw	a2,a2,a4
  7e:	2785                	addiw	a5,a5,1
	buffer->nextout %= BSIZE;
  80:	0307e7bb          	remw	a5,a5,a6
        if (buffer->num_consumed >= MAX) {
  84:	2685                	addiw	a3,a3,1
  86:	fea697e3          	bne	a3,a0,74 <consumer+0x22>
  8a:	dd90                	sw	a2,56(a1)
  8c:	d5dc                	sw	a5,44(a1)
  8e:	47a9                	li	a5,10
  90:	d9dc                	sw	a5,52(a1)
	    exit(0);
  92:	4501                	li	a0,0
  94:	00000097          	auipc	ra,0x0
  98:	30c080e7          	jalr	780(ra) # 3a0 <exit>

000000000000009c <main>:
	buffer->num_consumed++;
    }
}

int main(int argc, char *argv[])
{
  9c:	1141                	addi	sp,sp,-16
  9e:	e406                	sd	ra,8(sp)
  a0:	e022                	sd	s0,0(sp)
  a2:	0800                	addi	s0,sp,16
    buffer = (buffer_t *) mmap(NULL, sizeof(buffer_t),
  a4:	4781                	li	a5,0
  a6:	577d                	li	a4,-1
  a8:	02100693          	li	a3,33
  ac:	4619                	li	a2,6
  ae:	03c00593          	li	a1,60
  b2:	4501                	li	a0,0
  b4:	00000097          	auipc	ra,0x0
  b8:	39c080e7          	jalr	924(ra) # 450 <mmap>
  bc:	00001797          	auipc	a5,0x1
  c0:	8aa7b223          	sd	a0,-1884(a5) # 960 <buffer>
		               PROT_READ | PROT_WRITE,
			       MAP_ANONYMOUS | MAP_SHARED, -1, 0);
    buffer->nextin = 0;
  c4:	02052423          	sw	zero,40(a0)
    buffer->nextout = 0;
  c8:	02052623          	sw	zero,44(a0)
    buffer->num_produced = 0;
  cc:	02052823          	sw	zero,48(a0)
    buffer->num_consumed = 0;
  d0:	02052a23          	sw	zero,52(a0)
    buffer->total = 0;
  d4:	02052c23          	sw	zero,56(a0)
    if (!fork())
  d8:	00000097          	auipc	ra,0x0
  dc:	2c0080e7          	jalr	704(ra) # 398 <fork>
  e0:	e509                	bnez	a0,ea <main+0x4e>
        producer();
  e2:	00000097          	auipc	ra,0x0
  e6:	f1e080e7          	jalr	-226(ra) # 0 <producer>
    else {
	wait(0);
  ea:	4501                	li	a0,0
  ec:	00000097          	auipc	ra,0x0
  f0:	2bc080e7          	jalr	700(ra) # 3a8 <wait>
    }
    if (!fork())
  f4:	00000097          	auipc	ra,0x0
  f8:	2a4080e7          	jalr	676(ra) # 398 <fork>
  fc:	e509                	bnez	a0,106 <main+0x6a>
        consumer();
  fe:	00000097          	auipc	ra,0x0
 102:	f54080e7          	jalr	-172(ra) # 52 <consumer>
    else {
	wait(0);
 106:	4501                	li	a0,0
 108:	00000097          	auipc	ra,0x0
 10c:	2a0080e7          	jalr	672(ra) # 3a8 <wait>
    }
    printf("total = %d\n", buffer->total);
 110:	00001797          	auipc	a5,0x1
 114:	8507b783          	ld	a5,-1968(a5) # 960 <buffer>
 118:	5f8c                	lw	a1,56(a5)
 11a:	00000517          	auipc	a0,0x0
 11e:	7be50513          	addi	a0,a0,1982 # 8d8 <malloc+0xe6>
 122:	00000097          	auipc	ra,0x0
 126:	618080e7          	jalr	1560(ra) # 73a <printf>
    exit(0);
 12a:	4501                	li	a0,0
 12c:	00000097          	auipc	ra,0x0
 130:	274080e7          	jalr	628(ra) # 3a0 <exit>

0000000000000134 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 134:	1141                	addi	sp,sp,-16
 136:	e422                	sd	s0,8(sp)
 138:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 13a:	87aa                	mv	a5,a0
 13c:	0585                	addi	a1,a1,1
 13e:	0785                	addi	a5,a5,1
 140:	fff5c703          	lbu	a4,-1(a1)
 144:	fee78fa3          	sb	a4,-1(a5)
 148:	fb75                	bnez	a4,13c <strcpy+0x8>
    ;
  return os;
}
 14a:	6422                	ld	s0,8(sp)
 14c:	0141                	addi	sp,sp,16
 14e:	8082                	ret

0000000000000150 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 150:	1141                	addi	sp,sp,-16
 152:	e422                	sd	s0,8(sp)
 154:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 156:	00054783          	lbu	a5,0(a0)
 15a:	cb91                	beqz	a5,16e <strcmp+0x1e>
 15c:	0005c703          	lbu	a4,0(a1)
 160:	00f71763          	bne	a4,a5,16e <strcmp+0x1e>
    p++, q++;
 164:	0505                	addi	a0,a0,1
 166:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 168:	00054783          	lbu	a5,0(a0)
 16c:	fbe5                	bnez	a5,15c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 16e:	0005c503          	lbu	a0,0(a1)
}
 172:	40a7853b          	subw	a0,a5,a0
 176:	6422                	ld	s0,8(sp)
 178:	0141                	addi	sp,sp,16
 17a:	8082                	ret

000000000000017c <strlen>:

uint
strlen(const char *s)
{
 17c:	1141                	addi	sp,sp,-16
 17e:	e422                	sd	s0,8(sp)
 180:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 182:	00054783          	lbu	a5,0(a0)
 186:	cf91                	beqz	a5,1a2 <strlen+0x26>
 188:	0505                	addi	a0,a0,1
 18a:	87aa                	mv	a5,a0
 18c:	4685                	li	a3,1
 18e:	9e89                	subw	a3,a3,a0
 190:	00f6853b          	addw	a0,a3,a5
 194:	0785                	addi	a5,a5,1
 196:	fff7c703          	lbu	a4,-1(a5)
 19a:	fb7d                	bnez	a4,190 <strlen+0x14>
    ;
  return n;
}
 19c:	6422                	ld	s0,8(sp)
 19e:	0141                	addi	sp,sp,16
 1a0:	8082                	ret
  for(n = 0; s[n]; n++)
 1a2:	4501                	li	a0,0
 1a4:	bfe5                	j	19c <strlen+0x20>

00000000000001a6 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1a6:	1141                	addi	sp,sp,-16
 1a8:	e422                	sd	s0,8(sp)
 1aa:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1ac:	ca19                	beqz	a2,1c2 <memset+0x1c>
 1ae:	87aa                	mv	a5,a0
 1b0:	1602                	slli	a2,a2,0x20
 1b2:	9201                	srli	a2,a2,0x20
 1b4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 1b8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1bc:	0785                	addi	a5,a5,1
 1be:	fee79de3          	bne	a5,a4,1b8 <memset+0x12>
  }
  return dst;
}
 1c2:	6422                	ld	s0,8(sp)
 1c4:	0141                	addi	sp,sp,16
 1c6:	8082                	ret

00000000000001c8 <strchr>:

char*
strchr(const char *s, char c)
{
 1c8:	1141                	addi	sp,sp,-16
 1ca:	e422                	sd	s0,8(sp)
 1cc:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1ce:	00054783          	lbu	a5,0(a0)
 1d2:	cb99                	beqz	a5,1e8 <strchr+0x20>
    if(*s == c)
 1d4:	00f58763          	beq	a1,a5,1e2 <strchr+0x1a>
  for(; *s; s++)
 1d8:	0505                	addi	a0,a0,1
 1da:	00054783          	lbu	a5,0(a0)
 1de:	fbfd                	bnez	a5,1d4 <strchr+0xc>
      return (char*)s;
  return 0;
 1e0:	4501                	li	a0,0
}
 1e2:	6422                	ld	s0,8(sp)
 1e4:	0141                	addi	sp,sp,16
 1e6:	8082                	ret
  return 0;
 1e8:	4501                	li	a0,0
 1ea:	bfe5                	j	1e2 <strchr+0x1a>

00000000000001ec <gets>:

char*
gets(char *buf, int max)
{
 1ec:	711d                	addi	sp,sp,-96
 1ee:	ec86                	sd	ra,88(sp)
 1f0:	e8a2                	sd	s0,80(sp)
 1f2:	e4a6                	sd	s1,72(sp)
 1f4:	e0ca                	sd	s2,64(sp)
 1f6:	fc4e                	sd	s3,56(sp)
 1f8:	f852                	sd	s4,48(sp)
 1fa:	f456                	sd	s5,40(sp)
 1fc:	f05a                	sd	s6,32(sp)
 1fe:	ec5e                	sd	s7,24(sp)
 200:	1080                	addi	s0,sp,96
 202:	8baa                	mv	s7,a0
 204:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 206:	892a                	mv	s2,a0
 208:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 20a:	4aa9                	li	s5,10
 20c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 20e:	89a6                	mv	s3,s1
 210:	2485                	addiw	s1,s1,1
 212:	0344d863          	bge	s1,s4,242 <gets+0x56>
    cc = read(0, &c, 1);
 216:	4605                	li	a2,1
 218:	faf40593          	addi	a1,s0,-81
 21c:	4501                	li	a0,0
 21e:	00000097          	auipc	ra,0x0
 222:	19a080e7          	jalr	410(ra) # 3b8 <read>
    if(cc < 1)
 226:	00a05e63          	blez	a0,242 <gets+0x56>
    buf[i++] = c;
 22a:	faf44783          	lbu	a5,-81(s0)
 22e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 232:	01578763          	beq	a5,s5,240 <gets+0x54>
 236:	0905                	addi	s2,s2,1
 238:	fd679be3          	bne	a5,s6,20e <gets+0x22>
  for(i=0; i+1 < max; ){
 23c:	89a6                	mv	s3,s1
 23e:	a011                	j	242 <gets+0x56>
 240:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 242:	99de                	add	s3,s3,s7
 244:	00098023          	sb	zero,0(s3)
  return buf;
}
 248:	855e                	mv	a0,s7
 24a:	60e6                	ld	ra,88(sp)
 24c:	6446                	ld	s0,80(sp)
 24e:	64a6                	ld	s1,72(sp)
 250:	6906                	ld	s2,64(sp)
 252:	79e2                	ld	s3,56(sp)
 254:	7a42                	ld	s4,48(sp)
 256:	7aa2                	ld	s5,40(sp)
 258:	7b02                	ld	s6,32(sp)
 25a:	6be2                	ld	s7,24(sp)
 25c:	6125                	addi	sp,sp,96
 25e:	8082                	ret

0000000000000260 <stat>:

int
stat(const char *n, struct stat *st)
{
 260:	1101                	addi	sp,sp,-32
 262:	ec06                	sd	ra,24(sp)
 264:	e822                	sd	s0,16(sp)
 266:	e426                	sd	s1,8(sp)
 268:	e04a                	sd	s2,0(sp)
 26a:	1000                	addi	s0,sp,32
 26c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 26e:	4581                	li	a1,0
 270:	00000097          	auipc	ra,0x0
 274:	170080e7          	jalr	368(ra) # 3e0 <open>
  if(fd < 0)
 278:	02054563          	bltz	a0,2a2 <stat+0x42>
 27c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 27e:	85ca                	mv	a1,s2
 280:	00000097          	auipc	ra,0x0
 284:	178080e7          	jalr	376(ra) # 3f8 <fstat>
 288:	892a                	mv	s2,a0
  close(fd);
 28a:	8526                	mv	a0,s1
 28c:	00000097          	auipc	ra,0x0
 290:	13c080e7          	jalr	316(ra) # 3c8 <close>
  return r;
}
 294:	854a                	mv	a0,s2
 296:	60e2                	ld	ra,24(sp)
 298:	6442                	ld	s0,16(sp)
 29a:	64a2                	ld	s1,8(sp)
 29c:	6902                	ld	s2,0(sp)
 29e:	6105                	addi	sp,sp,32
 2a0:	8082                	ret
    return -1;
 2a2:	597d                	li	s2,-1
 2a4:	bfc5                	j	294 <stat+0x34>

00000000000002a6 <atoi>:

int
atoi(const char *s)
{
 2a6:	1141                	addi	sp,sp,-16
 2a8:	e422                	sd	s0,8(sp)
 2aa:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2ac:	00054683          	lbu	a3,0(a0)
 2b0:	fd06879b          	addiw	a5,a3,-48
 2b4:	0ff7f793          	zext.b	a5,a5
 2b8:	4625                	li	a2,9
 2ba:	02f66863          	bltu	a2,a5,2ea <atoi+0x44>
 2be:	872a                	mv	a4,a0
  n = 0;
 2c0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 2c2:	0705                	addi	a4,a4,1
 2c4:	0025179b          	slliw	a5,a0,0x2
 2c8:	9fa9                	addw	a5,a5,a0
 2ca:	0017979b          	slliw	a5,a5,0x1
 2ce:	9fb5                	addw	a5,a5,a3
 2d0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2d4:	00074683          	lbu	a3,0(a4)
 2d8:	fd06879b          	addiw	a5,a3,-48
 2dc:	0ff7f793          	zext.b	a5,a5
 2e0:	fef671e3          	bgeu	a2,a5,2c2 <atoi+0x1c>
  return n;
}
 2e4:	6422                	ld	s0,8(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret
  n = 0;
 2ea:	4501                	li	a0,0
 2ec:	bfe5                	j	2e4 <atoi+0x3e>

00000000000002ee <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2f4:	02b57463          	bgeu	a0,a1,31c <memmove+0x2e>
    while(n-- > 0)
 2f8:	00c05f63          	blez	a2,316 <memmove+0x28>
 2fc:	1602                	slli	a2,a2,0x20
 2fe:	9201                	srli	a2,a2,0x20
 300:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 304:	872a                	mv	a4,a0
      *dst++ = *src++;
 306:	0585                	addi	a1,a1,1
 308:	0705                	addi	a4,a4,1
 30a:	fff5c683          	lbu	a3,-1(a1)
 30e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 312:	fee79ae3          	bne	a5,a4,306 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 316:	6422                	ld	s0,8(sp)
 318:	0141                	addi	sp,sp,16
 31a:	8082                	ret
    dst += n;
 31c:	00c50733          	add	a4,a0,a2
    src += n;
 320:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 322:	fec05ae3          	blez	a2,316 <memmove+0x28>
 326:	fff6079b          	addiw	a5,a2,-1
 32a:	1782                	slli	a5,a5,0x20
 32c:	9381                	srli	a5,a5,0x20
 32e:	fff7c793          	not	a5,a5
 332:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 334:	15fd                	addi	a1,a1,-1
 336:	177d                	addi	a4,a4,-1
 338:	0005c683          	lbu	a3,0(a1)
 33c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 340:	fee79ae3          	bne	a5,a4,334 <memmove+0x46>
 344:	bfc9                	j	316 <memmove+0x28>

0000000000000346 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 346:	1141                	addi	sp,sp,-16
 348:	e422                	sd	s0,8(sp)
 34a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 34c:	ca05                	beqz	a2,37c <memcmp+0x36>
 34e:	fff6069b          	addiw	a3,a2,-1
 352:	1682                	slli	a3,a3,0x20
 354:	9281                	srli	a3,a3,0x20
 356:	0685                	addi	a3,a3,1
 358:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 35a:	00054783          	lbu	a5,0(a0)
 35e:	0005c703          	lbu	a4,0(a1)
 362:	00e79863          	bne	a5,a4,372 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 366:	0505                	addi	a0,a0,1
    p2++;
 368:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 36a:	fed518e3          	bne	a0,a3,35a <memcmp+0x14>
  }
  return 0;
 36e:	4501                	li	a0,0
 370:	a019                	j	376 <memcmp+0x30>
      return *p1 - *p2;
 372:	40e7853b          	subw	a0,a5,a4
}
 376:	6422                	ld	s0,8(sp)
 378:	0141                	addi	sp,sp,16
 37a:	8082                	ret
  return 0;
 37c:	4501                	li	a0,0
 37e:	bfe5                	j	376 <memcmp+0x30>

0000000000000380 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 380:	1141                	addi	sp,sp,-16
 382:	e406                	sd	ra,8(sp)
 384:	e022                	sd	s0,0(sp)
 386:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 388:	00000097          	auipc	ra,0x0
 38c:	f66080e7          	jalr	-154(ra) # 2ee <memmove>
}
 390:	60a2                	ld	ra,8(sp)
 392:	6402                	ld	s0,0(sp)
 394:	0141                	addi	sp,sp,16
 396:	8082                	ret

0000000000000398 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 398:	4885                	li	a7,1
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3a0:	4889                	li	a7,2
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3a8:	488d                	li	a7,3
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3b0:	4891                	li	a7,4
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <read>:
.global read
read:
 li a7, SYS_read
 3b8:	4895                	li	a7,5
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <write>:
.global write
write:
 li a7, SYS_write
 3c0:	48c1                	li	a7,16
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <close>:
.global close
close:
 li a7, SYS_close
 3c8:	48d5                	li	a7,21
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3d0:	4899                	li	a7,6
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3d8:	489d                	li	a7,7
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <open>:
.global open
open:
 li a7, SYS_open
 3e0:	48bd                	li	a7,15
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3e8:	48c5                	li	a7,17
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3f0:	48c9                	li	a7,18
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3f8:	48a1                	li	a7,8
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <link>:
.global link
link:
 li a7, SYS_link
 400:	48cd                	li	a7,19
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 408:	48d1                	li	a7,20
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 410:	48a5                	li	a7,9
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <dup>:
.global dup
dup:
 li a7, SYS_dup
 418:	48a9                	li	a7,10
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 420:	48ad                	li	a7,11
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 428:	48b1                	li	a7,12
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 430:	48b5                	li	a7,13
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 438:	48b9                	li	a7,14
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 440:	48d9                	li	a7,22
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 448:	48dd                	li	a7,23
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 450:	48e1                	li	a7,24
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 458:	48e5                	li	a7,25
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 460:	1101                	addi	sp,sp,-32
 462:	ec06                	sd	ra,24(sp)
 464:	e822                	sd	s0,16(sp)
 466:	1000                	addi	s0,sp,32
 468:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 46c:	4605                	li	a2,1
 46e:	fef40593          	addi	a1,s0,-17
 472:	00000097          	auipc	ra,0x0
 476:	f4e080e7          	jalr	-178(ra) # 3c0 <write>
}
 47a:	60e2                	ld	ra,24(sp)
 47c:	6442                	ld	s0,16(sp)
 47e:	6105                	addi	sp,sp,32
 480:	8082                	ret

0000000000000482 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 482:	7139                	addi	sp,sp,-64
 484:	fc06                	sd	ra,56(sp)
 486:	f822                	sd	s0,48(sp)
 488:	f426                	sd	s1,40(sp)
 48a:	f04a                	sd	s2,32(sp)
 48c:	ec4e                	sd	s3,24(sp)
 48e:	0080                	addi	s0,sp,64
 490:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 492:	c299                	beqz	a3,498 <printint+0x16>
 494:	0805c963          	bltz	a1,526 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 498:	2581                	sext.w	a1,a1
  neg = 0;
 49a:	4881                	li	a7,0
 49c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4a0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4a2:	2601                	sext.w	a2,a2
 4a4:	00000517          	auipc	a0,0x0
 4a8:	4a450513          	addi	a0,a0,1188 # 948 <digits>
 4ac:	883a                	mv	a6,a4
 4ae:	2705                	addiw	a4,a4,1
 4b0:	02c5f7bb          	remuw	a5,a1,a2
 4b4:	1782                	slli	a5,a5,0x20
 4b6:	9381                	srli	a5,a5,0x20
 4b8:	97aa                	add	a5,a5,a0
 4ba:	0007c783          	lbu	a5,0(a5)
 4be:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4c2:	0005879b          	sext.w	a5,a1
 4c6:	02c5d5bb          	divuw	a1,a1,a2
 4ca:	0685                	addi	a3,a3,1
 4cc:	fec7f0e3          	bgeu	a5,a2,4ac <printint+0x2a>
  if(neg)
 4d0:	00088c63          	beqz	a7,4e8 <printint+0x66>
    buf[i++] = '-';
 4d4:	fd070793          	addi	a5,a4,-48
 4d8:	00878733          	add	a4,a5,s0
 4dc:	02d00793          	li	a5,45
 4e0:	fef70823          	sb	a5,-16(a4)
 4e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4e8:	02e05863          	blez	a4,518 <printint+0x96>
 4ec:	fc040793          	addi	a5,s0,-64
 4f0:	00e78933          	add	s2,a5,a4
 4f4:	fff78993          	addi	s3,a5,-1
 4f8:	99ba                	add	s3,s3,a4
 4fa:	377d                	addiw	a4,a4,-1
 4fc:	1702                	slli	a4,a4,0x20
 4fe:	9301                	srli	a4,a4,0x20
 500:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 504:	fff94583          	lbu	a1,-1(s2)
 508:	8526                	mv	a0,s1
 50a:	00000097          	auipc	ra,0x0
 50e:	f56080e7          	jalr	-170(ra) # 460 <putc>
  while(--i >= 0)
 512:	197d                	addi	s2,s2,-1
 514:	ff3918e3          	bne	s2,s3,504 <printint+0x82>
}
 518:	70e2                	ld	ra,56(sp)
 51a:	7442                	ld	s0,48(sp)
 51c:	74a2                	ld	s1,40(sp)
 51e:	7902                	ld	s2,32(sp)
 520:	69e2                	ld	s3,24(sp)
 522:	6121                	addi	sp,sp,64
 524:	8082                	ret
    x = -xx;
 526:	40b005bb          	negw	a1,a1
    neg = 1;
 52a:	4885                	li	a7,1
    x = -xx;
 52c:	bf85                	j	49c <printint+0x1a>

000000000000052e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 52e:	7119                	addi	sp,sp,-128
 530:	fc86                	sd	ra,120(sp)
 532:	f8a2                	sd	s0,112(sp)
 534:	f4a6                	sd	s1,104(sp)
 536:	f0ca                	sd	s2,96(sp)
 538:	ecce                	sd	s3,88(sp)
 53a:	e8d2                	sd	s4,80(sp)
 53c:	e4d6                	sd	s5,72(sp)
 53e:	e0da                	sd	s6,64(sp)
 540:	fc5e                	sd	s7,56(sp)
 542:	f862                	sd	s8,48(sp)
 544:	f466                	sd	s9,40(sp)
 546:	f06a                	sd	s10,32(sp)
 548:	ec6e                	sd	s11,24(sp)
 54a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 54c:	0005c903          	lbu	s2,0(a1)
 550:	18090f63          	beqz	s2,6ee <vprintf+0x1c0>
 554:	8aaa                	mv	s5,a0
 556:	8b32                	mv	s6,a2
 558:	00158493          	addi	s1,a1,1
  state = 0;
 55c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 55e:	02500a13          	li	s4,37
 562:	4c55                	li	s8,21
 564:	00000c97          	auipc	s9,0x0
 568:	38cc8c93          	addi	s9,s9,908 # 8f0 <malloc+0xfe>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 56c:	02800d93          	li	s11,40
  putc(fd, 'x');
 570:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 572:	00000b97          	auipc	s7,0x0
 576:	3d6b8b93          	addi	s7,s7,982 # 948 <digits>
 57a:	a839                	j	598 <vprintf+0x6a>
        putc(fd, c);
 57c:	85ca                	mv	a1,s2
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	ee0080e7          	jalr	-288(ra) # 460 <putc>
 588:	a019                	j	58e <vprintf+0x60>
    } else if(state == '%'){
 58a:	01498d63          	beq	s3,s4,5a4 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 58e:	0485                	addi	s1,s1,1
 590:	fff4c903          	lbu	s2,-1(s1)
 594:	14090d63          	beqz	s2,6ee <vprintf+0x1c0>
    if(state == 0){
 598:	fe0999e3          	bnez	s3,58a <vprintf+0x5c>
      if(c == '%'){
 59c:	ff4910e3          	bne	s2,s4,57c <vprintf+0x4e>
        state = '%';
 5a0:	89d2                	mv	s3,s4
 5a2:	b7f5                	j	58e <vprintf+0x60>
      if(c == 'd'){
 5a4:	11490c63          	beq	s2,s4,6bc <vprintf+0x18e>
 5a8:	f9d9079b          	addiw	a5,s2,-99
 5ac:	0ff7f793          	zext.b	a5,a5
 5b0:	10fc6e63          	bltu	s8,a5,6cc <vprintf+0x19e>
 5b4:	f9d9079b          	addiw	a5,s2,-99
 5b8:	0ff7f713          	zext.b	a4,a5
 5bc:	10ec6863          	bltu	s8,a4,6cc <vprintf+0x19e>
 5c0:	00271793          	slli	a5,a4,0x2
 5c4:	97e6                	add	a5,a5,s9
 5c6:	439c                	lw	a5,0(a5)
 5c8:	97e6                	add	a5,a5,s9
 5ca:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 5cc:	008b0913          	addi	s2,s6,8
 5d0:	4685                	li	a3,1
 5d2:	4629                	li	a2,10
 5d4:	000b2583          	lw	a1,0(s6)
 5d8:	8556                	mv	a0,s5
 5da:	00000097          	auipc	ra,0x0
 5de:	ea8080e7          	jalr	-344(ra) # 482 <printint>
 5e2:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 5e4:	4981                	li	s3,0
 5e6:	b765                	j	58e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5e8:	008b0913          	addi	s2,s6,8
 5ec:	4681                	li	a3,0
 5ee:	4629                	li	a2,10
 5f0:	000b2583          	lw	a1,0(s6)
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	e8c080e7          	jalr	-372(ra) # 482 <printint>
 5fe:	8b4a                	mv	s6,s2
      state = 0;
 600:	4981                	li	s3,0
 602:	b771                	j	58e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 604:	008b0913          	addi	s2,s6,8
 608:	4681                	li	a3,0
 60a:	866a                	mv	a2,s10
 60c:	000b2583          	lw	a1,0(s6)
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e70080e7          	jalr	-400(ra) # 482 <printint>
 61a:	8b4a                	mv	s6,s2
      state = 0;
 61c:	4981                	li	s3,0
 61e:	bf85                	j	58e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 620:	008b0793          	addi	a5,s6,8
 624:	f8f43423          	sd	a5,-120(s0)
 628:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 62c:	03000593          	li	a1,48
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e2e080e7          	jalr	-466(ra) # 460 <putc>
  putc(fd, 'x');
 63a:	07800593          	li	a1,120
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	e20080e7          	jalr	-480(ra) # 460 <putc>
 648:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 64a:	03c9d793          	srli	a5,s3,0x3c
 64e:	97de                	add	a5,a5,s7
 650:	0007c583          	lbu	a1,0(a5)
 654:	8556                	mv	a0,s5
 656:	00000097          	auipc	ra,0x0
 65a:	e0a080e7          	jalr	-502(ra) # 460 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 65e:	0992                	slli	s3,s3,0x4
 660:	397d                	addiw	s2,s2,-1
 662:	fe0914e3          	bnez	s2,64a <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 666:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 66a:	4981                	li	s3,0
 66c:	b70d                	j	58e <vprintf+0x60>
        s = va_arg(ap, char*);
 66e:	008b0913          	addi	s2,s6,8
 672:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 676:	02098163          	beqz	s3,698 <vprintf+0x16a>
        while(*s != 0){
 67a:	0009c583          	lbu	a1,0(s3)
 67e:	c5ad                	beqz	a1,6e8 <vprintf+0x1ba>
          putc(fd, *s);
 680:	8556                	mv	a0,s5
 682:	00000097          	auipc	ra,0x0
 686:	dde080e7          	jalr	-546(ra) # 460 <putc>
          s++;
 68a:	0985                	addi	s3,s3,1
        while(*s != 0){
 68c:	0009c583          	lbu	a1,0(s3)
 690:	f9e5                	bnez	a1,680 <vprintf+0x152>
        s = va_arg(ap, char*);
 692:	8b4a                	mv	s6,s2
      state = 0;
 694:	4981                	li	s3,0
 696:	bde5                	j	58e <vprintf+0x60>
          s = "(null)";
 698:	00000997          	auipc	s3,0x0
 69c:	25098993          	addi	s3,s3,592 # 8e8 <malloc+0xf6>
        while(*s != 0){
 6a0:	85ee                	mv	a1,s11
 6a2:	bff9                	j	680 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 6a4:	008b0913          	addi	s2,s6,8
 6a8:	000b4583          	lbu	a1,0(s6)
 6ac:	8556                	mv	a0,s5
 6ae:	00000097          	auipc	ra,0x0
 6b2:	db2080e7          	jalr	-590(ra) # 460 <putc>
 6b6:	8b4a                	mv	s6,s2
      state = 0;
 6b8:	4981                	li	s3,0
 6ba:	bdd1                	j	58e <vprintf+0x60>
        putc(fd, c);
 6bc:	85d2                	mv	a1,s4
 6be:	8556                	mv	a0,s5
 6c0:	00000097          	auipc	ra,0x0
 6c4:	da0080e7          	jalr	-608(ra) # 460 <putc>
      state = 0;
 6c8:	4981                	li	s3,0
 6ca:	b5d1                	j	58e <vprintf+0x60>
        putc(fd, '%');
 6cc:	85d2                	mv	a1,s4
 6ce:	8556                	mv	a0,s5
 6d0:	00000097          	auipc	ra,0x0
 6d4:	d90080e7          	jalr	-624(ra) # 460 <putc>
        putc(fd, c);
 6d8:	85ca                	mv	a1,s2
 6da:	8556                	mv	a0,s5
 6dc:	00000097          	auipc	ra,0x0
 6e0:	d84080e7          	jalr	-636(ra) # 460 <putc>
      state = 0;
 6e4:	4981                	li	s3,0
 6e6:	b565                	j	58e <vprintf+0x60>
        s = va_arg(ap, char*);
 6e8:	8b4a                	mv	s6,s2
      state = 0;
 6ea:	4981                	li	s3,0
 6ec:	b54d                	j	58e <vprintf+0x60>
    }
  }
}
 6ee:	70e6                	ld	ra,120(sp)
 6f0:	7446                	ld	s0,112(sp)
 6f2:	74a6                	ld	s1,104(sp)
 6f4:	7906                	ld	s2,96(sp)
 6f6:	69e6                	ld	s3,88(sp)
 6f8:	6a46                	ld	s4,80(sp)
 6fa:	6aa6                	ld	s5,72(sp)
 6fc:	6b06                	ld	s6,64(sp)
 6fe:	7be2                	ld	s7,56(sp)
 700:	7c42                	ld	s8,48(sp)
 702:	7ca2                	ld	s9,40(sp)
 704:	7d02                	ld	s10,32(sp)
 706:	6de2                	ld	s11,24(sp)
 708:	6109                	addi	sp,sp,128
 70a:	8082                	ret

000000000000070c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 70c:	715d                	addi	sp,sp,-80
 70e:	ec06                	sd	ra,24(sp)
 710:	e822                	sd	s0,16(sp)
 712:	1000                	addi	s0,sp,32
 714:	e010                	sd	a2,0(s0)
 716:	e414                	sd	a3,8(s0)
 718:	e818                	sd	a4,16(s0)
 71a:	ec1c                	sd	a5,24(s0)
 71c:	03043023          	sd	a6,32(s0)
 720:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 724:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 728:	8622                	mv	a2,s0
 72a:	00000097          	auipc	ra,0x0
 72e:	e04080e7          	jalr	-508(ra) # 52e <vprintf>
}
 732:	60e2                	ld	ra,24(sp)
 734:	6442                	ld	s0,16(sp)
 736:	6161                	addi	sp,sp,80
 738:	8082                	ret

000000000000073a <printf>:

void
printf(const char *fmt, ...)
{
 73a:	711d                	addi	sp,sp,-96
 73c:	ec06                	sd	ra,24(sp)
 73e:	e822                	sd	s0,16(sp)
 740:	1000                	addi	s0,sp,32
 742:	e40c                	sd	a1,8(s0)
 744:	e810                	sd	a2,16(s0)
 746:	ec14                	sd	a3,24(s0)
 748:	f018                	sd	a4,32(s0)
 74a:	f41c                	sd	a5,40(s0)
 74c:	03043823          	sd	a6,48(s0)
 750:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 754:	00840613          	addi	a2,s0,8
 758:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 75c:	85aa                	mv	a1,a0
 75e:	4505                	li	a0,1
 760:	00000097          	auipc	ra,0x0
 764:	dce080e7          	jalr	-562(ra) # 52e <vprintf>
}
 768:	60e2                	ld	ra,24(sp)
 76a:	6442                	ld	s0,16(sp)
 76c:	6125                	addi	sp,sp,96
 76e:	8082                	ret

0000000000000770 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 770:	1141                	addi	sp,sp,-16
 772:	e422                	sd	s0,8(sp)
 774:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 776:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 77a:	00000797          	auipc	a5,0x0
 77e:	1ee7b783          	ld	a5,494(a5) # 968 <freep>
 782:	a02d                	j	7ac <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 784:	4618                	lw	a4,8(a2)
 786:	9f2d                	addw	a4,a4,a1
 788:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 78c:	6398                	ld	a4,0(a5)
 78e:	6310                	ld	a2,0(a4)
 790:	a83d                	j	7ce <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 792:	ff852703          	lw	a4,-8(a0)
 796:	9f31                	addw	a4,a4,a2
 798:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 79a:	ff053683          	ld	a3,-16(a0)
 79e:	a091                	j	7e2 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7a0:	6398                	ld	a4,0(a5)
 7a2:	00e7e463          	bltu	a5,a4,7aa <free+0x3a>
 7a6:	00e6ea63          	bltu	a3,a4,7ba <free+0x4a>
{
 7aa:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7ac:	fed7fae3          	bgeu	a5,a3,7a0 <free+0x30>
 7b0:	6398                	ld	a4,0(a5)
 7b2:	00e6e463          	bltu	a3,a4,7ba <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7b6:	fee7eae3          	bltu	a5,a4,7aa <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 7ba:	ff852583          	lw	a1,-8(a0)
 7be:	6390                	ld	a2,0(a5)
 7c0:	02059813          	slli	a6,a1,0x20
 7c4:	01c85713          	srli	a4,a6,0x1c
 7c8:	9736                	add	a4,a4,a3
 7ca:	fae60de3          	beq	a2,a4,784 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 7ce:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7d2:	4790                	lw	a2,8(a5)
 7d4:	02061593          	slli	a1,a2,0x20
 7d8:	01c5d713          	srli	a4,a1,0x1c
 7dc:	973e                	add	a4,a4,a5
 7de:	fae68ae3          	beq	a3,a4,792 <free+0x22>
    p->s.ptr = bp->s.ptr;
 7e2:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 7e4:	00000717          	auipc	a4,0x0
 7e8:	18f73223          	sd	a5,388(a4) # 968 <freep>
}
 7ec:	6422                	ld	s0,8(sp)
 7ee:	0141                	addi	sp,sp,16
 7f0:	8082                	ret

00000000000007f2 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7f2:	7139                	addi	sp,sp,-64
 7f4:	fc06                	sd	ra,56(sp)
 7f6:	f822                	sd	s0,48(sp)
 7f8:	f426                	sd	s1,40(sp)
 7fa:	f04a                	sd	s2,32(sp)
 7fc:	ec4e                	sd	s3,24(sp)
 7fe:	e852                	sd	s4,16(sp)
 800:	e456                	sd	s5,8(sp)
 802:	e05a                	sd	s6,0(sp)
 804:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 806:	02051493          	slli	s1,a0,0x20
 80a:	9081                	srli	s1,s1,0x20
 80c:	04bd                	addi	s1,s1,15
 80e:	8091                	srli	s1,s1,0x4
 810:	0014899b          	addiw	s3,s1,1
 814:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 816:	00000517          	auipc	a0,0x0
 81a:	15253503          	ld	a0,338(a0) # 968 <freep>
 81e:	c515                	beqz	a0,84a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 820:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 822:	4798                	lw	a4,8(a5)
 824:	02977f63          	bgeu	a4,s1,862 <malloc+0x70>
 828:	8a4e                	mv	s4,s3
 82a:	0009871b          	sext.w	a4,s3
 82e:	6685                	lui	a3,0x1
 830:	00d77363          	bgeu	a4,a3,836 <malloc+0x44>
 834:	6a05                	lui	s4,0x1
 836:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 83a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 83e:	00000917          	auipc	s2,0x0
 842:	12a90913          	addi	s2,s2,298 # 968 <freep>
  if(p == (char*)-1)
 846:	5afd                	li	s5,-1
 848:	a895                	j	8bc <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 84a:	00000797          	auipc	a5,0x0
 84e:	12678793          	addi	a5,a5,294 # 970 <base>
 852:	00000717          	auipc	a4,0x0
 856:	10f73b23          	sd	a5,278(a4) # 968 <freep>
 85a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 85c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 860:	b7e1                	j	828 <malloc+0x36>
      if(p->s.size == nunits)
 862:	02e48c63          	beq	s1,a4,89a <malloc+0xa8>
        p->s.size -= nunits;
 866:	4137073b          	subw	a4,a4,s3
 86a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 86c:	02071693          	slli	a3,a4,0x20
 870:	01c6d713          	srli	a4,a3,0x1c
 874:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 876:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 87a:	00000717          	auipc	a4,0x0
 87e:	0ea73723          	sd	a0,238(a4) # 968 <freep>
      return (void*)(p + 1);
 882:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 886:	70e2                	ld	ra,56(sp)
 888:	7442                	ld	s0,48(sp)
 88a:	74a2                	ld	s1,40(sp)
 88c:	7902                	ld	s2,32(sp)
 88e:	69e2                	ld	s3,24(sp)
 890:	6a42                	ld	s4,16(sp)
 892:	6aa2                	ld	s5,8(sp)
 894:	6b02                	ld	s6,0(sp)
 896:	6121                	addi	sp,sp,64
 898:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 89a:	6398                	ld	a4,0(a5)
 89c:	e118                	sd	a4,0(a0)
 89e:	bff1                	j	87a <malloc+0x88>
  hp->s.size = nu;
 8a0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8a4:	0541                	addi	a0,a0,16
 8a6:	00000097          	auipc	ra,0x0
 8aa:	eca080e7          	jalr	-310(ra) # 770 <free>
  return freep;
 8ae:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8b2:	d971                	beqz	a0,886 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8b4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8b6:	4798                	lw	a4,8(a5)
 8b8:	fa9775e3          	bgeu	a4,s1,862 <malloc+0x70>
    if(p == freep)
 8bc:	00093703          	ld	a4,0(s2)
 8c0:	853e                	mv	a0,a5
 8c2:	fef719e3          	bne	a4,a5,8b4 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 8c6:	8552                	mv	a0,s4
 8c8:	00000097          	auipc	ra,0x0
 8cc:	b60080e7          	jalr	-1184(ra) # 428 <sbrk>
  if(p == (char*)-1)
 8d0:	fd5518e3          	bne	a0,s5,8a0 <malloc+0xae>
        return 0;
 8d4:	4501                	li	a0,0
 8d6:	bf45                	j	886 <malloc+0x94>
