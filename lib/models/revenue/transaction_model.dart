class TransactionModel {
  final int id;
  final String patientName;
  final String date;
  final double amount;
  final String paymentMethod;

  TransactionModel({
    required this.id,
    required this.patientName,
    required this.date,
    required this.amount,
    required this.paymentMethod,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      patientName: json['patient_name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'stripe',
    );
  }
}
