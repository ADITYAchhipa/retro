import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/error_boundary.dart';
import '../../core/widgets/loading_states.dart';
import '../../core/theme/enterprise_dark_theme.dart';
import '../../core/neo/neo.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isSearching = false;
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
    _searchFocusNode.dispose();
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
          SnackBar(
            content: Text(
              'Error loading chats: $error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(milliseconds: 1800),
          ),
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
    return _chats.where((chat) {
      final userName = chat['userName'].toString().toLowerCase();
      final lastMessage = chat['lastMessage'].toString().toLowerCase();
      final propertyTitle = chat['propertyTitle'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return userName.contains(query) || lastMessage.contains(query) || propertyTitle.contains(query);
    }).toList();
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
      SnackBar(
        content: Text(
          'Chat deleted',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1400),
      ),
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
        padding: EdgeInsets.zero,
        child: Scaffold(
          backgroundColor: isDark ? EnterpriseDarkTheme.primaryBackground : Colors.white,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildModernHeader(theme, isDark),
                Expanded(
                  child: _buildBody(theme, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: EnterpriseDarkTheme.primaryAccent.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: _isSearching
            ? _buildSearchBar(theme, isDark)
            : Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _handleBack,
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      'Messages',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: isDark ? Colors.white70 : theme.primaryColor,
                      ),
                      onPressed: () => setState(() => _isSearching = true),
                      tooltip: 'Search messages',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            blurRadius: 12,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: (isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary)
                .withOpacity(isDark ? 0.2 : 0.15),
            blurRadius: 12,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.primary),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.primary),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                  });
                  _searchController.clear();
                },
                tooltip: 'Close search',
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBody(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _onRefresh,
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _buildChatList(theme, isDark),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return LoadingStates.listShimmer(context, itemCount: 6);
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
            'No messages yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.titleLarge?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with property owners or guests',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/explore'),
            icon: const Icon(Icons.explore),
            label: const Text('Explore Properties'),
          ),
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
      child: NeoGlass(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(18),
        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        borderWidth: 1,
        blur: isDark ? 12 : 0,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
          BoxShadow(
            color: (isDark ? EnterpriseDarkTheme.primaryAccent : theme.colorScheme.primary)
                .withOpacity(isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(5, 5),
          ),
        ],
        child: InkWell(
          onTap: () => _onChatTap(chat),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
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
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? Colors.grey[850]! : Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['userName'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          chat['timestamp'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1),
                      ),
                      child: Text(
                        chat['propertyTitle'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['lastMessage'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[700],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${chat['unreadCount']}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
