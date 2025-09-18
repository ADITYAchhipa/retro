import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/widgets/tab_back_handler.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/providers/ui_visibility_provider.dart';

/// Modular Booking Requests Screen with Industrial-Grade Features
class ModularBookingRequestsScreen extends ConsumerStatefulWidget {
  const ModularBookingRequestsScreen({super.key});

  @override
  ConsumerState<ModularBookingRequestsScreen> createState() =>
      _ModularBookingRequestsScreenState();
}

class _ModularBookingRequestsScreenState
    extends ConsumerState<ModularBookingRequestsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'pending';
  String _searchQuery = '';
  
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRequests();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await Future.delayed(const Duration(seconds: 2));
      
      final mockRequests = List.generate(12, (index) => {
        'id': 'request_$index',
        'guestName': 'Guest ${index + 1}',
        // Stable placeholder images to avoid 404s
        'guestImage': 'https://picsum.photos/seed/guest_$index/200/200',
        'propertyTitle': 'Property ${(index % 3) + 1}',
        'propertyImage': 'https://picsum.photos/seed/property_$index/400/300',
        'checkIn': DateTime.now().add(Duration(days: index + 1)),
        'checkOut': DateTime.now().add(Duration(days: index + 4)),
        'guests': (index % 4) + 1,
        'totalAmount': 300.0 + (index * 50),
        'status': ['pending', 'approved', 'rejected'][index % 3],
        'message': index % 2 == 0 ? 'Looking forward to staying at your place!' : null,
        'requestedAt': DateTime.now().subtract(Duration(hours: index)),
        'responseTime': '${2 + (index % 6)} hours',
        'guestRating': 4.0 + (index % 10) * 0.1,
        'guestReviews': index * 2 + 5,
        'isInstantBook': index % 4 == 0,
      });
      
      if (mounted) {
        setState(() {
          _requests = mockRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load requests: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      maxWidth: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: TabBackHandler(
        child: Scaffold(
          appBar: _buildAppBar(),
          body: _isLoading ? _buildLoadingState() : _buildContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        'Booking Requests',
        style: (theme.textTheme.titleLarge ?? theme.textTheme.titleMedium)?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1.0,
        ),
      ),
      toolbarHeight: 44,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      flexibleSpace: null,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(105),
        child: Container(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterTabs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by guest or property...',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final theme = Theme.of(context);
    final filters = [
      {'key': 'pending', 'label': 'Pending', 'count': _requests.where((r) => r['status'] == 'pending').length},
      {'key': 'approved', 'label': 'Approved', 'count': _requests.where((r) => r['status'] == 'approved').length},
      {'key': 'rejected', 'label': 'Rejected', 'count': _requests.where((r) => r['status'] == 'rejected').length},
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${filter['label']} (${filter['count']})'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter['key'] as String);
              },
              showCheckmark: true,
              selectedColor: theme.colorScheme.primary.withOpacity(0.12),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(isSelected ? 0.0 : 0.3)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    final filteredRequests = _getFilteredRequests();

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _loadRequests,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: filteredRequests.isEmpty
            ? _buildEmptyState()
            : _buildRequestsList(filteredRequests),
      ),
    );
  }

  Widget _buildLoadingState() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 88;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomPad),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LoadingStates.propertyCardSkeleton(context),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64),
            const SizedBox(height: 16),
            Text(
              'No Requests Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'New booking requests will appear here',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> requests) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 88;
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: request['guestImage'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request['guestName'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (request['isInstantBook'])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Instant Book',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[600]),
                          Text(
                            ' ${request['guestRating'].toStringAsFixed(1)} (${request['guestReviews']} reviews)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(request['status']),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 16, color: theme.colorScheme.outline.withOpacity(0.12)),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: request['propertyImage'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['propertyTitle'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatDate(request['checkIn'])} - ${_formatDate(request['checkOut'])}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${request['guests']} guests',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              CurrencyFormatter.formatPrice((request['totalAmount'] as num).toDouble()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green[600],
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
            if (request['message'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message from guest:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request['message'],
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Requested ${_formatTimeAgo(request['requestedAt'])}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (request['status'] == 'pending')
                  Text(
                    'Respond within ${request['responseTime']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            if (request['status'] == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (request['status'] != 'pending') ...[
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _viewGuestProfile(request),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('Profile'),
                ),
                TextButton.icon(
                  onPressed: () => _contactGuest(request),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Message'),
                ),
                TextButton.icon(
                  onPressed: () => _viewRequestDetails(request),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Declined';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredRequests() {
    return _requests.where((request) {
      final matchesFilter = request['status'] == _selectedFilter;
      if (!matchesFilter) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final guest = (request['guestName'] as String).toLowerCase();
      final prop = (request['propertyTitle'] as String).toLowerCase();
      return guest.contains(q) || prop.contains(q);
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _approveRequest(Map<String, dynamic> request) {
    setState(() {
      request['status'] = 'approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request approved for ${request['guestName']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Request'),
        content: const Text('Are you sure you want to decline this booking request?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              setState(() {
                request['status'] = 'rejected';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request declined for ${request['guestName']}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewGuestProfile(Map<String, dynamic> request) {
    // Open guest profile with path parameter; pass name/avatar via extra
    final guestId = request['id'];
    ref.read(immersiveRouteOpenProvider.notifier).state = true;
    context.push('/guest-profile/$guestId', extra: {
      'guestName': request['guestName'],
      'guestAvatar': request['guestImage'],
    }).whenComplete(() {
      ref.read(immersiveRouteOpenProvider.notifier).state = false;
    });
  }

  void _contactGuest(Map<String, dynamic> request) {
    final chatId = request['id'];
    context.push('/chat/$chatId', extra: {
      'requestId': request['id'],
      'guestName': request['guestName'],
    });
  }

  void _viewRequestDetails(Map<String, dynamic> request) {
    final id = request['id'];
    context.push('/booking-history/$id');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
