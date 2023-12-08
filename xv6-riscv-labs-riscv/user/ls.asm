
user/_ls:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	30a080e7          	jalr	778(ra) # 31a <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	2de080e7          	jalr	734(ra) # 31a <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	2bc080e7          	jalr	700(ra) # 31a <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	b2298993          	addi	s3,s3,-1246 # b88 <buf.0>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	416080e7          	jalr	1046(ra) # 48c <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	29a080e7          	jalr	666(ra) # 31a <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	28c080e7          	jalr	652(ra) # 31a <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	29c080e7          	jalr	668(ra) # 344 <memset>
  return buf;
  b0:	84ce                	mv	s1,s3
  b2:	bf69                	j	4c <fmtname+0x4c>

00000000000000b4 <ls>:

void
ls(char *path)
{
  b4:	d9010113          	addi	sp,sp,-624
  b8:	26113423          	sd	ra,616(sp)
  bc:	26813023          	sd	s0,608(sp)
  c0:	24913c23          	sd	s1,600(sp)
  c4:	25213823          	sd	s2,592(sp)
  c8:	25313423          	sd	s3,584(sp)
  cc:	25413023          	sd	s4,576(sp)
  d0:	23513c23          	sd	s5,568(sp)
  d4:	1c80                	addi	s0,sp,624
  d6:	892a                	mv	s2,a0
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
  d8:	4581                	li	a1,0
  da:	00000097          	auipc	ra,0x0
  de:	4a4080e7          	jalr	1188(ra) # 57e <open>
  e2:	06054f63          	bltz	a0,160 <ls+0xac>
  e6:	84aa                	mv	s1,a0
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  e8:	d9840593          	addi	a1,s0,-616
  ec:	00000097          	auipc	ra,0x0
  f0:	4aa080e7          	jalr	1194(ra) # 596 <fstat>
  f4:	08054163          	bltz	a0,176 <ls+0xc2>
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }

  switch(st.type){
  f8:	da041783          	lh	a5,-608(s0)
  fc:	0007869b          	sext.w	a3,a5
 100:	4705                	li	a4,1
 102:	08e68a63          	beq	a3,a4,196 <ls+0xe2>
 106:	4709                	li	a4,2
 108:	02e69663          	bne	a3,a4,134 <ls+0x80>
  case T_FILE:
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 10c:	854a                	mv	a0,s2
 10e:	00000097          	auipc	ra,0x0
 112:	ef2080e7          	jalr	-270(ra) # 0 <fmtname>
 116:	85aa                	mv	a1,a0
 118:	da843703          	ld	a4,-600(s0)
 11c:	d9c42683          	lw	a3,-612(s0)
 120:	da041603          	lh	a2,-608(s0)
 124:	00001517          	auipc	a0,0x1
 128:	9a450513          	addi	a0,a0,-1628 # ac8 <malloc+0x118>
 12c:	00000097          	auipc	ra,0x0
 130:	7cc080e7          	jalr	1996(ra) # 8f8 <printf>
      }
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 134:	8526                	mv	a0,s1
 136:	00000097          	auipc	ra,0x0
 13a:	430080e7          	jalr	1072(ra) # 566 <close>
}
 13e:	26813083          	ld	ra,616(sp)
 142:	26013403          	ld	s0,608(sp)
 146:	25813483          	ld	s1,600(sp)
 14a:	25013903          	ld	s2,592(sp)
 14e:	24813983          	ld	s3,584(sp)
 152:	24013a03          	ld	s4,576(sp)
 156:	23813a83          	ld	s5,568(sp)
 15a:	27010113          	addi	sp,sp,624
 15e:	8082                	ret
    fprintf(2, "ls: cannot open %s\n", path);
 160:	864a                	mv	a2,s2
 162:	00001597          	auipc	a1,0x1
 166:	93658593          	addi	a1,a1,-1738 # a98 <malloc+0xe8>
 16a:	4509                	li	a0,2
 16c:	00000097          	auipc	ra,0x0
 170:	75e080e7          	jalr	1886(ra) # 8ca <fprintf>
    return;
 174:	b7e9                	j	13e <ls+0x8a>
    fprintf(2, "ls: cannot stat %s\n", path);
 176:	864a                	mv	a2,s2
 178:	00001597          	auipc	a1,0x1
 17c:	93858593          	addi	a1,a1,-1736 # ab0 <malloc+0x100>
 180:	4509                	li	a0,2
 182:	00000097          	auipc	ra,0x0
 186:	748080e7          	jalr	1864(ra) # 8ca <fprintf>
    close(fd);
 18a:	8526                	mv	a0,s1
 18c:	00000097          	auipc	ra,0x0
 190:	3da080e7          	jalr	986(ra) # 566 <close>
    return;
 194:	b76d                	j	13e <ls+0x8a>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 196:	854a                	mv	a0,s2
 198:	00000097          	auipc	ra,0x0
 19c:	182080e7          	jalr	386(ra) # 31a <strlen>
 1a0:	2541                	addiw	a0,a0,16
 1a2:	20000793          	li	a5,512
 1a6:	00a7fb63          	bgeu	a5,a0,1bc <ls+0x108>
      printf("ls: path too long\n");
 1aa:	00001517          	auipc	a0,0x1
 1ae:	92e50513          	addi	a0,a0,-1746 # ad8 <malloc+0x128>
 1b2:	00000097          	auipc	ra,0x0
 1b6:	746080e7          	jalr	1862(ra) # 8f8 <printf>
      break;
 1ba:	bfad                	j	134 <ls+0x80>
    strcpy(buf, path);
 1bc:	85ca                	mv	a1,s2
 1be:	dc040513          	addi	a0,s0,-576
 1c2:	00000097          	auipc	ra,0x0
 1c6:	110080e7          	jalr	272(ra) # 2d2 <strcpy>
    p = buf+strlen(buf);
 1ca:	dc040513          	addi	a0,s0,-576
 1ce:	00000097          	auipc	ra,0x0
 1d2:	14c080e7          	jalr	332(ra) # 31a <strlen>
 1d6:	1502                	slli	a0,a0,0x20
 1d8:	9101                	srli	a0,a0,0x20
 1da:	dc040793          	addi	a5,s0,-576
 1de:	00a78933          	add	s2,a5,a0
    *p++ = '/';
 1e2:	00190993          	addi	s3,s2,1
 1e6:	02f00793          	li	a5,47
 1ea:	00f90023          	sb	a5,0(s2)
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 1ee:	00001a17          	auipc	s4,0x1
 1f2:	902a0a13          	addi	s4,s4,-1790 # af0 <malloc+0x140>
        printf("ls: cannot stat %s\n", buf);
 1f6:	00001a97          	auipc	s5,0x1
 1fa:	8baa8a93          	addi	s5,s5,-1862 # ab0 <malloc+0x100>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 1fe:	a801                	j	20e <ls+0x15a>
        printf("ls: cannot stat %s\n", buf);
 200:	dc040593          	addi	a1,s0,-576
 204:	8556                	mv	a0,s5
 206:	00000097          	auipc	ra,0x0
 20a:	6f2080e7          	jalr	1778(ra) # 8f8 <printf>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 20e:	4641                	li	a2,16
 210:	db040593          	addi	a1,s0,-592
 214:	8526                	mv	a0,s1
 216:	00000097          	auipc	ra,0x0
 21a:	340080e7          	jalr	832(ra) # 556 <read>
 21e:	47c1                	li	a5,16
 220:	f0f51ae3          	bne	a0,a5,134 <ls+0x80>
      if(de.inum == 0)
 224:	db045783          	lhu	a5,-592(s0)
 228:	d3fd                	beqz	a5,20e <ls+0x15a>
      memmove(p, de.name, DIRSIZ);
 22a:	4639                	li	a2,14
 22c:	db240593          	addi	a1,s0,-590
 230:	854e                	mv	a0,s3
 232:	00000097          	auipc	ra,0x0
 236:	25a080e7          	jalr	602(ra) # 48c <memmove>
      p[DIRSIZ] = 0;
 23a:	000907a3          	sb	zero,15(s2)
      if(stat(buf, &st) < 0){
 23e:	d9840593          	addi	a1,s0,-616
 242:	dc040513          	addi	a0,s0,-576
 246:	00000097          	auipc	ra,0x0
 24a:	1b8080e7          	jalr	440(ra) # 3fe <stat>
 24e:	fa0549e3          	bltz	a0,200 <ls+0x14c>
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 252:	dc040513          	addi	a0,s0,-576
 256:	00000097          	auipc	ra,0x0
 25a:	daa080e7          	jalr	-598(ra) # 0 <fmtname>
 25e:	85aa                	mv	a1,a0
 260:	da843703          	ld	a4,-600(s0)
 264:	d9c42683          	lw	a3,-612(s0)
 268:	da041603          	lh	a2,-608(s0)
 26c:	8552                	mv	a0,s4
 26e:	00000097          	auipc	ra,0x0
 272:	68a080e7          	jalr	1674(ra) # 8f8 <printf>
 276:	bf61                	j	20e <ls+0x15a>

0000000000000278 <main>:

int
main(int argc, char *argv[])
{
 278:	1101                	addi	sp,sp,-32
 27a:	ec06                	sd	ra,24(sp)
 27c:	e822                	sd	s0,16(sp)
 27e:	e426                	sd	s1,8(sp)
 280:	e04a                	sd	s2,0(sp)
 282:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
 284:	4785                	li	a5,1
 286:	02a7d963          	bge	a5,a0,2b8 <main+0x40>
 28a:	00858493          	addi	s1,a1,8
 28e:	ffe5091b          	addiw	s2,a0,-2
 292:	02091793          	slli	a5,s2,0x20
 296:	01d7d913          	srli	s2,a5,0x1d
 29a:	05c1                	addi	a1,a1,16
 29c:	992e                	add	s2,s2,a1
    ls(".");
    exit(0);
  }
  for(i=1; i<argc; i++)
    ls(argv[i]);
 29e:	6088                	ld	a0,0(s1)
 2a0:	00000097          	auipc	ra,0x0
 2a4:	e14080e7          	jalr	-492(ra) # b4 <ls>
  for(i=1; i<argc; i++)
 2a8:	04a1                	addi	s1,s1,8
 2aa:	ff249ae3          	bne	s1,s2,29e <main+0x26>
  exit(0);
 2ae:	4501                	li	a0,0
 2b0:	00000097          	auipc	ra,0x0
 2b4:	28e080e7          	jalr	654(ra) # 53e <exit>
    ls(".");
 2b8:	00001517          	auipc	a0,0x1
 2bc:	84850513          	addi	a0,a0,-1976 # b00 <malloc+0x150>
 2c0:	00000097          	auipc	ra,0x0
 2c4:	df4080e7          	jalr	-524(ra) # b4 <ls>
    exit(0);
 2c8:	4501                	li	a0,0
 2ca:	00000097          	auipc	ra,0x0
 2ce:	274080e7          	jalr	628(ra) # 53e <exit>

00000000000002d2 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2d2:	1141                	addi	sp,sp,-16
 2d4:	e422                	sd	s0,8(sp)
 2d6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2d8:	87aa                	mv	a5,a0
 2da:	0585                	addi	a1,a1,1
 2dc:	0785                	addi	a5,a5,1
 2de:	fff5c703          	lbu	a4,-1(a1)
 2e2:	fee78fa3          	sb	a4,-1(a5)
 2e6:	fb75                	bnez	a4,2da <strcpy+0x8>
    ;
  return os;
}
 2e8:	6422                	ld	s0,8(sp)
 2ea:	0141                	addi	sp,sp,16
 2ec:	8082                	ret

