
user/_prodcons3:     file format elf64-littleriscv


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
   8:	00001717          	auipc	a4,0x1
   c:	9a873703          	ld	a4,-1624(a4) # 9b0 <buffer>
  10:	6789                	lui	a5,0x2
  12:	97ba                	add	a5,a5,a4
  14:	479c                	lw	a5,8(a5)
  16:	7ff00693          	li	a3,2047
  1a:	04f6c763          	blt	a3,a5,68 <producer+0x68>
	    exit(0);
	}
	buffer->num_produced++;
  1e:	6589                	lui	a1,0x2
	buffer->buf[buffer->nextin++] = 1;
  20:	4885                	li	a7,1
	buffer->nextin %= BSIZE;
  22:	00001817          	auipc	a6,0x1
  26:	98e80813          	addi	a6,a6,-1650 # 9b0 <buffer>
        if (buffer->num_produced >= MAX) {
  2a:	7ff00513          	li	a0,2047
	buffer->num_produced++;
  2e:	00b706b3          	add	a3,a4,a1
  32:	2785                	addiw	a5,a5,1 # 2001 <__global_pointer$+0xe58>
  34:	c69c                	sw	a5,8(a3)
	buffer->buf[buffer->nextin++] = 1;
  36:	429c                	lw	a5,0(a3)
  38:	0017861b          	addiw	a2,a5,1
  3c:	c290                	sw	a2,0(a3)
  3e:	078a                	slli	a5,a5,0x2
  40:	973e                	add	a4,a4,a5
  42:	01172023          	sw	a7,0(a4)
	buffer->nextin %= BSIZE;
  46:	00083703          	ld	a4,0(a6)
  4a:	00b70633          	add	a2,a4,a1
  4e:	421c                	lw	a5,0(a2)
  50:	41f7d69b          	sraiw	a3,a5,0x1f
  54:	0156d69b          	srliw	a3,a3,0x15
  58:	9fb5                	addw	a5,a5,a3
  5a:	7ff7f793          	andi	a5,a5,2047
  5e:	9f95                	subw	a5,a5,a3
  60:	c21c                	sw	a5,0(a2)
        if (buffer->num_produced >= MAX) {
  62:	461c                	lw	a5,8(a2)
  64:	fcf555e3          	bge	a0,a5,2e <producer+0x2e>
	    exit(0);
  68:	4501                	li	a0,0
  6a:	00000097          	auipc	ra,0x0
  6e:	380080e7          	jalr	896(ra) # 3ea <exit>

0000000000000072 <consumer>:
    }
}

