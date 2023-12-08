
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
   c:	9c873703          	ld	a4,-1592(a4) # 9d0 <buffer>
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
  26:	9ae80813          	addi	a6,a6,-1618 # 9d0 <buffer>
        if (buffer->num_produced >= MAX) {
  2a:	7ff00513          	li	a0,2047
	buffer->num_produced++;
  2e:	00b706b3          	add	a3,a4,a1
  32:	2785                	addiw	a5,a5,1 # 2001 <__global_pointer$+0xe38>
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
  7e:	9565b583          	ld	a1,-1706(a1) # 9d0 <buffer>
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
  9c:	80150513          	addi	a0,a0,-2047 # 801 <free+0x27>
	    exit(0);
	}
	buffer->total += buffer->buf[buffer->nextout++];
  a0:	00279713          	slli	a4,a5,0x2
  a4:	972e                	add	a4,a4,a1
  a6:	4318                	lw	a4,0(a4)
  a8:	9e39                	addw	a2,a2,a4
  aa:	2785                	addiw	a5,a5,1 # 2001 <__global_pointer$+0xe38>
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
  cc:	80078793          	addi	a5,a5,-2048 # 800 <free+0x26>
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
  f2:	01448593          	addi	a1,s1,20 # 2014 <__global_pointer$+0xe4b>
  f6:	4501                	li	a0,0
  f8:	00000097          	auipc	ra,0x0
  fc:	3a2080e7          	jalr	930(ra) # 49a <mmap>
 100:	00001797          	auipc	a5,0x1
 104:	8ca7b823          	sd	a0,-1840(a5) # 9d0 <buffer>
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
 15a:	87a7b783          	ld	a5,-1926(a5) # 9d0 <buffer>
 15e:	6709                	lui	a4,0x2
 160:	97ba                	add	a5,a5,a4
 162:	4b8c                	lw	a1,16(a5)
 164:	00000517          	auipc	a0,0x0
 168:	7e450513          	addi	a0,a0,2020 # 948 <malloc+0xec>
 16c:	00000097          	auipc	ra,0x0
 170:	638080e7          	jalr	1592(ra) # 7a4 <printf>
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
 30c:	0705                	addi	a4,a4,1 # 2001 <__global_pointer$+0xe38>
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

00000000000004aa <sem_init>:
.global sem_init
sem_init:
 li a7, SYS_sem_init
 4aa:	48e9                	li	a7,26
 ecall
 4ac:	00000073          	ecall
 ret
 4b0:	8082                	ret

00000000000004b2 <sem_destroy>:
.global sem_destroy
sem_destroy:
 li a7, SYS_sem_destroy
 4b2:	48ed                	li	a7,27
 ecall
 4b4:	00000073          	ecall
 ret
 4b8:	8082                	ret

00000000000004ba <sem_wait>:
.global sem_wait
sem_wait:
 li a7, SYS_sem_wait
 4ba:	48f1                	li	a7,28
 ecall
 4bc:	00000073          	ecall
 ret
 4c0:	8082                	ret

00000000000004c2 <sem_post>:
.global sem_post
sem_post:
 li a7, SYS_sem_post
 4c2:	48f5                	li	a7,29
 ecall
 4c4:	00000073          	ecall
 ret
 4c8:	8082                	ret

00000000000004ca <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4ca:	1101                	addi	sp,sp,-32
 4cc:	ec06                	sd	ra,24(sp)
 4ce:	e822                	sd	s0,16(sp)
 4d0:	1000                	addi	s0,sp,32
 4d2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4d6:	4605                	li	a2,1
 4d8:	fef40593          	addi	a1,s0,-17
 4dc:	00000097          	auipc	ra,0x0
 4e0:	f2e080e7          	jalr	-210(ra) # 40a <write>
}
 4e4:	60e2                	ld	ra,24(sp)
 4e6:	6442                	ld	s0,16(sp)
 4e8:	6105                	addi	sp,sp,32
 4ea:	8082                	ret

