let kullaniciLat = null;
let kullaniciLng = null;
let kullaniciSehir = null;

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
                ? '<div class="delete-icon" onclick="ilanSil(event, ' + ilan.id + ')" title="İlanı Sil" style="position:absolute;top:12px;left:12px;z-index:2;background:rgba(220,53,69,0.85);color:#fff;border-radius:50%;width:36px;height:36px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:16px;box-shadow:0 2px 8px rgba(0,0,0,0.15);transition:background 0.2s;" onmouseenter="this.style.background=\'#c82333\'" onmouseleave="this.style.background=\'rgba(220,53,69,0.85)\'">' +
                    '<i class="fa-solid fa-trash"></i>' +
                '</div>'
                : '';

            const html = '<article class="card" data-ilan-id="' + ilan.id + '" style="position:relative;">' +
                silBtnHtml +
                '<div class="favorite-icon ' + (isFavori ? 'active' : '') + '" onclick="toggleFavori(event, ' + ilan.id + ')" title="Favoriye Ekle/Çıkar">' +
                    '<i class="' + (isFavori ? 'fa-solid' : 'fa-regular') + ' fa-heart"></i>' +
                '</div>' +
                cardMediaHtml +
                '<div class="card-action">' +
                    '<a class="action-btn" href="#" onclick="ilanDetayAc(event, ' + ilan.id + ')" style="width:100%; text-align:center;">Rezervasyon</a>' +
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
            const card = document.querySelector('[data-ilan-id="' + ilanId + '"]');
            if (card) {
                const actionDiv = card.querySelector('.card-action');
                if (actionDiv) {
                    actionDiv.innerHTML = '<span class="action-btn" style="background:#f0ad4e; width:100%; text-align:center;"><i class="fa-solid fa-check"></i> Rezervasyon Yapıldı</span>';
                    actionDiv.style.opacity = '1';
                    actionDiv.style.pointerEvents = 'none';
                }
            }
            // Modal içindeki butonu da güncelle
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
            // Hata durumunda animasyonu geri al
            btn.innerHTML = orjinalMetin;
            btn.style.pointerEvents = 'auto';
            alert(mesaj);
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

// ================= YORUM VE DETAY MODAL ================= //
let aktifIlanId = null;
let seciliYildiz = 0;

window.ilanDetayAc = async function(event, ilanId) {
    event.preventDefault();
    aktifIlanId = ilanId;
    seciliYildiz = 0;
    
    // İlanı bul
    const ilan = (window.tumIlanlar || []).find(i => i.id === ilanId);
    if (!ilan) return;
    
    const usta = ilan.olusturanKullanici ? (ilan.olusturanKullanici.ad + ' ' + ilan.olusturanKullanici.soyad) : '';
    
    // Modal içeriğini doldur
    const headerImg = document.getElementById('modal-header-img');
    if (ilan.gorselYolu) {
        headerImg.style.backgroundImage = 'url("/uploads/' + ilan.gorselYolu + '")';
        headerImg.style.display = 'block';
    } else {
        headerImg.style.display = 'none';
    }

    let icerikHtml = '<h2 style="margin-top:0;">' + ilan.baslik + '</h2>';
    if (usta) icerikHtml += '<p><i class="fa-solid fa-user"></i> <strong>Usta:</strong> ' + usta + '</p>';
    if (ilan.butce) icerikHtml += '<p><i class="fa-solid fa-turkish-lira-sign"></i> <strong>Bütçe:</strong> ' + ilan.butce + ' ₺</p>';
    icerikHtml += '<div style="margin-top:15px; line-height:1.6; color:#444;">' + (ilan.aciklama || '').replace(/\n/g, '<br>') + '</div>';
    
    document.getElementById('ilan-detay-icerik').innerHTML = icerikHtml;
    
    // Alt bar butonunu güncelle
    var bottomBarHtml = '<button id="modal-rezv-btn" class="btn-card" style="width:100%; padding:14px; font-size:16px; display:flex; align-items:center; justify-content:center; gap:8px;" onclick="rezervasyonYap(event, ' + ilan.id + ')">Hemen Rezervasyon Yap</button>';

    // Giriş yapılmışsa ve ilan sahibi değilse "Mesaj Gönder" butonu ekle
    if (window.girisYapildi && ilan.olusturanKullanici && window.aktifKullaniciEposta !== ilan.olusturanKullanici.eposta) {
        bottomBarHtml += '<a href="mesajlar.html?partnerId=' + ilan.olusturanKullanici.id + '" class="btn-card" style="width:100%; padding:14px; font-size:16px; display:flex; align-items:center; justify-content:center; gap:8px; background:#28a745; text-decoration:none; margin-top:8px;"><i class="fa-solid fa-envelope"></i> Mesaj Gönder</a>';
    }

    document.getElementById('modal-bottom-bar').innerHTML = bottomBarHtml;
    
    // Yorum kısmını resetle
    document.getElementById('yorum-mesaj').innerText = '';
    document.getElementById('yorum-metni').value = '';
    document.querySelectorAll('.yildiz-secim i').forEach(y => {
        y.classList.remove('secili', 'hovered');
    });
    
    // Kullanıcı giriş yaptıysa ve Müşteri ise yorum formunu göster
    if (window.girisYapildi && window.aktifKullaniciRol === 'MUSTERI') {
        document.getElementById('yorum-yap-alani').style.display = 'block';
    } else {
        document.getElementById('yorum-yap-alani').style.display = 'none';
    }
    
    // Yorumları ve puanı yükle
    await yorumlariYukle(ilanId);
    
    // Modalı aç
    document.getElementById('ilan-detay-modal').style.display = 'block';
};

