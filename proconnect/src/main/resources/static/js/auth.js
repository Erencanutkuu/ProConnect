let girisYapildi = false;
window.aktifKullaniciEposta = null;
window.aktifKullaniciRol = null;

document.addEventListener('DOMContentLoaded', async function() {
    try {
        const response = await fetch('/me', { credentials: 'include' });
        const data = await response.json();

        const navActions = document.querySelector('.nav-actions');

        if (data.girisYapildi) {
            girisYapildi = true;
            window.aktifKullaniciEposta = data.eposta;
            window.aktifKullaniciRol = data.rol;
            if (navActions) {
                navActions.innerHTML =
                    '<a href="mesajlar.html" class="nav-user" style="position:relative;"><i class="fa-solid fa-envelope"></i> Mesajlar <span id="mesaj-badge" style="display:none;background:#dc3545;color:#fff;border-radius:10px;padding:1px 6px;font-size:11px;font-weight:700;margin-left:2px;"></span></a>' +
                    '<a href="profil.html" class="nav-user"><i class="fa-solid fa-user"></i> ' + data.ad + '</a>' +
                    '<a href="#" class="btn-kayit btn-outline" onclick="cikisYap()">Çıkış Yap</a>';

                // Okunmamış mesaj sayısını al
                mesajBadgeGuncelle();
            }

            if (data.rol === 'USTA') {
                if (!data.epostaDogrulandi) {
                    ustaUyariGoster('E-postanizi dogrulayin. Profilinizden dogrulama yapabilirsiniz.');
                } else if (!data.belgeYuklendi) {
                    ustaUyariGoster('Ilan olusturabilmek icin profilinizden belgenizi yukleyin.');
                } else {
                    // E-posta dogrulandi + belge yuklendi = ilan olusturabilir
                    var ilanCard = document.getElementById('ilan-olustur-card');
                    if (ilanCard) ilanCard.style.display = '';
                }
            }
        }
        window.dispatchEvent(new Event('authLoaded'));
    } catch (e) {
        window.dispatchEvent(new Event('authLoaded'));
    }
});

function ustaUyariGoster(mesaj) {
    var grid = document.querySelector('.grid');
    if (!grid) return;

    var mevcutUyari = document.getElementById('usta-uyari');
    if (mevcutUyari) mevcutUyari.remove();

    var uyari = document.createElement('div');
    uyari.id = 'usta-uyari';
    uyari.style.cssText = 'grid-column: 1/-1; background: #fff3cd; border: 1px solid #ffc107; padding: 16px; border-radius: 8px; text-align: center; color: #856404; font-weight: 500;';
    uyari.textContent = mesaj;
    grid.insertBefore(uyari, grid.firstChild);
}

async function mesajBadgeGuncelle() {
    try {
        var res = await fetch('/mesaj/okunmamis-sayisi', { credentials: 'include' });
        var data = await res.json();
        var badge = document.getElementById('mesaj-badge');
        if (badge) {
            if (data.sayi > 0) {
                badge.textContent = data.sayi;
                badge.style.display = 'inline';
            } else {
                badge.style.display = 'none';
            }
        }
    } catch (e) {}
}

async function cikisYap() {
    await fetch('/cikis', { method: 'POST', credentials: 'include' });
    window.location.href = 'index.html';
}
