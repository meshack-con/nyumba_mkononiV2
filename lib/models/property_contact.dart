class PropertyContact {
  const PropertyContact({
    required this.ownerName,
    required this.ownerPhone,
    this.ownerEmail,
  });
  final String ownerName;
  final String ownerPhone;
  final String? ownerEmail;
  factory PropertyContact.fromJson(Map<String, dynamic> json) => PropertyContact(
        ownerName: json['owner_jina'] as String,
        ownerPhone: json['owner_simu'] as String,
        ownerEmail: json['owner_email'] as String?,
      );
}
