MODULE KameraTest360
    ! YENI BRAKET (eoat_assembly_v1), flans ekseni etrafinda 180 derece donuk takili + Computar MLM-3XMP lens
    ! 360 DERECE: 12 foto, 30 derece arayla. -180 -> 0 -> +150, sonra ayni yoldan -180'e geri, -180 tarafindan cikis.
    ! TCP = TUPUN MERKEZ CIZGISI. tKamera Z = 65.480 (lens baglanti yuzu, v1 CAD) + 79.500 (lens CAD)
    !       + 86 (lens metal ucu -> tup yuzeyi) + 3.945 (tup yaricapi) = 235.945 mm ; X,Y = -67.511,-19.6 (v1 CAD, 180 donuk)
    ! Tum noktalar robot tabani (wobj0). Fotograf noktalari CAD tup eksenine gore; ince ayarda ModPos ile guncellenir.
    ! UYARI: +90..+150 (pFoto10-12) tarafi CAD'de dar: kamera/lens parcaya 10-52 mm, flans istasyona 74-137 mm.
    !        Robot kollari kontrol edilmedi. Ilk deneme dusuk hizda ve adim adim.
    ! Kutle 0.5 kg / agirlik merkezi YER TUTUCU
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];

    CONST bool bHomeKullan := TRUE;

    ! HOME: kameranin konumu ve yonu kullanicinin HOME'u ile ayni. Braket 180 donuk oldugu icin eksen 6 farkli:
    !       HOME robconf teyit edilmedi -> ilk MoveJ konfigurasyon kontrolu kapali. Robotta ModPos yapin.
    ! pUst   : pAra'nin 200 mm ustu. HOME -> pUst -> pAra yolu parcanin ustunden yuksekte gecer.
    ! pAra   : pYaklas'in 150 mm ustu.
    ! pYaklas: pFoto7'den optik eksen boyunca 120 mm geri.
    ! pUst/pAra/pYaklas: TCP konumlari ters surumle ayni. robconf [0,0,-1,0] tahmin, TEYIT EDILMEDI (kontrol kapali).
    CONST robtarget pHomeKul := [[-360.053,337.582,437.652],[0.4117930,0.5867360,-0.3940890,-0.5752060],[1,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pUst := [[67.055,623.962,686.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pAra := [[67.055,623.962,486.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pYaklas := [[67.055,623.962,336.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! Kullanicinin 3 referans konumu, bu takima (tKamera) cevrilmis hali. Sadece kontrol icin, programda kullanilmaz.
    ! pRef3 orijinali tKamera (242.546) ile kaydedildi VARSAYIMIYLA cevrildi. robconf eski brakete gore.
    CONST robtarget pRef1 := [[-49.509,600.504,343.089],[0.3593369,0.5187635,0.4482773,0.6330947],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet1
    CONST robtarget pRef2 := [[-47.174,594.294,340.742],[0.4512960,0.8631220,0.1873698,0.1274553],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet2
    CONST robtarget pRef3 := [[-52.047,590.841,341.186],[0.5010801,0.6943511,-0.2642580,-0.4438051],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet3

    ! Fotograf noktalari (ince ayarda ModPos ile guncellenir)
    CONST robtarget pFoto1 := [[-49.540,596.048,341.166],[0.3245152,0.5413259,0.4779064,0.6109514],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece
    CONST robtarget pFoto2 := [[-49.540,596.048,341.166],[0.4371489,0.6810066,0.3776314,0.4500283],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece
    CONST robtarget pFoto3 := [[-49.540,596.048,341.166],[0.5199916,0.7742777,0.2516215,0.2584365],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece
    CONST robtarget pFoto4 := [[-49.540,596.048,341.166],[0.5673977,0.8147831,0.1084640,0.0492326],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece
    CONST robtarget pFoto5 := [[-49.540,596.048,341.166],[0.5761367,0.7997624,-0.0420852,-0.1633263],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece
    CONST robtarget pFoto6 := [[-49.540,596.048,341.166],[0.5456128,0.7302392,-0.1897663,-0.3647548],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece
    CONST robtarget pFoto7 := [[-49.540,596.048,341.166],[0.4779064,0.6109514,-0.3245152,-0.5413259],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece
    CONST robtarget pFoto8 := [[-49.540,596.048,341.166],[0.1897663,0.3647548,0.5456128,0.7302392],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece
    CONST robtarget pFoto9 := [[-49.540,596.048,341.166],[0.0420852,0.1633263,0.5761366,0.7997624],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece
    CONST robtarget pFoto10 := [[-49.540,596.048,341.166],[-0.1084640,-0.0492327,0.5673977,0.8147831],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece
    CONST robtarget pFoto11 := [[-49.540,596.048,341.166],[-0.2516215,-0.2584365,0.5199915,0.7742777],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece
    CONST robtarget pFoto12 := [[-49.540,596.048,341.166],[-0.3776314,-0.4500283,0.4371488,0.6810066],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece

    VAR speeddata vKamDonus := [30,15,5000,1000];   ! 15 derece/s
    CONST num nFotoBekle := 0.5;
    VAR num nFoto;

    PROC main()
        Giris;
        ConfL \Off;
        SingArea \Wrist;
        nFoto := 0;
        ! Gidis: -180 (pFoto7) -> 0 (pFoto1) -> +150 (pFoto12), her noktada dur ve foto
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
        MoveL pFoto10, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto11, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto12, vKamDonus, fine, tKamera;
        FotoAl;
        ! Ayni yoldan geri -180'e (kablo cozulur)
        MoveL pFoto11, vKamDonus, z1, tKamera;
        MoveL pFoto10, vKamDonus, z1, tKamera;
        MoveL pFoto9, vKamDonus, z1, tKamera;
        MoveL pFoto8, vKamDonus, z1, tKamera;
        MoveL pFoto1, vKamDonus, z1, tKamera;
        MoveL pFoto2, vKamDonus, z1, tKamera;
        MoveL pFoto3, vKamDonus, z1, tKamera;
        MoveL pFoto4, vKamDonus, z1, tKamera;
        MoveL pFoto5, vKamDonus, z1, tKamera;
        MoveL pFoto6, vKamDonus, z1, tKamera;
        MoveL pFoto7, vKamDonus, fine, tKamera;
        Cikis;
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    PROC FotoAl()
        nFoto := nFoto + 1;
        TPWrite "Foto " \Num:=nFoto;
        WaitTime nFotoBekle;
    ENDPROC

    PROC Giris()
        ConfJ \Off;
        IF bHomeKullan MoveJ pHomeKul, v100, fine, tKamera;
        ConfJ \On;
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
