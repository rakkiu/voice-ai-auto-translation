enum Language {
  vi('vi-VN', 'Tiếng Việt', 'vi'),
  en('en-US', 'English', 'en');

  const Language(this.locale, this.displayName, this.whisperCode);

  final String locale;
  final String displayName;
  final String whisperCode;

  Language get opposite => this == Language.vi ? Language.en : Language.vi;
}
