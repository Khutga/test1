import 'package:flutter/material.dart';
import 'dart:convert';
// sql_servis.dart dosyanın yolunu kendi projene göre ayarla
import '../services/sql_servis.dart';

class TamKapsamliTest extends StatefulWidget {
  const TamKapsamliTest({Key? key}) : super(key: key);

  @override
  State<TamKapsamliTest> createState() => _TamKapsamliTestState();
}

class _TamKapsamliTestState extends State<TamKapsamliTest> {
  // Dinamik Giriş Alanları
  final _tabloController = TextEditingController(text: Tablolar.hesaplar);
  final _veriKolon = TextEditingController(text: "bakiye");
  final _veriDeger = TextEditingController(text: "5000");
  final _sartKolon = TextEditingController(text: "id");
  final _sartDeger = TextEditingController(text: "1");

  bool _yukleniyor = false;
  String _konsolCiktisi = "İşlem sonucu burada görünecek...";

  // Konsol Çıktısı Formatlayıcı
  void _konsolaYaz(String islemAdi, ApiResponse res) {
    setState(() {
      _yukleniyor = false;
      _konsolCiktisi =
          "=== $islemAdi ===\n"
          "Durum: ${res.basarili ? 'BAŞARILI ✔️' : 'HATA ❌'}\n"
          "Mesaj: ${res.mesaj}\n"
          "Eklenen ID: ${res.eklenenId ?? 'Yok'}\n"
          "Dönen Veri:\n${const JsonEncoder.withIndent('  ').convert(res.veri)}";
    });
  }

  // Ekleme İşlemi
  Future<void> _islemEkle() async {
    setState(() => _yukleniyor = true);
    ApiResponse res = await SqlServis.ekle(
      tablo: _tabloController.text.trim(),
      veriler: {
        "ad": "Test Kullanıcı", // Test için sabit veri
        "eposta": "test@test.com",
        "sifre": "1234",
        _veriKolon.text.trim(): _veriDeger.text.trim(), // Dinamik girilen veri
      },
      geriDondur: "*",
    );
    _konsolaYaz("YENİ VERİ EKLE", res);
  }

  // Güncelleme İşlemi
  Future<void> _islemGuncelle() async {
    setState(() => _yukleniyor = true);
    ApiResponse res = await SqlServis.guncelle(
      tablo: _tabloController.text.trim(),
      veriler: {_veriKolon.text.trim(): _veriDeger.text.trim()},
      sartlar: {_sartKolon.text.trim(): _sartDeger.text.trim()},
      geriDondur: "*",
    );
    _konsolaYaz("VERİ GÜNCELLE", res);
  }

  // Silme İşlemi
  Future<void> _islemSil() async {
    setState(() => _yukleniyor = true);
    ApiResponse res = await SqlServis.sil(
      tablo: _tabloController.text.trim(),
      sartlar: {_sartKolon.text.trim(): _sartDeger.text.trim()},
    );
    _konsolaYaz("VERİ SİL", res);
  }

  // Tüm Verileri Çekme
  Future<void> _islemTumunuCek() async {
    setState(() => _yukleniyor = true);
    ApiResponse res = await SqlServis.cek(tablo: _tabloController.text.trim());
    _konsolaYaz("TÜM TABLOYU ÇEK", res);
  }

  // Şartlı Veri Çekme
  Future<void> _islemSartliCek() async {
    setState(() => _yukleniyor = true);
    ApiResponse res = await SqlServis.cek(
      tablo: _tabloController.text.trim(),
      sartlar: {_sartKolon.text.trim(): _sartDeger.text.trim()},
    );
    _konsolaYaz("ŞARTLI (WHERE) ÇEK", res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tam Kapsamlı API Paneli"),
        backgroundColor: Colors.blueGrey[900],
      ),
      // BÜTÜN SAYFAYI KAYDIRILABİLİR YAPAN WIDGET
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BÖLÜM: DİNAMİK GİRİŞ ALANLARI
            const Text(
              "Hangi Tablo?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _tabloController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 15),

            const Text(
              "Veri (Ekleme/Güncelleme İçin SET)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _veriKolon,
                    decoration: const InputDecoration(
                      labelText: "Kolon Adı",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _veriDeger,
                    decoration: const InputDecoration(
                      labelText: "Yeni Değer",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            const Text(
              "Şart (Güncelle/Sil/Çek İçin WHERE)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sartKolon,
                    decoration: const InputDecoration(
                      labelText: "Şart Kolonu",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _sartDeger,
                    decoration: const InputDecoration(
                      labelText: "Aranan Değer",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // 2. BÖLÜM: BÜTÜN İŞLEM BUTONLARI (ESKİ TEST BUTONLARI GİBİ)
            const Text(
              "İşlemi Tetikle",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _islemButonu("EKLE (Insert)", Colors.green, _islemEkle),
                _islemButonu(
                  "GÜNCELLE (Update)",
                  Colors.orange,
                  _islemGuncelle,
                ),
                _islemButonu("SİL (Delete)", Colors.red, _islemSil),
                _islemButonu(
                  "TÜMÜNÜ ÇEK (Select *)",
                  Colors.blue,
                  _islemTumunuCek,
                ),
                _islemButonu(
                  "ŞARTLI ÇEK (Where)",
                  Colors.purple,
                  _islemSartliCek,
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 3. BÖLÜM: KONSOL ÇIKTISI
            const Text(
              "JSON Çıktısı (Response):",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey, width: 1.5),
              ),
              child: _yukleniyor
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.green),
                      ),
                    )
                  : Text(
                      _konsolCiktisi,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Ortak Buton Tasarımı
  Widget _islemButonu(String etiket, Color renk, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: renk,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: _yukleniyor ? null : onPressed,
      child: Text(etiket, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  void dispose() {
    _tabloController.dispose();
    _veriKolon.dispose();
    _veriDeger.dispose();
    _sartKolon.dispose();
    _sartDeger.dispose();
    super.dispose();
  }
}
