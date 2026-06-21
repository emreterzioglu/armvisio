let exchangeRates = {};
let tryRates = {};
let selectedFlight = null;
let selectedHotel = null;

// Fallback rates (yaklaşık değerler - API'ye ulaşılamazsa kullanılır)
const FALLBACK_RATES = {
  EUR: 0.0261, USD: 0.0292, GBP: 0.0222, CHF: 0.0257,
  CZK: 0.649, HUF: 10.45, BGN: 0.0511, GEL: 0.0791,
  THB: 0.973, AED: 0.107, CZK: 0.649, RSD: 3.05
};

document.addEventListener('DOMContentLoaded', () => {
  loadExchangeRates();
  loadDestinations();
  setDefaultDates();

  document.getElementById('search-btn').addEventListener('click', performSearch);
  document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => switchTab(tab.dataset.tab));
  });
});

function setDefaultDates() {
  const today = new Date();
  const depart = new Date(today);
  depart.setDate(today.getDate() + 30);
  const ret = new Date(depart);
  ret.setDate(depart.getDate() + 7);

  document.getElementById('depart-date').value = formatDate(depart);
  document.getElementById('return-date').value = formatDate(ret);
}

function formatDate(date) {
  return date.toISOString().split('T')[0];
}

async function loadExchangeRates() {
  try {
    const res = await fetch('/api/rates-to-try');
    const data = await res.json();
    if (data.rates) {
      tryRates = data.rates;
      renderRates(data.rates);
    } else {
      throw new Error('fallback');
    }
  } catch (err) {
    tryRates = FALLBACK_RATES;
    renderRates(FALLBACK_RATES);
    document.querySelector('.rates-note').textContent =
      'Yaklaşık değerler gösterilmektedir. Güncel kurlar için internet bağlantısı gerekli.';
  }
}

function renderRates(rates) {
  const important = ['EUR', 'USD', 'GBP', 'CHF', 'CZK', 'HUF', 'BGN', 'GEL', 'THB', 'AED'];
  const container = document.getElementById('rates-container');
  container.innerHTML = important
    .filter(c => rates[c])
    .map(c => `
      <div class="rate-card">
        <div class="currency">${c}</div>
        <div class="value">${rates[c].toFixed(4)}</div>
      </div>
    `).join('');
}

function tryToEur(tryAmount) {
  if (tryRates.EUR) return tryAmount * tryRates.EUR;
  return tryAmount;
}

function eurToTry(eurAmount) {
  if (tryRates.EUR) return eurAmount / tryRates.EUR;
  return eurAmount;
}

function currencyToTry(amount, currency) {
  if (currency === 'TRY') return amount;
  if (currency === 'EUR') return eurToTry(amount);
  if (tryRates[currency]) return amount / tryRates[currency];
  return amount;
}

async function loadDestinations() {
  try {
    const res = await fetch('/api/destinations');
    const destinations = await res.json();

    const select = document.getElementById('destination');
    destinations.forEach(d => {
      const opt = document.createElement('option');
      opt.value = d.code;
      opt.textContent = `${d.city}, ${d.country} (${d.code})`;
      opt.dataset.currency = d.currency;
      select.appendChild(opt);
    });

    const grid = document.getElementById('destinations-grid');
    grid.innerHTML = destinations.map(d => `
      <div class="dest-card" data-code="${d.code}">
        <div class="city">${d.city}</div>
        <div class="country">${d.country}</div>
      </div>
    `).join('');

    grid.querySelectorAll('.dest-card').forEach(card => {
      card.addEventListener('click', () => {
        document.getElementById('destination').value = card.dataset.code;
        window.scrollTo({ top: 0, behavior: 'smooth' });
      });
    });
  } catch (err) {
    console.error('Destinasyonlar yüklenemedi:', err);
  }
}

