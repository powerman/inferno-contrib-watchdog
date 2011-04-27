Watchdog: module
{
	PATH: con "/opt/powerman/watchdog/dis/cmd/watchdog.dis";

	init:	fn(nil: ref Draw->Context, argv: list of string);

	me:	fn(): int;
	pid:	fn(watchpid: int): int;
	cmd:	fn(argv: list of string): int;
	stop:	fn(watchdog: int);
};
