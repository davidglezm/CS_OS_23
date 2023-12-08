
user/_prodcons-sem:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <producer>:
} buffer_t;

buffer_t *buffer;

void producer()
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  while(1) {
//    printf("producer calling sem_wait\n");
    sem_wait(&buffer->free);
  10:	00001497          	auipc	s1,0x1
  14:	bf848493          	addi	s1,s1,-1032 # c08 <buffer>
    sem_wait(&buffer->lock);
    if (buffer->num_produced >= MAX) {
  18:	494d                	li	s2,19
        sem_post(&buffer->occupied);
        sem_post(&buffer->lock);
        exit(0);
    }
    buffer->num_produced++;
    printf("producer %d producing %d\n", getpid(), buffer->num_produced);
  1a:	00001a17          	auipc	s4,0x1
  1e:	afea0a13          	addi	s4,s4,-1282 # b18 <malloc+0xea>
    buffer->buf[buffer->nextin++] = buffer->num_produced;

    buffer->nextin %= BSIZE;
  22:	49a9                	li	s3,10
  24:	a891                	j	78 <producer+0x78>
    buffer->num_produced++;
  26:	2785                	addiw	a5,a5,1
  28:	d91c                	sw	a5,48(a0)
    printf("producer %d producing %d\n", getpid(), buffer->num_produced);
  2a:	00000097          	auipc	ra,0x0
  2e:	612080e7          	jalr	1554(ra) # 63c <getpid>
  32:	85aa                	mv	a1,a0
  34:	609c                	ld	a5,0(s1)
  36:	5b90                	lw	a2,48(a5)
  38:	8552                	mv	a0,s4
  3a:	00001097          	auipc	ra,0x1
  3e:	93c080e7          	jalr	-1732(ra) # 976 <printf>
    buffer->buf[buffer->nextin++] = buffer->num_produced;
  42:	6098                	ld	a4,0(s1)
  44:	571c                	lw	a5,40(a4)
  46:	0017869b          	addiw	a3,a5,1
  4a:	d714                	sw	a3,40(a4)
  4c:	078a                	slli	a5,a5,0x2
  4e:	97ba                	add	a5,a5,a4
  50:	5b18                	lw	a4,48(a4)
  52:	c398                	sw	a4,0(a5)
    buffer->nextin %= BSIZE;
  54:	6088                	ld	a0,0(s1)
  56:	551c                	lw	a5,40(a0)
  58:	0337e7bb          	remw	a5,a5,s3
  5c:	d51c                	sw	a5,40(a0)
    sem_post(&buffer->occupied);
  5e:	03c50513          	addi	a0,a0,60
  62:	00000097          	auipc	ra,0x0
  66:	632080e7          	jalr	1586(ra) # 694 <sem_post>
       of the next empty slot in the buffer, or
       buffer->occupied == BSIZE and buffer->nextin is the index of the
       next (occupied) slot that will be emptied by a consumer
       (such as buffer->nextin == buffer->nextout) */

    sem_post(&buffer->lock);
  6a:	6088                	ld	a0,0(s1)
  6c:	04450513          	addi	a0,a0,68
  70:	00000097          	auipc	ra,0x0
  74:	624080e7          	jalr	1572(ra) # 694 <sem_post>
    sem_wait(&buffer->free);
  78:	6088                	ld	a0,0(s1)
  7a:	04050513          	addi	a0,a0,64
  7e:	00000097          	auipc	ra,0x0
  82:	60e080e7          	jalr	1550(ra) # 68c <sem_wait>
    sem_wait(&buffer->lock);
  86:	6088                	ld	a0,0(s1)
  88:	04450513          	addi	a0,a0,68
  8c:	00000097          	auipc	ra,0x0
  90:	600080e7          	jalr	1536(ra) # 68c <sem_wait>
    if (buffer->num_produced >= MAX) {
  94:	6088                	ld	a0,0(s1)
  96:	591c                	lw	a5,48(a0)
  98:	f8f957e3          	bge	s2,a5,26 <producer+0x26>
        sem_post(&buffer->free);
  9c:	04050513          	addi	a0,a0,64
  a0:	00000097          	auipc	ra,0x0
  a4:	5f4080e7          	jalr	1524(ra) # 694 <sem_post>
        sem_post(&buffer->occupied);
  a8:	00001497          	auipc	s1,0x1
  ac:	b6048493          	addi	s1,s1,-1184 # c08 <buffer>
  b0:	6088                	ld	a0,0(s1)
  b2:	03c50513          	addi	a0,a0,60
  b6:	00000097          	auipc	ra,0x0
  ba:	5de080e7          	jalr	1502(ra) # 694 <sem_post>
        sem_post(&buffer->lock);
  be:	6088                	ld	a0,0(s1)
  c0:	04450513          	addi	a0,a0,68
  c4:	00000097          	auipc	ra,0x0
  c8:	5d0080e7          	jalr	1488(ra) # 694 <sem_post>
        exit(0);
  cc:	4501                	li	a0,0
  ce:	00000097          	auipc	ra,0x0
  d2:	4ee080e7          	jalr	1262(ra) # 5bc <exit>

00000000000000d6 <consumer>:
  }
}

