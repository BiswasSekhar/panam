// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      description: fields[2] as String,
      date: fields[3] as DateTime,
      categoryId: fields[4] as String,
      accountId: fields[5] as String,
      type: fields[6] as TransactionType,
      note: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      externalRef: fields[9] as String?,
      dedupKey: fields[10] as String?,
      source: fields[11] as TransactionSource,
      isSelfTransfer: fields[12] as bool?,
      importSequence: fields[13] as int?,
      isActualIncome: fields[14] as bool?,
      isActualExpense: fields[15] as bool?,
      isLoan: fields[16] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.accountId)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.externalRef)
      ..writeByte(10)
      ..write(obj.dedupKey)
      ..writeByte(11)
      ..write(obj.source)
      ..writeByte(12)
      ..write(obj.isSelfTransfer)
      ..writeByte(13)
      ..write(obj.importSequence)
      ..writeByte(14)
      ..write(obj.isActualIncome)
      ..writeByte(15)
      ..write(obj.isActualExpense)
      ..writeByte(16)
      ..write(obj.isLoan);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 0;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionSourceAdapter extends TypeAdapter<TransactionSource> {
  @override
  final int typeId = 5;

  @override
  TransactionSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionSource.manual;
      case 1:
        return TransactionSource.importPdfText;
      case 2:
        return TransactionSource.importOcrImage;
      default:
        return TransactionSource.manual;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionSource obj) {
    switch (obj) {
      case TransactionSource.manual:
        writer.writeByte(0);
        break;
      case TransactionSource.importPdfText:
        writer.writeByte(1);
        break;
      case TransactionSource.importOcrImage:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
