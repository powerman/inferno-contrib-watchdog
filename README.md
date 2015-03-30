Provide watchdog command and module for detecting crash of command/pid and executing some action (shutdown -h by default).

# Install #

```
cd $INFERNO_ROOT/opt
mkdir -p powerman
hg clone https://inferno-contrib-watchdog.googlecode.com/hg/ powerman/watchdog
```

After starting emu run /opt/setup.sh to install all /opt packages (you can download it from http://code.google.com/p/inferno-os/issues/detail?id=261).

## Dependencies ##

http://code.google.com/p/inferno-contrib-logger/

# Example #

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