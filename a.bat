..\snasm -map _LemmingsNext.asm _LemmingsNext.dat
if ERRORLEVEL 1 goto doexit

rem simple 48k model
..\CSpect.exe -w3 -map=_LemmingsNext.dat.map -zxnext -mmc=.\ _LemmingsNext.sna

:doexit

