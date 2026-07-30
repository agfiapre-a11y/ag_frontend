import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/dynamic_theme.dart';
import '../../models/tenant_config.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_config.dart';
import '../../widgets/responsive_scaffold.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).loadTenants();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TenantConfig> get _filteredTenants {
    final tenants = ref.watch(superAdminProvider).tenants;
    if (_searchQuery.isEmpty) return tenants;
    final q = _searchQuery.toLowerCase();
    return tenants
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.slug.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);
    final appState = ref.watch(appStateProvider);
    final user = appState.user;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text('Church Management',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(superAdminProvider.notifier).loadTenants(),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white24,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.church), text: 'Churches'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorView(state.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChurchesTab(),
                    _buildUsersTab(),
                    _buildSettingsTab(appState),
                  ],
                ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateTenantDialog(context),
              icon: const Icon(Icons.add),
              label: Text('Add Church',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(superAdminProvider.notifier).loadTenants(),
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchesTab() {
    final tenants = _filteredTenants;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search churches...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        if (tenants.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.church_outlined,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No churches yet',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Tap "Add Church" to create your first tenant',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final tenant = tenants[index];
                return _TenantCard(
                  tenant: tenant,
                  onEdit: () => _showEditTenantDialog(context, tenant),
                  onDelete: () => _confirmDelete(context, tenant),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('User Management',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Manage admin accounts across all churches',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AppState appState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsCard(
          title: 'Platform Information',
          children: [
            _SettingsRow(label: 'API URL', value: ApiConfig.baseUrl),
            _SettingsRow(
                label: 'Configured',
                value: ApiConfig.isConfigured ? 'Yes' : 'No'),
            _SettingsRow(
                label: 'Total Churches',
                value: '${ref.watch(superAdminProvider).tenants.length}'),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Default Modules',
          children: [
            Wrap(
              spacing: 8,
              children: [
                'members',
                'attendance',
                'finance',
                'sermons',
                'events',
                'welfare',
              ]
                  .map((m) => Chip(
                        label: Text(m,
                            style: GoogleFonts.poppins(fontSize: 12)),
                        avatar: Icon(_moduleIcon(m), size: 18),
                      ))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  IconData _moduleIcon(String module) {
    switch (module) {
      case 'members':
        return Icons.people;
      case 'attendance':
        return Icons.check_circle_outline;
      case 'finance':
        return Icons.account_balance_wallet;
      case 'sermons':
        return Icons.menu_book;
      case 'events':
        return Icons.event;
      case 'welfare':
        return Icons.volunteer_activism;
      default:
        return Icons.extension;
    }
  }

  void _showCreateTenantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _TenantFormDialog(),
    );
  }

  void _showEditTenantDialog(BuildContext context, TenantConfig tenant) {
    showDialog(
      context: context,
      builder: (_) => _TenantFormDialog(tenant: tenant),
    );
  }

  void _confirmDelete(BuildContext context, TenantConfig tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Church?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
            'Are you sure you want to deactivate "${tenant.name}"? This will make the church inactive.',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref
                  .read(superAdminProvider.notifier)
                  .deleteTenant(tenant.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ?? 'Church deactivated successfully'),
                  backgroundColor: err != null ? AppColors.error : AppColors.primary,
                ));
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final TenantConfig tenant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TenantCard({
    required this.tenant,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = DynamicTheme.primaryColor(tenant);
    final secondary = DynamicTheme.secondaryColor(tenant);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: primary,
          child: tenant.logoUrl != null
              ? ClipOval(
                  child: Image.network(tenant.logoUrl!,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                    return Text(tenant.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.bold));
                  }),
                )
              : Text(tenant.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(tenant.name,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tenant.subscriptionTier.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 10, color: primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text('${tenant.enabledModules.length} modules',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
            if (!tenant.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('INACTIVE',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Slug', value: tenant.slug),
                _DetailRow(label: 'Email', value: tenant.email ?? '—'),
                _DetailRow(label: 'Phone', value: tenant.phone ?? '—'),
                _DetailRow(label: 'Address', value: tenant.address ?? '—'),
                _DetailRow(
                    label: 'Max Members', value: '${tenant.maxMembers}'),
                _DetailRow(
                    label: 'Max Branches', value: '${tenant.maxBranches}'),
                _DetailRow(
                    label: 'Subscription Expiry',
                    value: tenant.subscriptionExpiry ?? '—'),
                _DetailRow(
                    label: 'Primary Color',
                    value: tenant.primaryColor,
                    colorSwatch: primary),
                _DetailRow(
                    label: 'Secondary Color',
                    value: tenant.secondaryColor,
                    colorSwatch: secondary),
                const SizedBox(height: 8),
                Text('Enabled Modules',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: tenant.enabledModules
                      .map<Widget>((m) => Chip(
                            label: Text(m,
                                style: GoogleFonts.poppins(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
                if (tenant.motto != null) ...[
                  const SizedBox(height: 8),
                  Text('Motto',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(tenant.motto!,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text('Edit',
                          style: GoogleFonts.poppins(fontSize: 13)),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      label: Text('Deactivate',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? colorSwatch;

  const _DetailRow({
    required this.label,
    required this.value,
    this.colorSwatch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Row(
              children: [
                if (colorSwatch != null) ...[
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorSwatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(value,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TenantFormDialog extends ConsumerStatefulWidget {
  final TenantConfig? tenant;

  const _TenantFormDialog({this.tenant});

  @override
  ConsumerState<_TenantFormDialog> createState() => _TenantFormDialogState();
}

class _TenantFormDialogState extends ConsumerState<_TenantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _maxMembersCtrl = TextEditingController(text: '500');
  final _maxBranchesCtrl = TextEditingController(text: '5');
  final _subscriptionExpiryCtrl = TextEditingController();

  String _subscriptionTier = 'basic';
  String _primaryColor = '#2E7D32';
  String _secondaryColor = '#FFD600';
  Set<String> _enabledModules = {
    'members',
    'attendance',
    'finance',
    'sermons',
    'events',
    'welfare'
  };

  @override
  void initState() {
    super.initState();
    if (widget.tenant != null) {
      final t = widget.tenant!;
      _nameCtrl.text = t.name;
      _slugCtrl.text = t.slug;
      _addressCtrl.text = t.address ?? '';
      _phoneCtrl.text = t.phone ?? '';
      _emailCtrl.text = t.email ?? '';
      _maxMembersCtrl.text = t.maxMembers.toString();
      _maxBranchesCtrl.text = t.maxBranches.toString();
      _subscriptionExpiryCtrl.text = t.subscriptionExpiry ?? '';
      _subscriptionTier = t.subscriptionTier;
      _primaryColor = t.primaryColor;
      _secondaryColor = t.secondaryColor;
      _enabledModules = t.enabledModules.toSet();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _maxMembersCtrl.dispose();
    _maxBranchesCtrl.dispose();
    _subscriptionExpiryCtrl.dispose();
    super.dispose();
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = ref.read(superAdminProvider.notifier);
    String? error;

    if (widget.tenant != null) {
      error = await notifier.updateTenant(widget.tenant!.id, {
        'name': _nameCtrl.text.trim(),
        'slug': _slugCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'maxMembers': int.tryParse(_maxMembersCtrl.text) ?? 500,
        'maxBranches': int.tryParse(_maxBranchesCtrl.text) ?? 5,
        'subscriptionTier': _subscriptionTier,
        'subscriptionExpiry': _subscriptionExpiryCtrl.text.trim(),
        'primaryColor': _primaryColor,
        'secondaryColor': _secondaryColor,
        'enabledModules': _enabledModules.toList(),
      });
    } else {
      error = await notifier.createTenant(
        name: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        maxMembers: int.tryParse(_maxMembersCtrl.text) ?? 500,
        maxBranches: int.tryParse(_maxBranchesCtrl.text) ?? 5,
        subscriptionTier: _subscriptionTier,
        subscriptionExpiry: _subscriptionExpiryCtrl.text.trim(),
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        enabledModules: _enabledModules.toList(),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ));
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.tenant != null
              ? 'Church updated successfully'
              : 'Church created successfully'),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tenant != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Church' : 'Add New Church',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Church Name *',
                    prefixIcon: Icon(Icons.church),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onChanged: (v) {
                    if (!isEdit) {
                      _slugCtrl.text = _slugify(v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _slugCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Slug *',
                    prefixIcon: Icon(Icons.link),
                    helperText: 'URL identifier, e.g. paradise-ag',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxMembersCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Max Members',
                          prefixIcon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxBranchesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Max Branches',
                          prefixIcon: Icon(Icons.account_tree),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _subscriptionTier,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Tier',
                    prefixIcon: Icon(Icons.star),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'basic', child: Text('Basic')),
                    DropdownMenuItem(
                        value: 'standard', child: Text('Standard')),
                    DropdownMenuItem(
                        value: 'premium', child: Text('Premium')),
                  ],
                  onChanged: (v) =>
                      setState(() => _subscriptionTier = v ?? 'basic'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subscriptionExpiryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Expiry (YYYY-MM-DD)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ColorPicker(
                        label: 'Primary',
                        color: _primaryColor,
                        onChanged: (c) =>
                            setState(() => _primaryColor = c),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ColorPicker(
                        label: 'Secondary',
                        color: _secondaryColor,
                        onChanged: (c) =>
                            setState(() => _secondaryColor = c),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Enabled Modules',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    'members',
                    'attendance',
                    'finance',
                    'sermons',
                    'events',
                    'welfare',
                  ].map((m) {
                    final selected = _enabledModules.contains(m);
                    return FilterChip(
                      label: Text(m,
                          style: GoogleFonts.poppins(fontSize: 12)),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _enabledModules.add(m);
                          } else {
                            _enabledModules.remove(m);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Update' : 'Create',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String label;
  final String color;
  final ValueChanged<String> onChanged;

  const _ColorPicker({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  static const _presets = [
    '#2E7D32',
    '#1565C0',
    '#C62828',
    '#6A1B9A',
    '#EF6C00',
    '#00838F',
    '#FFD600',
    '#FFFFFF',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showColorDialog(context),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _parseColor(color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                color,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isLight(_parseColor(color))
                        ? Colors.black54
                        : Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showColorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pick $label Color',
            style: GoogleFonts.poppins(fontSize: 16)),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((c) {
            return GestureDetector(
              onTap: () {
                onChanged(c);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _parseColor(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == c ? AppColors.primary : Colors.grey.shade300,
                    width: color == c ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 7) buffer.write('FF');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  bool _isLight(Color c) {
    return c.computeLuminance() > 0.5;
  }
}
