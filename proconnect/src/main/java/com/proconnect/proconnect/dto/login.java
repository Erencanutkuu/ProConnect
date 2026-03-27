package com.proconnect.proconnect.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class login {

    @NotBlank(message = "E-posta boş bırakılamaz")
    @Email(message = "Geçersiz e-posta formatı")
    private String eposta;
    @NotBlank(message = "Şifre boş bırakılamaz")
    private String sifre;

}
