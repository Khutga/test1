class HesapModel {
  final int id;
  final String kullaniciAdi;
  final String isim;
  final String soyIsim;
  final String eposta;
  final String? telefon;
  final String sifreHash;
  final String dogumTarihi;
  final String? biyografi;
  final String? burc;
  final String cinsiyet;
  final int xpPuani;
  final double birinciCoinBakiye;
  final double ikinciCoinBakiye;
  final bool yasakliMi;
  final bool onayliHesap;
  final DateTime olusturulmaTarihi;
  final DateTime sonGuncelleme;
  final int? boy;
  final double? kilo;
  final bool ajansVarMi;

  HesapModel({
    required this.id,
    required this.kullaniciAdi,
    required this.isim,
    required this.soyIsim,
    required this.eposta,
    this.telefon,
    required this.sifreHash,
    required this.dogumTarihi,
    this.biyografi,
    this.burc,
    required this.cinsiyet,
    required this.xpPuani,
    required this.birinciCoinBakiye,
    required this.ikinciCoinBakiye,
    required this.yasakliMi,
    required this.onayliHesap,
    required this.olusturulmaTarihi,
    required this.sonGuncelleme,
    this.boy,
    this.kilo,
    required this.ajansVarMi,
  });

  factory HesapModel.fromJson(Map<String, dynamic> json) {
    // API'den gelen verileri güvenli bir şekilde dönüştürmek için yardımcı fonksiyonlar
    int parseInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
    double parseDouble(dynamic value) => double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
    bool parseBool(dynamic value) => value == 1 || value == '1' || value == true;

    return HesapModel(
      id: parseInt(json['id']),
      kullaniciAdi: json['kullanici_adi'] ?? '',
      isim: json['isim'] ?? '',
      soyIsim: json['soy_isim'] ?? '',
      eposta: json['eposta'] ?? '',
      telefon: json['telefon'],
      sifreHash: json['sifre_hash'] ?? '',
      dogumTarihi: json['dogum_tarihi'] ?? '',
      biyografi: json['biyografi'],
      burc: json['burc'],
      cinsiyet: json['cinsiyet'] ?? 'Belirtmek İstemiyor',
      xpPuani: parseInt(json['xp_puani']),
      birinciCoinBakiye: parseDouble(json['birinci_coin_bakiye']),
      ikinciCoinBakiye: parseDouble(json['ikinci_coin_bakiye']),
      yasakliMi: parseBool(json['yasakli_mi']),
      onayliHesap: parseBool(json['onayli_hesap']),
      olusturulmaTarihi: DateTime.tryParse(json['olusturulma_tarihi']?.toString() ?? '') ?? DateTime.now(),
      sonGuncelleme: DateTime.tryParse(json['son_guncelleme']?.toString() ?? '') ?? DateTime.now(),
      boy: json['boy'] != null ? parseInt(json['boy']) : null,
      kilo: json['kilo'] != null ? parseDouble(json['kilo']) : null,
      ajansVarMi: parseBool(json['ajansvarmi']),
    );
  }
}