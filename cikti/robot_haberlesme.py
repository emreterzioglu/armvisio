# -*- coding: utf-8 -*-
"""
Robot haberlesmesi (TCP)  -  PC SUNUCU, robot ISTEMCI
=====================================================

Robot, PC'ye baglanir (robot_deneme.py ile denenen yapi):
    PC IP : 192.168.212.1      Port: 5000
PC her ag kartini dinler (PC_IP = "0.0.0.0"), robot hangi IP'ye baglanirsa baglansin olur.

---------------------------------------------------------------------------
PROTOKOL  (robot yazilimcisi ile ORTAK - degistirirseniz iki tarafta da degistirin)
---------------------------------------------------------------------------
Kurallar:
  - Konusmayi HER ZAMAN PC baslatir: PC bir komut gonderir, robot TEK satir cevap verir.
    Robot kendiliginden mesaj gondermez (gonderirse PC bir sonraki komuttan once atar).
  - PC her komutun sonuna  \\r\\n  ekler. Robotun da cevabin sonuna \\r\\n eklemesi onerilir
    (eklemezse de PC anlar).
  - Sadece BUYUK harf, Turkce karakter ve bosluk YOK. (PC tarafinda buyuk/kucuk harf fark etmez.)
  - Baglanti koparsa robot tekrar baglanmayi denemeli.

  Sira  PC  -> Robot        Robot -> PC                        Not
  ----  ------------------  ---------------------------------  ---------------------------------
   1    HOME_MISIN          HOME        / HOME_DEGIL           anahtar + buton
   2    HAZIR_MISIN         HAZIRIM     / DEGILIM              DMC okunduktan sonra; DEGILIM
                                                               gelirse 1 sn arayla tekrar sorulur
   3    START1              START1_OK                          touch'tan 2 sn sonra
   4    PROG1_BITTI_MI      PROG1_BITTI / DEVAM                0.5 sn arayla surekli sorulur
   5    KONUM2_GIT          KONUM2_GITTIM                      cevap hareket BITINCE verilir
   6    START2              START2_OK
   7    PROG2_BITTI_MI      PROG2_BITTI / DEVAM                0.5 sn arayla surekli sorulur
   8    HOME_GIT            HOME_GITTIM                        cevap hareket BITINCE verilir

Tabloda olmayan bir cevap gelirse ya da zaman asimi olursa PC "ROBOT HATASI" verir ve
baska komut gondermez.

---------------------------------------------------------------------------
ANLIK KONUM KANALI  (EK - port 5001, sadece robot -> PC)
---------------------------------------------------------------------------
Yukaridaki soru-cevap (port 5000) AYNEN kalir. Robot ikinci bir baglantiyla 5001'e baglanir ve
foto noktasindan GECTIGI ANDA, soru beklemeden su mesajlari gonderir (sonu \r\n):
    PROG1 (START1 sonrasi):  P1_KONUM1, P1_KONUM2, ... P1_KONUM12
    PROG2 (START2 sonrasi):  P2_KONUM12, P2_KONUM11, ... P2_KONUM1
KonumDinleyici her mesajda hemen konum_geldi(program, nokta) cagirir -> fotograf orada cekilir.
Robot, 5000 VE 5001 portlarinin ikisi de aciksa baglanir (robot kodunda bOlayKanali := TRUE).

Tek basina calistirma (robot yazilimcisiyla deneme icin):
    python robot_haberlesme.py
  Robot baglaninca komutu yazip Enter'a basin, cevap ekrana gelir. 'q' ile cikis.
"""

import os
import re
import select
import socket
import threading
import time

# ======================= AYARLAR =======================
PC_IP = "0.0.0.0"            # "0.0.0.0" = tum ag kartlari. Sadece biri: "192.168.212.1"
PORT = 5000
KONUM_PORT = 5001            # anlik konum kanali (robot -> PC)
SATIR_SONU = "\r\n"          # PC'nin gonderdigi komutlarin sonu
SATIR_BEKLE_SN = 0.15        # robot satir sonu gondermezse: bu kadar sessizlik = mesaj bitti

