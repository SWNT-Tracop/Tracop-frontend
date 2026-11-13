# CI del frontend

El workflow `.github/workflows/flutter-ci.yml` ejecuta en GitHub Actions:

- `snyk code test` para analizar el código Dart/Flutter. Usa el secret `SNYK_TOKEN` configurado en GitHub y falla ante hallazgos de severidad alta o crítica.
- `flutter analyze` para análisis estático de Dart y Flutter.
- `flutter test` para las pruebas del frontend.

Se ejecuta en `push` y en todos los eventos `pull_request`, sin filtrar por rama destino; por tanto, también revisa PRs dirigidas a `develop` además de `master`.
