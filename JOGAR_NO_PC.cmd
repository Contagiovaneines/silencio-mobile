@echo off
cd /d "%~dp0"
set "SILENCIO_FLUTTER=%USERPROFILE%\.cache\codex-runtimes\flutter-sdk\bin\flutter.bat"
if not exist "%SILENCIO_FLUTTER%" (
  echo Flutter nao encontrado neste computador. Veja o README.
  pause
  exit /b 1
)
echo Abrindo Silencio no Chrome. Mantenha esta janela aberta durante o jogo.
call "%SILENCIO_FLUTTER%" run -d chrome
pause
