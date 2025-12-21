import 'kotak_statement_parser.dart';
import 'sbi_statement_parser.dart';
import 'models.dart';

class StatementParser {
  /// Try to parse the text with all available bank parsers
  /// Returns the parser result with the most transactions found
  static ParsedStatement parse(String text) {
    // Try SBI parser first (as it's more specific with date format)
    final sbiResult = SBIStatementParser.parse(text);
    
    // Try Kotak parser
    final kotakResult = KotakStatementParser.parse(text);
    
    // Return the one with more transactions
    // If both have same count, prefer the one with detected bank name
    if (sbiResult.transactions.length > kotakResult.transactions.length) {
      return sbiResult;
    } else if (kotakResult.transactions.length > sbiResult.transactions.length) {
      return kotakResult;
    } else {
      // Same count, prefer one with bank name detected
      if (sbiResult.bankName != null) return sbiResult;
      if (kotakResult.bankName != null) return kotakResult;
      return kotakResult; // Default to Kotak if no clear winner
    }
  }
}
