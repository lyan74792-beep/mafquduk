// Admins tab: pending admin accounts awaiting approval with approve / reject confirmation buttons.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../data/models/admin.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminsTab extends StatefulWidget {
  const AdminsTab({super.key});

  @override
  State<AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends State<AdminsTab> {
  final AdminRepository _repo = AdminRepository();
  final Set<int> _busyIds = <int>{};

  Future<void> _handleAction({
    required PendingAdmin admin,
    required bool approve,
    required Future<void> Function() reload,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          approve
              ? t('adminApproveAdminConfirmTitle')
              : t('adminRejectAdminConfirmTitle'),
        ),
        content: Text(
          approve
              ? t('adminApproveAdminConfirmBody')
              : t('adminRejectAdminConfirmBody'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('adminCancel')),
          ),
          ElevatedButton(
            style: approve
                ? null
                : ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('adminConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(admin.id));
    try {
      if (approve) {
        await _repo.approveAdmin(admin.id);
      } else {
        await _repo.rejectAdmin(admin.id);
      }
      if (!mounted) return;
      showSnack(
        context,
        approve
            ? t('adminAdminApprovedSuccess')
            : t('adminAdminRejectedSuccess'),
      );
      await reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(admin.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<PendingAdmin>>(
      load: _repo.pendingAdmins,
      isEmpty: (items) => items.isEmpty,
      emptyText: t('adminEmptyPendingAdmins'),
      emptyIcon: Icons.admin_panel_settings_outlined,
      builder: (context, admins, reload) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: admins.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final admin = admins[index];
            final isBusy = _busyIds.contains(admin.id);
            return _PendingAdminCard(
              admin: admin,
              isBusy: isBusy,
              onApprove: () => _handleAction(
                admin: admin,
                approve: true,
                reload: reload,
              ),
              onReject: () => _handleAction(
                admin: admin,
                approve: false,
                reload: reload,
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingAdminCard extends StatelessWidget {
  const _PendingAdminCard({
    required this.admin,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final PendingAdmin admin;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_add_alt_1_outlined,
                color: AppColors.govGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.fullName,
                      style: const TextStyle(
                        color: AppColors.govGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      admin.email,
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                admin.createdAt,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onApprove,
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(t('adminApproveAdminBtn')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(t('adminRejectAdminBtn')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
