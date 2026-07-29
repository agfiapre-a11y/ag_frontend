import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/organization.dart';
import '../../providers/data_provider.dart';

class OrganizationsScreen extends ConsumerWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/organizations/add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(organizationProvider.notifier).refresh(),
        child: organizations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No organizations yet',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: organizations.length,
                itemBuilder: (context, index) {
                  final org = organizations[index];
                  return _OrganizationCard(
                    organization: org,
                    onTap: () => context.push('/organizations/edit/${org.id}'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Organization'),
                          content: const Text(
                              'Are you sure you want to delete this organization?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.errorRed),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(organizationProvider.notifier)
                            .delete(org.id);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  final Organization organization;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OrganizationCard({
    required this.organization,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.emeraldDeep,
          child: Text(
            organization.name[0].toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          organization.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          organization.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onTap,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
