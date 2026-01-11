import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_conversation.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

/// Screen showing list of all chat conversations for the user.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  static const route = '/conversations';

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _authService = AuthService();
  List<ChatConversation> _conversations = [];
  List<UserModel> _pharmacists = [];
  bool _isLoading = true;
  String _userRole = 'patient';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _userRole = user.role;
    }

    final conversations = await _authService.getUserConversations();
    
    // Load pharmacists for patients to start new chats
    if (_userRole == 'patient') {
      final pharmacists = await _authService.getPharmacists();
      _pharmacists = pharmacists;
    }

    if (mounted) {
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }
  }

  Future<void> _startNewConversation() async {
    if (_pharmacists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pharmacists available')),
      );
      return;
    }

    final selectedPharmacist = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PharmacistSelectionSheet(pharmacists: _pharmacists),
    );

    if (selectedPharmacist != null && mounted) {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      // Check if conversation already exists
      final existingConversation = _conversations.firstWhere(
        (c) => c.pharmacistId == selectedPharmacist.id,
        orElse: () => ChatConversation(
          id: '',
          patientId: '',
          patientName: '',
          pharmacistId: '',
          pharmacistName: '',
        ),
      );

      if (existingConversation.id.isNotEmpty) {
        // Navigate to existing conversation
        _navigateToChat(existingConversation);
        return;
      }

      // Create new conversation
      final conversation = await _authService.getOrCreateConversation(
        patientId: user.id,
        patientName: user.fullName,
        pharmacistId: selectedPharmacist.id,
        pharmacistName: selectedPharmacist.fullName,
      );

      if (conversation != null && mounted) {
        _navigateToChat(conversation);
      }
    }
  }

  void _navigateToChat(ChatConversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conversation,
          userRole: _userRole,
        ),
      ),
    );
    _loadData(); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_userRole == 'patient' ? 'Chat with Pharmacist' : 'Patient Chats'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _ConversationCard(
                        conversation: conversation,
                        userRole: _userRole,
                        onTap: () => _navigateToChat(conversation),
                      );
                    },
                  ),
                ),
      floatingActionButton: _userRole == 'patient'
          ? FloatingActionButton.extended(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userRole == 'patient'
                ? 'Start a conversation with a pharmacist'
                : 'Patients will contact you here',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying a conversation preview
class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.userRole,
    required this.onTap,
  });

  final ChatConversation conversation;
  final String userRole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherName = conversation.getOtherParticipantName(userRole);
    final unreadCount = conversation.getUnreadCount(userRole);
    final hasUnread = unreadCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasUnread ? 3 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessageTime != null)
                          Text(
                            _formatTime(conversation.lastMessageTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread 
                                  ? theme.colorScheme.primary 
                                  : Colors.grey[500],
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isNotEmpty
                                ? conversation.lastMessage
                                : 'No messages yet',
                            style: TextStyle(
                              color: hasUnread 
                                  ? Colors.grey[800] 
                                  : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

/// Bottom sheet for selecting a pharmacist to start a new conversation
class _PharmacistSelectionSheet extends StatelessWidget {
  const _PharmacistSelectionSheet({required this.pharmacists});

  final List<UserModel> pharmacists;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select a Pharmacist',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          // List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pharmacists.length,
              itemBuilder: (context, index) {
                final pharmacist = pharmacists[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: pharmacist.photoUrl != null
                        ? NetworkImage(pharmacist.photoUrl!)
                        : null,
                    child: pharmacist.photoUrl == null
                        ? Text(
                            pharmacist.fullName.isNotEmpty
                                ? pharmacist.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  title: Text(pharmacist.fullName),
                  subtitle: Text(pharmacist.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, pharmacist),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
