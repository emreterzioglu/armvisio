MODULE KameraTest360
    ! YENI BRAKET (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! HIZLI SUREKLI TARAMA: HOME -> 12 foto -> HOME, robot arada hic durmaz; 12 foto hareket halinde cekilir.
    !   Yol kisa tutuldu: HOME'dan dogrudan ilk fotoya, son fotodan 30 mm dik kalkip dogrudan HOME'a.
    !   HOME'un kendi ekseni etrafindaki acisi ilk (+60) ve son (+90) fotonun ortasina (+75) alindi -> giris/cikista ~90 derece donus.
    !   Sira: +90, +120, +150, -180, -150, -120, -90, -60, -30, 0, +30, +60  (tek yonde 330 derece)
    ! Iki takim, ayni montaj:
    !   tKamera: TCP = tup merkezi. Z = 56.0 (kamera on yuzu, v1 CAD) + 90 (lens, olculen) + 86 (odak) + 3.945 = 235.945
    !   tUc    : TCP = lens ucu.    Z = 56.0 + 90 = 146.0  (tarama bununla yapilir; noktalar pFoto'lardan otomatik turetilir)
    !   Kamera yakin/uzak bakiyorsa IKISININ Z'sini AYNI miktar degistirin (+ uzaklastirir).
    ! Foto tetigi: dijital cikis YOK. Her foto noktasinda kamera PC'sine TCP soketle "TRIG;n;" gonderilir
    !   (kamera_sunucu.py). bKamera := FALSE yapilirsa PC'siz calisir (sadece hareket + sayac).
    ! HOME (pHomeKul): tupun ucunun ustu. Bu deger robotun daha once ulastigi (sade surum) HOME; Ogret'te ModPos yapilacak
    !   (gercek eksen konfigurasyonu kaydedilsin diye). main ve EveDon HOME'a MoveJ + ConfJ\On ile gider.
    ! Program baslarken robot HOME'da degilse: once Z'de 150 mm dik kalkis, sonra HOME (EveDon).
    ! Noktalar robot tabani (wobj0), 45 mm bosluklu istasyon. Kutle/agirlik merkezi YER TUTUCU.
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
    PERS tooldata tUc := [TRUE,[[-67.511,-19.6,146.0],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];

    CONST robtarget pHomeKul := [[-48.101,637.090,352.293],[0.0940770,-0.7699387,0.6122421,0.1533083],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! 12 foto noktasi (tKamera, TCP = tup merkezi). Ogretme: Ogret rutini ile her noktada dur, ince ayar, ModPos.
    ! pFoto1-7, 10, 11: kullanicinin ogrettigi net konumlar. pFoto8 (+30), pFoto9 (+60), pFoto12 (+150):
    !   ogretilen 10 noktadan hesaplanan gercek tup eksenine gore baslangic tahmini (ogretilecek).
    CONST robtarget pFoto1 := [[-49.40,642.80,344.60],[0.324493,0.54145,0.477769,0.610961],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece  (OGRETILDI)
    CONST robtarget pFoto2 := [[-50.32,641.69,344.65],[0.43715,0.681006,0.377632,0.450028],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece  (OGRETILDI)
    CONST robtarget pFoto3 := [[-51.00,641.08,344.70],[0.519992,0.774277,0.251623,0.258437],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece  (OGRETILDI)
    CONST robtarget pFoto4 := [[-51.93,641.20,344.96],[0.567296,0.814998,0.106842,0.0503807],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece  (OGRETILDI)
    CONST robtarget pFoto5 := [[-53.02,641.04,344.85],[0.576143,0.799768,-0.0420776,-0.163281],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece  (OGRETILDI)
    CONST robtarget pFoto6 := [[-53.57,641.71,345.01],[0.545612,0.73024,-0.189766,-0.364756],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece  (OGRETILDI)
    CONST robtarget pFoto7 := [[-52.77,642.81,345.24],[0.477914,0.610947,-0.32451,-0.541327],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece  (OGRETILDI)
    CONST robtarget pFoto8 := [[-50.49,643.26,345.11],[0.1897268,0.3649064,0.5455117,0.7302494],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece (TAHMIN, ogretilecek)
    CONST robtarget pFoto9 := [[-51.07,643.78,345.37],[0.0420311,0.1634950,0.5760787,0.7997725],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece (TAHMIN, ogretilecek)
    CONST robtarget pFoto10 := [[-52.25,644.29,345.86],[0.108464,0.0492315,-0.567399,-0.814782],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece  (OGRETILDI)
    CONST robtarget pFoto11 := [[-53.15,643.22,344.42],[0.251616,0.25843,-0.519996,-0.774279],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece  (OGRETILDI)
    CONST robtarget pFoto12 := [[-53.20,643.14,345.41],[0.3776262,0.4500229,-0.4371541,-0.6810097],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece (TAHMIN, ogretilecek)
    ! Cekim sirasi (tek yonde 330 derece): +90,+120,+150,-180,-150,-120,-90,-60,-30,0,+30,+60
    !   ONEMLI: pFoto10/11 onceki dosyada BILEK TERS iken ogretildi (robconf o duruşa ait). Ogret rutini bunlari
    !   normal bilekte, -180'den eksi yonde donerek ziyaret eder; ModPos ile normal bilek robconf'u kaydedilir.
    !   Giris bu robconf ile yapilir (MoveJ, ConfJ\On): eksen 4 her cevrimde ayni daldan baslar.
    CONST num nSira{12} := [10,11,12,7,6,5,4,3,2,1,8,9];
    CONST num nGeri := 120;    ! giris: pFoto10'dan optik eksen boyunca geri (mm)
    CONST num nYukari := 100;  ! giris: ustune (mm)
    CONST num nUc := 89.945;   ! lens ucu -> tup merkezi (86 + 3.945)

    ! HIZLAR (robot kendi eksen hiz sinirinda daha yavas gidebilir; kamera fps'ine gore ayarlayin)
    VAR speeddata vTara := [150,90,5000,1000];    ! tarama: 90 derece/s -> 30 derece ~0.33 s, 330 derece ~3.7 s
    VAR speeddata vGecis := [300,180,5000,1000];  ! HOME <-> tarama gecisi
    CONST num nKalkis := 50;                      ! HOME'a gitmeden once dik kalkis (mm): tarama sonu ve EveDon
    ! Kamera PC baglantisi
    CONST bool bKamera := FALSE;           ! TRUE: kamera PC'sine baglan ve tetik gonder
    PERS string sPcIp := "192.168.1.10";   ! kamera PC'sinin robota bakan IP'si
    PERS num nPcPort := 5000;              ! kamera_sunucu.py ile ayni
    VAR socketdev sockKam;
    VAR triggdata trFoto;
    VAR intnum iFoto;
    VAR num nFoto;

    PROC main()
        VAR num i;
        ! Eski modullerden kalan ayni isimli PERS takim degerlerini ez (yanlis TCP = robot yanlis yere gider)
        tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        tUc := [TRUE,[[-67.511,-19.6,146.0],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        ConfL \Off;
        SingArea \Wrist;
        IF Distance(CPos(\Tool:=tKamera \WObj:=wobj0), pHomeKul.trans) > 5 EveDon;
        nFoto := 0;
        IF bKamera KameraBaglan;
        CONNECT iFoto WITH FotoTrap;
        TriggInt trFoto, 0, iFoto;
        ! Giris: ogretilmis konfigurasyonla pFoto10'un geri-ustune (MoveJ), sonra optik eksen boyunca ice; foto 1..12 durmadan
        Giris;
        ! (tarama lens ucu takimi tUc ile: ogretilen tKamera noktasi optik eksen boyunca nUc geri = ayni flans pozu)
        TriggL RelTool(Foto(nSira{1}), 0, 0, -nUc), vGecis, trFoto, z1, tUc;   ! foto 1 (+90)
        FOR i FROM 2 TO 12 DO
            TriggL RelTool(Foto(nSira{i}), 0, 0, -nUc), vTara, trFoto, z1, tUc;
        ENDFOR
        ! Dik kalkis ve HOME (eklem hareketi, en yakin konfigurasyon)
        MoveL Offs(Foto(nSira{12}), 0, 0, nKalkis), vGecis, z10, tKamera;
        ConfJ \On;
        MoveJ pHomeKul, vGecis, fine, tKamera;
        IDelete iFoto;
        IF bKamera THEN
            SocketSend sockKam \Str:="END;";
            SocketClose sockKam;
        ENDIF
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! OGRETME (once bunu calistirin). PP'yi bu rutine alin. Her Stop'ta: tool'da lineer ince ayar -> o MoveL satirinda ModPos.
    !   Sira robotun normal bilek duruşunu korur: HOME -> -180 -> eksi yonde +150,+120,+90 -> geri -180 -> arti yonde 0,+30,+60.
    PROC Ogret()
        VAR robtarget p;
        ConfL \Off;
        SingArea \Wrist;
        p := CRobT(\Tool:=tKamera \WObj:=wobj0);
        MoveL Offs(p, 0, 0, nKalkis), v50, fine, tKamera;
        MoveL pHomeKul, v50, fine, tKamera;
        Stop;   ! HOME: ModPos (gerekirse once ince ayar)
        MoveL RelTool(pFoto7, 0, 0, -nGeri), v50, fine, tKamera;
        MoveL pFoto7, v20, fine, tKamera;
        Stop;
        MoveL pFoto12, v20, fine, tKamera;
        Stop;
        MoveL pFoto11, v20, fine, tKamera;
        Stop;
        MoveL pFoto10, v20, fine, tKamera;
        Stop;
        MoveL pFoto11, v20, z1, tKamera;
        MoveL pFoto12, v20, z1, tKamera;
        MoveL pFoto7, v20, z1, tKamera;
        MoveL pFoto6, v20, z1, tKamera;
        MoveL pFoto5, v20, z1, tKamera;
        MoveL pFoto4, v20, z1, tKamera;
        MoveL pFoto3, v20, z1, tKamera;
        MoveL pFoto2, v20, z1, tKamera;
        MoveL pFoto1, v20, fine, tKamera;
        Stop;
        MoveL pFoto8, v20, fine, tKamera;
        Stop;
        MoveL pFoto9, v20, fine, tKamera;
        Stop;
        EveDon;
    ENDPROC

    FUNC robtarget Foto(num i)
        TEST i
        CASE 1: RETURN pFoto1;
        CASE 2: RETURN pFoto2;
        CASE 3: RETURN pFoto3;
        CASE 4: RETURN pFoto4;
        CASE 5: RETURN pFoto5;
        CASE 6: RETURN pFoto6;
        CASE 7: RETURN pFoto7;
        CASE 8: RETURN pFoto8;
        CASE 9: RETURN pFoto9;
        CASE 10: RETURN pFoto10;
        CASE 11: RETURN pFoto11;
        DEFAULT: RETURN pFoto12;
        ENDTEST
    ENDFUNC

    ! pFoto10'un OGRETILMIS robconf'u ile (eksen 4 dogru dalda) yaklas
    PROC Giris()
        ConfJ \On;
        MoveJ Offs(RelTool(pFoto10, 0, 0, -nGeri), 0, 0, nYukari), vGecis, z10, tKamera;
        ConfL \Off;
        MoveL RelTool(pFoto10, 0, 0, -nGeri), vGecis, z5, tKamera;
    ENDPROC

    TRAP FotoTrap
        VAR jointtarget jt;
        nFoto := nFoto + 1;
        jt := CJointT();
        TPWrite "Foto " \Num:=nFoto;
        TPWrite "  J4=" \Num:=jt.robax.rax_4;
        IF bKamera SocketSend sockKam \Str:="TRIG;" + NumToStr(nFoto, 0) + ";";
    ENDTRAP

    PROC KameraBaglan()
        SocketClose sockKam;
        SocketCreate sockKam;
        SocketConnect sockKam, sPcIp, nPcPort \Time:=5;
    ERROR
        TPWrite "Kamera PC'sine baglanilamadi: " + sPcIp;
        Stop;
    ENDPROC

    ! Bulundugu yerden Z'de nKalkis kadar dik kalk, sonra HOME (eklem hareketi).
    ! pHomeKul ROBOTTA OGRETILMELI (jog + bu satirda ModPos): hesaplanan HOME robota ulasilamiyor.
    PROC EveDon()
        VAR robtarget p;
        ConfL \Off;
        p := CRobT(\Tool:=tKamera \WObj:=wobj0);
        MoveL Offs(p, 0, 0, nKalkis), v50, fine, tKamera;
        ConfJ \On;
        MoveJ pHomeKul, v100, fine, tKamera;
    ENDPROC
ENDMODULE