void *consumer()
{
  72:	1141                	addi	sp,sp,-16
  74:	e406                	sd	ra,8(sp)
  76:	e022                	sd	s0,0(sp)
  78:	0800                	addi	s0,sp,16
    while(1) {
        if (buffer->num_consumed >= MAX) {
  7a:	00001597          	auipc	a1,0x1
  7e:	9365b583          	ld	a1,-1738(a1) # 9b0 <buffer>
  82:	6789                	lui	a5,0x2
  84:	97ae                	add	a5,a5,a1
  86:	47d4                	lw	a3,12(a5)
  88:	7ff00793          	li	a5,2047
  8c:	04d7c363          	blt	a5,a3,d2 <consumer+0x60>
  90:	6709                	lui	a4,0x2
  92:	972e                	add	a4,a4,a1
  94:	435c                	lw	a5,4(a4)
  96:	4b10                	lw	a2,16(a4)
  98:	2685                	addiw	a3,a3,1
  9a:	6505                	lui	a0,0x1
  9c:	80150513          	addi	a0,a0,-2047 # 801 <free+0x47>
	    exit(0);
	}
	buffer->total += buffer->buf[buffer->nextout++];
  a0:	00279713          	slli	a4,a5,0x2
  a4:	972e                	add	a4,a4,a1
  a6:	4318                	lw	a4,0(a4)
  a8:	9e39                	addw	a2,a2,a4
  aa:	2785                	addiw	a5,a5,1 # 2001 <__global_pointer$+0xe58>
	buffer->nextout %= BSIZE;
  ac:	41f7d71b          	sraiw	a4,a5,0x1f
  b0:	0157571b          	srliw	a4,a4,0x15
  b4:	9fb9                	addw	a5,a5,a4
  b6:	7ff7f793          	andi	a5,a5,2047
  ba:	9f99                	subw	a5,a5,a4
        if (buffer->num_consumed >= MAX) {
  bc:	2685                	addiw	a3,a3,1
  be:	fea691e3          	bne	a3,a0,a0 <consumer+0x2e>
  c2:	6709                	lui	a4,0x2
  c4:	95ba                	add	a1,a1,a4
  c6:	c990                	sw	a2,16(a1)
  c8:	c1dc                	sw	a5,4(a1)
  ca:	6785                	lui	a5,0x1
  cc:	80078793          	addi	a5,a5,-2048 # 800 <free+0x46>
  d0:	c5dc                	sw	a5,12(a1)
	    exit(0);
  d2:	4501                	li	a0,0
  d4:	00000097          	auipc	ra,0x0
  d8:	316080e7          	jalr	790(ra) # 3ea <exit>

00000000000000dc <main>:
	buffer->num_consumed++;
    }
}

int main(int argc, char *argv[])
{
  dc:	1101                	addi	sp,sp,-32
  de:	ec06                	sd	ra,24(sp)
  e0:	e822                	sd	s0,16(sp)
  e2:	e426                	sd	s1,8(sp)
  e4:	1000                	addi	s0,sp,32
    buffer = (buffer_t *) mmap(NULL, sizeof(buffer_t),
  e6:	4781                	li	a5,0
  e8:	577d                	li	a4,-1
  ea:	02100693          	li	a3,33
  ee:	4619                	li	a2,6
  f0:	6489                	lui	s1,0x2
  f2:	01448593          	addi	a1,s1,20 # 2014 <__global_pointer$+0xe6b>
  f6:	4501                	li	a0,0
  f8:	00000097          	auipc	ra,0x0
  fc:	3a2080e7          	jalr	930(ra) # 49a <mmap>
 100:	00001797          	auipc	a5,0x1
 104:	8aa7b823          	sd	a0,-1872(a5) # 9b0 <buffer>
		               PROT_READ | PROT_WRITE,
			       MAP_ANONYMOUS | MAP_SHARED, -1, 0);
    buffer->nextin = 0;
 108:	9526                	add	a0,a0,s1
 10a:	00052023          	sw	zero,0(a0)
    buffer->nextout = 0;
 10e:	00052223          	sw	zero,4(a0)
    buffer->num_produced = 0;
 112:	00052423          	sw	zero,8(a0)
    buffer->num_consumed = 0;
 116:	00052623          	sw	zero,12(a0)
    buffer->total = 0;
 11a:	00052823          	sw	zero,16(a0)
    if (!fork())
 11e:	00000097          	auipc	ra,0x0
 122:	2c4080e7          	jalr	708(ra) # 3e2 <fork>
 126:	e509                	bnez	a0,130 <main+0x54>
        producer();
 128:	00000097          	auipc	ra,0x0
 12c:	ed8080e7          	jalr	-296(ra) # 0 <producer>
    else
	wait(0);
 130:	4501                	li	a0,0
 132:	00000097          	auipc	ra,0x0
 136:	2c0080e7          	jalr	704(ra) # 3f2 <wait>
    if (!fork())
 13a:	00000097          	auipc	ra,0x0
 13e:	2a8080e7          	jalr	680(ra) # 3e2 <fork>
 142:	e509                	bnez	a0,14c <main+0x70>
        consumer();
 144:	00000097          	auipc	ra,0x0
 148:	f2e080e7          	jalr	-210(ra) # 72 <consumer>
    else
	wait(0);
 14c:	4501                	li	a0,0
 14e:	00000097          	auipc	ra,0x0
 152:	2a4080e7          	jalr	676(ra) # 3f2 <wait>
    printf("total = %d\n", buffer->total);
 156:	00001797          	auipc	a5,0x1
 15a:	85a7b783          	ld	a5,-1958(a5) # 9b0 <buffer>
 15e:	6709                	lui	a4,0x2
 160:	97ba                	add	a5,a5,a4
 162:	4b8c                	lw	a1,16(a5)
 164:	00000517          	auipc	a0,0x0
 168:	7c450513          	addi	a0,a0,1988 # 928 <malloc+0xec>
 16c:	00000097          	auipc	ra,0x0
 170:	618080e7          	jalr	1560(ra) # 784 <printf>
    exit(0);
 174:	4501                	li	a0,0
 176:	00000097          	auipc	ra,0x0
 17a:	274080e7          	jalr	628(ra) # 3ea <exit>

000000000000017e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 17e:	1141                	addi	sp,sp,-16
 180:	e422                	sd	s0,8(sp)
 182:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 184:	87aa                	mv	a5,a0
 186:	0585                	addi	a1,a1,1
 188:	0785                	addi	a5,a5,1
 18a:	fff5c703          	lbu	a4,-1(a1)
 18e:	fee78fa3          	sb	a4,-1(a5)
 192:	fb75                	bnez	a4,186 <strcpy+0x8>
    ;
  return os;
}
 194:	6422                	ld	s0,8(sp)
 196:	0141                	addi	sp,sp,16
 198:	8082                	ret

000000000000019a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 19a:	1141                	addi	sp,sp,-16
 19c:	e422                	sd	s0,8(sp)
 19e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1a0:	00054783          	lbu	a5,0(a0)
 1a4:	cb91                	beqz	a5,1b8 <strcmp+0x1e>
 1a6:	0005c703          	lbu	a4,0(a1)
 1aa:	00f71763          	bne	a4,a5,1b8 <strcmp+0x1e>
    p++, q++;
 1ae:	0505                	addi	a0,a0,1
 1b0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1b2:	00054783          	lbu	a5,0(a0)
 1b6:	fbe5                	bnez	a5,1a6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1b8:	0005c503          	lbu	a0,0(a1)
}
 1bc:	40a7853b          	subw	a0,a5,a0
 1c0:	6422                	ld	s0,8(sp)
 1c2:	0141                	addi	sp,sp,16
 1c4:	8082                	ret

00000000000001c6 <strlen>:

uint
strlen(const char *s)
{
 1c6:	1141                	addi	sp,sp,-16
 1c8:	e422                	sd	s0,8(sp)
 1ca:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1cc:	00054783          	lbu	a5,0(a0)
 1d0:	cf91                	beqz	a5,1ec <strlen+0x26>
 1d2:	0505                	addi	a0,a0,1
 1d4:	87aa                	mv	a5,a0
 1d6:	4685                	li	a3,1
 1d8:	9e89                	subw	a3,a3,a0
 1da:	00f6853b          	addw	a0,a3,a5
 1de:	0785                	addi	a5,a5,1
 1e0:	fff7c703          	lbu	a4,-1(a5)
 1e4:	fb7d                	bnez	a4,1da <strlen+0x14>
    ;
  return n;
}
 1e6:	6422                	ld	s0,8(sp)
 1e8:	0141                	addi	sp,sp,16
 1ea:	8082                	ret
  for(n = 0; s[n]; n++)
 1ec:	4501                	li	a0,0
 1ee:	bfe5                	j	1e6 <strlen+0x20>

00000000000001f0 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1f0:	1141                	addi	sp,sp,-16
 1f2:	e422                	sd	s0,8(sp)
 1f4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1f6:	ca19                	beqz	a2,20c <memset+0x1c>
 1f8:	87aa                	mv	a5,a0
 1fa:	1602                	slli	a2,a2,0x20
 1fc:	9201                	srli	a2,a2,0x20
 1fe:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 202:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 206:	0785                	addi	a5,a5,1
 208:	fee79de3          	bne	a5,a4,202 <memset+0x12>
  }
  return dst;
}
 20c:	6422                	ld	s0,8(sp)
 20e:	0141                	addi	sp,sp,16
 210:	8082                	ret

