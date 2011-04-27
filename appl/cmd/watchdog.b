implement Watchdog;

include "sys.m";
	sys: Sys;
	sprint: import sys;
include "draw.m";
include "opt/powerman/logger/module/logger.m";
	logger: Logger;
	log, ERR, WARN, NOTICE, INFO, DEBUG: import logger;
include "wait.m";
	wait: Wait;
include "env.m";
	env: Env;
include "sh.m";
	sh: Sh;
include "arg.m";
include "../../module/watchdog.m";


loadmodules()
{
	if(sys != nil)
		return;
	sys		=  load Sys Sys->PATH;
	logger		=  checkload(load Logger Logger->PATH, "Logger");
	logger->init();
	wait		=  checkload(load Wait Wait->PATH, "Wait");
	wait->init();
	env		=  checkload(load Env Env->PATH, "Env");
	sh		=  checkload(load Sh Sh->PATH, "Sh");
	logger->modname("Watchdog");
}

init(nil: ref Draw->Context, argv: list of string)
{
	loadmodules();
	arg		:= checkload(load Arg Arg->PATH, "Arg");
	arg->init(argv);
	logger->modname(nil);
	logger->progname(arg->progname());

	watchpid := 0;
	arg->setusage(sprint("%s [-v] [-p pid | cmd args]", arg->progname()));
	while((p := arg->opt()) != 0)
		case p {
		'v' =>	logger->verbose++;
		'p' =>	watchpid = int arg->earg();
			if(watchpid <= 0)
				arg->usage();
		* =>	arg->usage();
		}
	argv = arg->argv();
	if(!(watchpid != 0 ^ len argv != 0))
		arg->usage();

	if(watchpid)
		pid(watchpid);
	else
		cmd(argv);
}

me(): int
{
	loadmodules();

	return pid(sys->pctl(0, nil));
}

pid(watchpid: int): int
{
	loadmodules();

	fname := "/prog/"+string watchpid+"/wait";
	fd := sys->open(fname, Sys->OREAD);
	if(fd == nil)
		fail(sprint("open %s: %r", fname));

	pidc := chan of int;
	spawn watchdog_pid(watchpid, fd, getcmd(), pidc);
	return <-pidc;
}

cmd(argv: list of string): int
{
	loadmodules();

	c := chan of int;
	spawn run(argv, c);
	watchpid := <-c;

	pidc := chan of int;
	spawn watchdog_cmd(watchpid, c, getcmd(), pidc);
	return <-pidc;
}

stop(watchdog: int)
{
	pidctl(watchdog, "kill");
}

###

getcmd(): string
{
	cmd := env->getenv("watchdog");
	if(cmd == nil)
		cmd = "shutdown -h";
	return cmd;
}

run(argv: list of string, c: chan of int)
{
	c <-= sys->pctl(0, nil);
	sh->run(nil, argv);
	c <-= 1;
}

watchdog_pid(watchpid: int, fd: ref Sys->FD, cmd: string, pidc: chan of int)
{
	pidc <-= sys->pctl(Sys->NEWPGRP, nil);
	buf := array[2*Sys->WAITLEN] of byte;
	for(;;){
		n := sys->read(fd, buf, len buf);
		if(n <= 0)
			break;
		(pid,nil,nil) := wait->parse(string buf[0:n]);
		if(pid == watchpid)
			break;
	}
	died(watchpid, cmd);
}

watchdog_cmd(watchpid: int, diedc: chan of int, cmd: string, pidc: chan of int)
{
	pidc <-= sys->pctl(Sys->NEWPGRP, nil);
	<-diedc;
	died(watchpid, cmd);
}

died(watchpid: int, cmd: string)
{
	log(INFO, sprint("pid %d died, executing: %s", watchpid, cmd));
	sh->system(nil, cmd);
}

###

fail(s: string)
{
	if(logger != nil)
		log(ERR, s);
	else
		sys->fprint(sys->fildes(2), "%s\n", s);
	raise "fail:"+s;
}

checkload[T](x: T, s: string): T
{
	if(x == nil)
		fail(sprint("load: %s: %r", s));
	return x;
}

pidctl(pid: int, s: string): int
{
	f := sprint("#p/%d/ctl", pid);
	fd := sys->open(f, Sys->OWRITE);
	if(fd == nil || sys->fprint(fd, "%s", s) < 0){
		log(DEBUG, sprint("pidctl(%d, %s): %r", pid, s));
		return 0;
	}
	return 1;
}

