import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../models/enums.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/issue_service.dart';
import '../../services/resident_service.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() => _ResidentDashboardScreenState();
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resident Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
          ],
        ),
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.grid_view), label: 'Assets'),
            NavigationDestination(icon: Icon(Icons.build_outlined), label: 'Service'),
            NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Community'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance Due', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('₹ 0', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Notices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _InfoTile(title: 'Water shutdown', subtitle: 'Tomorrow 10:00 AM'),
      ],
    );
  }
}

class _ResidentAssetsTab extends StatelessWidget {
  const _ResidentAssetsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('My Unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _InfoTile(title: 'Unit A-3', subtitle: 'Occupied • Lease active'),
        _InfoTile(title: 'Rent', subtitle: '₹ 0 due'),
      ],
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

  Future<void> _createTicket(BuildContext context, String buildingId, String flatId, String userId) async {
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    IssuePriority priority = IssuePriority.medium;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              DropdownButton<IssuePriority>(
                value: priority,
                onChanged: (value) {
                  if (value == null) return;
                  priority = value;
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
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Create')),
          ],
        );
      },
    );

    if (created != true) return;
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
        return FutureBuilder(
          future: ResidentService.instance.getLinkForUser(userId),
          builder: (context, AsyncSnapshot<dynamic> linkSnapshot) {
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
                  child: StreamBuilder(
                    stream: IssueService.instance.streamIssuesForResident(userId),
                    builder: (context, AsyncSnapshot<List<dynamic>> stream) {
                      if (stream.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final issues = stream.data?.cast<dynamic>() ?? [];
                      if (issues.isEmpty) {
                        return const Center(child: Text('No tickets yet.'));
                      }
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const Text('My Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                      onPressed: () => _createTicket(context, link.buildingId, link.flatId, userId),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String buildingId, String flatNumber) async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await CommunityService.instance.sendMessage(
      buildingId: buildingId,
      userId: profile.id,
      userName: profile.name,
      flatNumber: flatNumber,
      content: text,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      return const Center(child: Text('Please login first.'));
    }

    return FutureBuilder(
      future: ResidentService.instance.getLinkForUser(userId),
      builder: (context, AsyncSnapshot<dynamic> linkSnapshot) {
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
              child: StreamBuilder(
                stream: CommunityService.instance.streamMessages(link.buildingId),
                builder: (context, AsyncSnapshot<List<dynamic>> stream) {
                  if (stream.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = stream.data?.cast<dynamic>() ?? [];
                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        author: message.userName,
                        flat: message.flatNumber,
                        message: message.content,
                        isHost: message.userName == 'MGMT',
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(hintText: 'Write a message...'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _sendMessage(link.buildingId, link.flatId),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(56, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResidentSettingsTab extends StatelessWidget {
  const _ResidentSettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
          onTap: () {},
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
    required this.isHost,
  });

  final String author;
  final String flat;
  final String message;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isHost ? const Color(0xFFE6F4FF) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$author • $flat',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isHost ? const Color(0xFF0A3DFF) : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}
