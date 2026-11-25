# Kamera PC'si - TCP SUNUCU (robot istemci olarak baglanir).
# Akis: robot baglanir -> PC "HAZIR_MISIN" gonderir -> robot "HAZIRIM" cevaplar ->
#       robot her foto noktasinda "KONUM<n>;" gonderir -> sonda "BITTI;".
# Calistirma: python kamera_pc_sunucu.py   (Python 3, ek paket gerekmez)
import socket

DINLE_IP = "0.0.0.0"   # tum ag kartlari (PC'nin IP'si 192.168.212.1 olmali)
PORT = 5000

def foto_cek(konum):
    # BURAYA kameranin kendi yazilimini/SDK'sini cagiran kod gelecek.
    print(f"  -> KONUM {konum}: foto cekildi (simdilik test)")

def bir_cevrim(con):
    con.sendall(b"HAZIR_MISIN")
    cevap = con.recv(1024).decode("ascii", "ignore").strip()
    print("Robot cevabi:", cevap)
    if not cevap.startswith("HAZIRIM"):
        print("Robot hazir degil."); return
    tampon = ""
    while True:
        veri = con.recv(1024)
        if not veri:
            print("Robot baglantiyi kapatti."); return
        tampon += veri.decode("ascii", "ignore")
        while ";" in tampon:
            mesaj, tampon = tampon.split(";", 1)
            mesaj = mesaj.strip()
            if mesaj.startswith("KONUM"):
                foto_cek(int(mesaj[5:]))
            elif mesaj == "BITTI":
                print("Cevrim bitti."); return

if __name__ == "__main__":
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((DINLE_IP, PORT)); srv.listen(1)
        print(f"Robot bekleniyor, port {PORT} ...")
        while True:
            con, adr = srv.accept()
            print("Robot baglandi:", adr)
            with con:
                bir_cevrim(con)
