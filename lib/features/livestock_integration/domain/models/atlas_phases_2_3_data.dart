class AtlasInventoryAlertData {
  const AtlasInventoryAlertData({required this.productId, required this.productName, required this.alertType, required this.severity, required this.message, required this.quantity, required this.minimumQuantity, this.expiryDate});
  final String productId, productName, alertType, severity, message; final double quantity, minimumQuantity; final DateTime? expiryDate;
  factory AtlasInventoryAlertData.fromMap(Map<String,dynamic> m)=>AtlasInventoryAlertData(productId:m['product_id'] as String? ?? '',productName:m['product_name'] as String? ?? '',alertType:m['alert_type'] as String? ?? '',severity:m['severity'] as String? ?? '',message:m['message'] as String? ?? '',quantity:(m['quantity'] as num?)?.toDouble()??0,minimumQuantity:(m['minimum_quantity'] as num?)?.toDouble()??0,expiryDate:DateTime.tryParse(m['expiry_date'] as String? ?? ''));
}

class AtlasNutritionPerformanceData {
  const AtlasNutritionPerformanceData({required this.totalQuantity,required this.plannedQuantity,required this.consumptionVariance,required this.totalCost,required this.averageDailyGainKg,required this.costPerKgGain});
  final double totalQuantity,plannedQuantity,consumptionVariance,totalCost,averageDailyGainKg,costPerKgGain;
  factory AtlasNutritionPerformanceData.fromMap(Map<String,dynamic> m)=>AtlasNutritionPerformanceData(totalQuantity:(m['total_quantity']as num?)?.toDouble()??0,plannedQuantity:(m['planned_quantity']as num?)?.toDouble()??0,consumptionVariance:(m['consumption_variance']as num?)?.toDouble()??0,totalCost:(m['total_cost']as num?)?.toDouble()??0,averageDailyGainKg:(m['average_daily_gain_kg']as num?)?.toDouble()??0,costPerKgGain:(m['cost_per_kg_gain']as num?)?.toDouble()??0);
}

class AtlasFinancialSummaryData {
 const AtlasFinancialSummaryData({required this.income,required this.expense,required this.receivable,required this.payable,required this.balance,required this.projectedBalance,required this.costByCenter,required this.costByLot,required this.costByAnimal,required this.indicators});
 final double income,expense,receivable,payable,balance,projectedBalance; final Map<String,double> costByCenter,costByLot,costByAnimal,indicators;
 static Map<String,double> _numbers(dynamic value)=>Map<String,dynamic>.from(value as Map? ?? const {}).map((k,v)=>MapEntry(k,(v as num?)?.toDouble()??0));
 factory AtlasFinancialSummaryData.fromMap(Map<String,dynamic> m)=>AtlasFinancialSummaryData(income:(m['income']as num?)?.toDouble()??0,expense:(m['expense']as num?)?.toDouble()??0,receivable:(m['receivable']as num?)?.toDouble()??0,payable:(m['payable']as num?)?.toDouble()??0,balance:(m['balance']as num?)?.toDouble()??0,projectedBalance:(m['projected_balance']as num?)?.toDouble()??0,costByCenter:_numbers(m['cost_by_center']),costByLot:_numbers(m['cost_by_lot']),costByAnimal:_numbers(m['cost_by_animal']),indicators:_numbers(m['indicators']));
}
