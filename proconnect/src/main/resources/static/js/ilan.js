let kullaniciLat = null;
let kullaniciLng = null;
let kullaniciSehir = null;
let cachedRezvIlanIds = null; // Rezervasyon cache - tekrar API çağrısını önler

function getFavorilerKey() {
    return window.aktifKullaniciEposta ? 'favoriler_' + window.aktifKullaniciEposta : 'favoriler_anon';
}

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

    sehirleriYukle();
});

window.addEventListener('authLoaded', function() {
    ilanlariYukle();
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
        window.tumIlanlar = ilanlar; // İlan detaylarına modalden erişmek için

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

            let isFavori = false;
            try {
                const favs = JSON.parse(localStorage.getItem(getFavorilerKey()) || '[]');
                isFavori = favs.includes(ilan.id);
            } catch(e){}

            // Bu ilan bana mi ait?
            const benimIlanim = ilan.olusturanKullanici && window.aktifKullaniciEposta === ilan.olusturanKullanici.eposta;

            const cardMediaHtml = ilan.gorselYolu
                ? '<div class="card-media" style="background: url(\'/uploads/' + ilan.gorselYolu + '\') center/cover no-repeat;"></div>'
                : '<div class="card-media"></div>';

            const silBtnHtml = benimIlanim
                ? '<div class="delete-icon" onclick="ilanSil(event, ' + ilan.id + ')" title="İlanı Sil">' +
                    '<i class="fa-solid fa-trash"></i>' +
                '</div>'
                : '';

            const html = '<article class="card" data-ilan-id="' + ilan.id + '">' +
                silBtnHtml +
                '<div class="favorite-icon ' + (isFavori ? 'active' : '') + '" onclick="toggleFavori(event, ' + ilan.id + ')" title="Favoriye Ekle/Çıkar">' +
                    '<i class="' + (isFavori ? 'fa-solid' : 'fa-regular') + ' fa-heart"></i>' +
                '</div>' +
                cardMediaHtml +
                '<div class="card-action">' +
                    '<a class="action-btn" href="#" onclick="ilanDetayAc(event, ' + ilan.id + ')">Rezervasyon</a>' +
                '</div>' +
                '<div class="card-body">' +
                    '<h3 class="card-title">' + ilan.baslik + '</h3>' +
                    (usta ? '<div class="meta"><span><i class="fa-solid fa-user"></i> ' + usta + '</span></div>' : '') +
                    (konum ? '<div class="meta"><span><i class="fa-solid fa-location-dot"></i> ' + konum + '</span></div>' : '') +
                    (butce ? '<div class="meta"><span><i class="fa-solid fa-turkish-lira-sign"></i> ' + butce + '</span></div>' : '') +
                    '<p class="card-desc">' + (ilan.aciklama || '').substring(0, 100) + '</p>' +
                '</div>' +
            '</article>';

            grid.insertAdjacentHTML('beforeend', html);
        });
        
        // Giriş yapılmışsa, mevcut rezervasyonları kontrol et ve kartları güncelle
        if (girisYapildi) {
            try {
                const rezvRes = await fetch('/rezervasyon/benimkiler', { credentials: 'include' });
                if (rezvRes.ok) {
                    const rezvlar = await rezvRes.json();
                    cachedRezvIlanIds = rezvlar.filter(r => r.durum !== 'IPTAL').map(r => r.ilan ? r.ilan.id : null).filter(Boolean);
                    cachedRezvIlanIds.forEach(function(rIlanId) {
                        const card = document.querySelector('[data-ilan-id="' + rIlanId + '"]');
                        if (card) {
                            const actionDiv = card.querySelector('.card-action');
                            if (actionDiv) {
                                actionDiv.innerHTML = '<span class="action-btn action-btn-yapildi"><i class="fa-solid fa-check"></i> Rezervasyon Yapıldı</span>';
                                actionDiv.style.opacity = '1';
                                actionDiv.style.pointerEvents = 'none';
                            }
                        }
                    });
                }
            } catch(e) { /* sessizce devam */ }
        }
    } catch (error) {
        grid.insertAdjacentHTML('beforeend', '<p id="ilan-yukle" style="text-align:center; color:red; grid-column:1/-1;">İlanlar yüklenemedi.</p>');
    }
}

