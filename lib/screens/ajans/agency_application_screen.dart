import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class AgencyApplicationScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onApplicationSubmitted;

  const AgencyApplicationScreen({
    super.key,
    required this.userId,
    required this.onApplicationSubmitted,
  });

  @override
  State<AgencyApplicationScreen> createState() =>
      _AgencyApplicationScreenState();
}

class _AgencyApplicationScreenState extends State<AgencyApplicationScreen> {
  bool _showJoinForm = false; // false = Ajans Kur, true = Ajansa Katıl
  bool _isLoading = false;

  // --- Ajans Kurma Formu Controller'ları ---
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstWeekController = TextEditingController();
  final TextEditingController _activeBroadcastersController =
      TextEditingController();

  // --- Ajansa Katılma Formu Controller'ı ---
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _agencyNameController.dispose();
    _phoneController.dispose();
    _firstWeekController.dispose();
    _activeBroadcastersController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  // =========================================================================
  // AJANS BAŞVURUSU GÖNDERME İŞLEMİ (GÜNCELLENDİ)
  // =========================================================================
  Future<void> _submitAgencyApplication() async {
    final name = _agencyNameController.text.trim();
    final phone = _phoneController.text.trim();
    final firstWeek = _firstWeekController.text.trim();
    final active = _activeBroadcastersController.text.trim();

    if (name.isEmpty || phone.isEmpty || firstWeek.isEmpty || active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen tüm alanları eksiksiz doldurun!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Eşsiz bir davet kodu oluşturuyoruz (Kayıt anında gerekli olduğu için)
    final yeniDavetKodu =
        "AJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    // Başvuruyu doğrudan "ajanslar" tablosuna "Bekliyor" olarak ekle
    final res = await SqlServis.ekle(
      tablo: 'ajanslar',
      veriler: {
        'ajans_ismi': name,
        'ajans_sahibi_id': widget.userId,
        'telefon': phone,
        'ilk_hafta_yayinci': int.tryParse(firstWeek) ?? 0,
        'tahmini_aktif_yayinci': int.tryParse(active) ?? 0,
        'davet_kodu': yeniDavetKodu,
        'onay_durumu': 'Bekliyor',
      },
    );

    setState(() => _isLoading = false);

    if (res.basarili) {
      widget.onApplicationSubmitted();
    } else {
      String hataMesaji = "Bilinmeyen bir hata";
      try {
        hataMesaji = res.mesaj ?? hataMesaji;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $hataMesaji"),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  // =========================================================================
  // AJANSA KATILMA İŞLEMİ (ONAYA DÜŞER)
  // =========================================================================
  Future<void> _joinAgency() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen davet kodunu girin!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Davet koduna sahip ajansı bul
    final res = await SqlServis.cek(
      tablo: 'ajanslar',
      sartlar: {'davet_kodu': code},
    );
    if (res.basarili && res.veri.isNotEmpty) {
      int ajansId = int.tryParse(res.veri.first['id'].toString()) ?? 0;

      // 2. Kullanıcının zaten bir başvurusu var mı kontrol et
      final checkRes = await SqlServis.cek(
        tablo: 'ajans_uyeleri',
        sartlar: {'kullanici_id': widget.userId},
      );
      if (checkRes.basarili && checkRes.veri.isNotEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Zaten bir ajansa kayıtlısınız veya onay bekleyen bir başvurunuz var!",
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }

      // 3. Üyeyi ajansa 'Bekliyor' statüsünde ekle
      await SqlServis.ekle(
        tablo: 'ajans_uyeleri',
        veriler: {
          'ajans_id': ajansId,
          'kullanici_id': widget.userId,
          'onay_durumu': 'Bekliyor',
        },
      );

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Başvurunuz ajans sahibine iletildi. Onaylandığında ajansa katılacaksınız!",
          ),
          backgroundColor: AppTheme.success,
        ),
      );

      // Başvurudan sonra kod alanını temizle
      _inviteCodeController.clear();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Geçersiz davet kodu!"),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajans İşlemleri")),
      body: MainBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Üst Sekme Geçiş Butonları (Toggle)
              Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showJoinForm = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showJoinForm
                                ? AppTheme.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Ajans Kur",
                            style: TextStyle(
                              color: !_showJoinForm
                                  ? Colors.white
                                  : context.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showJoinForm = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showJoinForm
                                ? AppTheme.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Ajansa Katıl",
                            style: TextStyle(
                              color: _showJoinForm
                                  ? Colors.white
                                  : context.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Seçili Olan Formu Göster
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: !_showJoinForm
                            ? _buildCreateForm()
                            : _buildJoinForm(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Ajans Kurma Formu ---
  Widget _buildCreateForm() {
    return Column(
      children: [
        CustomTextField(
          label: "Ajans Adı",
          controller: _agencyNameController,
          icon: LucideIcons.briefcase,
          hint: 'Ajans adını girin',
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: "İletişim Numarası",
          controller: _phoneController,
          icon: LucideIcons.phone,
          hint: '+90 5XX XXX XX XX',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: "İlk Hafta Getirilecek Yayıncı Sayısı",
          controller: _firstWeekController,
          icon: LucideIcons.users,
          hint: 'Örn: 5',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: "Tahmini Aktif Yayıncı Sayısı",
          controller: _activeBroadcastersController,
          icon: LucideIcons.activity,
          hint: 'Örn: 20',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        PremiumButton(
          text: "Başvuruyu Gönder",
          icon: LucideIcons.send,
          onPressed: _submitAgencyApplication,
        ),
        const SizedBox(height: 20),
        Text(
          "Başvurunuz yönetici onayından geçtikten sonra ajansınız aktif edilecektir.",
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  // --- Ajansa Katılma Formu ---
  Widget _buildJoinForm() {
    return Column(
      children: [
        Icon(
          LucideIcons.users,
          size: 60,
          color: AppTheme.accent.withOpacity(0.8),
        ),
        const SizedBox(height: 16),
        Text(
          "Davet Kodun Var Mı?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Ajans sahibinden aldığın davet kodunu girerek başvuru yapabilirsin. Ajans sahibi onayladığında hesaba dahil olacaksın.",
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 30),
        CustomTextField(
          label: "Örn: AJ-12345",
          controller: _inviteCodeController,
          icon: LucideIcons.key,
          hint: 'Davet Kodu',
        ),
        const SizedBox(height: 28),
        PremiumButton(
          text: "Katılım İsteği Gönder",
          icon: LucideIcons.logIn,
          onPressed: _joinAgency,
        ),
      ],
    );
  }
}
