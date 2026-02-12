import 'package:flutter/material.dart';

import '../../models/community_message.dart';
import '../../models/enums.dart';
import '../../models/flat.dart';
import '../../models/issue.dart';
import '../../models/resident_link.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/building_service.dart';
import '../../services/community_service.dart';
import '../../services/issue_service.dart';
import '../../services/payment_service.dart';
import '../../services/resident_service.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  int _index = 0;

  final _pages = const [
    _ResidentHomeTab(),
    _ResidentAssetsTab(),
    _ResidentServiceTab(),
    _ResidentCommunityTab(),
    _ResidentSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resident Portal'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
          ],
        ),
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(icon: Icon(Icons.grid_view), label: 'Unit'),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              label: 'Service',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              label: 'Community',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidentHomeTab extends StatelessWidget {
  const _ResidentHomeTab();

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      return const Center(child: Text('Please login first.'));
    }
    return FutureBuilder<double>(
      future: PaymentService.instance.getBalanceDueForResident(userId),
      builder: (context, dueSnapshot) {
        final balanceDue = dueSnapshot.data ?? 0;
        return FutureBuilder<double>(
          future: PaymentService.instance.getRentDueForResident(userId),
          builder: (context, rentSnapshot) {
            final rentDue = rentSnapshot.data ?? 0;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A3DFF), Color(0xFF0030D0)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Balance Due',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currency(balanceDue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _InfoTile(title: 'Rent', subtitle: '${_currency(rentDue)} due'),
                const Text(
                  'Notices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const _InfoTile(
                  title: 'Water shutdown',
                  subtitle: 'Tomorrow 10:00 AM',
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ResidentAssetsTab extends StatelessWidget {
  const _ResidentAssetsTab();

  Future<ResidentLink?> _resolveLink() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return null;
    return ResidentService.instance.getLinkForUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResidentLink?>(
      future: _resolveLink(),
      builder: (context, linkSnapshot) {
        final link = linkSnapshot.data;
        if (linkSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (link == null) {
          return const Center(child: Text('No building linked yet.'));
        }
        return FutureBuilder<Flat?>(
          future: BuildingService.instance.getFlatById(link.flatId),
          builder: (context, flatSnapshot) {
            final flat = flatSnapshot.data;
            if (flatSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (flat == null) {
              return const Center(child: Text('Unit information unavailable.'));
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'My Unit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  title: 'Unit ${flat.flatNumber}',
                  subtitle: flat.status == FlatStatus.occupied
                      ? 'Occupied'
                      : 'Pending occupancy',
                ),
                _InfoTile(
                  title: 'Rent',
                  subtitle: '${_currency(flat.rentAmount)} configured',
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ResidentServiceTab extends StatefulWidget {
  const _ResidentServiceTab();

  @override
  State<_ResidentServiceTab> createState() => _ResidentServiceTabState();
}

class _ResidentServiceTabState extends State<_ResidentServiceTab> {
  Future<String?> _resolveUserId() async {
    return AuthService.instance.currentUserId;
  }

  Future<void> _createTicket(
    BuildContext context,
    String buildingId,
    String flatId,
    String userId,
  ) async {
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    IssuePriority priority = IssuePriority.medium;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Ticket'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<IssuePriority>(
                    value: priority,
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => priority = value);
                    },
                    items: IssuePriority.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) return;
    if (categoryController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category and description are required.')),
      );
      return;
    }
    await IssueService.instance.createIssue(
      residentId: userId,
      buildingId: buildingId,
      flatId: flatId,
      category: categoryController.text.trim(),
      description: descriptionController.text.trim(),
      priority: priority,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveUserId(),
      builder: (context, snapshot) {
        final userId = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userId == null) {
          return const Center(child: Text('Please login first.'));
        }
        return FutureBuilder<ResidentLink?>(
          future: ResidentService.instance.getLinkForUser(userId),
          builder: (context, linkSnapshot) {
            if (linkSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final link = linkSnapshot.data;
            if (link == null) {
              return const Center(child: Text('No building linked yet.'));
            }
            return Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Issue>>(
                    stream: IssueService.instance.streamIssuesForResident(
                      userId,
                    ),
                    builder: (context, stream) {
                      if (stream.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final issues = stream.data ?? const <Issue>[];
                      if (issues.isEmpty) {
                        return const Center(child: Text('No tickets yet.'));
                      }
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const Text(
                            'My Tickets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...issues.map((issue) {
                            return _InfoTile(
                              title: issue.category,
                              subtitle: issue.status.name,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: () => _createTicket(
                        context,
                        link.buildingId,
                        link.flatId,
                        userId,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('New Ticket'),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ResidentCommunityTab extends StatefulWidget {
  const _ResidentCommunityTab();

  @override
  State<_ResidentCommunityTab> createState() => _ResidentCommunityTabState();
}

class _ResidentCommunityTabState extends State<_ResidentCommunityTab> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String buildingId, String flatNumber) async {
    if (_isSending) return;
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await CommunityService.instance.sendMessage(
        buildingId: buildingId,
        userId: profile.id,
        userName: profile.name,
        flatNumber: flatNumber,
        content: text,
      );
      if (!mounted) return;
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Message send failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      return const Center(child: Text('Please login first.'));
    }

    return FutureBuilder<ResidentLink?>(
      future: ResidentService.instance.getLinkForUser(userId),
      builder: (context, linkSnapshot) {
        if (linkSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final link = linkSnapshot.data;
        if (link == null) {
          return const Center(child: Text('No building linked yet.'));
        }
        return FutureBuilder<Flat?>(
          future: BuildingService.instance.getFlatById(link.flatId),
          builder: (context, flatSnapshot) {
            if (flatSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final flat = flatSnapshot.data;
            if (flat == null) {
              return const Center(child: Text('Unit information unavailable.'));
            }
            final currentUserId = AuthService.instance.currentUserId;
            return Column(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFEAF2FF), Color(0xFFF7FAFF)],
                      ),
                    ),
                    child: StreamBuilder<List<CommunityMessage>>(
                      stream: CommunityService.instance.streamMessages(
                        link.buildingId,
                      ),
                      builder: (context, stream) {
                        if (stream.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (stream.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load messages: ${stream.error}',
                            ),
                          );
                        }
                        final messages =
                            stream.data ?? const <CommunityMessage>[];
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet. Start the group chat.',
                            ),
                          );
                        }
                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMine =
                                currentUserId != null &&
                                message.userId == currentUserId;
                            final olderMessage = index + 1 < messages.length
                                ? messages[index + 1]
                                : null;
                            final showHeader =
                                olderMessage == null ||
                                olderMessage.userId != message.userId;
                            return _MessageBubble(
                              author: message.userName,
                              flat: message.flatNumber,
                              message: message.content,
                              createdAt: message.createdAt,
                              isMine: isMine,
                              isManagement: message.flatNumber == 'MGMT',
                              showHeader: showHeader,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE5EAF3))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) =>
                                _sendMessage(link.buildingId, flat.flatNumber),
                            decoration: InputDecoration(
                              hintText: 'Message group...',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF2F6FF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _isSending
                              ? null
                              : () => _sendMessage(
                                  link.buildingId,
                                  flat.flatNumber,
                                ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            padding: EdgeInsets.zero,
                            backgroundColor: const Color(0xFF0A3DFF),
                            shape: const CircleBorder(),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ResidentSettingsTab extends StatelessWidget {
  const _ResidentSettingsTab();

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authChoice, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          title: 'Profile & Security',
          subtitle: 'Password, vacate, help',
          icon: Icons.person_outline,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
        ),
        _SettingsTile(
          title: 'Logout',
          subtitle: 'Sign out of this device',
          icon: Icons.logout,
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0A3DFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.author,
    required this.flat,
    required this.message,
    required this.createdAt,
    required this.isMine,
    required this.isManagement,
    required this.showHeader,
  });

  final String author;
  final String flat;
  final String message;
  final DateTime? createdAt;
  final bool isMine;
  final bool isManagement;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final headerColor = isManagement
        ? const Color(0xFF0A3DFF)
        : const Color(0xFF1F2937);
    final bubbleColor = isMine ? const Color(0xFFDCEBFF) : Colors.white;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Column(
          crossAxisAlignment: align,
          children: [
            if (showHeader)
              Padding(
                padding: EdgeInsets.only(
                  left: isMine ? 0 : 12,
                  right: isMine ? 12 : 0,
                  top: 8,
                  bottom: 4,
                ),
                child: Text(
                  isMine ? 'You' : '$author - $flat',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: headerColor,
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: radius,
                  border: Border.all(color: const Color(0xFFD7DFEC)),
                ),
                child: Column(
                  crossAxisAlignment: align,
                  children: [
                    Text(message),
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatMessageTime(DateTime? value) {
  if (value == null) return '';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _currency(double value) => 'Rs ${value.toStringAsFixed(0)}';
