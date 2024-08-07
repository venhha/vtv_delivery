import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:vtv_common/core.dart';

class CashOrderEntity extends Equatable {
  final String cashOrderId;
  final String transportId;
  final String orderId;
  final int money;
  final String shipperUsername;
  final bool shipperHold;
  final String? wareHouseUsername;
  final bool wareHouseHold;
  final bool handlePayment;
  final Status status;
  final DateTime createAt;
  final DateTime updateAt;

  const CashOrderEntity({
    required this.cashOrderId,
    required this.transportId,
    required this.orderId,
    required this.money,
    required this.shipperUsername,
    required this.shipperHold,
    required this.wareHouseUsername,
    required this.wareHouseHold,
    required this.handlePayment,
    required this.status,
    required this.createAt,
    required this.updateAt,
  });

  String get statusNameByShipper {
    if (status == Status.INACTIVE && handlePayment) return 'Đã thanh toán online'; // online payment > auto complete
    if (shipperHold && !wareHouseHold && !handlePayment) {
      return 'Shipper đang giữ tiền';
    } else if (!shipperHold && !wareHouseHold && !handlePayment) {
      return 'Đang giao'; //! only shipper can see this status at 3rd tab (has been sent money to warehouse)
    } else if (!shipperHold && wareHouseHold && !handlePayment) {
      return 'Warehouse đang giữ tiền';
    } else if (!shipperHold && !wareHouseHold && handlePayment) {
      return 'Hoàn thành';
    }
    return 'Unknown status: $status, shipperHold: $shipperHold, wareHouseHold: $wareHouseHold, handlePayment: $handlePayment';
    // return 'Unknown status';
  }

  String get statusNameByWarehouse {
    if (status == Status.INACTIVE && handlePayment) return 'Đã thanh toán online'; // online payment > auto complete
    if (shipperHold && !wareHouseHold && !handlePayment) {
      return 'Shipper đang giữ tiền';
    } else if (!shipperHold && !wareHouseHold && !handlePayment) {
      return 'Chờ kho xác nhận'; //! only warehouse can see this status at 1st tab (under warehouse's confirmation)
    } else if (!shipperHold && wareHouseHold && !handlePayment) {
      return 'Warehouse đang giữ tiền';
    } else if (!shipperHold && !wareHouseHold && handlePayment) {
      return 'Hoàn thành';
    }
    // return 'Unknown status: $status, shipperHold: $shipperHold, wareHouseHold: $wareHouseHold, handlePayment: $handlePayment';
    return 'Unknown status';
  }

  @override
  List<Object?> get props {
    return [
      cashOrderId,
      transportId,
      orderId,
      money,
      shipperUsername,
      shipperHold,
      wareHouseUsername,
      wareHouseHold,
      handlePayment,
      status,
      createAt,
      updateAt,
    ];
  }

  @override
  bool get stringify => true;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cashOrderId': cashOrderId,
      'transportId': transportId,
      'orderId': orderId,
      'money': money,
      'shipperUsername': shipperUsername,
      'shipperHold': shipperHold,
      'waveHouseUsername': wareHouseUsername,
      'waveHouseHold': wareHouseHold,
      'handlePayment': handlePayment,
      'status': status.name,
      'createAt': createAt.toIso8601String(),
      'updateAt': updateAt.toIso8601String,
    };
  }

  factory CashOrderEntity.fromMap(Map<String, dynamic> map) {
    return CashOrderEntity(
      cashOrderId: map['cashOrderId'] as String,
      transportId: map['transportId'] as String,
      orderId: map['orderId'] as String,
      money: map['money'] as int,
      shipperUsername: map['shipperUsername'] as String,
      shipperHold: map['shipperHold'] as bool,
      wareHouseUsername: map['waveHouseUsername'] as String?,
      wareHouseHold: map['waveHouseHold'] as bool,
      handlePayment: map['handlePayment'] as bool,
      status: Status.values.firstWhere((element) => element.name == map['status'] as String),
      createAt: DateTime.parse(map['createAt'] as String),
      updateAt: DateTime.parse(map['updateAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory CashOrderEntity.fromJson(String source) =>
      CashOrderEntity.fromMap(json.decode(source) as Map<String, dynamic>);
}