0000000000000212 <strchr>:

char*
strchr(const char *s, char c)
{
 212:	1141                	addi	sp,sp,-16
 214:	e422                	sd	s0,8(sp)
 216:	0800                	addi	s0,sp,16
  for(; *s; s++)
 218:	00054783          	lbu	a5,0(a0)
 21c:	cb99                	beqz	a5,232 <strchr+0x20>
    if(*s == c)
 21e:	00f58763          	beq	a1,a5,22c <strchr+0x1a>
  for(; *s; s++)
 222:	0505                	addi	a0,a0,1
 224:	00054783          	lbu	a5,0(a0)
 228:	fbfd                	bnez	a5,21e <strchr+0xc>
      return (char*)s;
  return 0;
 22a:	4501                	li	a0,0
}
 22c:	6422                	ld	s0,8(sp)
 22e:	0141                	addi	sp,sp,16
 230:	8082                	ret
  return 0;
 232:	4501                	li	a0,0
 234:	bfe5                	j	22c <strchr+0x1a>

0000000000000236 <gets>:

char*
gets(char *buf, int max)
{
 236:	711d                	addi	sp,sp,-96
 238:	ec86                	sd	ra,88(sp)
 23a:	e8a2                	sd	s0,80(sp)
 23c:	e4a6                	sd	s1,72(sp)
 23e:	e0ca                	sd	s2,64(sp)
 240:	fc4e                	sd	s3,56(sp)
 242:	f852                	sd	s4,48(sp)
 244:	f456                	sd	s5,40(sp)
 246:	f05a                	sd	s6,32(sp)
 248:	ec5e                	sd	s7,24(sp)
 24a:	1080                	addi	s0,sp,96
 24c:	8baa                	mv	s7,a0
 24e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 250:	892a                	mv	s2,a0
 252:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 254:	4aa9                	li	s5,10
 256:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 258:	89a6                	mv	s3,s1
 25a:	2485                	addiw	s1,s1,1
 25c:	0344d863          	bge	s1,s4,28c <gets+0x56>
    cc = read(0, &c, 1);
 260:	4605                	li	a2,1
 262:	faf40593          	addi	a1,s0,-81
 266:	4501                	li	a0,0
 268:	00000097          	auipc	ra,0x0
 26c:	19a080e7          	jalr	410(ra) # 402 <read>
    if(cc < 1)
 270:	00a05e63          	blez	a0,28c <gets+0x56>
    buf[i++] = c;
 274:	faf44783          	lbu	a5,-81(s0)
 278:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 27c:	01578763          	beq	a5,s5,28a <gets+0x54>
 280:	0905                	addi	s2,s2,1
 282:	fd679be3          	bne	a5,s6,258 <gets+0x22>
  for(i=0; i+1 < max; ){
 286:	89a6                	mv	s3,s1
 288:	a011                	j	28c <gets+0x56>
 28a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 28c:	99de                	add	s3,s3,s7
 28e:	00098023          	sb	zero,0(s3)
  return buf;
}
 292:	855e                	mv	a0,s7
 294:	60e6                	ld	ra,88(sp)
 296:	6446                	ld	s0,80(sp)
 298:	64a6                	ld	s1,72(sp)
 29a:	6906                	ld	s2,64(sp)
 29c:	79e2                	ld	s3,56(sp)
 29e:	7a42                	ld	s4,48(sp)
 2a0:	7aa2                	ld	s5,40(sp)
 2a2:	7b02                	ld	s6,32(sp)
 2a4:	6be2                	ld	s7,24(sp)
 2a6:	6125                	addi	sp,sp,96
 2a8:	8082                	ret

00000000000002aa <stat>:

int
stat(const char *n, struct stat *st)
{
 2aa:	1101                	addi	sp,sp,-32
 2ac:	ec06                	sd	ra,24(sp)
 2ae:	e822                	sd	s0,16(sp)
 2b0:	e426                	sd	s1,8(sp)
 2b2:	e04a                	sd	s2,0(sp)
 2b4:	1000                	addi	s0,sp,32
 2b6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2b8:	4581                	li	a1,0
 2ba:	00000097          	auipc	ra,0x0
 2be:	170080e7          	jalr	368(ra) # 42a <open>
  if(fd < 0)
 2c2:	02054563          	bltz	a0,2ec <stat+0x42>
 2c6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2c8:	85ca                	mv	a1,s2
 2ca:	00000097          	auipc	ra,0x0
 2ce:	178080e7          	jalr	376(ra) # 442 <fstat>
 2d2:	892a                	mv	s2,a0
  close(fd);
 2d4:	8526                	mv	a0,s1
 2d6:	00000097          	auipc	ra,0x0
 2da:	13c080e7          	jalr	316(ra) # 412 <close>
  return r;
}
 2de:	854a                	mv	a0,s2
 2e0:	60e2                	ld	ra,24(sp)
 2e2:	6442                	ld	s0,16(sp)
 2e4:	64a2                	ld	s1,8(sp)
 2e6:	6902                	ld	s2,0(sp)
 2e8:	6105                	addi	sp,sp,32
 2ea:	8082                	ret
    return -1;
 2ec:	597d                	li	s2,-1
 2ee:	bfc5                	j	2de <stat+0x34>

00000000000002f0 <atoi>:

int
atoi(const char *s)
{
 2f0:	1141                	addi	sp,sp,-16
 2f2:	e422                	sd	s0,8(sp)
 2f4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2f6:	00054683          	lbu	a3,0(a0)
 2fa:	fd06879b          	addiw	a5,a3,-48
 2fe:	0ff7f793          	zext.b	a5,a5
 302:	4625                	li	a2,9
 304:	02f66863          	bltu	a2,a5,334 <atoi+0x44>
 308:	872a                	mv	a4,a0
  n = 0;
 30a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 30c:	0705                	addi	a4,a4,1 # 2001 <__global_pointer$+0xe58>
 30e:	0025179b          	slliw	a5,a0,0x2
 312:	9fa9                	addw	a5,a5,a0
 314:	0017979b          	slliw	a5,a5,0x1
 318:	9fb5                	addw	a5,a5,a3
 31a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 31e:	00074683          	lbu	a3,0(a4)
 322:	fd06879b          	addiw	a5,a3,-48
 326:	0ff7f793          	zext.b	a5,a5
 32a:	fef671e3          	bgeu	a2,a5,30c <atoi+0x1c>
  return n;
}
 32e:	6422                	ld	s0,8(sp)
 330:	0141                	addi	sp,sp,16
 332:	8082                	ret
  n = 0;
 334:	4501                	li	a0,0
 336:	bfe5                	j	32e <atoi+0x3e>

0000000000000338 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 338:	1141                	addi	sp,sp,-16
 33a:	e422                	sd	s0,8(sp)
 33c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 33e:	02b57463          	bgeu	a0,a1,366 <memmove+0x2e>
    while(n-- > 0)
 342:	00c05f63          	blez	a2,360 <memmove+0x28>
 346:	1602                	slli	a2,a2,0x20
 348:	9201                	srli	a2,a2,0x20
 34a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 34e:	872a                	mv	a4,a0
      *dst++ = *src++;
 350:	0585                	addi	a1,a1,1
 352:	0705                	addi	a4,a4,1
 354:	fff5c683          	lbu	a3,-1(a1)
 358:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 35c:	fee79ae3          	bne	a5,a4,350 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 360:	6422                	ld	s0,8(sp)
 362:	0141                	addi	sp,sp,16
 364:	8082                	ret
    dst += n;
 366:	00c50733          	add	a4,a0,a2
    src += n;
 36a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 36c:	fec05ae3          	blez	a2,360 <memmove+0x28>
 370:	fff6079b          	addiw	a5,a2,-1
 374:	1782                	slli	a5,a5,0x20
 376:	9381                	srli	a5,a5,0x20
 378:	fff7c793          	not	a5,a5
 37c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 37e:	15fd                	addi	a1,a1,-1
 380:	177d                	addi	a4,a4,-1
 382:	0005c683          	lbu	a3,0(a1)
 386:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 38a:	fee79ae3          	bne	a5,a4,37e <memmove+0x46>
 38e:	bfc9                	j	360 <memmove+0x28>

0000000000000390 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 390:	1141                	addi	sp,sp,-16
 392:	e422                	sd	s0,8(sp)
 394:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 396:	ca05                	beqz	a2,3c6 <memcmp+0x36>
 398:	fff6069b          	addiw	a3,a2,-1
 39c:	1682                	slli	a3,a3,0x20
 39e:	9281                	srli	a3,a3,0x20
 3a0:	0685                	addi	a3,a3,1
 3a2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3a4:	00054783          	lbu	a5,0(a0)
 3a8:	0005c703          	lbu	a4,0(a1)
 3ac:	00e79863          	bne	a5,a4,3bc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3b0:	0505                	addi	a0,a0,1
    p2++;
 3b2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3b4:	fed518e3          	bne	a0,a3,3a4 <memcmp+0x14>
  }
  return 0;
 3b8:	4501                	li	a0,0
 3ba:	a019                	j	3c0 <memcmp+0x30>
      return *p1 - *p2;
 3bc:	40e7853b          	subw	a0,a5,a4
}
 3c0:	6422                	ld	s0,8(sp)
 3c2:	0141                	addi	sp,sp,16
 3c4:	8082                	ret
  return 0;
 3c6:	4501                	li	a0,0
 3c8:	bfe5                	j	3c0 <memcmp+0x30>

