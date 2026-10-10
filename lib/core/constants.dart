class Currency {
  final String code;
  final String symbol;
  final String name;
  const Currency(this.code, this.symbol, this.name);
}

const List<Currency> kCurrencies = [
  Currency('SYP', 'ل.س', 'الليرة السورية'),
  Currency('USD', 'USD', 'الدولار الأمريكي'),
  Currency('EUR', 'EUR', 'اليورو'),
  Currency('SAR', 'SAR', 'الريال السعودي'),
  Currency('AED', 'AED', 'الدرهم الإماراتي'),
];

Currency currencyOf(String code) =>
    kCurrencies.firstWhere((c) => c.code == code, orElse: () => kCurrencies.first);

String currencySymbol(String code) => currencyOf(code).symbol;

const String kAppName = 'رامي';
const String kAppVersion = '1.0.0';
const String kDbName = 'rami.db';
const int kDbVersion = 1;
const int kBackupVersion = 1;
const int kMaxAmountMinor = 99999999999999; // 999,999,999,999.99
