#!/bin/bash
# run_kucina.sh — Inicia el Backend y la App Kucina Pro en macOS

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$BASE_DIR/kucina_backend"
APP_DIR="$BASE_DIR/kucina_flutter"
ENTITLEMENTS="$APP_DIR/macos/Runner/DebugProfile.entitlements"

echo "🔌 Verificando Backend API en http://localhost:3000..."
if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
  echo "🚀 Iniciando Kucina Backend en segundo plano..."
  (cd "$BACKEND_DIR" && node src/index.js > server.log 2>&1 &)
  sleep 2
fi

echo "🧹 Limpiando xattrs de fuentes..."
xattr -cr "$APP_DIR/assets/" 2>/dev/null || true
xattr -cr "$APP_DIR/lib/" 2>/dev/null || true

echo "🔧 Compilando Flutter..."
cd "$APP_DIR"
flutter build macos --debug 2>&1 | grep -E "(Building|error:)" || true

APP="$APP_DIR/build/macos/Build/Products/Debug/kucina_flutter.app"
if [ ! -d "$APP" ]; then
  APP="/tmp/kucina_flutter_build/macos/Build/Products/Debug/kucina_flutter.app"
fi

if [ ! -d "$APP" ]; then
  echo "❌ No se encontró el .app compilado"; exit 1
fi

echo "🧹 Limpiando xattrs del bundle..."
xattr -cr "$APP" 2>/dev/null || true

echo "✍️  Firmando con permisos de red activos..."
codesign --force --sign - --entitlements "$ENTITLEMENTS" "$APP"

echo "🚀 Abriendo Kucina..."
pkill -f "kucina_flutter" 2>/dev/null || true
sleep 1
open "$APP"
echo "✅ ¡Kucina iniciada con conexión de red garantizada!"