00000000000002ee <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2f4:	00054783          	lbu	a5,0(a0)
 2f8:	cb91                	beqz	a5,30c <strcmp+0x1e>
 2fa:	0005c703          	lbu	a4,0(a1)
 2fe:	00f71763          	bne	a4,a5,30c <strcmp+0x1e>
    p++, q++;
 302:	0505                	addi	a0,a0,1
 304:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 306:	00054783          	lbu	a5,0(a0)
 30a:	fbe5                	bnez	a5,2fa <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 30c:	0005c503          	lbu	a0,0(a1)
}
 310:	40a7853b          	subw	a0,a5,a0
 314:	6422                	ld	s0,8(sp)
 316:	0141                	addi	sp,sp,16
 318:	8082                	ret

000000000000031a <strlen>:

uint
strlen(const char *s)
{
 31a:	1141                	addi	sp,sp,-16
 31c:	e422                	sd	s0,8(sp)
 31e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 320:	00054783          	lbu	a5,0(a0)
 324:	cf91                	beqz	a5,340 <strlen+0x26>
 326:	0505                	addi	a0,a0,1
 328:	87aa                	mv	a5,a0
 32a:	4685                	li	a3,1
 32c:	9e89                	subw	a3,a3,a0
 32e:	00f6853b          	addw	a0,a3,a5
 332:	0785                	addi	a5,a5,1
 334:	fff7c703          	lbu	a4,-1(a5)
 338:	fb7d                	bnez	a4,32e <strlen+0x14>
    ;
  return n;
}
 33a:	6422                	ld	s0,8(sp)
 33c:	0141                	addi	sp,sp,16
 33e:	8082                	ret
  for(n = 0; s[n]; n++)
 340:	4501                	li	a0,0
 342:	bfe5                	j	33a <strlen+0x20>

