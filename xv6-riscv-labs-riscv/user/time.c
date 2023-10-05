#include "kernel/types.h" 
#include "kernel/stat.h" 
#include "user/user.h" 
#include "kernel/param.h"
#include "kernel/pstat.h"
#include <stddef.h>

#define MAXARGS 16 
int main(int argc, char *argv[])
{ 
	int start, elapsed, rc;
	// char newargv[MAXARGS];
	struct rusage ru; 
	if(argc < 2){ 
		printf("Usage: time <comm> [args...]"); 
		exit(-1); 
	} 
	// for(i = 1; i < argc; i++){ 
	// 	newargv[i-1] = argv[i]; 
	// } 
	// newargv[argc-1] = 0; 
	start = uptime(); 
	rc = fork(); 
	if(rc == 0){ 
		exec(argv[1], argv); 
	} 
	wait2(0, &ru); 
	elapsed = uptime() - start; 
	printf("Elapsed Time: %d Ticks, CPU Time: %d Ticks, CPU Percentage: %d% \n", elapsed, ru.cputime, ru.cputime*100/elapsed); 
	exit(0); 
}