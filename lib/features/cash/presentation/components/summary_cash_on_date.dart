import 'package:flutter/material.dart';
import 'package:vtv_common/core.dart';

import '../../domain/entities/cash_order_by_date_entity.dart';

class SummaryCashOnDate extends StatelessWidget {
  const SummaryCashOnDate({
    super.key,
    required this.cashOnDate,
    this.endBuilder,
  });

  final CashOrderByDateEntity cashOnDate;
  final WidgetBuilder? endBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: ListDynamic(list: {
                'Ngày:': ConversionUtils.convertDateTimeToString(cashOnDate.date),
                'Số đơn đã giao:': cashOnDate.cashOrders.length.toString(),
                'Tổng tiền thu:': ConversionUtils.formatCurrency(cashOnDate.totalMoney),
              }),
            ),
            if (endBuilder != null) ...[const SizedBox(width: 8), endBuilder!(context)],
          ],
        ),
      ),
    );
  }
}
