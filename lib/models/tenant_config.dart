class TenantConfig {
  final String id;
  final String name;
  final String slug;
  final String? address;
  final String? phone;
  final String? email;
  final String primaryColor;
  final String secondaryColor;
  final String? logoUrl;
  final String? bannerUrl;
  final String? appName;
  final int maxMembers;
  final int maxBranches;
  final String subscriptionTier;
  final String? subscriptionExpiry;
  final List<String> enabledModules;
  final bool isActive;

  // Branding & website content
  final String? motto;
  final String? aboutText;
  final String? mission;
  final String? vision;
  final String? pastorMessage;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;

  TenantConfig({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.phone,
    this.email,
    required this.primaryColor,
    this.secondaryColor = '#FFD600',
    this.logoUrl,
    this.bannerUrl,
    this.appName,
    this.maxMembers = 500,
    this.maxBranches = 5,
    required this.subscriptionTier,
    this.subscriptionExpiry,
    this.enabledModules = const ['members', 'attendance', 'finance', 'sermons', 'events', 'welfare'],
    required this.isActive,
    this.motto,
    this.aboutText,
    this.mission,
    this.vision,
    this.pastorMessage,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
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
      secondaryColor: json['secondaryColor'] as String? ?? '#FFD600',
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      appName: json['appName'] as String?,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 500,
      maxBranches: (json['maxBranches'] as num?)?.toInt() ?? 5,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'basic',
      subscriptionExpiry: json['subscriptionExpiry'] as String?,
      enabledModules: (json['enabledModules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['members', 'attendance', 'finance', 'sermons', 'events', 'welfare'],
      isActive: json['isActive'] as bool? ?? true,
      motto: json['motto'] as String?,
      aboutText: json['aboutText'] as String?,
      mission: json['mission'] as String?,
      vision: json['vision'] as String?,
      pastorMessage: json['pastorMessage'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
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
      'secondaryColor': secondaryColor,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'appName': appName,
      'maxMembers': maxMembers,
      'maxBranches': maxBranches,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiry': subscriptionExpiry,
      'enabledModules': enabledModules,
      'isActive': isActive,
      'motto': motto,
      'aboutText': aboutText,
      'mission': mission,
      'vision': vision,
      'pastorMessage': pastorMessage,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'twitterUrl': twitterUrl,
    };
  }

  bool hasModule(String module) => enabledModules.contains(module);
}
