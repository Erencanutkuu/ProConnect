package com.proconnect.proconnect.util;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.security.Key;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;

  // Spring'in bu sınıfı yönetmesini sağlar, böylece ihtiyaç duyduğumuz yerde @Autowired ile kullanabiliriz
// burada JWT oluşturma ve doğrulama işlemleri için gerekli yöntemleri ekleyeceğiz. Örneğin, JWT oluşturmak için bir yöntem, JWT'yi doğrulamak için başka bir yöntem olabilir. Ayrıca, JWT'nin geçerlilik süresini ve gizli anahtarını yönetmek için de yardımcı yöntemler ekleyebiliriz.
// Bu sınıf, JWT işlemlerini merkezi bir yerde toplamak ve kodun geri kalanında bu işlemleri kolayca kullanabilmek için tasarlanmıştır.
//getmapping ise burdaki hazır şeyi alıp kullanmak için 
@Component
public class jwtutil {
    @Value("${spring.jwt.secret}")  // application.properties dosyasındaki değeri alır
    private String secret ;
    @Value("${spring.jwt.expiration}")  // application.properties dosyasındaki değeri alır
    private String expiration;

    private Key getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secret);  // Base64 ile kodlanmış gizli anahtarı byte dizisine dönüştür yani eren olur biz secret içine 64 bit degerinde bir şey oluşturudk ya onu duzeltir 
        
        return Keys.hmacShaKeyFor(keyBytes); // HMAC SHA algoritmasıyla imzalama anahtarı oluşturur ve artık anlar yan anlaması için yapılır
        

    }

        // ✅ Olması gereken
    public String generateToken(String eposta, String rol) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", rol);  // gerçek rol geliyor

        return Jwts.builder()
            .setClaims(claims)
            .setSubject(eposta)    // eposta subject oluyor
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60))
            .signWith(getSigningKey(), SignatureAlgorithm.HS256)
            .compact();
    }





        // ==================== 1. ADIM: Tüm claim'leri çöz ====================
    // Bu method token'ı secret key ile açar, içindeki her şeyi döndürür
    // Diğer tüm metodlar bunu kullanır

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
            .setSigningKey(getSigningKey())  // aynı key ile açıyoruz
            .build()
            .parseClaimsJws(token)          // token'ı parse et
            .getBody();                      // içindeki bilgileri al
    }


    // ==================== 2. ADIM: Username oku ====================
    // setSubject(username) ile yazdık, getSubject() ile okuyoruz

    public String extractUsername(String token) {
        return extractAllClaims(token).getSubject();
    }


    // ==================== 3. ADIM: Expiration oku ====================

    public Date extractExpiration(String token) {
        return extractAllClaims(token).getExpiration();
    }


    // ==================== 4. ADIM: Süresi dolmuş mu? ====================
    // Expiration tarihi şimdiki zamandan önce mi?

    public boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }


    // ==================== 5. ADIM: Token geçerli mi? ====================
    // Username doğru mu + süresi geçmemiş mi?

        public boolean isTokenValid(String token, String username) {
        String tokenUsername = extractUsername(token);
        return tokenUsername.equals(username) && !isTokenExpired(token);
        }
   

       


        
   
}
