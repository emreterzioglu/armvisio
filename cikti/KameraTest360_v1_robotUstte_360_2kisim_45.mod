MODULE KameraTest360
    ! YENI BRAKET (eoat_assembly_v1), flans ekseni etrafinda 180 derece donuk takili + Computar MLM-3XMP lens
    ! 360 DERECE: 12 foto, 30 derece arayla, IKI KISIM:
    !   A: -180 -> 0 -> +60 (foto 1-9), ayni yoldan -180'e geri, pUst'e cikis.
    !   pUst'te bilek ters cevrilir (J4 ve J6 180 derece, J5 isaret degistirir) -> J4 sinirdan uzaklasir.
    !   B: +90 -> +150 (foto 10-12), +90 tarafindan giris/cikis. pUst'te bilek geri cevrilir, HOME.
    !   Sebep: tek seferde -180 -> +150 donuste J4 sinira dayaniyor (foto 9 ile 10 arasi "out of range").
    ! TCP = TUPUN MERKEZ CIZGISI. tKamera Z = 65.480 (lens baglanti yuzu, v1 CAD) + 79.500 (lens CAD)
    !       + 86 (lens metal ucu -> tup yuzeyi) + 3.945 (tup yaricapi) = 235.945 mm ; X,Y = -67.511,-19.6 (v1 CAD, 180 donuk)
    ! Tum noktalar robot tabani (wobj0). Fotograf noktalari CAD tup eksenine gore; ince ayarda ModPos ile guncellenir.
    ! 45 MM BOSLUK: parca platformu robot masasindan 45 mm uzaklastirildi (robot tabani +Y, fiziksel +X).
    !   Parcaya bagli tum noktalar (pUst..pFoto12, pRef) Y +45 kaydirildi. HOME degismedi.
    ! ROBOTSTUDIO YERLESIMI:
    !   istasyon_fiziksel_zemin0_45bosluk.step -> konum (0,0,0), donus 0 (zemin Z=0, masa ustu Z=820, platform +X)
    !   Robot -> konum (0,0,820), donus Z = -90 derece (tepeden bakinca saat yonunde 90)
    !   Bu kod robot tabanina (wobj0) gore yazildi; gercek robotta kaydedilen referanslar parcayi taban +Y'de gosteriyor.
    !   Robot RobotStudio'da donmeden birakilirsa noktalar parcaya 90 derece kayik gorunur.
    ! ROBOT KAMERANIN USTUNDE: tKamera yonu eski braketle ayni (Rz -90) -> eksen 6 eski kodla ayni yonde calisir.
    !   Flans tum turda tup merkezi seviyesinde ya da ustunde (Z 330-478; tup merkezi Z 341).
    !   BEDELI: kamera goruntusu eski koda gore 180 derece donuk gelir (tup yine yatay ve ortada, yesil ok SAGA bakar).
    !   Goruntu PC'de 180 derece dondurulmeli.
    ! CAD (robot kollari haric): kamera/lens parcaya en yakin 9 mm (+150), flans istasyona en yakin 156 mm.
    ! Kutle 0.5 kg / agirlik merkezi YER TUTUCU
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];

    CONST bool bHomeKullan := TRUE;

    ! HOME: robotun durusu (tum eksenler) kullanicinin HOME'u ile ayni; deger bu takima gore yeniden hesaplandi.
    ! pUst   : pAra'nin 200 mm ustu. HOME -> pUst -> pAra yolu parcanin ustunden yuksekte gecer.
    ! pAra   : pYaklas'in 150 mm ustu.
    ! pYaklas: pFoto7'den optik eksen boyunca 120 mm geri.
    ! pUst/pAra/pYaklas: TCP konumlari ters surumle ayni. robconf [0,0,-1,0] tahmin, TEYIT EDILMEDI (kontrol kapali).
    CONST robtarget pHomeKul := [[-348.869,279.502,343.717],[0.4117930,0.5867360,-0.3940890,-0.5752060],[1,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pUst := [[67.055,668.962,686.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pAra := [[67.055,668.962,486.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    ! B kismi giris: pYaklasB = pFoto10'dan optik eksen boyunca 120 mm geri, pAraB = 150 mm ustu
    CONST robtarget pAraB := [[-25.143,531.376,449.013],[-0.1084640,-0.0492327,0.5673977,0.8147831],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pYaklasB := [[-25.143,531.376,299.013],[-0.1084640,-0.0492327,0.5673977,0.8147831],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pYaklas := [[67.055,668.962,336.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! Kullanicinin 3 referans konumu, bu takima (tKamera) cevrilmis ve +45 Y kaydirilmis hali (TAHMIN; bosluk sonrasi yeniden kaydedilmeli). Sadece kontrol icin, programda kullanilmaz.
    ! pRef3 orijinali tKamera (242.546) ile kaydedildi VARSAYIMIYLA cevrildi. robconf eski brakete gore.
    CONST robtarget pRef1 := [[-49.509,645.504,343.089],[0.3593369,0.5187635,0.4482773,0.6330947],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet1
    CONST robtarget pRef2 := [[-47.174,639.294,340.742],[0.4512960,0.8631220,0.1873698,0.1274553],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet2
    CONST robtarget pRef3 := [[-52.047,635.841,341.186],[0.5010801,0.6943511,-0.2642580,-0.4438051],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet3

    ! Fotograf noktalari (ince ayarda ModPos ile guncellenir)
    CONST robtarget pFoto1 := [[-49.540,641.048,341.166],[0.3245152,0.5413259,0.4779064,0.6109514],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece
    CONST robtarget pFoto2 := [[-49.540,641.048,341.166],[0.4371489,0.6810066,0.3776314,0.4500283],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece
    CONST robtarget pFoto3 := [[-49.540,641.048,341.166],[0.5199916,0.7742777,0.2516215,0.2584365],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece
    CONST robtarget pFoto4 := [[-49.540,641.048,341.166],[0.5673977,0.8147831,0.1084640,0.0492326],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece
    CONST robtarget pFoto5 := [[-49.540,641.048,341.166],[0.5761367,0.7997624,-0.0420852,-0.1633263],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece
    CONST robtarget pFoto6 := [[-49.540,641.048,341.166],[0.5456128,0.7302392,-0.1897663,-0.3647548],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece
    CONST robtarget pFoto7 := [[-49.540,641.048,341.166],[0.4779064,0.6109514,-0.3245152,-0.5413259],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece
    CONST robtarget pFoto8 := [[-49.540,641.048,341.166],[0.1897663,0.3647548,0.5456128,0.7302392],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece
    CONST robtarget pFoto9 := [[-49.540,641.048,341.166],[0.0420852,0.1633263,0.5761366,0.7997624],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece
    CONST robtarget pFoto10 := [[-49.540,641.048,341.166],[-0.1084640,-0.0492327,0.5673977,0.8147831],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece
    CONST robtarget pFoto11 := [[-49.540,641.048,341.166],[-0.2516215,-0.2584365,0.5199915,0.7742777],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece
    CONST robtarget pFoto12 := [[-49.540,641.048,341.166],[-0.3776314,-0.4500283,0.4371488,0.6810066],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece

    VAR speeddata vKamDonus := [30,15,5000,1000];   ! 15 derece/s
    CONST num nFotoBekle := 0.5;
    VAR num nFoto;

    PROC main()
        Giris;
        ConfL \Off;
        SingArea \Wrist;
        nFoto := 0;
        ! A KISMI: -180 (pFoto7) -> +60 (pFoto9), foto 1-9
        MoveL pFoto7, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto6, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto5, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto4, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto3, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto2, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto1, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto8, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto9, vKamDonus, fine, tKamera;
        FotoAl;
        ! Ayni yoldan geri -180'e (kablo cozulur)
        MoveL pFoto8, vKamDonus, z1, tKamera;
        MoveL pFoto1, vKamDonus, z1, tKamera;
        MoveL pFoto2, vKamDonus, z1, tKamera;
        MoveL pFoto3, vKamDonus, z1, tKamera;
        MoveL pFoto4, vKamDonus, z1, tKamera;
        MoveL pFoto5, vKamDonus, z1, tKamera;
        MoveL pFoto6, vKamDonus, z1, tKamera;
        MoveL pFoto7, vKamDonus, fine, tKamera;
        MoveL pYaklas, v50, fine, tKamera;
        MoveL pAra, v100, fine, tKamera;
        MoveL pUst, v100, fine, tKamera;
        ! B KISMI: bilegi ters cevir (parcadan uzakta), +90 tarafindan gir
        BilekCevir;
        MoveL pAraB, v100, fine, tKamera;
        MoveL pYaklasB, v100, fine, tKamera;
        MoveL pFoto10, v50, fine, tKamera;
        FotoAl;
        MoveL pFoto11, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto12, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto11, vKamDonus, z1, tKamera;
        MoveL pFoto10, vKamDonus, fine, tKamera;
        MoveL pYaklasB, v50, fine, tKamera;
        MoveL pAraB, v100, fine, tKamera;
        MoveL pUst, v100, fine, tKamera;
        BilekCevir;
        ConfL \On;
        IF bHomeKullan MoveL pHomeKul, v100, fine, tKamera;
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    PROC FotoAl()
        VAR jointtarget j;
        nFoto := nFoto + 1;
        j := CJointT();
        TPWrite "Foto " \Num:=nFoto;
        TPWrite "J4=" \Num:=j.robax.rax_4;
        TPWrite "J5=" \Num:=j.robax.rax_5;
        TPWrite "J6=" \Num:=j.robax.rax_6;
        WaitTime nFotoBekle;
    ENDPROC

    ! Ayni TCP pozunu bilegin diger durusuyla alir: J4 ve J6 180 derece (sifira dogru), J5 isaret degistirir.
    ! Parcadan uzakta (pUst) yapilir. Iki kez cagrilinca robot eski durusuna doner.
    PROC BilekCevir()
        VAR jointtarget j;
        j := CJointT();
        IF j.robax.rax_4 > 0 THEN
            j.robax.rax_4 := j.robax.rax_4 - 180;
        ELSE
            j.robax.rax_4 := j.robax.rax_4 + 180;
        ENDIF
        j.robax.rax_5 := -j.robax.rax_5;
        IF j.robax.rax_6 > 0 THEN
            j.robax.rax_6 := j.robax.rax_6 - 180;
        ELSE
            j.robax.rax_6 := j.robax.rax_6 + 180;
        ENDIF
        MoveAbsJ j, v50, fine, tKamera;
    ENDPROC

    PROC Giris()
        ConfJ \On;
        IF bHomeKullan MoveJ pHomeKul, v100, fine, tKamera;
        ! pUst/pAra/pYaklas robconf teyit edilmedi -> konfigurasyon kontrolu kapali
        ConfL \Off;
        MoveL pUst, v100, fine, tKamera;
        MoveL pAra, v100, fine, tKamera;
        MoveL pYaklas, v100, fine, tKamera;
        MoveL pFoto7, v50, fine, tKamera;
    ENDPROC

    PROC Cikis()
        ConfL \Off;
        MoveL pYaklas, v50, fine, tKamera;
        MoveL pAra, v100, fine, tKamera;
        MoveL pUst, v100, fine, tKamera;
        IF bHomeKullan MoveL pHomeKul, v100, fine, tKamera;
        ConfL \On;
    ENDPROC
ENDMODULE
