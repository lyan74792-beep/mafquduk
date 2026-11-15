/* =========================================================
   منصة مفقودك - app.js
   1) نظام تبديل اللغة الفوري (عربي / إنجليزي / أردو / تركي)
   2) مشاركة الموقع الدقيق (GPS + اختيار من الخريطة)
   3) تبسيط وتسريع تعبئة النماذج (تعبئة تلقائية + تحقق فوري)
   4) خدمة استعلام وتتبع حالة البلاغات بنجاح
   ========================================================= */

/* ---------- 1) الترجمات ---------- */
const LANG_NAMES = { ar: 'العربية', en: 'English', ur: 'اردو', tr: 'Türkçe' };
const RTL_LANGS = ['ar', 'ur'];

/* Strings live in assets/i18n/<lang>.js (loaded before this file). */
const TRANSLATIONS = window.I18N || {};

function t(lang, key) {
  return (TRANSLATIONS[lang] && TRANSLATIONS[lang][key]) || TRANSLATIONS.ar[key] || key;
}

/* Translate a lookup value stored in Arabic; unknown values stay as they are. */
function tv(lang, value) {
  const table = (window.I18N_VALUES || {})[lang];
  return (table && table[value]) || value;
}

function applyLanguage(lang) {
  if (!TRANSLATIONS[lang]) lang = 'ar';
  const dir = RTL_LANGS.includes(lang) ? 'rtl' : 'ltr';

  document.documentElement.setAttribute('lang', lang);
  document.documentElement.setAttribute('dir', dir);

  const bsLink = document.getElementById('bootstrap-css');
  if (bsLink) {
    bsLink.href = dir === 'rtl'
      ? 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css'
      : 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css';
  }

  document.querySelectorAll('[data-i18n]').forEach(el => {
    el.textContent = t(lang, el.getAttribute('data-i18n'));
  });
  document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
    el.placeholder = t(lang, el.getAttribute('data-i18n-placeholder'));
  });
  // Lookup values stored in Arabic (categories, landmarks, …): assets/i18n/values.js
  document.querySelectorAll('[data-i18n-value]').forEach(el => {
    el.textContent = tv(lang, el.getAttribute('data-i18n-value'));
  });

  document.querySelectorAll('.lang-option').forEach(b => {
    b.classList.toggle('active', b.dataset.lang === lang);
  });
  const currentLabel = document.getElementById('currentLangLabel');
  if (currentLabel) currentLabel.textContent = LANG_NAMES[lang];

  localStorage.setItem('mafqodak_lang', lang);
  // Server messages (alerts after a form is sent) follow the same language.
  document.cookie = 'mafqodak_lang=' + lang + '; path=/; max-age=31536000; SameSite=Lax';
}

function initLanguageSwitcher() {
  const saved = localStorage.getItem('mafqodak_lang') || 'ar';
  applyLanguage(saved);
  document.querySelectorAll('.lang-option').forEach(btn => {
    btn.addEventListener('click', () => applyLanguage(btn.dataset.lang));
  });
}