00000000000004ec <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4ec:	7139                	addi	sp,sp,-64
 4ee:	fc06                	sd	ra,56(sp)
 4f0:	f822                	sd	s0,48(sp)
 4f2:	f426                	sd	s1,40(sp)
 4f4:	f04a                	sd	s2,32(sp)
 4f6:	ec4e                	sd	s3,24(sp)
 4f8:	0080                	addi	s0,sp,64
 4fa:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4fc:	c299                	beqz	a3,502 <printint+0x16>
 4fe:	0805c963          	bltz	a1,590 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 502:	2581                	sext.w	a1,a1
  neg = 0;
 504:	4881                	li	a7,0
 506:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 50a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 50c:	2601                	sext.w	a2,a2
 50e:	00000517          	auipc	a0,0x0
 512:	4aa50513          	addi	a0,a0,1194 # 9b8 <digits>
 516:	883a                	mv	a6,a4
 518:	2705                	addiw	a4,a4,1
 51a:	02c5f7bb          	remuw	a5,a1,a2
 51e:	1782                	slli	a5,a5,0x20
 520:	9381                	srli	a5,a5,0x20
 522:	97aa                	add	a5,a5,a0
 524:	0007c783          	lbu	a5,0(a5)
 528:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 52c:	0005879b          	sext.w	a5,a1
 530:	02c5d5bb          	divuw	a1,a1,a2
 534:	0685                	addi	a3,a3,1
 536:	fec7f0e3          	bgeu	a5,a2,516 <printint+0x2a>
  if(neg)
 53a:	00088c63          	beqz	a7,552 <printint+0x66>
    buf[i++] = '-';
 53e:	fd070793          	addi	a5,a4,-48
 542:	00878733          	add	a4,a5,s0
 546:	02d00793          	li	a5,45
 54a:	fef70823          	sb	a5,-16(a4)
 54e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 552:	02e05863          	blez	a4,582 <printint+0x96>
 556:	fc040793          	addi	a5,s0,-64
 55a:	00e78933          	add	s2,a5,a4
 55e:	fff78993          	addi	s3,a5,-1
 562:	99ba                	add	s3,s3,a4
 564:	377d                	addiw	a4,a4,-1
 566:	1702                	slli	a4,a4,0x20
 568:	9301                	srli	a4,a4,0x20
 56a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 56e:	fff94583          	lbu	a1,-1(s2)
 572:	8526                	mv	a0,s1
 574:	00000097          	auipc	ra,0x0
 578:	f56080e7          	jalr	-170(ra) # 4ca <putc>
  while(--i >= 0)
 57c:	197d                	addi	s2,s2,-1
 57e:	ff3918e3          	bne	s2,s3,56e <printint+0x82>
}
 582:	70e2                	ld	ra,56(sp)
 584:	7442                	ld	s0,48(sp)
 586:	74a2                	ld	s1,40(sp)
 588:	7902                	ld	s2,32(sp)
 58a:	69e2                	ld	s3,24(sp)
 58c:	6121                	addi	sp,sp,64
 58e:	8082                	ret
    x = -xx;
 590:	40b005bb          	negw	a1,a1
    neg = 1;
 594:	4885                	li	a7,1
    x = -xx;
 596:	bf85                	j	506 <printint+0x1a>