void consumer()
{
  d6:	7179                	addi	sp,sp,-48
  d8:	f406                	sd	ra,40(sp)
  da:	f022                	sd	s0,32(sp)
  dc:	ec26                	sd	s1,24(sp)
  de:	e84a                	sd	s2,16(sp)
  e0:	e44e                	sd	s3,8(sp)
  e2:	e052                	sd	s4,0(sp)
  e4:	1800                	addi	s0,sp,48
  while(1) {
 //   printf("Consumer calling sem_wait\n");
    sem_wait(&buffer->occupied);
  e6:	00001497          	auipc	s1,0x1
  ea:	b2248493          	addi	s1,s1,-1246 # c08 <buffer>
    sem_wait(&buffer->lock);
    if (buffer->num_consumed >= MAX) {
  ee:	494d                	li	s2,19
        sem_post(&buffer->occupied);
        sem_post(&buffer->free);
        sem_post(&buffer->lock);
        exit(0);
   }
    printf("consumer %d consuming %d\n", getpid(), buffer->buf[buffer->nextout]);
  f0:	00001a17          	auipc	s4,0x1
  f4:	a48a0a13          	addi	s4,s4,-1464 # b38 <malloc+0x10a>
    buffer->total += buffer->buf[buffer->nextout++];
    buffer->nextout %= BSIZE;
  f8:	49a9                	li	s3,10
  fa:	a8a9                	j	154 <consumer+0x7e>
    printf("consumer %d consuming %d\n", getpid(), buffer->buf[buffer->nextout]);
  fc:	00000097          	auipc	ra,0x0
 100:	540080e7          	jalr	1344(ra) # 63c <getpid>
 104:	85aa                	mv	a1,a0
 106:	609c                	ld	a5,0(s1)
 108:	57d8                	lw	a4,44(a5)
 10a:	070a                	slli	a4,a4,0x2
 10c:	97ba                	add	a5,a5,a4
 10e:	4390                	lw	a2,0(a5)
 110:	8552                	mv	a0,s4
 112:	00001097          	auipc	ra,0x1
 116:	864080e7          	jalr	-1948(ra) # 976 <printf>
    buffer->total += buffer->buf[buffer->nextout++];
 11a:	6088                	ld	a0,0(s1)
 11c:	555c                	lw	a5,44(a0)
 11e:	00279713          	slli	a4,a5,0x2
 122:	972a                	add	a4,a4,a0
 124:	5d14                	lw	a3,56(a0)
 126:	4318                	lw	a4,0(a4)
 128:	9f35                	addw	a4,a4,a3
 12a:	dd18                	sw	a4,56(a0)
 12c:	2785                	addiw	a5,a5,1
    buffer->nextout %= BSIZE;
 12e:	0337e7bb          	remw	a5,a5,s3
 132:	d55c                	sw	a5,44(a0)
    buffer->num_consumed++;
 134:	595c                	lw	a5,52(a0)
 136:	2785                	addiw	a5,a5,1
 138:	d95c                	sw	a5,52(a0)
    sem_post(&buffer->free);
 13a:	04050513          	addi	a0,a0,64
 13e:	00000097          	auipc	ra,0x0
 142:	556080e7          	jalr	1366(ra) # 694 <sem_post>
       of the next occupied slot in the buffer, or
       b->occupied == 0 and b->nextout is the index of the next
       (empty) slot that will be filled by a producer (such as
       b->nextout == b->nextin) */

    sem_post(&buffer->lock);
 146:	6088                	ld	a0,0(s1)
 148:	04450513          	addi	a0,a0,68
 14c:	00000097          	auipc	ra,0x0
 150:	548080e7          	jalr	1352(ra) # 694 <sem_post>
    sem_wait(&buffer->occupied);
 154:	6088                	ld	a0,0(s1)
 156:	03c50513          	addi	a0,a0,60
 15a:	00000097          	auipc	ra,0x0
 15e:	532080e7          	jalr	1330(ra) # 68c <sem_wait>
    sem_wait(&buffer->lock);
 162:	6088                	ld	a0,0(s1)
 164:	04450513          	addi	a0,a0,68
 168:	00000097          	auipc	ra,0x0
 16c:	524080e7          	jalr	1316(ra) # 68c <sem_wait>
    if (buffer->num_consumed >= MAX) {
 170:	6088                	ld	a0,0(s1)
 172:	595c                	lw	a5,52(a0)
 174:	f8f954e3          	bge	s2,a5,fc <consumer+0x26>
        sem_post(&buffer->occupied);
 178:	03c50513          	addi	a0,a0,60
 17c:	00000097          	auipc	ra,0x0
 180:	518080e7          	jalr	1304(ra) # 694 <sem_post>
        sem_post(&buffer->free);
 184:	00001497          	auipc	s1,0x1
 188:	a8448493          	addi	s1,s1,-1404 # c08 <buffer>
 18c:	6088                	ld	a0,0(s1)
 18e:	04050513          	addi	a0,a0,64
 192:	00000097          	auipc	ra,0x0
 196:	502080e7          	jalr	1282(ra) # 694 <sem_post>
        sem_post(&buffer->lock);
 19a:	6088                	ld	a0,0(s1)
 19c:	04450513          	addi	a0,a0,68
 1a0:	00000097          	auipc	ra,0x0
 1a4:	4f4080e7          	jalr	1268(ra) # 694 <sem_post>
        exit(0);
 1a8:	4501                	li	a0,0
 1aa:	00000097          	auipc	ra,0x0
 1ae:	412080e7          	jalr	1042(ra) # 5bc <exit>

00000000000001b2 <main>:

  }
}

int main(int argc, char *argv[])
{
 1b2:	7179                	addi	sp,sp,-48
 1b4:	f406                	sd	ra,40(sp)
 1b6:	f022                	sd	s0,32(sp)
 1b8:	ec26                	sd	s1,24(sp)
 1ba:	e84a                	sd	s2,16(sp)
 1bc:	e44e                	sd	s3,8(sp)
 1be:	1800                	addi	s0,sp,48
 1c0:	84ae                	mv	s1,a1
  if (argc != 3) {
 1c2:	478d                	li	a5,3
 1c4:	02f50063          	beq	a0,a5,1e4 <main+0x32>
     printf("usage: %s <nproducers> <nconsumers>\n", argv[0]);
 1c8:	618c                	ld	a1,0(a1)
 1ca:	00001517          	auipc	a0,0x1
 1ce:	98e50513          	addi	a0,a0,-1650 # b58 <malloc+0x12a>
 1d2:	00000097          	auipc	ra,0x0
 1d6:	7a4080e7          	jalr	1956(ra) # 976 <printf>
     exit(0);
 1da:	4501                	li	a0,0
 1dc:	00000097          	auipc	ra,0x0
 1e0:	3e0080e7          	jalr	992(ra) # 5bc <exit>
  }
  int nproducers = atoi(argv[1]);
 1e4:	6588                	ld	a0,8(a1)
 1e6:	00000097          	auipc	ra,0x0
 1ea:	2dc080e7          	jalr	732(ra) # 4c2 <atoi>
 1ee:	89aa                	mv	s3,a0
  int nconsumers = atoi(argv[2]);
 1f0:	6888                	ld	a0,16(s1)
 1f2:	00000097          	auipc	ra,0x0
 1f6:	2d0080e7          	jalr	720(ra) # 4c2 <atoi>
 1fa:	892a                	mv	s2,a0
  int i;

  buffer = (buffer_t *) mmap(NULL, sizeof(buffer_t), 
 1fc:	4781                	li	a5,0
 1fe:	577d                	li	a4,-1
 200:	02100693          	li	a3,33
 204:	4619                	li	a2,6
 206:	04800593          	li	a1,72
 20a:	4501                	li	a0,0
 20c:	00000097          	auipc	ra,0x0
 210:	460080e7          	jalr	1120(ra) # 66c <mmap>
 214:	00001497          	auipc	s1,0x1
 218:	9f448493          	addi	s1,s1,-1548 # c08 <buffer>
 21c:	e088                	sd	a0,0(s1)
                          PROT_READ | PROT_WRITE,
                          MAP_ANONYMOUS | MAP_SHARED, -1, 0);
  buffer->nextin = 0;
 21e:	02052423          	sw	zero,40(a0)
  buffer->nextout = 0;
 222:	02052623          	sw	zero,44(a0)
  buffer->num_produced = 0;
 226:	02052823          	sw	zero,48(a0)
  buffer->num_consumed = 0;
 22a:	02052a23          	sw	zero,52(a0)
  buffer->total = 0;
 22e:	02052c23          	sw	zero,56(a0)
  sem_init(&buffer->occupied, 1, 0);
 232:	4601                	li	a2,0
 234:	4585                	li	a1,1
 236:	03c50513          	addi	a0,a0,60
 23a:	00000097          	auipc	ra,0x0
 23e:	442080e7          	jalr	1090(ra) # 67c <sem_init>
  sem_init(&buffer->free, 1, BSIZE);
 242:	6088                	ld	a0,0(s1)
 244:	4629                	li	a2,10
 246:	4585                	li	a1,1
 248:	04050513          	addi	a0,a0,64
 24c:	00000097          	auipc	ra,0x0
 250:	430080e7          	jalr	1072(ra) # 67c <sem_init>
  sem_init(&buffer->lock, 1, 1);
 254:	6088                	ld	a0,0(s1)
 256:	4605                	li	a2,1
 258:	4585                	li	a1,1
 25a:	04450513          	addi	a0,a0,68
 25e:	00000097          	auipc	ra,0x0
 262:	41e080e7          	jalr	1054(ra) # 67c <sem_init>

  for (i = 0; i < BSIZE; i++)
 266:	4781                	li	a5,0
    buffer->buf[i] = 0;
 268:	85a6                	mv	a1,s1
  for (i = 0; i < BSIZE; i++)
 26a:	4629                	li	a2,10
    buffer->buf[i] = 0;
 26c:	6198                	ld	a4,0(a1)
 26e:	00279693          	slli	a3,a5,0x2
 272:	9736                	add	a4,a4,a3
 274:	00072023          	sw	zero,0(a4)
  for (i = 0; i < BSIZE; i++)
 278:	2785                	addiw	a5,a5,1
 27a:	fec799e3          	bne	a5,a2,26c <main+0xba>

  for (i = 0; i < nconsumers; i++)
 27e:	0d205663          	blez	s2,34a <main+0x198>
 282:	4481                	li	s1,0
    if (!fork()) { 
 284:	00000097          	auipc	ra,0x0
 288:	330080e7          	jalr	816(ra) # 5b4 <fork>
 28c:	c545                	beqz	a0,334 <main+0x182>
  for (i = 0; i < nconsumers; i++)
 28e:	2485                	addiw	s1,s1,1
 290:	fe991ae3          	bne	s2,s1,284 <main+0xd2>
      consumer();
      exit(0);
    }
  for (i = 0; i < nproducers; i++)
 294:	0b305863          	blez	s3,344 <main+0x192>
 298:	4481                	li	s1,0
    if (!fork()) {
 29a:	00000097          	auipc	ra,0x0
 29e:	31a080e7          	jalr	794(ra) # 5b4 <fork>
 2a2:	cd49                	beqz	a0,33c <main+0x18a>
  for (i = 0; i < nproducers; i++)
 2a4:	2485                	addiw	s1,s1,1
 2a6:	fe999ae3          	bne	s3,s1,29a <main+0xe8>
      producer();
      exit(0);
    }
  for (i = 0; i < nconsumers; i++)
 2aa:	01205d63          	blez	s2,2c4 <main+0x112>
 2ae:	4481                	li	s1,0
    wait(0);
 2b0:	4501                	li	a0,0
 2b2:	00000097          	auipc	ra,0x0
 2b6:	312080e7          	jalr	786(ra) # 5c4 <wait>
  for (i = 0; i < nconsumers; i++)
 2ba:	2485                	addiw	s1,s1,1
 2bc:	ff24cae3          	blt	s1,s2,2b0 <main+0xfe>
  for (i = 0; i < nproducers; i++)
 2c0:	01305b63          	blez	s3,2d6 <main+0x124>
  for (i = 0; i < nconsumers; i++)
 2c4:	4481                	li	s1,0
    wait(0);
 2c6:	4501                	li	a0,0
 2c8:	00000097          	auipc	ra,0x0
 2cc:	2fc080e7          	jalr	764(ra) # 5c4 <wait>
  for (i = 0; i < nproducers; i++)
 2d0:	2485                	addiw	s1,s1,1
 2d2:	ff34cae3          	blt	s1,s3,2c6 <main+0x114>
  printf("total = %d\n", buffer->total);
 2d6:	00001497          	auipc	s1,0x1
 2da:	93248493          	addi	s1,s1,-1742 # c08 <buffer>
 2de:	609c                	ld	a5,0(s1)
 2e0:	5f8c                	lw	a1,56(a5)
 2e2:	00001517          	auipc	a0,0x1
 2e6:	89e50513          	addi	a0,a0,-1890 # b80 <malloc+0x152>
 2ea:	00000097          	auipc	ra,0x0
 2ee:	68c080e7          	jalr	1676(ra) # 976 <printf>
  sem_destroy(&buffer->occupied);
 2f2:	6088                	ld	a0,0(s1)
 2f4:	03c50513          	addi	a0,a0,60
 2f8:	00000097          	auipc	ra,0x0
 2fc:	38c080e7          	jalr	908(ra) # 684 <sem_destroy>
  sem_destroy(&buffer->free);
 300:	6088                	ld	a0,0(s1)
 302:	04050513          	addi	a0,a0,64
 306:	00000097          	auipc	ra,0x0
 30a:	37e080e7          	jalr	894(ra) # 684 <sem_destroy>
  sem_destroy(&buffer->lock);
 30e:	6088                	ld	a0,0(s1)
 310:	04450513          	addi	a0,a0,68
 314:	00000097          	auipc	ra,0x0
 318:	370080e7          	jalr	880(ra) # 684 <sem_destroy>
  munmap(buffer, sizeof(buffer_t));
 31c:	04800593          	li	a1,72
 320:	6088                	ld	a0,0(s1)
 322:	00000097          	auipc	ra,0x0
 326:	352080e7          	jalr	850(ra) # 674 <munmap>

  exit(0);
 32a:	4501                	li	a0,0
 32c:	00000097          	auipc	ra,0x0
 330:	290080e7          	jalr	656(ra) # 5bc <exit>
      consumer();
 334:	00000097          	auipc	ra,0x0
 338:	da2080e7          	jalr	-606(ra) # d6 <consumer>
      producer();
 33c:	00000097          	auipc	ra,0x0
 340:	cc4080e7          	jalr	-828(ra) # 0 <producer>
  for (i = 0; i < nconsumers; i++)
 344:	f72045e3          	bgtz	s2,2ae <main+0xfc>
 348:	b779                	j	2d6 <main+0x124>
  for (i = 0; i < nproducers; i++)
 34a:	f53047e3          	bgtz	s3,298 <main+0xe6>
 34e:	b761                	j	2d6 <main+0x124>

0000000000000350 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 350:	1141                	addi	sp,sp,-16
 352:	e422                	sd	s0,8(sp)
 354:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 356:	87aa                	mv	a5,a0
 358:	0585                	addi	a1,a1,1
 35a:	0785                	addi	a5,a5,1
 35c:	fff5c703          	lbu	a4,-1(a1)
 360:	fee78fa3          	sb	a4,-1(a5)
 364:	fb75                	bnez	a4,358 <strcpy+0x8>
    ;
  return os;
}
 366:	6422                	ld	s0,8(sp)
 368:	0141                	addi	sp,sp,16
 36a:	8082                	ret

000000000000036c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 36c:	1141                	addi	sp,sp,-16
 36e:	e422                	sd	s0,8(sp)
 370:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 372:	00054783          	lbu	a5,0(a0)
 376:	cb91                	beqz	a5,38a <strcmp+0x1e>
 378:	0005c703          	lbu	a4,0(a1)
 37c:	00f71763          	bne	a4,a5,38a <strcmp+0x1e>
    p++, q++;
 380:	0505                	addi	a0,a0,1
 382:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 384:	00054783          	lbu	a5,0(a0)
 388:	fbe5                	bnez	a5,378 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 38a:	0005c503          	lbu	a0,0(a1)
}
 38e:	40a7853b          	subw	a0,a5,a0
 392:	6422                	ld	s0,8(sp)
 394:	0141                	addi	sp,sp,16
 396:	8082                	ret

