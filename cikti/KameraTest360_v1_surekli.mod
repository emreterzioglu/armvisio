MODULE KameraTest360
    ! YENI BRAKET (v1, flansa 180 derece donuk) + Computar lens. Robot kameranin ustunde.
    ! SUREKLI TARAMA: robot durmadan doner, 12 foto hareket halinde cekilir (30 derece arayla, ~1 s aralikla).
    !   Sira: +90, +120, +150, -180, -150, -120, -90, -60, -30, 0, +30, +60  (tek yonde 330 derece)
    ! Iki takim, ayni montaj:
    !   tKamera: TCP = tup merkezi. Z = 56.0 (kamera on yuzu, v1 CAD) + 90 (lens, olculen) + 86 (odak) + 3.945 = 235.945
    !   tUc    : TCP = lens ucu.    Z = 56.0 + 90 = 146.0  (tarama bununla yapilir: uc tupun etrafinda daire cizer)
    !   Kamera yakin/uzak bakiyorsa IKISININ Z'sini AYNI miktar degistirin (+ uzaklastirir).
    ! Foto tetigi: doKameraTetik dijital cikisi (I/O konfigurasyonunda TANIMLANMALI, isim yer tutucu).
    ! HOME (pHomeKul): tupun ucunun ustu, tup ekseni boyunca asagi bakis. HOME'a gidis: once Z'de 150 mm dik kalkis.
    ! Noktalar robot tabani (wobj0), 45 mm bosluklu istasyon. Kutle/agirlik merkezi YER TUTUCU.
    PERS tooldata tKamera := [TRUE,[[-67.511,-19.6,235.945],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];
    PERS tooldata tUc := [TRUE,[[-67.511,-19.6,146.0],[0.7071068,0,0,-0.7071068]],[0.5,[-45,0,30],[1,0,0,0],0,0,0]];

    CONST robtarget pHomeKul := [[-48.101,637.090,352.293],[0.0940770,-0.7699387,0.6122421,0.1533083],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    ! Yaklasma (tKamera): ilk fotonun (+90) 120 mm gerisi
    CONST robtarget pYaklas := [[-25.143,531.376,299.013],[-0.1084640,-0.0492327,0.5673977,0.8147831],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    ! 12 foto noktasi (tUc, lens ucu), cekim sirasiyla
    CONST robtarget pUc{12} := [
        [[-31.253,558.844,309.571],[-0.1084640,-0.0492327,0.5673977,0.8147831],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[9.993,580.319,311.876],[-0.2516215,-0.2584365,0.5199915,0.7742777],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[35.288,618.066,322.030],[-0.3776314,-0.4500283,0.4371488,0.6810066],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[37.853,661.971,337.311],[0.4779064,0.6109514,-0.3245152,-0.5413259],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[17.001,700.270,353.625],[0.5456128,0.7302392,-0.1897663,-0.3647548],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[-21.681,722.700,366.601],[0.5761367,0.7997624,-0.0420852,-0.1633263],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[-67.827,723.252,372.761],[0.5673977,0.8147831,0.1084640,0.0492326],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[-109.073,701.777,370.456],[0.5199916,0.7742777,0.2516215,0.2584365],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[-134.368,664.030,360.302],[0.4371489,0.6810066,0.3776314,0.4500283],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[-136.933,620.125,345.021],[0.3245152,0.5413259,0.4779064,0.6109514],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[-116.081,581.826,328.707],[0.1897663,0.3647548,0.5456128,0.7302392],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]],
        [[-77.399,559.396,315.731],[0.0420852,0.1633263,0.5761366,0.7997624],[0,0,-1,0],[9E9,9E9,9E9,9E9,9E9,9E9]]
    ];

    VAR speeddata vTara := [50,33,5000,1000];   ! uc 50 mm/s, donus 33 derece/s -> ~0.93 s / 30 derece
    VAR triggdata trFoto;
    VAR intnum iFoto;
    VAR num nFoto;

    PROC main()
        VAR num i;
        EveDon;
        ConfL \Off;
        SingArea \Wrist;
        MoveL pYaklas, v100, fine, tKamera;
        MoveL pUc{1}, v50, fine, tUc;
        ! Foto 1: baslangicta (robot duruyor)
        nFoto := 1;
        PulseDO \PLength:=0.02, doKameraTetik;
        ! Foto 2-12: hareket halinde, her noktadan gecerken tetik
        CONNECT iFoto WITH FotoTrap;
        TriggInt trFoto, 0, iFoto;
        FOR i FROM 2 TO 11 DO
            TriggL pUc{i}, vTara, trFoto, z1, tUc;
        ENDFOR
        TriggL pUc{12}, vTara, trFoto, fine, tUc;
        IDelete iFoto;
        TPWrite "Toplam foto: " \Num:=nFoto;
        EveDon;
    ENDPROC

    TRAP FotoTrap
        nFoto := nFoto + 1;
        PulseDO \PLength:=0.02, doKameraTetik;
    ENDTRAP

    ! Bulundugu yerden Z'de 150 mm dik kalk, sonra HOME
    PROC EveDon()
        VAR robtarget p;
        ConfL \Off;
        p := CRobT(\Tool:=tKamera \WObj:=wobj0);
        MoveL Offs(p, 0, 0, 150), v50, fine, tKamera;
        MoveL pHomeKul, v100, fine, tKamera;
    ENDPROC
ENDMODULE