async function ilanOlustur() {
    const baslik = document.getElementById('ilan-baslik').value.trim();
    const aciklama = document.getElementById('ilan-aciklama').value.trim();
    const butce = document.getElementById('ilan-butce').value || null;
    const sehir = document.getElementById('ilan-sehir').value.trim();
    const ilce = document.getElementById('ilan-ilce').value.trim();
    const gorselInput = document.getElementById('ilan-gorsel');

    const mesajEl = document.getElementById('ilan-mesaj');

    if (!baslik || !aciklama) {
        mesajEl.textContent = 'Başlık ve açıklama zorunludur.';
        mesajEl.style.color = 'red';
        return;
    }

    const formData = new FormData();
    formData.append('baslik', baslik);
    formData.append('aciklama', aciklama);
    if (butce) formData.append('butce', butce);
    if (sehir) formData.append('sehir', sehir);
    if (ilce) formData.append('ilce', ilce);
    if (kullaniciLat) formData.append('konumLat', kullaniciLat);
    if (kullaniciLng) formData.append('konumLng', kullaniciLng);

    if (gorselInput && gorselInput.files.length > 0) {
        formData.append('gorsel', gorselInput.files[0]);
    }

    try {
        const response = await fetch('/ilan/olustur', {
            method: 'POST',
            // FormData kullanırken Content-Type belirtilmez (tarayıcı boundary ile ayarlar)
            credentials: 'include',
            body: formData
        });

        if (response.ok) {
            mesajEl.textContent = 'İlan oluşturuldu!';
            mesajEl.style.color = 'green';
            document.getElementById('ilan-baslik').value = '';
            document.getElementById('ilan-aciklama').value = '';
            document.getElementById('ilan-butce').value = '';
            document.getElementById('ilan-sehir').value = '';
            document.getElementById('ilan-ilce').value = '';
            if (document.getElementById('ilan-gorsel')) document.getElementById('ilan-gorsel').value = '';
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

    const btn = event.currentTarget;
    const isModalBtn = btn.id === 'modal-rezv-btn';
    
    // Yükleniyor animasyonu
    const orjinalMetin = btn.innerHTML;
    btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> İşleniyor...';
    btn.style.pointerEvents = 'none';

    try {
        const response = await fetch('/rezervasyon/olustur', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ ilanId: ilanId })
        });

        if (response.ok) {
            // Cache'i güncelle
            if (cachedRezvIlanIds && !cachedRezvIlanIds.includes(ilanId)) {
                cachedRezvIlanIds.push(ilanId);
            }
            const card = document.querySelector('[data-ilan-id="' + ilanId + '"]');
            if (card) {
                const actionDiv = card.querySelector('.card-action');
                if (actionDiv) {
                    actionDiv.innerHTML = '<span class="action-btn" style="background:#f0ad4e; width:100%; text-align:center;"><i class="fa-solid fa-check"></i> Rezervasyon Yapıldı</span>';
                    actionDiv.style.opacity = '1';
                    actionDiv.style.pointerEvents = 'none';
                }
            }
            // Detay sayfasındaki butonu da güncelle
            const modalBtn = document.getElementById('modal-rezv-btn');
            if (modalBtn) {
                modalBtn.innerHTML = '<i class="fa-solid fa-check"></i> Rezervasyon Yapıldı';
                modalBtn.style.background = '#f0ad4e';
                modalBtn.style.pointerEvents = 'none';
            }
        } else {
            const data = await response.text();
            let mesaj = 'Hata oluştu';
            try {
                const json = JSON.parse(data);
                mesaj = json.message || mesaj;
            } catch (e) {
                mesaj = data || mesaj;
            }
            // "Zaten yapıldı" hatası gelirse butonu güncelle, alert gösterme
            if (mesaj.includes('zaten')) {
                btn.innerHTML = '<i class="fa-solid fa-check"></i> Rezervasyon Yapıldı';
                btn.style.background = '#f0ad4e';
                btn.style.pointerEvents = 'none';
                // Ana sayfadaki kartı da güncelle
                const card = document.querySelector('[data-ilan-id="' + ilanId + '"]');
                if (card) {
                    const actionDiv = card.querySelector('.card-action');
                    if (actionDiv) {
                        actionDiv.innerHTML = '<span class="action-btn" style="background:#f0ad4e; width:100%; text-align:center;"><i class="fa-solid fa-check"></i> Rezervasyon Yapıldı</span>';
                        actionDiv.style.opacity = '1';
                        actionDiv.style.pointerEvents = 'none';
                    }
                }
            } else {
                btn.innerHTML = orjinalMetin;
                btn.style.pointerEvents = 'auto';
                alert(mesaj);
            }
        }
    } catch (error) {
        btn.innerHTML = orjinalMetin;
        btn.style.pointerEvents = 'auto';
        alert('Sunucuya bağlanılamadı.');
    }
}

