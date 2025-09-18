import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';

// Video call models
class VideoTourSession {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String hostId;
  final String hostName;
  final String guestId;
  final String guestName;
  final DateTime scheduledTime;
  final Duration duration;
  final VideoTourStatus status;
  final String? meetingUrl;
  final List<String> tourHighlights;

  VideoTourSession({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.hostId,
    required this.hostName,
    required this.guestId,
    required this.guestName,
    required this.scheduledTime,
    this.duration = const Duration(minutes: 30),
    this.status = VideoTourStatus.scheduled,
    this.meetingUrl,
    this.tourHighlights = const [],
  });

  VideoTourSession copyWith({
    VideoTourStatus? status,
    String? meetingUrl,
    List<String>? tourHighlights,
  }) {
    return VideoTourSession(
      id: id,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      hostId: hostId,
      hostName: hostName,
      guestId: guestId,
      guestName: guestName,
      scheduledTime: scheduledTime,
      duration: duration,
      status: status ?? this.status,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      tourHighlights: tourHighlights ?? this.tourHighlights,
    );
  }
}

enum VideoTourStatus {
  scheduled,
  starting,
  inProgress,
  completed,
  cancelled,
  noShow,
}

// Video Tour Service
class VideoTourService extends StateNotifier<List<VideoTourSession>> {
  VideoTourService() : super(_mockSessions);

  static final List<VideoTourSession> _mockSessions = [
    VideoTourSession(
      id: '1',
      propertyId: 'prop1',
      propertyTitle: 'Modern Downtown Apartment',
      hostId: 'host1',
      hostName: 'Sarah Johnson',
      guestId: 'guest1',
      guestName: 'John Doe',
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
      status: VideoTourStatus.scheduled,
      tourHighlights: ['Kitchen', 'Living Room', 'Bedroom', 'Balcony View'],
    ),
    VideoTourSession(
      id: '2',
      propertyId: 'prop2',
      propertyTitle: 'Cozy Beach House',
      hostId: 'host2',
      hostName: 'Mike Wilson',
      guestId: 'guest2',
      guestName: 'Jane Smith',
      scheduledTime: DateTime.now().add(const Duration(days: 1)),
      status: VideoTourStatus.scheduled,
      tourHighlights: ['Ocean View', 'Private Beach Access', 'Deck Area'],
    ),
  ];

  VideoTourSession? getSessionById(String id) {
    try {
      return state.firstWhere((session) => session.id == id);
    } catch (e) {
      return null;
    }
  }

  void scheduleVideoTour({
    required String propertyId,
    required String propertyTitle,
    required String hostId,
    required String hostName,
    required String guestId,
    required String guestName,
    required DateTime scheduledTime,
    required List<String> tourHighlights,
  }) {
    final newSession = VideoTourSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      hostId: hostId,
      hostName: hostName,
      guestId: guestId,
      guestName: guestName,
      scheduledTime: scheduledTime,
      tourHighlights: tourHighlights,
    );

    state = [...state, newSession];
  }

  void startVideoTour(String sessionId) {
    state = state.map((session) {
      if (session.id == sessionId) {
        return session.copyWith(
          status: VideoTourStatus.starting,
          meetingUrl: 'https://meet.rentally.com/tour/${session.id}',
        );
      }
      return session;
    }).toList();

    // Simulate connection process
    Timer(const Duration(seconds: 3), () {
      updateSessionStatus(sessionId, VideoTourStatus.inProgress);
    });
  }

  void updateSessionStatus(String sessionId, VideoTourStatus status) {
    state = state.map((session) {
      if (session.id == sessionId) {
        return session.copyWith(status: status);
      }
      return session;
    }).toList();
  }

  void cancelVideoTour(String sessionId) {
    updateSessionStatus(sessionId, VideoTourStatus.cancelled);
  }

  void completeVideoTour(String sessionId) {
    updateSessionStatus(sessionId, VideoTourStatus.completed);
  }
}

// Provider
final videoTourServiceProvider = StateNotifierProvider<VideoTourService, List<VideoTourSession>>(
  (ref) => VideoTourService(),
);

// Video Tour Scheduling Screen
class VideoTourSchedulingScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String hostId;
  final String hostName;

  const VideoTourSchedulingScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.hostId,
    required this.hostName,
  });

  @override
  ConsumerState<VideoTourSchedulingScreen> createState() => _VideoTourSchedulingScreenState();
}

