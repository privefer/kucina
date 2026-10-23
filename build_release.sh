#!/bin/bash
# ==============================================================================
# build_release.sh — Compilador Universal de Kucina para Producción
# ==============================================================================
# Uso:
#   ./build_release.sh [android-apk | android-bundle | macos | ios | web | all] [API_URL]
# ==============================================================================

set -e

TARGET=${1:-"macos"}
PROD_API=${2:-"https://api.kucina.pe/api"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR/kucina_flutter"

echo "=================================================="
echo "🚀 Kucina Release Builder"
echo "🎯 Target: $TARGET"
echo "🌐 API Base URL: $PROD_API"
echo "=================================================="

cd "$FLUTTER_DIR"

echo "🧹 Limpiando xattrs y cachés..."
xattr -cr "$FLUTTER_DIR/assets/" 2>/dev/null || true
xattr -cr "$FLUTTER_DIR/lib/" 2>/dev/null || true

case "$TARGET" in
  "android-apk")
    echo "📱 Compilando Android APK Release..."
    flutter build apk --release --dart-define=API_BASE_URL="$PROD_API"
    echo "✅ APK generado en: $FLUTTER_DIR/build/app/outputs/flutter-apk/app-release.apk"
    ;;

  "android-bundle")
    echo "📦 Compilando Android App Bundle (.aab) para Google Play..."
    flutter build appbundle --release --dart-define=API_BASE_URL="$PROD_API"
    echo "✅ AAB generado en: $FLUTTER_DIR/build/app/outputs/bundle/release/app-release.aab"
    ;;

  "macos")
    echo "🖥️  Compilando macOS Release..."
    flutter build macos --release --dart-define=API_BASE_URL="$PROD_API"
    echo "✅ App macOS generada en: $FLUTTER_DIR/build/macos/Build/Products/Release/kucina_flutter.app"
    ;;

  "ios")
    echo "🍏 Compilando iOS Release (no-codesign para exportación CI)..."
    flutter build ios --release --no-codesign --dart-define=API_BASE_URL="$PROD_API"
    echo "✅ iOS Bundle generado en: $FLUTTER_DIR/build/ios/iphoneos/Runner.app"
    ;;

  "web")
    echo "🌐 Compilando Web Client Release..."
    flutter build web --release --dart-define=API_BASE_URL="$PROD_API"
    echo "✅ Web build generado en: $FLUTTER_DIR/build/web"
    ;;

  *)
    echo "❌ Opción desconocida: $TARGET"
    echo "Opciones válidas: android-apk, android-bundle, macos, ios, web"
    exit 1
    ;;
esac

echo "🎉 ¡Compilación completada con éxito!"
