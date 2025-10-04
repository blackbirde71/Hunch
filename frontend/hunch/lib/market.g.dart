// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MarketAdapter extends TypeAdapter<Market> {
  @override
  final int typeId = 0;

  @override
  Market read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Market(
      id: fields[0] as String,
      question: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      action: fields[4] as SwipeAction,
    );
  }

  @override
  void write(BinaryWriter writer, Market obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.action);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SwipeActionAdapter extends TypeAdapter<SwipeAction> {
  @override
  final int typeId = 1;

  @override
  SwipeAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SwipeAction.yes;
      case 1:
        return SwipeAction.no;
      case 2:
        return SwipeAction.blank;
      default:
        return SwipeAction.yes;
    }
  }

  @override
  void write(BinaryWriter writer, SwipeAction obj) {
    switch (obj) {
      case SwipeAction.yes:
        writer.writeByte(0);
        break;
      case SwipeAction.no:
        writer.writeByte(1);
        break;
      case SwipeAction.blank:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