0000000000000344 <memset>:

void*
memset(void *dst, int c, uint n)
{
 344:	1141                	addi	sp,sp,-16
 346:	e422                	sd	s0,8(sp)
 348:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 34a:	ca19                	beqz	a2,360 <memset+0x1c>
 34c:	87aa                	mv	a5,a0
 34e:	1602                	slli	a2,a2,0x20
 350:	9201                	srli	a2,a2,0x20
 352:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 356:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 35a:	0785                	addi	a5,a5,1
 35c:	fee79de3          	bne	a5,a4,356 <memset+0x12>
  }
  return dst;
}
 360:	6422                	ld	s0,8(sp)
 362:	0141                	addi	sp,sp,16
 364:	8082                	ret

0000000000000366 <strchr>:

char*
strchr(const char *s, char c)
{
 366:	1141                	addi	sp,sp,-16
 368:	e422                	sd	s0,8(sp)
 36a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 36c:	00054783          	lbu	a5,0(a0)
 370:	cb99                	beqz	a5,386 <strchr+0x20>
    if(*s == c)
 372:	00f58763          	beq	a1,a5,380 <strchr+0x1a>
  for(; *s; s++)
 376:	0505                	addi	a0,a0,1
 378:	00054783          	lbu	a5,0(a0)
 37c:	fbfd                	bnez	a5,372 <strchr+0xc>
      return (char*)s;
  return 0;
 37e:	4501                	li	a0,0
}
 380:	6422                	ld	s0,8(sp)
 382:	0141                	addi	sp,sp,16
 384:	8082                	ret
  return 0;
 386:	4501                	li	a0,0
 388:	bfe5                	j	380 <strchr+0x1a>

000000000000038a <gets>:

