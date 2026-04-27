// Kullanıcı konumu (cerez-consent.js'den veya sessionStorage'dan)
let kullaniciLat = null;
let kullaniciLng = null;

// Sayfa yüklenince konumu al (izin verildiyse)
document.addEventListener('DOMContentLoaded', function() {
    if (navigator.geolocation && localStorage.getItem('cerezOnay') === 'kabul') {
        navigator.geolocation.getCurrentPosition(function(pos) {
            kullaniciLat = pos.coords.latitude;
            kullaniciLng = pos.coords.longitude;
        });
    }

    // Enter tuşu ile arama
    document.getElementById('search-input').addEventListener('keydown', function(e) {
        if (e.key === 'Enter') hizmetAra();
    });
});

async function hizmetAra() {
    const query = document.getElementById('search-input').value.trim();
    if (!query) return;

    const sonuclarDiv = document.getElementById('arama-sonuclari');
    const sonucGrid = document.getElementById('sonuc-grid');
    const aiOneri = document.getElementById('ai-oneri');
    const sonucYok = document.getElementById('sonuc-yok');

    // Yükleniyor göster
    sonuclarDiv.style.display = 'block';
    aiOneri.textContent = 'Aranıyor...';
    sonucGrid.innerHTML = '';
    sonucYok.style.display = 'none';

    // Smooth scroll ile sonuçlara git
    sonuclarDiv.scrollIntoView({ behavior: 'smooth' });

    try {
        const response = await fetch('/ara', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({
                query: query,
                lat: kullaniciLat,
                lng: kullaniciLng
            })
        });

        if (!response.ok) {
            aiOneri.textContent = 'Arama sırasında bir hata oluştu.';
            return;
        }

        const data = await response.json();

        // AI önerisi göster
        if (data.aiOneri) {
            aiOneri.innerHTML = '<i class="fa-solid fa-robot"></i> ' + data.aiOneri;
        } else {
            aiOneri.textContent = '';
        }

        // Sonuçları göster
        if (data.sonuclar && data.sonuclar.length > 0) {
            sonucGrid.innerHTML = data.sonuclar.map(function(ilan) {
                const konum = ilan.ilce && ilan.sehir
                    ? ilan.ilce + ', ' + ilan.sehir
                    : (ilan.sehir || '');
                return '<article class="card">' +
                    '<div class="card-media"></div>' +
                    '<div class="card-body">' +
                        '<h3 class="card-title">' + ilan.baslik + '</h3>' +
                        '<div class="meta"><span><i class="fa-solid fa-location-dot"></i> ' + konum + '</span></div>' +
                        '<div class="meta"><span><i class="fa-solid fa-turkish-lira-sign"></i> ' + (ilan.butce || 'Belirtilmemiş') + '</span></div>' +
                        '<p style="font-size:13px;color:#666;margin:6px 0 0;">' + (ilan.aciklama || '').substring(0, 100) + '</p>' +
                    '</div>' +
                '</article>';
            }).join('');
            sonucYok.style.display = 'none';
        } else {
            sonucGrid.innerHTML = '';
            sonucYok.style.display = 'block';
        }
    } catch (error) {
        console.error('Arama hatası:', error);
        aiOneri.textContent = 'Sunucuya bağlanılamadı.';
    }
}
