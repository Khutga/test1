import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

// İleriki adımlarda oluşturacağımız ekranları buraya dahil ediyoruz
import 'agency_application_screen.dart';
import 'agency_owner_dashboard.dart';
import 'agency_member_dashboard.dart';

class AgencyMainScreen extends StatefulWidget {
  const AgencyMainScreen({super.key});

  @override
  State<AgencyMainScreen> createState() => _AgencyMainScreenState();
}

class _AgencyMainScreenState extends State<AgencyMainScreen> {
  bool _isLoading = true;
  bool _hasAgency = false;
  bool _isOwner = false;
  bool _isPending = false;
  int _userId = 1;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  // Kullanıcının ajans durumunu, yetkisini ve başvuru durumunu kontrol ediyoruz
  Future<void> _checkUserStatus() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('kullanici_id') ?? 1;

    _hasAgency = false;
    _isOwner = false;
    _isPending = false;

    // 1. Önce kullanıcının kendi kurduğu bir ajans (veya başvurusu) var mı bakalım
    final ownerRes = await SqlServis.cek(
      tablo: 'ajanslar',
      sartlar: {'ajans_sahibi_id': _userId},
    );

    if (ownerRes.basarili && ownerRes.veri.isNotEmpty) {
      String durum =
          ownerRes.veri.first['onay_durumu']?.toString() ?? 'Bekliyor';

      if (durum == 'Onaylandi') {
        _hasAgency = true;
        _isOwner = true;
      } else if (durum == 'Bekliyor') {
        _isPending = true;
      }
    }
    // 2. Sahip değilse, başka bir ajansa üye mi (veya üyelik başvurusu beklemede mi) diye bakalım
    else {
      final memberRes = await SqlServis.cek(
        tablo: 'ajans_uyeleri',
        sartlar: {'kullanici_id': _userId},
      );

      if (memberRes.basarili && memberRes.veri.isNotEmpty) {
        String uyeDurumu =
            memberRes.veri.first['onay_durumu']?.toString() ?? 'Bekliyor';

        if (uyeDurumu == 'Onaylandi') {
          _hasAgency = true;
          _isOwner = false;
        } else if (uyeDurumu == 'Bekliyor') {
          // Üyelik isteği attı ama ajans lideri henüz onaylamadıysa da bekliyor ekranı gösterilebilir
          // veya başvuru ekranında uyarı verdirilebilir. Şimdilik pending ekranına atıyoruz.
          _isPending = true;
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Veriler yüklenirken...
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    // Durum 1: Kullanıcının onay bekleyen bir başvurusu varsa
    if (_isPending) {
      return _buildPendingScreen();
    }

    // Durum 2: Kullanıcı Ajans Sahibiyse
    if (_hasAgency && _isOwner) {
      return AgencyOwnerDashboard(
        userId: _userId,
        onStatusChanged:
            _checkUserStatus, // Çıkış yaparsa sayfayı yenilemek için
      );
    }

    // Durum 3: Kullanıcı bir Ajansta Üyeyse
    if (_hasAgency && !_isOwner) {
      return AgencyMemberDashboard(
        userId: _userId,
        onStatusChanged: _checkUserStatus, // Ayrılırsa sayfayı yenilemek için
      );
    }

    // Durum 4: Hiçbir şeyi yoksa, Başvuru ve Katılım formunu göster
    return AgencyApplicationScreen(
      userId: _userId,
      onApplicationSubmitted:
          _checkUserStatus, // Başvuruyu tamamlarsa ekranı yenilemek için
    );
  }

  // Başvuru Bekleme Ekranı Tasarımı
  Widget _buildPendingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajans Başvurusu")),
      body: MainBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 60,
                      color: AppTheme.accentGold,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Başvurunuz İnceleniyor",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Ajans açma talebiniz sistem yöneticilerimiz tarafından incelenmektedir. Durum sonuçlandığında buradan bildirim alacaksınız.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _checkUserStatus, // Yenile butonu
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text("Durumu Yenile"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.textPrimary,
                          side: BorderSide(color: context.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
