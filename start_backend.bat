@echo off
title Vidreel Backend Sunucusu
cd /d "%~dp0backend"
echo [1/2] Gerekli paketler kontrol ediliyor...
python -m pip install fastapi uvicorn sqlalchemy pydantic pydantic-settings python-jose[cryptography] "passlib[bcrypt]" python-multipart
echo.
echo [2/2] Vidreel Guvenli Backend Sunucusu Baslatiliyor...
echo Yerel IP (Telefon icin): http://192.168.1.101:8000
echo Swagger API Dokumantasyonu: http://127.0.0.1:8000/docs
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
