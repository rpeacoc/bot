@echo off

:: batch file used to update Windows, Linux and OSX GIT repos

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
pause>NUL
goto:eof

:endif_envexist

:: location of batch files used to set up Intel compilation environment

call %envfile%

echo.
echo ---------------------- windows: %COMPUTERNAME% ------------------------------
echo repo: %svn_root%
%svn_drive%

cd %svn_root%\smv
echo.
echo *** smv ***
git remote update
git checkout master
git merge firemodels/master
git merge origin/master
git push origin master
git describe --dirty --abbrev=7

set scriptdir=%linux_svn_root%/bot/Scripts/
set linux_fdsdir=%linux_svn_root%

pause