0000000000000398 <strlen>:

uint
strlen(const char *s)
{
 398:	1141                	addi	sp,sp,-16
 39a:	e422                	sd	s0,8(sp)
 39c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 39e:	00054783          	lbu	a5,0(a0)
 3a2:	cf91                	beqz	a5,3be <strlen+0x26>
 3a4:	0505                	addi	a0,a0,1
 3a6:	87aa                	mv	a5,a0
 3a8:	4685                	li	a3,1
 3aa:	9e89                	subw	a3,a3,a0
 3ac:	00f6853b          	addw	a0,a3,a5
 3b0:	0785                	addi	a5,a5,1
 3b2:	fff7c703          	lbu	a4,-1(a5)
 3b6:	fb7d                	bnez	a4,3ac <strlen+0x14>
    ;
  return n;
}
 3b8:	6422                	ld	s0,8(sp)
 3ba:	0141                	addi	sp,sp,16
 3bc:	8082                	ret
  for(n = 0; s[n]; n++)
 3be:	4501                	li	a0,0
 3c0:	bfe5                	j	3b8 <strlen+0x20>

00000000000003c2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 3c2:	1141                	addi	sp,sp,-16
 3c4:	e422                	sd	s0,8(sp)
 3c6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3c8:	ca19                	beqz	a2,3de <memset+0x1c>
 3ca:	87aa                	mv	a5,a0
 3cc:	1602                	slli	a2,a2,0x20
 3ce:	9201                	srli	a2,a2,0x20
 3d0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 3d4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3d8:	0785                	addi	a5,a5,1
 3da:	fee79de3          	bne	a5,a4,3d4 <memset+0x12>
  }
  return dst;
}
 3de:	6422                	ld	s0,8(sp)
 3e0:	0141                	addi	sp,sp,16
 3e2:	8082                	ret

