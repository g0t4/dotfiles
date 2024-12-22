#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <security-command-args>\n", argv[0]);
        return 1;
    }

    // Construct the command string
    size_t cmd_size = 9; // "security " + null terminator
    for (int i = 1; i < argc; i++) {
        cmd_size += strlen(argv[i]) + 1; // Add space and argument length
    }

    char *command = malloc(cmd_size);
    if (!command) {
        perror("malloc");
        return 1;
    }

    snprintf(command, cmd_size, "security");
    for (int i = 1; i < argc; i++) {
        strncat(command, " ", cmd_size - strlen(command) - 1);
        strncat(command, argv[i], cmd_size - strlen(command) - 1);
    }

    // Run the command and print its output
    FILE *fp = popen(command, "r");
    if (!fp) {
        perror("popen");
        free(command);
        return 1;
    }

    char buffer[128];
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        printf("%s", buffer);
    }

    int status = pclose(fp);
    if (status == -1) {
        perror("pclose");
    } else {
        printf("\nCommand exited with status: %d\n", WEXITSTATUS(status));
    }

    free(command);
    return 0;
}