class _VideoTourSchedulingScreenState extends ConsumerState<VideoTourSchedulingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<String> _selectedHighlights = [];
  final _noteController = TextEditingController();

  final List<String> _availableHighlights = [
    'Kitchen & Dining Area',
    'Living Room',
    'Master Bedroom',
    'Bathrooms',
    'Balcony/Patio',
    'Storage Areas',
    'Building Amenities',
    'Neighborhood Tour',
    'Parking Area',
    'Laundry Facilities',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleVideoTour),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyInfo(theme),
            const SizedBox(height: 24),
            _buildDateTimeSelection(theme),
            const SizedBox(height: 24),
            _buildTourHighlights(theme),
            const SizedBox(height: 24),
            _buildSpecialRequests(theme),
            const SizedBox(height: 24),
            _buildScheduleButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.propertyTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    widget.hostName[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Host: ${widget.hostName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Available for virtual tours',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date & Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Select Date',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Select Time',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tours are typically 30 minutes long and can be rescheduled up to 2 hours before the scheduled time.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourHighlights(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tour Highlights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select areas you\'d like to focus on during the tour',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableHighlights.map((highlight) {
                final isSelected = _selectedHighlights.contains(highlight);
                return FilterChip(
                  label: Text(highlight),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedHighlights.add(highlight);
                      } else {
                        _selectedHighlights.remove(highlight);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialRequests(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Requests (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any specific questions or areas you\'d like the host to focus on?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleButton(ThemeData theme) {
    final canSchedule = _selectedDate != null && _selectedTime != null;
    
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSchedule ? () => _scheduleVideoTour(context) : null,
        icon: const Icon(Icons.video_call),
        label: Text(AppLocalizations.of(context)!.scheduleVideoTour),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _scheduleVideoTour(BuildContext context) async {
    if (_selectedDate == null || _selectedTime == null) return;

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    ref.read(videoTourServiceProvider.notifier).scheduleVideoTour(
      propertyId: widget.propertyId,
      propertyTitle: widget.propertyTitle,
      hostId: widget.hostId,
      hostName: widget.hostName,
      guestId: 'current_user_id',
      guestName: 'Current User',
      scheduledTime: scheduledDateTime,
      tourHighlights: _selectedHighlights,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.videoTourScheduled),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Video Tour Session Screen
class VideoTourSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const VideoTourSessionScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<VideoTourSessionScreen> createState() => _VideoTourSessionScreenState();
}

class _VideoTourSessionScreenState extends ConsumerState<VideoTourSessionScreen> {
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isScreenSharing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = ref.watch(videoTourServiceProvider);
    final session = sessions.firstWhere((s) => s.id == widget.sessionId);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildVideoArea(session, theme),
            _buildTopBar(session, theme),
            _buildBottomControls(session, theme),
            if (session.status == VideoTourStatus.starting)
              _buildConnectingOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea(VideoTourSession session, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Main video (host's camera)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade700,
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    size: 80,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Video Tour in Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Host is showing you around the property',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Picture-in-picture (guest's camera)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _isVideoOn
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade400, Colors.green.shade600],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade700,
                        child: const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(VideoTourSession session, ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.propertyTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'with ${session.hostName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(VideoTourSession session, ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              isActive: !_isMuted,
              onTap: () => setState(() => _isMuted = !_isMuted),
            ),
            _buildControlButton(
              icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
              isActive: _isVideoOn,
              onTap: () => setState(() => _isVideoOn = !_isVideoOn),
            ),
            _buildControlButton(
              icon: Icons.screen_share,
              isActive: _isScreenSharing,
              onTap: () => setState(() => _isScreenSharing = !_isScreenSharing),
            ),
            _buildControlButton(
              icon: Icons.chat,
              isActive: false,
              onTap: () => _showChatDialog(),
            ),
            _buildControlButton(
              icon: Icons.call_end,
              isActive: false,
              backgroundColor: Colors.red,
              onTap: () => _endCall(session),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: backgroundColor != null ? Colors.white : (isActive ? Colors.black : Colors.white),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildConnectingOverlay(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Connecting to video tour...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tourChat),
        content: SizedBox(
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(l10n.chatMessagesHere),
                ),
              ),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _endCall(VideoTourSession session) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.endVideoTour),
        content: Text(l10n.endVideoTourConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(videoTourServiceProvider.notifier).completeVideoTour(session.id);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close video screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.videoTourCompleted),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(l10n.endTour),
          ),
        ],
      ),
    );
  }
}