00000000000003e4 <strchr>:

char*
strchr(const char *s, char c)
{
 3e4:	1141                	addi	sp,sp,-16
 3e6:	e422                	sd	s0,8(sp)
 3e8:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3ea:	00054783          	lbu	a5,0(a0)
 3ee:	cb99                	beqz	a5,404 <strchr+0x20>
    if(*s == c)
 3f0:	00f58763          	beq	a1,a5,3fe <strchr+0x1a>
  for(; *s; s++)
 3f4:	0505                	addi	a0,a0,1
 3f6:	00054783          	lbu	a5,0(a0)
 3fa:	fbfd                	bnez	a5,3f0 <strchr+0xc>
      return (char*)s;
  return 0;
 3fc:	4501                	li	a0,0
}
 3fe:	6422                	ld	s0,8(sp)
 400:	0141                	addi	sp,sp,16
 402:	8082                	ret
  return 0;
 404:	4501                	li	a0,0
 406:	bfe5                	j	3fe <strchr+0x1a>

0000000000000408 <gets>:

char*
gets(char *buf, int max)
{
 408:	711d                	addi	sp,sp,-96
 40a:	ec86                	sd	ra,88(sp)
 40c:	e8a2                	sd	s0,80(sp)
 40e:	e4a6                	sd	s1,72(sp)
 410:	e0ca                	sd	s2,64(sp)
 412:	fc4e                	sd	s3,56(sp)
 414:	f852                	sd	s4,48(sp)
 416:	f456                	sd	s5,40(sp)
 418:	f05a                	sd	s6,32(sp)
 41a:	ec5e                	sd	s7,24(sp)
 41c:	1080                	addi	s0,sp,96
 41e:	8baa                	mv	s7,a0
 420:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 422:	892a                	mv	s2,a0
 424:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 426:	4aa9                	li	s5,10
 428:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 42a:	89a6                	mv	s3,s1
 42c:	2485                	addiw	s1,s1,1
 42e:	0344d863          	bge	s1,s4,45e <gets+0x56>
    cc = read(0, &c, 1);
 432:	4605                	li	a2,1
 434:	faf40593          	addi	a1,s0,-81
 438:	4501                	li	a0,0
 43a:	00000097          	auipc	ra,0x0
 43e:	19a080e7          	jalr	410(ra) # 5d4 <read>
    if(cc < 1)
 442:	00a05e63          	blez	a0,45e <gets+0x56>
    buf[i++] = c;
 446:	faf44783          	lbu	a5,-81(s0)
 44a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 44e:	01578763          	beq	a5,s5,45c <gets+0x54>
 452:	0905                	addi	s2,s2,1
 454:	fd679be3          	bne	a5,s6,42a <gets+0x22>
  for(i=0; i+1 < max; ){
 458:	89a6                	mv	s3,s1
 45a:	a011                	j	45e <gets+0x56>
 45c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 45e:	99de                	add	s3,s3,s7
 460:	00098023          	sb	zero,0(s3)
  return buf;
}
 464:	855e                	mv	a0,s7
 466:	60e6                	ld	ra,88(sp)
 468:	6446                	ld	s0,80(sp)
 46a:	64a6                	ld	s1,72(sp)
 46c:	6906                	ld	s2,64(sp)
 46e:	79e2                	ld	s3,56(sp)
 470:	7a42                	ld	s4,48(sp)
 472:	7aa2                	ld	s5,40(sp)
 474:	7b02                	ld	s6,32(sp)
 476:	6be2                	ld	s7,24(sp)
 478:	6125                	addi	sp,sp,96
 47a:	8082                	ret

000000000000047c <stat>:

int
stat(const char *n, struct stat *st)
{
 47c:	1101                	addi	sp,sp,-32
 47e:	ec06                	sd	ra,24(sp)
 480:	e822                	sd	s0,16(sp)
 482:	e426                	sd	s1,8(sp)
 484:	e04a                	sd	s2,0(sp)
 486:	1000                	addi	s0,sp,32
 488:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 48a:	4581                	li	a1,0
 48c:	00000097          	auipc	ra,0x0
 490:	170080e7          	jalr	368(ra) # 5fc <open>
  if(fd < 0)
 494:	02054563          	bltz	a0,4be <stat+0x42>
 498:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 49a:	85ca                	mv	a1,s2
 49c:	00000097          	auipc	ra,0x0
 4a0:	178080e7          	jalr	376(ra) # 614 <fstat>
 4a4:	892a                	mv	s2,a0
  close(fd);
 4a6:	8526                	mv	a0,s1
 4a8:	00000097          	auipc	ra,0x0
 4ac:	13c080e7          	jalr	316(ra) # 5e4 <close>
  return r;
}
 4b0:	854a                	mv	a0,s2
 4b2:	60e2                	ld	ra,24(sp)
 4b4:	6442                	ld	s0,16(sp)
 4b6:	64a2                	ld	s1,8(sp)
 4b8:	6902                	ld	s2,0(sp)
 4ba:	6105                	addi	sp,sp,32
 4bc:	8082                	ret
    return -1;
 4be:	597d                	li	s2,-1
 4c0:	bfc5                	j	4b0 <stat+0x34>

00000000000004c2 <atoi>:

int
atoi(const char *s)
{
 4c2:	1141                	addi	sp,sp,-16
 4c4:	e422                	sd	s0,8(sp)
 4c6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4c8:	00054683          	lbu	a3,0(a0)
 4cc:	fd06879b          	addiw	a5,a3,-48
 4d0:	0ff7f793          	zext.b	a5,a5
 4d4:	4625                	li	a2,9
 4d6:	02f66863          	bltu	a2,a5,506 <atoi+0x44>
 4da:	872a                	mv	a4,a0
  n = 0;
 4dc:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 4de:	0705                	addi	a4,a4,1
 4e0:	0025179b          	slliw	a5,a0,0x2
 4e4:	9fa9                	addw	a5,a5,a0
 4e6:	0017979b          	slliw	a5,a5,0x1
 4ea:	9fb5                	addw	a5,a5,a3
 4ec:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4f0:	00074683          	lbu	a3,0(a4)
 4f4:	fd06879b          	addiw	a5,a3,-48
 4f8:	0ff7f793          	zext.b	a5,a5
 4fc:	fef671e3          	bgeu	a2,a5,4de <atoi+0x1c>
  return n;
}
 500:	6422                	ld	s0,8(sp)
 502:	0141                	addi	sp,sp,16
 504:	8082                	ret
  n = 0;
 506:	4501                	li	a0,0
 508:	bfe5                	j	500 <atoi+0x3e>

000000000000050a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 50a:	1141                	addi	sp,sp,-16
 50c:	e422                	sd	s0,8(sp)
 50e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 510:	02b57463          	bgeu	a0,a1,538 <memmove+0x2e>
    while(n-- > 0)
 514:	00c05f63          	blez	a2,532 <memmove+0x28>
 518:	1602                	slli	a2,a2,0x20
 51a:	9201                	srli	a2,a2,0x20
 51c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 520:	872a                	mv	a4,a0
      *dst++ = *src++;
 522:	0585                	addi	a1,a1,1
 524:	0705                	addi	a4,a4,1
 526:	fff5c683          	lbu	a3,-1(a1)
 52a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 52e:	fee79ae3          	bne	a5,a4,522 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 532:	6422                	ld	s0,8(sp)
 534:	0141                	addi	sp,sp,16
 536:	8082                	ret
    dst += n;
 538:	00c50733          	add	a4,a0,a2
    src += n;
 53c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 53e:	fec05ae3          	blez	a2,532 <memmove+0x28>
 542:	fff6079b          	addiw	a5,a2,-1
 546:	1782                	slli	a5,a5,0x20
 548:	9381                	srli	a5,a5,0x20
 54a:	fff7c793          	not	a5,a5
 54e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 550:	15fd                	addi	a1,a1,-1
 552:	177d                	addi	a4,a4,-1
 554:	0005c683          	lbu	a3,0(a1)
 558:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 55c:	fee79ae3          	bne	a5,a4,550 <memmove+0x46>
 560:	bfc9                	j	532 <memmove+0x28>

0000000000000562 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 562:	1141                	addi	sp,sp,-16
 564:	e422                	sd	s0,8(sp)
 566:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 568:	ca05                	beqz	a2,598 <memcmp+0x36>
 56a:	fff6069b          	addiw	a3,a2,-1
 56e:	1682                	slli	a3,a3,0x20
 570:	9281                	srli	a3,a3,0x20
 572:	0685                	addi	a3,a3,1
 574:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 576:	00054783          	lbu	a5,0(a0)
 57a:	0005c703          	lbu	a4,0(a1)
 57e:	00e79863          	bne	a5,a4,58e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 582:	0505                	addi	a0,a0,1
    p2++;
 584:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 586:	fed518e3          	bne	a0,a3,576 <memcmp+0x14>
  }
  return 0;
 58a:	4501                	li	a0,0
 58c:	a019                	j	592 <memcmp+0x30>
      return *p1 - *p2;
 58e:	40e7853b          	subw	a0,a5,a4
}
 592:	6422                	ld	s0,8(sp)
 594:	0141                	addi	sp,sp,16
 596:	8082                	ret
  return 0;
 598:	4501                	li	a0,0
 59a:	bfe5                	j	592 <memcmp+0x30>

