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

class _HostServiceDeskTab extends StatefulWidget {
  const _HostServiceDeskTab();

  @override
  State<_HostServiceDeskTab> createState() => _HostServiceDeskTabState();
}

class _HostServiceDeskTabState extends State<_HostServiceDeskTab> {
  final _searchController = TextEditingController();
  IssuePriority? _priorityFilter;
  IssueStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<_IssueMeta> _loadIssueMeta(Issue issue) async {
    final flat = await BuildingService.instance.getFlatById(issue.flatId);
    final resident = await ResidentService.instance.getApprovedResidentForFlat(
      issue.flatId,
    );
    return _IssueMeta(
      flatNumber: flat?.flatNumber ?? issue.flatId,
      residentName: resident?.user.name,
      residentEmail: resident?.user.email,
    );
  }

  Future<void> _assignIssue(BuildContext context, Issue issue) async {
    final nameController = TextEditingController(text: issue.assigneeName ?? '');
    final phoneController = TextEditingController(
      text: issue.assigneePhone ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Assignee name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Assignee phone (optional)',
                ),
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
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    await IssueService.instance.assignIssue(
      issueId: issue.id,
      assigneeName: name,
      assigneePhone: phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
    );
  }

  Widget _buildIssueTile(BuildContext context, Issue issue) {
    return FutureBuilder<_IssueMeta>(
      future: _loadIssueMeta(issue),
      builder: (context, snapshot) {
        final meta = snapshot.data;
        final flatLabel = meta?.flatNumber ?? issue.flatId;
        final residentLabel = meta?.residentName ?? 'Resident';
        final subtitle = [
          residentLabel,
          'Flat $flatLabel',
          issue.priority.name,
          if (issue.assigneeName != null && issue.assigneeName!.isNotEmpty)
            'Assigned: ${issue.assigneeName}',
          if (issue.attachments.isNotEmpty)
            'Attachments: ${issue.attachments.length}',
        ].where((item) => item.isNotEmpty).join(' • ');
        return _IssueCard(
          title: issue.category,
          subtitle: subtitle,
          status: issue.status,
          priority: issue.priority,
          trailing: PopupMenuButton<_IssueAction>(
            onSelected: (action) {
              switch (action) {
                case _IssueAction.assign:
                  _assignIssue(context, issue);
                  break;
                case _IssueAction.inProgress:
                  IssueService.instance.updateStatus(
                    issue.id,
                    IssueStatus.inProgress,
                  );
                  break;
                case _IssueAction.resolve:
                  IssueService.instance.updateStatus(
                    issue.id,
                    IssueStatus.resolved,
                  );
                  break;
                case _IssueAction.close:
                  IssueService.instance.updateStatus(
                    issue.id,
                    IssueStatus.closed,
                  );
                  break;
                case _IssueAction.reopen:
                  IssueService.instance.updateStatus(
                    issue.id,
                    IssueStatus.open,
                  );
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: _IssueAction.assign,
                  child: Text('Assign'),
                ),
                if (issue.status != IssueStatus.inProgress &&
                    issue.status != IssueStatus.resolved &&
                    issue.status != IssueStatus.closed)
                  const PopupMenuItem(
                    value: _IssueAction.inProgress,
                    child: Text('Mark in progress'),
                  ),
                if (issue.status != IssueStatus.resolved)
                  const PopupMenuItem(
                    value: _IssueAction.resolve,
                    child: Text('Resolve'),
                  ),
                if (issue.status != IssueStatus.closed)
                  const PopupMenuItem(
                    value: _IssueAction.close,
                    child: Text('Close'),
                  ),
                if (issue.status == IssueStatus.resolved ||
                    issue.status == IssueStatus.closed)
                  const PopupMenuItem(
                    value: _IssueAction.reopen,
                    child: Text('Reopen'),
                  ),
              ];
            },
          ),
        );
      },
    );
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
            final issues = _filterIssues(stream.data ?? const <Issue>[]);
            final activeIssues = issues
                .where(
                  (issue) =>
                      issue.status == IssueStatus.open ||
                      issue.status == IssueStatus.inProgress,
                )
                .toList();
            final solvedIssues = issues
                .where(
                  (issue) =>
                      issue.status == IssueStatus.resolved ||
                      issue.status == IssueStatus.closed,
                )
                .toList();
            if (activeIssues.isEmpty && solvedIssues.isEmpty) {
              return const Center(child: Text('No tickets yet.'));
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SearchAndFilterBar(
                  searchController: _searchController,
                  priority: _priorityFilter,
                  status: _statusFilter,
                  onSearchChanged: (_) => setState(() {}),
                  onPriorityChanged: (value) {
                    setState(() => _priorityFilter = value);
                  },
                  onStatusChanged: (value) {
                    setState(() => _statusFilter = value);
                  },
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Active Tickets (${activeIssues.length})',
                ),
                const SizedBox(height: 12),
                if (activeIssues.isEmpty)
                  const _InfoTile(
                    title: 'All clear',
                    subtitle: 'No active tickets right now.',
                  )
                else
                  ...activeIssues.map((issue) => _buildIssueTile(context, issue)),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Solved Tickets (${solvedIssues.length})',
                ),
                const SizedBox(height: 12),
                if (solvedIssues.isEmpty)
                  const _InfoTile(
                    title: 'Nothing solved yet',
                    subtitle: 'Resolved tickets will show up here.',
                  )
                else
                  ...solvedIssues.map((issue) => _buildIssueTile(context, issue)),
              ],
            );
          },
        );
      },
    );
  }

  List<Issue> _filterIssues(List<Issue> issues) {
    final query = _searchController.text.trim().toLowerCase();
    return issues.where((issue) {
      if (_priorityFilter != null && issue.priority != _priorityFilter) {
        return false;
      }
      if (_statusFilter != null && issue.status != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack =
          '${issue.category} ${issue.description} ${issue.status.name}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }
}

class _IssueMeta {
  final String flatNumber;
  final String? residentName;
  final String? residentEmail;

  const _IssueMeta({
    required this.flatNumber,
    this.residentName,
    this.residentEmail,
  });
}

enum _IssueAction { assign, inProgress, resolve, close, reopen }

class _HostCommunityTab extends StatefulWidget {
  const _HostCommunityTab();

  @override
  State<_HostCommunityTab> createState() => _HostCommunityTabState();
}

class _HostCommunityTabState extends State<_HostCommunityTab> {
  final _controller = TextEditingController();
  bool _isSending = false;
  final List<_PendingMessage> _pending = [];

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
    final pendingMessage = _PendingMessage(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: profile.id,
      userName: profile.name,
      flatNumber: 'MGMT',
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _isSending = true;
      _pending.add(pendingMessage);
    });
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
      setState(() => _pending.removeWhere((item) => item.localId == pendingMessage.localId));
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
                    if (stream.hasError) {
                      return Center(
                        child: Text('Unable to load messages: ${stream.error}'),
                      );
                    }
                    final messages = stream.data ?? const <CommunityMessage>[];
                    _reconcilePending(messages, _pending);
                    final combined = _combineMessages(messages, _pending);
                    if (combined.isEmpty) {
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
                      itemCount: combined.length,
                      itemBuilder: (context, index) {
                        final message = combined[index];
                        final isMine =
                            currentUserId != null &&
                            message.userId == currentUserId;
                        final olderMessage = index + 1 < combined.length
                            ? combined[index + 1]
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
                          isPending: message.isPending,
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
                      child: const Icon(Icons.send_rounded),
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

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.searchController,
    required this.priority,
    required this.status,
    required this.onSearchChanged,
    required this.onPriorityChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final IssuePriority? priority;
  final IssueStatus? status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<IssuePriority?> onPriorityChanged;
  final ValueChanged<IssueStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search tickets...',
            filled: true,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DropdownButton<IssuePriority?>(
              value: priority,
              hint: const Text('Priority'),
              onChanged: onPriorityChanged,
              items: [
                const DropdownMenuItem<IssuePriority?>(
                  value: null,
                  child: Text('All priorities'),
                ),
                ...IssuePriority.values.map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.name),
                  ),
                ),
              ],
            ),
            DropdownButton<IssueStatus?>(
              value: status,
              hint: const Text('Status'),
              onChanged: onStatusChanged,
              items: [
                const DropdownMenuItem<IssueStatus?>(
                  value: null,
                  child: Text('All statuses'),
                ),
                ...IssueStatus.values.map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.name),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
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

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.priority,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IssueStatus status;
  final IssuePriority priority;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final statusLabel = status.name.toUpperCase();
    final statusColor = _statusColor(status);
    final priorityColor = _priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF9FBFF), Color(0xFFF1F5FF)],
        ),
        border: Border.all(color: const Color(0xFFDDE6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _TagChip(
                label: statusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Row(
            children: [
              _TagChip(
                label: priority.name.toUpperCase(),
                color: priorityColor,
              ),
              const Spacer(),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(IssueStatus status) {
  switch (status) {
    case IssueStatus.open:
      return const Color(0xFFDC2626);
    case IssueStatus.inProgress:
      return const Color(0xFF2563EB);
    case IssueStatus.resolved:
      return const Color(0xFF16A34A);
    case IssueStatus.closed:
      return const Color(0xFF6B7280);
  }
}

Color _priorityColor(IssuePriority priority) {
  switch (priority) {
    case IssuePriority.low:
      return const Color(0xFF0EA5E9);
    case IssuePriority.medium:
      return const Color(0xFFF59E0B);
    case IssuePriority.high:
      return const Color(0xFFEF4444);
    case IssuePriority.urgent:
      return const Color(0xFF7C3AED);
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
    required this.isPending,
  });

  final String author;
  final String flat;
  final String message;
  final DateTime? createdAt;
  final bool isMine;
  final bool isManagement;
  final bool showHeader;
  final bool isPending;

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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          Icon(
                            isPending ? Icons.schedule : Icons.check,
                            size: 12,
                            color: Colors.black54,
                          ),
                        ],
                      ],
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

class _PendingMessage {
  final String localId;
  final String userId;
  final String userName;
  final String flatNumber;
  final String content;
  final DateTime createdAt;

  const _PendingMessage({
    required this.localId,
    required this.userId,
    required this.userName,
    required this.flatNumber,
    required this.content,
    required this.createdAt,
  });
}

class _ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String flatNumber;
  final String content;
  final DateTime? createdAt;
  final bool isPending;

  const _ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.flatNumber,
    required this.content,
    required this.createdAt,
    required this.isPending,
  });
}

