# Configuración de Almacenamiento en la Nube - NotePlus

Esta guía te ayudará a configurar el almacenamiento en la nube para tu aplicación NotePlus usando Firebase Firestore.

## 📋 Requisitos Previos

1. **Cuenta de Google** para acceder a Firebase Console
2. **Flutter SDK** instalado en tu sistema
3. **Android Studio** o **VS Code** con extensiones de Flutter

## 🚀 Pasos de Configuración

### 1. Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Ingresa un nombre para tu proyecto (ej: `noteplus-app`)
4. Sigue los pasos de configuración
5. Habilita Google Analytics si lo deseas

### 2. Configurar Firebase para tu App

#### Para Android:
1. En Firebase Console, ve a "Configuración del proyecto"
2. Descarga el archivo `google-services.json`
3. Coloca el archivo en `android/app/google-services.json`
4. Abre `android/build.gradle` y agrega:
   ```gradle
   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
     }
   }
   ```
5. Abre `android/app/build.gradle` y agrega al final:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### Para iOS:
1. En Firebase Console, ve a "Configuración del proyecto"
2. Descarga el archivo `GoogleService-Info.plist`
3. Coloca el archivo en `ios/Runner/GoogleService-Info.plist`
4. Abre `ios/Runner.xcodeproj` en Xcode
5. Agrega el archivo a tu proyecto

#### Para Web:
1. En Firebase Console, ve a "Configuración del proyecto"
2. Copia la configuración de Firebase
3. Actualiza el archivo `web/index.html` con los scripts de Firebase

### 3. Configurar Firestore Database

1. En Firebase Console, ve a "Firestore Database"
2. Haz clic en "Crear base de datos"
3. Elige "Iniciar en modo de prueba" (para desarrollo)
4. Selecciona una ubicación para tu base de datos
5. Espera a que se cree la base de datos

### 4. Configurar Reglas de Seguridad

En Firestore Database, ve a la pestaña "Reglas" y reemplaza con:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Los usuarios solo pueden acceder a sus propios datos
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Actualizar Archivos de Configuración

1. **Actualiza `firebase_options.dart`**:
   - Reemplaza los valores placeholder con tus credenciales reales de Firebase
   - Puedes obtener estos valores desde Firebase Console > Configuración del proyecto

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

### 6. Ejecutar la Aplicación

```bash
flutter run
```

## 📱 Uso de la Aplicación

### Activar Sincronización en la Nube

1. Abre la aplicación
2. Ve a la página de Agenda
3. Toca el ícono de configuración de nube (☁️) en la barra superior
4. Activa "Sincronización en la nube"
5. La aplicación creará automáticamente una cuenta anónima o usará tu cuenta existente

### Características Disponibles

- ✅ **Sincronización automática**: Los datos se guardan en la nube automáticamente
- ✅ **Modo offline**: La aplicación funciona sin conexión y sincroniza cuando vuelve a estar online
- ✅ **Copia de seguridad local**: Los datos siempre tienen una copia local
- ✅ **Sincronización manual**: Puedes forzar la sincronización desde la configuración
- ✅ **Cuentas anónimas**: No es necesario registrarse para usar la sincronización

## 🔧 Estructura de Datos

### Notas
```
/users/{userId}/notes/{noteId}
{
  "id": "note-id",
  "title": "Título de la nota",
  "content": "Contenido de la nota",
  "createdAt": timestamp,
  "modifiedAt": timestamp,
  "reminderAt": timestamp,
  "userId": "user-id",
  "category": "categoría",
  "tags": ["tag1", "tag2"],
  "isPinned": false,
  "backgroundColor": "#252836"
}
```

### Recordatorios
```
/users/{userId}/reminders/{reminderId}
{
  "id": "reminder-id",
  "title": "Título del recordatorio",
  "description": "Descripción",
  "reminderAt": timestamp,
  "isCompleted": false,
  "isTriggered": false,
  "userId": "user-id",
  "noteId": "note-id"
}
```

## 🛠️ Solución de Problemas

### Error de inicialización de Firebase
- Asegúrate de haber colocado correctamente los archivos de configuración
- Verifica que las dependencias estén instaladas: `flutter pub get`

### Error de permisos en Firestore
- Verifica que las reglas de seguridad estén configuradas correctamente
- Asegúrate de que el usuario esté autenticado

### Problemas de sincronización
- Verifica tu conexión a internet
- Intenta sincronizar manualmente desde la configuración
- Revisa los logs en la consola para ver errores específicos

## 📊 Costos y Límites

### Plan Gratuito (Spark Plan)
- **Almacenamiento**: 1GB
- **Documentos leídos**: 50,000 por día
- **Documentos escritos**: 20,000 por día
- **Eliminaciones**: 20,000 por día

### Para uso personal
El plan gratuito es más que suficiente para uso personal de la aplicación NotePlus.

## 🔒 Privacidad y Seguridad

- Los datos están cifrados en tránsito y en reposo
- Cada usuario solo puede acceder a sus propios datos
- Las cuentas anónimas no requieren información personal
- Puedes eliminar todos tus datos en cualquier momento

## 📞 Soporte

Si tienes problemas durante la configuración:

1. Revisa los logs de la aplicación con `flutter logs`
2. Verifica la configuración en Firebase Console
3. Consulta la [documentación de Firebase](https://firebase.google.com/docs)
4. Revisa que todas las dependencias estén actualizadas

---

**¡Listo!** Tu aplicación NotePlus ahora tiene almacenamiento en la nube con sincronización automática.
