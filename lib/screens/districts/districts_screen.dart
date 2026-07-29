import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/district.dart';
import '../../providers/data_provider.dart';

class DistrictsScreen extends ConsumerWidget {
  const DistrictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districts = ref.watch(districtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Districts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/districts/add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(districtProvider.notifier).refresh(),
        child: districts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_city_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No districts yet',
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
                itemCount: districts.length,
                itemBuilder: (context, index) {
                  final district = districts[index];
                  return _DistrictCard(
                    district: district,
                    onTap: () => context.push('/districts/edit/${district.id}'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete District'),
                          content: const Text(
                              'Are you sure you want to delete this district?'),
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
                        await ref.read(districtProvider.notifier).delete(district.id);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _DistrictCard extends StatelessWidget {
  final District district;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DistrictCard({
    required this.district,
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
            district.name[0].toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          district.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          district.description,
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
