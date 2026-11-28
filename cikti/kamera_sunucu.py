# Kamera PC'si (Windows) - TCP sunucu. Robot baglanir, "TRIG;n;" gonderir, biz fotografi cekip "ACK;n;OK;" doneriz.
# Calistirma:  python kamera_sunucu.py      (Python 3, ek paket gerekmez)
import socket

HOST = "0.0.0.0"   # tum ag kartlarinda dinle
PORT = 5000        # RAPID'deki nPcPort ile ayni

def foto_cek(n):
    # BURAYA kameranin kendi yazilimini/SDK'sini cagiran kod gelecek.
    # Basarili ise True, degilse False donsun.
    print(f"  -> foto {n} cekildi (simdilik test)")
    return True

def calis():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((HOST, PORT)); srv.listen(1)
        print(f"Robot bekleniyor, port {PORT} ...")
        while True:
            con, adr = srv.accept()
            print("Robot baglandi:", adr)
            tampon = ""
            with con:
                while True:
                    veri = con.recv(1024)
                    if not veri:
                        print("Robot baglantiyi kapatti."); break
                    tampon += veri.decode("ascii", "ignore")
                    # Mesajlar ';' ile biter: "TRIG;3;" veya "END;"
                    while True:
                        if tampon.startswith("END;"):
                            print("Tarama bitti."); tampon = tampon[4:]; continue
                        if tampon.startswith("TRIG;") and tampon.count(";") >= 2:
                            _, n, tampon = tampon.split(";", 2)
                            print("Tetik:", n)
                            durum = "OK" if foto_cek(n) else "ERR"
                            con.sendall(f"ACK;{n};{durum};".encode("ascii"))
                            continue
                        break

if __name__ == "__main__":
    calis()
