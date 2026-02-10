import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../models/enums.dart';
import '../../services/auth_service.dart';
import '../../services/building_service.dart';
import '../../services/community_service.dart';
import '../../services/issue_service.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  int _index = 0;

  final _pages = const [
    _HostHomeTab(),
    _HostAssetsTab(),
    _HostServiceDeskTab(),
    _HostCommunityTab(),
    _HostSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Host Dashboard'),
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

class _HostHomeTab extends StatelessWidget {
  const _HostHomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _HeroMetricCard(
          title: 'Total Revenue',
          value: '₹ 0',
          subtitle: 'All time collections',
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Open Tickets'),
        const SizedBox(height: 8),
        _InfoTile(title: 'Leaking Pipe', subtitle: 'Flat B-2 • High priority'),
        _InfoTile(title: 'AC Not Cooling', subtitle: 'Flat A-3 • Medium priority'),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Invite Code'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.copy),
          label: const Text('Copy Invite Code'),
        ),
      ],
    );
  }
}

class _HostAssetsTab extends StatelessWidget {
  const _HostAssetsTab();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isOccupied = index.isEven;
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: isOccupied ? const Color(0xFFE6F4FF) : const Color(0xFFFFF4E6),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unit A-${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(isOccupied ? 'Occupied' : 'Vacant'),
                const Spacer(),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HostServiceDeskTab extends StatelessWidget {
  const _HostServiceDeskTab();

  Future<String?> _resolveBuildingId() async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return null;
    if (profile.buildingId != null && profile.buildingId!.isNotEmpty) return profile.buildingId;
    final building = await BuildingService.instance.getBuildingForHost(profile.id);
    return building?.id;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveBuildingId(),
      builder: (context, snapshot) {
        final buildingId = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (buildingId == null) {
          return const Center(child: Text('No building found yet.'));
        }
        return StreamBuilder(
          stream: IssueService.instance.streamIssuesForBuilding(buildingId),
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
                _SectionHeader(title: 'Service Desk'),
                const SizedBox(height: 12),
                ...issues.map((issue) {
                  return _InfoTile(
                    title: issue.category,
                    subtitle: 'Flat ${issue.flatId} • ${issue.status.name}',
                    trailing: issue.status == IssueStatus.open
                        ? TextButton(
                            onPressed: () => IssueService.instance.updateStatus(issue.id, IssueStatus.resolved),
                            child: const Text('Resolve'),
                          )
                        : null,
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _HostCommunityTab extends StatefulWidget {
  const _HostCommunityTab();

  @override
  State<_HostCommunityTab> createState() => _HostCommunityTabState();
}

class _HostCommunityTabState extends State<_HostCommunityTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _resolveBuildingId() async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return null;
    if (profile.buildingId != null && profile.buildingId!.isNotEmpty) return profile.buildingId;
    final building = await BuildingService.instance.getBuildingForHost(profile.id);
    return building?.id;
  }

  Future<void> _sendMessage(String buildingId) async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await CommunityService.instance.sendMessage(
      buildingId: buildingId,
      userId: profile.id,
      userName: profile.name,
      flatNumber: 'MGMT',
      content: text,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveBuildingId(),
      builder: (context, snapshot) {
        final buildingId = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (buildingId == null) {
          return const Center(child: Text('No building found yet.'));
        }
        return Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: CommunityService.instance.streamMessages(buildingId),
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
                      onPressed: () => _sendMessage(buildingId),
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

class _HostSettingsTab extends StatelessWidget {
  const _HostSettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _SettingsTile(
          title: 'Profile & Security',
          subtitle: 'Password, vacate, admin',
          icon: Icons.person_outline,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
        ),
        _SettingsTile(
          title: 'Admin Console',
          subtitle: 'Developer tools',
          icon: Icons.admin_panel_settings_outlined,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminConsole),
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

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      child: Row(
        children: [
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
          ?trailing,
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