00000000000003ca <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3ca:	1141                	addi	sp,sp,-16
 3cc:	e406                	sd	ra,8(sp)
 3ce:	e022                	sd	s0,0(sp)
 3d0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3d2:	00000097          	auipc	ra,0x0
 3d6:	f66080e7          	jalr	-154(ra) # 338 <memmove>
}
 3da:	60a2                	ld	ra,8(sp)
 3dc:	6402                	ld	s0,0(sp)
 3de:	0141                	addi	sp,sp,16
 3e0:	8082                	ret

00000000000003e2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3e2:	4885                	li	a7,1
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <exit>:
.global exit
exit:
 li a7, SYS_exit
 3ea:	4889                	li	a7,2
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3f2:	488d                	li	a7,3
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3fa:	4891                	li	a7,4
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <read>:
.global read
read:
 li a7, SYS_read
 402:	4895                	li	a7,5
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <write>:
.global write
write:
 li a7, SYS_write
 40a:	48c1                	li	a7,16
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <close>:
.global close
close:
 li a7, SYS_close
 412:	48d5                	li	a7,21
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <kill>:
.global kill
kill:
 li a7, SYS_kill
 41a:	4899                	li	a7,6
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <exec>:
.global exec
exec:
 li a7, SYS_exec
 422:	489d                	li	a7,7
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <open>:
.global open
open:
 li a7, SYS_open
 42a:	48bd                	li	a7,15
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 432:	48c5                	li	a7,17
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 43a:	48c9                	li	a7,18
 ecall
 43c:	00000073          	ecall
 ret
 440:	8082                	ret

0000000000000442 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 442:	48a1                	li	a7,8
 ecall
 444:	00000073          	ecall
 ret
 448:	8082                	ret

000000000000044a <link>:
.global link
link:
 li a7, SYS_link
 44a:	48cd                	li	a7,19
 ecall
 44c:	00000073          	ecall
 ret
 450:	8082                	ret

0000000000000452 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 452:	48d1                	li	a7,20
 ecall
 454:	00000073          	ecall
 ret
 458:	8082                	ret

