require('dotenv').config();
const express = require('express');
const path = require('path');
const fetch = require('node-fetch');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

let amadeusToken = null;
let tokenExpiry = 0;

async function getAmadeusToken() {
  if (amadeusToken && Date.now() < tokenExpiry) return amadeusToken;

  const key = process.env.AMADEUS_API_KEY;
  const secret = process.env.AMADEUS_API_SECRET;
  if (!key || !secret || key === 'your_amadeus_api_key') return null;

  const res = await fetch('https://api.amadeus.com/v1/security/oauth2/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=client_credentials&client_id=${key}&client_secret=${secret}`
  });
  const data = await res.json();
  amadeusToken = data.access_token;
  tokenExpiry = Date.now() + (data.expires_in - 60) * 1000;
  return amadeusToken;
}

const EXCHANGE_APIS = [
  base => `https://api.frankfurter.app/latest?from=${base}`,
  base => `https://open.er-api.com/v6/latest/${base}`,
  base => `https://api.exchangerate-api.com/v4/latest/${base}`
];

async function fetchRates(base) {
  for (const buildUrl of EXCHANGE_APIS) {
    try {
      const url = buildUrl(base);
      const response = await fetch(url, { timeout: 5000 });
      if (!response.ok) continue;
      const data = await response.json();
      // Normalize response format
      if (data.rates) return { base, rates: data.rates };
    } catch (e) {
      continue;
    }
  }
  return null;
}

// Güncel döviz kurları (birden fazla ücretsiz API dener)
app.get('/api/exchange-rates', async (req, res) => {
  try {
    const base = req.query.base || 'TRY';
    const data = await fetchRates(base);
    if (data) return res.json(data);
    res.status(503).json({ error: 'Döviz kuru alınamadı', fallback: true });
  } catch (err) {
    res.status(500).json({ error: 'Döviz kuru alınamadı', details: err.message });
  }
});

// TRY bazlı tüm kurları al
app.get('/api/rates-to-try', async (req, res) => {
  try {
    const data = await fetchRates('TRY');
    if (data) return res.json(data);
    res.status(503).json({ error: 'Kurlar alınamadı', fallback: true });
  } catch (err) {
    res.status(500).json({ error: 'Kurlar alınamadı', details: err.message });
  }
});

