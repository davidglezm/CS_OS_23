#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    return -1;
  return(procinfo(addr));
}

// HW 4 - Task 1
// system call that allows user to query total free memory
uint64
sys_freepmem(void){
  int res = freepmem();
  return res;
}

// HW 4 - Task 2
// system call to allocate VIRTUAL memory on the disk
uint64
sys_sbrk(void){
  // Declare variables to store the heap sizes(curr_size, new_size) 
  // and the change needed(increment)
  int curr_size;
  int new_size;
  int increment;

  // Retrieve the first system call argument, which is the number 
  // of bytes to increase the heap by, and store it in 'increment'
  if(argint(0, &increment) < 0){
    return -1;
  }

  // Get the current size of the process's heap from its process structure.]
  curr_size = myproc()->sz;

  // Calculate the new size of the heap by adding 'increment' to the current size
  new_size = curr_size + increment;

  // Check if the new size is below a memory safety threshold ('TRAPFRAME')
  // This is to ensure the heap does not overlap with the trap frame
  if(new_size < TRAPFRAME){
    // If the new size is valid, update the process's heap size to -> new_size
    myproc()->sz = new_size;
    
    // Return the old heap end address before the increment
    return curr_size;
  }

  // If the new size is not valid or exceeds the memory safety threshold
  return -1;
}
// REMOVE -> NEW IMPLEMENTATION(LINE 123)
// uint64
// sys_sbrk(void)
// {
//   int addr;
//   int n;

//   if(argint(0, &n) < 0)
//     return -1;
//   addr = myproc()->sz;
//   if(growproc(n) < 0)
//     return -1;
//   return addr;
// }

// HW6 - TASK 3
int sys_sem_init(void) {
    uint64 s;
    int index, value, pshared;

    // Retrieve semaphore pointer, pshared flag, and initial value from syscall arguments
    // Return error if any syscall argument retrieval fails or pshared is zero
    if (argaddr(0, &s) < 0 || argint(1, &pshared) < 0 || argint(2, &value) < 0 || pshared == 0) {
        return -1;
    }

    // Allocate a new semaphore and check for allocation success
    index = semalloc();
    if (index < 0) {
        return -1;
    }

    // Set the semaphore's initial value
    semtable.sem[index].count = value;

    // Copy the semaphore index back to the user space and return success or error
    return copyout(myproc()->pagetable, s, (char*)&index, sizeof(index)) < 0 ? -1 : 0;
}

int sys_sem_destroy(void) {
    uint64 s;
    int addr;

    // Retrieve semaphore pointer from syscall argument
    if (argaddr(0, &s) < 0) {
        return -1;
    }

    // Copy semaphore address from user space; return error if copyin fails
    if (copyin(myproc()->pagetable, (char*)&addr, s, sizeof(int)) < 0) {
        return -1;
    }

    // Acquire lock, deallocate the semaphore, and release lock
    acquire(&semtable.lock);
    semdealloc(addr);
    release(&semtable.lock);

    return 0;
}

int sys_sem_wait(void) {
    uint64 s;
    int addr;

    // Retrieve semaphore pointer from syscall argument and copy address from user space
    if (argaddr(0, &s) < 0 || copyin(myproc()->pagetable, (char*)&addr, s, sizeof(int)) < 0) {
        return -1;
    }

    // Acquire lock and wait if semaphore count is zero, then decrement count
    acquire(&semtable.sem[addr].lock);
    while (semtable.sem[addr].count == 0) {
        sleep((void*)&semtable.sem[addr], &semtable.sem[addr].lock);
    }
    semtable.sem[addr].count--;
    release(&semtable.sem[addr].lock);

    return 0;
}

int sys_sem_post(void) {
    uint64 s;
    int addr;

    // Retrieve semaphore pointer from syscall argument and copy address from user space
    if (argaddr(0, &s) < 0 || copyin(myproc()->pagetable, (char*)&addr, s, sizeof(int)) < 0) {
        return -1;
    }

    // Acquire lock, increment semaphore count, signal any waiting process, and release lock
    acquire(&semtable.sem[addr].lock);
    semtable.sem[addr].count++;
    wakeup((void*)&semtable.sem[addr]);
    release(&semtable.sem[addr].lock);

    return 0;
}

