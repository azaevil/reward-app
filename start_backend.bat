@echo off
title Reward App Backend
cd /d "%~dp0backend"
echo [1/2] Gerekli paketler kontrol ediliyor...
python -m pip install fastapi uvicorn sqlalchemy pydantic pydantic-settings python-jose[cryptography] "passlib[bcrypt]" python-multipart
echo.
echo [2/2] Backend Sunucusu Baslatiliyor (Docker gerekmez, SQLite devrede)...
echo Swagger API Adresi: http://127.0.0.1:8000/docs
echo.
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
pause