// Uçuş arama (Amadeus API)
app.get('/api/flights', async (req, res) => {
  try {
    const token = await getAmadeusToken();
    if (!token) {
      return res.status(400).json({
        error: 'API_KEY_MISSING',
        message: 'Amadeus API anahtarı ayarlanmamış. .env dosyasına AMADEUS_API_KEY ve AMADEUS_API_SECRET ekleyin.'
      });
    }

    const { origin, destination, departDate, returnDate, adults } = req.query;
    const params = new URLSearchParams({
      originLocationCode: origin,
      destinationLocationCode: destination,
      departureDate: departDate,
      returnDate: returnDate || '',
      adults: adults || '1',
      currencyCode: 'EUR',
      max: '10'
    });
    if (!returnDate) params.delete('returnDate');

    const response = await fetch(
      `https://api.amadeus.com/v2/shopping/flight-offers?${params}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const data = await response.json();

    if (data.errors) {
      return res.status(400).json({ error: data.errors[0].detail });
    }

    const flights = (data.data || []).map(offer => ({
      price: parseFloat(offer.price.total),
      currency: offer.price.currency,
      airlines: offer.validatingAirlineCodes,
      outbound: {
        departure: offer.itineraries[0].segments[0].departure,
        arrival: offer.itineraries[0].segments[offer.itineraries[0].segments.length - 1].arrival,
        duration: offer.itineraries[0].duration,
        stops: offer.itineraries[0].segments.length - 1
      },
      inbound: offer.itineraries[1] ? {
        departure: offer.itineraries[1].segments[0].departure,
        arrival: offer.itineraries[1].segments[offer.itineraries[1].segments.length - 1].arrival,
        duration: offer.itineraries[1].duration,
        stops: offer.itineraries[1].segments.length - 1
      } : null
    }));

    res.json({ flights, dictionaries: data.dictionaries });
  } catch (err) {
    res.status(500).json({ error: 'Uçuş araması başarısız', details: err.message });
  }
});

// Otel arama (Amadeus API)
app.get('/api/hotels', async (req, res) => {
  try {
    const token = await getAmadeusToken();
    if (!token) {
      return res.status(400).json({
        error: 'API_KEY_MISSING',
        message: 'Amadeus API anahtarı ayarlanmamış.'
      });
    }

    const { cityCode, checkIn, checkOut, adults, rooms } = req.query;

    // Önce şehirdeki otelleri bul
    const hotelsRes = await fetch(
      `https://api.amadeus.com/v1/reference-data/locations/hotels/by-city?cityCode=${cityCode}&radius=20&radiusUnit=KM&hotelSource=ALL`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const hotelsData = await hotelsRes.json();

    if (!hotelsData.data || hotelsData.data.length === 0) {
      return res.json({ hotels: [] });
    }

    // İlk 20 otelin fiyatlarını al
    const hotelIds = hotelsData.data.slice(0, 20).map(h => h.hotelId).join(',');
    const params = new URLSearchParams({
      hotelIds,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      adults: adults || '2',
      roomQuantity: rooms || '1',
      currency: 'EUR'
    });

    const offersRes = await fetch(
      `https://api.amadeus.com/v3/shopping/hotel-offers?${params}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const offersData = await offersRes.json();

    if (offersData.errors) {
      return res.status(400).json({ error: offersData.errors[0].detail });
    }

    const hotels = (offersData.data || []).map(hotel => ({
      name: hotel.hotel.name,
      hotelId: hotel.hotel.hotelId,
      rating: hotel.hotel.rating,
      offers: (hotel.offers || []).map(offer => ({
        price: parseFloat(offer.price.total),
        currency: offer.price.currency,
        room: offer.room?.description?.text || 'Standart Oda',
        checkIn: offer.checkInDate,
        checkOut: offer.checkOutDate,
        cancellation: offer.policies?.cancellation?.description?.text || 'Bilgi yok'
      }))
    })).filter(h => h.offers.length > 0);

    res.json({ hotels });
  } catch (err) {
    res.status(500).json({ error: 'Otel araması başarısız', details: err.message });
  }
});

// Popüler destinasyonlar
app.get('/api/destinations', (req, res) => {
  res.json([
    { code: 'BCN', city: 'Barselona', country: 'İspanya', currency: 'EUR' },
    { code: 'FCO', city: 'Roma', country: 'İtalya', currency: 'EUR' },
    { code: 'CDG', city: 'Paris', country: 'Fransa', currency: 'EUR' },
    { code: 'LHR', city: 'Londra', country: 'İngiltere', currency: 'GBP' },
    { code: 'AMS', city: 'Amsterdam', country: 'Hollanda', currency: 'EUR' },
    { code: 'ATH', city: 'Atina', country: 'Yunanistan', currency: 'EUR' },
    { code: 'LIS', city: 'Lizbon', country: 'Portekiz', currency: 'EUR' },
    { code: 'PRG', city: 'Prag', country: 'Çekya', currency: 'CZK' },
    { code: 'BUD', city: 'Budapeşte', country: 'Macaristan', currency: 'HUF' },
    { code: 'VIE', city: 'Viyana', country: 'Avusturya', currency: 'EUR' },
    { code: 'DXB', city: 'Dubai', country: 'BAE', currency: 'AED' },
    { code: 'BKK', city: 'Bangkok', country: 'Tayland', currency: 'THB' },
    { code: 'TBS', city: 'Tiflis', country: 'Gürcistan', currency: 'GEL' },
    { code: 'SOF', city: 'Sofya', country: 'Bulgaristan', currency: 'BGN' },
    { code: 'BEG', city: 'Belgrad', country: 'Sırbistan', currency: 'RSD' }
  ]);
});

app.listen(PORT, () => {
  console.log(`🌍 Tatil Maliyet Karşılaştırıcı çalışıyor: http://localhost:${PORT}`);
});
