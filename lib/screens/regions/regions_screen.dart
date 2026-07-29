import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/region.dart';
import '../../providers/data_provider.dart';

class RegionsScreen extends ConsumerWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ref.watch(regionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/regions/add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(regionProvider.notifier).refresh(),
        child: regions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No regions yet',
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
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  return _RegionCard(
                    region: region,
                    onTap: () => context.push('/regions/edit/${region.id}'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Region'),
                          content: const Text(
                              'Are you sure you want to delete this region?'),
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
                        await ref.read(regionProvider.notifier).delete(region.id);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  final Region region;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RegionCard({
    required this.region,
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
            region.name[0].toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          region.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          region.description,
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
