MODULE KameraTest360
    ! PC HABERLESMELI CEVRIM (robot_haberlesme.py ile ayni protokol). ROBOT = ISTEMCI, PC = SUNUCU
    ! Robot 192.168.212.30 -> PC 192.168.212.1:5000. PC sorar, robot TEK satir cevap verir (sonuna CR LF).
    !   HOME_MISIN     -> HOME / HOME_DEGIL
    !   HAZIR_MISIN    -> HAZIRIM / DEGILIM        (oto mod + robot evde)
    !   START1         -> START1_OK, sonra PROG1 (pHome_Base -> 12 foto noktasi, pPhoto12'de biter)
    !   PROG1_BITTI_MI -> DEVAM (hareket surerken) / PROG1_BITTI
    !   KONUM2_GIT     -> pTop'un ustune yaklasir, PROG1 baslangicinin girisine (pPhoto1, ogretilmis konf.) gecer,
    !                     29 derece egilerek radyusun ilk noktasina (pTopPhoto1, +60) iner, varinca KONUM2_GITTIM
    !   START2         -> START2_OK, sonra PROG2: radyus etrafinda PROG1 ile AYNI yonde (ustten saat yonu)
    !                     pTopPhoto1 (+60) -> ... -> pTopPhoto12 (+90). Iki uc da robota en yakin iki nokta.
    !   PROG2_BITTI_MI -> DEVAM / PROG2_BITTI
    !   HOME_GIT       -> pHome_Base'e gider, varinca HOME_GITTIM
    ! Hareket surerken gelen PROGx_BITTI_MI sorularini zaman kesmesi (TRAP + SocketPeek) cevaplar.
    ! Eksen 4 son noktada sikisirsa nKaydir'i artirin (ornek 10): 12 nokta tup ekseni etrafinda birlikte kayar.
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

    ! 12 RADYUS noktasi (tup ust ucundaki radyuslu kenar, kamera radyus ortasina dik, yatayin 29 derece asagisina bakar).
    ! Ayni numarali pPhoto noktasindan hesaplandi: tup ekseni boyunca 6.02 mm (+ nokta duzeltmesi) yukari, 0.16 mm kameraya dogru,
    ! tool x etrafinda 29 derece. 6.02 mm, NET goruntu veren pTop'tan olculen ust yuzey yuksekliginden geliyor (CAD degil).
    ! Gerekirse ModPos ile tek tek ince ayar yapilabilir.
    CONST robtarget pTopPhoto1 := [[-50.39,641.64,350.95],[-0.0002436,0.1688110,0.7579763,0.6300593],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece, radyus ortasi
    CONST robtarget pTopPhoto2 := [[-49.88,641.15,350.71],[0.0923183,0.4007870,0.7109757,0.5704040],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece, radyus ortasi
    CONST robtarget pTopPhoto3 := [[-48.73,640.48,350.33],[0.1799467,0.6048726,0.6163411,0.4710329],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece, radyus ortasi
    CONST robtarget pTopPhoto4 := [[-49.76,639.77,350.20],[0.2527154,0.7687678,0.4782814,0.3411420],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece, radyus ortasi
    CONST robtarget pTopPhoto5 := [[-50.41,639.28,350.11],[0.3095655,0.8798099,0.3083156,0.1872038],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece, radyus ortasi
    CONST robtarget pTopPhoto6 := [[-51.30,639.47,350.29],[0.3451671,0.9310780,0.1160532,0.0220249],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece, radyus ortasi
    CONST robtarget pTopPhoto7 := [[-52.27,639.25,350.34],[0.3575454,0.9185478,-0.0816196,-0.1475447],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece, radyus ortasi
    CONST robtarget pTopPhoto8 := [[-52.73,639.83,350.61],[0.3453953,0.8435901,-0.2750490,-0.3056239],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece, radyus ortasi
    CONST robtarget pTopPhoto9 := [[-51.89,640.85,350.86],[0.3097224,0.7111471,-0.4497111,-0.4428337],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece, radyus ortasi
    CONST robtarget pTopPhoto10 := [[-52.32,641.10,351.01],[-0.2529212,-0.5302386,0.5937409,0.5498633],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece, radyus ortasi
    CONST robtarget pTopPhoto11 := [[-52.20,640.79,350.89],[0.1788957,0.3131979,-0.6972967,-0.6194196],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece, radyus ortasi
    CONST robtarget pTopPhoto12 := [[-51.51,642.19,351.29],[0.0926826,0.0748206,-0.7533313,-0.6467641],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece, radyus ortasi

    ! VARSAYIM: pHome_Base ve pTop tCam secili iken kaydedildi
    ! pTop: KONUM2_GIT'te sadece yaklasma noktasi (pTop'a inilmez); radyus noktalarinin yuksekligi de bundan hesaplandi
    PERS robtarget pTop := [[-51.73,641.4,349.93],[0.116902,-0.990114,-0.0773209,0.00553204],[1,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    PERS robtarget pHome_Base := [[-14.54,276.64,339.62],[0.0207356,-0.998668,-0.0468316,0.0062025],[1,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];


    CONST num nKaydir := 0;      ! derece
    CONST num nGeri := 120;      ! foto noktalarina giris/cikis: optik eksen boyunca geri (mm)
    CONST num nUst := 100;       ! pTop'a giris/cikis: optik eksen boyunca geri (mm)
    CONST num nEvTol := 5;       ! robot pHome_Base'e bu mesafeden (mm) yakinsa "evde" sayilir
    VAR speeddata vScan := [100,60,5000,1000];
    VAR speeddata vTransfer := [200,120,5000,1000];
    CONST zonedata zPhoto := [FALSE,5,5,5,0.5,5,0.5];

    ! --- Haberlesme ---
    CONST string sPcIp := "192.168.212.1";
    CONST num nPort := 5000;
    CONST bool bOtoModGerekli := TRUE;   ! manuel modda denemek icin FALSE yapin
    VAR socketdev skPc;
    VAR bool bBagli := FALSE;
    VAR bool bHata;
    VAR string sKomut;
    VAR string sTrap;
    VAR string sBekleyen;                ! hareket surerken DEVAM cevabi verilecek soru
    VAR intnum iSorgu;
    VAR bool bProg1Bitti := FALSE;
    VAR bool bProg2Bitti := FALSE;

    ! Robotun bilinen konumu
    CONST num KON_BILINMIYOR := 0;
    CONST num KON_EV := 1;
    CONST num KON_P12 := 2;
    CONST num KON_TOP := 3;
    CONST num KON_T12 := 4;      ! pTopPhoto12'de
    CONST num KON_T1 := 5;       ! pTopPhoto1'de
    VAR num nKonum := 0;

    PROC main()
        Ready;
        IF EvdeMi() THEN
            nKonum := KON_EV;
        ELSE
            nKonum := KON_BILINMIYOR;
        ENDIF
        TPWrite "PC komutlari bekleniyor.";
        WHILE TRUE DO
            IF NOT bBagli PcBaglan;
            sKomut := KomutAl();
            IF sKomut <> "" KomutIsle sKomut;
        ENDWHILE
    ENDPROC

    PROC KomutIsle(string s)
        TEST s
        CASE "HOME_MISIN":
            IF EvdeMi() THEN
                Cevap "HOME";
            ELSE
                Cevap "HOME_DEGIL";
            ENDIF
        CASE "HAZIR_MISIN":
            IF HazirMi() THEN
                Cevap "HAZIRIM";
            ELSE
                Cevap "DEGILIM";
            ENDIF
        CASE "START1":
            IF NOT EvdeMi() THEN
                Cevap "HOME_DEGIL";      ! tabloda yok: PC hata verir, robot hareket etmez
            ELSE
                bProg1Bitti := FALSE;
                Cevap "START1_OK";
                SorguAc "PROG1_BITTI_MI";
                Prog1;
                SorguKapat;
                bProg1Bitti := TRUE;
            ENDIF
        CASE "PROG1_BITTI_MI":
            IF bProg1Bitti THEN
                Cevap "PROG1_BITTI";
            ELSE
                Cevap "DEVAM";
            ENDIF
        CASE "KONUM2_GIT":
            Konum2Git;
            Cevap "KONUM2_GITTIM";
        CASE "START2":
            bProg2Bitti := FALSE;
            Cevap "START2_OK";
            SorguAc "PROG2_BITTI_MI";
            Prog2;
            SorguKapat;
            bProg2Bitti := TRUE;
        CASE "PROG2_BITTI_MI":
            IF bProg2Bitti THEN
                Cevap "PROG2_BITTI";
            ELSE
                Cevap "DEVAM";
            ENDIF
        CASE "HOME_GIT":
            EveGit;
            Cevap "HOME_GITTIM";
        DEFAULT:
            TPWrite "Bilinmeyen komut: " + s;
            Cevap "BILINMEYEN_KOMUT";
        ENDTEST
    ENDPROC

    ! PROG1: pHome_Base -> 12 nokta (tek yon, pPhoto1 +60 ile baslar) -> pPhoto12'de biter
    PROC Prog1()
        nKonum := KON_BILINMIYOR;
        ConfJ \On;
        MoveJ RelTool(Photo(1), 0, 0, -nGeri), vTransfer, z10, tCam;
        ConfL \Off;
        MoveL Photo(1), vTransfer, fine, tCam;
        FOR k FROM 2 TO 11 DO
            MoveL Photo(k), vScan, zPhoto, tCam;
        ENDFOR
        MoveL Photo(12), vScan, fine, tCam;
        nKonum := KON_P12;
    ENDPROC

    ! KONUM2: pTop'un ustune yaklasir, eve ugrar (durmadan), PROG1 girisine gider (pPhoto1, ogretilmis konfigurasyon),
    ! sonra sadece 29 derece egilip radyusun ilk noktasina. Buyuk donusler, calisan koddaki ile ayni
    ! iki eklem hareketi (pTop ustu -> ev, ev -> PROG1 girisi) ile yapilir.
    ! (Eski surumde pTop'tan pTopPhoto12'ye dogrusal gecis 179 derecelik donustu: yon belirsiz -> sapitma.)
    PROC Konum2Git()
        IF nKonum = KON_T1 RETURN;
        IF nKonum = KON_BILINMIYOR OR nKonum = KON_T12 EveGit;
        IF nKonum = KON_P12 MoveL RelTool(Photo(12), 0, 0, -nGeri), vTransfer, z10, tCam;
        nKonum := KON_BILINMIYOR;
        ConfJ \On;
        MoveJ RelTool(pTop, 0, 0, -nUst), vTransfer, z10, tCam;          ! pTop yaklasma noktasi (eskisiyle ayni)
        MoveJ pHome_Base, vTransfer, z50, tCam;                          ! pTop ustu -> ev (eski HOME_GIT yolu)
        MoveJ RelTool(Photo(1), 0, 0, -nGeri), vTransfer, z10, tCam;     ! ev -> PROG1 girisi (START1 ile ayni hareket)
        ConfL \Off;
        MoveL RelTool(TopPhoto(1), 0, 0, -nGeri), vTransfer, z10, tCam;  ! 29 derece egim, radyus +60 noktasinin 120 mm gerisi
        MoveL TopPhoto(1), v50, fine, tCam;
        nKonum := KON_T1;
    ENDPROC

    ! PROG2: radyus etrafinda PROG1 ile ayni yonde: pTopPhoto1 (+60) -> pTopPhoto12 (+90)
    PROC Prog2()
        IF nKonum <> KON_T1 Konum2Git;
        nKonum := KON_BILINMIYOR;
        ConfL \Off;
        FOR k FROM 2 TO 11 DO
            MoveL TopPhoto(k), vScan, zPhoto, tCam;
        ENDFOR
        MoveL TopPhoto(12), vScan, fine, tCam;
        nKonum := KON_T12;
    ENDPROC

    ! KONTROL (PC'siz, manuel modda, PP to Routine): radyus noktalarinda tek tek durur.
    ! Goruntu net ve radyus ortasi merkezde mi bakin; gerekirse o satirda ModPos.
    PROC FiletKontrol()
        Ready;
        EveGit;
        Konum2Git;
        Stop;
        FOR k FROM 2 TO 12 DO
            MoveL TopPhoto(k), v20, fine, tCam;
            Stop;
        ENDFOR
        nKonum := KON_T12;
        EveGit;
    ENDPROC

    ! Bulundugu yerden optik eksen boyunca geri cekilip pHome_Base'e
    PROC EveGit()
        IF NOT EvdeMi() THEN
            TEST nKonum
            CASE KON_TOP:
                MoveL RelTool(pTop, 0, 0, -nUst), vTransfer, z10, tCam;
            CASE KON_P12:
                MoveL RelTool(Photo(12), 0, 0, -nGeri), vTransfer, z10, tCam;
            CASE KON_T12:
                MoveL RelTool(TopPhoto(12), 0, 0, -nGeri), vTransfer, z10, tCam;
            CASE KON_T1:
                MoveL RelTool(TopPhoto(1), 0, 0, -nGeri), vTransfer, z10, tCam;
            DEFAULT:
                ! konum bilinmiyor (ornek: hareket yarida kesildi): kamera ekseni boyunca geri
                MoveL RelTool(CRobT(\Tool:=tCam \WObj:=wobj0), 0, 0, -nGeri), v50, z10, tCam;
            ENDTEST
        ENDIF
        nKonum := KON_BILINMIYOR;
        ConfJ \On;
        MoveJ pHome_Base, vTransfer, fine, tCam;
        nKonum := KON_EV;
    ENDPROC

    PROC Ready()
        tCam := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        ConfL \Off;
        SingArea \Wrist;
    ENDPROC

    FUNC bool EvdeMi()
        VAR robtarget p;
        p := CRobT(\Tool:=tCam \WObj:=wobj0);
        RETURN Distance(p.trans, pHome_Base.trans) < nEvTol;
    ENDFUNC

    ! Program calisiyorsa motorlar zaten acik ve acil stop basili degildir.
    FUNC bool HazirMi()
        IF bOtoModGerekli AND OpMode() <> OP_AUTO RETURN FALSE;
        RETURN EvdeMi();
    ENDFUNC

    ! ---------------- Haberlesme ----------------
    PROC PcBaglan()
        WHILE NOT bBagli DO
            bHata := FALSE;
            SocketClose skPc;
            SocketCreate skPc;
            SocketConnect skPc, sPcIp, nPort \Time:=5;
            IF bHata THEN
                WaitTime 2;          ! PC programi acik degil: 2 s sonra tekrar dene
            ELSE
                bBagli := TRUE;
                TPWrite "PC'ye baglandi.";
            ENDIF
        ENDWHILE
    ERROR
        bHata := TRUE;
        TRYNEXT;
    ENDPROC

    ! Gelen komutu dondurur; zaman asiminda veya kopmada "" dondurur
    FUNC string KomutAl()
        VAR string s;
        SocketReceive skPc \Str:=s \Time:=60;
        RETURN Temizle(s);
    ERROR
        IF ERRNO <> ERR_SOCK_TIMEOUT THEN
            bBagli := FALSE;
            SocketClose skPc;
        ENDIF
        RETURN "";
    ENDFUNC

    ! Cevabi CR LF ile gonderir
    PROC Cevap(string s)
        IF bBagli SocketSend skPc \Str:=s + "\0D\0A";
    ERROR
        bBagli := FALSE;
        TRYNEXT;
    ENDPROC

    ! Ilk satiri alir: bastaki ve sondaki CR / LF karakterlerini atar
    FUNC string Temizle(string s)
        VAR num n;
        WHILE StrLen(s) > 0 DO
            IF NOT StrMemb(s, 1, "\0D\0A") THEN
                n := StrFind(s, 1, "\0D\0A");
                IF n <= StrLen(s) s := StrPart(s, 1, n - 1);
                RETURN s;
            ENDIF
            IF StrLen(s) = 1 RETURN "";
            s := StrPart(s, 2, StrLen(s) - 1);
        ENDWHILE
        RETURN "";
    ENDFUNC

    ! Hareket sirasinda: 0.1 s'de bir sokete bakar, PROGx_BITTI_MI gelmisse DEVAM der
    PROC SorguAc(string s)
        sBekleyen := s;
        IDelete iSorgu;
        CONNECT iSorgu WITH SorguTrap;
        ITimer 0.1, iSorgu;
    ENDPROC

    PROC SorguKapat()
        IDelete iSorgu;
    ENDPROC

    TRAP SorguTrap
        IF NOT bBagli RETURN;
        IF SocketPeek(skPc) > 0 THEN
            SocketReceive skPc \Str:=sTrap \Time:=1;
            IF Temizle(sTrap) = sBekleyen THEN
                Cevap "DEVAM";
            ELSE
                Cevap "MESGUL";      ! hareket surerken baska komut: tabloda yok, PC hata verir
            ENDIF
        ENDIF
    ERROR
        bBagli := FALSE;         ! baglanti koptu: hareket devam eder, bitince yeniden baglanilir
        RETURN;
    ENDTRAP

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

    FUNC robtarget TopPhoto(num nNo)
        VAR robtarget p;
        TEST nNo
        CASE 1: p := pTopPhoto1;
        CASE 2: p := pTopPhoto2;
        CASE 3: p := pTopPhoto3;
        CASE 4: p := pTopPhoto4;
        CASE 5: p := pTopPhoto5;
        CASE 6: p := pTopPhoto6;
        CASE 7: p := pTopPhoto7;
        CASE 8: p := pTopPhoto8;
        CASE 9: p := pTopPhoto9;
        CASE 10: p := pTopPhoto10;
        CASE 11: p := pTopPhoto11;
        DEFAULT: p := pTopPhoto12;
        ENDTEST
        RETURN p;
    ENDFUNC
ENDMODULE