000000000000059c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 59c:	1141                	addi	sp,sp,-16
 59e:	e406                	sd	ra,8(sp)
 5a0:	e022                	sd	s0,0(sp)
 5a2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 5a4:	00000097          	auipc	ra,0x0
 5a8:	f66080e7          	jalr	-154(ra) # 50a <memmove>
}
 5ac:	60a2                	ld	ra,8(sp)
 5ae:	6402                	ld	s0,0(sp)
 5b0:	0141                	addi	sp,sp,16
 5b2:	8082                	ret

00000000000005b4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5b4:	4885                	li	a7,1
 ecall
 5b6:	00000073          	ecall
 ret
 5ba:	8082                	ret

00000000000005bc <exit>:
.global exit
exit:
 li a7, SYS_exit
 5bc:	4889                	li	a7,2
 ecall
 5be:	00000073          	ecall
 ret
 5c2:	8082                	ret

00000000000005c4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 5c4:	488d                	li	a7,3
 ecall
 5c6:	00000073          	ecall
 ret
 5ca:	8082                	ret

00000000000005cc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5cc:	4891                	li	a7,4
 ecall
 5ce:	00000073          	ecall
 ret
 5d2:	8082                	ret

00000000000005d4 <read>:
.global read
read:
 li a7, SYS_read
 5d4:	4895                	li	a7,5
 ecall
 5d6:	00000073          	ecall
 ret
 5da:	8082                	ret

00000000000005dc <write>:
.global write
write:
 li a7, SYS_write
 5dc:	48c1                	li	a7,16
 ecall
 5de:	00000073          	ecall
 ret
 5e2:	8082                	ret

00000000000005e4 <close>:
.global close
close:
 li a7, SYS_close
 5e4:	48d5                	li	a7,21
 ecall
 5e6:	00000073          	ecall
 ret
 5ea:	8082                	ret

00000000000005ec <kill>:
.global kill
kill:
 li a7, SYS_kill
 5ec:	4899                	li	a7,6
 ecall
 5ee:	00000073          	ecall
 ret
 5f2:	8082                	ret

00000000000005f4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 5f4:	489d                	li	a7,7
 ecall
 5f6:	00000073          	ecall
 ret
 5fa:	8082                	ret

00000000000005fc <open>:
.global open
open:
 li a7, SYS_open
 5fc:	48bd                	li	a7,15
 ecall
 5fe:	00000073          	ecall
 ret
 602:	8082                	ret

0000000000000604 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 604:	48c5                	li	a7,17
 ecall
 606:	00000073          	ecall
 ret
 60a:	8082                	ret

000000000000060c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 60c:	48c9                	li	a7,18
 ecall
 60e:	00000073          	ecall
 ret
 612:	8082                	ret

0000000000000614 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 614:	48a1                	li	a7,8
 ecall
 616:	00000073          	ecall
 ret
 61a:	8082                	ret

000000000000061c <link>:
.global link
link:
 li a7, SYS_link
 61c:	48cd                	li	a7,19
 ecall
 61e:	00000073          	ecall
 ret
 622:	8082                	ret

0000000000000624 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 624:	48d1                	li	a7,20
 ecall
 626:	00000073          	ecall
 ret
 62a:	8082                	ret

000000000000062c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 62c:	48a5                	li	a7,9
 ecall
 62e:	00000073          	ecall
 ret
 632:	8082                	ret

0000000000000634 <dup>:
.global dup
dup:
 li a7, SYS_dup
 634:	48a9                	li	a7,10
 ecall
 636:	00000073          	ecall
 ret
 63a:	8082                	ret

000000000000063c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 63c:	48ad                	li	a7,11
 ecall
 63e:	00000073          	ecall
 ret
 642:	8082                	ret

0000000000000644 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 644:	48b1                	li	a7,12
 ecall
 646:	00000073          	ecall
 ret
 64a:	8082                	ret

000000000000064c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 64c:	48b5                	li	a7,13
 ecall
 64e:	00000073          	ecall
 ret
 652:	8082                	ret

0000000000000654 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 654:	48b9                	li	a7,14
 ecall
 656:	00000073          	ecall
 ret
 65a:	8082                	ret

000000000000065c <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 65c:	48d9                	li	a7,22
 ecall
 65e:	00000073          	ecall
 ret
 662:	8082                	ret

0000000000000664 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 664:	48dd                	li	a7,23
 ecall
 666:	00000073          	ecall
 ret
 66a:	8082                	ret

000000000000066c <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 66c:	48e1                	li	a7,24
 ecall
 66e:	00000073          	ecall
 ret
 672:	8082                	ret

0000000000000674 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 674:	48e5                	li	a7,25
 ecall
 676:	00000073          	ecall
 ret
 67a:	8082                	ret

000000000000067c <sem_init>:
.global sem_init
sem_init:
 li a7, SYS_sem_init
 67c:	48e9                	li	a7,26
 ecall
 67e:	00000073          	ecall
 ret
 682:	8082                	ret

0000000000000684 <sem_destroy>:
.global sem_destroy
sem_destroy:
 li a7, SYS_sem_destroy
 684:	48ed                	li	a7,27
 ecall
 686:	00000073          	ecall
 ret
 68a:	8082                	ret

