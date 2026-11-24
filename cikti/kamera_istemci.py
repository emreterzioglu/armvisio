# Kamera PC'si (Windows) - TCP ISTEMCI. Robot (192.168.212.30:5000) sunucu; robot her foto noktasinda
# "KONUM<n>;" gonderir (n = pFoto numarasi), cevrim sonunda "BITTI;".
# Calistirma: python kamera_istemci.py   (Python 3, ek paket gerekmez)
import socket, time

ROBOT_IP = "192.168.212.30"
PORT = 5000

def foto_cek(konum):
    # BURAYA kameranin kendi yazilimini/SDK'sini cagiran kod gelecek.
    print(f"  -> KONUM {konum}: foto cekildi (simdilik test)")

def bir_cevrim():
    with socket.create_connection((ROBOT_IP, PORT), timeout=60) as s:
        s.settimeout(None)
        print("Robota baglandi.")
        tampon = ""
        while True:
            veri = s.recv(1024)
            if not veri:
                print("Robot baglantiyi kapatti."); return
            tampon += veri.decode("ascii", "ignore")
            while ";" in tampon:
                mesaj, tampon = tampon.split(";", 1)
                if mesaj.startswith("KONUM"):
                    foto_cek(int(mesaj[5:]))
                elif mesaj == "BITTI":
                    print("Cevrim bitti."); return

if __name__ == "__main__":
    while True:                      # her cevrimde robot yeniden dinlemeye gecer; tekrar baglan
        try:
            bir_cevrim()
        except OSError as e:
            print("Baglanti yok, 1 s sonra tekrar:", e)
        time.sleep(1)
