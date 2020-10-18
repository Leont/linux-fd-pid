#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <signal.h>
#include <linux/wait.h>
#include <asm-generic/unistd.h>

#define die_sys(format) Perl_croak(aTHX_ format, strerror(errno))

static SV* S_io_fdopen(pTHX_ int fd, const char* classname) {
	PerlIO* pio = PerlIO_fdopen(fd, "r");
	GV* gv = newGVgen(classname);
	SV* ret = newRV_noinc((SV*)gv);
	IO* io = GvIOn(gv);
	HV* stash = gv_stashpv(classname, FALSE);
	IoTYPE(io) = '<';
	IoIFP(io) = pio;
	IoOFP(io) = pio;
	sv_bless(ret, stash);
	return ret;
}
#define io_fdopen(fd, classname) S_io_fdopen(aTHX_ fd, classname)

#define get_fd(self) PerlIO_fileno(IoOFP(sv_2io(SvRV(self))))

MODULE = Linux::FD::Pid				PACKAGE = Linux::FD::Pid

PROTOTYPES: DISABLED

SV*
new(classname, pid)
	const char* classname;
	int pid;
	PREINIT:
	int pidfd;
	CODE:
	pidfd = syscall(__NR_pidfd_open, pid, 0);
	if (pidfd < 0)
		die_sys("Couldn't open pidfd: %s");
	RETVAL = io_fdopen(pidfd, classname);
	OUTPUT:
		RETVAL

void
send(file_handle, signal)
	SV* file_handle;
	int signal;
	PREINIT:
		int fd, ret;
	CODE:
		fd = get_fd(file_handle);
		ret = syscall(__NR_pidfd_send_signal, fd, signal, NULL, 0);
		if (ret < 0)
			die_sys("Couldn't send signal: %s");

int
wait(file_handle, flags = WEXITED)
	SV* file_handle;
	int flags;
	PREINIT:
		int fd, wait_result;
		siginfo_t info;
	CODE:
		fd = get_fd(file_handle);
		wait_result = waitid(P_PIDFD, fd, &info, flags);
		if (wait_result != 0)
			die_sys("Can't wait pid: %s");
		RETVAL = info.si_status;
	OUTPUT:
		RETVAL
