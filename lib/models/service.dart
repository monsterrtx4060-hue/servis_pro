class Service {
  final int? id;
  final int customerId;
  final String product;
  final String problem;
  final double price;
  final String doneDescription;
  final String plannedDate; // yyyy-MM-dd
  final String date; // yyyy-MM-dd
  final String serviceStatus;

  Service({
    this.id,
    required this.customerId,
    required this.product,
    required this.problem,
    required this.price,
    required this.doneDescription,
    required this.plannedDate,
    required this.date,
    required this.serviceStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'product': product,
      'problem': problem,
      'price': price,
      'done_description': doneDescription,
      'planned_date': plannedDate,
      'date': date,
      'service_status': serviceStatus,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    final priceRaw = map['price'];
    final parsedPrice = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw.toString()) ?? 0.0;

    return Service(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      product: (map['product'] ?? '').toString(),
      problem: (map['problem'] ?? '').toString(),
      price: parsedPrice,
      doneDescription: (map['done_description'] ?? '').toString(),
      plannedDate: (map['planned_date'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      serviceStatus: (map['service_status'] ?? 'Açık').toString(),
    );
  }
}
