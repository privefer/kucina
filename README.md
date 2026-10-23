# Kucina Pro — Sistema POS y Gestión de Restaurantes

Kucina Pro es una solución integral para la gestión gastronómica, pedidos en sala, comandas en cocina y facturación en tiempo real. Cuenta con una arquitectura desacoplada compuesta por un backend REST y clientes multiplataforma (macOS, iOS, Android).

---

## 🏗️ Arquitectura del Sistema

* **Backend API (`kucina_backend`)**: Node.js, Express, autenticación JWT, gestión de comandas, menú, mesas y reportes de ventas.
* **Frontend App (`kucina_flutter`)**: Flutter multiplataforma (desktop y móvil) optimizado para pantallas táctiles y estaciones de comandas.

---

## 🚀 Inicio Rápido

### Requisitos
* Node.js 18+
* Flutter SDK 3.x+

### 1. Configuración del Backend
```bash
cd kucina_backend
cp .env.example .env
npm install
node src/index.js
```
El servidor se iniciará en `http://localhost:3000`.

### 2. Ejecución del Frontend
```bash
cd kucina_flutter
flutter pub get
flutter run -d macos
```

---

## 🔒 Variables de Entorno y Seguridad
Antes de desplegar en producción, copie `.env.example` a `.env` y configure claves criptográficas seguras:
* `JWT_SECRET`: Clave de firma para tokens de acceso.
* `JWT_REFRESH_SECRET`: Clave de firma para renovación de sesión.
* `PORT`: Puerto de escucha del servicio (por defecto 3000).

---

## 📄 Licencia
Este proyecto es software privado y propietario. Todos los derechos reservados.
