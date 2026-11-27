import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAccount {
  final String id;
  final String nama;
  final String alias;
  final String bank;
  final String noRekening;
  final bool favorit;
  final DateTime? createdAt;

  const SavedAccount({
    required this.id,
    required this.nama,
    required this.alias,
    required this.bank,
    required this.noRekening,
    required this.favorit,
    this.createdAt,
  });

  bool get isBca => bank.toUpperCase() == 'BCA';

  String get displayName => alias.trim().isNotEmpty ? alias.trim() : nama;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory SavedAccount.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SavedAccount(
      id: doc.id,
      nama: (d['nama'] ?? '') as String,
      alias: (d['alias'] ?? '') as String,
      bank: (d['bank'] ?? '') as String,
      noRekening: (d['noRekening'] ?? '') as String,
      favorit: (d['favorit'] ?? false) as bool,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nama': nama,
    'alias': alias,
    'bank': bank,
    'noRekening': noRekening,
    'favorit': favorit,
  };
}
