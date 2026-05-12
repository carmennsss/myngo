@echo off
echo ==========================================
echo   MYNGO - Despliegue Manual a Cloudflare
echo ==========================================

:: 1. Compilar Flutter Web
echo [1/2] Compilando Flutter Web (Release)...
call C:\dev\flutter\bin\flutter.bat build web --release --tree-shake-icons

if %errorlevel% neq 0 (
    echo [ERROR] La compilacion de Flutter ha fallado.
    pause
    exit /b %errorlevel%
)

:: 2. Desplegar a Cloudflare Pages
:: NOTA: Reemplaza 'myngo-app' por el nombre real de tu proyecto en Cloudflare si es distinto.
echo [2/2] Subiendo a Cloudflare Pages...
call npx wrangler pages deploy build/web --project-name=myngo-app --branch=main

if %errorlevel% neq 0 (
    echo [ERROR] El despliegue a Cloudflare ha fallado.
    pause
    exit /b %errorlevel%
)

echo ==========================================
echo   ¡DESPLIEGUE COMPLETADO CON EXITO!
echo ==========================================
pause
