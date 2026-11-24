MODULE KameraTest360
    ! Yeni braket (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! HOME -> tek yonde 330 derece, 12 foto durmadan -> HOME
    ! Sira: +90, +120, +150, -180, -150, -120, -90, -60, -30, 0, +30, +60
    ! Noktalar robot tabani (wobj0). Konfigurasyon kontrolu KAPALI (eksen 4 surekli; bilek normal duruşta kalir).
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];  ! TCP = tup merkezi
    PERS tooldata tUc := [TRUE,[[-67.511,-19.6,146.0],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];      ! TCP = lens ucu

    ! HOME: tupun ucunun ustu (robotun daha once ulastigi deger)
    CONST robtarget pHomeKul := [[-48.101,637.090,352.293],[0.0940770,-0.7699387,0.6122421,0.1533083],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! 12 foto noktasi (tKamera). Kullanicinin degerleri; pFoto8 haric (bkz. not).
    CONST robtarget pFoto1 := [[-49.40,642.80,344.60],[0.324493,0.54145,0.477769,0.610961],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! 0 derece
    CONST robtarget pFoto2 := [[-50.32,641.69,344.65],[0.43715,0.681006,0.377632,0.450028],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece
    CONST robtarget pFoto3 := [[-51.00,641.08,344.70],[0.519992,0.774277,0.251623,0.258437],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece
    CONST robtarget pFoto4 := [[-51.93,641.20,344.96],[0.567296,0.814998,0.106842,0.0503807],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece
    CONST robtarget pFoto5 := [[-53.02,641.04,344.85],[0.576143,0.799768,-0.0420776,-0.163281],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece
    CONST robtarget pFoto6 := [[-53.57,641.71,345.01],[0.545612,0.73024,-0.189766,-0.364756],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece
    CONST robtarget pFoto7 := [[-52.77,642.81,345.24],[0.477914,0.610947,-0.32451,-0.541327],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece
    CONST robtarget pFoto8 := [[-50.49,643.26,345.11],[0.1897268,0.3649064,0.5455117,0.7302494],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece (TAHMIN - ogretilen deger +80 derecedeydi)
    CONST robtarget pFoto9 := [[-49.540,641.048,341.166],[0.0420852,0.1633263,0.5761366,0.7997624],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece
    CONST robtarget pFoto10 := [[-52.25,644.29,345.86],[0.108464,0.0492315,-0.567399,-0.814782],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece
    CONST robtarget pFoto11 := [[-53.15,643.22,344.42],[0.251616,0.25843,-0.519996,-0.774279],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece
    CONST robtarget pFoto12 := [[-49.540,641.048,341.166],[-0.3776314,-0.4500283,0.4371488,0.6810066],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece

    CONST num nSira{12} := [10,11,12,7,6,5,4,3,2,1,8,9];
    CONST num nUc := 89.945;     ! lens ucu -> tup merkezi
    CONST num nGeri := 120;      ! giris: ilk fotonun optik eksen boyunca gerisi (mm)
    CONST num nKalkis := 50;     ! cikis: dik kalkis (mm)
    VAR speeddata vTara := [150,90,5000,1000];
    VAR speeddata vGecis := [300,180,5000,1000];
    VAR triggdata trFoto;
    VAR intnum iFoto;
    VAR num nFoto;

    PROC main()
        VAR num i;
        Hazirla;
        nFoto := 0;
        CONNECT iFoto WITH FotoTrap;
        TriggInt trFoto, 0, iFoto;
        MoveL RelTool(pFoto10, 0, 0, -nGeri), vGecis, z10, tKamera;
        FOR i FROM 1 TO 12 DO
            TriggL RelTool(Foto(nSira{i}), 0, 0, -nUc), vTara, trFoto, z1, tUc;
        ENDFOR
        IDelete iFoto;
        EveDon;
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! Ogretme: ayni yol, her fotoda durur -> ince ayar -> o satirda ModPos
    PROC Ogret()
        Hazirla;
        MoveL RelTool(pFoto10, 0, 0, -nGeri), v50, fine, tKamera;
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

    ! Takimlari ayarla, HOME'da degilse HOME'a git
    PROC Hazirla()
        tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        tUc := [TRUE,[[-67.511,-19.6,146.0],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        ConfL \Off;
        SingArea \Wrist;
        IF Distance(CPos(\Tool:=tKamera \WObj:=wobj0), pHomeKul.trans) > 5 EveDon;
    ENDPROC

    ! Z'de dik kalk, HOME'a dogrusal git
    PROC EveDon()
        VAR robtarget p;
        p := CRobT(\Tool:=tKamera \WObj:=wobj0);
        MoveL Offs(p, 0, 0, nKalkis), v100, z10, tKamera;
        MoveL pHomeKul, v100, fine, tKamera;
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
        VAR jointtarget j;
        nFoto := nFoto + 1;
        j := CJointT();
        TPWrite "Foto " \Num:=nFoto;
        TPWrite "  J4=" \Num:=j.robax.rax_4;
    ENDTRAP
ENDMODULE