# Zaman asimlari (saniye)
CEVAP_SN = 5.0               # normal komutlarin cevabi
HAZIR_BEKLE_MAX_SN = 30      # HAZIR_MISIN: robot bu sure icinde HAZIRIM demezse hata
PROG_MAX_SN = 300            # PROG1 / PROG2 en fazla bu kadar surebilir
KONUM2_SN = 60               # KONUM2_GIT -> KONUM2_GITTIM
HOME_GIT_SN = 60             # HOME_GIT   -> HOME_GITTIM
SORGU_ARALIK_SN = 0.5        # PROGx_BITTI_MI sorma araligi
# =======================================================

# ---- Protokol (yukaridaki tablo) ----
HOME_MISIN, HOME, HOME_DEGIL = "HOME_MISIN", "HOME", "HOME_DEGIL"
HAZIR_MISIN, HAZIRIM, DEGILIM = "HAZIR_MISIN", "HAZIRIM", "DEGILIM"
START1, START1_OK = "START1", "START1_OK"
PROG1_BITTI_MI, PROG1_BITTI = "PROG1_BITTI_MI", "PROG1_BITTI"
KONUM2_GIT, KONUM2_GITTIM = "KONUM2_GIT", "KONUM2_GITTIM"
START2, START2_OK = "START2", "START2_OK"
PROG2_BITTI_MI, PROG2_BITTI = "PROG2_BITTI_MI", "PROG2_BITTI"
HOME_GIT, HOME_GITTIM = "HOME_GIT", "HOME_GITTIM"
DEVAM = "DEVAM"


class RobotHata(Exception):
    """Robota ulasilamadi / cevap gelmedi."""


class RobotBeklenmeyen(RobotHata):
    """Robot tabloda olmayan (ya da beklenmeyen) bir cevap verdi."""

    def __init__(self, komut, cevap, beklenen):
        self.komut, self.cevap, self.beklenen = komut, cevap, beklenen
        super().__init__(f"{komut} komutuna '{cevap}' cevabı geldi (beklenen: {beklenen})")


class RobotIptal(RobotHata):
    """Bekleme programdan iptal edildi (parca alindi, program kapandi vb.)."""


def _log(yon, metin):
    ms = int((time.time() % 1) * 1000)
    print(f"{time.strftime('%H:%M:%S')}.{ms:03d} [ROBOT] {yon} {metin}")


def _temizle(veri):
    metin = veri.decode("utf-8", errors="replace")
    return re.sub(r"[\x00-\x1f\x7f]", "", metin).strip().upper()