0000000000000598 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 598:	7119                	addi	sp,sp,-128
 59a:	fc86                	sd	ra,120(sp)
 59c:	f8a2                	sd	s0,112(sp)
 59e:	f4a6                	sd	s1,104(sp)
 5a0:	f0ca                	sd	s2,96(sp)
 5a2:	ecce                	sd	s3,88(sp)
 5a4:	e8d2                	sd	s4,80(sp)
 5a6:	e4d6                	sd	s5,72(sp)
 5a8:	e0da                	sd	s6,64(sp)
 5aa:	fc5e                	sd	s7,56(sp)
 5ac:	f862                	sd	s8,48(sp)
 5ae:	f466                	sd	s9,40(sp)
 5b0:	f06a                	sd	s10,32(sp)
 5b2:	ec6e                	sd	s11,24(sp)
 5b4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5b6:	0005c903          	lbu	s2,0(a1)
 5ba:	18090f63          	beqz	s2,758 <vprintf+0x1c0>
 5be:	8aaa                	mv	s5,a0
 5c0:	8b32                	mv	s6,a2
 5c2:	00158493          	addi	s1,a1,1
  state = 0;
 5c6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5c8:	02500a13          	li	s4,37
 5cc:	4c55                	li	s8,21
 5ce:	00000c97          	auipc	s9,0x0
 5d2:	392c8c93          	addi	s9,s9,914 # 960 <malloc+0x104>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 5d6:	02800d93          	li	s11,40
  putc(fd, 'x');
 5da:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5dc:	00000b97          	auipc	s7,0x0
 5e0:	3dcb8b93          	addi	s7,s7,988 # 9b8 <digits>
 5e4:	a839                	j	602 <vprintf+0x6a>
        putc(fd, c);
 5e6:	85ca                	mv	a1,s2
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	ee0080e7          	jalr	-288(ra) # 4ca <putc>
 5f2:	a019                	j	5f8 <vprintf+0x60>
    } else if(state == '%'){
 5f4:	01498d63          	beq	s3,s4,60e <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 5f8:	0485                	addi	s1,s1,1
 5fa:	fff4c903          	lbu	s2,-1(s1)
 5fe:	14090d63          	beqz	s2,758 <vprintf+0x1c0>
    if(state == 0){
 602:	fe0999e3          	bnez	s3,5f4 <vprintf+0x5c>
      if(c == '%'){
 606:	ff4910e3          	bne	s2,s4,5e6 <vprintf+0x4e>
        state = '%';
 60a:	89d2                	mv	s3,s4
 60c:	b7f5                	j	5f8 <vprintf+0x60>
      if(c == 'd'){
 60e:	11490c63          	beq	s2,s4,726 <vprintf+0x18e>
 612:	f9d9079b          	addiw	a5,s2,-99
 616:	0ff7f793          	zext.b	a5,a5
 61a:	10fc6e63          	bltu	s8,a5,736 <vprintf+0x19e>
 61e:	f9d9079b          	addiw	a5,s2,-99
 622:	0ff7f713          	zext.b	a4,a5
 626:	10ec6863          	bltu	s8,a4,736 <vprintf+0x19e>
 62a:	00271793          	slli	a5,a4,0x2
 62e:	97e6                	add	a5,a5,s9
 630:	439c                	lw	a5,0(a5)
 632:	97e6                	add	a5,a5,s9
 634:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 636:	008b0913          	addi	s2,s6,8
 63a:	4685                	li	a3,1
 63c:	4629                	li	a2,10
 63e:	000b2583          	lw	a1,0(s6)
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	ea8080e7          	jalr	-344(ra) # 4ec <printint>
 64c:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 64e:	4981                	li	s3,0
 650:	b765                	j	5f8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 652:	008b0913          	addi	s2,s6,8
 656:	4681                	li	a3,0
 658:	4629                	li	a2,10
 65a:	000b2583          	lw	a1,0(s6)
 65e:	8556                	mv	a0,s5
 660:	00000097          	auipc	ra,0x0
 664:	e8c080e7          	jalr	-372(ra) # 4ec <printint>
 668:	8b4a                	mv	s6,s2
      state = 0;
 66a:	4981                	li	s3,0
 66c:	b771                	j	5f8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 66e:	008b0913          	addi	s2,s6,8
 672:	4681                	li	a3,0
 674:	866a                	mv	a2,s10
 676:	000b2583          	lw	a1,0(s6)
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	e70080e7          	jalr	-400(ra) # 4ec <printint>
 684:	8b4a                	mv	s6,s2
      state = 0;
 686:	4981                	li	s3,0
 688:	bf85                	j	5f8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 68a:	008b0793          	addi	a5,s6,8
 68e:	f8f43423          	sd	a5,-120(s0)
 692:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 696:	03000593          	li	a1,48
 69a:	8556                	mv	a0,s5
 69c:	00000097          	auipc	ra,0x0
 6a0:	e2e080e7          	jalr	-466(ra) # 4ca <putc>
  putc(fd, 'x');
 6a4:	07800593          	li	a1,120
 6a8:	8556                	mv	a0,s5
 6aa:	00000097          	auipc	ra,0x0
 6ae:	e20080e7          	jalr	-480(ra) # 4ca <putc>
 6b2:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6b4:	03c9d793          	srli	a5,s3,0x3c
 6b8:	97de                	add	a5,a5,s7
 6ba:	0007c583          	lbu	a1,0(a5)
 6be:	8556                	mv	a0,s5
 6c0:	00000097          	auipc	ra,0x0
 6c4:	e0a080e7          	jalr	-502(ra) # 4ca <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6c8:	0992                	slli	s3,s3,0x4
 6ca:	397d                	addiw	s2,s2,-1
 6cc:	fe0914e3          	bnez	s2,6b4 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 6d0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6d4:	4981                	li	s3,0
 6d6:	b70d                	j	5f8 <vprintf+0x60>
        s = va_arg(ap, char*);
 6d8:	008b0913          	addi	s2,s6,8
 6dc:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 6e0:	02098163          	beqz	s3,702 <vprintf+0x16a>
        while(*s != 0){
 6e4:	0009c583          	lbu	a1,0(s3)
 6e8:	c5ad                	beqz	a1,752 <vprintf+0x1ba>
          putc(fd, *s);
 6ea:	8556                	mv	a0,s5
 6ec:	00000097          	auipc	ra,0x0
 6f0:	dde080e7          	jalr	-546(ra) # 4ca <putc>
          s++;
 6f4:	0985                	addi	s3,s3,1
        while(*s != 0){
 6f6:	0009c583          	lbu	a1,0(s3)
 6fa:	f9e5                	bnez	a1,6ea <vprintf+0x152>
        s = va_arg(ap, char*);
 6fc:	8b4a                	mv	s6,s2
      state = 0;
 6fe:	4981                	li	s3,0
 700:	bde5                	j	5f8 <vprintf+0x60>
          s = "(null)";
 702:	00000997          	auipc	s3,0x0
 706:	25698993          	addi	s3,s3,598 # 958 <malloc+0xfc>
        while(*s != 0){
 70a:	85ee                	mv	a1,s11
 70c:	bff9                	j	6ea <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 70e:	008b0913          	addi	s2,s6,8
 712:	000b4583          	lbu	a1,0(s6)
 716:	8556                	mv	a0,s5
 718:	00000097          	auipc	ra,0x0
 71c:	db2080e7          	jalr	-590(ra) # 4ca <putc>
 720:	8b4a                	mv	s6,s2
      state = 0;
 722:	4981                	li	s3,0
 724:	bdd1                	j	5f8 <vprintf+0x60>
        putc(fd, c);
 726:	85d2                	mv	a1,s4
 728:	8556                	mv	a0,s5
 72a:	00000097          	auipc	ra,0x0
 72e:	da0080e7          	jalr	-608(ra) # 4ca <putc>
      state = 0;
 732:	4981                	li	s3,0
 734:	b5d1                	j	5f8 <vprintf+0x60>
        putc(fd, '%');
 736:	85d2                	mv	a1,s4
 738:	8556                	mv	a0,s5
 73a:	00000097          	auipc	ra,0x0
 73e:	d90080e7          	jalr	-624(ra) # 4ca <putc>
        putc(fd, c);
 742:	85ca                	mv	a1,s2
 744:	8556                	mv	a0,s5
 746:	00000097          	auipc	ra,0x0
 74a:	d84080e7          	jalr	-636(ra) # 4ca <putc>
      state = 0;
 74e:	4981                	li	s3,0
 750:	b565                	j	5f8 <vprintf+0x60>
        s = va_arg(ap, char*);
 752:	8b4a                	mv	s6,s2
      state = 0;
 754:	4981                	li	s3,0
 756:	b54d                	j	5f8 <vprintf+0x60>
    }
  }
}
 758:	70e6                	ld	ra,120(sp)
 75a:	7446                	ld	s0,112(sp)
 75c:	74a6                	ld	s1,104(sp)
 75e:	7906                	ld	s2,96(sp)
 760:	69e6                	ld	s3,88(sp)
 762:	6a46                	ld	s4,80(sp)
 764:	6aa6                	ld	s5,72(sp)
 766:	6b06                	ld	s6,64(sp)
 768:	7be2                	ld	s7,56(sp)
 76a:	7c42                	ld	s8,48(sp)
 76c:	7ca2                	ld	s9,40(sp)
 76e:	7d02                	ld	s10,32(sp)
 770:	6de2                	ld	s11,24(sp)
 772:	6109                	addi	sp,sp,128
 774:	8082                	ret

0000000000000776 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 776:	715d                	addi	sp,sp,-80
 778:	ec06                	sd	ra,24(sp)
 77a:	e822                	sd	s0,16(sp)
 77c:	1000                	addi	s0,sp,32
 77e:	e010                	sd	a2,0(s0)
 780:	e414                	sd	a3,8(s0)
 782:	e818                	sd	a4,16(s0)
 784:	ec1c                	sd	a5,24(s0)
 786:	03043023          	sd	a6,32(s0)
 78a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 78e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 792:	8622                	mv	a2,s0
 794:	00000097          	auipc	ra,0x0
 798:	e04080e7          	jalr	-508(ra) # 598 <vprintf>
}
 79c:	60e2                	ld	ra,24(sp)
 79e:	6442                	ld	s0,16(sp)
 7a0:	6161                	addi	sp,sp,80
 7a2:	8082                	ret

00000000000007a4 <printf>:

void
printf(const char *fmt, ...)
{
 7a4:	711d                	addi	sp,sp,-96
 7a6:	ec06                	sd	ra,24(sp)
 7a8:	e822                	sd	s0,16(sp)
 7aa:	1000                	addi	s0,sp,32
 7ac:	e40c                	sd	a1,8(s0)
 7ae:	e810                	sd	a2,16(s0)
 7b0:	ec14                	sd	a3,24(s0)
 7b2:	f018                	sd	a4,32(s0)
 7b4:	f41c                	sd	a5,40(s0)
 7b6:	03043823          	sd	a6,48(s0)
 7ba:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7be:	00840613          	addi	a2,s0,8
 7c2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7c6:	85aa                	mv	a1,a0
 7c8:	4505                	li	a0,1
 7ca:	00000097          	auipc	ra,0x0
 7ce:	dce080e7          	jalr	-562(ra) # 598 <vprintf>
}
 7d2:	60e2                	ld	ra,24(sp)
 7d4:	6442                	ld	s0,16(sp)
 7d6:	6125                	addi	sp,sp,96
 7d8:	8082                	ret

00000000000007da <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7da:	1141                	addi	sp,sp,-16
 7dc:	e422                	sd	s0,8(sp)
 7de:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7e0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7e4:	00000797          	auipc	a5,0x0
 7e8:	1f47b783          	ld	a5,500(a5) # 9d8 <freep>
 7ec:	a02d                	j	816 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7ee:	4618                	lw	a4,8(a2)
 7f0:	9f2d                	addw	a4,a4,a1
 7f2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7f6:	6398                	ld	a4,0(a5)
 7f8:	6310                	ld	a2,0(a4)
 7fa:	a83d                	j	838 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7fc:	ff852703          	lw	a4,-8(a0)
 800:	9f31                	addw	a4,a4,a2
 802:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 804:	ff053683          	ld	a3,-16(a0)
 808:	a091                	j	84c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 80a:	6398                	ld	a4,0(a5)
 80c:	00e7e463          	bltu	a5,a4,814 <free+0x3a>
 810:	00e6ea63          	bltu	a3,a4,824 <free+0x4a>
{
 814:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 816:	fed7fae3          	bgeu	a5,a3,80a <free+0x30>
 81a:	6398                	ld	a4,0(a5)
 81c:	00e6e463          	bltu	a3,a4,824 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 820:	fee7eae3          	bltu	a5,a4,814 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 824:	ff852583          	lw	a1,-8(a0)
 828:	6390                	ld	a2,0(a5)
 82a:	02059813          	slli	a6,a1,0x20
 82e:	01c85713          	srli	a4,a6,0x1c
 832:	9736                	add	a4,a4,a3
 834:	fae60de3          	beq	a2,a4,7ee <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 838:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 83c:	4790                	lw	a2,8(a5)
 83e:	02061593          	slli	a1,a2,0x20
 842:	01c5d713          	srli	a4,a1,0x1c
 846:	973e                	add	a4,a4,a5
 848:	fae68ae3          	beq	a3,a4,7fc <free+0x22>
    p->s.ptr = bp->s.ptr;
 84c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 84e:	00000717          	auipc	a4,0x0
 852:	18f73523          	sd	a5,394(a4) # 9d8 <freep>
}
 856:	6422                	ld	s0,8(sp)
 858:	0141                	addi	sp,sp,16
 85a:	8082                	ret

000000000000085c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 85c:	7139                	addi	sp,sp,-64
 85e:	fc06                	sd	ra,56(sp)
 860:	f822                	sd	s0,48(sp)
 862:	f426                	sd	s1,40(sp)
 864:	f04a                	sd	s2,32(sp)
 866:	ec4e                	sd	s3,24(sp)
 868:	e852                	sd	s4,16(sp)
 86a:	e456                	sd	s5,8(sp)
 86c:	e05a                	sd	s6,0(sp)
 86e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 870:	02051493          	slli	s1,a0,0x20
 874:	9081                	srli	s1,s1,0x20
 876:	04bd                	addi	s1,s1,15
 878:	8091                	srli	s1,s1,0x4
 87a:	0014899b          	addiw	s3,s1,1
 87e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 880:	00000517          	auipc	a0,0x0
 884:	15853503          	ld	a0,344(a0) # 9d8 <freep>
 888:	c515                	beqz	a0,8b4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 88a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 88c:	4798                	lw	a4,8(a5)
 88e:	02977f63          	bgeu	a4,s1,8cc <malloc+0x70>
 892:	8a4e                	mv	s4,s3
 894:	0009871b          	sext.w	a4,s3
 898:	6685                	lui	a3,0x1
 89a:	00d77363          	bgeu	a4,a3,8a0 <malloc+0x44>
 89e:	6a05                	lui	s4,0x1
 8a0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8a4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8a8:	00000917          	auipc	s2,0x0
 8ac:	13090913          	addi	s2,s2,304 # 9d8 <freep>
  if(p == (char*)-1)
 8b0:	5afd                	li	s5,-1
 8b2:	a895                	j	926 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 8b4:	00000797          	auipc	a5,0x0
 8b8:	12c78793          	addi	a5,a5,300 # 9e0 <base>
 8bc:	00000717          	auipc	a4,0x0
 8c0:	10f73e23          	sd	a5,284(a4) # 9d8 <freep>
 8c4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8c6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8ca:	b7e1                	j	892 <malloc+0x36>
      if(p->s.size == nunits)
 8cc:	02e48c63          	beq	s1,a4,904 <malloc+0xa8>
        p->s.size -= nunits;
 8d0:	4137073b          	subw	a4,a4,s3
 8d4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8d6:	02071693          	slli	a3,a4,0x20
 8da:	01c6d713          	srli	a4,a3,0x1c
 8de:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8e0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8e4:	00000717          	auipc	a4,0x0
 8e8:	0ea73a23          	sd	a0,244(a4) # 9d8 <freep>
      return (void*)(p + 1);
 8ec:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8f0:	70e2                	ld	ra,56(sp)
 8f2:	7442                	ld	s0,48(sp)
 8f4:	74a2                	ld	s1,40(sp)
 8f6:	7902                	ld	s2,32(sp)
 8f8:	69e2                	ld	s3,24(sp)
 8fa:	6a42                	ld	s4,16(sp)
 8fc:	6aa2                	ld	s5,8(sp)
 8fe:	6b02                	ld	s6,0(sp)
 900:	6121                	addi	sp,sp,64
 902:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 904:	6398                	ld	a4,0(a5)
 906:	e118                	sd	a4,0(a0)
 908:	bff1                	j	8e4 <malloc+0x88>
  hp->s.size = nu;
 90a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 90e:	0541                	addi	a0,a0,16
 910:	00000097          	auipc	ra,0x0
 914:	eca080e7          	jalr	-310(ra) # 7da <free>
  return freep;
 918:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 91c:	d971                	beqz	a0,8f0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 91e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 920:	4798                	lw	a4,8(a5)
 922:	fa9775e3          	bgeu	a4,s1,8cc <malloc+0x70>
    if(p == freep)
 926:	00093703          	ld	a4,0(s2)
 92a:	853e                	mv	a0,a5
 92c:	fef719e3          	bne	a4,a5,91e <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 930:	8552                	mv	a0,s4
 932:	00000097          	auipc	ra,0x0
 936:	b40080e7          	jalr	-1216(ra) # 472 <sbrk>
  if(p == (char*)-1)
 93a:	fd5518e3          	bne	a0,s5,90a <malloc+0xae>
        return 0;
 93e:	4501                	li	a0,0
 940:	bf45                	j	8f0 <malloc+0x94>
