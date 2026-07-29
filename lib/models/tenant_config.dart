class TenantConfig {
  final String id;
  final String name;
  final String slug;
  final String? address;
  final String? phone;
  final String? email;
  final String primaryColor;
  final String? logoUrl;
  final String? appName;
  final String subscriptionTier;
  final bool isActive;

  TenantConfig({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.phone,
    this.email,
    required this.primaryColor,
    this.logoUrl,
    this.appName,
    required this.subscriptionTier,
    required this.isActive,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    return TenantConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      primaryColor: json['primaryColor'] as String? ?? '#2E7D32',
      logoUrl: json['logoUrl'] as String?,
      appName: json['appName'] as String?,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'basic',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'address': address,
      'phone': phone,
      'email': email,
      'primaryColor': primaryColor,
      'logoUrl': logoUrl,
      'appName': appName,
      'subscriptionTier': subscriptionTier,
      'isActive': isActive,
    };
  }
}
