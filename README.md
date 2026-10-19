# Panel Institucional CursAR

Panel web de instituciones para **CursAR**: las instituciones (universidades, terciarios, centros de formación) se **loguean con su cuenta** y desde ahí gestionan todo lo suyo de forma autónoma.

**Sitio en línea:** https://mvquinteros.github.io/PanelCursarInstitucion/

## ¿Qué hace?

Al iniciar sesión, cada institución ve solo sus datos y puede:

- **Dashboard** con estadísticas y gráficos (ofertas por estado y por área).
- **Ofertas**: crear, editar, activar / dar de baja y reenviar a revisión, con búsqueda y filtros. Las ofertas pasan por una revisión del equipo de CursAR (aprobada / pendiente) antes de mostrarse en la app.
- **Avisos**: publicar noticias, recordatorios de inscripción, consejos o eventos para sus seguidores. Quedan guardados como historial: se pueden consultar, editar o borrar.
- **Perfil de la institución**: datos de contacto, dirección, ubicación en el mapa y logo.

Además:

- Modo claro / oscuro que se recuerda entre sesiones.
- Diseño responsive: tabla en pantallas grandes y tarjetas en celular.
- Cualquiera puede registrarse como institución desde el panel; queda pendiente de aprobación por el administrador.

## Tecnologías

- **Flutter** (web) — panel compilado desde un solo código.
- **Firebase**: autenticación, Cloud Firestore (base de datos) y Storage (logos).
- **go_router** para rutas y **fl_chart** para los gráficos del dashboard.
- **GitHub Pages** para hospedaje: cada push a `main` compila y publica automáticamente vía GitHub Actions.

## Ejecutar localmente

```bash
flutter pub get
flutter run -d chrome
```

Para publicar:

```bash
flutter build web --release
```

El proyecto usa el Firebase configurado en `lib/firebase_config.dart`. Las reglas de seguridad de Firestore deben permitir a la institución leer y escribir **solo** sus documentos (`ofertas`, `avisos_instituciones`, `instituciones` y su usuario), verificando la pertenencia a través de `usuarios/{uid}.institucionUid`.
