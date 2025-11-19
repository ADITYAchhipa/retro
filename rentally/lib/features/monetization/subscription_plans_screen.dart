// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/monetization_service.dart';
import '../../models/monetization_models.dart';
import '../../core/utils/currency_formatter.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  final bool isHost;
  
  const SubscriptionPlansScreen({
    super.key,
    this.isHost = true,
  });

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

// Top-level shimmering skeleton card used while loading
class _SkeletonCard extends StatefulWidget {
  final ThemeData theme;
  const _SkeletonCard({required this.theme});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmer(Widget child) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;
        final gradient = LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.1, 0.3, 0.4],
          begin: Alignment(-1.0 - 2 * v, -0.3),
          end: Alignment(1.0 - 2 * v, 0.3),
        );
        return ShaderMask(
          shaderCallback: (rect) => gradient.createShader(rect),
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.theme.colorScheme.outline.withValues(alpha: 0.15)),
            borderRadius: borderRadius,
          ),
          child: _shimmer(
            Container(
              color: Colors.grey.shade300,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header block
                    Container(height: 110, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(height: 16),
                    // Chips row
                    Row(
                      children: [
                        Container(width: 70, height: 20, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(999))),
                        const SizedBox(width: 8),
                        Container(width: 90, height: 20, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(999))),
                        const SizedBox(width: 8),
                        Container(width: 60, height: 20, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(999))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Feature lines
                    Container(height: 12, width: double.infinity, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Container(height: 12, width: double.infinity, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Container(height: 12, width: double.infinity, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    // Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(width: 120, height: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> with TickerProviderStateMixin {
  SubscriptionDuration _selectedDuration = SubscriptionDuration.monthly;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  double _headerMaxHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Measure header height after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  Color _planAccentColor(SubscriptionPlan plan, ThemeData theme) {
    // Modern vibrant colors per tier
    switch (plan.tier) {
      case SubscriptionTier.elite:
        return const Color(0xFF8B5CF6); // Purple
      case SubscriptionTier.pro:
        return const Color(0xFF3B82F6); // Vibrant Blue
      case SubscriptionTier.basic:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  Color _planAccentColorSecondary(SubscriptionPlan plan) {
    // Secondary gradient color for modern effect
    switch (plan.tier) {
      case SubscriptionTier.elite:
        return const Color(0xFFEC4899); // Pink
      case SubscriptionTier.pro:
        return const Color(0xFF06B6D4); // Cyan
      case SubscriptionTier.basic:
        return const Color(0xFF059669); // Darker Green
    }
  }

  Widget _buildTestimonialsRibbon() {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final testimonials = [
      {'name': 'Anita, Owner', 'text': 'Pro plan boosted my bookings by 35% in a month!', 'rating': 5},
      {'name': 'Rohit, Seeker', 'text': 'Priority booking got me a vehicle within minutes.', 'rating': 5},
      {'name': 'Meera, Owner', 'text': 'Elite plan’s zero commission saved me thousands.', 'rating': 5},
    ];

    Widget stars(int n) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(n, (i) => Icon(Icons.star, size: isPhone ? 12 : 14, color: Colors.amber)),
        );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      padding: EdgeInsets.all(isPhone ? 10 : 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: testimonials.map((t) {
            return Container(
              width: isPhone ? 220 : 280,
              margin: EdgeInsets.only(right: isPhone ? 8 : 12),
              padding: EdgeInsets.all(isPhone ? 10 : 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stars(t['rating'] as int),
                  const SizedBox(height: 6),
                  Text(
                    t['text'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t['name'] as String,
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _hoverScaleWrap({required Widget child}) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool hovered = false;
        bool pressed = false;
        double scale() => pressed ? 0.98 : (hovered ? 1.02 : 1.0);
        return MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (_) => setState(() => pressed = true),
            onTapCancel: () => setState(() => pressed = false),
            onTapUp: (_) => setState(() => pressed = false),
            child: AnimatedScale(
              scale: scale(),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      Widget skeletonCard() => _SkeletonCard(theme: theme);
      if (width >= 1024) {
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => skeletonCard(),
        );
      } else if (width >= 720) {
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => skeletonCard(),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 4,
        itemBuilder: (_, __) => skeletonCard(),
      );
    });
  }


  Widget _buildGuaranteeChips() {
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    Chip buildChip(IconData icon, String label, Color color) {
      return Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(icon, size: isPhone ? 14 : 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: isPhone ? 11 : 12,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.10),
        shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.25))),
        padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 8),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: isPhone ? 6 : 8,
        runSpacing: isPhone ? 6 : 8,
        children: [
          buildChip(Icons.verified, 'Money-back guarantee', const Color(0xFF10B981)),
          buildChip(Icons.lock, 'Secure payment', const Color(0xFF6366F1)),
          buildChip(Icons.cancel_schedule_send, 'Cancel anytime', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _measureHeader() {
    final ctx = _headerKey.currentContext;
    if (ctx != null) {
      final h = ctx.size?.height ?? 0.0;
      if (h > 0.0 && (h - _headerMaxHeight).abs() > 1.0) {
        setState(() {
          _headerMaxHeight = h;
        });
      }
    }
  }

  void _onScroll() {
    if (!mounted) return;
    // Rebuild so header height instantly reflects current scroll offset
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final monetization = ref.watch(monetizationServiceProvider);
    
    final plans = monetization.subscriptionPlans.where((plan) => plan.id.startsWith('host_')).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'Host Plans' : 'Premium Plans'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: monetization.isLoading
          ? _buildLoadingSkeleton()
          : Column(
              children: [
                // Duration Toggle - Fixed at top
                Padding(
                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDurationButton('Monthly', SubscriptionDuration.monthly),
                        ),
                        Expanded(
                          child: _buildDurationButton('Yearly (Save 17%)', SubscriptionDuration.yearly),
                        ),
                      ],
                    ),
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          // Header
                          SliverToBoxAdapter(
                            child: Container(
                              key: _headerKey,
                              width: double.infinity,
                              padding: EdgeInsets.all(isPhone ? 16 : 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary.withValues(alpha: 0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isHost ? Icons.business : Icons.star,
                                    size: isPhone ? 34 : 48,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  SizedBox(height: isPhone ? 10 : 16),
                                  Text(
                                    widget.isHost 
                                        ? 'Grow Your Hosting Business'
                                        : 'Unlock Premium Features',
                                    style: (isPhone ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isPhone ? 6 : 8),
                                  Text(
                                    widget.isHost
                                        ? 'Choose the perfect plan to maximize your earnings and reach more guests'
                                        : 'Get early access, advanced filters, and exclusive deals',
                                    style: (isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Testimonials ribbon
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 16, vertical: isPhone ? 6 : 8),
                              child: _buildTestimonialsRibbon(),
                            ),
                          ),
                          // Plans Grid/List
                          if (width >= 1024)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildPlanCard(plans[index]),
                                  childCount: plans.length,
                                ),
                              ),
                            )
                          else if (width >= 720)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildPlanCard(plans[index]),
                                  childCount: plans.length,
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildPlanCard(plans[index]),
                                  childCount: plans.length,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlanHighlights(SubscriptionPlan plan) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final planId = plan.id;

    // Compute yearly savings chip when applicable
    final annualIfMonthly = plan.monthlyPrice * 12;
    final yearlySavings = ((annualIfMonthly - plan.yearlyPrice).clamp(0, double.infinity)) as double;
    final yearlySavingsPct = annualIfMonthly > 0 ? ((yearlySavings / annualIfMonthly) * 100).round() : 0;

    List<Widget> chips = [];

    void addChip(IconData icon, String label, Color color) {
      chips.add(
        Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(icon, size: isPhone ? 12 : 14, color: color),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isPhone ? 9.5 : 11,
              letterSpacing: -0.2,
            ),
          ),
          backgroundColor: color.withValues(alpha: 0.10),
          shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.25))),
          padding: EdgeInsets.symmetric(horizontal: isPhone ? 4 : 6),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // Owner plans - structured badge layout
    if (planId.startsWith('host_')) {
      if (planId.contains('elite')) {
        // Elite plan badges (5 badges)
        addChip(Icons.card_giftcard, '7-Day Free Trial', Colors.teal.shade700);
        addChip(Icons.monetization_on_outlined, 'Zero Commission', const Color(0xFF8B5CF6));
        addChip(Icons.public, 'Global Reach', const Color(0xFFEC4899));
        addChip(Icons.smart_toy, 'AI Pricing', const Color(0xFF6366F1));
        addChip(Icons.support_agent, 'Concierge Support', const Color(0xFFF59E0B));
      } else if (planId.contains('pro')) {
        // Pro plan badges (6 badges in 2-2-2 layout)
        addChip(Icons.local_fire_department, 'Most Popular', Colors.amber.shade700);
        addChip(Icons.card_giftcard, '7-Day Free Trial', Colors.teal.shade700);
        addChip(Icons.trending_up, 'Featured Placement', const Color(0xFF3B82F6));
        addChip(Icons.insights, 'Advanced Analytics', const Color(0xFF06B6D4));
        addChip(Icons.headset_mic, 'Priority Support', const Color(0xFF8B5CF6));
        addChip(Icons.local_offer, 'Intro Offer 20% off', const Color(0xFFEC4899));
      } else {
        // Basic plan badges
        addChip(Icons.card_giftcard, '7-Day Free Trial', Colors.teal.shade700);
        addChip(Icons.rocket_launch, 'Start Hosting', theme.colorScheme.primary);
        addChip(Icons.format_list_bulleted, 'Up to 3 Listings', Colors.grey.shade800);
      }
    }

    // Yearly savings chip (added last for all plans)
    if (_selectedDuration == SubscriptionDuration.yearly && yearlySavings > 0) {
      addChip(Icons.savings, 'Save $yearlySavingsPct% yearly', Colors.green.shade700);
    }


    if (chips.isEmpty) return const SizedBox.shrink();

    // For Pro plan on phone, use structured rows to ensure 2-2-2 layout
    if (isPhone && planId.contains('pro') && chips.length >= 6) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: chips[0]), // Most Popular
              const SizedBox(width: 4),
              Flexible(child: chips[1]), // 7-Day Free Trial
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Flexible(child: chips[2]), // Featured Placement
              const SizedBox(width: 4),
              Flexible(child: chips[3]), // Advanced Analytics
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Flexible(child: chips[4]), // Priority Support
              const SizedBox(width: 4),
              Flexible(child: chips[5]), // Intro Offer
            ],
          ),
          if (chips.length > 6) ...[
            const SizedBox(height: 5),
            ...chips.sublist(6), // Any additional chips (like yearly savings)
          ],
        ],
      );
    }

    // Default wrap layout for other plans
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: isPhone ? 4 : 6,
        runSpacing: isPhone ? 5 : 6,
        children: chips,
      ),
    );
  }

  Widget _buildDurationButton(String text, SubscriptionDuration duration) {
    final isSelected = _selectedDuration == duration;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = duration),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isPhone ? 10 : 12, horizontal: isPhone ? 6 : 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                )]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isPhone ? 12 : null,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final price = plan.getPrice(_selectedDuration);
    final monthlyEquivalent = _selectedDuration == SubscriptionDuration.yearly ? price / 12 : price;
    final annualIfMonthly = plan.monthlyPrice * 12;
    final yearlySavings = ((annualIfMonthly - plan.yearlyPrice).clamp(0, double.infinity)) as double;
    final yearlySavingsPct = annualIfMonthly > 0 ? ((yearlySavings / annualIfMonthly) * 100).round() : 0;
    final accent = _planAccentColor(plan, theme);

    final accentSecondary = _planAccentColorSecondary(plan);

    Widget header() => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accentSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isPhone ? 14 : 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 10, vertical: isPhone ? 3 : 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        plan.tier.name.toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: isPhone ? 10 : 11),
                      ),
                    ),
                    SizedBox(height: isPhone ? 8 : 10),
                    Text(
                      plan.name,
                      style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: (isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 12, vertical: isPhone ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatPrice(price, currency: plan.currency),
                          style: (isPhone ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                        Text(
                          _selectedDuration == SubscriptionDuration.yearly
                              ? '/year (${CurrencyFormatter.formatPrice(monthlyEquivalent, currency: plan.currency)}/mo)'
                              : '/month',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedDuration == SubscriptionDuration.yearly && yearlySavings > 0)
                    Padding(
                      padding: EdgeInsets.only(top: isPhone ? 6 : 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 8, vertical: isPhone ? 3 : 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.savings, size: 14, color: Colors.white),
                            SizedBox(width: isPhone ? 4 : 6),
                            Text(
                              'Save ${CurrencyFormatter.formatPrice(yearlySavings, currency: plan.currency)} ($yearlySavingsPct%)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

    return _hoverScaleWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: plan.isPopular ? 0.2 : 0.15),
              blurRadius: plan.isPopular ? 20 : 15,
              offset: const Offset(0, 4),
              spreadRadius: plan.isPopular ? 2 : 1,
            ),
            BoxShadow(
              color: accentSecondary.withValues(alpha: plan.isPopular ? 0.15 : 0.1),
              blurRadius: plan.isPopular ? 30 : 20,
              offset: const Offset(0, 8),
              spreadRadius: plan.isPopular ? 1 : 0,
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: plan.isPopular
                ? BorderSide(color: accent.withValues(alpha: 0.3), width: 2)
                : BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          color: Colors.white,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (plan.isPopular)
                Positioned(
                  top: -8,
                  right: isPhone ? 12 : 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 12 : 16,
                      vertical: isPhone ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accentSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: accentSecondary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: isPhone ? 14 : 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: isPhone ? 4 : 6),
                        Text(
                          'MOST POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: isPhone ? 10 : 11,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(plan.isPopular ? (isPhone ? 16 : 20) : (isPhone ? 12 : 16)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final content = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plan.isPopular) SizedBox(height: isPhone ? 8 : 12),
                        header(),
                        SizedBox(height: isPhone ? 14 : 18),
                        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                        SizedBox(height: isPhone ? 12 : 16),
                        _buildPlanHighlights(plan),
                        SizedBox(height: isPhone ? 10 : 14),
                        ...plan.features.map((feature) => Padding(
                              padding: EdgeInsets.symmetric(vertical: isPhone ? 3 : 4),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: isPhone ? 16 : 20),
                                  SizedBox(width: isPhone ? 8 : 12),
                                  Expanded(child: Text(feature, style: isPhone ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)),
                                ],
                              ),
                            )),
                        SizedBox(height: isPhone ? 10 : 14),
                        _buildGuaranteeChips(),
                        SizedBox(height: isPhone ? 16 : 24),
                        Container(
                          width: double.infinity,
                          height: isPhone ? 48 : 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent, accentSecondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _selectPlan(plan),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Start 7-Day Free Trial',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                            ),
                          ),
                        ),
                        if (_isCurrentPlan(plan))
                          Padding(
                            padding: EdgeInsets.only(top: isPhone ? 8 : 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text('Current Plan', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    );
                    if (constraints.hasBoundedHeight) {
                      return SingleChildScrollView(
                        primary: false,
                        child: content,
                      );
                    }
                    return content;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Secure Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustBadge(Icons.credit_card, 'Stripe Secured'),
              _buildTrustBadge(Icons.lock, '256-bit SSL'),
              _buildTrustBadge(Icons.cancel, 'Cancel Anytime'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your payment information is encrypted and secure. Cancel or change your plan anytime.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }


  bool _isCurrentPlan(SubscriptionPlan plan) {
    final currentSubscription = ref.read(monetizationServiceProvider).currentSubscription;
    return currentSubscription != null && 
           currentSubscription.plan.id == plan.id && 
           currentSubscription.isValid;
  }

  void _selectPlan(SubscriptionPlan plan) async {
    // Don't allow selecting current plan
    if (_isCurrentPlan(plan)) return;
    
    // Show confirmation dialog
    final confirmed = await _showPurchaseConfirmation(plan);
    if (!confirmed) return;
    
    // setState(() => _isProcessing = true);
    
    try {
      final success = await ref
          .read(monetizationServiceProvider.notifier)
          .purchaseSubscription(plan, _selectedDuration);
      
      if (success && mounted) {
        // Success toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 8),
                Text('Subscription activated: ${plan.name}')
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        _showSuccessDialog(plan);
      } else if (mounted) {
        _showErrorDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        // setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _showPurchaseConfirmation(SubscriptionPlan plan) async {
    final price = plan.getPrice(_selectedDuration);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        final promoController = TextEditingController();
        double discountedPrice = price;
        String? promoMsg;
        return StatefulBuilder(
          builder: (context, setState) {
            final isProTier = plan.tier == SubscriptionTier.pro;
            const introDiscountPct = 0.20;
            final introPrice = (price * (1 - introDiscountPct));
            void applyPromo() {
              final code = promoController.text.trim().toUpperCase();
              int pct = 0;
              if (code == 'SAVE10') pct = 10;
              if (code == 'SAVE20') pct = 20;
              if (pct > 0) {
                setState(() {
                  discountedPrice = price * (1 - pct / 100);
                  promoMsg = 'Applied $pct% off';
                });
              } else {
                setState(() {
                  discountedPrice = price;
                  promoMsg = 'Invalid code';
                });
              }
            }

            return AlertDialog(
              scrollable: true,
              title: const Text('Confirm Subscription'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 7-day trial notice
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      '7-Day Free Trial: ₹0 today. Next charge ${CurrencyFormatter.formatPrice(isProTier ? introPrice : price, currency: plan.currency)} after trial${isProTier ? ' (with 20% intro discount)' : ''}.',
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('Plan: ${plan.name}'),
                  Text('Duration: ${_selectedDuration.name}'),
                  const SizedBox(height: 8),
                  Text('Price: ${CurrencyFormatter.formatPrice(price, currency: plan.currency)}'),
                  if (discountedPrice != price)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Discounted: ${CurrencyFormatter.formatPrice(discountedPrice, currency: plan.currency)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: promoController,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Promo code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: applyPromo,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  if (promoMsg != null) ...[
                    const SizedBox(height: 6),
                    Text(promoMsg!, style: TextStyle(color: promoMsg!.startsWith('Applied') ? Colors.green : Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'You will be charged ${CurrencyFormatter.formatPrice(discountedPrice, currency: plan.currency)} ${_selectedDuration == SubscriptionDuration.monthly ? 'monthly' : 'yearly'}.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;
  }

  Widget _buildComparisonSection(List<SubscriptionPlan> plans) {
    final theme = Theme.of(context);
    if (plans.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Compare plans', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: plans.map((p) {
                final planPrice = CurrencyFormatter.formatPrice(p.getPrice(_selectedDuration), currency: p.currency);
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          if (p.isPopular)
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(planPrice, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 6),
                          Text('${p.features.length} features', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Text('Welcome to ${plan.name}! Your subscription is now active.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: const Text('There was an issue processing your payment. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
