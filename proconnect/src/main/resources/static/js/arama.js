document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('search-input').addEventListener('keydown', function(e) {
        if (e.key === 'Enter') hizmetAra();
    });

    // Dropdown dışına tıklanırsa kapat
    document.addEventListener('click', function(e) {
        const wrapper = document.querySelector('.search-wrapper');
        if (wrapper && !wrapper.contains(e.target)) {
            document.getElementById('search-dropdown').style.display = 'none';
        }
    });
});

async function hizmetAra() {
    const query = document.getElementById('search-input').value.trim();
    const dropdown = document.getElementById('search-dropdown');
    if (!query) {
        dropdown.style.display = 'none';
        return;
    }

    // Yükleniyor göster
    dropdown.style.display = 'block';
    dropdown.innerHTML = '<div class="dropdown-loading">Aranıyor...</div>';

    try {
        const response = await fetch('/ara', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({
                query: query,
                lat: kullaniciLat,
                lng: kullaniciLng,
                sehir: kullaniciSehir
            })
        });

        if (!response.ok) {
            dropdown.innerHTML = '<div class="dropdown-empty">Bir hata oluştu.</div>';
            return;
        }

        const data = await response.json();

        if (data.sonuclar && data.sonuclar.length > 0) {
            dropdown.innerHTML = data.sonuclar.map(function(ilan) {
                const konum = ilan.ilce && ilan.sehir
                    ? ilan.ilce + ', ' + ilan.sehir
                    : (ilan.sehir || 'Konum belirtilmemiş');
                const butce = ilan.butce ? ilan.butce + ' ₺' : '';
                return '<div class="dropdown-item" onclick="ilanSec(' + ilan.id + ')">' +
                    '<div class="dropdown-item-left">' +
                        '<i class="fa-solid fa-briefcase"></i>' +
                        '<div>' +
                            '<div class="dropdown-item-title">' + ilan.baslik + '</div>' +
                            '<div class="dropdown-item-sub">' + konum + '</div>' +
                        '</div>' +
                    '</div>' +
                    '<div class="dropdown-item-right">' + butce + '</div>' +
                '</div>';
            }).join('');
        } else {
            dropdown.innerHTML = '<div class="dropdown-empty">Sonuç bulunamadı.</div>';
        }
    } catch (error) {
        console.error('Arama hatası:', error);
        dropdown.innerHTML = '<div class="dropdown-empty">Sunucuya bağlanılamadı.</div>';
    }
}

function ilanSec(ilanId) {
    document.getElementById('search-dropdown').style.display = 'none';
    const card = document.querySelector('[data-ilan-id="' + ilanId + '"]');
    if (card) {
        card.scrollIntoView({ behavior: 'smooth', block: 'center' });
        card.style.outline = '3px solid var(--accent)';
        card.style.outlineOffset = '4px';
        setTimeout(function() {
            card.style.outline = '';
            card.style.outlineOffset = '';
        }, 2000);
    }
}
