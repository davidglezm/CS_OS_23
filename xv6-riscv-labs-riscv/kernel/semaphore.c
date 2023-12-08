// HW6 - TASK 2
#include "types.h"
#include "riscv.h"
#include "param.h"
#include "defs.h"
#include "spinlock.h"

#define NSEM 100  // Maximum number of semaphores

struct semtab semtable;  // Declare a semaphore table

// Initialize the semaphore table
void seminit(void)
{
    initlock(&semtable.lock, "semtable");  // Initialize the lock for the semaphore table
    for (int i = 0; i < NSEM; i++)
        initlock(&semtable.sem[i].lock, "sem");  // Initialize the lock for each semaphore
};

// Allocate a semaphore
int semalloc(void){
    acquire(&semtable.lock);  // Acquire the lock for the semaphore table
    for (int i = 0; i < NSEM; i++){
        if(!semtable.sem[i].valid){
            semtable.sem[i].valid = 1;  // Mark the semaphore as valid (in use)
            release(&semtable.lock);    // Release the lock for the semaphore table
            return i;  // Return the index of the allocated semaphore
        }
    }
    release(&semtable.lock);  // Release the lock if no semaphore is available
    return -1;  // Return -1 if no semaphore is available
};

// Deallocate a semaphore
void semdealloc(int index){
    acquire(&semtable.sem[index].lock);  // Acquire the lock for the specified semaphore
    if(index > -1 && index < NSEM){
        semtable.sem[index].valid = 0;  // Invalidate the semaphore
    }
    release(&semtable.sem[index].lock);  // Release the lock for the semaphore
};
