MODULE KameraTest360
    ! Yeni braket (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! Baslangic ve bitis HER ZAMAN pHome_Base.
    !
    ! HABERLESME: ROBOT = ISTEMCI, PC = SUNUCU (192.168.212.1:5000). Robot baglanir, PC komut verir.
    !   PC -> "HOME_MISIN"   Robot -> "HOMEDAYIM" / "HOMEDA_DEGILIM"   (pHome_Base'te mi, kontrol eder)
    !   PC -> "HAZIR_MISIN"  Robot -> "HAZIRIM" / "HAZIR_DEGILIM:<sebep>"
    !          Hazir = alan tarayicida insan yok + acil stop basili degil + motorlar acik (+ otomatik mod)
    !   PC -> "PROG1"        Robot: pHome_Base -> 360 derece tek yonlu tarama, 12 foto ("KONUM<n>;", n = 1..12)
    !                        pPhoto12'de durur, "PROG1_END;" gonderir, 10 s "PROG2" bekler
    !                        10 s icinde PROG2 gelirse oradan PROG2'ye gecer, gelmezse pHome_Base'e doner ("HOME;")
    !   PC -> "PROG2"        Robot: (pPhoto12'den ya da pHome_Base'ten) pTop'a gider, "PTOP;" gonderir,
    !                        PC'den "PTOP_OK" bekler (en fazla nTopBekle s), pHome_Base'e doner, "PROG2_END;"
    !
    ! TARAMA SIRASI (yeni numaralar): pPhoto1 (+60, robota en yakin) -> pPhoto2 (+30) -> pPhoto3 (0) -> ...
    !   -> pPhoto9 (-180) -> pPhoto10 (+150) -> pPhoto11 (+120) -> pPhoto12 (+90, eski pos10)
    ! EKSEN 4: tarama 330 derece, eksen 4 ~+-180 sinirina yakin calisir. Son noktada (pPhoto12) sikisiyorsa
    !   nKaydir ile 12 fotonun hepsi tup ekseni etrafinda birlikte kaydirilir (ornek +10: bitis sinirdan uzaklasir).
    PERS tooldata tCam := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];  ! TCP = tup merkezi

    CONST robtarget pPhoto1 := [[-51.07,643.78,345.37],[0.0420311,0.1634950,0.5760787,0.7997725],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece (eski pos9)
    CONST robtarget pPhoto2 := [[-50.49,643.26,345.11],[0.1897268,0.3649064,0.5455117,0.7302494],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece (eski pos8)
    CONST robtarget pPhoto3 := [[-49.33,642.59,344.43],[0.325663,0.540551,0.478772,0.610349],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece (eski pos1)
    CONST robtarget pPhoto4 := [[-50.32,641.69,344.65],[0.43715,0.681006,0.377632,0.450028],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece (eski pos2)
    CONST robtarget pPhoto5 := [[-51.00,641.08,344.70],[0.519992,0.774277,0.251623,0.258437],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece (eski pos3)
    CONST robtarget pPhoto6 := [[-51.93,641.20,344.96],[0.567296,0.814998,0.106842,0.0503807],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece (eski pos4)
    CONST robtarget pPhoto7 := [[-53.02,641.04,344.85],[0.576143,0.799768,-0.0420776,-0.163281],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece (eski pos5)
    CONST robtarget pPhoto8 := [[-53.57,641.71,345.01],[0.545612,0.73024,-0.189766,-0.364756],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece (eski pos6)
    CONST robtarget pPhoto9 := [[-52.77,642.81,345.24],[0.477914,0.610947,-0.32451,-0.541327],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece (eski pos7)
    CONST robtarget pPhoto10 := [[-53.20,643.14,345.41],[-0.3776262,-0.4500229,0.4371541,0.6810097],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece (eski pos12)
    CONST robtarget pPhoto11 := [[-53.15,643.22,344.42],[0.251616,0.25843,-0.519996,-0.774279],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece (eski pos11)
    CONST robtarget pPhoto12 := [[-52.25,644.29,345.86],[0.108464,0.0492315,-0.567399,-0.814782],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece (eski pos10)

    ! VARSAYIM: pHome_Base ve pTop tCam secili iken kaydedildi
    PERS robtarget pTop := [[-51.73,641.4,349.93],[0.116902,-0.990114,-0.0773209,0.00553204],[1,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    PERS robtarget pHome_Base := [[-14.54,276.64,339.62],[0.0207356,-0.998668,-0.0468316,0.0062025],[1,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    CONST num nKaydir := 0;      ! derece: 12 fotoyu tup ekseni etrafinda birlikte kaydirir (eksen 4 payi icin)
    CONST num nGeri := 120;      ! foto noktalarina giris/cikis: optik eksen boyunca geri (mm)
    CONST num nUst := 100;       ! pTop'a giris/cikis: optik eksen boyunca geri (mm)
    CONST num nProg2Bekle := 10; ! PROG1 sonunda PROG2 bekleme suresi (s)
    CONST num nTopBekle := 5;    ! pTop'ta PC'nin "PTOP_OK" cevabini bekleme (s)
    CONST num nEvTol := 2;       ! pHome_Base'te sayilma toleransi (mm)
    VAR speeddata vScan := [150,90,5000,1000];
    VAR speeddata vTransfer := [300,180,5000,1000];
    CONST zonedata zPhoto := [FALSE,5,5,5,0.5,5,0.5];

    ! --- Hazirlik kriterleri: sinyal adlari I/O ayarlarindakiyle AYNI olmali ---
    CONST bool bKontrolAlan := FALSE;      ! DSQC1042 baglaninca TRUE yapin
    CONST string sSigAlanBos := "di_Alan_Bos";      ! 1 = alan tarayicida insan YOK
    CONST bool bKontrolAcil := TRUE;
    CONST string sSigAcilStop := "do_Acil_Stop";    ! sistem cikisi "Emergency Stop": 1 = acil stop BASILI
    CONST bool bKontrolMotor := TRUE;
    CONST string sSigMotor := "do_Motor_Acik";      ! sistem cikisi "Motors On State": 1 = motorlar ACIK
    CONST bool bOtoModGerekli := TRUE;              ! FALSE: manuel modda test icin
    VAR signaldi diAlanBos;
    VAR signaldo doAcilStop;
    VAR signaldo doMotorAcik;

    ! --- Haberlesme ---
    CONST string sPcIp := "192.168.212.1";
    CONST num nPort := 5000;
    VAR socketdev robot_socket;
    VAR string user_query;
    VAR string sSebep;
    VAR bool bPcAcik := FALSE;

    VAR triggdata trPhoto;
    VAR intnum iPhoto;
    VAR num nPhoto;

    PROC main()
        SetDO do_Robot_State, 0;
        Ready;
        WHILE TRUE DO
            IF NOT bPcAcik PcConnect;
            IF bPcAcik THEN
                KomutBekle 3600;
                IF user_query <> "" KomutIsle;
            ENDIF
        ENDWHILE
    ENDPROC

    PROC KomutIsle()
        IF Komut("HOME_MISIN") THEN
            IF EvdeMi() THEN
                Gonder "HOMEDAYIM";
            ELSE
                Gonder "HOMEDA_DEGILIM";
            ENDIF
        ELSEIF Komut("HAZIR_MISIN") THEN
            IF HazirMi() THEN
                SetDO do_Robot_State, 1;
                Gonder "HAZIRIM";
            ELSE
                SetDO do_Robot_State, 0;
                Gonder "HAZIR_DEGILIM:" + sSebep;
            ENDIF
        ELSEIF Komut("PROG1") THEN
            IF NOT EvdeMi() THEN
                Gonder "HOMEDA_DEGILIM";
            ELSEIF NOT HazirMi() THEN
                SetDO do_Robot_State, 0;
                Gonder "HAZIR_DEGILIM:" + sSebep;
            ELSE
                Prog1;
            ENDIF
        ELSEIF Komut("PROG2") THEN
            IF NOT EvdeMi() THEN
                Gonder "HOMEDA_DEGILIM";
            ELSEIF NOT HazirMi() THEN
                SetDO do_Robot_State, 0;
                Gonder "HAZIR_DEGILIM:" + sSebep;
            ELSE
                Prog2 FALSE;
            ENDIF
        ELSE
            Gonder "ANLASILMADI";
        ENDIF
    ENDPROC

    ! PROG1: pHome_Base -> 12 foto (tek yon, 330 derece) -> pPhoto12'de dur -> PROG2 bekle
    PROC Prog1()
        nPhoto := 0;
        CONNECT iPhoto WITH PhotoTrap;
        TriggInt trPhoto, 0, iPhoto;
        ! Giris 0 derece (pPhoto3, OGRETILMIS konfigurasyon) uzerinden: eksen 4 her cevrimde ayni daldan baslar
        ConfJ \On;
        MoveJ RelTool(Photo(3), 0, 0, -nGeri), vTransfer, z10, tCam;
        ConfL \Off;
        MoveL Photo(3), vTransfer, z5, tCam;
        MoveL Photo(2), vTransfer, z5, tCam;
        ! Tarama: pPhoto1 (+60) -> ... -> pPhoto12 (+90), durmadan
        TriggL Photo(1), vTransfer, trPhoto, fine, tCam;
        FOR k FROM 2 TO 11 DO
            TriggL Photo(k), vScan, trPhoto, zPhoto, tCam;
        ENDFOR
        TriggL Photo(12), vScan, trPhoto, fine, tCam;
        IDelete iPhoto;
        Gonder "PROG1_END;";
        ! 10 s PROG2 tetigi bekle
        KomutBekle nProg2Bekle;
        IF Komut("PROG2") THEN
            Prog2 TRUE;
        ELSE
            MoveL RelTool(Photo(12), 0, 0, -nGeri), vTransfer, fine, tCam;
            EveGit;
            Gonder "HOME;";
        ENDIF
    ENDPROC

    ! PROG2: pTop'a git, PC'ye bildir, pHome_Base'e don. bPos12: pPhoto12'den mi geliyoruz
    PROC Prog2(bool bPos12)
        IF bPos12 MoveL RelTool(Photo(12), 0, 0, -nGeri), vTransfer, z10, tCam;
        ConfJ \On;
        MoveJ RelTool(pTop, 0, 0, -nUst), vTransfer, z10, tCam;
        ConfL \Off;
        MoveL pTop, v100, fine, tCam;
        Gonder "PTOP;";
        KomutBekle nTopBekle;          ! PC fotografi cekip "PTOP_OK" gonderebilir (gelmezse sure dolunca devam)
        MoveL RelTool(pTop, 0, 0, -nUst), vTransfer, z10, tCam;
        EveGit;
        Gonder "PROG2_END;";
    ENDPROC

    PROC EveGit()
        ConfJ \On;
        MoveJ pHome_Base, vTransfer, fine, tCam;
    ENDPROC

    FUNC bool EvdeMi()
        VAR robtarget p;
        VAR num nDot;
        p := CRobT(\Tool:=tCam \WObj:=wobj0);
        nDot := Abs(p.rot.q1*pHome_Base.rot.q1 + p.rot.q2*pHome_Base.rot.q2 + p.rot.q3*pHome_Base.rot.q3 + p.rot.q4*pHome_Base.rot.q4);
        RETURN Distance(p.trans, pHome_Base.trans) < nEvTol AND nDot > 0.9999;
    ENDFUNC

    ! Hazir mi? Degilse sSebep doldurulur
    FUNC bool HazirMi()
        sSebep := "";
        IF bKontrolAlan THEN
            IF DInput(diAlanBos) = 0 sSebep := sSebep + "ALAN_DOLU ";
        ENDIF
        IF bKontrolAcil THEN
            IF DOutput(doAcilStop) = 1 sSebep := sSebep + "ACIL_STOP ";
        ENDIF
        IF bKontrolMotor THEN
            IF DOutput(doMotorAcik) = 0 sSebep := sSebep + "MOTOR_KAPALI ";
        ENDIF
        IF bOtoModGerekli THEN
            IF OpMode() <> OP_AUTO sSebep := sSebep + "MANUEL_MOD ";
        ENDIF
        RETURN sSebep = "";
    ENDFUNC

    ! Ortak ayarlar + hazirlik sinyallerini isimle bagla
    PROC Ready()
        tCam := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        ConfL \Off;
        SingArea \Wrist;
        IF bKontrolAlan AliasIO sSigAlanBos, diAlanBos;
        IF bKontrolAcil AliasIO sSigAcilStop, doAcilStop;
        IF bKontrolMotor AliasIO sSigMotor, doMotorAcik;
    ERROR
        TPWrite "Hazirlik sinyali bulunamadi (I/O adlarini kontrol edin), ERRNO: " + NumToStr(ERRNO, 0);
        Stop;
    ENDPROC

    ! PC'ye baglan. Baglanamazsa 2 s bekleyip doner; main dongusu tekrar dener.
    PROC PcConnect()
        SocketClose robot_socket;
        SocketCreate robot_socket;
        SocketConnect robot_socket, sPcIp, nPort \Time:=10;
        bPcAcik := TRUE;
        TPWrite "PC baglantisi kuruldu.";
    ERROR
        bPcAcik := FALSE;
        SocketClose robot_socket;
        TPWrite "PC'ye baglanilamadi, tekrar denenecek (ERRNO " + NumToStr(ERRNO, 0) + ")";
        WaitTime 2;
        RETURN;
    ENDPROC

    ! PC'den komut bekle (en fazla nSure s). Gelmezse user_query = ""
    PROC KomutBekle(num nSure)
        user_query := "";
        SocketReceive robot_socket \Str:=user_query \Time:=nSure;
    ERROR
        user_query := "";
        IF ERRNO <> ERR_SOCK_TIMEOUT THEN
            bPcAcik := FALSE;      ! baglanti koptu: main yeniden baglanir
            SocketClose robot_socket;
        ENDIF
        TRYNEXT;
    ENDPROC

    FUNC bool Komut(string s)
        RETURN StrMatch(user_query, 1, s) <= StrLen(user_query);
    ENDFUNC

    PROC Gonder(string s)
        IF bPcAcik SocketSend robot_socket \Str:=s;
    ERROR
        bPcAcik := FALSE;
        TRYNEXT;
    ENDPROC

    ! Ogretme: 12 noktayi tarama sirasiyla gezer, her birinde durur -> ince ayar -> o satirda ModPos
    PROC Ogret()
        Ready;
        ConfJ \On;
        MoveJ RelTool(pPhoto3, 0, 0, -nGeri), v50, fine, tCam;
        MoveL pPhoto3, v20, fine, tCam;
        MoveL pPhoto2, v20, fine, tCam;
        MoveL pPhoto1, v20, fine, tCam;
        Stop;
        MoveL pPhoto2, v20, fine, tCam;
        Stop;
        MoveL pPhoto3, v20, fine, tCam;
        Stop;
        MoveL pPhoto4, v20, fine, tCam;
        Stop;
        MoveL pPhoto5, v20, fine, tCam;
        Stop;
        MoveL pPhoto6, v20, fine, tCam;
        Stop;
        MoveL pPhoto7, v20, fine, tCam;
        Stop;
        MoveL pPhoto8, v20, fine, tCam;
        Stop;
        MoveL pPhoto9, v20, fine, tCam;
        Stop;
        MoveL pPhoto10, v20, fine, tCam;
        Stop;
        MoveL pPhoto11, v20, fine, tCam;
        Stop;
        MoveL pPhoto12, v20, fine, tCam;
        Stop;
        MoveL RelTool(pPhoto12, 0, 0, -nGeri), v50, fine, tCam;
        EveGit;
    ENDPROC

    FUNC robtarget Photo(num nNo)
        VAR robtarget p;
        TEST nNo
        CASE 1: p := pPhoto1;
        CASE 2: p := pPhoto2;
        CASE 3: p := pPhoto3;
        CASE 4: p := pPhoto4;
        CASE 5: p := pPhoto5;
        CASE 6: p := pPhoto6;
        CASE 7: p := pPhoto7;
        CASE 8: p := pPhoto8;
        CASE 9: p := pPhoto9;
        CASE 10: p := pPhoto10;
        CASE 11: p := pPhoto11;
        DEFAULT: p := pPhoto12;
        ENDTEST
        RETURN RelTool(p, 0, 0, 0 \Ry:=nKaydir);
    ENDFUNC

    TRAP PhotoTrap
        nPhoto := nPhoto + 1;
        IF bPcAcik SocketSend robot_socket \Str:="KONUM" + NumToStr(nPhoto, 0) + ";";
    ERROR
        bPcAcik := FALSE;
        TRYNEXT;
    ENDTRAP
ENDMODULE
