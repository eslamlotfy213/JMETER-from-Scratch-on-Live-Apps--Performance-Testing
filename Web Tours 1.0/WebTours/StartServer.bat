@ECHO OFF
ECHO starting the webtours apache server...
ECHO press CTRL-C or close the window to exit :)
bin\httpd.exe -d "%cd%"
