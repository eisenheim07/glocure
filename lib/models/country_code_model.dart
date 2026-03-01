/// Country Code Model for phone number input
class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int maxLength;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.maxLength,
  });
}

/// List of supported countries
const List<CountryCode> countryCodes = [
  CountryCode(
    name: 'India',
    code: 'IN',
    dialCode: '+91',
    flag: '🇮🇳',
    maxLength: 10,
  ),
  CountryCode(
    name: 'United States',
    code: 'US',
    dialCode: '+1',
    flag: '🇺🇸',
    maxLength: 10,
  ),
  CountryCode(
    name: 'United Kingdom',
    code: 'GB',
    dialCode: '+44',
    flag: '🇬🇧',
    maxLength: 10,
  ),
  CountryCode(
    name: 'Canada',
    code: 'CA',
    dialCode: '+1',
    flag: '🇨🇦',
    maxLength: 10,
  ),
  CountryCode(
    name: 'Australia',
    code: 'AU',
    dialCode: '+61',
    flag: '🇦🇺',
    maxLength: 9,
  ),
  CountryCode(
    name: 'Germany',
    code: 'DE',
    dialCode: '+49',
    flag: '🇩🇪',
    maxLength: 11,
  ),
  CountryCode(
    name: 'France',
    code: 'FR',
    dialCode: '+33',
    flag: '🇫🇷',
    maxLength: 9,
  ),
  CountryCode(
    name: 'Japan',
    code: 'JP',
    dialCode: '+81',
    flag: '🇯🇵',
    maxLength: 10,
  ),
  CountryCode(
    name: 'China',
    code: 'CN',
    dialCode: '+86',
    flag: '🇨🇳',
    maxLength: 11,
  ),
  CountryCode(
    name: 'Brazil',
    code: 'BR',
    dialCode: '+55',
    flag: '🇧🇷',
    maxLength: 11,
  ),
  CountryCode(
    name: 'Russia',
    code: 'RU',
    dialCode: '+7',
    flag: '🇷🇺',
    maxLength: 10,
  ),
  CountryCode(
    name: 'South Korea',
    code: 'KR',
    dialCode: '+82',
    flag: '🇰🇷',
    maxLength: 10,
  ),
  CountryCode(
    name: 'Italy',
    code: 'IT',
    dialCode: '+39',
    flag: '🇮🇹',
    maxLength: 10,
  ),
  CountryCode(
    name: 'Spain',
    code: 'ES',
    dialCode: '+34',
    flag: '🇪🇸',
    maxLength: 9,
  ),
  CountryCode(
    name: 'Netherlands',
    code: 'NL',
    dialCode: '+31',
    flag: '🇳🇱',
    maxLength: 9,
  ),
  CountryCode(
    name: 'Sweden',
    code: 'SE',
    dialCode: '+46',
    flag: '🇸🇪',
    maxLength: 9,
  ),
  CountryCode(
    name: 'Norway',
    code: 'NO',
    dialCode: '+47',
    flag: '🇳🇴',
    maxLength: 8,
  ),
  CountryCode(
    name: 'Denmark',
    code: 'DK',
    dialCode: '+45',
    flag: '🇩🇰',
    maxLength: 8,
  ),
  CountryCode(
    name: 'Finland',
    code: 'FI',
    dialCode: '+358',
    flag: '🇫🇮',
    maxLength: 9,
  ),
  CountryCode(
    name: 'Switzerland',
    code: 'CH',
    dialCode: '+41',
    flag: '🇨🇭',
    maxLength: 9,
  ),
];