char*
gets(char *buf, int max)
{
 38a:	711d                	addi	sp,sp,-96
 38c:	ec86                	sd	ra,88(sp)
 38e:	e8a2                	sd	s0,80(sp)
 390:	e4a6                	sd	s1,72(sp)
 392:	e0ca                	sd	s2,64(sp)
 394:	fc4e                	sd	s3,56(sp)
 396:	f852                	sd	s4,48(sp)
 398:	f456                	sd	s5,40(sp)
 39a:	f05a                	sd	s6,32(sp)
 39c:	ec5e                	sd	s7,24(sp)
 39e:	1080                	addi	s0,sp,96
 3a0:	8baa                	mv	s7,a0
 3a2:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3a4:	892a                	mv	s2,a0
 3a6:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3a8:	4aa9                	li	s5,10
 3aa:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3ac:	89a6                	mv	s3,s1
 3ae:	2485                	addiw	s1,s1,1
 3b0:	0344d863          	bge	s1,s4,3e0 <gets+0x56>
    cc = read(0, &c, 1);
 3b4:	4605                	li	a2,1
 3b6:	faf40593          	addi	a1,s0,-81
 3ba:	4501                	li	a0,0
 3bc:	00000097          	auipc	ra,0x0
 3c0:	19a080e7          	jalr	410(ra) # 556 <read>
    if(cc < 1)
 3c4:	00a05e63          	blez	a0,3e0 <gets+0x56>
    buf[i++] = c;
 3c8:	faf44783          	lbu	a5,-81(s0)
 3cc:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3d0:	01578763          	beq	a5,s5,3de <gets+0x54>
 3d4:	0905                	addi	s2,s2,1
 3d6:	fd679be3          	bne	a5,s6,3ac <gets+0x22>
  for(i=0; i+1 < max; ){
 3da:	89a6                	mv	s3,s1
 3dc:	a011                	j	3e0 <gets+0x56>
 3de:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3e0:	99de                	add	s3,s3,s7
 3e2:	00098023          	sb	zero,0(s3)
  return buf;
}
 3e6:	855e                	mv	a0,s7
 3e8:	60e6                	ld	ra,88(sp)
 3ea:	6446                	ld	s0,80(sp)
 3ec:	64a6                	ld	s1,72(sp)
 3ee:	6906                	ld	s2,64(sp)
 3f0:	79e2                	ld	s3,56(sp)
 3f2:	7a42                	ld	s4,48(sp)
 3f4:	7aa2                	ld	s5,40(sp)
 3f6:	7b02                	ld	s6,32(sp)
 3f8:	6be2                	ld	s7,24(sp)
 3fa:	6125                	addi	sp,sp,96
 3fc:	8082                	ret

00000000000003fe <stat>:

int
stat(const char *n, struct stat *st)
{
 3fe:	1101                	addi	sp,sp,-32
 400:	ec06                	sd	ra,24(sp)
 402:	e822                	sd	s0,16(sp)
 404:	e426                	sd	s1,8(sp)
 406:	e04a                	sd	s2,0(sp)
 408:	1000                	addi	s0,sp,32
 40a:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 40c:	4581                	li	a1,0
 40e:	00000097          	auipc	ra,0x0
 412:	170080e7          	jalr	368(ra) # 57e <open>
  if(fd < 0)
 416:	02054563          	bltz	a0,440 <stat+0x42>
 41a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 41c:	85ca                	mv	a1,s2
 41e:	00000097          	auipc	ra,0x0
 422:	178080e7          	jalr	376(ra) # 596 <fstat>
 426:	892a                	mv	s2,a0
  close(fd);
 428:	8526                	mv	a0,s1
 42a:	00000097          	auipc	ra,0x0
 42e:	13c080e7          	jalr	316(ra) # 566 <close>
  return r;
}
 432:	854a                	mv	a0,s2
 434:	60e2                	ld	ra,24(sp)
 436:	6442                	ld	s0,16(sp)
 438:	64a2                	ld	s1,8(sp)
 43a:	6902                	ld	s2,0(sp)
 43c:	6105                	addi	sp,sp,32
 43e:	8082                	ret
    return -1;
 440:	597d                	li	s2,-1
 442:	bfc5                	j	432 <stat+0x34>

0000000000000444 <atoi>:

int
atoi(const char *s)
{
 444:	1141                	addi	sp,sp,-16
 446:	e422                	sd	s0,8(sp)
 448:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 44a:	00054683          	lbu	a3,0(a0)
 44e:	fd06879b          	addiw	a5,a3,-48
 452:	0ff7f793          	zext.b	a5,a5
 456:	4625                	li	a2,9
 458:	02f66863          	bltu	a2,a5,488 <atoi+0x44>
 45c:	872a                	mv	a4,a0
  n = 0;
 45e:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 460:	0705                	addi	a4,a4,1
 462:	0025179b          	slliw	a5,a0,0x2
 466:	9fa9                	addw	a5,a5,a0
 468:	0017979b          	slliw	a5,a5,0x1
 46c:	9fb5                	addw	a5,a5,a3
 46e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 472:	00074683          	lbu	a3,0(a4)
 476:	fd06879b          	addiw	a5,a3,-48
 47a:	0ff7f793          	zext.b	a5,a5
 47e:	fef671e3          	bgeu	a2,a5,460 <atoi+0x1c>
  return n;
}
 482:	6422                	ld	s0,8(sp)
 484:	0141                	addi	sp,sp,16
 486:	8082                	ret
  n = 0;
 488:	4501                	li	a0,0
 48a:	bfe5                	j	482 <atoi+0x3e>

000000000000048c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 48c:	1141                	addi	sp,sp,-16
 48e:	e422                	sd	s0,8(sp)
 490:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 492:	02b57463          	bgeu	a0,a1,4ba <memmove+0x2e>
    while(n-- > 0)
 496:	00c05f63          	blez	a2,4b4 <memmove+0x28>
 49a:	1602                	slli	a2,a2,0x20
 49c:	9201                	srli	a2,a2,0x20
 49e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4a2:	872a                	mv	a4,a0
      *dst++ = *src++;
 4a4:	0585                	addi	a1,a1,1
 4a6:	0705                	addi	a4,a4,1
 4a8:	fff5c683          	lbu	a3,-1(a1)
 4ac:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4b0:	fee79ae3          	bne	a5,a4,4a4 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4b4:	6422                	ld	s0,8(sp)
 4b6:	0141                	addi	sp,sp,16
 4b8:	8082                	ret
    dst += n;
 4ba:	00c50733          	add	a4,a0,a2
    src += n;
 4be:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4c0:	fec05ae3          	blez	a2,4b4 <memmove+0x28>
 4c4:	fff6079b          	addiw	a5,a2,-1
 4c8:	1782                	slli	a5,a5,0x20
 4ca:	9381                	srli	a5,a5,0x20
 4cc:	fff7c793          	not	a5,a5
 4d0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4d2:	15fd                	addi	a1,a1,-1
 4d4:	177d                	addi	a4,a4,-1
 4d6:	0005c683          	lbu	a3,0(a1)
 4da:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4de:	fee79ae3          	bne	a5,a4,4d2 <memmove+0x46>
 4e2:	bfc9                	j	4b4 <memmove+0x28>

00000000000004e4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4e4:	1141                	addi	sp,sp,-16
 4e6:	e422                	sd	s0,8(sp)
 4e8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4ea:	ca05                	beqz	a2,51a <memcmp+0x36>
 4ec:	fff6069b          	addiw	a3,a2,-1
 4f0:	1682                	slli	a3,a3,0x20
 4f2:	9281                	srli	a3,a3,0x20
 4f4:	0685                	addi	a3,a3,1
 4f6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4f8:	00054783          	lbu	a5,0(a0)
 4fc:	0005c703          	lbu	a4,0(a1)
 500:	00e79863          	bne	a5,a4,510 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 504:	0505                	addi	a0,a0,1
    p2++;
 506:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 508:	fed518e3          	bne	a0,a3,4f8 <memcmp+0x14>
  }
  return 0;
 50c:	4501                	li	a0,0
 50e:	a019                	j	514 <memcmp+0x30>
      return *p1 - *p2;
 510:	40e7853b          	subw	a0,a5,a4
}
 514:	6422                	ld	s0,8(sp)
 516:	0141                	addi	sp,sp,16
 518:	8082                	ret
  return 0;
 51a:	4501                	li	a0,0
 51c:	bfe5                	j	514 <memcmp+0x30>

000000000000051e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 51e:	1141                	addi	sp,sp,-16
 520:	e406                	sd	ra,8(sp)
 522:	e022                	sd	s0,0(sp)
 524:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 526:	00000097          	auipc	ra,0x0
 52a:	f66080e7          	jalr	-154(ra) # 48c <memmove>
}
 52e:	60a2                	ld	ra,8(sp)
 530:	6402                	ld	s0,0(sp)
 532:	0141                	addi	sp,sp,16
 534:	8082                	ret

0000000000000536 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 536:	4885                	li	a7,1
 ecall
 538:	00000073          	ecall
 ret
 53c:	8082                	ret

000000000000053e <exit>:
.global exit
exit:
 li a7, SYS_exit
 53e:	4889                	li	a7,2
 ecall
 540:	00000073          	ecall
 ret
 544:	8082                	ret

0000000000000546 <wait>:
.global wait
wait:
 li a7, SYS_wait
 546:	488d                	li	a7,3
 ecall
 548:	00000073          	ecall
 ret
 54c:	8082                	ret

000000000000054e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 54e:	4891                	li	a7,4
 ecall
 550:	00000073          	ecall
 ret
 554:	8082                	ret

0000000000000556 <read>:
.global read
read:
 li a7, SYS_read
 556:	4895                	li	a7,5
 ecall
 558:	00000073          	ecall
 ret
 55c:	8082                	ret

000000000000055e <write>:
.global write
write:
 li a7, SYS_write
 55e:	48c1                	li	a7,16
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <close>:
.global close
close:
 li a7, SYS_close
 566:	48d5                	li	a7,21
 ecall
 568:	00000073          	ecall
 ret
 56c:	8082                	ret

000000000000056e <kill>:
.global kill
kill:
 li a7, SYS_kill
 56e:	4899                	li	a7,6
 ecall
 570:	00000073          	ecall
 ret
 574:	8082                	ret

0000000000000576 <exec>:
.global exec
exec:
 li a7, SYS_exec
 576:	489d                	li	a7,7
 ecall
 578:	00000073          	ecall
 ret
 57c:	8082                	ret

000000000000057e <open>:
.global open
open:
 li a7, SYS_open
 57e:	48bd                	li	a7,15
 ecall
 580:	00000073          	ecall
 ret
 584:	8082                	ret