function toggleFavori(event, ilanId) {
    event.preventDefault();
    event.stopPropagation();
    
    const iconDiv = event.currentTarget;
    const icon = iconDiv.querySelector('i');
    
    let favs = [];
    try {
        favs = JSON.parse(localStorage.getItem(getFavorilerKey()) || '[]');
    } catch(e) {}
    
    const index = favs.indexOf(ilanId);
    if (index > -1) {
        // Favorilerden cikar
        favs.splice(index, 1);
        iconDiv.classList.remove('active');
        icon.classList.remove('fa-solid');
        icon.classList.add('fa-regular');
    } else {
        // Favorilere ekle
        favs.push(ilanId);
        iconDiv.classList.add('active');
        icon.classList.remove('fa-regular');
        icon.classList.add('fa-solid');
    }
    
    localStorage.setItem(getFavorilerKey(), JSON.stringify(favs));
}

// ================= ILAN SIL ================= //

async function ilanSil(event, ilanId) {
    event.preventDefault();
    event.stopPropagation();

    if (!confirm('Bu ilanı silmek istediğinize emin misiniz?')) return;

    try {
        const response = await fetch('/ilan/sil/' + ilanId, {
            method: 'DELETE',
            credentials: 'include'
        });

        if (response.ok) {
            const card = document.querySelector('[data-ilan-id="' + ilanId + '"]');
            if (card) {
                card.style.transition = 'opacity 0.3s, transform 0.3s';
                card.style.opacity = '0';
                card.style.transform = 'scale(0.9)';
                setTimeout(function() { card.remove(); }, 300);
            }
        } else {
            const data = await response.text();
            alert(data || 'İlan silinemedi.');
        }
    } catch (e) {
        alert('Sunucuya bağlanılamadı.');
    }
}

// ================= SPA: İLAN DETAY SAYFASI ================= //
let aktifIlanId = null;
let seciliYildiz = 0;