async function performSearch() {
  const origin = document.getElementById('origin').value.toUpperCase().trim();
  const destination = document.getElementById('destination').value;
  const departDate = document.getElementById('depart-date').value;
  const returnDate = document.getElementById('return-date').value;
  const adults = document.getElementById('adults').value;
  const rooms = document.getElementById('rooms').value;

  if (!origin || !destination || !departDate || !returnDate) {
    alert('Lütfen tüm alanları doldurun.');
    return;
  }

  const btn = document.getElementById('search-btn');
  btn.disabled = true;
  btn.textContent = 'Aranıyor...';

  document.getElementById('results').style.display = 'block';
  document.getElementById('flights-list').innerHTML = '<p class="loading">Uçuşlar aranıyor...</p>';
  document.getElementById('hotels-list').innerHTML = '<p class="loading">Oteller aranıyor...</p>';

  selectedFlight = null;
  selectedHotel = null;

  await Promise.all([
    searchFlights(origin, destination, departDate, returnDate, adults),
    searchHotels(destination, departDate, returnDate, adults, rooms)
  ]);

  btn.disabled = false;
  btn.textContent = 'Ara ve Karşılaştır';
  updateSummary();
}

async function searchFlights(origin, destination, departDate, returnDate, adults) {
  try {
    const params = new URLSearchParams({ origin, destination, departDate, returnDate, adults });
    const res = await fetch(`/api/flights?${params}`);
    const data = await res.json();

    if (data.error === 'API_KEY_MISSING') {
      document.getElementById('flights-list').innerHTML = `
        <div class="api-warning">
          <strong>API Anahtarı Gerekli</strong><br>
          Uçuş araması için Amadeus API anahtarı gereklidir.<br><br>
          <strong>Ücretsiz kayıt:</strong> <a href="https://developers.amadeus.com" target="_blank" style="color:#64b5f6">developers.amadeus.com</a><br>
          Self-Service tier ile aylık 500 ücretsiz istek hakkınız var.<br><br>
          Kayıt sonrası <code>.env</code> dosyasına API key ve secret'ı ekleyin.
        </div>`;
      return;
    }

    if (data.error) {
      document.getElementById('flights-list').innerHTML = `<p class="error-msg">${data.error}</p>`;
      return;
    }

    if (!data.flights || data.flights.length === 0) {
      document.getElementById('flights-list').innerHTML = '<p class="loading">Bu tarihler için uçuş bulunamadı.</p>';
      return;
    }

    const container = document.getElementById('flights-list');
    container.innerHTML = data.flights.map((f, i) => {
      const tryPrice = currencyToTry(f.price, f.currency);
      return `
        <div class="flight-card ${i === 0 ? 'selected' : ''}" data-index="${i}" data-price="${f.price}" data-currency="${f.currency}">
          <div class="price">${f.price.toFixed(0)} ${f.currency}</div>
          <div class="price-try">≈ ${tryPrice.toFixed(0)} TRY / kişi</div>
          <div class="route">
            ${f.outbound.departure.iataCode} → ${f.outbound.arrival.iataCode}
          </div>
          <div class="details">
            Havayolu: ${f.airlines.join(', ')}<br>
            Süre: ${formatDuration(f.outbound.duration)}<br>
            Aktarma: ${f.outbound.stops === 0 ? 'Direkt' : f.outbound.stops + ' aktarma'}<br>
            ${f.inbound ? `Dönüş: ${formatDuration(f.inbound.duration)}, ${f.inbound.stops === 0 ? 'Direkt' : f.inbound.stops + ' aktarma'}` : ''}
          </div>
        </div>
      `;
    }).join('');

    if (data.flights.length > 0) {
      selectedFlight = data.flights[0];
    }

    container.querySelectorAll('.flight-card').forEach(card => {
      card.addEventListener('click', () => {
        container.querySelectorAll('.flight-card').forEach(c => c.classList.remove('selected'));
        card.classList.add('selected');
        selectedFlight = data.flights[card.dataset.index];
        updateSummary();
      });
    });
  } catch (err) {
    document.getElementById('flights-list').innerHTML = `<p class="error-msg">Hata: ${err.message}</p>`;
  }
}