class RobotSunucu:
    def __init__(self, ip=PC_IP, port=PORT, durum_bildir=None):
        """durum_bildir(bagli: bool, bilgi: str): robot baglandi / koptu bildirimi."""
        self.ip, self.port = ip, port
        self._bildir = durum_bildir or (lambda bagli, bilgi: None)
        self._kilit = threading.RLock()        # ayni anda tek komut
        self._conn_kilit = threading.Lock()    # baglanti degisimi
        self._conn = None
        self._sunucu = None
        self._calisiyor = False

    # ---------------- sunucu ----------------
    def baslat(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        if os.name == "nt":
            # Windows: ikinci bir program ayni portu ACAMASIN (robot_deneme.py acikken hata versin)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        else:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind((self.ip, self.port))
        except OSError as e:
            s.close()
            raise RobotHata(f"Robot portu açılamadı ({self.ip}:{self.port}): {e}. "
                            f"robot_deneme.py açıksa kapatın.") from e
        s.listen(1)
        s.settimeout(1.0)
        self._sunucu = s
        self._calisiyor = True
        threading.Thread(target=self._kabul_dongusu, daemon=True).start()
        _log("--", f"robot bekleniyor ({self.ip}:{self.port})")

    def bagli_mi(self):
        return self._conn is not None

    def _kabul_dongusu(self):
        while self._calisiyor:
            try:
                yeni, adres = self._sunucu.accept()
            except socket.timeout:
                self._baglanti_kontrol()
                continue
            except OSError:
                if not self._calisiyor:
                    break
                time.sleep(0.5)
                continue
            yeni.settimeout(None)
            yeni.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            yeni.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
            with self._conn_kilit:
                eski, self._conn = self._conn, yeni
            if eski is not None:                 # robot yeniden baglandi: eskisini kapat
                try:
                    eski.close()
                except OSError:
                    pass
            bilgi = f"{adres[0]}:{adres[1]}"
            _log("--", f"robot bağlandı {bilgi}")
            self._bildir(True, bilgi)

    def _baglanti_kontrol(self):
        """Bosta iken robotun baglantiyi kapatip kapatmadigina bakar (veri tuketmeden)."""
        c = self._conn
        if c is None or not self._kilit.acquire(blocking=False):
            return                               # komut suruyorsa ona karisma
        try:
            okunabilir, _, _ = select.select([c], [], [], 0)
            if okunabilir and not c.recv(1, socket.MSG_PEEK):
                self._baglanti_koptu("robot bağlantıyı kapattı")
        except OSError as e:
            self._baglanti_koptu(str(e))
        finally:
            self._kilit.release()

    def _baglanti_koptu(self, neden):
        with self._conn_kilit:
            c, self._conn = self._conn, None
        if c is None:
            return
        try:
            c.close()
        except OSError:
            pass
        _log("--", f"bağlantı koptu: {neden}")
        self._bildir(False, neden)

    # ---------------- komut ----------------
    def sor(self, komut, zaman_asimi=CEVAP_SN, sessiz=False):
        """Komutu gonderir, robotun tek satirlik cevabini (BUYUK harf) dondurur."""
        with self._kilit:
            c = self._conn
            if c is None:
                raise RobotHata("Robot bağlı değil")
            try:
                self._eski_veriyi_at(c)
                if not sessiz:
                    _log("->", komut)
                c.sendall((komut + SATIR_SONU).encode("ascii"))
                cevap = self._mesaj_oku(c, komut, zaman_asimi)
            except OSError as e:
                self._baglanti_koptu(str(e))
                raise RobotHata(f"Robot bağlantısı koptu ({komut}): {e}") from e
            if not sessiz:
                _log("<-", cevap)
            return cevap

    def bekle(self, komut, beklenen, zaman_asimi=CEVAP_SN):
        """Komutu gonderir; cevap 'beklenen' degilse RobotBeklenmeyen firlatir."""
        cevap = self.sor(komut, zaman_asimi)
        if cevap != beklenen:
            raise RobotBeklenmeyen(komut, cevap, beklenen)
        return cevap

    def sorgula(self, komut, beklenen, ara_cevaplar, toplam_sn,
                aralik=SORGU_ARALIK_SN, iptal=None):
        """'beklenen' gelene kadar komutu aralikla tekrar sorar.
        ara_cevaplar: beklerken gelebilecek cevaplar (or. DEVAM). Baska cevap -> hata."""
        bitis = time.monotonic() + toplam_sn
        son_cevap, sayac = None, 0
        while True:
            if iptal and iptal():
                raise RobotIptal(f"{komut} iptal edildi")
            sayac += 1
            cevap = self.sor(komut, sessiz=True)
            if cevap != son_cevap:              # terminal dolmasin: sadece degisince yaz
                _log("->", komut)
                _log("<-", cevap if sayac == 1 else f"{cevap}  ({sayac}. soru)")
                son_cevap = cevap
            if cevap == beklenen:
                return cevap
            if cevap not in ara_cevaplar:
                raise RobotBeklenmeyen(komut, cevap, beklenen)
            if time.monotonic() >= bitis:
                raise RobotHata(f"{komut}: {toplam_sn:.0f} sn içinde {beklenen} gelmedi")
            dur = time.monotonic() + aralik
            while time.monotonic() < dur:
                if iptal and iptal():
                    raise RobotIptal(f"{komut} iptal edildi")
                time.sleep(0.05)

    # ---------------- yardimcilar ----------------
    @staticmethod
    def _eski_veriyi_at(c):
        """Onceki komuttan kalmis gec cevaplari at (yeni komutun cevabi sanilmasin)."""
        atilan = b""
        c.setblocking(False)
        try:
            while True:
                veri = c.recv(4096)
                if not veri:
                    raise ConnectionError("robot bağlantıyı kapattı")
                atilan += veri
        except (BlockingIOError, InterruptedError):
            pass
        finally:
            c.setblocking(True)
        if atilan.strip():
            _log("!!", f"beklenmeyen eski veri atıldı: {_temizle(atilan)!r}")

    @staticmethod
    def _mesaj_oku(c, komut, zaman_asimi):
        """Ilk dolu satiri dondurur. Satir sonu gelmezse kisa sessizlikten sonra
        gelen veriyi mesaj sayar."""
        bitis = time.monotonic() + zaman_asimi
        tampon = b""
        while True:
            satirlar = re.split(rb"[\r\n]", tampon)
            for satir in satirlar[:-1]:
                if satir.strip():
                    return _temizle(satir)
            tampon = satirlar[-1]               # yarim kalan satir

            kalan = bitis - time.monotonic()
            if kalan <= 0:
                if tampon.strip():
                    return _temizle(tampon)
                raise RobotHata(f"Robot {zaman_asimi:.0f} sn içinde cevap vermedi ({komut})")
            c.settimeout(min(kalan, SATIR_BEKLE_SN) if tampon.strip() else kalan)
            try:
                parca = c.recv(1024)
            except socket.timeout:
                if tampon.strip():
                    return _temizle(tampon)      # satir sonu yok, robot sustu: mesaj bitti
                continue
            finally:
                c.settimeout(None)
            if not parca:
                raise ConnectionError("robot bağlantıyı kapattı")
            tampon += parca

    def kapat(self):
        self._calisiyor = False
        if self._sunucu is not None:
            try:
                self._sunucu.close()
            except OSError:
                pass
            self._sunucu = None
        with self._conn_kilit:
            c, self._conn = self._conn, None
        if c is not None:
            try:
                c.close()
            except OSError:
                pass


_KONUM_DESEN = re.compile(r"^P([12])_KONUM(\d{1,2})$")


class KonumDinleyici:
    """Port 5001: robotun foto noktasindan gecerken gonderdigi P1_KONUMn / P2_KONUMn mesajlari."""

    def __init__(self, ip=PC_IP, port=KONUM_PORT, konum_geldi=None):
        """konum_geldi(program: int, nokta: int): her mesajda HEMEN cagrilir (okuma thread'inden)."""
        self.ip, self.port = ip, port
        self._cb = konum_geldi or (lambda program, nokta: None)
        self._sunucu = None
        self._calisiyor = False

    def baslat(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        if os.name == "nt":
            s.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        else:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind((self.ip, self.port))
        except OSError as e:
            s.close()
            raise RobotHata(f"Konum portu açılamadı ({self.ip}:{self.port}): {e}") from e
        s.listen(1)
        s.settimeout(1.0)
        self._sunucu = s
        self._calisiyor = True
        threading.Thread(target=self._kabul_dongusu, daemon=True).start()
        _log("--", f"konum kanalı bekleniyor ({self.ip}:{self.port})")

    def _kabul_dongusu(self):
        while self._calisiyor:
            try:
                c, adres = self._sunucu.accept()
            except socket.timeout:
                continue
            except OSError:
                break
            c.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            _log("--", f"konum kanalı bağlandı {adres[0]}:{adres[1]}")
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
                    metin = _temizle(satir)
                    if not metin:
                        continue
                    m = _KONUM_DESEN.match(metin)
                    if not m:
                        _log("!!", f"konum kanalında tanınmayan mesaj: {metin!r}")
                        continue
                    _log("<=", metin)
                    try:
                        self._cb(int(m.group(1)), int(m.group(2)))
                    except Exception as e:          # kamera hatasi okumayi durdurmasin
                        _log("!!", f"konum_geldi hatası: {e}")
        except OSError as e:
            _log("--", f"konum kanalı hatası: {e}")
        finally:
            c.close()
            _log("--", "konum kanalı kapandı")

    def kapat(self):
        self._calisiyor = False
        if self._sunucu is not None:
            try:
                self._sunucu.close()
            except OSError:
                pass
            self._sunucu = None


if __name__ == "__main__":
    # Elle deneme: komut yaz -> robotun cevabini gor. Konum mesajlari ayrica ekrana yazilir.
    k = KonumDinleyici(konum_geldi=lambda p, n: print(f"   -> FOTO: program {p}, nokta {n}"))
    k.baslat()
    r = RobotSunucu()
    r.baslat()
    print("Robot bağlanınca komut yazıp Enter'a basın (or. HOME_MISIN).  q: çıkış")
    try:
        while True:
            k = input().strip().upper()
            if k == "Q":
                break
            if not k:
                continue
            try:
                r.sor(k)
            except RobotHata as e:
                print("  HATA:", e)
    finally:
        r.kapat()
        k.kapat()
