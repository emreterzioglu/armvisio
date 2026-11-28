MODULE SoketTest
    ! SADECE HABERLESME TESTI - robot hareket etmez.
    ! Bu modulu yuklerken baska modul (KameraTest360 vb.) yuklu OLMASIN: "main" ve degisken adlari cakisir.
    PERS string sPcIp := "192.168.1.10";   ! Kamera PC'sinin robota bakan ethernet IP'si
    PERS num nPcPort := 5000;
    VAR socketdev sockKam;
    VAR string sCevap;

    PROC main()
        VAR num i;
        SocketClose sockKam;
        SocketCreate sockKam;
        SocketConnect sockKam, sPcIp, nPcPort \Time:=5;
        TPWrite "Baglandi.";
        FOR i FROM 1 TO 3 DO
            SocketSend sockKam \Str:="TRIG;" + NumToStr(i, 0) + ";";
            SocketReceive sockKam \Str:=sCevap \Time:=10;
            TPWrite "Cevap: " + sCevap;
        ENDFOR
        SocketSend sockKam \Str:="END;";
        SocketClose sockKam;
        TPWrite "Test bitti.";
    ERROR
        TPWrite "Soket hatasi, ERRNO: " \Num:=ERRNO;
        SocketClose sockKam;
        Stop;
    ENDPROC
ENDMODULE
