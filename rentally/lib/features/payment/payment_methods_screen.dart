import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<_CardItem> _cards = const [
    _CardItem(brand: 'Visa', last4: '4242', expiry: '12/26', isDefault: true),
    _CardItem(brand: 'Mastercard', last4: '2210', expiry: '07/25'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.background : Colors.white,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(theme, 'Your Cards', Icons.credit_card, isPhone),
          const SizedBox(height: 12),
          ..._cards
              .asMap()
              .entries
              .map((e) => _animateIn(_cardTile(context, e.value, theme), e.key)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showAddCardSheet,
            icon: const Icon(Icons.add),
            label: const Text('Add New Card'),
            style: FilledButton.styleFrom(
              minimumSize: Size(double.infinity, isPhone ? 46 : 48),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Other Methods', Icons.account_balance_wallet_outlined, isPhone),
          const SizedBox(height: 12),
          _animateIn(_walletTile(context, 'PayPal', Icons.account_balance_wallet, Colors.indigo, theme), _cards.length),
          const SizedBox(height: 10),
          _animateIn(_walletTile(context, 'Cash on Arrival', Icons.payments, Colors.green, theme), _cards.length + 1),
        ],
      ),
    );
  }

  Widget _brandGlyph(String brand, Color color, ThemeData theme) {
    switch (brand) {
      case 'visa':
        return Text('V', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18));
      case 'mastercard':
        return SizedBox(
          width: 28,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      case 'amex':
        return Text('A', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18));
      default:
        return Icon(Icons.credit_card, color: color);
    }
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon, bool isPhone) {
    return Row(
      children: [
        Container(
          width: isPhone ? 22 : 24,
          height: isPhone ? 22 : 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: isPhone ? 14 : 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: isPhone ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _animateIn(Widget child, int index) {
    final delayMs = 60 * index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + delayMs),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _cardTile(BuildContext context, _CardItem c, ThemeData theme) {
    final brand = c.brand.toLowerCase();
    final color = _brandColor(brand, theme);
    final isDark = theme.brightness == Brightness.dark;
    final softBorder = isDark
        ? theme.colorScheme.outlineVariant.withOpacity(0.25)
        : theme.colorScheme.outlineVariant.withOpacity(0.4);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      splashColor: theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08),
      highlightColor: Colors.transparent,
      onTap: () {
        setState(() {
          _cards = _cards
              .map((cc) => cc == c ? cc.copyWith(isDefault: true) : cc.copyWith(isDefault: false))
              .toList();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: c.isDefault
                ? theme.colorScheme.primary.withOpacity(0.35)
                : softBorder,
            width: 1,
          ),
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: _brandGlyph(brand, color, theme),
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
                          '${c.brand} •••• ${c.last4}',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (c.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expires ${c.expiry}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'default':
                    setState(() {
                      _cards = _cards
                          .map((cc) => cc == c ? cc.copyWith(isDefault: true) : cc.copyWith(isDefault: false))
                          .toList();
                    });
                    break;
                  case 'remove':
                    setState(() => _cards = _cards.where((cc) => cc != c).toList());
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!c.isDefault)
                  const PopupMenuItem(value: 'default', child: Text('Set as default')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletTile(BuildContext context, String title, IconData icon, Color color, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final softBorder = isDark
        ? theme.colorScheme.outlineVariant.withOpacity(0.25)
        : theme.colorScheme.outlineVariant.withOpacity(0.4);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      splashColor: theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08),
      highlightColor: Colors.transparent,
      onTap: () => SnackBarUtils.showInfo(context, '$title setup coming soon'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: softBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Tap to configure', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _showAddCardSheet() {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_card_rounded),
                        const SizedBox(width: 8),
                        Text('Add Card', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: numberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        hintText: '1234 5678 9012 3456',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expiryCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Expiry',
                              hintText: 'MM/YY',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: cvvCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '123',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cardholder Name',
                        hintText: 'John Doe',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _cards = [
                                  ..._cards,
                                  _CardItem(
                                    brand: 'Card',
                                    last4: numberCtrl.text.isNotEmpty
                                        ? numberCtrl.text.substring(numberCtrl.text.length - 4)
                                        : '0000',
                                    expiry: expiryCtrl.text.isNotEmpty ? expiryCtrl.text : '01/30',
                                  ),
                                ];
                              });
                              Navigator.pop(context);
                              SnackBarUtils.showSuccess(context, 'Card added');
                            },
                            child: const Text('Add Card'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _brandColor(String brand, ThemeData theme) {
    switch (brand) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.deepOrange;
      case 'amex':
        return Colors.indigo;
      default:
        return theme.colorScheme.primary;
    }
  }
}

class _CardItem {
  final String brand;
  final String last4;
  final String expiry;
  final bool isDefault;
  const _CardItem({required this.brand, required this.last4, required this.expiry, this.isDefault = false});

  _CardItem copyWith({String? brand, String? last4, String? expiry, bool? isDefault}) {
    return _CardItem(
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiry: expiry ?? this.expiry,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
