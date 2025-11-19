import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/review_service.dart';
import '../../app/app_state.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/widgets/tab_back_handler.dart';

class BidirectionalReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String guestId;
  final String guestName;
  final String listingId;
  final String listingTitle;

  const BidirectionalReviewScreen({
    super.key,
    required this.bookingId,
    required this.guestId,
    required this.guestName,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  ConsumerState<BidirectionalReviewScreen> createState() => _BidirectionalReviewScreenState();
}

class _BidirectionalReviewScreenState extends ConsumerState<BidirectionalReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Property review form
  final _propertyFormKey = GlobalKey<FormState>();
  final _propertyCommentController = TextEditingController();
  double _propertyRating = 5.0;
  final Map<String, double> _propertyCategories = {
    'cleanliness': 5.0,
    'accuracy': 5.0,
    'communication': 5.0,
    'location': 5.0,
    'check_in': 5.0,
    'value': 5.0,
  };

  // Guest review form
  final _guestFormKey = GlobalKey<FormState>();
  final _guestCommentController = TextEditingController();
  double _guestRating = 5.0;
  final Map<String, double> _guestCategories = {
    'cleanliness': 5.0,
    'communication': 5.0,
    'respect': 5.0,
    'reliability': 5.0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _propertyCommentController.dispose();
    _guestCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    return TabBackHandler(
      tabController: _tabController,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Leave Reviews'),
        backgroundColor: theme.colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.home),
              text: 'Review Property',
            ),
            if (isOwner)
              const Tab(
                icon: Icon(Icons.person),
                text: 'Review Guest',
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
        children: [
          _buildPropertyReviewTab(theme),
          if (isOwner) _buildGuestReviewTab(theme),
        ],
      ),
      ),
    );
  }

  Widget _buildPropertyReviewTab(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _propertyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was your stay?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.listingTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Overall Rating
            Text(
              'Overall Rating',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStarRating(_propertyRating, (rating) {
              setState(() => _propertyRating = rating);
            }),
            
            const SizedBox(height: 24),

            // Category Ratings
            Text(
              'Rate Your Experience',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._propertyCategories.entries.map((entry) => 
              _buildCategoryRating(
                entry.key,
                entry.value,
                (value) => setState(() => _propertyCategories[entry.key] = value),
              ),
            ),

            const SizedBox(height: 24),

            // Comment
            Text(
              'Share Your Experience',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _propertyCommentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell others about your stay...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please share your experience';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitPropertyReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Property Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestReviewTab(ThemeData theme) {
    return SingleChildScrollView(
      dragStartBehavior: DragStartBehavior.down,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _guestFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was your guest?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.guestName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Overall Rating
            Text(
              'Overall Rating',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStarRating(_guestRating, (rating) {
              setState(() => _guestRating = rating);
            }),
            
            const SizedBox(height: 24),

            // Category Ratings
            Text(
              'Rate Guest Behavior',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._guestCategories.entries.map((entry) => 
              _buildCategoryRating(
                entry.key,
                entry.value,
                (value) => setState(() => _guestCategories[entry.key] = value),
              ),
            ),

            const SizedBox(height: 24),

            // Comment
            Text(
              'Share Your Experience',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _guestCommentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell other hosts about this guest...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please share your experience';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitGuestReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Guest Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, Function(double) onRatingChanged) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged((index + 1).toDouble()),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  Widget _buildCategoryRating(String category, double value, Function(double) onChanged) {
    final displayName = _getCategoryDisplayName(category);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'cleanliness':
        return 'Cleanliness';
      case 'accuracy':
        return 'Accuracy';
      case 'communication':
        return 'Communication';
      case 'location':
        return 'Location';
      case 'check_in':
        return 'Check-in';
      case 'value':
        return 'Value';
      case 'respect':
        return 'Respect for Property';
      case 'reliability':
        return 'Reliability';
      default:
        return category.toUpperCase();
    }
  }

  void _submitPropertyReview() async {
    if (!_propertyFormKey.currentState!.validate()) return;

    try {
      await ref.read(reviewProvider.notifier).addReview(
        listingId: widget.listingId,
        userId: ref.read(authProvider).user!.id,
        userName: ref.read(authProvider).user!.name,
        rating: _propertyRating,
        comment: _propertyCommentController.text.trim(),
        categoryRatings: _propertyCategories,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Property review submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error: $e');
      }
    }
  }

  void _submitGuestReview() async {
    if (!_guestFormKey.currentState!.validate()) return;

    try {
      await ref.read(reviewProvider.notifier).addGuestReview(
        guestId: widget.guestId,
        listingId: widget.listingId,
        ownerId: ref.read(authProvider).user!.id,
        ownerName: ref.read(authProvider).user!.name,
        rating: _guestRating,
        comment: _guestCommentController.text.trim(),
        categoryRatings: _guestCategories,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Guest review submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error: $e');
      }
    }
  }
}
