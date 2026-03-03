import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please login first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream:
                NotificationService.instance.streamNotificationsForUser(userId),
            builder: (context, snapshot) {
              final unreadCount = (snapshot.data ?? const <AppNotification>[])
                  .where((item) => !item.read)
                  .length;
              return IconButton(
                tooltip: 'Mark all as read',
                onPressed: unreadCount == 0
                    ? null
                    : () async {
                        await NotificationService.instance
                            .markAllReadForUser(userId);
                      },
                icon: const Icon(Icons.done_all),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.instance.streamNotificationsForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const _EmptyState(
              title: 'No notifications yet.',
              body: 'You will see updates about your account here.',
            );
          }

          final unreadCount =
              notifications.where((item) => !item.read).length;
          final filtered = _showUnreadOnly
              ? notifications.where((item) => !item.read).toList()
              : notifications;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _NotificationHeader(
                  unreadCount: unreadCount,
                  showUnreadOnly: _showUnreadOnly,
                  onFilterChanged: (value) {
                    setState(() => _showUnreadOnly = value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        title: 'No unread notifications.',
                        body: 'Switch to all to see older updates.',
                        actionLabel: 'Show all',
                        onAction: () {
                          setState(() => _showUnreadOnly = false);
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _NotificationCard(
                            notification: item,
                            onTap: () async {
                              if (!item.read) {
                                await NotificationService.instance
                                    .markRead(item.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;
    final colorScheme = theme.colorScheme;
    final surfaceColor = isUnread
        ? colorScheme.primaryContainer.withOpacity(0.35)
        : colorScheme.surface;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: isUnread
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (notification.createdAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({
    required this.unreadCount,
    required this.showUnreadOnly,
    required this.onFilterChanged,
  });

  final int unreadCount;
  final bool showUnreadOnly;
  final ValueChanged<bool> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unread notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unreadCount == 0
                      ? 'You are all caught up.'
                      : '$unreadCount unread message${unreadCount == 1 ? '' : 's'}.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: !showUnreadOnly,
                onSelected: (_) => onFilterChanged(false),
              ),
              const SizedBox(height: 8),
              ChoiceChip(
                label: const Text('Unread'),
                selected: showUnreadOnly,
                onSelected: (_) => onFilterChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none,
                size: 54, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} • $hour:$minute $ampm';
}
