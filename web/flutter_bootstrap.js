{{flutter_js}}
{{flutter_build_config}}

const tracopBootStartedAt = performance.now();

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      await new Promise((resolve) => requestAnimationFrame(resolve));
      const minimumBootDuration = 1450;
      const remainingBootDuration =
          minimumBootDuration - (performance.now() - tracopBootStartedAt);
      if (remainingBootDuration > 0) {
        await new Promise((resolve) => window.setTimeout(resolve, remainingBootDuration));
      }
      const bootScreen = document.getElementById('tracop-boot');
      if (bootScreen) {
        bootScreen.classList.add('is-ready');
        window.setTimeout(() => bootScreen.remove(), 180);
      }
    } catch (error) {
      console.error('No se pudo iniciar TRACOP.', error);
      const bootScreen = document.getElementById('tracop-boot');
      if (bootScreen) {
        bootScreen.innerHTML =
            '<p role="alert">No se pudo abrir TRACOP. Recarga la página para intentarlo de nuevo.</p>';
      }
    }
  },
});
