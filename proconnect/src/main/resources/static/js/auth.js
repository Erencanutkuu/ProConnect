let girisYapildi = false;

document.addEventListener('DOMContentLoaded', async function() {
    try {
        const response = await fetch('/me', { credentials: 'include' });
        const data = await response.json();

        const navActions = document.querySelector('.nav-actions');
        if (!navActions) return;

        if (data.girisYapildi) {
            girisYapildi = true;
            navActions.innerHTML =
                '<a href="profil.html" class="nav-user"><i class="fa-solid fa-user"></i> ' + data.ad + '</a>' +
                '<a href="#" class="btn-kayit btn-outline" onclick="cikisYap()">Çıkış Yap</a>';

            if (data.rol === 'USTA') {
                var ilanCard = document.getElementById('ilan-olustur-card');
                if (ilanCard) ilanCard.style.display = '';
            }
        }
    } catch (e) {
        // sessizce geç
    }
});

async function cikisYap() {
    await fetch('/cikis', { method: 'POST', credentials: 'include' });
    window.location.href = 'index.html';
}