000000000000045a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 45a:	48a5                	li	a7,9
 ecall
 45c:	00000073          	ecall
 ret
 460:	8082                	ret

0000000000000462 <dup>:
.global dup
dup:
 li a7, SYS_dup
 462:	48a9                	li	a7,10
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 46a:	48ad                	li	a7,11
 ecall
 46c:	00000073          	ecall
 ret
 470:	8082                	ret

0000000000000472 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 472:	48b1                	li	a7,12
 ecall
 474:	00000073          	ecall
 ret
 478:	8082                	ret

000000000000047a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 47a:	48b5                	li	a7,13
 ecall
 47c:	00000073          	ecall
 ret
 480:	8082                	ret

0000000000000482 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 482:	48b9                	li	a7,14
 ecall
 484:	00000073          	ecall
 ret
 488:	8082                	ret

000000000000048a <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 48a:	48d9                	li	a7,22
 ecall
 48c:	00000073          	ecall
 ret
 490:	8082                	ret

0000000000000492 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 492:	48dd                	li	a7,23
 ecall
 494:	00000073          	ecall
 ret
 498:	8082                	ret

000000000000049a <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 49a:	48e1                	li	a7,24
 ecall
 49c:	00000073          	ecall
 ret
 4a0:	8082                	ret

00000000000004a2 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 4a2:	48e5                	li	a7,25
 ecall
 4a4:	00000073          	ecall
 ret
 4a8:	8082                	ret

00000000000004aa <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4aa:	1101                	addi	sp,sp,-32
 4ac:	ec06                	sd	ra,24(sp)
 4ae:	e822                	sd	s0,16(sp)
 4b0:	1000                	addi	s0,sp,32
 4b2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4b6:	4605                	li	a2,1
 4b8:	fef40593          	addi	a1,s0,-17
 4bc:	00000097          	auipc	ra,0x0
 4c0:	f4e080e7          	jalr	-178(ra) # 40a <write>
}
 4c4:	60e2                	ld	ra,24(sp)
 4c6:	6442                	ld	s0,16(sp)
 4c8:	6105                	addi	sp,sp,32
 4ca:	8082                	ret

00000000000004cc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4cc:	7139                	addi	sp,sp,-64
 4ce:	fc06                	sd	ra,56(sp)
 4d0:	f822                	sd	s0,48(sp)
 4d2:	f426                	sd	s1,40(sp)
 4d4:	f04a                	sd	s2,32(sp)
 4d6:	ec4e                	sd	s3,24(sp)
 4d8:	0080                	addi	s0,sp,64
 4da:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4dc:	c299                	beqz	a3,4e2 <printint+0x16>
 4de:	0805c963          	bltz	a1,570 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4e2:	2581                	sext.w	a1,a1
  neg = 0;
 4e4:	4881                	li	a7,0
 4e6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4ea:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4ec:	2601                	sext.w	a2,a2
 4ee:	00000517          	auipc	a0,0x0
 4f2:	4aa50513          	addi	a0,a0,1194 # 998 <digits>
 4f6:	883a                	mv	a6,a4
 4f8:	2705                	addiw	a4,a4,1
 4fa:	02c5f7bb          	remuw	a5,a1,a2
 4fe:	1782                	slli	a5,a5,0x20
 500:	9381                	srli	a5,a5,0x20
 502:	97aa                	add	a5,a5,a0
 504:	0007c783          	lbu	a5,0(a5)
 508:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 50c:	0005879b          	sext.w	a5,a1
 510:	02c5d5bb          	divuw	a1,a1,a2
 514:	0685                	addi	a3,a3,1
 516:	fec7f0e3          	bgeu	a5,a2,4f6 <printint+0x2a>
  if(neg)
 51a:	00088c63          	beqz	a7,532 <printint+0x66>
    buf[i++] = '-';
 51e:	fd070793          	addi	a5,a4,-48
 522:	00878733          	add	a4,a5,s0
 526:	02d00793          	li	a5,45
 52a:	fef70823          	sb	a5,-16(a4)
 52e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 532:	02e05863          	blez	a4,562 <printint+0x96>
 536:	fc040793          	addi	a5,s0,-64
 53a:	00e78933          	add	s2,a5,a4
 53e:	fff78993          	addi	s3,a5,-1
 542:	99ba                	add	s3,s3,a4
 544:	377d                	addiw	a4,a4,-1
 546:	1702                	slli	a4,a4,0x20
 548:	9301                	srli	a4,a4,0x20
 54a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 54e:	fff94583          	lbu	a1,-1(s2)
 552:	8526                	mv	a0,s1
 554:	00000097          	auipc	ra,0x0
 558:	f56080e7          	jalr	-170(ra) # 4aa <putc>
  while(--i >= 0)
 55c:	197d                	addi	s2,s2,-1
 55e:	ff3918e3          	bne	s2,s3,54e <printint+0x82>
}
 562:	70e2                	ld	ra,56(sp)
 564:	7442                	ld	s0,48(sp)
 566:	74a2                	ld	s1,40(sp)
 568:	7902                	ld	s2,32(sp)
 56a:	69e2                	ld	s3,24(sp)
 56c:	6121                	addi	sp,sp,64
 56e:	8082                	ret
    x = -xx;
 570:	40b005bb          	negw	a1,a1
    neg = 1;
 574:	4885                	li	a7,1
    x = -xx;
 576:	bf85                	j	4e6 <printint+0x1a>

