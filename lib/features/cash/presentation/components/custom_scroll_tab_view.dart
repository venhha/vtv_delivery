import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vtv_common/core.dart';

import '../../domain/entities/response/cash_order_by_date_resp.dart';
import '../../domain/entities/cash_order_entity.dart';
import 'cash_item.dart';
import 'filter_cash_transfer_dialog.dart';
import 'summary_cash_on_date.dart';

class FilterCashTransferParams {
  final DateTime? filterDate;
  final String? filterShipper;

  FilterCashTransferParams({this.filterDate, this.filterShipper});

  FilterCashTransferParams copyWith({
    DateTime? selectedDate,
    String? shipperUsername,
    bool keep = true,
  }) {
    return FilterCashTransferParams(
      filterDate: keep ? (selectedDate ?? filterDate) : selectedDate,
      filterShipper: keep ? (shipperUsername ?? filterShipper) : shipperUsername,
    );
  }

  @override
  String toString() => 'FilterCashTransferParams(selectedDate: $filterDate, shipperUsername: $filterShipper)';
}

class CustomScrollTabView extends StatefulWidget {
  const CustomScrollTabView._inner({
    super.key,
    required this.listController,
    required this.typeWork,
    required this.isSlidable,
    required this.showAddress,
    this.canChangeShipper = true,
    this.onScanPressed,
    this.onInsertPressed,
    this.onConfirmPressed,
    this.onStorePressed,
    required this.warehouseSlideEndLabel,
    this.onCashItemPressed,
  });

  factory CustomScrollTabView.shipper({
    Key? key,
    required FilterListController<CashOrderByDateResp, RespData<List<CashOrderByDateResp>>, FilterCashTransferParams>
        futureListController,
    bool isSlidable = false,
    void Function(BuildContext, DateTime)? onScanPressed,
    void Function(BuildContext, DateTime)? onInsertPressed,
    void Function(BuildContext, DateTime)? onStorePressed,
    ValueCallback<CashOrderEntity>? onCashItemPressed,
    VoidCallback? onRefresh,
    bool showAddress = false,
    bool canChangeShipper = false,
  }) {
    return CustomScrollTabView._inner(
      key: key,
      listController: futureListController,
      typeWork: TypeWork.SHIPPER,
      isSlidable: isSlidable,
      onScanPressed: onScanPressed,
      onInsertPressed: onInsertPressed,
      onStorePressed: onStorePressed,
      showAddress: showAddress,
      canChangeShipper: canChangeShipper,
      warehouseSlideEndLabel: 'Xác nhận',
      onCashItemPressed: onCashItemPressed,
    );
  }

  factory CustomScrollTabView.warehouse({
    Key? key,
    required FilterListController<CashOrderByDateResp, RespData<List<CashOrderByDateResp>>, FilterCashTransferParams>
        futureListController,
    bool isSlidable = false,
    void Function(List<String>, CashOrderByDateResp)? onConfirmPressed,
    VoidCallback? onRefresh,
    bool showAddress = false,
    bool canChangeShipper = true,
    String warehouseSlideEndLabel = 'Xác nhận',
  }) {
    return CustomScrollTabView._inner(
      key: key,
      listController: futureListController,
      typeWork: TypeWork.WAREHOUSE,
      isSlidable: isSlidable,
      onConfirmPressed: onConfirmPressed,
      showAddress: showAddress,
      canChangeShipper: canChangeShipper,
      warehouseSlideEndLabel: warehouseSlideEndLabel,
    );
  }

  final FilterListController<CashOrderByDateResp, RespData<List<CashOrderByDateResp>>, FilterCashTransferParams>
      listController;

  final TypeWork typeWork;
  final bool isSlidable; // whether the list (in day) can be slidable (for shipper transfer/ warehouse confirm action)
  final bool showAddress;
  final bool canChangeShipper;

  final ValueCallback<CashOrderEntity>? onCashItemPressed;

  //# shipper action
  final void Function(BuildContext, DateTime)? onScanPressed;
  final void Function(BuildContext, DateTime)? onInsertPressed;
  final void Function(BuildContext, DateTime)? onStorePressed; //! the API logic not allow shipper to store

  //# warehouse action
  final void Function(List<String>, CashOrderByDateResp)? onConfirmPressed;

  // style
  final String warehouseSlideEndLabel;

  @override
  State<CustomScrollTabView> createState() => _CustomScrollTabViewState();
}

class _CustomScrollTabViewState extends State<CustomScrollTabView> with SingleTickerProviderStateMixin {
  final FocusNode _dateFocusNode = FocusNode(debugLabel: 'Menu Date Picker');
  final FocusNode _shipperFocusNode = FocusNode(debugLabel: 'Menu Shipper Picker');
  late final AnimationController _animationController;
  late final Animation<Offset> _offsetAnimation;

