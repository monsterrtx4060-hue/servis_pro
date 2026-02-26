class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? address;

  Customer({this.id, required this.name, required this.phone, this.address});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'address': address};
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      address: map['address']?.toString(),
    );
  }
}
