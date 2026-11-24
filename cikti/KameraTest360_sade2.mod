MODULE KameraTest360
    ! Yeni braket (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! Bekleme noktasi: ilk fotonun (+90) optik eksen boyunca 120 mm gerisi.
    ! Cevrim: iceri -> tek yonde 330 derece, 12 foto durmadan -> ayni yaydan hizla geri -> bekleme noktasina cik.
    ! Robot her cevrimi ayni noktada bitirir; eksen 4 ve kablo her seferinde ayni durumdan baslar.
    ! Sira: +90, +120, +150, -180, -150, -120, -90, -60, -30, 0, +30, +60
    ! Noktalar robot tabani (wobj0). Konfigurasyon kontrolu KAPALI (eksen 4 surekli; bilek normal duruşta kalir).
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.913,234.402],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];  ! TCP = tup merkezi (ince ayar noktalarindan duzeltildi: Y -0.313, Z -1.543 mm)
    PERS tooldata tUc := [TRUE,[[-67.511,-19.913,144.457],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];      ! TCP = lens ucu (tKamera Z - 89.945)

    ! 12 foto noktasi = IDEAL DAIRE: hepsi gercek tup merkezinde (tek nokta), bakis acisi 30 derece arayla.
    !   Gercek tup ekseni ve takim duzeltmesi, kullanicinin ince ayar yaptigi 9 noktadan hesaplandi
    !   (o noktalar bu daireden flansta en fazla 1.29 mm, yonelimde en fazla 0.21 derece farkli).
    CONST robtarget pFoto1 := [[-51.841,642.459,344.996],[0.3244929,0.5414499,0.4777689,0.6109609],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +0 derece
    CONST robtarget pFoto2 := [[-51.841,642.459,344.996],[0.4371454,0.6810945,0.3774670,0.4500364],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -30 derece
    CONST robtarget pFoto3 := [[-51.841,642.459,344.996],[0.5200071,0.7743237,0.2514413,0.2584428],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -60 derece
    CONST robtarget pFoto4 := [[-51.841,642.459,344.996],[0.5674312,0.8147840,0.1082804,0.0492366],[1,-1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -90 derece
    CONST robtarget pFoto5 := [[-51.841,642.459,344.996],[0.5761858,0.7997181,-0.0422597,-0.1633249],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -120 derece
    CONST robtarget pFoto6 := [[-51.841,642.459,344.996],[0.5456743,0.7301527,-0.1899199,-0.3647561],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -150 derece
    CONST robtarget pFoto7 := [[-51.841,642.459,344.996],[0.4779760,0.6108286,-0.3246374,-0.5413298],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! -180 derece
    CONST robtarget pFoto8 := [[-51.841,642.459,344.996],[0.1897268,0.3649064,0.5455117,0.7302494],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +30 derece
    CONST robtarget pFoto9 := [[-51.841,642.459,344.996],[0.0420311,0.1634950,0.5760787,0.7997725],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +60 derece
    CONST robtarget pFoto10 := [[-51.841,642.459,344.996],[0.1085289,0.0490582,-0.5673869,-0.8147925],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +90 derece
    CONST robtarget pFoto11 := [[-51.841,642.459,344.996],[0.2516929,0.2582682,-0.5200287,-0.7742858],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +120 derece
    CONST robtarget pFoto12 := [[-51.841,642.459,344.996],[-0.3777044,-0.4498776,0.4372313,0.6810127],[0,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! +150 derece

    CONST num nSira{12} := [10,11,12,7,6,5,4,3,2,1,8,9];
    CONST num nUc := 89.945;     ! lens ucu -> tup merkezi
    CONST num nGeri := 120;      ! giris: ilk fotonun optik eksen boyunca gerisi (mm)
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
        ConfJ \Off;
        MoveJ RelTool(pFoto10, 0, 0, -nGeri), v100, fine, tKamera;   ! bekleme noktasi (zaten oradaysa hareket yok)
        FOR i FROM 1 TO 12 DO
            TriggL RelTool(Foto(nSira{i}), 0, 0, -nUc), vTara, trFoto, z0, tUc;   ! z0: foto aninda noktadan en fazla 0.3 mm
        ENDFOR
        IDelete iFoto;
        ! Ayni yaydan hizla geri +90'a (kablo cozulur, bilek her cevrimde ayni yerden baslar), sonra disari
        FOR i FROM 11 TO 1 STEP -1 DO
            MoveL Foto(nSira{i}), vGecis, z10, tKamera;
        ENDFOR
        MoveL RelTool(pFoto10, 0, 0, -nGeri), vGecis, fine, tKamera;
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! Ogretme: ayni yol, her fotoda durur -> ince ayar -> o satirda ModPos
    PROC Ogret()
        Hazirla;
        ConfJ \Off;
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
        tKamera := [TRUE,[[-67.511,-19.913,234.402],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
        tUc := [TRUE,[[-67.511,-19.913,144.457],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
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

    TRAP FotoTrap
        VAR jointtarget j;
        nFoto := nFoto + 1;
        j := CJointT();
        TPWrite "Foto " \Num:=nFoto;
        TPWrite "  J4=" \Num:=j.robax.rax_4;
    ENDTRAP
ENDMODULE
