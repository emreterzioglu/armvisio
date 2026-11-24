MODULE SoketSunucuTest
    ! SADECE HABERLESME TESTI (robot hareket etmez). Robot = sunucu, PC baglanir.
    ! Baska modul (KameraTest360) yukluyken calistirmayin: "main" cakisir.
    CONST string sRobotIp := "192.168.212.30";
    CONST num nPort := 5000;
    VAR socketdev sSunucu;
    VAR socketdev sPc;

    PROC main()
        VAR num i;
        SocketClose sPc;
        SocketClose sSunucu;
        SocketCreate sSunucu;
        SocketBind sSunucu, sRobotIp, nPort;
        SocketListen sSunucu;
        TPWrite "PC bekleniyor: " + sRobotIp + ":" + NumToStr(nPort, 0);
        SocketAccept sSunucu, sPc \Time:=120;
        TPWrite "PC baglandi.";
        FOR i FROM 1 TO 12 DO
            SocketSend sPc \Str:="KONUM" + NumToStr(i, 0) + ";";
            WaitTime 0.5;
        ENDFOR
        SocketSend sPc \Str:="BITTI;";
        SocketClose sPc;
        SocketClose sSunucu;
        TPWrite "Test bitti.";
    ERROR
        TPWrite "Soket hatasi, ERRNO: " + NumToStr(ERRNO, 0);
        SocketClose sPc;
        SocketClose sSunucu;
        Stop;
    ENDPROC
ENDMODULE
