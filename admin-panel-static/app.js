/**
 * SMARTFARMING Admin Panel - Static (client-side only)
 * Matches Flutter admin design and behavior; uses mock data when no backend.
 */

(function () {
  'use strict';

  const STORAGE_KEY = 'sfarm_admin_user';

  // ----- Mock data -----
  let mockFarmers = [
    { id: 'f1', name: 'Juan Dela Cruz', email: 'juan@example.com', farmLocation: 'Panabo City' },
    { id: 'f2', name: 'Maria Santos', email: 'maria@example.com', farmLocation: 'Davao City' },
  ];

  let mockDetections = [
    { id: 'd1', imageUrl: '', disease: 'Brown Spot', confidence: 0.92, timestamp: new Date(Date.now() - 86400000) },
    { id: 'd2', imageUrl: '', disease: 'Bacterial Leaf Blight', confidence: 0.88, timestamp: new Date(Date.now() - 172800000) },
  ];

  let mockTreatments = [
    { id: 't1', userId: 'f1', userName: 'Juan Dela Cruz', disease: 'Brown Spot', scheduleDate: new Date(), status: 'pending', type: 'treatment', notes: '' },
    { id: 't2', userId: 'f2', userName: 'Maria Santos', disease: 'Sheath Blight', scheduleDate: new Date(Date.now() + 86400000), status: 'pending', type: 'fertilization', notes: '' },
    { id: 't3', userId: 'f1', userName: 'Juan Dela Cruz', disease: 'Blast', scheduleDate: new Date(Date.now() - 86400000), status: 'completed', type: 'treatment', notes: '' },
  ];

  const mockWeather = {
    temperature: 28,
    humidity: 75,
    condition: 'Partly cloudy',
    windSpeed: 3.5,
    rainProbability: 20,
  };

  const mockSoilByUser = {
    f1: { moisture: 45, ph: 6.2 },
    f2: { moisture: 72, ph: 5.2 },
  };

  // ----- DOM refs -----
  const screens = document.querySelectorAll('.screen');
  const snackbar = document.getElementById('snackbar');
  const modalOverlay = document.getElementById('modal-overlay');
  const modalContent = document.getElementById('modal-content');

  // ----- Navigation -----
  function showScreen(screenId) {
    const id = screenId.startsWith('screen-') ? screenId : 'screen-' + screenId;
    screens.forEach(function (el) {
      el.classList.toggle('active', el.id === id);
    });
    if (id === 'screen-admin-dashboard') {
      refreshDashboard();
    } else if (id === 'screen-farmer-management') {
      renderFarmerList();
    } else if (id === 'screen-detection-records') {
      renderDetectionList();
    } else if (id === 'screen-admin-calendar') {
      renderCalendar();
    } else if (id === 'screen-admin-soil-weather') {
      renderSoilWeather();
    } else if (id === 'screen-admin-profile') {
      refreshProfile();
    }
  }

  function getCurrentUser() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  function setCurrentUser(user) {
    if (user) localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
    else localStorage.removeItem(STORAGE_KEY);
  }

  // ----- Snackbar -----
  function showSnackbar(message, type) {
    snackbar.textContent = message;
    snackbar.className = 'snackbar show ' + (type || 'info');
    setTimeout(function () {
      snackbar.classList.remove('show');
    }, 3000);
  }

  // ----- Modal -----
  function showModal(title, bodyHtml, actions) {
    modalContent.innerHTML =
      '<h2>' + escapeHtml(title) + '</h2>' +
      (bodyHtml || '') +
      '<div class="modal-actions">' + (actions || '') + '</div>';
    modalOverlay.classList.remove('hidden');
    modalOverlay.setAttribute('aria-hidden', 'false');
  }

  function closeModal() {
    modalOverlay.classList.add('hidden');
    modalOverlay.setAttribute('aria-hidden', 'true');
  }

  function escapeHtml(s) {
    if (!s) return '';
    const div = document.createElement('div');
    div.textContent = s;
    return div.innerHTML;
  }

  // ----- Splash -----
  function runSplash() {
    showScreen('screen-splash');
    setTimeout(function () {
      const user = getCurrentUser();
      if (user && user.email) {
        showScreen('admin-dashboard');
      } else {
        showScreen('admin-login');
      }
    }, 2500);
  }

  // ----- Login -----
  function validateEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email || '');
  }

  function handleLoginSubmit(e) {
    e.preventDefault();
    const emailEl = document.getElementById('login-email');
    const passwordEl = document.getElementById('login-password');
    const email = (emailEl.value || '').trim();
    const password = passwordEl.value || '';

    document.getElementById('login-email-error').textContent = '';
    document.getElementById('login-password-error').textContent = '';

    let valid = true;
    if (!email) {
      document.getElementById('login-email-error').textContent = 'Please enter your email';
      valid = false;
    } else if (!validateEmail(email)) {
      document.getElementById('login-email-error').textContent = 'Please enter a valid email';
      valid = false;
    }
    if (!password) {
      document.getElementById('login-password-error').textContent = 'Please enter your password';
      valid = false;
    }
    if (!valid) return;

    // Static: accept any admin login (e.g. admin@admin.com / any password)
    setCurrentUser({ name: email.split('@')[0].replace(/\./g, ' ') || 'Admin', email: email });
    showSnackbar('Signed in successfully', 'success');
    showScreen('admin-dashboard');
  }

  function togglePassword() {
    const input = document.getElementById('login-password');
    const icon = document.querySelector('#screen-admin-login .toggle-pwd .material-symbols-outlined');
    if (input.type === 'password') {
      input.type = 'text';
      icon.textContent = 'visibility_off';
    } else {
      input.type = 'password';
      icon.textContent = 'visibility';
    }
  }

  // ----- Dashboard -----
  function refreshDashboard() {
    const user = getCurrentUser();
    document.getElementById('dashboard-username').textContent = (user && user.name) ? user.name : 'Admin';

    const pending = mockTreatments.filter(function (t) { return t.status === 'pending'; });
    document.getElementById('stat-detections').textContent = mockDetections.length;
    document.getElementById('stat-treatments').textContent = pending.length;

    const distribution = {};
    mockDetections.forEach(function (d) {
      distribution[d.disease] = (distribution[d.disease] || 0) + 1;
    });
    const distEl = document.getElementById('disease-distribution');
    if (Object.keys(distribution).length === 0) {
      distEl.innerHTML = '<span>No data available</span>';
    } else {
      distEl.innerHTML = Object.entries(distribution).map(function (e) {
        return '<div class="row"><span>' + escapeHtml(e[0]) + '</span><strong>' + e[1] + '</strong></div>';
      }).join('');
    }
  }

  // ----- Logout -----
  function confirmLogout() {
    showModal(
      'Logout',
      '<p>Are you sure you want to logout?</p>',
      '<button type="button" class="btn-text" data-action="cancel">Cancel</button>' +
      '<button type="button" class="btn-text" data-action="logout">Logout</button>'
    );
    modalContent.querySelector('[data-action="logout"]').addEventListener('click', function () {
      closeModal();
      setCurrentUser(null);
      showScreen('admin-login');
    });
    modalContent.querySelector('[data-action="cancel"]').addEventListener('click', closeModal);
  }

  // ----- Farmer list -----
  function renderFarmerList() {
    const listEl = document.getElementById('farmer-list');
    const emptyEl = document.getElementById('farmer-empty');
    if (mockFarmers.length === 0) {
      listEl.innerHTML = '';
      emptyEl.classList.remove('hidden');
      return;
    }
    emptyEl.classList.add('hidden');
    listEl.innerHTML = mockFarmers.map(function (f) {
      return (
        '<div class="farmer-card" data-id="' + escapeHtml(f.id) + '">' +
          '<div class="farmer-avatar">' + (f.name.charAt(0).toUpperCase()) + '</div>' +
          '<div class="farmer-info">' +
            '<p class="farmer-name">' + escapeHtml(f.name) + '</p>' +
            '<p class="farmer-meta">Email: ' + escapeHtml(f.email) + '</p>' +
            (f.farmLocation ? '<p class="farmer-meta">Location: ' + escapeHtml(f.farmLocation) + '</p>' : '') +
          '</div>' +
          '<button type="button" class="farmer-menu-btn" aria-haspopup="true" aria-expanded="false" data-id="' + escapeHtml(f.id) + '">' +
            '<span class="material-symbols-outlined">more_vert</span>' +
          '</button>' +
        '</div>'
      );
    }).join('');

    listEl.querySelectorAll('.farmer-menu-btn').forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        e.stopPropagation();
        const id = btn.getAttribute('data-id');
        const farmer = mockFarmers.find(function (f) { return f.id === id; });
        if (!farmer) return;
        showFarmerMenu(btn, farmer);
      });
    });
  }

  function showFarmerMenu(anchor, farmer) {
    const existing = document.querySelector('.dropdown-menu');
    if (existing) existing.remove();
    const div = document.createElement('div');
    div.className = 'dropdown-menu';
    div.innerHTML =
      '<button type="button" data-action="edit">' +
        '<span class="material-symbols-outlined">edit</span> Edit' +
      '</button>' +
      '<button type="button" class="danger" data-action="delete">' +
        '<span class="material-symbols-outlined">delete</span> Delete' +
      '</button>';
    document.body.appendChild(div);
    const rect = anchor.getBoundingClientRect();
    div.style.position = 'fixed';
    div.style.left = rect.left + 'px';
    div.style.top = (rect.bottom + 4) + 'px';

    function close() {
      div.remove();
      document.removeEventListener('click', close);
    }
    setTimeout(function () { document.addEventListener('click', close); }, 0);

    div.querySelector('[data-action="edit"]').addEventListener('click', function () {
      close();
      showEditFarmerDialog(farmer);
    });
    div.querySelector('[data-action="delete"]').addEventListener('click', function () {
      close();
      showDeleteFarmerDialog(farmer);
    });
  }

  function showAddFarmerDialog() {
    showModal(
      'Add Farmer',
      '<p>Farmer registration should be done through the mobile app.</p>',
      '<button type="button" class="btn btn-primary" data-action="ok">OK</button>'
    );
    modalContent.querySelector('[data-action="ok"]').addEventListener('click', closeModal);
  }

  function showEditFarmerDialog(farmer) {
    showModal(
      'Edit Farmer',
      '<p>Edit functionality for ' + escapeHtml(farmer.name) + '</p>',
      '<button type="button" class="btn-text" data-action="cancel">Cancel</button>' +
      '<button type="button" class="btn-text" data-action="save">Save</button>'
    );
    modalContent.querySelector('[data-action="cancel"]').addEventListener('click', closeModal);
    modalContent.querySelector('[data-action="save"]').addEventListener('click', function () {
      closeModal();
      showSnackbar('Edit functionality coming soon', 'info');
    });
  }

  function showDeleteFarmerDialog(farmer) {
    showModal(
      'Delete Farmer',
      '<p>Are you sure you want to delete ' + escapeHtml(farmer.name) + '?</p>',
      '<button type="button" class="btn-text" data-action="cancel">Cancel</button>' +
      '<button type="button" class="btn-text danger" data-action="delete">Delete</button>'
    );
    modalContent.querySelector('[data-action="cancel"]').addEventListener('click', closeModal);
    modalContent.querySelector('[data-action="delete"]').addEventListener('click', function () {
      closeModal();
      showSnackbar('Delete functionality coming soon', 'info');
    });
  }

  // ----- Detection list -----
  function formatDate(d) {
    const dt = d instanceof Date ? d : new Date(d);
    const day = dt.getDate();
    const month = dt.getMonth() + 1;
    const year = dt.getFullYear();
    const h = dt.getHours();
    const m = dt.getMinutes();
    return day + '/' + month + '/' + year + ' ' + h + ':' + (m < 10 ? '0' : '') + m;
  }

  function renderDetectionList() {
    const listEl = document.getElementById('detection-list');
    const emptyEl = document.getElementById('detection-empty');
    if (mockDetections.length === 0) {
      listEl.innerHTML = '';
      emptyEl.classList.remove('hidden');
      return;
    }
    emptyEl.classList.add('hidden');
    listEl.innerHTML = mockDetections.map(function (d) {
      const imgHtml = d.imageUrl
        ? '<img src="' + escapeHtml(d.imageUrl) + '" alt="">'
        : '<div class="no-image"><span class="material-symbols-outlined">broken_image</span></div>';
      return (
        '<div class="detection-card">' +
          imgHtml +
          '<div class="detection-card-body">' +
            '<div class="detection-card-header">' +
              '<p class="detection-disease">' + escapeHtml(d.disease) + '</p>' +
              '<span class="detection-confidence">' + (d.confidence * 100).toFixed(1) + '%</span>' +
            '</div>' +
            '<p class="detection-date">Date: ' + formatDate(d.timestamp) + '</p>' +
            '<div class="detection-actions">' +
              '<button type="button" class="btn-outline"><span class="material-symbols-outlined">info</span> Details</button>' +
              '<button type="button" class="btn-outline"><span class="material-symbols-outlined">download</span> Download</button>' +
            '</div>' +
          '</div>' +
        '</div>'
      );
    }).join('');
  }

  // ----- Model Trainer -----
  function setupModelTrainer() {
    document.getElementById('btn-upload-dataset').addEventListener('click', function () {
      document.getElementById('input-dataset').click();
    });
    document.getElementById('input-dataset').addEventListener('change', function () {
      const files = this.files;
      if (files && files.length) {
        showSnackbar(files.length + ' images selected', 'success');
      }
      this.value = '';
    });

    document.getElementById('btn-trigger-training').addEventListener('click', function () {
      const btn = this;
      btn.disabled = true;
      btn.innerHTML = '<span class="spinner" style="width:16px;height:16px;border-width:2px"></span> Training...';
      setTimeout(function () {
        btn.disabled = false;
        btn.innerHTML = '<span class="material-symbols-outlined btn-icon-left">play_arrow</span> Start Training';
        showSnackbar('Training trigger sent. This requires backend ML server integration.', 'info');
      }, 3000);
    });

    document.getElementById('btn-replace-model').addEventListener('click', function () {
      document.getElementById('input-model').click();
    });
    document.getElementById('input-model').addEventListener('change', function () {
      if (this.files && this.files.length) {
        showSnackbar('Model file selected. Replace functionality requires backend integration.', 'info');
      }
      this.value = '';
    });
  }

  // ----- Profile -----
  function refreshProfile() {
    const user = getCurrentUser();
    document.getElementById('profile-name').textContent = (user && user.name) ? user.name : 'Admin';
    document.getElementById('profile-email').textContent = (user && user.email) ? user.email : '';
  }

  function handleProfileLogout() {
    showModal(
      'Logout',
      '<p>Are you sure you want to logout?</p>',
      '<button type="button" class="btn-text" data-action="cancel">Cancel</button>' +
      '<button type="button" class="btn-text" data-action="logout">Logout</button>'
    );
    modalContent.querySelector('[data-action="cancel"]').addEventListener('click', closeModal);
    modalContent.querySelector('[data-action="logout"]').addEventListener('click', function () {
      closeModal();
      setCurrentUser(null);
      showScreen('admin-login');
    });
  }

  // ----- Calendar -----
  let calendarState = {
    focused: new Date(),
    selected: new Date(),
    format: 'month',
  };

  function renderCalendar() {
    const year = calendarState.focused.getFullYear();
    const month = calendarState.focused.getMonth();
    const first = new Date(year, month, 1);
    const last = new Date(year, month + 1, 0);
    const startPad = (first.getDay() + 6) % 7;
    const daysInMonth = last.getDate();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let html = '<div class="calendar-nav">' +
      '<button type="button" data-step="-1">&lsaquo;</button>' +
      '<strong>' + first.toLocaleDateString('en-US', { month: 'long', year: 'numeric' }) + '</strong>' +
      '<button type="button" data-step="1">&rsaquo;</button>' +
      '</div>';
    html += '<table class="calendar-table"><thead><tr>';
    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].forEach(function (d) {
      html += '<th>' + d + '</th>';
    });
    html += '</tr></thead><tbody><tr>';

    let cell = 0;
    for (let i = 0; i < startPad; i++) {
      const d = new Date(year, month, 1 - (startPad - i));
      html += '<td class="other-month">' + d.getDate() + '</td>';
      cell++;
    }
    for (let d = 1; d <= daysInMonth; d++) {
      if (cell === 7) { html += '</tr><tr>'; cell = 0; }
      const date = new Date(year, month, d);
      date.setHours(0, 0, 0, 0);
      let cls = '';
      if (date.getTime() === today.getTime()) cls = 'today';
          else if (date.getTime() === calendarState.selected.getTime()) cls = 'selected';
      html += '<td class="' + cls + '" data-date="' + date.getTime() + '">' + d + '</td>';
      cell++;
    }
    while (cell < 7 && cell > 0) {
      html += '<td class="other-month"></td>';
      cell++;
    }
    html += '</tr></tbody></table>';

    document.getElementById('calendar-grid').innerHTML = html;

    document.getElementById('calendar-grid').querySelectorAll('[data-step]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        const step = parseInt(btn.getAttribute('data-step'), 10);
        const d = new Date(calendarState.focused);
        d.setMonth(d.getMonth() + step);
        calendarState.focused = d;
        renderCalendar();
      });
    });

    document.getElementById('calendar-grid').querySelectorAll('td[data-date]').forEach(function (td) {
      td.addEventListener('click', function () {
        calendarState.selected = new Date(parseInt(td.getAttribute('data-date'), 10));
        renderCalendar();
      });
    });

    document.querySelectorAll('.view-btn').forEach(function (btn) {
      btn.classList.toggle('active', btn.getAttribute('data-format') === calendarState.format);
      btn.onclick = function () {
        calendarState.format = btn.getAttribute('data-format');
        document.querySelectorAll('.view-btn').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
      };
    });

    const statusFilter = document.getElementById('filter-status').value;
    const typeFilter = document.getElementById('filter-type').value;
    let list = mockTreatments.filter(function (t) {
      const d = t.scheduleDate instanceof Date ? t.scheduleDate : new Date(t.scheduleDate);
      d.setHours(0, 0, 0, 0);
      return d.getTime() === calendarState.selected.getTime();
    });
    if (statusFilter) list = list.filter(function (t) { return t.status === statusFilter; });
    if (typeFilter) list = list.filter(function (t) { return t.type === typeFilter; });

    document.getElementById('selected-date-label').textContent =
      calendarState.selected.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

    const container = document.getElementById('calendar-treatments');
    if (list.length === 0) {
      container.innerHTML = '<p class="empty-state">No treatments for ' +
        calendarState.selected.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) + '</p>';
    } else {
      container.innerHTML = list.map(function (t) {
        let actions = '';
        if (t.status === 'pending') {
          actions = '<div class="treatment-card-actions">' +
            '<button type="button" class="btn btn-primary btn-complete" data-id="' + t.id + '">Mark Complete</button>' +
            '<button type="button" class="btn btn-outline btn-reschedule" data-id="' + t.id + '">Reschedule</button>' +
            '<button type="button" class="btn btn-outline danger btn-cancel" data-id="' + t.id + '">Cancel</button>' +
            '</div>';
        }
        return (
          '<div class="treatment-card" data-id="' + t.id + '">' +
            '<div class="treatment-card-header">' +
              '<p class="treatment-card-name">' + escapeHtml(t.userName || t.userId) + '</p>' +
              '<span class="treatment-status ' + t.status + '">' + t.status.toUpperCase() + '</span>' +
            '</div>' +
            '<p class="treatment-card-details">' + escapeHtml(t.type) + ': ' + escapeHtml(t.disease) + '</p>' +
            '<p class="treatment-card-details">' + (t.scheduleDate instanceof Date ? t.scheduleDate : new Date(t.scheduleDate)).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) + '</p>' +
            (t.notes ? '<p class="treatment-card-details">Notes: ' + escapeHtml(t.notes) + '</p>' : '') +
            actions +
          '</div>'
        );
      }).join('');

      container.querySelectorAll('.btn-complete').forEach(function (btn) {
        btn.addEventListener('click', function () {
          const t = mockTreatments.find(function (x) { return x.id === btn.getAttribute('data-id'); });
          if (t) { t.status = 'completed'; showSnackbar('Status updated to completed'); renderCalendar(); }
        });
      });
      container.querySelectorAll('.btn-cancel').forEach(function (btn) {
        btn.addEventListener('click', function () {
          const t = mockTreatments.find(function (x) { return x.id === btn.getAttribute('data-id'); });
          if (t) { t.status = 'cancelled'; showSnackbar('Status updated to cancelled'); renderCalendar(); }
        });
      });
      container.querySelectorAll('.btn-reschedule').forEach(function (btn) {
        btn.addEventListener('click', function () {
          showSnackbar('Reschedule: use a date picker in production', 'info');
        });
      });
    }
  }

  document.getElementById('filter-status').addEventListener('change', renderCalendar);
  document.getElementById('filter-type').addEventListener('change', renderCalendar);

  // ----- Soil & Weather -----
  function moistureColor(m) {
    if (m == null) return 'neutral';
    if (m < 30) return 'humidity-low';
    if (m > 70) return 'humidity-high';
    return 'humidity-ok';
  }

  function phColor(ph) {
    if (ph == null) return 'neutral';
    if (ph < 5.5) return 'ph-low';
    if (ph > 7.5) return 'ph-high';
    return 'ph-ok';
  }

  function renderSoilWeather() {
    const w = mockWeather;
    document.getElementById('weather-content').innerHTML = [
      ['thermostat', w.temperature + '°C', 'Temp'],
      ['water_drop', w.humidity + '%', 'Humidity'],
      ['cloud', w.condition, 'Condition'],
      ['grain', w.rainProbability + '%', 'Rain'],
      ['air', w.windSpeed + ' m/s', 'Wind'],
    ].map(function (row) {
      return (
        '<div class="weather-chip">' +
          '<span class="material-symbols-outlined">' + row[0] + '</span>' +
          '<div><span class="weather-chip-value">' + escapeHtml(row[1]) + '</span><br><span class="weather-chip-label">' + escapeHtml(row[2]) + '</span></div>' +
        '</div>'
      );
    }).join('');

    const soilHtml = mockFarmers.length === 0
      ? '<div class="card"><p style="text-align:center;margin:0">No farmers yet</p></div>'
      : mockFarmers.map(function (u) {
          const soil = mockSoilByUser[u.id] || {};
          const m = soil.moisture;
          const ph = soil.ph;
          const mStr = m != null ? m.toFixed(1) + '%' : '-';
          const phStr = ph != null ? ph.toFixed(1) : '-';
          return (
            '<div class="soil-card">' +
              '<p class="soil-card-title">' + escapeHtml(u.name) + '</p>' +
              (u.farmLocation ? '<p class="soil-card-location">' + escapeHtml(u.farmLocation) + '</p>' : '') +
              '<div class="soil-metrics">' +
                '<div class="soil-metric ' + moistureColor(m) + '">' +
                  '<div class="soil-metric-label"><span class="material-symbols-outlined">water_drop</span> Humidity</div>' +
                  '<div class="soil-metric-value">' + mStr + '</div>' +
                '</div>' +
                '<div class="soil-metric ' + phColor(ph) + '">' +
                  '<div class="soil-metric-label"><span class="material-symbols-outlined">science</span> pH (Acidity)</div>' +
                  '<div class="soil-metric-value">' + phStr + '</div>' +
                '</div>' +
              '</div>' +
            '</div>'
          );
        }).join('');
    document.getElementById('soil-cards').innerHTML = soilHtml;
  }

  document.getElementById('btn-soil-refresh').addEventListener('click', function () {
    renderSoilWeather();
    showSnackbar('Refreshed', 'success');
  });

  // ----- Global nav (data-nav) -----
  document.body.addEventListener('click', function (e) {
    const nav = e.target.closest('[data-nav]');
    if (nav) {
      e.preventDefault();
      showScreen(nav.getAttribute('data-nav'));
    }
  });

  // ----- Init -----
  document.getElementById('form-login').addEventListener('submit', handleLoginSubmit);
  document.querySelector('.toggle-pwd').addEventListener('click', togglePassword);
  document.getElementById('btn-logout').addEventListener('click', confirmLogout);
  document.getElementById('btn-add-farmer').addEventListener('click', showAddFarmerDialog);
  document.getElementById('btn-add-farmer-empty').addEventListener('click', showAddFarmerDialog);
  document.getElementById('btn-profile-logout').addEventListener('click', handleProfileLogout);
  modalOverlay.addEventListener('click', function (e) {
    if (e.target === modalOverlay) closeModal();
  });

  setupModelTrainer();

  runSplash();
})();
