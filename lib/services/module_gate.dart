import '../models/tenant_config.dart';
import '../providers/tenant_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModuleGate {
  static const String members = 'members';
  static const String attendance = 'attendance';
  static const String finance = 'finance';
  static const String sermons = 'sermons';
  static const String events = 'events';
  static const String welfare = 'welfare';
  static const String branches = 'branches';
  static const String departments = 'departments';
  static const String users = 'users';

  static bool isModuleEnabled(TenantConfig? config, String module) {
    if (config == null) return true;
    return config.hasModule(module);
  }

  static bool canAddMember(TenantConfig? config, int currentMemberCount) {
    if (config == null) return true;
    return currentMemberCount < config.maxMembers;
  }

  static bool canAddBranch(TenantConfig? config, int currentBranchCount) {
    if (config == null) return true;
    return currentBranchCount < config.maxBranches;
  }

  static bool isSubscriptionActive(TenantConfig? config) {
    if (config == null) return true;
    if (config.subscriptionExpiry == null || config.subscriptionExpiry!.isEmpty) {
      return true;
    }
    try {
      final expiry = DateTime.parse(config.subscriptionExpiry!);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return true;
    }
  }

  static String? getUpgradeMessage(TenantConfig? config, String module) {
    if (!isModuleEnabled(config, module)) {
      return 'This feature is not available in your current plan. Contact your administrator to upgrade.';
    }
    if (!isSubscriptionActive(config)) {
      return 'Your subscription has expired. Contact your administrator to renew.';
    }
    return null;
  }
}

final moduleGateProvider = Provider<ModuleGate>((ref) => ModuleGate());

final enabledModulesProvider = Provider<List<String>>((ref) {
  final config = ref.watch(tenantConfigProvider);
  return config?.enabledModules ?? [
    ModuleGate.members,
    ModuleGate.attendance,
    ModuleGate.finance,
    ModuleGate.sermons,
    ModuleGate.events,
    ModuleGate.welfare,
  ];
});