window.ilanDetayAc = async function(event, ilanId) {
    event.preventDefault();
    aktifIlanId = ilanId;
    seciliYildiz = 0;
    
    const ilan = (window.tumIlanlar || []).find(i => i.id === ilanId);
    if (!ilan) return;
    
    const usta = ilan.olusturanKullanici ? (ilan.olusturanKullanici.ad + ' ' + ilan.olusturanKullanici.soyad) : '';
    const konum = ilan.ilce && ilan.sehir ? ilan.ilce + ', ' + ilan.sehir : (ilan.sehir || '');
    
    // Hero görseli
    const heroEl = document.getElementById('detay-hero');
    if (ilan.gorselYolu) {
        heroEl.style.backgroundImage = 'url("/uploads/' + ilan.gorselYolu + '")';
        heroEl.style.display = 'block';
    } else {
        heroEl.style.display = 'block';
        heroEl.style.backgroundImage = '';
    }
    
    // Sol sütun: İlan bilgileri
    let bilgiHtml = '<h1>' + ilan.baslik + '</h1>';
    if (usta) bilgiHtml += '<div class="detay-bilgi-satir"><i class="fa-solid fa-user"></i> <strong>' + usta + '</strong></div>';
    if (konum) bilgiHtml += '<div class="detay-bilgi-satir"><i class="fa-solid fa-location-dot"></i> ' + konum + '</div>';
    if (ilan.butce) bilgiHtml += '<div class="detay-bilgi-satir"><i class="fa-solid fa-turkish-lira-sign"></i> <strong>' + ilan.butce + ' ₺</strong></div>';
    bilgiHtml += '<div class="detay-aciklama">' + (ilan.aciklama || '').replace(/\n/g, '<br>') + '</div>';
    document.getElementById('detay-ilan-bilgi').innerHTML = bilgiHtml;
    
    // Sağ sütun: Aksiyon kutusu
    let aksiyonHtml = '';
    if (ilan.butce) {
        aksiyonHtml += '<div class="detay-fiyat">' + ilan.butce + ' ₺</div>';
    }
    aksiyonHtml += '<button id="modal-rezv-btn" class="btn-card" onclick="rezervasyonYap(event, ' + ilan.id + ')"><i class="fa-solid fa-calendar-check"></i> Hemen Rezervasyon Yap</button>';
    
    if (girisYapildi && ilan.olusturanKullanici && window.aktifKullaniciEposta !== ilan.olusturanKullanici.eposta) {
        aksiyonHtml += '<a href="mesajlar.html?partnerId=' + ilan.olusturanKullanici.id + '" class="btn-card btn-mesaj"><i class="fa-solid fa-comments"></i> Ustaya Mesaj Yaz</a>';
        aksiyonHtml += '<p class="detay-mesaj-aciklama">Mesajlar sayfasında sohbet açılacak</p>';
    }
    document.getElementById('detay-aksiyon-kutu').innerHTML = aksiyonHtml;
    
    // Mevcut rezervasyonu kontrol et (cache'den)
    if (girisYapildi && cachedRezvIlanIds && cachedRezvIlanIds.includes(ilanId)) {
        const btn = document.getElementById('modal-rezv-btn');
        if (btn) {
            btn.innerHTML = '<i class="fa-solid fa-check"></i> Rezervasyon Yapıldı';
            btn.style.background = '#f0ad4e';
            btn.style.pointerEvents = 'none';
        }
    }
    
    // Yorum formu reset
    const mesajEl = document.getElementById('detay-yorum-mesaj');
    if (mesajEl) mesajEl.innerText = '';
    const metinEl = document.getElementById('detay-yorum-metni');
    if (metinEl) metinEl.value = '';
    document.querySelectorAll('#detay-yildiz-secim i').forEach(y => {
        y.classList.remove('secili', 'hovered');
    });
    
    // Müşteriyse yorum formu göster
    if (girisYapildi && window.aktifKullaniciRol === 'MUSTERI') {
        document.getElementById('detay-yorum-yap').style.display = 'block';
    } else {
        document.getElementById('detay-yorum-yap').style.display = 'none';
    }
    
    // Navbar'daki kullanıcı bilgisini detay sayfasına kopyala
    const anaNavActions = document.querySelector('#ana-sayfa-icerik .nav-actions');
    const detayNavActions = document.getElementById('detay-nav-actions');
    if (anaNavActions && detayNavActions) {
        detayNavActions.innerHTML = anaNavActions.innerHTML;
    }
    
    // Yorumları yükle
    await yorumlariYukle(ilanId);
    
    // Sayfa geçişi: ana sayfayı gizle, detay sayfasını göster
    document.getElementById('ana-sayfa-icerik').style.display = 'none';
    document.getElementById('ilan-detay-sayfa').style.display = 'block';
    window.scrollTo({ top: 0, behavior: 'smooth' });
};

window.detaySayfaKapat = function(event) {
    if (event) event.preventDefault();
    document.getElementById('ilan-detay-sayfa').style.display = 'none';
    document.getElementById('ana-sayfa-icerik').style.display = 'block';
};

// Yıldız Hover ve Click (detay sayfası)
document.addEventListener('DOMContentLoaded', () => {
    function yildizlariAktifEt(container) {
        const yildizlar = container.querySelectorAll('i');
        yildizlar.forEach(y => {
            y.addEventListener('mouseover', function() {
                const deger = parseInt(this.getAttribute('data-deger'));
                yildizlar.forEach(yInner => {
                    if (parseInt(yInner.getAttribute('data-deger')) <= deger) {
                        yInner.classList.add('hovered');
                    } else {
                        yInner.classList.remove('hovered');
                    }
                });
            });
            y.addEventListener('mouseout', function() {
                yildizlar.forEach(yInner => yInner.classList.remove('hovered'));
            });
            y.addEventListener('click', function() {
                seciliYildiz = parseInt(this.getAttribute('data-deger'));
                yildizlar.forEach(yInner => {
                    if (parseInt(yInner.getAttribute('data-deger')) <= seciliYildiz) {
                        yInner.classList.add('secili');
                    } else {
                        yInner.classList.remove('secili');
                    }
                });
            });
        });
    }
    
    const detayYildiz = document.getElementById('detay-yildiz-secim');
    if (detayYildiz) yildizlariAktifEt(detayYildiz);
});

