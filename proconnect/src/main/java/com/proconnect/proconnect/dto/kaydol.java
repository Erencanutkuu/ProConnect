package com.proconnect.proconnect.dto;

import com.proconnect.proconnect.entity.Rol;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class kaydol {
    @NotBlank(message = "Ad boş bırakılamaz")
    private String ad;

    @NotBlank(message = "Soyad boş bırakılamaz")
    private String soyad;

    @NotBlank(message = "E-posta boş bırakılamaz")
    @Email(message = "Geçersiz e-posta formatı")
    private String eposta;

    @NotBlank(message = "Şifre boş bırakılamaz")
    private String sifre; // Bu ham şifredir, veritabanına böyle gitmeyecek!

    @NotNull(message = "Rol boş bırakılamaz")
    private Rol rol; // MÜŞTERİ mi, USTA mı?

    private String tcno;
}  // bu olmasa requestbody iş yapamaz 
// bunu yapma nedenimiz entity içindeki kullanıcı java içinde ıd vb şeyler oldugu için biz sadece kaydolurken gerekli olan bilgileri almak istiyoruz bu yüzden ayrı bir dto oluşturduk