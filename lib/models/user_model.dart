class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final AddressModel? defaultAddress;
  final List<String> paymentMethodIds;
  final String? stripeCustomerId;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.defaultAddress,
    required this.paymentMethodIds,
    this.stripeCustomerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'defaultAddress': defaultAddress?.toMap(),
      'paymentMethodIds': paymentMethodIds,
      'stripeCustomerId': stripeCustomerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'],
      defaultAddress: map['defaultAddress'] != null 
          ? AddressModel.fromMap(map['defaultAddress']) 
          : null,
      paymentMethodIds: List<String>.from(map['paymentMethodIds'] ?? []),
      stripeCustomerId: map['stripeCustomerId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class AddressModel {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String? apartment;
  final String? instructions;

  AddressModel({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.apartment,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'apartment': apartment,
      'instructions': instructions,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      apartment: map['apartment'],
      instructions: map['instructions'],
    );
  }

  String get fullAddress {
    String address = street;
    if (apartment != null && apartment!.isNotEmpty) {
      address += ', $apartment';
    }
    address += ', $city, $state $zipCode';
    return address;
  }
}