  List<String> getCashOrderIdsByDate(DateTime date, List<CashOrderByDateResp> items) {
    return items
        .where((element) => element.date == date)
        .expand((element) => element.cashOrders)
        .map((e) => e.cashOrderId)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    if (widget.isSlidable) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true);

      _offsetAnimation = Tween<Offset>(
        begin: const Offset(0.1, 0),
        end: const Offset(0, 0),
      ).animate(_animationController);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.listController.addListener(() {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    if (widget.isSlidable) _animationController.dispose();
    widget.listController.removeListener(() {
      if (mounted) setState(() {});
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listController.isLoading || widget.listController.isFiltering) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (widget.typeWork == TypeWork.SHIPPER) {
      return _shipperView();
    } else {
      return _warehouseView();
    }
  }

  Widget emptyFilterView() {
    return const Center(
        child: Text('Không tìm thấy đơn nào...', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)));
  }

  Widget _shipperView() {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.listController.refresh();
        widget.listController.performFilter();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _totalCashTransferCountAndEditClearFilter(canChangeShipper: false)),
            SliverToBoxAdapter(child: _filterInput(canChangeShipper: false)),
            if (widget.listController.filteredItems?.isEmpty == true) SliverFillRemaining(child: emptyFilterView()),
            for (final cashOnDate in widget.listController.filteredItems!) ...[
              SliverToBoxAdapter(
                child: Slidable(
                  key: ValueKey(cashOnDate.date),
                  endActionPane: widget.isSlidable ? shipperActionPane(cashOnDate.date) : null,
                  child: SummaryCashOnDate(
                    cashOnDate: cashOnDate,
                    endBuilder: widget.isSlidable
                        ? (_) => SlideTransition(
                            position: _offsetAnimation,
                            child: const Icon(Icons.keyboard_double_arrow_left_rounded, color: Colors.blue))
                        : null,
                  ),
                ),
              ),
              _sliverList(cashOnDate),
            ],
          ],
        ),
      ),
    );
  }

  Widget _warehouseView() {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.listController.refresh();
        widget.listController.performFilter();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: _totalCashTransferCountAndEditClearFilter(canChangeShipper: widget.canChangeShipper)),
            SliverToBoxAdapter(child: _filterInput(canChangeShipper: widget.canChangeShipper)),
            if (widget.listController.filteredItems?.isEmpty == true) SliverFillRemaining(child: emptyFilterView()),
            for (final cashOnDate in widget.listController.filteredItems!) ...[
              SliverToBoxAdapter(
                child: Slidable(
                  key: ValueKey(cashOnDate.date),
                  endActionPane: widget.isSlidable ? _warehouseSlideEnd(cashOnDate) : null,
                  child: SummaryCashOnDate(
                    cashOnDate: cashOnDate,
                    endBuilder: widget.isSlidable
                        ? (_) => SlideTransition(
                            position: _offsetAnimation,
                            child: const Icon(Icons.keyboard_double_arrow_left_rounded, color: Colors.blue))
                        : null,
                  ),
                ),
              ),
              _sliverList(cashOnDate),
            ],
          ],
        ),
      ),
    );
  }

  ActionPane? shipperActionPane(DateTime date) {
    if (widget.onStorePressed != null) {
      return _shipperSlideEndToStoreOrder(date);
    } else if (widget.onScanPressed != null && widget.onInsertPressed != null) {
      return _shipperSlideEndToTransferCash(date);
    }
    return null;
  }

  ActionPane _shipperSlideEndToStoreOrder(DateTime date) {
    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: 0.3,

      // All actions are defined in the children parameter.
      children: [
        const SizedBox(width: 2),
        SlidableAction(
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          icon: Icons.qr_code_scanner_sharp,
          label: 'Lưu kho',
          onPressed: (context) => widget.onStorePressed!(context, date),
        ),
      ],
    );
  }

  ActionPane _shipperSlideEndToTransferCash(DateTime date) {
    return ActionPane(
      // A motion is a widget used to control how the pane animates.
      motion: const ScrollMotion(),
      extentRatio: 0.45,

      // All actions are defined in the children parameter.
      children: [
        const SizedBox(width: 2),
        SlidableAction(
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          icon: Icons.qr_code_scanner_sharp,
          label: 'Quét',
          onPressed: (context) => widget.onScanPressed!(context, date),
        ),
        const SizedBox(width: 2),
        SlidableAction(
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: Icons.type_specimen_outlined,
          label: 'Nhập',
          onPressed: (context) => widget.onInsertPressed!(context, date),
        ),
      ],
    );
  }

  ActionPane _warehouseSlideEnd(CashOrderByDateResp cashOnDate) {
    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: 0.3,
      children: [
        const SizedBox(width: 2),
        SlidableAction(
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: Icons.check,
          label: widget.warehouseSlideEndLabel,
          onPressed: widget.onConfirmPressed != null
              ? (_) => widget.onConfirmPressed!(
                  getCashOrderIdsByDate(cashOnDate.date, widget.listController.filteredItems!), cashOnDate)
              : null,
        ),
      ],
    );
  }

  SliverList _sliverList(CashOrderByDateResp cashOnDate) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: cashOnDate.cashOrders.length,
        (context, index) => Column(
          children: [
            const SizedBox(height: 4),
            CashItem(
              onPressed: widget.onCashItemPressed != null
                  ? () => widget.onCashItemPressed!.call(cashOnDate.cashOrders[index])
                  : null,
              cash: cashOnDate.cashOrders[index],
              isWarehouse: widget.typeWork == TypeWork.WAREHOUSE,
              showAddress: widget.showAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalCashTransferCountAndEditClearFilter({required bool canChangeShipper}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          children: [
            //# total cash orders
            Text('Số đơn tìm thấy: ${widget.listController.items.expand((e) => e.cashOrders).length}'),
            const VerticalDivider(),
            if (widget.listController.filterParams.filterDate != null ||
                widget.listController.filterParams.filterShipper != null) ...[
              Text('Số đơn đã lọc: ${widget.listController.filteredItems!.expand((e) => e.cashOrders).length}'),
              const VerticalDivider(),
            ],
            //# icon search/ clear filter
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  style: VTVTheme.shrinkButton,
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final rs = await showDialog<({DateTime? selectedDate, String? shipperUsername})>(
                        context: context,
                        builder: (context) => FilterCashTransferDialog(
                              initDate: widget.listController.filterParams.filterDate,
                              initShipperUsername: widget.listController.filterParams.filterShipper,
                              canChangeShipper: canChangeShipper,
                            ));
                    if (rs == null) return;

                    if (rs.selectedDate != widget.listController.filterParams.filterDate ||
                        rs.shipperUsername != widget.listController.filterParams.filterShipper) {
                      setState(() {
                        widget.listController.filterParams = widget.listController.filterParams
                            .copyWith(selectedDate: rs.selectedDate, shipperUsername: rs.shipperUsername, keep: false);
                        widget.listController.performFilter();
                      });
                    }
                  },
                ),
                if (widget.listController.filterParams.filterDate != null ||
                    widget.listController.filterParams.filterShipper != null)
                  IconButton(
                    style: VTVTheme.shrinkButton,
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: () {
                      setState(() {
                        widget.listController.filterParams = widget.listController.filterParams
                            .copyWith(selectedDate: null, shipperUsername: null, keep: false);
                        widget.listController.performFilter();
                      });
                    },
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _filterInput({required bool canChangeShipper}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                'Ngày: ${widget.listController.filterParams.filterDate != null ? ConversionUtils.convertDateTimeToString(widget.listController.filterParams.filterDate!) : '(chưa chọn)'}'),
            MenuAnchor(
              childFocusNode: _dateFocusNode,
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return TextButton(
                  focusNode: _dateFocusNode,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: const Text('Đổi ngày'),
                );
              },
              menuChildren: widget.listController.items
                  .map((e) => MenuItemButton(
                        child: Text(ConversionUtils.convertDateTimeToString(e.date)),
                        onPressed: () {
                          if (widget.listController.filterParams.filterDate == e.date) return;
                          setState(() {
                            widget.listController.filterParams =
                                widget.listController.filterParams.copyWith(selectedDate: e.date);
                            widget.listController.performFilter();
                          });
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        if (canChangeShipper)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipper: ${widget.listController.filterParams.filterShipper ?? '(chưa chọn)'}'),
              MenuAnchor(
                childFocusNode: _shipperFocusNode,
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return TextButton(
                    focusNode: _shipperFocusNode,
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: const Text('Đổi shipper'),
                  );
                },
                menuChildren: widget.listController.items
                    .expand((e) => e.cashOrders.map((cash) => cash.shipperUsername))
                    .toSet()
                    .map((e) => MenuItemButton(
                          child: Text(e),
                          onPressed: () {
                            if (widget.listController.filterParams.filterShipper == e) return;
                            setState(() {
                              widget.listController.filterParams =
                                  widget.listController.filterParams.copyWith(shipperUsername: e);
                              widget.listController.performFilter();
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }
}