0000000000000586 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 586:	48c5                	li	a7,17
 ecall
 588:	00000073          	ecall
 ret
 58c:	8082                	ret

000000000000058e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 58e:	48c9                	li	a7,18
 ecall
 590:	00000073          	ecall
 ret
 594:	8082                	ret

0000000000000596 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 596:	48a1                	li	a7,8
 ecall
 598:	00000073          	ecall
 ret
 59c:	8082                	ret

000000000000059e <link>:
.global link
link:
 li a7, SYS_link
 59e:	48cd                	li	a7,19
 ecall
 5a0:	00000073          	ecall
 ret
 5a4:	8082                	ret

00000000000005a6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5a6:	48d1                	li	a7,20
 ecall
 5a8:	00000073          	ecall
 ret
 5ac:	8082                	ret

00000000000005ae <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5ae:	48a5                	li	a7,9
 ecall
 5b0:	00000073          	ecall
 ret
 5b4:	8082                	ret

00000000000005b6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5b6:	48a9                	li	a7,10
 ecall
 5b8:	00000073          	ecall
 ret
 5bc:	8082                	ret

00000000000005be <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5be:	48ad                	li	a7,11
 ecall
 5c0:	00000073          	ecall
 ret
 5c4:	8082                	ret

00000000000005c6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5c6:	48b1                	li	a7,12
 ecall
 5c8:	00000073          	ecall
 ret
 5cc:	8082                	ret

00000000000005ce <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5ce:	48b5                	li	a7,13
 ecall
 5d0:	00000073          	ecall
 ret
 5d4:	8082                	ret

00000000000005d6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5d6:	48b9                	li	a7,14
 ecall
 5d8:	00000073          	ecall
 ret
 5dc:	8082                	ret

00000000000005de <getprocs>:
.global getprocs
getprocs:
 li a7, SYS_getprocs
 5de:	48d9                	li	a7,22
 ecall
 5e0:	00000073          	ecall
 ret
 5e4:	8082                	ret

00000000000005e6 <freepmem>:
.global freepmem
freepmem:
 li a7, SYS_freepmem
 5e6:	48dd                	li	a7,23
 ecall
 5e8:	00000073          	ecall
 ret
 5ec:	8082                	ret

00000000000005ee <mmap>:
.global mmap
mmap:
 li a7, SYS_mmap
 5ee:	48e1                	li	a7,24
 ecall
 5f0:	00000073          	ecall
 ret
 5f4:	8082                	ret

00000000000005f6 <munmap>:
.global munmap
munmap:
 li a7, SYS_munmap
 5f6:	48e5                	li	a7,25
 ecall
 5f8:	00000073          	ecall
 ret
 5fc:	8082                	ret

00000000000005fe <sem_init>:
.global sem_init
sem_init:
 li a7, SYS_sem_init
 5fe:	48e9                	li	a7,26
 ecall
 600:	00000073          	ecall
 ret
 604:	8082                	ret

0000000000000606 <sem_destroy>:
.global sem_destroy
sem_destroy:
 li a7, SYS_sem_destroy
 606:	48ed                	li	a7,27
 ecall
 608:	00000073          	ecall
 ret
 60c:	8082                	ret

000000000000060e <sem_wait>:
.global sem_wait
sem_wait:
 li a7, SYS_sem_wait
 60e:	48f1                	li	a7,28
 ecall
 610:	00000073          	ecall
 ret
 614:	8082                	ret

0000000000000616 <sem_post>:
.global sem_post
sem_post:
 li a7, SYS_sem_post
 616:	48f5                	li	a7,29
 ecall
 618:	00000073          	ecall
 ret
 61c:	8082                	ret

000000000000061e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 61e:	1101                	addi	sp,sp,-32
 620:	ec06                	sd	ra,24(sp)
 622:	e822                	sd	s0,16(sp)
 624:	1000                	addi	s0,sp,32
 626:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 62a:	4605                	li	a2,1
 62c:	fef40593          	addi	a1,s0,-17
 630:	00000097          	auipc	ra,0x0
 634:	f2e080e7          	jalr	-210(ra) # 55e <write>
}
 638:	60e2                	ld	ra,24(sp)
 63a:	6442                	ld	s0,16(sp)
 63c:	6105                	addi	sp,sp,32
 63e:	8082                	ret

0000000000000640 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 640:	7139                	addi	sp,sp,-64
 642:	fc06                	sd	ra,56(sp)
 644:	f822                	sd	s0,48(sp)
 646:	f426                	sd	s1,40(sp)
 648:	f04a                	sd	s2,32(sp)
 64a:	ec4e                	sd	s3,24(sp)
 64c:	0080                	addi	s0,sp,64
 64e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 650:	c299                	beqz	a3,656 <printint+0x16>
 652:	0805c963          	bltz	a1,6e4 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 656:	2581                	sext.w	a1,a1
  neg = 0;
 658:	4881                	li	a7,0
 65a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 65e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 660:	2601                	sext.w	a2,a2
 662:	00000517          	auipc	a0,0x0
 666:	50650513          	addi	a0,a0,1286 # b68 <digits>
 66a:	883a                	mv	a6,a4
 66c:	2705                	addiw	a4,a4,1
 66e:	02c5f7bb          	remuw	a5,a1,a2
 672:	1782                	slli	a5,a5,0x20
 674:	9381                	srli	a5,a5,0x20
 676:	97aa                	add	a5,a5,a0
 678:	0007c783          	lbu	a5,0(a5)
 67c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 680:	0005879b          	sext.w	a5,a1
 684:	02c5d5bb          	divuw	a1,a1,a2
 688:	0685                	addi	a3,a3,1
 68a:	fec7f0e3          	bgeu	a5,a2,66a <printint+0x2a>
  if(neg)
 68e:	00088c63          	beqz	a7,6a6 <printint+0x66>
    buf[i++] = '-';
 692:	fd070793          	addi	a5,a4,-48
 696:	00878733          	add	a4,a5,s0
 69a:	02d00793          	li	a5,45
 69e:	fef70823          	sb	a5,-16(a4)
 6a2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6a6:	02e05863          	blez	a4,6d6 <printint+0x96>
 6aa:	fc040793          	addi	a5,s0,-64
 6ae:	00e78933          	add	s2,a5,a4
 6b2:	fff78993          	addi	s3,a5,-1
 6b6:	99ba                	add	s3,s3,a4
 6b8:	377d                	addiw	a4,a4,-1
 6ba:	1702                	slli	a4,a4,0x20
 6bc:	9301                	srli	a4,a4,0x20
 6be:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6c2:	fff94583          	lbu	a1,-1(s2)
 6c6:	8526                	mv	a0,s1
 6c8:	00000097          	auipc	ra,0x0
 6cc:	f56080e7          	jalr	-170(ra) # 61e <putc>
  while(--i >= 0)
 6d0:	197d                	addi	s2,s2,-1
 6d2:	ff3918e3          	bne	s2,s3,6c2 <printint+0x82>
}
 6d6:	70e2                	ld	ra,56(sp)
 6d8:	7442                	ld	s0,48(sp)
 6da:	74a2                	ld	s1,40(sp)
 6dc:	7902                	ld	s2,32(sp)
 6de:	69e2                	ld	s3,24(sp)
 6e0:	6121                	addi	sp,sp,64
 6e2:	8082                	ret
    x = -xx;
 6e4:	40b005bb          	negw	a1,a1
    neg = 1;
 6e8:	4885                	li	a7,1
    x = -xx;
 6ea:	bf85                	j	65a <printint+0x1a>