/* ---------- 2) مشاركة الموقع (GPS + خريطة) ---------- */
function initLocationPicker(prefix) {
  const gpsBtn = document.getElementById(prefix + '_gps_btn');
  const mapBtn = document.getElementById(prefix + '_map_btn');
  const latInput = document.getElementById(prefix + '_lat');
  const lngInput = document.getElementById(prefix + '_lng');
  const statusEl = document.getElementById(prefix + '_location_status');
  const currentLang = () => localStorage.getItem('mafqodak_lang') || 'ar';

  function showFound() {
    if (!statusEl || !latInput || !lngInput) return;
    statusEl.textContent = t(currentLang(), 'location_status_found') + ' (' + latInput.value + ', ' + lngInput.value + ')';
    statusEl.classList.remove('text-danger', 'text-muted');
    statusEl.classList.add('text-success');
  }
  function showError() {
    if (!statusEl) return;
    statusEl.textContent = t(currentLang(), 'location_status_error');
    statusEl.classList.remove('text-success', 'text-muted');
    statusEl.classList.add('text-danger');
  }

  if (gpsBtn && latInput && lngInput) {
    gpsBtn.addEventListener('click', () => {
      if (!navigator.geolocation) { showError(); return; }
      navigator.geolocation.getCurrentPosition(pos => {
        latInput.value = pos.coords.latitude.toFixed(6);
        lngInput.value = pos.coords.longitude.toFixed(6);
        showFound();
      }, showError, { enableHighAccuracy: true, timeout: 10000 });
    });
  }

  if (mapBtn) {
    let map, marker;
    const modalEl = document.getElementById(prefix + '_map_modal');
    if (!modalEl) return;
    const modal = new bootstrap.Modal(modalEl);

    mapBtn.addEventListener('click', () => {
      modal.show();
      setTimeout(() => {
        if (!map) {
          map = L.map(prefix + '_map_container').setView([21.4225, 39.8262], 15);
          L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap contributors'
          }).addTo(map);
          map.on('click', e => {
            if (marker) { marker.setLatLng(e.latlng); }
            else { marker = L.marker(e.latlng).addTo(map); }
          });
        } else {
          map.invalidateSize();
        }
      }, 300);
    });

    const confirmBtn = document.getElementById(prefix + '_map_confirm');
    if (confirmBtn && latInput && lngInput) {
      confirmBtn.addEventListener('click', () => {
        if (marker) {
          const ll = marker.getLatLng();
          latInput.value = ll.lat.toFixed(6);
          lngInput.value = ll.lng.toFixed(6);
          showFound();
        }
        modal.hide();
      });
    }
  }
}

/* ---------- 3) تبسيط وتسريع النموذج ---------- */
function initSmartForm(config) {
  const form = document.getElementById(config.formId);
  if (!form) return;

  const savedName = localStorage.getItem('mafqodak_name');
  const savedPhone = localStorage.getItem('mafqodak_phone');

  if (config.nameField) {
    const el = document.getElementById(config.nameField);
    if (el && !el.value && savedName) el.value = savedName;
  }
  if (config.phoneField) {
    const el = document.getElementById(config.phoneField);
    if (el && !el.value && savedPhone) el.value = savedPhone;
  }
  if (config.dateField) {
    const el = document.getElementById(config.dateField);
    if (el) {
      const today = new Date().toISOString().split('T')[0];
      el.max = today;
      if (!el.value) el.value = today;
    }
  }

  if (config.phoneField) {
    const phoneEl = document.getElementById(config.phoneField);
    const pattern = /^05\d{8}$/;
    if (phoneEl) {
      phoneEl.addEventListener('input', () => {
        if (pattern.test(phoneEl.value)) {
          phoneEl.classList.remove('is-invalid');
          phoneEl.classList.add('is-valid');
        } else {
          phoneEl.classList.remove('is-valid');
          phoneEl.classList.add('is-invalid');
        }
      });
    }
  }

  form.addEventListener('submit', (e) => {
    if (!form.checkValidity()) {
      e.preventDefault();
      e.stopPropagation();
    }
    form.classList.add('was-validated');

    if (config.nameField) {
      const el = document.getElementById(config.nameField);
      if (el && el.value) localStorage.setItem('mafqodak_name', el.value);
    }
    if (config.phoneField) {
      const el = document.getElementById(config.phoneField);
      if (el && el.value) localStorage.setItem('mafqodak_phone', el.value);
    }
  });
}

/* ---------- 4) إظهار مربع "أخرى" عند اختيارها من القائمة ---------- */
function initOtherToggle(selectId, otherInputId, triggerValue) {
  const select = document.getElementById(selectId);
  const otherInput = document.getElementById(otherInputId);
  if (!select || !otherInput) return;

  function update() {
    if (select.value === triggerValue) {
      otherInput.classList.remove('d-none');
      otherInput.setAttribute('required', 'required');
    } else {
      otherInput.classList.add('d-none');
      otherInput.removeAttribute('required');
      otherInput.value = '';
    }
  }
  select.addEventListener('change', update);
  update();
}

