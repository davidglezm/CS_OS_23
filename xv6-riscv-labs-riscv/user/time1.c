#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(2, "Usage: time1 command [args...]\n");
        exit(1);
    }

    // Timer starts
    int start_time = uptime();

    // Fork child process
    int pid = fork();
    if (pid < 0) {
        fprintf(2, "Fork failed\n");
        exit(1);
    } else if (pid == 0) {
        // Child process
        exec(argv[1], argv + 1);
        // If exec() fails -> exit
        fprintf(2, "exec failed\n");
        exit(1);
    } else {
        // Parent process
        int status;
        wait(&status);

        // Timer ends
        int end_time = uptime();

        // Elapsed time
        int elapsed_time = end_time - start_time;
        printf("Time: %d ticks\n", elapsed_time);
        printf("elapsed time: %d ticks\n", elapsed_time);
    }

    exit(0);
}