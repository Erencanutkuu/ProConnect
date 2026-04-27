document.addEventListener('DOMContentLoaded', function() {
    if (!localStorage.getItem('cerezOnay')) {
        document.getElementById('cerez-banner').style.display = 'flex';
    }
});

async function cerezKabulEt() {
    localStorage.setItem('cerezOnay', 'kabul');
    document.getElementById('cerez-banner').style.display = 'none';

    try {
        await fetch('/cerez-onay', {
            method: 'POST',
            credentials: 'include'
        });
    } catch (e) {
        // Giriş yapmamışsa sessizce geç
    }

    konumIzniIste();
}

function cerezReddet() {
    localStorage.setItem('cerezOnay', 'red');
    document.getElementById('cerez-banner').style.display = 'none';
}

function konumIzniIste() {
    if (!navigator.geolocation) return;

    navigator.geolocation.getCurrentPosition(
        async function(position) {
            try {
                await fetch('/konum', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    credentials: 'include',
                    body: JSON.stringify({
                        lat: position.coords.latitude,
                        lng: position.coords.longitude
                    })
                });
            } catch (e) {
                // Giriş yapmamışsa sessizce geç
            }
        },
        function(error) {
            console.log('Konum izni reddedildi');
        }
    );
}
