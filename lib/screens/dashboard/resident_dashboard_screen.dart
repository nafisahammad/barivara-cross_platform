import 'package:flutter/material.dart';

import '../../models/building.dart';
import '../../models/community_message.dart';
import '../../models/enums.dart';
import '../../models/flat.dart';
import '../../models/issue.dart';
import '../../models/issue_templates.dart';
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

  Future<void> _requestPayment(
    BuildContext context,
    ResidentLink link,
  ) async {
    final amountController = TextEditingController();
    PaymentCategory category = PaymentCategory.rent;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Request payment approval'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount paid',
                      hintText: 'e.g. 15000',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentCategory>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: PaymentCategory.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_paymentCategoryLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => category = value);
                    },
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
                  child: const Text('Send request'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }

    try {
      await PaymentService.instance.createPaymentRequest(
        residentId: link.userId,
        buildingId: link.buildingId,
        flatId: link.flatId,
        amount: amount,
        category: category,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment request sent for approval.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
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
            return FutureBuilder<Building?>(
              future: BuildingService.instance.getBuildingById(link.buildingId),
              builder: (context, buildingSnapshot) {
                if (buildingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final building = buildingSnapshot.data;
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _UnitHeaderCard(
                      flatNumber: flat.flatNumber,
                      status: flat.status,
                      buildingName: building?.name,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Overview'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatCard(
                          label: 'Floor',
                          value: 'Level ${flat.floor}',
                        ),
                        _StatCard(
                          label: 'Rent',
                          value: _currency(flat.rentAmount),
                        ),
                        _StatCard(
                          label: 'Approval',
                          value: _approvalLabel(link.approvalStatus),
                        ),
                        _StatCard(
                          label: 'Linked',
                          value: _formatDate(link.createdAt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Unit Details'),
                    const SizedBox(height: 12),
                    _InfoTile(
                      title: 'Status',
                      subtitle: _flatStatusLabel(flat.status),
                    ),
                    if (building != null)
                      _InfoTile(
                        title: 'Building',
                        subtitle: building.name,
                      ),
                    if (building != null && building.address.isNotEmpty)
                      _InfoTile(
                        title: 'Address',
                        subtitle: building.address,
                      ),
                    if (building == null)
                      const _InfoTile(
                        title: 'Building',
                        subtitle: 'Building details unavailable.',
                      ),
                    if ((building?.rules ?? const []).isNotEmpty)
                      _RulesCard(rules: building!.rules),
                    if ((building?.rules ?? const []).isEmpty)
                      const _InfoTile(
                        title: 'House Rules',
                        subtitle: 'No rules added yet.',
                      ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Payments'),
                    const SizedBox(height: 12),
                    _InfoTile(
                      title: 'Send payment request',
                      subtitle:
                          'Submit a paid amount for host approval and confirmation.',
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _requestPayment(context, link),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Request payment approval'),
                      ),
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

class _ResidentServiceTab extends StatefulWidget {
  const _ResidentServiceTab();

  @override
  State<_ResidentServiceTab> createState() => _ResidentServiceTabState();
}

class _ResidentServiceTabState extends State<_ResidentServiceTab> {
  final _searchController = TextEditingController();
  IssuePriority? _priorityFilter;
  IssueStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _resolveUserId() async {
    return AuthService.instance.currentUserId;
  }

  Future<void> _createTicket(
    BuildContext context,
    String buildingId,
    String flatId,
    String userId,
  ) async {
    final descriptionController = TextEditingController();
    final attachmentsController = TextEditingController();
    IssuePriority priority = IssuePriority.medium;
    String category = kIssueCategories.first;

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
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: kIssueCategories
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => category = value);
                    },
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      helperText: kIssueCategoryHints[category],
                    ),
                  ),
                  TextField(
                    controller: attachmentsController,
                    decoration: const InputDecoration(
                      labelText: 'Attachment links (optional)',
                      helperText: 'Paste URLs separated by commas or new lines.',
                    ),
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
    if (category.trim().isEmpty || descriptionController.text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category and description are required.')),
      );
      return;
    }
    final attachments = attachmentsController.text
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    await IssueService.instance.createIssue(
      residentId: userId,
      buildingId: buildingId,
      flatId: flatId,
      category: category.trim(),
      description: descriptionController.text.trim(),
      priority: priority,
      attachments: attachments,
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
                      final filtered = _filterIssues(issues);
                      if (filtered.isEmpty) {
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
                          const SizedBox(height: 12),
                          ...filtered.map((issue) {
                            return _IssueTile(
                              issue: issue,
                              showAssignee: true,
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
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
                              fillColor:
                                  Theme.of(context).colorScheme.surfaceContainerHighest,
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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

  void _showPlaceholder(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            message ?? 'This setting will be available in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

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
          title: 'Profile Details',
          subtitle: 'Name, phone, unit info',
          icon: Icons.person_outline,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
        ),
        _SettingsTile(
          title: 'Notification Preferences',
          subtitle: 'Tickets, payments, announcements',
          icon: Icons.notifications_outlined,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.notificationPreferences),
        ),
        _SettingsTile(
          title: 'Privacy & Security',
          subtitle: 'Change password, manage sessions',
          icon: Icons.lock_outline,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.privacySecurity),
        ),
        _SettingsTile(
          title: 'Language & Region',
          subtitle: 'Locale, currency, time format',
          icon: Icons.language_outlined,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.languageRegion),
        ),
        _SettingsTile(
          title: 'Payment Methods',
          subtitle: 'Add or update payment methods',
          icon: Icons.credit_card_outlined,
          onTap: () => _showPlaceholder(
            context,
            title: 'Payment Methods',
            message: 'Payment method management is coming soon.',
          ),
        ),
        _SettingsTile(
          title: 'App Appearance',
          subtitle: 'Theme, text size, layout density',
          icon: Icons.palette_outlined,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.appAppearance),
        ),
        _SettingsTile(
          title: 'Support',
          subtitle: 'Help center, contact admin',
          icon: Icons.support_agent_outlined,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.support),
        ),
        _SettingsTile(
          title: 'Data Export',
          subtitle: 'Download receipts or ticket history',
          icon: Icons.download_outlined,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.dataExport),
        ),
        _SettingsTile(
          title: 'Emergency Contacts',
          subtitle: 'Update emergency contact list',
          icon: Icons.contact_phone_outlined,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.emergencyContacts),
        ),
        _SettingsTile(
          title: 'App Info',
          subtitle: 'Version, terms, privacy policy',
          icon: Icons.info_outline,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.appInfo),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _UnitHeaderCard extends StatelessWidget {
  const _UnitHeaderCard({
    required this.flatNumber,
    required this.status,
    this.buildingName,
  });

  final String flatNumber;
  final FlatStatus status;
  final String? buildingName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusLabel = _flatStatusLabel(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unit $flatNumber',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  buildingName ?? 'Resident building',
                  style: TextStyle(
                    color: scheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surface,
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.rules});

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'House Rules',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('- $rule'),
            ),
          ),
        ],
      ),
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

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue, this.showAssignee = false});

  final Issue issue;
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = <String>[
      'Status: ${issue.status.name}',
      'Priority: ${issue.priority.name}',
      if (issue.assigneeName != null && issue.assigneeName!.isNotEmpty)
        'Assigned: ${issue.assigneeName}',
      _slaLabel(issue),
    ].where((value) => value.isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(issue.category, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(issue.description),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (issue.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Attachments: ${issue.attachments.length}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

String _slaLabel(Issue issue) {
  final due = issue.slaDueAt;
  if (due == null) return '';
  final now = DateTime.now();
  final diff = due.difference(now);
  if (diff.isNegative) {
    final overdue = diff.abs();
    return 'Overdue by ${_formatDuration(overdue)}';
  }
  return 'SLA ${_formatDuration(diff)} left';
}

String _formatDuration(Duration value) {
  if (value.inDays >= 1) {
    return '${value.inDays}d';
  }
  if (value.inHours >= 1) {
    return '${value.inHours}h';
  }
  return '${value.inMinutes}m';
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: scheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
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
                  Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
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
    final scheme = Theme.of(context).colorScheme;
    final headerColor = isManagement ? scheme.primary : scheme.onSurface;
    final bubbleColor = isMine ? scheme.primaryContainer : scheme.surface;
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
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: align,
                  children: [
                    Text(message),
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
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

String _formatDate(DateTime? value) {
  if (value == null) return 'Not linked';
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
  final month = months[value.month - 1];
  return '${value.day} $month ${value.year}';
}

String _approvalLabel(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.approved:
      return 'Approved';
    case ApprovalStatus.pending:
      return 'Pending';
  }
}

String _flatStatusLabel(FlatStatus status) {
  switch (status) {
    case FlatStatus.occupied:
      return 'Occupied';
    case FlatStatus.vacant:
      return 'Vacant';
  }
}

String _paymentCategoryLabel(PaymentCategory category) {
  switch (category) {
    case PaymentCategory.rent:
      return 'Rent';
    case PaymentCategory.electricity:
      return 'Electricity';
    case PaymentCategory.water:
      return 'Water';
    case PaymentCategory.gas:
      return 'Gas';
    case PaymentCategory.other:
      return 'Other';
  }
}

String _currency(double value) => 'Rs ${value.toStringAsFixed(0)}';
