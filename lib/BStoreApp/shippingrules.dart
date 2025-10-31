class ShippingRule {
  final String areaName;
  final String charge;
  final String contactNumber;
  final String codInstructions;
  final String bKashInstructions;
  final String nagadInstructions;
  final String rocketInstructions;

  ShippingRule({
    required this.areaName,
    required this.charge,
    required this.contactNumber,
    required this.codInstructions,
    required this.bKashInstructions,
    required this.nagadInstructions,
    required this.rocketInstructions,
  });

  factory ShippingRule.fromJson(Map<String, dynamic> json) {
    return ShippingRule(
      areaName: json['area_name']?.toString() ?? 'Unknown Area',
      charge: json['charge']?.toString() ?? '60',
      contactNumber: json['contact_number']?.toString() ?? '',
      codInstructions: json['COD_instructions']?.toString() ?? '',
      bKashInstructions: json['bKash_instructions']?.toString() ?? '',
      nagadInstructions: json['Nagad_instructions']?.toString() ?? '',
      rocketInstructions: json['Rocket_instructions']?.toString() ?? '',
    );
  }
}
