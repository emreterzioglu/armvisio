MODULE KameraTest360
    ! YENI BRAKET (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! HIZLI SUREKLI TARAMA: HOME -> 12 foto -> HOME, robot arada hic durmaz; 12 foto hareket halinde cekilir.
    !   Yol kisa tutuldu: HOME'dan dogrudan ilk fotoya, son fotodan 30 mm dik kalkip dogrudan HOME'a.
    !   HOME'un kendi ekseni etrafindaki acisi ilk ve son fotonun ortasina (+75) alindi -> giris/cikista ~90 derece donus.
    !   Sira: +90, +120, +150, -180, -150, -120, -90, -60, -30, 0, +30, +60  (tek yonde 330 derece)
    ! Iki takim, ayni montaj:
    !   tKamera: TCP = tup merkezi. Z = 56.0 (kamera on yuzu, v1 CAD) + 90 (lens, olculen) + 86 (odak) + 3.945 = 235.945
    !   tUc    : TCP = lens ucu.    Z = 56.0 + 90 = 146.0  (tarama bununla yapilir; noktalar pFoto'lardan otomatik turetilir)
    !   Kamera yakin/uzak bakiyorsa IKISININ Z'sini AYNI miktar degistirin (+ uzaklastirir).
    ! Foto tetigi: dijital cikis YOK. Her foto noktasinda kamera PC'sine TCP soketle "TRIG;n;" gonderilir
    !   (kamera_sunucu.py). bKamera := FALSE yapilirsa PC'siz calisir (sadece hareket + sayac).
    ! HOME (pHomeKul): tupun ucunun ustu, tup ekseni boyunca asagi bakis (lens ucu tup ucundan 86 mm).
    ! Program baslarken robot HOME'da degilse: once Z'de 150 mm dik kalkis, sonra HOME (EveDon).
    ! Noktalar robot tabani (wobj0), 45 mm bosluklu istasyon. Kutle/agirlik merkezi YER TUTUCU.
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
    PERS tooldata tUc := [TRUE,[[-67.511,-19.6,146.0],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];

    CONST robtarget pHomeKul := [[-48.101,637.090,352.293],[0.0643572,-0.0170153,-0.9835428,-0.1679646],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! 12 foto noktasi (tKamera, TCP = tup merkezi). Ogretme: Ogret rutini ile her noktada dur, ince ayar, ModPos.
    ! pFoto1-6 kullanicinin ogrettigi degerler; pFoto7-12 bu 6 noktadan hesaplanan baslangic tahmini (ogretilecek).
    CONST robtarget pFoto1 := [[-49.40,642.80,344.60],[0.324493,0.54145,0.477769,0.610961],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece   (OGRETILDI)
    CONST robtarget pFoto2 := [[-50.32,641.69,344.65],[0.43715,0.681006,0.377632,0.450028],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece   (OGRETILDI)
    CONST robtarget pFoto3 := [[-51.00,641.08,344.70],[0.519992,0.774277,0.251623,0.258437],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece   (OGRETILDI)
    CONST robtarget pFoto4 := [[-51.93,641.20,344.96],[0.567296,0.814998,0.106842,0.0503807],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece   (OGRETILDI)
    CONST robtarget pFoto5 := [[-53.02,641.04,344.85],[0.576143,0.799768,-0.0420776,-0.163281],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece   (OGRETILDI)
    CONST robtarget pFoto6 := [[-53.57,641.71,345.01],[0.545612,0.73024,-0.189766,-0.364756],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece   (OGRETILDI)
    CONST robtarget pFoto7 := [[-53.75,642.90,345.55],[0.4779064,0.6109514,-0.3245152,-0.5413259],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece (TAHMIN)
    CONST robtarget pFoto8 := [[-49.91,643.65,345.32],[0.1897663,0.3647548,0.5456128,0.7302392],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece (TAHMIN)
    CONST robtarget pFoto9 := [[-50.57,644.39,345.67],[0.0420852,0.1633263,0.5761366,0.7997624],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece (TAHMIN)
    CONST robtarget pFoto10 := [[-51.55,644.71,345.91],[-0.1084640,-0.0492327,0.5673977,0.8147831],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece (TAHMIN)
    CONST robtarget pFoto11 := [[-52.58,644.50,345.97],[-0.2516215,-0.2584365,0.5199915,0.7742777],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece (TAHMIN)
    CONST robtarget pFoto12 := [[-53.39,643.84,345.84],[-0.3776314,-0.4500283,0.4371488,0.6810066],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece (TAHMIN)
    ! Cekim sirasi (tek yonde 330 derece): +90,+120,+150,-180,-150,-120,-90,-60,-30,0,+30,+60
    CONST num nSira{12} := [10,11,12,7,6,5,4,3,2,1,8,9];
    CONST num nUc := 89.945;   ! lens ucu -> tup merkezi (86 + 3.945)

    ! HIZLAR (robot kendi eksen hiz sinirinda daha yavas gidebilir; kamera fps'ine gore ayarlayin)
    VAR speeddata vTara := [150,90,5000,1000];    ! tarama: 90 derece/s -> 30 derece ~0.33 s, 330 derece ~3.7 s
    VAR speeddata vGecis := [300,180,5000,1000];  ! HOME <-> tarama gecisi
    CONST num nKalkis := 30;                      ! son fotodan sonra dik kalkis (mm)
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
        ! HOME -> foto 1 (dogrudan), foto 1..12 durmadan
        ! (tarama lens ucu takimi tUc ile: ogretilen tKamera noktasi optik eksen boyunca nUc geri = ayni flans pozu)
        TriggL RelTool(Foto(nSira{1}), 0, 0, -nUc), vGecis, trFoto, z1, tUc;
        FOR i FROM 2 TO 12 DO
            TriggL RelTool(Foto(nSira{i}), 0, 0, -nUc), vTara, trFoto, z1, tUc;
        ENDFOR
        ! Dik kalkis ve HOME (durmadan)
        MoveL Offs(Foto(nSira{12}), 0, 0, nKalkis), vGecis, z10, tKamera;
        MoveL pHomeKul, vGecis, fine, tKamera;
        IDelete iFoto;
        IF bKamera THEN
            SocketSend sockKam \Str:="END;";
            SocketClose sockKam;
        ENDIF
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! OGRETME: PP'yi bu rutine alin. Her noktada durur -> tool'da lineer ince ayar -> MoveL satirinda ModPos -> devam.
    PROC Ogret()
        ConfL \Off;
        SingArea \Wrist;
        MoveL pFoto10, v20, fine, tKamera;
        Stop;
        MoveL pFoto11, v20, fine, tKamera;
        Stop;
        MoveL pFoto12, v20, fine, tKamera;
        Stop;
        MoveL pFoto7, v20, fine, tKamera;
        Stop;
        MoveL pFoto6, v20, fine, tKamera;
        Stop;
        MoveL pFoto5, v20, fine, tKamera;
        Stop;
        MoveL pFoto4, v20, fine, tKamera;
        Stop;
        MoveL pFoto3, v20, fine, tKamera;
        Stop;
        MoveL pFoto2, v20, fine, tKamera;
        Stop;
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

    TRAP FotoTrap
        nFoto := nFoto + 1;
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

    ! Bulundugu yerden Z'de 150 mm dik kalk, sonra HOME
    PROC EveDon()
        VAR robtarget p;
        ConfL \Off;
        p := CRobT(\Tool:=tKamera \WObj:=wobj0);
        MoveL Offs(p, 0, 0, 150), v50, fine, tKamera;
        MoveL pHomeKul, v100, fine, tKamera;
    ENDPROC
ENDMODULE
