/// Format a price amount string (e.g. "1234567.50") to Indian format with ₹ and commas.
/// Indian format: 12,34,567.50 (first group 3 digits from right, then groups of 2).
String formatIndianCurrency(String amountStr) {
  if (amountStr.isEmpty) return '₹0';
  final trimmed = amountStr.trim();
  final isNegative = trimmed.startsWith('-');
  final numPart = isNegative ? trimmed.substring(1) : trimmed;
  final parts = numPart.split('.');
  final intPart = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
  final decPart = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '') : null;

  if (intPart.isEmpty) {
    return '${isNegative ? '-' : ''}₹0${decPart != null && decPart.isNotEmpty ? '.$decPart' : ''}';
  }

  final rev = intPart.split('').reversed.join();
  final chunks = <String>[];
  final firstLen = rev.length >= 3 ? 3 : rev.length;
  chunks.add(rev.substring(0, firstLen).split('').reversed.join());
  var i = firstLen;
  while (i < rev.length) {
    final end = (i + 2) <= rev.length ? i + 2 : rev.length;
    chunks.add(rev.substring(i, end).split('').reversed.join());
    i = end;
  }
  final formatted = chunks.reversed.join(',');
  return '${isNegative ? '-' : ''}₹$formatted${decPart != null && decPart.isNotEmpty ? '.$decPart' : ''}';
}
