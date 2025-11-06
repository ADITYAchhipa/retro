import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/review_service.dart';

class GuestProfileScreen extends ConsumerWidget {
  final String guestId;
  final String guestName;
  final String? guestAvatar;

  const GuestProfileScreen({
    super.key,
    required this.guestId,
    required this.guestName,
    this.guestAvatar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guestReviews = ref.watch(guestReviewsProvider(guestId));
    final guestStats = ref.watch(guestReviewStatsProvider(guestId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$guestName\'s Profile'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guest Header
            _buildGuestHeader(theme, guestStats),
            
            const SizedBox(height: 24),

            // Stats Overview
            _buildStatsOverview(theme, guestStats),
            
            const SizedBox(height: 24),

            // Category Ratings
            if (guestStats.categoryAverages.isNotEmpty) ...[
              _buildCategoryRatings(theme, guestStats),
              const SizedBox(height: 24),
            ],

            // Reviews List
            _buildReviewsList(theme, guestReviews),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestHeader(ThemeData theme, ReviewStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: guestAvatar != null ? NetworkImage(guestAvatar!) : null,
            child: guestAvatar == null
                ? Text(
                    guestName.isNotEmpty ? guestName[0].toUpperCase() : 'G',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // Guest Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guestName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stats.averageRating > 0 
                          ? stats.averageRating.toStringAsFixed(1)
                          : 'No ratings yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${stats.totalReviews} ${stats.totalReviews == 1 ? 'review' : 'reviews'})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getReputationColor(stats.averageRating).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getReputationLabel(stats.averageRating),
                    style: TextStyle(
                      color: _getReputationColor(stats.averageRating),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme, ReviewStats stats) {
    if (stats.totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.star_outline,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'No reviews yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Distribution',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final starRating = 5 - index;
            final count = stats.ratingDistribution[starRating] ?? 0;
            final percentage = stats.totalReviews > 0 ? count / stats.totalReviews : 0.0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('$starRating'),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryRatings(ThemeData theme, ReviewStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Ratings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...stats.categoryAverages.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCategoryDisplayName(entry.key),
                    style: theme.textTheme.bodyMedium,
                  ),
                  Row(
                    children: [
                      Text(
                        entry.value.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewsList(ThemeData theme, List<Review> reviews) {
    if (reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews from Hosts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...reviews.map((review) => _buildReviewCard(theme, review)),
      ],
    );
  }

  Widget _buildReviewCard(ThemeData theme, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: review.userAvatar != null 
                    ? NetworkImage(review.userAvatar!) 
                    : null,
                child: review.userAvatar == null
                    ? Text(
                        review.userName.isNotEmpty 
                            ? review.userName[0].toUpperCase() 
                            : 'H',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review Comment
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium,
          ),
          
          // Category Ratings
          if (review.categoryRatings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: review.categoryRatings.entries.map((entry) {
                return Chip(
                  label: Text(
                    '${_getCategoryDisplayName(entry.key)}: ${entry.value.toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'cleanliness':
        return 'Cleanliness';
      case 'communication':
        return 'Communication';
      case 'respect':
        return 'Respect';
      case 'reliability':
        return 'Reliability';
      default:
        return category.toUpperCase();
    }
  }

  Color _getReputationColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.orange;
    if (rating >= 3.0) return Colors.red;
    return Colors.grey;
  }

  String _getReputationLabel(double rating) {
    if (rating == 0) return 'New Guest';
    if (rating >= 4.5) return 'Excellent Guest';
    if (rating >= 4.0) return 'Good Guest';
    if (rating >= 3.0) return 'Average Guest';
    return 'Needs Improvement';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}
