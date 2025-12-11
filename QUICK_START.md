# 🚀 Guía Rápida - Activar Guardado en la Nube

## Paso 1: Crear Proyecto Firebase (5 minutos)

1. Ve a https://console.firebase.google.com/
2. Haz clic en **"Agregar proyecto"**
3. Nombre: `noteplus-app`
4. Sigue los pasos (habilita Analytics si quieres)

## Paso 2: Configurar Android

1. En Firebase Console → Configuración del proyecto
2. Descarga `google-services.json`
3. Colócalo en: `android/app/google-services.json`

## Paso 3: Actualizar Archivos

Abre estos archivos y reemplaza los placeholders:

### `firebase_options.dart`
```dart
// Reemplaza estos valores con los de tu proyecto Firebase
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'TU_API_KEY',
  appId: 'TU_APP_ID',
  messagingSenderId: 'TU_SENDER_ID',
  projectId: 'TU_PROJECT_ID',
  authDomain: 'TU_PROJECT_ID.firebaseapp.com',
  storageBucket: 'TU_PROJECT_ID.appspot.com',
);
```

## Paso 4: Instalar Dependencias
```bash
flutter pub get
```

## Paso 5: Configurar Firestore

1. En Firebase Console → Firestore Database
2. "Crear base de datos"
3. "Iniciar en modo de prueba"
4. Copia estas reglas de seguridad:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Paso 6: Ejecutar App
```bash
flutter run
```

## Paso 7: Activar Sincronización

1. Abre la app
2. Ve a la página de Agenda
3. Toca el ícono de nube ☁️ (arriba derecha)
4. Activa "Sincronización en la nube"

¡Listo! Tus datos se guardarán automáticamente en la nube.
