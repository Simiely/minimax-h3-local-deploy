@echo off
setlocal
rem Push this repo to GitHub and create the remote repo if missing.
rem Usage:  push-to-github.cmd [PAT]        # token is never written to disk

set "USERNAME=Simiely"
set "REPO=minimax-h3-local-deploy"

if not "%~1"=="" goto havearg
set /p TOKEN=GitHub PAT: 
goto checktoken
:havearg
set "TOKEN=%~1"
:checktoken
if "%TOKEN%"=="" goto notoken

echo [1/4] checking token ...
curl -s -o "%TEMP%\gh_user.json" -w "%%{http_code}" -H "Authorization: token %TOKEN%" https://api.github.com/user > "%TEMP%\gh_code.txt"
set /p CODE=<"%TEMP%\gh_code.txt"
if not "%CODE%"=="200" goto badcode

echo [2/4] creating repo %USERNAME%/%REPO% if missing ...
curl -s -o nul -H "Authorization: token %TOKEN%" -H "Accept: application/vnd.github+json" https://api.github.com/user/repos -d "{\"name\":\"%REPO%\",\"description\":\"MiniMax H3 local deployment notes for 12GB and 16GB consumer GPUs\",\"private\":false}"

echo [3/4] setting remote ...
git remote remove origin >nul 2>nul
git remote add origin https://%TOKEN%@github.com/%USERNAME%/%REPO%.git
git branch -M main

echo [4/4] pushing ...
git push -u origin main
if errorlevel 1 goto badpush
echo.
echo [OK] https://github.com/%USERNAME%/%REPO%
goto end

:notoken
echo [ERROR] no token given.
goto end

:badcode
echo [ERROR] token rejected, HTTP code %CODE%.
echo         A classic PAT must be 40 chars and start with ghp_ .
echo         If the code is 000 the network is down - check the proxy first.
goto end

:badpush
echo [FAIL] push failed. Usually the network: GitHub is unreachable
echo        without a working proxy. Fix the proxy and rerun.
goto end

:end
endlocal
pause