000000000000068c <sem_wait>:
.global sem_wait
sem_wait:
 li a7, SYS_sem_wait
 68c:	48f1                	li	a7,28
 ecall
 68e:	00000073          	ecall
 ret
 692:	8082                	ret

0000000000000694 <sem_post>:
.global sem_post
sem_post:
 li a7, SYS_sem_post
 694:	48f5                	li	a7,29
 ecall
 696:	00000073          	ecall
 ret
 69a:	8082                	ret

000000000000069c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 69c:	1101                	addi	sp,sp,-32
 69e:	ec06                	sd	ra,24(sp)
 6a0:	e822                	sd	s0,16(sp)
 6a2:	1000                	addi	s0,sp,32
 6a4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 6a8:	4605                	li	a2,1
 6aa:	fef40593          	addi	a1,s0,-17
 6ae:	00000097          	auipc	ra,0x0
 6b2:	f2e080e7          	jalr	-210(ra) # 5dc <write>
}
 6b6:	60e2                	ld	ra,24(sp)
 6b8:	6442                	ld	s0,16(sp)
 6ba:	6105                	addi	sp,sp,32
 6bc:	8082                	ret

00000000000006be <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 6be:	7139                	addi	sp,sp,-64
 6c0:	fc06                	sd	ra,56(sp)
 6c2:	f822                	sd	s0,48(sp)
 6c4:	f426                	sd	s1,40(sp)
 6c6:	f04a                	sd	s2,32(sp)
 6c8:	ec4e                	sd	s3,24(sp)
 6ca:	0080                	addi	s0,sp,64
 6cc:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 6ce:	c299                	beqz	a3,6d4 <printint+0x16>
 6d0:	0805c963          	bltz	a1,762 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 6d4:	2581                	sext.w	a1,a1
  neg = 0;
 6d6:	4881                	li	a7,0
 6d8:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 6dc:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 6de:	2601                	sext.w	a2,a2
 6e0:	00000517          	auipc	a0,0x0
 6e4:	51050513          	addi	a0,a0,1296 # bf0 <digits>
 6e8:	883a                	mv	a6,a4
 6ea:	2705                	addiw	a4,a4,1
 6ec:	02c5f7bb          	remuw	a5,a1,a2
 6f0:	1782                	slli	a5,a5,0x20
 6f2:	9381                	srli	a5,a5,0x20
 6f4:	97aa                	add	a5,a5,a0
 6f6:	0007c783          	lbu	a5,0(a5)
 6fa:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6fe:	0005879b          	sext.w	a5,a1
 702:	02c5d5bb          	divuw	a1,a1,a2
 706:	0685                	addi	a3,a3,1
 708:	fec7f0e3          	bgeu	a5,a2,6e8 <printint+0x2a>
  if(neg)
 70c:	00088c63          	beqz	a7,724 <printint+0x66>
    buf[i++] = '-';
 710:	fd070793          	addi	a5,a4,-48
 714:	00878733          	add	a4,a5,s0
 718:	02d00793          	li	a5,45
 71c:	fef70823          	sb	a5,-16(a4)
 720:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 724:	02e05863          	blez	a4,754 <printint+0x96>
 728:	fc040793          	addi	a5,s0,-64
 72c:	00e78933          	add	s2,a5,a4
 730:	fff78993          	addi	s3,a5,-1
 734:	99ba                	add	s3,s3,a4
 736:	377d                	addiw	a4,a4,-1
 738:	1702                	slli	a4,a4,0x20
 73a:	9301                	srli	a4,a4,0x20
 73c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 740:	fff94583          	lbu	a1,-1(s2)
 744:	8526                	mv	a0,s1
 746:	00000097          	auipc	ra,0x0
 74a:	f56080e7          	jalr	-170(ra) # 69c <putc>
  while(--i >= 0)
 74e:	197d                	addi	s2,s2,-1
 750:	ff3918e3          	bne	s2,s3,740 <printint+0x82>
}
 754:	70e2                	ld	ra,56(sp)
 756:	7442                	ld	s0,48(sp)
 758:	74a2                	ld	s1,40(sp)
 75a:	7902                	ld	s2,32(sp)
 75c:	69e2                	ld	s3,24(sp)
 75e:	6121                	addi	sp,sp,64
 760:	8082                	ret
    x = -xx;
 762:	40b005bb          	negw	a1,a1
    neg = 1;
 766:	4885                	li	a7,1
    x = -xx;
 768:	bf85                	j	6d8 <printint+0x1a>

