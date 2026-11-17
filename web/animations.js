// NortInstall — scroll-reveal анимации на всех страницах.
// Автоматически помечает секции и карточки классом .reveal и показывает
// их по мере попадания в вьюпорт (с небольшой ступенчатой задержкой).
(function () {
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1 });

  document.querySelectorAll("section, .step, .cert, .card").forEach(function (el, i) {
    el.classList.add("reveal");
    el.style.transitionDelay = (i % 4) * 70 + "ms";
    observer.observe(el);
  });
})();
