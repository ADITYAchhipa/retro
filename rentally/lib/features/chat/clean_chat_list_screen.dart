import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/error_boundary.dart';
import '../../widgets/loading_states.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/theme/enterprise_light_theme.dart';

/// **CleanChatListScreen**
/// 
/// Clean chat list screen with messaging functionality
/// 
/// **Features:**
/// - Responsive design for all screen sizes
/// - Error boundaries with crash protection
/// - Chat search and filtering
/// - Real-time message updates
/// - Chat management actions
class CleanChatListScreen extends StatefulWidget {
  const CleanChatListScreen({super.key});

  @override
  State<CleanChatListScreen> createState() => _CleanChatListScreenState();
}

class _CleanChatListScreenState extends State<CleanChatListScreen> {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  String _searchQuery = '';
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  // Mock chat data
  final List<Map<String, dynamic>> _chats = [
    {
      'id': '1',
      'userName': 'John Smith',
      'userImage': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
      'lastMessage': 'Thanks for the quick response!',
      'timestamp': '2 min ago',
      'unreadCount': 2,
      'isOnline': true,
      'propertyTitle': 'Downtown Apartment',
    },
    {
      'id': '2',
      'userName': 'Sarah Johnson',
      'userImage': 'https://images.unsplash.com/photo-1494790108755-2616b332c1a2?w=100',
      'lastMessage': 'Is the property still available?',
      'timestamp': '1 hour ago',
      'unreadCount': 0,
      'isOnline': false,
      'propertyTitle': 'Beach House',
    },
    {
      'id': '3',
      'userName': 'Mike Wilson',
      'userImage': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'lastMessage': 'Perfect! When can we schedule the viewing?',
      'timestamp': '3 hours ago',
      'unreadCount': 1,
      'isOnline': true,
      'propertyTitle': 'Luxury Condo',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadChats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => _isLoading = false);
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $error')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadChats();
  }

  List<Map<String, dynamic>> _getFilteredChats() {
    if (_searchQuery.isEmpty) {
      return _chats;
    }
    return _chats.where((chat) =>
      chat['userName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      chat['propertyTitle'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      chat['lastMessage'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _onChatTap(Map<String, dynamic> chat) {
    context.push('/chat/${chat['id']}');
  }

  void _markAsRead(String chatId) {
    setState(() {
      final chatIndex = _chats.indexWhere((chat) => chat['id'] == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex]['unreadCount'] = 0;
      }
    });
  }

  void _deleteChat(String chatId) {
    setState(() {
      _chats.removeWhere((chat) => chat['id'] == chatId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ErrorBoundary(
      onError: (details) {
        debugPrint('Chat list screen error: ${details.exception}');
      },
      child: ResponsiveLayout(
        child: Scaffold(
          backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : EnterpriseLightTheme.primaryBackground,
          appBar: _buildAppBar(theme),
          body: _buildBody(theme, isDark),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBack,
      ),
      title: const Text('Messages'),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () => _showSearchDialog(context),
          icon: const Icon(Icons.search),
          tooltip: 'Search Chats',
        ),
        IconButton(
          onPressed: () => context.push('/new-chat'),
          icon: const Icon(Icons.add_comment),
          tooltip: 'New Chat',
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _onRefresh,
      child: Column(
        children: [
          if (_searchQuery.isNotEmpty) _buildSearchHeader(theme),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _buildChatList(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Search results for "$_searchQuery"',
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(child: LoadingStates.propertyCardSkeleton(context)),
      ),
    );
  }

  Widget _buildChatList(ThemeData theme, bool isDark) {
    final filteredChats = _getFilteredChats();
    
    if (filteredChats.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return _buildChatItem(chat, theme, isDark);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No messages yet' : 'No chats found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.titleLarge?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Start a conversation with property owners or guests'
                : 'Try adjusting your search terms',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/explore'),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Properties'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, ThemeData theme, bool isDark) {
    final hasUnread = chat['unreadCount'] > 0;
    
    return Dismissible(
      key: Key(chat['id']),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.mark_chat_read, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _markAsRead(chat['id']);
          return false;
        } else {
          return await _showDeleteConfirmation(context, chat['userName']);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteChat(chat['id']);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          onTap: () => _onChatTap(chat),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: CachedNetworkImageProvider(chat['userImage']),
                onBackgroundImageError: (exception, stackTrace) {},
                child: chat['userImage'].isEmpty 
                    ? Text(chat['userName'][0].toUpperCase())
                    : null,
              ),
              if (chat['isOnline'])
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  chat['userName'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (hasUnread)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${chat['unreadCount']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chat['propertyTitle'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                chat['lastMessage'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: Text(
            chat['timestamp'],
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Chats'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by name, property, or message...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String userName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete the chat with $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }
}