00000000000006ec <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6ec:	7119                	addi	sp,sp,-128
 6ee:	fc86                	sd	ra,120(sp)
 6f0:	f8a2                	sd	s0,112(sp)
 6f2:	f4a6                	sd	s1,104(sp)
 6f4:	f0ca                	sd	s2,96(sp)
 6f6:	ecce                	sd	s3,88(sp)
 6f8:	e8d2                	sd	s4,80(sp)
 6fa:	e4d6                	sd	s5,72(sp)
 6fc:	e0da                	sd	s6,64(sp)
 6fe:	fc5e                	sd	s7,56(sp)
 700:	f862                	sd	s8,48(sp)
 702:	f466                	sd	s9,40(sp)
 704:	f06a                	sd	s10,32(sp)
 706:	ec6e                	sd	s11,24(sp)
 708:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 70a:	0005c903          	lbu	s2,0(a1)
 70e:	18090f63          	beqz	s2,8ac <vprintf+0x1c0>
 712:	8aaa                	mv	s5,a0
 714:	8b32                	mv	s6,a2
 716:	00158493          	addi	s1,a1,1
  state = 0;
 71a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 71c:	02500a13          	li	s4,37
 720:	4c55                	li	s8,21
 722:	00000c97          	auipc	s9,0x0
 726:	3eec8c93          	addi	s9,s9,1006 # b10 <malloc+0x160>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 72a:	02800d93          	li	s11,40
  putc(fd, 'x');
 72e:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 730:	00000b97          	auipc	s7,0x0
 734:	438b8b93          	addi	s7,s7,1080 # b68 <digits>
 738:	a839                	j	756 <vprintf+0x6a>
        putc(fd, c);
 73a:	85ca                	mv	a1,s2
 73c:	8556                	mv	a0,s5
 73e:	00000097          	auipc	ra,0x0
 742:	ee0080e7          	jalr	-288(ra) # 61e <putc>
 746:	a019                	j	74c <vprintf+0x60>
    } else if(state == '%'){
 748:	01498d63          	beq	s3,s4,762 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 74c:	0485                	addi	s1,s1,1
 74e:	fff4c903          	lbu	s2,-1(s1)
 752:	14090d63          	beqz	s2,8ac <vprintf+0x1c0>
    if(state == 0){
 756:	fe0999e3          	bnez	s3,748 <vprintf+0x5c>
      if(c == '%'){
 75a:	ff4910e3          	bne	s2,s4,73a <vprintf+0x4e>
        state = '%';
 75e:	89d2                	mv	s3,s4
 760:	b7f5                	j	74c <vprintf+0x60>
      if(c == 'd'){
 762:	11490c63          	beq	s2,s4,87a <vprintf+0x18e>
 766:	f9d9079b          	addiw	a5,s2,-99
 76a:	0ff7f793          	zext.b	a5,a5
 76e:	10fc6e63          	bltu	s8,a5,88a <vprintf+0x19e>
 772:	f9d9079b          	addiw	a5,s2,-99
 776:	0ff7f713          	zext.b	a4,a5
 77a:	10ec6863          	bltu	s8,a4,88a <vprintf+0x19e>
 77e:	00271793          	slli	a5,a4,0x2
 782:	97e6                	add	a5,a5,s9
 784:	439c                	lw	a5,0(a5)
 786:	97e6                	add	a5,a5,s9
 788:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 78a:	008b0913          	addi	s2,s6,8
 78e:	4685                	li	a3,1
 790:	4629                	li	a2,10
 792:	000b2583          	lw	a1,0(s6)
 796:	8556                	mv	a0,s5
 798:	00000097          	auipc	ra,0x0
 79c:	ea8080e7          	jalr	-344(ra) # 640 <printint>
 7a0:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 7a2:	4981                	li	s3,0
 7a4:	b765                	j	74c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7a6:	008b0913          	addi	s2,s6,8
 7aa:	4681                	li	a3,0
 7ac:	4629                	li	a2,10
 7ae:	000b2583          	lw	a1,0(s6)
 7b2:	8556                	mv	a0,s5
 7b4:	00000097          	auipc	ra,0x0
 7b8:	e8c080e7          	jalr	-372(ra) # 640 <printint>
 7bc:	8b4a                	mv	s6,s2
      state = 0;
 7be:	4981                	li	s3,0
 7c0:	b771                	j	74c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7c2:	008b0913          	addi	s2,s6,8
 7c6:	4681                	li	a3,0
 7c8:	866a                	mv	a2,s10
 7ca:	000b2583          	lw	a1,0(s6)
 7ce:	8556                	mv	a0,s5
 7d0:	00000097          	auipc	ra,0x0
 7d4:	e70080e7          	jalr	-400(ra) # 640 <printint>
 7d8:	8b4a                	mv	s6,s2
      state = 0;
 7da:	4981                	li	s3,0
 7dc:	bf85                	j	74c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7de:	008b0793          	addi	a5,s6,8
 7e2:	f8f43423          	sd	a5,-120(s0)
 7e6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7ea:	03000593          	li	a1,48
 7ee:	8556                	mv	a0,s5
 7f0:	00000097          	auipc	ra,0x0
 7f4:	e2e080e7          	jalr	-466(ra) # 61e <putc>
  putc(fd, 'x');
 7f8:	07800593          	li	a1,120
 7fc:	8556                	mv	a0,s5
 7fe:	00000097          	auipc	ra,0x0
 802:	e20080e7          	jalr	-480(ra) # 61e <putc>
 806:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 808:	03c9d793          	srli	a5,s3,0x3c
 80c:	97de                	add	a5,a5,s7
 80e:	0007c583          	lbu	a1,0(a5)
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	e0a080e7          	jalr	-502(ra) # 61e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 81c:	0992                	slli	s3,s3,0x4
 81e:	397d                	addiw	s2,s2,-1
 820:	fe0914e3          	bnez	s2,808 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 824:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 828:	4981                	li	s3,0
 82a:	b70d                	j	74c <vprintf+0x60>
        s = va_arg(ap, char*);
 82c:	008b0913          	addi	s2,s6,8
 830:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 834:	02098163          	beqz	s3,856 <vprintf+0x16a>
        while(*s != 0){
 838:	0009c583          	lbu	a1,0(s3)
 83c:	c5ad                	beqz	a1,8a6 <vprintf+0x1ba>
          putc(fd, *s);
 83e:	8556                	mv	a0,s5
 840:	00000097          	auipc	ra,0x0
 844:	dde080e7          	jalr	-546(ra) # 61e <putc>
          s++;
 848:	0985                	addi	s3,s3,1
        while(*s != 0){
 84a:	0009c583          	lbu	a1,0(s3)
 84e:	f9e5                	bnez	a1,83e <vprintf+0x152>
        s = va_arg(ap, char*);
 850:	8b4a                	mv	s6,s2
      state = 0;
 852:	4981                	li	s3,0
 854:	bde5                	j	74c <vprintf+0x60>
          s = "(null)";
 856:	00000997          	auipc	s3,0x0
 85a:	2b298993          	addi	s3,s3,690 # b08 <malloc+0x158>
        while(*s != 0){
 85e:	85ee                	mv	a1,s11
 860:	bff9                	j	83e <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 862:	008b0913          	addi	s2,s6,8
 866:	000b4583          	lbu	a1,0(s6)
 86a:	8556                	mv	a0,s5
 86c:	00000097          	auipc	ra,0x0
 870:	db2080e7          	jalr	-590(ra) # 61e <putc>
 874:	8b4a                	mv	s6,s2
      state = 0;
 876:	4981                	li	s3,0
 878:	bdd1                	j	74c <vprintf+0x60>
        putc(fd, c);
 87a:	85d2                	mv	a1,s4
 87c:	8556                	mv	a0,s5
 87e:	00000097          	auipc	ra,0x0
 882:	da0080e7          	jalr	-608(ra) # 61e <putc>
      state = 0;
 886:	4981                	li	s3,0
 888:	b5d1                	j	74c <vprintf+0x60>
        putc(fd, '%');
 88a:	85d2                	mv	a1,s4
 88c:	8556                	mv	a0,s5
 88e:	00000097          	auipc	ra,0x0
 892:	d90080e7          	jalr	-624(ra) # 61e <putc>
        putc(fd, c);
 896:	85ca                	mv	a1,s2
 898:	8556                	mv	a0,s5
 89a:	00000097          	auipc	ra,0x0
 89e:	d84080e7          	jalr	-636(ra) # 61e <putc>
      state = 0;
 8a2:	4981                	li	s3,0
 8a4:	b565                	j	74c <vprintf+0x60>
        s = va_arg(ap, char*);
 8a6:	8b4a                	mv	s6,s2
      state = 0;
 8a8:	4981                	li	s3,0
 8aa:	b54d                	j	74c <vprintf+0x60>
    }
  }
}
 8ac:	70e6                	ld	ra,120(sp)
 8ae:	7446                	ld	s0,112(sp)
 8b0:	74a6                	ld	s1,104(sp)
 8b2:	7906                	ld	s2,96(sp)
 8b4:	69e6                	ld	s3,88(sp)
 8b6:	6a46                	ld	s4,80(sp)
 8b8:	6aa6                	ld	s5,72(sp)
 8ba:	6b06                	ld	s6,64(sp)
 8bc:	7be2                	ld	s7,56(sp)
 8be:	7c42                	ld	s8,48(sp)
 8c0:	7ca2                	ld	s9,40(sp)
 8c2:	7d02                	ld	s10,32(sp)
 8c4:	6de2                	ld	s11,24(sp)
 8c6:	6109                	addi	sp,sp,128
 8c8:	8082                	ret

00000000000008ca <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8ca:	715d                	addi	sp,sp,-80
 8cc:	ec06                	sd	ra,24(sp)
 8ce:	e822                	sd	s0,16(sp)
 8d0:	1000                	addi	s0,sp,32
 8d2:	e010                	sd	a2,0(s0)
 8d4:	e414                	sd	a3,8(s0)
 8d6:	e818                	sd	a4,16(s0)
 8d8:	ec1c                	sd	a5,24(s0)
 8da:	03043023          	sd	a6,32(s0)
 8de:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8e2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8e6:	8622                	mv	a2,s0
 8e8:	00000097          	auipc	ra,0x0
 8ec:	e04080e7          	jalr	-508(ra) # 6ec <vprintf>
}
 8f0:	60e2                	ld	ra,24(sp)
 8f2:	6442                	ld	s0,16(sp)
 8f4:	6161                	addi	sp,sp,80
 8f6:	8082                	ret

00000000000008f8 <printf>:

void
printf(const char *fmt, ...)
{
 8f8:	711d                	addi	sp,sp,-96
 8fa:	ec06                	sd	ra,24(sp)
 8fc:	e822                	sd	s0,16(sp)
 8fe:	1000                	addi	s0,sp,32
 900:	e40c                	sd	a1,8(s0)
 902:	e810                	sd	a2,16(s0)
 904:	ec14                	sd	a3,24(s0)
 906:	f018                	sd	a4,32(s0)
 908:	f41c                	sd	a5,40(s0)
 90a:	03043823          	sd	a6,48(s0)
 90e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 912:	00840613          	addi	a2,s0,8
 916:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 91a:	85aa                	mv	a1,a0
 91c:	4505                	li	a0,1
 91e:	00000097          	auipc	ra,0x0
 922:	dce080e7          	jalr	-562(ra) # 6ec <vprintf>
}
 926:	60e2                	ld	ra,24(sp)
 928:	6442                	ld	s0,16(sp)
 92a:	6125                	addi	sp,sp,96
 92c:	8082                	ret

000000000000092e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 92e:	1141                	addi	sp,sp,-16
 930:	e422                	sd	s0,8(sp)
 932:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 934:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 938:	00000797          	auipc	a5,0x0
 93c:	2487b783          	ld	a5,584(a5) # b80 <freep>
 940:	a02d                	j	96a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 942:	4618                	lw	a4,8(a2)
 944:	9f2d                	addw	a4,a4,a1
 946:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 94a:	6398                	ld	a4,0(a5)
 94c:	6310                	ld	a2,0(a4)
 94e:	a83d                	j	98c <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 950:	ff852703          	lw	a4,-8(a0)
 954:	9f31                	addw	a4,a4,a2
 956:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 958:	ff053683          	ld	a3,-16(a0)
 95c:	a091                	j	9a0 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 95e:	6398                	ld	a4,0(a5)
 960:	00e7e463          	bltu	a5,a4,968 <free+0x3a>
 964:	00e6ea63          	bltu	a3,a4,978 <free+0x4a>
{
 968:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 96a:	fed7fae3          	bgeu	a5,a3,95e <free+0x30>
 96e:	6398                	ld	a4,0(a5)
 970:	00e6e463          	bltu	a3,a4,978 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 974:	fee7eae3          	bltu	a5,a4,968 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 978:	ff852583          	lw	a1,-8(a0)
 97c:	6390                	ld	a2,0(a5)
 97e:	02059813          	slli	a6,a1,0x20
 982:	01c85713          	srli	a4,a6,0x1c
 986:	9736                	add	a4,a4,a3
 988:	fae60de3          	beq	a2,a4,942 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 98c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 990:	4790                	lw	a2,8(a5)
 992:	02061593          	slli	a1,a2,0x20
 996:	01c5d713          	srli	a4,a1,0x1c
 99a:	973e                	add	a4,a4,a5
 99c:	fae68ae3          	beq	a3,a4,950 <free+0x22>
    p->s.ptr = bp->s.ptr;
 9a0:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 9a2:	00000717          	auipc	a4,0x0
 9a6:	1cf73f23          	sd	a5,478(a4) # b80 <freep>
}
 9aa:	6422                	ld	s0,8(sp)
 9ac:	0141                	addi	sp,sp,16
 9ae:	8082                	ret

00000000000009b0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9b0:	7139                	addi	sp,sp,-64
 9b2:	fc06                	sd	ra,56(sp)
 9b4:	f822                	sd	s0,48(sp)
 9b6:	f426                	sd	s1,40(sp)
 9b8:	f04a                	sd	s2,32(sp)
 9ba:	ec4e                	sd	s3,24(sp)
 9bc:	e852                	sd	s4,16(sp)
 9be:	e456                	sd	s5,8(sp)
 9c0:	e05a                	sd	s6,0(sp)
 9c2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9c4:	02051493          	slli	s1,a0,0x20
 9c8:	9081                	srli	s1,s1,0x20
 9ca:	04bd                	addi	s1,s1,15
 9cc:	8091                	srli	s1,s1,0x4
 9ce:	0014899b          	addiw	s3,s1,1
 9d2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9d4:	00000517          	auipc	a0,0x0
 9d8:	1ac53503          	ld	a0,428(a0) # b80 <freep>
 9dc:	c515                	beqz	a0,a08 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9de:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9e0:	4798                	lw	a4,8(a5)
 9e2:	02977f63          	bgeu	a4,s1,a20 <malloc+0x70>
 9e6:	8a4e                	mv	s4,s3
 9e8:	0009871b          	sext.w	a4,s3
 9ec:	6685                	lui	a3,0x1
 9ee:	00d77363          	bgeu	a4,a3,9f4 <malloc+0x44>
 9f2:	6a05                	lui	s4,0x1
 9f4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9f8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9fc:	00000917          	auipc	s2,0x0
 a00:	18490913          	addi	s2,s2,388 # b80 <freep>
  if(p == (char*)-1)
 a04:	5afd                	li	s5,-1
 a06:	a895                	j	a7a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a08:	00000797          	auipc	a5,0x0
 a0c:	19078793          	addi	a5,a5,400 # b98 <base>
 a10:	00000717          	auipc	a4,0x0
 a14:	16f73823          	sd	a5,368(a4) # b80 <freep>
 a18:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a1a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a1e:	b7e1                	j	9e6 <malloc+0x36>
      if(p->s.size == nunits)
 a20:	02e48c63          	beq	s1,a4,a58 <malloc+0xa8>
        p->s.size -= nunits;
 a24:	4137073b          	subw	a4,a4,s3
 a28:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a2a:	02071693          	slli	a3,a4,0x20
 a2e:	01c6d713          	srli	a4,a3,0x1c
 a32:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a34:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a38:	00000717          	auipc	a4,0x0
 a3c:	14a73423          	sd	a0,328(a4) # b80 <freep>
      return (void*)(p + 1);
 a40:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a44:	70e2                	ld	ra,56(sp)
 a46:	7442                	ld	s0,48(sp)
 a48:	74a2                	ld	s1,40(sp)
 a4a:	7902                	ld	s2,32(sp)
 a4c:	69e2                	ld	s3,24(sp)
 a4e:	6a42                	ld	s4,16(sp)
 a50:	6aa2                	ld	s5,8(sp)
 a52:	6b02                	ld	s6,0(sp)
 a54:	6121                	addi	sp,sp,64
 a56:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a58:	6398                	ld	a4,0(a5)
 a5a:	e118                	sd	a4,0(a0)
 a5c:	bff1                	j	a38 <malloc+0x88>
  hp->s.size = nu;
 a5e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a62:	0541                	addi	a0,a0,16
 a64:	00000097          	auipc	ra,0x0
 a68:	eca080e7          	jalr	-310(ra) # 92e <free>
  return freep;
 a6c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a70:	d971                	beqz	a0,a44 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a72:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a74:	4798                	lw	a4,8(a5)
 a76:	fa9775e3          	bgeu	a4,s1,a20 <malloc+0x70>
    if(p == freep)
 a7a:	00093703          	ld	a4,0(s2)
 a7e:	853e                	mv	a0,a5
 a80:	fef719e3          	bne	a4,a5,a72 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 a84:	8552                	mv	a0,s4
 a86:	00000097          	auipc	ra,0x0
 a8a:	b40080e7          	jalr	-1216(ra) # 5c6 <sbrk>
  if(p == (char*)-1)
 a8e:	fd5518e3          	bne	a0,s5,a5e <malloc+0xae>
        return 0;
 a92:	4501                	li	a0,0
 a94:	bf45                	j	a44 <malloc+0x94>
