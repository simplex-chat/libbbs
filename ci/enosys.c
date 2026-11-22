#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <sys/syscall.h>
#include <unistd.h>

long syscall(long number, ...) {
	va_list ap;
	va_start(ap, number);
	long a = va_arg(ap, long);
	long b = va_arg(ap, long);
	long c = va_arg(ap, long);
	long d = va_arg(ap, long);
	long e = va_arg(ap, long);
	long f = va_arg(ap, long);
	va_end(ap);
	if (number == SYS_getrandom) {
		fputs("enosys: getrandom\n", stderr);
		errno = ENOSYS;
		return -1;
	}
	long (*real)(long, ...) = (long (*)(long, ...)) dlsym(RTLD_NEXT, "syscall");
	return real(number, a, b, c, d, e, f);
}