async function yorumlariYukle(ilanId) {
    const ozetEl = document.getElementById('detay-puan-ozeti');
    const listEl = document.getElementById('detay-yorum-listesi');
    
    if (ozetEl) ozetEl.innerHTML = 'Yükleniyor...';
    if (listEl) listEl.innerHTML = '<p class="muted">Yorumlar yükleniyor...</p>';
    
    try {
        const resPuan = await fetch('/yorum/puan/' + ilanId);
        if (resPuan.ok) {
            const puanData = await resPuan.json();
            if (puanData.yorumSayisi > 0) {
                const ortPuan = parseFloat(puanData.ortalama).toFixed(1);
                let starsHtml = '';
                for (let i = 1; i <= 5; i++) {
                    if (i <= Math.round(ortPuan)) starsHtml += '<i class="fa-solid fa-star"></i> ';
                    else starsHtml += '<i class="fa-regular fa-star"></i> ';
                }
                if (ozetEl) ozetEl.innerHTML = '<div class="puan-ozeti-sayi">' + ortPuan + '</div>' +
                                   '<div class="puan-ozeti-yildizlar">' + starsHtml + '</div>' +
                                   '<div style="color:var(--muted); font-size:14px; margin-left:8px;">(' + puanData.yorumSayisi + ' Değerlendirme)</div>';
            } else {
                if (ozetEl) ozetEl.innerHTML = '<div style="color:var(--muted); font-size:14px;">Henüz değerlendirme yapılmamış.</div>';
            }
        }
        
        const resYorumlar = await fetch('/yorum/ilan/' + ilanId);
        if (resYorumlar.ok) {
            const yorumlar = await resYorumlar.json();
            if (yorumlar.length > 0) {
                let yHtml = '';
                yorumlar.forEach(y => {
                    let starsHtml = '';
                    for (let i = 1; i <= 5; i++) {
                        if (i <= y.puan) starsHtml += '<i class="fa-solid fa-star"></i>';
                        else starsHtml += '<i class="fa-regular fa-star"></i>';
                    }
                    const tarih = new Date(y.yorumTarihi).toLocaleDateString('tr-TR');
                    const musteriAd = y.musteri ? (y.musteri.ad + ' ' + y.musteri.soyad.charAt(0) + '.') : 'İsimsiz';
                    yHtml += '<div class="yorum-kart">' +
                                '<div class="yorum-kart-header">' +
                                    '<span class="yorum-kullanici">' + musteriAd + '</span>' +
                                    '<span class="yorum-tarih">' + tarih + '</span>' +
                                '</div>' +
                                '<div class="yorum-puan">' + starsHtml + '</div>' +
                                '<p class="yorum-metin">' + (y.yorumMetni || '') + '</p>' +
                             '</div>';
                });
                if (listEl) listEl.innerHTML = yHtml;
            } else {
                if (listEl) listEl.innerHTML = '<p class="muted">İlk yorumu sen yap!</p>';
            }
        }
    } catch(e) {
        if (ozetEl) ozetEl.innerHTML = 'Puan bilgisi alınamadı.';
        if (listEl) listEl.innerHTML = 'Yorumlar yüklenirken bir hata oluştu.';
    }
}

window.yorumGonder = async function() {
    if (!aktifIlanId) return;
    const mesajEl = document.getElementById('detay-yorum-mesaj');
    
    if (seciliYildiz === 0) {
        if (mesajEl) { mesajEl.innerText = "Lütfen bir puan (yıldız) seçin."; mesajEl.style.color = "red"; }
        return;
    }
    
    const metin = (document.getElementById('detay-yorum-metni') || {}).value || '';
    if (mesajEl) { mesajEl.innerText = "Gönderiliyor..."; mesajEl.style.color = "var(--muted)"; }
    
    try {
        const response = await fetch('/yorum/yaz', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({
                ilanId: aktifIlanId,
                puan: seciliYildiz,
                yorumMetni: metin.trim()
            })
        });
        
        if (response.ok) {
            if (mesajEl) { mesajEl.innerText = "Değerlendirmeniz başarıyla eklendi!"; mesajEl.style.color = "green"; }
            const metinEl = document.getElementById('detay-yorum-metni');
            if (metinEl) metinEl.value = '';
            await yorumlariYukle(aktifIlanId);
        } else {
            const err = await response.text();
            if (mesajEl) { mesajEl.innerText = err || "Yorum eklenemedi."; mesajEl.style.color = "red"; }
        }
    } catch(e) {
        if (mesajEl) { mesajEl.innerText = "Sunucu bağlantı hatası."; mesajEl.style.color = "red"; }
    }
};