window.ilanDetayKapat = function() {
    document.getElementById('ilan-detay-modal').style.display = 'none';
};

// Yıldız Hover ve Click Mantığı
document.addEventListener('DOMContentLoaded', () => {
    const yildizlar = document.querySelectorAll('.yildiz-secim i');
    
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
});

async function yorumlariYukle(ilanId) {
    const ozetEl = document.getElementById('ilan-puan-ozeti');
    const listEl = document.getElementById('ilan-yorum-listesi');
    
    ozetEl.innerHTML = 'Yükleniyor...';
    listEl.innerHTML = '<p class="muted">Yorumlar yükleniyor...</p>';
    
    try {
        // Puan Özeti Çek
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

                ozetEl.innerHTML = '<div class="puan-ozeti-sayi">' + ortPuan + '</div>' +
                                   '<div class="puan-ozeti-yildizlar">' + starsHtml + '</div>' +
                                   '<div style="color:var(--muted); font-size:14px; margin-left:8px;">(' + puanData.yorumSayisi + ' Değerlendirme)</div>';
            } else {
                ozetEl.innerHTML = '<div style="color:var(--muted); font-size:14px;">Henüz değerlendirme yapılmamış.</div>';
            }
        }
        
        // Yorumları Çek
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
                listEl.innerHTML = yHtml;
            } else {
                listEl.innerHTML = '<p class="muted">İlk yorumu sen yap!</p>';
            }
        }
    } catch(e) {
        ozetEl.innerHTML = 'Puan bilgisi alınamadı.';
        listEl.innerHTML = 'Yorumlar yüklenirken bir hata oluştu.';
    }
}

window.yorumGonder = async function() {
    if (!aktifIlanId) return;
    const mesajEl = document.getElementById('yorum-mesaj');
    
    if (seciliYildiz === 0) {
        mesajEl.innerText = "Lütfen bir puan (yıldız) seçin.";
        mesajEl.style.color = "red";
        return;
    }
    
    const metin = document.getElementById('yorum-metni').value.trim();
    mesajEl.innerText = "Gönderiliyor...";
    mesajEl.style.color = "var(--muted)";
    
    try {
        const response = await fetch('/yorum/yaz', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({
                ilanId: aktifIlanId,
                puan: seciliYildiz,
                yorumMetni: metin
            })
        });
        
        if (response.ok) {
            mesajEl.innerText = "Değerlendirmeniz başarıyla eklendi!";
            mesajEl.style.color = "green";
            document.getElementById('yorum-metni').value = '';
            
            // Yorumları yeniden yükle
            await yorumlariYukle(aktifIlanId);
        } else {
            const err = await response.text();
            mesajEl.innerText = err || "Yorum eklenemedi.";
            mesajEl.style.color = "red";
        }
    } catch(e) {
        mesajEl.innerText = "Sunucu bağlantı hatası.";
        mesajEl.style.color = "red";
    }
};
