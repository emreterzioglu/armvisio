MODULE KameraTest360
    ! SADECE HAREKET (PC haberlesmesi yok, girdi beklemez): pHome_Base -> PROG1 -> PROG2 -> pHome_Base
    ! PROG1: 12 foto noktasi, tek yonde 330 derece: pPhoto1 (+60) -> ... -> pPhoto12 (+90, eski pos10)
    ! PROG2: pPhoto12'den pTop'a, sonra pHome_Base
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

    ! VARSAYIM: pHome_Base ve pTop tCam secili iken kaydedildi
    PERS robtarget pTop := [[-51.73,641.4,349.93],[0.116902,-0.990114,-0.0773209,0.00553204],[1,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    PERS robtarget pHome_Base := [[-14.54,276.64,339.62],[0.0207356,-0.998668,-0.0468316,0.0062025],[1,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    CONST num nKaydir := 0;      ! derece
    CONST num nGeri := 120;      ! foto noktalarina giris/cikis: optik eksen boyunca geri (mm)
    CONST num nUst := 100;       ! pTop'a giris/cikis: optik eksen boyunca geri (mm)
    VAR speeddata vScan := [100,60,5000,1000];       ! tarama: 60 derece/s (onceki 90)
    VAR speeddata vTransfer := [200,120,5000,1000];  ! gecis: 200 mm/s, 120 derece/s (onceki 300 / 180)
    CONST zonedata zPhoto := [FALSE,5,5,5,0.5,5,0.5];

    PROC main()
        Ready;
        EveGit;
        Prog1;
        Prog2;
        TPWrite "PROG1 + PROG2 bitti.";
    ENDPROC

    ! PROG1: pHome_Base -> 12 nokta (tek yon) -> pPhoto12'de biter
    PROC Prog1()
        ! Giris 0 derece (pPhoto3, OGRETILMIS konfigurasyon) uzerinden: eksen 4 her cevrimde ayni daldan baslar
        ConfJ \On;
        MoveJ RelTool(Photo(3), 0, 0, -nGeri), vTransfer, z10, tCam;
        ConfL \Off;
        MoveL Photo(3), vTransfer, z5, tCam;
        MoveL Photo(2), vTransfer, z5, tCam;
        MoveL Photo(1), vTransfer, fine, tCam;
        FOR k FROM 2 TO 11 DO
            MoveL Photo(k), vScan, zPhoto, tCam;
        ENDFOR
        MoveL Photo(12), vScan, fine, tCam;
    ENDPROC

    ! PROG2: pPhoto12'den geri cekil -> pTop -> pHome_Base
    PROC Prog2()
        MoveL RelTool(Photo(12), 0, 0, -nGeri), vTransfer, z10, tCam;
        ConfJ \On;
        MoveJ RelTool(pTop, 0, 0, -nUst), vTransfer, z10, tCam;
        ConfL \Off;
        MoveL pTop, v50, fine, tCam;
        MoveL RelTool(pTop, 0, 0, -nUst), vTransfer, z10, tCam;
        EveGit;
    ENDPROC

    PROC EveGit()
        ConfJ \On;
        MoveJ pHome_Base, vTransfer, fine, tCam;
    ENDPROC

    PROC Ready()
        tCam := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        ConfL \Off;
        SingArea \Wrist;
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
ENDMODULE
