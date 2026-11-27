class SettingModel {
  final String name;
  final String userId;
  final String email;
  final bool isDarkMode;
  final String language;
  final bool biometricEnabled;
  final bool pinEnabled;
  final bool accountProtection;

  const SettingModel({
    this.name = 'Memuat...',
    this.userId = '',
    this.email = '',
    this.isDarkMode = false,
    this.language = 'Bahasa Indonesia',
    this.biometricEnabled = false,
    this.pinEnabled = true,
    this.accountProtection = true,
  });

  SettingModel copyWith({
    String? name,
    String? userId,
    String? email,
    bool? isDarkMode,
    String? language,
    bool? biometricEnabled,
    bool? pinEnabled,
    bool? accountProtection,
  }) {
    return SettingModel(
      name: name ?? this.name,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      accountProtection: accountProtection ?? this.accountProtection,
    );
  }
}
