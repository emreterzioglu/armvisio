MODULE KameraTest360
    ! YENI BRAKET (eoat_assembly_v1, flansa 180 derece donuk) + Computar MLM-3XMP lens. Robot kameranin ustunde.
    ! 360 DERECE, 12 foto (30 derece arayla), iki kisim:
    !   A: -180 -> 0 -> +60 (foto 1-9), geri -180, cikis pUst.  B: pUst'te bilek ters -> +90..+150 (foto 10-12), geri, bilek duz, HOME.
    ! TCP = TUP MERKEZI. tKamera Z = 65.480 (lens baglanti yuzu, v1 CAD) + 79.500 (lens CAD) + 86 (lens metal ucu -> tup yuzeyi)
    !       + 3.945 (tup yaricapi) = 235.945 mm.  X,Y = -67.511,-19.6 (v1 CAD).
    ! ODAK (86 mm) AYARI: nOdakDuzelt. pFoto1'de lens metal ucu ile tup yuzeyi arasini olcun:
    !       nOdakDuzelt := 86 - olculen.  (+ deger kamerayi uzaklastirir, - yaklastirir). Noktalar degismez.
    ! YARIDA KESILIP BASTAN BASLATMA: main once GuvenliBasla'yi calistirir. Robot neredeyse oradan guvenli yoldan HOME'a doner:
    !   tup etrafindaysa ayni yaydan geri, yaklasma hattindaysa optik eksen boyunca geri + yukari, bilek ters ise duzeltir.
    ! ROBOTSTUDIO: istasyon_fiziksel_zemin0_45bosluk.step (0,0,0); robot (0,0,820), donus Z = -90.
    ! Noktalar robot tabani (wobj0), parca 45 mm bosluklu konumda. Kutle/agirlik merkezi YER TUTUCU.
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
    PERS num nOdakDuzelt := 0;

    ! Durum (PERS: program yarida kesilse de saklanir)
    PERS bool bBilekTers := FALSE;
    PERS bool bJUstVar := FALSE;
    PERS jointtarget jUstNormal := [[0,0,0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! HOME: kullanicinin HOME durusu. pUst: pAra'nin 100 mm ustu. pAra: pYaklas'in 150 mm ustu.
    ! pYaklas: pFoto7'den optik eksen boyunca 120 mm geri. pAraB/pYaklasB: ayni mantik, pFoto10 (+90) icin.
    ! pUst/pAra/pYaklas/pAraB/pYaklasB robconf TAHMIN -> bu hareketlerde konfigurasyon kontrolu kapali.
    CONST robtarget pUst := [[67.055,668.962,586.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pHomeKul := [[-348.869,279.502,343.717],[0.4117930,0.5867360,-0.3940890,-0.5752060],[1,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pAra := [[67.055,668.962,486.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pYaklas := [[67.055,668.962,336.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pAraB := [[-25.143,531.376,449.013],[-0.1084640,-0.0492327,0.5673977,0.8147831],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pYaklasB := [[-25.143,531.376,299.013],[-0.1084640,-0.0492327,0.5673977,0.8147831],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! Fotograf noktalari: hepsi tup merkezinde, sadece yonelim degisir (CAD tup ekseni)
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

    ! Kullanici referanslari (kontrol icin, programda kullanilmaz; bosluk sonrasi yeniden kaydedilmeli)
    CONST robtarget pRef1 := [[-49.509,645.504,343.089],[0.3593369,0.5187635,0.4482773,0.6330947],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet1
    CONST robtarget pRef2 := [[-47.174,639.294,340.742],[0.4512960,0.8631220,0.1873698,0.1274553],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet2
    CONST robtarget pRef3 := [[-52.047,635.841,341.186],[0.5010801,0.6943511,-0.2642580,-0.4438051],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];   ! pNet3

    CONST num nSiraA{9} := [7,6,5,4,3,2,1,8,9];
    CONST num nSiraB{3} := [10,11,12];
    VAR speeddata vKamDonus := [30,15,5000,1000];   ! 15 derece/s
    CONST num nFotoBekle := 0.5;
    VAR num nFoto;

    PROC main()
        tKamera.tframe.trans.z := 235.945 + nOdakDuzelt;
        GuvenliBasla;
        ConfL \Off;
        SingArea \Wrist;
        nFoto := 0;
        ! A kismi
        MoveL pUst, v100, fine, tKamera;
        MoveL pAra, v100, fine, tKamera;
        MoveL pYaklas, v100, fine, tKamera;
        FOR k FROM 1 TO 9 DO
            MoveL Foto(nSiraA{k}), vKamDonus, fine, tKamera;
            FotoAl;
        ENDFOR
        FOR k FROM 8 TO 1 STEP -1 DO
            MoveL Foto(nSiraA{k}), vKamDonus, z1, tKamera;
        ENDFOR
        MoveL pFoto7, vKamDonus, fine, tKamera;
        MoveL pYaklas, v50, fine, tKamera;
        MoveL pAra, v100, fine, tKamera;
        MoveL pUst, v100, fine, tKamera;
        ! B kismi
        BilekTers;
        MoveL pAraB, v100, fine, tKamera;
        MoveL pYaklasB, v100, fine, tKamera;
        FOR k FROM 1 TO 3 DO
            MoveL Foto(nSiraB{k}), vKamDonus, fine, tKamera;
            FotoAl;
        ENDFOR
        MoveL pFoto11, vKamDonus, z1, tKamera;
        MoveL pFoto10, vKamDonus, fine, tKamera;
        MoveL pYaklasB, v50, fine, tKamera;
        MoveL pAraB, v100, fine, tKamera;
        MoveL pUst, v100, fine, tKamera;
        BilekDuz;
        MoveL pHomeKul, v100, fine, tKamera;
        ConfL \On;
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! Robot nerede olursa olsun guvenli yoldan HOME'a getirir
    PROC GuvenliBasla()
        VAR robtarget p;
        VAR num d;
        VAR num kBas;
        VAR bool bUstte := FALSE;
        ConfL \Off;
        p := CRobT(\Tool:=tKamera \WObj:=wobj0);
        d := Distance(p.trans, pFoto1.trans);
        IF d < 2 THEN
            ! Tup etrafinda: ayni yaydan cikis noktasina geri
            IF bBilekTers THEN
                kBas := EnYakin(p.rot, TRUE);
                FOR k FROM kBas TO 1 STEP -1 DO
                    MoveL Foto(nSiraB{k}), vKamDonus, fine, tKamera;
                ENDFOR
                MoveL pYaklasB, v50, fine, tKamera;
                MoveL pAraB, v100, fine, tKamera;
            ELSE
                kBas := EnYakin(p.rot, FALSE);
                FOR k FROM kBas TO 1 STEP -1 DO
                    MoveL Foto(nSiraA{k}), vKamDonus, fine, tKamera;
                ENDFOR
                MoveL pYaklas, v50, fine, tKamera;
                MoveL pAra, v100, fine, tKamera;
            ENDIF
            MoveL pUst, v100, fine, tKamera;
            bUstte := TRUE;
        ELSEIF d < 300 THEN
            ! Parcaya yakin: optik eksen boyunca 100 mm geri, sonra pUst yuksekligine dik cik
            MoveL RelTool(p, 0, 0, -100), v50, fine, tKamera;
            p := CRobT(\Tool:=tKamera \WObj:=wobj0);
            IF p.trans.z < pUst.trans.z THEN
                p.trans.z := pUst.trans.z;
                MoveL p, v50, fine, tKamera;
            ENDIF
            MoveL pUst, v100, fine, tKamera;
            bUstte := TRUE;
        ELSEIF bBilekTers THEN
            MoveL pUst, v100, fine, tKamera;
            bUstte := TRUE;
        ENDIF
        IF bBilekTers BilekDuz;
        IF bUstte THEN
            MoveL pHomeKul, v100, fine, tKamera;
        ELSE
            ConfJ \On;
            MoveJ pHomeKul, v100, fine, tKamera;
        ENDIF
    ENDPROC

    ! pUst'te: ayni TCP pozu, bilegin diger durusu (J4, J6 180 derece; J5 isaret degistirir)
    PROC BilekTers()
        VAR jointtarget j;
        j := CJointT();
        jUstNormal := j;
        bJUstVar := TRUE;
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
        bBilekTers := TRUE;
        MoveAbsJ j, v50, fine, tKamera;
    ENDPROC

    ! pUst'te kaydedilen normal duruşa tam olarak geri doner
    PROC BilekDuz()
        IF bJUstVar THEN
            MoveL pUst, v100, fine, tKamera;
            MoveAbsJ jUstNormal, v50, fine, tKamera;
        ENDIF
        bBilekTers := FALSE;
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

    ! Su anki yonelime en yakin foto noktasinin sira numarasi (A veya B dizisinde)
    FUNC num EnYakin(orient o, bool bB)
        VAR num n;
        VAR num en := 1;
        VAR num enIyi := -1;
        VAR num s;
        VAR robtarget f;
        IF bB THEN
            n := 3;
        ELSE
            n := 9;
        ENDIF
        FOR k FROM 1 TO n DO
            IF bB THEN
                f := Foto(nSiraB{k});
            ELSE
                f := Foto(nSiraA{k});
            ENDIF
            s := Abs(o.q1*f.rot.q1 + o.q2*f.rot.q2 + o.q3*f.rot.q3 + o.q4*f.rot.q4);
            IF s > enIyi THEN
                enIyi := s;
                en := k;
            ENDIF
        ENDFOR
        RETURN en;
    ENDFUNC

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
ENDMODULE
