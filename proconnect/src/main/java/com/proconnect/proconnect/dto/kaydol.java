package com.proconnect.proconnect.dto;

import lombok.Data;

@Data 
public class kaydol {
    private String ad;
    private String soyad;
    private String eposta;
    private String sifre; // Bu ham şifredir, veritabanına böyle gitmeyecek!
    private String rol; // MÜŞTERİ mi, USTA mı? (String olarak alacağız, sonra kontrol edeceğiz)
}  // bu olmasa requestbody iş yapamaz 