/*
 * Dummy process used as a stand-in game executable for Discord's process scanner.
 *
 * Discord on Linux identifies games by the real executable path (/proc/<pid>/exe),
 * so this binary is copied to a file named after the game's executable and run.
 *
 * Usage: idle [pid] [ignored args...]
 *   With a pid, exits as soon as that process exits (even if it is SIGKILLed).
 *   Without one, waits until killed.
 */
#include <poll.h>
#include <stdlib.h>
#include <sys/pidfd.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (argc < 2)
        for (;;)
            pause();
    int fd = pidfd_open(atoi(argv[1]), 0);
    if (fd < 0)
        return 1;
    struct pollfd p = { .fd = fd, .events = POLLIN };
    poll(&p, 1, -1);
    return 0;
}
