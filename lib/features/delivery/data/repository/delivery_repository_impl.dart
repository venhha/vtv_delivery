import 'package:vtv_common/core.dart';
import 'package:vtv_common/order.dart';

import '../../domain/entities/deliver_entity.dart';
import '../../domain/entities/res/transport_resp.dart';
import '../../domain/repository/delivery_repository.dart';
import '../data_sources/delivery_data_source.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryDataSource _dataSource;

  DeliveryRepositoryImpl(this._dataSource);

  @override
  FRespData<DeliverEntity> getDeliverInfo() async {
    return handleDataResponseFromDataSource(dataCallback: () => _dataSource.getDeliverInfo());
  }

  @override
  FRespData<TransportResp> getTransportByWardCode(String wardCode) async {
    return handleDataResponseFromDataSource(dataCallback: () => _dataSource.getTransportByWardCode(wardCode));
  }

  @override
  FRespData<TransportEntity> updateStatusTransportByDeliver(
    String transportId,
    OrderStatus status,
    bool handled,
    String wardCode,
  ) async {
    return handleDataResponseFromDataSource(
      dataCallback: () => _dataSource.updateStatusTransportByDeliver(transportId, status, handled, wardCode),
    );
  }

  @override
  FRespData<TransportResp> getTransportByWardWork() async {
    return handleDataResponseFromDataSource(dataCallback: () => _dataSource.getTransportByWardWork());
  }
}
