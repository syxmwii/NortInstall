// ============================================================
// NortInstall — единая конфигурация сайта.
// Правится вручную владельцем проекта; остальные страницы
// подхватывают значения отсюда.
// ============================================================

// ВАЖНО: замените на ваш репозиторий вида "user/repo".
// Из него сайт берёт .ipa: Releases → latest → NortInstall*.ipa
const NORT_REPO = "syxmwii/NortInstall";

const NORT_RELEASES = `https://github.com/${NORT_REPO}/releases/latest/download`;

// Полный список сертификатов. status: active | checking | revoked
// file — имя .ipa в релизе; CI подписывает его секретами CERT_<ID>_*.
const NORT_CERTS = [
  { id: "A", region: "США",    type: "Enterprise", status: "active"   },
  { id: "B", region: "Европа", type: "Enterprise", status: "active"   },
  { id: "C", region: "Азия",   type: "Enterprise", status: "checking" },
  { id: "D", region: "СНГ",    type: "Enterprise", status: "active"   },
  { id: "E", region: "США",    type: "Developer",  status: "active"   },
  { id: "F", region: "Европа", type: "Developer",  status: "revoked"  },
  { id: "G", region: "Global", type: "Enterprise", status: "active"   },
  { id: "H", region: "Global", type: "Enterprise", status: "revoked"  },
  { id: "I", region: "США",    type: "Enterprise", status: "active"   },
  { id: "J", region: "Европа", type: "Enterprise", status: "active"   },
  { id: "K", region: "Азия",   type: "Developer",  status: "active"   },
  { id: "L", region: "Global", type: "Developer",  status: "active"   },
];

const NORT_STATUS = {
  active:   { label: "Активен",  className: "ok"   },
  checking: { label: "Проверка", className: "warn" },
  revoked:  { label: "Отозван",  className: "bad"  },
};
