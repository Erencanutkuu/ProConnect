package com.proconnect.proconnect.util;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class tcno {

    @Column(name = "tc_no", length = 11) 
    private String deger; // İŞTE EKSİK OLAN BUYDU!

    // Hibernate için boş constructor şarttır
    public tcno() {}

    public tcno(String deger) {
        this.deger = deger;
    }

    // Getter ve Setter (Veriye erişmek için)
    public String getDeger() { return deger; }
    public void setDeger(String deger) { this.deger = deger; }

    /**
     * Senin yazdığın validasyon metodu aynen kalabilir.
     * Statik olması güzel, her yerden çağırabilirsin.
     */
    public static boolean validate(String tcno) {
        if (tcno == null || tcno.length() != 11 || tcno.startsWith("0")) return false;
        if (!tcno.matches("\\d{11}")) return false;

        int[] digits = new int[11];
        for (int i = 0; i < 11; i++) {
            digits[i] = Character.getNumericValue(tcno.charAt(i));
        }

        int oddSum = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
        int evenSum = digits[1] + digits[3] + digits[5] + digits[7];

        int tenthDigitCalculation = ((oddSum * 7) - evenSum) % 10;
        if (tenthDigitCalculation < 0) tenthDigitCalculation += 10;
        if (tenthDigitCalculation != digits[9]) return false;

        int firstTenSum = 0;
        for (int i = 0; i < 10; i++) firstTenSum += digits[i];

        return (firstTenSum % 10 == digits[10]);
    }
}