package com.proconnect.proconnect.util;

import java.util.Base64.Decoder;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.security.Key;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;

@Component  // Spring'in bu sınıfı yönetmesini sağlar, böylece ihtiyaç duyduğumuz yerde @Autowired ile kullanabiliriz
// burada JWT oluşturma ve doğrulama işlemleri için gerekli yöntemleri ekleyeceğiz. Örneğin, JWT oluşturmak için bir yöntem, JWT'yi doğrulamak için başka bir yöntem olabilir. Ayrıca, JWT'nin geçerlilik süresini ve gizli anahtarını yönetmek için de yardımcı yöntemler ekleyebiliriz.
// Bu sınıf, JWT işlemlerini merkezi bir yerde toplamak ve kodun geri kalanında bu işlemleri kolayca kullanabilmek için tasarlanmıştır.
//getmapping ise burdaki hazır şeyi alıp kullanmak için 
public class jwtutil {
    @Value("${spring.jwt.secret}")  // application.properties dosyasındaki değeri alır
    private String secret ;
    @Value("${spring.jwt.expiration}")  // application.properties dosyasındaki değeri alır
    private String expiration;

    private Key getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secret);  // Base64 ile kodlanmış gizli anahtarı byte dizisine dönüştür yani eren olur biz secret içine 64 bit degerinde bir şey oluşturudk ya onu duzeltir 
        
        return Keys.hmacShaKeyFor(keyBytes); // HMAC SHA algoritmasıyla imzalama anahtarı oluşturur ve artık anlar yan anlaması için yapılır
        

    }

    public String generateToken(String username) {

    Map<String, Object> claims = new HashMap<>();
    claims.put("role", "USER");

    return Jwts.builder()
        .setClaims(claims) // rolunu içine eklemek için claims ekliyoruz
        .setSubject(username)
        .setIssuedAt(new Date())
        .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60)) // 1 saat
        .signWith(getSigningKey(), SignatureAlgorithm.HS256)
        .compact();

    }
}
