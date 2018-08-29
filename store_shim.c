#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int (*real_open)(const char *, int, ...);

void init() __attribute__((constructor)) {
  real_open = dlsym(RTLD_NEXT, "open");
}

#define NIX_STORE "/nix/store"

int open(const char *pathname, int flags, ...) {
  va_list args;
  va_start(args, flags);

  char *pathname_override = (char *)pathname;
  int mode = 0;

  if (strncmp(NIX_STORE, pathname, strlen(NIX_STORE)) == 0)
    asprintf(&pathname_override, "%s%s", getenv("BUNDLE_ROOT"), pathname);

  if (flags & O_CREAT)
    mode = va_arg(args, int);

  va_end(args);

  int ret = real_open(pathname_override, flags, mode);

  if (pathname_override != pathname)
    free(pathname_override);

  return ret;
}