/* ---------- 5) خدمة تتبع البلاغ المباشرة ---------- */
function initReportTracker() {
  const form = document.getElementById('trackForm');
  const queryInput = document.getElementById('track_query');
  const resultsDiv = document.getElementById('searchResults');
  if (!form || !resultsDiv || !queryInput) return;

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    const query = queryInput.value.trim();
    if (!query) return;

    const currentLang = localStorage.getItem('mafqodak_lang') || 'ar';

    fetch(`track_status.php?query=${encodeURIComponent(query)}`)
      .then(res => res.json())
      .then(data => {
        resultsDiv.classList.remove('d-none');
        if (data.success) {
          const r = data.report;
          const STEPS = { received: 20, searching: 40, matched: 60, ready: 80, delivered: 100, cancelled: 100 };
          const stKey = STEPS[r.status] ? r.status : 'searching';
          const pct = STEPS[stKey];
          const barColor = stKey === 'cancelled' ? '#b91c1c' : '#0d4a3a';
          resultsDiv.innerHTML = `
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h5 class="fw-bold mb-0 track-report-id">#${r.report_id}</h5>
              <span class="badge bg-secondary">${r.created_at}</span>
            </div>
            <div class="progress mb-3 track-progress" style="height:10px;">
              <div class="progress-bar track-progress-bar" role="progressbar" style="width:${pct}%; background-color:${barColor};"></div>
            </div>
            <p class="mb-0 fw-semibold text-muted small">${t(currentLang, 'track_status_' + stKey)}</p>
          `;
        } else if (data.message === 'server_error') {
          resultsDiv.innerHTML = `<div class="alert alert-danger mb-0 text-center small">${t(currentLang, 'track_server_error')}</div>`;
        } else {
          resultsDiv.innerHTML = `
            <div class="alert alert-warning mb-0 text-center small">
              ${t(currentLang, 'track_not_found')}
            </div>
          `;
        }
      })
      .catch(() => {
        resultsDiv.classList.remove('d-none');
        resultsDiv.innerHTML = `<div class="alert alert-danger mb-0 text-center small">${t(localStorage.getItem('mafqodak_lang') || 'ar', 'track_fetch_error')}</div>`;
      });
  });
}

/* ---------- 6) Voice dictation (Web Speech API) for description fields ---------- */
const VOICE_LOCALES = { ar: 'ar-SA', en: 'en-US', ur: 'ur-PK', tr: 'tr-TR' };

function initVoiceInput(buttonId, fieldId) {
  const btn = document.getElementById(buttonId);
  const field = document.getElementById(fieldId);
  const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!btn || !field) return;
  if (!Recognition) {            // browser without speech recognition: hide the mic
    btn.classList.add('d-none');
    return;
  }
  let recognizer = null;
  const lang = () => localStorage.getItem('mafqodak_lang') || 'ar';
  const setListening = (on) => {
    btn.classList.toggle('btn-danger', on);
    btn.classList.toggle('btn-outline-secondary', !on);
    btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    btn.title = t(lang(), on ? 'voice_stop' : 'voice_start');
  };
  btn.title = t(lang(), 'voice_start');
  btn.addEventListener('click', () => {
    if (recognizer) { recognizer.stop(); return; }
    recognizer = new Recognition();
    recognizer.lang = VOICE_LOCALES[lang()] || 'ar-SA';
    recognizer.interimResults = false;
    recognizer.onresult = (e) => {
      const text = Array.from(e.results).map(r => r[0].transcript).join(' ').trim();
      if (text) field.value = (field.value ? field.value.trim() + ' ' : '') + text;
      field.dispatchEvent(new Event('input'));
    };
    recognizer.onerror = () => { field.placeholder = t(lang(), 'voice_error'); };
    recognizer.onend = () => { recognizer = null; setListening(false); };
    setListening(true);
    recognizer.start();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initLanguageSwitcher();
  initReportTracker();
});