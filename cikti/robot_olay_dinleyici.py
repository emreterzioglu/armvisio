# -*- coding: utf-8 -*-
"""
Robot ANLIK KONUM kanali (TCP)  -  PC SUNUCU, robot ISTEMCI
=============================================================

robot_haberlesme.py (port 5000, soru-cevap) DEGISMEDEN kalir. Bu modul AYRI bir port (5001)
dinler. Robot burada soru beklemeden, foto noktasindan GECTIGI ANDA mesaj gonderir:

    PROG1 (START1 sonrasi):  P1_KONUM1, P1_KONUM2, ... P1_KONUM12
    PROG2 (START2 sonrasi):  P2_KONUM12, P2_KONUM11, ... P2_KONUM1
    Her mesajin sonunda \\r\\n vardir.

Mesaj gelir gelmez konum_geldi(program, nokta) cagrilir -> fotografi orada cekin.
PC bu kanala hicbir sey yazmaz.

Kullanim (robot_haberlesme.py ile birlikte):
    from robot_olay_dinleyici import OlayDinleyici
    def foto_cek(program, nokta):        # program: 1 / 2, nokta: 1..12
        kamera.tetikle()                 # ornek
    dinleyici = OlayDinleyici(konum_geldi=foto_cek)
    dinleyici.baslat()

Tek basina deneme:  python robot_olay_dinleyici.py   (gelen mesajlari zamaniyla yazar)
"""

import re
import socket
import threading
import time

PC_IP = "0.0.0.0"
PORT = 5001
_DESEN = re.compile(r"^P([12])_KONUM(\d{1,2})$")


def _log(metin):
    ms = int((time.time() % 1) * 1000)
    print(f"{time.strftime('%H:%M:%S')}.{ms:03d} [KONUM] {metin}")


class OlayDinleyici:
    def __init__(self, ip=PC_IP, port=PORT, konum_geldi=None):
        """konum_geldi(program: int, nokta: int) -> her mesajda hemen cagrilir (okuma thread'inden)."""
        self.ip, self.port = ip, port
        self._cb = konum_geldi or (lambda program, nokta: None)
        self._sunucu = None
        self._calisiyor = False

    def baslat(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((self.ip, self.port))
        s.listen(1)
        s.settimeout(1.0)
        self._sunucu = s
        self._calisiyor = True
        threading.Thread(target=self._kabul_dongusu, daemon=True).start()
        _log(f"robot bekleniyor ({self.ip}:{self.port})")

    def _kabul_dongusu(self):
        while self._calisiyor:
            try:
                c, adres = self._sunucu.accept()
            except socket.timeout:
                continue
            except OSError:
                break
            c.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            _log(f"robot bağlandı {adres[0]}:{adres[1]}")
            # robot yeniden baglanirsa yeni baglanti icin yeni okuyucu; eskisi kendiliginden biter
            threading.Thread(target=self._oku, args=(c,), daemon=True).start()

    def _oku(self, c):
        tampon = b""
        try:
            while self._calisiyor:
                parca = c.recv(1024)
                if not parca:
                    break
                tampon += parca
                *satirlar, tampon = re.split(rb"\r\n|\r|\n", tampon)
                for satir in satirlar:
                    metin = satir.decode("ascii", errors="replace").strip().upper()
                    if not metin:
                        continue
                    m = _DESEN.match(metin)
                    if m:
                        _log(metin)
                        try:
                            self._cb(int(m.group(1)), int(m.group(2)))
                        except Exception as e:      # kamera hatasi okumayi durdurmasin
                            _log(f"konum_geldi hatası: {e}")
                    else:
                        _log(f"tanınmayan mesaj atlandı: {metin!r}")
        except OSError as e:
            _log(f"bağlantı hatası: {e}")
        finally:
            c.close()
            _log("robot bağlantısı kapandı")

    def kapat(self):
        self._calisiyor = False
        if self._sunucu is not None:
            self._sunucu.close()
            self._sunucu = None


if __name__ == "__main__":
    d = OlayDinleyici(konum_geldi=lambda p, n: print(f"   -> FOTO: program {p}, nokta {n}"))
    d.baslat()
    print("Ctrl+C ile çıkış")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        d.kapat()
