import 'package:flutter/material.dart';
import 'package:vtv_common/core.dart';
import 'package:vtv_common/guest.dart';
import 'package:vtv_common/order.dart';
import 'package:vtv_common/shop.dart';

import '../../../../service_locator.dart';
import '../../domain/entities/shop_and_transport_entity.dart';
import '../../domain/entities/ward_work_entity.dart';
import '../../domain/repository/deliver_repository.dart';

class NearbyOrders extends StatelessWidget {
  const NearbyOrders({super.key, this.wardWork});

  final WardWorkEntity? wardWork;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: wardWork != null
          ? sl<DeliverRepository>().getTransportByWardCode(wardWork!.wardCode)
          : sl<DeliverRepository>().getTransportByWardWork(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!.fold(
            (error) => MessageScreen.error(error.message),
            (ok) => Column(
              children: [
                Text(
                  'Các đơn hàng cần giao tại ${wardWork != null ? wardWork!.fullName : 'khu vực của bạn'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final shopAndTransport in ok.data!.shopAndTransports)
                  if (shopAndTransport.count > 0) ShopAndTransport(shopAndTransport: shopAndTransport),
                // ListView.builder(
                //   shrinkWrap: true,
                //   physics: const NeverScrollableScrollPhysics(),
                //   itemCount: ok.data!.shopAndTransports.length,
                //   itemBuilder: (context, index) {
                //     final shopAndTransport = ok.data!.shopAndTransports[index];
                //     if (shopAndTransport.count > 0) {
                //       return ShopAndTransport(shopAndTransport: shopAndTransport);
                //     }
                //     return const SizedBox.shrink();
                //   },
                // ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
        // return const Center(
        //   child: CircularProgressIndicator(),
        // );
      },
    );
  }
}

class ShopAndTransport extends StatelessWidget {
  const ShopAndTransport({super.key, required this.shopAndTransport});

  // include:
  // final int count;
  // final String wardCode;
  // final String wardName;
  // final ShopEntity shop;
  // final List<TransportEntity> transports;
  final ShopAndTransportEntity shopAndTransport;

  @override
  Widget build(BuildContext context) {
    return Wrapper(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShopInfo(
            shopId: shopAndTransport.shop.shopId,
            shopName: shopAndTransport.shop.name,
            shopAvatar: shopAndTransport.shop.avatar,
            trailing: Text('Số đơn hàng: ${shopAndTransport.count}'),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            'Địa chỉ Shop: ${shopAndTransport.shop.address}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final transport in shopAndTransport.transports) TransportItem(transport: transport),
        ],
      ),
    );
  }
}

class TransportItem extends StatelessWidget {
  const TransportItem({super.key, required this.transport});

  final TransportEntity transport;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.tertiaryContainer),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildStatus(transport.transportHandles.first.transportStatus),
          Text('Đơn hàng: ${transport.orderId}'),
          FullAddressByWardCode(
            prefixString: 'Địa chỉ giao hàng: ',
            wardCode: transport.wardCodeCustomer,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatus(OrderStatus status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Trạng thái:'),
        OrderStatusBadge(status: status, type: OrderStatusBadgeType.driver),
      ],
    );
  }
}

class FullAddressByWardCode extends StatelessWidget {
  const FullAddressByWardCode({super.key, required this.wardCode, this.prefixString, this.style});

  final String wardCode;
  final String? prefixString;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sl<GuestRepository>().getFullAddressByWardCode(wardCode),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!.fold(
            (error) => MessageScreen.error(error.message),
            (ok) => Text(
              '${prefixString ?? ''}${ok.data!}',
              style: style,
              maxLines: 2,
            ),
          );
        }
        return const SizedBox.shrink();
        // return const Center(
        //   child: Text(
        //     'Đang tải địa chỉ...',
        //     textAlign: TextAlign.center,
        //     style: TextStyle(color: Colors.black54),
        //   ),
        // );
      },
    );
  }
}