000000000000076a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 76a:	7119                	addi	sp,sp,-128
 76c:	fc86                	sd	ra,120(sp)
 76e:	f8a2                	sd	s0,112(sp)
 770:	f4a6                	sd	s1,104(sp)
 772:	f0ca                	sd	s2,96(sp)
 774:	ecce                	sd	s3,88(sp)
 776:	e8d2                	sd	s4,80(sp)
 778:	e4d6                	sd	s5,72(sp)
 77a:	e0da                	sd	s6,64(sp)
 77c:	fc5e                	sd	s7,56(sp)
 77e:	f862                	sd	s8,48(sp)
 780:	f466                	sd	s9,40(sp)
 782:	f06a                	sd	s10,32(sp)
 784:	ec6e                	sd	s11,24(sp)
 786:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 788:	0005c903          	lbu	s2,0(a1)
 78c:	18090f63          	beqz	s2,92a <vprintf+0x1c0>
 790:	8aaa                	mv	s5,a0
 792:	8b32                	mv	s6,a2
 794:	00158493          	addi	s1,a1,1
  state = 0;
 798:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 79a:	02500a13          	li	s4,37
 79e:	4c55                	li	s8,21
 7a0:	00000c97          	auipc	s9,0x0
 7a4:	3f8c8c93          	addi	s9,s9,1016 # b98 <malloc+0x16a>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 7a8:	02800d93          	li	s11,40
  putc(fd, 'x');
 7ac:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7ae:	00000b97          	auipc	s7,0x0
 7b2:	442b8b93          	addi	s7,s7,1090 # bf0 <digits>
 7b6:	a839                	j	7d4 <vprintf+0x6a>
        putc(fd, c);
 7b8:	85ca                	mv	a1,s2
 7ba:	8556                	mv	a0,s5
 7bc:	00000097          	auipc	ra,0x0
 7c0:	ee0080e7          	jalr	-288(ra) # 69c <putc>
 7c4:	a019                	j	7ca <vprintf+0x60>
    } else if(state == '%'){
 7c6:	01498d63          	beq	s3,s4,7e0 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 7ca:	0485                	addi	s1,s1,1
 7cc:	fff4c903          	lbu	s2,-1(s1)
 7d0:	14090d63          	beqz	s2,92a <vprintf+0x1c0>
    if(state == 0){
 7d4:	fe0999e3          	bnez	s3,7c6 <vprintf+0x5c>
      if(c == '%'){
 7d8:	ff4910e3          	bne	s2,s4,7b8 <vprintf+0x4e>
        state = '%';
 7dc:	89d2                	mv	s3,s4
 7de:	b7f5                	j	7ca <vprintf+0x60>
      if(c == 'd'){
 7e0:	11490c63          	beq	s2,s4,8f8 <vprintf+0x18e>
 7e4:	f9d9079b          	addiw	a5,s2,-99
 7e8:	0ff7f793          	zext.b	a5,a5
 7ec:	10fc6e63          	bltu	s8,a5,908 <vprintf+0x19e>
 7f0:	f9d9079b          	addiw	a5,s2,-99
 7f4:	0ff7f713          	zext.b	a4,a5
 7f8:	10ec6863          	bltu	s8,a4,908 <vprintf+0x19e>
 7fc:	00271793          	slli	a5,a4,0x2
 800:	97e6                	add	a5,a5,s9
 802:	439c                	lw	a5,0(a5)
 804:	97e6                	add	a5,a5,s9
 806:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 808:	008b0913          	addi	s2,s6,8
 80c:	4685                	li	a3,1
 80e:	4629                	li	a2,10
 810:	000b2583          	lw	a1,0(s6)
 814:	8556                	mv	a0,s5
 816:	00000097          	auipc	ra,0x0
 81a:	ea8080e7          	jalr	-344(ra) # 6be <printint>
 81e:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 820:	4981                	li	s3,0
 822:	b765                	j	7ca <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 824:	008b0913          	addi	s2,s6,8
 828:	4681                	li	a3,0
 82a:	4629                	li	a2,10
 82c:	000b2583          	lw	a1,0(s6)
 830:	8556                	mv	a0,s5
 832:	00000097          	auipc	ra,0x0
 836:	e8c080e7          	jalr	-372(ra) # 6be <printint>
 83a:	8b4a                	mv	s6,s2
      state = 0;
 83c:	4981                	li	s3,0
 83e:	b771                	j	7ca <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 840:	008b0913          	addi	s2,s6,8
 844:	4681                	li	a3,0
 846:	866a                	mv	a2,s10
 848:	000b2583          	lw	a1,0(s6)
 84c:	8556                	mv	a0,s5
 84e:	00000097          	auipc	ra,0x0
 852:	e70080e7          	jalr	-400(ra) # 6be <printint>
 856:	8b4a                	mv	s6,s2
      state = 0;
 858:	4981                	li	s3,0
 85a:	bf85                	j	7ca <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 85c:	008b0793          	addi	a5,s6,8
 860:	f8f43423          	sd	a5,-120(s0)
 864:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 868:	03000593          	li	a1,48
 86c:	8556                	mv	a0,s5
 86e:	00000097          	auipc	ra,0x0
 872:	e2e080e7          	jalr	-466(ra) # 69c <putc>
  putc(fd, 'x');
 876:	07800593          	li	a1,120
 87a:	8556                	mv	a0,s5
 87c:	00000097          	auipc	ra,0x0
 880:	e20080e7          	jalr	-480(ra) # 69c <putc>
 884:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 886:	03c9d793          	srli	a5,s3,0x3c
 88a:	97de                	add	a5,a5,s7
 88c:	0007c583          	lbu	a1,0(a5)
 890:	8556                	mv	a0,s5
 892:	00000097          	auipc	ra,0x0
 896:	e0a080e7          	jalr	-502(ra) # 69c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 89a:	0992                	slli	s3,s3,0x4
 89c:	397d                	addiw	s2,s2,-1
 89e:	fe0914e3          	bnez	s2,886 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 8a2:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 8a6:	4981                	li	s3,0
 8a8:	b70d                	j	7ca <vprintf+0x60>
        s = va_arg(ap, char*);
 8aa:	008b0913          	addi	s2,s6,8
 8ae:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 8b2:	02098163          	beqz	s3,8d4 <vprintf+0x16a>
        while(*s != 0){
 8b6:	0009c583          	lbu	a1,0(s3)
 8ba:	c5ad                	beqz	a1,924 <vprintf+0x1ba>
          putc(fd, *s);
 8bc:	8556                	mv	a0,s5
 8be:	00000097          	auipc	ra,0x0
 8c2:	dde080e7          	jalr	-546(ra) # 69c <putc>
          s++;
 8c6:	0985                	addi	s3,s3,1
        while(*s != 0){
 8c8:	0009c583          	lbu	a1,0(s3)
 8cc:	f9e5                	bnez	a1,8bc <vprintf+0x152>
        s = va_arg(ap, char*);
 8ce:	8b4a                	mv	s6,s2
      state = 0;
 8d0:	4981                	li	s3,0
 8d2:	bde5                	j	7ca <vprintf+0x60>
          s = "(null)";
 8d4:	00000997          	auipc	s3,0x0
 8d8:	2bc98993          	addi	s3,s3,700 # b90 <malloc+0x162>
        while(*s != 0){
 8dc:	85ee                	mv	a1,s11
 8de:	bff9                	j	8bc <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 8e0:	008b0913          	addi	s2,s6,8
 8e4:	000b4583          	lbu	a1,0(s6)
 8e8:	8556                	mv	a0,s5
 8ea:	00000097          	auipc	ra,0x0
 8ee:	db2080e7          	jalr	-590(ra) # 69c <putc>
 8f2:	8b4a                	mv	s6,s2
      state = 0;
 8f4:	4981                	li	s3,0
 8f6:	bdd1                	j	7ca <vprintf+0x60>
        putc(fd, c);
 8f8:	85d2                	mv	a1,s4
 8fa:	8556                	mv	a0,s5
 8fc:	00000097          	auipc	ra,0x0
 900:	da0080e7          	jalr	-608(ra) # 69c <putc>
      state = 0;
 904:	4981                	li	s3,0
 906:	b5d1                	j	7ca <vprintf+0x60>
        putc(fd, '%');
 908:	85d2                	mv	a1,s4
 90a:	8556                	mv	a0,s5
 90c:	00000097          	auipc	ra,0x0
 910:	d90080e7          	jalr	-624(ra) # 69c <putc>
        putc(fd, c);
 914:	85ca                	mv	a1,s2
 916:	8556                	mv	a0,s5
 918:	00000097          	auipc	ra,0x0
 91c:	d84080e7          	jalr	-636(ra) # 69c <putc>
      state = 0;
 920:	4981                	li	s3,0
 922:	b565                	j	7ca <vprintf+0x60>
        s = va_arg(ap, char*);
 924:	8b4a                	mv	s6,s2
      state = 0;
 926:	4981                	li	s3,0
 928:	b54d                	j	7ca <vprintf+0x60>
    }
  }
}
 92a:	70e6                	ld	ra,120(sp)
 92c:	7446                	ld	s0,112(sp)
 92e:	74a6                	ld	s1,104(sp)
 930:	7906                	ld	s2,96(sp)
 932:	69e6                	ld	s3,88(sp)
 934:	6a46                	ld	s4,80(sp)
 936:	6aa6                	ld	s5,72(sp)
 938:	6b06                	ld	s6,64(sp)
 93a:	7be2                	ld	s7,56(sp)
 93c:	7c42                	ld	s8,48(sp)
 93e:	7ca2                	ld	s9,40(sp)
 940:	7d02                	ld	s10,32(sp)
 942:	6de2                	ld	s11,24(sp)
 944:	6109                	addi	sp,sp,128
 946:	8082                	ret

0000000000000948 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 948:	715d                	addi	sp,sp,-80
 94a:	ec06                	sd	ra,24(sp)
 94c:	e822                	sd	s0,16(sp)
 94e:	1000                	addi	s0,sp,32
 950:	e010                	sd	a2,0(s0)
 952:	e414                	sd	a3,8(s0)
 954:	e818                	sd	a4,16(s0)
 956:	ec1c                	sd	a5,24(s0)
 958:	03043023          	sd	a6,32(s0)
 95c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 960:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 964:	8622                	mv	a2,s0
 966:	00000097          	auipc	ra,0x0
 96a:	e04080e7          	jalr	-508(ra) # 76a <vprintf>
}
 96e:	60e2                	ld	ra,24(sp)
 970:	6442                	ld	s0,16(sp)
 972:	6161                	addi	sp,sp,80
 974:	8082                	ret

0000000000000976 <printf>:

void
printf(const char *fmt, ...)
{
 976:	711d                	addi	sp,sp,-96
 978:	ec06                	sd	ra,24(sp)
 97a:	e822                	sd	s0,16(sp)
 97c:	1000                	addi	s0,sp,32
 97e:	e40c                	sd	a1,8(s0)
 980:	e810                	sd	a2,16(s0)
 982:	ec14                	sd	a3,24(s0)
 984:	f018                	sd	a4,32(s0)
 986:	f41c                	sd	a5,40(s0)
 988:	03043823          	sd	a6,48(s0)
 98c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 990:	00840613          	addi	a2,s0,8
 994:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 998:	85aa                	mv	a1,a0
 99a:	4505                	li	a0,1
 99c:	00000097          	auipc	ra,0x0
 9a0:	dce080e7          	jalr	-562(ra) # 76a <vprintf>
}
 9a4:	60e2                	ld	ra,24(sp)
 9a6:	6442                	ld	s0,16(sp)
 9a8:	6125                	addi	sp,sp,96
 9aa:	8082                	ret

00000000000009ac <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 9ac:	1141                	addi	sp,sp,-16
 9ae:	e422                	sd	s0,8(sp)
 9b0:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 9b2:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9b6:	00000797          	auipc	a5,0x0
 9ba:	25a7b783          	ld	a5,602(a5) # c10 <freep>
 9be:	a02d                	j	9e8 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 9c0:	4618                	lw	a4,8(a2)
 9c2:	9f2d                	addw	a4,a4,a1
 9c4:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 9c8:	6398                	ld	a4,0(a5)
 9ca:	6310                	ld	a2,0(a4)
 9cc:	a83d                	j	a0a <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 9ce:	ff852703          	lw	a4,-8(a0)
 9d2:	9f31                	addw	a4,a4,a2
 9d4:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 9d6:	ff053683          	ld	a3,-16(a0)
 9da:	a091                	j	a1e <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9dc:	6398                	ld	a4,0(a5)
 9de:	00e7e463          	bltu	a5,a4,9e6 <free+0x3a>
 9e2:	00e6ea63          	bltu	a3,a4,9f6 <free+0x4a>
{
 9e6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9e8:	fed7fae3          	bgeu	a5,a3,9dc <free+0x30>
 9ec:	6398                	ld	a4,0(a5)
 9ee:	00e6e463          	bltu	a3,a4,9f6 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9f2:	fee7eae3          	bltu	a5,a4,9e6 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 9f6:	ff852583          	lw	a1,-8(a0)
 9fa:	6390                	ld	a2,0(a5)
 9fc:	02059813          	slli	a6,a1,0x20
 a00:	01c85713          	srli	a4,a6,0x1c
 a04:	9736                	add	a4,a4,a3
 a06:	fae60de3          	beq	a2,a4,9c0 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 a0a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 a0e:	4790                	lw	a2,8(a5)
 a10:	02061593          	slli	a1,a2,0x20
 a14:	01c5d713          	srli	a4,a1,0x1c
 a18:	973e                	add	a4,a4,a5
 a1a:	fae68ae3          	beq	a3,a4,9ce <free+0x22>
    p->s.ptr = bp->s.ptr;
 a1e:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 a20:	00000717          	auipc	a4,0x0
 a24:	1ef73823          	sd	a5,496(a4) # c10 <freep>
}
 a28:	6422                	ld	s0,8(sp)
 a2a:	0141                	addi	sp,sp,16
 a2c:	8082                	ret

0000000000000a2e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 a2e:	7139                	addi	sp,sp,-64
 a30:	fc06                	sd	ra,56(sp)
 a32:	f822                	sd	s0,48(sp)
 a34:	f426                	sd	s1,40(sp)
 a36:	f04a                	sd	s2,32(sp)
 a38:	ec4e                	sd	s3,24(sp)
 a3a:	e852                	sd	s4,16(sp)
 a3c:	e456                	sd	s5,8(sp)
 a3e:	e05a                	sd	s6,0(sp)
 a40:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a42:	02051493          	slli	s1,a0,0x20
 a46:	9081                	srli	s1,s1,0x20
 a48:	04bd                	addi	s1,s1,15
 a4a:	8091                	srli	s1,s1,0x4
 a4c:	0014899b          	addiw	s3,s1,1
 a50:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a52:	00000517          	auipc	a0,0x0
 a56:	1be53503          	ld	a0,446(a0) # c10 <freep>
 a5a:	c515                	beqz	a0,a86 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a5c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a5e:	4798                	lw	a4,8(a5)
 a60:	02977f63          	bgeu	a4,s1,a9e <malloc+0x70>
 a64:	8a4e                	mv	s4,s3
 a66:	0009871b          	sext.w	a4,s3
 a6a:	6685                	lui	a3,0x1
 a6c:	00d77363          	bgeu	a4,a3,a72 <malloc+0x44>
 a70:	6a05                	lui	s4,0x1
 a72:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a76:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a7a:	00000917          	auipc	s2,0x0
 a7e:	19690913          	addi	s2,s2,406 # c10 <freep>
  if(p == (char*)-1)
 a82:	5afd                	li	s5,-1
 a84:	a895                	j	af8 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a86:	00000797          	auipc	a5,0x0
 a8a:	19278793          	addi	a5,a5,402 # c18 <base>
 a8e:	00000717          	auipc	a4,0x0
 a92:	18f73123          	sd	a5,386(a4) # c10 <freep>
 a96:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a98:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a9c:	b7e1                	j	a64 <malloc+0x36>
      if(p->s.size == nunits)
 a9e:	02e48c63          	beq	s1,a4,ad6 <malloc+0xa8>
        p->s.size -= nunits;
 aa2:	4137073b          	subw	a4,a4,s3
 aa6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 aa8:	02071693          	slli	a3,a4,0x20
 aac:	01c6d713          	srli	a4,a3,0x1c
 ab0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 ab2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 ab6:	00000717          	auipc	a4,0x0
 aba:	14a73d23          	sd	a0,346(a4) # c10 <freep>
      return (void*)(p + 1);
 abe:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 ac2:	70e2                	ld	ra,56(sp)
 ac4:	7442                	ld	s0,48(sp)
 ac6:	74a2                	ld	s1,40(sp)
 ac8:	7902                	ld	s2,32(sp)
 aca:	69e2                	ld	s3,24(sp)
 acc:	6a42                	ld	s4,16(sp)
 ace:	6aa2                	ld	s5,8(sp)
 ad0:	6b02                	ld	s6,0(sp)
 ad2:	6121                	addi	sp,sp,64
 ad4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 ad6:	6398                	ld	a4,0(a5)
 ad8:	e118                	sd	a4,0(a0)
 ada:	bff1                	j	ab6 <malloc+0x88>
  hp->s.size = nu;
 adc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 ae0:	0541                	addi	a0,a0,16
 ae2:	00000097          	auipc	ra,0x0
 ae6:	eca080e7          	jalr	-310(ra) # 9ac <free>
  return freep;
 aea:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 aee:	d971                	beqz	a0,ac2 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 af0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 af2:	4798                	lw	a4,8(a5)
 af4:	fa9775e3          	bgeu	a4,s1,a9e <malloc+0x70>
    if(p == freep)
 af8:	00093703          	ld	a4,0(s2)
 afc:	853e                	mv	a0,a5
 afe:	fef719e3          	bne	a4,a5,af0 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 b02:	8552                	mv	a0,s4
 b04:	00000097          	auipc	ra,0x0
 b08:	b40080e7          	jalr	-1216(ra) # 644 <sbrk>
  if(p == (char*)-1)
 b0c:	fd5518e3          	bne	a0,s5,adc <malloc+0xae>
        return 0;
 b10:	4501                	li	a0,0
 b12:	bf45                	j	ac2 <malloc+0x94>
