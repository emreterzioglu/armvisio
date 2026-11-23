MODULE KameraTest360
    ! YENI BRAKET (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! TCP = tup merkezi: Z = 65.480 (lens baglanti yuzu) + 79.500 (lens) + 86 (odak) + 3.945 (tup yaricapi) = 235.945
    !   Kamera parcaya yakin/uzak bakiyorsa sadece Z'yi degistirin (+ uzaklastirir). Noktalar degismez.
    ! HOME (pHomeKul): kamera tupun ucunun ustunde, tup ekseni boyunca asagi bakar (lens ucu tup ucundan 86 mm).
    ! HOME'a gidis (EveDon): once bulundugu yerde Z'de 150 mm dik kalkis, sonra pHomeKul.
    ! Tarama: -180'den girer. Once -180 -> +90 (eksi yonde, foto 1-4), sonra +90 -> +60 (arti yonde, foto 5-12),
    !   ayni yoldan -180'e geri doner (kablo cozulur), yaklasma noktasindan cikar, HOME.
    ! Noktalar robot tabani (wobj0), 45 mm bosluklu istasyon. Kutle/agirlik merkezi YER TUTUCU.
    ! RobotStudio: istasyon_fiziksel_zemin0_45bosluk.step (0,0,0); robot (0,0,820), donus Z = -90.
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];

    CONST robtarget pHomeKul := [[-48.101,637.090,352.293],[0.0940770,-0.7699387,0.6122421,0.1533083],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    ! Yaklasma: pFoto7'den optik eksen boyunca 120 mm geri
    CONST robtarget pYaklas := [[67.055,668.962,336.023],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! Foto noktalari: hepsi tup merkezinde, sadece bakis acisi degisir
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

    VAR speeddata vKamDonus := [30,15,5000,1000];   ! 15 derece/s
    CONST num nFotoBekle := 0.5;
    VAR num nFoto;

    PROC main()
        EveDon;
        ConfL \Off;
        SingArea \Wrist;
        nFoto := 0;
        MoveL pYaklas, v100, fine, tKamera;
        ! -180 -> +90 (eksi yonde)
        Foto pFoto7;
        Foto pFoto12;
        Foto pFoto11;
        Foto pFoto10;
        ! +90 -> +60 (arti yonde, -180'den gecerek)
        MoveL pFoto11, vKamDonus, z1, tKamera;
        MoveL pFoto12, vKamDonus, z1, tKamera;
        MoveL pFoto7, vKamDonus, z1, tKamera;
        Foto pFoto6;
        Foto pFoto5;
        Foto pFoto4;
        Foto pFoto3;
        Foto pFoto2;
        Foto pFoto1;
        Foto pFoto8;
        Foto pFoto9;
        ! Ayni yoldan -180'e geri (kablo cozulur)
        MoveL pFoto8, vKamDonus, z1, tKamera;
        MoveL pFoto1, vKamDonus, z1, tKamera;
        MoveL pFoto2, vKamDonus, z1, tKamera;
        MoveL pFoto3, vKamDonus, z1, tKamera;
        MoveL pFoto4, vKamDonus, z1, tKamera;
        MoveL pFoto5, vKamDonus, z1, tKamera;
        MoveL pFoto6, vKamDonus, z1, tKamera;
        MoveL pFoto7, vKamDonus, fine, tKamera;
        MoveL pYaklas, v50, fine, tKamera;
        EveDon;
        TPWrite "Toplam foto: " \Num:=nFoto;
    ENDPROC

    ! Bulundugu yerden Z'de 150 mm dik kalk, sonra HOME
    PROC EveDon()
        VAR robtarget p;
        ConfL \Off;
        p := CRobT(\Tool:=tKamera \WObj:=wobj0);
        MoveL Offs(p, 0, 0, 150), v50, fine, tKamera;
        MoveL pHomeKul, v100, fine, tKamera;
    ENDPROC

    ! Noktaya git, dur, foto
    PROC Foto(robtarget pt)
        VAR jointtarget j;
        MoveL pt, vKamDonus, fine, tKamera;
        nFoto := nFoto + 1;
        j := CJointT();
        TPWrite "Foto " \Num:=nFoto;
        TPWrite "J4=" \Num:=j.robax.rax_4;
        WaitTime nFotoBekle;
    ENDPROC
ENDMODULE
