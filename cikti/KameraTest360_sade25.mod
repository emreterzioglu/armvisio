MODULE KameraTest360
    ! Yeni braket (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! Bekleme noktasi: ilk fotonun (+90) optik eksen boyunca 120 mm gerisi.
    ! Cevrim: iceri -> tek yonde 330 derece, 12 foto durmadan -> ayni yaydan hizla geri -> bekleme noktasina cik.
    ! Gidis ve donus ayni sekilde: tKamera ile, TCP (tup merkezi) ogretilen noktalarda, robot sadece doner.
    ! Robot her cevrimi ayni noktada bitirir; eksen 4 ve kablo her seferinde ayni durumdan baslar.
    ! Sira: +90, +120, +150, -180, -150, -120, -90, -60, -30, 0, +30, +60
    ! Noktalar robot tabani (wobj0). Konfigurasyon kontrolu KAPALI (eksen 4 surekli; bilek normal duruşta kalir).
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];  ! TCP = tup merkezi

    ! 12 foto noktasi (tKamera). pFoto1-7, 10, 11: kullanicinin ince ayarli degerleri.
    !   pFoto8, 9, 12: bu 9 noktadan hesaplanan gercek tup eksenine gore (9 noktanin hepsi bu eksene <= 0.93 mm oturuyor).
    CONST robtarget pFoto1 := [[-49.40,642.80,344.60],[0.324493,0.54145,0.477769,0.610961],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece
    CONST robtarget pFoto2 := [[-50.32,641.69,344.65],[0.43715,0.681006,0.377632,0.450028],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece
    CONST robtarget pFoto3 := [[-51.00,641.08,344.70],[0.519992,0.774277,0.251623,0.258437],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece
    CONST robtarget pFoto4 := [[-51.93,641.20,344.96],[0.567296,0.814998,0.106842,0.0503807],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece
    CONST robtarget pFoto5 := [[-53.02,641.04,344.85],[0.576143,0.799768,-0.0420776,-0.163281],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece
    CONST robtarget pFoto6 := [[-53.57,641.71,345.01],[0.545612,0.73024,-0.189766,-0.364756],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece
    CONST robtarget pFoto7 := [[-52.77,642.81,345.24],[0.477914,0.610947,-0.32451,-0.541327],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece
    CONST robtarget pFoto8 := [[-50.49,643.26,345.11],[0.1897268,0.3649064,0.5455117,0.7302494],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece (TAHMIN - ogretilen deger +80 derecedeydi)
    CONST robtarget pFoto9 := [[-51.07,643.78,345.37],[0.0420311,0.1634950,0.5760787,0.7997725],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece (gercek eksenden hesaplandi)
    CONST robtarget pFoto10 := [[-52.25,644.29,345.86],[0.108464,0.0492315,-0.567399,-0.814782],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece
    CONST robtarget pFoto11 := [[-53.15,643.22,344.42],[0.251616,0.25843,-0.519996,-0.774279],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece
    CONST robtarget pFoto12 := [[-53.20,643.14,345.41],[-0.3776262,-0.4500229,0.4371541,0.6810097],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece (gercek eksenden hesaplandi)

    CONST num nSira{12} := [10,11,12,7,6,5,4,3,2,1,8,9];
    CONST num nGeri := 120;      ! giris: ilk fotonun optik eksen boyunca gerisi (mm)
    VAR speeddata vTara := [150,90,5000,1000];
    VAR speeddata vGecis := [300,180,5000,1000];
    ! --- Kamera PC haberlesmesi: ROBOT = SUNUCU (192.168.212.30:5000), PC baglanir ---
    CONST bool bKamera := TRUE;            ! FALSE: PC'siz calisir (sadece hareket)
    CONST string sRobotIp := "192.168.212.30";
    CONST num nPort := 5000;
    VAR socketdev sSunucu;
    VAR socketdev sPc;
    ! Foto bolgesi: konum 5 mm, yonelim 0.5 derece (z1'de robot her noktada neredeyse duruyordu)
    CONST zonedata zFoto := [FALSE,5,5,5,0.5,5,0.5];
    VAR triggdata trFoto;
    VAR intnum iFoto;
    VAR num nFoto;

    PROC main()
        VAR num i;
        Hazirla;
        nFoto := 0;
        IF bKamera PcBekle;
        CONNECT iFoto WITH FotoTrap;
        TriggInt trFoto, 0, iFoto;
        ! ConfJ\On: bekleme noktasina pFoto10'un OGRETILMIS konfigurasyonuyla ([0,1,-1,0], J4 +90..+180) gider.
        ! \Off iken robot bilegi ters cozumu secip J4'u ters yone, sinira kadar donduruyordu.
        ConfJ \On;
        MoveJ RelTool(pFoto10, 0, 0, -nGeri), v100, fine, tKamera;   ! bekleme noktasi
        ! Gidis da donus gibi: TCP tup merkezinde sabit, robot sadece doner (silindirik hareket)
        FOR i FROM 1 TO 12 DO
            TriggL Foto(nSira{i}), vTara, trFoto, zFoto, tKamera;
        ENDFOR
        IDelete iFoto;
        ! Ayni yaydan hizla geri +90'a (kablo cozulur, bilek her cevrimde ayni yerden baslar), sonra disari
        FOR i FROM 11 TO 1 STEP -1 DO
            MoveL Foto(nSira{i}), vGecis, z10, tKamera;
        ENDFOR
        MoveL RelTool(pFoto10, 0, 0, -nGeri), vGecis, fine, tKamera;
        IF bKamera THEN
            SocketSend sPc \Str:="BITTI;";
            SocketClose sPc;
            SocketClose sSunucu;
        ENDIF
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! Robot sunucu olur, kamera PC'sinin baglanmasini bekler (en fazla 60 s)
    PROC PcBekle()
        SocketClose sPc;
        SocketClose sSunucu;
        SocketCreate sSunucu;
        SocketBind sSunucu, sRobotIp, nPort;
        SocketListen sSunucu;
        TPWrite "Kamera PC bekleniyor...";
        SocketAccept sSunucu, sPc \Time:=60;
        TPWrite "Kamera PC baglandi.";
    ERROR
        TPWrite "Kamera PC baglanmadi (ERRNO " + NumToStr(ERRNO,0) + ")";
        Stop;
    ENDPROC

    ! Ogretme: ayni yol, her fotoda durur -> ince ayar -> o satirda ModPos
    PROC Ogret()
        Hazirla;
        ConfJ \On;
        MoveJ RelTool(pFoto10, 0, 0, -nGeri), v50, fine, tKamera;
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
        MoveL RelTool(pFoto9, 0, 0, -nGeri), v50, fine, tKamera;
    ENDPROC

    ! Takimlari ayarla
    PROC Hazirla()
        tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        ConfL \Off;
        SingArea \Wrist;
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

    ! KISA tutuldu: uzun kesme rutini (ekrana yazma vb.) hareket planlamasini geciktirip gidisi bozuyordu
    TRAP FotoTrap
        nFoto := nFoto + 1;
        IF bKamera SocketSend sPc \Str:="KONUM" + NumToStr(nSira{nFoto}, 0) + ";";
    ENDTRAP
ENDMODULE
