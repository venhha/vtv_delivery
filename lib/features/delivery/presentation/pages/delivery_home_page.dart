import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vtv_common/auth.dart';
import 'package:vtv_common/core.dart';

import '../../../../app_state.dart';
import '../components/menu_action_item.dart';
import 'delivery_scanner_page.dart';

//! json format for warehouse's qr
// {
//   'wU': warehouseUsername,
//   'wC': warehouseWardCode,
// }

const _menuLabelTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
const _cashLabelTextStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({
    super.key,
  });

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  bool _isReturn = false;

  @override
  Widget build(BuildContext context) {
    final TypeWork typeWork = Provider.of<AppState>(context).typeWork;
    return Stack(
      fit: StackFit.expand,
      children: [
        // if (typeWork == TypeWork.WAREHOUSE) Align(alignment: Alignment.topCenter, child: _warehouseQrCode()),
        //# app bar actions
        Align(
          alignment: Alignment.topLeft,
          child: IntrinsicHeight(
            child: Builder(
              builder: (context) {
                if (typeWork == TypeWork.WAREHOUSE) {
                  return _warehouseAppBar(context);
                } else if (typeWork == TypeWork.PICKUP) {
                  //# view nearby orders
                  return _pickupAppBar(context);
                } else if (typeWork == TypeWork.SHIPPER) {
                  //# view nearby orders
                  return _shipperAppBar(context);
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),

        //# menu actions
        Align(
          alignment: Alignment.center,
          child: IntrinsicHeight(
            child: Builder(builder: (context) {
              if (typeWork == TypeWork.SHIPPER || typeWork == TypeWork.WAREHOUSE) {
                return _shipperAndWarehouseActions(context, typeWork);
              } else if (typeWork == TypeWork.PICKUP) {
                return _pickupActions(context);
              }
              return const SizedBox.shrink();
            }),
          ),
        ),

        //# bottom actions: toggle _isReturn (only for shipper & warehouse)
        if (typeWork == TypeWork.SHIPPER || typeWork == TypeWork.WAREHOUSE)
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: Tooltip(
                message: 'Chuyển đổi chế độ hoàn hàng',
                child: TextButton.icon(
                  label: _isReturn ? const Text('Chế độ hoàn hàng') : const Text('Chế độ giao hàng'),
                  icon: _isReturn ? const Icon(Icons.backspace_rounded) : const Icon(Icons.real_estate_agent_rounded),
                  onPressed: () {
                    setState(() {
                      _isReturn = !_isReturn;
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Builder _warehouseQrCode() {
  Row _pickupAppBar(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        MenuActionItem(
          label: 'Đơn hàng\ngần đây',
          icon: Icons.location_on_outlined,
          color: Colors.orange,
          size: 50,
          labelTextStyle: _cashLabelTextStyle,
          onPressed: () => Navigator.of(context).pushNamed('/pickup'),
        ),
        const SizedBox(width: 16),
        menuActionAcceptOrDeniedReturnOrder(context),
      ],
    );
  }

  Row _shipperAppBar(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        menuActionAcceptOrDeniedReturnOrder(context),
      ],
    );
  }

  Widget _pickupActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //# open scanner to get order's qr >> pickup then deliver to warehouse
        MenuActionItem(
          label: 'Lấy hàng',
          icon: Icons.qr_code,
          color: Colors.blue,
          labelTextStyle: _menuLabelTextStyle,
          onPressed: () async {
            Navigator.of(context).pushNamed(DeliveryScannerPage.routeName, arguments: DeliveryType.pickup);
          },
        ),
      ],
    );
  }

  Row _warehouseAppBar(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 16),
        //# warehouse's qr
        MenuActionItem(
          label: 'QR của kho',
          icon: Icons.qr_code,
          color: Colors.orange,
          size: 50,
          labelTextStyle: _cashLabelTextStyle,
          onPressed: () async {
            final warehouseUsername = context.read<AuthCubit>().state.currentUsername;
            final warehouseWardCode = Provider.of<AppState>(context, listen: false).deliveryInfo!.wardCode;
            final data = jsonEncode({
              'wU': warehouseUsername,
              'wC': warehouseWardCode,
            });
            Navigator.of(context).pushNamed('/qr', arguments: data);
          },
        ),

        const SizedBox(width: 16),
        menuActionAcceptOrDeniedReturnOrder(context),

        const SizedBox(width: 16),
        Tooltip(
          message: 'Chấp nhận trả hàng hoặc từ chối hoàn hàng',
          child: MenuActionItem(
            label: 'Hủy đơn hàng',
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
            size: 50,
            labelTextStyle: _cashLabelTextStyle,
            onPressed: () {
              Navigator.of(context).pushNamed(DeliveryScannerPage.routeName, arguments: DeliveryType.forcedReturn);
            },
          ),
        ),
      ],
    );
  }

  Tooltip menuActionAcceptOrDeniedReturnOrder(BuildContext context) {
    return Tooltip(
      message: 'Chấp nhận hoặc từ chối hoàn trả hàng ',
      child: MenuActionItem(
        label: 'Chấp nhận / Từ chối\nHoàn hàng',
        icon: Icons.qr_code_scanner,
        color: Colors.cyan,
        size: 50,
        labelTextStyle: _cashLabelTextStyle,
        onPressed: () {
          Navigator.of(context).pushNamed(DeliveryScannerPage.routeName, arguments: DeliveryType.pickup);
        },
      ),
    );
  }

  Widget pickupReturnForWarehouseAndPickerMenuAction(BuildContext context, TypeWork typeWork) {
    if (typeWork != TypeWork.WAREHOUSE && typeWork != TypeWork.SHIPPER) return const SizedBox.shrink();

    return Tooltip(
      message: typeWork == TypeWork.WAREHOUSE
          ? 'Lưu kho đơn hàng hoàn hàng từ pickup / shipper'
          : 'Lấy hàng từ kho để chuẩn bị giao',
      child: MenuActionItem(
        label: typeWork == TypeWork.WAREHOUSE ? 'Lưu kho / Nhận hàng\n(hoàn hàng)' : 'Lấy hàng từ kho\n(hoàn hàng)',
        icon: Icons.qr_code_scanner,
        color: Colors.blue,
        labelTextStyle: _menuLabelTextStyle,
        onPressed: () async {
          await Navigator.of(context).pushNamed(DeliveryScannerPage.routeName, arguments: DeliveryType.pickupReturn);
        },
      ),
    );
  }

  Widget deliveredReturnForWarehouseAndPickerMenuAction(BuildContext context, TypeWork typeWork) {
    if (typeWork != TypeWork.WAREHOUSE && typeWork != TypeWork.SHIPPER) return const SizedBox.shrink();

    return Tooltip(
      message: 'Trả hàng cho shop',
      child: MenuActionItem(
        label: 'Giao cho shop\n(hoàn hàng)',
        icon: Icons.assignment_turned_in_outlined,
        color: Colors.green,
        labelTextStyle: _menuLabelTextStyle,
        onPressed: () async {
          await Navigator.of(context).pushNamed(DeliveryScannerPage.routeName, arguments: DeliveryType.deliveredReturn);
        },
      ),
    );
  }

  Widget _shipperAndWarehouseActions(BuildContext context, TypeWork typeWork) {
    return Wrap(
      // mainAxisAlignment: MainAxisAlignment.center,
      // mainAxisSize: MainAxisSize.min,
      children: [
        if (_isReturn) ...[
          pickupReturnForWarehouseAndPickerMenuAction(context, typeWork),
          const SizedBox(width: 10),
          deliveredReturnForWarehouseAndPickerMenuAction(context, typeWork),
        ] else ...[
          Tooltip(
            message: typeWork == TypeWork.WAREHOUSE
                ? 'Lưu kho đơn hàng từ người lấy hàng / shop'
                : 'Lấy hàng từ kho để chuẩn bị giao',
            child: MenuActionItem(
              label: typeWork == TypeWork.WAREHOUSE ? 'Lưu kho / Nhận hàng' : 'Lấy hàng từ kho',
              icon: Icons.qr_code_scanner,
              color: Colors.blue,
              labelTextStyle: _menuLabelTextStyle,
              onPressed: () async {
                await Navigator.of(context).pushNamed(DeliveryScannerPage.routeName, arguments: DeliveryType.pickup);
              },
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Giao hàng cho khách',
            child: MenuActionItem(
              label: 'Giao cho khách',
              icon: Icons.assignment_turned_in_outlined,
              color: Colors.green,
              labelTextStyle: _menuLabelTextStyle,
              onPressed: () async {
                await Navigator.of(context).pushNamed(DeliveryScannerPage.routeName, arguments: DeliveryType.delivered);
              },
            ),
          ),
        ]
      ],
    );
  }
}
