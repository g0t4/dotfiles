#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>

// PURPOSE - testing overhead of shelling out... shaves ~2ms off off popen approach, of course this replaces the curreent process so it's not what I would be doing in a full c impl...

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <security-command-args>\n", argv[0]);
        return 1;
    }

    // Prepare arguments for execvp
    char **exec_args = malloc((argc + 1) * sizeof(char *));
    if (!exec_args) {
        perror("malloc");
        return 1;
    }

    exec_args[0] = "security"; // First argument is the command
    for (int i = 1; i < argc; i++) {
        exec_args[i] = argv[i]; // Copy arguments
    }
    exec_args[argc] = NULL; // Null-terminate the argument list

    // Fork a child process
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        free(exec_args);
        return 1;
    }

    if (pid == 0) {
        // In the child process: execute the command
        execvp("security", exec_args);
        // If execvp returns, it failed
        perror("execvp");
        free(exec_args);
        exit(1);
    }

    // In the parent process: wait for the child to complete
    int status;
    if (waitpid(pid, &status, 0) == -1) {
        perror("waitpid");
        free(exec_args);
        return 1;
    }

    // Check the exit status of the child process
    if (WIFEXITED(status)) {
        printf("Command exited with status: %d\n", WEXITSTATUS(status));
    } else if (WIFSIGNALED(status)) {
        printf("Command terminated by signal: %d\n", WTERMSIG(status));
    }

    free(exec_args);
    return 0;
}
