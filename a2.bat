..\snasm -map test.asm test.dat
if ERRORLEVEL 1 goto doexit

rem simple 48k model
..\CSpect.exe -s7 -map=test.dat.map -zxnext -mmc=.\ test.sna

:doexit

