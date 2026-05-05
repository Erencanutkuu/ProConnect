package com.proconnect.proconnect.util;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;

/**
 * JWT token'ı hem Cookie'den hem de Authorization header'dan okur.
 * Mobil uygulama (Flutter) header gönderir, web uygulaması cookie gönderir.
 */
public class JwtResolver {

    public static String resolveToken(HttpServletRequest request) {
        // 1. Önce Authorization header'ı kontrol et
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }

        // 2. Yoksa cookie'den al
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if ("jwt".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }

        return null;
    }
}
