class MockData {
  static const List<Map<String, dynamic>> liveStreams = [
    {"id": 1, "name": "Aylin_99", "viewers": "2.4K", "tags": ["Trend", "Sohbet"], "isAgency": false},
    {"id": 2, "name": "DarkKnight", "viewers": "1.1K", "tags": ["Oyun", "VIP"], "isAgency": true},
    {"id": 3, "name": "Ceren.K", "viewers": "856", "tags": ["Müzik"], "isAgency": false},
    {"id": 4, "name": "Caner_X", "viewers": "500", "tags": ["Yeni"], "isAgency": false},
  ];

  static const List<Map<String, dynamic>> messagesList = [
    {"id": 1, "name": "Melis", "msg": "Yayınına bayıldım! 😍", "time": "2m", "unread": 2, "soulMatch": 89, "coupleLevel": 3},
    {"id": 2, "name": "Burak (Ajans)", "msg": "Turnuva saat 20:00'de başlıyor.", "time": "1s", "unread": 0, "soulMatch": null, "coupleLevel": null},
    {"id": 3, "name": "Selin_G", "msg": "Teşekkür ederim hediyeler için 🎁", "time": "5s", "unread": 0, "soulMatch": 65, "coupleLevel": 1},
  ];
  static const List<Map<String, dynamic>> agencyMembers = [
    {"id": 1, "name": "Aylin_99", "idCode": "LV-883P111", "status": "Aktif", "joinDate": "12.04.2026"},
    {"id": 2, "name": "Ceren.K", "idCode": "LV-442O992", "status": "Aktif", "joinDate": "18.04.2026"},
    {"id": 3, "name": "Mert_V", "idCode": "LV-102K331", "status": "Deaktif", "joinDate": "01.05.2026"},
  ];

  static const List<Map<String, dynamic>> coinPackages = [
    {"id": 1, "amount": 5000, "price": "\$1.99", "popular": false, "bonus": 0},
    {"id": 3, "amount": 25000, "price": "\$9.99", "popular": true, "bonus": 1500},
    {"id": 4, "amount": 50000, "price": "\$19.99", "popular": false, "bonus": 4000},
    {"id": 6, "amount": 150000, "price": "\$59.99", "popular": true, "bonus": 20000},
  ];

  static const List<Map<String, dynamic>> receivedGifts = [
    {"id": 1, "name": "Melis", "gift": "Qədim Əjdaha 🐲", "cost": "25,000 Coin", "date": "Bugün 12:44"},
    {"id": 2, "name": "Burak_VIP", "gift": "Premium Yacht 🛳️", "cost": "8,500 Coin", "date": "Dün 22:15"},
    {"id": 3, "name": "Selin_G", "gift": "Gül Buketi 🌹", "cost": "100 Coin", "date": "18.05.2026"}
  ];

  static const List<Map<String, dynamic>> sentGifts = [
    {"id": 101, "name": "Aylin_99", "gift": "Premium Yacht 🛳️", "cost": "8,500 Coin", "date": "Dün 20:30"},
    {"id": 102, "name": "Ceren.K", "gift": "Ürək ❤️", "cost": "10 Coin", "date": "15.05.2026"}
  ];

  static const List<Map<String, dynamic>> relationshipRoadmap = [
    {"lv": 1, "label": "Sadə mesajlaşma", "unlocked": true},
    {"lv": 2, "label": "Şəkil göndərmək", "unlocked": true},
    {"lv": 3, "label": "Səsli mesajlar", "unlocked": true},
    {"lv": 4, "label": "Səsli zəng icazəsi", "unlocked": true},
    {"lv": 5, "label": "Video zəng limiti ləğvi", "unlocked": false},
    {"lv": 6, "label": "Xüsusi Çütlük Badge-i & Çərçivəsi", "unlocked": false}
  ];
  static const List<Map<String, dynamic>> announcements = [
    {"id": 1, "sender": "SİSTEM", "type": "system", "text": "FiFi Live 2.0 Versiyasına Xoş Gəldiniz! 🚀", "time": "10:00"},
    {"id": 2, "sender": "Star_Ajans", "type": "pk", "text": "🔥 Böyük PK Turniri bu axşam saat 21:00-da başlayır! Hər kəs dəvətlidir!", "time": "11:30", "cost": 15000}
  ];

  static const List<Map<String, dynamic>> joinRequests = [
    {"id": 101, "name": "Gamze_Resmi", "idCode": "LV-392D881", "level": 18, "expectedHours": 30, "requestDate": "Bugün"},
    {"id": 102, "name": "ErenLive", "idCode": "LV-111A554", "level": 25, "expectedHours": 45, "requestDate": "Dün"},
  ];

  static const List<Map<String, dynamic>> assistants = [
    {"id": 1, "name": "Hakan_Asistan", "idCode": "AG-938X221", "role": "Finans Sorumlusu", "joinDate": "10.01.2026"},
    {"id": 2, "name": "Dilara_Mod", "idCode": "AG-112B342", "role": "Yayın Moderatörü", "joinDate": "15.02.2026"}
  ];
}