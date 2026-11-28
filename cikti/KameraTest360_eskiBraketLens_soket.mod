MODULE KameraTest360
    ! TCP = TUPUN MERKEZ CIZGISI. Robot hep bu noktanin etrafinda doner; TCP hic yer degistirmez.
    ! ESKI BRAKET + Computar MLM-3XMP lens (CAD)
    ! tKamera Z = 76.026 (lens baglanti yuzu, eski EOAT CAD) + 79.500 (lens, MLM-3XMP CAD)
    !           + 86 (lens metal ucu -> tup yuzeyi) + 3.945 (tup yaricapi, D7.89/2) = 245.471 mm
    ! Net goruntu noktasi tup yuzeyi (TCP'den 3.945 mm once). Kamera her acida tupe dik ve merkeze bakar.
    !
    ! ISTASYON: istasyon_robot_tabani.step -> robot RobotStudio'da (0,0,0), donus 0, dosya (0,0,0).
    ! Tum noktalar robot tabani (wobj0) koordinatlarinda.
    !
    ! INCE AYAR SURUMU: 7 fotograf noktasi (0,-30,...,-180) ayri ayri adlandirildi (pFoto1..pFoto7).
    ! Her nokta gercek robotta ortalanip yataylanip ModPos ile kaydedilebilir.
    ! Fotolar arasi MoveL: TCP (tup merkezi) sabit kalir, robot yalnizca yonelimi dondurur.
    ! Kutle 0.5 kg / agirlik merkezi YER TUTUCU
    PERS tooldata tKamera := [TRUE,[[0,68,245.471],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];

    CONST bool bHomeKullan := TRUE;

    ! HOME: robot durusu onceki kodla ayni (deger yeni TCP'ye gore). Ara nokta/yaklasma/fotolar: TCP = tup merkezi, degismedi
    CONST robtarget pHomeKul := [[-360.053,337.582,437.652],[0.4117930,0.5867360,-0.3940890,-0.5752060],[1,1,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pAra := [[-166.134,568.134,496.308],[0.3245152,0.5413259,0.4779064,0.6109514],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    CONST robtarget pYaklas := [[-166.134,568.134,346.308],[0.3245152,0.5413259,0.4779064,0.6109514],[1,-1,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! Kullanicinin 3 referans konumu, bu takima (tKamera) cevrilmis hali. Sadece kontrol icin, programda kullanilmaz.
    ! pRef3 orijinali tKamera (242.546) ile kaydedildi VARSAYIMIYLA cevrildi.
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

    VAR speeddata vKamDonus := [30,15,5000,1000];   ! 15 derece/s
    CONST num nFotoBekle := 0.5;
    VAR num nFoto;

    ! --- Kamera PC haberlesmesi: PC = sunucu (kamera_sunucu.py), robot = istemci ---
    PERS string sPcIp := "192.168.1.10";   ! Kamera PC'sinin robota bakan ethernet IP'si (kendi degerinizi yazin)
    PERS num nPcPort := 5000;              ! kamera_sunucu.py ile ayni port
    VAR socketdev sockKam;
    VAR string sCevap;

    PROC main()
        KameraBaglan;
        Giris;
        ConfL \Off;
        SingArea \Wrist;
        nFoto := 0;
        ! Gidis: her noktada dur, "foto" (ince ayar: robot burada dururken ortalayip ModPos yapin)
        MoveL pFoto1, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto2, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto3, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto4, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto5, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto6, vKamDonus, fine, tKamera;
        FotoAl;
        MoveL pFoto7, vKamDonus, fine, tKamera;
        FotoAl;
        ! Ayni yoldan geri (kablo cozulur)
        MoveL pFoto6, vKamDonus, z1, tKamera;
        MoveL pFoto5, vKamDonus, z1, tKamera;
        MoveL pFoto4, vKamDonus, z1, tKamera;
        MoveL pFoto3, vKamDonus, z1, tKamera;
        MoveL pFoto2, vKamDonus, z1, tKamera;
        MoveL pFoto1, vKamDonus, fine, tKamera;
        ConfL \On;
        Cikis;
        SocketSend sockKam \Str:="END;";
        SocketClose sockKam;
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! Robot durdu -> "TRIG;n;" gonder -> PC "ACK;n;OK;" donene kadar bekle (en fazla 10 s)
    PROC FotoAl()
        nFoto := nFoto + 1;
        WaitTime nFotoBekle;                   ! titresim sonsun
        SocketSend sockKam \Str:="TRIG;" + NumToStr(nFoto, 0) + ";";
        SocketReceive sockKam \Str:=sCevap \Time:=10;
        IF sCevap <> "ACK;" + NumToStr(nFoto, 0) + ";OK;" THEN
            TPWrite "Kamera hatali cevap: " + sCevap;
            Stop;
        ENDIF
        TPWrite "Foto " \Num:=nFoto;
    ERROR
        TPWrite "Kamera PC cevap vermedi, foto no: " \Num:=nFoto;
        Stop;
    ENDPROC

    PROC KameraBaglan()
        SocketClose sockKam;
        SocketCreate sockKam;
        SocketConnect sockKam, sPcIp, nPcPort \Time:=5;
        TPWrite "Kamera PC'sine baglandi.";
    ERROR
        TPWrite "Kamera PC'sine baglanilamadi: " + sPcIp;
        Stop;
    ENDPROC

    PROC Giris()
        ConfJ \On;
        IF bHomeKullan MoveJ pHomeKul, v100, fine, tKamera;
        MoveJ pAra, v100, fine, tKamera;
        MoveL pYaklas, v100, fine, tKamera;
        MoveL pFoto1, v50, fine, tKamera;
    ENDPROC

    PROC Cikis()
        MoveL pYaklas, v50, fine, tKamera;
        MoveL pAra, v100, fine, tKamera;
        ConfJ \On;
        IF bHomeKullan MoveJ pHomeKul, v100, fine, tKamera;
    ENDPROC
ENDMODULE
