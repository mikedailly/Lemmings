..\snasm -map _LemmingsNext.asm _LemmingsNext.dat
if ERRORLEVEL 1 goto doexit


rem simple 48k model
..\CSpect.exe -debug -60 -w3 -tv -map=_LemmingsNext.dat.map -zxnext -mmc=.\ _LemmingsNext.nex

:doexit

