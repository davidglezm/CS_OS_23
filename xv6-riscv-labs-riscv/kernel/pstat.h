struct pstat {
	int pid;
	enum procstate state;
	uint64 size;
	int ppid;
	char name[16];
};
struct rusage{
	uint cputime;
};



