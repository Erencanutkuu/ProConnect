let kullaniciLat = null;
let kullaniciLng = null;
let kullaniciSehir = null;

document.addEventListener('DOMContentLoaded', async function() {
    // Konum al ve şehir tespit et
    if (navigator.geolocation && localStorage.getItem('cerezOnay') === 'kabul') {
        try {
            const pos = await new Promise(function(resolve, reject) {
                navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 5000 });
            });
            kullaniciLat = pos.coords.latitude;
            kullaniciLng = pos.coords.longitude;

            // Nominatim ile şehir bul
            const geoRes = await fetch('https://nominatim.openstreetmap.org/reverse?lat=' + kullaniciLat + '&lon=' + kullaniciLng + '&format=json&accept-language=tr');
            const geoData = await geoRes.json();
            kullaniciSehir = geoData.address.province || geoData.address.city || geoData.address.state || '';
        } catch (e) {
            // konum alınamadı, devam et
        }
    }

    ilanlariYukle();
    sehirleriYukle();
});

async function ilanlariYukle() {
    const grid = document.getElementById('rezervasyon');

    // Mevcut ilan kartlarını temizle (ilan-olustur-card hariç)
    grid.querySelectorAll('article.card:not(.ilan-olustur-card), #ilan-yukle').forEach(function(el) { el.remove(); });

    try {
        // Konum/şehir varsa yakınlık sıralaması için gönder
        let url = '/ilan/aktif';
        const params = [];
        if (kullaniciLat && kullaniciLng) {
            params.push('lat=' + kullaniciLat);
            params.push('lng=' + kullaniciLng);
        }
        if (kullaniciSehir) {
            params.push('sehir=' + encodeURIComponent(kullaniciSehir));
        }
        if (params.length > 0) url += '?' + params.join('&');

        const response = await fetch(url);
        const ilanlar = await response.json();

        if (ilanlar.length === 0) {
            grid.insertAdjacentHTML('beforeend', '<p id="ilan-yukle" style="text-align:center; color:var(--muted); grid-column:1/-1;">Henüz aktif ilan bulunmuyor.</p>');
            return;
        }

        ilanlar.forEach(function(ilan) {
            const konum = ilan.ilce && ilan.sehir
                ? ilan.ilce + ', ' + ilan.sehir
                : (ilan.sehir || '');
            const butce = ilan.butce ? ilan.butce + ' ₺' : '';
            const usta = ilan.olusturanKullanici
                ? ilan.olusturanKullanici.ad + ' ' + ilan.olusturanKullanici.soyad
                : '';

            const html = '<article class="card" data-ilan-id="' + ilan.id + '">' +
                '<div class="card-media"></div>' +
                '<div class="card-action">' +
                    '<a class="action-btn" href="#" onclick="rezervasyonYap(event, ' + ilan.id + ')">Rezervasyon</a>' +
                '</div>' +
                '<div class="card-body">' +
                    '<h3 class="card-title">' + ilan.baslik + '</h3>' +
                    (usta ? '<div class="meta"><span><i class="fa-solid fa-user"></i> ' + usta + '</span></div>' : '') +
                    (konum ? '<div class="meta"><span><i class="fa-solid fa-location-dot"></i> ' + konum + '</span></div>' : '') +
                    (butce ? '<div class="meta"><span><i class="fa-solid fa-turkish-lira-sign"></i> ' + butce + '</span></div>' : '') +
                    '<p style="font-size:13px;color:#666;margin:6px 0 0;">' + (ilan.aciklama || '').substring(0, 100) + '</p>' +
                '</div>' +
            '</article>';

            grid.insertAdjacentHTML('beforeend', html);
        });
    } catch (error) {
        grid.insertAdjacentHTML('beforeend', '<p id="ilan-yukle" style="text-align:center; color:red; grid-column:1/-1;">İlanlar yüklenemedi.</p>');
    }
}

async function ilanOlustur() {
    const veri = {
        baslik: document.getElementById('ilan-baslik').value.trim(),
        aciklama: document.getElementById('ilan-aciklama').value.trim(),
        butce: document.getElementById('ilan-butce').value || null,
        sehir: document.getElementById('ilan-sehir').value.trim(),
        ilce: document.getElementById('ilan-ilce').value.trim(),
        konumLat: kullaniciLat,
        konumLng: kullaniciLng
    };

    const mesajEl = document.getElementById('ilan-mesaj');

    if (!veri.baslik || !veri.aciklama) {
        mesajEl.textContent = 'Başlık ve açıklama zorunludur.';
        mesajEl.style.color = 'red';
        return;
    }

    try {
        const response = await fetch('/ilan/olustur', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify(veri)
        });

        if (response.ok) {
            mesajEl.textContent = 'İlan oluşturuldu!';
            mesajEl.style.color = 'green';
            document.getElementById('ilan-baslik').value = '';
            document.getElementById('ilan-aciklama').value = '';
            document.getElementById('ilan-butce').value = '';
            document.getElementById('ilan-sehir').value = '';
            document.getElementById('ilan-ilce').value = '';
            // yeni ilanı sayfaya ekle
            ilanlariYukle();
        } else {
            const raw = await response.text();
            mesajEl.textContent = raw || 'Hata oluştu!';
            mesajEl.style.color = 'red';
        }
    } catch (error) {
        mesajEl.textContent = 'Sunucuya bağlanılamadı.';
        mesajEl.style.color = 'red';
    }
}

function sehirleriYukle() {
    var sehirSelect = document.getElementById('ilan-sehir');
    if (!sehirSelect || typeof sehirIlceler === 'undefined') return;

    Object.keys(sehirIlceler).sort(function(a, b) {
        return a.localeCompare(b, 'tr');
    }).forEach(function(sehir) {
        var opt = document.createElement('option');
        opt.value = sehir;
        opt.textContent = sehir;
        sehirSelect.appendChild(opt);
    });
}

function ilceleriGuncelle() {
    var sehirSelect = document.getElementById('ilan-sehir');
    var ilceSelect = document.getElementById('ilan-ilce');
    if (!sehirSelect || !ilceSelect) return;

    var sehir = sehirSelect.value;
    ilceSelect.innerHTML = '';

    if (!sehir) {
        ilceSelect.innerHTML = '<option value="">Önce şehir seçin</option>';
        return;
    }

    ilceSelect.innerHTML = '<option value="">İlçe Seçin</option>';
    var ilceler = sehirIlceler[sehir] || [];
    ilceler.forEach(function(ilce) {
        var opt = document.createElement('option');
        opt.value = ilce;
        opt.textContent = ilce;
        ilceSelect.appendChild(opt);
    });
}

async function rezervasyonYap(event, ilanId) {
    event.preventDefault();

    if (!girisYapildi) {
        window.location.href = 'login.html';
        return;
    }

    try {
        const response = await fetch('/rezervasyon/olustur', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ ilanId: ilanId })
        });

        if (response.ok) {
            const card = document.querySelector('[data-ilan-id="' + ilanId + '"]');
            const actionDiv = card.querySelector('.card-action');
            actionDiv.innerHTML = '<span class="action-btn" style="background:#f0ad4e;">Rezervasyon Yapıldı</span>';
            actionDiv.style.opacity = '1';
            actionDiv.style.pointerEvents = 'none';
        } else {
            const data = await response.text();
            let mesaj = 'Hata oluştu';
            try {
                const json = JSON.parse(data);
                mesaj = json.message || mesaj;
            } catch (e) {
                mesaj = data || mesaj;
            }
            alert(mesaj);
        }
    } catch (error) {
        alert('Sunucuya bağlanılamadı.');
    }
}