0000000000000578 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 578:	7119                	addi	sp,sp,-128
 57a:	fc86                	sd	ra,120(sp)
 57c:	f8a2                	sd	s0,112(sp)
 57e:	f4a6                	sd	s1,104(sp)
 580:	f0ca                	sd	s2,96(sp)
 582:	ecce                	sd	s3,88(sp)
 584:	e8d2                	sd	s4,80(sp)
 586:	e4d6                	sd	s5,72(sp)
 588:	e0da                	sd	s6,64(sp)
 58a:	fc5e                	sd	s7,56(sp)
 58c:	f862                	sd	s8,48(sp)
 58e:	f466                	sd	s9,40(sp)
 590:	f06a                	sd	s10,32(sp)
 592:	ec6e                	sd	s11,24(sp)
 594:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 596:	0005c903          	lbu	s2,0(a1)
 59a:	18090f63          	beqz	s2,738 <vprintf+0x1c0>
 59e:	8aaa                	mv	s5,a0
 5a0:	8b32                	mv	s6,a2
 5a2:	00158493          	addi	s1,a1,1
  state = 0;
 5a6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5a8:	02500a13          	li	s4,37
 5ac:	4c55                	li	s8,21
 5ae:	00000c97          	auipc	s9,0x0
 5b2:	392c8c93          	addi	s9,s9,914 # 940 <malloc+0x104>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 5b6:	02800d93          	li	s11,40
  putc(fd, 'x');
 5ba:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5bc:	00000b97          	auipc	s7,0x0
 5c0:	3dcb8b93          	addi	s7,s7,988 # 998 <digits>
 5c4:	a839                	j	5e2 <vprintf+0x6a>
        putc(fd, c);
 5c6:	85ca                	mv	a1,s2
 5c8:	8556                	mv	a0,s5
 5ca:	00000097          	auipc	ra,0x0
 5ce:	ee0080e7          	jalr	-288(ra) # 4aa <putc>
 5d2:	a019                	j	5d8 <vprintf+0x60>
    } else if(state == '%'){
 5d4:	01498d63          	beq	s3,s4,5ee <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 5d8:	0485                	addi	s1,s1,1
 5da:	fff4c903          	lbu	s2,-1(s1)
 5de:	14090d63          	beqz	s2,738 <vprintf+0x1c0>
    if(state == 0){
 5e2:	fe0999e3          	bnez	s3,5d4 <vprintf+0x5c>
      if(c == '%'){
 5e6:	ff4910e3          	bne	s2,s4,5c6 <vprintf+0x4e>
        state = '%';
 5ea:	89d2                	mv	s3,s4
 5ec:	b7f5                	j	5d8 <vprintf+0x60>
      if(c == 'd'){
 5ee:	11490c63          	beq	s2,s4,706 <vprintf+0x18e>
 5f2:	f9d9079b          	addiw	a5,s2,-99
 5f6:	0ff7f793          	zext.b	a5,a5
 5fa:	10fc6e63          	bltu	s8,a5,716 <vprintf+0x19e>
 5fe:	f9d9079b          	addiw	a5,s2,-99
 602:	0ff7f713          	zext.b	a4,a5
 606:	10ec6863          	bltu	s8,a4,716 <vprintf+0x19e>
 60a:	00271793          	slli	a5,a4,0x2
 60e:	97e6                	add	a5,a5,s9
 610:	439c                	lw	a5,0(a5)
 612:	97e6                	add	a5,a5,s9
 614:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 616:	008b0913          	addi	s2,s6,8
 61a:	4685                	li	a3,1
 61c:	4629                	li	a2,10
 61e:	000b2583          	lw	a1,0(s6)
 622:	8556                	mv	a0,s5
 624:	00000097          	auipc	ra,0x0
 628:	ea8080e7          	jalr	-344(ra) # 4cc <printint>
 62c:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 62e:	4981                	li	s3,0
 630:	b765                	j	5d8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 632:	008b0913          	addi	s2,s6,8
 636:	4681                	li	a3,0
 638:	4629                	li	a2,10
 63a:	000b2583          	lw	a1,0(s6)
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	e8c080e7          	jalr	-372(ra) # 4cc <printint>
 648:	8b4a                	mv	s6,s2
      state = 0;
 64a:	4981                	li	s3,0
 64c:	b771                	j	5d8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 64e:	008b0913          	addi	s2,s6,8
 652:	4681                	li	a3,0
 654:	866a                	mv	a2,s10
 656:	000b2583          	lw	a1,0(s6)
 65a:	8556                	mv	a0,s5
 65c:	00000097          	auipc	ra,0x0
 660:	e70080e7          	jalr	-400(ra) # 4cc <printint>
 664:	8b4a                	mv	s6,s2
      state = 0;
 666:	4981                	li	s3,0
 668:	bf85                	j	5d8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 66a:	008b0793          	addi	a5,s6,8
 66e:	f8f43423          	sd	a5,-120(s0)
 672:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 676:	03000593          	li	a1,48
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	e2e080e7          	jalr	-466(ra) # 4aa <putc>
  putc(fd, 'x');
 684:	07800593          	li	a1,120
 688:	8556                	mv	a0,s5
 68a:	00000097          	auipc	ra,0x0
 68e:	e20080e7          	jalr	-480(ra) # 4aa <putc>
 692:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 694:	03c9d793          	srli	a5,s3,0x3c
 698:	97de                	add	a5,a5,s7
 69a:	0007c583          	lbu	a1,0(a5)
 69e:	8556                	mv	a0,s5
 6a0:	00000097          	auipc	ra,0x0
 6a4:	e0a080e7          	jalr	-502(ra) # 4aa <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6a8:	0992                	slli	s3,s3,0x4
 6aa:	397d                	addiw	s2,s2,-1
 6ac:	fe0914e3          	bnez	s2,694 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 6b0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6b4:	4981                	li	s3,0
 6b6:	b70d                	j	5d8 <vprintf+0x60>
        s = va_arg(ap, char*);
 6b8:	008b0913          	addi	s2,s6,8
 6bc:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 6c0:	02098163          	beqz	s3,6e2 <vprintf+0x16a>
        while(*s != 0){
 6c4:	0009c583          	lbu	a1,0(s3)
 6c8:	c5ad                	beqz	a1,732 <vprintf+0x1ba>
          putc(fd, *s);
 6ca:	8556                	mv	a0,s5
 6cc:	00000097          	auipc	ra,0x0
 6d0:	dde080e7          	jalr	-546(ra) # 4aa <putc>
          s++;
 6d4:	0985                	addi	s3,s3,1
        while(*s != 0){
 6d6:	0009c583          	lbu	a1,0(s3)
 6da:	f9e5                	bnez	a1,6ca <vprintf+0x152>
        s = va_arg(ap, char*);
 6dc:	8b4a                	mv	s6,s2
      state = 0;
 6de:	4981                	li	s3,0
 6e0:	bde5                	j	5d8 <vprintf+0x60>
          s = "(null)";
 6e2:	00000997          	auipc	s3,0x0
 6e6:	25698993          	addi	s3,s3,598 # 938 <malloc+0xfc>
        while(*s != 0){
 6ea:	85ee                	mv	a1,s11
 6ec:	bff9                	j	6ca <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 6ee:	008b0913          	addi	s2,s6,8
 6f2:	000b4583          	lbu	a1,0(s6)
 6f6:	8556                	mv	a0,s5
 6f8:	00000097          	auipc	ra,0x0
 6fc:	db2080e7          	jalr	-590(ra) # 4aa <putc>
 700:	8b4a                	mv	s6,s2
      state = 0;
 702:	4981                	li	s3,0
 704:	bdd1                	j	5d8 <vprintf+0x60>
        putc(fd, c);
 706:	85d2                	mv	a1,s4
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	da0080e7          	jalr	-608(ra) # 4aa <putc>
      state = 0;
 712:	4981                	li	s3,0
 714:	b5d1                	j	5d8 <vprintf+0x60>
        putc(fd, '%');
 716:	85d2                	mv	a1,s4
 718:	8556                	mv	a0,s5
 71a:	00000097          	auipc	ra,0x0
 71e:	d90080e7          	jalr	-624(ra) # 4aa <putc>
        putc(fd, c);
 722:	85ca                	mv	a1,s2
 724:	8556                	mv	a0,s5
 726:	00000097          	auipc	ra,0x0
 72a:	d84080e7          	jalr	-636(ra) # 4aa <putc>
      state = 0;
 72e:	4981                	li	s3,0
 730:	b565                	j	5d8 <vprintf+0x60>
        s = va_arg(ap, char*);
 732:	8b4a                	mv	s6,s2
      state = 0;
 734:	4981                	li	s3,0
 736:	b54d                	j	5d8 <vprintf+0x60>
    }
  }
}
 738:	70e6                	ld	ra,120(sp)
 73a:	7446                	ld	s0,112(sp)
 73c:	74a6                	ld	s1,104(sp)
 73e:	7906                	ld	s2,96(sp)
 740:	69e6                	ld	s3,88(sp)
 742:	6a46                	ld	s4,80(sp)
 744:	6aa6                	ld	s5,72(sp)
 746:	6b06                	ld	s6,64(sp)
 748:	7be2                	ld	s7,56(sp)
 74a:	7c42                	ld	s8,48(sp)
 74c:	7ca2                	ld	s9,40(sp)
 74e:	7d02                	ld	s10,32(sp)
 750:	6de2                	ld	s11,24(sp)
 752:	6109                	addi	sp,sp,128
 754:	8082                	ret

0000000000000756 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 756:	715d                	addi	sp,sp,-80
 758:	ec06                	sd	ra,24(sp)
 75a:	e822                	sd	s0,16(sp)
 75c:	1000                	addi	s0,sp,32
 75e:	e010                	sd	a2,0(s0)
 760:	e414                	sd	a3,8(s0)
 762:	e818                	sd	a4,16(s0)
 764:	ec1c                	sd	a5,24(s0)
 766:	03043023          	sd	a6,32(s0)
 76a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 76e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 772:	8622                	mv	a2,s0
 774:	00000097          	auipc	ra,0x0
 778:	e04080e7          	jalr	-508(ra) # 578 <vprintf>
}
 77c:	60e2                	ld	ra,24(sp)
 77e:	6442                	ld	s0,16(sp)
 780:	6161                	addi	sp,sp,80
 782:	8082                	ret

0000000000000784 <printf>:

void
printf(const char *fmt, ...)
{
 784:	711d                	addi	sp,sp,-96
 786:	ec06                	sd	ra,24(sp)
 788:	e822                	sd	s0,16(sp)
 78a:	1000                	addi	s0,sp,32
 78c:	e40c                	sd	a1,8(s0)
 78e:	e810                	sd	a2,16(s0)
 790:	ec14                	sd	a3,24(s0)
 792:	f018                	sd	a4,32(s0)
 794:	f41c                	sd	a5,40(s0)
 796:	03043823          	sd	a6,48(s0)
 79a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 79e:	00840613          	addi	a2,s0,8
 7a2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7a6:	85aa                	mv	a1,a0
 7a8:	4505                	li	a0,1
 7aa:	00000097          	auipc	ra,0x0
 7ae:	dce080e7          	jalr	-562(ra) # 578 <vprintf>
}
 7b2:	60e2                	ld	ra,24(sp)
 7b4:	6442                	ld	s0,16(sp)
 7b6:	6125                	addi	sp,sp,96
 7b8:	8082                	ret

00000000000007ba <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ba:	1141                	addi	sp,sp,-16
 7bc:	e422                	sd	s0,8(sp)
 7be:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7c0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7c4:	00000797          	auipc	a5,0x0
 7c8:	1f47b783          	ld	a5,500(a5) # 9b8 <freep>
 7cc:	a02d                	j	7f6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7ce:	4618                	lw	a4,8(a2)
 7d0:	9f2d                	addw	a4,a4,a1
 7d2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7d6:	6398                	ld	a4,0(a5)
 7d8:	6310                	ld	a2,0(a4)
 7da:	a83d                	j	818 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7dc:	ff852703          	lw	a4,-8(a0)
 7e0:	9f31                	addw	a4,a4,a2
 7e2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 7e4:	ff053683          	ld	a3,-16(a0)
 7e8:	a091                	j	82c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7ea:	6398                	ld	a4,0(a5)
 7ec:	00e7e463          	bltu	a5,a4,7f4 <free+0x3a>
 7f0:	00e6ea63          	bltu	a3,a4,804 <free+0x4a>
{
 7f4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7f6:	fed7fae3          	bgeu	a5,a3,7ea <free+0x30>
 7fa:	6398                	ld	a4,0(a5)
 7fc:	00e6e463          	bltu	a3,a4,804 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 800:	fee7eae3          	bltu	a5,a4,7f4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 804:	ff852583          	lw	a1,-8(a0)
 808:	6390                	ld	a2,0(a5)
 80a:	02059813          	slli	a6,a1,0x20
 80e:	01c85713          	srli	a4,a6,0x1c
 812:	9736                	add	a4,a4,a3
 814:	fae60de3          	beq	a2,a4,7ce <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 818:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 81c:	4790                	lw	a2,8(a5)
 81e:	02061593          	slli	a1,a2,0x20
 822:	01c5d713          	srli	a4,a1,0x1c
 826:	973e                	add	a4,a4,a5
 828:	fae68ae3          	beq	a3,a4,7dc <free+0x22>
    p->s.ptr = bp->s.ptr;
 82c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 82e:	00000717          	auipc	a4,0x0
 832:	18f73523          	sd	a5,394(a4) # 9b8 <freep>
}
 836:	6422                	ld	s0,8(sp)
 838:	0141                	addi	sp,sp,16
 83a:	8082                	ret

000000000000083c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 83c:	7139                	addi	sp,sp,-64
 83e:	fc06                	sd	ra,56(sp)
 840:	f822                	sd	s0,48(sp)
 842:	f426                	sd	s1,40(sp)
 844:	f04a                	sd	s2,32(sp)
 846:	ec4e                	sd	s3,24(sp)
 848:	e852                	sd	s4,16(sp)
 84a:	e456                	sd	s5,8(sp)
 84c:	e05a                	sd	s6,0(sp)
 84e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 850:	02051493          	slli	s1,a0,0x20
 854:	9081                	srli	s1,s1,0x20
 856:	04bd                	addi	s1,s1,15
 858:	8091                	srli	s1,s1,0x4
 85a:	0014899b          	addiw	s3,s1,1
 85e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 860:	00000517          	auipc	a0,0x0
 864:	15853503          	ld	a0,344(a0) # 9b8 <freep>
 868:	c515                	beqz	a0,894 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 86a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 86c:	4798                	lw	a4,8(a5)
 86e:	02977f63          	bgeu	a4,s1,8ac <malloc+0x70>
 872:	8a4e                	mv	s4,s3
 874:	0009871b          	sext.w	a4,s3
 878:	6685                	lui	a3,0x1
 87a:	00d77363          	bgeu	a4,a3,880 <malloc+0x44>
 87e:	6a05                	lui	s4,0x1
 880:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 884:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 888:	00000917          	auipc	s2,0x0
 88c:	13090913          	addi	s2,s2,304 # 9b8 <freep>
  if(p == (char*)-1)
 890:	5afd                	li	s5,-1
 892:	a895                	j	906 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 894:	00000797          	auipc	a5,0x0
 898:	12c78793          	addi	a5,a5,300 # 9c0 <base>
 89c:	00000717          	auipc	a4,0x0
 8a0:	10f73e23          	sd	a5,284(a4) # 9b8 <freep>
 8a4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8a6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8aa:	b7e1                	j	872 <malloc+0x36>
      if(p->s.size == nunits)
 8ac:	02e48c63          	beq	s1,a4,8e4 <malloc+0xa8>
        p->s.size -= nunits;
 8b0:	4137073b          	subw	a4,a4,s3
 8b4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8b6:	02071693          	slli	a3,a4,0x20
 8ba:	01c6d713          	srli	a4,a3,0x1c
 8be:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8c0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8c4:	00000717          	auipc	a4,0x0
 8c8:	0ea73a23          	sd	a0,244(a4) # 9b8 <freep>
      return (void*)(p + 1);
 8cc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8d0:	70e2                	ld	ra,56(sp)
 8d2:	7442                	ld	s0,48(sp)
 8d4:	74a2                	ld	s1,40(sp)
 8d6:	7902                	ld	s2,32(sp)
 8d8:	69e2                	ld	s3,24(sp)
 8da:	6a42                	ld	s4,16(sp)
 8dc:	6aa2                	ld	s5,8(sp)
 8de:	6b02                	ld	s6,0(sp)
 8e0:	6121                	addi	sp,sp,64
 8e2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8e4:	6398                	ld	a4,0(a5)
 8e6:	e118                	sd	a4,0(a0)
 8e8:	bff1                	j	8c4 <malloc+0x88>
  hp->s.size = nu;
 8ea:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8ee:	0541                	addi	a0,a0,16
 8f0:	00000097          	auipc	ra,0x0
 8f4:	eca080e7          	jalr	-310(ra) # 7ba <free>
  return freep;
 8f8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8fc:	d971                	beqz	a0,8d0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8fe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 900:	4798                	lw	a4,8(a5)
 902:	fa9775e3          	bgeu	a4,s1,8ac <malloc+0x70>
    if(p == freep)
 906:	00093703          	ld	a4,0(s2)
 90a:	853e                	mv	a0,a5
 90c:	fef719e3          	bne	a4,a5,8fe <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 910:	8552                	mv	a0,s4
 912:	00000097          	auipc	ra,0x0
 916:	b60080e7          	jalr	-1184(ra) # 472 <sbrk>
  if(p == (char*)-1)
 91a:	fd5518e3          	bne	a0,s5,8ea <malloc+0xae>
        return 0;
 91e:	4501                	li	a0,0
 920:	bf45                	j	8d0 <malloc+0x94>