void _reconcilePending(
  List<CommunityMessage> messages,
  List<_PendingMessage> pending,
) {
  if (pending.isEmpty) return;
  final toRemove = <String>{};
  for (final candidate in pending) {
    final match = messages.any((message) {
      if (message.userId != candidate.userId) return false;
      if (message.content != candidate.content) return false;
      if (message.flatNumber != candidate.flatNumber) return false;
      final createdAt = message.createdAt;
      if (createdAt == null) return false;
      final diff = createdAt.difference(candidate.createdAt).inSeconds.abs();
      return diff <= 90;
    });
    if (match) {
      toRemove.add(candidate.localId);
    }
  }
  if (toRemove.isEmpty) return;
  pending.removeWhere((item) => toRemove.contains(item.localId));
}

List<_ChatMessage> _combineMessages(
  List<CommunityMessage> messages,
  List<_PendingMessage> pending,
) {
  final combined = <_ChatMessage>[
    ...messages.map(
      (message) => _ChatMessage(
        id: message.id,
        userId: message.userId,
        userName: message.userName,
        flatNumber: message.flatNumber,
        content: message.content,
        createdAt: message.createdAt,
        isPending: false,
      ),
    ),
    ...pending.map(
      (message) => _ChatMessage(
        id: message.localId,
        userId: message.userId,
        userName: message.userName,
        flatNumber: message.flatNumber,
        content: message.content,
        createdAt: message.createdAt,
        isPending: true,
      ),
    ),
  ];
  combined.sort((a, b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  return combined;
}

String _formatMessageTime(DateTime? value) {
  if (value == null) return '';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _currency(double value) => 'Rs ${value.toStringAsFixed(0)}';