async function searchHotels(cityCode, checkIn, checkOut, adults, rooms) {
  try {
    const params = new URLSearchParams({ cityCode, checkIn, checkOut, adults, rooms });
    const res = await fetch(`/api/hotels?${params}`);
    const data = await res.json();

    if (data.error === 'API_KEY_MISSING') {
      document.getElementById('hotels-list').innerHTML = `
        <div class="api-warning">
          <strong>API Anahtarı Gerekli</strong><br>
          Otel araması için Amadeus API anahtarı gereklidir.<br><br>
          <strong>Ücretsiz kayıt:</strong> <a href="https://developers.amadeus.com" target="_blank" style="color:#64b5f6">developers.amadeus.com</a>
        </div>`;
      return;
    }

    if (data.error) {
      document.getElementById('hotels-list').innerHTML = `<p class="error-msg">${data.error}</p>`;
      return;
    }

    if (!data.hotels || data.hotels.length === 0) {
      document.getElementById('hotels-list').innerHTML = '<p class="loading">Bu tarihler için otel bulunamadı.</p>';
      return;
    }

    const container = document.getElementById('hotels-list');
    container.innerHTML = data.hotels.map((h, i) => {
      const offer = h.offers[0];
      const tryPrice = currencyToTry(offer.price, offer.currency);
      return `
        <div class="hotel-card ${i === 0 ? 'selected' : ''}" data-index="${i}" data-price="${offer.price}" data-currency="${offer.currency}">
          <div class="name">${h.name}</div>
          ${h.rating ? `<div class="rating">${'★'.repeat(parseInt(h.rating))}${'☆'.repeat(5-parseInt(h.rating))}</div>` : ''}
          <div class="price">${offer.price.toFixed(0)} ${offer.currency}</div>
          <div class="price-try">≈ ${tryPrice.toFixed(0)} TRY / toplam konaklama</div>
          <div class="details">
            Oda: ${offer.room}<br>
            Giriş: ${offer.checkIn} - Çıkış: ${offer.checkOut}<br>
            İptal: ${offer.cancellation}
          </div>
        </div>
      `;
    }).join('');

    if (data.hotels.length > 0) {
      selectedHotel = { hotel: data.hotels[0], offer: data.hotels[0].offers[0] };
    }

    container.querySelectorAll('.hotel-card').forEach(card => {
      card.addEventListener('click', () => {
        container.querySelectorAll('.hotel-card').forEach(c => c.classList.remove('selected'));
        card.classList.add('selected');
        const h = data.hotels[card.dataset.index];
        selectedHotel = { hotel: h, offer: h.offers[0] };
        updateSummary();
      });
    });
  } catch (err) {
    document.getElementById('hotels-list').innerHTML = `<p class="error-msg">Hata: ${err.message}</p>`;
  }
}

function updateSummary() {
  const adults = parseInt(document.getElementById('adults').value) || 1;
  const content = document.getElementById('summary-content');

  if (!selectedFlight && !selectedHotel) {
    content.innerHTML = '<p class="loading">Uçuş veya otel seçimi yapın.</p>';
    return;
  }

  let flightTotal = 0;
  let hotelTotal = 0;
  let rows = '';

  if (selectedFlight) {
    const perPerson = currencyToTry(selectedFlight.price, selectedFlight.currency);
    flightTotal = perPerson * adults;
    rows += `
      <div class="summary-row">
        <span>Uçak bileti (${adults} kişi × ${selectedFlight.price.toFixed(0)} ${selectedFlight.currency})</span>
        <span>${flightTotal.toFixed(0)} TRY</span>
      </div>`;
  }

  if (selectedHotel) {
    hotelTotal = currencyToTry(selectedHotel.offer.price, selectedHotel.offer.currency);
    rows += `
      <div class="summary-row">
        <span>Konaklama (${selectedHotel.hotel.name})</span>
        <span>${hotelTotal.toFixed(0)} TRY</span>
      </div>`;
  }

  const total = flightTotal + hotelTotal;

  content.innerHTML = `
    <div class="summary-box">
      <h3>Tahmini Toplam Maliyet</h3>
      ${rows}
      <div class="summary-row total">
        <span>TOPLAM</span>
        <span>${total.toFixed(0)} TRY</span>
      </div>
      <div class="summary-row" style="color:#78909c; font-size:0.85rem;">
        <span>EUR karşılığı</span>
        <span>≈ ${tryToEur(total).toFixed(0)} EUR</span>
      </div>
    </div>
  `;
}

function switchTab(tabName) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
  document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
  document.getElementById(`tab-${tabName}`).classList.add('active');
}

function formatDuration(iso) {
  if (!iso) return '';
  const match = iso.match(/PT(\d+H)?(\d+M)?/);
  if (!match) return iso;
  const hours = match[1] ? match[1].replace('H', '') + 'sa ' : '';
  const mins = match[2] ? match[2].replace('M', '') + 'dk' : '';
  return hours + mins;
}
