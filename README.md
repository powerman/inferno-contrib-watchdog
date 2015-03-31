# Description

Provide watchdog command and module for detecting crash of command/pid and
executing some action (shutdown -h by default).


# Install

Make directory with this app/module available in /opt/powerman/watchdog/, for ex.:

```
# git clone https://github.com/powerman/inferno-contrib-watchdog.git $INFERNO_ROOT/opt/powerman/watchdog
```

or in user home directory:

```
$ git clone https://github.com/powerman/inferno-contrib-watchdog.git $INFERNO_USER_HOME/opt/powerman/watchdog
$ emu
; bind opt /opt
```

If you want to run commands and read man pages without entering full path
to them (like `/opt/VENDOR/APP/dis/cmd/NAME`) you should also install and
use https://github.com/powerman/inferno-opt-setup 

## Dependencies

* https://github.com/powerman/inferno-contrib-logger


# Example

Shutdown emu when pid 1 exit:

```
; watchdog -p 1
```

Shutdown emu in 3 seconds:

```
; watchdog sleep 3
```

Output "task done" in 3 seconds:

```
; watchdog=echo task done
; watchdog sleep 3
```

Restart app if it crashes:

```
; watchdog=app
; watchdog app
```

Use as module to monitor background services:

```
include "opt/powerman/watchdog/module/watchdog.m";

init(nil: ref Draw->Context, argv: list of string)
{
        spawn service();
}

service()
{
        watchdog := load Watchdog Watchdog->PATH;

        sys->pctl(Sys->NEWPGRP, nil);
        exc->setexcmode(exc->NOTIFYLEADER);
        watchdog->me();

        …
}
```
