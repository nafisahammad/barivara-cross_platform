import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/building.dart';
import '../../models/community_message.dart';
import '../../models/enums.dart';
import '../../models/flat.dart';
import '../../models/issue.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/building_service.dart';
import '../../services/community_service.dart';
import '../../services/issue_service.dart';
import '../../services/payment_service.dart';
import '../../services/resident_service.dart';
import 'unit_console_screen.dart';

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
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Host Portal'),
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
            NavigationDestination(icon: Icon(Icons.grid_view), label: 'Assets'),
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

class _HostHomeTab extends StatelessWidget {
  const _HostHomeTab();

  Future<Building?> _resolveBuilding() async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return null;
    return BuildingService.instance.getBuildingForHost(profile.id);
  }

  Future<void> _copyInviteCode(BuildContext context, String inviteCode) async {
    await Clipboard.setData(ClipboardData(text: inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invite code copied: $inviteCode')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Building?>(
      future: _resolveBuilding(),
      builder: (context, snapshot) {
        final building = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (building == null) {
          return const Center(child: Text('No building found yet.'));
        }
        return FutureBuilder<double>(
          future: PaymentService.instance.getTotalRevenueForBuilding(
            building.id,
          ),
          builder: (context, revenueSnapshot) {
            final revenue = revenueSnapshot.data ?? 0;
            return StreamBuilder<List<Issue>>(
              stream: IssueService.instance.streamIssuesForBuilding(
                building.id,
              ),
              builder: (context, issueSnapshot) {
                final openIssues = (issueSnapshot.data ?? const <Issue>[])
                    .where(
                      (issue) =>
                          issue.status == IssueStatus.open ||
                          issue.status == IssueStatus.inProgress,
                    )
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _HeroMetricCard(
                      title: 'Total Revenue',
                      value: _currency(revenue),
                      subtitle: 'Confirmed collections',
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Open Tickets (${openIssues.length})',
                    ),
                    const SizedBox(height: 8),
                    if (openIssues.isEmpty)
                      const _InfoTile(
                        title: 'All clear',
                        subtitle: 'No open service tickets',
                      )
                    else
                      ...openIssues
                          .take(4)
                          .map(
                            (issue) => _InfoTile(
                              title: issue.category,
                              subtitle:
                                  'Flat ${issue.flatId} - ${issue.priority.name}',
                            ),
                          ),
                    const SizedBox(height: 16),
                    const _SectionHeader(title: 'Invite Code'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _copyInviteCode(context, building.inviteCode),
                      icon: const Icon(Icons.copy),
                      label: Text('Copy ${building.inviteCode}'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HostAssetsTab extends StatefulWidget {
  const _HostAssetsTab();

  @override
  State<_HostAssetsTab> createState() => _HostAssetsTabState();
}

class _HostAssetsTabState extends State<_HostAssetsTab> {
  int _reloadKey = 0;

  Future<Building?> _resolveBuilding() async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) return null;
    return BuildingService.instance.getBuildingForHost(profile.id);
  }

  Future<_HostAssetsData> _loadAssetsData(String buildingId) async {
    final flats = await BuildingService.instance.getFlatsForBuilding(
      buildingId,
    );
    final pendingRequests = await ResidentService.instance
        .getPendingRequestsForBuilding(buildingId);
    return _HostAssetsData(flats: flats, pendingRequests: pendingRequests);
  }

  Future<void> _approveRequest(PendingAccessRequest request) async {
    try {
      await ResidentService.instance.approveAccessRequest(request.link);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${request.residentName}.')),
      );
      setState(() => _reloadKey++);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _declineRequest(PendingAccessRequest request) async {
    try {
      await ResidentService.instance.declineAccessRequest(request.link);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Declined ${request.residentName}.')),
      );
      setState(() => _reloadKey++);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openUnitConsole(Flat flat) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UnitConsoleScreen(flat: flat)),
    );
    if (changed == true) {
      setState(() => _reloadKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Building?>(
      future: _resolveBuilding(),
      builder: (context, buildingSnapshot) {
        final building = buildingSnapshot.data;
        if (buildingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (building == null) {
          return const Center(child: Text('No building found yet.'));
        }
        return FutureBuilder<_HostAssetsData>(
          key: ValueKey(_reloadKey),
          future: _loadAssetsData(building.id),
          builder: (context, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = dataSnapshot.data;
            if (data == null) {
              return const Center(child: Text('Unable to load assets.'));
            }
            final flats = data.flats;
            final pendingRequests = data.pendingRequests;
            if (flats.isEmpty) {
              return const Center(child: Text('No units found.'));
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SectionHeader(
                  title: 'Pending Requests (${pendingRequests.length})',
                ),
                const SizedBox(height: 8),
                if (pendingRequests.isEmpty)
                  const _InfoTile(
                    title: 'No pending requests',
                    subtitle: 'New resident requests will appear here.',
                  )
                else
                  ...pendingRequests.map(
                    (request) => _InfoTile(
                      title: request.residentName,
                      subtitle:
                          '${request.flatNumber} - ${request.residentEmail}',
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _declineRequest(request),
                            child: const Text('Decline'),
                          ),
                          FilledButton(
                            onPressed: () => _approveRequest(request),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Units'),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: flats.length,
                  itemBuilder: (context, index) {
                    final flat = flats[index];
                    final isOccupied = flat.status == FlatStatus.occupied;
                    return InkWell(
                      onTap: () => _openUnitConsole(flat),
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: isOccupied
                              ? const Color(0xFFE6F4FF)
                              : const Color(0xFFFFF4E6),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    flat.flatNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _openUnitConsole(flat),
                                  icon: const Icon(Icons.settings_outlined),
                                  tooltip: 'Unit settings',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(isOccupied ? 'Occupied' : 'Vacant'),
                            const Spacer(),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [Icon(Icons.chevron_right)],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HostAssetsData {
  final List<Flat> flats;
  final List<PendingAccessRequest> pendingRequests;

  const _HostAssetsData({required this.flats, required this.pendingRequests});
}

class _HostServiceDeskTab extends StatelessWidget {
  const _HostServiceDeskTab();

  Future<String?> _resolveBuildingId() async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) {
      return null;
    }
    if (profile.buildingId != null && profile.buildingId!.isNotEmpty) {
      return profile.buildingId;
    }
    final building = await BuildingService.instance.getBuildingForHost(
      profile.id,
    );
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
        return StreamBuilder<List<Issue>>(
          stream: IssueService.instance.streamIssuesForBuilding(buildingId),
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
                const _SectionHeader(title: 'Service Desk'),
                const SizedBox(height: 12),
                ...issues.map((issue) {
                  return _InfoTile(
                    title: issue.category,
                    subtitle: 'Flat ${issue.flatId} - ${issue.status.name}',
                    trailing: issue.status == IssueStatus.open
                        ? TextButton(
                            onPressed: () => IssueService.instance.updateStatus(
                              issue.id,
                              IssueStatus.resolved,
                            ),
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
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _resolveBuildingId() async {
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) {
      return null;
    }
    if (profile.buildingId != null && profile.buildingId!.isNotEmpty) {
      return profile.buildingId;
    }
    final building = await BuildingService.instance.getBuildingForHost(
      profile.id,
    );
    return building?.id;
  }

  Future<void> _sendMessage(String buildingId) async {
    if (_isSending) return;
    final profile = await AuthService.instance.getCurrentProfile();
    if (profile == null) {
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _isSending = true);
    try {
      await CommunityService.instance.sendMessage(
        buildingId: buildingId,
        userId: profile.id,
        userName: profile.name,
        flatNumber: 'MGMT',
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
                  stream: CommunityService.instance.streamMessages(buildingId),
                  builder: (context, stream) {
                    if (stream.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (stream.hasError) {
                      return Center(
                        child: Text('Unable to load messages: ${stream.error}'),
                      );
                    }
                    final messages = stream.data ?? const <CommunityMessage>[];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('No messages yet. Start the group chat.'),
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
                        onSubmitted: (_) => _sendMessage(buildingId),
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
                          : () => _sendMessage(buildingId),
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
  }
}

class _HostSettingsTab extends StatelessWidget {
  const _HostSettingsTab();

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
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
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
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
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
