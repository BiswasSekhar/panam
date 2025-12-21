import 'package:flutter_test/flutter_test.dart';

import 'package:panam/features/import/sbi_statement_parser.dart';
import 'package:panam/data/models/transaction.dart';

void main() {
  test('SBIStatementParser parses rows across line breaks and repeated headers', () {
    const text = '''
Account Name : Mr. BISWAS SHEKHAR

Txn Date Value Date Description Ref No./Cheque No. Debit Credit Balance
11 Dec
2025 11 Dec 2025 TO TRANSFER- UPI/DR/533530369303/BISWAS /KKBK/7907999106/Self- 3,750.00 11,862.64

Txn Date Value Date Description Ref No./Cheque No. Debit Credit Balance
11 Dec 2025 11 Dec 2025 BY TRANSFER- UPI/CR/534926810404/BISWAS /KKBK/7907999106/Self- 30,000.00 42,862.64

12 Dec 2025 12 Dec 2025 BY TRANSFER- IMPS/CR/1234567890/Somebody 0.00 1,000.00 43,862.64
''';

    final parsed = SBIStatementParser.parse(text);
    expect(parsed.bankName, anyOf(isNull, equals('SBI')));

    expect(parsed.transactions.length, 3);

    final t0 = parsed.transactions[0];
    expect(t0.date.year, 2025);
    expect(t0.date.month, 12);
    expect(t0.date.day, 11);
    expect(t0.amount, 3750.00);
    expect(t0.type, TransactionType.expense);
    expect(t0.isSelfTransfer, true);

    final t1 = parsed.transactions[1];
    expect(t1.amount, 30000.00);
    expect(t1.type, TransactionType.income);
    expect(t1.isSelfTransfer, true);

    final t2 = parsed.transactions[2];
    expect(t2.amount, 1000.00);
    expect(t2.type, TransactionType.income);
  });
}
